-------------------------------------------------------------------WiriScript v15---------------------------------------------------------------------------------------
--[[ Thanks to
		
		DeF3c,
		Hollywood Collins,
		Murten,
		Koda,
		ICYPhoenix,
		jayphen,
		Fwishky,
		Polygon
		komt,
		Ren, 
		Sainan,
		NONECKED

and all other developers who shared their work and nice people who helped me. All of you guys teached me things I used in this script <3.
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
This is an open code for you to use and share. Feel free to add, modify or remove features as long as you don't try to sell this script. Please consider 
sharing your own versions with Stand's community. --]]
-------------------------------------------------------------------by: nowiry------------------------------------------------------------------------------------------

util.require_natives(1640181023)
require 'lua_imGUI V2-1'
json = require 'pretty.json'
UI = UI.new()

local audible = true
local delay = 300
local scriptdir = filesystem.scripts_dir()
local wiridir = scriptdir .. "\\WiriScript"
local languagedir = wiridir .. "\\language"
local owned = false
local spoofname, spoofrid = true, true
local version = 15
local ini = {}
local spawned_attackers = {}
local explosive_bandito_sent = false
local minitank_weapon
local random_minitank_weapon = true
local hostile_group
local friendly_group
local showing_intro = false
local worldPtr = memory.rip(memory.scan('48 8B 05 ? ? ? ? 45 ? ? ? ? 48 8B 48 08 48 85 C9 74 07') + 3)
if worldPtr == 0 then
	return notification.red('Pattern scan failed')
end

wait = util.yield
joaat = util.joaat
alloc = memory.alloc
getTime = util.current_time_millis
create_tick_handler = util.create_tick_handler

---------------------------------
--CONFIG
---------------------------------

config = {
	controls = {
		vehicleweapons = 86,
		airstrikeaircraft = 86
	},
	general = {
		standnotifications = false,
		displayhealth = true,
		language = 'english',
		disablelockon = false,
		disablepreview = false,
		bustedfeatures = false
	},
	onfocuscolour = {
		r = 164,
		g = 84,
		b = 244,
		a = 255
	},
	highlightcolour = {
		r = 0,
		g = 255,
		b = 255,
		a = 255
	},
	buttonscolour = {
		r = 127,
		g = 0,
		b = 204,
		a = 255
	},
	healthtxtpos = {
		x = 0.03, 
		y = 0.05
	},
}

-----------------------------------
--FILE SYSTEM
-----------------------------------

if not filesystem.exists(scriptdir..'\\WiriScript') then
	filesystem.mkdir(scriptdir..'\\WiriScript')
end

if not filesystem.exists(scriptdir..'\\WiriScript\\language') then
	filesystem.mkdir(scriptdir..'\\WiriScript\\language')
end

if filesystem.exists(scriptdir..'\\WiriScript\\logo.png') then
	os.remove(scriptdir..'\\WiriScript\\logo.png')
end

if filesystem.exists(scriptdir..'\\WiriScript\\config.data') then
	os.remove(scriptdir..'\\WiriScript\\config.data')
end

if filesystem.exists(scriptdir..'\\savednames.data') then
	os.remove(scriptdir..'\\savednames.data')
end

if not filesystem.exists(scriptdir..'\\WiriScript\\profiles') then
	filesystem.mkdir(scriptdir..'\\WiriScript\\profiles')
end

if not filesystem.exists(scriptdir..'\\WiriScript\\handling') then
	filesystem.mkdir(scriptdir..'\\WiriScript\\handling') 
end

if filesystem.exists(filesystem.resources_dir()..'\\wiriscript_logo.png') then
	os.remove(filesystem.resources_dir()..'\\wiriscript_logo.png')
end

-----------------------------------

local config_file = (scriptdir..'\\WiriScript\\config.ini')


function ini.save(file, t)
	file = io.open(file, 'w')
	local contents = ''
	for section, s in pairs_by_keys(t) do
		contents = contents..('[%s]\n'):format(section)
		for key, value in pairs(s) do
			if string.len(key) == 1 then key = string.upper(key) end
			contents = contents..('%s = %s\n'):format(key, tostring(value))
		end
		contents = contents..'\n'
	end
	file:write(contents)
	file:close()
end


function ini.load(file)
	if not filesystem.exists(file) then return end
	local t = {}
	local section
	for line in io.lines(file) do
		local strg = line:match('^%[([^%]]+)%]$')
		if strg then
			section = strg
			t[section] = t[section] or {}
		end
		local key, value = line:match('^([%w_]+)%s*=%s*(.+)$')
		if key and value ~= nil then
			if string.len(key) == 1 then key = string.lower(key) end
			if value == 'true' then value = true end
			if value == 'false' then value = false end
			if tonumber(value) then value = tonumber(value) end
			t[section][key] = value
		end
	end
	return t
end


local loaded_config = ini.load(config_file)


if loaded_config then
	for s, table in pairs(loaded_config) do
		for k, v in pairs(table) do
			if config[s] and config[s][k] ~= nil then
				config[s][k] = v
			end
		end
	end
end

general_config = config.general
control_config = config.controls

function game_notification(message)
	GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT('DIA_ZOMBIE1', 0)
	while not GRAPHICS.HAS_STREAMED_TEXTURE_DICT_LOADED('DIA_ZOMBIE1') do
		wait()
	end
	if not string.match(message, '[%.?]$') then message = message .. '.' end
	util.BEGIN_TEXT_COMMAND_THEFEED_POST(message or 'nil')
	local tittle = 'WiriScript'
	local subtitle = '~c~Notification'
	HUD.END_TEXT_COMMAND_THEFEED_POST_MESSAGETEXT('DIA_ZOMBIE1', 'DIA_ZOMBIE1', true, 4, tittle, subtitle)
	HUD.END_TEXT_COMMAND_THEFEED_POST_TICKER(true, false)
end


function stand_notification(message)
	message = '[WiriScript] ' .. message:gsub('[~]%w[~]', '')
	if not string.match(message, '[%.?]$') then message = message .. '.' end
	util.toast(message, TOAST_ABOVE_MAP)
end


notification = {
	['normal'] = function(message)
		if not general_config.standnotifications then
			game_notification(message)
		else
			stand_notification(message)
		end
	end,

	['red'] = function(message)
		if not general_config.standnotifications then
			HUD._THEFEED_SET_NEXT_POST_BACKGROUND_COLOR(6)
			game_notification(message)
		else
			stand_notification(message)
		end
	end
}


function pairs_by_keys(t, f)
	local a = {}
	for n in pairs(t) do table.insert(a, n) end
	table.sort(a, f)
	local i = 0
	local iter = function()
	  i = i + 1
	  if a[i] == nil then return nil
	  else return a[i], t[a[i]]
	  end
	end
	return iter
end

features = {} --stores the features' names
menunames = {}


function menuname(section, name)
	features[ section ] = features[ section ] or {}
	features[ section ][ name ] = features[ section ][ name ] or ''
	if general_config.language ~= 'english' then
		menunames[ section ] = menunames[ section ] or {}
		if not menunames[ section ][ name ] and menunames[ section ][ name ] ~= '' then
			menunames[ section ][ name ] = ''
			return name
		end
		if  menunames[ section ][ name ] == '' then
			return name
		end
		return menunames[ section ][ name ]
	end
	return name
end



if general_config.language ~= 'english' then
	local file = languagedir .. '\\' .. general_config.language .. '.json'
	if not filesystem.exists(file) then
		notification.red('Translation file not found')
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


async_http.init('pastebin.com', '/raw/EhH1C6Dh', function(output)
	local cversion = tonumber(output)
	if cversion then 
		if cversion > version then	
    	    notification.red('WiriScript v' .. output .. ' is available')
			menu.hyperlink(menu.my_root(), 'Get WiriScript v' .. output, 'https://cutt.ly/get-wiriscript', '')
    	end
	end
end, function()
	util.log('[WiriScript] Failed to check for updates.')
end)
async_http.dispatch()


async_http.init('pastebin.com', '/raw/WMUmGzNj', function(output)
	if string.match(output, '^#') ~= nil then
        notification.red('Nowiry: '..string.match(output, '^#(.+)'))
    end
end, function()
    util.log('[WiriScript] Failed to get message.')
end)
async_http.dispatch()


vect = {
	['new'] = function(x, y, z)
		return {['x'] = x, ['y'] = y, ['z'] = z}
	end,
	['subtract'] = function(a, b)
		return vect.new(a.x-b.x, a.y-b.y, a.z-b.z)
	end,
	['add'] = function(a, b)
		return vect.new(a.x+b.x, a.y+b.y, a.z+b.z)
	end,
	['mag'] = function(a)
		return math.sqrt(a.x^2 + a.y^2 + a.z^2)
	end,
	['norm'] = function(a)
		local mag = vect.mag(a)
		return vect.div(a, mag)
	end,
	['mult'] = function(a, b)
		return vect.new(a.x*b, a.y*b, a.z*b)
	end, 
	['div'] = function(a, b)
		return vect.new(a.x/b, a.y/b, a.z/b)
	end, 
	['dist'] = function(a, b) --returns the distance between two vectors
		return vect.mag(vect.subtract(a, b) )
	end
}


local weapons = {						--here you can modify which weapons are available to choose
	['Pistol'] = 'weapon_pistol', --['name shown in Stand'] =  'weapon ID'
	['Stun Gun'] = 'weapon_stungun',
	['Up-n-Atomizer'] =  'weapon_raypistol',
	['Special Carbine'] = 'weapon_specialcarbine',
	['Pump Shotgun'] = 'weapon_pumpshotgun',
	['Combat MG'] = 'weapon_combatmg',
	['Heavy Sniper'] = 'weapon_heavysniper',
	['Minigun'] = 'weapon_minigun',
	['RPG'] = 'weapon_rpg',
	['Railgun'] = 'weapon_railgun', --Stolen idea from Collins kek
	['Compact Launcher'] = 'weapon_compactlauncher',
	['Compact EMP Launcher'] = 'weapon_emplauncher'
}


local melee_weapons = {
	['Unarmed'] = 'weapon_unarmed', --['name shown in Stand'] = 'weapon ID'
	['Knife'] = 'weapon_knife',
	['Machete'] = 'weapon_machete',
	['Battle Axe'] = 'weapon_battleaxe',
	['Wrench'] = 'weapon_wrench',
	['Hammer'] = 'weapon_hammer',
	['Baseball Bat'] = 'weapon_bat'
}


local peds = {									--here you can modify which peds are available to choose
	['Prisoner'] =  's_m_y_prismuscl_01', --['name shown in Stand'] = 'ped model ID'
	['Mime'] = 's_m_y_mime',
	['Astronaut'] = 's_m_m_movspace_01',
	['SWAT'] = 's_m_y_swat_01',
	['Ballas Ganster'] =  'csb_ballasog',
	['Marine'] = 'csb_ramp_marine',
	['Female Police Officer'] =  's_f_y_cop_01',
	['Male Police Officer'] = 's_m_y_cop_01',
	['Jesus'] = 'u_m_m_jesus_01',
	['Zombie'] = 'u_m_y_zombie_01',
	['Juggernaut'] = 'u_m_y_juggernaut_01',
	['Clown'] = 's_m_y_clown_01',
	['Hooker'] = 's_f_y_hooker_01',
	['Altruist'] = 'a_m_y_acult_01'
}


local gunner_weapon_list = {              --these are the buzzard's gunner weapons. You can include some (make sure gunners can use them from heli)
	['Combat MG'] = 'weapon_combatmg',
	['RPG'] = 'weapon_rpg'
}


local modIndex = --used to change minitank's weapon
{
	['Machine Gun'] = -1,
	['Rocket Laucher'] = 1,
	['Plasma Cannon'] = 2
}


local imputs = {
	['INPUT_VEH_DUCK'] = {
		['control'] = 'X|A',
		['index'] = 73
	},
	['INPUT_VEH_ATTACK'] = {
		['control'] = 'Mouse L|RB',
		['index'] = 69
	},
	['INPUT_VEH_AIM'] = {
		['control'] = 'Mouse R|LB',
		['index'] = 68
	},
	['INPUT_VEH_HORN'] = {
		['control'] = 'E|L3',
		['index'] = 86
	},
	['INPUT_VEH_CINEMATIC_UP_ONLY'] = {
		['control'] = 'Numpad +|none',
		['index'] = 96
	},
	['INPUT_VEH_CINEMATIC_DOWN_ONLY'] = {
		['control'] = 'Numpad -|none',
		['index'] = 97
	},
	['INPUT_JUMP'] = {
		['control'] = 'Spacebar|X',
		['index'] = 22
	}
}


function SHOW_CORNER_HELP_GIVEN_CONTROL_INDEX(index, message)
	for name, imput in pairs(imputs) do
		if imput.index == index then
			return util.show_corner_help(('~%s~'):format(name)..' '..message)
		end
	end
	error('Control index not found')
end


function address_from_pointer_chain(basePtr, offsets)
	local addr = memory.read_long(basePtr)
	for k = 1, (#offsets - 1) do
		addr = memory.read_long(addr + offsets[k])
		if addr == 0 then
			return 0
		end
	end
	addr = addr + offsets[#offsets]
	return addr
end


function atan2(y, x)
	if x > 0 then
		return math.atan(y/x)
	end
	if x < 0 and y >= 0 then
		return (math.atan(y/x) + math.pi)
	end
	if x < 0 and y < 0 then
		return (math.atan(y/x) - math.pi)
	end
	if x == 0 and y > 0 then
		return (math.pi / 2)
	end
	if x == 0 and y < 0 then
		return (-math.pi / 2)
	end
	if x == 0 and y == 0 then
		return 0 -- actually 'tan' is not defined in this case but...
	end
end


function GET_ROTATION_FROM_DIRECTION(v)
	local mag = vect.mag(v)
	local rotation = {
		['pitch'] = math.asin(v.z / mag) * (180 / math.pi),
		['roll'] = 0.0,
		['yaw'] = -atan2(v.x, v.y) * (180 / math.pi)
	}
	return rotation
end


function SET_ENT_FACE_ENT(ent1, ent2) --All credits to Ren for suggesting me this function
	local a = ENTITY.GET_ENTITY_COORDS(ent1)
	local b = ENTITY.GET_ENTITY_COORDS(ent2)
	local dx = b.x - a.x
	local dy = b.y - a.y
	local heading = MISC.GET_HEADING_FROM_VECTOR_2D(dx, dy)
	return ENTITY.SET_ENTITY_HEADING(ent1, heading)
end


function SET_ENT_FACE_ENT_3D(ent1, ent2)
	local a = ENTITY.GET_ENTITY_COORDS(ent1)
	local b = ENTITY.GET_ENTITY_COORDS(ent2)
	local ab = vect.subtract(b, a)
	local rot = GET_ROTATION_FROM_DIRECTION(ab)
	ENTITY.SET_ENTITY_ROTATION(ent1, rot.pitch, rot.roll, rot.yaw)
end


function EXPLODE(pid, type, owned)
	local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
	pos.z = pos.z - 1.0
	if not owned then
		FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, type, 1.0, audible, invisible, 0, false)
	else
		FIRE.ADD_OWNED_EXPLOSION(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()), pos.x, pos.y, pos.z, type, 1.0, audible, invisible, 0, true)
	end
end


function trapcage(pid)
	local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
	local pos = ENTITY.GET_ENTITY_COORDS(p)
	local objhash = joaat('prop_gold_cont_01')
	STREAMING.REQUEST_MODEL(objhash)
	while not STREAMING.HAS_MODEL_LOADED(objhash) do
		wait()
	end
	local obj = OBJECT.CREATE_OBJECT(objhash, pos.x, pos.y, pos.z - 1.0, true, false, false)
	ENTITY.FREEZE_ENTITY_POSITION(obj, true)
	STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(objhash)
end


function trapcage_2(pid)
	local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
	local pos = ENTITY.GET_ENTITY_COORDS(p)
	local objhash = joaat('prop_rub_cage01a')
	STREAMING.REQUEST_MODEL(objhash)
	while not STREAMING.HAS_MODEL_LOADED(objhash) do
		wait()
	end
	local obj_1 = OBJECT.CREATE_OBJECT(objhash, pos.x, pos.y, pos.z - 1.0, true, false, false)
	local obj_2 = OBJECT.CREATE_OBJECT(objhash, pos.x, pos.y, pos.z + 1.2, true, false, false)
	ENTITY.SET_ENTITY_ROTATION(obj_2, -180.0, ENTITY.GET_ENTITY_ROTATION(obj_2).y, 90.0, 1, true)
	ENTITY.FREEZE_ENTITY_POSITION(obj_1, true)
	ENTITY.FREEZE_ENTITY_POSITION(obj_2, true)
	STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
end


function insert_once(list, value)
	for k, v in pairs(list) do
		if v == value then return true end
	end
	table.insert(list, value)
	return false
end


function table.find(t, value)
	for k, v in pairs(t) do
		if v == value then
			return true
		end
	end
	return false
end


function ADD_BLIP_FOR_ENTITY(entity, blipSprite, colour)
	local blip = HUD.ADD_BLIP_FOR_ENTITY(entity)
	HUD.SET_BLIP_SPRITE(blip, blipSprite)
	HUD.SET_BLIP_COLOUR(blip, colour)
	HUD.SHOW_HEIGHT_ON_BLIP(blip, false)
	HUD.SET_BLIP_ROTATION(blip, SYSTEM.CEIL(ENTITY.GET_ENTITY_HEADING(entity)))
	NETWORK.SET_NETWORK_ID_CAN_MIGRATE(entity, false)
	util.create_thread(function()
		local netId = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(entity)
		while NETWORK.NETWORK_DOES_ENTITY_EXIST_WITH_NETWORK_ID(netId) do
			HUD.SET_BLIP_ROTATION(blip, SYSTEM.CEIL(ENTITY.GET_ENTITY_HEADING(entity)))
			if ENTITY.IS_ENTITY_DEAD(NETWORK.NET_TO_ENT(netId)) then
				break	
			end
			wait()
		end
		HUD.SET_BLIP_DISPLAY(blip, 0)
		util.remove_blip(blip)
	end)
	return blip
end


local function ADD_RELATIONSHIP_GROUP(name)
	local ptr = alloc(32)
	PED.ADD_RELATIONSHIP_GROUP(name, ptr)
	local relationship = memory.read_int(ptr); memory.free(ptr)
	return relationship
end


local set_relationship = {
	['hostile'] = function(ped)
		if not PED._DOES_RELATIONSHIP_GROUP_EXIST(hostile_group) then
			hostile_group = ADD_RELATIONSHIP_GROUP('hostile_group')
			PED.SET_RELATIONSHIP_BETWEEN_GROUPS(0, hostile_group, hostile_group)
		end
		PED.SET_PED_RELATIONSHIP_GROUP_HASH(ped, hostile_group)
	end,

	['friendly'] = function(ped)
		if not PED._DOES_RELATIONSHIP_GROUP_EXIST(friendly_group) then
			friendly_group = ADD_RELATIONSHIP_GROUP('friendly_group')
			PED.SET_RELATIONSHIP_BETWEEN_GROUPS(0, friendly_group, friendly_group)
		end
		PED.SET_PED_RELATIONSHIP_GROUP_HASH(ped, friendly_group)
	end
}


function random(t) --returns a random value from table
	local list = {}
	for k, value in pairs(t) do table.insert(list, value) end
	return list[math.random(1, #list)]
end


function REQUEST_CONTROL(entity)
	if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) then
		local netId = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(entity)
		NETWORK.SET_NETWORK_ID_CAN_MIGRATE(netId, true)
		NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
	end
	return NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity)
end


function REQUEST_CONTROL_LOOP(entity)
	local tick = 0
	while not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) and tick < 25 do
		wait()
		NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
		tick = tick + 1
	end
	if NETWORK.NETWORK_IS_SESSION_STARTED() then
		local netId = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(entity)
		NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
		NETWORK.SET_NETWORK_ID_CAN_MIGRATE(netId, true)
	end
end


function GET_NEARBY_PEDS(pid, radius) --returns a list of nearby peds given player Id
	local peds = {}
	local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
	local pos = ENTITY.GET_ENTITY_COORDS(p)
	for k, ped in pairs(entities.get_all_peds_as_handles()) do
		if ped ~= p then
			local ped_pos = ENTITY.GET_ENTITY_COORDS(ped)
			if vect.dist(pos, ped_pos) <= radius then table.insert(peds, ped) end
		end
	end
	return peds
end


function GET_NEARBY_VEHICLES(pid, radius) --returns a list of nearby vehicles given player Id
	local vehicles = {}
	local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
	local pos = ENTITY.GET_ENTITY_COORDS(p)
	local v = PED.GET_VEHICLE_PED_IS_IN(p, false)
	for k, vehicle in pairs(entities.get_all_vehicles_as_handles()) do 
		local veh_pos = ENTITY.GET_ENTITY_COORDS(vehicle)
		if vehicle ~= v and vect.dist(pos, veh_pos) <= radius then table.insert(vehicles, vehicle) end
	end
	return vehicles
end


function GET_NEARBY_ENTITIES(pid, radius) --returns nearby peds and vehicles given player Id
	local peds = GET_NEARBY_PEDS(pid, radius)
	local vehicles = GET_NEARBY_VEHICLES(pid, radius)
	local entities = peds
	for i = 1, #vehicles do table.insert(entities, vehicles[i]) end
	return entities
end


function DELETE_NEARBY_VEHICLES(pos, model, radius)
	local hash = joaat(model)
	local vehicles = entities.get_all_vehicles_as_handles()
	for k, veh in pairs(vehicles) do
		if ENTITY.DOES_ENTITY_EXIST(veh) and ENTITY.GET_ENTITY_MODEL(veh) == hash then
			local vpos = ENTITY.GET_ENTITY_COORDS(veh, false)
			local ped = VEHICLE.GET_PED_IN_VEHICLE_SEAT(veh, -1)
			if not PED.IS_PED_A_PLAYER(ped) and vect.dist(pos, vpos) < radius then
				REQUEST_CONTROL_LOOP(veh)
				REQUEST_CONTROL_LOOP(ped)
				ENTITY.SET_ENTITY_AS_MISSION_ENTITY(veh, true, true)
				ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ped, true, true)
				entities.delete_by_handle(veh)
				entities.delete_by_handle(ped)
			end
		end
	end
end


function DELETE_PEDS(model)
	local hash = joaat(model)
	local peds = entities.get_all_peds_as_handles()
	for k, ped in pairs(peds) do
		if ENTITY.GET_ENTITY_MODEL(ped) == hash and not PED.IS_PED_A_PLAYER(ped) then
			REQUEST_CONTROL_LOOP(ped)
			ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ped, true, true)
			entities.delete_by_handle(ped)
		end
	end
end


local write_global = {
	['byte'] = function(global, value)
		memory.write_byte(memory.script_global(global), value)
	end,
	['int'] = function(global, value)
		memory.write_int(memory.script_global(global), value)
	end
}


local read_global = {
	['byte'] = function(global)
		return memory.read_byte(memory.script_global(global))
	end,
	['int'] = function(global)
		return memory.read_int(memory.script_global(global))
	end
}


function SET_PED_CAN_BE_KNOCKED_OFF_VEH(ped, state)
	native_invoker.begin_call()
	native_invoker.push_arg_int(ped)
	native_invoker.push_arg_int(state)
	native_invoker.end_call('7A6535691B477C48')
end


function getn(table)
	if rawget(table, 1) ~= nil then return #table end -- treat as array
	-- treat as object
	local t = {}
	local maxn = 0
	for k, v in pairs(table) do
		if type(v) == 'table' then 
			maxn = maxn + getn(v)
		else
			t[#t + 1] = v
		end
	end
	maxn = maxn + #t
	return maxn
end


function incr(ptr, fvalue, delta)
    local cvalue = memory.read_float(ptr) 
    local delta = math.abs(delta)
	if cvalue ~= fvalue then
    	if cvalue > fvalue then 
			delta = -delta 
		end
    	if math.abs(fvalue - cvalue) > delta then
    	    cvalue = cvalue + delta
    	else  
    	    cvalue = fvalue
    	end
	end
    memory.write_float(ptr, cvalue)
end


function round(num, decimalPlaces)
	return tonumber(string.format('%.' .. (decimalPlaces or 0) .. 'f', num))
end


function ROTATION_TO_DIRECTION(rotation) --https://forum.cfx.re/t/get-position-where-player-is-aiming/1903886/2
	local adjusted_rotation = { 
		x = (math.pi / 180) * rotation.x, 
		y = (math.pi / 180) * rotation.y, 
		z = (math.pi / 180) * rotation.z 
	}
	local direction = {
		x = -math.sin(adjusted_rotation.z) * math.abs(math.cos(adjusted_rotation.x)), 
		y =  math.cos(adjusted_rotation.z) * math.abs(math.cos(adjusted_rotation.x)), 
		z =  math.sin(adjusted_rotation.x)
	}
	return direction
end


function GET_OFFSET_FROM_CAM(distance)
	local cam_rot = CAM.GET_GAMEPLAY_CAM_ROT(0)
	local cam_pos = CAM.GET_GAMEPLAY_CAM_COORD()
	local direction = ROTATION_TO_DIRECTION(cam_rot)
	local destination = { 
		x = cam_pos.x + direction.x * distance, 
		y = cam_pos.y + direction.y * distance, 
		z = cam_pos.z + direction.z * distance 
	}
	return destination
end


function draw_debug_text(text)
	text = tostring(text)
	local content = ''
	for w in text:gmatch('[^;]+') do
		content = content .. w .. '\n'
	end
	directx.draw_text(0.05, 0.05, content, ALIGN_TOP_LEFT, 1.0, {['r'] = 1, ['g'] = 0, ['b'] = 0, ['a'] = 1}, false)
end


function RAYCAST_GAMEPLAY_CAM(distance, flag)
	local ptr1, ptr2, ptr3, ptr4 = alloc(), alloc(), alloc(), alloc()
	local cam_rot = CAM.GET_GAMEPLAY_CAM_ROT(0)
	local cam_pos = CAM.GET_GAMEPLAY_CAM_COORD()
	local direction = ROTATION_TO_DIRECTION(cam_rot)
	local destination = { 
		x = cam_pos.x + direction.x * distance, 
		y = cam_pos.y + direction.y * distance, 
		z = cam_pos.z + direction.z * distance 
	}
	SHAPETEST.GET_SHAPE_TEST_RESULT(
		SHAPETEST.START_EXPENSIVE_SYNCHRONOUS_SHAPE_TEST_LOS_PROBE(
			cam_pos.x, 
			cam_pos.y, 
			cam_pos.z, 
			destination.x, 
			destination.y, 
			destination.z, 
			flag or -1, 
			-1, 
			1
		), ptr1, ptr2, ptr3, ptr4
	)
	local hit, coords, nsurface, entity = memory.read_byte(ptr1), memory.read_vector3(ptr2), memory.read_vector3(ptr3), memory.read_int(ptr4)
	memory.free(ptr1); memory.free(ptr2); memory.free(ptr3); memory.free(ptr4)
	return hit, coords, nsurface, entity
end


function RAYCAST(cam, distance, flag)
	local ptr1, ptr2, ptr3, ptr4 = alloc(), alloc(), alloc(), alloc()
	local cam_rot = CAM.GET_CAM_ROT(cam, 2)
	local cam_pos = CAM.GET_CAM_COORD(cam)
	local direction = ROTATION_TO_DIRECTION(cam_rot)
	local destination = { 
		x = cam_pos.x + direction.x * distance, 
		y = cam_pos.y + direction.y * distance, 
		z = cam_pos.z + direction.z * distance 
	}
	SHAPETEST.GET_SHAPE_TEST_RESULT(
		SHAPETEST.START_EXPENSIVE_SYNCHRONOUS_SHAPE_TEST_LOS_PROBE(
			cam_pos.x, 
			cam_pos.y, 
			cam_pos.z, 
			destination.x, 
			destination.y, 
			destination.z, 
			flag or -1, 
			-1, 
			1
		), ptr1, ptr2, ptr3, ptr4
	)
	local hit, coords, nsurface, entity = memory.read_byte(ptr1), memory.read_vector3(ptr2), memory.read_vector3(ptr3), memory.read_int(ptr4)
	memory.free(ptr1); memory.free(ptr2); memory.free(ptr3); memory.free(ptr4)
	return hit, coords, nsurface, entity
end


function does_key_exists(table, key)
	for k, v in pairs(table) do
		if k == key then return true end
	end
	return false
end


function equals(l1, l2)
	if l1 == l2 then return true end
	local type1 = type(l1)
    local type2 = type(l2)
    if type1 ~= type2 then return false end
	if type1 ~= 'table' then return false end
	for k, v in pairs(l1) do
		if not l2[ k ] or not equals(v, l2[ k ]) then
			return false
		end
	end
	return true
end


function SET_ENTITY_COORDS_2(entity, coords) --used in teleport gun
	local addr = entities.handle_to_pointer(entity)
	local v = memory.read_long(addr + 0x30)
	memory.write_float(v + 0x50, coords.x)
	memory.write_float(v + 0x54, coords.y)
	memory.write_float(v + 0x58, coords.z)
	memory.write_float(addr + 0x90, coords.x)
	memory.write_float(addr + 0x94, coords.y)
	memory.write_float(addr + 0x98, coords.z)
end


INSTRUCTIONAL = {}
INSTRUCTIONAL.isKeyboard = PAD._IS_USING_KEYBOARD(2)

function INSTRUCTIONAL.DRAW(buttons, colour)
	if not equals(buttons, INSTRUCTIONAL.currentsettup) or INSTRUCTIONAL.isKeyboard ~= PAD._IS_USING_KEYBOARD(2) then
		local colour = colour or {
			['r'] = 0,
			['g'] = 0,
			['b'] = 0
		}

		INSTRUCTIONAL.scaleform = GRAPHICS.REQUEST_SCALEFORM_MOVIE('instructional_buttons')
		while not GRAPHICS.HAS_SCALEFORM_MOVIE_LOADED(INSTRUCTIONAL.scaleform) do
			wait()
		end
		
		GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(INSTRUCTIONAL.scaleform, 'CLEAR_ALL')
		GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

		GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(INSTRUCTIONAL.scaleform, 'TOGGLE_MOUSE_BUTTONS')
		GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_BOOL(true)
		GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

		for i = 1, #buttons do
			GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(INSTRUCTIONAL.scaleform, 'SET_DATA_SLOT')
			GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(i) --position
			GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_PLAYER_NAME_STRING(PAD.GET_CONTROL_INSTRUCTIONAL_BUTTON(2, buttons[i][2], true)) --control
			GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_TEXTURE_NAME_STRING(buttons[i][1]) --name
			GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_BOOL(buttons[i][3] or false) --clickable
			GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(buttons[i][2]) --what control will be pressed when you click the button
			GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
		end

		GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(INSTRUCTIONAL.scaleform, 'SET_BACKGROUND_COLOUR')
		GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(colour.r)
		GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(colour.g)
		GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(colour.b)
		GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(80)
		GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

		GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(INSTRUCTIONAL.scaleform, 'DRAW_INSTRUCTIONAL_BUTTONS')
		GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

		INSTRUCTIONAL.currentsettup = buttons
		INSTRUCTIONAL.isKeyboard = PAD._IS_USING_KEYBOARD(2)
	end
	GRAPHICS.DRAW_SCALEFORM_MOVIE_FULLSCREEN(INSTRUCTIONAL.scaleform, 255, 255, 255, 255, 0)
end


function DRAW_LOCKON_SPRITE_ON_PLAYER(pid, color)
	local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
	local mpos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
	local dist = vect.dist(pos, mpos)
	local max = 2000.0
	local delta = max - dist
	local mult = delta / max

	if dist > max then 
		mult = 0.0
	end

	if mult > 1.0 then
		mult = 1.0
	end

	local ptrx, ptry = alloc(), alloc()
	color = color or {['r'] = 255, ['g'] = 0, ['b'] = 0}
	
	GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT("helicopterhud", false)
	while not GRAPHICS.HAS_STREAMED_TEXTURE_DICT_LOADED("helicopterhud") do
		wait()
	end
	
	--GRAPHICS.SET_DRAW_ORIGIN(pos.x, pos.y, pos.z, 0)
	GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(pos.x, pos.y, pos.z, ptrx, ptry)
	local posx = memory.read_float(ptrx); memory.free(ptrx)
	local posy = memory.read_float(ptry); memory.free(ptry)
	GRAPHICS.DRAW_SPRITE("helicopterhud", "hud_outline", posx, posy, mult * 0.03 * 1.5, mult * 0.03 * 2.6, 90.0, color.r, color.g, color.b, 255, true)
end


function IS_PLAYER_FRIEND(pid)
	local ptr = alloc(76)
	NETWORK.NETWORK_HANDLE_FROM_PLAYER(pid, ptr, 13)
	if NETWORK.NETWORK_IS_HANDLE_VALID(ptr, 13) then
		return NETWORK.NETWORK_IS_FRIEND(ptr)
	end
end


function DRAW_STRING(s, x, y, scale, font)
	HUD.BEGIN_TEXT_COMMAND_DISPLAY_TEXT('STRING')
	HUD.SET_TEXT_FONT(font or 0)
	HUD.SET_TEXT_SCALE(scale, scale)
	HUD.SET_TEXT_DROP_SHADOW()
	HUD.SET_TEXT_WRAP(0.0, 1.0)
	HUD.SET_TEXT_DROPSHADOW(1, 0, 0, 0, 0)
	HUD.SET_TEXT_OUTLINE()
	HUD.SET_TEXT_EDGE(1, 0, 0, 0, 0)
	HUD.SET_TEXT_OUTLINE()
	HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(s)
	HUD.END_TEXT_COMMAND_DISPLAY_TEXT(x, y)
end


function REQUEST_MODEL(modelHash)
	STREAMING.REQUEST_MODEL(modelHash)
	while not STREAMING.HAS_MODEL_LOADED(modelHash) do
		wait()
	end
end


function GET_GROUND_Z_FOR_3D_COORD(pos)
	local ptr = alloc()
	MISC.GET_GROUND_Z_FOR_3D_COORD(pos.x, pos.y, pos.z, ptr, false)
	local groundz = memory.read_float(ptr); memory.free(ptr)
	return groundz
end


function GET_VEHICLE_PLAYER_IS_IN(pId)
	local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pId)
	local vehicle = PED.GET_VEHICLE_PED_IS_IN(p, false)
	return vehicle
end


function DISPLAY_ONSCREEN_KEYBOARD(windowName, maxInput, defaultText)
	MISC.DISPLAY_ONSCREEN_KEYBOARD(0, windowName, "", defaultText, "", "", "", maxInput);
	while MISC.UPDATE_ONSCREEN_KEYBOARD() == 0 do
		wait()
	end
	if not MISC.GET_ONSCREEN_KEYBOARD_RESULT() then
		return ""
	end
	return MISC.GET_ONSCREEN_KEYBOARD_RESULT()
end


function firstUpper(txt)
	return tostring(txt):gsub("^%l", string.upper)
end


colour = {
	['new'] = function(r, g, b, a)
		return {['r'] = r, ['g'] = g, ['b'] = b, ['a'] = a or 255}
	end,
	['mult'] = function(colour, n)
		local result =  {
			['r'] = round(colour.r * n),
			['g'] = round(colour.g * n),
			['b'] = round(colour.b * n),
			['a'] = round(colour.a * n)
		}
		return result
	end,
	['div'] = function(colour, n)
		local result = {
			['r'] = colour.r / n,
			['g'] = colour.g / n,
			['b'] = colour.b / n,
			['a'] = colour.a / n
		}
		return result
	end
}


function GET_USER_VEHICLE_MODEL()
	local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), true)
	if vehicle ~= 0 then
		return ENTITY.GET_ENTITY_MODEL(vehicle)
	end
end


function GET_USER_VEHICLE_NAME()
	local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), true)
	if vehicle ~= 0 then
		local model = ENTITY.GET_ENTITY_MODEL(vehicle)
		return HUD._GET_LABEL_TEXT(VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(model)), model
	else
		return '???'
	end
end


function IS_THIS_MODEL_AN_AIRCRAFT(model)
	return VEHICLE.IS_THIS_MODEL_A_HELI(model) or VEHICLE.IS_THIS_MODEL_A_PLANE(model)
end

-------------------------------------
--INTRO
-------------------------------------

local function ADD_TEXT_TO_SINGLE_LINE(scaleform, text, font, colour)
	GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, 'ADD_TEXT_TO_SINGLE_LINE')
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_TEXTURE_NAME_STRING('presents')
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_TEXTURE_NAME_STRING(text)
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_TEXTURE_NAME_STRING(font)
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_TEXTURE_NAME_STRING(colour)
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_BOOL(true)
	GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
end


local function HIDE(scaleform)
	GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "HIDE")
	GRAPHICS.BEGIN_TEXT_COMMAND_SCALEFORM_STRING("STRING")
	HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME('presents')
	GRAPHICS.END_TEXT_COMMAND_SCALEFORM_STRING()
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(0.16)
	GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
end


local function SETUP_SINGLE_LINE(scaleform)
	GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, 'SETUP_SINGLE_LINE')
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_TEXTURE_NAME_STRING('presents')
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(0.5)
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(0.5)
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(70)
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(125)
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_TEXTURE_NAME_STRING('left')
	GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
end


if SCRIPT_MANUAL_START then
	showing_intro = true
	AUDIO.PLAY_SOUND_FROM_ENTITY(-1, "clown_die_wrapper", PLAYER.PLAYER_PED_ID(), "BARRY_02_SOUNDSET", true, 20)

	util.create_thread(function()
		local state = 0
		local ctime = util.current_time_millis
		local stime = ctime()

		while true do
			wait()
			local scaleform = GRAPHICS.REQUEST_SCALEFORM_MOVIE('OPENING_CREDITS')
			
			while not GRAPHICS.HAS_SCALEFORM_MOVIE_LOADED(scaleform) do
				wait()
			end

			if state == 0 then
				SETUP_SINGLE_LINE(scaleform)

				ADD_TEXT_TO_SINGLE_LINE(scaleform, 'a', '$font5', 'HUD_COLOUR_FRANKLIN')
				ADD_TEXT_TO_SINGLE_LINE(scaleform, 'nowiry', '$font2', 'HUD_COLOUR_WHITE')
				ADD_TEXT_TO_SINGLE_LINE(scaleform, 'production', '$font5', 'HUD_COLOUR_FRANKLIN')

				GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, 'SHOW_SINGLE_LINE')
				GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_TEXTURE_NAME_STRING('presents')
				GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

				GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, 'SHOW_CREDIT_BLOCK')
				GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_TEXTURE_NAME_STRING('presents')
				GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(0.5)
				GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

				AUDIO.PLAY_SOUND_FROM_ENTITY(-1, 'Pre_Screen_Stinger', PLAYER.PLAYER_PED_ID(), 'DLC_HEISTS_FINALE_SCREEN_SOUNDS', true, 20)
				state = 1
				stime = ctime()
			end

			if ctime() - stime >= 4000 and state == 1 then
				HIDE(scaleform)
				state = 2
				stime = ctime()
			end

			if ctime() - stime >= 3000 and state == 2 then
				SETUP_SINGLE_LINE(scaleform)
				ADD_TEXT_TO_SINGLE_LINE(scaleform, 'wiriscript', '$font2', 'HUD_COLOUR_TREVOR')
				ADD_TEXT_TO_SINGLE_LINE(scaleform, 'v'..version, '$font5', 'HUD_COLOUR_WHITE')
				
				GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, 'SHOW_SINGLE_LINE')
				GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_TEXTURE_NAME_STRING('presents')
				GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

				GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, 'SHOW_CREDIT_BLOCK')
				GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_TEXTURE_NAME_STRING('presents')
				GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(0.5)
				GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

				AUDIO.PLAY_SOUND_FROM_ENTITY(-1, 'SPAWN', PLAYER.PLAYER_PED_ID(), 'BARRY_01_SOUNDSET', true, 20)
				state = 3
				stime = ctime()
			end

			if ctime() - stime >= 4000 and state == 3 then
				HIDE(scaleform)
				state = 4
				stime = ctime()
			end

			if ctime() - stime >= 3000 and state == 4 then
				showing_intro = false
				break
			end

			GRAPHICS.DRAW_SCALEFORM_MOVIE_FULLSCREEN(scaleform, 255, 255, 255, 255, 0)
		end
	end)
end

	
-------------------------------------
--SETTINGS
-------------------------------------

local settings = menu.list(menu.my_root(), 'Settings', {'settings'}, '')

menu.divider(settings, 'Settings' )


menu.action(settings, menuname('Settings', 'Save Settings'), {}, '', function()
	ini.save(config_file, config)
	notification.normal('Configuration saved')
end)


-------------------------------------
--LANGUAGE
-------------------------------------


local language_settings = menu.list(settings, 'Language')

menu.divider(language_settings, 'Language')


menu.action(language_settings, 'Create New Translation', {}, 'Creates a file you can use to make a new WiriScript translation', function()
	local file = wiridir .. 'new translation.json'
	local content = json.stringify(features, nil, 4)
	file = io.open(file, 'w')
	file:write(content)
	file:close()
	notification.normal('File: new translation.json was created')
end)


if general_config.language ~= 'english' then
	menu.action(language_settings, 'Update Translation', {}, 'Creates an updated translation file that has all the missing features', function()
		for section, t in pairs(menunames) do
			if not features[ section ] then
				menunames[ section ] = nil
			else
				for k, name in pairs(t) do
					if not does_key_exists(features[ section ], k) then t[ k ] = nil end
				end
			end
		end
		local file = wiridir .. general_config.language .. ' (update).json'
		local content = json.stringify(menunames, nil, 4)
		file = io.open(file, 'w')
		file:write(content)
		file:close()
		notification.normal('File: '..general_config.language..' (update).json, was created')
	end)
end

menu.divider(language_settings, '°°°')


if general_config.language ~= 'english' then
	local actionId
	actionId = menu.action(language_settings, 'English', {}, '', function()
		general_config.language = 'english'
		ini.save(config_file, config)
		menu.show_warning(actionId, CLICK_MENU, 'Would you like to restart the script now?', function()
			util.stop_script()
		end)
	end)
end


for i, path in ipairs(filesystem.list_files(languagedir)) do
	local filename, ext = string.match(path, '^.+\\(.+)%.(.+)$')
	if ext == 'json' and general_config.language ~= filename then
		local actionId
		actionId = menu.action(language_settings, firstUpper(filename), {}, '', function()
			general_config.language = filename
			ini.save(config_file, config)
            menu.show_warning(actionId, CLICK_MENU, 'Would you like to restart the script now?', function()
                util.stop_script()	
            end)
		end)
	end
end


menu.toggle(settings, menuname('Settings', 'Display Health Text'), {'displayhealth'}, 'If health is going to be displayed while using Mod Health', function(toggle)
	general_config.displayhealth = toggle
end, general_config.displayhealth)


local healthtxt = menu.list(settings, menuname('Settings', 'Health Text Position'), {}, '')
local _x, _y =  directx.get_client_size()

menu.slider(healthtxt, 'X', {'healthx'}, '', 0, _x, round(_x * config.healthtxtpos['x']) , 1, function(x)
	config.healthtxtpos['x'] = round(x/_x, 4)
end)

menu.slider(healthtxt, 'Y', {'healthy'}, '', 0, _y, round(_y * config.healthtxtpos['y']), 1, function(y)
	config.healthtxtpos['y'] = round(y/_y, 4)
end)


menu.toggle(settings, menuname('Settings', 'Stand Notifications'), {'standnotifications'}, 'Turns to Stand\'s notification appearance', function(toggle)
	general_config.standnotifications = toggle
end, general_config.standnotifications)


-------------------------------------
--CONTROLS
-------------------------------------

local control_settings = menu.list(settings, menuname('Settings', 'Controls') , {}, '')

menu.divider(control_settings, menuname('Settings', 'Controls'))


local airstrike_plane_control = menu.list(control_settings, menuname('Settings - Controls', 'Airstrike Aircraft'), {}, '')
for name, imput in pairs(imputs) do
	local list = {}
	for w in string.gmatch(imput.control, '[^|]+') do table.insert(list, w) end
	local strg = "Keyboard: "..list[1]..", Controller: "..list[2]
	menu.action(airstrike_plane_control, strg, {}, "", function()
		control_config.airstrikeaircraft = imput.index
		util.show_corner_help(('~%s~'):format(name) .. ' to use Airstrike Aircraft')
	end)
end


local vehicle_weapons_control = menu.list(control_settings, menuname('Settings - Controls', 'Vehicle Weapons'), {}, '')

for name, imput in pairs(imputs) do
	local list = {}
	for w in string.gmatch(imput.control, '[^|]+') do table.insert(list, w) end
	local strg = "Keyboard: " .. list[1] .. ", Controller: " .. list[2]
	menu.action(vehicle_weapons_control, strg, {}, "", function()
		control_config.vehicleweapons = imput.index
		util.show_corner_help(('~%s~'):format(name) .. ' to use Vehicle Weapons')
	end)
end


local function check_loaded_controls()
	for option, index in pairs(config.controls) do
		for name, imput in pairs(imputs) do
			if index == imput.index then return	end
		end
		control_config[option] = 86	
	end
	ini.save(config_file, config)
	ini.load(config_file)
end

check_loaded_controls()


menu.toggle(settings, menuname('Settings', 'Disable Lock-On Sprites'), {}, 'Disables the boxes that UFO draws on players. ', function(toggle)
	general_config.disablelockon = toggle
end, general_config.disablelockon)


menu.toggle(settings, menuname('Settings', 'Disable Vehicle Gun Preview'), {}, '', function(toggle)
	general_config.disablepreview = toggle
end, general_config.disablepreview)


-------------------------------------
--HANDLING EDITOR CONFIG
-------------------------------------

local onfocuscolour = colour.div(config.onfocuscolour, 255)
local highlightcolour = colour.div(config.highlightcolour, 255)
local buttonscolour = colour.div(config.buttonscolour, 255)

local handling_editor_settings = menu.list(settings, menuname('Settings', 'Handling Editor'), {}, '')

menu.divider(handling_editor_settings, menuname('Settings', 'Handling Editor'))


menu.colour(handling_editor_settings, menuname('Settings - Handling Editor', 'Focused Text Colour'), {'onfocuscolour'}, '', onfocuscolour, false, function(new)
	onfocuscolour = new
	config.onfocuscolour = colour.mult(new, 255)
end)

menu.colour(handling_editor_settings, menuname('Settings - Handling Editor', 'Highlight Colour'), {'highlightcolour'}, '', highlightcolour, false, function(new)
	highlightcolour = new
	config.highlightcolour = colour.mult(new, 255)
end)

menu.colour(handling_editor_settings, menuname('Settings - Handling Editor', 'Buttons Colour'), {'buttonscolour'}, '', buttonscolour, false, function(new)
	buttonscolour = new
	config.buttonscolour = colour.mult(new, 255)
end)

-------------------------------------

menu.toggle(settings, menuname('Settings', 'Busted Features'), {}, 'Allows you to use some previously removed features', function(toggle)
	general_config.bustedfeatures = toggle
	if general_config.bustedfeatures then
		util.show_corner_help('Busted features were previously removed because they are now limited/not working as expected, keep that in mind when you use them. Please restart WiriScript to commit changes.')
		ini.save(config_file, config)
	end
end, general_config.bustedfeatures)

-------------------------------------
--SPOOFING PROFILE
-------------------------------------

local usingprofile = false
local profiles_list = {}

local profiles_root = menu.list(menu.my_root(), menuname('Spoofing Profile', 'Spoofing Profile'), {'profiles'}, '')

function add_profile(table)
	local name = table.name
	local rid = table.rid

	local profile_actions = menu.list(profiles_root, name, {'profile' .. name}, '')

	menu.divider(profile_actions, name)

	menu.action(profile_actions, menuname('Spoofing Profile - Profile', 'Enable Spoofing Profile'), {'enable'..name}, '', function()
		usingprofile = true 
		if spoofname then
			menu.trigger_commands('spoofedname ' .. name)
			menu.trigger_commands('spoofname on')
		end
		if spoofrid then
			menu.trigger_commands('spoofedrid ' .. rid)
			menu.trigger_commands('spoofrid hard')
		end
	end)

	menu.action(profile_actions, menuname('Spoofing Profile - Profile', 'Delete'), {}, '', function()
		os.remove(wiridir .. '\\profiles\\' .. name .. '.json')
		for k, profile in ipairs(profiles_list) do
			if profile == table then 
				restore_profile = menu.action(recycle_bin, name, {}, 'Click to restore', function()
					save_profile(profile)
					menu.delete(restore_profile)
				end)	
				profiles_list[k] = nil 
			end
		end
		notification.normal('Profile moved to recycle bin')
		menu.delete(profile_actions)
	end)
	
	menu.divider(profile_actions, menuname('Spoofing Profile - Profile', 'Spoofing Options') )
	
	menu.toggle(profile_actions, menuname('Spoofing Profile - Profile', 'Name'), {}, '', function(on)
		spoofname = on
	end, true)

	menu.toggle(profile_actions, menuname('Spoofing Profile - Profile', 'SCID')..' '..rid, {}, '', function(on)
		spoofrid = on
	end, true)
end


function save_profile(profile)
	for k, table in pairs(profiles_list) do
		if table.name == profile.name or table.rid == profile.rid then
			return false
		end
	end
	table.insert(profiles_list, profile)
	local file = io.open(wiridir .. '\\Profiles\\' .. profile.name .. '.json', 'w')
	local content = json.stringify(profile, nil, 4)
	file:write(content)
	file:close()
	add_profile(profile)
	return true
end


menu.action(profiles_root, menuname('Spoofing Profile', 'Disable Spoofing Profile'), {'disableprofile'}, '', function()
	if usingprofile then 
		menu.trigger_commands('spoofname off; spoofrid off')
		usingprofile = false
	else
		notification.red('You are not using any spoofing profile')
	end
end)


if filesystem.exists(wiridir .. '\\profiles.data') then
	local profiles_data = (wiridir .. '\\profiles.data')
	for line in io.lines(profiles_data) do
		local profile = json.parse(line)	
		save_profile(profile)
		table.insert(profiles_list, profile)
	end
	os.remove(profiles_data)
end

-------------------------------------
--ADD SPOOFING PROFILE
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
		return notification.red('Name and SCID are required')
	end
	local profile = {['name'] = newname, ['rid'] = newrid}
	if save_profile(profile) then
		notification.normal('Spoofing profile created')
	else
		notification.red('Spoofing profile already exists')
	end
end)


recycle_bin = menu.list(profiles_root, menuname('Spoofing Profile', 'Recycle Bin'), {}, 'Temporary stores the deleted profiles. Profiles are permanetly erased when the script stops.')

menu.divider(profiles_root, menuname('Spoofing Profile', 'Spoofing Profile') )


for i, path in ipairs(filesystem.list_files(wiridir .. '\\profiles')) do
	local filename, ext = string.match(path, '^.+\\(.+)%.(.+)$')
	if ext == "json" then
		local file = io.open(path, 'r')
		local content = file:read('a')
		file:close()
		if string.len(content) > 0 then
			local profile = json.parse(content, false)
			if profile.name and profile.rid ~= nil then
				table.insert(profiles_list, profile)
				add_profile(profile)
			end
		end
	else
		os.remove(path)
	end
end


GenerateFeatures = function(pid)
	
	menu.divider(menu.player_root(pid),'WiriScript')		
	
	-------------------------------------
	--CREATE SPOOFING PROFILE
	-------------------------------------

	menu.action(menu.player_root(pid), menuname('Player', 'Create Spoofing Profile'), {}, '', function()
		local profile = {
			['name'] = PLAYER.GET_PLAYER_NAME(pid),
			['rid'] = players.get_rockstar_id(pid)
		}
		if save_profile(profile) then
			notification.normal('Spoofing profile created')
		else
			notification.red('Spoofing profile already exists')
		end
	end)


	-------------------------------------
	--EXPLOSIONS
	-------------------------------------

	local trolling_list = menu.list(menu.player_root(pid), menuname('Player', 'Trolling & Griefing'), {}, '')		


	local explo_settings = menu.list(trolling_list, menuname('Trolling', 'Custom Explosion'), {}, '')
	
	menu.divider(explo_settings, menuname('Trolling', 'Custom Explosion'))

	menu.slider(explo_settings, menuname('Trolling - Custom Explosion', 'Explosion Type'), {'explosion'},'', 0, 72, 0, 1, function(value)
		type = value
	end)
	
	menu.toggle(explo_settings, menuname('Trolling - Custom Explosion', 'Invisible'), {}, '', function(toggle)
		invisible = toggle
	end)

	menu. toggle(explo_settings, menuname('Trolling - Custom Explosion', 'Audible'), {}, '', function(toggle)
		audible = toggle
	end, true)
	
	menu.toggle(explo_settings, menuname('Trolling - Custom Explosion', 'Owned Explosions'), {}, '', function(toggle)
		owned = toggle
	end)
	
	menu.action(explo_settings, menuname('Trolling - Custom Explosion', 'Explode'), {'customexplode'}, '', function()
		EXPLODE(pid, type, owned)
	end)

	menu.slider(explo_settings, menuname('Trolling - Custom Explosion', 'Loop Delay'), {'delay'}, '', 50, 1000, 300, 10, function(value) --changes the speed of loop
		delay = value
	end)
	
	menu.toggle(explo_settings, menuname('Trolling - Custom Explosion', 'Explosion Loop'), {'customloop'}, '', function(toggle)
		explosion_loop = toggle
		while explosion_loop do
			EXPLODE(pid, type, owned)
			wait(delay)
		end
	end)

	menu.toggle_loop(trolling_list, menuname('Trolling', 'Water Loop'), {'waterloop'}, '', function()
		EXPLODE(pid, 13, false)
	end)


	-------------------------------------
	--KILL AS THE ORBITAL CANNON
	-------------------------------------

	menu.action(trolling_list, menuname('Trolling', 'Kill as Orbital Cannon'), {'orbital'}, '', function()
		local countdown = 3
		if players.is_in_interior(pid) then
			return notification.red('The player is in interior')
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
		CAM.RENDER_SCRIPT_CAMS(true, false, 3000, true, false, 0)
		STREAMING.SET_FOCUS_POS_AND_VEL(pos.x, pos.y, pos.z, 5.0, 0.0, 0.0)
		GRAPHICS.SET_SCRIPT_GFX_DRAW_ORDER(1)
		GRAPHICS.SET_DRAW_ORIGIN(pos.x, pos.y, pos.z, 0)
		GRAPHICS.ANIMPOSTFX_PLAY('MP_OrbitalCannon', 0, true)
		wait(1000)
		CAM.DO_SCREEN_FADE_IN(0)

		local scaleform = GRAPHICS.REQUEST_SCALEFORM_MOVIE('ORBITAL_CANNON_CAM')
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

			GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, 'SET_STATE')
			GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(3)
			GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

			GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, 'SET_ZOOM_LEVEL')
			GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(1.0)
			GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

			GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, 'SET_CHARGING_LEVEL')
			GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(1.0)
			GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
			
			if countdown > 0 then
				if os.difftime(os.time(), startTime) == 1 then
					countdown = countdown - 1
					startTime = os.time()
				end
				GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, 'SET_COUNTDOWN')
				GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(countdown)
				GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
			else
				GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, 'SET_CHARGING_LEVEL')
				GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(0.0)
				GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

				local effect = {['asset'] = 'scr_xm_orbital', ['name'] = 'scr_xm_orbital_blast'}
		
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
				AUDIO.PLAY_SOUND_FROM_COORD(-1, 'DLC_XM_Explosions_Orbital_Cannon', pos.x, pos.y, pos.z, 0, true, 0, false)
				CAM.SHAKE_CAM(cam, "GAMEPLAY_EXPLOSION_SHAKE", 1.5)
				break
			end
			GRAPHICS.SET_SCRIPT_GFX_DRAW_ORDER(0)
			GRAPHICS.DRAW_SCALEFORM_MOVIE_FULLSCREEN(scaleform, 255, 255, 255, 255, 0)
			GRAPHICS.RESET_SCRIPT_GFX_ALIGN()
		end
		CAM.DO_SCREEN_FADE_OUT(500)
		wait(600)
		GRAPHICS.ANIMPOSTFX_STOP('MP_OrbitalCannon')
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


	menu.toggle_loop(trolling_list, menuname('Trolling', 'Flame Loop'), {'flameloop'}, '', function()
		EXPLODE(pid, 12, false)
	end)

	-------------------------------------
	--SHAKE CAMERA
	-------------------------------------

	menu.toggle_loop(trolling_list, menuname('Trolling', 'Shake Camera'), {'shake'}, '', function()
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
		FIRE.ADD_OWNED_EXPLOSION(PLAYER.PLAYER_PED_ID(), pos.x, pos.y, pos.z, 0, 0, false, true, 80)
		wait(150)
	end)

	-------------------------------------
	--ATTACKER OPTIONS
	-------------------------------------

	local attacker = {
		random_weapon = true,
		random_model = true
	}
	local attacker_options = menu.list(trolling_list, menuname('Trolling', 'Attacker Options'), {}, '')
	
	menu.divider(attacker_options, menuname('Trolling', 'Attacker Options'))


	menu.click_slider(attacker_options, menuname('Trolling - Attacker Options', 'Spawn Attacker'), {'attacker'}, '', 1, 15, 1, 1, function(quantity)
		local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		for i = 1, quantity do
			local pos = ENTITY.GET_ENTITY_COORDS(player_ped)
			local weapon, model
			
			pos.x = pos.x + math.random(-3, 3)
			pos.y = pos.y + math.random(-3, 3)
			pos.z = pos.z - 1.0
			
			if attacker.random_weapon then
				weapon = random(weapons)
			else 
				weapon = attacker.weapon 
			end
			
			if attacker.random_model then 
				model = random(peds) 
			else 
				model = attacker.model 
			end

			local modelHash, weaponHash = joaat(model), joaat(weapon)
			REQUEST_MODEL(modelHash)
			local ped = entities.create_ped(0, modelHash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z); insert_once(spawned_attackers, model)
			SET_ENT_FACE_ENT(ped, player_ped)
			WEAPON.GIVE_WEAPON_TO_PED(ped, weaponHash, 9999, true, true)
			ENTITY.SET_ENTITY_INVINCIBLE(ped, godmode)
			PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
			TASK.TASK_COMBAT_PED(ped, player_ped, 0, 16)
			PED.SET_PED_AS_ENEMY(ped, true)
			if stationary then PED.SET_PED_COMBAT_MOVEMENT(ped, 0) end
			PED.SET_PED_COMBAT_ATTRIBUTES(ped, 46, 1)
			set_relationship.hostile(ped)
			STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(modelHash)
			wait(100)
		end
	end)
	
	
	local ped_weapon_list = menu.list(attacker_options, menuname('Trolling - Attacker Options', 'Set Weapon')..': Random', {}, '')	
	
	menu.divider(ped_weapon_list, 'Attacker Weapon List')
	
	
	local ped_melee_list = menu.list(ped_weapon_list, 'Melee', {}, '')
	

	for k, weapon in pairs_by_keys(melee_weapons) do --creates the attacker melee weapon list
		menu.action(ped_melee_list, k, {}, '', function()
			attacker.random_weapon = false
			attacker.weapon = weapon
			menu.set_menu_name(ped_weapon_list, menuname('Trolling - Attacker Options', 'Set Weapon')..': '..k, {}, '')	
			menu.trigger_command(attacker_options, '')
		end)
	end
	

	menu.action(ped_weapon_list, 'Random Weapon', {}, '', function()
		attacker.random_weapon = true
		menu.set_menu_name(ped_weapon_list, menuname('Trolling - Attacker Options', 'Set Weapon')..': Random', {}, '')	
		menu.trigger_command(attacker_options, '')
	end)


	for k, weapon in pairs_by_keys(weapons) do --creates the attacker weapon list
		menu.action(ped_weapon_list, k, {}, '', function()
			attacker.random_weapon = false
			attacker.weapon = weapon
			menu.set_menu_name(ped_weapon_list, menuname('Trolling - Attacker Options', 'Set Weapon')..': '..k)
			menu.trigger_command(attacker_options, '')
		end)
	end

	local ped_list = menu.list(attacker_options, menuname('Trolling - Attacker Options', 'Set Model')..': Random', {}, '')

	menu.divider(ped_list, 'Attacker Model List')
	
	
	menu.action(ped_list, 'Random Model', {}, '', function()
		attacker.random_model = true
		menu.set_menu_name(ped_list, menuname('Trolling - Attacker Options', 'Set Model')..': Random')
		menu.trigger_command(attacker_options, '')
	end)


	for k, model in pairs_by_keys(peds) do --creates the attacker appearance list
		menu.action(ped_list, k, {}, '', function()
			attacker.random_model = false
			attacker.model = model
			menu.set_menu_name(ped_list, menuname('Trolling - Attacker Options', 'Set Model')..': '..k)
			menu.trigger_command(attacker_options, '')
		end)
	end


	menu.click_slider(attacker_options, menuname('Trolling - Attacker Options', 'Clone Player (Enemy)'), {'enemyclone'}, '', 1, 15, 1, 1, function(quantity)
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
		pos.z = pos.z - 1.0
		for i = 1, quantity do
			pos.x  = pos.x + math.random(-3, 3)
			pos.y = pos.y + math.random(-3, 3)
			local weapon
			if attacker.random_weapon then weapon = random(weapons) else weapon = attacker.weapon end
			local weapon_hash = joaat(weapon)
			local clone = PED.CLONE_PED(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid), 1, 1, 1); insert_once(spawned_attackers, 'mp_f_freemode_01'); insert_once(spawned_attackers, 'mp_m_freemode_01')
			WEAPON.GIVE_WEAPON_TO_PED(clone, weapon_hash, 9999, true, true)
			ENTITY.SET_ENTITY_COORDS(clone, pos.x, pos.y, pos.z)
			
			if read_global.byte(262145 + 4723) == 1 then --XMAS
				PED.SET_PED_PROP_INDEX(clone, 0, 22, 0, true)
			end
			
			ENTITY.SET_ENTITY_INVINCIBLE(clone, godmode)
			PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(clone, true)
			TASK.TASK_COMBAT_PED(clone, PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid), 0, 16)
			PED.SET_PED_COMBAT_ATTRIBUTES(clone, 46, 1)
			set_relationship.hostile(clone)
			if stationary then	PED.SET_PED_COMBAT_MOVEMENT(clone, 0) end
			wait(100)
		end
	end)


	menu.toggle(attacker_options, menuname('Trolling - Attacker Options', 'Stationary'), {}, '', function(toggle)
		stationary = toggle
	end)

	-------------------------------------
	--ENEMY CHOP
	-------------------------------------

	menu.action(attacker_options, menuname('Trolling - Attacker Options', 'Enemy Chop'), {'sendchop'}, '', function()
		local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(player_ped)
		pos.x  = pos.x + math.random(-3, 3)
		pos.y = pos.y + math.random(-3, 3)
		pos.z = pos.z - 1.0
		local ped_hash = joaat('a_c_chop')
		REQUEST_MODEL(ped_hash)
		local ped = entities.create_ped(28, ped_hash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z); insert_once(spawned_attackers, 'a_c_chop')
		ENTITY.SET_ENTITY_INVINCIBLE(ped, godmode)
		PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
		TASK.TASK_COMBAT_PED(ped, player_ped, 0, 16)
		PED.SET_PED_COMBAT_ATTRIBUTES(ped, 46, 1)
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(ped_hash)
		set_relationship.hostile(ped)
	end)

	-------------------------------------
	--SEND POLICE CAR
	-------------------------------------

	menu.action(attacker_options, menuname('Trolling - Attacker Options', 'Send Police Car'), {'sendpolicecar'}, '', function()
		local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(player_ped)
		local veh_hash = joaat('police3')
		local ped_hash = joaat('s_m_y_cop_01')
		STREAMING.REQUEST_MODEL(veh_hash); STREAMING.REQUEST_MODEL(ped_hash)
		while not STREAMING.HAS_MODEL_LOADED(veh_hash) or not STREAMING.HAS_MODEL_LOADED(ped_hash) do
			wait()
		end
		local coords_ptr = alloc()
		local nodeId = alloc()
		local coords
		local weapons = {'weapon_pistol', 'weapon_pumpshotgun'}
		if not PATHFIND.GET_RANDOM_VEHICLE_NODE(pos.x, pos.y, pos.z, 80, 0, 0, 0, coords_ptr, nodeId) then
			pos.x = pos.x + math.random(-20,20)
			pos.y = pos.y + math.random(-20,20)
			PATHFIND.GET_CLOSEST_VEHICLE_NODE(pos.x, pos.y, pos.z, coords_ptr, 1, 100, 2.5)
		end
		coords = memory.read_vector3(coords_ptr); memory.free(coords_ptr); memory.free(nodeId)
		local veh = entities.create_vehicle(veh_hash, coords, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
		SET_ENT_FACE_ENT(veh, player_ped)
		VEHICLE.SET_VEHICLE_SIREN(veh, true)
		AUDIO.BLIP_SIREN(veh)
		VEHICLE.SET_VEHICLE_ENGINE_ON(veh, true, true, true)
		ENTITY.SET_ENTITY_INVINCIBLE(veh, godmode)

		local function create_ped_into_vehicle(seat)
			local cop = entities.create_ped(5, ped_hash, coords, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
			PED.SET_PED_RANDOM_COMPONENT_VARIATION(cop, 0)
			WEAPON.GIVE_WEAPON_TO_PED(cop, joaat(random(weapons)) , -1, false, true)
			PED.SET_PED_NEVER_LEAVES_GROUP(cop, true)
			PED.SET_PED_COMBAT_ATTRIBUTES(cop, 1, true)
			PED.SET_PED_AS_COP(cop, true)
			PED.SET_PED_INTO_VEHICLE(cop, veh, seat)
			TASK.TASK_COMBAT_PED(cop, player_ped, 0, 16)
			ENTITY.SET_ENTITY_INVINCIBLE(cop, godmode)
			PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(cop, true)
			PED.SET_PED_KEEP_TASK(cop, true)
			return cop
		end

		for seat = -1, 0 do
			local cop = create_ped_into_vehicle(seat)
			util.create_thread(function()
				while ENTITY.GET_ENTITY_HEALTH(cop) > 0 do
					local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
					if PLAYER.IS_PLAYER_DEAD(pid) then
						while PLAYER.IS_PLAYER_DEAD(pid) do
							wait()
						end
						TASK.TASK_COMBAT_PED(cop, player_ped, 0, 16)
					end
					wait()
				end
			end)
		end
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(ped_hash); STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(veh_hash)
		AUDIO.PLAY_POLICE_REPORT('SCRIPTED_SCANNER_REPORT_FRANLIN_0_KIDNAP', 0.0)
	end)


	menu.toggle(attacker_options, menuname('Trolling - Attacker Options', 'Invincible Attackers'), {}, '', function(toggle)
		godmode = toggle
	end)


	menu.action(attacker_options, menuname('Trolling - Attacker Options', 'Delete Attackers'), {}, '', function()
		local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(p, false)
		for k, model in pairs(spawned_attackers) do
			DELETE_PEDS(model)
			spawned_attackers[k] = nil
		end
	end)

	-------------------------------------
	--CAGE OPTIONS
	-------------------------------------

	local cage_options = menu.list(trolling_list, menuname('Trolling', 'Cage'), {}, '')
	
	menu.divider(cage_options, menuname('Trolling', 'Cage'))


	local function vehicle_kick(pid)
		local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(player_ped) 
		if PED.IS_PED_IN_ANY_VEHICLE(player_ped, false) then
			menu.trigger_commands('freeze' .. PLAYER.GET_PLAYER_NAME(pid) .. ' on')
			wait(500)
			if PED.IS_PED_IN_ANY_VEHICLE(player_ped, false) then
				menu.trigger_commands('freeze' .. PLAYER.GET_PLAYER_NAME(pid) .. ' off')
				return false
			end
			menu.trigger_commands('freeze' .. PLAYER.GET_PLAYER_NAME(pid) .. ' off')
		end
		return true
	end
	

	menu.action(cage_options, menuname('Trolling - Cage', 'Small'), {'smallcage'}, '', function()
		if vehicle_kick(pid) then
			trapcage(pid)
		end
	end) 
	

	menu.action(cage_options, menuname('Trolling - Cage', 'Tall'), {'tallcage'}, '', function()
		if vehicle_kick(pid) then
			trapcage_2(pid)
		end
	end)

	-------------------------------------
	--AUTOMATIC
	-------------------------------------

	menu.toggle(cage_options, menuname('Trolling - Cage', 'Automatic'), {'autocage'}, '', function(toggle)
		cage_loop = toggle
		
		local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local a = ENTITY.GET_ENTITY_COORDS(p) --first position
		
		if cage_loop then
			if not vehicle_kick(pid) then return end
			trapcage(pid)
		end

		while cage_loop do
			local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
			local b = ENTITY.GET_ENTITY_COORDS(p) --current position
			if vect.dist(a, b) >= 4 then
				a = b
				if not PED.IS_PED_IN_ANY_VEHICLE(p, false) then
					trapcage(pid)
					notification.normal(PLAYER.GET_PLAYER_NAME(pid)..' '..'was out of the cage')
				end
			end
			wait(1000)
		end
	end)

	-------------------------------------
	--FENCE
	-------------------------------------

	menu.action(cage_options, menuname('Trolling - Cage', 'Fence'), {'fence'}, '', function()
		local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(player_ped)
		local object_hash = joaat('prop_fnclink_03e')
		pos.z = pos.z-1.0
		STREAMING.REQUEST_MODEL(object_hash)
		while not STREAMING.HAS_MODEL_LOADED(object_hash) do
			wait()
		end
		local object = {}
		object[1] = OBJECT.CREATE_OBJECT(object_hash, pos.x-1.5, pos.y+1.5, pos.z, true, true, true) 																			
		object[2] = OBJECT.CREATE_OBJECT(object_hash, pos.x-1.5, pos.y-1.5, pos.z, true, true, true)
		
		object[3] = OBJECT.CREATE_OBJECT(object_hash, pos.x+1.5, pos.y+1.5, pos.z, true, true, true) 	
		local rot_3  = ENTITY.GET_ENTITY_ROTATION(object[3])
		rot_3.z = -90
		ENTITY.SET_ENTITY_ROTATION(object[3], rot_3.x, rot_3.y, rot_3.z, 1, true)
		
		object[4] = OBJECT.CREATE_OBJECT(object_hash, pos.x-1.5, pos.y+1.5, pos.z, true, true, true) 	
		local rot_4  = ENTITY.GET_ENTITY_ROTATION(object[4])
		rot_4.z = -90
		ENTITY.SET_ENTITY_ROTATION(object[4], rot_4.x, rot_4.y, rot_4.z, 1, true)
		
		for key, obj in pairs(object) do
			ENTITY.FREEZE_ENTITY_POSITION(obj, true)
		end
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(object_hash)
	end)


	-------------------------------------
	--STUNT TUBE
	-------------------------------------

	menu.action(cage_options, menuname('Trolling - Cage', 'Stunt Tube'), {'stunttube'}, '', function()
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
		local hash = joaat('stt_prop_stunt_tube_s')
		REQUEST_MODEL(hash)
		local obj = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z, true, true, false)
		local rot = ENTITY.GET_ENTITY_ROTATION(obj)
		ENTITY.SET_ENTITY_ROTATION(obj, rot.x, 90.0, rot.z, 1, true)
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
	end)

	-------------------------------------
	--RAPE
	-------------------------------------

	if general_config.bustedfeatures then
		menu.toggle(trolling_list, menuname('Trolling - Rape', 'Rape'), {}, 'Busted feature.', function(on)
			rape = on
			if pid == players.user() then return end		
			if rape then
				piggyback = false
				local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
				local pos = ENTITY.GET_ENTITY_COORDS(p, false)
				STREAMING.REQUEST_ANIM_DICT('rcmpaparazzo_2')
				while not STREAMING.HAS_ANIM_DICT_LOADED('rcmpaparazzo_2') do
					wait()
				end
				TASK.TASK_PLAY_ANIM(PLAYER.PLAYER_PED_ID(), 'rcmpaparazzo_2', 'shag_loop_a', 8, -8, -1, 1, 0, false, false, false)
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
	end

	-------------------------------------
	--ENEMY VEHICLES
	-------------------------------------

	local minitank_godmode = false
	local enemy_vehicles = menu.list(trolling_list, menuname('Trolling', 'Enemy Vehicles'), {}, '')

	menu.divider(enemy_vehicles, menuname('Trolling - Enemy Vehicles', 'Minitank'))


	menu.click_slider(enemy_vehicles, menuname('Trolling - Enemy Vehicles', 'Send Minitank(s)'), {'sendminitank'}, '', 1, 25, 1, 1, function(quantity)
		local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(player_ped)
		local minitank_hash = joaat('minitank')
		local ped_hash = joaat('s_m_y_blackops_01')
		local weapon
		STREAMING.REQUEST_MODEL(minitank_hash); STREAMING.REQUEST_MODEL(ped_hash)
		while not STREAMING.HAS_MODEL_LOADED(minitank_hash) or not STREAMING.HAS_MODEL_LOADED(ped_hash) do
			wait()
		end
		for i = 1, quantity do
			local coords_ptr = alloc()
			local nodeId = alloc()
			local coords
			if not PATHFIND.GET_RANDOM_VEHICLE_NODE(pos.x, pos.y, pos.z, 80, 0, 0, 0, coords_ptr, nodeId) then
				pos.x = pos.x + math.random(-20,20)
				pos.y = pos.y + math.random(-20,20)
				PATHFIND.GET_CLOSEST_VEHICLE_NODE(pos.x, pos.y, pos.z, coords_ptr, 1, 100, 2.5)
				coords = memory.read_vector3(coords_ptr)
			end
			coords = memory.read_vector3(coords_ptr)
			memory.free(coords_ptr); memory.free(nodeId)
				--DOING THINGS WITH MINITANK
			local minitank = entities.create_vehicle(minitank_hash, coords, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
			ENTITY._SET_ENTITY_CLEANUP_BY_ENGINE(minitank, false)
			if not ENTITY.DOES_ENTITY_EXIST(minitank) then 
				notification.red('Failed to create vehicle. Please try again')
				return
			end
			ADD_BLIP_FOR_ENTITY(minitank, 742, 4)
			ENTITY.SET_ENTITY_INVINCIBLE(minitank, minitank_godmode)
			VEHICLE.SET_VEHICLE_MOD_KIT(minitank, 0)
			if random_minitank_weapon then
				local list = {}
				for k, v in pairs(modIndex) do 
					table.insert(list, v)
				end
				weapon = list[math.random(1, #list)] 
			else 
				weapon = minitank_weapon 
			end
			VEHICLE.SET_VEHICLE_MOD(minitank, 10, weapon, false) --GIVES THE SPECIFIED WEAPON TO VEHICLE
			VEHICLE.SET_VEHICLE_ENGINE_ON(minitank, true, true, true)
			SET_ENT_FACE_ENT(minitank, player_ped)
				--DOING THINGS WITH DRIVER
			local driver = entities.create_ped(5, ped_hash, coords, CAM.GET_GAMEPLAY_CAM_ROT(0).z)

			PED.SET_PED_COMBAT_ATTRIBUTES(driver, 1, true)
			PED.SET_PED_COMBAT_ATTRIBUTES(driver, 3, false)
			PED.SET_PED_INTO_VEHICLE(driver, minitank, -1)
			TASK.TASK_COMBAT_PED(driver, player_ped, 0, 0)
			PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(driver, true)
			ENTITY.SET_ENTITY_VISIBLE(driver, false, 0)

			util.create_thread(function()
				while not ENTITY.IS_ENTITY_DEAD(minitank) do
					if PLAYER.IS_PLAYER_DEAD(pid) then
						while PLAYER.IS_PLAYER_DEAD(pid) do
							wait()
						end
						PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(driver, false)
						TASK.TASK_COMBAT_PED(driver, PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid), 0, 0)
					end
					wait()
				end
			end)
			wait(150)
		end
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(ped_hash)
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(minitank_hash)
	end)


	menu.toggle(enemy_vehicles, menuname('Trolling - Enemy Vehicles', 'Invincible'), {}, '', function(toggle)
		minitank_godmode = toggle
	end)

	-------------------------------------
	--MINITANK WEAPON
	-------------------------------------

	local menu_minitank_weapon = menu.list(enemy_vehicles, menuname('Trolling - Enemy Vehicles', 'Minitank Weapon')..': Random', {}, '')

	menu.divider(menu_minitank_weapon, 'RC Tank Weapon')


	menu.action(menu_minitank_weapon, 'Random Weapon', {}, '', function()
		random_minitank_weapon = true
		menu.set_menu_name(menu_minitank_weapon, menuname('Trolling - Enemy Vehicles', 'Minitank Weapon')..': Random')
		menu.trigger_command(enemy_vehicles, '')
	end)


	for k, weapon in pairs_by_keys(modIndex) do
		menu.action(menu_minitank_weapon, k, {}, '', function()
			minitank_weapon = weapon
			random_minitank_weapon = false
			menu.set_menu_name(menu_minitank_weapon, menuname('Trolling - Enemy Vehicles', 'Minitank Weapon')..': '..k)
			menu.trigger_command(enemy_vehicles, '')
		end)
	end


	menu.action(enemy_vehicles, menuname('Trolling - Enemy Vehicles', 'Delete Minitank(s)'), {}, '', function()
		local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(p, false)
		DELETE_NEARBY_VEHICLES(pos, 'minitank', 1000.0)
	end)

	-------------------------------------
	--ENEMY BUZZARD
	-------------------------------------

	local buzzard_visible = true
	local gunner_weapon = 'weapon_combatmg'
	
	menu.divider(enemy_vehicles, menuname('Trolling - Enemy Vehicles', 'Buzzard'))


	menu.click_slider(enemy_vehicles, menuname('Trolling - Enemy Vehicles', 'Send Buzzard(s)'), {'sendbuzzard'}, '', 1, 5, 1, 1, function(quantity)
		local heli_hash = joaat('buzzard2')
		local ped_hash = joaat('s_m_y_blackops_01')
		local player_ped =  PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(player_ped)
		STREAMING.REQUEST_MODEL(ped_hash); STREAMING.REQUEST_MODEL(heli_hash)
		while not STREAMING.HAS_MODEL_LOADED(ped_hash) or not STREAMING.HAS_MODEL_LOADED(heli_hash) do
			wait()
		end
		local player_group_hash = PED.GET_PED_RELATIONSHIP_GROUP_HASH(player_ped)
		util.create_thread(function()
			PED.SET_RELATIONSHIP_BETWEEN_GROUPS(5, joaat('ARMY'), player_group_hash)
			PED.SET_RELATIONSHIP_BETWEEN_GROUPS(5, player_group_hash, joaat('ARMY'))
			PED.SET_RELATIONSHIP_BETWEEN_GROUPS(0, joaat('ARMY'), joaat('ARMY'))
		end)
		for i = 1, quantity do
			pos.x = pos.x + math.random(-20, 20)
			pos.y = pos.y + math.random(-20, 20)
			pos.z = pos.z + math.random(20, 40)
			local heli = entities.create_vehicle(heli_hash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
			if not ENTITY.DOES_ENTITY_EXIST(heli) then 
				notification.red('Failed to create vehicle. Please try again')
				return
			end
			ENTITY.SET_ENTITY_AS_MISSION_ENTITY(heli, true, true)
			ENTITY.SET_ENTITY_INVINCIBLE(heli, buzzard_godmode)
			ENTITY.SET_ENTITY_VISIBLE(heli, buzzard_visible, 0)	
			VEHICLE.SET_VEHICLE_ENGINE_ON(heli, true, true, true)
			VEHICLE.SET_HELI_BLADES_FULL_SPEED(heli)
			ADD_BLIP_FOR_ENTITY(heli, 422, 4)

			local function create_ped_into_vehicle(seat)
				local pedNetId = NETWORK.PED_TO_NET(entities.create_ped(29, ped_hash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z))
				if NETWORK.NETWORK_GET_ENTITY_IS_NETWORKED(NETWORK.NET_TO_PED(pedNetId)) then
					NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(pedNetId, true)
				end
				NETWORK.SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER(pedNetId, players.user(), true)
				local ped = NETWORK.NET_TO_PED(pedNetId)
				PED.SET_PED_INTO_VEHICLE(ped, heli, seat)
				WEAPON.GIVE_WEAPON_TO_PED(ped, joaat(gunner_weapon) , 9999, false, true)
				PED.SET_PED_COMBAT_ATTRIBUTES(ped, 20, true)
				PED.SET_PED_MAX_HEALTH(ped, 500)
				ENTITY.SET_ENTITY_HEALTH(ped, 500)
				ENTITY.SET_ENTITY_INVINCIBLE(ped, buzzard_godmode)
				ENTITY.SET_ENTITY_VISIBLE(ped, buzzard_visible, 0)
				PED.SET_PED_SHOOT_RATE(ped, 1000)
				PED.SET_PED_RELATIONSHIP_GROUP_HASH(ped, joaat('ARMY'))
				TASK.TASK_COMBAT_HATED_TARGETS_AROUND_PED(ped, 1000, 0)
				return pedNetId
			end

			local pilot = NETWORK.NET_TO_PED(create_ped_into_vehicle(-1))
			PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(pilot, true)
			
			for seat = 1, 2 do
				create_ped_into_vehicle(seat)
			end

			local function give_task_to_pilot(param0, param1)
				if param1 ~= param0 then
					if param0 == 0 then
						TASK.TASK_HELI_CHASE(pilot, player_ped, 0, 0, 50)
						PED.SET_PED_KEEP_TASK(pilot, true)
					end
					if param0 == 1 then
						TASK.TASK_HELI_MISSION(pilot, heli, 0, player_ped, 0.0, 0.0, 0.0, 23, 30.0, -1.0, -1.0, 10.0, 10.0, 5.0, 0)
						PED.SET_PED_KEEP_TASK(pilot, true)
					end
				end
				return param0
			end

			util.create_thread(function()
				local param0, param1
				while not ENTITY.IS_ENTITY_DEAD(pilot) do
					wait()
					local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
					local a, b = ENTITY.GET_ENTITY_COORDS(player_ped), ENTITY.GET_ENTITY_COORDS(heli)
					if MISC.GET_DISTANCE_BETWEEN_COORDS(a.x, a.y, a.z, b.x, b.y, b.z, true) > 90 then
						param0 = 0
					else
						param0 = 1
					end
					param1 = give_task_to_pilot(param0, param1)
				end
			end)
			STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(heli_hash)
			STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(ped_hash)
			wait(100)
		end
	end)

	
	menu.toggle(enemy_vehicles, menuname('Trolling - Enemy Vehicles', 'Invincible'), {}, '', function(toggle)
		buzzard_godmode = toggle
	end)
	

	local menu_gunner_weapon_list = menu.list(enemy_vehicles, menuname('Trolling - Enemy Vehicles', 'Gunners Weapon')..': Combat MG')
	
	menu.divider(menu_gunner_weapon_list, 'Gunners Weapon List')


	for k, weapon in pairs_by_keys(gunner_weapon_list) do
		menu.action(menu_gunner_weapon_list, k, {}, '', function()
			gunner_weapon = weapon
			menu.set_menu_name(menu_gunner_weapon_list, 'Gunner\'s Weapon: '..k)
			menu.trigger_command(enemy_vehicles, '')
		end)
	end


	menu.toggle(enemy_vehicles, menuname('Trolling - Enemy Vehicles', 'Visible'), {}, 'You shouldn\'t be that toxic to turn this off.', function(toggle)
		buzzard_visible = toggle
	end, true)
	
	-------------------------------------
	--DAMAGE
	-------------------------------------

	local function REQUEST_WEAPON_ASSET(hash)
		WEAPON.REQUEST_WEAPON_ASSET(hash, 31, 0)
		while not WEAPON.HAS_WEAPON_ASSET_LOADED(hash) do
			wait()
		end
		WEAPON.GIVE_WEAPON_TO_PED(PLAYER.PLAYER_PED_ID(), hash, 120, 1, 1)
		WEAPON.SET_CURRENT_PED_WEAPON(PLAYER.PLAYER_PED_ID(), hash, 1)
	end

	local damage = menu.list(trolling_list, menuname('Trolling', 'Damage'), {}, 'Choose the weapon and shoot \'em no matter where you are.')

	menu.divider(damage, menuname('Trolling', 'Damage'))
	
	menu.action(damage, menuname('Trolling - Damage', 'Heavy Sniper'), {}, '', function()
		local hash = joaat('weapon_heavysniper')
		local a = CAM.GET_GAMEPLAY_CAM_COORD()
		local b = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid), false)
		REQUEST_WEAPON_ASSET(hash)
		MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(a.x, a.y, a.z, b.x , b.y, b.z, 200, 0, hash, PLAYER.PLAYER_PED_ID(), true, false, 2500.0)
	end)

	menu.action(damage, menuname('Trolling - Damage', 'Firework'), {}, '', function()
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
		local hash = joaat('weapon_firework')
		REQUEST_WEAPON_ASSET(hash)
		MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z+3, pos.x , pos.y, pos.z-2, 200, 0, hash, 0, true, false, 2500.0)
	end)

	menu.action(damage, menuname('Trolling - Damage', 'Up-n-Atomizer'), {}, '', function()
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
		local hash = joaat('weapon_raypistol')
		REQUEST_WEAPON_ASSET(hash)
		MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z+3, pos.x , pos.y, pos.z-2, 200, 0, hash, 0, true, false, 2500.0)
	end)

	menu.action(damage, menuname('Trolling - Damage', 'Molotov'), {}, '', function()
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
		local hash = joaat('weapon_molotov')
		REQUEST_WEAPON_ASSET(hash)
		MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z, pos.x , pos.y, pos.z-2, 200, 0, hash, 0, true, false, 2500.0)
	end)

	menu.action(damage, menuname('Trolling - Damage', 'EMP Launcher'), {}, '', function()
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
		local hash = joaat('weapon_emplauncher')
		REQUEST_WEAPON_ASSET(hash)
		MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z, pos.x , pos.y, pos.z-2, 200, 0, hash, 0, true, false, 2500.0)
	end)

	-------------------------------------
	--HOSTILE PEDS
	-------------------------------------

	menu.action(trolling_list, menuname('Trolling', 'Hostile Peds'), {'hostilepeds'}, 'All on foot peds will combat player.', function()
		local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(player_ped)
		for k, ped in pairs(GET_NEARBY_PEDS(pid, 90)) do
			if not PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
				REQUEST_CONTROL_LOOP(ped)
				TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
				PED.SET_PED_COMBAT_ATTRIBUTES(ped, 46, true)
				PED.SET_PED_MAX_HEALTH(ped, 300)
				ENTITY.SET_ENTITY_HEALTH(ped, 300)
				WEAPON.GIVE_WEAPON_TO_PED(ped, joaat(random(weapons)), 9999, false, true)
				TASK.TASK_COMBAT_PED(ped, player_ped, 0, 0)
				WEAPON.SET_PED_DROPS_WEAPONS_WHEN_DEAD(ped, false)
				set_relationship.hostile(ped)
			end
		end
	end)

	-------------------------------------
	--HOSTILE TRAFFIC
	-------------------------------------

	menu.action(trolling_list, menuname('Trolling', 'Hostile Traffic'), {'hostiletraffic'}, '', function()
		local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
	
		for k, vehicle in pairs(GET_NEARBY_VEHICLES(pid, 250)) do	
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
	--TROLLY BANDITO
	-------------------------------------

	local bandito_godmode = false

	local trolly_vehicles = menu.list(trolling_list, menuname('Trolling', 'Trolly Vehicles'), {}, '')


	local function spawn_trolly_vehicle(pid, vehicleHash, pedHash)
		local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(player_ped)
		local coords_ptr, nodeId = alloc(), alloc()
		local coords
		
		if not PATHFIND.GET_RANDOM_VEHICLE_NODE(pos.x, pos.y, pos.z, 100, 0, 0, 0, coords_ptr, nodeId) then
			pos.x = pos.x + math.random(-20,20)
			pos.y = pos.y + math.random(-20,20)
			PATHFIND.GET_CLOSEST_VEHICLE_NODE(pos.x, pos.y, pos.z, coords_ptr, 1, 100, 2.5)
			coords = memory.read_vector3(coords_ptr)
		else
			coords = memory.read_vector3(coords_ptr)
		end
		memory.free(coords_ptr); memory.free(nodeId)

		local vehicle = entities.create_vehicle(vehicleHash, coords, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
		ENTITY.SET_ENTITY_AS_MISSION_ENTITY(vehicle, true, true)

		if not ENTITY.DOES_ENTITY_EXIST(vehicle) then
			local tick = 0
			while not ENTITY.DOES_ENTITY_EXIST(vehicle) and tick <= 10 do
				vehicle = entities.create_vehicle(vehicleHash, coords, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
				tick = tick + 1
				wait()
			end
		end
		
		VEHICLE.SET_VEHICLE_MOD_KIT(vehicle, 0)
		
		for i = 0, 50 do
			VEHICLE.SET_VEHICLE_MOD(vehicle, i, VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, i) - 1, false)
		end
		
		VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle, true, true, true)
		VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(vehicle, true)
		VEHICLE.SET_VEHICLE_IS_CONSIDERED_BY_PLAYER(vehicle, false)
		SET_ENT_FACE_ENT(vehicle, player_ped)

		local driver = entities.create_ped(5, pedHash, coords, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
		ENTITY.SET_ENTITY_AS_MISSION_ENTITY(driver, true, true)
		PED.SET_PED_COMBAT_ATTRIBUTES(driver, 1, true)
		PED.SET_PED_INTO_VEHICLE(driver, vehicle, -1)
		PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(driver, true)
		TASK.TASK_VEHICLE_MISSION_PED_TARGET(driver, vehicle, player_ped, 6, 500.0, 786988, 0.0, 0.0, true)
		SET_PED_CAN_BE_KNOCKED_OFF_VEH(driver, 1)
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(pedHash); STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(vehicleHash)
		return vehicle, driver
	end

	menu.divider(trolly_vehicles, 'Bandito')

	
	menu.click_slider(trolly_vehicles, menuname('Trolling - Trolly Vehicles', 'Send Bandito(s)'), {'sendbandito'}, '', 1,25,1,1, function(quantity)
		local bandito_hash = joaat('rcbandito')
		local ped_hash = joaat('mp_m_freemode_01')
		STREAMING.REQUEST_MODEL(bandito_hash)
		STREAMING.REQUEST_MODEL(ped_hash)
		while not STREAMING.HAS_MODEL_LOADED(bandito_hash) and not STREAMING.HAS_MODEL_LOADED(ped_hash) do
			wait()
		end
		for i = 1, quantity do
			local vehicle, driver = spawn_trolly_vehicle(pid, bandito_hash, ped_hash)
			ADD_BLIP_FOR_ENTITY(vehicle, 646, 4)
			ENTITY.SET_ENTITY_INVINCIBLE(vehicle, bandito_godmode)
			ENTITY.SET_ENTITY_VISIBLE(driver, false, 0)
			wait(150)
		end
	end)


	menu.toggle(trolly_vehicles, menuname('Trolling - Trolly Vehicles', 'Invincible'), {}, '', function(toggle)
		bandito_godmode = toggle
	end)


	menu.action(trolly_vehicles, menuname('Trolling - Trolly Vehicles', 'Send Explosive Bandito'), {'explobandito'}, '', function()
		local bandito_hash = joaat('rcbandito')
		local ped_hash = joaat('mp_m_freemode_01')
		STREAMING.REQUEST_MODEL(bandito_hash); STREAMING.REQUEST_MODEL(ped_hash)
		while not STREAMING.HAS_MODEL_LOADED(bandito_hash) and not STREAMING.HAS_MODEL_LOADED(ped_hash) do
			wait()
		end
		if not explosive_bandito_sent then
			explosive_bandito_sent = true
			local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
			local bandito = spawn_trolly_vehicle(pid, bandito_hash, ped_hash)
			VEHICLE.SET_VEHICLE_MOD(bandito, 5, 3, false)
			VEHICLE.SET_VEHICLE_MOD(bandito, 48, 5, false)
			VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(bandito, 128, 0, 128)
			VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(bandito, 128, 0, 128)
			ADD_BLIP_FOR_ENTITY(bandito, 646, 27)
			VEHICLE.ADD_VEHICLE_PHONE_EXPLOSIVE_DEVICE(bandito)
			util.create_thread(function()
				while not ENTITY.IS_ENTITY_DEAD(bandito) do
					wait()
					local a, b = ENTITY.GET_ENTITY_COORDS(p), ENTITY.GET_ENTITY_COORDS(bandito)
					if MISC.GET_DISTANCE_BETWEEN_COORDS(a.x, a.y, a.z, b.x, b.y, b.z, false) < 3 then
						VEHICLE.DETONATE_VEHICLE_PHONE_EXPLOSIVE_DEVICE() --NEW
					end
				end
				explosive_bandito_sent = false
			end)
		else
			notification.red('Explosive bandito already sent')
		end
	end)


	menu.action(trolly_vehicles, menuname('Trolling - Trolly Vehicles', 'Delete Bandito(s)'), {}, '', function()
		local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(p, false)
		DELETE_NEARBY_VEHICLES(pos, 'rcbandito', 1000.0)
	end)
	
	-------------------------------------
	--GO KART
	-------------------------------------

	local gokart_godmode = false
	menu.divider(trolly_vehicles, 'Go-Kart')


	menu.click_slider(trolly_vehicles, menuname('Trolling - Trolly Vehicles', 'Send Go-Kart(s)'), {'sendgokart'}, '',1, 15, 1, 1, function(quantity)
		local vehicleHash = joaat('veto2')
		local pedHash = joaat('mp_m_freemode_01')
		STREAMING.REQUEST_MODEL(vehicleHash)
		STREAMING.REQUEST_MODEL(pedHash)
		while not STREAMING.HAS_MODEL_LOADED(vehicleHash) and not STREAMING.HAS_MODEL_LOADED(pedHash) do
			wait()
		end
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
		DELETE_NEARBY_VEHICLES(pos, 'veto2', 1000.0)
	end)

	-------------------------------------
	--HOSTILE JET
	-------------------------------------

	menu.divider(enemy_vehicles, 'Lazer')

	menu.click_slider(enemy_vehicles, menuname('Trolling - Enemy Vehicles', 'Send Lazer(s)'), {'sendlazer'}, '', 1, 15, 1, 1, function(quantity)
		local jet_hash = joaat('lazer')
		local ped_hash = joaat('s_m_y_blackops_01')
		local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(player_ped)
		STREAMING.REQUEST_MODEL(jet_hash); STREAMING.REQUEST_MODEL(ped_hash)
		while not STREAMING.HAS_MODEL_LOADED(jet_hash) and not STREAMING.HAS_MODEL_LOADED(ped_hash) do
			wait()
		end
		for i = 1, quantity do
			pos.x = pos.x + math.random(-80, 80)
			pos.y = pos.y + math.random(-80, 80)
			pos.z = pos.z + math.random(500, 550)
			local pilot = entities.create_ped(5, ped_hash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
			if not ENTITY.DOES_ENTITY_EXIST(pilot) then
				local tick = 0
				while not ENTITY.DOES_ENTITY_EXIST(pilot) and tick <= 10 do
					pilot = entities.create_ped(5, ped_hash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
					tick = tick + 1
					wait()
				end
			end
				
			local jet = entities.create_vehicle(jet_hash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
			if not ENTITY.DOES_ENTITY_EXIST(jet) then
				local tick = 0
				while not ENTITY.DOES_ENTITY_EXIST(jet) and tick <= 10 do
					wait()
					jet = entities.create_vehicle(jet_hash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
					tick = tick + 1
				end
				entities.delete_by_handle(pilot)
			end
			ENTITY.SET_ENTITY_AS_MISSION_ENTITY(jet, true, true)
			SET_ENT_FACE_ENT(jet, player_ped)
			ADD_BLIP_FOR_ENTITY(jet, 16, 4)
			VEHICLE._SET_VEHICLE_JET_ENGINE_ON(jet, true)
			VEHICLE.SET_VEHICLE_FORWARD_SPEED(jet, 60)
			VEHICLE.CONTROL_LANDING_GEAR(jet, 3)
			ENTITY.SET_ENTITY_INVINCIBLE(jet, jet_godmode)
			VEHICLE.SET_VEHICLE_FORCE_AFTERBURNER(jet, true)
		
			PED.SET_PED_INTO_VEHICLE(pilot, jet, -1)
			TASK.TASK_PLANE_MISSION(pilot, jet, 0, player_ped, 0, 0, 0, 6, 100, 0, 0, 80, 50)
			PED.SET_PED_COMBAT_ATTRIBUTES(pilot, 1, true)
			set_relationship.hostile(pilot)
			wait(150)
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
		DELETE_NEARBY_VEHICLES(pos, 'lazer', 1000.0)
	end)

	-------------------------------------
	--RAM PLAYER
	-------------------------------------

	menu.click_slider(trolling_list, menuname('Trolling', 'Ram Player'), {'ram'}, '', 1, 3, 1, 1, function(value)
		local vehicles = {'insurgent2', 'phantom2', 'adder'}
		local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(player_ped)
		local theta = (math.random() + math.random(0, 1)) * math.pi --returns a random angle between 0 and 2pi (exclusive)
		local coord = vect.new(
			pos.x + 12 * math.cos(theta),
			pos.y + 12 * math.sin(theta),
			pos.z
		)
		local veh_hash = joaat(vehicles[value])
		STREAMING.REQUEST_MODEL(veh_hash)
		while not STREAMING.HAS_MODEL_LOADED(veh_hash) do
			wait()
		end
		local veh = entities.create_vehicle(veh_hash, coord, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
		SET_ENT_FACE_ENT(veh, player_ped)
		VEHICLE.SET_VEHICLE_DOORS_LOCKED(veh, 2)
		ENTITY.SET_ENTITY_LOAD_COLLISION_FLAG(veh, true)
		VEHICLE.SET_VEHICLE_FORWARD_SPEED(veh, 100)
	end)


	-------------------------------------
	--PIGGY BACK
	-------------------------------------

	if general_config.bustedfeatures then
		menu.toggle(trolling_list, menuname('Trolling', 'Piggy Back'), {}, 'Busted feature.', function(on)
			if pid == players.user() then return end
			piggyback = on

			if piggyback then
				rape = false
				local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
				local tick = 0
				STREAMING.REQUEST_ANIM_DICT('rcmjosh2')
				while not STREAMING.HAS_ANIM_DICT_LOADED('rcmjosh2') do
					wait()
				end
				ENTITY.ATTACH_ENTITY_TO_ENTITY(PLAYER.PLAYER_PED_ID(), p, PED.GET_PED_BONE_INDEX(p, 0xDD1C), 0, -0.2, 0.65, 0, 0, 180, false, true, false, false, 0, true)
				TASK.TASK_PLAY_ANIM(PLAYER.PLAYER_PED_ID(), 'rcmjosh2', 'josh_sitting_loop', 8, -8, -1, 1, 0, false, false, false)
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
	end
	-------------------------------------
	--RAIN ROCKETS
	-------------------------------------

	local function rain_rockets(pid, owned)
		local user_ped = PLAYER.PLAYER_PED_ID()
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
		local owner
		local hash = joaat('weapon_airstrike_rocket')
		if not WEAPON.HAS_WEAPON_ASSET_LOADED(hash) then
			WEAPON.REQUEST_WEAPON_ASSET(hash, 31, 0)
		end
		pos.x = pos.x + math.random(-6,6)
		pos.y = pos.y + math.random(-6,6)
		local ground_ptr = alloc(32); MISC.GET_GROUND_Z_FOR_3D_COORD(pos.x, pos.y, pos.z, ground_ptr, false, false); pos.z = memory.read_float(ground_ptr); memory.free(ground_ptr)
		if owned then owner = user_ped else owner = 0 end
		MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z+50, pos.x, pos.y, pos.z, 200, true, hash, owner, true, false, 2500.0)
	end


	menu.toggle(trolling_list, menuname('Trolling', 'Rain Rockets (owned)'), {'ownedrockets'}, '', function(toggle)
		rainRockets = toggle
		while rainRockets do
			rain_rockets(pid, true)
			wait(500)
		end
	end)


	menu.toggle(trolling_list, menuname('Trolling', 'Rain Rockets'), {'rockets'}, '', function(toggle)
		rainRockets = toggle
		while rainRockets do
			rain_rockets(pid, false)
			wait(500)
		end
	end)

	-------------------------------------
	--FORCEFIELD FOR OTHERS
	-------------------------------------

	menu.toggle_loop(trolling_list, menuname('Trolling', 'Forcefield'), {'forcefield'}, 'Push nearby entities away from player.', function()
		local a = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
		local entities = GET_NEARBY_ENTITIES(pid, 10)
		for k, entity in pairs(entities) do
			util.create_thread(function()
				local b = ENTITY.GET_ENTITY_COORDS(entity)
				local force = vect.norm(vect.subtract(b, a))
				if REQUEST_CONTROL(entity) then
					ENTITY.APPLY_FORCE_TO_ENTITY(entity, 1, force.x, force.y, force.z, 0, 0, 0.5, 0, false, false, true)
					if ENTITY.IS_ENTITY_A_PED(entity) and not PED.IS_PED_IN_ANY_VEHICLE(entity, true) then
						PED.SET_PED_TO_RAGDOLL(entity, 1000, 1000, 0, 0, 0, 0)
					end
				end
				util.stop_thread()
			end)
		end
	end)


	--Vector3 coords = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER::PLAYER_PED_ID(), 0.0f, 0.0f, 0.0f);
	--FIRE::ADD_EXPLOSION(coords.x, coords.y, coords.z, 7, FLT_MAX, FALSE, TRUE, 0.0f);

	-------------------------------------
	--KAMIKASE
	-------------------------------------

	menu.click_slider(trolling_list, menuname('Trolling', 'Kamikaze'), {'kamikaze'}, '', 1, 3, 1, 1, function(value)
		local planes = {'lazer', 'mammatus', 'cuban800'}
		local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(player_ped)
		local theta = (math.random() + math.random(0, 1)) * math.pi --returns a random angle between 0 and 2pi (exclusive)
		local coord = vect.new(
			pos.x + 20 * math.cos(theta),
			pos.y + 20 * math.sin(theta),
			pos.z + 30
		)
		local hash = joaat(planes[value])
		REQUEST_MODEL(hash)
		local plane = entities.create_vehicle(hash, coord, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
		SET_ENT_FACE_ENT_3D(plane, player_ped)
		ENTITY.SET_ENTITY_LOAD_COLLISION_FLAG(plane, true)
		VEHICLE.SET_VEHICLE_FORWARD_SPEED(plane, 150)
		VEHICLE.CONTROL_LANDING_GEAR(plane, 3)
	end)

	-------------------------------------
	--CREEPER CLOWN
	-------------------------------------

	menu.action(trolling_list, menuname('Trolling', 'Creeper Clown'), {}, '', function()
		local hash = joaat('s_m_y_clown_01')
		local explosion = {
			['asset'] = 'scr_rcbarry2',
			['name'] = 'scr_exp_clown'
		}
		local appears = {
			['asset'] = 'scr_rcbarry2',
			['name'] = 'scr_clown_appears'
		}
		AUDIO.REQUEST_SCRIPT_AUDIO_BANK("BARRY_02_CLOWN_A", false, -1)
		AUDIO.REQUEST_SCRIPT_AUDIO_BANK("BARRY_02_CLOWN_B", false, -1)
		AUDIO.REQUEST_SCRIPT_AUDIO_BANK("BARRY_02_CLOWN_C", false, -1)
		REQUEST_MODEL(hash)
		local player = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(player)
		local theta = (math.random() + math.random(0, 1)) * math.pi
		local coord = vect.new(
			pos.x + 7.0 * math.cos(theta),
			pos.y + 7.0 * math.sin(theta),
			pos.z - 1.0
		)
		local ped = entities.create_ped(0, hash, coord, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
		
		STREAMING.REQUEST_NAMED_PTFX_ASSET(appears.asset)
		while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(appears.asset) do
			wait()
		end
		GRAPHICS.USE_PARTICLE_FX_ASSET(appears.asset)
		GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_ON_ENTITY(appears.name, ped, 0.0, 0.0, -1.0, 0.0, 0.0, 0.0, 0.5, false, false, false, false)
		SET_ENT_FACE_ENT(ped, player)
		PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true) 
		
		-- yes, TASK_GO_TO_ENTITY and TASK_FOLLOW_TO_OFFSET_OF_ENTITY exist but for some reason the ped stops running when you use those
		TASK.TASK_GO_TO_COORD_ANY_MEANS(ped, pos.x, pos.y, pos.z, 5.0, 0, 0, 0, 0)
		local dest = pos
		PED.SET_PED_KEEP_TASK(ped, true)
		AUDIO.STOP_PED_SPEAKING(ped, true)
		AUDIO.SET_AMBIENT_VOICE_NAME(ped, "CLOWNS")
		
		create_tick_handler(function()
			local pos = ENTITY.GET_ENTITY_COORDS(ped)
			local ppos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))

			if vect.dist(pos, ppos) < 3.0 then
				STREAMING.REQUEST_NAMED_PTFX_ASSET(explosion.asset)
				while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(explosion.asset) do
					wait()
				end
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
	end)

	-------------------------------------
	--REMOTE VEHICLE OPTIONS
	-------------------------------------

	local vehicleOpt = menu.list(menu.player_root(pid), menuname('Vehicle', 'Vehicle'), {}, '')

	menu.divider(vehicleOpt, menuname('Vehicle', 'Vehicle'))
	
	-------------------------------------
	--TELEPORT
	-------------------------------------

	local tpvehicle = menu.list(vehicleOpt, menuname('Vehicle', 'Teleport'), {}, '')

	menu.divider(tpvehicle, menuname('Vehicle', 'Teleport'))

	menu.action(tpvehicle, menuname('Vehicle - Teleport', 'TP to Me'), {}, '', function()
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), false)
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle == 0 then return end
		REQUEST_CONTROL_LOOP(vehicle)
		ENTITY.SET_ENTITY_COORDS(vehicle, pos.x, pos.y, pos.z, false, false, false)
	end)

	menu.action(tpvehicle, menuname('Vehicle - Teleport', 'TP to Ocean'), {}, '', function()
		local pos = {x = -4809.93, y = -2521.67, z = 250}
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle == 0 then return end
		REQUEST_CONTROL_LOOP(vehicle)
		ENTITY.SET_ENTITY_COORDS(vehicle, pos.x, pos.y, pos.z, false, false, false)
	end)

	menu.action(tpvehicle, menuname('Vehicle - Teleport', 'TP to Prision'), {}, '', function()
		local pos = {x = 1680.11, y = 2512.89, z = 45.56}
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle == 0 then return end
		REQUEST_CONTROL_LOOP(vehicle)
		ENTITY.SET_ENTITY_COORDS(vehicle, pos.x, pos.y, pos.z, false, false, false)
	end)

	menu.action(tpvehicle, menuname('Vehicle - Teleport', 'TP to Fort Zancudo'), {}, '', function()
		local pos = {x = -2219.0583, y = 3213.0232, z = 32.8102}
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle == 0 then return end
		REQUEST_CONTROL_LOOP(vehicle)
		ENTITY.SET_ENTITY_COORDS(vehicle, pos.x, pos.y, pos.z, false, false, false)
	end)

	menu.action(tpvehicle, menuname('Vehicle - Teleport', 'TP to Waypoint'), {}, '', function()
		local ptr = alloc()
		local blip = HUD.GET_FIRST_BLIP_INFO_ID(8)
		if blip ~= 0 then
			local pos = HUD.GET_BLIP_COORDS(blip)
			local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
			if vehicle == 0 then return end
			REQUEST_CONTROL_LOOP(vehicle)
			ENTITY.SET_ENTITY_COORDS(vehicle, pos.x, pos.y, pos.z, false, false, false)
		else
			notification.red('No waypoint found')
		end
	end)

	-------------------------------------
	--ACROBATICS
	-------------------------------------

	local acrobatics = menu.list(vehicleOpt, menuname('Vehicle', 'Acrobatics'), {}, '')

	menu.divider(acrobatics, menuname('Vehicle', 'Acrobatics'))


	menu.action(acrobatics, menuname('Vehicle - Acrobatics', 'Ollie'), {}, '', function()
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle ~= 0 and VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(vehicle) then
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
		if vehicle ~= 0 and VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(vehicle) then
			REQUEST_CONTROL_LOOP(vehicle)
			ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, 0.0, 0.0, 21.43, 20.0, 0.0, 0.0, 1, false, true, true, true, true)
		end
	end)

	menu.action(acrobatics, menuname('Vehicle - Acrobatics', 'Heel Flip'), {}, '', function()
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle ~= 0 and VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(vehicle) then
			REQUEST_CONTROL_LOOP(vehicle)
			ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, 0.0, 0.0, 10.71, -5.0, 0.0, 0.0, 1, false, true, true, true, true)
		end
	end)

	-------------------------------------
	--KILL ENGINE
	-------------------------------------
	
	menu.action(vehicleOpt, menuname('Vehicle', 'Kill Engine'), {}, '', function()
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle == 0 then return end
		REQUEST_CONTROL_LOOP(vehicle)
		VEHICLE.SET_VEHICLE_ENGINE_HEALTH(vehicle, -4000)
	end)

	-------------------------------------
	--CLEAN
	-------------------------------------
	
	menu.action(vehicleOpt, menuname('Vehicle', 'Clean'), {}, '', function()
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle == 0 then return end
		REQUEST_CONTROL_LOOP(vehicle)
		VEHICLE.SET_VEHICLE_DIRT_LEVEL(vehicle, 0.0)
	end)


	-------------------------------------
	--REPAIR
	-------------------------------------

	menu.action(vehicleOpt, menuname('Vehicle', 'Repair'), {}, '', function()
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle == 0 then return end
		REQUEST_CONTROL_LOOP(vehicle)
		VEHICLE.SET_VEHICLE_FIXED(vehicle)
		VEHICLE.SET_VEHICLE_DEFORMATION_FIXED(vehicle)
		VEHICLE.SET_VEHICLE_DIRT_LEVEL(vehicle, 0.0)
	end)

	-------------------------------------
	--KICK
	-------------------------------------

	menu.action(vehicleOpt, menuname('Vehicle', 'Kick'), {}, '', function()
		local param = {578856274, PLAYER.PLAYER_ID(), 0, 0, 0, 0, 1, PLAYER.PLAYER_ID(), MISC.GET_FRAME_COUNT()}
		util.trigger_script_event(1 << pid, param)
	end)
	

	-------------------------------------
	--UPGRADE
	-------------------------------------

	menu.action(vehicleOpt, menuname('Vehicle', 'Upgrade'), {}, '', function()
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle == 0 then return end
		REQUEST_CONTROL_LOOP(vehicle)
		VEHICLE.SET_VEHICLE_MOD_KIT(vehicle, 0)
		for i = 0, 50 do
			VEHICLE.SET_VEHICLE_MOD(vehicle, i, VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, i) - 1, false)
		end
	end)

	-------------------------------------
	--BURST TIRES
	-------------------------------------
	
	menu.action(vehicleOpt, menuname('Vehicle', 'Burst Tires'), {}, '', function()
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle == 0 then return end
		REQUEST_CONTROL_LOOP(vehicle)
		VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(vehicle, true)
		for wheelId = 0, 7 do
			VEHICLE.SET_VEHICLE_TYRE_BURST(vehicle, wheelId, true, 1000.0)
		end
	end)

	-------------------------------------
	--CATAPULT
	-------------------------------------
	
	menu.action(vehicleOpt, menuname('Vehicle', 'Catapult'), {}, '', function()
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle ~= 0 and VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(vehicle) then
			REQUEST_CONTROL_LOOP(vehicle)
			ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, 0.0, 0.0, 9999, 0.0, 0.0, 0.0, 1, false, true, true, true, true)
		end	
	end)

	-------------------------------------
	--BOOST FORWARD
	-------------------------------------
	
	menu.action(vehicleOpt, menuname('Vehicle', 'Boost Forward'), {}, '', function()
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle == 0 then return end
		REQUEST_CONTROL_LOOP(vehicle)
		local unitv = ENTITY.GET_ENTITY_FORWARD_VECTOR(vehicle)
		local force = vect.mult(unitv, 30)
		AUDIO.SET_VEHICLE_BOOST_ACTIVE(vehicle, true)
		ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, force.x, force.y, force.z, 0.0, 0.0, 0.0, 1, false, true, true, true, true)
		AUDIO.SET_VEHICLE_BOOST_ACTIVE(vehicle, false)
	end)

	-------------------------------------
	--LICENSE PLATE
	-------------------------------------

	menu.text_input(vehicleOpt, menuname('Vehicle', 'Set License Plate'), {'setplatetxt'}, 'MAX 8 characters', function(strg)
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle == 0 or strg == '' then return end
		REQUEST_CONTROL_LOOP(vehicle)
		while #strg > 8 do -- reduces the length of string till it's 8 characters long
			wait()
			strg = string.gsub(strg, '.$', '')
		end
		VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(vehicle, strg)
	end)

	-------------------------------------
	--GOD MODE
	-------------------------------------
	
	menu.toggle(vehicleOpt, menuname('Vehicle', 'God Mode'), {}, '', function(toggle)
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle == 0 then return end
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
	--INVISIBLE
	-------------------------------------

	menu.toggle(vehicleOpt, menuname('Vehicle', 'Invisible'), {}, '', function(toggle)
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle == 0 then return end
		REQUEST_CONTROL_LOOP(vehicle)
		ENTITY.SET_ENTITY_VISIBLE(vehicle, not toggle, false)
	end)

	-------------------------------------
	--FREEZE
	-------------------------------------

	menu.toggle(vehicleOpt, menuname('Vehicle', 'Freeze'), {}, '', function(toggle)
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle == 0 then return end
		REQUEST_CONTROL_LOOP(vehicle)
		ENTITY.FREEZE_ENTITY_POSITION(vehicle, toggle)
	end)

	-------------------------------------
	--LOCK DOORS
	-------------------------------------

	menu.toggle(vehicleOpt, menuname('Vehicle', 'Child Lock'), {}, '', function(toggle)
		local vehicle = GET_VEHICLE_PLAYER_IS_IN(pid)
		if vehicle == 0 then return end
		REQUEST_CONTROL_LOOP(vehicle)
		if toggle then
			VEHICLE.SET_VEHICLE_DOORS_LOCKED(vehicle, 4)
		else
			VEHICLE.SET_VEHICLE_DOORS_LOCKED(vehicle, 1)
		end
	end)

	-------------------------------------
	--FRIENDLY OPTIONS
	-------------------------------------

	local friendly_list = menu.list(menu.player_root(pid), menuname('Player', 'Friendly Options'), {}, '')
	
	menu.divider(friendly_list, menuname('Player', 'Friendly Options'))

	-------------------------------------
	--KILL KILLERS
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

--END OF GENERATEFEATURES
end

local defaulthealth = ENTITY.GET_ENTITY_MAX_HEALTH(PLAYER.PLAYER_PED_ID())
local modded_health = defaulthealth

-------------------------------------
--SELF
-------------------------------------

local self_options = menu.list(menu.my_root(), menuname('Self', 'Self'), {'selfoptions'}, '')

-------------------------------------
--HEALTH OPTIONS
-------------------------------------

menu.toggle(self_options, menuname('Self', 'Mod Health'), {'modhealth'}, 'Changes your ped\'s max health. Some menus will tag you as modder. It returns to default max health when it\'s disabled.', function(toggle)
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

		if general_config.displayhealth then
			local strg = '~b~' .. 'HEALTH ' .. '~w~' .. tostring(ENTITY.GET_ENTITY_HEALTH(PLAYER.PLAYER_PED_ID()))
			DRAW_STRING(strg, config.healthtxtpos['x'], config.healthtxtpos['y'], 0.6, 4)	
		end
		return modhealth
	end)
end)


menu.slider(self_options, menuname('Self', 'Modded Health'), {'moddedhealth'}, 'Health will be modded with the given value.', 100, 9000,defaulthealth,50, function(value)
	modded_health = value
end)


menu.action(self_options, menuname('Self', 'Max Health'), {'maxhealth'}, '', function()
	ENTITY.SET_ENTITY_HEALTH(PLAYER.PLAYER_PED_ID(), PED.GET_PED_MAX_HEALTH(PLAYER.PLAYER_PED_ID()))
end)


menu.action(self_options, menuname('Self', 'Max Armour'), {'maxarmour'}, '', function()
	PED.SET_PED_ARMOUR(PLAYER.PLAYER_PED_ID(), 50)
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
--FORCEFIELD
-------------------------------------

menu.toggle_loop(self_options, menuname('Self', 'Forcefield'), {'forcefield'}, 'Push nearby entities away.', function()
	local pos1 = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
	local entities = GET_NEARBY_ENTITIES(PLAYER.PLAYER_ID(), 10)
	for k, entity in pairs(entities) do
		util.create_thread(function()
			local pos2 = ENTITY.GET_ENTITY_COORDS(entity)
			local force = vect.norm(vect.subtract(pos2, pos1))
			if REQUEST_CONTROL(entity) then
				ENTITY.APPLY_FORCE_TO_ENTITY(entity, 1, force.x, force.y, force.z, 0, 0, 0.5, 0, false, false, true)
				if ENTITY.IS_ENTITY_A_PED(entity) and not PED.IS_PED_IN_ANY_VEHICLE(entity, true) then
					PED.SET_PED_TO_RAGDOLL(entity, 1000, 1000, 0, 0, 0, 0)
				end
			end
			util.stop_thread()
		end)
	end
end)

-------------------------------------
--FORCE
-------------------------------------

menu.toggle(self_options, menuname('Self', 'Force'), {'jedimode'}, 'Use Force in nearby vehicles.', function(toggle)
	force = toggle	
	if force then
		util.show_corner_help('~INPUT_VEH_FLY_SELECT_TARGET_RIGHT~ ~INPUT_VEH_FLY_ROLL_RIGHT_ONLY~ to use Force.')
		local user_ped = PLAYER.PLAYER_PED_ID()
		local pos = ENTITY.GET_ENTITY_COORDS(user_ped)
		util.create_thread(function()
			local effect = {
				['asset'] = 'scr_ie_tw',
				['name'] = 'scr_impexp_tw_take_zone'
			}
			local colour = {
				['r'] = 128 / 255,
				['g'] = 0.0,
				['b'] = 128 / 255
			}
			
			STREAMING.REQUEST_NAMED_PTFX_ASSET(effect.asset)
			while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(effect.asset) do
				wait()
			end
			
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
--CARPET RIDE
-------------------------------------

local object
menu.toggle(self_options, menuname('Self', 'Carpet Ride'), {'carpetride'}, '', function(toggle)
	carpetride = toggle
	local hspeed = 0.2
	local vspeed = 0.2
	local user_ped = PLAYER.PLAYER_PED_ID()
	local pos = ENTITY.GET_ENTITY_COORDS(user_ped)
	local object_hash = joaat('p_cs_beachtowel_01_s')
	
	if carpetride then
		STREAMING.REQUEST_ANIM_DICT('rcmcollect_paperleadinout@')
		STREAMING.REQUEST_MODEL(object_hash)
		while not STREAMING.HAS_ANIM_DICT_LOADED('rcmcollect_paperleadinout@') and not STREAMING.HAS_MODEL_LOADED(object_hash) do
			wait()
		end
		TASK.CLEAR_PED_TASKS_IMMEDIATELY(user_ped)
		object = OBJECT.CREATE_OBJECT(object_hash, pos.x, pos.y, pos.z, true, true, true)
		ENTITY.ATTACH_ENTITY_TO_ENTITY(user_ped, object, 0, 0, -0.2, 1.0, 0, 0, 0, false, true, false, false, 0, true)
		ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(object, false, false)

		TASK.TASK_PLAY_ANIM(user_ped, 'rcmcollect_paperleadinout@', 'meditiate_idle', 8, -8, -1, 1, 0, false, false, false)
		util.show_corner_help('~INPUT_MOVE_UP_ONLY~ ~INPUT_MOVE_DOWN_ONLY~ ~INPUT_VEH_JUMP~ ~INPUT_DUCK~ to use Carpet Ride.\nPress ~INPUT_VEH_MOVE_UP_ONLY~ to move faster.')
		
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
--KILL KILLERS
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
--UNDEAD OFFRADAR
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
--TRAILS
-------------------------------------

local bones = {
	['L Hand'] = 0x49D9,
	['R Hand'] = 0xDEAD,
	['L Foot'] = 0x3779,
	['R Foot'] = 0xCC4D
}
local trails_colour = {
	['r'] = 255,
	['g'] = 0,
	['b'] = 68
}

local trails_options = menu.list(self_options, menuname('Self', 'Trails'))


menu.toggle(trails_options, menuname('Self - Trails', 'Toggle Trails'), {'toggletrails'}, '', function(toggle)
	trails = toggle
	local lastvehicle
	local minimum, maximum
	local effect = {['asset'] = 'scr_rcpaparazzo1', ['name'] = 'scr_mich4_firework_sparkle_spawn'}
	local effects = {}
	STREAMING.REQUEST_NAMED_PTFX_ASSET(effect.asset)
	while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(effect.asset) do
		wait()
	end
	create_tick_handler(function()	
		local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
		if vehicle == 0 then
			for k, boneId in pairs(bones) do
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
					1.2, --scale
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
				['left'] = {['x'] = minimum.x, ['y'] = minimum.y},			--BACK & LEFT
				['right'] = {['x'] = maximum.x, ['y'] = minimum.y}
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
					1.2, 
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
		wait()
		if os.time() - sTime == 1 then
			for i = 1, #effects do
				GRAPHICS.STOP_PARTICLE_FX_LOOPED(effects[i], 0)
				GRAPHICS.REMOVE_PARTICLE_FX(effects[i], 0)
				effects[i] = nil
			end
			sTime = os.time()
		end
	end

	for k, effect in pairs(effects) do
		GRAPHICS.STOP_PARTICLE_FX_LOOPED(effect, 0)
		GRAPHICS.REMOVE_PARTICLE_FX(effect, 0)
	end
end)


menu.rainbow(menu.colour(trails_options, menuname('Self - Trails', 'Colour'), {'trailcolour'}, '', {['r'] = 255/255, ['g'] = 0, ['b'] = 255/255, ['a'] = 1.0}, false, function(colour)
	trails_colour = colour
end))

-------------------------------------
--COMBUSTION MAN
-------------------------------------

menu.toggle(self_options, menuname('Self', 'Combustion Man'), {'combustionman'}, 'Shoot explosive ammo without aiming a weapon. If you think Oppressor MK2 is annoying, you haven\'t use it with this.', function(toggle)
	shootlazer = toggle

	if shootlazer then
		util.show_corner_help("Press ~INPUT_ATTACK~ to shoot using Combustion Man.")
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
--PROOFS
-------------------------------------

local proofs = {
	bullet = false,
	fire = false,
	explosion = false,
	collision = false,
	melee = false,
	steam = false,
	drown = false
}

local menu_self_proofs = menu.list(self_options, menuname('Self', 'Player Proofs'), {}, '')

menu.divider(menu_self_proofs, menuname('Self', 'Player Proofs'))


for proof, bool in pairs_by_keys(proofs) do
	menu.toggle(menu_self_proofs, menuname('Self - Proofs', ('%s'):format(proof:gsub("^%l", string.upper))), {}, '', function(toggle)
		proofs[ proof ] = toggle
		ENTITY.SET_ENTITY_PROOFS(PLAYER.PLAYER_PED_ID(), proofs.bullet, proofs.fire, proofs.explosion, proofs.collision, proofs.melee, proofs.steam, 1, proofs.drown)
	end)
end

create_tick_handler(function()
	if table.find(proofs, true) then
		ENTITY.SET_ENTITY_PROOFS(PLAYER.PLAYER_PED_ID(), proofs.bullet, proofs.fire, proofs.explosion, proofs.collision, proofs.melee, proofs.steam, 1, proofs.drown)
	end
	return true
end)

-------------------------------------
--WEAPON OPTIONS
-------------------------------------

local weapon_options = menu.list(menu.my_root(), menuname('Weapon', 'Weapon'), {'weaponoptions'}, '')

menu.divider(weapon_options, menuname('Weapon', 'Weapon'))

-------------------------------------
--VEHICLE PAINT GUN
-------------------------------------

menu.toggle_loop(weapon_options, menuname('Weapon', 'Vehicle Paint Gun'), {'paintgun'}, 'Applies a random colour combination to the damaged vehicle.', function(toggle)
	if PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) then
		local ptr = alloc(32); PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(PLAYER.PLAYER_ID(), ptr)
		local entity = memory.read_int(ptr); memory.free(ptr)
		if entity == 0 then return end
		if ENTITY.IS_ENTITY_A_PED(entity) then
			entity = PED.GET_VEHICLE_PED_IS_IN(entity, false)
		end
		if ENTITY.IS_ENTITY_A_VEHICLE(entity) then
			REQUEST_CONTROL_LOOP(entity)
			VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(entity, math.random(0,255), math.random(0,255), math.random(0,255))
			VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(entity, math.random(0,255), math.random(0,255), math.random(0,255))
		end
	end
end)

-------------------------------------
--SHOOTING EFFECT
-------------------------------------


local effects_list = 
{
	['Clown Flowers'] = 
	{
		['asset'] = 'scr_rcbarry2',
		['name'] = 'scr_clown_bul',
		['scale'] = 0.3, 	--scale
		['rot'] = {
			x = 0, 			--xRot
			y = 0, 			--yRot
			z = 180			--zRot
		} 		
	},
	['Clown Muz'] = {
		['asset'] = 'scr_rcbarry2',
		['name'] = 'muz_clown',
		['scale'] = 0.8,
		['rot'] = {
			x = 0,
			y = 0,
			z = 0
		}
	}
}

local shooting_effect = effects_list['Clown Flowers']

local toggle_shooting_effect = menu.toggle(weapon_options, menuname('Weapon', 'Shooting Effect')..': Clown Flowers', {'shootingeffect'}, 'Effects while shooting.', function(toggle)
	cartoon = toggle
	local user_ped = PLAYER.PLAYER_PED_ID()
	local effects = {}
	
	STREAMING.REQUEST_NAMED_PTFX_ASSET(shooting_effect.asset)
	while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(shooting_effect.asset) do
		wait()
	end
	while cartoon do
		if PED.IS_PED_SHOOTING(user_ped) then
			local weapon = WEAPON.GET_CURRENT_PED_WEAPON_ENTITY_INDEX(user_ped, false)
			local bone_pos = ENTITY._GET_ENTITY_BONE_POSITION_2(weapon, ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(weapon, 'gun_muzzle'))
			local offset = ENTITY.GET_OFFSET_FROM_ENTITY_GIVEN_WORLD_COORDS(weapon, bone_pos.x, bone_pos.y, bone_pos.z)
			local rot = shooting_effect['rot']
				
			GRAPHICS.USE_PARTICLE_FX_ASSET(shooting_effect.asset)
			GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_ON_ENTITY(
				shooting_effect.name,
				weapon, 
				offset.x + 0.10,
				offset.y,
				offset.z,
				rot.x,
				rot.y,
				rot.z,
				shooting_effect.scale,
				false, false, false
			)
		end	
		wait()
	end
end)

local select_effect = menu.list(weapon_options, menuname('Weapon', 'Set Shooting Effect'), {}, '')

for k, table in pairs_by_keys(effects_list) do
	menu.action(select_effect, k, {k}, '', function()
		shooting_effect = table
		menu.set_menu_name(toggle_shooting_effect, menuname('Weapon', 'Shooting Effect')..': '..k)
		if not cartoon then menu.trigger_command(toggle_shooting_effect, 'on') end
		menu.trigger_command(weapon_options, '')
	end)
end


-------------------------------------
--MAGNET GUN
-------------------------------------

local magnetgun_root = menu.list(weapon_options, menuname('Weapon', 'Magnet Gun'), {}, '')

menu.divider(magnetgun_root, menuname('Weapon', 'Magnet Gun'))

smooth_mode = menu.toggle(magnetgun_root, menuname('Magnet Gun', 'Magnet Gun'), {'magnetgun'}, '', function(toggle)
	velocity_magnetgun = toggle
	if velocity_magnetgun and force_magnetgun then
		menu.trigger_command(chaos_mode, 'off')
	end
end)

chaos_mode = menu.toggle(magnetgun_root, menuname('Magnet Gun', 'Chaos Mode'), {'chaosmmode'}, '', function(toggle)
	force_magnetgun = toggle
	if force_magnetgun and velocity_magnetgun then
		menu.trigger_command(smooth_mode, 'off')
	end
end)

-- draws the sphere in the magnet gun's blackhole
-- sets the color in rainbow mode

local sphere_colour = {
	['r'] = 255,
	['g'] = 0,
	['b'] = 255
}
util.create_tick_handler(function()
	if not force_magnetgun and not velocity_magnetgun then
		return true
	end
	
	if sphere_colour.r > 0 and sphere_colour.b == 0 then
		sphere_colour.r = sphere_colour.r - 1
		sphere_colour.g = sphere_colour.g + 1
	end
		
	if sphere_colour.g > 0 and sphere_colour.r == 0 then
		sphere_colour.g = sphere_colour.g - 1
		sphere_colour.b = sphere_colour.b + 1
	end
	
	if sphere_colour.b > 0 and sphere_colour.g == 0 then
		sphere_colour.r = sphere_colour.r + 1
		sphere_colour.b = sphere_colour.b - 1
	end

	if PLAYER.IS_PLAYER_FREE_AIMING(players.user()) then
		local offset = GET_OFFSET_FROM_CAM(30)
		GRAPHICS._DRAW_SPHERE(offset.x, offset.y, offset.z, 0.5, sphere_colour.r, sphere_colour.g, sphere_colour.b, 0.5)
	end
	return true
end)


util.create_tick_handler(function()
	if not force_magnetgun and not velocity_magnetgun then
		return true
	end
	local v = {}
	if PLAYER.IS_PLAYER_FREE_AIMING(players.user()) then
		local offset = GET_OFFSET_FROM_CAM(30)
		for key, vehicle in pairs(entities.get_all_vehicles_as_handles()) do
			if vehicle ~= PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false) then
				local vpos = ENTITY.GET_ENTITY_COORDS(vehicle)
				if vect.dist(offset, vpos) < 70 and REQUEST_CONTROL(vehicle) and #v < 20 then
					insert_once(v, vehicle)
					local unitv = vect.norm(vect.subtract(offset, vpos))
					local dist = vect.dist(offset, vpos)
					
					if velocity_magnetgun then
						local vel = vect.mult(unitv, dist)
						ENTITY.SET_ENTITY_VELOCITY(vehicle, vel.x, vel.y, vel.z)
					elseif force_magnetgun then
						local force = vect.mult(unitv, dist)
						ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, force.x, force.y, force.z, 0, 0, 0.5, 0, false, false, true)
					end
				end
			end
		end
	end
	return true
end)

-------------------------------------
--AIRSTRIKE GUN
-------------------------------------

menu.toggle_loop(weapon_options, menuname('Weapon', 'Airstrike Gun'), {}, '', function(toggle)
	local hash = joaat('weapon_airstrike_rocket')
	if not WEAPON.HAS_WEAPON_ASSET_LOADED(hash) then
		WEAPON.REQUEST_WEAPON_ASSET(hash, 31, 0)
	end
	
	local hit, coords, normal_surface, entity = RAYCAST_GAMEPLAY_CAM(1000.0)
	if hit == 1 then
		if PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) then
			MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(coords.x, coords.y, coords.z + 35, coords.x, coords.y, coords.z, 200, true, hash, PLAYER.PLAYER_PED_ID(), true, false, 2500.0)
		end
	end

end)

-------------------------------------
--BULLET CHANGER
-------------------------------------


local ammo_ptrs = --belongs to ammo type 4
{
	--['Firework'] 		= {['hash'] = 0x7F7497E5},
	['Flare'] 			= {['hash'] = 0x47757124},
	['Grenade Launcher']= {['hash'] = 0xA284510B},
	--['RPG'] 			= {['hash']	= 0xB1CA77B1},
	--['Sticky Bomb'] 	= {['hash'] = 0x2C3731D9},
	['Grenade'] 		= {['hash'] = 0x93E220BD},
	['Molotov'] 		= {['hash'] = 0x24B17070},
	['Tear Gas'] 		= {['hash'] = 0xFDBC8A50},
	['Snow Ball'] 		= {['hash'] = 0x787F0BB},
	--['Ball'] 			= {['hash'] = 0x23C9F95C},
	--['Flare'] 		= {['hash'] = 0x497FACC3},
}
local rockets_list = {
	['RPG Rockets'] = 'weapon_rpg',
	['Firework'] = 'weapon_firework',
	['Up-n-Atomizer'] = 'weapon_raypistol'
}
local bullet = 0xB1CA77B1
local from_memory = false
local default_bullet = {}


function GET_CURRENT_WEAPON_AMMO_TYPE() --returns 4 if OBJECT (Rocket, grenade, etc.), and 2 if INSTANT HIT
	local offsets = {0x08, 0x10D8, 0x20, 0x54}
	local addr = address_from_pointer_chain(worldPtr, offsets)
	if addr ~= 0 then
		return memory.read_byte(addr), addr
	else
		error('Current ammo type not found')
	end
end


function GET_CURRENT_WEAPON_AMMO_PTR()
	local offsets = {0x08, 0x10D8, 0x20, 0x60}
	local addr = address_from_pointer_chain(worldPtr, offsets)
	local value
	if addr ~= 0 then
		return memory.read_long(addr), addr
	else
		error('Current ammo pointer not found.')
	end
end


function SET_BULLET_TO_DEFAULT()
	for weapon, data in pairs(default_bullet) do
		local atype, aptr = data.ammotype, data.ammoptr
		memory.write_byte(atype.addr, atype.value)
		memory.write_long(aptr.addr, aptr.value)
	end
end


local toggle_bullet_type = menu.toggle(weapon_options, menuname('Weapon', 'Bullet Changer')..': RPG Rocket', {'bulletchanger'}, '', function(toggle)
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
					ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(current_weapon, 'gun_muzzle')
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
					  ['ammotype'] = {
						['addr'] = ammotype_addr, 
						['value'] = ammotype
					},
					  ['ammoptr'] = {
						['addr'] = ammoptr_addr, 
						['value'] = ammoptr
					}
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


local bullet_type = menu.list(weapon_options, menuname('Weapon', 'Bullet Type'))
local type_throwables = menu.list(bullet_type, menuname('Weapon - Bullet Type', 'Throwables'), {}, 'Not networked. Other players can only see explosions.')

for k, v in pairs_by_keys(rockets_list) do
	menu.action(bullet_type, k, {}, '', function()
		bullet = joaat(v)
		menu.set_menu_name(toggle_bullet_type, menuname('Weapon', 'Bullet Changer')..': '..k)
		if not bulletchanger then menu.trigger_command(toggle_bullet_type, 'on') end
		menu.trigger_command(weapon_options, '')
		from_memory = false
	end)
end


for k, data in pairs_by_keys(ammo_ptrs) do
	menu.action(type_throwables, k, {}, '', function()
		local current_ptr = alloc(12)
		WEAPON.GET_CURRENT_PED_WEAPON(PLAYER.PLAYER_PED_ID(), current_ptr)
		local current = memory.read_int(current_ptr); memory.free(current_ptr)
		
		if data.ammoptr == nil then 
			WEAPON.GIVE_WEAPON_TO_PED(PLAYER.PLAYER_PED_ID(), data.hash, 9999, false, false)
			WEAPON.SET_CURRENT_PED_WEAPON(PLAYER.PLAYER_PED_ID(), data.hash, false)
			data.ammoptr = GET_CURRENT_WEAPON_AMMO_PTR()
			WEAPON.SET_CURRENT_PED_WEAPON(PLAYER.PLAYER_PED_ID(), current, false)
		end

		bullet = data.ammoptr
    	menu.set_menu_name(toggle_bullet_type, menuname('Weapon', 'Bullet Changer')..': '..k)
		if not bulletchanger then menu.trigger_command(toggle_bullet_type, 'on') end
		menu.trigger_command(weapon_options, '')
		from_memory = true
  	end)
end

-------------------------------------
--PTFX GUN
-------------------------------------

local ptfx_gun = menu.list(weapon_options, menuname('Weapon', 'Particle Weapon'), {'ptfxgun'}, '')

menu.divider(ptfx_gun, menuname('Weapon', 'Particle Weapon'))


local impact_effects =
{
	['Clown Explosion'] =
	{
		['asset'] = 'scr_rcbarry2',
		['name'] = 'scr_exp_clown',
		['colour'] = false
	},
	['Clown Appears'] =
	{
		['asset'] = 'scr_rcbarry2',
		['name'] = 'scr_clown_appears',
		['colour'] = false
	},
	['FW Trailburst'] =
	{
		['asset'] = 'scr_rcpaparazzo1',
		['name'] = 'scr_mich4_firework_trailburst_spawn',
		['colour'] = true
	},
	['FW Starburst'] = 
	{
		['asset'] = 'scr_indep_fireworks',
		['name'] = 'scr_indep_firework_starburst',
		['colour'] = true
	},
	['FW Fountain'] = 
	{
		['asset'] = 'scr_indep_fireworks',
		['name'] = 'scr_indep_firework_fountain',
		['colour'] = true
	},
	['Alien Disintegration'] = 
	{
		['asset'] = 'scr_rcbarry1',
		['name'] = 'scr_alien_disintegrate',
		['colour'] = false
	},
	['Clown Flowers'] = 
	{
		['asset'] = 'scr_rcbarry2',
		['name'] = 'scr_clown_bul',
		['colour'] = false
	},
	['FW Ground Burst'] = 
	{
		['asset'] = 'proj_indep_firework',
		['name'] = 'scr_indep_firework_grd_burst',
		['colour'] = false
	}
}

local impact_effect = impact_effects['Clown Explosion']
local impact_colour = 
{
	['r'] = 128 / 255,
	['g'] = 0.0,
	['b'] = 128 / 255
}

local toggle_impact_effect = menu.toggle(ptfx_gun,  menuname('Weapon', 'Particle Weapon')..': Clown Explosion', {'impacteffect'}, '', function(toggle)
	ptfxgun = toggle
	while ptfxgun do
		wait()
		if not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(impact_effect.asset) then
			STREAMING.REQUEST_NAMED_PTFX_ASSET(impact_effect.asset)
			while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(impact_effect.asset) do
				wait()
			end
		end
		local hit, coords, normal_surface, entity = RAYCAST_GAMEPLAY_CAM(1000.0)
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
					rot.pitch - 90, 
					rot.roll, 
					rot.yaw, 
					1.0, 
					false, false, false, false
				)
			end
		end
	end
end)


local list_impact_effect = menu.list(ptfx_gun,  menuname('Weapon - Particle Weapon', 'Set Particle Effect'))


for k, table in pairs_by_keys(impact_effects) do
	local helptext
	if impact_effects[k]['colour'] then
		helptext = 'Colour can be changed.'
	else
		helptext = ''
	end
	menu.action(list_impact_effect, k, {}, helptext, function()
		impact_effect = impact_effects[k]
		menu.set_menu_name(toggle_impact_effect, menuname('Weapon', 'Particle Weapon')..': '..k)
		if not ptfxgun then menu.trigger_command(toggle_impact_effect, 'on') end
		menu.trigger_command(ptfx_gun, '')
	end)
end


menu.rainbow(
	menu.colour(ptfx_gun, menuname('Weapon - Particle Weapon', 'Particle Effect Colour'), {'impactcolour'}, 'Only works on some fx\'s.', {['r'] = 128/255, ['g'] = 0, ['b'] = 128/255, ['a'] = 1.0}, false, function(colour)
		impact_colour = colour
	end)
)

-------------------------------------
--VEHICLE GUN
-------------------------------------


local vehicle_gun_list = {
	['Lazer'] = 'lazer',
	['Insurgent'] = 'insurgent2',
	['Phantom Wedge'] = 'phantom2',
	['Adder'] = 'adder'
}

local vehicle_for_gun = vehicle_gun_list.Adder
local intovehicle

local vehicle_gun = menu.list(weapon_options, menuname('Weapon', 'Vehicle Gun'), {'vehiclegun'}, '')

menu.divider(vehicle_gun, menuname('Weapon', 'Vehicle Gun'))

local toggle_vehicle_gun = menu.toggle(vehicle_gun, menuname('Weapon', 'Vehicle Gun')..': Adder', {'togglevehiclegun'}, '', function(toggle)
	vehiclegun = toggle
	
	local preview
	local offset = alloc(); memory.write_float(offset, 25)
	local maxoffset = 100
	local minoffset = 15
	local p = 0.0
	local buttons = {
		{'increase offset', 241},
		{'decrease offset', 242}
	}
	
	while vehiclegun do
		wait()
		local hash = joaat(vehicle_for_gun)
		local hit, coords, nsurface, entity = RAYCAST_GAMEPLAY_CAM(memory.read_float(offset) + 5, 1)
		
		if not general_config.disablepreview then 
			local foffset = minoffset + p * (maxoffset - minoffset)
			incr(offset, foffset, 0.5)
			if PAD.IS_CONTROL_JUST_PRESSED(2, 241) and PAD.IS_CONTROL_PRESSED(2, 241) then
				if p < 1.0 then 
					p = p + 0.25
				end
			end		
			if PAD.IS_CONTROL_JUST_PRESSED(2, 242) and PAD.IS_CONTROL_PRESSED(2, 242) then
				if p > 0.0 then
					p = p - 0.25
				end
			end
		end

		if hit ~= 1 then 
			coords = GET_OFFSET_FROM_CAM(memory.read_float(offset)) 
		end
		
		REQUEST_MODEL(hash)
		
		if PLAYER.IS_PLAYER_FREE_AIMING(players.user()) then
			local rot = CAM.GET_GAMEPLAY_CAM_ROT(0)
			
			if not general_config.disablepreview then
				if not ENTITY.DOES_ENTITY_EXIST(preview) then --VEHICLE PREVIEW
					preview = VEHICLE.CREATE_VEHICLE(hash, coords.x, coords.y, coords.z, rot.z, false, false)
					ENTITY.SET_ENTITY_ALPHA(preview, 153, true)
					ENTITY.SET_ENTITY_DYNAMIC(preview, 1);
					ENTITY.SET_ENTITY_HAS_GRAVITY(preview, 1)
					ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(preview, false, false)
				end
				ENTITY.SET_ENTITY_COORDS_NO_OFFSET(preview, coords.x, coords.y, coords.z, false, false, false)
				if hit == 1 then
					VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(preview, 1.0)
				end
				ENTITY.SET_ENTITY_ROTATION(preview, rot.x, rot.y, rot.z, 0, true)
				INSTRUCTIONAL.DRAW(buttons)
			end

			if PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) then --VEHICLE GUN
				local vehicle = entities.create_vehicle(hash, coords, rot.z)
				ENTITY.SET_ENTITY_ROTATION(vehicle, rot.x, rot.y, rot.z, 0, true) 
				if intovehicle then
					VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle, true, true, true)
					PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), vehicle, -1)
				else
					VEHICLE.SET_VEHICLE_DOORS_LOCKED(vehicle, 2)
				end
				ENTITY.SET_ENTITY_COORDS_NO_OFFSET(vehicle, coords.x, coords.y, coords.z, false, false, false)
				ENTITY.SET_ENTITY_LOAD_COLLISION_FLAG(vehicle, true)
				VEHICLE.SET_VEHICLE_FORWARD_SPEED(vehicle, 200)
				ENTITY._SET_ENTITY_CLEANUP_BY_ENGINE(vehicle, true)
			end
		elseif ENTITY.DOES_ENTITY_EXIST(preview) then
			entities.delete_by_handle(preview)
		end
	end
end)


local set_vehicle = menu.list(vehicle_gun, menuname('Weapon - Vehicle Gun', 'Set Vehicle'))


for k, vehicle in pairs_by_keys(vehicle_gun_list) do
	menu.action(set_vehicle, k, {}, '', function()
		vehicle_for_gun = vehicle_gun_list[k]
		menu.set_menu_name(toggle_vehicle_gun, 'Vehicle Gun: ' .. k)
		if not vehiclegun then menu.trigger_command(toggle_vehicle_gun, 'on') end
		menu.trigger_command(vehicle_gun, '')
	end)
end


menu.text_input(vehicle_gun, menuname('Weapon - Vehicle Gun', 'Custom Vehicle'), {'customvehgun'}, '', function(vehicle)
	local modelHash = joaat(vehicle)
	local name = HUD._GET_LABEL_TEXT(VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(modelHash))
	if STREAMING.IS_MODEL_A_VEHICLE(modelHash) then
		vehicle_for_gun = vehicle
		menu.set_menu_name(toggle_vehicle_gun, 'Vehicle Gun: ' .. name)
	else
		return notification.red('The model is not a vehicle')
	end
	if not vehiclegun then menu.trigger_command(toggle_vehicle_gun, 'on') end
end)


menu.toggle(vehicle_gun, menuname('Weapon - Vehicle Gun', 'Set Into Vehicle'), {}, '', function(toggle)
	intovehicle = toggle
end)

-------------------------------------
--TELEPORT GUN
-------------------------------------

menu.toggle(weapon_options, menuname('Weapon', 'Teleport Gun'), {'tpgun'}, '', function(toggle)
	telegun = toggle

	while telegun do
		wait()
		local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
		local hit, coords, normal_surface, entity = RAYCAST_GAMEPLAY_CAM(1000.0)
		
		if hit == 1 and PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) then	
			if vehicle == 0 then
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
--BULLET SPEED MULT
-------------------------------------

local default_speed = {}
local speed_mult = 1

function SET_AMMO_SPEED_MULT(mult)
	local offsets = {0x08, 0x10D8, 0x20, 0x60, 0x58}
	local addr = address_from_pointer_chain(worldPtr, offsets)
	if addr ~= 0 then
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
--MAGNET ENTITIES
-------------------------------------


menu.toggle(weapon_options, menuname('Weapon', 'Magnet Entities'), {}, '', function(toggle)
	magnetent = toggle
	
	local applyforce = false
	local entities = {}
	local entity

	if magnetent then
		util.show_corner_help('Magnet Entities applies an attractive force on two specific entities. Shoot the chosen entities (vehicle, object or ped) to attract them to each other')
	end

	util.create_tick_handler(function()
		if PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) then
			local ptr = alloc()
			PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(PLAYER.PLAYER_ID(), ptr)
			entity = memory.read_int(ptr); memory.free(ptr)
			if entity == 0 then
				return 
			end
			if ENTITY.IS_ENTITY_A_PED(entity) then
				local vehicle = PED.GET_VEHICLE_PED_IS_IN(entity, false)
				if vehicle ~= 0 then
					entity = vehicle
				end
			end

			local dist = vect.dist(
				ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID()),
				ENTITY.GET_ENTITY_COORDS(entity)
			)

			if entities[1] ~= entity and dist < 500 then 
				table.insert(entities, entity)
			end

			if #entities == 2 then
				local ent1, ent2 = table.unpack(entities)
			
				util.create_tick_handler(function()
					local pos1, pos2 = ENTITY.GET_ENTITY_COORDS(ent1), ENTITY.GET_ENTITY_COORDS(ent2)
					local dist = vect.dist(pos1, pos2)
					local force1 = vect.mult(vect.norm(vect.subtract(pos2, pos1)), dist / 20)
					local force2 = vect.mult(force1, -1)

					if REQUEST_CONTROL(ent1) then
						if ENTITY.IS_ENTITY_A_PED(ent1) then
							PED.SET_PED_TO_RAGDOLL(ent1, 1000, 1000, 0, 0, 0, 0)
						end
						ENTITY.APPLY_FORCE_TO_ENTITY(ent1, 1, force1.x, force1.y, force1.z, 0, 0, 0, 0, false, false, true)
					end

					if REQUEST_CONTROL(ent2) then
						if ENTITY.IS_ENTITY_A_PED(ent2) then
							PED.SET_PED_TO_RAGDOLL(ent2, 1000, 1000, 0, 0, 0, 0)
						end
						ENTITY.APPLY_FORCE_TO_ENTITY(ent2, 1, force2.x, force2.y, force2.z, 0, 0, 0, 0, false, false, true)
					end

					return magnetent
				end)
				entities = {}
			end
		end
		return magnetent
	end)
end)


-------------------------------------
--VALKYIRE ROCKET
-------------------------------------

menu.toggle(weapon_options, menuname('Weapon', 'Valkyire Rocket'), {}, '', function(toggle)
		
	valkyire_rocket = toggle

	if valkyire_rocket then
		local rocket, cam
		local g = alloc()
		local bar = alloc(); 
		local init
		local sTime
		local draw_rect = function(x, y, z, w)
			GRAPHICS.DRAW_RECT(x, y, z, w, 255, 255, 255, 255)
		end
	
		while valkyire_rocket do
			wait()

			if PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) then
				if not init then init = true end
				sTime = getTime()
			end

			if init then
				if not ENTITY.DOES_ENTITY_EXIST(rocket) then
					local weapon = WEAPON.GET_CURRENT_PED_WEAPON_ENTITY_INDEX(PLAYER.PLAYER_PED_ID())
					local c = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(weapon, 0.0, 1.0, 0.0)
					rocket =  entities.create_object(joaat('w_lr_rpg_rocket'), c)
					CAM.DESTROY_ALL_CAMS(true)
					cam = CAM.CREATE_CAM('DEFAULT_SCRIPTED_CAMERA', true)
					CAM.ATTACH_CAM_TO_ENTITY(cam, rocket, 0.0, 0.0, 0.0, true)
					CAM.RENDER_SCRIPT_CAMS(true, true, 700, true, true)
					CAM.SET_CAM_ACTIVE(cam, true)
					ENTITY.SET_ENTITY_VISIBLE(rocket, 0)
					memory.write_float(bar, 0.5); memory.write_float(g, 255)
				else
					local rot = CAM.GET_GAMEPLAY_CAM_ROT(0)
					CAM.SET_CAM_ROT(cam, rot.x, rot.y, rot.z, 0)
					ENTITY.SET_ENTITY_ROTATION(rocket, rot.x, rot.y, rot.z, 0, 1)

					local c = vect.add(ENTITY.GET_ENTITY_COORDS(rocket), vect.mult(ROTATION_TO_DIRECTION(CAM.GET_GAMEPLAY_CAM_ROT(0)), 0.8))
					ENTITY.SET_ENTITY_COORDS(rocket, c.x, c.y, c.z, false, false, false, false)
					STREAMING.SET_FOCUS_POS_AND_VEL(c.x, c.y, c.z, 5.0, 0.0, 0.0)

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
					GRAPHICS.SET_TIMECYCLE_MODIFIER("CAMERA_secuirity")

					GRAPHICS.DRAW_RECT(0.25, 0.5, 0.03, 0.5, 255, 255, 255, 255)

					if getTime() - sTime >= 100 then
						incr(bar, 0, -0.01); incr(g, 0, -4)
						sTime = getTime()
					end

					GRAPHICS.DRAW_RECT(0.25, 0.75 - (memory.read_float(bar) / 2), 0.03, memory.read_float(bar), 255, round(memory.read_float(g)), 0, 255)

					local groundZ = alloc()
					MISC.GET_GROUND_Z_FOR_3D_COORD(ENTITY.GET_ENTITY_COORDS(rocket).x, ENTITY.GET_ENTITY_COORDS(rocket).y, ENTITY.GET_ENTITY_COORDS(rocket).z, groundZ, 0)
					groundZ = memory.read_float(groundZ)
					
					if ENTITY.HAS_ENTITY_COLLIDED_WITH_ANYTHING(rocket) or math.abs(ENTITY.GET_ENTITY_COORDS(rocket).z - groundZ) < 0.5 or memory.read_float(bar) <= 0.01 then
						local impact_coord = ENTITY.GET_ENTITY_COORDS(rocket); ENTITY.FREEZE_ENTITY_POSITION(PLAYER.PLAYER_PED_ID(), false)
						FIRE.ADD_EXPLOSION(impact_coord.x, impact_coord.y, impact_coord.z, 32, 1.0, true, false, 0.4)
						entities.delete_by_handle(rocket)
						rocket = 0
						PLAYER.DISABLE_PLAYER_FIRING(PLAYER.PLAYER_PED_ID(), false)
						STREAMING.CLEAR_FOCUS()
						CAM.RENDER_SCRIPT_CAMS(false, false, 3000, true, false, 0)
						CAM.DESTROY_CAM(cam, 1)
						GRAPHICS.SET_TIMECYCLE_MODIFIER("DEFAULT")
						init = false
					end
				end
			end
		end
		GRAPHICS.SET_TIMECYCLE_MODIFIER("DEFAULT")
		STREAMING.CLEAR_FOCUS()
		CAM.RENDER_SCRIPT_CAMS(false, false, 3000, true, false, 0)
		CAM.DESTROY_CAM(cam, 1)
		PLAYER.DISABLE_PLAYER_FIRING(PLAYER.PLAYER_PED_ID(), false)
		rocket = 0
		bar = 0.5
		y = 255
		ENTITY.FREEZE_ENTITY_POSITION(PLAYER.PLAYER_PED_ID(), false)
	end
end)

-------------------------------------
--VEHICLE
-------------------------------------

local vehicle_options = menu.list(menu.my_root(), menuname('Vehicle', 'Vehicle'), {}, '')

menu.divider(vehicle_options, menuname('Vehicle', 'Vehicle'))

-------------------------------------
--AIRSTRIKE AIRCRAFT
-------------------------------------

local vehicle_weapon = menu.list(vehicle_options, menuname('Vehicle', 'Vehicle Weapons'), {'vehicleweapons'}, 'Allows you to add weapons to any vehicle.')

menu.divider(vehicle_weapon, menuname('Vehicle', 'Vehicle Weapons'))


local airstrikeplanes =  menu.toggle(vehicle_options, menuname('Vehicle', 'Airstrike Aircraft'), {'airstrikeplanes'}, 'Use any plane or helicopter to make airstrikes.', function(toggle)
	airstrike_plane = toggle
	local control = control_config.airstrikeaircraft
	if airstrike_plane then
		SHOW_CORNER_HELP_GIVEN_CONTROL_INDEX(control, 'to use Airstrike Aircraft.')
	end

	while airstrike_plane do
		wait(200)
		if PED.IS_PED_IN_ANY_PLANE(PLAYER.PLAYER_PED_ID()) or PED.IS_PED_IN_ANY_HELI(PLAYER.PLAYER_PED_ID()) then
			if PAD.IS_CONTROL_PRESSED(2, control) then
				local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID())
				local pos = ENTITY.GET_ENTITY_COORDS(vehicle)
				local startTime = os.time() 
				util.create_thread(function()
					while os.time()-startTime <= 5 do
						wait(500)		
						local ground_ptr = alloc(32)
						MISC.GET_GROUND_Z_FOR_3D_COORD(pos.x, pos.y, pos.z, ground_ptr, false, false)
						local ground = memory.read_float(ground_ptr); memory.free(ground_ptr)
						pos.x = pos.x + math.random(-3,3)
						pos.y = pos.y + math.random(-3,3)
						if pos.z - ground > 10 then
							MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z - 3, pos.x, pos.y, ground, 200, true, joaat("weapon_airstrike_rocket"), PLAYER.PLAYER_PED_ID(), true, false, 2500.0)
						end
					end
				end)
			end
		end
	end
end)

-------------------------------------
--VEHICLE WEAPONS' STUFF
-------------------------------------

function draw_line_from_vehicle(vehicle, startpoint, display)
	local coord1
	local coord2
	local minimum_ptr = alloc()
	local maximum_ptr = alloc()
	MISC.GET_MODEL_DIMENSIONS(ENTITY.GET_ENTITY_MODEL(vehicle), minimum_ptr, maximum_ptr)
	local minimum = memory.read_vector3(minimum_ptr)
	local maximum = memory.read_vector3(maximum_ptr)
	local startcoords = 
	{
		fl = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, minimum.x, maximum.y, 0), --FRONT & LEFT
		fr = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, maximum.x, maximum.y, 0)  --FRONT & RIGHT
	}	
	local endcoords = 
	{
		fl = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, minimum.x, maximum.y+25, 0),
		fr = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, maximum.x, maximum.y+25, 0)
	}
	for k, v in pairs(startcoords, endcoords) do
		if k == startpoint then
			coord1 = startcoords[k]
			coord2 = endcoords[k]
		end
	end
	if display then
		GRAPHICS.DRAW_LINE(coord1.x, coord1.y, coord1.z, coord2.x, coord2.y, coord2.z, 255, 0, 0, 150)
	end
	memory.free(minimum_ptr)
	memory.free(maximum_ptr)
end


function shoot_bullet_from_vehicle(vehicle, weaponName, startpoint)
	local user_ped = PLAYER.PLAYER_PED_ID()
	local weaponHash = joaat(weaponName)
	local minimum_ptr = alloc()
	local maximum_ptr = alloc()
	local coord1
	local coord2
	if not WEAPON.HAS_WEAPON_ASSET_LOADED(weaponHash) then
		WEAPON.REQUEST_WEAPON_ASSET(weaponHash, 31, 26)
		while not WEAPON.HAS_WEAPON_ASSET_LOADED(weaponHash) do
			wait()
		end
	end
	local veh_coords = ENTITY.GET_ENTITY_COORDS(vehicle, true)
	MISC.GET_MODEL_DIMENSIONS(ENTITY.GET_ENTITY_MODEL(vehicle), minimum_ptr, maximum_ptr)
	local minimum = memory.read_vector3(minimum_ptr)
	local maximum = memory.read_vector3(maximum_ptr)

	local startcoords = 
	{
		fl = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, minimum.x, maximum.y + 0.25, 0.3), 	--FRONT & LEFT
		fr = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, maximum.x, maximum.y + 0.25, 0.3), 	--FRONT & RIGHT
		bl = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, minimum.x, minimum.y, 0.3), 			--BACK & LEFT
		br = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, maximum.x, minimum.y, 0.3) 				--BACK & RIGHT
	}	
	local endcoords = 
	{
		fl = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, minimum.x, maximum.y + 50, 0.0),
		fr = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, maximum.x, maximum.y + 50, 0.0),
		bl = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, minimum.x, minimum.y - 50, 0.0),
		br = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, maximum.x, minimum.y - 50, 0.0)
	}

	for k, v in pairs(startcoords, endcoords) do
		if k == startpoint then
			coord1 = startcoords[k]
			coord2 = endcoords[k]
		end
	end
	MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(coord1.x, coord1.y, coord1.z, coord2.x, coord2.y, coord2.z, 200, true, weaponHash, user_ped, true, false, 2000.0)
	memory.free(minimum_ptr)
	memory.free(maximum_ptr)
end

-------------------------------------
--VEHICLE LASER
-------------------------------------


menu.toggle(vehicle_weapon, menuname('Vehicle - Vehicle Weapons', 'Vehicle Lasers'), {'vehiclelasers'},'', function(toggle)
	vehicle_laser = toggle
	if vehicle_laser and airstrike_plane then
		menu.trigger_command(airstrikeplanes, 'off')
	end
	local user_ped = PLAYER.PLAYER_PED_ID()
	util.create_thread(function()
		while vehicle_laser do
			wait()
			local vehicle = PED.GET_VEHICLE_PED_IS_IN(user_ped, false)
			if vehicle ~= 0 then
				draw_line_from_vehicle(vehicle, 'fl', vehicle_laser); draw_line_from_vehicle(vehicle, 'fr', vehicle_laser)
			end
		end
	end)
end)

-------------------------------------
--VEHICLE WEAPONS
-------------------------------------

local selected_veh_weapon = 'WEAPON_VEHICLE_ROCKET'

local toggle_veh_weapons = menu.toggle(vehicle_weapon, menuname('Vehicle - Vehicle Weapons', 'Vehicle Weapons')..': Rockets', {'togglevehweapons'}, '', function(toggle)
	veh_rockets = toggle
	local user_ped = PLAYER.PLAYER_PED_ID()
	
	if veh_rockets then
		local control = control_config.vehicleweapons
			SHOW_CORNER_HELP_GIVEN_CONTROL_INDEX(control,'to use Vehicle Weapons.\nPress ~INPUT_VEH_LOOK_BEHIND~ to shoot backwards.')
	end

	while veh_rockets do
		wait()
		local control = control_config.vehicleweapons
		local vehicle = PED.GET_VEHICLE_PED_IS_IN(user_ped, false)
		if vehicle ~= 0 then
			if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, control) then
				if not PAD.IS_CONTROL_PRESSED(0, 79) then
					shoot_bullet_from_vehicle(vehicle, selected_veh_weapon, 'fl'); shoot_bullet_from_vehicle(vehicle, selected_veh_weapon, 'fr')
				else
					shoot_bullet_from_vehicle(vehicle, selected_veh_weapon, 'bl'); shoot_bullet_from_vehicle(vehicle, selected_veh_weapon, 'br')
				end
			end
		end
	end
end)


local veh_weapons_list = {
	['Rockets'] = 'WEAPON_VEHICLE_ROCKET',
	['Up-n-Atomizer'] = 'weapon_raypistol',
	['Firework'] = 'weapon_firework',
	['Tank Cannon'] = 'VEHICLE_WEAPON_TANK',
	['Lazer MG'] = 'VEHICLE_WEAPON_PLAYER_LAZER'
}


local vehicle_weapon_list = menu.list(vehicle_weapon, menuname('Vehicle - Vehicle Weapons', 'Set Vehicle Weapon'))


for k, weapon in pairs_by_keys(veh_weapons_list) do
	menu.action(vehicle_weapon_list, k, {k}, '', function()
		selected_veh_weapon = weapon
		menu.set_menu_name(toggle_veh_weapons, menuname('Vehicle - Vehicle Weapons', 'Set Vehicle Weapon')..': '..k)
		if not veh_rocket then menu.trigger_command(toggle_veh_weapons, 'on') end
		menu.trigger_command(vehicle_weapon, '')
	end)
end

-------------------------------------
--VEHICLE EDITOR
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
	offsets = {
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
		{ -- boat
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
	if not PED.IS_PED_IN_ANY_VEHICLE(PLAYER.PLAYER_PED_ID(), false) then 
		return
	end
	
	local file = wiridir ..'\\handling\\' .. self.vehicle_name .. '.json'

	if not filesystem.exists(file) then 
		return notification.red('File not found')
	end
	
	file = io.open(file, 'r')
	local content = file:read('a')
	file:close()
	if string.len(content) > 0 then
		local parsed = json.parse(content, false)
		local sethandling = function(offsets, s)
			for _, a in ipairs(offsets) do
				local addr = address_from_pointer_chain(worldPtr, {0x08, 0xD30, 0x938, a[2]})
				if addr ~= 0 then
					memory.write_float(addr, parsed[s][a[1]])
				end
			end
		end
		sethandling(self.offsets[1], 'handling')
		if parsed.flying ~= nil then sethandling(self.offsets[2], 'flying') end
		if parsed.boat ~= nil then sethandling(self.offsets[3], 'boat') end
		notification.normal(firstUpper(self.vehicle_name) .. ' handling data loaded')
	end
end


function handling:save()
	if not PED.IS_PED_IN_ANY_VEHICLE(PLAYER.PLAYER_PED_ID(), false) then 
		return
	end
	local table = {}
	local model = GET_USER_VEHICLE_MODEL()
	local file = wiridir ..'\\handling\\' .. self.vehicle_name .. '.json'
	local gethandling = function(offsets)
		local s = {}
		for _, a in ipairs(offsets) do
			local addr = address_from_pointer_chain(worldPtr, {0x08, 0xD30, 0x938, a[2]})
			if addr ~= 0 then
				local value = memory.read_float(addr)
				s[ a[1] ] = value
			end
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
	notification.normal(firstUpper(self.vehicle_name) .. ' handling data saved')
end


function handling:create_actions(offsets, s)
	local t = {}
	table.insert(t, menu.divider(handling_editor, firstUpper(s)))
	table.sort(offsets, function(a, b) return a[2] < b[2] end)
	
	for k, a in ipairs(offsets) do
		local action = menu.action(handling_editor, a[1], {}, '', function()
			local addr = address_from_pointer_chain(worldPtr, {0x08, 0xD30, 0x938, a[2]})
			if addr == 0 then return end
			local value = round(memory.read_float(addr), 4)
			local nvalue = DISPLAY_ONSCREEN_KEYBOARD("BS_WB_VAL", 7, value)
			if nvalue == '' then return end
			if tonumber(nvalue) == nil then
				return notification.red('Invalid input')
			elseif tonumber(nvalue) ~= value then
				memory.write_float(addr, tonumber(nvalue))
			end 
		end)
		menu.on_tick_in_viewport(action, function()
			self.inviewport[s] = self.inviewport[s] or {} -- create an empty array if it doesn't exist
			if not table.find(self.inviewport[s], a[1]) then
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
--VEHICLE DOORS
-------------------------------------

local doors_list = menu.list(vehicle_options, menuname('Vehicle', 'Vehicle Doors'), {}, '')


local doors = {
	menuname('Vehicle - Vehicle Doors', 'Driver Door'),
	menuname('Vehicle - Vehicle Doors', 'Passenger Door'),
	menuname('Vehicle - Vehicle Doors', 'Rear Left'),
	menuname('Vehicle - Vehicle Doors', 'Rear Right'),
	menuname('Vehicle - Vehicle Doors', 'Hood'),
	menuname('Vehicle - Vehicle Doors', 'Trunk')
}

menu.divider(doors_list, menuname('Vehicle', 'Vehicle Doors'))

for i, door in ipairs(doors) do
	menu.toggle(doors_list, door, {}, '', function(toggle)
		local vehicle = entities.get_user_vehicle_as_handle()
		if toggle then
			VEHICLE.SET_VEHICLE_DOOR_OPEN(vehicle, i - 1, false, false)
		else
			VEHICLE.SET_VEHICLE_DOOR_SHUT(vehicle, i - 1, false)
		end
	end)
end

menu.toggle(doors_list, menuname('Vehicle - Vehicle Doors', 'All'), {}, '', function(toggle)
	local vehicle = entities.get_user_vehicle_as_handle()
	for i, door in ipairs(doors) do
		if toggle then
			VEHICLE.SET_VEHICLE_DOOR_OPEN(vehicle, i - 1, false, false)
		else
			VEHICLE.SET_VEHICLE_DOOR_SHUT(vehicle, i - 1, false)
		end
	end
end)

-------------------------------------
--UFO
-------------------------------------

local cam
local heli
local object
local zoom = 0.0
local lastzoom
local ifov = alloc()
memory.write_float(ifov, 110)
local counting
local charge = alloc()
memory.write_float(charge, 1.0)
local countdown = 3
local camaddr

menu.toggle(vehicle_options, menuname('Vehicle', 'UFO'), {'ufo'}, 'Drive an UFO, use its tractor beam and cannon.', function(toggle)
	ufo_toggle = toggle

	local blackhole = false
	local cannon = false
	local attracted = {}
	local tick = 0
	local buttons = {
		{'exit', 75},
		{'release tractor beam', 22},
		{'tractor beam', 73},
		{'cannon', 80},
		{'vertical flight', 119}
	}
	local cannonbuttons = {
		{'exit', 75},
		{'zoom', 241},
		{'shoot', 24},
		{'cannon', 80},
		{'vertical flight', 119}
	}
	local sId
	local PLAY_SOUND_FRONTEND = function(audioName, audioRef)
		if AUDIO.HAS_SOUND_FINISHED(sId) then
			sId = AUDIO.GET_SOUND_ID()
			AUDIO.PLAY_SOUND_FRONTEND(sId, audioName, audioRef, true)
		end
	end
	local STOP_SOUND = function(sId)
		AUDIO.STOP_SOUND(sId)
		AUDIO.RELEASE_SOUND_ID(sId)
	end
		
	if ufo_toggle then
		menu.trigger_commands('becomeorbitalcannon on; otr on')
		CAM.DO_SCREEN_FADE_OUT(500)
		wait(600)
		local vehicleHash = joaat('hydra')
		local objHash = joaat('imp_prop_ship_01a')
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
		pos.z = pos.z + 200
		
		STREAMING.REQUEST_MODEL(vehicleHash); STREAMING.REQUEST_MODEL(objHash)
		while not STREAMING.HAS_MODEL_LOADED(vehicleHash) and not STREAMING.HAS_MODEL_LOADED(objHash) do
			wait()
		end

		veh = entities.create_vehicle(vehicleHash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
		while not ENTITY.DOES_ENTITY_EXIST(veh) and tick < 10 do
			wait()
			veh = entities.create_vehicle(vehicleHash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
			tick = tick + 1
		end
		ENTITY.SET_ENTITY_VISIBLE(veh, false, 0)
		PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), veh, -1)
		VEHICLE.SET_VEHICLE_ENGINE_ON(veh, true, true, true)
		VEHICLE._SET_VEHICLE_JET_ENGINE_ON(veh, true)
		ENTITY.SET_ENTITY_INVINCIBLE(veh, true)
		VEHICLE.SET_PLANE_TURBULENCE_MULTIPLIER(veh, 0.0)
		local addr = memory.read_long(entities.handle_to_pointer(veh) + 0x20) + 0x38
		memory.write_float(addr, -20.0)
		camaddr = addr
		
		object = entities.create_object(objHash, pos)
		ENTITY.ATTACH_ENTITY_TO_ENTITY(object, veh, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, true, true, false, 0, true)
		
		cam = CAM.CREATE_CAM("DEFAULT_SCRIPTED_CAMERA", false)
		CAM._ATTACH_CAM_TO_VEHICLE_BONE(cam, veh, 0, true, -90.0, 0.0, 0.0, 0.0, 0.0, -4.0, true)
		CAM.SET_CAM_FOV(cam, memory.read_float(ifov))
		
		CAM.SET_CAM_ACTIVE(cam, true)
		GRAPHICS.SET_SCRIPT_GFX_DRAW_ORDER(1)
		AUDIO.REQUEST_SCRIPT_AUDIO_BANK("DLC_CHRISTMAS2017/XM_ION_CANNON", false, -1)
		wait(600)
		CAM.DO_SCREEN_FADE_IN(500)

		create_tick_handler(function()
			VEHICLE.DISABLE_VEHICLE_WEAPON(true, -123497569, veh, PLAYER.PLAYER_PED_ID())
			VEHICLE.DISABLE_VEHICLE_WEAPON(true, -494786007, veh, PLAYER.PLAYER_PED_ID())
			
			PAD.DISABLE_CONTROL_ACTION(2, 75, true) -- INPUT_VEH_EXIT
			PAD.DISABLE_CONTROL_ACTION(2, 80, true) -- INPUT_VEH_CIN_CAM
			PAD.DISABLE_CONTROL_ACTION(2, 99, true) -- INPUT_VEH_SELECT_NEXT_WEAPON

			local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(veh, 0.0, 0.0, -10.0)
			
			if not cannon then 
				GRAPHICS._DRAW_SPHERE(pos.x, pos.y, pos.z, 1.0, 0, 255, 255, 50)
			end

			if PAD.IS_CONTROL_JUST_PRESSED(2, 73) then
				local groundz = GET_GROUND_Z_FOR_3D_COORD(pos)
				local onground = vect.new(pos.x, pos.y, groundz)
				for k, vehicle in pairs(entities.get_all_vehicles_as_handles()) do
					local vpos = ENTITY.GET_ENTITY_COORDS(vehicle)
					if vect.dist(onground, vpos) < 80 and vehicle ~= veh and #attracted < 15 then
						insert_once(attracted, vehicle)
					end
				end
			end

			for k, vehicle in pairs(attracted) do
				local vpos = ENTITY.GET_ENTITY_COORDS(vehicle)
				if REQUEST_CONTROL(vehicle) then
					local norm = vect.norm(vect.subtract(pos, vpos))
					local mult = vect.dist(pos, vpos) * 3
					local vel = vect.mult(norm, mult)
					ENTITY.SET_ENTITY_VELOCITY(vehicle, vel.x, vel.y, vel.z)
				end
			end

			if PAD.IS_CONTROL_JUST_PRESSED(2, 22) then
				for k, v in pairs(attracted) do attracted[ k ] = nil end
			end
			return ufo_toggle
		end)
		
		-- get all players in the session
		-- if a player ped is on screen draws a lock-on sprite on them
		-- color is cyan for strangers and lime for friends

		create_tick_handler(function()
			if general_config.disablelockon then 
				return ufo_toggle 
			end
			for _, pid in pairs(players.list(false)) do
				if ENTITY.IS_ENTITY_ON_SCREEN(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)) and not players.is_in_interior(pid) then
					local color = {['r'] = 0, ['g'] = 255, ['b'] = 255}
					if IS_PLAYER_FRIEND(pid) then color = {['r'] = 128, ['g'] = 255, ['b'] = 0} end
					DRAW_LOCKON_SPRITE_ON_PLAYER(pid, color)
				end
			end	
			return ufo_toggle 
		end)
	end

	while ufo_toggle do
		wait()
		CAM._DISABLE_VEHICLE_FIRST_PERSON_CAM_THIS_FRAME()
		
		if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(2, 75) or PAD.IS_DISABLED_CONTROL_PRESSED(2, 75) then
			menu.trigger_commands('ufo off')
		end

		if PAD.IS_CONTROL_JUST_PRESSED(2, 80) or PAD.IS_CONTROL_JUST_PRESSED(2, 45) then
			AUDIO.PLAY_SOUND_FRONTEND(-1, 'cannon_active', 'dlc_xm_orbital_cannon_sounds', true)
			zoom = 0.0
			cannon = not cannon
		end

		if cannon then
			local scaleform = GRAPHICS.REQUEST_SCALEFORM_MOVIE('ORBITAL_CANNON_CAM')
			while not GRAPHICS.HAS_SCALEFORM_MOVIE_LOADED(scaleform) do
				wait()
			end

			PAD.DISABLE_CONTROL_ACTION(2, 85, true) -- INPUT_VEH_RADIO_WHEEL
			CAM.RENDER_SCRIPT_CAMS(true, false, 3000, true, false, 0)
			
			GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, 'SET_STATE')
			GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(3)
			GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

			GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, 'SET_CHARGING_LEVEL')
			GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(memory.read_float(charge))
			GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

			if PAD.IS_CONTROL_JUST_PRESSED(2, 241) then
				if zoom < 1.0 then 
					zoom = zoom + 0.25
					PLAY_SOUND_FRONTEND('zoom_out_loop', 'dlc_xm_orbital_cannon_sounds')
				end
			end

			if PAD.IS_CONTROL_JUST_PRESSED(2, 242) then
				if zoom > 0.0 then 
					zoom = zoom - 0.25
					PLAY_SOUND_FRONTEND('zoom_out_loop', 'dlc_xm_orbital_cannon_sounds')
				end
			end
			
			if zoom ~= lastzoom then
				GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SET_ZOOM_LEVEL")
				GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(zoom)
				GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
				lastzoom = zoom
			end

			local fov = 25 + 85 * (1.0 - zoom)
			incr(ifov, fov, 0.5)
			
			if memory.read_float(ifov) ~= fov then
				CAM.SET_CAM_FOV(cam, memory.read_float(ifov))
			elseif not AUDIO.HAS_SOUND_FINISHED(sId) then
				STOP_SOUND(sId)
			end
				
			if PAD.IS_CONTROL_PRESSED(2, 24) then
				if memory.read_float(charge) == 1.0 then
					if not counting then 
						startTime = os.time()
						counting = true
					end

					if countdown ~= 0 then
						if os.difftime(os.time(), startTime) == 1 then
							countdown = countdown - 1	
							startTime = os.time()
						end
						GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SET_COUNTDOWN")
						GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(countdown)
						GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
					else
						memory.write_float(charge, 0.0)
						countdown = 3
						counting = false
						local effect = {['asset'] = 'scr_xm_orbital', ['name'] = 'scr_xm_orbital_blast'}
						local hit, pos, normal, ent = RAYCAST(cam, 1000)
						local rot = GET_ROTATION_FROM_DIRECTION(normal)
						
						STREAMING.REQUEST_NAMED_PTFX_ASSET(effect.asset)
						while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(effect.asset) do
							wait()
						end

						STREAMING.SET_FOCUS_POS_AND_VEL(pos.x, pos.y, pos.z, 5.0, 0.0, 0.0)
						FIRE.ADD_OWNED_EXPLOSION(PLAYER.PLAYER_PED_ID(), pos.x, pos.y, pos.z, 59, 1.0, true, false, 1.0)
						GRAPHICS.USE_PARTICLE_FX_ASSET(effect.asset)
						GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD(
							effect.name, 
							pos.x, 
							pos.y, 
							pos.z, 
							rot.pitch - 90, 
							rot.roll, 
							rot.yaw, 
							1.0, 
							false, false, false, true
						)
						AUDIO.PLAY_SOUND_FROM_COORD(-1, "DLC_XM_Explosions_Orbital_Cannon", pos.x, pos.y, pos.z, 0, true, 0, false)
						CAM.SHAKE_CAM(cam, "GAMEPLAY_EXPLOSION_SHAKE", 1.5)
						STREAMING.CLEAR_FOCUS()
					end
				else
					incr(charge, 1.0, 0.015)
					counting = false
				end
			else
				incr(charge, 1.0, 0.015)
				counting = false
				countdown = 3
			end
			GRAPHICS.SET_SCRIPT_GFX_DRAW_ORDER(0)
			GRAPHICS.DRAW_SCALEFORM_MOVIE_FULLSCREEN(scaleform, 255, 255, 255, 255, 0)
			GRAPHICS.RESET_SCRIPT_GFX_ALIGN()
			dbuttons = cannonbuttons
		else
			CAM.RENDER_SCRIPT_CAMS(false, false, 3000, true, false, 0)
			dbuttons = buttons
		end
		INSTRUCTIONAL.DRAW(dbuttons)
	end

	CAM.DO_SCREEN_FADE_OUT(500)
	wait(600)
	local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
	local ptr1 = alloc()
	STOP_SOUND(sId)
	AUDIO.RELEASE_NAMED_SCRIPT_AUDIO_BANK("DLC_CHRISTMAS2017/XM_ION_CANNON")
	PATHFIND.GET_CLOSEST_VEHICLE_NODE(pos.x, pos.y, pos.z, ptr1, 1, 100, 2.5)
	pos = memory.read_vector3(ptr1)
	memory.write_float(camaddr, -1.57)
	entities.delete_by_handle(veh); entities.delete_by_handle(object)
	ENTITY.SET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), pos.x, pos.y, pos.z, false, false, false)
	ENTITY.SET_ENTITY_VISIBLE(PLAYER.PLAYER_PED_ID(), true, 0)
	CAM.SET_CAM_ACTIVE(cam, false)
	CAM.RENDER_SCRIPT_CAMS(false, false, 3000, true, false, 0)
	CAM.DESTROY_CAM(cam, false)
	wait(600)
	CAM.DO_SCREEN_FADE_IN(500)
	menu.trigger_commands('becomeorbitalcannon off; otr off')
end)


-------------------------------------
--VEHICLE INSTANT LOCK
-------------------------------------

menu.toggle(vehicle_options, menuname('Vehicle', 'Vehicle Instant Lock-On'), {}, '', function(toggle)
	vehlock = toggle
	local default = {}
	local offsets = {0x08, 0x10D8, 0x70, 0x60, 0x178}

	while vehlock do
		wait()
		local ptr = alloc()
		local addr = address_from_pointer_chain(worldPtr, offsets)
		if addr ~= 0 then
			local value = memory.read_float(addr)
			if value ~= 0.0 then
				table.insert(default, {['addr'] = addr, ['value'] = value})
				memory.write_float(addr, 0.0)
			end
		end
	end

	if #default > 0 then
		for k, t in pairs(default) do
			memory.write_float(t.addr, t.value)
		end
	end
end)

-------------------------------------
--VEHICLE EFFECTS
-------------------------------------

local effects = {
	['Clown Appears'] = {
		['name'] = 'scr_clown_appears',
		['asset'] = 'scr_rcbarry2',
		['scale'] = 0.3,
		['delay'] = 500
	},
	['Alien Impact'] = {
		['name'] = 'scr_alien_impact_bul',
		['asset'] = 'scr_rcbarry1',
		['scale'] = 1.0,
		['delay'] = 50
	},
	['Electic Fire'] = {
		['name'] = 'ent_dst_elec_fire_sp',
		['asset'] = 'core',
		['scale'] = 0.8,
		['delay'] = 25
	}
}

local effect = effects['Clown Appears']

local vehicle_ptfx = menu.toggle(vehicle_options, menuname('Vehicle', 'Vehicle Effect')..': Clown Appears', {'vehicleptfx'}, '', function(toggle)
	particleveh = toggle
	local bones = {
		'wheel_lf',
		'wheel_lr',
		'wheel_rf',
		'wheel_rr'
	}

	while particleveh do
		wait(effect.delay)
		local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), true)
		if not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(effect.asset) then
			STREAMING.REQUEST_NAMED_PTFX_ASSET(effect.asset)
			while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(effect.asset) do
				wait()
			end
		end

		for k, bone in pairs(bones) do
			GRAPHICS.USE_PARTICLE_FX_ASSET(effect.asset)
			GRAPHICS._START_NETWORKED_PARTICLE_FX_NON_LOOPED_ON_ENTITY_BONE(
				effect.name,
				vehicle,
				0.0, --offsetX
				0.0, --offsetY
				0.0, --offsetZ
				0.0, --rotX
				0.0, --rotY
				0.0, --rotZ
				ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(vehicle, bone),
				effect.scale, --scale
				false, false, false
			)
		end
	end
end)


local select_effect = menu.list(vehicle_options, menuname('Vehicle', 'Set Vehicle Effect'))

menu.divider(select_effect, menuname('Vehicle', 'Set Vehicle Effect'))


for k, v in pairs_by_keys(effects) do
	menu.action(select_effect, k, {}, '', function()
		effect = v
		menu.set_menu_name(vehicle_ptfx, 'Vehicle Effect: '..k)
		if not particleveh then menu.trigger_command(vehicle_ptfx,  'on') end
		menu.trigger_command(vehicle_options,  '')
	end)
end

-------------------------------------
--AUTOPILOT
-------------------------------------

local driving_style_flag = {
	['Stop Before Vehicles'] = 1,
	['Stop Before Peds'] = 2,
	['Avoid Vehicles'] = 4,
	['Avoid Empty Vehicles'] = 8,
	['Avoid Peds'] = 16,
	['Avoid Objects'] = 32,
	['Stop At Traffic Lights'] = 128,
	['Reverse Only'] = 1024,
	['Take Shortest Path'] = 262144,
	['Ignore Roads'] = 4194304,
	['Ignore All Pathing'] = 16777216
}

local drivingstyle = 786988
local presets = {
	{
	  ['name'] = menuname('Settings - Driving Style', 'Normal'), 
	  ['description'] = 'Stop before vehicles & peds, avoid empty vehicles & objects and stop at traffic lights.',
	  ['int'] = 786603
	},
	{
	  ['name'] = menuname('Settings - Driving Style', 'Ignore Lights'),
	  ['description'] = 'Stop before vehicles, avoid vehicles & objects.', 
	  ['int'] = 2883621
	},
	{
	  ['name'] = menuname('Settings - Driving Style', 'Avoid Traffic'),
	  ['description'] = 'Avoid vehicles & objects.', 
	  ['int'] = 786468
	},
	{
	  ['name'] = menuname('Settings - Driving Style', 'Rushed'),
	  ['description'] = 'Stop before vehicles, avoid vehicles, avoid objects', 
	  ['int'] = 1074528293
	},
	{
	  ['name'] = menuname('Settings - Driving Style', 'Default'),
	  ['description'] = 'Avoid vehicles, empty vehicles & objects, allow going wrong way and take shortest path', 
	  ['int'] = 786988
	}
}
local selected_flags = {}
local list_autopilot = menu.list(vehicle_options, menuname('Vehicle', 'Autopilot'))

menu.divider(list_autopilot, menuname('Vehicle', 'Autopilot'))


menu.toggle(list_autopilot, menuname('Vehicle', 'Autopilot'), {'autopilot'}, '', function(toggle)
	autopilot = toggle

	if autopilot then
		local lastblip
		local lastdrivstyle
		local lastspeed
		
		local function DRIVE_TO_WAYPOINT()
			local vehicle = entities.get_user_vehicle_as_handle()
			if vehicle ~= 0 then
				local coord
				local ptr = alloc()
				local blip = HUD.GET_FIRST_BLIP_INFO_ID(8)

				if blip == 0 then
					notification.normal('Set a waypoint to start driving')
				else
					coord = HUD.GET_BLIP_COORDS(blip)
					PED.SET_DRIVER_ABILITY(PLAYER.PLAYER_PED_ID(), 0.5);

					TASK.OPEN_SEQUENCE_TASK(ptr)
					TASK.TASK_VEHICLE_DRIVE_TO_COORD_LONGRANGE(0, vehicle, coord.x, coord.y, coord.z, autopilot_speed or 25.0, drivingstyle, 45.0);
					TASK.TASK_VEHICLE_PARK(0, vehicle, coord.x, coord.y, coord.z, ENTITY.GET_ENTITY_HEADING(vehicle), 7, 60.0, true);
					TASK.CLOSE_SEQUENCE_TASK(memory.read_int(ptr));
					TASK.TASK_PERFORM_SEQUENCE(PLAYER.PLAYER_PED_ID(), memory.read_int(ptr))
					TASK.CLEAR_SEQUENCE_TASK(ptr)

					lastspeed = autopilot_speed or 25.0
					lastblip = blip
					lastdrivstyle = drivingstyle
					return coord
				end
			end
		end

		local lastcoord  = DRIVE_TO_WAYPOINT()
		
		while autopilot do
			wait()
			local blip = HUD.GET_FIRST_BLIP_INFO_ID(8)

			if drivingstyle ~= lastdrivstyle  then
				lastcoord = DRIVE_TO_WAYPOINT()
				lastdrivstyle = drivingstyle
			end

			if blip ~= lastblip then
				lastcoord = DRIVE_TO_WAYPOINT()
				lastblip = blip
			end

			if lastspeed ~= autopilot_speed then
				lastcoord = DRIVE_TO_WAYPOINT()
				lastspeed = autopilot_speed
			end
		end
	else
		TASK.CLEAR_PED_TASKS(PLAYER.PLAYER_PED_ID())
	end
end)


local menu_driving_style = menu.list(list_autopilot, menuname('Settings', 'Driving Style'), {}, '')

menu.divider(menu_driving_style, menuname('Settings', 'Driving Style'))

menu.divider(menu_driving_style, menuname('Settings - Driving Style', 'Presets'))


for k, style in pairs(presets) do
	menu.action(menu_driving_style, style.name, {}, style.description, function()
		drivingstyle = style.int
	end)
end

menu.divider(menu_driving_style, menuname('Settings - Driving Style', 'Custom'))


for k, flag in pairs(driving_style_flag) do
	menu.toggle(menu_driving_style, k, {}, '', function(toggle) 
		local toggle = toggle
		if toggle then
			table.insert(selected_flags, flag)
		else
			for j = 1, #selected_flags do
				if selected_flags[j] == flag then
					selected_flags[j] = nil
				end
			end
		end
	end)
end


menu.action(menu_driving_style, menuname('Settings - Driving Style', 'Set Custom Driving Style'), {}, '', function()
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
--ENGINE ALWAYS ON
-------------------------------------

menu.toggle_loop(vehicle_options, menuname('Vehicle', 'Engine Always On'), {'alwayson'}, '', function()
	local veh = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
	if ENTITY.DOES_ENTITY_EXIST(veh) then
		VEHICLE.SET_VEHICLE_ENGINE_ON(veh, true, true, true)
		VEHICLE.SET_VEHICLE_LIGHTS(veh, 0)
		VEHICLE._SET_VEHICLE_LIGHTS_MODE(veh, 2)
	end
end)

-------------------------------------
--BODYGUARD MENU
-------------------------------------

local bodyguards_options = menu.list(menu.my_root(), menuname('Bodyguard Menu', 'Bodyguard Menu'), {'bodyguardmenu'}, '')

menu.divider(bodyguards_options, menuname('Bodyguard Menu', 'Bodyguard Menu'))

-------------------------------------
--BODYGUARD
-------------------------------------


local bodyguard = {
	godmode = false,
	ignoreplayers = false,
	random_model = true, 	--	random model
	random_weapon = true,	--	random weapon
	spawned = {},
	backup_godmode = false
}

menu.action(bodyguards_options, menuname('Bodyguard Menu', 'Spawn Bodyguard (7 Max)'), {'spawnbodyguard'}, '', function()
	local user_ped = PLAYER.PLAYER_PED_ID()
	local pos = ENTITY.GET_ENTITY_COORDS(user_ped)
	local size_ptr =  alloc(32); local any_ptr = alloc(32)
	local groupId = PED.GET_PED_GROUP_INDEX(user_ped); PED.GET_GROUP_SIZE(groupId, any_ptr, size_ptr); local groupSize = memory.read_int(size_ptr); memory.free(size_ptr); memory.free(any_ptr)
	if groupSize == 7 then
		return notification.red('You reached the max number of bodyguards')
	end
	pos.x = pos.x + math.random(-3, 3)
	pos.y = pos.y + math.random(-3, 3)
	pos.z = pos.z - 1.0
	local weapon, model
	if bodyguard.random_weapon then weapon = random(weapons) else weapon = bodyguard.weapon end
	if bodyguard.random_model then model = random(peds) else model = bodyguard.model end
	local pedHash = joaat(model)
	STREAMING.REQUEST_MODEL(pedHash)
	while not STREAMING.HAS_MODEL_LOADED(pedHash) do 
		wait()
	end
	local pedNetId = NETWORK.PED_TO_NET(entities.create_ped(29, pedHash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z)); insert_once(bodyguard.spawned, model)
	if NETWORK.NETWORK_GET_ENTITY_IS_NETWORKED(NETWORK.NET_TO_PED(pedNetId)) then
		NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(pedNetId, true)
	end
	NETWORK.SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER(pedNetId, players.user(), true)
	local ped = NETWORK.NET_TO_PED(pedNetId)
	WEAPON.GIVE_WEAPON_TO_PED(ped, joaat(weapon), -1, false, true)
	PED.SET_PED_HIGHLY_PERCEPTIVE(ped, true)
	PED.SET_PED_COMBAT_RANGE(ped, 2)
	PED.SET_PED_SEEING_RANGE(ped, 100.0)
	ENTITY.SET_ENTITY_INVINCIBLE(ped, bodyguard.godmode)
	PED.SET_PED_AS_GROUP_MEMBER(ped, groupId)
	PED.SET_PED_NEVER_LEAVES_GROUP(ped, true)
	PED.SET_GROUP_FORMATION(groupId, 0)
	PED.SET_GROUP_FORMATION_SPACING(groupId, 1.0, 0.9, 3.0)
	SET_ENT_FACE_ENT(ped, user_ped)
	if bodyguard.ignoreplayers then
		local relHash = PED.GET_PED_RELATIONSHIP_GROUP_HASH(PLAYER.PLAYER_PED_ID())
		PED.SET_PED_RELATIONSHIP_GROUP_HASH(ped, relHash)
	else
		set_relationship.friendly(ped)
	end
end)


local bodyguards_model_list = menu.list(bodyguards_options, menuname('Bodyguard Menu', 'Set Model')..': Random', {}, '')

menu.divider(bodyguards_model_list, 'Bodyguard Model List')


menu.action(bodyguards_model_list, 'Random Model', {}, '', function()
	bodyguard.random_model = true
	menu.set_menu_name(bodyguards_model_list, menuname('Bodyguard Menu', 'Set Model')..': Random')
	menu.trigger_command(bodyguards_options, '')
end)


for k, model in pairs_by_keys(peds) do
	menu.action(bodyguards_model_list, k, {}, '', function()
		bodyguard.model = model
		bodyguard.random_model = false
		menu.set_menu_name(bodyguards_model_list, menuname('Bodyguard Menu', 'Set Model')..': '..k)
		menu.trigger_command(bodyguards_options, '')
	end)
end


menu.action(bodyguards_options, menuname('Bodyguard Menu', 'Clone Player (Bodyguard)'), {'clonebodyguard'}, '', function()
	local user_ped = PLAYER.PLAYER_PED_ID()
	local size_ptr =  alloc(32)
	local any_ptr = alloc(32)
	local pos = ENTITY.GET_ENTITY_COORDS(user_ped)
	local groupId = PLAYER.GET_PLAYER_GROUP(players.user()); PED.GET_GROUP_SIZE(groupId, any_ptr, size_ptr); local groupSize = memory.read_int(size_ptr); memory.free(size_ptr); memory.free(any_ptr)
	if groupSize >= 7 then
		return notification.red('You reached the max number of bodyguards')
	end
	pos.x = pos.x + math.random(-3, 3)
	pos.y = pos.y + math.random(-3, 3)
	pos.z = pos.z - 1.0
	local weapon
	if bodyguard.random_weapon then weapon = random(weapons) else weapon = bodyguard.weapon end
	local clone = PED.CLONE_PED(user_ped, 1, 1, 1); insert_once(bodyguard.spawned, 'mp_f_freemode_01'); insert_once(bodyguard.spawned, 'mp_m_freemode_01')
	
	if read_global.byte(262145 + 4723) == 1 then --XMAS
		PED.SET_PED_PROP_INDEX(clone, 0, 22, 0, true)
	end
	
	WEAPON.GIVE_WEAPON_TO_PED(clone, joaat(weapon), 9999, false, true)
	PED.SET_PED_HIGHLY_PERCEPTIVE(clone, true)
	PED.SET_PED_COMBAT_RANGE(clone, 2)
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
		set_relationship.friendly(clone)
	end
end)


local bodyguards_weapon_list = menu.list(bodyguards_options, menuname('Bodyguard Menu', 'Set Weapon')..': Random')

menu.divider(bodyguards_weapon_list, 'Bodyguard Weapon List')

local bodyguards_melee_list = menu.list(bodyguards_weapon_list, 'Melee')


for k, weapon in pairs_by_keys(melee_weapons) do
	menu.action(bodyguards_melee_list, k, {}, '', function()
		bodyguard.weapon = weapon
		bodyguard.random_weapon = false
		menu.set_menu_name(bodyguards_weapon_list, menuname('Bodyguard Menu', 'Set Weapon')..': '..k)
		menu.trigger_command(bodyguards_options, '')
	end)
end


menu.action(bodyguards_weapon_list,'Random Weapon', {}, '', function()
	bodyguard.random_weapon = true
	menu.set_menu_name(bodyguards_weapon_list, menuname('Bodyguard Menu', 'Set Weapon')..': Random')
	menu.trigger_command(bodyguards_options, '')
end)


for k, weapon in pairs_by_keys(weapons) do
	menu.action(bodyguards_weapon_list, k, {}, '', function()
		bodyguard.weapon = weapon
		bodyguard.random_weapon = false
		menu.set_menu_name(bodyguards_weapon_list, menuname('Bodyguard Menu', 'Set Weapon')..': '..k)
		menu.trigger_command(bodyguards_options, '')
	end)
end


menu.toggle(bodyguards_options, menuname('Bodyguard Menu', 'Invincible Bodyguard'), {'bodyguardsgodmode'}, '', function(toggle)
	bodyguard.godmode = toggle
end)


menu.toggle(bodyguards_options, menuname('Bodyguard Menu', 'Ignore Players'), {}, '', function(toggle)
	bodyguard.ignoreplayers = toggle
end)


menu.action(bodyguards_options, menuname('Bodyguard Menu', 'Delete Bodyguards'), {}, '', function()
	local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
	local pos = ENTITY.GET_ENTITY_COORDS(p, false)
	for i, model in ipairs(bodyguard.spawned) do
		DELETE_PEDS(model)
		bodyguard.spawned[i] = nil
	end
end)

-------------------------------------
--BACKUP HELICOPTER
-------------------------------------

local backup_heli_option = menu.list(bodyguards_options,  menuname('Bodyguard Menu', 'Backup Helicopter'))

menu.divider(backup_heli_option, menuname('Bodyguard Menu', 'Backup Helicopter'))


menu.action(backup_heli_option, menuname('Bodyguard Menu - Backup Helicopter', 'Spawn Backup Helicopter'), {'backupheli'}, '', function()
	local user_ped = PLAYER.PLAYER_PED_ID()
	local pos = ENTITY.GET_ENTITY_COORDS(user_ped)
	pos.x = pos.x + math.random(-20, 20)
	pos.y = pos.y + math.random(-20, 20)
	pos.z = pos.z + math.random(20, 40)
	local heli_hash = joaat('buzzard2')
	local ped_hash = joaat('s_m_y_blackops_01')
	STREAMING.REQUEST_MODEL(ped_hash); STREAMING.REQUEST_MODEL(heli_hash)
	while not STREAMING.HAS_MODEL_LOADED(ped_hash) or not STREAMING.HAS_MODEL_LOADED(heli_hash) do
		wait()
	end
	set_relationship.friendly(user_ped)
	local heli= entities.create_vehicle(heli_hash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
	if not ENTITY.DOES_ENTITY_EXIST(heli) then 
		notification.red('Failed to create vehicle. Please try again')
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

	local function create_ped_into_vehicle(seat, godmode)
		local pedNetId = NETWORK.PED_TO_NET(entities.create_ped(29, ped_hash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z))
		if NETWORK.NETWORK_GET_ENTITY_IS_NETWORKED(NETWORK.NET_TO_PED(pedNetId)) then
			NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(pedNetId, true)
		end
		NETWORK.SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER(pedNetId, players.user(), true)
		local ped = NETWORK.NET_TO_PED(pedNetId)
		PED.SET_PED_INTO_VEHICLE(ped, heli, seat)
		WEAPON.GIVE_WEAPON_TO_PED(ped, joaat('weapon_combatmg'), -1, false, true)
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
		ENTITY.SET_ENTITY_INVINCIBLE(ped, godmode)
		if bodyguard.ignoreplayers then
			local relHash = PED.GET_PED_RELATIONSHIP_GROUP_HASH(PLAYER.PLAYER_PED_ID())
			PED.SET_PED_RELATIONSHIP_GROUP_HASH(ped, relHash)
		else
			set_relationship.friendly(ped)
		end
		return pedNetId
	end

	local pilot = NETWORK.NET_TO_PED(create_ped_into_vehicle(-1, bodyguard.backup_godmode))
	PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(pilot, true)
	for seat = 1, 2 do
		create_ped_into_vehicle(seat, bodyguard.backup_godmode)
	end
	STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(heli_hash)

	local function give_task_to_pilot(param0, param1)
		if param1 ~= param0 then
			if param0 == 0 then
				TASK.TASK_HELI_CHASE(pilot, user_ped, 0, 0, 50)
				PED.SET_PED_KEEP_TASK(pilot, true)
			end
			if param0 == 1 then
				TASK.TASK_HELI_MISSION(pilot, heli, 0, user_ped, 0.0, 0.0, 0.0, 23, 20.0, 40.0, -1.0, SYSTEM.CEIL(-1.0), 10, -1.0, 0)
				PED.SET_PED_KEEP_TASK(pilot, true)
			end
		end
		return param0
	end
	
	util.create_thread(function()
		local param0, param1
		while ENTITY.GET_ENTITY_HEALTH(pilot) > 0 do
			local user_ped = PLAYER.PLAYER_PED_ID()
			local a, b = ENTITY.GET_ENTITY_COORDS(user_ped), ENTITY.GET_ENTITY_COORDS(heli)
			
			if MISC.GET_DISTANCE_BETWEEN_COORDS(a.x, a.y, a.z, b.x, b.y, b.z, true) > 90 then
				param0 = 0
			else
				param0 = 1
			end
			param1 = give_task_to_pilot(param0, param1)
			wait()
		end
	end)
	STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(ped_hash)
end)


menu.toggle(backup_heli_option, menuname('Bodyguard Menu - Backup Helicopter', 'Invincible Backup'), {'backupgodmode'}, '', function(toggle)
	bodyguard.backup_godmode = toggle
end)


-------------------------------------
--WORD
-------------------------------------

local world_options = menu.list(menu.my_root(), menuname('World', 'World'), {}, '')

menu.divider(world_options, menuname('World', 'World'))

-------------------------------------
--JUMPING CARS
-------------------------------------

menu.toggle(world_options, menuname('World', 'Jumping Cars'), {}, '', function(toggle)
	jumpingcars = toggle
	create_tick_handler(function()
		wait(1500)
		local entities = GET_NEARBY_VEHICLES(players.user(), 120)
		for k, vehicle in pairs(entities) do
			REQUEST_CONTROL(vehicle)
			ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, 0, 0, 6.5, 0, 0, 0, 0, false, false, true)
		end
		return jumpingcars
	end)
end)

-------------------------------------
--KILL ENEMIES
-------------------------------------

menu.action(world_options, menuname('World', 'Kill Enemies'), {'killenemies'}, '', function()
	local peds = GET_NEARBY_PEDS(players.user(), 500)
	for k, ped in pairs(peds) do
		local rel = PED.GET_RELATIONSHIP_BETWEEN_PEDS(PLAYER.PLAYER_PED_ID(), ped)
		if rel == 4 or rel == 5 or PED.IS_PED_IN_COMBAT(ped, PLAYER.PLAYER_PED_ID()) and not ENTITY.IS_ENTITY_DEAD(ped) then
			local pos = ENTITY.GET_ENTITY_COORDS(ped)
			FIRE.ADD_OWNED_EXPLOSION(PLAYER.PLAYER_PED_ID(), pos.x, pos.y, pos.z, 1, 1.0, true, false, 0.0)
		end
	end
end)


menu.toggle_loop(world_options, menuname('World', 'Auto Kill Enemies'), {'autokillenemies'}, '', function()
	local peds = GET_NEARBY_PEDS(players.user(), 500)
	for k, ped in pairs(peds) do
		local rel = PED.GET_RELATIONSHIP_BETWEEN_PEDS(PLAYER.PLAYER_PED_ID(), ped)
		if rel == 4 or rel == 5 or PED.IS_PED_IN_COMBAT(ped, PLAYER.PLAYER_PED_ID()) and not ENTITY.IS_ENTITY_DEAD(ped) then
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
	'molotov',
	'starling',
	'bombishka',
	'howard',
	'duster',
	'luxor2',
	'lazer',
	'nimbus',
	'shamal',
	'stunt',
	'titan',
	'velum2',
	'milijet',
	'mamatus',
	'besra',
	'cuban800',
	'saebreeze'
}


menu.toggle(world_options, menuname('World', 'Angry Planes'), {}, '', function(toggle)
	angryplanes = toggle
	local spawned = {}

	create_tick_handler(function()
		for k, plane in pairs(spawned) do
			if ENTITY.IS_ENTITY_DEAD(plane.plane) then
				spawned[ k ] = nil
			end
		end
		return angryplanes
	end)

	while angryplanes do
		wait(1000)
		if #spawned < 40 then
			local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
			local theta = (math.random() + math.random(0, 1)) * math.pi --returns a random angle between 0 and 2pi (exclusive)
			local radius = math.random(50, 150)
			pos = vect.new(
				pos.x + radius * math.cos(theta),
				pos.y + radius * math.sin(theta),
				pos.z + 200
			)
			local jet_hash = joaat(random(planes))
			local ped_hash = joaat('s_m_y_blackops_01')
			STREAMING.REQUEST_MODEL(jet_hash); STREAMING.REQUEST_MODEL(ped_hash)
			while not STREAMING.HAS_MODEL_LOADED(jet_hash) and not STREAMING.HAS_MODEL_LOADED(ped_hash) do
				wait()
			end
			local jet = entities.create_vehicle(jet_hash, pos, math.deg(theta))
			if jet ~= 0 then
				local pilot = entities.create_ped(5, ped_hash, pos, math.deg(theta))
				table.insert(spawned, {['plane'] = jet, ['pilot'] = pilot})
				PED.SET_PED_INTO_VEHICLE(pilot, jet, -1)
				VEHICLE._SET_VEHICLE_JET_ENGINE_ON(jet, true)
				VEHICLE.SET_VEHICLE_FORWARD_SPEED(jet, 60)
				VEHICLE.SET_HELI_BLADES_FULL_SPEED(jet)
				VEHICLE.CONTROL_LANDING_GEAR(jet, 3)
				VEHICLE.SET_VEHICLE_FORCE_AFTERBURNER(jet, true)
				TASK.TASK_PLANE_MISSION(pilot, jet, 0, PLAYER.PLAYER_PED_ID(), 0, 0, 0, 6, 100, 0, 0, 80, 50)
				PED.SET_PED_COMBAT_ATTRIBUTES(pilot, 1, true)
			end
		end
	end
	for k, plane in pairs(spawned) do
		entities.delete_by_handle(plane.plane)
		entities.delete_by_handle(plane.pilot)
	end
end)

-------------------------------------
--WIRISCRIPT
-------------------------------------

local script = menu.list(menu.my_root(), 'WiriScript', {}, '')

menu.divider(script, 'WiriScript')

menu.action(script, menuname('WiriScript', 'Show Credits'), {}, '', function()
	if showing_intro then return end
	
	local state = 0
	local ctime = util.current_time_millis
	local stime = ctime()
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
		{'wiriscript', 'HUD_COLOUR_TREVOR'}
	}
	local buttons = {
		{'skip', 194}
	}
	AUDIO.SET_MOBILE_RADIO_ENABLED_DURING_GAMEPLAY(true)
	AUDIO.SET_MOBILE_PHONE_RADIO_STATE(true)
	AUDIO.SET_RADIO_TO_STATION_NAME("RADIO_01_CLASS_ROCK")
	AUDIO.SET_CUSTOM_RADIO_TRACK_LIST("RADIO_01_CLASS_ROCK", "END_CREDITS_SAVE_MICHAEL_TREVOR", true)

	create_tick_handler(function()
		local scaleform = GRAPHICS.REQUEST_SCALEFORM_MOVIE('OPENING_CREDITS')
		
		while not GRAPHICS.HAS_SCALEFORM_MOVIE_LOADED(scaleform) do
			wait()
		end
	
		if ctime() - stime >= delay and state == 0 then
			SETUP_SINGLE_LINE(scaleform)
			ADD_TEXT_TO_SINGLE_LINE(scaleform, ty[i][1] or ty[i], '$font2', ty[i][2] or 'HUD_COLOUR_WHITE')
			GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, 'SHOW_SINGLE_LINE')
			GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_TEXTURE_NAME_STRING('presents')
			GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
		
			GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, 'SHOW_CREDIT_BLOCK')
			GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_TEXTURE_NAME_STRING('presents')
			GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(0.5)
			GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
		
			state = 1
			i = i + 1
			delay = 4000
			stime = ctime()
		end
	
		if ctime() - stime >= 4000 and state == 1 then
			HIDE(scaleform)
			state = 0
			stime = ctime()
		end
	
		if state == 1 and i == #ty + 1 then
			state = 2
			stime = ctime()
		end

		if ctime() - stime >= 3000 and state == 2 then
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
			stime = ctime()
		elseif state ~= 2 then
			INSTRUCTIONAL.DRAW(buttons)
		end
		HUD.HIDE_HUD_AND_RADAR_THIS_FRAME()
		HUD._HUD_WEAPON_WHEEL_IGNORE_SELECTION()
		GRAPHICS.DRAW_SCALEFORM_MOVIE_FULLSCREEN(scaleform, 255, 255, 255, 255, 0)
		return true
	end)
end)

menu.hyperlink(menu.my_root(), 'Join WiriScript FanClub', 'https://cutt.ly/wiriscript-fanclub', 'Join us in our fan club, created by komt.')

for pid = 0,30 do 
	if players.exists(pid) then
		GenerateFeatures(pid)
	end
end

players.on_join(GenerateFeatures)

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

	if ufo_toggle then
		local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
		if ENTITY.GET_ENTITY_MODEL(vehicle) == joaat('hydra') then
			local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
			local ptr1 = alloc()
			local addr = memory.read_long(entities.handle_to_pointer(vehicle) + 0x20) + 0x38
			memory.write_float(addr, -1.57)
			local obj = OBJECT.GET_CLOSEST_OBJECT_OF_TYPE(pos.x, pos.y, pos.z, 4.0, joaat('imp_prop_ship_01a'), 0, 0, 1)
			if ENTITY.DOES_ENTITY_EXIST(obj) and ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(obj, vehicle) then
				local netID = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(obj)
				NETWORK.SET_NETWORK_ID_CAN_MIGRATE(netID, 1)
				ENTITY.SET_ENTITY_AS_MISSION_ENTITY(vehicle, 1, 1)
				ENTITY.SET_ENTITY_AS_MISSION_ENTITY(obj, 1, 1)
				entities.delete_by_handle(vehicle)
				entities.delete_by_handle(obj)
				PATHFIND.GET_CLOSEST_VEHICLE_NODE(pos.x, pos.y, pos.z, ptr1, 1, 100, 2.5)
				pos = memory.read_vector3(ptr1)
				ENTITY.SET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), pos.x, pos.y, pos.z, false, false, false)
				ENTITY.SET_ENTITY_VISIBLE(PLAYER.PLAYER_PED_ID(), true, 0)
				CAM.RENDER_SCRIPT_CAMS(false, false, 3000, true, false, 0)
			end
		end
	end
end)


while true do
	wait()
-------------------------------------
--AMMO SPEED MULT
-------------------------------------

	if speed_mult ~= 1.0 then
		SET_AMMO_SPEED_MULT(speed_mult)
	end

-------------------------------------
--HANDLING DISPLAY
-------------------------------------

	if handling.display_handling then
		handling.vehicle_name = GET_USER_VEHICLE_NAME()
		handling.vehicle_model = GET_USER_VEHICLE_MODEL()

		if PAD.IS_CONTROL_JUST_PRESSED(2, 323) or PAD.IS_DISABLED_CONTROL_JUST_PRESSED(2, 323) then
			UI.toggle_cursor_mode()
			handling.cursor_mode = not handling.cursor_mode
		end

		UI.set_highlight_colour(highlightcolour.r, highlightcolour.g, highlightcolour.b)
		UI.begin('Vehicle Handling', handling.window_x, handling.window_y)
		UI.label('Current Vehicle\t', handling.vehicle_name)

		for s, l in pairs(handling.inviewport) do
			if #s > 0 then
				local subhead = firstUpper(s)
				UI.subhead(subhead)
				for _, a in ipairs(l) do
					local addr = address_from_pointer_chain(worldPtr, {0x08, 0xD30, 0x938, a[2]})
					local value

					if addr == 0 then
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
					handling.flying[i] = nil
				end
			end

			if VEHICLE.IS_THIS_MODEL_A_BOAT(handling.vehicle_model) and #handling.boat == 0 then
				handling.boat = handling:create_actions(handling.offsets[3], 'boat')
			end

			if not VEHICLE.IS_THIS_MODEL_A_BOAT(handling.vehicle_model) and #handling.boat > 0 then
				for i, Id in ipairs(handling.boat) do
					menu.delete(Id)
					handling.boat[i] = nil
				end
			end
		end

		UI.divider()
		UI.start_horizontal()
		   
		if UI.button('Save Handling', buttonscolour, colour.div(buttonscolour, 5/3)) then
			handling:save()
		end

		if UI.button('Load Handling', buttonscolour, colour.div(buttonscolour, 5/3)) then
			handling:load()
		end
		
		UI.end_horizontal()
		handling.window_x, handling.window_y = UI.finish()
		local buttons = {
			{'toggle cursor mode', 323, true}
		}
		INSTRUCTIONAL.DRAW(buttons)
	end
end

--a message for whoever is watching this: I love you <3 kek
