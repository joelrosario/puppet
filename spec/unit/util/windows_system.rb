#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../spec_helper'

describe "Puppet::Util::Windows" do
    confine :true => Puppet.features.windows?

    require 'puppet/util/windows_system'

    before(:each) do
        @computername = "testcomputername"
        Puppet::Util::Windows::API.stubs(:GetComputerName).returns "testcomputername"
    end
    
    describe Puppet::Util::Windows::Resource do
        describe "Given a resource name" do
            it "should return the computer uri with the resource name appended to at the end" do
                Puppet::Util::Windows::Resource.uri("test,user").should be_eql("WinNT://testcomputername/test,user")
            end
        end
    end

    describe Puppet::Util::Windows::Computer do
        it "should be able to get the name of the computer" do
            Puppet::Util::Windows::Computer.name.should be_eql("testcomputername")
        end

        it "should be able to provide a WinNT resource uri for the computer" do
            Puppet::Util::Windows::Computer.resource_uri.should be_eql("WinNT://testcomputername")
        end

        describe "When asked for an api object" do
            it "should connect to the computer resource uri and return the resulting adsi object" do
                Puppet::Util::ADSI.expects(:connect).returns "connected"
                Puppet::Util::Windows::Computer.api.should be_eql("connected")
            end
        end
        
        it "should be able to create a resource" do
            adsi_obj_mock = mock("adsi_obj")
            adsi_obj_mock.expects(:SetInfo)
            
            adsi_mock = mock("adsi")
            adsi_mock.expects(:create).with("user", "testuser").returns adsi_obj_mock
            
            Puppet::Util::ADSI.expects(:connect).with("WinNT://testcomputername").returns adsi_mock
            Puppet::Util::Windows::Computer.create("user", "testuser")
        end
        
        it "should be abl to delete a resource" do
            adsi_mock = mock("adsi")
            adsi_mock.expects(:Delete).with("user", "testuser")
            
            Puppet::Util::ADSI.expects(:connect).with("WinNT://testcomputername").returns adsi_mock
            Puppet::Util::Windows::Computer.delete("user", "testuser")
        end
    end
    
    describe Puppet::Util::Windows::Group do
        before(:each) { @groupname = "testgroup" }
        
        describe "An instance" do
            before(:each) do
                @adsi_mock = mock("adsi")
                @group = Puppet::Util::Windows::Group.new(@groupname, @adsi_mock)
            end
            
            describe "Given a group named #{@groupname}" do
                it "should provide a resource uri WinNT://testcomputername/#{@groupname},group" do
                    @group.resource_uri.should be_eql("WinNT://testcomputername/#{@groupname},group")
                end
            end
            
            it "should be able to add a member" do
                @adsi_mock.expects(:Add).with("WinNT://testcomputername/testuser")
                @adsi_mock.expects(:SetInfo)
                
                @group.add_member("testuser")
            end

            it "should be able to remove a member" do
                @adsi_mock.expects(:Remove).with("WinNT://testcomputername/testuser")
                @adsi_mock.expects(:SetInfo)
                
                @group.remove_member("testuser")
            end
            
            describe "when asked for a list of members" do
                it "should return a list of member names, not objects" do
                    member_names = ['member1', 'member2']
                    member_mocks = member_names.collect {|member_name| member_mock = mock('member'); member_mock.expects(:Name).returns(member_name); member_mock }

                    @adsi_mock.expects(:Members).returns(member_mocks)
                    
                    members = @group.members
                    
                    members.length.should be_eql(2)
                    members.each {|member| member_names.include?(member).should be_true }
                end
            end
            
            it "should be able to add a list of users to a group" do
                @group.expects(:members).returns ['user1', 'user2']

                @group.expects(:remove_member).with('user1')
                @group.expects(:add_member).with('user3')

                @group.set_members(['user2', 'user3'])
            end
        end
        
        it "should be able to create a group" do
            Puppet::Util::Windows::Computer.expects(:create).with("group", @groupname)
            got_called = false
            
            group = Puppet::Util::Windows::Group.create(@groupname) { got_called = true }
            got_called.should be_true
            group.is_a?(Puppet::Util::Windows::Group).should be_true
        end
        
        it "should be able to confirm the existence of a group" do
            Puppet::Util::ADSI.expects(:connectable?).with("WinNT://testcomputername/#{@groupname},group").returns true
            Puppet::Util::Windows::Group.exists?(@groupname).should be_true
        end
        
        it "should be able to delete a group" do
            Puppet::Util::Windows::Computer.expects(:delete).with("group", @groupname)
            Puppet::Util::Windows::Group.delete(@groupname)
        end
    end
    
    describe Puppet::Util::Windows::User do
        before(:each) { @username = "testuser" }
        
        describe "An instance" do
            before(:each) do
                @adsi_mock = mock("adsi")
                @user = Puppet::Util::Windows::User.new(@username, @adsi_mock)
            end
            
            describe "when asked for a list of groups which it's a member of" do
                it "should provide a list of names, not object" do
                    group_names = ["group1", "group2"]
                    group_mocks = group_names.collect {|group_name| group_mock = mock("group"); group_mock.expects(:name).returns(group_name); group_mock }

                    @adsi_mock.expects(:Groups).returns(group_mocks)

                    groups = @user.groups
                    
                    groups.length.should be_eql(2)
                    groups.each {|group| group_names.include?(group).should be_true }
                end
            end
            
            it 'should be able to test whether the given password is correct' do
                Puppet::Util::Windows::API.expects(:LogonUser).with(@username, 'pwdwrong').returns(false)
                Puppet::Util::Windows::API.expects(:LogonUser).with(@username, 'pwdright').returns(true)

                @user.password_is?('pwdwrong').should be_false
                @user.password_is?('pwdright').should be_true
            end
            
            it 'should be able to set a user\'s password' do
                @adsi_mock.expects(:SetPassword).with('pwd')
                @adsi_mock.expects(:SetInfo).twice
                
                flagname = "UserFlags"
                fADS_UF_DONT_EXPIRE_PASSWD = 0x10000
                
                @adsi_mock.expects(:Get).with(flagname).returns(0)
                @adsi_mock.expects(:Put).with(flagname, fADS_UF_DONT_EXPIRE_PASSWD)
                
                @user.password= 'pwd'
            end
            
            describe 'when given a set of groups to which to add the user' do
                def mock_object(name)
                    obj = mock(name)
                    yield(obj) if block_given?
                    return obj
                end
                
                before(:each) do
                    @groups_to_set = 'group1,group2'
                    @user.expects(:groups).returns ['group2', 'group3']
                end
                
                describe 'if membership is specified as inclusive' do
                    it 'should add the user to those groups, and remove it from groups not in the list' do
                        Puppet::Util::ADSI.expects(:connect).with('WinNT://testcomputername/group1,group').returns mock_object('adsi') {|m|
                            m.expects(:Add).with('WinNT://testcomputername/testuser')
                            m.expects(:SetInfo)
                        }
                        
                        Puppet::Util::ADSI.expects(:connect).with('WinNT://testcomputername/group3,group').returns mock_object('adsi') {|m|
                            m.expects(:Remove).with('WinNT://testcomputername/testuser')
                            m.expects(:SetInfo)
                        }
                        
                        @user.set_groups(@groups_to_set, false)
                    end
                end
                
                describe 'if membership is specified as minimum' do
                    it 'should add the user to the specified groups without affecting it\'s other memberships' do
                        Puppet::Util::ADSI.expects(:connect).with('WinNT://testcomputername/group1,group').returns mock_object('adsi') {|m|
                            m.expects(:Add).with('WinNT://testcomputername/testuser')
                            m.expects(:SetInfo)
                        }
                        
                        @user.set_groups(@groups_to_set, true)
                    end
                end
            end
        end
        
        describe "Given a user named #{@username}" do
            it "should provide a resource uri WinNT://testcomputername/testuser,user" do
                Puppet::Util::Windows::User.resource_uri(@username).should be_eql("WinNT://testcomputername/testuser,user")
            end
        end
        
        it "should be able to create a user" do
            password = 'pwd'
            
            adsi_obj = mock("adsi")
            adsi_obj.expects(:SetPassword).with(password)
            adsi_obj.expects(:SetInfo).twice
            
            flagname = "UserFlags"
            fADS_UF_DONT_EXPIRE_PASSWD = 0x10000
            
            adsi_obj.expects(:Get).with(flagname).returns(0)
            adsi_obj.expects(:Put).with(flagname, fADS_UF_DONT_EXPIRE_PASSWD)
            
            Puppet::Util::Windows::Computer.expects(:create).with("user", @username).returns(adsi_obj)
            got_called = false
            
            user = Puppet::Util::Windows::User.create(@username, password) { got_called = true }
            got_called.should be_true
            user.is_a?(Puppet::Util::Windows::User).should be_true
        end
        
        it "should be able to confirm the existence of a user" do
            Puppet::Util::ADSI.expects(:connectable?).with("WinNT://testcomputername/#{@username},user").returns true
            Puppet::Util::Windows::User.exists?(@username).should be_true
        end
        
        it "should be able to delete a group" do
            Puppet::Util::Windows::Computer.expects(:delete).with("user", @username)
            Puppet::Util::Windows::User.delete(@username)
        end
    end
end
