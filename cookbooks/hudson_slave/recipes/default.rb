#
# Cookbook Name:: hudson_slave
# Recipe:: default
#

# TODO
# * Announce slave to the master node (hard coded for now)
# * Customise the build steps for the app based on the "migrate" field of the app in the instance (usually "rake db:migrate")
# * Add account name to labels (currently not available in the dna.json though)
# * Should we use internal EC2 hostnames?
# * Only add the slaves and nodes if they aren't already on the master

# Config - move to attributes
node[:hudson] ||= Hash.new
node[:hudson][:master] ||= Hash.new
node[:hudson][:master][:host] = "ec2-174-129-24-134.compute-1.amazonaws.com"
node[:hudson][:master][:port] = 80
node[:hudson][:gem] ||= Hash.new
node[:hudson][:gem][:install] = "hudson --pre"
node[:hudson][:gem][:version] = "hudson-0.3.0.beta.6"

env_name = node[:environment][:name]

if ['solo','app_master'].include?(node[:instance_role]) && env_name =~ /_(ci|hudson_slave)$/
  # gem_package "hudson" do
  #   source "http://gemcutter.org"
  #   version "0.3.0.beta.3"
  #   action :install
  # end
  
  execute "install_hudson_in_resin" do
    command "/usr/local/ey_resin/ruby/bin/gem install #{node[:hudson][:gem][:install]}"
    not_if { FileTest.directory?("/usr/local/ey_resin/ruby/gems/1.8/gems/#{node[:hudson][:gem][:version]}") }
  end
  
  ruby_block "add-slave-to-master" do
    block do
      Gem.clear_paths
      require "hudson"
      require "hudson/config"

      Hudson::Api.setup_base_url(node[:hudson][:master])
      
      # Tell master about this slave
      Hudson::Api.add_node(
        :name        => env_name,
        :description => "Automatically added by Engine Yard AppCloud for environment #{env_name}",
        :slave_host  => node[:engineyard][:environment][:instances].first[:public_hostname],
        :slave_user  => node[:users].first[:username],
        :executors   => [node[:applications].size, 1].max,
        :label       => node[:applications].keys.join(" ")
      )
    end
    action :create
  end

  # ey_cloud_report "hudson-slave-setup" do
  #   message "Added instance to Hudson CI server"
  # end
  
  ruby_block "tell-master-about-job" do
    block do
      node[:hudson][:applications] ||= []

      # Tell server about each application
      node[:applications].each do |app_name, data|

        job_type = data['type'] # TODO rack, rails3, etc?
        job_config = Hudson::JobConfigBuilder.new(:rails) do |c|
          c.scm           = data[:repository_name]
          c.assigned_node = app_name
        end

        if Hudson::Api.create_job(app_name, job_config, :override => true)
          build_url = "#{Hudson::Api.base_uri}/job/#{app_name}/build"
          node[:hudson][:applications] << { :name => app_name, :success => true, :build_url => build_url }
        else
          node[:hudson][:applications] << { :name => app_name, :success => false }
        end
      end
    end
    action :create
  end

  # ey_cloud_report "hudson-jobs-setup" do
  #   node[:hudson][:applications].each do |app|
  #     message "Setup build trigger to #{app[:build_url]}"
  #   end
  # end

end