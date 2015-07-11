#! /bin/bash

[[ -z $ANSIBLE_SSH_ROOT_PASS ]]     && echo "ANSIBLE_SSH_ROOT_PASS is missing." && exit 1
[[ -z $ANSIBLE_SSH_HOST ]]          && echo "ANSIBLE_SSH_HOST is missing." && exit 1
[[ -z $ANSIBLE_SSH_PORT ]]          && echo "ANSIBLE_SSH_PORT is missing." && exit 1
[[ -z $AZK_DOMAIN ]]                && echo "AZK_DOMAIN is missing." && exit 1

if [[ -z ${AZK_SRC_DIR} ]] || [[ ! -d ${AZK_SRC_DIR} ]]; then
  echo "Failed to locate source dir ${AZK_SRC_DIR}"
  exit 1
fi

set -e

quiet() {
  ( $@ ) > /dev/null 2>&1
}

mkdir -p /root/.ssh
if [[ -d ${AZK_SSH_KEY_DIR} ]] && quiet ls ${AZK_SSH_KEY_DIR}/*.pub; then
  cp -R ${AZK_SSH_KEY_DIR}/* /root/.ssh
  cat /root/.ssh/*.pub >> playbooks/roles/configure/files/authorized_keys
else
  ssh-keygen -t rsa -b 4096 -N "" -f /root/.ssh/id_rsa
  cat /root/.ssh/id_rsa.pub >> playbooks/roles/configure/files/authorized_keys
fi

export ANSIBLE_HOST_KEY_CHECKING=False

[[ -z $ANSIBLE_SSH_USER ]] && \
  export ANSIBLE_SSH_USER='git'
[[ -z $ANSIBLE_SSH_PASS ]] && \
  export ANSIBLE_SSH_PASS=$( date +%s | sha256sum | base64 | head -c 32 | sha256sum | awk '{print $1}' )
[[ -z $ANSIBLE_SSH_ROOT_USER ]] && \
  export ANSIBLE_SSH_ROOT_USER='root'

[[ -z $SRC_DIR ]] && \
  export SRC_DIR=$( date +%s | sha256sum | head -c 7 )
[[ -z $REMOTE_SRC_DIR ]] && \
  export REMOTE_SRC_DIR="/home/${ANSIBLE_SSH_USER}/${SRC_DIR}"
[[ -z $REMOTE_GIT_DIR ]] && \
  export REMOTE_GIT_DIR="/home/${ANSIBLE_SSH_USER}/${SRC_DIR}.git"

(
  echo -n "default ansible_ssh_host=${ANSIBLE_SSH_HOST} "
  echo -n "ansible_ssh_port=${ANSIBLE_SSH_PORT} "
  echo -n "ansible_ssh_user=${ANSIBLE_SSH_ROOT_USER} "
  echo -n "ansible_ssh_pass=${ANSIBLE_SSH_ROOT_PASS}"
) > /etc/ansible/hosts

if [[ -z ${RUN_SETUP} ]] || [[ ${RUN_SETUP} == true ]]; then
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

if [[ -z ${RUN_DEPLOY} ]] || [[ ${RUN_DEPLOY} == true ]]; then
  # Deploying
  cd ${AZK_SRC_DIR}
  git remote add azk_deploy ssh://${ANSIBLE_SSH_USER}@${ANSIBLE_SSH_HOST}:${ANSIBLE_SSH_PORT}${REMOTE_GIT_DIR} || true
  git push azk_deploy master
fi
