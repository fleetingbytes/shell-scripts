# Notes on mktemp

I find it very difficult to read through the man page of mktemp.
It is not clear to me what each option does and what the exact result in each
invocation would be, especially when considering all the fallback scenarios.

I decided to test each possibility manually. Until I got annoyed by the need
to delete all the temp files created when testing. So I wrote a script for it.

## Findings

Wrong statement:
```
If the -p option is set, then the given tmpdir will be used if the TMPDIR
environment variable is not set.
```
Actually, if the -p option is set, then the given tmpdir will be used *regardless*
of the TMPDIR environment variable. Compare tests 7, 8, 9 and 17, 18, 19.


Imprecise statement:
```
Any number of temporary files may be created in a single invocation,
including one based on the internal template resulting from the -t flag.
```
Better: Any number of temporary files may be created in a single invocation,
but only the first file will use the internal template resulting from the *-t* flag.



| Test | Invocation                                                    | Result                                                         |
| ---- | ------------------------------------------------------------  | -------------------------------------------------------------- |
| 1    | unset TMPDIR; mktemp                                          | /tmp/tmp.kAq6t6x9Lc                                            |
| 2    | unset TMPDIR; mktemp my_template                              | ./my_template                                                  |
| 3    | unset TMPDIR; mktemp my_templateX                             | ./my_templateS                                                 |
| 4    | unset TMPDIR; mktemp my_templateX.XXX                         | ./my_templateX.LlK                                             |
| 5    | unset TMPDIR; mktemp -t my_prefix                             | /tmp/my_prefix.7qQR4Q1N6l                                      |
| 6    | unset TMPDIR; mktemp -t my_prefix my_template.XXX             | /tmp/my_prefix.xys9GSXUGH *and also* my_template.VHl           |
| 7    | unset TMPDIR; mktemp -p $FALLBACK_DIR                         | $FALLBACK_DIR/tmp.SYvivtqMlF                                   |
| 8    | unset TMPDIR; mktemp -p $FALLBACK_DIR my_template.XXX         | $FALLBACK_DIR/my_template.ftW                                  |
| 9    | unset TMPDIR; mktemp -p $FALLBACK_DIR -t my_prefix            | $FALLBACK_DIR/my_prefix.aVEMBq9ofq                             |
| 10   | TMPDIR="" mktemp                                              | mktemp: mkstemp failed on /tmp.lXVEGGhiQu: Permission denied   |
| 11   | TMPDIR=$TEST_TEMP_DIR mktemp                                  | $TEST_TEMP_DIR/tmp.qr2ioVyCVq                                  |
| 12   | TMPDIR=$TEST_TEMP_DIR mktemp my_template                      | ./my_template                                                  |
| 13   | TMPDIR=$TEST_TEMP_DIR mktemp my_templateX                     | ./my_templateO                                                 |
| 14   | TMPDIR=$TEST_TEMP_DIR mktemp my_templateX.XXX                 | ./my_templateX.uWN                                             |
| 15   | TMPDIR=$TEST_TEMP_DIR mktemp -t my_prefix                     | $TEST_TEMP_DIR/my_prefix.T6AWJOoot0                            |
| 16   | TMPDIR=$TEST_TEMP_DIR mktemp -t my_prefix my_template.XXX     | $TEST_TEMP_DIR/my_prefix.CO5eoysV7i *and also* my_template.QJz |
| 17   | TMPDIR=$TEST_TEMP_DIR mktemp -p $FALLBACK_DIR                 | $FALLBACK_DIR/tmp.N73EzK4CX6                                   |
| 18   | TMPDIR=$TEST_TEMP_DIR mktemp -p $FALLBACK_DIR my_template.XXX | $FALLBACK_DIR/my_template.wH7                                  |
| 19   | TMPDIR=$TEST_TEMP_DIR mktemp -p $FALLBACK_DIR -t my_prefix    | $FALLBACK_DIR/my_prefix.2nihCRFors                             |

None: environment variables *TEST_TEMP_DIR* and *FALLBACK_DIR* were always set and pointing to existing directories.
