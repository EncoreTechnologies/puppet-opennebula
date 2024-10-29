# @summary Utility class that sets up all front end config
class opennebula::frontend::config {
  $rpc_endpoint = $opennebula::rpc_endpoint
  $public_fireedge_endpoint = $opennebula::public_fireedge_endpoint
  $vnc_proxy_support_wss = $opennebula::vnc_proxy_support_wss
  $vnc_proxy_cert = $opennebula::ssl_cert_path
  $vnc_proxy_key = $opennebula::ssl_key_path
  $owner = $opennebula::owner
  $owner_group = $opennebula::owner_group
  $onhv_user = $opennebula::onhv_user
  $onhv_passwd = $opennebula::onhv_passwd
  $db_server = $opennebula::db_server
  $db_port = $opennebula::db_port
  $db_user = $opennebula::db_user
  $db_passwd = $opennebula::db_passwd
  $use_ldap_auth = $opennebula::use_ldap_auth
  $ldap_user = $opennebula::ldap_user
  $ldap_user_passwd = $opennebula::ldap_user_passwd
  $ldap_server = $opennebula::ldap_server
  $ldap_port = $opennebula::ldap_port
  $ldap_search_base = $opennebula::ldap_search_base
  $ldap_groups = $opennebula::ldap_groups
  $server_id = $opennebula::server_id
  $hook_script = $opennebula::hook_script
  $floating_ip_cidr = $opennebula::floating_ip_cidr
  $failover_iface_name = $opennebula::failover_iface_name
  $token = $opennebula::token
  $host_attributes = $opennebula::host_attributes
  $host_attributes_tmpl_dir = $opennebula::host_attributes_tmpl_dir
  $election_timeout = $opennebula::election_timeout

  if $use_ldap_auth {
    $_default_auth = 'ldap'

    if $server_id == -1 or $facts['is_onhv_ha_initialized'] != undef {
      file { '/var/lib/one/ldap.yaml':
        ensure => 'file',
        owner  => $owner,
        group  => $owner_group,
      }

      file { '/var/lib/one/onhv_ldap_group_check.py':
        ensure  => 'file',
        owner   => $owner,
        group   => $owner_group,
        mode    => '0700',
        content => epp('opennebula/frontend/auth/onhv_ldap_group_check.py.epp', {
            ldap_groups => $ldap_groups.to_json,
            ldap_file   => '/var/lib/one/ldap.yaml',
        }),
      }

      file { '/var/lib/one/onhv_ldap_groups.py':
        ensure  => 'file',
        owner   => $owner,
        group   => $owner_group,
        mode    => '0700',
        content => epp('opennebula/frontend/auth/onhv_ldap_groups.py.epp', {
            ldap_groups => $ldap_groups.to_json,
            ldap_file   => '/var/lib/one/ldap.yaml',
        }),
      }

      exec { 'Update ldap groups':
        command => '/bin/python3 /var/lib/one/onhv_ldap_groups.py',
        unless  => '/bin/python3 /var/lib/one/onhv_ldap_group_check.py',
        require => [
          File['/var/lib/one/onhv_ldap_groups.py'],
          Service['opennebula'],
        ],
      }

      file { '/etc/one/auth/ldap_auth.conf':
        ensure  => 'file',
        owner   => $owner,
        group   => $owner_group,
        mode    => '0640',
        content => epp('opennebula/frontend/auth/ldap_auth.conf.epp', {
            ldap_user        => $ldap_user,
            ldap_user_passwd => $ldap_user_passwd,
            ldap_server      => $ldap_server,
            ldap_port        => $ldap_port,
            ldap_search_base => $ldap_search_base,
        }),
      }
    }
  } else {
    $_default_auth = 'default'
  }

  if $facts['is_onhv_ha_initialized'] == undef {
    $_server_id = -1
  } else {
    $_server_id = $server_id
  }

  file { '/etc/one/sunstone-server.conf':
    ensure  => 'file',
    notify  => Service['opennebula'],
    owner   => $owner,
    group   => $owner_group,
    mode    => '0640',
    content => epp('opennebula/frontend/config/sunstone-server.conf.epp', {
        public_fireedge_endpoint => $public_fireedge_endpoint,
        vnc_proxy_support_wss    => $vnc_proxy_support_wss,
        vnc_proxy_cert           => $vnc_proxy_cert,
        vnc_proxy_key            => $vnc_proxy_key,
        token                    => $token,
    }),
  }

  file { '/etc/one/monitord.conf':
    ensure  => 'file',
    notify  => Service['opennebula'],
    owner   => $owner,
    group   => $owner_group,
    mode    => '0640',
    content => epp('opennebula/frontend/config/monitord.conf.epp', {
        floating_ip_cidr => $floating_ip_cidr,
        server_id        => $_server_id,
    }),
  }

  file { '/etc/one/oned.conf':
    ensure  => 'file',
    notify  => Service['opennebula'],
    owner   => $owner,
    group   => $owner_group,
    mode    => '0640',
    content => epp('opennebula/frontend/config/oned.conf.epp', {
        db_server           => $db_server,
        db_port             => $db_port,
        db_user             => $db_user,
        db_passwd           => $db_passwd,
        default_auth        => $_default_auth,
        hook_script         => $hook_script,
        floating_ip_cidr    => $floating_ip_cidr,
        failover_iface_name => $failover_iface_name,
        server_id           => $_server_id,
    }),
  }

  file { '/var/lib/one/.one/one_auth':
    ensure  => 'file',
    owner   => $owner,
    group   => $owner_group,
    mode    => '0600',
    content => "${onhv_user}:${onhv_passwd}",
  }

  file { '/var/lib/one/onhv_host_attributes.py':
    ensure  => 'file',
    owner   => $owner,
    group   => $owner_group,
    mode    => '0700',
    content => epp('opennebula/frontend/config/onhv_host_attributes.py.epp', {
        host_attributes_tmpl_dir => $host_attributes_tmpl_dir,
        election_timeout         => $election_timeout,
    }),
  }

  file { '/var/lib/one/onhv_host_attributes_check.py':
    ensure  => 'file',
    owner   => $owner,
    group   => $owner_group,
    mode    => '0700',
    content => epp('opennebula/frontend/config/onhv_host_attributes_check.py.epp', {
        election_timeout         => $election_timeout,
    }),
  }

  if !$host_attributes.empty and ($server_id == -1 or $server_id == 0) {
    file { $host_attributes_tmpl_dir:
      ensure => 'directory',
      owner  => $owner,
      group  => $owner_group,
    }

    $host_attributes.each |$hostname, $attributes| {
      file { "${host_attributes_tmpl_dir}/${hostname}_attributes.txt":
        ensure  => 'file',
        owner   => $owner,
        group   => $owner_group,
        content => epp('opennebula/frontend/config/onhv_host_attributes.txt.epp', {
            attributes  => $attributes,
        }),
        require => File[$host_attributes_tmpl_dir],
      }

      exec { "update host ${hostname} attributes":
        command => "/bin/python3 /var/lib/one/onhv_host_attributes.py ${hostname}",
        onlyif  => "/bin/python3 /var/lib/one/onhv_host_attributes_check.py ${hostname} '${$attributes.to_json}'",
        require => [
          File['/var/lib/one/onhv_host_attributes.py'],
          File['/var/lib/one/onhv_host_attributes_check.py'],
          Service['opennebula']
        ],
      }
    }
  }
}
