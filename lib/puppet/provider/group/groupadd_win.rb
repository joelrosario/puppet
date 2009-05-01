Puppet::Type.type(:group).provide :groupadd_win do
    desc "Group management for windows"

    confine :true => Puppet.features.windows?
    require 'puppet/util/windows_system'

    has_features :manages_members

    def members
        Puppet::Util::Windows::Group.new(@resource[:name]).members
    end

    def members=(members)
        Puppet::Util::Windows::Group.new(@resource[:name]).set_members(members)
    end

    def create
        group = Puppet::Util::Windows::Group.create(@resource[:name])
        group.set_members(@resource[:members])
    end

    def exists?
        Puppet::Util::Windows::Group.exists?(@resource[:name])
    end

    def delete
        Puppet::Util::Windows::Group.delete(@resource[:name])
    end
end
