# frozen_string_literal: true

module LocalHelpers
  def gpg(gpg_cmd, options = { user: 'root', acceptable_exit_codes: [0] }, &block)
    user = options.delete(:user)
    gpg = "gpg #{gpg_cmd}"
    shell("su #{user} -c \"#{gpg}\"", options, &block)
  end
end

RSpec::Matchers.define(:be_one_of) do |expected|
  match do |actual|
    expected.include?(actual)
  end

  failure_message do |actual|
    "expected one of #{expected}, got #{actual}"
  end
end

RSpec.configure do |c|
  c.include ::LocalHelpers
end
