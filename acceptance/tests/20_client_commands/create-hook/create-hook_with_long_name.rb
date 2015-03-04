# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require 'razor_helper'
require 'yaml'
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'QA-1818 - C59714 - create-hook with long name  (250 characters)'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/59714'

hook_dir      = '/opt/puppet/share/razor-server/hooks'
hook_type     = 'hook_type_1'
hook_name     = long_string
hook_path     = "#{hook_dir}/#{hook_type}.hook"

teardown do
  agents.each do |agent|
    on(agent, "test -e #{hook_dir}.bak && mv #{hook_dir}.bak  #{hook_dir} || rm -rf #{hook_dir}")
    on(agent, "razor -u https://#{agent}:8151/api delete-hook --name #{hook_name}")
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
  on(agent, "razor -u https://#{agent}:8151/api create-hook --name #{hook_name}" \
            " --hook-type #{hook_type} --c value=5 --c foo=newFoo --c bar=newBar")

  step 'Verify if the hook is successfully created:'
  on(agent, "razor -u https://razor-razor@#{agent}:8151/api hooks") do |result|
    assert_match(/name: #{hook_name}/, result.stdout, 'razor create-hook failed')
  end
end
