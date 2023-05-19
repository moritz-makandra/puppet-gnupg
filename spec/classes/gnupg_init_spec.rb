require 'spec_helper'

describe 'gnupg', type: :class do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_class('gnupg::install') }
      it {
        is_expected.to contain_package('gnupg')
          .with_ensure('present')
      }

      context 'when absent' do
        let(:params) do
          {
            package_ensure: 'absent',
          }
        end

        it {
          is_expected.to contain_package('gnupg')
            .with_ensure('absent')
        }
      end
    end
  end
end
