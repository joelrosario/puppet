if Facter.operatingsystem == "windows"
	require 'win32ole'
	require 'Win32API'
end

module ADSI
	def ADSI.connectable?(uri)
		begin
			adsi_obj = WIN32OLE.connect(uri)
			return adsi_obj != nil;
		rescue
		end

		return false
	end
end

module Windows
	class Resource
		def Resource.uri(resource_name)
			"#{Computer.resource_uri}/#{resource_name}"
		end
	end

	class User
		def initialize(username, native_adsi_obj = nil)
			@username = username
			@user = native_adsi_obj
		end

		def user
			@user = WIN32OLE.connect(User.resource_uri(@username)) if @user == nil
			return @user
		end

		def password_is?(password)
			fLOGON32_LOGON_NETWORK_CLEARTEXT = 8
			fLOGON32_PROVIDER_DEFAULT = 0

			logon_user = Win32API.new("advapi32", "LogonUser", ['P', 'P', 'P', 'L', 'L', 'P'], 'L')
			close_handle = Win32API.new("kernel32", "CloseHandle", ['P'], 'V')

			token = ' ' * 4
			if logon_user.call(@username, "", password, fLOGON32_LOGON_NETWORK_CLEARTEXT, fLOGON32_PROVIDER_DEFAULT, token) == 1
				close_handle.call(token.unpack('L')[0])
				return true
			end

			return false
		end

		def add_flag(flag_name, value)
			flag = 0

			begin
				flag = user.Get(flag_name)
			rescue
			end

			user.Put(flag_name, flag | value)
			user.SetInfo
		end

		def password=(password)
			user.SetPassword(password)
			user.SetInfo

			fADS_UF_DONT_EXPIRE_PASSWD = 0x10000
			add_flag("UserFlags", fADS_UF_DONT_EXPIRE_PASSWD)
		end

		def groups
			groups = []
			user.Groups.each {|group| groups << group.name }
			return groups
		end

		def add_to_groups(group_names)
			group_names.each {|name| Group.new(name).add_user(@username) } if group_names.length > 0
		end

		def remove_from_groups(group_names)
			group_names.each {|name| Group.new(name).remove_user(@username) } if group_names.length > 0
		end

		def set_groups(names, minimal = true)
			return if names == nil || names.strip.length == 0

			names = names.strip.split(',')
			current_groups = groups

			names.find_all {|name| !current_groups.include?(name) }.tap {|names_to_add| add_to_groups(names_to_add) }
			current_groups.find_all {|name| !names.include?(name) }.tap {|names_to_remove| remove_from_groups(names_to_remove) } if minimal == false
		end

		def User.resource_uri(username)
			return "#{Resource.uri(username)},user"
		end

		def User.exists?(username)
			return ADSI::connectable?(User.resource_uri(username))
		end

		def User.create(username, password)
			User.new(username, Computer.create("user", username)).tap {|user| user.password = password; yield user if block_given? }
		end

		def User.delete(username)
			Computer.delete("user", username)
		end
	end

	class Group
		def initialize(groupname, native_adsi_obj = nil)
			@groupname = groupname
			@group = native_adsi_obj
		end

		def resource_uri
			Group.resource_uri(@groupname)
		end

		def Group.resource_uri(name)
			"#{Resource.uri(name)},group"
		end

		def group
			@group = WIN32OLE.connect(resource_uri) if @group == nil
			return @group
		end

		def add_user(username)
			group.Add(User.resource_uri(username))
			group.SetInfo
		end

		def remove_user(username)
			group.Remove(User.resource_uri(username))
			group.SetInfo
		end

		def add_member(name)
			group.Add(Resource.uri(name))
			group.SetInfo
		end

		def remove_member(name)
			group.Remove(Resource.uri(name))
			group.SetInfo
		end

		def members
			list = []
			group.Members.each {|member| list << member.Name }
			list
		end

		def set_members(members)
			return nil if members == nil || members.length == 0

			current_members = self.members

			members.inject([]) {|members_to_add, member| current_members.include?(member) ? members_to_add : members_to_add << member }.each {|member| add_member(member) }
			current_members.inject([]) {|members_to_remove, member| members.include?(member) ? members_to_remove : members_to_remove << member }.each {|member| remove_member(member) }
		end

		def Group.create(name)
			Windows::Group.new(name, Computer.create("group", name)).tap {|group| yield group if block_given? }
		end

		def Group.exists?(name)
			return ADSI::connectable?(Group.resource_uri(name))
		end

		def Group.delete(name)
			Computer.delete("group", name)
		end
	end

	class Computer
		def Computer.name
			name = " " * 128
			size = "128"
			Win32API.new('kernel32','GetComputerName',['P','P'],'I').call(name,size)
			return name.unpack("A*")
		end

		def Computer.resource_uri
			computer_name = Computer.name
			return "WinNT://#{computer_name}"
		end

		def Computer.api
			return WIN32OLE.connect(Computer.resource_uri)
		end

		def Computer.create(resource_type, name)
			Computer.api.create(resource_type, name).SetInfo
		end

		def Computer.delete(resource_type, name)
			Computer.api.Delete(resource_type, name)
		end
	end
end
