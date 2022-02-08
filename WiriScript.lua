--[[
--------------------------------
THIS FILE IS PART OF WIRISCRIPT
        Nowiry#2663
--------------------------------
]]

util.require_natives(1640181023)
require "wiriscript.functions"
require 'lua_imGUI V2-1'
json = require 'pretty.json'
ufo = require "wiriscript.ufo"
guided_missile = require "wiriscript.guided_missile"
UI = UI.new()

local version = 16
local scriptdir = filesystem.scripts_dir()
local wiridir = scriptdir .. '\\WiriScript\\'
local languagedir = wiridir .. 'language\\'
local config_file = wiridir .. 'config.ini'
local profiles_list = {}
local spoofname = true
local spoofrid = true
local spoofcrew = true
local usingprofile = false
local showing_intro = false
worldptr = memory.rip(memory.scan('48 8B 05 ? ? ? ? 45 ? ? ? ? 48 8B 48 08 48 85 C9 74 07') + 3)
if worldptr == 0 then 
	error('pattern scan failed: CPedFactory') 
end

-----------------------------------
-- FILE SYSTEM
-----------------------------------

if not filesystem.exists(wiridir) then
	filesystem.mkdir(wiridir)
end

if not filesystem.exists(languagedir) then
	filesystem.mkdir(languagedir)
end

if not filesystem.exists(wiridir .. '\\profiles') then
	filesystem.mkdir(wiridir .. '\\profiles')
end

if not filesystem.exists(wiridir .. '\\handling') then
	filesystem.mkdir(wiridir .. '\\handling') 
end

if filesystem.exists(wiridir .. '\\logo.png') then
	os.remove(wiridir .. '\\logo.png')
end

if filesystem.exists(wiridir .. '\\config.data') then
	os.remove(wiridir .. '\\config.data')
end

if filesystem.exists(scriptdir .. '\\savednames.data') then
	os.remove(scriptdir .. '\\savednames.data')
end

if filesystem.exists(filesystem.resources_dir() .. '\\wiriscript_logo.png') then
	os.remove(filesystem.resources_dir() .. '\\wiriscript_logo.png')
end

if filesystem.exists(wiridir .. '\\profiles.data') then
	os.remove(wiridir .. '\\profiles.data')
end

-----------------------------------
-- CONSTANTS
-----------------------------------

-- label =  'weapon ID'
local weapons = {												
	WT_PIST 		= "weapon_pistol",
	WT_STUN			= "weapon_stungun",
	WT_RAYPISTOL		= "weapon_raypistol",
	WT_RIFLE_SCBN 		= "weapon_specialcarbine",
	WT_SG_PMP		= "weapon_pumpshotgun",
	WT_MG			= "weapon_mg",
	WT_RIFLE_HVY 		= "weapon_heavysniper",
	WT_MINIGUN		= "weapon_minigun",
	WT_RPG			= "weapon_rpg",
	WT_RAILGUN 		= "weapon_railgun",
	WT_CMPGL 		= "weapon_compactlauncher",
	WT_EMPL 		= "weapon_emplauncher"
}


local melee_weapons = {
	WT_UNARMED 		= "weapon_unarmed",
	WT_KNIFE		= "weapon_knife",
	WT_MACHETE		= "weapon_machete",
	WT_BATTLEAXE		= "weapon_battleaxe",
	WT_WRENCH		= "weapon_wrench",
	WT_HAMMER		= "weapon_hammer",
	WT_BAT			= "weapon_bat"
}


-- here you can modify which peds are available to choose
-- ['name shown in Stand'] = 'ped model ID'
local peds = {
	['Prisoner'] 			= "s_m_y_prismuscl_01",
	['Mime'] 			= "s_m_y_mime",
	['Astronaut'] 			= "s_m_m_movspace_01",
	['SWAT'] 			= "s_m_y_swat_01",
	['Ballas Ganster'] 		= "csb_ballasog",
	['Marine'] 			= "csb_ramp_marine",
	['Female Police Officer'] 	= "s_f_y_cop_01",
	['Male Police Officer'] 	= "s_m_y_cop_01",
	['Jesus'] 			= "u_m_m_jesus_01",
	['Zombie'] 			= "u_m_y_zombie_01",
	['Juggernaut'] 			= "u_m_y_juggernaut_01",
	['Clown'] 			= "s_m_y_clown_01",
	['Hooker'] 			= "s_f_y_hooker_01",
	['Altruist'] 			= "a_m_y_acult_01"
}

-- these are the buzzard's gunner weapons
local gunner_weapon_list = {
	WT_MG 	= "weapon_mg",
	WT_RPG 	= "weapon_rpg"
}

-- used to change minitank's weapon
local modIndex =
{
	WT_V_PLRBUL 	= - 1,
	MINITANK_WEAP2 	=   1,
	MINITANK_WEAP3 	=   2
}

-- [name] = {"keyboard; controller", index}
local imputs = {
	INPUT_JUMP			= {'Spacebar; X', 22},
	INPUT_VEH_ATTACK		= {'Mouse L; RB', 69},
	INPUT_VEH_AIM			= {'Mouse R; LB', 68},
	INPUT_VEH_DUCK			= {'X; A', 73},
	INPUT_VEH_HORN			= {'E; L3', 86},
	INPUT_VEH_CINEMATIC_UP_ONLY 	= {'Numpad +; none', 96},
	INPUT_VEH_CINEMATIC_DOWN_ONLY 	= {'Numpad -; none', 97}
}


local veh_weapons = {
	{"weapon_vehicle_rocket"	, "WT_V_SPACERKT"	, PAD.IS_CONTROL_JUST_PRESSED},
	{"weapon_raypistol"		, "WT_RAYPISTOL"	, PAD.IS_CONTROL_PRESSED},
	{"weapon_firework"		, "WT_FWRKLNCHR"	, PAD.IS_CONTROL_JUST_PRESSED},
	{"vehicle_weapon_tank"		, "WT_V_TANK"		, PAD.IS_CONTROL_JUST_PRESSED},
	{"vehicle_weapon_player_lazer"	, "WT_V_PLRBUL"		, PAD.IS_CONTROL_PRESSED}
}


local formations = {
	{'Freedom to Move', 0},
	{'Circle Around Leader', 1},
	{'Line', 3},
	{'Arrow Formation', 4},
}


local proofs = {
	bullet 		= false,
	fire 		= false,
	explosion 	= false,
	collision 	= false,
	melee 		= false,
	steam 		= false,
	drown 		= false
}


NULL = 0
NOTIFICATION_RED = 6
NOTIFICATION_BLACK = 2

---------------------------------
-- CONFIG
---------------------------------

if filesystem.exists(config_file) then
	local loaded = ini.load(config_file)
	for s, t in pairs(loaded) do
		for k, v in pairs(t) do
			if config[ s ] and config[ s ][ k ] ~= nil then
				config[ s ][ k ] = v
			end
		end
	end
end


if config.general.language ~= 'english' then
	local file = languagedir .. '\\' .. config.general.language .. '.json'
	if not filesystem.exists(file) then
		notification.normal('Translation file not found', NOTIFICATION_RED)
	else
		file = io.open(file, 'r')
		local content = file:read('a')
        	file:close()
		if string.len(content) > 0 then 
			local loaded = json.parse(content, false)
			menunames = loaded
        	end
	end
end

-----------------------------------
-- HTTP
-----------------------------------

async_http.init('pastebin.com', '/raw/EhH1C6Dh', function(output)
	local cversion = tonumber(output)
	if cversion then 
		if cversion > version then	
    	    		notification.normal('WiriScript v' .. output .. ' is available', NOTIFICATION_RED)
			menu.hyperlink(menu.my_root(), 'Get WiriScript v' .. output, 'https://cutt.ly/get-wiriscript', '')
    		end
	end
end, function()
	util.log('[WiriScript] Failed to check for updates.')
end)
async_http.dispatch()


async_http.init('pastebin.com', '/raw/WMUmGzNj', function(output)
	if string.match(output, '^#') ~= nil then
		local msg = string.match(output, '^#(.+)')
        	notification.help('~b~' .. '~italic~' .. 'Nowiry: ' .. '~s~' .. msg)
	end
end, function()
    util.log('[WiriScript] Failed to get message.')
end)
async_http.dispatch()

-------------------------------------
-- INTRO
-------------------------------------

local function ADD_TEXT_TO_SINGLE_LINE(scaleform, text, font, colour)
	GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "ADD_TEXT_TO_SINGLE_LINE")
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_TEXTURE_NAME_STRING("presents")
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_TEXTURE_NAME_STRING(text)
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_TEXTURE_NAME_STRING(font)
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_TEXTURE_NAME_STRING(colour)
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_BOOL(true)
	GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
end


local function HIDE(scaleform)
	GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "HIDE")
	GRAPHICS.BEGIN_TEXT_COMMAND_SCALEFORM_STRING("STRING")
	HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME("presents")
	GRAPHICS.END_TEXT_COMMAND_SCALEFORM_STRING()
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(0.16)
	GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
end


local function SETUP_SINGLE_LINE(scaleform)
	GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SETUP_SINGLE_LINE")
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_TEXTURE_NAME_STRING("presents")
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(0.5)
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(0.5)
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(70.0)
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(125.0)
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_TEXTURE_NAME_STRING('left')
	GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
end


if SCRIPT_MANUAL_START then
	showing_intro = true
	local state = 0
	local stime = cTime()
	AUDIO.PLAY_SOUND_FROM_ENTITY(-1, "clown_die_wrapper", PLAYER.PLAYER_PED_ID(), "BARRY_02_SOUNDSET", true, 20)
	
	create_tick_handler(function()	
		local scaleform = GRAPHICS.REQUEST_SCALEFORM_MOVIE("OPENING_CREDITS")	
		while not GRAPHICS.HAS_SCALEFORM_MOVIE_LOADED(scaleform) do
			wait()
		end

		if state == 0 then
			SETUP_SINGLE_LINE(scaleform)
			ADD_TEXT_TO_SINGLE_LINE(scaleform, 'a', '$font5', "HUD_COLOUR_WHITE")
			ADD_TEXT_TO_SINGLE_LINE(scaleform, 'nowiry', '$font2', "HUD_COLOUR_BLUE")
			ADD_TEXT_TO_SINGLE_LINE(scaleform, 'production', '$font5', "HUD_COLOUR_WHITE")

			GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SHOW_SINGLE_LINE")
			GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_TEXTURE_NAME_STRING("presents")
			GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

			GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SHOW_CREDIT_BLOCK")
			GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_TEXTURE_NAME_STRING("presents")
			GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(0.5)
			GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

			AUDIO.PLAY_SOUND_FROM_ENTITY(-1, "Pre_Screen_Stinger", PLAYER.PLAYER_PED_ID(), "DLC_HEISTS_FINALE_SCREEN_SOUNDS", true, 20)
			state = 1
			stime = cTime()
		end

		if cTime() - stime >= 4000 and state == 1 then
			HIDE(scaleform)
			state = 2
			stime = cTime()
		end

		if cTime() - stime >= 3000 and state == 2 then
			SETUP_SINGLE_LINE(scaleform)
			ADD_TEXT_TO_SINGLE_LINE(scaleform, 'wiriscript', '$font2', "HUD_COLOUR_BLUE")
			ADD_TEXT_TO_SINGLE_LINE(scaleform, 'v' .. version, '$font5', "HUD_COLOUR_WHITE")
			
			GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SHOW_SINGLE_LINE")
			GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_TEXTURE_NAME_STRING("presents")
			GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

			GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SHOW_CREDIT_BLOCK")
			GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_TEXTURE_NAME_STRING("presents")
			GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(0.5)
			GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

			AUDIO.PLAY_SOUND_FROM_ENTITY(-1, "SPAWN", PLAYER.PLAYER_PED_ID(), "BARRY_01_SOUNDSET", true, 20)
			state = 3
			stime = cTime()
		end

		if cTime() - stime >= 4000 and state == 3 then
			HIDE(scaleform)
			state = 4
			stime = cTime()
		end
		if cTime() - stime >= 3000 and state == 4 then
			showing_intro = false
			return false
		end
		GRAPHICS.DRAW_SCALEFORM_MOVIE_FULLSCREEN(scaleform, 255, 255, 255, 255, 0)
		return true
	end)
end
	
---------------------
---------------------
-- SETTINGS
---------------------
---------------------

local settings = menu.list(menu.my_root(), 'Settings', {'settings'}, '')

menu.divider(settings, 'Settings')


menu.action(settings, menuname('Settings', 'Save Settings'), {}, '', function()
	ini.save(config_file, config)
	notification.normal('Configuration saved')
end)

-------------------------------------
-- LANGUAGE
-------------------------------------

local language_settings = menu.list(settings, 'Language')

menu.divider(language_settings, 'Language')


menu.action(language_settings, 'Create New Translation', {}, 'Creates a file you can use to make a new WiriScript translation', function()
	local file = wiridir .. '\\new translation.json'
	local content = json.stringify(features, nil, 4)
	file = io.open(file,'w')
	file:write(content)
	file:close()
	notification.normal('File: new translation.json was created')
end)

if config.general.language ~= 'english' then
	menu.action(language_settings, 'Update Translation', {}, 'Creates an updated translation file that has all the missing features', function()
		local t = swap_values(features, menunames)
		local file = wiridir .. config.general.language .. ' (update).json'
		local content = json.stringify(t, nil, 4)
		file = io.open(file, 'w')
		file:write(content)
		file:close()
		notification.normal('File: ' .. config.general.language .. ' (update).json, was created')
	end)
end

menu.divider(language_settings, '°°°')


if config.general.language ~= 'english' then
	local actionId
	actionId = menu.action(language_settings, 'English', {}, '', function()
		config.general.language = 'english'
		ini.save(config_file, config)
		menu.show_warning(actionId, CLICK_MENU, 'Would you like to restart the script now to apply the language setting?', function()
			util.stop_script()
		end)
	end)
end

for _, path in ipairs(filesystem.list_files(languagedir)) do
	local filename, ext = string.match(path, '^.+\\(.+)%.(.+)$')
	if ext == 'json' and config.general.language ~= filename then
		local actionId
		actionId = menu.action(language_settings, first_upper(filename), {}, '', function()
			config.general.language = filename
			ini.save(config_file, config)
            menu.show_warning(actionId, CLICK_MENU, 'Would you like to restart the script now to apply the language setting?', function()
                util.stop_script()	
            end)
		end)
	end
end

-------------------------------------

menu.toggle(settings, menuname('Settings', 'Display Health Text'), {'displayhealth'}, 'If health is going to be displayed while using Mod Health', function(toggle)
	config.general.displayhealth = toggle
end, config.general.displayhealth)


local healthtxt = menu.list(settings, menuname('Settings', 'Health Text Position'), {}, '')
local _x, _y =  directx.get_client_size()

menu.slider(healthtxt, 'X', {'healthx'}, '', 0, _x, round(_x * config.healthtxtpos.x) , 1, function(x)
	config.healthtxtpos.x = round(x /_x, 4)
end)

menu.slider(healthtxt, 'Y', {'healthy'}, '', 0, _y, round(_y * config.healthtxtpos.y), 1, function(y)
	config.healthtxtpos.y = round(y /_y, 4)
end)


menu.toggle(settings, menuname('Settings', 'Stand Notifications'), {'standnotifications'}, 'Turns to Stand\'s notification appearance', function(toggle)
	config.general.standnotifications = toggle
end, config.general.standnotifications)


-------------------------------------
-- CONTROLS
-------------------------------------

local control_settings = menu.list(settings, menuname('Settings', 'Controls') , {}, '')

menu.divider(control_settings, menuname('Settings', 'Controls'))


local airstrike_plane_control = menu.list(control_settings, menuname('Settings - Controls', 'Airstrike Aircraft'), {}, '')

for name, control in pairs(imputs) do
	local keyboard, controller = control[1]:match('^(.+)%s?;%s?(.+)$')
	local strg = "Keyboard: ".. keyboard .. ", Controller: " .. controller
	menu.action(airstrike_plane_control, strg, {}, "", function()
		config.controls.airstrikeaircraft = control[2]
		util.show_corner_help('Press ' .. ('~%s~ '):format(name) .. ' to use Airstrike Aircraft')
	end)
end

local vehicle_weapons_control = menu.list(control_settings, menuname('Settings - Controls', 'Vehicle Weapons'), {}, '')

for name, control in pairs(imputs) do
	local keyboard, controller = control[1]:match('^(.+)%s?;%s?(.+)$')
	local strg = "Keyboard: ".. keyboard .. ", Controller: " .. controller
	menu.action(vehicle_weapons_control, strg, {}, "", function()
		config.controls.vehicleweapons = control[2]
		util.show_corner_help('Press ' .. ('~%s~ '):format(name) .. ' to use Vehicle Weapons')
	end)
end

menu.toggle(settings, menuname('Settings', 'Disable Lock-On Sprites'), {}, 'Disables the boxes that UFO draws on players. ', function(toggle)
	config.general.disablelockon = toggle
end, config.general.disablelockon)


menu.toggle(settings, menuname('Settings', 'Disable Vehicle Gun Preview'), {}, '', function(toggle)
	config.general.disablepreview = toggle
end, config.general.disablepreview)


-------------------------------------
-- HANDLING EDITOR CONFIG
-------------------------------------

local handling_editor_settings = menu.list(settings, menuname('Settings', 'Handling Editor'), {}, '')

menu.divider(handling_editor_settings, menuname('Settings', 'Handling Editor'))


local onfocuscolour = Colour.Normalize(config.onfocuscolour)

menu.colour(handling_editor_settings, menuname('Settings - Handling Editor', 'Focused Text Colour'), {'onfocuscolour'}, '', onfocuscolour, false, function(new)
	onfocuscolour = new
	config.onfocuscolour = Colour.Integer(new)
end)


local highlightcolour = Colour.Normalize(config.highlightcolour)

menu.colour(handling_editor_settings, menuname('Settings - Handling Editor', 'Highlight Colour'), {'highlightcolour'}, '', highlightcolour, false, function(new)
	highlightcolour = new
	config.highlightcolour = Colour.Integer(new)
end)


local buttonscolour = Colour.Normalize(config.buttonscolour)

menu.colour(handling_editor_settings, menuname('Settings - Handling Editor', 'Buttons Colour'), {'buttonscolour'}, '', buttonscolour, false, function(new)
	buttonscolour = new
	config.buttonscolour = Colour.Integer(new)
end)

-------------------------------------

menu.toggle(settings, menuname('Settings', 'Busted Features'), {}, 'Allows you to use some previously removed features. Requires to save save settings and restart.', function(toggle)
	config.general.bustedfeatures = toggle
	if config.general.bustedfeatures then
		notification.help('Please save settings and restart the script')
	end
end, config.general.bustedfeatures)

-------------------------------------
-- SPOOFING PROFILE
-------------------------------------

local profiles_root = menu.list(menu.my_root(), menuname('Spoofing Profile', 'Spoofing Profile'), {'profiles'}, '')

function add_profile(profile, name)
	local name = name or profile.name
	local rid = profile.rid
	local profile_actions = menu.list(profiles_root, name, {'profile' .. name}, '')

	menu.divider(profile_actions, name)

	menu.action(profile_actions, menuname('Spoofing Profile - Profile', 'Enable Spoofing Profile'), {'enable' .. name}, '', function()
		usingprofile = true 
		if spoofname then
			menu.trigger_commands('spoofedname ' .. profile.name)
			menu.trigger_commands('spoofname on')
		end
		if spoofrid then
			menu.trigger_commands('spoofedrid ' .. rid)
			menu.trigger_commands('spoofrid hard')
		end
		if spoofcrew and profile.crew and not equals(profile.crew, {}) then
			menu.trigger_commands(
				'crewid ' 		.. profile.crew.icon 	.. ';' ..
				'crewtag ' 		.. profile.crew.tag 	.. ';' ..
				'crewname ' 	.. profile.crew.name 	.. ';' ..
				'crewmotto ' 	.. profile.crew.motto 	.. ';' ..
				'crewaltbadge '	.. string.lower( profile.crew.alt_badge ) .. '; crew on'
			)
		end
	end)

	menu.action(profile_actions, menuname('Spoofing Profile - Profile', 'Delete'), {}, '', function()
		os.remove(wiridir .. '\\profiles\\' .. name .. '.json')
		local restore_profile
		restore_profile = menu.action(recycle_bin, name, {}, 'Click to restore', function()
			save_profile(profile)
			menu.delete(restore_profile)
		end)
		profiles_list[ key_of(profiles_list, profile) ] = nil
		menu.delete(profile_actions)
		notification.normal('Profile moved to recycle bin')
	end)
	
	menu.divider(profile_actions, menuname('Spoofing Profile - Profile', 'Spoofing Options') )
	
	menu.toggle(profile_actions, menuname('Spoofing Profile - Profile', 'Name'), {}, '', function(toggle)
		spoofname = toggle
	end, true)

	menu.toggle(profile_actions, menuname('Spoofing Profile - Profile', 'SCID') .. ' ' .. rid, {}, '', function(toggle)
		spoofrid = toggle
	end, true)

	if profile.crew and not equals(profile.crew, {}) then
		menu.toggle(profile_actions, menuname('Spoofing Profile - Profile', 'Crew Spoofing'), {}, '', function(toggle)
			spoofcrew = toggle
		end, true)
		local crewinfo = menu.list(profile_actions, menuname('Spoofing Profile - Profile', 'Crew'))
		for k, value in pairs_by_keys(profile.crew) do
			local name = k:gsub('_', " ")
			name = cap_each_word(name)
			menu.action(crewinfo, name .. ': ' .. value, {}, 'Click to copy to clipboard.', function()
				util.copy_to_clipboard(v)
			end)
		end
	end
end


function save_profile(profile)
	local key = profile.name 
	if includes(profiles_list, profile) then
		notification.normal('This spoofing profile already exists', NOTIFICATION_RED)
		return
	elseif profiles_list[ profile.name ] ~= nil then
		local n = 0
		for k in pairs(profiles_list) do
			if k:match(profile.name) then
				n = n + 1
			end
		end
		key = profile.name .. ' (' .. (n + 1) .. ')' 
	end
	profiles_list[ key ] =  profile
	local file = io.open(wiridir .. '\\profiles\\' .. key .. '.json', 'w')
	local content = json.stringify(profile, nil, 4)
	file:write(content)
	file:close()
	add_profile(profile, key)
	notification.normal('Spoofing profile created')
end

menu.action(profiles_root, menuname('Spoofing Profile', 'Disable Spoofing Profile'), {'disableprofile'}, '', function()
	if usingprofile then 
		menu.trigger_commands('spoofname off; spoofrid off; crew off')
		usingprofile = false
	else
		notification.normal('You are not using any spoofing profile', NOTIFICATION_RED)
	end
end)

-------------------------------------
-- ADD SPOOFING PROFILE
-------------------------------------

local newname
local newrid
local newprofile = menu.list(profiles_root, menuname('Spoofing Profile', 'Add Profile'), {'addprofile'}, 'Manually creates a new spoofing profile.')

menu.divider(newprofile, menuname('Spoofing Profile', 'Add Profile') )


menu.text_input(newprofile, menuname('Spoofing Profile - Add Profile', 'Name'), {'profilename'}, 'Type the profile\'s name.', function(name)
	newname = name
end)

menu.text_input(newprofile, menuname('Spoofing Profile - Add Profile', 'SCID'), {'profilerid'}, 'Type the profile\'s SCID.', function(rid)
	newrid = rid
end)

menu.action(newprofile, menuname('Spoofing Profile - Add Profile', 'Save Spoofing Profile'), {'saveprofile'}, '', function()
	if newname == nil or newrid == nil then
		notification.normal('Name and SCID are required', NOTIFICATION_RED)
		return
	end
	local profile = {['name'] = newname, ['rid'] = newrid}
	save_profile(profile)
end)


recycle_bin = menu.list(profiles_root, menuname('Spoofing Profile', 'Recycle Bin'), {}, 'Temporary stores the deleted profiles. Profiles are permanetly erased when the script stops.')

menu.divider(profiles_root, menuname('Spoofing Profile', 'Spoofing Profile') )


for _, path in ipairs(filesystem.list_files(wiridir .. '\\profiles')) do
	local filename, ext = string.match(path, '^.+\\(.+)%.(.+)$')
	if ext == 'json' then
		local file = io.open(path, 'r')
		local content = file:read('a')
		file:close()
		if string.len(content) > 0 then
			local profile = json.parse(content, false)
			if profile.name and profile.rid then
				profile.rid = tonumber(profile.rid)
				profiles_list[ filename ] = profile
				add_profile(profile, filename)
			end
		end
	else os.remove(path) end
end


generate_features = function(pid)
	menu.divider(menu.player_root(pid),'WiriScript')		
	
	developer(menu.action, menu.player_root(pid), 'CPed', {}, '', function()
		local addr = entities.handle_to_pointer(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
		local hex = string.format("%x", addr)
		util.copy_to_clipboard(string.upper( hex ))
	end)

	-------------------------------------
	-- CREATE SPOOFING PROFILE
	-------------------------------------

	menu.action(menu.player_root(pid), menuname('Player', 'Create Spoofing Profile'), {}, '', function()
		local profile = {name = PLAYER.GET_PLAYER_NAME(pid), rid = players.get_rockstar_id(pid), crew = get_player_clan(pid)}
		save_profile(profile)
	end)

	---------------------
	---------------------
	-- TROLLING 
	---------------------
	---------------------

	local trolling_list = menu.list(menu.player_root(pid), menuname('Player', 'Trolling & Griefing'), {}, '')	

	-------------------------------------
	-- EXPLOSIONS
	-------------------------------------
	
	local explo_settings = menu.list(trolling_list, menuname('Trolling', 'Custom Explosion'), {}, '')
	local explosions = {
		audible = true,
		speed = 300,
		owned = false,
		type = 0,
		invisible = false
	}
	function explosions:explode_player(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
		pos.z = pos.z - 1.0
		if not self.owned then
			FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, self.type, 1.0, self.audible, self.invisible, 0, false)
		else
			FIRE.ADD_OWNED_EXPLOSION(PLAYER.PLAYER_PED_ID(), pos.x, pos.y, pos.z, self.type, 1.0, self.audible, self.invisible, 0, true)
		end
	end
	
	menu.divider(explo_settings, menuname('Trolling', 'Custom Explosion'))

	menu.slider(explo_settings, menuname('Trolling - Custom Explosion', 'Explosion Type'), {'explosion'},'', 0, 72, 0, 1, function(value)
		explosions.type = value
	end)
	
	menu.toggle(explo_settings, menuname('Trolling - Custom Explosion', 'Invisible'), {}, '', function(toggle)
		explosions.invisible = toggle
	end)

	menu. toggle(explo_settings, menuname('Trolling - Custom Explosion', 'Audible'), {}, '', function(toggle)
		explosions.audible = toggle
	end, true)
	
	menu.toggle(explo_settings, menuname('Trolling - Custom Explosion', 'Owned Explosions'), {}, '', function(toggle)
		explosions.owned = toggle
	end)
	
	menu.action(explo_settings, menuname('Trolling - Custom Explosion', 'Explode'), {'customexplode'}, '', function()
		explosions:explode_player(pid)
	end)

	menu.slider(explo_settings, menuname('Trolling - Custom Explosion', 'Loop Speed'), {'speed'}, '', 50, 1000, 300, 10, function(value) --changes the speed of loop
		explosions.speed = value
	end)
	
	menu.toggle_loop(explo_settings, menuname('Trolling - Custom Explosion', 'Explosion Loop'), {'customloop'}, '', function()
		explosions:explode_player(pid)
		wait(explosions.speed)
	end)

	menu.toggle_loop(trolling_list, menuname('Trolling', 'Water Loop'), {'waterloop'}, '', function()
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
		pos.z = pos.z - 1.0
		FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, 13, 1.0, true, false, 0, false)
	end)

	menu.toggle_loop(trolling_list, menuname('Trolling', 'Flame Loop'), {'flameloop'}, '', function()
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
		pos.z = pos.z - 1.0
		FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, 12, 1.0, true, false, 0, false)
	end)

	-------------------------------------
	-- KILL AS THE ORBITAL CANNON
	-------------------------------------

	menu.action(trolling_list, menuname('Trolling', 'Kill as Orbital Cannon'), {'orbital'}, '', function()
		local countdown = 3
		if players.is_in_interior(pid) then
			return notification.normal('The player is in interior', NOTIFICATION_RED)
		end
		local cam = CAM.CREATE_CAM("DEFAULT_SCRIPTED_CAMERA", false)
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
		local height = pos.z + 200
		menu.trigger_commands('becomeorbitalcannon on')
		CAM.DO_SCREEN_FADE_OUT(500)
		wait(1000)
		CAM.SET_CAM_ROT(cam, -90, 0.0, 0.0, 2)
		CAM.SET_CAM_FOV(cam, 80)
		CAM.SET_CAM_COORD(cam, pos.x, pos.y, height)
		CAM.SET_CAM_ACTIVE(cam, true)
		STREAMING.LOAD_SCENE(pos.x, pos.y, pos.z)
		CAM.RENDER_SCRIPT_CAMS(true, false, 3000, true, false, 0)
		STREAMING.SET_FOCUS_POS_AND_VEL(pos.x, pos.y, pos.z, 5.0, 0.0, 0.0)
		GRAPHICS.SET_SCRIPT_GFX_DRAW_ORDER(1)
		GRAPHICS.SET_DRAW_ORIGIN(pos.x, pos.y, pos.z, 0)
		GRAPHICS.ANIMPOSTFX_PLAY("MP_OrbitalCannon", 0, true)
		wait(1000)
		CAM.DO_SCREEN_FADE_IN(0)

		local scaleform = GRAPHICS.REQUEST_SCALEFORM_MOVIE("ORBITAL_CANNON_CAM")
		while not GRAPHICS.HAS_SCALEFORM_MOVIE_LOADED(scaleform) do
			wait()
		end
		
		local startTime = os.time()
		while true do
			wait()
			local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
			DRAW_LOCKON_SPRITE_ON_PLAYER(pid)

			CAM.SET_CAM_COORD(cam, pos.x, pos.y, height)
			HUD.DISPLAY_RADAR(false)

			GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SET_STATE")
			GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(3)
			GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

			GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SET_ZOOM_LEVEL")
			GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(1.0)
			GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

			GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SET_CHARGING_LEVEL")
			GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(1.0)
			GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
			
			if countdown > 0 then
				if os.difftime(os.time(), startTime) == 1 then
					countdown = countdown - 1
					startTime = os.time()
				end
				GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SET_COUNTDOWN")
				GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(countdown)
				GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
			else
				GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SET_CHARGING_LEVEL")
				GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(0.0)
				GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

				local effect = {asset = "scr_xm_orbital", name = "scr_xm_orbital_blast"}
		
				STREAMING.REQUEST_NAMED_PTFX_ASSET(effect.asset)
				while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(effect.asset) do
					wait()
				end

				FIRE.ADD_OWNED_EXPLOSION(PLAYER.PLAYER_PED_ID(), pos.x, pos.y, pos.z, 59, 1.0, true, false, 1.0)
				GRAPHICS.USE_PARTICLE_FX_ASSET(effect.asset)
				GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD(
					effect.name, 
					pos.x,
					pos.y,
					pos.z, 
					0.0, 
					0.0, 
					0.0,
					1.0, 
					false, false, false, true
				)
				AUDIO.PLAY_SOUND_FROM_COORD(-1, "DLC_XM_Explosions_Orbital_Cannon", pos.x, pos.y, pos.z, 0, true, 0, false)
				CAM.SHAKE_CAM(cam, "GAMEPLAY_EXPLOSION_SHAKE", 1.5)
				break
			end
			GRAPHICS.SET_SCRIPT_GFX_DRAW_ORDER(0)
			GRAPHICS.DRAW_SCALEFORM_MOVIE_FULLSCREEN(scaleform, 255, 255, 255, 255, 0)
			GRAPHICS.RESET_SCRIPT_GFX_ALIGN()
		end
		CAM.DO_SCREEN_FADE_OUT(500)
		wait(600)
		GRAPHICS.ANIMPOSTFX_STOP("MP_OrbitalCannon")
		CAM.RENDER_SCRIPT_CAMS(false, false, 3000, true, false, 0)
		CAM.SET_CAM_ACTIVE(cam, false)
		CAM.DESTROY_CAM(cam, false)
		HUD.DISPLAY_RADAR(true)
		STREAMING.CLEAR_FOCUS()
		GRAPHICS.CLEAR_DRAW_ORIGIN()
		wait(600)
		CAM.DO_SCREEN_FADE_IN(0)
		menu.trigger_commands('becomeorbitalcannon off')
	end)

	-------------------------------------
	-- SHAKE CAMERA
	-------------------------------------

	menu.toggle_loop(trolling_list, menuname('Trolling', 'Shake Camera'), {'shake'}, '', function()
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
		FIRE.ADD_OWNED_EXPLOSION(PLAYER.PLAYER_PED_ID(), pos.x, pos.y, pos.z, 0, 0, false, true, 80)
		wait(150)
	end)

	-------------------------------------
	-- ATTACKER OPTIONS
	-------------------------------------

	local attacker = {
		spawned 	= {},
		stationary 	= false,
		godmode 	= false
	}
	local attacker_options = menu.list(trolling_list, menuname('Trolling', 'Attacker Options'), {}, '')
	
	menu.divider(attacker_options, menuname('Trolling', 'Attacker Options'))

	menu.click_slider(attacker_options, menuname('Trolling - Attacker Options', 'Spawn Attacker'), {'attacker'}, '', 1, 15, 1, 1, function(quantity)
		local weapon = attacker.weapon or random(weapons)
		local model = attacker.model or random(peds)
		local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local modelHash = joaat(model)
		local weaponHash = joaat(weapon)
		
		for i = 1, quantity do
			local pos = ENTITY.GET_ENTITY_COORDS(player_ped)
			pos.x = pos.x + math.random(-3,3)
			pos.y = pos.y + math.random(-3,3)
			pos.z = pos.z - 1.0
			
			REQUEST_MODELS(modelHash)
			local ped = entities.create_ped(0, modelHash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
			insert_once(attacker.spawned, model)
			NETWORK.SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER(NETWORK.PED_TO_NET(ped), PLAYER.PLAYER_ID(), true)
			NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(NETWORK.PED_TO_NET(ped), true)
			SET_ENT_FACE_ENT(ped, player_ped)
			WEAPON.GIVE_WEAPON_TO_PED(ped, weaponHash, -1, true, true)
			WEAPON.SET_CURRENT_PED_WEAPON(ped, weaponHash, false)
			ENTITY.SET_ENTITY_INVINCIBLE(ped, attacker.godmode)
			PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
			TASK.TASK_COMBAT_PED(ped, player_ped, 0, 16)
			PED.SET_PED_AS_ENEMY(ped, true)
			
			if attacker.stationary then 
				PED.SET_PED_COMBAT_MOVEMENT(ped, 0) 
			end
			
			PED.SET_PED_COMBAT_ATTRIBUTES(ped, 46, 1)
			PED.SET_PED_CONFIG_FLAG(ped, 208, true)
			relationship:hostile(ped)
			STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(modelHash)

			wait(100)
		end
	end)

	local ped_list = menu.list(attacker_options, menuname('Trolling - Attacker Options', 'Set Model') .. ': ' .. HUD._GET_LABEL_TEXT("SR_GUN_RANDOM"), {}, '')

	menu.divider(ped_list, menuname('Trolling - Attacker Options', 'Attacker Model List'))
	
	menu.action(ped_list, HUD._GET_LABEL_TEXT("SR_GUN_RANDOM"), {}, '', function()
		attacker.model = nil
		menu.set_menu_name(ped_list, menuname('Trolling - Attacker Options', 'Set Model') .. ': ' .. HUD._GET_LABEL_TEXT("SR_GUN_RANDOM"))
		menu.focus(ped_list)
	end)

	-- creates the attacker appearance list
	for k, model in pairs_by_keys(peds) do 
		menu.action(ped_list, menuname('Ped Models', k), {}, '', function()
			attacker.model = model
			menu.set_menu_name(ped_list, menuname('Trolling - Attacker Options', 'Set Model')..': '..k)
			menu.focus(ped_list)
		end)
	end

	menu.click_slider(attacker_options, menuname('Trolling - Attacker Options', 'Clone Player (Enemy)'), {'enemyclone'}, '', 1, 15, 1, 1, function(quantity)
		local weapon = attacker.weapon or random(weapons)
		local weapon_hash = joaat(weapon)
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
		for i = 1, quantity do
			pos.x = pos.x + math.random(-3,3)
			pos.y = pos.y + math.random(-3,3)
			pos.z = pos.z - 1.0
			local clone = PED.CLONE_PED(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid), 1, 1, 1)
			insert_once(attacker.spawned, "mp_f_freemode_01"); insert_once(attacker.spawned, "mp_m_freemode_01")
			WEAPON.GIVE_WEAPON_TO_PED(clone, weapon_hash, -1, true, true)
			WEAPON.SET_CURRENT_PED_WEAPON(clone, weapon_hash, false)
			ENTITY.SET_ENTITY_COORDS(clone, pos.x, pos.y, pos.z)
			ENTITY.SET_ENTITY_INVINCIBLE(clone, attacker.godmode)
			PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(clone, true)
			TASK.TASK_COMBAT_PED(clone, PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid), 0, 16)
			PED.SET_PED_COMBAT_ATTRIBUTES(clone, 46, 1)
			PED.SET_PED_CONFIG_FLAG(clone, 208, true)
			relationship:hostile(clone)

			if attacker.stationary then	
				PED.SET_PED_COMBAT_MOVEMENT(clone, 0) 
			end
			wait(100)
		end
	end)


	local ped_weapon_list = menu.list(attacker_options, menuname('Trolling - Attacker Options', 'Set Weapon') .. ': ' .. HUD._GET_LABEL_TEXT("SR_GUN_RANDOM"), {}, '')	
	menu.divider(ped_weapon_list, HUD._GET_LABEL_TEXT("PM_WEAPONS"))
	
	local ped_melee_list = menu.list(ped_weapon_list, HUD._GET_LABEL_TEXT("VAULT_WMENUI_8"), {}, '')
	menu.divider(ped_melee_list, HUD._GET_LABEL_TEXT("VAULT_WMENUI_8"))
	
	-- creates the attacker melee weapon list
	for label, weapon in pairs_by_keys(melee_weapons) do
		local strg = HUD._GET_LABEL_TEXT(label)
		menu.action(ped_melee_list,  strg, {}, '', function()
			attacker.weapon = weapon
			menu.set_menu_name(ped_weapon_list, menuname('Trolling - Attacker Options', 'Set Weapon') .. ': ' .. strg, {}, '')	
			menu.focus(ped_weapon_list)
		end)
	end

	menu.action(ped_weapon_list, HUD._GET_LABEL_TEXT("SR_GUN_RANDOM"), {}, '', function()
		attacker.weapon = nil
		menu.set_menu_name(ped_weapon_list, menuname('Trolling - Attacker Options', 'Set Weapon') .. ': ' .. HUD._GET_LABEL_TEXT("SR_GUN_RANDOM"), {}, '')	
		menu.focus(ped_weapon_list)
	end)

	-- creates the attacker weapon list
	for label, weapon in pairs_by_keys(weapons) do
		local strg = HUD._GET_LABEL_TEXT(label)
		menu.action(ped_weapon_list, strg, {}, '', function()
			attacker.weapon = weapon
			menu.set_menu_name(ped_weapon_list, menuname('Trolling - Attacker Options', 'Set Weapon') .. ': ' .. strg)
			menu.focus(ped_weapon_list)
		end)
	end


	menu.toggle(attacker_options, menuname('Trolling - Attacker Options', 'Stationary'), {}, '', function(toggle)
		attacker.stationary = toggle
	end)

	-------------------------------------
	-- ENEMY CHOP
	-------------------------------------

	menu.action(attacker_options, menuname('Trolling - Attacker Options', 'Enemy Chop'), {'sendchop'}, '', function()
		local ped_hash = joaat("a_c_chop")
		local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(player_ped)
		pos.x = pos.x + math.random(-3,3)
		pos.y = pos.y + math.random(-3,3)
		pos.z = pos.z - 1.0
		
		REQUEST_MODELS(ped_hash)
		local ped = entities.create_ped(28, ped_hash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
		insert_once(attacker.spawned, "a_c_chop")
		ENTITY.SET_ENTITY_INVINCIBLE(ped, attacker.godmode)
		PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
		TASK.TASK_COMBAT_PED(ped, player_ped, 0, 16)
		PED.SET_PED_COMBAT_ATTRIBUTES(ped, 46, 1)
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(ped_hash)
		relationship:hostile(ped)
	end)

	-------------------------------------
	-- SEND POLICE CAR
	-------------------------------------

	menu.action(attacker_options, menuname('Trolling - Attacker Options', 'Send Police Car'), {'sendpolicecar'}, '', function()
		local veh_hash = joaat("police3")
		local ped_hash = joaat("s_m_y_cop_01")
		local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(player_ped)
		
		REQUEST_MODELS(veh_hash, ped_hash)
		local coords_ptr = alloc()
		local nodeId = alloc()
		local weapons = {"weapon_pistol", "weapon_pumpshotgun"}
		
		if not PATHFIND.GET_RANDOM_VEHICLE_NODE(pos.x, pos.y, pos.z, 80, 0, 0, 0, coords_ptr, nodeId) then
			pos.x = pos.x + math.random(-20,20)
			pos.y = pos.y + math.random(-20,20)
			PATHFIND.GET_CLOSEST_VEHICLE_NODE(pos.x, pos.y, pos.z, coords_ptr, 1, 100, 2.5)
		end
		
		local coords = memory.read_vector3(coords_ptr); memory.free(coords_ptr); memory.free(nodeId)
		local vehicle = entities.create_vehicle(veh_hash, coords, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
		SET_ENT_FACE_ENT(vehicle, player_ped)
		VEHICLE.SET_VEHICLE_SIREN(vehicle, true)
		AUDIO.BLIP_SIREN(vehicle)
		VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle, true, true, true)
		ENTITY.SET_ENTITY_INVINCIBLE(vehicle, attacker.godmode)
		
		for seat = -1, 0 do
			local cop = entities.create_ped(5, ped_hash, coords, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
			local weapon = random(weapons)
			PED.SET_PED_RANDOM_COMPONENT_VARIATION(cop, 0)
			WEAPON.GIVE_WEAPON_TO_PED(cop, joaat(weapon) , -1, false, true)
			PED.SET_PED_NEVER_LEAVES_GROUP(cop, true)
			PED.SET_PED_COMBAT_ATTRIBUTES(cop, 1, true)
			PED.SET_PED_AS_COP(cop, true)
			PED.SET_PED_INTO_VEHICLE(cop, vehicle, seat)
			ENTITY.SET_ENTITY_INVINCIBLE(cop, attacker.godmode)
			TASK.TASK_COMBAT_PED(cop, player_ped, 0, 16)
			PED.SET_PED_KEEP_TASK(cop, true)
			create_tick_handler(function()
				if TASK.GET_SCRIPT_TASK_STATUS(cop, 0x2E85A751) == 7 then
					TASK.CLEAR_PED_TASKS(cop)
					TASK.TASK_SMART_FLEE_PED(cop, PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid), 1000.0, -1, false, false)
					PED.SET_PED_KEEP_TASK(cop, true)
					return false
				end
				return true
			end)
		end
		
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(ped_hash)
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(veh_hash)
		AUDIO.PLAY_POLICE_REPORT("SCRIPTED_SCANNER_REPORT_FRANLIN_0_KIDNAP", 0.0)
	end)

	menu.toggle(attacker_options, menuname('Trolling - Attacker Options', 'Invincible Attackers'), {}, '', function(toggle)
		attacker.godmode = toggle
	end)

	menu.action(attacker_options, menuname('Trolling - Attacker Options', 'Delete Attackers'), {}, '', function()
		local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(p, false)
		for _, model in ipairs(attacker.spawned) do
			DELETE_PEDS(model)
		end
		attacker.spawned = {}
	end)

	-------------------------------------
	-- CAGE OPTIONS
	-------------------------------------

	local cage_options = menu.list(trolling_list, menuname('Trolling', 'Cage'), {}, '')
	
	menu.divider(cage_options, menuname('Trolling', 'Cage'))

	menu.action(cage_options, menuname('Trolling - Cage', 'Small'), {'smallcage'}, '', function()
		local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		TASK.CLEAR_PED_TASKS_IMMEDIATELY(p)
		if PED.IS_PED_IN_ANY_VEHICLE(p) then return end
		trapcage(pid)
	end) 
	
	menu.action(cage_options, menuname('Trolling - Cage', 'Tall'), {'tallcage'}, '', function()
		local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		TASK.CLEAR_PED_TASKS_IMMEDIATELY(p)
		if PED.IS_PED_IN_ANY_VEHICLE(p) then return end
		trapcage_2(pid)
	end)

	-------------------------------------
	-- AUTOMATIC
	-------------------------------------

	-- 1) traps the player in cage
	-- 2) gets the position of the cage
	-- 3) if the current player position is 4 m far from the cage, another one is created.
	menu.toggle(cage_options, menuname('Trolling - Cage', 'Automatic'), {'autocage'}, '', function(toggle)
		cage_loop = toggle
		local a
		while cage_loop do
			wait(1000)
			local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
			local b = ENTITY.GET_ENTITY_COORDS(p)
			if not NETWORK.NETWORK_IS_PLAYER_CONNECTED(pid) then break end
			if a == nil or vect.dist(a, b) >= 4 then
				TASK.CLEAR_PED_TASKS_IMMEDIATELY(p)
				if PED.IS_PED_IN_ANY_VEHICLE(p, false) then return end
				a = b
				trapcage(pid)
				notification.normal('<C>' .. PLAYER.GET_PLAYER_NAME(pid) .. '</C> ' .. 'was out of the cage')
			end
		end
	end)

	-------------------------------------
	-- FENCE
	-------------------------------------

	menu.action(cage_options, menuname('Trolling - Cage', 'Fence'), {'fence'}, '', function()
		local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(player_ped)
		local object_hash = joaat("prop_fnclink_03e")
		pos.z = pos.z - 1.0
		REQUEST_MODELS(object_hash)
		local object = {}
		object[1] = OBJECT.CREATE_OBJECT(object_hash, pos.x - 1.5, pos.y + 1.5, pos.z, true, true, true) 																			
		object[2] = OBJECT.CREATE_OBJECT(object_hash, pos.x - 1.5, pos.y - 1.5, pos.z, true, true, true)
		
		object[3] = OBJECT.CREATE_OBJECT(object_hash, pos.x + 1.5, pos.y + 1.5, pos.z, true, true, true) 	
		local rot_3  = ENTITY.GET_ENTITY_ROTATION(object[3])
		rot_3.z = -90
		ENTITY.SET_ENTITY_ROTATION(object[3], rot_3.x, rot_3.y, rot_3.z, 1, true)
		
		object[4] = OBJECT.CREATE_OBJECT(object_hash, pos.x - 1.5, pos.y + 1.5, pos.z, true, true, true) 	
		local rot_4  = ENTITY.GET_ENTITY_ROTATION(object[4])
		rot_4.z = -90
		ENTITY.SET_ENTITY_ROTATION(object[4], rot_4.x, rot_4.y, rot_4.z, 1, true)
		
		for key, obj in pairs(object) do
			ENTITY.FREEZE_ENTITY_POSITION(obj, true)
		end
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(object_hash)
	end)

	-------------------------------------
	-- STUNT TUBE
	-------------------------------------

	menu.action(cage_options, menuname('Trolling - Cage', 'Stunt Tube'), {'stunttube'}, '', function()
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
		local hash = joaat("stt_prop_stunt_tube_s")
		REQUEST_MODELS(hash)
		local obj = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z, true, true, false)
		local rot = ENTITY.GET_ENTITY_ROTATION(obj)
		ENTITY.SET_ENTITY_ROTATION(obj, rot.x, 90.0, rot.z, 1, true)
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
	end)

	-------------------------------------
	-- RAPE
	-------------------------------------

	busted(menu.toggle, trolling_list, menuname('Trolling', 'Rape'), {}, 'Busted feature', function(toggle)
		rape = toggle
		if pid == PLAYER.PLAYER_ID() then return end		
		if rape then
			piggyback = false
			local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
			local pos = ENTITY.GET_ENTITY_COORDS(p, false)
			STREAMING.REQUEST_ANIM_DICT("rcmpaparazzo_2")
			while not STREAMING.HAS_ANIM_DICT_LOADED("rcmpaparazzo_2") do
				wait()
			end
			TASK.TASK_PLAY_ANIM(PLAYER.PLAYER_PED_ID(), "rcmpaparazzo_2", "shag_loop_a", 8, -8, -1, 1, 0, false, false, false)
			ENTITY.ATTACH_ENTITY_TO_ENTITY(PLAYER.PLAYER_PED_ID(), p, 0, 0, -0.3, 0, 0, 0, 0, false, true, false, false, 0, true)
			while rape do
				wait()
				if not NETWORK.NETWORK_IS_PLAYER_CONNECTED(pid) then
					rape = false
				end
			end
			TASK.CLEAR_PED_TASKS_IMMEDIATELY(PLAYER.PLAYER_PED_ID())
			ENTITY.DETACH_ENTITY(PLAYER.PLAYER_PED_ID(), true, false)
		end
	end)

	-------------------------------------
	-- ENEMY VEHICLES
	-------------------------------------
	
	local minitanks = {
		godmode = false
	}

	local enemy_vehicles = menu.list(trolling_list, menuname('Trolling', 'Enemy Vehicles'), {}, '')

	menu.divider(enemy_vehicles, menuname('Trolling - Enemy Vehicles', 'Minitank'))

	menu.click_slider(enemy_vehicles, menuname('Trolling - Enemy Vehicles', 'Send Minitank(s)'), {'sendminitank'}, '', 1, 25, 1, 1, function(quantity)
		local minitank_hash = joaat("minitank")
		local ped_hash = joaat("s_m_y_blackops_01")
		local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(player_ped)
		
		REQUEST_MODELS(minitank_hash, ped_hash)
		PED.SET_RELATIONSHIP_BETWEEN_GROUPS(0, joaat("ARMY"), joaat("ARMY"))
		
		for i = 1, quantity do
			local weapon = minitanks.weapon or random(modIndex)
			local coords_ptr = alloc()
			local nodeId = alloc()
			local coords

			local vehicle = VEHICLE.CREATE_VEHICLE(minitank_hash, pos.x, pos.y, pos.z, CAM.GET_GAMEPLAY_CAM_ROT(0).z, true, false)
			NETWORK.SET_NETWORK_ID_CAN_MIGRATE(NETWORK.VEH_TO_NET(vehicle), false)

			if ENTITY.DOES_ENTITY_EXIST(vehicle) then
				local driver = entities.create_ped(5, ped_hash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
				PED.SET_PED_INTO_VEHICLE(driver, vehicle, -1)

				if not PATHFIND.GET_RANDOM_VEHICLE_NODE(pos.x, pos.y, pos.z, 80, 0, 0, 0, coords_ptr, nodeId) then
					pos.x = pos.x + math.random(-20,20)
					pos.y = pos.y + math.random(-20,20)
					PATHFIND.GET_CLOSEST_VEHICLE_NODE(pos.x, pos.y, pos.z, coords_ptr, 1, 100, 2.5)
					coords = memory.read_vector3(coords_ptr)
				end

				coords = memory.read_vector3(coords_ptr)
				memory.free(coords_ptr)
				memory.free(nodeId)

				ENTITY.SET_ENTITY_COORDS(vehicle, coords.x, coords.y, coords.z)
				ADD_BLIP_FOR_ENTITY(vehicle, 742, 4)
				ENTITY.SET_ENTITY_INVINCIBLE(vehicle, minitanks.godmode)
				VEHICLE.SET_VEHICLE_MOD_KIT(vehicle, 0)
				VEHICLE.SET_VEHICLE_MOD(vehicle, 10, weapon, false)
				VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle, true, true, true)
				SET_ENT_FACE_ENT(vehicle, player_ped)

				PED.SET_PED_RELATIONSHIP_GROUP_HASH(driver, joaat("ARMY"))
				PED.SET_PED_COMBAT_ATTRIBUTES(driver, 1, true)
				PED.SET_PED_COMBAT_ATTRIBUTES(driver, 3, false)
				
				PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(driver, true)
				TASK.TASK_COMBAT_PED(driver, player_ped, 0, 0)
				PED.SET_PED_KEEP_TASK(driver, true)
				ENTITY.SET_ENTITY_VISIBLE(driver, false, 0)

				create_tick_handler(function()
					if TASK.GET_SCRIPT_TASK_STATUS(driver, 0x2E85A751) == 7 then
						TASK.CLEAR_PED_TASKS(driver)
						TASK.TASK_COMBAT_PED(driver, PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid), 0, 0)
						PED.SET_PED_KEEP_TASK(driver, true)
					end
					return (not ENTITY.IS_ENTITY_DEAD(vehicle))
				end)

				wait(150)
			end			
		end

		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(ped_hash)
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(minitank_hash)
	end)

	menu.toggle(enemy_vehicles, menuname('Trolling - Enemy Vehicles', 'Invincible'), {}, '', function(toggle)
		minitanks.godmode = toggle
	end)

	-------------------------------------
	-- MINITANK WEAPON
	-------------------------------------

	local menu_minitank_weapon = menu.list(enemy_vehicles, menuname('Trolling - Enemy Vehicles', 'Minitank Weapon') .. ': ' .. HUD._GET_LABEL_TEXT("SR_GUN_RANDOM"), {}, '')

	menu.divider(menu_minitank_weapon, HUD._GET_LABEL_TEXT("PM_WEAPONS"))

	menu.action(menu_minitank_weapon, HUD._GET_LABEL_TEXT("SR_GUN_RANDOM"), {}, '', function()
		minitanks.weapon = nil
		menu.set_menu_name(menu_minitank_weapon, menuname('Trolling - Enemy Vehicles', 'Minitank Weapon') .. ': ' .. HUD._GET_LABEL_TEXT("SR_GUN_RANDOM"))
		menu.focus(menu_minitank_weapon)
	end)

	for label, weapon in pairs_by_keys(modIndex) do
		local strg = HUD._GET_LABEL_TEXT(label)
		menu.action(menu_minitank_weapon, strg, {}, '', function()
			minitanks.weapon = weapon
			menu.set_menu_name(menu_minitank_weapon, menuname('Trolling - Enemy Vehicles', 'Minitank Weapon') .. ': ' .. strg)
			menu.focus(menu_minitank_weapon)
		end)
	end

	menu.action(enemy_vehicles, menuname('Trolling - Enemy Vehicles', 'Delete Minitank(s)'), {}, '', function()
		local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(p, false)
		DELETE_NEARBY_VEHICLES(pos, "minitank", 1000.0)
	end)

	-------------------------------------
	-- ENEMY BUZZARD
	-------------------------------------

	local buzzard_visible = true
	local gunner_weapon = "weapon_mg"
	
	menu.divider(enemy_vehicles, menuname('Trolling - Enemy Vehicles', 'Buzzard'))

	menu.click_slider(enemy_vehicles, menuname('Trolling - Enemy Vehicles', 'Send Buzzard(s)'), {'sendbuzzard'}, '', 1, 5, 1, 1, function(quantity)
		local heli_hash = joaat("buzzard2")
		local ped_hash = joaat("s_m_y_blackops_01")
		local player_ped =  PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(player_ped)
		local player_group_hash = PED.GET_PED_RELATIONSHIP_GROUP_HASH(player_ped)

		REQUEST_MODELS(ped_hash, heli_hash)
		
		PED.SET_RELATIONSHIP_BETWEEN_GROUPS(5, joaat("ARMY"), player_group_hash)
		PED.SET_RELATIONSHIP_BETWEEN_GROUPS(5, player_group_hash, joaat("ARMY"))
		PED.SET_RELATIONSHIP_BETWEEN_GROUPS(0, joaat("ARMY"), joaat("ARMY"))

		for i = 1, quantity do
			local heli = VEHICLE.CREATE_VEHICLE(heli_hash, pos.x, pos.y, pos.z, CAM.GET_GAMEPLAY_CAM_ROT(0).z, true, false)
			NETWORK.SET_NETWORK_ID_CAN_MIGRATE(NETWORK.VEH_TO_NET(heli), false)

			if ENTITY.DOES_ENTITY_EXIST(heli) then
				local pilot = entities.create_ped(29, ped_hash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
				PED.SET_PED_INTO_VEHICLE(pilot, heli, -1)

				pos.x = pos.x + math.random(-20,20)
				pos.y = pos.y + math.random(-20,20)
				pos.z = pos.z + 30
				
				ENTITY.SET_ENTITY_COORDS(heli, pos.x, pos.y, pos.z)
				NETWORK.SET_NETWORK_ID_CAN_MIGRATE(NETWORK.VEH_TO_NET(heli), false)
				ENTITY.SET_ENTITY_INVINCIBLE(heli, buzzard_godmode)
				ENTITY.SET_ENTITY_VISIBLE(heli, buzzard_visible, 0)	
				VEHICLE.SET_VEHICLE_ENGINE_ON(heli, true, true, true)
				VEHICLE.SET_HELI_BLADES_FULL_SPEED(heli)
				ADD_BLIP_FOR_ENTITY(heli, 422, 4)

				PED.SET_PED_MAX_HEALTH(pilot, 500)
				ENTITY.SET_ENTITY_HEALTH(pilot, 500)
				ENTITY.SET_ENTITY_INVINCIBLE(pilot, buzzard_godmode)
				ENTITY.SET_ENTITY_VISIBLE(pilot, buzzard_visible, 0)
				PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(pilot, true)
				TASK.TASK_HELI_MISSION(pilot, heli, 0, player_ped, 0.0, 0.0, 0.0, 23, 40.0, 40.0, -1.0, 0, 10, -1.0, 0)
				PED.SET_PED_KEEP_TASK(pilot, true)
				
				for seat = 1, 2 do 
					local ped = entities.create_ped(29, ped_hash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
					PED.SET_PED_INTO_VEHICLE(ped, heli, seat)
					WEAPON.GIVE_WEAPON_TO_PED(ped, joaat(gunner_weapon), -1, false, true)
					PED.SET_PED_COMBAT_ATTRIBUTES(ped, 20, true)
					PED.SET_PED_MAX_HEALTH(ped, 500)
					ENTITY.SET_ENTITY_HEALTH(ped, 500)
					ENTITY.SET_ENTITY_INVINCIBLE(ped, buzzard_godmode)
					ENTITY.SET_ENTITY_VISIBLE(ped, buzzard_visible, 0)
					PED.SET_PED_SHOOT_RATE(ped, 1000)
					PED.SET_PED_RELATIONSHIP_GROUP_HASH(ped, joaat("ARMY"))
					TASK.TASK_COMBAT_HATED_TARGETS_AROUND_PED(ped, 1000, 0)
				end
				
				wait(100)
			end
		end

		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(heli_hash)
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(ped_hash)
	end)
	
	menu.toggle(enemy_vehicles, menuname('Trolling - Enemy Vehicles', 'Invincible'), {}, '', function(toggle)
		buzzard_godmode = toggle
	end)

	local menu_gunner_weapon_list = menu.list(enemy_vehicles, menuname('Trolling - Enemy Vehicles', 'Gunners Weapon') .. ': ' .. HUD._GET_LABEL_TEXT("WT_MG"))
	
	menu.divider(menu_gunner_weapon_list, HUD._GET_LABEL_TEXT("PM_WEAPONS"))

	for label, weapon in pairs_by_keys(gunner_weapon_list) do
		local strg = HUD._GET_LABEL_TEXT(label)
		menu.action(menu_gunner_weapon_list, strg, {}, '', function()
			gunner_weapon = weapon
			menu.set_menu_name(menu_gunner_weapon_list, 'Gunner\'s Weapon: ' .. strg)
			menu.focus(menu_gunner_weapon_list)
		end)
	end

	menu.toggle(enemy_vehicles, menuname('Trolling - Enemy Vehicles', 'Visible'), {}, 'You shouldn\'t be that toxic to turn this off.', function(toggle)
		buzzard_visible = toggle
	end, true)
	
	-------------------------------------
	-- HOSTILE JET
	-------------------------------------

	menu.divider(enemy_vehicles, 'Lazer')

	menu.click_slider(enemy_vehicles, menuname('Trolling - Enemy Vehicles', 'Send Lazer(s)'), {'sendlazer'}, '', 1, 15, 1, 1, function(quantity)
		local jet_hash = joaat("lazer")
		local ped_hash = joaat("s_m_y_blackops_01")
		local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(player_ped)
		REQUEST_MODELS(jet_hash, ped_hash)
		
		for i = 1, quantity do
			local jet = VEHICLE.CREATE_VEHICLE(jet_hash, pos.x, pos.y, pos.z, CAM.GET_GAMEPLAY_CAM_ROT(0).z, true, false)
			NETWORK.SET_NETWORK_ID_CAN_MIGRATE(NETWORK.VEH_TO_NET(jet), false)

			if ENTITY.DOES_ENTITY_EXIST(jet) then
				local pilot = entities.create_ped(5, ped_hash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
				PED.SET_PED_INTO_VEHICLE(pilot, jet, -1)

				pos.x = pos.x + math.random(-80,80)
				pos.y = pos.y + math.random(-80,80)
				pos.z = pos.z + 500

				ENTITY.SET_ENTITY_COORDS(jet, pos.x, pos.y, pos.z)
				SET_ENT_FACE_ENT(jet, player_ped)
				ADD_BLIP_FOR_ENTITY(jet, 16, 4)
				VEHICLE._SET_VEHICLE_JET_ENGINE_ON(jet, true)
				VEHICLE.SET_VEHICLE_FORWARD_SPEED(jet, 60)
				VEHICLE.CONTROL_LANDING_GEAR(jet, 3)
				ENTITY.SET_ENTITY_INVINCIBLE(jet, jet_godmode)
				VEHICLE.SET_VEHICLE_FORCE_AFTERBURNER(jet, true)
				
				TASK.TASK_PLANE_MISSION(pilot, jet, 0, player_ped, 0, 0, 0, 6, 100, 0, 0, 80, 50)
				PED.SET_PED_COMBAT_ATTRIBUTES(pilot, 1, true)
				relationship:hostile(pilot)
				wait(150)
			end
		end
		
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(ped_hash)
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(jet_hash)
	end)

	menu.toggle(enemy_vehicles, menuname('Trolling - Enemy Vehicles', 'Invincible'), {}, '', function(toggle)
		jet_godmode = toggle
	end, jet_godmode)

	menu.action(enemy_vehicles, menuname('Trolling - Enemy Vehicles', 'Delete Lazers'), {}, '', function()
		local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(p, false)
		DELETE_NEARBY_VEHICLES(pos, "lazer", 1000.0)
	end)

	-------------------------------------
	-- DAMAGE
	-------------------------------------

	local damage = menu.list(trolling_list, menuname('Trolling', 'Damage'), {}, 'Choose the weapon and shoot \'em no matter where you are.')
	
	menu.divider(damage, menuname('Trolling', 'Damage'))
	
	menu.action(damage, menuname('Trolling - Damage', 'Heavy Sniper'), {}, '', function()
		local hash = joaat("weapon_heavysniper")
		local a = CAM.GET_GAMEPLAY_CAM_COORD()
		local b = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid), false)
		REQUEST_WEAPON_ASSET(hash)
		MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(a.x, a.y, a.z, b.x , b.y, b.z, 200, 0, hash, PLAYER.PLAYER_PED_ID(), true, false, 2500.0)
	end)

	menu.action(damage, menuname('Trolling - Damage', 'Firework'), {}, '', function()
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
		local hash = joaat("weapon_firework")
		REQUEST_WEAPON_ASSET(hash)
		MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z+3, pos.x , pos.y, pos.z-2, 200, 0, hash, 0, true, false, 2500.0)
	end)

	menu.action(damage, menuname('Trolling - Damage', 'Up-n-Atomizer'), {}, '', function()
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
		local hash = joaat("weapon_raypistol")
		REQUEST_WEAPON_ASSET(hash)
		MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z+3, pos.x , pos.y, pos.z-2, 200, 0, hash, 0, true, false, 2500.0)
	end)

	menu.action(damage, menuname('Trolling - Damage', 'Molotov'), {}, '', function()
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
		local hash = joaat("weapon_molotov")
		REQUEST_WEAPON_ASSET(hash)
		MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z, pos.x , pos.y, pos.z-2, 200, 0, hash, 0, true, false, 2500.0)
	end)

	menu.action(damage, menuname('Trolling - Damage', 'EMP Launcher'), {}, '', function()
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
		local hash = joaat("weapon_emplauncher")
		REQUEST_WEAPON_ASSET(hash)
		MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z, pos.x , pos.y, pos.z-2, 200, 0, hash, 0, true, false, 2500.0)
	end)

	-------------------------------------
	-- HOSTILE PEDS
	-------------------------------------

	menu.action(trolling_list, menuname('Trolling', 'Hostile Peds'), {'hostilepeds'}, 'All on foot peds will combat player.', function()
		local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(player_ped)
		for _, ped in ipairs(GET_NEARBY_PEDS(pid, 90)) do
			if not PED.IS_PED_IN_ANY_VEHICLE(ped, false) and not PED.IS_PED_A_PLAYER(ped) then
				local weapon = random(weapons)
				REQUEST_CONTROL_LOOP(ped)
				TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
				PED.SET_PED_COMBAT_ATTRIBUTES(ped, 46, true)
				PED.SET_PED_MAX_HEALTH(ped, 300)
				ENTITY.SET_ENTITY_HEALTH(ped, 300)
				WEAPON.GIVE_WEAPON_TO_PED(ped, joaat(weapon), -1, false, true)
				TASK.TASK_COMBAT_PED(ped, player_ped, 0, 0)
				WEAPON.SET_PED_DROPS_WEAPONS_WHEN_DEAD(ped, false)
				relationship:hostile(ped)
			end
		end
	end)

	-------------------------------------
	-- HOSTILE TRAFFIC
	-------------------------------------

	menu.action(trolling_list, menuname('Trolling', 'Hostile Traffic'), {'hostiletraffic'}, '', function()
		local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		for _, vehicle in ipairs(GET_NEARBY_VEHICLES(pid, 250)) do	
			if not VEHICLE.IS_VEHICLE_SEAT_FREE(vehicle, -1) then
				local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1)
				if not PED.IS_PED_A_PLAYER(driver) then 
					REQUEST_CONTROL_LOOP(driver)
					PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(driver, true)
					PED.SET_PED_MAX_HEALTH(driver, 300)
					ENTITY.SET_ENTITY_HEALTH(driver, 300)
					TASK.CLEAR_PED_TASKS_IMMEDIATELY(driver)
					PED.SET_PED_INTO_VEHICLE(driver, vehicle, -1)
					PED.SET_PED_COMBAT_ATTRIBUTES(driver, 46, true)
					TASK.TASK_COMBAT_PED(driver, player_ped, 0, 0)
					TASK.TASK_VEHICLE_MISSION_PED_TARGET(driver, vehicle, player_ped, 6, 100, 0, 0, 0, true)
				end
			end
		end
	end)

	-------------------------------------
	-- TROLLY BANDITO
	-------------------------------------

	local banditos = {
		godmode = false, 
		explosive_bandito_exists = false
	}
	local trolly_vehicles = menu.list(trolling_list, menuname('Trolling', 'Trolly Vehicles'), {}, '')

	local function spawn_trolly_vehicle(pid, vehicleHash, pedHash)
		local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(player_ped)
		local coords_ptr = alloc()
		local nodeId = alloc()
		local coords

		local vehicle = VEHICLE.CREATE_VEHICLE(vehicleHash, pos.x, pos.y, pos.z, CAM.GET_GAMEPLAY_CAM_ROT(0).z, true, false)
		NETWORK.SET_NETWORK_ID_CAN_MIGRATE(NETWORK.VEH_TO_NET(vehicle), false)
		VEHICLE.SET_VEHICLE_MOD_KIT(vehicle, 0)
		
		for i = 0, 50 do
			VEHICLE.SET_VEHICLE_MOD(vehicle, i, VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, i) - 1, false)
		end
		
		local driver = entities.create_ped(5, pedHash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
		PED.SET_PED_INTO_VEHICLE(driver, vehicle, -1)

		if not PATHFIND.GET_RANDOM_VEHICLE_NODE(pos.x, pos.y, pos.z, 100, 0, 0, 0, coords_ptr, nodeId) then
			pos.x = pos.x + math.random(-20,20)
			pos.y = pos.y + math.random(-20,20)
			PATHFIND.GET_CLOSEST_VEHICLE_NODE(pos.x, pos.y, pos.z, coords_ptr, 1, 100, 2.5)
			coords = memory.read_vector3(coords_ptr)
			memory.free(coords_ptr); memory.free(nodeId)
		else
			coords = memory.read_vector3(coords_ptr)
			memory.free(coords_ptr); memory.free(nodeId)
		end

		VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle, true, true, true)
		VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(vehicle, true)
		VEHICLE.SET_VEHICLE_IS_CONSIDERED_BY_PLAYER(vehicle, false)
		ENTITY.SET_ENTITY_COORDS(vehicle, coords.x, coords.y, coords.z)
		SET_ENT_FACE_ENT(vehicle, player_ped)

		PED.SET_PED_COMBAT_ATTRIBUTES(driver, 1, true)
		PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(driver, true)
		TASK.TASK_VEHICLE_MISSION_PED_TARGET(driver, vehicle, player_ped, 6, 500.0, 786988, 0.0, 0.0, true)
		SET_PED_CAN_BE_KNOCKED_OFF_VEH(driver, 1)
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(pedHash); STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(vehicleHash)
		return vehicle, driver
	end

	menu.divider(trolly_vehicles, 'Bandito')

	menu.click_slider(trolly_vehicles, menuname('Trolling - Trolly Vehicles', 'Send Bandito(s)'), {'sendbandito'}, '', 1,25,1,1, function(quantity)
		local bandito_hash = joaat("rcbandito")
		local ped_hash = joaat("mp_m_freemode_01")
		REQUEST_MODELS(bandito_hash, ped_hash)
		for i = 1, quantity do
			local vehicle, driver = spawn_trolly_vehicle(pid, bandito_hash, ped_hash)
			ADD_BLIP_FOR_ENTITY(vehicle, 646, 4)
			ENTITY.SET_ENTITY_INVINCIBLE(vehicle, banditos.godmode)
			ENTITY.SET_ENTITY_VISIBLE(driver, false, 0)
			wait(150)
		end
	end)

	menu.toggle(trolly_vehicles, menuname('Trolling - Trolly Vehicles', 'Invincible'), {}, '', function(toggle)
		banditos.godmode = toggle
	end)

	menu.action(trolly_vehicles, menuname('Trolling - Trolly Vehicles', 'Send Explosive Bandito'), {'explobandito'}, '', function()
		local bandito_hash = joaat("rcbandito")
		local ped_hash = joaat("mp_m_freemode_01")
		REQUEST_MODELS(bandito_hash, ped_hash)
		
		if banditos.explosive_bandito_exists then
			notification.normal('Explosive bandito already sent', NOTIFICATION_RED)
			return
		end
		banditos.explosive_bandito_exists = true
		local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local bandito = spawn_trolly_vehicle(pid, bandito_hash, ped_hash)
		VEHICLE.SET_VEHICLE_MOD(bandito, 5, 3, false)
		VEHICLE.SET_VEHICLE_MOD(bandito, 48, 5, false)
		VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(bandito, 128, 0, 128)
		VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(bandito, 128, 0, 128)
		ADD_BLIP_FOR_ENTITY(bandito, 646, 27)
		VEHICLE.ADD_VEHICLE_PHONE_EXPLOSIVE_DEVICE(bandito)

		while not ENTITY.IS_ENTITY_DEAD(bandito) do
			wait()
			local a = ENTITY.GET_ENTITY_COORDS(p)
			local b = ENTITY.GET_ENTITY_COORDS(bandito)
			if vect.dist(a,b) < 3.0 then
				VEHICLE.DETONATE_VEHICLE_PHONE_EXPLOSIVE_DEVICE()
			end
		end

		banditos.explosive_bandito_exists = false
	end)

	menu.action(trolly_vehicles, menuname('Trolling - Trolly Vehicles', 'Delete Bandito(s)'), {}, '', function()
		local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(p, false)
		DELETE_NEARBY_VEHICLES(pos, "rcbandito", 1000.0)
	end)
	
	-------------------------------------
	-- GO KART
	-------------------------------------

	local gokart_godmode = false
	menu.divider(trolly_vehicles, 'Go-Kart')

	menu.click_slider(trolly_vehicles, menuname('Trolling - Trolly Vehicles', 'Send Go-Kart(s)'), {'sendgokart'}, '',1, 15, 1, 1, function(quantity)
		local vehicleHash = joaat("veto2")
		local pedHash = joaat("mp_m_freemode_01")
		REQUEST_MODELS(vehicleHash, pedHash)
		
		for i = 1, quantity do
			local gokart, driver = spawn_trolly_vehicle(pid, vehicleHash, pedHash)
			ADD_BLIP_FOR_ENTITY(gokart, 748, 5)
			ENTITY.SET_ENTITY_INVINCIBLE(gokart, gokart_godmode)
			VEHICLE.SET_VEHICLE_COLOURS(gokart, 89, 0)
			VEHICLE.TOGGLE_VEHICLE_MOD(gokart, 18, true)
			VEHICLE.MODIFY_VEHICLE_TOP_SPEED(gokart, 250)
			ENTITY.SET_ENTITY_INVINCIBLE(driver, gokart_godmode)
			PED.SET_PED_COMPONENT_VARIATION(driver, 3, 111, 13, 2)
			PED.SET_PED_COMPONENT_VARIATION(driver, 4, 67, 5, 2)
			PED.SET_PED_COMPONENT_VARIATION(driver, 6, 101, 1, 2)
			PED.SET_PED_COMPONENT_VARIATION(driver, 8, -1, -1, 2)
			PED.SET_PED_COMPONENT_VARIATION(driver, 11, 148, 5, 2)
			PED.SET_PED_PROP_INDEX(driver, 0, 91, 0, true)
			wait(150)
		end
	
	end)

	menu.toggle(trolly_vehicles, menuname('Trolling - Trolly Vehicles', 'Invincible'), {}, '', function(toggle)
		gokart_godmode = toggle
	end)

	menu.action(trolly_vehicles, menuname('Trolling - Trolly Vehicles', 'Delete Go-Karts'), {}, '', function()
		local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(p, false)
		DELETE_NEARBY_VEHICLES(pos, "veto2", 1000.0)
	end)

	-------------------------------------
	-- RAM PLAYER
	-------------------------------------

	menu.click_slider(trolling_list, menuname('Trolling', 'Ram Player'), {'ram'}, '', 1, 3, 1, 1, function(value)
		local vehicles = {"insurgent2", "phantom2", "adder"}
		local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(player_ped)
		local theta = (math.random() + math.random(0, 1)) * math.pi --returns a random angle between 0 and 2pi (exclusive)
		local coord = vect.new(
			pos.x + 12 * math.cos(theta),
			pos.y + 12 * math.sin(theta),
			pos.z
		)
		local veh_hash = joaat(vehicles[value])
		REQUEST_MODELS(veh_hash)
		local vehicle = entities.create_vehicle(veh_hash, coord, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
		SET_ENT_FACE_ENT(vehicle, player_ped)
		VEHICLE.SET_VEHICLE_DOORS_LOCKED(vehicle, 2)
		ENTITY.SET_ENTITY_LOAD_COLLISION_FLAG(vehicle, true)
		VEHICLE.SET_VEHICLE_FORWARD_SPEED(vehicle, 100)
	end)


	-------------------------------------
	-- PIGGY BACK
	-------------------------------------

	busted(menu.toggle, trolling_list, menuname('Trolling', 'Piggy Back'), {}, 'Busted feature.', function(toggle)
		if pid == players.user() then return end
		piggyback = toggle
		if piggyback then
			rape = false
			local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
			local tick = 0
			STREAMING.REQUEST_ANIM_DICT("rcmjosh2")
			while not STREAMING.HAS_ANIM_DICT_LOADED("rcmjosh2") do
				wait()
			end
			ENTITY.ATTACH_ENTITY_TO_ENTITY(PLAYER.PLAYER_PED_ID(), p, PED.GET_PED_BONE_INDEX(p, 0xDD1C), 0, -0.2, 0.65, 0, 0, 180, false, true, false, false, 0, true)
			TASK.TASK_PLAY_ANIM(PLAYER.PLAYER_PED_ID(), "rcmjosh2", "josh_sitting_loop", 8, -8, -1, 1, 0, false, false, false)
			while piggyback do
				wait()
				if not NETWORK.NETWORK_IS_PLAYER_CONNECTED(pid) then
					piggyback = false
				end
			end
			TASK.CLEAR_PED_TASKS_IMMEDIATELY(PLAYER.PLAYER_PED_ID())
			ENTITY.DETACH_ENTITY(PLAYER.PLAYER_PED_ID(), true, false)
		end
	end)
	
	-------------------------------------
	-- RAIN ROCKETS
	-------------------------------------

	local function rain_rockets(pid, owned)
		local user_ped = PLAYER.PLAYER_PED_ID()
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
		local owner
		local hash = joaat("weapon_airstrike_rocket")
		if not WEAPON.HAS_WEAPON_ASSET_LOADED(hash) then
			WEAPON.REQUEST_WEAPON_ASSET(hash, 31, 0)
		end
		pos.x = pos.x + math.random(-6,6)
		pos.y = pos.y + math.random(-6,6)
		local ground_ptr = alloc(32); MISC.GET_GROUND_Z_FOR_3D_COORD(pos.x, pos.y, pos.z, ground_ptr, false, false); pos.z = memory.read_float(ground_ptr); memory.free(ground_ptr)
		if owned then owner = user_ped else owner = 0 end
		MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z+50, pos.x, pos.y, pos.z, 200, true, hash, owner, true, false, 2500.0)
	end

	menu.toggle_loop(trolling_list, menuname('Trolling', 'Rain Rockets (owned)'), {'ownedrockets'}, '', function()
		rain_rockets(pid, true)
		wait(500)
	end)

	menu.toggle_loop(trolling_list, menuname('Trolling', 'Rain Rockets'), {'rockets'}, '', function()
		rain_rockets(pid, false)
		wait(500)
	end)

	-------------------------------------
	-- NET FORCEFIELD
	-------------------------------------

	local items = {'Disable', 'Push Out', 'Destroy'}
	local current_forcefield
	local forcefield = menu.list(trolling_list, menuname('Forcefield', 'Forcefield') .. ': ' .. menuname('Forcefield', items[ 1 ]) ) 

	for i, item in ipairs(items) do
		menu.action(forcefield, menuname('Forcefield', item), {}, '', function()
			current_forcefield = i
			menu.set_menu_name(forcefield, menuname('Forcefield', 'Forcefield') .. ': ' .. menuname('Forcefield', item) )
			menu.focus(forcefield)
		end)
	end

	create_tick_handler(function()
		if current_forcefield == 1 then
			return true
		elseif current_forcefield == 2 then
			local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
			local pos1 = ENTITY.GET_ENTITY_COORDS(player_ped)
			local entities = GET_NEARBY_ENTITIES(pid, 10)
			
			for _, entity in ipairs(entities) do
				local pos2 = ENTITY.GET_ENTITY_COORDS(entity)
				local force = vect.norm(vect.subtract(pos2, pos1))
				if ENTITY.IS_ENTITY_A_PED(entity)  then
					if not PED.IS_PED_A_PLAYER(entity) and not PED.IS_PED_IN_ANY_VEHICLE(entity, true) then
						REQUEST_CONTROL(entity)
						PED.SET_PED_TO_RAGDOLL(entity, 1000, 1000, 0, 0, 0, 0)
						ENTITY.APPLY_FORCE_TO_ENTITY(entity, 1, force.x, force.y, force.z, 0, 0, 0.5, 0, false, false, true)
					end
				else
					REQUEST_CONTROL(entity)
					ENTITY.APPLY_FORCE_TO_ENTITY(entity, 1, force.x, force.y, force.z, 0, 0, 0.5, 0, false, false, true)
				end
			end
		elseif current_forcefield == 3 then
			local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
			local pos = ENTITY.GET_ENTITY_COORDS(player_ped)
			FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, 29, 5.0, false, true, 0.0, true)
		end
		return true
	end)

	-------------------------------------
	-- KAMIKASE
	-------------------------------------

	menu.click_slider(trolling_list, menuname('Trolling', 'Kamikaze'), {'kamikaze'}, '', 1, 3, 1, 1, function(value)
		local planes = {"lazer", "mammatus", "cuban800"}
		local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(player_ped)
		local theta = (math.random() + math.random(0, 1)) * math.pi --returns a random angle between 0 and 2pi (exclusive)
		local coord = vect.new(
			pos.x + 20 * math.cos(theta),
			pos.y + 20 * math.sin(theta),
			pos.z + 30
		)
		local hash = joaat(planes[ value ])
		REQUEST_MODELS(hash)
		local plane = entities.create_vehicle(hash, coord, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
		SET_ENT_FACE_ENT_3D(plane, player_ped)
		ENTITY.SET_ENTITY_LOAD_COLLISION_FLAG(plane, true)
		VEHICLE.SET_VEHICLE_FORWARD_SPEED(plane, 150)
		VEHICLE.CONTROL_LANDING_GEAR(plane, 3)
	end)

	-------------------------------------
	-- CREEPER CLOWN
	-------------------------------------

	menu.action(trolling_list, menuname('Trolling', 'Creeper Clown'), {}, '', function()
		local hash = joaat("s_m_y_clown_01")
		local explosion = {
			asset 	= "scr_rcbarry2",
			name 	= "scr_exp_clown"
		}
		local appears = {
			asset 	= "scr_rcbarry2",
			name 	= "scr_clown_appears"
		}

		AUDIO.REQUEST_SCRIPT_AUDIO_BANK("BARRY_02_CLOWN_A", false, -1)
		AUDIO.REQUEST_SCRIPT_AUDIO_BANK("BARRY_02_CLOWN_B", false, -1)
		AUDIO.REQUEST_SCRIPT_AUDIO_BANK("BARRY_02_CLOWN_C", false, -1)

		REQUEST_MODELS(hash)
		local player = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(player)
		local theta = ( math.random() + math.random(0, 1) ) * math.pi
		local coord = vect.new(
			pos.x + 7.0 * math.cos(theta),
			pos.y + 7.0 * math.sin(theta),
			pos.z - 1.0
		)
		local ped = entities.create_ped(0, hash, coord, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
	
		REQUEST_PTFX_ASSET(appears.asset)
		GRAPHICS.USE_PARTICLE_FX_ASSET(appears.asset)
		GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_ON_ENTITY(appears.name, ped, 0.0, 0.0, -1.0, 0.0, 0.0, 0.0, 0.5, false, false, false, false)
		SET_ENT_FACE_ENT(ped, player)
		PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true) 
		
		TASK.TASK_GO_TO_COORD_ANY_MEANS(ped, pos.x, pos.y, pos.z, 5.0, 0, 0, 0, 0)
		local dest = pos
		PED.SET_PED_KEEP_TASK(ped, true)
		AUDIO.STOP_PED_SPEAKING(ped, true)
		AUDIO.SET_AMBIENT_VOICE_NAME(ped, "CLOWNS")
		
		create_tick_handler(function()
			local pos = ENTITY.GET_ENTITY_COORDS(ped)
			local ppos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))

			if vect.dist(pos, ppos) < 3.0 then
				REQUEST_PTFX_ASSET(explosion.asset)
				GRAPHICS.USE_PARTICLE_FX_ASSET(explosion.asset)
				GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD(
					explosion.name, 
					pos.x, 
					pos.y, 
					pos.z, 
					0.0, 
					0.0, 
					0.0, 
					1.0, 
					false, false, false, false
				)
				FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, 0, 1.0, true, true, 1.0)
				ENTITY.SET_ENTITY_VISIBLE(ped, false, 0)

				return false
			elseif vect.dist(ppos, dest) > 3 then
				dest = ppos
				TASK.TASK_GO_TO_COORD_ANY_MEANS(ped, ppos.x, ppos.y, ppos.z, 5.0, 0, 0, 0, 0)
			end
			return true
		end)

		AUDIO.RELEASE_NAMED_SCRIPT_AUDIO_BANK("BARRY_02_CLOWN_A")
		AUDIO.RELEASE_NAMED_SCRIPT_AUDIO_BANK("BARRY_02_CLOWN_B")
		AUDIO.RELEASE_NAMED_SCRIPT_AUDIO_BANK("BARRY_02_CLOWN_C")
	end)

	---------------------
	---------------------
	-- NET VEHICLE OPT
	---------------------
	---------------------

	local vehicleOpt = menu.list(menu.player_root(pid), menuname('Player - Vehicle', 'Vehicle'), {}, '')

	menu.divider(vehicleOpt, menuname('Player - Vehicle', 'Vehicle'))
	
	-------------------------------------
	-- TELEPORT
	-------------------------------------

	local tpvehicle = menu.list(vehicleOpt, menuname('Player - Vehicle', 'Teleport'))

	menu.divider(tpvehicle, menuname('Player - Vehicle', 'Teleport'))

	menu.action(tpvehicle, menuname('Vehicle - Teleport', 'TP to Me'), {}, '', function()
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), false)
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle == NULL then return end
		REQUEST_CONTROL_LOOP(vehicle)
		ENTITY.SET_ENTITY_COORDS(vehicle, pos.x, pos.y, pos.z, false, false, false)
	end)

	menu.action(tpvehicle, menuname('Vehicle - Teleport', 'TP to Ocean'), {}, '', function()
		local pos = {x = -4809.93, y = -2521.67, z = 250}
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle == NULL then return end
		REQUEST_CONTROL_LOOP(vehicle)
		ENTITY.SET_ENTITY_COORDS(vehicle, pos.x, pos.y, pos.z, false, false, false)
	end)

	menu.action(tpvehicle, menuname('Vehicle - Teleport', 'TP to Prision'), {}, '', function()
		local pos = {x = 1680.11, y = 2512.89, z = 45.56}
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle == NULL then return end
		REQUEST_CONTROL_LOOP(vehicle)
		ENTITY.SET_ENTITY_COORDS(vehicle, pos.x, pos.y, pos.z, false, false, false)
	end)

	menu.action(tpvehicle, menuname('Vehicle - Teleport', 'TP to Fort Zancudo'), {}, '', function()
		local pos = {x = -2219.0583, y = 3213.0232, z = 32.8102}
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle == NULL then return end
		REQUEST_CONTROL_LOOP(vehicle)
		ENTITY.SET_ENTITY_COORDS(vehicle, pos.x, pos.y, pos.z, false, false, false)
	end)

	menu.action(tpvehicle, menuname('Vehicle - Teleport', 'TP to Waypoint'), {}, '', function()
		local pos = GET_WAYPOINT_COORDS()
		if pos then
			local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
			if vehicle == NULL then return end
			REQUEST_CONTROL_LOOP(vehicle)
			ENTITY.SET_ENTITY_COORDS(vehicle, pos.x, pos.y, pos.z, false, false, false)
		else notification.normal('No waypoint found', NOTIFICATION_RED) end
	end)

	-------------------------------------
	-- ACROBATICS
	-------------------------------------

	local acrobatics = menu.list(vehicleOpt, menuname('Player - Vehicle', 'Acrobatics'), {}, '')

	menu.divider(acrobatics, menuname('Player - Vehicle', 'Acrobatics'))


	menu.action(acrobatics, menuname('Vehicle - Acrobatics', 'Ollie'), {}, '', function()
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle ~= NULL and VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(vehicle) then
			REQUEST_CONTROL_LOOP(vehicle)
			ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, 0.0, 0.0, 10.0, 0.0, 0.0, 0.0, 1, false, true, true, true, true)
		end
	end)
	
	menu.action(acrobatics, menuname('Vehicle - Acrobatics', 'Kick Flip'), {}, '', function()
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(vehicle) then
			REQUEST_CONTROL_LOOP(vehicle)
			ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, 0.0, 0.0, 10.71, 5.0, 0.0, 0.0, 1, false, true, true, true, true)
		end
	end)

	menu.action(acrobatics, menuname('Vehicle - Acrobatics', 'Double Kick Flip'), {}, '', function()
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle ~= NULL and VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(vehicle) then
			REQUEST_CONTROL_LOOP(vehicle)
			ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, 0.0, 0.0, 21.43, 20.0, 0.0, 0.0, 1, false, true, true, true, true)
		end
	end)

	menu.action(acrobatics, menuname('Vehicle - Acrobatics', 'Heel Flip'), {}, '', function()
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle ~= NULL and VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(vehicle) then
			REQUEST_CONTROL_LOOP(vehicle)
			ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, 0.0, 0.0, 10.71, -5.0, 0.0, 0.0, 1, false, true, true, true, true)
		end
	end)

	-------------------------------------
	-- KILL ENGINE
	-------------------------------------
	
	menu.action(vehicleOpt, menuname('Player - Vehicle', 'Kill Engine'), {}, '', function()
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle == NULL then return end
		REQUEST_CONTROL_LOOP(vehicle)
		VEHICLE.SET_VEHICLE_ENGINE_HEALTH(vehicle, -4000)
	end)

	-------------------------------------
	-- CLEAN
	-------------------------------------
	
	menu.action(vehicleOpt, menuname('Player - Vehicle', 'Clean'), {}, '', function()
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle == NULL then return end
		REQUEST_CONTROL_LOOP(vehicle)
		VEHICLE.SET_VEHICLE_DIRT_LEVEL(vehicle, 0.0)
	end)

	-------------------------------------
	-- REPAIR
	-------------------------------------

	menu.action(vehicleOpt, menuname('Player - Vehicle', 'Repair'), {}, '', function()
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle == NULL then return end
		REQUEST_CONTROL_LOOP(vehicle)
		VEHICLE.SET_VEHICLE_FIXED(vehicle)
		VEHICLE.SET_VEHICLE_DEFORMATION_FIXED(vehicle)
		VEHICLE.SET_VEHICLE_DIRT_LEVEL(vehicle, 0.0)
	end)

	-------------------------------------
	-- KICK
	-------------------------------------

	menu.action(vehicleOpt, menuname('Player - Vehicle', 'Kick'), {}, '', function()
		local param = {578856274, PLAYER.PLAYER_ID(), 0, 0, 0, 0, 1, PLAYER.PLAYER_ID(), MISC.GET_FRAME_COUNT()}
		util.trigger_script_event(1 << pid, param)
	end)
	
	-------------------------------------
	-- UPGRADE
	-------------------------------------

	menu.action(vehicleOpt, menuname('Player - Vehicle', 'Upgrade'), {}, '', function()
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle == NULL then return end
		REQUEST_CONTROL_LOOP(vehicle)
		VEHICLE.SET_VEHICLE_MOD_KIT(vehicle, 0)
		for i = 0, 50 do
			VEHICLE.SET_VEHICLE_MOD(vehicle, i, VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, i) - 1, false)
		end
	end)
	
	-------------------------------------
	-- CUSTOM PAINT
	-------------------------------------

	menu.action(vehicleOpt, menuname('Player - Vehicle', 'Apply Radom Paint'), {}, '', function()
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle == NULL then return end
		REQUEST_CONTROL_LOOP(vehicle)
		local primary, secundary = Colour.Random(), Colour.Random()
		VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(vehicle, unpack(primary))
		VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(vehicle, unpack(secundary))
	end)
	
	-------------------------------------
	-- BURST TIRES
	-------------------------------------
	
	menu.action(vehicleOpt, menuname('Player - Vehicle', 'Burst Tires'), {}, '', function()
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle == NULL then return end
		REQUEST_CONTROL_LOOP(vehicle)
		VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(vehicle, true)
		for wheelId = 0, 7 do
			VEHICLE.SET_VEHICLE_TYRE_BURST(vehicle, wheelId, true, 1000.0)
		end
	end)

	-------------------------------------
	-- CATAPULT
	-------------------------------------
	
	menu.action(vehicleOpt, menuname('Player - Vehicle', 'Catapult'), {}, '', function()
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle ~= NULL and VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(vehicle) then
			REQUEST_CONTROL_LOOP(vehicle)
			ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, 0.0, 0.0, 9999, 0.0, 0.0, 0.0, 1, false, true, true, true, true)
		end	
	end)

	-------------------------------------
	-- BOOST FORWARD
	-------------------------------------
	
	menu.action(vehicleOpt, menuname('Player - Vehicle', 'Boost Forward'), {}, '', function()
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle == NULL then return end
		REQUEST_CONTROL_LOOP(vehicle)
		local unitv = ENTITY.GET_ENTITY_FORWARD_VECTOR(vehicle)
		local force = vect.mult(unitv, 40)
		AUDIO.SET_VEHICLE_BOOST_ACTIVE(vehicle, true)
		ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, force.x, force.y, force.z, 0.0, 0.0, 0.0, 1, false, true, true, true, true)
		AUDIO.SET_VEHICLE_BOOST_ACTIVE(vehicle, false)
	end)

	-------------------------------------
	-- LICENSE PLATE
	-------------------------------------

	menu.text_input(vehicleOpt, menuname('Player - Vehicle', 'Set License Plate'), {'setplatetxt'}, 'MAX 8 characters', function(strg)
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle == NULL or strg == '' then return end
		REQUEST_CONTROL_LOOP(vehicle)
		while #strg > 8 do -- reduces the length of string till it's 8 characters long
			wait()
			strg = string.gsub(strg, '.$', '')
		end
		VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(vehicle, strg)
	end)

	-------------------------------------
	-- GOD MODE
	-------------------------------------
	
	menu.toggle(vehicleOpt, menuname('Player - Vehicle', 'God Mode'), {}, '', function(toggle)
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle == NULL then return end
		REQUEST_CONTROL_LOOP(vehicle)
		if toggle then
			VEHICLE.SET_VEHICLE_ENVEFF_SCALE(vehicle, 0.0)
			VEHICLE.SET_VEHICLE_BODY_HEALTH(vehicle, 1000.0)
			VEHICLE.SET_VEHICLE_ENGINE_HEALTH(vehicle, 1000.0)
			VEHICLE.SET_VEHICLE_FIXED(vehicle)
			VEHICLE.SET_VEHICLE_DEFORMATION_FIXED(vehicle)
			VEHICLE.SET_VEHICLE_PETROL_TANK_HEALTH(vehicle, 1000.0)
			VEHICLE.SET_VEHICLE_DIRT_LEVEL(vehicle, 0.0)
			if VEHICLE._IS_VEHICLE_DAMAGED(vehicle) then
				for i = 0, 10 do
					VEHICLE.SET_VEHICLE_TYRE_FIXED(vehicle, i)
				end
			end
		end
		ENTITY.SET_ENTITY_INVINCIBLE(vehicle, toggle)
		ENTITY.SET_ENTITY_PROOFS(vehicle, toggle, toggle, toggle, toggle, toggle, toggle, 1, toggle)
		VEHICLE.SET_DISABLE_VEHICLE_PETROL_TANK_DAMAGE(vehicle, toggle)
		VEHICLE.SET_DISABLE_VEHICLE_PETROL_TANK_FIRES(vehicle, toggle)
		VEHICLE.SET_VEHICLE_CAN_BE_VISIBLY_DAMAGED(vehicle, not toggle)
		VEHICLE.SET_VEHICLE_CAN_BREAK(vehicle, not toggle)
		VEHICLE.SET_VEHICLE_ENGINE_CAN_DEGRADE(vehicle, not toggle)
		VEHICLE.SET_VEHICLE_EXPLODES_ON_HIGH_EXPLOSION_DAMAGE(vehicle, not toggle)
		VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(vehicle, not toggle)
		VEHICLE.SET_VEHICLE_WHEELS_CAN_BREAK(vehicle, not toggle)
	end)

	-------------------------------------
	-- INVISIBLE
	-------------------------------------

	menu.toggle(vehicleOpt, menuname('Player - Vehicle', 'Invisible'), {}, '', function(toggle)
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle == NULL then return end
		REQUEST_CONTROL_LOOP(vehicle)
		ENTITY.SET_ENTITY_VISIBLE(vehicle, not toggle, false)
	end)

	-------------------------------------
	-- FREEZE
	-------------------------------------

	menu.toggle(vehicleOpt, menuname('Player - Vehicle', 'Freeze'), {}, '', function(toggle)
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle == NULL then return end
		REQUEST_CONTROL_LOOP(vehicle)
		ENTITY.FREEZE_ENTITY_POSITION(vehicle, toggle)
	end)

	-------------------------------------
	-- LOCK DOORS
	-------------------------------------

	menu.toggle(vehicleOpt, menuname('Player - Vehicle', 'Child Lock'), {}, '', function(toggle)
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle == NULL then return end
		REQUEST_CONTROL_LOOP(vehicle)
		if toggle then
			VEHICLE.SET_VEHICLE_DOORS_LOCKED(vehicle, 4)
		else
			VEHICLE.SET_VEHICLE_DOORS_LOCKED(vehicle, 1)
		end
	end)

	---------------------
	---------------------
	-- FRIENDLY
	---------------------
	---------------------

	local friendly_list = menu.list(menu.player_root(pid), menuname('Player', 'Friendly Options'), {}, '')
	
	menu.divider(friendly_list, menuname('Player', 'Friendly Options'))

	-------------------------------------
	-- KILL KILLERS
	-------------------------------------

	menu.toggle_loop(friendly_list, menuname('Friendly Options', 'Kill Killers'), {'explokillers'}, 'Explodes the player\'s murderer.', function(toggle)
		local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local killer = PED.GET_PED_SOURCE_OF_DEATH(p)
		if ENTITY.DOES_ENTITY_EXIST(killer) and not ENTITY.IS_ENTITY_DEAD(killer) and killer ~= p then
			local pos = ENTITY.GET_ENTITY_COORDS(killer, false)
			FIRE.ADD_OWNED_EXPLOSION(p, pos.x, pos.y, pos.z, 1, 1.0, true, false, 1)
			while not ENTITY.IS_ENTITY_DEAD(p) do
				wait()
			end
		end
	end)

-- end of generate_features
end

local defaulthealth = ENTITY.GET_ENTITY_MAX_HEALTH(PLAYER.PLAYER_PED_ID())
local modded_health = defaulthealth

---------------------
---------------------
-- SELF
---------------------
---------------------

local self_options = menu.list(menu.my_root(), menuname('Self', 'Self'), {'selfoptions'}, '')

-------------------------------------
-- HEALTH OPTIONS
-------------------------------------

menu.toggle(self_options, menuname('Self', 'Mod Max Health'), {'modhealth'}, 'Changes your ped\'s max health. Some menus will tag you as modder. It returns to default max health when it\'s disabled.', function(toggle)
	modhealth  = toggle
	if modhealth then
		local user = PLAYER.PLAYER_PED_ID()
		PED.SET_PED_MAX_HEALTH(user,  modded_health)
		ENTITY.SET_ENTITY_HEALTH(user, modded_health)
	else
		local user = PLAYER.PLAYER_PED_ID()
		PED.SET_PED_MAX_HEALTH(user, defaulthealth)
		menu.trigger_commands('moddedhealth ' .. defaulthealth) -- just if you want the slider to go to default value when mod health is off
		if ENTITY.GET_ENTITY_HEALTH(user) > defaulthealth then 
			ENTITY.SET_ENTITY_HEALTH(user, defaulthealth)
		end
	end
	create_tick_handler(function()
		if PED.GET_PED_MAX_HEALTH(PLAYER.PLAYER_PED_ID()) ~= modded_health  then
			PED.SET_PED_MAX_HEALTH(PLAYER.PLAYER_PED_ID(), modded_health)
			ENTITY.SET_ENTITY_HEALTH(PLAYER.PLAYER_PED_ID(), modded_health)	
		end
		if config.general.displayhealth then
			local strg = '~b~' .. 'HEALTH ' .. '~w~' .. tostring(ENTITY.GET_ENTITY_HEALTH(PLAYER.PLAYER_PED_ID()))
			DRAW_STRING(strg, config.healthtxtpos.x, config.healthtxtpos.y, 0.6, 4)	
		end
		return modhealth
	end)
end)

menu.slider(self_options, menuname('Self', 'Set Max Health'), {'moddedhealth'}, 'Health will be modded with the given value.', 100, 9000,defaulthealth,50, function(value)
	modded_health = value
end)

menu.action(self_options, menuname('Self', 'Refill Health'), {'maxhealth'}, '', function()
	ENTITY.SET_ENTITY_HEALTH(PLAYER.PLAYER_PED_ID(), PED.GET_PED_MAX_HEALTH(PLAYER.PLAYER_PED_ID()))
end)

menu.action(self_options, menuname('Self', 'Refill Armour'), {'maxarmour'}, '', function()
	if util.is_session_started() then
		PED.SET_PED_ARMOUR(PLAYER.PLAYER_PED_ID(), 50)
	else
		PED.SET_PED_ARMOUR(PLAYER.PLAYER_PED_ID(), 100)
	end
end)

menu.toggle(self_options, menuname('Self', 'Refill Health in Cover'), {'healincover'}, '', function(toggle)
	refillincover = toggle
	while refillincover do
		if PED.IS_PED_IN_COVER(PLAYER.PLAYER_PED_ID()) then
			PLAYER._SET_PLAYER_HEALTH_RECHARGE_LIMIT(players.user(), 1)
			PLAYER.SET_PLAYER_HEALTH_RECHARGE_MULTIPLIER(players.user(), 15)
		else
			PLAYER._SET_PLAYER_HEALTH_RECHARGE_LIMIT(players.user(), 0.5)
			PLAYER.SET_PLAYER_HEALTH_RECHARGE_MULTIPLIER(players.user(), 1)
		end
		wait()
	end
	if not refillincover then
		PLAYER._SET_PLAYER_HEALTH_RECHARGE_LIMIT(players.user(), 0.25)
		PLAYER.SET_PLAYER_HEALTH_RECHARGE_MULTIPLIER(players.user(), 1)
	end
end)

menu.action(self_options, menuname('Self', 'Instant Bullshark'), {}, 'For those who prefer a non toggle based option.', function()
	write_global.int(2703656 + 3590, 1)
end)

-------------------------------------
-- FORCEFIELD
-------------------------------------

local items = {'Disable', 'Push Out', 'Destroy'}
local current_forcefield
local forcefield = menu.list(self_options, menuname('Forcefield', 'Forcefield') .. ': ' .. menuname('Forcefield', items[ 1 ]) ) 

for i, item in ipairs(items) do
	menu.action(forcefield, menuname('Forcefield', item), {}, '', function()
		current_forcefield = i
		menu.set_menu_name(forcefield, menuname('Forcefield', 'Forcefield') .. ': ' .. menuname('Forcefield', item) )
		menu.focus(forcefield)
	end)
end

create_tick_handler(function()
	if current_forcefield == 1 then
		return true
	elseif current_forcefield == 2 then
		local pos1 = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
		local entities = GET_NEARBY_ENTITIES(PLAYER.PLAYER_ID(), 10)
		for k, entity in pairs(entities) do
			local pos2 = ENTITY.GET_ENTITY_COORDS(entity)
			local force = vect.norm(vect.subtract(pos2, pos1))
			if ENTITY.IS_ENTITY_A_PED(entity)  then
				if not PED.IS_PED_A_PLAYER(entity) and not PED.IS_PED_IN_ANY_VEHICLE(entity, true) then
					REQUEST_CONTROL(entity)
					PED.SET_PED_TO_RAGDOLL(entity, 1000, 1000, 0, 0, 0, 0)
					ENTITY.APPLY_FORCE_TO_ENTITY(entity, 1, force.x, force.y, force.z, 0, 0, 0.5, 0, false, false, true)
				end
			else
				REQUEST_CONTROL(entity)
				ENTITY.APPLY_FORCE_TO_ENTITY(entity, 1, force.x, force.y, force.z, 0, 0, 0.5, 0, false, false, true)
			end
		end
	elseif current_forcefield == 3 then
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
		proofs.explosion = true
		FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, 29, 5.0, false, true, 0.0, true)
	end
	return true
end)

-------------------------------------
-- FORCE
-------------------------------------

menu.toggle(self_options, menuname('Self', 'Force'), {'jedimode'}, 'Use Force in nearby vehicles.', function(toggle)
	force = toggle	
	if force then
		notification.help(
			"Press " .. "~INPUT_VEH_FLY_SELECT_TARGET_RIGHT~ " .. 'and ' ..
			"~INPUT_VEH_FLY_ROLL_RIGHT_ONLY~ " .. 'to use Force.'
		)
		local user_ped = PLAYER.PLAYER_PED_ID()
		local pos = ENTITY.GET_ENTITY_COORDS(user_ped)
		util.create_thread(function()
			local effect = {asset	= "scr_ie_tw", name	= "scr_impexp_tw_take_zone"}
			local colour = Colour.New(0.5, 0, 0.5)
			
			REQUEST_PTFX_ASSET(effect.asset)
			GRAPHICS.USE_PARTICLE_FX_ASSET(effect.asset)
			GRAPHICS.SET_PARTICLE_FX_NON_LOOPED_COLOUR(colour.r, colour.g, colour.b)
			GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_ON_ENTITY(
				effect.name, 
				user_ped, 
				0.0, 
				0.0, 
				-0.9, 
				0.0, 
				0.0, 
				0.0, 
				1.0, 
				false, false, false
			)
		end)
	end
	while force do
		wait()
		local entities = GET_NEARBY_VEHICLES(players.user(), 50)
		if PAD.IS_CONTROL_PRESSED(0, 118) then
			for k, entity in pairs(entities) do
				REQUEST_CONTROL(entity)
				ENTITY.APPLY_FORCE_TO_ENTITY(entity, 1, 0, 0, 0.5, 0, 0, 0, 0, false, false, true)
			end
		end
		if PAD.IS_CONTROL_PRESSED(0, 109) then
			for k, entity in pairs(entities) do
				REQUEST_CONTROL(entity)
				ENTITY.APPLY_FORCE_TO_ENTITY(entity, 1, 0, 0, -70, 0, 0, 0, 0, false, false, true)
			end
		end
	end
end)

-------------------------------------
-- CARPET RIDE
-------------------------------------

local object
menu.toggle(self_options, menuname('Self', 'Carpet Ride'), {'carpetride'}, '', function(toggle)
	carpetride = toggle
	local hspeed = 0.2
	local vspeed = 0.2
	local user_ped = PLAYER.PLAYER_PED_ID()
	local pos = ENTITY.GET_ENTITY_COORDS(user_ped)
	local object_hash = joaat("p_cs_beachtowel_01_s")
	
	if carpetride then
		STREAMING.REQUEST_ANIM_DICT("rcmcollect_paperleadinout@")
		REQUEST_MODELS(object_hash)
		TASK.CLEAR_PED_TASKS_IMMEDIATELY(user_ped)
		object = OBJECT.CREATE_OBJECT(object_hash, pos.x, pos.y, pos.z, true, true, true)
		ENTITY.ATTACH_ENTITY_TO_ENTITY(user_ped, object, 0, 0, -0.2, 1.0, 0, 0, 0, false, true, false, false, 0, true)
		ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(object, false, false)

		TASK.TASK_PLAY_ANIM(user_ped, "rcmcollect_paperleadinout@", "meditiate_idle", 8, -8, -1, 1, 0, false, false, false)
		notification.help(
			"Press " .. "~INPUT_MOVE_UP_ONLY~ " .. "~INPUT_MOVE_DOWN_ONLY~ " .. "~INPUT_VEH_JUMP~ " .. "~INPUT_DUCK~ " .. 'to use Carpet Ride.\n' ..
			"Press " .. "~INPUT_VEH_MOVE_UP_ONLY~ " .. "to move faster"
		)
		local height = ENTITY.GET_ENTITY_COORDS(object, false).z
		
		while carpetride do
			wait()
			HUD.DISPLAY_SNIPER_SCOPE_THIS_FRAME()
			local obj_pos = ENTITY.GET_ENTITY_COORDS(object)
			local camrot = CAM.GET_GAMEPLAY_CAM_ROT(0)
			ENTITY.SET_ENTITY_ROTATION(object, 0, 0, camrot.z, 0, true)
			local forward = ENTITY.GET_ENTITY_FORWARD_VECTOR(user_ped)
			if PAD.IS_CONTROL_PRESSED(0, 32) then
				if PAD.IS_CONTROL_PRESSED(0, 102) then 
					height = height + vspeed 
				end
				if PAD.IS_CONTROL_PRESSED(0, 36) then 
					height = height - vspeed 
				end
				ENTITY.SET_ENTITY_COORDS(object, obj_pos.x + forward.x * hspeed, obj_pos.y + forward.y * hspeed, height, false, false, false, false)
			elseif PAD.IS_CONTROL_PRESSED(0, 130) then
				  ENTITY.SET_ENTITY_COORDS(object, obj_pos.x - forward.x * hspeed, obj_pos.y - forward.y * hspeed, height, false, false, false, false)
			else
				 if PAD.IS_CONTROL_PRESSED(0, 102) then
					ENTITY.SET_ENTITY_COORDS(object, obj_pos.x, obj_pos.y, height, false, false, false, false)
					height = height + vspeed
				elseif PAD.IS_CONTROL_PRESSED(0, 36) then
					ENTITY.SET_ENTITY_COORDS(object, obj_pos.x, obj_pos.y, height, false, false, false, false)
					height = height - vspeed
				end
			end
			   if PAD.IS_CONTROL_PRESSED(0, 61) then
				hspeed, vspeed = 1.5, 1.5
			else
				hspeed, vspeed = 0.2, 0.2
			end
		end
	else
		TASK.CLEAR_PED_TASKS_IMMEDIATELY(user_ped)
		ENTITY.DETACH_ENTITY(user_ped, true, false)
		ENTITY.SET_ENTITY_VISIBLE(object, false)
		entities.delete_by_handle(object)
	end
end)

-------------------------------------
-- KILL KILLERS
-------------------------------------

menu.toggle_loop(self_options, menuname('Friendly Options', 'Kill Killers'), {'explokillers'}, 'Explodes the player\'s murderer.', function(toggle)
	local p = PLAYER.PLAYER_PED_ID()
	local killer = PED.GET_PED_SOURCE_OF_DEATH(p)
	if ENTITY.DOES_ENTITY_EXIST(killer) and not ENTITY.IS_ENTITY_DEAD(killer) and killer ~= p then
		local pos = ENTITY.GET_ENTITY_COORDS(killer, false)
		FIRE.ADD_OWNED_EXPLOSION(p, pos.x, pos.y, pos.z, 1, 1.0, true, false, 1)
		while not ENTITY.IS_ENTITY_DEAD(p) do
			wait()
		end
	end
end)

-------------------------------------
-- UNDEAD OFFRADAR
-------------------------------------

menu.toggle(self_options, menuname('Self', 'Undead Offradar'), {'undeadoffradar'}, '', function(toggle)
	undead = toggle
	local user = PLAYER.PLAYER_PED_ID()
	local defaulthealth = ENTITY.GET_ENTITY_MAX_HEALTH(user)
	if undead then ENTITY.SET_ENTITY_MAX_HEALTH(user, 0) end
	while undead do
		wait()
		if ENTITY.GET_ENTITY_MAX_HEALTH(user) ~= 0 then
			ENTITY.SET_ENTITY_MAX_HEALTH(user, 0)
		end
	end
	ENTITY.SET_ENTITY_MAX_HEALTH(user, defaulthealth)
end)

-------------------------------------
-- TRAILS
-------------------------------------

local bones = {
	0x49D9,	-- left hand
	0xDEAD,	-- right hand
	0x3779,	-- left foot
	0xCC4D	-- right foot
}
local trails_colour = Colour.New(1.0, 0, 1.0)
local trails_options = menu.list(self_options, menuname('Self', 'Trails'))

menu.toggle(trails_options, menuname('Self - Trails', 'Trails'), {'toggletrails'}, '', function(toggle)
	trails = toggle
	local lastvehicle
	local minimum, maximum
	local effect = {asset = "scr_rcpaparazzo1", name = "scr_mich4_firework_sparkle_spawn"}
	local effects = {}
	REQUEST_PTFX_ASSET(effect.asset)
	create_tick_handler(function()	
		local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
		if vehicle == NULL then
			for _, boneId in ipairs(bones) do
				GRAPHICS.USE_PARTICLE_FX_ASSET(effect.asset)
				local fx = GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY_BONE(
					effect.name, 
					PLAYER.PLAYER_PED_ID(), 
					0.0, 
					0.0, 
					0.0, 
					0.0, 
					0.0, 
					0.0, 
					PED.GET_PED_BONE_INDEX(PLAYER.PLAYER_PED_ID(), boneId),
					0.7, --scale
					false, false, false
				)
				GRAPHICS.SET_PARTICLE_FX_LOOPED_COLOUR(
					fx, 
					trails_colour.r, 
					trails_colour.g, 
					trails_colour.b, 
					0
				)
				table.insert(effects, fx)
			end
		else
			if lastvehicle ~= vehicle then
				local minimum_ptr = alloc()
				local maximum_ptr = alloc()
				MISC.GET_MODEL_DIMENSIONS(ENTITY.GET_ENTITY_MODEL(vehicle), minimum_ptr, maximum_ptr)
				minimum = memory.read_vector3(minimum_ptr); memory.free(minimum_ptr)
				maximum = memory.read_vector3(maximum_ptr); memory.free(maximum_ptr)
				lastvehicle = vehicle
			end

			local offsets = {
				left = vect.new(minimum.x, minimum.y), -- BACK & LEFT
				right = vect.new(maximum.x, minimum.y) -- BACK & RIGHT
			}
			for k, offset in pairs(offsets) do
				GRAPHICS.USE_PARTICLE_FX_ASSET(effect.asset)
				local fx = GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY(
					effect.name,
				 	vehicle, 
					offset.x, 
					offset.y, 
					0.0, 
					0.0, 0.0, 0.0, 
					1.0, -- scale
					false, false, false
				)
				GRAPHICS.SET_PARTICLE_FX_LOOPED_COLOUR(
					fx, 
					trails_colour.r, 
					trails_colour.g, 
					trails_colour.b, 
					0
				)
				table.insert(effects, fx)
			end
		end
		return trails
	end)
	
	local sTime = os.time()
	while trails do
		if os.time() - sTime == 1 then
			for i = 1, #effects do
				GRAPHICS.STOP_PARTICLE_FX_LOOPED(effects[i], 0)
				GRAPHICS.REMOVE_PARTICLE_FX(effects[i], 0)
				effects[i] = nil
			end
			sTime = os.time()
		end
		wait()
	end
	
	for k, effect in pairs(effects) do
		GRAPHICS.STOP_PARTICLE_FX_LOOPED(effect, 0)
		GRAPHICS.REMOVE_PARTICLE_FX(effect, 0)
	end
end)

menu.rainbow(menu.colour(trails_options, menuname('Self - Trails', 'Colour'), {'trailcolour'}, '', Colour.New(1.0, 0, 1.0), false, function(colour)
	trails_colour = colour
end))

-------------------------------------
-- COMBUSTION MAN
-------------------------------------

menu.toggle(self_options, menuname('Self', 'Combustion Man'), {'combustionman'}, 'Shoot explosive ammo without aiming a weapon. If you think Oppressor MK2 is annoying, you haven\'t use it with this.', function(toggle)
	shootlazer = toggle
	if shootlazer then
		notification.help("Press " .. "~INPUT_ATTACK~ " .. "to use Combustion Man.")
		create_tick_handler(function()
			PAD.DISABLE_CONTROL_ACTION(2, 106, true) -- INPUT_VEH_MOUSE_CONTROL_OVERRIDE
			PAD.DISABLE_CONTROL_ACTION(2, 122, true) -- INPUT_VEH_FLY_MOUSE_CONTROL_OVERRIDE
			PAD.DISABLE_CONTROL_ACTION(2, 135, true) -- INPUT_VEH_SUB_MOUSE_CONTROL_OVERRIDE

			local a = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
			local b = GET_OFFSET_FROM_CAM(80)
			local hash = joaat("VEHICLE_WEAPON_PLAYER_LAZER")
			HUD.DISPLAY_SNIPER_SCOPE_THIS_FRAME()
			if not WEAPON.HAS_WEAPON_ASSET_LOADED(hash) then
				WEAPON.REQUEST_WEAPON_ASSET(hash, 31, 26)
				while not WEAPON.HAS_WEAPON_ASSET_LOADED(hash) do
					wait()
				end
			end
			if PAD.IS_DISABLED_CONTROL_PRESSED(2, 24) then
				MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(
					a.x, a.y, a.z,
					b.x, b.y, b.z,
					200,
					true,
					hash,
					PLAYER.PLAYER_PED_ID(),
					true, true, -1.0
				)
			end
			if not PED.IS_PED_IN_ANY_VEHICLE(PLAYER.PLAYER_PED_ID(), true) then
				PLAYER.DISABLE_PLAYER_FIRING(PLAYER.PLAYER_PED_ID(), true)
			end
			return shootlazer
		end)
	end
end)

-------------------------------------
-- PROOFS
-------------------------------------

local menu_self_proofs = menu.list(self_options, menuname('Self', 'Player Proofs'), {}, '')

menu.divider(menu_self_proofs, menuname('Self', 'Player Proofs'))


for proof, bool in pairs_by_keys(proofs) do
	menu.toggle(menu_self_proofs, menuname('Self - Proofs', first_upper(proof)), {proof .. 'proof'}, '', function(toggle)
		proofs[ proof ] = toggle
		ENTITY.SET_ENTITY_PROOFS(PLAYER.PLAYER_PED_ID(), proofs.bullet, proofs.fire, proofs.explosion, proofs.collision, proofs.melee, proofs.steam, 1, proofs.drown)
	end)
end

create_tick_handler(function()
	if includes(proofs, true) then
		ENTITY.SET_ENTITY_PROOFS(PLAYER.PLAYER_PED_ID(), proofs.bullet, proofs.fire, proofs.explosion, proofs.collision, proofs.melee, proofs.steam, 1, proofs.drown)
	end
	return true
end)

---------------------
---------------------
-- WEAPON
---------------------
---------------------

local weapon_options = menu.list(menu.my_root(), menuname('Weapon', 'Weapon'), {'weaponoptions'}, '')

menu.divider(weapon_options, menuname('Weapon', 'Weapon'))

-------------------------------------
-- VEHICLE PAINT GUN
-------------------------------------

menu.toggle_loop(weapon_options, menuname('Weapon', 'Vehicle Paint Gun'), {'paintgun'}, 'Applies a random colour combination to the damaged vehicle.', function(toggle)
	if PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) then
		local ptr = alloc(32); PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(PLAYER.PLAYER_ID(), ptr)
		local entity = memory.read_int(ptr); memory.free(ptr)
		
		if entity == NULL then 
			return 
		end
		
		if ENTITY.IS_ENTITY_A_PED(entity) then
			entity = PED.GET_VEHICLE_PED_IS_IN(entity, false)
		end
		if ENTITY.IS_ENTITY_A_VEHICLE(entity) then
			REQUEST_CONTROL_LOOP(entity)
			local primary, secundary = Colour.Random(), Colour.Random()
			VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(entity, unpack(primary))
			VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(entity, unpack(secundary))
		end
	end
end)

-------------------------------------
-- SHOOTING EFFECT
-------------------------------------

local effects = 
{
	-- Clown Flowers
	{
		asset 	= "scr_rcbarry2",
		name 	= "scr_clown_bul",
		scale	= 0.3, 
		rot		= vect.new(0, 0, 180)
	},
	-- Clown Muz
	{
		asset 	= "scr_rcbarry2",
		name	= "muz_clown",
		scale 	= 0.8,
		rot		= vect.new(0, 0, 0)
	}
}
local items = {'Disable', 'Clown Flowers', 'Clown Muz'}
local current_effect
local shooting_effect = menu.list(weapon_options, menuname('Shooting Effect', 'Shooting Effect') .. ': ' .. menuname('Shooting Effect', items[1]) )

for i, item in ipairs(items) do
	menu.action(shooting_effect, menuname('Shooting Effect', item), {}, '', function()
		current_effect = i
		menu.set_menu_name(shooting_effect, menuname('Shooting Effect', 'Shooting Effect') .. ': ' .. menuname('Shooting Effect', item) )
		menu.focus(shooting_effect)
	end)
end

create_tick_handler(function()
	if current_effect == 1 then
		return true
	elseif current_effect ~= nil then
		local user_ped = PLAYER.PLAYER_PED_ID()
		if PED.IS_PED_SHOOTING(user_ped) then
			local effect = effects[ current_effect - 1 ]
			local weapon = WEAPON.GET_CURRENT_PED_WEAPON_ENTITY_INDEX(user_ped, false)
			local bone_pos = ENTITY._GET_ENTITY_BONE_POSITION_2(weapon, ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(weapon, "gun_muzzle"))
			local offset = ENTITY.GET_OFFSET_FROM_ENTITY_GIVEN_WORLD_COORDS(weapon, bone_pos.x, bone_pos.y, bone_pos.z)
			REQUEST_PTFX_ASSET(effect.asset)
			GRAPHICS.USE_PARTICLE_FX_ASSET(effect.asset)
			GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_ON_ENTITY(
				effect.name,
				weapon, 
				offset.x + 0.10,
				offset.y,
				offset.z,
				effect.rot.x,
				effect.rot.y,
				effect.rot.z,
				effect.scale,
				false, false, false
			)
		end	
	end
	return true
end)

-------------------------------------
-- MAGNET GUN
-------------------------------------

local items = {'Disable', 'Smooth', 'Caos Mode'}
local current_magnetgun
local sphere_colour = Colour.New(0, 255, 255)
local magnetgun = menu.list(weapon_options, menuname('Weapon', 'Magnet Gun') .. ': ' .. menuname('Weapon - Magnet Gun', items[ 1 ]))

for i, item in ipairs(items) do
	menu.action(magnetgun, menuname('Weapon - Magnet Gun', item), {}, '', function()
		current_magnetgun = i
		menu.set_menu_name(magnetgun, menuname('Weapon', 'Magnet Gun') .. ': ' .. menuname('Weapon - Magnet Gun', item) )
		menu.focus(magnetgun)
	end)
end

create_tick_handler(function()
	if current_magnetgun == 1 then
		return true
	elseif current_magnetgun == 2 and PLAYER.IS_PLAYER_FREE_AIMING(PLAYER.PLAYER_ID()) then
		local v = {}
		local offset = GET_OFFSET_FROM_CAM(30)
		for _, vehicle in ipairs(entities.get_all_vehicles_as_handles()) do
			if vehicle ~= PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false) then
				local vpos = ENTITY.GET_ENTITY_COORDS(vehicle)
				if vect.dist(offset, vpos) < 70 and REQUEST_CONTROL(vehicle) and #v < 20 then
					insert_once(v, vehicle)
					local unitv = vect.norm(vect.subtract(offset, vpos))
					local dist = vect.dist(offset, vpos)
					local vel = vect.mult(unitv, dist)
					ENTITY.SET_ENTITY_VELOCITY(vehicle, vel.x, vel.y, vel.z)
				end
			end
		end
		GRAPHICS._DRAW_SPHERE(offset.x, offset.y, offset.z, 0.5, sphere_colour.r, sphere_colour.g, sphere_colour.b, 0.5)
		sphere_colour = Colour.Rainbow(sphere_colour)
	elseif current_magnetgun == 3 and PLAYER.IS_PLAYER_FREE_AIMING(PLAYER.PLAYER_ID()) then
		local v = {}
		local offset = GET_OFFSET_FROM_CAM(30)
		for _, vehicle in ipairs(entities.get_all_vehicles_as_handles()) do
			if vehicle ~= PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false) then
				local vpos = ENTITY.GET_ENTITY_COORDS(vehicle)
				if vect.dist(offset, vpos) < 70 and REQUEST_CONTROL(vehicle) and #v < 20 then
					insert_once(v, vehicle)
					local unitv = vect.norm(vect.subtract(offset, vpos))
					local dist = vect.dist(offset, vpos)
					local mult = 15 * (1 - 2^(-dist))
					local force = vect.mult(unitv, mult)
					ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, force.x, force.y, force.z, 0, 0, 0.5, 0, false, false, true)
				end
			end
		end
		GRAPHICS._DRAW_SPHERE(offset.x, offset.y, offset.z, 0.5, sphere_colour.r, sphere_colour.g, sphere_colour.b, 0.5)
		sphere_colour = Colour.Rainbow(sphere_colour)
	end
	return true
end)

-------------------------------------
-- AIRSTRIKE GUN
-------------------------------------

menu.toggle_loop(weapon_options, menuname('Weapon', 'Airstrike Gun'), {}, '', function(toggle)
	local hash = joaat("weapon_airstrike_rocket")
	if not WEAPON.HAS_WEAPON_ASSET_LOADED(hash) then
		WEAPON.REQUEST_WEAPON_ASSET(hash, 31, 0)
	end
	local hit, coords, normal_surface, entity = RAYCAST(nil, 1000.0)
	if hit == 1 then
		if PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) then
			MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(coords.x, coords.y, coords.z + 35, coords.x, coords.y, coords.z, 200, true, hash, PLAYER.PLAYER_PED_ID(), true, false, 2500.0)
		end
	end
end)

-------------------------------------
-- BULLET CHANGER
-------------------------------------


local ammo_ptrs = --belongs to ammo type 4
{
	WT_FLAREGUN		= {hash = 0x47757124},
	WT_GL			= {hash = 0xA284510B},
	WT_GNADE 		= {hash = 0x93E220BD},
	WT_MOLOTOV		= {hash = 0x24B17070},
	WT_GNADE_SMK	= {hash = 0xFDBC8A50},
	WT_SNWBALL		= {hash = 0x0787F0BB}
}
local rockets_list = {
	WT_A_RPG		= "weapon_rpg",
	WT_FWRKLNCHR	= "weapon_firework",
	WT_RAYPISTOL	= "weapon_raypistol"
}
local bullet 			= 0xB1CA77B1
local from_memory 		= false
local default_bullet 	= {}

function GET_CURRENT_WEAPON_AMMO_TYPE() --returns 4 if OBJECT (rocket, grenade, etc.), and 2 if INSTANT HIT
	local offsets = {0x08, 0x10D8, 0x20, 0x54}
	local addr = address_from_pointer_chain(worldptr, offsets)
	if addr ~= NULL then
		return memory.read_byte(addr), addr
	else
		error('current ammo type not found')
	end
end

function GET_CURRENT_WEAPON_AMMO_PTR()
	local offsets = {0x08, 0x10D8, 0x20, 0x60}
	local addr = address_from_pointer_chain(worldptr, offsets)
	local value
	if addr ~= NULL then
		return memory.read_long(addr), addr
	else
		error('current ammo pointer not found.')
	end
end

function SET_BULLET_TO_DEFAULT()
	for weapon, data in pairs(default_bullet) do
		local atype, aptr = data.ammotype, data.ammoptr
		memory.write_byte(atype.addr, atype.value)
		memory.write_long(aptr.addr, aptr.value)
	end
end


local toggle_bullet_type = menu.toggle(weapon_options, menuname('Weapon', 'Bullet Changer') .. ': ' .. HUD._GET_LABEL_TEXT("WT_A_RPG"), {'bulletchanger'}, '', function(toggle)
	bulletchanger = toggle
	while bulletchanger do
		wait()
		if not from_memory then
			SET_BULLET_TO_DEFAULT()
			local user_ped = PLAYER.PLAYER_PED_ID()
			local pos2 = GET_OFFSET_FROM_CAM(30)
			if PED.IS_PED_SHOOTING(user_ped) and GET_CURRENT_WEAPON_AMMO_TYPE() ~= 4 then
				local current_weapon = WEAPON.GET_CURRENT_PED_WEAPON_ENTITY_INDEX(user_ped, false)
				local pos1 = ENTITY._GET_ENTITY_BONE_POSITION_2(
					current_weapon, 
					ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(current_weapon, "gun_muzzle")
				)
				MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos1.x, pos1.y, pos1.z, pos2.x, pos2.y, pos2.z, 200, true, bullet, user_ped, true, false, 2000.0)
			end
		else
			local weapon_ptr = alloc(12)
			WEAPON.GET_CURRENT_PED_WEAPON(PLAYER.PLAYER_PED_ID(), weapon_ptr, true)
			local weapon = memory.read_int(weapon_ptr); memory.free(weapon_ptr)
			local ammotype, ammotype_addr = GET_CURRENT_WEAPON_AMMO_TYPE()
			local ammoptr, ammoptr_addr = GET_CURRENT_WEAPON_AMMO_PTR()
	
			if not does_key_exists(default_bullet, weapon) then
				default_bullet[weapon] = {
					['ammotype'] = {['addr'] = ammotype_addr, ['value'] = ammotype},
					['ammoptr'] = {['addr'] = ammoptr_addr, ['value'] = ammoptr}
				}
				memory.write_byte(ammotype_addr, 4)
				memory.write_long(ammoptr_addr, bullet)
			else
				if ammotype ~= 4 then
					memory.write_byte(ammotype_addr, 4)
				end
				if ammoptr ~= bullet then
					memory.write_long(ammoptr_addr, bullet)
				end
			end
		end
	end
	SET_BULLET_TO_DEFAULT()
end)

local bullet_type = menu.list(weapon_options, menuname('Weapon', 'Set Weapon Bullet'))
menu.divider(bullet_type, menuname('Weapon', 'Set Weapon Bullet'))

local type_throwables = menu.list(bullet_type, HUD._GET_LABEL_TEXT("AT_THROW"), {}, 'Not networked. Other players can only see explosions.')
menu.divider(type_throwables, HUD._GET_LABEL_TEXT("AT_THROW"))

for label, v in pairs_by_keys(rockets_list) do
	local strg = HUD._GET_LABEL_TEXT(label)
	menu.action(bullet_type, strg, {}, '', function()
		bullet = joaat(v)
		menu.set_menu_name(toggle_bullet_type, menuname('Weapon', 'Bullet Changer') .. ': ' .. strg)
		if not bulletchanger then menu.trigger_command(toggle_bullet_type, 'on') end
		menu.focus(bullet_type)
		from_memory = false
	end)
end

for label, data in pairs_by_keys(ammo_ptrs) do
	local strg = HUD._GET_LABEL_TEXT(label)
	menu.action(type_throwables, strg, {}, '', function()
		local current_ptr = alloc(12)
		WEAPON.GET_CURRENT_PED_WEAPON(PLAYER.PLAYER_PED_ID(), current_ptr)
		local current = memory.read_int(current_ptr); memory.free(current_ptr)
		if data.ammoptr == nil then 
			WEAPON.GIVE_WEAPON_TO_PED(PLAYER.PLAYER_PED_ID(), data.hash, -1, false, false)
			WEAPON.SET_CURRENT_PED_WEAPON(PLAYER.PLAYER_PED_ID(), data.hash, false)
			data.ammoptr = GET_CURRENT_WEAPON_AMMO_PTR()
			WEAPON.SET_CURRENT_PED_WEAPON(PLAYER.PLAYER_PED_ID(), current, false)
		end
		bullet = data.ammoptr
    	menu.set_menu_name(toggle_bullet_type, menuname('Weapon', 'Bullet Changer') .. ': ' .. strg)
		if not bulletchanger then menu.trigger_command(toggle_bullet_type, 'on') end
		menu.focus(bullet_type)
		from_memory = true
  	end)
end

-------------------------------------
-- PTFX GUN
-------------------------------------

local effects = {
	['Clown Explosion'] = {
		asset 	= "scr_rcbarry2",
		name	= "scr_exp_clown",
		colour 	= false
	},
	['Clown Appears'] = {
		asset	= "scr_rcbarry2",
		name 	= "scr_clown_appears",
		colour 	= false
	},
	['FW Trailburst'] = {
		asset 	= "scr_rcpaparazzo1",
		name 	= "scr_mich4_firework_trailburst_spawn",
		colour 	= true
	},
	['FW Starburst'] = {
		asset	= "scr_indep_fireworks",
		name	= "scr_indep_firework_starburst",
		colour 	= true
	},
	['FW Fountain'] = {
		asset 	= "scr_indep_fireworks",
		name	= "scr_indep_firework_fountain",
		colour 	= true
	},
	['Alien Disintegration'] = {
		asset	= "scr_rcbarry1",
		name 	= "scr_alien_disintegrate",
		colour 	= false
	},
	['Clown Flowers'] = {
		asset	= "scr_rcbarry2",
		name	= "scr_clown_bul",
		colour 	= false
	},
	['FW Ground Burst'] = {
		asset 	= "proj_indep_firework",
		name	= "scr_indep_firework_grd_burst",
		colour 	= false
	}
}
local impact_effect = effects ['Clown Explosion']
local impact_colour = Colour.New(0.5, 0, 0.5)

local fx_weapon_root = menu.list(weapon_options, menuname('Hit Effect', 'Hit Effect'))

menu.divider(fx_weapon_root, menuname('Hit Effect', 'Hit Effect'))

local fx_weapon_toggle = menu.toggle(fx_weapon_root,  menuname('Hit Effect', 'Hit Effect') .. ': ' .. menuname('Hit Effect', 'Clown Explosion'), {}, '', function(toggle)
	fx_weapon = toggle 
	while fx_weapon do
		REQUEST_PTFX_ASSET(impact_effect.asset)
		local hit, coords, normal_surface, entity = RAYCAST(nil, 1000.0)
		if hit == 1 then
			if PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) then
				local rot = GET_ROTATION_FROM_DIRECTION(normal_surface)
				GRAPHICS.USE_PARTICLE_FX_ASSET(impact_effect.asset)
				if impact_effect.colour then
					local colour = impact_colour
					GRAPHICS.SET_PARTICLE_FX_NON_LOOPED_COLOUR(colour.r, colour.g, colour.b)
				end
				GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD(
					impact_effect.name, 
					coords.x, 
					coords.y, 
					coords.z, 
					rot.x - 90, 
					rot.y, 
					rot.z, 
					1.0, 
					false, false, false, false
				)
			end
		end
		wait()
	end	
end)

local fx_list = menu.list(fx_weapon_root,  menuname('Hit Effect', 'Set Effect') )

for k, table in pairs_by_keys(effects) do
	local helptext
	if effects[k].colour then
		helptext = "Colour can be changed."
	else helptext = "" end
	menu.action(fx_list, menuname('Hit Effect', k), {}, helptext, function()
		impact_effect = effects[k]
		menu.set_menu_name(fx_weapon_toggle, menuname('Hit Effect', 'Hit Effect') .. ': ' .. menuname('Hit Effect', k) )
		if not fx_weapon then menu.trigger_command(fx_weapon_toggle, 'on') end
		menu.focus(fx_list)
	end)
end


menu.rainbow(menu.colour(fx_weapon_root, menuname('Hit Effect', 'Colour'), {'effectcolour'}, 'Only works on some fx\'s.',  Colour.New(0.5, 0, 0.5), false, function(colour)
	impact_colour = colour
end))

-------------------------------------
-- VEHICLE GUN
-------------------------------------

local vehicle_gun_list = {
	['Lazer'] 			= "lazer",
	['Insurgent'] 		= "insurgent2",
	['Phantom Wedge'] 	= "phantom2",
	['Adder'] 			= "adder"
}
local vehicle_for_gun = vehicle_gun_list.Adder
local into_vehicle
local vehicle_gun = menu.list(weapon_options, menuname('Weapon', 'Vehicle Gun'), {'vehiclegun'}, '')

menu.divider(vehicle_gun, menuname('Weapon', 'Vehicle Gun'))

local toggle_vehicle_gun = menu.toggle(vehicle_gun, menuname('Weapon', 'Vehicle Gun') .. ': Adder', {'togglevehiclegun'}, '', function(toggle)
	vehiclegun = toggle
	local preview
	local offset = 25
	local maxoffset = 100
	local minoffset = 15
	local mult = 0.0

	create_tick_handler(function()
		local hash = joaat(vehicle_for_gun)
		REQUEST_MODELS(hash)
		local hit, coords, nsurface, entity = RAYCAST(nil, offset + 5.0, 1)
		
		if not config.general.disablepreview then 
			local offset_limit = minoffset + mult * (maxoffset - minoffset)
			offset = incr(offset, 0.5, offset_limit)
			if PAD.IS_CONTROL_JUST_PRESSED(2, 241) and PAD.IS_CONTROL_PRESSED(2, 241) then
				if mult < 1.0 then mult = mult + 0.25 end
			end		
			if PAD.IS_CONTROL_JUST_PRESSED(2, 242) and PAD.IS_CONTROL_PRESSED(2, 242) then
				if mult > 0.0 then mult = mult - 0.25 end
			end
		end
		
		if hit ~= 1 then 
			coords = GET_OFFSET_FROM_CAM(offset) 
		end
		
		if PLAYER.IS_PLAYER_FREE_AIMING(PLAYER.PLAYER_ID()) then
			local rot = CAM.GET_GAMEPLAY_CAM_ROT(0)
			if not config.general.disablepreview then
				if not ENTITY.DOES_ENTITY_EXIST(preview) then
					preview = VEHICLE.CREATE_VEHICLE(hash, coords.x, coords.y, coords.z, rot.z, false, false)
					ENTITY.SET_ENTITY_ALPHA(preview, 153, true)
					ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(preview, false, false)
				end
				
				ENTITY.SET_ENTITY_COORDS_NO_OFFSET(preview, coords.x, coords.y, coords.z, false, false, false)
				
				if hit == 1 then
					VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(preview, 1.0)
				end
				
				ENTITY.SET_ENTITY_ROTATION(preview, rot.x, rot.y, rot.z, 0, true)
				
				if instructional:begin() then
					add_control_group_instructional_button(29, "FM_AE_SORT_2")
					instructional:set_background_colour(0, 0, 0, 80)
					instructional:draw()
				end

			end
			if PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) then
				if ENTITY.DOES_ENTITY_EXIST(preview) then
					entities.delete_by_handle(preview)
				end
				
				local vehicle = entities.create_vehicle(hash, coords, rot.z)
				ENTITY.SET_ENTITY_ROTATION(vehicle, rot.x, rot.y, rot.z, 0, true) 
				
				if into_vehicle then
					VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle, true, true, true)
					PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), vehicle, -1)
				else VEHICLE.SET_VEHICLE_DOORS_LOCKED(vehicle, 2) end
				
				ENTITY.SET_ENTITY_LOAD_COLLISION_FLAG(vehicle, true)
				VEHICLE.SET_VEHICLE_FORWARD_SPEED(vehicle, 200)
				ENTITY._SET_ENTITY_CLEANUP_BY_ENGINE(vehicle, true)
			end
		elseif ENTITY.DOES_ENTITY_EXIST(preview) then
			entities.delete_by_handle(preview)
		end
		return vehiclegun
	end)
end)

local set_vehicle = menu.list(vehicle_gun, menuname('Weapon - Vehicle Gun', 'Set Vehicle'))

for k, vehicle in pairs_by_keys(vehicle_gun_list) do
	menu.action(set_vehicle, k, {}, '', function()
		vehicle_for_gun = vehicle_gun_list[k]
		menu.set_menu_name(toggle_vehicle_gun, 'Vehicle Gun: ' .. k)
		if not vehiclegun then menu.trigger_command(toggle_vehicle_gun, 'on') end
		menu.focus(set_vehicle)
	end)
end

menu.text_input(vehicle_gun, menuname('Weapon - Vehicle Gun', 'Custom Vehicle'), {'customvehgun'}, '', function(vehicle)
	local modelHash = joaat(vehicle)
	local name = HUD._GET_LABEL_TEXT(VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(modelHash))
	if STREAMING.IS_MODEL_A_VEHICLE(modelHash) then
		vehicle_for_gun = vehicle
		menu.set_menu_name(toggle_vehicle_gun, 'Vehicle Gun: ' .. name)
	else 
		return notification.normal('The model is not a vehicle', NOTIFICATION_RED) 
	end
	if not vehiclegun then menu.trigger_command(toggle_vehicle_gun, 'on') end
end)

menu.toggle(vehicle_gun, menuname('Weapon - Vehicle Gun', 'Set Into Vehicle'), {}, '', function(toggle)
	into_vehicle = toggle
end)

-------------------------------------
-- TELEPORT GUN
-------------------------------------

menu.toggle(weapon_options, menuname('Weapon', 'Teleport Gun'), {'tpgun'}, '', function(toggle)
	telegun = toggle
	while telegun do
		wait()
		local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
		local hit, coords, normal_surface, entity = RAYCAST(nil, 1000.0)
		
		if hit == 1 and PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) then	
			if vehicle == NULL then
				coords.z = coords.z + 1.0
				SET_ENTITY_COORDS_2(PLAYER.PLAYER_PED_ID(), coords)
			else
				local speed = ENTITY.GET_ENTITY_SPEED(vehicle)
				ENTITY.SET_ENTITY_COORDS(vehicle, coords.x, coords.y, coords.z, false, false, false, false)
				ENTITY.SET_ENTITY_HEADING(vehicle, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
				VEHICLE.SET_VEHICLE_FORWARD_SPEED(vehicle, speed)
			end
		end
	end
end)

-------------------------------------
-- BULLET SPEED MULT
-------------------------------------

local default_speed = {}
local speed_mult = 1

function SET_AMMO_SPEED_MULT(mult)
	local offsets = {0x08, 0x10D8, 0x20, 0x60, 0x58}
	local addr = address_from_pointer_chain(worldptr, offsets)
	if addr ~= NULL then
		local value = memory.read_float(addr)
		if not does_key_exists(default_speed, addr) and value ~= nil then
			default_speed[addr] = value
			memory.write_float(addr, mult * value)
		elseif value ~= mult * default_speed[addr] then
			memory.write_float(addr, mult * default_speed[addr])
		end
	end
end

menu.click_slider(weapon_options, menuname('Weapon', 'Bullet Speed Mult'), {'ammospeedmult'},  'Allows you to change the speed of non-instant hit bullets (rockets, fireworks, grenades, etc.)', 100, 2500, 100, 50, function(mult)
	speed_mult = mult / 100
	if speed_mult == 1 then
		for addr,  value in pairs(default_speed) do
			memory.write_float(addr, value)
			default_speed[addr] = nil
		end
	end
end)

-------------------------------------
-- MAGNET ENTITIES
-------------------------------------

menu.toggle(weapon_options, menuname('Weapon', 'Magnet Entities'), {}, '', function(toggle)
	magnetent = toggle
	if not magnetent then return end
	local applyforce = false
	local entities = {}
	local entity = 0
	notification.help(
		"Magnet Entities applies an attractive force on two specific entities. " ..
		"Shoot the chosen entities (vehicle, object or ped) to attract them to each other"
	)
	while magnetent do
		wait()
		if PLAYER.IS_PLAYER_FREE_AIMING(PLAYER.PLAYER_ID()) then
			local ptr = alloc(32)
			
            if PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(PLAYER.PLAYER_ID(), ptr) then
				entity = memory.read_int(ptr)
			end
			memory.free(ptr)
			
            if entity and entity ~= NULL then
				if ENTITY.IS_ENTITY_A_PED(entity) and PED.IS_PED_IN_ANY_VEHICLE(entity) then
					local vehicle = PED.GET_VEHICLE_PED_IS_IN(entity, false)
					entity = vehicle
				end
				draw_box_esp(entity, Colour.New(255,0,0))
			end
				
			if PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) and entity and entity ~= NULL then
				local mypos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
				local entpos = ENTITY.GET_ENTITY_COORDS(entity)
				local dist = vect.dist(mypos, entpos)
				
				if entities[1] ~= entity and dist < 500 then 
					table.insert(entities, entity)
				end
				
				if #entities == 2 then
					local ent1, ent2 = entities[1], entities[2]
					create_tick_handler(function()
						if not ENTITY.DOES_ENTITY_EXIST(ent1) or not ENTITY.DOES_ENTITY_EXIST(ent2) then
							return false
						end

						local pos1 = ENTITY.GET_ENTITY_COORDS(ent1)
						local pos2 = ENTITY.GET_ENTITY_COORDS(ent2)
						local dist = vect.dist(pos1, pos2)
						local force1 = vect.mult(vect.norm(vect.subtract(pos2, pos1)), dist / 20)
						local force2 = vect.mult(force1, -1)

						
						if ENTITY.IS_ENTITY_A_PED(ent1) then
                            if not PED.IS_PED_A_PLAYER(ent1) then
                                REQUEST_CONTROL(ent1)
                                PED.SET_PED_TO_RAGDOLL(ent1, 1000, 1000, 0, 0, 0, 0)
                                ENTITY.APPLY_FORCE_TO_ENTITY(ent1, 1, force1.x, force1.y, force1.z, 0, 0, 0, 0, false, false, true)
                            end
                        else
                            REQUEST_CONTROL(ent1)
                            ENTITY.APPLY_FORCE_TO_ENTITY(ent1, 1, force1.x, force1.y, force1.z, 0, 0, 0, 0, false, false, true)
						end
						
						if ENTITY.IS_ENTITY_A_PED(ent2) then
                            if not PED.IS_PED_A_PLAYER(ent2) then
                                REQUEST_CONTROL(ent2)
                                PED.SET_PED_TO_RAGDOLL(ent2, 1000, 1000, 0, 0, 0, 0)
                                ENTITY.APPLY_FORCE_TO_ENTITY(ent2, 1, force2.x, force2.y, force2.z, 0, 0, 0, 0, false, false, true)
                            end
                        else
                            REQUEST_CONTROL(ent2)
                            ENTITY.APPLY_FORCE_TO_ENTITY(ent2, 1, force2.x, force2.y, force2.z, 0, 0, 0, 0, false, false, true)
						end

						return magnetent
					end)
					entities = {}
				end
			end
		end
	end
end)

-------------------------------------
-- VALKYIRE ROCKET
-------------------------------------

menu.toggle(weapon_options, menuname('Weapon', 'Valkyire Rocket'), {}, '', function(toggle)
	valkyire_rocket = toggle
	if valkyire_rocket then
		local rocket
		local cam
		local blip
		local init
		local draw_rect = function(x, y, z, w)
			GRAPHICS.DRAW_RECT(x, y, z, w, 255, 255, 255, 255)
		end

		while valkyire_rocket do
			if PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) and not init then
				init = true 
				sTime = cTime()
			elseif init then
				if not ENTITY.DOES_ENTITY_EXIST(rocket) then
					local weapon = WEAPON.GET_CURRENT_PED_WEAPON_ENTITY_INDEX(PLAYER.PLAYER_PED_ID())
					local offset = GET_OFFSET_FROM_CAM(10)
			
					rocket = OBJECT.CREATE_OBJECT_NO_OFFSET(joaat('w_lr_rpg_rocket'), offset.x, offset.y, offset.z, true, false, true)
					ENTITY.SET_ENTITY_INVINCIBLE(rocket, true)
					ENTITY._SET_ENTITY_CLEANUP_BY_ENGINE(rocket, true)
					NETWORK.SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER(NETWORK.OBJ_TO_NET(rocket), PLAYER.PLAYER_ID(), true)
					ENTITY.SET_ENTITY_LOAD_COLLISION_FLAG(rocket, true, 1)
					NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(NETWORK.OBJ_TO_NET(rocket), true);
					NETWORK.SET_NETWORK_ID_CAN_MIGRATE(NETWORK.OBJ_TO_NET(rocket), false)
					ENTITY.SET_ENTITY_RECORDS_COLLISIONS(rocket, true)
					ENTITY.SET_ENTITY_HAS_GRAVITY(rocket, false)
				
					CAM.DESTROY_ALL_CAMS(true)
					cam = CAM.CREATE_CAM("DEFAULT_SCRIPTED_CAMERA", true)
					CAM.SET_CAM_NEAR_CLIP(cam, 0.01)
					CAM.SET_CAM_NEAR_DOF(cam, 0.01)
					GRAPHICS.CLEAR_TIMECYCLE_MODIFIER()
					GRAPHICS.SET_TIMECYCLE_MODIFIER("CAMERA_secuirity")
					ATTACH_CAM_TO_ENTITY_WITH_FIXED_DIRECTION(cam, rocket, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1)
					CAM.SET_CAM_ACTIVE(cam, true)
					CAM.RENDER_SCRIPT_CAMS(true, false, 0, true, true, 0)

					PLAYER.DISABLE_PLAYER_FIRING(PLAYER.PLAYER_PED_ID(), true)
					ENTITY.FREEZE_ENTITY_POSITION(PLAYER.PLAYER_PED_ID(), true)
				else
					local rot = CAM.GET_GAMEPLAY_CAM_ROT(0)
					local direction = ROTATION_TO_DIRECTION(CAM.GET_GAMEPLAY_CAM_ROT(0))
					local coords = ENTITY.GET_ENTITY_COORDS(rocket)
					local groundZ = GET_GROUND_Z_FOR_3D_COORD(coords)
					local altitude = math.abs(coords.z - groundZ)
					local force = vect.mult(direction, 40)
					ENTITY.SET_ENTITY_ROTATION(rocket, rot.x, rot.y, rot.z, 0, 1)
					STREAMING.SET_FOCUS_POS_AND_VEL(coords.x, coords.y, coords.z, rot.z, rot.y, rot.z)
					
					ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(rocket, 1, force.x, force.y, force.z, false, false, false, false)

					HUD.HIDE_HUD_AND_RADAR_THIS_FRAME()
					PLAYER.DISABLE_PLAYER_FIRING(PLAYER.PLAYER_PED_ID(), true)
					ENTITY.FREEZE_ENTITY_POSITION(PLAYER.PLAYER_PED_ID(), true)
					HUD._HUD_WEAPON_WHEEL_IGNORE_SELECTION()
					
					draw_rect(0.5, 0.5 - 0.025, 0.050, 0.002)
					draw_rect(0.5, 0.5 + 0.025, 0.050, 0.002)
					draw_rect(0.5 - 0.025, 0.5, 0.002, 0.052)
					draw_rect(0.5 + 0.025, 0.5, 0.002, 0.052)
					draw_rect(0.5 + 0.05, 0.5, 0.050, 0.002)
					draw_rect(0.5 - 0.05, 0.5, 0.050, 0.002)
					draw_rect(0.5, 0.5 + 0.05, 0.002, 0.050)
					draw_rect(0.5, 0.5 - 0.05, 0.002, 0.050)
					
					local length = 0.5 - 0.5 * (cTime()-sTime) / 7000 -- timer length
					local perc = length / 0.5
					local color = get_blended_color(perc) -- timer color

					GRAPHICS.DRAW_RECT(0.25, 0.5, 0.03, 0.5, 255, 255, 255, 120)
					GRAPHICS.DRAW_RECT(0.25, 0.75 - length / 2, 0.03, length, color.r, color.g, color.b, color.a)

					if ENTITY.HAS_ENTITY_COLLIDED_WITH_ANYTHING(rocket) or length <= 0 then
						local impact_coord = ENTITY.GET_ENTITY_COORDS(rocket)
						FIRE.ADD_EXPLOSION(impact_coord.x, impact_coord.y, impact_coord.z, 32, 1.0, true, false, 0.4)
						entities.delete_by_handle(rocket)
						PLAYER.DISABLE_PLAYER_FIRING(PLAYER.PLAYER_PED_ID(), false)
						CAM.RENDER_SCRIPT_CAMS(false, false, 3000, true, false, 0)
						GRAPHICS.SET_TIMECYCLE_MODIFIER("DEFAULT")
						STREAMING.CLEAR_FOCUS()
						CAM.DESTROY_CAM(cam, 1)
						PLAYER.DISABLE_PLAYER_FIRING(PLAYER.PLAYER_PED_ID(), false)
						ENTITY.FREEZE_ENTITY_POSITION(PLAYER.PLAYER_PED_ID(), false)
					
						rocket = 0
						init = false
					end	
				end
			end
			wait()
		end
		
		if rocket and ENTITY.DOES_ENTITY_EXIST(rocket) then
			local impact_coord = ENTITY.GET_ENTITY_COORDS(rocket)
			FIRE.ADD_EXPLOSION(impact_coord.x, impact_coord.y, impact_coord.z, 32, 1.0, true, false, 0.4)
			entities.delete_by_handle(rocket)
			STREAMING.CLEAR_FOCUS()
			CAM.RENDER_SCRIPT_CAMS(false, false, 3000, true, false, 0)
			CAM.DESTROY_CAM(cam, 1)
			GRAPHICS.SET_TIMECYCLE_MODIFIER("DEFAULT")
			ENTITY.FREEZE_ENTITY_POSITION(PLAYER.PLAYER_PED_ID(), false)
			PLAYER.DISABLE_PLAYER_FIRING(PLAYER.PLAYER_PED_ID(), false)
			if HUD.DOES_BLIP_EXIST(blip) then
				util.remove_blip(blip)
			end
			HUD.UNLOCK_MINIMAP_ANGLE()
			HUD.UNLOCK_MINIMAP_POSITION()
		end
	end
end)

-------------------------------------
-- GUIDED MISSILE
-------------------------------------

menu.action(weapon_options, menuname('Weapon', 'Launch Guided Missile'), {}, '', function()
	if ufo.get_state() == -1 then 
		guided_missile.set_state(true)
	end
end)

-------------------------------------
-- SUPERPUNCH
-------------------------------------

menu.toggle_loop(weapon_options, menuname('Weapon', 'Superpunch'), {}, 'Push nearby entities away when performing melee animation', function ()
	local is_performing_action = PED.IS_PED_PERFORMING_MELEE_ACTION(PLAYER.PLAYER_PED_ID())
	if is_performing_action then
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
		FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, 29, 25.0, false, true, 0.0, true)
		AUDIO.PLAY_SOUND_FRONTEND(-1, "EMP_Blast", "DLC_HEISTS_BIOLAB_FINALE_SOUNDS", false)
	end
end)

---------------------
---------------------
-- VEHICLE
---------------------
---------------------

local vehicle_options = menu.list(menu.my_root(), menuname('Vehicle', 'Vehicle'), {}, '')

menu.divider(vehicle_options, menuname('Vehicle', 'Vehicle'))

-------------------------------------
-- AIRSTRIKE AIRCRAFT
-------------------------------------

local vehicle_weapon = menu.list(vehicle_options, menuname('Vehicle', 'Vehicle Weapons'), {'vehicleweapons'}, 'Allows you to add weapons to any vehicle.')

menu.divider(vehicle_weapon, menuname('Vehicle', 'Vehicle Weapons'))


local airstrikeplanes =  menu.toggle(vehicle_options, menuname('Vehicle', 'Airstrike Aircraft'), {'airstrikeplanes'}, 'Use any plane or helicopter to make airstrikes.', function(toggle)
	airstrike_plane = toggle
	if not airstrike_plane then return end
	for name, control in pairs(imputs) do
		if control[2] == config.controls.airstrikeaircraft then
			util.show_corner_help('Press ' .. ('~%s~'):format(name) .. ' to use Airstrike Aircraft')
			notification.help('Airstrike Aircraft can be used in planes or helicopters.')
			break
		end
	end
	while airstrike_plane do
		local control = config.controls.airstrikeaircraft
		if IS_PED_IN_ANY_AIRCRAFT(PLAYER.PLAYER_PED_ID()) and PAD.IS_CONTROL_PRESSED(2, control) then
			local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID())
			local pos = ENTITY.GET_ENTITY_COORDS(vehicle)
			local startTime = os.time() 
			create_tick_handler(function()
				wait(500)
				local groundz = GET_GROUND_Z_FOR_3D_COORD(pos)
				pos.x = pos.x + math.random(-3,3)
				pos.y = pos.y + math.random(-3,3)
				if ( pos.z - groundz > 10 ) then
					MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z - 3, pos.x, pos.y, groundz, 200, true, joaat("weapon_airstrike_rocket"), PLAYER.PLAYER_PED_ID(), true, false, 2500.0)
				end
				return ( os.time() - startTime <= 5 )
			end)
		end
		wait(200)
	end
end)

-------------------------------------
-- VEHICLE WEAPONS
-------------------------------------

function draw_line_from_vehicle(vehicle, startpoint)
	local minimum_ptr, maximum_ptr = alloc(), alloc()
	MISC.GET_MODEL_DIMENSIONS(ENTITY.GET_ENTITY_MODEL(vehicle), minimum_ptr, maximum_ptr)
	local minimum = memory.read_vector3(minimum_ptr); memory.free(minimum_ptr)
	local maximum = memory.read_vector3(maximum_ptr); memory.free(maximum_ptr)
	local startcoords = 
	{
		fl = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, minimum.x, maximum.y, 0), --FRONT & LEFT
		fr = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, maximum.x, maximum.y, 0)  --FRONT & RIGHT
	}	
	local endcoords = 
	{
		fl = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, minimum.x, maximum.y + 25, 0),
		fr = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, maximum.x, maximum.y + 25, 0)
	}
	local coord1 = startcoords[ startpoint ]
	local coord2 = endcoords[ startpoint ]
	GRAPHICS.DRAW_LINE(coord1.x, coord1.y, coord1.z, coord2.x, coord2.y, coord2.z, 255, 0, 0, 150)
end


function shoot_bullet_from_vehicle(vehicle, weaponName, startpoint)
	local weaponHash = joaat(weaponName)
	local minimum_ptr, maximum_ptr = alloc(), alloc()
	if not WEAPON.HAS_WEAPON_ASSET_LOADED(weaponHash) then
		WEAPON.REQUEST_WEAPON_ASSET(weaponHash, 31, 26)
		while not WEAPON.HAS_WEAPON_ASSET_LOADED(weaponHash) do
			wait()
		end
	end
	MISC.GET_MODEL_DIMENSIONS(ENTITY.GET_ENTITY_MODEL(vehicle), minimum_ptr, maximum_ptr)
	local minimum = memory.read_vector3(minimum_ptr); memory.free(minimum_ptr)
	local maximum = memory.read_vector3(maximum_ptr); memory.free(maximum_ptr)

	local startcoords = 
	{
		fl = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, minimum.x, maximum.y + 0.25, 0.3), 	--FRONT & LEFT
		fr = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, maximum.x, maximum.y + 0.25, 0.3), 	--FRONT & RIGHT
		bl = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, minimum.x, minimum.y, 0.3), 		--BACK & LEFT
		br = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, maximum.x, minimum.y, 0.3) 			--BACK & RIGHT
	}	
	local endcoords = 
	{
		fl = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, minimum.x, maximum.y + 50, 0.0),
		fr = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, maximum.x, maximum.y + 50, 0.0),
		bl = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, minimum.x, minimum.y - 50, 0.0),
		br = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, maximum.x, minimum.y - 50, 0.0)
	}
	local coord1 = startcoords[ startpoint ]
	local coord2 = endcoords[ startpoint ]
	MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(coord1.x, coord1.y, coord1.z, coord2.x, coord2.y, coord2.z, 200, true, weaponHash, PLAYER.PLAYER_PED_ID(), true, false, 2000.0)
end

-------------------------------------
-- VEHICLE LASER
-------------------------------------

menu.toggle(vehicle_weapon, menuname('Vehicle - Vehicle Weapons', 'Vehicle Lasers'), {'vehiclelasers'},'', function(toggle)
	vehicle_laser = toggle
	if vehicle_laser and airstrike_plane then
		menu.trigger_command(airstrikeplanes, 'off')
	end
	while vehicle_laser do
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(PLAYER.PLAYER_ID())
		if vehicle ~= NULL then
			draw_line_from_vehicle(vehicle, 'fl')
			draw_line_from_vehicle(vehicle, 'fr')
		end
		wait()
	end
end)

-------------------------------------
-- VEHICLE WEAPONS
-------------------------------------

local selected = 1

local toggle_veh_weapons = menu.toggle(vehicle_weapon, menuname('Vehicle - Vehicle Weapons', 'Vehicle Weapons') .. ': ' .. HUD._GET_LABEL_TEXT("WT_V_SPACERKT"), {}, '', function(toggle)
	veh_rockets = toggle
	if not veh_rockets then return end
	for name, control in pairs(imputs) do
		if control[2] == config.controls.vehicleweapons then
			util.show_corner_help('Press ' .. ('~%s~'):format(name) .. ' to use Vehicle Weapons')
			break
		end
	end
	while veh_rockets do
		local control = config.controls.vehicleweapons
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(PLAYER.PLAYER_ID())
		if vehicle ~= NULL and veh_weapons[ selected ][ 3 ](2, control) then
			if not PAD.IS_CONTROL_PRESSED(0, 79) then
				shoot_bullet_from_vehicle(vehicle, veh_weapons[ selected ][ 1 ], 'fl')
				shoot_bullet_from_vehicle(vehicle, veh_weapons[ selected ][ 1 ], 'fr')
			else
				shoot_bullet_from_vehicle(vehicle, veh_weapons[ selected ][ 1 ], 'bl')
				shoot_bullet_from_vehicle(vehicle, veh_weapons[ selected ][ 1 ], 'br')
			end
		end
		wait()
	end
end)

local vehicle_weapon_list = menu.list(vehicle_weapon, menuname('Vehicle - Vehicle Weapons', 'Set Vehicle Weapon'))
menu.divider(vehicle_weapon_list, HUD._GET_LABEL_TEXT("PM_WEAPONS"))

for i, table in pairs_by_keys(veh_weapons) do
	local strg = HUD._GET_LABEL_TEXT( table[2] )
	menu.action(vehicle_weapon_list, strg, {strg}, '', function()
		selected = i
		menu.set_menu_name(toggle_veh_weapons, menuname('Vehicle - Vehicle Weapons', 'Set Vehicle Weapon') .. ': ' .. strg)
		if not veh_rocket then menu.trigger_command(toggle_veh_weapons, 'on') end
		menu.focus(vehicle_weapon_list)
	end)
end

-------------------------------------
-- VEHICLE EDITOR
-------------------------------------

local handling_editor = menu.list(vehicle_options, menuname('Vehicle', 'Handling Editor'), {}, '', function()
	handling.display_handling = true
end, function()
	handling.display_handling = false
	if handling.cursor_mode then
		handling.cursor_mode = false
		UI.toggle_cursor_mode(false)
	end
end)


handling = {
	cursor_mode = false,
	window_x = 0.02,
	window_y = 0.08,
	inviewport = {},
	display_handling = false,
	flying = {},
	boat = {},
	offsets = 
	{
		-- handling
		{    
			{'Mass', 0xC},
			{'Initial Drag Coefficient', 0x10},
			{'Down Force Modifier', 0x14},
			{'Centre Of Mass Offset X', 0x20},
			{'Centre Of Mass Offset Y', 0x24},
			{'Centre Of Mass Offset Z', 0x28},
			{'Inercia Multiplier X', 0x30},
			{'Inercia Multiplier Y', 0x34},
			{'Inercia Multiplier Z', 0x38},
			{'Percent Submerged', 0x40},
			{'Submerged Ratio', 0x44},
			{'Drive Bias Front', 0x48},
			{'Acceleration', 0x4C},
			{'Drive Inertia', 0x54},
			{'Up Shift', 0x58},
			{'Down Shift', 0x5C},
			{'Initial Drive Force', 0x60},
			{'Drive Max Flat Velocity', 0x64},
			{'Initial Drive Max Flat Velocity', 0x68},
			{'Brake Force', 0x6C},
			{'Brake Bias Front', 0x74},
			{'Brake Bias Rear', 0x78},
			{'Hand Brake Force', 0x7C},
			{'Steering Lock', 0x80},
			{'Steering Lock Ratio', 0x84},
			{'Traction Curve Max', 0x88},
			{'Traction Curve Max Ratio', 0x8C},
			{'Traction Curve Min', 0x90},
			{'Traction Curve Min Ratio', 0x94},
			{'Traction Curve Lateral', 0x98},
			{'Traction Curve Lateral Ratio', 0x9C},
			{'Traction Spring Delta Max', 0xA0},
			{'Traction Spring Delta Max Ratio', 0xA4},
			{'Low Speed Traction Multiplier', 0xA8},
			{'Camber Stiffness', 0xAC},
			{'Traction Bias Front', 0xB0},
			{'Traction Bias Rear', 0xB4},
			{'Traction Loss Multiplier', 0xB8},
			{'Suspension Force', 0xBC},
			{'Suspension Comp Damp', 0xC0},
			{'Suspension Rebound Damp', 0xC4},
			{'Suspension Lower Limit', 0xC8},
			{'Suspension Upper Limit', 0xCC},
			{'Suspension Raise', 0xD0},
			{'Suspension Bias Front', 0xD4},
			{'Suspension Bias Rear', 0xD8},
			{'Anti-Roll Bar Force', 0xDC},
			{'Anti-Roll Bar Bias Front', 0xE0},
			{'Anti-Roll Bar Bias Rear', 0xE4},
			{'Roll Centre Height Front', 0xE8},
			--{'Roll Centre Height Front', 0xEC},
			{'Collision Damage Multiplier', 0xF0},
			{'Weapon Damage Multiplier', 0xF4},
			--{'Weapon Damage Multiplier', 0xF8},
			{'Engine Damage Multiplier', 0xFC},
			{'Petrol Tank Volume', 0x100},
			{'Oil Volume', 0x104},
			{'Seat Offset Distance X', 0x10C},
			{'Seat Offset Distance Y', 0x110},
			{'Seat Offset Distance Z', 0x114},
			{'Increase Speed', 0x120}
		},
		-- flying
		{
			{'Thrust', 0x338},
			{'Thrust Fall Off', 0x33C},
			{'Thrust Vectoring', 0x340},
			{'Yaw Mult', 0x34C},
			{'Yaw Stabilise', 0x350},
			{'Side Slip Mult', 0x354},
			{'Roll Mult', 0x35C},
			{'Roll Stabilise', 0x360},
			{'Pitch Mult', 0x368},
			{'Pitch Stabilise', 0x36C},
			{'Form Lift Mult', 0x374},
			{'Attack Lift Mult', 0x378},
			{'Attack Dive Mult', 0x37C},
			{'Gear Down Drag V', 0x380},
			{'Gear Down Lift Mult', 0x384},
			{'Wind Mult', 0x388},
			{'Move Res', 0x38C},
			{'Turn Res X', 0x390},
			{'Turn Res Y', 0x394},
			{'Turn Res Z', 0x398},
			{'Speed Res X', 0x3A0},
			{'Speed Res Y', 0x3A4},
			{'Speed Res Z', 0x3A8},
			{'Gear Door Front Open', 0x3B0},
			{'Gear Door Rear Open', 0x3B4},
			{'Gear Door Rear Open 2', 0x3B8},
			{'Gear Door Rear M Open', 0x3BC},
			{'Turbulence Magnitude Max', 0x3C0},
			{'Turbulence Force Mult', 0x3C4},
			{'Turbulence Roll Torque Mult', 0x3C8},
			{'Turbulence Pitch Torque Mult', 0x3CC},
			{'Body Damage Control Effect', 0x3D0},
			{'Input Sensitivity For Difficulty', 0x3D4},
			{'On Ground Yaw Boost Speed Peak', 0x3D8},
			{'On Ground Yaw Boost Speed Cap', 0x3DC},
			{'Engine Off Glide Mult', 0x3E0},
			{'Afterburner Effect Radius', 0x3E4},
			{'Afterburner Effect Distance', 0x3E8},
			{'Afterburner Effect Force Mult', 0x3EC},
			{'Submerge Level To Pull Heli Underwater', 0x3F0},
			{'Extra Lift With Roll', 0x3F4},
		},
		-- boat
		{
    		{'Box Front Mult', 0x338},
    		{'Box Rear Mult', 0x33C},
    		{'Box Side Mult', 0x340},
    		{'Sample Top', 0x344},
    		{'Sample Bottom', 0x348},
    		{'Sample Bottom Test Correction', 0x34C},
    		{'Aquaplane Force', 0x350},
    		{'Aquaplane Push Water Mult', 0x354},
    		{'Aquaplane Push Water Cap', 0x358},
    		{'Aquaplane Push Water Apply', 0x35C},
    		{'Rudder Force', 0x360},
    		{'Rudder Offset Submerge', 0x364},
    		{'Rudder Offset Force', 0x368},
    		{'Rudder Offset Force Z Mult', 0x36C},
    		{'Wave Audio Mult', 0x370},
    		{'Look L R Cam Height', 0x3A0},
    		{'Drag Coefficient', 0x3A4},
    		{'Keel Sphere Size', 0x3A8},
    		{'Prop Radius', 0x3AC},
    		{'Low Lod Ang Offset', 0x3B0},
    		{'Low Lod Draught Offset', 0x3B4},
    		{'Impeller Offset', 0x3B8},
    		{'Impeller Force Mult', 0x3BC},
    		{'Dinghy Sphere Buoy Const', 0x3C0},
    		{'Prow Raise Mult', 0x3C4},
    		{'Deep Water Sample Buotancy Mult', 0x3C8},
    		{'Transmission Multiplier', 0x3CC},
    		{'Traction Multiplier', 0x3D0}
		}
	}
}


function handling:load()
	local file = wiridir ..'\\handling\\' .. self.vehicle_name .. '.json'
	if not PED.IS_PED_IN_ANY_VEHICLE(PLAYER.PLAYER_PED_ID(), false) then 
		return
	end
	if not filesystem.exists(file) then 
		return notification.normal('File not found', NOTIFICATION_RED)
	end
	
	file = io.open(file, 'r')
	local content = file:read('a')
	file:close()
	if string.len(content) > 0 then
		local parsed = json.parse(content, false)
		local sethandling = function(offsets, s)
			for _, a in ipairs(offsets) do
				local addr = address_from_pointer_chain(worldptr, {0x08, 0xD30, 0x938, a[2]})
				if addr ~= NULL then
					memory.write_float(addr, parsed[s][a[1]])
				else notification.normal('Got a null address while trying to write ' .. a[2], NOTIFICATION_RED) end
			end
		end
		sethandling(self.offsets[1], 'handling')
		if parsed.flying ~= nil then sethandling(self.offsets[2], 'flying') end
		if parsed.boat ~= nil then sethandling(self.offsets[3], 'boat') end
		notification.normal(first_upper(self.vehicle_name) .. ' handling data loaded')
	end
end


function handling:save()
	if not PED.IS_PED_IN_ANY_VEHICLE(PLAYER.PLAYER_PED_ID(), false) then 
		return
	end
	local table = {}
	local model = GET_USER_VEHICLE_MODEL(true)
	local file = wiridir ..'\\handling\\' .. self.vehicle_name .. '.json'
	local gethandling = function(offsets)
		local s = {}
		for _, a in ipairs(offsets) do
			local addr = address_from_pointer_chain(worldptr, {0x08, 0xD30, 0x938, a[2]})
			if addr ~= NULL then
				local value = memory.read_float(addr)
				s[ a[1] ] = value
			else notification.normal('Got a null address while trying to write ' .. a[2], NOTIFICATION_RED) end
		end
		return s
	end
	table.handling = gethandling(self.offsets[1])
	if IS_THIS_MODEL_AN_AIRCRAFT(model) then
		table.flying = gethandling(self.offsets[2])
	end
	if VEHICLE.IS_THIS_MODEL_A_BOAT(model) then
		table.boat = gethandling(self.offsets[3])
	end
	file = io.open(file, 'w')
	file:write(json.stringify(table, nil, 4))
	file:close()
	notification.normal(first_upper(self.vehicle_name) .. ' handling data saved')
end


function handling:create_actions(offsets, s)
	local t = {}
	table.insert(t, menu.divider(handling_editor, first_upper(s)))
	table.sort(offsets, function(a, b) return a[2] < b[2] end)
	
	for _, a in ipairs(offsets) do
		local action = menu.action(handling_editor, a[1], {}, '', function()
			local addr = address_from_pointer_chain(worldptr, {0x08, 0xD30, 0x938, a[2]})
			if addr == NULL then return end
			local value = round(memory.read_float(addr), 4)
			local nvalue = DISPLAY_ONSCREEN_KEYBOARD("BS_WB_VAL", 7, value)
			if nvalue == '' then return end
			if tonumber(nvalue) == nil then
				return notification.normal('Invalid input', NOTIFICATION_RED)
			elseif tonumber(nvalue) ~= value then
				memory.write_float(addr, tonumber(nvalue))
			end 
		end)
		menu.on_tick_in_viewport(action, function()
			self.inviewport[s] = self.inviewport[s] or {}
			if not includes(self.inviewport[s], a[1]) then
			   table.insert(self.inviewport[s], a)
			end
		end)
		  
		menu.on_focus(action, function()
			self.onfocus = a[1]
		end)
		
		table.insert(t, action)
	end
	return t
end

handling:create_actions(handling.offsets[1], 'handling')

-------------------------------------
-- VEHICLE DOORS
-------------------------------------

local doors_list = menu.list(vehicle_options, menuname('Vehicle', 'Vehicle Doors'), {}, '')

local doors = {
	'Driver Door',
	'Passenger Door',
	'Rear Left',
	'Rear Right',
	'Hood',
	'Trunk'
}

menu.divider(doors_list, menuname('Vehicle', 'Vehicle Doors'))

for i, door in ipairs(doors) do
	menu.toggle(doors_list, menuname('Vehicle - Vehicle Doors', door), {}, '', function(toggle)
		local vehicle = entities.get_user_vehicle_as_handle()
		if toggle then
			VEHICLE.SET_VEHICLE_DOOR_OPEN(vehicle, (i-1), false, false)
		else
			VEHICLE.SET_VEHICLE_DOOR_SHUT(vehicle, (i-1), false)
		end
	end)
end

menu.toggle(doors_list, menuname('Vehicle - Vehicle Doors', 'All'), {}, '', function(toggle)
	local vehicle = entities.get_user_vehicle_as_handle()
	for i, door in ipairs(doors) do
		if toggle then
			VEHICLE.SET_VEHICLE_DOOR_OPEN(vehicle, (i-1), false, false)
		else
			VEHICLE.SET_VEHICLE_DOOR_SHUT(vehicle, (i-1), false)
		end
	end
end)

-------------------------------------
-- UFO
-------------------------------------

menu.action(vehicle_options, menuname('Vehicle', 'UFO'), {'ufo'}, 'Drive an UFO, use its tractor beam and cannon.', function(toggle)
	if guided_missile.get_state() == -1 then
		ufo.set_state(true)
	end
end)

-------------------------------------
-- VEHICLE INSTANT LOCK ON
-------------------------------------

menu.toggle(vehicle_options, menuname('Vehicle', 'Vehicle Instant Lock-On'), {}, '', function(toggle)
	vehlock = toggle
	local default = {}
	local offsets = {0x08, 0x10D8, 0x70, 0x60, 0x178}

	while vehlock do
		wait()
		local ptr = alloc()
		local addr = address_from_pointer_chain(worldptr, offsets)
		if addr ~= NULL then
			local value = memory.read_float(addr)
			if value ~= 0.0 then
				table.insert(default, {addr, value})
				memory.write_float(addr, 0.0)
			end
		end
	end

	if #default > 0 then
		for _, data in ipairs(default) do
			memory.write_float(table.unpack(data))
		end
	end
end)

-------------------------------------
-- VEHICLE EFFECTS
-------------------------------------

local effects = {
	-- Clown Appears
	{
		name 	= "scr_clown_appears",
		asset	= "scr_rcbarry2",
		scale	= 0.3,
		speed	= 500
	},
	-- Alien Impact
	{
		name 	= "scr_alien_impact_bul",
		asset	= "scr_rcbarry1",
		scale	= 1.0,
		speed	= 50
	},
	-- Electic Fire
	{
		name 	= "ent_dst_elec_fire_sp",
		asset 	= "core",
		scale 	= 0.8,
		speed	= 25
	}
}
local wheel_bones = {"wheel_lf", "wheel_lr", "wheel_rf", "wheel_rr"}
local items = {'Disable', 'Clown Appears', 'Alien Impact', 'Electic Fire'}
local current_effect
local vehicle_effect = menu.list(vehicle_options, menuname('Vehicle Effects', 'Vehicle Effects') .. ': ' .. menuname('Vehicle Effects', items[1]) )

for i, item in ipairs(items) do
	menu.action(vehicle_effect, menuname('Vehicle Effects', item), {}, '', function()
		current_effect = i
		menu.set_menu_name(vehicle_effect, menuname('Vehicle Effects', 'Vehicle Effects') .. ': ' .. menuname('Vehicle Effects', item) )
		menu.focus(vehicle_effect)
	end)
end

create_tick_handler(function()
	if current_effect == 1 then
		return true
	elseif current_effect ~= nil then
		local effect = effects[ current_effect - 1 ]
		local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), true)
		if vehicle == NULL then return true end
		REQUEST_PTFX_ASSET(effect.asset)
		for k, bone in pairs(wheel_bones) do
			GRAPHICS.USE_PARTICLE_FX_ASSET(effect.asset)
			GRAPHICS._START_NETWORKED_PARTICLE_FX_NON_LOOPED_ON_ENTITY_BONE(
				effect.name,
				vehicle,
				0.0, 			--offsetX
				0.0, 			--offsetY
				0.0, 			--offsetZ
				0.0, 			--rotX
				0.0, 			--rotY
				0.0, 			--rotZ
				ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(vehicle, bone),
				effect.scale, 	--scale
				false, false, false
			)
		end
		wait(effect.speed)
	end
	return true
end)

-------------------------------------
-- AUTOPILOT
-------------------------------------

local driving_style_flag = {
	['Stop Before Vehicles'] 	= 1,
	['Stop Before Peds'] 		= 2,
	['Avoid Vehicles'] 			= 4,
	['Avoid Empty Vehicles'] 	= 8,
	['Avoid Peds'] 				= 16,
	['Avoid Objects']			= 32,
	['Stop At Traffic Lights'] 	= 128,
	['Reverse Only'] 			= 1024,
	['Take Shortest Path'] 		= 262144,
	['Ignore Roads'] 			= 4194304,
	['Ignore All Pathing'] 		= 16777216
}

local drivingstyle = 786988
local presets = {
	{
		'Normal', 
		'Stop before vehicles & peds, avoid empty vehicles & objects and stop at traffic lights.',
		786603
	},
	{
	  	'Ignore Lights',
	  	'Stop before vehicles, avoid vehicles & objects.', 
	  	2883621
	},
	{
	  	'Avoid Traffic',
	  	'Avoid vehicles & objects.', 
	  	786468
	},
	{
	  	'Rushed',
	  	'Stop before vehicles, avoid vehicles, avoid objects', 
	  	1074528293
	},
	{
	  	'Default',
	  	'Avoid vehicles, empty vehicles & objects, allow going wrong way and take shortest path', 
	  	786988
	}
}
local selected_flags = {}
local list_autopilot = menu.list(vehicle_options, menuname('Vehicle - Autopilot', 'Autopilot') )

menu.divider(list_autopilot, menuname('Vehicle - Autopilot', 'Autopilot') )


menu.toggle(list_autopilot, menuname('Vehicle - Autopilot', 'Autopilot'), {'autopilot'}, '', function(toggle)
	autopilot = toggle
	if autopilot then
		local lastblip
		local lastdrivstyle
		local lastspeed
		local drive_to_waypoint =  function()
			local vehicle = entities.get_user_vehicle_as_handle()
			if vehicle == NULL then return end
			local ptr = alloc()
			local coord = GET_WAYPOINT_COORDS()
			if not coord then
				notification.normal('Set a waypoint to start driving')
			else
				PED.SET_DRIVER_ABILITY(PLAYER.PLAYER_PED_ID(), 0.5);
				TASK.OPEN_SEQUENCE_TASK(ptr)
				TASK.TASK_VEHICLE_DRIVE_TO_COORD_LONGRANGE(0, vehicle, coord.x, coord.y, coord.z, autopilot_speed or 25.0, drivingstyle, 45.0);
				TASK.TASK_VEHICLE_PARK(0, vehicle, coord.x, coord.y, coord.z, ENTITY.GET_ENTITY_HEADING(vehicle), 7, 60.0, true);
				TASK.CLOSE_SEQUENCE_TASK(memory.read_int(ptr));
				TASK.TASK_PERFORM_SEQUENCE(PLAYER.PLAYER_PED_ID(), memory.read_int(ptr))
				TASK.CLEAR_SEQUENCE_TASK(ptr)

				lastspeed = autopilot_speed or 25.0
				lastblip = HUD.GET_FIRST_BLIP_INFO_ID(8)
				lastdrivstyle = drivingstyle
				return coord
			end
		end
		local lastcoord = drive_to_waypoint()
		while autopilot do
			wait()
			local blip = HUD.GET_FIRST_BLIP_INFO_ID(8)
			if drivingstyle ~= lastdrivstyle  then
				lastcoord = drive_to_waypoint()
				lastdrivstyle = drivingstyle
			end
			if blip ~= lastblip then
				lastcoord = drive_to_waypoint()
				lastblip = blip
			end
			if lastspeed ~= autopilot_speed then
				lastcoord = drive_to_waypoint()
				lastspeed = autopilot_speed
			end
		end
	else
		TASK.CLEAR_PED_TASKS(PLAYER.PLAYER_PED_ID())
	end
end)

local menu_driving_style = menu.list(list_autopilot, menuname('Vehicle - Autopilot', 'Driving Style'), {}, '')

menu.divider(menu_driving_style, menuname('Vehicle - Autopilot', 'Driving Style'))
menu.divider(menu_driving_style, menuname('Autopilot - Driving Style', 'Presets'))

for k, style in pairs(presets) do
	menu.action(menu_driving_style, menuname('Autopilot - Driving Style', style[ 1 ]), {}, style[ 2 ], function()
		drivingstyle = style[ 3 ]
	end)
end

menu.divider(menu_driving_style, menuname('Autopilot - Driving Style', 'Custom'))

for name, flag in pairs(driving_style_flag) do
	menu.toggle(menu_driving_style, menuname('Autopilot - Driving Style', name), {}, '', function(toggle) 
		local toggle = toggle
		if toggle then
			table.insert(selected_flags, flag)
		else selected_flags[ name ] = nil end
	end)
end

menu.action(menu_driving_style, menuname('Autopilot - Driving Style', 'Set Custom Driving Style'), {}, '', function()
	local style = 0
	for k, v in pairs(selected_flags) do
		style = style + v
	end
	drivingstyle = style
end)

menu.slider(list_autopilot, menuname('Vehicle - Autopilot', 'Speed'), {'autopilotspeed'}, '', 10, 200, 25, 1, function(speed)
	autopilot_speed = speed
end)

-------------------------------------
-- ENGINE ALWAYS ON
-------------------------------------

menu.toggle_loop(vehicle_options, menuname('Vehicle', 'Engine Always On'), {'alwayson'}, '', function()
	local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
	if ENTITY.DOES_ENTITY_EXIST(vehicle) then
		VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle, true, true, true)
		VEHICLE.SET_VEHICLE_LIGHTS(vehicle, 0)
		VEHICLE._SET_VEHICLE_LIGHTS_MODE(vehicle, 2)
	end
end)

---------------------
---------------------
-- BODYGUARD
---------------------
---------------------

local bodyguards_options = menu.list(menu.my_root(), menuname('Bodyguard Menu', 'Bodyguard Menu'), {'bodyguardmenu'}, '')

menu.divider(bodyguards_options, menuname('Bodyguard Menu', 'Bodyguard Menu'))

local bodyguard = {
	godmode 		= false,
	ignoreplayers 	= false,
	spawned 		= {},
	backup_godmode 	= false,
	formation 		= 0
}

menu.action(bodyguards_options, menuname('Bodyguard Menu', 'Spawn Bodyguard (7 Max)'), {'spawnbodyguard'}, '', function()
	local user_ped = PLAYER.PLAYER_PED_ID()
	local pos = ENTITY.GET_ENTITY_COORDS(user_ped)
	local ptr1 = alloc(32)
	local ptr2 = alloc(32)
	local groupId = PED.GET_PED_GROUP_INDEX(user_ped); PED.GET_GROUP_SIZE(groupId, ptr2, ptr1)
	local groupSize = memory.read_int(ptr1); memory.free(ptr1); memory.free(ptr2)
	if groupSize == 7 then
		return notification.normal('You reached the max number of bodyguards', NOTIFICATION_RED)
	end
	pos.x = pos.x + math.random(-3, 3)
	pos.y = pos.y + math.random(-3, 3)
	pos.z = pos.z - 1.0
	local model = bodyguard.model or random(peds)
	local weapon = bodyguard.weapon or random(weapons)
	local m_ped_hash = joaat(model)
	
	REQUEST_MODELS(m_ped_hash)
	local ped = entities.create_ped(29, m_ped_hash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
	insert_once(bodyguard.spawned, model)
	NETWORK.SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER(NETWORK.PED_TO_NET(ped), PLAYER.PLAYER_ID(), true)
	NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(NETWORK.PED_TO_NET(ped), true)
	WEAPON.GIVE_WEAPON_TO_PED(ped, joaat(weapon), -1, false, true)
	WEAPON.SET_CURRENT_PED_WEAPON(ped, joaat(weapon), false)
	PED.SET_PED_HIGHLY_PERCEPTIVE(ped, true)
	PED.SET_PED_COMBAT_RANGE(ped, 2)
	PED.SET_PED_CONFIG_FLAG(ped, 208, true)
	PED.SET_PED_SEEING_RANGE(ped, 100.0)
	ENTITY.SET_ENTITY_INVINCIBLE(ped, bodyguard.godmode)
	PED.SET_PED_AS_GROUP_MEMBER(ped, groupId)
	PED.SET_PED_NEVER_LEAVES_GROUP(ped, true)
	PED.SET_GROUP_FORMATION(groupId, bodyguard.formation)
	PED.SET_GROUP_FORMATION_SPACING(groupId, 1.0, 0.9, 3.0)
	SET_ENT_FACE_ENT(ped, user_ped)
	
	if bodyguard.ignoreplayers then
		local relHash = PED.GET_PED_RELATIONSHIP_GROUP_HASH(PLAYER.PLAYER_PED_ID())
		PED.SET_PED_RELATIONSHIP_GROUP_HASH(ped, relHash)
	else 
		relationship:friendly(ped) 
	end
end)

local bodyguards_model_list = menu.list(bodyguards_options, menuname('Bodyguard Menu', 'Set Model') .. ': ' .. HUD._GET_LABEL_TEXT("SR_GUN_RANDOM"), {}, '')

menu.divider(bodyguards_model_list, 'Bodyguard Model List')

menu.action(bodyguards_model_list, HUD._GET_LABEL_TEXT("SR_GUN_RANDOM"), {}, '', function()
	bodyguard.model = nil
	menu.set_menu_name(bodyguards_model_list, menuname('Bodyguard Menu', 'Set Model') .. ': ' .. HUD._GET_LABEL_TEXT("SR_GUN_RANDOM"))
	menu.focus(bodyguards_model_list)
end)

for k, model in pairs_by_keys(peds) do
	menu.action(bodyguards_model_list, menuname('Ped Models', k), {}, '', function()
		bodyguard.model = model
		menu.set_menu_name(bodyguards_model_list, menuname('Bodyguard Menu', 'Set Model') .. ': ' .. k)
		menu.focus(bodyguards_model_list)
	end)
end

menu.action(bodyguards_options, menuname('Bodyguard Menu', 'Clone Player (Bodyguard)'), {'clonebodyguard'}, '', function()
	local user_ped = PLAYER.PLAYER_PED_ID()
	local ptr1 = alloc(32)
	local ptr2 = alloc(32)
	local pos = ENTITY.GET_ENTITY_COORDS(user_ped)
	local groupId = PLAYER.GET_PLAYER_GROUP(players.user()); PED.GET_GROUP_SIZE(groupId, ptr2, ptr1)
	local groupSize = memory.read_int(ptr1); memory.free(ptr1); memory.free(ptr2)
	if groupSize >= 7 then
		return notification.normal('You reached the max number of bodyguards', NOTIFICATION_RED)
	end
	pos.x = pos.x + math.random(-3,3)
	pos.y = pos.y + math.random(-3,3)
	pos.z = pos.z - 1.0
	local weapon = bodyguard.weapon or random(weapons)
	
	local clone = PED.CLONE_PED(user_ped, 1, 1, 1)
	insert_once(bodyguard.spawned, "mp_f_freemode_01")
	insert_once(bodyguard.spawned, "mp_m_freemode_01")
	WEAPON.GIVE_WEAPON_TO_PED(clone, joaat(weapon), -1, false, true)
	WEAPON.SET_CURRENT_PED_WEAPON(clone, joaat(weapon), false)
	PED.SET_PED_HIGHLY_PERCEPTIVE(clone, true)
	PED.SET_PED_COMBAT_RANGE(clone, 2)
	PED.SET_PED_CONFIG_FLAG(clone, 208, true)
	PED.SET_PED_SEEING_RANGE(clone, 100.0)
	ENTITY.SET_ENTITY_COORDS(clone, pos.x, pos.y, pos.z)
	ENTITY.SET_ENTITY_INVINCIBLE(clone, bodyguard.godmode)
	PED.SET_PED_AS_GROUP_MEMBER(clone, groupId)
	PED.SET_PED_NEVER_LEAVES_GROUP(clone, true)
	PED.SET_GROUP_FORMATION(groupId, 0)
	PED.SET_GROUP_FORMATION_SPACING(groupId, 1.0, 0.9, 3.0)
	SET_ENT_FACE_ENT(clone, user_ped)
	
	if bodyguard.ignoreplayers then
		local relHash = PED.GET_PED_RELATIONSHIP_GROUP_HASH(PLAYER.PLAYER_PED_ID())
		PED.SET_PED_RELATIONSHIP_GROUP_HASH(clone, relHash)
	else
		relationship:friendly(clone) 
	end
end)

-- bodyguards weapons
local bodyguards_weapon_list = menu.list(bodyguards_options, menuname('Bodyguard Menu', 'Set Weapon') .. ': ' .. HUD._GET_LABEL_TEXT("SR_GUN_RANDOM"))
menu.divider(bodyguards_weapon_list, HUD._GET_LABEL_TEXT("PM_WEAPONS"))

local bodyguards_melee_list = menu.list(bodyguards_weapon_list, HUD._GET_LABEL_TEXT("VAULT_WMENUI_8"))
menu.divider(bodyguards_melee_list, HUD._GET_LABEL_TEXT("VAULT_WMENUI_8"))

for label, weapon in pairs_by_keys(melee_weapons) do
	local strg = HUD._GET_LABEL_TEXT(label)
	menu.action(bodyguards_melee_list, strg, {}, '', function()
		bodyguard.weapon = weapon
		menu.set_menu_name(bodyguards_weapon_list, menuname('Bodyguard Menu', 'Set Weapon') .. ': ' .. strg)
		menu.focus(bodyguards_weapon_list)
	end)
end

menu.action(bodyguards_weapon_list, HUD._GET_LABEL_TEXT("SR_GUN_RANDOM"), {}, '', function()
	bodyguard.weapon = nil
	menu.set_menu_name(bodyguards_weapon_list, menuname('Bodyguard Menu', 'Set Weapon') .. ': ' .. HUD._GET_LABEL_TEXT("SR_GUN_RANDOM"))
	menu.focus(bodyguards_weapon_list)
end)

for label, weapon in pairs_by_keys(weapons) do
	local strg = HUD._GET_LABEL_TEXT(label)
	menu.action(bodyguards_weapon_list, strg, {}, '', function()
		bodyguard.weapon = weapon
		menu.set_menu_name(bodyguards_weapon_list, menuname('Bodyguard Menu', 'Set Weapon') .. ': ' .. strg)
		menu.focus(bodyguards_weapon_list)
	end)
end

menu.toggle(bodyguards_options, menuname('Bodyguard Menu', 'Invincible Bodyguard'), {'bodyguardsgodmode'}, '', function(toggle)
	bodyguard.godmode = toggle
end)

menu.toggle(bodyguards_options, menuname('Bodyguard Menu', 'Ignore Players'), {}, '', function(toggle)
	bodyguard.ignoreplayers = toggle
end)

local formation = menu.list(bodyguards_options, menuname('Bodyguard Menu', 'Group Formation') .. ': ' .. menuname('Bodyguard Menu - Group Formation', formations[1][1] ), {}, '')

for _, value in ipairs(formations) do
	menu.action(formation, menuname('Bodyguard Menu - Group Formation', value[1]) , {}, '', function()
		bodyguard.formation = value[2]
		local group = PED.GET_PED_GROUP_INDEX(PLAYER.PLAYER_PED_ID())
		PED.SET_GROUP_FORMATION(group, bodyguard.formation)
		menu.set_menu_name(formation, menuname('Bodyguard Menu', 'Group Formation') .. ': ' .. menuname('Bodyguard Menu - Group Formation', value[1]) )
		menu.focus(formation)
	end)
end

menu.action(bodyguards_options, menuname('Bodyguard Menu', 'Delete Bodyguards'), {}, '', function()
	local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
	local pos = ENTITY.GET_ENTITY_COORDS(p, false)
	for _, model in ipairs(bodyguard.spawned) do
		DELETE_PEDS(model)
	end
	bodyguard.spawned = {}
end)

-------------------------------------
-- BACKUP HELICOPTER
-------------------------------------

local backup_heli_option = menu.list(bodyguards_options,  menuname('Bodyguard Menu', 'Backup Helicopter'))

menu.divider(backup_heli_option, menuname('Bodyguard Menu', 'Backup Helicopter'))


menu.action(backup_heli_option, menuname('Bodyguard Menu - Backup Helicopter', 'Spawn Backup Helicopter'), {'backupheli'}, '', function()
	local heli_hash = joaat("buzzard2")
	local ped_hash = joaat("s_m_y_blackops_01")
	local user_ped = PLAYER.PLAYER_PED_ID()
	local pos = ENTITY.GET_ENTITY_COORDS(user_ped)
	pos.x = pos.x + math.random(-20, 20)
	pos.y = pos.y + math.random(-20, 20)
	pos.z = pos.z + 30
	
	REQUEST_MODELS(ped_hash, heli_hash)
	relationship:friendly(user_ped)
	local heli = entities.create_vehicle(heli_hash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
	
	if not ENTITY.DOES_ENTITY_EXIST(heli) then 
		notification.normal('Failed to create vehicle. Please try again', NOTIFICATION_RED)
		return
	else
		local heliNetId = NETWORK.VEH_TO_NET(heli)
		if NETWORK.NETWORK_GET_ENTITY_IS_NETWORKED(NETWORK.NET_TO_PED(heliNetId)) then
			NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(heliNetId, true)
		end
		NETWORK.SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER(heliNetId, players.user(), true)
		ENTITY.SET_ENTITY_INVINCIBLE(heli, godmode)
		VEHICLE.SET_VEHICLE_ENGINE_ON(heli, true, true, true)
		VEHICLE.SET_HELI_BLADES_FULL_SPEED(heli)
		VEHICLE.SET_VEHICLE_SEARCHLIGHT(heli, true, true)
		ENTITY.SET_ENTITY_INVINCIBLE(heli, bodyguard.backup_godmode)
		ADD_BLIP_FOR_ENTITY(heli, 422, 26)
	end

	local pilot = entities.create_ped(29, ped_hash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
	PED.SET_PED_INTO_VEHICLE(pilot, heli, -1)
	PED.SET_PED_MAX_HEALTH(pilot, 500)
	ENTITY.SET_ENTITY_HEALTH(pilot, 500)
	ENTITY.SET_ENTITY_INVINCIBLE(pilot, bodyguard.backup_godmode)
	PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(pilot, true)
	TASK.TASK_HELI_MISSION(pilot, heli, 0, user_ped, 0.0, 0.0, 0.0, 23, 40.0, 40.0, -1.0, 0, 10, -1.0, 0)
	PED.SET_PED_KEEP_TASK(pilot, true)
	
	for seat = 1, 2 do
		local ped = entities.create_ped(29, ped_hash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
		local pedNetId = NETWORK.PED_TO_NET(ped)
		
		if NETWORK.NETWORK_GET_ENTITY_IS_NETWORKED(ped) then
			NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(pedNetId, true)
		end
		
		NETWORK.SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER(pedNetId, players.user(), true)
		PED.SET_PED_INTO_VEHICLE(ped, heli, seat)
		WEAPON.GIVE_WEAPON_TO_PED(ped, joaat("weapon_mg"), -1, false, true)
		PED.SET_PED_COMBAT_ATTRIBUTES(ped, 5, true)
		PED.SET_PED_COMBAT_ATTRIBUTES(ped, 3, false)
		PED.SET_PED_COMBAT_MOVEMENT(ped, 2)
		PED.SET_PED_COMBAT_ABILITY(ped, 2)
		PED.SET_PED_COMBAT_RANGE(ped, 2)
		PED.SET_PED_SEEING_RANGE(ped, 100.0)
		PED.SET_PED_TARGET_LOSS_RESPONSE(ped, 1)
		PED.SET_PED_HIGHLY_PERCEPTIVE(ped, true)
		PED.SET_PED_VISUAL_FIELD_PERIPHERAL_RANGE(ped, 400.0)
		PED.SET_COMBAT_FLOAT(ped, 10, 400.0)
		PED.SET_PED_MAX_HEALTH(ped, 500)
		ENTITY.SET_ENTITY_HEALTH(ped, 500)
		ENTITY.SET_ENTITY_INVINCIBLE(ped, bodyguard.backup_godmode)
		
		if bodyguard.ignoreplayers then
			local relHash = PED.GET_PED_RELATIONSHIP_GROUP_HASH(PLAYER.PLAYER_PED_ID())
			PED.SET_PED_RELATIONSHIP_GROUP_HASH(ped, relHash)
		else
			relationship:friendly(ped)
		end
	end
	
	STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(heli_hash)
	STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(ped_hash)
end)

menu.toggle(backup_heli_option, menuname('Bodyguard Menu - Backup Helicopter', 'Invincible Backup'), {'backupgodmode'}, '', function(toggle)
	bodyguard.backup_godmode = toggle
end)

---------------------
---------------------
-- WORLD
---------------------
---------------------

local world_options = menu.list(menu.my_root(), menuname('World', 'World'), {}, '')

menu.divider(world_options, menuname('World', 'World'))

-------------------------------------
-- JUMPING CARS
-------------------------------------

menu.toggle_loop(world_options, menuname('World', 'Jumping Cars'), {}, '', function(toggle)
	local entities = GET_NEARBY_VEHICLES(PLAYER.PLAYER_ID(), 150)
	for _, vehicle in ipairs(entities) do
		REQUEST_CONTROL(vehicle)
		ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, 0, 0, 6.5, 0, 0, 0, 0, false, false, true)
	end
	wait(1500)
end)

-------------------------------------
-- KILL ENEMIES
-------------------------------------

menu.action(world_options, menuname('World', 'Kill Enemies'), {'killenemies'}, '', function()
	local peds = GET_NEARBY_PEDS(PLAYER.PLAYER_ID(), 500)
	for _, ped in ipairs(peds) do
		local rel = PED.GET_RELATIONSHIP_BETWEEN_PEDS(PLAYER.PLAYER_PED_ID(), ped)
		if not ENTITY.IS_ENTITY_DEAD(ped) and ( (rel == 4 or rel == 5) or PED.IS_PED_IN_COMBAT(ped, PLAYER.PLAYER_PED_ID()) ) then
			local pos = ENTITY.GET_ENTITY_COORDS(ped)
			FIRE.ADD_OWNED_EXPLOSION(PLAYER.PLAYER_PED_ID(), pos.x, pos.y, pos.z, 1, 1.0, true, false, 0.0)
		end
	end
end)

menu.toggle_loop(world_options, menuname('World', 'Auto Kill Enemies'), {'autokillenemies'}, '', function()
	local peds = GET_NEARBY_PEDS(players.user(), 500)
	for _, ped in ipairs(peds) do
		local rel = PED.GET_RELATIONSHIP_BETWEEN_PEDS(PLAYER.PLAYER_PED_ID(), ped)
		if not ENTITY.IS_ENTITY_DEAD(ped) and ( (rel == 4 or rel == 5) or PED.IS_PED_IN_COMBAT(ped, PLAYER.PLAYER_PED_ID()) ) then
			local pos = ENTITY.GET_ENTITY_COORDS(ped)
			FIRE.ADD_OWNED_EXPLOSION(PLAYER.PLAYER_PED_ID(), pos.x, pos.y, pos.z, 1, 1.0, true, false, 0.0)
		end
	end
end)


-------------------------------------
--ANGRY PLANES
-------------------------------------

local planes = {
	'besra',
	'dodo',
	'avenger',
	'microlight',
	'molotok',
	'bombushka',
	'howard',
	'duster',
	'luxor2',
	'lazer',
	'nimbus',
	'shamal',
	'stunt',
	'titan',
	'velum2',
	'miljet',
	'mammatus',
	'besra',
	'cuban800',
	'seabreeze',
	'alphaz1',
	'mogul',
	'nokota',
	'strikeforce',
	'vestra',
	'tula',
	'rogue'
}
local spawned = {}

menu.toggle(world_options, menuname('World', 'Angry Planes'), {}, '', function(toggle)
	angryplanes = toggle
	
	if not angryplanes then
		for index, value in ipairs(spawned) do
			entities.delete_by_handle(value [1])
			entities.delete_by_handle(value [2])
			spawned [index] = nil
		end
		return 
	end

	local ped_hash = joaat("s_m_y_blackops_01")
	REQUEST_MODELS(ped_hash)

	while angryplanes do
		if #spawned < 50 then
			local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
			local theta = (math.random() + math.random(0, 1)) * math.pi
			local radius = math.random(50, 150)
			local plane_hash = joaat(random(planes))
			
			REQUEST_MODELS(plane_hash)
			local plane = VEHICLE.CREATE_VEHICLE(plane_hash, pos.x, pos.y, pos.z, CAM.GET_GAMEPLAY_CAM_ROT(0).z, true, false)
			if ENTITY.DOES_ENTITY_EXIST(plane) then
				NETWORK.SET_NETWORK_ID_CAN_MIGRATE(NETWORK.VEH_TO_NET(plane), false)
				ENTITY._SET_ENTITY_CLEANUP_BY_ENGINE(plane, true)

				local pilot = PED.CREATE_PED(26, ped_hash, pos.x, pos.y, pos.z, CAM.GET_GAMEPLAY_CAM_ROT(0).z, true, true)
				spawned [1 + #spawned] = {plane, pilot}
				PED.SET_PED_INTO_VEHICLE(pilot, plane, -1)

				pos = vect.new(
					pos.x + radius * math.cos(theta),
					pos.y + radius * math.sin(theta),
					pos.z + 200
				)

				VEHICLE._SET_VEHICLE_JET_ENGINE_ON(plane, true)
				ENTITY.SET_ENTITY_COORDS(plane, pos.x, pos.y, pos.z)
				ENTITY.SET_ENTITY_HEADING(plane, math.deg(theta))
				VEHICLE.SET_VEHICLE_FORWARD_SPEED(plane, 60)
				VEHICLE.SET_HELI_BLADES_FULL_SPEED(plane)
				VEHICLE.CONTROL_LANDING_GEAR(plane, 3)
				VEHICLE.SET_VEHICLE_FORCE_AFTERBURNER(plane, true)
				TASK.TASK_PLANE_MISSION(pilot, plane, 0, PLAYER.PLAYER_PED_ID(), 0, 0, 0, 6, 100, 0, 0, 80, 50)
			end
		end
		wait(500)
	end
end)

-------------------------------------
-- HEALTH BAR
-------------------------------------

local items = {'Disable', 'Players', 'Peds', 'Players & Peds', 'Aimed Ped'}
local current_health_bar
local health_bars = menu.list(world_options, menuname('World', 'Draw Health Bar') .. ': ' .. menuname('World - Draw Health Bar', items[1]))

for i, name in ipairs(items) do
	menu.action(health_bars, menuname('World - Draw Health Bar', name), {}, '', function()
		current_health_bar = i
		menu.set_menu_name(health_bars, menuname('World', 'Draw Health Bar') .. ': ' .. menuname('World - Draw Health Bar', name))
		menu.focus(health_bars)	
	end)
end

create_tick_handler(function()
	if current_health_bar == 1 then -- disable
		return true
	elseif current_health_bar == 2 then -- players
		for _, player in ipairs(players.list(false)) do
			local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player)
			draw_health_on_ped(ped, 250)
		end
	elseif current_health_bar == 3 then -- peds
		local peds = GET_NEARBY_PEDS(PLAYER.PLAYER_ID(), 300)
		for _, ped in ipairs(peds) do
			if not PED.IS_PED_A_PLAYER(ped) and ENTITY.HAS_ENTITY_CLEAR_LOS_TO_ENTITY(PLAYER.PLAYER_PED_ID(), ped, 1) then
				draw_health_on_ped(ped, 250)
			end
		end
	elseif current_health_bar == 4 then -- players & peds
		local peds = GET_NEARBY_PEDS(PLAYER.PLAYER_ID(), 300)
		for _, ped in ipairs(peds) do
			if ped ~= PLAYER.PLAYER_PED_ID() and ENTITY.HAS_ENTITY_CLEAR_LOS_TO_ENTITY(PLAYER.PLAYER_PED_ID(), ped, 1) then
				draw_health_on_ped(ped, 250)
			end
		end
	elseif current_health_bar == 5 then -- aimed ped
		if PLAYER.IS_PLAYER_FREE_AIMING(PLAYER.PLAYER_ID()) then
			local entity = NULL
			local ptr = alloc(32)
			if PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(PLAYER.PLAYER_ID(), ptr) then
				entity = memory.read_int(ptr)
			end
			memory.free(ptr)
			if entity ~= NULL and ENTITY.IS_ENTITY_A_PED(entity) then
				draw_health_on_ped(entity, 500)
			end
		end
	end
	return true
end)

---------------------
---------------------
-- WIRISCRIPT
---------------------
---------------------

local script = menu.list(menu.my_root(), 'WiriScript', {}, '')

menu.divider(script, 'WiriScript')

menu.action(script, menuname('WiriScript', 'Show Credits'), {}, '', function()
	if showing_intro then return end
	
	local state = 0
	local stime = cTime()
	local i = 1
	local delay = 0
	local ty = {
		'DeF3c',
		'Hollywood Collins',
		'Murten',
		'QuickNET',
		'komt',
		'Ren',
		'ICYPhoenix',
		'Koda',
		'jayphen',
		'Fwishky',
		'Polygon',
		'Sainan',
		'NONECKED',
		{'wiriscript', "HUD_COLOUR_BLUE"}
	}

	AUDIO.SET_MOBILE_RADIO_ENABLED_DURING_GAMEPLAY(true)
	AUDIO.SET_MOBILE_PHONE_RADIO_STATE(true)
	AUDIO.SET_RADIO_TO_STATION_NAME("RADIO_01_CLASS_ROCK")
	AUDIO.SET_CUSTOM_RADIO_TRACK_LIST("RADIO_01_CLASS_ROCK", "END_CREDITS_SAVE_MICHAEL_TREVOR", true)

	create_tick_handler(function()
		local scaleform = GRAPHICS.REQUEST_SCALEFORM_MOVIE("OPENING_CREDITS")
		
		while not GRAPHICS.HAS_SCALEFORM_MOVIE_LOADED(scaleform) do
			wait()
		end
	
		if cTime() - stime >= delay and state == 0 then
			SETUP_SINGLE_LINE(scaleform)
			ADD_TEXT_TO_SINGLE_LINE(scaleform, ty[i][1] or ty[i], "$font2", ty[i][2] or "HUD_COLOUR_WHITE")
			GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SHOW_SINGLE_LINE")
			GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_TEXTURE_NAME_STRING("presents")
			GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
		
			GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SHOW_CREDIT_BLOCK")
			GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_TEXTURE_NAME_STRING("presents")
			GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(0.5)
			GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
		
			state = 1
			i = i + 1
			delay = 4000
			stime = cTime()
		end
	
		if cTime() - stime >= 4000 and state == 1 then
			HIDE(scaleform)
			state = 0
			stime = cTime()
		end
	
		if state == 1 and i == #ty + 1 then
			state = 2
			stime = cTime()
		end

		if cTime() - stime >= 3000 and state == 2 then
			AUDIO.START_AUDIO_SCENE("CAR_MOD_RADIO_MUTE_SCENE")
			wait(5000)
			AUDIO.SET_MOBILE_RADIO_ENABLED_DURING_GAMEPLAY(false)
			AUDIO.SET_MOBILE_PHONE_RADIO_STATE(false)
			AUDIO.CLEAR_CUSTOM_RADIO_TRACK_LIST("RADIO_01_CLASS_ROCK")
			AUDIO.SKIP_RADIO_FORWARD()
			AUDIO.STOP_AUDIO_SCENE("CAR_MOD_RADIO_MUTE_SCENE")
			return false
		end

		if PAD.IS_CONTROL_JUST_PRESSED(2, 194)  then
			state = 2
			stime = cTime()
		elseif state ~= 2 then
		
			if instructional:begin() then
				add_control_instructional_button(194, "REPLAY_SKIP_S")
				instructional:set_background_colour(0, 0, 0, 80)
				instructional:draw()
			end
		end

		HUD.HIDE_HUD_AND_RADAR_THIS_FRAME()
		HUD._HUD_WEAPON_WHEEL_IGNORE_SELECTION()
		GRAPHICS.DRAW_SCALEFORM_MOVIE_FULLSCREEN(scaleform, 255, 255, 255, 255, 0)
		return true
	end)
end)


developer(menu.toggle_loop, menu.my_root(), 'Address Picker', {}, 'Developer', function()
	if PLAYER.IS_PLAYER_FREE_AIMING(PLAYER.PLAYER_ID()) then
		local ptr = alloc(32)
		if PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(PLAYER.PLAYER_ID(), ptr) then
			entity = memory.read_int(ptr)
		end
		memory.free(ptr)
		if entity and entity ~= NULL then
			if ENTITY.IS_ENTITY_A_PED(entity) and PED.IS_PED_IN_ANY_VEHICLE(entity, false) then
				local vehicle  = PED.GET_VEHICLE_PED_IS_IN(entity, false)
				entity = vehicle
			end
			
			local strg
			local ptrX = alloc()
			local ptrY = alloc()
			draw_box_esp(entity, Colour.New(255, 0, 0))
			local pos = ENTITY.GET_ENTITY_COORDS(entity)
			GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(pos.x, pos.y, pos.z, ptrX, ptrY)
			local posX = memory.read_float(ptrX); memory.free(ptrX)
			local posY = memory.read_float(ptrY); memory.free(ptrY)
			local addr = entities.handle_to_pointer(entity)
			
			if addr ~= NULL then
				local addr_hex = string.format("%x", addr)
				strg = string.upper(addr_hex)
			else 
				strg = 'NULL' 
			end

			local lenX, lenY = directx.get_text_size(strg, 0.5)
			GRAPHICS.DRAW_RECT(posX, posY, lenX, lenY, 0, 0, 0, 120)
			directx.draw_text(posX, posY, strg, ALIGN_CENTRE, 0.5, Colour.New(1.0, 1.0, 1.0))
			if PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) and addr ~= NULL then
				util.copy_to_clipboard(strg)
			end
		end
	end
end)


developer(menu.action, menu.my_root(), 'CPedFactory', {}, '', function()
	local hex = string.format("%x", worldptr)
	util.copy_to_clipboard(string.upper( hex ))
end)


menu.hyperlink(menu.my_root(), menuname('WiriScript', 'Join WiriScript FanClub'), 'https://cutt.ly/wiriscript-fanclub', 'Join us in our fan club, created by komt.')


for _, pId in ipairs(players.list()) do
	generate_features(pId)
end
players.on_join(generate_features)

-------------------------------------
--ON STOP
-------------------------------------

util.on_stop(function()
	if handling.cursor_mode then
		UI.toggle_cursor_mode(false)
	end
	if bulletchanger then
		SET_BULLET_TO_DEFAULT()
	end
	if speed_mult ~= 1.0 then
		SET_AMMO_SPEED_MULT(1.0)
	end

	ufo.on_stop()
	guided_missile.on_stop()

	if usingprofile then
		if spoofname then 
			menu.trigger_commands('spoofname off') 
		end

		if spoofrid then 
			menu.trigger_commands('spoofrid off') 
		end
		
		if spoofcrew then 
			menu.trigger_commands('crew off') 
		end
	end

	if carpetride then
		local m_object_hash = joaat("p_cs_beachtowel_01_s")
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
		local obj = OBJECT.GET_CLOSEST_OBJECT_OF_TYPE(pos.x, pos.y, pos.z, 10.0, m_object_hash, false, 0, 0)
		if ENTITY.DOES_ENTITY_EXIST(obj) and ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(PLAYER.PLAYER_PED_ID(), obj) then
			TASK.CLEAR_PED_TASKS_IMMEDIATELY(PLAYER.PLAYER_PED_ID())
			ENTITY.DETACH_ENTITY(PLAYER.PLAYER_PED_ID(), true, false)
			ENTITY.SET_ENTITY_VISIBLE(obj, false)
			entities.delete_by_handle(obj)
		end
	end

	if autopilot then
		TASK.CLEAR_PED_TASKS(PLAYER.PLAYER_PED_ID())
	end

end)


while true do
	wait()

	guided_missile.main_loop()
	ufo.main_loop()

	if speed_mult ~= 1.0 then
		SET_AMMO_SPEED_MULT(speed_mult)
	end

-------------------------------------
--HANDLING DISPLAY
-------------------------------------

	if handling.display_handling then
		handling.vehicle_name = GET_USER_VEHICLE_NAME()
		handling.vehicle_model = GET_USER_VEHICLE_MODEL(true)

		if PAD.IS_CONTROL_JUST_PRESSED(2, 323) or PAD.IS_DISABLED_CONTROL_JUST_PRESSED(2, 323) then
			UI.toggle_cursor_mode()
			handling.cursor_mode = not handling.cursor_mode
		end

		UI.set_highlight_colour(highlightcolour.r, highlightcolour.g, highlightcolour.b)
		UI.begin('Vehicle Handling', handling.window_x, handling.window_y)
		
		UI.label('Current Vehicle\t', handling.vehicle_name)

		for s, l in pairs(handling.inviewport) do
			if #s > 0 then
				local subhead = first_upper(s)
				UI.subhead(subhead)
				for _, a in ipairs(l) do
					local addr = address_from_pointer_chain(worldptr, {0x08, 0xD30, 0x938, a[2]})
					local value
					
					if addr == NULL then
						value = '???'
					else
						value = round(memory.read_float(addr), 3)
					end
					
					if a[1] == handling.onfocus then
						UI.label(a[1] .. ':\t', value, onfocuscolour, onfocuscolour)
					else
						UI.label(a[1] .. ':\t', value)
					end
				end
			end
		end

		if menu.is_open() then 
			handling.inviewport = {}
			if IS_THIS_MODEL_AN_AIRCRAFT(handling.vehicle_model) and #handling.flying == 0 then
				handling.flying = handling:create_actions(handling.offsets[2], 'flying')
			end
			
			if not IS_THIS_MODEL_AN_AIRCRAFT(handling.vehicle_model) and #handling.flying > 0 then
				for i, Id in ipairs(handling.flying) do
					menu.delete(Id)
				end
				handling.flying = {}
			end
			
			if VEHICLE.IS_THIS_MODEL_A_BOAT(handling.vehicle_model) and #handling.boat == 0 then
				handling.boat = handling:create_actions(handling.offsets[3], 'boat')
			end
			
			if not VEHICLE.IS_THIS_MODEL_A_BOAT(handling.vehicle_model) and #handling.boat > 0 then
				for i, Id in ipairs(handling.boat) do
					menu.delete(Id)		
				end
				handling.boat = {}
			end
		end

		UI.divider()
		UI.start_horizontal()
		   
		if UI.button('Save Handling', buttonscolour, Colour.Mult(buttonscolour, 0.6)) then
			handling:save()
		end

		if UI.button('Load Handling', buttonscolour, Colour.Mult(buttonscolour, 0.6)) then
			handling:load()
		end
		
		UI.end_horizontal()
		handling.window_x, handling.window_y = UI.finish()

		if instructional:begin() then
			add_control_instructional_button(323, 'Cursor mode')
			instructional:set_background_colour(0, 0, 0, 80)
			instructional:draw()
		end

	end
end
