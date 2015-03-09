# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require File.expand_path(__FILE__ + '/../../../razor_helper', '.')
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Command - "repos"'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/446'

reset_database

agents.each do |agent|
  step "Test empty query results on #{agent}"
  text = on(agent, "razor -u https://#{agent}:8151/api repos").output
  assert_match /There are no items for this query./, text
end

razor agents, 'create-repo --name puppet-test-repo --url "http://provisioning.example.com/centos-6.4/x86_64/os/" --task centos' do |agent|
  step "Test single query result on #{agent}"
  text = on(agent, "razor -u https://#{agent}:8151/api repos").output
  assert_match /puppet-test-repo/, text
end