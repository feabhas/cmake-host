#!/bin/bash
DISCLAIMER='
// -----------------------------------------------------------------------------
// main program
//
// DISCLAIMER:
// Feabhas is furnishing this item "as is". Feabhas does not provide any
// warranty of the item whatsoever, whether express, implied, or statutory,
// including, but not limited to, any warranty of merchantability or fitness
// for a particular purpose or any warranty that the contents of the item will
// be error-free.
// In no respect shall Feabhas incur any liability for any damages, including,
// but limited to, direct, indirect, special, or consequential damages arising
// out of, resulting from, or any way connected to the use of the item, whether
// or not based upon warranty, contract, tort, or otherwise; whether or not
// injury was sustained by persons or property or otherwise; and whether or not
// loss was sustained from, or arose out of, the results of, the item, or any
// services that may be provided by Feabhas.
// -----------------------------------------------------------------------------
'
set -o nounset 
set -o errexit

CMAKE='cmake'
if ! $CMAKE --version >/dev/null 2>&1; then
    echo "Cannot find cmake command: $CMAKE" >&2
    exit 1
fi

GENERATOR='Ninja'
BUILD_OPTIONS=
BUILD_VERBOSE='-v'

# Ninja build does not work with C++20 Modules
if [[ -n $(type -p ninja) && ! -f src/Modules.txt ]]; then
  echo "Build generator: ninja $(ninja --version)"
elif [[ -n $(type -p make) ]]; then
  echo "Build generator: $(make --version | head -1)"
  GENERATOR='Unix Makefiles'
  BUILD_OPTIONS='--no-print-directory'
  BUILD_VERBOSE='VERBOSE=1'
else
  echo "Cannot find 'ninja' or GNU 'make' command:" >&2
  exit 1
fi

function usage {
  cat <<EOT
Usage: ${0#.*/} [options...]
  Wrapper around cmake build system.
  Generate options:
    reset      -- generate (always) and build
    debug      -- generate/build debug version (default)
    release    -- generate/build release version
    --Cnn      -- set C langauge version to nn, also -c
    --C++nn    -- set C langauge version to nn, also -cpp -CPP
    -Dvar=val  -- define a CMake variable which must have a value
   Build options:
    --verbose  -- show compiler commands also -v
    clean      -- remove object files and build
    test       -- run cmake with test target after a build
    clang-tidy -- run clang-tidy after a build
  Other options:
    --c        -- generate main.c if it doesn't exist, also -C
    --c++      -- generate main.cpp if it doesn't exist, also -cpp -C++
    --help     -- this help information, also -h -?
 
  Output written to build/debug (or build/release), executables:
      build/debug/Application
  Generates compile_commands.json used by tools like clang-tidy.
  Set clang_tidy options using -DCLANG_TIDY_OPTIONS="options"
  Script will generate a missing main.c/main.cpp based on the
  hostname: those staring with c- or ac- are C otherwise C++.
EOT
  exit 1
}

function main_template {
    LANG="${1:-}"
    if [[ -z $LANG ]]; then
        if [[ $HOSTNAME == *c-* ]]; then
            LANG=c
        else
            LANG=cpp
        fi
    fi
    if [[ $LANG = c ]]; then
        echo "Generating src/main.c"
        cat >src/main.c <<EOT
${DISCLAIMER}
#include <stdio.h>

int main(void)
{
    printf("Hello world!\n");
    return 0;
}
EOT
    else
        echo "Generating src/main.cpp"
        cat >src/main.cpp <<EOT
${DISCLAIMER}
#include <iostream>

int main()
{
    std::cout << "Hello world!\n";
}
EOT
    fi
}


BUILD=build
CONFIG=debug
RESET=
CLEAN=
CMAKE_OPTS=
LANG=
VERBOSE=
TEST=
CLANG_TIDY=

for arg; do
  case "$arg" in
    --help|-h|-\?) usage    ;;
    --verbose|-v)  VERBOSE="$BUILD_VERBOSE"  ;;
    debug)         CONFIG=debug ;;
    release)       CONFIG=release ;;
    test)          TEST=1   ;;
    clang-tidy)    CLANG_TIDY=1 ;;
    clean)         CLEAN=--clean-first ;;
    reset)         RESET=1  ;;
    --[cC])        LANG=c   ;;
    --cpp|--CPP|--[cC]++)   
                   LANG=cpp ;;
    --[cC][0-9][0-9]) 
                   CMAKE_OPTS="$CMAKE_OPTS -DCMAKE_C_STANDARD=${arg#--[cC]}" ;;
    --[cC]++[0-9][0-9]|--CPP[0-9][0-9]|--cpp[0-9][0-9]) 
                   CMAKE_OPTS="$CMAKE_OPTS -DCMAKE_CXX_STANDARD=${arg#--[cC]??}" ;;
    -D*)           CMAKE_OPTS="$CMAKE_OPTS $arg" ;;
    *)
      echo "Unknown option $arg" >&2
      usage
      ;;
  esac
done

# generate main.c/main.cpp if required

[[ ! -d src ]] && mkdir src
[[ ! -d include ]] && mkdir include

if [[ ! -f src/main.c && ! -f src/main.cpp ]]; then
  main_template $LANG
fi

# force clean generate

FSTAMP='.files.md5'
old=
if [[ -f "$FSTAMP" ]]; then
    old=$(cat $FSTAMP)
fi
find include src -name '*.[ch]' -o -name '*.cpp' | md5sum >$FSTAMP
new=$(cat $FSTAMP)
[[ "$old" != "$new" ]] && RESET=1

if [[ -n $RESET && -d $BUILD/$CONFIG ]]; then
  rm -rf $BUILD/$CONFIG
elif [[ ! -d $BUILD/$CONFIG ]]; then
  RESET=1
fi

# run cmake

if [[ -n $RESET ]]; then
    $CMAKE --preset ${CONFIG} -G "$GENERATOR"  $CMAKE_OPTS
fi

if $CMAKE --build --preset ${CONFIG} ${CLEAN} -- $BUILD_OPTIONS $VERBOSE
then
  if [[ -n $CLANG_TIDY ]]; then
    $CMAKE --build --preset clang-tidy
  fi
  if [[ -n $TEST ]]; then
    $CMAKE --build --preset test
  fi
else
  exit $?
fi
