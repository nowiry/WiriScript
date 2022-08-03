--[[
--------------------------------
THIS FILE IS PART OF WIRISCRIPT
         Nowiry#2663
--------------------------------
]]

---@diagnostic disable: exp-in-action, unknown-symbol, break-outside
---@diagnostic disable

require "wiriscript.functions"

--------------------------
-- BITWISE
--------------------------

---@class Bitwise
---@field bits integer
local Bitwise = {}
Bitwise.__index = Bitwise

function Bitwise.new()
	return setmetatable({bits = 0}, Bitwise)
end

function Bitwise:IsBitSet(place)
	return self.bits & (1 << place) ~= 0
end

function Bitwise:SetBit(place)
	self.bits = self.bits | (1 << place)
end

function Bitwise:ClearBit(place)
	self.bits = self.bits & ~(1 << place)
end

function Bitwise:ToggleBit(place, on)
	if on then self:SetBit(place) else self:ClearBit(place) end
end

function Bitwise:reset()
	self.bits = 0
end

---DEBUG
Bitwise.__tostring = function(self, bits)
    bits = bits or 32
    local tbl = {}
	local num = self.bits
    for b = bits, 1, -1 do
        tbl[b] = math.fmod(num, 2)
        num = math.floor((num - tbl[b]) / 2)
    end
    return table.concat(tbl)
end

--------------------------------

local self = {}
self.version = 21
local State <const> =
{
	GettingNearbyEnts = 0,
	SettingTargets = 1,
	Reseted = 2
}
local state = State.Reseted
local targetEnts = {-1, -1, -1, -1, -1, -1}
---Stores nearby targetable entities
---@type integer[]
local nearbyEntities = {-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1}
local numTargets = 0
local maxTargets = 6
local lastShot <const> = newTimer()
local rechargeTimer <const> = newTimer()
local entCount = 1
local shotCount = 1
local chargeLevel = 100.0
local vehicleWeaponSide = 0
local myVehicle = 0
local weapon <const> = util.joaat("VEHICLE_WEAPON_SPACE_ROCKET")
local lockOnBits <const> = Bitwise.new()
local bits <const> = Bitwise.new()
local trans = {
	DisablingPassive = translate("Misc", "Disabling passive mode")
}
local NULL <const> = 0

---@type Timer[]
local homingTimers <const> = {}
for i = 1, 6 do homingTimers[i] = newTimer() end

--- @type Sound[]
local amberHomingSounds <const> = {}
for i = 1, 6 do amberHomingSounds[i] = Sound.new("VULKAN_LOCK_ON_AMBER", 0) end

--- @type Sound[]
local redHomingSounds <const> = {}
for i = 1, 6 do redHomingSounds[i] = Sound.new("VULKAN_LOCK_ON_RED", 0) end

local Bit_IsTargetShooting <const> = 0
local Bit_IsRecharging <const> = 1
local Bit_IsCamPointingInFront <const> = 2
local Bit_IgnoreFriends <const> = 3
local Bit_IgnoreOrgMembers <const> = 4
local Bit_IgnoreCrewMembers <const> = 5


---@param position v3
---@param scale number
---@param colour Colour
local DrawLockOnSprite = function (position, scale, colour)
	if GRAPHICS.HAS_STREAMED_TEXTURE_DICT_LOADED("mpsubmarine_periscope") then
		local txdSizeX = scale * 0.042
		local txdSizeY = scale * 0.042 * GRAPHICS._GET_ASPECT_RATIO(0)
		GRAPHICS.SET_DRAW_ORIGIN(position.x, position.y, position.z, 0)
		GRAPHICS.DRAW_SPRITE(
		"mpsubmarine_periscope", "target_default", 0.0, 0.0, txdSizeX, txdSizeY, 0.0, colour.r, colour.g, colour.b, colour.a, true, 0)
		GRAPHICS.CLEAR_DRAW_ORIGIN()
	end
end


---@param vehicle Vehicle
---@return boolean
local IsAnyPoliceVehicle = function(vehicle)
	local modelHash = ENTITY.GET_ENTITY_MODEL(vehicle)
	pluto_switch int_to_uint(modelHash)do
		case 0x79FBB0C5:
		case 0x9F05F101:
		case 0x71FA16EA:
		case 0x8A63C7B9:
		case 0x1517D4D9:
		case 0xFDEFAEC3:
		case 0x1B38E955:
		case 0x95F4C618:
		case 0xA46462F7:
		case 0x9BAA707C:
		case 0x72935408:
		case 0xB822A1AA:
		case 0xE2E7D4AB:
		case 0x9DC66994:
			return true
	end
	return false
end


---@param entity Entity
---@return boolean
local IsEntityInSaveScreenPos = function (entity)
	local pScreenX = memory.alloc(4)
	local pScreenY = memory.alloc(4)
	local pos = ENTITY.GET_ENTITY_COORDS(entity, true)
	if not GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(pos.x, pos.y, pos.z, pScreenX, pScreenY) then
		return false
	end
	local screenX = memory.read_float(pScreenX)
	local screenY = memory.read_float(pScreenY)
	if screenX < 0.1 or screenX > 0.9 or screenY < 0.1 or screenY > 0.9 then
		return false
	end
	return true
end


---@param player Player
---@return integer
local GetPlayerOrgSlot = function (player)
	if player ~= -1 then
		local address = memory.script_global(1892703 + (player * 599 + 1) + 10)
		if address ~= 0 then return memory.read_int(address) end
	end
	return -1
end


---@param player0 Player
---@param player1 Player
---@return boolean
local ArePlayersInTheSameOrg = function (player0, player1)
	local slot0 = GetPlayerOrgSlot(player0)
	return slot0 ~= -1 and slot0 == GetPlayerOrgSlot(player1)
end


---@param player0 Player
---@param player1 Player
---@return boolean
local ArePlayersInTheSameCrew = function (player0, player1)
	if NETWORK.NETWORK_CLAN_SERVICE_IS_VALID() then
		local pHandle0 = memory.alloc(104)
		local pHandle1 = memory.alloc(104)
		NETWORK.NETWORK_HANDLE_FROM_PLAYER(player0, pHandle0, 13)
		NETWORK.NETWORK_HANDLE_FROM_PLAYER(player1, pHandle1, 13)

		if NETWORK.NETWORK_CLAN_PLAYER_IS_ACTIVE(pHandle0) and
		NETWORK.NETWORK_CLAN_PLAYER_IS_ACTIVE(pHandle1) then
			local pClanDesc0 = memory.alloc(280)
			local pClanDesc1 = memory.alloc(280)
			NETWORK.NETWORK_CLAN_PLAYER_GET_DESC(pClanDesc0, 35, pHandle0)
			NETWORK.NETWORK_CLAN_PLAYER_GET_DESC(pClanDesc1, 35, pHandle0)
			return memory.read_int(pClanDesc0 + 0x0) == memory.read_int(pClanDesc1 + 0x0)
		end

	end
	return false
end


---@param player Player
local IsPedTargetablePlayer = function (ped)
	local player = NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(ped)
	if player == -1 or not players.exists(player) then
		return false
	end
	if is_player_passive(player) then
		return false
	elseif bits:IsBitSet(Bit_IgnoreFriends) and is_player_friend(player) then
		return false
	elseif bits:IsBitSet(Bit_IgnoreOrgMembers) and
	ArePlayersInTheSameOrg(players.user(), player) then
		return false
	elseif bits:IsBitSet(Bit_IgnoreCrewMembers) and
	ArePlayersInTheSameCrew(players.user(), player) then
		return false
	end
	return true
end


---@param vehicle Vehicle
---@return boolean
local DoesVehicleHavePlayerDriver = function(vehicle)
	if VEHICLE.IS_VEHICLE_SEAT_FREE(vehicle, -1, false) then
		return false
	end
	local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1, false)
	if not ENTITY.DOES_ENTITY_EXIST(driver) or not PED.IS_PED_A_PLAYER(driver) or
	not IsPedTargetablePlayer(driver) then
		return false
	end
	return true
end


---@param entity Entity
---@param target Entity
---@return number
local GetDistanceBetweenEntities = function(entity, target)
	if not ENTITY.DOES_ENTITY_EXIST(entity) or not ENTITY.DOES_ENTITY_EXIST(target) then
		return 0.0
	end
	local pos = ENTITY.GET_ENTITY_COORDS(entity, true)
	return ENTITY.GET_ENTITY_COORDS(target, true):distance(pos)
end


---@param player Player
---@return integer
local GetPlayerWantedLevel = function (player)
	local netPlayer = GetNetGamePlayer(player)
	if netPlayer == NULL then
		return 0
	end
	local playerInfo = memory.read_long(netPlayer + 0xA0)
	if playerInfo == NULL then
		return 0
	end
	return memory.read_uint(playerInfo + 0x0888)
end


---@param entity Entity
---@return boolean
local IsEntityTargetable = function(entity)
	if not ENTITY.DOES_ENTITY_EXIST(entity) or ENTITY.IS_ENTITY_DEAD(entity, false) then
		return false
	end
	local distance = GetDistanceBetweenEntities(myVehicle, entity)
	if distance > 500.0 or distance < 10.0 then
		return false
	end
	if ENTITY.IS_ENTITY_A_PED(entity) and PED.IS_PED_A_PLAYER(entity) and
	not PED.IS_PED_IN_ANY_VEHICLE(entity, false) and players.user_ped() ~= entity and
	IsPedTargetablePlayer(entity) then
		return true
	elseif ENTITY.IS_ENTITY_A_VEHICLE(entity) and entity ~= myVehicle then
		if DoesVehicleHavePlayerDriver(entity) then
			return true
		elseif GetPlayerWantedLevel(players.user()) > 0 and IsAnyPoliceVehicle(entity) then
			return true
		end
	end
	return false
end


local SetNearbyEntities = function()
	local count = 1
	local entities = entities.get_all_vehicles_as_handles()
	for _, player in ipairs(players.list(false)) do
		entities[#entities+1] = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player)
	end
	for _, entity in ipairs(entities) do
		if count == 20 then break end
		if IsEntityTargetable(entity) and not table.find(targetEnts, entity) and
		not table.find(nearbyEntities, entity) and IsEntityInSaveScreenPos(entity) then
			nearbyEntities[count] = entity
			count = count + 1
		end
	end
	state = State.SettingTargets
end


---@param entity Entity
---@return boolean
local TargetEntitiesInsert = function (entity)
	for i, target in ipairs(targetEnts) do
        if target == -1 or not ENTITY.DOES_ENTITY_EXIST(target) then
            targetEnts[i] = entity
            numTargets = numTargets + 1
			return true
        end
    end
	return false
end


---@return integer
local GetFartherTargetIndex = function()
	local lastDistance = 0.0
	local index = -1
	local myPos = ENTITY.GET_ENTITY_COORDS(players.user_ped(), true)
	for i = 1, maxTargets do
		local pos = ENTITY.GET_ENTITY_COORDS(targetEnts[i], true)
		local distance = myPos:distance(pos)
		if distance > lastDistance then
			index = i
			lastDistance = distance
		end
	end
	return index
end


---@param entity Entity
---@param amplitude number
---@return boolean
local IsCameraPointingInFrontOfEntity = function(entity, amplitude)
	local camDir = CAM.GET_GAMEPLAY_CAM_ROT(0):toDir()
	local fwdVector = ENTITY.GET_ENTITY_FORWARD_VECTOR(entity)
	camDir.z, fwdVector.z = 0.0, 0.0
	local angle = math.acos(fwdVector:dot(camDir) / (#camDir * #fwdVector))
	return math.deg(angle) < amplitude
end


local SetTargetEntities = function()
	if entCount < 1 or entCount > 20 then
        entCount = 1
    end
	local entity = nearbyEntities[entCount]

	if ENTITY.DOES_ENTITY_EXIST(entity) and not ENTITY.IS_ENTITY_DEAD(entity, false) and
	ENTITY.HAS_ENTITY_CLEAR_LOS_TO_ENTITY(myVehicle, entity, 511) then
		if numTargets < maxTargets then
			if TargetEntitiesInsert(entity) then
				nearbyEntities[entCount] = -1
				entCount = entCount + 1
			end
		else
			local targetId = GetFartherTargetIndex()
			local target = targetEnts[targetId]

			if targetId >= 1 and target then
				local entityPos = ENTITY.GET_ENTITY_COORDS(entity, true)
				local myPos = ENTITY.GET_ENTITY_COORDS(players.user_ped(), true)
				local targetPos = ENTITY.GET_ENTITY_COORDS(target, true)
				local targetDist = targetPos:distance(myPos)
				local entDist = entityPos:distance(myPos)
				if targetDist > entDist then targetEnts[targetId] = entity end
			end

			nearbyEntities[entCount] = -1
			entCount = entCount + 1
		end
	else
		nearbyEntities[entCount] = -1
		entCount = entCount + 1
	end

	if entCount >= 20 then
		state = State.GettingNearbyEnts
		entCount = 1
	end
end


local IsAnyHomingSoundActive = function()
	for i = 1, 6 do
		local amberSound = amberHomingSounds[i]
		local redSound = redHomingSounds[i]
		if not amberSound:hasFinished() or not redSound:hasFinished() then
			return true
		end
	end
	return false
end


---@param entity Entity
---@param count integer
local LockOnEnity = function (entity, count)
	local redSound = redHomingSounds[count]
	local bitPlace = count - 1
	local lockOnTimer = homingTimers[count]
	local amberSound = amberHomingSounds[count]

	if not ENTITY.DOES_ENTITY_EXIST(entity) or ENTITY.IS_ENTITY_DEAD(entity, false) or
	not IsEntityInSaveScreenPos(entity) then
		amberSound:stop()
		lockOnBits:ClearBit(bitPlace)
		redSound:stop()
		lockOnBits:ClearBit(bitPlace + 6)
		return
	end

	if not lockOnBits:IsBitSet(bitPlace) then
		if amberSound:hasFinished() and not IsAnyHomingSoundActive() then
            lockOnBits:SetBit(bitPlace)
			amberSound:play()
			lockOnTimer.reset()
		end
	elseif not lockOnBits:IsBitSet(bitPlace + 6) and
	lockOnTimer.elapsed() >= 1000 then
		amberSound:stop()
		if redSound:hasFinished() then
			lockOnBits:SetBit(bitPlace + 6)
			redSound:play()
			lockOnTimer.reset()
		end
	elseif lockOnBits:IsBitSet(bitPlace + 6) and
	lockOnTimer.elapsed() >= 700 then
		if not redSound:hasFinished() then redSound:stop() end
	end

	local hudColour = HudColour.orange
	if lockOnBits:IsBitSet(bitPlace + 6) then
		hudColour = HudColour.red
	end
	local pos = ENTITY.GET_ENTITY_COORDS(entity, true)
	DrawLockOnSprite(pos, 1.0, get_hud_colour(hudColour))
end


local LockOnTargets = function()
    if numTargets == 0 and ENTITY.DOES_ENTITY_EXIST(myVehicle) and not ENTITY.IS_ENTITY_DEAD(myVehicle) and
	VEHICLE.IS_VEHICLE_DRIVEABLE(myVehicle) then
        local coords = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(myVehicle, 0.0, 100.0, 0.0)
		local colour = get_hud_colour(HudColour.white)
		colour.a = 160
        DrawLockOnSprite(coords, 1.0, colour)
    end
    for i, target in ipairs(targetEnts) do LockOnEnity(target, i) end
end


local UpdateTargetEntities = function()
	local count = 0
	for i = 1, 6 do
		local entity = targetEnts[i]
		if entity == -1 or not ENTITY.DOES_ENTITY_EXIST(entity) or ENTITY.IS_ENTITY_DEAD(entity, false) or
		not IsEntityInSaveScreenPos(entity) or not bits:IsBitSet(Bit_IsCamPointingInFront) or not
		ENTITY.HAS_ENTITY_CLEAR_LOS_TO_ENTITY(entity, myVehicle, 511) or
		not IsEntityTargetable(entity) then
			targetEnts[i] = -1
			if numTargets > 0 then numTargets = numTargets - 1 end
		else
			if i > maxTargets then
				targetEnts[i] = -1
				if numTargets > 0 then numTargets = numTargets - 1 end
			else
				count = count + 1
			end
		end
	end
	if count ~= numTargets then
		numTargets = count
	end
end


---@param vehicle Vehicle
---@param damage number
---@param weaponHash Hash
---@param ownerPed Ped
---@param isAudible boolean
---@param isVisible boolean
---@param speed number
---@param target Ped
---@param position integer
local ShootFromVehicle = function (vehicle, damage, weaponHash, ownerPed, isAudible, isVisible, speed, target, position)
	local pos = ENTITY.GET_ENTITY_COORDS(vehicle, true)
	local min, max = v3.new(), v3.new()
	MISC.GET_MODEL_DIMENSIONS(ENTITY.GET_ENTITY_MODEL(vehicle), min, max)
	local direction = ENTITY.GET_ENTITY_ROTATION(vehicle, 2):toDir()
	local a

	if position == 0 then
		local offset = {x = min.x + 0.3, y = max.y - 0.15, z = 0.3}
		a = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, offset.x, offset.y, offset.z)
	elseif position == 1 then
		local offset = {x = max.x - 0.3, y = max.y - 0.15, z = 0.3}
		a = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, offset.x, offset.y, offset.z)
	end

	local b = v3.new(direction)
	b:mul(5.0); b:add(a)
	MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS_IGNORE_ENTITY_NEW(a.x, a.y, a.z, b.x, b.y, b.z, damage, true, weaponHash, ownerPed, isAudible, not isVisible, speed, vehicle, 0, 0, target, 0, 0, 0, 0)
	AUDIO.PLAY_SOUND_FROM_COORD(-1, "Fire", pos.x, pos.y, pos.z, "DLC_BTL_Terrobyte_Turret_Sounds", true, 120, true)
end


local ShootMissiles = function()
	local controlId = 68
	if PED.IS_PED_IN_FLYING_VEHICLE(players.user_ped()) then
		controlId = 114
	end
	local target = 0

	if PAD.IS_DISABLED_CONTROL_PRESSED(2, controlId) or bits:IsBitSet(Bit_IsTargetShooting) then
		if shotCount < 1 or shotCount > 6 then shotCount = 1 end
		if bits:IsBitSet(Bit_IsRecharging) or lastShot.elapsed() < 300 then
			return
		end

		local vehicle = PED.GET_VEHICLE_PED_IS_IN(players.user_ped(), false)
		local pos = ENTITY.GET_ENTITY_COORDS(vehicle, true)
		vehicleWeaponSide = vehicleWeaponSide == 0 and 1 or 0
		local ownerPed = players.user_ped()

		if numTargets > 0 then
			if ENTITY.DOES_ENTITY_EXIST(targetEnts[shotCount]) and
			not ENTITY.IS_ENTITY_DEAD(targetEnts[shotCount], false) then
				target = targetEnts[shotCount]
			end
			bits:SetBit(Bit_IsTargetShooting)
			shotCount = shotCount + 1
			ShootFromVehicle(vehicle, 200, weapon, ownerPed, true, true, 1000.0, target, vehicleWeaponSide)
			lastShot.reset()
			if numTargets == shotCount - 1 then
				bits:SetBit(Bit_IsRecharging)
				bits:ClearBit(Bit_IsTargetShooting)
                shotCount = 1
				chargeLevel = 0
				rechargeTimer.reset()
			end
		else
			ShootFromVehicle(vehicle, 200, weapon, ownerPed, true, true, 1000.0, 0, vehicleWeaponSide)
			lastShot.reset()
		end
	end
end


local StopHomingSounds = function()
	for _, sound in ipairs(redHomingSounds) do
		if not sound:hasFinished() then sound:stop() end
	end
	for _, sound in ipairs(amberHomingSounds) do
		if not sound:hasFinished() then sound:stop() end
	end
end


local LockOnManager = function ()
	if bits:IsBitSet(Bit_IsRecharging) then
		if rechargeTimer.elapsed() < 3000 then
			chargeLevel = 100 * rechargeTimer.elapsed() / 3000
			StopHomingSounds()
			lockOnBits:reset()
			return
		else
			bits:ClearBit(Bit_IsRecharging)
			chargeLevel = 100.0
			shotCount = 0
		end
	end

	if not bits:IsBitSet(Bit_IsTargetShooting) and not bits:IsBitSet(Bit_IsRecharging) then
		if state == State.GettingNearbyEnts then
			SetNearbyEntities()
		elseif state == State.SettingTargets then
			SetTargetEntities()
		end
		UpdateTargetEntities()
	end
	LockOnTargets()
end


Print = {}

---@param font integer
---@param scale v2
---@param centred boolean
---@param rightJustified boolean
---@param outline boolean
---@param colour? Colour
---@param wrap? v2
Print.setupdraw = function(font, scale, centred, rightJustified, outline, colour, wrap)
    HUD.SET_TEXT_FONT(font)
    HUD.SET_TEXT_SCALE(scale.x, scale.y)
    colour = colour or {r = 255, g = 255, b = 255, a = 255}
    HUD.SET_TEXT_COLOUR(colour.r, colour.g, colour.b, colour.a)
    wrap = wrap or {x = 0.0, y = 1.0}
    HUD.SET_TEXT_WRAP(wrap.x, wrap.y)
    HUD.SET_TEXT_RIGHT_JUSTIFY(rightJustified)
    HUD.SET_TEXT_CENTRE(centred)
    HUD.SET_TEXT_DROPSHADOW(0, 0, 0, 0, 0)
    HUD.SET_TEXT_EDGE(0, 0, 0, 0, 0)
    if outline then HUD.SET_TEXT_OUTLINE() end
end


---@param text string
---@param x number
---@param y number
Print.drawstring = function (text, x, y)
    HUD.BEGIN_TEXT_COMMAND_DISPLAY_TEXT(text)
	GRAPHICS.BEGIN_TEXT_COMMAND_SCALEFORM_STRING(text)
	GRAPHICS.END_TEXT_COMMAND_SCALEFORM_STRING()
    HUD.END_TEXT_COMMAND_DISPLAY_TEXT(x, y, 0)
end


local DrawChargingMeter = function ()
	local safeRight = 0.95
	local maxWidth = 0.119
	local width = interpolate(0.0, maxWidth, chargeLevel / 100)
	local colour = {r = 0, g = 153, b = 51, a = 255}
	if chargeLevel < 100 then
		colour = {r = 153, g = 0, b = 0, a = 255}
	end
	local height = 0.035
	local rectPosX = 0.85 + width /2
	GRAPHICS.DRAW_RECT(rectPosX, 0.55, width, height, colour.r, colour.g, colour.b, colour.a)

	local textColour = get_hud_colour(HudColour.white)
	Print.setupdraw(4, {x = 0.55, y = 0.55}, true, false, false, textColour)
	local textPosX = 0.85 + maxWidth/2
	local text = (chargeLevel == 100) and "DRONE_READY" or "DRONE_CHARGING"
	Print.drawstring(text, textPosX, 0.55 - 0.019)

	GRAPHICS.DRAW_RECT(0.85 + maxWidth/2, 0.496, maxWidth, 0.06, 156, 156, 156, 80)
	Print.setupdraw(4, {x = 0.65, y = 0.65}, true, false, false, textColour)
	Print.drawstring("DRONE_MISSILE", textPosX + 0.001, 0.495 - 0.02)
end


local DisableControlActions = function ()
	PAD.DISABLE_CONTROL_ACTION(2, 25, true)
	PAD.DISABLE_CONTROL_ACTION(2, 91, true)
	PAD.DISABLE_CONTROL_ACTION(2, 99, true)
	PAD.DISABLE_CONTROL_ACTION(2, 115, true)
	PAD.DISABLE_CONTROL_ACTION(2, 262, true)
	PAD.DISABLE_CONTROL_ACTION(2, 68, true)
	PAD.DISABLE_CONTROL_ACTION(2, 69, true)
	PAD.DISABLE_CONTROL_ACTION(2, 70, true)
	PAD.DISABLE_CONTROL_ACTION(2, 114, true)
	PAD.DISABLE_CONTROL_ACTION(2, 331, true)
end


self.reset = function()
	set_streamed_texture_dict_as_no_longer_needed("mpsubmarine_periscope")
	lockOnBits:reset()
	targetEnts = {-1, -1, -1, -1, -1, -1}
	entCount = 1
	numTargets = 0
	shotCount = 1
	chargeLevel = 100.0
	myVehicle = 0
	StopHomingSounds()
	nearbyEntities = {-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1}
	state = State.Reseted
end


---@param ignore boolean
self.SetIgnoreFriends = function(ignore)
	bits:ToggleBit(Bit_IgnoreFriends, ignore)
end

---@param ignore boolean
self.SetIgnoreOrgMembers = function (ignore)
	bits:ToggleBit(Bit_IgnoreOrgMembers, ignore)
end

---@param ignore boolean
self.SetIgnoreCrewMembers = function (ignore)
	bits:ToggleBit(Bit_IgnoreCrewMembers, ignore)
end

---@param value integer
self.SetMaxTargets = function (value)
	maxTargets = value
end


self.mainLoop = function ()
	if NETWORK.NETWORK_IS_GAME_IN_PROGRESS() and
	PLAYER.IS_PLAYER_PLAYING(players.user()) and PED.IS_PED_IN_ANY_VEHICLE(players.user_ped(), false) then
		
		local vehicle = PED.GET_VEHICLE_PED_IS_IN(players.user_ped(), false)
		if ENTITY.DOES_ENTITY_EXIST(vehicle) and not ENTITY.IS_ENTITY_DEAD(vehicle, false) and
		VEHICLE.IS_VEHICLE_DRIVEABLE(vehicle, false) and
		VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1, false) == players.user_ped() then

			if not is_player_passive(players.user()) then
				if state == State.Reseted then
					request_streamed_texture_dict("mpsubmarine_periscope")
					state = State.GettingNearbyEnts
				end
				myVehicle = vehicle
				if IsCameraPointingInFrontOfEntity(vehicle, 40.0) then
					bits:SetBit(Bit_IsCamPointingInFront)
				else
					bits:ClearBit(Bit_IsCamPointingInFront)
				end

				LockOnManager()
				ShootMissiles()
				DrawChargingMeter()
				DisablePhone()
				DisableControlActions()
			else
				if state ~= State.Reseted then
					self.reset()
				end
				local timerStart = memory.script_global(2815059 + 4463)
				local timerState = memory.script_global(2815059 + 4463 + 1)
				if timerStart ~= NULL and timerState ~= NULL and
				memory.read_int(timerState) == 0 then
					notification:normal(trans.DisablingPassive)
					memory.write_int(timerStart, NETWORK.GET_NETWORK_TIME())
					memory.write_int(timerState, 1)
				end
			end
		elseif state ~= State.Reseted then
			self.reset()
		end
	elseif state ~= State.Reseted then
		self.reset()
	end
end

return self