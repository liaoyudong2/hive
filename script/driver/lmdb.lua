--lmdb.lua
local lmdb         = require("lmdb")
local log_info     = logger.info
local sformat      = string.format

local MDB_SUCCESS  = lmdb.MDB_CODE.MDB_SUCCESS
local MDB_NOTFOUND = lmdb.MDB_CODE.MDB_NOTFOUND

local MDB_NOSUBDIR = lmdb.MDB_ENV_FLAG.MDB_NOSUBDIR

local MDB_FIRST    = lmdb.MDB_CUR_OP.MDB_FIRST
local MDB_NEXT     = lmdb.MDB_CUR_OP.MDB_NEXT
local MDB_SET      = lmdb.MDB_CUR_OP.MDB_SET

local LMDB_PATH    = environ.get("HIVE_LMDB_PATH", "./lmdb/")

local Lmdb         = class()
local prop         = property(Lmdb)
prop:reader("driver", nil)
prop:reader("dbname", nil)
prop:reader("jcodec", nil)

function Lmdb:__init()
    stdfs.mkdir(LMDB_PATH)
end

function Lmdb:open(name, dbname)
    if not self.driver then
        local driver = lmdb.create()
        local jcodec = json.jsoncodec()
        driver.set_max_dbs(128)
        driver.set_codec(jcodec)
        local rc    = driver.open(sformat("%s%s.mdb", LMDB_PATH, name), MDB_NOSUBDIR, 0644)
        self.driver = driver
        self.jcodec = jcodec
        self.dbname = dbname
        log_info("[Lmdb][open] open lmdb {}:{}!", name, rc)
    end
end

function Lmdb:puts(objects, dbname)
    return self.driver.batch_put(objects, dbname or self.dbname) == MDB_SUCCESS
end

function Lmdb:put(key, value, dbname)
    log_info("[Lmdb][put] {}.{}={}", key, dbname, value)
    return self.driver.easy_put(key, value, dbname or self.dbname) == MDB_SUCCESS
end

function Lmdb:get(key, dbname)
    local data, rc = self.driver.easy_get(key, dbname or self.dbname)
    log_info("[Lmdb][get] {}.{}={}={}", key, dbname, data, rc)
    if data then
        return data, true
    end
    if rc == MDB_NOTFOUND or rc == MDB_SUCCESS then
        return nil, true
    end
    return nil, false
end

function Lmdb:gets(keys, dbname)
    local res, rc = self.driver.batch_get(keys, dbname or self.dbname)
    if rc == MDB_SUCCESS then
        return res, true
    end
    return nil, false
end

function Lmdb:del(key, dbname)
    return self.driver.easy_del(key, dbname or self.dbname)
end

function Lmdb:dels(keys, dbname)
    return self.driver.batch_del(keys, dbname or self.dbname) == MDB_SUCCESS
end

--迭代器
function Lmdb:iter(dbname, key)
    local flag   = nil
    local driver = self.driver
    driver.cursor_open(dbname or self.dbname)
    local function iter()
        local v, k
        if not flag then
            flag = MDB_NEXT
            v, k = driver.cursor_get(key, key and MDB_SET or MDB_FIRST)
        else
            v, k = driver.cursor_get(key, flag)
        end
        if not v then
            driver.cursor_close()
        end
        return k, v
    end
    return iter
end

return Lmdb
