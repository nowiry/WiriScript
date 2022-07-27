---@diagnostic disable:param-type-mismatch
--[[
--------------------------------
THIS FILE IS PART OF WIRISCRIPT
         Nowiry#2663
--------------------------------
]]

gVersion = 21
local scriptStartTime = util.current_time_millis()

local required <const> = {
	"lib/natives-1651208000.lua",
	"lib/wiriscript/functions.lua",
	"lib/wiriscript/ufo.lua",
	"lib/wiriscript/guided_missile.lua",
	"lib/pretty/json.lua",
	"lib/pretty/json/constant.lua",
	"lib/pretty/json/parser.lua",
	"lib/pretty/json/serializer.lua",
	"lib/wiriscript/ped_list.lua",
	"lib/wiriscript/homing_missiles.lua"
}
local scriptdir <const> = filesystem.scripts_dir()
for _, file in ipairs(required) do
	assert(filesystem.exists(scriptdir .. file), "required file not found: " .. file)
end

util.require_natives(1651208000)
local Functions = require "wiriscript.functions"
local UFO = require "wiriscript.ufo"
local GuidedMissile = require "wiriscript.guided_missile"
local pedList <const> = require "wiriscript.ped_list"
local homingMissiles = require "wiriscript.homing_missiles"

if filesystem.exists(filesystem.resources_dir() .. "WiriTextures.ytd") then
	util.register_file(filesystem.resources_dir() .. "WiriTextures.ytd")
	notification.txdDict = "WiriTextures"
	notification.txdName = "logo"
	request_streamed_texture_dict("WiriTextures")
else
	error("required file not found: WiriTextures.ytd" )
end


if Functions.version ~= gVersion or UFO.version ~= gVersion or GuidedMissile.version ~= gVersion or
homingMissiles.version ~= gVersion then
	error("versions of WiriScript's files don't match")
end

-----------------------------------
-- FILE SYSTEM
-----------------------------------	

local wiriDir <const> = scriptdir .. "WiriScript\\"
local languageDir <const> = wiriDir .. "language\\"
local configFile <const> = wiriDir .. "config.ini"


if not filesystem.exists(wiriDir) then
	filesystem.mkdir(wiriDir)
end

if not filesystem.exists(languageDir) then
	filesystem.mkdir(languageDir)
end

if not filesystem.exists(wiriDir .. "profiles") then
	filesystem.mkdir(wiriDir .. "profiles")
end

if not filesystem.exists(wiriDir .. "handling") then
	filesystem.mkdir(wiriDir .. "handling")
end

if not filesystem.exists(wiriDir .. "bodyguards") then
	filesystem.mkdir(wiriDir .. "bodyguards")
end

-----------------------------------
-- PEDS LIST
-----------------------------------

-- Here you can modify which peds are available to choose
-- ["name shown in Stand"] = "ped model ID"
local attackerList <const> = {
	["Prisoner (Muscular)"] = "s_m_y_prismuscl_01",
	["Mime Artist"] = "s_m_y_mime",
	["Movie Astronaut"] = "s_m_m_movspace_01",
	["SWAT"] = "s_m_y_swat_01",
	["Ballas Ganster"] = "g_m_y_ballaorig_01",
	["Marine"]= "csb_ramp_marine",
	["Cop Female"] = "s_f_y_cop_01",
	["Cop Male"] = "s_m_y_cop_01",
	["Jesus"] = "u_m_m_jesus_01",
	["Zombie"] = "u_m_y_zombie_01",
	["Avon Juggernaut"] = "u_m_y_juggernaut_01",
	["Clown"] = "s_m_y_clown_01",
	["Hooker"] = "s_f_y_hooker_02",
	["Altruist"] = "a_m_y_acult_01",
	["Fireman Male"] = "s_m_y_fireman_01",
	["Bigfoot"] = "ig_orleans",
	["Mariachi"] = "u_m_y_mani",
	["Priest"] = "ig_priest",
	["Transvestite Male"] = "a_m_m_tranvest_01",
	["General Fat Male"] = "a_m_m_genfat_01",
	["Grandma"] = "a_f_o_genstreet_01",
	["Bouncer"] = "s_m_m_bouncer_01",
	["High Security"] = "s_m_m_highsec_02",
	["Maid"] = "s_f_m_maid_01",
	["Juggalo Female"] = "a_f_y_juggalo_01",
	["Beach Female"] = "a_f_m_beach_01",
	["Beverly Hills Female"] = "a_f_m_bevhills_01",
	["Hipster"] = "ig_ramp_hipster",
	["Hipster Female"] = "a_f_y_hipster_01",
	["FIB Agent"] = "mp_m_fibsec_01",
	["Female Baywatch"] = "s_f_y_baywatch_01",
	["Franklyn"] = "player_one",
	["Trevor"] = "player_two",
	["Michael"] = "player_zero",
	["Pogo the Monkey"] = "u_m_y_pogo_01",
	["Space Ranger"] = "u_m_y_rsranger_01",
	["Stone Man"] = "s_m_m_strperf_01",
	["Street Art Male"] = "u_m_m_streetart_01",
	["Impotent Rage"] = "u_m_y_imporage",
	["Mechanic"] = "s_m_y_xmech_02",
}

---@class ModelList
ModelList =
{
	reference = 0,
	default = nil,
	name = "",
	command = "",
	---@type fun(caption: string, model: string)?
	onClick = nil,
	changeName = false,
}
ModelList.__index = ModelList

---@param parent integer
---@param name string
---@param command string
---@param helpText string
---@param tbl table
---@param onClick? fun(caption: string, model: string)
---@param changeName boolean #If the list's name will change to show the selected model.
---@return ModelList
function ModelList.new(parent, name, command, helpText, tbl, onClick, changeName)
	local self = setmetatable({}, ModelList)
	self.name = name
	self.command = command
	self.onClick = onClick
	self.changeName = changeName
	self.reference = menu.list(parent, name, {self.command}, helpText or "")
	for caption, value in pairs_by_keys(tbl) do
		if type(value) == "string" then
			self:addOpt(self.reference, caption, value)
		elseif type(value) == "table" then
			self:addSection(caption, value)
		else
			error("field "..caption.." is an invalid value")
		end
	end
	return self
end

function ModelList:addOpt(parent, caption, model)
	local command = self.command ~= "" and self.command .. caption or ""
	menu.action(parent, caption, {command}, "", function(click)
		if self.changeName then
			local newName = string.format("%s: %s", self.name, caption)
			menu.set_menu_name(self.reference, newName)
		end
		if (click & CLICK_FLAG_AUTO) == 0 then menu.focus(self.reference) end
		if self.onClick then self.onClick(caption, model) end
	end)
end

function ModelList:addSection(menu_name, tbl)
	local reference = menu.list(self.reference, menu_name, {}, "")
	for caption, name in pairs_by_keys(tbl) do self:addOpt(reference, caption, name) end
end

-----------------------------------
-- WEAPONS LIST
-----------------------------------

local Weapons <const> =
{
	-- Shotguns
	VAULT_WMENUI_2 =
	{
		WT_SG_PMP = "weapon_pumpshotgun",
		WT_SG_PMP2 = "weapon_pumpshotgun_mk2",
		WT_SG_SOF = "weapon_sawnoffshotgun",
		WT_SG_BLP = "weapon_bullpupshotgun",
		WT_SG_ASL = "weapon_assaultshotgun",
		WT_MUSKET = "weapon_musket",
		WT_HVYSHOT = "weapon_heavyshotgun",
		WT_DBSHGN = "weapon_dbshotgun",
		WT_AUTOSHGN = "weapon_autoshotgun",
		WT_CMBSHGN = "weapon_combatshotgun",
	},
	-- Machine guns
	VAULT_WMENUI_3 =
	{
		WT_SMG_MCR = "weapon_microsmg",
		WT_MCHPIST = "weapon_machinepistol",
		WT_MINISMG = "weapon_minismg",
		WT_SMG = "weapon_smg",
		WT_SMG2 = "weapon_smg_mk2",
		WT_SMG_ASL = "weapon_assaultsmg",
		WT_COMBATPDW = "weapon_combatpdw",
		WT_MG = "weapon_mg",
		WT_MG_CBT = "weapon_combatmg",
		WT_MG_CBT2 = "weapon_combatmg_mk2",
		WT_GUSENBERG = "weapon_gusenberg",
		WT_RAYCARBINE = "weapon_raycarbine",
	},
	-- Rifles
	VAULT_WMENUI_4 =
	{
		WT_RIFLE_ASL = "weapon_assaultrifle",
		WT_RIFLE_ASL2 = "weapon_assaultrifle_mk2",
		WT_RIFLE_CBN = "weapon_carbinerifle",
		WT_RIFLE_CBN2 = "weapon_carbinerifle_mk2",
		WT_RIFLE_ADV = "weapon_advancedrifle",
		WT_RIFLE_SCBN = "weapon_specialcarbine",
		WT_SPCARBINE2 = "weapon_specialcarbine_mk2",
		WT_BULLRIFLE = "weapon_bullpuprifle",
		WT_BULLRIFLE2 = "weapon_bullpuprifle_mk2",
		WT_CMPRIFLE = "weapon_compactrifle",
		WT_MLTRYRFL = "weapon_militaryrifle",
		WT_HEAVYRIFLE = "WEAPON_HEAVYRIFLE",
		WT_TACRIFLE = "WEAPON_TACTICALRIFLE",
	},
	-- Sniper rifles
	VAULT_WMENUI_5 =
	{
		WT_SNIP_RIF = "weapon_sniperrifle",
		WT_SNIP_HVY = "weapon_heavysniper",
		WT_SNIP_HVY2 = "weapon_heavysniper_mk2",
		WT_MKRIFLE = "weapon_marksmanrifle",
		WT_MKRIFLE2 = "weapon_marksmanrifle_mk2",
		WT_PRCSRIFLE = "WEAPON_PRECISIONRIFLE",
	},
	-- Heavy weapons
	VAULT_WMENUI_6 =
	{
		WT_GL = "weapon_grenadelauncher",
		WT_RPG = "weapon_rpg",
		WT_MINIGUN = "weapon_minigun",
		WT_FWRKLNCHR = "weapon_firework",
		WT_RAILGUN = "weapon_railgun",
		WT_HOMLNCH = "weapon_hominglauncher",
		WT_CMPGL = "weapon_compactlauncher",
		WT_RAYMINIGUN = "weapon_rayminigun",
	},
	-- Melee weapons
	VAULT_WMENUI_8 =
	{
		WT_UNARMED = "weapon_unarmed",
		WT_KNIFE = "weapon_knife",
		WT_NGTSTK = "weapon_nightstick",
		WT_HAMMER = "weapon_hammer",
		WT_BAT = "weapon_bat",
		WT_CROWBAR = "weapon_crowbar",
		WT_GOLFCLUB = "weapon_golfclub",
		WT_BOTTLE = "weapon_bottle",
		WT_DAGGER = "weapon_dagger",
		WT_SHATCHET = "weapon_stone_hatchet",
		WT_KNUCKLE = "weapon_knuckle",
		WT_MACHETE = "weapon_machete",
		WT_FLASHLIGHT = "weapon_flashlight",
		WT_SWTCHBLDE = "weapon_switchblade",
		WT_BATTLEAXE = "weapon_battleaxe",
		WT_POOLCUE = "weapon_poolcue",
		WT_WRENCH = "weapon_wrench",
		WT_HATCHET = "weapon_hatchet",
	},
	-- Pistols
	VAULT_WMENUI_9 =
	{
		WT_PIST = "weapon_pistol",
		WT_PIST2  = "weapon_pistol_mk2",
		WT_PIST_CBT = "weapon_combatpistol",
		WT_PIST_50 = "weapon_pistol50",
		WT_SNSPISTOL = "weapon_snspistol",
		WT_SNSPISTOL2 = "weapon_snspistol_mk2",
		WT_HEAVYPSTL = "weapon_heavypistol",
		WT_VPISTOL = "weapon_vintagepistol",
		WT_CERPST = "weapon_ceramicpistol",
		WT_MKPISTOL = "weapon_marksmanpistol",
		WT_REVOLVER = "weapon_revolver",
		WT_REVOLVER2 = "weapon_revolver_mk2",
		WT_REV_DA = "weapon_doubleaction",
		WT_REV_NV= "weapon_navyrevolver",
		WT_GDGTPST = "weapon_gadgetpistol",
		WT_STUN = "weapon_stungun",
		WT_FLAREGUN = "weapon_flaregun",
		WT_RAYPISTOL = "weapon_raypistol",
		WT_PIST_AP = "weapon_appistol",
	},
}

---@class WeaponList
WeaponList =
{
	reference = 0,
	---@type string?
	name = "",
	---@type string?
	command = "",
	---@type fun(caption: string, model: string)?
	onClick = nil,
	changeName = false,
	selected = nil,
}
WeaponList.__index = WeaponList

---@param parent integer
---@param name string
---@param command? string
---@param helpText? string
---@param onClick? fun(caption: string, model: string)
---@param changeName boolean
---@return WeaponList
function WeaponList.new(parent, name, command, helpText, onClick, changeName)
	local self = setmetatable({}, WeaponList)
	self.name = name
	self.command = command
	self.changeName = changeName
	self.onClick = onClick
	self.reference = menu.list(parent, name, {self.command}, helpText or "")
	for section, tbl in pairs_by_keys(Weapons) do self:addSection(section, tbl) end
	return self
end

function WeaponList:addOpt(parent, label, model)
	local name = util.get_label_text(label)
	local command = self.command ~= "" and self.command .. name or ""
	menu.action(parent, name, {command}, "", function(click)
		if self.changeName then
			local newName = string.format("%s: %s", self.name, name)
			menu.set_menu_name(self.reference, newName)
		end
		self.selected = model
		if click == CLICK_MENU then menu.focus(self.reference) end
		if self.onClick then self.onClick(name, model) end
	end)
end

function WeaponList:addSection(section, weapons)
	local list = menu.list(self.reference, util.get_label_text(section), {}, "")
	for label, model in pairs_by_keys(weapons) do self:addOpt(list, label, model) end
end

-----------------------------------
-- OTHERS
-----------------------------------

-- [name] = {"keyboard; controller", index}
local Imputs <const> = {
	INPUT_JUMP = {"Spacebar; X", 22},
	INPUT_VEH_ATTACK = {"Mouse L; RB", 69},
	INPUT_VEH_AIM = {"Mouse R; LB", 68},
	INPUT_VEH_DUCK = {"X; A", 73},
	INPUT_VEH_HORN = {"E; L3", 86},
	INPUT_VEH_CINEMATIC_UP_ONLY = {"Numpad +; none", 96},
	INPUT_VEH_CINEMATIC_DOWN_ONLY = {"Numpad -; none", 97}
}

local Sounds <const> = {
	zoomOut = Sound.new("zoom_out_loop", "dlc_xm_orbital_cannon_sounds"),
	activating = Sound.new("cannon_activating_loop", "dlc_xm_orbital_cannon_sounds"),
	backgroundLoop = Sound.new("background_loop", "dlc_xm_orbital_cannon_sounds"),
	fireLoop = Sound.new("cannon_charge_fire_loop", "dlc_xm_orbital_cannon_sounds")
}

local NULL <const> = 0
DecorFlag_isTrollyVehicle = 1 << 0
DecorFlag_isEnemyVehicle = 1 << 1
DecorFlag_isAttacker = 1 << 2
DecorFlag_isAngryPlane = 1 << 3

local customLabels <const> = {
	EnterFileName = util.register_label("Enter the file name"),
	InvalidChar = util.register_label("Got an invalid character, try again"),
	EnterValue = util.register_label("Enter the value"),
	ValueMustBeNumber = util.register_label("The value must be a number, try again")
}

---------------------------------
-- CONFIG
---------------------------------


if filesystem.exists(configFile) then
	for s, tbl in pairs(Ini.load(configFile)) do
		for k, v in pairs(tbl) do
			if Config[s] and Config[s][k] ~= nil then Config[s][k] = v end
		end
	end
	util.log("Configuration loaded")
end

if Config.general.language ~= "english" then
	local ok, err = load_translation(Config.general.language .. ".json")
	if not ok then notification:help("Couldn't load tranlation: " .. err, HudColour.red) end
end

-----------------------------------
-- HTTP
-----------------------------------

async_http.init("pastebin.com", "/raw/EhH1C6Dh", function(output)
	local version = tonumber(output)
	if version and version > gVersion then
    	notification:normal("WiriScript ~g~v" .. output .. "~s~" .. " is available.", HudColour.purpleDark)
		menu.hyperlink(menu.my_root(), "How to get WiriScript v" .. output, "https://cutt.ly/get-wiriscript", "")
	end
end, function() util.log("Failed to check for updates.") end)
async_http.dispatch()


async_http.init("pastebin.com", "/raw/WMUmGzNj", function(output)
	if string.match(output, '^#') ~= nil then
		local msg = string.match(output, '^#(.+)')
        notification:normal("~b~~italic~Nowiry: ~s~" .. msg, HudColour.purpleDark)
    end
end, function() util.log("Failed to get message.") end)
async_http.dispatch()

-------------------------------------
-- INTRO
-------------------------------------

---@class OpeningCredits
OpeningCredits = {handle = 0}
OpeningCredits.__index = OpeningCredits

function OpeningCredits.new()
	local self = setmetatable({}, OpeningCredits)
	self:REQUEST_SCALEFORM_MOVIE()
	return self
end

function OpeningCredits:REQUEST_SCALEFORM_MOVIE()
	self.handle = GRAPHICS.REQUEST_SCALEFORM_MOVIE("OPENING_CREDITS")
end

function OpeningCredits:HAS_LOADED()
	return GRAPHICS.HAS_SCALEFORM_MOVIE_LOADED(self.handle)
end

function OpeningCredits:ADD_TEXT_TO_SINGLE_LINE(mcName, text, font, colour)
	GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(self.handle, "ADD_TEXT_TO_SINGLE_LINE")
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_TEXTURE_NAME_STRING(mcName)
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_TEXTURE_NAME_STRING(text)
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_TEXTURE_NAME_STRING(font)
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_TEXTURE_NAME_STRING(colour)
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_BOOL(true)
	GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
end

function OpeningCredits:HIDE(mcName)
	GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(self.handle, "HIDE")
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_TEXTURE_NAME_STRING(mcName)
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(0.16)
	GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
end

function OpeningCredits:SETUP_SINGLE_LINE(mcName, fadeInDuration, fadeOutDuration, x, y, align)
	GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(self.handle, "SETUP_SINGLE_LINE")
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_TEXTURE_NAME_STRING(mcName)
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(fadeInDuration)
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(fadeOutDuration)
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(x)
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(y)
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_TEXTURE_NAME_STRING(align)
	GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
end

function OpeningCredits:SHOW_SINGLE_LINE(mcName)
	GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(self.handle, "SHOW_SINGLE_LINE")
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_TEXTURE_NAME_STRING(mcName)
	GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
end

function OpeningCredits:DRAW_FULLSCREEN(r, g, b, a)
	GRAPHICS.DRAW_SCALEFORM_MOVIE_FULLSCREEN(self.handle, r, g, b, a, 0)
end

function OpeningCredits:SET_AS_NO_LONGER_NEEDED()
	local pHandle = memory.alloc_int()
	memory.write_int(pHandle, self.handle)
	GRAPHICS.SET_SCALEFORM_MOVIE_AS_NO_LONGER_NEEDED(pHandle)
end


if SCRIPT_MANUAL_START and not SCRIPT_SILENT_START and Config.general.showintro then
	gShowingIntro = true
	local state = 0
	local timer <const> = newTimer()
	local scaleform <const> = OpeningCredits.new()
	local menuPosX = menu.get_position()
	local posX = menuPosX > 0.5 and 0.0 or 100.0
	local align = posX == 0.0 and "left" or "right"

	util.create_tick_handler(function()
		if (state == 0 and timer.elapsed() < 600) or
		not scaleform:HAS_LOADED() then
			return
		end

		if state ==  0 then
			scaleform:SETUP_SINGLE_LINE("production", 0.5, 0.5, posX, 0.0, align)
			scaleform:ADD_TEXT_TO_SINGLE_LINE("production", 'a', "$font5", "HUD_COLOUR_WHITE")
			scaleform:ADD_TEXT_TO_SINGLE_LINE("production", "nowiry", "$font2", "HUD_COLOUR_FREEMODE")
			scaleform:ADD_TEXT_TO_SINGLE_LINE("production", "production", "$font5", "HUD_COLOUR_WHITE")
			scaleform:SHOW_SINGLE_LINE("production")
			AUDIO.PLAY_SOUND_FROM_ENTITY(-1, "Pre_Screen_Stinger", PLAYER.PLAYER_PED_ID(), "DLC_HEISTS_FINALE_SCREEN_SOUNDS", true, 20)
			state = 1
			timer.reset()
		end

		if timer.elapsed() >= 4000 and state == 1 then
			scaleform:HIDE("production")
			state = 2
			timer.reset()
		end

		if timer.elapsed() >= 3000 and state == 2 then
			scaleform:SETUP_SINGLE_LINE("wiriscript", 0.5, 0.5, posX, 0.0, align)
			scaleform:ADD_TEXT_TO_SINGLE_LINE("wiriscript", "wiriscript", "$font2", "HUD_COLOUR_FREEMODE")
			scaleform:ADD_TEXT_TO_SINGLE_LINE("wiriscript", 'v' .. gVersion, "$font5", "HUD_COLOUR_WHITE")
			scaleform:SHOW_SINGLE_LINE("wiriscript")
			AUDIO.PLAY_SOUND_FROM_ENTITY(-1, "SPAWN", PLAYER.PLAYER_PED_ID(), "BARRY_01_SOUNDSET", true, 20)
			state = 3
			timer.reset()
		end

		if timer.elapsed() >= 4000 and state == 3 then
			scaleform:HIDE("wiriscript")
			state = 4
			timer.reset()
		end

		if timer.elapsed() >= 3000 and state == 4 then
			scaleform:SET_AS_NO_LONGER_NEEDED()
			gShowingIntro = false
			return false
		end
		scaleform:DRAW_FULLSCREEN(255, 255, 255, 255)
	end)
end

---------------------
---------------------
-- SPOOFING PROFILE
---------------------
---------------------

---@param value any
---@param e string
function type_match(value, e)
	local t = type(value)
	for w in e:gmatch('[^|]+') do
		if t == w then return true end
	end
	local msg = "expected %s, got %s"
	return nil, msg:format(e:gsub('|', " or "), t)
end

-------------------------------------
-- CREW
-------------------------------------

---@class Crew
Crew =
{
	icon = 0,
	tag = "",
	name = "",
	motto = "",
	alt_badge = "Off",
	rank = "",
}
Crew.__index = Crew

---@param o? table
---@return Crew
function Crew.new(o)
	o = o or {}
	local self = setmetatable(o, Crew)
	return self
end

---@param player integer
---@return Crew
function Crew.get_player_crew(player)
	local self = setmetatable({}, Crew)
	local networkHandle = memory.alloc(104)
	local clanDesc = memory.alloc(280)
	NETWORK.NETWORK_HANDLE_FROM_PLAYER(player, networkHandle, 13)
	if NETWORK.NETWORK_IS_HANDLE_VALID(networkHandle, 13) and
	NETWORK.NETWORK_CLAN_PLAYER_GET_DESC(clanDesc, 35, networkHandle) then
		self.icon = memory.read_int(clanDesc)
		self.name = memory.read_string(clanDesc + 0x08)
		self.tag = memory.read_string(clanDesc + 0x88)
		self.rank = memory.read_string(clanDesc + 0xB0)
		self.motto = players.clan_get_motto(player)
		self.alt_badge = memory.read_byte(clanDesc + 0xA0) ~= 0 and "On" or "Off"
	end
	return self
end


local crewInfo =
{
	Name = translate("Spoofing Profile - Crew", "Name"),
	ID = translate("Spoofing Profile - Crew", "ID"),
	Tag = translate("Spoofing Profile - Crew", "Tag"),
	AltBadge = translate("Spoofing Profile - Crew", "Alternative Badge"),
	Motto = translate("Spoofing Profile - Crew", "Motto"),
	None = translate("Spoofing Profile - Crew", "None")
}


---Creates a list with the crew's information
---@param parent integer
---@param name string
function Crew:createInfoList(parent, name)
	if self.icon == 0 then
		menu.action(parent, name .. ": " .. crewInfo.None, {}, "", function()end)
		return
	end
	local actions <const> = {{crewInfo.Name, self.name}, {crewInfo.ID, self.icon}, {crewInfo.Tag, self.tag},
	{crewInfo.Motto, self.motto}, {crewInfo.AltBadge, self.alt_badge == "On" and "Yes" or "No"}}
	local root = menu.list(parent, name, {}, "")
	for _, tbl in ipairs(actions) do menu.readonly(root, tbl[1], tbl[2]) end
end

Crew.__eq = function (a, b)
	return a.icon == b.icon and a.tag == b.tag and a.name == b.name
end

Crew.__pairs = function(tbl)
	local k <const> = {"icon", "name", "tag", "motto", "alt_badge", "rank"}
	local i = 0
	local iter = function()
		i = i + 1
		if tbl[k[i]] == nil then return nil end
		return k[i], tbl[k[i]]
	end
	return iter, tbl, nil
end

---Returns if a `Crew` (or table with crew information) is valid.
---If it's not, it also returns the error message.
---@param o table|Crew
---@return boolean
---@return string? errmsg
function Crew.isValid(o)
	if not o or not next(o) then return true end
	local types <const> =
	{
		icon = "number",
		tag = "string",
		name = "string",
		motto = "string|nil",
		alt_badge = "string|nil",
		rank = "string|nil"
	}
	for k, t in pairs(types) do
		local ok, err = type_match(rawget(o, k), t)
		if not ok then return false, "field " .. k .. ", " .. err end
	end
	return true
end

-------------------------------------
-- PROFILE
-------------------------------------

ProfileFlag_SpoofName = 1 << 0
ProfileFlag_SpoofRId = 1 << 1
ProfileFlag_SpoofCrew = 1 << 2
ProfileFlag_SpoofIp = 1 << 3


---@class Profile
Profile =
{
	name = "**Invalid**",
	rid = 0,
	crew = Crew.new(),
	flags = ProfileFlag_SpoofName | ProfileFlag_SpoofRId,
	---@type string|nil
	ip = nil,
}
Profile.__index = Profile

---@param o? table
---@return Profile
function Profile.new(o)
	o = o or {}
	local self = setmetatable(o, Profile)
	self.crew = Crew.new(self.crew)
	return self
end


---@param player integer
---@return Profile
function Profile.get_profile_from_player(player)
	local self = setmetatable({}, Profile)
	self.name = PLAYER.GET_PLAYER_NAME(player)
	self.rid = players.get_rockstar_id(player)
	self.crew = Crew.get_player_crew(player)
	self.ip = get_external_ip(player)
	return self
end


function Profile:enableName()
	local nameSpoofing = menu.ref_by_path("Online>Spoofing>Name Spoofing", 33)
	local spoofName =  menu.ref_by_rel_path(nameSpoofing, "Name Spoofing")
	if menu.get_value(spoofName) ~= 1 then
		menu.trigger_command(spoofName, "on")
	end
	local spoofedName = menu.ref_by_rel_path(nameSpoofing, "Spoofed Name")
	menu.trigger_command(spoofedName, self.name)
end


function Profile:enableRId()
	local rIdSpoofing = menu.ref_by_path("Online>Spoofing>RID Spoofing", 33)
	local spoofRId = menu.ref_by_rel_path(rIdSpoofing, "RID Spoofing")
	if menu.get_value(spoofRId) ~= 1 then
		menu.trigger_command(spoofRId, "on")
	end
	local spoofedRId = menu.ref_by_rel_path(rIdSpoofing, "Spoofed RID")
	menu.trigger_command(spoofedRId, self.rid)
end


function Profile:enableCrew()
	local crewSpoofing = menu.ref_by_path("Online>Spoofing>Crew Spoofing", 33)
	local crew = menu.ref_by_rel_path(crewSpoofing, "Crew Spoofing")
	if menu.get_value(crew) ~= 1 then
		menu.trigger_command(crew, "on")
	end

	local crewId = menu.ref_by_rel_path(crewSpoofing, "ID")
	menu.trigger_command(crewId, self.crew.icon)

	local crewTag = menu.ref_by_rel_path(crewSpoofing, "Tag")
	menu.trigger_command(crewTag, self.crew.tag)

	local crewAltBadge = menu.ref_by_rel_path(crewSpoofing, "Alternative Badge")
	local altBadgeValue = (self.crew.alt_badge == "On") and 1 or 0
	if menu.get_value(crewAltBadge) ~= altBadgeValue then
		menu.trigger_command(crewAltBadge, string.lower(self.crew.alt_badge))
	end

	local crewName = menu.ref_by_rel_path(crewSpoofing, "Name")
	menu.trigger_command(crewName, self.crew.name)

	local crewMotto = menu.ref_by_rel_path(crewSpoofing, "Motto")
	menu.trigger_command(crewMotto, self.crew.motto)
end


function Profile:enableIp()
	local ipSpoofing = menu.ref_by_path("Online>Spoofing>IP Address Spoofing", 35)
	local toggleIpSpoofing = menu.ref_by_rel_path(ipSpoofing, "IP Address Spoofing")
	if menu.get_value(toggleIpSpoofing) ~= 1 then
		menu.trigger_command(toggleIpSpoofing, "on")
	end
	local spoofedIp = menu.ref_by_rel_path(ipSpoofing, "Spoofed IP Address")
	menu.trigger_command(spoofedIp, self.ip)
end


---@param flag integer
---@return boolean
function Profile:isFlagOn(flag)
	return (self.flags & flag) ~= 0
end


---@param flag integer
---@param value boolean
function Profile:setFlag(flag, value)
	self.flags = value and (self.flags | flag) or (self.flags & ~flag)
end


function Profile:enable()
	if self:isFlagOn(ProfileFlag_SpoofName) then self:enableName() end
	if self:isFlagOn(ProfileFlag_SpoofRId) then self:enableRId() end
	if self:isFlagOn(ProfileFlag_SpoofCrew) then self:enableCrew() end
	if self:isFlagOn(ProfileFlag_SpoofIp) then self:enableIp() end
end


---@param a Profile
---@param b Profile
Profile.__eq = function (a, b)
	return a.name == b.name and a.rid == b.rid and
	a.crew == b.crew and a.ip == b.ip
end

Profile.__pairs = function(tbl)
	local k <const> = {"name", "rid", "crew", "ip"}
	local i = 0
	local iter = function()
		i = i + 1
		if tbl[k[i]] == nil then return nil end
		return k[i], tbl[k[i]]
	end
	return iter, tbl, nil
end

---Returns if a `Profile` (or table with a profile information) is valid.
---If it's not, it also returns the error message
---@param obj table|Profile
---@return boolean
---@return string? errmsg
function Profile.isValid(obj)
	local types <const> =
	{
		name = "string",
		rid  = "string|number",
		crew = "table|nil",
		ip = "string|nil",
	}
	for k, t in pairs(types) do
		local ok, err = type_match(rawget(obj, k), t)
		if not ok then return false, "field " .. k  .. ", ".. err end
	end
	if type(obj.rid) == "string" and not tonumber(obj.rid) then
		return false, "field rid is not string castable"
	end
	return Crew.isValid(obj.crew)
end

-------------------------------------
-- PROFILE MANAGER
-------------------------------------

local trans =
{
	ProfileDisabled = translate("Spoofing Profile", "Spoofing Profile disabled"),
	NotNumber = translate("Spoofing Profile", "RID must be a number"),
	MissingData = translate("Spoofing Profile", "Name and RID are required"),
	AlreadyExists = translate("Spoofing Profile", "Profile already exists"),
	NotUsingProfile = translate("Spoofing Profile", "You are not using any spoofing profile"),
	ProfileSaved = translate("Spoofing Profile", "Spoofing Profile saved"),
	Enabled = translate("Spoofing Profile", "Proofile enabled"),
	MovedToBin = translate("Spoofing Profile", "Profile moved to recycle bin"),
	InvalidProfile = translate("Spoofing Profile", "%s is an invalid profile: %s"),
}

---@class ProfileManager
ProfileManager =
{
	reference = 0,
	---@type table<string, Profile>
	profiles = {},
	---@type table<string, integer>
	menuLists = {},
	recycleBin = 0,
	dir = wiriDir .. "profiles\\",
	isUsingAnyProfile = false,
	---@type table<string, boolean>
	deletedProfiles = {},
	---@type Profile
	activeProfile = nil
}
ProfileManager.__index = ProfileManager


---@param parent integer
function ProfileManager.new(parent)
	local self = setmetatable({}, ProfileManager)
	local trans_SpoofingProfiles = translate("Spoofing Profile", "Spoofing Profile")
	self.reference = menu.list(parent, trans_SpoofingProfiles, {}, "")
	self.menuLists = {}
	self.deletedProfiles = {}
	self.profiles = {}

	local name <const> = translate("Spoofing Profile", "Disable Spoofing")
	 menu.action(self.reference, name, {"disableprofile"}, "", function()
		if not self:isAnyProfileEnabled() then
			notification:help(trans.NotUsingProfile, HudColour.red)
		else
			local name <const> = self.activeProfile.name
			self:disableSpoofing()
			notification:normal("%s: %s", HudColour.black, trans.ProfileDisabled, name)
		end
	end)

	local name <const> = translate("Spoofing Profile", "Add Profile")
	local addList = menu.list(self.reference, name, {"addprofile"}, "")
	local profile = {}

	local name <const> = translate("Spoofing Profile", "Name")
	local helpText = translate("Spoofing Profile", "Type the profile's name")
	menu.text_input(addList, name, {"profilename"}, helpText, function(name, click)
		if click ~= CLICK_SCRIPTED and name ~= "" then profile.name = name end
	end)

	local name <const> = translate("Spoofing Profile", "RID")
	local helpText = translate("Spoofing Profile", "Type the profile's RID")
	menu.text_input(addList, name, {"profilerid"}, helpText, function(rid, click)
		if click ~= CLICK_SCRIPTED and rid ~= "" then
			if not tonumber(rid) then return notification:help(trans.NotNumber, HudColour.red) end
			profile.rid = rid
		end
	end)

	local name <const> = translate("Spoofing Profile", "Save Spoofing Profile")
	menu.action(addList, name, {"saveprofile"}, "", function()
		if not profile.name or not profile.rid then
			return notification:help(trans.MissingData, HudColour.red)
		end
		local valid, err = Profile.isValid(profile)
		if not valid then
			return notification:help("%s: %s", HudColour.red, trans.InvalidProfile, err)
		end
		local profile = Profile.new(profile)
		if self:includes(profile) then
			return notification:help(trans.AlreadyExists, HudColour.red)
		end
		self:save(profile, true)
		notification:normal("%s: %s", HudColour.black, trans.ProfileSaved, profile.name)
	end)

	self.recycleBin = menu.list(self.reference, translate("Spoofing Profile", "Recycle Bin"), {}, "")
	menu.divider(self.reference, trans_SpoofingProfiles)
	self:load()
	return self
end


---@param profile Profile
---@return boolean
function ProfileManager:includes(profile)
	return table.find(self.profiles, profile) ~= nil
end

---@param menuName string
---@param profile Profile
function ProfileManager:add(menuName, profile)
	local root = menu.list(self.reference, menuName, {}, "")
	menu.divider(root, menuName)
	self.profiles[menuName] = profile; self.menuLists[menuName] = root

	menu.action(root, translate("Spoofing Profile", "Enable Spoofing Profile"), {}, "", function()
		if self:isAnyProfileEnabled() then self:disableSpoofing() end
		profile:enable()
		self.activeProfile = profile
		notification:normal("%s: %s", HudColour.back, trans.Enabled, profile.name)
	end)

	menu.action(root, translate("Spoofing Profile", "Open Profile"), {}, "", function()
		local pHandle = memory.alloc(104)
		NETWORK.NETWORK_HANDLE_FROM_MEMBER_ID(tostring(profile.rid), pHandle, 13)
		NETWORK.NETWORK_SHOW_PROFILE_UI(pHandle)
	end)

	menu.action(root, translate("Spoofing Profile", "Delete") , {}, "", function()
		self:remove(menuName, profile)
		notification:normal(trans.MovedToBin)
	end)

	menu.toggle(root, translate("Spoofing Profile", "Name"), {}, "", function(on)
		profile:setFlag(ProfileFlag_SpoofName, on)
	end, true)

	local name <const> = translate("Spoofing Profile", "RID")
	menu.toggle(root, name .. ": " .. profile.rid, {}, "", function(on)
		profile:setFlag(ProfileFlag_SpoofRId, on)
	end, true)

	if profile.ip then
		local name <const> = translate("Spoofing Profile", "IP")
		menu.toggle(root, name .. ": " .. profile.ip , {}, "", function(on)
			profile:setFlag(ProfileFlag_SpoofIp, on)
		end, false)
	end

	menu.toggle(root, translate("Spoofing Profile", "Crew Spoofing"), {}, "",
		function(toggle) profile:setFlag(ProfileFlag_SpoofCrew, toggle) end, false)
	profile.crew:createInfoList(root, translate("Spoofing Profile", "Crew"))
end


---@param profile Profile
---@param add boolean
function ProfileManager:save(profile, add)
	local fileName = profile.name
	if self.profiles[fileName] then
		local i = 2
		repeat
			fileName = string.format("%s (%d)", profile.name, i)
			i = i + 1
		until not self.profiles[fileName]
	end
	local file <close> = assert(io.open(self.dir .. fileName .. ".json", "w"))
	local content = json.stringify(profile, nil, 4)
	file:write(content)
	if add then self:add(fileName, profile) end
end


---@param name string
---@param profile Profile
function ProfileManager:remove(name, profile)
	menu.delete(self.menuLists[name])
	self.profiles[name] = nil; self.menuLists[name] = nil
	if self.deletedProfiles[ name ] then return end

	local helpText = translate("Spoofing Profile", "Click to restore")
	local command
	command = menu.action(self.recycleBin, name, {}, helpText, function()
		self:save(profile, true)
		menu.delete(command)
		self.deletedProfiles[name] = nil
	end)

	local filePath = self.dir .. name .. ".json"
	os.remove(filePath)
	self.deletedProfiles[name] = true
end


---@return boolean
function ProfileManager:isAnyProfileEnabled()
	return self.activeProfile ~= nil
end


function ProfileManager:disableSpoofing()
	if not self.activeProfile then return end
	local spoofing = menu.ref_by_path("Online>Spoofing", 33)
	if self.activeProfile:isFlagOn(ProfileFlag_SpoofName) then
		local spoofName = menu.ref_by_rel_path(spoofing, "Name Spoofing>Name Spoofing")
		if menu.get_value(spoofName) ~= 0 then menu.trigger_command(spoofName, "off") end
	end

	if self.activeProfile:isFlagOn(ProfileFlag_SpoofRId) then
		local spoofRId = menu.ref_by_rel_path(spoofing, "RID Spoofing>RID Spoofing")
		if menu.get_value(spoofRId) ~= 0 then menu.trigger_command(spoofRId, "off") end
	end

	if self.activeProfile:isFlagOn(ProfileFlag_SpoofCrew) then
		local spoofCrew = menu.ref_by_rel_path(spoofing, "Crew Spoofing>Crew Spoofing")
		if menu.get_value(spoofCrew) ~= 0 then menu.trigger_command(spoofCrew, "off") end
	end

	if self.activeProfile:isFlagOn(ProfileFlag_SpoofIp) then
		local ipSpoofing = menu.ref_by_rel_path(spoofing, "IP Address Spoofing>IP Address Spoofing")
		if menu.get_value(ipSpoofing) ~= 0 then menu.trigger_command(ipSpoofing, "off") end
	end
	self.activeProfile = nil
end


function ProfileManager:load()
	local count = 0
	for _, path in ipairs(filesystem.list_files(self.dir)) do
		local fileName, ext = string.match(path, '^.+\\(.+)%.(.+)$')
		if ext ~= "json" then
			os.remove(path)
			goto LABEL_CONTINUE
		end

		local ok, result = json.parse(path, false)
		if not ok then
			notification:help(result, HudColour.red)
			goto LABEL_CONTINUE
		end

		local valid, err = Profile.isValid(result)
		if not valid then
			notification:help(trans.InvalidProfile, HudColour.red, fileName, err)
			goto LABEL_CONTINUE
		end

		local profile = Profile.new(result)
		self:add(fileName, profile)
		count = count + 1
	::LABEL_CONTINUE::
	end
	util.log("Spoofing Profiles loaded: %d", count)
end

local profilesList <const> = ProfileManager.new(menu.my_root())
util.log("Spoofing Profiles initialized")

---------------------
---------------------
-- PLAYERS OPTIONS
---------------------
---------------------

generate_features = function(pId)
	menu.divider(menu.player_root(pId), "WiriScript")

	-------------------------------------
	-- CREATE SPOOFING PROFILE
	-------------------------------------

	menu.action(menu.player_root(pId), translate("Player", "Create Spoofing Profile"), {}, "", function()
		local profile = Profile.get_profile_from_player(pId)
		if profilesList:includes(profile) then
			return notification:help(trans.AlreadyExists, HudColour.red)
		end
		profilesList:save(profile, true)
		notification:normal(trans.ProfileSaved)
	end)

	---------------------
	---------------------
	-- TROLLING
	---------------------
	---------------------

	local trollingOpt <const> = menu.list(menu.player_root(pId), translate("Player", "Trolling & Griefing"), {}, "")

	-------------------------------------
	-- EXPLOSIONS
	-------------------------------------

	local customExplosion <const> = menu.list(trollingOpt, translate("Trolling", "Custom Explosion"), {}, "")
	local lastExplosion = newTimer()
	local Explosion = {
		audible = true,
		speed = 300,
		owned = false,
		type = 0,
		invisible = false
	}
	function Explosion:explodePlyr(pId)
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pId), false)
		pos.z = pos.z - 1.0
		if self.owned then self:addOwnedExplosion(pos) else self:addExplosion(pos) end
	end

	function Explosion:addOwnedExplosion(pos)
		FIRE.ADD_OWNED_EXPLOSION(players.user_ped(), pos.x, pos.y, pos.z, self.type, 1.0, self.audible, self.invisible, 0.0)
	end

	function Explosion:addExplosion(pos)
		FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, self.type, 1.0, self.audible, self.invisible, 0.0, false)
	end

	menu.slider(customExplosion, translate("Trolling - Custom Explosion", "Explosion Type"), {}, "",
		0, 72, 0, 1, function(value) Explosion.type = value end)

	menu.toggle(customExplosion, translate("Trolling - Custom Explosion", "Invisible"), {}, "",
		function(toggle) Explosion.invisible = toggle end)

	menu.toggle(customExplosion, translate("Trolling - Custom Explosion", "Silent"), {}, "",
		function(toggle) Explosion.audible = not toggle end)

	menu.toggle(customExplosion, translate("Trolling - Custom Explosion", "Owned Explosions"), {}, "",
		function(toggle) Explosion.owned = toggle end)

	menu.slider(customExplosion, translate("Trolling - Custom Explosion", "Loop Speed"), {}, "",
		50, 1000, 300, 10, function(value) Explosion.speed = value end)

	menu.action(customExplosion, translate("Trolling - Custom Explosion", "Explode"), {}, "", function ()
		Explosion:explodePlyr(pId)
	end)

	menu.toggle_loop(customExplosion, translate("Trolling - Custom Explosion", "Explosion Loop"), {}, "", function()
		if not players.exists(pId) then util.stop_thread() end
		if lastExplosion.elapsed() > Explosion.speed then
			Explosion:explodePlyr(pId); lastExplosion.reset()
		end
	end)

	menu.toggle_loop(trollingOpt, translate("Trolling", "Water Loop"), {}, "", function()
		if not players.exists(pId) then util.stop_thread()  end
		local pos = players.get_position(pId)
		pos.z = pos.z - 1.0
		FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, 13, 1.0, true, false, 0, false)
	end)

	menu.toggle_loop(trollingOpt, translate("Trolling", "Flame Loop"), {}, "", function()
		if not players.exists(pId) then util.stop_thread()  end
		local pos = players.get_position(pId)
		pos.z = pos.z - 1.0
		FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, 12, 1.0, true, false, 0, false)
	end)

	-------------------------------------
	-- KILL AS THE ORBITAL CANNON
	-------------------------------------

	local msg = translate("Trolling", "The player is in interior")

	menu.action(trollingOpt, translate("Trolling", "Kill With Orbital Cannon"), {"orbital"}, "", function()
		if players.is_in_interior(pId) then
			notification:help(msg, HudColour.red)
			return
		elseif gUsingOrbitalCannon then
			CAM.DO_SCREEN_FADE_OUT(800)
			util.yield(500)
			gCannonTarget = pId
			util.yield(4000)
			CAM.DO_SCREEN_FADE_IN(800)
			return
		end
		gUsingOrbitalCannon = true
		gCannonTarget = pId
		local height
		local cam = 0
		local zoomLevel = 0.0
		local scaleform = 0
		local maxFov <const> = 110
		local minFov <const> = 25
		local camFov = maxFov
		local zoomTimer <const> = newTimer()
		local canZoom = false -- Used when not using keyboard

		---@param playSound boolean
		local function dispatchZoomLevel(playSound)
			if playSound then Sounds.zoomOut:play() end
			GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SET_ZOOM_LEVEL")
			GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(zoomLevel)
			GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
			zoomTimer.reset()
		end

		local setCannonCamZoom = function ()
			local fovTarget = interpolate(maxFov, minFov, zoomLevel)
			local fov = CAM.GET_CAM_FOV(CAM.GET_RENDERING_CAM())
			if fovTarget ~= fov then
				camFov = interpolate(fov, fovTarget, zoomTimer.elapsed() / 200)
				CAM.SET_CAM_FOV(cam, camFov)
				return
			else Sounds.zoomOut:stop() end

			if PAD._IS_USING_KEYBOARD(2) then
				if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(2, 241) and zoomLevel < 1.0 then
					zoomLevel = zoomLevel + 0.25
					dispatchZoomLevel(true)
				elseif PAD.IS_DISABLED_CONTROL_JUST_PRESSED(2, 242) and
				zoomLevel > 0.0 then
					zoomLevel = zoomLevel - 0.25
					dispatchZoomLevel(true)
				end
			elseif canZoom then
				local controlNormal = PAD.GET_CONTROL_NORMAL(2, 221)
				if controlNormal > 0.3 and canZoom and zoomLevel < 1.0 then
					zoomLevel = zoomLevel + 0.25
					dispatchZoomLevel(true)
					canZoom = false
				elseif controlNormal < -0.3 and canZoom and zoomLevel > 0.0 then
					zoomLevel = zoomLevel - 0.25
					dispatchZoomLevel(true)
					canZoom = false
				end
			elseif PAD.GET_CONTROL_NORMAL(2, 221) == 0 then
				canZoom = true
			end
		end

		---@param pos Vector3
		---@param size number
		---@param hudColour integer
		local drawLockonSprite = function (pos, size, hudColour)
			if GRAPHICS.HAS_STREAMED_TEXTURE_DICT_LOADED("helicopterhud") then
				local colour = get_hud_colour(hudColour)
				local txdSizeX = 0.013
				local txdSizeY = 0.013 * GRAPHICS._GET_ASPECT_RATIO(0)
				GRAPHICS.SET_DRAW_ORIGIN(pos.x, pos.y, pos.z, 0)
				size = (size * 0.03)
				GRAPHICS.DRAW_SPRITE("helicopterhud", "hud_corner", -size * 0.5, -size, txdSizeX, txdSizeY, 0.0, colour.r, colour.g, colour.b, colour.a, true, 0)
				GRAPHICS.DRAW_SPRITE("helicopterhud", "hud_corner",  size * 0.5, -size, txdSizeX, txdSizeY, 90., colour.r, colour.g, colour.b, colour.a, true, 0)
				GRAPHICS.DRAW_SPRITE("helicopterhud", "hud_corner", -size * 0.5,  size, txdSizeX, txdSizeY, 270, colour.r, colour.g, colour.b, colour.a, true, 0)
				GRAPHICS.DRAW_SPRITE("helicopterhud", "hud_corner",  size * 0.5,  size, txdSizeX, txdSizeY, 180, colour.r, colour.g, colour.b, colour.a, true, 0)
				GRAPHICS.CLEAR_DRAW_ORIGIN()
			end
		end

		local countdown = 3 -- `seconds`
		local isCounting = false
		local countdownTimer <const> = newTimer()
		local state = 0
		local chargeLvl = 1.0
		local fadingTimer <const> = newTimer()
		local didShoot = false

		while true do
			util.yield()
			if not GRAPHICS.HAS_SCALEFORM_MOVIE_LOADED(scaleform) then
				scaleform = GRAPHICS.REQUEST_SCALEFORM_MOVIE("ORBITAL_CANNON_CAM")
				while GRAPHICS.HAS_SCALEFORM_MOVIE_LOADED(scaleform) do
					util.yield_once()
				end
			end

			if not CAM.DOES_CAM_EXIST(cam) then
				if not CAM.IS_SCREEN_FADED_OUT() then
					CAM.DO_SCREEN_FADE_OUT(800)
				else
					ENTITY.FREEZE_ENTITY_POSITION(PLAYER.PLAYER_PED_ID(), true)
					AUDIO.REQUEST_SCRIPT_AUDIO_BANK("DLC_CHRISTMAS2017/XM_ION_CANNON", false, -1)
					AUDIO.START_AUDIO_SCENE("dlc_xm_orbital_cannon_camera_active_scene")
					request_streamed_texture_dict("helicopterhud")
					Sounds.activating:play()

					CAM.DESTROY_ALL_CAMS(true)
					cam = CAM.CREATE_CAM("DEFAULT_SCRIPTED_CAMERA", false)
					CAM.SET_CAM_ROT(cam, -90.0, 0.0, 0.0, 2)
					CAM.SET_CAM_FOV(cam, camFov)
					local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(gCannonTarget), false)
					height = pos.z + 150
					CAM.SET_CAM_COORD(cam, pos.x, pos.y, height)
					CAM.SET_CAM_ACTIVE(cam, true)
					CAM.RENDER_SCRIPT_CAMS(true, false, 0, true, false, 0)
					GRAPHICS.ANIMPOSTFX_PLAY("MP_OrbitalCannon", 0, true)
					STREAMING.SET_FOCUS_POS_AND_VEL(pos.x, pos.y, pos.z, 5.0, 0.0, 0.0)
					menu.trigger_commands("becomeorbitalcannon on")

					dispatchZoomLevel(false)
					fadingTimer.reset()
				end
			elseif state == 0 and CAM.IS_SCREEN_FADED_OUT() then
				if fadingTimer.elapsed() > 2000 then
					CAM.DO_SCREEN_FADE_IN(500)

					Sounds.activating:stop()
					Sounds.backgroundLoop:play()
					AUDIO.PLAY_SOUND_FRONTEND(-1, "cannon_active", "dlc_xm_orbital_cannon_sounds", true)
				end
			else
				local targetPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(gCannonTarget)
				local pos = ENTITY.GET_ENTITY_COORDS(targetPed, false)
				STREAMING.SET_FOCUS_POS_AND_VEL(pos.x, pos.y, pos.z, 5.0, 0.0, 0.0)
				CAM.SET_CAM_COORD(cam, pos.x, pos.y, pos.z + 150)
				DisablePhone()
				HudTimer.DisableThisFrame()

				for _, player in ipairs(players.list()) do
					if not players.is_in_interior(player) and player ~= gCannonTarget then
						local playerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player)
						local pos = ENTITY.GET_ENTITY_COORDS(playerPed, false)
						local txdSize = interpolate(1.0, 0.5, camFov / maxFov)
						drawLockonSprite(pos, txdSize, HudColour.green)
					end
				end
				-- To prevent user ped falling through the map
				local myPos = ENTITY.GET_ENTITY_COORDS(players.user_ped(), false)
            	STREAMING.REQUEST_COLLISION_AT_COORD(myPos.x, myPos.y, myPos.z)

				GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SET_STATE")
				GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(4)
				GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

				if NETWORK.NETWORK_IS_IN_TRANSITION() or
				not NETWORK.NETWORK_IS_PLAYER_ACTIVE(gCannonTarget)then
					state = 3
				end

				if state == 0 then
					if PAD.IS_DISABLED_CONTROL_PRESSED(0, 69) then
						if not isCounting then
							PAD.SET_PAD_SHAKE(0, 1000, 50)
							countdownTimer.reset()
							Sounds.fireLoop:play()
							isCounting = true
						end
						if countdownTimer.elapsed() > 1000 and countdown > 0 then
							countdown = countdown - 1
							countdownTimer.reset()
						end
						GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SET_COUNTDOWN")
						GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(countdown)
						GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
					elseif isCounting then
						AUDIO.SET_VARIABLE_ON_SOUND(Sounds.fireLoop.Id, "Firing", 0.0)
						Sounds.fireLoop:stop()
						isCounting = false
						countdown = 3
					end
					setCannonCamZoom()
					if countdown == 0 then
						Sounds.fireLoop:stop()
						state = 1
					end
					if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(2, 202) then
						fadingTimer.reset()
						state = 2
					end
				elseif state == 1 then
					chargeLvl = 0.0
					local effect = Effect.new("scr_xm_orbital", "scr_xm_orbital_blast")
					STREAMING.REQUEST_NAMED_PTFX_ASSET(effect.asset)
					while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(effect.asset) do
						util.yield()
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
					PAD.SET_PAD_SHAKE(0, 500, 256)
					fadingTimer.reset()
					state = 2
					didShoot = true
				elseif state == 2 then
					if CAM.IS_SCREEN_FADED_OUT() then
						if fadingTimer.elapsed() > 1000 then
							state = 3
						end
					elseif not didShoot or fadingTimer.elapsed() > 1000 then
						CAM.DO_SCREEN_FADE_OUT(800)
						fadingTimer.reset()
					end
				elseif state == 3 then
					Sounds.backgroundLoop:stop()
					Sounds.fireLoop:stop()
					Sounds.zoomOut:stop()
					Sounds.activating:stop()

					ENTITY.FREEZE_ENTITY_POSITION(PLAYER.PLAYER_PED_ID(), false)
					PLAYER.DISABLE_PLAYER_FIRING(PLAYER.PLAYER_ID(), false)
					menu.trigger_commands("becomeorbitalcannon off")

					GRAPHICS.ANIMPOSTFX_STOP("MP_OrbitalCannon")
					AUDIO.STOP_AUDIO_SCENE("dlc_xm_orbital_cannon_camera_active_scene")
					AUDIO.RELEASE_NAMED_SCRIPT_AUDIO_BANK("DLC_CHRISTMAS2017/XM_ION_CANNON")
					set_streamed_texture_dict_as_no_longer_needed("helicopterhud")

					CAM.RENDER_SCRIPT_CAMS(false, false, 0, true, false, 0)
					CAM.SET_CAM_ACTIVE(cam, false)
					CAM.DESTROY_CAM(cam, false)
					STREAMING.CLEAR_FOCUS()

					local pScaleform = memory.alloc_int()
					memory.write_int(pScaleform, scaleform)
					GRAPHICS.SET_SCALEFORM_MOVIE_AS_NO_LONGER_NEEDED(pScaleform)

					util.yield(800)
					CAM.DO_SCREEN_FADE_IN(800)
					gUsingOrbitalCannon = false
					break
				end

				if Instructional:begin() then
					Instructional.add_control(202, "HUD_INPUT3")
					if PAD._IS_USING_KEYBOARD(0) then
						Instructional.add_control(242, "ORB_CAN_ZOOMO")
						Instructional.add_control(241, "ORB_CAN_ZOOMI")
					else
						Instructional.add_control(221, "ORB_CAN_ZOOM")
					end
					Instructional.add_control(24, "ORB_CAN_FIRE")
        			Instructional:set_background_colour(0, 0, 0, 80)
        			Instructional:draw()
				end

				PAD.DISABLE_CONTROL_ACTION(0, 24, true)
				PAD.DISABLE_CONTROL_ACTION(0, 257, true)
				PAD.DISABLE_CONTROL_ACTION(0, 84, true)
				PAD.DISABLE_CONTROL_ACTION(0, 85, true)
				PAD.DISABLE_CONTROL_ACTION(0, 142, true)
				PAD.DISABLE_CONTROL_ACTION(0, 141, true)
				PAD.DISABLE_CONTROL_ACTION(0, 140, true)
				PAD.DISABLE_CONTROL_ACTION(0, 263, true)
				PAD.DISABLE_CONTROL_ACTION(0, 264, true)
				PAD.DISABLE_CONTROL_ACTION(0, 143, true)
				PAD.DISABLE_CONTROL_ACTION(2, 200, true)
				HUD._HUD_WEAPON_WHEEL_IGNORE_SELECTION()
				HUD.HIDE_HUD_AND_RADAR_THIS_FRAME()

				GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SET_CHARGING_LEVEL")
				GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(chargeLvl)
				GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

				GRAPHICS.SET_SCRIPT_GFX_DRAW_ORDER(0)
				GRAPHICS.DRAW_SCALEFORM_MOVIE_FULLSCREEN(scaleform, 255, 255, 255, 255, 0)
				GRAPHICS.RESET_SCRIPT_GFX_ALIGN()
			end
		end
	end)

	-------------------------------------
	-- SHAKE CAMERA
	-------------------------------------

	menu.toggle_loop(trollingOpt, translate("Trolling", "Shake Camera"), {"shake"}, "", function()
		if not players.exists(pId) then
			util.stop_thread()
		end
		local pos = players.get_position(pId)
		FIRE.ADD_OWNED_EXPLOSION(PLAYER.PLAYER_PED_ID(), pos.x, pos.y, pos.z, 0, 0, false, true, 80)
		util.yield(150)
	end)

	-------------------------------------
	-- ATTACKER OPTIONS
	-------------------------------------

	local attacker = {
		stationary 	= false,
		godmode = false
	}
	local count = 1
	---@type WeaponList
	local weaponList
	local attackerOpt <const> = menu.list(trollingOpt, translate("Trolling", "Attacker Options"), {}, "")

	-------------------------------------
	-- SPAWN ATTACKER
	-------------------------------------

	---@param ped integer
	---@param weaponHash integer #the hash of the weapon the attacker is going to recieve
	local make_attacker = function (ped, targetId, weaponHash)
		set_decor_flag(ped, DecorFlag_isAttacker)
		PED.SET_PED_MAX_HEALTH(ped, 500)
		ENTITY.SET_ENTITY_HEALTH(ped, 500, 0)
		WEAPON.GIVE_WEAPON_TO_PED(ped, weaponHash, -1, true, true)
		WEAPON.SET_CURRENT_PED_WEAPON(ped, weaponHash, false)
		ENTITY.SET_ENTITY_INVINCIBLE(ped, attacker.godmode)
		if attacker.stationary then
			PED.SET_PED_COMBAT_MOVEMENT(ped, 0)
		else
			PED.SET_PED_COMBAT_MOVEMENT(ped, 2)
		end
		PED.SET_PED_COMBAT_ATTRIBUTES(ped, 46, true)
		PED.SET_PED_COMBAT_ATTRIBUTES(ped, 0, false)
		PED.SET_RAGDOLL_BLOCKING_FLAGS(ped, 1)
		PED.SET_PED_TARGET_LOSS_RESPONSE(ped, 2)
		PED.SET_PED_CONFIG_FLAG(ped, 208, true)
		PED.SET_PED_HEARING_RANGE(ped, 150.0)
		PED.SET_PED_SEEING_RANGE(ped, 150.0)
		local blip = add_ai_blip_for_ped(ped, true, false, 250.0, -1, -1)
		set_blip_name(blip, "blip_4zyc6f", true) -- random collision for 0xB1122704

		util.create_tick_handler(function ()
			local target = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(targetId)
			local pedPos = ENTITY.GET_ENTITY_COORDS(ped, false)
			if not ENTITY.DOES_ENTITY_EXIST(ped) or ENTITY.IS_ENTITY_DEAD(ped, false) then
				return false
			elseif not ENTITY.DOES_ENTITY_EXIST(target) or not NETWORK.NETWORK_IS_PLAYER_CONNECTED(targetId) or
			players.get_position(targetId):distance(pedPos) > 250.0 and not PED.IS_PED_INJURED(ped) then
				remove_decor(ped)
				PED.SET_PED_COMBAT_ATTRIBUTES(ped, 46, false)
				WEAPON.REMOVE_ALL_PED_WEAPONS(ped, true)
				HUD.SET_PED_HAS_AI_BLIP(ped, false)
				TASK.CLEAR_PED_TASKS(ped)
				PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, false)
				TASK.TASK_WANDER_STANDARD(ped, 10.0, 10)
				PED.SET_PED_KEEP_TASK(ped, true)
				local pHandle = memory.alloc_int()
				memory.write_int(pHandle, ped)
				ENTITY.SET_PED_AS_NO_LONGER_NEEDED(pHandle)
				return false
			elseif not PED.IS_PED_IN_COMBAT(ped, target) and not ENTITY.IS_ENTITY_DEAD(target, 0) then
				TASK.CLEAR_PED_TASKS(ped)
				PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
				TASK.TASK_COMBAT_PED(ped, target, 0, 16)
			end
		end)
	end

	local menu_name <const> = translate("Trolling - Attacker Options", "Spawn Attacker")
	ModelList.new(attackerOpt, menu_name, "", "", attackerList, function (caption, model)
		local i = 0
		local modelHash <const> = util.joaat(model)
		request_model(modelHash)
		repeat
			i = i + 1
			local targetPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pId)
			local pos = get_random_offset_in_range(targetPed, 2.0, 4.0)
			pos.z = pos.z - 1.0
			local ped = entities.create_ped(0, modelHash, pos, 0.0)
			NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(NETWORK.PED_TO_NET(ped), true)
			ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ped, false, true)
			NETWORK.SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER(NETWORK.PED_TO_NET(ped), PLAYER.PLAYER_ID(), true)
			ENTITY.SET_ENTITY_LOAD_COLLISION_FLAG(ped, true, 1)
			set_entity_face_entity(ped, targetPed, false)
			local weapon <const> = weaponList.selected or table.random(Weapons)
			local weaponHash <const> = util.joaat(weapon)
			make_attacker(ped, pId, weaponHash)
			util.yield(200)
		until count == i
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(modelHash)
	end, false)

	-------------------------------------
	-- CLONE ATTACKER
	-------------------------------------

	menu.action(attackerOpt, translate("Trolling - Attacker Options", "Clone Player (Enemy)"), {}, "", function()
		local i = 0
		repeat
			i = i + 1
			local target = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pId)
			local pos = get_random_offset_in_range(target, 2.0, 4.0)
			pos.z = pos.z - 1.0
			local clone = entities.create_ped(4, ENTITY.GET_ENTITY_MODEL(target), pos, 0)
			NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(NETWORK.PED_TO_NET(clone), true)
			ENTITY.SET_ENTITY_AS_MISSION_ENTITY(clone, false, true)
			NETWORK.SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER(NETWORK.PED_TO_NET(clone), PLAYER.PLAYER_ID(), true)
			ENTITY.SET_ENTITY_LOAD_COLLISION_FLAG(clone, true, 1)
			PED.CLONE_PED_TO_TARGET(target, clone)
			set_entity_face_entity(clone, target, false)
			local weapon <const> = weaponList.selected or table.random(Weapons)
			local weaponHash <const> = util.joaat(weapon)
			make_attacker(clone, pId, weaponHash)
			util.yield(200)
		until count == i
	end)

	-- Set weapon
	weaponList = WeaponList.new(attackerOpt, translate("Trolling - Attacker Options", "Set Weapon"), "", "", nil, true)

	-------------------------------------
	-- ENEMY CHOP
	-------------------------------------

	menu.action(attackerOpt, translate("Trolling - Attacker Options", "Enemy Chop"), {}, "", function()
		local i = 0
		local pedHash <const> = util.joaat("a_c_chop")
		request_model(pedHash)
		repeat
			i = i + 1
			local target = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pId)
			local pos = get_random_offset_in_range(target, 2.0, 4.0)
			pos.z = pos.z - 1.0
			local ped = entities.create_ped(28, pedHash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
			NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(NETWORK.PED_TO_NET(ped), true)
			ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ped, false, true)
			NETWORK.SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER(NETWORK.PED_TO_NET(ped), PLAYER.PLAYER_ID(), true)
			ENTITY.SET_ENTITY_LOAD_COLLISION_FLAG(ped, true, 1)
			set_entity_face_entity(ped, target, false)
			make_attacker(ped, pId, util.joaat("weapon_animal"))
			util.yield(200)
		until count == i;
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(pedHash)
	end)

	menu.slider(attackerOpt, translate("Trolling - Attacker Options", "Count"), {}, "",
		1, 10, 1, 1, function(value) count = value end)

	-------------------------------------
	-- SEND POLICE CAR
	-------------------------------------

	menu.action(attackerOpt, translate("Trolling - Attacker Options", "Send Police Car"), {}, "", function()
		local targetPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pId)
		local offset = get_random_offset_in_range(targetPed, 50.0, 60.0)
		local outCoords = v3.new()
		local outHeading = memory.alloc(4)
		if PATHFIND.GET_CLOSEST_VEHICLE_NODE_WITH_HEADING(offset.x, offset.y, offset.z, outCoords, outHeading, 1, 3.0, 0) then
			local vehicleHash <const> = util.joaat("police3")
			local pedHash <const> = util.joaat("s_m_y_cop_01")
			request_model(vehicleHash); request_model(pedHash)

			local pos = ENTITY.GET_ENTITY_COORDS(targetPed, false)
			local vehicle = entities.create_vehicle(vehicleHash, pos, 0.0)
			if not ENTITY.DOES_ENTITY_EXIST(vehicle) then return end
			ENTITY.SET_ENTITY_COORDS(vehicle, outCoords.x, outCoords.y, outCoords.z, 0, 0, 0, false)
			ENTITY.SET_ENTITY_HEADING(vehicle, memory.read_float(outHeading))
			VEHICLE.SET_VEHICLE_SIREN(vehicle, true)
			AUDIO.BLIP_SIREN(vehicle)
			VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle, true, true, true)
			ENTITY.SET_ENTITY_INVINCIBLE(vehicle, attacker.godmode)

			local pSequence = memory.alloc_int()
			TASK.OPEN_SEQUENCE_TASK(pSequence)
			TASK.TASK_COMBAT_PED(0, targetPed, 0, 16)
			TASK.TASK_GO_TO_ENTITY(0, targetPed, 6000, 10.0, 3.0, 0, 0)
			local sequence = memory.read_int(pSequence)
			TASK.SET_SEQUENCE_TO_REPEAT(sequence, true)
			TASK.CLOSE_SEQUENCE_TASK(sequence)

			for seat = -1, 0 do
				local cop = entities.create_ped(5, pedHash, outCoords, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
				ENTITY.SET_ENTITY_AS_MISSION_ENTITY(cop, 1, 1)
				set_decor_flag(cop, DecorFlag_isAttacker)
				PED.SET_PED_INTO_VEHICLE(cop, vehicle, seat)
				PED.SET_PED_RANDOM_COMPONENT_VARIATION(cop, 0)
				local weapon <const> = (seat == -1) and "weapon_pistol" or "weapon_pumpshotgun"
				WEAPON.GIVE_WEAPON_TO_PED(cop, util.joaat(weapon), -1, false, true)
				PED.SET_PED_COMBAT_ATTRIBUTES(cop, 1, true)
				PED.SET_PED_AS_COP(cop, true)
				ENTITY.SET_ENTITY_INVINCIBLE(cop, attacker.godmode)
				TASK.TASK_PERFORM_SEQUENCE(cop, sequence)
			end

			TASK.CLEAR_SEQUENCE_TASK(pSequence)
			AUDIO.PLAY_POLICE_REPORT("SCRIPTED_SCANNER_REPORT_FRANLIN_0_KIDNAP", 0.0)
		end
	end)


	menu.toggle(attackerOpt, translate("Trolling - Attacker Options", "Invincible Attackers"), {}, "",
		function(toggle) attacker.godmode = toggle end)

	menu.toggle(attackerOpt, translate("Trolling - Attacker Options", "Stationary"), {}, "",
		function(toggle) attacker.stationary = toggle end)

	menu.action(attackerOpt, translate("Trolling - Attacker Options", "Delete Attackers"), {}, "", function()
		for _, ped in ipairs(entities.get_all_peds_as_handles()) do
			if is_decor_flag_set(ped, DecorFlag_isAttacker) then entities.delete_by_handle(ped) end
		end
	end)

	-------------------------------------
	-- CAGE OPTIONS
	-------------------------------------

	local cageOptions <const> = menu.list(trollingOpt, translate("Trolling", "Cage"), {}, "")

	---@param pId Player
	local function trapcage(pId) -- small
		local objHash <const> = util.joaat("prop_gold_cont_01")
		request_model(objHash)
		local pos = players.get_position(pId)
		local obj = entities.create_object(objHash, pos)
		ENTITY.FREEZE_ENTITY_POSITION(obj, true)
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(objHash)
	end

	---@param pId Player
	local function trapcage_2(pId) -- tall
		local objHash <const> = util.joaat("prop_rub_cage01a")
		request_model(objHash)
		local pos = players.get_position(pId)
		local obj1 = entities.create_object(objHash, v3.new(pos.x, pos.y, pos.z - 1.0))
		local obj2 = entities.create_object(objHash, v3.new(pos.x, pos.y, pos.z + 1.2))
		ENTITY.SET_ENTITY_ROTATION(obj2, -180.0, ENTITY.GET_ENTITY_ROTATION(obj2, 2).y, 90.0, 1, true)
		ENTITY.FREEZE_ENTITY_POSITION(obj1, true)
		ENTITY.FREEZE_ENTITY_POSITION(obj2, true)
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(objHash)
	end

	menu.action(cageOptions, translate("Trolling - Cage", "Small"), {"smallcage"}, "", function()
		local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pId)
		TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
		if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then return end
		trapcage(pId)
	end, nil, nil, COMMANDPERM_AGGRESSIVE)

	menu.action(cageOptions, translate("Trolling - Cage", "Tall"), {"tallcage"}, "", function()
		local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pId)
		TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
		if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then return end
		trapcage_2(pId)
	end, nil, nil, COMMANDPERM_AGGRESSIVE)

	-------------------------------------
	-- AUTOMATIC
	-------------------------------------

	local notifmsg = translate("Trolling - Cage", "<C>%s</C> was out of the cage")

	-- 1) traps the player in cage
	-- 2) gets the position of the cage
	-- 3) if the current player position is 4 m away from the cage, another one is created.
	local cagePos
	local timer <const> = newTimer()
	menu.toggle_loop(cageOptions, translate("Trolling - Cage", "Automatic"), {"autocage"}, "", function()
		if not players.exists(pId) then
			util.stop_thread()
		end
		if timer.elapsed() >= 1000 and NETWORK.NETWORK_IS_PLAYER_CONNECTED(pId) then
			local targetPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pId)
			local playerPos = ENTITY.GET_ENTITY_COORDS(targetPed, false)
			if not cagePos or cagePos:distance(playerPos) >= 4.0 then
				TASK.CLEAR_PED_TASKS_IMMEDIATELY(targetPed)
				if PED.IS_PED_IN_ANY_VEHICLE(targetPed, false) then return end
				cagePos = playerPos
				trapcage(pId)
				local playerName = PLAYER.GET_PLAYER_NAME(pId)
				if playerName ~= "**Invalid**" then
					notification:normal(notifmsg, HudColour.black, playerName)
				end
			end
			timer.reset()
		end
	end)

	-------------------------------------
	-- FENCE
	-------------------------------------

	menu.action(cageOptions, translate("Trolling - Cage", "Fence"), {"fence"}, "", function()
		local objHash <const> = util.joaat("prop_fnclink_03e")
		request_model(objHash)
		local pos = players.get_position(pId)
		pos.z = pos.z - 1.0
		local object = {}
		object[1] = entities.create_object(objHash, v3.new(pos.x - 1.5, pos.y + 1.5, pos.z))
		object[2] = entities.create_object(objHash, v3.new(pos.x - 1.5, pos.y - 1.5, pos.z))

		object[3] = entities.create_object(objHash, v3.new(pos.x + 1.5, pos.y + 1.5, pos.z))
		local rot_3 = ENTITY.GET_ENTITY_ROTATION(object[3], 2)
		rot_3.z = -90.0
		ENTITY.SET_ENTITY_ROTATION(object[3], rot_3.x, rot_3.y, rot_3.z, 1, true)

		object[4] = entities.create_object(objHash, v3.new(pos.x - 1.5, pos.y + 1.5, pos.z))
		local rot_4 = ENTITY.GET_ENTITY_ROTATION(object[4], 2)
		rot_4.z = -90.0
		ENTITY.SET_ENTITY_ROTATION(object[4], rot_4.x, rot_4.y, rot_4.z, 1, true)
		for _, obj in ipairs(object) do
			ENTITY.FREEZE_ENTITY_POSITION(obj, true)
		end
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(objHash)
	end, nil, nil, COMMANDPERM_AGGRESSIVE)

	-------------------------------------
	-- STUNT TUBE
	-------------------------------------

	menu.action(cageOptions, translate("Trolling - Cage", "Stunt Tube"), {"stunttube"}, "", function()
		local hash <const> = util.joaat("stt_prop_stunt_tube_s")
		request_model(hash)
		local pos = players.get_position(pId)
		local obj = entities.create_object(hash, pos)
		local rot = ENTITY.GET_ENTITY_ROTATION(obj, 2)
		ENTITY.SET_ENTITY_ROTATION(obj, rot.x, 90.0, rot.z, 1, true)
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
	end, nil, nil, COMMANDPERM_AGGRESSIVE)

	-------------------------------------
	-- RAPE
	-------------------------------------

	local helpText = translate("Trolling", "The player won't see you attached to them")
	menu.toggle(trollingOpt, translate("Trolling", "Rape"), {}, helpText, function (toggle)
		gUsingRape = toggle
		-- Otherwise the game would crash
		if pId == PLAYER.PLAYER_ID() then return end
		if gUsingRape then
			gUsingPiggyback = false
			local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pId)
			STREAMING.REQUEST_ANIM_DICT("rcmpaparazzo_2")
			while not STREAMING.HAS_ANIM_DICT_LOADED("rcmpaparazzo_2") do
				util.yield()
			end
			TASK.TASK_PLAY_ANIM(PLAYER.PLAYER_PED_ID(), "rcmpaparazzo_2", "shag_loop_a", 8, -8, -1, 1, 0, false, false, false)
			ENTITY.ATTACH_ENTITY_TO_ENTITY(PLAYER.PLAYER_PED_ID(), p, 0, 0, -0.3, 0, 0, 0, 0, false, true, false, false, 0, true)
			while gUsingRape do
				util.yield()
				if not NETWORK.NETWORK_IS_PLAYER_CONNECTED(pId) then gUsingRape = false end
			end
			TASK.CLEAR_PED_TASKS_IMMEDIATELY(PLAYER.PLAYER_PED_ID())
			ENTITY.DETACH_ENTITY(PLAYER.PLAYER_PED_ID(), true, false)
		end
	end)

	-------------------------------------
	-- ENEMY VEHICLES
	-------------------------------------

	local enemyVehiclesOpt <const> = menu.list(trollingOpt, translate("Trolling", "Enemy Vehicles"), {}, "")
	local options <const> = {"Minitank", "Buzzard", "Lazer"}
	local setGodmode = false
	local gunnerWeapon = util.joaat("weapon_mg")
	local weaponModId = -1
	local count = 1

	---@param targetId integer
	local function spawn_minitank(targetId)
		local vehicleHash <const> = util.joaat("minitank")
		local pedHash <const> = util.joaat("s_m_y_blackops_01")
		request_model(vehicleHash); request_model(pedHash)
		local pos = players.get_position(targetId)
		local vehicle = entities.create_vehicle(vehicleHash, pos, 0.0)
		if not ENTITY.DOES_ENTITY_EXIST(vehicle) then
			return
		end
		NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(NETWORK.VEH_TO_NET(vehicle), true)
		ENTITY.SET_ENTITY_AS_MISSION_ENTITY(vehicle, false, true)
		NETWORK.SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER(NETWORK.VEH_TO_NET(vehicle), PLAYER.PLAYER_ID(), true)
		ENTITY.SET_ENTITY_LOAD_COLLISION_FLAG(vehicle, true, 1)
		set_decor_flag(vehicle, DecorFlag_isEnemyVehicle)
		local offset = get_random_offset_in_range(vehicle, 35.0, 50.0)
		local outHeading = memory.alloc(4)
		local outCoords = v3.new()
		if PATHFIND.GET_CLOSEST_VEHICLE_NODE_WITH_HEADING(offset.x, offset.y, offset.z, outCoords, outHeading, 1, 3.0, 0) then
			local driver = entities.create_ped(5, pedHash, offset, 0.0)
			NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(NETWORK.PED_TO_NET(driver), true)
			ENTITY.SET_ENTITY_AS_MISSION_ENTITY(driver, false, true)
			NETWORK.SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER(NETWORK.PED_TO_NET(driver), PLAYER.PLAYER_ID(), true)
			ENTITY.SET_ENTITY_LOAD_COLLISION_FLAG(driver, true, 1)
			ENTITY.SET_ENTITY_INVINCIBLE(driver, true)
			PED.SET_PED_INTO_VEHICLE(driver, vehicle, -1)
			AUDIO.STOP_PED_SPEAKING(driver, true)
			PED.SET_PED_COMBAT_ATTRIBUTES(driver, 46, true)
			PED.SET_PED_COMBAT_ATTRIBUTES(driver, 1, true)
			PED.SET_PED_COMBAT_ATTRIBUTES(driver, 3, false)
			PED.SET_PED_COMBAT_RANGE(driver, 2)
			PED.SET_PED_SEEING_RANGE(driver, 1000.0)
			PED.SET_PED_SHOOT_RATE(driver, 1000)
			PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(driver, true)
			TASK.SET_DRIVE_TASK_DRIVING_STYLE(driver, 786468)

			ENTITY.SET_ENTITY_COORDS(vehicle, outCoords.x, outCoords.y, outCoords.z, 0, 0, 0, false)
			ENTITY.SET_ENTITY_HEADING(vehicle, memory.read_float(outHeading))
			ENTITY.SET_ENTITY_INVINCIBLE(vehicle, setGodmode)
			VEHICLE.SET_VEHICLE_MOD_KIT(vehicle, 0)
			VEHICLE.SET_VEHICLE_MOD(vehicle, 10, weaponModId, false)
			VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle, true, true, true)
			local blip = add_blip_for_entity(vehicle, 742, 4)

			util.create_tick_handler(function()
				local target = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(targetId)
				local vehPos = ENTITY.GET_ENTITY_COORDS(vehicle, false)
				if not ENTITY.DOES_ENTITY_EXIST(vehicle) or ENTITY.IS_ENTITY_DEAD(vehicle, 0) or
				not ENTITY.DOES_ENTITY_EXIST(driver) or PED.IS_PED_INJURED(driver) then
					return false
				elseif not PED.IS_PED_IN_COMBAT(driver, target) and not PED.IS_PED_INJURED(target) then
					TASK.CLEAR_PED_TASKS(driver)
					TASK.TASK_COMBAT_PED(driver, target, 0, 16)
					PED.SET_PED_KEEP_TASK(driver, true)
				elseif not NETWORK.NETWORK_IS_PLAYER_CONNECTED(targetId) or
				not ENTITY.DOES_ENTITY_EXIST(target) or players.get_position(targetId):distance(vehPos) > 1000.0 then
					TASK.CLEAR_PED_TASKS(driver)
					PED.SET_PED_COMBAT_ATTRIBUTES(driver, 46, false)
					TASK.TASK_VEHICLE_DRIVE_WANDER(driver, vehicle, 10.0, 786603)
					PED.SET_PED_KEEP_TASK(driver, true)
					remove_decor(vehicle)
					util.remove_blip(blip)
					local pVehicle = memory.alloc_int()
					memory.write_int(pVehicle, vehicle)
					ENTITY.SET_VEHICLE_AS_NO_LONGER_NEEDED(pVehicle)
					return false
				end
			end)
		end
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(vehicleHash)
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(pedHash)
	end

	---@param targetId integer
	local function spawn_buzzard(targetId)
		local vehicleHash <const> = util.joaat("buzzard")
		local pedHash <const> = util.joaat("s_m_y_blackops_01")
		request_model(vehicleHash);	request_model(pedHash)
		local target = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(targetId)
		local playerRelGroup = PED.GET_PED_RELATIONSHIP_GROUP_HASH(target)
		PED.SET_RELATIONSHIP_BETWEEN_GROUPS(5, util.joaat("ARMY"), playerRelGroup)
		PED.SET_RELATIONSHIP_BETWEEN_GROUPS(5, playerRelGroup, util.joaat("ARMY"))
		PED.SET_RELATIONSHIP_BETWEEN_GROUPS(0, util.joaat("ARMY"), util.joaat("ARMY"))

		local pos = players.get_position(targetId)
		local heli = entities.create_vehicle(vehicleHash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
		if ENTITY.DOES_ENTITY_EXIST(heli) then
			NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(NETWORK.VEH_TO_NET(heli), true)
			ENTITY.SET_ENTITY_AS_MISSION_ENTITY(heli, false, true)
			NETWORK.SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER(NETWORK.VEH_TO_NET(heli), PLAYER.PLAYER_ID(), true)
			ENTITY.SET_ENTITY_LOAD_COLLISION_FLAG(heli, true, 1)
			set_decor_flag(heli, DecorFlag_isEnemyVehicle)
			local pos = get_random_offset_in_range(target, 20, 40)
			pos.z = pos.z + 20.0
			ENTITY.SET_ENTITY_COORDS(heli, pos.x, pos.y, pos.z, false, false, false, false)
			NETWORK.SET_NETWORK_ID_CAN_MIGRATE(NETWORK.VEH_TO_NET(heli), false)
			ENTITY.SET_ENTITY_INVINCIBLE(heli, setGodmode)
			VEHICLE.SET_VEHICLE_ENGINE_ON(heli, true, true, true)
			VEHICLE.SET_HELI_BLADES_FULL_SPEED(heli)
			local blip = add_blip_for_entity(heli, 422, 4)
			set_blip_name(blip, "buzzard2", true)

			local pilot = entities.create_ped(29, pedHash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
			PED.SET_PED_INTO_VEHICLE(pilot, heli, -1)
			PED.SET_PED_MAX_HEALTH(pilot, 500)
			ENTITY.SET_ENTITY_HEALTH(pilot, 500, 0)
			ENTITY.SET_ENTITY_INVINCIBLE(pilot, setGodmode)
			PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(pilot, true)
			PED.SET_PED_KEEP_TASK(pilot, true)
			TASK.TASK_HELI_MISSION(pilot, heli, 0, target, 0.0, 0.0, 0.0, 23, 40.0, 40.0, -1.0, 0, 10, -1.0, 0)
			for seat = 1, 2 do
				local ped = entities.create_ped(29, pedHash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
				PED.SET_PED_INTO_VEHICLE(ped, heli, seat)
				WEAPON.GIVE_WEAPON_TO_PED(ped, gunnerWeapon, -1, false, true)
				PED.SET_PED_COMBAT_ATTRIBUTES(ped, 20, true)
				PED.SET_PED_MAX_HEALTH(ped, 500)
				ENTITY.SET_ENTITY_HEALTH(ped, 500, 0)
				ENTITY.SET_ENTITY_INVINCIBLE(ped, setGodmode)
				PED.SET_PED_SHOOT_RATE(ped, 1000)
				PED.SET_PED_RELATIONSHIP_GROUP_HASH(ped, util.joaat("ARMY"))
				TASK.TASK_COMBAT_HATED_TARGETS_AROUND_PED(ped, 200, 0)
			end
		end
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(pedHash)
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(vehicleHash)
	end

	---@param targetId integer
	local function spawn_lazer(targetId)
		local jetHash <const> = util.joaat("lazer")
		local pedHash <const> = util.joaat("s_m_y_blackops_01")
		request_model(jetHash); request_model(pedHash)
		local target = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(targetId)
		local pos = players.get_position(targetId)
		local jet = entities.create_vehicle(jetHash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
		if ENTITY.DOES_ENTITY_EXIST(jet) then
			NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(NETWORK.VEH_TO_NET(jet), true)
		ENTITY.SET_ENTITY_AS_MISSION_ENTITY(jet, false, true)
		NETWORK.SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER(NETWORK.VEH_TO_NET(jet), players.user(), true)
		ENTITY.SET_ENTITY_LOAD_COLLISION_FLAG(jet, true, 1)
			set_decor_flag(jet, DecorFlag_isEnemyVehicle)
			local pos = get_random_offset_in_range(jet, 30, 80)
			pos.z = pos.z + 500
			ENTITY.SET_ENTITY_COORDS(jet, pos.x, pos.y, pos.z, 0, 0, 0, 0)
			set_entity_face_entity(jet, target, false)
			local blip = add_blip_for_entity(jet, 16, 4)
			set_blip_name(blip, "blip_4xz66m0", true) -- random collision for 0x2257C97F
			VEHICLE.CONTROL_LANDING_GEAR(jet, 3)
			ENTITY.SET_ENTITY_INVINCIBLE(jet, setGodmode)
			VEHICLE.SET_VEHICLE_FORCE_AFTERBURNER(jet, true)

			local pilot = entities.create_ped(5, pedHash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
			ENTITY.SET_ENTITY_AS_MISSION_ENTITY(pilot, false, true)
			PED.SET_PED_INTO_VEHICLE(pilot, jet, -1)
			TASK.TASK_PLANE_MISSION(pilot, jet, 0, target, 0.0, 0.0, 0.0, 6, 100.0, 0, 0.0, 80.0, 50.0, 0)
			PED.SET_PED_COMBAT_ATTRIBUTES(pilot, 1, true)
			relationship:hostile(pilot)
			VEHICLE.SET_VEHICLE_FORWARD_SPEED(jet, 60)
		end
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(jetHash)
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(pedHash)
	end


	menu.action_slider(enemyVehiclesOpt, translate("Trolling - Enemy Vehicles", "Send Enemy Vehicle"), {}, "", options, function(index, optName)
		local i = 0
		repeat
			if optName == "Buzzard" then spawn_buzzard(pId)
			elseif optName == "Minitank" then spawn_minitank(pId)
			elseif optName == "Lazer" then spawn_lazer(pId) end
			i = i + 1
			util.yield(200)
		until i == count;
	end)


	local  minitankModIds <const> =
	{
		stockWeapon = -1,
		plasmaCannon = 1,
		rocket = 2,
	}
	local options <const> = {
		util.get_label_text("WT_V_PLRBUL"),
		util.get_label_text("MINITANK_WEAP2"),
		util.get_label_text("MINITANK_WEAP3"),
	}
	menu.slider_text(enemyVehiclesOpt, translate("Trolling - Enemy Vehicles", "Minitank Weapon"), {}, "", options, function(index)
		if index == 1 then
			weaponModId = minitankModIds.stockWeapon
		elseif index == 2 then
			weaponModId = minitankModIds.plasmaCannon
		elseif index == 3 then
			weaponModId = minitankModIds.rocket
		else
			error("got unexpected option")
		end
	end)

	-- Gunners weapon
	local gunnerWeapons <const> = {"weapon_mg", "weapon_rpg"}
	local options <const> =	{util.get_label_text("WT_MG"), util.get_label_text("WT_RPG")}
	menu.slider_text(enemyVehiclesOpt, translate("Trolling - Enemy Vehicles", "Gunners Weapon"), {}, "", options, function(index)
		gunnerWeapon = util.joaat(gunnerWeapons[index])
	end)

	menu.slider(enemyVehiclesOpt, translate("Trolling - Enemy Vehicles", "Count"), {}, "",
		1, 10, 1, 1, function (value) count = value end)

	-- Invincible
	menu.toggle(enemyVehiclesOpt, translate("Trolling - Enemy Vehicles", "Invincible"), {}, "",
		function(toggle) setGodmode = toggle end)

	local deleteVehiclePassengers = function(vehicle)
		for seat = -1, VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(vehicle) -1 do
			if VEHICLE.IS_VEHICLE_SEAT_FREE(vehicle, seat, false) then
				goto LABEL_CONTINUE
			end
			local passenger = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, seat, 0)
			if request_control(passenger, 1000) then entities.delete_by_handle(passenger) end
		::LABEL_CONTINUE::
		end
	end

	-- Delete enemy vehicles
	menu.action(enemyVehiclesOpt, translate("Trolling - Enemy Vehicles", "Delete"), {}, "", function()
		for _, vehicle in ipairs(entities.get_all_vehicles_as_handles()) do
			if is_decor_flag_set(vehicle, DecorFlag_isEnemyVehicle) and request_control(vehicle, 1000) then
				deleteVehiclePassengers(vehicle)
				entities.delete_by_handle(vehicle)
			end
		end
	end)

	-------------------------------------
	-- DAMAGE
	-------------------------------------

	local helpText <const> =
	translate("Trolling - Damage", "Choose the weapon and shoot 'em no matter where you are")
	local damageOpt <const> = menu.list(trollingOpt, translate("Trolling", "Damage"), {}, helpText)
	local lastStunGunShot = newTimer()

	menu.toggle(damageOpt, translate("Trolling - Damage", "Spectate"), {}, "", function(toggle)
		local reference = menu.ref_by_path("Players>" .. players.get_name_with_tags(pId) .. ">Spectate>Ninja Method", 33)
		menu.trigger_command(reference, toggle and "on" or "off")
	end)


	menu.action(damageOpt, translate("Trolling - Damage", "Heavy Sniper"), {}, "", function()
		local hash <const> = util.joaat("weapon_heavysniper")
		local a = CAM.GET_GAMEPLAY_CAM_COORD()
		local b = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pId), false)
		request_weapon_asset(hash)
		WEAPON.GIVE_WEAPON_TO_PED(PLAYER.PLAYER_PED_ID(), hash, 120, 1, 0)
		MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(a.x, a.y, a.z, b.x, b.y, b.z, 200, 0, hash, players.user_ped(), true, false, 2500.0)
	end)


	menu.action(damageOpt, translate("Trolling - Damage", "Firework"), {}, "", function()
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pId), false)
		local hash <const> = util.joaat("weapon_firework")
		request_weapon_asset(hash)
		WEAPON.GIVE_WEAPON_TO_PED(PLAYER.PLAYER_PED_ID(), hash, 120, 1, 0)
		MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z+3.0, pos.x, pos.y, pos.z-2.0, 200, 0, hash, 0, true, false, 2500.0)
	end)


	menu.action(damageOpt, translate("Trolling - Damage", "Up-n-Atomizer"), {}, "", function()
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pId), false)
		local hash <const> = util.joaat("weapon_raypistol")
		request_weapon_asset(hash)
		WEAPON.GIVE_WEAPON_TO_PED(PLAYER.PLAYER_PED_ID(), hash, 120, 1, 0)
		MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z+3.0, pos.x, pos.y, pos.z-2.0, 200, 0, hash, 0, true, false, 2500.0)
	end)


	menu.action(damageOpt, translate("Trolling - Damage", "Molotov"), {}, "", function()
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pId), false)
		local hash <const> = util.joaat("weapon_molotov")
		request_weapon_asset(hash)
		WEAPON.GIVE_WEAPON_TO_PED(PLAYER.PLAYER_PED_ID(), hash, 120, true, false)
		MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z, pos.x, pos.y, pos.z-2.0, 200, 0, hash, 0, true, false, 2500.0)
	end)


	menu.action(damageOpt, translate("Trolling - Damage", "EMP Launcher"), {}, "", function()
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pId), false)
		local hash <const> = util.joaat("weapon_emplauncher")
		request_weapon_asset(hash)
		WEAPON.GIVE_WEAPON_TO_PED(PLAYER.PLAYER_PED_ID(), hash, 120, true, false)
		MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z, pos.x, pos.y, pos.z-2.0, 200, 0, hash, 0, true, false, 2500.0)
	end)


	menu.toggle_loop(damageOpt, translate("Trolling - Damage", "Taze"), {"taze"}, "", function ()
		if not players.exists(pId) then
			util.stop_thread()
		end
		local hash <const> = util.joaat("weapon_stungun")
		request_weapon_asset(hash)
		if lastStunGunShot.elapsed() > 2500 then
			local pos = players.get_position(pId)
			MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z + 2.0, pos.x, pos.y, pos.z, 0, 0, hash, players.user_ped(), true, false, -1)
			lastStunGunShot.reset()
		end
	end)

	-------------------------------------
	-- HOSTILE PEDS
	-------------------------------------

	menu.toggle_loop(trollingOpt, translate("Trolling", "Hostile Peds"), {}, "", function()
		if not players.exists(pId) then
			util.stop_thread()
		end
		local target = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pId)
		local pSequence = memory.alloc_int()
		TASK.OPEN_SEQUENCE_TASK(pSequence)
		TASK.TASK_LEAVE_ANY_VEHICLE(0, 0, 256)
		TASK.TASK_COMBAT_PED(0, target, 0, 0)
		TASK.TASK_GO_TO_ENTITY(0, target, -1, 80.0, 3.0, 0, 0)
		local sequence = memory.read_int(pSequence)
		TASK.CLOSE_SEQUENCE_TASK(sequence)
		for _, ped in ipairs(get_peds_in_player_range(pId, 70.0)) do
			if not PED.IS_PED_A_PLAYER(ped) and TASK.GET_SEQUENCE_PROGRESS(ped) == -1 then
				request_control_once(ped)
				local weapon = table.random(Weapons)
				PED.SET_PED_COMBAT_ATTRIBUTES(ped, 46, true)
				PED.SET_PED_MAX_HEALTH(ped, 300)
				ENTITY.SET_ENTITY_HEALTH(ped, 300, 0)
				WEAPON.GIVE_WEAPON_TO_PED(ped, util.joaat(weapon), -1, false, true)
				WEAPON.SET_PED_DROPS_WEAPONS_WHEN_DEAD(ped, false)
				TASK.CLEAR_PED_TASKS(ped)
				TASK.TASK_PERFORM_SEQUENCE(ped, sequence)
				relationship:hostile(ped)
			end
		end
		TASK.CLEAR_SEQUENCE_TASK(pSequence)
	end)

	-------------------------------------
	-- HOSTILE TRAFFIC
	-------------------------------------

	menu.toggle_loop(trollingOpt, translate("Trolling", "Hostile Traffic"), {}, "", function()
		if not players.exists(pId) then
			util.stop_thread()
		end
		local targetPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pId)
		for _, vehicle in ipairs(get_vehicles_in_player_range(pId, 70.0)) do
			if TASK.GET_ACTIVE_VEHICLE_MISSION_TYPE(vehicle) ~= 6 then
				local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1, 0)
				if ENTITY.DOES_ENTITY_EXIST(driver) and not PED.IS_PED_A_PLAYER(driver) then
					request_control_once(driver)
					PED.SET_PED_MAX_HEALTH(driver, 300)
					ENTITY.SET_ENTITY_HEALTH(driver, 300, 0)
					PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(driver, true)
					TASK.TASK_VEHICLE_MISSION_PED_TARGET(
						driver, vehicle, targetPed, 6, 100, 0, 0, 0, true)
				end
			end
		end
	end)

	-------------------------------------
	-- TROLLY VEHICLES
	-------------------------------------

	local function create_trolly_vehicle(targetId, vehicleHash, pedHash)
		request_model(vehicleHash); request_model(pedHash)
		local targetPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(targetId)
		local pos = ENTITY.GET_ENTITY_COORDS(targetPed, false)
		local driver = 0
		local vehicle = entities.create_vehicle(vehicleHash, pos, 0.0)
		NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(NETWORK.VEH_TO_NET(vehicle), true)
		ENTITY.SET_ENTITY_AS_MISSION_ENTITY(vehicle, false, true)
		NETWORK.SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER(NETWORK.VEH_TO_NET(vehicle), players.user(), true)
		ENTITY.SET_ENTITY_LOAD_COLLISION_FLAG(vehicle, true, 1)
		set_decor_flag(vehicle, DecorFlag_isTrollyVehicle)
		VEHICLE.SET_VEHICLE_MOD_KIT(vehicle, 0)
		for i = 0, 50 do
			VEHICLE.SET_VEHICLE_MOD(vehicle, i, VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, i) - 1, false)
		end
		local offset = get_random_offset_in_range(vehicle, 25.0, 25.0)
		local outCoords = v3.new()
		if PATHFIND.GET_CLOSEST_VEHICLE_NODE(offset.x, offset.y, offset.z, outCoords, 1, 3.0, 0) then
			driver = entities.create_ped(5, pedHash, pos, 0.0)
			NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(NETWORK.PED_TO_NET(driver), true)
			ENTITY.SET_ENTITY_AS_MISSION_ENTITY(driver, true, true)
			NETWORK.SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER(NETWORK.PED_TO_NET(driver), players.user(), true)
			ENTITY.SET_ENTITY_LOAD_COLLISION_FLAG(driver, true, 1)
			PED.SET_PED_INTO_VEHICLE(driver, vehicle, -1)
			ENTITY.SET_ENTITY_COORDS(vehicle, outCoords.x, outCoords.y, outCoords.z, false, false, false, true)
			set_entity_face_entity(vehicle, targetPed, false)
			VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle, true, true, true)
			VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(vehicle, true)
			VEHICLE.SET_VEHICLE_IS_CONSIDERED_BY_PLAYER(vehicle, false)
			PED.SET_PED_COMBAT_ATTRIBUTES(driver, 1, true)
			PED.SET_PED_COMBAT_ATTRIBUTES(driver, 3, false)
			PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(driver, true)
			TASK.TASK_VEHICLE_MISSION_PED_TARGET(driver, vehicle, targetPed, 6, 500.0, 786988, 0.0, 0.0, true)
			PED.SET_PED_CAN_BE_KNOCKED_OFF_VEHICLE(driver, 1)
			STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(pedHash)
			STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(vehicleHash)
		end
		return vehicle, driver
	end

	local trollyVehicles <const> = menu.list(trollingOpt, translate("Trolling", "Trolly Vehicles"), {}, "")
	local options <const> = {"Bandito", "Go-Kart"}
	local setInvincible = false
	local count = 1
	local AttackType <const> = {explode = 0, dropMine = 1}
	local attacktype = 0
	local selectedMine = 1
	local mineSlider

	menu.action_slider(trollyVehicles, translate("Trolling", "Send Trolly Vehicle"), {}, "", options, function (index, opt)
		local pedHash <const> = util.joaat("mp_m_freemode_01")
		local i = 0
		repeat
			if opt == "Bandito" then
				local vehicleHash <const> = util.joaat("rcbandito")
				local pedHash <const> = util.joaat("mp_m_freemode_01")
				local vehicle, driver = create_trolly_vehicle(pId, vehicleHash, pedHash)
				add_blip_for_entity(vehicle, 646, 4)
				ENTITY.SET_ENTITY_INVINCIBLE(vehicle, setInvincible)
				ENTITY.SET_ENTITY_VISIBLE(driver, false, 0)
			elseif opt == "Go-Kart" then
				local vehicleHash <const> = util.joaat("veto2")
				local gokart, driver = create_trolly_vehicle(pId, vehicleHash, pedHash)
				ENTITY.SET_ENTITY_INVINCIBLE(gokart, setInvincible)
				VEHICLE.SET_VEHICLE_COLOURS(gokart, 89, 0)
				VEHICLE.TOGGLE_VEHICLE_MOD(gokart, 18, true)
				ENTITY.SET_ENTITY_INVINCIBLE(driver, setInvincible)

				PED.SET_PED_COMPONENT_VARIATION(driver, 3, 111, 13, 2)
				PED.SET_PED_COMPONENT_VARIATION(driver, 4, 67, 5, 2)
				PED.SET_PED_COMPONENT_VARIATION(driver, 6, 101, 1, 2)
				PED.SET_PED_COMPONENT_VARIATION(driver, 8, -1, -1, 2)
				PED.SET_PED_COMPONENT_VARIATION(driver, 11, 148, 5, 2)
				PED.SET_PED_PROP_INDEX(driver, 0, 91, 0, true)

				add_blip_for_entity(gokart, 748, 5)
			end
			i = i + 1
			util.yield(200)
		until i == count
	end)

	menu.toggle(trollyVehicles, translate("Trolling - Trolly Vehicles", "Invincibles"), {}, "",
		function(toggle) setInvincible = toggle end)


	local GetMineHash = function()
		if selectedMine == 1 then
			return util.joaat("vehicle_weapon_mine_kinetic_rc")
		elseif selectedMine == 2 then
			return util.joaat("vehicle_weapon_mine_emp_rc")
		else
			error("unexpected mine index: " .. selectedMine)
		end
	end

	menu.action(trollyVehicles, translate("Trolling - Trolly Vehicles", "Send Armed Bandito"), {}, "", function()
		local vehicleHash <const> = util.joaat("rcbandito")
		local pedHash <const> = util.joaat("mp_m_freemode_01")
		local lastShoot = newTimer()

		local bandito, driver = create_trolly_vehicle(pId, vehicleHash, pedHash)
		VEHICLE.SET_VEHICLE_MOD(bandito, 5, 3, false)
		VEHICLE.SET_VEHICLE_MOD(bandito, 48, 5, false)
		VEHICLE.SET_VEHICLE_MOD(bandito, 9, 0, false)
		VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(bandito, 128, 0, 128)
		VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(bandito, 128, 0, 128)
		ENTITY.SET_ENTITY_VISIBLE(driver, false, 0)
		local blip = add_blip_for_entity(bandito, 646, 27)

		util.create_tick_handler(function()
			if not ENTITY.DOES_ENTITY_EXIST(bandito) or ENTITY.IS_ENTITY_DEAD(bandito, false) or
			not ENTITY.DOES_ENTITY_EXIST(driver) or ENTITY.IS_ENTITY_DEAD(driver, false) then

				set_entity_as_no_longer_needed(bandito)
				set_entity_as_no_longer_needed(driver)
				return false

			elseif NETWORK.NETWORK_IS_PLAYER_CONNECTED(pId) then
				local playerPos = players.get_position(pId)
				local pos = ENTITY.GET_ENTITY_COORDS(bandito, true)

				if playerPos:distance(pos) > 3.0 or not request_control_once(bandito) or
				not request_control_once(driver) then
					return
				end

				if attacktype == AttackType.explode then
					NETWORK.NETWORK_EXPLODE_VEHICLE(bandito, true, false, NETWORK.PARTICIPANT_ID_TO_INT())
					ENTITY.SET_ENTITY_HEALTH(driver, 0, 0)
				elseif attacktype == AttackType.dropMine and
				(not lastShoot.isEnabled() or lastShoot.elapsed() > 1000) and not
				MISC.IS_PROJECTILE_TYPE_WITHIN_DISTANCE(pos.x, pos.y, pos.z, GetMineHash(), 3.0, true) then
					local weapon <const> = GetMineHash()

					if not WEAPON.HAS_WEAPON_ASSET_LOADED(weapon) then
						WEAPON.REQUEST_WEAPON_ASSET(weapon, 31, 26)
						return
					end

					local min, max = v3.new(), v3.new()
					local modelHash = ENTITY.GET_ENTITY_MODEL(bandito)
					MISC.GET_MODEL_DIMENSIONS(modelHash, min, max)

					local coord0 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(bandito, 0.0, min.y, 0.2)
					local coord1 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(bandito, 0.0, min.y, min.z)

					MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS_IGNORE_ENTITY_NEW(
						coord0.x, coord0.y, coord0.z, coord1.x, coord1.y, coord1.z,
						0, true, weapon, players.user(), true, false, -1.0, 0, false, false, 0, true, 1, 0, 0)
					lastShoot.reset()
				end
			elseif request_control(bandito) and request_control(ped) then
				TASK.CLEAR_PED_TASKS(driver)
				TASK.TASK_VEHICLE_DRIVE_WANDER(driver, bandito, 10.0, 786603)
				PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(driver, false)
				remove_decor(bandito)
				util.remove_blip(blip)
				set_entity_as_no_longer_needed(bandito)
				set_entity_as_no_longer_needed(driver)
				return false
			end
		end)
	end)

	local options = {util.get_label_text("BAND_BOMB"), util.get_label_text("TOP_MINE")}
	local menuName = translate("Trolling - Trolly Vehicles", "Bandito Weapon")
	menu.slider_text(trollyVehicles, menuName, {}, "", options, function (index, value)
		if index == 1 then
			attacktype = AttackType.explode
			menu.set_visible(mineSlider, false)
		elseif index == 2 then
			attacktype = AttackType.dropMine
			menu.set_visible(mineSlider, true)
		else
			error("got unexpected index: " .. index)
		end
	end)

	local mines = {util.get_label_text("KINET_MINE"), util.get_label_text("EMP_MINE")}
	local menuName = translate("Trolling - Trolly Vehicles", "Mine")
	mineSlider = menu.slider_text(trollyVehicles, menuName, {}, "", mines, function (index, value)
		selectedMine = index
	end)

	menu.slider(trollyVehicles, translate("Trolling - Trolly Vehicles", "Count"), {}, "",
		1, 10, 1, 1, function(value) count = value end)

	menu.action(trollyVehicles, translate("Trolling - Trolly Vehicles", "Delete"), {}, "", function()
		for _, vehicle in ipairs(entities.get_all_vehicles_as_handles()) do
			if is_decor_flag_set(vehicle, DecorFlag_isTrollyVehicle) then
				entities.delete_by_handle(VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1, 0))
				entities.delete_by_handle(vehicle)
			end
		end
	end)

	menu.set_visible(mineSlider, false)

	-------------------------------------
	-- RAM PLAYER
	-------------------------------------

	local options <const> = {"Insurgent", "Phantom Wedge",  "Adder"}
	menu.action_slider(trollingOpt, translate("Trolling", "Ram Player"), {"ram"}, "", options, function (index)
		local vehicles <const> = {"insurgent2", "phantom2", "adder"}
		local vehicleName = vehicles[index]
		local vehicleHash <const> = util.joaat(vehicleName)
		request_model(vehicleHash)
		local targetPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pId)
		local coord = get_random_offset_in_range(targetPed, 12.0, 12.0)
		local vehicle = entities.create_vehicle(vehicleHash, coord, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
		set_entity_face_entity(vehicle, targetPed, false)
		VEHICLE.SET_VEHICLE_DOORS_LOCKED(vehicle, 2)
		VEHICLE.SET_VEHICLE_FORWARD_SPEED(vehicle, 100)
	end)

	-------------------------------------
	-- PIGGY BACK
	-------------------------------------

	local helpText = translate("Trolling", "The player won't see you attached to them")
	menu.toggle(trollingOpt, translate("Trolling", "Piggy Back"), {}, helpText, function (toggle)
		if players.user() == pId then return end
		gUsingPiggyback = toggle
		if gUsingPiggyback then
			gUsingRape = false
			local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pId)
			STREAMING.REQUEST_ANIM_DICT("rcmjosh2")
			while not STREAMING.HAS_ANIM_DICT_LOADED("rcmjosh2") do
				util.yield()
			end
			ENTITY.ATTACH_ENTITY_TO_ENTITY(PLAYER.PLAYER_PED_ID(), ped, PED.GET_PED_BONE_INDEX(ped, 0xDD1C), 0, -0.2, 0.65, 0, 0, 180, false, true, false, false, 0, true)
			TASK.TASK_PLAY_ANIM(PLAYER.PLAYER_PED_ID(), "rcmjosh2", "josh_sitting_loop", 8, -8, -1, 1, 0, false, false, false)
			while gUsingPiggyback do
				util.yield()
				if not NETWORK.NETWORK_IS_PLAYER_CONNECTED(pId) then
					gUsingPiggyback = false
					break
				end
			end
			TASK.CLEAR_PED_TASKS_IMMEDIATELY(PLAYER.PLAYER_PED_ID())
			ENTITY.DETACH_ENTITY(PLAYER.PLAYER_PED_ID(), true, false)
		end
	end)

	-------------------------------------
	-- RAIN ROCKETS
	-------------------------------------

	local lastOwnedShot = newTimer()
	local lastShot = newTimer()

	---@param pId Player
	---@param ownerPed boolean
	local function rain_rockets(pId, ownerPed)
		local target = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pId)
		local hash <const> = util.joaat("weapon_airstrike_rocket")
		if not WEAPON.HAS_WEAPON_ASSET_LOADED(hash) then
			WEAPON.REQUEST_WEAPON_ASSET(hash, 31, 0)
		end
		local pos = get_random_offset_in_range(target, 0.0, 6.0)
		pos.z = pos.z - 10.0
		MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(
			pos.x, pos.y, pos.z+50, pos.x, pos.y, pos.z, 200, true, hash, ownerPed, true, false, 2500.0)
	end


	menu.toggle_loop(trollingOpt, translate("Trolling", "Rain Rockets"), {}, "", function()
		if not players.exists(pId) then
			util.stop_thread()
		end
		if lastShot.elapsed() > 500 then
			rain_rockets(pId, 0); lastShot.reset()
		end
	end)

	menu.toggle_loop(trollingOpt, translate("Trolling", "Rain Rockets (owned)"), {}, "", function()
		if not players.exists(pId) then
			util.stop_thread()
		end
		if lastOwnedShot.elapsed() > 500 then
			rain_rockets(pId, players.user()); lastOwnedShot.reset()
		end
	end)

	-------------------------------------
	-- NET FORCEFIELD
	-------------------------------------

	local selectedOpt = 1
	local options <const> = {translate("Forcefield", "Push Out"), translate("Forcefield", "Destroy")}

	menu.toggle_loop(trollingOpt, translate("Forcefield", "Forcefield"), {}, "", function ()
		if not players.exists(pId) then
			util.stop_thread()
		end
		if selectedOpt == 1 then
			local vehicles = get_vehicles_in_player_range(pId, 10)
			local targetPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pId)
			local playerPos = ENTITY.GET_ENTITY_COORDS(targetPed, false)
			for _, vehicle in ipairs(vehicles) do
				local pos = ENTITY.GET_ENTITY_COORDS(vehicle, false)
				if vehicle ~= PED.GET_VEHICLE_PED_IS_IN(targetPed, false) and request_control_once(vehicle) then
					local force = v3.new(pos)
					force:sub(playerPos)
					force:normalise()
					ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, force.x, force.y, force.z, 0, 0, 0.5, 0, false, false, true, 0, 0)
				end
			end
		elseif selectedOpt == 2 then
			local pos = players.get_position(pId)
			FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, 29, 5.0, false, true, 0.0, true)
		end
	end)

	menu.slider_text(trollingOpt, translate("Forcefield", "Set Forcefield"), {}, "", options, function(index)
		selectedOpt = index
	end)

	-------------------------------------
	-- KAMIKASE
	-------------------------------------

	local options <const> = {"Lazer", "Mammatus",  "Cuban800"}
	menu.action_slider(trollingOpt, translate("Trolling", "Kamikaze"), {}, "", options, function (index, plane)
		local hash <const> = util.joaat(plane)
		request_model(hash)
		local targetPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pId)
		local pos = get_random_offset_in_range(targetPed, 20.0, 20.0)
		pos.z = pos.z + 30.0
		local plane = entities.create_vehicle(hash, pos, 0.0)
		set_entity_face_entity(plane, targetPed, true)
		VEHICLE.SET_VEHICLE_FORWARD_SPEED(plane, 150)
		VEHICLE.CONTROL_LANDING_GEAR(plane, 3)
	end)

	-------------------------------------
	-- CREEPER CLOWN
	-------------------------------------

	local helpText = translate("Trolling", "Spawn a clown that runs to the player and explodes when nearby")

	menu.action(trollingOpt, translate("Trolling", "Creeper Clown"), {"creeper"}, helpText, function()
		local hash <const> = util.joaat("s_m_y_clown_01")
		local explosion <const> = Effect.new("scr_rcbarry2", "scr_exp_clown")
		local appears <const> = Effect.new("scr_rcbarry2",  "scr_clown_appears")
		request_model(hash)
		local player = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pId)
		local pos = ENTITY.GET_ENTITY_COORDS(player, false)
		local coord = get_random_offset_in_range(player, 5.0, 8.0)
		coord.z = coord.z - 1.0
		local ped = entities.create_ped(0, hash, coord, CAM.GET_GAMEPLAY_CAM_ROT(0).z)

		request_fx_asset(appears.asset)
		GRAPHICS.USE_PARTICLE_FX_ASSET(appears.asset)
		GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_ON_ENTITY(
			appears.name,
			ped,
			0.0, 0.0, -1.0,
			0.0, 0.0, 0.0,
			0.5,
			false, false, false)
		set_entity_face_entity(ped, player, false)
		PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
		TASK.TASK_GO_TO_COORD_ANY_MEANS(ped, pos.x, pos.y, pos.z, 5.0, 0, 0, 0, 0)
		local dest = pos
		PED.SET_PED_KEEP_TASK(ped, true)
		AUDIO.STOP_PED_SPEAKING(ped, true)
		util.create_tick_handler(function()
			local pos = ENTITY.GET_ENTITY_COORDS(ped, true)
			local targetPos = players.get_position(pId)
			if not ENTITY.DOES_ENTITY_EXIST(ped) or PED.IS_PED_FATALLY_INJURED(ped) then
				return false
			elseif pos:distance(targetPos) > 150 and
			request_control(ped) then
				entities.delete_by_handle(ped)
				return false
			elseif pos:distance(targetPos) < 3.0 and request_control(ped) then
				request_fx_asset(explosion.asset)
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
					false, false, false, false)
				FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, 0, 1.0, true, true, 1.0, false)
				ENTITY.SET_ENTITY_VISIBLE(ped, false, 0)
				entities.delete_by_handle(ped)
				return false
			elseif targetPos:distance(dest) > 3.0 and request_control_once(ped) then
				dest = targetPos
				TASK.TASK_GO_TO_COORD_ANY_MEANS(ped, targetPos.x, targetPos.y, targetPos.z, 5.0, 0, 0, 0, 0)
			end
		end)
	end, nil, nil, COMMANDPERM_RUDE)

	---------------------
	---------------------
	-- NET VEHICLE OPT
	---------------------
	---------------------

	local vehicleOpt <const> = menu.list(menu.player_root(pId), translate("Player - Vehicle", "Vehicle"), {}, "")

	-------------------------------------
	-- TELEPORT
	-------------------------------------

	local tpVehicleOpt <const> = menu.list(vehicleOpt, translate("Player - Vehicle", "Teleport"), {}, "")
	local trans =
	{
		failedToGetControl = translate("Player - Vehicle", "Failed to get control of the vehicle"),
		noWaypointFound = translate("Player - Vehicle", "No waypoint found")
	}

	local function tp_player_vehicle(player, pos)
		local vehicle = get_vehicle_player_is_in(player)
		if not ENTITY.DOES_ENTITY_EXIST(vehicle) or ENTITY.IS_ENTITY_DEAD(vehicle, false) or
		not VEHICLE.IS_VEHICLE_DRIVEABLE(vehicle, true) then
			return
		end
		if request_control(vehicle, 1000) then
			ENTITY.SET_ENTITY_COORDS(vehicle, pos.x, pos.y, pos.z, 0, 0, 0, false)
		else
			notification:help(trans.failedToGetControl, HudColour.red)
		end
	end

	menu.action(tpVehicleOpt, translate("Vehicle - Teleport", "TP to Me"), {}, "", function()
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), false)
		tp_player_vehicle(pId, pos)
	end)

	menu.action(tpVehicleOpt, translate("Vehicle - Teleport", "TP to Ocean"), {"tptoocean"}, "", function()
		tp_player_vehicle(pId, v3.new(-4809.93, -2521.67, 250.0))
	end, nil, nil, COMMANDPERM_RUDE)

	menu.action(tpVehicleOpt, translate("Vehicle - Teleport", "TP to Fort Zancudo"), {"tptozancudo"}, "", function()
		tp_player_vehicle(pId, v3.new(-2219.0, 3213.0, 32.81))
	end, nil, nil, COMMANDPERM_RUDE)

	menu.action(tpVehicleOpt, translate("Vehicle - Teleport", "TP to Prision"), {"tptoprision"}, "", function()
		tp_player_vehicle(pId, v3.new(1680.11, 2512.89, 45.56))
	end, nil, nil, COMMANDPERM_RUDE)

	menu.action(tpVehicleOpt, translate("Vehicle - Teleport", "TP to Waypoint"), {}, "", function()
		local blip = HUD.GET_FIRST_BLIP_INFO_ID(8)
		if blip == 0 then
			notification:help(trans.noWaypointFound, HudColour.red)
		else
			tp_player_vehicle(pId, get_blip_coords(blip))
		end
	end)

	-------------------------------------
	-- ACROBATICS
	-------------------------------------

	local acrobatics <const> = menu.list(vehicleOpt, translate("Player - Vehicle", "Acrobatics"), {}, "")

	menu.action(acrobatics, translate("Vehicle - Acrobatics", "Ollie"), {"ollie"}, "", function()
		local vehicle = get_vehicle_player_is_in(pId)
		if vehicle ~= NULL and VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(vehicle) and
		request_control(vehicle, 1000) then
			ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, 0.0, 0.0, 10.0, 0.0, 0.0, 0.0, 1, false, true, true, true, true)
		end
	end)

	menu.action(acrobatics, translate("Vehicle - Acrobatics", "Kick Flip"), {"kickflip"}, "", function()
		local vehicle = get_vehicle_player_is_in(pId)
		if vehicle ~= NULL and VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(vehicle) and
		request_control(vehicle, 1000) then
			ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, 0.0, 0.0, 10.71, 5.0, 0.0, 0.0, 1, false, true, true, true, true)
		end
	end)

	menu.action(acrobatics, translate("Vehicle - Acrobatics", "Double Kick Flip"), {}, "", function()
		local vehicle = get_vehicle_player_is_in(pId)
		if vehicle ~= NULL and VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(vehicle) and
		request_control(vehicle, 1000) then
			ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, 0.0, 0.0, 21.43, 20.0, 0.0, 0.0, 1, false, true, true, true, true)
		end
	end)

	menu.action(acrobatics, translate("Vehicle - Acrobatics", "Heel Flip"), {}, "", function()
		local vehicle = get_vehicle_player_is_in(pId)
		if vehicle ~= NULL and VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(vehicle) and
		request_control(vehicle, 1000) then
			ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, 0.0, 0.0, 10.71, -5.0, 0.0, 0.0, 1, false, true, true, true, true)
		end
	end)

	-------------------------------------
	-- KILL ENGINE
	-------------------------------------

	menu.action(vehicleOpt, translate("Player - Vehicle", "Kill Engine"), {"killengine"}, "", function()
		local vehicle = get_vehicle_player_is_in(pId)
		if vehicle ~= NULL and request_control(vehicle, 1000) then
			VEHICLE.SET_VEHICLE_ENGINE_HEALTH(vehicle, -4000)
		end
	end, nil, nil, COMMANDPERM_RUDE)

	-------------------------------------
	-- CLEAN
	-------------------------------------

	menu.action(vehicleOpt, translate("Player - Vehicle", "Clean"), {"cleanveh"}, "", function()
		local vehicle = get_vehicle_player_is_in(pId)
		if vehicle ~= NULL and request_control(vehicle, 1000) then
			VEHICLE.SET_VEHICLE_DIRT_LEVEL(vehicle, 0.0)
		end
	end, nil, nil, COMMANDPERM_FRIENDLY)

	-------------------------------------
	-- REPAIR
	-------------------------------------

	menu.action(vehicleOpt, translate("Player - Vehicle", "Repair"), {"repairveh"}, "", function()
		local vehicle = get_vehicle_player_is_in(pId)
		if vehicle ~= NULL and request_control(vehicle, 1000) then
			VEHICLE.SET_VEHICLE_FIXED(vehicle)
			VEHICLE.SET_VEHICLE_DEFORMATION_FIXED(vehicle)
			VEHICLE.SET_VEHICLE_DIRT_LEVEL(vehicle, 0.0)
		end
	end, nil, nil, COMMANDPERM_FRIENDLY)

	-------------------------------------
	-- UPGRADE
	-------------------------------------

	menu.action(vehicleOpt, translate("Player - Vehicle", "Upgrade"), {"upgradeveh"}, "", function()
		local vehicle = get_vehicle_player_is_in(pId)
		if vehicle ~= NULL and request_control(vehicle, 1000) then
			VEHICLE.SET_VEHICLE_MOD_KIT(vehicle, 0)
			for i = 0, 50 do VEHICLE.SET_VEHICLE_MOD(vehicle, i, VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, i) - 1, false) end
		end
	end, nil, nil, COMMANDPERM_FRIENDLY)

	-------------------------------------
	-- CUSTOM PAINT
	-------------------------------------

	menu.action(vehicleOpt, translate("Player - Vehicle", "Apply Radom Paint"), {"randompaint"}, "", function()
		local vehicle = get_vehicle_player_is_in(pId)
		if vehicle ~= NULL and request_control(vehicle, 1000) then
			local primary, secundary = get_random_colour(), get_random_colour()
			VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(vehicle, primary.r, primary.g, primary.b)
			VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(vehicle, secundary.r, secundary.g, secundary.b)
		end
	end, nil, nil, COMMANDPERM_NEUTRAL)

	-------------------------------------
	-- BURST TIRES
	-------------------------------------

	menu.action(vehicleOpt, translate("Player - Vehicle", "Burst Tires"), {}, "", function()
		local vehicle = get_vehicle_player_is_in(pId)
		if vehicle ~= NULL and request_control(vehicle, 1000) then
			VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(vehicle, true)
			for wheelId = 0, 7 do VEHICLE.SET_VEHICLE_TYRE_BURST(vehicle, wheelId, true, 1000.0) end
		end
	end, nil, nil, COMMANDPERM_RUDE)

	-------------------------------------
	-- CATAPULT
	-------------------------------------

	menu.action(vehicleOpt, translate("Player - Vehicle", "Catapult"), {"catapult"}, "", function()
		local vehicle = get_vehicle_player_is_in(pId)
		if vehicle ~= NULL and VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(vehicle) and
		request_control(vehicle, 1000) then
			ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, 0.0, 0.0, 9999, 0.0, 0.0, 0.0, 1, false, true, true, true, true)
		end
	end, nil, nil, COMMANDPERM_RUDE)

	-------------------------------------
	-- BOOST FORWARD
	-------------------------------------

	menu.action(vehicleOpt, translate("Player - Vehicle", "Boost Forward"), {}, "", function()
		local vehicle = get_vehicle_player_is_in(pId)
		if vehicle ~= NULL and request_control(vehicle, 1000) then
			local force = ENTITY.GET_ENTITY_FORWARD_VECTOR(vehicle)
			force:mul(40.0)
			AUDIO.SET_VEHICLE_BOOST_ACTIVE(vehicle, true)
			ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, force.x, force.y, force.z, 0.0, 0.0, 0.0, 1, false, true, true, true, true)
			AUDIO.SET_VEHICLE_BOOST_ACTIVE(vehicle, false)
		end
	end)

	-------------------------------------
	-- GOD MODE
	-------------------------------------

	menu.toggle(vehicleOpt, translate("Player - Vehicle", "God Mode"), {"vehgodmode"}, "", function(on)
		local vehicle = get_vehicle_player_is_in(pId)
		if vehicle ~= NULL and request_control(vehicle, 1000) then
			if on then
				VEHICLE.SET_VEHICLE_ENVEFF_SCALE(vehicle, 0.0)
				VEHICLE.SET_VEHICLE_BODY_HEALTH(vehicle, 1000.0)
				VEHICLE.SET_VEHICLE_ENGINE_HEALTH(vehicle, 1000.0)
				VEHICLE.SET_VEHICLE_FIXED(vehicle)
				VEHICLE.SET_VEHICLE_DEFORMATION_FIXED(vehicle)
				VEHICLE.SET_VEHICLE_PETROL_TANK_HEALTH(vehicle, 1000.0)
				VEHICLE.SET_VEHICLE_DIRT_LEVEL(vehicle, 0.0)
				for i = 0, 10 do VEHICLE.SET_VEHICLE_TYRE_FIXED(vehicle, i) end
			end
			ENTITY.SET_ENTITY_INVINCIBLE(vehicle, on)
			ENTITY.SET_ENTITY_PROOFS(vehicle, on, on, on, on, on, on, 1, on)
			VEHICLE.SET_DISABLE_VEHICLE_PETROL_TANK_DAMAGE(vehicle, on)
			VEHICLE.SET_DISABLE_VEHICLE_PETROL_TANK_FIRES(vehicle, on)
			VEHICLE.SET_VEHICLE_CAN_BE_VISIBLY_DAMAGED(vehicle, not on)
			VEHICLE.SET_VEHICLE_CAN_BREAK(vehicle, not on)
			VEHICLE.SET_VEHICLE_ENGINE_CAN_DEGRADE(vehicle, not on)
			VEHICLE.SET_VEHICLE_EXPLODES_ON_HIGH_EXPLOSION_DAMAGE(vehicle, not on)
			VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(vehicle, not on)
			VEHICLE.SET_VEHICLE_WHEELS_CAN_BREAK(vehicle, not on)
		end
	end)

	-------------------------------------
	-- INVISIBLE
	-------------------------------------

	menu.toggle_loop(vehicleOpt, translate("Player - Vehicle", "Invisible"), {"invisibleveh"}, "", function()
		if not players.exists(pId) then
			util.stop_thread()
		end
		local vehicle = get_vehicle_player_is_in(pId)
		if vehicle ~= NULL and request_control_once(vehicle) then
			ENTITY.SET_ENTITY_VISIBLE(vehicle, false, false)
		end
	end, function ()
		local vehicle = get_vehicle_player_is_in(pId)
		if vehicle ~= NULL and request_control(vehicle, 1000) then
			ENTITY.SET_ENTITY_VISIBLE(vehicle, true, false)
		end
	end)

	-------------------------------------
	-- FREEZE
	-------------------------------------

	menu.toggle_loop(vehicleOpt, translate("Player - Vehicle", "Freeze"), {"freezeveh"}, "", function()
		if not players.exists(pId) then
			util.stop_thread()
		end
		local vehicle = get_vehicle_player_is_in(pId)
		if vehicle ~= NULL and request_control_once(vehicle) then
			ENTITY.FREEZE_ENTITY_POSITION(vehicle, true)
		end
	end, function ()
		local vehicle = get_vehicle_player_is_in(pId)
		if vehicle ~= NULL and request_control(vehicle, 1000) then
			ENTITY.FREEZE_ENTITY_POSITION(vehicle, false)
		end
	end)

	-------------------------------------
	-- LOCK DOORS
	-------------------------------------

	menu.toggle_loop(vehicleOpt, translate("Player - Vehicle", "Child Lock"), {"lockveh"}, "", function()
		if not players.exists(pId) then
			util.stop_thread()
		end
		local vehicle = get_vehicle_player_is_in(pId)
		if vehicle ~= NULL and request_control_once(vehicle) then
			VEHICLE.SET_VEHICLE_DOORS_LOCKED(vehicle, 4)
		end
	end, function ()
		local vehicle = get_vehicle_player_is_in(pId)
		if vehicle ~= NULL and request_control(vehicle, 1000) then
			VEHICLE.SET_VEHICLE_DOORS_LOCKED(vehicle, 1)
		end
	end)

	---------------------
	---------------------
	-- FRIENDLY
	---------------------
	---------------------

	local friendlyOpt <const> = menu.list(menu.player_root(pId), translate("Player", "Friendly Options"), {}, "")

	-------------------------------------
	-- KILL KILLERS
	-------------------------------------

	local explodeKiller = false
	local helpText = translate("Friendly Options", "Explodes the player's murderer")
	menu.toggle_loop(friendlyOpt, translate("Friendly Options", "Kill Killers"), {"explokillers"}, helpText, function()
		if not players.exists(pId) then
			util.stop_thread()
		end
		local playerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pId)
		local sourceOfDeath = PED.GET_PED_SOURCE_OF_DEATH(playerPed)
		if explodeKiller and ENTITY.DOES_ENTITY_EXIST(sourceOfDeath) then
			if sourceOfDeath == playerPed then
				return
			end
			local pos = ENTITY.GET_ENTITY_COORDS(sourceOfDeath, false)
			FIRE.ADD_OWNED_EXPLOSION(playerPed, pos.x, pos.y, pos.z - 1.0, 1, 1.0, true, false, 1.0)
			explodeKiller = false
		elseif not ENTITY.IS_ENTITY_DEAD(playerPed, false) then
			explodeKiller = true
		end
	end)

end -- generate_features()

---------------------
---------------------
-- SELF
---------------------
---------------------

local selfOpt <const> = menu.list(menu.my_root(), translate("Self", "Self"), {"selfoptions"}, "")

-------------------------------------
-- MOD MAX HEALTH
-------------------------------------

local defaultHealth = ENTITY.GET_ENTITY_MAX_HEALTH(PLAYER.PLAYER_PED_ID())
local moddedHealth = defaultHealth
local slider

local SetEntityMaxHealth = function(entity, value)
	local maxHealth = ENTITY.GET_ENTITY_MAX_HEALTH(entity)
	if maxHealth == value then
		return
	end
	PED.SET_PED_MAX_HEALTH(entity, value)
	local health = ENTITY.GET_ENTITY_HEALTH(entity)
	ENTITY.SET_ENTITY_HEALTH(entity, value, 0)
end

menu.toggle_loop(selfOpt, translate("Self", "Mod Max Health"), {"modhealth"}, "", function ()
	SetEntityMaxHealth(players.user_ped(), moddedHealth)
	if Config.general.displayhealth then
		local health = ENTITY.GET_ENTITY_HEALTH(PLAYER.PLAYER_PED_ID())
		local strg = string.format("~b~HEALTH ~w~ %s", health)
		draw_string(strg, Config.healthtxtpos.x, Config.healthtxtpos.y, 0.6, 4)
	end
end, function ()
	menu.set_value(slider, defaultHealth)
	SetEntityMaxHealth(players.user_ped(), defaultHealth)
end)

slider = menu.slider(selfOpt, translate("Self", "Set Max Health"), {"moddedhealth"}, "", 100, 9000, defaultHealth, 50, function(value, prev, click)
	if (click & CLICK_FLAG_AUTO) ~= 0 then return end
	moddedHealth = value
end)

-------------------------------------
-- REFILL HEALTH
-------------------------------------

menu.action(selfOpt, translate("Self", "Refill Health"), {"maxhealth"}, "", function()
	ENTITY.SET_ENTITY_HEALTH(PLAYER.PLAYER_PED_ID(), PED.GET_PED_MAX_HEALTH(PLAYER.PLAYER_PED_ID()), 0)
end)

-------------------------------------
-- REFILL ARMOUR
-------------------------------------

menu.action(selfOpt, translate("Self", "Refill Armour"), {"maxarmour"}, "", function()
	if util.is_session_started() then
		PED.SET_PED_ARMOUR(PLAYER.PLAYER_PED_ID(), 50)
	else
		PED.SET_PED_ARMOUR(PLAYER.PLAYER_PED_ID(), 100)
	end
end)

-------------------------------------
-- REFILL HEALTH IN COVER
-------------------------------------

menu.toggle_loop(selfOpt, translate("Self", "Refill Health in Cover"), {"healincover"}, "", function()
	if PED.IS_PED_IN_COVER(PLAYER.PLAYER_PED_ID(), false) then
		PLAYER._SET_PLAYER_HEALTH_RECHARGE_LIMIT(PLAYER.PLAYER_ID(), 1.0)
		PLAYER.SET_PLAYER_HEALTH_RECHARGE_MULTIPLIER(PLAYER.PLAYER_ID(), 15.0)
	else
		PLAYER._SET_PLAYER_HEALTH_RECHARGE_LIMIT(PLAYER.PLAYER_ID(), 0.5)
		PLAYER.SET_PLAYER_HEALTH_RECHARGE_MULTIPLIER(PLAYER.PLAYER_ID(), 1.0)
	end
end, function ()
	PLAYER._SET_PLAYER_HEALTH_RECHARGE_LIMIT(PLAYER.PLAYER_ID(), 0.25)
	PLAYER.SET_PLAYER_HEALTH_RECHARGE_MULTIPLIER(PLAYER.PLAYER_ID(), 1.0)
end)

-------------------------------------
-- BULLSHARK
-------------------------------------

menu.action(selfOpt, translate("Self", "Instant Bullshark"), {}, "", function()
	write_global.int(2703735 + 3576, 1 << 0)
end)

-------------------------------------
-- FORCEFIELD
-------------------------------------

local selectedOpt = 1
local options <const> = {translate("Forcefield", "Push Out"), translate("Forcefield", "Destroy")}


menu.toggle_loop(selfOpt, translate("Forcefield", "Forcefield"), {"forcefield"}, "", function()
	if selectedOpt == 1 then
		local entities = get_entities_in_player_range(players.user(), 10.0)
		local playerPos = players.get_position(players.user())
		for _, entity in ipairs(entities) do
			local entPos = ENTITY.GET_ENTITY_COORDS(entity, false)
			if not PED.IS_PED_A_PLAYER(entity) and
			PED.GET_VEHICLE_PED_IS_IN(players.user_ped(), false) ~= entity and
			request_control_once(entity) then
				local force = v3.new(entPos)
				force:sub(playerPos)
				force:normalise()
				if ENTITY.IS_ENTITY_A_PED(entity) then PED.SET_PED_TO_RAGDOLL(entity, 1000, 1000, 0, 0, 0, 0) end
				ENTITY.APPLY_FORCE_TO_ENTITY(entity, 3, force.x, force.y, force.z, 0, 0, 0.5, 0, false, false, true, 0, 0)
			end
		end
	elseif selectedOpt == 2 then
		set_explosion_proof(players.user_ped(), true)
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), false)
		FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, 29, 5.0, false, true, 0.0, true)
	end
end, function()
	set_explosion_proof(players.user_ped(), false)
end)


menu.slider_text(selfOpt, translate("Forcefield", "Set Forcefield"), {}, "", options, function(index)
	selectedOpt = index
end)

-------------------------------------
-- FORCE
-------------------------------------

local helpText = translate("Self", "Use Jedi Force on nearby vehicles")
local notif_format = translate("Self", "Press ~%s~ and ~%s~ to use Force")

local state = 0
menu.toggle_loop(selfOpt, translate("Self", "Force"), {"jedimode"}, helpText, function()
	if state == 0 then
		notification:help(notif_format, HudColour.black, "INPUT_VEH_FLY_SELECT_TARGET_RIGHT", "INPUT_VEH_FLY_ROLL_RIGHT_ONLY")
		local localPed = PLAYER.PLAYER_PED_ID()
		local effect = Effect.new("scr_ie_tw", "scr_impexp_tw_take_zone")
		local colour = {r = 0.5, g = 0.0, b = 0.5, a = 1.0}
		request_fx_asset(effect.asset)
		GRAPHICS.USE_PARTICLE_FX_ASSET(effect.asset)
		GRAPHICS.SET_PARTICLE_FX_NON_LOOPED_COLOUR(colour.r, colour.g, colour.b)
		GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_ON_ENTITY(
			effect.name,
			players.user_ped(),
			0.0, 0.0, -0.9,
			0.0, 0.0, 0.0,
			1.0,
			false, false, false)
		state = 1
	elseif state == 1 then
		local entities = get_ped_nearby_vehicles(players.user_ped())
		for _, vehicle in ipairs(entities) do
			if PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID() ,false) == vehicle then
				goto LABEL_CONTINUE
			end
			if PAD.IS_CONTROL_PRESSED(0, 118) and request_control_once(vehicle) then
				ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, 0, 0, 0.5, 0, 0, 0, 0, false, false, true, 0, 0)
			elseif PAD.IS_CONTROL_PRESSED(0, 109) and request_control_once(vehicle) then
				ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, 0, 0, -70, 0, 0, 0, 0, false, false, true, 0, 0)
			end
		::LABEL_CONTINUE::
		end
	end
end, function()
	state = 0
end)

-------------------------------------
-- CARPET RIDE
-------------------------------------

local state = 0
local object = 0
local format0 = translate("Self", "Press ~%s~ ~%s~ ~%s~ ~%s~ to use Carpet Ride")
local format1 = translate("Self", "Press ~%s~ to move faster")

menu.toggle_loop(selfOpt, translate("Self", "Carpet Ride"), {"carpetride"}, "", function()
	if state == 0 then
		local objHash <const> = util.joaat("p_cs_beachtowel_01_s")
		request_model(objHash)
		STREAMING.REQUEST_ANIM_DICT("rcmcollect_paperleadinout@")
		while not STREAMING.HAS_ANIM_DICT_LOADED("rcmcollect_paperleadinout@") do
			util.yield()
		end
		local localPed = PLAYER.PLAYER_PED_ID()
		local pos = ENTITY.GET_ENTITY_COORDS(localPed, false)
		TASK.CLEAR_PED_TASKS_IMMEDIATELY(localPed)
		object = entities.create_object(objHash, pos)
		ENTITY.ATTACH_ENTITY_TO_ENTITY(localPed, object, 0, 0, -0.2, 1.0, 0, 0, 0, false, true, false, false, 0, true)
		ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(object, false, false)

		TASK.TASK_PLAY_ANIM(localPed, "rcmcollect_paperleadinout@", "meditiate_idle", 8, -8, -1, 1, 0, false, false, false)
		notification:help(format0 .. ".\n" .. format1 .. '.', HudColour.black,
			"INPUT_MOVE_UP_ONLY", "INPUT_MOVE_DOWN_ONLY", "INPUT_VEH_JUMP", "INPUT_DUCK", "INPUT_VEH_MOVE_UP_ONLY")
		state = 1
	elseif state == 1 then
		HUD.DISPLAY_SNIPER_SCOPE_THIS_FRAME()
		local objPos = ENTITY.GET_ENTITY_COORDS(object, false)
		local camrot = CAM.GET_GAMEPLAY_CAM_ROT(0)
		ENTITY.SET_ENTITY_ROTATION(object, 0, 0, camrot.z, 0, true)
		local forwardV = ENTITY.GET_ENTITY_FORWARD_VECTOR(PLAYER.PLAYER_PED_ID())
		forwardV.z = 0.0
		local delta = v3.new(0, 0, 0)
		local speed = 0.2
		if PAD.IS_CONTROL_PRESSED(0, 61) then
			speed = 1.5
		end
		if PAD.IS_CONTROL_PRESSED(0, 32) then
			delta = v3.new(forwardV)
			delta:mul(speed)
		end
		if PAD.IS_CONTROL_PRESSED(0, 130)  then
			delta = v3.new(forwardV)
			delta:mul(-speed)
		end
		if PAD.IS_DISABLED_CONTROL_PRESSED(0, 22) then
			delta.z = speed
		end
		if PAD.IS_CONTROL_PRESSED(0, 36) then
			delta.z = -speed
		end
		local newPos = v3.new(objPos)
		newPos:add(delta)
		ENTITY.SET_ENTITY_COORDS(object, newPos.x, newPos.y, newPos.z, false, false, false, false)
	end
end, function ()
	TASK.CLEAR_PED_TASKS_IMMEDIATELY(PLAYER.PLAYER_PED_ID())
	ENTITY.DETACH_ENTITY(PLAYER.PLAYER_PED_ID(), true, false)
	ENTITY.SET_ENTITY_VISIBLE(object, false, 0)
	entities.delete_by_handle(object)
	state = 0
end)

-------------------------------------
-- UNDEAD OFFRADAR
-------------------------------------

local maxHealth <const> = 328
menu.toggle_loop(selfOpt, translate("Self", "Undead Offradar"), {"undeadotr"}, "", function()
	if ENTITY.GET_ENTITY_MAX_HEALTH(PLAYER.PLAYER_PED_ID()) ~= 0 then
		ENTITY.SET_ENTITY_MAX_HEALTH(PLAYER.PLAYER_PED_ID(), 0)
	end
end, function ()
	ENTITY.SET_ENTITY_MAX_HEALTH(PLAYER.PLAYER_PED_ID(), maxHealth)
end)

-------------------------------------
-- TRAILS
-------------------------------------

local bones <const> = {
	0x49D9,	-- left hand
	0xDEAD,	-- right hand
	0x3779,	-- left foot
	0xCC4D	-- right foot
}
local colour = {r = 1.0, g = 0.0, b = 1.0, a = 1.0}
local timer <const> = newTimer()
local trailsOpt <const> = menu.list(selfOpt, translate("Self", "Trails"), {}, "")
local effect <const> = Effect.new("scr_rcpaparazzo1", "scr_mich4_firework_sparkle_spawn")
local effects = {}

---@param effects table
local function removeFxs(effects)
	for _, effect in ipairs(effects) do
		GRAPHICS.STOP_PARTICLE_FX_LOOPED(effect, 0)
		GRAPHICS.REMOVE_PARTICLE_FX(effect, 0)
	end
end

menu.toggle_loop(trailsOpt, translate("Self - Trails", "Trails"), {"trails"}, "", function ()
	if not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(effect.asset) then
		STREAMING.REQUEST_NAMED_PTFX_ASSET(effect.asset)
		return
	end
	if timer.elapsed() >= 1000 then
		removeFxs(effects); effects = {}
		timer.reset()
	end
	if PED.IS_PED_IN_ANY_VEHICLE(PLAYER.PLAYER_PED_ID(), true) then
		local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
		local minimum, maximum = v3.new(), v3.new()
		MISC.GET_MODEL_DIMENSIONS(ENTITY.GET_ENTITY_MODEL(vehicle), minimum, maximum)
		local offsets <const> = {v3(minimum.x, minimum.y, 0.0), v3(maximum.x, minimum.y, 0.0)}
		for _, offset in ipairs(offsets) do
			GRAPHICS.USE_PARTICLE_FX_ASSET(effect.asset)
			local fx =
			GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY(
				effect.name,
				vehicle,
				offset.x,
				offset.y,
				0.0,
				0.0,
				0.0,
				0.0,
				0.7, --scale
				false, false, false,
				0, 0, 0, 0
			)
			GRAPHICS.SET_PARTICLE_FX_LOOPED_COLOUR(fx, colour.r, colour.g, colour.b, 0)
			table.insert(effects, fx)
		end
	elseif ENTITY.DOES_ENTITY_EXIST(PLAYER.PLAYER_PED_ID()) then
		for _, boneId in ipairs(bones) do
			GRAPHICS.USE_PARTICLE_FX_ASSET(effect.asset)
			local fx =
			GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY_BONE(
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
				false, false, false,
				0, 0, 0, 0
			)
			GRAPHICS.SET_PARTICLE_FX_LOOPED_COLOUR(fx, colour.r, colour.g, colour.b, 0)
			table.insert(effects, fx)
		end
	end
end, function ()
	removeFxs(effects); effects = {}
end)

local trailColour = menu.colour(trailsOpt, translate("Self - Trails", "Colour"), {"trailcolour"}, "",
	colour, false, function(newColour) colour = newColour end)
menu.rainbow(trailColour)

-------------------------------------
-- COMBUSTION MAN
-------------------------------------

local state = 0
local hash <const> = util.joaat("VEHICLE_WEAPON_PLAYER_LAZER")
local msg = translate("Self", "Press ~%s~ to use Combustion Man")

menu.toggle_loop(selfOpt, translate("Self", "Combustion Man"), {"combustionman"}, "", function()
	if state == 0 then
		notification:help(msg, HudColour.black, "INPUT_ATTACK")
		state = 1
	end
	PAD.DISABLE_CONTROL_ACTION(2, 106, true)
	PAD.DISABLE_CONTROL_ACTION(2, 122, true)
	PAD.DISABLE_CONTROL_ACTION(2, 135, true)
	HUD.DISPLAY_SNIPER_SCOPE_THIS_FRAME()

	WEAPON.REQUEST_WEAPON_ASSET(hash, 31, 26)
	if PAD.IS_DISABLED_CONTROL_PRESSED(2, 24) then
		local pos = players.get_position(players.user())
		local offset = get_offset_from_cam(80)
		MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(
			pos.x,
			pos.y,
			pos.z,
			offset.x,
			offset.y,
			offset.z,
			200,
			true,
			hash,
			PLAYER.PLAYER_PED_ID(),
			true, true, -1.0
		)
	end
end, function()
	state = 0
end)

-------------------------------------
-- GOD FINGER
-------------------------------------

local is_player_pointing = function ()
	return read_global.int(4521801 + 930) == 3
end

local targetEntity = NULL
local lastStop <const> = newTimer()
local explosionProof = false
local helpTxt <const> =
translate("Self", "Move entities with your finger when pointing them. Press B to start pointing.")

menu.toggle_loop(selfOpt, translate("Self", "God Finger"), {"godfinger"}, helpTxt, function()
	if is_player_pointing() then
		write_global.int(4521801 + 935, NETWORK.GET_NETWORK_TIME()) -- to avoid the animation to stop
		if not ENTITY.DOES_ENTITY_EXIST(targetEntity) then
			local flag = TraceFlag.peds | TraceFlag.vehicles | TraceFlag.objects
			local raycastResult = get_raycast_result(1000.0, flag)
			if raycastResult.didHit and ENTITY.DOES_ENTITY_EXIST(raycastResult.hitEntity) then
				targetEntity = raycastResult.hitEntity
			else return end
		end
		local myPos = players.get_position(players.user())
		local entityPos = ENTITY.GET_ENTITY_COORDS(targetEntity, true)
		local camDir = CAM.GET_GAMEPLAY_CAM_ROT(0):toDir()
		local distance = myPos:distance(entityPos)
		if distance > 30.0 then distance = 30.0
		elseif distance < 10.0 then distance = 10.0 end
		local targetPos = v3.new(camDir)
		targetPos:mul(distance)
		targetPos:add(myPos)
		local direction = v3.new(targetPos)
		direction:sub(entityPos)
		direction:normalise()

		if ENTITY.IS_ENTITY_A_PED(targetEntity) then
			direction:mul(5.0)
			local explosionPos = v3.new(entityPos)
			explosionPos:sub(direction)
			draw_box_esp(targetEntity, {r = 255, g = 255, b = 255, a = 255})
			set_explosion_proof(players.user_ped(), true)
			explosionProof = true
			FIRE.ADD_EXPLOSION(explosionPos.x, explosionPos.y, explosionPos.z, 29, 25.0, false, true, 0.0, true)
		else
			local vel = v3.new(direction)
			local magnitude = entityPos:distance(targetPos)
			vel:mul(magnitude)
			draw_box_esp(targetEntity, {r = 255, g = 255, b = 255, a = 255})
			request_control_once(targetEntity)
			ENTITY.SET_ENTITY_VELOCITY(targetEntity, vel.x, vel.y, vel.z)
		end
	elseif targetEntity ~= NULL then
		lastStop.reset()
		targetEntity = NULL
	elseif explosionProof and lastStop.elapsed() > 500 then
		-- No need to worry about disabling any proof if Stand's godmode is on because
		-- it'll turn them back on anyways
		explosionProof = false
		set_explosion_proof(players.user_ped(), false)
    end
end)

-------------------------------------
-- EWO
-------------------------------------

menu.action(selfOpt, translate("Self", "Explode Myself"), {"explodemyself"}, "", function()
	local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), false)
	FIRE.ADD_OWNED_EXPLOSION(PLAYER.PLAYER_PED_ID(), pos.x, pos.y, pos.z - 1.0, 0, 1.0, true, false, 1.0)
end)

---------------------
---------------------
-- WEAPON
---------------------
---------------------

local weaponOpt <const> = menu.list(menu.my_root(), translate("Weapon", "Weapon"), {"weaponoptions"}, "")

-------------------------------------
-- VEHICLE PAINT GUN
-------------------------------------

local helpText = translate("Weapon", "Applies a random colour combination to the damaged vehicle")

menu.toggle_loop(weaponOpt, translate("Weapon", "Vehicle Paint Gun"), {"paintgun"}, helpText, function()
	if PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) then
		local entity = get_entity_player_is_aiming_at(players.user())
		if entity ~= NULL and ENTITY.IS_ENTITY_A_VEHICLE(entity) then
			request_control(entity)
			local primary, secundary = get_random_colour(), get_random_colour()
			VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(entity, primary.r, primary.g, primary.b)
			VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(entity, secundary.r, secundary.g, secundary.b)
		end
	end
end)

-------------------------------------
-- SHOOTING EFFECT
-------------------------------------

local ShootEffect = {scale = 0, rotation = {}}
ShootEffect.__index = ShootEffect
setmetatable(ShootEffect, Effect)

function ShootEffect.new(asset, name, scale, rotation)
	tbl = setmetatable({}, ShootEffect)
	tbl.name = name
	tbl.asset = asset
	tbl.scale = scale or 1.0
	tbl.rotation = rotation or v3.new()
	return tbl
end

local selectedOpt = 1
local shootingEffects <const> = {
	ShootEffect.new("scr_rcbarry2", "muz_clown", 0.8, v3.new(90, 0.0, 0.0)),
	ShootEffect.new("scr_rcbarry2", "scr_clown_bul", 0.3, v3.new(180.0, 0.0, 0.0)),
}

menu.toggle_loop(weaponOpt, translate("Weapon - Shooting Effect", "Shooting Effect"), {"shootingfx"}, "", function ()
	local effect = shootingEffects[selectedOpt]
	if not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(effect.asset) then
		STREAMING.REQUEST_NAMED_PTFX_ASSET(effect.asset)
		return
	end

	if PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) then
		local weapon = WEAPON.GET_CURRENT_PED_WEAPON_ENTITY_INDEX(PLAYER.PLAYER_PED_ID(), false)
		local boneId = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(weapon, "gun_muzzle")

		GRAPHICS.USE_PARTICLE_FX_ASSET(effect.asset)
		GRAPHICS._START_NETWORKED_PARTICLE_FX_NON_LOOPED_ON_ENTITY_BONE(
			effect.name,
			weapon,
			0.0,
			0.0,
			0.0,
			effect.rotation.x,
			effect.rotation.y,
			effect.rotation.z,
			boneId,
			effect.scale,
			false, false, false
		)
	end
end)

local options <const> = {
	translate("Weapon - Shooting Effect", "Clown Muzzle"),
	translate("Weapon - Shooting Effect", "Clown Flowers"),
}
menu.slider_text(weaponOpt, translate("Weapon - Shooting Effect", "Set Shooting Effect"), {}, "", options, function (index)
	selectedOpt = index
end)

-------------------------------------
-- MAGNET GUN
-------------------------------------

local colour <const> = {r = 0, g = 255, b = 255, a = 255}
local selectedOpt = 1

menu.toggle_loop(weaponOpt, translate("Weapon", "Magnet Gun"), {"magnetgun"}, "", function ()
	if not PLAYER.IS_PLAYER_FREE_AIMING(PLAYER.PLAYER_ID()) then return end
	local numVehicles = 0
	local offset = get_offset_from_cam(30.0)
	local vehicles <const> = get_vehicles_in_player_range(players.user(), 70.0)
	rainbow_colour(colour)
	GRAPHICS._DRAW_SPHERE(offset.x, offset.y, offset.z, 0.5, colour.r, colour.g, colour.b, 0.5)
	for _, vehicle in ipairs(vehicles) do
		if vehicle ~= PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false) and
		numVehicles < 20 and request_control_once(vehicle) then
			numVehicles = numVehicles + 1
			local vehiclePos = ENTITY.GET_ENTITY_COORDS(vehicle, false)
			local vect = v3.new(offset)
			vect:sub(vehiclePos)
			if selectedOpt == 1 then
				ENTITY.SET_ENTITY_VELOCITY(vehicle, vect.x, vect.y, vect.z)
			elseif selectedOpt == 2 then
				vect:mul(0.5)
				ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, vect.x, vect.y, vect.z, 0.0, 0.0, 0.5, 0, false, false, true, false, false)
			end
		end
	end
end)

local options <const> = {translate("Weapon - Magnet Gun", "Smooth"), translate("Weapon - Magnet Gun", "Chaos Mode")}
menu.slider_text(weaponOpt, translate("Weapon", "Set Magnet Gun"), {}, "", options, function(index)
	selectedOpt = index
end)

-------------------------------------
-- AIRSTRIKE GUN
-------------------------------------

menu.toggle_loop(weaponOpt, translate("Weapon", "Airstrike Gun"), {"airstikegun"}, "", function()
	local hash <const> = util.joaat("weapon_airstrike_rocket")
	WEAPON.REQUEST_WEAPON_ASSET(hash, 31, 0)
	local raycastResult = get_raycast_result(1000.0)
	if raycastResult.didHit and PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) then
		local pos = raycastResult.endCoords
		MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z+35.0, pos.x, pos.y, pos.z, 200, true, hash, players.user_ped(), true, false, 2500.0)
	end
end)

-------------------------------------
-- BULLET CHANGER
-------------------------------------

local weaponModels <const> = {
	"weapon_rpg",
	"weapon_firework",
	"weapon_raypistol",
	"weapon_grenadelauncher",
	"weapon_molotov",
	"weapon_snowball",
	"weapon_flaregun",
	"weapon_emplauncher"
}
local selectedOpt = 1
local timer <const> = newTimer()

---Returns the current weapon's time between shots in millis or `-1.0`.
---@return number
local function get_time_between_shots()
	local CPed = entities.handle_to_pointer(players.user_ped())
	local addr = addr_from_pointer_chain(CPed, {0x10D8, 0x20, 0x013C})
	return addr ~= 0 and memory.read_float(addr) * 1000 or -1.0
end

menu.toggle_loop(weaponOpt, translate("Weapon", "Bullet Changer"), {"bulletchanger"}, "", function ()
	local localPed = PLAYER.PLAYER_PED_ID()
	if not WEAPON.IS_PED_ARMED(localPed, 4) then
		return
	end
	local selectedBullet = util.joaat(weaponModels[selectedOpt])
	if not WEAPON.HAS_WEAPON_ASSET_LOADED(selectedBullet) then
		WEAPON.REQUEST_WEAPON_ASSET(selectedBullet, 31, 26)
		WEAPON.GIVE_WEAPON_TO_PED(localPed, selectedBullet, 200, false, false)
	end
	PLAYER.DISABLE_PLAYER_FIRING(PLAYER.PLAYER_ID(), true)
	if PAD.IS_DISABLED_CONTROL_PRESSED(0, 24) and
	PLAYER.IS_PLAYER_FREE_AIMING(PLAYER.PLAYER_ID()) and timer.elapsed() > math.max(get_time_between_shots(), 80.0) then
		local weapon = WEAPON.GET_CURRENT_PED_WEAPON_ENTITY_INDEX(localPed, false)
		local bonePos = ENTITY._GET_ENTITY_BONE_POSITION_2(weapon, ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(weapon, "gun_muzzle"))
		local b = get_offset_from_cam(30.0)
		MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(
			bonePos.x,
			bonePos.y,
			bonePos.z,
			b.x,
			b.y,
			b.z,
			200, true, selectedBullet, localPed, true, false, 2000.0)
		PAD.SET_PAD_SHAKE(0, 50, 100)
		timer.reset()
	elseif PAD.IS_DISABLED_CONTROL_JUST_RELEASED(0, 24) then
		PAD.STOP_PAD_SHAKE(0)
	end
end)

local options <const> = {
	{util.get_label_text("WT_A_RPG")}, {util.get_label_text("WT_FWRKLNCHR")},
	{util.get_label_text("WT_RAYPISTOL")}, {util.get_label_text("WT_GL")},
	{util.get_label_text("WT_MOLOTOV")}, {util.get_label_text("WT_SNWBALL")},
	{util.get_label_text("WT_FLAREGUN")}, {util.get_label_text("WT_EMPL")},
}
menu.list_select(weaponOpt, translate("Weapon", "Set Weapon Bullet"), {}, "", options, 1, function(opt)
	selectedOpt = opt
end)

-------------------------------------
-- HIT EFFECT
-------------------------------------

local HitEffect = {colorCanChange = false}
HitEffect.__index = HitEffect
setmetatable(HitEffect, Effect)

function HitEffect.new(asset, name, colorCanChange)
	local inst = setmetatable({}, HitEffect)
	inst.name = name
	inst.asset = asset
	inst.colorCanChange = colorCanChange or false
	return inst
end

local hitEffects <const> = {
	HitEffect.new("scr_rcbarry2", "scr_exp_clown"),
	HitEffect.new("scr_rcbarry2", "scr_clown_appears"),
	HitEffect.new("scr_rcpaparazzo1", "scr_mich4_firework_trailburst_spawn", true),
	HitEffect.new("scr_indep_fireworks", "scr_indep_firework_starburst", true),
	HitEffect.new("scr_indep_fireworks", "scr_indep_firework_fountain", true),
	HitEffect.new("scr_rcbarry1", "scr_alien_disintegrate"),
	HitEffect.new("scr_rcbarry2", "scr_clown_bul"),
	HitEffect.new("proj_indep_firework", "scr_indep_firework_grd_burst"),
	HitEffect.new("scr_rcbarry2", "muz_clown"),
}
local options <const> = {
	{translate("Weapon - Hit Effect", "Clown Explosion")},
	{translate("Weapon - Hit Effect", "Clown Appears")},
	{translate("Weapon - Hit Effect", "Trailburst FW")},
	{translate("Weapon - Hit Effect", "Starburst FW")},
	{translate("Weapon - Hit Effect", "Fountain FW")},
	{translate("Weapon - Hit Effect", "Alien Disintegration")},
	{translate("Weapon - Hit Effect", "Clown Flowers")},
	{translate("Weapon - Hit Effect", "Ground Burst FW")},
	{translate("Weapon - Hit Effect", "Clown Muz")},
}
local effectColour = {r = 0.5, g = 0.0, b = 0.5, a = 1.0}
local selectedOpt = 1
local hitEffectRoot <const> = menu.list(weaponOpt, translate("Weapon - Hit Effect", "Hit Effect"), {}, "")

menu.toggle_loop(hitEffectRoot, translate("Weapon - Hit Effect", "Hit Effect"), {"hiteffects"}, "", function()
	local effect = hitEffects[selectedOpt]
	if not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(effect.asset) then
		return STREAMING.REQUEST_NAMED_PTFX_ASSET(effect.asset)
	end
	local hitCoords = v3.new()
	if WEAPON.GET_PED_LAST_WEAPON_IMPACT_COORD(players.user_ped(), hitCoords) then
		local raycastResult = get_raycast_result(1000.0)
		local rot = raycastResult.surfaceNormal:toRot()
		GRAPHICS.USE_PARTICLE_FX_ASSET(effect.asset)
		if effect.colorCanChange then
			local colour = effectColour
			GRAPHICS.SET_PARTICLE_FX_NON_LOOPED_COLOUR(colour.r, colour.g, colour.b)
		end
		GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD(
			effect.name,
			hitCoords.x,
			hitCoords.y,
			hitCoords.z,
			rot.x - 90.0,
			rot.y,
			rot.z,
			1.0,
			false, false, false, false)
	end
end)

menu.list_select(hitEffectRoot, translate("Weapon - Hit Effect", "Set Effect"), {}, "", options, 1, function (opt)
	selectedOpt = opt
end)

local name <const> =  translate("Weapon - Hit Effect", "Colour")
local helpText = translate("Weapon - Hit Effect", "Only works on some effects.")
local menuColour =
menu.colour(hitEffectRoot, name, {"effectcolour"}, helpText, effectColour, false,
	function(colour) effectColour = colour end)

menu.rainbow(menuColour)

-------------------------------------
-- VEHICLE GUN
-------------------------------------

---@class Preview
Preview = {handle = 0, modelHash = 0}
Preview.__index = Preview

---@param modelHash Hash
---@return Preview
function Preview.new(modelHash)
	local self = setmetatable({}, Preview)
	self.modelHash = modelHash
	return self
end

---@param pos Vector3
function Preview:create(pos, heading)
	if self:exists() then return end
	self.handle = VEHICLE.CREATE_VEHICLE(self.modelHash, pos.x, pos.y, pos.z, heading, 0, 0, 0)
	ENTITY.SET_ENTITY_ALPHA(self.handle, 153, true)
	ENTITY.SET_ENTITY_COLLISION(self.handle, false, false)
	ENTITY.SET_CAN_CLIMB_ON_ENTITY(self.handle, false)
end

---@param rot Vector3
function Preview:setRotation(rot)
	ENTITY.SET_ENTITY_ROTATION(self.handle, rot.x, rot.y, rot.z, 0, true)
end

---@param pos Vector3
function Preview:setCoords(pos)
	ENTITY.SET_ENTITY_COORDS_NO_OFFSET(self.handle, pos.x, pos.y, pos.z, 0, 0, 0)
end

function Preview:destroy()
	entities.delete_by_handle(self.handle)
	self.handle = 0
end

function Preview:setOnGround()
	VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(self.handle, 1.0)
end

---@return boolean
function Preview:exists()
	return self.handle ~= 0 and ENTITY.DOES_ENTITY_EXIST(self.handle)
end

local vehicles <const> =
{
	"adder",
	"lazer",
	"insurgent2",
	"phantom2",
}
local modelHash = util.joaat("adder")
local preview <const> = Preview.new(modelHash)
local setIntoVehicle = false
local maxDist <const> = 100.0
local minDist <const> = 15.0
local distancePerc = 0.0
local currentDistance = minDist
local lastInput <const> = newTimer()
local vehicleGun <const> = menu.list(weaponOpt, translate("Weapon - Vehicle Gun", "Vehicle Gun"), {}, "")

---@return number
function get_veh_distance()
	if PAD.IS_CONTROL_JUST_PRESSED(2, 241) and distancePerc < 1.0 then
		distancePerc = distancePerc + 0.25
		lastInput.reset()
	elseif PAD.IS_CONTROL_JUST_PRESSED(2, 242) and distancePerc > 0.0 then
		distancePerc = distancePerc - 0.25
		lastInput.reset()
	end
	local distance = interpolate(minDist, maxDist, distancePerc)
	local duration <const> = 200 -- `ms`
	if currentDistance ~= distance and lastInput.elapsed() <= duration then
		currentDistance = interpolate(currentDistance, distance, lastInput.elapsed() / duration)
	end
	return currentDistance
end


menu.toggle_loop(vehicleGun, translate("Weapon - Vehicle Gun", "Vehicle Gun"), {}, "", function ()
	request_model(modelHash)
	local camRot = CAM.GET_GAMEPLAY_CAM_ROT(0)
	local distance = get_veh_distance()
	local raycast = get_raycast_result(distance + 5.0, TraceFlag.world)
	local coords = raycast.didHit and raycast.endCoords or get_offset_from_cam(distance)

	if not Config.general.disablepreview and
	PLAYER.IS_PLAYER_FREE_AIMING(PLAYER.PLAYER_ID()) then
		if not preview:exists() then
			preview.modelHash = modelHash
			preview:create(coords, camRot.z)
		else
			preview:setCoords(coords)
			preview:setRotation(camRot)
			if raycast.didHit then preview:setOnGround() end
		end
	elseif preview:exists() then preview:destroy() end

	if Instructional:begin() then
		Instructional.add_control_group(29, "FM_AE_SORT_2")
		Instructional:set_background_colour(0, 0, 0, 80)
		Instructional:draw()
	end

	if PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) then
		local veh = VEHICLE.CREATE_VEHICLE(modelHash, coords.x, coords.y, coords.z, camRot.z, 1, 1, 0)
		NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(NETWORK.VEH_TO_NET(veh), true)
		ENTITY._SET_ENTITY_CLEANUP_BY_ENGINE(veh, true)
		ENTITY.SET_ENTITY_COORDS_NO_OFFSET(veh, coords.x, coords.y, coords.z, 0, 0, 0)
		ENTITY.SET_ENTITY_ROTATION(veh, camRot.x, camRot.y, camRot.z, 0, true)
		if setIntoVehicle then
			VEHICLE.SET_VEHICLE_ENGINE_ON(veh, 1, 1, 1)
			PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), veh, -1)
		else
			VEHICLE.SET_VEHICLE_DOORS_LOCKED(veh, 2)
		end
		VEHICLE.SET_VEHICLE_FORWARD_SPEED(veh, 200.0)
	end
end, function()
	if preview:exists() then preview:destroy() end
end)


local options <const> =  {{"Adder"}, {"Lazer"}, {"Insurgent"}, {"Phantom Wedge"}}
menu.list_select(vehicleGun, translate("Weapon - Vehicle Gun", "Set Vehicle"), {}, "", options, 1, function (opt)
	local vehicle = vehicles[opt]
	modelHash = util.joaat(vehicle)
end)


local errmsg = translate("Weapon - Vehicle Gun", "The model is not a vehicle")

menu.text_input(vehicleGun, translate("Weapon - Vehicle Gun", "Custom Vehicle"), {"customvehgun"}, "", function(vehicle, click)
	if (click & CLICK_FLAG_AUTO) ~= 0 then
		return
	end
	if STREAMING.IS_MODEL_A_VEHICLE(util.joaat(vehicle)) then
		modelHash = util.joaat(vehicle)
	else notification:help(errmsg, HudColour.red) end
end)

menu.toggle(vehicleGun, translate("Weapon - Vehicle Gun", "Set Into Vehicle"), {}, "", function(toggle)
	setIntoVehicle = toggle
end)

-------------------------------------
-- TELEPORT GUN
-------------------------------------

local function write_vector3(address, vector)
	memory.write_float(address + 0x0, vector.x)
	memory.write_float(address + 0x4, vector.y)
	memory.write_float(address + 0x8, vector.z)
end

local function set_entity_coords(entity, coords)
	local fwEntity = entities.handle_to_pointer(entity)
	local CNavigation = memory.read_long(fwEntity + 0x30)
	if CNavigation ~= 0 then
		write_vector3(CNavigation + 0x50, coords)
		write_vector3(fwEntity + 0x90, coords)
	end
end

menu.toggle_loop(weaponOpt, translate("Weapon", "Teleport Gun"), {"tpgun"}, "", function()
	local raycastResult = get_raycast_result(1000.0)
	if raycastResult.didHit and PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) then
		local coords = raycastResult.endCoords
		if not PED.IS_PED_IN_ANY_VEHICLE(players.user_ped(), false) then
			coords.z = coords.z + 1.0
			set_entity_coords(PLAYER.PLAYER_PED_ID(), coords)
		else
			local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
			local speed = ENTITY.GET_ENTITY_SPEED(vehicle)
			ENTITY.SET_ENTITY_COORDS(vehicle, coords.x, coords.y, coords.z, false, false, false, false)
			ENTITY.SET_ENTITY_HEADING(vehicle, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
			VEHICLE.SET_VEHICLE_FORWARD_SPEED(vehicle, speed + 2.5)
		end
	end
end)

-------------------------------------
-- BULLET SPEED MULT
-------------------------------------

---@class AmmoSpeed
local AmmoSpeed = {address = 0, defaultValue = 0}
AmmoSpeed.__index = AmmoSpeed

---@param address integer
---@return AmmoSpeed
function AmmoSpeed.new(address)
	assert(address ~= 0, "got a nullpointer")
	local instance = setmetatable({}, AmmoSpeed)
	instance.address = address
	instance.defaultValue = memory.read_float(address)
	return instance
end

AmmoSpeed.__eq = function (a, b)
	return a.address == b.address
end

---@return number
function AmmoSpeed:getValue()
	return memory.read_float(self.address)
end

---@param value number
function AmmoSpeed:setValue(value)
	memory.write_float(self.address, value)
end

function AmmoSpeed:reset()
	memory.write_float(self.address, self.defaultValue)
end

local multiplier
---@type AmmoSpeed
local modifiedSpeed
local helpText <const> =
translate("Weapon", "Allows you to change the speed of non-instant hit bullets (rockets, fireworks, etc.)")

menu.slider_float(weaponOpt, translate("Weapon", "Bullet Speed Mult"), {"bulletspeedmult"}, helpText, 10, 100000, 100, 10, function(value)
	multiplier = value / 100
end)

util.create_tick_handler(function()
	local CPed = entities.handle_to_pointer(PLAYER.PLAYER_PED_ID())
	if CPed == 0 or not multiplier then return end
	local ammoSpeedAddress = addr_from_pointer_chain(CPed, {0x10D8, 0x20, 0x60, 0x58})
	if ammoSpeedAddress == 0 then
		if entities.get_user_vehicle_as_pointer() == 0 then return end
		ammoSpeedAddress = addr_from_pointer_chain(CPed, {0x10D8, 0x70, 0x60, 0x58})
		if ammoSpeedAddress == 0 then return end
	end
	local ammoSpeed = AmmoSpeed.new(ammoSpeedAddress)
	modifiedSpeed = modifiedSpeed or ammoSpeed
	if ammoSpeed ~= modifiedSpeed then
		modifiedSpeed:reset()
		modifiedSpeed = ammoSpeed
	end
	local newValue = modifiedSpeed.defaultValue * multiplier
	if modifiedSpeed:getValue() ~= newValue then
		modifiedSpeed:setValue(newValue)
	end
end)

util.on_stop(function ()
	if modifiedSpeed then modifiedSpeed:reset() end
end)

-------------------------------------
-- MAGNET ENTITIES
-------------------------------------

---@class EntityPair
EntityPair = {ent1 = 0, ent2 = 0}
EntityPair.__index = EntityPair

---@param ent1 Entity
---@param ent2 Entity
---@return EntityPair
function EntityPair.new(ent1, ent2)
	local instance = setmetatable({}, EntityPair)
	instance.ent1 = ent1
	instance.ent2 = ent2
	return instance
end

EntityPair.__eq = function (a, b)
	return a.ent1 == b.ent1 and a.ent2 == b.ent2
end

---@return boolean
function EntityPair:exists()
	return ENTITY.DOES_ENTITY_EXIST(self.ent1) and ENTITY.DOES_ENTITY_EXIST(self.ent2)
end

---@param ent Entity
---@param force Vector3
---@param flag? integer
local apply_force_to_ent = function (ent, force, flag)
	if ENTITY.IS_ENTITY_A_PED(ent) then
		if PED.IS_PED_A_PLAYER(ent) then
			return
		else PED.SET_PED_TO_RAGDOLL(ent, 1000, 1000, 0, 0, 0, 0) end
	end
	if request_control_once(ent) then
		ENTITY.APPLY_FORCE_TO_ENTITY(ent, flag or 1, force.x, force.y, force.z, 0.0, 0.0, 0.0, 0, false, false, true, 0, 0)
	end
end

function EntityPair:attract()
	local pos1 = ENTITY.GET_ENTITY_COORDS(self.ent1, false)
	local pos2 = ENTITY.GET_ENTITY_COORDS(self.ent2, false)
	local force = v3.new(pos2)
	force:sub(pos1)
	force:mul(0.05)
	apply_force_to_ent(self.ent1, force)
	force:mul(-1)
	apply_force_to_ent(self.ent2, force)
end

local shotEntities = {}
local counter = 0
---@type EntityPair[]
local entityPairs = {}
local helpText = translate("Weapon", "Shoot two entities to attract them to each other")

menu.toggle_loop(weaponOpt, translate("Weapon", "Magnet Entities"), {"magnetents"}, helpText, function()
	local entity = get_entity_player_is_aiming_at(players.user())
	if entity ~= 0 and ENTITY.DOES_ENTITY_EXIST(entity) then
		draw_box_esp(entity, {r = 255, g = 0, b = 255, a = 255})
		if PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) and
		not (shotEntities[1] and shotEntities[1] == entity) then
			counter = counter + 1
			shotEntities[counter] = entity
		end
		if counter == 2 then
			local entPair = EntityPair.new(table.unpack(shotEntities))
			table.insert_once(entityPairs, entPair)
			counter = 0
			shotEntities = {}
		end
	end
	for i = #entityPairs, 1, -1 do
		local entPair = entityPairs[i]
		if entPair:exists() then entPair:attract() else table.remove(entityPairs, i) end
	end
end, function ()
	counter = 0
	shotEntities = {}; entityPairs = {}
end)

-------------------------------------
-- VALKYIRE ROCKET
-------------------------------------

menu.toggle(weaponOpt, translate("Weapon", "Valkyire Rocket"), {"valkrocket"}, "", function(toggle)
	gUsingValkRocket = toggle
	if gUsingValkRocket then
		local rocket
		local cam
		local blip
		local init
		local timer <const> = newTimer()
		local draw_rect = function(x, y, z, w)
			GRAPHICS.DRAW_RECT(x, y, z, w, 255, 255, 255, 255, 0)
		end

		while gUsingValkRocket do
			util.yield()
			if PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) and not init then
				init = true
				timer.reset()
			elseif init then
				if not ENTITY.DOES_ENTITY_EXIST(rocket) then
					local offset = get_offset_from_cam(10)
					rocket = entities.create_object(util.joaat("w_lr_rpg_rocket"), offset)
					ENTITY.SET_ENTITY_INVINCIBLE(rocket, true)
					ENTITY._SET_ENTITY_CLEANUP_BY_ENGINE(rocket, true)
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
					CAM._ATTACH_CAM_TO_ENTITY_WITH_FIXED_DIRECTION(cam, rocket, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1)
					CAM.SET_CAM_ACTIVE(cam, true)
					CAM.RENDER_SCRIPT_CAMS(true, false, 0, true, true, 0)

					PLAYER.DISABLE_PLAYER_FIRING(PLAYER.PLAYER_PED_ID(), true)
					ENTITY.FREEZE_ENTITY_POSITION(PLAYER.PLAYER_PED_ID(), true)
				else
					local rot = CAM.GET_GAMEPLAY_CAM_ROT(0)
					local coords = ENTITY.GET_ENTITY_COORDS(rocket, false)
					local force = rot:toDir()
					force:mul(40.0)

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
					draw_rect(0.5 + 0.050, 0.5, 0.050, 0.002)
					draw_rect(0.5 - 0.050, 0.5, 0.050, 0.002)
					draw_rect(0.5, 0.500 + 0.05, 0.002, 0.05)
					draw_rect(0.5, 0.500 - 0.05, 0.002, 0.05)

					local maxTime = 7000 -- `ms`
					local length = 0.5 - 0.5 * (timer.elapsed() / maxTime) -- timer length
					local perc = length / 0.5
					local color = get_blended_colour(perc) -- timer color
					GRAPHICS.DRAW_RECT(0.25, 0.5, 0.03, 0.5, 255, 255, 255, 120, false)
					GRAPHICS.DRAW_RECT(0.25, 0.75 - length / 2, 0.03, length, color.r, color.g, color.b, color.a, false)

					if ENTITY.HAS_ENTITY_COLLIDED_WITH_ANYTHING(rocket) or length <= 0 then
						local impactCoord = ENTITY.GET_ENTITY_COORDS(rocket, false)
						FIRE.ADD_EXPLOSION(impactCoord.x, impactCoord.y, impactCoord.z, 32, 1.0, true, false, 0.4, false)
						entities.delete_by_handle(rocket)
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
		end

		if rocket and ENTITY.DOES_ENTITY_EXIST(rocket) then
			local impactCoord = ENTITY.GET_ENTITY_COORDS(rocket, false)
			FIRE.ADD_EXPLOSION(impactCoord.x, impactCoord.y, impactCoord.z, 32, 1.0, true, false, 0.4, false)
			entities.delete_by_handle(rocket)
			STREAMING.CLEAR_FOCUS()
			CAM.RENDER_SCRIPT_CAMS(false, false, 3000, true, false, 0)
			CAM.DESTROY_CAM(cam, 1)
			GRAPHICS.SET_TIMECYCLE_MODIFIER("DEFAULT")
			ENTITY.FREEZE_ENTITY_POSITION(PLAYER.PLAYER_PED_ID(), false)
			PLAYER.DISABLE_PLAYER_FIRING(PLAYER.PLAYER_PED_ID(), false)
			if HUD.DOES_BLIP_EXIST(blip) then util.remove_blip(blip) end
			HUD.UNLOCK_MINIMAP_ANGLE()
			HUD.UNLOCK_MINIMAP_POSITION()
		end
	end
end)

-------------------------------------
-- GUIDED MISSILE
-------------------------------------

menu.action(weaponOpt, translate("Weapon", "Launch Guided Missile"), {"missile"}, "", function()
	if not UFO.exists() then GuidedMissile.create() end
end)

util.on_stop(function ()
	GuidedMissile.onStop()
end)

-------------------------------------
-- SUPERPUNCH
-------------------------------------

menu.toggle_loop(weaponOpt, translate("Weapon", "Superpunch"), {"superpunch"}, "", function()
	local pWeapon = memory.alloc_int()
	WEAPON.GET_CURRENT_PED_WEAPON(players.user_ped(), pWeapon, 1)
	local weaponHash = memory.read_int(pWeapon)
	if WEAPON.IS_PED_ARMED(players.user_ped(), 1) or weaponHash == util.joaat("weapon_unarmed") then
		local pImpactCoords = v3.new()
		local pos = ENTITY.GET_ENTITY_COORDS(players.user_ped(), false)
		if WEAPON.GET_PED_LAST_WEAPON_IMPACT_COORD(players.user_ped(), pImpactCoords) then
			set_explosion_proof(players.user_ped(), true)
			util.yield_once()
			FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z - 1.0, 29, 5.0, false, true, 0.3, true)
		elseif not FIRE.IS_EXPLOSION_IN_SPHERE(29, pos.x, pos.y, pos.z, 2.0) then
			set_explosion_proof(players.user_ped(), false)
		end
	end
end)

---------------------
---------------------
-- VEHICLE
---------------------
---------------------

local vehicleOptions <const> = menu.list(menu.my_root(), translate("Vehicle", "Vehicle"), {}, "")

-------------------------------------
-- AIRSTRIKE AIRCRAFT
-------------------------------------

local vehicleWeaponRoot <const> = menu.list(vehicleOptions, translate("Vehicle", "Vehicle Weapons"), {"vehicleweapons"}, "")
local state = 0
local hash <const> = util.joaat("weapon_airstrike_rocket")
local trans =
{
	MenuName = translate("Vehicle", "Airstrike Aircraft"),
	Help = translate("Vehicle", "Use any plane or helicopter to make airstrikes"),
	CornerHelp = translate("Vehicle", "Press ~%s~ to use Airstrike Aircraft"),
	Notification = translate("Vehicle", "Airstrike Aircraft can be used in planes and helicopters"),
	HelpText = translate("Vehicle", "Use any plane or helicopter to make airstrikes"),
}


menu.toggle_loop(vehicleOptions, trans.MenuName, {"airstrikeplane"}, trans.HelpText, function ()
	local control = Config.controls.airstrikeaircraft
	if state == 0 then
		local action_name = table.find_if(Imputs, function (k, tbl)
			return tbl[2] == control
		end)
		assert(action_name, "control name not found")
		notification:help(trans.Notification)
		util.show_corner_help(trans.CornerHelp:format(action_name))
		state = 1
	end

	if PED.IS_PED_IN_FLYING_VEHICLE(players.user_ped()) and PAD.IS_CONTROL_PRESSED(2, control) then
		local start <const> = newTimer()
		local vehicle = PED.GET_VEHICLE_PED_IS_IN(players.user_ped(), false)
		local pos = ENTITY.GET_ENTITY_COORDS(vehicle, false)

		util.create_tick_handler(function()
			util.yield(500)

			local groundz = get_ground_z(pos)
			pos.x = pos.x + random_float(-3, 3)
			pos.y = pos.y + random_float(-3, 3)
			if pos.z - groundz < 10.0 then return end

			MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z-3.0, pos.x, pos.y, groundz, 200, true, hash, players.user(), true, false, 2500.0)
			return start.elapsed() < 5000
		end)

		util.yield(200)
	end
end, function() state = 0 end)

-------------------------------------
-- VEHICLE WEAPONS
-------------------------------------

---@param vehicle Vehicle
---@return number heading
local get_vehicle_cam_relative_heading = function(vehicle)
	local camDir = CAM.GET_GAMEPLAY_CAM_ROT(0):toDir()
	local fwdVector = ENTITY.GET_ENTITY_FORWARD_VECTOR(vehicle)
	camDir.z, fwdVector.z = 0.0, 0.0
	local angle = math.acos(fwdVector:dot(camDir) / (#camDir * #fwdVector))
	return math.deg(angle)
end

local shoot_from_vehicle = function (vehicle, damage, weaponHash, ownerPed, isAudible, isVisible, speed, target, position)
	local min, max = v3.new(), v3.new()
	local offset
	MISC.GET_MODEL_DIMENSIONS(ENTITY.GET_ENTITY_MODEL(vehicle), min, max)
	if position == 0 then
		offset = {x = min.x, y = max.y + 0.25, z = 0.3}
	elseif position == 1 then
		offset = {x = min.x, y = min.y, z = 0.3}
	elseif position == 2 then
		offset = {x = max.x, y = max.y + 0.25, z = 0.3}
	elseif position == 3 then
		offset = {x = max.x, y = min.y, z = 0.3}
	else
		error("got unexpected position")
	end
	local a = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, offset.x, offset.y, offset.z)
	local direction = ENTITY.GET_ENTITY_ROTATION(vehicle, 2):toDir()
	local b = v3.new(direction)
	if get_vehicle_cam_relative_heading(vehicle) > 95.0 then
		b:mul(-1)
	end
	b:mul(300.0); b:add(a)
	MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS_IGNORE_ENTITY_NEW(a.x, a.y, a.z, b.x, b.y, b.z,
			damage, true, weaponHash, ownerPed, isAudible, not isVisible, speed, vehicle, 0, 0, target, 0, 0, 0, 0)
end

-------------------------------------
-- VEHICLE LASER
-------------------------------------

menu.toggle_loop(vehicleWeaponRoot, translate("Vehicle - Vehicle Weapons", "Vehicle Lasers"), {"vehiclelasers"}, "", function ()
	if PED.IS_PED_IN_ANY_VEHICLE(PLAYER.PLAYER_PED_ID(), false) then
		local vehicle = get_vehicle_player_is_in(players.user())
		local min, max = v3.new(), v3.new()
		MISC.GET_MODEL_DIMENSIONS(ENTITY.GET_ENTITY_MODEL(vehicle), min, max)
		local startLeft = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, min.x, max.y, 0.0)
		local endLeft = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, min.x, max.y + 25.0, 0)
		GRAPHICS.DRAW_LINE(startLeft.x, startLeft.y, startLeft.z, endLeft.x, endLeft.y, endLeft.z, 255, 0, 0, 150)

		local startRight = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, max.x, max.y, 0.0)
		local endRight = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, max.x, max.y + 25.0, 0)
		GRAPHICS.DRAW_LINE(startRight.x, startRight.y, startRight.z, endRight.x, endRight.y, endRight.z, 255, 0, 0, 150)
	end
end)

-------------------------------------
-- VEHICLE WEAPONS
-------------------------------------

---@class VehicleWeapon
VehicleWeapon = {modelName = "", timeBetweenShots = 0}
VehicleWeapon.__index = VehicleWeapon

function VehicleWeapon.new(modelName, timeBetweenShots)
	local instance = setmetatable({}, VehicleWeapon)
	instance.modelName = modelName
	instance.timeBetweenShots = timeBetweenShots
	return instance
end

---@type table<string, VehicleWeapon>
local vehicleWeaponList <const> = {
	VehicleWeapon.new("weapon_vehicle_rocket", 220),
	VehicleWeapon.new("weapon_raypistol", 50),
	VehicleWeapon.new("weapon_firework", 220),
	VehicleWeapon.new("vehicle_weapon_tank", 220),
	VehicleWeapon.new("vehicle_weapon_player_lazer", 30)
}
local options <const> = {
	{util.get_label_text("WT_V_SPACERKT")}, {util.get_label_text("WT_RAYPISTOL")},
	{util.get_label_text("WT_FWRKLNCHR")}, {util.get_label_text("WT_V_TANK")}, {util.get_label_text("WT_V_PLRBUL")}
}
local selectedOpt = 1
local state = 0
local timer <const> = newTimer()
local msg = translate("Vehicle - Vehicle Weapons", "Press ~%s~ to use Vehicle Weapons")

local vehicleWeapons =
menu.toggle_loop(vehicleWeaponRoot, translate("Vehicle - Vehicle Weapons", "Vehicle Weapons"), {}, "", function()
	local control = Config.controls.vehicleweapons

	if state == 0 or timer.elapsed() > 120000 then
		local controlName = table.find_if(Imputs, function(k, tbl)
			return tbl[2] == control
		end)
		assert(controlName, "control name not found")
		util.show_corner_help(msg:format(controlName))
		state = 1
		timer.reset()
	end

	local selectedWeapon = vehicleWeaponList[selectedOpt]
	local vehicle = get_vehicle_player_is_in(players.user())
	local weaponHash <const> = util.joaat(selectedWeapon.modelName)
	request_weapon_asset(weaponHash)

	if not ENTITY.DOES_ENTITY_EXIST(vehicle) or not PAD.IS_CONTROL_PRESSED(0, control) or
	timer.elapsed() < selectedWeapon.timeBetweenShots then
		return
	elseif get_vehicle_cam_relative_heading(vehicle) < 95.0 then
		shoot_from_vehicle(vehicle, 200, weaponHash, players.user_ped(), true, true, 2000.0, 0, 0)
		shoot_from_vehicle(vehicle, 200, weaponHash, players.user_ped(), true, true, 2000.0, 0, 2)
		timer.reset()
	else
		shoot_from_vehicle(vehicle, 200, weaponHash, players.user_ped(), true, true, 2000.0, 0, 1)
		shoot_from_vehicle(vehicle, 200, weaponHash, players.user_ped(), true, true, 2000.0, 0, 3)
		timer.reset()
	end
end, function () state = 0 end)


menu.list_select(vehicleWeaponRoot, translate("Vehicle - Vehicle Weapons", "Set Vehicle Weapons"), {}, "",
	options, 1, function (index) selectedOpt = index end)

-------------------------------------
-- VEHICLE HOMING MISSILE
-------------------------------------

local reference
local name = translate("Vehicle - Vehicle Weapons", "Advanced Homing Missiles")
local helpText =
translate("Vehicle - Vehicle Weapons", "Allows you to use homing missiles on any vehicle and " ..
"shoot up to six targets at once")

reference =
menu.toggle_loop(vehicleWeaponRoot, name, {"homingmissiles"}, helpText, function ()
	if UFO.exists() or GuidedMissile.exists() then
		menu.set_value(reference, false)
	else
		homingMissiles.mainLoop()
	end
end, function () homingMissiles.reset() end)


local name = translate("Vehicle - Vehicle Weapons", "Homing Missiles: Ignore Friends")
local helpText =
translate("Vehicle - Vehicle Weapons", "Makes the Advanced Homing Missiles to ignores friends")
menu.toggle(vehicleWeaponRoot, name, {}, helpText, function (on)
	homingMissiles.ignoreFriends(on)
end)

-------------------------------------
-- VEHICLE HANDLING EDITOR
-------------------------------------

CHandlingData =
{
	--{"m_model_hash", 0x0008},
	{"fMass", 0x000C},
	{"fInitialDragCoeff", 0x0010},
	{"fDownforceModifier", 0x0014},
	{"fPopUpLightRotation", 0x0018},
	{"vecCentreOfMassOffsetX", 0x0020},
	{"vecCentreOfMassOffsetY", 0x0024},
	{"vecCentreOfMassOffsetZ", 0x0028},
	{"vecInertiaMultiplierX", 0x0030},
	{"vecInertiaMultiplierY", 0x0034},
	{"vecInertiaMultiplierZ", 0x0038},
	{"fPercentSubmerged", 0x0040},
	{"fSubmergedRatio", 0x0044},
	{"fDriveBiasFront", 0x0048},
	{"fDriveBiasRear", 0x004C},
	--{"nInitialDriveGears", 0x0050},
	{"fDriveInertia", 0x0054},
	{"fClutchChangeRateScaleUpShift", 0x0058},
	{"fClutchChangeRateScaleDownShift", 0x005C},
	{"fInitialDriveForce", 0x0060},
	{"fDriveMaxFlatVel", 0x0064},
	{"fInitialDriveMaxFlatVel", 0x0068},
	{"fBrakeForce", 0x006C},
	{"fBrakeBiasFront", 0x0074},
	{"fBrakeBiasRear", 0x0078},
	{"fHandBrakeForce", 0x007C},
	{"fSteeringLock", 0x0080},
	{"fSteeringLockRatio", 0x0084},
	{"fTractionCurveMax", 0x0088},
	{"fTractionCurveMaxRatio", 0x008C},
	{"fTractionCurveMin", 0x0090},
	{"fTractionCurveRatio", 0x0094},
	{"fTractionCurveLateral", 0x0098},
	{"fTractionCurveLateralRatio", 0x009C},
	{"fTractionSpringDeltaMax", 0x00A0},
	{"fTractionSpringDeltaMaxRatio", 0x00A4},
	{"fLowSpeedTractionLossMult", 0x00A8},
	{"fCamberStiffnesss", 0x00AC},
	{"fTractionBiasFront", 0x00B0},
	{"fTractionBiasRear", 0x00B4},
	{"fTractionLossMult", 0x00B8},
	{"fSuspensionForce", 0x00BC},
	{"fSuspensionCompDamp", 0x00C0},
	{"fSuspensionReboundDamp", 0x00C4},
	{"fSuspensionUpperLimit", 0x00C8},
	{"fSuspensionLowerLimit", 0x00CC},
	{"fSuspensionRaise", 0x00D0},
	{"fSuspensionBiasFront", 0x00D4},
	{"fSuspensionBiasRear", 0x00D8},
	{"fAntiRollBarForce", 0x00DC},
	{"fAntiRollBarBiasFront", 0x00E0},
	{"fAntiRollBarBiasRear", 0x00E4},
	{"fRollCentreHeightFront", 0x00E8},
	{"fRollCentreHeightRear", 0x00EC},
	{"fCollisionDamageMult", 0x00F0},
	{"fWeaponDamageMult", 0x00F4},
	{"fDeformationDamageMult", 0x00F8},
	{"fEngineDamageMult", 0x00FC},
	{"fPetrolTankVolume", 0x0100},
	{"fOilVolume", 0x0104},
	{"fSeatOffsetDistX", 0x010C},
	{"fSeatOffsetDistY", 0x0110},
	{"fSeatOffsetDistZ", 0x0114},
	--{"nMonetaryValue", 0x0118},
	--{"strModelFlags", 0x0124},
	--{"strHandlingFlags", 0x0128},
	--{"strDamageFlags", 0x012C},
	--{"AIHandling", 0x013C},
}

CFlyingHandlingData =
{
	{"fThrust", 0x0008},
	{"fThrustFallOff", 0x000C},
	{"fThrustVectoring", 0x0010},
	{"fYawMult", 0x001C},
	{"fYawStabilise", 0x0020},
	{"fSideSlipMult", 0x0024},
	{"fRollMult", 0x002C},
	{"fRollStabilise", 0x0030},
	{"fPitchMult", 0x0038},
	{"fPitchStabilise", 0x003C},
	{"fFormLiftMult", 0x0044},
	{"fAttackLiftMult", 0x0048},
	{"fAttackDiveMult", 0x004C},
	{"fGearDownDragV", 0x0050},
	{"fGearDownLiftMult", 0x0054},
	{"fWindMult", 0x0058},
	{"fMoveRes", 0x005C},
	{"vecTurnResX", 0x0060},
	{"vecTurnResY", 0x0064},
	{"vecTurnResZ", 0x0068},
	{"vecSpeedResX", 0x0070},
	{"vecSpeedResY", 0x0074},
	{"vecSpeedResZ", 0x0078},
	{"fGearDoorFrontOpen", 0x0080},
	{"fGearDoorRearOpen", 0x0084},
	{"fGearDoorRearOpen2", 0x0088},
	{"fGearDoorRearMOpen", 0x008C},
	{"fTurbulanceMagnitudMax", 0x0090},
	{"fTurbulanceForceMulti", 0x0094},
	{"fTurbulanceRollTorqueMulti", 0x0098},
	{"fTurbulancePitchTorqueMulti", 0x009C},
	{"fBodyDamageControlEffectMult", 0x00A0},
	{"fInputSensitivityForDifficulty", 0x00A4},
	{"fOnGroundYawBoostSpeedPeak", 0x00A8},
	{"fOnGroundYawBoostSpeedCap", 0x00AC},
	{"fEngineOffGlideMult", 0x00B0},
	{"fAfterburnerEffectRadius", 0x00B4},
	{"fAfterburnerEffectDistance", 0x00B8},
	{"fAfterburnerEffectForceMulti", 0x00BC},
	{"fSubmergeLevelToPullHeliUnderWater", 0x00C0},
	{"fExtraLiftWithRoll", 0x00C4},
}

SubHandlingData =
{
	CBikeHandlingData = 
	{
		{"fLeanFwdCOMMult", 0x0008},
		{"fLeanFwdForceMult", 0x000C},
		{"fLeanBakCOMMult", 0x0010},
		{"fLeanBakForceMult", 0x0014},
		{"fMaxBankAngle", 0x0018},
		{"fFullAnimAngle", 0x001C},
		{"fDesLeanReturnFrac", 0x0024},
		{"fStickLeanMult", 0x0028},
		{"fBrakingStabilityMult", 0x002C},
		{"fInAirSteerMult", 0x0030},
		{"fWheelieBalancePoint", 0x0034},
		{"fStoppieBalancePoint", 0x0038},
		{"fWheelieSteerMult", 0x003C},
		{"fRearBalanceMult", 0x0040},
		{"fFrontBalanceMult", 0x0044},
		{"fBikeGroundSideFrictionMult", 0x0048},
		{"fBikeWheelGroundSideFrictionMult", 0x004C},
		{"fBikeOnStandLeanAngle", 0x0050},
		{"fBikeOnStandSteerAngle", 0x0054},
		{"fJumpForce", 0x0058},
	},
	CFlyingHandlingData = CFlyingHandlingData,
	CFlyingHandlingData2 = CFlyingHandlingData,
	CBoatHandlingData =
	{
		{"fBoxFrontMult", 0x0008},
		{"fBoxRearMult", 0x000C},
		{"fBoxSideMult", 0x0010},
		{"fSampleTop", 0x0014},
		{"fSampleBottom", 0x0018},
		{"fSampleBottomTestCorrection", 0x001C},
		{"fAquaplaneForce", 0x0020},
		{"fAquaplanePushWaterMult", 0x0024},
		{"fAquaplanePushWaterCap", 0x0028},
		{"fAquaplanePushWaterApply", 0x002C},
		{"fRudderForce", 0x0030},
		{"fRudderOffsetSubmerge", 0x0034},
		{"fRudderOffsetForce", 0x0038},
		{"fRudderOffsetForceZMult", 0x003C},
		{"fWaveAudioMult", 0x0040},
		{"vecMoveResistanceX", 0x0050},
		{"vecMoveResistanceY", 0x0054},
		{"vecMoveResistanceZ", 0x0058},
		{"vecTurnResistanceX", 0x0060},
		{"vecTurnResistanceY", 0x0064},
		{"vecTurnResistanceZ", 0x0068},
		{"fLook_L_R_CamHeight", 0x0070},
		{"fDragCoefficient", 0x0074},
		{"fKeelSphereSize", 0x0078},
		{"fPropRadius", 0x007C},
		{"fLowLodAngOffset", 0x0080},
		{"fLowLodDraughtOffset", 0x0084},
		{"fImpellerOffset", 0x0088},
		{"fImpellerForceMult", 0x008C},
		{"fDinghySphereBuoyConst", 0x0090},
		{"fProwRaiseMult", 0x0094},
		{"fDeepWaterSampleBuoyancyMult", 0x0098},
		{"fTransmissionMultiplier", 0x009C},
		{"fTractionMultiplier", 0x00A0},
	},
	CSeaPlaneHandlingData =
	{
		{"fPontoonBuoyConst", 0x0010},
		{"fPontoonSampleSizeFront", 0x0014},
		{"fPontoonSampleSizeMiddle", 0x0018},
		{"fPontoonSampleSizeRear", 0x001C},
		{"fPontoonLengthFractionForSamples", 0x0020},
		{"fPontoonDragCoefficient", 0x0024},
		{"fPontoonVerticalDampingCoefficientUp", 0x0028},
		{"fPontoonVerticalDampingCoefficientDown", 0x002C},
		{"fKeelSphereSize", 0x0030},
	},
	CSubmarineHandlingData =
	{
		{"vTurnResX", 0x0010},
		{"vTurnResY", 0x0014},
		{"vTurnResZ", 0x0018},
		{"fMoveResXY", 0x0020},
		{"fMoveResZ", 0x0024},
		{"fPitchMult", 0x0028},
		{"fPitchAngle", 0x002C},
		{"fYawMult", 0x0030},
		{"fDiveSpeed", 0x0034},
		{"fRollMult", 0x0038},
		{"fRollStab", 0x003C}
	},
	CTrainHandlingData =
	{
	},
	CTrailerHandlingData =
	{
	},
	CCarHandlingData =
	{
		{"fBackEndPopUpCarImpulseMult", 0x0008},
		{"fBackEndPopUpBuildingImpulseMult", 0x000C},
		{"fBackEndPopUpMaxDeltaSpeed", 0x0010},
		{"fToeFront", 0x0014},
		{"fToeRear", 0x0018},
		{"fCamberFront", 0x001C},
		{"fCamberRear", 0x0020},
		{"fCastor", 0x0024},
		{"fEngineResistance", 0x0028},
		{"fMaxDriveBiasTransfer", 0x002C},
		{"fJumpForceScale", 0x0030},
		--{"strAdvancedFlags", 0x003C},
	},
	CVehicleWeaponHandlingData =
	{
		{"fUvAnimatiomMult", 0x0320},
		{"fMiscGadgetVar", 0x0324},
		{"fWheelImpactOffset", 0x0328}
	},
	CSpecialFlightHandlingData =
	{
		{"vecAngularDampingX", 0x0010},
		{"vecAngularDampingY", 0x0014},
		{"vecAngularDampingZ", 0x0018},
		{"vecAngularDampingMinX", 0x0020},
		{"vecAngularDampingMinY", 0x0024},
		{"vecAngularDampingMinZ", 0x0028},
		{"vecLinearDampingX", 0x0030},
		{"vecLinearDampingY", 0x0034},
		{"vecLinearDampingZ", 0x0038},
		{"vecLinearDampingMinX", 0x0040},
		{"vecLinearDampingMinY", 0x0044},
		{"vecLinearDampingMinZ", 0x0048},
		{"fLiftCoefficient", 0x0050},
		{"fMinLiftVelocity", 0x0060},
		{"fDragCoefficient", 0x006C},
		{"fRollTorqueScale", 0x0070},
		{"fYawTorqueScale", 0x007C},
		{"fMaxPitchTorque", 0x0088},
		{"fMaxSteeringRollTorque", 0x008C},
		{"fPitchTorqueScale", 0x0090},
		{"fMaxThrust", 0x0098},
		{"fTransitionDuration", 0x009C},
		{"fHoverVelocityScale", 0x00A0},
		{"fMinSpeedForThrustFalloff", 0x00A8},
		{"fBrakingThrustScale", 0x00AC},
		--{"strFlags", 0x00B8},
	},
}

-------------------------------------
-- HANDLING SECTION
-------------------------------------

HandlingType =
{
	Bike = 0,
	Flying = 1,
	VerticalFlying = 2,
	Boat = 3,
	SeaPlane = 4,
	Submarine = 5,
	Train = 6,
	Trailer = 7,
	Car = 8,
	Weapon = 9,
	SpecialFlight = 10,
}

---@param address integer
---@param index integer
---@return integer
local get_vtable_entry_pointer = function(address, index)
    return memory.read_long(memory.read_long(address) + (8 * index))
end

---@class SubHandling
---@field type integer
---@field address integer

---@param pVehicle integer #pointer to CAutomobile
---@return SubHandling[]
local function get_vehicle_sub_handling(pVehicle)
	local CHandlingData = memory.read_long(pVehicle + 0x938)
	local subHandlingArray = memory.read_long(CHandlingData + 0x158)
	local numSubHandling = memory.read_ushort(CHandlingData + 0x160)
	local tbl = {}
	for i = 0, numSubHandling -1 do
		local subHandlingData = memory.read_long(subHandlingArray + i*8)
		if subHandlingData ~= NULL then
			local GetSubhandlingType_addr = get_vtable_entry_pointer(subHandlingData, 2)
			local result =
			util.call_foreign_function(GetSubhandlingType_addr, subHandlingData)
			if table.find(HandlingType, result) then
				tbl[#tbl+1] = {type = result, address = subHandlingData}
			end
		end
	end
	return tbl
end

---@param t integer #The subhandling type.
---@return string
local function get_sub_handling_type_name(t)
	if t == HandlingType.Bike then
		return "CBikeHandlingData"
	elseif t == HandlingType.Flying then
		return "CFlyingHandlingData"
	elseif t == HandlingType.VerticalFlying then
		return "CFlyingHandlingData2"
	elseif t == HandlingType.Boat then
		return "CBoatHandlingData"
	elseif t == HandlingType.SeaPlane then
		return "CSeaPlaneHandlingData"
	elseif t == HandlingType.Submarine then
		return "CSubmarineHandlingData"
	elseif t == HandlingType.Train then
		return "CTrainHandlingData"
	elseif t == HandlingType.Trailer then
		return "CTrailerHandlingData"
	elseif t == HandlingType.Car then
		return "CCarHandlingData"
	elseif t == HandlingType.Weapon then
		return "CVehicleWeaponHandlingData"
	elseif t == HandlingType.SpecialFlight then
		return "CSpecialFlightHandlingData"
	else
		error("got unexpected handling type")
	end
end

-------------------------------------
-- HANDLING DATA
-------------------------------------

---@class HandlingData
HandlingData =
{
	reference = 0,
	name = "",
	baseAddress = NULL,
	isVisible = true,
	offsets = {},
	isOpen = false,
}
HandlingData.__index = HandlingData

---@param parent integer
---@param name string
---@param baseAddress? integer
---@param offsets {[1]: string, [2]: integer}[] #Each table must have the param name, and offset from base address.
---@return HandlingData
function HandlingData.new(parent, name, baseAddress, offsets)
	assert(type(offsets) == "table", "offsets must be a table, got " .. type(offsets))
	local self = setmetatable({}, HandlingData)
	self.baseAddress = baseAddress
	self.name = name
	self.reference = menu.list(parent, name, {}, "", function ()
		self.isOpen = true
		if self.baseAddress == NULL then menu.focus(parent) end
	end, function()
		self.isOpen = false
	end)
	menu.divider(self.reference, name)
	self.offsets = offsets
	for _, o in ipairs(offsets) do
		local optname, offset <const> = o[1], o[2]
		self:createOpt(self.reference, optname, offset)
	end
	return self
end

---@param parent integer
---@param name string
---@param offset integer
function HandlingData:createOpt(parent, name, offset)
	menu.action(parent, name, {}, "", function ()
		self:writeValueFromUser(offset)
	end)
end

---@param offset integer
function HandlingData:writeValueFromUser(offset)
	local label = customLabels.EnterValue
	while true do
		assert(self.baseAddress ~= 0, "base address is a null pointer")
		local value = memory.read_float(self.baseAddress + offset)
		local newValue = get_input_from_screen_keyboard(label, 20, round(value, 5))
		if newValue == "" then break end
		if not tonumber(newValue) then
			label = customLabels.ValueMustBeNumber
		else
			memory.write_float(self.baseAddress + offset, tonumber(newValue))
			break
		end
		util.yield(250)
	end
end

---@param visible boolean
function HandlingData:setVisible(visible)
	if self.isVisible == visible then return end
	menu.set_visible(self.reference, visible)
	self.isVisible = visible
end

---@return table<string, number>
function HandlingData:get()
	assert(self.baseAddress ~= NULL, "base address is a null pointer")
	local result = {}
	for _, tbl in ipairs(self.offsets) do
		local optname, offset <const> = tbl[1], tbl[2]
		local value = memory.read_float(self.baseAddress + offset)
		result[optname] = round(value, 5)
	end
	return result
end

---@param values {[1]: string, [2]: number}[] #Each table must have the param name (string) and value (number).
function HandlingData:set(values)
	assert(self.baseAddress ~= NULL, self.name .. "'s base address is a null pointer")
	local count = 0
	for _, tbl in ipairs(self.offsets) do
		local optname, offset <const> = tbl[1], tbl[2]
		local value = values[optname]
		assert(value == nil or type(value) == "number", "expected field " .. optname .. " to be a number or nil, got " .. type(value))
		if value then memory.write_float(self.baseAddress + offset, value); count = count + 1 end
	end
	util.log("%d/%d parameters loaded for %s", count, #self.offsets, self.name)
end

-------------------------------------
-- FILELIST
-------------------------------------

---@class SubOpt
---@field name string
---@field callback fun(filename: string, ext: string, path: string)

---@class FilesList
FilesList =
{
	reference = 0,
	dir = "",
	---@type string
	ext = nil,
	isOpen = false,
	fileOpts = {},
	---@type SubOpt[]
	subOpts = {},
}
FilesList.__index = FilesList

---@param parent integer
---@param name string
---@param directory string
---@param ext? string #The extension the file must match to be loaded.
---@return FilesList
function FilesList.new(parent, name, directory, ext)
	local self = setmetatable({}, FilesList)
	self.dir = directory
	self.ext = ext
	self.subOpts, self.fileOpts = {}, {}
	self.reference = menu.list(parent, name, {}, "", function ()
		self.isOpen = true; self:load()
	end, function ()
		self.isOpen = false; self:clear()
	end)
	return self
end

function FilesList:load()
	if not self.dir or not filesystem.exists(self.dir) or
	not filesystem.is_dir(self.dir) then
		return
	end
	for _, path in ipairs(filesystem.list_files(self.dir)) do
		local name, ext = string.match(path, '^.+\\(.+)%.(.+)$')
		if not self.ext or self.ext == ext then self:createOpt(name, ext, path) end
	end
end

---@param filename string
---@param ext string
---@param path string
function FilesList:createOpt(filename, ext, path)
	local list <const> = menu.list(self.reference, filename, {}, "")
	for _, subOpt in ipairs(self.subOpts) do
		menu.action(list, subOpt.name, {subOpt.name .. filename}, "", function () subOpt.callback(filename, ext, path) end)
	end
	self.fileOpts[#self.fileOpts+1] = list
end

---@param filename string #Must include file extension.
---@param content string
function FilesList:add(filename, content)
	assert(self.dir ~= "", "tried to add a file to a null directory")
	if not filesystem.exists(self.dir) then
		filesystem.mkdir(self.dir)
	end
	local name, ext = string.match(filename, '^(.+)%.(.+)$')
	assert(name and ext, "couldn't match file name or extension")
	if filesystem.exists(self.dir .. filename) then
		local count = 2
		repeat
			filename = string.format("%s (%s).%s", name, count, ext)
			count = count + 1
		until not filesystem.exists(self.dir .. filename)
	end
	local file <close> = assert(io.open(self.dir .. filename, "w"))
	file:write(content)
end

function FilesList:clear()
	if #self.fileOpts == 0 then return end
	for i, ref in ipairs(self.fileOpts) do
		menu.delete(ref); self.fileOpts[i] = nil
	end
end

function FilesList:reload()
	self:clear(); self:load()
end

---@param name string
---@param onClick fun(name:string, ext: string, path: string)
function FilesList:addSubOpt(name, onClick)
	table.insert(self.subOpts, {name = name, callback = onClick})
end

function FilesList:isLoaded()
	return #self.fileOpts > 0
end

-------------------------------------
-- HANDLING EDITOR
-------------------------------------

---@class HandlingEditor
HandlingEditor =
{
	reference = 0,
	isOpen = false,
	---@type table<string, HandlingData>
	subHandlingData = {},
	ref_vehicleName = 0,
	ref_save = 0,
	---@type FilesList
	savedFiles = nil,
	---@type HandlingData
	handlingData = nil, -- CHandlingData instance
	state = 0,
	lastVehicle = 0,
	boxColour = {r = 255, g = 255, b = 255, a = 255}
}
HandlingEditor.__index = HandlingEditor


local msgs =
{
	SuccessfullySaved = translate("Handling Editor", "Handling data successfully saved"),
	SuccessfullyLoaded = translate("Handling Editor", "Handling data successfully loaded"),
}

---@param parent integer
---@param menuname string
---@param commands table
---@param helpTxt string
---@return HandlingEditor
function HandlingEditor.new(parent, menuname, commands, helpTxt)
	local self = setmetatable({}, HandlingEditor)
	self.reference = menu.list(parent, menuname, commands, helpTxt, function ()
		self.isOpen = true
	end, function ()
		self.isOpen = false
	end)
	self.ref_vehicleName = menu.readonly(self.reference, translate("Handling Editor", "Vehicle"))
	local name <const> = translate("Handling Editor", "Save")
	self.ref_save = menu.action(self.reference, name, {"savehandling"}, "", function ()
		local ok, msg = self:save()
		if not ok then return notification:help(capitalize(msg), HudColour.red) end
		notification:normal(msgs.SuccessfullySaved, HudColour.purpleDark)
	end)
	local name <const> = translate("Handling Editor", "Saved Files")
	self.savedFiles = FilesList.new(self.reference, name, "", "json")

	self.savedFiles:addSubOpt(translate("Handling Editor", "Load"), function (name, ext, path)
		local ok, msg = self:load(path)
		if not ok then return notification:help(capitalize(msg), HudColour.red) end
		notification:normal(msgs.SuccessfullyLoaded, HudColour.purpleDark)
	end)

	self.savedFiles:addSubOpt(translate("Handling Editor", "Delete"), function (name, ext, path)
		local ok, msg = os.remove(path)
		if not ok then return notification:help(msg, HudColour.red) end
		self.savedFiles:reload()
	end)

	menu.hyperlink(self.reference, translate("Handling Editor", "Tutorial"), "https://gtamods.com/wiki/Handling.meta", "")
	return self
end

---@param name string
function HandlingEditor:setVehicleName(name)
	menu.set_value(self.ref_vehicleName, name)
end

function HandlingEditor:removeSubHandlingData()
	if not next(self.subHandlingData) then return end
	for _, subHandling in pairs(self.subHandlingData) do
		menu.delete(subHandling.reference)
	end
	self.subHandlingData = {}
end


function HandlingEditor:onTick()
	local vehicle = entities.get_user_vehicle_as_handle()
	if self.isOpen and ENTITY.DOES_ENTITY_EXIST(vehicle) and not ENTITY.IS_ENTITY_DEAD(vehicle, false) then
		if menu.is_open() then draw_box_esp(vehicle, self.boxColour) end

		if vehicle ~= self.lastVehicle or not self.handlingData then
			if self.handlingData then
				menu.delete(self.handlingData.reference)
				self.handlingData = nil
			end
			self:removeSubHandlingData()

			local pVehicle = entities.handle_to_pointer(vehicle)
			if pVehicle == NULL then return end
			local CHandlingData_addr = memory.read_long(pVehicle + 0x938)
			self.handlingData = HandlingData.new(self.reference, "CHandlingData", CHandlingData_addr, CHandlingData)

			local model = ENTITY.GET_ENTITY_MODEL(vehicle)
			local vehicleName = VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(model)
			self:setVehicleName(util.get_label_text(vehicleName))

			for _, subHandling in ipairs(get_vehicle_sub_handling(pVehicle)) do
				local name = get_sub_handling_type_name(subHandling.type)
				local offsets = SubHandlingData[name]
				if offsets then
					self.subHandlingData[name] =
					HandlingData.new(self.reference, name, subHandling.address, offsets)
				end
			end

			self.savedFiles.dir = wiriDir .. "handling\\" .. string.lower(vehicleName) .. "\\"
			if self.savedFiles.isOpen then self.savedFiles:reload() end
			self.lastVehicle = vehicle
		end
	elseif self.handlingData then

		self:removeSubHandlingData()
		self:setVehicleName("???")
		menu.delete(self.handlingData.reference)
		self.savedFiles:clear()
		self.handlingData = nil

	end
end


local trans = {
	VehicleNotFound = translate("Handling Editor", "User vehicle not found"),
	SaveCanceled = translate("Handling Editor", "Save canceled")
}

---@return boolean
---@return string? errmsg
function HandlingEditor:save()
	local vehicle = entities.get_user_vehicle_as_handle()
	if not ENTITY.DOES_ENTITY_EXIST(vehicle)
	or self.handlingData.baseAddress == NULL then
		return false, trans.VehicleNotFound
	end
	local input = ""
	local label = customLabels.EnterFileName
	while true do
		input = get_input_from_screen_keyboard(label, 31, "")
		if input == "" then
			return false, trans.SaveCanceled
		end
		if not input:find '[^%w_%.%-]' then break end
		label = customLabels.InvalidChar
		util.yield(250)
	end
	local data = {}
	data[self.handlingData.name] = self.handlingData:get()
	for _, subHandling in pairs(self.subHandlingData) do
		data[subHandling.name] = subHandling:get()
	end
	self.savedFiles:add(input .. ".json", json.stringify(data, nil, 4))
	return true, nil
end

---@param path string
---@return boolean
---@return string? errmsg
function HandlingEditor:load(path)
	local vehicle = entities.get_user_vehicle_as_handle()
	if not ENTITY.DOES_ENTITY_EXIST(vehicle) or
	self.handlingData.baseAddress == NULL then
		return false, "user vehicle not found"
	end
	if not filesystem.exists(path) then
		return false, "file does not exist"
	end
	local ok, result = json.parse(path, false)
	if not ok then return false, result end
	local handlingData = result["CHandlingData"]
	if not handlingData then
		return false, "field: CHandlingData was not found in the parsed file"
	end
	self.handlingData:set(handlingData)
	local handlingTypes <const> = get_vehicle_sub_handling(entities.handle_to_pointer(vehicle))
	local count = 0

	for _, ht in ipairs(handlingTypes) do
		local name <const> = get_sub_handling_type_name(ht.type)
		local data = result[name]
		if data then
			local subHandling = self.subHandlingData[name]
			if subHandling then subHandling:set(data) count = count + 1 end
		end
	end

	util.log("%d / %d subhandlings loaded", count, #handlingTypes)
	return true
end

local handlingEditor <const> =
HandlingEditor.new(vehicleOptions, translate("Handling Editor", "Handling Editor"), {}, "")
util.log("Handling Editor initialized")

-------------------------------------
-- UFO
-------------------------------------

local objModels <const> = {
	"imp_prop_ship_01a",
	"sum_prop_dufocore_01a"
}
local options <const> = {translate("UFO", "Alien UFO"), translate("UFO", "Military UFO")}
local helpText = translate("UFO", "Drive an UFO, use its tractor beam and cannon")

menu.action_slider(vehicleOptions, translate("UFO", "UFO"), {"ufo"}, helpText, options, function (index)
	local obj = objModels[index]
	UFO.setObjModel(obj)
	if not (GuidedMissile.exists() or UFO.exists()) then UFO.create() end
end)

util.on_stop(function ()
	if UFO.exists() then UFO.onStop() end
end)

-------------------------------------
-- VEHICLE INSTANT LOCK ON
-------------------------------------

---@class VehicleLockOn
VehicleLockOn = {address = 0, defaultValue = 0}
VehicleLockOn.__index = VehicleLockOn

---@param address integer
---@return VehicleLockOn
function VehicleLockOn.new(address)
	assert(address ~= NULL, "got a null pointer")
	local instance = setmetatable({}, VehicleLockOn)
	instance.address = address
	instance.defaultValue = memory.read_float(address)
	return instance
end

VehicleLockOn.__eq = function (a, b)
	return a.address == b.address
end

---@return number
function VehicleLockOn:getValue()
	return memory.read_float(self.address)
end

---@param value number
function VehicleLockOn:setValue(value)
	memory.write_float(self.address, value)
end

function VehicleLockOn:reset()
	memory.write_float(self.address, self.defaultValue)
end

---@type VehicleLockOn
local modifiedLockOn

menu.toggle_loop(vehicleOptions, translate("Vehicle", "Vehicle Instant Lock-On"), {}, "", function ()
	local CPed = entities.handle_to_pointer(players.user_ped())
	if CPed == NULL then return end
	local address = addr_from_pointer_chain(CPed, {0x10D8, 0x70, 0x60, 0x178})
	if address == NULL then return end
	local lockOn = VehicleLockOn.new(address)
	modifiedLockOn = modifiedLockOn or lockOn
	if lockOn ~= modifiedLockOn then
		modifiedLockOn:reset()
		modifiedLockOn = lockOn
	end
	if modifiedLockOn:getValue() ~= 0.0 then
		modifiedLockOn:setValue(0.0)
	end
end, function ()
	if modifiedLockOn then modifiedLockOn:reset() end
end)


-------------------------------------
-- VEHICLE EFFECTS
-------------------------------------

local effects <const> = {
	{"scr_rcbarry1", "scr_alien_impact_bul", 1.0, 50},
	{"scr_rcbarry2", "scr_clown_appears", 0.3, 500},
	{"core", "ent_dst_elec_fire_sp", 1.0, 100},
	{"scr_rcbarry1", "scr_alien_disintegrate", 0.1, 400},
	{"scr_rcbarry1", "scr_alien_teleport", 0.1, 400}
}
local wheelBones <const> = {"wheel_lf", "wheel_lr", "wheel_rf", "wheel_rr"}
local selectedOpt = 1


menu.toggle_loop(vehicleOptions, translate("Vehicle Effects", "Vehicle Effects"), {}, "", function ()
	local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), true)
	if vehicle == NULL then return end
	local effect = effects[selectedOpt]
	request_fx_asset(effect[1])
	for _, bone in pairs(wheelBones) do
		GRAPHICS.USE_PARTICLE_FX_ASSET(effect[1])
		GRAPHICS._START_NETWORKED_PARTICLE_FX_NON_LOOPED_ON_ENTITY_BONE(
			effect[2],
			vehicle,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(vehicle, bone),
			effect[3],
			false, false, false
		)
	end
	util.yield(effect[4])
end)

local options <const> = {
	translate("Vehicle Effects", "Alien Impact"),
	translate("Vehicle Effects", "Clown Appears"),
	translate("Vehicle Effects", "Blue Sparks"),
	translate("Vehicle Effects", "Alien Disintegration"),
	translate("Vehicle Effects", "Firey Particles"),
}
menu.slider_text(vehicleOptions, translate("Vehicle Effects", "Set Vehicle Effect"), {}, "",
	options, function (index) selectedOpt = index end)

-------------------------------------
-- AUTOPILOT
-------------------------------------

local autopilotSpeed = 25.0
local lastBlip
local lastStyle
local lastSpeed
local lastNotification <const> = newTimer()
local drivingStyle = 786988

---@param blip Blip
local task_drive_to_blip = function(blip)
	local vehicle = get_vehicle_player_is_in(players.user())
	local pSequence = memory.alloc_int()
	local pos = get_blip_coords(blip)
	if vehicle ~= NULL and pos then
		PED.SET_DRIVER_ABILITY(PLAYER.PLAYER_PED_ID(), 1.0)
		TASK.OPEN_SEQUENCE_TASK(pSequence)
		TASK.TASK_VEHICLE_DRIVE_TO_COORD_LONGRANGE(
			0, vehicle, pos.x, pos.y, pos.z, autopilotSpeed, drivingStyle, 45.0)
		local heading = ENTITY.GET_ENTITY_HEADING(vehicle)
		TASK.TASK_VEHICLE_PARK(0, vehicle, pos.x, pos.y, pos.z, heading, 7, 60.0, true)
		TASK.CLOSE_SEQUENCE_TASK(memory.read_int(pSequence))
		TASK.TASK_PERFORM_SEQUENCE(PLAYER.PLAYER_PED_ID(), memory.read_int(pSequence))
		TASK.CLEAR_SEQUENCE_TASK(pSequence)
	end
end

local menuName = translate("Vehicle - Autopilot", "Autopilot")
local autopilot <const> = menu.list(vehicleOptions, menuName, {}, "")
local msg = translate("Vehicle - Autopilot", "Set a waypoint to start driving")

menu.toggle_loop(autopilot, translate("Vehicle - Autopilot", "Autopilot"), {}, "", function()
	if HUD.GET_FIRST_BLIP_INFO_ID(8) == 0 then
		if not lastNotification.isEnabled() or
		lastNotification.elapsed() > 30000 then
			notification:normal(msg)
			lastNotification.reset()
			return
		end
	elseif lastNotification.isEnabled() then
		lastNotification.disable()
	end

	local blip = HUD.GET_FIRST_BLIP_INFO_ID(8)
	if blip == 0 and TASK.GET_SEQUENCE_PROGRESS(PLAYER.PLAYER_PED_ID()) ~= -1 then
		TASK.CLEAR_PED_TASKS(PLAYER.PLAYER_PED_ID())
	elseif drivingStyle ~= lastStyle or blip ~= lastBlip or autopilotSpeed ~= lastSpeed or
	TASK.GET_SEQUENCE_PROGRESS(PLAYER.PLAYER_PED_ID()) == -1 then
		task_drive_to_blip(blip)
		lastStyle = drivingStyle
		lastBlip = blip
		lastSpeed = autopilotSpeed
	end
end, function ()
	TASK.CLEAR_PED_TASKS(PLAYER.PLAYER_PED_ID())
	lastNotification.disable()
end)

---@class PresetDriveStyle
---@field name string
---@field help string
---@field style integer

---@type PresetDriveStyle[]
local presets <const> =
{
	{
		name = "Normal",
		help = "Stop before vehicles & peds, avoid empty vehicles & objects and stop at traffic lights.",
		style = 786603
	},
	{
	  	name = "Ignore Lights",
	  	help = "Stop before vehicles, avoid vehicles & objects.",
	  	style = 2883621
	},
	{
	  	name = "Avoid Traffic",
	  	help = "Avoid vehicles & objects.",
	  	style = 786468
	},
	{
	  	name = "Rushed",
	  	help = "Stop before vehicles, avoid vehicles, avoid objects",
	  	style = 1074528293
	},
	{
	  	name = "Default",
	  	help = "Avoid vehicles, empty vehicles & objects, allow going wrong way and take shortest path",
	  	style = 786988
	}
}

local drivingStyleList <const> = menu.list(autopilot, translate("Vehicle - Autopilot", "Driving Style"), {}, "")
menu.divider(drivingStyleList, translate("Autopilot - Driving Style", "Presets"))

for _, preset in ipairs(presets) do
	local name <const> = translate("Autopilot - Driving Style", preset.name)
	menu.action(drivingStyleList, name, {}, preset.help, function()
		drivingStyle = preset.style
	end)
end

menu.divider(drivingStyleList, translate("Autopilot - Driving Style", "Custom"))
local currentFlag = 0
local drivingStyleFlag <const> = {
	["Stop Before Vehicles"] = 1 << 0,
	["Stop Before Peds"] = 1 << 1,
	["Avoid Vehicles"] = 1 << 2,
	["Avoid Empty Vehicles"] = 1 << 3,
	["Avoid Peds"] = 1 << 4,
	["Avoid Objects"] = 1 << 5,
	["Stop At Traffic Lights"] = 1 << 7,
	["Reverse Only"] = 1 << 10,
	["Take Shortest Path"] = 1 << 18,
	["Ignore Roads"] = 1 << 22,
	["Ignore All Pathing"] = 1 << 24,
}
for name, flag in pairs(drivingStyleFlag) do
	menu.toggle(drivingStyleList, translate("Autopilot - Driving Style", name), {}, "", function(toggle)
		currentFlag = toggle and (currentFlag | flag) or (currentFlag & ~flag)
	end)
end

menu.action(drivingStyleList, translate("Autopilot - Driving Style", "Set Custom Driving Style"), {}, "",
	function() drivingStyle = currentFlag end)

menu.slider(autopilot, translate("Vehicle - Autopilot", "Speed"), {"autopilotspeed"}, "",
	5, 200, 20, 1, function(speed) autopilotSpeed = speed end)

-------------------------------------
-- ENGINE ALWAYS ON
-------------------------------------

menu.toggle_loop(vehicleOptions, translate("Vehicle", "Engine Always On"), {"alwayson"}, "", function()
	local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
	if ENTITY.DOES_ENTITY_EXIST(vehicle) then
		VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle, true, true, true)
		VEHICLE.SET_VEHICLE_LIGHTS(vehicle, 0)
		VEHICLE._SET_VEHICLE_LIGHTS_MODE(vehicle, 2)
	end
end)

-------------------------------------
-- TARGET PASSENGERS
-------------------------------------

menu.toggle_loop(vehicleOptions, translate("Vehicle", "Target Passengers"), {"targetpassengers"}, "", function()
	local localPed = PLAYER.PLAYER_PED_ID()
	if not PED.IS_PED_IN_ANY_VEHICLE(localPed, false) then
		return
	end
	local vehicle = PED.GET_VEHICLE_PED_IS_IN(localPed, false)
	for seat = -1, VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(vehicle) - 1 do
		local ped = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, seat, 0)
		if ENTITY.DOES_ENTITY_EXIST(ped) and ped ~= localPed and PED.IS_PED_A_PLAYER(ped) then
			local playerGroupHash = PED.GET_PED_RELATIONSHIP_GROUP_HASH(ped)
			local myGroupHash = PED.GET_PED_RELATIONSHIP_GROUP_HASH(localPed)
			PED.SET_RELATIONSHIP_BETWEEN_GROUPS(4, playerGroupHash, myGroupHash)
		end
	end
end)

---------------------
---------------------
-- BODYGUARD
---------------------
---------------------

-------------------------------------
-- COMPONENT
-------------------------------------

---@class Component
local Component = {reference = 0, drawableId = -1, textureId = 0, componentId = 0}
Component.__index = Component

local trans <const> =
{
    Type = translate("Wardrobe", "Type"),
    Texture = translate("Wardrobe", "Texture"),
}


---@param parent integer
---@param name string
---@param ped Ped
---@param componentId integer
---@param onChange fun(drawable: integer, texture: integer)
function Component.new(parent, name, ped, componentId, onChange)
    local self = setmetatable({}, Component)
    self.reference = menu.list(parent, name , {}, "")
    self.componentId = componentId

	local numDrawables = PED.GET_NUMBER_OF_PED_DRAWABLE_VARIATIONS(ped, componentId)
    self.drawableId = PED.GET_PED_DRAWABLE_VARIATION(ped, componentId)
    local textureSlider

    menu.slider(self.reference, trans.Type, {}, "", -1, numDrawables - 1, self.drawableId, 1, function (value, prev, click)
		if (click & CLICK_FLAG_AUTO) ~= 0 then return end
        self.drawableId = value
        local numTextures = PED.GET_NUMBER_OF_PED_TEXTURE_VARIATIONS(ped, componentId, value)
        menu.set_max_value(textureSlider, numTextures - 1)
        self.textureId = 0
		menu.set_value(textureSlider, self.textureId)
        onChange(self.drawableId, self.textureId)
    end)

    self.textureId = PED.GET_PED_TEXTURE_VARIATION(ped, componentId)
    local currentNumTextures = PED.GET_NUMBER_OF_PED_TEXTURE_VARIATIONS(ped, componentId, self.drawableId)

	textureSlider =
    menu.slider(self.reference, trans.Texture, {}, "", 0, currentNumTextures - 1, self.textureId, 1, function (value, prev, click)
		if (click & CLICK_FLAG_AUTO) ~= 0 then return end
        self.textureId = value
        onChange(self.drawableId, self.textureId)
    end)

	return self
end

-------------------------------------
-- PROP
-------------------------------------

---@class Prop
local Prop = {reference = 0, componentId = -1, drawableId = 0, textureId = 0}
Prop.__index = Prop

---@param parent integer
---@param name string
---@param ped Ped
---@param componentId integer
---@param onChange fun(drawableId: integer, textureId: integer)
function Prop.new(parent, name, ped, componentId, onChange)
    local self = setmetatable({}, Prop)
    self.reference = menu.list(parent, name, {}, "")
    self.componentId = componentId

    local numDrawables = PED.GET_NUMBER_OF_PED_PROP_DRAWABLE_VARIATIONS(ped, componentId)
    self.drawableId = PED.GET_PED_PROP_INDEX(ped, componentId)
    local textureSlider

    menu.slider(self.reference, trans.Type, {}, "", -1, numDrawables - 1, self.drawableId, 1, function (drawableId, prev, click)
		if (click & CLICK_FLAG_AUTO) ~= 0 then return end
        self.drawableId = drawableId
        local numTextures = PED.GET_NUMBER_OF_PED_PROP_TEXTURE_VARIATIONS(ped, componentId, drawableId)
        menu.set_max_value(textureSlider, numTextures - 1)
        self.textureId = 0
		menu.set_value(textureSlider, self.textureId)
        onChange(self.drawableId, self.textureId)
    end)

    self.textureId = PED.GET_NUMBER_OF_PED_PROP_TEXTURE_VARIATIONS(ped, componentId, self.drawableId)
    local currentNumTextures = PED.GET_PED_PROP_TEXTURE_INDEX(ped, componentId)

	textureSlider =
    menu.slider(self.reference, trans.Texture, {}, "", 0, currentNumTextures - 1, self.textureId, 1, function (value, prev, click)
		if (click & CLICK_FLAG_AUTO) ~= 0 then return end
        self.textureId = value
        onChange(self.drawableId, self.textureId)
    end)

	return self
end

-------------------------------------
-- WARDROBE
-------------------------------------

---@class Wardrobe
Wardrobe = {
    reference = 0,
    ---@type table<number, Component>
    components = {},
    ---@type table<number, Prop>
    props = {}
}
Wardrobe.__index = Wardrobe


local components <const> = {
	[0]  = translate("Wardrobe", "Head"),
    [1]  = translate("Wardrobe", "Beard / Mask"),
    [2]  = translate("Wardrobe", "Hair"),
    [3]  = translate("Wardrobe", "Gloves / Torso"),
    [4]  = translate("Wardrobe", "Legs"),
    [5]  = translate("Wardrobe", "Hands / Back"),
    [6]  = translate("Wardrobe", "Shoes"),
    [7]	 = translate("Wardrobe", "Teeth / Scarf / Necklace / Bracelets"),
	[8]  = translate("Wardrobe", "Accesories / Tops"),
    [9]  = translate("Wardrobe", "Task / Armour"),
    [10] = translate("Wardrobe", "Decals"),
    [11] = translate("Wardrobe", "Torso 2"),
}

local props <const> =
{
    [0] = translate("Wardrobe", "Hat"),
    [1] = translate("Wardrobe", "Classes"),
    [2] = translate("Wardrobe", "Earwear"),
    [6] = translate("Wardrobe", "Watch"),
    [7] = translate("Wardrobe", "Bracelet"),
}


---@param parent integer
---@param menu_name string
---@param command_names string[]
---@param help_text string
---@param ped Ped
---@return Wardrobe
function Wardrobe.new(parent, menu_name, command_names, help_text, ped)
    local self = setmetatable({}, Wardrobe)
    self.reference = menu.list(parent, menu_name, command_names, help_text, function ()
        self.isOpen = true
    end, function ()
        self.isOpen = false
    end)
    self.components, self.props = {}, {}

    for componentId, name in pairs_by_keys(components, function (a, b) return a < b end) do
        if PED.GET_NUMBER_OF_PED_DRAWABLE_VARIATIONS(ped, componentId) < 1 then
            goto LABEL_CONTINUE
        end
		self.components[componentId] =
        Component.new(self.reference, name, ped, componentId, function (drawableId, textureId)
            request_control(ped)
            PED.SET_PED_COMPONENT_VARIATION(ped, componentId, drawableId, textureId, 2)
        end)
	::LABEL_CONTINUE::
    end

    for propId, name in pairs_by_keys(props, function (a, b) return a < b end) do
        if PED.GET_NUMBER_OF_PED_PROP_DRAWABLE_VARIATIONS(ped, propId) < 1 then
            goto LABEL_CONTINUE
        end
		self.props[propId] =
        Prop.new(self.reference, name, ped, propId, function (drawableId, textureId)
            request_control(ped)
            if drawableId == -1 then PED.CLEAR_PED_PROP(ped, propId)
            else PED.SET_PED_PROP_INDEX(ped, propId, drawableId, textureId, true) end
        end)
	::LABEL_CONTINUE::
    end

    return self
end


---@alias Component_t {drawableId: integer, textureId: integer}
---@alias Prop_t Component_t
---@alias Outfit {components: table<integer, Component_t>, props: table<integer, Prop_t>}

---@return Outfit
function Wardrobe:getOutfit()
    assert(self.reference ~= 0, "wardrobe reference does not exist")
    local tbl = {components = {}, props = {}}

    for componentId, component in pairs(self.components) do
        tbl.components[componentId] =
		{drawableId = component.drawableId, textureId = component.textureId}
    end

    for propId, prop in pairs(self.props) do
        tbl.props[propId] =
		{drawableId = prop.drawableId, textureId = prop.textureId}
    end

    return tbl
end

-------------------------------------
-- MEMBER
-------------------------------------

---@class Member
Member =
{
	handle = 0,
	mgr = 0,
	isMgrOpen = false,
	invincible = 0,
	references =
	{
		invincible = 0,
		teleport = 0,
	},
	weaponHash = 0,
	---@type Wardrobe
	wardrobe = nil,
}
Member.__index = Member

---@param ped Ped
---@return Member
function Member.new(ped)
	local self = setmetatable({}, Member)
	self.handle = ped
	PED.SET_PED_HIGHLY_PERCEPTIVE(ped, true)
	PED.SET_PED_SEEING_RANGE(ped, 100.0)
	PED.SET_PED_CAN_PLAY_AMBIENT_ANIMS(ped, false)
	PED.SET_PED_CAN_PLAY_AMBIENT_BASE_ANIMS(ped, false)
	PED.SET_PED_CONFIG_FLAG(ped, 208, true)
	PED.SET_RAGDOLL_BLOCKING_FLAGS(ped, 1)
	PED.SET_RAGDOLL_BLOCKING_FLAGS(ped, 4)
	--PED.SET_PED_SHOOT_RATE(ped, 1000)
	PED.SET_PED_COMBAT_ATTRIBUTES(ped, 5, true)
	PED.SET_PED_COMBAT_ATTRIBUTES(ped, 0, false)
	PED.SET_PED_COMBAT_ATTRIBUTES(ped, 46, true)

	local blip = add_ai_blip_for_ped(ped, true, false, 100.0, 2, -1)
	set_blip_name(blip, "blip_9rt4uwu", true) -- a random collision for 0xED0C8764
	HUD.SET_BLIP_AS_FRIENDLY(blip, true)
	return self
end

---@param modelHash? Hash
function Member:createMember(modelHash)
	local pos = get_random_offset_in_range(players.user_ped(), 2.0, 3.0)
	pos.z = pos.z - 1.0
	local ped = NULL
	if modelHash then
		ped = entities.create_ped(4, modelHash, pos, 0.0)
	else
		local modelHash <const> = ENTITY.GET_ENTITY_MODEL(players.user_ped())
		ped = entities.create_ped(4, modelHash, pos, 0)
	end
	NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(NETWORK.PED_TO_NET(ped), true)
	ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ped, false, true)
	NETWORK.SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER(NETWORK.PED_TO_NET(ped), PLAYER.PLAYER_ID(), true)
	ENTITY.SET_ENTITY_LOAD_COLLISION_FLAG(ped, true, 1)
	if not modelHash then PED.CLONE_PED_TO_TARGET(players.user_ped(), ped) end
	set_entity_face_entity(ped, players.user_ped(), false)
	return Member.new(ped)
end

function Member:removeMgr()
	if self.mgr == 0 then return end
	menu.delete(self.mgr); self.mgr = 0
end

function Member:delete()
	if ENTITY.DOES_ENTITY_EXIST(self.handle) and request_control(self.handle, 1000) then
		entities.delete_by_handle(self.handle); self.handle = 0
	end
end


local trans =
{
	Invincible = translate("Bg Menu", "Invencible"),
	TpToMe = translate("Bg Menu", "Teleport to Me"),
	Delete = translate("Bg Menu", "Delete"),
	Weapon = translate("Bg Menu", "Weapon"),
	Appearance = translate("Bg Menu", "Appearance"),
	Save = translate("Bg Menu", "Save"),
	BodyguardSaved = translate("Bg Menu", "Bodyguard saved"),
	SaveCanceled = translate("Bg Menu", "Save canceled")
}


---Creates the list to edit some properties of the bodyguard
---@param parent integer
---@param name string
function Member:createMgr(parent, name)
	self.mgr = menu.list(parent, name, {}, "", function ()
		self.isMgrOpen = true
	end, function ()
		self.isMgrOpen = false
	end)

	self.references = {}
	if not is_ped_an_animal(self.handle) then
		WeaponList.new(self.mgr, trans.Weapon, "", "", function (caption, model)
			local hash <const> = util.joaat(model)
			self:giveWeapon(hash); self.weaponHash = hash
		end, true)
	end
	self.references.invincible = menu.toggle(self.mgr, trans.Invincible, {}, "", function (on)
		request_control(self.handle, 1000)
		ENTITY.SET_ENTITY_INVINCIBLE(self.handle, on)
		ENTITY.SET_ENTITY_PROOFS(self.handle, on, on, on, on, on, on, on, on)
	end)
	self.references.teleport = menu.action(self.mgr, trans.TpToMe, {}, "", function ()
		request_control(self.handle, 1000)
		local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
		if ENTITY.DOES_ENTITY_EXIST(vehicle) then self:tpToVehicle(vehicle)
		else self:tpToLeader() end
	end)

	self.wardrobe = Wardrobe.new(self.mgr, trans.Appearance, {}, "", self.handle)

	menu.action(self.mgr, trans.Save, {}, "", function()
		local ok, err = self:save()
		if not ok then notification:help(err, HudColour.red) return end
		notification:normal(trans.BodyguardSaved)
	end)

	menu.action(self.mgr, trans.Delete, {}, "",  function ()
		self:delete() self:removeMgr()
	end)
end

---@param value boolean
function Member:setInvincible(value)
	assert(self.references.invincible ~= 0, "bodyguard manager not found")
	menu.set_value(self.references.invincible, value)
end

---@param weaponHash Hash
function Member:giveWeapon(weaponHash)
	WEAPON.REMOVE_ALL_PED_WEAPONS(self.handle, 1)
	WEAPON.GIVE_WEAPON_TO_PED(self.handle, weaponHash, 9999, true, true)
	WEAPON.SET_CURRENT_PED_WEAPON(self.handle, weaponHash, false)
end

---@param vehicle Vehicle
function Member:tpToVehicle(vehicle)
	if not VEHICLE.ARE_ANY_VEHICLE_SEATS_FREE(vehicle) or
	PED.GET_VEHICLE_PED_IS_IN(self.handle, false) == vehicle then return end
	local seat
	for i = -1, VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(vehicle) -1 do
		if VEHICLE.IS_VEHICLE_SEAT_FREE(vehicle, i, false) then seat = i break end
	end
	PED.SET_PED_INTO_VEHICLE(self.handle, vehicle, seat)
end

function Member:tpToLeader()
	local pos = get_random_offset_in_range(players.user_ped(), 2.0, 3.0)
	ENTITY.SET_ENTITY_COORDS(self.handle, pos.x, pos.y, pos.z - 1.0, 0, 0, 0, 0)
	set_entity_face_entity(self.handle, players.user_ped(), false)
end

function Member:tp()
	assert(self.references.teleport ~= 0, "bodyguard manager not found")
	menu.trigger_command(self.references.teleport, "")
end


function Member:getInfo()
	local pWeaponHash = memory.alloc_int()
	WEAPON.GET_CURRENT_PED_WEAPON(self.handle, pWeaponHash, true)
	local tbl = {
		WeaponHash = memory.read_int(pWeaponHash),
		Outfit = self.wardrobe:getOutfit(),
		ModelHash = ENTITY.GET_ENTITY_MODEL(self.handle)
	}
	return tbl
end


---@return boolean
---@return string? errmsg
function Member:save()
	local input = ""
	local label = customLabels.EnterFileName
	while true do
		input = get_input_from_screen_keyboard(label, 31, "")
		if input == "" then
			return false, trans.SaveCanceled
		end
		if not input:find '[^%w_%.%-]' then break end
		label = customLabels.InvalidChar
		util.yield(250)
	end
	local path = wiriDir .. "bodyguards\\" .. input .. ".json"
	local file, err = io.open(path, "w")
	if not file then
		return false, err
	end
	file:write(json.stringify(self:getInfo(), nil, 0, false))
	file:close()
	return true
end


---@param obj Outfit
---@return boolean
---@return string? errmsg
function Member:setOutfit(obj)
	local types =
	{
		components = "table",
		props = "table"
	}
	for k, v in pairs(types) do
		local ok, errmsg = type_match(obj[k], v)
		if not ok then return false, "field " .. k .. ' ' .. errmsg end
	end

	for componentId, tbl in pairs(obj.components) do
		if tonumber(componentId) and math.type(tbl.drawableId) == "integer" and
		math.type(tbl.textureId) == "integer" and request_control(self.handle) then
        	PED.SET_PED_COMPONENT_VARIATION(self.handle, componentId, tbl.drawableId, tbl.textureId, 2)
		end
	end

	for propId, tbl in pairs(obj.props) do
		if tonumber(propId) and math.type(tbl.drawableId) == "integer" and
		math.type(tbl.textureId) == "integer" and request_control(self.handle) then
			PED.SET_PED_PROP_INDEX(self.handle, propId, tbl.drawableId, tbl.textureId, true)
		end
	end
	return true
end


-------------------------------------
-- GROUP
-------------------------------------

local Formation <const> =
{
	freedomToMove = 0,
	circleAroundLeader = 1,
	line = 3,
	arrow = 4,
}

---@class Group
Group =
{
	ID = 0,
	---@type Member[]
	members = {},
	numMembers = 0,
	formation = Formation.freedomToMove,
	defaults =
	{
		invincible = false,
		weaponHash = util.joaat("weapon_heavypistol"),
	},
	rg = util.joaat("rgFM_HateEveryOne"),
}
Group.__index = Group

---@return Group
function Group.new()
	local self = setmetatable({}, Group)
	for num = 0, 6, 1 do
		local ped = PED.GET_PED_AS_GROUP_MEMBER(self.getID(), num)
		if ENTITY.DOES_ENTITY_EXIST(ped) and
		request_control(ped, 1000) then self:pushMember(Member.new(ped)) end
	end
	return self
end

---@return integer
function Group.getID()
	return PLAYER.GET_PLAYER_GROUP(PLAYER.PLAYER_ID())
end

---@return integer
function Group:getSize()
	local unkPtr, sizePtr = memory.alloc(1), memory.alloc(1)
	PED.GET_GROUP_SIZE(self.getID(), unkPtr, sizePtr)
	return memory.read_int(sizePtr)
end

---@param member Member
function Group:pushMember(member)
	if not PED.IS_PED_IN_GROUP(member.handle) then
		PED.SET_PED_AS_GROUP_MEMBER(member.handle, self.getID())
		PED.SET_PED_NEVER_LEAVES_GROUP(member.handle, true)
	end
	PED.SET_PED_RELATIONSHIP_GROUP_HASH(member.handle, self.rg)
	PED.SET_GROUP_SEPARATION_RANGE(self.getID(), 9999.0)
	PED.SET_GROUP_FORMATION_SPACING(self.getID(), 1.0, 0.9, 3.0)
	PED.SET_GROUP_FORMATION(self.getID(), self.formation)
	table.insert(self.members, member)
	self.numMembers = self.numMembers + 1
end

---@param rgHash Hash
function Group:setRelationshipGrp(rgHash)
	self.rg = rgHash
	for num = 0, 6, 1 do
		local ped = PED.GET_PED_AS_GROUP_MEMBER(self.getID(), num)
		if ENTITY.DOES_ENTITY_EXIST(ped) and
		request_control(ped, 1000) then PED.SET_PED_RELATIONSHIP_GROUP_HASH(ped, rgHash) end
	end
end

function Group:onTick()
	if self.numMembers == 0 then return end
	for i = self.numMembers, 1, -1 do
		local member = self.members[i]
		local ped = member.handle
		if not ENTITY.DOES_ENTITY_EXIST(ped) or PED.IS_PED_INJURED(ped) then
			self.numMembers = self.numMembers - 1
			member:removeMgr()
			table.remove(self.members, i)
			set_entity_as_no_longer_needed(ped)
			goto LABEL_CONTINUE
		end
		if member.isMgrOpen and menu.is_open() then
			draw_box_esp(ped, {r = 255, g = 255, b = 255, a = 255})
		end
		if not PED.IS_PED_IN_GROUP(ped) then
			PED.SET_PED_AS_GROUP_MEMBER(ped, self.getID())
		end
	::LABEL_CONTINUE::
	end
end

---@param formation integer
function Group:setFormation(formation)
	self.formation = formation
	PED.SET_GROUP_FORMATION(self.getID(), formation)
end

function Group:deleteMembers()
	for num = 0, 6, 1 do
		local ped = PED.GET_PED_AS_GROUP_MEMBER(self.getID(), num)
		if ENTITY.DOES_ENTITY_EXIST(ped) and
		request_control(ped, 1000) then entities.delete_by_handle(ped) end
	end
end

---@param value boolean
function Group:setInvincible(value)
	for _, member in ipairs(self.members) do member:setInvincible(value) end
	self.defaults.invincible = value
end

function Group:teleport()
	for _, member in ipairs(self.members) do member:tp() end
end

-------------------------------------
-- BODYGUARDS MENU
-------------------------------------

local trans =
{
	Clone = translate("Bg Menu", "Clone"),
	ReachedMaxNumBodyguards = translate("Bg Menu", "You reached the maximum number of bodygards"),
	Unknown = translate("Bg Menu", "Unknown"),
	InvalidOutfit = translate("Bg Menu", "%s has an invalid outfit: %s")
}

---@class BodyguardMenu
BodyguardMenu =
{
	ref = 0,
	divider = 0,
	isOpen = false,
	---@type Group
	group = {},
}
BodyguardMenu.__index = BodyguardMenu

---@param parent integer
---@param name string
---@param command_names? table
---@return BodyguardMenu
function BodyguardMenu.new(parent, name, command_names)
	local self = setmetatable({}, BodyguardMenu)
	self.ref = menu.list(parent, name, command_names or {}, "", function()
		self.isOpen = true
	end, function()
		self.isOpen = false
	end)
	self.group = Group.new()

	ModelList.new(self.ref, translate("Bg Menu", "Spawn"), "spawnbg", "", pedList, function (caption, model)
		if self.group:getSize() >= 7 then
			return notification:help(trans.ReachedMaxNumBodyguards, HudColour.red)
		end
		local modelHash <const> = util.joaat(model)
		request_model(modelHash)
		local member = Member:createMember(modelHash)
		self.group:pushMember(member)
		local weaponHash = self.group.defaults.weaponHash
		if is_ped_an_animal(member.handle) then
			weaponHash = util.joaat("weapon_animal")
		end
		member:giveWeapon(weaponHash)
		member:createMgr(self.ref, caption)
		if self.group.defaults.invincible then member:setInvincible(true) end
	end, false)

	menu.action(self.ref, translate("Bg Menu", "Clone Myself"), {"clonebg"}, "", function ()
		if self.group:getSize() >= 7 then
			return notification:help(trans.ReachedMaxNumBodyguards, HudColour.red)
		end
		local member = Member:createMember()
		self.group:pushMember(member)
		local weaponHash = self.group.defaults.weaponHash
		if is_ped_an_animal(member.handle) then
			weaponHash = util.joaat("weapon_animal")
		end
		member:giveWeapon(weaponHash)
		member:createMgr(self.ref, trans.Clone)
		if self.group.defaults.invincible then member:setInvincible(true) end
	end)


	local saved = FilesList.new(self.ref, translate("Bg Menu", "Saved"), wiriDir .. "bodyguards", "json")

	saved:addSubOpt(translate("Bg Menu", "Spawn"), function(name, ext, path)
		if self.group:getSize() >= 7 then
			return notification:help(trans.ReachedMaxNumBodyguards, HudColour.red)
		end
		local ok, result = json.parse(path)
		if not ok then return notification:help(result, HudColour.red) end

		local modelHash <const> = result.ModelHash
		request_model(modelHash)
		local member = Member:createMember(modelHash)
		self.group:pushMember(member)

		local weaponHash = result.WeaponHash
		if is_ped_an_animal(member.handle) and
		weaponHash ~= util.joaat("weapon_animal") then
			weaponHash = util.joaat("weapon_animal")
		end

		local ok, errmsg = member:setOutfit(result.Outfit)
		if not ok then
			notification:help(trans.InvalidOutfit, HudColour.red, name, errmsg)
		end

		member:giveWeapon(weaponHash)
		member:createMgr(self.ref, name)
		if self.group.defaults.invincible then member:setInvincible(true) end
	end)


	saved:addSubOpt(translate("Bg Menu", "Delete"), function (name, ext, path)
		local ok, err = os.remove(path)
		if not ok then return notification:help(err, HudColour.red) end
		saved:reload()
	end)

	self:createCommands(self.ref)
	self.divider = menu.divider(self.ref, translate("Bg Menu", "Spawned Bodyguards"))
	for _, member in ipairs(self.group.members) do
		if member.mgr == 0 then member:createMgr(self.ref, trans.Unknown) end
	end
	return self
end


---@param parent integer
function BodyguardMenu:createCommands(parent)
	local list = menu.list(parent, translate("Bg Menu", "Group"), {}, "")
	local formations <const> =
	{
		translate("Bg Menu", "Freedom"), translate("Bg Menu", "Circle"),
		translate("Bg Menu", "Line"), translate("Bg Menu", "Arrow")
	}
	menu.slider_text(list, translate("Bg Menu", "Group Formation"), {"groupformation"}, "", formations, function (index)
		local formation
		if index == 1 then
			formation = Formation.freedomToMove
		elseif index == 2 then
			formation = Formation.circleAroundLeader
		elseif index == 3 then
			formation = Formation.line
		elseif index == 4 then
			formation = Formation.arrow
		else
			error("got unexpected option")
		end
		self.group:setFormation(formation)
	end)

	local relGroups <const> =
	{
		{translate("Bg Menu", "Like Players"), {"like"}},
		{translate("Bg Menu", "Dislike Players, Like Gangs"), {"dislike"}},
		{translate("Bg Menu", "Hate Players, Like Gangs"), {"hate"}},
		{translate("Bg Menu", "Like Players, Hate Player Haters"), {"hatehaters"}},
		{translate("Bg Menu", "Dislike Players, Like Cops"), {"dislikeplyrlikecops"}},
		{translate("Bg Menu", "Hate Players, Like Cops"), {"hateplyrlikecops"}},
		{translate("Bg Menu", "Hate Everyone"), {"hateall"}},
	}
	local menuName = translate("Bg Menu", "Relationship Group")
	local helpText = translate("Bg Menu", "Online Only")
	menu.list_select(list, menuName, {"rg"}, helpText, relGroups, 7, function(opt)
		local rg
		if opt == 1 then
			rg = util.joaat("rgFM_AiLike")
		elseif opt == 2 then
			rg = util.joaat("rgFM_AiDislike")
		elseif opt == 3 then
			rg = util.joaat("rgFM_AiHate")
		elseif opt == 4 then
			rg = util.joaat("rgFM_AiLike_HateAiHate")
		elseif opt == 5 then
			rg = util.joaat("rgFM_AiDislikePlyrLikeCops")
		elseif opt == 6 then
			rg = util.joaat("rgFM_AiHatePlyrLikeCops")
		elseif opt == 7 then
			rg = util.joaat("rgFM_HateEveryOne")
		else
			error("got unexpected option")
		end
		self.group:setRelationshipGrp(rg)
	end)

	menu.action(list, translate("Bg Menu", "Delete Members"), {"cleargroup"}, "", function()
		self.group:deleteMembers()
	end)
	menu.action(list, translate("Bg Menu", "Teleport Members to Me"), {"tpmembers"}, "", function()
		self.group:teleport()
	end)
	menu.toggle(list, translate("Bg Menu", "Invincible"), {"groupgodmode"}, "", function(toggle)
		self.group:setInvincible(toggle)
	end)
	WeaponList.new(list, translate("Bg Menu", "Default Weapon"), "groupgun", "", function(caption, model)
		self.group.defaults.weaponHash = util.joaat(model)
	end, true)
end


function BodyguardMenu:onTick()
	if self.group.numMembers ~= 0 then
		if self.isOpen and
		not menu.get_visible(self.divider) then
			menu.set_visible(self.divider, true)
		end
		self.group:onTick()
	elseif self.isOpen and menu.get_visible(self.divider) then
		menu.set_visible(self.divider, false)
	end
end


local bodyguardMenu <const> = BodyguardMenu.new(menu.my_root(), translate("Bg Menu", "Bodyguards Menu"), {})
util.log("Bodyguards Menu initialized")

---------------------
---------------------
-- WORLD
---------------------
---------------------

local worldOptions <const> = menu.list(menu.my_root(), translate("World", "World"), {}, "")

-------------------------------------
-- JUMPING CARS
-------------------------------------

menu.toggle_loop(worldOptions, translate("World", "Jumping Cars"), {}, "", function()
	local entities = get_vehicles_in_player_range(PLAYER.PLAYER_ID(), 150)
	for _, vehicle in ipairs(entities) do
		if request_control_once(vehicle) then
			ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, 0, 0, 6.5, 0, 0, 0, 0, false, false, true, 0, 0)
		end
	end
	util.yield(1500)
end)

-------------------------------------
-- KILL ENEMIES
-------------------------------------

local function killEnemies()
	local peds = get_peds_in_player_range(PLAYER.PLAYER_ID(), 500)
	for _, ped in ipairs(peds) do
		local rel = PED.GET_RELATIONSHIP_BETWEEN_PEDS(players.user_ped(), ped)
		if not ENTITY.IS_ENTITY_DEAD(ped, 0) and
		(rel == 4 or rel == 5 or PED.IS_PED_IN_COMBAT(ped, players.user_ped())) then
			local pos = ENTITY.GET_ENTITY_COORDS(ped, false)
			FIRE.ADD_OWNED_EXPLOSION(players.user_ped(), pos.x, pos.y, pos.z, 1, 1.0, true, false, 0.0)
		end
	end
end

menu.action(worldOptions, translate("World", "Kill Enemies"), {"killenemies"}, "", function()
	local count = 0
	local pos = players.get_position(players.user())
	local timer = newTimer()
	while PED.COUNT_PEDS_IN_COMBAT_WITH_TARGET_WITHIN_RADIUS(players.user_ped(), pos.x, pos.y, pos.z, 450.0) > 0 and
	timer.elapsed() < 1000 do
		killEnemies()
		count = count + 1
		util.yield()
	end
end)

menu.toggle_loop(worldOptions, translate("World", "Auto Kill Enemies"), {"autokillenemies"}, "", function()
	killEnemies()
end)

-------------------------------------
--ANGRY PLANES
-------------------------------------

local planes <const> = {
	"besra",
	"dodo",
	"avenger",
	"microlight",
	"molotok",
	"bombushka",
	"howard",
	"duster",
	"luxor2",
	"lazer",
	"nimbus",
	"shamal",
	"stunt",
	"titan",
	"velum2",
	"miljet",
	"mammatus",
	"besra",
	"cuban800",
	"seabreeze",
	"alphaz1",
	"mogul",
	"nokota",
	"strikeforce",
	"vestra",
	"tula",
	"rogue",
}
local numPlanes = 0

menu.toggle_loop(worldOptions, translate("World", "Angry Planes"), {}, "", function ()
	if numPlanes < 15 then
		local pedHash <const> = util.joaat("s_m_y_blackops_01")
		local planeModel <const> = planes[math.random(#planes)]
		local planeHash <const> = util.joaat(planeModel)
		request_model(planeHash); request_model(pedHash)
		local pos = players.get_position(players.user())
		local plane = VEHICLE.CREATE_VEHICLE(planeHash, pos.x, pos.y, pos.z, CAM.GET_GAMEPLAY_CAM_ROT(0).z, true, false, 0)
		set_decor_flag(plane, DecorFlag_isAngryPlane)
		if ENTITY.DOES_ENTITY_EXIST(plane) then
			NETWORK.SET_NETWORK_ID_CAN_MIGRATE(NETWORK.VEH_TO_NET(plane), false)
			ENTITY._SET_ENTITY_CLEANUP_BY_ENGINE(plane, true)
			local pilot = entities.create_ped(26, pedHash, pos, 0)
			PED.SET_PED_INTO_VEHICLE(pilot, plane, -1)
			pos = get_random_offset_in_range(PLAYER.PLAYER_PED_ID(), 50.0, 150.0)
			pos.z = pos.z + 75.0
			ENTITY.SET_ENTITY_COORDS(plane, pos.x, pos.y, pos.z, 0, 0, 0, false)
			local theta = random_float(0, 2 * math.pi)
			ENTITY.SET_ENTITY_HEADING(plane, math.deg(theta))
			VEHICLE.SET_VEHICLE_FORWARD_SPEED(plane, 60)
			VEHICLE.SET_HELI_BLADES_FULL_SPEED(plane)
			VEHICLE.CONTROL_LANDING_GEAR(plane, 3)
			VEHICLE.SET_VEHICLE_FORCE_AFTERBURNER(plane, true)
			TASK.TASK_PLANE_MISSION(pilot, plane, 0, PLAYER.PLAYER_PED_ID(), 0, 0, 0, 6, 100, 0, 0, 80, 50, 0)
			numPlanes = numPlanes + 1
		end
		util.yield(250)
	end
end, function ()
	for _, vehicle in ipairs(entities.get_all_vehicles_as_handles()) do
		if is_decor_flag_set(vehicle, DecorFlag_isAngryPlane) then
			entities.delete_by_handle(VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1, 0))
			entities.delete_by_handle(vehicle)
			numPlanes = numPlanes - 1
		end
	end
end)

-------------------------------------
-- HEALTH BAR
-------------------------------------

function draw_rect(x, y, width, height, colour)
	GRAPHICS.DRAW_RECT(x, y, width, height, colour.r, colour.g, colour.b, colour.a, false)
end

---@param ped Ped
---@param maxDistance number
function draw_health_bar(ped, maxDistance)
	local myPos = players.get_position(players.user())
	local pedPos = ENTITY.GET_ENTITY_COORDS(ped, true)
	local distance = myPos:distance(pedPos)
	if distance >= maxDistance then return end
	local distPerc = 1.0 - distance / maxDistance

	local healthPerc = 0.0
	local armourPerc = 0.0
	if not PED.IS_PED_FATALLY_INJURED(ped) then
		local armour = PED.GET_PED_ARMOUR(ped)
		armourPerc = armour / 100.0
		if armourPerc > 1.0 then armourPerc = 1.0 end
		local health = ENTITY.GET_ENTITY_HEALTH(ped) - 100.0
		local maxHealth = PED.GET_PED_MAX_HEALTH(ped) - 100.0
		healthPerc = health / maxHealth
		if healthPerc > 1.0 then healthPerc = 1.0 end
	end

	local maxLength = 0.05 * distPerc ^3
	local height = 0.008 * distPerc ^1.5
	local pos = PED.GET_PED_BONE_COORDS(ped, 0x322C --[[head]], 0.35, 0., 0.)
	local pScreenX, pScreenY = memory.alloc(4), memory.alloc(4)
	if not GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(pos.x, pos.y, pos.z, pScreenX, pScreenY) then
		return
	end
	local screenX = memory.read_float(pScreenX)
	local screenY = memory.read_float(pScreenY)

	local barLength = interpolate(0.0, maxLength, healthPerc)
	local colour = get_blended_colour(healthPerc)
	draw_rect(screenX, screenY, maxLength + 0.002, height + 0.002, {r = 0, g = 0, b = 0, a = 120})
	draw_rect(screenX - maxLength/2 + barLength/2, screenY, barLength, height, colour)

	local barLength = interpolate(0.0, maxLength, armourPerc)
	local colour = get_hud_colour(HudColour.radarArmour)
	draw_rect(screenX, screenY + 1.5 * height, maxLength + 0.002, height + 0.002, {r = 0, g = 0, b = 0, a = 120})
	draw_rect(screenX - maxLength/2 + barLength/2, screenY + 1.5 * height, barLength, height, colour)
end

local selectedOpt = 1
local aimedPed = 0
local options <const> = {
	{translate("Draw Health Bar", "Disable")},
	{translate("Draw Health Bar", "Players")},
	{translate("Draw Health Bar", "Peds")},
	{translate("Draw Health Bar", "Players & Peds")},
	{translate("Draw Health Bar", "Aimed Ped")},
}
menu.list_select(worldOptions, translate("World", "Draw Health Bar"), {}, "", options, 1, function (opt)
	selectedOpt = opt
end)

util.create_tick_handler(function()
	if selectedOpt == 1 then
		return
	elseif selectedOpt == 5 then
		if not PLAYER.IS_PLAYER_FREE_AIMING(PLAYER.PLAYER_ID()) then
			aimedPed = 0 return
		end
		local pEntity <const> = memory.alloc_int()
		if PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(PLAYER.PLAYER_ID(), pEntity) then
			local entity = memory.read_int(pEntity)
			if ENTITY.IS_ENTITY_A_PED(entity) then aimedPed = entity end
		end
		draw_health_bar(aimedPed, 1000.0)
	else
		for _, ped in ipairs(get_peds_in_player_range(players.user(), 500.0)) do
			if not ENTITY.IS_ENTITY_ON_SCREEN(ped) or
			not ENTITY.HAS_ENTITY_CLEAR_LOS_TO_ENTITY(players.user_ped(), ped, TraceFlag.world) then
				goto LABEL_CONTINUE
			end
			if (selectedOpt == 2 and not PED.IS_PED_A_PLAYER(ped)) or
			(PED.IS_PED_A_PLAYER(ped) and selectedOpt == 3) then
				goto LABEL_CONTINUE
			end
			draw_health_bar(ped, 350.0)
		::LABEL_CONTINUE::
		end
	end
end)

---------------------
---------------------
-- PROTECTIONS
---------------------
---------------------

local protectionOpt <const> = menu.list(menu.my_root(), translate("Protections", "Protections"), {}, "")
local cageModels <const> =
{
	"prop_gold_cont_01",
	"prop_gold_cont_01b",
	"prop_feeder1_cr",
	"prop_rub_cage01a",
	"stt_prop_stunt_tube_s",
	"stt_prop_stunt_tube_end",
	"prop_jetski_ramp_01",
}
local lastMsg = ""
local lastNotification <const> = newTimer()
local format = translate("Protections", "Cage object from <C>%s</C>")


---@param entity Entity
---@param target Entity
---@return boolean
function is_entity_inside_entity(entity, target)
	local dist = ENTITY.GET_ENTITY_COORDS(entity, false)
	dist:sub(ENTITY.GET_ENTITY_COORDS(target, false))
	dist:abs()
	local model = ENTITY.GET_ENTITY_MODEL(target)
	local min, max = v3.new(), v3.new()
	MISC.GET_MODEL_DIMENSIONS(model, min, max)
	return dist.x < max.y and dist.y < max.x and dist.z < max.z
end

menu.toggle_loop(protectionOpt, translate("Protections", "Anticage"), {"anticage"}, "", function()
	local myPos = players.get_position(players.user())
	for _, model in ipairs(cageModels) do
		local modelHash <const> =  util.joaat(model)
		local obj = OBJECT.GET_CLOSEST_OBJECT_OF_TYPE(myPos.x, myPos.y, myPos.z, 8.0, modelHash, false, 0, 0)
		if obj == NULL or not ENTITY.DOES_ENTITY_EXIST(obj) or
		not is_entity_inside_entity(players.user_ped(), obj) then
			goto LABEL_CONTINUE
		end
		local ownerId = get_entity_owner(obj)
		local msg = string.format(format, PLAYER.GET_PLAYER_NAME(ownerId))
		if  NETWORK.NETWORK_IS_PLAYER_CONNECTED(ownerId) and
		(lastMsg ~= msg or lastNotification.elapsed() >= 15000) then
			notification:normal(msg, HudColour.purpleDark)
			lastMsg = msg
			lastNotification.reset()
		end
		request_control(obj, 1000)
		entities.delete_by_handle(obj)
	::LABEL_CONTINUE::
	end
end)

---------------------
---------------------
-- SETTINGS
---------------------
---------------------

local settings <const> = menu.list(menu.my_root(), translate("Settings", "Settings"), {"settings"}, "")

-------------------------------------
-- LANGUAGE
-------------------------------------

local languageSettings <const> = menu.list(settings, translate("Settings", "Language"), {}, "")
local msg = translate("Settings", "File %s was created")

local helpText = translate("Settings", "Creates a translation template")
menu.action(languageSettings, translate("Settings", "Create New Translation"), {}, helpText, function()
	local fileName = wiriDir .. "new translation.json"
	local content = json.stringify(Features, nil, 4)
	local file <close> = assert(io.open(fileName, "w"))
	file:write(content)
	notification:normal(msg, HudColour.black, "new translation.json")
end)

swap_values = function(a, b)
	local tbl = {}
	for k, v in pairs(a) do
		if type(v) == "table" and type(b[k]) == "table" then
			tbl[k] = swap_values(v, b[k])
		else
			tbl[k] = b[k]
		end
	end
	return tbl
end

local menuName = translate("Settings", "Update Translation")
local helpText = translate("Settings", "Creates an updated translation file")
local warningMsg = translate("Settings", "Would you like to restart the script now to apply the language setting?")

if Config.general.language ~= "english" then
	menu.action(languageSettings, menuName, {}, helpText, function()
		local t = swap_values(Features, Translation)
		local filePath = wiriDir .. Config.general.language .. " (update).json"
		local content = json.stringify(t, nil, 4)
		local file <close> = assert(io.open(filePath, "w"))
		file:write(content)
		notification:normal(msg, HudColour.black, Config.general.language .. " (update).json")
	end)

	local actionId
	actionId = menu.action(languageSettings, "English", {}, "", function()
		Config.general.language = "english"
		Ini.save(configFile, Config)
		menu.show_warning(actionId, CLICK_MENU, warningMsg, function()
			util.stop_script()
		end)
	end)
end


for _, path in ipairs(filesystem.list_files(languageDir)) do
	local filename, ext = string.match(path, '^.+\\(.+)%.(.+)$')
	if ext ~= "json" and Config.general.language == filename then
		goto LABEL_CONTINUE
	end
	local actionId
	actionId = menu.action(languageSettings, capitalize(filename), {}, "", function()
		Config.general.language = filename
		Ini.save(configFile, Config)
        menu.show_warning(actionId, CLICK_MENU, warningMsg, function()
            util.stop_script()
        end)
	end)
::LABEL_CONTINUE::
end

-------------------------------------
-- HEALTH TEXT
-------------------------------------

local helpText <const> = translate("Settings", "If health is going to be displayed while using Mod Health")
menu.toggle(settings, translate("Settings", "Display Health Text"), {"displayhealth"}, helpText, function(toggle)
	Config.general.displayhealth = toggle
end, Config.general.displayhealth)

local healthtxt <const> = menu.list(settings, translate("Settings", "Health Text Position"), {}, "")
local sizeX, sizeY = directx.get_client_size()

local sliderX = menu.slider(healthtxt, "X", {"healthx"}, "", 0, sizeX, math.ceil(sizeX * Config.healthtxtpos.x), 1, function(x)
	Config.healthtxtpos.x = round(x/sizeX, 4)
end)

menu.on_tick_in_viewport(sliderX, function()
	draw_string("~b~HEALTH~s~", Config.healthtxtpos.x, Config.healthtxtpos.y, 0.6, 4)
end)

menu.slider(healthtxt, "Y", {"healthy"}, "", 0, sizeY, math.ceil(sizeY * Config.healthtxtpos.y), 1, function(y)
	Config.healthtxtpos.y = round(y/sizeY, 4)
end)

-------------------------------------
-- NOTIFICATIONS
-------------------------------------

local helpText = translate("Settings", "Returns to Stand's Notification system")
menu.toggle(settings, translate("Settings", "Stand Notifications"), {"standnotifications"}, helpText, function(toggle)
	Config.general.standnotifications = toggle
end, Config.general.standnotifications)

-------------------------------------
-- INTRO
-------------------------------------

menu.toggle(settings, translate("Settings", "Show Intro"), {}, "", function(toggle)
	Config.general.showintro = toggle
end, Config.general.showintro)

-------------------------------------
-- CONTROLS
-------------------------------------

local controlSettings <const> = menu.list(settings, translate("Settings", "Controls") , {}, "")
local airstrikePlaneControl <const> = menu.list(controlSettings, translate("Settings - Controls", "Airstrike Aircraft"), {}, "")
local trans =
{
	AirstrikeAircraft = translate("Settings - Controls", "Press ~%s~ to use Airstrike Aircraft"),
	Keyboard = translate("Settings - Controls", "Keyboard"),
	Controller = translate("Settings - Controls", "Controller"),
	VehicleWeapons = translate("Settings - Controls", "Press ~%s~ to use Vehicle Weapons")
}

for name, control in pairs(Imputs) do
	local keyboard, controller = control[1]:match('^(.+)%s?;%s?(.+)$')
	local strg = ("%s: %s, %s: %s"):format(trans.Keyboard, keyboard, trans.Controller, controller)
	menu.action(airstrikePlaneControl, strg, {}, "", function()
		Config.controls.airstrikeaircraft = control[2]
		util.show_corner_help(trans.AirstrikeAircraft:format(name))
	end)
end

local vehicleWeaponsControl <const> = menu.list(controlSettings, translate("Settings - Controls", "Vehicle Weapons"), {}, "")
for name, control in pairs(Imputs) do
	local keyboard, controller = control[1]:match('^(.+)%s?;%s?(.+)$')
	local strg = ("%s: %s, %s: %s"):format(trans.Keyboard, keyboard, trans.Controller, controller)
	menu.action(vehicleWeaponsControl, strg, {}, "", function()
		Config.controls.vehicleweapons = control[2]
		util.show_corner_help(trans.VehicleWeapons:format(name))
	end)
end

-------------------------------------
-- UFO
-------------------------------------

local ufoSettings <const> = menu.list(settings, translate("Settings", "UFO"), {}, "")

menu.toggle(ufoSettings, translate("Settings - UFO", "Disable Player Boxes"), {}, "", function(toggle)
	Config.ufo.disableboxes = toggle
end, Config.ufo.disableboxes)

local helpText <const> =
translate("Settings - UFO", "Makes the tractor beam to ignore vehicles with non player drivers")
menu.toggle(ufoSettings, translate("Settings - UFO", "Target Only Player Vehicles"), {}, helpText, function(toggle)
	Config.ufo.targetplayer = toggle
end, Config.ufo.targetplayer)

-------------------------------------
-- VEHICLE GUN
-------------------------------------

local vehicleGunSettings <const> = menu.list(settings, translate("Settings", "Vehicle Gun"), {}, "")
menu.toggle(vehicleGunSettings, translate("Settings", "Disable Vehicle Preview"), {}, "", function(toggle)
	Config.vehiclegun.disablepreview = toggle
end, Config.vehiclegun.disablepreview)

---------------------
---------------------
-- WIRISCRIPT
---------------------
---------------------

local script <const> = menu.list(menu.my_root(), "WiriScript", {}, "")
menu.action(script, translate("WiriScript", "Show Credits"), {}, "", function()
	if gShowingIntro then
		return
	end
	gIsShowingCredits = true
	local state = 0
	local timer <const> = newTimer()
	local i = 1
	local delay = 500
	--- Thank you all <3
	local ty <const> =
	{
		"Murten",
		"Hollywood Collins",
		"vsus/Ren",
		"QuickNET",
		"komt",
		"ICYPhoenix",
		"DeF3c",
		"Koda",
		"jayphen",
		"Fwishky",
		"Polygon",
		"Sainan",
		"NONECKED",
		{"wiriscript", "HUD_COLOUR_BLUE"},
	}
	local scaleform <const> = OpeningCredits.new()
	local menuPosX = menu.get_position()
	local posX = menuPosX > 0.5 and 0.0 or 100.0
	local align = posX == 0.0 and "left" or "right"

	AUDIO.SET_MOBILE_RADIO_ENABLED_DURING_GAMEPLAY(true)
	AUDIO.SET_MOBILE_PHONE_RADIO_STATE(true)
	AUDIO.SET_RADIO_TO_STATION_NAME("RADIO_01_CLASS_ROCK")
	AUDIO.SET_CUSTOM_RADIO_TRACK_LIST("RADIO_01_CLASS_ROCK", "END_CREDITS_SAVE_MICHAEL_TREVOR", true)

	util.create_tick_handler(function()
		if not scaleform:HAS_LOADED() then return end
		if timer.elapsed() >= delay and state == 0 then
			scaleform:SETUP_SINGLE_LINE("thankyou", 0.5, 0.5, posX, 0.0, align)
			local kind = type(ty[i])
			local text = (kind == "table") and ty[i][1] or ty[i]
			local colour = "HUD_COLOUR_WHITE"
			if kind == "table" then colour = ty[i][2] end
			scaleform:ADD_TEXT_TO_SINGLE_LINE("thankyou", text, "$font2", colour)
			scaleform:SHOW_SINGLE_LINE("thankyou")
			state = 1
			i = i + 1
			delay = 4000 -- `millis`
			timer.reset()
		end

		if timer.elapsed() >= 4000 and state == 1 then
			scaleform:HIDE("thankyou")
			state = 0
			timer.reset()
		end

		if state == 1 and i == #ty + 1 then
			state = 2
			timer.reset()
		end

		if timer.elapsed() >= 3000 and state == 2 then
			AUDIO.START_AUDIO_SCENE("CAR_MOD_RADIO_MUTE_SCENE")
			util.yield(5000)
			AUDIO.SET_MOBILE_RADIO_ENABLED_DURING_GAMEPLAY(false)
			AUDIO.SET_MOBILE_PHONE_RADIO_STATE(false)
			AUDIO.CLEAR_CUSTOM_RADIO_TRACK_LIST("RADIO_01_CLASS_ROCK")
			AUDIO.SKIP_RADIO_FORWARD()
			AUDIO.STOP_AUDIO_SCENE("CAR_MOD_RADIO_MUTE_SCENE")
			scaleform:SET_AS_NO_LONGER_NEEDED()
			gIsShowingCredits = false
			return false
		end

		if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(2, 194)  then
			state = 2
			timer.reset()
		elseif state ~= 2 then
			if Instructional:begin() then
				Instructional.add_control(194, "REPLAY_SKIP_S")
				Instructional:set_background_colour(0, 0, 0, 80)
				Instructional:draw()
			end
		end

		HUD.HIDE_HUD_AND_RADAR_THIS_FRAME()
		HUD._HUD_WEAPON_WHEEL_IGNORE_SELECTION()
		scaleform:DRAW_FULLSCREEN(255, 255, 255, 255)
	end)
end)

memory.scan("GetNetGamePlayer", "48 83 EC ? 33 C0 38 05 ? ? ? ? 74 ? 83 F9", function (address)
	GetNetGamePlayer_addr = address
end)
--[[memory.scan("UnregisterNetworkObject", "48 89 70 ? 48 89 78 ? 41 54 41 56 41 57 48 83 ec ? 80 7a ? ? 45 8a f9", function (address)
	UnregisterNetworkObject_addr = address - 0xB
end)]]
memory.scan("CNetworkObjectMgr", "48 8B 0D ? ? ? ? 45 33 C0 E8 ? ? ? ? 33 FF 4C 8B F0", function (address)
	CNetworkObjectMgr = memory.rip(address + 3)
end)
--[[memory.scan("ChangeNetObjOwner", "48 8B C4 48 89 58 08 48 89 68 10 48 89 70 18 48 89 78 20 41 54 41 56 41 57 48 81 EC ? ? ? ? 44 8A 62 4B", function (address)
	ChangeNetObjOwner_addr = address 
end)
]]

---@param player integer
---@return integer
function GetNetGamePlayer(player)
	return util.call_foreign_function(GetNetGamePlayer_addr, player)
end

---@param addr integer
---@return string
function read_net_address(addr)
	local fields = {}
	for i = 3, 0, -1 do table.insert(fields, memory.read_ubyte(addr + i)) end
	return table.concat(fields, ".")
end

---@param player integer
---@return string? IP
function get_external_ip(player)
	local netPlayer = GetNetGamePlayer(player)
	if netPlayer == NULL then
		return nil
	end
	local CPlayerInfo = memory.read_long(netPlayer + 0xA0)
	if CPlayerInfo == NULL then
		return nil
	end
	local netPlayerData = CPlayerInfo + 0x20
	local netAddress = read_net_address(netPlayerData + 0x4C)
	return netAddress
end

--[[function UnregisterNetworkObject(object, reason, force1, force2)
	local netObj = get_net_obj(object)
	if netObj == NULL then
		return false
	end
	local net_object_mgr = memory.read_long(CNetworkObjectMgr)
	if net_object_mgr == NULL then
		return false
	end
	util.call_foreign_function(UnregisterNetworkObject_addr, net_object_mgr, netObj, reason, force1, force2)
	return true
end]]

--[[function ChangeNetObjOwner(object, player)
	if NETWORK.NETWORK_IS_IN_SESSION() then
		local net_object_mgr = memory.read_long(CNetworkObjectMgr)
		if net_object_mgr == NULL then
			return false
		end
		if not ENTITY.DOES_ENTITY_EXIST(object) then
			return false
		end
		local netObj = get_net_obj(object)
		if netObj == NULL then
			return false
		end
		local net_game_player = GetNetGamePlayer(player)
		if net_game_player == NULL then
			return false
		end
		util.call_foreign_function(ChangeNetObjOwner_addr, net_object_mgr, netObj, net_game_player, 0)
		return true
	else
		NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(object)
		return true
	end
end]]

local helpText = translate("WiriScript", "Join us in our fan club, created by %s")
local menuName = translate("WiriScript", "Join %s")

menu.hyperlink(menu.my_root(), menuName:format("WiriScript FanClub"), "https://cutt.ly/wiriscript-fanclub", helpText:format("komt"))

players.on_join(generate_features)
players.dispatch_on_join()
util.log("On join dispatched")

-------------------------------------
--ON STOP
-------------------------------------

-- This function (along with some others on_stop functions) allow us to do 
-- some cleanup when the script stops
util.on_stop(function()
	if profilesList:isAnyProfileEnabled() then
		profilesList:disableSpoofing()
		util.log("Active spoofing profile disabled due to script stop")
	end

	if gUsingOrbitalCannon then
		ENTITY.FREEZE_ENTITY_POSITION(PLAYER.PLAYER_PED_ID(), false)
		menu.trigger_commands("becomeorbitalcannon off")
		GRAPHICS.ANIMPOSTFX_STOP("MP_OrbitalCannon")

		HUD.DISPLAY_RADAR(true)
		CAM.RENDER_SCRIPT_CAMS(false, false, 0, true, false, 0)
		STREAMING.CLEAR_FOCUS()
		CAM.DESTROY_ALL_CAMS(true)
		CAM.DO_SCREEN_FADE_IN(0)

		AUDIO.STOP_AUDIO_SCENE("dlc_xm_orbital_cannon_camera_active_scene")
		Sounds.activating:stop()
		Sounds.backgroundLoop:stop()
		Sounds.fireLoop:stop()
		Sounds.zoomOut:stop()
	end

	if gIsShowingCredits then
		AUDIO.SET_MOBILE_RADIO_ENABLED_DURING_GAMEPLAY(false)
		AUDIO.SET_MOBILE_PHONE_RADIO_STATE(false)
		AUDIO.CLEAR_CUSTOM_RADIO_TRACK_LIST("RADIO_01_CLASS_ROCK")
		AUDIO.SKIP_RADIO_FORWARD()
	end

	set_streamed_texture_dict_as_no_longer_needed("WiriTextures")
	Ini.save(configFile, Config)
end)

util.log("Script loaded in %d millis", util.current_time_millis() - scriptStartTime)

while true do
	bodyguardMenu:onTick()
	GuidedMissile.mainLoop()
	UFO.mainLoop()
	handlingEditor:onTick()
	util.yield()
end
