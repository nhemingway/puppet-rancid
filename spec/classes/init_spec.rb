# frozen_string_literal: true

require 'spec_helper'
describe 'rancid' do
  context 'with default params on EL 6' do
    let(:facts) do
      {
        osfamily: 'RedHat',
        operatingsystemmajrelease: '6',
      }
    end

    it { is_expected.to compile.with_all_deps }

    context 'with show_cloginrc_diff unset' do
      it { is_expected.to contain_file('rancid_cloginrc').with_show_diff('true') }
    end

    context 'with show_cloginrc_diff set to true' do
      let(:params) { { show_cloginrc_diff: true } }

      it { is_expected.to contain_file('rancid_cloginrc').with_show_diff('true') }
    end

    context 'with show_cloginrc_diff set to false' do
      let(:params) { { show_cloginrc_diff: false } }

      it { is_expected.to contain_file('rancid_cloginrc').with_show_diff('false') }
    end
  end

  context 'with default params on osfamily Debian' do
    let(:facts) do
      {
        osfamily: 'Debian',
      }
    end

    it { is_expected.to compile.with_all_deps }

    context 'with show_cloginrc_diff unset' do
      it { is_expected.to contain_file('rancid_cloginrc').with_show_diff('true') }
    end

    context 'with show_cloginrc_diff set to true' do
      let(:params) { { show_cloginrc_diff: true } }

      it { is_expected.to contain_file('rancid_cloginrc').with_show_diff('true') }
    end

    context 'with show_cloginrc_diff set to false' do
      let(:params) { { show_cloginrc_diff: false } }

      it { is_expected.to contain_file('rancid_cloginrc').with_show_diff('false') }
    end
  end

  context 'when switching version control systems' do
    let(:facts) do
      {
        osfamily: 'Debian',
      }
    end

    context 'when cvs' do
      let(:params) { { vcs: 'cvs' } }

      it do
        is_expected.to contain_file('rancid_config')
          .with_content(/^RCSSYS=cvs;/)
          .with_content(%r{^CVSROOT=\$BASEDIR/CVS;})
      end
    end

    context 'when cvs with a root' do
      let(:params) { { vcs: 'cvs', vcsroot: '/my/repo' } }

      it do
        is_expected.to contain_file('rancid_config')
          .with_content(/^RCSSYS=cvs;/)
          .with_content(%r{^CVSROOT=/my/repo;})
      end
    end

    context 'when svn' do
      let(:params) { { vcs: 'svn' } }

      it do
        is_expected.to contain_file('rancid_config')
          .with_content(%r{^CVSROOT=\$BASEDIR/svn;})
          .with_content(/^RCSSYS=svn;/)
      end
    end

    context 'when svn with a root' do
      let(:params) { { vcs: 'svn', vcsroot: '/my/repo' } }

      it do
        is_expected.to contain_file('rancid_config')
          .with_content(/^RCSSYS=svn;/)
          .with_content(%r{^CVSROOT=/my/repo;})
      end
    end

    context 'when git' do
      let(:params) { { vcs: 'git' } }

      it do
        is_expected.to contain_file('rancid_config')
          .with_content(%r{^CVSROOT=\$BASEDIR/.git;})
          .with_content(/^RCSSYS=git;/)
      end
    end

    context 'when git with a root' do
      let(:params) { { vcs: 'git', vcsroot: '/my/repo' } }

      it do
        is_expected.to contain_file('rancid_config')
          .with_content(/^RCSSYS=git;/)
          .with_content(%r{^CVSROOT=/my/repo;})
      end
    end

    context 'when managing packages' do
      context 'when true - git' do
        let(:params) { { vcs: 'git', manage_vcs_packages: true } }

        it { is_expected.to contain_package('git') }
        it { is_expected.not_to contain_package('subversion') }
        it { is_expected.not_to contain_package('cvs') }
      end

      context 'when true - svn' do
        let(:params) { { vcs: 'svn', manage_vcs_packages: true } }

        it { is_expected.not_to contain_package('git') }
        it { is_expected.to contain_package('subversion') }
        it { is_expected.not_to contain_package('cvs') }
      end

      context 'when true - cvs' do
        let(:params) { { vcs: 'cvs', manage_vcs_packages: true } }

        it { is_expected.not_to contain_package('git') }
        it { is_expected.not_to contain_package('subversion') }
        it { is_expected.to contain_package('cvs') }
      end

      context 'when false' do
        let(:params) { { vcs: 'git', manage_vcs_packages: false } }

        it { is_expected.not_to contain_package('git') }
        it { is_expected.not_to contain_package('subversion') }
        it { is_expected.not_to contain_package('cvs') }
      end
    end
  end
end
