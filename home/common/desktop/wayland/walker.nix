{
  programs.walker = {
    enable = true;
    runAsService = true;

    config = {
      placeholders."default".input = "Example";
      providers.prefixes = [
        {provider = "websearch"; prefix = "+";}
        {provider = "providerlist"; prefix = "_";}
      ];
      keybinds.quick_activate = ["1" "2" "3" "4" "5"];
    };
  };
}
