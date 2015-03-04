# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require File.expand_path(__FILE__ + '/../../../razor_helper', '.')
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Create repo with blank name'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/597'

reset_database

razor agents, 'create-repo --name "" --url "http://provisioning.example.com/centos-6.4/x86_64/os/" --task centos', nil, exit: 1 do |agent, output|
  assert_match /name must be between 1 and 250 characters in length, but is 0 characters long/, output
end