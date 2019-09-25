#if defined _grab_rendering_included
	#endinput
#endif
#define _grab_rendering_included

#pragma reqlib grab_rendering

/**
 * Gets player rendering, which is applied on grab start.
 *
 * @param id        Client index
 * @param red       Red (RGB))
 * @param blue      Blue (RGB)
 * @param green     Green (RGB)
 * @param amount    Amount
 *
 * @noreturn
 * @error           If the client index is not within the range of 1 to MaxClients,
 *                  an error will be thrown.
 */
native grab_get_player_rendering(id, &Float:red = 0.0, &Float:green = 0.0, &Float:blue = 0.0, &Float:amount = 0.0);

/**
 * Sets player rendering, which will be applied on grab start.
 *
 * @note Only values other than "-1.0" will be applied.
 *
 * @param id        Client index, or 0 to set to all players
 * @param red       Red (RGB)
 * @param blue      Blue (RGB)
 * @param green     Green (RGB)
 * @param amount    Amount
 *
 * @noreturn
 * @error           If the client index is not within the range of 0 to MaxClients,
 *                  an error will be thrown.
 */
native grab_set_player_rendering(id, Float:red = -1.0, Float:green = -1.0, Float:blue = -1.0, Float:amount = -1.0);