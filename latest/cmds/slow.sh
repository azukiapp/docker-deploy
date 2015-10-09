#! /bin/bash

abs_dir() {
  cd "${1%/*}"; link=`readlink ${1##*/}`;
  if [ -z "$link" ]; then pwd; else abs_dir $link; fi
}

ROOT_PATH=`abs_dir ${BASH_SOURCE:-$0}`

. ${ROOT_PATH}/../utils.sh

help() {
  echo "Usage:"
  echo "  $ deploy fast"
  echo ""
}

if [ $# -ge 1 ]; then
  help
  exit 1
fi

export RUN_SETUP='true'
export RUN_CONFIGURE='true'
export RUN_DEPLOY='true'
require run.sh
