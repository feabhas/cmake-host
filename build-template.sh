#!/bin/bash

# This script looks for exercise templates
# in a set of standard locations:

TEMPLATE_PATH="./exercises . ../exercises .. $HOME/exercises $HOME"
SOURCES="src include"
BASE=base.tar.gz
FILES=".devcontainer .vscode build.sh build-one.sh CMake* $SOURCES"

# All folders in the templates folder must contain a src folder with
# starter files for a C/C++ exercise which are copied to the src folder,
# nested inc or include folder filess are copied to the include folder.
# Existing src and include files are copied to the src.back folder
# overwriting an existing back files.
# The template may be built using the CMake in the current folder.

set -o nounset 
set -o errexit

function usage 
{
  echo $1 >&2
  cat  >&2 <<EOT
Usage: ${0#.*/} [[exercises]
  Create new sub-projects in this folder copying from each 
  project in the 'templates' sub-folder of the 'exercises'
  folder given on the command line (default: this folder).
    --build  builds each template using CMake, also -b
    --keep   keeps original project structure, also -k
             default is to copy to a 'project' subfolder
    --help   this help message, also -h -?
EOT
  exit 1
}

function get_template_dir {
  TEMPLATE_DIR=
  for dir in $TEMPLATE_PATH ; do
    echo "Looking in $dir"
    if [[ -d $dir/templates ]]; then
      TEMPLATE_DIR="$dir/templates"
      break
    fi
  done
  [[ -z $TEMPLATE_DIR ]] && usage "Cannot find template folder"
  : # required due to bug in handling &&
}


TEMPLATE=
ALL=
BUILD=
KEEP=
for arg; do
  case "$arg" in
    --help|-h|-\?) usage ;;
    --build|-b) BUILD=1 ;;
    --keep|-k) KEEP=1 ;;
    *)
      if [[ -n "$TEMPLATE" ]]; then
          usage "Unknown argument $arg: template already set to $TEMPLATE"
      fi
      TEMPLATE="$arg"
      ;;
  esac
done

get_template_dir
TEMPLATE=${TEMPLATE,,}
SOL=
DIRS=()

SOLUTIONS_DIR=$(dirname $TEMPLATE_DIR)/solutions

for t in "$TEMPLATE_DIR"/*; do
  [[ ! -d "$t/src" ]] && continue
  echo "Cloning from template $t"
  name=$(basename $t)
  name=${name,,}

  rm -rf src/* include/*
  for dir in $SOURCES; do
    if [[ -d "$t/$dir" ]]; then
        cp -rf "$t/$dir"/* $dir 2>/dev/null || true
    elif [[ $dir == include && -d "$t/inc" ]]; then
      cp -rf "$t/inc"/* $dir 2>/dev/null || true
    fi
  done

  mkdir -p "$name"
  tar c -O $FILES | (cd "$name"; tar xf -)
  cp -r $SOLUTIONS_DIR $name
  if [[ -n $BUILD ]]; then 
    if ! (cd "$name"; ./build.sh reset 2>&1); then
      echo "Build failed for template $SOL"
      exit 1
    fi
    rm -rf "$name/build" 2>/dev/null || true
  fi
done

if [[ -z $KEEP ]]; then
  mkdir -p project 2>/dev/null || true
  mv $FILES project
fi
