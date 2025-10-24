local http = require "luci.http"
local util = require "luci.util"

if http.formvalue("start") then
  util.exec("/etc/init.d/zapret start")
elseif http.formvalue("stop") then
  util.exec("/etc/init.d/zapret stop")
elseif http.formvalue("restart") then
  util.exec("/etc/init.d/zapret restart")
end
