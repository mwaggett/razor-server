# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require File.expand_path(__FILE__ + '/../../../razor_helper', '.')
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Update tag rule used by policy without force parameter'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/819'

reset_database

tag_name = 'puppet-test-tag'

razor agents, 'create-tag --name ' + tag_name + ' --rule \'["=", ["fact", "processorcount"], "20520"]\'' do |agent|
  step "Verify that the tag is defined on #{agent}"
  text = on(agent, "razor -u http://#{agent}:8080/api tags #{tag_name}").output
  assert_match /20520/, text
end

create_policy agents, tag_name: 'puppet-test-tag'

razor agents, 'update-tag-rule --name ' + tag_name + ' --rule \'["=", ["fact", "processorcount"], "454545"]\'', nil, exit: 1 do |agent, output|
  assert_match /Tag '#{tag_name}' is used by policies and 'force' is false/, output
end