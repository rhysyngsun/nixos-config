{pkgs, ...}: {
  programs.nvf = {
    settings = {
      vim = {
        lsp.servers = {
          # jinja_lsp = {
          #   cmd = ["${pkgs.jinja-lsp}/bin/jinja-lsp"];
          # };
        };
      };
    };
  };
}
