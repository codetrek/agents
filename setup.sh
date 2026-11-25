#!/usr/bin/env bash

set -e

catalog=$(cd "$(dirname "${BASH_SOURCE[0]}")/skills" && pwd -P)
shared="$HOME/.agents/skills"

install_link() {
    local destination=$1 source=$2
    [[ -L "$destination" ]] && return 0
    if [[ -d "$destination" ]]; then
        printf 'Directory already exists: %s\n' "$destination" >&2
        return 1
    fi
    ln -sf "$source" "$destination"
}

if [[ ! -e "$HOME/.agents" && ! -L "$HOME/.agents" && -d "$HOME/.env/.agents" ]]; then
    install_link "$HOME/.agents" .env/.agents
fi
mkdir -p "$HOME/.agents"
if ! [[ "$shared" -ef "$catalog" ]]; then
    install_link "$shared" "$catalog"
fi

for client in .claude .copilot; do
    mkdir -p "$HOME/$client"
    install_link "$HOME/$client/skills" ../.agents/skills
done

echo Done!
