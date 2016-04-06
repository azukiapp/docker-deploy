# This image includes:
#
# azukiapp/deploy:
# * Alpine Linux
# * Ansible
# * SSHPass

FROM alpine:3.2
MAINTAINER Azuki <support@azukiapp.com>

RUN mkdir -p /azk/deploy
WORKDIR /azk/deploy

RUN packages=' \
    bash \
    g++ \
    openssh \
    sshpass \
    git \
    py-pip \
    python-dev \
  ' \
  set -x \
  && apk --update add $packages \
  && pip install ansible \
  && apk del g++ python-dev py-gdbm py-pip python-doc  \
             python-tests pkgconf pkgconfig \
  && apk add python \
  && rm -rf /var/cache/apk/*

COPY playbooks ./playbooks
COPY cmds ./cmds
COPY utils ./utils
COPY *.sh ./

ENTRYPOINT ["/azk/deploy/deploy.sh"]
CMD ["/azk/deploy/deploy.sh"]
