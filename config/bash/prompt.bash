# CyberNeon netrunner prompt for bash (sourced from ~/.bashrc)
__cn_git() {
    local b
    b=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null) || return 0
    printf ' \001\e[38;2;255;42;79m\002\xee\x82\xa0 %s\001\e[0m\002' "$b"
}
__cn_prompt() {
    local ec=$?
    local R='\[\e[38;2;255;42;79m\]' C='\[\e[38;2;91;238;220m\]' N='\[\e[38;2;17;30;41m\]'
    local BR='\[\e[48;2;255;42;79m\]' BC='\[\e[48;2;91;238;220m\]' B='\[\e[1m\]' X='\[\e[0m\]'
    local SEP=$'\xee\x82\xbc'   # nerd-font slanted separator
    local st="$C"; [ "$ec" -ne 0 ] && st="$R"
    PS1="\[\e]0;\u@\h: \w\a\]${R}┏━${X}${BR}${N}${B} \u ${X}${BC}${R}${SEP}${X}${BC}${N}${B} \w ${X}${C}${SEP}${X}\$(__cn_git)\n${R}┗━${st}❯${X} "
}
case "$PROMPT_COMMAND" in
    *__cn_prompt*) ;;
    *) PROMPT_COMMAND="__cn_prompt${PROMPT_COMMAND:+;$PROMPT_COMMAND}" ;;
esac
