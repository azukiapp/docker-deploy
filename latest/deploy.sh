#! /bin/sh

set -x

[ -z $ANSIBLE_SSH_HOST ]          && echo "ANSIBLE_SSH_HOST is missing." && exit 1
[ -z $ANSIBLE_SSH_ROOT_PASS ]     && echo "ANSIBLE_SSH_ROOT_PASS is missing." && exit 1

if [ -z ${PROJECT_SRC_PATH} ] || [ ! -d ${PROJECT_SRC_PATH} ]; then
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

mkdir -p /root/.ssh
if [ -d ${LOCAL_SSH_KEYS_PATH} ] && quiet ls ${LOCAL_SSH_KEYS_PATH}/*.pub; then
  cp -R ${LOCAL_SSH_KEYS_PATH}/* /root/.ssh
  cat /root/.ssh/*.pub >> playbooks/roles/configure/files/authorized_keys
else
  ssh-keygen -t rsa -b 4096 -N "" -f /root/.ssh/id_rsa
  cat /root/.ssh/id_rsa.pub >> playbooks/roles/configure/files/authorized_keys
fi

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

if git remote | grep "^${GIT_REMOTE}$"; then
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
  echo -n "ansible_ssh_pass=${ANSIBLE_SSH_ROOT_PASS}"
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
