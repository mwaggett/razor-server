# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require File.expand_path(__FILE__ + '/../../razor_helper', '.')
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database}

test_name "C550 Create Policy with missing repo configuration parameter"
step "https://testrail.ops.puppetlabs.net/index.php?/cases/view/550"

reset_database agents

razor agents, 'create-tag', {
  "name" => "small",
  "rule" => ["=", ["fact", "processorcount"], "2"]
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
  "tags"          => ["small"]
}

razor agents, 'create-policy', json, exit: 1 do |agent, text|
  assert_match /404 Resource Not Found/, text
  assert_match /repo must be the name of an existing repo, but is 'centos-6.4'/, text
end
