# @summary Default parameters for opennebula module.
#
class opennebula::params {
  $firewalld_svcs = {
    'ssh' => {
      ensure => 'present',
    },
    'libvirt' => {
      ensure => 'present',
    },
    'opennebula-node' => {
      ensure => 'present',
    },
  }

  $firewalld_frontend_svcs = {
    'opennebula' => {
      ensure => 'present',
    },
  }

  $firewalld_node_ports = {
    'opennebula-node' => {
      short => 'opennebula-node',
      description => 'OpenNebula Node',
      port => [
        {
          'port' => '5900-6999',
          'protocol' => 'tcp',
        },
        {
          'port' => '49152-49252',
          'protocol' => 'tcp',
        },
      ],
    },
  }

  $firewalld_ports = {
    opennebula => {
      short => 'opennebula',
      description => 'OpenNebula',
      port => [
        {
          'port' => '2474',
          'protocol' => 'tcp',
        },
        {
          'port' => '2616',
          'protocol' => 'tcp',
        },
        {
          'port' => '2633',
          'protocol' => 'tcp',
        },
        {
          'port' => '4124',
          'protocol' => 'tcp',
        },
        {
          'port' => '4124',
          'protocol' => 'udp',
        },
        {
          'port' => '5030',
          'protocol' => 'tcp',
        },
        {
          'port' => '9869',
          'protocol' => 'tcp',
        },
        {
          'port' => '29876',
          'protocol' => 'tcp',
        },
      ],
    },
  }

  $firewalld_libvirt_exporter_svc = {
    'opennebula-libvirt-exporter' => {
      ensure => 'present',
    },
  }

  $firewalld_libvirt_exporter_ports = {
    'opennebula-libvirt-exporter' => {
      short => 'opennebula-libvirt-exporter',
      description => 'OpenNebula Libvirt Node Based Exporter',
      port => [
        {
          'port' => '9926',
          'protocol' => 'tcp',
        },
      ],
    },
  }

  $firewalld_onhv_exporter_svc = {
    'opennebula-onhv-exporter' => {
      ensure => 'present',
    },
  }

  $firewalld_onhv_exporter_ports = {
    'opennebula-onhv-exporter' => {
      short => 'opennebula-onhv-exporter',
      description => 'OpenNebula Onhv Frontend Based Exporter',
      port => [
        {
          'port' => '9925',
          'protocol' => 'tcp',
        },
      ],
    },
  }

  $qemu_dynamic_ownership = 1
}
