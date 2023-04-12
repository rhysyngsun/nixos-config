{ pkgs, ... }:
let 
  rice = pkgs.rice;
in
{
  programs.alacritty.settings = {
    import = [
      "${rice.alacritty.config}"
    ];
    window = {
      inherit (rice) opacity;
    };
  };
}
