# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require 'razor/acceptance/utils'
require 'yaml'
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'QA-1820 - C63490 - create-hook with non-existing config param'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/63490'

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

step "Create hook type"
agents.each do |agent|
  on(agent, "mkdir -p #{hook_path}")
  on(agent, "razor -u https://#{agent}:8151/api create-hook --name #{hook_name}" \
           " --hook-type #{hook_type} --c value=5 --c foo=newFoo --c bar=newBar", \
            :acceptable_exit_codes => [1]) do |result|
    assert_match %r(error: configuration key 'value' is not defined for this hook type), result.stdout
  end
end
