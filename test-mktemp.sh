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
FALLBACK_DIR="$HOME/fallback_dir"
TEST_TEMP_DIR="$HOME/test_temp_dir"
REPORT_FILE="mktemp-report"
getopts "d" DELETE_REPORT_FILE


prepare_mktemp_invocations() {
    echo 'unset TMPDIR; mktemp' >> "$INVOCATIONS"
    echo 'unset TMPDIR; mktemp my_template' >> "$INVOCATIONS"
    echo 'unset TMPDIR; mktemp my_templateX' >> "$INVOCATIONS"
    echo 'unset TMPDIR; mktemp my_templateX.XXX' >> "$INVOCATIONS"
    echo 'unset TMPDIR; mktemp -t my_prefix' >> "$INVOCATIONS"
    echo 'unset TMPDIR; mktemp -t my_prefix my_template.XXX' >> "$INVOCATIONS"
    echo 'unset TMPDIR; mktemp -p $FALLBACK_DIR' >> "$INVOCATIONS"
    echo 'unset TMPDIR; mktemp -p $FALLBACK_DIR my_template.XXX' >> "$INVOCATIONS"
    echo 'unset TMPDIR; mktemp -p $FALLBACK_DIR -t my_prefix' >> "$INVOCATIONS"
    echo 'TMPDIR="" mktemp' >> "$INVOCATIONS"
    echo 'TMPDIR=$TEST_TEMP_DIR mktemp' >> "$INVOCATIONS"
    echo 'TMPDIR=$TEST_TEMP_DIR mktemp my_template' >> "$INVOCATIONS"
    echo 'TMPDIR=$TEST_TEMP_DIR mktemp my_templateX' >> "$INVOCATIONS"
    echo 'TMPDIR=$TEST_TEMP_DIR mktemp my_templateX.XXX' >> "$INVOCATIONS"
    echo 'TMPDIR=$TEST_TEMP_DIR mktemp -t my_prefix' >> "$INVOCATIONS"
    echo 'TMPDIR=$TEST_TEMP_DIR mktemp -t my_prefix my_template.XXX' >> "$INVOCATIONS"
    echo 'TMPDIR=$TEST_TEMP_DIR mktemp -p $FALLBACK_DIR' >> "$INVOCATIONS"
    echo 'TMPDIR=$TEST_TEMP_DIR mktemp -p $FALLBACK_DIR my_template.XXX' >> "$INVOCATIONS"
    echo 'TMPDIR=$TEST_TEMP_DIR mktemp -p $FALLBACK_DIR -t my_prefix' >> "$INVOCATIONS"
    fsync "$INVOCATIONS"
}

create_test_dirs() {
    mkdir -p "$FALLBACK_DIR" "$TEST_TEMP_DIR"
}

cleanup() {
    rm -f "$INVOCATIONS"
    rm -rf "$FALLBACK_DIR" "$TEST_TEMP_DIR"
    [ $DELETE_REPORT_FILE = "d" ] && rm "$REPORT_FILE"
}

execute_invocations_and_write_report() {
    while read invocation; do
        printf "%s ==> " "$invocation" >> "$REPORT_FILE"
        eval "$invocation" '2>&1' "|" 'tee -a $REPORT_FILE' "|" "grep --invert-match --fixed-strings" '"Permission denied"' "|" "xargs rm"
    done < "$INVOCATIONS"
}

show_report() {
    sed "s:$FALLBACK_DIR:\$FALLBACK_DIR:g; s:$TEST_TEMP_DIR:\$TEST_TEMP_DIR:g" "$REPORT_FILE"
}

trap cleanup EXIT

prepare_mktemp_invocations
create_test_dirs
execute_invocations_and_write_report
show_report
