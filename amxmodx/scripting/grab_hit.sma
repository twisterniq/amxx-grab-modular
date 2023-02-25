#include <amxmodx>
#include <hamsandwich>
#include <reapi>
#include <grab_modular>

public stock const PluginName[] = "Grab: Hit"
public stock const PluginVersion[] = "2.1.0"
public stock const PluginAuthor[] = "twisterniq"

// Path to the sound that will be played when player is hit
// It's a default sound, so it's not precached
new const SOUND_HIT[] = "player/pl_pain2.wav"

enum _:CVars
{
    CVAR_ENABLED,
    Float:CVAR_DAMAGE,
    Float:CVAR_COOLDOWN,
    CVAR_GIBS,
    CVAR_BLOOD,
    CVAR_SCREENSHAKE,
    Float:CVAR_SCREENSHAKE_AMPLITUDE,
    Float:CVAR_SCREENSHAKE_DURATION,
    Float:CVAR_SCREENSHAKE_FREQUENCY
}

new g_eCVars[CVars]
new bool:g_bHitEnabled[MAX_PLAYERS + 1]

public plugin_init()
{
    register_plugin(PluginName, PluginVersion, PluginAuthor)
    register_dictionary("grab_hit.txt")

    func_CreateCVars()
}

func_CreateCVars()
{
    bind_pcvar_num(
        create_cvar(
            .name = "grab_hit_enabled",
            .string = "1",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_CVAR_ENABLED"),
            .has_min = true,
            .min_val = 0.0,
            .has_max = true, 
            .max_val = 1.0
        ), g_eCVars[CVAR_ENABLED]
    )

    bind_pcvar_float(
        create_cvar(
            .name = "grab_hit_damage",
            .string = "5.0",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_HIT_CVAR_DAMAGE"),
            .has_min = true,
            .min_val = 1.0
        ), g_eCVars[CVAR_DAMAGE]
    )

    bind_pcvar_float(
        create_cvar(
            .name = "grab_hit_cooldown",
            .string = "0.5",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_HIT_CVAR_COOLDOWN"),
            .has_min = true,
            .min_val = 0.1
        ), g_eCVars[CVAR_COOLDOWN]
    )

    bind_pcvar_num(
        create_cvar(
            .name = "grab_hit_gibs",
            .string = "1",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_HIT_CVAR_GIBS"),
            .has_min = true,
            .min_val = 0.0,
            .has_max = true,
            .max_val = 1.0
        ), g_eCVars[CVAR_GIBS]
    )

    bind_pcvar_num(
        create_cvar(
            .name = "grab_hit_blood",
            .string = "1",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_HIT_CVAR_BLOOD"),
            .has_min = true,
            .min_val = 0.0,
            .has_max = true,
            .max_val = 1.0
        ), g_eCVars[CVAR_BLOOD]
    )

    bind_pcvar_num(
        create_cvar(
            .name = "grab_hit_screenshake",
            .string = "1",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_HIT_CVAR_SCREENSHAKE"),
            .has_min = true,
            .min_val = 0.0,
            .has_max = true,
            .max_val = 1.0
        ), g_eCVars[CVAR_SCREENSHAKE]
    )

    bind_pcvar_float(
        create_cvar(
            .name = "grab_hit_screenshake_amplitude",
            .string = "8.0",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_HIT_CVAR_SCREENSHAKE_AMPLITUDE"),
            .has_min = true,
            .min_val = 0.0,
            .has_max = true,
            .max_val = 16.0
        ), g_eCVars[CVAR_SCREENSHAKE_AMPLITUDE]
    )

    bind_pcvar_float(
        create_cvar(
            .name = "grab_hit_screenshake_duration",
            .string = "4.0",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_HIT_CVAR_SCREENSHAKE_DURATION"),
            .has_min = true,
            .min_val = 0.0,
            .has_max = true,
            .max_val = 16.0
        ), g_eCVars[CVAR_SCREENSHAKE_DURATION]
    )

    bind_pcvar_float(
        create_cvar(
            .name = "grab_hit_screenshake_freq",
            .string = "8.0",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_HIT_CVAR_SCREENSHAKE_FREQUENCY"),
            .has_min = true,
            .min_val = 0.0,
            .has_max = true,
            .max_val = 16.0
        ), g_eCVars[CVAR_SCREENSHAKE_FREQUENCY]
    )

    AutoExecConfig(true, "grab_hit", "grab_modular")
}

public client_disconnected(id)
{
    func_UnsetHit(id)
}

public grab_on_grabbing(id, iTarget)
{
    if (g_bHitEnabled[id])
    {
        // Already hitting player
        return
    }

    if (!(1 <= iTarget <= MaxClients))
    {
        // Target is not a player
        return
    }

    if (!(get_entvar(id, var_button) & IN_USE))
    {
        // Player is not using '+use'
        return
    }

    if (g_eCVars[CVAR_BLOOD])
    {
        new Float:flOrigin[3]
        get_entvar(iTarget, var_origin, flOrigin)

        UTIL_Blood(flOrigin)
    }

    if (g_eCVars[CVAR_SCREENSHAKE])
    {
        UTIL_ScreenShake(iTarget, g_eCVars[CVAR_SCREENSHAKE_AMPLITUDE], g_eCVars[CVAR_SCREENSHAKE_DURATION], g_eCVars[CVAR_SCREENSHAKE_FREQUENCY])
    }

    new Float:flHealth
    get_entvar(iTarget, var_health, flHealth)

    if (flHealth - g_eCVars[CVAR_DAMAGE] > 0.0)
    {
        set_entvar(iTarget, var_health, flHealth - g_eCVars[CVAR_DAMAGE])
    }
    else
    {
        ExecuteHam(Ham_Killed, iTarget, id, g_eCVars[CVAR_GIBS] ? GIB_ALWAYS : GIB_NEVER)
    }

    rh_emit_sound2(iTarget, 0, CHAN_BODY, SOUND_HIT, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

    g_bHitEnabled[id] = true
    set_task(g_eCVars[CVAR_COOLDOWN], "task_HitPlayer", id)
}

public grab_on_finish(id, iEnt)
{
    func_UnsetHit(id)
}

public task_HitPlayer(id)
{
    g_bHitEnabled[id] = false
}

func_UnsetHit(const id)
{
    if (g_bHitEnabled[id])
    {
        remove_task(id)
        g_bHitEnabled[id] = false
    }
}

stock UTIL_Blood(Float:flOrigin[3])
{
    message_begin_f(MSG_BROADCAST, SVC_TEMPENTITY)
    write_byte(TE_BLOODSTREAM)
    write_coord_f(flOrigin[0])              // pos.x
    write_coord_f(flOrigin[1])              // pos.y
    write_coord_f(flOrigin[2] + 15)         // pos.z
    write_coord_f(random_float(0.0, 255.0)) // vec.x
    write_coord_f(random_float(0.0, 255.0)) // vec.y
    write_coord_f(random_float(0.0, 255.0)) // vec.z
    write_byte(70)                          // col index
    write_byte(random_num(50, 250))         // speed
    message_end()
}

stock UTIL_ScreenShake(id, Float:flAmplitude, Float:flDuration, Float:flFrequency)
{
    static iMsgScreenShake

    if (!iMsgScreenShake)
    {
        iMsgScreenShake = get_user_msgid("ScreenShake")
    }

    message_begin(MSG_ONE, iMsgScreenShake, .player = id)
    write_short(float_to_short(flAmplitude)) // amplitude
    write_short(float_to_short(flDuration))  // duration
    write_short(float_to_short(flFrequency)) // frequency
    message_end()
}

// from OciXCrom's msgstocks
stock float_to_short(Float:flValue)
{
    return clamp(floatround(flValue * (1<<12)), 0, 0xFFFF)
}