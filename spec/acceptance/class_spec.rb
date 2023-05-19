require 'spec_helper_acceptance'

describe 'gnupg' do
  let(:manifest) do
    <<~PP
    class { 'gnupg': }
    PP
  end

  it_behaves_like 'an idempotent resource'
end
