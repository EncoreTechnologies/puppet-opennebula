# @summary Utility class that sets up ssh
class opennebula::frontend::ssh {
  $home_dir        = $opennebula::home_dir
  $ssh_priv_key    = $opennebula::oa_privkey
  $ssh_pub_key     = $opennebula::oa_pubkey

  $owner = $opennebula::owner
  $owner_group = $opennebula::owner_group

  # Setup SSH keys for oneadmin user
  file { "${home_dir}/.ssh":
    ensure => directory,
    owner  => $owner,
    group  => $owner_group,
    mode   => '0700',
  }

  file { "${home_dir}/.ssh/id_oneadmin":
    ensure  => file,
    content => $ssh_priv_key,
    owner   => $owner,
    group   => $owner_group,
    mode    => '0600',
  }

  file { "${home_dir}/.ssh/id_oneadmin.pub":
    ensure  => file,
    content => $ssh_pub_key,
    owner   => 'oneadmin',
    group   => 'oneadmin',
    mode    => '0644',
  }

  file { "${home_dir}/.ssh/authorized_keys":
    ensure => file,
    owner  => $owner,
    group  => $owner_group,
    mode   => '0600',
  }

  file_line { 'add_oneadmin_pubkey':
    path    => "${home_dir}/.ssh/authorized_keys",
    line    => $ssh_pub_key,
    require => File["${home_dir}/.ssh/authorized_keys"],
  }

  file { "${home_dir}/.ssh/config":
    ensure  => 'file',
    owner   => $owner,
    group   => $owner_group,
    mode    => '0600',
    content => epp('opennebula/frontend/ssh/config.epp', {
        identity_file => "${home_dir}/.ssh/id_oneadmin",
    }),
  }
}
