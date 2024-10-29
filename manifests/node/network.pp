# @summary Puppet define to manage NetworkManager configuration on OpenNebula nodes
#
# @api private
#
class opennebula::node::network (
  Enum['present','absent']   $ensure            = $opennebula::ensure,
  Hash                       $firewalld_ports   = $opennebula::firewalld_node_ports,
  Hash                       $firewalld_svcs    = $opennebula::firewalld_svcs,
  Optional[Hash]             $if_bond           = $opennebula::if_bond,
  Optional[Hash]             $if_bridge         = $opennebula::if_bridge,
  Optional[Hash]             $if_config         = $opennebula::if_config,
  Optional[Hash]             $if_slave          = $opennebula::if_slave,
  Optional[Hash]             $if_vlan           = $opennebula::if_vlan,
  Optional[Hash]             $vnets             = $opennebula::vnets,
  String                     $bridge_name       = $opennebula::bridge_name_prefix,
  String                     $vm_firewalld_zone = $opennebula::vm_firewalld_zone,
) {
  # Create hash to pass to create_resources
  $_ensure = { 'ensure' => $ensure }

  # We need to make sure network config happens prior to NFS mount resources
  $_ensure_and_before = $_ensure + { 'before' => Class['encore_base::profile::nfs'] }

  # Control interface/bond/bridge configuration on the hypervisor
  if $opennebula::manage_network == true {
    class { 'networkmanager':
      erase_unmanaged_keyfiles => true,
      no_auto_default          => true,
    }

    if ! $if_config.empty {
      create_resources('networkmanager::ifc::connection', $if_config, $_ensure_and_before)
    }
    if ! $if_bond.empty {
      create_resources('networkmanager::ifc::bond', $if_bond, $_ensure_and_before)
    }
    if ! $if_bridge.empty {
      create_resources('networkmanager::ifc::bridge', $if_bridge, $_ensure_and_before)
    }
    if ! $if_slave.empty {
      create_resources('networkmanager::ifc::bond::slave', $if_slave, $_ensure_and_before)
    }
    if ! $if_vlan.empty {
      create_resources('networkmanager::ifc::vlan', $if_vlan, $_ensure_and_before)
    }
  }
  # Open ports for open nebula specific things on the hypervisor
  ensure_resources('firewalld::custom_service', $firewalld_ports)
  ensure_resources('firewalld_service', $firewalld_svcs)

  if ! $vnets.empty {
    # Array of all VLAN IDs used for virtual networks
    # e.g. [208, 209]
    $vnet_vlans = $vnets.values.map | $values | { $values[vlan] }

    # combine VLAN IDs to create an array of bridge names for all VLANs.
    # e.g. ['one-br0-vlan208', 'one-br0-vlan209']
    $vnet_bridges = $vnet_vlans.map | $value | { "${bridge_name}${value}" }

    # The bridges on each hypervisor which have an IP address on them need to go into
    # the 'public' firewalld zone which occurs above via
    # 'create_resources('networknanager::ifc::bridge', $if_bridge...)'
    #
    # In other words:
    # - Bridges with an IP go into 'public' zone. This is so opennebula-node
    #   firewalld service applies to them.
    # - Bridges for VM traffic only (no IP on them) go into libvirt zone
    #
    # This line filters out any bridge with an IP on it so we add only the bridges for
    # VMs only into the libvirt zone.
    $vnet_bridges_without_ip = $vnet_bridges.filter | $bridge | { !($bridge in $if_bridge.keys ) }

    # Add all bridges without IP addresses on them to the libvirt zone
    firewalld_zone { $vm_firewalld_zone:
      interfaces => $vnet_bridges_without_ip,
    }
  }
}
