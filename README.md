# Compose2Nix Flake Generator

This repository contains a Bash script that automates the generation of a Nix flake for `compose2nix`, enabling declarative infrastructure management for Docker or Podman-based projects using Nix.

## 🔧 Features

- Automatically detects `docker-compose.yml`/`.yaml` and `.env` files in a specified project directory
- Supports both Docker and Podman runtimes
- Generates a `flake.nix` with a runnable `nix run` entry point
- Stores the `compose2nix` output in a fixed path (customizable)

## 🚀 Usage

### 1. Prerequisites

Ensure you have the following installed:

- **Nix** (with flakes enabled)
- **Docker** or **Podman** (depending on the runtime you choose)
- Git

### 2. Run the Script

```bash
./your-script-name.sh -p <projectRoot> [-r docker|podman]
```

#### Parameters

- `-p <projectRoot>` (required): Path to the root of the project containing `docker-compose` files
- `-r <runtime>` (optional): Specify `docker` (default) or `podman`

#### Example

```bash
./generate-flake.sh -p ~/projects/my-app -r podman
```

This will:

1. Change to the `~/projects/my-app` directory
2. Scan for `docker-compose` and `.env` files
3. Generate a `flake.nix` that runs `compose2nix` using those files
4. Save the output Nix file to:

```
/mnt/data/oci-containers/my-app.nix
```

> **Note**: Update `output_path` in the script if you want to change this location.

### 3. Run the Flake

After generating the `flake.nix`, simply run:

```bash
nix run
```

This will execute the `compose2nix` conversion and save the resulting Nix expression to the specified path.

## 🗂 Output

- `flake.nix`: A fully functional Nix flake generated in the project directory
- `*.nix` output file: The result of `compose2nix`, saved under `/mnt/data/oci-containers/<project>.nix`

## 🛠 Customization

You may edit the following line in the script to customize where the output is saved:

```bash
output_path="/mnt/data/oci-containers/${projectName}.nix"
```

## 📝 License

This project uses the [`compose2nix`](https://github.com/aksiksi/compose2nix) tool by [@aksiksi](https://github.com/aksiksi). Be sure to review its license and usage terms.
