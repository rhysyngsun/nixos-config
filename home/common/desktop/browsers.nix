{

  programs.chromium.enable = true;
  programs.firefox = {
    enable = true;

    profiles = {
      Default = {
        id = 0;
        isDefault = true;

        settings = {
          "network.protocol-handler.expose.magnet" = true;
        };
      };
    };
  };
}
