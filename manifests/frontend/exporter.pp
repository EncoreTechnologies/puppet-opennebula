# @summary class that sets up all open nebula front end prometheus exporters
#
# @note Only the EE edition of OpenNebula gets access to the native opennebula-prometheus exporters
#       CE edition will have to make use of different / open source exporters (TBD)
class opennebula::frontend::exporter {
  $edition                       = $opennebula::edition
  $firewalld_onhv_exporter_ports = $opennebula::firewalld_onhv_exporter_ports
  $firewalld_onhv_exporter_svc   = $opennebula::firewalld_onhv_exporter_svc

  if $edition == 'EE' {
    package { ['opennebula-prometheus', 'opennebula-prometheus-kvm']:
      ensure  => 'installed',
    }

    service { ['opennebula-exporter', 'opennebula-node-exporter']:
      ensure  => 'running',
      enable  => true,
      require => Package['opennebula-prometheus-kvm'],
    }

    # Open ports for our ONHV exporter on the hypervisor
    ensure_resources('firewalld::custom_service', $firewalld_onhv_exporter_ports)
    ensure_resources('firewalld_service', $firewalld_onhv_exporter_svc)
  }

  if $edition == 'CE' {
    notify { 'Puppet does not currently support the CE edition of open nebula.' : }
  }
}
