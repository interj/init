# gcw <branch> — cd into the worktree that already has <branch> checked out,
# since git refuses to check a branch out twice. Otherwise plain `git checkout
# "$@"`, so `gcw -b x` and `gcw -- file` behave like gco.
gcw() {
  local wt
  wt=$(git worktree list --porcelain | awk -v b="refs/heads/$1" '
    /^worktree /{p=substr($0,10)} $0=="branch "b{print p; exit}')
  if [[ -n $wt ]]; then cd "$wt"; else git checkout "$@"; fi
}
