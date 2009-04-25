module Puppet
    Puppet::Type.type(:file).newproperty(:win_acl) do
        desc "This property sets windows permissions."

        @event = :permissions_changed

        def is_to_s(current_permissions)
            current_permissions.keys.sort.inject("") do |str, name|
                list = current_permissions[name]
                str += '; ' if str.length > 0
                str += "#{name}: #{list.collect {|entry| entry.strip }.join(',')}"
            end
        end

        def retrieve
            replace_values_in(permissions_of(filename)) {|value| File.securities value}
        end

        def insync?(actual_permissions)
            configured_permissions == upcase_keys(actual_permissions)
        end

        def sync
            permissions = replace_values_in(configured_permissions) {|permissions_constants| permissions_constants.inject(0) {|flags, constant| flags | File.const_get(constant) } }
            File.set_permissions(filename, permissions)

            return :permissions_changed
        end

        def configured_permissions
            should_hash = {}

            split_on(';', @should[0]).each do |entry|
                split_on(':', entry) {|name, list| should_hash[name.upcase] = split_on(',', list, :upcase) }
            end

            return should_hash
        end

        def filename
            @resource.name
        end

        def permissions_of(filename)
            permissions = File.get_permissions(filename)
        end

        def replace_values_in(hash)
            hash.inject({}) {|hash, row| key, value = row; hash[key] = yield(value); hash }
        end

        def map_methods(list, *methods)
            methods.inject(list) {|list, method| list.collect {|entry| entry.send(method)} }
        end

        def split_on(char, str, *processor_methods)
            list = map_methods(str.split(char).collect {|e| e.strip }, *processor_methods)
            return list if !block_given?
            yield(list)
        end

        def upcase_keys(hash)
            hash.inject({}) {|hash, row| key, value = row; hash[key.upcase] = value; hash }
        end
    end
end
