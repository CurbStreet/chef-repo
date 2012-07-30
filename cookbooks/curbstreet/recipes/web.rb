# setup rvm
include_recipe "rvm::user"

# create .ssh directory for deployer
directory "/home/deployer/.ssh" do
  owner "deployer"
  group "deployer"
  mode  "0700"
end

# copy id_deploy
cookbook_file "/home/deployer/.ssh/id_rsa" do
  source "id_deploy"
  mode "0600"
end

# copy id_deploy.pub
cookbook_file "/home/deployer/.ssh/id_rsa.pub" do
  source "id_deploy.pub"
  mode "0622"
end

# deploy project
git "/home/deployer/curbstreet" do
  repository  "git@github.com:CurbStreet/curbstreet.rb.git"
  reference   "master"
  enable_submodules true
  action      :sync
  user        "deployer"
  group       "deployer"
end