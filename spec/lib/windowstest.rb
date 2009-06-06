#require File.dirname(__FILE__) + '/../../../lib/puppet/util/windows_system.rb'
require File.dirname(__FILE__) + '/../../lib/puppet/util/windows_system.rb'

module WindowsTest
    include Puppet::Util::Windows

    def group(name)
        Group.new(name)
    end

    def user(name)
        User.new(name)
    end

    def create_test_groups(groupnames)
        list = groupnames.collect do |name|
            group = Puppet::Util::Windows::Group.create(name)
            delete_group_later name
            group
        end

        return list[0] if list.length == 1
        return list
    end

    def create_test_user(username, password)
        user = Puppet::Util::Windows::User.create(username, password)
        @users_to_delete << username
        return user
    end

    def create_test_users(*usernames)
        password = "qwertyuiop"
        
        list = usernames.flatten.collect do |name|
            create_test_user(name, password)
        end

        return list[0] if list.length == 1
        return list
    end

    def delete_test_users
        @users_to_delete.each {|name| Puppet::Util::Windows::User.delete(name) }
        @users_to_delete = []
    end

    def delete_test_groups
        @groups_to_delete.each {|name| Puppet::Util::Windows::Group.delete(name) }
        @groups_to_delete = []
    end

    def delete_group_later(groupname)
        @groups_to_delete << groupname
    end

    def delete_user_later(username)
        @users_to_delete << username
    end
end
