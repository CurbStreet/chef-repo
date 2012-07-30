require 'yaml'

#
# setup rvm
#
include_recipe "rvm::user"


#
# Deployment
#

# variables
env           = 'stage'
app_name      = 'curbstreet'
deploy_user   = 'deployer'
deploy_group  = 'deployer'

home_dir  = "/home/#{deployer}"
app_dir   = "#{home_dir}/#{app_name}"

# create application directory
directory "#{home_dir}/.ssh" do
  owner deploy_user
  group deploy_group
  mode  "0700"
end

# copy id_deploy
cookbook_file "#{home_dir}/.ssh/id_deploy" do
  owner deploy_user
  group deploy_group
  source "id_deploy"
  mode "0600"
end

# create application directory
directory app_dir do
  owner deploy_user
  group deploy_group
  mode  "0755"
end

# create shared directory
directory "#{app_dir}/shared" do
  owner deploy_user
  group deploy_group
  mode  "0755"
end

# create a wrapper object
template "#{app_dir}/shared/ssh_wrapper.sh" do
  owner deploy_user
  group deploy_group
  source "ssh_wrapper.sh.erb"
  mode 0755
  variables({
    :deploy_key_path => "#{home_dir}/.ssh/id_deploy"
  })
end

# create config directory
directory "#{app_dir}/shared/config" do
  owner deploy_user
  group deploy_group
  mode  "0755"
end

configs = data_bag("configs")

configs.each do |config|
  data    = data_bag_item('configs', config)
  config  = config[env]
  data    = {}
  data[env] = config

  file "#{app_dir}/shared/config/#{config}" do
    owner deploy_user
    group deploy_group
    mode  "0640"
    content data.to_yaml
  end
end

# deploy project
deploy "#{app_dir}" do
  action              :deploy
  repo                node[app_name]['repository']
  revision            node[app_name]['revision']
  symlink_before_migrate node[app_name]['config_files_to_symlink']
  user                deploy_user
  enable_submodules   true
  environment         node[app_name]['environment']
  migrate             false
  git_ssh_wrapper     "#{app_dir}/shared/ssh_wrapper.sh"
  scm_provider        Chef::Provider::Git
end