

# %{%B%F{cyan}%}

prompt() {
    echo -n "$1 "
}

prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  echo -n "%{$bg%}%{$fg%}"
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n "$3%{%f%k%b%} "
}

prompt_status() {
    #print return code except 0 and 148(ctrl+z)
    echo -n "%(0?..%(148?..%F{red}%? ))"
    echo -n "%(1j.%F{cyan}%j⚙ .)"
}

prompt_context() {
    prompt "%B%(!.%F{red}.%F{blue})%n%b%{%F{white}%}@%m"
}

# Dir: current working directory
prompt_dir() {
  prompt '%B%F{blue}%2~%f%b'
}

# Virtualenv: current working virtualenv
prompt_virtualenv() {
  local virtualenv_path="$VIRTUAL_ENV"
  # if [[ -n $virtualenv_path && -n $VIRTUAL_ENV_DISABLE_PROMPT ]]; then
  if [[ -n "$virtualenv_path" ]]; then
    prompt "(`basename $virtualenv_path`)"
    #prompt_segment default cyan "(`basename $virtualenv_path`)"
    prompt_segment
fi
}

# Git: branch/detached head, dirty status
prompt_git() {
    (( $+commands[git] )) || return
    local PL_BRANCH_CHAR
    () {
        local LC_ALL="" LC_CTYPE="en_US.UTF-8"
        PL_BRANCH_CHAR=$'\ue0a0'         # 
    }
    local ref dirty mode repo_path
    local repo_path=$(git rev-parse --git-dir 2>/dev/null)
    local is_inside_work_tree=$(git rev-parse --is-inside-work-tree 2>&1)

    if [[ "$is_inside_work_tree" = "true" ]]; then
        dirty=$(parse_git_dirty)
        ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git rev-parse --short HEAD 2> /dev/null)"
        if [[ -n $dirty ]]; then
            prompt_segment default yellow
            else
              prompt_segment default green
            fi

            if [[ -e "${repo_path}/BISECT_LOG" ]]; then
              mode=" <B>"
            elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
              mode=" >M<"
            elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
              mode=" >R>"
        fi

        setopt promptsubst
        autoload -Uz vcs_info

        zstyle ':vcs_info:*' enable git
        zstyle ':vcs_info:*' get-revision true
        zstyle ':vcs_info:*' check-for-changes true
        zstyle ':vcs_info:*' stagedstr '✚'
        zstyle ':vcs_info:*' unstagedstr '●'
        zstyle ':vcs_info:*' formats ' %u%c'
        zstyle ':vcs_info:*' actionformats ' %u%c'
        vcs_info
        prompt "${ref/refs\/heads\//$PL_BRANCH_CHAR }${vcs_info_msg_0_%% }${mode}"
        prompt_segment
    fi
}

3prompt_svn() {
    local rev branch
    if in_svn; then
        rev=$(svn_get_rev_nr)
        branch=$(svn_get_branch_name)
        if [[ $(svn_dirty_choose_pwd 1 0) -eq 1 ]]; then
            prompt_segment yellow black "$rev@$branch±"
        else
            prompt_segment green black "$rev@$branch"
        fi
    fi
}


prompt_end() {
    prompt "%(!.%F{red}#.%B%F{blue}%%%b)"
}

build_prompt() {
    RETVAL=$?
    prompt_status
    prompt_virtualenv
    prompt_context
    prompt_dir
    prompt_git
#    prompt_svn
    prompt_end
}

PROMPT='%{%f%k%b%}$(build_prompt)%{%f%k%b%}'
