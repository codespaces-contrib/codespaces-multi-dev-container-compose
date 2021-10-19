param (
    $devContainerBaseFolder='.',
    $dockerHostPort='9256'
)

$ErrorActionPreference = "Stop"

$env:DOCKER_HOST = "tcp://localhost:$dockerHostPort"

$workspaceContainer = (docker ps -q --filter "label=com.github.codespaces.active.workspace=true") -join ''
Write-Host "Boostrap container ID: $workspaceContainer"
$composeProjectName = (docker inspect -f '{{ index .Config.Labels \"com.docker.compose.project\" }}' ${workspaceContainer}) -join ''
if ($composeProjectName -ne "" ) {
    Write-Host "Compose project name: $composeProjectName"
    $env:COMPOSE_PROJECT_NAME=$composeProjectName
}
$workspaceFolderInContainer = (docker exec -i $workspaceContainer /bin/sh -c "cat /tmp/__boostrap_container_workspace_folder") -join ''
Write-Host "Workspace folder in container: $workspaceFolderInContainer"

$tempDir = "$pwd/._devcontainer_temp"
New-Item -ItemType Directory -Force -Path "$tempDir" > $null
Write-Host "Temp directory: $tempDir"

# Add a .gitignore file
$tempGitIgnore = "
*
../._devcontainer_temp
"
[IO.File]::WriteAllText("$tempDir/.gitignore", $tempGitIgnore)

# Copy config files
$targetBaseFolder="$tempDir\$devContainerBaseFolder"
New-Item -ItemType Directory -Force -Path "$targetBaseFolder" > $null
Write-Host
Write-Host "Copying:"
Write-Host "- $devContainerBaseFolder/.devcontainer"
Try {
    docker cp -L "${workspaceContainer}:${workspaceFolderInContainer}/${devContainerBaseFolder}/.devcontainer" "${targetBaseFolder}"
} Catch {
    Write-Host "Failed to copy .devcontainer folder. Valid path?"
    exit 1
}
$commonConfigList = Get-Content -Path "$PSScriptRoot\common-config.list"
ForEach ($contentPath in $commonConfigList) {
    Write-Host "- $contentPath"
    Try {
        docker cp -L "${workspaceContainer}:${workspaceFolderInContainer}/${contentPath}" "${tempDir}" 2>$null
    } Catch {
        Write-Host "   (Skipping $contentPath. Not found.)"
    }
}

Write-Host
Write-Host "Launching VS Code..."
code --force-user-env --disable-workspace-trust --skip-add-to-recently-opened "${targetBaseFolder}"


