{ ... }:
{
  flake.modules.homeManager.programs-devtools =
    { pkgs, ... }:
    {
      home = {
        packages = with pkgs; [
          pkgs-unstable.heroku
          xh
          just
          grc
          usql
          gnumake
          git-ignore
          lazygit
          entr
          tealdeer
          libtree
          squirrel-sql

          # http request cli's
          httpie
          pkgs-unstable.posting

          # jq/xq/yq all-in-one
          yq-go
          jq

          sphinx

          cachix

          k3d
          kubectl
          headlamp
          kubernetes-helm
          awscli2
          k6

          # virtualization
          lazydocker
          vagrant

          bytecode-viewer
          zensical

          # concourse cli
          fly
        ];
        sessionPath = [ "$HOME/bin" ];
        shellAliases = {
          ".." = "cd ..";
          "..." = "cd ../..";
          "...." = "cd ../../..";
          "....." = "cd ../../../..";
          "rm" = "rm -I --preserve-root";
        };
      };

      home.file.".cargo/config.toml".text = ''
        [net]
        git-fetch-with-cli = true
      '';
    };
}
