#!/bin/bash
ssh -i "${SSH_PUBLIC_KEY_FILE_PATH}" -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $*