#include <amxmodx>
#include <hamsandwich>
#include <grab_modular>

public stock const PluginName[] = "Grab Menu: Restart Ent"
public stock const PluginVersion[] = "1.0.0"
public stock const PluginAuthor[] = "twisterniq"

/****************************************************************************************
****************************************************************************************/

// Lang key of this item that will be displayed in the menu
new const ITEM_NAME[] = "GRAB_MENU_RESTART_ENT"

// Unique identificator of this item
new const ITEM_KEY[] = "restart_ent"

/****************************************************************************************
****************************************************************************************/

enum _:CVars
{
    CVAR_TEAM,
    CVAR_TARGET_TEAM,
    CVAR_ACCESS
}

new g_pCVars[CVars]
new g_iItemId

public plugin_init()
{
    register_plugin(PluginName, PluginVersion, PluginAuthor)
    register_dictionary("grab_menu_restart_ent.txt")

    func_CreateCVars()
}

func_CreateCVars()
{
    g_pCVars[CVAR_TEAM] = create_cvar(
        .name = "grab_menu_restart_ent_grabber_team",
        .string = "abc",
        .flags = FCVAR_NONE,
        .description = fmt("%L", LANG_SERVER, "GRAB_MENU_CVAR_GRABBER_TEAM")
    )

    g_pCVars[CVAR_TARGET_TEAM] = create_cvar(
        .name = "grab_menu_restart_ent_grabbed_team",
        .string = "c",
        .flags = FCVAR_NONE,
        .description = fmt("%L", LANG_SERVER, "GRAB_MENU_CVAR_GRABBED_TEAM")
    )

    g_pCVars[CVAR_ACCESS] = create_cvar(
        .name = "grab_menu_restart_ent_access",
        .string = "",
        .flags = FCVAR_NONE,
        .description = fmt("%L", LANG_SERVER, "GRAB_MENU_CVAR_ACCESS")
    )

    AutoExecConfig(true, "grab_menu_restart_ent", "grab_modular")
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

public grab_menu_item_selected(id, iTarget, iItemId)
{
    if (iItemId != g_iItemId)
    {
        return
    }

    if (1 <= iTarget <= MaxClients)
    {
        return
    }

    grab_disable(id)
    ExecuteHam(Ham_CS_Restart, iTarget)
}
