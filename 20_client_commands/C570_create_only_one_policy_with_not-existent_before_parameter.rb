# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require File.expand_path(__FILE__ + '/../../razor_helper', '.')
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database}

test_name "C570 Create only one Policy with non-existent 'before' configuration parameter"
step "https://testrail.ops.puppetlabs.net/index.php?/cases/view/570"

reset_database

razor agents, 'create-tag', {
  "name" => "small",
  "rule" => ["=", ["fact", "processorcount"], "2"]
}

razor agents, 'create-repo', {
  "name" => "centos-6.4",
  "url"  => "http://provisioning.example.com/centos-6.4/x86_64/os/",
  "task" => "centos"
}


razor agents, 'create-broker', {
  "name"        => "noop",
  "broker-type" => "noop"
}



json = {
  "name"          => "centos-for-small",
  "repo"          => "centos-6.4",
  "task"          => "centos",
  "broker"        => "noop",
  "enabled"       => true,
  "hostname"      => "host${id}.example.com",
  "root-password" => "secret",
  "max-count"     => 20,
  "tags"          => ["small"],
  "before"        => "nonesuch"
}

razor agents, 'create-policy', json, exit: 1 do |agent, text|
  assert_match /404 Resource Not Found/, text
  assert_match /before must be the name of an existing policy, but is 'nonesuch'/, text
end
