web = data_bag_item('apps', 'web')

# setup rvm
node['rvm'] = web['rvm']
include_recipe "rvm::user"
