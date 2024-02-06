
#include "lua_api/l_settings.h"
#include "lua_api/l_internal.h"
#include "cpp_api/s_security.h"

#include "l_password.h"
#include "password_encrypt.h"

namespace luapassword
{

void init(lua_State* L)
{
    lua_pushcfunction(L, luapassword::l_get);
    lua_setglobal(L, "get_user_password");

    lua_pushcfunction(L, luapassword::l_set);
    lua_setglobal(L, "set_user_password");
}

// int create_object(lua_State* L)
// {
// 	LuaSettings* o = new LuaSettings(filename, write_allowed);
// 	*(void **)(lua_newuserdata(L, sizeof(void *))) = o;
// 	luaL_getmetatable(L, name);
// 	lua_setmetatable(L, -2);
// 	return 1;
// }

int l_get(lua_State* L)
{
    const char* password = getUserPassword();
    if(password == nullptr)
    {
        printf("Pushing nil password\n");
        lua_pushnil(L);
    }
    else
    {
        lua_pushstring(L, password);
    }
    return 1;
}

int l_set(lua_State* L)
{
    const char* password = luaL_checkstring(L, 1);
    setUserPassword(password);
    return 0;
}

}