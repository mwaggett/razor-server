# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require File.expand_path(__FILE__ + '/../../../razor_helper', '.')
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Delete policy with blank name'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/654'

reset_database

razor agents, 'delete-policy --name ""', nil, exit: 1 do |agent, output|
  assert_match /name must be at least 1 characters in length, but is only 0 characters long/, output
end
