#include <amxmodx>
#include <reapi>
#include <grab_modular>

public stock const PluginName[] = "Grab: Throw on Drop"
public stock const PluginVersion[] = "2.0.0"
public stock const PluginAuthor[] = "twisterniq"

enum _:CVars
{
    CVAR_ENABLED,
    CVAR_VELOCITY
}

new g_eCVars[CVars]

public plugin_init()
{
    register_plugin(PluginName, PluginVersion, PluginAuthor)
    register_dictionary("grab_throw_on_drop.txt")

    register_clcmd("drop", "clcmd_Drop")

    func_CreateCVars()
}

func_CreateCVars()
{
    bind_pcvar_num(
        create_cvar(
            .name = "grab_throw_on_drop_enabled",
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
            .name = "grab_throw_on_drop_velocity",
            .string = "1500",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_THROW_ON_DROP_CVAR_VELOCITY"),
            .has_min = true,
            .min_val = 1.0
        ), g_eCVars[CVAR_VELOCITY]
    )

    AutoExecConfig(true, "grab_throw_on_drop", "grab_modular")
}

public clcmd_Drop(const id)
{
    if (!g_eCVars[CVAR_ENABLED])
    {
        return PLUGIN_CONTINUE
    }

    new iTarget = grab_get_grabbed(id)

    if (!iTarget)
    {
        return PLUGIN_CONTINUE
    }

    new Float:flVelocity[3]
    velocity_by_aim(id, g_eCVars[CVAR_VELOCITY], flVelocity)

    set_entvar(iTarget, var_velocity, flVelocity)
    grab_disable(id)

    return PLUGIN_HANDLED
}
