# AGENTS.md
## Purpose
This repository packages a reproducible Node-RED environment for agentic workflow development.
The image includes Node 22, Node-RED, OpenCode, GitHub CLI, and sandbox-runtime tooling.
Keep workflow state in `/data`, project files in `/workspace`, and secrets outside the image.
## Structure
`Dockerfile` defines the image, installed tools, volumes, entrypoint, and exposed port.
`entrypoint.sh` creates runtime directories and configures Git credentials from `GH_TOKEN`.
`compose.yaml` runs the standard service with persistent Node-RED data and local workspace mounts.
`compose.srt.yaml` is an opt-in override for trusted nested sandbox development.
`Makefile` provides the supported build, run, stop, log, and help commands.
`.github/workflows/publish-ghcr.yml` publishes the image to GitHub Container Registry.
`README.md` documents setup, CA certificates, secrets, sandboxing, and publishing.
## Makefile Usage
Run `make help` to list available targets and descriptions.
Run `make build` to build the image; set `IMAGE=...` to choose another tag.
Run `make up` to build and start Node-RED on port 1880.
Run `make up-srt` only for trusted workflows requiring nested sandbox permissions.
Run `make logs` to follow service output and `make down` to stop services without removing volumes.
Pass `CACERT=/path/to/ca.pem` to `make build` when package downloads need a corporate CA.
