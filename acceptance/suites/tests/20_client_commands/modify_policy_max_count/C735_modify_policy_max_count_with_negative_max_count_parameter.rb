# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require File.expand_path(__FILE__ + '/../../../razor_helper', '.')
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Modify policy max count with negative max count parameter'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/735'

reset_database

results = create_policy agents

razor agents, "modify-policy-max-count --name #{results[:policy][:name]} --max-count -10", nil, exit:1 do |agent, output|
  assert_match /There are currently 0 nodes bound to this policy. Cannot lower max-count to -10/, output
end
