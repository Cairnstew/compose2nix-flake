#!/bin/bash

# Enable strict mode for better error handling
set -euo pipefail

# Default value for runtime
runtime="docker"

# Function to display usage/help
usage() {
  echo "Usage: $0 -path <projectRoot> [-runtime docker|podman]"
  exit 1
}

# Parse flags
while getopts "p:r:" opt; do
  case "$opt" in
    p) projectRoot="$OPTARG" ;;  # Set projectRoot flag (-p)
    r) runtime="$OPTARG" ;;       # Set runtime flag (-r)
    *) usage ;;                   # Call usage if an invalid flag is provided
  esac
done

# Validate if projectRoot is provided
if [[ -z "${projectRoot:-}" ]]; then
  echo "❌ Error: Project root directory is required! Use -path <projectRoot>."
  exit 1
fi

# Validate runtime input
if [[ "$runtime" != "docker" && "$runtime" != "podman" ]]; then
  echo "❌ Invalid runtime: $runtime"
  echo "   Valid options: docker, podman"
  exit 1
fi

# Validate if the projectRoot exists
if [[ -d "$projectRoot" ]]; then
  echo "📂 Changing directory to: $projectRoot"
  cd "$projectRoot" || exit 1
else
  echo "❌ Project directory '$projectRoot' does not exist!"
  exit 1
fi

projectName=$(basename "$(realpath "$projectRoot")")

output_path="/mnt/data/oci-containers/${projectName}.nix" # CHANGE THIS 

# Output start message
echo "======================================================"
echo "🚀 Starting compose2nix generation for project: ${projectName}"
echo "======================================================"
echo ""

# Get the list of files in the project directory
dirContents=$(ls)

# Filter for docker-compose and env files
compose_files=()
env_files=()
absolute_path=$(realpath ./.)

# Loop through the contents and find relevant files
for file in $dirContents; do
    if [[ "$file" == "docker-compose.yml" || "$file" == "docker-compose.yaml" ]]; then
        compose_files+=("$file")
    elif [[ "$file" == ".env" ]]; then
        env_files+=("$file")
    fi
done

# Generate paths for compose files
compose_file_paths=()
for file in "${compose_files[@]}"; do
    compose_file_paths+=("$absolute_path/$file")
done

# Convert compose file paths to string, comma-separated
compose_files_str=$(IFS=,; echo "${compose_file_paths[*]}")

# Generate paths for env files
env_file_paths=()
for file in "${env_files[@]}"; do
    env_file_paths+=("$absolute_path/$file")
done

# Convert env file paths to string, comma-separated
env_files_str=$(IFS=,; echo "${env_file_paths[*]}")

# Assign variables for easier reference
compose_files="${compose_files_str}"
env_files="${env_files_str}"

# Output directory information
echo "📂 Project directory: ${absolute_path}"
echo "🔍 Scanning for docker-compose files..."
echo "📝 Found compose files:"
echo "$compose_files" | tr ',' '\n'

echo ""
if [ -n "$env_files" ]; then
    echo "🧪 Found .env files:"
    echo "$env_files" | tr ',' '\n'
else
    echo "⚠️  No .env files found."
fi

cat > "flake.nix" <<EOF
{
  description = "A flake that runs compose2nix with multiple compose files";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    compose2nix.url = "github:aksiksi/compose2nix";
  };

  outputs = { self, nixpkgs, compose2nix, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
    compose2nixPkg = compose2nix.packages.\${system}.default;

  in {
    packages.\${system}.default = pkgs.writeShellApplication {
      name = "run-compose2nix";
      runtimeInputs = [ compose2nixPkg ];
      text = ''

        echo ""
        echo "🔧 Running compose2nix..."
        compose2nix \\
          -inputs="${compose_files}" \\
          -env_files="${env_files}" \\
          -project="${projectName}" \\
          -runtime="${runtime}" \\
          -output="${output_path}"

        echo ""
        echo "✅ compose2nix generation complete!"
        echo "📦 Output saved to: ${output_path}"
        echo "======================================================"
      '';
    };

    apps.\${system}.default = {
      type = "app";
      program = "\${self.packages.\${system}.default}/bin/run-compose2nix";
    };
  };
}
EOF

nix run 