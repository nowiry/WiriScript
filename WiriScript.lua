-------------------------------------------------------------------WiriScript v11---------------------------------------------------------------------------------------
--[[ Thanks to
		
		DeF3c,
		Hollywood Collins,
		Murten,
		MrPainKiller for the name suggestion,	
		Koda,
		ICYPhoenix,
		jayphen,
		Fwishky,
		Polygon
		komt, <3
		Ren, 
		Sainan,
		NONECKED

and all other developers who shared their work and nice people who helped me. All of you guys teached me things I used in this script <3.
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
This is an open code for you to use and share. Feel free to add, modify or remove features as long as you don't try to sell this script. Please consider 
sharing your own versions with Stand's community. --]]
-------------------------------------------------------------------by: nowiry------------------------------------------------------------------------------------------

util.require_no_lag('natives-1627063482')
require 'lua_imGUI V2-1'
UI = UI.new()

local audible = true
local delay = 300
local scriptdir = filesystem.scripts_dir()
local languages = filesystem.list_files(scriptdir..'\\WiriScript\\Language')
local owned = false
local cage_type = 1
local spoofname, spoofrid = true, true
local version = 11
local spawned_attackers = {}
local explosive_bandito_sent = false
local minitank_weapon
local random_minitank_weapon = true
local hostile_group
local friendly_group
local worldPtr = memory.rip(memory.scan('48 8B 05 ? ? ? ? 45 ? ? ? ? 48 8B 48 08 48 85 C9 74 07') + 3)
if worldPtr == 0 then
	notification.red('Pattern scan failed')
	return
end

wait = util.yield
joaat = util.joaat
alloc = memory.alloc

---------------------------------
--CONFIG
---------------------------------

configlist = {
	['controls'] = 
	{
		vehicleweapons = 86,
		airstrikeaircraft = 86
	},
	['drivingstyle'] = 
	{
		drivingstyle = 786988
	},
	['general'] =
	{
		standnotifications = false,
		displayhealth = true,
		language = 'english'
	}
}

-----------------------------------
--FILE SYSTEM
-----------------------------------

if not filesystem.exists(scriptdir..'\\WiriScript') then
	filesystem.mkdir(scriptdir..'\\WiriScript')
end

if not filesystem.exists(scriptdir..'\\WiriScript\\Language') then
	filesystem.mkdir(scriptdir..'\\WiriScript\\Language')
end

if filesystem.exists(scriptdir..'\\WiriScript\\logo.png') then
	os.remove(scriptdir..'\\WiriScript\\logo.png')
end

if filesystem.exists(scriptdir..'\\WiriScript\\config.data') then --deleting the old config file
	os.remove(scriptdir..'\\WiriScript\\config.data')
end

if filesystem.exists(scriptdir..'\\savednames.data') then
	os.remove(scriptdir..'\\savednames.data')
end

if not filesystem.exists(scriptdir..'\\WiriScript\\Profiles') then
	filesystem.mkdir(scriptdir..'\\WiriScript\\Profiles')
end

if not filesystem.exists(scriptdir..'\\WiriScript\\Handling') then 
	filesystem.mkdir(scriptdir..'\\WiriScript\\Handling') 
end

---------------------------------

local config_file = (scriptdir..'\\WiriScript\\config.ini')

local ini = {
	['save'] = function(file, t)
		file = io.open(file, 'w')
		local contents = ''
		for section, s in pairs(t) do
			contents = contents..('[%s]\n'):format(section)
			for key, value in pairs(s) do
				contents = contents..('%s=%s\n'):format(key, tostring(value))
			end
			contents = contents..'\n'
		end
		file:write(contents)
		file:close()
	end,
	
	['load'] = function(file)
		if not filesystem.exists(file) then 
			return 
		end

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
				if tonumber(value) then value = tonumber(value) end
				if value == 'true' then value = true end
				if value == 'false' then value = false end
				t[section][key] = value
			end
		end
		return t
	end
}


local loaded_config = ini.load(config_file)

if loaded_config then
	configlist = loaded_config
end


general_config = configlist.general
control_config = configlist.controls
drivstyle_config = configlist.drivingstyle


---------------------------------


function game_notification(message)
	GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT('DIA_ZOMBIE1', 0)
	while not GRAPHICS.HAS_STREAMED_TEXTURE_DICT_LOADED('DIA_ZOMBIE1') do
		wait()
	end
	if string.match(message, '?$') == nil then
		message = message..'.'
	end
	util.BEGIN_TEXT_COMMAND_THEFEED_POST(message)
	local tittle = 'WiriScript'
	local subtitle = '~c~Notification'
	HUD.END_TEXT_COMMAND_THEFEED_POST_MESSAGETEXT('DIA_ZOMBIE1', 'DIA_ZOMBIE1', true, 4, tittle, subtitle)
	HUD.END_TEXT_COMMAND_THEFEED_POST_TICKER(true, false)
end


function stand_notification(message)
	local list = {}
	for w in string.gmatch(message, '[^~]%w*[^~]') do table.insert(list, w) end
	local text = '[WiriScript] '..table.concat(list)
	if string.match(text, '?$') == nil then
		text = text..'.'
	end
	util.toast(text, TOAST_ABOVE_MAP)
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


------------------------------

features = {} --stores the features' names
menunames = {}


function menuname(section, name)
	features[ section ] = features[ section ] or {}
	features[ section ][ name ] = features[ section ][ name ] or ''
	
	if general_config.language ~= 'english' then
		menunames[ section ] = menunames[ section ] or {}
		if not menunames[ section ][ name ] and menunames[ section ][ name ] ~= '' then
			outdated_translation = true
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

---------------------------------


translation = {
	['save'] = function(file, t)
		local content = '{\n'
		local subtables = {}
		for k, s in pairs_by_keys(t) do
			local t = ('\t\"%s\":{\n'):format(k)
			local l = {}
			for key, v in pairs_by_keys(s) do
				table.insert(l, ('\t\t\"%s\":\"%s\"'):format(key, v))
			end
			t = t..table.concat(l, ',\n')..'\n\t}'
			table.insert(subtables, t)
		end
		content = content..table.concat(subtables, ',\n')..'\n}'
		file = io.open(file, 'w')
		file:write(content)
		file:close()
	end,

	['load'] = function(file)
		if not filesystem.exists(file) then 
			return false
		end
	
		local t = {}
		local section
	
		for line in io.lines(file) do 
			local s = line:match('\"(.+)\"%s?:%s?{')
			if s then
				section = s
				t[section] = t[section] or {}
			end
			local key, value = line:match('\"(.+)\"%s?:%s?\"(.*)\"')
			if key and value ~= nil then
				t[section][key] = value
			end
		end
		return t
	end
}


if general_config.language ~= 'english' then
	local file = scriptdir..'\\WiriScript\\Language\\'..general_config.language..'.json'
	
	if not filesystem.exists(file) then
		notification.red('Translation file not found')
	else
		local loaded = translation.load(file)
		menunames = loaded
	end
end


---------------------------------

async_http.init('pastebin.com', '/raw/EhH1C6Dh', function(output)
	cversion = tonumber(output)
	if cversion > version then	
        notification.red('WiriScript v'..output..' is available')
		menu.hyperlink(menu.my_root(), 'Get WiriScript v'..output, 'https://cutt.ly/get-wiriscript', '')
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


local weapons = 
{						--here you can modify which weapons are available to choose
	['Pistol'] = 'weapon_pistol', --['name shown in Stand'] =  'weapon ID'
	['Stun Gun'] = 'weapon_stungun',
	['Up-n-Atomizer'] =  'weapon_raypistol',
	['Special Carbine'] = 'weapon_specialcarbine',
	['Pump Shotgun'] = 'weapon_pumpshotgun',
	['Combat MG'] = 'weapon_combatmg',
	['Heavy Sniper'] = 'weapon_heavysniper',
	['Minigun'] = 'weapon_minigun',
	['RPG'] = 'weapon_rpg',
	['Railgun'] = 'weapon_railgun' --Stolen idea from Collins kek
}


local melee_weapons = 
{
	['Unarmed'] = 'weapon_unarmed', --['name shown in Stand'] = 'weapon ID'
	['Knife'] = 'weapon_knife',
	['Machete'] = 'weapon_machete',
	['Battle Axe'] = 'weapon_battleaxe',
	['Wrench'] = 'weapon_wrench',
	['Hammer'] = 'weapon_hammer',
	['Baseball Bat'] = 'weapon_bat'
}


local peds = 
{									--here you can modify which peds are available to choose
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


local imputs = 
{
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
		return 0
	end
end


function toggle_command(command, bool)
	local state
	if bool then state = ' on' else state = ' off' end
	menu.trigger_commands(command..state)
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
	pos.z = pos.z - 0.9
	if not owned then
		FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, type, 1.0, audible, invisible, 0, false)
	else
		FIRE.ADD_OWNED_EXPLOSION(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()), pos.x, pos.y, pos.z, type, 1.0, audible, invisible, 0, true)
	end
end


function CREATE_CAGE(pos, type)
	pos.z = pos.z - 0.9
	local object = {}
	local object_name = {'prop_gold_cont_01b', 'prop_rub_cage01a'}
	local hash = joaat(object_name[type])
	STREAMING.REQUEST_MODEL(hash)
	while not STREAMING.HAS_MODEL_LOADED(hash) do
		wait()
	end
	object[1] = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z, true, true, true) --why do you think I spawned the same object twice? lol --just one of these objects is useless
	if type == 2 then
		pos.z = pos.z + 2.2
	end
	object[2] = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z, true, true, true)
	for k, v in pairs(object) do
		if v == 0 then --if 'CREATE_OBJECT' fails to create one of the objects
			notification.red('Something went wrong creating cage')
			return
		end
		ENTITY.FREEZE_ENTITY_POSITION(v, true)
	end
	local rot  = ENTITY.GET_ENTITY_ROTATION(object[2])
	if type == 1 then
		rot.z = 180
	end
	if type == 2 then
		rot.x = -180
		rot.z = 90
	end
	ENTITY.SET_ENTITY_ROTATION(object[2], rot.x, rot.y, rot.z, 1, true)
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

--------------------------------------------------------------------------------------------------------


function SHOOT_OWNED_BULLET_FROM_CAM(pid, weaponID, damage) --shoots a player with an owned bullet spawned from cam coords
	local user_ped = PLAYER.PLAYER_PED_ID()
	local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
	local target = PED.GET_PED_BONE_COORDS(player_ped, 0xe0fd, 0.4, 0, 0)
	local cam_pos = CAM.GET_GAMEPLAY_CAM_COORD()
	local weapon_hash = joaat(weaponID)
	WEAPON.REQUEST_WEAPON_ASSET(weapon_hash, 31, 26)
	while not WEAPON.HAS_WEAPON_ASSET_LOADED(weapon_hash) do
		wait()
	end
	MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(cam_pos.x, cam_pos.y, cam_pos.z, target.x , target.y, target.z, damage, 0, weapon_hash, user_ped, true, false, -1.0)
end


function ADD_BLIP_FOR_ENTITY(entity, blipSprite, colour)
	local blip_ptr = alloc()
	local blip = HUD.ADD_BLIP_FOR_ENTITY(entity)
	memory.write_int(blip_ptr, blip)
	HUD.SET_BLIP_SPRITE(blip, blipSprite)
	HUD.SET_BLIP_COLOUR(blip, colour)
	HUD.SHOW_HEIGHT_ON_BLIP(blip, false)
	HUD.SET_BLIP_ROTATION(blip, SYSTEM.CEIL(ENTITY.GET_ENTITY_HEADING(entity)))
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
		HUD.REMOVE_BLIP(memory.read_int(blip_ptr))
		memory.free(blip_ptr)
	end)
	return blip
end


local function ADD_RELATIONSHIP_GROUP(name)
	local ptr = alloc(32)
	PED.ADD_RELATIONSHIP_GROUP(name, ptr)
	local relationship = memory.read_int(ptr); memory.free(ptr)
	return relationship
end


local set_relationship = 
{
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
		local netId = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(entity); NETWORK.SET_NETWORK_ID_CAN_MIGRATE(netId, true)
		NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
	end
	return NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity)
end


local function GET_NEARBY_PEDS(pid, radius) --returns a list of nearby peds from a given player Id
	local peds = {}
	local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
	local pos = ENTITY.GET_ENTITY_COORDS(player_ped)
	
	for k, ped in pairs(entities.get_all_peds_as_handles()) do
		if ped ~= player_ped then
			local ped_pos = ENTITY.GET_ENTITY_COORDS(ped)
			if vect.dist(pos, ped_pos) <= radius then table.insert(peds, ped) end
		end
	end
	return peds
end


local function GET_NEARBY_VEHICLES(pid, radius) --returns a list of nearby vehicles from given player Id
	local vehicles = {}
	local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
	local pos = ENTITY.GET_ENTITY_COORDS(player_ped)
	local player_veh = PED.GET_VEHICLE_PED_IS_IN(player_ped, false)

	for k, vehicle in pairs(entities.get_all_vehicles_as_handles()) do 
		local veh_pos = ENTITY.GET_ENTITY_COORDS(vehicle)
		if vehicle ~= player_veh and vect.dist(pos, veh_pos) <= radius then table.insert(vehicles, vehicle) end
	end
	return vehicles
end


local function GET_NEARBY_ENTITIES(pid, radius) --returns nearby peds and vehicles given player Id
	local peds = GET_NEARBY_PEDS(pid, radius)
	local vehicles = GET_NEARBY_VEHICLES(pid, radius)
	local entities = peds
	for i = 1, #vehicles do table.insert(entities, vehicles[i]) end
	return entities
end


function DELETE_ALL_VEHICLES_GIVEN_MODEL(model)
	local hash = joaat(model)
	if STREAMING.IS_MODEL_A_VEHICLE(hash) then
		for k, vehicle in pairs(entities.get_all_vehicles_as_handles()) do
			if ENTITY.GET_ENTITY_MODEL(vehicle) == hash then
				local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1)
				if not PED.IS_PED_A_PLAYER(driver) then
					entities.delete(driver)
					entities.delete(vehicle)
				end
			end
		end
	else
		error('model: '..model..' is not a vehicle')
	end
end


function DELETE_ALL_PEDS_GIVEN_MODEL(model)
	local hash = joaat(model)
	if STREAMING.IS_MODEL_A_PED(hash) then
		for k, ped in pairs(entities.get_all_peds_as_handles()) do
			if ENTITY.GET_ENTITY_MODEL(ped) == hash then
				if not PED.IS_PED_A_PLAYER(ped) then
					entities.delete(ped)
				end
			end
		end
	else
		error('model: '..model..' is not a ped')
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
	local t = {}
	for k, v in pairs(table) do
		t[#t + 1] = v
	end
	return #t
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
	local adjusted_rotation = 
	{ 
		x = (math.pi / 180) * rotation.x, 
		y = (math.pi / 180) * rotation.y, 
		z = (math.pi / 180) * rotation.z 
	}
	local direction = 
	{
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
	local destination = 
	{ 
		x = cam_pos.x + direction.x * distance, 
		y = cam_pos.y + direction.y * distance, 
		z = cam_pos.z + direction.z * distance 
	}
	return destination
end


function draw_debug_text(text)
	text = tostring(text)
	directx.draw_text(0.05, 0.05, text, ALIGN_TOP_LEFT, 1.0, {['r'] = 1, ['g'] = 0, ['b'] = 0, ['a'] = 1}, false)
end


function RAYCAST_GAMEPLAY_CAM(distance, flag)
	local ptr1, ptr2, ptr3, ptr4 = alloc(), alloc(), alloc(), alloc()
	local cam_rot = CAM.GET_GAMEPLAY_CAM_ROT(0)
	local cam_pos = CAM.GET_GAMEPLAY_CAM_COORD()
	local direction = ROTATION_TO_DIRECTION(cam_rot)
	local destination = 
	{ 
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
INSTRUCTIONAL.scaleform = GRAPHICS.REQUEST_SCALEFORM_MOVIE('instructional_buttons')

function INSTRUCTIONAL.DRAW(buttons, colour)
	if type(buttons) == 'string' then notification.normal(buttons) end

	if not equals(buttons, INSTRUCTIONAL.currentsettup) then
		local colour = colour or {
			['r'] = 0,
			['g'] = 0,
			['b'] = 0
		}

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
	util.create_tick_handler(function()
		return not GRAPHICS.HAS_STREAMED_TEXTURE_DICT_LOADED("helicopterhud")
	end)
	
	--GRAPHICS.SET_DRAW_ORIGIN(pos.x, pos.y, pos.z, 0)
	GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(pos.x, pos.y, pos.z, ptrx, ptry)
	local posx = memory.read_float(ptrx); memory.free(ptrx)
	local posy = memory.read_float(ptry); memory.free(ptry)
	GRAPHICS.DRAW_SPRITE("helicopterhud", "hud_outline", posx, posy, mult * 0.03 * 1.5, mult * 0.03 * 2.6, 90.0, color.r, color.g, color.b, 255, true)
end


--------------------------------------------INTRO----------------------------------------------------

if SCRIPT_MANUAL_START then
	AUDIO.PLAY_SOUND_FROM_ENTITY(-1, "clown_die_wrapper", PLAYER.PLAYER_PED_ID(), "BARRY_02_SOUNDSET", true, 20)

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

				AUDIO.PLAY_SOUND_FROM_ENTITY(-1, "Pre_Screen_Stinger", PLAYER.PLAYER_PED_ID(), "DLC_HEISTS_FINALE_SCREEN_SOUNDS", true, 20)
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

				AUDIO.PLAY_SOUND_FROM_ENTITY(-1, "SPAWN", PLAYER.PLAYER_PED_ID(), "BARRY_01_SOUNDSET", true, 20)
				state = 3
				stime = ctime()
			end

			if ctime() - stime >= 4000 and state == 3 then
				HIDE(scaleform)
				state = 4
				stime = ctime()
			end

			if ctime() - stime >= 3000 and state == 4 then break end

			GRAPHICS.DRAW_SCALEFORM_MOVIE_FULLSCREEN(scaleform, 255, 255, 255, 255, 0)
		end

		menu.action(script, 'Show Credits', {}, '', function()
			local state = 0
			local ctime = util.current_time_millis
			local stime = ctime()
			local i = 1
			local delay = 0
			local ty = {
				{'DeF3c'},
				{'Hollywood Collins'},
				{'Murten'},
				{'komt'},
				{'Ren'},
				{'MrPainKiller'},
				{'ICYPhoenix'},
				{'Koda'},
				{'jayphen'},
				{'Fwishky'},
				{'Polygon'},
				{'Sainan'},
				{'NONECKED'},
				{'wiriscript', 'HUD_COLOUR_TREVOR'}
			}
			local buttons = {
				{'Skip', 194}
			}
			menu.trigger_commands('screenshot on')
			AUDIO.SET_MOBILE_RADIO_ENABLED_DURING_GAMEPLAY(true)
			AUDIO.SET_MOBILE_PHONE_RADIO_STATE(true)
			AUDIO.SET_RADIO_TO_STATION_NAME("RADIO_01_CLASS_ROCK")
			AUDIO.SET_CUSTOM_RADIO_TRACK_LIST("RADIO_01_CLASS_ROCK", "END_CREDITS_SAVE_MICHAEL_TREVOR", true)
		
			while true do
				wait()
				local scaleform = GRAPHICS.REQUEST_SCALEFORM_MOVIE('OPENING_CREDITS')
				while not GRAPHICS.HAS_SCALEFORM_MOVIE_LOADED(scaleform) do
					wait()
				end
			
				if ctime() - stime >= delay and state == 0 then
					SETUP_SINGLE_LINE(scaleform)
				
					local strg
					if i < #ty then
						strg =  ty[i][1]..','
					else
						strg = ty[i][1]
					end
				
					ADD_TEXT_TO_SINGLE_LINE(scaleform, strg, '$font2', ty[i][2] or 'HUD_COLOUR_WHITE')
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
					menu.trigger_commands('screenshot off')
					AUDIO.START_AUDIO_SCENE("CAR_MOD_RADIO_MUTE_SCENE")
					wait(5000)
					AUDIO.SET_MOBILE_RADIO_ENABLED_DURING_GAMEPLAY(false)
					AUDIO.SET_MOBILE_PHONE_RADIO_STATE(false)
					AUDIO.CLEAR_CUSTOM_RADIO_TRACK_LIST("RADIO_01_CLASS_ROCK")
					AUDIO.SKIP_RADIO_FORWARD()
					AUDIO.STOP_AUDIO_SCENE("CAR_MOD_RADIO_MUTE_SCENE")
					break
				end

				if PAD.IS_CONTROL_JUST_PRESSED(2, 194)  then
					state = 2
					stime = ctime()
				elseif state ~= 2 then
					INSTRUCTIONAL.DRAW(buttons)
				end
			
				GRAPHICS.DRAW_SCALEFORM_MOVIE_FULLSCREEN(scaleform, 255, 255, 255, 255, 0)
			end
		end)
	end)
end

	
-----------------------------------------------------SETTINGS--------------------------------------------------


local settings = menu.list(menu.my_root(), menuname('Settings', 'Settings'), {'settings'}, '')

menu.divider(settings, menuname('Settings', 'Settings') )


menu.action(settings, menuname('Settings', 'Save Settings'), {}, '', function()
	ini.save(config_file, configlist)
	notification.normal('Configuration saved')
end)


---------------------------------
--LANGUAGE
---------------------------------

local language_settings = menu.list(settings, menuname('Settings', 'Language'))

menu.divider(language_settings, menuname('Settings', 'Language'))



menu.action(language_settings, 'Create New Translation', {}, 'Creates a file you can use to make a new WiriScript translation', function()
	translation.save(scriptdir..'\\WiriScript\\new translation.json', features)
	notification.normal('File: new translation.json, was created')
end)


if general_config.language ~=  'english' then
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
		translation.save(scriptdir..'\\WiriScript\\'..general_config.language..' (update).json', menunames)
		notification.normal('File: '..general_config.language..' (update).json, was created')
	end)
end


menu.divider(language_settings, '°°°')

if general_config.language ~= 'english' then
	menu.action(language_settings, 'English', {}, '', function()
		general_config.language = 'english'
		ini.save(config_file, configlist)
		notification.red('WiriScript needs to restart. Would you like to do it now?')
		local buttons = {
			{'Later', 194},
			{'Restart now', 191}
		}
		local colour = {
			['r'] = 255, 
			['g'] = 0,
			['b'] = 0
		}
		while true do
			wait()
			INSTRUCTIONAL.DRAW(buttons, colour)
			if PAD.IS_CONTROL_JUST_PRESSED(2, 191) then
				util.stop_script()
			end
			if PAD.IS_CONTROL_JUST_PRESSED(2, 194) then
				break
			end
		end
	end)
end

for k, path in pairs_by_keys(languages) do
	local filename, ext = string.match(path, '^.+\\(.+)%.(.+)$')
	if ext == 'json' and general_config.language ~= filename then
		menu.action(language_settings, filename:gsub("^%l", string.upper), {}, '', function()
			general_config.language = filename
			ini.save(config_file, configlist)
			notification.red('WiriScript needs to restart. Would you like to do it now?')
			local buttons = {
				{'Restart now', 191},
				{'Later', 194}
			}
			local colour = {
				['r'] = 255, 
				['g'] = 0,
				['b'] = 0
			}
			while true do
				wait()
				INSTRUCTIONAL.DRAW(buttons, colour)
				if PAD.IS_CONTROL_JUST_PRESSED(2, 191) then
					util.stop_script()
				end
				if PAD.IS_CONTROL_JUST_PRESSED(2, 194) then
					break
				end
			end
		end)
	end
end


---------------------------------

menu.toggle(settings, menuname('Settings', 'Display Info When Modding Health'), {'displayhealth'}, '', function(toggle)
	general_config.displayhealth = toggle
end, general_config.displayhealth)


menu.toggle(settings, menuname('Settings', 'Stand Notifications'), {'standnotifications'}, 'Turns to Stand\'s notification appearance', function(toggle)
	general_config.standnotifications = toggle
end, general_config.standnotifications)


---------------------------------
--CONTROLS
---------------------------------


local control_settings = menu.list(settings, menuname('Settings', 'Controls') , {}, '')

menu.divider(control_settings, menuname('Settings', 'Controls'))


local airstrike_plane_control = menu.list(control_settings, menuname('Settings - Controls', 'Airstrike Aircraft'), {}, '')
for name, imput in pairs(imputs) do
	local list = {}
	for w in string.gmatch(imput.control, '[^|]+') do table.insert(list, w) end
	local strg = "Keyboard: "..list[1]..", Controller: "..list[2]
	menu.action(airstrike_plane_control, strg, {}, "", function()
		control_config.airstrikeaircraft = imput.index
		util.show_corner_help(('~%s~'):format(name)..' to use Airstrike Aircraft')
	end)
end


local vehicle_weapons_control = menu.list(control_settings, menuname('Settings - Controls', 'Vehicle Weapons'), {}, '')
for name, imput in pairs(imputs) do
	local list = {}
	for w in string.gmatch(imput.control, '[^|]+') do table.insert(list, w) end
	local strg = "Keyboard: "..list[1]..", Controller: "..list[2]
	menu.action(vehicle_weapons_control, strg, {}, "", function()
		control_config.vehicleweapons = imput.index
		util.show_corner_help(('~%s~'):format(name)..' to use Vehicle Weapons')
	end)
end


local function check_loaded_controls()
	for option, index in pairs(configlist.controls) do
		for name, imput in pairs(imputs) do
			if index == imput.index then return	end
		end
		control_config[option] = 86	
	end
	ini.save(config_file, configlist)
	ini.load(config_file)
end
check_loaded_controls()


----------------------------------
--DRIVING STYLE
----------------------------------


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


local selected_flags = {}
local menu_driving_style = menu.list(settings, menuname('Settings', 'Driving Style'), {}, 'Changes the driving style of Banditos and Go-Karts')


menu.divider(menu_driving_style, menuname('Settings', 'Driving Style'))


menu.divider(menu_driving_style, menuname('Settings - Driving Style', 'Presets'))


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


local bandito_drive_style


for k, style in pairs(presets) do
	menu.action(menu_driving_style, style.name, {}, style.description, function()
		drivstyle_config.drivingstyle = style.int
		notification.normal('Driving style applied')
	end)
end


menu.divider(menu_driving_style, 'Custom')


for k, flag in pairs(driving_style_flag) do
	menu.toggle(menu_driving_style, k, {}, '', function(on) 
		local toggle = on
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
	drivstyle_config.drivingstyle = style
	notification.normal('Driving style applied')
end)

--------------------------------------------SPOOFING PROFILE STUFF------------------------------------------------

local usingprofile = false
local profiles_list = {}

local profiles_root = menu.list(menu.my_root(), menuname('Spoofing Profile', 'Spoofing Profile'), {'profiles'}, '')

function add_profile(t)
	local name = t.name
	local rid = t.rid
	local counter = 1
	local profile_actions = menu.list(profiles_root, name, {'profile'..name}, '')

	menu.divider(profile_actions, name)

	menu.action(profile_actions, menuname('Spoofing Profile - Profile', 'Enable Spoofing Profile'), {'enable'..name}, '', function()
		usingprofile = true 
		if spoofname then
			menu.trigger_commands('spoofedname '..name)
			menu.trigger_commands('spoofname on')
		end
		if spoofrid then
			menu.trigger_commands('spoofedrid '..rid)
			menu.trigger_commands('spoofrid hard')
		end
		notification.normal('Spoofing profile enabled. You\'ll need to change sessions for others to see the difference')
	end)

	delete = menu.action(profile_actions, menuname('Spoofing Profile - Profile', 'Delete'), {}, '', function()
		menu.show_warning(delete, CLICK_MENU, 'Are you sure you want to move this profile to Recycle Bin?', function()
			os.remove(scriptdir..'\\WiriScript\\Profiles\\'..name..'.json', 'w')
			for k, profile in pairs(profiles_list) do
				if profile == t then 
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
	profiles_data = io.open(scriptdir..'\\WiriScript\\Profiles\\'..profile.name..'.json', 'w')
	local str = '{\n\t"name": "'..profile.name..'"'..',\n\t"rid": "'..profile.rid..'"\n}'
	profiles_data:write(str)
	profiles_data:close()
	add_profile(profile)
	return true
end


menu.action(profiles_root, menuname('Spoofing Profile', 'Disable Spoofing Profile'), {'disableprofile'}, '', function()
	if usingprofile then 
		menu.trigger_commands('spoofname off')
		menu.trigger_commands('spoofrid off')
		notification.normal('Spoofing profile disabled. You will need to change sessions for others to see the change')
		usingprofile = false
	else
		notification.red('You are not using any spoofing profile')
	end
end)


if filesystem.exists(scriptdir..'\\WiriScript\\Profiles.data') then
	json = require('json')
	local profiles_data = (scriptdir..'\\WiriScript\\Profiles.data')
	for line in io.lines(profiles_data) do
		local profile = json.decode(line)	
		save_profile(profile)
		table.insert(profiles_list, profile)
	end
	os.remove(profiles_data)
	notification.red('Your spoofing profiles were migrated from the old .data file to individual .json files and json.lua is no longer required, you\'re free to delete it')
end

-----------------------------------
--ADD SPOOFING PROFILE
-----------------------------------

local newname
local newrid
local newprofile = menu.list(profiles_root, menuname('Spoofing Profile', 'Add Profile'), {'addprofile'}, 'Manually creates a new spoofing profile.')


menu.divider(newprofile, menuname('Spoofing Profile', 'Add Profile') )


menu.action(newprofile, menuname('Spoofing Profile - Add Profile', 'Name'), {'profilename'}, 'Type the profile\'s name.', function()
	if newname ~= nil then 
		menu.show_command_box('profilename '..newname)
	else
		menu.show_command_box('profilename ')
	end
end, function(name)
	newname = name
end)


menu.action(newprofile, menuname('Spoofing Profile - Add Profile', 'SCID'), {'profilerid'}, 'Type then profile\'s SCID.', function()
	if newrid ~= nil then 
		menu.show_command_box('profilerid '..newrid)
	else
		menu.show_command_box('profilerid ')
	end
end, function(rid)
	newrid = rid
end)


menu.action(newprofile, menuname('Spoofing Profile - Add Profile', 'Save Spoofing Profile'), {'saveprofile'}, '', function()
	if newname == nil or newrid == nil then
		notification.red('Name and SCID are required')
		return
	end
	local profile = {
		['name'] = newname,
		['rid'] = newrid
	}
	if save_profile(profile) then
		notification.normal('Spoofing profile created')
	else
		notification.red('Spoofing profile already exists')
	end
end)


----------------------------------------

recycle_bin = menu.list(profiles_root, menuname('Spoofing Profile', 'Recycle Bin'), {}, 'Temporary stores the deleted profiles. Profiles are permanetly erased when the script stops.')

--menu.divider(recycle_bin,  menuname('Spoofing Profile', 'Recycle Bin'))

menu.divider(profiles_root, menuname('Spoofing Profile', 'Spoofing Profile') )

function profilesload()
	for i, path in ipairs(filesystem.list_files(scriptdir..'\\WiriScript\\Profiles')) do
		local profile = {}
		for line in io.lines(path) do
			local key, value = string.match(line, '([^\t]+)%s?:%s?([^\n]+)')
			if key ~= nil and value ~= nil then
				key, value = string.match(key, '[^\"].+[^\",?]'), string.match(value, '[^\"].+[^\",?]')
				profile[key] = value
			end
		end
		table.insert(profiles_list, profile)
		add_profile(profile)
	end
end
profilesload()

-------------------------------------------------------------------------------------------------------------------------

GenerateFeatures = function(pid)
	menu.divider(menu.player_root(pid),'WiriScript')		
	
----------------------------------------------CREATE SPOOFING PROFILE----------------------------------------------------


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


--------------------------------------------EXPLOSION AND LOOP STUFF-----------------------------------------------------
	

	local trolling_list = menu.list(menu.player_root(pid), menuname('Player', 'Trolling & Griefing'), {}, '')		


	local explo_settings = menu.list(trolling_list, menuname('Trolling', 'Custom Explosion'), {}, '')
	menu.divider(explo_settings, menuname('Trolling', 'Custom Explosion'))

	menu.slider(explo_settings, menuname('Trolling - Custom Explosion', 'Explosion Type'), {'explosion'},'', 0, 72, 0, 1, function(value)
		type = value
	end)
	
	menu.toggle(explo_settings, menuname('Trolling - Custom Explosion', 'Invisible'), {}, '', function(on)
		invisible = on
	end)

	menu. toggle(explo_settings, menuname('Trolling - Custom Explosion', 'Audible'), {}, '', function(on)
		audible = on
	end, true)
	
	menu.toggle(explo_settings, menuname('Trolling - Custom Explosion', 'Owned Explosions'), {}, '', function(on)
		owned = on
	end)
	
	menu.action(explo_settings, menuname('Trolling - Custom Explosion', 'Explode'), {'customexplode'}, '', function()
		EXPLODE(pid, type, owned)
	end)

	menu.slider(explo_settings, menuname('Trolling - Custom Explosion', 'Loop Delay'), {'delay'}, '', 50, 1000, 300, 10, function(value) --changes the speed of loop
		delay = value
	end)
	
	menu.toggle(explo_settings, menuname('Trolling - Custom Explosion', 'Explosion Loop'), {'customloop'}, '', function(on)
		explosion_loop = on
		while explosion_loop do
			EXPLODE(pid, type, owned)
			wait(delay)
		end
	end)

	menu.toggle(trolling_list, menuname('Trolling', 'Water Loop'), {'waterloop'}, '', function(on)
		hydrant_loop = on
		while hydrant_loop do
			EXPLODE(pid, 13, false)
			wait()
		end
	end)


----------------------------------------
--KILL AS THE ORBITAL CANNON
----------------------------------------


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
		wait(600)
		CAM.SET_CAM_ROT(cam, -90, 0.0, 0.0, 2)
		CAM.SET_CAM_FOV(cam, 80)
		CAM.SET_CAM_COORD(cam, pos.x, pos.y, height)
		CAM.SET_CAM_ACTIVE(cam, true)
		CAM.RENDER_SCRIPT_CAMS(true, false, 3000, true, false, 0)
		STREAMING.SET_FOCUS_POS_AND_VEL(pos.x, pos.y, pos.z, 5.0, 0.0, 0.0)
		
		GRAPHICS.SET_SCRIPT_GFX_DRAW_ORDER(1)
		GRAPHICS.SET_DRAW_ORIGIN(pos.x, pos.y, pos.z, 0)
		GRAPHICS.ANIMPOSTFX_PLAY('MP_OrbitalCannon', 0, true)
		--wait(500)
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

				local effect = {
					['asset'] = 'scr_xm_orbital', 
					['name'] = 'scr_xm_orbital_blast'
				}
			
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

				AUDIO.PLAY_SOUND_FROM_COORD(
					-1, 
					'DLC_XM_Explosions_Orbital_Cannon', 
					pos.x,
					pos.y,
					pos.z, 
					0, 
					true, 
					0, 
					false
				)
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
		--wait(600)
		CAM.DO_SCREEN_FADE_IN(0)
		menu.trigger_commands('becomeorbitalcannon off')
	end)


	menu.toggle(trolling_list, menuname('Trolling', 'Flame Loop'), {'flameloop'}, '', function(on)
		fire_loop = on
		while fire_loop do
			EXPLODE(pid, 12, false)
			wait()
		end
	end, false)


-------------------------------------------------SHAKE CAM------------------------------------------------------------------


	menu.toggle(trolling_list, menuname('Trolling', 'Shake Camera'), {'shake'}, '', function(on)
		shakecam = on
		while shakecam do
			local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
			FIRE.ADD_OWNED_EXPLOSION(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()), pos.x, pos.y, pos.z, 0, 0, false, true, 80)
			wait(150)
		end
	end)


-------------------------------------------ATTACKER  OPTIONS--------------------------------------------------------


	local attacker_weapon, attacker_model
	local attacker_random_model, attacker_random_weapon = true, true
	local attacker_options = menu.list(trolling_list, menuname('Trolling', 'Attacker Options'), {}, '')

	
	menu.divider(attacker_options, menuname('Trolling', 'Attacker Options'))


	menu.click_slider(attacker_options, menuname('Trolling - Attacker Options', 'Spawn Attacker'), {'attacker'}, '', 1, 15, 1, 1, function(quantity)
		local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		for i = 1, quantity do
			local pos = ENTITY.GET_ENTITY_COORDS(player_ped)
			pos.x = pos.x + math.random(-3, 3)
			pos.y = pos.y + math.random(-3, 3)
			pos.z = pos.z - 0.9
			local weapon, model
			if attacker_random_weapon then weapon = random(weapons) else weapon = attacker_weapon end
			if attacker_random_model then model = random(peds) else model = attacker_model end
			local ped_hash, weapon_hash = joaat(model), joaat(weapon)
			STREAMING.REQUEST_MODEL(ped_hash)
			while not STREAMING.HAS_MODEL_LOADED(ped_hash) do
				wait()
			end
			local ped = entities.create_ped(0, ped_hash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z); insert_once(spawned_attackers, model)
			SET_ENT_FACE_ENT(ped, player_ped)
			WEAPON.GIVE_WEAPON_TO_PED(ped, weapon_hash, 9999, true, true)
			ENTITY.SET_ENTITY_INVINCIBLE(ped, godmode)
			PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
			TASK.TASK_COMBAT_PED(ped, player_ped, 0, 16)
			PED.SET_PED_AS_ENEMY(ped, true)
			if stationary then PED.SET_PED_COMBAT_MOVEMENT(ped, 0) end
			PED.SET_PED_COMBAT_ATTRIBUTES(ped, 46, 1)
			set_relationship.hostile(ped)
			STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(ped_hash)
			wait(100)
		end
	end)
	
	
	local ped_weapon_list = menu.list(attacker_options, menuname('Trolling - Attacker Options', 'Set Weapon')..': Random', {}, '')	
	
	
	menu.divider(ped_weapon_list, 'Attacker Weapon List')
	
	
	local ped_melee_list = menu.list(ped_weapon_list, 'Melee', {}, '')
	

	for k, weapon in pairs_by_keys(melee_weapons) do --creates the attacker melee weapon list
		menu.action(ped_melee_list, k, {}, '', function()
			attacker_random_weapon = false
			attacker_weapon = weapon
			menu.set_menu_name(ped_weapon_list, menuname('Trolling - Attacker Options', 'Set Weapon')..': '..k, {}, '')	
		end)
	end
	

	menu.action(ped_weapon_list, 'Random Weapon', {}, '', function()
		attacker_random_weapon = true
		menu.set_menu_name(ped_weapon_list, menuname('Trolling - Attacker Options', 'Set Weapon')..': Random', {}, '')	
	end)


	for k, weapon in pairs_by_keys(weapons) do --creates the attacker weapon list
		menu.action(ped_weapon_list, k, {}, '', function()
			attacker_random_weapon = false
			attacker_weapon = weapon
			menu.set_menu_name(ped_weapon_list, menuname('Trolling - Attacker Options', 'Set Weapon')..': '..k)
		end)
	end

	local ped_list = menu.list(attacker_options, menuname('Trolling - Attacker Options', 'Set Model')..': Random', {}, '')


	menu.divider(ped_list, 'Attacker Model List')
	
	
	menu.action(ped_list, 'Random Model', {}, '', function()
		attacker_random_model = true
		menu.set_menu_name(ped_list, menuname('Trolling - Attacker Options', 'Set Model')..': Random')
	end)


	for k, model in pairs_by_keys(peds) do --creates the attacker appearance list
		menu.action(ped_list, k, {}, '', function()
			attacker_random_model = false
			attacker_model = model
			menu.set_menu_name(ped_list, menuname('Trolling - Attacker Options', 'Set Model')..': '..k)
		end)
	end


	menu.click_slider(attacker_options, menuname('Trolling - Attacker Options', 'Clone Player (Enemy)'), {'enemyclone'}, '', 1, 15, 1, 1, function(quantity)
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
		pos.z = pos.z-0.9
		for i = 1, quantity do
			pos.x  = pos.x + math.random(-3, 3)
			pos.y = pos.y + math.random(-3, 3)
			local weapon
			if attacker_random_weapon then weapon = random(weapons) else weapon = attacker_weapon end
			local weapon_hash = joaat(weapon)
			local clone = PED.CLONE_PED(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid), 1, 1, 1); insert_once(spawned_attackers, 'mp_f_freemode_01'); insert_once(spawned_attackers, 'mp_m_freemode_01')
			WEAPON.GIVE_WEAPON_TO_PED(clone, weapon_hash, 9999, true, true)
			ENTITY.SET_ENTITY_COORDS(clone, pos.x, pos.y, pos.z)
			ENTITY.SET_ENTITY_INVINCIBLE(clone, godmode)
			PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(clone, true)
			TASK.TASK_COMBAT_PED(clone, PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid), 0, 16)
			PED.SET_PED_COMBAT_ATTRIBUTES(clone, 46, 1)
			set_relationship.hostile(clone)
			if stationary then	PED.SET_PED_COMBAT_MOVEMENT(clone, 0) end
			wait(100)
		end
	end)


	menu.toggle(attacker_options, menuname('Trolling - Attacker Options', 'Stationary'), {}, '', function(on)
		stationary = on
	end, false)


------------------------------------------------------
--ENEMY CHOP
------------------------------------------------------


	menu.action(attacker_options, menuname('Trolling - Attacker Options', 'Enemy Chop'), {'sendchop'}, '', function()
		local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(player_ped)
		pos.x  = pos.x + math.random(-3, 3)
		pos.y = pos.y + math.random(-3, 3)
		pos.z = pos.z - 0.9
		local ped_hash = joaat('a_c_chop')
		STREAMING.REQUEST_MODEL(ped_hash)
		while not STREAMING.HAS_MODEL_LOADED(ped_hash) do
			wait()
		end
		local ped = entities.create_ped(28, ped_hash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z); insert_once(spawned_attackers, 'a_c_chop')
		ENTITY.SET_ENTITY_INVINCIBLE(ped, godmode)
		PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
		TASK.TASK_COMBAT_PED(ped, player_ped, 0, 16)
		PED.SET_PED_COMBAT_ATTRIBUTES(ped, 46, 1)
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(ped_hash)
		set_relationship.hostile(ped)
	end)


-------------------------------------------------------
--SEND POLICE CAR
-------------------------------------------------------
	

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


	menu.toggle(attacker_options, menuname('Trolling - Attacker Options', 'Invincible Attackers'), {}, '', function(on_godmode)
		godmode = on_godmode
	end, false)


	menu.action(attacker_options, menuname('Trolling - Attacker Options', 'Delete Attackers'), {}, '', function()
		for k, model in pairs(spawned_attackers) do
			DELETE_ALL_PEDS_GIVEN_MODEL(model)
			spawned_attackers[k] = nil
		end
	end)

------------------------------------------CAGE OPTIONS----------------------------------------------------------------------
	

	local cage_options = menu.list(trolling_list, menuname('Trolling', 'Cage'), {}, '')
	
	
	menu.divider(cage_options, menuname('Trolling', 'Cage'))


	local function SIMPLE_CAGE(pid, version)
		local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(player_ped) 
		if PED.IS_PED_IN_ANY_VEHICLE(player_ped, false) then
			menu.trigger_commands('freeze'..PLAYER.GET_PLAYER_NAME(pid)..' on')
			wait(300)
			if PED.IS_PED_IN_ANY_VEHICLE(player_ped, false) then
				notification.red('Failed to kick player out of the vehicle')
				menu.trigger_commands('freeze'..PLAYER.GET_PLAYER_NAME(pid)..' off')
				return
			end
			menu.trigger_commands('freeze'..PLAYER.GET_PLAYER_NAME(pid)..' off')
			pos =  ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)) --if not it could place the cage at the wrong position
		end
		CREATE_CAGE(pos, version)
	end
	

	menu.action(cage_options, menuname('Trolling - Cage', 'Small'), {'smallcage'}, '', function()
		SIMPLE_CAGE(pid, 1)
	end) 
	

	menu.action(cage_options, menuname('Trolling - Cage', 'Tall'), {'tallcage'}, '', function()
		SIMPLE_CAGE(pid, 2)
	end)


---------------------------------------------------
--AUTOMATIC
---------------------------------------------------


	menu.toggle(cage_options, menuname('Trolling - Cage', 'Automatic'), {'autocage'}, '', function(on)
		cage_loop = on
		pos1 = ENTITY.GET_ENTITY_COORDS(player_ped) --first position
		local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		if cage_loop then
			if PED.IS_PED_IN_ANY_VEHICLE(player_ped, false) then
				menu.trigger_commands('freeze'..PLAYER.GET_PLAYER_NAME(pid)..' on')
				wait(300)
				if PED.IS_PED_IN_ANY_VEHICLE(player_ped, false) then
					notification.red('Failed to kick player out of the vehicle')
					menu.trigger_commands('freeze'..PLAYER.GET_PLAYER_NAME(pid)..' off')
					return
				end
				menu.trigger_commands('freeze'..PLAYER.GET_PLAYER_NAME(pid)..' off')
				pos1 =  ENTITY.GET_ENTITY_COORDS(player_ped)
			end
			CREATE_CAGE(pos1, 1)
		end

		while cage_loop do
			local pos2 = ENTITY.GET_ENTITY_COORDS(player_ped) --current position
			if vect.dist(pos1, pos2) >= 4 then
				pos1 = pos2
				if PED.IS_PED_IN_ANY_VEHICLE(player_ped, false) then
					goto continue
				end
				CREATE_CAGE(pos1, 1)
				notification.normal(PLAYER.GET_PLAYER_NAME(pid)..' '..'was out of the cage. Doing it again')
				::continue::
			end
			wait(1000)
		end
	end, false)


------------------------------------------------------
--FENCE
------------------------------------------------------


	menu.action(cage_options, menuname('Trolling - Cage', 'Fence'), {'fence'}, '', function()
		local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(player_ped)
		local object_hash = joaat('prop_fnclink_03e')
		pos.z = pos.z-0.9
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
		
		for key, value in pairs(object) do
			ENTITY.FREEZE_ENTITY_POSITION(value, true)
			if value == 0 then 
				notification.red('Something went wrong')
			end
		end
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(object_hash)
	end)


-------------------------------------------------------
--STUNT TUBE
-------------------------------------------------------


	menu.action(cage_options, menuname('Trolling - Cage', 'Stunt Tube'), {'stunttube'}, '', function()
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
		local hash = joaat('stt_prop_stunt_tube_s')
		STREAMING.REQUEST_MODEL(hash)

		while not STREAMING.HAS_MODEL_LOADED(hash) do		
			wait()
		end
		local cage_object = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z, true, true, false)

		local rot  = ENTITY.GET_ENTITY_ROTATION(cage_object)
		rot.y = 90
		ENTITY.SET_ENTITY_ROTATION(cage_object, rot.x,rot.y,rot.z,1,true)
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
	end)


------------------------------------------------GUITAR-----------------------------------------------------------------------


	menu.action(trolling_list, menuname('Trolling', 'Attach Guitar'), {'attachguitar'}, 'Attaches a guitar to their ped causing crazy things if they\'re in a vehicle and looks nice.', function()
		local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(player_ped)
		local object_hash = joaat('prop_acc_guitar_01_d1')
		STREAMING.REQUEST_MODEL(object_hash)
		while not STREAMING.HAS_MODEL_LOADED(object_hash) do
			wait()
		end
		local object = OBJECT.CREATE_OBJECT(object_hash, pos.x, pos.y, pos.z, true, true, true)
		if object == 0 then 
			notification.red('Something went wrong')
		end
		ENTITY.ATTACH_ENTITY_TO_ENTITY(object, PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid), PED.GET_PED_BONE_INDEX(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid), 0x5c01), 0.5, -0.2, 0.1, 0, 70, 0, false, true, true --[[Collision]], false, 0, true)
		--ENTITY.SET_ENTITY_VISIBLE(object, false, 0) --turns guitar invisible
		wait(3000)
		if player_ped ~= ENTITY.GET_ENTITY_ATTACHED_TO(object) then
			notification.red('The entity is not attached. Maybe '..PLAYER.GET_PLAYER_NAME(pid)..' has attactment protections')
			return
		end
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(object_hash)
	end)


----------------------------------------------------RAPE--------------------------------------------------------------------


	local rape_options = menu.list(trolling_list, menuname('Trolling', 'Rape'))
	
	
	menu.divider(rape_options, menuname('Trolling', 'Rape'))


	menu.action(rape_options, menuname('Trolling - Rape', 'Monkey'), {}, '', function()
		local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(player_ped)
		local ped_hash = joaat('a_c_chimp')
		STREAMING.REQUEST_MODEL(ped_hash)
		STREAMING.REQUEST_ANIM_DICT('rcmpaparazzo_2')
		wait(50)
		while not STREAMING.HAS_MODEL_LOADED(ped_hash) or not STREAMING.HAS_ANIM_DICT_LOADED('rcmpaparazzo_2') do
			wait()
		end
		local ped = entities.create_ped(1, ped_hash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
		PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
		TASK.TASK_PLAY_ANIM(ped, 'rcmpaparazzo_2', 'shag_loop_a', 8, 8, -1, 1, 0, 0, 0, 0)
		ENTITY.ATTACH_ENTITY_TO_ENTITY(ped, player_ped, PED.GET_PED_BONE_INDEX(ped, 0x0), 0, -0.3, 0.2, 0, 0, 0, false, true, false, false, 0, true)
		ENTITY.SET_ENTITY_INVINCIBLE(ped, true)
		ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(ped, false, false) --for ped not to be beaten with a melee weapon (because ped ditaches from player)
		wait(3000)
		if player_ped ~= ENTITY.GET_ENTITY_ATTACHED_TO(ped) then
			notification.red('The entity is not attached. Maybe '..PLAYER.GET_PLAYER_NAME(pid)..' has attactment protections')
			return
		end
		while player_ped == ENTITY.GET_ENTITY_ATTACHED_TO(ped) do
			if not ENTITY.IS_ENTITY_PLAYING_ANIM(ped, 'rcmpaparazzo_2', 'shag_loop_a',3) then
				TASK.TASK_PLAY_ANIM(ped, 'rcmpaparazzo_2', 'shag_loop_a', 8, 8, -1, 1, 0, 0, 0, 0)
			end
			wait()
		end
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(ped_hash)
	end)


	menu.toggle(rape_options, menuname('Trolling - Rape', 'By Me'), {'rape'}, '', function(on)
		rape = on
		if pid ~= players.user() then
			if rape then
				piggyback = false
				local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
				local pos = ENTITY.GET_ENTITY_COORDS(player_ped)
				STREAMING.REQUEST_ANIM_DICT('rcmpaparazzo_2')
				while not STREAMING.HAS_ANIM_DICT_LOADED('rcmpaparazzo_2') do
					wait()
				end
				local user_ped = PLAYER.PLAYER_PED_ID()
				TASK.TASK_PLAY_ANIM(user_ped, 'rcmpaparazzo_2', 'shag_loop_a', 8, -8, -1, 1, 0, false, false, false)
				local netID = NETWORK.PED_TO_NET(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()))
				NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(netID, true)
				ENTITY.ATTACH_ENTITY_TO_ENTITY(user_ped, player_ped, 0, 0, -0.3, 0, 0, 0, 0, false, true, true, false, 0, true)
				menu.trigger_commands('nocollision on')
			end
			while rape do 
				wait()
			end
			TASK.CLEAR_PED_TASKS_IMMEDIATELY(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()))
			ENTITY.DETACH_ENTITY(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()), true, false)
			menu.trigger_commands('nocollision off')
		end

		util.create_tick_handler(function()
			if not ENTITY.IS_ENTITY_ATTACHED(PLAYER.PLAYER_PED_ID()) then
				rape = false
				return false
			end
			return true
		end)
	end)


--------------------------------------------------ENEMY MINITANK----------------------------------------------------------------
	

local enemy_vehicles = menu.list(trolling_list, menuname('Trolling', 'Enemy Vehicles'), {}, '')
local minitank_godmode = false


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
		--TASK.TASK_VEHICLE_MISSION_PED_TARGET(driver, minitank, player_ped, 6, 100, 0, 2, 0, true)
		TASK.TASK_COMBAT_PED(driver, player_ped, 0, 0)
		PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(driver, true)
		ENTITY.SET_ENTITY_VISIBLE(driver, false, 0)
		
		
		util.create_thread(function()
			while ENTITY.GET_ENTITY_HEALTH(minitank) > 0 do
				if PLAYER.IS_PLAYER_DEAD(pid) then
					while PLAYER.IS_PLAYER_DEAD(pid) do
						wait()
					end
					local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
					PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(driver, false)
					--TASK.TASK_VEHICLE_MISSION_PED_TARGET(driver, minitank, player_ped, 6, 100, 786988, 2, 0, true)
					TASK.TASK_COMBAT_PED(driver, player_ped, 0, 0)
				end
				wait()
			end
		end)
		
		wait(150)
	end
	STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(ped_hash)
	STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(minitank_hash)
end)


menu.toggle(enemy_vehicles, menuname('Trolling - Enemy Vehicles', 'Invincible'), {}, '', function(on)
	minitank_godmode = on
end, false)

-----------------------------------
--MINITANK WEAPON
-----------------------------------

local menu_minitank_weapon = menu.list(enemy_vehicles, menuname('Trolling - Enemy Vehicles', 'Minitank Weapon')..': Random', {}, '')


menu.divider(menu_minitank_weapon, 'RC Tank Weapon')


menu.action(menu_minitank_weapon, 'Random Weapon', {}, '', function()
	random_minitank_weapon = true
	menu.set_menu_name(menu_minitank_weapon, menuname('Trolling - Enemy Vehicles', 'Minitank Weapon')..': Random')
end)


for k, weapon in pairs_by_keys(modIndex) do
	menu.action(menu_minitank_weapon, k, {}, '', function()
		minitank_weapon = weapon
		random_minitank_weapon = false
		menu.set_menu_name(menu_minitank_weapon, menuname('Trolling - Enemy Vehicles', 'Minitank Weapon')..': '..k)
	end)
end


menu.action(enemy_vehicles, menuname('Trolling - Enemy Vehicles', 'Delete Minitank(s)'), {}, '', function()
	DELETE_ALL_VEHICLES_GIVEN_MODEL('minitank')
end)

--------------------------------------------------ENEMY BUZZARD------------------------------------------------------------------

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
				while ENTITY.GET_ENTITY_HEALTH(pilot) > 0 do
					local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
					local a, b = ENTITY.GET_ENTITY_COORDS(player_ped), ENTITY.GET_ENTITY_COORDS(heli)
					if MISC.GET_DISTANCE_BETWEEN_COORDS(a.x, a.y, a.z, b.x, b.y, b.z, true) > 90 then
						param0 = 0
					else
						param0 = 1
					end
					param1 = give_task_to_pilot(param0, param1)
					wait()
				end
			end)
			STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(heli_hash)
			STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(ped_hash)
			wait(100)
		end
	end)

	
	menu.toggle(enemy_vehicles, menuname('Trolling - Enemy Vehicles', 'Invincible'), {}, '', function(on)
		buzzard_godmode = on
	end, false)
	

	local menu_gunner_weapon_list = menu.list(enemy_vehicles, menuname('Trolling - Enemy Vehicles', 'Gunners Weapon')..': Combat MG')
	
	
	menu.divider(menu_gunner_weapon_list, 'Gunners Weapon List')


	for k, weapon in pairs_by_keys(gunner_weapon_list) do
		menu.action(menu_gunner_weapon_list, k, {}, '', function()
			gunner_weapon = weapon
			menu.set_menu_name(menu_gunner_weapon_list, 'Gunner\'s Weapon: '..k)
		end)
	end


	menu.toggle(enemy_vehicles, menuname('Trolling - Enemy Vehicles', 'Visible'), {}, 'You shouldn\'t be that toxic to turn this off.', function(on)
		buzzard_visible = on
	end, true)
	
	
	--[[menu.action(enemy_vehicles, 'Delete Buzzards', {}, '', function()
		DELETE_ALL_VEHICLES_GIVEN_MODEL('buzzard2'); DELETE_ALL_PEDS_GIVEN_MODEL('s_m_y_blackops_01')
	end)]]

------------------------------------------------------------DAMAGE-------------------------------------------------------------------

	local damage = menu.list(trolling_list, menuname('Trolling', 'Damage'), {}, 'Choose the weapon and shoot \'em no matter where you are.')
	

	menu.toggle(damage, menuname('Trolling - Damage', 'Spectate'), {}, 'If player is not visible or far enough, you\'ll need to spectate before using Damage. This is just Stand\'s option duplicated.', function(on)
		spectate = on
		if spectate then
			menu.trigger_commands('spectate '..PLAYER.GET_PLAYER_NAME(pid)..' on')
		else
			menu.trigger_commands('spectate '..PLAYER.GET_PLAYER_NAME(pid)..' off')
		end
	end)


	menu.divider(damage, 'Damage')
	

	local owned_bullet = true
	local damage_value = 200 --default damage value
	
	menu.action(damage, menuname('Trolling - Damage', 'Heavy Sniper'), {}, '', function()
		SHOOT_OWNED_BULLET_FROM_CAM(pid, 'weapon_heavysniper', damage_value)
	end)


	menu.action(damage, menuname('Trolling - Damage', 'Shotgun'), {}, '', function()
		SHOOT_OWNED_BULLET_FROM_CAM(pid, 'weapon_pumpshotgun', damage_value)
	end)


	menu.slider(damage, menuname('Trolling - Damage', 'Damage Level'), {'damagevalue'}, 'The bullet demages player with the given value.', 10, 1000, 200, 50, function(value)
		damage_value = value
	end)


	menu.toggle(damage, menuname('Trolling - Damage', 'Tase'), {}, '', function(on)
		tase = on
		while tase do 
			SHOOT_OWNED_BULLET_FROM_CAM(pid, 'weapon_stungun', 1)
			wait(2500)
		end
	end)


-----------------------------------------------------HOSTILE PEDS------------------------------------------------------------------


	menu.action(trolling_list, menuname('Trolling', 'Hostile Peds'), {'hostilepeds'}, 'All on foot peds will combat player.', function()
		local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(player_ped)
		
		for k, ped in pairs(GET_NEARBY_PEDS(pid, 90)) do
			
			if not PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
				local tick = 0
				
				while not REQUEST_CONTROL(ped) and tick <= 10 do
					REQUEST_CONTROL(ped)
					tick = tick + 1
					wait()
				end
				
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


--------------------------------------------------HOSTILE TRAFFIC-----------------------------------------------------------------


	menu.action(trolling_list, menuname('Trolling', 'Hostile Traffic'), {'hostiletraffic'}, '', function()
		local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos  = ENTITY.GET_ENTITY_COORDS(player_ped)
		local vehicles = {}
		
		for k, vehicle in pairs(GET_NEARBY_VEHICLES(pid, 250)) do	
			if not VEHICLE.IS_VEHICLE_SEAT_FREE(vehicle, -1) then
				local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1)
				if not PED.IS_PED_A_PLAYER(driver) then 
					local tick = 0
					while not REQUEST_CONTROL(driver) and tick <= 10 do
						REQUEST_CONTROL(driver)
						tick = tick + 1
						wait()
					end

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


-----------------------------------------------TROLLY BANDITO------------------------------------------------------------------

	local bandito = {
		['spawned'] = {}
	}

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
		TASK.TASK_VEHICLE_MISSION_PED_TARGET(driver, vehicle, player_ped, 6, 500.0, drivstyle_config.drivingstyle, 0.0, 0.0, true)
		SET_PED_CAN_BE_KNOCKED_OFF_VEH(driver, 1)
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(pedHash); STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(vehicleHash)
		return vehicle, driver
	end
	

	local bandito_godmode = false


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


	menu.toggle(trolly_vehicles, menuname('Trolling - Trolly Vehicles', 'Invincible'), {}, '', function(on)
		bandito_godmode = on
	end, false)


	menu.action(trolly_vehicles, menuname('Trolling - Trolly Vehicles', 'Send Explosive Bandito'), {'explobandito'}, '', function()
		local bandito_hash = joaat('rcbandito')
		local ped_hash = joaat('mp_m_freemode_01')
		STREAMING.REQUEST_MODEL(bandito_hash); STREAMING.REQUEST_MODEL(ped_hash)
		while not STREAMING.HAS_MODEL_LOADED(bandito_hash) and not STREAMING.HAS_MODEL_LOADED(ped_hash) do
			wait()
		end
		if not explosive_bandito_sent then
			explosive_bandito_sent = true
			local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
			local bandito = spawn_trolly_vehicle(pid, bandito_hash, ped_hash)
			VEHICLE.SET_VEHICLE_MOD(bandito, 5, 3, false); VEHICLE.SET_VEHICLE_MOD(bandito, 48, 5, false)
			VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(bandito, 128, 0, 128); VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(bandito, 128, 0, 128)
			ADD_BLIP_FOR_ENTITY(bandito, 646, 27)
			VEHICLE.ADD_VEHICLE_PHONE_EXPLOSIVE_DEVICE(bandito)
			util.create_thread(function()
				while ENTITY.GET_ENTITY_HEALTH(bandito) > 0 do
					local a, b = ENTITY.GET_ENTITY_COORDS(player_ped), ENTITY.GET_ENTITY_COORDS(bandito)
					if MISC.GET_DISTANCE_BETWEEN_COORDS(a.x, a.y, a.z, b.x, b.y, b.z, false) < 3 then
						VEHICLE.DETONATE_VEHICLE_PHONE_EXPLOSIVE_DEVICE() --NEW
					end
					wait()
				end
				explosive_bandito_sent = false
			end)
		else
			notification.red('Explosive bandito already sent')
		end
	end)


	menu.action(trolly_vehicles, menuname('Trolling - Trolly Vehicles', 'Delete Bandito(s)'), {}, '', function()
		DELETE_ALL_VEHICLES_GIVEN_MODEL('rcbandito')
	end)
	
------------------------------------
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


	--[[menu.action(trolly_vehicles, menuname.delete..' Go-Karts', {}, '', function()
		DELETE_ALL_VEHICLES_GIVEN_MODEL('veto2')
	end)]]

---------------------------------------------------HOSTILE JET---------------------------------------------------------------


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
					jet = entities.create_vehicle(jet_hash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
					tick = tick + 1
					wait()
				end
				entities.delete(pilot)
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


	menu.toggle(enemy_vehicles, menuname('Trolling - Enemy Vehicles', 'Invincible'), {}, '', function(on)
		jet_godmode = on
	end, jet_godmode)


	--[[menu.action(enemy_vehicles, 'Delete Lazers', {}, '', function()
		DELETE_ALL_VEHICLES_GIVEN_MODEL('lazer')
	end)]]


--------------------------------------------------------RAM PLAYER--------------------------------------------------------------


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


----------------------------------------------------------PIGGY BACK-------------------------------------------------------------
	

	menu.toggle(trolling_list, menuname('Trolling', 'Piggy Back'), {'piggyback'}, '', function(on)
		piggyback = on
		local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local user_ped = PLAYER.PLAYER_PED_ID()
		local tick = 0
		if pid ~= players.user() then
			if piggyback then
				rape = false
				STREAMING.REQUEST_ANIM_DICT('rcmjosh2')
				while not STREAMING.HAS_ANIM_DICT_LOADED('rcmjosh2') do
					wait()
				end
				ENTITY.ATTACH_ENTITY_TO_ENTITY(user_ped, player_ped, PED.GET_PED_BONE_INDEX(player_ped, 0xDD1C), 0, -0.2, 0.65, 0, 0, 180, false, true, true, false, 0, true)
				TASK.TASK_PLAY_ANIM(user_ped, 'rcmjosh2', 'josh_sitting_loop', 8, -8, -1, 1, 0, false, false, false)
				menu.trigger_commands('nocollision on')
			else
				TASK.CLEAR_PED_TASKS_IMMEDIATELY(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()))
				ENTITY.DETACH_ENTITY(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()), true, false)
				menu.trigger_commands('nocollision off')
				while user_ped == ENTITY.GET_ENTITY_ATTACHED_TO(player_ped) and tick <= 15 do
					ENTITY.DETACH_ENTITY(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()), true, false)
					tick = tick + 1
					wait()
				end
			end
		end

		util.create_tick_handler(function()
			if not ENTITY.IS_ENTITY_ATTACHED(PLAYER.PLAYER_PED_ID()) then
				piggyback = false
				return false
			end
			return true
		end)
	end)


--------------------------------------------------------------ALIEN EGG------------------------------------------------------------------


	menu.action(trolling_list, menuname('Trolling', 'Attach Alien Egg'), {'alienegg'}, '', function()
		local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(player_ped)
		local object_hash = joaat('prop_alien_egg_01')
		STREAMING.REQUEST_MODEL(object_hash)
		while not STREAMING.HAS_MODEL_LOADED(object_hash) do
			wait()
		end
		local object = OBJECT.CREATE_OBJECT(object_hash, pos.x, pos.y, pos.z, true, true, true)
		ENTITY.ATTACH_ENTITY_TO_ENTITY(object, player_ped, PED.GET_PED_BONE_INDEX(player_ped, 0x0), 0, 0, 0, 0, 0, 0, false, true, false, false, 0, true)
	end)


--------------------------------------------------------------RAIN ROCKETS----------------------------------------------------------------


	local function rain_rockets(pid, owned)
		local user_ped = PLAYER.PLAYER_PED_ID()
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
		local owner
		pos.x = pos.x + math.random(-6,6)
		pos.y = pos.y + math.random(-6,6)
		local ground_ptr = alloc(32); MISC.GET_GROUND_Z_FOR_3D_COORD(pos.x, pos.y, pos.z, ground_ptr, false, false); pos.z = memory.read_float(ground_ptr); memory.free(ground_ptr)
		if owned then owner = user_ped else owner = 0 end
		MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z+50, pos.x, pos.y, pos.z, 200, true, joaat('weapon_airstrike_rocket'), owner, true, false, -1.0)
	end


	menu.toggle(trolling_list, menuname('Trolling', 'Rain Rockets (owned)'), {'ownedrockets'}, '', function(on)
		rainRockets = on
		while rainRockets do
			rain_rockets(pid, true)
			wait(500)
		end
	end)


	menu.toggle(trolling_list, menuname('Trolling', 'Rain Rockets'), {'rockets'}, '', function(on)
		rainRockets = on
		while rainRockets do
			rain_rockets(pid, false)
			wait(500)
		end
	end)

------------------------------------------------------------------------------------------------------------------------------------------


-------------------------------------
--FORCEFIELD FOR OTHERS
-------------------------------------


	menu.toggle(trolling_list, menuname('Trolling', 'Forcefield'), {'forcefield'}, 'Push nearby entities away from player.', function(on)
		forcefield = on
		
		while forcefield do
			wait()
			local pos1 = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
			local entities = GET_NEARBY_ENTITIES(pid, 10)
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
		end
	end)


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
		
		STREAMING.REQUEST_MODEL(hash)
		while not STREAMING.HAS_MODEL_LOADED(hash) do
			wait()
		end
		
		local plane = entities.create_vehicle(hash, coord, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
		SET_ENT_FACE_ENT_3D(plane, player_ped)
		ENTITY.SET_ENTITY_LOAD_COLLISION_FLAG(plane, true)
		VEHICLE.SET_VEHICLE_FORWARD_SPEED(plane, 150)
		VEHICLE.CONTROL_LANDING_GEAR(plane, 3)
	end)


-------------------------------------
--KAMIKASE
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

		STREAMING.REQUEST_MODEL(hash)
		while not STREAMING.HAS_MODEL_LOADED(hash) do
			wait()
		end
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
		
		util.create_tick_handler(function()
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
				--AUDIO.PLAY_SOUND_FROM_COORD(-1, "clown_die_wrapper", pos.x, pos.y, pos.z, "BARRY_02_SOUNDSET", false, 0, false)
			elseif vect.dist(ppos, dest) > 3 then
				dest = ppos
				TASK.TASK_GO_TO_COORD_ANY_MEANS(ped, ppos.x, ppos.y, ppos.z, 5.0, 0, 0, 0, 0)
			end
			return true
		end)
		
	end)
	
	
-----------------------------------------------------------FRIENDLY OPTIONS---------------------------------------------------------------


	local friendly_list = menu.list(menu.player_root(pid), menuname('Player', 'Friendly Options'), {}, '')
	menu.divider(friendly_list, menuname('Player', 'Friendly Options'))


-------------------------------------
--KILL KILLERS
-------------------------------------


	menu.toggle(friendly_list, menuname('Friendly Options', 'Kill Killers'), {'explokillers'}, 'Explodes the player\'s murderer.', function(on)
		kill_killers = on
		while kill_killers do
			local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
			local killer = PED.GET_PED_SOURCE_OF_DEATH(player_ped)
			if killer ~= 0 and killer ~= player_ped then
				local pos = ENTITY.GET_ENTITY_COORDS(killer)
				FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, 1, 99999, true, false, 1)
				wait(500)
				while PLAYER.IS_PLAYER_DEAD(players.user()) do
					wait()
				end
			end
			wait()
		end
	end)
	
--END OF GENERATEFEATURES
end

local defaulthealth = ENTITY.GET_ENTITY_MAX_HEALTH(PLAYER.PLAYER_PED_ID())
local modhealth
local modded_health = defaulthealth
--display health stuff
local screen_w, screen_h = directx.get_client_size() --from BoperSkript
function _x(yes)
	return yes / screen_w
end
function _y(yes)
	return yes / screen_h
end

-------------------------------------------------SELF--------------------------------------------------------------------


local self_options = menu.list(menu.my_root(), menuname('Self', 'Self'), {'selfoptions'}, '')

-------------------------------------
--HEALTH OPTIONS
-------------------------------------

menu.toggle(self_options, menuname('Self', 'Mod Health'), {'modhealth'}, 'Changes your ped\'s max health. Some menus will tag you as modder. It returns to default max health when it\'s disabled.', function(on)
	modhealth  = on
	if modhealth then
		local user_ped = PLAYER.PLAYER_PED_ID()
		PED.SET_PED_MAX_HEALTH(user_ped,  modded_health)
		ENTITY.SET_ENTITY_HEALTH(user_ped, modded_health)
	else
		local user_ped = PLAYER.PLAYER_PED_ID()
		PED.SET_PED_MAX_HEALTH(user_ped, defaulthealth)
		menu.trigger_commands('moddedhealth '..defaulthealth) -- just if you want the slider to go to default value when mod health is off
		if ENTITY.GET_ENTITY_HEALTH(user_ped) > defaulthealth then 
			ENTITY.SET_ENTITY_HEALTH(user_ped, defaulthealth)
		end
	end
	
	util.create_thread(function()
		while modhealth do
			local user_ped = PLAYER.PLAYER_PED_ID()
			if PED.GET_PED_MAX_HEALTH(user_ped) ~= modded_health  then
				PED.SET_PED_MAX_HEALTH(user_ped, modded_health)
				ENTITY.SET_ENTITY_HEALTH(user_ped, modded_health)	
			end
			wait()
		end
	end)

	while modhealth do
		local user_ped = PLAYER.PLAYER_PED_ID()
		--thanks to boper skript
		if general_config.displayhealth then
			local logo = directx.create_texture(scriptdir..'\\resources\\wiriscript_logo.png')
			local text = 'WiriScript | Player Health: '..ENTITY.GET_ENTITY_HEALTH(user_ped)..'/'..PED.GET_PED_MAX_HEALTH(user_ped)
			local wmtxt_x, wmtxt_y = directx.get_text_size(text, 0.75)
			local wmposx,wmposy = _x(80),_y(25) + wmtxt_y*0.4 --change the text position here
			
			directx.draw_rect(wmposx-wmposx * 0.6, wmposy - wmtxt_y * 0.3, wmtxt_x+wmtxt_x * 0.13, wmtxt_y + wmtxt_y * 0.5, {['r'] = 0.0,['g'] = 0.0,['b'] = 0.0,['a'] = 0.7})
			directx.draw_texture(
				logo,	 			-- id
				0.015,				-- sizeX
				0.015,				-- sizeY
				0.0,				-- centerX
				0.5,				-- centerY
				wmposx-wmposx*0.65,	-- posX
				wmposy+wmposy*0.35,	-- posY
				0,					-- rotation
				{					-- colour
					['r'] = 1.0,
					['g'] = 1.0,
					['b'] = 1.0,
					['a'] = 1.0
				}
			)
			directx.draw_text(wmposx, wmposy, text, ALIGN_TOP_LEFT, 0.7,  {['r'] = 1.0,['g'] = 1.0,['b'] = 1.0,['a'] = 1.0}, true)
		end
		wait()
	end
end)


menu.slider(self_options, menuname('Self', 'Modded Health'), {'moddedhealth'}, 'Health will be modded with the given value.', 100, 9000,defaulthealth,50, function(value)
	modded_health = value
end)


menu.action(self_options, menuname('Self', 'Max Health'), {'maxhealth'}, '', function()
	local user_ped = PLAYER.PLAYER_PED_ID()
	ENTITY.SET_ENTITY_HEALTH(user_ped, PED.GET_PED_MAX_HEALTH(user_ped))
end)


menu.action(self_options, menuname('Self', 'Max Armour'), {'maxarmour'}, '', function()
	local user_ped = PLAYER.PLAYER_PED_ID()
	PED.SET_PED_ARMOUR(user_ped, 50)
end)


menu.toggle(self_options, menuname('Self', 'Refill Health When in Cover'), {'healincover'}, '', function(on)
	refillincover = on
	while refillincover do
		local user_ped = PLAYER.PLAYER_PED_ID()
		if PED.IS_PED_IN_COVER(user_ped) then
			PLAYER._SET_PLAYER_HEALTH_RECHARGE_LIMIT(players.user(), 1)
			PLAYER.SET_PLAYER_HEALTH_RECHARGE_MULTIPLIER(players.user(), 15)
		else
			PLAYER._SET_PLAYER_HEALTH_RECHARGE_LIMIT(players.user(),0.5)
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
	write_global.int(2441237 + 4013, 1)
end)


-------------------------------------
--FORCEFIELD
-------------------------------------

menu.toggle(self_options, menuname('Self', 'Forcefield'), {'forcefield'}, 'Push nearby entities away.', function(on)
	forcefield = on
	
	while forcefield do
		wait()
		local pos1 = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()))
		local entities = GET_NEARBY_ENTITIES(players.user(), 10)
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
	end	
end)


-------------------------------------
--FORCE
-------------------------------------

local forceCommandIds = {}
local object
menu.toggle(self_options, menuname('Self', 'Force'), {'jedimode'}, 'Use Force in nearby vehicles.', function(on)
	force = on	
	if force then
		util.show_corner_help('~INPUT_VEH_FLY_SELECT_TARGET_RIGHT~ ~INPUT_VEH_FLY_ROLL_RIGHT_ONLY~ to use Force.')
		local user_ped = PLAYER.PLAYER_PED_ID()
		local pos = ENTITY.GET_ENTITY_COORDS(user_ped)
		util.create_thread(function()
			local effect = 
			{
				['asset'] = 'scr_ie_tw',
				['name'] = 'scr_impexp_tw_take_zone'
			}
			local colour =
			{
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
		wait()
	end
end)

-------------------------------------
--CARPET RIDE
-------------------------------------


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
		TASK.CLEAR_PED_TASKS_IMMEDIATELY(PLAYER.PLAYER_PED_ID())
		object = OBJECT.CREATE_OBJECT(object_hash, pos.x, pos.y, pos.z, true, true, true)
		ENTITY.ATTACH_ENTITY_TO_ENTITY(user_ped, object, 0, 0, -0.2, 1.0, 0, 0, 0, false, true, false, false, 0, true)
		ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(object, false, false)

		TASK.TASK_PLAY_ANIM(user_ped, 'rcmcollect_paperleadinout@', 'meditiate_idle', 8, -8, -1, 1, 0, false, false, false)
		util.show_corner_help('~INPUT_MOVE_UP_ONLY~ ~INPUT_MOVE_DOWN_ONLY~ ~INPUT_VEH_JUMP~ ~INPUT_DUCK~ to use Carpet Ride.\nPress ~INPUT_VEH_MOVE_UP_ONLY~ to move faster.')
		
		local height = ENTITY.GET_ENTITY_COORDS(object, false).z
		
		while carpetride do
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
			wait()
		end
	else
		TASK.CLEAR_PED_TASKS_IMMEDIATELY(user_ped)
		ENTITY.DETACH_ENTITY(user_ped, true, false)
		ENTITY.SET_ENTITY_VISIBLE(object, false)
		entities.delete(object)
	end
end)

-------------------------------------
--KILL KILLERS
-------------------------------------


menu.toggle(self_options, menuname('Self', 'Kill Killers'), {'explokillers'}, 'Explodes your murderer.', function(on)
	kill_killers = on
	while kill_killers do
		local user_ped = PLAYER.PLAYER_PED_ID()
		local killer = PED.GET_PED_SOURCE_OF_DEATH(user_ped)
		if killer ~= 0 and killer ~= user_ped then
			local pos = ENTITY.GET_ENTITY_COORDS(killer)
			FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, 1, 99999, true, false, 1)
			wait(500)
			while PLAYER.IS_PLAYER_DEAD(players.user()) do
				wait()
			end
		end
		wait()
	end
end)

-------------------------------------
--UNDEAD OFFRADAR
-------------------------------------


menu.toggle(self_options, menuname('Self', 'Undead Offradar'), {'undeadoffradar'}, '', function(on)
	undead = on
	local user_ped = PLAYER.PLAYER_PED_ID()
	local defaulthealth = ENTITY.GET_ENTITY_MAX_HEALTH(user_ped)
	if undead then
		ENTITY.SET_ENTITY_MAX_HEALTH(user_ped, 0)
	end
	while undead do
		if ENTITY.GET_ENTITY_MAX_HEALTH(user_ped) ~= 0 then
			ENTITY.SET_ENTITY_MAX_HEALTH(user_ped, 0)
		end
		wait()
	end
	ENTITY.SET_ENTITY_MAX_HEALTH(user_ped, defaulthealth)
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


menu.toggle(trails_options, menuname('Self - Trails', 'Toggle Trails'), {'toggletrails'}, '', function(on)
	trails = on
	
	local effect = 
	{
		['asset'] = 'scr_rcpaparazzo1',
		['name'] = 'scr_mich4_firework_sparkle_spawn',
	}
	local effects = {}
	STREAMING.REQUEST_NAMED_PTFX_ASSET(effect.asset)
	while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(effect.asset) do
		wait()
	end
	
	util.create_tick_handler(function()	
		local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
		
		if vehicle == 0 then
			for k, boneId in pairs(bones) do
				GRAPHICS.USE_PARTICLE_FX_ASSET(effect.asset)
				local fx = GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY_BONE(
					effect.name, 
					PLAYER.PLAYER_PED_ID(), 
					0, 
					0, 
					0, 
					0, 
					0, 
					0, 
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
			local minimum_ptr = alloc()
			local maximum_ptr = alloc()
			MISC.GET_MODEL_DIMENSIONS(ENTITY.GET_ENTITY_MODEL(vehicle), minimum_ptr, maximum_ptr)
			local minimum = memory.read_vector3(minimum_ptr); memory.free(minimum_ptr)
			local maximum = memory.read_vector3(maximum_ptr); memory.free(maximum_ptr)
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
		draw_debug_text(#effects)
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


menu.rainbow(
	menu.colour(trails_options, menuname('Self - Trails', 'Colour'), {'trailcolour'}, '', {['r'] = 255/255, ['g'] = 0, ['b'] = 255/255, ['a'] = 1.0}, false, function(colour)
		trails_colour = colour
	end)
)

-------------------------------------
--COMBUSTION MAN
-------------------------------------

menu.toggle(self_options, menuname('Self', 'Combustion Man'), {'combustionman'}, 'Shoot explosive ammo without aiming a weapon. If you think Oppressor MK2 is annoying, you haven\'t use it with this.', function(toggle)
	shootlazer = toggle
	local disable = {'disablevehmousecontroloverride', 'disablevehflymousecontroloverride', 'disablevehsubmousecontroloverride'}

	for i = 1, #disable do toggle_command(disable[i], shootlazer) end

	if shootlazer then
		util.show_corner_help('Press ~INPUT_ATTACK~ to shoot using Combustion Man.')
	end

	while shootlazer do
		wait()
		local user_ped = PLAYER.PLAYER_PED_ID()
		local pos1 = ENTITY.GET_ENTITY_COORDS(user_ped)
		local pos2 = GET_OFFSET_FROM_CAM(80)
		local weaponHash = joaat('VEHICLE_WEAPON_PLAYER_LAZER')
		HUD.DISPLAY_SNIPER_SCOPE_THIS_FRAME()
		if not WEAPON.HAS_WEAPON_ASSET_LOADED(weaponHash) then
			WEAPON.REQUEST_WEAPON_ASSET(weaponHash, 31, 26)
			while not WEAPON.HAS_WEAPON_ASSET_LOADED(weaponHash) do
				wait()
			end
		end
		if PAD.IS_CONTROL_PRESSED(2, 24) then
			MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(
				pos1.x, pos1.y, pos1.z, 
				pos2.x, pos2.y, pos2.z, 
				200, 
				true, 
				weaponHash, 
				user_ped, 
				true, false, -1.0
			)
		end
	end
end)

---------------------------------------------------WEAPON-------------------------------------------------------

local weapon_options = menu.list(menu.my_root(), menuname('Weapon', 'Weapon'), {'weaponoptions'}, '')


menu.divider(weapon_options, menuname('Weapon', 'Weapon'))

-------------------------------------
--VEHICLE PAINT GUN
-------------------------------------


menu.toggle(weapon_options, menuname('Weapon', 'Vehicle Paint Gun'), {'paintgun'}, 'Applies a random colour combination to the damaged vehicle.', function(on)
	paintgun = on
	while paintgun do
		if PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) then
			local entity_ptr = alloc(32); PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(PLAYER.PLAYER_ID(), entity_ptr)
			local entity = memory.read_int(entity_ptr); memory.free(entity_ptr)
			if entity == 0 then return end
			if ENTITY.IS_ENTITY_A_PED(entity) then
				entity = PED.GET_VEHICLE_PED_IS_IN(entity, false)
			end
			if ENTITY.IS_ENTITY_A_VEHICLE(entity) then
				REQUEST_CONTROL(entity)
				VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(entity, math.random(0,255), math.random(0,255), math.random(0,255))
				VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(entity, math.random(0,255), math.random(0,255), math.random(0,255))
			end
		end
		wait()
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
		['rot'] = 
		{
			x = 0, 			--xRot
			y = 0, 			--yRot
			z = 180			--zRot
		} 		
	},
	['Clown Muz'] = 
	{
		['asset'] = 'scr_rcbarry2',
		['name'] = 'muz_clown',
		['scale'] = 0.8,
		['rot'] = 
		{
			x = 0,
			y = 0, 
			z = 0		
		}
	}
}

local shooting_effect = effects_list['Clown Flowers']

local toggle_shooting_effect = menu.toggle(weapon_options, menuname('Weapon', 'Shooting Effect')..': Clown Flowers', {'shootingeffect'}, 'Effects while shooting.', function(on)
	cartoon = on
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
		menu.trigger_commands('shootingeffect on')
		menu.trigger_commands('weaponoptions')
	end)
end

-------------------------------------------------
--MAGNET GUN
-------------------------------------------------

local magnetgun_root = menu.list(weapon_options, menuname('Weapon', 'Magnet Gun'), {'magnetgun'})

menu.divider(magnetgun_root, menuname('Weapon', 'Magnet Gun'))

menu.toggle(magnetgun_root, menuname('Magnet Gun', 'Chaos Mode'), {'chaosmagnetgun'}, '', function(toggle)
	force_magnetgun = toggle
	if force_magnetgun and velocity_magnetgun then
		menu.trigger_commands('smoothmagnetgun off')
	end
end)

menu.toggle(magnetgun_root, menuname('Magnet Gun', 'Smooth Magnet Gun'), {'smoothmagnetgun'}, '', function(toggle)
	velocity_magnetgun = toggle
	if velocity_magnetgun and force_magnetgun then
		menu.trigger_commands('chaosmagnetgun off')
	end
end)

-- draws the sphere in the magnet gun's blackhole
-- sets the color in rainbow mode 

local colour = {
	['r'] = 255,
	['g'] = 0,
	['b'] = 255
}
local state = 0
util.create_tick_handler(function()
	if not force_magnetgun and not velocity_magnetgun then
		return true
	end
	if state == 0 then
		if colour.g < 255 then
			colour.g = colour.g + 1
		else
			state = 1
		end
	end

	if state == 1 then
		if colour.r > 0 then
			colour.r = colour.r - 1
		else
			state = 2
		end
	end

	if state == 2 then
		if colour.b < 255 then
			colour.b = colour.b + 1
		else
			state = 3
		end
	end

	if state == 3 then
		if colour.g > 0 then
			colour.g = colour.g - 1
		else
			state = 4
		end
	end

	if state == 4 then
		if colour.r < 255 then
			colour.r = colour.r + 1
		else
			state = 5
		end
	end

	if state == 5 then
		if colour.b > 0 then
			colour.b = colour.b - 1
		else
			state = 0
		end
	end

	if PLAYER.IS_PLAYER_FREE_AIMING(players.user()) then
		local offset = GET_OFFSET_FROM_CAM(30)
		GRAPHICS._DRAW_SPHERE(offset.x, offset.y, offset.z, 0.5, colour.r, colour.g, colour.b, 0.5)
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

menu.toggle(weapon_options, menuname('Weapon', 'Airstrike Gun'), {}, '', function(toggle)
	strikegun = toggle
	local weapon = joaat('weapon_airstrike_rocket')
	while strikegun do
		local hit, coords, normal_surface, entity = RAYCAST_GAMEPLAY_CAM(1000.0)
		if hit == 1 then
			if PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) then
				MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(coords.x, coords.y, coords.z + 35, coords.x, coords.y, coords.z, 200, true, weapon, PLAYER.PLAYER_PED_ID(), true, false, -1.0)
			end
		end
		wait()
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
	['Granade'] 		= {['hash'] = 0x93E220BD},
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


function GET_CURRENT_WEAPON_AMMO_TYPE() --returns 4 if OBJECT (Rocket, granade, etc.), and 2 if INSTANT HIT
	local offsets = {
		0x08,
		0x10D8,
		0x20,
		0x54
	}
	local addr = address_from_pointer_chain(worldPtr, offsets)
	if addr ~= 0 then
		return memory.read_byte(addr), addr
	else
		error('Current ammo type not found')
	end
end


function GET_CURRENT_WEAPON_AMMO_PTR()
	local offsets = {
		0x08,
		0x10D8,
		0x20,
		0x60
	}
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
				MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos1.x, pos1.y, pos1.z, pos2.x, pos2.y, pos2.z, 200, true, bullet, user_ped, true, false, -1.0)
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
		menu.trigger_commands('bulletchanger on')
		menu.trigger_commands('weaponoptions')
		from_memory = false
	end)
end


for k, data in pairs_by_keys(ammo_ptrs) do
	--local command = 'bulletchanger'..string.lower(k)
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
		menu.trigger_commands('bulletchanger on')
		menu.trigger_commands('weaponoptions')
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
	['r'] = 128/255,
	['g'] = 0.0,
	['b'] = 128/255
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
				local rotation = GET_ROTATION_FROM_DIRECTION(normal_surface)
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
					rotation.pitch - 90, 
					rotation.roll, 
					rotation.yaw, 
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
		menu.trigger_commands('impacteffect on')
		menu.trigger_commands('ptfxgun')
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


local vehicle_gun_list =
{
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
		{'Increase offset', 241},
		{'Decrease offset', 242}
	}
	
	while vehiclegun do
		wait()
		local hash = joaat(vehicle_for_gun)
		local hit, coords, nsurface, entity = RAYCAST_GAMEPLAY_CAM(memory.read_float(offset) + 5, 1)
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

		if hit ~= 1 then coords = GET_OFFSET_FROM_CAM(memory.read_float(offset)) end
		
		STREAMING.REQUEST_MODEL(hash)
		while not STREAMING.HAS_MODEL_LOADED(hash) do
			wait()
		end
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)

		if PLAYER.IS_PLAYER_FREE_AIMING(players.user()) then
			local rot = CAM.GET_GAMEPLAY_CAM_ROT(0)
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

			INSTRUCTIONAL.DRAW(buttons)
		elseif ENTITY.DOES_ENTITY_EXIST(preview) then
			entities.delete(preview)
		end
	end
end)


local set_vehicle = menu.list(vehicle_gun, menuname('Weapon - Vehicle Gun', 'Set Vehicle'))


for k, vehicle in pairs_by_keys(vehicle_gun_list) do
	menu.action(set_vehicle, k, {}, '', function()
		vehicle_for_gun = vehicle_gun_list[k]
		menu.set_menu_name(toggle_vehicle_gun, 'Vehicle Gun: '..k)
		menu.trigger_commands('togglevehiclegun on')
		menu.trigger_commands('vehiclegun')
	end)
end


menu.text_input(vehicle_gun, menuname('Weapon - Vehicle Gun', 'Custom Vehicle'), {'customvehgun'}, '', function(vehicle)
	local modelHash = joaat(vehicle)
	local name = HUD._GET_LABEL_TEXT(VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(modelHash))
	if STREAMING.IS_MODEL_A_VEHICLE(modelHash) then
		vehicle_for_gun = vehicle
		menu.set_menu_name(toggle_vehicle_gun, 'Vehicle Gun: '..name)
	else
		return notification.red('The model is not a vehicle')
	end
	menu.trigger_commands('togglevehiclegun on')
end, '')


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
--INSTANT LOCK-ON
-------------------------------------

--[[
menu.toggle(weapon_options, menuname('Weapon', 'Instant Lock-On'), {'instalockon'}, 'Decreases the time needed to lock something with Homing Launcher', function(toggle)
	instalockon = toggle
	local default = {}
	local offsets = {
		0x08,
		0x10D8,
		0x20,
		0x60,
		0x178
	}
	
	while instalockon do
		local ptr = alloc()
		WEAPON.GET_CURRENT_PED_WEAPON(PLAYER.PLAYER_PED_ID(), ptr, true)
		if memory.read_int(ptr) == 0x63AB0442 then
			local addr = address_from_pointer_chain(worldPtr, offsets)
			local value = memory.read_float(addr)
			if value ~= 0.0 then
				default.addr = addr
				default.value = value
				memory.write_float(addr, 0.0)
			end
		end
		memory.free(ptr)
		wait()
	end
	if getn(default) > 0 then memory.write_float(default.addr, default.value) end
end)
]]

-------------------------------------
--BULLET SPEED MULT
-------------------------------------


local default_speed = {}
local speed_mult = 1

function SET_AMMO_SPEED_MULT(mult)
	local offsets =
	{
		0x08,
		0x10D8,
		0x20,
		0x60,
		0x58
	}
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


menu.click_slider(weapon_options, menuname('Weapon', 'Bullet Speed Mult'), {'ammospeedmult'},  'Allows you to change the speed of non-instant hit bullets (rockets, fireworks, granades, etc.)', 100, 2500, 100, 50, function(mult)
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

	while magnetent do
		wait()
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
				
				util.create_thread(function()
					while magnetent do
						wait()
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
					end
				end)
				entities = {}
			end
		end
	end
end)

---------------------------------------------------VEHICLE-------------------------------------------------------


local vehicle_options = menu.list(menu.my_root(), menuname('Vehicle', 'Vehicle'), {}, '') -- change

menu.divider(vehicle_options, menuname('Vehicle', 'Vehicle'))

------------------------------------------------
--AIRSTRIKE AIRCRAFT
------------------------------------------------

local vehicle_weapon = menu.list(vehicle_options, menuname('Vehicle', 'Vehicle Weapons'), {'vehicleweapons'}, 'Allows you to add weapons to any vehicle.')

menu.divider(vehicle_weapon, menuname('Vehicle', 'Vehicle Weapons'))


menu.toggle(vehicle_options, menuname('Vehicle', 'Airstrike Aircraft'), {'airstrikeplanes'}, 'Use any plane or helicopter to make airstrikes.', function(on)
	airstrike_plane = on
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
							MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z - 3, pos.x, pos.y, ground, 200, true, joaat("weapon_airstrike_rocket"), PLAYER.PLAYER_PED_ID(), true, false, -1.0)
						end
					end
				end)
			end
		end
	end
end)

---------------------------------------------------
--VEHICLE WEAPONS' STUFF
---------------------------------------------------

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
	local speed	= ENTITY.GET_ENTITY_SPEED(vehicle) 

	local startcoords = 
	{
		fl = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, minimum.x, maximum.y + speed * 0.25, 0.3), 	--FRONT & LEFT
		fr = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, maximum.x, maximum.y + speed * 0.25, 0.3), 	--FRONT & RIGHT
		bl = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, minimum.x, minimum.y, 0.3), 			--BACK & LEFT
		br = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, maximum.x, minimum.y, 0.3) 				--BACK & RIGHT
	}	
	local endcoords = 
	{
		fl = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, minimum.x, maximum.y + 50, 0.3),
		fr = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, maximum.x, maximum.y + 50, 0.3),
		bl = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, minimum.x, minimum.y - 50, 0.3),
		br = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, maximum.x, minimum.y - 50, 0.3)
	}

	for k, v in pairs(startcoords, endcoords) do
		if k == startpoint then
			coord1 = startcoords[k]
			coord2 = endcoords[k]
		end
	end
	MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(coord1.x, coord1.y, coord1.z, coord2.x, coord2.y, coord2.z, 200, true, weaponHash, user_ped, true, false, -1.0)
	memory.free(minimum_ptr)
	memory.free(maximum_ptr)
end

---------------------------------------------------
--VEHICLE LASER
---------------------------------------------------


menu.toggle(vehicle_weapon, menuname('Vehicle - Vehicle Weapons', 'Vehicle Lasers'), {'vehiclelasers'},'', function(on)
	vehicle_laser = on
	if vehicle_laser then
		menu.trigger_commands('airstrikeplanes off')
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


---------------------------------------------------
--VEHICLE WEAPONS
---------------------------------------------------


local selected_veh_weapon = 'VEHICLE_WEAPON_ROGUE_MISSILE'

local toggle_veh_weapons = menu.toggle(vehicle_weapon, menuname('Vehicle - Vehicle Weapons', 'Vehicle Weapons')..': Rogue Missile', {'togglevehweapons'}, '', function(on)
	veh_rockets = on
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
	['Rockets'] = 'weapon_rpg',
	['Up-n-Atomizer'] = 'weapon_raypistol',
	['Firework'] = 'weapon_firework',
	--['Khanjali Cannon'] = 'VEHICLE_WEAPON_KHANJALI_CANNON_HEAVY',
	['Rogue Missile'] = 'VEHICLE_WEAPON_ROGUE_MISSILE',
	--['Plane Rocket'] ='VEHICLE_WEAPON_PLANE_ROCKET',
	['Tank Cannon'] = 'VEHICLE_WEAPON_TANK',
	['Lazer MG'] = 'VEHICLE_WEAPON_PLAYER_LAZER',
}


local vehicle_weapon_list = menu.list(vehicle_weapon, menuname('Vehicle - Vehicle Weapons', 'Set Vehicle Weapon'))


for k, weapon in pairs_by_keys(veh_weapons_list) do
	menu.action(vehicle_weapon_list, k, {k}, '', function()
		selected_veh_weapon = weapon
		menu.set_menu_name(toggle_veh_weapons, menuname('Vehicle - Vehicle Weapons', 'Set Vehicle Weapon')..': '..k)
		menu.trigger_commands('togglevehweapons on')
		menu.trigger_commands('vehicleweapon')
	end)
end

-------------------------------------
--VEHICLE EDITOR
-------------------------------------


local handling_offsets = {
	['normal'] = 
	{
		['Mass'] = 0xC,
		['Percent Submerged'] = 0x40,
		['Acceleration'] = 0x4C,
		['Initial Drive Force'] = 0x60,
		['Break Force'] = 0x6C,
		['Hand Brake Force'] = 0x7C,
		['Suspencion Force'] = 0xBC,
		['Deformation Damage Mult'] = 0xF8,
		['Suspension Height'] = 0xD0,
		['Collision Damage Mult'] = 0xF0,
		['Weapon Damage Mult'] = 0xF4,
		['Engine Damage Mult'] = 0xFC,
		['Traction Curve [Maximum]'] = 0x88,
		['Traction Curve [Minimum]'] = 0x90
	},
	['advanced'] = 
	{
		['Submerged Ratio'] = 0x44, 
		['Drive Bias - Front'] = 0x48,
		['Drive Inertia'] = 0x54,
		['Clutch Change Rate Scale [Up Shift]'] = 0x58,
		['Clutch Change Rate Scale [Down Shift]'] = 0x5C,
		['Drive Max Flat Vel'] = 0x64,
		['Initial Drive Max Flat Vel'] = 0x68,
		['Brake Bias - Front'] = 0x74,
		['Brake Bias - Rear']= 0x78,
		['Steering Lock']  = 0x80,
		['Steering Lock Ratio'] = 0x84,
		['Traction Curve Max Ratio'] = 0x8C,
		['Traction Curve Min Ratio'] = 0x94, 
		['Traction Curve Lateral'] = 0x98,
		['Traction Curve Lateral Ratio'] = 0x9C,
		['Traction Spring Delta Max '] = 0xA0,
		['Traction Spring Delta Max Ratio'] = 0xA4,
		['Low Speed Traction Loss Mult'] = 0xA8,
		['Camber Stiffness'] = 0xAC,
		['Traction Bias Front'] = 0xB0,
		['Traction Bias Rear'] = 0xB4,
		['Traction Loss Mult'] = 0xB8,
		['Suspension Comp Damp'] = 0xC0,
		['Suspension Rebound Damb'] = 0xC4, 
		['Suspension Upper Limit'] = 0xC8,
		['Susppension Lower Limit'] = 0xCC,
		['Suspension Bias Front'] = 0xD4,
		['Suspension Bias Rear'] = 0xD8,
		['Anti Roll Bar Foce'] = 0xDC,
		['Anti Roll Bar Bias Front'] = 0xE0,
		['Anti Roll Bar Bias Rear'] = 0xE4,
		['Roll Centre Height Front'] = 0xE8,
		['Roll Centre Height Rear'] = 0xEC,
		['Petrol Tank Volume'] = 0x100,
		['Oil Volume'] = 0x104,
		['Initial Drag Coeff'] = 0x10,
		['Down Force Modifier'] = 0x14,
		['Increase Speed'] = 0x120
	}
}

local veh_edit_Ids = {}	
local lastVehicle
local vehicleName
local veh_display = {}
local veh_last_focused, veh_focused
local window1_x, window1_y = 0.02, 0.08
local on_focus_colour = 
{
	['r'] = 168	/ 255, 
	['g'] = 84 	/ 255, 
	['b'] = 244 / 255, 
	['a'] = 1.0
}
local weapon_focused, weapon_last_focused
local cursor_mode = false

local vehicle_editor = menu.list(vehicle_options, menuname('Vehicle', 'Handling Editor'), {}, '', function()
	display_handling = true
end, function()
	display_handling = false
	if cursor_mode then 
		UI.toggle_cursor_mode(false)
		cursor_mode = false 
	end
end)


function save_handling()
	if PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), true) == 0 then return notification.red('Current Vehicle not found') end

	local handling_file = (scriptdir..'\\WiriScript\\Handling\\'..vehicleName..'.txt')
	handling_data = io.open(handling_file, 'w')
	handling_data:write('<'..string.upper(vehicleName)..'>\n\n')
	handling_data:write('<normal>\n')
	
	for k, offset in pairs_by_keys(handling_offsets.normal) do 
		local value  = memory.read_float(address_from_pointer_chain(worldPtr, {0x08, 0xD30, 0x938, offset}))
		handling_data:write('\t'..k..' = '..value..'\n')	
	end
		
	handling_data:write('\n<advanced>\n')
		
	for k, offset in pairs_by_keys(handling_offsets.advanced) do
		local value  = memory.read_float(address_from_pointer_chain(worldPtr, {0x08, 0xD30, 0x938, offset}))
		handling_data:write('\t'..k..' = '..value..'\n')	
	end

	handling_data:close()
	
	notification.normal(vehicleName..': '..'Handling data saved')
end

function load_handling()
	if PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), true) == 0 then return notification.red('Current Vehicle not found') end

	local handling_file = (scriptdir..'\\WiriScript\\handling\\'..vehicleName..'.txt')
	
	if not filesystem.exists(handling_file) then 
		return notification.red('File not found')
	end
	
	for line in io.lines(handling_file) do
		local name, value = string.match(line, '([^\t]-)%s?=%s?([^\n]+)')
		if name ~= nil and value ~= nil then
			value = tonumber(value)
			for _, table in pairs(handling_offsets) do
				for key, offset in pairs(table) do
					if key == name then 
						local addr = address_from_pointer_chain(worldPtr, {0x08, 0xD30, 0x938, offset})
						if memory.read_float(addr) ~= value then
							memory.write_float(addr, value)
						end
					end
				end
			end
		end
	end

	notification.normal(vehicleName..': handling data loaded')
end

menu.divider(vehicle_editor, 'Normal')

if PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), true) ~= 0 then
	vehicleName = HUD._GET_LABEL_TEXT(
		VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(
			ENTITY.GET_ENTITY_MODEL(
				PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), true)
			)
		)
	)
else
	vehicleName = '???'
end


function create_options(tId, t)
	for k, offset in pairs_by_keys(t) do
		local list = {}
			
		for w in string.gmatch(k, '%w+') do
			table.insert(list, w)
		end
			
		local command = string.lower(table.concat(list))
		local addr
	
		veh_edit_Ids[k] = menu.action(tId, k, {command}, '', function()
			addr = address_from_pointer_chain(worldPtr, {0x08, 0xD30, 0x938, offset})
			menu.show_command_box(command..' ')
		end, function(newvalue)
			if tonumber(newvalue) == nil then
				notification.red('Invalid input. Number expected')
				return
			end
			memory.write_float(addr, newvalue)
		end)
	end
end
	
create_options(vehicle_editor, handling_offsets.normal)

menu.divider(vehicle_editor, 'Advanced')

create_options(vehicle_editor, handling_offsets.advanced)

for k, commandId in pairs(veh_edit_Ids) do
	menu.on_tick_in_viewport(commandId, function()
		insert_once(veh_display, k)
		if #veh_display > 10 then 
			table.remove(veh_display, 1)
		end
	end)
	menu.on_focus(commandId, function()
		if k ~= veh_last_focused  then 
			veh_focused = k
			veh_last_focused = veh_focused
		end
	end)
end

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
	menuname('Vehicle - Vehicle Doors', 'Trunk'),
}

menu.divider(doors_list, menuname('Vehicle', 'Vehicle Doors'))

for k, door in pairs_by_keys(doors, function(a, b) return a < b end) do
	menu.toggle(doors_list, door, {}, '', function(on)
		local vehicle = entities.get_user_vehicle_as_handle()
		if on then
			VEHICLE.SET_VEHICLE_DOOR_OPEN(vehicle, k-1, false, false)
		else
			VEHICLE.SET_VEHICLE_DOOR_SHUT(vehicle, k-1, false)
		end
	end)
end

menu.toggle(doors_list, menuname('Vehicle - Vehicle Doors', 'All'), {}, '', function(on)
	local vehicle = entities.get_user_vehicle_as_handle()
	for k, door in pairs(doors) do
		if on then
			VEHICLE.SET_VEHICLE_DOOR_OPEN(vehicle, k-1, false, false)
		else
			VEHICLE.SET_VEHICLE_DOOR_SHUT(vehicle, k-1, false)
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
local minoffset = -150
local maxoffset = -4.0
local offset = alloc(); memory.write_float(offset, -4.0)
local counting
local charge = alloc(); memory.write_float(charge, 1.0)
local countdown = 3
local camaddr

menu.toggle(vehicle_options, menuname('Vehicle', 'UFO'), {'ufo'}, 'Drive an UFO, use its tractor beam and cannon.', function(toggle)
	ufo_toggle = toggle

	local blackhole = false
	local cannon = false
	local attracted = {}
	local tick = 0
	local buttons = {
		{'Exit', 75},
		{'Release tractor beam', 22},
		{'Tractor beam', 73},
		{'Cannon', 80},
		{'Vertical flight', 119}
	}
	local cannonbuttons = {
		{'Exit', 75},
		{'Zoom', 241},
		{'Shoot', 24},
		{'Cannon', 80},
		{'Vertical flight', 119}
	}


	if ufo_toggle then
		menu.trigger_commands('disablevehexit on; becomeorbitalcannon on; disablevehcincam on; disablevehselectnextweapon on; disablevehradiowheel on')
		CAM.DO_SCREEN_FADE_OUT(500)
		wait(600)
		menu.trigger_commands('otr on')
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
		local addr = entities.handle_to_pointer(veh)
		addr = memory.read_long(addr + 0x20) + 0x38
		camaddr = addr
		memory.write_float(addr, -20.0)

		object = entities.create_object(objHash, pos)
		ENTITY.ATTACH_ENTITY_TO_ENTITY(object, veh, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, true, true, false, 0, true)
				
		cam = CAM.CREATE_CAM("DEFAULT_SCRIPTED_CAMERA", false)
		CAM.SET_CAM_ROT(cam, -90, 0.0, 0.0, 2)
		CAM.SET_CAM_FOV(cam, 80)
		CAM.ATTACH_CAM_TO_ENTITY(cam, veh, 0.0, 0.0, -4.0, true)
		CAM.SET_CAM_ACTIVE(cam, true)
		
		GRAPHICS.SET_SCRIPT_GFX_DRAW_ORDER(1)
		wait(500)
		CAM.DO_SCREEN_FADE_IN(0)

		util.create_tick_handler(function()
			VEHICLE.DISABLE_VEHICLE_WEAPON(true, -123497569, veh, PLAYER.PLAYER_PED_ID())
			VEHICLE.DISABLE_VEHICLE_WEAPON(true, -494786007, veh, PLAYER.PLAYER_PED_ID())

			local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(veh, 0.0, 0.0, -10.0)
			
			if not cannon then GRAPHICS._DRAW_SPHERE(pos.x, pos.y, pos.z, 1.0, 0, 255, 255, 5) end
			
			if PAD.IS_CONTROL_JUST_PRESSED(2, 73) then
				local ptr = alloc()
				MISC.GET_GROUND_Z_FOR_3D_COORD(pos.x, pos.y, pos.z, ptr, false)
				local groundz = memory.read_float(ptr); memory.free(ptr)
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
		-- color is red for strangers and cian for friends

		util.create_tick_handler(function()
			for _, pid in pairs(players.list(false)) do
				if ENTITY.IS_ENTITY_ON_SCREEN(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)) and not players.is_in_interior(pid) then
					local color = {
						['r'] = 0	, 
						['g'] = 255	, 
						['b'] = 255
					}
					for k, fid in pairs(players.list(false, true, false)) do
						if fid == pid then
							color = {
								['r'] = 128	, 
								['g'] = 255	, 
								['b'] = 0
							}
						end
					end
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
			cannon = not cannon
		end

		if cannon then
			CAM.RENDER_SCRIPT_CAMS(true, false, 3000, true, false, 0)
			local scaleform = GRAPHICS.REQUEST_SCALEFORM_MOVIE('ORBITAL_CANNON_CAM')
			while not GRAPHICS.HAS_SCALEFORM_MOVIE_LOADED(scaleform) do
				wait()
			end
			
			GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, 'SET_STATE')
			GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(3)
			GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

			GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, 'SET_CHARGING_LEVEL')
			GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(memory.read_float(charge))
			GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

			if PAD.IS_CONTROL_JUST_PRESSED(2, 241) then
				if zoom < 1.0 then 
					zoom = zoom + 0.25
					AUDIO.PLAY_SOUND_FRONTEND(-1, "zoom_out_loop", "dlc_xm_orbital_cannon_sounds", true)
				end
			end

			if PAD.IS_CONTROL_JUST_PRESSED(2, 242) then
				if zoom > 0.0 then 
					zoom = zoom - 0.25
					AUDIO.PLAY_SOUND_FRONTEND(-1, "zoom_out_loop", "dlc_xm_orbital_cannon_sounds", true)
				end
			end
			
			if zoom ~= lastzoom then
				GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, 'SET_ZOOM_LEVEL')
				GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(zoom)
				GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
				lastzoom = zoom
			end
			
			local foffset = maxoffset - zoom * (maxoffset - minoffset)

			incr(offset, foffset, 0.5)
			CAM.ATTACH_CAM_TO_ENTITY(cam, veh, 0.0, 0.0, memory.read_float(offset), true)

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
						GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, 'SET_COUNTDOWN')
						GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(countdown)
						GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
					else
						memory.write_float(charge, 0.0)
						countdown = 3
						counting = false

						local pos = CAM.GET_CAM_COORD(cam)
						local ptr1, ptr2 = alloc(), alloc()
						MISC.GET_GROUND_Z_AND_NORMAL_FOR_3D_COORD(pos.x, pos.y, pos.z, ptr1, ptr2)
						local ground, normal = memory.read_float(ptr1), memory.read_vector3(ptr2)
						local effect = {
							['asset'] = 'scr_xm_orbital',
							['name'] = 'scr_xm_orbital_blast'
						}
					
						STREAMING.REQUEST_NAMED_PTFX_ASSET(effect.asset)
						while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(effect.asset) do
							wait()
						end

						STREAMING.SET_FOCUS_POS_AND_VEL(pos.x, pos.y, ground, 5.0, 0.0, 0.0)
						FIRE.ADD_OWNED_EXPLOSION(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()), pos.x, pos.y, ground, 59, 1.0, true, false, 1.0)
						GRAPHICS.USE_PARTICLE_FX_ASSET(effect.asset)
						GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD(
							effect.name, 
							pos.x, pos.y, ground, 
							normal.x, normal.y, normal.z, 
							1.0, 
							false, false, false, true
						)

						AUDIO.PLAY_SOUND_FROM_COORD(
							-1, 
							'DLC_XM_Explosions_Orbital_Cannon', 
							pos.x, pos.y, ground, 
							0, 
							true, 
							0, 
							false
						)
						CAM.SHAKE_CAM(cam, "GAMEPLAY_EXPLOSION_SHAKE", 1.5)
						STREAMING.CLEAR_FOCUS()
					end

				else
					incr(charge, 1.0, 0.015)
					counting = false
				end
			
			else
				incr(charge, 1.0, 0.010)
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
	
	PATHFIND.GET_CLOSEST_VEHICLE_NODE(pos.x, pos.y, pos.z, ptr1, 1, 100, 2.5)
	pos = memory.read_vector3(ptr1)
	memory.write_float(camaddr, -1.57)
	entities.delete(veh)
	entities.delete(object)
	
	ENTITY.SET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), pos.x, pos.y, pos.z, false, false, false)
	ENTITY.SET_ENTITY_VISIBLE(PLAYER.PLAYER_PED_ID(), true, 0)
	CAM.SET_CAM_ACTIVE(cam, false)
	CAM.RENDER_SCRIPT_CAMS(false, false, 3000, true, false, 0)
	CAM.DESTROY_CAM(cam, false)
	menu.trigger_commands('otr off')
	wait(500)
	CAM.DO_SCREEN_FADE_IN(0)
	menu.trigger_commands('disablevehexit off; becomeorbitalcannon off; disablevehcincam off;  disablevehselectnextweapon off; disablevehradiowheel off')
end)

-------------------------------------
--VEHICLE INSTANT LOCK
-------------------------------------


menu.toggle(vehicle_options, menuname('Vehicle', 'Vehicle Instant Lock-On'), {}, '', function(toggle)
	vehlock = toggle
	local default = {}
	local offsets = {
		0x08,
		0x10D8,
		0x70,
		0x60,
		0x178
	}

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
				0.0, --rotZ, 
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
		if not particleveh then
			menu.trigger_commands('vehicleptfx on')
		end
	end)
end


-------------------------------------
--AUTOPILOT
-------------------------------------

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
	
	local lastblip
	local lastdrivstyle
	local lastcoord
	
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
				TASK.TASK_VEHICLE_DRIVE_TO_COORD_LONGRANGE(0, vehicle, coord.x, coord.y, coord.z, 25.0, drivingstyle, 45.0);
				TASK.TASK_VEHICLE_PARK(0, vehicle, coord.x, coord.y, coord.z, ENTITY.GET_ENTITY_HEADING(vehicle), 7, 60.0, true);
				TASK.CLOSE_SEQUENCE_TASK(memory.read_int(ptr));
				TASK.TASK_PERFORM_SEQUENCE(PLAYER.PLAYER_PED_ID(), memory.read_int(ptr))
				TASK.CLEAR_SEQUENCE_TASK(ptr)

				lastblip = blip
				lastdrivstyle = drivingstyle
				return coord
			end
		end
	end

	if autopilot then
		lastcoord = DRIVE_TO_WAYPOINT()
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

menu.divider(menu_driving_style, 'Custom')

for k, flag in pairs(driving_style_flag) do
	menu.toggle(menu_driving_style, k, {}, '', function(on) 
		local toggle = on
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

-----------------------------------------------------------BODYGUARD MENU---------------------------------------------------------------


local bodyguards_options = menu.list(menu.my_root(), menuname('Bodyguard Menu', 'Bodyguard Menu'), {'bodyguardmenu'}, '')

menu.divider(bodyguards_options, menuname('Bodyguard Menu', 'Bodyguard Menu'))

-------------------------------------------------
--BODYGUARD
-------------------------------------------------


local bodyguard =
{
	['godmode'] = false,
	['ignoreplayers'] = false,
	--['weapon']
	--['model']
	['random_model'] = true, 	--random model
	['random_weapon'] = true,	--random weapon
	['spawned'] = {},
	['backup_godmode'] = false
}

menu.action(bodyguards_options, menuname('Bodyguard Menu', 'Spawn Bodyguard (7 Max)'), {'spawnbodyguard'}, '', function()
	local user_ped = PLAYER.PLAYER_PED_ID()
	local pos = ENTITY.GET_ENTITY_COORDS(user_ped)
	local size_ptr =  alloc(32); local any_ptr = alloc(32)
	local groupId = PED.GET_PED_GROUP_INDEX(user_ped); PED.GET_GROUP_SIZE(groupId, any_ptr, size_ptr); local groupSize = memory.read_int(size_ptr); memory.free(size_ptr); memory.free(any_ptr)
	if groupSize == 7 then
		notification.red('You reached the max number of bodyguards')
		return
	end
	pos.x = pos.x + math.random(-3, 3)
	pos.y = pos.y + math.random(-3, 3)
	pos.z = pos.z - 0.9
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
	menu.trigger_commands('bodyguardmenu')
end)


for k, model in pairs_by_keys(peds) do
	menu.action(bodyguards_model_list, k, {}, '', function()
		bodyguard.model = model
		bodyguard.random_model = false
		menu.set_menu_name(bodyguards_model_list, menuname('Bodyguard Menu', 'Set Model')..': '..k)
		menu.trigger_commands('bodyguardmenu')
	end)
end


menu.action(bodyguards_options, menuname('Bodyguard Menu', 'Clone Player (Bodyguard)'), {'clonebodyguard'}, '', function()
	local user_ped = PLAYER.PLAYER_PED_ID()
	local size_ptr =  alloc(32)
	local any_ptr = alloc(32)
	local pos = ENTITY.GET_ENTITY_COORDS(user_ped)
	local groupId = PLAYER.GET_PLAYER_GROUP(players.user()); PED.GET_GROUP_SIZE(groupId, any_ptr, size_ptr); local groupSize = memory.read_int(size_ptr); memory.free(size_ptr); memory.free(any_ptr)
	if groupSize >= 7 then
		notification.red('You reached the max number of bodyguards')
		return
	end
	pos.x = pos.x + math.random(-3, 3)
	pos.y = pos.y + math.random(-3, 3)
	pos.z = pos.z - 0.9
	local weapon
	if bodyguard.random_weapon then weapon = random(weapons) else weapon = bodyguard.weapon end
	local clone = PED.CLONE_PED(user_ped, 1, 1, 1); insert_once(bodyguard.spawned, 'mp_f_freemode_01'); insert_once(bodyguard.spawned, 'mp_m_freemode_01')
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
		menu.trigger_commands('bodyguardmenu')
	end)
end


menu.action(bodyguards_weapon_list,'Random Weapon', {}, '', function()
	bodyguard.random_weapon = true
	menu.set_menu_name(bodyguards_weapon_list, menuname('Bodyguard Menu', 'Set Weapon')..': Random')
	menu.trigger_commands('bodyguardmenu')
end)


for k, weapon in pairs_by_keys(weapons) do
	menu.action(bodyguards_weapon_list, k, {}, '', function()
		bodyguard.weapon = weapon
		bodyguard.random_weapon = false
		menu.set_menu_name(bodyguards_weapon_list, menuname('Bodyguard Menu', 'Set Weapon')..': '..k)
		menu.trigger_commands('bodyguardmenu')
	end)
end


menu.toggle(bodyguards_options, menuname('Bodyguard Menu', 'Invincible Bodyguard'), {'bodyguardsgodmode'}, '', function(on)
	bodyguard.godmode = on
end)


menu.toggle(bodyguards_options, menuname('Bodyguard Menu', 'Ignore Players'), {}, '', function(on)
	bodyguard.ignoreplayers = on
end)


menu.action(bodyguards_options, menuname('Bodyguard Menu', 'Delete Bodyguards'), {}, '', function()
	for k, model in pairs(bodyguard.spawned) do
		DELETE_ALL_PEDS_GIVEN_MODEL(model)
		bodyguard.spawned[k] = nil
	end
end)

-------------------------------------------------
--BACKUP HELICOPTER
-------------------------------------------------


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


menu.toggle(backup_heli_option,menuname('Bodyguard Menu - Backup Helicopter', 'Invincible Backup'), {'backupgodmode'}, '', function(on)
	bodyguard.backup_godmode = on
end)


---------------------------------------------------WORLD------------------------------------------------------------------------

local world_options = menu.list(menu.my_root(), menuname('World', 'World'), {}, '')


menu.divider(world_options, menuname('World', 'World'))

-------------------------------------
--JUMPING CARS
-------------------------------------


menu.toggle(world_options, menuname('World', 'Jumping Cars'), {}, '', function(toggle)
	jumpingcars = toggle
	util.create_thread(function()
		while jumpingcars do
			wait(1500)
			local entities = GET_NEARBY_VEHICLES(players.user(), 120)
			for k, vehicle in pairs(entities) do
				REQUEST_CONTROL(vehicle)
				ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, 0, 0, 6.5, 0, 0, 0, 0, false, false, true)
			end
		end
	end)
end)


-------------------------------------
--KILL ENEMIES
-------------------------------------


menu.action(world_options, menuname('World', 'Kill Enemies'), {'killenemies'}, '', function()
	local user_ped = PLAYER.PLAYER_PED_ID()
	local peds = GET_NEARBY_PEDS(players.user(), 500)
	for k, ped in pairs(peds) do
		if PED.IS_PED_IN_COMBAT(ped, user_ped) then
			local pos = ENTITY.GET_ENTITY_COORDS(ped)
			FIRE.ADD_OWNED_EXPLOSION(user_ped, pos.x, pos.y, pos.z, 1, 9999.9, true, false, 0.0)
		end
	end
end)


menu.toggle(world_options, menuname('World', 'Auto Kill Enemies'), {'autokillenemies'}, '', function(toggle)
	killenemies = toggle
	local user_ped = PLAYER.PLAYER_PED_ID()
	while killenemies do
		wait()
		local peds = GET_NEARBY_PEDS(players.user(), 500)
		for k, ped in pairs(peds) do
			if PED.IS_PED_IN_COMBAT(ped, user_ped) then
				local pos = ENTITY.GET_ENTITY_COORDS(ped)
				FIRE.ADD_OWNED_EXPLOSION(user_ped, pos.x, pos.y, pos.z, 1, 9999.9, true, false, 0.0)
			end
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

	util.create_thread(function()
		while angryplanes do
			wait()
			for k, plane in pairs(spawned) do
				if ENTITY.IS_ENTITY_DEAD(plane.plane) then
					spawned[ k ] = nil
				end
			end
		end
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
		entities.delete(plane.plane)
		entities.delete(plane.pilot)
	end
end)

script = menu.list(menu.my_root(), 'WiriScript', {}, '')

menu.divider(script, 'WiriScript')

menu.hyperlink(menu.my_root(), 'Join WiriScript FanClub', 'https://cutt.ly/wiriscript-fanclub', 'Join us in our fan club, created by komt.')

if outdated_translation then
	notification.normal(('"%s"'):format(general_config.language:gsub("^%l", string.upper))..' is outdated')
end


-----------------------------------------------------------------------------------------------------------

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
	if cursor_mode then 
		UI.toggle_cursor_mode(false) 
	end

	if bulletchanger then
		SET_BULLET_TO_DEFAULT()
	end

	if shootlazer then
		menu.trigger_commands('disablevehmousecontroloverride off; disablevehflymousecontroloverride off; disablevehsubmousecontroloverride off')
	end
	
	if speed_mult ~= 1.0 then
		SET_AMMO_SPEED_MULT(1.0)
	end

	if ufo_toggle then
		menu.trigger_commands('disablevehexit off; becomeorbitalcannon off; disablevehcincam off;  disablevehselectnextweapon off; disablevehradiowheel off')
	end

	if rape or piggyback then
		menu.trigger_commands('nocollision off')
	end

	if ufo_toggle then
		local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
		if ENTITY.GET_ENTITY_MODEL(vehicle) == joaat('hydra') then
			local obj = ENTITY.GET_ENTITY_ATTACHED_TO(vehicle)
			local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
			local ptr1 = alloc()
			entities.delete(vehicle)
			entities.delete(obj)
			PATHFIND.GET_CLOSEST_VEHICLE_NODE(pos.x, pos.y, pos.z, ptr1, 1, 100, 2.5)
			pos = memory.read_vector3(ptr1)
			ENTITY.SET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), pos.x, pos.y, pos.z, false, false, false)
			ENTITY.SET_ENTITY_VISIBLE(PLAYER.PLAYER_PED_ID(), true, 0)
			CAM.RENDER_SCRIPT_CAMS(false, false, 3000, true, false, 0)
			menu.trigger_commands('disablevehexit off; becomeorbitalcannon off; disablevehcincam off;  disablevehselectnextweapon off; disablevehradiowheel off')
		end
	end
end)

-------------------------------------

while true do
	wait()
	local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), true)
	
	if vehicle ~= 0 then
		local vehicleHash = ENTITY.GET_ENTITY_MODEL(vehicle)
		vehicleName = HUD._GET_LABEL_TEXT(VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(vehicleHash))
		if vehicleHash ~= lastVehicle then
			lastVehicle = vehicleHash
		end
	else
		vehicleName = '???'
	end
	
-------------------------------------
--AMMO SPEED MULT
-------------------------------------

	if speed_mult ~= 1.0 then
		SET_AMMO_SPEED_MULT(speed_mult)
	end

-------------------------------------
--HANDLING DISPLAY
-------------------------------------

	if display_handling then	
		local normal = {}
		local advanced = {}

		if PAD.IS_CONTROL_JUST_PRESSED(2, 323) then 
			GRAPHICS.SET_SCRIPT_GFX_DRAW_ORDER(80)
			UI.toggle_cursor_mode() 
			cursor_mode = not cursor_mode
		end

		for index = 1, #veh_display do
			for k, offset in pairs(handling_offsets.normal) do
				if veh_display[index] == k then
					normal[k] = offset
				end
			end
		end
			
		for index = 1, #veh_display do
			for k, offset in pairs(handling_offsets.advanced) do
				if veh_display[index] == k then
					advanced[k] = offset
				end
			end
		end
			
		UI.set_highlight_colour(0.0, 1.0, 1.0)
		UI.begin('Vehicle Handling', window1_x, window1_y)
		UI.label('Current Vehicle\t', vehicleName)
		
		if getn(normal) > 0 then UI.subhead('Normal') end
	
		for k, offset in pairs_by_keys(normal) do
			local addr = address_from_pointer_chain(worldPtr, {0x08, 0xD30, 0x938, offset})
			local name = k..':\t'
			if addr ~= 0 then
				if k == veh_focused then 
					UI.label(name, round(memory.read_float(addr), 3), on_focus_colour, on_focus_colour)
				else
					UI.label(name, round(memory.read_float(addr), 3))
				end
			else
				if veh_focused == k then 
					UI.label(name, '???', on_focus_colour, on_focus_colour)
				else
					UI.label(name, '???')
				end
			end
		end

		if getn(advanced) > 0 then UI.subhead('Advanced') end
		
		for k, offset in pairs_by_keys(advanced) do
			local addr = address_from_pointer_chain(worldPtr, {0x08, 0xD30, 0x938, offset})
			local name = k..':\t'
			if addr ~= 0 then
				if veh_focused == k then 
					UI.label(name, round(memory.read_float(addr), 3), on_focus_colour, on_focus_colour)
				else
					UI.label(name, round(memory.read_float(addr), 3))
				end
			else
				if veh_focused == k then 
					UI.label(name, '???', on_focus_colour, on_focus_colour)
				else
					UI.label(name, '???')
				end
			end
		end
		
		UI.divider()
		UI.start_horizontal()
		   
		if UI.button(
		   'Save Handling',
			   {
					['r'] = 127	/ 255, 
					['g'] = 0, 
					['b'] = 204 / 255, 
					['a'] = 1.0
				}
			) then
			   save_handling()
		end

		if UI.button(
		   'Load Handling',
			   {
					['r'] = 127	/ 255, 
					['g'] = 0, 
					['b'] = 204 / 255, 
					['a'] = 1.0
				}
			) then
			   load_handling()
		   end
		
		UI.end_horizontal()
		window1_x, window1_y = UI.finish()
		
		local buttons
		if cursor_mode then
			buttons = {
				{'Disable Cursor Mode', 323, true}
			}
		else
			buttons = {
				{'Cursor Mode', 323, true}
			}
		end
		INSTRUCTIONAL.DRAW(buttons)
	end
end

--a message for whoever is watching this: I love you <3 kek
