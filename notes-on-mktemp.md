# Exploratory Tests of mktemp and Understanding Its man Page

I find the man page on mktemp very difficult to read.
It is not clear to me what each option does and what the exact result in each
invocation would be, especially when considering all the fallback scenarios.

Having studied the mktemp(1) very carefully, I used mktemp in a few scripts
and I was becoming suspicious that something is not quite the way it should be.
In the end I felt compelled to write a script to explore what mktemp and its
-t and -p options actually do and if it is in accordance with the mktemp man
page.


## Method

I designed a set of testcases, where each tests executes a particular
invocation of mktemp and reports the paths of the created temporary files.

Each of my testcases either sets or unsets the
*TMPDIR* environment variable before executing mktemp with 0 to 2 *template*s,
with or without a *prefix* option, and with or without a *tmpdir* option.


## Test Results

| Test | Invocation                                                                   | Result                                                             |
| ---- | ---------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| 1    | unset TMPDIR; mktemp                                                         | /tmp/tmp.4HAQgmU1Ny                                                |
| 2    | unset TMPDIR; mktemp my_template.XX                                          | my_template.LH                                                     |
| 3    | unset TMPDIR; mktemp -t my_prefix                                            | /tmp/my_prefix.ezb7pFfBQx                                          |
| 4    | unset TMPDIR; mktemp -t my_prefix my_template.XX                             | /tmp/my_prefix.LFDfDgO63l my_template.k2                           |
| 5    | unset TMPDIR; mktemp -t my_prefix my_template.XX my_template.XXX             | /tmp/my_prefix.3gk7VdOxgi my_template.Ys my_template.454           |
| 6    | unset TMPDIR; mktemp -p $FALLBACK_DIR                                        | $FALLBACK_DIR/tmp.B78VECvQUy                                       |
| 7    | unset TMPDIR; mktemp -p $FALLBACK_DIR my_template.XX                         | $FALLBACK_DIR/my_template.jc                                       |
| 8    | unset TMPDIR; mktemp -p $FALLBACK_DIR my_template.XX my_template.XXX         | $FALLBACK_DIR/my_template.WF $FALLBACK_DIR/my_template.Jjf         |
| 9    | unset TMPDIR; mktemp -p $FALLBACK_DIR -t my_prefix                           | $FALLBACK_DIR/my_prefix.hUidTWqNGC                                 |
| 10   | unset TMPDIR; mktemp -p $FALLBACK_DIR -t my_prefix my_template.XXX           | $FALLBACK_DIR/my_prefix.XieMbtkGjt my_template.9Lb                 |
| 11   | TMPDIR=$TEST_TEMP_DIR mktemp                                                 | $TEST_TEMP_DIR/tmp.IPMbHHYv65                                      |
| 12   | TMPDIR=$TEST_TEMP_DIR mktemp my_template.XX                                  | my_template.O8                                                     |
| 13   | TMPDIR=$TEST_TEMP_DIR mktemp -t my_prefix                                    | $TEST_TEMP_DIR/my_prefix.HJ663i12rQ                                |
| 14   | TMPDIR=$TEST_TEMP_DIR mktemp -t my_prefix my_template.XX                     | $TEST_TEMP_DIR/my_prefix.7ih7Tcz5gW my_template.I6                 |
| 15   | TMPDIR=$TEST_TEMP_DIR mktemp -t my_prefix my_template.XX my_template.XXX     | $TEST_TEMP_DIR/my_prefix.aHOJyHWQV6 my_template.Gv my_template.OpF |
| 16   | TMPDIR=$TEST_TEMP_DIR mktemp -p $FALLBACK_DIR                                | $FALLBACK_DIR/tmp.KYVXmLdXQo                                       |
| 17   | TMPDIR=$TEST_TEMP_DIR mktemp -p $FALLBACK_DIR my_template.XX                 | $FALLBACK_DIR/my_template.C5                                       |
| 18   | TMPDIR=$TEST_TEMP_DIR mktemp -p $FALLBACK_DIR my_template.XX my_template.XXX | $FALLBACK_DIR/my_template.WL $FALLBACK_DIR/my_template.aNK         |
| 19   | TMPDIR=$TEST_TEMP_DIR mktemp -p $FALLBACK_DIR -t my_prefix                   | $FALLBACK_DIR/my_prefix.WiVEiziQt9                                 |
| 20   | TMPDIR=$TEST_TEMP_DIR mktemp -p $FALLBACK_DIR -t my_prefix my_template.XXX   | $FALLBACK_DIR/my_prefix.eKNRL05mhO my_template.fXl                 |

Notes:

- Variables *TEST_TEMP_DIR* and *FALLBACK_DIR* represent paths to existing directories.
- Paths to the created temporary files in the Result columt are separated by space.


## Man Page Review and Discussion

### Synopsis Section

```
     mktemp [-d] [-p tmpdir] [-q] [-t prefix] [-u] template ...
     mktemp [-d] [-p tmpdir] [-q] [-u] -t prefix
```

There is no need for these two separate invocation forms. Both can be summarized as:
```
     mktemp [-dqu] [-p tmpdir] [-t prefix] [template ...]
```

### Description Section

```
The mktemp utility takes each of the given file name templates [...]
```

The templates are not mere file name templates. Rather, they are the absolute or relative paths to a file (relative to `$(pwd)`).

```
[...] and overwrites a portion of it to create a file name.  This file name is
unique and suitable for use by the application.  The template may be any
file name with some number of ‘Xs’ appended to it, for example
/tmp/temp.XXXX.
```
Again, we are talking file paths here, not file names.

```
The trailing ‘Xs’ are replaced with the current process
number and/or a unique letter combination.
```

"A unique letter combination" should be "a combination of alphanumeric characters (alnum in re_format(7))".

```
If the -t prefix option is given, mktemp will generate a template string
based on the prefix and the TMPDIR environment variable if set.  If the
-p option is set, then the given tmpdir will be used if the TMPDIR
environment variable is not set.  Finally, /tmp will be used if neither
TMPDIR or -p are set and used. [...]
```

This is probably the part that is the hardest to read.
And also it is either wrong or mktemp has a bug.

This all reads as if the `[-p tmpdir]` option is meant to be used only in
conjunction with the `[-t prefix]` option. As if `[[-p tmpdir] -t prefix]` was in the synopsis.
This is clearly not the case. mktemp happily accepts the *-p* option alone.

The *-p* option, is not any kind of fallback. Rather, it simply sets a value for
the TMPDIR environment variable for the duration of the mktemp process.

All that the description needs to say here (but does not say!) is this:

```
Unless modified by the -t or -p options or the optional template argument,
mktemp tries to use the default template `$TMPDIR/tmp.XXXXXXXXXX`,
or `/tmp/tmp.XXXXXXXXXX` if TMPDIR is not set.
```

This is much easier to read and in accordance with the actual behavior.
It also provides the missing information how long the alphanumeric sequence is by default.
To this we can append the valid security warning from the rest of the paragraph:

```
Care should be taken to ensure that it is
appropriate to use an environment variable potentially supplied by the
user.
```

The next paragraph of the description now becomes redundant:
```
If no arguments are passed or if only the -d flag is passed mktemp
behaves as if -t tmp was supplied.
```
Besides, the way it was, it instantly opens the question how mktemp behaves if only -u is passed.
I don't know the answer to this either.

The penultimate paragraph of the descrioption is ... imprecise, at best.

```
Any number of temporary files may be created in a single invocation,
including one based on the internal template resulting from the -t flag.
```

It mentions some "internal template" but this term is not explained anywhere.




Imprecise statement:
```
Any number of temporary files may be created in a single invocation,
including one based on the internal template resulting from the -t flag.
```
Better: Any number of temporary files may be created in a single invocation,
but only the first file will use the internal template resulting from the *-t* flag.



