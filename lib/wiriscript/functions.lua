--[[
--------------------------------
THIS FILE IS PART OF WIRISCRIPT
         Nowiry#2663
--------------------------------
]]



util.require_natives(1640181023)
if not filesystem.exists(filesystem.scripts_dir() .. "lib/natives-1640181023.lua") then
	error("required file not found: lib/natives-1640181023.lua")
end

wait = util.yield
cTime = util.current_time_millis

gConfig = {
	controls = {
		vehicleweapons 		= 86,
		airstrikeaircraft 	= 86
	},
	general = {
		standnotifications 	= false,
		displayhealth 		= true,
		language 			= "english",
		bustedfeatures 		= false,	
		developer			= false, 	-- developer flag (enables/disables some debug features)
		showintro			= true
	},
	ufo = {
		disableboxes 		= false, 	-- determines if boxes are drawn on players to show their position
		targetplayer		= false 	-- wether tractor beam only targets players or not
	},
	vehiclegun = {
		disablepreview 		= false,
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

--------------------------
-- NOTIFICATION
--------------------------


gNotificationTextureDict = "DIA_ZOMBIE1"
gNotificationTextureName = "DIA_ZOMBIE1"

notification = {}
if filesystem.exists(filesystem.resources_dir() .. "WiriTextures.ytd") then
	util.register_file(filesystem.resources_dir() .. "WiriTextures.ytd")
	gNotificationTextureDict = "WiriTextures"
	gNotificationTextureName = "logo"
end

function notification.stand(message)
	message = "[WiriScript] " .. tostring(message):gsub('[~]%w[~]', "") -- removes any text colour (i.e. ~r~, ~b~, ~s~, etc.)
	if not string.match(message, '[%.?]$') then message = message .. '.' end
	util.toast(message)
end

function notification.help(message, color)
	if gConfig.general.standnotifications then
		return notification.stand(message)
	end
	message = tostring(message) or "NULL"
	if not message:match('[%.?]$') then 
		message = message .. '.' 
	end
	HUD._THEFEED_SET_NEXT_POST_BACKGROUND_COLOR(color or HudColour.black)
	util.BEGIN_TEXT_COMMAND_THEFEED_POST("~BLIP_INFO_ICON~ " .. message)
	HUD.END_TEXT_COMMAND_THEFEED_POST_TICKER_WITH_TOKENS(true, true)
end

function notification.normal(message, color)
	if gConfig.general.standnotifications then
		return notification.stand(message)
	end
	if not GRAPHICS.HAS_STREAMED_TEXTURE_DICT_LOADED(gNotificationTextureDict)  then
		GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT(gNotificationTextureDict, 0)
		repeat
			wait()
		until GRAPHICS.HAS_STREAMED_TEXTURE_DICT_LOADED(gNotificationTextureDict)
	end

	message = tostring(message) or "NULL"
	if not message:match('[%.?]$') then -- basically, if the string doesnt have an ending '.' or '?' concats a '.'
		message = message .. '.'
	end
	HUD._THEFEED_SET_NEXT_POST_BACKGROUND_COLOR(color or HudColour.black)
	util.BEGIN_TEXT_COMMAND_THEFEED_POST(message)
	HUD.END_TEXT_COMMAND_THEFEED_POST_MESSAGETEXT(
		gNotificationTextureDict, gNotificationTextureName, true, 4, "WiriScript", "~c~Notification~s~")
	HUD.END_TEXT_COMMAND_THEFEED_POST_TICKER(true, false)
end

--------------------------
-- MENU
--------------------------

features = {}
menunames = {}
-- the heart and soul of translation system
function menuname(section, name)
	features[ section ] = features[ section ] or {}
	features[ section ][ name ] = features[ section ][ name ] or ""
	if gConfig.general.language ~= "english" then
		menunames[ section ] = menunames[ section ] or {}
		menunames[ section ][ name ] = menunames[ section ][ name ] or ""
		if menunames[ section ][ name ] == "" then return name end
		return menunames[ section ][ name ]
	end
	return name
end

function busted(callback, parent, menu_name, ...)
	local name = menu_name -- doing this to call menuname function even if busted features are disabled
	if gConfig.general.bustedfeatures then
		local arg = {...}
		return callback(parent, name, table.unpack(arg) )
	end
end

-- callback is invoked if the developer flag is true
-- developer flag can be set to true from the gConfig file or from the source code
function developer(callback, ...)	
	if gConfig.general.developer then
		local arg = {...}
		return callback( table.unpack(arg) )
	end
end

--------------------------
-- FILE
--------------------------

ini = {}
function ini.save(file, t)
	file = io.open(file, 'w')
	local contents = ""
	for section, s in pairsByKeys(t) do
		contents = contents .. string.format("[%s]\n", section)
		for key, value in pairs(s) do
			if string.len(key) == 1 then 
				key = string.upper(key)
			end
			contents = contents .. ('%s = %s\n'):format(key, tostring(value))
		end
		contents = contents .. '\n'
	end
	file:write(contents)
	file:close()
end

function ini.load(file)
	local instance = {}
	local section
	for line in io.lines(file) do
		local strg = line:match('^%[([^%]]+)%]$')
		if strg then
			section = strg
			instance[ section ] = instance[ section ] or {}
		end
		local key, value = line:match('^([%w_]+)%s*=%s*(.+)$')
		if key and value ~= nil then
			if string.len(key) == 1 then 
				key = string.lower(key)
			end
			if value == "true" then 
				value = true 
			elseif value == "false" then 
				value = false 
			elseif tonumber(value) then
				value = tonumber(value)
			end
			instance[ section ][ key ] = value
		end
	end
	return instance
end

function parseJsonFile(path, without_null)
	local file = io.open(path, 'r')
	local str = file:read('a')
	file:close()
	if not (string.len(str) > 0) then
		return
	end
	local success, result = pcall(json.parse, str, without_null)
	if success then
		return result
	else
		local fileName  = string.match(path, '^.+\\(.+)')
		notification.help("Got unexpected condition in " .. fileName ..
			". If you need support go to WiriScript ~b~FanClub~s~", HudColour.red)
		util.log("[WiriScript] Got unexpected condition in " .. fileName .. ":\n" .. result)
	end
end

--------------------------
-- EFFECT
--------------------------

Effect = {asset = "", name = ""}
Effect.__index = Effect

function Effect.new(asset, name)
	local inst = setmetatable({}, Effect) 
	inst.name = name
	inst.asset = asset
	return inst
end

--------------------------
-- SOUND
--------------------------

Sound = {Id = nil, name = "", reference = ""}
Sound.__index = Sound

function Sound.new(name, reference)
	local inst = setmetatable({}, Sound)
	inst.Id = -1
	inst.name = name
	inst.reference = reference
	return inst
end

function Sound:play()
	if self.Id == -1 then
        self.Id = AUDIO.GET_SOUND_ID()
        AUDIO.PLAY_SOUND_FRONTEND(self.Id, self.name, self.reference, true)
    end
end

function Sound:stop()
	if self.Id ~= -1 then
        AUDIO.STOP_SOUND(self.Id)
        AUDIO.RELEASE_SOUND_ID(self.Id)
        self.Id = -1
    end
end

--------------------------
-- VECTOR
--------------------------

vect = {}
vect.new = function(X, Y, Z)
    return {x = X or 0, y = Y or 0, z = Z or 0}
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

vect.mag2 = function(a)
	return (a.x^2 + a.y^2 + a.z^2)
end

vect.norm = function(a)
    local mag = vect.mag(a)
    return vect.mult(a, 1/mag)
end

vect.mult = function(a,b)
	return vect.new(a.x*b, a.y*b, a.z*b)
end

-- returns the distance between two coords
vect.dist = function(a,b)
    return vect.mag(vect.subtract(a, b))
end

vect.dist2 = function(a,b)
    return vect.mag2(vect.subtract(a, b))
end

vect.tostring = function(a)
    return  string.format("{x: %.3f, y: %.3f, z: %.3f}", a.x, a.y, a.z)
end

function toRotation(v)
	local mag = vect.mag(v)
	local rotation = {
		x =   math.asin(v.z / mag) * (180 / math.pi),
		y =   0.0,
		z = - math.atan(v.x, v.y) * (180 / math.pi)
	}
	return rotation
end

-- https://forum.cfx.re/t/get-position-where-player-is-aiming/1903886/2
function toDirection(rotation) 
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

--------------------------
-- COLOUR
--------------------------

HudColour = 
{
	pureWhite = 0,
	white = 1,
	black = 2,
	grey = 3,
	greyLight = 4,
	greyDrak = 5,
	red = 6,
	redLight = 7,
	redDark = 8,
	blue = 9,
	blueLight = 10,
	blueDark = 11,
	yellow = 12,
	yellowLight = 13,
	yellowDark = 14,
	orange = 15,
	orangeLight = 16,
	orangeDark = 17,
	green = 18,
	greenLight = 19,
	greenDark = 20,
	purple = 21,
	purpleLight = 22,
	purpleDark = 23,
	radarHealth = 25,
	radarArmour = 26,
	friendly = 118,
}

function getHudColour(hudColour)
	local colourR = memory.alloc(8)
	local colourG = memory.alloc(8)
	local colourB = memory.alloc(8)
	local colourA = memory.alloc(8)
	HUD.GET_HUD_COLOUR(hudColour, colourR, colourG, colourB, colourA);
	local colour = Colour.new(
		memory.read_int(colourR),
		memory.read_int(colourG),
		memory.read_int(colourB),
		memory.read_int(colourA)
	)
	memory.free(colourR); memory.free(colourG)
	memory.free(colourB); memory.free(colourA)
	return colour
end

Colour = {}
Colour.new = function(R, G, B, A)
    return {r = R or 0, g = G or 0, b = B or 0, a = A or 0}
end

Colour.mult = function(colour, n)
	local new = {a = colour.a}
	new.r = colour.r * n		
	new.g = colour.g * n
	new.b = colour.b * n
    return new
end

-- needs to be called on tick
-- colour in a  0-255 basis
Colour.rainbow = function(colour)
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
	end
	return colour
end

Colour.normalize = function(colour)
	local new = colour
    return Colour.mult(new, 1/255)
end

Colour.toInt = function(colour)
	local new = {}
	new.r = math.floor(colour.r * 255)
	new.g = math.floor(colour.g * 255)
	new.b = math.floor(colour.b * 255)
	new.a = math.floor(colour.a * 255)
    return new
end

Colour.random = function()
    local new = {}
    new.r = math.random(0,255)
    new.g = math.random(0,255)
    new.b = math.random(0,255)
    new.a = 255
    return new
end

function interpolate(y0, y1, perc)
	return (1 - perc) * y0 + perc * y1
end

function getBlendedColour(perc)
	local color = {a = 1.0}
	if perc <= 0.5 then
		color.r = 1.0
		color.g = interpolate(0.0, 1.0, (perc / 0.5))
		color.b = 0.0
	else
		color.r = interpolate(1.0, 0, ((perc - 0.5) / 0.5))
		color.g = 1.0
		color.b = 0.0
	end
	return Colour.toInt(color)
end

--------------------------
-- INSTRUCTIONAL
--------------------------

instructional = {} -- namespace
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

-- name can be a label or any other string
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
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_BOOL(false)
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(index)
    GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

	self.position = self.position + 1
end

function instructional.add_control (index, name)
	local button = PAD.GET_CONTROL_INSTRUCTIONAL_BUTTON(2, index, true)
    instructional:add_data_slot(index, name, button)
end

function instructional.add_control_group (index, name)
	local button = PAD.GET_CONTROL_GROUP_INSTRUCTIONAL_BUTTON(2, index, true)
    instructional:add_data_slot(index, name, button)
end

function instructional:set_background_colour (r, g, b, a)
	GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(self.scaleform, "SET_BACKGROUND_COLOUR")
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

--------------------------
-- RALATIONSHIP
--------------------------

local function addRelationshipGroup(name)
	local ptr = memory.alloc_int()
	PED.ADD_RELATIONSHIP_GROUP(name, ptr)
	local rel = memory.read_int(ptr)
	memory.free(ptr)
	return rel
end

relationship = {}
function relationship:hostile(ped)
	if not PED._DOES_RELATIONSHIP_GROUP_EXIST(self.hostile_group) then
		self.hostile_group = addRelationshipGroup("hostile_group")
		PED.SET_RELATIONSHIP_BETWEEN_GROUPS(0, self.hostile_group, self.hostile_group)
	end
	PED.SET_PED_RELATIONSHIP_GROUP_HASH(ped, self.hostile_group)
end

function relationship:friendly(ped)
	if not PED._DOES_RELATIONSHIP_GROUP_EXIST(self.friendly_group) then
		self.friendly_group = addRelationshipGroup("friendly_group")
		PED.SET_RELATIONSHIP_BETWEEN_GROUPS(0, self.friendly_group, self.friendly_group)
	end
	PED.SET_PED_RELATIONSHIP_GROUP_HASH(ped, self.friendly_group)
end

--------------------------
-- ENTITIES
--------------------------

function setEntityFaceEntity(ent1, ent2, usePitch)
	local a = ENTITY.GET_ENTITY_COORDS(ent1, false)
	local b = ENTITY.GET_ENTITY_COORDS(ent2, false)
	local s = vect.subtract(b,a)
	local r = toRotation(s)
	if not usePitch then
		ENTITY.SET_ENTITY_HEADING(ent1, r.z)
	else
		ENTITY.SET_ENTITY_ROTATION(ent1, r.x, r.y, r.z)
	end
end

function addBlipForEntity(entity, blipSprite, colour)
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

function requestControl(entity)
	if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) then
		local netId = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(entity)
		NETWORK.SET_NETWORK_ID_CAN_MIGRATE(netId, true)
		NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
	end
	return NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity)
end

function requestControlLoop(entity)
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
function getNearbyPeds(pId, radius) 
	local peds = {}
	local playerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pId)
	local pos = ENTITY.GET_ENTITY_COORDS(playerPed)
	for k, ped in pairs(entities.get_all_peds_as_handles()) do
		if ped ~= playerPed and not PED.IS_PED_FATALLY_INJURED(ped) then
			local ped_pos = ENTITY.GET_ENTITY_COORDS(ped)
			if vect.dist(pos, ped_pos) <= radius then table.insert(peds, ped) end
		end
	end
	return peds
end

-- returns a list of nearby vehicles given player Id
function getNearbyVehicles(pId, radius) 
	local vehicles = {}
	local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pId)
	local pos = ENTITY.GET_ENTITY_COORDS(p)
	local v = PED.GET_VEHICLE_PED_IS_IN(p, false)
	for _, vehicle in ipairs(entities.get_all_vehicles_as_handles()) do 
		local veh_pos = ENTITY.GET_ENTITY_COORDS(vehicle)
		if vehicle ~= v and vect.dist(pos, veh_pos) <= radius then table.insert(vehicles, vehicle) end
	end
	return vehicles
end

-- returns a list of nearby peds and vehicles given player Id
function getNearbyEntities(pId, radius) 
	local peds = getNearbyPeds(pId, radius)
	local vehicles = getNearbyVehicles(pId, radius)
	local entities = peds
	for i = 1, #vehicles do table.insert(entities, vehicles[i]) end
	return entities
end

function deleteNearbyVehicles(pos, model, radius)
	local hash = util.joaat(model)
	local vehicles = entities.get_all_vehicles_as_handles()
	for _, vehicle in ipairs(vehicles) do
		if ENTITY.DOES_ENTITY_EXIST(vehicle) and ENTITY.GET_ENTITY_MODEL(vehicle) == hash then
			local vpos = ENTITY.GET_ENTITY_COORDS(vehicle, false)
			local ped = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1)
			if not PED.IS_PED_A_PLAYER(ped) and vect.dist(pos, vpos) < radius then
				requestControlLoop(vehicle)
				requestControlLoop(ped)
				ENTITY.SET_ENTITY_AS_MISSION_ENTITY(vehicle, true, true)
				ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ped, true, true)
				entities.delete_by_handle(vehicle)
				entities.delete_by_handle(ped)
			end
		end
	end
end

-- deletes all non player peds with the given model name
function deletePedsWithModelHash(modelHash)
	if not STREAMING.IS_MODEL_VALID(modelHash) then
		error("got an invalid model hash")
	end
	for _, ped in ipairs(entities.get_all_peds_as_handles()) do
		if ENTITY.GET_ENTITY_MODEL(ped) == modelHash and not PED.IS_PED_A_PLAYER(ped) then
			requestControlLoop(ped)
			entities.delete_by_handle(ped)
		end
	end
end

function drawLockonSprite(entity, hudColour)
	if GRAPHICS.HAS_STREAMED_TEXTURE_DICT_LOADED("helicopterhud") then
		GRAPHICS.SET_SCRIPT_GFX_DRAW_ORDER(1)
		local entCoord = ENTITY.GET_ENTITY_COORDS(entity)
		GRAPHICS.SET_DRAW_ORIGIN(entCoord.x, entCoord.y, entCoord.z, 0);
		local camCoord = CAM.GET_FINAL_RENDERED_CAM_COORD()
		local distance = vect.dist(entCoord, camCoord)
		local width =  (0.5 / distance)
		if width < 0.015 then
			width = 0.015
		end
		local height = width * GRAPHICS._GET_ASPECT_RATIO(false)
		local colour = getHudColour(hudColour)
		GRAPHICS.DRAW_SPRITE("helicopterhud", "hud_outline", 0.0, 0.0, width, height, 0.0, colour.r, colour.g, colour.b, colour.a, false);	
		GRAPHICS.CLEAR_DRAW_ORIGIN();
	else
		GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT("helicopterhud", 0)
	end
end

function drawBoxEsp(entity, colour)
	colour = colour or Colour.new(255, 0, 0, 255)
	local minimum = v3.new()
	local maximum = v3.new()
	if ENTITY.DOES_ENTITY_EXIST(entity) then
		MISC.GET_MODEL_DIMENSIONS(ENTITY.GET_ENTITY_MODEL(entity), minimum, maximum)
		local width   = 2 * v3.getX(maximum)
		local length  = 2 * v3.getY(maximum)
		local depth   = 2 * v3.getZ(maximum)

		local offset1 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, -width / 2,  length / 2,  depth / 2)
		local offset4 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity,  width / 2,  length / 2,  depth / 2)
		local offset5 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, -width / 2,  length / 2, -depth / 2)
		local offset7 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity,  width / 2,  length / 2, -depth / 2)
		local offset2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, -width / 2, -length / 2,  depth / 2) 
		local offset3 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity,  width / 2, -length / 2,  depth / 2)
		local offset6 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, -width / 2, -length / 2, -depth / 2)
		local offset8 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity,  width / 2, -length / 2, -depth / 2)

		GRAPHICS.DRAW_LINE(offset1.x, offset1.y, offset1.z, offset4.x, offset4.y, offset4.z, colour.r, colour.g, colour.b, 255)
		GRAPHICS.DRAW_LINE(offset1.x, offset1.y, offset1.z, offset2.x, offset2.y, offset2.z, colour.r, colour.g, colour.b, 255)
		GRAPHICS.DRAW_LINE(offset1.x, offset1.y, offset1.z, offset5.x, offset5.y, offset5.z, colour.r, colour.g, colour.b, 255)
		GRAPHICS.DRAW_LINE(offset2.x, offset2.y, offset2.z, offset3.x, offset3.y, offset3.z, colour.r, colour.g, colour.b, 255)
		GRAPHICS.DRAW_LINE(offset3.x, offset3.y, offset3.z, offset8.x, offset8.y, offset8.z, colour.r, colour.g, colour.b, 255)
		GRAPHICS.DRAW_LINE(offset4.x, offset4.y, offset4.z, offset7.x, offset7.y, offset7.z, colour.r, colour.g, colour.b, 255)
		GRAPHICS.DRAW_LINE(offset4.x, offset4.y, offset4.z, offset3.x, offset3.y, offset3.z, colour.r, colour.g, colour.b, 255)
		GRAPHICS.DRAW_LINE(offset5.x, offset5.y, offset5.z, offset7.x, offset7.y, offset7.z, colour.r, colour.g, colour.b, 255)
		GRAPHICS.DRAW_LINE(offset6.x, offset6.y, offset6.z, offset2.x, offset2.y, offset2.z, colour.r, colour.g, colour.b, 255)
		GRAPHICS.DRAW_LINE(offset6.x, offset6.y, offset6.z, offset8.x, offset8.y, offset8.z, colour.r, colour.g, colour.b, 255)
		GRAPHICS.DRAW_LINE(offset5.x, offset5.y, offset5.z, offset6.x, offset6.y, offset6.z, colour.r, colour.g, colour.b, 255)
		GRAPHICS.DRAW_LINE(offset7.x, offset7.y, offset7.z, offset8.x, offset8.y, offset8.z, colour.r, colour.g, colour.b, 255)
	end
	v3.free(minimum)
	v3.free(maximum)
end


function isModelAnAircraft(model)
	return VEHICLE.IS_THIS_MODEL_A_HELI(model) or VEHICLE.IS_THIS_MODEL_A_PLANE(model)
end

function isPedInAnyAircraft(ped)
	return PED.IS_PED_IN_ANY_PLANE(ped) or PED.IS_PED_IN_ANY_HELI(ped)
end

function getOffsetFromEntityGivenDistance(entity, distance)
	local pos = ENTITY.GET_ENTITY_COORDS(entity, 0)
	local theta = (math.random() + math.random(0, 1)) * math.pi --returns a random angle between 0 and 2pi (exclusive)
	local coords = vect.new(
		pos.x + distance * math.cos(theta),
		pos.y + distance * math.sin(theta),
		pos.z
	)
	return coords
end

--------------------------
-- PLAYER
--------------------------

function isPlayerFriend(pId)
	local ptr = memory.alloc(104)
	NETWORK.NETWORK_HANDLE_FROM_PLAYER(pId, ptr, 13)
	return ( NETWORK.NETWORK_IS_HANDLE_VALID(ptr, 13) and NETWORK.NETWORK_IS_FRIEND(ptr) )
end

function getVehiclePlayerIsIn(pId)
	local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pId)
	local vehicle = PED.GET_VEHICLE_PED_IS_IN(p, false)
	return vehicle
end

function getUserVehicleModel(last_vehicle)
	local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), last_vehicle)
	if vehicle ~= NULL then
		return ENTITY.GET_ENTITY_MODEL(vehicle)
	end
	return NULL
end

function getUserVehicleName()
	local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), true)
	if vehicle ~= NULL then
		local model = ENTITY.GET_ENTITY_MODEL(vehicle)
		return HUD._GET_LABEL_TEXT(VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(model)), model
	else
		return "???"
	end
end

getEntityPlayerIsAimingAt = function(player)
	local ent = NULL
	if PLAYER.IS_PLAYER_FREE_AIMING(player) then
		local ptr = memory.alloc_int()		
		if PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(player, ptr) then
			ent = memory.read_int(ptr)
		end
		memory.free(ptr)
		if ENTITY.IS_ENTITY_A_PED(ent) and PED.IS_PED_IN_ANY_VEHICLE(ent) then
			local vehicle = PED.GET_VEHICLE_PED_IS_IN(ent, false)
			ent = vehicle
		end
	end
	return ent
end

function getPlayerClan(player)
	local clan = {icon = 0, tag = "", name = "", motto = "", alt_badge = "Off", rank = "Rank4"}
	local network_handle = memory.alloc(104)
    local clan_desc = memory.alloc(280)
    
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
		clan.alt_badge = memory.read_byte(clan_desc + 0xA0) == 1 and "On" or "Off"
	end
	
	memory.free(network_handle)
	memory.free(clan_desc)
	return clan
end

--------------------------
-- CAM
--------------------------

function getOffsetFromCam(dist)
	local rot = CAM.GET_FINAL_RENDERED_CAM_ROT(2)
	local pos = CAM.GET_FINAL_RENDERED_CAM_COORD()
	local dir = toDirection(rot)
	local offset = {
		x = pos.x + dir.x * dist,
		y = pos.y + dir.y * dist,
		z = pos.z + dir.z * dist 
	}
	return offset
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

--------------------------
-- RAYCAST
--------------------------

TraceFlag = 
{
	everything = -1,
	none = 0,
	world = 1,
	vehicles = 2,
	pedsSimpleCollision = 4,
	peds = 8,
	objects = 16,
	water = 32,
	foliage = 256,
}

function getRaycastResult(dist, flag)
	local result = {}
	flag = flag or TraceFlag.everything
	local didHit 		= memory.alloc(8)
	local endCoords 	= v3.new()
	local surfaceNormal = v3.new()
	local hitEntity 	= memory.alloc_int()
	local origin 		= CAM.GET_FINAL_RENDERED_CAM_COORD()
	local destination 	= getOffsetFromCam(dist)

	SHAPETEST.GET_SHAPE_TEST_RESULT(
		SHAPETEST.START_EXPENSIVE_SYNCHRONOUS_SHAPE_TEST_LOS_PROBE(
			origin.x, 
			origin.y, 
			origin.z, 
			destination.x,
			destination.y,
			destination.z,
			flag,
			PLAYER.PLAYER_PED_ID(), -- the shape test ignores the local ped 
			1
		), didHit, endCoords, surfaceNormal, hitEntity
	)
	result.didHit 			= toBool(memory.read_byte(didHit))
	result.endCoords 		= vect.new(v3.get(endCoords))
	result.surfaceNormal 	= vect.new(v3.get(surfaceNormal))
	result.hitEntity 		= memory.read_int(hitEntity)

	memory.free(didHit)
	v3.free(endCoords)
	v3.free(surfaceNormal)
	memory.free(hitEntity)
	return result
end

--------------------------
-- STREAMING
--------------------------

-- 1) requests all the given models
-- 2) waits till all of them have been loaded
function requestModels(...)
	local arg = {...}
	for _, model in ipairs(arg) do
		if not STREAMING.IS_MODEL_VALID(model) then
			error("tried to request an invalid model")
		end
		STREAMING.REQUEST_MODEL(model)
		while not STREAMING.HAS_MODEL_LOADED(model) do
			wait()
		end
	end
end

function requestPtfxAsset(asset)
	STREAMING.REQUEST_NAMED_PTFX_ASSET(asset)
	while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(asset) do
		wait()
	end
end

function requestWeaponAsset(hash)
	WEAPON.REQUEST_WEAPON_ASSET(hash, 31, 0)
	while not WEAPON.HAS_WEAPON_ASSET_LOADED(hash) do
		wait()
	end
	WEAPON.GIVE_WEAPON_TO_PED(PLAYER.PLAYER_PED_ID(), hash, 120, 1, 1)
	WEAPON.SET_CURRENT_PED_WEAPON(PLAYER.PLAYER_PED_ID(), hash, 1)
end

--------------------------
-- MEMORY
--------------------------

-- reads a long from the base pointer
-- use this one if you're using a base pointer from a pattern scan
function addressFromPointerChain(basePtr, offsets)
	local addr = basePtr
	for k = 1, (#offsets - 1) do
		addr = memory.read_long(addr + offsets[k])
		if addr == NULL then
			return NULL
		end
	end
	addr = addr + offsets[#offsets]
	return addr
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
	end,
	string = function(global)
		return memory.read_string(memory.script_global(global))
	end
}

--------------------------
-- TABLE
--------------------------

-- returns a random value from the given table
function getRandomValue(t)
	if rawget(t, 1) ~= nil then 
		return t[ math.random(1, #t) ] 
	end
	local list = {}
	for k, value in pairs(t) do 
		table.insert(list, value) 
	end
	return list[math.random(1, #list)]
end

function equals(a,b)
	if a == b then return true end
	local type1 = type(a)
    local type2 = type(b)
    if type1 ~= type2 then 
		return false 
	end
	if type1 ~= "table" then 
		return false 
	end
	for k, v in pairs(a) do
		if b[ k ] == nil or not equals(v, b[ k ]) then
			return false
		end
	end
	return true
end

function pairsByKeys(t, f)
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

function getKey(t, value)
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

-- swaps the values of two tables
function swapValues(a,b)
	local res = {}
	for k, v in pairs(a) do
		if type(v) == "table" and type(b[ k ]) == "table" then
			res[ k ] = swapValues(v, b[ k ])
		else
			res[ k ] = b[ k ]  
		end
	end
	return res
end

-- 1) checks if the given value exists in the given table
-- 2) if it doesn't, it inserts it
function insertOnce(t, value)
	if not includes(t, value) then
		table.insert(t, value)
		return true
	end
	return false
end

function doesKeyExist(table, key)
	for k, v in pairs(table) do
		if k == key then return true end
	end
	return false
end

function unpack(self)
	-- when it's an array
	if rawget(self, 1) ~= nil then
		return table.unpack(self)
	else
		-- when it's an object
		local l = {}
		for k, v in pairs(self) do
			table.insert(l, v)
		end
		return table.unpack(l)
	end
end


--------------------------
-- MISC
--------------------------

-- increases (or decreases) the value until reaching the limit (if limit ~= nil).
-- 1) to increase the value, delta > 0
-- 2) to decrease the value, delta < 0 or limit < current value
-- 3) requires on tick call
function increment(current, delta, limit)
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

function drawDebugText(...)
	local arg = {...}	
	local strg = ""
	for _, w in ipairs(arg) do
		strg = strg .. tostring(w) .. '\n'
	end
	local colour = Colour.new(1.0, 0, 0, 1.0)
	directx.draw_text(0.05, 0.05, strg, ALIGN_TOP_LEFT, 1.0, colour, false)
end

function toBool(value)
	return value ~= 0
end

function getWaypointCoords()
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

function getGroundZ(pos)
	local ptr = memory.alloc()
	MISC.GET_GROUND_Z_FOR_3D_COORD(pos.x, pos.y, pos.z, ptr, false)
	local groundz = memory.read_float(ptr); memory.free(ptr)
	return groundz
end

function displayOnScreenKeyword(windowName, maxInput, defaultText)
	MISC.DISPLAY_ONSCREEN_KEYBOARD(0, windowName, "", defaultText, "", "", "", maxInput);
	while MISC.UPDATE_ONSCREEN_KEYBOARD() == 0 do
		wait()
	end
	if not MISC.GET_ONSCREEN_KEYBOARD_RESULT() then
		return ""
	end
	return MISC.GET_ONSCREEN_KEYBOARD_RESULT()
end

function drawString(s, x, y, scale, font)
	HUD.BEGIN_TEXT_COMMAND_DISPLAY_TEXT("STRING")
	HUD.SET_TEXT_FONT(font or 0)
	HUD.SET_TEXT_SCALE(scale, scale)
	HUD.SET_TEXT_DROP_SHADOW()
	HUD.SET_TEXT_WRAP(0.0, 1.0)
	HUD.SET_TEXT_DROPSHADOW(1, 0, 0, 0, 0)
	HUD.SET_TEXT_OUTLINE()
	HUD.SET_TEXT_EDGE(1, 0, 0, 0, 0)
	HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(s)
	HUD.END_TEXT_COMMAND_DISPLAY_TEXT(x, y)
end

function capitalize(txt)
	return tostring(txt):gsub('^%l', string.upper)
end

function capEachWord(txt)
	txt = string.lower(txt)
	return txt:gsub('(%l)(%w+)', function(a,b) return string.upper(a) .. b end)
end

function setOutOfRadar(bool)
	if bool then
		write_global.int(2689156 + ((PLAYER.PLAYER_ID() * 453) + 1) + 209, 1)
		write_global.int(2703656 + 70, NETWORK.GET_NETWORK_TIME() + 1)
	else
		write_global.int(2689156 + ((PLAYER.PLAYER_ID() * 453) + 1) + 209, 0)
	end
end

disablePhone = function ()
    write_global.int(19937, 1)
end
