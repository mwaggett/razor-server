# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require File.expand_path(__FILE__ + '/../../razor_helper', '.')
confine :to, :platform => 'el-6'
confine :except, :roles => %w{master dashboard database}

test_name "C488	Create 'puppet-pe' Broker with Long Unicode Name (250 characters)"
step "https://testrail.ops.puppetlabs.net/index.php?/cases/view/488"

data = "ᓱᓴᓐᐊᒡᓗᒃᑲᖅព្រះឃោសាចាជួន​ណាតعبدالحافظედუარდშევარდნაძეСолижонШарипов".chars.to_a
name = (1..250).map { data[rand(data.length)] }.join

step "using #{name.inspect} as the broker name"

reset_database
json = {"name" => "#{name}", "broker-type" => "puppet-pe"}

razor agents, 'create-broker', json do |agent|
  step "Verify that the broker is defined on #{agent}"
  text = on(agent, "razor -u http://#{agent}:8080/api brokers").output
  assert_match /name:\s*"#{name}"/, text
end

