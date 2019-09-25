#include <amxmodx>
#include <reapi>
#include <grab_modular>

#pragma semicolon 1

new const PLUGIN_NAME[] = "Grab: No Fall Damage on Grabbing";
new const PLUGIN_VERSION[] = "1.0.0";
new const PLUGIN_AUTHOR[] = "w0w";

/****************************************************************************************
****************************************************************************************/

enum _:Cvars
{
	CVAR_ENABLED,
};

new g_eCvar[Cvars];

public plugin_init()
{
	register_plugin(
		.plugin_name = PLUGIN_NAME,
		.version = PLUGIN_VERSION,
		.author = PLUGIN_AUTHOR
	);

	register_dictionary("grab_no_fall_damage_on_grabbing.txt");

	RegisterHookChain(RG_CSGameRules_FlPlayerFallDamage, "refwd_FlPlayerFallDamage_Pre", false);

	func_RegisterCvars();
}

func_RegisterCvars()
{
	new pCvar = create_cvar("grab_no_fall_damage_on_grabbing_enabled", "1", FCVAR_NONE, fmt("%L", LANG_SERVER, "GRAB_NO_FALL_DAMAGE_ON_GRABBING_CVAR_ENABLED"), true, 0.0, true, 1.0);
	bind_pcvar_num(pCvar, g_eCvar[CVAR_ENABLED]);

	AutoExecConfig(true, "grab_no_fall_damage_on_grabbing", "grab_modular");
}

public refwd_FlPlayerFallDamage_Pre(const id)
{
	if(!g_eCvar[CVAR_ENABLED])
		return HC_CONTINUE;

	if(!is_entity_grabbed(id))
		return HC_CONTINUE;

	SetHookChainReturn(ATYPE_FLOAT, 0.0);
	return HC_CONTINUE;
}