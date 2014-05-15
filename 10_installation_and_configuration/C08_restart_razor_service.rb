# -*- encoding: utf-8 -*-
confine :to, :platform => 'el-6'
confine :except, :roles => %w{master dashboard database}

test_name 'Restart Razor Service'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/8'

step 'Restart Razor Service'
# the redirect to /dev/null is to work around a bug in the init script or
# service, per: https://tickets.puppetlabs.com/browse/RAZOR-247
on agents, 'service pe-razor-server restart >&/dev/null'

step 'Verify restart was successful'
agents.each do |agent|
  text = on(agent, "razor -u http://#{agent}:8080/api").output

  assert_match(/Usage: razor \[FLAGS\] NAVIGATION/, text,
    'The help information should be displayed')
end
