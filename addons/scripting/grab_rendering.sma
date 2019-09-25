#include <amxmodx>
#include <reapi>
#include <grab_modular>

#pragma semicolon 1

new const PLUGIN_NAME[] = "Grab: Rendering";
new const PLUGIN_VERSION[] = "1.0.0";
new const PLUGIN_AUTHOR[] = "w0w";

/****************************************************************************************
****************************************************************************************/

#define CHECK_PLAYER(%0) \
    if (!(1 <= %0 <= MaxClients)) \
        abort(AMX_ERR_NATIVE, "Player out of range (%d)", %0);

enum _:Cvars
{
	CVAR_ENABLED
};

new g_eCvar[Cvars];

enum _:RenderData
{
	Float:RENDER_COLOR_RED,
	Float:RENDER_COLOR_GREEN,
	Float:RENDER_COLOR_BLUE,
	Float:RENDER_AMOUNT
};

new Float:g_flRenderCvar[RenderData];
new Float:g_flPlayerRenderData[MAX_PLAYERS+1][RenderData];

public plugin_init()
{
	register_plugin(
		.plugin_name = PLUGIN_NAME,
		.version = PLUGIN_VERSION,
		.author = PLUGIN_AUTHOR
	);

	register_dictionary("grab_rendering.txt");

	func_RegisterCvars();
}

func_RegisterCvars()
{
	new pCvar;

	pCvar = create_cvar("grab_rendering_enabled", "1", FCVAR_NONE, fmt("%L", LANG_SERVER, "GRAB_RENDERING_CVAR_ENABLED"), true, 0.0, true, 1.0);
	bind_pcvar_num(pCvar, g_eCvar[CVAR_ENABLED]);

	pCvar = create_cvar("grab_rendering_color_red", "255", FCVAR_NONE, fmt("%L", LANG_SERVER, "GRAB_RENDERING_CVAR_COLOR_RED"), true, 0.0, true, 255.0);
	bind_pcvar_float(pCvar, g_flRenderCvar[RENDER_COLOR_RED]);

	pCvar = create_cvar("grab_rendering_color_green", "255", FCVAR_NONE, fmt("%L", LANG_SERVER, "GRAB_RENDERING_CVAR_COLOR_GREEN"), true, 0.0, true, 255.0);
	bind_pcvar_float(pCvar, g_flRenderCvar[RENDER_COLOR_GREEN]);

	pCvar = create_cvar("grab_rendering_color_blue", "255", FCVAR_NONE, fmt("%L", LANG_SERVER, "GRAB_RENDERING_CVAR_COLOR_BLUE"), true, 0.0, true, 255.0);
	bind_pcvar_float(pCvar, g_flRenderCvar[RENDER_COLOR_BLUE]);

	pCvar = create_cvar("grab_rendering_amount", "128", FCVAR_NONE, fmt("%L", LANG_SERVER, "GRAB_RENDERING_CVAR_AMOUNT"), true, 0.0, true, 255.0);
	bind_pcvar_float(pCvar, g_flRenderCvar[RENDER_AMOUNT]);

	AutoExecConfig(true, "grab_rendering", "grab_modular");
}

public plugin_natives()
{
	register_library("grab_rendering");

	register_native("grab_set_player_rendering", "NativeHandle_SetPlayerRendering");
	register_native("grab_get_player_rendering", "NativeHandle_GetPlayerRendering");
}

public NativeHandle_GetPlayerRendering(iPlugin, iParams)
{
	enum { arg_player = 1, arg_color_red, arg_color_green, arg_color_blue, arg_amount };

	new iPlayer = get_param(arg_player);

	CHECK_PLAYER(iPlayer)

	set_float_byref(arg_color_red, g_flPlayerRenderData[iPlayer][RENDER_COLOR_RED]);
	set_float_byref(arg_color_green, g_flPlayerRenderData[iPlayer][RENDER_COLOR_GREEN]);
	set_float_byref(arg_color_blue, g_flPlayerRenderData[iPlayer][RENDER_COLOR_BLUE]);
	set_float_byref(arg_amount, g_flPlayerRenderData[iPlayer][RENDER_AMOUNT]);
}

public NativeHandle_SetPlayerRendering(iPlugin, iParams)
{
	enum { arg_player = 1, arg_color_red, arg_color_green, arg_color_blue, arg_amount };
	#pragma unused arg_color_red, arg_color_green, arg_color_blue

	new iPlayer = get_param(arg_player);

	new Float:flData[arg_amount - 1];

	for(new i; i < sizeof flData; i++)
		flData[i] = get_param_f(i + 2);

	if(iPlayer)
	{
		CHECK_PLAYER(iPlayer)

		for(new i; i < sizeof flData; i++)
			g_flPlayerRenderData[iPlayer][i] = flData[i] != -1.0 ? flData[i] : g_flRenderCvar[i];
	}
	else
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!is_user_connected(i))
				continue;

			for(new a; a < sizeof flData; a++)
				g_flPlayerRenderData[i][a] = flData[a] != -1.0 ? flData[a] : g_flRenderCvar[a];
		}
	}

}

public client_putinserver(id)
{
	for(new i; i < RenderData; i++)
		g_flPlayerRenderData[id][i] = g_flRenderCvar[i];
}

public grab_on_start(id, iEntity)
{
	if(!g_eCvar[CVAR_ENABLED])
		return;

	UTIL_SetRendering(iEntity,
		kRenderFxGlowShell,
		g_flPlayerRenderData[id][RENDER_COLOR_RED],
		g_flPlayerRenderData[id][RENDER_COLOR_GREEN],
		g_flPlayerRenderData[id][RENDER_COLOR_BLUE],
		kRenderNormal,
		g_flPlayerRenderData[id][RENDER_AMOUNT]);
}

public grab_on_finish(id, iEntity)
{
	if(!g_eCvar[CVAR_ENABLED])
		return;

	new iRenderFx, Float:flRenderColor[3], iRender, Float:flAmount;
	UTIL_GetRendering(iEntity, iRenderFx, flRenderColor[0], flRenderColor[1], flRenderColor[2], iRender, flAmount);

	if(
		iRenderFx == kRenderFxGlowShell
		&& g_flPlayerRenderData[id][RENDER_COLOR_RED] == flRenderColor[0]
		&& g_flPlayerRenderData[id][RENDER_COLOR_GREEN] == flRenderColor[1]
		&& g_flPlayerRenderData[id][RENDER_COLOR_BLUE] == flRenderColor[2]
		&& iRender == kRenderNormal
		&& g_flPlayerRenderData[id][RENDER_AMOUNT] == flAmount
	)
	{
		UTIL_SetRendering(iEntity);
	}
}

/****************************************************************************************
****************************************************************************************/

stock UTIL_SetRendering(iEnt, iRenderFx = kRenderFxNone, Float:flRed = 0.0, Float:flGreen = 0.0, Float:flBlue = 0.0, iRender = kRenderNormal, Float:flAmount = 0.0)
{
	new Float:flRenderColor[3];
	flRenderColor[0] = flRed;
	flRenderColor[1] = flGreen;
	flRenderColor[2] = flBlue;

	set_entvar(iEnt, var_renderfx, iRenderFx);
	set_entvar(iEnt, var_rendercolor, flRenderColor);
	set_entvar(iEnt, var_rendermode, iRender);
	set_entvar(iEnt, var_renderamt, flAmount);
}

stock UTIL_GetRendering(id, &iRenderFx = kRenderFxNone, &Float:flRed = 0.0, &Float:flGreen = 0.0, &Float:flBlue = 0.0, &iRender = kRenderNormal, &Float:flAmount = 0.0)
{
	new Float:flRenderColor[3];
	get_entvar(id, var_rendercolor, flRenderColor);

	iRenderFx = get_entvar(id, var_renderfx);

	flRed = flRenderColor[0];
	flGreen = flRenderColor[1];
	flBlue = flRenderColor[2];

	iRender = get_entvar(id, var_rendermode);
	flAmount = Float:get_entvar(id, var_renderamt);
}