# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require File.expand_path(__FILE__ + '/../../../razor_helper', '.')
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Remove policy tag'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/775'

reset_database
results = create_policy agents, create_tag: true, tag_name: 'puppet-test-tag'
policy_name = results[:policy][:name]
tag_name = results[:tag_name]

agents.each do |agent|
  step "Verify that the policy is defined on #{agent}"
  text = on(agent, "razor -u https://#{agent}:8151/api policies").output
  assert_match /#{tag_name}/, text
end

razor agents, 'remove-policy-tag --name ' + policy_name + ' --tag ' + tag_name do |agent|
  step "Verify that tag #{tag_name} is no longer defined on policy #{policy_name} on #{agent}"
  text = on(agent, "razor -u https://#{agent}:8151/api policies").output
  refute_match /#{tag_name}/, text
end
