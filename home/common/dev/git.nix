{
  config,
  pkgs,
  ...
}:
{
  home = {
    packages = with pkgs; [
      gita
      pre-commit
    ];
  };

  programs = {
    gh = {
      # github CLI
      enable = true;
      # gitCredentialHelper.enable = true;
      settings = {
        git_protocol = "ssh";
      };
    };

    git = {
      enable = true;

      difftastic = {
        enable = true;
        # enableAsDifftool = true;
      };
      lfs.enable = true;

      ignores = [
        ".direnv/"
        ".envrc"
        ".devenv/"
        # "flake.nix"
        # "flake.lock"
      ];

      extraConfig = {
        advice.statusHints = false;

        alias = {
          # add
          a = "add"; # add
          chunkyadd = "add --patch"; # stage commits chunk by chunk

          # via http://blog.apiaxle.com/post/handy-git-tips-to-stop-you-getting-fired/
          snapshot = ''!git stash save "snapshot: $(date)" && git stash apply "stash@{0}"'';
          snapshots = "!git stash list --grep snapshot";

          #via http://stackoverflow.com/questions/5188320/how-can-i-get-a-list-of-git-branches-ordered-by-most-recent-commit
          recent-branches = "!git for-each-ref --count=15 --sort=-committerdate refs/heads/ --format='%(refname:short)'";

          # branch
          b = "branch -v"; # branch (verbose)

          # commit
          c = "commit -m"; # commit with message
          ca = "commit -am"; # commit all with message
          ci = "commit"; # commit
          amend = "commit --amend"; # amend your last commit
          ammend = "commit --amend"; # amend your last commit

          # checkout
          co = "checkout"; # checkout
          nb = "checkout -b"; # create and switch to a new branch (mnemonic: "git new branch branchname...")

          # cherry-pick
          cp = "cherry-pick -x"; # grab a change from a branch

          # diff
          d = "diff"; # diff unstaged changes
          dc = "diff --cached"; # diff staged changes
          last = "diff HEAD^"; # diff last committed change

          # log
          l = "log --graph --date=short";
          changes = "log --pretty=format:\"%h %cr %cn %Cgreen%s%Creset\" --name-status";
          short = "log --pretty=format:\"%h %cr %cn %Cgreen%s%Creset\"";
          simple = "log --pretty=format:\" * %s\"";
          shortnocolor = "log --pretty=format:\"%h %cr %cn %s\"";

          # pull
          pl = "pull"; # pull

          # push
          ps = "push"; # push

          # rebase
          rc = "rebase --continue"; # continue rebase
          rs = "rebase --skip"; # skip rebase

          # remote
          r = "remote -v"; # show remotes (verbose)

          # reset
          unstage = "reset HEAD"; # remove files from index (tracking)
          uncommit = "reset --soft HEAD^"; # go back before last commit, with files in uncommitted state
          filelog = "log -u"; # show changes to a file
          mt = "mergetool"; # fire up the merge tool

          # stash
          ss = "stash"; # stash changes
          sl = "stash list"; # list stashes
          sa = "stash apply"; # apply stash (restore changes)
          sd = "stash drop"; # drop stashes (destory changes)

          # status
          s = "status"; # status
          st = "status"; # status
          stat = "status"; # status

          # tag
          t = "tag -n"; # show tags with <n> lines of each tag message
        };

        apply.whitespace = "nowarn";

        branch.autosetupmerge = true;

        color = {
          ui = true;
          branch = {
            current = "yellow reverse";
            local = "yellow";
            remote = "green";
          };
          diff = {
            meta = "yellow bold";
            frag = "magenta bold";
            old = "red";
            new = "green";
          };
        };

        core = {
          autocrlf = false;
          editor = "nvim";
        };

        diff = {
          algorithm = "histogram";
          colorMoved = "default";
          tool = "difftastic";
        };

        difftool = {
          difftastic = {
            cmd = "${config.programs.git.iniContent.diff.external} $LOCAL $REMOTE";
          };
        };

        fetch = {
          prune = true;
          prunetags = true;
        };

        format.pretty = "format:%C(blue)%ad%Creset %C(yellow)%h%C(green)%d%Creset %C(blue)%s %C(magenta) [%an]%Creset";

        init.defaultBranch = "main";

        log.date = "iso";

        merge.conflictstyle = "zdiff3";

        push = {
          default = "upstream";
          autosetupremote = true;
        };

        url."git@github.com:".insteadOf = "https://github.com/";

        user = {
          name = "Nathan Levesque";
          email = "rhysyngsun@gmail.com";
        };
      };

      includes = [
        {
          contents = {
            user.email = "nlevesq@mit.edu";
          };
          condition = "hasconfig:remote.*.url:git@github.com:mitodl/**";
        }
      ];
    };
  };
}
