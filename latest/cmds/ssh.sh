#! /bin/bash

ssh -p ${REMOTE_PORT} -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
  ${REMOTE_ROOT_USER}@${REMOTE_HOST} "${@}"
