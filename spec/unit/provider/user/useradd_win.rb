#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../../spec_helper'

describe "User management for Windows: useradd_win" do
    confine :true => Puppet.features.windows?
    
    before(:each) do
        @resource = stub('resource')
        @resource.stubs(:[]).with(:name).returns('testuser')
        @resource.stubs(:[]).with(:password).returns('pwd')

        provider_class = Puppet::Type.type(:user).provider(:useradd_win)
        @provider = provider_class.new(@resource)

        @user_mock = mock('user')
        @provider.stubs(:user).returns @user_mock
    end

    it 'should be able to verify a users password using User::password_is?' do
        @user_mock.expects(:password_is?).with('pwd').returns true
        @provider.password.should be_eql('pwd')
        
        @user_mock.expects(:password_is?).with('pwd').returns false
        @provider.password.should be_eql('')
    end
    
    it 'should be able to set a users password using User::password' do
        @user_mock.expects(:password=).with('pwd')
        @provider.password = 'pwd'
    end
    
    describe 'when asked for a list of groups of which the user is a member' do
        it 'should return the list of groups as a csv' do
            @user_mock.expects(:groups).returns ['group1', 'group2', 'group3']
            @provider.groups.should be_eql('group1,group2,group3')
        end
        
        it 'should return :absent if any error is raised while fetching the list' do
            @user_mock.expects(:groups).raises("ERROR")
            @provider.groups.should be_eql(:absent)
        end
    end
    
    it 'should be able to add a user to a set of groups' do
        @resource.expects(:[]).with(:membership).returns(:minimum)
        @user_mock.expects(:set_groups).with('group1,group2', true)
        
        @provider.groups = 'group1,group2'
        
        @resource.expects(:[]).with(:membership).returns(:inclusive)
        @user_mock.expects(:set_groups).with('group1,group2', false)
        
        @provider.groups = 'group1,group2'
    end
    
    it 'should be able to create a user' do
        @resource.expects(:[]).with(:groups).returns('group1,group2')
        @resource.expects(:[]).with(:membership).returns(:minimum)
        
        Puppet::Util::Windows::User.expects(:create).with('testuser', 'pwd').returns @user_mock
        @user_mock.expects(:set_groups).with('group1,group2', true)
        
        @provider.create
    end
    
    it 'should be able to test whether a user exists' do
        Puppet::Util::Windows::User.expects(:exists?).with('testuser').returns true
        @provider.should be_exists

        Puppet::Util::Windows::User.expects(:exists?).with('testuser').returns false
        @provider.should_not be_exists
    end
    
    it 'should be able to delete a user' do
        Puppet::Util::Windows::User.expects(:delete).with('testuser')
        @provider.delete
    end
end
