# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
#require 'razor_helper'
require 'yaml'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'QA-1821 - C59734 - delete hook then recreate same hook'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/59734'

hook_dir      = '/opt/puppet/share/razor-server/hooks'
hook_type     = 'hook_type_1'
hook_name     = 'hookName1'
hook_path     = "#{hook_dir}/#{hook_type}.hook"

teardown do
  agents.each do |agent|
    on(agent, "test -e #{hook_dir}.bak && mv #{hook_dir}.bak  #{hook_dir} || rm -rf #{hook_dir}")
    on(agent, "razor delete-hook --name #{hook_name}")
  end
end

step "Backup #{hook_dir}"
agents.each do |agent|
  on(agent, "test -e #{hook_dir} && cp #{hook_dir} #{hook_dir}.bak} || true")
end

configurationFile =<<-EOF
---
value:
  description: "The current value of the hook"
  default: 0
foo:
  description: "The current value of the hook"
  default: defaultFoo
bar:
  description: "The current value of the hook"
  default: defaultBar

EOF

step "Create hook type"
agents.each do |agent|
  on(agent, "mkdir -p #{hook_path}")
  create_remote_file(agent,"#{hook_path}/configuration.yaml", configurationFile)
  on(agent, "chmod +r #{hook_path}/configuration.yaml")
  on(agent, "razor create-hook --name #{hook_name}" \
            " --hook-type #{hook_type} --c value=5 --c foo=newFoo --c bar=newBar")

  step 'Verify if the hook is successfully created:'
  on(agent, "razor hooks") do |result|
    assert_match(/#{hook_name}/, result.stdout, 'razor create-hook failed')
  end

  step 'Delete the newly created hook'
  on(agent, "razor delete-hook --name #{hook_name}") do |result|
    assert_match(/result: hook #{hook_name} destroyed/, result.stdout, 'test failed')
  end

  step "Verify that hook #{hook_name} is no longer defined on #{agent}"
  text = on(agent, "razor hooks").output
  refute_match /#{hook_name}/, text

  step "Create a new hook with same name as the newly deleted hook:  '#{hook_name}'"
  on(agent, "razor create-hook --name #{hook_name}" \
            " --hook-type #{hook_type} --c value=5 --c foo=newFoo --c bar=newBar")

  step "Create a new hook with same name as existing hook #{hook_name}"
  on(agent, "razor create-hook --name #{hook_name}" \
            " --hook-type #{hook_type} --c value=5 --c foo=newFoo --c bar=newBar")

end
