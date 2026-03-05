{
  description = "homelab-platform";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    flake-parts.url = "github:hercules-ci/flake-parts/main";
    devenv.url = "github:cachix/devenv/v2.0";
    treefmt-nix.url = "github:numtide/treefmt-nix/main";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["aarch64-darwin" "aarch64-linux" "x86_64-darwin" "x86_64-linux"];

      perSystem = {
        pkgs,
        system,
        ...
      }: {
        devShells.default = inputs.devenv.lib.mkShell {
          inherit inputs pkgs;

          modules = [
            {
              env = {
                BOOTSTRAP_PRIVATE_KEY = "op://veselabs/homelab-platform deploy key/password";
                ONEPASSWORD_TOKEN = "op://veselabs/service account auth token/credential";
              };

              languages = {
                nix.enable = true;
                shell.enable = true;
              };

              packages = builtins.attrValues {
                inherit
                  (pkgs)
                  _1password-cli
                  fluxcd
                  just
                  kubernetes-helm
                  pre-commit
                  ;
              };

              treefmt = {
                enable = true;
                config = {
                  programs = {
                    alejandra.enable = true;
                    prettier.enable = true;
                  };
                };
              };

              git-hooks.hooks = {
                deadnix.enable = true;
                end-of-file-fixer.enable = true;
                statix.enable = true;
                treefmt.enable = true;
                trim-trailing-whitespace.enable = true;
                yamllint.enable = true;
              };
            }
          ];
        };

        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      };
    };
}
