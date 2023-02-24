#if defined _grab_menu_included
    #endinput
#endif
#define _grab_menu_included

/**
 * The maximum buffer size required to store a grab menu item name.
 */
const GRAB_MENU_MAX_NAME_LENGTH = 64;

/**
 * The maximum buffer size required to store a grab menu item key.
 */
const GRAB_MENU_MAX_KEY_LENGTH = 64;

/**
 * The maximum buffer size required to store a grab menu item access.
 */
const GRAB_MENU_MAX_ACCESS_LENGTH = 64;

enum GrabItemTeam (<<= 1)
{
    GRAB_TEAM_T = 1,
    GRAB_TEAM_CT,
    GRAB_TEAM_SPECTATOR,
    GRAB_TEAM_NONE
};

enum GrabItemProp
{
    GRAB_PROP_NAME,
    GRAB_PROP_KEY,
    GRAB_PROP_GRABBER_TEAM,
    GRAB_PROP_GRABBED_TEAM,
    GRAB_PROP_ACCESS
};

enum
{
    GRAB_GLOBAL_INFO
};

/**
 * Opens grab menu for player.
 *
 * @param id            Grabber index
 *
 * @return              true on success, false otherwise
 * @error               If the grabber index is not within the range of 1 to MaxClients,
 *                      an error will be thrown.
 */
native bool:grab_menu_open(id);

/**
 * Adds item to menu.
 *
 * @param name          Item name
 * @param key           Item key
 * @param grabber_team  Team to which item will be displayed
 * @param grabbed_team  Item will be displayed only if target is in that team
 * @param access        Item access
 *
 * @return              Item index on success, 0 otherwise
 * @error               If such key already exists, an error will be thrown.
 */
native grab_menu_add_item(const name[], const key[], GrabItemTeam:grabber_team = GRAB_TEAM_NONE, GrabItemTeam:grabbed_team = GRAB_TEAM_NONE, const access[] = "");

/**
 * Gets info about item.
 *
 * @param id            Client index or GRAB_GLOBAL_INFO constant (0)
 * @param item          Item index
 * @param name          Buffer to copy item name to
 * @param name_len      Maximum size of buffer
 * @param key           Buffer to copy item key to
 * @param key_len       Maximum size of buffer
 * @param grabber_team  Variable to store grabber team to
 * @param grabbed_team  Variable to store grabbed team to
 * @param access        Buffer to copy item access to
 * @param access_len    Maximum size of buffer
 *
 * @return              true if item exists, false otherwise
 * @error               If an invalid item index is provided, an error will be thrown.
 */
native bool:grab_menu_get_item_info(id, item, const name[] = "", name_length = 0, const key[] = "", key_length = 0, &GrabItemTeam:grabber_team = GRAB_TEAM_NONE, &GrabItemTeam:grabbed_team = GRAB_TEAM_NONE, const access[] = "", access_len = 0);

/**
 * Sets info for item.
 *
 * @param id            Client index or GRAB_GLOBAL_INFO constant (0)
 * @param item          Item index
 * @param itemprop      Item property (see GrabItemProp)
 * @param ...           New value
 *
 * @return              true on success, false otherwise
 */
native bool:grab_menu_set_item_info(id, item, GrabItemProp:itemprop, any:...);

/**
 * Finds item by key.
 *
 * @param key           Item key
 *
 * @return              Item index, or 0 if no item found
 */
native grab_menu_find_item_by_key(const key[]);

/**
 * Called when player opens grab menu.
 *
 * @param id            Grabber index
 * @param target        Grabbed index
 *
 * @return              GRAB_ALLOWED to allow opening the menu
 *                      GRAB_BLOCKED to prevent opening the menu
 */
forward grab_menu_opened(id, entity);

/**
 * Called when grab menu item is going to be added to the menu and access is checked.
 *
 * @param id            Grabber index
 * @param entity        Grabbed index
 * @param item          Item index
 * @param access        Item access
 */
forward grab_menu_item_access_check(id, entity, item, access[]);

/**
 * Called when grab menu item is going to be added to the menu.
 *
 * @param id            Grabber index
 * @param entity        Grabbed index
 * @param item          Item index
 *
 * @return              GRAB_ALLOWED to add the item to the menu
 *                      GRAB_BLOCKED to hide the item from the menu
 */
forward grab_menu_item_show(id, entity, item);

/**
 * Called when grab menu item is being added to the menu.
 *
 * @param id            Grabber index
 * @param item          Item index
 *
 * @return              GRAB_ALLOWED to allow pressing
 *                      GRAB_BLOCKED to block pressing
 */
forward grab_menu_item_pressing(id, item);

/**
 * Called when player selects item in menu.
 *
 * @param id            Grabber index
 * @param entity        Grabbed index
 * @param item          Item index
 *
 * @return              GRAB_ALLOWED to allow item selection
 *                      GRAB_BLOCKED to block menu reopening
 */
forward grab_menu_item_selected(id, entity, item);
