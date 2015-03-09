# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require File.expand_path(__FILE__ + '/../../../razor_helper', '.')
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Reinstall node that does not exist'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/764'

reset_database

razor agents, 'reinstall-node --name does-not-exist', nil, exit: 1 do |agent, output|
  assert_match /name must be the name of an existing node, but is 'does-not-exist'/, output
end
