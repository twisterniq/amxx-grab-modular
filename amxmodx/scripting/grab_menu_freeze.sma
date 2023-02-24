#include <amxmodx>
#include <reapi>
#include <grab_modular>

public stock const PluginName[] = "Grab Menu: Freeze"
public stock const PluginVersion[] = "2.0.0"
public stock const PluginAuthor[] = "twisterniq"

/****************************************************************************************
****************************************************************************************/

// Lang key of this item that will be displayed in the menu
new const ITEM_NAME[] = "GRAB_MENU_FREEZE"

// Unique identificator of this item
new const ITEM_KEY[] = "freeze"

// Path to sound that will be played when player is frozen
new const FREEZE_SOUND[] = "grab_freeze.wav"

// Path to sound that will be played when player is unfrozen
new const UNFREEZE_SOUND[] = "grab_unfreeze.wav"

/****************************************************************************************
****************************************************************************************/

#define is_user_valid(%0) (1 <= %0 <= MaxClients)

enum _:CVars
{
    CVAR_TEAM,
    CVAR_TARGET_TEAM,
    CVAR_ACCESS,

    CVAR_UNSET_TYPE,
    Float:CVAR_COLOR_RED,
    Float:CVAR_COLOR_GREEN,
    Float:CVAR_COLOR_BLUE,
    Float:CVAR_AMOUNT
}

enum _:FreezeTypes
{
    FT_START = 1,
    FT_SELECT
}

new g_pCVars[CVars]
new g_eCVars[CVars]

new g_iItemId

public plugin_precache()
{
    register_plugin(PluginName, PluginVersion, PluginAuthor)

    precache_sound(FREEZE_SOUND)
    precache_sound(UNFREEZE_SOUND)
}

public plugin_init()
{
    register_dictionary("grab_menu_freeze.txt")
    func_CreateCVars()
}

func_CreateCVars()
{
    g_pCVars[CVAR_TEAM] = create_cvar(
        .name = "grab_menu_freeze_grabber_team",
        .string = "abc",
        .flags = FCVAR_NONE,
        .description = fmt("%L", LANG_SERVER, "GRAB_MENU_CVAR_GRABBER_TEAM")
    )

    g_pCVars[CVAR_TARGET_TEAM] = create_cvar(
        .name = "grab_menu_freeze_grabbed_team",
        .string = "ab",
        .flags = FCVAR_NONE,
        .description = fmt("%L", LANG_SERVER, "GRAB_MENU_CVAR_GRABBED_TEAM")
    )

    g_pCVars[CVAR_ACCESS] = create_cvar(
        .name = "grab_menu_freeze_access",
        .string = "d",
        .flags = FCVAR_NONE,
        .description = fmt("%L", LANG_SERVER, "GRAB_MENU_CVAR_ACCESS")
    )

    bind_pcvar_num(
        create_cvar(
            .name = "grab_menu_freeze_unset_type",
            .string = "1",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_MENU_FREEZE_CVAR_UNSET_TYPE"),
            .has_min = true,
            .min_val = 1.0,
            .has_max = true,
            .max_val = 2.0
        ), g_eCVars[CVAR_UNSET_TYPE]
    )

    bind_pcvar_float(
        create_cvar(
            .name = "grab_menu_freeze_color_red",
            .string = "0",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_MENU_FREEZE_CVAR_COLOR_RED"),
            .has_min = true,
            .min_val = 0.0,
            .has_max = true,
            .max_val = 255.0
        ), g_eCVars[CVAR_COLOR_RED]
    )

    bind_pcvar_float(
        create_cvar(
            .name = "grab_menu_freeze_color_green",
            .string = "100",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_MENU_FREEZE_CVAR_COLOR_GREEN"),
            .has_min = true,
            .min_val = 0.0,
            .has_max = true,
            .max_val = 255.0
        ), g_eCVars[CVAR_COLOR_GREEN]
    )

    bind_pcvar_float(
        create_cvar(
            .name = "grab_menu_freeze_color_blue",
            .string = "200",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_MENU_FREEZE_CVAR_COLOR_BLUE"),
            .has_min = true,
            .min_val = 0.0,
            .has_max = true,
            .max_val = 255.0
        ), g_eCVars[CVAR_COLOR_BLUE]
    )

    bind_pcvar_float(
        create_cvar(
            .name = "grab_menu_freeze_amount",
            .string = "30",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_MENU_FREEZE_CVAR_AMOUNT"),
            .has_min = true,
            .min_val = 0.0,
            .has_max = true,
            .max_val = 255.0
        ), g_eCVars[CVAR_AMOUNT]
    )

    AutoExecConfig(true, "grab_menu_freeze", "grab_modular")
}

public OnConfigsExecuted()
{
    new szGrabberTeam[4]
    get_pcvar_string(g_pCVars[CVAR_TEAM], szGrabberTeam, charsmax(szGrabberTeam))

    new szGrabbedTeam[4]
    get_pcvar_string(g_pCVars[CVAR_TARGET_TEAM], szGrabbedTeam, charsmax(szGrabbedTeam))

    new szAccess[GRAB_MENU_MAX_ACCESS_LENGTH]
    get_pcvar_string(g_pCVars[CVAR_ACCESS], szAccess, charsmax(szAccess))

    g_iItemId = grab_menu_add_item(
        .name = fmt("%L", LANG_SERVER, ITEM_NAME),
        .key = ITEM_KEY,
        .grabber_team = GrabItemTeam:read_flags(szGrabberTeam),
        .grabbed_team = GrabItemTeam:read_flags(szGrabbedTeam),
        .access = szAccess
    )
}

public grab_on_start(id, iTarget)
{
    if (g_eCVars[CVAR_UNSET_TYPE] == FT_SELECT)
    {
        return
    }

    if (!func_CheckPlayer(iTarget))
    {
        return
    }

    func_FreezePlayer(id, iTarget, false)
}

public grab_on_finish(id, iTarget)
{
    if (g_eCVars[CVAR_UNSET_TYPE] == FT_START)
    {
        return
    }

    if (!func_CheckPlayer(iTarget))
    {
        return
    }

    rg_set_rendering(iTarget,
        kRenderFxGlowShell,
        g_eCVars[CVAR_COLOR_RED],
        g_eCVars[CVAR_COLOR_GREEN],
        g_eCVars[CVAR_COLOR_BLUE],
        kRenderNormal,
        g_eCVars[CVAR_AMOUNT]
    )
}

bool:func_CheckPlayer(const id)
{
    return is_user_valid(id) && get_entvar(id, var_flags) & FL_FROZEN
}

public grab_menu_item_show(id, iTarget, iItemId)
{
    if (iItemId != g_iItemId)
    {
        return
    }

    if (g_eCVars[CVAR_UNSET_TYPE] == FT_START)
    {
        return
    }

    new bool:bFreeze = bool:(get_entvar(iTarget, var_flags) & FL_FROZEN)
    grab_menu_set_item_info(id, iItemId, GRAB_PROP_NAME, "%L", id, bFreeze ? "GRAB_MENU_FREEZE_UNSET" : "GRAB_MENU_FREEZE")
}

public grab_menu_item_selected(id, iTarget, iItemId)
{
    if (iItemId != g_iItemId)
    {
        return
    }

    new bool:bFrozen = bool:(get_entvar(iTarget, var_flags) & FL_FROZEN)

    if (!bFrozen)
    {
        func_FreezePlayer(id, iTarget, true)
        return
    }

    if (g_eCVars[CVAR_UNSET_TYPE] == FT_SELECT && bFrozen)
    {
        func_FreezePlayer(id, iTarget, false)
    }
}

func_FreezePlayer(id, iTarget, bool:bFreeze)
{
    if (bFreeze)
    {
        set_entvar(iTarget, var_flags, get_entvar(iTarget, var_flags) | FL_FROZEN)
        client_print_color(0, iTarget, "%l", "GRAB_MENU_FREEZE_MSG", id, iTarget)
        rh_emit_sound2(id, 0, CHAN_ITEM, FREEZE_SOUND, 0.5, ATTN_NORM, 0, PITCH_NORM)

        rg_set_rendering(iTarget,
            kRenderFxGlowShell,
            g_eCVars[CVAR_COLOR_RED],
            g_eCVars[CVAR_COLOR_GREEN],
            g_eCVars[CVAR_COLOR_BLUE],
            kRenderNormal,
            g_eCVars[CVAR_AMOUNT]
        )
    }
    else
    {
        set_entvar(iTarget, var_flags, get_entvar(iTarget, var_flags) & ~FL_FROZEN)
        client_print_color(0, iTarget, "%l", "GRAB_MENU_FREEZE_UNSET_MSG", id, iTarget)
        rh_emit_sound2(id, 0, CHAN_ITEM, UNFREEZE_SOUND, 0.5, ATTN_NORM, 0, PITCH_NORM)

        new iRenderFx, Float:flRenderColor[3], iRenderMode, Float:flAmount
        rg_get_rendering(iTarget, iRenderFx, flRenderColor, iRenderMode, flAmount)

        if (
            iRenderFx == kRenderFxGlowShell
            && flRenderColor[0] == g_eCVars[CVAR_COLOR_RED]
            && flRenderColor[1] == g_eCVars[CVAR_COLOR_GREEN]
            && flRenderColor[2] == g_eCVars[CVAR_COLOR_BLUE]
            && iRenderMode == kRenderNormal
            && flAmount == g_eCVars[CVAR_AMOUNT]
        )
        {
            rg_set_rendering(iTarget)
        }
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
