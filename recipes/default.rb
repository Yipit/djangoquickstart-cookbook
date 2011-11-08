#
# Cookbook Name:: yipit
# Recipe:: default
#
# Copyright 2011, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#


# Calculate some locations based on set attributes

node.env_name = "#{node.app_name}-env"
node.project_home = "#{node.env_root}/#{node.env_name}"
node.app_home = "#{node.project_home}/#{node.app_name}"

# Install some packages

['binutils', 'chkconfig', 'libcurl4-gnutls-dev', 'libxslt1-dev',
'ntp','python-dev','python-virtualenv', 'python-setuptools', 'rubygems', 'vim', 'git'].each do |pkg|
      package pkg do
          :install
      end
end

# Supervisor installation has a bug, so we need to 
# install elementtree before we can install supervisor

python_pip "elementtree" do
  action :install
end

package "supervisor" do
    action :install
end

# Set up a command to update supervisor on config 
# changes, but don't actually do anything now

execute "supervisor update" do
  command "sudo supervisorctl reread && sudo supervisorctl update"
  action :nothing
end

# This gives us a nicely colored prompt that we can use
# to indicate different environments. It also gives 
# us some more info about the machin on the command line

template "/home/ubuntu/.bashrc" do
  source "bashrc.erb"
  mode 0644
  owner "ubuntu"
  group "ubuntu"
  variables(
    :role => node.name,
    :instance_id => node.ec2.instance_id,
    :prompt_color => node.prompt_color)
end

# To see exactly what this does, checkout provieders/build_repo.rb
# This only runs if the project home directory doesn't exist yet
djangoquickstart_build_repo node.branch do
  action :add
  settings node.settings
  repo node.repo
  app_name node.app_name
  env_root node.env_root
  not_if { File.directory? node.project_home }
end

package "nginx" do
    :install
end

# Set up nginx sites-enables and retsart on changes

template "/etc/nginx/sites-enabled/default" do
  source "nginx-default.erb"
  owner "root"
  group "root"
  variables(
    :domain => node.site_domain,
    :project_home => node.project_home)
  notifies :restart, "service[nginx]"
end

service 'nginx' do
  supports :restart => true, :reload => true
  action :enable
end

# Set up gunicorn through supervisor and restart on changes

template "/etc/supervisor/conf.d/gunicorn.conf" do
  source "gunicorn.conf.erb"
  owner "root"
  group "root"
  variables(
    :domain => node.site_domain,
    :project_env => node.project_home,
    :settings => "#{node.app_home}/settings/__init__.py",
    :conf => "#{node.app_home}/conf/gunicorn/gunicorn.conf")
  notifies :run, resources(:execute => "supervisor update")
end

