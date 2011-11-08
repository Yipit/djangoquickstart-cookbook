action :add do
  
  repo = new_resource.repo
  branch = new_resource.branch
  app_name = new_resource.app_name
  env_root = new_resource.env_root
  
  env_name = "#{app_name}-env"
  project_home = "#{env_root}/#{env_name}"
  
  # Give ownership of the directory that houses the virtualenv to the ubuntu user
  
  directory "#{env_root}" do
       owner "ubuntu"
       group "ubuntu"
       mode 0775
  end
  
  # Create the virtualenv
  
  python_virtualenv "#{project_home}" do
    owner "ubuntu"
    group "ubuntu"
    interpreter "python2.7"
    action :create
  end
  
  # clone the repo
  
  repo_address = "https://github.com/#{repo}.git"
  
  execute "git_clone" do
    command "git clone #{repo_address} #{app_name} -b #{new_resource.branch}"
    user "ubuntu"
    cwd project_home
  end
  
  # install the external apps
  # I'm not using the opscode cookbook because there's a bug
  # around installing libraries with c extensions in virtualenvs
  
  execute "#{project_home}/bin/pip install -r conf/external_apps.txt" do
    user "ubuntu"
    cwd "#{project_home}/#{app_name}"
  end
  
end
