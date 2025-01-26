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
    -d, --deploy-keys-dir  Specify the directory where to create the 
                           GitHub deploy keypair. Default is
                           "$DEFAULT_DEPLOY_KEYS_DIR"
    -k, --keepass-db       Specify the path to the KeePass DB.
                           Default is "$DEFAULT_KEEPASS_DB"

FLAGS
    -p, --private          GitHub repository shall be private
    -K, --push-keepass     Commit and push the KeePass DB
    -C, --push-chezmoi     Commit and push the chezmoi dotfiles
    -h, --help             Prints this help text

Example:
$script_name ~/src/new-project \\
  --deploy-keys-dir=~/path/to/deploy_keys \\
  --keepass-db=~/path/to/KeePassDB.kdbx \\
  --private \\
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
    if [ "${1#-}" = "$1" ]; then
        return 1
    else
        return 0
    fi
}

is_a_positional_argument() {
    if starts_with_a_hyphen "$1"; then
        return 1
    else
        return 0
    fi
}

parse_optional_positional_argument() {
    if [ $# -gt 0 ] && is_a_positional_argument "$1"; then
        printf "%s" $1
        return 0
    else
        printf "$DEFAULT_PROJECT_DIR"
        return 1
    fi
}

set_defaults() {
    DEPLOY_KEYS_DIR=$DEFAULT_DEPLOY_KEYS_DIR
    KEEPASS_DB=$DEFAULT_KEEPASS_DB
    PRIVATE_GITHUB_REPOSITORY=0
    PUSH_KEEPASS_DB=0
    PUSH_CHEZMOI=0
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

    while getopts ":d:k:pKCh-:" opt; do
        case $opt in
            d) DEPLOY_KEYS_DIR=$OPTARG; echo "Option -d with value $DEPLOY_KEYS_DIR" ;;
            k) KEEPASS_DB=$OPTARG; echo "Option -k with value $KEEPASS_DB" ;;
            p) echo "Option -p"; PRIVATE_GITHUB_REPOSITORY=1 ;;
            K) echo "Option -K"; PUSH_KEEPASS_DB=1 ;;
            C) echo "Option -C"; PUSH_CHEZMOI=1 ;;
            h) show_help; exit 0 ;; # Redundant, but kept for completeness
            -)
                case "${OPTARG}" in
                    deploy-key-dir=*)
                        DEPLOY_KEYS_DIR=${OPTARG#*=}
                        echo "Long option --deploy-key-dir with value $DEPLOY_KEYS_DIR"
                        ;;
                    keepass-db=*)
                        KEEPASS_DB=${OPTARG#*=}
                        echo "Long option --keepass-db with value $KEEPASS_DB"
                        ;;
                    private)
                        PRIVATE_GITHUB_REPOSITORY=1
                        echo "Long option --private"
                        ;;
                    push-keepass-db)
                        PUSH_KEEPASS_DB=1
                        echo "Long option --push-keepass-db"
                        ;;
                    push-chezmoi)
                        PUSH_CHEZMOI=1
                        echo "Long option --push-chezmoi"
                        ;;
                    *)
                        echo "Unknown long option --${OPTARG}" >&2
                        exit 1
                        ;;
                esac
                ;;
            \?) echo "Invalid option: -$OPTARG" >&2; show_help; exit 1 ;;
            :) echo "Option -$OPTARG requires an argument" >&2; exit 1 ;;
        esac
    done
}

set_defaults
parse_cli "$@"
printf "project dir is \"%s\"\n" $PROJECT_DIR
printf "deploy keys dir is \"%s\"\n" $DEPLOY_KEYS_DIR
printf "keepass db is \"%s\"\n" $KEEPASS_DB
printf "private is \"%s\"\n" $PRIVATE_GITHUB_REPOSITORY
printf "push keepass db \"%s\"\n" $PUSH_KEEPASS_DB
printf "push chezmoi \"%s\"\n" $PUSH_CHEZMOI
