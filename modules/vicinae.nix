{ inputs, ... }:
{
  flake.modules.homeManager.vicinae =
    { lib, pkgs, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) isLinux isDarwin system;
      extensions = inputs.vicinae-extensions.packages.${system};
    in
    {
      imports = [ inputs.vicinae.homeManagerModules.default ];

      programs.vicinae = lib.mkMerge [
        {
          settings = {
            close_on_focus_loss = true;
            consider_preedit = true;
            pop_to_root_on_close = true;
            favicon_service = "twenty";
            search_files_in_root = true;
            launcher_window = {
              # Stylix sets the opacity too.
              opacity = lib.mkForce 0.98;
            };
          };
          extensions = [ extensions.nix ];
        }

        (lib.mkIf isLinux {
          systemd = {
            enable = true;
            autoStart = true;
            environment = {
              USE_LAYER_SHELL = 1;
            };
          };
          extensions = [ extensions.power-profile ];
        })

        (lib.mkIf isDarwin {
          launchd = {
            enable = true;
            autoStart = true;
          };
        })
      ];
    };
}
