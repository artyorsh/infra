# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"
  config.vm.box_check_update = false
  config.vm.synced_folder ".", "/vagrant", disabled: true
  
  # App ports
  config.vm.network :forwarded_port, host: 51821, guest: 51821
  config.vm.network :forwarded_port, host: 3600, guest: 3600
  config.vm.network :forwarded_port, host: 3601, guest: 3601

  config.ssh.insert_key = false

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048
    vb.linked_clone = true
  end
end
