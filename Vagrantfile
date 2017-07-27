# -*- mode: ruby -*-
# vi: set ft=ruby :

iprange = "192.168.1"
domain = "shibusa.io"
vboxversion = "5.1.24"

Vagrant.require_version ">= 1.9.7"
Vagrant.configure("2") do |config|
  # Vagrant ssh private key
  config.ssh.private_key_path = ["~/.ssh/id_rsa", "~/.vagrant.d/insecure_private_key"]
  config.ssh.insert_key = false

  # PostgreSQL DB
  postgresqlip = 30
  config.vm.define "postgresqlnode" do |postgresql|
    postgresql.vm.box = "centos/7"
    postgresql.vm.hostname = "postgresql.#{domain}"
    postgresql.vm.network "public_network", bridge: "en0: Wi-Fi (AirPort)", ip: "#{iprange}.#{postgresqlip}"
    postgresql.vm.provision "file", source: "~/.ssh/id_rsa.pub", destination: "~/.ssh/authorized_keys"
    postgresql.vm.provision :shell, path: "init.sh"
    postgresql.vm.provision :shell, path: "postgresql.sh"
    postgresql.vm.provision :shell, path: "appdb.sh"
  end

  # webapp nodes
  webappservs = 3
  webappipstart = 20
  (1..webappservs).each do |i|
    config.vm.define "webappnode-#{i}" do |webappnode|
      webappnode.vm.box = "centos/7"
      webappnode.vm.hostname = "webappnode-#{i}.#{domain}"
      webappnode.vm.network "public_network", bridge: "en0: Wi-Fi (AirPort)", ip: "#{iprange}.#{webappipstart + i}"
      webappnode.vm.provision "file", source: "~/.ssh/id_rsa.pub", destination: "~/.ssh/authorized_keys"
      webappnode.vm.provision :shell, path: "init.sh"
      webappnode.vm.provision :shell, path: "appproj.sh"
    end
  end

  # nginx load balancer
  nginxip = 10
  config.vm.define "nginxnode" do |nginx|
    nginx.vm.box = "centos/7"
    nginx.vm.hostname = "nginx.#{domain}"
    nginx.vm.network "public_network", bridge: "en0: Wi-Fi (AirPort)", ip: "#{iprange}.#{nginxip}"
    nginx.vm.provision "file", source: "~/.ssh/id_rsa.pub", destination: "~/.ssh/authorized_keys"
    nginx.vm.provision :shell, path: "init.sh"
    nginx.vm.provision :shell, path: "nginx.sh"
    nginx.vm.provision :shell, path: "apphttp.sh"
  end
end
