#
# Cookbook Name:: yipit
# Recipe:: default
#
# Copyright 2011, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#


node.env_name = "#{node.app_name}-env"
node.project_home = "#{node.env_root}/#{node.env_name}"
node.app_home = "#{node.project_home}/#{node.app_name}"

['binutils', 'chkconfig', 'libcurl4-gnutls-dev', 'libxslt1-dev',
'ntp','python-dev','python-virtualenv', 'python-setuptools', 'rubygems', 'vim', 'git'].each do |pkg|
      package pkg do
          :install
      end
end

python_pip "elementtree" do
  action :install
end

package "supervisor" do
    action :install
end

execute "supervisor update" do
  command "sudo supervisorctl reread && sudo supervisorctl update"
  action :nothing
end

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

