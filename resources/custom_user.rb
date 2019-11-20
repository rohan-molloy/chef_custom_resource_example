resource_name :custom_user
default_action :add
property :custom_username, String, name_property: true

action :add do
  user 'create-the-user' do
    username new_resource.custom_username
    action :create
  end
end

action :del do
  user 'remove-the-user' do
    username new_resource.custom_username
    action :remove
  end
end
