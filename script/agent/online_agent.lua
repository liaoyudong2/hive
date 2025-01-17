--online_agent.lua
local log_info      = logger.info
local log_debug     = logger.debug
local tunpack       = table.unpack
local tinsert       = table.insert
local sname2sid     = service.name2sid

local event_mgr     = hive.get("event_mgr")
local router_mgr    = hive.get("router_mgr")
local monitor       = hive.get("monitor")
local protobuf_mgr  = hive.get("protobuf_mgr")

local SUCCESS       = hive.enum("KernCode", "SUCCESS")
local LOGIC_FAILED  = hive.enum("KernCode", "LOGIC_FAILED")
local check_success = hive.success

local OnlineAgent   = singleton()
local prop          = property(OnlineAgent)
prop:reader("open_ids", {})
prop:reader("player_ids", {})

function OnlineAgent:__init()
    event_mgr:add_listener(self, "rpc_forward_client")
    event_mgr:add_listener(self, "rpc_forward_group_client")
    self.lobby_sid = sname2sid("lobby")

    if hive.service_name == "lobby" then
        monitor:watch_service_ready(self, "login")
        monitor:watch_service_ready(self, "router")
    end
end

--执行远程rpc消息
function OnlineAgent:cas_dispatch_lobby(open_id, lobby_id)
    return router_mgr:call_login_hash(open_id, "rpc_cas_dispatch_lobby", open_id, lobby_id)
end

function OnlineAgent:login_dispatch_lobby(open_id)
    local ok, code = router_mgr:call_login_hash(open_id, "rpc_login_dispatch_lobby", open_id, hive.id)
    if check_success(code, ok) then
        self.open_ids[open_id] = true
    end
    return ok, code
end

function OnlineAgent:rm_dispatch_lobby(open_id)
    router_mgr:send_login_hash(open_id, "rpc_rm_dispatch_lobby", open_id, hive.id)
    self.open_ids[open_id] = nil
end

function OnlineAgent:login_player(player_id)
    router_mgr:call_router(player_id, "rpc_set_player_service", { player_id }, hive.id, 1)
    return true, SUCCESS
end

function OnlineAgent:logout_player(player_id)
    router_mgr:call_router(player_id, "rpc_set_player_service", { player_id }, hive.id, 0)
end

function OnlineAgent:query_openid(open_id)
    return router_mgr:call_login_hash(open_id, "rpc_query_openid", open_id)
end

function OnlineAgent:query_player(player_id)
    local ok, lobby_id = router_mgr:call_router(player_id, "rpc_query_player_service", player_id, self.lobby_sid)
    return ok, ok and SUCCESS or LOGIC_FAILED, ok and lobby_id or 0
end

--有序
function OnlineAgent:call_lobby(player_id, rpc, ...)
    return router_mgr:call_lobby_player(player_id, rpc, ...)
end

function OnlineAgent:send_lobby(player_id, rpc, ...)
    return router_mgr:send_lobby_player(player_id, rpc, ...)
end
--player_id在线的lobby将收到rpc
function OnlineAgent:send_group_lobby(player_ids, rpc, ...)
    router_mgr:group_lobby_player(player_ids, rpc, ...)
end

function OnlineAgent:call_client(player_id, cmd_id, msg)
    msg = self:encode_msg(player_id, cmd_id, msg)
    return router_mgr:call_lobby_player(player_id, "rpc_forward_client", player_id, cmd_id, msg)
end

function OnlineAgent:send_client(player_id, cmd_id, msg)
    msg = self:encode_msg(player_id, cmd_id, msg)
    return router_mgr:send_lobby_player(player_id, "rpc_forward_client", player_id, cmd_id, msg)
end

function OnlineAgent:send_group_client(player_ids, cmd_id, msg)
    msg = self:encode_msg(0, cmd_id, msg)
    if not player_ids or next(player_ids) == nil then
        return router_mgr:send_lobby_all("rpc_forward_group_client", player_ids, cmd_id, msg)
    end
    router_mgr:group_lobby_player(player_ids, "rpc_forward_group_client", player_ids, cmd_id, msg)
end

function OnlineAgent:send_lobby_client(lobby_id, player_id, cmd_id, msg)
    msg = self:encode_msg(player_id, cmd_id, msg)
    router_mgr:send_target(lobby_id, "rpc_forward_client", player_id, cmd_id, msg)
end

function OnlineAgent:encode_msg(player_id, cmd_id, msg)
    log_debug("[S2C] player_id:{},cmd_id:{},cmd:{},msg:{}", player_id, cmd_id, protobuf_mgr:msg_name(cmd_id), msg)
    return protobuf_mgr:encode(cmd_id, msg)
end

--rpc处理
------------------------------------------------------------------
--透传给client的消息
--需由player_mgr实现on_forward_client，给client发消息
function OnlineAgent:rpc_forward_client(player_id, cmd_id, msg)
    local ok, res = tunpack(event_mgr:notify_listener("on_forward_client", player_id, cmd_id, msg))
    return ok and SUCCESS or LOGIC_FAILED, res
end

function OnlineAgent:rpc_forward_group_client(player_ids, cmd_id, msg)
    local ok, res = tunpack(event_mgr:notify_listener("on_forward_group_client", player_ids, cmd_id, msg))
    return ok and SUCCESS or LOGIC_FAILED, res
end

-- Online服务已经ready
function OnlineAgent:on_service_ready(id, service_name)
    log_info("[OnlineAgent][on_service_ready]->service_name:{}", service.id2nick(id))
    self:on_rebuild_online(id, service_name)
end

-- online数据恢复
function OnlineAgent:on_rebuild_online(id, service_name)
    if service_name == "login" then
        local open_ids = {}
        for open_id, _ in pairs(self.open_ids) do
            tinsert(open_ids, open_id)
        end
        log_info("[OnlineAgent][on_rebuild_online]->rebuild login_lobby:{}", #open_ids)
        router_mgr:send_target(id, "rpc_rebuild_login_lobby", open_ids, hive.id)
    else
        local player_ids = {}
        for player_id, _ in pairs(self.player_ids) do
            tinsert(player_ids, player_id)
        end
        log_info("[OnlineAgent][on_rebuild_online]->rebuild router_lobby:{}", #player_ids)
        router_mgr:send_router(hive.id, "rpc_set_player_service", player_ids, hive.id, 1)
    end
end

hive.online_agent = OnlineAgent()

return OnlineAgent
