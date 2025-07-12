#!/bin/sh

UPLINK='eth'

# TMODE is expected to be set via the containerlab topology file prior to deployment
# Expected values are "lacp" or "static" or "active-backup" which will bond eth1 and eth2
if [ -z "$TMODE" ]; then
  TMODE='none'
fi

# TACTIVE and TBACKUP to be set via the containerlab topology file for active-backup runner
# expected values are "eth1" or "eth2" default is "eth1" active and "eth2" backup
if [ -z "$TACTIVE" ]; then
  TACTIVE='eth1'
  TBACKUP='eth2'
elif [ "$TACTIVE" == 'eth1' ]; then
  TBACKUP='eth2'
elif [ "$TACTIVE" == 'eth2' ]; then
  TBACKUP='eth1'
fi

echo "teaming mode is " $TMODE

#######################
# Re-run script as sudo
#######################

if [ "$(id -u)" != "0" ]; then
  exec sudo --preserve-env=TMODE,TACTIVE,TBACKUP "$0" "$@"
fi

##########################
# Check operation status 
##########################

# First, try to bring up the interfaces
ip link set eth1 up 2>/dev/null || true
ip link set eth2 up 2>/dev/null || true

# Wait for eth1
check=$( cat /sys/class/net/eth1/operstate 2>/dev/null )
while [ "up" != "$check" ] && [ "unknown" != "$check" ]; do
    echo "waiting for eth1 interface to come up"
    sleep 1
    check=$( cat /sys/class/net/eth1/operstate 2>/dev/null )
done

# Wait for eth2 - FIXED THE BUG HERE
check=$( cat /sys/class/net/eth2/operstate 2>/dev/null )
while [ "up" != "$check" ] && [ "unknown" != "$check" ]; do
    echo "waiting for eth2 interface to come up"
    sleep 1
    check=$( cat /sys/class/net/eth2/operstate 2>/dev/null )  # Fixed: was eth1
done

echo "eth1 state: $(cat /sys/class/net/eth1/operstate 2>/dev/null)"
echo "eth2 state: $(cat /sys/class/net/eth2/operstate 2>/dev/null)"

###############
# Enabling LLDP
###############

lldpad -d
for i in `ls /sys/class/net/ | grep 'eth\|ens\|eno'`
do
    lldptool set-lldp -i $i adminStatus=rxtx 2>/dev/null || true
    lldptool -T -i $i -V sysName enableTx=yes 2>/dev/null || true
    lldptool -T -i $i -V portDesc enableTx=yes 2>/dev/null || true
    lldptool -T -i $i -V sysDesc enableTx=yes 2>/dev/null || true
done

################
# Teaming setup
################

cat << EOF > /home/alpine/teamd-lacp.conf
{
   "device": "team0",
   "runner": {
       "name": "lacp",
       "active": true,
       "fast_rate": true,
       "tx_hash": ["eth", "ipv4", "ipv6"]
   },
     "link_watch": {"name": "ethtool"},
     "ports": {"eth1": {}, "eth2": {}}
}
EOF

cat << EOF > /home/alpine/teamd-static.conf
{
 "device": "team0",
 "runner": {"name": "roundrobin"},
 "ports": {"eth1": {}, "eth2": {}}
}
EOF

cat << EOF > /home/alpine/teamd-active-backup.conf
{
  "device": "team0",
  "runner": {"name": "activebackup"},
  "link_watch": {"name": "ethtool"},
  "ports": {
    "$TACTIVE": {
      "prio": 100
    },
    "$TBACKUP": {
      "prio": -10
    }
  }
}
EOF

if [ "$TMODE" == 'lacp' ]; then
  TARG='/home/alpine/teamd-lacp.conf'
elif [ "$TMODE" == 'static' ]; then
  TARG='/home/alpine/teamd-static.conf'
elif [ "$TMODE" == 'active-backup' ]; then
  TARG='/home/alpine/teamd-active-backup.conf'
fi

if [ "$TMODE" == 'lacp' ] || [ "$TMODE" == 'static' ] || [ "$TMODE" == 'active-backup' ]; then
  echo "Setting up team interface with mode: $TMODE"
  
  # Check if teamd is available
  if ! command -v teamd >/dev/null 2>&1; then
    echo "ERROR: teamd not found"
    exit 1
  fi
  
  teamd -v
  
  # Kill any existing teamd process
  teamd -k -f $TARG 2>/dev/null || true
  
  # Bring down interfaces before adding to team
  ip link set eth1 down
  ip link set eth2 down
  
  # Start teamd
  if teamd -d -r -f $TARG; then
    echo "teamd started successfully"
    ip link set team0 up
    UPLINK="team"
    echo "Team interface created and up"
  else
    echo "ERROR: Failed to start teamd"
    # Fall back to bringing up individual interfaces
    ip link set eth1 up
    ip link set eth2 up
  fi
fi

echo "Setup complete. UPLINK mode: $UPLINK"

#####################
# Enter sleeping loop
#####################

while sleep 3600; do :; done