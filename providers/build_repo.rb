action :add do
  
  repo = new_resource.repo
  branch = new_resource.branch
  app_name = new_resource.app_name
  env_root = new_resource.env_root
  
  env_name = "#{app_name}-env"
  project_home = "#{env_root}/#{env_name}"
  
  puts "#{env_root}"
  puts "#{app_name}-env"
  
  
  directory "#{env_root}" do
       owner "ubuntu"
       group "ubuntu"
       mode 0775
  end
  
  python_virtualenv "#{project_home}" do
    owner "ubuntu"
    group "ubuntu"
    interpreter "python2.7"
    action :create
  end
  
  repo_address = "https://github.com/#{repo}.git"
  
  execute "git_clone" do
    command "git clone #{repo_address} #{app_name} -b #{new_resource.branch}"
    user "ubuntu"
    cwd project_home
  end
  
  execute "#{project_home}/bin/pip install -r conf/external_apps.txt" do
    user "ubuntu"
    cwd "#{project_home}/#{app_name}"
  end
  
end
