# custom_resource_example

This is an example of creating a custom Chef resource. 
I've aimed to go with the most simple possible example I could think of

- The resource block will be called `custom_user`
- It will have actions `:add` and `:del`
- It will have parameter `custom_username`
- It will be a wrapper to the standard `user` resource 

## 1. Understand Resources   

### 1.1 Grammar  
Recall that Chef resources have the following general grammar

```
<resource_name> <name> do
  <key> <value>
  action :<action>
end
```
On docs.chef.io/resource_user.html, we can see the full syntax of the `user` resource

```
user 'name' do
  comment                    String
  force                      true, false # see description
  gid                        String, Integer
  home                       String
  iterations                 Integer
  manage_home                true, false
  non_unique                 true, false
  password                   String
  salt                       String
  shell                      String
  system                     true, false
  uid                        String, Integer
  username                   String # defaults to 'name' if not specified
  action                     Symbol # defaults to :create if not specified
end
```

### 1.2 Implicit Defaults
The Chef resources often make liberal use of 'syntactic sugar' by including implicit defaults.
This allows clean readable code like this.

```
user 'bob' do
  action :create
end
```
#### 1.2.1 name_parameter
When ever a Chef resource is invoked it is passed a 'name'. 
The name identifies the instance of the resource.

The properties of the resource are defined as *parameters* between the do/end, 
There will be at least one parameter that will default to the 'name' resource if not explicitly set.

So the above statement can be defined equivalently as

```
user 'This text doesn't change anything!' do
  username 'bob'
  action :create
end 
```
#### 1.2.2 default_action
Resources will have a default action. 
It is a universal convention that the default action should be positive, 
such as ':add, :install, :start, :run'. 

This means the example of creating bob can be expressed as `user 'bob' do end`

## 2 Create Resources

### 2.1 Define the resource in cookbook
From within a cookbook directory, run `chef resource generate custom_user` and add the following to `resources/custom_user.rb`

```
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

```

### 2.3 Reference resource from recipe
Add the following to `recipes/main.rb`
This recipe first invokes the newly created resource 
with both implicit and explicit parameters parameters and actions

```
custom_user 'Creating user bob' do
  custom_username 'bob'
  action :add
end

custom_user 'bob' do
  action :del
end

custom_user 'alice' do
end
```

## 3 Testing your cookbook

### 3.1 Define unit tests
Add the following to `test/integration/default/default_test.rb`

```
describe user("bob") do
    it { should_not exist }
end

describe user("alice") do
    it { should exist }
end
```

### 3.2 Configure integration testing
Add the following to `kitchen.yml`
This driver requires Docker.


```
---
driver:
  name: dokken
  chef_version: current

transport:
  name: dokken

provisioner:
  name: dokken

verifier:
  name: inspec

platforms:
- name: centos-7
  driver:
    image: dokken/centos-7

suites:
  - name: default
    verifier:
      inspec_tests:
        - test/integration/default
    attributes:
```

### 3.3 Run integration tests
```
$ kitchen test
-----> Starting Kitchen (v2.3.3)
-----> Cleaning up any prior instances of <default-centos-7>
-----> Destroying <default-centos-7>...
       Deleting kitchen sandbox at /home/rohan/.dokken/kitchen_sandbox/a7915d66f7-default-centos-7
       Deleting verifier sandbox at /home/rohan/.dokken/verifier_sandbox/a7915d66f7-default-centos-7
       Finished destroying <default-centos-7> (0m0.02s).
-----> Testing <default-centos-7>
-----> Creating <default-centos-7>...
       Creating kitchen sandbox at /home/rohan/.dokken/kitchen_sandbox/a7915d66f7-default-centos-7
       Creating verifier sandbox at /home/rohan/.dokken/verifier_sandbox/a7915d66f7-default-centos-7
       Building work image..
       Creating container a7915d66f7-default-centos-7
       Finished creating <default-centos-7> (0m14.47s).
-----> Converging <default-centos-7>...
       Creating kitchen sandbox in /home/rohan/.dokken/kitchen_sandbox/a7915d66f7-default-centos-7
       Installing cookbooks for Policyfile /mnt/Projects/chef/custom_resource_example/Policyfile.rb using `chef install`
       Installing cookbooks from lock
       Installing custom_resource_example 0.1.0
       Preparing dna.json
       Exporting cookbook dependencies from Policyfile /home/rohan/.dokken/kitchen_sandbox/a7915d66f7-default-centos-7...
       Exported policy 'custom_resource_example' to /home/rohan/.dokken/kitchen_sandbox/a7915d66f7-default-centos-7
       
       To converge this system with the exported policy, run:
         cd /home/rohan/.dokken/kitchen_sandbox/a7915d66f7-default-centos-7
         chef-client -z
       Removing non-cookbook files before transfer
       Preparing validation.pem
       Preparing client.rb
+---------------------------------------------+
✔ 2 product licenses accepted.
+---------------------------------------------+
Starting Chef Infra Client, version 15.5.15
Creating a new client identity for default-centos-7 using the validator key.
Using policy 'custom_resource_example' at revision '1ac83a0ed9b446a41e2eeecc24cabf77f5259f97c897bf8d597208d6b41de5c2'
resolving cookbooks for run list: ["custom_resource_example::default@0.1.0 (6558d58)"]
Synchronizing Cookbooks:
  - custom_resource_example (0.1.0)
Installing Cookbook Gems:
Compiling Cookbooks...
Converging 3 resources
Recipe: custom_resource_example::default
  * custom_user[Creating user bob] action add
    * linux_user[create-the-user] action create
      - create user bob
  
  * custom_user[bob] action del
    * linux_user[remove-the-user] action remove
      - remove user bob
  
  * custom_user[alice] action add
    * linux_user[create-the-user] action create
      - create user alice
  

Running handlers:
Running handlers complete
Chef Infra Client finished, 6/6 resources updated in 01 seconds
       Finished converging <default-centos-7> (0m5.48s).
-----> Setting up <default-centos-7>...
       Finished setting up <default-centos-7> (0m0.00s).
-----> Verifying <default-centos-7>...
       Loaded tests from {:path=>".mnt.Projects.chef.custom_resource_example.test.integration.default"} 

Profile: tests from {:path=>"/mnt/Projects/chef/custom_resource_example/test/integration/default"} (tests from {:path=>".mnt.Projects.chef.custom_resource_example.test.integration.default"})
Version: (not specified)
Target:  docker://ea3e336a32d11368adc55c5104ddda2a50936e710cca38249a667e4bdafb2843

  User bob
     ✔  should not exist
  User alice
     ✔  should exist

Test Summary: 2 successful, 0 failures, 0 skipped
       Finished verifying <default-centos-7> (0m2.06s).
-----> Destroying <default-centos-7>...
       Deleting kitchen sandbox at /home/rohan/.dokken/kitchen_sandbox/a7915d66f7-default-centos-7
       Deleting verifier sandbox at /home/rohan/.dokken/verifier_sandbox/a7915d66f7-default-centos-7
       Finished destroying <default-centos-7> (0m0.57s).
       Finished testing <default-centos-7> (0m22.67s).
-----> Kitchen is finished. (0m24.65s)

```