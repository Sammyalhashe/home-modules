{ inputs, ... }:
{
  flake.modules.homeManager.quickNotes = inputs.vicinae-quick-notes.homeManagerModules.default;
}
