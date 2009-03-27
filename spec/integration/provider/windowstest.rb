require File.dirname(__FILE__) + '/../../../lib/puppet/util/windows_system.rb'

module WindowsTest
    include Puppet::Util::Windows

    class List
        def initialize
            @list = []
        end

        def clear
            destroy
            @list = []
        end

        def register(item)
            @list << item
        end
    end

    class Groups < List
        include Puppet::Util::Windows

        def destroy
            @list.each {|group|
                begin
                    Group.delete(group)
                rescue
                    puts "Group #{group} not found"
                end
            }
        end
    end

    class Users < List
        include Puppet::Util::Windows

        def destroy
            @list.each {|user|
                begin
                    User.delete(user)
                rescue
                    puts "User #{user} not found"
                end
            }
        end
    end

    def helper_users
        @users = Users.new if @users == nil
        @users
    end

    def helper_groups
        @groups = Groups.new if @groups == nil
        @groups
    end

    def clear
        helper_groups.clear
        helper_users.clear
    end

    def register_group(name)
        helper_groups.register name
    end

    def register_user(name)
        helper_users.register name
    end

    def mkuser(name, password = "1234567")
        User.create(name, password) { register_user name }
    end

    def mkgroup(name)
        Group.create(name) { register_group name }
    end

    def mkusers(names)
        names.collect {|name| mkuser name }
    end

    def mkgroups(names)
        names.collect {|name| mkgroup name }
    end

    def group(name)
        Group.new(name)
    end

    def user(name)
        User.new(name)
    end

    def assert_no_missing_member(group, expected_members)
        members = group.members
        expected_members.each {|member| assert(members.include?(member), "#{member} should be a member") }
    end

    def should_have_no_missing_member(testgroup, expected_members)
        members = testgroup.members
        expected_members.each {|member| members.include?(member).should be_true }
    end

    def teardown
        clear
    end
end
