require File.dirname(__FILE__) + '/../../../lib/puppet/util/windows_system.rb'

module WindowsTest
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
	def destroy
		@list.each {|group|
			begin
				Windows::Group.delete(group)
			rescue
				puts "Group #{group} not found"
			end
		}
	end
    end

    class Users < List
	def destroy
		@list.each {|user|
			begin
				Windows::User.delete(user)
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
	Windows::User.create(name, password) { register_user name }
    end

    def mkgroup(name)
	Windows::Group.create(name) { register_group name }
    end

    def mkusers(names)
	names.collect {|name| mkuser name }
    end

    def mkgroups(names)
	names.collect {|name| mkgroup name }
    end

    def group(name)
	Windows::Group.new(name)
    end

    def assert_no_missing_member(group, expected_members)
	group.members.tap {|members|
		expected_members.each {|member| assert(members.include?(member), "#{member} should be a member") }
	}
    end

    def teardown
      clear
    end
end
