#!/usr/bin/env bash

set -o emacs

BASHMAN_HOME="$(cd $(dirname $(realpath $0)) && pwd)"
BASHMAN_HISTORY="${HOME}/.bashman_history"
BASHMAN_PATH=${BASHMAN_PATH:-.}

_help_() {
    cat <<-END_OF_HELP
	bashman - command-line interpreter of Postman collections
	
	Available commands:
	
	    help                   Shows help.
	    load [collection]      Loads a given Postman collection file
	                           or reloads the current one.
	    env [environment]      Loads a given Postman environment file
	                           or reloads the current one.
	    item [item]	           Selects the item or reloads the current one.
	    run [item] [args]      Makes a call based on the current state.
	    exit/quit/CTRL+D       Exits Bashman.
	
	Environment variables:
	    
	    BASHMAN_HOME           Directory containing all Bashman scripts
	    BASHMAN_PATH           Comma-separated list of directories to
	                           search for collections and environments
	    BASHMAN_HISTORY	       Path to a file containing history of commands
	                           (default: \${BASHMAN_HOME}/.bashman_history)
	    
	END_OF_HELP
}

_load_() {
    local collection=${1:-${BM_COLLECTION}}
    [[ -z "${collection}" ]] && { echo "No collection selected." >&2; return 2; }
    [[ -f "${collection}" && -r "${collection}" ]] || { echo "Access denied." >&2; return 1; }
    source <(jq -L ${BASHMAN_HOME} -r -f ${BASHMAN_HOME}/collection.jq < ${collection})
    BM_COLLECTION="${collection}"
}

_env_() {
    local env=${1:-${BM_ENV}}

    [[ -z "${env}" ]] && { echo "No environment selected." >&2; return 2; }
    [[ -f "${env}" && -r "${env}" ]] || { echo "Access denied." >&2; return 1; }

    source <(jq -L ${BASHMAN_HOME} -r -f ${BASHMAN_HOME}/env.jq < "${env}")
    BM_ENV="${env}"
    
    [[ -n "${BM_COLLECTION}" ]] && _load_ "${BM_COLLECTION}"
    [[ -n "${BM_ITEM}" ]] && _item_ "${BM_ITEM}"
}

_item_() {
    local item=${1:-}
    [[ -z "${item}" ]] && { echo "No item selected." >&2; return 2; }

    declare -F | grep -q "${item}" || { echo "item: Item not found." >&2; return 1; }
    
    unset BM_NAME BM_METHOD BM_HEADER BM_BODY BM_URL
    unset BM_RESPONSE_BODY BM_RESPONSE_META BM_RESPONSE_CODE

    ${item} && BM_ITEM="${item}"
}

_run_() {
    if declare -F | grep -q "${1}"; then
        shift
        _item_ "${1}"
    fi 

    local auth headers response
    case "${BM_AUTH_TYPE}" in
        basic)
            auth="--basic -u ${BM_AUTH_USER}:${BM_AUTH_PASS}"
            ;;
        digest)
            auth="--digest -u ${BM_AUTH_USER}:${BM_AUTH_PASS}"
            ;;
        bearer)
            auth="--oauth2-bearer ${BM_AUTH_PASS} -u ${BM_AUTH_USER}"
    esac

    headers=""
    for header in "${!BM_HEADER[@]}"; do headers+=" --header '${header}: ${BM_HEADER[${header}]}'"; done

    response=$(curl \
        --silent \
        --write-out '\n%{json}' \
        --location \
        --request "${BM_METHOD}" "${BM_URL}" \
        ${auth:-} \
        ${auth## } \
        "${@}")

    BM_RESPONSE_META=$(tail -n 1 <<< "${response}")
    BM_RESPONSE_BODY=$(head -n -1 <<< "${response}")
    BM_RESPONSE_CODE=$(jq .http_code <<< "${BM_RESPONSE_META}")

    cat <<< "${BM_RESPONSE_BODY}"
}

_comp_commands_() {
    echo -n "env help item load run" | xargs -n1 | fzf -1 -0 -q "${*}"
}

_comp_load_() {
    find ${BASHMAN_PATH//:/ } -name '*.postman_collection.json' \
        | sed -e "s#^${PWD}##" \
        | fzf -1 -0 -q "${*}"
}

_comp_env_() {
    find ${BASHMAN_PATH//:/ } -name '*.postman_environment.json' \
        | sed -e "s#^${PWD}##" \
        | fzf -1 -0 -q "${*}"
}

_comp_item_() {
    echo $(declare -F | awk '{print $3}' | grep -v '^_' | fzf -1 -0 -q "${*}")
}

_comp_run_() {
    echo $(declare -F | awk '{print $3}' | grep -v '^_' | fzf -1 -0 -q "${*}")
}

_complete_() {
    local line="${READLINE_LINE## }"
    local cmd="${line%% *}"
    local args="${line#* }"
    
    if [[ ${#line} -gt ${#cmd} ]]; then
        case "${cmd}" in
            load|env|item|run)
                READLINE_LINE="${cmd} $(_comp_${cmd}_ ${args})"
                READLINE_POINT=${#READLINE_LINE}
                ;;
            run|help)
                ;;
        esac
    else
        local comp="$(_comp_commands_ ${cmd})"
        if [[ -n ${comp} ]]; then
            READLINE_LINE="${comp} "
            READLINE_POINT=${#READLINE_LINE}
        fi
    fi
}

_prompt_() {
    echo "${BM_ENV_NAME:-[env]}:${BM_COLLECTION_NAME:-[col]}:${BM_ITEM:-[item]}:${BM_RESPONSE_CODE:-[code]}> "
}

_init_() {
    [[ -r ${HOME}/.config/bashman/config ]] && source ${HOME}/.config/bashman/config
    [[ -r ./.bashman_config ]] && source ./.bashman_config
    [[ -n "${BM_ENV}" && -r "${BM_ENV}" ]] && _env_ "${BM_ENV}"
    [[ -n "${BM_COLLECTION}" && -r "${BM_COLLECTION}" ]] && _load_ "${BM_COLLECTION}"
    [[ -n "${BM_ITEM}" && -r "${BM_ITEM}" ]] && _item_ "${BM_ITEM}"
}

_init_
_help_

touch "${BASHMAN_HISTORY}"
history -r "${BASHMAN_HISTORY}"

bind -x '"\t":"_complete_"'

while read -e -p "$(_prompt_)" -a CMDLINE; do
    history -s "${CMDLINE[*]}"
    CMD=${CMDLINE[0]}
    ARGS=("${CMDLINE[@]:1}")
    case "${CMD}" in
        help)
            _help_
            ;;
        env)
            _env_ "${ARGS[@]}"
            ;;
        load)
            _load_ "${ARGS[@]}"
            ;;
        item)
            _item_ "${ARGS[@]}"
            ;;
        run)
            _run_ "${ARGS[@]}"
            ;;
        exit|quit)
            break
            ;;
        "")
            continue
            ;;
        *)
            echo "Unknown command: ${CMD}" >&2
        esac
        unset CMDLINE CMD ARGS
done

history -w "${BASHMAN_HISTORY}"
