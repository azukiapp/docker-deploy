#! /bin/bash

set -- $*

abs_dir() {
  cd "${1%/*}"; link=`readlink ${1##*/}`;
  if [ -z "$link" ]; then pwd; else abs_dir $link; fi
}

check_project_src() {
  [ -z ${LOCAL_PROJECT_PATH} ] && export LOCAL_PROJECT_PATH="/azk/deploy/src"

  if [ ! -d ${LOCAL_PROJECT_PATH} ]; then
    echo "Failed to locate source dir ${LOCAL_PROJECT_PATH}"
    exit 1
  fi
}

main() {
  load_configs
  check_project_src
  require cmds/setup-ssh.sh
  check_cache

  if [ "$1" = "--provider" ]; then
    shift; export CURRENT_PROVIDER=$1; shift
    if [ -f ${ROOT_PATH}/deploy-${CURRENT_PROVIDER}.sh ]; then
      if ! contains "REMOTE_HOST" "${SKIP[@]}" || ! contains "PROVIDER" "${SKIP[@]}" || [ "${PROVIDER}" != "${CURRENT_PROVIDER}" ]; then
        . ${ROOT_PATH}/deploy-${CURRENT_PROVIDER}.sh
      fi
    else
      echo "Invalid provider ${CURRENT_PROVIDER}."
      exit 1
    fi
  fi

  set_config PROVIDER "$CURRENT_PROVIDER" 
  set_config REMOTE_HOST "$REMOTE_HOST"

  # This is a workaround because of https://github.com/docker/docker/issues/3753
  [ "$1" = "/bin/sh" ] && shift
  [ "$1" = "-c" ] && shift

  require cmds/setup-ansible.sh

  case "$1" in
    "")
      require cmds/run.sh
      ;;
    rollback|versions|fast|slow|restart)
      CMD=$1; shift; bash ./cmds/${CMD}.sh "${@}"
      ;;
    *)
      echo "Invalid command ${1}."
  esac
}

ROOT_PATH=`abs_dir ${BASH_SOURCE:-$0}`
cd ${ROOT_PATH}

# Importing set of utils functions
. ${ROOT_PATH}/utils.sh

main "${@}"
