FROM mcr.microsoft.com/vscode/devcontainers/base:0-bullseye

COPY forward-socket /usr/local/bin/
RUN chmod +x /usr/local/bin/forward-socket \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get update && apt-get install -y socat
