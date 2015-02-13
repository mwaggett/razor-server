# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require File.expand_path(__FILE__ + '/../../../razor_helper', '.')
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Reinstall node that has never been installed'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/765'

reset_database

razor agents, 'register-node --installed false --hw-info \'{"net0": "abcdef"}\'' do |agent, output|
  name = /name:\s+(?<name>.+)/.match(output)[:name]
  step "Verify that the node is defined on #{agent}"
  text = on(agent, "razor -u http://#{agent}:8080/api --full nodes #{name}").output
  assert_match /abcdef/, text

  razor agent, 'reinstall-node --name ' + name, nil do |agent, output|
    assert_match /no changes; node #{name} was neither bound nor installed/, output
  end
end

