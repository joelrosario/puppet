require 'puppet/provider'

Puppet::Type.type(:user).provide :useradd_win do
    desc "User management for windows"

    confine :true => Puppet.features.windows?
    require 'puppet/util/windows_system'

    has_features :manages_passwords

    def user
        @user = Puppet::Util::Windows::User.new(name) unless defined?(@user)
        @user
    end

    def name
        @resource[:name]
    end

    def password
        password = @resource[:password]
        user.password_is?(password) ?password :"" rescue :absent
    end

    def password=(pwd)
        user.password = @resource[:password]
    end

    def groups
        user.groups.join(',') rescue :absent
    end

    def groups=(groups)
        user.set_groups(groups, @resource[:membership] == :minimum)
    end

    def create
        @user = Puppet::Util::Windows::User.create(name, @resource[:password])
        user.set_groups(@resource[:groups], @resource[:membership] == :minimum)
    end

    def exists?
        return Puppet::Util::Windows::User.exists?(name)
    end

    def delete
        Puppet::Util::Windows::User.delete(name)
    end
end
