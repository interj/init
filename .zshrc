# Path to your oh-my-zsh installation

# xhost local:interj > /dev/null 2>&1

setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format.
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
setopt HIST_IGNORE_SPACE         # Don\'t record an entry starting with a space.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
export HISTSIZE=2000000000
export SAVEHIST=$HISTSIZE

tabs 4

export ZSH_DISABLE_COMPFIX=true

export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="interj"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.

ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)


plugins=(git rsync colored-man-pages zsh-syntax-highlighting zsh-autosuggestions colorize)

# User configuration
# export MANPATH="/usr/local/man:$MANPATH"

source $ZSH/oh-my-zsh.sh


# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

function swap()
{
    [ -d "$1" ] && nameonly='-u'
    local tempfile=`mktemp $nameonly $(dirname "$1")/XXXXXX`
     mv "$1"        "$tempfile" &&
    (mv "$2"        "$1") 2> /dev/null
     mv "$tempfile" "$2"
}

export LESS='--mouse --wheel-lines=3 -R'
export SYSTEMD_LESS="FRMK $LESS"

function sshz()
{
    /usr/bin/ssh -t "$@" "/bin/zsh"
}

unalias ag 2>/dev/null

if [ -f /proc/sys/fs/binfmt_misc/WSLInterop ]; then

    alias psshutdown=psshutdown.exe
    
    keep_current_path() 
    {
        printf "\e]9;9;%s\e\\" "$(wslpath -w "$PWD")"
    }
    precmd_functions+=(keep_current_path)
fi

# pay-respects (thefuck replacement) — https://github.com/iffse/pay-respects
# Defines `fuck` + inline correction (^X^X) + a command_not_found_handler, plus
# rage-typo aliases (fuck/kurwa variants). The baked file is the cached init
# script + plain alias lines; sourcing it does zero subprocesses or whence checks.
# Regenerate after a pay-respects upgrade: zsh ~/init/pay-respects/gen-pay-respects-aliases.zsh
# ~/.cargo/bin is on PATH via ~/.zshenv. Files live in init/pay-respects/ (a
# subdir) so ZSH_CUSTOM's top-level *.zsh autoloader does NOT source them.
if [[ -o interactive ]] && (( $+commands[pay-respects] )); then
	if [[ -r $HOME/init/pay-respects/pay-respects-aliases.zsh ]]; then
		source $HOME/init/pay-respects/pay-respects-aliases.zsh
	else
		eval "$(pay-respects zsh --alias fuck)"   # fallback if not yet baked
	fi
fi
export PATH="$HOME/.local/bin:$PATH"

# --- live shared history: pick up other shells' commands on keypress ---
# Up/Down recall and Ctrl-R/Ctrl-S search first import only the newly-appended
# bytes of $HISTFILE, so a command run in another shell shows up the instant you
# reach for it — without the navigation breakage of `fc -RI` or the bloat of a
# full `fc -R`. A precmd snapshot marks the file position so this shell never
# re-imports its own commands.
#
# The Up/Down search widgets are wrapped IN PLACE (the original is copied aside
# with `functions -c`, then the same-named widget is redefined) rather than under
# a new name. Keeping the original widget name bound is essential: the search
# functions decide whether to *continue* a search vs *restart* it by comparing
# $LASTWIDGET to their own name, so a differently-named wrapper makes every press
# restart — bringing up one match and never stepping further.
if [[ -o interactive ]]; then
  zmodload zsh/stat 2>/dev/null
  autoload -Uz add-zsh-hook
  typeset -gi _HIST_OFF=$(zstat +size $HISTFILE 2>/dev/null || echo 0)
  _hist_snapshot() { _HIST_OFF=$(zstat +size $HISTFILE 2>/dev/null || echo 0); }
  add-zsh-hook precmd _hist_snapshot
  _hist_import_new() {
    local -i sz=$(zstat +size $HISTFILE 2>/dev/null || echo 0)
    if (( sz > _HIST_OFF )); then
      local tmp=$(mktemp)
      tail -c +$((_HIST_OFF + 1)) $HISTFILE > $tmp
      fc -R $tmp
      command rm -f $tmp
      _HIST_OFF=$sz
    fi
  }
  # Force-load the original search functions, copy them aside, then redefine the
  # same-named widgets to import first. Preserves $LASTWIDGET search continuity.
  autoload -Uz +X up-line-or-beginning-search down-line-or-beginning-search 2>/dev/null
  if functions -c up-line-or-beginning-search _hist_orig_up 2>/dev/null; then
    up-line-or-beginning-search() { _hist_import_new; _hist_orig_up }
    zle -N up-line-or-beginning-search
  fi
  if functions -c down-line-or-beginning-search _hist_orig_down 2>/dev/null; then
    down-line-or-beginning-search() { _hist_import_new; _hist_orig_down }
    zle -N down-line-or-beginning-search
  fi
  bindkey '^[[A' up-line-or-beginning-search;   bindkey '^[OA' up-line-or-beginning-search
  bindkey '^[[B' down-line-or-beginning-search; bindkey '^[OB' down-line-or-beginning-search
  # Incremental search: override the builtin widget name with a wrapper that
  # imports first, then invokes the genuine builtin via the `.` prefix. Keeping
  # the stock widget name bound (rather than a custom name) is what makes isearch
  # actually start — and lets isearch's own keymap keep stepping through matches.
  _hist_isearch_back() { _hist_import_new; zle .history-incremental-search-backward }
  _hist_isearch_fwd()  { _hist_import_new; zle .history-incremental-search-forward }
  zle -N history-incremental-search-backward _hist_isearch_back
  zle -N history-incremental-search-forward  _hist_isearch_fwd
  stty -ixon 2>/dev/null   # free Ctrl-S from terminal flow control for forward search
  bindkey '^R' history-incremental-search-backward
  bindkey '^S' history-incremental-search-forward
fi

# URL-decode a string (handles %XX escapes and + as space)
urldecode() { python3 -c 'import sys,urllib.parse as u; print(u.unquote_plus(sys.argv[1]))' "$1"; }
