case test_config[:pe_razor_server_install_type]
when :package
  step "Set Up PE Razor Sever Development Repo." do
    package_build_version = test_config[:pe_razor_server_package_build_version]
    if package_build_version
      install_puppetlabs_dev_repo master, 'pe-razor-server', package_build_version
    else
      abort("Environment variable PE_RAZOR_SERVER_PACKAGE_BUILD_VERSION require for package install!")
    end
  end
end
