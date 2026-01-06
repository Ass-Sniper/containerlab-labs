#!/usr/bin/env bash
#
# Trigger eBGP UPDATE / WITHDRAW / UPDATE from r4 (AS65002)
#

set -euo pipefail

LAB_NAME="clab-egp-igp-rr"
EBGP_NODE="r4"
EBGP_CONTAINER="${LAB_NAME}-${EBGP_NODE}"

PREFIX="100.64.4.0/24"
NH_IP="100.64.4.1"

echo "[*] Triggering eBGP UPDATE from ${EBGP_CONTAINER}"
echo "[*] Test prefix: ${PREFIX}"
echo

# ------------------------------------------------------------
# 1. Ensure prefix exists in RIB (REQUIRED for BGP network)
# ------------------------------------------------------------
echo "[1/4] Installing static route into RIB (required for BGP network)..."

docker exec "${EBGP_CONTAINER}" \
  ip route replace "${PREFIX}" via "${NH_IP}" dev lo || true

docker exec "${EBGP_CONTAINER}" \
  ip route show "${PREFIX}" || {
    echo "[!] Failed to install route into RIB"
    exit 1
  }

# ------------------------------------------------------------
# 2. Advertise prefix via BGP
# ------------------------------------------------------------
echo
echo "[2/4] Advertising prefix via BGP..."

docker exec "${EBGP_CONTAINER}" vtysh -c "configure terminal" \
  -c "router bgp 65002" \
  -c "network ${PREFIX}"

sleep 3

# ------------------------------------------------------------
# 3. Withdraw prefix
# ------------------------------------------------------------
echo
echo "[3/4] Withdrawing prefix..."

docker exec "${EBGP_CONTAINER}" vtysh -c "configure terminal" \
  -c "router bgp 65002" \
  -c "no network ${PREFIX}"

sleep 3

# ------------------------------------------------------------
# 4. Re-advertise prefix
# ------------------------------------------------------------
echo
echo "[4/4] Re-advertising prefix..."

docker exec "${EBGP_CONTAINER}" vtysh -c "configure terminal" \
  -c "router bgp 65002" \
  -c "network ${PREFIX}"

echo
echo "[✓] eBGP UPDATE trigger completed."
echo "[✓] Expected observations:"
echo "    - r3 eth3 : eBGP UPDATE / WITHDRAW / UPDATE"
echo "    - r3 eth1 : RR-reflected UPDATE to r1"
echo "    - r3 eth2 : RR-reflected UPDATE to r2"
