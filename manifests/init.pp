# @summary Puppet module to manage OpenNebula configuration
#
# @param version - OpenNebula version. default 6.8
# @param token - needs documentation
# @param is_node - true/false whether the node is a hypervisor
# @param is_frontend - true/false whether the node is a frontend
#
# @param ssl_cert_path - needs documentation
# @param ssl_key_path - needs documentation
# @param hostname - needs documentation
# @param vnc_proxy_support_wss - needs documentation
# @param rpc_endpoint - The rpc endpoint of opennebula cluster.  This should be publicly available
# @param public_fireedge_endpoint - The endpoint to set /etc/one/sunstone-server.conf file with
# @param onhv_user - The onhv user to connect to rpc endpoint
# @param onhv_passwd - Password of onhv user
# @param owner - Filesystem user that is considered owner of config files for opennebula
# @param owner_group - Filesystem group that is considered group of config files for opennebula
# @param log_dir - Log directory where any logs from puppet run are stored
#
# @param db_server - Hostname/ip of db server
# @param db_port - Port of db server
# @param db_user - Database user to connect to as
# @param db_passwd - Password of database user
# @param db_root_passwd - Password of root database user
# @param db_svc_user - Database service account to generate backups
# @param db_svc_passwd - Password for database service account
# @param db_name - Port of db server
# @param db_backup_script - Absolute path to backup script for open nebula
# @param db_backup_retention - Number of days to retain backups
# @param db_backup_nfs_mount - Mount point of nfs share to store database backups
# @param ds_for_db_backups - Datastore number to store db backups on.  This is the
#   option that should be changed if a user want to store in another location
# @param db_backup_dir - Path the database backups will be stored within nfs share
# @param db_log_expire_seconds - needs documentation
#
# @param use_ldap_auth - true/false on whether to use ldap for auth
# @param ldap_user - LDAP user to query search for any users trying to login to opennebula, usually svc account
# @param ldap_user_passwd - Password of ldap user
# @param ldap_server - LDAP server hostname/ip
# @param ldap_port - Port to use for ldap connection
# @param ldap_search_base - The base DN to search for users for auth
# @param ldap_groups - Hash representing the relationship between opennebula groups and ldap groups
#   The key represents be the opennebula group and value represents the ldap group
#
# @param frontend_if_config - Hash of network connection configurations for frontend
# @param vlan_tmpl_dir - Hash of network connection configurations for frontend
# @param cluster_groups - Hash of all available cluster groups where the key is the name of the cluster
# group and value is a list of clusters for that group
# @param default_cluster_group - The default cluster group that is used if neither "clusters" or "cluster_group" key is
# passed into the "vnets" parameter per vlan name
# @param default_dns - The default dns string that is used if the "dns" key is not passed into the "vnets" parameter per vlan name
#   This parameter should be a string of space seperated dns entries
# @param default_provisioning_enabled - The default value used for "provisioning_enabled" key in "vnets" parameter if not set
# @param default_zone - The default value used for "zone" key in "vnets" parameter if not set
# @param default_ipam - The default value used for "ipam" key in "vnets" parameter if not set
# @param nginx_ssl_ciphers - SSL ciphers to use for nginx
# @param nginx_ssl_protocols - SSL protocols to use for nginx
# @param host_attributes - Hash where the key is the onhv fqdn and value is hash of attributes for that host
# @param host_attributes_tmpl_dir - Directory where the host attribute template files reside
#
# @param server_id - The server id of a node apart of HA for onhv frontend
# @param ha_servers - Hash of all servers in HA where the key is the server_id
# and the value is the ip address of that node
# @param hook_script - Absolute path to failover script
# @param election_timeout - Time in seconds where our scripts like network, ldap etc will wait
# @param auth_backup_nfs_mount  - Mount point to store contents of /var/lib/one/.one directory
# @param ds_for_auth_backup - Datastore number to store auth dir on.  This is the
#   option that should be changed if a user want to store in another location
# @param auth_backup_dir - The directory store auth dir on nfs mount
# @param failover_iface_name - Network interface that will be used for floating ip change
# @param floating_ip_cidr - IP address that will be used for any node that becomes leader
# @param monitoring_interval - needs documentation
# @param hook_tmpl_dir - needs documentation
# @param ipmi_username - needs documentation
# @param ipmi_password - needs documentation
# @param codeready_repo - needs documentation

# @param edition - OpenNebula edition. default CE
# @param ensure - Indicate if packages should be present or absent
# @param firewalld_node_ports - Hash of ports to open on the nodes.
# @param firewalld_ports - Hash of ports to open on the frontend host.
# @param firewalld_svcs - Hash of firewalld services to open on the node host.
# @param firewalld_libvirt_exporter_ports - needs documentation
# @param firewalld_libvirt_exporter_svc - needs documentation
# @param firewalld_onhv_exporter_ports - needs documentation
# @param firewalld_onhv_exporter_svc - needs documentation
# @param home_dir - OpenNebula home directory. default /var/lib/one
# @param if_bond - Hash of network bond configuration
# @param if_bridge - Hash of network bridge configurations
# @param if_config - Hash of network interface configuration
# @param if_slave - Hash of bond slaves configurations
# @param if_vlan - Hash of VLAN configurations
# @param manage_network - true/false whether to manage the network configuration.
# @param manage_repo - true/false whether to manage the OpenNebula repositories.
# @param oa_privkey - Oneadmin private key
# @param oa_pubkey - Oneadmin public key
# @param qemu_dynamic_ownership - 0/1 whether to enable dynamic ownership in libvirt.
# @param vnets - Hash of all virtual networks used in open nebula. Includes the vnet name and vnet VLAN ID.
# @param bridge_name_prefix - String used to form the bridge name for each virtual network (vnet).
# @param vm_firewalld_zone - String. The firewalld zone that all bridge interfaces
# which do not have IP addresses get added to for vnets to allow inbound VM only traffic
#
class opennebula (
  ################################
  # General Params
  ################################

  String                         $version                  = '6.8',
  Enum['CE','EE']                $edition                  = 'CE',
  Optional[String]               $token                    = undef,

  ################################
  # Frontend Params
  ################################

  Boolean                        $is_frontend              = false,
  # Opennebula params
  String                         $ssl_cert_path            = '/etc/pki/tls/certs/onhv.crt',
  String                         $ssl_key_path             = '/etc/pki/tls/private/onhv.key',
  String                         $hostname                 = "onecloud.${facts['networking']['domain']}",
  String                         $rpc_endpoint             = "http://onecloud.${facts['networking']['domain']}:2633/RPC2",
  String                         $public_fireedge_endpoint = "http://onecloud.${facts['networking']['domain']}:2616",
  String                         $vnc_proxy_support_wss    = 'no',
  String                         $onhv_user                = 'oneadmin',
  String                         $onhv_passwd              = undef,
  String                         $owner                    = 'oneadmin',
  String                         $owner_group              = 'oneadmin',
  Stdlib::Absolutepath           $log_dir                  = '/opt/encore/log/',
  Hash                           $firewalld_ports          = $opennebula::params::firewalld_ports,
  Variant[Array[String]]         $nginx_ssl_ciphers        = 'PROFILE=SYSTEM',
  Variant[Array[String]]         $nginx_ssl_protocols      = 'TLSv1.2 TLSv1.3',
  Hash                           $host_attributes          = undef,
  Stdlib::Absolutepath           $host_attributes_tmpl_dir = undef,

  # DB params
  String                         $db_server               = 'localhost',
  Integer                        $db_port                 = 3306,
  String                         $db_user                 = 'oneadmin',
  Optional[String]               $db_passwd               = undef,
  Optional[String]               $db_root_passwd          = undef,
  String                         $db_svc_user             = 'encore_db_backup',
  Optional[String]               $db_svc_passwd           = undef,
  String                         $db_name                 = 'opennebula',
  Stdlib::Absolutepath           $db_backup_script        = '/opt/encore/bin/mysql_backup.sh',
  Integer                        $db_backup_retention     = 7,
  Stdlib::Absolutepath           $db_backup_nfs_mount     = '/var/lib/one/datastores/',
  Integer                        $ds_for_db_backups       = 1,
  Stdlib::Absolutepath           $db_backup_dir           = '/onecloud-backups/db-backups/onecloud.dev.encore.internal',
  # 3 days = 259200 seconds
  Integer                        $db_log_expire_seconds   = 259200,

  # LDAP params
  Boolean                        $use_ldap_auth            = false,
  Optional[String]               $ldap_user                = undef,
  Optional[String]               $ldap_user_passwd         = undef,
  Optional[String]               $ldap_server              = undef,
  Optional[Integer]              $ldap_port                = undef,
  Optional[String]               $ldap_search_base         = undef,
  Optional[Hash]                 $ldap_groups              = undef,

  # Network params
  Optional[Hash]                 $frontend_if_config       = undef,
  Optional[Stdlib::Absolutepath] $vlan_tmpl_dir            = undef,
  Hash                           $cluster_groups           = undef,
  String                         $default_cluster_group    = undef,
  String                         $default_dns              = undef,
  Boolean                        $default_provisioning_enabled = undef,
  String                         $default_zone             = undef,
  String                         $default_ipam             = undef,

  # HA Params

  # NOTE: server_id of 0 is considered the leader and "ha_servers" parameter
  # must be filled out if leader
  Integer                        $server_id               = -1,
  Optional[Hash]                 $ha_servers              = undef,
  Stdlib::Absolutepath           $hook_script             = '/var/lib/one/remotes/hooks/raft/vip.sh',
  Integer                        $election_timeout        = 30,
  String                         $failover_iface_name     = 'enp3s0',
  Optional[String]               $floating_ip_cidr        = undef,

  Stdlib::Absolutepath           $auth_backup_nfs_mount   = '/var/lib/one/datastores/',
  Integer                        $ds_for_auth_backup      = 1,
  Stdlib::Absolutepath           $auth_backup_dir         = '/.one',
  Integer                        $monitoring_interval     = 5,
  String                         $hook_tmpl_dir           = '/var/lib/one/hooks',
  String                         $ipmi_username           = undef,
  String                         $ipmi_password           = undef,
  String                         $codeready_repo          = 'codeready-builder-for-rhel-9-x86_64-rpms',

  ################################
  # Node Params
  ################################

  Boolean                        $is_node                  = false,
  Enum['present','absent']       $ensure                   = 'present',
  Hash                           $firewalld_node_ports     = $opennebula::params::firewalld_node_ports,
  Hash                           $firewalld_svcs           = $opennebula::params::firewalld_svcs,
  Stdlib::Absolutepath           $home_dir                 = '/var/lib/one',
  Optional[Hash]                 $if_bond                  = undef,
  Optional[Hash]                 $if_bridge                = undef,
  Optional[Hash]                 $if_config                = undef,
  Optional[Hash]                 $if_slave                 = undef,
  Optional[Hash]                 $if_vlan                  = undef,
  Boolean                        $manage_network           = true,
  Boolean                        $manage_repo              = true,
  String                         $oa_privkey               = undef,
  String                         $oa_pubkey                = undef,
  # within libvirt, '0' is the default (off)
  Integer                        $qemu_dynamic_ownership   = 0,
  Optional[Hash]                 $vnets                    = undef,
  String                         $bridge_name_prefix       = 'one-br0-vlan',
  String                         $vm_firewalld_zone        = 'libvirt',

  ################################
  # Node Based Exporter Params
  ################################
  Hash                           $firewalld_libvirt_exporter_ports   = $opennebula::params::firewalld_libvirt_exporter_ports,
  Hash                           $firewalld_libvirt_exporter_svc     = $opennebula::params::firewalld_libvirt_exporter_svc,

  ################################
  # Frontend Based Exporter Params
  ################################
  Hash                           $firewalld_onhv_exporter_ports   = $opennebula::params::firewalld_onhv_exporter_ports,
  Hash                           $firewalld_onhv_exporter_svc     = $opennebula::params::firewalld_onhv_exporter_svc,
) inherits opennebula::params {
  contain opennebula::repo

  if $is_frontend == true {
    contain opennebula::frontend::database
    contain opennebula::frontend::install
    contain opennebula::frontend::config
    contain opennebula::frontend::ssh
    contain opennebula::frontend::network
    contain opennebula::frontend::nginx
    contain opennebula::frontend::services
    contain opennebula::frontend::exporter
    contain opennebula::frontend::vm_ha

    if $server_id > -1 {
      contain opennebula::frontend::ha
    }
  }

  if $is_node == true {
    contain opennebula::node::config
    contain opennebula::node::install
    contain opennebula::node::network
    contain opennebula::node::exporter
  }
}
