# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require File.expand_path(__FILE__ + '/../../../razor_helper', '.')
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name "Modify policy max count increase"
step "https://testrail.ops.puppetlabs.net/index.php?/cases/view/725"

reset_database
result = create_policy agents, policy_max_count: 5
agents.each do |agent|
  text = on(agent, "razor -u http://#{agent}:8080/api policies puppet-test-policy").output
  assert_match /max_count:\s+5/, text
end

razor agents, "modify-policy-max-count --name #{result[:policy][:name]} --max-count 6" do |agent|
  step "Verify that the count was increased on #{agent}"
  text = on(agent, "razor -u http://#{agent}:8080/api policies #{result[:policy][:name]}").output
  assert_match /max_count:\s+6/, text
end
