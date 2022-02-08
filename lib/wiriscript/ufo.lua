--[[
--------------------------------
THIS FILE IS PART OF WIRISCRIPT
        Nowiry#2663
--------------------------------
]]

util.require_natives(1640181023)
require "wiriscript.functions"

local self = {}
local state = -1
local vehicle_hash = joaat("hydra")
local object_hash = joaat("imp_prop_ship_01a")
local jet
local object
local cam
local fov = 110
local zoom = 0.0
local lastzoom
local charge = 0.0
local countdown = 3
local counting
local attracted = {}
local sTime
local cam_rot = vect.new(-89.0, 0.0, 0.0)
local cannon = false
local sId = {
    zoom_out = -1,
    fire_charge = -1
}
local veh_cam_dist
local scaleform = GRAPHICS.REQUEST_SCALEFORM_MOVIE("ORBITAL_CANNON_CAM")
local effect = {asset = "scr_xm_orbital", name = "scr_xm_orbital_blast"}
local sphere_colour = Colour.New(0, 255, 255)


self.set_state = function (bool)
    if bool then
        if state == -1 then
            state = 0
        end
    else
        if state ~= -1 then
            state = 2
        end
    end
end


self.get_state = function ()
    return state
end


local function currect_heading(value)
    if value < 0 then
        value = value + 360
    end
    return value
end


local function draw_instructional_buttons()
    if cannon then
        if instructional:begin() then
            add_control_instructional_button(75, "BB_LC_EXIT")
            add_control_instructional_button(80, "Disable Cannon")

            if PAD._IS_USING_KEYBOARD(0) then
                add_control_group_instructional_button(29, "ORB_CAN_ZOOM")
            end

            add_control_group_instructional_button(21, "HUD_INPUT101")
            add_control_instructional_button(69, "ORB_CAN_FIRE")
            instructional:set_background_colour(0, 0, 0, 80)
            instructional:draw()
        end
    else
        if instructional:begin() then
            add_control_instructional_button(75, "BB_LC_EXIT")
            add_control_instructional_button(119, "Vertical flight")
            add_control_instructional_button(80, "Cannon")

            if #attracted > 0 then
                add_control_instructional_button(22, "Release vehicles")
            end

            if #attracted < 15 then
                add_control_instructional_button(73, "Tractor beam")
            end

            instructional:set_background_colour(0, 0, 0, 80)
            instructional:draw()
        end
    end
end


local tractor_beam = function ()
    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(jet, 0.0, 0.0, -10.0)
    if not cannon then
        local colour = Colour.Rainbow(sphere_colour)
        GRAPHICS._DRAW_SPHERE(pos.x, pos.y, pos.z, 1.0, colour.r, colour.g, colour.b, colour.a)
    end
    
    if PAD.IS_CONTROL_JUST_PRESSED(2, 73) then
        for _, vehicle in ipairs(entities.get_all_vehicles_as_handles()) do
            local groundz = GET_GROUND_Z_FOR_3D_COORD(pos)
            local on_ground_coord = vect.new(pos.x, pos.y, groundz)
            local veh_pos = ENTITY.GET_ENTITY_COORDS(vehicle)
            if vect.dist(on_ground_coord, veh_pos) < 80 and vehicle ~= jet and #attracted < 15 then
                insert_once(attracted, vehicle)
            end 
        end
    end
    
    for _, vehicle in ipairs(attracted) do
        local veh_pos = ENTITY.GET_ENTITY_COORDS(vehicle)
        if REQUEST_CONTROL(vehicle) then
            local norm = vect.norm(vect.subtract(pos, veh_pos))
            local x = vect.dist(pos, veh_pos)
            local mult = 110 * (1 - 2^(-x))
            local vel = vect.mult(norm, mult)
            ENTITY.SET_ENTITY_VELOCITY(vehicle, vel.x, vel.y, vel.z)
        end
    end
    
    if PAD.IS_CONTROL_JUST_PRESSED(2, 22) then 
        attracted = {} 
    end
end


local draw_boxes_on_players = function ()
    if config.general.disablelockon then
        return 
    end
    for _, player in pairs(players.list(false)) do
        if ENTITY.IS_ENTITY_ON_SCREEN(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player)) and not players.is_in_interior(player) then
            local colour = Colour.New(0, 255, 255)
            if IS_PLAYER_FRIEND(player) then colour = Colour.New(128, 255, 0) end
            DRAW_LOCKON_SPRITE_ON_PLAYER(player, colour)
        end
    end
end


local set_cannon_cam_zoom_level = function ()
    local increasing
    local decreasing 

    if PAD._IS_USING_KEYBOARD(2) then
        if PAD.IS_CONTROL_JUST_PRESSED(2, 241) then
            increasing = true
        end
        if PAD.IS_CONTROL_JUST_PRESSED(2, 242) then
            decreasing = true
        end
    end

    if increasing then
        if zoom < 1.0 then
            zoom = zoom + 0.25
        end
    elseif decreasing then
        if zoom > 0.0 then
            zoom = zoom - 0.25
        end
    end

    local fov_limit = 25 + 85 * (1.0 - zoom)
    fov = incr(fov, 0.5, fov_limit)

    if zoom ~= lastzoom then
        if AUDIO.HAS_SOUND_FINISHED(sId.zoom_out) then
            sId.zoom_out = AUDIO.GET_SOUND_ID()
            AUDIO.PLAY_SOUND_FRONTEND(sId.zoom_out, "zoom_out_loop", "dlc_xm_orbital_cannon_sounds", true)
        end

        GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SET_ZOOM_LEVEL")
        GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(zoom)
        GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
        lastzoom = zoom
    end

    if fov ~= fov_limit then
        CAM.SET_CAM_FOV(cam, fov)
    elseif not AUDIO.HAS_SOUND_FINISHED(sId.zoom_out) then
        AUDIO.STOP_SOUND(sId.zoom_out)
		AUDIO.RELEASE_SOUND_ID(sId.zoom_out)
        sId.zoom_out = -1
    end
end


local function set_cannon_cam_rot()
    local mult = 1.0
    local axis_x = PAD.GET_CONTROL_UNBOUND_NORMAL(2, 220)
    local axis_y = PAD.GET_CONTROL_UNBOUND_NORMAL(2, 221)
    local pitch
    local roll
    local heading
    local frame_time = 30 * MISC.GET_FRAME_TIME()

    if PAD._IS_USING_KEYBOARD(0) then
		mult = 3.0
		axis_x = axis_x * mult
		axis_y = axis_y * mult
	end
    
    if PAD.IS_LOOK_INVERTED() then
        axis_y = - axis_y
    end

    if axis_x ~= 0 or axis_y ~= 0 then
        heading  = -(axis_x * 0.05) * frame_time * 25
        pitch    = -(axis_y * 0.05) * frame_time * 25
        cam_rot = vect.add(vect.new(pitch, 0, heading), cam_rot)

        if cam_rot.x > -45.0 then
            cam_rot.x = -45.0
        elseif cam_rot.x < -89.0 then
            cam_rot.x = -89.0
        end

        ATTACH_CAM_TO_ENTITY_WITH_FIXED_DIRECTION(cam, jet, cam_rot.x, 0.0, cam_rot.z, 0.0, 0.0, -4.0, true)
    end
    local heading = currect_heading(CAM.GET_CAM_ROT(cam, 2).z) 
    HUD.LOCK_MINIMAP_ANGLE(round( heading ))
    HUD.SET_RADAR_ZOOM_PRECISE(0.0)
end


local render_cannon_cam = function ()
    if not cannon then
        CAM.RENDER_SCRIPT_CAMS(false, false, 3000, true, false, 0)
        return
    end
    CAM.RENDER_SCRIPT_CAMS(true, false, 3000, true, false, 0)
    PAD.DISABLE_CONTROL_ACTION(2, 85, true)   -- INPUT_VEH_RADIO_WHEEL
    PAD.DISABLE_CONTROL_ACTION(2, 122, true)  -- INPUT_VEH_FLY_MOUSE_CONTROL_OVERRIDE

    set_cannon_cam_zoom_level()
    set_cannon_cam_rot()

    GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SET_STATE")
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(3)
	GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

    GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SET_CHARGING_LEVEL")
	GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(charge)
	GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

    if PAD.IS_CONTROL_PRESSED(2, 69) then
        local hit, pos, normal, ent = RAYCAST(cam, 1000)
        if hit == 1 then
            STREAMING.SET_FOCUS_POS_AND_VEL(pos.x, pos.y, pos.z, 0.0, 0.0, 0.0)
        end
        if charge == 1.0 then
            if not counting then
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

                if AUDIO.HAS_SOUND_FINISHED(sId.fire_charge) then
                    sId.fire_charge = AUDIO.GET_SOUND_ID()
                    AUDIO.PLAY_SOUND_FRONTEND(sId.fire_charge, "cannon_charge_fire_loop", "dlc_xm_orbital_cannon_sounds", true)
                end
            else
                charge = 0.0
                countdown = 3
                counting = false
                
                local rot = GET_ROTATION_FROM_DIRECTION(normal)
                REQUEST_PTFX_ASSET(effect.asset)
                FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, 59, 1.0, true, false, 1.0)
                GRAPHICS.USE_PARTICLE_FX_ASSET(effect.asset)
                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD(
					effect.name, 
					pos.x, 
                    pos.y, 
                    pos.z, 
					rot.x - 90, 
                    rot.y, 
                    rot.z, 
					1.0, 
					false, false, false, true
				)
                AUDIO.PLAY_SOUND_FROM_COORD(-1, "DLC_XM_Explosions_Orbital_Cannon", pos.x, pos.y, pos.z, 0, true, 0, false)
                CAM.SHAKE_CAM(cam, "GAMEPLAY_EXPLOSION_SHAKE", 1.5)
            end
        else -- recharging
            charge = incr(charge, 0.015, 1.0)
            counting = false
        end
    elseif charge ~= 1.0 or counting then
        charge = incr(charge, 0.015, 1.0)
		counting = false
		countdown = 3
    end

    if charge ~= 1.0 and not AUDIO.HAS_SOUND_FINISHED(sId.fire_charge) then
        AUDIO.STOP_SOUND(sId.fire_charge)
        AUDIO.RELEASE_SOUND_ID(sId.fire_charge)
        sId.fire_charge = -1
    end

    STREAMING.CLEAR_FOCUS()
    GRAPHICS.DRAW_SCALEFORM_MOVIE_FULLSCREEN(scaleform, 255, 255, 255, 255, 0)
end


self.main_loop = function ()
    if state == 0 then
        CAM.DO_SCREEN_FADE_OUT(500)
		wait(600)
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
		REQUEST_MODELS(vehicle_hash, object_hash)
		jet = entities.create_vehicle(vehicle_hash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
		ENTITY.SET_ENTITY_VISIBLE(jet, false, 0)
		VEHICLE.SET_VEHICLE_ENGINE_ON(jet, true, true, true)
		VEHICLE._SET_VEHICLE_JET_ENGINE_ON(jet, true)
		ENTITY.SET_ENTITY_INVINCIBLE(jet, true)
		VEHICLE.SET_PLANE_TURBULENCE_MULTIPLIER(jet, 0.0)
		veh_cam_dist = memory.read_long(entities.handle_to_pointer(jet) + 0x20) + 0x38
		if veh_cam_dist ~= NULL then
            memory.write_float(veh_cam_dist, - 20.0)
        end
		
		object = entities.create_object(object_hash, pos)
		ENTITY.ATTACH_ENTITY_TO_ENTITY(object, jet, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, true, true, false, 0, true)
		
        CAM.DESTROY_ALL_CAMS(true)
		cam = CAM.CREATE_CAM("DEFAULT_SCRIPTED_CAMERA", false)
        ATTACH_CAM_TO_ENTITY_WITH_FIXED_DIRECTION (cam, jet, -89.0, 0.0, 0.0, 0.0, 0.0, -4.0, true)
        CAM.SET_CAM_FOV(cam, fov)
		CAM.SET_CAM_ACTIVE(cam, true)
		GRAPHICS.SET_SCRIPT_GFX_DRAW_ORDER(1)
		
        AUDIO.REQUEST_SCRIPT_AUDIO_BANK("DLC_CHRISTMAS2017/XM_ION_CANNON", false, -1)

        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(jet, pos.x, pos.y, pos.z + 200, false, false, true)
        PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), jet, -1)
        wait(600)
		CAM.DO_SCREEN_FADE_IN(500)

        state = 1
    elseif state == 1 then
        PAD.DISABLE_CONTROL_ACTION(2, 75, true) -- INPUT_VEH_EXIT
		PAD.DISABLE_CONTROL_ACTION(2, 80, true) -- INPUT_VEH_CIN_CAM
		PAD.DISABLE_CONTROL_ACTION(2, 99, true) -- INPUT_VEH_SELECT_NEXT_WEAPON

        VEHICLE.DISABLE_VEHICLE_WEAPON(true, - 123497569, jet, PLAYER.PLAYER_PED_ID())
		VEHICLE.DISABLE_VEHICLE_WEAPON(true, - 494786007, jet, PLAYER.PLAYER_PED_ID())	
        CAM._DISABLE_VEHICLE_FIRST_PERSON_CAM_THIS_FRAME()
		
		if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(2, 75) or PAD.IS_DISABLED_CONTROL_PRESSED(2, 75) then
			state = 2
		end

        if GET_VEHICLE_PLAYER_IS_IN(PLAYER.PLAYER_ID()) ~= jet then
            state = 2
        end
		
		if PAD.IS_CONTROL_JUST_PRESSED(2, 80) or PAD.IS_CONTROL_JUST_PRESSED(2, 45) then
			AUDIO.PLAY_SOUND_FRONTEND(-1, "cannon_active", "dlc_xm_orbital_cannon_sounds", true)
            zoom = 0.0
			cannon = not cannon
            STREAMING.CLEAR_FOCUS()
            HUD.UNLOCK_MINIMAP_ANGLE()
            if cannon then
                cam_rot = vect.new(-89.0, 0.0, 0.0)
                ATTACH_CAM_TO_ENTITY_WITH_FIXED_DIRECTION (cam, jet, -89.0, 0.0, 0.0, 0.0, 0.0, -4.0, true)
            end
		end

        toggle_off_radar(true)
        tractor_beam()
        draw_boxes_on_players()
        render_cannon_cam()
        draw_instructional_buttons()
    elseif state == 2 then
        CAM.DO_SCREEN_FADE_OUT(500)
	    wait(600)
        
        state = 3
    elseif state == 3 then
	    local ptr1 = alloc()
	    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
	    if veh_cam_dist ~= NULL then 
            memory.write_float(veh_cam_dist, -1.57) 
        end
	    if not AUDIO.HAS_SOUND_FINISHED(sId.zoom_out) then
            AUDIO.STOP_SOUND(sId.zoom_out)
            AUDIO.RELEASE_SOUND_ID(sId.zoom_out)
        end
        STREAMING.CLEAR_FOCUS()
	    AUDIO.RELEASE_NAMED_SCRIPT_AUDIO_BANK("DLC_CHRISTMAS2017/XM_ION_CANNON")
	    entities.delete_by_handle(jet)
	    entities.delete_by_handle(object)
	    PATHFIND.GET_CLOSEST_VEHICLE_NODE(pos.x, pos.y, pos.z, ptr1, 1, 100, 2.5)
	    pos = memory.read_vector3(ptr1); memory.free(ptr1)
	    ENTITY.SET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), pos.x, pos.y, pos.z, false, false, false)
	    ENTITY.SET_ENTITY_VISIBLE(PLAYER.PLAYER_PED_ID(), true, 0)
	    PED.REMOVE_PED_HELMET(PLAYER.PLAYER_PED_ID(), true)
	    CAM.SET_CAM_ACTIVE(cam, false)
	    CAM.RENDER_SCRIPT_CAMS(false, false, 3000, true, false, 0)
	    CAM.DESTROY_CAM(cam, false)
        HUD.UNLOCK_MINIMAP_ANGLE()
        toggle_off_radar(false)

        state = 4
    elseif state == 4 then
	    wait(600)
	    CAM.DO_SCREEN_FADE_IN(500)

        state = -1
    end
end

self.on_stop = function ()
    if state ~= -1 and GET_VEHICLE_PLAYER_IS_IN(PLAYER.PLAYER_ID()) == jet then
        state = 3
        self.main_loop()
    end
end

return self
