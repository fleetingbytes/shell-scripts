#!/usr/bin/env sh

script_name=$(basename $0 | rev | cut -d / -f 1 | rev)

DEFAULT_KEEPASS_DB="$HOME/src/chazre/KeePassDB.kdbx"
DEFAULT_DEPLOY_KEYS_DIR="$HOME/.ssh/github_deploy_keys"
DEFAULT_PROJECT_DIR="."

help_text=$(cat << EOF
NAME
    $script_name - Creates a remote repository and credentials

SYNOPSIS
    $script_name path [-d dir] [-k path] [FLAGS]

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

OPTIONS
    -d, --deploy-key-dir  Specify the directory where to create the 
                          GitHub deploy keypair. Default is
                          "$DEFAULT_DEPLOY_KEYS_DIR"
    -k, --keepass-db      Specify the path to the KeePass DB.
                          Default is "$DEFAULT_KEEPASS_DB"

FLAGS
    -p, --private         GitHub repository shall be private
    -K, --push-keepass    Commit and push the KeePass DB
    -G, --push-chezmoi    Commit and push the chezmoi dotfiles
    -h, --help            Prints this help text

Example:
$script_name ~/src/new-project \\
  --deploy-keys-dir=~/.ssh/github_deploy_keys \\
  --keepass-db=~/src/chazre/KeePassDB.kdbx \\
  --private \\
  --push-keepass \\
  --push-chezmoi \\
EOF
)

show_help() {
    echo "$help_text"
}

starts_with_a_hyphen() {
    [ "${1#-}" = "$1" ]
}

is_a_positional_argument() {
    if starts_with_a_hyphen "$1"; then:
        return 1
    else
        return 0
}

parse_optional_positional_argument() {
    if [ $# -gt 0 ] && [ "${1#-}" = "$1" ]; then
        printf "%s" $1
        return 0
    else
        printf "$DEFAULT_PROJECT_DIR"
        return 1
    fi
}

parse_cli() {
    PROJECT_DIR=$(parse_optional_positional_argument "$@")
    local user_specified_project_dir=$?
    if [ $user_specified_project_dir -eq 0 ]; then
        shift
    fi
    while getopts ":d:k:ph" opt; do
        case $opt in
            d) echo "Option -d with value $OPTARG" ;;
            k) echo "Option -k with value $OPTARG" ;;
            p) echo "Option -p" ;;
            h) echo "Option -h" ;;
            \?) echo "Invalid option: -$OPTARG" >&2; show_help; exit 1 ;;
            :) echo "Option -$OPTARG requires an argument" >&2; exit 1 ;;
        esac
    done
}

parse_cli "$@"
printf "project dir is \"%s\" after parsing the arguments.\n" $PROJECT_DIR
