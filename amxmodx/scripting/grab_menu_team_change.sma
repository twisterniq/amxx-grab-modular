#include <amxmodx>
#include <reapi>
#include <grab_modular>

public stock const PluginName[] = "Grab Menu: Team Change"
public stock const PluginVersion[] = "2.0.0"
public stock const PluginAuthor[] = "twisterniq"

/****************************************************************************************
****************************************************************************************/

// Lang key of this item that will be displayed in the menu
new const ITEM_NAME[] = "GRAB_MENU_TEAM_CHANGE"

// Unique identificator of this item
new const ITEM_KEY[] = "team_change"

/****************************************************************************************
****************************************************************************************/

enum _:CVars
{
    CVAR_TEAM,
    CVAR_TARGET_TEAM,
    CVAR_ACCESS,

    CVAR_TO,
    CVAR_KILL,
    CVAR_RESPAWN
}

new g_pCVars[CVars]
new g_eCVars[CVars]

new g_iItemId

public plugin_init()
{
    register_plugin(PluginName, PluginVersion, PluginAuthor)
    register_dictionary("grab_menu_team_change.txt")

    func_CreateCVars()
}

func_CreateCVars()
{
    g_pCVars[CVAR_TEAM] = create_cvar(
        .name = "grab_menu_team_change_grabber_team",
        .string = "abc",
        .flags = FCVAR_NONE,
        .description = fmt("%L", LANG_SERVER, "GRAB_MENU_CVAR_GRABBER_TEAM")
    )

    g_pCVars[CVAR_TARGET_TEAM] = create_cvar(
        .name = "grab_menu_team_change_grabbed_team",
        .string = "ab",
        .flags = FCVAR_NONE,
        .description = fmt("%L", LANG_SERVER, "GRAB_MENU_CVAR_GRABBED_TEAM")
    )

    g_pCVars[CVAR_ACCESS] = create_cvar(
        .name = "grab_menu_team_change_access",
        .string = "",
        .flags = FCVAR_NONE,
        .description = fmt("%L", LANG_SERVER, "GRAB_MENU_CVAR_ACCESS")
    )

    bind_pcvar_num(
        create_cvar(
            .name = "grab_menu_team_change_to",
            .string = "4",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_MENU_TEAM_CHANGE_CVAR_TO"),
            .has_min = true,
            .min_val = 1.0,
            .has_max = true,
            .max_val = 4.0
        ), g_eCVars[CVAR_TO]
    )

    bind_pcvar_num(
        create_cvar(
            .name = "grab_menu_team_change_kill",
            .string = "1",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_MENU_TEAM_CHANGE_CVAR_KILL"),
            .has_min = true,
            .min_val = 0.0,
            .has_max = true,
            .max_val = 1.0
        ), g_eCVars[CVAR_KILL]
    )

    bind_pcvar_num(
        create_cvar(
            .name = "grab_menu_team_change_respawn",
            .string = "0",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_MENU_TEAM_CHANGE_CVAR_RESPAWN"),
            .has_min = true,
            .min_val = 0.0,
            .has_max = true,
            .max_val = 1.0
        ), g_eCVars[CVAR_RESPAWN]
    )

    AutoExecConfig(true, "grab_menu_team_change", "grab_modular")
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

    new TeamName:iTeam = TeamName:g_eCVars[CVAR_TO]

    if (get_member(iTarget, m_iTeam) == iTeam)
    {
        return
    }

    new bool:bKill = g_eCVars[CVAR_KILL] == 1

    if (bKill)
    {
        user_kill(iTarget)
    }

    if (TEAM_TERRORIST <= iTeam <= TEAM_SPECTATOR)
    {
        rg_set_user_team(iTarget, iTeam, .check_win_conditions = bKill)
    }
    else
    {
        rg_switch_team(iTarget)
    
        if (bKill)
        {
            rg_check_win_conditions()
        }
    }

    if (bKill && g_eCVars[CVAR_RESPAWN] && !get_member_game(m_bRoundTerminating))
    {
        RequestFrame("func_RespawnPlayer", iTarget)
    }

    client_print_color(0, iTarget, "%l", "GRAB_MENU_TEAM_CHANGE_MSG", id, iTarget)
}

public func_RespawnPlayer(const id)
{
    if (is_user_connected(id) && !is_user_alive(id) && !get_member_game(m_bRoundTerminating))
    {
        rg_round_respawn(id)
    }
}