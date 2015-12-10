set -e

check_remote_host() {
  if [ -z ${REMOTE_HOST} ]; then
    echo
    echo "We're sorry, but azk couldn't detect to which server you want to deploy your application."
    echo
    echo "If you're going to deploy using a provider (e.g. DigitalOcean), perform a full deployment"
    echo "by running:"
    echo "  $ azk deploy full"
    echo
    echo "Otherwise, if you want to deploy directly to a server using its IP, be sure to add it into"
    echo "'deploy' system envs in the Azkfile.js. Check this link for a reference:"
    echo "  http://to.azk.io/DEPLOY_NO_REMOTE_HOST"
    echo
    exit 1
  fi

  if [ "${CHECK_SSH}" = "true" ]; then
    RETRY=0; MAX_RETRY=3
    until [ ${RETRY} -ge ${MAX_RETRY} ]; do
      quiet nc -zw10 ${REMOTE_HOST} ${REMOTE_PORT} && break
      RETRY=`expr ${RETRY} + 1`
      echo "Server is not accepting SSH connections yet. Retrying... (${RETRY}/${MAX_RETRY})"
      sleep 5
    done

    if [ ${RETRY} -ge ${MAX_RETRY} ]; then
      echo
      echo "Failed to connect to server. Please, try again."
      clear_config "REMOTE_HOST"
      exit 1
    fi
  fi
}

generate_authorized_keys() {
  cat ${LOCAL_ROOT_DOT_SSH_PATH}/*.pub > playbooks/roles/configure/files/authorized_keys
}

generate_ansible_config_file() {
  mkdir -p /etc/ansible
  (
    echo -n "default ansible_ssh_host=${REMOTE_HOST} "
    echo -n "ansible_ssh_port=${REMOTE_PORT} "
    echo -n "ansible_ssh_user=${REMOTE_ROOT_USER} "
    ( [ ! -z ${REMOTE_ROOT_PASS} ] && echo -n "ansible_ssh_pass=${REMOTE_ROOT_PASS}" ) || true
    echo ""
  ) > /etc/ansible/hosts
}

export_envs() {
  export ANSIBLE_HOST_KEY_CHECKING=False

  if ( cd ${LOCAL_PROJECT_PATH}; git remote | grep -q "^${GIT_REMOTE}$" ); then
    export REMOTE_PROJECT_PATH=$( cd ${LOCAL_PROJECT_PATH}; git remote -v | grep -E "^${GIT_REMOTE}\t" | head -1 | awk '{ print $2 }' | sed -r 's/.*\:\/\/.*@[^:]*(:[0-9]+)?//' | sed 's/\.git//' )
  else
    [ -z ${REMOTE_PROJECT_PATH_ID} ] && \
      export REMOTE_PROJECT_PATH_ID=$( date +%s | sha256sum | head -c 7 )
    [ -z $REMOTE_PROJECT_PATH ] && \
      export REMOTE_PROJECT_PATH="/home/${REMOTE_USER}/${REMOTE_PROJECT_PATH_ID}"
  fi
  export REMOTE_GIT_PATH="${REMOTE_PROJECT_PATH}.git"
}

. /azk/deploy/utils/envs.sh

check_remote_host
generate_authorized_keys
generate_ansible_config_file
export_envs

set +e
