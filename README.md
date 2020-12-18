# Cproj

Convenience shell function for C project scaffolding

v1.0.0

MIT License, &copy; 2020 Scott Madin <smadin@gmail.com>

## Overview

*Cproj* is a Bash function which builds out a skeleton for a C project, similar to a typical IDE's "new project" functionality: creating a root directory with a standard subdirectory structure and populating it with some initial boilerplate, to relieve the developer of as much tedium as possible.

## Installation

Copy `cproj.sh` into some appropriate location, and update your `.bashrc` or `.profile` so that the script will be sourced when the shell starts. For example, I keep a `~/.scripts/` directory, and include this in my `.bashrc`:

```bash
for file in $HOME/.scripts/*.sh; do
    . "$file"
done
```

## Usage

Cproj defines a shell function `cproj(<projname>)` which creates a project directory `./<projname>/`, and populates it with a basic subdirectory structure and set of files:

    /home/user/dev $ cproj sample
    This is Cproj, v1.0.0

    Created project in /home/user/dev/sample
    To build, enter:
        cd sample
        make all test
    /home/user/dev $ cd sample
    /home/user/dev/sample $ ls -F
    include/ LICENSE Makefile README.md src/ test/
    /home/user/dev/sample $ ls -F src include test
    include:
    sample.h

    src:
    sample_main.c sample_lib.c

    test:
    test_sample_lib.c

    /home/user/dev/sample $ make all
    [build messages]
    /home/user/dev/sample $ ls -F
    bin/ include/ LICENSE Makefile obj/ README.md src/ test/
    /home/user/dev/sample $ ./bin/sample
    This is sample, v0.0.0

    /home/user/dev/sample $ make test
    This is Scuttle, v1.0.0
    [build messages]
    cat test/log/test_sample.log
    Test suite sample_lib:
    *** Suite passed: 1 / 1 tests passed.
    *** 1 / 1 suites passed.

If Scuttle is installed in the standard location (`/usr/local/include/scuttle.h`, `/usr/local/lib/scuttle/scuttle.sh`), the skeleton Cproj builds will use that installation. If not, Cproj will attempt to fetch `scuttle.sh` into a new `script/` subdirectory of the project, and `scuttle.h` into `include/`.
