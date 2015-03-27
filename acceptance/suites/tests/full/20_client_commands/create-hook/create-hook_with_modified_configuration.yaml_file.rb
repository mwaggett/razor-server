# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require 'razor/acceptance/utils'
require 'yaml'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'QA-1819 - C59717 - create hook with modified configuration.yaml file'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/59717'

hook_dir      = '/opt/puppet/share/razor-server/hooks'
hook_type     = 'hook_type_1'
hook_name1    = 'hookName1'
hook_name2    = 'hookName2'
hook_path     = "#{hook_dir}/#{hook_type}.hook"

teardown do
  agents.each do |agent|
    on(agent, "test -e #{hook_dir}.bak && mv #{hook_dir}.bak  #{hook_dir} || rm -rf #{hook_dir}")
    on(agent, "razor delete-hook --name #{hook_name1}")
    on(agent, "razor delete-hook --name #{hook_name2}")
  end
end

reset_database

step "Backup #{hook_dir}"
agents.each do |agent|
  on(agent, "test -e #{hook_dir} && cp #{hook_dir} #{hook_dir}.bak} || true")
end

json = {
    "name"            => "#{hook_name2}",
    "hook-type"       => "#{hook_type}",
    "configuration"   => {
        "foo2"         => "newFoo222",
        "bar2"         => "newBar222"
    }
}

#Original configuration.yaml file
configurationFile1 =<<-EOF
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

# Modify configuration.yaml and add two more objects: foo2 and bar2
configurationFile2 =<<-EOF
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
foo2:
    description: "The current value of the hook"
default: defaultFoo2
bar2:
    description: "The current value of the hook"
default: defaultBar2

EOF

step "Create hook type #{hook_type}"
agents.each do |agent|
  on(agent, "mkdir -p #{hook_path}")
  create_remote_file(agent,"#{hook_path}/configuration.yaml", configurationFile1)
  on(agent, "chmod +r #{hook_path}/configuration.yaml")

  step "Create a hook with original configuration.yaml file:"
  on(agent, "razor create-hook --name #{hook_name1}" \
            " --hook-type #{hook_type} --c value=5 --c foo=newFoo --c bar=newBar")

  step 'Verify if the hook is successfully created:'
  on(agent, "razor -u https://razor-razor@#{agent}:8151/api hooks") do |result|
    assert_match(/#{hook_name1}/, result.stdout, 'razor create-hook failed with original configuration.yaml file')
  end

  step "Create modified configuration.yaml file:"
  create_remote_file(agent, "#{hook_path}/configuration.yaml", configurationFile2)
  on(agent, "chmod +r #{hook_path}/configuration.yaml")

  step "Create hook with newly modified configuration.yaml file:"
  razor agent, 'create-hook', json

  step "Verify that the hook is created on #{agent}"
    on(agent, "razor hooks") do |result|
      assert_match(/#{hook_name2}/, result.stdout, 'razor create-hook failed with modified configuration.yaml file')

    end
end
