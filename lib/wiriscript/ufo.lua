--[[
--------------------------------
THIS FILE IS PART OF WIRISCRIPT
         Nowiry#2663
--------------------------------
]]

require "wiriscript.functions"

local self = {}
local UfoState = 
{
    nonExistent = -1,
    beingCreated = 0,
    onFlight = 1,
    fadingOut = 2,
    beingDestroyed = 3,
    fadingIn = 4,
}
local state = UfoState.nonExistent
local vehicleHash = util.joaat("hydra")
local objHash = util.joaat("imp_prop_ship_01a")
local jet
local object
local cam
local fov = 110
local zoom = 0.0
local lastZoom
local charge = 0.0
local countdown = 3
local counting
local attracted = {}
local sTime
local cameraRot = vect.new(-89.0, 0.0, 0.0)
local cannon = false
local scaleform = GRAPHICS.REQUEST_SCALEFORM_MOVIE("ORBITAL_CANNON_CAM")
local sphereColour = Colour.new(0, 255, 255, 255)
local sound = 
{
    zoomOut         = Sound.new("zoom_out_loop", "dlc_xm_orbital_cannon_sounds"),
    fireLoop        = Sound.new("cannon_charge_fire_loop", "dlc_xm_orbital_cannon_sounds"),
    backgroundLoop  = Sound.new("background_loop", "dlc_xm_orbital_cannon_sounds"),
    panLoop         = Sound.new("pan_loop", "dlc_xm_orbital_cannon_sounds")
}

self.exists = function ()
    return state ~= UfoState.nonExistent
end

self.create = function ()
    state = UfoState.beingCreated
end

self.destroy = function ()
    state = UfoState.beingDestroyed
end


local function currect_heading(value)
    if value < 0 then
        value = value + 360
    end
    return value
end


local function draw_instructional_buttons()
    if instructional:begin() then
        instructional.add_control(75, "BB_LC_EXIT")
        if cannon then
            instructional.add_control(80, "Disable Cannon")
            
            if PAD._IS_USING_KEYBOARD(0) then
                instructional.add_control_group(29, "ORB_CAN_ZOOM")
            end

            instructional.add_control_group(21, "HUD_INPUT101")
            instructional.add_control(69, "ORB_CAN_FIRE")
        else
            instructional.add_control(119, "Vertical flight")
            instructional.add_control(80, "Cannon")

            if #attracted > 0 then
                instructional.add_control(22, "Release vehicles")
            end

            if #attracted < 15 then
                instructional.add_control(73, "Tractor beam")
            end
        end
        instructional.add_control(69, "ORB_CAN_FIRE")
        instructional:set_background_colour(0, 0, 0, 80)
        instructional:draw()
    end
end


local --[[CPed*]] getVehicleDriver = function (--[[CAutomobile*]] vehicle)
    return  memory.read_long(vehicle + 0x0C68)
end

local isPedPlayer = function (--[[CPed*]] ped)
    return memory.read_long(ped + 0x10C8) ~= 0 
end


local tractor_beam = function ()
    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(jet, 0.0, 0.0, -10.0)
    if not cannon then
        Colour.rainbow(sphereColour)
        GRAPHICS._DRAW_SPHERE(pos.x, pos.y, pos.z, 1.0, sphereColour.r, sphereColour.g, sphereColour.b, 255)
    end
    
    if PAD.IS_CONTROL_JUST_PRESSED(2, 73) then
        local groundZ = getGroundZ(pos)
        local onGroundCoord = vect.new(pos.x, pos.y, groundZ)
        for _, vehicle in ipairs(entities.get_all_vehicles_as_handles()) do
            local vehiclePos = ENTITY.GET_ENTITY_COORDS(vehicle)
            if #attracted < 15 and vect.dist2(onGroundCoord, vehiclePos) < 6000.0 and vehicle ~= jet then
                if gConfig.ufo.targetplayer then  
                    -- target vehicles with player drivers              
                    local driver = getVehicleDriver(entities.handle_to_pointer(vehicle))
                    if driver == NULL then
                        goto continue
                    end
                    if isPedPlayer(driver) then
                        insertOnce(attracted, vehicle)
                    end
                else 
                    -- target all vehicles                    
                    insertOnce(attracted, vehicle)
                end                
            end
            ::continue::
        end
    end

    for _, vehicle in ipairs(attracted) do
        local vehiclePos = ENTITY.GET_ENTITY_COORDS(vehicle)
        if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(vehicle) then
            local norm = vect.norm(vect.subtract(pos, vehiclePos))
            local x = vect.dist(pos, vehiclePos)
            local mult = 110 * (1 - 2^(-x))
            local vel = vect.mult(norm, mult)
            ENTITY.SET_ENTITY_VELOCITY(vehicle, vel.x, vel.y, vel.z)
        else
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(vehicle)
        end
    end
    
    if PAD.IS_CONTROL_JUST_PRESSED(2, 22) then 
        attracted = {} 
    end
end


local draw_sprite_on_players = function ()
    if gConfig.ufo.disableboxes then
        return 
    end
    for _, player in pairs(players.list(false)) do
        if ENTITY.IS_ENTITY_ON_SCREEN(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player)) and not players.is_in_interior(player) then
            local hudColour = isPlayerFriend(player) and HudColour.friendly or HudColour.red
            local playerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player)
            drawLockonSprite(playerPed, hudColour)
        end
    end
end


local set_cannon_cam_zoom = function ()
    if not PAD._IS_USING_KEYBOARD(2) then
        return
    end
    if PAD.IS_CONTROL_JUST_PRESSED(2, 241) then
        if zoom < 1.0 then
            zoom = zoom + 0.25
        end
    end
    if PAD.IS_CONTROL_JUST_PRESSED(2, 242) then
        if zoom > 0.0 then
            zoom = zoom - 0.25
        end
    end

    local fovLimit = 25 + 85 * (1.0 - zoom)
    fov = increment(fov, 1.0, fovLimit)		
    if zoom ~= lastZoom then
        sound.zoomOut:play()
    
        GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SET_ZOOM_LEVEL")
        GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(zoom)
        GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
        lastZoom = zoom
    end

    if fov ~= fovLimit then
        CAM.SET_CAM_FOV(cam, fov)
    else
        sound.zoomOut:stop()
    end
end


local function set_cannon_cam_rot()
    local mult = 1.0
    local axisX = PAD.GET_CONTROL_UNBOUND_NORMAL(2, 220)
    local axisY = PAD.GET_CONTROL_UNBOUND_NORMAL(2, 221)
    local pitch
    local roll
    local heading
    local frameTime = 30 * MISC.GET_FRAME_TIME()
    local maxRotX = -25.0
    local minRotX = -89.0

    if PAD._IS_USING_KEYBOARD(0) then
		mult = 3.0
		axisX = axisX * mult
		axisY = axisY * mult
	end
    
    if PAD.IS_LOOK_INVERTED() then
        axisY = -axisY
    end

    if axisX ~= 0 or axisY ~= 0 then
        heading  = -(axisX * 0.05) * frameTime * 25
        pitch    = -(axisY * 0.05) * frameTime * 25
        cameraRot  = vect.add(vect.new(pitch, 0, heading), cameraRot)

        if cameraRot.x > maxRotX then
            cameraRot.x = maxRotX
        elseif cameraRot.x < minRotX then
            cameraRot.x = minRotX
        end
        sound.panLoop:play()
        ATTACH_CAM_TO_ENTITY_WITH_FIXED_DIRECTION(cam, jet, cameraRot.x, 0.0, cameraRot.z, 0.0, 0.0, -4.0, true)
    else
        sound.panLoop:stop()
    end
    local heading = currect_heading(CAM.GET_CAM_ROT(cam, 2).z) 
    HUD.LOCK_MINIMAP_ANGLE(round( heading ))
end


local function recharge_cannon()
    charge = increment(charge, 0.015, 1.0)
end


local render_cannon_cam = function ()
    if not cannon then
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

    PAD.DISABLE_CONTROL_ACTION(2, 85, true)   -- INPUT_VEH_RADIO_WHEEL
    PAD.DISABLE_CONTROL_ACTION(2, 122, true)  -- INPUT_VEH_FLY_MOUSE_CONTROL_OVERRIDE
   
    disablePhone()
    set_cannon_cam_zoom()
    set_cannon_cam_rot()

    GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SET_STATE")
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(3)
	GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

    GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SET_CHARGING_LEVEL")
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(charge)
	GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

    if PAD.IS_CONTROL_PRESSED(2, 69) then
        local raycastResult = getRaycastResult(1000.0)
        local pos = raycastResult.endCoords
        if raycastResult.didHit then            
            STREAMING.SET_FOCUS_POS_AND_VEL(pos.x, pos.y, pos.z, 0.0, 0.0, 0.0)
        end
        if charge == 1.0 then
            if not counting then
                sound.fireLoop:play()
                sTime = cTime()
                counting = true
            end
            if countdown ~= 0 then
                if (cTime() - sTime) >= 1000 then
                    countdown = countdown - 1
                    sTime = cTime()
                end

                GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SET_COUNTDOWN")
				GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(countdown)
				GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
            else
                charge = 0.0
                countdown = 3
                counting = false

                local rot = toRotation(raycastResult.surfaceNormal)
                local effect = Effect.new("scr_xm_orbital", "scr_xm_orbital_blast")
                requestPtfxAsset(effect.asset)
                FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, 59, 1.0, true, false, 1.0)
                GRAPHICS.USE_PARTICLE_FX_ASSET(effect.asset)
                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD(
					effect.name, 
					pos.x, 
                    pos.y, 
                    pos.z, 
					rot.x - 90.0, -- to make the effect rotation relative 
                    rot.y, 
                    rot.z, 
					1.0,
					false, false, false, true
				)

                AUDIO.PLAY_SOUND_FROM_COORD(-1, "DLC_XM_Explosions_Orbital_Cannon", pos.x, pos.y, pos.z, 0, true, 0, false)
                CAM.SHAKE_CAM(cam, "GAMEPLAY_EXPLOSION_SHAKE", 1.5)
            end
        else
            recharge_cannon()
            sound.fireLoop:stop()
            counting = false
        end
    elseif charge ~= 1.0 or counting then
        recharge_cannon()
        AUDIO.SET_VARIABLE_ON_SOUND(sound.fireLoop.Id, "Firing", 0.0)
        sound.fireLoop:stop()
		counting = false
		countdown = 3
    end

    if not AUDIO.IS_AUDIO_SCENE_ACTIVE("DLC_BTL_Hacker_Drone_HUD_Scene") then
        AUDIO.START_AUDIO_SCENE("DLC_BTL_Hacker_Drone_HUD_Scene")
    end
    sound.backgroundLoop:play()

    STREAMING.CLEAR_FOCUS()
    GRAPHICS.DRAW_SCALEFORM_MOVIE_FULLSCREEN(scaleform, 255, 255, 255, 255, 0)
end


local set_vehicle_cam_distance = function (--[[Vehicle]] vehicle, value)
    local addr = memory.read_long(entities.handle_to_pointer(vehicle) + 0x20) + 0x38
	if addr ~= NULL then
        memory.write_float(addr, value)
    end
end


self.main_loop = function ()
    if state == UfoState.beingCreated then
        CAM.DO_SCREEN_FADE_OUT(500)
		wait(600)
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
		requestModels(vehicleHash, objHash)
		jet = entities.create_vehicle(vehicleHash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
		ENTITY.SET_ENTITY_VISIBLE(jet, false, 0)
		VEHICLE.SET_VEHICLE_ENGINE_ON(jet, true, true, true)
		VEHICLE._SET_VEHICLE_JET_ENGINE_ON(jet, true)
		ENTITY.SET_ENTITY_INVINCIBLE(jet, true)
		VEHICLE.SET_PLANE_TURBULENCE_MULTIPLIER(jet, 0.0)
        set_vehicle_cam_distance(jet, -20)
		
		object = entities.create_object(objHash, pos)
		ENTITY.ATTACH_ENTITY_TO_ENTITY(object, jet, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, true, true, false, 0, true)
		
        CAM.DESTROY_ALL_CAMS(true)
		cam = CAM.CREATE_CAM("DEFAULT_SCRIPTED_CAMERA", false)
        ATTACH_CAM_TO_ENTITY_WITH_FIXED_DIRECTION (cam, jet, -89.0, 0.0, 0.0, 0.0, 0.0, -4.0, true)
        CAM.SET_CAM_FOV(cam, fov)
		CAM.SET_CAM_ACTIVE(cam, true)
		GRAPHICS.SET_SCRIPT_GFX_DRAW_ORDER(1)
		
        AUDIO.REQUEST_SCRIPT_AUDIO_BANK("DLC_CHRISTMAS2017/XM_ION_CANNON", false, -1)
        AUDIO.SET_AUDIO_FLAG("DisableFlightMusic", true);

        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(jet, pos.x, pos.y, pos.z + 200, false, false, true)
        PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), jet, -1)
        wait(600)
		CAM.DO_SCREEN_FADE_IN(500)

        state = UfoState.onFlight
    elseif state == UfoState.onFlight then
        PAD.DISABLE_CONTROL_ACTION(2, 75, true) -- INPUT_VEH_EXIT
		PAD.DISABLE_CONTROL_ACTION(2, 80, true) -- INPUT_VEH_CIN_CAM
		PAD.DISABLE_CONTROL_ACTION(2, 99, true) -- INPUT_VEH_SELECT_NEXT_WEAPON

        VEHICLE.DISABLE_VEHICLE_WEAPON(true, -123497569, jet, PLAYER.PLAYER_PED_ID())
		VEHICLE.DISABLE_VEHICLE_WEAPON(true, -494786007, jet, PLAYER.PLAYER_PED_ID())	
        CAM._DISABLE_VEHICLE_FIRST_PERSON_CAM_THIS_FRAME()
		
		if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(2, 75) or PAD.IS_DISABLED_CONTROL_PRESSED(2, 75) or
        getVehiclePlayerIsIn(PLAYER.PLAYER_ID()) ~= jet then
			state = UfoState.fadingOut
		end
		
		if PAD.IS_CONTROL_JUST_PRESSED(2, 80) or PAD.IS_CONTROL_JUST_PRESSED(2, 45) then
            AUDIO.PLAY_SOUND_FRONTEND(-1, "cannon_active", "dlc_xm_orbital_cannon_sounds", true);
            zoom = 0.0
			cannon = not cannon
            STREAMING.CLEAR_FOCUS()
            HUD.UNLOCK_MINIMAP_ANGLE()
            if cannon then
                cameraRot = vect.new(-89.0, 0.0, 0.0)
                ATTACH_CAM_TO_ENTITY_WITH_FIXED_DIRECTION (cam, jet, -89.0, 0.0, 0.0, 0.0, 0.0, -4.0, true)
            end
		end

        tractor_beam()
        draw_sprite_on_players()
        render_cannon_cam()
        draw_instructional_buttons()
        setOutOfRadar(true)
    elseif state == UfoState.fadingOut then
        CAM.DO_SCREEN_FADE_OUT(500)
	    wait(600)
        
        state = UfoState.beingDestroyed
    elseif state == UfoState.beingDestroyed then
        sound.zoomOut:stop()
        sound.backgroundLoop:stop()
        sound.fireLoop:stop()
        sound.panLoop:stop()

        STREAMING.CLEAR_FOCUS()
        AUDIO.STOP_AUDIO_SCENE("DLC_BTL_Hacker_Drone_HUD_Scene")
	    AUDIO.RELEASE_NAMED_SCRIPT_AUDIO_BANK("DLC_CHRISTMAS2017/XM_ION_CANNON")
	    
        set_vehicle_cam_distance(jet, -1.57)
        entities.delete_by_handle(jet)
	    entities.delete_by_handle(object)
        
        local outCoords = v3.new()
	    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
	    PATHFIND.GET_CLOSEST_VEHICLE_NODE(pos.x, pos.y, pos.z, outCoords, 1, 100, 2.5)
        ENTITY.SET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), v3.getX(outCoords), v3.getY(outCoords), v3.getZ(outCoords), false, false, false)
        ENTITY.SET_ENTITY_VISIBLE(PLAYER.PLAYER_PED_ID(), true, 0)
	    PED.REMOVE_PED_HELMET(PLAYER.PLAYER_PED_ID(), true)
        setOutOfRadar(false)
	    
        CAM.SET_CAM_ACTIVE(cam, false)
	    CAM.RENDER_SCRIPT_CAMS(false, false, 0, true, false, 0)
	    CAM.DESTROY_CAM(cam, false)
        HUD.UNLOCK_MINIMAP_ANGLE()    
        attracted = {}
    
        state = UfoState.fadingIn
    elseif state == UfoState.fadingIn then
	    wait(600)
	    CAM.DO_SCREEN_FADE_IN(500)

        state = UfoState.nonExistent
    end
end

self.on_stop = function ()
    if self.exists() and getVehiclePlayerIsIn(PLAYER.PLAYER_ID()) == jet then
        self.destroy()
        self.main_loop()
    end
end

return self
