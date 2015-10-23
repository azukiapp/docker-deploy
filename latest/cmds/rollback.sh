#!/bin/bash

. ${ROOT_PATH}/utils/utils.sh
load_configs

usage() {
  echo "Usage:"
  echo "  $ deploy rollback [ git-ref | --help ]"
  echo ""
  echo "Accepted git-ref:"
  echo "  - Default (no git-ref passed): previous version;"
  echo "  - Deploy version (e.g. v2);"
  echo "  - Branch name (e.g. master);"
  echo "  - Commit SHA1 (e.g. 880d01a);"
  echo "  - Tag (e.g. my-release);"
  echo ""
}

if [ $# -gt 1 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  usage
  exit 1
fi

echo "↻ App is being restored to ${1:-"previous version"}..."
echo ""

GIT_REF=${1:-"__PREVIOUS__"}
${ROOT_PATH}/cmds/run-remote.sh "rollback" "${GIT_REF}"
