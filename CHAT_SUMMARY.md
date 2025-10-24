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

Key directories and files
- openwrt/rootfs/etc/init.d/zapret — procd service (reads UCI, builds nft rules, runs nfqws)
- openwrt/rootfs/etc/config/zapret — UCI config (supports 'auto' for interfaces)
- openwrt/rootfs/usr/lib/lua/luci/... — LuCI controller, CBI model, and view
- openwrt/rootfs/etc/zapret/lists/ — host and IP lists (list-general.txt, ipset-all.txt)
- openwrt/rootfs/etc/zapret/tls_clienthello_www_google_com.bin — placeholder; replace with real sample if needed
- openwrt/install.sh — one-shot SSH installer
- openwrt/mk_ipk.sh — builds .ipk packages (optionally embeds nfqws from openwrt/artifacts/nfqws)
- openwrt/pkg/BUILD_NFQWS.md — how to build nfqws for ath79 (MIPS 24kc)
- openwrt/pkg/README_PACKAGING.md — package building notes

Install via SSH (Option A)
1) Copy and run installer:
   scp -r openwrt root@ROUTER:/root/
   ssh root@ROUTER 'sh /root/openwrt/install.sh'
2) Provide nfqws binary if not auto-downloaded:
   scp nfqws root@ROUTER:/usr/sbin/
   ssh root@ROUTER 'chmod +x /usr/sbin/nfqws'
3) Open LuCI -> Services -> Zapret. Enable, pick a profile, Save & Apply, Start/Restart.

Install via LuCI IPK (Option B)
1) (Optional) Place nfqws binary at openwrt/artifacts/nfqws (chmod +x) to embed into zapret.ipk.
2) Build packages on router:
   ssh root@ROUTER 'sh /root/openwrt/mk_ipk.sh'
3) LuCI -> System -> Software -> Upload Package: install /root/openwrt/bin/zapret.ipk and /root/openwrt/bin/luci-app-zapret.ipk.

LuCI usage
- Services -> Zapret: toggle Enable, select Profile (Windows .bat analogs), optionally tweak Base desync mode, IP set options, hostlist path.
- Buttons: Start, Stop, Restart.

Profiles (presets matching .bat)
- general
- simple_fake
- fake_tls_auto
- simple_fake_alt
- fake_tls_auto_alt
- fake_tls_auto_alt2
- fake_tls_auto_alt3
- alt
- alt2
- alt3
- alt4
- alt5 (syndata; not recommended)
- alt6
- alt7
- alt8

Auto interface detection (defaults)
- if_lan=auto: prefers br-lan; falls back to interface.lan via ubus/uci.
- if_wan=auto: uses ubus network.interface.wan l3_device/device; falls back to UCI (network.wan.device / ifname).

IP ranges (nft set) integration
- Enable in UCI/LuCI: ipset_enable=1, ipset_path=/etc/zapret/lists/ipset-all.txt.
- Service will create inet fw4 set zapret_ipset and match dst IP alongside port rules.

Commands reference
- Enable service: /etc/init.d/zapret enable
- Start/Restart: /etc/init.d/zapret start | restart
- Check nft rules: nft list ruleset | grep zapret
- Logs: logread | grep zapret; ps w | grep nfqws

Building nfqws for TL-WDR3500 (ath79)
- See openwrt/pkg/BUILD_NFQWS.md for SDK/toolchain steps.
- After building, place binary at openwrt/artifacts/nfqws to embed into zapret.ipk, or copy to /usr/sbin/nfqws.

Notes
- Requires: nftables, kmod-nft-queue, libnetfilter-queue (installer installs these).
- QUIC issues: remove 443 from UDP ports or adjust nfqws options (EXTRA_OPTS) in UCI/LuCI.
- Replace tls_clienthello_www_google_com.bin placeholder with real sample if your preset needs it.

Next steps
- Build nfqws for ath79 and embed into ipk for one-click LuCI install.
- Optionally extend profiles or tune parameters for specific ISPs.
- Create a pull request with these additions once tested on device.
