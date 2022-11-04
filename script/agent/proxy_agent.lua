--proxy_agent.lua
local sformat    = string.format
local log_info   = logger.info
local scheduler  = hive.get("scheduler")

local ProxyAgent = singleton()
local prop       = property(ProxyAgent)
prop:reader("service_name", "proxy")          --地址
prop:reader("run_thread", false) --是否启用子线程
prop:reader("proxy_mgr", nil)

function ProxyAgent:__init()
    self.run_thread = environ.status("HIVE_OPEN_WORK_THREAD")
    if self.run_thread then
        --启动代理线程
        scheduler:startup(self.service_name, "proxy")
        --日志上报
        if environ.status("HIVE_LOG_REPORT") then
            logger.add_monitor(self)
            log_info("[ProxyAgent][__init] open hive log report!!!")
        end
    else
        import("proxy/proxy_mgr.lua")
        self.proxy_mgr = hive.get("proxy_mgr")
    end
end

--日志分发
function ProxyAgent:dispatch_log(content, lvl_name, lvl)
    local title = sformat("[%s][%s]", hive.service_name, lvl_name)
    if self.proxy_mgr then
        self.proxy_mgr:rpc_dispatch_log(title, content, lvl)
    else
        scheduler:send(self.service_name, "rpc_dispatch_log", title, content, lvl)
    end
end

function ProxyAgent:get(url, querys, headers)
    if self.proxy_mgr then
        return true, self.proxy_mgr:rpc_http_get(url, querys, headers)
    end
    return scheduler:call(self.service_name, "rpc_http_get", url, querys, headers)
end

function ProxyAgent:post(url, post_data, headers, querys)
    if self.proxy_mgr then
        return true, self.proxy_mgr:rpc_http_post(url, post_data, headers, querys)
    end
    return scheduler:call(self.service_name, "rpc_http_post", url, post_data, headers, querys)
end

function ProxyAgent:put(url, post_data, headers, querys)
    if self.proxy_mgr then
        return true, self.proxy_mgr:rpc_http_put(url, post_data, headers, querys)
    end
    return scheduler:call(self.service_name, "rpc_http_put", url, post_data, headers, querys)
end

function ProxyAgent:del(url, querys, headers)
    if self.proxy_mgr then
        return true, self.proxy_mgr:rpc_http_del(url, querys, headers)
    end
    return scheduler:call(self.service_name, "rpc_http_del", url, querys, headers)
end

hive.proxy_agent = ProxyAgent()

return ProxyAgent
