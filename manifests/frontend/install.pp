# @summary Utility class that installs front end services for opennebula
class opennebula::frontend::install {
  # Install opennebula
  package { [
      'opennebula',
      'opennebula-rubygems',
      'ruby-devel',
      'opennebula-sunstone',
      'opennebula-fireedge',
      'opennebula-gate',
      'opennebula-flow',
      'opennebula-provision',
    ]:
      ensure  => 'installed',
  }
}
