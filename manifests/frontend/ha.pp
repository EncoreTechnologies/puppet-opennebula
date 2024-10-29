# @summary Utility class that sets up HA if configured
class opennebula::frontend::ha {
  $owner = $opennebula::owner
  $owner_group = $opennebula::owner_group

  $db_user = $opennebula::db_user
  $db_passwd = $opennebula::db_passwd
  $db_backup_nfs_mount = $opennebula::db_backup_nfs_mount
  $ds_for_db_backups = $opennebula::ds_for_db_backups
  $db_backup_dir = $opennebula::db_backup_dir
  $db_backup_script = $opennebula::db_backup_script

  # Auth params
  $auth_backup_nfs_mount  = $opennebula::auth_backup_nfs_mount
  $ds_for_auth_backup = $opennebula::ds_for_auth_backup
  $auth_backup_dir = $opennebula::auth_backup_dir

  # HA params
  $server_id = $opennebula::server_id
  $failover_iface_name = $opennebula::failover_iface_name
  $floating_ip_cidr = $opennebula::floating_ip_cidr
  $hook_script = $opennebula::hook_script
  $ha_servers = $opennebula::ha_servers
  $facts_file = $opennebula::facts_file
  $election_timeout = $opennebula::election_timeout

  $_auth_backup_path = "${auth_backup_nfs_mount}${ds_for_auth_backup}${auth_backup_dir}"

  file { '/var/lib/one/onhv_ha_follower.py':
    ensure  => 'file',
    require => Class['encore_base::profile::nfs'],
    owner   => $owner,
    group   => $owner_group,
    mode    => '0700',
    content => epp('opennebula/frontend/ha/onhv_ha_follower.py.epp', {
        auth_backup_path => $_auth_backup_path,
        db_backup_path   => "${db_backup_nfs_mount}${ds_for_db_backups}${db_backup_dir}",
        db_user          => $db_user,
        db_passwd        => $db_passwd,
    }),
  }

  file { '/var/lib/one/onhv_add_servers_check.py':
    ensure  => 'file',
    require => Service['opennebula'],
    owner   => $owner,
    group   => $owner_group,
    mode    => '0700',
    content => epp('opennebula/frontend/ha/onhv_add_servers_check.py.epp', {
        ha_servers => $ha_servers.to_json,
        server_id  => $server_id,
    }),
  }

  file { '/var/lib/one/onhv_add_servers.py':
    ensure  => 'file',
    require => Service['opennebula'],
    owner   => $owner,
    group   => $owner_group,
    mode    => '0700',
    content => epp('opennebula/frontend/ha/onhv_add_servers.py.epp', {
        auth_backup_path => $_auth_backup_path,
        ha_servers       => $ha_servers.to_json,
        election_timeout => $election_timeout,
    }),
  }

  # This should only be ran once on init
  if $facts['is_onhv_ha_initialized'] == undef {
    if $server_id > 0 {
      exec { '/var/lib/one/onhv_ha_follower.py':
        command => '/bin/python3 /var/lib/one/onhv_ha_follower.py',
        require => File['/var/lib/one/onhv_ha_follower.py'],
      }

      facter::fact { 'is_onhv_ha_initialized':
        value   => true,
        require => Exec['/var/lib/one/onhv_ha_follower.py'],
      }
    } else {
      facter::fact { 'is_onhv_ha_initialized':
        value   => true,
      }
    }
  } else {
    exec { '/var/lib/one/onhv_add_servers.py':
      command => '/bin/python3 /var/lib/one/onhv_add_servers.py',
      onlyif  => '/bin/python3 /var/lib/one/onhv_add_servers_check.py',
      require => File[
        '/var/lib/one/onhv_add_servers.py',
        '/var/lib/one/onhv_add_servers_check.py',
      ],
    }
  }
}
