[ -z ${LOCAL_PROJECT_PATH} ] && LOCAL_PROJECT_PATH="/azk/deploy/src"

if [ ! -d ${LOCAL_PROJECT_PATH} ]; then
  echo "Failed to locate source dir ${LOCAL_PROJECT_PATH}"
  exit 1
fi

quiet() {
  ( $@ ) > /dev/null 2>&1
}

set -e

LOCAL_ROOT_DOT_SSH_PATH="/root/.ssh"
[ -z ${LOCAL_DOT_SSH_PATH} ] && LOCAL_DOT_SSH_PATH="/azk/deploy/.ssh"
mkdir -p ${LOCAL_ROOT_DOT_SSH_PATH}
if [ -d ${LOCAL_DOT_SSH_PATH} ] && quiet ls ${LOCAL_DOT_SSH_PATH}/*.pub; then
  if [ "${LOCAL_DOT_SSH_PATH%/}" != "${LOCAL_ROOT_DOT_SSH_PATH}" ]; then
    cp -R ${LOCAL_DOT_SSH_PATH}/* ${LOCAL_ROOT_DOT_SSH_PATH}
  fi
else
  if ! quiet ls ${LOCAL_ROOT_DOT_SSH_PATH}/id_rsa.pub; then
    ssh-keygen -t rsa -b 4096 -N "" -f ${LOCAL_ROOT_DOT_SSH_PATH}/id_rsa
  fi
fi

set +e
