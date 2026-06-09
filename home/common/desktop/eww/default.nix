{ pkgs, ... }:

{
  programs.eww = {
    enable = true;
    yuckConfig = builtins.readFile ./_config/eww.yuck;
    scssConfig = builtins.readFile ./_config/eww.scss;
  };
}
