#! /bin/bash

require() {
  . ${ROOT_PATH}/$1
}

contains() {
  local seeking=$1; shift
  for el; do
    if [ "$el" = "$seeking" ]; then
      return 0
    fi
  done
  return 1
}

check_cache() {
  # check the variables necessary to skip setup provider step.
  SKIP=()

  if [ ! -z ${REMOTE_HOST} ]; then
      SKIP+=('REMOTE_HOST')
  fi

  if [ ! -z ${PROVIDER} ]; then
      SKIP+=('PROVIDER')
  fi
}

set_config() {
  if [ $# -lt 1 ]; then
    echo "Failed to set config"
    return 1
  fi

  echo "$1=\"$2\"" > ${ROOT_PATH}/.config/$1
}

quiet() {
  ( $@ ) > /dev/null 2>&1
}

load_configs() {
  CONFIG_DIR=${ROOT_PATH}/.config

  if [ ! -d $CONFIG_DIR ]; then
    mkdir -p $CONFIG_DIR  
  fi

  for cfg in $( ls ${CONFIG_DIR}/ ); do
    . ${CONFIG_DIR}/${cfg}
  done
}
