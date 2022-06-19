--[[
--------------------------------
THIS FILE IS PART OF WIRISCRIPT
         Nowiry#2663
--------------------------------
]]

util.require_natives(1651208000)

if not filesystem.exists(filesystem.scripts_dir() .. "lib/natives-1640181023.lua") then
	error("required file not found: lib/natives-1640181023.lua")
end

json = require "pretty.json"
local self = {}
self.version = 19

gConfig = {
	controls = {
		vehicleweapons 		= 86,
		airstrikeaircraft 	= 86
	},
	general = {
		standnotifications 	= false,
		displayhealth 		= true,
		language 		= "english",
		developer		= false, 	-- developer flag (enables/disables some debug features)
		showintro		= true
	},
	ufo = {
		disableboxes 		= false, 	-- determines if boxes are drawn on players to show their position
		targetplayer		= false 	-- wether tractor beam only targets players or not
	},
	vehiclegun = {
		disablepreview 		= false,
	},
	healthtxtpos = {
		x = 0.03,
		y = 0.05
	},
}

---@alias hudColour_t integer

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

--------------------------
-- NOTIFICATION
--------------------------

---@class Notification
Notification =
{
	txdDict = "DIA_ZOMBIE1",
	txdName = "DIA_ZOMBIE1",
	title = "WiriScript",
	subtitle = "~c~Notification~s~",
	defaultColour = HudColour.black
}
Notification.__index = Notification
Notification.__close = function (self)
	GRAPHICS.SET_STREAMED_TEXTURE_DICT_AS_NO_LONGER_NEEDED(self.txdDict)
end

---@param msg string
function Notification.stand(msg)
	msg = "[WiriScript] " .. tostring(msg):gsub('[~]%w[~]', "") -- removes any text colour (i.e. ~r~, ~b~, ~s~, etc.)
	util.toast(msg)
end

---@param msg string
---@param colour? hudColour_t
function Notification:help(msg, colour)
	if gConfig.general.standnotifications then
		return self.stand(msg)
	end
	msg = tostring(msg) or "NULL"
	HUD._THEFEED_SET_NEXT_POST_BACKGROUND_COLOR(colour or self.defaultColour)
	util.BEGIN_TEXT_COMMAND_THEFEED_POST("~BLIP_INFO_ICON~ " .. msg)
	HUD.END_TEXT_COMMAND_THEFEED_POST_TICKER_WITH_TOKENS(true, true)
end

---@param msg string
---@param colour? hudColour_t
function Notification:normal(msg, colour)
	if gConfig.general.standnotifications then
		return Notification.stand(msg)
	end
	if not self:hasTxdDictLoaded() then self:requestTxdDict() end
	msg = tostring(msg) or "NULL"
	HUD._THEFEED_SET_NEXT_POST_BACKGROUND_COLOR(colour or self.defaultColour)
	util.BEGIN_TEXT_COMMAND_THEFEED_POST(msg)
	HUD.END_TEXT_COMMAND_THEFEED_POST_MESSAGETEXT(self.txdDict, self.txdName, true, 4, self.title, self.subtitle)
	HUD.END_TEXT_COMMAND_THEFEED_POST_TICKER(false, false)
end

function Notification:requestTxdDict()
	GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT(self.txdDict, 0)
	while not GRAPHICS.HAS_STREAMED_TEXTURE_DICT_LOADED(self.txdDict) do util.yield() end
end

---@return boolean
function Notification:hasTxdDictLoaded()
	return GRAPHICS.HAS_STREAMED_TEXTURE_DICT_LOADED(self.txdDict)
end

---@param title? string
---@param subtitle? string
---@return Notification
function Notification.new(title, subtitle)
	local self = setmetatable({}, Notification)
	self.title = title
	self.subtitle = subtitle
	return self
end

--------------------------
-- MENU
--------------------------

Features = {}
MenuNames = setmetatable({}, {__index = Features})

---@param section string
---@param name string
---@return string
function get_menu_name(section, name)
	Features[section] = Features[section] or {}
	Features[section][name] = Features[section][name] or ""
	if gConfig.general.language == "english" then
		return name
	end
	MenuNames[section] = MenuNames[section] or Features[section]
	if not MenuNames[section][name] then
		MenuNames[section][name] = ""
		return name
	end
	return MenuNames[section][name] == "" and name or MenuNames[section][name]
end

--------------------------
-- FILE
--------------------------

Ini = {}

---Saves a table with key-value pairs in an ini format file.
---@param fileName string
---@param t table
function Ini.save(fileName, t)
	local file <close> = assert(io.open(fileName, "w"), fileName .. " does not exist")
	local s = {}
	for section, values in pairs(t) do
		local l = {}
		table.insert(l, string.format("[%s]", section))
		for key, v in pairs(values) do
			table.insert(l, string.format("%s=%s", key, v))
		end
		table.insert(s, table.concat(l, '\n') .. '\n')
	end
	file:write(table.concat(s, '\n'))
end

---@param value string
---@return any
function Ini.match_value_type(value)
	if type(value) == "string" then
		if tonumber(value) then
			return tonumber(value)
		end
		local toBool = {["true"] = true, ["false"] = false}
		if toBool[value] ~= nil then
			return toBool[value]
		end
		return value
	else
		error("expected value to be a string, got " .. type(value))
	end
end

---Parses a table from an ini format file.
---@param fileName any
---@return table
function Ini.load(fileName)
	local t = {}
	local cSection = ""
	for line in io.lines(fileName) do
		local section = string.match(line, '^%[' .. '([^%]]+)' .. '%]$')
		if section then
			cSection = section
			t[cSection] = t[cSection] or {}
		elseif t[cSection] and #line > 0 then
			local key, value = string.match(line, '^([%w_]+)%s*=%s*(.+)$')
			if key and value then
				t[cSection][key] = Ini.match_value_type(value)
			end
		end
	end
	return t
end


local parseJson = json.parse

---@param filePath string
---@param withoutNull? boolean
---@return boolean
---@return string|table
json.parse = function (filePath, withoutNull)
	local file <close> = assert(io.open(filePath, "r"), filePath .. " does not exist")
	local content = file:read("a")
	local fileName = string.match(filePath, '^.+\\(.+)')
	if #content == 0 then
		return false,  fileName .. " is empty"
	end
	return pcall(parseJson, content, withoutNull)
end

--------------------------
-- EFFECT
--------------------------

---@class Effect
Effect = {asset = "", name = "", scale = 1.0}
Effect.__index = Effect

---@param asset string
---@param name string
---@param scale? number
---@return Effect
function Effect.new(asset, name, scale)
	local inst = setmetatable({}, Effect)
	inst.name = name
	inst.asset = asset
	inst.scale = scale
	return inst
end

--------------------------
-- SOUND
--------------------------

---@class Sound
Sound = {Id = -1, name = "", reference = ""}
Sound.__index = Sound

---@param name string
---@param reference string
---@return Sound
function Sound.new(name, reference)
	local inst = setmetatable({}, Sound)
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

---@class Vector3
---@field x number
---@field y number
---@field z number

--------------------------
-- COLOUR
--------------------------

---@param hudColour hudColour_t
---@return table
function get_hud_colour(hudColour)
	local colourR = memory.alloc(1)
	local colourG = memory.alloc(1)
	local colourB = memory.alloc(1)
	local colourA = memory.alloc(1)
	HUD.GET_HUD_COLOUR(hudColour, colourR, colourG, colourB, colourA);
	local colour = Colour.new(
		memory.read_int(colourR),
		memory.read_int(colourG),
		memory.read_int(colourB),
		memory.read_int(colourA)
	)
	return colour
end


Colour = {}
Colour.new = function(R, G, B, A)
    return {r = R or 0, g = G or 0, b = B or 0, a = A or 0}
end

---Requires on tick call
---@param colour any
---@return any
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

Colour.random = function()
    local new = {}
    new.r = math.random(0, 255)
    new.g = math.random(0, 255)
    new.b = math.random(0, 255)
    new.a = 255
    return new
end

---@param colour table
---@return table
Colour.toInt = function(colour)
	local new = {}
	new.r = math.floor(colour.r * 255)
	new.g = math.floor(colour.g * 255)
	new.b = math.floor(colour.b * 255)
	new.a = math.floor(colour.a * 255)
    return new
end

---@param colour table
---@return number
---@return number
---@return number
Colour.get = function (colour)
	return colour.r, colour.g, colour.b
end

---@param y0 number
---@param y1 number
---@param perc number
---@return number
function interpolate(y0, y1, perc)
	if perc > 1.0 then perc = 1.0 end
	return (1 - perc) * y0 + perc * y1
end

---@param perc number
---@return table
function get_blended_colour(perc)
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

Instructional = {}

---@return boolean
function Instructional:begin ()
	if GRAPHICS.HAS_SCALEFORM_MOVIE_LOADED(self.scaleform) then
		GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(self.scaleform, "CLEAR_ALL")
		GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

    	GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(self.scaleform, "TOGGLE_MOUSE_BUTTONS")
		GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_BOOL(true)
		GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

		self.position = 0
        return true
	else
		self.scaleform = GRAPHICS.REQUEST_SCALEFORM_MOVIE("instructional_buttons")
		return false
    end
end

---@param index integer
---@param name string
---@param button string
function Instructional:add_data_slot(index, name, button)
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

---@param index integer
---@param name string
function Instructional.add_control(index, name)
	local button = PAD.GET_CONTROL_INSTRUCTIONAL_BUTTON(2, index, true)
    Instructional:add_data_slot(index, name, button)
end

---@param index integer
---@param name string
function Instructional.add_control_group (index, name)
	local button = PAD.GET_CONTROL_GROUP_INSTRUCTIONAL_BUTTON(2, index, true)
    Instructional:add_data_slot(index, name, button)
end

---@param r integer
---@param g integer
---@param b integer
---@param a integer
function Instructional:set_background_colour(r, g, b, a)
	GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(self.scaleform, "SET_BACKGROUND_COLOUR")
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(r)
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(g)
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(b)
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(a)
	GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
end

function Instructional:draw ()
	GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(self.scaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
	GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

    GRAPHICS.DRAW_SCALEFORM_MOVIE_FULLSCREEN(self.scaleform, 255, 255, 255, 255, 0)
	self.position = 0
end

--------------------------
-- TIMER
--------------------------

---@class Timer
---@field reset function
---@field elapsed function

---@return Timer
function newTimer()
	local self = {start = util.current_time_millis()}
	local function reset()
		self.start = util.current_time_millis()
	end
	local function elapsed()
		return util.current_time_millis() - self.start
	end
	return
	{
		reset = reset,
		elapsed = elapsed
	}
end

--------------------------
-- RALATIONSHIP
--------------------------

---@param name string
---@return integer
local function add_relationship_group(name)
	local ptr = memory.alloc_int()
	PED.ADD_RELATIONSHIP_GROUP(name, ptr)
	return memory.read_int(ptr)
end

relationship = {}
function relationship:hostile(ped)
	if not PED._DOES_RELATIONSHIP_GROUP_EXIST(self.hostile_group) then
		self.hostile_group = add_relationship_group("hostile_group")
	end
	PED.SET_PED_RELATIONSHIP_GROUP_HASH(ped, self.hostile_group)
	PED.SET_RELATIONSHIP_BETWEEN_GROUPS(0, self.hostile_group, self.hostile_group)
end

function relationship:friendly(ped)
	if not PED._DOES_RELATIONSHIP_GROUP_EXIST(self.friendly_group) then
		self.friendly_group = add_relationship_group("friendly_group")
	end
	PED.SET_PED_RELATIONSHIP_GROUP_HASH(ped, self.friendly_group)
	PED.SET_RELATIONSHIP_BETWEEN_GROUPS(0, self.friendly_group, self.friendly_group)
end

--------------------------
-- ENTITIES
--------------------------


function setBit(bitfield, bitNum)
	return (bitfield | (1 << bitNum))
end

function clearBit(bitfield, bitNum)
	return (bitfield & ~(1 << bitNum))
end

---@param entity integer
---@param value boolean
function set_explosion_proof(entity, value)
	local pEntity = entities.handle_to_pointer(entity)
	if pEntity == 0 then return end
	local damageBits = memory.read_uint(pEntity + 0x0188)
	damageBits = value and setBit(damageBits, 11) or clearBit(damageBits, 11)
	memory.write_uint(pEntity + 0x0188, damageBits)
end


---@param entity integer
---@param target integer
---@param usePitch? boolean
function set_entity_face_entity(entity, target, usePitch)
	local pos1 = ENTITY.GET_ENTITY_COORDS(entity, false)
	local pos2 = ENTITY.GET_ENTITY_COORDS(target, false)
	local rel = v3.new(pos2)
	rel:sub(pos1)
	local rot = rel:toRot()
	if not usePitch then
		ENTITY.SET_ENTITY_HEADING(entity, rot.z)
	else
		ENTITY.SET_ENTITY_ROTATION(entity, rot.x, rot.y, rot.z)
	end
end

---@param entity integer
---@param blipSprite integer
---@param colour integer
---@return integer
function add_blip_for_entity(entity, blipSprite, colour)
	local blip = HUD.ADD_BLIP_FOR_ENTITY(entity)
	HUD.SET_BLIP_SPRITE(blip, blipSprite)
	HUD.SET_BLIP_COLOUR(blip, colour)
	HUD.SHOW_HEIGHT_ON_BLIP(blip, false)
	util.create_tick_handler(function ()
		if ENTITY.DOES_ENTITY_EXIST(entity) and not ENTITY.IS_ENTITY_DEAD(entity) then
			local heading = ENTITY.GET_ENTITY_HEADING(entity)
        	HUD.SET_BLIP_ROTATION(blip, round(heading))
		elseif not HUD.DOES_BLIP_EXIST(blip) then
			return false
		else
			util.remove_blip(blip)
			return false
		end
	end)
	return blip
end

---@param blip integer
---@param name string
---@param isLabel? boolean
function set_blip_name(blip, name, isLabel)
	HUD.BEGIN_TEXT_COMMAND_SET_BLIP_NAME("STRING")
	if not isLabel then
		HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(name)
	else
		HUD.ADD_TEXT_COMPONENT_SUBSTRING_TEXT_LABEL(name)
	end
	HUD.END_TEXT_COMMAND_SET_BLIP_NAME(blip)
end

---@param entity integer
---@return boolean
function request_control_once(entity)
	if not NETWORK.NETWORK_IS_IN_SESSION() then
		return true
	end
	local netId = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(entity)
	NETWORK.SET_NETWORK_ID_CAN_MIGRATE(netId, true)
	return NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
end

---@param entity integer
---@param timeOut? integer #time in `ms` trying to get control
---@return boolean
function request_control(entity, timeOut)
	if not ENTITY.DOES_ENTITY_EXIST(entity) then
		return false
	end
	timeOut = timeOut or 500
	local start = newTimer()
	while not request_control_once(entity) and start.elapsed() < timeOut do
		util.yield()
	end
	return start.elapsed() < timeOut
end

---@param ped integer
---@param maxPeds? integer
---@param ignore? integer
---@return integer[]
function get_ped_nearby_peds(ped, maxPeds, ignore)
	maxPeds = maxPeds or 16
	local pEntityList = memory.alloc((maxPeds + 1) * 8)
	memory.write_int(pEntityList, maxPeds)
	local pedsList = {}
	for i = 1, PED.GET_PED_NEARBY_PEDS(ped, pEntityList, ignore or -1), 1 do
		pedsList[i] = memory.read_int(pEntityList + i*8)
	end
	return pedsList
end

---@param ped integer
---@param maxVehicles? integer
---@return integer[]
function get_ped_nearby_vehicles(ped, maxVehicles)
	maxVehicles = maxVehicles or 16
	local pVehicleList = memory.alloc((maxVehicles + 1) * 8)
	memory.write_int(pVehicleList, maxVehicles)
	local vehiclesList = {}
	for i = 1, PED.GET_PED_NEARBY_VEHICLES(ped, pVehicleList) do
		vehiclesList[i] = memory.read_int(pVehicleList + i*8)
	end
	return vehiclesList
end

---@param ped integer
---@return integer[]
function get_ped_nearby_entities(ped)
	local peds = get_ped_nearby_peds(ped)
	local vehicles = get_ped_nearby_vehicles(ped)
	local entities = peds
	for i = 1, #vehicles do table.insert(entities, vehicles[i]) end
	return entities
end

---@param pId integer
---@param radius number
---@return integer[]
function get_peds_in_player_range(pId, radius)
	local peds = {}
	local playerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pId)
	local pos = players.get_position(pId)
	for _, ped in ipairs(entities.get_all_peds_as_handles()) do
		if ped ~= playerPed and not PED.IS_PED_FATALLY_INJURED(ped) then
			local pedPos = ENTITY.GET_ENTITY_COORDS(ped)
			if pos:distance(pedPos) <= radius then table.insert(peds, ped) end
		end
	end
	return peds
end

---@param pId integer
---@param radius number
---@return integer[]
function get_vehicles_in_player_range(pId, radius)
	local vehicles = {}
	local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pId)
	local pos = players.get_position(pId)
	local v = PED.GET_VEHICLE_PED_IS_IN(p, false)
	for _, vehicle in ipairs(entities.get_all_vehicles_as_handles()) do
		local vehPos = ENTITY.GET_ENTITY_COORDS(vehicle)
		if vehicle ~= v and pos:distance(vehPos) <= radius then table.insert(vehicles, vehicle) end
	end
	return vehicles
end

---@param pId integer
---@param radius number
---@return integer[]
function get_entities_in_player_range(pId, radius)
	local peds = get_peds_in_player_range(pId, radius)
	local vehicles = get_vehicles_in_player_range(pId, radius)
	local entities = peds
	for i = 1, #vehicles do table.insert(entities, vehicles[i]) end
	return entities
end

---@param entity integer
---@param colour? table
function draw_box_esp(entity, colour)
	colour = colour or Colour.new(255, 0, 0, 255)
	local minimum = v3.new()
	local maximum = v3.new()
	if ENTITY.DOES_ENTITY_EXIST(entity) then
		MISC.GET_MODEL_DIMENSIONS(ENTITY.GET_ENTITY_MODEL(entity), minimum, maximum)
		local width   = 2 * maximum.x
		local length  = 2 * maximum.y
		local depth   = 2 * maximum.z
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
end

---@param entity integer
---@param flag integer
function set_decor_flag(entity, flag)
	if ENTITY.DOES_ENTITY_EXIST(entity) then
		DECORATOR.DECOR_SET_INT(entity, "Casino_Game_Info_Decorator", flag)
	end
end

---@param entity integer
---@param flag integer
---@return boolean
function is_decor_flag_set(entity, flag)
	if ENTITY.DOES_ENTITY_EXIST(entity) and
	DECORATOR.DECOR_EXIST_ON(entity, "Casino_Game_Info_Decorator") then
		local value = DECORATOR.DECOR_GET_INT(entity, "Casino_Game_Info_Decorator")
		return (value & flag) ~= 0
	end
	return false
end

---@param entity integer
function remove_decor(entity)
	DECORATOR.DECOR_REMOVE(entity, "Casino_Game_Info_Decorator")
end


---@param ped integer
---@param forcedOn boolean
---@param hasCone boolean
---@param noticeRange number
---@param colour integer
---@param sprite integer
---@return integer
function add_ai_blip_for_ped(ped, forcedOn, hasCone, noticeRange, colour, sprite)
	if colour == -1 then
		HUD.SET_PED_HAS_AI_BLIP(ped, true)
	else
		HUD._SET_PED_HAS_AI_BLIP_WITH_COLOR(ped, true, colour)
	end
	HUD.SET_PED_AI_BLIP_NOTICE_RANGE(ped, noticeRange)
	if sprite ~= -1 then HUD._SET_PED_AI_BLIP_SPRITE(ped, sprite) end
	HUD.SET_PED_AI_BLIP_HAS_CONE(ped, hasCone)
	HUD.SET_PED_AI_BLIP_FORCED_ON(ped, forcedOn)
	util.yield_once() -- the ped does not get the blip inmmediatly
	return HUD._GET_AI_BLIP_2(ped)
end

---Returns a random offset from an entity in range.
---@param entity integer
---@param minDistance number
---@param maxDistance number
---@return Vector3
function get_random_offset_in_range(entity, minDistance, maxDistance)
	local radius = random_float(minDistance, maxDistance)
	local angle = random_float(0, 2 * math.pi)
	local delta = v3.new(math.cos(angle), math.sin(angle), 0.0)
	delta:mul(radius)
	local pos = ENTITY.GET_ENTITY_COORDS(entity, false)
	pos:add(delta)
	return pos
end

--------------------------
-- PLAYER
--------------------------

---@param pId integer
---@return boolean
function is_player_friend(pId)
	local pHandle = memory.alloc(104)
	NETWORK.NETWORK_HANDLE_FROM_PLAYER(pId, pHandle, 13)
	local isFriend = NETWORK.NETWORK_IS_HANDLE_VALID(pHandle, 13) and NETWORK.NETWORK_IS_FRIEND(pHandle)
	return isFriend
end

---@param pId integer
---@return integer
function get_vehicle_player_is_in(pId)
	local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pId)
	local vehicle = PED.GET_VEHICLE_PED_IS_IN(p, false)
	return vehicle
end

---@param player integer
---@return integer
function get_entity_player_is_aiming_at(player)
	local entity = NULL
	if PLAYER.IS_PLAYER_FREE_AIMING(player) then
		local pEntity = memory.alloc_int()
		if PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(player, pEntity) then
			entity = memory.read_int(pEntity)
		end
		if ENTITY.IS_ENTITY_A_PED(entity) and PED.IS_PED_IN_ANY_VEHICLE(entity) then
			local vehicle = PED.GET_VEHICLE_PED_IS_IN(entity, false)
			entity = vehicle
		end
	end
	return entity
end

--------------------------
-- CAM
--------------------------

---@param dist number
---@return userdata
function get_offset_from_cam(dist)
	local rot = CAM.GET_FINAL_RENDERED_CAM_ROT(2)
	local pos = CAM.GET_FINAL_RENDERED_CAM_COORD()
	local dir = rot:toDir()
	dir:mul(dist)
	local offset = v3.new(pos)
	offset:add(dir)
	return offset
end

_ATTACH_CAM_TO_ENTITY_WITH_FIXED_DIRECTION = function (--[[Cam (int)]] cam, --[[Entity (int)]] entity, --[[float]] xRot, --[[float]] yRot, --[[float]] zRot, --[[float]] xOffset, --[[float]] yOffset, --[[float]] zOffset, --[[BOOL (bool)]] isRelative)
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

---@param dist number
---@param flag? integer
---@return table
function get_raycast_result(dist, flag)
	local result = {}
	flag = flag or TraceFlag.everything
	local didHit = memory.alloc(1)
	local endCoords = v3.new()
	local surfaceNormal = v3.new()
	local hitEntity = memory.alloc_int()
	local origin = CAM.GET_FINAL_RENDERED_CAM_COORD()
	local destination = get_offset_from_cam(dist)
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
	result.didHit = memory.read_byte(didHit) ~= 0
	result.endCoords = endCoords
	result.surfaceNormal = surfaceNormal
	result.hitEntity = memory.read_int(hitEntity)
	return result
end

--------------------------
-- STREAMING
--------------------------

---@param model integer
function request_model(model)
	if STREAMING.IS_MODEL_VALID(model) and not STREAMING.HAS_MODEL_LOADED(model) then
		STREAMING.REQUEST_MODEL(model)
		while not STREAMING.HAS_MODEL_LOADED(model) do
			util.yield()
		end
	end
end

---@param asset string
function request_fx_asset(asset)
	STREAMING.REQUEST_NAMED_PTFX_ASSET(asset)
	while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(asset) do
		util.yield()
	end
end

---@param hash integer
function request_weapon_asset(hash)
	if WEAPON.HAS_WEAPON_ASSET_LOADED(hash) then
		return
	end
	WEAPON.REQUEST_WEAPON_ASSET(hash, 31, 0)
	while not WEAPON.HAS_WEAPON_ASSET_LOADED(hash) do
		util.yield()
	end
end

--------------------------
-- MEMORY
--------------------------

---@param addr integer
---@param offsets integer[]
---@return integer
function addr_from_pointer_chain(addr, offsets)
	if addr == 0 then return 0 end
	for k = 1, (#offsets - 1) do
		addr = memory.read_long(addr + offsets[k])
		if addr == 0 then return 0 end
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
		return memory.write_float(memory.script_global(global), on)
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

---Returns a random value from the given table.
---@param t table
---@return any
function table.random(t)
	if rawget(t, 1) ~= nil then
		return t[ math.random(#t) ]
	end
	local list = {}
	for _, value in pairs(t) do
		table.insert(list, value)
	end
	local result = list[math.random(#list)]
	return type(result) ~= "table" and result or table.random(result)
end

function equals(a, b)
	if a == b then return true end
	local type1 = type(a)
    local type2 = type(b)
    if type1 ~= type2 then return false end
	if type1 ~= "table" then return false end
	for k, v in pairs(a) do
		if b[ k ] == nil or not equals(v, b[ k ]) then
			return false
		end
	end
	return true
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

---Inserts `value` if `t` does not already includes it.
---@param t table
---@param value any
---@return boolean
function table.insert_once(t, value)
	if not table.find(t, value) then
		table.insert(t, value)
		return true
	end
	return false
end

---@generic K, V
---@param t table
---@param f fun(key: K, value: V): boolean
---@return V
---@nodiscard
function table.find_if(t, f)
	for k, v in pairs(t) do
		if f(k, v) then return k end
	end
end

---@generic K, V
---@param t table<K, V>
---@param value any
---@return K?
---@nodiscard
function table.find(t, value)
	for k, v in pairs(t) do
		if value == v then return k end
	end
	return nil
end

---@generic K, V
---@param t table<K, V>
---@param f fun(key: K, value: V):boolean
---@return integer
function table.count_if(t, f)
	local count = 0
	for k, v in pairs(t) do
		if f(k, v) then count = count + 1 end
	end
	return count
end

--------------------------
-- MISC
--------------------------

---@param num number
---@param places? integer
---@return number?
function round(num, places)
	return tonumber(string.format('%.' .. (places or 0) .. 'f', num))
end

function draw_debug_text(...)
	local arg = {...}
	local strg = ""
	for _, w in ipairs(arg) do
		strg = strg .. tostring(w) .. '\n'
	end
	local colour = Colour.new(1.0, 0, 0, 1.0)
	directx.draw_text(0.05, 0.05, strg, ALIGN_TOP_LEFT, 1.0, colour, false)
end

---@param blip integer
---@return Vector3?
function get_blip_coords(blip)
	if blip == NULL then return nil end
	local pos = HUD.GET_BLIP_COORDS(blip)
	local tick = 0
	local success, groundz = util.get_ground_z(pos.x, pos.y)
	while not success and tick < 10 do
		util.yield()
		success, groundz = util.get_ground_z(pos.x, pos.y)
		tick = tick + 1
	end
	if success then pos.z = groundz end
	return pos
end

---@param pos Vector3
---@return number?
function get_ground_z(pos)
	local ptr = memory.alloc(4)
	MISC.GET_GROUND_Z_FOR_3D_COORD(pos.x, pos.y, pos.z, ptr, false)
	local groundz = memory.read_float(ptr)
	return groundz
end

---@param windowName string
---@param maxInput integer
---@param defaultText string
---@return string
function get_input_from_screen_keyboard(windowName, maxInput, defaultText)
	MISC.DISPLAY_ONSCREEN_KEYBOARD(0, windowName, "", defaultText, "", "", "", maxInput);
	while MISC.UPDATE_ONSCREEN_KEYBOARD() == 0 do
		util.yield()
	end
	if MISC.UPDATE_ONSCREEN_KEYBOARD() == 1 then
		return MISC.GET_ONSCREEN_KEYBOARD_RESULT()
	else
		return ""
	end
end

---@param s number
---@param x number
---@param y number
---@param scale number
---@param font integer
function draw_string(s, x, y, scale, font)
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

function EnableOTR()
	write_global.int(2689224 + ((PLAYER.PLAYER_ID() * 451) + 1) + 207, 1)
	write_global.int(2703660 + 56, NETWORK.GET_NETWORK_TIME() + 1)
end

function DisableOTR()
	write_global.int(2689224 + ((PLAYER.PLAYER_ID() * 451) + 1) + 207, 0)
end

function DisablePhone()
    write_global.int(19937, 1)
end

function SetTimerPosition(value)
    write_global.int(1645748 + 1121, value)
end

---@param min number
---@param max number
---@return number
function random_float(min, max)
	return min + math.random() * (max - min)
end

local org_log = util.log
util.log = function (msg)
	org_log("[WiriScript] " .. msg)
end


return self
