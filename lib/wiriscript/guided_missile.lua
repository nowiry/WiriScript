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
local object
local camera
local blip
local scaleform
local start_pos
local sTime
local flash_rate = 0.0
local audio_reference = "DLC_Arena_Piloted_Missile_Sounds"
local ptfx_asset = "scr_xs_props"
local m_object_hash = joaat("xs_prop_arena_airmissile_01a")
local scaleform = GRAPHICS.REQUEST_SCALEFORM_MOVIE("SUBMARINE_MISSILES")
local effects = {
    missile_trail = -1
}
local sId = {
    startup = -1,
    out_of_bounds = -1,
    static_loop = -1,
    disconnect = -1
}


self.set_state = function (bool)
    if bool then
        if state == -1 then
            state = 0
        end
    elseif state ~= -1 then
        state = 2
    end
end


self.get_state = function ()
    return state
end


local function currect_heading(heading)
    if heading > 180.0 then
        return (heading - 180.0)
    end
    return (heading + 180.0)
end

local function currect_rot(value)
    if value > 180 then
        value = value - 360
    end
    if value < -180 then
        value = value + 360
    end
    return value
end


local function draw_intructional_buttons()
    if instructional:begin() then
        add_control_group_instructional_button(20, "DRONE_SPACE")
        add_control_group_instructional_button(21, "DRONE_POSITION")

        if not PAD._IS_USING_KEYBOARD(0) then
            add_control_instructional_button(208, "DRONE_SPEEDU")
            add_control_instructional_button(207, "DRONE_SLOWD")
        else
            add_control_instructional_button(209, "DRONE_SPEEDU")
            add_control_instructional_button(210, "DRONE_SLOWD")
        end

        add_control_instructional_button(75, "MOVE_DRONE_RE")
        instructional:set_background_colour(0, 0, 0, 80)
        instructional:draw()
    end
end


local function get_script_axes()
    local left_x  = PAD.GET_CONTROL_UNBOUND_NORMAL(2, 218)
	local left_y  = PAD.GET_CONTROL_UNBOUND_NORMAL(2, 219)
	local right_x = PAD.GET_CONTROL_UNBOUND_NORMAL(2, 220)
	local right_y = PAD.GET_CONTROL_UNBOUND_NORMAL(2, 221)
    return left_x, left_y, right_x, right_y
end


local function set_entity_rotation()
    local max = 40.0
    local mult = 1.0
    local axis_x = 0.0
    local axis_y = 0.0
    local pitch
    local roll
    local heading
    local frame_time = 30 * MISC.GET_FRAME_TIME()
    local ent_roll = ENTITY.GET_ENTITY_ROLL(object)
	local ent_pitch = ENTITY.GET_ENTITY_PITCH(object)
    local left_x, left_y, right_x, right_y = get_script_axes()

    if PAD._IS_USING_KEYBOARD(0) then
		mult = 3.0
		right_x = right_x * mult
		right_y = right_y * mult
	end
    
    if PAD.IS_LOOK_INVERTED() then
        right_y = - right_y
		left_y  = - left_y
    end

    if (right_x ~= 0 or right_y ~= 0) or (left_x ~= 0 or left_y ~= 0) then 
        if right_x ~= 0 then
            axis_x = right_x
        elseif left_x ~= 0 then
            axis_x = left_x
        else 
            axis_x = 0 
        end

        if right_y ~= 0 then
            axis_y = right_y
        elseif left_y ~= 0 then
            axis_y = left_y
        else 
            axis_y = 0 
        end

        local ent_rot = ENTITY.GET_ENTITY_ROTATION(object, 2)
        heading = -(axis_x * 0.05) * frame_time * 20
        pitch = (axis_y * 0.05) * frame_time * 20

        if (ent_roll ~= 0 or right_x ~= 0) or left_x ~= 0 then
            if right_x ~= 0 then
                axis_x = right_x
                roll = -(axis_x * 0.05) * frame_time * (max - 25.0)
            elseif left_x ~= 0 then
                axis_x = left_x
                roll = -(axis_x * 0.05) * frame_time * (max - 25.0)
            else
                if ent_rot.y ~= 0 then
                    if ent_rot.y < 0 then
                        axis_x = -1.0
                    else
                        axis_x = 1.0
                    end
                else 
                    axis_x = 0.0 
                end

                if ent_rot.y ~= 0 then
                    if ent_rot.y < 2.0 and ent_rot.y > 0.0 then
                        axis_x = 0.0001
                    elseif ent_rot.y > -2.0 and ent_rot.y < 0.0 then
                        axis_x = -0.0001
                    end
                else 
                    axis_x = 0.0 
                end
                
                roll = -(axis_x * 0.05) * frame_time * (max - 25)
            end
        else roll = 0.0 end

        local rot = vect.add(vect.new(pitch, roll, heading), ent_rot) 
        if rot.y > max then
            rot.y = max
        elseif rot.y < -max then
            rot.y = -max
        end
        
        if rot.x > 80 then
            rot.x = 80
        elseif rot.x < -max then
            rot.x = -max
        end
        ENTITY.SET_ENTITY_ROTATION(object, rot.x, rot.y, rot.z, 2, true)
    else
        local ent_rot = ENTITY.GET_ENTITY_ROTATION(object, 2)
        if ent_roll ~= 0 or ent_pitch ~= 0 then
            if ent_rot.y ~= 0 then
                if ent_rot.y < 0 then
                    axis_x = -1.0
                else
                    axis_x = 1.0
                end
            else 
                axis_x = 0.0 
            end

            if ent_rot.y ~= 0 then
                if ent_rot.y < 2.0 and ent_rot.y > 0.0 then
                    axis_x = 0.0001
                elseif ent_rot.y > -2.0 and ent_rot.y < 0.0 then
                    axis_x = -0.0001
                end
            else 
                axis_x = 0.0 
            end

            if ent_rot.x ~= 0.0 then
				if ent_rot.x < 2.0 and ent_rot.x > 0.0 then
					axis_y = 0.0001
				elseif ent_rot.x > -2.0 and ent_rot.x < 0.0 then
					axis_y = -0.0001
                end
			else 
                axis_y = 0.0 
            end

            heading = currect_rot(-(( (axis_y * 0.05) * frame_time) * (max - 25)))
            roll = currect_rot(-(( (axis_x * 0.05) * frame_time) * (max - 25)))
            local rot = vect.add(vect.new(0, roll, heading), ent_rot)
            ENTITY.SET_ENTITY_ROTATION(object, rot.x, rot.y, rot.z, 2, true)
        end
    end
end


local function out_of_bounds_state(pos)
    local perc = 0.0
    local limit = 3000.0
    local distance = vect.dist(pos, start_pos)

    if distance >= (limit - 500) and distance < limit then
        perc = (distance - (limit - 500)) / 500
        
        if AUDIO.HAS_SOUND_FINISHED(sId.out_of_bounds) then
            sId.out_of_bounds = AUDIO.GET_SOUND_ID()
            AUDIO.PLAY_SOUND_FRONTEND(sId.out_of_bounds, "Out_Of_Bounds_Alarm_Loop", audio_reference, true)
        end

        if flash_rate ~= round(perc, 1) then
            flash_rate = round(perc, 1)
            GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SET_WARNING_IS_VISIBLE")
            GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_BOOL(true)
            GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

            GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SET_WARNING_FLASH_RATE")
            GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(flash_rate)
            GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
        end
        
        return false
    elseif distance >= limit then
        return true
    else
        flash_rate = 0.0

        if not AUDIO.HAS_SOUND_FINISHED(sId.out_of_bounds) then
			AUDIO.STOP_SOUND(sId.out_of_bounds)
			AUDIO.RELEASE_SOUND_ID(sId.out_of_bounds)
			sId.out_of_bounds = -1
        end

        GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SET_WARNING_IS_VISIBLE")
        GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_BOOL(false)
        GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
    end
    return false
end


self.main_loop = function ()
    if state == 0 then

        if PED.IS_PED_IN_ANY_VEHICLE(PLAYER.PLAYER_PED_ID(), false) then
            TASK.TASK_LEAVE_ANY_VEHICLE(PLAYER.PLAYER_PED_ID(), 0, 0)
        end

        ENTITY.FREEZE_ENTITY_POSITION(PLAYER.PLAYER_PED_ID(), true)
        local coords = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())

        REQUEST_MODELS(m_object_hash)
        NETWORK._RESERVE_NETWORK_LOCAL_OBJECTS(NETWORK.GET_NUM_RESERVED_MISSION_OBJECTS(false, 1) + 1)
        object = OBJECT.CREATE_OBJECT_NO_OFFSET(m_object_hash, coords.x, coords.y, coords.z, true, false, true)
        ENTITY.SET_ENTITY_HEADING(object, currect_heading(CAM.GET_GAMEPLAY_CAM_ROT(0).z))
        ENTITY.SET_ENTITY_AS_MISSION_ENTITY(object, false, true)
        ENTITY.SET_ENTITY_INVINCIBLE(object, true)
        ENTITY._SET_ENTITY_CLEANUP_BY_ENGINE(object, true)
        NETWORK.SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER(NETWORK.OBJ_TO_NET(object), PLAYER.PLAYER_ID(), true)
        ENTITY.SET_ENTITY_LOAD_COLLISION_FLAG(object, true, 1)
        NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(NETWORK.OBJ_TO_NET(object), true);
        ENTITY.SET_ENTITY_LOD_DIST(object, 700)
        NETWORK.SET_NETWORK_ID_CAN_MIGRATE(NETWORK.OBJ_TO_NET(object), false)
        ENTITY.SET_ENTITY_RECORDS_COLLISIONS(object, true)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(object, coords.x, coords.y, coords.z + 5, false, false, true)
        ENTITY.SET_ENTITY_HAS_GRAVITY(object, false)
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(m_object_hash)

        camera = CAM.CREATE_CAM("DEFAULT_SCRIPTED_CAMERA", true)
        CAM.SET_CAM_FOV(camera, 80)
        CAM.SET_CAM_NEAR_CLIP(camera, 0.01)
        CAM.SET_CAM_NEAR_DOF(camera, 0.01)
        GRAPHICS.CLEAR_TIMECYCLE_MODIFIER()
        GRAPHICS.SET_TIMECYCLE_MODIFIER("eyeinthesky")
        ATTACH_CAM_TO_ENTITY_WITH_FIXED_DIRECTION(camera, object, 0.0, 0.0, 180.0, 0.0, -0.9, 0.0, 1)
        CAM.RENDER_SCRIPT_CAMS(true, false, 0, true, true, 0)

        GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SET_WARNING_IS_VISIBLE")
        GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_BOOL(false)
        GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

        GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SET_ZOOM_VISIBLE")
        GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_BOOL(false)
        GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

        if not AUDIO.IS_AUDIO_SCENE_ACTIVE("dlc_aw_arena_piloted_missile_scene") then
            AUDIO.START_AUDIO_SCENE("dlc_aw_arena_piloted_missile_scene")
        end

        sId.startup = AUDIO.GET_SOUND_ID()
        AUDIO.PLAY_SOUND_FRONTEND(sId.startup, "HUD_Startup", audio_reference, true)
        
        REQUEST_PTFX_ASSET(ptfx_asset)
        GRAPHICS.USE_PARTICLE_FX_ASSET(ptfx_asset)
        effects.missile_trail = GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY(
            "scr_xs_guided_missile_trail", 
            object, 
            0.0, 0.0, 0.0, 
            0.0, 0.0, 0.0, 
            1.0, 
            false, false, false
        )

        blip = HUD.ADD_BLIP_FOR_COORD(coords.x, coords.y, coords.z)
        HUD.SET_BLIP_SCALE(blip, 1.0)
        HUD.SET_BLIP_ROUTE(blip, 0)
        HUD.SET_BLIP_SPRITE(blip, 548)

        start_pos = coords
        state = 1
    elseif state == 1 then
        local force_mag
        local accelerating
        local decelerating
        local coords    = ENTITY.GET_ENTITY_COORDS(object, true)
        local velocity  = ENTITY.GET_ENTITY_VELOCITY(object)
        local rotation  = CAM.GET_CAM_ROT(camera, 2)
        local heading   = currect_heading( ENTITY.GET_ENTITY_HEADING(object) )
        local direction = util.rot_to_dir(rotation)

        HUD.SET_BLIP_DISPLAY(blip, 2)
        HUD.SET_BLIP_COORDS(blip, coords.x, coords.y, coords.z)
        HUD.LOCK_MINIMAP_POSITION(coords.x, coords.y)
        HUD.SET_BLIP_ROTATION(blip, round(heading))
        HUD.SET_BLIP_PRIORITY(blip, 9)
        HUD.LOCK_MINIMAP_ANGLE(round(heading))

        if ENTITY.HAS_ENTITY_COLLIDED_WITH_ANYTHING(object) or ENTITY.GET_LAST_MATERIAL_HIT_BY_ENTITY(object) ~= 0 or ENTITY.IS_ENTITY_IN_WATER(object) then
            state = 2
        end

        if NETWORK.NETWORK_HAS_CONTROL_OF_NETWORK_ID(NETWORK.OBJ_TO_NET(object))  then
            if not PAD._IS_USING_KEYBOARD(0) then
                if PAD.GET_CONTROL_UNBOUND_NORMAL(2, 208) ~= 0 then
                    accelerating = true
                end
                if PAD.GET_CONTROL_UNBOUND_NORMAL(2, 207) ~= 0 then
                    decelerating = true
                end
            else
                if PAD.GET_CONTROL_UNBOUND_NORMAL(2, 209) ~= 0 then
                    accelerating = true
                end
                if PAD.GET_CONTROL_UNBOUND_NORMAL(2, 210) ~= 0 then
                    decelerating = true
                end
            end
            
            if accelerating then
                force_mag = 150.0
            elseif decelerating then
                force_mag = 50.0
            else
                force_mag = 100.0
            end
    
            local force = vect.mult(direction, force_mag)
            ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(object, 1, force.x, force.y, force.z, false, false, false, false)
            set_entity_rotation()
            STREAMING.SET_FOCUS_POS_AND_VEL(coords.x, coords.y, coords.z, velocity.x, velocity.y, velocity.z)
            --PED.SET_POP_CONTROL_SPHERE_THIS_FRAME(coords.x, coords.y, coords.z, 60.0, 100.0)
            if MISC.GET_FRAME_COUNT() % 120 == 0 then
                PED.SET_SCENARIO_PEDS_SPAWN_IN_SPHERE_AREA(coords.x, coords.y, coords.z, 60.0, 30);
            end
            
            GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SET_ALT_FOV_HEADING")
            GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(0)
            GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(0)
            GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_FLOAT(rotation.z)
            GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
    
            if out_of_bounds_state(coords) or PAD.IS_CONTROL_JUST_PRESSED(2, 75) then
                state = 2
            end
            
            GRAPHICS.DRAW_SCALEFORM_MOVIE_FULLSCREEN(scaleform, 255, 255, 255, 0, 1)
            draw_intructional_buttons()
        else
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(object) 
        end
    elseif state == 2 then
        local coord = CAM.GET_CAM_COORD(camera)
        FIRE.ADD_EXPLOSION(coord.x, coord.y, coord.z, 81, 5.0, true, false, 1.0, false)
        PAD.SET_PAD_SHAKE(0, 300, 200)
        NETWORK.NETWORK_FADE_OUT_ENTITY(object, false, true)
        
        if not AUDIO.HAS_SOUND_FINISHED(sId.startup) then
            AUDIO.STOP_SOUND(sId.startup)
            AUDIO.RELEASE_SOUND_ID(sId.startup)
            sId.startup = -1
        end

        if not AUDIO.HAS_SOUND_FINISHED(sId.out_of_bounds) then
			AUDIO.STOP_SOUND(sId.out_of_bounds)
			AUDIO.RELEASE_SOUND_ID(sId.out_of_bounds)
            sId.out_of_bounds = -1
        end

        if GRAPHICS.DOES_PARTICLE_FX_LOOPED_EXIST(effects.missile_trail) then
            GRAPHICS.STOP_PARTICLE_FX_LOOPED(effects.missile_trail, false)
            STREAMING.REMOVE_NAMED_PTFX_ASSET(ptfx_asset)
        end

        if HUD.DOES_BLIP_EXIST(blip) then
            util.remove_blip(blip)
        end

        state = 3
    elseif state == 3 then
        if not sTime then
            sId.static_loop = AUDIO.GET_SOUND_ID()
            AUDIO.PLAY_SOUND_FRONTEND(sId.static_loop, "HUD_Static_Loop", audio_reference, true)
            GRAPHICS.SET_TIMECYCLE_MODIFIER("MissileOutOfRange")
        
            sTime = cTime()
        elseif ( cTime() - sTime ) >= 1000 then
            if not AUDIO.HAS_SOUND_FINISHED(sId.static_loop) then
                AUDIO.STOP_SOUND(sId.static_loop)
                AUDIO.RELEASE_SOUND_ID(sId.static_loop)
                sId.static_loop = -1
            end
            
            CAM.DESTROY_ALL_CAMS(true)
            CAM.DESTROY_CAM(camera, false)
            CAM.RENDER_SCRIPT_CAMS(false, false, 3000, true, false, 0)
            STREAMING.CLEAR_FOCUS()

            sTime = nil
            state = 4
        end
    elseif state == 4 then
        if not sTime then
            sId.disconnect = AUDIO.GET_SOUND_ID()
            AUDIO.PLAY_SOUND_FRONTEND(sId.disconect, "HUD_Disconnect", audio_reference, true)
            
            sTime = cTime()
        elseif ( cTime() - sTime ) >= 500 then
            if not AUDIO.HAS_SOUND_FINISHED(sId.disconect) then
                AUDIO.STOP_SOUND(sId.disconect)
                AUDIO.RELEASE_SOUND_ID(sId.disconect)
                sId.disconect = -1
            end

            if AUDIO.IS_AUDIO_SCENE_ACTIVE("dlc_aw_arena_piloted_missile_scene") then
                AUDIO.STOP_AUDIO_SCENE("dlc_aw_arena_piloted_missile_scene")
            end

            GRAPHICS.SET_TIMECYCLE_MODIFIER("DEFAULT")
            
            entities.delete_by_handle(object)

            HUD.UNLOCK_MINIMAP_ANGLE()
            HUD.UNLOCK_MINIMAP_POSITION()
            ENTITY.FREEZE_ENTITY_POSITION(PLAYER.PLAYER_PED_ID(), false)
            
            sTime = nil
            state = -1
        end
    end
end


self.on_stop = function ()
    if state ~= -1 then
        if not AUDIO.HAS_SOUND_FINISHED(sId.out_of_bounds) then
			AUDIO.STOP_SOUND(sId.out_of_bounds)
			AUDIO.RELEASE_SOUND_ID(sId.out_of_bounds)
        end

        if not AUDIO.HAS_SOUND_FINISHED(sId.static_loop) then
            AUDIO.STOP_SOUND(sId.static_loop)
            AUDIO.RELEASE_SOUND_ID(sId.static_loop)
        end

        if not AUDIO.HAS_SOUND_FINISHED(sId.disconect) then
            AUDIO.STOP_SOUND(sId.disconect)
            AUDIO.RELEASE_SOUND_ID(sId.disconect)
        end

        if GRAPHICS.DOES_PARTICLE_FX_LOOPED_EXIST(effects.missile_trail) then
            GRAPHICS.STOP_PARTICLE_FX_LOOPED(effects.missile_trail, false)
            STREAMING.REMOVE_NAMED_PTFX_ASSET(ptfx_asset)
        end

        if AUDIO.IS_AUDIO_SCENE_ACTIVE("dlc_aw_arena_piloted_missile_scene") then
            AUDIO.STOP_AUDIO_SCENE("dlc_aw_arena_piloted_missile_scene")
        end

        if HUD.DOES_BLIP_EXIST(blip) then
            util.remove_blip(blip)
        end

        CAM.DESTROY_ALL_CAMS(true)
        CAM.DESTROY_CAM(camera, false)
        CAM.RENDER_SCRIPT_CAMS(false, false, 3000, true, false, 0)
        STREAMING.CLEAR_FOCUS()
        
        GRAPHICS.SET_TIMECYCLE_MODIFIER("DEFAULT")
        
        entities.delete_by_handle(object)

        HUD.UNLOCK_MINIMAP_ANGLE()
        HUD.UNLOCK_MINIMAP_POSITION()
        ENTITY.FREEZE_ENTITY_POSITION(PLAYER.PLAYER_PED_ID(), false)
    end
end

return self
