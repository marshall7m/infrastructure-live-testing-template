#!/usr/local/Cellar/bash/5.1.8/bin/bash

parent="./"
tg_plan_cmd="terragrunt run-all plan --terragrunt-working-dir $parent --terragrunt-non-interactive -detailed-exitcode"

tg_plan_out=$(eval "$tg_plan_cmd 2>&1")

exitcode=$?
if [ $exitcode -eq 1 ]; then
    echo "$tg_plan_cmd failed"
    echo "error:"
    echo
    echo "$tg_plan_cmd"
    exit 1
fi

diff_paths=($(echo "$tg_plan_out" | grep -Po 'exit\sstatus\s2\sprefix=\[\K.+?(?=\])'))
echo "Directories with diff"
echo "${diff_paths[@]}"

stack=$(echo "$tg_plan_out" | grep -Po '=>\sModule\s\K.+?(?=\))')

modules=($(echo "$stack" | grep -Po '.+?(?=\s\(excluded:)'))

deps=( $(echo "$stack" | grep -Po 'dependencies:\s+\K.+') )

if [ ${#modules[@]} -ne ${#deps[@]} ]; then
    echo "Error parsing stack"
fi

declare -A parsed_stack

for i in $(seq 0 $(( ${#modules[@]} - 1 ))); do
    if [[ " ${diff_paths[@]} " =~ " ${modules[i]} " ]]; then
        parsed_stack["${modules[i]}"]="${deps[i]}"
    fi
done

# echo "${parsed_stack[@]}"

declare -A run_order

for key in "${!parsed_stack[@]}"; do
    echo "key"
    echo "$key"
    for sub_key in "${!parsed_stack[@]}"; do
        echo "sub key"
        echo "$sub_key"
        echo "sub values"
        echo "${parsed_stack[$sub_key]}"
        echo
        if [[ " $(echo "${parsed_stack[$sub_key]}" | sed 's/[][]//g') " =~ " $(echo "$key" | sed 's/[][]//g') " ]]; then
            run_order["$sub_key"]=$(echo "${parsed_stack[$key]} ${parsed_stack[$sub_key]}" | sed 's/[][]//g')
        fi
    done
done

echo "${!run_order[@]}"

sf_input=()
for key in "${!run_order[@]}"; do
    sf_input+=("[${run_order[$key]} $key]")
done

echo
echo "${sf_input[@]}"
