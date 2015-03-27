# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require 'razor/acceptance/utils'
require 'yaml'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Create new user in shiro.ini'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/59697'

config_yaml       = '/etc/puppetlabs/razor/config.yaml'
config_yaml_bak   = '/tmp/config.yaml.bak'

shiro_ini         = '/etc/puppetlabs/razor/shiro.ini'
shiro_ini_bak     = '/tmp/shiro.ini.bak'

teardown do
  agents.each do |agent|
    on(agent, "test -e #{config_yaml_bak} && mv #{config_yaml_bak} #{config_yaml}")
    on(agent, "test -e #{shiro_ini_bak} && mv #{shiro_ini_bak} #{shiro_ini}")
    on(agent, "chmod +r #{config_yaml} #{shiro_ini}")
    restart_razor_service(agent)
  end
end

step "Backup #{config_yaml} and #{shiro_ini}"
agents.each do |agent|
  on(agent, "test -e #{config_yaml} && cp #{config_yaml} #{config_yaml_bak}")
  on(agent, "test -e #{shiro_ini} && cp #{shiro_ini} #{shiro_ini_bak}")
end

agents.each do |agent|
  step "Enable authentication on #{agent}"
  config = on(agent, "cat #{config_yaml}").output
  yaml = YAML.load(config)
  yaml['all']['auth']['enabled'] = true
  config = YAML.dump(yaml)

  step "Create new #{config_yaml} on #{agent}"
  create_remote_file(agent, "#{config_yaml}", config)

  step "Create new user on  #{agent}"
  shiro = on(agent, "cat #{shiro_ini}").output
  new_file = shiro.gsub(/razor = razor, admin/, "razor = razor, admin\nnewUser = newPassword, admin")

  create_remote_file(agent, "#{shiro_ini}", new_file)

  step "Set up users on #{agent}"
  on(agent, 'cat /etc/puppetlabs/razor/shiro.ini') do |result|
    assert_match /^\s*razor = razor/, result.stdout, 'User razor should already have password "razor"'
  end

  step "Restart Razor Service on #{agent}"
  restart_razor_service(agent)

  step 'C59697: Authenticate to razor server #{agent} with newly created credentials'
  on(agent, "razor -u https://newUser:newPassword@#{agent}:8151/api") do |result|
    assert_match(/Collections:/, result.stdout, 'The request should be unauthorized')
  end
end
