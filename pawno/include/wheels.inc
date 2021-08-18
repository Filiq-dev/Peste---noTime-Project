//------------------------------------------
//  Wheels System
//	Created By : JonathanW
//------------------------------------------
#define FILTERSCRIPT

#include <a_samp>


new PlayerText:Wheels[MAX_PLAYERS][23];
new Page[MAX_PLAYERS];

public OnFilterScriptInit()
{
	print("\n----------------------------------------");
	print("-- Wheels System - Created by JonathanW v2 --");
	print("----------------------------------------\n");
    CreateVehicle(400, 1950.0590,1297.8616,9.1094,136.684, 1, 1, 10000);
	return 1;
}

stock ShowWheels(playerid)
{
	PlayerTextDrawShow(playerid, Wheels[playerid][0]);
	PlayerTextDrawShow(playerid, Wheels[playerid][1]);
	PlayerTextDrawShow(playerid, Wheels[playerid][2]);
	PlayerTextDrawShow(playerid, Wheels[playerid][3]);
	PlayerTextDrawShow(playerid, Wheels[playerid][4]);
	PlayerTextDrawShow(playerid, Wheels[playerid][5]);
	PlayerTextDrawShow(playerid, Wheels[playerid][6]);
	PlayerTextDrawShow(playerid, Wheels[playerid][7]);
	PlayerTextDrawShow(playerid, Wheels[playerid][8]);
	PlayerTextDrawShow(playerid, Wheels[playerid][9]);
	PlayerTextDrawShow(playerid, Wheels[playerid][10]);
	PlayerTextDrawShow(playerid, Wheels[playerid][11]);
	PlayerTextDrawShow(playerid, Wheels[playerid][12]);
	PlayerTextDrawShow(playerid, Wheels[playerid][13]);
	PlayerTextDrawShow(playerid, Wheels[playerid][14]);
	PlayerTextDrawShow(playerid, Wheels[playerid][15]);
	PlayerTextDrawShow(playerid, Wheels[playerid][20]);

	PlayerTextDrawShow(playerid, Wheels[playerid][22]);
	PlayerTextDrawSetString(playerid, Wheels[playerid][22], "Next ~g~>");
	PlayerTextDrawShow(playerid, Wheels[playerid][21]);
	Page[playerid] = 1;
	
	SelectTextDraw(playerid,0xFFFFFFFF);
	return 1;
}
stock HideWheels(playerid)
{
	PlayerTextDrawHide(playerid, Wheels[playerid][0]);
	PlayerTextDrawHide(playerid, Wheels[playerid][1]);
	PlayerTextDrawHide(playerid, Wheels[playerid][2]);
	PlayerTextDrawHide(playerid, Wheels[playerid][3]);
	PlayerTextDrawHide(playerid, Wheels[playerid][4]);
	PlayerTextDrawHide(playerid, Wheels[playerid][5]);
	PlayerTextDrawHide(playerid, Wheels[playerid][6]);
	PlayerTextDrawHide(playerid, Wheels[playerid][7]);
	PlayerTextDrawHide(playerid, Wheels[playerid][8]);
	PlayerTextDrawHide(playerid, Wheels[playerid][9]);
	PlayerTextDrawHide(playerid, Wheels[playerid][10]);
	PlayerTextDrawHide(playerid, Wheels[playerid][11]);
	PlayerTextDrawHide(playerid, Wheels[playerid][12]);
	PlayerTextDrawHide(playerid, Wheels[playerid][13]);
	PlayerTextDrawHide(playerid, Wheels[playerid][14]);
	PlayerTextDrawHide(playerid, Wheels[playerid][15]);
	PlayerTextDrawHide(playerid, Wheels[playerid][16]);
	PlayerTextDrawHide(playerid, Wheels[playerid][17]);
	PlayerTextDrawHide(playerid, Wheels[playerid][18]);
	PlayerTextDrawHide(playerid, Wheels[playerid][19]);
	PlayerTextDrawHide(playerid, Wheels[playerid][20]);
	PlayerTextDrawHide(playerid, Wheels[playerid][21]);
	PlayerTextDrawHide(playerid, Wheels[playerid][22]);
	Page[playerid] = 0;
	CancelSelectTextDraw(playerid);
	return 1;
}
stock ShowPage2(playerid)
{
    PlayerTextDrawHide(playerid, Wheels[playerid][3]);
	PlayerTextDrawHide(playerid, Wheels[playerid][4]);
	PlayerTextDrawHide(playerid, Wheels[playerid][5]);
	PlayerTextDrawHide(playerid, Wheels[playerid][6]);
	PlayerTextDrawHide(playerid, Wheels[playerid][7]);
	PlayerTextDrawHide(playerid, Wheels[playerid][8]);
	PlayerTextDrawHide(playerid, Wheels[playerid][9]);
	PlayerTextDrawHide(playerid, Wheels[playerid][10]);
	PlayerTextDrawHide(playerid, Wheels[playerid][11]);
	PlayerTextDrawHide(playerid, Wheels[playerid][12]);
	PlayerTextDrawHide(playerid, Wheels[playerid][13]);
	PlayerTextDrawHide(playerid, Wheels[playerid][14]);
	PlayerTextDrawHide(playerid, Wheels[playerid][15]);
	
	PlayerTextDrawShow(playerid, Wheels[playerid][16]);
	PlayerTextDrawShow(playerid, Wheels[playerid][17]);
	PlayerTextDrawShow(playerid, Wheels[playerid][18]);
	PlayerTextDrawShow(playerid, Wheels[playerid][19]);
	
	PlayerTextDrawSetString(playerid, Wheels[playerid][22], "Prev ~g~<");
	PlayerTextDrawShow(playerid, Wheels[playerid][22]);
	Page[playerid] = 2;
	
	return 1;
}
stock ShowPage1(playerid)
{
    PlayerTextDrawShow(playerid, Wheels[playerid][3]);
	PlayerTextDrawShow(playerid, Wheels[playerid][4]);
	PlayerTextDrawShow(playerid, Wheels[playerid][5]);
	PlayerTextDrawShow(playerid, Wheels[playerid][6]);
	PlayerTextDrawShow(playerid, Wheels[playerid][7]);
	PlayerTextDrawShow(playerid, Wheels[playerid][8]);
	PlayerTextDrawShow(playerid, Wheels[playerid][9]);
	PlayerTextDrawShow(playerid, Wheels[playerid][10]);
	PlayerTextDrawShow(playerid, Wheels[playerid][11]);
	PlayerTextDrawShow(playerid, Wheels[playerid][12]);
	PlayerTextDrawShow(playerid, Wheels[playerid][13]);
	PlayerTextDrawShow(playerid, Wheels[playerid][14]);
	PlayerTextDrawShow(playerid, Wheels[playerid][15]);
	
	PlayerTextDrawHide(playerid, Wheels[playerid][16]);
	PlayerTextDrawHide(playerid, Wheels[playerid][17]);
	PlayerTextDrawHide(playerid, Wheels[playerid][18]);
	PlayerTextDrawHide(playerid, Wheels[playerid][19]);
	
	PlayerTextDrawSetString(playerid, Wheels[playerid][22], "Next ~g~>");
	PlayerTextDrawShow(playerid, Wheels[playerid][22]);
	Page[playerid] = 1;
	
	return 1;
}
