#!/bin/bash

. ${ROOT_PATH}/utils/utils.sh
load_configs

usage() {
  echo "Usage:"
  echo "  $ deploy full"
  echo ""
}

if [ $# -ge 1 ]; then
  usage
  exit 1
fi

export RUN_SETUP='true'
export RUN_CONFIGURE='true'
export RUN_DEPLOY='true'
require cmds/run.sh
