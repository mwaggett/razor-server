# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require File.expand_path(__FILE__ + '/../../../razor_helper', '.')
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Enable policy with long unicode name'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/691'

reset_database

result = create_policy agents, policy_name: long_unicode_string
name = result[:policy][:name]

json = {
    'name' => name
}
razor agents, 'disable-policy', json do |agent|
  step "Verify that the policy is disabled on #{agent}"
  text = on(agent, "razor -u http://#{agent}:8080/api policies '#{name}'").output
  assert_match /enabled:\s+false/, text
end

razor agents, 'enable-policy', json do |agent|
  step "Verify that the policy is enabled on #{agent}"
  text = on(agent, "razor -u http://#{agent}:8080/api policies '#{name}'").output
  assert_match /enabled:\s+true/, text
end
