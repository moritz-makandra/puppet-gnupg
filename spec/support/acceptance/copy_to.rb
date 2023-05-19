# Figure out the best method to copy files to a host and use it
#
# Will create the directories leading up to the target if they don't exist
def copy_to(sut, src, dest, opts = {})
  sut.mkdir_p(File.dirname(dest))

  if sut[:hypervisor] == 'docker'
    exclude_list = []
    opts[:silent] ||= true

    if opts.key?(:ignore) && !opts[:ignore].empty?
      opts[:ignore].each do |value|
        exclude_list << "--exclude '#{value}'"
      end
    end

    # Work around for breaking changes in beaker-docker
    container_id = if sut.host_hash[:docker_container]
                     sut.host_hash[:docker_container].id
                   else
                     sut.host_hash[:docker_container_id]
                   end

    if ENV['BEAKER_docker_cmd']
      docker_cmd = ENV['BEAKER_docker_cmd']
    else
      docker_cmd = 'docker'

      if ::Docker.version['Components'].any? { |x| x['Name'] =~ %r{podman}i }
        docker_cmd = 'podman'

        if ENV['CONTAINER_HOST']
          docker_cmd = 'podman --remote'
        elsif ENV['DOCKER_HOST']
          docker_cmd = "podman --remote --url=#{ENV['DOCKER_HOST']}"
        end
      end
    end

    sut.mkdir_p(File.dirname(dest)) unless directory_exists_on(sut, dest)

    cmd = if File.file?(src)
            %(#{docker_cmd} cp "#{src}" "#{container_id}:#{dest}")
          else
            [
              %(tar #{exclude_list.join(' ')} -hcf - -C "#{File.dirname(src)}" "#{File.basename(src)}"),
              %(#{docker_cmd} exec -i "#{container_id}" tar -C "#{dest}" -xf -),
            ].join(' | ')
          end

    `#{cmd}`
  elsif rsync_functional_on?(sut)
    # This makes rsync_to work like beaker and scp usually do
    exclude_hack = %(__-__' -L --exclude '__-__)

    # There appears to be a single copy of 'opts' that gets passed around
    # through all of the different hosts so we're going to make a local deep
    # copy so that we don't destroy the world accidentally.
    r_opts = Marshal.load(Marshal.dump(opts))
    r_opts[:ignore] ||= []
    r_opts[:ignore] << exclude_hack

    if File.directory?(src)
      dest = File.join(dest, File.basename(src)) if File.directory?(src)
      sut.mkdir_p(dest)
    end

    # End rsync hackery

    begin
      rsync_to(sut, src, dest, r_opts)
    rescue
      # Depending on what is getting tested, a new SSH session might not
      # work. In this case, we fall back to SSH.
      #
      # The rsync failure is quite fast so this doesn't affect performance as
      # much as shoving a bunch of data over the ssh session.
      scp_to(sut, src, dest, opts)
    end
  else
    scp_to(sut, src, dest, opts)
  end
end
