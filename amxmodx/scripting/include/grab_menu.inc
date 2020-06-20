#if defined _grab_menu_included
    #endinput
#endif
#define _grab_menu_included

#pragma reqlib grab_menu

#include <grab_menu_const>

/**
 * Called when player opens grab menu.
 *
 * @param id                    Client index
 *
 * @return                      PLUGIN_CONTINUE to let opening the menu
 *                              PLUGIN_HANDLED or higher to prevent opening the menu
 */
forward grab_menu_opened(id);

/**
 * Called before item is displayed.
 *
 * @param id                    Client index
 * @param entity                Entity index
 * @param item                  Item index
 *
 * @return                      PLUGIN_CONTINUE to let showing the item
 *                              PLUGIN_HANDLED or higher to prevent showing the item
 */
forward grab_menu_on_item_show(id, entity, item);

/**
 * Called when player selects item in menu.
 *
 * @note If PLUGIN_HANDLED or higher value is returned, the menu won't be opened again
 *
 * @param id                    Client index
 * @param entity                Entity grabbed index
 * @param item                  Item index
 *
 * @return                      PLUGIN_CONTINUE to let selecting the item
 *                              PLUGIN_HANDLED or higher to prevent selecting the item
 */
forward grab_menu_item_selected(id, entity, item);

/**
 * Opens grab menu for player.
 *
 * @param id                    Client index
 * @param entity                Entity index
 *
 * @return                      true on success, false otherwise
 * @error                       If the client index is not within the range of 1 to MaxClients,
 *                              an error will be thrown.
 */
native bool:grab_menu_open(id, entity);

/**
 * Adds item to menu.
 *
 * @param name                  Item name
 * @param key                   Item key
 * @param access                Access to item, ADMIN_ALL means default access
 * @param team                  Team to which item will be displayed
 * @param target_team           Item will be displayed only if target is in that team
 *
 * @return                      Item index
 * @error                       If the item with specified key already exists, an error will be
 *                              thrown.
 */
native grab_menu_add_item(const name[], const key[], const GrabItemTeam:team = (GRAB_TEAM_T|GRAB_TEAM_CT|GRAB_TEAM_SPECTATOR), const GrabItemTeam:target_team = (GRAB_TEAM_T|GRAB_TEAM_CT), const access = ADMIN_ALL);

/**
 * Gets info about item.
 *
 * @param item                  Item index
 * @param name                  Item name
 * @param name_length           Max buffer length
 * @param key                   Item key
 * @param key_length            Max buffer length
 * @param team                  Team to which item is displayed (see GrabTeams)
 * @param target_team           Item is displayed only if target is in that team
 * @param access                Access to item
 *
 * @return                      true if item exists, false otherwise
 */
native bool:grab_menu_get_item_info(const item, const name[] = "", &name_length = 0, const key[] = "", &key_length = 0, &GrabItemTeam:team = (GRAB_TEAM_T|GRAB_TEAM_CT|GRAB_TEAM_SPECTATOR), &GrabItemTeam:target_team = (GRAB_TEAM_T|GRAB_TEAM_CT), &access = 0);

/**
 * Sets info for item.
 *
 * @param item                  Item index
 * @param itemprop              Item property (see GrabItemProp)
 * @param ...                   New value
 *
 * @return                      true on success, false otherwise
 */
native bool:grab_menu_set_item_info(item, GrabItemProp:itemprop, any:...);

/**
 * Finds item by key.
 *
 * @param key                   Item key
 *
 * @return                      Item index
 */
native grab_menu_find_item_by_key(const key[]);