#! /bin/bash

. ${ROOT_PATH}/utils/utils.sh
load_configs

usage() {
  echo "Usage:"
  echo "  $ run-remote <script-name>"
  echo ""
  echo "This will run /home/<remote-user>/bin/<script-name> in the remote server"
  echo ""
}

if [ $# -eq 0 ]; then
  usage
  exit 1
fi

SCRIPT_NAME=$1
SCRIPT_ARGS=$2

${ROOT_PATH}/cmds/ssh.sh "/home/${REMOTE_USER}/bin/${SCRIPT_NAME} ${SCRIPT_ARGS}"
