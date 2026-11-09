#!/bin/bash
# Registers a GitHub Actions runner, runs it and deregisters it on shutdown.
# Must be run from the root of the actions-runner directory.

set -euo pipefail
exec 2>&1

: "${ACCESS_TOKEN:?ACCESS_TOKEN must be set}"
: "${REPOSITORY:?REPOSITORY must be set (owner/repo, or just the organisation name)}"
: "${WORKER_NAME:?WORKER_NAME must be set}"
WORKER_LABELS="${WORKER_LABELS:-}"
RUNNER_WORKDIR="${RUNNER_WORKDIR:-/actions-runner/_work}"

export RUNNER_ALLOW_RUNASROOT=1

# "owner/repo" -> repository runner, "org" -> organisation runner
if [[ "${REPOSITORY}" == */* ]]; then
    API_SCOPE="repos/${REPOSITORY}"
else
    API_SCOPE="orgs/${REPOSITORY}"
fi
RUNNER_URL="https://github.com/${REPOSITORY}"

# Usage: get_token registration-token|remove-token
# Both tokens expire after one hour, so always request a fresh one.
get_token() {
    local token
    token=$(curl -fsS -X POST \
        -H "Authorization: Bearer ${ACCESS_TOKEN}" \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "https://api.github.com/${API_SCOPE}/actions/runners/$1" \
        | jq -r '.token // empty') || true
    if [[ -z "${token}" ]]; then
        echo "Error: failed to obtain $1 from https://api.github.com/${API_SCOPE}" >&2
        return 1
    fi
    echo "${token}"
}

remove_runner() {
    local remove_token
    echo "Removing runner..."
    if remove_token=$(get_token remove-token); then
        ./config.sh remove --unattended --token "${remove_token}" \
            || echo "Warning: failed to remove runner"
    fi
}

# A previous run of this container was killed without cleaning up.
if [[ -f .runner ]]; then
    echo "Found stale runner configuration."
    remove_runner
    rm -f .runner .credentials .credentials_rsaparams
fi

echo "Obtaining registration token..."
REG_TOKEN=$(get_token registration-token)

RANDOM_SUFFIX=$(openssl rand -hex 4)
WORKER_NAME_WITH_SUFFIX="${WORKER_NAME}-${RANDOM_SUFFIX}"
LABELS="${WORKER_NAME},${WORKER_NAME_WITH_SUFFIX}"
if [[ -n "${WORKER_LABELS}" ]]; then
    LABELS="${WORKER_LABELS},${LABELS}"
fi
# Per-runner work dir, so replicas sharing one mounted directory don't collide.
WORK_DIR="${RUNNER_WORKDIR}/${WORKER_NAME_WITH_SUFFIX}"
mkdir -p "${WORK_DIR}"

echo "Configuring runner ${WORKER_NAME_WITH_SUFFIX}..."
./config.sh \
    --url "${RUNNER_URL}" \
    --token "${REG_TOKEN}" \
    --name "${WORKER_NAME_WITH_SUFFIX}" \
    --labels "${LABELS}" \
    --work "${WORK_DIR}" \
    --unattended \
    --disableupdate

RUNNER_PID=""

cleanup() {
    trap - INT TERM
    if [[ -n "${RUNNER_PID}" ]] && kill -0 "${RUNNER_PID}" 2>/dev/null; then
        echo "Stopping runner..."
        kill -TERM "${RUNNER_PID}" 2>/dev/null || true
        wait "${RUNNER_PID}" || true
    fi
    remove_runner
    rm -rf "${WORK_DIR}"
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

echo "Running runner..."
# Don't leak the personal access token into the job environment.
env -u ACCESS_TOKEN ./run.sh &
RUNNER_PID=$!
status=0
wait "${RUNNER_PID}" || status=$?
echo "Runner stopped (exit code ${status})"
cleanup
exit "${status}"
