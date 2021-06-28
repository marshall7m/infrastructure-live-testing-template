#!/usr/local/Cellar/bash/5.1.8/bin/bash

#logging
declare -A levels=([DEBUG]=0 [INFO]=1 [WARN]=2 [ERROR]=3)
script_logging_level="DEBUG"

log() {
    local log_message=$1
    local log_priority=$2

    #check if level exists
    [[ ${levels[$log_priority]} ]] || return 1

    #check if level is enough
    (( ${levels[$log_priority]} < ${levels[$script_logging_level]} )) && return 2

    #log here
    echo "${log_priority} : ${log_message}"
}


parent="./"
# returns the exitcode instead of the plan output (0=no plan difference, 1=error, 2=detected plan difference)
tg_plan_cmd="terragrunt run-all plan --terragrunt-working-dir $parent --terragrunt-non-interactive -detailed-exitcode"

tg_plan_out=$(eval "$tg_plan_cmd 2>&1")

exitcode=$?
if [ $exitcode -eq 1 ]; then
    log "$tg_plan_cmd failed" "INFO"
    log "error output" "INFO"
    log "$tg_plan_out" "INFO"
    exit 1
fi

# get directories that terragrunt detected a difference between the tf state and their cfg
diff_paths=($(echo "$tg_plan_out" | grep -Po 'exit\sstatus\s2\sprefix=\[\K.+?(?=\])'))
log "Directories with difference in terraform plan:" "DEBUG"
log " ${diff_paths[*]}" "DEBUG"

# terragrunt run-all plan run order
stack=$(echo "$tg_plan_out" | grep -Po '=>\sModule\s\K.+?(?=\))')

#terragrunt directories within stack
modules=( $(echo "$stack" | grep -Po '.+?(?=\s\(excluded:)') )

log "Modules:" "DEBUG"
log "${modules[*]}" "DEBUG"

#`modules` dependency directories
deps=( $(echo "$stack" | grep -Po 'dependencies:\s+\K.+') )

log "Dependencies:" "DEBUG"
log "${deps[*]}" "DEBUG"

#should be a module directory for every list of dependencies
if [ ${#modules[@]} -ne ${#deps[@]} ]; then
    log "Modules Count: ${#modules[@]}" "DEBUG"
    log "Dependency Nested Lists Count: ${#deps[@]}" "DEBUG"
    log "Error parsing stack: Length of modules directories and deps array are not equal" "ERROR"
    exit 1
fi

declare -A parsed_stack

# gets absolute path to the root of git repo
git_root=$(git rev-parse --show-toplevel)

# filters out target directories that didn't have a difference in terraform plan
for i in $(seq 0 $(( ${#modules[@]} - 1 ))); do
    if [[ " ${diff_paths[@]} " =~ " ${modules[i]} " ]]; then
        # for every directory addded to parsed_stack, only add the git root directory's relative path to the directory
        # Reason is for path portability (absolute paths will differ between instances)
        if [ "${deps[i]}" == "[]" ]; then
            parsed_stack[$(realpath --relative-to="$git_root" "${modules[i]}")]+=""
        else 
            parsed_stack[$(realpath --relative-to="$git_root" "${modules[i]}")]+=$(realpath --relative-to="$git_root" $( echo "${deps[i]}" | sed 's/[][]//g' ))            
        fi
    fi
done

log "Parsed Stack:" "INFO"
for i in ${!parsed_stack[@]}; do 
    log "parsed_stack[$i] = ${parsed_stack[$i]}" "DEBUG"
done

declare -A run_order

log "Getting run order" "INFO"
for key in "${!parsed_stack[@]}"; do
    for sub_key in "${!parsed_stack[@]}"; do
        if [ "$key" != "$sub_key" ]; then
            log "Checking if directory: ${key}" "DEBUG"
            log "is a dependency of: ${sub_key}" "DEBUG"
            log "Dependency List:" "DEBUG"
            log "${parsed_stack[$sub_key]}" "DEBUG"
            # if the terragrunt directory defined under `modules` is within a depedency list, add `modules` dependencies to the parent dependency list
            if [[ " ${parsed_stack[$sub_key]} " =~ " $key " ]]; then
                log "${key} is a dependency of ${sub_key}" "DEBUG"
                run_order["$sub_key"]=$(echo "${parsed_stack[$key]} ${parsed_stack[$sub_key]}")
            fi
        fi
    done
done

log "Stack Run Order:" "DEBUG"
for i in ${!run_order[@]}; do 
    log "run_order[$i] = ${run_order[$i]}" "DEBUG"
done


sf_input=()
for key in "${!run_order[@]}"; do
    # convert to nested list for step function map to iterate over and adds `key` terragrunt directory to the end of the run order
    sf_input+=("[${run_order[$key]} $key]")
done

log "Step Function Input:" "INFO"
log "${sf_input[*]}" "INFO"