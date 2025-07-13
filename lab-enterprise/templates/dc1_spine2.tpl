hostname {{ .ShortName }}
username admin privilege 15 secret admin
!
service routing protocols model multi-agent
!
vrf instance MGMT
!
interface Management0
   description oob_management
   vrf MGMT
{{ if .MgmtIPv4Address }}   ip address {{ .MgmtIPv4Address }}/{{ .MgmtIPv4PrefixLength }}{{end}}
{{ if .MgmtIPv6Address }}   ipv6 address {{ .MgmtIPv6Address }}/{{ .MgmtIPv6PrefixLength }}{{end}}
!
{{ if .MgmtIPv4Gateway }}ip route vrf MGMT 0.0.0.0/0 {{ .MgmtIPv4Gateway }}{{end}}
{{ if .MgmtIPv6Gateway }}ipv6 route vrf MGMT ::0/0 {{ .MgmtIPv6Gateway }}{{end}}
!
management security
   ssl profile eAPI
      cipher-list HIGH:!eNULL:!aNULL:!MD5:!ADH:!ANULL
      certificate eAPI.crt key eAPI.key
!
management api http-commands
   protocol https ssl profile eAPI
   no shutdown
   !
   vrf MGMT
      no shutdown
!
vlan internal order ascending range 1006 1199
!
no service interface inactive port-id allocation disabled
!
transceiver qsfp default-mode 4x10G
!
service routing protocols model multi-agent
!
logging buffered 32768 informational
logging console errors
logging monitor errors
logging vrf MGMT host {{ .Env.LOGGING_SERVER }}
logging format hostname fqdn
logging facility local7
logging vrf MGMT source-interface Management0
!
logging level AAA informational
logging level ACCOUNTING informational
logging level ACL informational
logging level AGENT informational
logging level ALE informational
logging level ARP informational
logging level BFD informational
logging level BGP informational
logging level BMP informational
logging level CAPACITY informational
logging level CAPI informational
logging level CLASSIFICATION informational
logging level CLEAR informational
logging level CVX informational
logging level DATAPLANE informational
logging level DHCP informational
logging level DMF informational
logging level DOT1X informational
logging level DOT1XHTTP informational
logging level DSCP informational
logging level ENVMON informational
logging level ETH informational
logging level EVENTMON informational
logging level EXTENSION informational
logging level FHRP informational
logging level FLOW informational
logging level FLOWTRACKING informational
logging level FORWARDING informational
logging level FRU informational
logging level FWK informational
logging level GMP informational
logging level HARDWARE informational
logging level HEALTH informational
logging level HTTPSERVICE informational
logging level IGMP informational
logging level IGMPSNOOPING informational
logging level INFLUXTELEMETRY informational
logging level INT informational
logging level INTF informational
logging level IP6ROUTING informational
logging level IPRIB informational
logging level IRA informational
logging level ISIS informational
logging level KERNELFIB informational
logging level LACP informational
logging level LAG informational
logging level LAUNCHER informational
logging level LDP informational
logging level LICENSE informational
logging level LINEPROTO informational
logging level LLDP informational
logging level LOGMGR informational
logging level LOOPBACK informational
logging level LOOPPROTECT informational
logging level MAPREDUCEMONITOR informational
logging level MCS informational
logging level MIRRORING informational
logging level MKA informational
logging level MLAG informational
logging level MLDSNOOPING informational
logging level MMODE informational
logging level MONITORSECURITY informational
logging level MROUTE informational
logging level MRP informational
logging level MSDP informational
logging level MSRP informational
logging level MSSPOLICYMONITOR informational
logging level MVRP informational
logging level NAT informational
logging level OPENCONFIG informational
logging level OPENFLOW informational
logging level OSPF informational
logging level OSPF3 informational
logging level PACKAGE informational
logging level PFC informational
logging level PIMBSR informational
logging level PORTSECURITY informational
logging level POSTCARDTELEMETRY informational
logging level PSEUDOWIRE informational
logging level PTP informational
logging level PWRMGMT informational
logging level QOS informational
logging level QUEUEMONITOR informational
logging level RADIUS informational
logging level REDUNDANCY informational
logging level RIB informational
logging level ROUTING informational
logging level SECURITY informational
logging level SERVERMONITOR informational
logging level SERVERPROBE informational
logging level SFE informational
logging level SPANTREE informational
logging level SSO informational
logging level STAGEMGR informational
logging level SYS informational
logging level SYSDB informational
logging level TAPAGG informational
logging level TCP informational
logging level TRAFFICPOLICY informational
logging level TRANSCEIVER informational
logging level TUNNEL informational
logging level TUNNELINTF informational
logging level VLAN informational
logging level VMTRACERSESS informational
logging level VMWAREVI informational
logging level VMWAREVS informational
logging level VRF informational
logging level VRRP informational
logging level VXLAN informational
logging level ZTP informational
!
hostname DC1_SPINE2
ip name-server vrf MGMT 1.1.1.1
ip name-server vrf MGMT 8.8.8.8
!
snmp-server chassis-id DC1_SPINE2
snmp-server contact Network Operations sebatianm@selector.ai
snmp-server location New York Data Center
snmp-server community public ro
snmp-server host {{ .Env.LOGGING_SERVER }} vrf MGMT version 2c public
snmp-server enable traps
snmp-server enable traps snmp authentication
snmp-server enable traps snmp link-down
snmp-server enable traps snmp link-up
snmp-server vrf MGMT
!
spanning-tree mode mstp
!
system l1
   unsupported speed action error
   unsupported error-correction action error
!
vrf instance MGMT
!
management security
   ssl profile eAPI
      cipher-list HIGH:!eNULL:!aNULL:!MD5:!ADH:!ANULL
      certificate eAPI.crt key eAPI.key
!
interface Ethernet1
   description P2P_LINK_TO_DC1_LEAF1A_Ethernet2
   mtu 9214
   no switchport
   ip address 172.31.255.2/31
!
interface Ethernet2
   description P2P_LINK_TO_DC1_LEAF1B_Ethernet2
   mtu 9214
   no switchport
   ip address 172.31.255.6/31
!
interface Ethernet3
   description P2P_LINK_TO_DC1_LEAF2A_Ethernet2
   mtu 9214
   no switchport
   ip address 172.31.255.10/31
!
interface Ethernet4
   description P2P_LINK_TO_DC1_LEAF2B_Ethernet2
   mtu 9214
   no switchport
   ip address 172.31.255.14/31
!
interface Loopback0
   description EVPN_Overlay_Peering
   ip address 192.168.255.2/32
!
interface Management0
   description oob_management
   vrf MGMT
   ip address 172.100.100.3/24
!
ip routing
no ip routing vrf MGMT
!
ip prefix-list PL-LOOPBACKS-EVPN-OVERLAY
   seq 10 permit 192.168.255.0/24 eq 32
!
ip route vrf MGMT 0.0.0.0/0 172.100.100.1
!
ntp server vrf MGMT time.google.com prefer iburst
!
route-map RM-CONN-2-BGP permit 10
   match ip address prefix-list PL-LOOPBACKS-EVPN-OVERLAY
!
router bfd
   multihop interval 300 min-rx 300 multiplier 3
!
router bgp 65001
   router-id 192.168.255.2
   no bgp default ipv4-unicast
   distance bgp 20 200 200
   maximum-paths 4 ecmp 4
   neighbor EVPN-OVERLAY-PEERS peer group
   neighbor EVPN-OVERLAY-PEERS next-hop-unchanged
   neighbor EVPN-OVERLAY-PEERS update-source Loopback0
   neighbor EVPN-OVERLAY-PEERS bfd
   neighbor EVPN-OVERLAY-PEERS ebgp-multihop 3
   neighbor EVPN-OVERLAY-PEERS password 7 q+VNViP5i4rVjW1cxFv2wA==
   neighbor EVPN-OVERLAY-PEERS send-community
   neighbor EVPN-OVERLAY-PEERS maximum-routes 0
   neighbor IPv4-UNDERLAY-PEERS peer group
   neighbor IPv4-UNDERLAY-PEERS password 7 AQQvKeimxJu+uGQ/yYvv9w==
   neighbor IPv4-UNDERLAY-PEERS send-community
   neighbor IPv4-UNDERLAY-PEERS maximum-routes 12000
   neighbor 172.31.255.3 peer group IPv4-UNDERLAY-PEERS
   neighbor 172.31.255.3 remote-as 65101
   neighbor 172.31.255.3 description DC1_LEAF1A_Ethernet2
   neighbor 172.31.255.7 peer group IPv4-UNDERLAY-PEERS
   neighbor 172.31.255.7 remote-as 65101
   neighbor 172.31.255.7 description DC1_LEAF1B_Ethernet2
   neighbor 172.31.255.11 peer group IPv4-UNDERLAY-PEERS
   neighbor 172.31.255.11 remote-as 65102
   neighbor 172.31.255.11 description DC1_LEAF2A_Ethernet2
   neighbor 172.31.255.15 peer group IPv4-UNDERLAY-PEERS
   neighbor 172.31.255.15 remote-as 65102
   neighbor 172.31.255.15 description DC1_LEAF2B_Ethernet2
   neighbor 192.168.255.3 peer group EVPN-OVERLAY-PEERS
   neighbor 192.168.255.3 remote-as 65101
   neighbor 192.168.255.3 description DC1_LEAF1A
   neighbor 192.168.255.4 peer group EVPN-OVERLAY-PEERS
   neighbor 192.168.255.4 remote-as 65101
   neighbor 192.168.255.4 description DC1_LEAF1B
   neighbor 192.168.255.5 peer group EVPN-OVERLAY-PEERS
   neighbor 192.168.255.5 remote-as 65102
   neighbor 192.168.255.5 description DC1_LEAF2A
   neighbor 192.168.255.6 peer group EVPN-OVERLAY-PEERS
   neighbor 192.168.255.6 remote-as 65102
   neighbor 192.168.255.6 description DC1_LEAF2B
   redistribute connected route-map RM-CONN-2-BGP
   !
   address-family evpn
      neighbor EVPN-OVERLAY-PEERS activate
   !
   address-family ipv4
      no neighbor EVPN-OVERLAY-PEERS activate
      neighbor IPv4-UNDERLAY-PEERS activate
!
router multicast
   ipv4
      software-forwarding kernel
   !
   ipv6
      software-forwarding kernel
!
end