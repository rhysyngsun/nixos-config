{ pkgs, ... }:
{
  imports = [
    ./alacritty
    ./git
    ./godot
    ./neovim
    # ./nodejs
    ./python
    ./tmux.nix
    ./wezterm
    ./yazi.nix
    ./zsh
  ];

  home = {
    packages = with pkgs; [
      heroku
      http-prompt
      xh
      just
      usql
      gnumake
      git-ignore
      entr
      tealdeer
      libtree

      # jq/xq/yq all-in-one
      yq-go

      sphinx
      copier

      # virtualization
      lazydocker
      vagrant

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

  services.pueue = {
    enable = true;
    settings = {
      client = {
        restart_in_place = false;
        read_local_logs = true;
        show_confirmation_questions = false;
        show_expanded_aliases = false;
        dark_mode = false;
        max_status_lines = null;
        status_time_format = "%H:%M:%S";
        status_datetime_format = ''
          %Y-%m-%d
          %H:%M:%S
        '';
      };
      daemon = {
        default_parallel_tasks = 2;
        pause_group_on_failure = false;
        pause_all_on_failure = false;
        callback = null;
        callback_log_lines = 10;
      };
      shared = {
        pueue_directory = null;
        runtime_directory = null;
        alias_file = null;
        use_unix_socket = true;
        unix_socket_path = null;
        host = "127.0.0.1";
        port = "6924";
        pid_path = null;
        daemon_cert = null;
        daemon_key = null;
        shared_secret_path = null;
      };
      profiles = { };
    };
  };

  home.file.".cargo/config.toml".text = ''
    [net]
    git-fetch-with-cli = true
  '';
}
