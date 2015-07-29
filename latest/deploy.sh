#! /bin/sh

abs_dir() {
  cd "${1%/*}"; link=`readlink ${1##*/}`;
  if [ -z "$link" ]; then pwd; else abs_dir $link; fi
}
ROOT_PATH=`abs_dir ${BASH_SOURCE:-$0}`
cd ${ROOT_PATH}

. ${ROOT_PATH}/deploy-setup.sh
. ${ROOT_PATH}/deploy-run.sh
