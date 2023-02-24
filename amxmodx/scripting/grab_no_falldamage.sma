#include <amxmodx>
#include <reapi>
#include <grab_modular>

public stock const PluginName[] = "Grab: No Fall Damage"
public stock const PluginVersion[] = "2.1.0"
public stock const PluginAuthor[] = "twisterniq"

enum _:CVars
{
    CVAR_AFTER_GRABBING,
    CVAR_ON_GRABBING
}

new g_iCVars[CVars]
new bool:g_bPlayerInAir[MAX_PLAYERS + 1]

public plugin_init()
{
    register_plugin(PluginName, PluginVersion, PluginAuthor)
    register_dictionary("grab_no_falldamage.txt")

    RegisterHookChain(RG_CSGameRules_FlPlayerFallDamage, "CSGameRules_FlPlayerFallDamage_Pre", false)
    func_CreateCVars()
}

func_CreateCVars()
{
    bind_pcvar_num(
        create_cvar(
            .name = "grab_no_falldamage_after_grabbing",
            .string = "1",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_NO_FALLDAMAGE_AFTER_GRABBING"),
            .has_min = true,
            .min_val = 0.0,
            .has_max = true, 
            .max_val = 1.0
        ), g_iCVars[CVAR_AFTER_GRABBING]
    )

    bind_pcvar_num(
        create_cvar(
            .name = "grab_no_falldamage_on_grabbing",
            .string = "1",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_NO_FALLDAMAGE_ON_GRABBING"),
            .has_min = true,
            .min_val = 0.0,
            .has_max = true, 
            .max_val = 1.0
        ), g_iCVars[CVAR_ON_GRABBING]
    )

    AutoExecConfig(true, "grab_no_fall_damage", "grab_modular")
}

public grab_on_finish(id, iTarget)
{
    if (!g_iCVars[CVAR_AFTER_GRABBING])
    {
        // Function 'no fall damage after grabbing' is disabled
        return
    }

    if (!(1 <= iTarget <= MaxClients))
    {
        // Target is not a player
        return
    }

    g_bPlayerInAir[iTarget] = !(get_entvar(iTarget, var_flags) & FL_ONGROUND)
}

public CSGameRules_FlPlayerFallDamage_Pre(const id)
{
    if (g_iCVars[CVAR_ON_GRABBING] && grab_get_grabber(id))
    {
        SetHookChainReturn(ATYPE_FLOAT, 0.0)
        return
    }

    if (g_iCVars[CVAR_AFTER_GRABBING] && g_bPlayerInAir[id])
    {
        g_bPlayerInAir[id] = false
        SetHookChainReturn(ATYPE_FLOAT, 0.0)
    }
}

public client_disconnected(id)
{
    g_bPlayerInAir[id] = false
}
