#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../../spec_helper'

describe "Provider for windows groups" do
    confine :true => Puppet.features.windows?

    require 'windowstest'
    include WindowsTest
    
    Puppet::Type.type(:user).provider(:useradd_win)
    #require File.dirname(__FILE__) + '/../../../../puppet/lib/util/windows_system'

    def group_provider(resource_configuration)
        provider = Puppet::Type.type(:group).provider(:groupadd_win).new
        provider.resource = resource_configuration
        return provider
    end

    before(:each) do
        @users_to_delete = []
        @groups_to_delete = []
    end
    
    def create_test_users(usernames)
        password = "qwertyuiop"
        
        usernames.flatten.each do |name|
            Puppet::Util::Windows::User.create(name, password)
            @users_to_delete << name
        end
    end

    def delete_test_users
        @users_to_delete.each {|name| Puppet::Util::Windows::User.delete(name) }
        @users_to_delete = []
    end

    after(:each) do
        delete_test_users
        clear
    end   

    it 'should create a group with configured members' do
        groupname = "randomgroup"
        register_group groupname

        expected_members = ["test1", "test2"]
        #mkusers(expected_members)
        create_test_users(expected_members)

        provider = group_provider :name => groupname, :members => ['test1', 'test2']
        provider.create

        should_have_no_missing_member(group(groupname), expected_members)
    end

    it 'should set a groups members' do
        groupname = "randomgroup"
        expected_members = ["test1", "test2"]

        testgroup = mkgroup(groupname)
        mkusers(expected_members)

        provider = group_provider :name => groupname, :members => ['test1', 'test2']
        provider.members = ['test1', 'test2']

        should_have_no_missing_member(testgroup, expected_members)
    end
end
