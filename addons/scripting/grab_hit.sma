#include <amxmodx>
#include <hamsandwich>
#include <reapi>
#include <grab_modular>

#pragma semicolon 1

new const PLUGIN_NAME[] = "Grab: Hit";
new const PLUGIN_VERSION[] = "1.0.0";
new const PLUGIN_AUTHOR[] = "w0w";

/****************************************************************************************
****************************************************************************************/

new const g_szSoundHit[] = "player/pl_pain2.wav";

/****************************************************************************************
****************************************************************************************/

#define is_user_valid(%0) (1 <= %0 <= MaxClients)

enum _:Cvars
{
	CVAR_ENABLED,
	CVAR_DAMAGE,
	Float:CVAR_COOLDOWN,
	CVAR_GIBS
};

new g_eCvar[Cvars];

enum (+= 100)
{
	TASK_ID_HIT = 100
};

new bool:g_bHitEnabled[MAX_PLAYERS+1];

public plugin_init()
{
	register_plugin(
		.plugin_name = PLUGIN_NAME,
		.version = PLUGIN_VERSION,
		.author = PLUGIN_AUTHOR
	);

	register_dictionary("grab_hit.txt");

	RegisterHookChain(RH_SV_DropClient, "refwd_DropClient_Post", true);

	func_RegisterCvars();
}

func_RegisterCvars()
{
	new pCvar;

	pCvar = create_cvar("grab_hit_enabled", "1", FCVAR_NONE, fmt("%L", LANG_SERVER, "GRAB_HIT_CVAR_ENABLED"), true, 0.0, true, 1.0);
	bind_pcvar_num(pCvar, g_eCvar[CVAR_ENABLED]);

	pCvar = create_cvar("grab_hit_damage", "5", FCVAR_NONE, fmt("%L", LANG_SERVER, "GRAB_HIT_CVAR_DAMAGE"), true, 1.0);
	bind_pcvar_num(pCvar, g_eCvar[CVAR_DAMAGE]);

	pCvar = create_cvar("grab_hit_cooldown", "0.5", FCVAR_NONE, fmt("%L", LANG_SERVER, "GRAB_HIT_CVAR_COOLDOWN"), true, 0.1);
	bind_pcvar_float(pCvar, g_eCvar[CVAR_COOLDOWN]);

	pCvar = create_cvar("grab_hit_gibs", "2", FCVAR_NONE, fmt("%L", LANG_SERVER, "GRAB_HIT_CVAR_GIBS"), true, 1.0, true, 2.0);
	bind_pcvar_num(pCvar, g_eCvar[CVAR_GIBS]);

	AutoExecConfig(true, "grab_hit", "grab_modular");
}

public refwd_DropClient_Post(const id)
{
	if(g_bHitEnabled[id])
	{
		g_bHitEnabled[id] = false;
		remove_task(id+TASK_ID_HIT);
	}
}

public grab_on_grabbing(id, iEntity)
{
	if(!(get_entvar(id, var_button) & IN_USE) || !is_user_valid(iEntity) ||g_bHitEnabled[id])
		return;

	new Float:flOrigin[3];
	get_entvar(iEntity, var_origin, flOrigin);

	UTIL_ScreenShake(iEntity, 8.0, 4.0, 100.0);
	UTIL_Blood(flOrigin);

	new Float:flHealth;
	get_entvar(iEntity, var_health, flHealth);

	if((flHealth - g_eCvar[CVAR_DAMAGE]) > 0.0)
		set_entvar(iEntity, var_health, flHealth - g_eCvar[CVAR_DAMAGE]);
	else
		ExecuteHamB(Ham_Killed, iEntity, id, g_eCvar[CVAR_GIBS]);

	rh_emit_sound2(iEntity, 0, CHAN_BODY, g_szSoundHit, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	g_bHitEnabled[id] = true;
	set_task(g_eCvar[CVAR_COOLDOWN], "task_GrabHit", id+TASK_ID_HIT);
}

public grab_on_finish(id, iEntity)
{
	if(g_bHitEnabled[id])
	{
		g_bHitEnabled[id] = false;
		remove_task(id+TASK_ID_HIT);
	}
}

public task_GrabHit(id)
{
	id -= TASK_ID_HIT;

	g_bHitEnabled[id] = false;
}

/****************************************************************************************
****************************************************************************************/

stock UTIL_ScreenShake(id, Float:flAmplitude, Float:flDuration, Float:flFrequency)
{
	static iMsgScreenShake;

	if(!iMsgScreenShake)
		iMsgScreenShake = get_user_msgid("ScreenShake");

	new iAmplitude = UTIL_FixedUnsigned16(flAmplitude, 1<<12);	// max 16.0
	new iDuration = UTIL_FixedUnsigned16(flDuration, 1<<12);	// max 16.0
	new iFrequency = UTIL_FixedUnsigned16(flFrequency, 1<<8);	// max 256.0

	message_begin(MSG_ONE, iMsgScreenShake, .player = id);
	{
		write_short(iAmplitude);					// amplitude
		write_short(iDuration);						// duration
		write_short(iFrequency);					// frequency
	}
	message_end();
}

// thx ConnorMcLeod
stock UTIL_FixedUnsigned16(Float:flValue, iScale)
{
    new iOutput;

    iOutput = floatround(flValue * iScale);

    if (iOutput < 0)
        iOutput = 0;

    if (iOutput > 0xFFFF)
        iOutput = 0xFFFF;

    return iOutput;
}

stock UTIL_Blood(Float:flOrigin[3])
{
	message_begin_f(MSG_BROADCAST, SVC_TEMPENTITY);
	{
		write_byte(TE_BLOODSTREAM);
		write_coord_f(flOrigin[0]);					// pos.x
		write_coord_f(flOrigin[1]);					// pos.y
		write_coord_f(flOrigin[2] + 15);			// pos.z
		write_coord_f(random_float(0.0, 255.0));	// vec.x
		write_coord_f(random_float(0.0, 255.0));	// vec.y
		write_coord_f(random_float(0.0, 255.0));	// vec.z
		write_byte(70);								// col index
		write_byte(random_num(50, 250));			// speed
	}
	message_end();
}