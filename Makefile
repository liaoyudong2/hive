empty:
	@echo "====No target! Please specify a target to make!"
	@echo "====If you want to compile all targets, use 'make server'"
	@echo "===='make all', which shoule be the default target is unavailable for UNKNOWN reaseon now."

CUR_DIR = $(shell pwd)/

.PHONY: clean all server  share lua luaext core

all: clean server 

server:  share lua luaext core

clean:
	rm -rf temp;

core:
	cd core/luna; make -j4 SOLUTION_DIR=$(CUR_DIR) -f luna.mak;
	cd core/plugins; make -j4 SOLUTION_DIR=$(CUR_DIR) -f lplugins.mak;
	cd core/luabus; make -j4 SOLUTION_DIR=$(CUR_DIR) -f luabus.mak;
	cd core/hive; make -j4 SOLUTION_DIR=$(CUR_DIR) -f hive.mak;

lua:
	cd extend/lua; make -j4 SOLUTION_DIR=$(CUR_DIR) -f lualib.mak;
	cd extend/lua; make -j4 SOLUTION_DIR=$(CUR_DIR) -f lua.mak;
	cd extend/lua; make -j4 SOLUTION_DIR=$(CUR_DIR) -f luac.mak;

luaext:
	cd extend/lbuffer; make -j4 SOLUTION_DIR=$(CUR_DIR) -f lbuffer.mak;
	cd extend/lcjson; make -j4 SOLUTION_DIR=$(CUR_DIR) -f lcjson.mak;
	cd extend/lcrypt; make -j4 SOLUTION_DIR=$(CUR_DIR) -f lcrypt.mak;
	cd extend/lcurl; make -j4 SOLUTION_DIR=$(CUR_DIR) -f lcurl.mak;
	cd extend/lhttp; make -j4 SOLUTION_DIR=$(CUR_DIR) -f lhttp.mak;
	cd extend/lkcp; make -j4 SOLUTION_DIR=$(CUR_DIR) -f lkcp.mak;
	cd extend/lstdfs; make -j4 SOLUTION_DIR=$(CUR_DIR) -f lstdfs.mak;
	cd extend/lualog; make -j4 SOLUTION_DIR=$(CUR_DIR) -f lualog.mak;
	cd extend/luaxlsx; make -j4 SOLUTION_DIR=$(CUR_DIR) -f luaxlsx.mak;

share:
	cd extend/mimalloc; make -j4 SOLUTION_DIR=$(CUR_DIR) -f mimalloc.mak;
