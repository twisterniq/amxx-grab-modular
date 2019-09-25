#include <amxmodx>
#include <reapi>
#include <grab_modular>

#pragma semicolon 1

new const PLUGIN_NAME[] = "Grab: No Fall Damage After Grabbing";
new const PLUGIN_VERSION[] = "1.0.0";
new const PLUGIN_AUTHOR[] = "w0w";

/****************************************************************************************
****************************************************************************************/

enum _:Cvars
{
	CVAR_ENABLED,
};

new g_eCvar[Cvars];

new bool:g_bPlayerInAir[MAX_PLAYERS+1];

public plugin_init()
{
	register_plugin(
		.plugin_name = PLUGIN_NAME,
		.version = PLUGIN_VERSION,
		.author = PLUGIN_AUTHOR
	);

	register_dictionary("grab_no_fall_damage_after_grabbing.txt");

	RegisterHookChain(RG_CSGameRules_FlPlayerFallDamage, "refwd_FlPlayerFallDamage_Pre", false);
	RegisterHookChain(RH_SV_DropClient, "refwd_DropClient_Post", true);

	func_RegisterCvars();
}

func_RegisterCvars()
{
	new pCvar;

	pCvar = create_cvar("grab_no_fall_damage_after_grabbing_enabled", "1", FCVAR_NONE, fmt("%L", LANG_SERVER, "GRAB_NO_FALL_DAMAGE_AFTER_GRABBING_CVAR_ENABLED"), true, 0.0, true, 1.0);
	bind_pcvar_num(pCvar, g_eCvar[CVAR_ENABLED]);

	AutoExecConfig(true, "grab_no_fall_damage_after_grabbing", "grab_modular");
}

public grab_on_start(id, iEntity)
{
	if(!g_eCvar[CVAR_ENABLED])
		return;

	if(is_user_connected(iEntity))
		g_bPlayerInAir[iEntity] = false;
}

public grab_on_finish(id, iEntity)
{
	if(!g_eCvar[CVAR_ENABLED])
		return;

	if(!is_user_connected(iEntity) || get_entvar(iEntity, var_flags) & FL_ONGROUND)
		return;

	g_bPlayerInAir[iEntity] = true;
}

public refwd_FlPlayerFallDamage_Pre(const id)
{
	if(!g_eCvar[CVAR_ENABLED])
		return HC_CONTINUE;

	if(!g_bPlayerInAir[id])
		return HC_CONTINUE;

	g_bPlayerInAir[id] = false;

	SetHookChainReturn(ATYPE_FLOAT, 0.0);
	return HC_CONTINUE;
}

public refwd_DropClient_Post(const id)
{
	g_bPlayerInAir[id] = false;
}