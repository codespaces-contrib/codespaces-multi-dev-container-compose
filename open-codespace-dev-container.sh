#/usr/env/bin bash
set -e

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DEVCONTAINER_BASE_FOLDER="${1:-"."}"
export DOCKER_HOST="tcp://localhost:${2:-9256}"
BOOTSTRAP_ROOT_FOLDER="${3:-"/workspace"}"

workspace_container="$(docker ps -q --filter "label=com.github.codespaces.active.workspace=true")"
export COMPOSE_PROJECT_NAME="$(docker inspect -f '{{ index .Config.Labels "com.docker.compose.project" }}' ${workspace_container})"

temp_dir="$(pwd)/._devcontainer_temp"
mkdir -p "${temp_dir}"
cat << 'EOF' > "${temp_dir}/.gitignore"
*
../._devcontainer_temp
EOF

echo "Boostrap container ID: ${workspace_container}"
echo "Temp directory: ${temp_dir}"

# Copy config files
echo
echo "Copying:"
while IFS= read -r content_path; do
    echo "- ${content_path}"
    docker cp -L "${workspace_container}:${BOOTSTRAP_ROOT_FOLDER}/${content_path}" "${temp_dir}"
done < common-config.list
echo "- ${DEVCONTAINER_BASE_FOLDER}/.devcontainer"
target_base_folder="${temp_dir}/${DEVCONTAINER_BASE_FOLDER}"
mkdir -p "${target_base_folder}"
docker cp -L "${workspace_container}:${BOOTSTRAP_ROOT_FOLDER}/${DEVCONTAINER_BASE_FOLDER}/.devcontainer" "${target_base_folder}"

echo
echo "Launching VS Code..."
code --force-user-env --disable-workspace-trust --skip-add-to-recently-opened "${target_base_folder}"
