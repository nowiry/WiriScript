--[[
--------------------------------
THIS FILE IS PART OF WIRISCRIPT
        Nowiry#2663
--------------------------------
]]

require "natives-1640181023"

wait = util.yield
joaat = util.joaat
alloc = memory.alloc
cTime = util.current_time_millis
create_tick_handler = util.create_tick_handler


config = {
	controls = {
		vehicleweapons 		= 86,
		airstrikeaircraft 	= 86
	},
	general = {
		standnotifications 	= false,
		displayhealth 		= true,
		language 			= 'english',
		disablelockon 		= false,
		disablepreview 		= false,
		bustedfeatures 		= false,
		developer			= false
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

Colour = {}
instructional = {}
ini = {}
vect = {}
relationship = {}
features = {}
menunames = {}
notification = {}
debug = {}


function notification.normal(message, color)
	if not config.general.standnotifications then
		GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT("DIA_ZOMBIE1", 0)
		while not GRAPHICS.HAS_STREAMED_TEXTURE_DICT_LOADED("DIA_ZOMBIE1") do
			wait()
		end
		message = tostring(message) or 'nil'
		if not message:match('[%.?]$') then message = message .. '.' end
		HUD._THEFEED_SET_NEXT_POST_BACKGROUND_COLOR(color or 2)
		util.BEGIN_TEXT_COMMAND_THEFEED_POST(message)
		local tittle = 'WiriScript'
		local subtitle = '~c~' .. 'Notification' .. '~s~'
		HUD.END_TEXT_COMMAND_THEFEED_POST_MESSAGETEXT("DIA_ZOMBIE1", "DIA_ZOMBIE1", true, 4, tittle, subtitle)
		HUD.END_TEXT_COMMAND_THEFEED_POST_TICKER(true, false)
	else
		message = '[WiriScript] ' .. tostring(message):gsub('[~]%w[~]', '')
		if not string.match(message, '[%.?]$') then message = message .. '.' end
		util.toast(message)
	end
end


function notification.help(message)
	if not message:match('[%.?]$') then message = message .. '.' end
	util.BEGIN_TEXT_COMMAND_THEFEED_POST("~BLIP_INFO_ICON~ " .. message)
	HUD.END_TEXT_COMMAND_THEFEED_POST_TICKER_WITH_TOKENS(true, true)
end


function menuname(section, name)
	features[ section ] = features[ section ] or {}
	features[ section ][ name ] = features[ section ][ name ] or ""
	if config.general.language ~= 'english' then
		menunames[ section ] = menunames[ section ] or {}
		menunames[ section ][ name ] = menunames[ section ][ name ] or ""
		if menunames[ section ][ name ] == "" then return name end
		return menunames[ section ][ name ]
	end
	return name
end


function ini.save(file, t)
	file = io.open(file, 'w')
	local contents = ""
	for section, s in pairs_by_keys(t) do
		contents = contents .. ('[%s]\n'):format(section)
		for key, value in pairs(s) do
			if string.len(key) == 1 then key = string.upper(key) end
			contents = contents .. ('%s = %s\n'):format(key, tostring(value))
		end
		contents = contents .. '\n'
	end
	file:write(contents)
	file:close()
end


function ini.load(file)
	local t = {}
	local section
	for line in io.lines(file) do
		local strg = line:match('^%[([^%]]+)%]$')
		if strg then
			section = strg
			t[ section ] = t[ section ] or {}
		end
		local key, value = line:match('^([%w_]+)%s*=%s*(.+)$')
		if key and value ~= nil then
			if string.len(key) == 1 then key = string.lower(key) end
			if value == 'true' then value = true end
			if value == 'false' then value = false end
			if tonumber(value) then value = tonumber(value) end
			t[ section ][ key ] = value
		end
	end
	return t
end


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


vect.new = function(x,y,z)
    return {['x'] = x, ['y'] = y, ['z'] = z or 0}
end

vect.subtract = function(a,b)
	return vect.new(a.x - b.x, a.y - b.y, a.z - b.z)
end

vect.add = function(a,b)
	return vect.new(a.x + b.x, a.y + b.y, a.z + b.z)
end

vect.mag = function(a)
	return math.sqrt(a.x^2 + a.y^2 + a.z^2)
end

vect.norm = function(a)
    local mag = vect.mag(a)
    return vect.mult(a, 1/mag)
end

vect.mult = function(a,b)
	return vect.new(a.x*b, a.y*b, a.z*b)
end

-- returns the dot product of two vectors
vect.dot = function (a,b)
	return (a.x * b.x + a.y * b.y + a.z * b.z)
end

--returns the angle between two vectors
vect.angle = function (a,b)
	return math.acos(vect.dot(a,b) / ( vect.mag(a) * vect.mag(b) ))
end

-- returns the distance between two coords
vect.dist = function(a,b)
    return vect.mag(vect.subtract(a, b))
end

vect.tostring = function(a)
    return "{" .. a.x .. ", " .. a.y .. ", " .. a.z .. "}"
end


function corner_help_given_control_index(i, message)
	for name, control in pairs(imputs) do
		if control[2] == i then
			util.show_corner_help('Press' .. ('~%s~ '):format(name) .. ' ' .. message)
			return
		end
	end
	error('Control index not found')
end


function address_from_pointer_chain(basePtr, offsets)
	local addr = memory.read_long(basePtr)
	for k = 1, (#offsets - 1) do
		addr = memory.read_long(addr + offsets[k])
		if addr == NULL then
			return 0
		end
	end
	addr = addr + offsets[#offsets]
	return addr
end


function atan2(y, x)
	if x > 0 then
		return ( math.atan(y / x) )
	end
	if x < 0 and y >= 0 then
		return ( math.atan(y / x) + math.pi )
	end
	if x < 0 and y < 0 then
		return ( math.atan(y / x) - math.pi )
	end
	if x == 0 and y > 0 then
		return ( math.pi / 2 )
	end
	if x == 0 and y < 0 then
		return ( - math.pi / 2 )
	end
	if x == 0 and y == 0 then
		return 0 -- actually 'tan' is not defined in this case
	end
end


function GET_ROTATION_FROM_DIRECTION(v)
	local mag = vect.mag(v)
	local rotation = {
		x =   math.asin(v.z / mag) * (180 / math.pi),
		y =   0.0,
		z = - atan2(v.x, v.y) * (180 / math.pi)
	}
	return rotation
end

-- all credits to Ren for suggesting me this function
function SET_ENT_FACE_ENT(ent1, ent2) 
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
	ENTITY.SET_ENTITY_ROTATION(ent1, rot.x, rot.y, rot.z)
end


function trapcage(pid) -- small
	local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
	local pos = ENTITY.GET_ENTITY_COORDS(p)
	local objhash = joaat("prop_gold_cont_01")
	REQUEST_MODELS(objhash)
	local obj = OBJECT.CREATE_OBJECT(objhash, pos.x, pos.y, pos.z - 1.0, true, false, false)
	ENTITY.FREEZE_ENTITY_POSITION(obj, true)
	STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(objhash)
end


function trapcage_2(pid) -- tall
	local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
	local pos = ENTITY.GET_ENTITY_COORDS(p)
	local objhash = joaat("prop_rub_cage01a")
	REQUEST_MODELS(objhash)
	local obj1 = OBJECT.CREATE_OBJECT(objhash, pos.x, pos.y, pos.z - 1.0, true, false, false)
	local obj2 = OBJECT.CREATE_OBJECT(objhash, pos.x, pos.y, pos.z + 1.2, true, false, false)
	ENTITY.SET_ENTITY_ROTATION(obj2, -180.0, ENTITY.GET_ENTITY_ROTATION(obj2).y, 90.0, 1, true)
	ENTITY.FREEZE_ENTITY_POSITION(obj1, true)
	ENTITY.FREEZE_ENTITY_POSITION(obj2, true)
	STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
end


function ADD_BLIP_FOR_ENTITY(entity, blipSprite, colour)
	local blip = HUD.ADD_BLIP_FOR_ENTITY(entity)
	HUD.SET_BLIP_SPRITE(blip, blipSprite)
	HUD.SET_BLIP_COLOUR(blip, colour)
	HUD.SHOW_HEIGHT_ON_BLIP(blip, false)
	HUD.SET_BLIP_ROTATION(blip, SYSTEM.CEIL(ENTITY.GET_ENTITY_HEADING(entity)))
	NETWORK.SET_NETWORK_ID_CAN_MIGRATE(entity, false)
	util.create_thread(function()
		while not ENTITY.IS_ENTITY_DEAD(entity) do
			local heading = ENTITY.GET_ENTITY_HEADING(entity)
			HUD.SET_BLIP_ROTATION(blip, SYSTEM.CEIL(heading))
			wait()
		end
		util.remove_blip(blip)
	end)
	return blip
end


local function ADD_RELATIONSHIP_GROUP(name)
	local ptr = alloc(32)
	PED.ADD_RELATIONSHIP_GROUP(name, ptr)
	local rel = memory.read_int(ptr); memory.free(ptr)
	return rel
end


function relationship:hostile(ped)
	if not PED._DOES_RELATIONSHIP_GROUP_EXIST(self.hostile_group) then
		self.hostile_group = ADD_RELATIONSHIP_GROUP('hostile_group')
		PED.SET_RELATIONSHIP_BETWEEN_GROUPS(0, self.hostile_group, self.hostile_group)
	end
	PED.SET_PED_RELATIONSHIP_GROUP_HASH(ped, self.hostile_group)
end


function relationship:friendly(ped)
	if not PED._DOES_RELATIONSHIP_GROUP_EXIST(self.friendly_group) then
		self.friendly_group = ADD_RELATIONSHIP_GROUP('friendly_group')
		PED.SET_RELATIONSHIP_BETWEEN_GROUPS(0, self.friendly_group, self.friendly_group)
	end
	PED.SET_PED_RELATIONSHIP_GROUP_HASH(ped, self.friendly_group)
end

-- returns a random value from the given table
function random(t)
	if rawget(t, 1) ~= nil then return t[ math.random(1, #t) ] end
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

-- returns a list of nearby peds given player Id
function GET_NEARBY_PEDS(pid, radius) 
	local peds = {}
	local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
	local pos = ENTITY.GET_ENTITY_COORDS(p)
	for k, ped in pairs(entities.get_all_peds_as_handles()) do
		if ped ~= p and not PED.IS_PED_FATALLY_INJURED(ped) then
			local ped_pos = ENTITY.GET_ENTITY_COORDS(ped)
			if vect.dist(pos, ped_pos) <= radius then table.insert(peds, ped) end
		end
	end
	return peds
end

-- returns a list of nearby vehicles given player Id
function GET_NEARBY_VEHICLES(pid, radius) 
	local vehicles = {}
	local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
	local pos = ENTITY.GET_ENTITY_COORDS(p)
	local v = PED.GET_VEHICLE_PED_IS_IN(p, false)
	for _, vehicle in ipairs(entities.get_all_vehicles_as_handles()) do 
		local veh_pos = ENTITY.GET_ENTITY_COORDS(vehicle)
		if vehicle ~= v and vect.dist(pos, veh_pos) <= radius then table.insert(vehicles, vehicle) end
	end
	return vehicles
end

-- returns nearby peds and vehicles given player Id
function GET_NEARBY_ENTITIES(pid, radius) 
	local peds = GET_NEARBY_PEDS(pid, radius)
	local vehicles = GET_NEARBY_VEHICLES(pid, radius)
	local entities = peds
	for i = 1, #vehicles do table.insert(entities, vehicles[i]) end
	return entities
end


function DELETE_NEARBY_VEHICLES(pos, model, radius)
	local hash = joaat(model)
	local vehicles = entities.get_all_vehicles_as_handles()
	for _, vehicle in ipairs(vehicles) do
		if ENTITY.DOES_ENTITY_EXIST(vehicle) and ENTITY.GET_ENTITY_MODEL(vehicle) == hash then
			local vpos = ENTITY.GET_ENTITY_COORDS(vehicle, false)
			local ped = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1)
			if not PED.IS_PED_A_PLAYER(ped) and vect.dist(pos, vpos) < radius then
				REQUEST_CONTROL_LOOP(vehicle)
				REQUEST_CONTROL_LOOP(ped)
				ENTITY.SET_ENTITY_AS_MISSION_ENTITY(vehicle, true, true)
				ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ped, true, true)
				entities.delete_by_handle(vehicle)
				entities.delete_by_handle(ped)
			end
		end
	end
end

-- deletes all non player peds with the given model name
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


write_global = {
	byte = function(global, value)
		memory.write_byte(memory.script_global(global), value)
	end,
	int = function(global, value)
		memory.write_int(memory.script_global(global), value)
	end,
	float = function(global)
		return memory.write_float(memory.script_global(global), value)
	end
}


read_global = {
	byte = function(global)
		return memory.read_byte(memory.script_global(global))
	end,
	int = function(global)
		return memory.read_int(memory.script_global(global))
	end,
	float = function(global)
		return memory.read_float(memory.script_global(global))
	end
}


function SET_PED_CAN_BE_KNOCKED_OFF_VEH(ped, state)
	native_invoker.begin_call()
	native_invoker.push_arg_int(ped)
	native_invoker.push_arg_int(state)
	native_invoker.end_call("7A6535691B477C48")
end


function equals(a,b)
	if a == b then return true end
	local type1 = type(a)
    local type2 = type(b)
    if type1 ~= type2 then return false end
	if type1 ~= 'table' then return false end
	for k, v in pairs(a) do
		if b[ k ] == nil or not equals(v, b[ k ]) then
			return false
		end
	end
	return true
end


function size(table)
	-- treat as array
	if rawget(table, 1) ~= nil then return #table end
	-- treat as object
	local n = 0
	for k, v in pairs(table) do
		n = n + 1
	end
	return n
end


function full_size(table)
	if rawget(table, 1) ~= nil then return #table end
	local n = 0
	for k, v in pairs(table) do
		if type(v) == 'table' then
			n = n + full_size(v)
		else n = n + 1 end
	end
	return n
end


function key_of(t, value)
	for k, v in pairs(t) do
		if equals(v, value) then
			return k
		end
	end
	return nil
end


function includes(t, value)
	for k, v in pairs(t) do
		if equals(v, value) then
			return true
		end
	end
	return false
end

-- returns a table containing all the key/value pairs from 'a' that match the key/value pairs from 'b'
function intersection(a,b)
	local res = {}
	for k, v in pairs(a) do
		if equals(v, b[ k ]) then
			res[ k ] = v
		elseif type(v) == 'table' and type(b[ k ]) == 'table' then
			res[ k ] = intersection(v, b[ k ])
		end
	end
	return res
end

-- 1) given two tables:
-- 		a = {key1 = 4, key2 = {key1 = 1, key2 = 4}, key3 = {}}
--		b = {key1 = 5, key2 = {key1 = 8, key3 = true}, key3 = 'apple'}
-- 2) it returns
--		{key1 = 5, key2 = {key1 = 8}, key3 = 'apple'}
function swap_values(a,b)
	local res = {}
	for k, v in pairs(a) do
		if type(v) == 'table' and type(b[ k ]) == 'table' then
			res[ k ] = swap_values(v, b[ k ])
		else
			res[ k ] = b[ k ]  
		end
	end
	return res
end

-- 1) checks if the given value exists in the given table
-- 2) if it doesn't, it inserts it
function insert_once(t, value)
	if not includes(t, value) then
		table.insert(t, value)
		return true
	end
	return false
end


function does_key_exists(table, key)
	for k, v in pairs(table) do
		if k == key then return true end
	end
	return false
end


function unpack(self)
	if rawget(self, 1) ~= nil then
		return table.unpack(self)
	else
		local l = {}
		for k, v in pairs(self) do
			table.insert(l, v)
		end
		return table.unpack(l)
	end
end

-- increases (or decreases) the value until reaching the limit (if limit ~= nil).
-- 1) to increase the value, delta > 0
-- 2) to decrease the value, delta < 0 or limit < current value
-- 3) requires on tick call
function incr(current, delta, limit)
	if current == limit then return current end
	if limit then
		if limit < current and delta > 0 then
			delta = - delta
		end
		current = current + delta
		if math.abs(limit - current) < delta then
			current = limit
		end
	else current = current + delta end
	return current
end


function round(num, places)
	return tonumber(string.format('%.' .. (places or 0) .. 'f', num))
end

-- https://forum.cfx.re/t/get-position-where-player-is-aiming/1903886/2
function ROTATION_TO_DIRECTION(rotation) 
	local adjusted_rotation = { 
		x = (math.pi / 180) * rotation.x, 
		y = (math.pi / 180) * rotation.y, 
		z = (math.pi / 180) * rotation.z 
	}
	local direction = {
		x = - math.sin(adjusted_rotation.z) * math.abs(math.cos(adjusted_rotation.x)), 
		y =   math.cos(adjusted_rotation.z) * math.abs(math.cos(adjusted_rotation.x)), 
		z =   math.sin(adjusted_rotation.x)
	}
	return direction
end


function GET_OFFSET_FROM_CAM(dist)
	local rot = CAM.GET_GAMEPLAY_CAM_ROT(0)
	local pos = CAM.GET_GAMEPLAY_CAM_COORD()
	local dir = ROTATION_TO_DIRECTION(rot)
	local destination = {
		x = pos.x + dir.x * dist,
		y = pos.y + dir.y * dist,
		z = pos.z + dir.z * dist 
	}
	return destination
end

-- requires on tick call
function debug.add_text(...)
	if not config.general.developer then
		return
	end
	local arg = {...}
	local strg = ""
	for _, w in ipairs(arg) do
		strg = strg .. tostring(w) .. '\n'
	end
	debug.text = debug.text .. strg
end

-- requires on tick call
function debug.draw()
	if not config.general.developer then
		return
	end
	directx.draw_text(0.05, 0.05, debug.text or "nil", ALIGN_TOP_LEFT, 0.6, Colour.New(0.0, 1.0, 1.0), false)
	debug.text = ""
end


function GET_CAM_COORDS_AND_ROT(cam)
	local pos, rot
	if cam ~= nil then
		rot = CAM.GET_CAM_ROT(cam, 2)
		pos = CAM.GET_CAM_COORD(cam)
	else
		rot = CAM.GET_GAMEPLAY_CAM_ROT(0)
		pos = CAM.GET_GAMEPLAY_CAM_COORD()
	end
	return pos, rot
end


function RAYCAST(cam, dist, flag)
	local ptr1, ptr2, ptr3, ptr4 = alloc(), alloc(), alloc(), alloc()
	local pos, rot = GET_CAM_COORDS_AND_ROT(cam)
	local dir = ROTATION_TO_DIRECTION(rot)
	local destination = { 
		x = pos.x + dir.x * dist, 
		y = pos.y + dir.y * dist, 
		z = pos.z + dir.z * dist 
	}
	SHAPETEST.GET_SHAPE_TEST_RESULT(
		SHAPETEST.START_EXPENSIVE_SYNCHRONOUS_SHAPE_TEST_LOS_PROBE(
			pos.x, 
			pos.y, 
			pos.z, 
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

-- used in teleport gun
function SET_ENTITY_COORDS_2(entity, coords) 
	local addr = entities.handle_to_pointer(entity)
	local v = memory.read_long(addr + 0x30)
	memory.write_float(v + 0x50, coords.x)
	memory.write_float(v + 0x54, coords.y)
	memory.write_float(v + 0x58, coords.z)
	memory.write_float(addr + 0x90, coords.x)
	memory.write_float(addr + 0x94, coords.y)
	memory.write_float(addr + 0x98, coords.z)
end


function GET_WAYPOINT_COORDS()
	local blip = HUD.GET_FIRST_BLIP_INFO_ID(8)
	if blip == NULL then return nil end
	local coords = HUD.GET_BLIP_COORDS(blip)
	local tick = 0
	local success, groundz = util.get_ground_z(coords.x, coords.y)
	while not success and tick < 10 do
		wait()
		success, groundz = util.get_ground_z(coords.x, coords.y)
		tick = tick + 1
	end
	if success then coords.z = groundz end
	return coords
end


function instructional:begin ()
	if not self.scaleform then
		self.scaleform = GRAPHICS.REQUEST_SCALEFORM_MOVIE("instructional_buttons")
	end
	
	if not GRAPHICS.HAS_SCALEFORM_MOVIE_LOADED(self.scaleform) then
        return false
    end
	
	GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(self.scaleform, "CLEAR_ALL")
	GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

    GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(self.scaleform, "TOGGLE_MOUSE_BUTTONS")
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_BOOL(true)
	GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

	self.position = 0
	return true
end

-- name can be a label
function instructional:add_data_slot (index, name, button)
	GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(self.scaleform, "SET_DATA_SLOT")
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(self.position)

    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_PLAYER_NAME_STRING(button)
    if HUD.DOES_TEXT_LABEL_EXIST(name) then
		GRAPHICS.BEGIN_TEXT_COMMAND_SCALEFORM_STRING(name)
		GRAPHICS.END_TEXT_COMMAND_SCALEFORM_STRING()
	else
		GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_TEXTURE_NAME_STRING(name)
	end
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_BOOL(true)
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(index)
    GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

	self.position = self.position + 1
end


function add_control_instructional_button (index, name)
	local button = PAD.GET_CONTROL_INSTRUCTIONAL_BUTTON(2, index, true)
    instructional:add_data_slot(index, name, button)
end


function add_control_group_instructional_button (index, name)
	local button = PAD.GET_CONTROL_GROUP_INSTRUCTIONAL_BUTTON(2, index, true)
    instructional:add_data_slot(index, name, button)
end


function instructional:set_background_colour (r, g, b, a)
	GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(instructional.scaleform, "SET_BACKGROUND_COLOUR")
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(r)
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(g)
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(b)
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(a)
	GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
end


function instructional:draw ()
	GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(self.scaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
	GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

    GRAPHICS.DRAW_SCALEFORM_MOVIE_FULLSCREEN(self.scaleform, 255, 255, 255, 255, 0)

	self.position = 0
end


function DRAW_LOCKON_SPRITE_ON_PLAYER(pid, colour)
	local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
	local mpos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
	local dist = vect.dist(pos, mpos)
	local max = 2000.0
	local delta = max - dist
	local mult = delta / max
	local ptrx, ptry = alloc(), alloc()
	colour = colour or Colour.New(255, 0, 0)
	
	GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT("helicopterhud", false)
	while not GRAPHICS.HAS_STREAMED_TEXTURE_DICT_LOADED("helicopterhud") do
		wait()
	end
	if dist > max then 
		mult = 0.0
	end
	if mult > 1.0 then
		mult = 1.0
	end
	GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(pos.x, pos.y, pos.z, ptrx, ptry)
	local posx = memory.read_float(ptrx); memory.free(ptrx)
	local posy = memory.read_float(ptry); memory.free(ptry)
	GRAPHICS.DRAW_SPRITE("helicopterhud", "hud_outline", posx, posy, mult * 0.03 * 1.5, mult * 0.03 * 2.6, 90.0, colour.r, colour.g, colour.b, 255, true)
end


function IS_PLAYER_FRIEND(pid)
	local ptr = alloc(104)
	NETWORK.NETWORK_HANDLE_FROM_PLAYER(pid, ptr, 13)
	if NETWORK.NETWORK_IS_HANDLE_VALID(ptr, 13) then
		return NETWORK.NETWORK_IS_FRIEND(ptr)
	end
end


function DRAW_STRING(s, x, y, scale, font)
	HUD.BEGIN_TEXT_COMMAND_DISPLAY_TEXT("STRING")
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

-- 1) requests all the given models
-- 2) waits till all of them have been loaded
function REQUEST_MODELS(...)
	local arg = {...}
	for _, model in ipairs(arg) do
		if not STREAMING.IS_MODEL_VALID(model) then
			error('tried to request an invalid model')
		end
		STREAMING.REQUEST_MODEL(model)
		while not STREAMING.HAS_MODEL_LOADED(model) do
			wait()
		end
	end
end


function REQUEST_PTFX_ASSET(asset)
	STREAMING.REQUEST_NAMED_PTFX_ASSET(asset)
	while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(asset) do
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


function first_upper(txt)
	return tostring(txt):gsub('^%l', string.upper)
end

function cap_each_word(txt)
	txt = string.lower(txt)
	return txt:gsub('(%l)(%w+)', function(a,b) return string.upper(a) .. b end)
end


Colour.New = function(R, G, B, A)
    local type = math.type(R + G + B)
    if type == 'integer' then
        A = A or 255
    elseif type == 'float' then
        A = A or 1.0
    end
    return {r = R, g = G, b = B, a = A}
end

Colour.Mult = function(colour, n)
    local new_colour = {}
    for k, v in pairs(colour) do
        new_colour[ k ] = v * n
    end 
    return new_colour
end

-- needs to be called on tick
-- numbers need to be integers
Colour.Rainbow = function(colour)
	if colour.r > 0 and colour.b == 0 then
		colour.r = colour.r - 1
		colour.g = colour.g + 1
	end
	if colour.g > 0 and colour.r == 0 then
		colour.g = colour.g - 1
		colour.b = colour.b + 1
	end
	if colour.b > 0 and colour.g == 0 then
		colour.r = colour.r + 1
		colour.b = colour.b - 1
	end return colour
end

Colour.Normalize = function(colour)
    local new_colour = {}
    for k, v in pairs(colour) do
        new_colour[ k ] = v / 255
    end 
    return new_colour
end

Colour.Integer = function(colour)
    local new_colour = {}
    for k, v in pairs(colour) do
        new_colour[ k ] = math.floor(v * 255)
    end 
    return new_colour
end

Colour.Random = function(colour)
    local new_colour = {}
    new_colour.r = math.random(0,255)
    new_colour.g = math.random(0,255)
    new_colour.b = math.random(0,255)
    new_colour.a = 255
    return new_colour
end


function GET_USER_VEHICLE_MODEL(last_vehicle)
	local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), last_vehicle)
	if vehicle ~= NULL then
		return ENTITY.GET_ENTITY_MODEL(vehicle)
	end
	return NULL
end


function GET_USER_VEHICLE_NAME()
	local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), true)
	if vehicle ~= NULL then
		local model = ENTITY.GET_ENTITY_MODEL(vehicle)
		return HUD._GET_LABEL_TEXT(VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(model)), model
	else
		return '???'
	end
end


function IS_THIS_MODEL_AN_AIRCRAFT(model)
	return VEHICLE.IS_THIS_MODEL_A_HELI(model) or VEHICLE.IS_THIS_MODEL_A_PLANE(model)
end

function IS_PED_IN_ANY_AIRCRAFT(ped)
	return PED.IS_PED_IN_ANY_PLANE(ped) or PED.IS_PED_IN_ANY_HELI(ped)
end


function busted(callback, parent, menu_name, ...)
	local arg = {...}
	local name = menu_name -- doing this to call menuname function even if busted features are disabled
	if config.general.bustedfeatures then
		return callback(parent, name, table.unpack(arg) )
	end
end

function developer(callback, ...)
	local arg = {...}
	if config.general.developer then
		return callback( table.unpack(arg) )
	end
end


function get_player_clan(player)
	local clan 				= {}
	local network_handle 	= alloc(104)
    local clan_desc 		= alloc(280)
	local to_state 			= {'Off', 'On'}
    NETWORK.NETWORK_HANDLE_FROM_PLAYER(player, network_handle, 13)
    if NETWORK.NETWORK_IS_HANDLE_VALID(network_handle, 13) and NETWORK.NETWORK_CLAN_PLAYER_GET_DESC(clan_desc, 35, network_handle) then
		clan.icon 	= memory.read_int(clan_desc)
		clan.name 	= memory.read_string(clan_desc + 0x08)
		clan.tag 	= memory.read_string(clan_desc + 0x88)
		clan.rank 	= memory.read_string(clan_desc + 0xB0)
		clan.motto  = players.clan_get_motto(player)
		--[[
		clan.colour = {
			memory.read_int(clan_desc + 0x100),
			memory.read_int(clan_desc + 0x108),
			memory.read_int(clan_desc + 0x110)
		}]]
		clan.alt_badge = to_state[ memory.read_byte(clan_desc + 0xA0) + 1 ] -- returns "Off" or "On"
	end
	memory.free(network_handle)
	memory.free(clan_desc)
	return clan
end


function REQUEST_WEAPON_ASSET(hash)
	WEAPON.REQUEST_WEAPON_ASSET(hash, 31, 0)
	while not WEAPON.HAS_WEAPON_ASSET_LOADED(hash) do
		wait()
	end
	WEAPON.GIVE_WEAPON_TO_PED(PLAYER.PLAYER_PED_ID(), hash, 120, 1, 1)
	WEAPON.SET_CURRENT_PED_WEAPON(PLAYER.PLAYER_PED_ID(), hash, 1)
end


function draw_box_esp(entity, colour)
	local min_ptr = alloc()
	local max_ptr = alloc()
	if ENTITY.DOES_ENTITY_EXIST(entity) then
		MISC.GET_MODEL_DIMENSIONS(ENTITY.GET_ENTITY_MODEL(entity), min_ptr, max_ptr)
		local max = memory.read_vector3(max_ptr); memory.free(max_ptr)
		local min = memory.read_vector3(min_ptr); memory.free(min_ptr)
		local width   = 2 * max.x
		local length  = 2 * max.y
		local depth   = 2 * max.z
		local offset1 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, -width / 2,  length / 2,  depth / 2)
		local offset4 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity,  width / 2,  length / 2,  depth / 2)
		local offset5 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, -width / 2,  length / 2, -depth / 2)
		local offset7 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity,  width / 2,  length / 2, -depth / 2)
		local offset2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, -width / 2, -length / 2,  depth / 2) 
		local offset3 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity,  width / 2, -length / 2,  depth / 2)
		local offset6 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, -width / 2, -length / 2, -depth / 2)
		local offset8 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity,  width / 2, -length / 2, -depth / 2)
		GRAPHICS.DRAW_LINE(offset1.x, offset1.y, offset1.z, offset4.x, offset4.y, offset4.z, colour.r, colour.g, colour.b, colour.a)
		GRAPHICS.DRAW_LINE(offset1.x, offset1.y, offset1.z, offset2.x, offset2.y, offset2.z, colour.r, colour.g, colour.b, colour.a)
		GRAPHICS.DRAW_LINE(offset1.x, offset1.y, offset1.z, offset5.x, offset5.y, offset5.z, colour.r, colour.g, colour.b, colour.a)
		GRAPHICS.DRAW_LINE(offset2.x, offset2.y, offset2.z, offset3.x, offset3.y, offset3.z, colour.r, colour.g, colour.b, colour.a)
		GRAPHICS.DRAW_LINE(offset3.x, offset3.y, offset3.z, offset8.x, offset8.y, offset8.z, colour.r, colour.g, colour.b, colour.a)
		GRAPHICS.DRAW_LINE(offset4.x, offset4.y, offset4.z, offset7.x, offset7.y, offset7.z, colour.r, colour.g, colour.b, colour.a)
		GRAPHICS.DRAW_LINE(offset4.x, offset4.y, offset4.z, offset3.x, offset3.y, offset3.z, colour.r, colour.g, colour.b, colour.a)
		GRAPHICS.DRAW_LINE(offset5.x, offset5.y, offset5.z, offset7.x, offset7.y, offset7.z, colour.r, colour.g, colour.b, colour.a)
		GRAPHICS.DRAW_LINE(offset6.x, offset6.y, offset6.z, offset2.x, offset2.y, offset2.z, colour.r, colour.g, colour.b, colour.a)
		GRAPHICS.DRAW_LINE(offset6.x, offset6.y, offset6.z, offset8.x, offset8.y, offset8.z, colour.r, colour.g, colour.b, colour.a)
		GRAPHICS.DRAW_LINE(offset5.x, offset5.y, offset5.z, offset6.x, offset6.y, offset6.z, colour.r, colour.g, colour.b, colour.a)
		GRAPHICS.DRAW_LINE(offset7.x, offset7.y, offset7.z, offset8.x, offset8.y, offset8.z, colour.r, colour.g, colour.b, colour.a)
	end
end


function draw_health_on_ped(ped, distance)
	if ENTITY.DOES_ENTITY_EXIST(ped) and ENTITY.IS_ENTITY_ON_SCREEN(ped) then
		local ptrX = alloc()
		local ptrY = alloc()
		local pos = {}
		local perc_health
		local CPed = entities.handle_to_pointer(ped)
		
		if CPed == NULL then 
			return 
		end
		-- by default a ped dies when it's healh is below the injured level (commonly 100)
		local health = memory.read_float(CPed + 0x280) - 100.0
		local health_max = memory.read_float(CPed + 0x2A0) - 100.0
		local armor = memory.read_float(CPed + 0x1530)
		local coords = ENTITY.GET_ENTITY_COORDS(ped)
		local m_coords = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
		local dist = vect.dist(m_coords, coords)
		local perc_dist = 1 - (dist / distance)
		local perc_armor = armor / 100 
		
		if health < 0 then -- substract 100 from health results in a negative number when the ped is dead
			health = 0 
		end
	
		if health_max <= 0 then -- could happen if a player is using undead off radar 
			perc_health = 0
		else 
			local perc = health / health_max 
			if perc > 1.0 then -- health > max health
				perc = 1.0
			end
			perc_health = perc
		end

		if dist > distance then 
			perc_dist = 0 
		elseif perc_dist > 1.0 then	
			perc_dist = 1.0 
		end

		-- the max armor a player can have in gta online is 50 but it's 100 in single player
		-- so a 50% of the armor bar in gta online means it's full, more than that triggers a moder detection
		if perc_armor > 1.0 then
			perc_armor = 1.0 
		end
		
		local offset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0, 0, 1.0)
		local total_length = 0.05 * perc_dist^3
		local width = 0.008 * perc_dist^1.5
		local color = get_blended_color(perc_health) -- colour of the health bar (goes from green to red)
		local health_bar_length = interpolate(0, total_length, perc_health)
		local armor_bar_length = interpolate(0, total_length, perc_armor)
		
		HUD.GET_HUD_SCREEN_POSITION_FROM_WORLD_POSITION(offset.x, offset.y, offset.z, ptrX, ptrY)
		pos.x = memory.read_float(ptrX); memory.free(ptrX)
		pos.y = memory.read_float(ptrY); memory.free(ptrY)

		-- health
		GRAPHICS.DRAW_RECT(pos.x, pos.y, total_length, width, color.r, color.g, color.b, 120)
		GRAPHICS.DRAW_RECT(pos.x, pos.y, total_length + 0.002, width + 0.002, 0, 0, 0, 120)
		GRAPHICS.DRAW_RECT(pos.x - total_length / 2 + health_bar_length / 2, pos.y, health_bar_length, width, color.r, color.g, color.b, color.a)
		-- armor
		GRAPHICS.DRAW_RECT(pos.x, pos.y + 1.5 * width, total_length, width, 0, 128, 128, 120)
		GRAPHICS.DRAW_RECT(pos.x, pos.y + 1.5 * width, total_length + 0.002, width + 0.002, 0, 0, 0, 120)
		GRAPHICS.DRAW_RECT(pos.x - total_length / 2 + armor_bar_length / 2, pos.y + 1.5 * width, armor_bar_length, width, 0, 255, 255, 255)
	end
end


function interpolate(y0, y1, perc)
	return (1.0 - perc) * y0 + perc * y1
end


function get_blended_color(perc)
	local color = {a = 1.0}
	if perc <= 0.5 then
		color.r = 1.0
		color.g = interpolate(0.0, 1.0, perc / 0.5)
		color.b = 0.0
	else
		color.r = interpolate(1.0, 0, (perc - 0.5) / 0.5)
		color.g = 1.0
		color.b = 0.0
	end
	return Colour.Integer(color)
end


ATTACH_CAM_TO_ENTITY_WITH_FIXED_DIRECTION = function (--[[Cam (int)]] cam, --[[Entity (int)]] entity, --[[float]] xRot, --[[float]] yRot, --[[float]] zRot, --[[float]] xOffset, --[[float]] yOffset, --[[float]] zOffset, --[[BOOL (bool)]] isRelative)
    native_invoker.begin_call()
    native_invoker.push_arg_int(cam)
    native_invoker.push_arg_int(entity)
    native_invoker.push_arg_float(xRot); native_invoker.push_arg_float(yRot); native_invoker.push_arg_float(zRot)
    native_invoker.push_arg_float(xOffset); native_invoker.push_arg_float(yOffset); native_invoker.push_arg_float(zOffset)
    native_invoker.push_arg_bool(isRelative)
    native_invoker.end_call("202A5ED9CE01D6E7")
end


function toggle_off_radar(bool)
	if bool then
		write_global.int(2689156 + ( (PLAYER.PLAYER_ID() * 453) + 1) + 209, 1)
		write_global.int(2703656 + 70, NETWORK.GET_NETWORK_TIME() + 1)
	else
		write_global.int(2689156 + ( (PLAYER.PLAYER_ID() * 453) + 1) + 209, 0)
	end
end
