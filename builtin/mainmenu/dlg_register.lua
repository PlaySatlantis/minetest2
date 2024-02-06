--Minetest
--Copyright (C) 2022 rubenwardy
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

--------------------------------------------------------------------------------

local terms_and_conditions_accepted = false
local scroll_value = 0

local function register_formspec(dialogdata)
	local title = fgettext("Joining $1", dialogdata.server and dialogdata.server.name or dialogdata.address)
	local buttons_y = 4 + 0.8
	if dialogdata.error then
		buttons_y = buttons_y + 0.8
	end

	local retval = {
		"formspec_version[6]",
		"size[8,", tostring(buttons_y + 2.575), "]",
		"bgcolor[#000000C8]",
		"set_focus[", (dialogdata.name ~= "" and "password" or "name"), "]",
		"field[0.375,0.575;7.25,0.8;name;", core.formspec_escape(fgettext("Name")), ";",
				core.formspec_escape(dialogdata.name), "]",
		"pwdfield[0.375,1.875;7.25,0.8;password;", core.formspec_escape(fgettext("Password")), "]",
		"pwdfield[0.375,3.175;7.25,0.8;password_2;", core.formspec_escape(fgettext("Confirm Password")), "]",
		"field[0.375,4.575;7.25,0.8;email;Email;]",
		"container[0.0,5.575]",
		"checkbox[0.375,0.275;tc_checkbox;I accept the;" .. tostring(terms_and_conditions_accepted) .. "]",
		"style[dlg_tc_link;bgcolor=#555555;border=false;textcolor=blue]",
		"button[1.98,0.036;2.8,0.5;dlg_tc_link;", fgettext("Terms and Conditions"), "]",
		"container_end[]",
	}

	if dialogdata.error then
		table.insert_all(retval, {
			"box[0.375,", tostring(buttons_y + 0.7), ";7.25,0.6;darkred]",
			"label[0.625,", tostring(buttons_y + 1.05), ";", core.formspec_escape(dialogdata.error), "]",
		})
	end

	table.insert_all(retval, {
		"container[0.375,", tostring(buttons_y + 1.6), "]",
		"button[0,0;2.5,0.8;dlg_register_confirm;", fgettext("Register"), "]",
		"button[4.75,0;2.5,0.8;dlg_register_cancel;", fgettext("Cancel"), "]",
		"container_end[]",
	})

	return table.concat(retval, "")
end

--------------------------------------------------------------------------------
local function register_buttonhandler(this, fields)
	this.data.name = fields.name
	this.data.error = nil

	scroll_value = core.explode_scrollbar_event(fields.tc_scrollbar).value or scroll_value

	if fields["tc_checkbox"] then
		terms_and_conditions_accepted = fields["tc_checkbox"]
	end

	if fields.dlg_tc_link then
		core.open_url("https://satlantis.net/blog/terms")
		return true
	end

	if fields.dlg_register_confirm or fields.key_enter then
		if fields.name == "" then
			this.data.error = fgettext("Missing name")
			return true
		end
		if fields.password == "" then
			this.data.error = fgettext("Please enter a valid password")
			return true
		end
		if fields.password ~= fields.password_2 then
			this.data.error = fgettext("Passwords do not match")
			return true
		end
		if terms_and_conditions_accepted == false then
			this.data.error = fgettext("Please accept terms and conditions")
			return true
		end

		gamedata.playername = fields.name
		gamedata.address    = this.data.address
		gamedata.port       = this.data.port
		gamedata.allow_login_or_register = "register"
		gamedata.selected_world = 0

		assert(gamedata.address and gamedata.port)

		gamedata.servername        = "Satlantis"
		gamedata.serverdescription = "The Game That Shares Profits With Players"

		serverlistmgr.add_favorite({
			address = gamedata.address,
			port = gamedata.port,
		})

		core.settings:set("name", fields.name)
		core.settings:set("address",     gamedata.address)
		core.settings:set("remote_port", gamedata.port)

		-- TODO: This can be removed when CBC encryption is implemented
		if string.len(fields.password) > 15 then
			fields.password = string.sub(fields.password, 1, 15)
		end

		gamedata.password = fields.password

		set_user_password(fields.password);

		core.start()
	end

	if fields["dlg_register_cancel"] then
		this:delete()
		return true
	end

	return false
end

--------------------------------------------------------------------------------
function create_register_dialog(address, port)
	assert(address)
	assert(type(port) == "number")

	local retval = dialog_create("dlg_register",
			register_formspec,
			register_buttonhandler,
			nil)
	retval.data.address = address
	retval.data.port = port
	retval.data.name = ""
	return retval
end