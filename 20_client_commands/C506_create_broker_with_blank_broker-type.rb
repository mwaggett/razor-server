# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require File.expand_path(__FILE__ + '/../../razor_helper', '.')
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database}

test_name "C506 Create Broker with blank Broker-type"
step "https://testrail.ops.puppetlabs.net/index.php?/cases/view/506"

reset_database
json = {
  "name" => "pe",
  "configuration" =>{
    "server" => "10.18.235.100"
  }
}

razor agents, 'create-broker', json, exit: 1 do |agent, text|
  assert_match /422 Unprocessable Entity/, text
  assert_match /broker-type is a required attribute, but it is not present/, text
end

