{
  description = "A flake that runs compose2nix with multiple compose files";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    compose2nix.url = "github:aksiksi/compose2nix";
  };

  outputs = { self, nixpkgs, compose2nix, ... }@inputs: {
    perSystem = { self', system, pkgs, ... }:
      let
        compose2nixPkg = compose2nix.packages.${system}.default;
        compose-files = [
          # Add more files here
        ];

        compose-files-str = builtins.concatStringsSep "," (builtins.map (path: toString path) compose-files);
      in {
        packages.default = pkgs.writeShellApplication {
          name = "run-compose2nix";
          runtimeInputs = [ compose2nixPkg ];
          text = ''
            set -e

            echo "Running compose2nix with inputs: ${compose-files-str}"

            compose2nix \
              -inputs="${compose-files-str}" \
              -project="home-manager" \
              -runtime="docker" \
              -output="../../modules/nixos/common/docker-containers.nix"
          '';
        };

        apps.default = {
          type = "app";
          program = "${self'.packages.default}/bin/run-compose2nix";
        };

        # Optional: for nix fmt
        formatter = pkgs.nixpkgs-fmt;
      };
  };
}