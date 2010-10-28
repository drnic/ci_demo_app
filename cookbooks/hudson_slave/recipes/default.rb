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

# Config
node[:hudson] ||= Hash.new
node[:hudson][:master] ||= Hash.new
node[:hudson][:master][:host] = "ec2-174-129-24-134.compute-1.amazonaws.com"
node[:hudson][:master][:port] = 80

env_name = node[:engineyard][:environment][:name]

if ['solo','app_master'].include?(node[:instance_role]) && env_name =~ /_(ci|hudson_slave)$/
  # Dependencies

  # gem_package "hudson" do
  #   source "http://gemcutter.org"
  #   version "0.3.0.beta.3"
  #   action :install
  # end
  
  execute "install_hudson_in_resin" do
    command "/usr/local/ey_resin/ruby/bin/gem install hudson --pre"
    not_if { FileTest.directory?("/usr/local/ey_resin/ruby/gems/1.8/gems/hudson-0.3.0.beta.5") }
  end
  
  ruby_block "add-slave-to-master" do
    block do
      Gem.clear_paths
      require "hudson"
      require "hudson/config"

      environment = node[:engineyard][:environment]
      host = environment[:instances].first[:public_hostname]

      Hudson::Api.setup_base_url(node[:hudson][:master])
      
      # Tell master about this slave
      Hudson::Api.add_node(
        :name        => env_name,
        :description => "Automatically added by Engine Yard AppCloud for environment #{env_name}",
        :slave_host  => host,
        :slave_user  => environment[:ssh_username],
        :executors   => [environment[:apps].size, 1].max,
        :label       => environment[:apps].map {|app| app[:name] }.join(" ")
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
      node[:applications].each do |application, data|
        # We need the app name and the git repo, at minimum
        # application => 'name'
        # data => {"auth"=>{"active"=>false}, "newrelic"=>false, "https_bind_port"=>443, "repository_name"=>"git://github.com/drnic/ci_demo_app.git", "type"=>"rack", "migration_command"=>"rake db:migrate", "http_bind_port"=>80, "revision"=>"", "run_deploy"=>false, "branch"=>"HEAD", "deploy_key"=>"-----BEGIN RSA PRIVATE KEY-----\nMIIEoQIBAAKCAQEAtzdpK2nFAs0dwPtXqNyKRtF8iHXBYzfvIHI+779UpcJJgFuk\nhK5F5xLt6FtwzBNUpOUkzEncZFSzD7GlP39nvUtJS0NQkN+ayxVEmgz7KoOAqFmI\nzubQc0E72rDKOAIonwBBDoOeia6kMLyIss8K3c08AJzY2pvGQHdh4vLQnQY9326d\nGydW9g8ExN8XTlG3O2kX5r+uMDkM2Ltd2sJGWg1pGlRJGryoVPp0LskBiE//gAFw\n1dOqnzBhLRTyZcewt+TRdsUr9VgL5O0D5yyuJpDvkdBCAvUPJzTf83M3a8kx62BX\nqVy89Ddvw0lbCX9TxpY+qd2eOQZmJKp+cayKTwIBIwKCAQB9ola+ru1+Q4Id7i17\nGuJ5tDgjDusCNPu+ejnI+DoLQ2WZ2HDQAnkTerHD5u5Cy2093vSpVzgKSLVMlxI6\nK3pV6ntmzxKsfBJfXwp4Q2pmS4tsICNMC/ymzaViwl7HUe/4ACycPP7/Uy7CVWUM\n5b5O8yHUiM820Td8qaI1OMmQPaIxUq8UtfgpDzd4pBkEBSb3VgErVhZ/VUoriWZT\nQRnKgLz0bZ9OdHKMfDghh4dN3VCgiSRi6b0NPMdB5SaF/DnSYryvhpdgziVZDBV+\nBc5EyCSq5e8kW6NtpIf69UCBamq8x846lQXTKdNl2p5PE/1yZk3F48b4OmutmBjg\ngfRLAoGBAN836SZCSnHoagN6Ah9u51SqK6LGPB2/BExDNkbWNmQIdJheuwd0R34b\nt8TUqv+CICLB2vpvCk+MkGbn9XYCu4TlkS1y3RG+EPfLJAh5+1RzN/6URnjnj/MH\nyY7FzvDcCwmkYtoBtFJq/yHDTc8hTCPlFsouqvdcCS7i3DkOC177AoGBANIfl4za\nqNsnGXsQQv4O4t8TNV4WpgT3gwnAsgx1zPIKR70seWP+tgMsYt1+jbIJ98cpXnar\n3ydfUgJaW/mKUazU2PuD7n10xR2il1wVaOI5tRDZpSGxCiMfhgrfqUh9raHzr3Dn\njxdf8KRgx2UKNgjv/5hlRnoIUq+PUHZxjlG9AoGADMFdx6wEQQX3bem2+ntdrREJ\nzsl/xy98lqTBReBa4SUN+hQKr/gEFdWyuspS6gdvjPUidLXjVQC3y122QUH8FjkA\n+0hkZ2nyV01vxfhXgSsnxWeO/5g0HIQaJWpjmLwd40s42UHtDAYdNSEaY5uAsZgP\n7kvPQVW3YcPSEeOLnwcCgYEAihTCrQS4Gvxv1IcHc8CjtynhPdReeErhFQmZkyjX\nIrZMZl8N8UD7Q+n302HK1BUtzAU+E3hCL9Dsv7e4yI4YakK6eWVTlEVrlyGz7A4R\nuTvdYtgqr717sK5QxVEmGbGsnaAi1Spz+Wrul+fTfOlz9z6gpflo09mVbA24iFlA\nRFcCgYBic5h83pTpAWncE2JR50EWYJPOdUk8uHozTCSZ5sSDbaF/YFz4sZqvFhrx\n8PO7uECgjjBhiU0He6B4XEwX3fUcEYdebcAfpP6YYFclIqGxwSxOqObu4c8u7hsg\nHnBh4bIG1XO5olS3DcjXNHnf20xuHKgBj1aDLAW5YxQH6REquA==\n-----END RSA PRIVATE KEY-----\n", "deploy_action"=>"deploy", "run_migrations"=>false, "services"=>[{"resource"=>"mongrel", "mongrel_base_port"=>5000, "mongrel_mem_limit"=>150, "mongrel_instance_count"=>3}, {"resource"=>"memcached", "base_port"=>11211, "mem_limit"=>128}], "recipes"=>["memcached", "monit", "nginx", "mongrel"], "vhosts"=>[{"name"=>"_", "role"=>"ci_demo_app_ci"}]}
        
        job_config = Hudson::JobConfigBuilder.new(:rails) do |c|
          c.scm           = data['repository_name']
          c.assigned_node = application
        end
        puts job_config.to_xml
        if Hudson::Api.create_job(application, job_config, :override => true)
          node[:hudson][:applications] << { :name => application, :build_url => "#{Hudson::Api.base_uri}/job/#{application}/build" }
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