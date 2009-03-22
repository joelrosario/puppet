#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../../lib/puppettest'
require 'windowstest'

require File.dirname(__FILE__) + '/../../../../lib/puppet/provider/user/useradd_win.rb'

class TestUserProvider < Test::Unit::TestCase
	include WindowsTest
    include Puppet::Util::Windows

	def user_provider(resource_configuration)
		Puppet::Type::User::ProviderUseradd_win.new.tap {|provider| provider.resource = resource_configuration }
	end

	def test_userIsCreated
		expected_groups = ["randomgroup1", "randomgroup2"]
		mkgroups(expected_groups)

		username = "testuser"
		register_user username

		password = "1234"

		provider = user_provider :name => username, :password => password, :groups => expected_groups.join(",")

		assert_nothing_raised { provider.create }

		user = User.new(username)
		assert(user.password_is?(password), "Password of user #{username} should be #{password}")
		user.groups.tap {|groups|
			expected_groups.each {|expected_group| assert(groups.include?(expected_group), "User should be a member of #{expected_group}") }
			assert(expected_groups.length == groups.length, "The user should be a member of #{expected_groups.length} groups.")
		}
	end

	def test_userGroupsAreSet
		expected_groups = ["randomgroup1", "randomgroup2"]
		mkgroups expected_groups

		username = "testuser"
		mkuser username

		provider = user_provider :name => username
		provider.groups = expected_groups.join(",")

		provider.groups.split(',').collect {|group| group.strip }.tap {|groups|
			assert(groups.length == expected_groups.length, "The user should be a member of #{expected_groups.length} groups.")
			groups.each {|group| assert(expected_groups.include?(group), "The user should be a member of #{group}") }
		}
	end

	def test_usersPasswordIsSet
		username = "testuser"
		password = "11112222"

		user = mkuser username, password

		provider = user_provider :name => username, :password => password
		provider.password = password

		assert(user.password_is?(password), "User #{username}'s password should be #{password}.")
	end
end
