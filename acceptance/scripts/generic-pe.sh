#!/bin/bash
script_dir=${0%/*}
acceptance_dir=$script_dir/../

cd $acceptance_dir

export pe_dist_dir=http://pe-releases.puppetlabs.lan/3.7.1/

export BEAKER_TESTSUITE="${2:-suites/tests/}"
export BEAKER_PRESUITE="suites/pre_suite/pe"
export BEAKER_CONFIG="$script_dir/hosts.cfg"
export BEAKER_KEYFILE="~/.ssh/id_rsa-acceptance"

export GENCONFIG_LAYOUT="${1:-redhat6-64mdca-64a}"

export GEM_SOURCE=http://rubygems.delivery.puppetlabs.net
bundle install --path vendor/bundle

bundle exec genconfig2 $GENCONFIG_LAYOUT > $BEAKER_CONFIG

bundle exec beaker \
  --config $BEAKER_CONFIG \
  --pre-suite $BEAKER_PRESUITE \
  --tests $BEAKER_TESTSUITE \
  --keyfile $BEAKER_KEYFILE \
  --helper lib/helper.rb \
  --load-path lib \
  --preserve-hosts onfail \
  --debug \
  --timeout 360
