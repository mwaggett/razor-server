# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require 'razor/acceptance/utils'
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Delete policy with unicode name'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/649'

reset_database

name = long_unicode_string
create_policy agents, policy_name: name

json = {
    'name' => name
}
razor agents, 'delete-policy', json do |agent|
  step "Verify that the policy is no longer defined on #{agent}"
  text = on(agent, "razor -u https://#{agent}:8151/api policies").output
  refute_match /#{Regexp.escape(name)}/, text
end
