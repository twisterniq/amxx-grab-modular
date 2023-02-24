#include <amxmodx>
#include <reapi>
#include <grab_modular>

public stock const PluginName[] = "Grab: Notify"
public stock const PluginVersion[] = "2.1.0"
public stock const PluginAuthor[] = "twisterniq"

#define is_user_valid(%0) (1 <= %0 <= MaxClients)

enum _:CVars
{
    CVAR_ENABLED,
    CVAR_MSG_TYPE,
    CVAR_ONLY_PLAYERS,
    CVAR_PLAYER_RECEIVER,
    CVAR_NO_PLAYER_RECEIVER
}

enum _:MessageTypes
{
    MT_CHAT = 1,
    MT_PRINT_CENTER,
    MT_HUD,
    MT_DHUD
}

enum _:NotificationTypes
{
    NT_GRABBER = 1,
    NT_GRABBED,
    NT_GRABBER_GRABBED,
    NT_ALL
}

enum _:ReceiverType
{
    RT_ALL,
    RT_GRABBER
}

new g_iCVars[CVars]
new g_iSyncHud

public plugin_init()
{
    register_plugin(PluginName, PluginVersion, PluginAuthor)
    register_dictionary("grab_notify.txt")

    g_iSyncHud = CreateHudSyncObj()
    func_CreateCVars()
}

func_CreateCVars()
{
    bind_pcvar_num(
        create_cvar(
            .name = "grab_notify_enabled",
            .string = "1",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_CVAR_ENABLED"),
            .has_min = true,
            .min_val = 0.0,
            .has_max = true, 
            .max_val = 1.0
        ), g_iCVars[CVAR_ENABLED]
    )

    bind_pcvar_num(
        create_cvar(
            .name = "grab_notify_msg_type",
            .string = "1",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_NOTIFY_CVAR_MSG_TYPE"),
            .has_min = true,
            .min_val = 1.0,
            .has_max = true, 
            .max_val = 4.0
        ), g_iCVars[CVAR_MSG_TYPE]
    )

    bind_pcvar_num(
        create_cvar(
            .name = "grab_notify_only_players",
            .string = "0",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_NOTIFY_CVAR_ONLY_PLAYERS"),
            .has_min = true,
            .min_val = 0.0,
            .has_max = true, 
            .max_val = 1.0
        ), g_iCVars[CVAR_ONLY_PLAYERS]
    )

    bind_pcvar_num(
        create_cvar(
            .name = "grab_notify_player_receiver",
            .string = "3",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_NOTIFY_CVAR_PLAYER_RECEIVER"),
            .has_min = true,
            .min_val = 1.0,
            .has_max = true, 
            .max_val = 4.0
        ), g_iCVars[CVAR_PLAYER_RECEIVER]
    )

    bind_pcvar_num(
        create_cvar(
            .name = "grab_notify_no_player_receiver",
            .string = "0",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_NOTIFY_CVAR_NO_PLAYER_RECEIVER"),
            .has_min = true,
            .min_val = 0.0,
            .has_max = true, 
            .max_val = 1.0
        ), g_iCVars[CVAR_NO_PLAYER_RECEIVER]
    )

    AutoExecConfig(true, "grab_notify", "grab_modular")
}

public grab_on_start(id, iEnt)
{
    if (!g_iCVars[CVAR_ENABLED])
    {
        return
    }

    // Is target a player?
    if (is_user_valid(iEnt))
    {
        switch (g_iCVars[CVAR_PLAYER_RECEIVER])
        {
            case NT_GRABBER:
            {
                func_PrintMessage(id, iEnt, "%l", "GRAB_NOTIFY_MSG_TYPE_GRABBER", iEnt)
            }
            case NT_GRABBED:
            {
                func_PrintMessage(iEnt, id, "%l", "GRAB_NOTIFY_MSG_TYPE_GRABBED", id)
            }
            case NT_GRABBER_GRABBED:
            {
                func_PrintMessage(id, iEnt, "%l", "GRAB_NOTIFY_MSG_TYPE_GRABBER", iEnt)
                func_PrintMessage(iEnt, id, "%l", "GRAB_NOTIFY_MSG_TYPE_GRABBED", id)
            }
            case NT_ALL:
            {
                func_PrintMessage(0, iEnt, "%l", "GRAB_NOTIFY_MSG_TYPE_ALL", id, iEnt)
            }
        }
    }
    // Check non-player entities only if CVar is disabled
    else if (!g_iCVars[CVAR_ONLY_PLAYERS])
    {
        new szClassName[32]
        get_entvar(iEnt, var_classname, szClassName, charsmax(szClassName))

        new iReceiver = g_iCVars[CVAR_NO_PLAYER_RECEIVER]

        if (equal(szClassName, "weaponbox") || equal(szClassName, "armoury_entity"))
        {
            if (iReceiver == RT_ALL)
            {
                func_PrintMessage(0, id, "%l", "GRAB_NOTIFY_WEAPON_ALL", id)
            }
            else
            {
                func_PrintMessage(id, print_team_default, "%l", "GRAB_NOTIFY_WEAPON_GRABBER")
            }
        }
        else if (equal(szClassName, "weapon_shield"))
        {
            if (iReceiver == RT_ALL)
            {
                func_PrintMessage(0, id, "%l", "GRAB_NOTIFY_WEAPON_SHIELD_ALL", id)
                
            }
            else
            {
                func_PrintMessage(id, print_team_default, "%l", "GRAB_NOTIFY_WEAPON_SHIELD_GRABBER")
            }
        }
        else if (equal(szClassName, "func_vehicle"))
        {
            if (iReceiver == RT_ALL)
            {
                func_PrintMessage(0, id, "%l", "GRAB_NOTIFY_VEHICLE_ALL", id)
            }
            else
            {
                func_PrintMessage(id, print_team_default, "%l", "GRAB_NOTIFY_VEHICLE_GRABBER")
            }
        }
    }
}

func_PrintMessage(iReceiver, iSender, const szMessage[], any:...)
{
    switch (g_iCVars[CVAR_MSG_TYPE])
    {
        case MT_CHAT:
        {
            new szNewMessage[192]
            vformat(szNewMessage, charsmax(szNewMessage), szMessage, 4)

            client_print_color(iReceiver, iSender, szNewMessage)
        }
        case MT_PRINT_CENTER:
        {
            new szNewMessage[128]
            vformat(szNewMessage, charsmax(szNewMessage), szMessage, 4)
            replace_chat_symbols(szNewMessage, charsmax(szNewMessage))

            client_print(iReceiver, print_center, szNewMessage)
        }
        case MT_HUD:
        {
            new szNewMessage[256]
            vformat(szNewMessage, charsmax(szNewMessage), szMessage, 4)
            replace_chat_symbols(szNewMessage, charsmax(szNewMessage))

            set_hudmessage(255, 255, 255, -1.0, 0.70, 0, 0.0, 2.0, 0.0, 3.0, -1)
            ShowSyncHudMsg(iReceiver, g_iSyncHud, szNewMessage)
        }
        case MT_DHUD:
        {
            new szNewMessage[128]
            vformat(szNewMessage, charsmax(szNewMessage), szMessage, 4)
            replace_chat_symbols(szNewMessage, charsmax(szNewMessage))

            set_dhudmessage(255, 255, 255, -1.0, 0.70, 0, 0.0, 0.3, 0.0, 1.0)
            show_dhudmessage(iReceiver, szNewMessage)
        }
    }
}

stock replace_chat_symbols(szMessage[], iLen)
{
    replace(szMessage, iLen, "* ", "")
    replace_all(szMessage, iLen, "^1", "")
    replace_all(szMessage, iLen, "^3", "")
    replace_all(szMessage, iLen, "^4", "")
}
