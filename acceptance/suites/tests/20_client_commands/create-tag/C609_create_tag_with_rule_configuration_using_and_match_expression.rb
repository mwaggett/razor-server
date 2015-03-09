# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require File.expand_path(__FILE__ + '/../../../razor_helper', '.')
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Create tag with rule configuration using "and" match expression'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/609'

reset_database

razor agents, 'create-tag --name puppet-test-tag --rule \'["and", true, true]\'' do |agent|
  step "Verify that the tag is defined on #{agent}"
  text = on(agent, "razor -u https://#{agent}:8151/api tags").output
  assert_match /puppet-test-tag/, text
end