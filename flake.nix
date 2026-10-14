{
  description = "Shared home-manager modules";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    # Only used by the eval checks; consumers should follow their own.
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Deliberately keeps its own nixpkgs: vicinae.cachix.org only has builds
    # against upstream's pin, so following ours would compile Vicinae locally.
    vicinae.url = "github:vicinaehq/vicinae";
    vicinae-extensions = {
      url = "github:vicinaehq/extensions";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.vicinae.follows = "vicinae";
      inputs.systems.follows = "vicinae/systems";
    };

    vicinae-quick-notes = {
      url = "github:Sammyalhashe/vicinae-quick-notes";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.vicinae.follows = "vicinae";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { config, lib, ... }:
      {
        imports = [
          flake-parts.flakeModules.modules
          ./modules/vicinae.nix
          ./modules/quick-notes.nix
        ];

        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
        ];

        # flake.modules sets no key, so importing default alongside a named module would duplicate it.
        flake.homeManagerModules =
          let
            keyed = lib.mapAttrs (name: module: {
              key = "home-modules#${name}";
              imports = [ module ];
            }) config.flake.modules.homeManager;
          in
          keyed // { default.imports = builtins.attrValues keyed; };

        perSystem =
          { pkgs, system, ... }:
          let
            home = inputs.home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              modules = [
                config.flake.homeManagerModules.default
                {
                  home.username = "check";
                  home.homeDirectory = if pkgs.stdenv.hostPlatform.isDarwin then "/Users/check" else "/home/check";
                  home.stateVersion = "26.05";
                  programs.vicinae.enable = true;
                  programs.quickNotes.enable = true;
                }
              ];
            };
          in
          {
            formatter = pkgs.nixfmt-tree;

            # Eval-only: forces the whole home configuration without building it.
            checks = {
              home-eval = pkgs.writeText "home-eval" (
                builtins.unsafeDiscardStringContext home.activationPackage.drvPath
              );
            };
          };
      }
    );
}
