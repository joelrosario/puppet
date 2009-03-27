#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../../spec_helper'

describe "Provider for windows groups" do
    confine :true => Puppet.features.windows?

    require File.dirname(__FILE__) + '/../windowstest'
    require File.dirname(__FILE__) + '/../../../../lib/puppet/provider/group/groupadd_win.rb'

    include WindowsTest

    def group_provider(resource_configuration)
        provider = Puppet::Type::Group::ProviderGroupadd_win.new
        provider.resource = resource_configuration
        return provider
    end

    after(:each) do
        clear
    end   

    it 'should create a group with configured members' do
        groupname = "randomgroup"
        register_group groupname

        expected_members = ["test1", "test2"]
        mkusers(expected_members)

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
