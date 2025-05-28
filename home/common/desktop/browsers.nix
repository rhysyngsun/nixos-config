{
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs; [ungoogled-chromium];

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

          extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
            bitwarden
            ebates
            firefox-color
            stylus
          ];

          search = {
            default = "ddg";

            engines = {
              np = {
                name = "Nix Packages";
                urls = [
                  {
                    template = "https://search.nixos.org/packages";
                    params = [
                      {
                        name = "type";
                        value = "packages";
                      }
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];

                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = ["@np"];
              };
              no = {
                name = "Nix Options";
                urls = [
                  {
                    template = "https://search.nixos.org/options";
                    params = [
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];

                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = ["@no"];
              };

              nw = {
                name = "NixOS Wiki";
                urls = [{template = "https://wiki.nixos.org/index.php?search={searchTerms}";}];
                icon = "https://wiki.nixos.org/favicon.png";
                updateInterval = 24 * 60 * 60 * 1000; # every day
                definedAliases = ["@nw"];
              };

              ghc = {
                name = "GitHub Code";
                urls = [{template = "https://github.com/search?q={searchTerms}&type=code";}];
                icon = "https://github.githubassets.com/favicons/favicon.png";
                definedAliases = ["@ghc"];
              };
              ghr = {
                name = "GitHub Repos";
                urls = [{template = "https://github.com/search?q={searchTerms}&type=repositories";}];
                icon = "https://github.githubassets.com/favicons/favicon.png";
                definedAliases = ["@ghr"];
              };
              ghi = {
                name = "GitHub Issues";
                urls = [{template = "https://github.com/search?q={searchTerms}&type=issues";}];
                icon = "https://github.githubassets.com/favicons/favicon.png";
                definedAliases = ["@ghi"];
              };

              bing.metaData.hidden = true;
              google.metaData.hidden = true;
              ddg.definedAliases = lib.mkForce ["@ddg"];
            };
          };
        };
      };
    };
  };

  # stop asking about this
  home.file.".mozilla/firefox/Default/search.json.mozlz4".force = lib.mkForce true;
}
