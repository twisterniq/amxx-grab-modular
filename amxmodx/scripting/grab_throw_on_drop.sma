#include <amxmodx>
#include <reapi>
#include <grab_modular>

#pragma semicolon 1

new const PLUGIN_NAME[] = "Grab: Throw on Drop";
new const PLUGIN_VERSION[] = "1.0.0";
new const PLUGIN_AUTHOR[] = "w0w";

/****************************************************************************************
****************************************************************************************/

enum _:Cvars
{
	CVAR_ENABLED,
	CVAR_VELOCITY
};

new g_eCvar[Cvars];

public plugin_init()
{
	register_plugin(
		.plugin_name = PLUGIN_NAME,
		.version = PLUGIN_VERSION,
		.author = PLUGIN_AUTHOR
	);

	register_dictionary("grab_throw_on_drop.txt");

	RegisterHookChain(RG_CBasePlayer_DropPlayerItem, "refwd_DropPlayerItem_Pre", false);

	func_RegisterCvars();
}

func_RegisterCvars()
{
	new pCvar;

	pCvar = create_cvar("grab_throw_on_drop_enabled", "1", FCVAR_NONE, fmt("%L", LANG_SERVER, "GRAB_THROW_ON_DROP_CVAR_ENABLED"), true, 0.0, true, 1.0);
	bind_pcvar_num(pCvar, g_eCvar[CVAR_ENABLED]);

	pCvar = create_cvar("grab_throw_on_drop_velocity", "1500", FCVAR_NONE, fmt("%L", LANG_SERVER, "GRAB_THROW_ON_DROP_CVAR_VELOCITY"), true, 1.0);
	bind_pcvar_num(pCvar, g_eCvar[CVAR_VELOCITY]);

	AutoExecConfig(true, "grab_throw_on_drop", "grab_modular");
}

public refwd_DropPlayerItem_Pre(const id, const pszItemName[])
{
	if(!g_eCvar[CVAR_ENABLED])
		return HC_CONTINUE;

	new iTarget = is_player_grabbing(id);

	if(!iTarget)
		return HC_CONTINUE;

	new Float:flVelocity[3];
	velocity_by_aim(id, g_eCvar[CVAR_VELOCITY], flVelocity);

	set_entvar(iTarget, var_velocity, flVelocity);
	grab_disable(id);

	SetHookChainReturn(ATYPE_INTEGER, false);
	return HC_SUPERCEDE;
}