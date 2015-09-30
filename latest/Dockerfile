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
  && apt-get install -y sshpass curl \
  && ansible-galaxy install -r files/requirements.txt \
  && apt-get clean -qq \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# TODO: split to another Dockerfile
COPY playbooks ./playbooks
COPY cmds ./cmds
COPY deploy.sh envs.sh ./

ENTRYPOINT ["/azk/deploy/deploy.sh"]
CMD [""]
