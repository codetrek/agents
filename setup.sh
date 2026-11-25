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
# .claude
mkdir -p ~/.claude
symlnk ../.agents/skills ~/.claude/skills

######################
# .copilot
mkdir -p ~/.copilot
symlnk ../.agents/skills ~/.copilot/skills

######################
# Finally
echo Done!
