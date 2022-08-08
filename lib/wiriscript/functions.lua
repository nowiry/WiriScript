--[[
--------------------------------
THIS FILE IS PART OF WIRISCRIPT
         Nowiry#2663
--------------------------------
]]

---@diagnostic disable: param-type-mismatch
json = require "pretty.json"
local self = {}
self.version = 21

Config = {
	controls = {
		vehicleweapons = 86,
		airstrikeaircraft = 86
	},
	general = {
		standnotifications = false,
		displayhealth = true,
		language = "english",
		developer = false, 	-- developer flag (enables/disables some debug features)
		showintro = true
	},
	ufo = {
		disableboxes = false, 	-- determines if boxes are drawn on players to show their position
		targetplayer = false 	-- wether tractor beam only targets players or not
	},
	vehiclegun = {
		disablepreview = false,
	},
	healthtxtpos = {
		x = 0.03,
		y = 0.05
	}
}

---@alias HudColour integer

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

local NULL <const> = 0

--------------------------
-- NOTIFICATION
--------------------------

---@class Notification
notification =
{
	txdDict = "DIA_ZOMBIE1",
	txdName = "DIA_ZOMBIE1",
	title = "WiriScript",
	subtitle = "~c~" .. util.get_label_text("PM_PANE_FEE") .. "~s~",
	defaultColour = HudColour.black
}

---@param msg string
function notification.stand(msg)
	assert(type(msg) == "string", "msg must be a string, got " .. type(msg))
	msg = "[WiriScript] " .. tostring(msg):gsub('[~]%w[~]', "") -- removes any text colour (i.e. ~r~, ~b~, ~s~, etc.)
	util.toast(msg)
end


---@param format string
---@param colour? HudColour
function notification:help(format, colour, ...)
	assert(type(format) == "string", "msg must be a string, got " .. type(format))

	local msg = string.format(format, ...)
	if Config.general.standnotifications then
		return self.stand(msg)
	end

	HUD._THEFEED_SET_NEXT_POST_BACKGROUND_COLOR(colour or self.defaultColour)
	util.BEGIN_TEXT_COMMAND_THEFEED_POST("~BLIP_INFO_ICON~ " .. msg)
	HUD.END_TEXT_COMMAND_THEFEED_POST_TICKER_WITH_TOKENS(true, true)
end


---@param format string
---@param colour? HudColour
function notification:normal(format, colour, ...)
	assert(type(format) == "string", "msg must be a string, got " .. type(format))

	local msg = string.format(format, ...)
	if Config.general.standnotifications then
		return self.stand(msg)
	end

	HUD._THEFEED_SET_NEXT_POST_BACKGROUND_COLOR(colour or self.defaultColour)
	util.BEGIN_TEXT_COMMAND_THEFEED_POST(msg)
	HUD.END_TEXT_COMMAND_THEFEED_POST_MESSAGETEXT(self.txdDict, self.txdName, true, 4, self.title, self.subtitle)
	HUD.END_TEXT_COMMAND_THEFEED_POST_TICKER(false, false)
end

--------------------------
-- MENU
--------------------------

Features = {}
Translation = {}

---@param section string
---@param name string
---@return string
function translate(section, name)
	Features[section] = Features[section] or {}
	Features[section][name] = Features[section][name] or ""
	if Config.general.language == "english" then
		return name
	end
	Translation[section] = Translation[section] or Features[section]
	if not Translation[section][name] then
		Translation[section][name] = ""
		return name
	end
	if Translation[section][name] == "" then
		return name
	end
	return Translation[section][name]
end


---@param value any
---@param e string
function type_match (value, e)
	local t = type(value)
	for w in e:gmatch('[^|]+') do
		if t == w then return true end
	end
	local msg = "must be %s, got %s"
	return false, msg:format(e:gsub('|', " or "), t)
end


---@param tbl table
---@param types {[1]: string, [2]:string}
---@return boolean
---@return string? errmsg
local check_table_types = function (tbl, types)
	if type(tbl) ~= "table" then
		return false, "tbl must be a tble"
	end
	for key, value in pairs(tbl) do
		local ok, err = type_match(key, types[1])
		if not ok then return false, "field " .. key .. ' ' .. err end

		local ok, err = type_match(value, types[2])
		if not ok then return false, "field " .. key .. ' ' .. err end
	end
	return true
end


---@param obj table
---@return boolean
---@return string? errmsg
function is_translation_valid (obj)
	for sect_name, section in pairs(obj) do
		if type(sect_name) ~= "string" then
			return false, "got unexpected key type: " .. type(sect_name)
		end
		if type(section) ~= "table" then
			return false, "field " .. sect_name .. " must be a table, got " .. type(section)
		end
		local ok, err = check_table_types(section, {"string", "string"})
		if not ok then return false, err end
	end
	return true
end


---@param language string
---@return boolean
---@return string? errmsg
function load_translation(language)
	local path = filesystem.scripts_dir() .. "WiriScript\\language\\" .. language
	if not filesystem.exists(path) then
		return false, "no such a file"
	end

	local ok, result = json.parse(path, false)
	if not ok then
		return false, result
	end

	local ok, err = is_translation_valid(result)
	if not ok then
		return false, err
	end

	Translation = result
	util.log("Translation file successfully loaded: %s", language)
	return true
end

--------------------------
-- FILE
--------------------------

Ini = {}

---Saves a table with key-value pairs in an ini format file.
---@param fileName string
---@param obj table
function Ini.save(fileName, obj)
	local file <close> = assert(io.open(fileName, "w"), "error loading file")
	local s = {}
	for section, tbl in pairs(obj) do
		assert(type(tbl) == "table", "expected field " .. section .. " to be a table, got " .. type(tbl))
		local l = {}
		table.insert(l, string.format("[%s]", section))
		for k, v in pairs(tbl) do table.insert(l, string.format("%s=%s", k, v)) end
		table.insert(s, table.concat(l, '\n') .. '\n')
	end
	file:write(table.concat(s, '\n'))
end


---Parses a table from an ini format file.
---@param fileName any
---@return table
function Ini.load(fileName)
	assert(type(fileName) == "string", "fileName must be a string")
	local file <close> = assert(io.open(fileName, "r"), "error loading file: " .. fileName)
	local data = {}
	local section
	for line in io.lines(fileName) do
		local tempSection = string.match(line, '^%[([^%]]+)%]$')
		if tempSection ~= nil then
			section = tonumber(tempSection) and tonumber(tempSection) or tempSection
			data[section] = data[section] or {}
		end
		local param, value = string.match(line, '^([%w_]+)%s*=%s*(.+)$')
		if section ~= nil and param and value ~= nil then
			if tonumber(value) then
				value = tonumber(value)
			elseif value == "true" then
				value = true
			elseif value == "false" then
				value = false
			end
			if tonumber(param) then param = tonumber(param) end
			---@diagnostic disable-next-line: need-check-nil
			data[section][param] = value
		end
	end
	return data
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

---@param name string|0
---@param reference string|0
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
	if not AUDIO.HAS_SOUND_FINISHED(self.Id) then
        AUDIO.STOP_SOUND(self.Id)
        AUDIO.RELEASE_SOUND_ID(self.Id)
        self.Id = -1
    end
end

function Sound:hasFinished()
	return AUDIO.HAS_SOUND_FINISHED(self.Id)
end

function Sound:playFromEntity(entity)
	if self.Id ~= -1 then
		return
	end
	self.Id = AUDIO.GET_SOUND_ID()
	AUDIO.PLAY_SOUND_FROM_ENTITY(self.Id, self.name, entity, self.reference, true, 0)
end

--------------------------
-- COLOUR
--------------------------

---@class Colour
---@field r number | integer
---@field g number | integer
---@field b number | integer
---@field a number | integer

function new_colour(r, g, b, a)
	return {r = r, g = g, b = b, a = a}
end

---@return Colour
function get_random_colour()
	local colour = {a = 255}
	colour.r = math.random(0,255)
	colour.g = math.random(0,255)
	colour.b = math.random(0,255)
	return colour
end

---@param hudColour HudColour
---@return Colour
function get_hud_colour(hudColour)
	local r = memory.alloc(1)
	local g = memory.alloc(1)
	local b = memory.alloc(1)
	local a = memory.alloc(1)
	HUD.GET_HUD_COLOUR(hudColour, r, g, b, a)
	return {r = memory.read_int(r), g = memory.read_int(g), b = memory.read_int(b), a = memory.read_int(a)}
end


---@param colour Colour
function rainbow_colour(colour)
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
end


---@param perc number
---@return Colour
function get_blended_colour(perc)
	local colour = {a = 255}
	local r, g, b
	if perc <= 0.5 then
		r = 1.0
		g = interpolate(0.0, 1.0, perc/0.5)
		b = 0.0
	else
		r = interpolate(1.0, 0, (perc - 0.5)/0.5)
		g = 1.0
		b = 0.0
	end
	colour.r = math.ceil(r * 255)
	colour.g = math.ceil(g * 255)
	colour.b = math.ceil(b * 255)
	return colour
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

    GRAPHICS.DRAW_SCALEFORM_MOVIE_FULLSCREEN(self.scaleform, 255, 255, 255, 220, 0)
	self.position = 0
end

--------------------------
-- TIMER
--------------------------

---@class Timer
---@field elapsed fun(): integer
---@field reset fun()
---@field isEnabled fun(): boolean
---@field disable fun()


---@return Timer
function newTimer()
	local self = {
		start = util.current_time_millis(),
		m_enabled = false,
	}

	local function reset()
		self.start = util.current_time_millis()
		self.m_enabled = true
	end

	local function elapsed()
		return util.current_time_millis() - self.start
	end

	local function disable() self.m_enabled = false end
	local function isEnabled() return self.m_enabled end

	return
	{
		isEnabled = isEnabled,
		reset = reset,
		elapsed = elapsed,
		disable = disable,
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

---@param entity Entity
---@param value boolean
function set_explosion_proof(entity, value)
	local pEntity = entities.handle_to_pointer(entity)
	if pEntity == 0 then return end
	local damageBits = memory.read_uint(pEntity + 0x0188)
	damageBits = value and setBit(damageBits, 11) or clearBit(damageBits, 11)
	memory.write_uint(pEntity + 0x0188, damageBits)
end


---@param entity Entity
---@param target Entity
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
		ENTITY.SET_ENTITY_ROTATION(entity, rot.x, rot.y, rot.z, 2, 0)
	end
end

---@param entity Entity
---@param blipSprite integer
---@param colour Colour
---@return Blip
function add_blip_for_entity(entity, blipSprite, colour)
	local blip = HUD.ADD_BLIP_FOR_ENTITY(entity)
	HUD.SET_BLIP_SPRITE(blip, blipSprite)
	HUD.SET_BLIP_COLOUR(blip, colour)
	HUD.SHOW_HEIGHT_ON_BLIP(blip, false)

	util.create_tick_handler(function ()
		if not ENTITY.DOES_ENTITY_EXIST(entity)or ENTITY.IS_ENTITY_DEAD(entity, 0) then
			util.remove_blip(blip)
			return false
		elseif not HUD.DOES_BLIP_EXIST(blip) then
			return false
		else
			local heading = ENTITY.GET_ENTITY_HEADING(entity)
        	HUD.SET_BLIP_ROTATION(blip, math.ceil(heading))
		end
	end)

	return blip
end

---@param blip Blip
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

---@param entity Entity
---@return boolean
function request_control_once(entity)
	if not NETWORK.NETWORK_IS_IN_SESSION() then
		return true
	end
	local netId = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(entity)
	NETWORK.SET_NETWORK_ID_CAN_MIGRATE(netId, true)
	return NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
end

---@param entity Entity
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

---@param ped Ped
---@param maxPeds? integer
---@param ignore? integer
---@return Entity[]
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

---@param ped Ped
---@param maxVehicles? integer
---@return Entity[]
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

---@param ped Ped
---@return Entity[]
function get_ped_nearby_entities(ped)
	local peds = get_ped_nearby_peds(ped)
	local vehicles = get_ped_nearby_vehicles(ped)
	local entities = peds
	for i = 1, #vehicles do table.insert(entities, vehicles[i]) end
	return entities
end

---@param player Player
---@param radius number
---@return Entity[]
function get_peds_in_player_range(player, radius)
	local peds = {}
	local playerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player)
	local pos = players.get_position(player)
	for _, ped in ipairs(entities.get_all_peds_as_handles()) do
		if ped ~= playerPed and not PED.IS_PED_FATALLY_INJURED(ped) then
			local pedPos = ENTITY.GET_ENTITY_COORDS(ped, true)
			if pos:distance(pedPos) <= radius then table.insert(peds, ped) end
		end
	end
	return peds
end

---@param player Player
---@param radius number
---@return Entity[]
function get_vehicles_in_player_range(player, radius)
	local vehicles = {}
	local pos = players.get_position(player)
	for _, vehicle in ipairs(entities.get_all_vehicles_as_handles()) do
		local vehPos = ENTITY.GET_ENTITY_COORDS(vehicle, true)
		if pos:distance(vehPos) <= radius then table.insert(vehicles, vehicle) end
	end
	return vehicles
end

---@param pId Player
---@param radius number
---@return Entity[]
function get_entities_in_player_range(pId, radius)
	local peds = get_peds_in_player_range(pId, radius)
	local vehicles = get_vehicles_in_player_range(pId, radius)
	local entities = peds
	for i = 1, #vehicles do table.insert(entities, vehicles[i]) end
	return entities
end

---@param start v3
---@param to v3
---@param colour Colour
local draw_line = function (start, to, colour)
	GRAPHICS.DRAW_LINE(start.x, start.y, start.z, to.x, to.y, to.z, colour.r, colour.g, colour.b, colour.a)
end


---@param entity Entity
---@param colour? Colour
function draw_box_esp(entity, colour)
	if not ENTITY.DOES_ENTITY_EXIST(entity) then
		return
	end
	colour = colour or {r = 255, g = 0, b = 0, a = 255}
	local min = v3.new()
	local max = v3.new()
	MISC.GET_MODEL_DIMENSIONS(ENTITY.GET_ENTITY_MODEL(entity), min, max)
	min:abs(); max:abs()

	local upperLeftRear = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, -max.x, -max.y, max.z)
	local upperRightRear = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, min.x, -max.y, max.z)
	local lowerLeftRear = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, -max.x, -max.y, -min.z)
	local lowerRightRear = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, min.x, -max.y, -min.z)

	draw_line(upperLeftRear, upperRightRear, colour)
	draw_line(lowerLeftRear, lowerRightRear, colour)
	draw_line(upperLeftRear, lowerLeftRear, colour)
	draw_line(upperRightRear, lowerRightRear, colour)

	local upperLeftFront = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, -max.x, min.y, max.z)
	local upperRightFront = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, min.x, min.y, max.z)
	local lowerLeftFront = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, -max.x, min.y, -min.z)
	local lowerRightFront = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, min.x, min.y, -min.z)

	draw_line(upperLeftFront, upperRightFront, colour)
	draw_line(lowerLeftFront, lowerRightFront, colour)
	draw_line(upperLeftFront, lowerLeftFront, colour)
	draw_line(upperRightFront, lowerRightFront, colour)

	draw_line(upperLeftRear, upperLeftFront, colour)
	draw_line(upperRightRear, upperRightFront, colour)
	draw_line(lowerLeftRear, lowerLeftFront, colour)
	draw_line(lowerRightRear, lowerRightFront, colour)
end


---@param entity Entity
---@param flag integer
function set_decor_flag(entity, flag)
	if ENTITY.DOES_ENTITY_EXIST(entity) then
		DECORATOR.DECOR_SET_INT(entity, "Casino_Game_Info_Decorator", flag)
	end
end

---@param entity Entity
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

---@param entity Entity
function remove_decor(entity)
	DECORATOR.DECOR_REMOVE(entity, "Casino_Game_Info_Decorator")
end

---@param ped Ped
---@param forcedOn boolean
---@param hasCone boolean
---@param noticeRange number
---@param colour integer
---@param sprite integer
---@return Blip
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


---@param entity Entity
---@param minDistance number
---@param maxDistance number
---@return v3
function get_random_offset_from_entity(entity, minDistance, maxDistance)
	local pos = ENTITY.GET_ENTITY_COORDS(entity, false)
	return get_random_offset_in_range(pos, minDistance, maxDistance)
end


---@param coords v3
---@param minDistance number
---@param maxDistance number
---@return v3
function get_random_offset_in_range(coords, minDistance, maxDistance)
	local radius = random_float(minDistance, maxDistance)
	local angle = random_float(0, 2 * math.pi)
	local delta = v3.new(math.cos(angle), math.sin(angle), 0.0)
	delta:mul(radius)
	coords:add(delta)
	return coords
end


---@param entity Entity
function set_entity_as_no_longer_needed(entity)
	if not ENTITY.DOES_ENTITY_EXIST(entity) then return end
	local pHandle = memory.alloc_int()
	memory.write_int(pHandle, entity)
	ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(pHandle)
end

---@param ped Ped
---@param hash Hash
---@return boolean
function is_ped_task_active(ped, hash)
	if ENTITY.DOES_ENTITY_EXIST(ped) and not PED.IS_PED_INJURED(ped) then
		local status = TASK.GET_SCRIPT_TASK_STATUS(ped, hash)
		return status == 1 or status == 0
	end
	return false
end

--------------------------
-- PLAYER
--------------------------

---@param player Player
---@return boolean
function is_player_friend(player)
	local pHandle = memory.alloc(104)
	NETWORK.NETWORK_HANDLE_FROM_PLAYER(player, pHandle, 13)
	local isFriend = NETWORK.NETWORK_IS_HANDLE_VALID(pHandle, 13) and NETWORK.NETWORK_IS_FRIEND(pHandle)
	return isFriend
end

---@param player Player
---@return Vehicle
function get_vehicle_player_is_in(player)
	local targetPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player)
	if PED.IS_PED_IN_ANY_VEHICLE(targetPed, false) then
		return PED.GET_VEHICLE_PED_IS_IN(targetPed, false)
	end
	return 0
end

---@param player Player
---@return Entity
function get_entity_player_is_aiming_at(player)
	if not PLAYER.IS_PLAYER_FREE_AIMING(player) then
		return NULL
	end
	local entity, pEntity = NULL, memory.alloc_int()
	if PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(player, pEntity) then
		entity = memory.read_int(pEntity)
	end
	if entity ~= NULL and ENTITY.IS_ENTITY_A_PED(entity) and PED.IS_PED_IN_ANY_VEHICLE(entity, false) then
		entity = PED.GET_VEHICLE_PED_IS_IN(entity, false)
	end
	return entity
end

---@param entity Entity
---@return integer address
function get_net_obj(entity)
	local pEntity = entities.handle_to_pointer(entity)
	return pEntity ~= NULL and memory.read_long(pEntity + 0x00D0) or NULL
end

---@param entity Entity
---@return Player owner
function get_entity_owner(entity)
	local net_obj = get_net_obj(entity)
	return net_obj ~= NULL and memory.read_byte(net_obj + 0x49) or -1
end

---@param player Player
---@return boolean
function is_player_passive(player)
	if player ~= players.user() then
		local address = memory.script_global(1892703 + (player * 599 + 1) + 8)
		if address ~= NULL then return memory.read_byte(address) == 1 end
	else
		local address = memory.script_global(1574582)
		if address ~= NULL then return memory.read_int(address) == 1 end
	end
	return false
end

---@param player Player
---@return boolean
function is_player_in_any_interior(player)
	local address = memory.script_global(2689235 + (player * 453 + 1) + 243)
	if address ~= NULL then
		return memory.read_int(address) ~= 0
	end
	return false
end

--------------------------
-- CAM
--------------------------

---@param dist number
---@return v3
function get_offset_from_cam(dist)
	local rot = CAM.GET_FINAL_RENDERED_CAM_ROT(2)
	local pos = CAM.GET_FINAL_RENDERED_CAM_COORD()
	local dir = rot:toDir()
	dir:mul(dist)
	local offset = v3.new(pos)
	offset:add(dir)
	return offset
end

--------------------------
-- NATIVES
--------------------------

---@diagnostic disable: undefined-global

--- CAM::_0x202A5ED9CE01D6E7
function CAM._ATTACH_CAM_TO_ENTITY_WITH_FIXED_DIRECTION(cam, entity, xRot, yRot, zRot, xOffset, yOffset, zOffset, isRelative)
    native_invoker.begin_call()
    native_invoker.push_arg_int(cam)
    native_invoker.push_arg_int(entity)
    native_invoker.push_arg_float(xRot); native_invoker.push_arg_float(yRot); native_invoker.push_arg_float(zRot)
    native_invoker.push_arg_float(xOffset); native_invoker.push_arg_float(yOffset); native_invoker.push_arg_float(zOffset)
    native_invoker.push_arg_bool(isRelative)
    native_invoker.end_call("202A5ED9CE01D6E7")
end

function PED.COUNT_PEDS_IN_COMBAT_WITH_TARGET_WITHIN_RADIUS(ped, posX, posY, posZ, radius)
	native_invoker.begin_call()
	native_invoker.push_arg_int(ped)
	native_invoker.push_arg_float(posX); native_invoker.push_arg_float(posY); native_invoker.push_arg_float(posZ)
	native_invoker.push_arg_float(radius)
	native_invoker.end_call("336B3D200AB007CB")
	return native_invoker.get_return_value_int()
end

---@diagnostic enable: undefined-global

--------------------------
-- RAYCAST
--------------------------

TraceFlag =
{
	everything = 4294967295,
	none = 0,
	world = 1,
	vehicles = 2,
	pedsSimpleCollision = 4,
	peds = 8,
	objects = 16,
	water = 32,
	foliage = 256,
}

---@class RaycastResult
---@field didHit boolean
---@field endCoords v3
---@field surfaceNormal v3
---@field hitEntity Entity

---@param dist number
---@param flag? integer
---@return RaycastResult
function get_raycast_result(dist, flag)
	local result = {}
	flag = flag or TraceFlag.everything
	local didHit = memory.alloc(1)
	local endCoords = v3.new()
	local surfaceNormal = v3.new()
	local hitEntity = memory.alloc_int()
	local pos1 = CAM.GET_FINAL_RENDERED_CAM_COORD()
	local pos2 = get_offset_from_cam(dist)

	local handle = SHAPETEST.START_EXPENSIVE_SYNCHRONOUS_SHAPE_TEST_LOS_PROBE(pos1.x, pos1.y, pos1.z, pos2.x, pos2.y, pos2.z, flag, players.user_ped(), 7)
	SHAPETEST.GET_SHAPE_TEST_RESULT(handle, didHit, endCoords, surfaceNormal, hitEntity)

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
---@return boolean
function request_model(model)
	if not STREAMING.IS_MODEL_VALID(model) then
		return false
	end

	if STREAMING.HAS_MODEL_LOADED(model) then
		return true
	end

	local timer = newTimer()
	STREAMING.REQUEST_MODEL(model)
	while not STREAMING.HAS_MODEL_LOADED(model) and
	timer.elapsed() < 500 do
		util.yield_once()
	end

	return timer.elapsed() < 500
end


---@param asset string
---@return boolean
function request_fx_asset(asset)
	if STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(asset) then
		return false
	end

	local timer = newTimer()
	STREAMING.REQUEST_NAMED_PTFX_ASSET(asset)
	while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(asset) and
	timer.elapsed() < 500 do
		util.yield_once()
	end

	return timer.elapsed() < 500
end


---@param hash integer
function request_weapon_asset(hash)
	if WEAPON.HAS_WEAPON_ASSET_LOADED(hash) then
		return true
	end

	WEAPON.REQUEST_WEAPON_ASSET(hash, 31, 0)
	while not WEAPON.HAS_WEAPON_ASSET_LOADED(hash) do util.yield() end
end

---Credits to aaron
---@param textureDict string
function request_streamed_texture_dict(textureDict)
	util.spoof_script("main_persistent", function()
		GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT(textureDict, false)
	end)
end

---@param textureDict string
function set_streamed_texture_dict_as_no_longer_needed(textureDict)
	util.spoof_script("main_persistent", function()
		GRAPHICS.SET_STREAMED_TEXTURE_DICT_AS_NO_LONGER_NEEDED(textureDict)
	end)
end

---@param name string
---@return integer
function request_scaleform_movie(name)
	local handle
	util.spoof_script("main_persistent", function ()
		handle = GRAPHICS.REQUEST_SCALEFORM_MOVIE(name)
	end)
	return handle
end

---@param handle integer
function set_scaleform_movie_as_no_longer_needed(handle)
	util.spoof_script("main_persistent", function ()
		local ptr = memory.alloc_int()
		memory.write_int(ptr, handle)
		GRAPHICS.SET_SCALEFORM_MOVIE_AS_NO_LONGER_NEEDED(ptr)
	end)
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
		local address = memory.script_global(global)
		if address ~= NULL then memory.write_byte(address, value) end
	end,
	int = function(global, value)
		local address = memory.script_global(global)
		if address ~= NULL then memory.write_int(address, value) end
	end,
	float = function(global, value)
		local address = memory.script_global(global)
		if address ~= NULL then memory.write_float(address, value) end
	end
}


read_global = {
	byte = function(global)
		local address = memory.script_global(global)
		return address ~= NULL and memory.read_byte(address) or nil
	end,
	int = function(global)
		local address = memory.script_global(global)
		return address ~= NULL and memory.read_int(address) or nil
	end,
	float = function(global)
		local address = memory.script_global(global)
		return address ~= NULL and memory.read_float(address) or nil
	end,
	string = function(global)
		local address = memory.script_global(global)
		return address ~= NULL and memory.read_string(address) or nil
	end
}


local orgScan = memory.scan

---@param name string
---@param pattern string
---@param callback fun(address: integer)
function memory.scan(name, pattern, callback)
	local address = orgScan(pattern)
	if address ~= NULL then
		util.log("Found " .. name)
		callback(address)
	else
		util.log("Failed to find " .. name)
		util.stop_script()
	end
end


HudTimer = {}

HudTimer.SetHeightMultThisFrame = function (mult)
	write_global.int(1649593 + 1163, mult)
end

HudTimer.DisableThisFrame = function()
	write_global.int(2727091, 1)
end


function EnableOTR()
	local toggle_addr = 2689235 + ((PLAYER.PLAYER_ID() * 453) + 1) + 208
	if read_global.int(toggle_addr) == 1 then
		return
	end
	write_global.int(toggle_addr, 1)
	write_global.int(2703735 + 56, NETWORK.GET_NETWORK_TIME() + 1)
end

function DisableOTR()
	write_global.int(2689235 + ((PLAYER.PLAYER_ID() * 453) + 1) + 208, 0)
end

function DisablePhone()
    write_global.int(20249, 1)
end

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
function table.insert_once(t, value)
	if not table.find(t, value) then table.insert(t, value) end
end

---@generic T: table, K, V
---@param t T
---@param f fun(key: K, value: V): boolean
---@return V
---@nodiscard
function table.find_if(t, f)
	for k, v in pairs(t) do
		if f(k, v) then return k end
	end
	return nil
end

---@generic T: table, K, V
---@param t T
---@param value any
---@return K?
---@nodiscard
function table.find(t, value)
	for k, v in pairs(t) do
		if value == v then return k end
	end
	return nil
end

---@generic T: table, K, V
---@param t T
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

--- Credits to Sainan
function int_to_uint(int)
    if int >= 0 then return int end
    return (1 << 32) + int
end

function interpolate(y0, y1, perc)
	perc = perc > 1.0 and 1.0 or perc
	return (1 - perc) * y0 + perc * y1
end

---@param num number
---@param places? integer
---@return number?
function round(num, places)
	return tonumber(string.format('%.' .. (places or 0) .. 'f', num))
end

---@param blip integer
---@return v3?
function get_blip_coords(blip)
	if blip == 0 then
		return nil
	end
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

---@param pos v3
---@return number?
function get_ground_z(pos)
	local pGroundZ = memory.alloc(4)
	MISC.GET_GROUND_Z_FOR_3D_COORD(pos.x, pos.y, pos.z, pGroundZ, false, true)
	local groundz = memory.read_float(pGroundZ)
	return groundz
end

---@param windowName string #Must be a label
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
	end
	return ""
end

---@param s string
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
	HUD.END_TEXT_COMMAND_DISPLAY_TEXT(x, y, 0)
end

function capitalize(txt)
	return tostring(txt):gsub('^%l', string.upper)
end

---@param min number
---@param max number
---@return number
function random_float(min, max)
	return min + math.random() * (max - min)
end


local orgLog = util.log

---@param format string
---@param ... any
util.log = function (format, ...)
	local strg = type(format) ~= "string" and tostring(format) or format:format(...)
	orgLog("[WiriScript] " .. strg)
end

function draw_debug_text(...)
	local arg = {...}
	local strg = ""
	for _, w in ipairs(arg) do
		strg = strg .. tostring(w) .. '\n'
	end
	local colour = {r = 1.0, g = 0.0, b = 0.0, a = 1.0}
	directx.draw_text(0.05, 0.05, strg, ALIGN_TOP_LEFT, 1.0, colour, false)
end

return self