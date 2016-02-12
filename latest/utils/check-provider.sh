if [ "$1" = "--provider" ]; then
  shift; export CURRENT_PROVIDER=$1; shift
  if [ -f ${ROOT_PATH}/deploy-${CURRENT_PROVIDER}.sh ]; then
    if [ -z $REMOTE_HOST ] || [ -z $PROVIDER ] || [ "${PROVIDER}" != "${CURRENT_PROVIDER}" ]; then
      export RUN_PROVIDER="true"
    fi
  else
    echo "Invalid provider ${CURRENT_PROVIDER}."
    echo "Check if you have the file ${ROOT_PATH}/deploy-${CURRENT_PROVIDER}.sh available in this image, by running:"
    echo "  $ azk deploy shell -c 'ls ${ROOT_PATH}/deploy-${CURRENT_PROVIDER}.sh'"
    exit 1
  fi
fi
