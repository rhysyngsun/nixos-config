{ pkgs, lib, ... }:
{
  home.packages = with pkgs; [ungoogled-chromium ];

  programs = {
    firefox = {
      enable = true;
      profiles = {
        Default = {
          id = 0;
          isDefault = true;

          settings = {
            "network.protocol-handler.expose.magnet" = true;
          };

          extensions = with pkgs.nur.repos.rycee.firefox-addons; [
            bitwarden
            catppuccin-gh-file-explorer
            ebates
            firefox-color
            stylus
          ];

          search = {
            default = "DuckDuckGo";

            engines = {
              "Nix Packages" = {
                urls = [{
                  template = "https://search.nixos.org/packages";
                  params = [
                    { name = "type"; value = "packages"; }
                    { name = "query"; value = "{searchTerms}"; }
                  ];
                }];

                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = [ "@np" ];
              };
              "Nix Options" = {
                urls = [{
                  template = "https://search.nixos.org/options";
                  params = [
                    { name = "query"; value = "{searchTerms}"; }
                  ];
                }];

                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = [ "@no" ];
              };

              "NixOS Wiki" = {
                urls = [{ template = "https://wiki.nixos.org/index.php?search={searchTerms}"; }];
                iconUpdateURL = "https://wiki.nixos.org/favicon.png";
                updateInterval = 24 * 60 * 60 * 1000; # every day
                definedAliases = [ "@nw" ];
              };

              "GitHub Code" = {
                urls = [{ template = "https://github.com/search?q={searchTerms}&type=code"; }];
                iconUpdateURL = "https://github.githubassets.com/favicons/favicon.png";
                definedAliases = [ "@ghc" ];
              };
              "GitHub Repos" = {
                urls = [{ template = "https://github.com/search?q={searchTerms}&type=repositories"; }];
                iconUpdateURL = "https://github.githubassets.com/favicons/favicon.png";
                definedAliases = [ "@ghr" ];
              };
              "GitHub Issues" = {
                urls = [{ template = "https://github.com/search?q={searchTerms}&type=issues"; }];
                iconUpdateURL = "https://github.githubassets.com/favicons/favicon.png";
                definedAliases = [ "@ghi" ];
              };

              "Bing".metaData.hidden = true;
              "Google".metaData.hidden = true;
              "DuckDuckGo".definedAliases = lib.mkForce [ "@ddg" ];
            };
          };
        };
      };
    };
  };

  # stop asking about this
  home.file.".mozilla/firefox/Default/search.json.mozlz4".force = lib.mkForce true;
}
