Puppet::Type.type(:group).provide :groupadd_win do
    desc "Group management for windows"

    confine :true => Puppet.features.windows?
    require 'puppet/util/windows_system'

    has_features :manages_members

    def group
        @group = Puppet::Util::Windows::Group.new(name) unless defined?(@group)
        @group
    end
    
    def name
        @resource[:name]
    end

    def members
        group.members
    end

    def members=(members)
        group.set_members(members)
    end

    def create
        @group = Puppet::Util::Windows::Group.create(name)
        @group.set_members(@resource[:members])
    end

    def exists?
        Puppet::Util::Windows::Group.exists?(name)
    end

    def delete
        Puppet::Util::Windows::Group.delete(name)
    end
end
