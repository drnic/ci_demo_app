#
# Cookbook Name:: hudson
# Recipe:: default
#

# Using manual hudson for now not hudson gem. No ebuild seems to exist.
# Based on http://bit.ly/9Y852l

# You can use this in combination with http://github.com/bjeanes/ey_hudson_proxy
# to serve hudson publicly on a Hudson-only EY instance. This is so you don't have to
# find a simple app to run on the instance in lieu of an actual staging/production site.
# Alternatively, set up nginx asa reverse proxy manually.

# We'll assume running hudson under the default username
hudson_user = node[:users].first[:username]
hudson_port = 8082 # change this in your proxy if modified
hudson_home = "/data/hudson-ci"
hudson_pid  = "#{hudson_home}/tmp/pid"
plugins     = %w[git github rake ruby greenballs]

%w[logs tmp war plugins .].each do |dir|
  directory "#{hudson_home}/#{dir}" do
    owner hudson_user
    group hudson_user
    mode  0755 unless dir == "war"
    action :create
    recursive true
  end
end

remote_file "#{hudson_home}/hudson.war" do
  source "http://hudson-ci.org/latest/hudson.war"
  owner hudson_user
  group hudson_user
  not_if { FileTest.exists?("#{hudson_home}/hudson.war") }
end

template "/etc/init.d/hudson" do
  source "init.sh.erb"
  owner "root"
  group "root"
  mode 0755
  variables(
    :user => hudson_user,
    :port => hudson_port,
    :home => hudson_home,
    :pid  => hudson_pid
  )
  not_if { FileTest.exists?("/etc/init.d/hudson") }
end

plugins.each do |plugin|
  remote_file "#{hudson_home}/plugins/#{plugin}.hpi" do
    source "http://hudson-ci.org/latest/#{plugin}.hpi"
    owner hudson_user
    group hudson_user
    not_if { FileTest.exists?("#{hudson_home}/plugins/#{plugin}.hpi") }
  end

end

template "/data/nginx/servers/hudson_reverse_proxy.conf" do
  source "proxy.conf.erb"
  owner hudson_user
  group hudson_user
  mode 0644
  variables(
    :port => hudson_port
  )
  not_if { FileTest.exists?("/data/nginx/servers/hudson_reverse_proxy.conf") }
end

execute "ensure-hudson-is-running" do
  command "/etc/init.d/hudson restart"
end

execute "Restart nginx" do
  command "/etc/init.d/nginx restart"
end
