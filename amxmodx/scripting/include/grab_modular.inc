#if defined _grab_modular_included
    #endinput
#endif
#define _grab_modular_included

enum
{
    GRAB_ALLOWED,
    GRAB_BLOCKED
};

#tryinclude <grab_rendering>
#tryinclude <grab_menu>

/**
 * Returns grabber index if entity is being grabbed.
 *
 * @param entity    Grabbed index
 *
 * @return          Grabber index, or 0 if not grabbed
 */
native grab_get_grabber(entity);

/**
 * Returns grabbed index if player is grabbing.
 *
 * @param id        Grabber index
 *
 * @return          Grabbed index, or 0 if not grabbing
 * @error           If the grabber index is not within the range of 1 to MaxClients,
 *                  an error will be thrown.
 */
native grab_get_grabbed(id);

/**
 * Returns the distance between grabber and grabbed.
 *
 * @param id        Grabber index
 *
 * @return          Distance between grabber and grabbed, or 0 if not grabbing
 * @error           If the grabber index is not within the range of 1 to MaxClients,
 *                  an error will be thrown.
 */
native Float:grab_get_distance(id);

/**
 * Sets the distance between grabber and grabbed.
 *
 * @param id        Grabber index
 * @param distance  New distance
 *
 * @return          true on success, false otherwise
 * @error           If the grabber index is not within the range of 0 to MaxClients,
 *                  an error will be thrown.
 */
native bool:grab_set_distance(id, Float:distance);

/**
 * Disables grab for player.
 *
 * @param id        Grabber index, or 0 for all players
 *
 * @return          true on success, false otherwise
 * @error           If the client index is not within the range of 1 to MaxClients,
 *                  an error will be thrown.
 */
native bool:grab_disable(id);

/**
 * Returns player access to grab.
 *
 * @param id        Client index
 *
 * @return          Access level
 * @error           If the client index is not within the range of 1 to MaxClients,
 *                  an error will be thrown.
 */
native grab_get_user_access(id);

/**
 * Sets player access to grab.
 *
 * @param id        Client index, or 0 for all players
 * @param level     Access level, 0 to remove access
 *
 * @return          true on success, false otherwise
 * @error           If the client index is greater than 0 and is not within the range of 0 to MaxClients,
 *                  an error will be thrown.
 */
native bool:grab_set_user_access(id, level = 1);

/**
 * Called when player starts to grab.
 *
 * @param id        Grabber index
 * @param entity    Grabbed index
 *
 * @noreturn
 */
forward grab_on_start(id, entity);

/**
 * Called when player finishes grabbing.
 *
 * @param id        Grabber index
 * @param entity    Grabbed index
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
 * @noreturn
 */
forward grab_on_grabbing(id, entity);

/**
 * Called when player access level is changed.
 *
 * @param id        Client index
 * @param old_level Previous level access
 * @param new_level New level access
 *
 * @noreturn
 */
forward grab_access_modified(id, old_level, new_level);
