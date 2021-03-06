# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require 'razor/acceptance/utils'
confine :except, :roles => %w{master dashboard database frictionless}

test_name "C504	Create 'noop' Broker"
step "https://testrail.ops.puppetlabs.net/index.php?/cases/view/504"

reset_database

json1 = {"name" => "puppet-broker-test", "broker-type" => "noop"}

razor agents, 'create-broker', json1 do |agent|
  step "Verify that the broker is defined on #{agent}"
  text = on(agent, "razor brokers").output
  assert_match /puppet-broker-test/, text
end
