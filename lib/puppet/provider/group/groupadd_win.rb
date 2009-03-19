require 'puppet/util/windows_system'

Puppet::Type.type(:group).provide :groupadd_win do
    desc "Group management for windows"

	defaultfor :operatingsystem => :windows

	has_features :manages_members

	def members
		Windows::Group.new(@resource[:name]).members
	end

	def members=(members)
		Windows::Group.new(@resource[:name]).set_members(members)
	end

	def create
		group = Windows::Group.create(@resource[:name])
		group.set_members(@resource[:members])
	end

	def exists?
		Windows::Group.exists?(@resource[:name])
	end

	def delete
		Windows::Group.delete(@resource[:name])
	end
end
