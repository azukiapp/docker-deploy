#! /bin/bash

set -- $*
set -x

usage() {
  echo "Usage:"
  echo "  $ azk shell deploy [ -- command [args] ]"
  echo ""
  echo "Commands:"
  echo "  - slow:           Configure the remote server and deploy the app (default for the first run);"
  echo "  - fast:           Deploy without configuring the remote server (default for every run after the first one);"
  echo "  - restart:        Restart the app on the remote server;"
  echo "  - versions:       List all app versions deployed on the remote server;"
  echo "  - rollback [ref]: Revert the app to a specified reference (version or git reference -- commit, branch etc.)"
  echo "                    If no reference is specified, rolls back to the previous version;"
  echo "  - ssh:            Create a SSH connection to remote server;"
  echo "  - shell:          Start a shell inside the deploy system;"
  echo "  - help:           Print this message."
}

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

setup_remote() {
  if [ ! -z $RUN_PROVIDER ]; then
    require ${ROOT_PATH}/deploy-${CURRENT_PROVIDER}.sh
  fi
  set_config PROVIDER "$CURRENT_PROVIDER"
  set_config REMOTE_HOST "$REMOTE_HOST"
  require utils/setup-ansible.sh
}

main() {
  load_configs
  check_project_src
  require utils/setup-ssh.sh

  if [ "$1" = "--provider" ]; then
    shift; export CURRENT_PROVIDER=$1; shift
    if [ -f ${ROOT_PATH}/deploy-${CURRENT_PROVIDER}.sh ]; then
      if [ -z $REMOTE_HOST ] || [ -z $PROVIDER ] || [ "${PROVIDER}" != "${CURRENT_PROVIDER}" ]; then
        export RUN_PROVIDER="true"
      fi
    else
      echo "Invalid provider ${CURRENT_PROVIDER}."
      exit 1
    fi
  fi

  # This is a workaround because of https://github.com/docker/docker/issues/3753
  [ "$1" = "/bin/sh" ] && shift
  [ "$1" = "-c" ] && shift

  case "$1" in
    ""|rollback|versions|fast|slow|restart|ssh)
      setup_remote
      CMD=${1:-"run"}; shift; bash ./cmds/${CMD}.sh "${@}"
      ;;
    shell)
      shift; exec bash "${@}"
      ;;
    help|-h|--help)
      usage && exit 0
      ;;
    *)
      echo "Invalid command ${1}."
  esac
}

export ROOT_PATH=`abs_dir ${BASH_SOURCE:-$0}`
cd ${ROOT_PATH}

# Importing set of utils functions
. ${ROOT_PATH}/utils/utils.sh

main "${@}"
