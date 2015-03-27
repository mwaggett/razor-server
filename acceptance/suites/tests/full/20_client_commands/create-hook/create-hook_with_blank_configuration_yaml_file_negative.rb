# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require 'razor/acceptance/utils'
require 'yaml'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'QA-1820 - C59749 - create-hook with blank configuration.yaml file negative test'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/59749'

hook_dir      = '/opt/puppet/share/razor-server/hooks'
hook_type     = 'hook_type_1'
hook_name     = 'hookName1'
hook_path     = "#{hook_dir}/#{hook_type}.hook"

teardown do
  agents.each do |agent|
    on(agent, "test -e #{hook_dir}.bak && mv #{hook_dir}.bak  #{hook_dir} || rm -rf #{hook_dir}")
  end
end

step "Backup #{hook_dir}"
agents.each do |agent|
  on(agent, "test -e #{hook_dir} && cp #{hook_dir} #{hook_dir}.bak} || true")
end

configurationFile =<<-EOF
EOF

step "Create hook type"
agents.each do |agent|
  on(agent, "mkdir -p #{hook_path}")
  create_remote_file(agent,"#{hook_path}/configuration.yaml", configurationFile)
  on(agent, "chmod +r #{hook_path}/configuration.yaml")

  #This is a negative test because it attempts to create a hook with undefined configuration object.
  # This test is different from https://testrail.ops.puppetlabs.net/index.php?/cases/view/63490
  # because it has a blank configuration.yaml while test case C63490 does not have the configuration.yaml
  on(agent, "razor create-hook --name #{hook_name}" \
            " --hook-type #{hook_type} --c value=5 --c foo=newFoo --c bar=newBar", \
            :acceptable_exit_codes => [1]) do |result|
    assert_match %r(error: configuration key 'value' is not defined for this hook type), result.stdout
  end
end
