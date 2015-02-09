# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require File.expand_path(__FILE__ + '/../../../razor_helper', '.')
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Add policy tag with rule configuration parameter using "neq"'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/465'

reset_database

tag_name = 'puppet-test-tag'

results = create_policy agents
policy_name = results[:policy][:name]

razor agents, "add-policy-tag --name #{policy_name} --tag #{tag_name} --rule " + '\'["neq", false, true]\'' do |agent|
  step "Verify that the tag is associated with policy on #{agent}"
  text = on(agent, "razor -u http://#{agent}:8080/api policies #{policy_name}").output
  assert_match /#{tag_name}/, text
end
