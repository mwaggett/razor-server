# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require File.expand_path(__FILE__ + '/../../../razor_helper', '.')
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Enable policy without name parameter'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/695'

reset_database

razor agents, 'enable-policy', nil, exit: 1 do |agent, output|
  assert_match /No arguments for command/, output
end
