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

TMPDIR=/tmp/zapret-openwrt-$$
mkdir -p "$TMPDIR"

cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT INT TERM

# Ensure basic tools
command -v opkg >/dev/null 2>&1 || {
  echo "[zapret] opkg is required (OpenWrt only)" >&2
  exit 1
}
command -v wget >/dev/null 2>&1 || opkg update && opkg install wget-ssl || opkg install wget || true
command -v tar >/dev/null 2>&1 || opkg update && opkg install tar || true

# Download repo tarball (GitHub codeload)
TARBALL_URL="https://codeload.github.com/${REPO}/tar.gz/${BRANCH}"
echo "[zapret] downloading repo tarball: $TARBALL_URL"
if ! wget -O "$TMPDIR/src.tar.gz" "$TARBALL_URL"; then
  echo "[zapret] failed to download $TARBALL_URL" >&2
  exit 1
fi

echo "[zapret] extracting"
mkdir -p "$TMPDIR/src"
# codeload wraps files under ${REPO##*/}-${BRANCH}/ ...
tar -xzf "$TMPDIR/src.tar.gz" -C "$TMPDIR/src"
TOPDIR=$(find "$TMPDIR/src" -maxdepth 1 -type d -name "*" -printf "%f\n" | sed -n '2p')
[ -n "$TOPDIR" ] || TOPDIR=$(ls -1 "$TMPDIR/src" | head -n1)
ROOT="$TMPDIR/src/$TOPDIR/$SUBDIR"
if [ ! -f "$ROOT/install.sh" ]; then
  echo "[zapret] install.sh not found at $ROOT. Check REPO/BRANCH/SUBDIR." >&2
  exit 1
fi

# Optionally provide nfqws artifact via environment URL
if [ -n "$NFQWS_URL" ]; then
  echo "[zapret] will pass NFQWS_URL to installer"
  export NFQWS_URL
fi

# Run installer
sh "$ROOT/install.sh"

# Post-config (optional overrides via env)
# Set UCI values if provided
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
/etc/init.d/zapret enable || true
if [ "$(uci -q get zapret.config.enabled)" = "1" ]; then
  /etc/init.d/zapret restart || /etc/init.d/zapret start || true
fi

# Reload LuCI
/etc/init.d/uhttpd reload 2>/dev/null || true
/etc/init.d/rpcd restart 2>/dev/null || true

echo "[zapret] installation complete. Open LuCI -> Services -> Zapret."
