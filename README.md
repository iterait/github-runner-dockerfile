# Github Actions: self-hosted runner in docker (with support of docker)

This a slight modification of [beikeni/github-runner-dockerfile](https://github.com/beikeni/github-runner-dockerfile) with updated OS,
github worker versions and internal docker support.

## Prebuilt images
Already built images are located in public docker hub repository [iterait/github-runner](https://hub.docker.com/r/iterait/github-runner).

## Build from source
```bash
docker build -t my-runner .
```
Optionally specify the worker version and checksums via `--build-arg RUNNER_VERSION=xxx`, `--build-arg RUNNER_SHA256_X64=xxx`
and `--build-arg RUNNER_SHA256_ARM64=xxx` (checksums are listed in the [runner release notes](https://github.com/actions/runner/releases)).
Both `linux/amd64` and `linux/arm64` are supported (`docker buildx build --platform linux/arm64 ...`); prebuilt images are `linux/amd64` only.

## Run

### Fetch personal token
Generate a [fine-grained personal access token](https://github.com/settings/personal-access-tokens/new) with the least privileges needed:
- repository runner: access to that repository only, with the *Administration: Read and write* repository permission,
- organisation runner: the *Self-hosted runners: Read and write* organisation permission.

Alternatively, use a [classic personal token](https://github.com/settings/tokens/new) with the `repo` scope (repository runner) or `admin:org` scope (organisation runner).

The token is only used to register and deregister the runner and is not passed to the jobs' environment.
Note, however, that jobs run as root with access to the host docker daemon, so only use the runner for workflows you trust.

### Set up compose.yml
1. copy `compose.example.yml` to `compose.yml`
1. set the env. variable `REPOSITORY` specifying the github repository (`owner/repo`) to which the worker will be associated (or just the organisation name if it's shared for the whole organisation)
1. set the env. variable `ACCESS_TOKEN` specifying the github personal token from the previous section
1. set the env. variable `WORKER_NAME` specifying the worker name base (e.g. hostname of the host machine)
1. optionally set the env. variable `WORKER_LABELS` specifying additional github worker labels (comma separated)
1. optionally set the env. variable `RUNNER_WORKDIR` specifying the jobs' work directory (default `/actions-runner/_work`).
   Since jobs use the host docker daemon, bind paths such as `docker run -v $PWD:/src` are resolved on the host.
   To make them work, mount `RUNNER_WORKDIR` at the same path on the host and in the container (see `compose.example.yml`).
   Each runner uses its own subdirectory, which is removed when the runner stops.

### Run the containers
```bash
docker compose up [-d]
```

The successful output should look like this:
```
$ docker compose
github-runner-1  | Obtaining registration token...
github-runner-1  |   % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
github-runner-1  |                                  Dload  Upload   Total   Spent    Left  Speed
100    96  100    96    0     0    306      0 --:--:-- --:--:-- --:--:--   306
github-runner-1  | Configuring runner...
github-runner-1  |
github-runner-1  | --------------------------------------------------------------------------------
github-runner-1  | |        ____ _ _   _   _       _          _        _   _                      |
github-runner-1  | |       / ___(_) |_| | | |_   _| |__      / \   ___| |_(_) ___  _ __  ___      |
github-runner-1  | |      | |  _| | __| |_| | | | | '_ \    / _ \ / __| __| |/ _ \| '_ \/ __|     |
github-runner-1  | |      | |_| | | |_|  _  | |_| | |_) |  / ___ \ (__| |_| | (_) | | | \__ \     |
github-runner-1  | |       \____|_|\__|_| |_|\__,_|_.__/  /_/   \_\___|\__|_|\___/|_| |_|___/     |
github-runner-1  | |                                                                              |
github-runner-1  | |                       Self-hosted runner registration                        |
github-runner-1  | |                                                                              |
github-runner-1  | --------------------------------------------------------------------------------
github-runner-1  |
github-runner-1  | # Authentication
github-runner-1  |
github-runner-1  |
github-runner-1  | √ Connected to GitHub
github-runner-1  |
github-runner-1  | # Runner Registration
github-runner-1  |
github-runner-1  |
github-runner-1  |
github-runner-1  |
github-runner-1  | √ Runner successfully added
github-runner-1  |
github-runner-1  | # Runner settings
github-runner-1  |
github-runner-1  |
github-runner-1  | √ Settings Saved.
github-runner-1  |
github-runner-1  | Running runner...
github-runner-1  |
github-runner-1  | √ Connected to GitHub
github-runner-1  |
github-runner-1  | Current runner version: '2.331.0'
github-runner-1  | 2026-01-15 11:11:23Z: Listening for Jobs
```
