# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require 'razor/acceptance/utils'
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Command - "tags"'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/447'

reset_database

agents.each do |agent|
  step "Test empty query results on #{agent}"
  text = on(agent, "razor -u https://#{agent}:8151/api tags").output
  assert_match /There are no items for this query./, text
end

razor agents, 'create-tag --name puppet-test-tag --rule \'["=", ["fact", "processorcount"], "2"]\'' do |agent|
  step "Test single query result on #{agent}"
  text = on(agent, "razor -u https://#{agent}:8151/api tags").output
  assert_match /puppet-test-tag/, text
end