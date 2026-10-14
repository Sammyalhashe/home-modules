{
  flake.modules.homeManager.quickNotes =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.quickNotes;

      quickNote = pkgs.writeShellApplication {
        name = "quick-note";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
          # @vicinae.schemaVersion 1
          # @vicinae.title Quick Note
          # @vicinae.mode silent
          # @vicinae.icon 📝
          # @vicinae.argument1 {"type": "text", "placeholder": "Note"}

          note=$1
          notes_dir=${lib.escapeShellArg cfg.notesDir}
          stamp=$(date +%Y%m%d-%H%M%S)
          host=$(uname -n)
          host=''${host%%.*}

          mkdir -p "$notes_dir"
          file="$notes_dir/$stamp-$host.md"
          n=1
          # noclobber creates with O_EXCL, so a concurrent capture can never overwrite this one.
          until (set -o noclobber && printf '%s\n' "$note" >"$file") 2>/dev/null; do
            [ -e "$file" ] || {
              echo "Cannot write $file" >&2
              exit 1
            }
            file="$notes_dir/$stamp-$host-$n.md"
            n=$((n + 1))
          done
          echo "Saved $(basename "$file")"
        '';
      };
    in
    {
      options.programs.quickNotes = {
        enable = lib.mkEnableOption "a Vicinae script command that saves each quick note as its own markdown file";

        notesDir = lib.mkOption {
          type = lib.types.str;
          default = "${config.home.homeDirectory}/Nextcloud/Notes/Inbox";
          defaultText = lib.literalExpression ''"''${config.home.homeDirectory}/Nextcloud/Notes/Inbox"'';
          description = "Directory the notes are written to; created if missing.";
        };
      };

      config = lib.mkIf cfg.enable {
        # Vicinae scans <data home>/vicinae/scripts; on macOS that is always ~/.local/share.
        xdg.dataFile."vicinae/scripts/quick-note".source = lib.getExe quickNote;
      };
    };
}
