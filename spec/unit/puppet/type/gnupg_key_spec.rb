require 'puppet'
require 'puppet/type/gnupg_key'

describe Puppet::Type.type(:gnupg_key) do
  let(:gnupg_key) { Puppet::Type.type(:gnupg_key).new(name: 'foo') }

  it 'accepts a user' do
    gnupg_key[:user] = 'root'
    expect(gnupg_key[:user]).to eq 'root'
  end

  it 'requires a key_source or key_server if ensure present' do
    expect {
      Puppet::Type.type(:gnupg_key).new(name: 'foo', user: 'root', ensure: 'present')
    }.to raise_error(%r{You need to specify at least one of*})
  end

  it 'ignores key_source or key_server value if ensure absent' do
    gnupg_key[:ensure] = 'absent'
    expect(gnupg_key[:ensure]). to eq :absent
  end

  it 'requires a name' do
    expect {
      Puppet::Type.type(:gnupg_key).new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

  it 'does not allow invalid formated user' do
    expect {
      gnupg_key[:user] = '1foo'
    }.to raise_error(Puppet::Error, %r{Invalid username format for*})
  end

  it 'accepts user names with dashes' do
    gnupg_key[:user] = 'foo-bar'
  end

  ['http://pkg.jenkins.io/debian/jenkins.io.key', 'ldap://keys.puppetlabs.com', 'hkp://pgp.mit.edu/'].each do |val|
    it "accepts key_server #{val}" do
      gnupg_key[:key_server] = val
      expect(gnupg_key[:key_server]).to eq val.to_s
    end
  end

  ['puppet:///modules/gnupg/random.key', 'http://www.puppetlabs.com/key.key', 'https://www.puppetlabs.com/key.key', 'file:///etc/foo.key', '/etc/foo.key'].each do |val|
    it "accepts key_source #{val}" do
      gnupg_key[:key_source] = val
      expect(gnupg_key[:key_source]).to eq val.to_s.gsub('file://', '')
    end
  end

  it 'does not accept invalid formated key_source URI' do
    expect {
      gnupg_key[:key_source] = 'httk://foo.bar/'
    }.to raise_error(Puppet::Error)
  end

  it 'does not accept invalid formated proxy URL' do
    expect {
      gnupg_key[:proxy] = 'httk://foo.bar/'
    }.to raise_error(Puppet::Error)
  end

  ['20BC0A86', 'D50582e6', '20BC0a86', '9B7D32F2D50582E6', '3CCe8BC520bc0A86'].each do |val|
    it "allows key_id with #{val}" do
      gnupg_key[:key_id] = val
      expect(gnupg_key[:key_id]).to eq val.upcase.to_sym
    end
  end

  ['ABCD', '1234567G', 'ASA1321', 'q321asd'].each do |val|
    it "does not allow key_id with #{val}" do
      expect {
        gnupg_key[:key_id] = val
      }.to raise_error(%r{Invalid key id*})
    end
  end

  [:public, :private, :both].each do |val|
    it "allows key_type with #{val}" do
      gnupg_key[:key_type] = val
      expect(gnupg_key[:key_type]).to eq val
    end
  end

  it 'has a key_type of public by default' do
    expect(gnupg_key[:key_type]).to eq :public
  end

  [:special, :other].each do |val|
    it "does not allow invalid key_type of #{val}" do
      expect {
        gnupg_key[:key_type] = val
      }.to raise_error(Puppet::Error)
    end
  end

  it 'does not allow key_type of both when ensure is present' do
    expect {
      Puppet::Type.type(:gnupg_key).new(name: 'key', ensure: 'present', key_type: 'both', key_source: 'http://www.example.com')
    }.to raise_error(%r{A key type of 'both' is invalid when ensure is 'present'\.})
  end

  it 'allows key_content with armored public key' do
    key = File.read('files/test.public.key')
    resource = Puppet::Type.type(:gnupg_key).new(name: 'key', key_type: 'public', key_content: key)
    expect(resource[:key_content]).to eq key
  end

  it 'allows key_content with armored private key' do
    key = File.read('files/random.private.key')
    resource = Puppet::Type.type(:gnupg_key).new(name: 'key', key_type: 'private', key_content: key)
    expect(resource[:key_content]).to eq key
  end

  it 'does not allow key_content that does not look like a public key when key_type is public' do
    key = 'I am not a public key'
    expect {
      Puppet::Type.type(:gnupg_key).new(name: 'key', key_type: 'public', key_content: key)
    }.to raise_error(%r{Provided key content does not look like a public key\.})
  end

  it 'does not allow key_content that does not look like a private key when key_type is private' do
    key = 'I am not a private key'
    expect {
      Puppet::Type.type(:gnupg_key).new(name: 'key', key_type: 'private', key_content: key)
    }.to raise_error(%r{Provided key content does not look like a private key\.})
  end
end
