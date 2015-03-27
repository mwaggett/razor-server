# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require 'razor/acceptance/utils'
require 'yaml'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Enable auth and authenticate with bad user and good password'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/62409'

config_yaml       = '/etc/puppetlabs/razor/config.yaml'
config_yaml_bak   = '/tmp/config.yaml.bak'

teardown do
  agents.each do |agent|
    on(agent, "test -e #{config_yaml_bak} && mv #{config_yaml_bak} #{config_yaml}")
    on(agent, "chmod +r #{config_yaml}")
    restart_razor_service(agent)
  end
end

#backup
agents.each do |agent|
  on(agent, "test -e #{config_yaml} && cp #{config_yaml} #{config_yaml_bak}")
end

agents.each do |agent|
  step "Enable authentication on #{agent}"
  config = on(agent, "cat #{config_yaml}").output
  yaml = YAML.load(config)
  yaml['all']['auth']['enabled'] = true
  config = YAML.dump(yaml)

  step "Create new #{config_yaml} on #{agent}"
  create_remote_file(agent, "#{config_yaml}", config)

  step "Set up users on #{agent}"
  on(agent, 'cat /etc/puppetlabs/razor/shiro.ini') do |result|
    assert_match /^\s*razor = razor/, result.stdout, 'User razor should already have password "razor"'
  end

  step "Restart Razor Service on #{agent}"
  # the redirect to /dev/null is to work around a bug in the init script or
  # service, per: https://tickets.puppetlabs.com/browse/RAZOR-247
  restart_razor_service(agent)

  step 'C62409: Authenticate to razor server #{agent} with bad user and good password'
  on(agent, "razor -u https://badUser:razor@#{agent}:8151/api", acceptable_exit_codes: 1) do |result|
    assert_match(/Credentials are required/, result.stdout, 'The request should be unauthorized')
  end
end
