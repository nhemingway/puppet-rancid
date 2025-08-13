# == Define: rancid::router_db
#
define rancid::router_db (
  Hash                        $devices         = {},
  Array[Stdlib::Absolutepath] $rancid_path_env = [ '/bin', '/usr/bin' ],
  String                      $router_db_mode  = '0640',
  Hash[String,String]         $vcs_remote_urls = {},
) {
  include rancid

  Exec {
    path => $rancid_path_env.join(':'),
  }

  exec { "rancid-cvs-${name}":
    command => "rancid-cvs ${name}",
    user    => $rancid::user,
    unless  => "test -d ${rancid::homedir}/${name}/CVS",
  }

  if ( $vcs_remote_urls[$name] ) {
    $remote_url = $vcs_remote_urls[$name]
    exec { "setup git remote ${name}":
      command => "git remote set-url origin ${remote_url}",
      cwd     => "${rancid::homedir}/${name}",
      user    => $rancid::user,
      unless  => "git remote -v | grep ${remote_url}",
    }

    file { "post-commit hook for ${name}":
      path    => "${rancid::homedir}/${name}/.git/hooks/post-commit",
      content => "git push origin\n",
      owner   => $rancid::user,
      group   => $rancid::group,
      mode    => '0755',
    }

    file { "rancid default git remote ${name}":
      ensure => absent,
      path   => "${rancid::homedir}/.git/${name}",
      force  => true,
      backup => false,
    }
  }

  if ( $devices[$name] ) {
    file { "${rancid::homedir}/${name}/router.db":
      ensure  => 'file',
      owner   => $rancid::user,
      group   => $rancid::group,
      mode    => $router_db_mode,
      content => template('rancid/router.db.erb'),
      require => Exec["rancid-cvs-${name}"],
    }
  } else {
    notify { "rancid::router_db -- ${name} not found in devices hash.": }
  }
}
