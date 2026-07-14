/*
 * Black Russia - Faction System
 * Система фракций с ролями и рангами
 */

#define FILTERSCRIPT

#include <a_samp>
#include <zcmd>
#include <sscanf2>

#include "../include/blackrussia.inc"
#include "../include/defines.inc"
#include "../include/database.inc"

// ============ ПЕРЕМЕННЫЕ ============

new FactionInfo[MAX_FACTIONS][FactionData];
new PlayerFaction[MAX_PLAYERS];
new PlayerRank[MAX_PLAYERS];
new FactionMarkers[MAX_FACTIONS];
new FactionPickups[MAX_FACTIONS];

// ============ ДАННЫЕ РАНГОВ ============

enum RankData {
    RankName[32],
    RankSalary,
    RankPermissions
};

new PoliceRanks[7][RankData] = {
    {"Рядовой", 1000, 0},
    {"Сержант", 1500, 1},
    {"Лейтенант", 2000, 2},
    {"Капитан", 2500, 3},
    {"Майор", 3000, 4},
    {"Полковник", 3500, 5},
    {"Генерал", 4000, 6}
};

new ArmyRanks[7][RankData] = {
    {"Боец", 1000, 0},
    {"Сержант", 1500, 1},
    {"Лейтенант", 2000, 2},
    {"Капитан", 2500, 3},
    {"Майор", 3000, 4},
    {"Полковник", 3500, 5},
    {"Генерал", 4000, 6}
};

new MafiaRanks[7][RankData] = {
    {"Боец", 1000, 0},
    {"Бригадир", 1500, 1},
    {"Авторитет", 2000, 2},
    {"Смотрящий", 2500, 3},
    {"Вор в Законе", 3000, 4},
    {"Босс", 3500, 5},
    {"Крестный отец", 4000, 6}
};

// ============ CALLBACK'И ============

public OnFilterScriptInit() {
    print("\n");
    print("====================================");
    print("Faction System загружена!");
    print("====================================\n");
    
    LoadFactions();
    CreateFactionMarkers();
    InitFactions();
    
    return 1;
}

public OnFilterScriptExit() {
    print("[Factions] Система фракций выгружена");
    return 1;
}

public OnPlayerConnect(playerid) {
    PlayerFaction[playerid] = FACTION_NONE;
    PlayerRank[playerid] = 0;
    return 1;
}

public OnPlayerDisconnect(playerid, reason) {
    SavePlayerFactionData(playerid);
    PlayerFaction[playerid] = FACTION_NONE;
    PlayerRank[playerid] = 0;
    return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid) {
    for(new i = 0; i < MAX_FACTIONS; i++) {
        if(FactionPickups[i] == pickupid) {
            ShowFactionInfo(playerid, i);
            return 1;
        }
    }
    return 1;
}

// ============ ЗАГРУЗКА ФРАКЦИЙ ============

LoadFactions() {
    print("[Factions] Загрузка фракций из БД...");
    
    // МВД - Полиция
    FactionInfo[FACTION_POLICE][FactionID] = FACTION_POLICE;
    strcpy(FactionInfo[FACTION_POLICE][FactionName], "МВД - Полиция");
    FactionInfo[FACTION_POLICE][FactionType] = FACTION_TYPE_POLICE;
    strcpy(FactionInfo[FACTION_POLICE][FactionLeader], "Начальник МВД");
    FactionInfo[FACTION_POLICE][FactionBank] = 500000;
    FactionInfo[FACTION_POLICE][MaxMembers] = 50;
    FactionInfo[FACTION_POLICE][ActiveMembers] = 0;
    FactionInfo[FACTION_POLICE][Color] = 0x0087CEFF;
    strcpy(FactionInfo[FACTION_POLICE][Description], "Министерство Внутренних Дел Российской Федерации");
    
    // Армия России
    FactionInfo[FACTION_ARMY][FactionID] = FACTION_ARMY;
    strcpy(FactionInfo[FACTION_ARMY][FactionName], "Армия России");
    FactionInfo[FACTION_ARMY][FactionType] = FACTION_TYPE_ARMY;
    strcpy(FactionInfo[FACTION_ARMY][FactionLeader], "Главнокомандующий");
    FactionInfo[FACTION_ARMY][FactionBank] = 750000;
    FactionInfo[FACTION_ARMY][MaxMembers] = 60;
    FactionInfo[FACTION_ARMY][ActiveMembers] = 0;
    FactionInfo[FACTION_ARMY][Color] = 0x228B22FF;
    strcpy(FactionInfo[FACTION_ARMY][Description], "Вооруженные Силы Российской Федерации");
    
    // Преступная организация
    FactionInfo[FACTION_MAFIA][FactionID] = FACTION_MAFIA;
    strcpy(FactionInfo[FACTION_MAFIA][FactionName], "Русская Преступная Синдикат");
    FactionInfo[FACTION_MAFIA][FactionType] = FACTION_TYPE_MAFIA;
    strcpy(FactionInfo[FACTION_MAFIA][FactionLeader], "Крестный отец");
    FactionInfo[FACTION_MAFIA][FactionBank] = 1000000;
    FactionInfo[FACTION_MAFIA][MaxMembers] = 40;
    FactionInfo[FACTION_MAFIA][ActiveMembers] = 0;
    FactionInfo[FACTION_MAFIA][Color] = 0xFF0000FF;
    strcpy(FactionInfo[FACTION_MAFIA][Description], "Независимая преступная организация");
    
    print("[Factions] Фракции успешно загружены!");
}

InitFactions() {
    print("[Factions] Инициализация фракций...");
    
    // Вставляем фракции в БД если их нет
    new query[512];
    
    // МВД
    mysql_format(g_SQL, query, sizeof(query),
        "INSERT IGNORE INTO `factions` (`ID`, `FactionName`, `FactionType`, `FactionLeader`, `FactionBank`, `MaxMembers`, `Description`) \
        VALUES (%d, '%s', %d, '%s', %d, %d, '%s')",
        FACTION_POLICE, "МВД - Полиция", FACTION_TYPE_POLICE, "Начальник МВД", 500000, 50, "Министерство Внутренних Дел");
    
    mysql_query(g_SQL, query, true);
    
    // Армия
    mysql_format(g_SQL, query, sizeof(query),
        "INSERT IGNORE INTO `factions` (`ID`, `FactionName`, `FactionType`, `FactionLeader`, `FactionBank`, `MaxMembers`, `Description`) \
        VALUES (%d, '%s', %d, '%s', %d, %d, '%s')",
        FACTION_ARMY, "Армия России", FACTION_TYPE_ARMY, "Главнокомандующий", 750000, 60, "Вооруженные Силы РФ");
    
    mysql_query(g_SQL, query, true);
    
    // Мафия
    mysql_format(g_SQL, query, sizeof(query),
        "INSERT IGNORE INTO `factions` (`ID`, `FactionName`, `FactionType`, `FactionLeader`, `FactionBank`, `MaxMembers`, `Description`) \
        VALUES (%d, '%s', %d, '%s', %d, %d, '%s')",
        FACTION_MAFIA, "Русская Преступная Синдикат", FACTION_TYPE_MAFIA, "Крестный отец", 1000000, 40, "Преступная организация");
    
    mysql_query(g_SQL, query, true);
    
    print("[Factions] Инициализация завершена!");
}

// ============ СОЗДАНИЕ МАРКЕРОВ ============

CreateFactionMarkers() {
    print("[Factions] Создание маркеров фракций...");
    
    // МВД (Красная площадь)
    FactionPickups[FACTION_POLICE] = CreatePickup(1239, 1, 300.0, 300.0, 10.0);
    CreateDynamicMapIcon(300.0, 300.0, 10.0, 30, 0x0087CEFF, 0, 0, -1, 100.0);
    
    // Армия (Военный архив)
    FactionPickups[FACTION_ARMY] = CreatePickup(1239, 1, 400.0, 400.0, 10.0);
    CreateDynamicMapIcon(400.0, 400.0, 10.0, 30, 0x228B22FF, 0, 0, -1, 100.0);
    
    // Мафия (Арбат)
    FactionPickups[FACTION_MAFIA] = CreatePickup(1239, 1, 200.0, 200.0, 10.0);
    CreateDynamicMapIcon(200.0, 200.0, 10.0, 30, 0xFF0000FF, 0, 0, -1, 100.0);
    
    print("[Factions] Маркеры созданы!");
}

// ============ КОМАНДЫ ============

CMD:factions(playerid, params[]) {
    new string[512];
    SendClientMessage(playerid, 0x00FF00FF, "=== ФРАКЦИИ СЕРВЕРА ===");
    SendClientMessage(playerid, 0xFFFFFFFF, " ");
    
    for(new i = 1; i < MAX_FACTIONS; i++) {
        if(FactionInfo[i][FactionID] != -1) {
            format(string, sizeof(string), "ID: %d | %s", i, FactionInfo[i][FactionName]);
            SendClientMessage(playerid, FactionInfo[i][Color], string);
            
            format(string, sizeof(string), "Лидер: %s | Касса: $%d", 
                FactionInfo[i][FactionLeader], FactionInfo[i][FactionBank]);
            SendClientMessage(playerid, 0xFFFFFFFF, string);
            
            format(string, sizeof(string), "Участников: %d/%d", 
                FactionInfo[i][ActiveMembers], FactionInfo[i][MaxMembers]);
            SendClientMessage(playerid, 0xFFFFFFFF, string);
            
            SendClientMessage(playerid, 0xFFFFFFFF, " ");
        }
    }
    
    return 1;
}

CMD:joinf(playerid, params[]) {
    new factionid;
    
    if(sscanf(params, "d", factionid)) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Используйте: /joinf [ID фракции]");
        return 1;
    }
    
    if(factionid < 1 || factionid >= MAX_FACTIONS) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Неправильный ID фракции!");
        return 1;
    }
    
    if(PlayerFaction[playerid] != FACTION_NONE) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Вы уже состоите в фракции!");
        return 1;
    }
    
    if(FactionInfo[factionid][ActiveMembers] >= FactionInfo[factionid][MaxMembers]) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Фракция переполнена!");
        return 1;
    }
    
    // Присоединяем к фракции
    JoinFaction(playerid, factionid, 0); // 0 = рядовой ранг
    
    new string[256];
    format(string, sizeof(string), "[SUCCESS] Вы присоединились к фракции %s!", FactionInfo[factionid][FactionName]);
    SendClientMessage(playerid, 0x00FF00FF, string);
    
    format(string, sizeof(string), "%s присоединился к фракции", GetPlayerNameEx(playerid));
    SendFactionMessage(factionid, string, FactionInfo[factionid][Color]);
    
    return 1;
}

CMD:leavef(playerid, params[]) {
    if(PlayerFaction[playerid] == FACTION_NONE) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Вы не состоите в фракции!");
        return 1;
    }
    
    new factionid = PlayerFaction[playerid];
    LeaveFaction(playerid);
    
    new string[256];
    format(string, sizeof(string), "[SUCCESS] Вы покинули фракцию %s!", FactionInfo[factionid][FactionName]);
    SendClientMessage(playerid, 0x00FF00FF, string);
    
    format(string, sizeof(string), "%s покинул фракцию", GetPlayerNameEx(playerid));
    SendFactionMessage(factionid, string, 0xFF0000FF);
    
    return 1;
}

CMD:faction(playerid, params[]) {
    if(PlayerFaction[playerid] == FACTION_NONE) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Вы не состоите в фракции!");
        return 1;
    }
    
    new factionid = PlayerFaction[playerid];
    new string[512];
    
    SendClientMessage(playerid, FactionInfo[factionid][Color], "=== ИНФОРМАЦИЯ О ФРАКЦИИ ===");
    
    format(string, sizeof(string), "Название: %s", FactionInfo[factionid][FactionName]);
    SendClientMessage(playerid, 0xFFFFFFFF, string);
    
    format(string, sizeof(string), "Лидер: %s", FactionInfo[factionid][FactionLeader]);
    SendClientMessage(playerid, 0xFFFFFFFF, string);
    
    format(string, sizeof(string), "Описание: %s", FactionInfo[factionid][Description]);
    SendClientMessage(playerid, 0xFFFFFFFF, string);
    
    format(string, sizeof(string), "Участников: %d/%d", 
        FactionInfo[factionid][ActiveMembers], FactionInfo[factionid][MaxMembers]);
    SendClientMessage(playerid, 0xFFFFFFFF, string);
    
    format(string, sizeof(string), "Касса фракции: $%d", FactionInfo[factionid][FactionBank]);
    SendClientMessage(playerid, 0xFFFFFFFF, string);
    
    format(string, sizeof(string), "Ваш ранг: %s", GetRankName(factionid, PlayerRank[playerid]));
    SendClientMessage(playerid, 0xFFFFFFFF, string);
    
    format(string, sizeof(string), "Зарплата: $%d", GetRankSalary(factionid, PlayerRank[playerid]));
    SendClientMessage(playerid, 0xFFFFFFFF, string);
    
    return 1;
}

CMD:f(playerid, params[]) {
    if(PlayerFaction[playerid] == FACTION_NONE) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Вы не состоите в фракции!");
        return 1;
    }
    
    if(sscanf(params, "s[128]", params)) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Используйте: /f [сообщение]");
        return 1;
    }
    
    new factionid = PlayerFaction[playerid];
    new string[256];
    
    format(string, sizeof(string), "[ФРАКЦИЯ] %s: %s", GetPlayerNameEx(playerid), params);
    SendFactionMessage(factionid, string, FactionInfo[factionid][Color]);
    
    return 1;
}

CMD:promotepl(playerid, params[]) {
    if(!IsPlayerAdmin(playerid)) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Только администраторы!");
        return 1;
    }
    
    new targetid, rank;
    
    if(sscanf(params, "ud", targetid, rank)) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Используйте: /promotepl [ID] [ранг]");
        return 1;
    }
    
    if(!IsPlayerConnected(targetid)) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Игрок не найден!");
        return 1;
    }
    
    if(PlayerFaction[targetid] == FACTION_NONE) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Игрок не состоит в фракции!");
        return 1;
    }
    
    PromotePlayer(targetid, rank);
    
    new string[256];
    format(string, sizeof(string), "[SUCCESS] Вы повысили %s на ранг %s", 
        GetPlayerNameEx(targetid), GetRankName(PlayerFaction[targetid], rank));
    SendClientMessage(playerid, 0x00FF00FF, string);
    
    format(string, sizeof(string), "[INFO] Вас повысили на ранг %s", GetRankName(PlayerFaction[targetid], rank));
    SendClientMessage(targetid, 0x00FF00FF, string);
    
    return 1;
}

// ============ HELPER ФУНКЦИИ ============

stock JoinFaction(playerid, factionid, rank) {
    PlayerFaction[playerid] = factionid;
    PlayerRank[playerid] = rank;
    FactionInfo[factionid][ActiveMembers]++;
    SavePlayerFactionData(playerid);
}

stock LeaveFaction(playerid) {
    if(PlayerFaction[playerid] != FACTION_NONE) {
        FactionInfo[PlayerFaction[playerid]][ActiveMembers]--;
    }
    PlayerFaction[playerid] = FACTION_NONE;
    PlayerRank[playerid] = 0;
    SavePlayerFactionData(playerid);
}

stock PromotePlayer(playerid, newrank) {
    PlayerRank[playerid] = newrank;
    SavePlayerFactionData(playerid);
}

stock SendFactionMessage(factionid, const message[], color) {
    for(new i = 0; i < MAX_PLAYERS; i++) {
        if(IsPlayerConnected(i) && PlayerFaction[i] == factionid) {
            SendClientMessage(i, color, message);
        }
    }
}

stock GetRankName(factionid, rank) {
    new rankname[32];
    
    if(factionid == FACTION_POLICE) {
        strcpy(rankname, PoliceRanks[rank][RankName], 32);
    } else if(factionid == FACTION_ARMY) {
        strcpy(rankname, ArmyRanks[rank][RankName], 32);
    } else if(factionid == FACTION_MAFIA) {
        strcpy(rankname, MafiaRanks[rank][RankName], 32);
    } else {
        strcpy(rankname, "Неизвестный", 32);
    }
    
    return rankname;
}

stock GetRankSalary(factionid, rank) {
    new salary = 1000;
    
    if(factionid == FACTION_POLICE) {
        salary = PoliceRanks[rank][RankSalary];
    } else if(factionid == FACTION_ARMY) {
        salary = ArmyRanks[rank][RankSalary];
    } else if(factionid == FACTION_MAFIA) {
        salary = MafiaRanks[rank][RankSalary];
    }
    
    return salary;
}

stock SavePlayerFactionData(playerid) {
    new query[256];
    
    mysql_format(g_SQL, query, sizeof(query),
        "UPDATE `players` SET `Faction` = %d, `Rank` = %d WHERE `ID` = %d",
        PlayerFaction[playerid], PlayerRank[playerid], GetPlayerDatabaseID(playerid));
    
    mysql_query(g_SQL, query, true);
}

stock LoadPlayerFactionData(playerid) {
    // TODO: Загрузить данные фракции из БД
}

stock ShowFactionInfo(playerid, factionid) {
    new string[512];
    
    format(string, sizeof(string), 
        "Добро пожаловать в %s\n\nЛидер: %s\n\nОписание:\n%s\n\nУчастников: %d/%d\n\nКасса: $%d",
        FactionInfo[factionid][FactionName],
        FactionInfo[factionid][FactionLeader],
        FactionInfo[factionid][Description],
        FactionInfo[factionid][ActiveMembers],
        FactionInfo[factionid][MaxMembers],
        FactionInfo[factionid][FactionBank]);
    
    ShowPlayerDialog(playerid, 1001, DIALOG_STYLE_MSGBOX, "Информация о фракции", string, "Присоединиться", "Отмена");
}

stock GetPlayerNameEx(playerid) {
    new name[24];
    GetPlayerName(playerid, name, sizeof(name));
    return name;
}

stock strcpy(dest[], const source[], maxlength = sizeof dest) {
    strmid(dest, source, 0, strlen(source), maxlength);
}

stock IsPlayerAdmin(playerid) {
    // TODO: Проверка админа из БД
    return IsPlayerConnected(playerid);
}

stock GetPlayerDatabaseID(playerid) {
    // TODO: Получить ID из БД
    return playerid;
}
