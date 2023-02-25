#include <amxmodx>
#include <reapi>
#include <grab_modular>

public stock const PluginName[] = "Grab: Rendering"
public stock const PluginVersion[] = "2.1.0"
public stock const PluginAuthor[] = "twisterniq"

enum _:CVars
{
    CVAR_ENABLED,
    Float:CVAR_RED,
    Float:CVAR_GREEN,
    Float:CVAR_BLUE,
    Float:CVAR_AMOUNT,
    CVAR_SAVE
}

enum _:RenderStruct
{
    Float:RENDER_COLOR_R,
    Float:RENDER_COLOR_G,
    Float:RENDER_COLOR_B,
    RENDER_FX,
    RENDER_MODE,
    Float:RENDER_AMOUNT
}

new g_eCVars[CVars]
new g_eRenderData[MAX_PLAYERS + 1][RenderStruct]

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

    bind_pcvar_num(
        create_cvar(
            .name = "grab_rendering_save",
            .string = "1",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_RENDERING_CVAR_SAVE"),
            .has_min = true,
            .min_val = 0.0,
            .has_max = true, 
            .max_val = 1.0
        ), g_eCVars[CVAR_SAVE]
    )

    AutoExecConfig(true, "grab_rendering", "grab_modular")
}

public plugin_natives()
{
    register_native("grab_set_user_rendering", "native_grab_set_user_rendering")
    register_native("grab_get_user_rendering", "native_grab_get_user_rendering")
}

public bool:native_grab_set_user_rendering()
{
    enum { arg_player = 1, arg_red, arg_green, arg_blue, arg_fx, arg_mode, arg_amount }

    new id = get_param(arg_player)

    new Float:flRed = floatclamp(float(get_param(arg_red)), -1.0, 255.0)
    new Float:flGreen = floatclamp(float(get_param(arg_green)), -1.0, 255.0)
    new Float:flBlue = floatclamp(float(get_param(arg_blue)), -1.0, 255.0)
    new iFx = get_param(arg_fx)
    new iMode = get_param(arg_mode)
    new Float:flAmount = floatclamp(float(get_param(arg_amount)), -1.0, 255.0)

    if (id)
    {
        if (!is_user_valid(id))
        {
            log_error(AMX_ERR_NATIVE, "Player out of range (%d).", id)
            return false
        }

        func_SetUserRendering(id, flRed, flGreen, flBlue, iFx, iMode, flAmount)
    }
    else
    {
        for (new i = 1; i <= MaxClients; i++)
        {
            if (is_user_connected(i))
            {
                func_SetUserRendering(i, flRed, flGreen, flBlue, iFx, iMode, flAmount)
            }
        }
    }

    return true
}

public bool:native_grab_get_user_rendering()
{
    enum { arg_player = 1, arg_red, arg_green, arg_blue, arg_fx, arg_mode, arg_amount }

    new id = get_param(arg_player)

    if (!is_user_valid(id))
    {
        log_error(AMX_ERR_NATIVE, "Player out of range (%d).", id)
        return false
    }

    set_param_byref(arg_red, floatround(g_eRenderData[id][RENDER_COLOR_R]))
    set_param_byref(arg_green, floatround(g_eRenderData[id][RENDER_COLOR_G]))
    set_param_byref(arg_blue, floatround(g_eRenderData[id][RENDER_COLOR_B]))
    set_param_byref(arg_fx, g_eRenderData[id][RENDER_FX])
    set_param_byref(arg_mode, g_eRenderData[id][RENDER_MODE])
    set_param_byref(arg_amount, floatround(g_eRenderData[id][RENDER_AMOUNT]))

    return true
}

func_SetUserRendering(const id, Float:flRed = -1.0, Float:flGreen = -1.0, Float:flBlue = -1.0, iFx = -1, iMode = -1, Float:flAmount = -1.0)
{
    g_eRenderData[id][RENDER_COLOR_R] = flRed >= 0.0 ? flRed : g_eCVars[CVAR_RED]
    g_eRenderData[id][RENDER_COLOR_G] = flGreen >= 0.0 ? flGreen : g_eCVars[CVAR_GREEN]
    g_eRenderData[id][RENDER_COLOR_B] = flBlue >= 0.0 ? flBlue : g_eCVars[CVAR_BLUE]
    g_eRenderData[id][RENDER_FX] = iFx >= kRenderFxNone ? iFx : kRenderFxGlowShell
    g_eRenderData[id][RENDER_MODE] = iMode >= kRenderNormal ? iMode : kRenderNormal
    g_eRenderData[id][RENDER_AMOUNT] = flAmount >= 0.0 ? flAmount : g_eCVars[CVAR_AMOUNT]

    new iTarget = grab_get_grabbed(id)

    if (iTarget)
    {
        // Set new rendering in case player if grabbing something or someone
        func_ApplyRendering(id, iTarget)
    }
}

public client_putinserver(id)
{
    // Set default rendering for player
    func_SetUserRendering(id)
}

public grab_on_start(id, iEnt)
{
    if (!g_eCVars[CVAR_ENABLED])
    {
        return
    }

    func_ApplyRendering(id, iEnt)
}

public grab_on_finish(id, iEnt)
{
    if (!g_eCVars[CVAR_ENABLED])
    {
        return
    }

    if (!is_entity(iEnt))
    {
        // Entity no longer exists
        return
    }

    new bool:bRenderingAllowed = is_rendering_allowed(iEnt,
        g_eRenderData[id][RENDER_FX],
        g_eRenderData[id][RENDER_COLOR_R],
        g_eRenderData[id][RENDER_COLOR_G],
        g_eRenderData[id][RENDER_COLOR_B],
        g_eRenderData[id][RENDER_MODE],
        g_eRenderData[id][RENDER_AMOUNT]
    )

    if (bRenderingAllowed)
    {
        // Reset rendering
        rg_set_rendering(iEnt)
    }
}

func_ApplyRendering(const id, const iEnt)
{
    if (g_eCVars[CVAR_SAVE] && !is_rendering_allowed(iEnt))
    {
        // 'Save' setting is enabled and player already has a rendering
        // so it will no be changed
        return
    }

    rg_set_rendering(
        iEnt,
        g_eRenderData[id][RENDER_FX],
        g_eRenderData[id][RENDER_COLOR_R],
        g_eRenderData[id][RENDER_COLOR_G],
        g_eRenderData[id][RENDER_COLOR_B],
        g_eRenderData[id][RENDER_MODE],
        g_eRenderData[id][RENDER_AMOUNT]
    )
}

stock bool:is_user_valid(const id)
{
    return (id > 0 && id <= MaxClients)
}

stock bool:is_rendering_allowed(const id, iFx = kRenderFxNone, Float:flRed = 0.0, Float:flGreen = 0.0, Float:flBlue = 0.0, iMode = kRenderNormal, Float:flAmount = 0.0)
{
    new iRenderFx, Float:flColor[3], iRenderMode, Float:flAmountCurr
    rg_get_rendering(id, iRenderFx, flColor, iRenderMode, flAmountCurr)

    return (
        iRenderFx == iFx
        && flColor[0] == flRed
        && flColor[1] == flGreen
        && flColor[2] == flBlue
        && iRenderMode == iMode
        && flAmountCurr == flAmount
    )
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
