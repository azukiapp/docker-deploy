# This image includes:
#
# azukiapp/deploy:
# * Ubuntu 14.04
# * Ansible
# * SSHPass

FROM ansible/ubuntu14.04-ansible
MAINTAINER Azuki <support@azukiapp.com>

RUN mkdir -p /azk/deploy
WORKDIR /azk/deploy
COPY files ./files
COPY playbooks ./playbooks
COPY deploy.sh deploy-setup deploy-run ./

RUN apt-get -y update \
  && apt-get install -y sshpass \
  && ansible-galaxy install -r files/requirements.txt

ENTRYPOINT ["/azk/deploy/deploy.sh"]
