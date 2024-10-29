# @summary Utility class that sets up VM HA hook scripts
class opennebula::frontend::vm_ha {
  $owner = $opennebula::owner
  $owner_group = $opennebula::owner_group
  $hook_tmpl_dir = $opennebula::hook_tmpl_dir
  $monitoring_interval = $opennebula::monitoring_interval
  $ipmi_username = $opennebula::ipmi_username
  $ipmi_password = $opennebula::ipmi_password

  file { $hook_tmpl_dir:
    ensure => 'directory',
    owner  => $owner,
    group  => $owner_group,
  }

  # This is the hook configuration we will create later
  file { "${hook_tmpl_dir}/error_hook":
    ensure  => 'file',
    owner   => $owner,
    group   => $owner_group,
    mode    => '0700',
    content => epp('opennebula/frontend/ha/error_hook.epp', {
        monitoring_interval => $monitoring_interval,
    }),
  }

  # This is the script that our hook will call
  file { '/var/lib/one/remotes/hooks/ft/fence_host.sh':
    ensure  => 'file',
    owner   => $owner,
    group   => $owner_group,
    mode    => '0700',
    content => epp('opennebula/frontend/ha/fence_host.sh.epp', {
        username => $ipmi_username,
        password => $ipmi_password,
    }),
  }

  # Actually create the hook so OpenNebula will do things when a host goes offline
  exec { 'onehook create host_error VM HA hook':
    command => "/bin/onehook create ${hook_tmpl_dir}/error_hook",
    unless  => "/bin/onehook list | grep 'host_error'",
  }
}
