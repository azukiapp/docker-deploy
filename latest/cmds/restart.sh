#! /bin/bash

. ${ROOT_PATH}/utils/utils.sh
load_configs

help() {
  echo "Usage:"
  echo "  $ deploy restart"
  echo ""
}

if [ ! $# -eq 0 ]; then
  help
  exit 1
fi

${ROOT_PATH}/cmds/run-remote.sh "azk-start"
