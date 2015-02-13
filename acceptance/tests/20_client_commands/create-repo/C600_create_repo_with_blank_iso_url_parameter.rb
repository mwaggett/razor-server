# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require File.expand_path(__FILE__ + '/../../../razor_helper', '.')
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Create repo with blank iso-url parameter'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/600'

reset_database

razor agents, 'create-repo --name puppet-test-repo --task centos --iso-url ""', nil, exit: 1 do |agent, output|
  assert_match /iso-url must be between 1 and 1000 characters in length, but is 0 characters long/, output
end