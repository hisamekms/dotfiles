export NODEJS_GLOBAL_PACKAGES=~/.nodejs/global-packages

function npm-global-install () {
  echo ${NODEJS_GLOBAL_PACKAGES}
  if [ -e ${NODEJS_GLOBAL_PACKAGES} ]; then
    cat ${NODEJS_GLOBAL_PACKAGES} | while read line
    do
      sudo npm install -g ${line}
    done
  fi
}