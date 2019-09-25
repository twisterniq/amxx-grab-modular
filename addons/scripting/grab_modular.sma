#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <reapi>

#pragma semicolon 1

new const PLUGIN_NAME[] = "Grab Modular";
new const PLUGIN_VERSION[] = "1.0.0";
new const PLUGIN_AUTHOR[] = "w0w";

/****************************************************************************************
****************************************************************************************/

#define is_user_valid(%0) (1 <= %0 <= MaxClients)

#define CHECK_PLAYER(%0) \
    if (!is_user_valid(%0)) \
        abort(AMX_ERR_NATIVE, "Player out of range (%d)", %0);

const GRAB_ENABLED = -1;

enum _:Forwards
{
	FORWARD_ON_USE_COMMAND,
	FORWARD_ON_START,
	FORWARD_ON_FINISH,
	FORWARD_ON_GRABBING
};

new g_iForward[Forwards];

enum _:GrabData
{
	GRABBER,
	GRABBED,
	Float:GRAB_DISTANCE
};

new g_ePlayerGrabData[MAX_PLAYERS+1][GrabData];

enum _:Cvars
{
	CVAR_ENABLED,
	Float:CVAR_MIN_DISTANCE,
	CVAR_MAX_DISTANCE,
	CVAR_FORCE,
	CVAR_LADDER_SUPPORT
};

new g_eCvar[Cvars];

new g_iCommandId;
new bool:g_bHasGrabAccess[MAX_PLAYERS+1];

public plugin_init()
{
	register_plugin(
		.plugin_name = PLUGIN_NAME,
		.version = PLUGIN_VERSION,
		.author = PLUGIN_AUTHOR
	);

	register_dictionary("grab_modular.txt");

	g_iCommandId = register_clcmd("+grab", "func_ClCmdGrabEnable", ADMIN_LEVEL_C);
	register_clcmd("-grab", "func_GrabDisable");

	g_iForward[FORWARD_ON_USE_COMMAND] = CreateMultiForward("grab_on_use_command", ET_STOP, FP_CELL);
	g_iForward[FORWARD_ON_START] = CreateMultiForward("grab_on_start", ET_STOP, FP_CELL, FP_CELL);
	g_iForward[FORWARD_ON_FINISH] = CreateMultiForward("grab_on_finish", ET_IGNORE, FP_CELL, FP_CELL);
	g_iForward[FORWARD_ON_GRABBING] = CreateMultiForward("grab_on_grabbing", ET_STOP, FP_CELL, FP_CELL);

	RegisterHookChain(RH_SV_DropClient, "refwd_DropClient_Post", true);
	register_forward(FM_CmdStart, "fmfwd_CmdStart_Post", true);

	func_RegisterCvars();
}

func_RegisterCvars()
{
	new pCvar;

	pCvar = create_cvar("grab_enabled", "1", FCVAR_NONE, fmt("%L", LANG_SERVER, "GRAB_CVAR_ENABLED"), true, 0.0, true, 1.0);
	bind_pcvar_num(pCvar, g_eCvar[CVAR_ENABLED]);

	pCvar = create_cvar("grab_min_distance", "90.0", FCVAR_NONE, fmt("%L", LANG_SERVER, "GRAB_CVAR_MIN_DISTANCE"), true, 1.0);
	bind_pcvar_float(pCvar, g_eCvar[CVAR_MIN_DISTANCE]);

	pCvar = create_cvar("grab_max_distance", "2000", FCVAR_NONE, fmt("%L", LANG_SERVER, "GRAB_CVAR_MAX_DISTANCE"), true, 1.0);
	bind_pcvar_num(pCvar, g_eCvar[CVAR_MAX_DISTANCE]);

	pCvar = create_cvar("grab_force", "8", FCVAR_NONE, fmt("%L", LANG_SERVER, "GRAB_CVAR_FORCE"), true, 0.1);
	bind_pcvar_num(pCvar, g_eCvar[CVAR_FORCE]);

	pCvar = create_cvar("grab_ladder_support", "1", FCVAR_NONE, fmt("%L", LANG_SERVER, "GRAB_CVAR_LADDER_SUPPORT"), true, 0.0, true, 1.0);
	bind_pcvar_num(pCvar, g_eCvar[CVAR_LADDER_SUPPORT]);

	AutoExecConfig(true, "grab_modular", "grab_modular");
}

public plugin_natives()
{
	register_library("grab_modular");

	register_native("is_entity_grabbed", "NativeHandle_IsEntityGrabbed");
	register_native("is_player_grabbing", "NativeHandle_IsPlayerGrabbing");

	register_native("grab_has_player_access", "NativeHandle_HasPlayerAccess");
	register_native("grab_set_player_access", "NativeHandle_SetPlayerAccess");

	register_native("grab_get_distance", "NativeHandle_GetDistance");
	register_native("grab_set_distance", "NativeHandle_SetDistance");

	register_native("grab_disable", "NativeHandle_GrabDisable");
}

public NativeHandle_IsEntityGrabbed(iPlugin, iParams)
{
	enum { arg_entity = 1 };

	return func_GetEntityGrabber(get_param(arg_entity));
}

public NativeHandle_IsPlayerGrabbing(iPlugin, iParams)
{
	enum { arg_player = 1 };

	new iPlayer = get_param(arg_player);

	CHECK_PLAYER(iPlayer)

	return g_ePlayerGrabData[iPlayer][GRABBED];
}

public bool:NativeHandle_HasPlayerAccess(iPlugin, iParams)
{
	enum { arg_player = 1, arg_custom };

	new iPlayer = get_param(arg_player);

	CHECK_PLAYER(iPlayer)

	new bool:bCustom = bool:get_param(arg_custom);

	if(!bCustom)
		return (cmd_access2(iPlayer, g_iCommandId) || g_bHasGrabAccess[iPlayer]);
	else
		return g_bHasGrabAccess[iPlayer];
}

public NativeHandle_SetPlayerAccess(iPlugin, iParams)
{
	enum { arg_player = 1, arg_set };

	new iPlayer = get_param(arg_player);
	new bool:bSet = bool:get_param(arg_set);

	if(iPlayer)
	{
		CHECK_PLAYER(iPlayer)

		g_bHasGrabAccess[iPlayer] = bSet;
	}
	else
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!is_user_connected(i))
				continue;

			g_bHasGrabAccess[i] = bSet;
		}
	}
}

public Float:NativeHandle_GetDistance(iPlugin, iParams)
{
	enum { arg_player = 1, arg_entity };

	new iPlayer = get_param(arg_player);

	CHECK_PLAYER(iPlayer)

	new iEntity = get_param(arg_entity);

	if(g_ePlayerGrabData[iPlayer][GRABBED] != iEntity)
		return 0.0;

	return g_ePlayerGrabData[iPlayer][GRAB_DISTANCE];
}

public bool:NativeHandle_SetDistance(iPlugin, iParams)
{
	enum { arg_player = 1, arg_entity, arg_distance };

	new iPlayer = get_param(arg_player);

	CHECK_PLAYER(iPlayer)

	new iEntity = get_param(arg_entity);

	if(g_ePlayerGrabData[iPlayer][GRABBED] != iEntity)
		return false;

	if(g_ePlayerGrabData[iPlayer][GRAB_DISTANCE] == g_eCvar[CVAR_MIN_DISTANCE])
		return false;

	new Float:flDistance = get_param_f(arg_distance);

	g_ePlayerGrabData[iPlayer][GRAB_DISTANCE] = floatclamp(flDistance, g_eCvar[CVAR_MIN_DISTANCE], float(g_eCvar[CVAR_MAX_DISTANCE]));

	return true;
}

public bool:NativeHandle_GrabDisable(iPlugin, iParams)
{
	enum { arg_player = 1 };

	new iPlayer = get_param(arg_player);

	if(iPlayer)
	{
		CHECK_PLAYER(iPlayer)

		if(!g_ePlayerGrabData[iPlayer][GRABBED])
			return false;

		func_GrabDisable(iPlayer);
	}
	else
	{
		new iCount;

		for(new i = 1; i <= MaxClients; i++)
		{
			if(!g_ePlayerGrabData[i][GRABBED])
				continue;

			func_GrabDisable(i);
			iCount++;
		}

		if(!iCount)
			return false;
	}

	return true;
}

public func_ClCmdGrabEnable(const id, iAccess, iCommand)
{
	if(!cmd_access(id, iAccess, iCommand, 0) && !g_bHasGrabAccess[id])
		return PLUGIN_HANDLED;

	new iResult;
	ExecuteForward(g_iForward[FORWARD_ON_USE_COMMAND], iResult, id);

	if(iResult >= PLUGIN_HANDLED)
		return PLUGIN_HANDLED;

	if(!g_ePlayerGrabData[id][GRABBED])
		g_ePlayerGrabData[id][GRABBED] = GRAB_ENABLED;

	return PLUGIN_HANDLED;
}

public func_GrabDisable(const id)
{
	if(!g_ePlayerGrabData[id][GRABBED])
		return PLUGIN_HANDLED;

	new iTarget = g_ePlayerGrabData[id][GRABBED];

	if(is_user_valid(iTarget))
	{
		g_ePlayerGrabData[iTarget][GRABBER] = 0;

		if(g_eCvar[CVAR_LADDER_SUPPORT])
			func_SetClimbAbility(iTarget, true);
	}

	if(iTarget > 0)
		ExecuteForward(g_iForward[FORWARD_ON_FINISH], _, id, iTarget);

	g_ePlayerGrabData[id][GRABBED] = 0;
	g_ePlayerGrabData[id][GRAB_DISTANCE] = 0.0;

	return PLUGIN_HANDLED;
}

public refwd_DropClient_Post(const id)
{
	if(g_ePlayerGrabData[id][GRABBER])
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(g_ePlayerGrabData[i][GRABBED] == id)
			{
				func_GrabDisable(i);
				break;
			}
		}
	}

	arrayset(g_ePlayerGrabData[id], 0, sizeof g_ePlayerGrabData[]);

	g_bHasGrabAccess[id] = false;
}

public fmfwd_CmdStart_Post(const id, iHandle)
{
	static iTarget;

	if(g_ePlayerGrabData[id][GRABBED] == GRAB_ENABLED)
	{
		new Float:flResult[3];
		flResult = UTIL_VelocityByAim(id, float(g_eCvar[CVAR_MAX_DISTANCE]));

		new Float:flOrigin[3];
		UTIL_GetViewPosition(id, flOrigin);

		flResult[0] += flOrigin[0];
		flResult[1] += flOrigin[1];
		flResult[2] += flOrigin[2];

		iTarget = UTIL_GetTargetByTraceLine(flOrigin, flResult, id, flResult);

		if(is_user_valid(iTarget))
		{
			if(func_IsEntityGrabbed(iTarget))
			{
				func_GrabDisable(id);
				return;
			}

			func_SetEntityGrabbed(id, iTarget);
		}
		else
		{
			new iMoveType;

			if(iTarget > 0 && is_entity(iTarget))
			{
				iMoveType = get_entvar(iTarget, var_movetype);

				if(!(iMoveType == MOVETYPE_WALK || iMoveType == MOVETYPE_STEP || iMoveType == MOVETYPE_TOSS || iMoveType == MOVETYPE_BOUNCE))
					return;
			}
			else
			{
				iTarget = 0;

				const Float:flRadius = 5.0;

				new iEnt = engfunc(EngFunc_FindEntityInSphere, -1, flResult, flRadius);

				while(!iTarget && iEnt > 0)
				{
					iMoveType = get_entvar(iEnt, var_movetype);

					if(iEnt != id && (iMoveType == MOVETYPE_WALK || iMoveType == MOVETYPE_STEP || iMoveType == MOVETYPE_TOSS || iMoveType == MOVETYPE_BOUNCE))
						iTarget = iEnt;

					iEnt = engfunc(EngFunc_FindEntityInSphere, iEnt, flResult, flRadius);
				}
			}

			if(iTarget)
			{
				if(!is_entity(iTarget) || func_IsEntityGrabbed(iTarget))
					return;

				func_SetEntityGrabbed(id, iTarget);
			}
		}

		return;
	}

	iTarget = g_ePlayerGrabData[id][GRABBED];

	if(iTarget > 0)
	{
		if(!pev_valid(iTarget) || Float:get_entvar(iTarget, var_max_health) && (Float:get_entvar(iTarget, var_health) < 1.0))
		{
			func_GrabDisable(id);
			return;
		}

		if(iTarget > MaxClients)
			func_GrabThink(id);
	}

	iTarget = g_ePlayerGrabData[id][GRABBER];

	if(iTarget > 0)
		func_GrabThink(iTarget);
}

func_GetEntityGrabber(iEntity)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(g_ePlayerGrabData[i][GRABBED] == iEntity)
			return i;
	}

	return 0;
}

bool:func_IsEntityGrabbed(iEntity)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(g_ePlayerGrabData[i][GRABBED] == iEntity)
			return true;
	}

	return false;
}

func_SetEntityGrabbed(id, iTarget)
{
	new iResult;
	ExecuteForward(g_iForward[FORWARD_ON_START], iResult, id, iTarget);

	if(iResult >= PLUGIN_HANDLED)
		return;

	new bool:bPlayer = is_user_valid(iTarget);

	g_ePlayerGrabData[id][GRABBED] = iTarget;

	if(bPlayer)
	{
		g_ePlayerGrabData[iTarget][GRABBER] = id;

		if(g_eCvar[CVAR_LADDER_SUPPORT])
			func_SetClimbAbility(iTarget, false);
	}

	new Float:flOrigin[3];
	get_entvar(id, var_origin, flOrigin);

	new Float:flTargetOrigin[3];
	get_entvar(iTarget, var_origin, flTargetOrigin);

	g_ePlayerGrabData[id][GRAB_DISTANCE] = get_distance_f(flOrigin, flTargetOrigin);

	if(g_ePlayerGrabData[id][GRAB_DISTANCE] < g_eCvar[CVAR_MIN_DISTANCE])
		g_ePlayerGrabData[id][GRAB_DISTANCE] = g_eCvar[CVAR_MIN_DISTANCE];
}

func_GrabThink(id)
{
	new iTarget = g_ePlayerGrabData[id][GRABBED];

	new iResult;
	ExecuteForward(g_iForward[FORWARD_ON_GRABBING], iResult, id, iTarget);

	if(iResult >= PLUGIN_HANDLED)
	{
		func_GrabDisable(id);
		return;
	}

	func_SetClimbAbility(iTarget, false);

	new iOrigin[3], Float:flOrigin[3], Float:flOrigin2[3], Float:flEntityOrigin[3], Float:flTVelocity[3];

	get_user_origin(id, iOrigin, Origin_Eyes);
	IVecFVec(iOrigin, flOrigin);

	velocity_by_aim(id, floatround(g_ePlayerGrabData[id][GRAB_DISTANCE]), flOrigin2);

	flEntityOrigin = func_GetEntityGrabbedOrigin(iTarget);

	flTVelocity[0] = ((flOrigin[0] + flOrigin2[0]) - flEntityOrigin[0]) * g_eCvar[CVAR_FORCE];
	flTVelocity[1] = ((flOrigin[1] + flOrigin2[1]) - flEntityOrigin[1]) * g_eCvar[CVAR_FORCE];
	flTVelocity[2] = ((flOrigin[2] + flOrigin2[2]) - flEntityOrigin[2]) * g_eCvar[CVAR_FORCE];

	set_entvar(iTarget, var_velocity, flTVelocity);
}

/****************************************************************************************
****************************************************************************************/

stock UTIL_GetTargetByTraceLine(const Float:flVStart[3], const Float:flVEnd[3], const pIgnore, Float:flVHitPos[3])
{
	engfunc(EngFunc_TraceLine, flVStart, flVEnd, 0, pIgnore, 0);
	get_tr2(0, TR_vecEndPos, flVHitPos);
	return get_tr2(0, TR_pHit);
}

stock UTIL_GetViewPosition(const id, Float:flViewPosition[3])
{
	new Float:flVOfs[3];
	get_entvar(id, var_origin, flViewPosition);
	get_entvar(id, var_view_ofs, flVOfs);	

	flViewPosition[0] += flVOfs[0];
	flViewPosition[1] += flVOfs[1];
	flViewPosition[2] += flVOfs[2];
}

stock Float:UTIL_VelocityByAim(id, Float:flSpeed = 1.0)
{
	new Float:flV1[3], Float:flV2[3];
	get_entvar(id, var_v_angle, flV1);
	engfunc(EngFunc_AngleVectors, flV1, flV1, flV2, flV2);

	flV1[0] *= flSpeed;
	flV1[1] *= flSpeed;
	flV1[2] *= flSpeed;

	return flV1;
}

stock rg_get_rendering(id, &iRenderFx = kRenderFxNone, &Float:flRed = 0.0, &Float:flGreen = 0.0, &Float:flBlue = 0.0, &iRenderMode = kRenderNormal, &Float:flAmount = 0.0)
{
	new Float:flRenderColor[3];
	get_entvar(id, var_rendercolor, flRenderColor);

	iRenderFx = get_entvar(id, var_renderfx);

	flRed = flRenderColor[0];
	flGreen = flRenderColor[1];
	flBlue = flRenderColor[2];

	iRenderMode = get_entvar(id, var_rendermode);
	get_entvar(id, var_renderamt, flAmount);
}

// thx s1lent
stock func_SetClimbAbility(id, bool:bCanClimb)
{
	new iFlags = get_entvar(id, var_iuser3);

	if(bCanClimb)
		iFlags &= ~PLAYER_PREVENT_CLIMB;
	else
		iFlags |= PLAYER_PREVENT_CLIMB;

	set_entvar(id, var_iuser3, iFlags);
}

stock Float:func_GetEntityGrabbedOrigin(iEnt)
{
	new Float:flOrigin[3];
	get_entvar(iEnt, var_origin, flOrigin);

	if(iEnt > MaxClients)
	{
		new Float:flMins[3], Float:flMaxs[3];
		get_entvar(iEnt, var_mins, flMins);
		get_entvar(iEnt, var_maxs, flMaxs);

		if(!flMins[2])
			flOrigin[2] += flMaxs[2] / 2;
	}

	return flOrigin;
}

stock bool:cmd_access2(id, iCommand)
{
	new iFlags;
	get_clcmd(iCommand, "", 0, iFlags, "", 0, 0);

	return bool:(get_user_flags(id) & iFlags);
}