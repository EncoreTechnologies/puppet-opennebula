# @summary Utility class that installs front end nginx reverse proxy
class opennebula::frontend::nginx {
  $owner                   = $opennebula::owner
  $owner_group             = $opennebula::owner_group
  $hostname                = $opennebula::hostname
  $ssl_cert_path           = $opennebula::ssl_cert_path
  $ssl_key_path            = $opennebula::ssl_key_path
  $nginx_ssl_ciphers       = $opennebula::nginx_ssl_ciphers
  $nginx_ssl_protocols     = $opennebula::nginx_ssl_protocols

  # nginx params to set CPU affinity rule
  $nginx_prepend = {
    'worker_cpu_affinity' => 'auto',
  }

  # configure nginx as reverse proxy
  class { 'nginx':
    confd_purge       => true,
    nginx_cfg_prepend => $nginx_prepend,
    ssl_ciphers       => join($nginx_ssl_ciphers, ':'),
    ssl_protocols     => join($nginx_ssl_protocols, ' '),
  }

  ## TODO: should probably manage this through nginx::resource stuff if possible
  file { '/etc/nginx/sites-available/onhv-ssl.conf':
    ensure  => 'file',
    owner   => $owner,
    group   => $owner_group,
    mode    => '0700',
    notify  => Service['nginx'],
    content => epp('opennebula/frontend/nginx/onhv-ssl.conf.epp', {
        hostname   => $hostname,
        nginx_cert => $ssl_cert_path,
        nginx_key  => $ssl_key_path,
    }),
  }

  file { '/etc/nginx/sites-enabled/onhv-ssl.conf':
    ensure => 'link',
    target => '/etc/nginx/sites-available/onhv-ssl.conf',
    notify => Service['nginx'],
  }

  # Open firewall for http and https via nginx
  include firewalld
  firewalld_service { ['http', 'https']:
    ensure => 'present',
    zone   => 'public',
  }
}
