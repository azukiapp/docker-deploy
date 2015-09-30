#! /bin/sh

set -- $*

abs_dir() {
  cd "${1%/*}"; link=`readlink ${1##*/}`;
  if [ -z "$link" ]; then pwd; else abs_dir $link; fi
}

check_project_src() {
  [ -z ${LOCAL_PROJECT_PATH} ] && LOCAL_PROJECT_PATH="/azk/deploy/src"

  if [ ! -d ${LOCAL_PROJECT_PATH} ]; then
    echo "Failed to locate source dir ${LOCAL_PROJECT_PATH}"
    exit 1
  fi
}

main() {
    check_project_src
  . ${ROOT_PATH}/cmds/setup-ssh.sh

  if [ "$1" = "--provider" ]; then
    shift; export PROVIDER=$1; shift
    if [ -f ${ROOT_PATH}/deploy-${PROVIDER}.sh ]; then
      . ${ROOT_PATH}/deploy-${PROVIDER}.sh
    else
      echo "Invalid provider ${PROVIDER}."
      exit 1
    fi
  fi

  # This is a workaround because of https://github.com/docker/docker/issues/3753
  [ "$1" = "/bin/sh" ] && shift
  [ "$1" = "-c" ] && shift

  . ${ROOT_PATH}/cmds/setup-ansible.sh

  if [ $# -eq 0 ]; then
    . ${ROOT_PATH}/cmds/run.sh
    return 0
  fi

  case "$1" in
    rollback)
      sh ./cmds/${1}.sh "$2"
      ;;
    *)
      echo "Invalid command ${1}."
  esac
}

ROOT_PATH=`abs_dir ${BASH_SOURCE:-$0}`
cd ${ROOT_PATH}
main "${@}"
