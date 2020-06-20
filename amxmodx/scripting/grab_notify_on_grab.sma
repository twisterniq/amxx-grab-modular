#include <amxmodx>
#include <reapi>
#include <grab_modular>

#pragma semicolon 1

new const PLUGIN_NAME[] = "Grab: Notify on Grab";
new const PLUGIN_VERSION[] = "1.0.0";
new const PLUGIN_AUTHOR[] = "w0w";

/****************************************************************************************
****************************************************************************************/

#define is_user_valid(%0) (1 <= %0 <= MaxClients)

enum _:Cvars
{
	CVAR_ENABLED,
	CVAR_MSG_TYPE,
	CVAR_TYPE,
	CVAR_WEAPONS,
	CVAR_WEAPONS_TYPE
};

new g_eCvar[Cvars];

new g_iSyncHud;

public plugin_init()
{
	register_plugin(
		.plugin_name = PLUGIN_NAME,
		.version = PLUGIN_VERSION,
		.author = PLUGIN_AUTHOR
	);

	register_dictionary("grab_notify_on_grab.txt");

	g_iSyncHud = CreateHudSyncObj();

	func_RegisterCvars();
}

func_RegisterCvars()
{
	new pCvar;

	pCvar = create_cvar("grab_notify_on_grab_enabled", "1", FCVAR_NONE, fmt("%L", LANG_SERVER, "GRAB_NOTIFY_ON_GRAB_CVAR_ENABLED"), true, 0.0, true, 1.0);
	bind_pcvar_num(pCvar, g_eCvar[CVAR_ENABLED]);

	pCvar = create_cvar("grab_notify_on_grab_msg_type", "1", FCVAR_NONE, fmt("%L", LANG_SERVER, "GRAB_NOTIFY_ON_GRAB_CVAR_MSG_TYPE"), true, 1.0, true, 4.0);
	bind_pcvar_num(pCvar, g_eCvar[CVAR_MSG_TYPE]);

	pCvar = create_cvar("grab_notify_on_grab_type", "1", FCVAR_NONE, fmt("%L", LANG_SERVER, "GRAB_NOTIFY_ON_GRAB_CVAR_TYPE"), true, 1.0, true, 4.0);
	bind_pcvar_num(pCvar, g_eCvar[CVAR_TYPE]);

	pCvar = create_cvar("grab_notify_on_grab_weapons", "1", FCVAR_NONE, fmt("%L", LANG_SERVER, "GRAB_NOTIFY_ON_GRAB_CVAR_WEAPONS"), true, 0.0, true, 1.0);
	bind_pcvar_num(pCvar, g_eCvar[CVAR_WEAPONS]);

	pCvar = create_cvar("grab_notify_on_grab_weapons_type", "2", FCVAR_NONE, fmt("%L", LANG_SERVER, "GRAB_NOTIFY_ON_GRAB_CVAR_WEAPONS_TYPE"), true, 1.0, true, 2.0);
	bind_pcvar_num(pCvar, g_eCvar[CVAR_WEAPONS_TYPE]);

	AutoExecConfig(true, "grab_notify_on_grab", "grab_modular");
}

public grab_on_start(id, iEntity)
{
	if(!g_eCvar[CVAR_ENABLED])
		return;

	if(is_user_valid(iEntity))
	{
		switch(g_eCvar[CVAR_TYPE])
		{
			case 1:
			{
				func_PrintMessage(id, iEntity, "%l", "GRAB_NOTIFY_ON_GRAB_MSG_TYPE_GRABBER", iEntity);
			}
			case 2:
			{
				func_PrintMessage(iEntity, id, "%l", "GRAB_NOTIFY_ON_GRAB_MSG_TYPE_GRABBED", id);
			}
			case 3:
			{
				func_PrintMessage(id, iEntity, "%l", "GRAB_NOTIFY_ON_GRAB_MSG_TYPE_GRABBER", iEntity);
				func_PrintMessage(iEntity, id, "%l", "GRAB_NOTIFY_ON_GRAB_MSG_TYPE_GRABBED", id);
			}
			case 4:
			{
				func_PrintMessage(0, iEntity, "%l", "GRAB_NOTIFY_ON_GRAB_MSG_TYPE_ALL", id, iEntity);
			}
		}
	}
	else
	{
		if(!g_eCvar[CVAR_WEAPONS])
			return;

		new szClassName[32];
		get_entvar(iEntity, var_classname, szClassName, charsmax(szClassName));

		new iClient = g_eCvar[CVAR_WEAPONS_TYPE] ? id : 0;

		if(!strcmp(szClassName, "weaponbox") || !strcmp(szClassName, "armoury_entity"))
		{
			if(g_eCvar[CVAR_WEAPONS_TYPE] == 1)
				func_PrintMessage(iClient, iClient, "%l", "GRAB_NOTIFY_ON_GRAB_WEAPON_GRABBER");
			else
				func_PrintMessage(iClient, iClient, "%l", "GRAB_NOTIFY_ON_GRAB_WEAPON_ALL", id);
		}
		else if(!strcmp(szClassName, "weapon_shield"))
		{
			if(g_eCvar[CVAR_WEAPONS_TYPE] == 1)
				func_PrintMessage(iClient, iClient, "%l", "GRAB_NOTIFY_ON_GRAB_WEAPON_SHIELD_GRABBER");
			else
				func_PrintMessage(iClient, iClient, "%l", "GRAB_NOTIFY_ON_GRAB_WEAPON_SHIELD_ALL", id);
		}
	}
}

func_PrintMessage(id, id2, const szMessage[], any:...)
{
	switch(g_eCvar[CVAR_MSG_TYPE])
	{
		case 1:
		{
			new szNewMessage[192];
			vformat(szNewMessage, charsmax(szNewMessage), szMessage, 4);

			client_print_color(id, id2, szNewMessage);
		}
		case 2:
		{
			new szNewMessage[128];
			vformat(szNewMessage, charsmax(szNewMessage), szMessage, 4);
			replace_chat_symbols(szNewMessage, charsmax(szNewMessage));

			client_print(id, print_center, szNewMessage);
		}
		case 3:
		{
			new szNewMessage[512];
			vformat(szNewMessage, charsmax(szNewMessage), szMessage, 4);
			replace_chat_symbols(szNewMessage, charsmax(szNewMessage));

			set_hudmessage(255, 255, 255, -1.0, 0.70, 0, 0.0, 2.0, 0.0, 3.0, -1);
			ShowSyncHudMsg(id, g_iSyncHud, szNewMessage);
		}
		case 4:
		{
			new szNewMessage[128];
			vformat(szNewMessage, charsmax(szNewMessage), szMessage, 4);
			replace_chat_symbols(szNewMessage, charsmax(szNewMessage));

			set_dhudmessage(255, 255, 255, -1.0, 0.70, 0, 0.0, 0.3, 0.0, 1.0);
			show_dhudmessage(id, szNewMessage);
		}
	}
}

stock replace_chat_symbols(szMessage[], iLen)
{
	replace(szMessage, iLen, "* ", "");
	replace_all(szMessage, iLen, "^1", "");
	replace_all(szMessage, iLen, "^3", "");
	replace_all(szMessage, iLen, "^4", "");
}