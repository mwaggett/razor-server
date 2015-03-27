# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require 'razor/acceptance/utils'
require 'yaml'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'QA-1820 - C59742 - create-hook with missing required configuration parameter'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/59742'

hook_dir      = '/opt/puppet/share/razor-server/hooks'
hook_type     = 'hook_type_1'
hook_name     = 'hook_name_2'
hook_path     = "#{hook_dir}/#{hook_type}.hook"

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
  required: true
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

  step 'create hook with  missing hook configuration attr'
  on(agent, "razor create-hook --name #{hook_name}" \
            " --hook-type #{hook_type}", :acceptable_exit_codes => [1]) do |result| \
        assert_match %r(error: configuration key 'value' is required by this hook type, but was not supplied), result.stdout
  end

end
