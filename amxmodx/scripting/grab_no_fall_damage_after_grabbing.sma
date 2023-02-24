#include <amxmodx>
#include <reapi>
#include <grab_modular>

public stock const PluginName[] = "Grab: No Fall Damage After Grabbing"
public stock const PluginVersion[] = "2.0.0"
public stock const PluginAuthor[] = "twisterniq"

new g_iCVarEnabled
new bool:g_bPlayerInAir[MAX_PLAYERS + 1]

public plugin_init()
{
    register_plugin(PluginName, PluginVersion, PluginAuthor)

    RegisterHookChain(RG_CSGameRules_FlPlayerFallDamage, "CSGameRules_FlPlayerFallDamage_Pre", false)
    func_CreateCVars()
}

func_CreateCVars()
{
    bind_pcvar_num(
        create_cvar(
            .name = "grab_no_fall_damage_after_grabbing_enabled",
            .string = "1",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_CVAR_ENABLED"),
            .has_min = true,
            .min_val = 0.0,
            .has_max = true, 
            .max_val = 1.0
        ), g_iCVarEnabled
    )

    AutoExecConfig(true, "grab_no_fall_damage_after_grabbing", "grab_modular")
}

public grab_on_finish(id, iTarget)
{
    if (!g_iCVarEnabled)
    {
        return
    }

    if (!(1 <= iTarget <= MaxClients))
    {
        return
    }

    g_bPlayerInAir[iTarget] = !(get_entvar(iTarget, var_flags) & FL_ONGROUND)
}

public CSGameRules_FlPlayerFallDamage_Pre(const id)
{
    if (!g_bPlayerInAir[id])
    {
        return
    }

    g_bPlayerInAir[id] = false
    SetHookChainReturn(ATYPE_FLOAT, 0.0)
}

public client_disconnected(id)
{
    g_bPlayerInAir[id] = false
}
