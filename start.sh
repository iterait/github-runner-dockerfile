#!/bin/bash

# This script must be run from the root of the actions-runner directory, i

set -euo pipefail
exec 2>&1

echo "Obtaining registration token..."
REG_TOKEN=$(curl --fail -X POST \
    -H "Authorization: token ${ACCESS_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    https://api.github.com/repos/${REPOSITORY}/actions/runners/registration-token \
    | jq .token --raw-output)

if [ -z "$REG_TOKEN" ]; then
    echo "Error: Failed to obtain registration token"
    exit 1
fi

echo "Configuring runner..."
RANDOM_SUFFIX=$(openssl rand -hex 4)
WORKER_NAME_WITH_SUFFIX="${WORKER_NAME}-${RANDOM_SUFFIX}"
RUNNER_ALLOW_RUNASROOT=1 ./config.sh \
    --url https://github.com/${REPOSITORY} \
    --token ${REG_TOKEN} \
    --name "${WORKER_NAME_WITH_SUFFIX}" \
    --labels "${WORKER_LABELS},${WORKER_NAME},${WORKER_NAME_WITH_SUFFIX}" \
    --unattended \
    --disableupdate \
    --replace


cleanup() {
    echo "Removing runner..."
    RUNNER_ALLOW_RUNASROOT=1 ./config.sh remove --unattended --token ${REG_TOKEN}
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

echo "Running runner..."
RUNNER_ALLOW_RUNASROOT=1 ./run.sh & wait $!
echo "Runner stopped"
