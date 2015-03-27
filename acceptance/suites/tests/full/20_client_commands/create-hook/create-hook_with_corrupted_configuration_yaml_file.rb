# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require 'razor/acceptance/utils'
require 'yaml'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'QA-1820 - C59748 - create-hook with corrupted configuration.yaml file'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/59748'

hook_dir      = '/opt/puppet/share/razor-server/hooks'
hook_type     = 'hook_type_1'
hook_name     = 'hookName1'
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
THIS IS A CORRUPTED CONFIGURATION.YAML FILE
  description: "The current value of the hook"
  default: 0
foo:
EOF

step "Create hook type"
agents.each do |agent|
  on(agent, "mkdir -p #{hook_path}")
  create_remote_file(agent,"#{hook_path}/configuration.yaml", configurationFile)
  on(agent, "chmod +r #{hook_path}/configuration.yaml")
  on(agent, "razor create-hook --name #{hook_name}" \
            " --hook-type #{hook_type} --c value=5 --c foo=newFoo --c bar=newBar", \
            :acceptable_exit_codes => [1]) do |result|
    assert_match(/500 Internal Server Error/, result.stdout, 'Create hook test failed')
  end
end
