{
  description = "homelab-platform";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    flake-parts.url = "github:hercules-ci/flake-parts/main";
    treefmt-nix.url = "github:numtide/treefmt-nix/main";
    devenv.url = "github:cachix/devenv/v1.9";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} ({self, ...}: {
      systems = ["aarch64-darwin" "aarch64-linux" "x86_64-darwin" "x86_64-linux"];

      perSystem = {
        pkgs,
        self',
        ...
      }: let
        treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs {
          projectRootFile = "flake.nix";

          programs = {
            alejandra.enable = true;
            prettier.enable = true;
          };
        };
      in {
        devShells.default = inputs.devenv.lib.mkShell {
          inherit inputs pkgs;

          modules = [
            {
              env = {
                BOOTSTRAP_PRIVATE_KEY = "op://VESELABS/homelab-platform Deploy key/password";
              };

              languages = {
                nix.enable = true;
                shell.enable = true;
              };

              packages =
                [
                  self'.formatter
                ]
                ++ builtins.attrValues {
                  inherit
                    (pkgs)
                    fluxcd
                    just
                    kubernetes-helm
                    ;
                };

              git-hooks.hooks = {
                deadnix.enable = true;
                end-of-file-fixer.enable = true;
                statix.enable = true;
                treefmt.enable = true;
                treefmt.package = self'.formatter;
                trim-trailing-whitespace.enable = true;
              };
            }
          ];
        };

        packages = {
          devenv-test = self'.devShells.default.config.test;
          devenv-up = self'.devShells.default.config.procfileScript;
        };

        formatter = treefmtEval.config.build.wrapper;
        checks.formatting = treefmtEval.config.build.check self;
      };
    });
}
