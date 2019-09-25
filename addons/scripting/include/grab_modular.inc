#if defined _grab_modular_included
	#endinput
#endif
#define _grab_modular_included

#pragma reqlib grab_modular

/**
 * Called when player uses +grab command.
 *
 * @param id        Client index
 *
 * @return          PLUGIN_CONTINUE to let using the command
 *                  PLUGIN_HANDLED or higher to prevent using the command
 */
forward grab_on_use_command(id, entity);

/**
 * Called when player starts to grab an entity.
 *
 * @param id        Client index
 * @param entity    Grabbed entity
 *
 * @return          PLUGIN_CONTINUE to let starting to grab
 *                  PLUGIN_HANDLED or higher to prevent starting to grab
 */
forward grab_on_start(id, entity);

/**
 * Called when player finishes grabbing an entity.
 *
 * @param id        Client index
 * @param entity    Grabbed entity
 *
 * @noreturn
 */
forward grab_on_finish(id, entity);

/**
 * Called when player is grabbing an entity.
 *
 * @param id        Client index
 * @param entity    Grabbed entity
 *
 * @return          PLUGIN_CONTINUE to continue grabbing
 *                  PLUGIN_HANDLED or higher to prevent grabbing
 */
forward grab_on_grabbing(id, entity);

/**
 * Returns client index if entity is grabbed.
 *
 * @param entity    Entity index
 *
 * @return          Client index, or 0 if not grabbed
 */
native is_entity_grabbed(entity);

/**
 * Returns entity index if player is grabbing.
 *
 * @param id        Client index
 *
 * @return          Entity index, or 0 if not grabbing
 * @error			If the client index is not within the range of 1 to MaxClients,
 *					an error will be thrown.
 */
native is_player_grabbing(id);

/**
 * Returns if player has access to use grab.
 *
 * @param id        Client index
 * @param custom	Access given by grab_set_player_access
 *
 * @return			true if player has access, false otherwise
 * @error			If the client index is not within the range of 1 to MaxClients,
 *					an error will be thrown.
 */
native grab_has_player_access(id, bool:custom = false);

/**
 * Sets player grab access.
 *
 * @note Set id 0 to give access to all players
 *
 * @param id        Client index
 * @param set		Access
 *
 * @noreturn
 * @error			If the client index is not within the range of 0 to MaxClients,
 *					an error will be thrown.
 */
native grab_set_player_access(id, bool:set = true);

/**
 * Returns the distance between grabber and grabbed.
 *
 * @param id        Client index
 * @param entity	Entity index
 *
 * @return          Distance between grabber and grabbed
 * @error			If the client index is not within the range of 1 to MaxClients,
 *					an error will be thrown.
 */
native Float:grab_get_distance(id, entity);

/**
 * Sets the distance between grabber and grabbed.
 *
 * @param id        Client index
 * @param entity	Entity index
 *
 * @return          true on success, false otherwise
 * @error			If the client index is not within the range of 0 to MaxClients,
 *					an error will be thrown.
 */
native bool:grab_set_distance(id, entity, Float:distance);

/**
 * Disables grab for player.
 *
 * @param id		Client index, or 0 to disable for all players
 *
 * @return          true on success, false otherwise
 * @error			If the client index is not within the range of 1 to MaxClients,
 *					an error will be thrown.
 */
native grab_disable(id);