# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require File.expand_path(__FILE__ + '/../../../razor_helper', '.')
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Remove node metadata erase entry that does not exist'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/773'

reset_database


razor agents, 'register-node --installed true --hw-info net0=abcdef' do |agent, output|
  name = /name:\s+(?<name>.+)/.match(output)[:name]
  step "Verify that the node is defined on #{agent}"
  text = on(agent, "razor -u https://#{agent}:8151/api nodes #{name}").output
  assert_match /name: /, text

  razor agent, "remove-node-metadata --node #{name} --key does-not-exist" do |agent, output|
    assert_match /metadata:\s+---/, output
  end
end
