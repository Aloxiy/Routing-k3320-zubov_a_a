/interface bridge
add name=bridge1 vlan-filtering=yes
/interface vlan
add name=vlan10 vlan-id=10 interface=bridge1
add name=vlan20 vlan-id=20 interface=bridge1
/interface bridge port
add bridge=bridge1 interface=ether2
add bridge=bridge1 interface=ether3
add bridge=bridge1 interface=ether4
/interface bridge vlan
add bridge=bridge1 tagged=bridge1,ether2,ether3 vlan-ids=10
add bridge=bridge1 tagged=bridge1,ether2,ether4 vlan-ids=20
/ip address
add address=10.10.0.2/24 interface=vlan10
add address=10.20.0.2/24 interface=vlan20
/user
add name=aloxiy password=1234 group=full
remove admin
/system identity
set name=SW01
