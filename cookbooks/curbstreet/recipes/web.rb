require 'yaml'

# variables
env           = 'stage'
app_name      = 'curbstreet'
deploy_user   = 'deployer'
deploy_group  = 'deployer'

home_dir      = "/home/#{deploy_user}"
app_dir       = "#{home_dir}/#{app_name}"
gemset_name   = "#{node['rvm']['user_default_ruby']}@#{app_name}"

permissions_setup = Proc.new do |resource|
  resource.owner deploy_user
  resource.group deploy_group
  resource.mode 0755
end

#
# setup rvm
#
include_recipe "rvm::user"

# create gemset
rvm_gemset gemset_name do
  action      :create
  user        deploy_user
end

#
# setup nvm
#
directory "#{home_dir}/.nvm" do
  permissions_setup.call self
end

# add nvm.sh
cookbook_file "#{home_dir}/.nvm/nvm.sh" do
  permissions_setup.call(self)
end

# install node
node['nodejs']['versions'].each do |version|
  bash "installing node version #{version}" do
    creates "#{home_dir}/.nvm/#{version}"
    user    deploy_user
    group   deploy_group
    cwd     home_dir
    environment 'HOME' => home_dir
    code    <<-EOF
    source #{home_dir}/.nvm/nvm.sh
    nvm install v#{version}
    EOF
  end
end

#
# Deployment
#

# create default alias
bash "make the default node" do
  user    deploy_user
  group   deploy_group
  cwd     home_dir
  environment 'HOME' => home_dir
  code    <<-EOF
  source #{home_dir}/.nvm/nvm.sh
  nvm alias default v#{node['nodejs']['default']}
  EOF
end

# install global packages
node['nodejs']['global_packages'].each do |pkg|
  bash "install global node packages" do
    user    deploy_user
    group   deploy_group
    cwd     home_dir
    environment 'HOME' => home_dir
    code    <<-EOF
    source #{home_dir}/.nvm/nvm.sh
    npm install -g #{pkg}
    EOF
  end
end

# create application directory
directory "#{home_dir}/.ssh" do
  permissions_setup.call self
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
  permissions_setup.call self
end

# create shared directory
directory "#{app_dir}/shared" do
  permissions_setup.call self
end

# create a wrapper object
template "#{app_dir}/shared/ssh_wrapper.sh" do
  permissions_setup.call self

  source "ssh_wrapper.sh.erb"
  variables({
    :deploy_key_path => "#{home_dir}/.ssh/id_deploy"
  })
end

node['unicorn']['user'] = deploy_user
node['unicorn']['group'] = deploy_group
node['unicorn']['working_directory'] = "#{app_dir}/current"

# create unicorn config
template "#{app_dir}/shared/unicorn.conf.rb" do
  permissions_setup.call self

  source "unicorn.conf.rb.erb"
  variables node['unicorn']
end

# create config directory
directory "#{app_dir}/shared/config" do
  permissions_setup.call self
end

configs = data_bag("configs")

configs.each do |config|
  data    = data_bag_item('configs', config)
  tmp     = {}
  tmp[env]= data[env]
  data    = tmp

  file "#{app_dir}/shared/config/#{config}.yml" do
    owner deploy_user
    group deploy_group
    mode  "0640"
    content data.to_yaml
  end
end

directory "#{app_dir}/shared/log" do
  permissions_setup.call self
end

directory "#{app_dir}/shared/pids" do
  permissions_setup.call self
end

directory "#{app_dir}/shared/system" do
  permissions_setup.call self
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

  before_migrate do
    # run bundle install
    rvm_shell 'bundle install' do
      ruby_string gemset_name
      user        deploy_user
      group       deploy_group
      cwd         "#{app_dir}/current"
      code        "bundle install"
    end
  end

  before_restart do
    # build javascript and css
    bash "compile asssets" do
      user    deploy_user
      group   deploy_group
      cwd     "#{app_dir}/current"
      environment 'HOME' => home_dir
      code    <<-EOF
      source #{home_dir}/.nvm/nvm.sh
      cake build
      EOF
    end
  end

  restart_command do
    # run unicorn
    rvm_shell 'unicorn' do
      ruby_string gemset_name
      user        deploy_user
      group       deploy_group
      cwd         "#{app_dir}/current"
      code        <<-EOF
      kill -QUIT $(cat #{app_dir}/current/#{node['unicorn']['pid']})
      bundle exec unicorn -D -E #{env} -c #{app_dir}/shared/unicorn.conf.rb
      EOF
    end
  end
end


# setup reverse proxy
include_recipe "nginx::default"

template "#{node[:nginx][:dir]}/sites-available/#{app_name}.conf" do
  source "nginx_proxy.conf.erb"
  owner   "root"
  group   "root"
  mode    "0664"
  notifies :restart, "service[nginx]"
  variables({
    :app_name     => app_name,
    :doc_dir      => "#{app_dir}/current/public",
    :domain_name  => node['domain_name']
  })
end

nginx_site "#{app_name}.conf"