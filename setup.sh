#!/usr/bin/env bash
set -e

BASEDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)

# symlnk <src> <dest>
function symlnk() {
    local src=$1
    local target=$2

    if [[ -L "$target" ]]; then
        if [[ $(readlink "$target") == "$src" ]] ||
            (cd "$(dirname "$target")" && [[ "$src" -ef "$(basename "$target")" ]]); then
            return 0
        fi
        unlink "$target"
    elif [[ -e "$target" ]]; then
        echo "ERROR: $target already exists. Move it aside and run setup again!" >&2
        return 1
    fi
    ln -s "$src" "$target"
}

######################
# .agents
if ! [[ "$BASEDIR" -ef ~/.agents ]]; then
    symlnk "$BASEDIR" ~/.agents
fi

######################
# .codex
mkdir -p ~/.codex
symlnk ../.agents/AGENTS.md ~/.codex/AGENTS.md
symlnk ../.agents/agents ~/.codex/agents

######################
# .claude
mkdir -p ~/.claude
symlnk ../.agents/AGENTS.md ~/.claude/CLAUDE.md
symlnk ../.agents/skills ~/.claude/skills

######################
# .copilot
mkdir -p ~/.copilot
symlnk ../.agents/skills ~/.copilot/skills
symlnk ../.agents/agents ~/.copilot/agents

######################
# Finally
echo Done!
