require 'puppet/util/feature'

Puppet.features.add(:windows) do
    result = false

    if Facter.operatingsystem == 'windows'
        begin
            require 'win32ole'
            require 'Win32API'
            result = true
        rescue
        end
    end

    result
end
