#include <strlib>

#define MAX_BIZ 100

enum eBizz {
    bID,
    bType,
    bOwner[MAX_PLAYER_NAME+1],
    bMessage[50],
    Float:bEnter[3],
    Float:bExit[3],
    bMapIcon,
    bLevel,
    bFee,
    bBuyPrice,
    bBalance,
    bLocked,
    bInterior,
    bVirtual,
    bGas,
    bStatic,

    bPickup,
    Text3D:bLabel
}
new BizzInfo[MAX_BIZ][eBizz];

new Iterator:Biz<MAX_BIZ>; 

YCMD:createbizz(playerid, params[], help) {
	if(pInfo[playerid][pAdmin] < 5) return adminOnly(playerid, 6);

	new type, value, level, micon, text[50];
	if(sscanf(params, "iiiis[45]", type, value, level, micon, text)) {
        Syntax(playerid, "/createbiz [type] [value] [level] [map icon] [text]");
        
        SCM(playerid, -1, "Type: Banca (1), Gun Shop (2), Club (3), Restaurant (4), Sex shop (5), 24/7 (6), Binco (7), Burger (8), Casino (9)");
        SCM(playerid, -1, "CNN (10), Gas Station (11), PNS (12), Pizza (13)");

        return true; 
    } 

	new bizID = Iter_Free(Biz);

	Iter_Add(Biz, bizID);
	GetPlayerPos(playerid, BizzInfo[bizID][bEnter][0], BizzInfo[bizID][bEnter][1], BizzInfo[bizID][bEnter][2]); 

    BizzInfo[bizID][bMapIcon] = micon;
    BizzInfo[bizID][bType] = type;
    BizzInfo[bizID][bBuyPrice] = value;
    BizzInfo[bizID][bLevel] = level;
    format(BizzInfo[bizID][bMessage], 50, text);

    gQuery[0] = (EOS);
	mysql_format(handle, gQuery, 256, "INSERT INTO `bizz` (`Type`, `mapIcon`, `Level`, `BuyPrice`, `Message`, `eX`, `eY`, `eZ`) VALUES ('%d', '%d', '%d', '%d', '%s', '%f', '%f', '%f')", type, micon, level, value, text, BizzInfo[bizID][bEnter][0], BizzInfo[bizID][bEnter][1], BizzInfo[bizID][bEnter][2]);
	mysql_tquery(handle, gQuery, "finish_create_biz", "ii", playerid, bizID);  	 

    return true;
}

YCMD:editbiz(playerid, params[], help) {
    if(pInfo[playerid][pAdmin] < 5) return adminOnly(playerid, 6);
    new bizID;
    if(sscanf(params, "i", bizID)) return Syntax(playerid, "/editbiz [biz id]"); 

    gString[0] = (EOS);
    format(gString, 70, "Editare biz %s", BizzInfo[bizID][bMessage]);
    Dialog_Show(playerid, dEditBiz, DIALOG_STYLE_LIST, gString, "Interior & VW\nLevel\nMap Icon\nPrice\nMessage\nTip\nFee\nTeleport me to biz", "Select", "Cancel");

    SetPVarInt(playerid, "tempBizID", bizID);

    return true;
}

Dialog:dEditBiz(playerid, response, listitem, inputtext[]) {
    if(pInfo[playerid][pAdmin] < 5) return adminOnly(playerid, 6);
    if(!response) return true;

    switch(listitem) {
        case 0: Dialog_Show(playerid, dEditInterior, DIALOG_STYLE_INPUT, "Interior & VW", "X, Y, Z, INTERIOR, VW\nNu trebuie sa aiba spatii intre virgula si cuvant.", "Ok", "Cancel");
        case 1: Dialog_Show(playerid, dEditLevel, DIALOG_STYLE_INPUT, "Level", "Introdu level-ul pe care doresti sa il aiba biz-ul.", "Ok", "Cancel");
        case 2: Dialog_Show(playerid, dEditMapIcon, DIALOG_STYLE_INPUT, "Map Icon", "Introdu map icon-ul pe care doresti sa il aiba biz-ul.", "Ok", "Cancel");
        case 3: Dialog_Show(playerid, dEditPrice, DIALOG_STYLE_INPUT, "Price", "Introdu pretul pe care sa il aiba biz-ul.", "Ok", "Cancel");
        case 4: Dialog_Show(playerid, dEditMessage, DIALOG_STYLE_INPUT, "Message", "Introdu mesajul pe care doresti sa il aiba biz-ul.", "Ok", "Cancel");
        case 5: Dialog_Show(playerid, dEditType, DIALOG_STYLE_INPUT, "Tip", "Introdu tip-ul pe care doresti sa il aiba biz-ul.", "Ok", "Cancel");
        case 6: Dialog_Show(playerid, dEditFee, DIALOG_STYLE_INPUT, "Fee", "Introdu fee-ul pe care doresti sa il aiba biz-ul.", "Ok", "Cancel");
        case 7: {
            new bizID = GetPVarInt(playerid, "tempBizID");

            SetPlayerPos(playerid, BizzInfo[bizID][bEnter][0], BizzInfo[bizID][bEnter][1], BizzInfo[bizID][bEnter][2]);

            DeletePVar(playerid, "tempBizID");
        }
    }

    return true;
}

Dialog:dEditInterior(playerid, response, listitem, inputtext[]) {
    if(pInfo[playerid][pAdmin] < 5) return adminOnly(playerid, 6);
    if(!response) return true; 

    new output[10][10],
        bizID = GetPVarInt(playerid, "tempBizID");

    DeletePVar(playerid, "tempBizID"); 
    strexplode(output, inputtext, ",");

    BizzInfo[bizID][bExit][0] = floatstr(output[0]);
    BizzInfo[bizID][bExit][1] = floatstr(output[1]);
    BizzInfo[bizID][bExit][2] = floatstr(output[2]);
    BizzInfo[bizID][bInterior] = strval(output[3]);
    BizzInfo[bizID][bVirtual] = (100+bizID); 
    
	gQuery[0] = (EOS);
	mysql_format(handle, gQuery, 284, "UPDATE `bizz` SET `eeX` = '%f', `eeY` = '%f', `eeZ` = '%f', `Interior` = '%d', `Virtual` = '%d' WHERE `id` = '%d'", BizzInfo[bizID][bExit][0], BizzInfo[bizID][bExit][1], BizzInfo[bizID][bExit][2], BizzInfo[bizID][bInterior], BizzInfo[bizID][bVirtual], bizID);
	mysql_tquery(handle, gQuery, "edit_interior_finish", "ii", playerid, bizID); 

    return true;
}

function edit_interior_finish(playerid, bizID) {
    sendAdmins(0xFF9100FF, "Biz: Admin %s edited biz with id %d", GetName(playerid), bizID);
}

Dialog:dEditLevel(playerid, response, listitem, inputtext[]) {

    return true;
}

Dialog:dEditMapIcon(playerid, response, listitem, inputtext[]) {

    return true;
}

Dialog:dEditPrice(playerid, response, listitem, inputtext[]) {

    return true;
}

Dialog:dEditMessage(playerid, response, listitem, inputtext[]) {

    return true;
}

Dialog:dEditType(playerid, response, listitem, inputtext[]) {

    return true;
}

Dialog:dEditFee(playerid, response, listitem, inputtext[]) {

    return true;
}

function EnterExitBiz(playerid) {

    foreach(new bizID : Biz) {
        if(IsPlayerInRangeOfPoint(playerid, 3.0, BizzInfo[bizID][bEnter][0], BizzInfo[bizID][bEnter][1], BizzInfo[bizID][bEnter][2])) {
            SetPlayerPos(playerid, BizzInfo[bizID][bExit][0], BizzInfo[bizID][bExit][1], BizzInfo[bizID][bExit][2]);
            SetPlayerInterior(playerid, BizzInfo[bizID][bInterior]);
            SetPlayerVirtualWorld(playerid, BizzInfo[bizID][bVirtual]);
        }
        else if(IsPlayerInRangeOfPoint(playerid, 3.0, BizzInfo[bizID][bExit][0], BizzInfo[bizID][bExit][1], BizzInfo[bizID][bExit][2])) {
            SetPlayerPos(playerid, BizzInfo[bizID][bEnter][0], BizzInfo[bizID][bEnter][1], BizzInfo[bizID][bEnter][2]);
            SetPlayerInterior(playerid, 0);
            SetPlayerVirtualWorld(playerid, 0);
        }
        else continue;
    } 
}

function finish_create_biz(playerid, bizID) { 
    updateBizzLabel(bizID);
    SCMEx(playerid, -1, "Acum poti folosi comanda /editbiz pentru a face setarile bizului.");
    sendAdmins(0xFF9100FF, "Biz: Admin %s added a new biz on server. %d", bizID);
}

function loadBiz() { 
    cache_get_data(rows, fields);
    if(rows) {
        new id, oldtick = GetTickCount();
        for(new i, j = cache_get_row_count ( ); i != j; ++i) {
            id = cache_get_field_content_int(i, "id");
            BizzInfo[id][bID] = id;

            BizzInfo[id][bType] = cache_get_field_content_int(i, "Type");
            BizzInfo[id][bMapIcon] = cache_get_field_content_int(i, "mapIcon");
            BizzInfo[id][bLevel] = cache_get_field_content_int(i, "Level");
            BizzInfo[id][bFee] = cache_get_field_content_int(i, "Fee");
            BizzInfo[id][bBuyPrice] = cache_get_field_content_int(i, "BuyPrice");
            BizzInfo[id][bBalance] = cache_get_field_content_int(i, "Balance");
            BizzInfo[id][bLocked] = cache_get_field_content_int(i, "Locked");
            BizzInfo[id][bInterior] = cache_get_field_content_int(i, "Interior");
            BizzInfo[id][bVirtual] = cache_get_field_content_int(i, "Virtual");
            BizzInfo[id][bGas] = cache_get_field_content_int(i, "Gas");
            BizzInfo[id][bStatic] = cache_get_field_content_int(i, "Static");

            BizzInfo[id][bEnter][0] = cache_get_field_content_float(i, "eX");
            BizzInfo[id][bEnter][1] = cache_get_field_content_float(i, "eY");
            BizzInfo[id][bEnter][2] = cache_get_field_content_float(i, "eZ"); 

            BizzInfo[id][bExit][0] = cache_get_field_content_float(i, "eeX");
            BizzInfo[id][bExit][1] = cache_get_field_content_float(i, "eeX");
            BizzInfo[id][bExit][2] = cache_get_field_content_float(i, "eeX"); 

            cache_get_field_content(i, "Message", BizzInfo[id][bMessage], handle, 49);
            cache_get_field_content(i, "Owner", BizzInfo[id][bOwner], handle, MAX_PLAYER_NAME+1); 

            if(BizzInfo[id][bMapIcon] != 0) {
                CreateDynamicMapIcon(BizzInfo[id][bEnter][0], BizzInfo[id][bEnter][1], BizzInfo[id][bEnter][2], BizzInfo[id][bMapIcon], 0); 
            }  

            updateBizzLabel(id);
            Iter_Add(Biz, id);
        }

        printf("[SQL] Am incarcat cu succes %d bizz-uri in %d ms.", Iter_Count(Biz), GetTickCount() - oldtick);
    }
} 

function updateBizzLabel(id) { 
    new lString[256], pret[150];

    if(BizzInfo[id][bLabel]) DestroyDynamic3DTextLabel(BizzInfo[id][bLabel]);
    if(BizzInfo[id][bBuyPrice] != 0) format(pret, sizeof(pret), "\n{FFFFFF}Pret: {a1a3d4}$%s (/buybiz)", FormatNumber(BizzInfo[id][bBuyPrice]));
    if(strlen(BizzInfo[id][bOwner]) < 6) format(lString, sizeof(lString), "{FFFFFF}Business {a1a3d4}#%d \n%s{FFFFFF}\n {FFFFFF}Value: {a1a3d4}%s \n{FFFFFF}Fee: {a1a3d4}$%s \n{FFFFFF}Level: {a1a3d4}%d", id, BizzInfo[id][bMessage], FormatNumber(BizzInfo[id][bBuyPrice]), FormatNumber(BizzInfo[id][bFee]), BizzInfo[id][bLevel]);
    else format(lString, sizeof(lString), "{FFFFFF}Business {a1a3d4}#%d \n%s{FFFFFF}\n {FFFFFF}Owner: {a1a3d4}%s \n{FFFFFF}Fee: {a1a3d4}$%s \n{FFFFFF}Level: {a1a3d4}%d%s", id, BizzInfo[id][bMessage], BizzInfo[id][bOwner], BizzInfo[id][bFee], BizzInfo[id][bLevel], pret);
    
    BizzInfo[id][bLabel] = CreateDynamic3DTextLabel(lString, 0xFFFFFF99, BizzInfo[id][bEnter][0], BizzInfo[id][bEnter][1], BizzInfo[id][bEnter][2], 25, INVALID_PLAYER_ID, INVALID_VEHICLE_ID);
    BizzInfo[id][bPickup] = CreateDynamicPickup(1239, 23, BizzInfo[id][bEnter][0], BizzInfo[id][bEnter][1], BizzInfo[id][bEnter][2], -1, -1, -1, 30.0);

    if(BizzInfo[id][bMapIcon] != 0) {
        CreateDynamicMapIcon(BizzInfo[id][bEnter][0], BizzInfo[id][bEnter][1], BizzInfo[id][bEnter][2], BizzInfo[id][bMapIcon], 0);
    }
} 