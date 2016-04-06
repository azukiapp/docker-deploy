#!/bin/bash

ssh -i "${SSH_PUBLIC_KEY_FILE_PATH}" -p ${REMOTE_PORT} -q -o ConnectTimeout=20 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
  ${REMOTE_USER}@${REMOTE_HOST} "${@}"
