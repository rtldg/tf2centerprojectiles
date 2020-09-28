/*
Copyright 2020, rtldg

Copying and distribution of this file, with or without modification, are permitted in any medium without royalty, provided the copyright notice and this notice are preserved. This file is offered as-is, without any warranty.
*/

#include <sourcemod>
#include <clientprefs>
#include <tf2_stocks>

#include <tf2attributes> // https://github.com/FlaminSarge/tf2attributes

public Plugin myinfo = {
	name = "[TF2] Centered Rockets",
	author = "rtldg",
	version = "6.9",
	url = "https://github.com/rtldg/tf2centeredrockets",
	description = "Provides the command sm_tf2centeredrockets <0|1> to shoot rockets from the center (like The Original) for any rocket launcher."
};

Handle g_hCenteredRockets;

public void OnPluginStart()
{
	RegConsoleCmd("sm_tf2centeredrockets", sm_tf2centeredrockets, "sm_tf2centeredrockets to toggle or sm_tf2centeredrockets <1|0> to set");
	g_hCenteredRockets = RegClientCookie("tf2centeredrockets", "TF2 Centered Rockets thing", CookieAccess_Protected);
	
	// Called every player spawn...
	HookEvent("player_spawn", Event_EverythingEver, EventHookMode_Post);
	// Sent when a player gets a whole new set of items, aka touches a resupply locker / respawn cabinet or spawns in.
	HookEvent("post_inventory_application", Event_EverythingEver, EventHookMode_Post);
}

Action sm_tf2centeredrockets(int client, int args)
{
	if (client < 1 || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;

	// No arguments. Toggle.
	if (args == 0)
	{
		SetCentered(client, !GetCentered(client));
		CenterRocketsMaybe(client);
		PrintToChat(client, "TF2 Centered Rockets toggled");
		return Plugin_Handled;
	}

	char arg[128];
	GetCmdArg(1, arg, sizeof(arg));

	int val = StringToInt(arg, 10);
	if (val == 0)
	{
		SetCentered(client, false);
		CenterRocketsMaybe(client, 0.0);
		PrintToChat(client, "TF2 Centered Rockets disabled");
		return Plugin_Handled;
	}
	else
	{
		SetCentered(client, true);
		CenterRocketsMaybe(client, 1.0);
		PrintToChat(client, "TF2 Centered Rockets enabled");
		return Plugin_Handled;
	}
}

Action Event_EverythingEver(Event event, const char[] name, bool dontBroadcast)
{
	CenterRocketsMaybe(GetClientOfUserId(event.GetInt("userid")));
	return Plugin_Continue;
}

bool GetCentered(int client)
{
	char cookie[2];
	GetClientCookie(client, g_hCenteredRockets, cookie, sizeof(cookie));
	return cookie[0] == '1';
}

void SetCentered(int client, bool center)
{
	char cookie[2];
	cookie[0] = center ? '1' : '0';
	SetClientCookie(client, g_hCenteredRockets, cookie);
}

void CenterRocketsMaybe(int client, float forced=-1.0)
{
	if (IsFakeClient(client) || TF2_GetPlayerClass(client) != TFClass_Soldier)
		return;
	int rocketlauncher = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	if (rocketlauncher == -1) // How could this happen? :thinking:
		return;
	float thing = forced;
	if (thing == -1.0)
		thing = GetCentered(client) ? 1.0 : 0.0;
	// List of attributes at https://wiki.teamfortress.com/wiki/List_of_item_attributes
	// 289 == centerfire_projectile
	TF2Attrib_SetByDefIndex(rocketlauncher, 289, thing); 
	//TF2Attrib_SetByName(rocketlauncher, "centerfire_projectile", thing); // doesn't work...
}
