# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require File.expand_path(__FILE__ + '/../../../razor_helper', '.')
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Create tag with rule configuration using "lte" match expression'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/620'

reset_database

razor agents, 'create-tag --name puppet-test-tag --rule \'["lte", 1, 1]\'' do |agent|
  step "Verify that the tag is defined on #{agent}"
  text = on(agent, "razor -u http://#{agent}:8080/api tags").output
  assert_match /puppet-test-tag/, text
end