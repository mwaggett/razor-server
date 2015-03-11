step "Install PE Razor Server"
  razor_hosts = get_razor_hosts
  razor_hosts.each do |host|
    install_pe_razor_server host
  end
