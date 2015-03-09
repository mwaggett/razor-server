# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require 'razor/acceptance/utils'
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Modify node metadata add entry with unicode name'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/702'

reset_database

razor agents, 'register-node --installed true --hw-info net0=abcdef' do |agent, output|
  node_name = /name:\s+(?<name>.+)/.match(output)[:name]
  step "Verify that the node is defined on #{agent}"
  text = on(agent, "razor -u https://#{agent}:8151/api nodes #{node_name}").output
  assert_match /name: /, text
  key = unicode_string
  value = unicode_string

  json = {
      'node' => node_name,
      'update' => {key => value}
  }
  razor agent, 'modify-node-metadata', json do |agent|
    step "Verify that the metadata for node #{node_name} is defined on #{agent}"
    text = on(agent, "razor -u https://#{agent}:8151/api nodes #{node_name}").output
    assert_match /metadata:\s+\n\s+#{Regexp.escape(key)}:\s+#{Regexp.escape(value)}/, text
  end
end
