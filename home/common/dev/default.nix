{ pkgs, ... }:
{
  imports = [
    ./alacritty
    ./git
    ./godot
    ./neovim.nix
    ./nodejs
    # ./ol-local
    ./python
    ./tmux.nix
    ./zsh
  ];

  home = {
    packages = with pkgs; [
      gaphor

      heroku
      http-prompt
      httpie
      jq
      just
      usql
      gnumake
      sphinx

      nnn

      # virtualization
      lazydocker
      vagrant

      doggo

      devenv
    ];
    sessionPath = [ "$HOME/bin" ];
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
      profiles = {};
    };
  };

  programs.vscode.userSettings = {
    "editor.formatOnType" = true;
  };
}
