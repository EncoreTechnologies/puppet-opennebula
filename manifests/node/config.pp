# @summary Private class to configure OpenNebula Hypervisor repositories.
#
# @api private
#
class opennebula::node::config {
  $manage_repo           = $opennebula::manage_repo
  $ensure                = $opennebula::ensure
  $_os_major             = $facts['os']['release']['major']
  $on_version            = $opennebula::version

  if $manage_repo == true and $facts['epel_config'] != 'true' {
    # Regex check if EPEL repository is already configured (NOTE: Only updated once per day).
    if /(?i:epel)/ in $facts['rhsm_enabled_repos'] {
      notify { 'EPEL status':
        message => 'INFO: EPEL repository is already configured, skipping.',
      }
    } else {
      # Set params for external EPEL repo.
      $_epel_source = 'https://dl.fedoraproject.org/pub/epel/'
      $_epel_pkg    = "epel-release-latest-${_os_major}.noarch.rpm"
      $_epel_full   = "${_epel_source}${_epel_pkg}"

      # Configure external EPEL repo.
      package { 'EPEL Configure':
        ensure   => $ensure,
        name     => "epel-release-${_os_major}",
        source   => $_epel_full,
        provider => 'rpm',
      }
    }

    # Ensure codeready repo is configured.
    rhsm_repo { 'Enable codeready repo':
      ensure => $ensure,
      id     => "codeready-builder-for-rhel-${_os_major}-x86_64-rpms",
    }
  }

  # Set fact for EPEL configuration.
  facter::fact { 'EPEL Config':
    name  => 'epel_config',
    value => true,
  }
}
