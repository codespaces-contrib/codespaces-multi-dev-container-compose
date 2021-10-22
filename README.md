# Using GitHub Codespaces with Multiple Development Containers (Compose variation)

Visual Studio Code Remote - Containers supports [a pattern](https://code.visualstudio.com/remote/advancedcontainers/connect-multiple-containers) that allows the use of multiple development containers at the same time for a source tree. Unfortunately [GitHub Codespaces](https://github.com/features/codespaces) does not currently support attaching a second window to a different container in the same Codespaces. However, the fact that the same technology is used in both Remote - Containers and Codespaces allows you to use the Remote - Containers extension with a codespace to achieve the same goal with some subtle tweaks.

This variation of the pattern mirrors the Remote - Containers one and spins everything up at once using a single Docker Compose file. If you would prefer spin up completely separate dev containers in the same codespace, [see this variation instead](https://github.com/chuxel/codespaces-multi-dev-container).

Codespaces will ultimately have first class support for this partern, so this is a workaround given current limitations.

## Setup
1. Install [VS Code](https://code.visualstudio.com/) (stable) locally
2. On macOS, follow the needed steps to [add `code` to your local `PATH`](https://code.visualstudio.com/docs/setup/mac#_launching-from-the-command-line). (This should already be done by default on a typical Windows/Linux install.)
3. Install the [GitHub Codespaces](https://marketplace.visualstudio.com/items?itemName=GitHub.codespaces) extension in local VS Code
4. Install the [VS Code Remote - Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension in local VS Code
5. Install the Docker CLI locally (e.g. by installing Docker Desktop, but Docker does not need to be running)
6. On macOS or Linux, install `jq` locally:
    - macOS: `brew install jq`
    - Linux: Use your distro's package manger to install. For example, `sudo apt-get install jq`

## Using this sample

1. Create a codespace from this repository from VS Code client locally (<kbd>F1</kbd> or <kbd>ctrl</kbd>+<kbd>shift</kbd>+<kbd>p</kbd>, select **Codesaces: Create New Codespace**, enter this repository)

    > Note: If you accidentally created the codespace from the web, you can open it in VS Code client after things are up and running if you prefer.

2. In this codespace, open a terminal and run the command: `keep-me-alive`

3. On Windows, be sure the **Remote - Containers: Execute in WSL** user setting is **Unchecked** (`"remote.containers.executeInWSL": false` in `settings.json`).

4. Next, copy `open-codespace-dev-container.sh` (macOS / Linux) or `open-codespace-dev-container.ps1` and `open-codespace-dev-container.cmd` (Windows) to your local machine.

5. In a **local** terminal, use the script to set up a connection to one of the sub-folders in this repository. For example, on macOS / Linux:

    ```bash
    bash open-codespace-dev-container.sh container-1-src
    ```

    ... or on Windows, use PowerShell/Command Prompt (not WSL) as follows:
    ```powershell
    .\open-codespace-dev-container.cmd container-1-src
    ```

4. In the VS Code window that appears, click **Reopen in Container** when a notification appears.

In a bit, this new window will be using the development container for this folder.

## Adapting the sample for your own use

This sample applies the same [patterns](https://code.visualstudio.com/remote/advancedcontainers/connect-multiple-containers) used in Remote - Containers for this same scenario. To adapt for your own use:

1. Modify the extensions and contents of each dev container by updating the `Dockerfile` and `devcontainer.json` file in `container-1-src` and `container-2-src` as needed. You can also rename the folders.

2. If you need to add another folder, copy the contents of `container-1-src` to create a new folder. Then update `docker-compose.yml` and add a new section for your container. For example, if you created a `container-3-src` folder, you could add a new section like this:

    ```yaml
    # Development container 3
    container-3:
      build:
        context: container-3-src/.devcontainer
        dockerfile: Dockerfile
      volumes:
        - ./container-3-src:/workspace:cached
      command: /bin/sh -c "while sleep 1000; do :; done"
    ```

3. For multi-repo scenarios, you can setup the "bootstrap" container (in the root `.devcontainer` folder) to clone repositories as described in [this sample](https://github.com/Chuxel/codespaces-multi-repo) instead. You can then modify `docker-compose.yaml` to reference the appropriate locations for the Dockerfiles and add the appropriate `.container` config into the repositories.

4. If your new container relies on contents outside of the `.devcontainer` folder (particularly if common across all containers), add them to `common-config.list` in the root of the repository.

## TODOs

There are few to-dos for this sample:
1. Cache VS Code Server between development containers to avoid having to download it multiple times.
2. Look for ways to further reduce steps.