param (
    $devContainerRelativePath='.',
    $dockerHostPort='9256',
    $workspaceFolderInContainer='unknown'
)

$ErrorActionPreference = "Stop"

$env:DOCKER_HOST = "tcp://localhost:$dockerHostPort"

# Find boostrap container
$bootstrapContainer = (docker ps -q --filter "label=com.github.codespaces.active.workspace=true") -join ''
Write-Host "Boostrap container ID: $bootstrapContainer"

# Set compose project name if one exists on boostrap container
$composeProjectName = (docker inspect -f '{{ index .Config.Labels \"com.docker.compose.project\" }}' ${bootstrapContainer}) -join ''
if ($composeProjectName -ne "" ) {
    Write-Host "Compose project name: $composeProjectName"
    $env:COMPOSE_PROJECT_NAME=$composeProjectName
}

# Determine where workspace exists in boostrap container
if ($workspaceFolderInContainer -eq "unknown") {
    $workspaceFolderInContainer = (docker exec -i $bootstrapContainer /bin/sh -c "cat /tmp/__boostrap_container_workspace_folder") -join ''
    Write-Host "Workspace folder in container: $workspaceFolderInContainer" 
}


# Create a temp directory in the current folder - ensures we don't hit trusted workspace issues
$tempDir = "$pwd/._devcontainer_temp"
New-Item -ItemType Directory -Force -Path "$tempDir" > $null
Write-Host "Temp directory: $tempDir"
$tempDevContainerFolder="$tempDir\$devContainerRelativePath"
Write-Host "Temp dev container path: $tempDevContainerFolder"
$tempGitIgnore = "
*
.
"
[IO.File]::WriteAllText("$tempDir/.gitignore", $tempGitIgnore)

# Copy config files
New-Item -ItemType Directory -Force -Path "$tempDevContainerFolder" > $null
Write-Host
Write-Host "Copying:"
Write-Host "- $devContainerRelativePath/.devcontainer"
Try {
    docker cp -L "${bootstrapContainer}:${workspaceFolderInContainer}/${devContainerRelativePath}/.devcontainer" "${tempDevContainerFolder}"
} Catch {
    Write-Host "Failed to copy .devcontainer folder. Valid path?"
    exit 1
}
$commonConfigList = Get-Content -Path "$PSScriptRoot\common-config.list"
ForEach ($contentPath in $commonConfigList) {
    Write-Host "- $contentPath"
    Try {
        docker cp -L "${bootstrapContainer}:${workspaceFolderInContainer}/${contentPath}" "${tempDir}" 2>$null
    } Catch {
        Write-Host "   (Skipping $contentPath. Not found.)"
    }
}

$tempDevContainerJsonFile = "$tempDevContainerFolder/.devcontainer/devcontainer.json"
$devContainerJsonRaw = [IO.File]::ReadAllText($tempDevContainerJsonFile)
$devContainerJsonRaw = $devContainerJsonRaw -replace "//.*"," "
$devContainerJson = ConvertFrom-Json -Input-Object $devContainerJsonRaw
if (!$devContainerJson.dockerComposeFile) {
    $workspacMountSource=(docker inspect -f '{{range .HostConfig.Mounts}}{{if eq .Target "/workspaces"}}{{.Source}}{{end}}{{end}}' ${bootstrapContainer}) -join ''
    if ($workspacMountSource -eq "") {
        $workspacMountSource = "/var/lib/docker/codespacemount/workspace"
    }
    Write-Host "Workspace mount source: ${workspaceMountSource}"
    $devContainerJson.workspaceFolder = "${workspaceFolderInContainer}/${devcontainerRelativePath}"
    $devContainerJson.workspaceMount = "source=${workspaceMountSource},destination=/workspaces,type=bind"
    [IO.File]::WriteAllText("${tempDevContainerJsonFile}", ConvertTo-Json -Input-Object $devContainerJson)
}

Write-Host
Write-Host "Launching VS Code..."
code --force-user-env --disable-workspace-trust --skip-add-to-recently-opened "${tempDevContainerFolder}"
Write-Host
Write-Host "Press F1 or Cmd/Ctrl+Shift+P and select the Remote-Containers: Reopen in Container in the new VS Code window to connect."
Write-Host

