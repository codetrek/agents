#!/usr/bin/env bash

BASEDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P) || exit 1

# symlnk <src> <dest>
function symlnk() {
    local src=$1
    local target=$2

    test -d $target && ! test -L $target && echo "ERROR: $target is a directory, please remove and try again!" && exit 1

    ! test -L $target && ln -sf $src $target
}

# .agents
if [[ ! -e ~/.agents && ! -L ~/.agents && -d ~/.env/.agents ]]; then
    symlnk .env/.agents ~/.agents
fi
mkdir -p ~/.agents || exit 1
if ! [[ -L ~/.agents/skills || ~/.agents/skills -ef "$BASEDIR/skills" ]]; then
    symlnk "$BASEDIR/skills" ~/.agents/skills || exit 1
fi

# .claude
mkdir -p ~/.claude
symlnk ../.agents/skills ~/.claude/skills

# .copilot
mkdir -p ~/.copilot
symlnk ../.agents/skills ~/.copilot/skills

echo Done!
