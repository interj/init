# Force glow to never word-wrap, so fenced code blocks and long commands stay on
# one line (copy-pasteable); the terminal soft-wraps prose. glow's config cannot
# express this: config `width: 0` means "wrap at the terminal width", and there is
# no per-code-block wrap option — only the `-w 0` *flag* disables wrapping, for the
# whole document. A passed -w overrides this (glow takes the last -w), e.g.
# `glow -w 100 file.md` to re-enable wrapping for a specific read.
glow() { command glow -w 0 "$@" }
