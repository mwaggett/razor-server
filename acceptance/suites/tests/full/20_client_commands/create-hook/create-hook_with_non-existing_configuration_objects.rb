# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require 'razor/acceptance/utils'
require 'yaml'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'QA-1820 - C59746 - create-hook with non-existing configuration object'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/59747'

hook_dir            = '/opt/puppet/share/razor-server/hooks'
hook_type           = 'hook_type_1'
hook_name           = 'hook_name_2'
hook_path           = "#{hook_dir}/#{hook_type}.hook"

teardown do
  agents.each do |agent|
    on(agent, "test -e #{hook_dir}.bak && mv #{hook_dir}.bak #{hook_dir}")
  end
end

step "Backup #{hook_dir}"
agents.each do |agent|
  on(agent, "test -e #{hook_dir} && cp #{hook_dir} #{hook_dir}.bak")
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


step 'Create hook with name and hook-type only'
agents.each do |agent|
  on(agent, "mkdir -p #{hook_path}")
  create_remote_file(agent,"#{hook_path}/configuration.yaml", configurationFile)
  on(agent, "chmod +r #{hook_path}/configuration.yaml")
  on(agent, "razor create-hook --name #{hook_name}" \
            " --hook-type #{hook_type} --c non-existing-object=aValue", \
          :acceptable_exit_codes => [1]) do |result|
    assert_match(/error: configuration key \'non-existing-object\' is not defined for this hook type/, result.stdout, 'test failed!')
  end
end