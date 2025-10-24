m = Map("zapret", translate("Zapret"), translate("DPI bypass via nfqws and nftables"))

s = m:section(TypedSection, "zapret", translate("Settings"))
s.anonymous = true
s.addremove = false

enabled = s:option(Flag, "enabled", translate("Enable"))

if_lan = s:option(Value, "if_lan", translate("LAN interface"))
if_lan.datatype = "string"

if_wan = s:option(Value, "if_wan", translate("WAN interface"))
if_wan.datatype = "string"

queue_num = s:option(Value, "queue_num", translate("NFQUEUE number"))
queue_num.datatype = "uinteger"
queue_num.default = 100

ports_tcp = s:option(Value, "ports_tcp", translate("TCP ports (space-separated; ranges allowed like 50000-50100)"))
ports_tcp.default = "443"

ports_udp = s:option(Value, "ports_udp", translate("UDP ports (space-separated; ranges allowed like 19294-19344)"))
ports_udp.default = "443"

mode = s:option(ListValue, "mode", translate("Base desync mode"))
mode:value("auto", "auto")
mode:value("fake", "fake")
mode:value("split", "split")
mode:value("disorder", "disorder")

profile = s:option(ListValue, "profile", translate("Preset profile (like .bat variants)"))
profile:value("general", translate("General (multidisorder midsld, repeats=8, md5sig+badseq)"))
profile:value("simple_fake", translate("Simple Fake (repeats=6)"))
profile:value("fake_tls_auto", translate("Fake TLS Auto (multidisorder, midsld, repeats=11, badseq, TLS mods)"))
profile:value("simple_fake_alt", translate("Simple Fake Alt (badseq increment)"))
profile:value("fake_tls_auto_alt", translate("Fake TLS Auto Alt (fakedsplit, badseq inc, TLS mods)"))
profile:value("fake_tls_auto_alt2", translate("Fake TLS Auto Alt2 (multisplit seqovl=681 pos=1, TLS mods)"))
profile:value("fake_tls_auto_alt3", translate("Fake TLS Auto Alt3 (multisplit seqovl=681 pos=1, ts)"))
profile:value("alt", translate("ALT (fakedsplit, ts, fakedsplit-pattern=0x00)"))
profile:value("alt2", translate("ALT2 (multisplit, seqovl=652 pos=2)"))
profile:value("alt3", translate("ALT3 (fakedsplit pos=1 autottl, badseq, repeats=8)"))
profile:value("alt4", translate("ALT4 (multisplit + md5sig + fake TLS)"))
profile:value("alt5", translate("ALT5 (syndata) — not recommended"))
profile:value("alt6", translate("ALT6 (multisplit, seqovl=681 pos=1)"))
profile:value("alt7", translate("ALT7 (multisplit, pos=2 sniext+1, seqovl=679)"))
profile:value("alt8", translate("ALT8 (fake+split2, badseq inc=2, fake-tls-mod=none)"))

hostlist = s:option(Value, "hostlist", translate("Host list path"))
hostlist.default = "/etc/zapret/lists/list-general.txt"

ipset_enable = s:option(Flag, "ipset_enable", translate("Enable IP set matching (dst IP)"))
ipset_path = s:option(Value, "ipset_path", translate("IP set file path"))
ipset_path.default = "/etc/zapret/lists/ipset-all.txt"

extra_opts = s:option(Value, "extra_opts", translate("Extra nfqws options"))

btns = s:option(DummyValue, "buttons", translate("Control"))
btns.template = "zapret/controls"

return m
