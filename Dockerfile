# syntax=docker/dockerfile:1.7
ARG NODE_VERSION=22
FROM node:${NODE_VERSION}-bookworm-slim

LABEL org.opencontainers.image.title="agentic-workflow-dev-env" \
      org.opencontainers.image.description="Node-RED and CLI tooling for agentic workflow development" \
      org.opencontainers.image.licenses="MIT"

ARG NODE_RED_VERSION=latest
ARG PI_VERSION=latest
ARG CODEX_VERSION=latest
ARG OPENCODE_INSTALL_URL=https://opencode.ai/install
ARG SRT_VERSION=latest

ENV DEBIAN_FRONTEND=noninteractive \
    NODE_RED_HOME=/data \
    WORKSPACE=/workspace \
    NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt \
    PATH=/home/node/.opencode/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Tools required for workflow development and @anthropic-ai/sandbox-runtime.
# Do not add Docker-in-Docker: mount the host socket only in a local override,
# and only when a workflow genuinely needs it.
RUN --mount=type=secret,id=cacert \
    apt-get update \
    && apt-get install -y --no-install-recommends \
      bash ca-certificates curl git gnupg tini \
      bubblewrap ripgrep socat openssh-client \
    && if [ -s /run/secrets/cacert ]; then \
         cp /run/secrets/cacert /usr/local/share/ca-certificates/custom-ca.crt; \
         update-ca-certificates; \
       fi \
    && npm install --global --omit=dev \
      node-red@${NODE_RED_VERSION} \
      @anthropic-ai/sandbox-runtime@${SRT_VERSION} \
      @tbrandenburg/node-red-agents@latest \
    && npm install --global --omit=dev \
      @earendil-works/pi-coding-agent@${PI_VERSION} --ignore-scripts \
    && npm install --global --omit=dev \
      @openai/codex@${CODEX_VERSION} \
    && su -s /bin/bash node -c "export HOME=/home/node; curl -fsSL '${OPENCODE_INSTALL_URL}' | bash" \
    && rm -f /usr/local/share/ca-certificates/custom-ca.crt \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# GitHub CLI from GitHub's signed APT repository.
RUN --mount=type=secret,id=cacert \
    if [ -s /run/secrets/cacert ]; then \
      cp /run/secrets/cacert /usr/local/share/ca-certificates/custom-ca.crt; \
      update-ca-certificates; \
    fi \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && install -d -m 0755 /etc/apt/keyrings \
    && curl -fsSL https://downloads.claude.ai/keys/claude-code.asc \
      -o /etc/apt/keyrings/claude-code.asc \
    && echo "deb [signed-by=/etc/apt/keyrings/claude-code.asc] https://downloads.claude.ai/claude-code/apt/latest latest main" \
      > /etc/apt/sources.list.d/claude-code.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh claude-code \
    && rm -f /etc/apt/keyrings/claude-code.asc /etc/apt/sources.list.d/claude-code.list \
    && rm -f /usr/local/share/ca-certificates/custom-ca.crt \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint

RUN mkdir -p "${NODE_RED_HOME}" "${WORKSPACE}" \
    && chown -R node:node "${NODE_RED_HOME}" "${WORKSPACE}"

USER node
WORKDIR /workspace

EXPOSE 1880
VOLUME ["/data", "/workspace"]

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint"]
CMD ["node-red", "--userDir", "/data"]
