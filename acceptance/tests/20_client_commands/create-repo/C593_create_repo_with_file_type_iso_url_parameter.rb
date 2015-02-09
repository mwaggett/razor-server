# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require File.expand_path(__FILE__ + '/../../../razor_helper', '.')
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Create repo with file type iso-url parameter'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/593'

reset_database

razor agents, 'create-repo --name puppet-test-repo --iso-url "file:///this/directory/does/not/exist/yet" --task centos' do |agent|
  step "Verify that the repo is defined on #{agent}"
  text = on(agent, "razor -u http://#{agent}:8080/api repos").output
  assert_match /puppet-test-repo/, text
end