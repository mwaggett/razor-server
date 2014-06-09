# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require File.expand_path(__FILE__ + '/../../../razor_helper', '.')
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Move policy after a different policy'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/738'

reset_database
create_policy agents, policy_name: 'after-policy'
create_policy agents, policy_name: 'before-policy', just_policy: true

agents.each do |agent|
  step "Verify that 'after-policy' is originally defined before 'before-policy' on #{agent}"
  text = on(agent, "razor -u http://#{agent}:8080/api policies").output
  assert_match /after-policy.+before-policy/m, text
end

razor agents, 'move-policy --name after-policy --after before-policy' do |agent|
  step "Verify that 'after-policy' is now defined after 'before-policy' on #{agent}"
  text = on(agent, "razor -u http://#{agent}:8080/api policies").output
  assert_match /before-policy.+after-policy/m, text
end
