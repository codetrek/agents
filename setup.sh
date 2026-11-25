#!/usr/bin/env bash

BASEDIR=$(cd "$(dirname ${BASH_SOURCE})" && pwd)

# symlnk <src> <dest>
function symlnk() {
    local src=$1
    local target=$2

    test -d $target && ! test -L $target && echo "ERROR: $target is a directory, please remove and try again!" && exit 1

    ! test -L $target && ln -sf $src $target
}

######################
# .agents
symlnk $BASEDIR ~/.agents

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
