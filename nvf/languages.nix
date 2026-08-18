{ pkgs, lib, ... }:
let
  inherit (lib.generators) mkLuaInline;
in
{
  config.vim = {
    languages = {
      enableDAP = true;
      enableExtraDiagnostics = true;
      enableFormat = true;
      enableTreesitter = true;

      bash.enable = true;
      go.enable = true;
      html.enable = true;
      java.enable = true;
      lua.enable = true;
      nix.enable = true;
      markdown.enable = true;
      pkl = {
        enable = true;
        lsp.server = "brine";
      };
      python = {
        enable = true;
        lsp.servers = [ "basedpyright" ];
      };
      rust.enable = true;
      sql = {
        enable = true;
        extensions.sqls-nvim.enable = true;
      };
      templ.enable = true;
      typescript.enable = true;
      yaml.enable = true;
      zig.enable = true;
    };
    lsp.servers.sqls = {
      cmd = lib.mkForce [
        "${pkgs.sqls}/bin/sqls"
        "-config"
        ".sqls.yml"
      ];
    };

    treesitter.queries = [
      {
        # Inject SQL into Rust string literals.
        #
        # Three things that make hand-written injections fail silently:
        #
        # 1. Since nvim 0.9 only the `@injection.content` capture is honoured
        #    (`languagetree.lua:_get_injection`). The older `@<lang>` capture form -
        #    still used by e.g. go.nvim's queries - is parsed fine and then ignored.
        # 2. `#match?` patterns are *Vim* regexes, auto-prefixed with `\v` (very
        #    magic), not PCRE. So `%(...)` is a non-capturing group, `>` is
        #    end-of-word, `\l` is a lowercase letter and `\c` means ignore-case.
        # 3. tree-sitter's query parser decodes escapes inside `"..."` and drops the
        #    backslash of anything it does not know, so every backslash meant for the
        #    Vim regex must be written doubled here. `\_s` also refuses to match a
        #    bare newline in match_str(), hence `[[:space:]]` for the leading run.
        #    `#gsub!` is the exception - it takes a *Lua* pattern, so `%s` there.
        #
        # `string_content` is the inner node of both `string_literal` and
        # `raw_string_literal`, so the quotes and the `r#` sigil are already excluded
        # and no `#offset!` fixup is needed.
        #
        # nvf emits the `; extends` modeline itself for loadtype = "extends"; adding
        # another one here would just be a comment.
        filetypes = [ "rust" ];
        loadtype = "extends";
        type = "injections";
        query = ''
          ; Heuristic: require a leading verb *and* a matching clause keyword, so that
          ; ordinary prose ("update available", "select a file") is not parsed as SQL.
          ; Anything this misses - `"SELECT 1;"` and friends - can be annotated with a
          ; comment instead; see the last pattern.
          ((string_content) @injection.content
            (#match? @injection.content "\\c^[[:space:]]*%(select|insert|update|delete|with)>\\_.*%(from|into|values|set|where)>")
            (#set! injection.language "sql"))

          ((string_content) @injection.content
            (#match? @injection.content "\\c^[[:space:]]*%(create|alter|drop|truncate)[[:space:]]+%(table|index|view|materialized|schema|database|sequence|type|function|trigger)>")
            (#set! injection.language "sql"))

          ; Explicit escape hatch: a comment holding nothing but a language name forces
          ; the injection on the string that follows it. All of these work -
          ;
          ;   let a = /* sql */ "SELECT 1;";
          ;   let b = /*sql*/ r#"SELECT 1;"#;
          ;   // sql
          ;   let c = "SELECT 1;";
          ;   conn.query_one(/* sql */ "SELECT 1;", (), |_| Ok(1))
          ;
          ; The language is read out of the comment rather than hard-coded, so
          ; `/* json */`, `/* graphql */` etc. come along for free. A comment that is
          ; not a language name (`/* fixme */`) simply fails to resolve and injects
          ; nothing. The comment must be the string's immediate sibling, or the
          ; immediate sibling of the `let` that binds it - a comment two statements up
          ; will not carry over.
          (([(line_comment) (block_comment)] @injection.language
             .
             [(string_literal (string_content) @injection.content)
              (raw_string_literal (string_content) @injection.content)
              (let_declaration
                value: [(string_literal (string_content) @injection.content)
                        (raw_string_literal (string_content) @injection.content)])])
            (#match? @injection.language "\\c^%(//|/\\*)[[:space:]]*\\l+[[:space:]]*%(\\*/)?[[:space:]]*$")
            (#gsub! @injection.language "[/*%s]" ""))
        '';
      }
    ];

    keymaps = [
      {
        mode = "n";
        key = "gd";
        action = "vim.lsp.buf.hover";
        lua = true;
      }
      {
        mode = "n";
        key = "gD";
        action = "vim.lsp.buf.declaration";
        lua = true;
      }
      {
        mode = "n";
        key = "gi";
        action = "vim.lsp.buf.implementation";
        lua = true;
      }
    ];

    lazy.plugins.nvim-whichpy = {
      package = pkgs.vimUtils.buildVimPlugin {
        pname = "nvim-whichpy";
        version = "latest";
        src = pkgs.fetchFromGitHub {
          owner = "neolooong";
          repo = "whichpy.nvim";
          rev = "8bc5ca0d22d0f6686425c905850cf6ddeda51445";
          hash = "sha256-Hm72XJN45o8sqGufLp/18tusfcpsumnOvQc1gsZZerQ=";
        };
        doCheck = false;
      };

      setupModule = "whichpy";

      ft = [ "python" ];

      cmd = [ "WhichPy" ];
    };
  };
}
