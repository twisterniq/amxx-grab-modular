#include <amxmodx>
#include <fakemeta>
#include <reapi>
#include <xs>

public stock const PluginName[] = "Grab Modular"
public stock const PluginVersion[] = "2.1.0"
public stock const PluginAuthor[] = "twisterniq"

/****************************************************************************************
****************************************************************************************/

// Entities with one of that classnames will be allowed to be grabbed
new const VALID_CLASSNAMES[][] =
{
    "weaponbox",
    "armoury_entity",
    "weapon_shield",
    // "func_vehicle"
}

// Interval between checks when player tries to grab something or someone
//
// There is no need to change it unless you want a faster response,
// but keep in mind that the lower the cooldown between checks, the greater the load
const Float:CHECK_TIME = 0.1

/****************************************************************************************
****************************************************************************************/

#define CHECK_NATIVE_PLAYER(%0,%1) \
    if (!is_user_valid(%0)) \
    { \
        log_error(AMX_ERR_NATIVE, "Player out of range (%d).", %0); \
        return %1; \
    }

enum _:Forwards
{
    FWD_ON_START,
    FWD_ON_FINISH,
    FWD_ON_GRABBING,
    FWD_ACCESS_MODIFIED
}

enum _:CVars
{
    CVAR_ENABLED,
    CVAR_PLAYERS_ONLY,
    Float:CVAR_MIN_DISTANCE,
    Float:CVAR_MAX_DISTANCE,
    Float:CVAR_FORCE,
    CVAR_LADDER_SUPPORT
}

enum _:GrabStruct
{
    bool:SEARCHING,
    GRABBER,
    GRABBED,
    Float:GRAB_DISTANCE,
    ACCESS_LEVEL
}

new g_hForwards[Forwards]
new g_eCVars[CVars]
new g_eGrabData[MAX_PLAYERS + 1][GrabStruct]

new Trie:g_tValidClassNames

public plugin_init()
{
    register_plugin(PluginName, PluginVersion, PluginAuthor)
    register_dictionary("grab_modular.txt")

    register_clcmd("+grab", "clcmd_GrabEnable")
    register_clcmd("-grab", "clcmd_GrabDisable")

    g_tValidClassNames = TrieCreate()

    for (new i; i < sizeof VALID_CLASSNAMES; i++)
    {
        TrieSetCell(g_tValidClassNames, VALID_CLASSNAMES[i], 1)
    }

    g_hForwards[FWD_ON_START] = CreateMultiForward("grab_on_start", ET_IGNORE, FP_CELL, FP_CELL)
    g_hForwards[FWD_ON_FINISH] = CreateMultiForward("grab_on_finish", ET_IGNORE, FP_CELL, FP_CELL)
    g_hForwards[FWD_ON_GRABBING] = CreateMultiForward("grab_on_grabbing", ET_IGNORE, FP_CELL, FP_CELL)
    g_hForwards[FWD_ACCESS_MODIFIED] = CreateMultiForward("grab_access_modified", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)

    register_forward(FM_CmdStart, "CmdStart_Post", true)

    func_CreateCVars()
}

func_CreateCVars()
{
    bind_pcvar_num(
        create_cvar(
            .name = "grab_enabled",
            .string = "1",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_CVAR_ENABLED"),
            .has_min = true,
            .min_val = 0.0,
            .has_max = true, 
            .max_val = 1.0
        ), g_eCVars[CVAR_ENABLED]
    )

    bind_pcvar_num(
        create_cvar(
            .name = "grab_players_only",
            .string = "0",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_CVAR_PLAYERS_ONLY"),
            .has_min = true,
            .min_val = 0.0,
            .has_max = true, 
            .max_val = 1.0
        ), g_eCVars[CVAR_PLAYERS_ONLY]
    )

    bind_pcvar_float(
        create_cvar(
            .name = "grab_min_distance",
            .string = "90",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_CVAR_MIN_DISTANCE"),
            .has_min = true,
            .min_val = 1.0
        ), g_eCVars[CVAR_MIN_DISTANCE]
    )

    bind_pcvar_float(
        create_cvar(
            .name = "grab_max_distance",
            .string = "2000",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_CVAR_MAX_DISTANCE"),
            .has_min = true,
            .min_val = 1.0
        ), g_eCVars[CVAR_MAX_DISTANCE]
    )

    bind_pcvar_float(
        create_cvar(
            .name = "grab_force",
            .string = "8.0",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_CVAR_FORCE"),
            .has_min = true,
            .min_val = 0.1
        ), g_eCVars[CVAR_FORCE]
    )

    bind_pcvar_num(
        create_cvar(
            .name = "grab_ladder_support",
            .string = "1",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_CVAR_LADDER_SUPPORT"),
            .has_min = true,
            .min_val = 0.0,
            .has_max = true, 
            .max_val = 1.0
        ), g_eCVars[CVAR_LADDER_SUPPORT]
    )

    AutoExecConfig(true, "grab_modular", "grab_modular")
}

public plugin_natives()
{
    register_native("grab_get_grabber", "native_grab_get_grabber")
    register_native("grab_get_grabbed", "native_grab_get_grabbed")
    register_native("grab_get_distance", "native_grab_get_distance")
    register_native("grab_set_distance", "native_grab_set_distance")
    register_native("grab_disable", "native_grab_disable")

    register_native("grab_get_user_access", "native_grab_get_user_access")
    register_native("grab_set_user_access", "native_grab_set_user_access")
}

public native_grab_get_grabber()
{
    enum { arg_entity = 1 }

    new iEnt = get_param(arg_entity)

    for (new i = 1; i <= MaxClients; i++)
    {
        if (g_eGrabData[i][GRABBED] == iEnt)
        {
            return i
        }
    }

    return 0
}

public native_grab_get_grabbed()
{
    enum { arg_player = 1 }

    new id = get_param(arg_player)
    CHECK_NATIVE_PLAYER(id, 0)

    return g_eGrabData[id][GRABBED]
}

public native_grab_get_user_access()
{
    enum { arg_player = 1 }

    new id = get_param(arg_player)
    CHECK_NATIVE_PLAYER(id, false)

    return g_eGrabData[id][ACCESS_LEVEL]
}

public bool:native_grab_set_user_access()
{
    enum { arg_player = 1, arg_level }

    new id = get_param(arg_player)
    new iNewLevel = get_param(arg_level)
    new iOldLevel

    if (id)
    {
        CHECK_NATIVE_PLAYER(id, false)

        iOldLevel = g_eGrabData[id][ACCESS_LEVEL]
        g_eGrabData[id][ACCESS_LEVEL] = iNewLevel

        ExecuteForward(g_hForwards[FWD_ACCESS_MODIFIED], _, id, iOldLevel, iNewLevel)
    }
    else
    {
        for (new i = 1; i <= MaxClients; i++)
        {
            if (!is_user_connected(i))
            {
                continue
            }

            iOldLevel = g_eGrabData[i][ACCESS_LEVEL]
            g_eGrabData[i][ACCESS_LEVEL] = iNewLevel

            ExecuteForward(g_hForwards[FWD_ACCESS_MODIFIED], _, i, iOldLevel, iNewLevel)
        }
    }

    return true
}

public Float:native_grab_get_distance()
{
    enum { arg_player = 1 }

    new id = get_param(arg_player)
    CHECK_NATIVE_PLAYER(id, 0.0)

    return g_eGrabData[id][GRAB_DISTANCE]
}

public bool:native_grab_set_distance()
{
    enum { arg_player = 1, arg_distance }

    new id = get_param(arg_player)
    CHECK_NATIVE_PLAYER(id, false)

    if (!g_eGrabData[id][GRABBED])
    {
        return false
    }

    g_eGrabData[id][GRAB_DISTANCE] = floatclamp(
        get_param_f(arg_distance),
        g_eCVars[CVAR_MIN_DISTANCE],
        g_eCVars[CVAR_MAX_DISTANCE]
    )

    return true
}

public bool:native_grab_disable()
{
    enum { arg_player = 1 }

    new id = get_param(arg_player)

    if (id)
    {
        CHECK_NATIVE_PLAYER(id, false)
        func_GrabDisable(id)
    }
    else
    {
        for (new i = 1; i <= MaxClients; i++)
        {
            func_GrabDisable(i)
        }
    }

    return true
}

public client_disconnected(id)
{
    new iGrabber = g_eGrabData[id][GRABBER]

    if (iGrabber)
    {
        // Disable grab if the disconnected player was being grabbed
        func_GrabDisable(iGrabber)
    }

    arrayset(g_eGrabData[id], 0, GrabStruct)
}


public clcmd_GrabEnable(const id)
{
    if (!g_eGrabData[id][ACCESS_LEVEL])
    {
        return PLUGIN_HANDLED
    }

    g_eGrabData[id][SEARCHING] = true
    return PLUGIN_HANDLED
}

public clcmd_GrabDisable(const id)
{
    func_GrabDisable(id)
    return PLUGIN_HANDLED
}

func_GrabDisable(const id)
{
    g_eGrabData[id][SEARCHING] = false

    if (!g_eGrabData[id][GRABBED])
    {
        return PLUGIN_HANDLED
    }

    new iTarget = g_eGrabData[id][GRABBED]
    ExecuteForward(g_hForwards[FWD_ON_FINISH], _, id, iTarget)

    // Is target a player?
    if (is_user_valid(iTarget))
    {
        // Entity is no longer grabbed by anyone
        g_eGrabData[iTarget][GRABBER] = 0

        if (g_eCVars[CVAR_LADDER_SUPPORT])
        {
            // Player can now use ladders again
            set_prevent_climb(iTarget, false)
        }
    }

    // Player is no longer grabbing anything
    g_eGrabData[id][GRABBED] = 0
    g_eGrabData[id][GRAB_DISTANCE] = 0.0

    return PLUGIN_HANDLED
}

public CmdStart_Post(const id, iHandle)
{
    static iEnt

    if (g_eGrabData[id][SEARCHING])
    {
        static Float:flTime[MAX_PLAYERS + 1]
        static Float:flGameTime

        flGameTime = get_gametime()

        // Prevent too many checkings
        if (flTime[id] < flGameTime)
        {
            static Float:flResult[3]
            velocity_by_aim(id, floatround(g_eCVars[CVAR_MAX_DISTANCE]), flResult)

            static Float:flOrigin[3]
            UTIL_GetViewPosition(id, flOrigin)

            flResult[0] += flOrigin[0]
            flResult[1] += flOrigin[1]
            flResult[2] += flOrigin[2]

            // Find a target
            iEnt = UTIL_GetTargetByTraceLine(flOrigin, flResult, id, flResult)

            func_TryGrabEnt(id, iEnt, flResult)
            flTime[id] = flGameTime + CHECK_TIME
        }
    }
    else
    {
        iEnt = g_eGrabData[id][GRABBER]
        
        if (is_user_valid(iEnt))
        {
            func_GrabThink(iEnt)
        }

        iEnt = g_eGrabData[id][GRABBED]

        if (iEnt && !is_user_valid(iEnt))
        {
            func_GrabThink(id)
        }
    }
}

bool:func_TryGrabEnt(const id, iTarget, Float:flOrigin[3])
{
    // Is target a player?
    if (is_user_valid(iTarget))
    {
        if (func_IsEntityGrabbed(iTarget))
        {
            // Target is already being grabbed, stop
            return false
        }
    }
    // Is it allowed to grab a non-player entity?
    else if (!g_eCVars[CVAR_PLAYERS_ONLY])
    {
        // Not a valid entity, let's try find it in sphere
        if (is_nullent(iTarget))
        {
            iTarget = NULLENT

            do
            {
                iTarget = engfunc(EngFunc_FindEntityInSphere, iTarget, flOrigin, 12.0)
            } while (iTarget && iTarget == id)
        }

        if (is_nullent(iTarget))
        {
            // Not a valid entity, stop
            return false
        }

        if (!func_IsClassNameValid(iTarget))
        {
            // Not a valid classname, stop
            return false
        }

        if (func_IsEntityGrabbed(iTarget))
        {
            // It is already being grabbed, stop
            return false
        }
    }
    else
    {
        return false
    }

    // Target is not being grabbed, start grabbing it
    func_StartGrabbing(id, iTarget)
    return true
}

bool:func_IsEntityGrabbed(const iEnt)
{
    for (new i = 1; i <= MaxClients; i++)
    {
        if (g_eGrabData[i][GRABBED] == iEnt)
        {
            return true
        }
    }

    return false
}

bool:func_IsClassNameValid(const iEnt)
{
    static szClassName[32]
    get_entvar(iEnt, var_classname, szClassName, charsmax(szClassName))

    return TrieKeyExists(g_tValidClassNames, szClassName)
}

func_StartGrabbing(const id, const iEnt)
{
    g_eGrabData[id][SEARCHING] = false
    g_eGrabData[id][GRABBED] = iEnt

    // Is target a player?
    if (is_user_valid(iEnt))
    {
        g_eGrabData[iEnt][GRABBER] = id

        if (g_eCVars[CVAR_LADDER_SUPPORT])
        {
            // Disable the ability to use ladders
            set_prevent_climb(iEnt, true)
        }
    }

    new Float:flOrigin[3]
    get_entvar(id, var_origin, flOrigin)

    new Float:flEntOrigin[3]
    get_entvar(iEnt, var_origin, flEntOrigin)

    // Get current distance between grabber and grabbed entity
    g_eGrabData[id][GRAB_DISTANCE] = get_distance_f(flOrigin, flEntOrigin)

    if (g_eGrabData[id][GRAB_DISTANCE] < g_eCVars[CVAR_MIN_DISTANCE])
    {
        g_eGrabData[id][GRAB_DISTANCE] = g_eCVars[CVAR_MIN_DISTANCE]
    }

    // Execute after setting grabber/grabbed and distance
    // so that natives return correct values
    ExecuteForward(g_hForwards[FWD_ON_START], _, id, iEnt)
}

func_GrabThink(const id)
{
    static iTarget
    iTarget = g_eGrabData[id][GRABBED]

    static bool:bPlayer
    bPlayer = is_user_valid(iTarget)

    if (bPlayer && !is_user_alive(iTarget) || !bPlayer && !is_entity(iTarget))
    {
        // Not a valid target anymore, stop grabbing
        func_GrabDisable(id)
        return
    }

    ExecuteForward(g_hForwards[FWD_ON_GRABBING], _, id, iTarget)

    static Float:flOrigin[3], Float:flVOfs[3]
    UTIL_GetViewPosition(id, flOrigin, flVOfs)

    static Float:flEntOrigin[3]
    func_GetEntOrigin(iTarget, flEntOrigin)

    if (bPlayer || !bPlayer && get_entvar(iTarget, var_movetype) != MOVETYPE_NONE)
    {
        static Float:flResult[3]
        velocity_by_aim(id, floatround(g_eGrabData[id][GRAB_DISTANCE]), flResult)

        static Float:flForce
        flForce = g_eCVars[CVAR_FORCE]

        static Float:flVelocity[3]
        flVelocity[0] = ((flOrigin[0] + flResult[0]) - flEntOrigin[0]) * flForce
        flVelocity[1] = ((flOrigin[1] + flResult[1]) - flEntOrigin[1]) * flForce
        flVelocity[2] = ((flOrigin[2] + flResult[2]) - flEntOrigin[2]) * flForce

        set_entvar(iTarget, var_velocity, flVelocity)
    }
    else
    {
        get_entvar(id, var_v_angle, flVOfs)
        angle_vector(flVOfs, ANGLEVECTOR_FORWARD, flVOfs)

        xs_vec_mul_scalar(flVOfs, g_eGrabData[id][GRAB_DISTANCE], flVOfs)
        xs_vec_add(flOrigin, flVOfs, flOrigin)

        static Float:flMins[3]
        get_entvar(iTarget, var_mins, flMins)

        static Float:flMaxs[3]
        get_entvar(iTarget, var_maxs, flMaxs)

        if (!flMins[2])
        {
            flOrigin[2] -= flMaxs[2] / 2
        }

        for (new i; i < sizeof flOrigin; i++)
        {
            flOrigin[i] -= floatfract(flOrigin[i])
        }

        engfunc(EngFunc_SetOrigin, iTarget, flOrigin)
    }
}

/****************************************************************************************
****************************************************************************************/

stock bool:is_user_valid(const id)
{
    return (id > 0 && id <= MaxClients)
}

stock UTIL_GetTargetByTraceLine(const Float:flVStart[3], const Float:flVEnd[3], const pIgnore, Float:flVHitPos[3])
{
    engfunc(EngFunc_TraceLine, flVStart, flVEnd, 0, pIgnore, 0)
    get_tr2(0, TR_vecEndPos, flVHitPos)
    return get_tr2(0, TR_pHit)
}

stock UTIL_GetViewPosition(const id, Float:flViewPosition[3], Float:flVOfs[3] = { 0.0, 0.0, 0.0 })
{
    get_entvar(id, var_origin, flViewPosition)
    get_entvar(id, var_view_ofs, flVOfs)	
    xs_vec_add(flViewPosition, flVOfs, flViewPosition)
}

// thx s1lent
stock set_prevent_climb(id, bool:bPrevent)
{
    new iFlags = get_entvar(id, var_iuser3)

    if (bPrevent)
    {
        iFlags |= PLAYER_PREVENT_CLIMB
    }
    else
    {
        iFlags &= ~PLAYER_PREVENT_CLIMB
    }

    set_entvar(id, var_iuser3, iFlags)
}

stock Float:func_GetEntOrigin(const iEnt, Float:flOrigin[3])
{
    get_entvar(iEnt, var_origin, flOrigin)

    if (iEnt > MaxClients)
    {
        static Float:flMins[3]
        get_entvar(iEnt, var_mins, flMins)

        static Float:flMaxs[3]
        get_entvar(iEnt, var_maxs, flMaxs)

        if (!flMins[2])
        {
            flOrigin[2] += flMaxs[2] / 2
        }
    }

    return flOrigin
}
