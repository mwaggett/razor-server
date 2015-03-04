#!/bin/bash
SCRIPT_PATH=$(pwd)
BASENAME_CMD="basename ${SCRIPT_PATH}"
SCRIPT_BASE_PATH=`eval ${BASENAME_CMD}`

if [ $SCRIPT_BASE_PATH = "create-hook" ]; then
  cd ../../
fi

export pe_dist_dir=http://neptune.puppetlabs.lan/4.0/ci-ready/

beaker \
  --config test_run_scripts/configs/rhel6-64mda-64a.yaml \
  --debug \
  --pre-suite 10_installation_and_configuration/00_pe_install.rb,10_installation_and_configuration/C03_install_razor_server.rb,10_installation_and_configuration/C06_install_razor_client.rb \
  --tests 20_client_commands/create-hook \
  --keyfile ~/.ssh/id_rsa-acceptance \
  --load-path lib \
  --preserve-hosts onfail \
  --timeout 360
  
