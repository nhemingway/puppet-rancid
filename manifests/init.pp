# == Class: rancid
#
# Manage RANCID - http://www.shrubbery.net/rancid/
#
class rancid (
  Enum['ALL', 'YES', 'NO']       $filterpwds,
  Boolean                        $nocommstr,
  Integer[1]                     $maxrounds,
  Integer[1]                     $oldtime,
  Integer[1]                     $locktime,
  Integer[1]                     $parcount,
  Optional[Stdlib::Fqdn]         $maildomain,
  Array[String]                  $groups,
  Hash                           $devices,
  Array                          $packages,
  Stdlib::Absolutepath           $rancid_config,
  Array[Stdlib::Absolutepath]    $rancid_path_env,
  Stdlib::Absolutepath           $homedir,
  Stdlib::Absolutepath           $logdir,
  String                         $user,
  String                         $group,
  Stdlib::Absolutepath           $shell,
  Stdlib::Absolutepath           $cron_d_file,
  String                         $cloginrc_content,
  Boolean                        $show_cloginrc_diff,
  Enum['cvs', 'svn', 'git']      $vcs,
  Optional[Stdlib::Absolutepath] $vcsroot,
  Boolean                        $manage_vcs_packages,
  Hash[String,String]            $vcs_remote_urls,
) {

  $cloginrc_path = "${homedir}/.cloginrc"

  if $vcsroot == undef {
    case $vcs {
      default: {
        fail("Rancid does not support vcs ${vcs}.")
      }
      'cvs': {
        $vcsroot_real = '$BASEDIR/CVS'
      }
      'svn': {
        $vcsroot_real = '$BASEDIR/svn'
      }
      'git': {
        $vcsroot_real = '$BASEDIR/.git'
      }
    }
  } else {
    $vcsroot_real = $vcsroot
  }

  # Debian and RedHat (currently) use the same names for these packages, so no
  # need to switch on osfamily
  case $vcs { # lint:ignore:case_without_default
    'cvs': {
      $vcs_packages = ['cvs']
    }
    'svn': {
      $vcs_packages = ['subversion']
    }
    'git': {
      $vcs_packages = ['git']
    }
  }

  package { $packages:
    ensure => present,
  }

  if ($manage_vcs_packages) {
    package { $vcs_packages:
      ensure => present,
    }
  }

  group { $group:
    ensure  => present,
    system  => true,
    require => Package[$packages],
  }

  user { $user:
    ensure  => present,
    gid     => $group,
    shell   => $shell,
    home    => $homedir,
    require => Package[$packages],
  }

  file { $logdir:
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => '0750',
  }

  file { $homedir:
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => '0750',
  }

  file { $rancid_config:
    ensure  => 'file',
    owner   => $user,
    group   => $group,
    mode    => '0640',
    content => template('rancid/rancid.conf.erb'),
    require => Package[$packages],
  }

  file { $cron_d_file:
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('rancid/rancid-cron.erb'),
    require => Package[$packages],
  }

  if ( $devices ) {
    rancid::router_db { $groups:
      devices         => $devices,
      rancid_path_env => $rancid_path_env,
      vcs_remote_urls => $vcs_remote_urls,
      subscribe       => File[$rancid_config],
      require         => Package[$packages],
    }
  }

  file { 'rancid_cloginrc':
    ensure    => file,
    path      => $cloginrc_path,
    owner     => $user,
    group     => $group,
    mode      => '0600',
    show_diff => $show_cloginrc_diff,
    content   => $cloginrc_content,
  }
}
