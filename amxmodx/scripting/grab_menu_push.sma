#include <amxmodx>
#include <grab_modular>

public stock const PluginName[] = "Grab Menu: Push"
public stock const PluginVersion[] = "2.0.0"
public stock const PluginAuthor[] = "twisterniq"

/****************************************************************************************
****************************************************************************************/

// Lang key of this item that will be displayed in the menu
new const ITEM_NAME[] = "GRAB_MENU_PUSH"

// Unique identificator of this item
new const ITEM_KEY[] = "push"

/****************************************************************************************
****************************************************************************************/

enum _:CVars
{
    CVAR_TEAM,
    CVAR_TARGET_TEAM,
    CVAR_ACCESS
}

new g_pCVars[CVars]
new Float:g_flCVarUnits

new g_iItemId

public plugin_init()
{
    register_plugin(PluginName, PluginVersion, PluginAuthor)
    register_dictionary("grab_menu_push.txt")

    func_CreateCVars()
}

func_CreateCVars()
{
    g_pCVars[CVAR_TEAM] = create_cvar(
        .name = "grab_menu_push_grabber_team",
        .string = "abc",
        .flags = FCVAR_NONE,
        .description = fmt("%L", LANG_SERVER, "GRAB_MENU_CVAR_GRABBER_TEAM")
    )

    g_pCVars[CVAR_TARGET_TEAM] = create_cvar(
        .name = "grab_menu_push_grabbed_team",
        .string = "ab",
        .flags = FCVAR_NONE,
        .description = fmt("%L", LANG_SERVER, "GRAB_MENU_CVAR_GRABBED_TEAM")
    )

    g_pCVars[CVAR_ACCESS] = create_cvar(
        .name = "grab_menu_push_access",
        .string = "d",
        .flags = FCVAR_NONE,
        .description = fmt("%L", LANG_SERVER, "GRAB_MENU_CVAR_ACCESS")
    )

    bind_pcvar_float(
        create_cvar(
            .name = "grab_menu_push_units",
            .string = "15.0",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_MENU_PUSH_CVAR_UNITS"),
            .has_min = true,
            .min_val = 0.1
        ), g_flCVarUnits
    )

    AutoExecConfig(true, "grab_menu_push", "grab_modular")
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

public grab_menu_item_selected(id, iTarget, iItem)
{
    if(iItem != g_iItemId)
    {
        return
    }

    grab_set_distance(id, grab_get_distance(id) + g_flCVarUnits)
}
