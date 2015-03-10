case test_config[:pe_razor_server_install_type]
when :package
  step "Set Up PE Razor Sever Development Repo." do
    package_build_version = test_config[:pe_razor_server_version]
    if package_build_version
      install_dev_repo_on master, 'pe-razor-server', package_build_version, "repo_configs"
    else
      abort("Environment variable PE_RAZOR_SERVER_PACKAGE_BUILD_VERSION require for package install!")
    end
  end
end
