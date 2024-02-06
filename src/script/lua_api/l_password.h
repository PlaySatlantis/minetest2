#pragma once

#include "common/c_content.h"
#include "lua_api/l_base.h"

namespace luapassword
{
	void init(lua_State *L);

    // const char name[] = "PasswordManager";
    // const luaL_Reg methods[] = {
    //     // luamethod(LuaSettings, get),
    //     "get", l_getPassword,
    //     "set", l_setPassword,
    //     {0,0}
    // };

    int l_get(lua_State* L);
    int l_set(lua_State* L);
}