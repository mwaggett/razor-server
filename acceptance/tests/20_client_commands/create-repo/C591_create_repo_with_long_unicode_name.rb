# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require File.expand_path(__FILE__ + '/../../../razor_helper', '.')
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Create repo with long unicode name (250 characters)'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/590'

reset_database

name = long_unicode_string

json = {
    "name" => name,
    "url"  => "http://provisioning.example.com/centos-6.4/x86_64/os/",
    "task" => "centos"
}

razor agents, 'create-repo', json do |agent|
  step "Verify that the repo is defined on #{agent}"
  text = on(agent, "razor -u http://#{agent}:8080/api repos").output
  assert_match /#{Regexp.escape(name)}/, text
end