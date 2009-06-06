#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../../spec_helper'

describe "Group management for Windows: useradd_win" do
    confine :true => Puppet.features.windows?
    
    before(:each) do
        @resource = stub('resource')
        @resource.stubs(:[]).with(:name).returns('testgroup')
        
        provider_class = Puppet::Type.type(:group).provider(:groupadd_win)
        @provider = provider_class.new(@resource)
        
        @group_mock = mock('group')
        @provider.stubs(:group).returns @group_mock
    end

    it 'should be able to provide a list of members' do
        expected_members = ['user1', 'user2']
        @group_mock.expects(:members).returns expected_members

        members = @provider.members
        members.length.should be_eql(2)
        expected_members.each {|member| members.include?(member).should be_true }
    end
    
    it 'should be able to set group members' do
        members = ['user1', 'user2']
        @group_mock.expects(:set_members).with(members)
        @provider.members = members
    end
    
    it 'should be able to create a group' do
        Puppet::Util::Windows::Group.expects(:create).with('testgroup').returns @group_mock
        members = ['user1', 'user2']
        @resource.expects(:[]).with(:members).returns members
        @group_mock.expects(:set_members).with(members)
        
        @provider.create
    end

    it 'should be able to delete a group' do
        Puppet::Util::Windows::Group.expects(:delete).with('testgroup')
        @provider.delete
    end
    
    it 'should be able to verify that a group exists' do
        Puppet::Util::Windows::Group.expects(:exists?).with('testgroup').returns true
        @provider.should be_exists
        
        Puppet::Util::Windows::Group.expects(:exists?).with('testgroup').returns false
        @provider.should_not be_exists
    end
end
