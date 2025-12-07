#!/usr/bin/env sh

TOOL="$1"

get_absolute_path_to_parent_dir_of_this_script() {
    local absolute_path="$(readlink -f -- "$1")"
    local parent_dir="$(dirname "$absolute_path")"
    printf "$parent_dir"
}

SCRIPT_DIR="$(get_absolute_path_to_parent_dir_of_this_script "$0")"
LIB_DIR="${SCRIPT_DIR}/lib"

# source functions from libraries
. "${LIB_DIR}/astral-sh-lib"

check cargo curl jq

exit_if_astral_tool_is_up_to_date "$TOOL"

install_astral_tool "$TOOL"
installed_version=$(cargo_installed_version "$TOOL")

printf "%s %s %s\n" "$TOOL" "updated to" "$installed_version"
