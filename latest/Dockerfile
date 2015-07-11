FROM ansible/ubuntu14.04-ansible

RUN mkdir -p /azk/deploy
WORKDIR /azk/deploy
COPY files ./files
COPY playbooks ./playbooks
COPY deploy.sh ./deploy.sh

RUN apt-get -y update \
  && apt-get install -y sshpass \
  && ansible-galaxy install -r files/requirements.txt

ENTRYPOINT ["/azk/deploy/deploy.sh"]
