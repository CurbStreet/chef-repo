# set node name as the hostname
hostname = node.name.gsub '_', '-'

execute "hostname #{hostname}"
file '/etc/hostname' do
  content "#{hostname}\n"
end

# start a upgrade
execute "apt-get update"
execute "apt-get upgrade -y"

# setup ntp service
package 'ntp' do
  action :install
end

# install additional packages needed
package 'build-essential' do
  action :install
end

users_manage "sysadmin" do
  group_id 2300
  action [ :remove, :create ]
end

users_manage "deployer" do
  group_id 2400
  action [ :remove, :create ]
end