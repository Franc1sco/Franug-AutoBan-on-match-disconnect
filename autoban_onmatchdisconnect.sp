#include <sourcemod>
#include <sdktools>
#include <cstrike>
#undef REQUIRE_PLUGIN
#include <pugsetup>

#define DATA "0.1"

public Plugin myinfo =
{
	name = "SM Franug AutoBan on match disconnect",
	author = "Franc1sco franug",
	description = "",
	version = DATA,
	url = "http://steamcommunity.com/id/franug"
}

Handle array_players_ids, array_players_time, array_players_name;

ConVar cv_enable, cv_bantime, cv_time;

public void OnPluginStart()
{
	cv_enable = CreateConVar("sm_autobandisconnect_enable", "0", "Enable or disable the functions of this plugin");
	cv_bantime = CreateConVar("sm_autobandisconnect_bantime", "1440", "Ban time for people that disconnect on match live");
	cv_time = CreateConVar("sm_autobandisconnect_enable", "300", "Time for wait people to reconnect until apply the ban");
	
	array_players_ids = CreateArray(64);
	array_players_time  = CreateArray();
	array_players_name  = CreateArray(128);
	
	CreateTimer(1.0, Timer_Checker, _, TIMER_REPEAT);
}

public OnMapStart()
{
	CleanAll();
}

public Action Timer_Checker(Handle timer)
{
	if(!!cv_enable.BoolValue)
		return;
		
	int size = GetArraySize(array_players_time);
	
	if (size == 0)return;
	
	char steamid[64], name[128];
	
	for (int i = 0; i < size; i++)
	{
		if(GetTime() > GetArrayCell(array_players_time, i)+cv_time.IntValue)
		{
			GetArrayString(array_players_ids, i, steamid, sizeof(steamid));
			GetArrayString(array_players_name, i, name, sizeof(name));
			
			ServerCommand("sm_addban %i %s match abandoned", cv_bantime.IntValue, steamid);
			
			PrintToChatAll("The player %s was banned for abandoned the match", name);
			
			RemoveFromArray(array_players_time, i);
			RemoveFromArray(array_players_ids, i);
			RemoveFromArray(array_players_name, i);
		}
	}
}

public void OnClientConnected(client)
{
	if(!!cv_enable.BoolValue)
		return;
		
	char steamid[64];
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	
	int index = FindStringInArray(array_players_ids, steamid);
	
	if (index == -1)return;
	
	RemoveFromArray(array_players_time, index);
	RemoveFromArray(array_players_ids, index);
	RemoveFromArray(array_players_name, index);
	
}

public OnClientDisconnect(client)
{
	if(!cv_enable.BoolValue)
		return;
	
	char steamid[64], name[128];
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	GetClientName(client, name, sizeof(name));
	
	PushArrayString(array_players_ids, steamid);
	PushArrayCell(array_players_time, GetTime());
	PushArrayString(array_players_name, name);
}


CleanAll()
{
	ClearArray(array_players_ids);
	ClearArray(array_players_time);
	ClearArray(array_players_name);
}


// pug setup - auto enable or disable cvar when match is live or not
public void PugSetup_OnGameStateChanged(GameState before, GameState after)
{
	if(after == GameState_Live)
		SetConVarBool(cv_enable, true);
	else
		SetConVarBool(cv_enable, false);
}