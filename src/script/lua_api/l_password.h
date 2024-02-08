#pragma once

#include "common/c_content.h"
#include "lua_api/l_base.h"

namespace luapassword
{
	void init(lua_State *L);

    int l_get(lua_State* L);
    int l_set(lua_State* L);
}