#!/bin/bash

# This script looks for solutions to exercises in a "templates" folder
# in a set of standard locations:

TMPLT_PATH=". ../exercises $HOME/exercises"

# All folders in the templates folder must contain an src folder with
# starter files for a C/C++ exercise which are copied to the src folder,
# nested inc or include folder filess are copied to the include folder.
# Existing src and include files are copied to the src.back folder
# overwriting an existing back files.
# The template is built using the CMake in the current folder.

set -o nounset 
set -o errexit

function usage 
{
  echo $1 >&2
  cat  >&2 <<EOT
Usage: ${0#.*/} [--all | name of template]
  The name of the template is letetr case insensitive and
  can be abbreviated to the first few letters of the template folder.
  If no template is specified a list is displayed to select from.
  THe --all is designed for use in a CI build"
EOT
  exit 1
}

function get_template_dir {
  TMPLTDIR=
  for dir in $TMPLT_PATH ; do
    [[ -d $dir/templates ]] && TMPLTDIR="$dir/templates" && break
  done
  [[ -z $TMPLTDIR ]] && usage "Cannot find template folder"
  : # required due to bug in handling &&
}

# configurable variables

SOURCES="src include"
BACKUP=src.bak

TMPLT=
ALL=
for arg; do
  case "$arg" in
    --help|-h|-\?) usage ;;
    --all) ALL=1;;
    *)
      if [[ -n "$TMPLT" ]]; then
          usage "Unknown argument $arg: template al;ready set to $TMPLT"
      fi
      TMPLT="$arg"
      ;;
  esac
done

get_template_dir
tmplt=${TMPLT,,}
SOL=
DIRS=()

for t in "$TMPLTDIR"/*; do
  [[ ! -d $t/src ]] && continue
  name=$(basename $t)
  name=${name,,}
  if [[ -n "$tmplt" && $name == $tmplt* ]]; then
    if [[ -z "$SOL" ]]; then
      SOL="$t"
    else
      echo "Template name matched multiple folders:"
      echo "  $SOL"
      echo "  $t"
      exit 1
    fi
  fi
  DIRS+=("$name")
done

if [[ -z "$ALL" && -z "$SOL" ]]; then
  PS3="Select template to copy (q quits)? "
  COLUMNS=1
  select opt in "${DIRS[@]}" QUIT; do
    [[ $REPLY == $((${#DIRS[@]}+1)) || ${REPLY,,} == quit || ${REPLY,,} == q ]] && exit 1
    [[ -z "$opt" ]] && continue
    SOL=$(ls -d "$TMPLTDIR"/* | grep -i "$opt")
    break
  done
fi

if [[ -z "$ALL" ]]; then
  echo "Copying template $SOL"

  # clean/create backup folder

  if [[ -f CMakeLists.txt ]]; then
    for src in $SOURCES; do
      dir="$BACKUP/$src"
      if [[ -d "$dir" ]]; then
        rm -rf "$dir"/* 2>/dev/null
      else
        mkdir -p $dir
      fi
    done
  else
    usage "please run this script inside the root of your workspace"
  fi

  for src in $SOURCES; do
    echo "Moving '$src' files to '$BACKUP/$src'"
    mv "$src"/* "$BACKUP/$src" 2>/dev/null || true
  done
fi

if [[ -z $ALL ]]; then
  BUILD=("$SOL")
else
  BUILD=("$TMPLTDIR"/*)
fi

for SOL in "${BUILD[@]}"; do
  echo "Building template $SOL"
  # handle different template layouts

  for dir in $SOURCES; do
    mkdir -p $dir
    from="$SOL/$dir"
    [[ ! -d $from && $dir == include ]] && from="$SOL/inc"
    if [[ -d "$from" ]]; then
        [[ -z "$ALL" ]] && echo "Copying template files from $from"
        cp -f "$from"/* $dir 2>/dev/null || true
    fi
  done

  if ! ./build.sh reset 2>&1; then
    echo "Build failed for template $SOL"
    exit 1
  fi
done
