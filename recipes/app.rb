#
# Cookbook Name:: yipit
# Recipe:: default
#
# Copyright 2011, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
['libgeos-3.2.0', 'libmysqlclient-dev', 'git-core', 'mercurial', 'mysql-client', 
'openjdk-6-jdk','postfix', 'python-gdal','python-imaging'].each do |pkg|
      package pkg do
          :install
      end
end

build_repo node.branch do
  action :add
  settings node.settings
  not_if { File.directory? node.project }
end
