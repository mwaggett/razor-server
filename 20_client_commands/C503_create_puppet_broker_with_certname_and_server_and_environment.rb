# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require File.expand_path(__FILE__ + '/../../razor_helper', '.')
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name "C503	Create 'puppet' Broker with certname and server and environment"
step "https://testrail.ops.puppetlabs.net/index.php?/cases/view/503"

reset_database
json = {
  "name" => "puppet-broker-test",
  "broker-type" => "puppet",
  "configuration" =>{
    "certname" => "EB983218-6FE4-4657-B406-CCAE3BEA594B",
    "server" => "puppet.example.com",
    "environment" => "testing"
  }
}

razor agents, 'create-broker', json do |agent|
  step "Verify that the broker is defined on #{agent}"
  text = on(agent, "razor -u http://#{agent}:8080/api brokers").output
  assert_match /puppet-broker-test/, text
end

