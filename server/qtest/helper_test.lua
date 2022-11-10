local lhelper = require("lhelper")
local luabus  = require("luabus")

logger.debug("mem_available:%s",lhelper.mem_available())
logger.debug("cpu_use_percent:%s",lhelper.cpu_use_percent())
logger.debug("cpu_core_num:%s",lhelper.cpu_core_num())
logger.debug("mem_usage:%s",lhelper.mem_usage())

logger.debug("[%s] dns: [%s]", "www.baidu.com", luabus.dns("git.ids111.com"))

-- return name type: 'ipv4', 'ipv6', or 'hostname'
local function guess_name_type(name)
    if name:match("^[%d%.]+$") then
        return "ipv4"
    end
    if name:find(":") then
        return "ipv6"
    end
    return "hostname"
end

logger.debug("ip:%s", guess_name_type("192.168.1.13"))
logger.debug("ip:%s", guess_name_type("192.168.1.13:jfdkalj"))
logger.debug("ip:%s", guess_name_type("baidu.com"))
logger.debug("ip:%s", guess_name_type("git.ids111.com"))

logger.debug("lan ip:%s,port:8080:%s", luabus.lan_ip(), luabus.port_is_used(8080))
