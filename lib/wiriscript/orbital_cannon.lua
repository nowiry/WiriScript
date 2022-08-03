--[[
--------------------------------
THIS FILE IS PART OF WIRISCRIPT
         Nowiry#2663
--------------------------------
]]
---@diagnostic disable: exp-in-action, unknown-symbol, break-outside, miss-method, action-after-return
---@diagnostic disable
require "wiriscript.functions"


local self = {}
local version = 22
local targetId = -1
local cam = 0
local zoomLevel = 0.0
local scaleform = 0
local maxFov <const> = 110
local minFov <const> = 25
local camFov = maxFov
local zoomTimer <const> = newTimer()
local canZoom = false -- Used when not using keyboard
local State =
{
    NonExistent = -1,
    FadingOut = 0,
    CreatingCam = 1,
    LoadingScene = 2,
    FadingIn = 3,
    Spectating = 4,
    Shooting = 5,
    FadingOut2 = 6,
    Destroying = 7,
    FadingIn2 = 8
}
local sounds <const> = {
	zoomOut = Sound.new("zoom_out_loop", "dlc_xm_orbital_cannon_sounds"),
	activating = Sound.new("cannon_activating_loop", "dlc_xm_orbital_cannon_sounds"),
	backgroundLoop = Sound.new("background_loop", "dlc_xm_orbital_cannon_sounds"),
	fireLoop = Sound.new("cannon_charge_fire_loop", "dlc_xm_orbital_cannon_sounds")
}
local countdown = 3 -- `seconds`
local isCounting = false
local lastCountdown <const> = newTimer()
local state = State.NonExistent
local chargeLevel = 0.0
local timer <const> = newTimer()
local didShoot = false
local NULL <const> = 0
local becomeOrbitalCannon = menu.ref_by_path("Online>Become The Orbital Cannon", 38)
local orbitalBlast = Effect.new("scr_xm_orbital", "scr_xm_orbital_blast")
local newSceneStart = newTimer()
local chargeTimer = newTimer()

self.exists = function ()
    return state ~= State.NonExistent
end

self.getVersion = function ()
    return version
end

---@param playSound boolean
local DispatchZoomLevel = function (playSound)
    if playSound then sounds.zoomOut:play() end
    GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SET_ZOOM_LEVEL")
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(zoomLevel)
    GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
    zoomTimer.reset()
end


local SetCannonCamZoom = function ()
    local fovTarget = interpolate(maxFov, minFov, zoomLevel)
    local fov = CAM.GET_CAM_FOV(cam)
    if fovTarget ~= fov then
        camFov = interpolate(fov, fovTarget, zoomTimer.elapsed() / 200)
        CAM.SET_CAM_FOV(cam, camFov)
        return
    else
        sounds.zoomOut:stop()
    end

    if PAD._IS_USING_KEYBOARD(2) then
        if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(2, 241) and zoomLevel < 1.0 then
            zoomLevel = zoomLevel + 0.25
            DispatchZoomLevel(true)
        elseif PAD.IS_DISABLED_CONTROL_JUST_PRESSED(2, 242) and
        zoomLevel > 0.0 then
            zoomLevel = zoomLevel - 0.25
            DispatchZoomLevel(true)
        end
    elseif canZoom then
        local controlNormal = PAD.GET_CONTROL_NORMAL(2, 221)
        if controlNormal > 0.3 and canZoom and zoomLevel < 1.0 then
            zoomLevel = zoomLevel + 0.25
            DispatchZoomLevel(true)
            canZoom = false
        elseif controlNormal < -0.3 and canZoom and zoomLevel > 0.0 then
            zoomLevel = zoomLevel - 0.25
            DispatchZoomLevel(true)
            canZoom = false
        end
    elseif PAD.GET_CONTROL_NORMAL(2, 221) == 0 then
        canZoom = true
    end
end


---@param pos Vector3
---@param size number
---@param hudColour integer
local DrawLockonSprite = function (pos, size, hudColour)
    local colour = get_hud_colour(hudColour)
    local txdSizeX = 0.013
    local txdSizeY = 0.013 * GRAPHICS._GET_ASPECT_RATIO(false)
    GRAPHICS.SET_DRAW_ORIGIN(pos.x, pos.y, pos.z, 0)
    size = (size * 0.03)
    GRAPHICS.DRAW_SPRITE("helicopterhud", "hud_corner", -size * 0.5, -size, txdSizeX, txdSizeY, 0.0, colour.r, colour.g, colour.b, colour.a, true, 0)
    GRAPHICS.DRAW_SPRITE("helicopterhud", "hud_corner",  size * 0.5, -size, txdSizeX, txdSizeY, 90., colour.r, colour.g, colour.b, colour.a, true, 0)
    GRAPHICS.DRAW_SPRITE("helicopterhud", "hud_corner", -size * 0.5,  size, txdSizeX, txdSizeY, 270, colour.r, colour.g, colour.b, colour.a, true, 0)
    GRAPHICS.DRAW_SPRITE("helicopterhud", "hud_corner",  size * 0.5,  size, txdSizeX, txdSizeY, 180, colour.r, colour.g, colour.b, colour.a, true, 0)
    GRAPHICS.CLEAR_DRAW_ORIGIN()
end


local DisableControlActions = function ()
    PAD.DISABLE_CONTROL_ACTION(2, 142,true)
    PAD.DISABLE_CONTROL_ACTION(2, 141,true)
    PAD.DISABLE_CONTROL_ACTION(2, 140,true)
    PAD.DISABLE_CONTROL_ACTION(2, 24, true)
    PAD.DISABLE_CONTROL_ACTION(2, 84, true)
    PAD.DISABLE_CONTROL_ACTION(2, 85, true)
    PAD.DISABLE_CONTROL_ACTION(2, 263,true)
    PAD.DISABLE_CONTROL_ACTION(2, 264,true)
    PAD.DISABLE_CONTROL_ACTION(2, 143,true)
    PAD.DISABLE_CONTROL_ACTION(2, 200,true)
    PAD.DISABLE_CONTROL_ACTION(2, 257,true)
    HUD._HUD_WEAPON_WHEEL_IGNORE_CONTROL_INPUT()
end


---@param distance number
---@return integer
local GetArrowAlpha = function (distance)
    local alpha = 255
    local maxDistance = 2500
    local minDistance = 1000
    if distance > maxDistance then
        alpha = 0
    elseif distance < minDistance then
        alpha = 255
    else
        local perc = 1.0 - (distance - minDistance) / (maxDistance - minDistance)
        alpha = math.ceil(alpha * perc)
    end
    return alpha
end


---@param entity Entity
---@param hudColour HudColour
local DrawDirectionalArrowForEntity = function (entity, hudColour)
    local entPos = ENTITY.GET_ENTITY_COORDS(entity, false)
    local ptr = memory.alloc(4)
    if not GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(entPos.x, entPos.y, entPos.z, ptr, ptr) then
        local colour = get_hud_colour(hudColour)
        local camPos = CAM.GET_CAM_COORD(cam)
        local camRot = v3.new(-math.pi/2, 0, 0)
        local deltaXY = v3.new(entPos.x, entPos.y, 0.0)
        deltaXY:sub(v3.new(camPos.x, camPos.y, 0.0))
        local distanceXY = deltaXY:magnitude()
        local distanceZ = entPos.z - camPos.z

        local elevation
        if distanceZ > 0.0 then
            elevation = math.atan(distanceZ / distanceXY)
        else
            elevation = 0.0
        end

        local azimuth
        if deltaXY.y ~= 0.0 then
            azimuth = math.atan(deltaXY.x, deltaXY.y)
        elseif deltaXY.x < 0.0 then
            azimuth = -90.0
        else
            azimuth = 90.0
        end

        local angle = math.atan(
        math.cos(camRot.x) * math.sin(elevation) - math.sin(camRot.x) * math.cos(elevation) * math.cos(-azimuth - camRot.z),
        math.sin(-azimuth - camRot.z) * math.cos(elevation))
        local screenX = 0.5 - math.cos(angle) * 0.19
        local screenY = 0.5 - math.sin(angle) * 0.19
        local colourA = GetArrowAlpha(distanceXY)
        GRAPHICS.DRAW_SPRITE("helicopterhud", "hudArrow", screenX, screenY, 0.02, 0.04, math.deg(angle) - 90.0, colour.r, colour.g, colour.b, colourA, false, 0)
    end
end


local DrawMarkersOnPlayers = function ()
    for _, player in ipairs(players.list()) do
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player)
        if INTERIOR.GET_INTERIOR_FROM_ENTITY(ped) ~= 0 or player == targetId then
            continue
        end
        if GRAPHICS.HAS_STREAMED_TEXTURE_DICT_LOADED("helicopterhud") then
            local pos = ENTITY.GET_ENTITY_COORDS(ped, false)
            local txdScale = interpolate(1.0, 0.5, camFov / maxFov)
            DrawLockonSprite(pos, txdScale, HudColour.green)
            DrawDirectionalArrowForEntity(ped, HudColour.green)
        end
    end
end


Destroy = function ()
    sounds.backgroundLoop:stop()
    sounds.fireLoop:stop()
    sounds.zoomOut:stop()
    sounds.activating:stop()

    ENTITY.FREEZE_ENTITY_POSITION(players.user_ped(), false)
    PLAYER.DISABLE_PLAYER_FIRING(players.user_ped(), false)
    menu.set_value(becomeOrbitalCannon, false)

    GRAPHICS.ANIMPOSTFX_STOP("MP_OrbitalCannon")
    AUDIO.STOP_AUDIO_SCENE("dlc_xm_orbital_cannon_camera_active_scene")
    AUDIO.RELEASE_NAMED_SCRIPT_AUDIO_BANK("DLC_CHRISTMAS2017/XM_ION_CANNON")
    set_streamed_texture_dict_as_no_longer_needed("helicopterhud")

    CAM.RENDER_SCRIPT_CAMS(false, false, 0, true, false, 0)
    if  CAM.DOES_CAM_EXIST(cam) then
        CAM.SET_CAM_ACTIVE(cam, false)
        CAM.DESTROY_CAM(cam, false)
    end
    STREAMING.CLEAR_FOCUS()
    NETWORK.NETWORK_SET_IN_FREE_CAM_MODE(false)
    
    local pScaleform = memory.alloc_int()
    memory.write_int(pScaleform, scaleform)
    GRAPHICS.SET_SCALEFORM_MOVIE_AS_NO_LONGER_NEEDED(pScaleform)
    scaleform = 0

    zoomLevel = 0.0
    chargeLevel = 0.0
    didShoot = false
    targetId = -1
    camFov = maxFov
end


local DrawInstructionalButtons = function()
    if Instructional:begin() then
        Instructional.add_control(202, "HUD_INPUT3")
        if not  PAD._IS_USING_KEYBOARD(0) then
            Instructional.add_control(221, "ORB_CAN_ZOOM")
        else
            Instructional.add_control(242, "ORB_CAN_ZOOMO")
            Instructional.add_control(241, "ORB_CAN_ZOOMI")
        end
        Instructional.add_control(24, "ORB_CAN_FIRE")
        Instructional:set_background_colour(0, 0, 0, 80)
        Instructional:draw()
    end
end


---@param player Player
---@return boolean
local IsPlayerTargetable = function (player)
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player)
    if player ~= -1 and PLAYER.IS_PLAYER_PLAYING(player) and not is_player_passive(player) 
    and not INTERIOR.GET_INTERIOR_FROM_ENTITY(ped) == 0 then
        return true
    end
    return false
end


self.mainLoop = function ()
    if state ~= State.NonExistent and state < State.FadingOut2 and
    (util.is_session_transition_active() or not NETWORK.NETWORK_IS_PLAYER_CONNECTED(targetId)) then
        Destroy()
        state = State.NonExistent
    end

    if state == State.NonExistent then
        -- Do nothing
    elseif state == State.FadingOut then
        if not CAM.IS_SCREEN_FADED_OUT() then
            CAM.DO_SCREEN_FADE_OUT(800)
        else
            state = State.CreatingCam
        end

    elseif state == State.CreatingCam then
        ENTITY.FREEZE_ENTITY_POSITION(players.user_ped(), true)
        AUDIO.REQUEST_SCRIPT_AUDIO_BANK("DLC_CHRISTMAS2017/XM_ION_CANNON", false, -1)
        AUDIO.START_AUDIO_SCENE("dlc_xm_orbital_cannon_camera_active_scene")
        request_streamed_texture_dict("helicopterhud")

        local pos = players.get_position(targetId)
        sounds.activating:play()
        CAM.DESTROY_ALL_CAMS(true)
        cam = CAM.CREATE_CAM("DEFAULT_SCRIPTED_CAMERA", false)  
        CAM.SET_CAM_COORD(cam, pos.x, pos.y, pos.z)
        CAM.SET_CAM_ROT(cam, -90.0, 0.0, 0.0, 2)
        CAM.SET_CAM_FOV(cam, maxFov)
        CAM.SET_CAM_ACTIVE(cam, true)
        CAM.RENDER_SCRIPT_CAMS(true, false, 0, true, false, 0)

        GRAPHICS.ANIMPOSTFX_PLAY("MP_OrbitalCannon", 0, true)
        menu.set_value(becomeOrbitalCannon, true)
        DispatchZoomLevel(false)
        state = State.LoadingScene

    elseif state == State.LoadingScene then
        local pos = players.get_position(targetId)
        STREAMING.NEW_LOAD_SCENE_START_SPHERE(pos.x, pos.y, pos.z, 300.0, false)
        STREAMING.SET_FOCUS_POS_AND_VEL(pos.x, pos.y, pos.z, 5.0, 0.0, 0.0)
        NETWORK.NETWORK_SET_IN_FREE_CAM_MODE(true)
        timer.disable()
        newSceneStart.reset()
        state = State.FadingIn

    elseif state == State.FadingIn then
        if not timer.isEnabled() then
            if STREAMING.IS_NEW_LOAD_SCENE_LOADED() or newSceneStart.elapsed() > 10000 then
                STREAMING.NEW_LOAD_SCENE_STOP()
                timer.reset()
            end
        elseif timer.elapsed() > 2000 then
            CAM.DO_SCREEN_FADE_IN(500)
            sounds.backgroundLoop:play()
            sounds.activating:stop()
            AUDIO.PLAY_SOUND_FRONTEND(-1, "cannon_active", "dlc_xm_orbital_cannon_sounds", true)
            state = State.Spectating
        end

    elseif GRAPHICS.HAS_SCALEFORM_MOVIE_LOADED(scaleform) then
        local pos = players.get_position(targetId)
        STREAMING.SET_FOCUS_POS_AND_VEL(pos.x, pos.y, pos.z, 5.0, 0.0, 0.0)
        CAM.SET_CAM_COORD(cam, pos.x, pos.y, pos.z + 150.0)
        DrawMarkersOnPlayers()

        local myPos = players.get_position(players.user())
        STREAMING.REQUEST_COLLISION_AT_COORD(myPos.x, myPos.y, myPos.z)

        GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SET_STATE")
        GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(4)
        GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

        if state == State.Spectating then
            if not chargeTimer.isEnabled() then
                chargeTimer.reset()
            elseif chargeTimer.elapsed() < 3000 then
                chargeLevel = interpolate(0.0, 100.0, chargeTimer.elapsed() / 3000)
            else
                chargeLevel = 100.0
            end

            if PAD.IS_DISABLED_CONTROL_PRESSED(0, 69) and chargeLevel == 100.0 then
                if not isCounting then
                    PAD.SET_PAD_SHAKE(0, 1000, 50)
                    sounds.fireLoop:play()
                    isCounting = true
                    lastCountdown.reset()
                end

                if lastCountdown.elapsed() > 1000 and countdown > 0 then
                    countdown = countdown - 1
                    lastCountdown.reset()
                end

                GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SET_COUNTDOWN")
                GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(countdown)
                GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

            elseif isCounting and chargeLevel == 100.0 then
                AUDIO.SET_VARIABLE_ON_SOUND(sounds.fireLoop.Id, "Firing", 0.0)
                sounds.fireLoop:stop()
                countdown = 3
                isCounting = false
            end

            SetCannonCamZoom()
            if countdown == 0 then
                sounds.fireLoop:stop()
                timer.reset()
                state = State.Shooting
            end

            if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, 202) or not IsPlayerTargetable(targetId) then
                timer.reset()
                state = State.FadingOut2
            end

        elseif state == State.Shooting then
            if STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(orbitalBlast.asset) then
                chargeLevel = 0.0
                FIRE.ADD_OWNED_EXPLOSION(players.user_ped(), pos.x, pos.y, pos.z, 59, 1.0, true, false, 1.0)
                GRAPHICS.USE_PARTICLE_FX_ASSET(orbitalBlast.asset)
                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD(
                    orbitalBlast.name,
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
                -1, "DLC_XM_Explosions_Orbital_Cannon", pos.x, pos.y, pos.z, NULL, true, 0, false)
                CAM.SHAKE_CAM(cam, "GAMEPLAY_EXPLOSION_SHAKE", 1.5)
                PAD.SET_PAD_SHAKE(0, 500, 256)
                timer.reset()
                state = State.FadingOut2
                didShoot = true
            else
                STREAMING.REQUEST_NAMED_PTFX_ASSET(orbitalBlast.asset)
            end

        elseif state == State.FadingOut2 then
            if CAM.IS_SCREEN_FADED_OUT() then
                state = State.Destroying
            elseif not didShoot or timer.elapsed() > 1000 then
                CAM.DO_SCREEN_FADE_OUT(800)
            end
    
        elseif state == State.Destroying then
            Destroy()
            state = State.FadingIn2
            timer.reset()

        elseif state == State.FadingIn2 then
            if  CAM.IS_SCREEN_FADED_OUT() and timer.elapsed() > 2000 then
                CAM.DO_SCREEN_FADE_IN(500)
                STREAMING.CLEAR_FOCUS()
                state = State.NonExistent
            end
        end

        DisableControlActions()
        HUD.HIDE_HUD_AND_RADAR_THIS_FRAME()
        DrawInstructionalButtons()
        HudTimer.DisableThisFrame()
        DisablePhone()

        GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SET_CHARGING_LEVEL")
        GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(chargeLevel)
        GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

        GRAPHICS.SET_SCRIPT_GFX_DRAW_ORDER(0)
        GRAPHICS.DRAW_SCALEFORM_MOVIE_FULLSCREEN(scaleform, 255, 255, 255, 255, 0)
    else
        scaleform = GRAPHICS.REQUEST_SCALEFORM_MOVIE("ORBITAL_CANNON_CAM")
    end
    ---DEBUG
    draw_debug_text(self.getState())
end


self.destroy = function ()
    if not CAM.IS_SCREEN_FADED_IN() then CAM.DO_SCREEN_FADE_IN(0) end
    Destroy()
    state = State.NonExistent
end


---@param target Player
self.create = function (target)
    if target == targetId then
        return
    end
    targetId = target
    state = State.FadingOut
end


---DEBUG
self.getState = function ()
    pluto_switch state do
        case -1:
            return "NonExistent"
        case 0:
            return "FadingOut"
        case 1:
            return "CreatingCam"
        case 2:
            return "LoadingScene"
        case 3:
            return "FadingIn"
        case 4:
            return "Spectating"
        case 5:
            return "Shooting"
        case 6:
            return "FadingOut2"
        case 7:
            return "Destroying"
        case 8:
            return "FadingIn2"
    end
end

return self