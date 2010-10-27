#
# Cookbook Name:: hudson_slave
# Recipe:: default
#

# TODO
# * Fix installation of 'hudson --pre' gem
# * Announce slave to the master node (hard coded for now)
# * Add an job to the master for each app on this slave, and limit them to run on this slave
# * Customise the build steps for the app based on the "migrate" field of the app in the instance (usually "rake db:migrate")
# * Add account name to labels (currently not available in the dna.json though)
# * Should we use internal EC2 hostnames?
# * Only add the slaves and nodes if they aren't already on the master

# Config
master_hostname = "ec2-184-73-167-68.compute-1.amazonaws.com"

env_name = node[:engineyard][:environment][:name]

if ['solo','app_master'].include?(node[:instance_role]) && env_name =~ /_(ci|hudson_slave)$/
  # Dependencies

  gem_package "hudson" do
    source "http://gemcutter.org"
    version "0.3.0.beta.2"
    action :install
  end
  
  execute "install_hudson_in_resin" do
    command "/usr/local/ey_resin/ruby/bin/gem install hudson -v 0.3.0.beta.2"
    not_if { FileTest.directory?("/usr/local/ey_resin/ruby/gems/1.8/gems/hudson-0.3.0.beta.2") }
  end
  
  ruby_block "add-slave-to-master" do
    block do
      Gem.clear_paths
      require "hudson"

      # Tell server about this slave
      Hudson::Api.add_node(
        :name        => node[:environment][:name],
        :description => "Automatically added by Engine Yard AppCloud for environment #{node[:environment][:name]}",
        :slave_host  => node[:engineyard][:environment][:instances].first[:public_hostname],
        :slave_user  => node[:engineyard][:environment][:ssh_username],
        :executors   => [node[:engineyard][:engineyard][:apps].size, 1].max,
        :label       => node[:engineyard][:engineyard][:apps] * " "
      )
    end
    action :create
  end
  
  ruby_block "tell-master-about-job" do
    block do
      # Tell server about each application
      node[:applications].each do |application, data|
        # We need the app name and the git repo, at minimum

        Hudson::Api.create_job(application, config)
      end
    end
    action :create
  end
end