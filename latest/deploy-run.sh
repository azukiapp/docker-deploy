set -e

echo > playbooks/roles/configure/files/authorized_keys
cat ${LOCAL_ROOT_DOT_SSH_PATH}/*.pub >> playbooks/roles/configure/files/authorized_keys

[ -z ${REMOTE_HOST} ] && echo "REMOTE_HOST is missing." && exit 1

export ANSIBLE_HOST_KEY_CHECKING=False

analytics_track() {
  [ "${DISABLE_ANALYTICS_TRACKER}" = "true" ] && return

  PROJECT_ID="55f3c582672e6c30ab510f67"
  WRITE_KEY="3901d75fa570c3cd6b94762af86c5d371c0f29bd9bb292a475edb87d1a4a1b44d06ab2c63ee70dadd9a13201807398650bbf11d2da38b01f521048615c08868522b90ed6d648f50181c81307014adea91b88f4a3e1aca570d593a242fb758c5ef6fa21046fa7dc2e166d6b6b77d210a6"

  COLLECTION="${1:-"deploy"}"
  DATA="${2}"

  curl -s "http://api.keen.io/3.0/projects/$PROJECT_ID/events/${COLLECTION}" \
    -H "Authorization: $WRITE_KEY" \
    -H 'Content-Type: application/json' \
    -d "${DATA}" \
    -o /dev/null
}

analytics_track "deploy-start" "{ \"mid\": \"${AZK_MID}\", \"uid\": \"${AZK_UID}\" }"

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
  ansible-playbook playbooks/configure.yml --extra-vars "\
    user=${REMOTE_USER} env_file=${ENV_FILE} local_project_path=\"${LOCAL_PROJECT_PATH}\" \
    remote_project_path=\"${REMOTE_PROJECT_PATH}\" git_reference=${GIT_CHECKOUT_COMMIT_BRANCH_TAG} \
    azk_domain=${AZK_DOMAIN} azk_agent_start_command=\"${AZK_AGENT_START_COMMAND}\" \
    azk_restart_command=\"${AZK_RESTART_COMMAND}\" src_dir=\"${REMOTE_PROJECT_PATH}\" git_dir=\"${REMOTE_GIT_PATH}\"
    remote_root_user=\"${REMOTE_ROOT_USER}\" projects_path=\"${PROJECTS_PATH}\" azk_agent_log_file=\"${AZK_AGENT_LOG_FILE}\" \
    host_domain=\"${HOST_DOMAIN}\""
fi

if [ -z ${RUN_DEPLOY} ] || [ "${RUN_DEPLOY}" = "true" ]; then
  # Deploying
  (
    cd ${LOCAL_PROJECT_PATH}
    quiet git remote rm ${GIT_REMOTE} || true
    quiet git remote add ${GIT_REMOTE} ssh://${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PORT}${REMOTE_GIT_PATH} || true
    git push ${GIT_REMOTE} ${GIT_CHECKOUT_COMMIT_BRANCH_TAG}
  )
fi

if [ "$( curl -sI "${REMOTE_HOST}" | head -1 | cut -d " " -f2 )" = "200" ]; then
  analytics_track "deploy-success" "{ \"mid\": \"${AZK_MID}\", \"uid\": \"${AZK_UID}\" }"
else
  analytics_track "deploy-failed" "{ \"mid\": \"${AZK_MID}\", \"uid\": \"${AZK_UID}\" }"
fi

echo
if [ -z "${HOST_DOMAIN}" ]; then
  echo "App successfully deployed at http://${REMOTE_HOST}"
else
  echo "App successfully deployed at http://${HOST_DOMAIN} (${REMOTE_HOST})"
fi

set +e
