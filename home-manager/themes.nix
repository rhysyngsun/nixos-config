{ pkgs, config, lib, ... }:

with lib;

let 
  flavor = "Mocha";
  accent = "Lavender";
  flavorLower = toLower flavor;
  accentLower = toLower accent;        
  gtkTheme = {
    name = "Catppuccin-${flavor}-Compact-${accent}-Dark";
    package = pkgs.unstable.catppuccin-gtk.override {
      accents = [ accentLower ];
      size = "compact";
      tweaks = [ "rimless" "black" ];
      variant = flavorLower;
    };
  };
in 
{
  home.pointerCursor = {
    name = "Catppuccin-${flavor}-${accent}-Cursors";
    package = pkgs.catppuccin-cursors."${flavorLower}${accent}";
  };

  programs.neovim = {
    extraConfig = ''
    colorscheme catppuccin-${flavorLower}
    '';

    plugins = with pkgs.vimPlugins; [
      catppuccin-nvim
    ];
  };

  # vscode
  programs.vscode = {
    extensions = with pkgs.vscode-extensions; [
      catppuccin.catppuccin-vsc
    ];

    userSettings = {
      "window.titleBarStyle" = "custom";
      "workbench.colorTheme" = "Catppuccin ${flavor}";
      "catppuccin.accentColor" = accentLower;
      # use your accent on the statusBar as well
      "catppuccin.customUIColors"."${flavorLower}"."statusBar.foreground" ="accent";
    };
  };

  xdg.dataFile."rofi/themes".source = (pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "rofi";
    rev = "5350da41a11814f950c3354f090b90d4674a95ce";
    hash = "sha256-DNorfyl3C4RBclF2KDgwvQQwixpTwSRu7fIvihPN8JY=";
  }) + "/.local/share/rofi/themes";
  programs.rofi.theme = "catppuccin-${flavorLower}";

  # alacrity
  xdg.configFile."alacritty/catppuccin".source = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "alacritty";
    rev = "3c808cbb4f9c87be43ba5241bc57373c793d2f17";
    hash = "sha256-w9XVtEe7TqzxxGUCDUR9BFkzLZjG8XrplXJ3lX6f+x0=";
  };
  programs.alacritty.settings = {
    import = [
      "$XDG_CONFIG_DIR/alacritty/catppuccin/catppuccin-${flavorLower}.yml"
    ];
  };

  gtk = {
    enable = true;
    theme = gtkTheme;
  };

  # background theming
  xdg.dataFile."backgrounds" = {
    source = ../backgrounds;
    recursive = true;
  };
  services.random-background = {
    enable = true;
    imageDirectory = "${config.xdg.dataHome}/backgrounds/";
    interval = "1h";
  };
}