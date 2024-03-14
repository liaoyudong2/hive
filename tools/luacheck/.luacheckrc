-- 单个全局变量 
self=false
-- 全局变量集合
stds.hive = {
    globals = {
        --common
        "tonumber", "coroutine", "ncmd_cs", "ncmd_ds","set_env",
        "table_ext", "string_ext", "math_ext", "http_helper", "redis_key", "io_ext","datetime_ext", "mongo_key",
        "hive", "environ", "signal", "http", "luabt", "service", "logger", "utility",
        "import", "class", "enum", "enum_kv_list", "mixin", "property", "singleton", "super", "implemented","logfeature",
        "classof", "is_class", "is_subclass", "instanceof","conv_class","class_review",
        --library
        "luakit","codec", "crypt", "stdfs", "luabus", "json", "curl", "timer", "log", "http", "bson","protobuf",
    }
}
std = "max+hive"
-- 排除文件
exclude_files = {
    "../../tools/",
	"../../server/qtest/",
	"../../script/third/"
}
-- 圈复杂度
max_cyclomatic_complexity = 30
-- 最大代码长度
max_code_line_length = 220
-- 最大注释长度
max_comment_line_length = 180
-- 忽略警告
ignore = {
    "212", "213", "512",
    "21/_.*" --(W212)unused argument '_arg'
}

-- 更多配置参考 https://luacheck.readthedocs.io/en/stable/config.html