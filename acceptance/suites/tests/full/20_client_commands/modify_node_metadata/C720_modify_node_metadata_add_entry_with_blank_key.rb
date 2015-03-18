# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require 'razor/acceptance/utils'
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Modify node metadata add entry with blank key'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/720'

reset_database

razor agents, 'register-node --installed true --hw-info net0=abcdef' do |agent, output|
  name = /name:\s+(?<name>.+)/.match(output)[:name]
  step "Verify that the node is defined on #{agent}"
  text = on(agent, "razor -u https://#{agent}:8151/api nodes #{name}").output
  assert_match /name: /, text

  razor agent, "modify-node-metadata --node #{name} --update '{\"\" : \"value\"}'", nil, exit: 1 do | agent, output |
    assert_match /update should be a object, but failed validation: blank hash key not allowed/, output
  end
end