Zapret for OpenWrt (nfqws + nftables)

Overview
- This adapts the Windows batch-based setup (WinDivert + winws) to OpenWrt using the Linux equivalent (nfqws) from the zapret project and nftables (fw4) rules.
- It targets bypassing DPI for YouTube/Discord/etc via TLS/QUIC desynchronization similar to the Windows setup.

Components
- /etc/init.d/zapret: Procd service to manage nftables rules and the nfqws process (reads UCI config)
- /etc/config/zapret: UCI configuration (mode, interfaces, queue number, ports, enabled). Interfaces support 'auto' autodetection.
- /etc/zapret/lists/: Host/domain lists reused from this repo (list-general.txt, ipset-all.txt)
- LuCI UI: Services -> Zapret (controller+CBI) for switching modes/presets and starting/stopping

Requirements on OpenWrt
- Tested on OpenWrt 22.03+ (fw4, nftables). For 21.02 (iptables), manual adjustments may be required.
- Packages to install:
  opkg update && opkg install kmod-nfnetlink kmod-nft-core kmod-nft-netdev \
    kmod-nft-queue libnetfilter-queue nftables ca-bundle luci-ssl
  # For nfqws binary (preferred from bol-van/zapret builds):
  # 1) Download nfqws for your CPU arch to /usr/sbin/nfqws and chmod +x
  # 2) Or build from source on OpenWrt SDK

Install
One-line online install (like amneziawg)
- Run on the router:
  wget -O - "https://raw.githubusercontent.com/m1ttya/openwrt-zapret-nfqws/main/openwrt/online_install.sh" | sh
- Optional: pass NFQWS_URL if you want auto-download of nfqws for your arch
  wget -O - "https://raw.githubusercontent.com/m1ttya/openwrt-zapret-nfqws/main/openwrt/online_install.sh" | NFQWS_URL="https://.../nfqws-arch" sh
- Optional overrides in the same line (examples): PROFILE=general ENABLE=1 IF_LAN=auto IF_WAN=auto PORTS_UDP="443 19294-19344 50000-50100"


Option A: One-shot installer over SSH (recommended)
1) Copy the openwrt folder to the router and run the installer:
   - scp -r openwrt root@ROUTER:/root/
   - ssh root@ROUTER 'sh /root/openwrt/install.sh'
   The installer will:
   - opkg install required packages (nftables, libnetfilter-queue, kmod-nft-queue, luci-ssl, etc.)
   - install nfqws automatically if provided as openwrt/artifacts/nfqws or via NFQWS_URL
   - deploy service, config, lists, LuCI UI, reload uhttpd
   - enable and start the service if enabled in UCI

Option B: Manual
1) Copy files to router (adjust path if needed):
   - scp -r openwrt/rootfs/* root@ROUTER:/
   This will place files under /etc/init.d/zapret, /etc/zapret/, and LuCI files.
2) Put nfqws binary into /usr/sbin/nfqws and make it executable (or set NFQWS_URL and use install.sh):
   - scp nfqws root@ROUTER:/usr/sbin/
   - ssh root@ROUTER 'chmod +x /usr/sbin/nfqws'
3) Enable and start service:
   - /etc/init.d/zapret enable
   - /etc/init.d/zapret start

Configuration (UCI)
- /etc/config/zapret (also editable via LuCI -> Services -> Zapret):
  - enabled: 1/0
  - mode: desync strategy (fake/split/disorder/auto)
  - queue_num: NFQUEUE number (default 100)
  - if_lan: LAN interface (e.g., br-lan). Default 'auto' tries br-lan or interface.lan.
  - if_wan: WAN device (e.g., pppoe-wan, eth0). Default 'auto' tries ubus network.interface.wan l3_device/device or UCI fallback.
  - ports_tcp / ports_udp: space-separated ports (usually 443)
  - hostlist: path to list of target domains (one per line)
  - extra_opts: extra nfqws options (e.g., -v, --dpi-desync-repeats=2)

Lists
- The original Windows bundle includes lists/lists-general.txt and ipset-all.txt.
- These are mapped to /etc/zapret/lists/*. You can edit them on the router.

Notes
- nftables rules only enqueue forwarded traffic from LAN to WAN on ports 443 (TCP/UDP). Local router traffic is not enqueued by default.
- Optional IP set matching (enable in LuCI/UCI) will load /etc/zapret/lists/ipset-all.txt into nft set zapret_ipset and add match by dst ip.
- If you use custom firewall, ensure no conflicting nft rules with higher priority drop/bypass your queue rules.

Packaging into IPK
- Optional: build .ipk packages on the router for easy install:
  - scp -r openwrt root@ROUTER:/root/
  - ssh root@ROUTER 'sh /root/openwrt/mk_ipk.sh'
  - ssh root@ROUTER 'opkg install /root/openwrt/bin/zapret.ipk /root/openwrt/bin/luci-app-zapret.ipk'

Uninstall
- /etc/init.d/zapret stop && /etc/init.d/zapret disable
- opkg remove luci-app-zapret zapret (if installed via IPK)
- Or manually remove /etc/init.d/zapret and /etc/zapret/

Troubleshooting
- Verify nfqws is running: ps w | grep nfqws
- Check nft rules exist: nft list ruleset | grep zapret
- Temporarily increase verbosity: set LOG_LEVEL=debug in config (adds -v to nfqws)
- If QUIC issues persist, try temporarily disabling UDP (remove 443 from PORTS_UDP) so traffic falls back to TCP.
