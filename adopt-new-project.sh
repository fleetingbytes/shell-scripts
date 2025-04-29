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
    $script_name - Creates a remote repository and credentials

SYNOPSIS
    $script_name [dir] [-n string] [-d string] [-s dir]
    [-k path] [FLAGS]

DESCRIPTION
    Once you have manually initialized a git repository locally,
    $script_name will:
    - create a corresponding remote repository in your GitHub account
    - set the remote url of the repository to your GitHub remote
    - generate a deploy key (keypair) for this repository
    - add this deploy key to this repository in GitHub
    - add this deploy key to your SSH agent
    - add this deploy key to the deploy keys group in KeePass
    - add this deploy key to your chezmoi dotfiles
    - push the local commits of the project to its remote repository

ARGUMENTS
    dir                    Path to the directory of the project.
                           Defaults to the current working directory.
OPTIONS
    -n, --name             Set the name for the project.
                           Default is the basename of the 'dir'
                           argument.
    -d, --description      Description of the project.
    -s, --deploy-keys-dir  Specify the directory where to create the 
                           GitHub deploy keypair. Default is
                           "$DEFAULT_DEPLOYMENT_KEYS_DIR".
    -k, --keepass-db       Specify the path to the KeePass DB.
                           Default is "$DEFAULT_KEEPASS_DB".

FLAGS
    -p, --private          GitHub repository shall be private
    -K, --push-keepass-db  Commit and push the KeePass DB
    -C, --push-chezmoi     Commit and push the chezmoi dotfiles
    -R, --push-repository  Push the adopted project to the remote
    -h, --help             Prints this help text

Example:
$script_name ~/src/new-project \\
  --deploy-keys-dir=~/path/to/deploy_keys \\
  --keepass-db=~/path/to/KeePassDB.kdbx \\
  --private \\
  --push-keepass-db \\
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

evaluate_relative_project_dir() {
    printf "%s" $(readlink -f -- "$1")
}

parse_optional_positional_argument() {
    if [ $# -gt 0 ] && is_a_positional_argument "$1"; then
        printf "%s" $(evaluate_relative_project_dir "$1")
        return 0
    else
        printf "$DEFAULT_PROJECT_DIR"
        return 1
    fi
}
set_defaults() {
    PROJECT_DESCRIPTION=""
    DEPLOYMENT_KEYS_DIR=$DEFAULT_DEPLOYMENT_KEYS_DIR
    KEEPASS_DB=$DEFAULT_KEEPASS_DB
    PRIVATE_GITHUB_REPOSITORY=""
    PUSH_KEEPASS_DB=""
    PUSH_CHEZMOI=""
    PUSH_REPOSITORY=""
}

parse_cli() {
    if help_option_used "$@"; then
        show_help
        exit 0
    fi

    PROJECT_DIR=$(parse_optional_positional_argument "$@")
    local user_specified_project_dir=$?
    if [ $user_specified_project_dir -eq 0 ]; then
        shift
    fi
    PROJECT_NAME=$(basename $PROJECT_DIR)

    while getopts ":n:d:s:k:pKCR-:" opt; do
        case $opt in
            n) PROJECT_NAME=$OPTARG ;;
            d) PROJECT_DESCRIPTION=$OPTARG ;;
            s) DEPLOYMENT_KEYS_DIR=$OPTARG ;;
            k) KEEPASS_DB=$OPTARG ;;
            p) PRIVATE_GITHUB_REPOSITORY=1 ;;
            K) PUSH_KEEPASS_DB=1 ;;
            C) PUSH_CHEZMOI=1 ;;
            R) PUSH_REPOSITORY=1 ;;
            -)
                case "${OPTARG}" in
                    name=*)
                        PROJECT_NAME="${OPTARG#*=}" ;;
                    description=*)
                        PROJECT_DESCRIPTION="${OPTARG#*=}" ;;
                    deploy-key-dir=*)
                        DEPLOYMENT_KEYS_DIR="${OPTARG#*=}" ;;
                    keepass-db=*)
                        KEEPASS_DB="${OPTARG#*=}" ;;
                    private)
                        PRIVATE_GITHUB_REPOSITORY=1 ;;
                    push-keepass-db)
                        PUSH_KEEPASS_DB=1 ;;
                    push-chezmoi)
                        PUSH_CHEZMOI=1 ;;
                    push-repository)
                        PUSH_REPOSITORY=1 ;;
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

exit_if_remote_has_changed() {
    local repository
    while read repository; do
        if remote_has_changed "$repository"; then
            printf "%s %s %s\n" "Detected changes in the" "$repository" "remote"
            exit 1
        fi
    done
}

set_color_variables

set_defaults
parse_cli "$@"

printf "%s\n" "$(dirname $KEEPASS_DB)" "$(chezmoi source-path)" | exit_if_remote_has_changed

repo_name="$PROJECT_NAME"

create_remote_repository "$PROJECT_NAME" "$PROJECT_DESCRIPTION" "$PRIVATE_GITHUB_REPOSITORY"
IFS=" " read url ssh_url << EOF
$(get_url_and_ssh_url "$repo_name")
EOF

add_remote_url "$PROJECT_DIR" "$ssh_url"

create_keypair_for_deployment "$repo_name" "$ssh_url"

add_deployment_key_to_gh_repo "$repo_name"

add_deployment_key_to_ssh_agent "$repo_name"

unlock | create_deployment_key_entry "$repo_name" "$url" "$ssh_url"
[ $PUSH_KEEPASS_DB ] && add_commit_push "$KEEPASS_DB" "feat: add deployment keys for $repo_name"

add_deployment_key_to_dotfiles $repo_name
chezmoi_stage_deployment_key $repo_name
[ $PUSH_CHEZMOI ] && chezmoi_commit_and_push

[ $PUSH_REPOSITORY ] && push_local_repository_to_the_remote "$PROJECT_DIR"
