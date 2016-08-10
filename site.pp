$action = hiera('action')
$jdbcName = hiera('jdbcName')
$dbtype = hiera('dbtype')
$jdbcProviderType = hiera('jdbcProviderType')
$implmenType = hiera('implmenType')
$classPath = hiera('classPath')
$desc = hiera('desc')
$scope = hiera('scope')
$cellName = hiera('cellName')
$nodeOrClusterName = hiera('nodeOrClusterName')
$serverName = hiera('serverName')


node 'puppetclient.in.ibm.com' {

file {'/test.txt':
ensure => file,
content => "2"
}

# Rebuild the database, but only when the file changes
exec { newaliases:
  command     => "/opt/IBM/WebSphere/AppServer/profiles/PROFILE_DMGR_01/bin/wsadmin.sh -lang jython -f /Softwares/$action MyJDBCProvider cell CELL_01 description \'$desc\'",
#  cwd         => "/",
  path        => ['/usr/bin', '/usr/sbin'],
#  user        => 'root',
#   subscribe   => File['/test.txt'],
#   refreshonly => true,
}
/*
class { 'ibm_installation_manager':
  source_dir => '/Softwares/IM',
  target     => '/opt/IBM/InstallationManager',
}

class { 'websphere':
  user     => 'webadmin',
  group    => 'webadmins',
  base_dir => '/opt/IBM',
}


websphere::instance { 'WebSphere85':
  target       => '/opt/IBM/WebSphere/AppServer',
  package      => 'com.ibm.websphere.NDTRIAL.v85',
  version      => '8.5.5000.20130514_1044',
  profile_base => '/opt/IBM/WebSphere/AppServer/profiles',
  repository   => '/Softwares/WAS/repository.config',
}

websphere::package { 'WebSphere_8554':
  ensure     => 'present',
  package    => 'com.ibm.websphere.NDTRIAL.v85',
  version    => '8.5.5004.20141119_1746',
  repository => '/Softwares/WAS_FP/repository.config',
  target     => '/opt/IBM/WebSphere/AppServer',
  require    => Websphere::Instance['WebSphere85'],
}

websphere::package { 'Java7':
  ensure     => 'present',
  package    => 'com.ibm.websphere.IBMJAVA.v71',
  version    => '7.1.2000.20141116_0823',
  target     => '/opt/IBM/WebSphere/AppServer',
  repository => '/Softwares/JAVA/repository.config',
  require    => Websphere::Package['WebSphere_8554'],
}

# Example DMGR profile
websphere::profile::dmgr { 'PROFILE_DMGR_01':
  instance_base => '/opt/IBM/WebSphere/AppServer',
  profile_base  => '/opt/IBM/WebSphere/AppServer/profiles',
  cell          => 'CELL_01',
  node_name     => 'dmgrNode01',
  subscribe     => [
    Websphere::Package['WebSphere_8554'],
    Websphere::Package['Java7'],
  ],
}



# Example Application Server profile
websphere::profile::appserver { 'PROFILE_APP_001':
  instance_base  => '/opt/IBM/WebSphere/AppServer',
  profile_base   => '/opt/IBM/WebSphere/AppServer/profiles',
  cell           => 'CELL_01',
  template_path  => '/opt/IBM/WebSphere/AppServer/profileTemplates/managed',
  dmgr_host      => 'puppetclient.in.ibm.com',
  node_name      => 'appNode01',
  manage_sdk     => true,
  sdk_name       => '1.7.1_64',
}


# Manage a cluster on the DMGR
websphere::cluster { 'MyCluster01':
  profile_base => '/opt/IBM/WebSphere/AppServer/profiles',
  dmgr_profile => 'PROFILE_DMGR_01',
  cell         => 'CELL_01',
  require      => Websphere::Profile::Dmgr['PROFILE_DMGR_01'],
}



# Export myself as a cluster member
websphere::cluster::member { 'AppServer01':
  ensure       => 'present',
  cluster      => 'MyCluster01',
  node         => 'appNode01',
  cell         => 'CELL_01',
  profile_base => '/opt/IBM/WebSphere/AppServer/profiles',
  dmgr_profile => 'PROFILE_DMGR_01',
}


# Example of a node scoped variable
websphere_variable { 'appNode01Logs':
  ensure       => 'present',
  variable     => 'LOG_ROOT',
  value        => '/var/log/websphere/wasmgmtlogs/appNode01',
  scope        => 'node',
  node         => 'appNode01',
  cell         => 'CELL_01',
  dmgr_profile => 'PROFILE_APP_001',
  profile_base => '/opt/IBM/WebSphere/AppServer/profiles',
  user         => 'webadmin',
  require      => Websphere::Profile::Appserver['PROFILE_APP_001'],
}

# Example of a server scoped variable
# NOTE: This will cause a FAILURE during the first Puppet run because the
# cluster member has not yet been created on the DMGR.
websphere_variable { 'AppServer01Logs':
  ensure       => 'present',
  variable     => 'LOG_ROOT',
  value        => '/opt/log/websphere/appserverlogs',
  scope        => 'server',
  server       => 'AppServer01',
  node         => 'appNode01',
  cell         => 'CELL_01',
  dmgr_profile => 'PROFILE_APP_001',
  profile_base => $profile_base,
  user         => $user,
  require      => Websphere::Profile::Appserver['PROFILE_APP_001'],
}

websphere_jdbc_provider { 'Puppet Test':
  ensure         => 'present',
  dmgr_profile   => 'PROFILE_DMGR_01',
  profile_base   => '/opt/IBM/WebSphere/AppServer/profiles',
  user           => 'webadmin',
  scope          => 'node',
  cell           => 'CELL_01',
  node           => 'appNode01',
  server         => 'AppServer01',
  dbtype         => 'Oracle',
  providertype   => 'Oracle JDBC Driver',
  implementation => 'Connection pool data source',
  description    => 'JDBC provider created by Puppet ',
  classpath      => '${ORACLE_JDBC_DRIVER_PATH}/ojdbc6.jar',
}

websphere_jdbc_datasource { 'Puppet Test':
  ensure                        => 'present',
  dmgr_profile                  => 'PROFILE_DMGR_01',
  profile_base                  => '/opt/IBM/WebSphere/AppServer/profiles',
  user                          => 'webadmin',
  scope                         => 'node',
  cell                          => 'CELL_01',
  node                          => 'appNode01',
  server                        => 'AppServer01',
  jdbc_provider                 => 'Puppet Test',
  jndi_name                     => 'myTest',
  data_store_helper_class       => 'com.ibm.websphere.rsadapter.Oracle11gDataStoreHelper',
  container_managed_persistence => true,
  url                           => 'jdbc:oracle:thin:@//localhost:1521/ankit',
  description                   => 'JDBC Datasource Created by Puppet',
}
*/
/*
websphere_jdbc_provider { 'Puppet Test':
  ensure         => 'present',
  dmgr_profile   => 'PROFILE_DMGR_01',
  profile_base   => '/opt/IBM/WebSphere/AppServer/profiles',
  user           => 'webadmin',
  scope          => 'cell',
  cell           => 'CELL_01',
  dbtype         => 'Oracle',
  providertype   => 'Oracle JDBC Driver',
  implementation => 'Connection pool data source',
  description    => 'Created by Puppet @ cell scope',
  classpath      => '${ORACLE_JDBC_DRIVER_PATH}/ojdbc6.jar',
}

websphere_jdbc_datasource { 'Puppet Test':
  ensure                        => 'present',
  dmgr_profile                  => 'PROFILE_DMGR_01',
  profile_base                  => '/opt/IBM/WebSphere/AppServer/profiles',
  user                          => 'webadmin',
  scope                         => 'cell',
  cell                          => 'CELL_01',
  jdbc_provider                 => 'Puppet Test',
  jndi_name                     => 'myTest',
  data_store_helper_class       => 'com.ibm.websphere.rsadapter.Oracle11gDataStoreHelper',
  container_managed_persistence => true,
  url                           => 'jdbc:oracle:thin:@//localhost:1521/sample',
  description                   => 'Created by Puppet @ cell scope',
}
*/

}
