# tell_me [-c] [-m MODEL] [--max-turns N] [--effort low|medium|high|xhigh|max] [claude flags=val] <question>
# Ask claude for a concise synopsis. Shows the tools/commands claude runs live,
# then renders the final answer with glow. Defaults to --effort low so it's fast.
# Ctrl+C stops everything immediately (no traps, plain foreground pipeline).
# -c/--continue resumes the previous tell_me conversation (works from any dir —
# claude sessions are per-directory, so the session's dir is remembered and cd'd
# into). Alt+R drops the resume command onto the command line (press Enter to run).
# e.g. tell_me how to get tail -f output from a systemctl service
#      tell_me --effort high design a backup strategy for postgres
#      tell_me -c so how would I automate that?

# Full help for tell_me. Printed to stdout (it's what the user asked for) by the
# -h/--help flag, which returns 0 — asking for help isn't an error.
_tell_me_help() {
  print -r -- 'tell_me — ask claude for a concise, read-only synopsis from the terminal.

Usage:
  tell_me [flags] <question>

Flags:
  --effort <level>   reasoning effort: low|medium|high|xhigh|max (default: low)
  -m, --model <m>    claude model to use
  --max-turns <n>    cap the number of agent turns
  -c, --continue     resume the previous tell_me conversation (from any dir)
  -h, --help         show this help and exit
  --                 end flag parsing; everything after is the question

  Any other claude flag is passed through. Value-taking passthrough flags must
  use the --flag=value form (one token) — a bare `--flag value` ends flag
  parsing at value and swallows your question.

Behaviour:
  Investigates with read-only commands only (Edit/Write/NotebookEdit are blocked
  and the model is steered away from mutating anything outside /tmp). Live tool
  lines are shown as claude works; the final answer is rendered with glow.

Resume:
  -c/--continue resumes the last session (its directory is remembered and
  switched into automatically). Alt+R drops the resume command onto the line.

Examples:
  tell_me how to tail -f a systemd service
  tell_me --effort high design a backup strategy for postgres
  tell_me -c so how would I automate that?'
}

tell_me() {
  emulate -L zsh

  local effort=low cont=0
  local -a claude_args
  local sessfile=${XDG_CACHE_HOME:-$HOME/.cache}/tell_me.session

  # Consume leading flags. Value-taking flags must be recognized here so their
  # value isn't mistaken for the start of the question — that's why -m/--model and
  # --max-turns are first-class alongside --effort. For any *other* claude flag
  # that needs a value, use the --flag=value form (a single token), since a bare
  # `--flag value` would end flag-parsing at `value` and swallow your prompt.
  # -c/--continue resumes the last tell_me session. First non-flag word = question.
  while [[ ${1-} == -* ]]; do
    case $1 in
      --effort)        effort=$2; shift 2 ;;
      --effort=*)      effort=${1#*=}; shift ;;
      -m|--model)      claude_args+=(--model "$2"); shift 2 ;;
      --model=*)       claude_args+=("$1"); shift ;;
      --max-turns)     claude_args+=(--max-turns "$2"); shift 2 ;;
      --max-turns=*)   claude_args+=("$1"); shift ;;
      -c|--continue)   cont=1; shift ;;
      -h|--help)       _tell_me_help; return 0 ;;
      --)              shift; break ;;
      *)               claude_args+=("$1"); shift ;;
    esac
  done

  # When continuing, resume the stored session. Claude stores sessions per-project
  # (keyed off the directory they were created in), so resume must run in that same
  # directory — the session file records both the id and that dir.
  local -a resume_args
  local resume_dir=""
  if (( cont )); then
    local _id _dir
    [[ -r $sessfile ]] && read -r _id _dir < "$sessfile"
    if [[ -z ${_id-} ]]; then
      echo "tell_me: no previous session to continue" >&2
      return 1
    fi
    resume_args=(--resume "$_id")
    resume_dir=$_dir
    # Legacy cache (id only): recover the session's dir from its log.
    [[ -n $resume_dir ]] || resume_dir=$(_tell_me_session_dir "$_id")
  fi

  if (( $# == 0 )); then
    echo "usage: tell_me [--effort low|medium|high|xhigh|max] [claude flags] <question>" >&2
    return 1
  fi

  # Persona/formatting lives in the system prompt (cleaner than stuffing it into
  # the user turn, and it persists across -c resumes). The read-only directive is
  # the real guard against unattended writes: tool restrictions block Edit/Write
  # but not Bash, so we steer the model away from mutating anything outside /tmp.
  local sysprompt="You are answering a terminal user through a CLI tool. Be concise and practical, and keep answers brief. Output GitHub-flavored markdown: short prose, fenced code blocks for any commands, bullet points where useful.

Investigate using read-only commands only. Do NOT create, modify, move, or delete files, and do not change system state, outside /tmp — no output redirection (>, >>, tee), rm, mv, chmod, package installs, git writes, or config edits on real paths. If you need scratch space, keep it strictly under /tmp. When fulfilling the request would require changing something, show the command for the user to run instead of running it yourself."

  # The user turn reconstructs the full imperative ("tell me <args>") so Claude
  # sees the whole request, not just the bare fragment. Without this, the shell
  # eats the command name and a fragment like "off" or "a date" reads as a
  # different question than "tell me off" / "tell me a date".
  local prompt="The user typed this request: \"tell me $*\""

  local raw=$(mktemp)

  # Run claude as a plain foreground pipeline (Ctrl+C kills claude+tee+jq at once).
  # stream-json lets us surface each tool/command claude runs the moment it starts.
  # tee saves the full event stream; the jq pass prints a live line per tool use,
  # styled by hand here (glow only renders the final answer, not these lines):
  # the tool name in cyan-bold (color 6, matching code), its argument dimmed.
  # </dev/null skips claude's ~3s wait for stdin that never arrives.
  # The claude stage runs in a subshell so that, when resuming, we can cd into the
  # session's project dir without disturbing your actual pwd.
  # --disallowedTools blocks file mutation: in unattended auto mode an answer
  # should never silently edit/write files (Bash can still read/inspect).
  ( [[ -n $resume_dir ]] && cd -- "$resume_dir"
    claude -p --output-format stream-json --verbose \
           --permission-mode auto --disallowedTools "Edit,Write,NotebookEdit" \
           --append-system-prompt "$sysprompt" \
           --effort "$effort" "${resume_args[@]}" "${claude_args[@]}" "$prompt" </dev/null
  ) \
    | tee "$raw" \
    | jq --unbuffered -r '
        select(.type=="assistant") | .message.content[]? | select(.type=="tool_use")
        | "  [1m▸ \(.name)[0m [36;48;2;48;52;56m\((.input.command // .input.url // .input.query // .input.pattern // .input.file_path // (.input|tostring)) | tostring | .[0:140])[0m"
      '

  # If claude was interrupted or errored, don't render a half/empty answer.
  if (( ${pipestatus[1]} != 0 )); then
    command rm -f "$raw"
    return ${pipestatus[1]}
  fi

  # Render the final answer. Use the bundled theme-neutral style: it styles with
  # bold/italic/underline attributes only (which inherit your terminal theme's
  # colors) and renders code in color 6, so nothing clashes with the palette.
  # -w 0 keeps long oneliners on one copy-pasteable line.
  local style=${ZSH_CUSTOM:-$HOME/init}/tell_me.glow.json
  [[ -r $style ]] || style=dark   # fall back to a built-in style if the file is gone
  jq -r 'select(.type=="result") | .result' "$raw" | glow -w 0 -s "$style" -

  # Remember this run's session id AND the dir it lives in (the resume dir when
  # continuing, else the current pwd) so `tell_me -c` and the Alt+R widget can
  # resume it from anywhere. Alt+R drops the resume command onto the command line.
  local sid=$(jq -r 'select(.type=="result") | .session_id // empty' "$raw")
  if [[ -n $sid ]]; then
    local sess_dir=${resume_dir:-$PWD}
    mkdir -p ${sessfile:h} && print -r -- "$sid $sess_dir" > "$sessfile"
    [[ -t 1 ]] && printf '  \033[2m↳ continue: tell_me -c "…" · Alt+R · or run\033[0m  \033[36;48;2;48;52;56m(cd %s && claude -r %s)\033[0m\n' "$sess_dir" "$sid"
  fi
  command rm -f "$raw"
}

# Resolve the directory a claude session lives in by reading the cwd recorded in
# its log — robust even when the cache only has an id, and correct for paths that
# contain '-' (which the project-dir slug can't be reliably decoded back into).
_tell_me_session_dir() {
  emulate -L zsh
  local f=(~/.claude/projects/*/$1.jsonl(N))
  (( $#f )) && jq -r 'select(.cwd!=null) | .cwd' "$f[1]" 2>/dev/null | head -1
}

# Alt+R: drop the resume command for the most recent tell_me session onto the
# command line, ready to run with Enter. Pure zle — no clipboard, no Wayland
# input injection — so it clobbers nothing and fires only when you press the key.
# Sessions are per-directory, so always wrap with `cd <session dir>` (harmless if
# you're already there) — that's what makes resume work from anywhere.
_tell_me_resume() {
  local sessfile=${XDG_CACHE_HOME:-$HOME/.cache}/tell_me.session
  if [[ -r $sessfile ]]; then
    local id dir
    read -r id dir < "$sessfile"
    [[ -n $dir ]] || dir=$(_tell_me_session_dir "$id")   # recover dir if cache lacks it
    if [[ -n $dir ]]; then
      BUFFER="(cd ${(q)dir} && claude -r $id)"
    else
      BUFFER="claude -r $id"
    fi
    CURSOR=$#BUFFER
  else
    zle -M "tell_me: no session to resume yet"
  fi
}
if [[ -o interactive ]]; then
  zle -N _tell_me_resume
  bindkey '^[r' _tell_me_resume   # Alt+r  (Esc-r); unbound by default. Free alts: ^[j ^[k ^[e
fi
