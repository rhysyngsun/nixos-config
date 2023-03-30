{ options, config, ... }:


let 
  cfg = config.modules.open-learning;
in {
  options.modules.open-learning = {
    enable = mkEnableOption {
      help = "Enable Open Learning development."
    }
  };
  config = mkIf cfg.{
    networking.extraHosts = concatLines [
      builtins.readFile ./hosts/open-learning.hosts
      builtins.readFile ./hosts/reddit.hosts
    ];
  };
}