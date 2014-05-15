# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require "./#{__FILE__}/../../razor_helper"
confine :to, :platform => 'el-6'
confine :except, :roles => %w{master dashboard database}

test_name "C500	Create 'puppet' Broker with certname and server"
step "https://testrail.ops.puppetlabs.net/index.php?/cases/view/500"

reset_database
json = {
  "name" => "puppet-broker-test",
  "broker-type" => "puppet",
  "configuration" =>{
    "certname" => "EB983218-6FE4-4657-B406-CCAE3BEA594B",
    "server" => "puppet.example.com"
  }
}

razor agents, 'create-broker', json do |agent|
  step "Verify that the broker is defined on #{agent}"
  text = on(agent, "razor -u http://#{agent}:8080/api brokers").output
  assert_match /name:\s*"puppet-broker-test"/, text
end

