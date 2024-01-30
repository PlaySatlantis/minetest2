--Minetest
--Copyright (C) 2014 sapier
--
--This program is free software; you can redistribute it and/or modify
--it under the terms of the GNU Lesser General Public License as published by
--the Free Software Foundation; either version 2.1 of the License, or
--(at your option) any later version.
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU Lesser General Public License for more details.
--
--You should have received a copy of the GNU Lesser General Public License along
--with this program; if not, write to the Free Software Foundation, Inc.,
--51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.


local function get_formspec(tabview, name, tabdata)
	-- Update the cached supported proto info,
	-- it may have changed after a change by the settings menu.
	common_update_cached_supp_proto()

	-- local logofile = defaulttexturedir .. "logo.png"
	local satlantis_logo_path = defaulttexturedir .. "logo_256x256.png"

	local message = "You are logged in as " .. core.settings:get("name")

	local retval =
		"container[0.0,0.4]" ..
		"image[2.0,-0.8;4.0,4.0;" .. core.formspec_escape(satlantis_logo_path) .. "]" ..
		"bgcolor[#000000C8]" ..
		"label[2.7,3.0;You are logged in as:]" ..
		"label[3.4,4.0;" .. core.settings:get("name") .. "]" ..
		"button[3.4,6.4;2.0,0.6;btn_mp_change_user;" .. "Change user" .. "]" ..
		"button[5.6,6.4;2.0,0.6;btn_mp_login;" .. fgettext("Start") .. "]" ..
		"container_end[]"

	return retval, "size[8,7.8,false]real_coordinates[true]"
end

local function set_selected_server(tabdata, idx, server)
	-- reset selection
	if idx == nil or server == nil then
		tabdata.selected = nil

		core.settings:set("address", "")
		core.settings:set("remote_port", "30000")
		return
	end

	local address = server.address
	local port    = server.port
	gamedata.serverdescription = server.description

	gamedata.fav = false
	for _, fav in ipairs(serverlistmgr.get_favorites()) do
		if address == fav.address and port == fav.port then
			gamedata.fav = true
			break
		end
	end

	if address and port then
		core.settings:set("address", address)
		core.settings:set("remote_port", port)
	end
	tabdata.selected = idx
end

local function main_button_handler(tabview, fields, name, tabdata)
	if fields.te_name then
		gamedata.playername = fields.te_name
		core.settings:set("name", fields.te_name)
	end

	if fields.btn_mp_change_user then
		core.settings:set("active_user_pass", "")
		tabdata:set_tab("custom_menu")
		return true
	end

	if (fields.btn_mp_login or fields.key_enter) then
		gamedata.playername = fields.te_name
		gamedata.password   = fields.te_pwd
		gamedata.address    = satlantis_server_address
		gamedata.port       = satlantis_server_port
		gamedata.playername = core.settings:get("name")
		gamedata.password   = core.settings:get("active_user_pass")

		local enable_split_login_register = core.settings:get_bool("enable_split_login_register")
		gamedata.allow_login_or_register = enable_split_login_register and "login" or "any"
		gamedata.selected_world = 0

		local idx = core.get_table_index("servers")
		local server = idx and tabdata.lookup[idx]

		set_selected_server(tabdata)

		if server and server.address == gamedata.address and
				server.port == gamedata.port then

			serverlistmgr.add_favorite(server)

			gamedata.servername        = server.name
			gamedata.serverdescription = server.description

			if not is_server_protocol_compat_or_error(
						server.proto_min, server.proto_max) then
				return true
			end
		else
			gamedata.servername        = ""
			gamedata.serverdescription = ""

			serverlistmgr.add_favorite({
				address = gamedata.address,
				port = gamedata.port,
			})
		end

		core.settings:set("address",     gamedata.address)
		core.settings:set("remote_port", gamedata.port)

		core.start()
		return true
	end

	return false
end

local function on_change(type, old_tab, new_tab)
	if type == "LEAVE" then return end
	-- if type == "ENTER" then
	-- 	mm_game_theme.set_engine(false)
	-- end
end

return {
	name = "logged_in",
	caption = fgettext("Logged in"),
	cbf_formspec = get_formspec,
	cbf_button_handler = main_button_handler,
	on_change = on_change,
	tabsize = { width=12, height= 12.0}
}
