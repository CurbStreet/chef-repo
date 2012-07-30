# set node name as the hostname
execute "hostname #{node.name}"
file '/etc/hostname' do
  content "#{node.name}\n"
end

# start a upgrade
execute "apt-get update"
execute "apt-get upgrade -y"

# setup ntp service
package 'ntp' do
  action [:install]
end