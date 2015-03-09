# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require 'razor/acceptance/utils'
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Modify node metadata add entry that already exists'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/718'

reset_database

razor agents, 'register-node --installed true --hw-info net0=abcdef' do |agent, output|
  name = /name:\s+(?<name>.+)/.match(output)[:name]
  step "Verify that the node is defined on #{agent}"
  text = on(agent, "razor -u https://#{agent}:8151/api nodes #{name}").output
  assert_match /name: /, text

  razor agent, 'modify-node-metadata --node ' + name + ' --update key=value' do |agent|
    step "Verify that the metadata is defined on #{agent}"
    text = on(agent, "razor -u https://#{agent}:8151/api nodes #{name}").output
    assert_match /metadata:\s+\n\s+key:\s+value/, text
  end

  razor agent, 'modify-node-metadata --node ' + name + ' --update key=value' do |agent, output|
    refute_match /[Ee]rror/, output
    step "Verify that the metadata is still defined on #{agent}"
    text = on(agent, "razor -u https://#{agent}:8151/api nodes #{name}").output
    assert_match /metadata:\s+\n\s+key:\s+value/, text
  end
end
