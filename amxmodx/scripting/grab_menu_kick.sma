#include <amxmodx>
#include <reapi>
#include <grab_modular>

public stock const PluginName[] = "Grab Menu: Kick"
public stock const PluginVersion[] = "2.0.0"
public stock const PluginAuthor[] = "twisterniq"

/****************************************************************************************
****************************************************************************************/

// Lang key of this item that will be displayed in the menu
new const ITEM_NAME[] = "GRAB_MENU_KICK"

// Unique identificator of this item
new const ITEM_KEY[] = "kick"

/****************************************************************************************
****************************************************************************************/

enum _:CVars
{
    CVAR_TEAM,
    CVAR_TARGET_TEAM,
    CVAR_ACCESS
}

new g_pCVars[CVars]
new g_szReason[128]

new g_iItemId

public plugin_init()
{
    register_plugin(PluginName, PluginVersion, PluginAuthor)
    register_dictionary("grab_menu_kick.txt")

    func_CreateCVars()
}

func_CreateCVars()
{
    g_pCVars[CVAR_TEAM] = create_cvar(
        .name = "grab_menu_kick_grabber_team",
        .string = "abc",
        .flags = FCVAR_NONE,
        .description = fmt("%L", LANG_SERVER, "GRAB_MENU_CVAR_GRABBER_TEAM")
    )

    g_pCVars[CVAR_TARGET_TEAM] = create_cvar(
        .name = "grab_menu_kick_grabbed_team",
        .string = "ab",
        .flags = FCVAR_NONE,
        .description = fmt("%L", LANG_SERVER, "GRAB_MENU_CVAR_GRABBED_TEAM")
    )

    g_pCVars[CVAR_ACCESS] = create_cvar(
        .name = "grab_menu_kick_access",
        .string = "d",
        .flags = FCVAR_NONE,
        .description = fmt("%L", LANG_SERVER, "GRAB_MENU_CVAR_ACCESS")
    )

    bind_pcvar_string(
        create_cvar(
            .name = "grab_menu_kick_reason",
            .string = "You've been kicked by admin",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_MENU_KICK_CVAR_REASON")
        ), g_szReason, charsmax(g_szReason)
    )

    AutoExecConfig(true, "grab_menu_kick", "grab_modular")
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
    if (iItem != g_iItemId)
    {
        return
    }

    client_print_color(0, iTarget, "%l", "GRAB_MENU_KICK_MSG", id, iTarget)
    rh_drop_client(iTarget, g_szReason)
}
