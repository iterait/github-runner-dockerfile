FROM ubuntu:26.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive
ARG TARGETARCH
ARG RUNNER_VERSION="2.338.0"
ARG RUNNER_SHA256_X64="af4b794c1bc41d73d40535e3fe092a39f9679cd8d965954c2aca25a05ca41d32"
ARG RUNNER_SHA256_ARM64="628b4a7258487b80c1d3c221095a7ded349f5ae0175fd3dfab708d07428f041b"

# Only the docker client tooling is installed; the daemon is the host's one (mounted socket).
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl gnupg && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    . /etc/os-release && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
      > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      jq openssl build-essential libssl-dev libffi-dev \
      python3 python3-venv python3-dev python3-pip \
      docker-ce-cli docker-buildx-plugin docker-compose-plugin && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /actions-runner
RUN case "${TARGETARCH:-amd64}" in \
      amd64) RUNNER_ARCH=x64;   RUNNER_SHA256="${RUNNER_SHA256_X64}" ;; \
      arm64) RUNNER_ARCH=arm64; RUNNER_SHA256="${RUNNER_SHA256_ARM64}" ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac && \
    RUNNER_TGZ="actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz" && \
    curl -fsSLO "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${RUNNER_TGZ}" && \
    echo "${RUNNER_SHA256}  ${RUNNER_TGZ}" | sha256sum -c - && \
    tar xzf "${RUNNER_TGZ}" && \
    rm "${RUNNER_TGZ}" && \
    apt-get update && \
    ./bin/installdependencies.sh && \
    rm -rf /var/lib/apt/lists/*

COPY --chmod=755 start.sh start.sh

ENTRYPOINT ["./start.sh"]
