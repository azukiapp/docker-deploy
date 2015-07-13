#! /bin/sh

set -x

[ -z $ANSIBLE_SSH_HOST ] && echo "ANSIBLE_SSH_HOST is missing." && exit 1

[ -z ${PROJECT_SRC_PATH} ] && PROJECT_SRC_PATH="/azk/deploy/src"

if [ ! -d ${PROJECT_SRC_PATH} ]; then
  echo "Failed to locate source dir ${PROJECT_SRC_PATH}"
  exit 1
fi

quiet() {
  ( $@ ) > /dev/null 2>&1
}

abs_dir() {
  cd "${1%/*}"; link=`readlink ${1##*/}`;
  if [ -z "$link" ]; then pwd; else abs_dir $link; fi
}
ROOT_PATH=`abs_dir ${BASH_SOURCE:-$0}`
cd ${ROOT_PATH}

set -e

ROOT_SSH_PATH="/root/.ssh"
[ -z ${LOCAL_SSH_KEYS_PATH} ] && LOCAL_SSH_KEYS_PATH="/azk/deploy/.ssh"
mkdir -p ${ROOT_SSH_PATH}
echo > playbooks/roles/configure/files/authorized_keys
if [ -d ${LOCAL_SSH_KEYS_PATH} ] && quiet ls ${LOCAL_SSH_KEYS_PATH}/*.pub; then
  if [ "${LOCAL_SSH_KEYS_PATH%/}" != "${ROOT_SSH_PATH}" ]; then
    cp -R ${LOCAL_SSH_KEYS_PATH}/* ${ROOT_SSH_PATH}
  fi
else
  if ! quiet ls ${ROOT_SSH_PATH}/id_rsa.pub; then
    ssh-keygen -t rsa -b 4096 -N "" -f ${ROOT_SSH_PATH}/id_rsa
  fi
fi
cat ${ROOT_SSH_PATH}/*.pub >> playbooks/roles/configure/files/authorized_keys

export ANSIBLE_HOST_KEY_CHECKING=False

[ -z $ANSIBLE_SSH_USER ] && \
  ANSIBLE_SSH_USER='git'
[ -z $ANSIBLE_SSH_PASS ] && \
  ANSIBLE_SSH_PASS=$( date +%s | sha256sum | base64 | head -c 32 | sha256sum | awk '{print $1}' )
[ -z $ANSIBLE_SSH_ROOT_USER ] && \
  ANSIBLE_SSH_ROOT_USER='root'
[ -z $ANSIBLE_SSH_PORT ] && \
  ANSIBLE_SSH_PORT='22'
[ -z $AZK_DOMAIN ] && \
  AZK_DOMAIN='dev.azk.io'

[ -z $GIT_REMOTE ] && \
  GIT_REMOTE='azk_deploy'

if ( cd ${PROJECT_SRC_PATH}; git remote | grep -q "^${GIT_REMOTE}$" ); then
  REMOTE_SRC_DIR=$( cd ${PROJECT_SRC_PATH}; git remote -v | grep -P "^${GIT_REMOTE}\t" | head -1 | awk '{ print $2 }' | sed 's/.*\:\/\/.*@[^:]*\(:[0-9]\+\)\?//' | sed 's/\.git//' )
else
  [ -z $REMOTE_SRC_DIR_ID ] && \
    REMOTE_SRC_DIR_ID=$( date +%s | sha256sum | head -c 7 )
  [ -z $REMOTE_SRC_DIR ] && \
    REMOTE_SRC_DIR="/home/${ANSIBLE_SSH_USER}/${REMOTE_SRC_DIR_ID}"
fi
REMOTE_GIT_DIR="${REMOTE_SRC_DIR}.git"

(
  echo -n "default ansible_ssh_host=${ANSIBLE_SSH_HOST} "
  echo -n "ansible_ssh_port=${ANSIBLE_SSH_PORT} "
  echo -n "ansible_ssh_user=${ANSIBLE_SSH_ROOT_USER} "
  ( [ ! -z ${ANSIBLE_SSH_ROOT_PASS} ] && echo -n "ansible_ssh_pass=${ANSIBLE_SSH_ROOT_PASS}" ) || true
) > /etc/ansible/hosts

if [ -z ${RUN_SETUP} ] || [ "${RUN_SETUP}" = "true" ]; then
  # Provisioning
  ansible-playbook playbooks/setup.yml --extra-vars "user=${ANSIBLE_SSH_USER} src_dir=${REMOTE_SRC_DIR} git_dir=${REMOTE_GIT_DIR} azk_domain=${AZK_DOMAIN}"
  ansible-playbook playbooks/reset.yml || true
fi

(
  echo -n "default ansible_ssh_host=${ANSIBLE_SSH_HOST} "
  echo -n "ansible_ssh_port=${ANSIBLE_SSH_PORT} "
  echo -n "ansible_ssh_user=${ANSIBLE_SSH_USER} "
  echo -n "ansible_ssh_pass=${ANSIBLE_SSH_PASS}"
) > /etc/ansible/hosts

if [ -z ${RUN_DEPLOY} ] || [ "${RUN_DEPLOY}" = "true" ]; then
  # Deploying
  cd ${PROJECT_SRC_PATH}
  quiet git remote add ${GIT_REMOTE} ssh://${ANSIBLE_SSH_USER}@${ANSIBLE_SSH_HOST}:${ANSIBLE_SSH_PORT}${REMOTE_GIT_DIR} || true
  git push ${GIT_REMOTE} master
fi
