require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'

unless ENV['RS_PROVISION'] == 'no'
  # This will install the latest available package on el and deb based
  # systems fail on windows and osx, and install via gem on other *nixes
  foss_opts = { default_action: 'gem_install' }
  default.is_pe? ? install_pe : install_puppet(foss_opts)

  hosts.each do |host|
    if %r{debian}.match?(host['platform'])
      on host, 'echo \'export PATH=/var/lib/gems/1.8/bin/:${PATH}\' >> ~/.bashrc'
    end

    on host, "mkdir -p #{host['distmoduledir']}"
  end
end

UNSUPPORTED_PLATFORMS = ['Suse', 'windows', 'AIX', 'Solaris'].freeze

module LocalHelpers
  def gpg(gpg_cmd, options = { user: 'root', acceptable_exit_codes: [0] }, &block)
    user = options.delete(:user)
    gpg = "gpg #{gpg_cmd}"
    shell("su #{user} -c \"#{gpg}\"", options, &block)
  end
end

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  # Include in our local helpers, because some puppet images run
  # as diffrent users
  c.include ::LocalHelpers

  # Configure all nodes in nodeset
  c.before :suite do
    # Install module and dependencies
    hosts.each do |host|
      copy_module_to(host, source: proj_root, module_name: 'gnupg')
    end
  end
end
