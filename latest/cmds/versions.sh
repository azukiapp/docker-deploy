#! /bin/bash

abs_dir() {
  cd "${1%/*}"; link=`readlink ${1##*/}`;
  if [ -z "$link" ]; then pwd; else abs_dir $link; fi
}

ROOT_PATH=`abs_dir ${BASH_SOURCE:-$0}`

. ${ROOT_PATH}/../utils.sh

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
ssh -p ${REMOTE_PORT} ${REMOTE_ROOT_USER}@${REMOTE_HOST} \
  "su ${REMOTE_USER} -c \"> ${OUTPUT_FILE} && tail -F ${OUTPUT_FILE} 2>/dev/null\"" &
TAIL_PID=$!

EXTRA_VARS="user=\"${REMOTE_USER}\" script_name=\"versions\" script_args=\"${REMOTE_GIT_PATH}\" output_file=\"${OUTPUT_FILE}\""
quiet ansible-playbook playbooks/run-remote.yml --extra-vars "${EXTRA_VARS}"

quiet kill ${TAIL_PID}
