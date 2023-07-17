{ pkgs, ... }:
let 
  rice = pkgs.rice;
in
{
  programs.alacritty.settings = rice.alacritty.config // {
    window = {
      inherit (rice) opacity;
    };
  };
}
