#!/usr/bin/env sh

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
. "${LIB_DIR}/git-lib"
. "${LIB_DIR}/keepassxc-cli-lib"
. "${LIB_DIR}/sh-lib"
. "${LIB_DIR}/ssh-add-lib"
. "${LIB_DIR}/ssh-keygen-lib"


SSH_DIR=$HOME/.ssh
AGE_IDENTITY_KEYFILE=${SSH_DIR}/age_identity.key
ENCRYPTED_KEEPASS_PASSWORD=${SSH_DIR}/keepass-password.age
DEPLOYMENT_KEYS_GROUP_PATH_IN_DB="/Home/SSH/GitHub Deploy Keys"


DEFAULT_KEEPASS_DB="$HOME/src/chazre/KeePassDB.kdbx"
DEFAULT_DEPLOYMENT_KEYS_DIR="$HOME/.ssh/github_deploy_keys"
DEFAULT_PROJECT_DIR=$(pwd)

script_name=$(basename $0 | rev | cut -d / -f 1 | rev)


help_text=$(cat << EOF
NAME
    $script_name - Creates credentials to my remotely existing fork
    of somebody's project.

SYNOPSIS
    $script_name fork [-s dir] [-k path] [FLAGS]

DESCRIPTION
    Once you have manually forked somebody's repository on github.com,
    $script_name will:
    - generate a deploy key (keypair) for this fork
    - add this deploy key to this repository in GitHub
    - add this deploy key to your SSH agent
    - add this deploy key to the deploy keys group in KeePass
    - add this deploy key to your chezmoi dotfiles

ARGUMENTS
    fork                   Name of my remote fork.

OPTIONS
    -s, --deploy-keys-dir  Specify the directory where to create the 
                           GitHub deploy keypair. Default is
                           "$DEFAULT_DEPLOYMENT_KEYS_DIR".
    -k, --keepass-db       Specify the path to the KeePass DB.
                           Default is "$DEFAULT_KEEPASS_DB".

FLAGS
    -K, --push-keepass     Commit and push the KeePass DB
    -C, --push-chezmoi     Commit and push the chezmoi dotfiles
    -h, --help             Prints this help text

Example:
$script_name dotfiles-1 \\
  --deploy-keys-dir=~/path/to/deploy_keys \\
  --keepass-db=~/path/to/KeePassDB.kdbx \\
  --push-keepass \\
  --push-chezmoi \\
EOF
)

show_help() {
    echo "$help_text"
}

help_option_used() {
    for arg in "$@"; do
        if [ "$arg" = "-h" -o "$arg" = "--help" ]; then
            return 0
        fi
    done
    return 1
}

starts_with_a_hyphen() {
    [ "${1#-}" != "$1" ]
}

is_a_positional_argument() {
    ! starts_with_a_hyphen "$1"
}

set_defaults() {
    DEPLOYMENT_KEYS_DIR=$DEFAULT_DEPLOYMENT_KEYS_DIR
    KEEPASS_DB=$DEFAULT_KEEPASS_DB
    PUSH_KEEPASS_DB=""
    PUSH_CHEZMOI=""
}

parse_cli() {
    if help_option_used "$@"; then
        show_help
        exit 0
    fi

    if [ $# -eq 0 ]; then
        show_help
        exit 1
    fi

    PROJECT_NAME=$1
    shift;

    while getopts "s:k:KC-:" opt; do
        case $opt in
            s) DEPLOYMENT_KEYS_DIR=$OPTARG ;;
            k) KEEPASS_DB=$OPTARG ;;
            K) PUSH_KEEPASS_DB=1 ;;
            C) PUSH_CHEZMOI=1 ;;
            -)
                case "${OPTARG}" in
                    deploy-key-dir=*)
                        DEPLOYMENT_KEYS_DIR="${OPTARG#*=}" ;;
                    keepass-db=*)
                        KEEPASS_DB="${OPTARG#*=}" ;;
                    push-keepass-db)
                        PUSH_KEEPASS_DB=1 ;;
                    push-chezmoi)
                        PUSH_CHEZMOI=1 ;;
                    *)
                        echo "Unknown option --${OPTARG}" >&2
                        exit 1
                        ;;
                esac
                ;;
            \?) echo "Invalid option: -$OPTARG" >&2; show_help; exit 1 ;;
            :) echo "Option -$OPTARG requires an argument" >&2; exit 1 ;;
        esac
    done
}

set_color_variables

set_defaults
parse_cli "$@"

exit_if_remote_has_changed "$(dirname $KEEPASS_DB)" "$(chezmoi source-path)"
exit_if_no_commits "$PROJECT_DIR"


fork_name="$PROJECT_NAME"

printf "%s=%s\n" "fork_name" "$fork_name"
printf "%s=%s\n" "DEPLOYMENT_KEYS_DIR" "$DEPLOYMENT_KEYS_DIR"
printf "%s=%s\n" "KEEPASS_DB" "$KEEPASS_DB"
printf "%s=%s\n" "PUSH_KEEPASS_DB" "$PUSH_KEEPASS_DB"
printf "%s=%s\n" "PUSH_CHEZMOI" "$PUSH_CHEZMOI"


IFS=" " read url ssh_url << EOF
$(get_url_and_ssh_url "$fork_name")
EOF
exit_if_var_empty "$url" "$ssh_url"

create_keypair_for_deployment "$fork_name" "$ssh_url"

add_deployment_key_to_gh_repo "$fork_name"

add_deployment_key_to_ssh_agent "$fork_name"

unlock | create_deployment_key_entry "$fork_name" "$url" "$ssh_url"
[ $PUSH_KEEPASS_DB ] && add_commit_push "$KEEPASS_DB" "feat: add deployment keys for $fork_name"

add_deployment_key_to_dotfiles $fork_name
chezmoi_stage_deployment_key $fork_name
[ $PUSH_CHEZMOI ] && chezmoi_commit_and_push
