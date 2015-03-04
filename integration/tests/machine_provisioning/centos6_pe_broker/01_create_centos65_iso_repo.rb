require 'razor_integration'
test_name 'C56 - Create a Razor Repo from an ISO URL (CentOS 6.5)'

#Checks to make sure environment is capable of running tests.
razor_config?
pe_version_check(master, 3.7, :fail)

#Init
razor_server = find_only_one(:razor_server)
iso_url = 'http://int-resources.ops.puppetlabs.net/ISO/CentOS/CentOS-6.5-x86_64/CentOS-6.5-x86_64-minimal.iso'
repo_name = 'centos65'
task = 'centos'
create_iso_repo_command = "razor create-repo --name=#{repo_name} --iso-url=#{iso_url} --task=#{task}"

#Verification
verify_repo_name_regex = /name: #{repo_name}/
verify_repo_url_regex = /iso_url: #{iso_url}/
verify_repo_task_regex = /task: #{task}/
verify_repo_command = 'razor repos centos65'

step 'Create Repo and Verify'
on(razor_server, create_iso_repo_command) do |result|
  assert_match(verify_repo_name_regex, result.stdout, 'Broker incorrectly configured!')
  assert_match(verify_repo_url_regex, result.stdout, 'Broker incorrectly configured!')
  assert_match(verify_repo_task_regex, result.stdout, 'Broker incorrectly configured!')
end

step 'Sleep a Bit While ISO is Downloaded and Unpacked'
sleep(90)

step 'Verify Repo via Collection Lookup'
on(razor_server, verify_repo_command) do |result|
  assert_match(verify_repo_name_regex, result.stdout, 'Broker incorrectly configured!')
  assert_match(verify_repo_url_regex, result.stdout, 'Broker incorrectly configured!')
  assert_match(verify_repo_task_regex, result.stdout, 'Broker incorrectly configured!')
end
