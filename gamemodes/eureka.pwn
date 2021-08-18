// eureka RPG - Summer Project
// Started on: 01.06.2017 (by L0K3D)
// Edited by -

/*
===================================================================
----------------------- Informations -----------------------
===================================================================

// Group types:
	1 - Police
	2 - Paramedic
	3 - Gangs
	4 - Hitman
	5 - S.I
	6 - Taxi
	7 - News Reporters


// Job types:
	1 - Detective
	2 - Arms Dealer
	3 - Drugs Dealer

// Checkpoint types: 5
	1 - location
	2 - arms dealer
	3 - locul gresit (nu esti in locatia potrivita, arata locatia)
	4 - comanda /work in momentul in care nu este la locul potrivit
*/


// General includes

#include <a_samp>
#include <a_mysql>
#include <fixes>
#include <foreach>
#include <sscanf2>
#include <streamer>
#include <regex>
#include <a_zone>



#include <YSI\y_master>
#include <YSI\y_commands>
#include <YSI\y_timers>
#include <YSI\y_iterate>
#include <YSI\y_stringhash>

#include <define>
#include <fly>
#include <mSelection>
#include <callbacks>
#include <tdFade>
#include <deathClear>

// Maps
#include <maps>
#include <mapFix>

#define GetName(%0) playerConnectName[%0]

// Natives

native WP_Hash(buffer[], len, const str[]);
native SendClientCheck(playerid, actionid, memaddr, memOffset, bytesCount); 

new handle, rows, fields;
new
	bool:flyingStatus[MAX_PLAYERS],
	bool:adminDuty[MAX_PLAYERS],
	bool:Freeze[MAX_PLAYERS],
	bool:carCreatingSession[MAX_PLAYERS],
	bool:spawnedVehicle[MAX_VEHICLES],

	pLogged[MAX_PLAYERS], loginTries[MAX_PLAYERS], playerHashedPass[MAX_PLAYERS][129], enteredCode[MAX_PLAYERS],
	PlayerZonesStatus[MAX_PLAYERS], TakingLesson[MAX_PLAYERS],
	pDrunkLevelLast[MAX_PLAYERS], FPS2[MAX_PLAYERS], 

	sdDrugs[MAX_PLAYERS], sdPrice[MAX_PLAYERS], sdID[MAX_PLAYERS], sdSwitch[MAX_PLAYERS],
	cgWeapon[MAX_PLAYERS], cgSwitch[MAX_PLAYERS], cgPrice[MAX_PLAYERS], cgMats[MAX_PLAYERS], cgID[MAX_PLAYERS],
	smMats[MAX_PLAYERS], smPrice[MAX_PLAYERS], smID[MAX_PLAYERS], smSwitch[MAX_PLAYERS],

	DMVTest[MAX_PLAYERS], PenaltyPoints[MAX_PLAYERS], DMVVehicle[MAX_PLAYERS], DMVLastSpeed[MAX_PLAYERS], DMVLastcrash[MAX_PLAYERS], DMVObject[MAX_PLAYERS], DMVCP[MAX_PLAYERS],

	Checkpoint[MAX_PLAYERS],
	playerHQ[MAX_PLAYERS],
	buyCarSession[MAX_PLAYERS],

	playerLive[MAX_PLAYERS],
	Float:lastPlayerHP[MAX_PLAYERS], Float:playerHP[MAX_PLAYERS], Float:playerArmour[MAX_PLAYERS], killTime[MAX_PLAYERS],

	Text3D:playerDeathLabel[MAX_PLAYERS],

	lastSuspect[MAX_PLAYERS], playerConnectName[MAX_PLAYER_NAME][MAX_PLAYERS]
;



// Job vehicles
new 
	jobVehicle[MAX_PLAYERS] = 0;

// Global variables
new
	para,
	para2,
	strPara[128],
	gMsg[128],
	jailStr[80],
	largeStr[256],
	szMsg[512]
;

new Float:randomDSPositions[13][4] = {
{2161.2761,-1197.2484,23.6200,91.1219}, // p1
{2161.3508,-1187.7800,23.5463,90.2877}, // p2
{2160.8994,-1177.9072,23.5456,90.0102}, // p3
{2160.8923,-1168.2021,23.5453,89.6369}, // p4
{2161.1440,-1158.1156,23.5658,90.1162}, // p5
{2161.5559,-1148.3022,24.1073,91.7817}, // p6
{2148.9875,-1138.7295,25.1938,270.8910}, // p7
{2149.1304,-1148.0770,24.1661,271.3997}, // p8
{2148.6567,-1157.2400,23.5730,270.0395}, // p9
{2148.4426,-1166.1725,23.5474,267.2718}, // p10
{2148.5679,-1175.5269,23.5474,268.6926}, // p11
{2148.5898,-1184.7809,23.5474,268.7801}, // p12
{2148.3611,-1194.3053,23.5592,270.6785} //
};

// ---------- Textdraw-uri
new  
	Text:ClockTime, Text:ClockDate,
	PlayerText:Logo[MAX_PLAYERS][4],
	PlayerText:warTD[MAX_PLAYERS][6],
	PlayerText:moneyTD[MAX_PLAYERS],
	PlayerText:healthTD[MAX_PLAYERS],
	PlayerText:examTD[MAX_PLAYERS], PlayerText:drivingTD[MAX_PLAYERS][3], PlayerText:dsTextdraw[MAX_PLAYERS][16], PlayerText:speedTD[MAX_PLAYERS][7]
;

// Iterators
new 
	Iterator:Admins<MAX_PLAYERS>,
	Iterator:Wars<MAX_TURFS>,
	Iterator:dealerVehicles<200>,
	Iterator:personalCars<MAX_VEHICLES>,
	Iterator:gpsIter<100>,
	Iterator:contracts<100>,
	Iterator:jailPlayers<100> // de marit cand e un numar mai mare de jucatori pe server
;

new playerJailTime[MAX_PLAYERS], playerJailType[MAX_PLAYERS]; // type: 1 - police, 2 - admin jail

// Actors

new
	PoliceActor,
	Actor1, Actor2, Actor3
;

enum hitmanContracts {
	targetID, targetSum, checkBy, lastUpdated[80]
}
new contractInfo[20][hitmanContracts];
new playerTarget[MAX_PLAYERS], playerCover[MAX_PLAYERS];

enum svrLocations {
	gpsID,
	gpsName[50], gpsAddedBy[MAX_PLAYER_NAME], gpsCity[20],
	Float:gpsX, Float:gpsY, Float:gpsZ
};
new gpsInfo[100][svrLocations], gpsSelected[MAX_PLAYERS][100];

enum playerInfo {
	pSQLID, pName[MAX_PLAYER_NAME + 1], pPassword[130], pSerialCode[41],
	pSkin,
	pLevel, pEPoints, pAdmin, pHelper,
	pAge, pSex, pEmail[100],
	pMoney, pBank, pWarns, pDrugs, pMaterials, pWanted, pWantedReason[256],
	pCarLic, pGunLic, pBoatLic, pFlyLic, 
	pMember, pRank, pGJoinDate, pFWarns, pFPunish, pWarDeaths, pWarKills, pDuty, pLastDuty,
	pJob, pMatsSkill, pMaxSlots, pLoyalityPoints, pLoyalityAccount, pPhoneNumber,

	// Hud
	pHudHealth
};
new pInfo[MAX_PLAYERS][playerInfo];
new pConfirm[MAX_PLAYERS];


enum dealerInfo {
	dID, dModel, dPrice, dPremiumPrice, dStock, dType
}
new dInfo[200][dealerInfo], dsCar[MAX_PLAYERS], dsLastCam[MAX_PLAYERS], dsLastID[MAX_PLAYERS];

enum personalcInfo {
	pcID, pcOwner, pcModel, pcColor1, pcColor2, pcLockStatus, pcCarPlate[10], pcSpawned, pcTimeToSpawn, pcAge, pcOdometer, pcInsurance, pcMod[17],
	Float:pcPosX, Float:pcPosY, Float:pcPosZ, Float:pcPosA, pcFuel
}
new pcInfo[MAX_VEHICLES][personalcInfo], pcSelected[MAX_PLAYERS][50], pcSelID[MAX_PLAYERS], vehID[MAX_VEHICLES], Float:playerKm[MAX_PLAYERS];

enum groupInfo {
	gID, gName[50], gMotto[128],
	
	Float:geX, Float:geY, Float:geZ,
	
	Float:giX, Float:giY, Float:giZ,
	
	Float:gSafeX, Float:gSafeY, Float:gSafeZ,
	
	gRankname1[20], gRankname2[20], gRankname3[20], gRankname4[20], gRankname5[20], gRankname6[20], gRankname7[20],
	
	gMaterials, gDrugs, gMoney, gType, gInterior, gDoor, gLeadskin, gApplications, gSlots, gWar, gScore,
	
	gPickup, Text3D:gLabel, gSafePickup, Text3D:gSafeLabel
};
new gInfo[MAX_GROUPS][groupInfo];

enum jobInfo {
	jID, jName[50], jStatus, jType,
	
	Float:jX, Float:jY, Float:jZ,
	
	jPickup, Text3D:jLabel
};
new jInfo[MAX_JOBS][jobInfo];

// Arms dealer
new 
	armsObject[MAX_PLAYERS][3]
;


enum turfInfo
{
	tID, tOwner,
	Float:tMinX,Float:tMinY,Float:tMaxX,Float:tMaxY,
};
new tInfo[MAX_TURFS][turfInfo];
new Turfs[MAX_TURFS];

enum warInfo
{
	wDeffender, wAttacker, wTime, wABestScore, wABestPlayer[MAX_PLAYER_NAME + 1], wAWorstScore, wAWorstPlayer[MAX_PLAYER_NAME + 1],
	wDBestScore, wDBestPlayer[MAX_PLAYER_NAME + 1], wDWorstScore, wDWorstPlayer[MAX_PLAYER_NAME + 1]
}
new wInfo[49][warInfo];

enum vehInfo {
	vID,
	vModel,
	vGroup,
	vColor1,
	vColor2,
	vCarPlate[11], vObject, vObject2,
	Float:vX,
	Float:vY,
	Float:vZ,
	Float:vA
};
new vInfo[MAX_VEHICLES][vehInfo], svrVeh[MAX_VEHICLES];


new dialogPlayer[MAX_PLAYERS][50];


main() {
	print("\n----------------------------------");
	print(" Eureka RPG Gamemode by L0K3D ");
	print("----------------------------------\n");
	print("----------------------------------\n");
}

task OneSecond[1000]() {
    new hour, minutes, seconds, day, month, year, mstr[20];
	gettime(hour, minutes, seconds), getdate(year, month, day);
	format(gMsg, 128,"%02d:%02d", hour, minutes), TextDrawSetString(ClockTime, gMsg);
	switch(month) { case 1: mstr="january"; case 2: mstr="february"; case 3: mstr="march"; case 4: mstr="april"; case 5: mstr="may"; case 6: mstr="june"; case 7: mstr="iuly"; case 8: mstr="august";  case 9: mstr="september";  case 10: mstr="octomber"; case 11: mstr="november"; case 12: mstr="december"; }
	format(gMsg, 128,"%02d %s %02d", day, mstr, year), TextDrawSetString(ClockDate, gMsg);

	if(minutes == 45 && seconds == 0) {
		new ads[124];
		format(ads, 124, "** Free announcements starts at %02d:50, be ready!", hour);
		sendgType(COLOR_DCHAT, 7, ads);
	}

	foreach(new c : personalCars) {
		if(pcInfo[c][pcSpawned] > 0) {
			for(new v; v < MAX_VEHICLES; v++) {
				if(c == vehID[v]) {
					if(!IsVehicleOccupied(v)) {
						pcInfo[c][pcTimeToSpawn] --; 
					}
					break;
				}
			}
		}
		if(pcInfo[c][pcTimeToSpawn] > 0 && pcInfo[c][pcTimeToSpawn] < 2) { 
			pcInfo[c][pcSpawned] = 0;
			pcInfo[c][pcTimeToSpawn] = 0;
			SCMEx(personalPlayerid(c), -1, ""ORANGE"(!) "LORANGE"Your %s was been despawned because it wasn`t used for 15 minutes.", vehName[pcInfo[c][pcModel] - 400]);
			for(new v; v < MAX_VEHICLES; v++) {
				if(c == vehID[v]) {
					vehID[v] = 0;
					DestroyVehicle(v);
					break;
				}
			}
		}
	}

	foreach(new i : Wars) {
	    new attackersOnTurf, att = wInfo[i][wAttacker], deff = wInfo[i][wDeffender];
	    if(wInfo[i][wTime] > 1) {
	        wInfo[i][wTime] -= 1;
            foreach(new x : Player) {
            	if(pInfo[x][pMember] == att && getPlayerTurf(x) == i && playerLive[x] > 0) { attackersOnTurf ++; }

		 		if(gInfo[pInfo[x][pMember]][gWar] == i)
			    {
					format(gMsg, 50, "%d", gInfo[wInfo[i][wAttacker]][gScore]), PlayerTextDrawSetString(x, warTD[x][2], gMsg);
					format(gMsg, 50, "%d", gInfo[wInfo[i][wDeffender]][gScore]), PlayerTextDrawSetString(x, warTD[x][3], gMsg);
					format(gMsg, 50, "turf timer: ~y~%s", timeFormat(wInfo[i][wTime])), PlayerTextDrawSetString(x, warTD[x][4], gMsg);
				    format(gMsg, 50, "attackers on turf: ~b~%d",  attackersOnTurf), PlayerTextDrawSetString(x, warTD[x][5], gMsg);
			    }
			}

			if(attackersOnTurf == 0) {
				foreach(new z : Player)
				{
					foreach(new y : Player) {
						if(gInfo[pInfo[y][pMember]][gWar] == i) { OnPlayerStreamOut(z, y); }
					}

					if(gInfo[pInfo[z][pMember]][gWar] == i) {	
						for(new td; td < 6; td++) { PlayerTextDrawHide(z, warTD[z][td]); }
						ZoneStopFlashForPlayer(z, i-1);
						SCM(z, COLOR_WAR, "-------------------------- [ The end of the war ] --------------------------");
						SCMEx(z, COLOR_WAR, "Final score: %d - %s and %s - %d", gInfo[att][gScore], gInfo[att][gName], gInfo[deff][gName], gInfo[deff][gScore]);
						SCMEx(z, COLOR_WAR, "The best scores: %s (%d)", wInfo[i][wABestPlayer], wInfo[i][wABestScore]);
						SCMEx(z, COLOR_WAR, "The worst scores: %s (%d)", wInfo[i][wAWorstPlayer], wInfo[i][wAWorstScore]);
						SCMEx(z, COLOR_WAR, "My personal score is %d, with %d kills and %d deaths.", pInfo[z][pWarKills], pInfo[z][pWarDeaths]);
						SCM(z, COLOR_WAR, "--------------------------------------------------------------------------------------------------------");
						SCMEx(z, COLOR_WAR, "[WAR] %s failed to win turf #%d because they left the turf.", gInfo[att][gName], i);
					}
				}
				gInfo[deff][gScore] = gInfo[att][gScore] = gInfo[deff][gWar] = gInfo[att][gWar] = wInfo[i][wAttacker] = wInfo[i][wDeffender] = wInfo[i][wTime] = 0;
				Iter_SafeRemove(Wars, i, i);
			}
		}
		else 
       	{
			foreach(new z : Player)
			{
				foreach(new y : Player) {
					if(gInfo[pInfo[y][pMember]][gWar] == i) { OnPlayerStreamOut(z, y); }
				}

				if(gInfo[pInfo[z][pMember]][gWar] == i) {	
					for(new td; td < 6; td++) { PlayerTextDrawHide(z, warTD[z][td]); }
					ZoneStopFlashForPlayer(z, i-1);
					SCM(z, COLOR_WAR, "-------------------------- [ The end of the war ] --------------------------");
					SCMEx(z, COLOR_WAR, "Final score: %d - %s and %s - %d", gInfo[att][gScore], gInfo[att][gName], gInfo[deff][gName], gInfo[deff][gScore]);
					SCMEx(z, COLOR_WAR, "The best scores: %s (%d)", wInfo[i][wABestPlayer], wInfo[i][wABestScore]);
					SCMEx(z, COLOR_WAR, "The worst scores: %s (%d)", wInfo[i][wAWorstPlayer], wInfo[i][wAWorstScore]);
					SCMEx(z, COLOR_WAR, "My personal score is %d, with %d kills and %d deaths.", pInfo[z][pWarKills], pInfo[z][pWarDeaths]);
					SCM(z, COLOR_WAR, "--------------------------------------------------------------------------------------------------------");
				}
			}

			if(gInfo[att][gScore] >= gInfo[deff][gScore]) {
				format(gMsg, 128, "AdmBot: %s won one of %s`s turfs. Final score: %dk - %dk", gInfo[att][gName], gInfo[deff][gName], gInfo[att][gScore], gInfo[deff][gScore]);
				SendClientMessageToAll(COLOR_NEWS, gMsg);
				tInfo[i][tOwner] = att;

				foreach(new x : Player) {
					if(PlayerZonesStatus[x]) {
						HideZoneForPlayer(x, Turfs[i]);
						ShowZoneForPlayer(x, Turfs[i], getZoneColor(i), 0x000000FF, 0x000000AF);
					}
				}
			} 
			else {
				foreach(new y : Player) {
					if(gInfo[pInfo[y][pMember]][gWar] == i) { SCMEx(y, COLOR_WAR, "[WAR] %s failed to win turf #%d because they had lower points that deffenders.", gInfo[att][gName], i); }
				}
			}

			gInfo[deff][gScore] = gInfo[att][gScore] = gInfo[deff][gWar] = gInfo[att][gWar] = wInfo[i][wAttacker] = wInfo[i][wDeffender] = wInfo[i][wTime] = 0;
			Iter_SafeRemove(Wars, i, i);
		}
	}

	foreach(new x : Player) {
		if(pLogged[x]) {
			if(GetPlayerState(x) == PLAYER_STATE_DRIVER || GetPlayerState(x) == PLAYER_STATE_PASSENGER) {
		    	new Speed = GetSpeed(x), vehicleid = GetPlayerVehicleID(x), km[30];

				playerKm[x] += (Speed*0.27)/1000;
				
				if(playerKm[x] > 1) {
					pcInfo[vehID[vehicleid]][pcOdometer] += 1, playerKm[x] = 0;
				}

				if(vehID[vehicleid] > 0)  {
					format(km, 30, "~w~Odometer: ~y~%d km", pcInfo[vehID[vehicleid]][pcOdometer]), PlayerTextDrawSetString(x, speedTD[x][5], km);
				}

				format(km, 30, "~w~Speed: ~y~%d km/h", Speed), PlayerTextDrawSetString(x, speedTD[x][1], km); 
				format(km, 30, "~w~Fuel: ~b~~h~~h~%d litres", 99), PlayerTextDrawSetString(x, speedTD[x][6], km); 


				if(DMVTest[x] == 1 && DMVCP[x] != 0)
				{
					if(PenaltyPoints[x] <= 25) {
						if(Speed > 100 && (GetTickCount() - DMVLastSpeed[x]) > 4000) {
							DMVLastSpeed[x] = GetTickCount();
							PenaltyPoints[x] += 3;
							showPlayerDMVTD(x);
						}
					}
					else {
						PlayerTextDrawHide(x, examTD[x]);
						DestroyVehicle(DMVVehicle[x]), DestroyObject(DMVObject[x]);
						PenaltyPoints[x] = DMVTest[x] = DMVCP[x] = 0, DMVVehicle[x] = -1;
						SCM(x, COLOR_GREEN, "Instructor: {C2C3C4}You failed the driving test because you`ve accumulated 25 penalty points.");
						DisablePlayerRaceCheckpoint(x);
					}
				}

			}
			new Float:health, Float:armour;
			GetPlayerHealth(x, health), GetPlayerArmour(x, armour);

			if(GetPlayerState(x) == PLAYER_STATE_DRIVER && GetPlayerWeapon(x) != 0) {
				SetPlayerArmedWeapon(x, 0);
			}

			if(flyingStatus[x] == false && playerLive[x] == 1) {
				if(lastPlayerHP[x] != health) {
					OnPlayerHealthModify(x, lastPlayerHP[x], playerHP[x]);
				}
			}

			if(pInfo[x][pHudHealth]) {
				if(flyingStatus[x] == false) { format(gMsg, 30, "%0.0f", health), PlayerTextDrawSetString(x, healthTD[x], gMsg); } 
				else { PlayerTextDrawSetString(x, healthTD[x], "fly mode"); }
				 
			}

			ResetPlayerMoney(x), GivePlayerMoney(x, pInfo[x][pMoney]);
		}
	}
}

task JailTimer[1000]() { 
	foreach(new x : jailPlayers) {
		if(--playerJailTime[x] > 1) {
			format(jailStr, 80, "~n~~r~Jailed~n~~w~You`ll be free in %s minutes", timeFormat(playerJailTime[x]));
			PlayerTextDrawSetString(x, examTD[x], jailStr);
		}
		else {
			SCM(x, -1, "You have been released from jail, try to be a better player!");
			SetPlayerPos(x, 264.0331,90.8764,1001.0391), SetPlayerFacingAngle(x, 86.8763), PlayerTextDrawHide(x, examTD[x]);
			playerJailTime[x] = playerJailType[x] = 0;
			Iter_SafeRemove(jailPlayers, x, x);
		}
	}
}

task FiveMinutes[1000 * (60 * 5)]() {
	new time = time = GetTickCount();
	for(new v; v < MAX_VEHICLES; v++) { if(vInfo[v][vID] > 0 ) { saveVeh(v); } }
	foreach(new x :  personalCars) { savePersonals(x); }
	for(new i; i < MAX_GROUPS; i++) { saveGroup(i); }
	for(new i; i < MAX_JOBS; i++) { saveJob(i); }
	foreach(new p : Player) {
		saveAccount(p);

		if(pInfo[p][pAdmin] > 0 && !IsPlayerPaused(p)) { SCMEx(p, COLOR_RED, "AdmData: "GREY"All server data saved, finished in %d milliseconds.", GetTickCount() - time); }
	}
}

timer kickTimer[500](playerid) {
    Kick(playerid);
}

timer securityKick[1000 * 120](playerid) {
    if(enteredCode[playerid] == 0) { Kick(playerid); }
}

timer lspdgateclose[9000]() {
    MoveDynamicObject(gatelspd, 1588.6552, -1637.9025, 15.0358, 1.5);
}


timer lspdbarclose[9000]()
{
    MoveDynamicObject(lspdbar, 1544.7007, -1630.7527, 13.2983, 1.5, 0.0000, 90.0200, 90.0000);
}

timer startExam[13000](playerid) {
	DMVTest[playerid] = 1, DMVCP[playerid] = 0;
	TogglePlayerSpectating(playerid, 0);
	SetPlayerRaceCheckpoint(playerid, 0, 1213.5448,-1849.8387,13.3828, 1181.7075,-1797.5635,13.3984,5.0);
	PlayerTextDrawHide(playerid, drivingTD[playerid][0]), PlayerTextDrawHide(playerid, drivingTD[playerid][1]), PlayerTextDrawHide(playerid, drivingTD[playerid][2]);
	showPlayerDMVTD(playerid);
}

/*new Float:turfsCoordonates[23][4] = {
	{1053.048828125, -2170.218994140625, 1240.048828125, -1985.218994140625},
	{1240.038330078125, -2089.2085876464844, 1586.038330078125, -1985.2085876464844},
	{1053.038330078125, -1985.2085876464844, 1331.038330078125, -1859.2085876464844},
	{1052.038330078125, -1711.2016296386719, 1320.038330078125, -1580.2016296386719},
	{816.048828125, -1859.1911926269531, 1163.048828125, -1711.1911926269531},
	{1163.0418090820312, -1858.1911926269531, 1563.0418090820312, -1711.1911926269531},
	{1320.0244140625, -1711.1911010742188, 1745.0244140625, -1580.1911010742188},
	{815.038330078125, -1711.1911010742188, 1052.038330078125, -1473.1911010742188},
	{1052.0278930664062, -1579.663330078125, 1227.0278930664062, -1242.663330078125},
	{815.0278930664062, -1473.17724609375, 1052.0278930664062, -1173.17724609375},
	{1052.0140380859375, -1242.6564331054688, 1366.0140380859375, -1132.6564331054688},
	{1227.0140380859375, -1452.6563415527344, 1450.0140380859375, -1242.6563415527344},
	{1227.0140380859375, -1579.6564025878906, 1490.0140380859375, -1452.6564025878906},
	{1366.0140380859375, -1243.55224609375, 1710.0140380859375, -1107.55224609375},
	{1450.0140380859375, -1452.6564025878906, 1839.0140380859375, -1242.6564025878906},
	{490.0140380859375, -1579.6564331054688, 1839.0140380859375, -1452.6564331054688},
	{331.038330078125, -1985.2014770507812, 1738.038330078125, -1859.2014770507812},
	{1563.038330078125, -1858.1807250976562, 1944.038330078125, -1711.1807250976562},
	{710.0072021484375, -1243.55224609375, 2069.0072021484375, -1136.55224609375},
	{1745.0234375, -1711.1796875, 2096.0234375, -1580.1796875},
	{1839.0078125, -1579.65625, 2137.0078125, -1243.65625},
	{1944.0234375, -1858.171875, 2406.0234375, -1711.171875},
	{2096.015625, -1712.1796875, 2459.015625, -1580.1796875}
};*/

public OnGameModeInit() {

	handle = mysql_connect("127.0.0.1", "root", "eureka", "");
	
	
	if(handle && mysql_errno(handle) == 0) { 
		print("[MYSQL] Succesfuly connected!");

		mysql_tquery(handle, "SELECT * FROM `groups`", "loadGroups", "");
		mysql_tquery(handle, "SELECT * FROM `jobs`", "loadJobs", "");
		mysql_tquery(handle, "SELECT * FROM `cars`", "loadCars", "");
		mysql_tquery(handle, "SELECT * FROM `turfs`", "loadTurfs", "");
		mysql_tquery(handle, "SELECT * FROM `gps`", "iniGPS", "");
		mysql_tquery(handle, "SELECT * FROM `dealervehicles` ORDER BY `dealerPrice` ASC", "IniDealer", "");
		
		SetGameModeText("eureka v0.2");
		ShowPlayerMarkers(PLAYER_MARKERS_MODE_STREAMED);
		EnableStuntBonusForAll(0);
	    UsePlayerPedAnims();
		DisableInteriorEnterExits();
	}
	else print("[MYSQL] Connection not found."), SendRconCommand("hostname (V) Connecting to database..."), SendRconCommand("password mysqlProblemeureka"), SetGameModeText("unavailable");
	
	SendRconCommand("language English");

	ClockTime = TextDrawCreate(577.599548, 24.653348, "23:45");
	TextDrawLetterSize(ClockTime, 0.449999, 1.600000);
	TextDrawAlignment(ClockTime, 2);
	TextDrawColor(ClockTime, -1);
	TextDrawSetShadow(ClockTime, 0);
	TextDrawSetOutline(ClockTime, 1);
	TextDrawBackgroundColor(ClockTime, 51);
	TextDrawFont(ClockTime, 3);
	TextDrawSetProportional(ClockTime, 1);

	ClockDate = TextDrawCreate(579.200256, 10.466676, "23 octombrie 2017");
	TextDrawLetterSize(ClockDate, 0.177200, 1.712000);
	TextDrawAlignment(ClockDate, 2);
	TextDrawColor(ClockDate, -1);
	TextDrawSetShadow(ClockDate, 0);
	TextDrawSetOutline(ClockDate, 1);
	TextDrawBackgroundColor(ClockDate, 51);
	TextDrawFont(ClockDate, 2);
	TextDrawSetProportional(ClockDate, 1);
	
	LoadDrugsMap();
	LoadAdminMap();
	LoadJailMap();
	LoadGangsHQDoors();
	LoadIslandMap();
	LoadBallasMap();
	LoadReportersHQ();

	CreateDynamicPickup(1318, 1, 2166.4668, -1671.5120, 15.0740, -1, -1, -1, 20.0); // getdrugs out
	CreateDynamicPickup(1279, 1, 316.8903, 1118.0417, 1083.8828, -1, 5, -1, 20.0); // getdrugs  in

	CreateDynamicPickup(1239, 1, 1219.2314, -1811.8459, 16.5938, -1, -1, -1, 20.0); // dmv exam place
	CreateDynamic3DTextLabel("Type {FF6347}/exam{FFFF00} to take\nyour driving license", COLOR_YELLOW, 1219.2314, -1811.8459, 16.5938, 100, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, -1, -1, -1, 20.0);

	CreateDynamicPickup(1277, 1, 2131.6790,-1150.6421,24.1334, -1, -1, -1, 20.0); // Dealership
	CreateDynamic3DTextLabel("Dealership\n Type /buycar for buy a vehicle or /sellcar for sell a car", 0xFFFF00AA, 2131.6790,-1150.6421,24.1334, 100, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, -1, -1, -1, 20.0);

	PoliceActor = CreateActor(303, 1543.8268,-1631.8849,13.3828,90.3145);
	SetActorInvulnerable(PoliceActor, true);

	// spawn civil actors
	Actor1 = CreateActor(0, -516.6025,-191.9402,78.3008, 71.2866), SetActorInvulnerable(Actor1, true);
	ApplyActorAnimation(Actor1, "PED","IDLE_CHAT", 4.1, 1, 0, 0, 0, 0);
	Actor2 = CreateActor(269, -518.2606,-192.9499,78.3454,358.2244), SetActorInvulnerable(Actor2, true);
	ApplyActorAnimation(Actor2, "PED","IDLE_CHAT", 4.1, 1, 0, 0, 0, 0);
	Actor3 = CreateActor(271, -519.8423,-191.2442,78.2659,255.9513), SetActorInvulnerable(Actor3, true);
	ApplyActorAnimation(Actor3, "PED","IDLE_CHAT", 4.1, 1, 0, 0, 0, 0);

	
	// Commands
	Command_AddAltNamed("vehicles", "cars"), Command_AddAltNamed("vehicles", "cars"), Command_AddAltNamed("vehicles", "v");
	return 1;
}


public OnGameModeExit() {
	for(new v; v < MAX_VEHICLES; v++) { if(vInfo[v][vID] > 0 ) { saveVeh(v); } }
	
	for(new i; i < MAX_GROUPS; i++) { saveGroup(i); }

	foreach(new x :  personalCars) { savePersonals(x); }

	for(new i; i < MAX_JOBS; i++) { saveJob(i); }
	
	foreach(new p : Player) {
		saveAccount(p);
	}
	
	mysql_close(handle);
	return 1;
}

public OnPlayerRequestClass(playerid, classid) {
	return 1;
}

public OnPlayerRequestSpawn(playerid) {
	return 1;
}

public OnIncomingConnection(playerid, ip_address[], port) {
	return 1;
}

public OnPlayerShootDynamicObject(playerid, weaponid, objectid, Float:x, Float:y, Float:z) {
	return 1;
}

public OnPlayerConnect(playerid) {

	// Remove buldings
	RemoveBuildingForPlayer(playerid, 14843, 266.3516, 81.1953, 1001.2813, 0.25);

	RemoveBuildingForPlayer(playerid, 14517, 2221.8750, -1148.0938, 1026.1484, 0.25); // Gangs HQ

	RemoveBuildingForPlayer(playerid, 627, -2569.0781, 323.3125, 11.3594, 0.25);
	RemoveBuildingForPlayer(playerid, 627, -2567.4219, 323.7031, 11.3594, 0.25);
	RemoveBuildingForPlayer(playerid, 1480, -2570.2109, 331.2734, 10.6953, 0.25);
	RemoveBuildingForPlayer(playerid, 627, -2567.8594, 331.3125, 11.3594, 0.25);
	RemoveBuildingForPlayer(playerid, 741, -2556.7656, 304.8047, 15.2500, 0.25);
	RemoveBuildingForPlayer(playerid, 741, -2557.8047, 304.7344, 15.2500, 0.25);
	RemoveBuildingForPlayer(playerid, 741, -2554.9922, 304.8984, 15.2500, 0.25);
	RemoveBuildingForPlayer(playerid, 741, -2555.0859, 305.8984, 15.2500, 0.25);
	RemoveBuildingForPlayer(playerid, 741, -2555.0781, 307.0469, 15.2500, 0.25);
	RemoveBuildingForPlayer(playerid, 741, -2555.9141, 304.8672, 15.2500, 0.25);
	RemoveBuildingForPlayer(playerid, 1479, -2563.6016, 327.3750, 10.9375, 0.25);
	RemoveBuildingForPlayer(playerid, 1458, -2560.3750, 323.2031, 15.1719, 0.25);
	RemoveBuildingForPlayer(playerid, 741, -2554.9531, 308.0313, 15.2500, 0.25);

	// ballas hq
	RemoveBuildingForPlayer(playerid, 739, 1986.8516, -1101.1484, 24.2109, 0.25);
	RemoveBuildingForPlayer(playerid, 5671, 1996.3984, -1110.7891, 30.2656, 0.25);
	RemoveBuildingForPlayer(playerid, 673, 1982.6250, -1121.3281, 23.9297, 0.25);
	RemoveBuildingForPlayer(playerid, 645, 1996.2031, -1123.5859, 24.2109, 0.25);
	RemoveBuildingForPlayer(playerid, 5520, 1996.3984, -1110.7891, 30.2656, 0.25);
	RemoveBuildingForPlayer(playerid, 673, 2010.0625, -1104.2109, 23.0938, 0.25);
	
	EnablePlayerCameraTarget(playerid, true);

	GetPlayerName(playerid, playerConnectName[playerid], MAX_PLAYER_NAME);

	SetPlayerHealth(playerid, 99.0);
	new query[128], serial[41];
	gpci(playerid, serial, 41);
	mysql_format(handle, query, 128, "SELECT `bannedBy`, `reason` FROM `bans` WHERE `SerialCode` = '%e'", serial), mysql_tquery(handle, query, "accountCheckBan", "i", playerid);


	SetSpawnInfo(playerid, 0, pInfo[playerid][pSkin], 0.0,0.0,0.0,0,0,0,0,0,0,0);
	TogglePlayerSpectating(playerid, 0);

	// resetare var
	playerTarget[playerid] = DMVVehicle[playerid] = -1;
	PenaltyPoints[playerid] = DMVTest[playerid] = DMVCP[playerid] = playerJailTime[playerid] = playerJailType[playerid] = PlayerZonesStatus[playerid] = 0;
	
	

	speedTD[playerid][0] = CreatePlayerTextDraw(playerid, 525.199951, 303.454681, "box");
	PlayerTextDrawLetterSize(playerid, speedTD[playerid][0], 0.000000, 0.879998);
	PlayerTextDrawTextSize(playerid, speedTD[playerid][0], 629.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, speedTD[playerid][0], 1);
	PlayerTextDrawColor(playerid, speedTD[playerid][0], -1);
	PlayerTextDrawUseBox(playerid, speedTD[playerid][0], 1);
	PlayerTextDrawBoxColor(playerid, speedTD[playerid][0], 90);
	PlayerTextDrawSetShadow(playerid, speedTD[playerid][0], 0);
	PlayerTextDrawSetOutline(playerid, speedTD[playerid][0], 0);
	PlayerTextDrawBackgroundColor(playerid, speedTD[playerid][0], 255);
	PlayerTextDrawFont(playerid, speedTD[playerid][0], 1);
	PlayerTextDrawSetProportional(playerid, speedTD[playerid][0], 1);
	PlayerTextDrawSetShadow(playerid, speedTD[playerid][0], 0);

	speedTD[playerid][1] = CreatePlayerTextDraw(playerid, 525.464355, 303.488098, "~w~Speed: ~y~loading..");
	PlayerTextDrawLetterSize(playerid, speedTD[playerid][1], 0.166258, 0.818799);
	PlayerTextDrawAlignment(playerid, speedTD[playerid][1], 1);
	PlayerTextDrawColor(playerid, speedTD[playerid][1], -1);
	PlayerTextDrawSetShadow(playerid, speedTD[playerid][1], 0);
	PlayerTextDrawSetOutline(playerid, speedTD[playerid][1], 1);
	PlayerTextDrawBackgroundColor(playerid, speedTD[playerid][1], 90);
	PlayerTextDrawFont(playerid, speedTD[playerid][1], 2);
	PlayerTextDrawSetProportional(playerid, speedTD[playerid][1], 1);
	PlayerTextDrawSetShadow(playerid, speedTD[playerid][1], 0);

	speedTD[playerid][2] = CreatePlayerTextDraw(playerid, 525.199951, 316.455474, "box");
	PlayerTextDrawLetterSize(playerid, speedTD[playerid][2], 0.000000, 0.879998);
	PlayerTextDrawTextSize(playerid, speedTD[playerid][2], 629.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, speedTD[playerid][2], 1);
	PlayerTextDrawColor(playerid, speedTD[playerid][2], -1);
	PlayerTextDrawUseBox(playerid, speedTD[playerid][2], 1);
	PlayerTextDrawBoxColor(playerid, speedTD[playerid][2], 90);
	PlayerTextDrawSetShadow(playerid, speedTD[playerid][2], 0);
	PlayerTextDrawSetOutline(playerid, speedTD[playerid][2], 0);
	PlayerTextDrawBackgroundColor(playerid, speedTD[playerid][2], 255);
	PlayerTextDrawFont(playerid, speedTD[playerid][2], 1);
	PlayerTextDrawSetProportional(playerid, speedTD[playerid][2], 1);
	PlayerTextDrawSetShadow(playerid, speedTD[playerid][2], 0);

	speedTD[playerid][3] = CreatePlayerTextDraw(playerid, 577.377258, 329.639831, "loading..");
	PlayerTextDrawLetterSize(playerid, speedTD[playerid][3], 0.166258, 0.818799);
	PlayerTextDrawTextSize(playerid, speedTD[playerid][3], 0.000000, 103.499893);
	PlayerTextDrawAlignment(playerid, speedTD[playerid][3], 2);
	PlayerTextDrawColor(playerid, speedTD[playerid][3], -1);
	PlayerTextDrawUseBox(playerid, speedTD[playerid][3], 1);
	PlayerTextDrawBoxColor(playerid, speedTD[playerid][3], 0x009C392A);
	PlayerTextDrawSetShadow(playerid, speedTD[playerid][3], 1);
	PlayerTextDrawSetOutline(playerid, speedTD[playerid][3], 1);
	PlayerTextDrawBackgroundColor(playerid, speedTD[playerid][3], 90);
	PlayerTextDrawFont(playerid, speedTD[playerid][3], 2);
	PlayerTextDrawSetProportional(playerid, speedTD[playerid][3], 1);
	PlayerTextDrawSetShadow(playerid, speedTD[playerid][3], 1);

	speedTD[playerid][4] = CreatePlayerTextDraw(playerid, 525.199951, 290.753906, "box");
	PlayerTextDrawLetterSize(playerid, speedTD[playerid][4], 0.000000, 0.879998);
	PlayerTextDrawTextSize(playerid, speedTD[playerid][4], 629.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, speedTD[playerid][4], 1);
	PlayerTextDrawColor(playerid, speedTD[playerid][4], -1);
	PlayerTextDrawUseBox(playerid, speedTD[playerid][4], 1);
	PlayerTextDrawBoxColor(playerid, speedTD[playerid][4], 90);
	PlayerTextDrawSetShadow(playerid, speedTD[playerid][4], 0);
	PlayerTextDrawSetOutline(playerid, speedTD[playerid][4], 0);
	PlayerTextDrawBackgroundColor(playerid, speedTD[playerid][4], 255);
	PlayerTextDrawFont(playerid, speedTD[playerid][4], 1);
	PlayerTextDrawSetProportional(playerid, speedTD[playerid][4], 1);
	PlayerTextDrawSetShadow(playerid, speedTD[playerid][4], 0);

	speedTD[playerid][5] = CreatePlayerTextDraw(playerid, 525.464355, 290.487304, "~w~Odometer: ~y~loading..");
	PlayerTextDrawLetterSize(playerid, speedTD[playerid][5], 0.166258, 0.818799);
	PlayerTextDrawAlignment(playerid, speedTD[playerid][5], 1);
	PlayerTextDrawColor(playerid, speedTD[playerid][5], -1);
	PlayerTextDrawSetShadow(playerid, speedTD[playerid][5], 0);
	PlayerTextDrawSetOutline(playerid, speedTD[playerid][5], 1);
	PlayerTextDrawBackgroundColor(playerid, speedTD[playerid][5], 90);
	PlayerTextDrawFont(playerid, speedTD[playerid][5], 2);
	PlayerTextDrawSetProportional(playerid, speedTD[playerid][5], 1);
	PlayerTextDrawSetShadow(playerid, speedTD[playerid][5], 0);

	speedTD[playerid][6] = CreatePlayerTextDraw(playerid, 525.934936, 316.072174, "~w~Fuel: ~y~loading..");
	PlayerTextDrawLetterSize(playerid, speedTD[playerid][6], 0.166258, 0.818799);
	PlayerTextDrawAlignment(playerid, speedTD[playerid][6], 1);
	PlayerTextDrawColor(playerid, speedTD[playerid][6], -1);
	PlayerTextDrawSetShadow(playerid, speedTD[playerid][6], 0);
	PlayerTextDrawSetOutline(playerid, speedTD[playerid][6], 1);
	PlayerTextDrawBackgroundColor(playerid, speedTD[playerid][6], 90);
	PlayerTextDrawFont(playerid, speedTD[playerid][6], 2);
	PlayerTextDrawSetProportional(playerid, speedTD[playerid][6], 1);
	PlayerTextDrawSetShadow(playerid, speedTD[playerid][6], 0);


	dsTextdraw[playerid][0] = CreatePlayerTextDraw(playerid, 418.208129, 351.361694, "Next car");
	PlayerTextDrawLetterSize(playerid, dsTextdraw[playerid][0], 0.248797, 1.559998);
	PlayerTextDrawAlignment(playerid, dsTextdraw[playerid][0], 2);
	PlayerTextDrawColor(playerid, dsTextdraw[playerid][0], -1);
	PlayerTextDrawSetShadow(playerid, dsTextdraw[playerid][0], 0);
	PlayerTextDrawSetOutline(playerid, dsTextdraw[playerid][0], 1);
	PlayerTextDrawBackgroundColor(playerid, dsTextdraw[playerid][0], 255);
	PlayerTextDrawFont(playerid, dsTextdraw[playerid][0], 2);
	PlayerTextDrawSetProportional(playerid, dsTextdraw[playerid][0], 1);
	PlayerTextDrawSetShadow(playerid, dsTextdraw[playerid][0], 0);

	dsTextdraw[playerid][1] = CreatePlayerTextDraw(playerid, 182.000000, 351.437500, "Previous car");
	PlayerTextDrawLetterSize(playerid, dsTextdraw[playerid][1], 0.247997, 1.559998);
	PlayerTextDrawAlignment(playerid, dsTextdraw[playerid][1], 1);
	PlayerTextDrawColor(playerid, dsTextdraw[playerid][1], -1);
	PlayerTextDrawSetShadow(playerid, dsTextdraw[playerid][1], 0);
	PlayerTextDrawSetOutline(playerid, dsTextdraw[playerid][1], 1);
	PlayerTextDrawBackgroundColor(playerid, dsTextdraw[playerid][1], 255);
	PlayerTextDrawFont(playerid, dsTextdraw[playerid][1], 2);
	PlayerTextDrawSetProportional(playerid, dsTextdraw[playerid][1], 1);
	PlayerTextDrawSetShadow(playerid, dsTextdraw[playerid][1], 0);

	dsTextdraw[playerid][2] = CreatePlayerTextDraw(playerid, 200.199951, 369.093292, "ld_beat:left");
	PlayerTextDrawLetterSize(playerid, dsTextdraw[playerid][2], 0.000000, 0.000000);
	PlayerTextDrawTextSize(playerid, dsTextdraw[playerid][2], 29.000000, 24.000000);
	PlayerTextDrawAlignment(playerid, dsTextdraw[playerid][2], 1);
	PlayerTextDrawColor(playerid, dsTextdraw[playerid][2], -1);
	PlayerTextDrawSetShadow(playerid, dsTextdraw[playerid][2], 0);
	PlayerTextDrawSetOutline(playerid, dsTextdraw[playerid][2], 0);
	PlayerTextDrawBackgroundColor(playerid, dsTextdraw[playerid][2], 255);
	PlayerTextDrawFont(playerid, dsTextdraw[playerid][2], 4);
	PlayerTextDrawSetProportional(playerid, dsTextdraw[playerid][2], 0);
	PlayerTextDrawSetShadow(playerid, dsTextdraw[playerid][2], 0);
	PlayerTextDrawSetSelectable(playerid, dsTextdraw[playerid][2], true);

	dsTextdraw[playerid][3] = CreatePlayerTextDraw(playerid, 405.895446, 369.293212, "ld_beat:right");
	PlayerTextDrawLetterSize(playerid, dsTextdraw[playerid][3], 0.000000, 0.000000);
	PlayerTextDrawTextSize(playerid, dsTextdraw[playerid][3], 29.000000, 24.000000);
	PlayerTextDrawAlignment(playerid, dsTextdraw[playerid][3], 1);
	PlayerTextDrawColor(playerid, dsTextdraw[playerid][3], -1);
	PlayerTextDrawSetShadow(playerid, dsTextdraw[playerid][3], 0);
	PlayerTextDrawSetOutline(playerid, dsTextdraw[playerid][3], 0);
	PlayerTextDrawBackgroundColor(playerid, dsTextdraw[playerid][3], 255);
	PlayerTextDrawFont(playerid, dsTextdraw[playerid][3], 4);
	PlayerTextDrawSetProportional(playerid, dsTextdraw[playerid][3], 0);
	PlayerTextDrawSetShadow(playerid, dsTextdraw[playerid][3], 0);
	PlayerTextDrawSetSelectable(playerid, dsTextdraw[playerid][3], true);

	dsTextdraw[playerid][4] = CreatePlayerTextDraw(playerid, 284.200073, 270.733306, "");
	PlayerTextDrawLetterSize(playerid, dsTextdraw[playerid][4], 0.000000, 0.000000);
	PlayerTextDrawTextSize(playerid, dsTextdraw[playerid][4], 90.000000, 90.000000);
	PlayerTextDrawAlignment(playerid, dsTextdraw[playerid][4], 1);
	PlayerTextDrawColor(playerid, dsTextdraw[playerid][4], -1);
	PlayerTextDrawSetShadow(playerid, dsTextdraw[playerid][4], 0);
	PlayerTextDrawSetOutline(playerid, dsTextdraw[playerid][4], 0);
	PlayerTextDrawBackgroundColor(playerid, dsTextdraw[playerid][4], 0);
	PlayerTextDrawFont(playerid, dsTextdraw[playerid][4], 5);
	PlayerTextDrawSetProportional(playerid, dsTextdraw[playerid][4], 0);
	PlayerTextDrawSetShadow(playerid, dsTextdraw[playerid][4], 0);
	PlayerTextDrawSetPreviewModel(playerid, dsTextdraw[playerid][4], 367);
	PlayerTextDrawSetPreviewRot(playerid, dsTextdraw[playerid][4], 0.000000, 0.000000, 50.000000, 1.000000);

	dsTextdraw[playerid][5] = CreatePlayerTextDraw(playerid, 329.999816, 384.879913, "buy car");
	PlayerTextDrawLetterSize(playerid, dsTextdraw[playerid][5], 0.400000, 1.600000);
	PlayerTextDrawTextSize(playerid, dsTextdraw[playerid][5], 20.000000, 72.000000);
	PlayerTextDrawAlignment(playerid, dsTextdraw[playerid][5], 2);
	PlayerTextDrawColor(playerid, dsTextdraw[playerid][5], 8388863);
	PlayerTextDrawUseBox(playerid, dsTextdraw[playerid][5], 1);
	PlayerTextDrawBoxColor(playerid, dsTextdraw[playerid][5], 0);
	PlayerTextDrawSetShadow(playerid, dsTextdraw[playerid][5], 0);
	PlayerTextDrawSetOutline(playerid, dsTextdraw[playerid][5], 1);
	PlayerTextDrawBackgroundColor(playerid, dsTextdraw[playerid][5], 255);
	PlayerTextDrawFont(playerid, dsTextdraw[playerid][5], 3);
	PlayerTextDrawSetProportional(playerid, dsTextdraw[playerid][5], 1);
	PlayerTextDrawSetShadow(playerid, dsTextdraw[playerid][5], 0);
	PlayerTextDrawSetSelectable(playerid, dsTextdraw[playerid][5], true);

	dsTextdraw[playerid][6] = CreatePlayerTextDraw(playerid, 329.199951, 327.386566, "change camera");
	PlayerTextDrawLetterSize(playerid, dsTextdraw[playerid][6], 0.400000, 1.600000);
	PlayerTextDrawTextSize(playerid, dsTextdraw[playerid][6], 20.969998, 111.000000);
	PlayerTextDrawAlignment(playerid, dsTextdraw[playerid][6], 2);
	PlayerTextDrawColor(playerid, dsTextdraw[playerid][6], -1);
	PlayerTextDrawUseBox(playerid, dsTextdraw[playerid][6], 1);
	PlayerTextDrawBoxColor(playerid, dsTextdraw[playerid][6], 0);
	PlayerTextDrawSetShadow(playerid, dsTextdraw[playerid][6], 0);
	PlayerTextDrawSetOutline(playerid, dsTextdraw[playerid][6], 1);
	PlayerTextDrawBackgroundColor(playerid, dsTextdraw[playerid][6], 255);
	PlayerTextDrawFont(playerid, dsTextdraw[playerid][6], 3);
	PlayerTextDrawSetProportional(playerid, dsTextdraw[playerid][6], 1);
	PlayerTextDrawSetShadow(playerid, dsTextdraw[playerid][6], 0);
	PlayerTextDrawSetSelectable(playerid, dsTextdraw[playerid][6], true);
	
	dsTextdraw[playerid][7] = CreatePlayerTextDraw(playerid, 27.000030, 157.146560, "box");
	PlayerTextDrawLetterSize(playerid, dsTextdraw[playerid][7], 0.000000, 11.039998);
	PlayerTextDrawTextSize(playerid, dsTextdraw[playerid][7], 150.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, dsTextdraw[playerid][7], 1);
	PlayerTextDrawColor(playerid, dsTextdraw[playerid][7], -1);
	PlayerTextDrawUseBox(playerid, dsTextdraw[playerid][7], 1);
	PlayerTextDrawBoxColor(playerid, dsTextdraw[playerid][7], 165);
	PlayerTextDrawSetShadow(playerid, dsTextdraw[playerid][7], 0);
	PlayerTextDrawSetOutline(playerid, dsTextdraw[playerid][7], 0);
	PlayerTextDrawBackgroundColor(playerid, dsTextdraw[playerid][7], 255);
	PlayerTextDrawFont(playerid, dsTextdraw[playerid][7], 1);
	PlayerTextDrawSetProportional(playerid, dsTextdraw[playerid][7], 1);
	PlayerTextDrawSetShadow(playerid, dsTextdraw[playerid][7], 0);

	dsTextdraw[playerid][8] = CreatePlayerTextDraw(playerid, 27.000030, 157.146560, "box");
	PlayerTextDrawLetterSize(playerid, dsTextdraw[playerid][8], 0.000000, 11.039998);
	PlayerTextDrawTextSize(playerid, dsTextdraw[playerid][8], 150.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, dsTextdraw[playerid][8], 1);
	PlayerTextDrawColor(playerid, dsTextdraw[playerid][8], -1);
	PlayerTextDrawUseBox(playerid, dsTextdraw[playerid][8], 1);
	PlayerTextDrawBoxColor(playerid, dsTextdraw[playerid][8], 165);
	PlayerTextDrawSetShadow(playerid, dsTextdraw[playerid][8], 0);
	PlayerTextDrawSetOutline(playerid, dsTextdraw[playerid][8], 0);
	PlayerTextDrawBackgroundColor(playerid, dsTextdraw[playerid][8], 255);
	PlayerTextDrawFont(playerid, dsTextdraw[playerid][8], 1);
	PlayerTextDrawSetProportional(playerid, dsTextdraw[playerid][8], 1);
	PlayerTextDrawSetShadow(playerid, dsTextdraw[playerid][8], 0);

	dsTextdraw[playerid][9] = CreatePlayerTextDraw(playerid, 26.800041, 156.799972, "box");
	PlayerTextDrawLetterSize(playerid, dsTextdraw[playerid][9], 0.000000, 1.599999);
	PlayerTextDrawTextSize(playerid, dsTextdraw[playerid][9], 150.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, dsTextdraw[playerid][9], 1);
	PlayerTextDrawColor(playerid, dsTextdraw[playerid][9], -1);
	PlayerTextDrawUseBox(playerid, dsTextdraw[playerid][9], 1);
	PlayerTextDrawBoxColor(playerid, dsTextdraw[playerid][9], 831105791);
	PlayerTextDrawSetShadow(playerid, dsTextdraw[playerid][9], 0);
	PlayerTextDrawSetOutline(playerid, dsTextdraw[playerid][9], 0);
	PlayerTextDrawBackgroundColor(playerid, dsTextdraw[playerid][9], 255);
	PlayerTextDrawFont(playerid, dsTextdraw[playerid][9], 1);
	PlayerTextDrawSetProportional(playerid, dsTextdraw[playerid][9], 1);
	PlayerTextDrawSetShadow(playerid, dsTextdraw[playerid][9], 0);

	dsTextdraw[playerid][10] = CreatePlayerTextDraw(playerid, 57.533325, 155.321395, "Dealership");
	PlayerTextDrawLetterSize(playerid, dsTextdraw[playerid][10], 0.488800, 1.756801);
	PlayerTextDrawAlignment(playerid, dsTextdraw[playerid][10], 1);
	PlayerTextDrawColor(playerid, dsTextdraw[playerid][10], -1);
	PlayerTextDrawSetShadow(playerid, dsTextdraw[playerid][10], 1);
	PlayerTextDrawSetOutline(playerid, dsTextdraw[playerid][10], 0);
	PlayerTextDrawBackgroundColor(playerid, dsTextdraw[playerid][10], 255);
	PlayerTextDrawFont(playerid, dsTextdraw[playerid][10], 3);
	PlayerTextDrawSetProportional(playerid, dsTextdraw[playerid][10], 1);
	PlayerTextDrawSetShadow(playerid, dsTextdraw[playerid][10], 1);

	dsTextdraw[playerid][11] = CreatePlayerTextDraw(playerid, 31.399995, 154.253372, "hud:radar_truck");
	PlayerTextDrawLetterSize(playerid, dsTextdraw[playerid][11], 0.000000, 0.000000);
	PlayerTextDrawTextSize(playerid, dsTextdraw[playerid][11], 22.000000, 18.000000);
	PlayerTextDrawAlignment(playerid, dsTextdraw[playerid][11], 1);
	PlayerTextDrawColor(playerid, dsTextdraw[playerid][11], -1);
	PlayerTextDrawSetShadow(playerid, dsTextdraw[playerid][11], 0);
	PlayerTextDrawSetOutline(playerid, dsTextdraw[playerid][11], 0);
	PlayerTextDrawBackgroundColor(playerid, dsTextdraw[playerid][11], 255);
	PlayerTextDrawFont(playerid, dsTextdraw[playerid][11], 4);
	PlayerTextDrawSetProportional(playerid, dsTextdraw[playerid][11], 0);
	PlayerTextDrawSetShadow(playerid, dsTextdraw[playerid][11], 0);

	dsTextdraw[playerid][12] = CreatePlayerTextDraw(playerid, 92.400039, 175.813293, "~g~Infernus");
	PlayerTextDrawLetterSize(playerid, dsTextdraw[playerid][12], 0.224799, 1.152000);
	PlayerTextDrawAlignment(playerid, dsTextdraw[playerid][12], 2);
	PlayerTextDrawColor(playerid, dsTextdraw[playerid][12], -1);
	PlayerTextDrawSetShadow(playerid, dsTextdraw[playerid][12], 0);
	PlayerTextDrawSetOutline(playerid, dsTextdraw[playerid][12], 0);
	PlayerTextDrawBackgroundColor(playerid, dsTextdraw[playerid][12], 255);
	PlayerTextDrawFont(playerid, dsTextdraw[playerid][12], 2);
	PlayerTextDrawSetProportional(playerid, dsTextdraw[playerid][12], 1);
	PlayerTextDrawSetShadow(playerid, dsTextdraw[playerid][12], 0);

	dsTextdraw[playerid][13] = CreatePlayerTextDraw(playerid, 95.600044, 187.759979, "~y~Price: ~w~45,000,000$");
	PlayerTextDrawLetterSize(playerid, dsTextdraw[playerid][13], 0.224799, 1.152000);
	PlayerTextDrawAlignment(playerid, dsTextdraw[playerid][13], 2);
	PlayerTextDrawColor(playerid, dsTextdraw[playerid][13], -1);
	PlayerTextDrawSetShadow(playerid, dsTextdraw[playerid][13], 0);
	PlayerTextDrawSetOutline(playerid, dsTextdraw[playerid][13], 0);
	PlayerTextDrawBackgroundColor(playerid, dsTextdraw[playerid][13], 255);
	PlayerTextDrawFont(playerid, dsTextdraw[playerid][13], 2);
	PlayerTextDrawSetProportional(playerid, dsTextdraw[playerid][13], 1);
	PlayerTextDrawSetShadow(playerid, dsTextdraw[playerid][13], 0);

	dsTextdraw[playerid][14] = CreatePlayerTextDraw(playerid, 95.600036, 201.199996, "~y~Stock: ~w~10 vehicles");
	PlayerTextDrawLetterSize(playerid, dsTextdraw[playerid][14], 0.224799, 1.152000);
	PlayerTextDrawAlignment(playerid, dsTextdraw[playerid][14], 2);
	PlayerTextDrawColor(playerid, dsTextdraw[playerid][14], -1);
	PlayerTextDrawSetShadow(playerid, dsTextdraw[playerid][14], 0);
	PlayerTextDrawSetOutline(playerid, dsTextdraw[playerid][14], 0);
	PlayerTextDrawBackgroundColor(playerid, dsTextdraw[playerid][14], 255);
	PlayerTextDrawFont(playerid, dsTextdraw[playerid][14], 2);
	PlayerTextDrawSetProportional(playerid, dsTextdraw[playerid][14], 1);
	PlayerTextDrawSetShadow(playerid, dsTextdraw[playerid][14], 0);

	dsTextdraw[playerid][15] = CreatePlayerTextDraw(playerid, 43.399997, 190.093307, "");
	PlayerTextDrawLetterSize(playerid, dsTextdraw[playerid][15], 0.000000, 0.000000);
	PlayerTextDrawTextSize(playerid, dsTextdraw[playerid][15], 90.000000, 90.000000);
	PlayerTextDrawAlignment(playerid, dsTextdraw[playerid][15], 1);
	PlayerTextDrawColor(playerid, dsTextdraw[playerid][15], -1);
	PlayerTextDrawSetShadow(playerid, dsTextdraw[playerid][15], 0);
	PlayerTextDrawSetOutline(playerid, dsTextdraw[playerid][15], 0);
	PlayerTextDrawBackgroundColor(playerid, dsTextdraw[playerid][15], 0);
	PlayerTextDrawFont(playerid, dsTextdraw[playerid][15], 5);
	PlayerTextDrawSetProportional(playerid, dsTextdraw[playerid][15], 0);
	PlayerTextDrawSetShadow(playerid, dsTextdraw[playerid][15], 0);
	PlayerTextDrawSetPreviewRot(playerid, dsTextdraw[playerid][15], 0.000000, 0.000000, 0.000000, 1.000000);
	PlayerTextDrawSetPreviewVehCol(playerid, dsTextdraw[playerid][15], 1, 1);

	drivingTD[playerid][0] = CreatePlayerTextDraw(playerid, -409.199890, 358.746734, "box");
	PlayerTextDrawLetterSize(playerid, drivingTD[playerid][0], 0.000000, 12.159996);
	PlayerTextDrawTextSize(playerid, drivingTD[playerid][0], 822.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, drivingTD[playerid][0], 1);
	PlayerTextDrawColor(playerid, drivingTD[playerid][0], -1);
	PlayerTextDrawUseBox(playerid, drivingTD[playerid][0], 1);
	PlayerTextDrawBoxColor(playerid, drivingTD[playerid][0], 157);
	PlayerTextDrawSetShadow(playerid, drivingTD[playerid][0], 0);
	PlayerTextDrawSetOutline(playerid, drivingTD[playerid][0], 0);
	PlayerTextDrawBackgroundColor(playerid, drivingTD[playerid][0], 255);
	PlayerTextDrawFont(playerid, drivingTD[playerid][0], 1);
	PlayerTextDrawSetProportional(playerid, drivingTD[playerid][0], 0);
	PlayerTextDrawSetShadow(playerid, drivingTD[playerid][0], 0);

	drivingTD[playerid][1] = CreatePlayerTextDraw(playerid, -384.399871, -9.359917, "box");
	PlayerTextDrawLetterSize(playerid, drivingTD[playerid][1], 0.000000, 12.159996);
	PlayerTextDrawTextSize(playerid, drivingTD[playerid][1], 847.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, drivingTD[playerid][1], 1);
	PlayerTextDrawColor(playerid, drivingTD[playerid][1], -1);
	PlayerTextDrawUseBox(playerid, drivingTD[playerid][1], 1);
	PlayerTextDrawBoxColor(playerid, drivingTD[playerid][1], 157);
	PlayerTextDrawSetShadow(playerid, drivingTD[playerid][1], 0);
	PlayerTextDrawSetOutline(playerid, drivingTD[playerid][1], 0);
	PlayerTextDrawBackgroundColor(playerid, drivingTD[playerid][1], 255);
	PlayerTextDrawFont(playerid, drivingTD[playerid][1], 1);
	PlayerTextDrawSetProportional(playerid, drivingTD[playerid][1], 0);
	PlayerTextDrawSetShadow(playerid, drivingTD[playerid][1], 0);

	drivingTD[playerid][2] = CreatePlayerTextDraw(playerid, 320.400085, 360.230743, 
	"~y~Exam rules:~n~~w~You are not allowed to hit the car - ~r~5 ~w~penalty points~n~Before you start the engine, you need to turn on the lights, if the time is 20:00 - ~r~5 ~w~penalty points~n~Try to drive with a maximum speed 100 km/h - ~r~3 ~w~penalty points~n~~b~Drive carefully, success.");
	PlayerTextDrawLetterSize(playerid, drivingTD[playerid][2], 0.274399, 1.256533);
	PlayerTextDrawAlignment(playerid, drivingTD[playerid][2], 2);
	PlayerTextDrawColor(playerid, drivingTD[playerid][2], -1);
	PlayerTextDrawSetShadow(playerid, drivingTD[playerid][2], 1);
	PlayerTextDrawSetOutline(playerid, drivingTD[playerid][2], 1);
	PlayerTextDrawBackgroundColor(playerid, drivingTD[playerid][2], 255);
	PlayerTextDrawFont(playerid, drivingTD[playerid][2], 1);
	PlayerTextDrawSetProportional(playerid, drivingTD[playerid][2], 1);
	PlayerTextDrawSetShadow(playerid, drivingTD[playerid][2], 1);

	healthTD[playerid] = CreatePlayerTextDraw(playerid, 577.229492, 67.149978, "1%");
	PlayerTextDrawLetterSize(playerid, healthTD[playerid], 0.120000, 0.707500);
	PlayerTextDrawAlignment(playerid, healthTD[playerid], 2);
	PlayerTextDrawColor(playerid, healthTD[playerid], -1);
	PlayerTextDrawSetShadow(playerid, healthTD[playerid], 0);
	PlayerTextDrawSetOutline(playerid, healthTD[playerid], 1);
	PlayerTextDrawBackgroundColor(playerid, healthTD[playerid], 90);
	PlayerTextDrawFont(playerid, healthTD[playerid], 2);
	PlayerTextDrawSetProportional(playerid, healthTD[playerid], 1);
	PlayerTextDrawSetShadow(playerid, healthTD[playerid], 0);

	Logo[playerid][0] = CreatePlayerTextDraw(playerid, 599.382690, 405.000000, "ld_drv:ribb");
	PlayerTextDrawLetterSize(playerid, Logo[playerid][0], 0.000000, 0.000000);
	PlayerTextDrawTextSize(playerid, Logo[playerid][0], 28.000000, 24.000000);
	PlayerTextDrawAlignment(playerid, Logo[playerid][0], 1);
	PlayerTextDrawColor(playerid, Logo[playerid][0], -16777126);
	PlayerTextDrawSetShadow(playerid, Logo[playerid][0], 0);
	PlayerTextDrawSetOutline(playerid, Logo[playerid][0], 0);
	PlayerTextDrawBackgroundColor(playerid, Logo[playerid][0], 255);
	PlayerTextDrawFont(playerid, Logo[playerid][0], 4);
	PlayerTextDrawSetProportional(playerid, Logo[playerid][0], 0);
	PlayerTextDrawSetShadow(playerid, Logo[playerid][0], 0);

	Logo[playerid][1] = CreatePlayerTextDraw(playerid, 584.339904, 404.283264, "ld_drv:ribb");
	PlayerTextDrawLetterSize(playerid, Logo[playerid][1], 0.000000, 0.000000);
	PlayerTextDrawTextSize(playerid, Logo[playerid][1], -29.000000, 24.000000);
	PlayerTextDrawAlignment(playerid, Logo[playerid][1], 1);
	PlayerTextDrawColor(playerid, Logo[playerid][1], 41541722);
	PlayerTextDrawSetShadow(playerid, Logo[playerid][1], 0);
	PlayerTextDrawSetOutline(playerid, Logo[playerid][1], 0);
	PlayerTextDrawBackgroundColor(playerid, Logo[playerid][1], 255);
	PlayerTextDrawFont(playerid, Logo[playerid][1], 4);
	PlayerTextDrawSetProportional(playerid, Logo[playerid][1], 0);
	PlayerTextDrawSetShadow(playerid, Logo[playerid][1], 0);

	Logo[playerid][2] = CreatePlayerTextDraw(playerid, 574.482543, 395.559509, "ld_drv:silboat");
	PlayerTextDrawLetterSize(playerid, Logo[playerid][2], 0.000000, 0.000000);
	PlayerTextDrawTextSize(playerid, Logo[playerid][2], 35.000000, 36.000000);
	PlayerTextDrawAlignment(playerid, Logo[playerid][2], 1);
	PlayerTextDrawColor(playerid, Logo[playerid][2], -3931905);
	PlayerTextDrawSetShadow(playerid, Logo[playerid][2], 0);
	PlayerTextDrawSetOutline(playerid, Logo[playerid][2], 0);
	PlayerTextDrawBackgroundColor(playerid, Logo[playerid][2], 255);
	PlayerTextDrawFont(playerid, Logo[playerid][2], 4);
	PlayerTextDrawSetProportional(playerid, Logo[playerid][2], 0);
	PlayerTextDrawSetShadow(playerid, Logo[playerid][2], 0);

	Logo[playerid][3] = CreatePlayerTextDraw(playerid, 624.499377, 429.266601, "www.eureka-rpg.ro");
	PlayerTextDrawLetterSize(playerid, Logo[playerid][3], 0.147350, 1.349166);
	PlayerTextDrawAlignment(playerid, Logo[playerid][3], 3);
	PlayerTextDrawColor(playerid, Logo[playerid][3], -1);
	PlayerTextDrawSetShadow(playerid, Logo[playerid][3], 0);
	PlayerTextDrawSetOutline(playerid, Logo[playerid][3], 1);
	PlayerTextDrawBackgroundColor(playerid, Logo[playerid][3], 255);
	PlayerTextDrawFont(playerid, Logo[playerid][3], 2);
	PlayerTextDrawSetProportional(playerid, Logo[playerid][3], 1);
	PlayerTextDrawSetShadow(playerid, Logo[playerid][3], 0);

	warTD[playerid][0] = CreatePlayerTextDraw(playerid, 30.882289, 275.516876, "ld_grav:beea");
	PlayerTextDrawLetterSize(playerid, warTD[playerid][0], 0.000000, 0.000000);
	PlayerTextDrawTextSize(playerid, warTD[playerid][0], 29.000000, 9.000000);
	PlayerTextDrawAlignment(playerid, warTD[playerid][0], 1);
	PlayerTextDrawColor(playerid, warTD[playerid][0], 12582911);
	PlayerTextDrawSetShadow(playerid, warTD[playerid][0], 0);
	PlayerTextDrawSetOutline(playerid, warTD[playerid][0], 0);
	PlayerTextDrawBackgroundColor(playerid, warTD[playerid][0], 255);
	PlayerTextDrawFont(playerid, warTD[playerid][0], 4);
	PlayerTextDrawSetProportional(playerid, warTD[playerid][0], 0);
	PlayerTextDrawSetShadow(playerid, warTD[playerid][0], 0);

	warTD[playerid][1] = CreatePlayerTextDraw(playerid, 76.981613, 275.516876, "ld_grav:beea");
	PlayerTextDrawLetterSize(playerid, warTD[playerid][1], 0.000000, 0.000000);
	PlayerTextDrawTextSize(playerid, warTD[playerid][1], 29.000000, 9.000000);
	PlayerTextDrawAlignment(playerid, warTD[playerid][1], 1);
	PlayerTextDrawColor(playerid, warTD[playerid][1], 9182463);
	PlayerTextDrawSetShadow(playerid, warTD[playerid][1], 0);
	PlayerTextDrawSetOutline(playerid, warTD[playerid][1], 0);
	PlayerTextDrawBackgroundColor(playerid, warTD[playerid][1], 255);
	PlayerTextDrawFont(playerid, warTD[playerid][1], 4);
	PlayerTextDrawSetProportional(playerid, warTD[playerid][1], 0);
	PlayerTextDrawSetShadow(playerid, warTD[playerid][1], 0);

	warTD[playerid][2] = CreatePlayerTextDraw(playerid, 45.035308, 262.300140, "-");
	PlayerTextDrawLetterSize(playerid, warTD[playerid][2], 0.400000, 1.600000);
	PlayerTextDrawAlignment(playerid, warTD[playerid][2], 2);
	PlayerTextDrawColor(playerid, warTD[playerid][2], -1);
	PlayerTextDrawSetShadow(playerid, warTD[playerid][2], 1);
	PlayerTextDrawSetOutline(playerid, warTD[playerid][2], 0);
	PlayerTextDrawBackgroundColor(playerid, warTD[playerid][2], 255);
	PlayerTextDrawFont(playerid, warTD[playerid][2], 2);
	PlayerTextDrawSetProportional(playerid, warTD[playerid][2], 1);
	PlayerTextDrawSetShadow(playerid, warTD[playerid][2], 1);

	warTD[playerid][3] = CreatePlayerTextDraw(playerid, 91.434600, 262.300140, "-");
	PlayerTextDrawLetterSize(playerid, warTD[playerid][3], 0.400000, 1.600000);
	PlayerTextDrawAlignment(playerid, warTD[playerid][3], 2);
	PlayerTextDrawColor(playerid, warTD[playerid][3], -1);
	PlayerTextDrawSetShadow(playerid, warTD[playerid][3], 1);
	PlayerTextDrawSetOutline(playerid, warTD[playerid][3], 0);
	PlayerTextDrawBackgroundColor(playerid, warTD[playerid][3], 255);
	PlayerTextDrawFont(playerid, warTD[playerid][3], 2);
	PlayerTextDrawSetProportional(playerid, warTD[playerid][3], 1);
	PlayerTextDrawSetShadow(playerid, warTD[playerid][3], 1);

	warTD[playerid][4] = CreatePlayerTextDraw(playerid, 67.267616, 302.736907, "");
	PlayerTextDrawLetterSize(playerid, warTD[playerid][4], 0.235764, 1.279166);
	PlayerTextDrawAlignment(playerid, warTD[playerid][4], 2);
	PlayerTextDrawColor(playerid, warTD[playerid][4], -1);
	PlayerTextDrawSetShadow(playerid, warTD[playerid][4], 0);
	PlayerTextDrawSetOutline(playerid, warTD[playerid][4], 1);
	PlayerTextDrawBackgroundColor(playerid, warTD[playerid][4], 255);
	PlayerTextDrawFont(playerid, warTD[playerid][4], 3);
	PlayerTextDrawSetProportional(playerid, warTD[playerid][4], 1);
	PlayerTextDrawSetShadow(playerid, warTD[playerid][4], 0);

	warTD[playerid][5] = CreatePlayerTextDraw(playerid, 67.738204, 290.253875, "~y~loading data..");
	PlayerTextDrawLetterSize(playerid, warTD[playerid][5], 0.235764, 1.279166);
	PlayerTextDrawAlignment(playerid, warTD[playerid][5], 2);
	PlayerTextDrawColor(playerid, warTD[playerid][5], -1);
	PlayerTextDrawSetShadow(playerid, warTD[playerid][5], 0);
	PlayerTextDrawSetOutline(playerid, warTD[playerid][5], 1);
	PlayerTextDrawBackgroundColor(playerid, warTD[playerid][5], 255);
	PlayerTextDrawFont(playerid, warTD[playerid][5], 3);
	PlayerTextDrawSetProportional(playerid, warTD[playerid][5], 1);
	PlayerTextDrawSetShadow(playerid, warTD[playerid][5], 0);


	examTD[playerid] = CreatePlayerTextDraw(playerid, 331.882354, 370.250000, "~y~Examen:~n~~w~Checkpoints: ~r~0/10~n~~w~Penalty: ~r~0 ~w~points");
	PlayerTextDrawLetterSize(playerid, examTD[playerid], 0.255999, 0.987499);
	PlayerTextDrawAlignment(playerid, examTD[playerid], 2);
	PlayerTextDrawColor(playerid, examTD[playerid], -1);
	PlayerTextDrawSetShadow(playerid, examTD[playerid], 1);
	PlayerTextDrawSetOutline(playerid, examTD[playerid], 0);
	PlayerTextDrawBackgroundColor(playerid, examTD[playerid], 255);
	PlayerTextDrawFont(playerid, examTD[playerid], 2);
	PlayerTextDrawSetProportional(playerid, examTD[playerid], 1);
	PlayerTextDrawSetShadow(playerid, examTD[playerid], 1);


	moneyTD[playerid] = CreatePlayerTextDrawEx(playerid,  607.011352, 125.833251, "+18.579$", 255, 2, 0.288666, 1.355259, -1, 3, 1, true);
	
    PlayerTextDrawShow(playerid, Logo[playerid][0]),  PlayerTextDrawShow(playerid, Logo[playerid][1]),  PlayerTextDrawShow(playerid, Logo[playerid][2]);  PlayerTextDrawShow(playerid, Logo[playerid][3]);
	TextDrawShowForPlayer(playerid, ClockTime), TextDrawShowForPlayer(playerid, ClockDate);
	InitFly(playerid);
	resetData(playerid);
	return 1;
}

public OnPlayerDisconnect(playerid, reason) {
	if((GetSVarInt("livePlayer") == playerid || GetSVarInt("liveReporter") == playerid) && GetSVarInt("liveOn") == 1) {
		if(GetSVarInt("livePlayer") == playerid) { 
			ClearAnimations(GetSVarInt("liveReporter")), SetCameraBehindPlayer(GetSVarInt("liveReporter"));
			SCMEx(GetSVarInt("liveReporter"), COLOR_YELLOW, "** Live ended because your guest disconnected.");
		}
		else if(GetSVarInt("liveReporter") == playerid) { 
			ClearAnimations(GetSVarInt("livePlayer")), SetCameraBehindPlayer(GetSVarInt("livePlayer"));
			SCMEx(GetSVarInt("livePlayer"), COLOR_YELLOW, "** Live ended because your reporter disconnected.");
		}
		DeleteSVar("livePlayer"), DeleteSVar("liveReporter"), DeleteSVar("liveOn"), DeleteSVar("liveStart");
	}

	if(playerTarget[playerid] != -1) {
		contractInfo[playerTarget[playerid]][checkBy] = -1, playerTarget[playerid] = -1;
	}

	foreach(new x : contracts) {
		if(contractInfo[x][targetID] == playerid) Iter_SafeRemove(contracts, x, x);

		foreach(new y : Player) {
			if(contractInfo[playerTarget[playerid]][targetID] == playerid) SCM(playerid, COLOR_DRED, "(!) "WHITE"Your target disconnected. Contract canceled."), playerTarget[y] = -1;
		}
	}

	if(pInfo[playerid][pAdmin] > 0) {
		Iter_Remove(Admins, playerid);
	}

	for(new c; c < MAX_VEHICLES; c++) {
		if(vehID[c] > 0) {
			new x = vehID[c];
			if(pInfo[playerid][pSQLID] == pcInfo[x][pcOwner]) {
				printf("Despawned - %s, id %d", vehName[pcInfo[x][pcModel] - 400], c);
				DestroyVehicle(c);
			}
		}
	}

	foreach(new x : personalCars) {
		if(pcInfo[x][pcOwner] == pInfo[playerid][pSQLID]) {
			pcInfo[x][pcSpawned] = pcInfo[x][pcTimeToSpawn] = 0;
			Iter_SafeRemove(personalCars, x, x);
		}
	}

	saveAccount(playerid);
	return 1;
}

// Login
forward accountCheckBan(playerid);
public accountCheckBan(playerid) {
	if(cache_num_rows()) {
		InterpolateCameraPos(playerid, 2062.878906, 988.830627, 11.947507, 2022.668579, 1397.960937, 27.489007, 20000);
		InterpolateCameraLookAt(playerid, 2063.091552, 993.787048, 12.570880, 2022.038208, 1402.912109, 27.785707, 10000);
		GameTextForPlayer(playerid, "Banned", 5000, 2);
		new bannedBy[MAX_PLAYER_NAME + 1], reason[30];

		cache_get_field_content(0, "bannedBy",  bannedBy, handle, MAX_PLAYER_NAME + 1);
		cache_get_field_content(0, "reason",  reason, handle, 30);

		SCMEx(playerid, COLOR_DRED, "You have been permanently banned on all accounts, you can`t play anymore on this server.");
		SCMEx(playerid, COLOR_LIGHT, "The ban was given by %s, reason: %s", bannedBy, reason);
		defer kickTimer(playerid);
	}
	else {
		new query[128];
		mysql_format(handle, query, 128, "SELECT * FROM `players` WHERE `username` = '%e'", GetName(playerid));
		mysql_tquery(handle, query, "accountCheck", "i", playerid);
	}
	return 1;
}	

forward accountCheck(playerid);
public accountCheck(playerid) {
	cache_get_data(rows, fields, handle);
	if(rows) {
		ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "SERVER: Login", ""SYN"Welcome back to eureka RPG"SYN"!\n\nYour account has been found in our database, you need to log in.\nPlease enter your password below.", "Login", "Cancel");
		GameTextForPlayer(playerid, "~y~ACCOUNT FOUND", 5000, 4);
	}
	else {
		
		ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "SERVER: Login", ""SYN"Welcome to eureka RPG"SYN"!\n\nYour account was not found in our database, make one.\nPlease enter a new password bellow.", "Register", "Cancel");
		GameTextForPlayer(playerid, "~y~ACCOUNT NOT FOUND", 5000, 4);
	}
	InterpolateCameraPos(playerid, 2062.878906, 988.830627, 11.947507, 2022.668579, 1397.960937, 27.489007, 20000);
	InterpolateCameraLookAt(playerid, 2063.091552, 993.787048, 12.570880, 2022.038208, 1402.912109, 27.785707, 10000);
	return 1;
}

forward accountLogin(playerid);
public accountLogin(playerid) {
	cache_get_data(rows, fields, handle);
	if(rows) {
		pInfo[playerid][pSQLID] = cache_get_field_content_int(0, "ID");
		cache_get_field_content(0, "username",  pInfo[playerid][pName], handle, MAX_PLAYER_NAME + 1);
		cache_get_field_content(0, "SerialCode", pInfo[playerid][pSerialCode], handle, 41);
		cache_get_field_content(0, "password", pInfo[playerid][pPassword], handle, 129);
		cache_get_field_content(0, "Email", pInfo[playerid][pEmail], handle, 100);
		cache_get_field_content(0, "WantedReason", pInfo[playerid][pWantedReason], handle, 200);

		pInfo[playerid][pLevel] = cache_get_field_content_int(0, "Level");
		pInfo[playerid][pEPoints] = cache_get_field_content_int(0, "eurekaPoints");
		pInfo[playerid][pAdmin] = cache_get_field_content_int(0, "AdminLevel");
		pInfo[playerid][pMoney] = cache_get_field_content_int(0, "Cash");
		pInfo[playerid][pBank] = cache_get_field_content_int(0, "Bank");
		pInfo[playerid][pWarns] = cache_get_field_content_int(0, "Warns");
		pInfo[playerid][pAge] = cache_get_field_content_int(0, "Age");
		pInfo[playerid][pSex] = cache_get_field_content_int(0, "Sex");
		pInfo[playerid][pMember] = cache_get_field_content_int(0, "Member");
		pInfo[playerid][pRank] = cache_get_field_content_int(0, "Rank");
		pInfo[playerid][pGJoinDate] = cache_get_field_content_int(0, "playerDays");
		pInfo[playerid][pFWarns] = cache_get_field_content_int(0, "FWarns");
		pInfo[playerid][pFPunish] = cache_get_field_content_int(0, "FPunish");
		pInfo[playerid][pSkin] = cache_get_field_content_int(0, "Skin");
		pInfo[playerid][pMaterials] = cache_get_field_content_int(0, "Materials");
		pInfo[playerid][pDrugs] = cache_get_field_content_int(0, "Drugs");
		pInfo[playerid][pJob] = cache_get_field_content_int(0, "Job");
		pInfo[playerid][pMatsSkill] = cache_get_field_content_int(0, "MatsSkill");
		pInfo[playerid][pMaxSlots] = cache_get_field_content_int(0, "MaxSlots");
		pInfo[playerid][pCarLic] = cache_get_field_content_int(0, "CarLic");
		pInfo[playerid][pGunLic] = cache_get_field_content_int(0, "GunLic");
		pInfo[playerid][pFlyLic] = cache_get_field_content_int(0, "FlyLic");
		pInfo[playerid][pBoatLic] = cache_get_field_content_int(0, "BoatLic");
		pInfo[playerid][pLoyalityPoints] = cache_get_field_content_int(0, "LoyalityPoints");
		pInfo[playerid][pLoyalityAccount] = cache_get_field_content_int(0, "LoyalityAccount");
		pInfo[playerid][pWanted] = cache_get_field_content_int(0, "Wanted");
		playerJailTime[playerid] = cache_get_field_content_int(0, "jailTime");
		playerJailType[playerid] = cache_get_field_content_int(0, "jailType");

		// Hud
		pInfo[playerid][pHudHealth] = cache_get_field_content_int(0, "hudHealth");

		if(pInfo[playerid][pHudHealth]) { PlayerTextDrawShow(playerid, healthTD[playerid]); }
		
		format(gMsg, 100, "www.eureka-rpg.ro", GetName(playerid)), PlayerTextDrawSetString(playerid, Logo[playerid][3], gMsg);
		Clearchat(playerid, 20), SCM(playerid, COLOR_LIGHT, "SERVER: "WHITE"Welcome back, have fun!");
	
		if(pInfo[playerid][pAdmin] > 0) {
			format(gMsg, 70, "New connection: %s (%d) has just logged in.", pInfo[playerid][pName], playerid), sendAdmins(0xCC8E33C8, gMsg);
		}
		
		if(pInfo[playerid][pMember]) { SCMEx(playerid, COLOR_TEAL, "Faction Motto: "WHITE"%s", gInfo[pInfo[playerid][pMember]][gMotto]); }
		
		if(pInfo[playerid][pAdmin] > 0) { Iter_Add(Admins, playerid); }

		if(pInfo[playerid][pMember] > 0) {
			if(gInfo[pInfo[playerid][pMember]][gWar] > 0) {
				pInfo[playerid][pWarKills] = pInfo[playerid][pWarDeaths] = 0;
				new w = gInfo[pInfo[playerid][pMember]][gWar];

				// pInfo[playerid][pWarKills] = pInfo[playerid][pWarDeaths] = 0;
				PlayerTextDrawColor(playerid, warTD[playerid][0], getFactionColor(wInfo[w][wAttacker])), PlayerTextDrawColor(playerid, warTD[playerid][1], getFactionColor(wInfo[w][wDeffender]));
				for(new x; x < 6; x++) { PlayerTextDrawShow(playerid, warTD[playerid][x]); } 

				// Checkpoints on map
				foreach(new z : Player) {
					if(gInfo[pInfo[z][pMember]][gWar] == w) { OnPlayerStreamIn(playerid, z); }
				}
			}
		}

		if(playerJailTime[playerid] > 0) {
			PlayerTextDrawSetString(playerid, examTD[playerid], "~r~Jailed~n~~w~Loading..."), PlayerTextDrawShow(playerid, examTD[playerid]);
			Iter_Add(jailPlayers, playerid);
		}

		if(pInfo[playerid][pWanted] > 0) {
			SetPlayerWantedLevel(playerid, pInfo[playerid][pWanted]);
		}
		
		new serial[41], query[100];
		gpci(playerid, serial, 41);
		if(strcmp(pInfo[playerid][pSerialCode], serial, false)) {
			new randCod[10];
			format(randCod, 10, randomString(10));
			mysql_format(handle, query, 256, "INSERT INTO `accounts_blocked` (`playerID`, `time`, `securityCode`) VALUES ('%d', '%d', '%e')", pInfo[playerid][pSQLID], GetTickCount(), randCod);
			mysql_tquery(handle, query, "", "");
			
			// codul nu va mai veni pe email, trebuie realizati din nou aceasta parte a sistemului;
			// link download mailer: https://forum.sa-mp.com/showthread.php?t=197755

			ShowPlayerDialog(playerid, DIALOG_BLOCK, DIALOG_STYLE_PASSWORD, "SERVER: Account blocked", 
			""SYN"This account is "DRED"blocked "SYN"because you are logged in from a different location.\n\nTo unblock your account you need to use a security cod, sended to your email.\nYou have 2 minutes "SYN"to use it.", "Proceed", "Cancel");
			defer securityKick(playerid);
		}

		SetPlayerScore(playerid, pInfo[playerid][pLevel]), SetPlayerHealth(playerid, 99.00);
		playerHP[playerid] = 99.00, playerArmour[playerid] = 0.00; pLogged[playerid] = 1; 
		SpawnPlayer(playerid);
	}
	else {
		if(2-loginTries[playerid] != 0) {
			loginTries[playerid] ++;
			SCMEx(playerid, COLOR_DRED, "You have %d attempts to login, otherwise you will be kicked from the server.", 3-loginTries[playerid]);
			ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "SERVER: Login", ""SYN"Welcome back to eureka RPG"SYN"!\n\nYour account has been found in our database, you need to log in.\nPlease enter your "DRED"correct"SYN" password.", "Login", "Cancel");
		} else ShowPlayerDialog(playerid, DIALOG_GENERAL, DIALOG_STYLE_MSGBOX, "SERVER: Wrong password", "You have been kicked because you wrote wrong password 3 times.", "Okay", ""), defer kickTimer(playerid);
	}

	mysql_format(handle, gMsg, 128, "SELECT * FROM `personalcars` WHERE `Owner` = '%d'", pInfo[playerid][pSQLID]);
	mysql_tquery(handle, gMsg, "loadPersonalCars", "i", playerid);

	return 1;
}

// Load Data
forward loadGroups();
public loadGroups() {
	cache_get_data(rows, fields);
	if(rows) {
		new id, pickup;
		for(new i; i < rows; i++) {
			id = cache_get_field_content_int(i, "id");
			gInfo[id][gID] = id;
			cache_get_field_content(i, "Name", gInfo[id][gName], handle, 50);
			cache_get_field_content(i, "Motto", gInfo[id][gMotto], handle, 128);
			cache_get_field_content(i, "rankName1", gInfo[id][gRankname1], handle, 20);
			cache_get_field_content(i, "rankName2", gInfo[id][gRankname2], handle, 20);
			cache_get_field_content(i, "rankName3", gInfo[id][gRankname3], handle, 20);
			cache_get_field_content(i, "rankName4", gInfo[id][gRankname4], handle, 20);
			cache_get_field_content(i, "rankName5", gInfo[id][gRankname5], handle, 20);
			cache_get_field_content(i, "rankName6", gInfo[id][gRankname6], handle, 20);
			cache_get_field_content(i, "rankName7", gInfo[id][gRankname7], handle, 20);
			
			gInfo[id][geX] = cache_get_field_content_float(i, "eX");
			gInfo[id][geY] = cache_get_field_content_float(i, "eY");
			gInfo[id][geZ] = cache_get_field_content_float(i, "eZ");
			
			gInfo[id][giX] = cache_get_field_content_float(i, "iX");
			gInfo[id][giY] = cache_get_field_content_float(i, "iY");
			gInfo[id][giZ] = cache_get_field_content_float(i, "iZ");
			
			gInfo[id][gSafeX] = cache_get_field_content_float(i, "SafeX");
			gInfo[id][gSafeY] = cache_get_field_content_float(i, "SafeY");
			gInfo[id][gSafeZ] = cache_get_field_content_float(i, "SafeZ");
			
			gInfo[id][gMaterials] = cache_get_field_content_int(i, "Materials");
			gInfo[id][gDrugs] = cache_get_field_content_int(i, "Drugs");
			gInfo[id][gMoney] = cache_get_field_content_int(i, "Money");
			
			gInfo[id][gApplications] = cache_get_field_content_int(i, "Applications");
			gInfo[id][gType] = cache_get_field_content_int(i, "Type");
			gInfo[id][gInterior] = cache_get_field_content_int(i, "Interior");
			gInfo[id][gDoor] = cache_get_field_content_int(i, "Door");
			gInfo[id][gSlots] = cache_get_field_content_int(i, "Slots");
			gInfo[id][gLeadskin] = cache_get_field_content_int(i, "leadSkin");

			format(gMsg, 128, "{FF6347}%s`s HQ\n{D2B48C}(%s)", gInfo[id][gName], (gInfo[id][gDoor]) ? ("closed") : ("opened"));

			if(gInfo[id][gType] == 1) { pickup = 1247; }
			else if(gInfo[id][gType] == 2 || gInfo[id][gType] == 5 || gInfo[id][gType] == 6 || gInfo[id][gType] == 7) { pickup = 1314; }
			else if(gInfo[id][gType] == 3) { pickup = 19130; }
			else if(gInfo[id][gType] == 4) { pickup = 1254; }
			
			else { pickup = 1239; }
			
			gInfo[id][gPickup] = CreateDynamicPickup(pickup, 1, gInfo[id][geX], gInfo[id][geY], gInfo[id][geZ], -1, -1, -1, 30.0);
			gInfo[id][gLabel] = CreateDynamic3DTextLabel(gMsg, COLOR_YELLOW, gInfo[id][geX], gInfo[id][geY], gInfo[id][geZ], 100, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, -1, -1, -1, 30.0);
			
			format(gMsg, 128, "%s`s\nFaction deposit", gInfo[id][gName]);
			gInfo[id][gSafePickup] = CreateDynamicPickup(1274, 1, gInfo[id][gSafeX], gInfo[id][gSafeY], gInfo[id][gSafeZ], id+1, -1, -1, 10.0);
			gInfo[id][gSafeLabel] =  CreateDynamic3DTextLabel(gMsg, 0xFFFF00AA, gInfo[id][gSafeX], gInfo[id][gSafeY], gInfo[id][gSafeZ], 100, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, id+1, -1, -1, 10.0);
		}
	}
	else print("No groups.");
	return 1;
}

forward loadCars();
public loadCars() {

	cache_get_data(rows, fields, handle);
	if(rows) {
		new i, car, alarm, doors, bonnet, boot, objective, lights;
		for(new x = 0; x < rows; x++) {
			i = cache_get_field_content_int(x, "id");
			vInfo[i][vID] = i;
			vInfo[i][vModel] = cache_get_field_content_int(x, "Model");
			vInfo[i][vGroup] = cache_get_field_content_int(x, "Group");
			vInfo[i][vX] = cache_get_field_content_float(x, "pX");
			vInfo[i][vY] = cache_get_field_content_float(x, "pY");
			vInfo[i][vZ] = cache_get_field_content_float(x, "pZ");
			vInfo[i][vA] = cache_get_field_content_float(x, "pA");
			cache_get_field_content(x, "CarPlate", vInfo[i][vCarPlate], handle, 11);
			vInfo[i][vColor1] = cache_get_field_content_int(x, "Color1");
			vInfo[i][vColor2] = cache_get_field_content_int(x, "Color2");

			if(gInfo[vInfo[i][vGroup]][gType] == 1 && vInfo[i][vModel] == 411) {
				car = CreateVehicle(vInfo[i][vModel], vInfo[i][vX], vInfo[i][vY], vInfo[i][vZ], vInfo[i][vA], vInfo[i][vColor1], vInfo[i][vColor2], -1, 1);
				vInfo[i][vObject] = CreateObject(19620,0,0,0,0,0,0,80 ); // <Infernus>
				AttachObjectToVehicle(vInfo[i][vObject], car, 0.000000, 0.000000, 0.699999, 0.000000, 0.000000, 0.000000 );
			}
			else if(gInfo[vInfo[i][vGroup]][gType] == 1 && vInfo[i][vModel] == 475) {
				car = CreateVehicle(vInfo[i][vModel], vInfo[i][vX], vInfo[i][vY], vInfo[i][vZ], vInfo[i][vA], vInfo[i][vColor1], vInfo[i][vColor2], -1, 1);
				vInfo[i][vObject] = CreateObject( 19620,0,0,0,0,0,0,80 ); // <Sabre>
				AttachObjectToVehicle(vInfo[i][vObject], car, 0.000000, -0.119999, 0.759999, 0.000000, 0.000000, 0.000000 ), AddVehicleComponent(car, 1098);
			}
			else if(gInfo[vInfo[i][vGroup]][gType] == 1 && vInfo[i][vModel] == 490) {
				car = CreateVehicle(vInfo[i][vModel], vInfo[i][vX], vInfo[i][vY], vInfo[i][vZ], vInfo[i][vA], vInfo[i][vColor1], vInfo[i][vColor2], -1, 1);
				vInfo[i][vObject] = CreateObject( 19420,0,0,0,0,0,0,80 ); // <rancherFBI>
				vInfo[i][vObject2] = CreateObject( 19777,0,0,0,0,0,0,80 ); // <rancherFBI>
				AttachObjectToVehicle(vInfo[i][vObject], car, 0.000000, 0.529999, 1.090000, 0.000000, 0.000000, 0.000000 );
				AttachObjectToVehicle(vInfo[i][vObject2], car, -0.000000, -3.159999, 0.100000, 89.000000, 0.000000, 0.000000 ); // <fbi spate>
			}
			else {
				car = CreateVehicle(vInfo[i][vModel], vInfo[i][vX], vInfo[i][vY], vInfo[i][vZ], vInfo[i][vA], vInfo[i][vColor1], vInfo[i][vColor2], -1);
			}	
			svrVeh[car] = vInfo[i][vID];
			SetVehicleNumberPlate(car, vInfo[i][vCarPlate]);
    		SetVehicleParamsEx(car, 0, lights, alarm, doors, bonnet, boot, objective);
		}
	}
	else print("No cars.");
	return 1;
}

forward loadTurfs();
public loadTurfs() {

	cache_get_data(rows, fields, handle);
	if(rows) {
		for(new x = 0; x < rows; x++) {
			new i = cache_get_field_content_int(x, "ID");
			tInfo[i][tID] = i;
			tInfo[i][tOwner] = cache_get_field_content_int(x, "Owner");
			tInfo[i][tMinX] = cache_get_field_content_float(x, "MinX");
			tInfo[i][tMinY] = cache_get_field_content_float(x, "MinY");
			tInfo[i][tMaxX] = cache_get_field_content_float(x, "MaxX");
			tInfo[i][tMaxY] = cache_get_field_content_float(x, "MaxY");

			Turfs[i] = CreateZone(tInfo[i][tMinX],tInfo[i][tMinY],tInfo[i][tMaxX],tInfo[i][tMaxY]);
			CreateZoneNumber(Turfs[i], i);
			CreateZoneBorders(Turfs[i]);
		}
	}
	else print("No turfs.");
	return 1;
}

forward loadJobs();
public loadJobs() {
	cache_get_data(rows, fields);
	if(rows) {
		new id;
		for(new i; i < rows; i++) {
			id = cache_get_field_content_int(i, "id");
			jInfo[id][jID] = id;
			jInfo[id][jStatus] = cache_get_field_content_int(i, "Status");
			jInfo[id][jType] = cache_get_field_content_int(i, "Type");  

			cache_get_field_content(i, "Name", jInfo[id][jName], handle, 50);
			
			jInfo[id][jX] = cache_get_field_content_float(i, "X");
			jInfo[id][jY] = cache_get_field_content_float(i, "Y");
			jInfo[id][jZ] = cache_get_field_content_float(i, "Z");

			updateJobLabel(id);
			
			jInfo[id][jPickup] = CreateDynamicPickup(1275, 1, jInfo[id][jX], jInfo[id][jY], jInfo[id][jZ], -1, -1, -1, 30.0);
			
		}
	}
	else print("The are no jobs.");
	return 1;
}

forward saveGroup(id);
public saveGroup(id) {
	new query[500];
	mysql_format(handle, query, 500, 
	"UPDATE `groups` SET `Name` = '%s', `Motto` = '%s', `eX` = '%f', `eY` = '%f', `eZ` = '%f', `iX` = '%f', `iY` = '%f', `iZ` = '%f', `rankName1` = '%s', `rankName2` = '%s', `rankName3` = '%s', `rankName4` = '%s', `rankName5` = '%s', `rankName6` = '%s', `rankName7` = '%s', `Type` = '%d', `Interior` = '%d', `Door` = '%d', `leadSkin` = '%d' WHERE `id` = '%d'",
	gInfo[id][gName], gInfo[id][gMotto], gInfo[id][geX], gInfo[id][geY],gInfo[id][geZ], gInfo[id][giX], gInfo[id][giY], gInfo[id][giZ], gInfo[id][gRankname1], gInfo[id][gRankname2], gInfo[id][gRankname3], gInfo[id][gRankname4], gInfo[id][gRankname5], gInfo[id][gRankname6], gInfo[id][gRankname7], gInfo[id][gType], gInfo[id][gInterior], gInfo[id][gDoor], gInfo[id][gLeadskin], id);
	mysql_tquery(handle, query, "", "");
	
	mysql_format(handle, query, 500, "UPDATE `groups` SET `SafeX` = '%f', `SafeY` = '%f', `SafeZ` = '%f', `Slots` = '%d', `Type` = '%d' WHERE `id` = '%d'", gInfo[id][gSafeX], gInfo[id][gSafeY], gInfo[id][gSafeZ], gInfo[id][gSlots], gInfo[id][gType], id);
	mysql_tquery(handle, query, "", "");
	return 1;
}

forward saveJob(id);
public saveJob(id) {
	new query[500];
	mysql_format(handle, query, 500, "UPDATE `jobs` SET `Name` = '%e', `Type` = '%d', `X` = '%f', `Y` = '%f', `Z` = '%f', `Status` = '%d' WHERE `id` = '%d'", jInfo[id][jName], jInfo[id][jType], jInfo[id][jX], jInfo[id][jY], jInfo[id][jZ], jInfo[id][jStatus], id);
	mysql_tquery(handle, query, "", "");
	return 1;
}

forward savePersonals(vid);
public savePersonals(vid) {
	if(pcInfo[vid][pcID] != 0) {
		new saveQuery[1000];
		mysql_format(handle, saveQuery, 1000, "UPDATE `personalcars` SET `Owner` = '%d', `Model` = '%d', `PosX` = '%f', `PosY` = '%f', `PosZ` = '%f', `PosA` = '%f', `Color1` = '%d', `Color2` = '%d', `LockStatus` = '%d', `Insurance` = '%d', `Age` = '%d', `Odometer` = '%d' WHERE `id` = '%d'",
		pcInfo[vid][pcOwner], pcInfo[vid][pcModel], pcInfo[vid][pcPosX], pcInfo[vid][pcPosY], pcInfo[vid][pcPosZ], pcInfo[vid][pcPosA], pcInfo[vid][pcColor1], pcInfo[vid][pcColor2], pcInfo[vid][pcLockStatus], pcInfo[vid][pcInsurance], pcInfo[vid][pcAge], pcInfo[vid][pcOdometer], pcInfo[vid][pcID]);
		mysql_tquery(handle, saveQuery);
		
		mysql_format(handle, saveQuery, 1000, "UPDATE `personalcars` SET `Mod1` = '%d', `Mod2` = '%d', `Mod3` = '%d', `Mod4` = '%d', `Mod5` = '%d', `Mod6` = '%d', `Mod7` = '%d', `Mod8` = '%d', `Mod9` = '%d', `Mod10` = '%d', `Mod11` = '%d', `Mod12` = '%d', `Mod13` = '%d', `Mod14` = '%d', `Mod15` = '%d', `Mod16` = '%d' WHERE `id` = '%d'",
		pcInfo[vid][pcMod][1], pcInfo[vid][pcMod][2], pcInfo[vid][pcMod][3], pcInfo[vid][pcMod][4], pcInfo[vid][pcMod][5], pcInfo[vid][pcMod][6], pcInfo[vid][pcMod][7], pcInfo[vid][pcMod][8], pcInfo[vid][pcMod][9], pcInfo[vid][pcMod][10], pcInfo[vid][pcMod][11], pcInfo[vid][pcMod][12], pcInfo[vid][pcMod][13], pcInfo[vid][pcMod][14], pcInfo[vid][pcMod][15],  pcInfo[vid][pcMod][16], pcInfo[vid][pcID]);
		mysql_tquery(handle, saveQuery);
	}
	return 1;
}

forward saveVeh(car);
public saveVeh(car) {
	new query[500];
	mysql_format(handle, query, 500, "UPDATE `cars` SET `Model` = '%d', `Group` = '%d', `CarPlate` = '%e', `pX` = '%f', `pY` = '%f', `pZ` = '%f', `pA` = '%f', `Color1` = '%d', `Color2` = '%d' WHERE `id` = '%d'",
	vInfo[car][vModel], vInfo[car][vGroup], vInfo[car][vCarPlate], vInfo[car][vX], vInfo[car][vY], vInfo[car][vZ], vInfo[car][vA], vInfo[car][vColor1], vInfo[car][vColor2], car);
	mysql_tquery(handle, query, "", "");
	return 1;
}

forward saveAccount(playerid);
public saveAccount(playerid) {
	new query[500];
	mysql_format(handle, query, 500, "UPDATE `players` SET 	`username` = '%e', `Level` = '%d', `Email` = '%e', `AdminLevel` = '%d', `Member` = '%d', `Rank` = '%d', `Skin` = '%d', `Cash` = '%d', `Bank` = '%d' WHERE `ID` = '%d'",  
	pInfo[playerid][pName], pInfo[playerid][pLevel], pInfo[playerid][pEmail], pInfo[playerid][pAdmin], pInfo[playerid][pMember], pInfo[playerid][pRank], pInfo[playerid][pSkin], pInfo[playerid][pMoney], pInfo[playerid][pBank], pInfo[playerid][pSQLID]);
	mysql_tquery(handle, query, "", "");

	mysql_format(handle, query, 500, "UPDATE `players` SET 	`eurekaPoints` = '%d', `Materials` = '%d', `Drugs` = '%d', `Warns` = '%d', `FWarns` = '%d', `playerDays` = '%d', `FPunish` = '%d', `Job` = '%d', `MatsSkill` = '%d' WHERE `ID` = '%d'",  
	pInfo[playerid][pEPoints], pInfo[playerid][pMaterials], pInfo[playerid][pDrugs], pInfo[playerid][pWarns], pInfo[playerid][pFWarns], pInfo[playerid][pGJoinDate], pInfo[playerid][pFPunish], pInfo[playerid][pJob], pInfo[playerid][pMatsSkill], pInfo[playerid][pSQLID]);
	mysql_tquery(handle, query, "", "");

	mysql_format(handle, query, 500, "UPDATE `players` SET 	`LoyalityAccount` = '%d', `LoyalityPoints` = '%d', `PhoneNumber` = '%d', `hudHealth` = '%d', `MaxSlots` = '%d', `jailTime` = '%d', `jailType` = '%d' WHERE `ID` = '%d'", 
		pInfo[playerid][pLoyalityAccount], pInfo[playerid][pLoyalityPoints],  pInfo[playerid][pPhoneNumber], pInfo[playerid][pHudHealth], pInfo[playerid][pMaxSlots], playerJailTime[playerid], playerJailType[playerid], pInfo[playerid][pSQLID]);
	mysql_tquery(handle, query, "", "");
	
	mysql_format(handle, query, 500, "UPDATE `players` SET `GunLic` = '%d', `FlyLic` = '%d', `BoatLic` = '%d', `CarLic` = '%d', `Wanted` = '%d', `WantedReason` = '%e' WHERE `ID` = '%d'", pInfo[playerid][pGunLic], pInfo[playerid][pFlyLic], pInfo[playerid][pBoatLic], pInfo[playerid][pCarLic], pInfo[playerid][pWanted], pInfo[playerid][pWantedReason], pInfo[playerid][pSQLID]);
	mysql_tquery(handle, query, "", "");	
	return 1;
}

forward securityCodeCheck(playerid);
public securityCodeCheck(playerid) {
	cache_get_data(rows, fields, handle);
	if(rows) { SCM(playerid, COLOR_LIGHTRED, "You have entered the correct code, now you can play!"), enteredCode[playerid] = 1; }
	else ShowPlayerDialog(playerid, DIALOG_BLOCK, DIALOG_STYLE_PASSWORD, "SERVER: Account blocked", 
			""SYN"You used a "DRED"incorrect code"SYN", try again.\n\nTo unblock your account you need to use a security cod, sended to your email.\nYou have 2 minutes "SYN"to use it.", "Proceed", "Cancel");
	return 1;
}

forward OnPlayerHealthModify(playerid, Float:oldhp, Float:newhp);
public OnPlayerHealthModify(playerid, Float:oldhp, Float:newhp) {
	if(newhp > oldhp && (GetTickCount() - killTime[playerid]) > 1500) {
		sendAdmins(COLOR_DRED, "Kick: %s has been kicked by the system, reason: possible health-hack.", GetName(playerid));
		SCM(playerid, COLOR_LIGHTRED, "You have been kicked by the system, reason: possible health-hack.")/*, defer kickTimer(x)*/;
	}
	return 1;
}


public OnPlayerSpawn(playerid)
{
    if(pLogged[playerid] == 1)
	{
		PreloadAnimLib(playerid,"BOMBER");
		PreloadAnimLib(playerid,"RAPPING");
		PreloadAnimLib(playerid,"SHOP");
		PreloadAnimLib(playerid,"BEACH");
		PreloadAnimLib(playerid,"SMOKING");
		PreloadAnimLib(playerid,"ON_LOOKERS");
		PreloadAnimLib(playerid,"DEALER");
		PreloadAnimLib(playerid,"CRACK");
		PreloadAnimLib(playerid,"CARRY");
		PreloadAnimLib(playerid,"COP_AMBIENT");
		PreloadAnimLib(playerid,"PARK");
		PreloadAnimLib(playerid,"INT_HOUSE");
		PreloadAnimLib(playerid,"FOOD");
		PreloadAnimLib(playerid,"GANGS");
		PreloadAnimLib(playerid,"PED");
		PreloadAnimLib(playerid,"FAT");

		playerLive[playerid] = 1;
		SetPlayerTeam(playerid, NO_TEAM), setHealth(playerid, 99.0), setArmour(playerid, 0), killTime[playerid] = GetTickCount();
		SetPlayerColor(playerid, getFactionColor(pInfo[playerid][pMember]));

		if(playerCover[playerid] == 0) { SetPlayerSkin(playerid, pInfo[playerid][pSkin]); }
			else { SetPlayerSkin(playerid, random(100)); }

		Delete3DTextLabel(playerDeathLabel[playerid]); 
		if(adminDuty[playerid] == true) { SetPlayerColor(playerid, 0x89D900FF); }
		
		if(playerJailTime[playerid] <= 0) {
			if(DMVTest[playerid] == 0) {
				if(pInfo[playerid][pMember] > 0) // 
				{
					new i = pInfo[playerid][pMember];
					playerHQ[playerid] = i;
					SetPlayerPos(playerid, gInfo[i][giX], gInfo[i][giY], gInfo[i][giZ]);
					SetPlayerInterior(playerid, gInfo[i][gInterior]);
					SetPlayerVirtualWorld(playerid, i+1);
					SetCameraBehindPlayer(playerid);

					if(pInfo[playerid][pDuty]) { 
						putDutyObjects(playerid), setArmour(playerid, 99.0);
						GivePlayerWeapon(playerid, 24, 100), GivePlayerWeapon(playerid, 31, 350), GivePlayerWeapon(playerid, 29, 100), GivePlayerWeapon(playerid, 41, 999); 
					}

					if(gInfo[i][gType] == 3) { GivePlayerWeapon(playerid, 24, 100); }
					if(gInfo[i][gType] == 7) { GivePlayerWeapon(playerid, 43, 100); }
			    }
			    else if (pInfo[playerid][pMember] == 0) {
					SetPlayerPos(playerid, 1127.0157,-2036.9995,69.8836), SetPlayerFacingAngle(playerid, 265.9748);
					SetPlayerInterior(playerid, 0), SetPlayerVirtualWorld(playerid, 0), SetCameraBehindPlayer(playerid);
			    }
			}
			else PutPlayerInVehicle(playerid, DMVVehicle[playerid], 0);
		}
		else {
			new spawn = random(sizeof(randomJail));
			SetPlayerInterior(para, 6), SetPlayerVirtualWorld(para, 2);
			SetPlayerPos(para, randomJail[spawn][0], randomJail[spawn][1], randomJail[spawn][2]), SetPlayerFacingAngle(para, 180.0);
		}
	}
	else Kick(playerid);
	return 1;
}

public OnVehicleDamageStatusUpdate(vehicleid, playerid)
{
	if(DMVTest[playerid] == 1 && DMVCP[playerid] != 0)
	{
		if(GetTickCount() - DMVLastcrash[playerid] > 4000) {
			if(PenaltyPoints[playerid] <= 25) {
				DMVLastcrash[playerid] = GetTickCount();
				PenaltyPoints[playerid] += 5;
				showPlayerDMVTD(playerid);
			}
			else {
				PlayerTextDrawHide(playerid, examTD[playerid]);
				DestroyVehicle(DMVVehicle[playerid]), DestroyObject(DMVObject[playerid]);
				PenaltyPoints[playerid] = DMVTest[playerid] = DMVCP[playerid] = 0, DMVVehicle[playerid] = -1;
				SCM(playerid, COLOR_GREEN, "Instructor: {C2C3C4}You failed the driving test because you`ve accumulated 25 penalty points.");
				DisablePlayerRaceCheckpoint(playerid);
			}
		}
	}
	return 1;
}

public OnPlayerTakeDamage(playerid, issuerid, Float:amount, weaponid, bodypart) {
	if(!IsPlayerPaused(playerid) && flyingStatus[playerid] == false) {
		new Float:healt, Float:armour;
		GetPlayerHealth(playerid, healt), GetPlayerArmour(playerid, armour);
		if((armour - amount) < 1 ) {
			setArmour(playerid, 0.00), setHealth(playerid, healt - amount);
		}
		else setHealth(playerid, healt), setArmour(playerid, armour - amount);
	}
	return 1;
}

public OnPlayerGiveDamage(playerid, damagedid, Float: amount, weaponid, bodypart)
{
	if(playerLive[damagedid] == 1) {
		if(IsPlayerPaused(damagedid && flyingStatus[damagedid] == false)) {
			if(playerArmour[damagedid] - amount < 1) {
				playerHP[damagedid] -= amount, playerArmour[damagedid] = 0.00;
				if(playerHP[damagedid] < 1) {
					OnPlayerDeath(damagedid, playerid, weaponid);
					playerDeathLabel[damagedid] = Create3DTextLabel(""CREM"[death]", -1, 30.0, 40.0, 50.0, 40.0, 0);
		   			Attach3DTextLabelToPlayer(playerDeathLabel[damagedid], damagedid, 0.0, 0.0, 0.3);
				}
			}
			else playerArmour[damagedid] -= amount;
		}
		
	}
    return 1;
}

public OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ) {
	if(playerTarget[playerid] != -1) {
		if(contractInfo[playerTarget[playerid]][targetID] == hitid && (GetPlayerWeapon(playerid) == 34 || GetPlayerWeapon(playerid) == 4 || GetPlayerWeapon(playerid) == 24)) {
			new string[128], Float:px, Float:py, Float:pz;
			GetPlayerPos(contractInfo[playerTarget[playerid]][targetID], px, py, pz);

			format(string, 128, "Agency ad: %s successfully killed %s from %0.2fm and received $%s.", 
				GetName(playerid), GetName(contractInfo[playerTarget[playerid]][targetID]), GetPlayerDistanceFromPoint(playerid, px, py, pz), FormatNumber(contractInfo[playerTarget[playerid]][targetSum]));
			sendGroup(COLOR_TEAL, pInfo[playerid][pMember], string);

			contractInfo[playerTarget[playerid]][targetSum] = 0;
			setArmour(contractInfo[playerTarget[playerid]][targetSum], 0.00), setHealth(contractInfo[playerTarget[playerid]][targetSum], 0.00);
			Iter_Remove(contracts, playerTarget[playerid]), SetPlayerSkin(playerid, pInfo[playerid][pSkin]), ClearAnimations(playerid);
			playerTarget[playerid] = -1, playerCover[playerid] = 0;
			foreach(new x : Player) {
				ShowPlayerNameTagForPlayer(x, playerid, true);
			}
		}
		else {
			if(GetPlayerDistanceFromPoint(contractInfo[playerTarget[playerid]][targetID], fX, fY, fZ) <= 2.0 && GetPlayerWeapon(playerid) == 34) {
				SCM(contractInfo[playerTarget[playerid]][targetID], COLOR_YELLOW, "** Try to hide, you are chased by hitmans.");
			}
		}
	}
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason) {
	if(playerLive[playerid]) {
		playerLive[playerid] = 0, killTime[playerid] = GetTickCount();
		if(killerid != INVALID_PLAYER_ID) {
			if(gInfo[pInfo[killerid][pMember]][gWar] == gInfo[pInfo[playerid][pMember]][gWar] && gInfo[pInfo[killerid][pMember]][gWar] != 0 && pInfo[playerid][pMember] != pInfo[killerid][pMember]) {
				new t = gInfo[pInfo[killerid][pMember]][gWar], m = pInfo[killerid][pMember];
				if(getPlayerTurf(killerid) == t) {
					new Float:health;
					GetPlayerHealth(killerid, health);
					gInfo[m][gScore] ++, pInfo[killerid][pWarKills] ++;
					pInfo[playerid][pWarDeaths] ++;

					new Float:px, Float:py, Float:pz;
					GetPlayerPos(killerid, px, py, pz);
					SCMEx(killerid, COLOR_LIGHT, "War: You have killed %s (%d) from %0.2f meters with %0.2f HP.", GetName(playerid), playerid,  GetPlayerDistanceFromPoint(playerid, px, py, pz), health);
					SCMEx(playerid, COLOR_LIGHT, "War: You have been killed by %s (%d) from %0.2f meters with %0.2f HP.", GetName(killerid), killerid,  GetPlayerDistanceFromPoint(playerid, px, py, pz), health);

					new pscore = pInfo[playerid][pWarKills] - pInfo[playerid][pWarDeaths], kscore = pInfo[killerid][pWarKills] - pInfo[killerid][pWarDeaths];
					if(pscore < wInfo[t][wAWorstScore]) { wInfo[t][wAWorstScore] = pscore, format(wInfo[t][wAWorstPlayer], MAX_PLAYER_NAME + 1, GetName(playerid)); }
					if(kscore > wInfo[t][wABestScore]) { wInfo[t][wABestScore] = kscore, format(wInfo[t][wABestPlayer], MAX_PLAYER_NAME + 1, GetName(killerid)); }

					foreach(new x : Player) {
						if(gInfo[pInfo[x][pMember]][gWar] == gInfo[pInfo[killerid][pMember]][gWar]) {
						 SendDeathMessageToPlayer(x, killerid, playerid, reason);
						}
					}
				}

			}
		}
	}
	SetPlayerHealth(playerid, 1.00);
	return 1;
}

public OnVehicleSpawn(vehicleid) {
	if(vehID[vehicleid] > 0) {
		new lights, alarm, bonnet, boot, objective;
		SetVehicleParamsEx(vehicleid, 0, lights, alarm, pcInfo[vehID[vehicleid]][pcLockStatus], bonnet, boot, objective);
		
		ChangeVehicleColor(vehicleid, pcInfo[vehID[vehicleid]][pcColor1], pcInfo[vehID[vehicleid]][pcColor2]);
		ModVehicle(vehicleid);
	}
	else if(svrVeh[vehicleid] > 0) {
		ChangeVehicleColor(vehicleid, vInfo[svrVeh[vehicleid]][vColor1], vInfo[svrVeh[vehicleid]][vColor2]);
	}
	return 1;
}

public OnVehicleDeath(vehicleid, killerid) {
	if(spawnedVehicle[vehicleid] == true) { spawnedVehicle[vehicleid] = false, DestroyVehicle(vehicleid); }
	if(vehID[vehicleid] > 0 && pcInfo[vehID[vehicleid]][pcInsurance] > 0) {
		pcInfo[vehID[vehicleid]][pcInsurance] --;
	}
	return 1;
}

public OnPlayerText(playerid, text[]) {
	if((GetSVarInt("livePlayer") == playerid || GetSVarInt("liveReporter") == playerid) && GetSVarInt("liveOn") == 1) {
		if(GetSVarInt("livePlayer") == playerid) { format(gMsg, 128, "Player %s: %s", GetName(playerid), text); }
		else if(GetSVarInt("liveReporter") == playerid) { format(gMsg, 128, "NR %s: %s", GetName(playerid), text); }
		SendClientMessageToAll(COLOR_LIVE, gMsg);
	}
	else {
		format(gMsg, 128, "%s: %s", GetName(playerid), text);
		nearByMessage(playerid, COLOR_WHITE, gMsg, 10.0);
		SetPlayerChatBubble(playerid, text, COLOR_GREY, 10.0, 8000);
	}
	return 0;
}

public OnPlayerCommandPerformed(playerid, cmdtext[], success) {
	if (success) return 1;
	if(!success) {
		new string[30];
		if(strlen(cmdtext) < 25) { format(string, 30, "%s", cmdtext); }
			else {
				strmid(string, cmdtext, 0, 25); 
				format(string, 30, "%s[..]", string);
			}

		return SCMEx(playerid, COLOR_LIGHT, "SERVER: This command ("SBLUE"%s"SYN") does not exist.", string); 
	}
	return 0;
}
// Locations
YCMD:addgps(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 6) return adminOnly(playerid, 6);
	new name[50], city[20];
	if(sscanf(params, "s[50]s[20]", name, city)) return Syntax(playerid, "/addgps [name] [city]");
	if(strlen(name) < 5 || strlen(name) > 50) return SCM(playerid, COLOR_GREY, "Please use a decent name. (5-30 characters).");
	if(strlen(city) < 5 || strlen(city) > 50) return SCM(playerid, COLOR_GREY, "Please use a decent City name. (2-20 characters).");
	new gpsId, query[256];
	gpsId = Iter_Free(gpsIter);

	Iter_Add(gpsIter, gpsId);
	GetPlayerPos(playerid, gpsInfo[gpsId][gpsX], gpsInfo[gpsId][gpsY], gpsInfo[gpsId][gpsZ]);

	format(gpsInfo[gpsId][gpsName], 50, name), format(gpsInfo[gpsId][gpsCity], 20, city);
	format(gpsInfo[gpsId][gpsAddedBy], MAX_PLAYER_NAME + 1, GetName(playerid));

	mysql_format(handle, query, 256, "INSERT INTO `gps` (`Name`, `gpsX`, `gpsY`, `gpsZ`, `addedBy`, `gpsCity`) VALUES ('%e', '%f', '%f', '%f',  '%e', '%e')", gpsInfo[gpsId][gpsName], gpsInfo[gpsId][gpsX], gpsInfo[gpsId][gpsY], gpsInfo[gpsId][gpsZ], gpsInfo[gpsId][gpsAddedBy], gpsInfo[gpsId][gpsCity]);
	mysql_tquery(handle, query, "", "");  	
	sendAdmins(0xFF9100FF, "GPS: Admin %s added a new location on server: (#%d) %s, city - %s.", gpsInfo[gpsId][gpsAddedBy], gpsId, gpsInfo[gpsId][gpsName], gpsInfo[gpsId][gpsCity]);
	return 1;
}

YCMD:gps(playerid, params[], help) {
	new string[4][328], gid, Float:distance;
	format(string[0], 40, "Location\tCity\tDistance\n");
	foreach(new x : gpsIter) {
		gpsSelected[playerid][gid] = x, gid++;
		distance = GetPlayerDistanceFromPoint(playerid, gpsInfo[x][gpsX], gpsInfo[x][gpsY], gpsInfo[x][gpsZ]);
		format(string[1], 328, "%s%s\t%s\t%0.2f\n", string[1], gpsInfo[x][gpsName], gpsInfo[x][gpsCity], distance);
	}

	if(pInfo[playerid][pAdmin] > 5) { format(string[2], 328, "%s%s\n"SHOPC"[+] Add a new location", string[0], string[1]); }
		else format(string[2], 328, "%s%s", string[0], string[1]);
	
	ShowPlayerDialog(playerid, DIALOG_GPS, DIALOG_STYLE_TABLIST_HEADERS, "SERVER: Locations", string[2], "Select", "Cancel");
	return 1;
}

//dealership commands:

YCMD:adddealer(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 6) return adminOnly(playerid, 6);
	new model, price, pprice, type;
	if(sscanf(params, "iii", model, price, pprice)) return Syntax(playerid, "/adddealer [model] [price] [premium price]"), SCM(playerid, COLOR_GREY, "Price format: money price = 0$ and premium price = 1++pp for premium cars || premium price = 0pp and money price = 1+ for normal cars.");
	if(model < 400 || model > 611) return SCM(playerid, COLOR_GREY, "Valid car IDs start at 400, and end at 611.");
	
	if(price == 0 && pprice > 0) type = 2;
	else if(price > 0 && pprice == 0) type = 1;
	else return SCM(playerid, COLOR_GREY, "Error: Unknown price format.");
	new query[256];
	mysql_format(handle, query, 256, "INSERT INTO `dealervehicles` (`dealerModel`, `dealerPrice`, `dealerPremiumPrice`, `dealerStock`, `dealerType`) VALUES (%d, %d, %d, 10,  %d)", model, price, pprice, type), mysql_tquery(handle, query, "addDealer", "iiii", model, price, pprice, type);
	sendAdmins(0xFF9100FF, "Dealership: Admin %s added a %s in dealership, type: %s.", GetName(playerid), vehName[model - 400], (price == 0) ? ("premium car.") : ("normal car."));
  	return 1;
}

YCMD:vehicles(playerid, params[], help) {
	if(personalCount(playerid) == 0) return SCM(playerid, COLOR_GREY, "You don`t have a personal vehicle.");
	showPlayerCars(playerid);
  	return 1;
}

YCMD:park(playerid, params[], help) {
	if(pcInfo[vehID[GetPlayerVehicleID(playerid)]][pcOwner] != pInfo[playerid][pSQLID]) return SCMEx(playerid, -1, "You are not in your personal vehicle.");
	new Float:vHealth, engine, lights, alarm, doors, bonnet, objective, boot;
	GetVehicleParamsEx(GetPlayerVehicleID(playerid), engine, lights, alarm, doors, bonnet, boot, objective), GetVehicleHealth(GetPlayerVehicleID(playerid), Float:vHealth);
	if(vHealth < 500.0 || engine == 1) return SCMEx(playerid, COLOR_GREY, "You have to take the engine off or car needs to be repaired.");
	new car = GetPlayerVehicleID(playerid), x = vehID[car];
	GetVehiclePos(car, pcInfo[vehID[car]][pcPosX], pcInfo[vehID[car]][pcPosY], pcInfo[vehID[car]][pcPosZ]), GetVehicleZAngle(car, pcInfo[vehID[car]][pcPosA]);
	DestroyVehicle(car), vehID[car] = 0;
	new veh = CreateVehicle(pcInfo[x][pcModel], pcInfo[x][pcPosX], pcInfo[x][pcPosY], pcInfo[x][pcPosZ], pcInfo[x][pcPosA], pcInfo[x][pcColor1], pcInfo[x][pcColor2], -1);
	vehID[veh] = x, pcInfo[x][pcSpawned] = 1, pcInfo[x][pcTimeToSpawn] = 60 * 15;
	SCMEx(playerid, -1, ""NON"You succesfully parked your %s here.", vehName[GetVehicleModel(car) - 400]);
	ModVehicle(veh);

	SetVehicleParamsEx(veh, engine, lights, alarm, pcInfo[vehID[veh]][pcLockStatus], bonnet, boot, objective); 
	return 1;
}

YCMD:lock(playerid, params[], help) {
	new car = GetClosestVehicle(playerid);
	new Float:x, Float:y, Float:z;
	GetVehiclePos(car, x, y, z);
	if(!IsPlayerInRangeOfPoint(playerid, 5.0, x, y, z)) return SCM(playerid, -1, "You need to be near by your vehicle.");
	if(pcInfo[vehID[car]][pcOwner] != pInfo[playerid][pSQLID]) return SCM(playerid, COLOR_GREY, "You don`t have keys of this car.");
	new engine, lights, alarm, bonnet, objective, boot, doors;
	GetVehicleParamsEx(car, engine, lights, alarm, doors, bonnet, boot, objective);
	switch(pcInfo[vehID[car]][pcLockStatus]) {
		case 0: {
			SetVehicleParamsEx(car, engine, lights, alarm, 1, bonnet, boot, objective);
			pcInfo[vehID[car]][pcLockStatus] = 1;
			format(gMsg, 30, "%s ~n~~r~locked", vehName[GetVehicleModel(car) - 400]);
			GameTextForPlayer(playerid, gMsg, 5000, 3);
		}
		case 1: {
			SetVehicleParamsEx(car, engine, lights, alarm, 0, bonnet, boot, objective);
			pcInfo[vehID[car]][pcLockStatus] = 0;
    		format(gMsg, 30, "%s ~n~~g~unlocked", vehName[GetVehicleModel(car)  - 400]);
			GameTextForPlayer(playerid, gMsg, 5000, 3);
		}
	}
	return 1;
}

YCMD:carplate(playerid, params[], help) {
	if(pcInfo[vehID[GetPlayerVehicleID(playerid)]][pcOwner] != pInfo[playerid][pSQLID]) return SCMEx(playerid, -1, "You are not in your personal vehicle.");
	new text[10];
	if(sscanf(params, "s[10]", text)) return Syntax(playerid, "/carplate [text]"), SCM(playerid, COLOR_GREY, "Hint: "WHITE"The text lengh must be between 1 and 10 characters.");
	new car = GetPlayerVehicleID(playerid);
	format(pcInfo[vehID[car]][pcCarPlate], 10, text);
	SetVehicleNumberPlate(car, text);
	SCMEx(playerid, -1, ""NON"You succesfully change vehicle plate to '%s'. Changes will be made after the car will be respawned.", text);
	return 1;
}

YCMD:carcolor(playerid, params[], help) {
	if(pcInfo[vehID[GetPlayerVehicleID(playerid)]][pcOwner] != pInfo[playerid][pSQLID]) return SCMEx(playerid, -1, "You are not in your personal vehicle.");
	new c1, c2;
	if(sscanf(params, "ii", c1, c2)) return SCM(playerid, COLOR_LIGHT, "Syntax: "WHITE"/carcolor [color 1] [color 2]"); 
	new i = GetPlayerVehicleID(playerid);
	if((c1 < 0 || c1 > 256) || (c2 < 0 || c2 > 256)) return SCM(playerid, COLOR_LIGHT, "Syntax: "WHITE"/carcolor [0 - 256] [0 - 256]"); 
		
	pcInfo[vehID[i]][pcColor1] = c1, pcInfo[vehID[i]][pcColor2] = c2;
	ChangeVehicleColor(i, c1, c2);
	SCMEx(playerid, -1, ""NON"You succesfully changed vehicle colors to %d and %d.", c1, c2);
	return 1;
}

YCMD:sellcarto(playerid, params[], help) {
	if(pcInfo[vehID[GetPlayerVehicleID(playerid)]][pcOwner] != pInfo[playerid][pSQLID]) return SCMEx(playerid, -1, "You are not in your personal vehicle.");
	new player, price, car = GetPlayerVehicleID(playerid), itID = vehID[car];
	if(sscanf(params, "ui", player, price)) return Syntax(playerid, "/sellcarto [playerid] [price]");
	if(player == playerid) return SCM(playerid, -1, "You can not sell a car to yourself.");
	if(player == INVALID_PLAYER_ID) return SCM(playerid, COLOR_GREY, "Error: Unknown playerid/name.");
	if(GetPVarInt(playerid, "sellingCarTo") != -1) return SCM(playerid, -1, "You have already submitted an offer.");
	if(!IsPlayerInRangeOfPlayer(playerid, player, 5.0)) return SCM(playerid, -1, "You need to be near by your client.");
	if(price < 1 || price > (2 * getDealerPrice(GetVehicleModel(GetPlayerVehicleID(playerid))))) return SCMEx(playerid, -1, "The price must be higher than $1 and lower than $%s.", FormatNumber(2 * getDealerPrice(GetVehicleModel(car))));
	if(pInfo[player][pLevel] < 3) return SCM(playerid, -1, "Player don't have level 3.");
	if(personalCount(playerid) >= pInfo[player][pMaxSlots]) return SCMEx(playerid, COLOR_RED, "Player reached the maximum number of vehicles which he can have (%d/%d).", personalCount(playerid), pInfo[player][pMaxSlots]);
	if(pInfo[player][pMoney] < price) return SCM(playerid, -1, "Player don't have enough money.");
	
	SetPVarInt(playerid, "sellingCarTo", player);
	SetPVarInt(playerid, "sellingCarPrice", price);
	SetPVarInt(player, "sellingCarID", playerid);
	format(szMsg, 370, ""SYN"Are you shure that you want to sell your "RED"%s "SYN"(age: %d days, odometer: %d kilometers, colors: %d, %d) to %s for "GREEN"$%s"SYN"?\n\nYou are not allowed to cheat other players! If your are caught cheating a player you can be banned, from one day up to "DRED"permanent"SYN".\nBe an honest player and enjoy the game!", 
	vehName[GetVehicleModel(car) - 400], daysAgo(pcInfo[itID][pcAge]), pcInfo[itID][pcOdometer], pcInfo[itID][pcColor2], pcInfo[itID][pcColor2], GetName(player), FormatNumber(price));
	ShowPlayerDialog(playerid, DIALOG_VEHICLES_SELL, DIALOG_STYLE_MSGBOX, "SERVER: Sell vehicle", szMsg, "Sell", "Cancel");
  	return 1;
}

YCMD:sellcar(playerid, params[], help) {
	if(!IsPlayerInRangeOfPoint(playerid, 5.0, 2131.6790,-1150.6421,24.1334)) return SCM(playerid, -1, "You are not at Dealership.");
	new car = GetPlayerVehicleID(playerid);
	if(pcInfo[vehID[car]][pcOwner] != pInfo[playerid][pSQLID]) return SCMEx(playerid, -1, "You are not in your personal vehicle.");
	
	format(szMsg, 158, ""GREEN"** Selling your car to Dealership\n\n"SYN"Are you shure that you want to sell your vehicle?\nYou will receive %s$ (75%% from standard price).", FormatNumber((getDealerPrice(GetVehicleModel(car)) * 75) / 100));
	ShowPlayerDialog(playerid, DIALOG_VEHICLES_SELLDS, DIALOG_STYLE_MSGBOX, "SERVER: Sell vehicle", szMsg, "Sell", "Cancel");
  	return 1;
}

YCMD:buycar(playerid, params[], help) {
	if(pInfo[playerid][pLevel] < 3) return SCM(playerid, -1, ""GREY"You need to have level "ORANGE"3+"GREY" to buy a car.");
	if(!IsPlayerInRangeOfPoint(playerid, 5.0, 2131.6790,-1150.6421,24.1334)) return SCM(playerid, -1, "You are not at Dealership.");
	format(szMsg, 50, "~g~%s", vehName[dInfo[Iter_First(dealerVehicles)][dModel] - 400]), PlayerTextDrawSetString(playerid, dsTextdraw[playerid][12], szMsg);
	if(dInfo[Iter_First(dealerVehicles)][dPrice] > 0) { format(szMsg, 50, "~y~Price: ~w~%s", FormatNumber(dInfo[Iter_First(dealerVehicles)][dPrice])), PlayerTextDrawSetString(playerid, dsTextdraw[playerid][13], szMsg); }
	else  { format(szMsg, 50, "~y~Price: ~w~%spp", FormatNumber(dInfo[Iter_First(dealerVehicles)][dPremiumPrice])), PlayerTextDrawSetString(playerid, dsTextdraw[playerid][13], szMsg); }
	format(szMsg, 50, "~y~Stock: ~w~%d cars", FormatNumber(dInfo[Iter_First(dealerVehicles)][dStock])), PlayerTextDrawSetString(playerid, dsTextdraw[playerid][14], szMsg);
	PlayerTextDrawSetPreviewModel(playerid, dsTextdraw[playerid][15], dInfo[Iter_First(dealerVehicles)][dModel]);
	for(new td; td < 16; td++) { PlayerTextDrawShow(playerid, dsTextdraw[playerid][td]); }
	SelectTextDraw(playerid, 0xFFFF00AA); 
	SetPlayerPos(playerid, -1664.7733,1228.5585,21.1563), SetPlayerCameraPos(playerid, -1661.796142, 1221.463745, 22.785600), SetPlayerCameraLookAt(playerid, -1661.581176, 1216.666503, 21.392564);
	
	SetPlayerVirtualWorld(playerid, playerid + 1), SetPlayerInterior(playerid, 0);
	dsCar[playerid] = CreateVehicle(dInfo[Iter_First(dealerVehicles)][dModel], -1663.7202,1209.1276,20.8840,316.3510, 1, 1, -1);
	SetVehicleVirtualWorld(dsCar[playerid], playerid + 1);
	dsLastCam[playerid] = 1, dsLastID[playerid] = Iter_First(dealerVehicles), buyCarSession[playerid] = 1;
  	return 1;
}

//job commands:

YCMD:sellmats(playerid, params[], help) {
	new para3;
	if(sscanf(params, "udd", para, para3, para2)) return Syntax(playerid, "/sellmats [playerid] [amount] [price]"); {
		if(jInfo[pInfo[playerid][pJob]][jType] == 2) {
			if(IsPlayerConnected(para)) {
				if(pInfo[playerid][pMaterials] < para3) return SCM(playerid, COLOR_GREY, "You don't have enough materials.");
				if(para == playerid) return SCM(playerid, COLOR_GREY, "You cannot sell materials to you.");
				smMats[para] = para3;
				smPrice[para] = para2;
				smID[para] = playerid;
				smSwitch[para] = 1;
				SCMEx(para, COLOR_TEAL, "%s want to give you %s materials for $%s. Type /accept materials to accept it.", GetName(playerid), FormatNumber(para3), FormatNumber(para2));
			}
			else SCM(playerid, COLOR_GREY, "This player is not connected.");
		}
		else SCM(playerid, COLOR_GREY, "You cannot use this command because you don't have "SBLUE"Arms Dealer Job"WHITE".");
	}
	return 1;
}

YCMD:selldrugs(playerid, params[], help) {
	new para3;
	if(sscanf(params, "udd", para, para3, para2)) return Syntax(playerid, "/selldrugs [playerid] [amount] [price]"); {
		if(jInfo[pInfo[playerid][pJob]][jType] == 3) {
			if(IsPlayerConnected(para)) {
				if(pInfo[playerid][pDrugs] < para3) return SCM(playerid, COLOR_GREY, "You don't have enough drugs.");
				if(para == playerid) return SCM(playerid, COLOR_GREY, "You cannot sell materials to you.");
				sdDrugs[para] = para3;
				sdPrice[para] = para2;
				sdID[para] = playerid;
				sdSwitch[para] = 1;
				SCMEx(para, COLOR_TEAL, "%s want to give you %s drugs for $%s. Type /accept materials to accept it.", GetName(playerid), FormatNumber(para3), FormatNumber(para2));
			}
			else SCM(playerid, COLOR_GREY, "This player is not connected.");
		}
		else SCM(playerid, COLOR_GREY, "You cannot use this command because you don't have "SBLUE"Drugs Dealer Job"WHITE".");
	}
	return 1;
}

YCMD:creategun(playerid, params[], help) {
	if(sscanf(params, "us[25]d", para, strPara, para2)) return Syntax(playerid, "/creategun [playerid] [gun name] [price]"), SCM(playerid, COLOR_WHITE, "Gun: m4(200 materials), deagle(150 materials), rifle(350 materials), ak47(250 materials), mp5(200 materials)"); {
		if(jInfo[pInfo[playerid][pJob]][jType] == 2) {
			if(IsPlayerConnected(para)) {
				switch(YHash(strPara)) {
					case _H<m4>: {
						if(pInfo[playerid][pMaterials] >= 200) {
							if(pInfo[para][pGunLic] >= 1) {
								cgWeapon[para] = 31;
								cgSwitch[para] = 1;
								cgID[para] = playerid;
								cgMats[para] = 200;
								cgPrice[para] = para2;
								SCMEx(para, COLOR_TEAL, "%s has created a M4 for you, type /accept gun to accept it. Will cost you $%s.", GetName(playerid), FormatNumber(para2));
							}
							else SCM(playerid, COLOR_GREY, "This player doesn't have gun licence.");
						}
						else SCM(playerid, COLOR_GREY, "You don't have 200 materials to create a M4.");
					}
				}
			}
			else SCM(playerid, COLOR_GREY, "This player is not connected.");
		}
		else SCM(playerid, COLOR_GREY, "You cannot use this command because you don't have "SBLUE"Arms Dealer Job"WHITE".");
	}
	
	return 1;
}

//drugs:
YCMD:getdrugs(playerid, params[], help) {
	if(jInfo[pInfo[playerid][pJob]][jType] == 3) {
		if(IsPlayerInRangeOfPoint(playerid, 5.0, 316.8903, 1118.0417, 1083.8828)) {
			if(sscanf(params, "d", para)) return Syntax(playerid, "/getdrugs [amount]");
			if(1 <= para <= 100) return SCM(playerid, COLOR_GREY, "You can get between 1 and 100 drugs.");
			if((pInfo[playerid][pDrugs] + para) > 100) return SCM(playerid, COLOR_GREY, "You can't carry more than 100 drugs on you.");
			SCMEx(playerid, COLOR_SBLUE, "Job info: "WHITE"You have received %d drugs in return of $%s.", para, FormatNumber(para*500));
			pInfo[playerid][pDrugs] += para;
			takePlayerMoney(playerid, para*500);
		} 
		else SCM(playerid, COLOR_GREY, "You are not in right place, follow the checkpoint and try again."), SetPlayerCheckpoint(playerid, 2166.0415, -1671.0844, 15.0732, 4.0), Checkpoint[playerid] = 3;
	}

	return 1;
}

YCMD:wars(playerid, params[], help) {
	if(Iter_Count(Wars)) {
		SCM(playerid, COLOR_TEAL, "------------------------------ Wars ------------------------------");
		new counting;
		foreach(new x : Wars) {
			counting++;
			SCMEx(playerid, -1, "#%d. %s attacked turf %d owned by %s - time: %s.", counting, gInfo[wInfo[x][wAttacker]][gName], x, gInfo[wInfo[x][wDeffender]][gName], timeFormat(wInfo[x][wTime]));
		}
		SCM(playerid, COLOR_TEAL, "-----------------------------");
	}
	else SCM(playerid, -1, "There is no active war.");	
	return 1;
}

YCMD:getjob(playerid, params[], help) {
	if(IsPlayerInAnyVehicle(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this action on foot.");
	if(pInfo[playerid][pJob] > 0) return SCM(playerid, COLOR_GREY, "You already have a job, use /quitjob first.");
	for(new i; i < sizeof(jInfo); i++) {
		if(IsPlayerInRangeOfPoint(playerid, 3.0, jInfo[i][jX], jInfo[i][jY], jInfo[i][jZ])) {
			if(jInfo[i][jStatus] == 1) {
				pInfo[playerid][pJob] = i;
				SCMEx(playerid, -1, "{3594A1}Congratulation! Your job is now: %s.", jInfo[i][jName]);
			}
			else SCM(playerid, COLOR_SBLUE, "This job was dezactivated by a administrator.");
		}
	}
	return 1;
}

YCMD:work(playerid, params[], help) {
	if(IsPlayerInAnyVehicle(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this action on foot.");
	if(pInfo[playerid][pJob] == 0) return SCM(playerid, COLOR_GREY, "You can not use this command because you don`t have a job.");
	new i = pInfo[playerid][pJob];
	new jtype = jInfo[i][jType];

	if(jtype != 1) {
		if(IsPlayerInRangeOfPoint(playerid, 3.0, jInfo[i][jX], jInfo[i][jY], jInfo[i][jZ])) {
			if(jInfo[i][jStatus] == 1) {
				if(jInfo[pInfo[playerid][pJob]][jType] == 2) {

					if(Checkpoint[playerid] > 0) return SCM(playerid, COLOR_GREY, "You have a checkpoint active, use /killcp to disable it.");
					SetPlayerCheckpoint(playerid, 2771.7961,-1625.9692,10.9272, 4.0);
					SCM(playerid, COLOR_SBLUE, "Job info: "WHITE"The car was loaded with guns, you need to deliver them and get your materials.");
					SCM(playerid, COLOR_SBLUE, "Job info: "WHITE"You are not allowed to get out of the car or to destroy it.");
					new spawn = random(sizeof(randomArms));
					new vehicleidz = CreateVehicle(482, randomArms[spawn][0], randomArms[spawn][1], randomArms[spawn][2], randomArms[spawn][3], -1, -1, -1);
					PutPlayerInVehicle(playerid, vehicleidz, 0);
					jobVehicle[playerid] = vehicleidz, Checkpoint[playerid] = 2;
					new lights, engine, alarm, doors, bonnet, boot, objective;
					GetVehicleParamsEx(vehicleidz, engine, lights, alarm, doors, bonnet, boot, objective);
					SetVehicleParamsEx(vehicleidz, VEHICLE_PARAMS_ON, lights, alarm, VEHICLE_PARAMS_OFF, bonnet, boot, objective);
					armsObject[playerid][0] = CreatePlayerObject(playerid, 1271, 2770.10, -1627.74, 11.51, 0.00, 0.00, 0.00);
					armsObject[playerid][1] = CreatePlayerObject(playerid, 1271, 2770.91, -1628.07, 11.51, 0.00, 0.00, 0.00);
					armsObject[playerid][2] = CreatePlayerObject(playerid, 2358, 2770.42, -1627.81, 11.99, 0.19, -0.79, -20.60);

					AttachPlayerObjectToVehicle(playerid, armsObject[playerid][0], jobVehicle[playerid], 0.019999, -1.200000, 0.000000, 0.000000, 0.000000, 0.000000);
					AttachPlayerObjectToVehicle(playerid, armsObject[playerid][1], jobVehicle[playerid], 0.000000, -2.000000, 0.000000, 0.000000, 0.000000, 0.000000);
					AttachPlayerObjectToVehicle(playerid, armsObject[playerid][2], jobVehicle[playerid], -0.600000, -1.419999, -0.019999, 0.000000, 0.000000, 90.000000 );
				}
			}
			else SCM(playerid, COLOR_SBLUE, "This job was dezactivated by an administrator.");
		}
		else {
			SetPlayerCheckpoint(playerid, jInfo[i][jX], jInfo[i][jY], jInfo[i][jZ], 0.75), Checkpoint[playerid] = 4;
			SCM(playerid, COLOR_GREY, "You are not in right place, follow the checkpoint and try again.");
		}
	}
	else { 
		SCM(playerid, -1, "You can not use this command now.");
	}
	return 1;
}

YCMD:quitjob(playerid, params[], help) {
	if(IsPlayerInAnyVehicle(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this action on foot.");
	if(pInfo[playerid][pJob] == 0) return SCM(playerid, COLOR_GREY, "You don't have a job.");
	if(Checkpoint[playerid] > 0) return SCM(playerid, COLOR_GREY, "You have a checkpoint active, use /killcp to disable it.");
	DisablePlayerCheckpoint(playerid);
	DisablePlayerRaceCheckpoint(playerid);
	Checkpoint[playerid] = 0;	
	pInfo[playerid][pJob] = 0;
	SCM(playerid, COLOR_WHITE, "You have used /quitjob and you have quited your job.");
	return 1;
}

YCMD:killcp(playerid, params[], help) {
	if(Checkpoint[playerid] == 0) return SCM(playerid, COLOR_GREY, "You don't have any checkpoint active.");
	else if(Checkpoint[playerid] == 2) {
		DestroyVehicle(jobVehicle[playerid]);
		jobVehicle[playerid] = INVALID_VEHICLE_ID;
		
		DestroyPlayerObject(playerid, armsObject[playerid][0]), DestroyPlayerObject(playerid, armsObject[playerid][1]), DestroyPlayerObject(playerid, armsObject[playerid][2]);
	}

	DisablePlayerCheckpoint(playerid), DisablePlayerRaceCheckpoint(playerid);
	Checkpoint[playerid] = 0;
	SCM(playerid, COLOR_WHITE, "You have disabled your checkpoint.");
	return 1;
}

YCMD:serverstats(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] == 0) return adminOnly(playerid, 1);
	format(gMsg, 128, ""ORANGE"---------------------------------- Server statst ----------------------------------\n"SYN"Server tickrates: %d", GetServerTickRate());
	ShowPlayerDialog(playerid, DIALOG_GENERAL, DIALOG_STYLE_MSGBOX, "SERVER: Server stats", gMsg, "Hide", "");
	return 1;
}

YCMD:freeze(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 1) return adminOnly(playerid, 1);
	if(sscanf(params, "u", para)) return Syntax(playerid, "/freeze [playerid]");
	if(!IsPlayerConnected(para)) return SCM(playerid, COLOR_WHITE, "The player is not connected.");
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "This player is already freezed.");
	TogglePlayerControllable(para, 0);
	Freeze[para] = true;
	sendAdmins(COLOR_RED, "AdmCmd: "WHITE"Admin %s used /freeze on %s (%d).", GetName(playerid), GetName(para), para);
	return 1;
}

YCMD:unfreeze(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 1) return adminOnly(playerid, 1);
	if(sscanf(params, "u", para)) return Syntax(playerid, "/unfreeze [playerid]");
	if(!IsPlayerConnected(para)) return SCM(playerid, COLOR_WHITE, "The player is not connected.");
	TogglePlayerControllable(para, 1);
	Freeze[para] = false;
	sendAdmins(COLOR_RED, "AdmCmd: "WHITE"Admin %s used /unfreeze on %s (%d).", GetName(playerid), GetName(para), para);
	return 1;
}

YCMD:gotods(playerid, params[], help) {
    if(pInfo[playerid][pAdmin] == 0) return adminOnly(playerid, 1);
	if(GetPlayerState(playerid) == 2) {
		new tmpcar = GetPlayerVehicleID(playerid);
		SetVehiclePos(tmpcar, 2121.6821,-1133.3068,24.9394), LinkVehicleToInterior(tmpcar, 0), SetVehicleVirtualWorld(tmpcar, 0);
	}
	else SetPlayerPos(playerid, 2131.6790,-1150.6421,24.1334), SetPlayerInterior(playerid, 0), SetPlayerVirtualWorld(playerid, 0);
	SCM(playerid, -1, "You have been teleported");
	return 1;
}

YCMD:gotojob(playerid, params[], help)
{
	if(pInfo[playerid][pAdmin] == 0) return adminOnly(playerid, 1);
	if(sscanf(params, "d", para)) return Syntax(playerid, "/gotojob [jobid]");
	if(para == 0 || para > MAX_JOBS) return SCM(playerid, COLOR_GREY, "This job id is invalid.");
	
	SetPlayerPos(playerid, jInfo[para][jX], jInfo[para][jY], jInfo[para][jZ]), SetPlayerVirtualWorld(playerid, 0), SetPlayerInterior(playerid, 0);
	if(IsPlayerInAnyVehicle(playerid)) { SetVehiclePos(GetPlayerVehicleID(playerid), jInfo[para][jX], jInfo[para][jY], jInfo[para][jZ]); }
	return 1;
}

YCMD:ah(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 1) return adminOnly(playerid, 1);
	SCM(playerid, COLOR_TEAL, "----------------------------- Admins Commands -----------------------------");
	SCM(playerid, -1, "Admin level 1: /a /gethere /gotohq /gotopoint /gotods /gotojob /cp /slap /spawn /acceptnamereq");
	SCM(playerid, -1, "Admin level 1: /fly /stopfly /vr /vehinfo /gotoveh /sveh");
	SCM(playerid, -1, "Admin level 2: /vmove /setvw /setint");
	SCM(playerid, -1, "Admin level 3: /setskin /setleader /groupveh /vmodel /vcolor");
	SCM(playerid, -1, "Admin level 4: /sethqint /sethqext /setgslots /setgtype /movesafe /movejob /agl /atl");
	SCM(playerid, -1, "Admin level 6: /bangpci /savedata /pset /addvehicle /setadmin /addgps");
	SCM(playerid, COLOR_TEAL, "---------------------------------------------------------------------------");
	return 1;
}

//factions:
YCMD:startlesson(playerid, params[], help)
{
	if(sscanf(params, "u", para)) return Syntax(playerid, "/startlesson [playerid]");
	if(gInfo[pInfo[playerid][pMember]][gType] != 5) return SCM(playerid, COLOR_GREY, "You are not in a School Instructors faction.");
	{
	    if(IsPlayerConnected(para))
	    {
	        if(para != INVALID_PLAYER_ID)
	        {
		        SCMEx(playerid, COLOR_WHITE, "* You've started %s's lesson.", GetName(para));
		        SCMEx(para, COLOR_WHITE, "* Instructor %s has started your lesson.", GetName(playerid));
		        TakingLesson[para] = 1;
			}
		}
	}
	return 1;
}

YCMD:givelicense(playerid, params[], help) {
	if(sscanf(params, "us[10]d", para, strPara, para2)) return Syntax(playerid, "/givelicense [playerid] [license] [price]"), SCM(playerid, COLOR_WHITE, "Licenses: fly, gun, boat.");
	if(!IsPlayerConnected(para)) return SCM(playerid, COLOR_GREY, "This player is not connected.");
	if(gInfo[pInfo[playerid][pMember]][gType] != 5) return SCM(playerid, COLOR_GREY, "You are not in a School Instructors faction.");
	if(pInfo[para][pMoney] < para2) return SCM(playerid, COLOR_GREY, "This player doesn't have enough money.");
	switch(YHash(strPara)) {
		case _H<fly>: {
			if(pInfo[para][pFlyLic] >= 11) return SCMEx(playerid, COLOR_GREY, "This player already have flying license for %d hours.", pInfo[para][pFlyLic]); 
			takePlayerMoney(para, para2), givePlayerMoney(playerid, para2);
			pInfo[para][pFlyLic] = 100;
			SCMEx(playerid, COLOR_NON, "You have received fly license from %s in return of $%s.", GetName(playerid), FormatNumber(para2));
			format(gMsg, 128, "%s have given fly license to %s in return of $%s.", GetName(playerid), GetName(para), FormatNumber(para2));
			sendGroup(pInfo[playerid][pMember], COLOR_NON, gMsg);
		}
		case _H<gun>: {
			if(pInfo[para][pGunLic] >= 11) return SCMEx(playerid, COLOR_GREY, "This player already have weapon license for %d hours.", pInfo[para][pGunLic]); 
			takePlayerMoney(para, para2), givePlayerMoney(playerid, para2);
			pInfo[para][pGunLic] = 100;
			SCMEx(playerid, COLOR_NON, "You have received weapon license from %s in return of $%s.", GetName(playerid), FormatNumber(para2));
			format(gMsg, 128, "%s have given weapon license to %s in return of $%s.", GetName(playerid), GetName(para), FormatNumber(para2));
			sendGroup(pInfo[playerid][pMember], COLOR_NON, gMsg);
		}
		case _H<boat>: {
			if(pInfo[para][pBoatLic] >= 11) return SCMEx(playerid, COLOR_GREY, "This player already have boat license for %d hours.", pInfo[para][pBoatLic]); 
			takePlayerMoney(para, para2), givePlayerMoney(playerid, para2);
			pInfo[para][pBoatLic] = 100;
			SCMEx(playerid, COLOR_NON, "You have received boat license from %s in return of $%s.", GetName(playerid), FormatNumber(para2));
			format(gMsg, 128, "%s have given boat license to %s in return of $%s.", GetName(playerid), GetName(para), FormatNumber(para2));
			sendGroup(pInfo[playerid][pMember], COLOR_NON, gMsg);
		}
	}
	return 1;
}

YCMD:showlicenses(playerid, params[], help) {
	if(sscanf(params, "u", para)) return Syntax(playerid, "/showlicenses [playerid]");
	if(!IsPlayerConnected(para)) return SCM(playerid, COLOR_GREY, "This player is not connected.");
	if(para == playerid) return SCM(playerid, -1, "Use /licenses to check your licenses.");

	SCMEx(playerid, COLOR_WHITE, "You have shown your licenses to %s.", GetName(para));
	SCM(para, COLOR_TEAL, "-------------------------");
	
	if(pInfo[playerid][pCarLic] == 0) gMsg = "not passed";
	else format(gMsg, 64, "passed(expire in %d hours)", pInfo[playerid][pCarLic]);
	SCMEx(para, COLOR_WHITE, "Driving license: %s", gMsg);
	if(pInfo[playerid][pGunLic] == 0) gMsg = "not passed";
	else format(gMsg, 64, "passed(expire in %d hours)", pInfo[playerid][pGunLic]);
	SCMEx(para, COLOR_WHITE, "Weapon license: %s", gMsg);
	if(pInfo[playerid][pFlyLic] == 0) gMsg = "not passed";
	else format(gMsg, 64, "passed(expire in %d hours)", pInfo[playerid][pFlyLic]);
	SCMEx(para, COLOR_WHITE, "Flying license: %s", gMsg);
	if(pInfo[playerid][pBoatLic] == 0) gMsg = "not passed";
	else format(gMsg, 64, "passed(expire in %d hours)", pInfo[playerid][pBoatLic]);
	SCMEx(para, COLOR_WHITE, "Boat license: %s", gMsg);
   	
	SCM(para, COLOR_TEAL, "-------------------------");
	return 1;
}

YCMD:licenses(playerid, params[], help) {
	SCM(playerid, COLOR_TEAL, "-------------------------");
	
	if(pInfo[playerid][pCarLic] == 0) gMsg = "not passed";
	else format(gMsg, 64, "passed(expire in %d hours)", pInfo[playerid][pCarLic]);
	SCMEx(playerid, COLOR_WHITE, "Driving license: %s", gMsg);
	if(pInfo[playerid][pGunLic] == 0) gMsg = "not passed";
	else format(gMsg, 64, "passed(expire in %d hours)", pInfo[playerid][pGunLic]);
	SCMEx(playerid, COLOR_WHITE, "Weapon license: %s", gMsg);
	if(pInfo[playerid][pFlyLic] == 0) gMsg = "not passed";
	else format(gMsg, 64, "passed(expire in %d hours)", pInfo[playerid][pFlyLic]);
	SCMEx(playerid, COLOR_WHITE, "Flying license: %s", gMsg);
	if(pInfo[playerid][pBoatLic] == 0) gMsg = "not passed";
	else format(gMsg, 64, "passed(expire in %d hours)", pInfo[playerid][pBoatLic]);
	SCMEx(playerid, COLOR_WHITE, "Boat license: %s", gMsg);
   	
	SCM(playerid, COLOR_TEAL, "-------------------------");
	return 1;
}

YCMD:gethere(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 1) return adminOnly(playerid, 1);
	if(sscanf(params, "u", para)) return Syntax(playerid, "/gethere [playerid]");
	if(!IsPlayerConnected(para)) return SCM(playerid, COLOR_WHITE, "The player is not connected.");
	new Float:X, FLoat:Y, Float:Z;
	GetPlayerPos(playerid, Float:X, Float:Y, Float:Z), SetPlayerPos(para, Float:X, Float:Y, Float:Z), SetPlayerInterior(para, GetPlayerInterior(playerid)), SetPlayerVirtualWorld(para, GetPlayerVirtualWorld(playerid));
	if(IsPlayerInAnyVehicle(para)) { SetVehicleVirtualWorld(GetPlayerVehicleID(para), GetPlayerVirtualWorld(para)), SetVehiclePos(GetPlayerVehicleID(para), Float:X, Float:Y, Float:Z); }
	SCMEx(para, COLOR_GREY, "You have been teleported by admin %s.", GetName(playerid));
	SCMEx(playerid, COLOR_GREY, "You have teleported %s to you.", GetName(para));
	playerHQ[para] = playerHQ[playerid];
	return 1;
}

YCMD:aduty(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 1) return adminOnly(playerid, 1);
	if(adminDuty[playerid] == true) {
		adminDuty[playerid] = false;
		ResetPlayerWeapons(playerid);
		sendAdmins(COLOR_NOTICE, "Notice: "WHITE"Admin %s is no longer in administrative duty.", GetName(playerid));
		SetPlayerColor(playerid, getFactionColor(pInfo[playerid][pMember]));
	}
	else if(adminDuty[playerid] == false) {//set player color
		GivePlayerWeapon(playerid, 38, 99999);
		adminDuty[playerid] = true;
		sendAdmins(COLOR_NOTICE, "Notice: "WHITE"Admin %s is now administrative duty.", GetName(playerid));
		SetPlayerColor(playerid, 0x89D900FF);
	}
	return 1;
}

YCMD:spawn(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 1) return adminOnly(playerid, 1);
	if(sscanf(params, "u", para)) return Syntax(playerid, "/spawn [playerid]");
	if(!IsPlayerConnected(para)) return SCM(playerid, COLOR_WHITE, "The player is not connected.");
	SpawnPlayer(para);
	sendAdmins(COLOR_RED, "AdmCmd: "WHITE"Admin %s respawned %s (%d).", GetName(playerid), GetName(para), para);
	SCMEx(para, -1, "You have been respawned by admin %s.", GetName(playerid));
	return 1;
}

YCMD:bangpci(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 6) return adminOnly(playerid, 6);
	if(sscanf(params, "us[30]", para, strPara)) return Syntax(playerid, "/bangpci [playerid] [reason]");
	if(!IsPlayerConnected(para)) return SCM(playerid, COLOR_WHITE, "The player is not connected.");
	new serial[41], query[200], pIP[20];
	gpci(playerid, serial, 41), GetPlayerIp(para, pIP, 20);
	sendAdmins(COLOR_RED, "Ban: Admin %s banned %s, reason: %s.", GetName(playerid), GetName(para), strPara);
	mysql_format(handle, query, 200, "INSERT INTO `bans` (`playerID`, `bannedBy`, `SerialCode`, `time`, `reason`, `ip`) VALUES ('%d', '%e', '%e', '%d', '%e', '%e')", pInfo[para][pSQLID], GetName(playerid), serial, gettime(), strPara, pIP);
	mysql_tquery(handle, query);
	defer kickTimer(para);
	return 1;
}

YCMD:savedata(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 6) return adminOnly(playerid, 6);
	
	new time;
	time = GetTickCount();
	foreach(new p : Player) { saveAccount(p); }
    for(new v; v < MAX_VEHICLES; v++) { if(vInfo[v][vID] > 0 ) { saveVeh(v); } }
	for(new i; i < MAX_GROUPS; i++) { saveGroup(i); }
	for(new i; i < MAX_JOBS; i++) { saveJob(i); }
	foreach(new x :  personalCars) { savePersonals(x); }
	// --------------------
	SCMEx(playerid, COLOR_YELLOW, "All server data saved in %d miliseconds.", GetTickCount() - time);
	return 1;
}

YCMD:jset(playerid, params[], help) {
	if(pInfo[playerid][pAdmin]  <= 5) return adminOnly(playerid, 6);
	if(sscanf(params, "ds[30]s[256]", para, strPara, largeStr)) return Syntax(playerid, "/jset [jobid] [item] [value]"), SCM(playerid, -1, "Items: status, name, type, pos");
	if(para == 0 || para > MAX_JOBS) return SCM(playerid, COLOR_GREY, "This job id is invalid.");
	switch(YHash(strPara)) {
		case _H<pos>: {
			sendAdmins(COLOR_NOTICE, "Notice: "WHITE"Admin %s changed job %s`s position, reason: %s.", GetName(playerid), jInfo[para][jName], largeStr);
			new Float:xX, Float:yY, Float:zZ;
			GetPlayerPos(playerid, xX, yY, zZ);

			jInfo[para][jX] = xX;
			jInfo[para][jY] = yY;
			jInfo[para][jZ] = zZ;

			DestroyDynamicPickup(jInfo[para][jPickup]);

			updateJobLabel(para, 2);
			
			jInfo[para][jPickup] = CreateDynamicPickup(1275, 1, xX, yY, zZ, -1, -1, -1, 30.0);
		}
		case _H<status>: {
			if(IsNumeric(largeStr)) { para2 = strval(largeStr); }
			sendAdmins(COLOR_NOTICE, "Notice: "WHITE"Admin %s changed job %s`s status to %d.", GetName(playerid), jInfo[para][jName], para2);
			jInfo[para][jStatus] = para2;
		}
		case _H<name>: {
			if(strlen(largeStr) >= 51) return SCM(playerid, COLOR_LIGHT, "Name is to large.");
			sendAdmins(COLOR_NOTICE, "Notice: "WHITE"Admin %s changed job %s`s name to %s.", GetName(playerid), jInfo[para][jName], largeStr);
			format(jInfo[para][jName], 256, largeStr);
		}
		case _H<type>: {
			if(IsNumeric(largeStr)) { para2 = strval(largeStr); }
			sendAdmins(COLOR_NOTICE, "Notice: "WHITE"Admin %s changed job %s`s type to %d.", GetName(playerid), jInfo[para][jName], para2);
			jInfo[para][jType] = para2;
		}
		default: { SCM(playerid, COLOR_GREY, "The item that you specified does not exist."); }
	}
	return 1;
}

YCMD:pset(playerid, params[], help) {
	if(pInfo[playerid][pAdmin]  < 6) return adminOnly(playerid, 6);
	if(sscanf(params, "us[30]i", para, strPara, para2)) return Syntax(playerid, "/pset [playerid] [item] [value]"), SCM(playerid, -1, "Items: Level, rank, group, money, bank (money), job, materials, drugs, loyalityaccount, loyalitypoints, vehslots");
	switch(YHash(strPara)) {
		case _H<level>: {
			sendAdmins(COLOR_NOTICE, "Notice: "WHITE"Admin %s changed %s`s level to %d.", GetName(playerid), GetName(para), para2);
			SCMEx(para, COLOR_LORANGE, "Admin %s changed your level to %d.", GetName(playerid), para2);
			pInfo[para][pLevel] = para2;
		}
		case _H<rank>: {
			if(para2 < 0 || para2 > 7) return Syntax(playerid, "/pset [playerid] [rank] [0-7]");
			sendAdmins(COLOR_NOTICE, "Notice: "WHITE"Admin %s changed %s`s rank to %d.", GetName(playerid), GetName(para), para2);
			SCMEx(para, COLOR_LORANGE, "Admin %s changed your rank to %d.", GetName(playerid), para2);
			pInfo[para][pRank] = para2, SetPlayerScore(para, para2);
		}
		case _H<group>: {
			if(gInfo[para2][gID] == 0 && para2 != 0) return SCM(playerid, COLOR_LIGHT, "Error: Invalid group id.");
			if(para2 != 0) {  
				sendAdmins(COLOR_NOTICE, "Notice: "WHITE"Admin %s changed %s`s group to %s (id: %d).", GetName(playerid), GetName(para), gInfo[para2][gName], para2);
				SCMEx(para, COLOR_LORANGE, "Admin %s changed your group to %s.", GetName(playerid), gInfo[para2][gName]);
				SetPlayerColor(para, getFactionColor(para));

				pInfo[para][pGJoinDate] = gettime();

				if(pInfo[para][pDuty] == 1) { 
					ResetPlayerWeapons(para), setArmour(para, 0.00), removeDutyObjects(para);
					pInfo[para][pDuty] = 0, pInfo[para][pLastDuty] = GetTickCount(); 
				}
			}
			else { 
				sendAdmins(COLOR_NOTICE, "Notice: "WHITE"Admin %s removed %s from his group.", GetName(playerid), GetName(para));
				SCMEx(para, COLOR_LORANGE, "Admin %s removed you from your group.", GetName(playerid));
				pInfo[para][pGJoinDate] = gettime();
			}
			pInfo[para][pMember] = para2, pInfo[para][pRank] = (para2 == 0) ? (0) : (1);
		}
		case _H<money>: {
			sendAdmins(COLOR_NOTICE, "Notice: "WHITE"Admin %s changed %s`s money to $%s.", GetName(playerid), GetName(para), FormatNumber(para2));
			SCMEx(para, COLOR_LORANGE, "Admin %s changed your money to $%s.", GetName(playerid), FormatNumber(para2));
			pInfo[para][pMoney] = para2;
		}
		case _H<bank>: {
			sendAdmins(COLOR_NOTICE, "Notice: "WHITE"Admin %s changed %s`s bank money to $%s.", GetName(playerid), GetName(para), FormatNumber(para2));
			SCMEx(para, COLOR_LORANGE, "Admin %s changed your bank money to $%s.", GetName(playerid), FormatNumber(para2));
			pInfo[para][pBank] = para2;
		}
		case _H<materials>: {
			sendAdmins(COLOR_NOTICE, "Notice: "WHITE"Admin %s changed %s`s materials to %s.", GetName(playerid), GetName(para), FormatNumber(para2));
			SCMEx(para, COLOR_LORANGE, "Admin %s changed your materials to %s.", GetName(playerid), FormatNumber(para2));
			pInfo[para][pMaterials] = para2;
		}
		case _H<drugs>: {
			sendAdmins(COLOR_NOTICE, "Notice: "WHITE"Admin %s changed %s`s drugs to %s.", GetName(playerid), GetName(para), FormatNumber(para2));
			SCMEx(para, COLOR_LORANGE, "Admin %s changed your drugs to %s.", GetName(playerid), FormatNumber(para2));
			pInfo[para][pDrugs] = para2;
		}
		case _H<job>: {
			sendAdmins(COLOR_NOTICE, "Notice: "WHITE"Admin %s changed %s`s job to %s.", GetName(playerid), GetName(para), FormatNumber(para2));
			SCMEx(para, COLOR_LORANGE, "Admin %s changed your job to %s.", GetName(playerid), FormatNumber(para2));
			pInfo[para][pJob] = para2;
		}
		case _H<loyalitypoints>: {
			sendAdmins(COLOR_NOTICE, "Notice: "WHITE"Admin %s changed %s`s loyality points to %d.", GetName(playerid), GetName(para), para2);
			SCMEx(para, COLOR_LORANGE, "Admin %s changed your Loyality points to %d.", GetName(playerid), para2);
			pInfo[para][pLoyalityPoints] = para2;
		}
		case _H<loyalityaccount>: {
			sendAdmins(COLOR_NOTICE, "Notice: "WHITE"Admin %s changed %s`s loyality account to %d.", GetName(playerid), GetName(para), para2);
			SCMEx(para, COLOR_LORANGE, "Admin %s changed your Loyality account to %d.", GetName(playerid), para2);
			pInfo[para][pLoyalityAccount] = para2;
		}
		case _H<vehslots>: {
			sendAdmins(COLOR_NOTICE, "Notice: "WHITE"Admin %s changed %s`s vehicle slots to %d.", GetName(playerid), GetName(para), para2);
			SCMEx(para, COLOR_LORANGE, "Admin %s changed your vehicle slots to %d.", GetName(playerid), para2);
			pInfo[para][pMaxSlots] = para2;
		}
		default: { SCM(playerid, COLOR_GREY, "The item that you specified does not exist."); }
	}
	return 1;
}

YCMD:setskin(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 3) return adminOnly(playerid, 3);
	if(sscanf(params, "ui", para, para2)) return Syntax(playerid, "/setskin [playerid] [skinid]");
	if(isLogged(para) == 0) return SCM(playerid, COLOR_GREY, "Error: Invalid player id.");
	SetPlayerSkin(para, para2), pInfo[para][pSkin] = para2;
	sendAdmins(COLOR_NOTICE, "Notice: "WHITE"Admin %s changed %s`s skin to %d.", GetName(playerid), GetName(para), para2);
	SCMEx(para, COLOR_LORANGE, "Admin %s changed your skin to %d.", GetName(playerid), para2);
	return 1;
}

YCMD:sethp(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 3) return adminOnly(playerid, 3);
	new Float:health;
	if(sscanf(params, "uf", para, health)) return Syntax(playerid, "/sethp [playerid] [health]");
	if(isLogged(para) == 0) return SCM(playerid, COLOR_GREY, "Error: Invalid player id.");
	setHealth(playerid, health);
	sendAdmins(COLOR_NOTICE, "Notice: "WHITE"Admin %s changed %s`s HP to %d.", GetName(playerid), GetName(para), health);
	SCMEx(para, COLOR_LORANGE, "Admin %s changed HP skin to %d.", GetName(playerid), health);
	return 1;
}

YCMD:setvw(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 2) return adminOnly(playerid, 2);
	if(sscanf(params, "ui", para, para2)) return Syntax(playerid, "/setvw [playerid] [virtualworld]");
	if(isLogged(para) == 0) return SCM(playerid, COLOR_GREY, "Error: Invalid player id.");
	SetPlayerVirtualWorld(para, para2), SCM(playerid, -1, "Action performed succesfully.");
	return 1;
}

YCMD:setint(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 2) return adminOnly(playerid, 2);
	if(sscanf(params, "ui", para, para2)) return Syntax(playerid, "/setint [playerid] [interior]");
	if(isLogged(para) == 0) return SCM(playerid, COLOR_GREY, "Error: Invalid player id.");
	SetPlayerInterior(para, para2), SCM(playerid, -1, "Action performed succesfully.");
	return 1;
}

YCMD:agl(playerid, params[], help) {
	if(pInfo[playerid][pAdmin]  < 4) return adminOnly(playerid, 4);
	if(sscanf(params, "us[30]i", para, strPara, para2)) return Syntax(playerid, "/agl [playerid] [license] [hours]"), SCM(playerid, -1, "Available licenses: driving, gun, flying, boat, pack - all in one");
	switch(YHash(strPara)) {
		case _H<driving>: {
			sendAdmins(COLOR_NOTICE, "Notice: "WHITE"%s`s driving license was set to %d hours by admin %s.", GetName(para), para2, GetName(playerid));
			SCMEx(para, -1, "Admin %s has gave you driving license.", GetName(playerid));
			pInfo[para][pCarLic] = para2;
		}
		case _H<gun>: {
			sendAdmins(COLOR_NOTICE, "Notice: "WHITE"%s`s gun license was set to %d hours by admin %s.", GetName(para), para2, GetName(playerid));
			SCMEx(para, -1, "Admin %s has gave you gun license.", GetName(playerid));
			pInfo[para][pGunLic] = para2;
		}
		case _H<flying>: {
			sendAdmins(COLOR_NOTICE, "Notice: "WHITE"%s`s flying license was set to %d hours by admin %s.", GetName(para), para2, GetName(playerid));
			SCMEx(para, -1, "Admin %s has gave you flying license.", GetName(playerid));
			pInfo[para][pFlyLic] = para2;
		}
		case _H<boat>: {
			sendAdmins(COLOR_NOTICE, "Notice: "WHITE"%s`s boat license was set to %d hours by admin %s.", GetName(para), para2, GetName(playerid));
			SCMEx(para, -1, "Admin %s has gave you boat license.", GetName(playerid));
			pInfo[para][pBoatLic] = para2;
		}
		case _H<pack>: {
			sendAdmins(COLOR_NOTICE, "Notice: "WHITE"%s`s licenses was set to %d hours by admin %s.", GetName(para), para2, GetName(playerid));
			SCMEx(para, -1, "Admin %s has gave you all licenses.", GetName(playerid));
			pInfo[para][pCarLic] = pInfo[para][pFlyLic] = pInfo[para][pBoatLic] = para2;
		}
		default: { SCM(playerid, COLOR_GREY, "The license that you specified does not exist."); }
	}
	return 1;
}

YCMD:atl(playerid, params[], help) {
	if(pInfo[playerid][pAdmin]  < 4) return adminOnly(playerid, 4);
	if(sscanf(params, "us[30]", para, strPara)) return Syntax(playerid, "/atl [playerid] [license]"), SCM(playerid, -1, "Available licenses: driving, gun, flying, boat");
	switch(YHash(strPara)) {
		case _H<driving>: {
			sendAdmins(COLOR_NOTICE, "Notice: "WHITE"Admin %s confiscated %s`s driving license.", GetName(playerid), GetName(para));
			SCMEx(para, -1, "Admin %s has confiscated your driving license.", GetName(playerid));
			pInfo[para][pCarLic] = 0;
		}
		case _H<gun>: {
			sendAdmins(COLOR_NOTICE, "Notice: "WHITE"Admin %s confiscated %s`s gun license.", GetName(playerid), GetName(para));
			SCMEx(para, -1, "Admin %s has confiscated your gun license.", GetName(playerid));
			pInfo[para][pGunLic] = 0;
		}
		case _H<flying>: {
			sendAdmins(COLOR_NOTICE, "Notice: "WHITE"Admin %s confiscated %s`s flying license.", GetName(playerid), GetName(para));
			SCMEx(para, -1, "Admin %s has confiscated your flying license.", GetName(playerid));
			pInfo[para][pFlyLic] = 0;
		}
		case _H<boat>: {
			sendAdmins(COLOR_NOTICE, "Notice: "WHITE"Admin %s confiscated %s`s boat license.", GetName(playerid), GetName(para));
			SCMEx(para, -1, "Admin %s has confiscated your boat license.", GetName(playerid));
			pInfo[para][pBoatLic] = 0;
		}
		default: { SCM(playerid, COLOR_GREY, "The license that you specified does not exist."); }
	}
	return 1;
}

YCMD:vr(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 1) return adminOnly(playerid, 1);
	new id = strval(params);
	if(IsPlayerInAnyVehicle(playerid) && id == 0) {
		SetVehicleToRespawn(GetPlayerVehicleID(playerid));
		SCMEx(playerid, -1, ""NON"You succesfull respawned vehicle #%d.", GetPlayerVehicleID(playerid));
	}
	else if(IsPlayerInAnyVehicle(playerid) == 0 && id != 0) {
		if(doesVehicleExist(id) == 0) return SCM(playerid, COLOR_GREY, "This vehicle doesn`t exist.");
		SetVehicleToRespawn(id);
		SCMEx(playerid, -1, ""NON"You succesfull respawned vehicle #%d.", id);
	}
	else Syntax(playerid, "/vr [vehicleid]");
	return 1;
}

YCMD:arepair(playerid, params[], help) {
	new range = strval(params);

	if(GetPlayerVehicleID(playerid) && !range) {
		RepairVehicle(GetPlayerVehicleID(playerid));
	}
	else if(GetPlayerVehicleID(playerid) && range) {
		 for(new i = 0, j = GetVehiclePoolSize(); i <= j; ++i) { RepairVehicle(i); }
	}
	else SendClientMessage(playerid, -1, "/arepair [range]");
	return 1;
}

YCMD:veh(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] == 0) return adminOnly(playerid, 1);
	if(strlen(params) < 3) return SCM(playerid, COLOR_GREY, "Enter more characters (minimum 3) or exact car id.");
	new count = 0, modelToSpawn = 0;
	for(new v; v < sizeof(vehName); v++) {
		if(strfind(vehName[v], params, true) != -1) {
			modelToSpawn = v+400;
			count++;
		}
	}

	if(count == 0 && (strval(params) >= 400 && strval(params) <= 611)) { modelToSpawn = strval(params); }
	else if(count == 0 && (strval(params) < 400 || strval(params) > 611)) return SCM(playerid, COLOR_GREY, "There is no car with this name."); 
	else if(count > 1) return SCM(playerid, -1, "There are more results, use /sveh to find your car.");

	new Float:x, Float:y, Float:z, Float:a;
	GetPlayerPos(playerid, x, y, z), GetPlayerFacingAngle(playerid, a);
	new vehicleidz = CreateVehicle(modelToSpawn,x, y, z, a, -1, -1, -1);
	PutPlayerInVehicle(playerid, vehicleidz, 0);
	spawnedVehicle[vehicleidz] = true;
	new lights, engine, alarm, doors, bonnet, boot, objective;
	GetVehicleParamsEx(vehicleidz, engine, lights, alarm, doors, bonnet, boot, objective);
	SetVehicleParamsEx(vehicleidz, VEHICLE_PARAMS_ON, lights, alarm, doors, bonnet, boot, objective);

	return 1;
}

YCMD:sveh(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] == 0) return adminOnly(playerid, 1);
	if(strlen(params) < 3) return SCM(playerid, COLOR_GREY, "Enter more characters, minimum 3.");
	new count, resultsMsg[256];
	format(resultsMsg, 256, ""NON"Results: ");
	for(new v; v < sizeof(vehName); v++) {
		if(strfind(vehName[v], params, true) != -1) {
			if(count == 0) format(resultsMsg, 256, "%s%s (m: %d)", resultsMsg, vehName[v], v+400);
			else format(resultsMsg, 256, "%s, %s (m: %d)", resultsMsg, vehName[v], v+400);
			count++;
		}
	}


	if(count == 0) { SCM(playerid, COLOR_GREY, "There is no car with this name."); }
	else {
		if(strlen(resultsMsg) > 120)  {
			new secondLine[128];
			
			strmid(secondLine, resultsMsg, 110, 256), strdel(resultsMsg, 110, 256);
			SCMEx(playerid, -1, "%s ...", resultsMsg), SCMEx(playerid, -1, "[...] %s", secondLine);
		}
		else SCM(playerid, -1, resultsMsg);
		SCMEx(playerid, COLOR_PURPLE, "Total results found for '%s': %d vehicles", params, count);
	}
	return 1;
}


YCMD:addvehicle(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 6) return adminOnly(playerid, 6);
	new str[284], Cache:cache_i;
	if(GetPVarInt(playerid, "AddVehicle") > 0) {
		new Float:x, Float:y, Float:z, Float:a;
		GetVehiclePos(GetPVarInt(playerid, "AddVehicle"), x, y, z), GetVehicleZAngle(GetPVarInt(playerid, "AddVehicle"), a);
		mysql_format(handle, str, 284, "INSERT INTO `cars` (`Model`, `Group`, `CarPlate`, `pX`, `pY`, `pZ`, `pA`, `Color1`, `Color2`) VALUES ('%d', '0', 'Null', '%f', '%f', '%f', '%f', '-1', '-1')", GetVehicleModel(GetPVarInt(playerid, "AddVehicle")), x, y, z, a);
		cache_i = mysql_query(handle, str);
		
		new id = cache_insert_id();
		GetVehiclePos(GetPVarInt(playerid, "AddVehicle"), x, y, z), GetVehicleZAngle(GetPVarInt(playerid, "AddVehicle"), a);
		vInfo[id][vID] = id;
		vInfo[id][vModel] = GetVehicleModel(GetPVarInt(playerid, "AddVehicle"));
		vInfo[id][vX] = x, vInfo[id][vY] = y, vInfo[id][vZ] = z, vInfo[id][vA] = a;
		vInfo[id][vGroup] = 0;
		vInfo[id][vColor1] = vInfo[id][vColor2] = random(126);
		format(vInfo[id][vCarPlate], 11, "Null");
		
		carCreatingSession[playerid] = true;
		new i = GetPVarInt(playerid, "AddVehicle");
		DeletePVar(playerid, "AddVehicle");
		svrVeh[i] = id;
		
		cache_delete(cache_i);
		format(str, 100, ""ORANGE"(+) Admin %s added a new vehicle on server.", GetName(playerid));
		sendAdmins(COLOR_WHITE, str);
	}
	else {
		if(IsPlayerInAnyVehicle(playerid)) return SCM(playerid, COLOR_GREY, "You can use this command because you are in a vehicle.");
		if(sscanf(params, "i", para)) return Syntax(playerid, "/addvehicle [model]"); 
		if(para < 400 || para > 612) return Syntax(playerid, "/addvehicle [400-612]"); 
		
		carCreatingSession[playerid] = false;
		new Float:x, Float:y, Float:z, Float:a;
		GetPlayerPos(playerid, x, y, z), GetPlayerFacingAngle(playerid, a);
		new vehicle = CreateVehicle(para,x, y, z, a, -1, -1, -1);
		PutPlayerInVehicle(playerid, vehicle, 0);
		SetPVarInt(playerid, "AddVehicle", vehicle);
	}
	return 1;
}

YCMD:vcolor(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 3) return adminOnly(playerid, 3);
	if(sscanf(params, "ii", para, para2)) return Syntax(playerid, "/vcolor [color 1] [color 2]"); 
	new i = GetPlayerVehicleID(playerid);
	if(i) { 
		if((para < 0 || para > 256) || (para2 < 0 || para2 > 256)) return Syntax(playerid, "/vcolor [color 1] [color 2]"); 
		vInfo[svrVeh[i]][vColor1] = para, vInfo[svrVeh[i]][vColor2] = para2;
		ChangeVehicleColor(i, para, para2);
		SCMEx(playerid, -1, "You succesfull changed vehicle colors to %d and %d (for vehicle #%d).", para, para2, i);
	}
	else SCM(playerid, -1, "You are not in a vehicle.");
	return 1;
}

YCMD:vmodel(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 3) return adminOnly(playerid, 3);
	if(sscanf(params, "i", para)) return Syntax(playerid, "/vmodel [model]"); 
	new i = GetPlayerVehicleID(playerid);
	if(i) { 
		vInfo[svrVeh[i]][vModel] = para, DestroyVehicle(i);
		i = CreateVehicle(vInfo[svrVeh[i]][vModel], vInfo[svrVeh[i]][vX], vInfo[svrVeh[i]][vY], vInfo[svrVeh[i]][vZ], vInfo[svrVeh[i]][vA], vInfo[svrVeh[i]][vColor1], vInfo[svrVeh[i]][vColor2], -1);
		PutPlayerInVehicle(playerid, i, 0);
		SCMEx(playerid, -1, "You succesfull moved this %s (id: %d)!", vehName[GetVehicleModel(i) - 400], i);
	}
	else SCM(playerid, -1, "You are not in a vehicle.");
	return 1;
}

YCMD:vgroup(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 3) return adminOnly(playerid, 3);
	new veh = GetPlayerVehicleID(playerid);
	if(veh) { 
		if(sscanf(params, "i", para)) return Syntax(playerid, "/vgroup [groupid]"); 
		if(para != 0 && gInfo[para][gID] == 0) return SCM(playerid, COLOR_GREY, "Error: Invalid group id.");
		vInfo[svrVeh[veh]][vGroup] = para;
		switch(para) {
			case 0: SCMEx(playerid, -1, "Now, this %s (id: %d) its civilian`s vehicle.", vehName[GetVehicleModel(veh) - 400], veh);
			default: SCMEx(playerid, -1, "Now, this %s (id: %d) its %s`s vehicle.", vehName[GetVehicleModel(veh) - 400], veh, gInfo[para][gName]);
		}
	}
	else SCM(playerid, -1, "You are not in a vehicle.");
	return 1;
}

YCMD:vmove(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 3) return adminOnly(playerid, 3);
	new i = GetPlayerVehicleID(playerid);
	if(i) { 
		GetVehiclePos(i, vInfo[svrVeh[i]][vX], vInfo[svrVeh[i]][vY], vInfo[svrVeh[i]][vZ]), GetVehicleZAngle(i, vInfo[svrVeh[i]][vA]);
		DestroyVehicle(i);
		i = CreateVehicle(vInfo[svrVeh[i]][vModel], vInfo[svrVeh[i]][vX], vInfo[svrVeh[i]][vY], vInfo[svrVeh[i]][vZ], vInfo[svrVeh[i]][vA], vInfo[svrVeh[i]][vColor1], vInfo[svrVeh[i]][vColor2], -1);
		PutPlayerInVehicle(playerid, i, 0);
		SCMEx(playerid, -1, "You succesfull moved this %s (id: %d)!", vehName[GetVehicleModel(i) - 400], i);
	}
	else SCM(playerid, -1, "You are not in a vehicle.");
	return 1;
}

YCMD:vehinfo(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 1) return adminOnly(playerid, 1);
	if(sscanf(params, "i", para)) return Syntax(playerid, "/vehinfo [veh id]");
	SCMEx(playerid, COLOR_TEAL, ""TEAL"Model: "WHITE"%d | "TEAL"Carplate: "WHITE"%s | "TEAL"Group: "WHITE"%d | "TEAL"Colors: "WHITE"%d, %d",
	vInfo[svrVeh[para]][vModel], vInfo[svrVeh[para]][vCarPlate], vInfo[svrVeh[para]][vGroup], vInfo[svrVeh[para]][vColor1], vInfo[svrVeh[para]][vColor2]);
	return 1;
}

YCMD:fly(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 1) return adminOnly(playerid, 1);
	StartFly(playerid), SetPlayerHealth(playerid, 999999.00);
	flyingStatus[playerid] = true;
	return 1;
}

YCMD:stopfly(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 1) return adminOnly(playerid, 1);
	StopFly(playerid), setHealth(playerid, 99.00);
	flyingStatus[playerid] = false;
	return 1;
}

YCMD:slap(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 1) return adminOnly(playerid, 1);
	if(sscanf(params, "u", para)) return Syntax(playerid, "/slap [playerid]");
	if(!IsPlayerConnected(para)) return SCM(playerid, COLOR_WHITE, "The player is not connected.");
	new Float:X, FLoat:Y, Float:Z;
	GetPlayerPos(para, Float:X, Float:Y, Float:Z);
	SetPlayerPos(para, Float:X, Float:Y, Float:Z+5);
	sendAdmins(COLOR_RED, "AdmCmd: "WHITE"Admin %s used /slap on %s (%d).", GetName(playerid), GetName(para), para);
	SCMEx(para, COLOR_LORANGE, "You have been slapped by Admin %s.", GetName(playerid));
	return 1;
}

YCMD:cp(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 1) return adminOnly(playerid, 1);
	if(sscanf(params, "d", para)) return Syntax(playerid, "/cp [size]");
	
	new Float:x, Float:y, Float:z;
	GetPlayerPos(playerid, x, y, z), SetPlayerPos(playerid, x, y, z+para);
	return 1;
}

YCMD:gotoveh(playerid, params[], help) {
	//if(pInfo[playerid][pAdmin] < 1) return adminOnly(playerid, 1);
	if(sscanf(params, "i", para)) return Syntax(playerid, "/gotoveh [vehicleid]");
	if(doesVehicleExist(para) == 0) return SCM(playerid, -1, "This vehicle does not exits.");
	new Float:x, Float:y, Float:z;
	GetVehiclePos(para, Float:x, Float:y, Float:z), PutPlayerInVehicle(playerid, para, 0), SetPlayerVirtualWorld(playerid, GetVehicleVirtualWorld(para));
	return 1;
}

YCMD:goto(playerid, params[], help) {
    if(pInfo[playerid][pAdmin] == 0) return adminOnly(playerid, 1);
	if(sscanf(params, "u", para)) return Syntax(playerid, "/goto [player]");
	if(pLogged[para] == 0) return SCM(playerid, COLOR_GREY, "The specified player isn`t connected.");
	
	new Float: fPosX, Float:fPosY, Float:fPosZ;
	GetPlayerPos(para, fPosX, fPosY, fPosZ);

	if(GetPlayerState(playerid) == 2) {
		SetVehiclePos(GetPlayerVehicleID(playerid), fPosX, fPosY, fPosZ);
		LinkVehicleToInterior(GetPlayerVehicleID(playerid), GetPlayerInterior(para));
		SetVehicleVirtualWorld(GetPlayerVehicleID(playerid), GetPlayerVirtualWorld(para));
	}
	else SetPlayerPos(playerid, fPosX, fPosY+1, fPosZ+1.5), playerHQ[playerid] = playerHQ[para];
	
	SetPlayerInterior(playerid, GetPlayerInterior(para)), SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(para));
    return 1;
}

YCMD:gotopoint(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 1) return adminOnly(playerid, 1);
	new Float:x, Float:y, Float:z;
	if(sscanf(params, "fffi", x, y, z, para)) return Syntax(playerid, "/gotopoint [x] [y] [z] [interior]");
	SetPlayerPos(playerid, x, y, z), SetPlayerInterior(playerid, para), SetCameraBehindPlayer(playerid);
	return 1;
}

YCMD:gotojail(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 1) return adminOnly(playerid, 1);
	if(sscanf(params, "s[30]", strPara)) return Syntax(playerid, "/gotopoint [bottom/above]");
	switch(YHash(strPara)) {
		case _H<bottom>: SetPlayerPos(playerid, 264.0331,90.8764,1001.0391);
		case _H<above>: SetPlayerPos(playerid, 267.7538,85.5792,1004.6830);
		default: return 0;
	}
	SetPlayerInterior(playerid, 6), SetPlayerVirtualWorld(playerid, 2), SetCameraBehindPlayer(playerid);
	return 1;
}

YCMD:gotohq(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 1) return adminOnly(playerid, 1);
	if(sscanf(params, "i", para)) return Syntax(playerid, "/gotohq [groupid]");
	SetPlayerPos(playerid, gInfo[para][geX], gInfo[para][geY], gInfo[para][geZ]);
	SetPlayerInterior(playerid, 0), SetPlayerVirtualWorld(playerid, 0);
	SetCameraBehindPlayer(playerid);
	return 1;
}

YCMD:getveh(playerid, params[], help) {
    if(pInfo[playerid][pAdmin] < 1) return adminOnly(playerid, 1);
	if(sscanf(params, "i", para)) return Syntax(playerid, "/getveh [vehicleid]");
	if(doesVehicleExist(para) == 0) return SCM(playerid, -1, "This vehicle does not exits.");
	new Float:x, Float:y, Float:z;
	GetPlayerPos(playerid, x, y, z), SetVehiclePos(para, x, y, z), LinkVehicleToInterior(para, GetPlayerInterior(playerid)), SetVehicleVirtualWorld(para, GetPlayerVirtualWorld(playerid));
	SCMEx(playerid, -1, "Vehicle %d (%s) has been teleported to you.", para, vehName[GetVehicleModel(para) - 400]);
	return 1;
}

YCMD:setadmin(playerid, params[], help) {
	// if(pInfo[playerid][pAdmin] < 6) return adminOnly(playerid, 6);
	if(sscanf(params, "ui", para, para2)) return Syntax(playerid, "/setadmin [playerid] [1-7]");
	if(para == INVALID_PLAYER_ID) return SCM(playerid, COLOR_GREY, "Error: Invalid player id.");
	if(para2 < 0 || para2 > 7) return Syntax(playerid, "/setadmin [playerid] [1-7]");
	sendAdmins(COLOR_NOTICE, "{DEC400}Staff announcement: Admin %s set %s`s administrator level to %d.", GetName(playerid), GetName(para), para2);
	if(pInfo[para][pAdmin] < para2) { SCMEx(para, COLOR_GREY, "Congratulations! You have been promoted to admin level "CREM"%d"GREY" by administrator "CREM"%s"GREY".", para2, GetName(playerid)); } 
	else if(pInfo[para][pAdmin] > para2 && para2 != 0) { SCMEx(para, COLOR_GREY, "You have been demoted to admin level "CREM"%d"GREY" by administrator "CREM"%s"GREY".", para2, GetName(playerid)); }
	else { SCMEx(para2, COLOR_GREY, "You have been removed from "CREM"Staff Team "GREY"(administrators), by "CREM"%s"GREY".", GetName(para)); }
	
	// iterators
	if(pInfo[para][pAdmin] == 0 && para2 > 0) { Iter_Add(Admins, para); }
	else if(pInfo[para][pAdmin] > 0 && para2 == 0) { Iter_Remove(Admins, para); }
	
	pInfo[para][pAdmin] = para2;
	return 1;
}

YCMD:setgslots(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 4) return adminOnly(playerid, 4);
	if(sscanf(params, "ii", para, para2)) return Syntax(playerid, "/setgslots [groupid] [slots]");
	if(gInfo[para][gID] == 0) return SCM(playerid, COLOR_GREY, "Error: Invalid group ID.");
	
	gInfo[para][gSlots] = para2;
	format(largeStr, 128, "AdmCmd: "WHITE"%s changed %s`s slots to %d.", GetName(playerid), gInfo[para][gName], para2), sendAdmins(COLOR_RED, largeStr);
	return 1;
}

YCMD:setgtype(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 4) return adminOnly(playerid, 4);
	if(sscanf(params, "ii", para, para2)) return Syntax(playerid, "/setgtype [groupid] [type]"), SCM(playerid, COLOR_GREY, "Types: "WHITE" 1- police, 2 - medics, 3 - gangs, 4 - hitman, 5- instructor, 6 - taxi, 7 - reporters.");
	if(gInfo[para][gID] == 0) return SCM(playerid, COLOR_GREY, "Error: Invalid group ID.");
	new groupType[20];
	switch(para2) {
		case 1: groupType = "police";
		case 2: groupType = "medic";
		case 3: groupType = "gangs";
		case 4: groupType = "hitman";
		case 5: groupType = "instructor";
		case 6: groupType = "taxi";
		case 7: groupType = "reporter";
	}
	
	gInfo[para][gType] = para2;
	format(largeStr, 128, "AdmCmd: "WHITE"%s changed %s`s type to %s.", GetName(playerid), gInfo[para][gName], groupType), sendAdmins(COLOR_RED, largeStr);
	return 1;
}

YCMD:movesafe(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 4) return adminOnly(playerid, 4);
	if(sscanf(params, "i", para)) return Syntax(playerid, "/movesafe [groupid]");
	if(gInfo[para][gID] == 0) return SCM(playerid, COLOR_GREY, "Error: Invalid group ID.");
			
	GetPlayerPos(playerid, gInfo[para][gSafeX], gInfo[para][gSafeY], gInfo[para][gSafeZ]);
	DestroyDynamicPickup(gInfo[para][gSafePickup]);
	DestroyDynamic3DTextLabel(gInfo[para][gSafeLabel]);
	format(gMsg, 128, "%s\nFaction safe", gInfo[para][gName]);

	gInfo[para][gSafePickup] = CreateDynamicPickup(1274, 1, gInfo[para][gSafeX], gInfo[para][gSafeY], gInfo[para][gSafeZ], para+1, -1, -1, 20.0);
	gInfo[para][gSafeLabel] = CreateDynamic3DTextLabel(gMsg, 0xFFFF00AA, gInfo[para][gSafeX], gInfo[para][gSafeY], gInfo[para][gSafeZ], 100, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, para+1, -1, -1, 20.0);
			
	SCMEx(playerid, COLOR_TEAL, "(!) "WHITE"The safe position of %s (#%d) was changed successfully.", gInfo[para][gName], para);
	saveGroup(para);
	return 1;
}

YCMD:sethqext(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 4) return adminOnly(playerid, 4);
	if(sscanf(params, "i", para)) return Syntax(playerid, "/sethqext [groupid]");
	if(gInfo[para][gID] == 0) return SCM(playerid, COLOR_GREY, "Error: Invalid group ID.");
			
	GetPlayerPos(playerid, gInfo[para][geX], gInfo[para][geY], gInfo[para][geZ]);
	DestroyDynamicPickup(gInfo[para][gPickup]);
	DestroyDynamic3DTextLabel(gInfo[para][gLabel]);
	format(gMsg, 128, "{FF6347}%s`s HQ\n{D2B48C}(%s)", gInfo[para][gName], (gInfo[para][gDoor]) ? ("closed") : ("opened"));
	new pickup;
	if(gInfo[para][gType] == 1) { pickup = 1247; }
	else if(gInfo[para][gType] == 2) { pickup = 1254; }
	else if(gInfo[para][gType] == 3) { pickup = 19130; }
	else if(gInfo[para][gType] == 4) { pickup = 1254; }
	else { pickup = 1239; }
			
	gInfo[para][gPickup] = CreateDynamicPickup(pickup, 1, gInfo[para][geX], gInfo[para][geY], gInfo[para][geZ], -1, -1, -1, 20.0);
	gInfo[para][gLabel] = CreateDynamic3DTextLabel(gMsg, COLOR_YELLOW, gInfo[para][geX], gInfo[para][geY], gInfo[para][geZ], 100, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, -1, -1, -1, 20.0);
			
	SCMEx(playerid, COLOR_TEAL, "(!) "WHITE"The exterior of %s (#%d) was changed successfully.", gInfo[para][gName], para);
	saveGroup(para);
	return 1;
}

YCMD:sethqint(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 4) return adminOnly(playerid, 4);
	if(sscanf(params, "i", para)) return Syntax(playerid, "/sethqint [groupid]");
	if(gInfo[para][gID] == 0) return SCM(playerid, COLOR_GREY, "Error: Invalid group ID.");
			
	GetPlayerPos(playerid, gInfo[para][giX], gInfo[para][giY], gInfo[para][giZ]), gInfo[para][gInterior] = GetPlayerInterior(playerid);
	SCMEx(playerid, COLOR_TEAL, "(!) "WHITE"The interior of %s (#%d) was changed successfully.", gInfo[para][gName], para);
	saveGroup(para);
	return 1;
}
YCMD:auninvite(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 2) return adminOnly(playerid, 2);
	if(sscanf(params, "us[30]", para, strPara)) return Syntax(playerid, "/auninvite [playerid] [reason: max 30 characters]");
	if(para == INVALID_PLAYER_ID) return SCM(playerid, COLOR_GREY, "Error: Invalid player id.");
	if(pInfo[para][pMember] == 0) return SCM(playerid, COLOR_GREY, "You can not use this command on civilians.");
	
	format(gMsg, 128, "%s was uninvited by Admin %s from %s, reason: %s", GetName(para), GetName(playerid), gInfo[pInfo[para][pMember]][gName], strPara);
	sendGroup(COLOR_LIGHT, pInfo[para][pMember], gMsg);
	format(gMsg, 128, "Admin uninvite: %s was uninvited by Admin %s from %s, reason: %s", GetName(para), GetName(playerid), gInfo[pInfo[para][pMember]][gName], strPara);
	sendAdmins(COLOR_RED, gMsg);
	format(gMsg, 128, "You got uninvited by Admin %s from %s, reason: %s", GetName(playerid), gInfo[pInfo[para][pMember]][gName], strPara);
	ShowPlayerDialog(para, DIALOG_GENERAL, DIALOG_STYLE_MSGBOX, "SERVER: Uninvite", gMsg, "Close", "");
	pInfo[para][pMember] = pInfo[para][pRank] = 0, pInfo[para][pGJoinDate] = gettime();
	pInfo[para][pSkin] = SPAWN_SKIN, SetPlayerSkin(para, SPAWN_SKIN), SetPlayerColor(para, getFactionColor(pInfo[para][pMember]));

	if(pInfo[para][pDuty] == 1) { 
		ResetPlayerWeapons(para), setArmour(para, 0.00), removeDutyObjects(para);
		pInfo[para][pDuty] = 0, pInfo[para][pLastDuty] = GetTickCount(); 
	}
	return 1;
}

YCMD:setleader(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 3) return adminOnly(playerid, 3);
	new p;
	if(sscanf(params, "ui", p, para)) return Syntax(playerid, "/setleader [playerid] [group id]");
	if(p == INVALID_PLAYER_ID) return SCM(playerid, COLOR_GREY, "Error: Invalid player id.");
	if(pInfo[p][pMember] > 0) return SCM(playerid, COLOR_GREY, "This player is already in a faction, you need to use /auninvite first.");
	if(gInfo[para][gID] == 0) return SCM(playerid, COLOR_GREY, "Error: Invalid group id.");
	pInfo[p][pMember] = para, pInfo[p][pRank] = 7, pInfo[p][pGJoinDate] = gettime();
	SCMEx(playerid, -1, "You have set %s`s leader to %s.", GetName(p), gInfo[para][gName]), SCMEx(p, -1, ""NON"You have been promoted to %s`s leader by %s. Good job!", gInfo[para][gName], GetName(playerid));
	SetPlayerColor(p, getFactionColor(para)), SetPlayerSkin(p, gInfo[para][gLeadskin]), pInfo[p][pSkin] = gInfo[para][gLeadskin];
	return 1;
}

YCMD:a(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 1) return adminOnly(playerid, 1);
	if(isnull(params)) return Syntax(playerid, "/a [message]");
	sendAdmins(COLOR_ACHAT, "(%d) Admin %s: %s", pInfo[playerid][pAdmin], GetName(playerid), params);
	return 1;
}

YCMD:admins(playerid, params[], help) {
	SCM(playerid, COLOR_TEAL, "---------------------------------------------------------");
	foreach(new i : Admins)
	{
		SCMEx(playerid, -1, "(%d) %s - admin level %d", i, GetName(i), pInfo[i][pAdmin]);
	}
	SCMEx(playerid, -1, "There are %d %s online. If you have a problem, use report.", Iter_Count(Admins), (Iter_Count(Admins) == 1) ? ("admin") : ("admins"));
	SCM(playerid, COLOR_TEAL, "---------------------------------------------------------");
	return 1;
}

///////////////////////////////////////////
YCMD:jobs(playerid, params[], help) {
	new header[60], contentStr[480], finalStr[550], count;
	format(header, 60, "#\tJob name\tOnline workers\n");
	for(new x; x < MAX_JOBS; x++) {
		if(jInfo[x][jID] > 0) {
			foreach(new z : Player) { if(pInfo[z][pJob] == x) { count++; } }
			format(contentStr, 480, "%s%d\t%s\t%d\n", contentStr, x, jInfo[x][jName], count);
		}
	}
	format(finalStr, 550, "%s%s", header, contentStr);
	ShowPlayerDialog(playerid, DIALOG_JOBS, DIALOG_STYLE_TABLIST_HEADERS, "SERVER: Jobs", finalStr, "Select", "Cancel");
	return 1;
}

YCMD:factions(playerid, params[], help) {
	new header[60], contentStr[480], finalStr[550];
	format(header, 60, "#\tFaction name\tMembers\tApplications status\n");
	for(new x; x < MAX_GROUPS; x++) {
		if(gInfo[x][gID] > 0) {
			new str[20];
			format(str, 20, "0/%02d", gInfo[x][gSlots]);
			format(contentStr, 480, "%s%d\t%s\t%s\t%s\n", contentStr, x, gInfo[x][gName], str, (gInfo[x][gApplications] > 0) ? ("{00A645}online") : ("{FF0000}offline"));
		}
	}
	format(finalStr, 550, "%s%s", header, contentStr);
	ShowPlayerDialog(playerid, DIALOG_FACTIONS, DIALOG_STYLE_TABLIST_HEADERS, "SERVER: Factions", finalStr, "Select", "Cancel");
	return 1;
}

YCMD:turfs(playerid, params[], help) {
	if(PlayerZonesStatus[playerid]) {
		hidePlayerZones(playerid), SCM(playerid, -1, "Gangzones disabled."), PlayerZonesStatus[playerid] = 0;
	}
	else {
		showPlayerZones(playerid), SCM(playerid, -1, "Gangzones enabled."), PlayerZonesStatus[playerid] = 1;
	}
	return 1;
}

YCMD:warstats(playerid, params[], help) {
	if(pInfo[playerid][pMember] == 0 || gInfo[pInfo[playerid][pMember]][gType] != 3) return SCM(playerid, COLOR_GREY, "This command can be used only by gangsters.");
	if(gInfo[pInfo[playerid][pMember]][gWar] == 0) return SCM(playerid, -1, "Your gang isn`t in a war!");

	SCMEx(playerid, COLOR_WAR, "Your personal score is %d - %d kills and %d deaths.", pInfo[playerid][pWarKills] - pInfo[playerid][pWarDeaths], pInfo[playerid][pWarKills], pInfo[playerid][pWarDeaths]);
	return 1;
}

YCMD:attack(playerid, params[], help) {
	if(pInfo[playerid][pMember] == 0 || gInfo[pInfo[playerid][pMember]][gType] != 3) return SCM(playerid, COLOR_GREY, "This command can be used only by gangsters.");
	if(pInfo[playerid][pRank] < 4) return SCM(playerid, COLOR_GREY, ""GREY"You need to have rank "ORANGE"4+ "GREY"to use this command.");
	if(getPlayerTurf(playerid) > 0) {
		new t = getPlayerTurf(playerid), m = pInfo[playerid][pMember];
		if(gInfo[m][gWar] > 0) return SCM(playerid, -1, "Your gang is already in a war!");
		if(tInfo[t][tOwner] == pInfo[playerid][pMember]) return SCM(playerid, -1, "You can not attack your gang zone!");
		if(wInfo[t][wTime] != 0) return SCM(playerid, -1, "This turf is already attacked!");
		if(gInfo[tInfo[t][tOwner]][gWar] > 0) return SCM(playerid, -1, "This gang is already in a war!");
		
		format(gMsg, 128, "{4191E0}[WAR] %s from %s attacked turf #%d owned by your group.", GetName(playerid), gInfo[m][gName], t), sendGroup(COLOR_WAR, tInfo[t][tOwner], gMsg);
		format(gMsg, 128, "{4191E0}[WAR] %s from your group attacked turf #%d owned by %s.", GetName(playerid), t, gInfo[tInfo[t][tOwner]][gName]), sendGroup(COLOR_WAR, m, gMsg);

		gInfo[wInfo[t][wDeffender]][gScore] = gInfo[wInfo[t][wAttacker]][gScore] = 0, wInfo[t][wAttacker] = m, wInfo[t][wDeffender] = tInfo[t][tOwner], wInfo[t][wTime] = 60 * 15;
		gInfo[tInfo[t][tOwner]][gWar] = gInfo[pInfo[playerid][pMember]][gWar] = t;
		wInfo[t][wABestScore] = wInfo[t][wAWorstScore] = 0;
		format(wInfo[t][wABestPlayer], MAX_PLAYER_NAME + 1, "No-one");
		format(wInfo[t][wAWorstPlayer], MAX_PLAYER_NAME + 1, "No-one");
		Iter_Add(Wars, t);

		foreach(new i : Player) {
			if(pInfo[i][pMember] == wInfo[t][wAttacker] || pInfo[i][pMember] == wInfo[t][wDeffender]) {
				pInfo[i][pWarKills] = pInfo[i][pWarDeaths] = 0;

				PlayerTextDrawColor(i, warTD[i][0], getFactionColor(wInfo[t][wAttacker])), PlayerTextDrawColor(i, warTD[i][1], getFactionColor(wInfo[t][wDeffender]));
				for(new x; x < 6; x++) { PlayerTextDrawShow(i, warTD[i][x]); }
				ZoneFlashForPlayer(i, t-1, 0xFF0000AA); 

				foreach(new z : Player) {
					if(pInfo[z][pMember] == wInfo[t][wAttacker] || pInfo[z][pMember] == wInfo[t][wDeffender]) {
						OnPlayerStreamIn(i, z);
					}
				}
			}
		}

	}
	else SCM(playerid, COLOR_GREY, "You are not in a turf.");
	return 1;
}

YCMD:test(playerid, params[], help) {
	GivePlayerWeapon(playerid, 31, 22);
	//SetPlayerSpecialAction(playerid, SPECIAL_ACTION_CARRY); - actiune speciala pentru a opri jump/sprint
	return 1;
}

YCMD:anime(playerid, params[], help) {
	new lib[30], name[30];
    if(sscanf(params, "s[30]s[30]", lib, name)) return Syntax(playerid,"/anime [library] [name]");
   
   	ApplyAnimation(playerid, lib, name,4.1, 0, 0, 0, 0, 0, 0);
    return 1;
}

YCMD:order(playerid, params[], help) {
	if(pInfo[playerid][pMember] && gInfo[pInfo[playerid][pMember]][gType] == 4) {
		if(playerHQ[playerid] != pInfo[playerid][pMember]) return SCM(playerid, COLOR_GREY, "You need to be in your HQ.");
		if(pInfo[playerid][pMoney] > 2500) {
			GivePlayerWeapon(playerid, 4, 99), GivePlayerWeapon(playerid, 34, 100), GivePlayerWeapon(playerid, 23, 99), GivePlayerWeapon(playerid, 29, 150);
			SCM(playerid, -1, "You bought the weapons from HQ for $2.500."), takePlayerMoney(playerid, 2500);
		}
		else SCM(playerid, -1, "You need to have $2.500 to get guns from HQ.");
	}
	else if(pInfo[playerid][pMember] && gInfo[pInfo[playerid][pMember]][gType] == 3) {
		if(playerHQ[playerid] != pInfo[playerid][pMember]) return SCM(playerid, COLOR_GREY, "You need to be in your HQ.");
		if(sscanf(params, "s[30]", strPara)) return Syntax(playerid, "/order [weaponid]"), SCM(playerid, -1, "Weapos: 1 - Deagle, 2 - MP5, 3 - M4, 4 - Shotgun, 5 - Country Rifle, 6 - Katana.");
		switch(YHash(strPara)) {
			case _H<1>: {
				if(gInfo[pInfo[playerid][pMember]][gMaterials] < 250) return SCM(playerid, COLOR_GREY, "There are no materials.");
				if(pInfo[playerid][pMoney] > 1250) {
					GivePlayerWeapon(playerid, 24, 150);
					takePlayerMoney(playerid, 1250), gInfo[pInfo[playerid][pMember]][gMaterials] -= 250, gInfo[pInfo[playerid][pMember]][gMoney] += 1250;
					SCM(playerid, -1, ""SYN"You bought a "BLUE"Desert Eagle "SYN"from HQ for $1.250 and 250 materials were spent from group safe.");
				}
				else SCM(playerid, COLOR_GREY, "You need to have $1,250 to get guns from HQ.");
			}
			case _H<2>: {
				if(gInfo[pInfo[playerid][pMember]][gMaterials] < 250) return SCM(playerid, COLOR_GREY, "There are no materials.");
				if(pInfo[playerid][pMoney] > 1000) {
					GivePlayerWeapon(playerid, 29, 150);
					takePlayerMoney(playerid, 1000), gInfo[pInfo[playerid][pMember]][gMaterials] -= 250, gInfo[pInfo[playerid][pMember]][gMoney] += 1000;
					SCM(playerid, -1, ""SYN"You bought a "BLUE"MP5 "SYN"from HQ for $1.000 and 250 materials were spent from group safe.");
				}
				else SCM(playerid, COLOR_GREY, "You need to have $1,000 to get guns from HQ.");
			}
			case _H<3>: {
				if(gInfo[pInfo[playerid][pMember]][gMaterials] < 450) return SCM(playerid, COLOR_GREY, "There are no materials.");
				if(pInfo[playerid][pMoney] > 2000) {
					GivePlayerWeapon(playerid, 31, 300);
					takePlayerMoney(playerid, 2000), gInfo[pInfo[playerid][pMember]][gMaterials] -= 450, gInfo[pInfo[playerid][pMember]][gMoney] += 2000;
					SCM(playerid, -1, ""SYN"You bought a "BLUE"M4 "SYN"from HQ for $2.000 and 450 materials were spent from group safe.");
				}
				else SCM(playerid, COLOR_GREY, "You need to have $2,000 to get guns from HQ.");
			}
			case _H<4>: {
				if(gInfo[pInfo[playerid][pMember]][gMaterials] < 450) return SCM(playerid, COLOR_GREY, "There are no materials.");
				if(pInfo[playerid][pMoney] > 1500) {
					GivePlayerWeapon(playerid, 25, 150);
					takePlayerMoney(playerid, 1500), gInfo[pInfo[playerid][pMember]][gMaterials] -= 450, gInfo[pInfo[playerid][pMember]][gMoney] += 1500;
					SCM(playerid, -1, ""SYN"You bought a "BLUE"Shotgun "SYN"from HQ for $1.500 and 450 materials were spent from group safe.");
				}
				else SCM(playerid, COLOR_GREY, "You need to have $1,500 to get guns from HQ.");
			}
			case _H<5>: {
				if(pInfo[playerid][pRank] < 4) return SCM(playerid, -1, ""GREY"You need to have rank "ORANGE"4+ "GREY" to use this order.");
				if(gInfo[pInfo[playerid][pMember]][gMaterials] < 450) return SCM(playerid, COLOR_GREY, "There are no materials.");
				if(pInfo[playerid][pMoney] > 1900) {
					GivePlayerWeapon(playerid, 33, 150);
					takePlayerMoney(playerid, 1900), gInfo[pInfo[playerid][pMember]][gMaterials] -= 450, gInfo[pInfo[playerid][pMember]][gMoney] += 1900;
					SCM(playerid, -1, ""SYN"You bought a "BLUE"Country Rifle "SYN"from HQ for $1.900 and 450 materials were spent from group safe.");
				}
				else SCM(playerid, COLOR_GREY, "You need to have $1,900 to get guns from HQ.");
			}
			case _H<6>: {
				if(pInfo[playerid][pRank] < 5) return SCM(playerid, -1, ""GREY"You need to have rank "ORANGE"5+ "GREY" to use this order.");
				if(gInfo[pInfo[playerid][pMember]][gMaterials] < 450) return SCM(playerid, COLOR_GREY, "There are no materials.");
				if(pInfo[playerid][pMoney] > 5000) {
					GivePlayerWeapon(playerid, 8, 150);
					takePlayerMoney(playerid, 5000), gInfo[pInfo[playerid][pMember]][gMaterials] -= 450, gInfo[pInfo[playerid][pMember]][gMoney] += 5000;
					SCM(playerid, -1, ""SYN"You bought a "BLUE"Katana "SYN"from HQ for $5.000 and 450 materials were spent from group safe.");
				}
				else SCM(playerid, COLOR_GREY, "You need to have $5,000 to get guns from HQ.");
			}
			default: SCM(playerid, COLOR_GREY, "Error: Wrong weapon.");
		}
	}
	else SCM(playerid, COLOR_GREY, "You are not allowed to use this command.");
	return 1;
}

YCMD:heal(playerid, params[], help) {
	if(pInfo[playerid][pMember] > 0) {
		if(!IsPlayerInRangeOfPoint(playerid, 100.00, gInfo[pInfo[playerid][pMember]][giX], gInfo[pInfo[playerid][pMember]][giY], gInfo[pInfo[playerid][pMember]][giZ])) return SCM(playerid, COLOR_GREY, "You need to be in your HQ.");
		setHealth(playerid, 99.00), GameTextForPlayer(playerid, "healed", 3000, 1);
	}
	else SCM(playerid, COLOR_GREY, "You are not allowed to use this command.");
	return 1;
}

YCMD:gmotto(playerid, params[], help) {
	if(pInfo[playerid][pRank] < 6) return SCM(playerid, COLOR_GREY, "You are not allowed to use this command.");
	if(isnull(params)) return Syntax(playerid, "/gmotto [text]");
	
	SCMEx(playerid, COLOR_TEAL, "(!) "WHITE"You have changed the faction`s motto  to '%s'", params); 

	format(gMsg, 128, "%s has changed the faction`s motto  to '%s'", GetName(playerid), params);
	sendGroup(pInfo[playerid][pMember], COLOR_LIGHT, gMsg);

	format(gInfo[pInfo[playerid][pMember]][gMotto], 128, params);
	return 1;
}

YCMD:showmotto(playerid, params[], help) {
	if(pInfo[playerid][pMember] == 0) return SCM(playerid, COLOR_GREY, "You are not allowed to use this command.");
	SCMEx(playerid, COLOR_LIGHT, "Faction motto: %s", gInfo[pInfo[playerid][pMember]][gMotto]); 
	return 1;
}

YCMD:gdeposit(playerid, params[], help) {
	if(pInfo[playerid][pMember] > 0) {
		if(sscanf(params, "s[30]i", strPara, para)) { Syntax(playerid, "/gdeposit [option] [value]"), SCMEx(playerid, -1, "Materials: %s, Drugs: %s, Money: $%s", FormatNumber(gInfo[pInfo[playerid][pMember]][gMaterials]), FormatNumber(gInfo[pInfo[playerid][pMember]][gDrugs]), FormatNumber(gInfo[pInfo[playerid][pMember]][gMoney])); }
		else {
			if(!IsPlayerInRangeOfPoint(playerid, 100.00, gInfo[pInfo[playerid][pMember]][gSafeX], gInfo[pInfo[playerid][pMember]][gSafeY], gInfo[pInfo[playerid][pMember]][gSafeZ])) return SCM(playerid, -1, "You need to be near by your faction`s safe.");
			switch(YHash(strPara)) {
				case _H<materials>: {
					if(pInfo[playerid][pMaterials] < para) return SCM(playerid, COLOR_GREY, "You don`t have enought materials.");
					gInfo[pInfo[playerid][pMember]][gMaterials] += para, pInfo[playerid][pMaterials] -= para;
					format(gMsg, 128, "* %s deposits %s materials in their group safe.", GetName(playerid), FormatNumber(para)), nearByMessage(playerid, COLOR_PURPLE, gMsg);
					SCMEx(playerid, -1, "You have deposited %s materials in your group safe!", FormatNumber(para));
				}
				case _H<money>: {
					if(pInfo[playerid][pMoney] < para) return SCM(playerid, COLOR_GREY, "You don`t have enought money.");
					gInfo[pInfo[playerid][pMember]][gMoney] += para, pInfo[playerid][pMoney] -= para;
					format(gMsg, 128, "* %s deposits $%s in their group safe.", GetName(playerid), FormatNumber(para)), nearByMessage(playerid, COLOR_PURPLE, gMsg);
					SCMEx(playerid, -1, "You have deposited $%s  in your group safe!", FormatNumber(para));
				}
				case _H<drugs>: {
					if(pInfo[playerid][pDrugs] < para) return SCM(playerid, COLOR_GREY, "You don`t have enought drugs.");
					gInfo[pInfo[playerid][pMember]][gDrugs] += para, pInfo[playerid][pDrugs] -= para;
					format(gMsg, 128, "* %s deposits %d drugs in their group safe.", GetName(playerid), para), nearByMessage(playerid, COLOR_PURPLE, gMsg);
					SCMEx(playerid, -1, "You have deposited %d drugs in your group safe!", para);
				}
				default: SCM(playerid, COLOR_GREY, "Wrong option.");
			}
		}
	}
	else SCM(playerid, COLOR_GREY, "You are not allowed to use this command.");
	return 1;
}

YCMD:invite(playerid, params[], help) {
	if(pInfo[playerid][pRank] < 6 || pInfo[playerid][pMember] == 0) return SCM(playerid, COLOR_GREY, "You are not allowed to use this command.");
	if(sscanf(params, "u", para)) return Syntax(playerid, "/invite [playerid]");
	if(para == INVALID_PLAYER_ID) return SCM(playerid, COLOR_GREY, "Error: Invalid player id.");
	if(para == playerid) return SCM(playerid, COLOR_GREY, "You can not invite yourself.");
	if(pInfo[para][pMember] > 0) return SCM(playerid, COLOR_GREY, "You can invite in your group only civilians.");
	if(GetPVarInt(para, "inviteGroup") == pInfo[playerid][pMember]) return SCM(playerid, COLOR_GREY, "This player is already invited to your group.");
	SetPVarInt(para, "inviteGroup", pInfo[playerid][pMember]), SetPVarString(para, "inviteName", pInfo[playerid][pName]);
	SCMEx(playerid, COLOR_NON, "%s was invited, please wait...", GetName(para));
	SCMEx(para, COLOR_NON, "You have been invited by %s to join in %s. Type /accept invite to accept.", GetName(playerid), gInfo[pInfo[playerid][pMember]][gName]);
	return 1;
}

YCMD:l(playerid, params[], help) {
	if(pInfo[playerid][pRank] <= 6 || pInfo[playerid][pMember] == 0) return SCM(playerid, COLOR_GREY, "You are not allowed to use this command.");
	format(gMsg, 128, "(/l) %s %s: %s", gInfo[pInfo[playerid][pMember]][gName], GetName(playerid), params);
	sendLeaders(gMsg);
	return 1;
}

YCMD:fvr(playerid, params[], help) {
	if(pInfo[playerid][pRank] < 6 || pInfo[playerid][pMember] == 0) return SCM(playerid, COLOR_GREY, "You are not allowed to use this command.");
	for(new x; x < MAX_VEHICLES; x++) {
		if((vInfo[svrVeh[x]][vGroup] == pInfo[playerid][pMember]) && !IsVehicleOccupied(x)) {
			SetVehicleToRespawn(x);
		}
	}
	SCM(playerid, -1, "You have spawned group`s cars!");
	return 1;
}

YCMD:f(playerid, params[], help) {
	if(pInfo[playerid][pMember] && gInfo[pInfo[playerid][pMember]][gType] != 1 && gInfo[pInfo[playerid][pMember]][gType] != 2) {
		if(isnull(params)) return Syntax(playerid, "/f(action) [message]");
		switch(pInfo[playerid][pRank]) { 
			case 1: format(gMsg, 128, "* %s %s: %s", gInfo[pInfo[playerid][pMember]][gRankname1], GetName(playerid), params); case 2: format(gMsg, 128, "* %s %s: %s", gInfo[pInfo[playerid][pMember]][gRankname2], GetName(playerid), params); case 3: format(gMsg, 128, "* %s %s: %s", gInfo[pInfo[playerid][pMember]][gRankname3], GetName(playerid), params); 
			case 4: format(gMsg, 128, "* %s %s: %s", gInfo[pInfo[playerid][pMember]][gRankname4], GetName(playerid), params); case 5: format(gMsg, 128, "* %s %s: %s", gInfo[pInfo[playerid][pMember]][gRankname5], GetName(playerid), params); 
			case 6: format(gMsg, 128, "{1BA6C2}* %s %s: %s", gInfo[pInfo[playerid][pMember]][gRankname6], GetName(playerid), params); case 7: format(gMsg, 128, "{1BA6C2}* %s %s: %s", gInfo[pInfo[playerid][pMember]][gRankname7], GetName(playerid), params); 
		}
		sendGroup(COLOR_FCHAT, pInfo[playerid][pMember], gMsg);
	}
	else SCM(playerid, COLOR_GREY, "You are not authorized to use this chat.");
	return 1;
}

// Hitmans commands
YCMD:contract(playerid, params[], help) {
	if(pInfo[playerid][pLevel] < 3) return SCM(playerid, COLOR_GREY, "You need to have level "ORANGE"3+ "GREY"to use this command.");
	if(gInfo[pInfo[playerid][pMember]][gType] == 4) return SCM(playerid, COLOR_GREY, "You are not allowed to use this command because you are a Hitman.");
	if(sscanf(params, "ui", para, para2)) return Syntax(playerid, "/contract [playerid] [money]");

	if(para == playerid) return SCM( playerid, COLOR_GREY, "You can not make a contract on you.");
	if(pInfo[playerid][pAdmin] > 0) return SCM( playerid, COLOR_GREY, "You can not make a contract on an admin.");
	if(gInfo[pInfo[para][pMember]][gType] == 4) return SCM(playerid, COLOR_GREY, "You can not make a contract on a Hitman.");
	if(pInfo[playerid][pMoney] < para2) return SCMEx(playerid, COLOR_GREY, "You do not have "GREEN"$%s "GREY"for this contract.", FormatNumber(para2));
	if(para2 < 10000) return SCM(playerid, COLOR_GREY, "The price of a contract is $10.000!");
	
	new found;
	
	SCMEx(playerid, -1, "Your contract was accepted by Hitman Agency. You paid $%s", FormatNumber(para2));
	pInfo[playerid][pMoney] -= para2;


	foreach(new x : contracts) {
		if(contractInfo[x][targetID] == para) {
			contractInfo[x][targetSum] += para2;
			contractInfo[x][lastUpdated] = gettime();
			found = 1;
		}
		else { found = 0; }
	}

	if(found == 0) {
		new id = Iter_Free(contracts);
		Iter_Add(contracts, id);
		contractInfo[id][targetID] = para, contractInfo[id][targetSum] += para2, contractInfo[id][lastUpdated] = gettime();
		contractInfo[id][checkBy] = -1;
	}
	
	return 1;
}

YCMD:contracts(playerid, params[], help) {
	if(gInfo[pInfo[playerid][pMember]][gType] != 4) return SCM(playerid, COLOR_GREY, "This command can be used only by Hitmans.");
	if(Iter_Count(contracts) == 0) return SCM(playerid, -1, "There are no contracts.");
	SCMEx(playerid, COLOR_PURPLE, "** There are %d contracts:", Iter_Count(contracts));
	foreach(new x : contracts) {
		if(contractInfo[x][checkBy] != -1) {
			SCMEx(playerid, -1, "Target: %s, money: $%s - got by %s", GetName(contractInfo[x][targetID]), FormatNumber(contractInfo[x][targetSum]), GetName(contractInfo[x][checkBy]));
		}
		else SCMEx(playerid, -1, "Target: %s, money: $%s, last contract %d minutes ago.", GetName(contractInfo[x][targetID]), FormatNumber(contractInfo[x][targetSum]), (gettime()-contractInfo[x][lastUpdated])/60);
	}
	return 1;
}

YCMD:gethit(playerid, params[], help) {
	if(gInfo[pInfo[playerid][pMember]][gType] != 4) return SCM(playerid, COLOR_GREY, "This command can be used only by Hitmans.");
	if(Iter_Count(contracts) == 0) return SCM(playerid, -1, "There are no contracts.");
	if(playerTarget[playerid] != -1) return SCM(playerid, COLOR_GREY, "You have already an active contract.");
	
	new id = Iter_Random(contracts), string[128];
	format(string, 128, "%s received a random hit: %s", GetName(playerid), GetName(contractInfo[id][targetID]));
	sendGroup(COLOR_TEAL, pInfo[playerid][pMember], string);

	SCM(playerid, COLOR_YELLOW, "You got a random target. Now you`re undercover, be ready to execute your command (/turn off).");
	contractInfo[id][checkBy] = playerid, playerTarget[playerid] = id, playerCover[playerid] = 1;

	SetPlayerSkin(playerid, random(100));
	foreach(new x : Player) {
		ShowPlayerNameTagForPlayer(x, playerid, false);
	}
	return 1;
}

YCMD:leavehit(playerid, params[], help) {
	if(gInfo[pInfo[playerid][pMember]][gType] != 4) return SCM(playerid, COLOR_GREY, "This command can be used only by Hitmans.");
	if(playerTarget[playerid] == -1) return SCM(playerid, COLOR_GREY, "You don`t have an active contract.");

	new string[128];
	SCM(playerid, COLOR_YELLOW, "Cancelling your contract...");
	format(string, 128, "%s canceled his contract.", GetName(playerid));
	sendGroup(COLOR_TEAL, pInfo[playerid][pMember], string);

	contractInfo[playerTarget[playerid]][checkBy] = -1, playerTarget[playerid] = -1, playerCover[playerid] = 0;

	SetPlayerSkin(playerid, pInfo[playerid][pSkin]);
	foreach(new x : Player) {
		ShowPlayerNameTagForPlayer(x, playerid, true);
	}
	return 1;
}

YCMD:mytarget(playerid, params[], help) {
	if(gInfo[pInfo[playerid][pMember]][gType] != 4) return SCM(playerid, COLOR_GREY, "This command can be used only by Hitmans.");
	if(playerTarget[playerid] == -1) return SCM(playerid, COLOR_GREY, "You don`t have an active contract.");

	new x = playerTarget[playerid], s = GetPlayerVehicleSeat(contractInfo[x][targetID]);
	SCMEx(playerid, COLOR_GREY, "** Your target is %s (%d), status: %s", 
		GetName(contractInfo[x][targetID]), contractInfo[x][targetID], (s == -1) ? ("without vehicle") : ((s == 0) ? ("driver") : ("passenger")));
	return 1;
}

// Reporters commands
YCMD:news(playerid, params[], help)
{
	if(gInfo[pInfo[playerid][pMember]][gType] != 7) return SCM(playerid, COLOR_GREY, "This command can be used only by reporters.");
	if(!IsPlayerInAnyVehicle(playerid) && vInfo[svrVeh[GetPlayerVehicleID(playerid)]][vGroup] != pInfo[playerid][pMember]) return SCM(playerid, COLOR_GREY, "You are not in faction`s vehicle.");
	if(isnull(params)) return Syntax(playerid, "/news [text]");

	format(largeStr, 256, "NR %s: %s", GetName(playerid), params);
	if(strlen(largeStr) > 120)  {
		new secondLine[128];
			
		strmid(secondLine, largeStr, 110, 256), strdel(largeStr, 110, 256);
		SendClientMessageToAll(0xFF9500FF, largeStr), SendClientMessageToAll(0xFF9500FF, secondLine);
	}
	else SendClientMessageToAll(0xFF9500FF, largeStr);
	return 1;
}

YCMD:live(playerid, params[], help) {
	if(pInfo[playerid][pRank] < 2 || gInfo[pInfo[playerid][pMember]][gType] != 7) return SCM(playerid, COLOR_GREY, "You need to be a Reporter (rank 2+) to use this command.");
	if(GetSVarInt("liveOn") == 1) return SCM(playerid, COLOR_GREY, "There is already an active live.");
	if(!IsPlayerInRangeOfPoint(playerid, 100.00, gInfo[pInfo[playerid][pMember]][giX], gInfo[pInfo[playerid][pMember]][giY], gInfo[pInfo[playerid][pMember]][giZ])) return SCM(playerid, COLOR_GREY, "You need to be in News Reporter studio.");
	if(sscanf(params, "u", para)) return Syntax(playerid, "/live [playerid]");
	if(para == INVALID_PLAYER_ID) return SCM(playerid, COLOR_GREY, "Error: Invalid player id.");
	if(para == playerid) return SCM(playerid, COLOR_GREY, "You can not send you an invitation.");
	if(pInfo[para][pWanted]) return SCM(playerid, COLOR_GREY, "You can not send an invitation to a criminal.");

	new liveStr[184];
	format(liveStr, 184, ""RED"** Send live invitation\n\n"SYN"Are you sure you want to invite %s to live?\n"GREEN"Live price: "SYN"$25,000", GetName(para));
	ShowPlayerDialog(playerid, DIALOG_CONFIRM, DIALOG_STYLE_MSGBOX, "SERVER: Live invitation", liveStr, "Send", "Cancel");

	SetSVarInt("liveReporter", playerid), SetSVarInt("livePlayer", para);
	pConfirm[playerid] = 1;
	return 1;
}

YCMD:stoplive(playerid, params[], help) {
	if(pInfo[playerid][pRank] < 2 || gInfo[pInfo[playerid][pMember]][gType] != 7) return SCM(playerid, COLOR_GREY, "You need to be a Reporter (rank 2+) to use this command.");
	if(GetSVarInt("liveOn") == 0) return SCM(playerid, COLOR_GREY, "There is no active live.");
	if(GetSVarInt("liveReporter") != playerid) return SCM(playerid, COLOR_GREY, "You are not the reporter who started this live.");

	ShowPlayerDialog(playerid, DIALOG_CONFIRM, DIALOG_STYLE_MSGBOX, "SERVER: Live invitation", ""RED"** Stop live\n\n"SYN"Are you sure that you want to stop this live?", "Stop", "Cancel");
	pConfirm[playerid] = 3;
	return 1;
}

// Police commands 
YCMD:r(playerid, params[], help) {
	if(pInfo[playerid][pMember] && gInfo[pInfo[playerid][pMember]][gType] == 1) {
		if(isnull(params)) return Syntax(playerid, "/r(adio) [message]");
		switch(pInfo[playerid][pRank]) { 
			case 1: format(gMsg, 128, "* %s %s: %s", gInfo[pInfo[playerid][pMember]][gRankname1], GetName(playerid), params); case 2: format(gMsg, 128, "* %s %s: %s", gInfo[pInfo[playerid][pMember]][gRankname2], GetName(playerid), params); case 3: format(gMsg, 128, "* %s %s: %s", gInfo[pInfo[playerid][pMember]][gRankname3], GetName(playerid), params); 
			case 4: format(gMsg, 128, "* %s %s: %s", gInfo[pInfo[playerid][pMember]][gRankname4], GetName(playerid), params); case 5: format(gMsg, 128, "* %s %s: %s", gInfo[pInfo[playerid][pMember]][gRankname5], GetName(playerid), params); 
			case 6: format(gMsg, 128, "{BE80ED}* %s %s: %s", gInfo[pInfo[playerid][pMember]][gRankname6], GetName(playerid), params); case 7: format(gMsg, 128, "{BE80ED}* %s %s: %s", gInfo[pInfo[playerid][pMember]][gRankname7], GetName(playerid), params); 
		}
		sendGroup(COLOR_RCHAT, pInfo[playerid][pMember], gMsg);
	}
	else SCM(playerid, COLOR_GREY, "You are not authorized to use this chat.");
	return 1;
}

YCMD:d(playerid, params[], help) {
	if(pInfo[playerid][pMember] && gInfo[pInfo[playerid][pMember]][gType] == 1) {
		if(isnull(params)) return Syntax(playerid, "/d(epartments) [message]");
		switch(pInfo[playerid][pRank]) { 
			case 1: format(gMsg, 128, "** %s %s: %s, over.", gInfo[pInfo[playerid][pMember]][gRankname1], GetName(playerid), params); case 2: format(gMsg, 128, "** %s %s: %s, over.", gInfo[pInfo[playerid][pMember]][gRankname2], GetName(playerid), params); case 3: format(gMsg, 128, "** %s %s: %s, over.", gInfo[pInfo[playerid][pMember]][gRankname3], GetName(playerid), params); 
			case 4: format(gMsg, 128, "** %s %s: %s, over.", gInfo[pInfo[playerid][pMember]][gRankname4], GetName(playerid), params); case 5: format(gMsg, 128, "** %s %s: %s, over.", gInfo[pInfo[playerid][pMember]][gRankname5], GetName(playerid), params); case 6: format(gMsg, 128, "** %s %s: %s, over.", gInfo[pInfo[playerid][pMember]][gRankname6], GetName(playerid), params); 
			case 7: format(gMsg, 128, "** %s %s: %s, over.", gInfo[pInfo[playerid][pMember]][gRankname7], GetName(playerid), params); 
		}
		sendgType(COLOR_DCHAT, gInfo[pInfo[playerid][pMember]][gType], gMsg);
	}
	return 1;
}

YCMD:duty(playerid, params[], help) {
	if(pInfo[playerid][pMember] && gInfo[pInfo[playerid][pMember]][gType] != 1) return SCM(playerid, COLOR_GREY, "This command can be used only by cops.");
	if(playerHQ[playerid] != pInfo[playerid][pMember]) return SCM(playerid, -1, "You need to be in your HQ.");
	
	switch(pInfo[playerid][pDuty]) {
		case 0: {
			if(pInfo[playerid][pLastDuty] != 0 && (GetTickCount() - pInfo[playerid][pLastDuty]) / 1000 < 120) return SCMEx(playerid, -1, "You need to wait %d seconds to be on-duty again.", 120 - ((GetTickCount() - pInfo[playerid][pLastDuty]) / 1000));
			format(gMsg, 128, "** %s took his equipment out of his locker.", GetName(playerid)), nearByMessage(playerid, COLOR_PURPLE, gMsg, 10.0);
			SCM(playerid, -1, "You are on duty!");
			GivePlayerWeapon(playerid, 24, 100), GivePlayerWeapon(playerid, 31, 350), GivePlayerWeapon(playerid, 29, 100), GivePlayerWeapon(playerid, 41, 999);
			pInfo[playerid][pDuty] = 1;
			setArmour(playerid, 99.00), setHealth(playerid, 99.00), putDutyObjects(playerid);
		}
		case 1: {
			format(gMsg, 128, "** %s put his equipment in his locker.", GetName(playerid)), nearByMessage(playerid, COLOR_PURPLE, gMsg, 10.0);
			SCM(playerid, -1, "You are off duty!");
			ResetPlayerWeapons(playerid), setArmour(playerid, 0.00), setHealth(playerid, 99.00), removeDutyObjects(playerid);
			pInfo[playerid][pDuty] = 0, pInfo[playerid][pLastDuty] = GetTickCount();
		}
	}
	return 1;
}

YCMD:clear(playerid, params[], help) {
	if(sscanf(params, "us[20]", para, strPara)) return Syntax(playerid, "/clear [playerid] [reason]"), SCM(playerid, COLOR_GREY, "Use this command only for "DRED"important "GREY"cases.");

	if(gInfo[pInfo[playerid][pMember]][gType] != 1) return SCM(playerid, COLOR_GREY, "This command can be used only by cops.");
	if(pInfo[playerid][pDuty] == 0) return SCM(playerid, COLOR_GREY, "You need to be on-duty to use his command.");
	if(isLogged(para) == 0) return SCM(playerid, -1, "The player is not connected");
	if(pInfo[para][pWanted] == 0) return SCM(playerid, COLOR_GREY, "Dispatch: This player is not wanted!");

	sendDutyCops(COLOR_BLUE, "Dispatch: %s cleared %s's wanted, reason: %s", GetName(playerid), GetName(para), strPara);
	SCMEx(para, COLOR_LIGHTBLUE, "%s cleared your wanted, reason: %s", GetName(playerid), strPara);

	pInfo[para][pWanted] = 0, SetPlayerWantedLevel(para, 0);
	format(pInfo[para][pWantedReason], 10, "NULL");
						
	return 1;
}

YCMD:confiscate(playerid, params[], help)
{
	if(gInfo[pInfo[playerid][pMember]][gType] != 1) return SCM(playerid, COLOR_GREY, "This command can be used only by cops.");
	if(pInfo[playerid][pDuty] == 0) return SCM(playerid, COLOR_GREY, "You need to be on-duty to use his command.");

	if(sscanf(params, "us[20]", para, strPara)) return Syntax(playerid, "/confiscate [playerid] [item]"), SCM(playerid, COLOR_GREY, "Items: "WHITE"Drugs, license (driving)");
	if(isLogged(para) == 0) return SCM(playerid, -1, "The player is not connected");
	if(GetDistanceBetweenPlayers(playerid, para) > 5.00) return SCM(playerid, COLOR_GREY, "You are too far away.");
	if(GetPlayerSpecialAction(para) != SPECIAL_ACTION_HANDSUP) return SCM(playerid, COLOR_GREY, "That person must have their hands up.");

	new string[128];
	switch(YHash(strPara)) {
		case _H<drugs>: {
			if(pInfo[para][pDrugs] == 0) return SCM(playerid, COLOR_GREY, "This player has no drugs to confiscate.");

			format(string, sizeof(string), "* %s has confiscated %s`s drugs drugs.", GetName(playerid), GetName(para)), nearByMessage(playerid, COLOR_PURPLE, string);
			SCMEx(para, -1, "%s has confiscated your drugs.", GetName(playerid));
			SCMEx(playerid, -1, "You have confiscated %s's drugs (%d).", GetName(para), pInfo[para][pDrugs]);
			pInfo[playerid][pDrugs] += pInfo[para][pDrugs];
			pInfo[para][pDrugs] = 0;
		}
		case _H<license>: {
			if(pInfo[para][pCarLic] == 0) return SCM(playerid, COLOR_GREY, "This player has no driving license to confiscate.");

			format(string, sizeof(string), "* %s has confiscated the driving license from %s.", GetName(playerid), GetName(para)), nearByMessage(playerid, COLOR_PURPLE, string);
			SCMEx(para, -1, "%s has confiscated your driving license.", GetName(playerid));
			SCMEx(playerid, -1, "You have confiscated %s's driving license.", GetName(para));
			pInfo[para][pCarLic] = -2;
		}
		default: SCM(playerid, COLOR_GREY, "Invalid item specified.");
	}
	return 1;
}

YCMD:wanted(playerid, params[], help) {
	if(gInfo[pInfo[playerid][pMember]][gType] != 1) return SCM(playerid, COLOR_GREY, "This command can be used only by cops.");
	if(pInfo[playerid][pDuty] == 0) return SCM(playerid, COLOR_GREY, "You need to be on-duty to use his command.");
	new contentStr[480], count;
	new Float:px, Float:py, Float:pz;
	foreach(new i : Player) {
		if(pInfo[i][pWanted] > 0) {
			dialogPlayer[playerid][count] = count++;
			GetPlayerPos(i, px, py, pz);
			format(contentStr, 480, "%s%s (id: %d)\twanted %d\t%0.2fm\n", contentStr, GetName(i), i, pInfo[i][pWanted], GetPlayerDistanceFromPoint(playerid, px, py, pz));
		}
	}
	if(count) {
		new header[60], finalStr[550];
		format(header, 60, "Player\tWanted level\tDistance (m)\n");
		format(finalStr, 550, "%s%s", header, contentStr);
		ShowPlayerDialog(playerid, DIALOG_WANTED, DIALOG_STYLE_TABLIST_HEADERS, "SERVER: Wanted list", finalStr, "Select", "Cancel");
	}
	else SCM(playerid, -1, "There are no suspects.");
	return 1;
}

YCMD:gov(playerid, params[], help) {
	if(isnull(params)) return Syntax(playerid, "/gov [message]");
	if((gInfo[pInfo[playerid][pMember]][gType] != 1 && gInfo[pInfo[playerid][pMember]][gType] != 2)) return SCM(playerid, COLOR_GREY, "You need to be in a department to use this command.");
	if(pInfo[playerid][pRank] < 6) return SCM(playerid, COLOR_GREY, "You need to have rank 5+ to use this command.");
	
	format(gMsg, 128, "------ Government Announcement from %s:", gInfo[pInfo[playerid][pMember]][gName]);
	SendClientMessageToAll(COLOR_TEAL, gMsg);

	if(pInfo[playerid][pRank] == 6) format(gMsg, 128, "* %s %s: %s", gInfo[pInfo[playerid][pMember]][gRankname6], GetName(playerid), params);
	if(pInfo[playerid][pRank] == 7) format(gMsg, 128, "* %s %s: %s", gInfo[pInfo[playerid][pMember]][gRankname7], GetName(playerid), params);
	SendClientMessageToAll(COLOR_BLUE, gMsg);
	return 1;
}

YCMD:m(playerid, params[], help)
{
	if(gInfo[pInfo[playerid][pMember]][gType] != 1) return SCM(playerid, COLOR_GREY, "This command can be used only by cops.");
	if(pInfo[playerid][pDuty] == 0) return SCM(playerid, COLOR_GREY, "You need to be on-duty to use his command.");
	if(!IsPlayerInAnyVehicle(playerid)) return SCM(playerid, COLOR_GREY, "You are not in a vehicle.");
	if(isnull(params)) return Syntax(playerid, "/m(egaphone) [text]");

	format(largeStr, 256, "(megaphone) "LRED"%s "YELLOW"says: %s", GetName(playerid), params);
	if(strlen(largeStr) > 120)  {
		new secondLine[128];
			
		strmid(secondLine, largeStr, 110, 256), strdel(largeStr, 110, 256);
		nearByMessage(playerid, COLOR_YELLOW, largeStr, 30.0), nearByMessage(playerid, COLOR_YELLOW, secondLine, 30.0);
	}
	else nearByMessage(playerid, COLOR_YELLOW, largeStr, 30.0);
	return 1;
}

YCMD:mdc(playerid, params[], help)
{
	if(gInfo[pInfo[playerid][pMember]][gType] != 1) return SCM(playerid, COLOR_GREY, "This command can be used only by cops.");
	if(pInfo[playerid][pDuty] == 0) return SCM(playerid, COLOR_GREY, "You need to be on-duty to use his command.");
	if(sscanf(params, "u", para)) return Syntax(playerid, "/mdc [playerid]");
	if(isLogged(para) == 0) return SCM(playerid, -1, "The player is not connected");
	GetPlayerMdc(playerid, para);
	return 1;
}

YCMD:su(playerid, params[], help)
{
	if(gInfo[pInfo[playerid][pMember]][gType] != 1) return SCM(playerid, COLOR_GREY, "This command can be used only by cops.");
	if(pInfo[playerid][pDuty] == 0) return SCM(playerid, COLOR_GREY, "You need to be on-duty to use his command.");
	if(sscanf(params, "uis[50]", para, para2, strPara)) return Syntax(playerid, "/suspect [playerid] [wanted level] [crime]");
	if(isLogged(para) == 0) return SCM(playerid, -1, "The player is not connected");
	if(para == playerid) return SCM(playerid, -1, "You can't suspect yourself!");
	if(gInfo[pInfo[para][pMember]][gType] == 1) return SCM(playerid, -1, "You can't suspect a cop!");
	if(para2 < 1 || para2 > 6) return SCM(playerid, -1, "Error: Unknown wanted level.");
	if(lastSuspect[playerid] != 0 && (GetTickCount() - lastSuspect[playerid]) / 1000 < 10) return SCMEx(playerid, -1, "You need to wait %d seconds.", 10 - ((GetTickCount() -lastSuspect[playerid]) / 1000));
	
	if(pInfo[para][pWanted] > 0) {
		format(pInfo[para][pWantedReason], 200, "%s, %s", pInfo[para][pWantedReason], strPara);
	}
	else format(pInfo[para][pWantedReason], 200, "%s", strPara);

	if(pInfo[para][pWanted] + para2 > 6) {
		pInfo[para][pWanted] = 6;
		SetPlayerWantedLevel(para, 6);
	}
	else {
		pInfo[para][pWanted] += para2;
		SetPlayerWantedLevel(para, pInfo[para][pWanted]);
	}
	lastSuspect[playerid] = GetTickCount();
	sendDutyCops(COLOR_BLUE, "Dispatch: %s (%d) has comitted a crime: '%s'. Reporter: %s (%d). W: +%d, new wanted level: %d", GetName(para), para, strPara, GetName(playerid), playerid, para2, pInfo[para][pWanted]);
	SCMEx(para, COLOR_RED, "You have commited a crime: %s. W: +%d, new wanted level: %d. Reported by: %s", strPara, para2, pInfo[para][pWanted], GetName(playerid));
	return 1; 
}

YCMD:arrest(playerid, params[], help) {
	if(gInfo[pInfo[playerid][pMember]][gType] != 1) return SCM(playerid, COLOR_GREY, "This command can be used only by cops.");
	if(pInfo[playerid][pDuty] == 0) return SCM(playerid, COLOR_GREY, "You need to be on-duty to use his command.");
	if(sscanf(params, "u", para)) return Syntax(playerid, "/arrest [playerid]");
	if(isLogged(para) == 0) return SCM(playerid, -1, "The player is not connected");
	if(pInfo[para][pWanted] == 0) return SCM(playerid, -1, "This player is not a suspect.");

	if(IsPlayerInRangeOfPoint(playerid, 18.00, 268.3221,75.6865,1001.0391) && IsPlayerInRangeOfPoint(para, 18.00, 268.3221,75.6865,1001.0391)) {
		new spawn = random(sizeof(randomJail)), finePrice, sentence;
		switch(pInfo[para][pWanted]) {
			case 1: finePrice = 1500, sentence = 2;
			case 2: finePrice = 3500, sentence = 5;
			case 3: finePrice = 5500, sentence = 7;
			case 4: finePrice = 6500, sentence = 10;
			case 5: finePrice = 7500, sentence = 15;
			case 6: finePrice = 9500, sentence = 20;
		}
		playerJailType[para] = 1, playerJailTime[para] = sentence * 60;
		PlayerTextDrawSetString(para, examTD[para], "~r~loading..."), PlayerTextDrawShow(para, examTD[para]);

		format(gMsg, 128,"%s has arrested suspect %s, issuing a fine of %s$ with a sentence of %d minutes.", GetName(playerid), GetName(para), FormatNumber(finePrice), sentence);
		SendClientMessageToAll(COLOR_LIGHTRED, gMsg);
		SCMEx(para, COLOR_LIGHTBLUE, "You have been arrested by %s for %d minutes and you have received a fine of $%s", GetName(para), sentence, FormatNumber(finePrice));

		pInfo[para][pWanted] = 0, Freeze[para] = false, takePlayerMoney(para, finePrice);
		TogglePlayerControllable(para, 1), SetPlayerSpecialAction(para, SPECIAL_ACTION_NONE);
		ResetPlayerWeapons(para), SetPlayerWantedLevel(para, 0), SetPlayerInterior(para, 6), SetPlayerVirtualWorld(para, 2);
		SetPlayerPos(para, randomJail[spawn][0], randomJail[spawn][1], randomJail[spawn][2]), SetPlayerFacingAngle(para, 180.0);
		format(pInfo[para][pWantedReason], 10, "NULL");


		Iter_Add(jailPlayers, para);
	}
	else if(IsPlayerInRangeOfPoint(playerid, 5.00, 1528.5862,-1677.9933,5.8906) && IsPlayerInRangeOfPoint(para, 5.00, 1528.5862,-1677.9933,5.8906)) {
		if(Freeze[para] == false) return SCM(playerid, -1, "The suspect must be cuffed first!");

		new spawn = random(sizeof(randomJail)), finePrice, sentence;
		switch(pInfo[para][pWanted]) {
			case 1: finePrice = 1500, sentence = 2;
			case 2: finePrice = 3500, sentence = 5;
			case 3: finePrice = 5500, sentence = 7;
			case 4: finePrice = 6500, sentence = 10;
			case 5: finePrice = 7500, sentence = 15;
			case 6: finePrice = 9500, sentence = 20;
		}
		playerJailType[para] = 1, playerJailTime[para] = sentence * 60;
		PlayerTextDrawSetString(para, examTD[para], "~r~loading..."), PlayerTextDrawShow(para, examTD[para]);

		format(gMsg, 128,"%s has arrested suspect %s, issuing a fine of %s$ with a sentence of %d minutes.", GetName(playerid), GetName(para), FormatNumber(finePrice), sentence);
		SendClientMessageToAll(COLOR_LIGHTRED, gMsg);
		SCMEx(para, COLOR_LIGHTBLUE, "You have been arrested by %s for %d minutes and you have received a fine of $%s", GetName(para), sentence, FormatNumber(finePrice));

		pInfo[para][pWanted] = 0, Freeze[para] = false, takePlayerMoney(para, finePrice);
		TogglePlayerControllable(para, 1), SetPlayerSpecialAction(para, SPECIAL_ACTION_NONE);
		ResetPlayerWeapons(para), SetPlayerWantedLevel(para, 0), SetPlayerInterior(para, 6), SetPlayerVirtualWorld(para, 2);
		SetPlayerPos(para, randomJail[spawn][0], randomJail[spawn][1], randomJail[spawn][2]), SetPlayerFacingAngle(para, 180.0);
		format(pInfo[para][pWantedReason], 10, "NULL");

		Iter_Add(jailPlayers, para);
	}
	else SCM(playerid, COLOR_GREY, "You are not in the correct location.");
	return 1;
}

YCMD:cuff(playerid, params[], help) {
	if(pInfo[playerid][pMember] && gInfo[pInfo[playerid][pMember]][gType] != 1) return SCM(playerid, COLOR_GREY, "This command can be used only by cops.");
	if(sscanf(params, "u", para)) return Syntax(playerid, "/cuff [playerid]");
	if(!IsPlayerConnected(para)) return SCM(playerid, COLOR_GREY, "This player is not connected.");
	if(Freeze[para] == true) return SCM(playerid, COLOR_GREY, "This player is already cuffed.");
	if(para == playerid) return SCM(playerid, COLOR_GREY, "You can't cuff yourself.");
	new Float:X, Float:Y, Float:Z;
	GetPlayerPos(para, X, Y, Z);
	if(GetPlayerVehicleID(playerid) > 0 && GetPlayerState(playerid) == PLAYER_STATE_DRIVER && (GetPlayerVehicleID(para) == GetPlayerVehicleID(playerid) && GetPlayerState(para) == PLAYER_STATE_PASSENGER)) {
		SCMEx(para, COLOR_WHITE, "You have been cuffed by Office %s.", GetName(playerid));
		format(gMsg, 100, "** Officer %s cuffed %s, he can't move right now.", GetName(playerid), GetName(para));
		nearByMessage(playerid, COLOR_PURPLE, gMsg, 12.0);

		TogglePlayerControllable(para, 0), SetPlayerSpecialAction(para, SPECIAL_ACTION_CUFFED);

		Freeze[para] = true;
	}
	else SCM(playerid, COLOR_GREY, "You can not cuff this player.");
	return 1;
}

YCMD:uncuff(playerid, params[], help) {
	if(pInfo[playerid][pMember] && gInfo[pInfo[playerid][pMember]][gType] != 1) return SCM(playerid, COLOR_GREY, "This command can be used only by cops.");
	if(sscanf(params, "u", para)) return Syntax(playerid, "/uncuff [playerid]");
	if(!IsPlayerConnected(para)) return SCM(playerid, COLOR_GREY, "This player is not connected.");
	if(Freeze[para] == false) return SCM(playerid, COLOR_GREY, "This player is not already cuffed.");
	if(para == playerid) return SCM(playerid, COLOR_GREY, "You can't cuff yourself.");
	new Float:X, Float:Y, Float:Z;
	GetPlayerPos(para, X, Y, Z);
	if(!IsPlayerInRangeOfPoint(playerid, 9.0, X, Y, Z)) return SCM(playerid, COLOR_GREY, "You need to be near the player.");
	
	SCMEx(para, COLOR_WHITE, "You have been uncuffed by Office %s.", GetName(playerid));
	format(gMsg, 100, "* Officer %s has stopped dragging %s, releasing their grip.", GetName(playerid), GetName(para));
	nearByMessage(playerid, COLOR_PURPLE, gMsg, 12.0);
	TogglePlayerControllable(para, 1), SetPlayerSpecialAction(para, SPECIAL_ACTION_NONE);
	
	Freeze[para] = false;
	return 1;
}


// General commands
YCMD:exam(playerid, params[], help)
{
	if(!IsPlayerInRangeOfPoint(playerid, 2.0, 1219.2314, -1811.8459, 16.5938)) return SCM(playerid, -1, "You are not at DMV place."), SetPlayerCheckpoint(playerid, 1219.2314, -1811.8459, 16.5938, 3.5), Checkpoint[playerid] = 3;
	if(pInfo[playerid][pCarLic] < 0) return SCM(playerid, -1, "Your license has been suspended.");
	if(pInfo[playerid][pCarLic] > 0) return SCM(playerid, -1, "You already have a driving license.");
	new alarm,doors,bonnet,boot,objective;

	DMVVehicle[playerid] = CreateVehicle(445, 1213.7495,-1839.2784,13.1088,180.1414, 205, -1, 10);


	DMVObject[playerid] = CreateObject(19308, 0.00, -0.22, 0.93,   0.00, 0.00, 0.00);
	SetObjectMaterialText(DMVObject[playerid], "DRIVING SCHOOL", 0, 80, "Arial", 26, 1, 0xFFFFFFFF, 23, 1);

	AttachObjectToVehicle(DMVObject[playerid], DMVVehicle[playerid], 0.00, -0.40, 0.90, 0.00, 0.00, 0.00);
	SetVehicleParamsEx(DMVVehicle[playerid],VEHICLE_PARAMS_ON,VEHICLE_PARAMS_OFF,alarm,doors,bonnet,boot,objective), SetVehicleNumberPlate(DMVVehicle[playerid], ""BLUE"DMV "DRED"Car");
	SetVehicleVirtualWorld(DMVVehicle[playerid], playerid+1), SetPlayerVirtualWorld(playerid, playerid+1);
	TogglePlayerSpectating(playerid, 1);
	InterpolateCameraPos(playerid, 1195.399291, -1843.158691, 20.030143, 1215.266479, -1844.870971, 15.758253, 15000);
	InterpolateCameraLookAt(playerid, 1200.052368, -1842.802368, 18.235185, 1213.983520, -1840.459106, 13.786005, 15000);
	PlayerTextDrawShow(playerid, drivingTD[playerid][0]), PlayerTextDrawShow(playerid, drivingTD[playerid][1]), PlayerTextDrawShow(playerid, drivingTD[playerid][2]);
	defer startExam(playerid);
	return 1;
}

YCMD:help(playerid, params[], help) {
    ShowPlayerDialog(playerid, DIALOG_HELP, DIALOG_STYLE_LIST, "SERVER: Help list", "General\nAnimations list\nFactions\nVehicles", "Select", "Cancel");
	return 1;
}

YCMD:stopanim(playerid, params[], help) {
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_WHITE, "You can't use this command while you are freezed.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ClearAnimations(playerid);
	return 1;
}

YCMD:hud(playerid, params[], help) {
	if(pInfo[playerid][pLevel] < 3) return SCM(playerid, -1, "You need to have level 3+ to use this command.");

	new contentStr[480], finalStr[550];
	format(contentStr, 480, ""WHITE"1\t"WHITE"Health\t%s\tnormal players\n", 
		(pInfo[playerid][pHudHealth]) ? ("{00A645}enabled") : ("{FF0000}disabled"));
	format(finalStr, 550, "#\tOption name\tStatus\tAccess\n%s",contentStr);
	ShowPlayerDialog(playerid, DIALOG_HUD, DIALOG_STYLE_TABLIST_HEADERS, "SERVER: Hud", finalStr, "Select", "Cancel");
	return 1;
}

YCMD:id(playerid, params[], help) {
	if(sscanf(params, "u", para)) return Syntax(playerid, "/id [playerid/username]");
	if(pLogged[para] == 0) return SCM(playerid, COLOR_GREY, "The specified player isn`t connected.");
	switch(pInfo[para][pMember]) { 
		case 0: SCMEx(playerid, -1, "(%d) %s | Level %d | Faction: None | Ping: %d | FPS: %d", para, GetName(para), pInfo[para][pLevel], GetPlayerPing(para), GetPlayerFPS(para));
		default: SCMEx(playerid, -1, "(%d) %s | Level %d | Faction: %s (rank %d) | Ping: %d | FPS: %d", para, GetName(para), pInfo[para][pLevel], gInfo[pInfo[para][pMember]][gName], pInfo[para][pRank], GetPlayerPing(para), FPS2[para]);
	}
	return 1;
}

YCMD:accept(playerid, params[], help) {
	if(sscanf(params, "s[30]", strPara)) return Syntax(playerid, "/accept [item]"), SCM(playerid, -1, "Items: invite, drugs, materials, gun");
	switch(YHash(strPara)) {
		case _H<invite>: {
			if(GetPVarInt(playerid, "inviteGroup") == 0) return SCM(playerid, COLOR_GREY, "You haven`t been invited in any group.");
			new name[MAX_PLAYER_NAME];
			pInfo[playerid][pMember] = GetPVarInt(playerid, "inviteGroup");
			pInfo[playerid][pRank] = 1, DeletePVar(playerid, "inviteGroup");
			pInfo[playerid][pSkin] = gInfo[pInfo[playerid][pMember]][gLeadskin], SetPlayerSkin(playerid, gInfo[pInfo[playerid][pMember]][gLeadskin]);
			pInfo[playerid][pGJoinDate] = gettime();
			GetPVarString(playerid, "inviteName", name, MAX_PLAYER_NAME);
			format(gMsg, 128, "%s is now your teammate, invited by %s.", GetName(playerid), name);
			sendGroup(COLOR_LIGHT, pInfo[playerid][pMember], gMsg);
			format(gMsg, 128, "Congratulations! Now you are %s`s member.", gInfo[pInfo[playerid][pMember]][gName]);
			ShowPlayerDialog(playerid, DIALOG_GENERAL, DIALOG_STYLE_MSGBOX, "SERVER: Invitation", gMsg, "Close", "");
			DeletePVar(playerid, "inviteName");
			SetPlayerColor(playerid, getFactionColor(pInfo[playerid][pMember]));
		}
		case _H<materials>: {
			if(smSwitch[playerid] > 0) { 
				if(pInfo[playerid][pMoney] >= smPrice[playerid]) {
					if(pInfo[smID[playerid]][pMaterials] < smMats[playerid]) return SCM(playerid, COLOR_GREY, "This player doesn't have enough materials.");
					givePlayerMoney(playerid, smPrice[playerid]);
					takePlayerMoney(smID[playerid], smPrice[playerid]);
					pInfo[smID[playerid]][pMaterials] -= smMats[playerid];
					pInfo[playerid][pMaterials] += smMats[playerid];

					smMats[playerid] = 0;
					smPrice[playerid] = 0;
					smID[playerid] = -1;
					smSwitch[playerid] = 0;
				}
				else SCM(playerid, COLOR_GREY, "You don't have enough money for this.");
			}
			else SCM(playerid, COLOR_GREY, "No one offered you any materials.");
		}
		case _H<car>: {
			new player = GetPVarInt(playerid, "sellingCarID");
			if(player == INVALID_PLAYER_ID) return SCM(playerid, COLOR_GREY, "Error: Unknown playerid/name.");
			if(GetPVarInt(player, "sellingCarTo") != playerid) return SCMEx(playerid, -1, "This player does not offered you a car.");
			if(pInfo[playerid][pMoney] < GetPVarInt(player, "sellingCarPrice")) return SCM(playerid, -1, "You don't have enough money.");
			if(!IsPlayerInRangeOfPlayer(playerid, player, 5.0)) return SCM(playerid, -1, "The vehicle owner is not near you");
			if(pcInfo[vehID[GetPlayerVehicleID(player)]][pcOwner] != pInfo[player][pSQLID]) return SCMEx(playerid, -1, "This player must be the driver of his car.");

			new car = GetPlayerVehicleID(playerid), id = vehID[car];
			
			format(szMsg, 128, "** %s sold his %s (id: %d) to %s for $%s", GetName(player), vehName[GetVehicleModel(car) - 400], car, GetName(playerid), FormatNumber(GetPVarInt(player, "sellingCarPrice")));
			nearByMessage(playerid, COLOR_PURPLE, szMsg, 15.0);
			SCMEx(player, COLOR_LIGHTBLUE, "%s has bought your %s (id: %d) for $%s.", GetName(playerid), vehName[GetVehicleModel(car) - 400], car, FormatNumber(GetPVarInt(player, "sellingCarPrice")));
			
			pInfo[playerid][pMoney] -= GetPVarInt(player, "sellingCarPrice"), pInfo[player][pMoney] += GetPVarInt(player, "sellingCarPrice");
			pcInfo[id][pcOwner] = pInfo[playerid][pSQLID];
			SetPVarInt(player, "sellingCarTo", -1);
			DeletePVar(player, "sellingCarPrice");
	    }
		case _H<drugs>: {
			if(sdSwitch[playerid] > 0) { 
				if(pInfo[playerid][pMoney] >= sdPrice[playerid]) {
					if(pInfo[sdID[playerid]][pMaterials] < sdDrugs[playerid]) return SCM(playerid, COLOR_GREY, "This player doesn't have enough drugs.");
					givePlayerMoney(playerid, sdPrice[playerid]);
					takePlayerMoney(sdID[playerid], sdPrice[playerid]);
					pInfo[sdID[playerid]][pDrugs] -= sdDrugs[playerid];
					pInfo[playerid][pDrugs] += sdDrugs[playerid];

					sdDrugs[playerid] = 0;
					sdPrice[playerid] = 0;
					sdID[playerid] = -1;
					sdSwitch[playerid] = 0;
				}
				else SCM(playerid, COLOR_GREY, "You don't have enough money for this.");
			}
			else SCM(playerid, COLOR_GREY, "No one offered you any drugs.");
		}
		case _H<gun>: {
			if(cgSwitch[playerid] > 0) { 
				if(pInfo[playerid][pMoney] >= cgPrice[playerid]) {
					if(pInfo[playerid][pGunLic] >= 1) {
						if(pInfo[cgID[playerid]][pMaterials] < cgMats[playerid]) return SCM(playerid, COLOR_GREY, "This player doesn't have enough materials.");
						GivePlayerWeapon(playerid, cgWeapon[playerid], 100);
						givePlayerMoney(playerid, cgPrice[playerid]);
						takePlayerMoney(cgID[playerid], cgPrice[playerid]);
						pInfo[cgID[playerid]][pMaterials] -= cgMats[playerid];

						cgPrice[playerid] = 0;
						cgSwitch[playerid] = 0;
						cgWeapon[playerid] = 0;
						cgID[playerid] = -1;
						cgMats[playerid] = 0;
					}
					else SCM(playerid, COLOR_GREY, "You don't have gun licence.");
				}
				else SCM(playerid, COLOR_GREY, "You don't have enough money for this.");
			}
			else SCM(playerid, COLOR_GREY, "No one offered you a weapon.");
		}
		default: {
			SCM(playerid, COLOR_GREY, "The item that you specified does not exist.");
		}
	}
	return 1;
}

YCMD:stats(playerid, params[], help) {
	showStats(playerid, playerid);
	return 1;
}

//animations:
YCMD:cheer(playerid, params[], help) {
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	if(sscanf(params, "d", para)) return Syntax(playerid, "/cheer [1-8]");
    switch(para) {
        case 1: ApplyAnimation(playerid,"ON_LOOKERS","shout_01",4.1, 1, 0, 0, 0, 0, 0); 
        case 2: ApplyAnimation(playerid,"ON_LOOKERS","shout_02",4.1, 0, 0, 0, 0, 0, 0); 
        case 3: ApplyAnimation(playerid,"ON_LOOKERS","shout_in",4.1, 0, 0, 0, 0, 0, 0); 
        case 4: ApplyAnimation(playerid,"RIOT","RIOT_ANGRY_B",4.1, 0, 0, 0, 0, 0, 0); 
        case 5: ApplyAnimation(playerid,"RIOT","RIOT_CHANT",4.1, 0, 0, 0, 0, 0, 0); 
        case 6: ApplyAnimation(playerid,"RIOT","RIOT_shout",4.1, 0, 0, 0, 0, 0, 0); 
        case 7: ApplyAnimation(playerid,"STRIP","PUN_HOLLER",4.1, 0, 0, 0, 0, 0, 0); 
        case 8: ApplyAnimation(playerid,"OTB","wtchrace_win",4.1, 0, 0, 0, 0, 0, 0); 
        default: return Syntax(playerid,"/cheer [1-8]");
    }
	return 1;
}

YCMD:sit(playerid, params[], help) {
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	if(sscanf(params, "d", para)) return Syntax(playerid, "/sit [1-5]");
    switch(para) {
        case 1: ApplyAnimation(playerid,"BEACH","bather",4.1, 0, 0, 0, 0, 0, 0);
        case 2: ApplyAnimation(playerid,"BEACH","Lay_Bac_Loop",4.1, 0, 0, 0, 0, 0, 0);
        case 3: ApplyAnimation(playerid,"BEACH","ParkSit_W_loop",4.1, 0, 0, 0, 0, 0, 0);
        case 4: ApplyAnimation(playerid,"BEACH","SitnWait_loop_W",4.1, 0, 0, 0, 0, 0, 0);
        case 5: ApplyAnimation(playerid,"BEACH","SitnWait_loop_W",4.1, 0, 0, 0, 0, 0, 0);
        case 6: ApplyAnimation(playerid,"BEACH", "ParkSit_M_loop", 4.1, 0, 0, 0, 0, 0, 0);
        default: return Syntax(playerid,"/sit [1-6]");
    }
	return 1;
}

YCMD:urinate(playerid, params[], help) {
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	SetPlayerSpecialAction(playerid, 68);
	return 1;
}

YCMD:sleep(playerid, params[], help) {
    if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    if(sscanf(params, "d", para)) return Syntax(playerid,"/sleep [1-2]");
    switch(para) {
        case 1: ApplyAnimation(playerid,"CRACK","crckdeth4",4.1, 0, 0, 0, 0, 0, 0); 
        case 2: ApplyAnimation(playerid,"CRACK","crckidle2",4.1, 0, 0, 0, 0, 0, 0); 
        default: return Syntax(playerid,"/sleep [1-2]");
    }
    return 1;
}

YCMD:seat(playerid, params[], help) {
    if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    if(sscanf(params, "d", para)) return Syntax(playerid,"/seat [1-7]");
    switch(para) {
        case 1: ApplyAnimation(playerid,"Attractors","Stepsit_in",4.1, 0, 0, 0, 0, 0, 0);// Not looping
        case 2: ApplyAnimation(playerid,"CRIB","PED_Console_Loop",4.1, 0, 0, 0, 0, 0, 0);
        case 3: ApplyAnimation(playerid,"INT_HOUSE","LOU_In",4.1, 0, 0, 0, 0, 0, 0); // Not looping
        case 4: ApplyAnimation(playerid,"MISC","SEAT_LR",4.1, 0, 0, 0, 0, 0, 0);
        case 5: ApplyAnimation(playerid,"MISC","Seat_talk_01",4.1, 0, 0, 0, 0, 0, 0);
        case 6: ApplyAnimation(playerid,"MISC","Seat_talk_02",4.1, 0, 0, 0, 0, 0, 0);
        case 7: ApplyAnimation(playerid,"ped","SEAT_down",4.1, 0, 0, 0, 0, 0, 0); // Not looping
        default: return Syntax(playerid,"/seat [1-7]");
    }
    return 1;
}

YCMD:dance(playerid, params[], help) {
    if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    if(sscanf(params, "d", para)) return Syntax(playerid,"/dance [1-4]");
    switch(para) {
        case 1: SetPlayerSpecialAction(playerid, SPECIAL_ACTION_DANCE1);
        case 2: SetPlayerSpecialAction(playerid, SPECIAL_ACTION_DANCE2);
        case 3: SetPlayerSpecialAction(playerid, SPECIAL_ACTION_DANCE3);
        case 4: SetPlayerSpecialAction(playerid, SPECIAL_ACTION_DANCE4);
        default: return Syntax(playerid,"/dance [1-4]");
    }
    return 1;
}

YCMD:cross(playerid, params[], help) {
    if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    if(sscanf(params, "d", para)) return Syntax(playerid,"/cross [1-5]");
    switch(para) {
        case 1: ApplyAnimation(playerid, "COP_AMBIENT", "Coplook_loop", 4.1, 0, 0, 0, 0, 0, 0);
        case 2: ApplyAnimation(playerid, "DEALER", "DEALER_IDLE", 4.1, 0, 0, 0, 0, 0, 0);
        case 3: ApplyAnimation(playerid, "DEALER", "DEALER_IDLE_01", 4.1, 0, 0, 0, 0, 0, 0);
        case 4: ApplyAnimation(playerid,"GRAVEYARD","mrnM_loop",4.1, 0, 0, 0, 0, 0, 0);
        case 5: ApplyAnimation(playerid,"GRAVEYARD","prst_loopa",4.1, 0, 0, 0, 0, 0, 0);
        default: return Syntax(playerid,"/cross [1-5]");
    }
    return 1;
}

YCMD:jiggy(playerid, params[], help) {
    if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    if(sscanf(params, "d", para)) return Syntax(playerid,"/jiggy [1-10]");
    switch(para) {
        case 1: ApplyAnimation(playerid,"DANCING","DAN_Down_A",4.1, 0, 0, 0, 0, 0, 0);
        case 2: ApplyAnimation(playerid,"DANCING","DAN_Left_A",4.1, 0, 0, 0, 0, 0, 0);
        case 3: ApplyAnimation(playerid,"DANCING","DAN_Loop_A",4.1, 0, 0, 0, 0, 0, 0);
        case 4: ApplyAnimation(playerid,"DANCING","DAN_Right_A",4.1, 0, 0, 0, 0, 0, 0);
        case 5: ApplyAnimation(playerid,"DANCING","DAN_Up_A",4.1, 0, 0, 0, 0, 0, 0);
        case 6: ApplyAnimation(playerid,"DANCING","dnce_M_a",4.1, 0, 0, 0, 0, 0, 0);
        case 7: ApplyAnimation(playerid,"DANCING","dnce_M_b",4.1, 0, 0, 0, 0, 0, 0);
        case 8: ApplyAnimation(playerid,"DANCING","dnce_M_c",4.1, 0, 0, 0, 0, 0, 0);
        case 9: ApplyAnimation(playerid,"DANCING","dnce_M_c",4.1, 0, 0, 0, 0, 0, 0);
        case 10: ApplyAnimation(playerid,"DANCING","dnce_M_d",4.1, 0, 0, 0, 0, 0, 0);
        default: return Syntax(playerid,"/jiggy [1-10]");
    }
    return 1;
}

YCMD:breathless(playerid, params[], help) {
    if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    if(sscanf(params, "d", para)) return Syntax(playerid,"/breathless [1-2]");
    switch(para) {
        case 1: ApplyAnimation(playerid,"PED","IDLE_tired",4.1, 0, 0, 0, 0, 0, 0);
        case 2: ApplyAnimation(playerid,"FAT","IDLE_tired",4.1, 0, 0, 0, 0, 0, 0);
        default: return Syntax(playerid,"/breathless [1-2]");
    }
    return 1;
}

YCMD:ped(playerid, params[], help) {
    if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    if(sscanf(params, "d", para)) return Syntax(playerid,"/ped [1-26]");
    switch(para) {
        case 1: ApplyAnimation(playerid,"PED","JOG_femaleA",4.1, 0, 0, 0, 0, 0, 0);
        case 2: ApplyAnimation(playerid,"PED","JOG_maleA",4.1, 0, 0, 0, 0, 0, 0);
        case 3: ApplyAnimation(playerid,"PED","WOMAN_walkfatold",4.1, 0, 0, 0, 0, 0, 0);
        case 4: ApplyAnimation(playerid,"PED","run_fat",4.1, 0, 0, 0, 0, 0, 0);
        case 5: ApplyAnimation(playerid,"PED","run_fatold",4.1, 0, 0, 0, 0, 0, 0);
        case 6: ApplyAnimation(playerid,"PED","run_old",4.1, 0, 0, 0, 0, 0, 0);
        case 7: ApplyAnimation(playerid,"PED","Run_Wuzi",4.1, 0, 0, 0, 0, 0, 0);
        case 8: ApplyAnimation(playerid,"PED","swat_run",4.1, 0, 0, 0, 0, 0, 0);
        case 9: ApplyAnimation(playerid,"PED","WALK_fat",4.1, 0, 0, 0, 0, 0, 0);
        case 10: ApplyAnimation(playerid,"PED","WALK_fatold",4.1, 0, 0, 0, 0, 0, 0);
        case 11: ApplyAnimation(playerid,"PED","WALK_gang1",4.1, 0, 0, 0, 0, 0, 0);
        case 12: ApplyAnimation(playerid,"PED","WALK_gang2",4.1, 0, 0, 0, 0, 0, 0);
        case 13: ApplyAnimation(playerid,"PED","WALK_old",4.1, 0, 0, 0, 0, 0, 0);
        case 14: ApplyAnimation(playerid,"PED","WALK_shuffle",4.1, 0, 0, 0, 0, 0, 0);
        case 15: ApplyAnimation(playerid,"PED","woman_run",4.1, 0, 0, 0, 0, 0, 0);
        case 16: ApplyAnimation(playerid,"PED","WOMAN_runbusy",4.1, 0, 0, 0, 0, 0, 0);
        case 17: ApplyAnimation(playerid,"PED","WOMAN_runfatold",4.1, 0, 0, 0, 0, 0, 0);
        case 18: ApplyAnimation(playerid,"PED","woman_runpanic",4.1, 0, 0, 0, 0, 0, 0);
        case 19: ApplyAnimation(playerid,"PED","WOMAN_runsexy",4.1, 0, 0, 0, 0, 0, 0);
        case 20: ApplyAnimation(playerid,"PED","WOMAN_walkbusy",4.1, 0, 0, 0, 0, 0, 0);
        case 21: ApplyAnimation(playerid,"PED","WOMAN_walkfatold",4.1, 0, 0, 0, 0, 0, 0);
        case 22: ApplyAnimation(playerid,"PED","WOMAN_walknorm",4.1, 0, 0, 0, 0, 0, 0);
        case 23: ApplyAnimation(playerid,"PED","WOMAN_walkold",4.1, 0, 0, 0, 0, 0, 0);
        case 24: ApplyAnimation(playerid,"PED","WOMAN_walkpro",4.1, 0, 0, 0, 0, 0, 0);
        case 25: ApplyAnimation(playerid,"PED","WOMAN_walksexy",4.1, 0, 0, 0, 0, 0, 0);
        case 26: ApplyAnimation(playerid,"PED","WOMAN_walkshop",4.1, 0, 0, 0, 0, 0, 0);
        default: return Syntax(playerid,"/ped [1-26]");
    }
    return 1;
}

YCMD:rap(playerid, params[], help) {
    if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    if(sscanf(params, "d", para)) return Syntax(playerid,"/rap [1-3]");
    switch(para) {
        case 1: ApplyAnimation(playerid,"RAPPING","RAP_A_Loop",4.1, 0, 0, 0, 0, 0, 0);
        case 2: ApplyAnimation(playerid,"RAPPING","RAP_B_Loop",4.1, 0, 0, 0, 0, 0, 0);
        case 3: ApplyAnimation(playerid,"RAPPING","RAP_C_Loop",4.1, 0, 0, 0, 0, 0, 0);
        default: return Syntax(playerid,"/rap [1-3]");
    }
    return 1;
}

YCMD:gesture(playerid, params[], help) {
    if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    if(sscanf(params, "d", para)) return Syntax(playerid,"/gesture [1-15]");
    switch(para) {
        case 1: ApplyAnimation(playerid,"GHANDS","gsign1",4.1, 0, 0, 0, 0, 0, 0);
        case 2: ApplyAnimation(playerid,"GHANDS","gsign1LH",4.1, 0, 0, 0, 0, 0, 0);
        case 3: ApplyAnimation(playerid,"GHANDS","gsign2",4.1, 0, 0, 0, 0, 0, 0);
        case 4: ApplyAnimation(playerid,"GHANDS","gsign2LH",4.1, 0, 0, 0, 0, 0, 0);
        case 5: ApplyAnimation(playerid,"GHANDS","gsign3",4.1, 0, 0, 0, 0, 0, 0);
        case 6: ApplyAnimation(playerid,"GHANDS","gsign3LH",4.1, 0, 0, 0, 0, 0, 0);
        case 7: ApplyAnimation(playerid,"GHANDS","gsign4",4.1, 0, 0, 0, 0, 0, 0);
        case 8: ApplyAnimation(playerid,"GHANDS","gsign4LH",4.1, 0, 0, 0, 0, 0, 0);
        case 9: ApplyAnimation(playerid,"GHANDS","gsign5",4.1, 0, 0, 0, 0, 0, 0);
        case 10: ApplyAnimation(playerid,"GHANDS","gsign5",4.1, 0, 0, 0, 0, 0, 0);
        case 11: ApplyAnimation(playerid,"GHANDS","gsign5LH",4.1, 0, 0, 0, 0, 0, 0);
        case 12: ApplyAnimation(playerid,"GANGS","Invite_No",4.1, 0, 0, 0, 0, 0, 0);
        case 13: ApplyAnimation(playerid,"GANGS","Invite_Yes",4.1, 0, 0, 0, 0, 0, 0);
        case 14: ApplyAnimation(playerid,"GANGS","prtial_gngtlkD",4.1, 0, 0, 0, 0, 0, 0);
        case 15: ApplyAnimation(playerid,"GANGS","smkcig_prtl",4.1, 0, 0, 0, 0, 0, 0);
        default: return Syntax(playerid,"/gesture [1-15]");
    }
    return 1;
}

YCMD:sup(playerid, params[], help) {
    if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    if(sscanf(params, "d", para)) return Syntax(playerid,"/sup [1-3]");
    switch(para) {
        case 1: ApplyAnimation(playerid,"GANGS","hndshkba",4.1, 0, 0, 0, 0, 0, 0);
        case 2: ApplyAnimation(playerid,"GANGS","hndshkda",4.1, 0, 0, 0, 0, 0, 0);
        case 3: ApplyAnimation(playerid,"GANGS","hndshkfa_swt",4.1, 0, 0, 0, 0, 0, 0);
        default: return Syntax(playerid,"/sup [1-3]");
    }
    return 1;
}

YCMD:chora(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze."); 
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling."); 
	ApplyAnimation(playerid, "COP_AMBIENT", "Coplook_watch",4.1, 0, 0, 0, 0, 0, 0); 
	return 1; 
}

YCMD:relax(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze."); 
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling."); 
	ApplyAnimation(playerid, "CRACK", "crckidle1",4.1, 0, 0, 0, 0, 0, 0); 
	return 1; 
}
YCMD:crabs(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze."); 
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling."); 
	ApplyAnimation(playerid,"MISC","Scratchballs_01",4.1, 0, 0, 0, 0, 0, 0); 
	return 1; 
}
YCMD:greeting(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze."); 
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling."); 
	ApplyAnimation(playerid,"ON_LOOKERS","Pointup_loop",4.1, 0, 0, 0, 0, 0, 0); 
	return 1; 
}
YCMD:stop(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze."); 
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling."); 
	ApplyAnimation(playerid,"PED","endchat_01",4.1, 0, 0, 0, 0, 0, 0); 
	return 1; 
}
YCMD:wash(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze."); 
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling."); 
	ApplyAnimation(playerid,"BD_FIRE","wash_up",4.1, 0, 0, 0, 0, 0, 0); 
	return 1; 
}
YCMD:mourn(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"GRAVEYARD","mrnF_loop",4.1, 0, 0, 0, 0, 0, 0); 
	return 1; 
}
YCMD:followme(playerid, params[], help) {
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"WUZI","Wuzi_follow",4.1, 0, 0, 0, 0, 0, 0); 
	return 1; 
}
YCMD:still(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"WUZI","Wuzi_stand_loop", 4.1, 0, 0, 0, 0, 0, 0); 
	return 1;
}
YCMD:hitch(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"MISC","Hiker_Pose", 4.1, 0, 0, 0, 0, 0, 0); 
	return 1; 
}
YCMD:palmbitch(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"MISC","bitchslap",4.1, 0, 0, 0, 0, 0, 0); 
	return 1; 
}
YCMD:cpranim(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"MEDIC","CPR",4.1, 0, 0, 0, 0, 0, 0); 
	return 1; 
}
YCMD:giftgiving(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"KISSING","gift_give",4.1, 0, 0, 0, 0, 0, 0); 
	return 1; 
}
YCMD:slap2(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"SWEET","sweet_ass_slap",4.1, 0, 0, 0, 0, 0, 0); 
	return 1; 
}
YCMD:drunk(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid, "PED", "WALK_DRUNK", 4.0, 1, 1, 1, 1, 0);
	return 1; 
}
YCMD:pump(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid, "BOMBER", "BOM_Plant", 4.1, 0, 0, 0, 0, 0, 0); 
	return 1; 
}
YCMD:tosteal(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"ped", "ARRESTgun", 4.1, 0, 0, 0, 0, 0, 0); 
	return 1; 
}
YCMD:laugh(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid, "RAPPING", "Laugh_01", 4.1, 0, 0, 0, 0, 0, 0); 
	return 1; 
}
YCMD:lookout(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid, "SHOP", "ROB_Shifty", 4.1, 0, 0, 0, 0, 0, 0); 
	return 1; 
}
YCMD:robman(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid, "SHOP", "ROB_Loop_Threat", 4.1, 0, 0, 0, 1, 0, 0); 
	return 1; 
}
YCMD:hide(playerid, params[], help) {
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling."); 
	ApplyAnimation(playerid, "ped", "cower",4.1, 0, 0, 0, 0, 0, 0); 
	return 1; 
}
YCMD:vomit(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid, "FOOD", "EAT_Vomit_P", 4.1, 0, 0, 0, 0, 0, 0); 
	return 1; 
}
YCMD:eat(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid, "FOOD", "EAT_Burger", 4.1, 0, 0, 0, 0, 0, 0); 
	return 1; 
}
YCMD:crack(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid, "CRACK", "crckdeth2", 4.1, 1, 0, 0, 0, 0, 0); 
	return 1; 
}
YCMD:fuck(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"PED","fucku",4.1, 0, 0, 0, 0, 0, 0); 
	return 1; 
}

YCMD:taichi(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"PARK","Tai_Chi_Loop", 4.1, 1, 0, 0, 0, 0, 0); 
	return 1; 
}

YCMD:entrenar(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"PARK","Tai_Chi_Loop", 4.1, 0, 0, 0, 0, 0, 0); 
	return 1; 
}

YCMD:carjacked1(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    ApplyAnimation(playerid,"PED","CAR_jackedLHS",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:carjacked2(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    ApplyAnimation(playerid,"PED","CAR_jackedRHS",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:handsup(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    SetPlayerSpecialAction(playerid, SPECIAL_ACTION_HANDSUP);
	return 1; 
}

YCMD:cellin(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
   	SetPlayerSpecialAction(playerid,SPECIAL_ACTION_USECELLPHONE);
	return 1; 
}

YCMD:cellout(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    SetPlayerSpecialAction(playerid,SPECIAL_ACTION_STOPUSECELLPHONE);
	return 1; 
}

YCMD:crossarms(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    ApplyAnimation(playerid, "COP_AMBIENT", "Coplook_loop", 4.1, 0, 0, 0, 1, 0, 0); // Arms crossed
	return 1; 
}

YCMD:lay(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"BEACH", "bather",4.1, 0, 0, 0, 1, 0, 0); // Lay down
	return 1; 
}

YCMD:foodeat(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid, "FOOD", "EAT_Burger", 4.1, 0, 0, 0, 0, 0, 0); // Eat Burger
	return 1; 
}

YCMD:wave(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	if(sscanf(params,"d", para)) return Syntax(playerid, "/wave [1-3]");
	switch(para) {
 		case 1: ApplyAnimation(playerid, "ON_LOOKERS", "wave_loop", 4.0, 1, 0, 0, 0, 0);
 		case 2: ApplyAnimation(playerid, "KISSING", "gfwave2", 4.0, 0, 0, 0, 0, 0);
 		case 3: ApplyAnimation(playerid, "PED", "endchat_03", 4.0, 0, 0, 0, 0, 0);
 		default: Syntax(playerid, "/wave [1-3]");
 	}
	return 1; 
}

YCMD:slapass(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid, "SWEET", "sweet_ass_slap", 4.1, 0, 0, 0, 0, 0, 0); // Ass Slapping
	return 1; 
}

YCMD:dealer(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    ApplyAnimation(playerid, "DEALER", "DEALER_DEAL", 4.1, 0, 0, 0, 0, 0, 0); // Deal Drugs
	return 1; 
}

YCMD:gro(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"BEACH", "ParkSit_M_loop", 4.1, 0, 0, 0, 0, 0, 0); // Sit
	return 1; 
}

YCMD:fucku(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"PED","fucku",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:chairsit(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"PED","SEAT_idle",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:injured(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid, "SWEET", "Sweet_injuredloop", 4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:fallback(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid, "PED","FLOOR_hit_f", 4.1, 0, 0, 0, 1, 0, 0);
	return 1; 
}

YCMD:fall(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"PED","KO_skid_front",4.1, 0, 0, 0, 1, 0, 0);
	return 1; 
}

YCMD:push(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"GANGS","shake_cara",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:akick(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"POLICE","Door_Kick",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:lowbodypush(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"GANGS","shake_carSH",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:spray(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"SPRAYCAN","spraycan_full",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:headbutt(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"WAYFARER","WF_Fwd",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:medic(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"MEDIC","CPR",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:koface(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"PED","KO_shot_face",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:kostomach(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"PED","KO_shot_stom",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:lifejump(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"PED","EV_dive",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:exhaust(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"PED","IDLE_tired",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:leftslap(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"PED","BIKE_elbowL",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:rollfall(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"PED","BIKE_fallR",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:carlock(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"PED","CAR_doorlocked_LHS",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:rcarjack1(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"PED","CAR_pulloutL_LHS",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:rcarjack2(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"PED","CAR_pulloutL_LHS",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:lcarjack1(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"PED","CAR_pulloutL_RHS",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:lcarjack2(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"PED","CAR_pullout_RHS",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:hoodfrisked(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"POLICE","crm_drgbst_01",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:lightcig(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"SMOKING","M_smk_in",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:tapcig(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"SMOKING","M_smk_tap",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:bat(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"BASEBALL","Bat_IDLE",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:box(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"GYMNASIUM","GYMshadowbox",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:lay2(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"SUNBATHE","Lay_Bac_in",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:chant(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"RIOT","RIOT_CHANT",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:finger(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"RIOT","RIOT_FUKU",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:shouting(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"RIOT","RIOT_shout",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:cop(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"SWORD","sword_block",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:elbow(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"FIGHT_D","FightD_3",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:kneekick(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"FIGHT_D","FightD_2",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:fstance(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"FIGHT_D","FightD_IDLE",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:gpunch(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"FIGHT_B","FightB_G",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:airkick(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"FIGHT_C","FightC_M",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:gkick(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"FIGHT_D","FightD_G",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:lowthrow(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"GRENADE","WEAPON_throwu",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:highthrow(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"GRENADE","WEAPON_throw",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:dealstance(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"DEALER","DEALER_IDLE",4.1, 0, 0, 0, 0, 0, 0);
	return 1; 
}

YCMD:pee(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	SetPlayerSpecialAction(playerid, 68);
	return 1; 
}

YCMD:getarrested(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    ApplyAnimation(playerid,"ped", "ARRESTgun", 4.1, 0, 0, 0, 1, 0, 0); // Gun Arrest
	return 1; 
}

YCMD:bomb(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    ApplyAnimation(playerid, "BOMBER","BOM_Plant_Loop",4.1, 0, 0, 0, 0, 0, 0); // Place Bomb
	return 1; 
}

YCMD:kiss(playerid, params[], help) { 
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
	ApplyAnimation(playerid,"KISSING","Playa_Kiss_01",4.1, 0, 0, 0, 0, 0, 0); 
	return 1; 
}

YCMD:smoke(playerid, params[], help) {
    if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    if(sscanf(params, "d", para)) return Syntax(playerid,"/smoke [1-2]");
    switch(para) {
        case 1: ApplyAnimation(playerid,"SMOKING","M_smk_in",4.1, 0, 0, 0, 0, 0, 0);
        case 2: ApplyAnimation(playerid,"SMOKING","M_smklean_loop",4.1, 0, 0, 0, 0, 0, 0);
        default: return Syntax(playerid,"/smoke [1-2]");
    }
    return 1;
}

YCMD:basket(playerid, params[], help) {
    if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    if(sscanf(params, "d", para)) return Syntax(playerid,"/basket [1-6]");
    switch(para) {
        case 1: ApplyAnimation(playerid,"BSKTBALL","BBALL_idleloop",4.1, 1, 0, 0, 0, 0, 0);
        case 2: ApplyAnimation(playerid,"BSKTBALL","BBALL_Jump_Shot",4.1, 0, 0, 0, 0, 0, 0);
        case 3: ApplyAnimation(playerid,"BSKTBALL","BBALL_pickup",4.1, 0, 0, 0, 0, 0, 0);
        case 4: ApplyAnimation(playerid,"BSKTBALL","BBALL_run",4.1, 1, 1, 1, 0, 0, 0);
        case 5: ApplyAnimation(playerid,"BSKTBALL","BBALL_def_loop",4.1, 1, 0, 0, 0, 0, 0);
        case 6: ApplyAnimation(playerid,"BSKTBALL","BBALL_Dnk",4.1, 0, 0, 0, 0, 0, 0);
        default: return Syntax(playerid,"/basket [1-6]");
    }
    return 1;
}

YCMD:gwalk(playerid, params[], help) {
    if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    if(sscanf(params, "d", para)) return Syntax(playerid,"/gwalk [1-2]");
    switch(para) {
        case 1: ApplyAnimation(playerid,"PED","WALK_gang1",4.1, 0, 0, 0, 0, 0, 0);
    	case 2: ApplyAnimation(playerid,"PED","WALK_gang2",4.1, 0, 0, 0, 0, 0, 0);
        default: return Syntax(playerid,"/gwalk [1-2]");
    }
    return 1;
}

YCMD:poli(playerid, params[], help) {
    if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    if(sscanf(params, "d", para)) return Syntax(playerid,"/poli [1-2]");
    switch(para) {
        case 1:ApplyAnimation(playerid,"POLICE","CopTraf_Come",4.1, 0, 0, 0, 0, 0, 0);
        case 2:ApplyAnimation(playerid,"POLICE","CopTraf_Stop",4.1, 0, 0, 0, 0, 0, 0);
        default: return Syntax(playerid,"/poli [1-2]");
    }
    return 1;
}

YCMD:dj(playerid, params[], help) {
    if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    if(sscanf(params, "d", para)) return Syntax(playerid,"/dj [1-4]");
    switch(para) {
        case 1: ApplyAnimation(playerid,"SCRATCHING","scdldlp",4.1, 0, 0, 0, 0, 0, 0);
        case 2: ApplyAnimation(playerid,"SCRATCHING","scdlulp",4.1, 0, 0, 0, 0, 0, 0);
        case 3: ApplyAnimation(playerid,"SCRATCHING","scdrdlp",4.1, 0, 0, 0, 0, 0, 0);
        case 4: ApplyAnimation(playerid,"SCRATCHING","scdrulp",4.1, 0, 0, 0, 0, 0, 0);
        default: return Syntax(playerid,"/dj [1-4]");
    }
    return 1;
}

YCMD:aim(playerid, params[], help) {
    if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    if(sscanf(params, "d", para)) return Syntax(playerid,"/aim [1-3]");
    switch(para) {
        case 1: ApplyAnimation(playerid,"PED","gang_gunstand",4.1, 0, 0, 0, 0, 0, 0);
	    case 2: ApplyAnimation(playerid,"PED","Driveby_L",4.1, 0, 0, 0, 0, 0, 0);
	    case 3: ApplyAnimation(playerid,"PED","Driveby_R",4.1, 0, 0, 0, 0, 0, 0);
        default: return Syntax(playerid,"/aim [1-3]");
    }
    return 1;
}

YCMD:lean(playerid, params[], help) {
    if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    if(sscanf(params, "d", para)) return Syntax(playerid,"/lean [1-2]");
    switch(para) {
        case 1: ApplyAnimation(playerid,"GANGS","leanIDLE",4.1, 0, 0, 0, 0, 0, 0);
    	case 2: ApplyAnimation(playerid,"MISC","Plyrlean_loop",4.1, 0, 0, 0, 0, 0, 0);
        default: return Syntax(playerid,"/lean [1-2]");
    }
    return 1;
}

YCMD:wank(playerid, params[], help)
{
   	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    if(sscanf(params, "d", para)) return Syntax(playerid,"/wank [1-2]");
    switch(para) {
        case 1: ApplyAnimation(playerid,"PAULNMAC","wank_in",4.1, 0, 0, 0, 0, 0, 0);
    	case 2: ApplyAnimation(playerid,"PAULNMAC","wank_loop",4.1, 0, 0, 0, 0, 0, 0);
        default: return Syntax(playerid,"/wank [1-2]");
    }
    return 1;
}

YCMD:inbedright(playerid, params[], help)//94
{
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    ApplyAnimation(playerid,"INT_HOUSE","BED_Loop_R",4.1, 0, 0, 0, 0, 0, 0);
    return 1;
}

YCMD:inbedleft(playerid, params[], help)//95
{
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    ApplyAnimation(playerid,"INT_HOUSE","BED_Loop_L",4.1, 0, 0, 0, 0, 0, 0);
    return 1;
}

YCMD:stand(playerid, params[], help)//95
{
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    ApplyAnimation(playerid,"WUZI","Wuzi_stand_loop", 4.1, 0, 0, 0, 0, 0, 0);
    return 1;
}

YCMD:slapped(playerid, params[], help)
{
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    ApplyAnimation(playerid,"SWEET","ho_ass_slapped",4.1, 0, 0, 0, 0, 0, 0);
    return 1;
}

YCMD:getup(playerid, params[], help)//95
{
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    ApplyAnimation(playerid,"PED","getup",4.1, 0, 0, 0, 0, 0, 0);
    return 1;
}

YCMD:follow(playerid, params[], help)//95
{
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    ApplyAnimation(playerid,"WUZI","Wuzi_follow",4.1, 0, 0, 0, 0, 0, 0);
    return 1;
}

YCMD:strip(playerid, params[], help) {
    if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    if(sscanf(params, "d", para)) return Syntax(playerid,"/strip [1-7]");
    switch(para) {
       	case 1: ApplyAnimation(playerid,"STRIP", "strip_A", 4.1, 0, 0, 0, 0, 0, 0 );
	    case 2: ApplyAnimation(playerid,"STRIP", "strip_B", 4.1, 0, 0, 0, 0, 0, 0 );
	    case 3: ApplyAnimation(playerid,"STRIP", "strip_C", 4.1, 0, 0, 0, 0, 0, 0 );
	    case 4: ApplyAnimation(playerid,"STRIP", "strip_D", 4.1, 0, 0, 0, 0, 0, 0 );
	    case 5: ApplyAnimation(playerid,"STRIP", "strip_E", 4.1, 0, 0, 0, 0, 0, 0 );
	    case 6: ApplyAnimation(playerid,"STRIP", "strip_F", 4.1, 0, 0, 0, 0, 0, 0 );
	    case 7: ApplyAnimation(playerid,"STRIP", "strip_G", 4.1, 0, 0, 0, 0, 0, 0 );
        default: return Syntax(playerid,"/strip [1-7]");
    }
    return 1;
}

YCMD:sexy(playerid, params[], help) {
    if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    if(sscanf(params, "d", para)) return Syntax(playerid,"/strip [1-8]");
    switch(para) {
       	case 1: ApplyAnimation(playerid,"SNM","SPANKING_IDLEW",4.1, 0, 0, 0, 0, 0, 0);
	    case 2: ApplyAnimation(playerid,"SNM","SPANKING_IDLEP",4.1, 0, 0, 0, 0, 0, 0);
	    case 3: ApplyAnimation(playerid,"SNM","SPANKINGW",4.1, 0, 0, 0, 0, 0, 0);
	    case 4: ApplyAnimation(playerid,"SNM","SPANKINGP",4.1, 0, 0, 0, 0, 0, 0);
	    case 5: ApplyAnimation(playerid,"SNM","SPANKEDW",4.1, 0, 0, 0, 0, 0, 0);
	    case 6: ApplyAnimation(playerid,"SNM","SPANKEDP",4.1, 0, 0, 0, 0, 0, 0);
	    case 7: ApplyAnimation(playerid,"SNM","SPANKING_ENDW",4.1, 0, 0, 0, 0, 0, 0);
	    case 8: ApplyAnimation(playerid,"SNM","SPANKING_ENDP",4.1, 0, 0, 0, 0, 0, 0);
        default: return Syntax(playerid,"/strip [1-8]");
    }
    return 1;
}

YCMD:bj(playerid, params[], help) {
    if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    if(sscanf(params, "d", para)) return Syntax(playerid,"/bj [1-4]");
    switch(para) {
       	case 1: ApplyAnimation(playerid,"BLOWJOBZ","BJ_COUCH_START_P",4.1, 0, 0, 0, 0, 0, 0);
	    case 2: ApplyAnimation(playerid,"BLOWJOBZ","BJ_COUCH_START_W",4.1, 0, 0, 0, 0, 0, 0);
	    case 3: ApplyAnimation(playerid,"BLOWJOBZ","BJ_COUCH_LOOP_P",4.1, 0, 0, 0, 0, 0, 0);
	    case 4: ApplyAnimation(playerid,"BLOWJOBZ","BJ_COUCH_LOOP_W",4.1, 0, 0, 0, 0, 0, 0);
        default: return Syntax(playerid,"/bj [1-4]");
    }
    return 1;
}

YCMD:chat(playerid, params[], help) {
    if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    if(sscanf(params, "d", para)) return Syntax(playerid,"/chat [1-2]");
    switch(para) {
        case 1: ApplyAnimation(playerid,"PED","IDLE_CHAT",4.1, 0, 0, 0, 0, 0, 0);
        case 2: ApplyAnimation(playerid,"MISC","Idle_Chat_02",4.1, 0, 0, 0, 0, 0, 0);
        default: return Syntax(playerid,"/chat [1-2]");
    }
    return 1;
}

YCMD:thankyou(playerid, params[], help)
{
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    ApplyAnimation(playerid,"FOOD","SHP_Thank", 4.1, 0, 0, 0, 0, 0, 0);
    return 1;
}

YCMD:deal(playerid, params[], help) {
    if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    if(sscanf(params, "d", para)) return Syntax(playerid,"/deal [1-2]");
    switch(para) {
        case 1: ApplyAnimation(playerid, "DEALER", "DEALER_DEAL", 4.1, 0, 0, 0, 0, 0, 0);
        case 2: ApplyAnimation(playerid,"DEALER","DRUGS_BUY", 4.1, 0, 0, 0, 0, 0, 0);
        default: return Syntax(playerid,"/deal [1-2]");
    }
    return 1;
}

YCMD:invite1(playerid, params[], help) {
    if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    if(sscanf(params, "d", para)) return Syntax(playerid,"/invite1 [1-2]");
    switch(para) {
        case 1: ApplyAnimation(playerid,"GANGS","Invite_Yes",4.1, 0, 0, 0, 0, 0, 0);
        case 2: ApplyAnimation(playerid,"GANGS","Invite_No",4.1, 0, 0, 0, 0, 0, 0);
        default: return Syntax(playerid,"/invite1 [1-2]");
    }
    return 1;
}

YCMD:checkout(playerid, params[], help)
{
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    ApplyAnimation(playerid, "GRAFFITI", "graffiti_Chkout", 4.1, 0, 0, 0, 0, 0, 0);
    return 1;
}

YCMD:nod(playerid, params[], help)
{
   	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    ApplyAnimation(playerid,"COP_AMBIENT","Coplook_nod",4.1, 0, 0, 0, 0, 0, 0);
    return 1;
}

YCMD:carsmoke(playerid, params[], help)
{
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    ApplyAnimation(playerid,"PED","Smoke_in_car", 4.1, 0, 0, 0, 0, 0, 0);
    return 1;
}

YCMD:angry(playerid, params[], help)
{
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    ApplyAnimation(playerid,"RIOT","RIOT_ANGRY",4.1, 0, 0, 0, 0, 0, 0);
    return 1;
}
YCMD:benddown(playerid, params[], help)
{
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    ApplyAnimation(playerid, "BAR", "Barserve_bottle", 4.1, 0, 0, 0, 0, 0, 0);
    return 1;
}
YCMD:shakehead(playerid, params[], help)
{
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    ApplyAnimation(playerid, "MISC", "plyr_shkhead", 4.1, 0, 0, 0, 0, 0, 0);
    return 1;
}
YCMD:cockgun(playerid, params[], help)
{
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    ApplyAnimation(playerid, "SILENCED", "Silence_reload", 4.1, 0, 0, 0, 0, 0, 0);
    return 1;
}

YCMD:scratch(playerid, params[], help)
{
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    ApplyAnimation(playerid,"MISC","Scratchballs_01", 4.1, 0, 0, 0, 0, 0, 0);
    return 1;
}

YCMD:liftup(playerid, params[], help)
{
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    ApplyAnimation(playerid, "CARRY", "liftup", 4.1, 0, 0, 0, 0, 0, 0);
    return 1;
}

YCMD:putdown(playerid, params[], help)
{
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    ApplyAnimation(playerid, "CARRY", "putdwn", 4.1, 0, 0, 0, 0, 0, 0);
    return 1;
}

YCMD:joint(playerid, params[], help)
{
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    ApplyAnimation(playerid,"GANGS","smkcig_prtl",4.1, 0, 0, 0, 0, 0, 0);
    return 1;
}

YCMD:yes(playerid, params[], help)
{
	if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    ApplyAnimation(playerid,"CLOTHES","CLO_Buy", 4.1, 0, 0, 0, 0, 0, 0);
    return 1;
}

YCMD:win(playerid, params[], help) {
    if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    if(sscanf(params, "d", para)) return Syntax(playerid,"/win [1-2]");
    switch(para) {
        case 1: ApplyAnimation(playerid,"CASINO","cards_win", 4.1, 0, 0, 0, 0, 0, 0);
        case 2: ApplyAnimation(playerid,"CASINO","Roulette_win", 4.1, 0, 0, 0, 0, 0, 0);
        default: return Syntax(playerid,"/win [1-2]");
    }
    return 1;
}

YCMD:cry(playerid, params[], help) {
    if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    if(sscanf(params, "d", para)) return Syntax(playerid,"/cry [1-2]");
    switch(para) {
        case 1: ApplyAnimation(playerid,"GRAVEYARD","mrnF_loop", 4.1, 0, 0, 0, 0, 0, 0);
        case 2: ApplyAnimation(playerid,"GRAVEYARD","mrnM_loop", 4.1, 0, 0, 0, 0, 0, 0);
        default: return Syntax(playerid,"/cry [1-2]");
    }
    return 1;
}

YCMD:celebrate(playerid, params[], help) {
    if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    if(sscanf(params, "d", para)) return Syntax(playerid,"/celebrate [1-2]");
    switch(para) {
        case 1: ApplyAnimation(playerid,"benchpress","gym_bp_celebrate", 4.1, 0, 0, 0, 0, 0, 0);
        case 2: ApplyAnimation(playerid,"GYMNASIUM","gym_tread_celebrate", 4.1, 0, 0, 0, 0, 0, 0);
        default: return Syntax(playerid,"/celebrate [1-2]");
    }
    return 1;
}

YCMD:bed(playerid, params[], help) {
    if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    if(sscanf(params, "d", para)) return Syntax(playerid,"/bed [1-4]");
    switch(para) {
        case 1: ApplyAnimation(playerid,"INT_HOUSE","BED_In_L",4.1, 0, 0, 0, 0, 0, 0);
        case 2: ApplyAnimation(playerid,"INT_HOUSE","BED_In_R",4.1, 0, 0, 0, 0, 0, 0);
        case 3: ApplyAnimation(playerid,"INT_HOUSE","BED_Loop_L", 4.1, 0, 0, 0, 0, 0, 0);
        case 4: ApplyAnimation(playerid,"INT_HOUSE","BED_Loop_R", 4.1, 0, 0, 0, 0, 0, 0);
        default: return Syntax(playerid,"/bed [1-4]");
    }
    return 1;
}

YCMD:bar(playerid, params[], help) {
    if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    if(sscanf(params, "d", para)) return Syntax(playerid, "/bar [1-5]");
    switch(para) {
        case 1: ApplyAnimation(playerid, "BAR", "Barcustom_get", 4.1, 0, 0, 0, 0, 0, 0);
        case 2: ApplyAnimation(playerid,"GHANDS","gsign2LH",4.1, 0, 0, 0, 0, 0, 0);
        case 3: ApplyAnimation(playerid, "BAR", "Barcustom_order", 4.1, 0, 0, 0, 0, 0, 0);
        case 4: ApplyAnimation(playerid, "BAR", "Barserve_give", 4.1, 0, 0, 0, 0, 0, 0);
        case 5: ApplyAnimation(playerid, "BAR", "Barserve_glass", 4.1, 0, 0, 0, 0, 0, 0);
        default: return Syntax(playerid,"/bar [1-5]");
    }
    return 1;
}

YCMD:lranim(playerid, params[], help) {
	if(!IsInLowRider(playerid)) return SCM(playerid, COLOR_GREY, "You must be in a compatible lowrider vehicle to use this command!");
    if(sscanf(params, "i", para)) return Syntax(playerid, "/lranim [0-36]");
    if(GetPlayerState(playerid) != PLAYER_STATE_DRIVER) return SCM(playerid, COLOR_GREY, "You need to be the driver of the vehicle!");
    switch(para) {
    	case 0:ApplyAnimation(playerid, "LOWRIDER", "F_smklean_loop", 4.0, 1, 0, 0, 0, 0, 1);
        case 1: ApplyAnimation(playerid, "LOWRIDER", "lrgirl_bdbnce", 4.0, 0, 0, 0, 1, 0, 1);
        case 2: ApplyAnimation(playerid, "LOWRIDER", "lrgirl_hair", 4.0, 1, 0, 0, 0, 0, 1);
        case 3: ApplyAnimation(playerid, "LOWRIDER", "lrgirl_hurry", 4.0, 1, 0, 0, 0, 0, 1);
        case 4: ApplyAnimation(playerid, "LOWRIDER", "lrgirl_idleloop", 4.0, 1, 0, 0, 0, 0, 1);
        case 5: ApplyAnimation(playerid, "LOWRIDER", "lrgirl_idle_to_l0", 4.0, 0, 0, 0, 1, 0, 1);
        case 6: ApplyAnimation(playerid, "LOWRIDER", "lrgirl_l0_bnce", 4.0, 1, 0, 0, 0, 0, 1);
        case 7: ApplyAnimation(playerid, "LOWRIDER", "lrgirl_l0_loop", 4.0, 1, 0, 0, 0, 0, 1);
        case 8: ApplyAnimation(playerid, "LOWRIDER", "lrgirl_l0_to_l1", 4.0, 0, 0, 0, 1, 0, 1);
        case 9: ApplyAnimation(playerid, "LOWRIDER", "lrgirl_l12_to_l0", 4.0, 0, 0, 0, 1, 0, 1);
        case 10: ApplyAnimation(playerid, "LOWRIDER", "lrgirl_l1_bnce", 4.0, 1, 0, 0, 0, 0, 1);
        case 11: ApplyAnimation(playerid, "LOWRIDER", "lrgirl_l1_loop", 4.0, 1, 0, 0, 0, 0, 1);
        case 12: ApplyAnimation(playerid, "LOWRIDER", "lrgirl_l1_to_l2", 4.0, 1, 0, 0, 0, 0, 1);
        case 13: ApplyAnimation(playerid, "LOWRIDER", "lrgirl_l2_bnce", 4.0, 1, 0, 0, 0, 0, 1);
        case 14: ApplyAnimation(playerid, "LOWRIDER", "lrgirl_l2_loop", 4.0, 1, 0, 0, 0, 0, 1);
        case 15: ApplyAnimation(playerid, "LOWRIDER", "lrgirl_l2_to_l3", 4.0, 0, 0, 0, 1, 0, 1);
        case 16: ApplyAnimation(playerid, "LOWRIDER", "lrgirl_l345_to_l1", 4.0, 0, 0, 0, 1, 0, 1);
        case 17: ApplyAnimation(playerid, "LOWRIDER", "lrgirl_l3_bnce", 4.0, 1, 0, 0, 0, 0, 1);
        case 18: ApplyAnimation(playerid, "LOWRIDER", "lrgirl_l3_loop", 4.0, 1, 0, 0, 0, 0, 1);
        case 19: ApplyAnimation(playerid, "LOWRIDER", "lrgirl_l3_to_l4", 4.0, 1, 0, 0, 0, 0, 1);
        case 20: ApplyAnimation(playerid, "LOWRIDER", "lrgirl_l4_bnce", 4.0, 1, 0, 0, 0, 0, 1);
        case 21: ApplyAnimation(playerid, "LOWRIDER", "lrgirl_l4_loop", 4.0, 1, 0, 0, 0, 0, 1);
        case 22: ApplyAnimation(playerid, "LOWRIDER", "lrgirl_l4_to_l5", 4.0, 0, 0, 0, 1, 0, 1);
        case 23: ApplyAnimation(playerid, "LOWRIDER", "lrgirl_l5_bnce", 4.0, 1, 0, 0, 0, 0, 1);
        case 24: ApplyAnimation(playerid, "LOWRIDER", "lrgirl_l5_loop", 4.0, 1, 0, 0, 0, 0, 1);
        case 25: ApplyAnimation(playerid, "LOWRIDER", "M_smklean_loop", 4.0, 1, 0, 0, 0, 0, 1);
        case 26: ApplyAnimation(playerid, "LOWRIDER", "prtial_gngtlkB", 4.0, 1, 0, 0, 0, 0, 1);
        case 27: ApplyAnimation(playerid, "LOWRIDER", "prtial_gngtlkC", 4.0, 1, 0, 0, 0, 0, 1);
        case 28: ApplyAnimation(playerid, "LOWRIDER", "prtial_gngtlkD", 4.0, 1, 0, 0, 0, 0, 1);
        case 29: ApplyAnimation(playerid, "LOWRIDER", "prtial_gngtlkF", 4.0, 1, 0, 0, 0, 0, 1);
        case 30: ApplyAnimation(playerid, "LOWRIDER", "prtial_gngtlkG", 4.0, 1, 0, 0, 0, 0, 1);
        case 31: ApplyAnimation(playerid, "LOWRIDER", "prtial_gngtlkH", 4.0, 1, 0, 0, 0, 0, 1);
        case 32: ApplyAnimation(playerid, "LOWRIDER", "RAP_A_Loop", 4.0, 1, 0, 0, 0, 0, 1);
        case 33: ApplyAnimation(playerid, "LOWRIDER", "RAP_B_Loop", 4.0, 1, 0, 0, 0, 0, 1);
        case 34: ApplyAnimation(playerid, "LOWRIDER", "RAP_C_Loop", 4.0, 1, 0, 0, 0, 0, 1);
        case 35: ApplyAnimation(playerid, "LOWRIDER", "Sit_relaxed", 4.0, 1, 0, 0, 0, 0, 1);
        case 36: ApplyAnimation(playerid, "LOWRIDER", "Tap_hand", 4.0, 1, 0, 0, 0, 0, 1);
    }
	return 1;
}

YCMD:die(playerid, params[], help) {
    if(Freeze[playerid] == true) return SCM(playerid, COLOR_GREY, "You can't use this command while you are freeze.");
	if(IsPlayerFalling(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this command while you are falling.");
    if(sscanf(params, "d", para)) return Syntax(playerid,"/die [1-2]");
    switch(para) {
        case 1: ApplyAnimation(playerid,"KNIFE","KILL_Knife_Ped_Die",4.1, 0, 0, 0, 0, 0, 0);
        case 2: ApplyAnimation(playerid, "PARACHUTE", "FALL_skyDive_DIE", 4.1, 0, 0, 0, 0, 0, 0);
        default: return Syntax(playerid,"/die [1-2]");
    }
    return 1;
}

public OnPlayerClickTextDraw(playerid, Text:clickedid) {
	if(clickedid == Text:INVALID_TEXT_DRAW) {
		if(buyCarSession[playerid] == 1) {
			buyCarSession[playerid] = 0;
			for(new td; td < 16; td++) { PlayerTextDrawHide(playerid, dsTextdraw[playerid][td]); }
			DestroyVehicle(dsCar[playerid]);
			SetPlayerPos(playerid, 2131.6790,-1150.6421,24.1334);
			SetPlayerInterior(playerid, 0), SetPlayerVirtualWorld(playerid, 0), SetCameraBehindPlayer(playerid);
		}
	}
	return 1;
}

public OnPlayerClickPlayerTextDraw(playerid, PlayerText:playertextid)
{
	if(playertextid == dsTextdraw[playerid][6]) {
		if(dsLastCam[playerid] == 1) {  
			SetPlayerCameraPos(playerid, -1667.654541, 1203.107543, 23.343799);
			SetPlayerCameraLookAt(playerid, -1664.795288, 1206.415039, 20.917928);
			dsLastCam[playerid] = 2;
		}
		else if(dsLastCam[playerid] == 2) {  
			SetPlayerCameraPos(playerid, -1654.318725, 1205.473144, 22.844400);
			SetPlayerCameraLookAt(playerid, -1658.602783, 1207.493530, 21.242673);
			dsLastCam[playerid] = 3;
		}
		else if(dsLastCam[playerid] == 3) {  
			SetPlayerCameraPos(playerid, -1654.318725, 1205.473144, 22.844400);
			SetPlayerCameraLookAt(playerid, -1658.602783, 1207.493530, 21.242673);
			dsLastCam[playerid] = 4;
		}
		else if(dsLastCam[playerid] == 4) {  
			SetPlayerCameraPos(playerid, -1661.796142, 1221.463745, 22.785600);
			SetPlayerCameraLookAt(playerid, -1661.581176, 1216.666503, 21.392564);
			dsLastCam[playerid] = 1;
		}
		return 1;
	}
	
	else if(playertextid == dsTextdraw[playerid][3]) {
		if(dsLastID[playerid] == Iter_Last(dealerVehicles)) {
			DestroyVehicle(dsCar[playerid]);
			dsCar[playerid] = CreateVehicle(dInfo[Iter_First(dealerVehicles)][dModel], -1663.7202,1209.1276,20.8840,316.3510, 1, 1, -1);
			SetVehicleVirtualWorld(dsCar[playerid], playerid + 1), dsLastID[playerid] = Iter_First(dealerVehicles);
			PlayerPlaySound(playerid,1057,0.0,0.0,0.0);
		}
		else {
			DestroyVehicle(dsCar[playerid]);
			dsCar[playerid] = CreateVehicle(dInfo[Iter_Next(dealerVehicles, dsLastID[playerid])][dModel], -1663.7202,1209.1276,20.8840,316.3510, 1, 1, -1);
			SetVehicleVirtualWorld(dsCar[playerid], playerid + 1);
			dsLastID[playerid] = Iter_Next(dealerVehicles, dsLastID[playerid]);
		}
		format(gMsg, 50, "~g~%s", vehName[dInfo[dsLastID[playerid]][dModel] - 400]), PlayerTextDrawSetString(playerid, dsTextdraw[playerid][12], gMsg);
		if(dInfo[dsLastID[playerid]][dPrice] > 0) { format(gMsg, 50, "~y~Price: ~w~%s", FormatNumber(dInfo[dsLastID[playerid]][dPrice])), PlayerTextDrawSetString(playerid, dsTextdraw[playerid][13], gMsg); }
		else  { format(gMsg, 50, "~y~Price: ~w~%spp", FormatNumber(dInfo[dsLastID[playerid]][dPremiumPrice])), PlayerTextDrawSetString(playerid, dsTextdraw[playerid][13], gMsg); }
		format(gMsg, 50, "~y~Stock: ~w~%d cars", dInfo[dsLastID[playerid]][dStock]), PlayerTextDrawSetString(playerid, dsTextdraw[playerid][14], gMsg);
		PlayerTextDrawSetPreviewModel(playerid, dsTextdraw[playerid][15], dInfo[dsLastID[playerid]][dModel]), PlayerTextDrawShow(playerid, dsTextdraw[playerid][15]);
	}
	else if(playertextid == dsTextdraw[playerid][2]) {
		if(dsLastID[playerid] == Iter_First(dealerVehicles)) {
			DestroyVehicle(dsCar[playerid]);
			dsCar[playerid] = CreateVehicle(dInfo[Iter_Last(dealerVehicles)][dModel], -1663.7202,1209.1276,20.8840,316.3510, 1, 1, -1);
			SetVehicleVirtualWorld(dsCar[playerid], playerid + 1), dsLastID[playerid] = Iter_Last(dealerVehicles);
			PlayerPlaySound(playerid,1057,0.0,0.0,0.0);
		}
		else {
			DestroyVehicle(dsCar[playerid]);
			dsCar[playerid] = CreateVehicle(dInfo[Iter_Prev(dealerVehicles, dsLastID[playerid])][dModel], -1663.7202,1209.1276,20.8840,316.3510, 1, 1, -1);
			SetVehicleVirtualWorld(dsCar[playerid], playerid + 1);
			dsLastID[playerid] = Iter_Prev(dealerVehicles, dsLastID[playerid]);
		}
		format(gMsg, 50, "~g~%s", vehName[dInfo[dsLastID[playerid]][dModel] - 400]), PlayerTextDrawSetString(playerid, dsTextdraw[playerid][12], gMsg);
		if(dInfo[dsLastID[playerid]][dPrice] > 0) { format(gMsg, 50, "~y~Price: ~w~%s", FormatNumber(dInfo[dsLastID[playerid]][dPrice])), PlayerTextDrawSetString(playerid, dsTextdraw[playerid][13], gMsg); }
		else  { format(gMsg, 50, "~y~Price: ~w~%spp", FormatNumber(dInfo[dsLastID[playerid]][dPremiumPrice])), PlayerTextDrawSetString(playerid, dsTextdraw[playerid][13], gMsg); }
		format(gMsg, 50, "~y~Stock: ~w~%d cars", dInfo[dsLastID[playerid]][dStock]), PlayerTextDrawSetString(playerid, dsTextdraw[playerid][14], gMsg);
		PlayerTextDrawSetPreviewModel(playerid, dsTextdraw[playerid][15], dInfo[dsLastID[playerid]][dModel]), PlayerTextDrawShow(playerid, dsTextdraw[playerid][15]);
	}
	else if(playertextid == dsTextdraw[playerid][5]) {
		if(personalCount(playerid) >= pInfo[playerid][pMaxSlots]) return SCMEx(playerid, COLOR_RED, "You have reached the maximum number of vehicles which you can have (%d/%d).", personalCount(playerid), pInfo[playerid][pMaxSlots]);
		if((dInfo[dsLastID[playerid]][dType] == 1) && (pInfo[playerid][pMoney] < dInfo[dsLastID[playerid]][dPrice])) return SCMEx(playerid, COLOR_GREY, "You need %s$ more to buy this car.", FormatNumber(dInfo[dsLastID[playerid]][dPrice]-pInfo[playerid][pMoney]));
		else if((dInfo[dsLastID[playerid]][dType] == 2) && (pInfo[playerid][pLoyalityPoints] < dInfo[dsLastID[playerid]][dPremiumPrice])) return SCMEx(playerid, COLOR_GREY, "You need %spp more to buy this car.", FormatNumber(dInfo[dsLastID[playerid]][dPremiumPrice]-pInfo[playerid][pLoyalityPoints]));
		new rand = random(sizeof(randomDSPositions)), gQuery[456];
		mysql_format(handle, gQuery, 256, "INSERT INTO `personalcars` (`Owner`, `Model`, `PosX`, `PosY`, `PosZ`, `PosA`, `Color1`, `Color2`, `LockStatus`, `Age`, `Insurance`) VALUES ('%d', '%d', '%f', '%f', '%f', '%f', '0', '0', '1', '%d', '15')", pInfo[playerid][pSQLID], dInfo[dsLastID[playerid]][dModel], randomDSPositions[rand][0], randomDSPositions[rand][1], randomDSPositions[rand][2], randomDSPositions[rand][3], gettime()); 
		mysql_tquery(handle, gQuery, "buyCar", "iiffff", playerid, dInfo[dsLastID[playerid]][dModel], randomDSPositions[rand][0], randomDSPositions[rand][1], randomDSPositions[rand][2], randomDSPositions[rand][3]);
		format(gMsg, 128, "Dealership: %s bought a %s from dealership, type: %s", GetName(playerid), vehName[dInfo[dsLastID[playerid]][dModel] - 400], (dInfo[dsLastID[playerid]][dPrice] == 0) ? ("premium car.") : ("normal car."));
		sendAdmins(0xFF9100FF, gMsg);
		
		if(dInfo[dsLastID[playerid]][dType] == 1) { SCMEx(playerid, COLOR_TEAL, "(-) {FFFFFF}You have bought a %s from dealership for %s$.", vehName[dInfo[dsLastID[playerid]][dModel] - 400], FormatNumber(dInfo[dsLastID[playerid]][dPrice])), pInfo[playerid][pMoney] -= dInfo[dsLastID[playerid]][dPrice]; }
		else if(dInfo[dsLastID[playerid]][dType] == 2) { 
			SCMEx(playerid, COLOR_TEAL, "(-) {FFFFFF}You have bought a premium car (%s) from dealership for %s premium points.", vehName[dInfo[dsLastID[playerid]][dModel] - 400], FormatNumber(dInfo[dsLastID[playerid]][dPremiumPrice])), pInfo[playerid][pLoyalityPoints] -= dInfo[dsLastID[playerid]][dPremiumPrice]; 
		}
		
		buyCarSession[playerid] = 0;
		for(new td; td < 16; td++) { PlayerTextDrawHide(playerid, dsTextdraw[playerid][td]); }
		DestroyVehicle(dsCar[playerid]);
		SetPlayerPos(playerid, 2131.6790,-1150.6421,24.1334);
		SetPlayerInterior(playerid, 0), SetPlayerVirtualWorld(playerid, 0), SetCameraBehindPlayer(playerid), CancelSelectTextDraw(playerid);
	}
	return 1;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger) {
	if(!ispassenger) {
		if((vInfo[svrVeh[vehicleid]][vGroup] > 0 && pInfo[playerid][pMember] != vInfo[svrVeh[vehicleid]][vGroup])  && pInfo[playerid][pAdmin] < 6) {
			new Float:x, Float:y, Float:z;
			GetPlayerPos(playerid, x, y, z), SetPlayerPos(playerid, x, y, z+2);
			SCMEx(playerid, -1, "This "SBLUE"%s "WHITE"can be used only be %s`s members!", vehName[GetVehicleModel(vehicleid) - 400], gInfo[vInfo[svrVeh[vehicleid]][vGroup]][gName]);
		}
		else if(gInfo[vInfo[vehicleid][vGroup]][gType] == 1 && pInfo[playerid][pDuty] == 0) {
			new Float:x, Float:y, Float:z;
			GetPlayerPos(playerid, x, y, z), SetPlayerPos(playerid, x, y, z+2);
			SCM(playerid, COLOR_BLUE, "To use faction vehicles you need to be on-duty!");
		}
	}
	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid) {

	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate) {
	new engine, lights, alarm, doors, bonnet, boot, objective;
	new veh = GetPlayerVehicleID(playerid);
	//new plane = GetVehicleModel(veh);

	if(oldstate == PLAYER_STATE_DRIVER || oldstate == PLAYER_STATE_PASSENGER)
	{
		for(new tds; tds < 7; tds++) {
			PlayerTextDrawHide(playerid, speedTD[playerid][tds]);
		}
	}

	if(oldstate == PLAYER_STATE_DRIVER)
	{
		for(new tds; tds < 7; tds++) {
			PlayerTextDrawHide(playerid, speedTD[playerid][tds]);
		}

		if(DMVTest[playerid] == 1 && pInfo[playerid][pCarLic] == 0) {
			PlayerTextDrawHide(playerid, examTD[playerid]);
			DestroyVehicle(DMVVehicle[playerid]), DestroyObject(DMVObject[playerid]);
			PenaltyPoints[playerid] = DMVTest[playerid] = DMVCP[playerid] = 0, DMVVehicle[playerid] = -1;
			SCM(playerid, COLOR_GREEN, "Instructor: {C2C3C4}You failed the driving test because you`ve left the car.");
			DisablePlayerRaceCheckpoint(playerid), SetPlayerVirtualWorld(playerid, 0);
		}

		if(Checkpoint[playerid] == 2) {
			DisablePlayerCheckpoint(playerid), Checkpoint[playerid] = 0, DestroyVehicle(jobVehicle[playerid]), jobVehicle[playerid] = -1;
			DestroyPlayerObject(playerid, armsObject[playerid][0]), DestroyPlayerObject(playerid, armsObject[playerid][1]), DestroyPlayerObject(playerid, armsObject[playerid][2]);

			SCM(playerid, COLOR_SBLUE, "Job Info: "WHITE"Job failed, you will not receive your materials.");
		}
	}

    if(IsABike(veh)) {
		GetVehicleParamsEx(veh, engine, lights, alarm, doors, bonnet, boot, objective);
		SetVehicleParamsEx(veh, VEHICLE_PARAMS_ON,lights, alarm, doors, bonnet, boot, objective);
	}

	if(newstate == PLAYER_STATE_DRIVER || newstate == PLAYER_STATE_PASSENGER) {

		if(vehID[veh] == 0) {
			PlayerTextDrawSetString(playerid, speedTD[playerid][3], "door is unlocked");
			PlayerTextDrawBoxColor(playerid, speedTD[playerid][3], 0x0DB5072A);
		}
		else {
			if(pcInfo[vehID[veh]][pcLockStatus] == 0) {
				PlayerTextDrawBoxColor(playerid, speedTD[playerid][3], 0x0DB5072A);
				PlayerTextDrawSetString(playerid, speedTD[playerid][3], "door is unlocked");
			}
			else {
				PlayerTextDrawBoxColor(playerid, speedTD[playerid][3], 0xFF00002A);
				PlayerTextDrawSetString(playerid, speedTD[playerid][3], "door is locked");
			}
		}

		for(new tds; tds < 7; tds++) {
			if((tds == 5 || tds == 4) && vehID[veh] == 0) continue;
			PlayerTextDrawShow(playerid, speedTD[playerid][tds]);
		}
	}

	if(newstate == PLAYER_STATE_DRIVER) {
		if(GetPlayerWeapon(playerid) != 0) { 
			SetPlayerArmedWeapon(playerid, 0);
		}

		if((GetTickCount()-GetPVarInt(playerid, "carSpamCount")) < 1000) 
        {
            SetPVarInt(playerid, "carSpamCount", GetPVarInt(playerid, "carSpamCount")+1);
            if(GetPVarInt(playerid, "carSpamCount") >= 5 && pInfo[playerid][pAdmin] == 0) 
            {
                new string[128];
                format(string, 128,"Kick: %s has been kicked by AdmBot, reason: Cheats (#vehicletp).", GetName(playerid));
               	SendClientMessageToAll(COLOR_LIGHTRED, string), defer kickTimer(playerid);
            }
        }
        SetPVarInt(playerid, "carSpamCount", GetTickCount());

		if(vehID[veh] == 0) {
			PlayerTextDrawSetString(playerid, speedTD[playerid][3], "door is unlocked");
			PlayerTextDrawBoxColor(playerid, speedTD[playerid][3], 0x0DB5072A);
		}
		else {
			if(pcInfo[vehID[veh]][pcLockStatus] == 0) {
				PlayerTextDrawBoxColor(playerid, speedTD[playerid][3], 0x0DB5072A);
				PlayerTextDrawSetString(playerid, speedTD[playerid][3], "door is unlocked");
			}
			else {
				PlayerTextDrawBoxColor(playerid, speedTD[playerid][3], 0xFF00002A);
				PlayerTextDrawSetString(playerid, speedTD[playerid][3], "door is locked");
			}
		}

		for(new tds; tds < 7; tds++) {
			if((tds == 5 || tds == 4) && vehID[veh] == 0) continue;
			PlayerTextDrawShow(playerid, speedTD[playerid][tds]);
		}

		new newcar = GetPlayerVehicleID(playerid);
		if(vehID[newcar] > 0) {
			new x = vehID[newcar];
			pcInfo[x][pcTimeToSpawn] = 60 * 15;
			SCMEx(playerid, -1, "This %s is owned by %s. Distance traveled: %dkm in %d days.", vehName[pcInfo[x][pcModel] - 400], getVehicleOwner(x), pcInfo[x][pcOdometer], daysAgo(pcInfo[x][pcAge]));
		}

		if((vInfo[svrVeh[veh]][vGroup] > 0 && pInfo[playerid][pMember] != vInfo[svrVeh[veh]][vGroup])  && pInfo[playerid][pAdmin] < 6) {
			RemovePlayerFromVehicle(playerid), SCMEx(playerid, -1, "This "SBLUE"%s "WHITE"can be used only be %s`s members!", vehName[GetVehicleModel(veh) - 400], gInfo[vInfo[svrVeh[veh]][vGroup]][gName]);
		}

		if(DMVTest[playerid] == 0 && pInfo[playerid][pCarLic] == 0) {
			RemovePlayerFromVehicle(playerid);
			SCM(playerid, -1, "You don`t have driving licence.");
		}

		new vehicleName[30], rand = random(3);
		switch(rand) {
			case 0: { format(vehicleName, 30, "~n~~g~%s", vehName[GetVehicleModel(veh) - 400]); }
			case 1: { format(vehicleName, 30, "~n~~y~%s", vehName[GetVehicleModel(veh) - 400]); }
			case 2: { format(vehicleName, 30, "~n~~r~~h~%s", vehName[GetVehicleModel(veh) - 400]); }
		}
		GameTextForPlayer(playerid, vehicleName, 3000, 1);
		
		if((vInfo[svrVeh[veh]][vGroup] > 0 && pInfo[playerid][pMember] != vInfo[svrVeh[veh]][vGroup])  && pInfo[playerid][pAdmin] == 0) {
			new Float:x, Float:y, Float:z;
			GetPlayerPos(playerid, x, y, z), SetPlayerPos(playerid, x, y, z+2);
			SCMEx(playerid, COLOR_GREY, "This "SBLUE"%s "GREY"can be used only be %s`s members!", vehName[GetVehicleModel(veh) - 400], gInfo[vInfo[svrVeh[veh]][vGroup]][gName]);
		}
	}
	if(newstate != PLAYER_STATE_DRIVER && GetPVarInt(playerid, "AddVehicle") > 0 && veh != GetPVarInt(playerid, "AddVehicle")) {
		DestroyVehicle(GetPVarInt(playerid, "AddVehicle"));
		SCMEx(playerid, COLOR_LIGHTRED, "Vehicle #%d was destroyed because you left it.", GetPVarInt(playerid, "AddVehicle")), DeletePVar(playerid, "AddVehicle");
	}
	return 1;
}

public OnPlayerEnterCheckpoint(playerid) {
	if(Checkpoint[playerid] == 1 || Checkpoint[playerid] == 3) {
		DisablePlayerCheckpoint(playerid), Checkpoint[playerid] = 0;
	}

	else if(Checkpoint[playerid] == 2) // job arms dealer
	{
		if(GetPlayerVehicleID(playerid) > 0 && (jobVehicle[playerid] == GetPlayerVehicleID(playerid))) { 
			new Float:z_angle;
			GetVehicleZAngle(GetPlayerVehicleID(playerid), z_angle);
			if(z_angle >= 255.0 && z_angle <= 285.0) {

				new mats = getPlayerSkill(pInfo[playerid][pMatsSkill]);
				pInfo[playerid][pMaterials] += 1000 + ((mats*200) + 100), SCMEx(playerid, COLOR_SBLUE, "Job Info: "WHITE"Nice work! You delivered all the guns safely and you have received %s materials.", FormatNumber(1000 + ((mats*200) + 100)));
			
				DisablePlayerCheckpoint(playerid), Checkpoint[playerid] = 0, DestroyVehicle(jobVehicle[playerid]), jobVehicle[playerid] = -1;
				DestroyPlayerObject(playerid, armsObject[playerid][0]), DestroyPlayerObject(playerid, armsObject[playerid][1]), DestroyPlayerObject(playerid, armsObject[playerid][2]);

			}
			else SCM(playerid, -1, "Please park the car properly.");
		}
		else SCM(playerid, -1, "You failed. You are not in your job vehicle."), DisablePlayerCheckpoint(playerid), Checkpoint[playerid] = 0;
	}
	else if(Checkpoint[playerid] == 4) {
		SCM(playerid, -1, "Type again /work to start your job, good luck! ;)"), DisablePlayerCheckpoint(playerid), Checkpoint[playerid] = 0;
	}
	return 1;
}

public OnPlayerLeaveCheckpoint(playerid) {
	return 1;
}

public OnPlayerEnterRaceCheckpoint(playerid) {
	if(DMVTest[playerid] == 1)
	{
		if(DMVCP[playerid] == 0)
		{
			SetPlayerRaceCheckpoint(playerid, 0, 1181.7075,-1797.5635,13.3984, 1182.6652,-1717.6641,13.5165, 5.0);
			DMVCP[playerid] = 1;
			showPlayerDMVTD(playerid);
		}
		else if(DMVCP[playerid] == 1)
		{
			SetPlayerRaceCheckpoint(playerid, 0, 1182.6652,-1717.6641,13.5165, 1153.0706,-1701.0609,13.7813, 5.0);
			DMVCP[playerid] = 2;
			showPlayerDMVTD(playerid);
		}
		else if(DMVCP[playerid] == 2)
		{
			SetPlayerRaceCheckpoint(playerid, 0, 1153.0706,-1701.0609,13.7813, 1154.3901,-1574.6116,13.2734, 5.0);
			DMVCP[playerid] = 3;
			showPlayerDMVTD(playerid);
		}
		else if(DMVCP[playerid] == 3)
		{
			SetPlayerRaceCheckpoint(playerid, 0, 1154.3901,-1574.6116,13.2734, 1295.3446,-1579.6139,13.3828, 5.0);
			DMVCP[playerid] = 4;
			showPlayerDMVTD(playerid);
		}
		else if(DMVCP[playerid] == 4)
		{
			SetPlayerRaceCheckpoint(playerid, 0, 1295.3446,-1579.6139,13.3828, 1295.3431,-1651.5891,13.3828, 5.0);
			DMVCP[playerid] = 5;
			showPlayerDMVTD(playerid);
		}
		else if(DMVCP[playerid] == 5)
		{
			SetPlayerRaceCheckpoint(playerid, 0, 1295.3431,-1651.5891,13.3828, 1295.0104,-1729.6229,13.3828, 5.0);
			DMVCP[playerid] = 6;
			showPlayerDMVTD(playerid);
		}
		else if(DMVCP[playerid] == 6)
		{
			SetPlayerRaceCheckpoint(playerid, 0, 1295.0104,-1729.6229,13.3828, 1294.3243,-1843.6172,13.3828, 5.0);
			DMVCP[playerid] = 7;
			showPlayerDMVTD(playerid);
		}
		else if(DMVCP[playerid] == 7)
		{
			SetPlayerRaceCheckpoint(playerid, 1, 1294.3243,-1843.6172,13.3828, 1294.3243,-1843.6172,13.3828, 5.0);
			DMVCP[playerid] = 8;
			showPlayerDMVTD(playerid);
		}
		else if(DMVCP[playerid] == 8)
		{
			PlayerTextDrawHide(playerid, examTD[playerid]);
			DestroyVehicle(DMVVehicle[playerid]), DestroyObject(DMVObject[playerid]);
			PenaltyPoints[playerid] = DMVTest[playerid] = DMVCP[playerid] = 0, DMVVehicle[playerid] = -1;
			pInfo[playerid][pCarLic] = 100;
			SCM(playerid, COLOR_GREEN, "Instructor: {FFFFFF}You have passed the driving test, congratulations!");
			DisablePlayerRaceCheckpoint(playerid);
		}
	}
	return 1;
}

public OnPlayerLeaveRaceCheckpoint(playerid) {
	return 1;
}

public OnRconCommand(cmd[]) {
	return 1;
}

public OnObjectMoved(objectid) {
	return 1;
}

public OnPlayerObjectMoved(playerid, objectid) {
	return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid) {
	return 1;
}

public OnVehicleMod(playerid, vehicleid, componentid) {
	if(vehID[vehicleid] > 0) {
		SaveComponent(vehicleid, componentid);
	}
	return 1;
}

public OnVehiclePaintjob(playerid, vehicleid, paintjobid) {
	return 1;
}

public OnVehicleRespray(playerid, vehicleid, color1, color2) {
	if(vehID[vehicleid] > 0) {
		pcInfo[vehID[vehicleid]][pcColor1] = color1;
		pcInfo[vehID[vehicleid]][pcColor2] = color2;
	}
	return 1;
}

public OnPlayerSelectedMenuRow(playerid, row) {
	return 1;
}

public OnPlayerExitedMenu(playerid) {
	return 1;
}

public OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid) {
	return 1;
}
public OnPlayerKeyStateChange(playerid, newkeys, oldkeys) {
    new engine, alarm, doors, bonnet, boot, objective, lights;
	if (newkeys & KEY_CROUCH) {
		if(gInfo[pInfo[playerid][pMember]][gType] == 1) {
			if(IsPlayerInRangeOfPoint(playerid, 15.00, 1588.6552, -1637.9025, 15.0358)) {
               MoveDynamicObject(gatelspd, 1596.7352,-1637.9025, 15.0358, 2), defer lspdgateclose();
			}
			else if(IsPlayerInRangeOfPoint(playerid, 15.00, 1544.7007, -1630.7527, 13.2983)) {
               MoveDynamicObject(lspdbar, 1544.7007, -1630.7527, 13.2983, 2,0.0000, 0.0000, 90.0000), defer lspdbarclose();
               ApplyActorAnimation(PoliceActor, "DEALER", "DEALER_DEAL", 4.1,  0, 0, 0, 0, 0);
			}
		}
	}

	if(newkeys & KEY_NO) {
		new car = GetClosestVehicle(playerid);
		new Float:x, Float:y, Float:z;
		GetVehiclePos(car, x, y, z);
		if(!IsPlayerInRangeOfPoint(playerid, 5.0, x, y, z)) return 0;
		if(pcInfo[vehID[car]][pcOwner] != pInfo[playerid][pSQLID]) return 0;
		GetVehicleParamsEx(car, engine, lights, alarm, doors, bonnet, boot, objective);
		switch(pcInfo[vehID[car]][pcLockStatus]) {
			case 0: {
				SetVehicleParamsEx(car, engine, lights, alarm, 1, bonnet, boot, objective);
				pcInfo[vehID[car]][pcLockStatus] = 1;
				format(gMsg, 30, "%s ~n~~r~locked", vehName[GetVehicleModel(car) - 400]);
				GameTextForPlayer(playerid, gMsg, 5000, 3);
			}
			case 1: {
				SetVehicleParamsEx(car, engine, lights, alarm, 0, bonnet, boot, objective);
				pcInfo[vehID[car]][pcLockStatus] = 0;
				format(gMsg, 30, "%s ~n~~g~unlocked", vehName[GetVehicleModel(car)  - 400]);
				GameTextForPlayer(playerid, gMsg, 5000, 3);
			}
		}
	}

	if((newkeys == KEY_SUBMISSION) && (IsPlayerInAnyVehicle(playerid)) && (GetPlayerState(playerid) == PLAYER_STATE_DRIVER))
    {
        new vehicless;
        new newcar = GetPlayerVehicleID(playerid);
        if(!IsABike(newcar))
		{
			if(vehID[newcar]) {
				if(pcInfo[vehID[newcar]][pcInsurance] == 0) return SCM(playerid, COLOR_GREY, "This vehicle cannot be used because it has no insurance points."); 
			}
    		vehicless = GetVehicleModel(newcar) - 400;
    		vehicless = GetVehicleModel(newcar) - 400;
            if(GetPlayerState(playerid) != PLAYER_STATE_DRIVER) return SCM(playerid, -1, "You need to be the driver of the vehicle");
    		GetVehicleParamsEx(GetPlayerVehicleID(playerid), engine, lights, alarm, doors, bonnet, boot, objective);
   			if(engine == 1)
   			{
	    		SetVehicleParamsEx(GetPlayerVehicleID(playerid), 0, lights, alarm, doors, bonnet, boot, objective);
	    		format(szMsg, sizeof(szMsg), "* %s stops the engine of his %s.", GetName(playerid), vehName[vehicless]);
				nearByMessage(playerid, COLOR_PURPLE, szMsg);
			}
			else
			{
	    		SetVehicleParamsEx(GetPlayerVehicleID(playerid), 1, lights, alarm, doors, bonnet, boot, objective);
	   			format(szMsg, sizeof(szMsg), "* %s starts the engine of his %s.", GetName(playerid), vehName[vehicless]);
				nearByMessage(playerid, COLOR_PURPLE, szMsg);
			}
		}
    }
	if(newkeys & KEY_SECONDARY_ATTACK)
    {
    	if(flyingStatus[playerid] == true) {
			StopFly(playerid), setHealth(playerid, 99.00), ClearAnimations(playerid);
			flyingStatus[playerid] = false;
			GameTextForPlayer(playerid, "~~Flying mode off", 4500, 3);
		}

		new Float: X, Float: Y, Float: Z;
		GetPlayerPos(playerid, X, Y, Z);
		if(IsPlayerInRangeOfPoint(playerid, 4.0, 2166.4668, -1671.5120, 15.0740)) {//drugs /getdrugs
			SetPlayerPos(playerid, 318.564971, 1118.209960, 1083.882812);
			SetPlayerInterior(playerid, 5);
			SetCameraBehindPlayer(playerid);
		}
		if(IsPlayerInRangeOfPoint(playerid, 4.0, 318.564971, 1118.209960, 1083.882812)) {//drugs /getdrugs exit
			SetPlayerPos(playerid, 2166.4668, -1671.5120, 15.0740);
			SetPlayerInterior(playerid, 0);
			SetCameraBehindPlayer(playerid);
			SetPlayerVirtualWorld(playerid, 0);
		}
		for(new i = 0; i < MAX_GROUPS; i++) {
			if(IsPlayerInRangeOfPoint(playerid, 2.0, gInfo[i][geX], gInfo[i][geY], gInfo[i][geZ]))
			{
				if(gInfo[i][gDoor] == 0 || (pInfo[playerid][pMember] == i && gInfo[i][gDoor] == 1)) {
					SetPlayerPos(playerid, gInfo[i][giX], gInfo[i][giY], gInfo[i][giZ]);
					SetPlayerInterior(playerid, gInfo[i][gInterior]);
					SetPlayerVirtualWorld(playerid, i+1);
					SetCameraBehindPlayer(playerid);
					playerHQ[playerid] = i;
					break;
				} 
				else SCMEx(playerid, -1, "You are not %s`s member.", gInfo[i][gName]);
			}
			else if(IsPlayerInRangeOfPoint(playerid, 2.0, gInfo[i][giX], gInfo[i][giY], gInfo[i][giZ]) && playerHQ[playerid] == i)
			{
				SetPlayerPos(playerid, gInfo[i][geX], gInfo[i][geY], gInfo[i][geZ]);
				SetPlayerInterior(playerid, 0);
				SetPlayerVirtualWorld(playerid, 0);
				SetCameraBehindPlayer(playerid);
				playerHQ[playerid] = 0;
				break;
			}
		}
	}
	return 1;
}

public OnRconLoginAttempt(ip[], password[], success) {
	return 1;
}

public OnPlayerResume(playerid, time) {
	SetPlayerHealth(playerid, playerHP[playerid]);
	SetPlayerArmour(playerid, playerArmour[playerid]);
	return 1;
}

public OnPlayerUpdate(playerid) {
	// handle fps counters.
	new drunknew;
	drunknew = GetPlayerDrunkLevel(playerid);

	if (drunknew < 100) { // go back up, keep cycling.
		SetPlayerDrunkLevel(playerid, 2000);
	} else {

		if (pDrunkLevelLast[playerid] != drunknew) {

			new wfps = pDrunkLevelLast[playerid] - drunknew;

			if ((wfps > 0) && (wfps < 200))
				FPS2[playerid] = wfps;

			pDrunkLevelLast[playerid] = drunknew;
		}
	}
	return 1;
}

public OnPlayerStreamIn(playerid, forplayerid) {
	if(playerCover[playerid] == 1) {
		ShowPlayerNameTagForPlayer(forplayerid, playerid, 0);
	}

	if(gInfo[pInfo[playerid][pMember]][gWar] == gInfo[pInfo[forplayerid][pMember]][gWar] && gInfo[pInfo[playerid][pMember]][gWar] != 0 && gInfo[pInfo[forplayerid][pMember]][gWar] != 0) {
		SetPlayerMarkerForPlayer( playerid, forplayerid, (GetPlayerColor(forplayerid) | 0x000000FF));
		SetPlayerMarkerForPlayer( forplayerid, playerid, (GetPlayerColor(playerid) | 0x000000FF));
	}
	else {
		SetPlayerMarkerForPlayer( playerid, forplayerid, ( GetPlayerColor( forplayerid ) & 0xFFFFFF00 ) );
		SetPlayerMarkerForPlayer( forplayerid, playerid, ( GetPlayerColor( playerid ) & 0xFFFFFF00 ) );
	}
	return 1;
}

public OnPlayerStreamOut(playerid, forplayerid) {	
	SetPlayerMarkerForPlayer( playerid, forplayerid, ( GetPlayerColor( forplayerid ) & 0xFFFFFF00 ) );
	SetPlayerMarkerForPlayer( forplayerid, playerid, ( GetPlayerColor( playerid ) & 0xFFFFFF00 ) );
	return 1;
}

public OnVehicleStreamIn(vehicleid, forplayerid) {
	return 1;
}

public OnVehicleStreamOut(vehicleid, forplayerid) {
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[]) {
	new query[354];
	switch(dialogid) { 
		case DIALOG_CONFIRM: {
			if(response) {
				if(pConfirm[playerid] == 1) {
					new liveStr[184];
					format(liveStr, 184, ""RED"** Accepting live invitation\n\n"SYN"Are you sure you want to accept live invitation from %s?\n"GREEN"Live price: "SYN"$25,000", GetName(GetSVarInt("liveReporter")));
					ShowPlayerDialog(GetSVarInt("livePlayer"), DIALOG_CONFIRM, DIALOG_STYLE_MSGBOX, "SERVER: Live invitation", liveStr, "Accept", "Cancel");
					pConfirm[playerid] = 0, pConfirm[GetSVarInt("livePlayer")] = 2;
				}
				else if(pConfirm[playerid] == 2) {
					new h, m, s, hStr[30];
					gettime(h, m, s), format(hStr, 30, "%02d:%02d", h, m);
					SetSVarString("liveStart", hStr), SetSVarInt("liveOn", 1);
					pConfirm[playerid] = 0;
					SCMEx(playerid, COLOR_YELLOW, "Live start time: %s", hStr);

					SetPlayerPos(GetSVarInt("livePlayer"), 254.0660,1754.2334,701.5938), SetPlayerFacingAngle(GetSVarInt("livePlayer"), 314.9005);
					SetPlayerInterior(playerid, gInfo[pInfo[GetSVarInt("liveReporter")][pMember]][gInterior]), SetPlayerVirtualWorld(playerid, pInfo[GetSVarInt("liveReporter")][pMember]+1);
					SetPlayerPos(GetSVarInt("liveReporter"), 255.7950,1754.1514,701.5938), SetPlayerFacingAngle(GetSVarInt("liveReporter"), 46.5202);

					ApplyAnimation(GetSVarInt("livePlayer"),"BEACH", "ParkSit_M_loop", 4.1, 0, 0, 0, 1, 0, 0);
					ApplyAnimation(GetSVarInt("liveReporter"),"BEACH", "ParkSit_M_loop", 4.1, 0, 0, 0, 1, 0, 0);

					SetPlayerCameraPos(playerid, 256.288909,1764.726196,702.700988);
					SetPlayerCameraLookAt(playerid, 256.157226, 1762.309570, 701.589416);

					SetPlayerCameraPos(GetSVarInt("liveReporter"), 256.288909,1764.726196,702.700988);
					SetPlayerCameraLookAt(GetSVarInt("liveReporter"), 256.157226, 1762.309570, 701.589416);
				}
				else if(pConfirm[playerid] == 3) {
					ClearAnimations(GetSVarInt("liveReporter")), ClearAnimations(GetSVarInt("livePlayer"));
					SetCameraBehindPlayer(GetSVarInt("liveReporter")), SetCameraBehindPlayer(GetSVarInt("livePlayer"));
					DeleteSVar("livePlayer"), DeleteSVar("liveReporter"), DeleteSVar("liveOn"), DeleteSVar("liveStart");
					pConfirm[playerid] = 0;
					SCMEx(playerid, COLOR_YELLOW, "Live ended.");
				}
			}
		}
		case DIALOG_GPS: {
			if(response) {
				if(listitem != Iter_Count(gpsIter)) {
					new  Float:distance, x = gpsSelected[playerid][listitem];
					distance = GetPlayerDistanceFromPoint(playerid, gpsInfo[x][gpsX], gpsInfo[x][gpsY], gpsInfo[x][gpsZ]);

					SCMEx(playerid, COLOR_YELLOW, ""YELLOW"Our system placed you a checkpoint to "ORANGE"%s"YELLOW". Distance: %0.2f meters.", gpsInfo[x][gpsName], distance);
					SetPlayerCheckpoint(playerid, gpsInfo[x][gpsX], gpsInfo[x][gpsY], gpsInfo[x][gpsZ], 2.0);
					Checkpoint[playerid] = 1;
				}
				else Syntax(playerid, "/addgps [name] [city]");
			}
		}
		case DIALOG_JOBS: {
			if(response) {
				new x = listitem+1, Float:distance;
				distance = GetPlayerDistanceFromPoint(playerid, jInfo[x][jX], jInfo[x][jY], jInfo[x][jZ]);

				SCMEx(playerid, COLOR_YELLOW, ""YELLOW"Our system placed you a checkpoint to "ORANGE"%s"YELLOW". Distance: %0.2f meters.", jInfo[x][jName], distance);
				SetPlayerCheckpoint(playerid, jInfo[x][jX], jInfo[x][jY], jInfo[x][jZ], 2.0);
				Checkpoint[playerid] = 1;
			}
		}
		case DIALOG_WANTED: {
			if(response) {
				new id = listitem;
				if(isLogged(dialogPlayer[playerid][id]) == 0) return SCM(playerid, -1, "The player is not connected");
				GetPlayerMdc(playerid, dialogPlayer[playerid][id]), FindPlayer(playerid, dialogPlayer[playerid][id]);
			}
		}
		case DIALOG_VEHICLES: {
			if(response) {
				new x = pcSelected[playerid][listitem];
				pcSelID[playerid] = x;
				if(listitem < personalCount(playerid)) {
					if(pInfo[playerid][pAdmin] < 2) {
						format(szMsg, 220, "#\tOption name\tPrice\n"SYN"1\tCheck vehicle info\t"CREM"free\n"SYN"2\tTow vehicle\t"CREM"free\n"SYN"3\tFind vehicle\t"CREM"free\n"SYN"4\tBuy insurance points\t"GREEN"$%s", FormatNumber(getInsurancePrice(daysAgo(pcInfo[x][pcAge]), pcInfo[x][pcOdometer])));
					}
					else if(pInfo[playerid][pAdmin] >= 2){
						if(pcInfo[x][pcSpawned] == 1) {
							format(szMsg, 240, "#\tOption name\tPrice\n"SYN"1\tCheck vehicle info\t"CREM"free\n"SYN"2\tTow vehicle\t"CREM"free\n"SYN"3\tFind vehicle\t"CREM"free\n"SYN"4\tBuy insurance points\t"GREEN"$%s\n"SYN"5\t"PINK"Get vehicle to me (a2+)"CREM"\tfree", FormatNumber(getInsurancePrice(daysAgo(pcInfo[x][pcAge]), pcInfo[x][pcOdometer])));
						}
						else {
							format(szMsg, 220, "#\tOption name\tPrice\n"SYN"1\tCheck vehicle info\t"CREM"free\n"SYN"2\tTow vehicle\t"CREM"free\n"SYN"3\tFind vehicle\t"CREM"free\n"SYN"4\tBuy insurance points\t"GREEN"$%s", FormatNumber(getInsurancePrice(daysAgo(pcInfo[x][pcAge]), pcInfo[x][pcOdometer])));
						}
					}
					ShowPlayerDialog(playerid, DIALOG_VEHICLES_MANAGE, DIALOG_STYLE_TABLIST_HEADERS, "SERVER: Vehicle info", szMsg, "Select", "Cancel");
				}
				else {
					if(pInfo[playerid][pMaxSlots] >= 10) return SCMEx(playerid, COLOR_RED, "You have reached the maximum number of slots which you can have (%d/10).", pInfo[playerid][pMaxSlots]);
					if(pInfo[playerid][pLoyalityPoints] < 20) return SCM(playerid, -1, "You need to have 20 premium points to use this option.");
					pInfo[playerid][pLoyalityPoints] -= 20;
					pInfo[playerid][pMaxSlots] ++;
					SCMEx(playerid, -1, ""PINK"(-) Congratulations! Now you have %d vehicle slots.", pInfo[playerid][pMaxSlots]);
				}
			}
		}
		case DIALOG_VEHICLES_MANAGE: {
			if(response) {
				new x = pcSelID[playerid];
				new engine, lights, alarm, bonnet, boot, objective;
				switch(listitem) {
					case 0: {
						format(szMsg, 200, ""CREM"** Information about your %s\n\n"SYN"Age: %d days\nOdometer: %dkm\nColors: %d, %d\nInsurance: %d points\nInsurance price: $%s", vehName[pcInfo[x][pcModel]-400], 
						daysAgo(pcInfo[x][pcAge]), pcInfo[x][pcOdometer], pcInfo[x][pcColor1], pcInfo[x][pcColor2], pcInfo[x][pcInsurance], FormatNumber(getInsurancePrice(daysAgo(pcInfo[x][pcAge]), pcInfo[x][pcOdometer])));
						ShowPlayerDialog(playerid, DIALOG_GENERAL, DIALOG_STYLE_MSGBOX, "SERVER: Personal vehicle info", szMsg, "Close", "");
					}
					case 1: {
						if(pcInfo[x][pcSpawned] == 0) {
							new car = CreateVehicle(pcInfo[x][pcModel], pcInfo[x][pcPosX], pcInfo[x][pcPosY], pcInfo[x][pcPosZ], pcInfo[x][pcPosA], pcInfo[x][pcColor1], pcInfo[x][pcColor2], -1);
							
							SetVehicleParamsEx(car, engine, lights, alarm, pcInfo[vehID[car]][pcLockStatus], bonnet, boot, objective);
							
							
							vehID[car] = x, pcInfo[x][pcSpawned] = 1, pcInfo[x][pcTimeToSpawn] = 60 * 15;
							SCMEx(playerid, -1, "You have spawned your %s.", vehName[pcInfo[x][pcModel]-400]);
							ModVehicle(car);
						}
						else {
							for(new v; v < MAX_VEHICLES; v++) {
								if(x == vehID[v]) {
									if(!IsVehicleOccupied(v)) {
										SetVehicleToRespawn(v);
										SCMEx(playerid, -1, "You have spawned your %s.", vehName[pcInfo[x][pcModel]-400]);
									}
									else { SCMEx(playerid, COLOR_GREY, "You can not spawn your vehicle because it`s used by %s", GetName(GetVehicleDriver(v))); }
									break;
								}
							}
						}
					}
					case 2: { 
						new  Float:distance;
						if(pcInfo[x][pcSpawned] == 0) {
							new car = CreateVehicle(pcInfo[x][pcModel], pcInfo[x][pcPosX], pcInfo[x][pcPosY], pcInfo[x][pcPosZ], pcInfo[x][pcPosA], pcInfo[x][pcColor1], pcInfo[x][pcColor2], -1);
							distance = GetPlayerDistanceFromPoint(playerid, pcInfo[x][pcPosX], pcInfo[x][pcPosY], pcInfo[x][pcPosZ]);

							SetVehicleParamsEx(car, engine, lights, alarm, pcInfo[vehID[car]][pcLockStatus], bonnet, boot, objective); 
							
							vehID[car] = x, pcInfo[x][pcSpawned] = 1, pcInfo[x][pcTimeToSpawn] = 60 * 15;
							SCMEx(playerid, COLOR_YELLOW, "Our system placed you a checkpoint to your %s. Distance: %.0f meters.", vehName[pcInfo[x][pcModel]-400], distance);
							SetPlayerCheckpoint(playerid, pcInfo[x][pcPosX], pcInfo[x][pcPosY], pcInfo[x][pcPosZ], 7.0);
							ModVehicle(car), Checkpoint[playerid] = 1;
						}
						else {
							new Float:pX, Float:pY, Float:pZ;
							for(new v; v < MAX_VEHICLES; v++) {
								if(x == vehID[v]) {
									Checkpoint[playerid] = 1;
									GetVehiclePos(v, pX, pY, pZ), SetPlayerCheckpoint(playerid, pX, pY, pZ, 7.0);
									distance = GetPlayerDistanceFromPoint(playerid,  pX, pY, pZ);
									SCMEx(playerid, COLOR_YELLOW, "Our system placed you a checkpoint to your %s. Distance: %.0f meters.", vehName[pcInfo[x][pcModel]-400], distance);
									break;
								}
							}
						}
					}
					case 3: {
						if(pcInfo[x][pcInsurance] < 5) {
							format(szMsg, 256, ""YELLOW"** Insurance price\n\n"SYN"- for every 1000km traveled, the price will increase by $150\n- for every day, the price will increase by $70\n\nEnter the below number of points you want to buy (maximum %d):", 5 - pcInfo[x][pcInsurance]);
							ShowPlayerDialog(playerid, DIALOG_V_BUYINSURANCE, DIALOG_STYLE_INPUT, "SERVER: Buy insurance points", szMsg, "Buy", "Cancel");
						}
						else {
							ShowPlayerDialog(playerid, DIALOG_GENERAL, DIALOG_STYLE_MSGBOX, "SERVER: Buy insurance points", ""YELLOW"** Insurance price\n\n"SYN"- for every 1000km traveled, the price will increase by $150\n- for every day, the price will increase by $70\n\n"PINK"You can not buy insurance because your points already have 5 + points.", "Hide", "");
						}
					}
					case 4: {
						new Float:pX, Float:pY, Float:pZ;
						for(new v; v < MAX_VEHICLES; v++) {
							if(x == vehID[v]) {
								GetPlayerPos(playerid, pX, pY, pZ), SetVehiclePos(v, pX, pY, pZ), LinkVehicleToInterior(v, GetPlayerInterior(playerid)), SetVehicleVirtualWorld(v, GetPlayerVirtualWorld(playerid));
								PutPlayerInVehicle(playerid, v, 0);
								SCMEx(playerid, 0xFF9100FF, "You have teleported your %s to you.", vehName[pcInfo[x][pcModel]-400]);
								break;
							}
						}
					}
				}
			}
		}
		case DIALOG_V_BUYINSURANCE: {
			if(response) {
				new x = pcSelID[playerid], points = strval(inputtext);
				if(points > 0 && points <= (5 - pcInfo[x][pcInsurance])) {
					if(pInfo[playerid][pMoney] < getInsurancePrice(daysAgo(pcInfo[x][pcAge]), pcInfo[x][pcOdometer]) * points) return SCMEx(playerid, -1, "You need to have $%s more to buy %d insurance points.", FormatNumber((getInsurancePrice(daysAgo(pcInfo[x][pcAge]), pcInfo[x][pcOdometer]) * points) - pInfo[playerid][pMoney]), points);
					pcInfo[x][pcInsurance] += points;
					pInfo[playerid][pMoney] -= (getInsurancePrice(daysAgo(pcInfo[x][pcAge]), pcInfo[x][pcOdometer]) * points);
					SCMEx(playerid, -1, ""PINK"(+) You paid $%s for %d insurance points.", FormatNumber(getInsurancePrice(daysAgo(pcInfo[x][pcAge]), pcInfo[x][pcOdometer]) * points), points);
				}
				else {
					format(szMsg, 256, ""YELLOW"** Insurance price\n\n"SYN"- for every 1000km traveled, the price will increase by $150\n- for every day, the price will increase by $70\n\n"RED"You can buy minimum 1 points and maximum %d:", 5 - pcInfo[x][pcInsurance]);
					ShowPlayerDialog(playerid, DIALOG_V_BUYINSURANCE, DIALOG_STYLE_INPUT, "SERVER: Buy insurance points", szMsg, "Buy", "Cancel");
				}
			}
		}
		case DIALOG_VEHICLES_SELLDS: {
			if(response) {
				if(!IsPlayerInRangeOfPoint(playerid, 5.0, 2131.6790,-1150.6421,24.1334)) return SCM(playerid, -1, "You are not at Dealership.");
				if(pcInfo[vehID[GetPlayerVehicleID(playerid)]][pcOwner] != pInfo[playerid][pSQLID]) return SCMEx(playerid, -1, "You are not in your personal vehicle.");
				new car = GetPlayerVehicleID(playerid), id = vehID[car], price = (getDealerPrice(GetVehicleModel(car)) * 75) / 100;
				mysql_format(handle, szMsg, 100, "DELETE FROM `personalcars` WHERE `id` = '%d'", pcInfo[vehID[car]][pcID]), mysql_tquery(handle, szMsg);
				
				pcInfo[id][pcID] = pcInfo[id][pcOwner] = pcInfo[id][pcModel] = 0;
				pcInfo[id][pcPosX] = pcInfo[id][pcPosY] = pcInfo[id][pcPosZ] = pcInfo[id][pcPosA] = 0.0000;
				format(pcInfo[id][pcCarPlate], 10, "(null)");
				pcInfo[id][pcColor1] = pcInfo[id][pcColor2] = pcInfo[id][pcOdometer] = pcInfo[id][pcSpawned] = pcInfo[id][pcLockStatus] = pcInfo[id][pcAge] = pcInfo[id][pcInsurance] = 0;
				Iter_Remove(personalCars, id);
				sendAdmins(0xFF9100FF, "Dealership: %s sold his %s to the Dealership for $%s.", GetName(playerid), vehName[GetVehicleModel(car) - 400], FormatNumber(price));
				
				SCMEx(playerid, COLOR_TEAL, "(+) You have sold your %s for %s$ to the Dealership.", vehName[GetVehicleModel(car) - 400], FormatNumber(price));
				pInfo[playerid][pMoney] += price;
				DestroyVehicle(car);
			}
		}
		case DIALOG_VEHICLES_SELL: {
			if(response) {
				if(pcInfo[vehID[GetPlayerVehicleID(playerid)]][pcOwner] != pInfo[playerid][pSQLID]) return SCMEx(playerid, -1, "You are not in your personal vehicle.");
				new car = GetPlayerVehicleID(playerid), itID = vehID[car];
				if(!IsPlayerInRangeOfPlayer(playerid, GetPVarInt(playerid, "sellingCarTo"), 15.0)) return SCM(playerid, -1, "You need to be near by your client.");
			
				SCMEx(playerid, COLOR_BLUE, "Offer sended to %s.", GetName(GetPVarInt(playerid, "sellingCarTo")));
				SCM(GetPVarInt(playerid, "sellingCarTo"), COLOR_YELLOW, "** New offer");
				SCMEx(GetPVarInt(playerid, "sellingCarTo"), COLOR_BLUE, "%s offered his %s (distance traveled: %dkm in %d days, colors: %d, %d) for $%s! Type /accept car %d to accept.", 
				GetName(playerid), vehName[GetVehicleModel(car) - 400], daysAgo(pcInfo[itID][pcAge]), pcInfo[itID][pcOdometer], pcInfo[itID][pcColor2], pcInfo[itID][pcColor2], FormatNumber(GetPVarInt(playerid, "sellingCarPrice")), playerid);
			}
			else SetPVarInt(playerid, "sellingCarTo", -1);
		}
		case DIALOG_HELP: {
			if(response) {
				new str[1408];
				switch(listitem) {
					case 0: {
					    strcat(str, ""SYN"---- General informations about "ORANGE"Eureka Role Play Gaming"SYN" ----\n\n");
					    strcat(str, ""CREM"** General commands: \n");
					    strcat(str, ""SYN"/stats - check your real statistics;\n");
					    strcat(str, ""SYN"/admins - see who from our Administrators Team is online;\n");
					    strcat(str, ""SYN"/gps - the most important locations;\n");
					    strcat(str, ""SYN"/wars - a list of active wars;\n");
					    strcat(str, ""SYN"/jobs - find a job;\n");
					    strcat(str, ""SYN"/factions - informations about server factions;\n");
					    strcat(str, ""SYN"/hud - show health percentage and other stuff;\n");
					    ShowPlayerDialog(playerid, DIALOG_HELP_RETURN, DIALOG_STYLE_MSGBOX, "SERVER: General informations;", str, "Back", "Hide");
					}
					case 1: {
					    strcat(str, "/fall - /fallback - /injured - /akick - /push - /lowbodypush - /handsup - /bomb - /drunk - /getarrested - /laugh - /sup\n");
					    strcat(str, "/basket - /headbutt - /medic - /spray - /robman - /taichi - /lookout - /kiss - /cellin - /cellout - /crossarms - /lay\n");
					    strcat(str, "/deal - /crack - /smokeanim - /groundsit - /chat - /chat2 - /dance - /fucku - /strip - /hide - /vomit - /eat - /chairsit\n");
					    strcat(str, "/koface - /kostomach - /rollfall - /carjacked1 - /carjacked2 - /rcarjack1 - /rcarjack2 - /lcarjack1 - /lcarjack2 - /bat\n");
					    strcat(str, "/lifejump - /exhaust - /leftslap - /carlock - /hoodfrisked - /lightcig - /tapcig - /box - /lay2 - /chant - /finger\n");
					    strcat(str, "/shouting - /knife - /cop - /elbow - /kneekick - /airkick - /gkick - /gpunch - /fstance - /lowthrow - /highthrow - /aim\n");
					    strcat(str, "/urinate - /lean - /run - /poli - /surrender - /sit - /breathless - /seat - /rap - /cross - /ped - /jiggy - /gesture\n");
					    strcat(str, "/sleep - /smoke - /pee - /chora - /relax - /crabs - /stop - /wash - /mourn - /fuck - /tosteal\n");
					    strcat(str, "/followme - /greeting - /still - /hitch - /palmbitch - /cpranim - /giftgiving - /slap2 - /pump - /cheer\n");
					    strcat(str, "/dj - /entrenar - /foodeat - /wave - /slapass - /dealer - /dealstance - /gwalk - /inbedright - /inbedleft\n");
					    strcat(str, "/wank - /sexy - /bj - /getup - /follow - /stand - /slapped - /slapass - /yes - /celebrate - /win - /checkout\n");
					    strcat(str, "/thankyou - /invite1 - /scratch - /nod - /cry - /carsmoke - /benddown - /shakehead - /angry\n");
					    strcat(str, "/cockgun - /bar - /liftup - /putdown - /die - /joint - /bed - /lranim\n");
					    ShowPlayerDialog(playerid, DIALOG_HELP_RETURN, DIALOG_STYLE_MSGBOX, "SERVER: Animations", str, "Back", "Hide");
					}
					case 2: {
						if(gInfo[pInfo[playerid][pMember]][gType] == 1) {
							strcat(str, ""SYN"/m - /mdc - /wanted - /find - /gov - /duty - /su(spect) - /clear - /cuff - /uncuff - /arrest - /mdc - /confiscate\n");
							strcat(str, ""SYN"/gdeposit - /showmotto - /d(epartments) - /r(adio) \n");
						}
						else if(gInfo[pInfo[playerid][pMember]][gType] == 4) {
							strcat(str, ""SYN"/contracts - /gethit - /leavehit - /mytarget\n");
						}

						// Only for leaders/co-leaders
						if(pInfo[playerid][pRank] > 5) {
							strcat(str, "\n\n"RED"** Only for members with rank 6+: \n"GREY"/fvr(espawn) - /invite - /gmotto");
						}
						ShowPlayerDialog(playerid, DIALOG_HELP_RETURN, DIALOG_STYLE_MSGBOX, "SERVER: Faction help", str, "Back", "Hide");
					}
				}
			}
		}

		case DIALOG_HELP_RETURN: {
			if(response) ShowPlayerDialog(playerid, DIALOG_HELP, DIALOG_STYLE_LIST, "SERVER: Help list", "General\nAnimations list\nFactions\nVehicles", "Select", "Cancel");
		}
		case DIALOG_HUD: {
			if(response) {
				if(listitem == 0) {
					if(pInfo[playerid][pHudHealth] == 0) {
						pInfo[playerid][pHudHealth] = !(pInfo[playerid][pHudHealth]);
						SCM(playerid, COLOR_NON, "Hud options updated!"); 
						PlayerTextDrawSetString(playerid, healthTD[playerid], "loading..."), PlayerTextDrawShow(playerid, healthTD[playerid]);
					}
					else {
						pInfo[playerid][pHudHealth] = 0;
						SCM(playerid, COLOR_NON, "Hud options updated!"), PlayerTextDrawHide(playerid, healthTD[playerid]);
					}
				}
			}
		}
		case DIALOG_REGISTER: {
			if(response) {
				new serialCode[41];
				WP_Hash(playerHashedPass[playerid], 129, inputtext);
				gpci(playerid, serialCode, 41);
				mysql_format(handle, query, 354, "INSERT INTO `players` (`username`, `password`, `SerialCode`, `Skin`) VALUES ('%e', '%e', '%e', '%d')", GetName(playerid), playerHashedPass[playerid], serialCode, SPAWN_SKIN);
				mysql_tquery(handle, query, "", "" );
				Clearchat(playerid, 20);
				SCM(playerid, COLOR_LIGHT, "REGISTER: "WHITE"Your account was been created! You need to finish all registration steps, otherwise it will be deleted.");
				ShowPlayerDialog(playerid, DIALOG_SEX, DIALOG_STYLE_MSGBOX, "SERVER: Select your character", ""SYN"Please select your character"SYN"!", "Male", "Female");
			} 
			else Kick(playerid);
		}
		case DIALOG_LOGIN: {
			if(response) {
				new hashed[129];
				WP_Hash(hashed, 129, inputtext );
				mysql_format(handle, query, 256, "SELECT * FROM `players` WHERE `username` = '%e' AND `password` = '%e'", GetName(playerid), hashed);
				mysql_tquery(handle, query, "accountLogin", "i", playerid);
			}
			else Kick(playerid);
		}
		case DIALOG_SEX: {
			if(response) {
				pInfo[playerid][pSex] = 1;
				SCM(playerid, COLOR_LIGHT, "GENDER: "WHITE"Thanks, now we know that you are a boy. How old are you?");
			}
			else {
				pInfo[playerid][pSex] = 2;
				SCM(playerid, COLOR_LIGHT, "GENDER: "WHITE"Thanks, now we know that you are a girl. How old are you?");
			}
			ShowPlayerDialog(playerid, DIALOG_AGE, DIALOG_STYLE_INPUT, "SERVER: Age", ""SYN"It`s important for us to know how old"SYN" are you!", "Proceed", "Cancel");
		}
		case DIALOG_AGE: {
			if(response) {
				new age = strval(inputtext);
				if(age > 0 && age < 50) {
					new y, m, d;
					getdate(y, m, d);
					pInfo[playerid][pAge] = age;
					SCMEx(playerid, COLOR_LIGHT, "AGE: "WHITE"Ok, you was born in %d. Now, sets the corectly email address.", y-age);
					ShowPlayerDialog(playerid, DIALOG_EMAIL, DIALOG_STYLE_INPUT, "SERVER: Email", ""SYN"If you lose your account you can use your email address "SYN"to recover your account.", "Set", "Cancel");
				}
				else ShowPlayerDialog(playerid, DIALOG_AGE, DIALOG_STYLE_INPUT, "SERVER: Age", ""SYN"It`s important for us to know how old"SYN" are you!", "Male", "Female");
			}
			else Kick(playerid);
		}
		case DIALOG_EMAIL: {
			if(response) {
				if(IsMail(inputtext)) {
					format(pInfo[playerid][pEmail], 100, inputtext);
					mysql_format(handle, query, 284, "UPDATE `players` SET `Sex` = '%d', `Age` = '%d', `Email` = '%e' WHERE `username` = '%e'", pInfo[playerid][pSex], pInfo[playerid][pAge], pInfo[playerid][pEmail], GetName(playerid));
					mysql_tquery(handle, query, "", "");
					
					mysql_format(handle, query, 256, "SELECT * FROM `players` WHERE `username` = '%e' AND `password` = '%e'", GetName(playerid), playerHashedPass[playerid]);
					mysql_tquery(handle, query, "accountLogin", "i", playerid);
					
					new Cache:count, sCode[41], pIP[16];
					gpci(playerid, sCode, 41), GetPlayerIp(playerid, pIP, 16);
					
					format(gMsg, 128, "New account - %s (%d) // ip: %s.", GetName(playerid), playerid, pIP), sendAdmins(COLOR_RED, gMsg);
					cache_delete(count);
					
				}
				else ShowPlayerDialog(playerid, DIALOG_EMAIL, DIALOG_STYLE_INPUT, "SERVER: Email", ""DRED"Error: Invalid email format.\n\n"SYN"If you lose your account you can use your email address "SYN"to recover your account.", "Set", "Cancel");
			}
			else Kick(playerid);
		}
		case DIALOG_BLOCK: {
			if(response) {
				mysql_format(handle, query, 284, "SELECT `securityCode` FROM `accounts_blocked` WHERE `playerID` = '%d' AND `securityCode` = '%e' ORDER BY `id` DESC LIMIT 1", pInfo[playerid][pSQLID], inputtext);
				mysql_tquery(handle, query, "securityCodeCheck", "i", playerid);
			}
			else Kick(playerid);
		}
	}
	return 1;
}


public OnPlayerClickPlayer(playerid, clickedplayerid, source) {
	return 1;
}

// functions
updateJobLabel(id, type = 0) {
	if(type == 2) DestroyDynamic3DTextLabel(jInfo[id][jLabel]);
	new jtype = jInfo[id][jType];

	if(jtype == 1) {
		format(gMsg, 128, "{0D82A8}Job #%d\nName: "WHITE"%s\n{0D82A8}%s", id, jInfo[id][jName], (jInfo[id][jStatus]) ? ("Type /getjob to get it") : ("This job is disabled"));
	}
	else {
		format(gMsg, 128, "{0D82A8}Job #%d\nName: "WHITE"%s\n{0D82A8}%s", id, jInfo[id][jName], (jInfo[id][jStatus]) ? ("Type /getjob to get it\nIf you are employed, type /work") : ("This job is disabled"));
	}
	jInfo[id][jLabel] = CreateDynamic3DTextLabel(gMsg, COLOR_YELLOW, jInfo[id][jX], jInfo[id][jY], jInfo[id][jZ], 100, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, -1, -1, -1, 30.0);
	return 1;
}

FindPlayer(playerid, target) {
	/*if(playerHQ[target] >= 1) {
		SetPlayerCheckpoint(playerid, gInfo[playerHQ[target]][geX], gInfo[playerHQ[target]][geY], gInfo[playerHQ[target]][geZ], 4.0);
	}
	else {
		new Float:x, Float:y, Float:z;
		GetPlayerPos(target, x, y, z);
		SetPlayerCheckpoint(playerid, x, y, z, 4.0);
	} */

	SCMEx(playerid, COLOR_YELLOW, "We have set you a checkpoint to %s`s (%d) location, distance: %0.2f (just message, working on)", GetName(target), target, GetDistanceBetweenPlayers(playerid, target));
	return 1;
}

GetPlayerMdc(playerid, target) {
	if(pInfo[target][pWanted] > 0) {
		new Float:px, Float:py, Float:pz;
		GetPlayerPos(target, px, py, pz);
		SCMEx(playerid, -1, "** Mobile Data Computer - %s [%d] - wanted: %d, distance: %0.2fm.", GetName(target), target, pInfo[target][pWanted], GetPlayerDistanceFromPoint(playerid, px, py, pz));
		new mdcStr[256];
		format(mdcStr, 256, "Suspected for: %s", pInfo[target][pWantedReason]);
		if(strlen(mdcStr) > 120)  {
			new secondLine[128];
			
			strmid(secondLine, mdcStr, 110, 256), strdel(mdcStr, 110, 256);
			SCMEx(playerid, COLOR_GREY, "%s ...", mdcStr), SCMEx(playerid, COLOR_GREY, "[...] %s", secondLine);
		}
		else SCM(playerid, COLOR_GREY, mdcStr);
	}
	else SCM(playerid, COLOR_GREY, "This player was not found in our database.");
	return 1;
}

putDutyObjects(playerid) {
	switch(GetPlayerSkin(playerid)) {
		case 265: {
			SetPlayerAttachedObject(playerid, DUTY_HAT, 19099, 2, 0.133999, -0.005000, -0.000000, 1.700001, -0.599999, -23.299987, 0.967000, 1.074000, 1.016000);
		}
		case 266: {
			SetPlayerAttachedObject(playerid, DUTY_HAT, 19099, 2, 0.161000, -0.027000, -0.004000, 3.400003, -1.799999, -23.200016, 1.547000, 1.166000, 1.081002);
		}
		case 267: {
			SetPlayerAttachedObject(playerid, DUTY_HAT, 19161, 2, 0.062999, -0.011000, 0.000000, 0.000000, -2.099999, -29.300006, 1.000000, 1.032000, 1.074000);
		}
		case 280: {
			SetPlayerAttachedObject(playerid, DUTY_HAT, 19521, 2, 0.153000, 0.005999, 0.003000, 0.000000, 0.000000, 0.000000, 1.000000, 1.000000, 1.155000);
			SetPlayerAttachedObject(playerid, DUTY_ARMOUR, 19142, 1, 0.078999, 0.039000, 0.009000, 0.000000, 0.000000, 0.000000, 1.000000, 1.064000, 1.000000);
		}
		case 281: { 
			SetPlayerAttachedObject(playerid, DUTY_HAT, 19521, 2, 0.159999, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 1.000000, 1.000000, 1.095000);
			SetPlayerAttachedObject(playerid, DUTY_ARMOUR, 19142, 1, 0.086999, 0.047000, 0.007000, 0.000000, 0.000000, 0.000000, 1.000000, 1.087999, 1.000000);
		}
		case 282: {
			SetPlayerAttachedObject(playerid, DUTY_HAT, 19521, 2, 0.157000, 0.000000, -0.000999, 0.000000, 0.000000, 0.000000, 1.000000, 1.000000, 1.179001);
			SetPlayerAttachedObject(playerid, DUTY_ARMOUR, 19515, 1, 0.087999, 0.029000, 0.012000, 0.000000, 0.000000, 0.000000, 1.000000, 1.241000, 1.060999);
		}
	}
	return 1;
}

removeDutyObjects(playerid) {
	switch(GetPlayerSkin(playerid)) {
		case 265, 266, 267: {
			if(IsPlayerAttachedObjectSlotUsed(playerid, DUTY_HAT)) { RemovePlayerAttachedObject(playerid, DUTY_HAT); }
		}
		case 280, 281, 282: {
			if(IsPlayerAttachedObjectSlotUsed(playerid, DUTY_HAT)) { RemovePlayerAttachedObject(playerid, DUTY_HAT); }
			if(IsPlayerAttachedObjectSlotUsed(playerid, DUTY_ARMOUR)) { RemovePlayerAttachedObject(playerid, DUTY_ARMOUR); }
		}
	}
	return 1;
}

setHealth(playerid, Float:amount) {
	playerHP[playerid] = lastPlayerHP[playerid] = amount;
	SetPlayerHealth(playerid, amount);
	return 1;
}

setArmour(playerid, Float:amount) {
	playerArmour[playerid] = amount;
	SetPlayerArmour(playerid, amount);
	return 1;
}

/*IsPlayerNearBoot(playerid, vehicleid) { // source: sa-mp.com
    new  Float:fX, Float:fY, Float:fZ; 
    GetVehicleBoot(vehicleid, fX, fY, fZ); 

    return (GetPlayerVirtualWorld(playerid) == GetVehicleVirtualWorld(vehicleid)) && IsPlayerInRangeOfPoint(playerid, 3.5, fX, fY, fZ); 
} 

IsPlayerNearHood(playerid, vehicleid) { // source: sa-mp.com
    new Float:fX, Float:fY, Float:fZ; 
    GetVehicleHood(vehicleid, fX, fY, fZ); 

    return (GetPlayerVirtualWorld(playerid) == GetVehicleVirtualWorld(vehicleid)) && IsPlayerInRangeOfPoint(playerid, 3.0, fX, fY, fZ); 
} 

GetVehicleBoot(vehicleid, &Float:x, &Float:y, &Float:z) { // source: sa-mp.com
    if (!GetVehicleModel(vehicleid) || vehicleid == INVALID_VEHICLE_ID) return (x = 0.0, y = 0.0, z = 0.0), 0; 
    new Float:pos[7]; 

    GetVehicleModelInfo(GetVehicleModel(vehicleid), VEHICLE_MODEL_INFO_SIZE, pos[0], pos[1], pos[2]); 
    GetVehiclePos(vehicleid, pos[3], pos[4], pos[5]); 
    GetVehicleZAngle(vehicleid, pos[6]); 

    x = pos[3] - (floatsqroot(pos[1] + pos[1]) * floatsin(-pos[6], degrees)); 
    y = pos[4] - (floatsqroot(pos[1] + pos[1]) * floatcos(-pos[6], degrees)); 
    z = pos[5]; 

    return 1; 
} 

GetVehicleHood(vehicleid, &Float:x, &Float:y, &Float:z) { // source: sa-mp.com
    if (!GetVehicleModel(vehicleid) || vehicleid == INVALID_VEHICLE_ID) return (x = 0.0, y = 0.0, z = 0.0), 0; 
	new Float:pos[7]; 
    
    GetVehicleModelInfo(GetVehicleModel(vehicleid), VEHICLE_MODEL_INFO_SIZE, pos[0], pos[1], pos[2]); 
    GetVehiclePos(vehicleid, pos[3], pos[4], pos[5]); 
    GetVehicleZAngle(vehicleid, pos[6]); 

    x = pos[3] + (floatsqroot(pos[1] + pos[1]) * floatsin(-pos[6], degrees)); 
    y = pos[4] + (floatsqroot(pos[1] + pos[1]) * floatcos(-pos[6], degrees)); 
    z = pos[5]; 

    return 1; 
}  */  

doesVehicleExist(const vehicleid) {
    if(GetVehicleModel(vehicleid) >= 400) { return 1; }
	return 0;
}

isLogged(playerid) {
	if(playerid != INVALID_PLAYER_ID && pLogged[playerid] == 1) 
		return 1;
	return 0;
}

daysAgo(timestamp) return (gettime() - timestamp) / 86400;

Syntax(playerid, syntaxMessage[]) return SCMEx(playerid, COLOR_LIGHT, "Syntax: "WHITE"%s", syntaxMessage);

sendLeaders(const message[]) {
	foreach(new x : Player) {
		if(pInfo[x][pRank] == 7 && pInfo[x][pMember] != 0) { 
			SCM(x, COLOR_TEAL, message);
		}
	}
	return 1;
}

Float:GetDistanceBetweenPlayers(playerid, targetplayerid) {
    new Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2;
    if(playerHQ[playerid] == 0) { GetPlayerPos(playerid, x1, y1, z1); } 
    	else { x1 = gInfo[playerHQ[playerid]][geX], y1 = gInfo[playerHQ[playerid]][geY], z1 = gInfo[playerHQ[playerid]][geZ]; }
    
    if(playerHQ[targetplayerid] == 0) { GetPlayerPos(targetplayerid, x2, y2, z2); } 
    	else { x2 = gInfo[playerHQ[targetplayerid]][geX], y2 = gInfo[playerHQ[targetplayerid]][geY], z2 = gInfo[playerHQ[targetplayerid]][geZ]; }
    return floatsqroot(floatpower(floatabs(floatsub(x2, x1)), 2) + floatpower(floatabs(floatsub(y2, y1)), 2) + floatpower(floatabs(floatsub(z2, z1)), 2));
}

showPlayerDMVTD(playerid) {
	PlayerTextDrawShow(playerid, examTD[playerid]);
	format(gMsg, 100, "~y~Examen:~n~~w~Checkpoints: ~r~%d/9~n~~w~Penalty: ~r~%d/25 ~w~points", DMVCP[playerid], PenaltyPoints[playerid]);
	PlayerTextDrawSetString(playerid, examTD[playerid], gMsg);
	return 1;
}

IsInLowRider(playerid) {
    new pveh = GetPlayerVehicleID(playerid);
    switch(GetVehicleModel(pveh)) {
        case 536, 575, 567: return 1;
    }
    return 0;
}

takePlayerMoney(playerid, money) {
	format(gMsg, 50, "-%s$", FormatNumber(money, "."));
	PlayerTextDrawSetString(playerid, moneyTD[playerid], gMsg), PlayerTextDrawFade(playerid, moneyTD[playerid], 0xFF0000FF);
	pInfo[playerid][pMoney] -= money;
	return 1;
}

IsPlayerFalling(playerid)
{
    new Float:X, Float:Y, Float:Z;
    GetPlayerVelocity(playerid, X, Y, Z);
    return (Z != 0.0);
}

givePlayerMoney(playerid, money) {
	format(gMsg, 50, "+%s$", FormatNumber(money, "."));
	PlayerTextDrawSetString(playerid, moneyTD[playerid], gMsg), PlayerTextDrawFade(playerid, moneyTD[playerid], 0x4DAD2BFF);
	pInfo[playerid][pMoney] += money;
	return 1;
}

getFactionColor(faction) {
	switch(faction) {
		case 0: return COLOR_WHITE;
		case 1: return COLOR_PD;
		case 2: return COLOR_FBI;
		case 3: return COLOR_HITMAN;
		case 4: return COLOR_TAXI;
		case 5: return COLOR_REPORTERS;
		case 6: return COLOR_GROVE;
		case 7: return COLOR_RUSSIAN;
		case 8: return COLOR_BALLAS;
		case 9: return COLOR_AZTECAS;
		case 10: return COLOR_PARAMEDIC;
		case 11: return COLOR_INSTRUCTORS;
	}
	return 0;
}

public OnPlayerEditObject(playerid, playerobject, objectid, response, Float:fX, Float:fY, Float:fZ, Float:fRotX, Float:fRotY, Float:fRotZ) {
	return 1;
}

public OnPlayerSelectObject(playerid, type, objectid, modelid, Float:fX, Float:fY, Float:fZ) {
    return 1;
}

getPlayerTurf(playerid) {
	new turfID;
	for(new i = 0; i < MAX_TURFS; i++) {
		new Float:x, Float:y, Float:z;
		GetPlayerPos(playerid,x,y,z);
		if((x >= tInfo[i][tMinX] && x < tInfo[i][tMaxX] && y >= tInfo[i][tMinY] && y < tInfo[i][tMaxY])) {
			turfID = i; break;	
		}
	}
	return turfID;
}

showPlayerZones(playerid) {
	for(new x; x < MAX_TURFS; x++) { 
		ShowZoneForPlayer(playerid, Turfs[x], getZoneColor(x), 0x000000FF, 0x000000AF); 
		if(gInfo[pInfo[playerid][pMember]][gWar] > 0) {
			ZoneFlashForPlayer(playerid, gInfo[pInfo[playerid][pMember]][gWar]-1, 0xFF0000AA); 
		}
		else {
			ZoneStopFlashForPlayer(playerid, x); 
		}
	}
	return 1;
}

hidePlayerZones(playerid) { 
	for(new x; x < MAX_TURFS; x++) { HideZoneForPlayer(playerid, Turfs[x]); } 
	return 1; 
}

getZoneColor(zoneid) {
	switch(tInfo[zoneid][tOwner]) {
		case 6: return 0x0E570FCA;
		case 7: return 0x454442CA;
		case 8: return COLOR_BALLAS;
		case 9: return 0x2DB3B3CA;
		default: return 0xFFFFFFAA;
	}
	return 0;
}

PreloadAnimLib(playerid, animlib[]) { return ApplyAnimation(playerid,animlib, "null", 0.0, 0,0, 0, 0, 0); }

resetData(playerid) { 
	loginTries[playerid] = 0;
	SetPVarInt(playerid, "AddVehicle", 0);
	pLogged[playerid] = 0;
	return 1;
}

showStats(playerid, tid) {
	new warnText[30], jobtext[50];
	SCM(playerid, COLOR_TEAL, "-----------------------------------------------------------------");
	if(pInfo[tid][pWarns] == 1) { warnText = ""ORANGE"1"WHITE"/3"; }
	else if(pInfo[tid][pWarns] == 2) { warnText = ""DRED"2"WHITE"/3"; }
	else { warnText = "0/3"; }

	if(pInfo[tid][pJob] == 0) { jobtext = "None"; }
	else { format(jobtext, 50, "%s", jInfo[pInfo[tid][pJob]][jName]); }

	SCMEx(playerid, -1, "(%d) %s | Level: %d | Eureka Points: %d/%d | Money in pocket: %s | Bank money: %s | Warns: %s", tid, GetName(tid), pInfo[tid][pLevel], pInfo[tid][pEPoints], 4 * pInfo[tid][pLevel], FormatNumber(pInfo[tid][pMoney]), FormatNumber(pInfo[tid][pBank]), warnText);
	SCMEx(playerid, -1, "Age: %d | Gender: %s | Job: %s | Materials: %s | Drugs: %s", pInfo[tid][pAge], (pInfo[tid][pSex] == 1) ? ("Male") : ("Female"), jobtext, FormatNumber(pInfo[tid][pMaterials]), FormatNumber(pInfo[tid][pDrugs]));
	SCMEx(playerid, -1, "Loyality Account: %s (%slp) | Phone number: %d", (pInfo[tid][pLoyalityAccount] == 1) ? ("Yes") : ("No"), FormatNumber(pInfo[tid][pLoyalityPoints]), pInfo[tid][pPhoneNumber]);
	if(pInfo[tid][pMember] > 0) {
		SCMEx(playerid, -1, "Faction: %s, rank %d and %d days | Faction Warns: %d/3", gInfo[pInfo[tid][pMember]][gName], pInfo[tid][pRank], daysAgo(pInfo[tid][pGJoinDate]), pInfo[tid][pFWarns]);
	}
	else {
		SCMEx(playerid, -1, "Faction: no-one | Factions Punish: %d/15", pInfo[tid][pFPunish]);
	}
	SCM(playerid, COLOR_TEAL, "-----------------------------------------------------------------");
	return 1;
}

FormatNumber(iNum, const szChar[] = ",") {
    new szStr[16];
    format(szStr, sizeof(szStr), "%d", iNum);
	for(new iLen = strlen(szStr) - 3; iLen > 0; iLen -= 3) { strins(szStr, szChar, iLen); }
    return szStr;
}

IsMail(const string[]) { // source: sa-mp.com forum
	static RegEx:mail;
	if(!mail) {		
		mail = regex_build("[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?");
	}
	return regex_match_exid(string, mail);
}

randomString(lenght) {
	new randomChar[][] = {
		"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
		"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
		"1", "2", "3", "4", "5", "6", "7", "8", "9", "0"
	};
	new string[20], rand;
	for(new i; i < lenght; i++) 
	{
		rand = random(sizeof(randomChar));
		strcat(string, randomChar[rand]);
	}
	return string;
}

forward iniGPS();
public iniGPS() {
	cache_get_data(rows, fields);
	if(rows) {
		new x;
		for ( new i = 0, j = cache_get_row_count ( ); i != j; i++ )
		{
			x = cache_get_field_content_int(i, "id"); gpsInfo[x][gpsID] = x;
			cache_get_field_content(i, "Name", gpsInfo[x][gpsName], handle, 50);
			gpsInfo[x][gpsX] = cache_get_field_content_float(i, "gpsX");
			gpsInfo[x][gpsY] = cache_get_field_content_float(i, "gpsY");
			gpsInfo[x][gpsZ] = cache_get_field_content_float(i, "gpsZ");
			cache_get_field_content(i, "addedBy", gpsInfo[x][gpsAddedBy], handle, MAX_PLAYER_NAME + 1);
			cache_get_field_content(i, "gpsCity", gpsInfo[x][gpsCity], handle, 20);
			
			Iter_Add(gpsIter, x);
		}
	}
	else print("There are no location.");
	return 1;
}

forward IniDealer();
public IniDealer() {
	cache_get_data(rows, fields);
	if(rows) {
		new x;
		for ( new i, j = cache_get_row_count ( ); i != j; ++i )
		{
			x = cache_get_field_content_int(i, "dealerID"); dInfo[x][dID] = x;
			dInfo[x][dModel] = cache_get_field_content_int(i, "dealerModel");
			dInfo[x][dPrice] = cache_get_field_content_int(i, "dealerPrice");
			dInfo[x][dPremiumPrice] = cache_get_field_content_int(i, "dealerPremiumPrice");
			dInfo[x][dStock] = cache_get_field_content_int(i, "dealerStock");
			dInfo[x][dType] = cache_get_field_content_int(i, "dealerType");
			
			Iter_Add(dealerVehicles, x);
		}
	}
	else print("There are no vehicles in dealership.");
	return 1;
}

forward addDealer(model, price, pprice, type);
public addDealer(model, price, pprice, type) {
	new x = cache_insert_id();
	dInfo[x][dID] = x, dInfo[x][dModel] = model, dInfo[x][dPrice] = price, dInfo[x][dPremiumPrice] = pprice, dInfo[x][dStock] = 10, dInfo[x][dType] = type;
	Iter_Add(dealerVehicles, x);
	return 1;
}

forward loadPersonalCars(playerid);
public loadPersonalCars(playerid) {
	cache_get_data(rows, fields);
	if(rows) {
		new x, id;
		for ( new i, j = cache_get_row_count ( ); i != j; ++i )
		{
			x = Iter_Free(personalCars);
			id = cache_get_field_content_int(i, "id"); pcInfo[x][pcID] = id;
			pcInfo[x][pcOwner] = cache_get_field_content_int(i, "Owner");
			pcInfo[x][pcModel] = cache_get_field_content_int(i, "Model");
			pcInfo[x][pcPosX] = cache_get_field_content_float(i, "PosX");
			pcInfo[x][pcPosY] = cache_get_field_content_float(i, "PosY");
			pcInfo[x][pcPosZ] = cache_get_field_content_float(i, "PosZ");
			pcInfo[x][pcPosA] = cache_get_field_content_float(i, "PosA");
			cache_get_field_content(i, "CarPlate", pcInfo[x][pcCarPlate], handle, 10);
			pcInfo[x][pcColor1] = cache_get_field_content_int(i, "Color1");
			pcInfo[x][pcColor2] = cache_get_field_content_int(i, "Color2");
			pcInfo[x][pcLockStatus] = cache_get_field_content_int(i, "LockStatus");
			pcInfo[x][pcAge] = cache_get_field_content_int(i, "Age");
			pcInfo[x][pcOdometer] = cache_get_field_content_int(i, "Odometer");
			pcInfo[x][pcInsurance] = cache_get_field_content_int(i, "Insurance");
			
			// Load tunning components
			pcInfo[x][pcMod][1] = cache_get_field_content_int(i, "Mod1");
			pcInfo[x][pcMod][2] = cache_get_field_content_int(i, "Mod2");
			pcInfo[x][pcMod][3] = cache_get_field_content_int(i, "Mod3");
			pcInfo[x][pcMod][4] = cache_get_field_content_int(i, "Mod4");
			pcInfo[x][pcMod][5] = cache_get_field_content_int(i, "Mod5");
			pcInfo[x][pcMod][6] = cache_get_field_content_int(i, "Mod6");
			pcInfo[x][pcMod][7] = cache_get_field_content_int(i, "Mod7");
			pcInfo[x][pcMod][8] = cache_get_field_content_int(i, "Mod8");
			pcInfo[x][pcMod][9] = cache_get_field_content_int(i, "Mod9");
			pcInfo[x][pcMod][10] = cache_get_field_content_int(i, "Mod10");
			pcInfo[x][pcMod][11] = cache_get_field_content_int(i, "Mod11");
			pcInfo[x][pcMod][12] = cache_get_field_content_int(i, "Mod12");
			pcInfo[x][pcMod][13] = cache_get_field_content_int(i, "Mod13");
			pcInfo[x][pcMod][14] = cache_get_field_content_int(i, "Mod14");
			pcInfo[x][pcMod][15] = cache_get_field_content_int(i, "Mod15");
			pcInfo[x][pcMod][16] = cache_get_field_content_int(i, "Mod16");
			
			Iter_Add(personalCars, x);
		}
	}
	return 1;
}

forward buyCar(playerid, model, Float:x, Float:y, Float:z, Float:a);
public buyCar(playerid, model, Float:x, Float:y, Float:z, Float:a) {
	new id = Iter_Free(personalCars), insertID = cache_insert_id();
	pcInfo[id][pcID] = insertID;
	pcInfo[id][pcOwner] = pInfo[playerid][pSQLID], pcInfo[id][pcModel] = model, pcInfo[id][pcPosX] = x, pcInfo[id][pcPosY] = y, pcInfo[id][pcPosZ] = z, pcInfo[id][pcPosA] = a;
	format(pcInfo[id][pcCarPlate], 10, "eureka RPG");
	pcInfo[id][pcColor1] = pcInfo[id][pcColor2] = pcInfo[id][pcOdometer] = pcInfo[id][pcSpawned] = 0, pcInfo[id][pcLockStatus] = 1, pcInfo[id][pcAge] = gettime(), pcInfo[id][pcInsurance] = 10;
			
	Iter_Add(personalCars, id);
}

forward SaveComponent(vehicleid, componentid); // sa:mp wiki
public SaveComponent(vehicleid, componentid)
{
    new playerid = GetVehicleDriver(vehicleid);
	if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER) {
	    if(pcInfo[vehID[vehicleid]][pcOwner] == pInfo[playerid][pSQLID]) {
			for(new s=0; s<20; s++) {
 				if(componentid == spoiler[s][0]) {
   					pcInfo[vehID[vehicleid]][pcMod][0] = componentid;
				}
			}
			for(new s=0; s<4; s++) {
 				if(componentid == bscoop[s][0]) {
   					pcInfo[vehID[vehicleid]][pcMod][1] = componentid;
				}
			}
			for(new s=0; s<17; s++) {
 				if(componentid == rscoop[s][0]) {
   					pcInfo[vehID[vehicleid]][pcMod][2] = componentid;
				}
			}
			for(new s=0; s<21; s++) {
 				if(componentid == rskirt[s][0]) {
   					pcInfo[vehID[vehicleid]][pcMod][3] = componentid;
				}
			}
			for(new s=0; s<21; s++) {
 				if(componentid == lskirt[s][0]) {
   					pcInfo[vehID[vehicleid]][pcMod][16] = componentid;
				}
			}
			for(new s=0; s<2; s++) {
 				if(componentid == modLights[s][0]) {
   					pcInfo[vehID[vehicleid]][pcMod][4] = componentid;
				}
			}
			for(new s=0; s<3; s++) {
 				if(componentid == nitro[s][0]) {
   					pcInfo[vehID[vehicleid]][pcMod][5] = componentid;
				}
			}
			for(new s=0; s<28; s++) {
 				if(componentid == exhaust[s][0]) {
   					pcInfo[vehID[vehicleid]][pcMod][6] = componentid;
				}
			}
			for(new s=0; s<17; s++) {
 				if(componentid == wheels[s][0]) {
   					pcInfo[vehID[vehicleid]][pcMod][7] = componentid;
				}
			}
			for(new s=0; s<1; s++) {
 				if(componentid == modBase[s][0]) {
   					pcInfo[vehID[vehicleid]][pcMod][8] = componentid;
				}
			}
			for(new s=0; s<1; s++) {
 				if(componentid == hydraulics[s][0]) {
   					pcInfo[vehID[vehicleid]][pcMod][9] = componentid;
				}
			}
			for(new s=0; s<23; s++) {
 				if(componentid == fbumper[s][0]) {
   					pcInfo[vehID[vehicleid]][pcMod][10] = componentid;
				}
			}
			for(new s=0; s<22; s++) {
 				if(componentid == rbumper[s][0]) {
   					pcInfo[vehID[vehicleid]][pcMod][11] = componentid;
				}
			}
			for(new s=0; s<2; s++) {
 				if(componentid == bventr[s][0]) {
   					pcInfo[vehID[vehicleid]][pcMod][12] = componentid;
				}
			}
			for(new s=0; s<2; s++) {
 				if(componentid == bventl[s][0]) {
   					pcInfo[vehID[vehicleid]][pcMod][13] = componentid;
				}
			}
			for(new s=0; s<2; s++) {
 				if(componentid == fbbars[s][0]) {
   					pcInfo[vehID[vehicleid]][pcMod][15] = componentid;
				}
			}
			for(new s=0; s<4; s++) {
 				if(componentid == rbbars[s][0]) {
   					pcInfo[vehID[vehicleid]][pcMod][14] = componentid;
				}
			}
			return 1;
		}
		else SCM(playerid, -1, ""CREM"The new adjustments weren`t saved because you are not the owner of the car.");
	}
	return 0;
}

GetDistancePlayerVeh(playerid, veh) {

	new
	    Float:Floats[7];

	GetPlayerPos(playerid, Floats[0], Floats[1], Floats[2]);
	GetVehiclePos(veh, Floats[3], Floats[4], Floats[5]);
	Floats[6] = floatsqroot((Floats[3]-Floats[0])*(Floats[3]-Floats[0])+(Floats[4]-Floats[1])*(Floats[4]-Floats[1])+(Floats[5]-Floats[2])*(Floats[5]-Floats[2]));

	return floatround(Floats[6]);
}

GetVehicleDriver(vehicleid) {
    foreach(new i : Player) {
		if (IsPlayerInVehicle(i, vehicleid) && GetPlayerState(i) == 2) 
        	return i;
    }
    return -1;
}

GetClosestVehicle(playerid, exception = INVALID_VEHICLE_ID) {
    new Float:distance, target = -1;

    for(new v; v < MAX_VEHICLES; v++) if(doesVehicleExist(v)) {
        if(v != exception && (target < 0 || distance > GetDistancePlayerVeh(playerid, v))) {
            target = v;
            distance = GetDistancePlayerVeh(playerid, v);
        }
    }
    return target;
}

IsVehicleOccupied(vehicleid) {
	foreach(new i : Player) {
		if(IsPlayerInVehicle(i, vehicleid )) 
			return 1;
	}
	return 0;
}

GetSpeed(playerid) {
    new Float:ST[3];
    GetVehicleVelocity(GetPlayerVehicleID(playerid),ST[0],ST[1],ST[2]);
    return floatround(1.61*floatsqroot(floatpower(floatabs(ST[0]), 2.0) + floatpower(floatabs(ST[1]), 2.0) + floatpower(floatabs(ST[2]), 2.0)) * 100.3);
}

ModVehicle(vehicleid) {
	if(vehicleid <= 0 || vehicleid >= MAX_VEHICLES) return;
	for(new i = 0; i < 17; ++i) {
		if(pcInfo[vehID[vehicleid]][pcMod][i] != 0) {
			AddVehicleComponent(vehicleid, pcInfo[vehID[vehicleid]][pcMod][i]);
		}
	}
}

personalPlayerid(iteratorid) {
	foreach(new x : Player) {
		if(pInfo[x][pSQLID] == pcInfo[iteratorid][pcOwner]) 
			return x;
	}
	return -1;
}

getVehicleOwner(iteratorid) {
	new name[MAX_PLAYER_NAME + 1], count;
	foreach(new x : Player) {
		if(pInfo[x][pSQLID] == pcInfo[iteratorid][pcOwner]) { 
			format(name, MAX_PLAYER_NAME + 1, GetName(x)); 
			count = 1;
		}
	}
	
	if(count == 0) 
		name = "Unknown";
	return name;
}

getInsurancePrice(days, km) {
	new dVal = 70 * days, kmVal = (km / 1000) * 150;
	return 5000 + dVal + kmVal;
}

personalCount(playerid) { 
	new count;
	foreach(new x : personalCars) {
		if(pcInfo[x][pcOwner] == pInfo[playerid][pSQLID]) count++;
	}
	return count;
}

showPlayerCars(playerid) {
	new string[4][1500], carID;
	format(string[0], 40, "SERVER: Personal cars (%d/%d)", personalCount(playerid), pInfo[playerid][pMaxSlots]);
	format(string[1], 40, "Vehicle\tSpawned\tTime to despawn\n");
	foreach(new x : personalCars) {
		if(pcInfo[x][pcOwner] == pInfo[playerid][pSQLID]) {
			pcSelected[playerid][carID] = x;
			carID++;
			format(gMsg, 10, timeFormat(pcInfo[x][pcTimeToSpawn]));
			format(string[2], 1500, "%s%s\t%s\t%s\n", string[2], vehName[pcInfo[x][pcModel] - 400], (pcInfo[x][pcSpawned]) ? ("{00A645}spawned") : ("{FF0000}despawned"), (pcInfo[x][pcSpawned]) ? (gMsg) : ("--:--"));
		}
	}
	format(string[3], 1500, "%s%s\n"CREM"[+] Add vehicle slot", string[1], string[2]);
	ShowPlayerDialog(playerid, DIALOG_VEHICLES, DIALOG_STYLE_TABLIST_HEADERS, string[0], string[3], "Select", "Cancel");
	return 1;
}

timeFormat(seconds) {
	new timeStr[15];
	format(timeStr, 15,"%02d:%02d",seconds/60, seconds - seconds/60*60);
	return timeStr;
}

getDealerPrice(model) {
	foreach(new x : dealerVehicles) {
		if(dInfo[x][dModel] == model) {
			switch(dInfo[x][dType]) {
				case 1: return dInfo[x][dPrice];
				case 2: return 0;
			}
		}
	}
	return 0;
}

sendDutyCops(color, const text[], {Float, _}:...) { // source: sa-mp.com forum
	static args, str[144];

	if ((args = numargs()) == 2)
	{
	    foreach(new i : Player) {
			if(pInfo[i][pMember] && gInfo[pInfo[i][pMember]][gType] == 1 && pInfo[i][pDuty] == 1) {
				SCM(i, color, text);
			}
		}
	}
	else
	{
		while (--args >= 2)
		{
			#emit LCTRL 5
			#emit LOAD.alt args
			#emit SHL.C.alt 2
			#emit ADD.C 12
			#emit ADD
			#emit LOAD.I
			#emit PUSH.pri
		}
		#emit PUSH.S text
		#emit PUSH.C 144
		#emit PUSH.C str
		#emit LOAD.S.pri 8
		#emit ADD.C 4
		#emit PUSH.pri
		#emit SYSREQ.C format
		#emit LCTRL 5
		#emit SCTRL 4

		foreach(new i : Player) {
			if(pInfo[i][pMember] && gInfo[pInfo[i][pMember]][gType] == 1 && pInfo[i][pDuty] == 1) {
				SCMEx(i, color, str);
			}
		}

		#emit RETN
	}
	return 1;
}

sendGroup(color, faction, string[]) {
	foreach(new i : Player) {
		if(pInfo[i][pMember] == faction) {
			SCM(i, color, string);
		}
	}
	return 1;
}

sendgType(color, type, msg[]) {
	foreach(new i : Player) {
		if(pInfo[i][pMember] && gInfo[pInfo[i][pMember]][gType] == type) {
			SCMEx(i, color, msg);
		}
	}
	return 1;
}

adminOnly(playerid, admin) {
	SCMEx(playerid, COLOR_GREY, ""GREY"You need to have admin level "ORANGE"%d+"GREY" to use this command.", admin);
	return 1;
}

sendAdmins(color, const text[], {Float, _}:...) { // source: sa-mp.com forum
	static args, str[144];

	if ((args = numargs()) == 2)
	{
	    foreach(new i : Admins) {
			SCM(i, color, text); 
		}
	}
	else
	{
		while (--args >= 2)
		{
			#emit LCTRL 5
			#emit LOAD.alt args
			#emit SHL.C.alt 2
			#emit ADD.C 12
			#emit ADD
			#emit LOAD.I
			#emit PUSH.pri
		}
		#emit PUSH.S text
		#emit PUSH.C 144
		#emit PUSH.C str
		#emit LOAD.S.pri 8
		#emit ADD.C 4
		#emit PUSH.pri
		#emit SYSREQ.C format
		#emit LCTRL 5
		#emit SCTRL 4

		foreach(new i : Admins) {
			SCM(i, color, str); 
		}

		#emit RETN
	}
	return 1;
}

SCMEx(playerid, color, fstring[], {Float, _}:...) { // source: sa-mp.com forum
    #if defined DEBUG
	    printf("[debug] SCM(%d,%d,%s,...)",playerid,color,fstring);
	#endif
    new n = numargs() * 4;
	if (n == 3 * 4) {
		return SCM(playerid, color, fstring);
	}
	else {
		new message[255];
		new arg_start;
        new arg_end;
        new i = 0;

        #emit CONST.pri  fstring
        #emit ADD.C    0x4
        #emit STOR.S.pri arg_start

        #emit LOAD.S.pri n
        #emit ADD.C    0x8
        #emit STOR.S.pri arg_end

        for (i = arg_end; i >= arg_start; i -= 4)
        {
            #emit LCTRL    5
            #emit LOAD.S.alt i
            #emit ADD
            #emit LOAD.I
            #emit PUSH.pri
        }
        #emit PUSH.S  fstring
        #emit PUSH.C  128
        #emit PUSH.ADR message
        #emit PUSH.S  n
        #emit SYSREQ.C format

        i = n / 4 + 1;
        while (--i >= 0) {
            #emit STACK 0x4
        }
        return SCM(playerid, color, message);
	}
}

Clearchat(player, lines) {
	for(new l; l <= lines; l++) { SCM(player, -1, " "); }
	return 1;
}

IsNumeric(const string[]) {
	for (new i = 0, j = strlen(string); i < j; i++) {
		if (string[i] > '9' || string[i] < '0') 
			return 0;
	}
	return 1;
}

getPlayerSkill(value) {
	switch(value)	{
		case 0..26: return 1;
		case 27..56: return 2;
		case 57..100: return 3;
		case 101..135: return 4;
		case 136..160: return 5;
		case 161..200: return 6;
		default: return 6;
	}
	return 0;
}

IsPlayerInRangeOfPlayer(playerid, playerid2, Float: radius) {
	new Float:X, Float:Y, Float:Z;
	GetPlayerPos(playerid2, X, Y, Z);

	return IsPlayerInRangeOfPoint(playerid, radius, X, Y, Z);
}

nearByMessage(playerid, color, string[], Float: Distance3 = 12.0) {
	new Float:X, Float:Y, Float:Z;
	GetPlayerPos(playerid, X, Y, Z);

	foreach(new i : Player) {
        if(IsPlayerInRangeOfPoint(i, Distance3, X, Y, Z) && (GetPlayerVirtualWorld(i) == GetPlayerVirtualWorld(playerid))) {
			SCM(i, color, string);
	    }
	}

	return 1;
}

IsABike(carid) {
	new model = GetVehicleModel(carid);
	if(model == 510 || model == 509 || model == 481) { return 1; }
	return 0;
}