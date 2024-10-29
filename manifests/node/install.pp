# @summary Puppet class to install OpenNebula hypervisor (node)
#
# @api private
#
class opennebula::node::install {
  $ensure          = $opennebula::ensure
  $home_dir        = $opennebula::home_dir
  $ssh_priv_key    = $opennebula::oa_privkey
  $ssh_pub_key     = $opennebula::oa_pubkey
  $dynamic_ownership = $opennebula::qemu_dynamic_ownership

  $_ensure = $ensure ? {
    'present' => 'running',
    'absent'  => 'stopped',
  }

  $_packages = ['opennebula-node-kvm', 'lldpd']
  package { $_packages:
    ensure => $ensure,
  }

  service { 'lldpd':
    ensure  => $_ensure,
  }

  # This used to be a default kernel mod but is not default any longer.
  # We need this on our hypervisors in order for our sysctl settings to apply.
  kmod::load { 'br_netfilter':
    before => Class['sysctl::base'],
  }

  # Setup SSH keys for oneadmin user
  file { "${home_dir}/.ssh":
    ensure => directory,
    owner  => 'oneadmin',
    group  => 'oneadmin',
    mode   => '0700',
  }

  file { "${home_dir}/.ssh/id_oneadmin":
    ensure  => file,
    content => $ssh_priv_key,
    owner   => 'oneadmin',
    group   => 'oneadmin',
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
    owner  => 'oneadmin',
    group  => 'oneadmin',
    mode   => '0600',
  }

  file_line { 'add_oneadmin_pubkey':
    path    => "${home_dir}/.ssh/authorized_keys",
    line    => $ssh_pub_key,
    require => File["${home_dir}/.ssh/authorized_keys"],
  }

  file { "${home_dir}/.ssh/config":
    ensure  => 'file',
    owner   => 'oneadmin',
    group   => 'oneadmin',
    mode    => '0600',
    content => epp('opennebula/frontend/ssh/config.epp', {
        identity_file => "${home_dir}/.ssh/id_oneadmin",
    }),
  }

  # if this changes we need to bounce the virtqemud daemon
  file_line { 'qemu_dynamic_ownership':
    path    => '/etc/libvirt/qemu.conf',
    line    => "dynamic_ownership = ${dynamic_ownership}",
    match   => '^dynamic_ownership =',
    require => Package['opennebula-node-kvm'],
    notify  => Service['virtqemud'],
  }

  service { 'virtqemud':
    ensure  => $_ensure,
  }
}

# vim: sw=2 ts=2 sts=2 et :
