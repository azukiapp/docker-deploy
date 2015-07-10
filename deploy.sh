#! /bin/bash

[[ -z $ANSIBLE_SSH_USER ]] && echo "ANSIBLE_SSH_USER is missing." && exit 1
[[ -z $ANSIBLE_SSH_PASSWORD ]] && echo "ANSIBLE_SSH_PASSWORD is missing." && exit 1
[[ -z $ANSIBLE_SSH_HOST ]] && echo "ANSIBLE_SSH_HOST is missing." && exit 1
[[ -z $ANSIBLE_SSH_PORT ]] && echo "ANSIBLE_SSH_PORT is missing." && exit 1
[[ -z $AZK_DOMAIN ]] && echo "AZK_DOMAIN is missing." && exit 1

if [[ -z ${AZK_DEPLOY_DIR} ]] || [[ ! -d ${AZK_DEPLOY_DIR} ]]; then
  echo "Failed to locate source dir ${AZK_DEPLOY_DIR}"
  exit 1
fi

set -e

mkdir -p /root/.ssh
ssh-keygen -t rsa -b 4096 -N "" -f /root/.ssh/id_rsa
cat /root/.ssh/id_rsa.pub >> playbooks/roles/configure/files/authorized_keys

export ANSIBLE_HOST_KEY_CHECKING=False
echo "default ansible_ssh_host=${ANSIBLE_SSH_HOST} ansible_ssh_port=${ANSIBLE_SSH_PORT} ansible_ssh_user=${ANSIBLE_SSH_USER} ansible_ssh_pass=${ANSIBLE_SSH_PASSWORD} ansible_sudo_pass=${ANSIBLE_SSH_PASSWORD}" > /etc/ansible/hosts

if [[ -z ${AZK_RUN_SETUP} ]] || [[ ${AZK_RUN_SETUP} == true ]]; then
  # Provisioning
  ansible-playbook playbooks/setup.yml --extra-vars "user=${ANSIBLE_SSH_USER} src_dir=${REMOTE_SRC_DIR} git_dir=${REMOTE_GIT_DIR} azk_domain=${AZK_DOMAIN}"
  ansible-playbook playbooks/reset.yml || true
fi

if [[ -z ${AZK_RUN_DEPLOY} ]] || [[ ${AZK_RUN_DEPLOY} == true ]]; then
  # Deploying
  cd ${AZK_DEPLOY_DIR} > /dev/null 2> /dev/null
  git remote add azk_deploy ssh://${ANSIBLE_SSH_USER}@${ANSIBLE_SSH_HOST}:${ANSIBLE_SSH_PORT}${REMOTE_GIT_DIR} || true
  git push azk_deploy master
  git remote rm azk_deploy
  cd - > /dev/null 2> /dev/null
fi

if [[ -z ${AZK_RUN_START} ]] || [[ ${AZK_RUN_START} == true ]]; then
  ansible-playbook playbooks/run.yml --extra-vars "src_dir=${REMOTE_SRC_DIR}"
fi