require 'etc'
require 'tmpdir'
require 'puppet/file_serving/content'

Puppet::Type.type(:gnupg_key).provide(:gnupg) do
  @doc = 'Provider for gnupg_key type.'

  defaultfor kernel: 'Linux'
  confine kernel: 'Linux'

  def self.instances
    []
  end

  # although we do not use the commands class it's used to detect if the gpg and awk commands are installed on the system
  commands gpg: 'gpg'
  commands awk: 'awk'

  def gpgenv(resource)
    if resource[:home]
      { 'GNUPGHOME' => resource[:home] }
    else
      {}
    end
  end

  def remove_key
    begin
      fingerprint_command = "gpg --fingerprint --with-colons #{resource[:key_id]} | awk -F: '$1 == \"fpr\" {print $10;}'"
      fingerprint = Puppet::Util::Execution.execute(fingerprint_command, uid: user_id, custom_environment: gpgenv(resource))
    rescue Puppet::ExecutionFailure => e
      raise Puppet::Error, "Could not determine fingerprint for #{resource[:key_id]} for user #{resource[:user]}: #{e}"
    end

    if resource[:key_type] == :public
      command = "gpg --batch --yes --delete-key #{fingerprint}"
    elsif resource[:key_type] == :private
      command = "gpg --batch --yes --delete-secret-key #{fingerprint}"
    elsif resource[:key_type] == :both
      command = "gpg --batch --yes --delete-secret-and-public-key #{fingerprint}"
    end

    begin
      Puppet::Util::Execution.execute(command, uid: user_id, custom_environment: gpgenv(resource))
    rescue Puppet::ExecutionFailure => e
      raise Puppet::Error, "Could not remove #{resource[:key_id]} for user #{resource[:user]}: #{e}"
    end
  end

  # where most of the magic happens
  # TODO implement dry-run to check if the key_id match the content of the file
  def add_key
    if resource[:key_server]
      add_key_from_key_server
    elsif resource[:key_source]
      add_key_from(:key_source)
    elsif resource[:key_content]
      add_key_from(:key_content)
    end
  end

  def add_key_from_key_server
    command = if resource[:proxy].nil? || resource[:proxy].empty?
                "gpg --keyserver #{resource[:key_server]} --recv-keys #{resource[:key_id]}"
              else
                "gpg --keyserver #{resource[:key_server]} --keyserver-options http-proxy=#{resource[:proxy]} --recv-keys #{resource[:key_id]}"
              end
    begin
      Puppet::Util::Execution.execute(command, uid: user_id, failonfail: true, custom_environment: gpgenv(resource))
    rescue Puppet::ExecutionFailure => e
      raise Puppet::Error, "Key #{resource[:key_id]} does not exist on #{resource[:key_server]}: #{e}"
    end
  end

  def add_key_from(rkey)
    tmp_path = if %r{content$}.match?(rkey.to_s)
                 create_temporary_file(user_id, resource[rkey])
               else
                 create_temporary_file(user_id, puppet_content)
               end
    command = "gpg --batch --import #{tmp_path}"
    begin
      Puppet::Util::Execution.execute(command, uid: user_id, failonfail: true, custom_environment: gpgenv(resource))
    rescue Puppet::ExecutionFailure => e
      raise Puppet::Error, "Error while importing key #{resource[:key_id]} from #{resource[:key_source]}: #{e}"
    end
  end

  def add_key_from_key_content
    path = create_temporary_file(user_id, resource[:key_content])
    command = "gpg --batch --import #{path}"
    begin
      Puppet::Util::Execution.execute(command, uid: user_id, failonfail: true, custom_environment: gpgenv(resource))
    rescue Puppet::ExecutionFailure => e
      raise Puppet::Error, "Error while importing key #{resource[:key_id]} using key content: #{e}"
    end
  end

  def user_id
    Etc.getpwnam(resource[:user]).uid
  rescue => e
    raise Puppet::Error, "User #{resource[:user]} does not exists: #{e}"
  end

  def create_temporary_file(user_id, content)
    Puppet::Util::SUIDManager.asuser(user_id) do
      tmpfile = Tempfile.open(['h0tw1r3-gnupg', 'key'])
      tmpfile.write(content)
      tmpfile.flush
      break tmpfile.path.to_s
    end
  end

  def puppet_content
    # Look up (if necessary) and return remote content.
    return @content if @content
    resp = Puppet.runtime[:http].get(URI(resource[:key_source]), options: { include_system_store: true })
    unless resp.success?
      raise 'Could not find any content at %s' % resource[:key_source]
    end
    @content = resp.body
  end

  def exists?
    # public and both can be grouped since private can't be present without public,
    # both only applies to delete and delete still has something to do if only
    # one of the keys is present
    if resource[:key_type] == :public || resource[:key_type] == :both
      command = "gpg --list-keys --with-colons #{resource[:key_id]}"
    elsif resource[:key_type] == :private
      command = "gpg --list-secret-keys --with-colons #{resource[:key_id]}"
    end

    output = Puppet::Util::Execution.execute(command, uid: user_id, custom_environment: gpgenv(resource))
    if output.exitstatus == 0
      true
    elsif output.exitstatus == 2
      false
    else
      raise Puppet::Error, "Unrecognized exit status from GnuPG #{output.exitstatus} #{output}"
    end
  end

  def create
    add_key
    # TODO: check before adding
    raise Puppet::Error, "#{resource[:key_type]} key added did not contain #{resource[:key_id]}!" unless exists?
  end

  def destroy
    remove_key
  end
end
