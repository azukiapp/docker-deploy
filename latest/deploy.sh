#!/bin/bash

usage() {
  echo "Usage:"
  echo "  $ deploy.sh [command [args]]"
  echo ""
  echo "Commands:"
  echo "  full              Configures the remote server and deploy the app (default for the first deployment)"
  echo "  fast              Deploys without configuring the remote server (default for every run after the first deployment)"
  echo "  restart           Restarts the app on the remote server"
  echo "  versions          Lists all versions of the app deployed on the remote server"
  echo "  rollback [ref]    Reverts the app to a specified reference (version or git reference -- commit, branch etc.)"
  echo "                    If no reference is specified, rolls back to the previous version"
  echo "  ssh               Connects to the remote server via SSH protocol"
  echo "  shell             Start a shell from inside the deploy system container"
  echo "  clear-cache       Clears deploy cached configuration"
  echo "  help              Print this message"
}

abs_dir() {
  cd "${1%/*}"; link=`readlink ${1##*/}`;
  if [ -z "$link" ]; then pwd; else abs_dir $link; fi
}

check_project_src() {
  [ -z ${LOCAL_PROJECT_PATH} ] && export LOCAL_PROJECT_PATH="/azk/deploy/src"

  if [ ! -d ${LOCAL_PROJECT_PATH} ]; then
    echo 'Failed to locate project source at ${LOCAL_PROJECT_PATH}'
    echo
    echo 'Check the `mounts` session of the deploy system in your Azkfile.js.'
    echo 'For further info, please read the docs: http://docs.azk.io/en/deploy/'
    exit 1
  fi
}

setup_remote() {
  if [ ! -z $RUN_PROVIDER ]; then
    require ${ROOT_PATH}/deploy-${CURRENT_PROVIDER}.sh

    # If we interact with provider, be sure the result machine is ready to receive the app
    export CHECK_SSH='true'
    export RUN_SETUP='true'
    export RUN_CONFIGURE='true'
    export RUN_DEPLOY='true'
  fi
  set_config PROVIDER "$CURRENT_PROVIDER"
  set_config REMOTE_HOST "$REMOTE_HOST"
  require utils/setup-ansible.sh
}

pre_command() {
  CMD=$1
  set_config CHECK_SSH 'true'
  setup_remote
}

post_command() {
  CMD=$1
  clear_config CHECK_SSH
}

main() {
  check_project_src

  require utils/setup-ssh.sh
  . utils/check-provider.sh

  case "$1" in
    ""|rollback|versions|fast|full|restart|ssh)
      CMD=${1:-"run"}; shift
      pre_command "$CMD" && \
      bash ./cmds/${CMD}.sh "${@}" && \
      post_command "$CMD"
      ;;
    clear-cache)
      CMD=${1}; shift
      bash ./cmds/${CMD}.sh "${@}"
      ;;
    shell)
      shift; exec bash "${@}"
      ;;
    help|-h|--help)
      usage && exit 0
      ;;
    *)
      echo "Invalid command ${1}. To see the available commands, please run:"
      echo "  $ azk deploy --help"
  esac
}

check_call() {
  . utils/check-provider.sh

  if echo "$1" | grep -qE '^/bin/.*sh$'; then
    CMD=$1; shift
    [ "$1" = "-c" ] && shift

    CMD_ARGS=
    echo "$1" | grep -qv "^${MY_PATH}" && CMD_ARGS="${CMD_ARGS} ${MY_PATH} "
    [ ! -z "${CURRENT_PROVIDER}" ] && CMD_ARGS="${CMD_ARGS} --provider ${CURRENT_PROVIDER} "
    exec ${CMD} -c "${CMD_ARGS}$*"
  fi
}

export MY_PATH="${BASH_SOURCE:-$0}"
export ROOT_PATH=`abs_dir ${MY_PATH}`
cd ${ROOT_PATH}

# Importing set of utils functions
. ${ROOT_PATH}/utils/utils.sh
load_configs

check_call "${@}"
main "${@}"
