require 'beaker/dsl/install_utils'

module RazorExtensions
  def self.initialize_config(options)

    install_type = get_option_value(options[:pe_razor_server_install_type],
                                    [:package], "Install Type",
                                    "PE_RAZOR_SERVER_INSTALL_TYPE", :package)

    install_mode = get_option_value(options[:pe_razor_server_install_mode],
                                    [:install, :upgrade], "Install Mode",
                                    "PE_RAZOR_SERVER_INSTALL_MODE", :install)

    pe_razor_server_version = get_option_value(options[:pe_razor_server_version],
                                               nil, "PE Razor Server Development Build Version",
                                               "PE_RAZOR_SERVER_PACKAGE_BUILD_VERSION", NIL)
    @config = {
      :pe_razor_server_install_type => install_type,
      :pe_razor_server_install_type => install_mode,
      :pe_razor_server_version => pe_razor_server_version,
    }
  end

  class << self
    attr_reader :config
  end

  def test_config
    RazorExtensions.config
  end

  # This method will create a policy in addition to the dependencies needed for that:
  # - Repo (creation can be bypassed by using :repo_name)
  # - Broker (creation can be bypassed by using :broker_name)
  #
  # [Optional]: This can also create and/or associate a tag.
  # => Tag creation: :create_tag = true
  # => Name/reference: :tag_name
  #
  # :task_name, :broker_type, and :policy_max_count can also be specified to alter the behavior.
  #
  # A block provided to this method will be executed inside the create-policy call, with
  # `agent` and `output` as optional parameters to the block.
  def create_policy(agents, args = {}, &block)
    def has_key_or_default(args, key, default)
      args.has_key?(key) ? args[key] : default
    end
    policy_name = has_key_or_default(args, :policy_name, 'puppet-test-policy')
    # Use :tag_name for reference, :create_tag for creation
    tag_name = has_key_or_default(args, :tag_name, (args[:create_tag] && 'small'))
    repo_name = has_key_or_default(args, :repo_name, "centos-6.4")
    broker_name = has_key_or_default(args, :broker_name, 'noop')
    broker_type = has_key_or_default(args, :broker_type,'noop')
    task_name = has_key_or_default(args, :task_name, "centos")
    max_count = has_key_or_default(args, :policy_max_count, 20)

    unless args[:just_policy]
      razor agents, 'create-tag', {
          "name" => tag_name,
          "rule" => ["=", ["fact", "processorcount"], "2"]
      } if args[:create_tag]
      razor agents, 'create-repo', {
          "name" => repo_name,
          "url"  => 'http://provisioning.example.com/centos-6.4/x86_64/os/',
          "task" => task_name
      } unless args.has_key?(:repo_name)
      razor agents, 'create-broker', {
          "name"        => broker_name,
          "broker-type" => broker_type
      } unless args.has_key?(:broker_name)
    end

    json = {
        'name'          => policy_name,
        'repo'          => repo_name,
        'task'          => task_name,
        'broker'        => broker_name,
        'enabled'       => true,
        'hostname'      => "host${id}.example.com",
        'root-password' => "secret",
        'max-count'     => max_count,
        'tags'          => tag_name.nil? ? [] : [tag_name]
    }
    # Workaround; max-count cannot be nil
    json.delete('max-count') if max_count.nil?

    {policy: {:name => policy_name, :max_count => max_count}, repo_name: repo_name,
        broker: {:broker_name => broker_name, :broker_type => broker_type},
        tag_name: tag_name, task_name: task_name}.tap do |return_hash|
      razor agents, 'create-policy', json do |agent, output|
        step "Verify that the policy is defined on #{agent}"
        text = on(agent, "razor -u https://#{agent}:8151/api policies '#{policy_name}'").output
        assert_match(/#{Regexp.escape(policy_name)}/, text)
        block and case block.arity
          when 0 then yield
          when 1 then yield agent
          when 2 then yield agent, output
          when 3 then yield agent, output, return_hash
          else raise "unexpected arity #{block.arity} for create_policy!"
        end
      end
    end
  end

  def self.get_option_value(value, legal_values, description, env_var_name =
                            nil, default_value = nil)
    value = ((env_var_name && ENV[env_var_name]) || value || default_value)
    if value
      value = value.to_sym
    end
    unless legal_values.nil? or legal_values.include?(value)
      raise ArgumentError, "Unsupported #description  '#{value}'"
    end

    value
  end

  def install_pe_razor_server (host)
    case test_config[:pe_razor_server_install_type]
    when :package
      install_package host, 'pe-razor-server'
    else
      abort("Invalid install type: " +
            test_config[:pe_razor_server_install_type])
    end
  end
end

Beaker::TestCase.send(:include, RazorExtensions)
