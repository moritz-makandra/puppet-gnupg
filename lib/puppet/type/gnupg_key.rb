require 'uri'
Puppet::Type.newtype(:gnupg_key) do
  @doc = 'Manage PGP public keys with GnuPG'

  ensurable

  autorequire(:package) do
    ['gnupg', 'gnupg2']
  end

  autorequire(:user) do
    self[:user]
  end

  KEY_SOURCES = [:key_source, :key_server, :key_content].freeze

  KEY_CONTENT_REGEXES = {
    public: ['-----BEGIN PGP PUBLIC KEY BLOCK-----', '-----END PGP PUBLIC KEY BLOCK-----'],
    private: ['-----BEGIN PGP PRIVATE KEY BLOCK-----', '-----END PGP PRIVATE KEY BLOCK-----'],
  }.freeze

  validate do
    creator_count = 0
    KEY_SOURCES.each do |param|
      creator_count += 1 unless self[param].nil?
    end

    if creator_count > 1
      raise Puppet::ParseError, "You cannot specify more than one of #{KEY_SOURCES.map { |p| p.to_s }.join(', ')}"
    end

    if creator_count == 0 && self[:ensure] == :present
      raise Puppet::ParseError, "You need to specify at least one of #{KEY_SOURCES.map { |p| p.to_s }.join(', ')}"
    end

    if self[:ensure] == :present && self[:key_type] == :both
      raise Puppet::ParseError, "A key type of 'both' is invalid when ensure is 'present'."
    end

    [:public, :private].each do |type|
      next unless self[:key_content] && self[:key_type] == type
      key_lines = self[:key_content].strip.lines.to_a

      first_line = key_lines.first.strip
      last_line = key_lines.last.strip

      unless first_line == KEY_CONTENT_REGEXES[type][0] && last_line == KEY_CONTENT_REGEXES[type][1]
        raise Puppet::ParseError, "Provided key content does not look like a #{type} key."
      end
    end
  end

  newparam(:name, namevar: true) do
    desc 'arbitrary catalog unique resource name'
  end

  newparam(:user) do
    desc 'execute gpg command with this user'

    validate do |value|
      # freebsd/linux username limitation
      unless %r{^[a-z_][a-z0-9_-]*[$]?}.match?(value)
        raise ArgumentError, "Invalid username format for #{value}"
      end
    end
  end

  newparam(:key_source) do
    desc 'Location of a file containing the PGP key. Values may be a local file path or Puppet supported URL.'

    validate do |source|
      raise ArgumentError, 'Arrays not accepted as an source parameter' if source.is_a?(Array)
      break if Puppet::Util.absolute_path?(source)

      begin
        uri = if URI.const_defined? 'DEFAULT_PARSER'
                URI.parse(URI::DEFAULT_PARSER.escape(source))
              else
                URI.parse(URI.escape(source))
              end
      rescue => detail
        raise ArgumentError, "Could not understand source #{source}: #{detail}"
      end

      raise Puppet::ParseError, "Cannot use relative URLs '#{source}'" unless uri.absolute?
      raise Puppet::ParseError, "Cannot use opaque URLs '#{source}'" unless uri.hierarchical?
      raise Puppet::ParseError, "Cannot use URLs of type '#{uri.scheme}' as source for fileserving" unless ['file', 'puppet', 'https', 'http'].include?(uri.scheme)
    end

    munge do |source|
      uri = if URI.const_defined? 'DEFAULT_PARSER'
              URI.parse(URI::DEFAULT_PARSER.escape(source))
            else
              URI.parse(URI.escape(source))
            end

      if ['file'].include?(uri.scheme)
        uri.path
      else
        source
      end
    end
  end

  newparam(:key_server) do
    desc 'PGP key server from where to retrieve the public key'

    validate do |server|
      if server
        uri = if URI.const_defined? 'DEFAULT_PARSER'
                URI.parse(URI::DEFAULT_PARSER.escape(server))
              else
                URI.parse(URI.escape(server))
              end
        unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS) ||
               uri.is_a?(URI::LDAP) || ['hkp'].include?(uri.scheme)
          raise Puppet::ParseError, "Invalid keyserver value #{server}"
        end
      end
    end
  end

  newparam(:key_content) do
    desc 'Content of an ASCII armor PGP key'
  end

  newparam(:key_id) do
    desc '8, 16, or 40 character version of the key ID'

    validate do |value|
      unless ([8, 16, 40].include? value.length) && value =~ (%r{^[0-9A-Fa-f]+$})
        raise Puppet::ParseError, "Invalid key id #{value}"
      end
    end

    munge do |value|
      value.upcase.to_sym
    end
  end

  newparam(:key_type) do
    desc 'type of key(s) being managed'

    newvalues(:public, :private, :both)

    defaultto :public
  end

  newparam(:proxy) do
    desc 'set the proxy to use for HTTP and HKP keyservers'

    validate do |value|
      if value
        uri = if URI.const_defined? 'DEFAULT_PARSER'
                URI.parse(URI::DEFAULT_PARSER.escape(value))
              else
                URI.parse(URI.escape(value))
              end
        unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
          raise ArgumentError, "Invalid proxy value #{value}"
        end
      end
    end
  end

  newparam(:home) do
    desc "Gnupg home directory. Overrides gpg default, typically .gnupg under the user's home directory"
    defaultto false

    validate do |value|
      unless Puppet::Util.absolute_path?(value)
        raise Puppet::ParseError, _("File paths must be fully qualified, not '%{path}'") % { path: value }
      end
    end

    munge do |value|
      ::File.join(::File.split(::File.expand_path(value)))
    end
  end
end
