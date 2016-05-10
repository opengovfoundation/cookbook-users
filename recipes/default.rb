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
serverUsers = data_bag('users').select do |key|
  !key.end_with?('_keys')
end

# We create a default staff group that all users belong to. We use this group
# for apache as well, so we can edit files written by the  webserver.
group 'staff' do
  action :create
end

# Keep a list of all ssh keys for our deploy user later.
deploySshKeys = []

# Loop over our users.
serverUsers.each do |userName|
  # Get the users' real data from the vault.
  fullUser = chef_vault_item('users', userName)

  # Create the user's account.
  user userName do
    comment   fullUser['comment']
    password  fullUser['password']
    shell     fullUser['shell']
    group     'staff'
    home      "/home/#{userName}"
  end

  # Create the ssh directory.
  directory "/home/#{userName}/.ssh" do
    owner  userName
    group  'staff'
    mode   '0755'
    action :create
  end

  # Add our public key to the user's authorized keys.
  file "/home/#{userName}/.ssh/authorized_keys" do
    content fullUser['ssh_keys'].join("\n")
    mode    '0644'
    owner   userName
    group   'staff'
  end

  # Add our ssh keys to the list for our deploy user.
  deploySshKeys.concat(fullUser['ssh_keys']);
end

# Create our deploy user
user 'deploy' do
  comment 'Deploy User'
  shell   '/bin/bash'
  group   'staff'
  home    '/home/deploy'
end

# Give all of our users access to the deploy user.
file "/home/deploy/.ssh/authorized_keys" do
  content deploySshKeys.join("\n")
  mode    '0644'
  owner   'deploy'
  group   'staff'
end

# Create sysadmin group. Add our users to it.
group 'sysadmin' do
  action  :create
  members serverUsers
end

# The sudo recipe gives privileges to sysadmin group by default.
include_recipe "sudo"
