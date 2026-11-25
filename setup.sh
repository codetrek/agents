#!/usr/bin/env bash
set -euo pipefail

fail() { printf 'setup.sh: %s\n' "$*" >&2; exit 1; }
[[ $# == 0 ]] || fail 'Usage: setup.sh'
[[ ${HOME:-} == /* ]] || fail 'HOME must be an absolute path.'

root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
catalog=$root/skills
shared=$HOME/.agents/skills
clients=("$HOME/.claude/skills" "$HOME/.copilot/skills")
root_alias=
if [[ ! -e $HOME/.agents && ! -L $HOME/.agents && -d $HOME/.env/.agents ]]; then root_alias=$HOME/.env/.agents; fi
shopt -s nullglob
manifests=("$catalog"/*/SKILL.md)
(( ${#manifests[@]} > 0 )) || fail "No skills found in $catalog"
for manifest in "${manifests[@]}"; do
  [[ -f $manifest ]] || fail "Expected a skill manifest file: $manifest"
done
shopt -s dotglob

# Resolve parent aliases without requiring directories that mkdir will create.
directory_key() {
  local path=${1:-/} suffix= name physical
  while [[ ! -d $path ]]; do
    [[ ! -e $path && ! -L $path ]] || return 1
    name=${path##*/}
    if [[ -n $root_alias && $name == .agents && ${path%/*} -ef $HOME ]]; then
      path=$root_alias
      continue
    fi
    case $name in
      '') ;;
      .|..) return 1 ;;
      *) suffix=/$name$suffix ;;
    esac
    path=${path%/*}
    path=${path:-/}
  done
  physical=$(CDPATH= cd -P -- "$path" && pwd -P) || return 1
  printf '%s\n' "${physical%/}$suffix"
}

location() {
  local parent
  parent=$(directory_key "${1%/*}") || fail "Expected a directory: ${1%/*}"
  printf '%s/%s\n' "$parent" "${1##*/}"
}
shared_key=$(location "$shared")
separate() {
  [[ $1 != "$2" && $1 != "$2"/* && $2 != "$1"/* ]] || fail "Incompatible skill directories overlap: $1, $2"
}
if [[ $shared_key != "$catalog" ]]; then separate "$shared_key" "$catalog"; fi
previous_client=
for client in "${clients[@]}"; do
  client_key=$(location "$client")
  if [[ $client_key == "$catalog" || $client_key == "$shared_key" ]]; then continue; fi
  separate "$client_key" "$catalog"
  separate "$client_key" "$shared_key"
  if [[ -n $previous_client && $previous_client != "$client_key" ]]; then separate "$client_key" "$previous_client"; fi
  previous_client=$client_key
done

# Compare the named skills directory itself, without following its final link:
# even after installation a link through ~/.agents differs from a checkout link.
points_to() {
  local link=$1 key=$2 name=${3:-} path parent
  [[ -L $link ]] || return 1
  path=$(readlink "$link") || return 1
  [[ $path == /* ]] || path=${link%/*}/$path
  if [[ -n $name ]]; then
    [[ $(basename -- "$path") == "$name" ]] || return 1
    path=$(dirname -- "$path")
  fi
  [[ $(basename -- "$path") == skills ]] || return 1
  parent=$(directory_key "$(dirname -- "$path")") || return 1
  [[ $parent/skills == "$key" ]]
}

make_link() {
  ln -s "$1" "${2%/*}/"
  printf 'Linked %s -> %s\n' "$2" "$1"
}

directory_link() {
  local action=$1 destination=$2 target=$3 key=$4 entry name
  if [[ -L $destination ]]; then
    points_to "$destination" "$key" || fail "Unexpected directory link: $destination"
    return 0
  fi
  if [[ -e $destination ]]; then
    [[ -d $destination && -r $destination && -x $destination ]] || fail "Expected a readable directory: $destination"
    for entry in "$destination"/*; do
      name=${entry##*/}
      [[ $name != .* && -f $catalog/$name/SKILL.md ]] || fail "Unmanaged entry: $entry"
      if ! points_to "$entry" "$catalog" "$name"; then
        [[ $target == "$shared" ]] && points_to "$entry" "$shared_key" "$name" || fail "Unmanaged entry: $entry"
      fi
      if [[ $action == install ]]; then unlink "$entry"; fi
    done
    if [[ $action == install ]]; then rmdir "$destination"; fi
  fi
  if [[ $action == install ]]; then
    mkdir -p "${destination%/*}"
    if [[ $target == "$shared" && ${destination%/*}/../.agents -ef $HOME/.agents ]]; then target=../.agents/skills; fi
    make_link "$target" "$destination"
  fi
}

# Verify the entire layout before removing even one owned link.
for action in check install; do
  if [[ $action == install && -n $root_alias ]]; then make_link .env/.agents "$HOME/.agents"; fi
  if [[ $shared_key != "$catalog" ]]; then directory_link "$action" "${root_alias:-$HOME/.agents}/skills" "$catalog" "$catalog"; fi
  for client in "${clients[@]}"; do
    client_key=$(location "$client")
    if [[ $client_key == "$catalog" || $client_key == "$shared_key" ]]; then continue; fi
    directory_link "$action" "$client" "$shared" "$shared_key"
  done
done
