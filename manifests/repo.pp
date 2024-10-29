# @summary Installs all repos required for opennebula
#
class opennebula::repo {
  $on_version            = $opennebula::version
  $edition               = $opennebula::edition
  $token                 = $opennebula::token

  if $edition == 'CE' {
    $_descr = 'OpenNebula Community Edition'
    $_baseurl = "https://downloads.opennebula.io/repo/${on_version}/RedHat/\$releasever/\$basearch"
  }

  if $edition == 'EE' {
    $_descr = 'OpenNebula Enterprise Edition'
    $_baseurl = "https://${token}@enterprise.opennebula.io/repo/6.8/RedHat/\$releasever/\$basearch"
  }

  yumrepo { 'OpenNebula Repo':
    ensure    => 'present',
    name      => 'opennebula',
    assumeyes => true,
    descr     => $_descr,
    baseurl   => $_baseurl,
    enabled   => '1',
    gpgkey    => 'https://downloads.opennebula.io/repo/repo2.key',
    gpgcheck  => '1',
  }
}
