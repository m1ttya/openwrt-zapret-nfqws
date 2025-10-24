#!/bin/sh
# Helper to test-run nfqws manually based on config
. /etc/zapret/zapret.conf

/usr/sbin/nfqws --qnum $QUEUE_NUM \
  --dpi-desync=${MODE:-auto} \
  --hostlist "$HOSTLIST" $EXTRA_OPTS
