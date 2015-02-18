# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require 'razor_helper'
require 'yaml'
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Razor - C59715 create-hook with long unicode name  (250 characters)'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/59715'

hook_dir      = '/opt/puppet/share/razor-server/hooks'
hook_type     = 'hook_type_1'
hook_name     = "扊扊扊℃갗ⴎ駘Ⰲ㽸Ꚁ扊℃갗ⴎ駘Ⰲ㽸Ꚁ扊℃갗ⴎ駘Ⰲ㽸Ꚁ扊℃갗ⴎ駘Ⰲ㽸Ꚁ扊℃갗ⴎ駘Ⰲ㽸Ꚁ扊℃갗ⴎ駘Ⰲ㽸Ꚁ扊℃갗ⴎ駘Ⰲ㽸Ꚁ扊℃갗ⴎ駘Ⰲ㽸Ꚁ扊℃갗ⴎ駘Ⰲ㽸Ꚁ扊℃갗ⴎ駘Ⰲ㽸Ꚁ扊"

hook_path     = "#{hook_dir}/#{hook_type}.hook"


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
  on(agent, "razor -u http://#{agent}:8080/api create-hook --name #{hook_name}" \
            " --hook-type #{hook_type} --c value=5 --c foo=newFoo --c bar=newBar")

  step 'Verify if the hook is successfully created:'
  on(agent, "razor -u http://razor-razor@#{agent}:8080/api hooks") do |result|
    assert_match(/name: #{hook_name}/, result.stdout, 'razor create-hook failed')
  end
end


teardown do
  agents.each do |agent|
    on(agent, "test -e #{hook_dir}.bak && mv #{hook_dir}.bak  #{hook_dir} || rm -rf #{hook_dir}")
    on(agent, "razor -u http://#{agent}:8080/api delete-hook --name #{hook_name}")
  end
end

