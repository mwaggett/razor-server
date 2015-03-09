# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require 'razor/acceptance/utils'
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}
require 'tmpdir'

test_name "Update tag rule with Invalid path for JSON File"
step "https://testrail.ops.puppetlabs.net/index.php?/cases/view/815"

file = '/tmp/' + Dir::Tmpname.make_tmpname(['update-tag-rule-', '.json'], nil)

step 'Ensure the temporary file is absolutely not present'
on agents, "rm -f #{file}"

reset_database
razor agents, 'update-tag-rule', %W{--json #{file}}, exit: 1 do |agent, text|
  assert_match %r{Error: File /tmp/update-tag-rule.*\.json not found}, text
end

