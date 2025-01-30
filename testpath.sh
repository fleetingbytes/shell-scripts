#!/usr/bin/env sh

get_absolute_path_to_parent_dir_of_this_script() {
    local absolute_path="$(stat -f "%R" -- "$1")"
    local parent_dir="$(dirname "$absolute_path")"
    printf "$parent_dir"
}

SCRIPT_DIR="$(get_absolute_path_to_parent_dir_of_this_script "$0")"
echo $SCRIPT_DIR
