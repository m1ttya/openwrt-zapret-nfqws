#!/bin/sh
# One-line online installer for Zapret (nfqws + nftables + LuCI) on OpenWrt
# Usage (example):
#   wget -O - "https://raw.githubusercontent.com/USER/REPO/BRANCH/openwrt/online_install.sh" | sh
# Optional env vars:
#   REPO="USER/REPO"            # GitHub repo path
#   BRANCH="main"               # branch/ref name
#   SUBDIR="openwrt"            # subdir in repo containing install.sh and rootfs
#   NFQWS_URL="..."             # direct URL to nfqws binary for your arch (overrides artifact)
#   ENABLE=1                     # force enable service after install (default: keep UCI value)
#   PROFILE="general"            # set profile in UCI after install (optional)
#   IF_LAN="auto" IF_WAN="auto" # override auto-detection
#   PORTS_TCP="443" PORTS_UDP="443" # override ports (ranges allowed like 19294-19344)

set -e

REPO="${REPO:-m1ttya/openwrt-zapret-nfqws}"
BRANCH="${BRANCH:-main}"
SUBDIR="${SUBDIR:-openwrt}"
LOG="/tmp/zapret_install.log"

# Start log
{
  echo "===== [zapret] Online installer started $(date) ====="
  echo "REPO=$REPO BRANCH=$BRANCH SUBDIR=$SUBDIR"
  echo "NFQWS_URL=${NFQWS_URL:-} NFQWS_IPK_URL=${NFQWS_IPK_URL:-}"
} >> "$LOG" 2>&1

TMPDIR=/tmp/zapret-openwrt-$$
mkdir -p "$TMPDIR"

echo "[zapret] tmpdir: $TMPDIR" | tee -a "$LOG"

cleanup() {
  echo "[zapret] cleanup" >> "$LOG" 2>&1
  rm -rf "$TMPDIR"
}
trap cleanup EXIT INT TERM

# Ensure basic tools
if ! command -v opkg >/dev/null 2>&1; then
  echo "[zapret] opkg is required (OpenWrt only)" | tee -a "$LOG" >&2
  exit 1
fi

echo "[zapret] step 1/6: ensure wget/tar/CA certs" | tee -a "$LOG"
command -v wget >/dev/null 2>&1 || opkg update >>"$LOG" 2>&1 && opkg install wget-ssl >>"$LOG" 2>&1 || opkg install wget >>"$LOG" 2>&1 || true
command -v tar >/dev/null 2>&1 || opkg update >>"$LOG" 2>&1 && opkg install tar >>"$LOG" 2>&1 || true
opkg install ca-bundle ca-certificates >>"$LOG" 2>&1 || true

# Print basic system info
{
  echo "Kernel: $(uname -a)"
  echo "Archs: $(opkg print-architecture 2>/dev/null | tr '\n' ' ')"
} >> "$LOG" 2>&1

# Download repo tarball (GitHub codeload)
TARBALL_URL="https://codeload.github.com/${REPO}/tar.gz/${BRANCH}"
echo "[zapret] step 2/6: download repo: $TARBALL_URL" | tee -a "$LOG"
if ! wget -O "$TMPDIR/src.tar.gz" "$TARBALL_URL" >>"$LOG" 2>&1; then
  echo "[zapret] failed to download $TARBALL_URL" | tee -a "$LOG" >&2
  exit 1
fi

# Extract
echo "[zapret] step 3/6: extract tarball" | tee -a "$LOG"
mkdir -p "$TMPDIR/src"
if ! tar -xzf "$TMPDIR/src.tar.gz" -C "$TMPDIR/src" >>"$LOG" 2>&1; then
  echo "[zapret] failed to extract tarball" | tee -a "$LOG" >&2
  exit 1
fi
TOPDIR=$(tar -tzf "$TMPDIR/src.tar.gz" | head -1 | cut -d/ -f1)
[ -n "$TOPDIR" ] || TOPDIR=$(ls -1 "$TMPDIR/src" | head -n1)
ROOT="$TMPDIR/src/$TOPDIR/$SUBDIR"
if [ ! -f "$ROOT/install.sh" ]; then
  echo "[zapret] install.sh not found at $ROOT. Check REPO/BRANCH/SUBDIR." | tee -a "$LOG" >&2
  exit 1
fi

# Pass env
[ -n "$NFQWS_URL" ] && export NFQWS_URL && echo "[zapret] passing NFQWS_URL" >> "$LOG"
[ -n "$NFQWS_IPK_URL" ] && export NFQWS_IPK_URL && echo "[zapret] passing NFQWS_IPK_URL" >> "$LOG"

# Run installer
echo "[zapret] step 4/6: run installer" | tee -a "$LOG"
if ! sh "$ROOT/install.sh" >>"$LOG" 2>&1; then
  echo "[zapret] installer failed, see $LOG" | tee -a "$LOG" >&2
  exit 1
fi

# Post-config (optional overrides via env)
echo "[zapret] step 5/6: apply post-config (UCI)" | tee -a "$LOG"
[ -n "$IF_LAN" ] && uci set zapret.config.if_lan="$IF_LAN"
[ -n "$IF_WAN" ] && uci set zapret.config.if_wan="$IF_WAN"
[ -n "$PORTS_TCP" ] && uci set zapret.config.ports_tcp="$PORTS_TCP"
[ -n "$PORTS_UDP" ] && uci set zapret.config.ports_udp="$PORTS_UDP"
[ -n "$PROFILE" ] && uci set zapret.config.profile="$PROFILE"
if [ "${ENABLE:-}" = "1" ]; then
  uci set zapret.config.enabled='1'
fi
uci commit zapret || true

# Apply service state according to UCI
echo "[zapret] step 6/6: enable/restart service" | tee -a "$LOG"
/etc/init.d/zapret enable >>"$LOG" 2>&1 || true
if [ "$(uci -q get zapret.config.enabled)" = "1" ]; then
  /etc/init.d/zapret restart >>"$LOG" 2>&1 || /etc/init.d/zapret start >>"$LOG" 2>&1 || true
fi

# Reload LuCI
/etc/init.d/uhttpd reload >>"$LOG" 2>&1 || true
/etc/init.d/rpcd restart >>"$LOG" 2>&1 || true

echo "[zapret] installation complete. Open LuCI -> Services -> Zapret." | tee -a "$LOG"
