# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require File.expand_path(__FILE__ + '/../../../razor_helper', '.')

confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Delete broker'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/630'

reset_database

razor agents, 'create-broker --name puppet-test-broker --broker-type noop' do |agent|
  step "Verify that the broker is defined on #{agent}"
  text = on(agent, "razor -u http://#{agent}:8080/api brokers").output
  assert_match /puppet-test-broker/, text
end

razor agents, 'delete-broker --name puppet-test-broker' do |agent|
  step "Verify that the broker is no longer defined on #{agent}"
  text = on(agent, "razor -u http://#{agent}:8080/api brokers").output
  refute_match /puppet-test-broker/, text
end