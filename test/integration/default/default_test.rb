# InSpec test for recipe custom_resource_example::default

# The InSpec reference, with examples and extensive documentation, can be
# found at https://www.inspec.io/docs/reference/resources/

describe user('bob') do
  it { should_not exist }
end

describe user('alice') do
  it { should exist }
end