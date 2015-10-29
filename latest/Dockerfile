# This image includes:
#
# azukiapp/deploy:
# * Ubuntu 14.04
# * Ansible
# * SSHPass

FROM ansible/ubuntu14.04-ansible:stable
MAINTAINER Azuki <support@azukiapp.com>

RUN mkdir -p /azk/deploy
WORKDIR /azk/deploy

COPY files ./files
RUN apt-get -y update \
  && apt-get install -y sshpass curl python-pip git\
  && ansible-galaxy install -r files/requirements.txt \
  && apt-get clean -qq \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# TODO: split to another Dockerfile
COPY playbooks ./playbooks
COPY cmds ./cmds
COPY utils ./utils
COPY *.sh ./

ENTRYPOINT ["/azk/deploy/deploy.sh"]
CMD ["/azk/deploy/deploy.sh"]
