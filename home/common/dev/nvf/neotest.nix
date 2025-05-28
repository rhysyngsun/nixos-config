{
  pkgs,
  lib,
  ...
}: let
  inherit (lib.generators) mkLuaInline;
in {
  programs.nvf.settings.vim = with pkgs.unstable.vimPlugins; {
    lazy.plugins = {
      "neotest" = {
        package = neotest;
        setupModule = "neotest";
        lazy = true;
        setupOpts = {
          adapters =
            mkLuaInline
            # lua
            ''
              {
                require("neotest-golang")({}),
                require("neotest-jest")({}),
                require("neotest-python")({}),
                require("neotest-rust")({}),
                require("neotest-zig")({}),
              }
            '';
        };
      };
    };
    extraPackages = [
      neotest-golang
      neotest-jest
      neotest-python
      neotest-rust
      neotest-zig
    ];
    keymaps = [
      {
        key = "<leader>ta";
        mode = ["n" "v"];
        action =
          # lua
          ''function() require("neotest").run.attach() end'';
        desc = "[t]est [a]ttach";
        lua = true;
      }
      {
        key = "<leader>tf";
        mode = ["n" "v"];
        action =
          # lua
          ''function() require("neotest").run.run(vim.fn.expand("%")) end'';
        desc = "[t]est run [f]ile";
        lua = true;
      }
      {
        key = "<leader>tA";
        mode = ["n" "v"];
        action =
          # lua
          ''function() require("neotest").run.run(vim.uv.cwd()) end'';
        desc = "[t]est [A]ll files";
        lua = true;
      }
      {
        key = "<leader>tS";
        mode = ["n" "v"];
        action =
          # lua
          ''function() require("neotest").run.run({ suite = true }) end'';
        desc = "[t]est [S]uite";
        lua = true;
      }
      {
        key = "<leader>tn";
        mode = ["n" "v"];
        action =
          # lua
          ''function() require("neotest").run.run() end'';
        desc = "[t]est [n]earest";
        lua = true;
      }
      {
        key = "<leader>tl";
        mode = ["n" "v"];
        action =
          # lua
          ''function() require("neotest").run.run_last() end'';
        desc = "[t]est [l]ast";
        lua = true;
      }
      {
        key = "<leader>ts";
        mode = ["n" "v"];
        action =
          # lua
          ''function() require("neotest").summary.toggle() end'';
        desc = "[t]est [s]ummary";
        lua = true;
      }
      {
        key = "<leader>to";
        mode = ["n" "v"];
        action =
          # lua
          ''function() require("neotest").output.open({ enter = true, auto_close = true }) end'';
        desc = "[t]est [o]utput";
        lua = true;
      }
      {
        key = "<leader>tO";
        mode = ["n" "v"];
        action =
          # lua
          ''function() require("neotest").output_panel.toggle() end'';
        desc = "[t]est [O]utput panel";
        lua = true;
      }
      {
        key = "<leader>tt";
        mode = ["n" "v"];
        action =
          # lua
          ''function() require("neotest").run.stop() end'';
        desc = "[t]est [t]erminate";
        lua = true;
      }
      {
        key = "<leader>td";
        mode = ["n" "v"];
        action =
          # lua
          ''function() require("neotest").run.run({ suite = false, strategy = "dap" }) end'';
        desc = "Debug nearest test";
        lua = true;
      }
      {
        key = "<leader>tD";
        mode = ["n" "v"];
        action =
          # lua
          ''function() require("neotest").run.run({ vim.fn.expand("%"), strategy = "dap" }) end'';
        desc = "Debug current file";
      }
    ];
  };
}
