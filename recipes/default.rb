#
# Cookbook:: custom_resource_example
# Recipe:: default
#
# Copyright:: 2019, rohan-molloy, All Rights Reserved.

custom_user 'Creating user bob' do
  custom_username 'bob'
  action :add
end

custom_user 'bob' do
  action :del
end

custom_user 'alice' do
end