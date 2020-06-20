#include <amxmodx>
#include <reapi>
#include <grab_modular>

#pragma semicolon 1

new const PLUGIN_NAME[] = "Grab: Pull";
new const PLUGIN_VERSION[] = "1.0.0";
new const PLUGIN_AUTHOR[] = "w0w";

/****************************************************************************************
****************************************************************************************/

enum _:Cvars
{
	CVAR_ENABLED,
	Float:CVAR_UNITS
};

new g_eCvar[Cvars];

new bool:g_bPullEnabled[MAX_PLAYERS+1];

public plugin_init()
{
	register_plugin(
		.plugin_name = PLUGIN_NAME,
		.version = PLUGIN_VERSION,
		.author = PLUGIN_AUTHOR
	);

	register_dictionary("grab_pull.txt");

	RegisterHookChain(RH_SV_DropClient, "refwd_DropClient_Post", true);

	register_clcmd("+pull", "func_ClCmdPullEnabled");
	register_clcmd("-pull", "func_ClCmdPullDisabled");

	func_RegisterCvars();
}

func_RegisterCvars()
{
	new pCvar;

	pCvar = create_cvar("grab_pull_enabled", "1", FCVAR_NONE, fmt("%L", LANG_SERVER, "GRAB_PULL_CVAR_ENABLED"), true, 0.0, true, 1.0);
	bind_pcvar_num(pCvar, g_eCvar[CVAR_ENABLED]);

	pCvar = create_cvar("grab_pull_units", "15.0", FCVAR_NONE, fmt("%L", LANG_SERVER, "GRAB_PULL_CVAR_UNITS"), true, 1.0);
	bind_pcvar_float(pCvar, g_eCvar[CVAR_UNITS]);

	AutoExecConfig(true, "grab_pull", "grab_modular");
}

public refwd_DropClient_Post(const id)
{
	g_bPullEnabled[id] = false;
}

public func_ClCmdPullEnabled(const id)
{
	if(!g_eCvar[CVAR_ENABLED])
		return PLUGIN_HANDLED;

	g_bPullEnabled[id] = true;
	return PLUGIN_HANDLED;
}

public func_ClCmdPullDisabled(const id)
{
	g_bPullEnabled[id] = false;
	return PLUGIN_HANDLED;
}

public grab_on_grabbing(id, iEntity)
{
	if(!g_bPullEnabled[id])
		return;

	grab_set_distance(id, iEntity, grab_get_distance(id, iEntity) - g_eCvar[CVAR_UNITS]);
}