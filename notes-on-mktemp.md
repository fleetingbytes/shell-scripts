# Exploratory Tests of mktemp and Understanding Its man Page

I find the man page on mktemp very difficult to read.
It did not make clear to me what each option does and what the exact result in each
invocation would be, especially when considering all the fallback scenarios.

Having studied the mktemp(1) very carefully, I used mktemp in a few scripts
and I was becoming suspicious that something is not quite the way it should be.
In the end I felt compelled to write some test cases and a script running them to explore what mktemp and its
-t and -p options actually do. Then I checked if the results are in accordance with the mktemp man
page.

First I present my test cases and their results. Then, based on the results I review the mktemp(1) man page.
In the end I offer some insights into my experience reading the mktemp man page as someone who wanted to
learn to use mktemp by reading its man page rather than just copy-pasting some pre-composed mktemp invocations
from somebody else's script.


## Tests

I designed a set of test cases, where each test executes a particular
invocation of mktemp and takes note of the paths of the created temporary
files as mktemp reports them.

Each of my test cases either sets or unsets the
*TMPDIR* environment variable before executing mktemp with 0 to 2 *template*s,
with or without a *-t prefix* option, and with or without a *-p tmpdir* option.


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
- Paths to the created temporary files in the Result column are separated by space.


## Man Page Review

### Synopsis Section

```
     mktemp [-d] [-p tmpdir] [-q] [-t prefix] [-u] template ...
     mktemp [-d] [-p tmpdir] [-q] [-u] -t prefix
```

These invocation forms are both wrong and contradictory. Template argument is never mandatory, -t prefix is always optional, as the tests reveal.
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
Again, we are talking file paths here, not file names.

```
The trailing ‘Xs’ are replaced with the current process
number and/or a unique letter combination.
```

Not exactly "a unique letter combination". I wish it said "a combination of alphanumeric characters (alnum in re_format(7))".

```
If the -t prefix option is given, mktemp will generate a template string
based on the prefix and the TMPDIR environment variable if set.  If the
-p option is set, then the given tmpdir will be used if the TMPDIR
environment variable is not set.  Finally, /tmp will be used if neither
TMPDIR or -p are set and used. [...]
```

Apart from how difficult to read this is, it suggests that it makes only senst to use `[-p tmpdir]` in
conjunction with the `[-t prefix]` option as a fallback in case TMPDIR is not set. As if `[-t prefix [-p tmpdir]]` was in the synopsis.
This is not the case and mktemp happily accepts the *-p* option alone.

The *-p* option, is not any kind of fallback. With it, mktemp simply ignores whether
the TMPDIR environment variable is set or not and tries to create the temporary files in the
tmpdir set by the -p option.
That is, unless we also use the -t option and at least one template argument (see testcases 10, 20)

Instead of such details, all that the description needs to say here (but does not say!) is this:

```
Unless modified by the -t or -p options or the optional template argument,
mktemp tries to use the default template `$TMPDIR/tmp.XXXXXXXXXX`,
falling back to `/tmp/tmp.XXXXXXXXXX` if TMPDIR is not set.
```

This is much easier to read and in accordance with the actual behavior.
It also provides the missing information how long the alphanumeric sequence is by default.
To this we can append the valid security warning from the rest of the paragraph:

```
Care should be taken to ensure that it is
appropriate to use an environment variable potentially supplied by the
user.
```

The next paragraph of the description now becomes redundant
but it serves as a good check for undestanding mktemp's behavior:
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
Any number of temporary files may be created in a single invocation according to the
supplied path templates ([template ...]). One generated path template
can be added to the zero or more supplied ones with the -t prefix option (see the -t option description for details).
```

I have no issues with the last paragraph ("The mktemp utility is provided ...").


### Options

Here I shall focus only on the -p and -t options. 

#### -p tmpdir

```
Use tmpdir for the -t flag if the TMPDIR environment variable is not set. [...]
```
Yes, but also use tmpdir if the TMPDIR environment variable *is* set. 

```
Additionally, any provided template arguments will be interpreted relative to the path specified as tmpdir. [...]
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
Interpret all provided template arguments relative to the path specified as tmpdir.
If tmpdir is either empty or omitted, then the TMPDIR environment variable (or the default /tmp) will be used.
If the -t option is provided, use tmpdir as path only for the generated template, not the template arguments (bug?).
```

#### -t prefix

```
Generate a template (using the supplied prefix and TMPDIR if set) to create a filename template.
```

It should mention five more things:
- the generated template is "$TMPDIR/${prefix}.XXXXXXXXXX"
- fallback to  "/tmp/${prefix}.XXXXXXXXXX" if TMPDIR is not set
- TMPDIR can be optionally replaced by the -p tmpdir option
- generated template is added to the provided templates ([template ...]) and is completely independent from them
- it claims the -p tmpdir for the generated template only and stops the -p tmpdir to have an effect on the provided templates (bug?)


## My Thoughts When Reading the mktemp(1) Page

### Synopsis

Why are there two distinct invocation forms and what are they trying to tell us?
That you must use at least one *template* positional argument?
That once you use the *-t prefix* option you can no longer provide a *template* positional argument?
So, is template a not mandatory argument?
Is -t prefix optional or mandatory?

Perhaps they wanted to write these two invocation forms instead:
```
     mktemp [-d] [-p tmpdir] [-q] [-u] template ...
     mktemp [-d] [-p tmpdir] [-q] [-u] -t prefix
```
Because you may get surprised when you try to use both your own templates and the -t prefix.
But doing so is not forbidden, so I guess they added the -t prefix option into the first
invocation form, although that creates all the confusion I just laid out.

### Description

```
The mktemp utility takes each of the given file name templates [...]
```

Having read the synopsis (I partly ignored for its confusing nature) and these introductory words,
a firm undestanding was established in my mind that mktemp works (only!) with the sort of templates provided in the positional template argument.
The handful of the slightest hints buried further in the text indicating that the -t prefix is a
more convenient, if not the preferred way to provide a template simply could not enter my imagination anymore.

```
If the -t prefix option is given, mktemp will generate a template string
based on the prefix and the TMPDIR environment variable if set.  If the
-p option is set, then the given tmpdir will be used if the TMPDIR
environment variable is not set.  Finally, /tmp will be used if neither
TMPDIR or -p are set and used. [...]
```

This is probably the part that is the hardest to read.
And also it is either wrong or mktemp has a bug.

Congratulate yourelf if you managed to distinguish the "tmpdir" option from the "TMPDIR" environment variable.

```
Any number of temporary files may be created in a single invocation,
including one based on the internal template resulting from the -t flag.
```

- Intuitively I had expected that the -t prefix opion would somehow affect the templates
provided as the template argument. That is not the case. And it hit me only after I started using
and testing mktemp.
- Third, having read and studied the mktemp man page very carefully, I was dead certain that
mktemp would only produce as many files as you provide templates.
A much clearer wording would have been:

I find it most unfortunate that -t has been chosen for prefix and -p for tmpdir.

### Options

It is most peculiar that the short form -p requires a tmpdir argument, but the long form --tmpdir does not.
