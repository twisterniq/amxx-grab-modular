#include <amxmodx>
#include <reapi>
#include <grab_modular>

public stock const PluginName[] = "Grab: Pull"
public stock const PluginVersion[] = "2.0.0"
public stock const PluginAuthor[] = "twisterniq"

enum _:CVars
{
    CVAR_CMD,
    CVAR_MOUSE,
    Float:CVAR_UNITS_PLAYER,
    Float:CVAR_UNITS_NO_PLAYER
}

enum _:PlayerStruct
{
    bool:GRABBING,
    bool:PULL_CMD,
    bool:PULL_MOUSE
}

new g_eCVars[CVars]
new g_ePlayerData[MAX_PLAYERS + 1][PlayerStruct]

public plugin_init()
{
    register_plugin(PluginName, PluginVersion, PluginAuthor)
    register_dictionary("grab_pull.txt")

    register_clcmd("+pull", "clcmd_PullEnabled")
    register_clcmd("-pull", "clcmd_PullDisabled")

    RegisterHookChain(RG_CBasePlayer_Observer_IsValidTarget, "CBasePlayer_Observer_IsValidTarget_Pre", false)

    func_CreateCVars()
}

func_CreateCVars()
{
    bind_pcvar_num(
        create_cvar(
            .name = "grab_pull_cmd",
            .string = "1",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_PULL_CVAR_CMD"),
            .has_min = true,
            .min_val = 0.0,
            .has_max = true, 
            .max_val = 1.0
        ), g_eCVars[CVAR_CMD]
    )

    bind_pcvar_num(
        create_cvar(
            .name = "grab_pull_mouse",
            .string = "1",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_PULL_CVAR_MOUSE"),
            .has_min = true,
            .min_val = 0.0,
            .has_max = true, 
            .max_val = 1.0
        ), g_eCVars[CVAR_MOUSE]
    )

    bind_pcvar_float(
        create_cvar(
            .name = "grab_pull_units_player",
            .string = "15.0",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_PULL_CVAR_UNITS_PLAYER"),
            .has_min = true,
            .min_val = 0.1
        ), g_eCVars[CVAR_UNITS_PLAYER]
    )

    bind_pcvar_float(
        create_cvar(
            .name = "grab_pull_units_no_player",
            .string = "1.0",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_PULL_CVAR_UNITS_NO_PLAYER"),
            .has_min = true,
            .min_val = 0.1
        ), g_eCVars[CVAR_UNITS_NO_PLAYER]
    )

    AutoExecConfig(true, "grab_pull", "grab_modular")
}

public client_disconnected(id)
{
    arrayset(g_ePlayerData[id], false, PlayerStruct)
}

public CBasePlayer_Observer_IsValidTarget_Pre(const id, iPlayerIndex, bool:bSameTeam)
{
    if (g_ePlayerData[id][GRABBING])
    {
        // Don't allow to change target when player is (maybe) pulling
        SetHookChainArg(2, ATYPE_INTEGER, 0)
    }    
}

public clcmd_PullEnabled(const id)
{
    if (!g_eCVars[CVAR_CMD])
    {
        return PLUGIN_HANDLED
    }

    g_ePlayerData[id][PULL_CMD] = true
    return PLUGIN_HANDLED
}

public clcmd_PullDisabled(const id)
{
    g_ePlayerData[id][PULL_CMD] = false
    return PLUGIN_HANDLED
}

public grab_on_start(id, iEnt)
{
    if (!g_eCVars[CVAR_MOUSE])
    {
        return
    }

    g_ePlayerData[id][GRABBING] = true
    set_member(id, m_bIsDefusing, true)
}

public grab_on_finish(id, iEnt)
{
    if (!g_eCVars[CVAR_MOUSE])
    {
        return
    }

    g_ePlayerData[id][GRABBING] = false
    set_member(id, m_bIsDefusing, false)
}

public grab_on_grabbing(id, iEnt)
{
    if (!g_eCVars[CVAR_CMD] && !g_eCVars[CVAR_MOUSE])
    {
        return
    }

    if (g_ePlayerData[id][PULL_CMD])
    {
        func_SetDistance(id, iEnt)
    }
    else
    {
        if (g_ePlayerData[id][PULL_MOUSE])
        {
            // Player releases right click
            if (!(get_entvar(id, var_button) & IN_ATTACK2))
            {
                g_ePlayerData[id][PULL_MOUSE] = false
            }
            else
            {
                func_SetDistance(id, iEnt)
            }
        }
        else
        {
            // Player is holding down right click
            if (get_entvar(id, var_button) & IN_ATTACK2)
            {
                g_ePlayerData[id][PULL_MOUSE] = true
            }
        }
    }
}

func_SetDistance(id, iEnt)
{
    static Float:flUnits

    // Units will depend on whether the target is player or not
    flUnits = (1 <= iEnt <= MaxClients) ? g_eCVars[CVAR_UNITS_PLAYER] : g_eCVars[CVAR_UNITS_NO_PLAYER]

    grab_set_distance(id, grab_get_distance(id) - flUnits)
}
