# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require File.expand_path(__FILE__ + '/../../../razor_helper', '.')
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name "C536 Create Policy with Long Unicode name"
step "https://testrail.ops.puppetlabs.net/index.php?/cases/view/536"

name = long_unicode_string

step "using #{name.inspect} as the policy name"

reset_database

create_policy agents, policy_name: name do |agent|
  step "Verify that the broker is defined on #{agent}"
  text = on(agent, "razor -u http://#{agent}:8080/api policies").output
  assert_match /#{Regexp.escape(name)}/, text
end
