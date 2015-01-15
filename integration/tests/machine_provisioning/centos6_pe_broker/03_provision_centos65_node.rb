require 'master_manipulator'
require 'razor_integration'
test_name 'C95 - Deploy Operating System to Node with Razor'

#Checks to make sure environment is capable of running tests.
razor_config?
pe_version_check(master, 3.7, :fail)

#Init
master_certname = on(master, puppet('config', 'print', 'certname')).stdout.rstrip
environment_base_path = on(master, puppet('config', 'print', 'environmentpath')).stdout.rstrip
prod_env_path = File.join(environment_base_path, 'production')
prod_env_modules_path = File.join(prod_env_path, 'modules')
prod_env_site_pp_path = File.join(prod_env_path, 'manifests', 'site.pp')

auth_keys_module_files_path = File.join(prod_env_modules_path, 'auth_keys', 'files')

razor_server = find_only_one(:razor_server)
razor_node = find_only_one(:razor_node)
razor_node_hostname = fact_on(razor_node, 'hostname')
ssh_auth_keys = get_ssh_auth_keys(razor_node)

#Manifests
local_manifests_root_path = ENV['MANIFESTS'] || 'manifests'
razor_node_manifest = File.read(File.join(local_manifests_root_path, 'razor_node.pp'))

#Verification
verify_cert_command = "cert list | grep '#{razor_node_hostname}'"

#Setup
step 'Write SSH Authorize Keys File to Master'
on(master, "mkdir -p #{auth_keys_module_files_path}")
create_remote_file(master, "#{auth_keys_module_files_path}/authorized_keys", ssh_auth_keys)
on(master, "chmod -R 755 #{auth_keys_module_files_path}")

step 'Update "site.pp" for "production" Environment'
inject_site_pp(master, prod_env_site_pp_path, create_site_pp(master_certname, razor_node_manifest))

#Test
step 'Reboot Razor Node to Begin Provisioning'
on(razor_node, 'shutdown -r 1 &')

step 'Wait for Provisioning to Finish'
sleep(361)

step 'Verify that Node Registered with Puppet Master'
retry_on(master, puppet(verify_cert_command), :max_retries => 24, :retry_interval => 10)

step 'Sign Cert for Razor Node'
on(master, puppet('cert sign --all'))

step 'Ping Razor Node'
retry_on(master, "ping -c 4 #{razor_node_hostname}", :max_retries => 24, :retry_interval => 10)

step 'Manually Kick Off Puppet Run on Razor Node'
ssh_with_password(razor_node_hostname, 'root', 'puppet', 'puppet agent -t', exit_codes = [2])

step 'Verify that Razor Node is Fully Operational'
on(razor_node, 'cat /var/log/razor.log')
