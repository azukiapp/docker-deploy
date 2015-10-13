#! /bin/bash

. ${ROOT_PATH}/utils/utils.sh
load_configs

help() {
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
  help
  exit 1
fi

echo "↻ App is being restored to ${1:-"previous version"}..."
echo ""

OUTPUT_FILE='/tmp/rollback.out'
ssh -p ${REMOTE_PORT} -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
  ${REMOTE_ROOT_USER}@${REMOTE_HOST} \
  "su ${REMOTE_USER} -c \"> ${OUTPUT_FILE} && tail -F ${OUTPUT_FILE} 2>/dev/null\"" &
TAIL_PID=$!

GIT_REF=${1:-"__PREVIOUS__"}
EXTRA_VARS="user=\"${REMOTE_USER}\" script_name=\"rollback\" script_args=\"${GIT_REF}\" output_file=\"${OUTPUT_FILE}\""
quiet ansible-playbook playbooks/run-remote.yml --extra-vars "${EXTRA_VARS}"

quiet kill ${TAIL_PID}
