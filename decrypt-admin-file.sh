#!/usr/bin/env sh

get_absolute_path_to_parent_dir_of_this_script() {
    local absolute_path="$(readlink -f -- "$1")"
    local parent_dir="$(dirname "$absolute_path")"
    printf "$parent_dir"
}

SCRIPT_DIR="$(get_absolute_path_to_parent_dir_of_this_script "$0")"
LIB_DIR="${SCRIPT_DIR}/lib"

. "${LIB_DIR}/keepassxc-cli-lib"
. "${LIB_DIR}/admin-file-codec"

SSH_DIR=$HOME/.ssh
AGE_IDENTITY_KEYFILE=${SSH_DIR}/age_identity.key
ENCRYPTED_KEEPASS_PASSWORD=${SSH_DIR}/keepass-password.age
DEFAULT_KEEPASS_DB="$HOME/src/chazre/KeePassDB.kdbx"

KEEPASS_DB=$DEFAULT_KEEPASS_DB
QUIET_KEEPASS_CLI=true

file=$1

with_admin_identity | decrypt_file "$1"
