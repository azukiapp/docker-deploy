#! /bin/bash

. ${ROOT_PATH}/utils/utils.sh
load_configs

help() {
  echo "Usage:"
  echo "  $ deploy versions"
  echo ""
}

if [ $# -ge 1 ]; then
  help
  exit 1
fi

echo "⇲ Retrieving deployed versions..."
echo ""

OUTPUT_FILE='/tmp/versions.out'
ssh -p ${REMOTE_PORT} -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
  ${REMOTE_ROOT_USER}@${REMOTE_HOST} \
  "su ${REMOTE_USER} -c \"> ${OUTPUT_FILE} && tail -F ${OUTPUT_FILE} 2>/dev/null\"" &
TAIL_PID=$!

EXTRA_VARS="user=\"${REMOTE_USER}\" script_name=\"versions\" script_args=\"${REMOTE_GIT_PATH}\" output_file=\"${OUTPUT_FILE}\""
quiet ansible-playbook playbooks/run-remote.yml --extra-vars "${EXTRA_VARS}"

quiet kill ${TAIL_PID}
