require 'spec_helper_acceptance'

describe 'gnupg' do
  let(:pp) { "class { 'gnupg': }" }

  it 'behaves idempotently' do
    idempotent_apply(pp)
  end
end
