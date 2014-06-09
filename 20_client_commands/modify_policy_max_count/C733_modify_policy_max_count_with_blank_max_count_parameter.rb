# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require File.expand_path(__FILE__ + '/../../../razor_helper', '.')
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Modify policy max count with blank max count parameter'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/733'

reset_database

results = create_policy agents

razor agents, "modify-policy-max-count --name #{results[:policy][:name]} --max-count ''", nil, exit:1 do |agent, output|
  assert_match /New max-count '' is not a valid integer/, output
end
