#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../../spec_helper'

describe "Provider for windows users" do
    confine :true => Puppet.features.windows?

    require 'windowstest'
    include WindowsTest

    def user_provider(resource_configuration)
        provider = Puppet::Type.type(:user).provider(:useradd_win).new
        provider.resource = resource_configuration
        return provider
    end

    after(:each) do
        clear
    end

    it 'should add a user with the given password and group membership' do
        expected_groups = ["randomgroup1", "randomgroup2"]
        username = "testuser"
        password = "1234"

        mkgroups(expected_groups)
        register_user username

        provider = user_provider :name => username, :password => password, :groups => expected_groups.join(",")
        provider.create

        testuser = user(username)
        testuser.password_is?(password).should be_true

        groups = testuser.groups

        expected_groups.each {|expected_group| groups.include?(expected_group).should be_true }
        expected_groups.length.should be_eql(groups.length)
    end

    describe "when a user belongs to groups named randomgroup1, randomgroup2," do
        before(:all) do
            expected_groups = ["randomgroup1", "randomgroup2"]
            username = "testuser"

            mkgroups expected_groups
            mkuser username

            @provider = user_provider :name => username
            @provider.groups = expected_groups.join(",")

            groups = @provider.groups.split(',').collect {|group| group.strip }
            groups.length.should be_eql(expected_groups.length)
            groups.each {|group| expected_groups.include?(group).should be_true }
        end
        
        describe "after setting membership to randomgroup1 only, " do
            before(:all) do
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

        testuser = mkuser username, password

        provider = user_provider :name => username, :password => password
        provider.password = password

        testuser.password_is?(password).should be_true
    end
end
