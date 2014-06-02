# -*- encoding: utf-8 -*-
confine :to, :platform => 'el-6'
confine :except, :roles => %w{master dashboard database}

test_name 'Stop Razor Service'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/9'

step 'Stop Razor Service'
on agents, 'service pe-razor-server stop'

step 'Verify that the service is not operational'
agents.each do |agent|
  text = on(agent, "razor -u http://#{agent}:8080/api").output

  assert_match(/Could not connect to the server/, text)
end
