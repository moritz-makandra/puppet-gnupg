# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'manage gnupg keys' do
  before(:all) do
    filedir = File.join(File.dirname(File.dirname(File.dirname(__FILE__))), 'files')
    testkeys = [
      'random.private.key',
      'test.public.key',
      'test2.public.key',
    ]
    testkeys.each do |keyfile|
      bolt_upload_file(File.join(filedir, keyfile), "/tmp/#{keyfile}")
    end
  end

  pp = <<~EOS
    include gnupg
    EOS

  context 'add keys various ways' do
    let(:manifest) do
      <<~EOS
      #{pp}
      gnupg_key { 'hkp_server-puppet_module_gnupg_testing_key':
        ensure     => 'present',
        user       => 'root',
        key_type   => 'public',
        key_server => 'hkp://keys.openpgp.org:80/',
        key_id     => '4C589D9E8E04A1D3',
      }
      gnupg_key { 'puppet_source':
        ensure     => 'present',
        user       => 'root',
        key_type   => 'public',
        key_id     => '926FA9B9',
        key_source => 'puppet:///modules/gnupg/test.public.key',
      }
      gnupg_key { 'content':
        ensure      => 'present',
        user        => 'root',
        key_id      => '58AA73E230EB06B2A2DE8A873CCE8BC520BC0A86',
        key_type    => 'public',
        key_content => file('gnupg/test2.public.key'),
      }
      EOS
    end

    it 'behaves idempotently' do
      idempotent_apply(manifest)
    end

    describe command('gpg --list-keys 4FDE866E31AF4DA20D8908824C589D9E8E04A1D3') do
      its(:stdout) { is_expected.to contain('4FDE866E31AF4DA20D8908824C589D9E8E04A1D3') }
    end

    describe command('gpg --list-keys 7F2A6D3944CDFE31A47ECC2A60135C26926FA9B9') do
      its(:stdout) { is_expected.to contain('7F2A6D3944CDFE31A47ECC2A60135C26926FA9B9') }
    end

    describe command('gpg --list-keys 58AA73E230EB06B2A2DE8A873CCE8BC520BC0A86') do
      its(:stdout) { is_expected.to contain('58AA73E230EB06B2A2DE8A873CCE8BC520BC0A86') }
    end
  end

  context 'delete a public key' do
    before(:all) do
      gpg('--batch --yes --import /tmp/test.public.key')
    end

    let(:manifest) do
      <<~EOS
      #{pp}
      gnupg_key { 'delete':
        ensure   => 'absent',
        user     => 'root',
        key_type => 'public',
        key_id   => '926FA9B9',
      }
      EOS
    end

    it 'behaves idempotently' do
      idempotent_apply(manifest)
    end

    describe command('gpg --list-keys 60135C26926FA9B9') do
      its(:stdout) { is_expected.not_to contain('60135C26926FA9B9') }
    end
  end

  context 'invalid key' do
    let(:manifest) do
      <<~EOS
      #{pp}
      gnupg_key { 'delete_if_exists':
        ensure   => 'absent',
        user     => 'root',
        key_type => 'public',
        key_id   => '926FA9B9',
      }
      -> gnupg_key { 'public_key_from_invalid_header':
        ensure      => 'present',
        user        => 'root',
        key_id      => '926FA9B9',
        key_type    => 'public',
        key_content => regsubst(file('gnupg/test.public.key'), ' PGP ', ' GPG '),
      }
      EOS
    end

    it 'applies with errors' do
      apply_manifest(manifest, expect_failures: true)
    end
  end

  context 'local source does not exist' do
    let(:manifest) do
      <<~EOS
      gnupg_key { 'jenkins_key':
        ensure     => 'present',
        user       => 'root',
        key_type   => 'public',
        key_source => '/santa/claus/does/not/exists/org/sorry/kids.key',
        key_id     => '40404040',
      }
      EOS
    end

    it 'applies with errors' do
      apply_manifest(manifest, expect_failures: true)
    end
  end

  context 'install a public key from invalid URL' do
    let(:manifest) do
      <<~EOS
      gnupg_key { 'jenkins_key':
        ensure     => 'present',
        user       => 'root',
        key_type   => 'public',
        key_source => 'http://localhost/key-not-there.key',
        key_id     => '40404040',
      }
      EOS
    end

    it 'applies with errors' do
      apply_manifest(manifest, expect_failures: true)
    end
  end

  context 'install private key from local file' do
    after(:all) do
      gpg('--batch --yes --delete-secret-and-public-key 7F2A6D3944CDFE31A47ECC2A60135C26926FA9B9')
    end

    let(:manifest) do
      <<~EOS
      gnupg_key { 'add_private_key_by_local_file_path':
        ensure     => 'present',
        user       => 'root',
        key_id     => '926FA9B9',
        key_type   => 'private',
        key_source => '/tmp/random.private.key'
      }
      EOS
    end

    it 'applies with no errors' do
      apply_manifest(manifest, expect_changes: true)
    end

    describe command('gpg --list-secret-keys 926FA9B9') do
      its(:stdout) { is_expected.to contain('7F2A6D3944CDFE31A47ECC2A60135C26926FA9B9') }
    end
  end

  context 'install private key from content' do
    after(:all) do
      gpg('--batch --yes --delete-secret-and-public-key 7F2A6D3944CDFE31A47ECC2A60135C26926FA9B9')
    end

    let(:manifest) do
      <<~EOS
      gnupg_key { 'add_private_key_by_local_file_path':
        ensure      => 'present',
        user        => 'root',
        key_id      => '926FA9B9',
        key_type    => 'private',
        key_content => file('gnupg/random.private.key'),
      }
      EOS
    end

    it 'applies with no errors' do
      apply_manifest(manifest, expect_changes: true)
    end

    describe command('gpg --list-secret-keys 926FA9B9') do
      its(:stdout) { is_expected.to contain('7F2A6D3944CDFE31A47ECC2A60135C26926FA9B9') }
    end
  end

  context 'delete private key' do
    before(:all) do
      gpg('--batch --yes --import /tmp/random.private.key')
    end

    let(:manifest) do
      <<~EOS
      gnupg_key { 'bye_bye_key':
        ensure   => 'absent',
        user     => 'root',
        key_id   => '926FA9B9',
        key_type => 'private',
      }
      EOS
    end

    it 'applies with no errors' do
      apply_manifest(manifest, expect_changes: true)
    end

    describe command('gpg --list-secret-keys 926FA9B9') do
      its(:stdout) { is_expected.not_to contain('7F2A6D3944CDFE31A47ECC2A60135C26926FA9B9') }
    end

    describe command('gpg --list-keys 926FA9B9') do
      its(:stdout) { is_expected.to contain('7F2A6D3944CDFE31A47ECC2A60135C26926FA9B9') }
    end
  end

  context 'delete both public and private keys' do
    before(:all) do
      gpg('--batch --yes --import /tmp/random.private.key')
    end

    let(:manifest) do
      <<~EOS
      gnupg_key { 'bye_bye_key':
        ensure   => 'absent',
        user     => 'root',
        key_id   => '926FA9B9',
        key_type => 'both',
      }
      EOS
    end

    it 'applies with no errors' do
      apply_manifest(manifest, expect_changes: true)
    end

    describe command('gpg --list-secret-keys 926FA9B9') do
      its(:stdout) { is_expected.not_to contain('7F2A6D3944CDFE31A47ECC2A60135C26926FA9B9') }
    end

    describe command('gpg --list-keys 926FA9B9') do
      its(:stdout) { is_expected.not_to contain('7F2A6D3944CDFE31A47ECC2A60135C26926FA9B9') }
    end
  end

  context 'add key to specific GNUPGHOME' do
    before(:all) do
      gpg('--batch --yes --delete-key 926FA9B9', expect_failures: true)
    end

    let(:manifest) do
      <<~EOS
      file { '/store':
        ensure => directory,
      }
      -> gnupg_key { 'new':
        ensure     => 'present',
        user       => 'root',
        home       => '/store',
        key_id     => '926FA9B9',
        key_source => 'puppet:///modules/gnupg/test.public.key',
      }
      EOS
    end

    it 'applies with no errors' do
      apply_manifest(manifest, expect_changes: true)
    end

    describe command('gpg --homedir /store --list-keys 926FA9B9') do
      its(:stdout) { is_expected.to contain('7F2A6D3944CDFE31A47ECC2A60135C26926FA9B9') }
    end
  end
end
