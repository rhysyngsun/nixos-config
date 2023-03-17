{
  # Git
  g = "git";
  gs = "git status";
  gstsh = "git stash";
  gst = "git stash";
  gsp = "git stash pop";
  gsa = "git stash apply";
  gsh = "git show";
  gshw = "git show";
  gshow = "git show";
  gi = "vim .gitignore";
  gcm = "git ci -m";
  gcim = "git ci -m";
  gc = "git commit";
  gci = "git ci";
  gco = "git co";
  gcp = "git cp";
  ga = "git add -A";
  guns = "git unstage";
  gunc = "git uncommit";
  gm = "git merge";
  gms = "git merge --squash";
  gam = "git amend --reset-author";
  grv = "git remote -v";
  grr = "git remote rm";
  grad = "git remote add";
  gr = "git rebase";
  gra = "git rebase --abort";
  ggrc = "git rebase --continue";
  gbi = "git rebase --interactive";
  grm = "git fetch origin ; git rebase origin/master";
  gl = "git l";
  glg = "git l";
  glog = "git l";
  co = "git co";
  gf = "git fetch";
  gfch = "git fetch";
  gd = "git diff";
  gb = "git b";
  gbd = "git b -D -w";
  gdc = "git diff --cached -w";
  gpub = "grb publish";
  gtr = "grb track";
  gpl = "git pull";
  gplr = "git pull --rebase";
  gps = "git push";
  gpsh = "git push -u origin `git rev-parse --abbrev-ref HEAD`";
  gnb = "git nb"; # new branch aka checkout -b
  grs = "git reset";
  grsh = "git reset --hard";
  gcln = "git clean";
  gclndf = "git clean -df";
  gclndfx = "git clean -dfx";
  gsm = "git submodule";
  gsmi = "git submodule init";
  gsmu = "git submodule update";
  gt = "git t";
  gbg = "git bisect good";
  gbb = "git bisect bad";
  grb = "git recent-branches";

  # Custom
  ip = "ifconfig en1 | grep inet | grep -v inet6 | cut -d \" \" -f 2";
  clip = "xclip -selection c"; # copy to the clipboard

  # Vagrant
  vu = "vagrant up";
  vup = "vagrant up --provision";
  vp = "vagrant provision";
  vr = "vagrant reload";
  vh = "vagrant halt -f";
  vs = "vagrant ssh";
}
