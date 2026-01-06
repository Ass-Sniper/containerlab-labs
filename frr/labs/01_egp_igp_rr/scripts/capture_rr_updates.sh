#!/usr/bin/env bash
#
# Capture BGP UPDATE / WITHDRAW packets on RR (r3)
# Interfaces:
#   eth3 : eBGP in  (from r4)
#   eth1 : RR out   (to r1)
#   eth2 : RR out   (to r2)
#

set -euo pipefail

LAB_NAME="clab-egp-igp-rr"
RR_NODE="r3"
RR_CONTAINER="${LAB_NAME}-${RR_NODE}"

CAPTURE_DIR="captures/bgp"
CAPTURE_DURATION=20   # seconds

FILTER='tcp port 179'
# BGP message types:
#  2 = UPDATE
#  3 = NOTIFICATION (kept for safety; UPDATE/WITHDRAW 都在 UPDATE)

echo "[*] Resolving PID for ${RR_CONTAINER} ..."

RR_PID=$(docker inspect -f '{{.State.Pid}}' "${RR_CONTAINER}")

if [[ -z "${RR_PID}" || "${RR_PID}" == "0" ]]; then
  echo "[!] Failed to resolve PID for ${RR_CONTAINER}"
  exit 1
fi

echo "[*] RR container PID = ${RR_PID}"
echo "[*] Capture duration   = ${CAPTURE_DURATION}s"
echo "[*] Output directory   = ${CAPTURE_DIR}"
echo

mkdir -p "${CAPTURE_DIR}"

# ------------------------------------------------------------
# Start captures
# ------------------------------------------------------------
echo "[*] Starting packet capture on RR interfaces..."

sudo nsenter -t "${RR_PID}" -n \
  timeout "${CAPTURE_DURATION}" tcpdump -i eth3 -nn -s 0 \
    "${FILTER}" \
    -w "${CAPTURE_DIR}/r3-eth3-ebgp.pcap" &

sudo nsenter -t "${RR_PID}" -n \
  timeout "${CAPTURE_DURATION}" tcpdump -i eth1 -nn -s 0 \
    "${FILTER}" \
    -w "${CAPTURE_DIR}/r3-eth1-rr-out.pcap" &

sudo nsenter -t "${RR_PID}" -n \
  timeout "${CAPTURE_DURATION}" tcpdump -i eth2 -nn -s 0 \
    "${FILTER}" \
    -w "${CAPTURE_DIR}/r3-eth2-rr-out.pcap" &

wait

echo
echo "[✓] Capture completed."
echo "[✓] Files generated:"
echo "    - ${CAPTURE_DIR}/r3-eth3-ebgp.pcap   (eBGP UPDATE in)"
echo "    - ${CAPTURE_DIR}/r3-eth1-rr-out.pcap (RR reflected to r1)"
echo "    - ${CAPTURE_DIR}/r3-eth2-rr-out.pcap (RR reflected to r2)"
echo
echo "[*] Open with Wireshark and compare UPDATE attributes"
