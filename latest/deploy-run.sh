set -e

echo > playbooks/roles/configure/files/authorized_keys
cat ${LOCAL_ROOT_DOT_SSH_PATH}/*.pub >> playbooks/roles/configure/files/authorized_keys

[ -z ${REMOTE_HOST} ] && echo "REMOTE_HOST is missing." && exit 1

export ANSIBLE_HOST_KEY_CHECKING=False

. /azk/deploy/envs.sh

if ( cd ${LOCAL_PROJECT_PATH}; git remote | grep -q "^${GIT_REMOTE}$" ); then
  REMOTE_PROJECT_PATH=$( cd ${LOCAL_PROJECT_PATH}; git remote -v | grep -P "^${GIT_REMOTE}\t" | head -1 | awk '{ print $2 }' | sed 's/.*\:\/\/.*@[^:]*\(:[0-9]\+\)\?//' | sed 's/\.git//' )
else
  [ -z ${REMOTE_PROJECT_PATH_ID} ] && \
    REMOTE_PROJECT_PATH_ID=$( date +%s | sha256sum | head -c 7 )
  [ -z $REMOTE_PROJECT_PATH ] && \
    REMOTE_PROJECT_PATH="/home/${REMOTE_USER}/${REMOTE_PROJECT_PATH_ID}"
fi
REMOTE_GIT_PATH="${REMOTE_PROJECT_PATH}.git"

(
  echo -n "default ansible_ssh_host=${REMOTE_HOST} "
  echo -n "ansible_ssh_port=${REMOTE_PORT} "
  echo -n "ansible_ssh_user=${REMOTE_ROOT_USER} "
  ( [ ! -z ${REMOTE_ROOT_PASS} ] && echo -n "ansible_ssh_pass=${REMOTE_ROOT_PASS}" ) || true
) > /etc/ansible/hosts

if [ -z ${RUN_SETUP} ] || [ "${RUN_SETUP}" = "true" ]; then
  # Provisioning
  ansible-playbook playbooks/setup.yml
  ansible-playbook playbooks/reset.yml || true
fi

if [ -z ${RUN_CONFIGURE} ] || [ "${RUN_CONFIGURE}" = "true" ]; then
  # Configuring
  ansible-playbook playbooks/configure.yml --extra-vars "user=${REMOTE_USER} src_dir=${REMOTE_PROJECT_PATH} git_dir=${REMOTE_GIT_PATH} azk_domain=${AZK_DOMAIN}"
fi

if [ -z ${RUN_DEPLOY} ] || [ "${RUN_DEPLOY}" = "true" ]; then
  # copy envs
  ansible-playbook playbooks/envs.yml --extra-vars "\
    user=${REMOTE_USER} env_file=${ENV_FILE} local_project_path=\"${LOCAL_PROJECT_PATH}\" \
    remote_project_path=\"${REMOTE_PROJECT_PATH}\" git_reference=${GIT_CHECKOUT_COMMIT_BRANCH_TAG} \
    azk_domain=${AZK_DOMAIN} azk_agent_start_command=\"${AZK_AGENT_START_COMMAND}\" azk_host=\"${AZK_HOST:-$AZK_HOST_IP}\" \
    azk_restart_command=\"${AZK_RESTART_COMMAND}\"
    "

  # Deploying
  (
    cd ${LOCAL_PROJECT_PATH}
    quiet git remote rm ${GIT_REMOTE} || true
    quiet git remote add ${GIT_REMOTE} ssh://${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PORT}${REMOTE_GIT_PATH} || true
    git push ${GIT_REMOTE} ${GIT_CHECKOUT_COMMIT_BRANCH_TAG}
  )
fi

echo
echo "App successfully deployed at ${AZK_HOST:-"http://$REMOTE_HOST"}"

set +e
