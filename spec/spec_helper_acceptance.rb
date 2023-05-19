# frozen_string_literal: true

Dir['./spec/support/acceptance/**/*.rb'].sort.each { |f| require f }

RSpec.configure do |c|
  c.before :suite do
    filedir = File.join(File.dirname(File.dirname(__FILE__)), 'files')
    testkeys = [
      'random.private.key',
      'test.public.key',
      'test2.public.key',
    ]
    hosts.each do |host|
      puts 'Copying fixture files to hosts'
      testkeys.each do |keyfile|
        copy_to(host, File.join(filedir, keyfile), "/tmp/#{keyfile}")
      end
    end
  end
end
