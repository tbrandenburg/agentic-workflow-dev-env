# AGENTS.md
## Purpose
This repository packages a reproducible Node-RED environment for agentic workflow development.
The image includes Node 22, Node-RED with node-red-agents, Pi, Claude Code, OpenCode, GitHub CLI, and sandbox-runtime tooling.
Keep workflow state in `/data`, project files in `/workspace`, and secrets outside the image.
## Structure
`Dockerfile` defines the image, installed tools, volumes, entrypoint, and exposed port.
`entrypoint.sh` creates runtime directories and configures Git credentials from `GH_TOKEN`.
`compose.yaml` runs the standard service with persistent Node-RED data and local workspace mounts.
`compose.srt.yaml` is an opt-in override for trusted nested sandbox development.
`Makefile` provides the supported build, run, stop, log, and help commands.
`VERSION` stores the semantic version; `.github/workflows/publish-ghcr.yml` publishes GHCR images.
## Makefile Usage
Run `make help` to list targets; `make build` builds the image with optional `IMAGE=...`.
Run `make up` to build and start Node-RED on port 1880.
Run `make interactive` to build the image and open a shell in `/workspace`.
Run `make up-srt` only for trusted workflows requiring nested sandbox permissions.
Run `make logs` to follow output; `make down` stops services without removing volumes.
Pass `CACERT=/path/to/ca.pem` to `make build` for corporate CA package downloads.
Run `make release BUMP=major|minor|patch` from a clean tree to tag and push a release.
