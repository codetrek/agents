#!/usr/bin/env bash
set -e

install_agents() {
    if (( $# > 1 )); then
        printf 'Usage: install.sh [checkout-directory]\n' >&2
        return 2
    fi

    local destination=${1:-"${HOME:?HOME is not set}/.agents"}
    if [[ -e "$destination" || -L "$destination" ]]; then
        printf 'Checkout path already exists: %s\n' "$destination" >&2
        return 1
    fi

    git clone -- https://github.com/codetrek/agents.git "$destination"
    bash "$destination/setup.sh"
}

install_agents "$@"
