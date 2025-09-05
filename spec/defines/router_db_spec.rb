# frozen_string_literal: true

require 'spec_helper'
describe 'rancid::router_db' do
  let(:title) { 'group1' }

  let(:facts) do
    {
      osfamily: 'Debian',
    }
  end

  let(:params) do
    {
      rancid_cvs_path: '/bin:/usr/bin',
    }
  end

  context 'when generating router.db' do
    let(:params) do
      super().merge(
        {
          devices: {
            'group1' => {
              'foo.mydomain' => {
                'hostname' => 'foo.mydomain',
                'type' => 'cisco',
                'status' => 'up',
              },
            },
          },
          router_db_mode: '0123',
        },
      )
    end

    it 'uses the correct field separator' do
      is_expected.to contain_file('/var/lib/rancid/group1/router.db')
        .with_content(/^foo.mydomain;cisco;up$/)
        .with_owner('rancid')
        .with_group('rancid')
        .with_mode('0123')
    end
  end

  context 'with multiple entries for a group' do
    let(:params) do
      super().merge(
        {
          devices: {
            'group1' => {
              'foo.mydomain' => {
                'hostname' => 'foo.mydomain',
                'type' => 'cisco',
                'status' => 'up',
              },
              'bar.mydomain' => {
                'hostname' => 'bar.mydomain',
                'type' => 'dnos10',
                'status' => 'up',
              },
            },
          },
          router_db_mode: '0123',
        },
      )
    end

    it 'router.db is stable' do
      is_expected.to contain_file('/var/lib/rancid/group1/router.db')
        .with_content(/\Abar.mydomain;dnos10;up\nfoo.mydomain;cisco;up\Z/)
        .with_owner('rancid')
        .with_group('rancid')
        .with_mode('0123')
    end
  end

  context 'with remote urls' do
    context 'when we are managing them' do
      let(:params) do
        super().merge(
          {
            vcs_remote_urls: {
              'group1' => 'http://my-server/my-path.git',
            },
          },
        )
      end

      it 'points at the requested remote url' do
        is_expected.to contain_exec('setup git remote group1')
          .with_command('git remote set-url origin http://my-server/my-path.git')
          .with_cwd('/var/lib/rancid/group1')
      end

      it 'deploys a post commit hook to auto-push to the remote' do
        is_expected.to contain_file('post-commit hook for group1')
      end

      it 'removes the default (local) remote' do
        is_expected.to contain_file('rancid default git remote group1')
      end
    end

    context 'when we are not managing them' do
      let(:params) do
        super().merge(
          {},
        )
      end

      it {
        is_expected.not_to contain_exec(/setup git remote/)
      }
    end
  end
end
