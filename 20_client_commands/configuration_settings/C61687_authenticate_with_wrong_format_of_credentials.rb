# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require 'razor_helper'
require 'yaml'
confine :to, :platform => %w{el-6-x86_64 el-7-x86_64}
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'C61687: Enable auth and authenticate with wrong format of credentials'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/61687'

config_yaml       = '/etc/puppetlabs/razor/config.yaml'
config_yaml_bak   = '/tmp/config.yaml.bak'

teardown do
  agents.each do |agent|
    on(agent, "test -e #{config_yaml_bak} && mv #{config_yaml_bak} #{config_yaml} || rm #{config_yaml}")
    on(agent, "chmod +r #{config_yaml}")
    on(agent, 'service pe-razor-server restart >&/dev/null')
  end
end

step "Backup #{config_yaml}"
agents.each do |agent|
  on(agent, "test -e #{config_yaml} && cp #{config_yaml} #{config_yaml_bak} || true")
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
  on agent, 'service pe-razor-server restart >&/dev/null'

  step 'C61687: Authenticate to razor server #{agent} with wrong format of credentials ("-" instead of ":")'
  on(agent, "razor -u http://razor-razor@#{agent}:8080/api") do |result|
    assert_match(/Credentials are required/, result.stdout, 'The request should be unauthorized')
  end
end
