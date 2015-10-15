#! /bin/bash

require() {
  if ( echo "$1" | grep "^/" ) > /dev/null 2>&1; then
    . $1
  else
    . ${ROOT_PATH}/$1
  fi
}

set_config() {
  if [ $# -lt 1 ]; then
    echo "Failed to set config"
    return 1
  fi

  echo "export $1=\"$2\"" > ${ENV_DIR}/$1
}

clear_config() {
  if [ $# -lt 1 ]; then
    echo "Failed to clean config"
    return 1
  fi

  rm -f ${ENV_DIR}/$1
}

clear_configs() {
  rm -f ${ENV_DIR}/*
}


quiet() {
  "$@" > /dev/null 2>&1
}

load_configs() {
  if [ ! -d ${ENV_DIR} ]; then
    mkdir -p ${ENV_DIR}
  fi

  for cfg in $( ls ${ENV_DIR}/ ); do
    # Values in Azkfile.js or .env precedes cache
    if [ -z $( eval echo \${$cfg} ) ]; then
      . ${ENV_DIR}/${cfg}
    else
      set_config ${cfg} $(eval echo \${$cfg})
    fi
  done
}

export CONFIG_DIR="${ROOT_PATH}/.config"
export ENV_DIR="${CONFIG_DIR}/env"