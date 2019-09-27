#include <amxmodx>
#include <reapi>
#include <grab_modular>
#include <grab_menu>

new const PLUGIN_NAME[] = "Grab Menu: Core";
new const PLUGIN_VERSION[] = "1.0.2";
new const PLUGIN_AUTHOR[] = "w0w";

/****************************************************************************************
****************************************************************************************/

#define is_user_valid(%0) (1 <= %0 <= MaxClients)

const ITEMS_PER_PAGE = 8;

enum _:Cvars
{
	CVAR_ENABLED,
	CVAR_CLOSE
};

new g_eCvar[Cvars];

new g_iMenuId;

enum _:MenuData
{
	MENU_NAME[MAX_MENUNAME_LENGTH],
	MENU_KEY[MAX_MENUKEY_LENGTH],
	GrabItemTeam:MENU_TEAM,
	GrabItemTeam:MENU_TARGET_TEAM,
	MENU_ACCESS
};

new Array:g_aMenuItems;

new g_iMenuPosition[MAX_PLAYERS+1];

enum _:Forwards
{
	FORWARD_MENU_OPENED,
	FORWARD_MENU_ON_ITEM_SHOW,
	FORWARD_MENU_ITEM_SELECTED,
};

new g_iForward[Forwards];

new Array:g_aPlayerMenuItems[MAX_PLAYERS+1];

public plugin_init()
{
	register_plugin(
		.plugin_name = PLUGIN_NAME,
		.version = PLUGIN_VERSION,
		.author = PLUGIN_AUTHOR
	);

	register_dictionary("grab_menu_core.txt");
	register_dictionary("common.txt");

	register_menucmd(g_iMenuId = register_menuid("func_GrabMenu"), 1023, "func_GrabMenu_Handler");

	g_iForward[FORWARD_MENU_OPENED] = CreateMultiForward("grab_menu_opened", ET_STOP, FP_CELL, FP_CELL);
	g_iForward[FORWARD_MENU_ON_ITEM_SHOW] = CreateMultiForward("grab_menu_on_item_show", ET_STOP, FP_CELL, FP_CELL, FP_CELL);
	g_iForward[FORWARD_MENU_ITEM_SELECTED] = CreateMultiForward("grab_menu_item_selected", ET_STOP, FP_CELL, FP_CELL, FP_CELL);

	RegisterHookChain(RH_SV_DropClient, "refwd_DropClient_Post", true);

	func_RegisterCvars();

	for(new i = 1; i <= MaxClients; i++)
		g_aPlayerMenuItems[i] = ArrayCreate();
}

func_RegisterCvars()
{
	new pCvar;

	pCvar = create_cvar("grab_menu_core_enabled", "1", FCVAR_NONE, fmt("%L", LANG_SERVER, "GRAB_MENU_CORE_CVAR_ENABLED"), true, 0.0, true, 1.0);
	bind_pcvar_num(pCvar, g_eCvar[CVAR_ENABLED]);

	pCvar = create_cvar("grab_menu_core_close", "1", FCVAR_NONE, fmt("%L", LANG_SERVER, "GRAB_MENU_CORE_CVAR_CLOSE"), true, 0.0, true, 1.0);
	bind_pcvar_num(pCvar, g_eCvar[CVAR_CLOSE]);

	AutoExecConfig(true, "grab_menu_core", "grab_modular/grab_menu");
}

public plugin_natives()
{
	g_aMenuItems = ArrayCreate(MenuData);

	register_library("grab_menu");

	register_native("grab_menu_open",				"NativeHandle_OpenMenu");
	register_native("grab_menu_add_item",			"NativeHandle_AddItem");
	register_native("grab_menu_get_item_info",		"NativeHandle_GetItemInfo");
	register_native("grab_menu_set_item_info", 		"NativeHandle_SetItemInfo");
	register_native("grab_menu_find_item_by_key",	"NativeHandle_FindItemByKey");
}

public bool:NativeHandle_OpenMenu(iPlugin, iParams)
{
	enum { arg_player = 1 };

	new iPlayer = get_param(arg_player);

	if(!is_user_valid(iPlayer))
		abort(AMX_ERR_NATIVE, "Player out of range (%d)", iPlayer);

	new iEnt = is_player_grabbing(iPlayer);

	if(!iEnt || !is_user_valid(iEnt))
		return false;

	func_GrabMenu(iPlayer, 0);
	return true;
}

public NativeHandle_AddItem(iPlugin, iParams)
{
	enum { arg_name = 1, arg_key, arg_team, arg_target_team, arg_access };

	new eMenuData[MenuData], szTeam[4];

	get_string(arg_name, eMenuData[MENU_NAME], charsmax(eMenuData[MENU_NAME]));

	get_string(arg_team, szTeam, charsmax(szTeam));
	eMenuData[MENU_TEAM] = GrabItemTeam:read_flags(szTeam);

	get_string(arg_target_team, szTeam, charsmax(szTeam));
	eMenuData[MENU_TARGET_TEAM] = GrabItemTeam:read_flags(szTeam);

	eMenuData[MENU_ACCESS] = get_param(arg_access);

	if(get_string(arg_key, eMenuData[MENU_KEY], charsmax(eMenuData[MENU_KEY]))
		&& ArrayFindString(g_aMenuItems, eMenuData[MENU_KEY]) != INVALID_HANDLE)
	{
		abort(AMX_ERR_NATIVE, "Key already exists (^"%s^")", eMenuData[MENU_KEY]);
	}

	return ArrayPushArray(g_aMenuItems, eMenuData) + 1;
}

public bool:NativeHandle_GetItemInfo(iPlugin, iParams)
{
	enum {
		arg_itemid = 1,
		arg_name,
		arg_name_length,
		arg_key,
		arg_key_length,
		arg_team,
		arg_access
	};

	new iItemInArray = get_param(arg_itemid) - 1;
	new iSize = ArraySize(g_aMenuItems);

	if(iItemInArray < 0 || iItemInArray > iSize)
		return false;

	new eMenuData[MenuData];
	ArrayGetArray(g_aMenuItems, iItemInArray, eMenuData);

	set_string(arg_name, eMenuData[MENU_NAME], get_param(arg_name_length));
	set_string(arg_key, eMenuData[MENU_KEY], get_param(arg_key_length));
	set_param_byref(arg_team, any:eMenuData[MENU_TEAM]);
	set_param_byref(arg_access, eMenuData[MENU_ACCESS]);

	return true;
}

public bool:NativeHandle_SetItemInfo(iPlugin, iParams)
{
	enum { arg_itemid = 1, arg_prop, arg_value, arg_vargs };

	new iItemInArray = get_param(arg_itemid) - 1;
	new iSize = ArraySize(g_aMenuItems);

	if(iItemInArray < 0 || iItemInArray > iSize)
		return false;

	new eMenuData[MenuData];
	ArrayGetArray(g_aMenuItems, iItemInArray, eMenuData);

	new iProp = get_param(arg_prop);

	switch(iProp)
	{
		case GRAB_PROP_NAME, GRAB_PROP_KEY:
		{
			vdformat(eMenuData[iProp], (iProp == any:GRAB_PROP_NAME ? MAX_MENUNAME_LENGTH : MAX_MENUKEY_LENGTH) - 1, arg_value, arg_vargs);
		}
		case GRAB_PROP_TEAM, GRAB_PROP_TARGET_TEAM, GRAB_PROP_ACCESS:
		{
			eMenuData[iProp] = get_param_byref(arg_value);
		}
		default:
		{
			return false;
		}
	}

	ArraySetArray(g_aMenuItems, iItemInArray, eMenuData);

	return true;
}

public NativeHandle_FindItemByKey(iPlugin, iParams)
{
	enum { arg_key = 1 };

	new szKey[MAX_MENUKEY_LENGTH];
	get_string(arg_key, szKey, charsmax(szKey));

	new iSize = ArraySize(g_aMenuItems);
	new eMenuData[MenuData];

	for(new i; i < iSize; i++)
	{
		ArrayGetArray(g_aMenuItems, i, eMenuData);

		if(!strcmp(eMenuData[MENU_KEY], szKey))
			return i + 1;
	}

	return 0;
}

public refwd_DropClient_Post(const id)
{
	ArrayDestroy(g_aPlayerMenuItems[id]);
}

public grab_on_start(id, iEntity)
{
	if(!g_eCvar[CVAR_ENABLED])
		return;

	if(!g_eCvar[CVAR_CLOSE] && func_IsMenuOpened(id, true))
		return;

	if(!is_user_valid(iEntity))
		return;

	func_GrabMenu(id, 0);
}

public grab_on_finish(id, iEntity)
{
	if(func_IsMenuOpened(id, false))
		show_menu(id, 0, "^n");
}

bool:func_IsMenuOpened(id, bool:bOtherMenu)
{
	new iMenu, iKeys;
	get_user_menu(id, iMenu, iKeys);

	if(bOtherMenu && get_member(id, m_iMenu) > Menu_OFF)
		return true;

	if(!iMenu)
		return false;

	return !bOtherMenu ? (iMenu == g_iMenuId) : (iMenu != g_iMenuId);
}

public func_GrabMenu(id, iPage)
{
	if(iPage < 0)
		return;

	new iTarget = is_player_grabbing(id);

	new iResult;
	ExecuteForward(g_iForward[FORWARD_MENU_OPENED], iResult, id, iTarget);

	if(iResult >= PLUGIN_HANDLED)
		return;

	SetGlobalTransTarget(id);

	ArrayClear(g_aPlayerMenuItems[id]);

	new iSize = ArraySize(g_aMenuItems);
	new eMenuData[MenuData];

	for(new i; i < iSize; i++)
	{
		ArrayGetArray(g_aMenuItems, i, eMenuData);

		if(eMenuData[MENU_TEAM] & GRAB_TEAM_T && get_member(id, m_iTeam) != TEAM_TERRORIST
			|| eMenuData[MENU_TEAM] & GRAB_TEAM_CT && get_member(id, m_iTeam) != TEAM_CT
			|| eMenuData[MENU_TEAM] & GRAB_TEAM_SPECTATOR && get_member(id, m_iTeam) != TEAM_SPECTATOR)
		{
			continue;
		}

		if(eMenuData[MENU_TARGET_TEAM] & GRAB_TEAM_T && get_member(iTarget, m_iTeam) != TEAM_TERRORIST
			|| eMenuData[MENU_TARGET_TEAM] & GRAB_TEAM_CT && get_member(iTarget, m_iTeam) != TEAM_CT
			|| eMenuData[MENU_TARGET_TEAM] & GRAB_TEAM_SPECTATOR && get_member(iTarget, m_iTeam) != TEAM_SPECTATOR)
		{
			continue;
		}

		new iResult;
		ExecuteForward(g_iForward[FORWARD_MENU_ON_ITEM_SHOW], iResult, id, iTarget, i + 1);

		if(iResult >= PLUGIN_HANDLED)
			continue;

		ArrayPushCell(g_aPlayerMenuItems[id], i);
	}

	new iItems = ArraySize(g_aPlayerMenuItems[id]);

	if(!iItems)
		return;

	new iStart = iPage * ITEMS_PER_PAGE;
	if(iStart > iItems)
		iStart = iItems;

	iStart = iStart - (iStart % ITEMS_PER_PAGE);
	g_iMenuPosition[id] = iStart / ITEMS_PER_PAGE;

	new iEnd = iStart + ITEMS_PER_PAGE;
	if(iEnd > iItems)
		iEnd = iItems;

	new szMenu[MAX_MENU_LENGTH], iLen, iKeys = (MENU_KEY_0), iMenuItem;
	new iPagesNum = (iItems / ITEMS_PER_PAGE + ((iItems % ITEMS_PER_PAGE) ? 1 : 0));
	new iItemId;

	if(iPagesNum > 1)
		iLen = formatex(szMenu, charsmax(szMenu), "^t^t^t^t^t\y%l \d%d/%d^n^n", "GRAB_MENU_CORE_TITLE", iTarget, iPage + 1, iPagesNum);
	else
		iLen = formatex(szMenu, charsmax(szMenu), "^t^t^t^t^t\y%l^n^n", "GRAB_MENU_CORE_TITLE", iTarget);

	for(new a = iStart; a < iEnd; a++)
	{
		iItemId = ArrayGetCell(g_aPlayerMenuItems[id], a);
		ArrayGetArray(g_aMenuItems, iItemId, eMenuData);

		if(eMenuData[MENU_ACCESS] == ADMIN_ALL || eMenuData[MENU_ACCESS] != ADMIN_ALL && get_user_flags(id) & eMenuData[MENU_ACCESS])
		{
			iKeys |= (1<<iMenuItem);
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^t^t^t^t^t\y%d. \w%s^n", ++iMenuItem, eMenuData[MENU_NAME]);
		}
		else
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^t^t^t^t^t\d%d. %s^n", ++iMenuItem, eMenuData[MENU_NAME]);
	}

	if(iEnd < iItems)
	{
		iKeys |= (MENU_KEY_9);
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^t^t^t^t^t\y9. \w%l^n^t^t^t^t^t\y0. \w%l", "MORE", iPage ? "BACK" : "EXIT");
	}
	else
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^t^t^t^t^t\y0. \w%l", iPage ? "BACK" : "EXIT");

	show_menu(id, iKeys, szMenu, -1, "func_GrabMenu");
}

public func_GrabMenu_Handler(id, iKey)
{
	switch(iKey)
	{
		case 8:
		{
			func_GrabMenu(id, ++g_iMenuPosition[id]);
		}
		case 9:
		{
			func_GrabMenu(id, --g_iMenuPosition[id]);
		}
		default:
		{
			new iSelectedItem = (g_iMenuPosition[id] * ITEMS_PER_PAGE) + iKey;
			new iItemInArray = ArrayGetCell(g_aPlayerMenuItems[id], iSelectedItem);

			new iEntity = is_player_grabbing(id);

			new iResult;
			ExecuteForward(g_iForward[FORWARD_MENU_ITEM_SELECTED], iResult, id, iEntity, iItemInArray + 1);

			if(iResult >= PLUGIN_HANDLED)
				return;

			if(!is_user_alive(iEntity))
				return;

			func_GrabMenu(id, g_iMenuPosition[id]);
		}
	}
}
