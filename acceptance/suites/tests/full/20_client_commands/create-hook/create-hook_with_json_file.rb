# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require 'razor/acceptance/utils'
require 'yaml'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'QA-1819 - C59716 - create-hook with json file'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/59716'

hook_dir      = '/opt/puppet/share/razor-server/hooks'
hook_type     = 'hook_type_1'
hook_name     = 'hookName1'
hook_path     = "#{hook_dir}/#{hook_type}.hook"

teardown do
  agents.each do |agent|
    on(agent, "test -e #{hook_dir}.bak && rm -rf #{hook_dir} && mv #{hook_dir}.bak #{hook_dir}")
    on(agent, "razor delete-hook --name #{hook_name}")
  end
end

reset_database

step "Backup #{hook_dir}"
agents.each do |agent|
  on(agent, "test -e #{hook_dir} && cp -r #{hook_dir} #{hook_dir}.bak")
end

json = {
    "name"            => "#{hook_name}",
    "hook-type"       => "#{hook_type}",
    "configuration"   => {
        "value"       => "7",
        "foo"         => "newFoo2",
        "bar"         => "newBar2"
    }
}

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

  step "Create hook"
  razor agent, 'create-hook', json
  
  step "Verify that the hook is created on #{agent}"
    on(agent, "razor hooks") do |result|
      assert_match(/#{hook_name}/, result.stdout, 'razor create-hook failed')
    end
end
