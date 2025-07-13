# S2Remote Engine Deployment Script

mkdir snmp-engine1; cd snmp-engine1;
curl https://<customer-s2ap-url-here>/engines/s2engine.sh | REMOTE_ENGINE_NAME=snmp-engine1 SNMP_ENGINE_CLASS=snmp-default bash -s snmp deploy

