Build nfqws for OpenWrt ath79 (MIPS 24kc)

Option A: Build on SDK
1) Download OpenWrt SDK matching your router firmware (ath79, same version).
2) Unpack and set feeds (include packages needed to build zapret/nfqws if available), or build nfqws statically from bol-van/zapret sources:
   - make menuconfig (set TARGET=ath79, Toolchain, etc.)
   - Ensure libnetfilter-queue and dependencies are available (or build static).
3) Build nfqws from source and copy the resulting binary to openwrt/artifacts/nfqws.

Option B: Cross-compile with musl toolchain
1) Use OpenWrt musl toolchain for mips_24kc (big endian), compile nfqws statically.
2) Place binary at openwrt/artifacts/nfqws (chmod +x).

After placing binary
- Run openwrt/mk_ipk.sh to build zapret.ipk including the nfqws binary.
- Install via LuCI -> System -> Software -> Upload Package.
