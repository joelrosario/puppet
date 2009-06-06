#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../../spec_helper'

describe "Provider for windows users" do
    confine :true => Puppet.features.windows?

    require 'windowstest'
    include WindowsTest

    before(:each) do
        @users_to_delete = []
        @groups_to_delete = []
    end
    
    after(:each) do
        delete_test_users
        delete_test_groups
    end   

    def user_provider(resource_configuration)
        provider = Puppet::Type.type(:user).provider(:useradd_win).new
        provider.resource = resource_configuration
        return provider
    end

    it 'should create a user with the given password and group membership' do
        expected_groups = ["randomgroup1", "randomgroup2"]
        username = "testuser"
        password = "1234"

        create_test_groups(expected_groups)
        delete_user_later username

        provider = user_provider :name => username, :password => password, :groups => expected_groups.join(",")
        provider.create

        testuser = user(username)
        testuser.password_is?(password).should be_true

        users_groups = testuser.groups

        users_groups.sort.should be_eql(expected_groups.sort)
    end

    describe "when a user belongs to groups named randomgroup1, randomgroup2," do
        before do
            @users_to_delete = []
            @groups_to_delete = []

            expected_groups = ["randomgroup1", "randomgroup2"]
            username = "testuser"

            create_test_groups expected_groups
            create_test_users username

            @provider = user_provider :name => username
            @provider.groups = expected_groups.join(",")

            groups = @provider.groups.split(',').collect {|group| group.strip }
            groups.length.should be_eql(expected_groups.length)
            groups.each {|group| expected_groups.include?(group).should be_true }
        end

        after do
            delete_test_users
            delete_test_groups
        end

        describe "after setting membership to randomgroup1 only, " do
            before do
                @provider.groups = "randomgroup1"
            end
            
            it "the user should no more be a member of randomgroup 2" do
                groups = @provider.groups
                
                groups.index(',').should be_nil
                groups.should be_eql("randomgroup1")
            end
        end
    end

    it 'should set a users password' do
        username = "testuser"
        password = "11112222"

        testuser = create_test_user username, password

        provider = user_provider :name => username, :password => password
        provider.password = password

        testuser.password_is?(password).should be_true
    end
end
