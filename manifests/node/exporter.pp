# @summary class that sets up all open nebula node based prometheus exporters
#
# @note Only the EE edition of OpenNebula gets access to the native opennebula-prometheus exporters
#       CE edition will have to make use of different / open source exporters (TBD)
class opennebula::node::exporter {
  $edition               = $opennebula::edition
  $codeready_repo        = $opennebula::codeready_repo
  $firewalld_libvirt_exporter_ports = $opennebula::firewalld_libvirt_exporter_ports
  $firewalld_libvirt_exporter_svc   = $opennebula::firewalld_libvirt_exporter_svc

  if $edition == 'EE' {
    # Enable codeready repo for installing mysql-libs
    exec { 'enable_codeready_repo':
      command => "/sbin/subscription-manager repos --enable=${codeready_repo}",
      before  => Package['opennebula-prometheus-kvm'],
      unless  => "/sbin/subscription-manager repos --list-enabled | grep '${codeready_repo}'",
    }

    package { ['opennebula-prometheus-kvm']:
      ensure  => 'installed',
    }

    service { ['opennebula-libvirt-exporter', 'opennebula-node-exporter']:
      ensure  => 'running',
      enable  => true,
      require => Package['opennebula-prometheus-kvm'],
    }

    # Open ports for our libvirt exporter on the hypervisor
    ensure_resources('firewalld::custom_service', $firewalld_libvirt_exporter_ports)
    ensure_resources('firewalld_service', $firewalld_libvirt_exporter_svc)
  }

  if $edition == 'CE' {
    notify { 'Puppet does not currently support the CE edition of open nebula.' : }
  }
}
