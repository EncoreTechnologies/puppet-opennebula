# @summary Utility class that starts/enables all the front end services
class opennebula::frontend::services {
  $firewalld_ports = $opennebula::params::firewalld_ports
  $firewalld_svcs = $opennebula::params::firewalld_frontend_svcs
  $server_id = $opennebula::server_id

  ensure_resources('firewalld::custom_service', $firewalld_ports)
  ensure_resources('firewalld_service', $firewalld_svcs)

  if $server_id > 0 {
    if $facts['is_onhv_ha_initialized'] == undef {
      $_ensure = 'stopped'
    } else {
      $_ensure = 'running'
    }
  } else {
    $_ensure = 'running'
  }

  service { [
      'opennebula',
      'opennebula-sunstone',
      'opennebula-fireedge',
      'opennebula-gate',
      'opennebula-flow',
    ]:
      ensure  => $_ensure,
      enable  => true,
      require => Package['opennebula'],
  }
}
