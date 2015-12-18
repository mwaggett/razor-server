# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require 'razor/acceptance/utils'
require 'yaml'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'QA-1820 - C59746 - create-hook with non-existing configuration object'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/59747'

hook_dir            = '/opt/puppetlabs/server/apps/razor-server/share/razor-server/hooks'
hook_type           = 'hook_type_1'
hook_name           = 'hook_name_2'
hook_path           = "#{hook_dir}/#{hook_type}.hook"

configuration_file =<<-EOF
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

agents.each do |agent|
  with_backup_of(agent, hook_dir) do
    step 'Create hook with name and hook-type only'
    on(agent, "mkdir -p #{hook_path}")
    create_remote_file(agent,"#{hook_path}/configuration.yaml", configuration_file)
    on(agent, "chmod +r #{hook_path}/configuration.yaml")
    on(agent, "razor create-hook --name #{hook_name}" \
              " --hook-type #{hook_type} --c non-existing-object=aValue", \
            :acceptable_exit_codes => [1]) do |result|
      assert_match(/error: configuration key \'non-existing-object\' is not defined for this hook type/, result.stdout, 'test failed!')
    end
  end
end
