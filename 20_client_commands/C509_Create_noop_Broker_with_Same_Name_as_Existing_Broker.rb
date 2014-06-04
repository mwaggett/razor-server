# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require File.expand_path(__FILE__ + '/../../razor_helper', '.')
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database}

test_name "C509	Create 'noop' Broker with Same Name as Existing Broker"
step "https://testrail.ops.puppetlabs.net/index.php?/cases/view/509"

reset_database

json1 = {"name" => "puppet-broker-test", "broker-type" => "puppet"}
json2 = {"name" => "puppet-broker-test", "broker-type" => "noop"}

razor agents, 'create-broker', json1 do |agent|
  step "Verify that the broker is defined on #{agent}"
  text = on(agent, "razor -u http://#{agent}:8080/api brokers").output
  assert_match /name:\s*"puppet-broker-test"/, text
end

razor agents, 'create-broker', json2, exit: 1 do |agent, text|
  assert_match /409 Conflict/, text
  assert_match /error: "The broker puppet-broker-test already exists, and the broker_type fields do not match"/, text
end

