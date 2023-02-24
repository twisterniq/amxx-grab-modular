#include <amxmodx>
#include <reapi>
#include <grab_modular>

public stock const PluginName[] = "Grab: Rendering"
public stock const PluginVersion[] = "2.0.0"
public stock const PluginAuthor[] = "twisterniq"

enum _:CVars
{
    CVAR_ENABLED,
    Float:CVAR_RED,
    Float:CVAR_GREEN,
    Float:CVAR_BLUE,
    Float:CVAR_AMOUNT
}

new g_eCVars[CVars]

public plugin_init()
{
    register_plugin(PluginName, PluginVersion, PluginAuthor)
    register_dictionary("grab_rendering.txt")

    func_CreateCVars()
}

func_CreateCVars()
{
    bind_pcvar_num(
        create_cvar(
            .name = "grab_rendering_enabled",
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
            .name = "grab_rendering_red",
            .string = "255",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_RENDERING_CVAR_RED"),
            .has_min = true,
            .min_val = 0.0,
            .has_max = true, 
            .max_val = 255.0
        ), g_eCVars[CVAR_RED]
    )

    bind_pcvar_float(
        create_cvar(
            .name = "grab_rendering_green",
            .string = "255",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_RENDERING_CVAR_GREEN"),
            .has_min = true,
            .min_val = 0.0,
            .has_max = true, 
            .max_val = 255.0
        ), g_eCVars[CVAR_GREEN]
    )

    bind_pcvar_float(
        create_cvar(
            .name = "grab_rendering_blue",
            .string = "255",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_RENDERING_CVAR_BLUE"),
            .has_min = true,
            .min_val = 0.0,
            .has_max = true, 
            .max_val = 255.0
        ), g_eCVars[CVAR_BLUE]
    )

    bind_pcvar_float(
        create_cvar(
            .name = "grab_rendering_amount",
            .string = "128",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_RENDERING_CVAR_AMOUNT"),
            .has_min = true,
            .min_val = 0.0,
            .has_max = true, 
            .max_val = 255.0
        ), g_eCVars[CVAR_AMOUNT]
    )

    AutoExecConfig(true, "grab_rendering", "grab_modular")
}

public grab_on_start(id, iEnt)
{
    if (!g_eCVars[CVAR_ENABLED])
    {
        return
    }

    new iRenderFx, Float:flRenderColor[3], iRenderMode, Float:flAmount
    rg_get_rendering(iEnt, iRenderFx, flRenderColor, iRenderMode, flAmount)

    if (
        iRenderFx == kRenderFxNone
        && flRenderColor[0] == 0.0
        && flRenderColor[1] == 0.0
        && flRenderColor[2] == 0.0
        && iRenderMode == kRenderNormal
        && flAmount == 0.0
    )
    {
        rg_set_rendering(
            iEnt,
            kRenderFxGlowShell,
            g_eCVars[CVAR_RED],
            g_eCVars[CVAR_GREEN],
            g_eCVars[CVAR_BLUE],
            kRenderNormal,
            g_eCVars[CVAR_AMOUNT]
        )
    }
}

public grab_on_finish(id, iEnt)
{
    if (!g_eCVars[CVAR_ENABLED])
    {
        return
    }

    // Entity no longer exists
    if (!is_entity(iEnt))
    {
        return
    }

    new iRenderFx, Float:flRenderColor[3], iRenderMode, Float:flAmount
    rg_get_rendering(iEnt, iRenderFx, flRenderColor, iRenderMode, flAmount)

    if (
        iRenderFx == kRenderFxGlowShell
        && flRenderColor[0] == g_eCVars[CVAR_RED]
        && flRenderColor[1] == g_eCVars[CVAR_GREEN]
        && flRenderColor[2] == g_eCVars[CVAR_BLUE]
        && iRenderMode == kRenderNormal
        && flAmount == g_eCVars[CVAR_AMOUNT]
    )
    {
        // Reset rendering
        rg_set_rendering(iEnt)
    }
}

stock rg_get_rendering(id, &iRenderFx = kRenderFxNone, Float:flRenderColor[3] = { 0.0, 0.0, 0.0 }, &iRenderMode = kRenderNormal, &Float:flAmount = 0.0)
{
    get_entvar(id, var_rendercolor, flRenderColor)
    iRenderFx = get_entvar(id, var_renderfx)
    iRenderMode = get_entvar(id, var_rendermode)
    get_entvar(id, var_renderamt, flAmount)
}

stock rg_set_rendering(id, iRenderFx = kRenderFxNone, Float:flRed = 0.0, Float:flGreen = 0.0, Float:flBlue = 0.0, iRender = kRenderNormal, Float:flAmount = 0.0)
{
    new Float:flRenderColor[3]
    flRenderColor[0] = flRed
    flRenderColor[1] = flGreen
    flRenderColor[2] = flBlue

    set_entvar(id, var_renderfx, iRenderFx)
    set_entvar(id, var_rendercolor, flRenderColor)
    set_entvar(id, var_rendermode, iRender)
    set_entvar(id, var_renderamt, flAmount)
}
