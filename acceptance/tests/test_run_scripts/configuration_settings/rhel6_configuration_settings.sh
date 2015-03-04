#!/bin/bash
SCRIPT_PATH=$(pwd)
BASENAME_CMD="basename ${SCRIPT_PATH}"
SCRIPT_BASE_PATH=`eval ${BASENAME_CMD}`

if [ $SCRIPT_BASE_PATH = "configuration_settings" ]; then
  cd ../../
fi

export pe_dist_dir=http://pe-releases.puppetlabs.lan/3.7.1/

beaker \
  --config test_run_scripts/configs/rhel6-64mda-64a.yaml \
  --debug \
  --pre-suite 10_installation_and_configuration/00_pe_install.rb,10_installation_and_configuration/C03_install_razor_server.rb,10_installation_and_configuration/C06_install_razor_client.rb \
  --tests 20_client_commands/configuration_settings \
  --keyfile ~/.ssh/id_rsa-acceptance \
  --load-path lib \
  --preserve-hosts onfail \
  --timeout 360
  