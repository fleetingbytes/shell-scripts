#!/usr/bin/env sh

set -euo pipefail
#set -x

get_absolute_path_to_parent_dir_of_this_script() {
    local absolute_path="$(readlink -f -- "$1")"
    local parent_dir="$(dirname "$absolute_path")"
    printf "$parent_dir"
}

SCRIPT_DIR="$(get_absolute_path_to_parent_dir_of_this_script "$0")"
LIB_DIR="${SCRIPT_DIR}/lib"

# source functions from libraries
. "${LIB_DIR}/chezmoi-lib"
. "${LIB_DIR}/gh-lib"
. "${LIB_DIR}/keepassxc-cli-lib"
. "${LIB_DIR}/ssh-keygen-lib"

# define variables that the libraries read
MAX_REPOS=1000
SSH_DIR=$HOME/.ssh
DEPLOYMENT_KEYS_DIR=${SSH_DIR}/github_deploy_keys
AGE_IDENTITY_KEYFILE=${SSH_DIR}/age_identity.key
ENCRYPTED_KEEPASS_PASSWORD=${SSH_DIR}/keepass-password.age
KEEPASS_DB=$HOME/src/chazre/KeePassDB.kdbx
DEPLOYMENT_KEYS_GROUP_PATH_IN_DB="/Home/SSH/GitHub Deploy Keys"

mkdir -p "$DEPLOYMENT_KEYS_DIR"

remove_all_local_deployment_keys_from_github

set +e
remove_all_local_github_deployment_keys
set -e

get_repo_names_urls_and_ssh_urls | while read repo_name url ssh_url; do
    printf "Creating deployment key for %s\n" $repo_name
    create_keypair_for_deployment "$repo_name" "$ssh_url"

    printf "Adding key for %s to KeePassDB ... " $repo_name
    create_deployment_key_entry "$repo_name" "$url" "$ssh_url"
    printf "added\n"

    printf "Adding deployment key for %s to GitHub ... " $repo_name
    add_deployment_key_to_gh_repo $repo_name

    printf "Adding deployment key for %s to dotfiles ... " $repo_name
    add_deployment_key_to_dotfiles $repo_name
    printf "added\n"
done


