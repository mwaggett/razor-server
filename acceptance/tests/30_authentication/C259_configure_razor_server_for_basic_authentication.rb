# -*- encoding: utf-8 -*-
# this is required because of the use of eval interacting badly with require_relative
require File.expand_path(__FILE__ + '/../../razor_helper', '.')
require 'yaml'
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Configure Razor server for basic authentication'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/259'

def with_backup_of(host, file)
  Dir.mktmpdir('beaker-backup') do |tmpdir|
    scp_from host, "/etc/puppetlabs/razor/#{file}", tmpdir
    begin
      yield tmpdir
    ensure
      scp_to host, File::join(tmpdir, file), "/etc/puppetlabs/razor/#{file}"
    end
  end
end

agents.each do |agent|
  begin
    step "Enable authentication on #{agent}"
    with_backup_of(agent, 'config.yaml') do |config_tmpdir|
      config = on(agent, 'cat /etc/puppetlabs/razor/config.yaml').output
      yaml = YAML.load(config)
      yaml['all']['auth']['enabled'] = true
      config = YAML.dump(yaml)
      File.open(File::join(config_tmpdir, 'new-config.yaml'), 'w') {|f| f.write(config) }
      step "Copy modified config.yaml to #{agent}"
      scp_to agent, File::join(config_tmpdir, 'new-config.yaml'), '/etc/puppetlabs/razor/config.yaml'
      on agent, 'chmod +r /etc/puppetlabs/razor/config.yaml'

      step "Set up users on #{agent}"
      with_backup_of(agent, 'shiro.ini') do |_|
        shiro = on(agent, 'cat /etc/puppetlabs/razor/shiro.ini').output
        assert_match /^\s*razor = razor/, shiro, 'User razor should already have password "razor"'

        step "Restart Razor Service on #{agent}"
        # the redirect to /dev/null is to work around a bug in the init script or
        # service, per: https://tickets.puppetlabs.com/browse/RAZOR-247
        on agent, 'service pe-razor-server restart >&/dev/null'

        step "Verify authentication on #{agent}"
        agents.each do |agent|
          text = on(agent, "razor -u http://razor:razor@#{agent}:8080/api").output

          assert_match(/Collections:/, text,
                       'The help information should be displayed')
        end
      end
    end
  rescue => e
    puts "Error: #{e}"
    raise e
  ensure
    step "Restart Razor Service to revert authentication on #{agent}"
    # the redirect to /dev/null is to work around a bug in the init script or
    # service, per: https://tickets.puppetlabs.com/browse/RAZOR-247
    on agent, 'service pe-razor-server restart >&/dev/null'

    step "Verify restart was successful on #{agent}"
    agents.each do |agent|
      text = on(agent, "razor -u http://#{agent}:8080/api").output
      assert_match(/Collections:/, text,
                   'The help information should be displayed again')
    end
  end
end