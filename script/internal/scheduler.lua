--scheduler.lua
local pcall              = pcall
local log_info           = logger.info
local log_err            = logger.err
local tunpack            = table.unpack

local worker_call        = hive.worker_call
local worker_broadcast   = hive.worker_broadcast
local worker_update      = hive.worker_update
local worker_names       = hive.worker_names

local FLAG_REQ           = hive.enum("FlagMask", "REQ")
local FLAG_RES           = hive.enum("FlagMask", "RES")
local THREAD_RPC_TIMEOUT = hive.enum("NetwkTime", "THREAD_RPC_TIMEOUT")
local KernCode           = enum("KernCode")

local event_mgr          = hive.get("event_mgr")
local thread_mgr         = hive.get("thread_mgr")

local Scheduler          = singleton()

function Scheduler:__init()
    hive.worker_setup("hive")
end

function Scheduler:quit()
    hive.worker_shutdown()
end

function Scheduler:update(clock_ms)
    worker_update(clock_ms)
end

function Scheduler:startup(name, entry)
    local ok, err = pcall(hive.worker_startup, name, entry, "internal/worker.lua")
    if not ok then
        log_err("[Scheduler][startup] startup failed: {}", err)
        return ok
    end
    log_info("[Scheduler][startup] startup {}: {}", name, entry)
    return ok
end

--访问其他线程任务
function Scheduler:broadcast(rpc, ...)
    worker_broadcast("", 0, FLAG_REQ, "master", rpc, ...)
end

function Scheduler:collect(rpc, ...)
    local names   = self:names()
    local adata   = {}
    local params  = table.pack(...)
    local channel = hive.make_channel("scheduler_collect")
    for _, name in ipairs(names or {}) do
        channel:push(function()
            local ok, code, data = self:call(name, rpc, table.unpack(params))
            if ok and code == KernCode.SUCCESS then
                adata[name] = data
                return true, KernCode.SUCCESS
            end
            return false, code
        end)
    end
    channel:execute(true)
    return adata
end

--访问其他线程任务
function Scheduler:call(name, rpc, ...)
    local session_id = thread_mgr:build_session_id()
    if worker_call(name, session_id, FLAG_REQ, "master", rpc, ...) then
        return thread_mgr:yield(session_id, rpc, THREAD_RPC_TIMEOUT)
    end
    return false, KernCode.RPC_FAILED
end

--访问其他线程任务
function Scheduler:send(name, rpc, ...)
    worker_call(name, 0, FLAG_REQ, "master", rpc, ...)
end

function Scheduler:names()
    return worker_names()
end

--事件分发
local function notify_rpc(session_id, title, rpc, ...)
    local rpc_datas = event_mgr:notify_listener(rpc, ...)
    if session_id > 0 then
        worker_call(title, session_id, FLAG_RES, tunpack(rpc_datas))
    end
end

function hive.on_scheduler(session_id, flag, ...)
    if flag == FLAG_REQ then
        thread_mgr:fork(notify_rpc, session_id, ...)
        return
    end
    thread_mgr:response(session_id, ...)
end

hive.scheduler = Scheduler()

return Scheduler
