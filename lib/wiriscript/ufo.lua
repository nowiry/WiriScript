--[[
--------------------------------
THIS FILE IS PART OF WIRISCRIPT
         Nowiry#2663
--------------------------------
]]

require "wiriscript.functions"

local self = {}
self.version = 19

local UfoState <const> =
{
    nonExistent = -1,
    beingCreated = 0,
    onFlight = 1,
    beingDestroyed = 2,
    fadingIn = 3,
}
local state = UfoState.nonExistent
local vehicleHash <const> = util.joaat("hydra")
local objHash = util.joaat("imp_prop_ship_01a")
local jet = 0
local object = 0
local cam = 0
local targetVehicles = {}
local isCannonActive = false
local scaleform = GRAPHICS.REQUEST_SCALEFORM_MOVIE("ORBITAL_CANNON_CAM")
local sound <const> = {
    zoomOut = Sound.new("zoom_out_loop", "dlc_xm_orbital_cannon_sounds"),
    fireLoop = Sound.new("cannon_charge_fire_loop", "dlc_xm_orbital_cannon_sounds"),
    backgroundLoop = Sound.new("background_loop", "dlc_xm_orbital_cannon_sounds"),
    panLoop = Sound.new("pan_loop", "dlc_xm_orbital_cannon_sounds")
}
local sphereColour = Colour.new(0, 255, 255, 255)
local backholePos

self.exists = function ()
    return state ~= UfoState.nonExistent
end

self.create = function ()
    state = UfoState.beingCreated
end

self.destroy = function ()
    state = UfoState.beingDestroyed
end

---@param model string
self.setObjModel = function (model)
    assert(type(model) == "string", "model must be a string, got a " .. type(model))
    objHash = util.joaat(model)
end

---Returns the positive equivalent of a negative angle.
---@param value number #angle in `degrees`
---@return number
local function makePositive(value)
    if value < 0 then value = value + 360 end
    return value
end

local function drawInstructionalButtons()
    if Instructional:begin() then
        Instructional.add_control(75, "BB_LC_EXIT")
        if isCannonActive then
            Instructional.add_control(80, "Disable Cannon")
            if PAD._IS_USING_KEYBOARD(0) then
                Instructional.add_control_group(29, "ORB_CAN_ZOOM")
            end
            Instructional.add_control_group(21, "HUD_INPUT101")
        else
            Instructional.add_control(119, "Vertical flight")
            Instructional.add_control(80, "Cannon")
            if #targetVehicles > 0 then
                Instructional.add_control(22, "Release vehicles")
            end
            if #targetVehicles < 15 then
                Instructional.add_control(73, "Tractor beam")
            end
        end
        Instructional.add_control(69, "ORB_CAN_FIRE")
        Instructional:set_background_colour(0, 0, 0, 80)
        Instructional:draw()
        SetTimerPosition(1)
    end
end


local --[[CPed*]] getVehicleDriver = function (--[[CAutomobile*]] vehicle)
    if vehicle == 0 then return 0 end
    return  memory.read_long(vehicle + 0x0C68)
end

local isPedPlayer = function (--[[CPed*]] ped)
    return ped ~= 0 and memory.read_long(ped + 0x10C8) ~= 0
end


local attractVehicles = function ()
    if #targetVehicles >= 16 then return end
    for _, vehicle in ipairs(entities.get_all_vehicles_as_handles()) do
        if #targetVehicles >= 16 then break end
        local vehiclePos = ENTITY.GET_ENTITY_COORDS(vehicle, false)
        local distance = backholePos:distance(vehiclePos)
        if ENTITY.DOES_ENTITY_EXIST(vehicle) and vehicle ~= jet and distance < 80.0 and
        ENTITY.HAS_ENTITY_CLEAR_LOS_TO_ENTITY(object, vehicle, TraceFlag.world) then
            if gConfig.ufo.targetplayer then
                local pVehicle = entities.handle_to_pointer(vehicle)
                local pDriver = getVehicleDriver(pVehicle)
                if isPedPlayer(pDriver) and not table.find(targetVehicles, vehicle) then
                    table.insert(targetVehicles, vehicle)
                end
            elseif not table.find(targetVehicles, vehicle) then
                table.insert(targetVehicles, vehicle)
            end
        end
    end
end


local easeOutExpo = function (x)
    return x >= 1.0 and 1.0 or 1 - 2^(-10 * x)
end

local tractorBeam = function ()
    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(jet, 0.0, 0.0, -8.0)
    backholePos = pos
    if not isCannonActive then
        Colour.rainbow(sphereColour)
        GRAPHICS._DRAW_SPHERE(pos.x, pos.y, pos.z, 1.0, sphereColour.r, sphereColour.g, sphereColour.b, 255)
    end
    if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(2, 73) then
        attractVehicles()
    elseif PAD.IS_DISABLED_CONTROL_JUST_PRESSED(2, 22) then
        targetVehicles = {}
    end
    for i = #targetVehicles, 1, -1 do
        local vehicle = targetVehicles[i]
        local vehiclePos = ENTITY.GET_ENTITY_COORDS(vehicle)
        local distance = vehiclePos:distance(pos)
        if ENTITY.DOES_ENTITY_EXIST(vehicle) and distance < 200 then
            local delta = v3.new(pos)
            delta:sub(vehiclePos)
            local multiplier = easeOutExpo(distance / 50.0) * 2.5
            delta:mul(multiplier)
            local vel = ENTITY.GET_ENTITY_VELOCITY(jet)
            vel:add(delta)
            request_control_once(vehicle)
            ENTITY.SET_ENTITY_VELOCITY(vehicle, vel.x, vel.y, vel.z)
            ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(vehicle, jet, true)
        else table.remove(targetVehicles, i) end
    end
end


local function drawLockonSprite(pos, size, hudColour)
	if GRAPHICS.HAS_STREAMED_TEXTURE_DICT_LOADED("helicopterhud") then
		local colour = get_hud_colour(hudColour)
		GRAPHICS.SET_DRAW_ORIGIN(pos.x, pos.y, pos.z, 0)
		size = size * 0.03
		GRAPHICS.DRAW_SPRITE("helicopterhud", "hud_outline", 0.0, 0.0, size, size * GRAPHICS._GET_ASPECT_RATIO(0), 0.0, colour.r, colour.g, colour.b, colour.a, false)
		GRAPHICS.CLEAR_DRAW_ORIGIN()
	else
		GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT("helicopterhud", 0)
	end
end


local drawSpriteOnPlayers = function ()
    if gConfig.ufo.disableboxes then
        return
    end
    for _, player in pairs(players.list(false)) do
        local playerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player)
        if ENTITY.IS_ENTITY_ON_SCREEN(playerPed) and not players.is_in_interior(player) then
            local playerPos = ENTITY.GET_ENTITY_COORDS(playerPed, false)
            local myPos = ENTITY.GET_ENTITY_COORDS(players.user_ped())
            local dist = myPos:distance(myPos)
            local size = interpolate(1.0, 0.5, dist / 1000.0)
            local hudColour = is_player_friend(player) and HudColour.friendly or HudColour.red
            drawLockonSprite(playerPos, size, hudColour)
        end
    end
end


local zoomTimer <const> = newTimer()
local maxFov <const> = 110.0
local minFov <const> = 25.0
local lastZoom
local zoom = 0.0
local camFov = maxFov

local setCannonCamZoom = function ()
    if not PAD._IS_USING_KEYBOARD(2) then return end
    if PAD.IS_CONTROL_JUST_PRESSED(2, 241) and zoom < 1.0 then
        zoom = zoom + 0.25
        zoomTimer.reset()
    end
    if PAD.IS_CONTROL_JUST_PRESSED(2, 242) and zoom > 0.0 then
        zoom = zoom - 0.25
        zoomTimer.reset()
    end
    if zoom ~= lastZoom then
        sound.zoomOut:play()
        GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SET_ZOOM_LEVEL")
        GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(zoom)
        GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
        lastZoom = zoom
    end
    local fovTarget = interpolate(maxFov, minFov, zoom)
	local fov = CAM.GET_CAM_FOV(CAM.GET_RENDERING_CAM())
    if fovTarget ~= fov and zoomTimer.elapsed() <= 300 then
        camFov = interpolate(fov, fovTarget, zoomTimer.elapsed() / 300)
        CAM.SET_CAM_FOV(CAM.GET_RENDERING_CAM(), camFov)
    else
        sound.zoomOut:stop()
    end
end


local cameraRot = v3.new(-89.0, 0.0, 0.0)

local function setCannonCamRot()
    local mult = 1.0
    local axisX = PAD.GET_CONTROL_UNBOUND_NORMAL(2, 220)
    local axisY = PAD.GET_CONTROL_UNBOUND_NORMAL(2, 221)
    local pitch
    local heading
    local frameTime <const> = 30 * MISC.GET_FRAME_TIME()
    local maxRotX <const> = -25.0
    local minRotX <const> = -89.0
    if PAD._IS_USING_KEYBOARD(0) then
		mult = 3.0
		axisX = axisX * mult
		axisY = axisY * mult
	end
    if PAD.IS_LOOK_INVERTED() then
        axisY = -axisY
    end
    if axisX ~= 0 or axisY ~= 0 then
        heading = -(axisX * 0.05) * frameTime * 25
        pitch = -(axisY * 0.05) * frameTime * 25
        cameraRot:add(v3.new(pitch, 0, heading))
        if cameraRot.x > maxRotX then
            cameraRot.x = maxRotX
        elseif cameraRot.x < minRotX then
            cameraRot.x = minRotX
        end
        sound.panLoop:play()
        _ATTACH_CAM_TO_ENTITY_WITH_FIXED_DIRECTION(cam, jet, cameraRot.x, 0.0, cameraRot.z, 0.0, 0.0, -4.0, true)
    else
        sound.panLoop:stop()
    end
    local heading = makePositive(CAM.GET_CAM_ROT(cam, 2).z)
    HUD.LOCK_MINIMAP_ANGLE(math.ceil(heading))
end


local charge = 0.0
local countdown = 3 -- `seconds`
local isCounting = false
local lastShot <const> = newTimer()
local lastCountdown <const> = newTimer()
local rechargeDuration <const> = 2000 -- `ms`

local renderCannonCam = function ()
    if not isCannonActive then
        if CAM.IS_CAM_RENDERING(cam) then
            CAM.RENDER_SCRIPT_CAMS(false, false, 0, true, false, 0)
        end
        if AUDIO.IS_AUDIO_SCENE_ACTIVE("DLC_BTL_Hacker_Drone_HUD_Scene") then
            AUDIO.STOP_AUDIO_SCENE("DLC_BTL_Hacker_Drone_HUD_Scene")
        end
        sound.panLoop:stop()
        sound.zoomOut:stop()
        sound.fireLoop:stop()
        sound.backgroundLoop:stop()
        return
    end

    if not CAM.IS_CAM_RENDERING(cam) then
        CAM.RENDER_SCRIPT_CAMS(true, false, 0, true, false, 0)
    end
    PAD.DISABLE_CONTROL_ACTION(2, 85, true)
    PAD.DISABLE_CONTROL_ACTION(2, 122, true)

    setCannonCamZoom()
    setCannonCamRot()

    GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SET_STATE")
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(3)
	GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

    GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SET_CHARGING_LEVEL")
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(charge)
	GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

    if PAD.IS_CONTROL_PRESSED(2, 69) then
        local raycastResult = get_raycast_result(1000.0)
        local pos = raycastResult.endCoords
        if raycastResult.didHit then
            STREAMING.SET_FOCUS_POS_AND_VEL(pos.x, pos.y, pos.z, 0.0, 0.0, 0.0)
        end
        if charge == 1.0 then
            if not isCounting then
                sound.fireLoop:play()
                lastCountdown.reset()
                isCounting = true
            end
            if countdown ~= 0 then
                if lastCountdown.elapsed() >= 1000 then
                    countdown = countdown - 1
                    lastCountdown.reset()
                end
                GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SET_COUNTDOWN")
				GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(countdown)
				GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
            else
                charge = 0.0
                countdown = 3
                isCounting = false

                local rot = raycastResult.surfaceNormal:toRot()
                local effect = Effect.new("scr_xm_orbital", "scr_xm_orbital_blast")
                request_fx_asset(effect.asset)
                FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, 59, 1.0, true, false, 1.0)
                GRAPHICS.USE_PARTICLE_FX_ASSET(effect.asset)
                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD(
					effect.name,
					pos.x,
                    pos.y,
                    pos.z,
					rot.x - 90.0,
                    rot.y,
                    rot.z,
					1.0,
					false, false, false, true
				)
                AUDIO.PLAY_SOUND_FROM_COORD(-1, "DLC_XM_Explosions_Orbital_Cannon", pos.x, pos.y, pos.z, 0, true, 0, false)
                CAM.SHAKE_CAM(cam, "GAMEPLAY_EXPLOSION_SHAKE", 1.5)
                lastShot.reset()
            end
        elseif charge ~= 1.0 then
            charge = interpolate(0.0, 1.0, lastShot.elapsed() / rechargeDuration)
            sound.fireLoop:stop()
            countdown = 3
            isCounting = false
        end
    elseif charge ~= 1.0 or isCounting then
        charge = interpolate(0.0, 1.0, lastShot.elapsed() / rechargeDuration)
        AUDIO.SET_VARIABLE_ON_SOUND(sound.fireLoop.Id, "Firing", 0.0)
        sound.fireLoop:stop()
        countdown = 3
        isCounting = false
    end

    if not AUDIO.IS_AUDIO_SCENE_ACTIVE("DLC_BTL_Hacker_Drone_HUD_Scene") then
        AUDIO.START_AUDIO_SCENE("DLC_BTL_Hacker_Drone_HUD_Scene")
    end
    sound.backgroundLoop:play()
    STREAMING.CLEAR_FOCUS()
    GRAPHICS.DRAW_SCALEFORM_MOVIE_FULLSCREEN(scaleform, 255, 255, 255, 255, 0)
end


local setVehicleCamDistance = function (--[[Vehicle]] vehicle, value)
    if vehicle == 0 then return end
    local addr = memory.read_long(entities.handle_to_pointer(vehicle) + 0x20)
	if addr ~= NULL then
        memory.write_float(addr + 0x38, value)
    end
end


local fadingTimer <const> = newTimer()

self.mainLoop = function ()
    if state == UfoState.beingCreated then
        if not CAM.IS_SCREEN_FADED_OUT() then
            CAM.DO_SCREEN_FADE_OUT(800)
        else
            if not ENTITY.DOES_ENTITY_EXIST(jet) then
                request_model(vehicleHash); request_model(objHash)
                local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
                jet = entities.create_vehicle(vehicleHash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
                ENTITY.SET_ENTITY_VISIBLE(jet, false, 0)
                ENTITY.SET_ENTITY_VISIBLE(PLAYER.PLAYER_PED_ID(), false, 0)
                VEHICLE.SET_VEHICLE_ENGINE_ON(jet, true, true, true)
                ENTITY.SET_ENTITY_INVINCIBLE(jet, true)
                VEHICLE.SET_PLANE_TURBULENCE_MULTIPLIER(jet, 0.0)
                setVehicleCamDistance(jet, -20.0)

                object = entities.create_object(objHash, pos)
                ENTITY.ATTACH_ENTITY_TO_ENTITY(object, jet, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, true, false, false, 0, true)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(jet, pos.x, pos.y, pos.z + 200, false, false, true)
                PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), jet, -1)

                CAM.DESTROY_ALL_CAMS(true)
                cam = CAM.CREATE_CAM("DEFAULT_SCRIPTED_CAMERA", false)
                _ATTACH_CAM_TO_ENTITY_WITH_FIXED_DIRECTION(cam, jet, -89.0, 0.0, 0.0, 0.0, 0.0, -4.0, true)
                CAM.SET_CAM_FOV(cam, camFov)
                CAM.SET_CAM_ACTIVE(cam, true)
                GRAPHICS.SET_SCRIPT_GFX_DRAW_ORDER(1)

                AUDIO.REQUEST_SCRIPT_AUDIO_BANK("DLC_CHRISTMAS2017/XM_ION_CANNON", false, -1)
                AUDIO.SET_AUDIO_FLAG("DisableFlightMusic", true)
                if not GRAPHICS.HAS_SCALEFORM_MOVIE_LOADED(scaleform) then
                    scaleform = GRAPHICS.REQUEST_SCALEFORM_MOVIE("ORBITAL_CANNON_CAM")
                    repeat
                        util.yield()
                    until GRAPHICS.HAS_SCALEFORM_MOVIE_LOADED(scaleform)
                end
                fadingTimer.reset()
            elseif fadingTimer.elapsed() > 1200 then
                state = UfoState.onFlight
                CAM.DO_SCREEN_FADE_IN(800)
            end
        end
    elseif state == UfoState.onFlight then
        if ENTITY.IS_ENTITY_VISIBLE(jet) then ENTITY.SET_ENTITY_VISIBLE(jet, false, 0) end
        PAD.DISABLE_CONTROL_ACTION(2, 75, true) -- INPUT_VEH_EXIT
		PAD.DISABLE_CONTROL_ACTION(2, 80, true) -- INPUT_VEH_CIN_CAM
		PAD.DISABLE_CONTROL_ACTION(2, 99, true) -- INPUT_VEH_SELECT_NEXT_WEAPON

        VEHICLE.DISABLE_VEHICLE_WEAPON(true, util.joaat("vehicle_weapon_player_lazer"), jet, PLAYER.PLAYER_PED_ID())
		VEHICLE.DISABLE_VEHICLE_WEAPON(true, util.joaat("vehicle_weapon_space_rocket"), jet, PLAYER.PLAYER_PED_ID())
        CAM._DISABLE_VEHICLE_FIRST_PERSON_CAM_THIS_FRAME()

		if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(2, 75) or get_vehicle_player_is_in(PLAYER.PLAYER_ID()) ~= jet then
            CAM.DO_SCREEN_FADE_OUT(500)
		end
        if CAM.IS_SCREEN_FADED_OUT() then
            state = UfoState.beingDestroyed
        end
		if PAD.IS_CONTROL_JUST_PRESSED(2, 80) or PAD.IS_CONTROL_JUST_PRESSED(2, 45) then
            if isCannonActive then
                cameraRot = v3.new(-89.0, 0.0, 0.0)
                _ATTACH_CAM_TO_ENTITY_WITH_FIXED_DIRECTION (cam, jet, -89.0, 0.0, 0.0, 0.0, 0.0, -4.0, true)
            end
            AUDIO.PLAY_SOUND_FRONTEND(-1, "cannon_active", "dlc_xm_orbital_cannon_sounds", true);
            zoom = 0.0
            CAM.SET_CAM_FOV(cam, maxFov)
			isCannonActive = not isCannonActive
            STREAMING.CLEAR_FOCUS()
            HUD.UNLOCK_MINIMAP_ANGLE()
		end

        tractorBeam()
        drawSpriteOnPlayers()
        renderCannonCam()
        drawInstructionalButtons()
        EnableOTR()
        DisablePhone()
    elseif state == UfoState.beingDestroyed then
        sound.zoomOut:stop()
        sound.backgroundLoop:stop()
        sound.fireLoop:stop()
        sound.panLoop:stop()

        STREAMING.CLEAR_FOCUS()
        AUDIO.STOP_AUDIO_SCENE("DLC_BTL_Hacker_Drone_HUD_Scene")
	    AUDIO.RELEASE_NAMED_SCRIPT_AUDIO_BANK("DLC_CHRISTMAS2017/XM_ION_CANNON")

        local pScaleform = memory.alloc_int()
        memory.write_int(pScaleform, scaleform)
        GRAPHICS.SET_SCALEFORM_MOVIE_AS_NO_LONGER_NEEDED(pScaleform)
        scaleform = 0

        if ENTITY.DOES_ENTITY_EXIST(jet) then
            setVehicleCamDistance(jet, -1.57)
        end
        entities.delete_by_handle(jet); jet = 0
	    entities.delete_by_handle(object); object = 0

        local outCoords = v3.new()
	    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
	    PATHFIND.GET_CLOSEST_VEHICLE_NODE(pos.x, pos.y, pos.z, outCoords, 1, 100, 2.5)
        ENTITY.SET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), outCoords.x, outCoords.y, outCoords.z, false, false, false)
        ENTITY.SET_ENTITY_VISIBLE(PLAYER.PLAYER_PED_ID(), true, 0)
	    PED.REMOVE_PED_HELMET(PLAYER.PLAYER_PED_ID(), true)
        DisableOTR()

        CAM.SET_CAM_ACTIVE(cam, false)
	    CAM.RENDER_SCRIPT_CAMS(false, false, 0, true, false, 0)
	    CAM.DESTROY_CAM(cam, false)
        HUD.UNLOCK_MINIMAP_ANGLE()
        targetVehicles = {}
        isCannonActive = false
        if CAM.IS_SCREEN_FADED_OUT() then
            fadingTimer.reset()
            state = UfoState.fadingIn
        end
    elseif state == UfoState.fadingIn then
        if fadingTimer.elapsed() > 1200 then
            CAM.DO_SCREEN_FADE_IN(500)
            state = UfoState.nonExistent
        end
    end
end


self.onStop = function ()
    if self.exists() and get_vehicle_player_is_in(PLAYER.PLAYER_ID()) == jet then
        if CAM.IS_SCREEN_FADED_OUT() then
            CAM.DO_SCREEN_FADE_IN(0)
        end
        state = UfoState.beingDestroyed
        self.mainLoop()
    end
end

return self
