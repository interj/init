#!/usr/bin/env zsh
# Regenerates pay-respects-aliases.zsh — the BAKED pay-respects setup sourced by .zshrc.
#
# It writes: (1) the cached `pay-respects zsh --alias fuck` init script, and
# (2) plain `alias` lines for rage-typo spellings of fuck/kurwa. Real
# commands/builtins/functions (fc, fg, ...) are filtered out HERE, once, so that
# sourcing the result at shell startup does zero `whence` lookups.
#
# Lives in init/pay-respects/ (NOT a top-level *.zsh) so ZSH_CUSTOM's autoloader
# never sources it — important, since it sets err_exit and has side effects.
# Run as a fresh process (not sourced) so no inherited aliases pollute the filter:
#   zsh $HOME/init/pay-respects/gen-pay-respects-aliases.zsh
emulate -L zsh
setopt err_exit pipe_fail

PR=${PR:-$HOME/.cargo/bin/pay-respects}
OUT=${1:-${0:A:h}/pay-respects-aliases.zsh}

[[ -x $PR ]] || { print -u2 "pay-respects not found at $PR"; exit 1 }

# Rage spellings, each also emitted in UPPER and Capitalized case.
#   fuck-family:  f{1,4} u{0,3} (ck|k|c|g|q)
#   kurwa-family: drawn-out, contractions, phonetic, euphemisms, qwerty typos
#                 (no inflected forms, per preference)
typeset -aU words
local f u e b x

for f in f ff fff ffff; do
	for u in '' u uu uuu; do
		for e in ck k c g q; do
			x="$f$u$e"; words+=("$x" "${(U)x}" "${(C)x}")
		done
	done
done

local -a kurwa=(
	# drawn-out / contractions
	kurwa kurwo kurwaa kurwaaa kurwaaaa ku kur kurw kwa krwa krw
	# phonetic spellings
	kurva qrwa qurwa korwa kórwa
	# euphemisms
	kurde kurcze kurna kurka
	# qwerty / transposition typos
	kirwa kyrwa kuewa kufwa jurwa lurwa kursa kurwq kurfa kruwa kwra kuruwa
)
for b in $kurwa; do
	words+=("$b" "${(U)b}" "${(C)b}")
done

# bare f / F (pay-respects' default key) and fff
words+=(f F fff)

{
	print -r -- "# pay-respects aliases — BAKED, do not edit by hand."
	print -r -- "# Regenerate: zsh \$HOME/init/pay-respects/gen-pay-respects-aliases.zsh"
	print -r -- "# Cached \`pay-respects zsh --alias fuck\` init script + rage-typo aliases."
	print -r -- "# Real commands/builtins were filtered out at generation time, so sourcing"
	print -r -- "# this does zero \`whence\` lookups — see the generator for details."
	print -r --
	"$PR" zsh --alias fuck
	print -r --
	print -r -- "# --- rage-typo aliases -> pay-respects ---"
	local w
	for w in ${(o)words}; do
		whence -- "$w" >/dev/null 2>&1 && continue   # skip real command/builtin/function
		print -r -- "alias ${(q)w}='__pr_main suggest'"
	done
} > "$OUT"

print "wrote $(grep -c '^alias' "$OUT") aliases + init script to $OUT"
