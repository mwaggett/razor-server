# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require File.expand_path(__FILE__ + '/../../../razor_helper', '.')
require 'yaml'
confine :to, :platform => %w{el-6-x86_64 el-7-x86_64}
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Create new user in shiro.ini'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/59697'

config_yaml       = '/etc/puppetlabs/razor/config.yaml'
config_yaml_bak   = '/tmp/config.yaml.bak'

shiro_ini         = '/etc/puppetlabs/razor/shiro.ini'
shiro_ini_bak     = '/tmp/shiro.ini.bak'


teardown do
  agents.each do |agent|
    on(agent, "test -e #{config_yaml_bak} && mv #{config_yaml_bak} #{config_yaml} || rm #{config_yaml}")
    on(agent, "test -e #{shiro_ini_bak} && mv #{shiro_ini_bak} #{shiro_ini} || rm #{shiro_ini}")
  end
end

step "Backup #{config_yaml} and #{shiro_ini}"
agents.each do |agent|
  on(agent, "test -e #{config_yaml} && cp #{config_yaml} #{config_yaml_bak} || true")
  on(agent, "test -e #{shiro_ini} && cp #{shiro_ini} #{shiro_ini_bak} || true")
end

agents.each do |agent|
  step "Enable authentication on #{agent}"
  config = on(agent, "cat #{config_yaml}").output
  yaml = YAML.load(config)
  yaml['all']['auth']['enabled'] = true
  config = YAML.dump(yaml)

  File.open('new-config-yaml', "w") {|file| file.write(config)}
  step "Copy modified config.yaml to #{agent}"
  scp_to agent, 'new-config-yaml', "#{config_yaml}"
  File.delete('new-config-yaml')
  on(agent, "chmod +r #{config_yaml}")

  step "Create new user on  #{agent}"
  shiro = on(agent, "cat #{shiro_ini}").output
  new_file = shiro.gsub(/razor = razor, admin/, "razor = razor, admin\nnewUser = newPassword, admin")

  # Write new user to shiro.ini file
  File.open('new-shiro.ini', "w"){|file| file.puts new_file}
  step "Copy modified shiro.ini to #{agent}"
  scp_to agent, 'new-shiro.ini', '/etc/puppetlabs/razor/shiro.ini'
  File.delete('new-shiro.ini')
  on(agent, "chmod +r #{shiro_ini}")

  step "Set up users on #{agent}"
  shiro = on(agent, 'cat /etc/puppetlabs/razor/shiro.ini').output
  assert_match /^\s*razor = razor/, shiro, 'User razor should already have password "razor"'

  step "Restart Razor Service on #{agent}"
  on agent, 'service pe-razor-server restart >&/dev/null'

  step 'C59697: Authenticate to razor server #{agent} with newly created credentials'
  text = on(agent, "razor -u http://newUser:newPassword@#{agent}:8080/api").output

  assert_match(/Collections:/, text,
               'The request should be unauthorized')
end
