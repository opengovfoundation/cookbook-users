#
# Cookbook Name:: opengov-users
# Recipe:: default
#

# Setup users and groups.

# The `users` cookbook doesn't play nice with `chef-vault` so we have to do a
# these things manually.

# This expects a chef-vault data bag named 'users' to exist.  Each item in the
# data bag should represent a user, named with the user's name.  The contents of
# this item should look like:
#
# {
#   "password": "Your hashed password",
#   "ssh_keys": [
#     "Your public keys"
#   ],
#   "shell": "/bin/bash",
#   "comment": "Bill Hunt"
# }

include_recipe 'chef-vault::default'

# Create a list of the users. Apparently you can't just iterate over the data
# bag's contents directly.
server_users = data_bag('users').select do |key|
  !key.end_with?('_keys')
end

# We create a default staff group that all users belong to. We use this group
# for apache as well, so we can edit files written by the  webserver.
group 'staff' do
  action :create
end

# Keep a list of all ssh keys for our deploy user later.
deploy_ssh_keys = []

# Function for creating users and their SSH keys.
def create_user(user_name, full_user)

  # Create the user's account.
  user user_name do
    comment full_user['comment']
    password full_user['password']
    shell full_user['shell']
    group 'staff'
    home "/home/#{user_name}"
  end

  # Create the user's home directory if it doesn't exist.
  # This is necessary on Ubuntu and some other distros.
  directory "/home/#{user_name}" do
    owner user_name
    group 'staff'
    mode '0755'
    action :create
  end

  # Create the ssh directory.
  directory "/home/#{user_name}/.ssh" do
    owner user_name
    group 'staff'
    mode '0755'
    action :create
  end

  # Add our public key to the user's authorized keys.
  file "/home/#{user_name}/.ssh/authorized_keys" do
    content full_user['ssh_keys'].join("\n")
    mode '0644'
    owner user_name
    group 'staff'
  end
end

# Loop over our users.
server_users.each do |user_name|
  # Get the users' real data from the vault.
  full_user = chef_vault_item('users', user_name)

  create_user(user_name, full_user)

  # Add our ssh keys to the list for our deploy user.
  deploy_ssh_keys.concat(full_user['ssh_keys']);
end

# Create our deploy user.
deploy_user = {
  'comment' => 'Deploy User',
  'password' => nil,
  'shell' => '/bin/bash',
  'ssh_keys' => deploy_ssh_keys
}

create_user('deploy', deploy_user)

# Create sysadmin group. Add our users to it.
group 'sysadmin' do
  action :create
  members server_users
end

# The sudo recipe gives privileges to sysadmin group by default.
include_recipe "sudo"
