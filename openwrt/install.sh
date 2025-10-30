#!/bin/sh
set -e

# This script installs zapret service and LuCI app on OpenWrt.
# Usage: scp -r openwrt root@ROUTER:/root/ && ssh root@ROUTER 'sh /root/openwrt/install.sh'

# Minimal required packages (keep small footprint)
PKGS="kmod-nfnetlink kmod-nft-core kmod-nft-netdev kmod-nft-queue libnetfilter-queue nftables ca-bundle"
# Optional: install luci-ssl only if explicitly requested (saves several MB on flash)
if [ "${WITH_LUCI_SSL:-0}" = "1" ]; then
  PKGS="$PKGS luci-ssl"
fi
# Auto-pick nfqws URL for your arch if not overridden
NFQWS_URL="${NFQWS_URL:-}"
NFQWS_IPK_URL="${NFQWS_IPK_URL:-}"
if [ -z "$NFQWS_URL" ] && [ -z "$NFQWS_IPK_URL" ]; then
  ARCH="$(opkg print-architecture 2>/dev/null | awk 'END{print $2}')"
  CPU="$(uname -m)"
  # Map common arches. TL-WDR3500 ath79 => mips (big-endian 24kc)
  case "$ARCH/$CPU" in
    mips*/mips|mips*/mips32)
      # Replace with an actual URL to a static mips (big endian) nfqws build
      NFQWS_URL=""
      ;;
    mipsel*/mipsel|*mipsel*)
      NFQWS_URL=""
      ;;
    arm*/armv7l)
      NFQWS_URL=""
      ;;
    aarch64*/aarch64)
      NFQWS_URL=""
      ;;
    *)
      NFQWS_URL=""
      ;;
  esac
fi

opkg update
opkg install $PKGS || true

# If a local artifact is provided, install it; otherwise try to download by URL or install IPK
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
elif [ -n "$NFQWS_IPK_URL" ]; then
  echo "Installing nfqws IPK from $NFQWS_IPK_URL"
  TMPIPK="/tmp/nfqws.ipk"
  if wget -O "$TMPIPK" "$NFQWS_IPK_URL"; then
    if opkg install "$TMPIPK"; then
      echo "nfqws installed via opkg"
    else
      echo "opkg failed to install IPK; the package is likely incompatible with this device/arch."
      if command -v ar >/dev/null 2>&1; then
        echo "Attempting to extract binary from IPK using ar..."
        mkdir -p /tmp/nfqws-extract && cd /tmp/nfqws-extract
        ar x "$TMPIPK" || true
        if [ -f data.tar.gz ]; then
          tar -xzf data.tar.gz || true
        fi
        if [ -x ./usr/sbin/nfqws ]; then
          mkdir -p /usr/sbin
          cp -f ./usr/sbin/nfqws /usr/sbin/nfqws
          chmod +x /usr/sbin/nfqws
        else
          echo "Could not find nfqws binary in IPK; please provide NFQWS_URL for your architecture (e.g., mips_24kc) or place /usr/sbin/nfqws manually."
        fi
      else
        echo "'ar' is not available on this system; cannot extract IPK. Please provide NFQWS_URL for your architecture (e.g., mips_24kc) or place /usr/sbin/nfqws manually."
      fi
    fi
  else
    echo "Failed to download $NFQWS_IPK_URL"
  fi
else
  echo "NOTE: No nfqws provided (no artifact, NFQWS_URL or NFQWS_IPK_URL). Place nfqws into /usr/sbin/nfqws manually."
fi

# Copy rootfs files from the script directory (works for both SSH and online installer)
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
if [ -z "$SCRIPT_DIR" ]; then
  SCRIPT_DIR="/root/openwrt"
fi
if [ -d "$SCRIPT_DIR/rootfs" ]; then
  cp -vr "$SCRIPT_DIR/rootfs"/* /
else
  echo "ERROR: rootfs directory not found next to install.sh (SCRIPT_DIR=$SCRIPT_DIR)"
fi

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
