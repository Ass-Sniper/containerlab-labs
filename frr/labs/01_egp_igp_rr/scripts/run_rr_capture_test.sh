#!/usr/bin/env bash
set -e

echo "[*] Starting RR capture + eBGP trigger test"

sudo ./scripts/capture_rr_updates.sh &
CAP_PID=$!

sleep 3   # 确保 tcpdump 已经 attach

sudo ./scripts/trigger_ebgp_update.sh

wait ${CAP_PID}

echo "[✓] RR capture test completed"
