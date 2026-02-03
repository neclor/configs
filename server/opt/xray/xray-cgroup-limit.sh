#!/usr/bin/env bash
#
# Limit Xray download speed using cgroup v2 + tc
#
# What this script does:
# - Creates a dedicated cgroup for Xray
# - Attaches Xray process to that cgroup
# - Limits ALL outgoing traffic of Xray
# - Does NOT depend on ports, nginx, or protocol
#

set -e

### CONFIG ###
IFACE="bond0"              # Network interface used for internet access
XRAY_SERVICE="xray"        # systemd service name
CGROUP_NAME="xray-limit"   # cgroup name
RATE="15mbit"              # Download speed limit
CLASSID="10"               # tc class id
FILTER_HANDLE="100"        # tc filter handle

echo "[*] Limiting Xray traffic using cgroup v2"
echo "    Interface : $IFACE"
echo "    Service   : $XRAY_SERVICE"
echo "    Cgroup    : $CGROUP_NAME"
echo "    Rate      : $RATE"

### 1. Ensure cgroup v2 is mounted
echo "[*] Ensuring cgroup v2 is available"
mountpoint -q /sys/fs/cgroup || {
  echo "ERROR: cgroup v2 is not mounted"
  exit 1
}

### 2. Create cgroup for Xray (if not exists)
echo "[*] Creating cgroup"
CGROUP_PATH="/sys/fs/cgroup/$CGROUP_NAME"
mkdir -p "$CGROUP_PATH"

### 3. Get main PID of Xray service
echo "[*] Getting Xray main PID"
XRAY_PID=$(systemctl show -p MainPID --value "$XRAY_SERVICE")

if [ -z "$XRAY_PID" ] || [ "$XRAY_PID" = "0" ]; then
  echo "ERROR: Xray service is not running"
  exit 1
fi

### 4. Attach Xray process to cgroup
echo "[*] Attaching Xray PID $XRAY_PID to cgroup"
echo "$XRAY_PID" > "$CGROUP_PATH/cgroup.procs"

### 5. Ensure root HTB qdisc exists
echo "[*] Ensuring root HTB qdisc exists"
tc qdisc show dev "$IFACE" | grep -q "htb" || \
tc qdisc add dev "$IFACE" root handle 1: htb default 30

### 6. Ensure parent class exists
echo "[*] Ensuring parent class exists"
tc class show dev "$IFACE" | grep -q "1:1" || \
tc class add dev "$IFACE" parent 1: classid 1:1 htb rate 1000mbit ceil 1000mbit

### 7. Remove previous Xray class (if exists)
echo "[*] Removing previous Xray class (if exists)"
tc class del dev "$IFACE" classid 1:$CLASSID 2>/dev/null || true

### 8. Remove previous cgroup filter (if exists)
echo "[*] Removing previous cgroup filter (if exists)"
tc filter del dev "$IFACE" parent 1: handle "$FILTER_HANDLE" cgroup 2>/dev/null || true

### 9. Create limited class for Xray
echo "[*] Creating limited class for Xray"
tc class add dev "$IFACE" parent 1:1 classid 1:$CLASSID \
    htb rate "$RATE" ceil "$RATE"

### 10. Bind cgroup traffic to limited class
echo "[*] Binding cgroup traffic to limited class"
tc filter add dev "$IFACE" protocol ip parent 1: prio 1 \
    handle "$FILTER_HANDLE" cgroup flowid 1:$CLASSID

echo "[✓] Xray traffic is now limited to $RATE"
echo "[i] Check stats with: tc -s class show dev $IFACE"
