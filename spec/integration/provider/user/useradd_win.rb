#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../../spec_helper'

describe "Provider for windows users" do
    confine :true => Puppet.features.windows?

    require 'windowstest'
	Puppet::Type.type(:user).provider(:useradd_win)

    include WindowsTest

    def user_provider(resource_configuration)
        provider = Puppet::Type::User::ProviderUseradd_win.new
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

    it 'should set the group membership of an existing user' do
        expected_groups = ["randomgroup1", "randomgroup2"]
        username = "testuser"

        mkgroups expected_groups
        mkuser username

        provider = user_provider :name => username
        provider.groups = expected_groups.join(",")

        groups = provider.groups.split(',').collect {|group| group.strip }
        groups.length.should be_eql(expected_groups.length)
        groups.each {|group| expected_groups.include?(group).should be_true }
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
