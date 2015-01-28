# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require File.expand_path(__FILE__ + '/../../../razor_helper', '.')
require 'yaml'
confine :to, :platform => %w{el-6-x86_64 el-7-x86_64}
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Enable auth and authenticate with bad user and bad password'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/62410'

config_yaml       = '/etc/puppetlabs/razor/config.yaml'
config_yaml_bak   = '/tmp/config.yaml.bak'


teardown do
  agents.each do |agent|
    on(agent, "test -e #{config_yaml_bak} && mv #{config_yaml_bak} #{config_yaml} || rm #{config_yaml}")
  end
end

#backup
agents.each do |agent|
  on(agent, "test -e #{config_yaml} && cp #{config_yaml} #{config_yaml_bak} || true")
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
  on agent, "chmod +r #{config_yaml}"

  step "Set up users on #{agent}"
  shiro = on(agent, 'cat /etc/puppetlabs/razor/shiro.ini').output
  assert_match /^\s*razor = razor/, shiro, 'User razor should already have password "razor"'

  step "Restart Razor Service on #{agent}"
  # the redirect to /dev/null is to work around a bug in the init script or
  # service, per: https://tickets.puppetlabs.com/browse/RAZOR-247
  on agent, 'service pe-razor-server restart >&/dev/null'

  step 'C62410: Authenticate to razor server #{agent} with bad user and bad password'
  text = on(agent, "razor -u http://badUser:badPassword@#{agent}:8080/api").output

  assert_match(/Credentials are required/, text,
               'The request should be unauthorized')
end
