enum jobInfo {
	jID, jName[50], jStatus, jType,
	
	Float:jX, Float:jY, Float:jZ,
	
	jPickup, Text3D:jLabel
};
new jInfo[MAX_JOBS][jobInfo];

new Iterator:Jobs<MAX_JOBS>;
 
function saveJob(id) { 

    gQuery[0] = (EOS);
	mysql_format(handle, gQuery, 250, "UPDATE `jobs` SET `Name` = '%e', `Type` = '%d', `X` = '%f', `Y` = '%f', `Z` = '%f', `Status` = '%d' WHERE `id` = '%d'", jInfo[id][jName], jInfo[id][jType], jInfo[id][jX], jInfo[id][jY], jInfo[id][jZ], jInfo[id][jStatus], id);
	mysql_tquery(handle, gQuery, "", "");

	return 1;
} 

function loadJobs() {
	cache_get_data(rows, fields);
	if(rows) {
		new id, oldtick = GetTickCount();
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
			
            Iter_Add(Jobs, id);
		}
		printf("[SQL] Am incarcat cu succes %d job-uri in %d ms.", id, GetTickCount() - oldtick);
	}
	else print("The are no jobs.");
	return 1;
}

YCMD:gotojobs(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] == 0) return adminOnly(playerid, 1);

	new header[60], contentStr[480], finalStr[550], count;
	format(header, 60, "#\tJob name\tOnline workers\n");

	foreach(new x : Jobs) {
		if(jInfo[x][jID] > 0) {
			foreach(new z : Player) { if(pInfo[z][pJob] == x) { count++; } }
			format(contentStr, 480, "%s%d\t%s\t%d\n", contentStr, x, jInfo[x][jName], count);
		}
	}

	format(finalStr, 550, "%s%s", header, contentStr);
	Dialog_Show(playerid, dAJobs, DIALOG_STYLE_TABLIST_HEADERS, "SERVER: Admin go to jobs", finalStr, "Select", "Cancel");

	return true;
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

YCMD:jobs(playerid, params[], help) {
	new header[60], contentStr[480], finalStr[550], count;
	format(header, 60, "#\tJob name\tOnline workers\n");
	foreach(new x : Jobs) {
		if(jInfo[x][jID] > 0) {
			foreach(new z : Player) { if(pInfo[z][pJob] == x) { count++; } }
			format(contentStr, 480, "%s%d\t%s\t%d\n", contentStr, x, jInfo[x][jName], count);
		}
	}
	format(finalStr, 550, "%s%s", header, contentStr);
	Dialog_Show(playerid, dJobs, DIALOG_STYLE_TABLIST_HEADERS, "SERVER: Jobs", finalStr, "Select", "Cancel");
	return 1;
}

Dialog:dJobs(playerid, response, listitem, inputtext[]) {
	if(!response) return true;
 
	new x = listitem+1, 
		Float:distance = GetPlayerDistanceFromPoint(playerid, jInfo[x][jX], jInfo[x][jY], jInfo[x][jZ]);

	SCMEx(playerid, COLOR_YELLOW, ""YELLOW"Our system placed you a checkpoint to "ORANGE"%s"YELLOW". Distance: %0.2f meters.", jInfo[x][jName], distance);
	SetPlayerCheckpoint(playerid, jInfo[x][jX], jInfo[x][jY], jInfo[x][jZ], 2.0);

	Checkpoint[playerid] = 1;

	return true;
} 

Dialog:dAJobs(playerid, response, listitem, inputtext[]) {
	if(!response) return true;
 
	new para = listitem+1; 

	SetPlayerPos(playerid, jInfo[para][jX], jInfo[para][jY], jInfo[para][jZ]), SetPlayerVirtualWorld(playerid, 0), SetPlayerInterior(playerid, 0);
	if(IsPlayerInAnyVehicle(playerid)) { SetVehiclePos(GetPlayerVehicleID(playerid), jInfo[para][jX], jInfo[para][jY], jInfo[para][jZ]); }

	return true;
}  

function SetPlayerJobs(playerid, type) {
    if(IsPlayerInAnyVehicle(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this action on foot.");
    if(pInfo[playerid][pJob] > 0 && type == 1) return SCM(playerid, COLOR_GREY, "You already have a job, use /quitjob first.");
	if(pInfo[playerid][pJob] == 0 && type == 0) return SCM(playerid, COLOR_GREY, "You don't have a job.");
    if(Checkpoint[playerid] > 0 && type == 0) return SCM(playerid, COLOR_GREY, "You have a checkpoint active, use /killcp to disable it.");

    new jobID = -1;
    foreach(new i : Jobs) {
        if(IsPlayerInRangeOfPoint(playerid, 3.0, jInfo[i][jX], jInfo[i][jY], jInfo[i][jZ])) {
            jobID = i;
            break;
        }
        continue;
    }

    if(type == 1) {  
        if(jInfo[jobID][jStatus] == 1) {
            pInfo[playerid][pJob] = jobID;
            SCMEx(playerid, -1, "{3594A1}Congratulation! Your job is now: %s.", jInfo[jobID][jName]);

            return true;
        }
        else return SCM(playerid, COLOR_SBLUE, "This job was dezactivated by a administrator.");  
    }
    else if(type == 0) {
        DisablePlayerCheckpoint(playerid);
        DisablePlayerRaceCheckpoint(playerid);
        Checkpoint[playerid] = 0;	
        pInfo[playerid][pJob] = 0;
        SCM(playerid, COLOR_WHITE, "You have used /quitjob and you have quited your job.");
    }

    return true;
} 

// YCMD:work(playerid, params[], help) {
// 	if(IsPlayerInAnyVehicle(playerid)) return SCM(playerid, COLOR_GREY, "You can't use this action on foot.");
// 	if(pInfo[playerid][pJob] == 0) return SCM(playerid, COLOR_GREY, "You can not use this command because you don`t have a job.");
// 	new i = pInfo[playerid][pJob];
// 	new jtype = jInfo[i][jType];

// 	if(jtype != 1) {
// 		if(IsPlayerInRangeOfPoint(playerid, 3.0, jInfo[i][jX], jInfo[i][jY], jInfo[i][jZ])) {
// 			if(jInfo[i][jStatus] == 1) {
// 				if(jInfo[pInfo[playerid][pJob]][jType] == 2) {

// 					if(Checkpoint[playerid] > 0) return SCM(playerid, COLOR_GREY, "You have a checkpoint active, use /killcp to disable it.");
// 					SetPlayerCheckpoint(playerid, 2771.7961,-1625.9692,10.9272, 4.0);
// 					SCM(playerid, COLOR_SBLUE, "Job info: "WHITE"The car was loaded with guns, you need to deliver them and get your materials.");
// 					SCM(playerid, COLOR_SBLUE, "Job info: "WHITE"You are not allowed to get out of the car or to destroy it.");
// 					new spawn = random(sizeof(randomArms));
// 					new vehicleidz = CreateVehicle(482, randomArms[spawn][0], randomArms[spawn][1], randomArms[spawn][2], randomArms[spawn][3], -1, -1, -1);
// 					PutPlayerInVehicle(playerid, vehicleidz, 0);
// 					jobVehicle[playerid] = vehicleidz, Checkpoint[playerid] = 2;
// 					new lights, engine, alarm, doors, bonnet, boot, objective;
// 					GetVehicleParamsEx(vehicleidz, engine, lights, alarm, doors, bonnet, boot, objective);
// 					SetVehicleParamsEx(vehicleidz, VEHICLE_PARAMS_ON, lights, alarm, VEHICLE_PARAMS_OFF, bonnet, boot, objective);
// 					armsObject[playerid][0] = CreatePlayerObject(playerid, 1271, 2770.10, -1627.74, 11.51, 0.00, 0.00, 0.00);
// 					armsObject[playerid][1] = CreatePlayerObject(playerid, 1271, 2770.91, -1628.07, 11.51, 0.00, 0.00, 0.00);
// 					armsObject[playerid][2] = CreatePlayerObject(playerid, 2358, 2770.42, -1627.81, 11.99, 0.19, -0.79, -20.60);

// 					AttachPlayerObjectToVehicle(playerid, armsObject[playerid][0], jobVehicle[playerid], 0.019999, -1.200000, 0.000000, 0.000000, 0.000000, 0.000000);
// 					AttachPlayerObjectToVehicle(playerid, armsObject[playerid][1], jobVehicle[playerid], 0.000000, -2.000000, 0.000000, 0.000000, 0.000000, 0.000000);
// 					AttachPlayerObjectToVehicle(playerid, armsObject[playerid][2], jobVehicle[playerid], -0.600000, -1.419999, -0.019999, 0.000000, 0.000000, 90.000000 );
// 				}
// 			}
// 			else SCM(playerid, COLOR_SBLUE, "This job was dezactivated by an administrator.");
// 		}
// 		else {
// 			SetPlayerCheckpoint(playerid, jInfo[i][jX], jInfo[i][jY], jInfo[i][jZ], 0.75), Checkpoint[playerid] = 4;
// 			SCM(playerid, COLOR_GREY, "You are not in right place, follow the checkpoint and try again.");
// 		}
// 	}
// 	else { 
// 		SCM(playerid, -1, "You can not use this command now.");
// 	}
// 	return 1;
// }

updateJobLabel(id, type = 0) {
	if(type == 2) DestroyDynamic3DTextLabel(jInfo[id][jLabel]);
	new jtype = jInfo[id][jType];

	if(jtype == 1) {
		format(gMsg, 128, "{0D82A8}Job #%d\nName: "WHITE"%s\n{0D82A8}%s\n{0D82A8}Press "WHITE"Y{0D82A8} for get job\nPress "WHITE"N{0D82A8} for quit job", id, jInfo[id][jName], (jInfo[id][jStatus]) ? ("Type /getjob to get it") : ("This job is disabled"));
	}
	else {
		format(gMsg, 128, "{0D82A8}Job #%d\nName: "WHITE"%s\n{0D82A8}%s", id, jInfo[id][jName], (jInfo[id][jStatus]) ? ("Press Y to get job\nIf you are employed, type /work") : ("This job is disabled"));
	}
	jInfo[id][jLabel] = CreateDynamic3DTextLabel(gMsg, COLOR_YELLOW, jInfo[id][jX], jInfo[id][jY], jInfo[id][jZ], 100, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, -1, -1, -1, 30.0);
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