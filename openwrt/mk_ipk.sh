#!/bin/sh
set -e
ROOT=$(pwd)/openwrt
OUT=$ROOT/bin
WORK=$ROOT/pkg/work
PKGBASE=zapret
LUCIPKG=luci-app-zapret

rm -rf "$OUT" "$WORK"
mkdir -p "$OUT" "$WORK"

# Package: zapret
ZP=$WORK/$PKGBASE
mkdir -p $ZP/CONTROL $ZP/data
ARCH=all
[ -x $ROOT/artifacts/nfqws ] && ARCH=$(opkg print-architecture 2>/dev/null | awk 'END{print $2}')
cat > $ZP/CONTROL/control <<EOF
Package: zapret
Version: 1.0-1
Architecture: $ARCH
Maintainer: You
Section: net
Priority: optional
Description: Zapret nfqws service and config
Depends: nftables, libnetfilter-queue, kmod-nft-queue
EOF
cat > $ZP/CONTROL/postinst <<'EOF'
#!/bin/sh
[ -n "$IPKG_INSTROOT" ] || /etc/init.d/zapret enable
exit 0
EOF
chmod +x $ZP/CONTROL/postinst

# copy files
mkdir -p $ZP/data
cp -a $ROOT/rootfs/etc/init.d/zapret $ZP/data/etc/init.d/
cp -a $ROOT/rootfs/etc/config/zapret $ZP/data/etc/config/
cp -a $ROOT/rootfs/etc/zapret $ZP/data/etc/
# optionally include nfqws binary if provided at openwrt/artifacts/nfqws
if [ -x $ROOT/artifacts/nfqws ]; then
  mkdir -p $ZP/data/usr/sbin
  cp -a $ROOT/artifacts/nfqws $ZP/data/usr/sbin/nfqws
fi

# build ipk
( cd $ZP/data && find . | sort | tar --mtime='UTC 2020-01-01' --owner=0 --group=0 -cO . | gzip -n > ../data.tar.gz )
( cd $ZP/CONTROL && tar --mtime='UTC 2020-01-01' --owner=0 --group=0 -cO . | gzip -n > ../control.tar.gz )
echo '2.0' > $ZP/debian-binary
( cd $ZP && tar -cf $OUT/$PKGBASE.ipk control.tar.gz data.tar.gz debian-binary )

# Package: LuCI app
LP=$WORK/$LUCIPKG
mkdir -p $LP/CONTROL $LP/data
cat > $LP/CONTROL/control <<'EOF'
Package: luci-app-zapret
Version: 1.0-1
Architecture: all
Maintainer: You
Section: luci
Priority: optional
Description: LuCI interface for zapret
Depends: luci
EOF

# copy LuCI files
mkdir -p $LP/data
cp -a $ROOT/rootfs/usr/lib/lua/luci $LP/data/usr/lib/lua/

# build ipk
( cd $LP/data && find . | sort | tar --mtime='UTC 2020-01-01' --owner=0 --group=0 -cO . | gzip -n > ../data.tar.gz )
( cd $LP/CONTROL && tar --mtime='UTC 2020-01-01' --owner=0 --group=0 -cO . | gzip -n > ../control.tar.gz )
echo '2.0' > $LP/debian-binary
( cd $LP && tar -cf $OUT/$LUCIPKG.ipk control.tar.gz data.tar.gz debian-binary )

echo "Built: $OUT/$PKGBASE.ipk and $OUT/$LUCIPKG.ipk"
