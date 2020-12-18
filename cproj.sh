#!/usr/bin/bash

function cproj() {
    cprojVersion="1.0.0"
    cprojSite="https://github.com/smadin/cproj"
    cprojMasterVersionUrl="$cprojSite/raw/master/VERSION"
    
    function checkCprojVersion() {
        verPat="^[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+$"
        if [[ -n "$(which curl)" ]]; then
            foundCurl="true"
            cprojMasterVersion=$(curl -L "$cprojMasterVersionUrl" 2>/dev/null)
        elif [[ -n "$(which wget)" ]]; then
            foundWget="true"
            cprojMasterVersion=$(wget -o /dev/null -O - "$cprojMasterVersionUrl")
        fi

        if [[ -z "$cprojMasterVersion" || ! "$cprojMasterVersion" =~ $verPat ]]; then
            echo "Cproj: unable to check latest version at $cprojMasterVersionUrl. Cproj may not be up to date."
        elif [[ "$cprojMasterVersion" =~ $verPat && "$cprojMasterVersion" != "$cprojVersion" ]]; then
            echo "Cproj: current version is $cprojVersion but version $cprojMasterVersion is available at $cprojSite."
        fi
    }

    echo "This is Cproj, v$cprojVersion."

    checkCprojVersion

    if [[ -z "$1" || "$1" == "-"* ]]; then
        echo "Cproj - C project scaffold generation"
        echo ""
        echo "cproj <projname>"
        echo "----------"
        echo "projname: the name of the new project for which to create a scaffold."
        echo "The new project will be generated in ./<projname>."
        echo ""
        echo "After generating a project, try:"
        echo "    $ cd <projname>"
        echo "    $ make all test"
        return 0
    fi

    projName=$1
    pwdBaseName=`basename $PWD`

    projNameUpper=`echo $projName | tr '[:lower:]' '[:upper:]'`
    projNameLower=`echo $projName | tr '[:upper:]' '[:lower:]'`

    randVal=$(($RANDOM % 100))

    if [[ ! -w "$PWD" ]]; then
        echo "cannot write to $PWD!"
        return 1
    fi

    if [[ "$pwdBaseName" != $projName ]]; then
        if [ ! -d "./$projName" ]; then
            mkdir -p ./$projName
        fi
        pushd ./$projName
        didPushdir="true"
    fi

    mkdir -p "src" "include" "test"

    if [[ -f /usr/local/include/scuttle.h && -f /usr/local/lib/scuttle/scuttle.sh ]]; then
        scuttleInvocation="bash /usr/local/lib/scuttle/scuttle.sh"
    elif [[ -n "$foundCurl" || -n "$foundWget" ]]; then
        mkdir -p "script"
        if [[ -n "$foundCurl" ]]; then
            curl -o script/scuttle.sh 
            curl -o include/scuttle.h
        else
            wget -P script "https://github.com/smadin/scuttle/raw/master/src/scuttle.sh"
            wget -P include "https://github.com/smadin/scuttle/raw/master/include/scuttle.h"
        fi
        scuttleInvocation="bash script/scuttle.sh"
    else
        echo "*** Warning: Cproj could not locate or fetch Scuttle. To use Scuttle for testing, you must install it and update the generated Makefile's test: target"
        scuttleInvocation="bash scuttle.sh"
    fi

    function writeHeader() {
        cat <<\EOF |
#ifndef _<<PROJNAME>>_H
#define _<<PROJNAME>>_H

#define <<PROJNAME>>_VER_MAJOR 1
#define <<PROJNAME>>_VER_MINOR 0
#define <<PROJNAME>>_VER_PATCH 0

#define _STR(x) #x
#define _XSTR(x) _STR(x)

#define <<PROJNAME>>_VER_STRING _XSTR(<<PROJNAME>>_VER_MAJOR) "." _XSTR(<<PROJNAME>>_VER_MINOR) "." _XSTR(<<PROJNAME>>_VER_PATCH)
#define <<PROJNAME>>_VER_NUM ((<<PROJNAME>>_VER_MAJOR * 1000000) + (<<PROJNAME>>_VER_MINOR * 1000) + (<<PROJNAME>>_VER_PATCH))

typedef struct {
    unsigned short major;
    unsigned short minor;
    unsigned short patch;
} <<ProjName>>Version;
const <<ProjName>>Version *CurrentVersion();

int <<projname>>();

#endif /* _<<PROJNAME>>_H */
EOF
        sed -e "s/<<PROJNAME>>/$projNameUpper/g" -e "s/<<ProjName>>/$projName/g" -e "s/<<projname>>/$projNameLower/g" > "include/$projNameLower.h"
    }

    function writeLibSource() {
        cat <<\EOF |
#include "<<projname>>.h"
#include <stdio.h>

int <<projname>>()
{
    return <<randval>>;
}
EOF
        sed -e "s/<<projname>>/$projNameLower/g" -e "s/<<randval>>/$randVal/g" > "src/lib$projNameLower.c"
    }

    function writeTestSuite() {
        cat <<\EOF |
#include "<<projname>>.h"
#include "test_lib<<projname>>.h"

SSUITE_INIT(<<projname>>_lib<<projname>>)
SSUITE_READY

STEST_SETUP
STEST_SETUP_END

STEST_TEARDOWN
STEST_TEARDOWN_END

STEST_START(<<projname>>_returns_val)
    int i = <<projname>>();
    SASSERT_EQ(<<randval>>, i)
STEST_END
EOF
        sed -e "s/<<projname>>/$projNameLower/g" -e "s/<<randval>>/$randVal/g" > "test/test_lib$projNameLower.c"
    }

    function writeMain() {
        cat <<\EOF |
#include "<<projname>>.h"
#include <stdio.h>

const <<ProjName>>Version currentVersion = {
    <<PROJNAME>>_VER_MAJOR,
    <<PROJNAME>>_VER_MINOR,
    <<PROJNAME>>_VER_PATCH
};

int main(int argc, char **argv)
{
    printf("This is <<ProjName>>, v%s.\n", <<PROJNAME>>_VER_STRING);
    int i = <<projname>>();
    printf("<<projname>>() returned %d\n", i);
    return 0;
}

const <<ProjName>>Version *CurrentVersion()
{
    return &currentVersion;
}
EOF
        sed -e "s/<<ProjName>>/$projName/g" -e "s/<<PROJNAME>>/$projNameUpper/g" -e "s/<<projname>>/$projNameLower/g" > "src/main.c"
    }

    function writeMakefile() {
        cat <<\EOF |
ifneq (,$(shell which clang))
CC      := clang
else ifneq (,$(shell which gcc))
CC      := gcc
endif
SRCDIR  := src
OBJDIR  := obj
INCDIR  := include
BINDIR  := bin
TESTDIR := test
CFLAGS  := -Wall -Werror $(patsubst %,-I%,$(INCDIR)) -c

ifdef DEBUG
    CFLAGS += -g
endif

LDFLAGS :=
SRC     := main.c \
           lib<<projname>>.c

OBJ     := $(SRC:.c=.o)
OBJS    := $(patsubst %,$(OBJDIR)/%,$(OBJ))
BIN     := <<projname>>

.PHONY: all clean dirs test

all: dirs test $(BINDIR)/$(BIN)

clean:
	$(MAKE) -C $(TESTDIR) clean
	rm -rf $(OBJDIR) $(BINDIR)

dirs:
	mkdir -p $(OBJDIR) $(BINDIR)

test: dirs $(OBJS)
	<<scuttle>> $(TESTDIR)
	$(MAKE) -C $(TESTDIR)
	cat $(TESTDIR)/log/test_<<projname>>.log

$(BINDIR)/$(BIN): $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $^

$(OBJDIR)/%.o: $(SRCDIR)/%.c
	$(CC) $(CFLAGS) -o $@ $<

EOF
        sed -e "s/<<projname>>/$projNameLower/g" -e "s,<<scuttle>>,$scuttleInvocation,g" > Makefile
    }

    writeHeader
    writeLibSource
    writeTestSuite
    writeMain
    writeMakefile

    if [[ -n "$didPushdir" ]]; then
        popd
    fi
}

