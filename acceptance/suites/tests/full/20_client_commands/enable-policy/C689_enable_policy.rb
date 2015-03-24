# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require 'razor/acceptance/utils'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Enable policy'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/689'

reset_database

result = create_policy agents
name = result[:policy][:name]

razor agents, 'disable-policy --name ' + name do |agent|
  step "Verify that the policy is disabled on #{agent}"
  text = on(agent, "razor -u https://#{agent}:8151/api policies #{name}").output
  assert_match /enabled:\s+false/, text
end
razor agents, 'enable-policy --name ' + name do |agent|
  step "Verify that the policy is enabled on #{agent}"
  text = on(agent, "razor -u https://#{agent}:8151/api policies #{name}").output
  assert_match /enabled:\s+true/, text
end
