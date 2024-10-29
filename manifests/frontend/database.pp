# @summary Utility class that installs database
class opennebula::frontend::database {
  $db_user = $opennebula::db_user
  $db_passwd = $opennebula::db_passwd
  $db_svc_user = $opennebula::db_svc_user
  $db_svc_passwd = $opennebula::db_svc_passwd
  $db_root_passwd = $opennebula::db_root_passwd
  $log_dir = $opennebula::log_dir
  $db_backup_script = $opennebula::db_backup_script
  $db_backup_nfs_mount = $opennebula::db_backup_nfs_mount
  $ds_for_db_backups = $opennebula::ds_for_db_backups
  $db_backup_dir = $opennebula::db_backup_dir
  $db_log_expire_seconds = $opennebula::db_log_expire_seconds
  $server_id = $opennebula::server_id

  $_maj = $facts['os']['release']['major']
  $_arch = $facts['os']['architecture']

  # Reason for using the community version instead of the streams version is that opennebula
  # depends on a package installed in the community version that is not in the streams version
  yumrepo { 'mysql':
    name     => 'mysql',
    descr    => 'Mysql Community Edition',
    baseurl  => "http://repo.mysql.com/yum/mysql-8.0-community/el/${_maj}/${_arch}/",
    gpgkey   => 'https://repo.mysql.com/RPM-GPG-KEY-mysql-2023',
    enabled  => 1,
    gpgcheck => 1,
  }

  package { 'mysql-community-server':
    ensure  => 'installed',
  }

  service { 'mysqld':
    ensure => 'running',
    enable => true,
  }

  file { $db_backup_script:
    ensure  => 'file',
    mode    => '0700',
    content => epp('opennebula/frontend/database/mysql_backup.sh.epp', {
        db_svc_user    => $db_svc_user,
        db_svc_passwd  => $db_svc_passwd,
        db_backup_path => "${db_backup_nfs_mount}${ds_for_db_backups}${db_backup_dir}",
        log_dir        => $log_dir,
    }),
    require => Service['mysqld'],
  }

  if str2bool($facts['mysql_init_script_ran']) != true {
    file { '/tmp/opennebula_mysql_init_script.sh':
      ensure  => 'file',
      mode    => '0700',
      content => epp('opennebula/frontend/database/mysql_init.sh.epp', {
          db_user        => $db_user,
          db_passwd      => $db_passwd,
          db_root_passwd => $db_root_passwd,
          db_svc_user    => $db_svc_user,
          db_svc_passwd  => $db_svc_passwd,
          log_dir        => $log_dir,
          server_id      => $server_id,
      }),
      require => Service['mysqld'],
    }

    exec { 'mysql init script':
      command => '/bin/bash /tmp/opennebula_mysql_init_script.sh',
      require => File['/tmp/opennebula_mysql_init_script.sh'],
    }

    facter::fact { 'mysql_init_script_ran':
      value   => true,
      require => Exec['mysql init script'],
    }

    facter::fact { 'db_type':
      value   => join(['mysql'], ','),
      require => Exec['mysql init script'],
    }

    exec { 'delete init script':
      command => '/bin/rm -f /tmp/opennebula_mysql_init_script.sh',
      require => Exec['mysql init script'],
    }
  }

  # The default for this retention is 30 days which uses a fair amount of space.
  # we lower it to three days
  file_line { 'set onhv mysql binlog expire duration':
    ensure => 'present',
    path   => '/etc/my.cnf',
    line   => "binlog_expire_logs_seconds=${db_log_expire_seconds}",
    after  => '^\[mysqld\]',
    notify => Service['mysqld'],
  }
}
