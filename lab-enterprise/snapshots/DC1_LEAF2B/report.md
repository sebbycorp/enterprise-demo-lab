# DC1_LEAF2B Commands Output

## Table of Contents

- [show lldp neighbors](#show-lldp-neighbors)
- [show ip interface brief](#show-ip-interface-brief)
- [show interfaces description](#show-interfaces-description)
- [show version](#show-version)
- [show running-config](#show-running-config)
## show interfaces description

```
Interface                      Status         Protocol           Description
Et1                            up             up                 
Et2                            up             up                 
Et3                            up             up                 
Et4                            up             up                 
Et5                            up             up                 
Et6                            up             up                 
Et7                            up             up                 
Et8                            up             up                 
Ma0                            up             up
```
## show ip interface brief

```
Address
Interface       IP Address           Status     Protocol         MTU    Owner  
--------------- -------------------- ---------- ------------- --------- -------
Management0     172.100.100.7/24     up         up              1500
```
## show lldp neighbors

```
Last table change time   : 0:00:20 ago
Number of table inserts  : 18
Number of table deletes  : 0
Number of table drops    : 0
Number of table age-outs : 0

Port          Neighbor Device ID       Neighbor Port ID    TTL
---------- ------------------------ ---------------------- ---
Et1           dc1_spine1               Ethernet4           120
Et2           dc1_spine2               Ethernet4           120
Et3           dc1_leaf2a               Ethernet3           120
Et4           dc1_leaf2a               Ethernet4           120
Et5           dc1_client3              aac1.ab8a.37da      120
Et6           dc1_client4              aac1.abfb.fb00      120
Et8           dc1_haproxy2             aac1.abcd.0ff1      120
Ma0           dc1_client2              0242.ac64.6409      120
Ma0           dc1_haproxy1             0242.ac64.640e      120
Ma0           dc1_client1              0242.ac64.6408      120
Ma0           dc1_client3              0242.ac64.640a      120
Ma0           dc1_client4              0242.ac64.640b      120
Ma0           dc1_haproxy2             0242.ac64.640f      120
Ma0           dc1_spine2               Management0         120
Ma0           dc1_spine1               Management0         120
Ma0           dc1_leaf2a               Management0         120
Ma0           dc1_leaf1a               Management0         120
Ma0           dc1_leaf1b               Management0         120
```
## show running-config

```
! Command: show running-config
! device: dc1-leaf2b (cEOSLab, EOS-4.33.4M-42444412.4334M (engineering build))
!
no aaa root
!
username admin privilege 15 role network-admin secret sha512 $6$yYvqvMgUNrZ8eSMB$TFJzTSDdEExmtU2rhbeD48b2435Bm97acn76659YTi1zTuaix4iF9hIFQKnS1vMcT7tFW0b7thijG8FJs3Axj.
!
management api http-commands
   protocol https ssl profile eAPI
   no shutdown
   !
   vrf MGMT
      no shutdown
!
no service interface inactive port-id allocation disabled
!
transceiver qsfp default-mode 4x10G
!
service routing protocols model multi-agent
!
hostname dc1_leaf2b
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
!
interface Ethernet2
!
interface Ethernet3
!
interface Ethernet4
!
interface Ethernet5
!
interface Ethernet6
!
interface Ethernet7
!
interface Ethernet8
!
interface Management0
   description oob_management
   vrf MGMT
   ip address 172.100.100.7/24
   ipv6 address 2001:172:100:100::3/80
!
no ip routing
no ip routing vrf MGMT
!
ip route vrf MGMT 0.0.0.0/0 172.100.100.1
!
ipv6 route vrf MGMT ::/0 2001:172:100:100::1
!
router multicast
   ipv4
      software-forwarding kernel
   !
   ipv6
      software-forwarding kernel
!
end
```
## show version

```
Arista cEOSLab
Hardware version: 
Serial number: 03616857D19DB7E334594335CE328ADD
Hardware MAC address: 001c.7378.21cf
System MAC address: 001c.7378.21cf

Software image version: 4.33.4M-42444412.4334M (engineering build)
Architecture: i686
Internal build version: 4.33.4M-42444412.4334M
Internal build ID: 191df00b-75d8-494d-aaad-7478e1101bc8
Image format version: 1.0
Image optimization: None

Kernel version: 6.8.0-51-generic

Uptime: 2 minutes
Total memory: 32501040 kB
Free memory: 18717908 kB
```
