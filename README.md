# Agentic workflow development environment

A general-purpose, publishable environment for building Node-RED agent workflows. It keeps workflow state in `/data`, projects in `/workspace`, and credentials outside the image.

Included: Node 22, Node-RED with node-red-agents, Pi, Claude Code, Codex, OpenCode CLI, Git/GitHub CLI, and Anthropic's sandbox runtime (`srt`) plus its required `bubblewrap`, `ripgrep`, and `socat` dependencies.

## Run

```sh
cp .env.example .env
mkdir -p workspace
docker compose up --build
```

Open `http://localhost:1880`. Node-RED state persists in the managed `node_red_data` volume and your local project files remain in `./workspace`.

To use a published image, set `IMAGE=ghcr.io/<owner>/agentic-workflow-dev-env:<tag>` in `.env` and run `docker compose up` (the local build section may be removed if you prefer image-only deployments).

## Corporate CA certificates

If a TLS-intercepting proxy requires a custom CA during the build, pass it as a BuildKit secret. The certificate is trusted for package downloads but is not copied into the resulting image layer:

```sh
make build CACERT=/path/to/corporate-ca.pem
```

The same image tag is used by `make up`; `make up-srt` starts the opt-in nested-sandbox override.

For a shell inside the built image, run `make interactive`. It mounts `./workspace` at `/workspace` and removes the temporary container on exit.

## Secrets

Inject provider credentials through your secret manager or environment at runtime. Never bake credentials or host home directories into the image.

`GH_TOKEN` is optional and is used to configure Git credential handling at startup, enabling non-interactive access to private repositories. Use a least-privilege fine-grained token.

## SRT profile

Normal Node-RED workflows use:

```sh
docker compose up
```

Flows that execute `@anthropic-ai/sandbox-runtime` within the container need nested sandboxing support:

```sh
docker compose -f compose.yaml -f compose.srt.yaml up
```

That override adds `SYS_ADMIN`, `NET_ADMIN`, and unconfined seccomp/AppArmor so Bubblewrap can create its nested namespaces. This is deliberately opt-in and is suitable only for trusted local development, not multi-tenant or internet-exposed deployments.

## Publish to GHCR

Push this directory to a GitHub repository named `agentic-workflow-dev-env`. The included workflow publishes `ghcr.io/<repository-owner>/agentic-workflow-dev-env` on pushes to `main` and version tags. Make the resulting package public in GitHub Packages if you want pull access without authentication.

The semantic version is stored in `VERSION`. Run `make release BUMP=patch`, `make release BUMP=minor`, or `make release BUMP=major` from a clean worktree. The target creates and pushes a `vMAJOR.MINOR.PATCH` tag and GitHub Release; the release workflow publishes matching semver image tags.

## Origin of the design

This is distilled from [tbrandenburg/pixel-agents-adt](https://github.com/tbrandenburg/pixel-agents-adt): its successful elements are the Node 22 base, OpenCode + `gh` + SRT runtime, SRT's `bubblewrap`/`ripgrep`/`socat` dependencies, pre-created tool state directories, and startup Git credential setup. Pixel Agents, the bundled Agentic Development Team demo flow, shared `~/.pixel-agents` discovery, and build-time patches to one demo's flows are intentionally excluded.
