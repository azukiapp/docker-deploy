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
RUN apt-get -y update \
  && apt-get install -y sshpass \
  && ansible-galaxy install -r files/requirements.txt

# TODO: split to another Dockerfile
COPY playbooks ./playbooks
COPY deploy.sh deploy-setup.sh deploy-run.sh ./

ENTRYPOINT ["/azk/deploy/deploy.sh"]
