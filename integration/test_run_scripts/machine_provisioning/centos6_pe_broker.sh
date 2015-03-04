#!/bin/bash
SCRIPT_PATH=$(pwd)
BASENAME_CMD="basename ${SCRIPT_PATH}"
SCRIPT_BASE_PATH=`eval ${BASENAME_CMD}`

if [ $SCRIPT_BASE_PATH = "machine_provisioning" ]; then
  cd ../../
fi

export pe_dist_dir=http://pe-releases.puppetlabs.lan/3.7.1/

beaker \
  --config configs/centos6-razor-vcloud.cfg \
  --debug \
  --pre-suite pre-suite \
  --tests tests/machine_provisioning/centos6_pe_broker \
  --keyfile ~/.ssh/id_rsa-acceptance \
  --load-path lib \
  --preserve-hosts onfail \
  --timeout 360
