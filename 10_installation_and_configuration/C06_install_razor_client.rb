# -*- encoding: utf-8 -*-
confine :to, :platform => 'el-6-x86_64'
confine :except, :roles => %w{master dashboard database frictionless}

test_name 'Install Razor Client'
step 'https://testrail.ops.puppetlabs.net/index.php?/cases/view/6'

step 'Install the Razor client'
on agents, 'gem install pe-razor-client'

step 'Print Razor help, and check for JSON warning'
agents.each do |agent|
  text = on(agent, "razor -u http://#{agent}:8080/api").output

  assert_match(/Usage: razor \[FLAGS\] NAVIGATION/, text,
    'The help information should be displayed')

  warning = Regexp.new(Regexp.escape('[WARNING] MultiJson is using the default adapter (ok_json).We recommend loading a different JSON library to improve performance.'))
  assert_match(warning, text, 'A warning should be displayed complaining about JSON')
end

step "install json_pure"
on agents, 'gem install json_pure'

step "verify JSON warning is gone"
agents.each do |agent|
  text = on(agent, "razor -u http://#{agent}:8080/api").output

  assert_match(/Usage: razor \[FLAGS\] NAVIGATION/, text,
    'The help information should be displayed')

  # Try a bunch of different things to try and be confident that changes in
  # error formatting don't cause us grief tomorrow.
  warning = Regexp.new(Regexp.escape('[WARNING] MultiJson is using the default adapter (ok_json).We recommend loading a different JSON library to improve performance.'))
  assert_no_match warning, text, 'The JSON warning should not be present any longer'
  assert_no_match /ok_json/, text, 'The JSON warning should not be present any longer'
  assert_no_match /MultiJson/, text, 'The JSON warning should not be present any longer'
end

