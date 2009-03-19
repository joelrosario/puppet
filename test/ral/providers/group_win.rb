#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../lib/puppettest'
require 'windowstest'

require File.dirname(__FILE__) + '/../../../lib/puppet/provider/group/groupadd_win.rb'

class TestGroupProvider < Test::Unit::TestCase
    include WindowsTest

    def group_provider(resource_configuration)
	Puppet::Type::Group::ProviderGroupadd_win.new.tap {|provider| provider.resource = resource_configuration }
    end

    def test_groupGetsCreated
	groupname = "randomgroup"
	register_group groupname

	expected_members = ["test1", "test2"]
	mkusers(expected_members)

	provider = group_provider :name => groupname, :members => ['test1', 'test2']

	assert_nothing_raised { provider.create }
	assert_no_missing_member(group(groupname), expected_members)
    end

    def test_groupMembersGetSet
	groupname = "randomgroup"
	group = mkgroup(groupname)
	expected_members = ["test1", "test2"]
	mkusers(expected_members)

	provider = group_provider :name => groupname, :members => ['test1', 'test2']

	assert_nothing_raised { provider.members = ['test1', 'test2'] }
	assert_no_missing_member(group, expected_members)
    end
end
