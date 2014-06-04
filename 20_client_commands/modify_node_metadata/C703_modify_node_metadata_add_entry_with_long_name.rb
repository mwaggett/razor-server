# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require File.expand_path(__FILE__ + '/../../../razor_helper', '.')
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Modify node metadata add entry with unicode name'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/702'

reset_database

razor agents, 'register-node --installed true --hw-info net0=abcdef' do |agent, output|
  node_name = /name:\s+(?<name>.+)/.match(output)[:name]
  step "Verify that the node is defined on #{agent}"
  text = on(agent, "razor -u http://#{agent}:8080/api nodes #{node_name}").output
  assert_match /name: /, text
  data = "abc123-_"
  key = (1..250).map { data[rand(data.length)] }.join
  value = (1..250).map { data[rand(data.length)] }.join

  razor agent, "modify-node-metadata --node #{node_name} --update #{key}=#{value}" do |agent|
    step "Verify that the metadata for node #{node_name} is defined on #{agent}"
    text = on(agent, "razor -u http://#{agent}:8080/api nodes #{node_name}").output
    assert_match /metadata:\s+\n\s+#{key}:\s+#{value}/, text
  end
end
