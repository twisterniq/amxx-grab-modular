#include <amxmodx>
#include <hamsandwich>
#include <reapi>
#include <grab_modular>

public stock const PluginName[] = "Grab: Push"
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
    bool:PUSH_CMD,
    bool:PUSH_MOUSE
}

new const WEAPON_NAMES[][] = 
{
    "weapon_knife",
    "weapon_shield",
    "weapon_glock18",
    "weapon_usp",
    "weapon_famas",
    "weapon_awp",
    "weapon_sg550",
    "weapon_g3sg1",
    "weapon_scout"
}

new g_eCVars[CVars]
new g_ePlayerData[MAX_PLAYERS + 1][PlayerStruct]

public plugin_init()
{
    register_plugin(PluginName, PluginVersion, PluginAuthor)
    register_dictionary("grab_push.txt")

    register_clcmd("+push", "clcmd_PushEnabled")
    register_clcmd("-push", "clcmd_PushDisabled")

    RegisterHam(Ham_Item_GetWeaponPtr, "weapon_knife", "GetWeaponPtr_Pre", false)
    RegisterHam(Ham_Item_GetWeaponPtr, "weapon_usp", "GetWeaponPtr_Pre", false)

    for (new i; i < sizeof WEAPON_NAMES; i++)
    {
        RegisterHam(Ham_Weapon_SecondaryAttack, WEAPON_NAMES[i], "Weapon_SecondaryAttack_Pre", false)
    }

    RegisterHookChain(RG_CBasePlayer_Observer_IsValidTarget, "CBasePlayer_Observer_IsValidTarget_Pre", false)

    func_CreateCVars()
}

func_CreateCVars()
{
    bind_pcvar_num(
        create_cvar(
            .name = "grab_push_cmd",
            .string = "1",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_PUSH_CVAR_CMD"),
            .has_min = true,
            .min_val = 0.0,
            .has_max = true, 
            .max_val = 1.0
        ), g_eCVars[CVAR_CMD]
    )

    bind_pcvar_num(
        create_cvar(
            .name = "grab_push_mouse",
            .string = "1",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_PUSH_CVAR_MOUSE"),
            .has_min = true,
            .min_val = 0.0,
            .has_max = true, 
            .max_val = 1.0
        ), g_eCVars[CVAR_MOUSE]
    )

    bind_pcvar_float(
        create_cvar(
            .name = "grab_push_units_player",
            .string = "15.0",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_PUSH_CVAR_UNITS_PLAYER"),
            .has_min = true,
            .min_val = 0.1
        ), g_eCVars[CVAR_UNITS_PLAYER]
    )

    bind_pcvar_float(
        create_cvar(
            .name = "grab_push_units_no_player",
            .string = "1.0",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_PUSH_CVAR_UNITS_NO_PLAYER"),
            .has_min = true,
            .min_val = 0.1
        ), g_eCVars[CVAR_UNITS_NO_PLAYER]
    )

    AutoExecConfig(true, "grab_push", "grab_modular")
}

public client_disconnected(id)
{
    arrayset(g_ePlayerData[id], false, PlayerStruct)
}

public GetWeaponPtr_Pre(const iEnt)
{
    if (!g_eCVars[CVAR_MOUSE])
    {
        return
    }

    new id = get_member(iEnt, m_pPlayer)

    if (g_ePlayerData[id][GRABBING])
    {
        // Block animation
        set_member(iEnt, m_Weapon_flNextSecondaryAttack, 0.5)
    }
}

public Weapon_SecondaryAttack_Pre(const iEnt)
{
    if (!g_eCVars[CVAR_MOUSE])
    {
        return HAM_IGNORED
    }

    new id = get_member(iEnt, m_pPlayer)

    // Block zoom or other action assigned if player is grabbing
    return g_ePlayerData[id][GRABBING] ? HAM_SUPERCEDE : HAM_IGNORED
}

public CBasePlayer_Observer_IsValidTarget_Pre(const id, iPlayerIndex, bool:bSameTeam)
{
    if (g_ePlayerData[id][GRABBING])
    {
        // Don't allow to change target when player is (maybe) pushing
        SetHookChainArg(2, ATYPE_INTEGER, 0)
    }    
}

public clcmd_PushEnabled(const id)
{
    if (!g_eCVars[CVAR_CMD])
    {
        return PLUGIN_HANDLED
    }

    g_ePlayerData[id][PUSH_CMD] = true
    return PLUGIN_HANDLED
}

public clcmd_PushDisabled(const id)
{
    g_ePlayerData[id][PUSH_CMD] = false
    return PLUGIN_HANDLED
}

public grab_on_start(id, iEnt)
{
    g_ePlayerData[id][GRABBING] = true
}

public grab_on_finish(id, iEnt)
{
    g_ePlayerData[id][GRABBING] = false
}

public grab_on_grabbing(id, iEnt)
{
    if (!g_eCVars[CVAR_CMD] && !g_eCVars[CVAR_MOUSE])
    {
        return
    }

    if (g_ePlayerData[id][PUSH_CMD])
    {
        func_SetDistance(id, iEnt)
    }
    else
    {
        static iButton
        iButton = get_entvar(id, var_button)

        if (g_ePlayerData[id][PUSH_MOUSE])
        {
            // Player releases left click
            if (!(iButton & IN_ATTACK))
            {
                g_ePlayerData[id][PUSH_MOUSE] = false
            }
            else
            {
                func_SetDistance(id, iEnt)
            }
        }
        else
        {
            // Player is holding down left click
            if (iButton & IN_ATTACK)
            {
                g_ePlayerData[id][PUSH_MOUSE] = true
            }
        }
    }
}

func_SetDistance(id, iEnt)
{
    static Float:flUnits

    // Units will depend on whether the target is player or not
    flUnits = (1 <= iEnt <= MaxClients) ? g_eCVars[CVAR_UNITS_PLAYER] : g_eCVars[CVAR_UNITS_NO_PLAYER]

    grab_set_distance(id, grab_get_distance(id) + flUnits)
}
