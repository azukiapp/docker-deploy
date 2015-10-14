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

  echo "export $1=\"$2\"" > ${CONFIG_DIR}/$1
}

clear_config() {
  if [ $# -lt 1 ]; then
    echo "Failed to clean config"
    return 1
  fi

  rm -f ${CONFIG_DIR}/$1
}

clear_configs() {
  rm -f ${CONFIG_DIR}/*
}


quiet() {
  "$@" > /dev/null 2>&1
}

load_configs() {
  if [ ! -d $CONFIG_DIR ]; then
    mkdir -p $CONFIG_DIR  
  fi

  for cfg in $( ls ${CONFIG_DIR}/ ); do
    # Values in Azkfile.js or .env precedes cache
    if [ -z $( eval echo \${$cfg} ) ]; then
      . ${CONFIG_DIR}/${cfg}
    else
      set_config ${cfg} $(eval echo \${$cfg})
    fi
  done
}

export CONFIG_DIR=${ROOT_PATH}/.config