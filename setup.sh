#!/usr/bin/env bash
set -e

BASEDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)

# symlnk <src> <dest>
function symlnk() {
    local src=$1
    local target=$2

    if [[ -L "$target" && "$(readlink "$target")" == "$src" ]]; then
        return
    fi
    if [[ -e "$target" || -L "$target" ]]; then
        echo "ERROR: $target already exists. Move it aside and run setup again." >&2
        exit 1
    fi
    ln -s "$src" "$target"
}

# .agents
if [[ ! -e "$HOME/.agents" && ! -L "$HOME/.agents" && -d "$HOME/.env/.agents" ]]; then
    symlnk .env/.agents "$HOME/.agents"
fi
mkdir -p "$HOME/.agents"
if ! [[ "$HOME/.agents/skills" -ef "$BASEDIR/skills" ]]; then
    symlnk "$BASEDIR/skills" "$HOME/.agents/skills"
fi

# .claude
mkdir -p "$HOME/.claude"
if ! [[ "$HOME/.claude/skills" -ef "$HOME/.agents/skills" ]]; then
    symlnk ../.agents/skills "$HOME/.claude/skills"
fi

# .copilot
mkdir -p "$HOME/.copilot"
if ! [[ "$HOME/.copilot/skills" -ef "$HOME/.agents/skills" ]]; then
    symlnk ../.agents/skills "$HOME/.copilot/skills"
fi

echo Done!
