# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require 'razor/acceptance/utils'
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Command - "policies"'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/445'

reset_database

agents.each do |agent|
  step "Test empty query results on #{agent}"
  text = on(agent, "razor -u https://#{agent}:8151/api policies").output
  assert_match /There are no items for this query./, text
end

name = 'centos-for-small'
create_policy agents, policy_name: name do |agent|
  step "Test single query result on #{agent}"
  text = on(agent, "razor -u https://#{agent}:8151/api policies").output
  assert_match /centos-for-small/, text
end
