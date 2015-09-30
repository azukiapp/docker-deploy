set -e

RETRY=0; MAX_RETRY=10
until [ ${RETRY} -ge ${MAX_RETRY} ]; do
  quiet nc -w 10 ${REMOTE_HOST} 22 && break
  RETRY=`expr ${RETRY} + 1`
  echo "Server is not accepting SSH connections yet. Retrying... (${RETRY}/${MAX_RETRY})"
  sleep 5
done

[ ${RETRY} -ge ${MAX_RETRY} ] && echo "Failed to connect to server. Try again later." && exit 1

echo > playbooks/roles/configure/files/authorized_keys
cat ${LOCAL_ROOT_DOT_SSH_PATH}/*.pub >> playbooks/roles/configure/files/authorized_keys

[ -z ${REMOTE_HOST} ] && echo "REMOTE_HOST is missing." && exit 1

export ANSIBLE_HOST_KEY_CHECKING=False

. /azk/deploy/envs.sh

(
  echo -n "default ansible_ssh_host=${REMOTE_HOST} "
  echo -n "ansible_ssh_port=${REMOTE_PORT} "
  echo -n "ansible_ssh_user=${REMOTE_ROOT_USER} "
  ( [ ! -z ${REMOTE_ROOT_PASS} ] && echo -n "ansible_ssh_pass=${REMOTE_ROOT_PASS}" ) || true
  echo ""
) > /etc/ansible/hosts

if ( cd ${LOCAL_PROJECT_PATH}; git remote | grep -q "^${GIT_REMOTE}$" ); then
  export REMOTE_PROJECT_PATH=$( cd ${LOCAL_PROJECT_PATH}; git remote -v | grep -P "^${GIT_REMOTE}\t" | head -1 | awk '{ print $2 }' | sed 's/.*\:\/\/.*@[^:]*\(:[0-9]\+\)\?//' | sed 's/\.git//' )
else
  [ -z ${REMOTE_PROJECT_PATH_ID} ] && \
    export REMOTE_PROJECT_PATH_ID=$( date +%s | sha256sum | head -c 7 )
  [ -z $REMOTE_PROJECT_PATH ] && \
    export REMOTE_PROJECT_PATH="/home/${REMOTE_USER}/${REMOTE_PROJECT_PATH_ID}"
fi
export REMOTE_GIT_PATH="${REMOTE_PROJECT_PATH}.git"

set +e
