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
      :pe_razor_server_install_mode => install_mode,
      :pe_razor_server_version => pe_razor_server_version,
    }

    pp_config = PP.pp(@config, "")

    Beaker::Log.notify "Razor Acceptance Configuration:\n\n#{pp_config}\n\n"
  end

  class << self
    attr_reader :config
  end

  def test_config
    RazorExtensions.config
  end

  def self.get_option_value(value, legal_values, description, env_var_name =
                            nil, default_value = nil)
    value = ((env_var_name && ENV[env_var_name]) || value || default_value)
    if value
      value = value.to_sym
    end
    unless legal_values.nil? or legal_values.include?(value)
      raise ArgumentError, "Unsupported #{description} '#{value}'"
    end

    value
  end

  def install_pe_razor_server (host)
    case test_config[:pe_razor_server_install_type]
    when :package
      install_package host, 'pe-razor-server'
    else
      abort("Invalid install type: " + test_config[:pe_razor_server_install_type])
    end
  end

  # Taken from puppet acceptance lib
  def fetch(base_url, file_name, dst_dir)
    FileUtils.makedirs(dst_dir)
    src = "#{base_url}/#{file_name}"
    dst = File.join(dst_dir, file_name)
    if File.exists?(dst)
      logger.notify "Already fetched #{dst}"
    else
      logger.notify "Fetching: #{src}"
      logger.notify "  and saving to #{dst}"
      open(src) do |remote|
        File.open(dst, "w") do |file|
          FileUtils.copy_stream(remote, file)
        end
      end
    end
    return dst
  end

  # Taken from puppet acceptance lib
  # Install development repos
  def install_dev_repo_on(host, package, sha, repo_configs_dir)
    platform = host['platform'] =~ /^(debian|ubuntu)/ ? host['platform'].with_version_codename : host['platform']
    platform_configs_dir = File.join(repo_configs_dir, platform)

    case platform
      when /^(fedora|el|centos)-(\d+)-(.+)$/
        variant = (($1 == 'centos') ? 'el' : $1)
        fedora_prefix = ((variant == 'fedora') ? 'f' : '')
        version = $2
        arch = $3

        #hack for https://tickets.puppetlabs.com/browse/RE-1990
        if host.is_pe?
          pattern = "pl-%s-%s-repos-pe-%s-%s%s-%s.repo"
        else
          pattern = "pl-%s-%s-%s-%s%s-%s.repo"
        end
        repo_filename = pattern % [
            package,
            sha,
            variant,
            fedora_prefix,
            version,
            arch
        ]

        repo = fetch(
            "http://builds.puppetlabs.lan/%s/%s/repo_configs/rpm/" % [package, sha],
            repo_filename,
            platform_configs_dir
        )

        scp_to(host, repo, '/etc/yum.repos.d/')

      when /^(debian|ubuntu)-([^-]+)-(.+)$/
        variant = $1
        version = $2
        arch = $3

        list = fetch(
            "http://builds.puppetlabs.lan/%s/%s/repo_configs/deb/" % [package, sha],
            "pl-%s-%s-%s.list" % [package, sha, version],
            platform_configs_dir
        )

        scp_to host, list, '/etc/apt/sources.list.d'
        on host, 'apt-get update'
      else
        host.logger.notify("No repository installation step for #{platform} yet...")
    end
  end
end

Beaker::TestCase.send(:include, RazorExtensions)
