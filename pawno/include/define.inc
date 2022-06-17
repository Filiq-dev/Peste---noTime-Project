#define function%0(%1) forward%0(%1); public%0(%1)

// Colors
#define COLOR_GREY          0xAFAFAFAA
#define COLOR_GREEN         0x4DAD2B2B 
#define COLOR_YELLOW        0xFFFF00AA
#define COLOR_LIGHTBLUE     0x33CCFFAA
#define COLOR_LIGHTRED      0xFF6347AA
#define COLOR_DRED          0xb40404FF
#define COLOR_RED           0xFF0000FF
#define COLOR_BLUE          0x3350FFFF
#define COLOR_SBLUE         0x3594A1FF
#define COLOR_DBLUE         0x2641FEFF
#define COLOR_LIGHT         0xB8DBFFFF
#define COLOR_WHITE         0xFFFFFFFF
#define COLOR_PURPLE        0xC2A2DAAA
#define COLOR_TEAL          0x67AAB1FF
#define COLOR_NON           0xE7AAA5A5
#define COLOR_ORANGE        0xFF9D00FF
#define COLOR_LORANGE       0xFFA14FFF // light orange
#define COLOR_WAR           0x4191E0FF
#define COLOR_SHOPCOLOR     0xF56969FF

#define COLOR_NOTICE    0xF29900FF
#define COLOR_ACHAT     0xEDD33EFF
#define COLOR_RCHAT     0x8D8DFFFF
#define COLOR_DCHAT     0xFF2945FF
#define COLOR_FCHAT     0x00C8FFFF
#define COLOR_NEWS      0xFF9500FF
#define COLOR_LIVE      0x99CC33FF

#pragma warning disable 238
#pragma warning disable 208


// Name colors
#define COLOR_PD            0x2455C7AA
#define COLOR_FBI           0x162086FF
#define COLOR_HITMAN        0x7E3937FF
#define COLOR_TAXI          0xEAFF00FF
#define COLOR_REPORTERS     0xCA91EDFF
#define COLOR_GROVE         0x0E570FFF
#define COLOR_RUSSIAN       0x454442FF
#define COLOR_BALLAS        0x8C00A8AA
#define COLOR_AZTECAS       0x2DB3B3FF
#define COLOR_PARAMEDIC     0xF86448FF
#define COLOR_INSTRUCTORS   0x00D179FF


// culori texte
#define BLUE        "{3366CC}"
#define WHITE       "{FFFFFF}"
#define TEAL        "{67AAB1}"
#define GREEN       "{4DAD2B}"
#define GREY        "{BABABA}"
#define YELLOW      "{FFFF00}"
#define DRED        "{A40808}"
#define LRED        "{FF6347}"
#define RED         "{FF0000}"
#define ANNO        "{2587CE}"
#define NON         "{E7AAA5}"
#define SYN         "{B8DBFF}"
#define CREM        "{D2B48C}"
#define ORANGE      "{FF9D00}"
#define PINK        "{E89091}"
#define LORANGE     "{FFA14F}"
#define SBLUE       "{3594A1}"
#define SHOPC       "{F56969}" 

// Atached objects
#define DUTY_HAT (0)
#define DUTY_ARMOUR (1) 

// Others
#undef  MAX_PLAYERS
#define MAX_PLAYERS     50
#define MAX_GROUPS      20
#define MAX_TURFS       19
#define MAX_JOBS        10
#define MAX_BUSINESS    5

#define SPAWN_SKIN      184
#define SCM             SendClientMessage

// news

new vehName[][] = { "Landstalker", "Bravura", "Buffalo", "Linerunner", "Perrenial", "Sentinel", "Dumper", "Firetruck", "Trashmaster", "Stretch", "Manana", "Infernus", "Voodoo", "Pony", "Mule", "Cheetah", "Ambulance", "Leviathan", "Moonbeam", "Esperanto", "Taxi", "Washington", "Bobcat", "Whoopee", "BF Injection", "Hunter", "Premier",
"Enforcer", "Securicar", "Banshee", "Predator", "Bus", "Rhino", "Barracks", "Hotknife", "Trailer", "Previon", "Coach", "Cabbie", "Stallion", "Rumpo", "RC Bandit", "Romero", "Packer", "Monster", "Admiral", "Squalo", "Seasparrow", "Pizzaboy", "Tram", "Trailer", "Turismo", "Speeder", "Reefer", "Tropic", "Flatbed", "Yankee", "Caddy",
"Solair", "Berkley's RC Van", "Skimmer", "PCJ-600", "Faggio", "Freeway", "RC Baron", "RC Raider", "Glendale", "Oceanic", "Sanchez", "Sparrow", "Patriot", "Quad", "Coastguard", "Dinghy", "Hermes", "Sabre", "Rustler", "ZR-350", "Walton", "Regina", "Comet", "BMX", "Burrito", "Camper", "Marquis", "Baggage", "Dozer", "Maverick",
"News Chopper", "Rancher", "FBI Rancher", "Virgo", "Greenwood", "Jetmax", "Hotring", "Sandking", "Blista Compact", "Police Maverick", "Boxvillde", "Benson", "Mesa", "RC Goblin", "Hotring Racer A", "Hotring Racer B", "Bloodring Banger", "Rancher", "Super GT", "Elegant", "Journey", "Bike", "Mountain Bike", "Beagle", "Cropduster",
"Stunt", "Tanker", "Roadtrain", "Nebula", "Majestic", "Buccaneer", "Shamal", "Hydra", "FCR-900", "NRG-500", "HPV1000", "Cement Truck", "Tow Truck", "Fortune", "Cadrona", "FBI Truck", "Willard", "Forklift", "Tractor", "Combine", "Feltzer", "Remington", "Slamvan", "Blade", "Freight", "Streak", "Vortex", "Vincent", "Bullet", "Clover",
"Sadler", "Firetruck", "Hustler", "Intruder", "Primo", "Cargobob", "Tampa", "Sunrise", "Merit", "Utility", "Nevada", "Yosemite", "Windsor", "Monster", "Monster", "Uranus", "Jester", "Sultan", "Stratum", "Elegy", "Raindance", "RC Tiger", "Flash", "Tahoma", "Savanna", "Bandito", "Freight Flat", "Streak Carriage", "Kart", "Mower", "Dune",
"Sweeper", "Broadway", "Tornado", "AT-400", "DFT-30", "Huntley", "Stafford", "BF-400", "News Van", "Tug", "Trailer", "Emperor", "Wayfarer", "Euros", "Hotdog", "Club", "Freight Box", "Trailer", "Andromada", "Dodo", "RC Cam", "Launch", "LS Police Car", "SF Police Car", "LV Police Car", "Police Ranger", "Picador", "S.W.A.T", "Alpha", "Phoenix",
"Glendale", "Sadler", "Luggage", "Luggage", "Stairs", "Boxville", "Tiller", "Utility Trailer" };

new Float:randomJail[14][3] = {
    {265.3839,82.0160,1001.0391}, // Jail1
    {265.6895,80.7961,1001.0391}, // Jail2
    {263.2338,83.5494,1001.0391}, // Jail3
    {263.5915,81.4954,1001.0391}, // Jail4
    {265.7344,83.7844,1001.0391}, // Jail5
    {264.3011,86.8114,1001.0391},// Jail6
    {265.4127,85.6519,1001.0391}, // Jail7
    {262.7498,86.1108,1001.0391},// Jail8
    {265.2384,88.2842,1001.0391}, // Jail9
    {264.1760,77.9824,1001.0391}, // Jail10
    {262.7851,75.9671,1001.0391}, // Jail11
    {265.8549,76.0920,1001.0391}, // Jail12
    {265.5084,78.8859,1001.0391}, // Jail13
    {262.7493,78.6393,1001.0391}// Jail14
    /*{268.6428,77.0243,1001.0391}, // Outofjail 1
    {268.6713,80.3934,1001.0391}, // Outofjail 2
    {268.7118,85.1676,1001.0391}*/ // Outofjail 3
};

/*new Float:randomOutOfJail[][] = {
    "268.6428,77.0243,1001.0391", // Outofjail 1
    "268.6713,80.3934,1001.0391", // Outofjail 2
    "268.7118,85.1676,1001.0391" // Outofjail 3
};*/

// new Float:randomArms[20][4] = {
//     {1657.5088,-1111.4285,24.0309,269.2869},
//     {1659.3077,-1102.2886,24.0301,269.5188},
//     {1658.9620,-1093.5762,24.0243,268.6577},
//     {1658.4021,-1084.5138,24.0286,269.1394},
//     {1627.3088,-1047.4539,24.0109,179.6198},
//     {1636.3195,-1047.6259,24.0171,179.4357},
//     {1645.4362,-1047.5532,24.0153,178.8817},
//     {1654.2898,-1047.6057,24.0188,177.9769},
//     {1680.7721,-1045.1458,24.0163,179.4636},
//     {1690.0070,-1044.6404,24.0318,180.0173},
//     {1698.6997,-1044.5209,24.0258,180.5837},
//     {1707.8258,-1045.2781,24.0280,179.7145},
//     {1558.5039,-1012.9221,24.0275,180.1582},
//     {1567.2894,-1013.2521,24.0264,181.5777},
//     {1576.4032,-1012.4585,24.0242,180.5829},
//     {1585.9080,-1011.6259,24.0275,188.1375},
//     {1594.8209,-1010.4429,24.0339,187.7611},
//     {1604.3584,-1010.0365,24.0346,178.6548},
//     {1613.2068,-1010.1227,24.0280,178.7853},
//     {1623.3124,-1011.3804,24.0165,160.9464}
// };

new spoiler[20][0] = {
    {1000},
    {1001},
    {1002},
    {1003},
    {1014},
    {1015},
    {1016},
    {1023},
    {1058},
    {1060},
    {1049},
    {1050},
    {1138},
    {1139},
    {1146},
    {1147},
    {1158},
    {1162},
    {1163},
    {1164}
};
 
new nitro[3][0] = {
    {1008},
    {1009},
    {1010}
};
 
new fbumper[23][0] = {
    {1117},
    {1152},
    {1153},
    {1155},
    {1157},
    {1160},
    {1165},
    {1166},
    {1169},
    {1170},
    {1171},
    {1172},
    {1173},
    {1174},
    {1175},
    {1179},
    {1181},
    {1182},
    {1185},
    {1188},
    {1189},
    {1192},
    {1193}
};
 
new rbumper[22][0] = {
    {1140},
    {1141},
    {1148},
    {1149},
    {1150},
    {1151},
    {1154},
    {1156},
    {1159},
    {1161},
    {1167},
    {1168},
    {1176},
    {1177},
    {1178},
    {1180},
    {1183},
    {1184},
    {1186},
    {1187},
    {1190},
    {1191}
};
 
new exhaust[28][0] = {
    {1018},
    {1019},
    {1020},
    {1021},
    {1022},
    {1028},
    {1029},
    {1037},
    {1043},
    {1044},
    {1045},
    {1046},
    {1059},
    {1064},
    {1065},
    {1066},
    {1089},
    {1092},
    {1104},
    {1105},
    {1113},
    {1114},
    {1126},
    {1127},
    {1129},
    {1132},
    {1135},
    {1136}
};
 
new bventr[2][0] = {
    {1142},
    {1144}
};
 
new bventl[2][0] = {
    {1143},
    {1145}
};
 
new bscoop[4][0] = {
    {1004},
    {1005},
    {1011},
    {1012}
};
 
new rscoop[17][0] = {
    {1006},
    {1032},
    {1033},
    {1035},
    {1038},
    {1053},
    {1054},
    {1055},
    {1061},
    {1067},
    {1068},
    {1088},
    {1091},
    {1103},
    {1128},
    {1130},
    {1131}
};
 
new lskirt[21][0] = {
    {1007},
    {1026},
    {1031},
    {1036},
    {1039},
    {1042},
    {1047},
    {1048},
    {1056},
    {1057},
    {1069},
    {1070},
    {1090},
    {1093},
    {1106},
    {1108},
    {1118},
    {1119},
    {1133},
    {1122},
    {1134}
};
 
new rskirt[21][0] = {
    {1017},
    {1027},
    {1030},
    {1040},
    {1041},
    {1051},
    {1052},
    {1062},
    {1063},
    {1071},
    {1072},
    {1094},
    {1095},
    {1099},
    {1101},
    {1102},
    {1107},
    {1120},
    {1121},
    {1124},
    {1137}
};
 
new hydraulics[1][0] = {
    {1087}
};
 
new modBase[1][0] = {
    {1086}
};
 
new rbbars[4][0] = {
    {1109},
    {1110},
    {1123},
    {1125}
};
 
new fbbars[2][0] = {
    {1115},
    {1116}
};
 
new wheels[17][0] = {
    {1025},
    {1073},
    {1074},
    {1075},
    {1076},
    {1077},
    {1078},
    {1079},
    {1080},
    {1081},
    {1082},
    {1083},
    {1084},
    {1085},
    {1096},
    {1097},
    {1098}
};
 
new modLights[2][0] = {
    {1013},
    {1024}
};