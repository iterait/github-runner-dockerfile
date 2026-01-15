FROM ubuntu:25.10

ARG RUNNER_VERSION="2.331.0"
ARG RUNNER_SHA256="5fcc01bd546ba5c3f1291c2803658ebd3cedb3836489eda3be357d41bfcf28a7"

RUN apt update -y && \
    apt install -y ca-certificates curl gnupg lsb-release && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg  && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

RUN apt update -y &&\
    apt install -y --no-install-recommends \
      jq build-essential libssl-dev libffi-dev \
      python3 python3-venv python3-dev python3-pip \
      docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

WORKDIR /actions-runner
RUN curl -fsSLO https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz && \
    echo "${RUNNER_SHA256}  actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" | shasum -a 256 -c && \
    tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

ARG DEBIAN_FRONTEND=noninteractive
RUN ./bin/installdependencies.sh

COPY start.sh start.sh
RUN chmod +x start.sh

ENTRYPOINT ["./start.sh"]
