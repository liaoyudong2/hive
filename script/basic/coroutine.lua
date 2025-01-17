-- coroutine.lua
local tpack      = table.pack
local tunpack    = table.unpack
local raw_yield  = coroutine.yield
local raw_resume = coroutine.resume
local co_running = coroutine.running

local co_hookor  = hive.load("co_hookor")

--协程改造
function hive.init_coroutine()
    coroutine.yield  = function(...)
        if co_hookor then
            co_hookor:yield(co_running())
        end
        return raw_yield(...)
    end
    coroutine.resume = function(co, ...)
        if co_hookor then
            co_hookor:yield(co_running())
            co_hookor:resume(co)
        end
        local args = tpack(raw_resume(co, ...))
        if co_hookor then
            co_hookor:resume(co_running())
        end
        return tunpack(args)
    end
    hive.eval        = function(name)
        if co_hookor then
            return co_hookor:eval(name, co_running())
        end
    end
end

function hive.hook_coroutine(hooker)
    co_hookor      = hooker
    hive.co_hookor = hooker
end
