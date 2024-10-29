# @summary Utility class that configures network settings for frontend
class opennebula::frontend::network {
  $frontend_if_config = $opennebula::frontend_if_config
  $manage_network = $opennebula::manage_network
  $vnets = $opennebula::vnets
  $owner = $opennebula::owner
  $owner_group = $opennebula::owner_group
  $vlan_tmpl_dir = $opennebula::vlan_tmpl_dir
  $server_id = $opennebula::server_id
  $election_timeout = $opennebula::election_timeout
  $cluster_groups = $opennebula::cluster_groups
  $default_cluster_group = $opennebula::default_cluster_group
  $default_dns = $opennebula::default_dns
  $default_provisioning_enabled = $opennebula::default_provisioning_enabled
  $default_zone = $opennebula::default_zone
  $default_ipam = $opennebula::default_ipam

  # Control interfaces for frontend
  if $manage_network == true {
    class { 'networkmanager':
      erase_unmanaged_keyfiles => true,
      no_auto_default          => true,
    }

    $_params = {
      'ensure'  => $opennebula::ensure,
      'before'  => Class['encore_base::profile::nfs'],
    }

    if !$frontend_if_config.empty {
      create_resources('networkmanager::ifc::connection', $frontend_if_config, $_params)
    }
  }

  if !$vnets.empty and ($server_id == -1 or $server_id == 0) {
    file { $vlan_tmpl_dir:
      ensure => 'directory',
      owner  => $owner,
      group  => $owner_group,
    }

    file { '/var/lib/one/onhv_cluster.py':
      ensure  => 'file',
      owner   => $owner,
      group   => $owner_group,
      mode    => '0755',
      content => epp('opennebula/frontend/network/onhv_cluster.py.epp', {
          election_timeout => $election_timeout,
          cluster_groups   => $cluster_groups.to_json,
      }),
    }

    exec { 'create clusters':
      command => '/bin/python3 /var/lib/one/onhv_cluster.py update',
      onlyif  => '/bin/python3 /var/lib/one/onhv_cluster.py check',
      require => [
        File['/var/lib/one/onhv_cluster.py'],
        Service['opennebula']
      ],
    }

    file { '/var/lib/one/onhv_network.py':
      ensure  => 'file',
      owner   => $owner,
      group   => $owner_group,
      mode    => '0755',
      content => epp('opennebula/frontend/network/onhv_network.py.epp', {
          vlan_tmpl_dir         => $vlan_tmpl_dir,
          election_timeout      => $election_timeout,
          default_cluster_group => $default_cluster_group,
          cluster_groups        => $cluster_groups.to_json,
      }),
    }

    file { '/var/lib/one/onhv_network_check.py':
      ensure  => 'file',
      owner   => $owner,
      group   => $owner_group,
      mode    => '0755',
      content => epp('opennebula/frontend/network/onhv_network_check.py.epp', {
          vlan_tmpl_dir         => $vlan_tmpl_dir,
          election_timeout      => $election_timeout,
          default_cluster_group => $default_cluster_group,
          cluster_groups        => $cluster_groups.to_json,
      }),
    }

    $vnets.each |$vlan_name, $vlan_hash| {
      if $vlan_hash['vlan'] != undef {
        if $vlan_hash['dns'] != undef {
          $_dns = $vlan_hash['dns']
        } else {
          $_dns = $default_dns
        }

        if $vlan_hash['provisioning_enabled'] != undef {
          $_provisioning_enabled = $vlan_hash['provisioning_enabled']
        } else {
          $_provisioning_enabled = $default_provisioning_enabled
        }

        if $vlan_hash['zone'] != undef {
          $_zone = $vlan_hash['zone']
        } else {
          $_zone = $default_zone
        }

        if $vlan_hash['ipam'] != undef {
          $_ipam = $vlan_hash['ipam']
        } else {
          $_ipam = $default_ipam
        }

        file { "${vlan_tmpl_dir}/${vlan_name}.txt":
          ensure  => 'file',
          owner   => $owner,
          group   => $owner_group,
          content => epp('opennebula/frontend/network/vlan.txt.epp', {
              vlan_name            => $vlan_name,
              vlan_id              => $vlan_hash['vlan'],
              ip_range             => $vlan_hash['ip_range'],
              gateway              => $vlan_hash['gateway'],
              dns                  => $_dns,
              provisioning_enabled => $_provisioning_enabled,
              zone                 => $_zone,
              ipam                 => $_ipam,
          }),
          require => File[$vlan_tmpl_dir],
        }

        exec { "create/update network ${vlan_name}":
          command => "/bin/python3 /var/lib/one/onhv_network.py ${vlan_name} '${vlan_hash.to_json}'",
          onlyif  => "/bin/python3 /var/lib/one/onhv_network_check.py ${vlan_name} '${vlan_hash.to_json}'",
          require => [
            File['/var/lib/one/onhv_network.py'],
            Service['opennebula']
          ],
        }
      } else {
        # NOTE: Currently commenting out trunk as it is broken right now

        # file { "${vlan_tmpl_dir}/${vlan_name}.txt":
        #   ensure  => 'file',
        #   owner   => $owner,
        #   group   => $owner_group,
        #   content => epp('opennebula/frontend/network/trunk.txt.epp', {
        #       vlan_name => $vlan_name,
        #   }),
        #   require => File[$vlan_tmpl_dir],
        # }

        # exec { "create trunk ${vlan_name}":
        #   command => "/bin/python3 /var/lib/one/onhv_network.py ${vlan_name}",
        #   unless  => "/bin/onevnet show ${vlan_name}",
        #   require => [
        #     File['/var/lib/one/onhv_network.py'],
        #     Service['opennebula']
        #   ],
        # }
      }
    }
  }
}
