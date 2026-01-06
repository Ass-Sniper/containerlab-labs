#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="configs"
COMMON_DIR="${CONFIG_DIR}/common"
BACKUP_DIR="${CONFIG_DIR}/_backup_$(date +%Y%m%d_%H%M%S)"

echo "[*] Creating backup at ${BACKUP_DIR}"
mkdir -p "${BACKUP_DIR}"
cp -r "${CONFIG_DIR}"/r* "${BACKUP_DIR}/"

echo "[*] Creating common config directory"
mkdir -p "${COMMON_DIR}"

# -----------------------------
# Step 1: Extract common daemons / vtysh.conf
# -----------------------------
FIRST_NODE=$(find "$CONFIG_DIR" -maxdepth 1 -type d -name 'r*' | sort | head -n1)
if [ -z "$FIRST_NODE" ]; then
    echo "[!] No rX directories found under $CONFIG_DIR"
    exit 1
fi

echo "[*] Using ${FIRST_NODE} as template for common files"

cp "${FIRST_NODE}/daemons" "${COMMON_DIR}/daemons"
cp "${FIRST_NODE}/vtysh.conf" "${COMMON_DIR}/vtysh.conf"

# -----------------------------
# Step 2: Generate frr-common.conf
# -----------------------------
COMMON_CONF="${COMMON_DIR}/frr-common.conf"

echo "[*] Generating ${COMMON_CONF}"

cat > "${COMMON_CONF}" <<'EOF'
!
! Common FRR global configuration
!
frr defaults traditional
log syslog informational
log stdout
service integrated-vtysh-config
!
EOF

# -----------------------------
# Step 3: Clean per-node frr.conf
# -----------------------------
echo "[*] Cleaning per-node frr.conf files"

for NODE in "${CONFIG_DIR}"/r*; do
    [ -d "${NODE}" ] || continue

    NODE_NAME=$(basename "${NODE}")
    SRC_CONF="${NODE}/frr.conf"
    DST_CONF="${NODE}/frr.conf"

    if [ ! -f "${SRC_CONF}" ]; then
        echo "[!] Skip ${NODE_NAME}, no frr.conf"
        continue
    fi

    echo "    - Processing ${NODE_NAME}"

    # Remove global/common lines
    sed -i \
        -e '/^frr version/d' \
        -e '/^frr defaults/d' \
        -e '/^log /d' \
        -e '/^service integrated-vtysh-config/d' \
        "${DST_CONF}"
done

echo
echo "[✓] Refactor completed successfully"
echo "    - Backup saved in: ${BACKUP_DIR}"
echo "    - Common configs in: ${COMMON_DIR}"
echo
echo "Next step:"
echo "  - Mount configs/common/* into /etc/frr"
echo "  - Concatenate frr-common.conf + node frr.conf at container startup"
