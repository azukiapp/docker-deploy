#!/bin/bash

. ${ROOT_PATH}/utils/utils.sh
load_configs

usage() {
  echo "Usage:"
  echo "  $ deploy versions"
  echo ""
}

if [ $# -ge 1 ]; then
  usage
  exit 1
fi

echo "⇲ Retrieving deployed versions..."
echo ""

${ROOT_PATH}/cmds/run-remote.sh "versions" "${REMOTE_GIT_PATH}"
