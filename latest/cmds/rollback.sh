#! /bin/sh

help() {
  echo "Usage:"
  echo "  $ azk shell deploy -- rollback GIT-REF"
  echo ""
  echo "Accepted GIT-REF:"
  echo "  - Deploy version (e.g. v2);"
  echo "  - Branch name (e.g. master);"
  echo "  - Commit SHA1 (e.g. 880d01a);"
  echo "  - Tag (e.g. my-release);"
  exit
}

{ [ ! $# -eq 1 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; } && help

quiet() {
  "${@}" >/dev/null 2>&1
}

export ANSIBLE_HOST_KEY_CHECKING=False
GIT_REF=${1}
OUTPUT_FILE='/tmp/rollback.out'
EXTRA_VARS="user=\"${REMOTE_USER}\" git_ref=\"${GIT_REF}\" output_file=\"${OUTPUT_FILE}\""

[ "${GIT_REF}" = "--list" ] && EXTRA_VARS="${EXTRA_VARS} git_dir=\"${REMOTE_GIT_PATH}\" op=\"list\""

ssh -p ${REMOTE_PORT} ${REMOTE_ROOT_USER}@${REMOTE_HOST} "su ${REMOTE_USER} -c \"echo > ${OUTPUT_FILE} && tail -F ${OUTPUT_FILE} 2>/dev/null\"" &
TAIL_PID=$!

quiet ansible-playbook playbooks/rollback.yml -vvv --extra-vars "${EXTRA_VARS}"

quiet kill ${TAIL_PID}
