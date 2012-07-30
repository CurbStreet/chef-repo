# start a upgrade
execute "apt-get update"
execute "apt-get upgrade -y"

# set node name as the hostname
file '/etc/hostname' do
  content "#{node.name}\n"
end

#restart hostname service
service 'hostname' do
  action [:restart]
end

# setup ntp service
package 'ntp' do
  action [:install]
end