# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require File.expand_path(__FILE__ + '/../../../razor_helper', '.')
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Add policy tag with unicode name'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/455'

reset_database

tag_name = 'puppet-test-tag'

json = {
    'name' => tag_name,
    'rule' => ["=", ["fact", "processorcount"], "2"]
}
razor agents, 'create-tag', json do |agent|
  step "Verify that the tag is defined on #{agent}"
  text = on(agent, "razor -u http://#{agent}:8080/api tags").output
  assert_match /#{tag_name}/, text
end

results = create_policy agents, policy_name: long_unicode_string
policy_name = results[:policy][:name]

agents.each do |agent|
  step "Verify that the tag is not associated with policy on #{agent}"
  text = on(agent, "razor -u http://#{agent}:8080/api policies #{policy_name}").output
  refute_match /#{tag_name}/, text
  end

json = {
    'name' => policy_name,
    'tag' => tag_name
}
razor agents, 'add-policy-tag', json do |agent|
  step "Verify that the tag is associated with policy on #{agent}"
  text = on(agent, "razor -u http://#{agent}:8080/api policies '#{policy_name}'").output
  assert_match /#{tag_name}/, text
end
