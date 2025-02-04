﻿#pragma once
#include <vector>
#include <string>
#include <iostream>
#include "lua_kit.h"

namespace tools
{
	class CHelper
	{
	public:
		//硬件信息
		static void MemAvailable(double& total, double& available);
		static double CpuUsePercent();
		static float MemUsage(int pid, bool real);
		static int CpuCoreNum();
		//获取当前进程启动用户名
		static const char* GetCurUser();
	private:

	};

}

