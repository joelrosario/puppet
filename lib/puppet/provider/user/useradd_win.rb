require 'puppet/provider'
require 'puppet/util/windows_system'

raise "ERROR: A windowsuser resource can only be configured on Windows. This OS is is #{Facter['kernel'].value}" if Facter['kernel'].value != 'windows'

Puppet::Type.type(:user).provide :useradd_win do
    desc "User management for windows"

    confine :operatingsystem => :windows

    has_features :manages_passwords

    def password
        name, password = @resource[:name], @resource[:password]
        Puppet::Util::Windows::User.new(name).password_is?(password) ?password :"" rescue :absent
    end

    def password=(pwd)
        Puppet::Util::Windows::User.new(@resource[:name]).password = @resource[:password]
    end

    def groups
        Puppet::Util::Windows::User.new(@resource[:name]).groups.join(',') rescue :absent
    end

    def groups=(groups)
        Puppet::Util::Windows::User.new(@resource[:name]).set_groups(groups)
    end

    def create
        user = Puppet::Util::Windows::User.create(@resource[:name], @resource[:password])
        user.set_groups(@resource[:groups], @resource[:membership] == :minimum)
    end

    def exists?
        return Puppet::Util::Windows::User.exists?(@resource[:name])
    end

    def delete
        Puppet::Util::Windows::User.delete(@resource[:name])
    end
end
