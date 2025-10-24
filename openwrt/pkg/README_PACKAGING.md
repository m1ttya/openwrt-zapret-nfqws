Packaging into .ipk on router

This project includes a simple layout to build two packages:
- zapret (service, configs, lists)
- luci-app-zapret (LuCI UI)

Steps on the router:
1) Copy repo to /root/openwrt
2) Run /root/openwrt/mk_ipk.sh
3) Install generated IPKs from /root/openwrt/bin/ with: opkg install /root/openwrt/bin/*.ipk

Notes:
- This is a lightweight packager using tar/ar; it does not compile anything.
- Ensure /usr/sbin/nfqws exists or set NFQWS_URL in install.sh.
