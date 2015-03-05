# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require File.expand_path(__FILE__ + '/../../../razor_helper', '.')
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Delete tag with long name'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/660'

reset_database

razor agents, 'create-tag --name ' + ('a' * 250) + ' --rule \'["=", ["fact", "processorcount"], "2"]\'' do |agent|
  step "Verify that the tag is defined on #{agent}"
  text = on(agent, "razor -u https://#{agent}:8151/api tags").output
  assert_match /#{'a' * 250}/, text
end

razor agents, 'delete-tag --name ' + ('a' * 250) do |agent|
  step "Verify that the tag is no longer defined on #{agent}"
  text = on(agent, "razor -u https://#{agent}:8151/api tags").output
  refute_match /#{'a' * 250}/, text
end
