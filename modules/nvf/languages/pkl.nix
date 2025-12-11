{
  config,
  pkgs,
  pkgs-stable,
  lib,
  ...
}: let
  inherit (builtins) attrNames;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.lists) isList;
  inherit (lib.types) enum either listOf package str;
  inherit (lib.nvim.types) mkGrammarOption;
  inherit (lib.nvim.lua) expToLua;
  inherit (lib.nvim.dag) entryBefore;

  cfg = config.vim.languages.pkl;

  defaultServer = "pkl-lsp";
  servers = {
    pkl-lsp = {
      package = pkgs-stable.pkl-lsp;
      lspConfig =  /* lua */''
        lspconfig.pkl_lsp.setup {
          capabilities = capabilities;
          on_attach = default_on_attach;
          settings = {
            ["pkl.cli.path"] = "${pkgs.pkl}/bin/pkl",
          };
        }
      '';
    };
  };

in {
  options.vim.languages.pkl = {
    enable = mkEnableOption "Pkl language support";

    treesitter = {
      enable = mkEnableOption "Pkl treesitter" // {default = config.vim.languages.enableTreesitter;};

      package = mkGrammarOption pkgs "pkl";
    };

    lsp = {
      enable = mkEnableOption "Pkl LSP support" // {default = config.vim.lsp.enable;};

      server = mkOption {
        description = "Pkl LSP server to use";
        type = enum (attrNames servers);
        default = defaultServer;
      };

      package = mkOption {
        description = "Pkl LSP server package, or the command to run as a list of strings";
        example = ''[lib.getExe pkgs.pkl-lsp]'';
        type = either package (listOf str);
        default = servers.${cfg.lsp.server}.package;
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.treesitter.enable {
      vim.treesitter.enable = true;
      vim.treesitter.grammars = [
        (pkgs.tree-sitter.buildGrammar {
          language = "pkl";
          inherit (pkgs-stable.localSources.tree-sitter-pkl) src version;
        })
      ];

      vim.pluginRC.pkl_lsp = entryBefore ["pkl-lsp"] /* lua */ ''
        local function get_pkl_lsp_client()
          for _, c in ipairs(vim.lsp.get_clients()) do
            if c.name == "pkl" then
              return c
            end
          end
        end
        require("lspconfig.configs").pkl_lsp = {
          default_config = {
            cmd = ${
              if isList cfg.lsp.package
              then expToLua cfg.lsp.package
              else ''{"${cfg.lsp.package}/bin/pkl-lsp"}''
            },
            filetypes = { "pkl" };
            root_dir =
              vim.fs.root(0, '.pkl-lsp')
                or vim.fs.root(0, '.git')
                or vim.fs.root(0, 'PklProject'),
            settings = {
              ["pkl.cli.path"] = "${pkgs.pkl}/bin/pkl"
            };
            init_options = {
              extendedClientCapabilities = {
                actionableRuntimeNotifications = true,
                pklConfigureCommand = true
              }
            };
            commands = {
              ["pkl.syncProjects"] = function (_, _)
                local client = get_pkl_lsp_client()
                local buf = vim.api.nvim_get_current_buf()
                client:request("pkl/syncProjects", nil, function() end, buf)
              end,
              ["pkl.downloadPackage"] = function (cmd, _)
                local client = get_pkl_lsp_client()
                local packageUri = cmd.arguments[1]
                local buf = api.nvim_get_current_buf()
                client:request("pkl/downloadPackage", packageUri, function() end, buf)
              end
            };
          };
        }

        -- vim.api.nvim_create_autocmd('LspAttach', {
        --   callback = function(ev)
        --     local client = vim.lsp.get_client_by_id(ev.data.client_id)
        --
        --     if client.name == "pkl_lsp" then
        --       local buf = vim.api.nvim_get_current_buf()
        --       client:request("pkl/syncProjects", nil, function() end, buf)
        --     end
        --   end
        -- })
      '';

      vim.pluginRC.pkl_treesitter = entryBefore ["treesitter"] /* lua */ ''
        local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
        parser_config.pkl = {
          install_info = {
            url = "${cfg.treesitter.package}", -- local path or git repo
            files = {"src/parser.c", "src/scanner.c"}, -- note that some parsers also require src/scanner.c or src/scanner.cc
            -- optional entries:
            branch = "main", -- default branch in case of git repo if different from master
            generate_requires_npm = false, -- if stand-alone parser without npm dependencies
            requires_generate_from_grammar = false, -- if folder contains pre-generated src/parser.c
          },
          filetype = "pkl", -- if filetype does not match the parser name
        }
      '';
    })

    (mkIf cfg.lsp.enable {
      vim.lsp.lspconfig.enable = true;
      vim.lsp.lspconfig.sources.pkl-lsp = servers.${cfg.lsp.server}.lspConfig;
    })
  ]);
}
