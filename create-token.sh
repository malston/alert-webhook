#!/usr/bin/env bash

set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

function create_token() {
    if [[ -f "config/token.json" ]]; then
        echo -n "Deleting token.json"
        echo ""
        rm "config/token.json"
    fi

    if [[ ! -f ./alert-webhook-token ]]; then
        echo -n "Compiling..."
        echo ""
        make build-token
    fi

    echo -n "Creating token..."
    echo ""
    ./alert-webhook-token
}

create_token