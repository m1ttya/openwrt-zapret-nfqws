module("luci.controller.zapret", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/zapret") then
        return
    end
    entry({"admin", "services", "zapret"}, call("action_zapret"), _("Zapret"), 60)
end

function action_zapret()
    local http = require "luci.http"
    local util = require "luci.util"
    if http.formvalue("start") then
        util.exec("/etc/init.d/zapret start")
    elseif http.formvalue("stop") then
        util.exec("/etc/init.d/zapret stop")
    elseif http.formvalue("restart") then
        util.exec("/etc/init.d/zapret restart")
    end
    luci.cbi("zapret"):render()
end
