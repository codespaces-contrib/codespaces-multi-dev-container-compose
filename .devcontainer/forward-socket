#!/bin/sh

SOURCE_SOCKET=${1:-"/var/run/docker-host.sock"}
TARGET_PORT=${2:-"9256"}

# Wrapper function to only use sudo if not already root
sudoIf()
{
    if [ "$(id -u)" -ne 0 ]; then
        sudo "$@"
    else
        "$@"
    fi
}

sudoIf socat TCP-LISTEN:${TARGET_PORT},fork,bind=127.0.0.1 UNIX-CONNECT:${SOURCE_SOCKET} 2>&1 > /tmp/socat.log
