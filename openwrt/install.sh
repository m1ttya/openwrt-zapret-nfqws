#!/bin/sh
set -e

# This script installs zapret service and LuCI app on OpenWrt.
# Usage: scp -r openwrt root@ROUTER:/root/ && ssh root@ROUTER 'sh /root/openwrt/install.sh'

PKGS="kmod-nfnetlink kmod-nft-core kmod-nft-netdev kmod-nft-queue libnetfilter-queue nftables ca-bundle luci-ssl"
# Auto-pick nfqws URL for your arch if not overridden
NFQWS_URL="${NFQWS_URL:-}"
if [ -z "$NFQWS_URL" ]; then
  ARCH="$(opkg print-architecture 2>/dev/null | awk 'END{print $2}')"
  CPU="$(uname -m)"
  # Map common arches. TL-WDR3500 ath79 => mips (big-endian 24kc)
  case "$ARCH/$CPU" in
    mips*/mips|mips*/mips32)
      # Replace with an actual URL to a static mips (big endian) nfqws build
      NFQWS_URL="https://example.com/zapret/nfqws-mips-24kc"
      ;;
    mipsel*/mipsel|*mipsel*)
      NFQWS_URL="https://example.com/zapret/nfqws-mipsel"
      ;;
    arm*/armv7l)
      NFQWS_URL="https://example.com/zapret/nfqws-armv7"
      ;;
    aarch64*/aarch64)
      NFQWS_URL="https://example.com/zapret/nfqws-aarch64"
      ;;
    *)
      NFQWS_URL=""
      ;;
  esac
fi

opkg update
opkg install $PKGS || true

# If a local artifact is provided, install it; otherwise try to download by URL
if [ -x /root/openwrt/artifacts/nfqws ]; then
  echo "Installing local nfqws artifact"
  mkdir -p /usr/sbin
  cp -f /root/openwrt/artifacts/nfqws /usr/sbin/nfqws
  chmod +x /usr/sbin/nfqws
elif [ -n "$NFQWS_URL" ]; then
  echo "Downloading nfqws from $NFQWS_URL"
  mkdir -p /usr/sbin
  if wget -O /usr/sbin/nfqws "$NFQWS_URL"; then
    chmod +x /usr/sbin/nfqws 2>/dev/null || true
  else
    echo "Failed to download nfqws; please place it manually in /usr/sbin/nfqws"
  fi
else
  echo "NOTE: NFQWS_URL is empty and no local artifact found. Place nfqws binary into /usr/sbin/nfqws manually or set NFQWS_URL."
fi

# Copy rootfs files
cp -vr /root/openwrt/rootfs/* /

# Ensure permissions
chmod +x /etc/init.d/zapret /etc/zapret/zapret.sh 2>/dev/null || true

# Enable service if config says enabled
ENABLED=$(uci -q get zapret.config.enabled || echo 1)
/etc/init.d/zapret enable
if [ "$ENABLED" = "1" ]; then
  /etc/init.d/zapret start || true
fi

# Reload LuCI
/etc/init.d/uhttpd reload 2>/dev/null || true
/etc/init.d/rpcd restart 2>/dev/null || true

echo "Installation finished. Open LuCI -> Services -> Zapret to configure."
