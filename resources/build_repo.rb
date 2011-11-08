actions :add

attribute :settings, :kind_of => String
attribute :branch, :kind_of => String, :name_attribute => true
attribute :repo, :kind_of => String
attribute :app_name, :kind_of => String
attribute :env_root, :kind_of => String