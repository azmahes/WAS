#
# Base class for websphere.
#
class websphere (
  $base_dir     = '/opt/IBM',
  $user         = 'websphere',
  $group        = 'websphere',
  $user_home    = '/opt/IBM',
  $manage_user  = true,
  $manage_group = true,
) {

  if $manage_user {
    user { $user:
      ensure => 'present',
      home   => $user_home,
      gid    => $group,
    }
  }

  if $manage_group {
    group { $group:
      ensure => 'present',
    }
  }

  # Seems some of these tools expect /opt/IBM and some data directories there,
  # even when the installation directory is different.  Manage these for good
  # measure.
  $java_prefs = [
    '/opt/IBM',
    "${base_dir}/.java",
    "${base_dir}/.java/systemPrefs",
    "${base_dir}/.java/userPrefs",
    "${base_dir}/workspace",
#    '/opt/IBM/.java',
#    '/opt/IBM/.java/systemPrefs',
#   '/opt/IBM/.java/userPrefs',
#    '/opt/IBM/workspace',
  ]

  file { $java_prefs:
    ensure => 'directory',
    owner  => $user,
    group  => $group,
  }

  ## concat is used to populate a file for facter
  concat { '/etc/puppetlabs/facter/facts.d/websphere.yaml':
    ensure => 'present',
  }
  concat::fragment { 'websphere_facts_header':
    target  => '/etc/puppetlabs/facter/facts.d/websphere.yaml',
    order   => '01',
    content => "---\nwebsphere_base_dir: ${base_dir}\nwebsphere_profile_dmgr_01_cell_01_dmgrnode01_soap: 8879\nwebsphere_profile_dmgr_01_cell_01_appnode01_soap: 8878\nwebsphere_profiles: PROFILE_DMGR_01\n",
  }

}
