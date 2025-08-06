#!/usr/bin/env sh

get_absolute_path_to_parent_dir_of_this_script() {
    local absolute_path="$(readlink -f -- "$1")"
    local parent_dir="$(dirname "$absolute_path")"
    printf "$parent_dir"
}

SCRIPT_DIR="$(get_absolute_path_to_parent_dir_of_this_script "$0")"

PROJECT_DIR=$(pwd)

count_local_commits() {
    local directory=$1
    if ! git -C "$directory" rev-parse HEAD > /dev/null 2>&1; then
        echo "0"
        return 0
    fi
    git -C "$directory" rev-list --count HEAD
}

exit_if_no_commits() {
    local directory=$1
    count=$(count_local_commits "$directory")
    if [ $count -eq 0 ]; then
        printf "%s %s\n%s\n" "No commits found in" "$directory" "Script aborted"
        exit 1
    fi
}

exit_if_no_commits "$PROJECT_DIR"

echo "It looks good, there are some commits"
