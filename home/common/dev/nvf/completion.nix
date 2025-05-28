{lib, ...}: let
  inherit (lib.generators) mkLuaInline;
in {
  programs.nvf.settings.vim.autocomplete = {
    enableSharedCmpSources = true;
    blink-cmp = {
      enable = true;
      friendly-snippets.enable = true;
      setupOpts = {
        keymap.preset = "default";
        completion = {
          menu = {
            auto_show = true;
          };
        };
        completion = {
          menu = {
            # border = "single";

            draw = {
              columns =
                mkLuaInline
                # lua
                ''
                  {
                    { "label", "label_description", gap = 3 },
                    { "kind_icon", "kind" , gap = 1},
                    { "source_name" },
                  }
                '';
              components = {
                source_name.text =
                  mkLuaInline
                  # lua
                  ''
                    function (ctx)
                      return "[" .. ctx.source_name .. "]"
                    end
                  '';
              };
            };
          };
          documentation = {
            window = {
              # border = "single";
            };
          };
        };
        signature = {
          enabled = true;
          window = {
            border = "single";
          };
        };
        sources = {
          default = [
            "lsp"
            "path"
            "snippets"
            "buffer"
          ];
          providers.lsp = {
            fallbacks = [];
          };
        };
      };
    };
  };
}
