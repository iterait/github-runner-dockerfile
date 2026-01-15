# Github Actions: self-hosted runner in docker (with support of docker)

This a slight modification of [beikeni/github-runner-dockerfile](https://github.com/beikeni/github-runner-dockerfile) with updated OS,
github worker versions and internal docker support.

## Prebuilt images
Already built images are located in public docker hub repository [iterait/github-runner](https://hub.docker.com/r/iterait/github-runner).

## Build from source
```bash
docker build -t my-runner .
```
Optionally specify the worker version and checksum via `--build-arg RUNNER_VERSION=xxx` and `--build-arg RUNNER_SHA256=xxx`, respectively.

## Run

### Fetch personal token
Generate [new classic personal token](https://github.com/settings/tokens/new). Select `repo`, `workflow` and `write:packages` permissions.

Alternatively use fine-grained personal access tokens.

### Set up compose.yml
1. copy `compose.example.yml` to `compose.yml`
1. set the env. variable `REPOSITORY` specifying the github repository to which the worker will be associated (or just organisation name if it's shared for whole organization)
1. set the env. variable `ACCESS_TOKEN` specifying the github personal token from the previous section
1. set the env. variable `WORKER_NAME` specifying the worker name base (e.g. hostname of the host machine)
1. set the env. variable `WORKER_LABELS` specifying the github worker labels (comma separated, at least one label)

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
