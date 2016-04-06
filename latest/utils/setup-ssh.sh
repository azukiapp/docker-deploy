setup_ssh_keys() {
  LOCAL_ROOT_DOT_SSH_PATH="/root/.ssh"
  PERSISTENT_SSH_PATH="${LOCAL_DOT_CONFIG_PATH}/ssh"
  mkdir -p ${PERSISTENT_SSH_PATH}

  SSH_PRIVATE_KEY_FILE_PATH="${LOCAL_ROOT_DOT_SSH_PATH}/${SSH_PRIVATE_KEY_FILE:-id_rsa}"
  SSH_PUBLIC_KEY_FILE_PATH="${SSH_PRIVATE_KEY_FILE_PATH}.pub"
  SSH_KEY_NAME="${SSH_KEY_NAME}"

  LOCAL_DOT_SSH_PATH=${LOCAL_DOT_SSH_PATH:-"/azk/deploy/.ssh"}

  if [ ! -L ${LOCAL_ROOT_DOT_SSH_PATH} ]; then
    if [ -d ${LOCAL_ROOT_DOT_SSH_PATH} ]; then
      echo "Ops, you should mount your '.ssh' folder on ${LOCAL_DOT_SSH_PATH}."
      exit 1
    else
      ln -s ${PERSISTENT_SSH_PATH} ${LOCAL_ROOT_DOT_SSH_PATH}
    fi
  fi

  if [ -d ${LOCAL_DOT_SSH_PATH} ] && quiet ls ${LOCAL_DOT_SSH_PATH}/*.pub; then
    if [ "${LOCAL_DOT_SSH_PATH%/}" != "${LOCAL_ROOT_DOT_SSH_PATH}" ]; then
      cp -R ${LOCAL_DOT_SSH_PATH}/${SSH_PRIVATE_KEY_FILE}* ${LOCAL_ROOT_DOT_SSH_PATH}
    fi
  else
    if ! quiet ls "${SSH_PUBLIC_KEY_FILE_PATH}"; then
      ssh-keygen -t rsa -b 4096 -N "" -f "${SSH_PRIVATE_KEY_FILE_PATH}"
    fi
  fi
}

set -e

setup_ssh_keys

# Avoid git to check the identity of the remote host
export GIT_SSH="${ROOT_PATH}/utils/git-deploy.sh"

# Avoid Ansible to buffer and suppress its output
export PYTHONUNBUFFERED=1

set +e
