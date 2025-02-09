# mktemp - Exploratory Tests and a Critical Review of Its Manual Page

## Abstract

This study explores the interplay between the *template* arguments and the *tmpdir* and *prefix* options of mktemp(1).
It finds errors and imprecisions in the mktemp manual page and suggests appropriate corrections.


## Introduction

I find the manual page on mktemp very difficult to read.
It failed to make clear to me what each option does and what the exact result in each
invocation would be, especially when considering various option and argument combinations, the fallback scenarios, and edge cases.

After a careful study of mktemp(1) I used mktemp in a few scripts
but I quickly became suspicious that something is not quite the way it should be.
In the end I felt compelled to write some test cases and a script running them to explore what mktemp and its
-t and -p options actually do. Then I checked if the results are in accordance with the mktemp man
page.

First I present my test cases and their results. Then, based on the results I review the mktemp(1) manual page.


## Tests

I designed a set of exploratory test cases where each test is a particular
invocation of mktemp and the result is the list of temporary files created this way.

Each of my test cases either sets or unsets the
*TMPDIR* environment variable before it executes mktemp with 0 to 2 *template*s,
with or without a *-t prefix* option, and with or without a *-p tmpdir* option.

Variables *TEST_TEMP_DIR* and *FALLBACK_DIR* in the table below represent paths to existing directories.
Paths to the created temporary files in the result column are separated by space.

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

More test cases were run for the review of the manual page.
The presented test set was reduced to sufficiently reveal the behavior of mktemp for the sake of the argument.


## Man Page Review

### Synopsis Section

```
     mktemp [-d] [-p tmpdir] [-q] [-t prefix] [-u] template ...
     mktemp [-d] [-p tmpdir] [-q] [-u] -t prefix
```

In the first form the template argument is not mandatory.
The second form with a guaranteed -t prefix does still allow the use of
one or more template arguments which makes it identical to the first form and thus redundant.

The user would be much better served by:
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

The description is overly strict.
And again, we are talking file paths here, not file names.
The template may be any file path. There is no need to attach any number of Xs.
In case of a template without trailing Xs, no portion will be overwritten and the template will suffice
for exactly one such file existing at a given time.
A template without trailing Xs is of course of little practical use, but mktemp allows it, so the manual could mention it.

```
The trailing ‘Xs’ are replaced with the current process
number and/or a unique letter combination.
```

I don't know about other platforms but on FreeBSD 14 I don't get any process number in the file name.
The formulation poses no problem because of the "and/or" conjunction
but the "unique letter combination" is not exactly a letter combination (at least on FreeBSD 14).
It should say "a combination of alphanumeric characters (alnum in re_format(7))".

```
If the -t prefix option is given, mktemp will generate a template string
based on the prefix and the TMPDIR environment variable if set.  If the
-p option is set, then the given tmpdir will be used if the TMPDIR
environment variable is not set.  Finally, /tmp will be used if neither
TMPDIR or -p are set and used. [...]
```

This suggests that it makes only sense to use `[-p tmpdir]` in
conjunction with the `[-t prefix]` option as a fallback in case TMPDIR is not set. As if `[-t prefix [-p tmpdir]]` was in the synopsis.
This is not the case and mktemp will happily accept the *-p* option alone.

The *-p* option is not any kind of fallback. With it, mktemp simply ignores whether
the TMPDIR environment variable is set or not and tries to interpret the given templates (or the generated template)
as paths relative to the tmpdir set by the -p option.
That is, unless we also use the -p option, the -t option, and at least one template argument (see test cases 10, 20)

Instead of such details, all that the description needs to say here (but does not say!) is this:

```
Unless modified by the -t or -p options or the optional template argument,
mktemp tries to use the default template `$TMPDIR/tmp.XXXXXXXXXX`,
falling back to `/tmp/tmp.XXXXXXXXXX` if TMPDIR is not set.
```

This is much easier to read and in accordance with the actual behavior.
It also provides the missing information how long the alphanumeric sequence is by default.
All the other details should be said in the Options section.
Right here we can append the valid security warning from the rest of the paragraph:

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

Let me nitpick on the penultimate paragraph:

```
Any number of temporary files may be created in a single invocation,
including one based on the internal template resulting from the -t flag.
```

- It mentions some "internal template" but this term has not been introduced anywhere.
Instead, the term "generated template" should be used.
- -t is not a flag, it is an option.

A much better wording would be:

```
Any number of temporary files may be created in a single invocation
according to the supplied path templates ([template ...]).
Optionally, one extra path template can be automatically generated
and added to the zero or more supplied ones with the -t prefix option
(see the -t option description for details).
```

I have no issues with the last paragraph ("The mktemp utility is provided ...").


### Options

Here I shall focus only on the -p and -t options. 

#### -p tmpdir

```
Use tmpdir for the -t flag if the TMPDIR environment variable is not set. [...]
```
Well, yes, but it also uses tmpdir for the -t option if the TMPDIR environment variable *is* set.

```
[...] Additionally, any provided template arguments will be interpreted relative to the path specified as tmpdir. [...]
```
But if you also specify the -t prefix, only the generated template will be interpreted
relative to the path specified as tmpdir, not the provided template arguments,
see test cases 10, 20. (This may be a bug in the mktemp program.)

```
If tmpdir is either empty or omitted, then the TMPDIR environment variable will be used.
```
And if TMPDIR is not set, then use /tmp.

All this can be written much more precisely:

```
Interpret the provided templates or the generated temple as a path relative to tmpdir.
If tmpdir is either empty or omitted, then the TMPDIR environment variable (or the default /tmp) will be used as the template's parent directory.
If the -t option is provided, use tmpdir as path only for the generated template, not the template arguments.
```

#### -t prefix

```
Generate a template (using the supplied prefix and TMPDIR if set) to create a filename template.
```

So much information is missing here.  I suggest:
```
Generate a template based on TMPDIR and the supplied prefix
and add it to the templates provided by the template arguments.
The generated template has the format "$TMPDIR/${prefix}.XXXXXXXXXX".
TMPDIR can be optionally replaced by the -p tmpdir option.
/tmp will be used instead of TMPDIR if neither TMPDIR nor tmpdir are set.
Use of -t prefix together with -p tmpdir prevents -p tmpdir to have an effect on the provided templates (known issue).
```

And I would mention the last sentence also in a dedicated Bugs section.

## Side Note

This is of course of no importance to the point I am making in this whole post,
but I find it very unfortunate that *-p* is used for an option called "tmpdir" and *-t* is used for an option called "prefix".
When reading I had to make conscious effort to prevent myself from associating the *prefix* option with *-p* and *tmpdir* with *-t*.
My vexation was even greater once I found that *--tmpdir* is the long form of *-p*. Good job, really.
I understand that the letters used for the options were probably motivated by the words *p*ath and *t*emplate and that
this cannot be changed anymore as it would break pretty much every script using mktemp.

At least we can use mktemp as a great example of bad CLI option naming.
And we can stop mktemp from being an example of a bad manual page.
