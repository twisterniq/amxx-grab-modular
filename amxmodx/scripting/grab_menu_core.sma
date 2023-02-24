#include <amxmodx>
#include <reapi>
#include <grab_modular>

public stock const PluginName[] = "Grab Menu: Core"
public stock const PluginVersion[] = "2.0.0"
public stock const PluginAuthor[] = "twisterniq"

#define is_user_valid(%0) (1 <= %0 <= MaxClients)

#define CHECK_NATIVE_PLAYER(%0,%1) \
    if (!is_user_valid(%0)) \
    { \
        log_error(AMX_ERR_NATIVE, "Player out of range (%d).", %0); \
        return %1; \
    }

#define CHECK_NATIVE_ITEM(%0,%1,%2) \
    if (!(0 <= %0 < %1)) \
    { \
        log_error(AMX_ERR_NATIVE, "Item out of range (%d).", %0); \
        return %2; \
    }

// Number of menu items per page if there is more than 9 items (max 8)
const ITEMS_ON_PAGE_WITH_PAGINATOR = 8

// Number of menu items per page if there is less than 9 items (max 9)
const ITEMS_ON_PAGE_WITHOUT_PAGINATOR = 9

enum _:CVars
{
    CVAR_ENABLED,
    CVAR_CLOSE
}

enum _:Forwards
{
    FWD_OPENED,
    FWD_ITEM_ACCESS_CHECK,
    FWD_ITEM_SHOW,
    FWD_ITEM_PRESSING,
    FWD_ITEM_SELECTED
}

enum _:ItemStruct
{
    ITEM_NAME[GRAB_MENU_MAX_NAME_LENGTH],
    ITEM_KEY[GRAB_MENU_MAX_KEY_LENGTH],
    GrabItemTeam:ITEM_GRABBER_TEAM,
    GrabItemTeam:ITEM_GRABBED_TEAM,
    ITEM_ACCESS[GRAB_MENU_MAX_ACCESS_LENGTH]
}

enum _:PlayerStruct
{
    PLAYER_TARGET,
    PLAYER_CURRENT_PAGE,
    Array:PLAYER_MENU_ITEMS,
    Trie:PLAYER_ITEM_DATA
}

new g_iMenuId

new g_eCVars[CVars]
new g_hForwards[Forwards]

new Array:g_aMenuItems
new g_iMenuItems

new g_ePlayerData[MAX_PLAYERS + 1][PlayerStruct]

public plugin_init()
{
    register_plugin(PluginName, PluginVersion, PluginAuthor)
    register_dictionary("grab_menu.txt")

    register_menucmd(g_iMenuId = register_menuid("func_MainMenu"), 1023, "func_MainMenu_Handler")

    g_hForwards[FWD_OPENED] = CreateMultiForward("grab_menu_opened", ET_STOP, FP_CELL, FP_CELL)
    g_hForwards[FWD_ITEM_ACCESS_CHECK] = CreateMultiForward("grab_menu_item_access_check", ET_STOP, FP_CELL, FP_CELL, FP_CELL, FP_STRING)
    g_hForwards[FWD_ITEM_SHOW] = CreateMultiForward("grab_menu_item_show", ET_STOP, FP_CELL, FP_CELL, FP_CELL)
    g_hForwards[FWD_ITEM_PRESSING] = CreateMultiForward("grab_menu_item_pressing", ET_STOP, FP_CELL, FP_CELL)
    g_hForwards[FWD_ITEM_SELECTED] = CreateMultiForward("grab_menu_item_selected", ET_STOP, FP_CELL, FP_CELL, FP_CELL)

    g_aMenuItems = ArrayCreate(ItemStruct)

    for (new i = 1; i <= MaxClients; i++)
    {
        g_ePlayerData[i][PLAYER_MENU_ITEMS] = ArrayCreate()
    }

    func_CreateCVars()
}

func_CreateCVars()
{
    bind_pcvar_num(
        create_cvar(
            .name = "grab_menu_enabled",
            .string = "1",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_CVAR_ENABLED"),
            .has_min = true,
            .min_val = 0.0,
            .has_max = true, 
            .max_val = 1.0
        ), g_eCVars[CVAR_ENABLED]
    )

    bind_pcvar_num(
        create_cvar(
            .name = "grab_menu_close",
            .string = "1",
            .flags = FCVAR_NONE,
            .description = fmt("%L", LANG_SERVER, "GRAB_MENU_CVAR_CLOSE"),
            .has_min = true,
            .min_val = 0.0,
            .has_max = true, 
            .max_val = 1.0
        ), g_eCVars[CVAR_CLOSE]
    )

    AutoExecConfig(true, "grab_menu_core", "grab_modular")
}

public plugin_natives()
{
    register_native("grab_menu_open", "native_grab_menu_open")
    register_native("grab_menu_add_item", "native_grab_menu_add_item")
    register_native("grab_menu_get_item_info", "native_grab_menu_get_item_info")
    register_native("grab_menu_set_item_info", "native_grab_menu_set_item_info")
    register_native("grab_menu_find_item_by_key", "native_grab_menu_find_item_by_key")
}

public bool:native_grab_menu_open()
{
    enum { arg_player = 1 }

    new id = get_param(arg_player)

    if (!is_user_valid(id))
    {
        log_error(AMX_ERR_NATIVE, "Player out of range (%d).", id)
        return false
    }

    new iTarget = grab_get_grabbed(id)

    if (!is_user_valid(iTarget))
    {
        return false
    }

    g_ePlayerData[id][PLAYER_TARGET] = iTarget
    func_CreateMenu(id, g_ePlayerData[id][PLAYER_CURRENT_PAGE] = 0)

    return true
}

public native_grab_menu_add_item()
{
    enum { arg_name = 1, arg_key, arg_grabber_team, arg_grabbed_team, arg_access }

    new eItemData[ItemStruct]
    get_string(arg_key, eItemData[ITEM_KEY], charsmax(eItemData[ITEM_KEY]))

    if (func_FindItemByKey(eItemData[ITEM_KEY]))
    {
        log_error(AMX_ERR_NATIVE, "Item key must be unique (^"%s^" already exists).", eItemData[ITEM_KEY])
        return 0
    }

    get_string(arg_name, eItemData[ITEM_NAME], charsmax(eItemData[ITEM_NAME]))
    eItemData[ITEM_GRABBER_TEAM] = GrabItemTeam:get_param(arg_grabber_team)
    eItemData[ITEM_GRABBED_TEAM] = GrabItemTeam:get_param(arg_grabbed_team)
    get_string(arg_access, eItemData[ITEM_ACCESS], charsmax(eItemData[ITEM_ACCESS]))

    ArrayPushArray(g_aMenuItems, eItemData)
    g_iMenuItems++

    return g_iMenuItems
}

public bool:native_grab_menu_get_item_info()
{
    enum
    {
        arg_player = 1,
        arg_itemid,
        arg_name, arg_name_length,
        arg_key, arg_key_length,
        arg_grabber_team,
        arg_grabbed_team,
        arg_access, arg_access_len
    }

    new id = get_param(arg_player)

    if (id)
    {
        CHECK_NATIVE_PLAYER(id, false)
    }

    new iItemId = get_param(arg_itemid) - 1
    CHECK_NATIVE_ITEM(iItemId, g_iMenuItems, false)

    new eItemData[ItemStruct]
    func_GetItemData(id, iItemId, eItemData)

    set_string(arg_name, eItemData[ITEM_NAME], get_param(arg_name_length))
    set_string(arg_key, eItemData[ITEM_KEY], get_param(arg_key_length))
    set_param_byref(arg_grabber_team, any:eItemData[ITEM_GRABBER_TEAM])
    set_param_byref(arg_grabbed_team, any:eItemData[ITEM_GRABBED_TEAM])
    set_string(arg_access, eItemData[ITEM_ACCESS], get_param(arg_access_len))

    return true
}

public bool:native_grab_menu_set_item_info(amxx, params)
{
    enum { arg_player = 1, arg_itemid, arg_prop, arg_value, arg_vargs }

    new id = get_param(arg_player)

    if (id)
    {
        CHECK_NATIVE_PLAYER(id, false)

        if (g_ePlayerData[id][PLAYER_ITEM_DATA] == Invalid_Trie)
        {
            g_ePlayerData[id][PLAYER_ITEM_DATA] = TrieCreate()
        }
    }

    new iItemId = get_param(arg_itemid) - 1
    CHECK_NATIVE_ITEM(iItemId, g_iMenuItems, false)

    new eItemData[ItemStruct]
    func_GetItemData(id, iItemId, eItemData)

    if (params < arg_value)
    {
        log_error(AMX_ERR_NATIVE, "Missing new item property value.")
        return false
    }

    if (!func_GetModifiedItemData(arg_prop, arg_value, arg_vargs, eItemData))
    {
        return false
    }

    new bool:bSuccess

    if (id)
    {
        bSuccess = bool:TrieSetArray(g_ePlayerData[id][PLAYER_ITEM_DATA], fmt("%d", iItemId), eItemData, ItemStruct)
    }
    else
    {
        bSuccess = bool:ArraySetArray(g_aMenuItems, iItemId, eItemData)
    }

    return bSuccess
}

public native_grab_menu_find_item_by_key()
{
    enum { arg_key = 1 }

    new szKey[GRAB_MENU_MAX_KEY_LENGTH]
    get_string(arg_key, szKey, charsmax(szKey))

    return func_FindItemByKey(szKey)
}

func_FindItemByKey(const szKey[])
{
    new eItemData[ItemStruct]

    for (new i; i < g_iMenuItems; i++)
    {
        ArrayGetArray(g_aMenuItems, i, eItemData)

        if (equal(eItemData[ITEM_KEY], szKey))
        {
            return i + 1
        }
    }

    return 0
}

public grab_on_start(id, iTarget)
{
    if (!g_eCVars[CVAR_ENABLED] || !g_iMenuItems)
    {
        return
    }

    if (!g_eCVars[CVAR_CLOSE] && func_IsMenuOpened(id, true))
    {
        return
    }

    g_ePlayerData[id][PLAYER_TARGET] = iTarget
    func_CreateMenu(id, g_ePlayerData[id][PLAYER_CURRENT_PAGE] = 0)
}

public grab_on_finish(id, iEnt)
{
    if (!g_eCVars[CVAR_ENABLED] || !g_iMenuItems)
    {
        return
    }

    if (func_IsMenuOpened(id, false))
    {
        show_menu(id, 0, "^n")
    }

    g_ePlayerData[id][PLAYER_TARGET] = 0
}

bool:func_IsMenuOpened(id, bool:bOtherMenu)
{
    new iMenu, iKeys
    get_user_menu(id, iMenu, iKeys)

    if (bOtherMenu && get_member(id, m_iMenu) > Menu_OFF)
    {
        return true
    }

    if (!iMenu)
    {
        return false
    }

    return !bOtherMenu ? (iMenu == g_iMenuId) : (iMenu != g_iMenuId)
}

func_CreateMenu(const id, const iPage)
{
    new iTarget = g_ePlayerData[id][PLAYER_TARGET]

    new iRet
    ExecuteForward(g_hForwards[FWD_OPENED], iRet, id, iTarget)

    if (iRet == GRAB_BLOCKED)
    {
        // Don't open menu
        return
    }

    new TeamName:iPlayerTeam, TeamName:iTargetTeam
    new bool:bPlayer = is_user_valid(iTarget)

    iPlayerTeam = get_member(id, m_iTeam)

    if (bPlayer)
    {
        iTargetTeam = get_member(iTarget, m_iTeam)
    }

    new eItemData[ItemStruct]

    ArrayClear(g_ePlayerData[id][PLAYER_MENU_ITEMS])

    for (new i; i < g_iMenuItems; i++)
    {
        func_GetItemData(id, i, eItemData)

        if (
            eItemData[ITEM_GRABBER_TEAM] & GRAB_TEAM_T && iPlayerTeam == TEAM_TERRORIST
            || eItemData[ITEM_GRABBER_TEAM] & GRAB_TEAM_CT && iPlayerTeam == TEAM_CT
            || eItemData[ITEM_GRABBER_TEAM] & GRAB_TEAM_SPECTATOR && iPlayerTeam == TEAM_SPECTATOR
        )
        {
            if (bPlayer &&
                (eItemData[ITEM_GRABBED_TEAM] & GRAB_TEAM_T && iTargetTeam == TEAM_TERRORIST
                || eItemData[ITEM_GRABBED_TEAM] & GRAB_TEAM_CT && iTargetTeam == TEAM_CT
                || eItemData[ITEM_GRABBED_TEAM] & GRAB_TEAM_SPECTATOR && iTargetTeam == TEAM_SPECTATOR)
                || !bPlayer && eItemData[ITEM_GRABBED_TEAM] & GRAB_TEAM_NONE
            )
            {
                if (eItemData[ITEM_ACCESS][0])
                {
                    ExecuteForward(g_hForwards[FWD_ITEM_ACCESS_CHECK], iRet, id, iTarget, i + 1, eItemData[ITEM_ACCESS])

                    if (iRet == GRAB_BLOCKED)
                    {
                        // Player doesn't have access to this item, it can't be shown, go to next item
                        continue
                    }
                }

                ExecuteForward(g_hForwards[FWD_ITEM_SHOW], iRet, id, iTarget, i + 1)

                if (iRet == GRAB_BLOCKED)
                {
                    // This item can't be shown, go to next item
                    continue
                }

                ArrayPushCell(g_ePlayerData[id][PLAYER_MENU_ITEMS], i)
            }
        }
    }

    if (!ArraySize(g_ePlayerData[id][PLAYER_MENU_ITEMS]))
    {
        // No items available for player
        return
    }

    func_MainMenu(id, iPage)
}

func_MainMenu(const id, iPage)
{
    if (iPage < 0)
    {
        return
    }

    new szMenu[MAX_MENU_LENGTH], iLen, iStart, iEnd, iMenuItem, iKeys = MENU_KEY_0, iPagesNum
    new iItems, iItemsOnPage, iItemId, eItemData[ItemStruct]
    new iTarget = g_ePlayerData[id][PLAYER_TARGET]
    new iRet

    iItems = ArraySize(g_ePlayerData[id][PLAYER_MENU_ITEMS])
    iItemsOnPage = iItems > ITEMS_ON_PAGE_WITHOUT_PAGINATOR ? ITEMS_ON_PAGE_WITH_PAGINATOR : ITEMS_ON_PAGE_WITHOUT_PAGINATOR
    iPagesNum = iItems / iItemsOnPage + ((iItems % iItemsOnPage) ? 1 : 0)

    if ((iStart = iPage * iItemsOnPage) > iItems)
    {
        iStart = iPage = g_ePlayerData[id][PLAYER_CURRENT_PAGE] = 0
    }

    if ((iEnd = iStart + iItemsOnPage) > iItems)
    {
        iEnd = iItems
    }

    SetGlobalTransTarget(id)

    if (is_user_valid(iTarget))
    {
        iLen = formatex(szMenu, charsmax(szMenu), "^t^t^t^t^t\y%l", "GRAB_MENU_TITLE_PLAYER", iTarget)
    }
    else
    {
        iLen = formatex(szMenu, charsmax(szMenu), "^t^t^t^t^t\y%l", "GRAB_MENU_TITLE_ENT")
    }

    if (iItems > ITEMS_ON_PAGE_WITH_PAGINATOR)
    {
        iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, " \d%d/%d", iPage + 1, iPagesNum)
    }

    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n")

    for (new i; iStart < iEnd; i++)
    {
        iItemId = ArrayGetCell(g_ePlayerData[id][PLAYER_MENU_ITEMS], iStart++)
        func_GetItemData(id, iItemId, eItemData)

        ExecuteForward(g_hForwards[FWD_ITEM_PRESSING], iRet, id, iItemId + 1)

        if (iRet == GRAB_ALLOWED)
        {
            iKeys |= (1<<iMenuItem)
            iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^t^t^t^t^t\y%d. \w%s^n",
                ++iMenuItem, eItemData[ITEM_NAME])
        }
        else
        {
            iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^t^t^t^t^t\d%d. %s^n", ++iMenuItem, eItemData[ITEM_NAME])
        }
    }

    if (iEnd != iItems)
    {
        iKeys |= MENU_KEY_9
        iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^t^t^t^t^t\y9. \w%l^n", "GRAB_MENU_NEXT")
    }
    else
    {
        iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n")
    }

    formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^t^t^t^t^t\y0. \w%l", iPage ? "GRAB_MENU_BACK" : "GRAB_MENU_EXIT")

    show_menu(id, iKeys, szMenu, -1, "func_MainMenu")
}

public func_MainMenu_Handler(const id, const iKey)
{
    new bool:bPagination = ArraySize(g_ePlayerData[id][PLAYER_MENU_ITEMS]) > ITEMS_ON_PAGE_WITHOUT_PAGINATOR

    switch (iKey)
    {
        // 9. Next
        case 8:
        {
            if (bPagination)
            {
                func_CreateMenu(id, ++g_ePlayerData[id][PLAYER_CURRENT_PAGE])
            }
            else
            {
                func_SelectItem(id, iKey, bPagination)
            }
        }
        // 0. Back/Exit
        case 9:
        {
            func_CreateMenu(id, --g_ePlayerData[id][PLAYER_CURRENT_PAGE])
        }
        default:
        {
            func_SelectItem(id, iKey, bPagination)
        }
    }
}

func_SelectItem(const id, const iKey, bool:bPagination)
{
    new iItemsPerPage = !bPagination ? ITEMS_ON_PAGE_WITHOUT_PAGINATOR : ITEMS_ON_PAGE_WITH_PAGINATOR
    new i = g_ePlayerData[id][PLAYER_CURRENT_PAGE] * iItemsPerPage + iKey
    new iItemId = ArrayGetCell(g_ePlayerData[id][PLAYER_MENU_ITEMS], i)

    new iRet
    ExecuteForward(g_hForwards[FWD_ITEM_SELECTED], iRet, id, g_ePlayerData[id][PLAYER_TARGET], iItemId + 1)

    if (iRet == GRAB_BLOCKED)
    {
        // Don't reopen menu if it's blocked
        return
    }

    if (!grab_get_grabbed(id))
    {
        // Don't reopen menu if grab was disabled
        return
    }

    func_CreateMenu(id, g_ePlayerData[id][PLAYER_CURRENT_PAGE])
}

// thanks to Kaido Ren (Shop API)
func_GetItemData(const id, const iItemId, eItemData[] = NULL_STRING)
{
    new bool:bSuccess

    if (id && g_ePlayerData[id][PLAYER_ITEM_DATA])
    {
        bSuccess = TrieGetArray(g_ePlayerData[id][PLAYER_ITEM_DATA], fmt("%d", iItemId), eItemData, ItemStruct)
    }

    // id is GRAB_GLOBAL_INFO or player has no custom data set
    if (!bSuccess)
    {
        ArrayGetArray(g_aMenuItems, iItemId, eItemData)
    }
}

// thanks to Kaido Ren (Shop API)
bool:func_GetModifiedItemData(arg_prop, arg_value, arg_vargs, eItemData[])
{
    new iProp = get_param(arg_prop)

    switch (iProp)
    {
        case GRAB_PROP_NAME:
        {
            if (!vdformat(eItemData[ITEM_NAME], GRAB_MENU_MAX_NAME_LENGTH - 1, arg_value, arg_vargs))
            {
                log_error(AMX_ERR_NATIVE, "New item property value cannot be empty.")
                return false
            }
        }
        case GRAB_PROP_KEY:
        {
            if (!vdformat(eItemData[ITEM_KEY], GRAB_MENU_MAX_KEY_LENGTH - 1, arg_value, arg_vargs))
            {
                log_error(AMX_ERR_NATIVE, "New item property value cannot be empty.")
                return false
            }

            if (ArrayFindString(g_aMenuItems, eItemData[ITEM_KEY]) != -1)
            {
                log_error(AMX_ERR_NATIVE, "Item key must be unique (^"%s^" already exists).", eItemData[ITEM_KEY])
            }
        }
        case GRAB_PROP_GRABBER_TEAM:
        {
            eItemData[ITEM_GRABBER_TEAM] = GrabItemTeam:get_param_byref(arg_value)
        }
        case GRAB_PROP_GRABBED_TEAM:
        {
            eItemData[ITEM_GRABBED_TEAM] = GrabItemTeam:get_param_byref(arg_value)
        }
        case GRAB_PROP_ACCESS:
        {
            vdformat(eItemData[ITEM_ACCESS], GRAB_MENU_MAX_ACCESS_LENGTH - 1, arg_value, arg_vargs)
        }
        default:
        {
            log_error(AMX_ERR_NATIVE, "This property doesn't exist.")
            return false
        }
    }

    return true
}