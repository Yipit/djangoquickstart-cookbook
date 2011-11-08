#
# Cookbook Name:: yipit
# Recipe:: default
#
# Copyright 2011, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

['binutils', 'chkconfig', 'libcurl4-gnutls-dev', 'libxslt1-dev',
'ntp','python-dev', 'python-setproctitle','python-virtualenv', 'python-setuptools', 'rubygems', 'vim'].each do |pkg|
      package pkg do
          :install
      end
end

authorized_users = node['authorized_users']
public_keys = data_bag_item('public_keys', 'public_keys')
authorized_keys = public_keys.values_at(*authorized_users)

template "/home/ubuntu/.ssh/authorized_keys" do
  source "authorized_keys.erb"
  mode 0644
  owner "ubuntu"
  group "ubuntu"
  variables(
    :authorized_keys => authorized_keys
  )
  only_if { authorized_keys.any? }
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
    :prompt_color => node.prompt_color,
    :project_directory => node.project)
end

template "/home/ubuntu/.vimrc" do
  source "vimconfig.erb"
  mode 0644
  owner "ubuntu"
  group "ubuntu"
end

template "/etc/rsyslog.d/papertrail.conf" do
  source "papertrail.conf.erb"
  owner "root"
  group "root"
  notifies :restart, "service[rsyslog]"
end

service "rsyslog" do
  supports :restart => true, :reload => true
  action :enable
end

gem_package "remote_syslog"

template "/etc/log_files.yml" do
  source "log_files.yml.erb"
  owner "root"
  group "root"
  variables(:hostname => node.name)
  notifies :run, resources(:execute => "supervisor update")
end

template "/etc/supervisor/conf.d/remote_syslog_supervisor.conf" do
  source "remote_syslog_supervisor.conf.erb"
  owner "root"
  group "root"
  notifies :run, resources(:execute => "supervisor update")
end

include_recipe "mongodb::10gen_repo"

node[:mongodb][:dbpath] = "/var/lib/mongodb"
node[:mongodb][:logpath] = "/var/log/mongodb"
node[:mongodb][:port] = 27017
node[:mongodb][:shard_name] = node.name
node[:mongodb][:sharded_collections] = {'yipit_staging.dealuser'=> 'value.deal_id', 'yipit_staging.email_log'=> 'user_id'}

template "/etc/apt/apt.conf.d/50unattended-upgrades" do
  source "50unattended-upgrades.erb"
  owner "root"
  group "root"
  notifies :run, resources(:execute => "supervisor update")
end

template "/etc/apt/apt.conf.d/02periodic" do
  source "02periodic.erb"
  owner "root"
  group "root"
  notifies :run, resources(:execute => "supervisor update")
end


