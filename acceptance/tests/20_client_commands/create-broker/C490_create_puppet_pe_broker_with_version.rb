# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require File.expand_path(__FILE__ + '/../../../razor_helper', '.')
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name "C490	Create 'puppet-pe' Broker with version"
step "https://testrail.ops.puppetlabs.net/index.php?/cases/view/490"

reset_database
json = {
  "name" => "pe-broker-test",
  "broker-type" => "puppet-pe",
  "configuration" =>{
    "version" => "1.2.3"
  }
}

razor agents, 'create-broker', json do |agent|
  step "Verify that the broker is defined on #{agent}"
  text = on(agent, "razor -u http://#{agent}:8080/api brokers").output
  assert_match /pe-broker-test/, text
end
