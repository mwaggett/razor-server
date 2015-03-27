step "Install PE Razor Server"
  razor_hosts = get_razor_hosts
  razor_hosts.each do |host|
    on host, 'service pe-razor-server stop'
    install_pe_razor_server host
    restart_razor_service(host)
  end
