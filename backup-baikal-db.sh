#!/usr/bin/env sh

get_absolute_path_to_parent_dir_of_this_script() {
    local absolute_path="$(readlink -f -- "$1")"
    local parent_dir="$(dirname "$absolute_path")"
    printf "$parent_dir"
}

SCRIPT_DIR="$(get_absolute_path_to_parent_dir_of_this_script "$0")"

DECRYPT_SCRIPT="$SCRIPT_DIR/decrypt-admin-file.sh"
ENCRYPT_SCRIPT="$SCRIPT_DIR/encrypt-admin-file.sh"

DB_FILE="/usr/local/jails/containers/baikal/usr/local/www/baikal/Specific/db/db.sqlite"
ADMIN_FILES_LOCAL_CLONE="/home/tejul/src/admin-files/"

RELATIVE_PATH_TO_DB_FILE_IN_REPO="bedna$DB_FILE.age"
LAST_BACKED_UP_DB="$ADMIN_FILES_LOCAL_CLONE/$RELATIVE_PATH_TO_DB_FILE_IN_REPO"

TMP_FILE=$(mktemp -t "decrypted_db") || exit 1

cleanup() {
    rm -f -- "$TMP_FILE"
}

pull_admin_files_repo() {
    if ! git -C "$ADMIN_FILES_LOCAL_CLONE" pull -q; then
        printf "%s\n" "Error when pulling admin-files" >&2
        exit 1
    fi
}

decrypt_last_backed_up_db() {
    "$DECRYPT_SCRIPT" "$LAST_BACKED_UP_DB" > "$TMP_FILE"
}

exit_if_baikal_db_did_not_change() {
    if diff "$DB_FILE" "$TMP_FILE"; then
        printf "%s\n" "Nothing changed since last backup" >&2
        exit 0
    fi
}

encrypt_current_db() {
    "$ENCRYPT_SCRIPT" "$DB_FILE" "$LAST_BACKED_UP_DB"
}

commit_and_push_repo() {
    local now="$(date -Iseconds)"
    git -C "$ADMIN_FILES_LOCAL_CLONE" add "$RELATIVE_PATH_TO_DB_FILE_IN_REPO"
    git -C "$ADMIN_FILES_LOCAL_CLONE" commit -m "chore: baikal db backup at $now"
    git -C "$ADMIN_FILES_LOCAL_CLONE" push
    printf "%s %s\n" "Baikal DB backed up successfully" "$now" >&2
}


set -e

trap cleanup EXIT INT TERM HUP

pull_admin_files_repo
decrypt_last_backed_up_db
exit_if_baikal_db_did_not_change
encrypt_current_db
commit_and_push_repo
