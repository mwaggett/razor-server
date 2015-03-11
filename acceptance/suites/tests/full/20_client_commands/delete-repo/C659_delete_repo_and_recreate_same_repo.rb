# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require 'razor/acceptance/utils'
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Delete repo and recreate same repo'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/659'

reset_database

razor agents, 'create-repo --name puppet-test-repo --url "http://provisioning.example.com/centos-6.4/x86_64/os/" --task centos' do |agent|
  step "Verify that the repo is defined on #{agent}"
  text = on(agent, "razor -u https://#{agent}:8151/api repos").output
  assert_match /puppet-test-repo/, text
end

razor agents, 'delete-repo --name puppet-test-repo' do |agent|
  step "Verify that the repo is no longer defined on #{agent}"
  text = on(agent, "razor -u https://#{agent}:8151/api repos").output
  refute_match /puppet-test-repo/, text
end

razor agents, 'create-repo --name puppet-test-repo --url "http://provisioning.example.com/centos-6.4/x86_64/os/" --task centos' do |agent|
  step "Verify that the repo is defined on #{agent}"
  text = on(agent, "razor -u https://#{agent}:8151/api repos").output
  assert_match /puppet-test-repo/, text
end
