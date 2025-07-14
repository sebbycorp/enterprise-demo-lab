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
hostname DC1_LEAF1A
ip name-server vrf MGMT 1.1.1.1
ip name-server vrf MGMT 8.8.8.8
!
snmp-server chassis-id DC1_LEAF1A
snmp-server contact Network Operations {{ .Env.OWNER }}
snmp-server location {{ .Env.DATACENTER_LOCATION }}
snmp-server community {{ .Env.SNMP_STRING }} ro
snmp-server host {{ .Env.LOGGING_SERVER }} vrf MGMT version 2c {{ .Env.SNMP_STRING }}
snmp-server enable traps
snmp-server enable traps snmp authentication
snmp-server enable traps snmp link-down
snmp-server enable traps snmp link-up
snmp-server vrf MGMT
!
spanning-tree mode mstp
no spanning-tree vlan-id 4093-4094
spanning-tree mst 0 priority 4096
!
system l1
   unsupported speed action error
   unsupported error-correction action error
!
vlan 110
   name Tenant_A_OP_Zone_1
!
vlan 111
   name Tenant_A_OP_Zone_2
!
vlan 4093
   name LEAF_PEER_L3
   trunk group LEAF_PEER_L3
!
vlan 4094
   name MLAG_PEER
   trunk group MLAG
!
vrf instance MGMT
!
management security
   ssl profile eAPI
      cipher-list HIGH:!eNULL:!aNULL:!MD5:!ADH:!ANULL
      certificate eAPI.crt key eAPI.key
!
interface Port-Channel3
   description MLAG_PEER_DC1_LEAF1B_Po3
   switchport mode trunk
   switchport trunk group LEAF_PEER_L3
   switchport trunk group MLAG
!
interface Port-Channel5
   description server01_PortChannel5
   switchport trunk allowed vlan 110
   switchport mode trunk
   mlag 5
   spanning-tree portfast edge
!
interface Port-Channel6
   description server02_PortChannel6
   switchport trunk allowed vlan 111
   switchport mode trunk
   mlag 6
   spanning-tree portfast edge
!
interface Port-Channel7
   description VyOS01_LACP
   switchport trunk allowed vlan 110-111
   switchport mode trunk
   mlag 7
!
interface Port-Channel9
   description HAPROXY01_LACP
   switchport trunk allowed vlan 110-111
   switchport mode trunk
   mlag 9
!
interface Ethernet1
   description P2P_LINK_TO_DC1_SPINE1_Ethernet1
   mtu 9214
   no switchport
   ip address 172.31.255.1/31
!
interface Ethernet2
   description P2P_LINK_TO_DC1_SPINE2_Ethernet1
   mtu 9214
   no switchport
   ip address 172.31.255.3/31
!
interface Ethernet3
   description MLAG_PEER_DC1_LEAF1B_Ethernet3
   channel-group 3 mode active
!
interface Ethernet4
   description MLAG_PEER_DC1_LEAF1B_Ethernet4
   channel-group 3 mode active
!
interface Ethernet5
   description server01_Eth1
   channel-group 5 mode active
!
interface Ethernet6
   description server02_Eth1
   channel-group 6 mode active
!
interface Ethernet7
   description VyOS01_DC1_LEAF1B
   channel-group 7 mode active
!
interface Ethernet8
   description HAPROXY01_DC1_LEAF1B
   channel-group 9 mode active
!
interface Loopback0
   description EVPN_Overlay_Peering
   ip address 192.168.255.3/32
!
interface Loopback1
   description VTEP_VXLAN_Tunnel_Source
   ip address 192.168.254.3/32
!
interface Management0
   description oob_management
   vrf MGMT
   ip address 172.100.100.4/24
!
interface Vlan110
   description Tenant_A_OP_Zone_1
   ip address virtual 10.1.10.1/24
!
interface Vlan111
   description Tenant_A_OP_Zone_2
   ip address virtual 10.1.11.1/24
!
interface Vlan4093
   description MLAG_PEER_L3_PEERING
   mtu 9214
   ip address 10.255.251.0/31
!
interface Vlan4094
   description MLAG_PEER
   mtu 9214
   no autostate
   ip address 10.255.252.0/31
!
interface Vxlan1
   description DC1_LEAF1A_VTEP
   vxlan source-interface Loopback1
   vxlan udp-port 4789
   vxlan vlan 110 vni 10110
   vxlan vlan 111 vni 10111
!
ip virtual-router mac-address 00:00:00:00:00:01
!
ip routing
no ip routing vrf MGMT
!
ip prefix-list PL-LOOPBACKS-EVPN-OVERLAY
   seq 10 permit 192.168.255.0/24 eq 32
   seq 20 permit 192.168.254.0/24 eq 32
!
mlag configuration
   domain-id DC1_LEAF1
   local-interface Vlan4094
   peer-address 10.255.252.1
   peer-link Port-Channel3
   reload-delay mlag 300
   reload-delay non-mlag 330
!
ip route vrf MGMT 0.0.0.0/0 172.100.100.1
!
ntp server vrf MGMT time.google.com prefer iburst
!
route-map RM-CONN-2-BGP permit 10
   match ip address prefix-list PL-LOOPBACKS-EVPN-OVERLAY
!
route-map RM-MLAG-PEER-IN permit 10
   description Make routes learned over MLAG Peer-link less preferred on spines to ensure optimal routing
   set origin incomplete
!
router bfd
   multihop interval 300 min-rx 300 multiplier 3
!
router bgp 65101
   router-id 192.168.255.3
   no bgp default ipv4-unicast
   distance bgp 20 200 200
   maximum-paths 4 ecmp 4
   neighbor EVPN-OVERLAY-PEERS peer group
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
   neighbor MLAG-IPv4-UNDERLAY-PEER peer group
   neighbor MLAG-IPv4-UNDERLAY-PEER remote-as 65101
   neighbor MLAG-IPv4-UNDERLAY-PEER next-hop-self
   neighbor MLAG-IPv4-UNDERLAY-PEER description DC1_LEAF1B
   neighbor MLAG-IPv4-UNDERLAY-PEER route-map RM-MLAG-PEER-IN in
   neighbor MLAG-IPv4-UNDERLAY-PEER password 7 vnEaG8gMeQf3d3cN6PktXQ==
   neighbor MLAG-IPv4-UNDERLAY-PEER send-community
   neighbor MLAG-IPv4-UNDERLAY-PEER maximum-routes 12000
   neighbor 10.255.251.1 peer group MLAG-IPv4-UNDERLAY-PEER
   neighbor 10.255.251.1 description DC1_LEAF1B
   neighbor 172.31.255.0 peer group IPv4-UNDERLAY-PEERS
   neighbor 172.31.255.0 remote-as 65001
   neighbor 172.31.255.0 description DC1_SPINE1_Ethernet1
   neighbor 172.31.255.2 peer group IPv4-UNDERLAY-PEERS
   neighbor 172.31.255.2 remote-as 65001
   neighbor 172.31.255.2 description DC1_SPINE2_Ethernet1
   neighbor 192.168.255.1 peer group EVPN-OVERLAY-PEERS
   neighbor 192.168.255.1 remote-as 65001
   neighbor 192.168.255.1 description DC1_SPINE1
   neighbor 192.168.255.2 peer group EVPN-OVERLAY-PEERS
   neighbor 192.168.255.2 remote-as 65001
   neighbor 192.168.255.2 description DC1_SPINE2
   redistribute connected route-map RM-CONN-2-BGP
   !
   vlan 110
      rd 192.168.255.3:10110
      route-target both 10110:10110
      redistribute learned
   !
   vlan 111
      rd 192.168.255.3:10111
      route-target both 10111:10111
      redistribute learned
   !
   address-family evpn
      neighbor EVPN-OVERLAY-PEERS activate
   !
   address-family ipv4
      no neighbor EVPN-OVERLAY-PEERS activate
      neighbor IPv4-UNDERLAY-PEERS activate
      neighbor MLAG-IPv4-UNDERLAY-PEER activate
!
router multicast
   ipv4
      software-forwarding kernel
   !
   ipv6
      software-forwarding kernel
!
end
