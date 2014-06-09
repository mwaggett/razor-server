# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require File.expand_path(__FILE__ + '/../../razor_helper', '.')
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'C790 Set Node Power State with invalid JSON syntax'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/790'

reset_database

step "create a node that we can set the power state of later"
json = {'installed' => true, 'hw-info' => {'net0' => '00:0c:29:08:06:e0'}}
razor agents, 'register-node', json do |node, text|
  _, nodeid = text.match(/name: "(node\d+)"/).to_a
  refute_nil nodeid, 'failed to extract node ID from output'

  json = '{"name" => nodeid, "to" => on}'
  razor node, 'set-node-desired-power-state', json, exit: 1 do |node, text|
    assert_match %r{Error: File /tmp/.*\.json is not valid JSON}, text
  end
end
