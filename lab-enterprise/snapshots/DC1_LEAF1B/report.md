# DC1_LEAF1B Commands Output

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
not supported command
```
## show lldp neighbors

```
not supported command
```
## show running-config

```
! Command: show running-config
! device: dc1-leaf1b (cEOSLab, EOS-4.33.4M-42444412.4334M (engineering build))
!
no aaa root
!
username admin privilege 15 role network-admin secret sha512 $6$gViPz5DG04kYuRzO$r.tJf5s4ph3IH/lrD6HZy7N3z6Pk1q4lh/IGqFKBGDDjEkOVH8Dd0N54UBiuE/7bQ4qG6LjPkRiLswrN.pQBp1
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
hostname dc1_leaf1b
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
   ip address 172.100.100.5/24
   ipv6 address 2001:172:100:100::d/80
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
Serial number: 74AB85A75AEEBA62FEB3287599BF5C71
Hardware MAC address: 001c.7396.7a0c
System MAC address: 001c.7396.7a0c

Software image version: 4.33.4M-42444412.4334M (engineering build)
Architecture: i686
Internal build version: 4.33.4M-42444412.4334M
Internal build ID: 191df00b-75d8-494d-aaad-7478e1101bc8
Image format version: 1.0
Image optimization: None

Kernel version: 6.8.0-51-generic

Uptime: 1 minute
Total memory: 32501040 kB
Free memory: 18586044 kB
```
