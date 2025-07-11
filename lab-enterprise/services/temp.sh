ROUTE1='cat /etc/hostname; \
sudo ip route del 10.1.0.0/16 via 10.1.10.1 dev team0.110; \
sudo ip route add 10.1.0.0/16 via 10.1.10.10 dev team0.110; \
'

ROUTE2='cat /etc/hostname; \
sudo ip route del 10.1.0.0/16 via 10.1.11.1 dev team0.111; \
sudo ip route add 10.1.0.0/16 via 10.1.11.10 dev team0.111; \
'

docker exec -it clab-s2-dc1_client1 /bin/sh -c "$ROUTE1"
docker exec -it clab-s2-dc1_client2 /bin/sh -c "$ROUTE2"
docker exec -it clab-s2-dc1_client3 /bin/sh -c "$ROUTE1"
docker exec -it clab-s2-dc1_client4 /bin/sh -c "$ROUTE2"