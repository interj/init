#!/bin/zsh
if [ $UID -eq 0 ]; then NCOLOR="red"; else NCOLOR="cyan"; fi

function ssh_conn_prompt() 
{
    [[ -z "$SSH_CONNECTION" ]] || echo "%{$fg_bold[yellow]%}⚡"
}

function my_git_prompt_info() {
  ref=$(git symbolic-ref HEAD 2> /dev/null) || return
  GIT_STATUS=$(git_prompt_status)
  [[ -n $GIT_STATUS ]] && GIT_STATUS="$GIT_STATUS"
  echo "$ZSH_THEME_GIT_PROMPT_PREFIX${ref#refs/heads/}$GIT_STATUS$ZSH_THEME_GIT_PROMPT_SUFFIX"
}

PROMPT='$(ssh_conn_prompt)%{$fg[$NCOLOR]%}%n%b%{$reset_color%}:%{$fg[green]%}%c%b%{$reset_color%} $(my_git_prompt_info)%{$reset_color%}%(!.#.€) '
RPROMPT='[%*]'

# git theming
ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}(%{$fg_no_bold[yellow]%}git:%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="$(git_prompt_status)%{$fg_bold[blue]%})"
ZSH_THEME_GIT_PROMPT_CLEAN=""
ZSH_THEME_GIT_PROMPT_DIRTY=""
ZSH_THEME_GIT_PROMPT_ADDED="%{$fg_bold[cyan]%}✈"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg_bold[yellow]%}✭"
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg_bold[red]%}✗"
ZSH_THEME_GIT_PROMPT_RENAMED="%{$fg_bold[blue]%}➦"
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg_bold[magenta]%}✂"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg_bold[grey]%}✱"

# LS colors, made with http://geoff.greer.fm/lscolors/
# export LSCOLORS="Gxfxcxdxbxegedabagacad"
# export LS_COLORS='no=00:fi=00:di=01;34:ln=00;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=41;33;01:ex=00;32:*.cmd=00;32:*.exe=01;32:*.com=01;32:*.bat=01;32:*.btm=01;32:*.dll=01;32:*.tar=00;31:*.tbz=00;31:*.tgz=00;31:*.rpm=00;31:*.deb=00;31:*.arj=00;31:*.taz=00;31:*.lzh=00;31:*.lzma=00;31:*.zip=00;31:*.zoo=00;31:*.z=00;31:*.Z=00;31:*.gz=00;31:*.bz2=00;31:*.tb2=00;31:*.tz2=00;31:*.tbz2=00;31:*.avi=01;35:*.bmp=01;35:*.fli=01;35:*.gif=01;35:*.jpg=01;35:*.jpeg=01;35:*.mng=01;35:*.mov=01;35:*.mpg=01;35:*.pcx=01;35:*.pbm=01;35:*.pgm=01;35:*.png=01;35:*.ppm=01;35:*.tga=01;35:*.tif=01;35:*.xbm=01;35:*.xpm=01;35:*.dl=01;35:*.gl=01;35:*.wmv=01;35:*.aiff=00;32:*.au=00;32:*.mid=00;32:*.mp3=00;32:*.ogg=00;32:*.voc=00;32:*.wav=00;32:*.patch=00;34:*.o=00;32:*.so=01;35:*.ko=01;31:*.la=00;33'

reset-prompt-accept-line() 
{
    zle reset-prompt
    zle accept-line
}

# TRAPALRM()
# {
#     if [[ "$WIDGET" != *"complete"* && "$WIDGET" != *"beginning-search" ]]; then;
#         zle reset-prompt;
#     fi
# }

TMOUT=0

zle -N reset-prompt-accept-line
bindkey "^M" reset-prompt-accept-line

[[ -z "$SSH_CONNECTION" ]] || ZSH_THEME_TERM_TAB_TITLE_IDLE="$ZSH_THEME_TERM_TITLE_IDLE"

