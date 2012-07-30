# start a upgrade
execute "apt-get update"
execute "apt-get upgrade -y"

# set node name as the hostname
file '/etc/hostname' do
  content "#{node.name}\n"
end

# setup ntp service
package 'ntp' do
  action [:install]
end