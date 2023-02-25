#if defined _grab_rendering_included
    #endinput
#endif
#define _grab_rendering_included

/**
 * Sets grabber's rendering mode.
 *
 * @note If -1 is specified, default value will be applied.
 *
 * @param id            Client index
 * @param r             The amount of red color (0 to 255)
 * @param g             The amount of green color (0 to 255)
 * @param b             The amount of blue color (0 to 255)
 * @param fx            Rendering effects. One of kRenderFx* constants
 * @param render        Render mode. One of kRender* constants
 * @param amount        Render amount (0 to 255)
 *
 * @return              true on success, false otherwise
 * @error               If client index is not within the range of 1 to MaxClients,
 *                      an error will be thrown.
 */
native bool:grab_set_user_rendering(id, r = -1, g = -1, b = -1, fx = -1, render = -1, amount = -1);

/**
 * Gets grabber's rendering mode.
 *
 * @param id            Client index
 * @param fx            Variable to store the rendering effect
 * @param r             Variable to store the amount of red color
 * @param g             Variable to store the amount of green color
 * @param b             Variable to store the amount of blue color
 * @param render        Variable to store the render mode
 * @param amount        Variable to store the render amount
 *
 * @return              true on success, false otherwise
 * @error               If client index is not within the range of 1 to MaxClients,
 *                      an error will be thrown.
 */
native bool:grab_get_user_rendering(id, &r = 0, &g = 0, &b = 0, &fx = kRenderFxNone, &render = kRenderNormal, &amount = 0);
