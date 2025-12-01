/interface bridge
add name=bridge1
/interface vlan
add name=vlan20 vlan-id=20 interface=bridge1
/interface bridge port
add bridge=bridge1 interface=ether2 
add bridge=bridge1 interface=ether3 pvid=10
/interface bridge vlan
add bridge=bridge1 tagged=bridge1,ether2 untagged=ether3 vlan-ids=20
/ip address
add address=10.20.0.3/24 interface=vlan20
/user
add name=aloxiy password=1234 group=full
remove admin
/system identity
set name=SW02-02
