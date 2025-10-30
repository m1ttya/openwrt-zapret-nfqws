# Chat Summary: Zapret OpenWrt Adaptation (nfqws + nftables + LuCI)

Overview
- Goal: adapt Windows zapret batch setup (WinDivert + winws) to OpenWrt using nfqws and nftables, with LuCI UI and one-shot installer.
- Target device: TP-Link TL-WDR3500 (ath79, MIPS 24kc).

What’s implemented
- OpenWrt service (procd) to run nfqws and manage nftables rules.
- UCI config at /etc/config/zapret with Enable, interfaces, queue, ports, mode, profile, ipset settings.
- Auto-detection of LAN/WAN (if_lan=auto, if_wan=auto) using ubus/uci; works out-of-the-box on typical ath79 setups.
- LuCI app (Services -> Zapret) with Start/Stop/Restart and preset profiles mirroring Windows .bat variants.
- IP ranges integration via nft set (optional): loads /etc/zapret/lists/ipset-all.txt into nft set zapret_ipset and adds dst ip matches.
- Packaging: mk_ipk.sh builds zapret.ipk (service+config+lists and optional nfqws) and luci-app-zapret.ipk (UI).
- Installer script install.sh sets dependencies, deploys files, reloads LuCI, and can download nfqws if URL provided.
- Online one-line installer openwrt/online_install.sh (supports NFQWS_URL/NFQWS_IPK_URL, logs to /tmp/zapret_install.log, uses uclient-fetch to save flash).
- QUIC/unknown-UDP emulation enabled when /etc/zapret/quic_initial_www_google_com.bin exists.
- NFT scripts fixed: no shell redirection inside nft language, no duplicate jumps; ipset rules prepended.

Key directories and files
- openwrt/rootfs/etc/init.d/zapret — procd service (reads UCI, builds nft rules, runs nfqws)
- openwrt/rootfs/etc/config/zapret — UCI config (supports 'auto' for interfaces)
- openwrt/rootfs/usr/lib/lua/luci/... — LuCI controller, CBI model, and view
- openwrt/rootfs/etc/zapret/ — binaries/data: tls_clienthello_www_google_com.bin, quic_initial_www_google_com.bin; lists/**
- openwrt/install.sh — one-shot SSH installer (WITH_LUCI_SSL optional to save space)
- openwrt/online_install.sh — one-line installer (uclient-fetch first, wget fallback, detailed steps)
- openwrt/mk_ipk.sh — builds .ipk packages (optionally embeds nfqws from openwrt/artifacts/nfqws)
- openwrt/pkg/BUILD_NFQWS.md — how to build nfqws for ath79 (MIPS 24kc)
- openwrt/pkg/README_PACKAGING.md — package building notes

Install options
- One-line online (recommended): see INSTALL_ONELINER.txt or README (uses online_install.sh).
- SSH installer: scp -r openwrt root@ROUTER:/root/ && ssh root@ROUTER 'sh /root/openwrt/install.sh'
- LuCI IPK: build via mk_ipk.sh, then upload zapret.ipk and luci-app-zapret.ipk.

LuCI usage
- Services -> Zapret: toggle Enable, select Profile (Windows .bat analogs), optionally tweak Base desync mode, IP set options, hostlist path.
- Buttons: Start, Stop, Restart.

Profiles (presets matching .bat)
- general, simple_fake, fake_tls_auto, simple_fake_alt, fake_tls_auto_alt, fake_tls_auto_alt2, fake_tls_auto_alt3,
  alt, alt2, alt3, alt4, alt5 (syndata; not recommended), alt6, alt7, alt8.

Auto interface detection (defaults)
- if_lan=auto: prefers br-lan; falls back to interface.lan via ubus/uci.
- if_wan=auto: uses ubus network.interface.wan l3_device/device; falls back to UCI (network.wan.device/ifname).

IP ranges (nft set) integration
- Enable in UCI/LuCI: ipset_enable=1, ipset_path=/etc/zapret/lists/ipset-all.txt.
- Service creates inet fw4 set zapret_ipset and matches dst IP alongside port rules.

Commands reference
- Enable service: /etc/init.d/zapret enable
- Start/Restart: /etc/init.d/zapret start | restart
- Check nft rules: nft list ruleset | grep zapret
- Logs: logread | grep zapret; ps w | grep nfqws

Low-flash considerations
- online_install.sh avoids installing wget-ssl/CA packages by preferring uclient-fetch.
- install.sh installs luci-ssl only if WITH_LUCI_SSL=1; saves several MB on small overlay.

Building nfqws for TL-WDR3500 (ath79)
- See openwrt/pkg/BUILD_NFQWS.md for SDK/toolchain steps.
- After building, place binary at openwrt/artifacts/nfqws to embed into zapret.ipk, or copy to /usr/sbin/nfqws.

Notes
- Requires: nftables, kmod-nft-queue, libnetfilter-queue (installer installs these).
- QUIC: /etc/zapret/quic_initial_www_google_com.bin is used for fake-quic/unknown-udp if present.

Next steps
- Build/provide nfqws for mips_24kc (musl) and use NFQWS_URL in installer for seamless setup.
- Optionally extend profiles or tune parameters for specific ISPs.
- Create a pull request with these additions once tested on device.
