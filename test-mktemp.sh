#!/bin/sh

# I find it very difficult to read through the man page of mktemp.
# It is not clear to me what each option does and what the exact result in each
# invocation would be, especially when considering all the fallback scenarios.
#
# I decided to test each possibility manually. Until I got annoyed by the need
# to delete all the temp files created when testing. So I wrote a script for it.
#
# It produces a report file with each tested invocation and the corresponding
# result. It deletes all the temp files created in the process. Even the report
# file itself can be optionally deleted. (Use the '-d' option for this.)

INVOCATIONS=$(mktemp)
START_OF_LABEL="‹"
END_OF_LABEL="›"
FILE_LABEL="${START_OF_LABEL}f${END_OF_LABEL}"
DIR_LABEL="${START_OF_LABEL}d${END_OF_LABEL}"
FALLBACK_DIR="$HOME/fallback_dir"
TEST_TEMP_DIR="$HOME/test_temp_dir"
GENERATED_PATHS_FILE="$(mktemp)"
REPORT_FILE="mktemp-report"


prepare_mktemp_invocations() {
    echo 'unset TMPDIR; mktemp' >> "$INVOCATIONS"
    echo 'unset TMPDIR; mktemp my_template.XX' >> "$INVOCATIONS"
    echo 'unset TMPDIR; mktemp -t my_prefix' >> "$INVOCATIONS"
    echo 'unset TMPDIR; mktemp -t my_prefix my_template.XX' >> "$INVOCATIONS"
    echo 'unset TMPDIR; mktemp -t my_prefix my_template.XX my_template.XXX' >> "$INVOCATIONS"
    echo 'unset TMPDIR; mktemp -p $FALLBACK_DIR' >> "$INVOCATIONS"
    echo 'unset TMPDIR; mktemp -p $FALLBACK_DIR my_template.XX' >> "$INVOCATIONS"
    echo 'unset TMPDIR; mktemp -p $FALLBACK_DIR my_template.XX my_template.XXX' >> "$INVOCATIONS"
    echo 'unset TMPDIR; mktemp -p $FALLBACK_DIR -t my_prefix' >> "$INVOCATIONS"
    echo 'unset TMPDIR; mktemp -p $FALLBACK_DIR -t my_prefix my_template.XXX' >> "$INVOCATIONS"

    echo 'TMPDIR=$TEST_TEMP_DIR mktemp' >> "$INVOCATIONS"
    echo 'TMPDIR=$TEST_TEMP_DIR mktemp my_template.XX' >> "$INVOCATIONS"
    echo 'TMPDIR=$TEST_TEMP_DIR mktemp -t my_prefix' >> "$INVOCATIONS"
    echo 'TMPDIR=$TEST_TEMP_DIR mktemp -t my_prefix my_template.XX' >> "$INVOCATIONS"
    echo 'TMPDIR=$TEST_TEMP_DIR mktemp -t my_prefix my_template.XX my_template.XXX' >> "$INVOCATIONS"
    echo 'TMPDIR=$TEST_TEMP_DIR mktemp -p $FALLBACK_DIR' >> "$INVOCATIONS"
    echo 'TMPDIR=$TEST_TEMP_DIR mktemp -p $FALLBACK_DIR my_template.XX' >> "$INVOCATIONS"
    echo 'TMPDIR=$TEST_TEMP_DIR mktemp -p $FALLBACK_DIR my_template.XX my_template.XXX' >> "$INVOCATIONS"
    echo 'TMPDIR=$TEST_TEMP_DIR mktemp -p $FALLBACK_DIR -t my_prefix' >> "$INVOCATIONS"
    echo 'TMPDIR=$TEST_TEMP_DIR mktemp -p $FALLBACK_DIR -t my_prefix my_template.XXX' >> "$INVOCATIONS"

    fsync "$INVOCATIONS"
}

create_test_dirs() {
    mkdir -p "$FALLBACK_DIR" "$TEST_TEMP_DIR"
}

cleanup() {
    rm -f "$INVOCATIONS" "$GENERATED_PATHS_FILE" "$REPORT_FILE"
    rm -rf "$FALLBACK_DIR" "$TEST_TEMP_DIR"
}

execute_invocations_and_write_report() {
    while read invocation; do
        printf "%s ==> " "$invocation" >> "$REPORT_FILE"
        eval "$invocation" '2>&1' "|" 'tee -a "$REPORT_FILE"' "|" 'grep --invert-match --fixed-strings "Permission denied"' "|" 'tee -a "$GENERATED_PATHS_FILE"' "|" "xargs rm"
        printf "\0" >> "$REPORT_FILE"
    done < "$INVOCATIONS"
}

label_files_and_directories_in_report() {
    local path
    local label
    while read path; do
        [ -d "$path" ] && label=$DIR_LABEL || label=$FILE_LABEL
        sed -i "" "s:$path:$label $path:g" "$REPORT_FILE"
        fsync "$REPORT_FILE"
    done < "$GENERATED_PATHS_FILE"
}

show_report() {
    label_files_and_directories_in_report
    sed "s:$FALLBACK_DIR:\$FALLBACK_DIR:g; s:$TEST_TEMP_DIR:\$TEST_TEMP_DIR:g" "$REPORT_FILE" | tr -d "\n" | tr "\0" "\n" | sed -E "s/([[:alnum:]])$START_OF_LABEL/\1 $START_OF_LABEL/g"
}

trap cleanup EXIT

prepare_mktemp_invocations
create_test_dirs
execute_invocations_and_write_report
show_report
