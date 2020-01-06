#!/usr/bin/env bash

set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

namespace="${1:-amhook}"

kubectl create secret -n "${namespace}" generic gmail-secret \
    --from-file=config/client_secret.json  \
    --from-file=config/token.json
