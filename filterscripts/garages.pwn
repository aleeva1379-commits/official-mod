/*
 * Black Russia - Transport & Garage System
 * Система транспорта и гаражей
 */

#define FILTERSCRIPT

#include <a_samp>
#include <zcmd>
#include <sscanf2>

#include "../include/blackrussia.inc"
#include "../include/defines.inc"
#include "../include/database.inc"

// ============ ПЕРЕМЕННЫЕ ============

new GarageInfo[MAX_GARAGES][GarageData];
new VehicleInfo[MAX_VEHICLES][VehicleData];
new GaragePickups[MAX_GARAGES];
new GarageCount = 0;
new VehicleCount = 0;

new PlayerInGarage[MAX_PLAYERS];
new PlayerVehicle[MAX_PLAYERS] = -1;

// ============ МОДЕЛИ АВТОМОБИЛЕЙ ============

enum VehicleModel {
    ModelID,
    ModelName[32],
    Price,
    MaxFuel,
    Speed,
    Acceleration
};

new Vehicles[20][VehicleModel] = {
    {400, "Landstalker", 50000, 100, 150, 80},
    {401, "Bravura", 40000, 80, 140, 75},
    {402, "Buffalo", 120000, 120, 200, 95},
    {404, "Perennial", 35000, 75, 130, 70},
    {407, "Firetruck", 100000, 150, 100, 60},
    {408, "Trashmaster", 25000, 100, 110, 50},
    {420, "Taxi", 15000, 80, 120, 65},
    {421, "Maverick", 500000, 200, 180, 90},
    {422, "Bobcat", 30000, 90, 125, 62},
    {426, "Premier", 45000, 85, 135, 72},
    {431, "Bus", 80000, 150, 100, 55},
    {433, "Barracks", 90000, 140, 110, 65},
    {434, "Sabregt", 180000, 110, 210, 100},
    {436, "Solair", 60000, 95, 160, 82},
    {445, "Admiral", 55000, 90, 145, 75},
    {451, "Turismo", 250000, 120, 230, 110},
    {467, "Moskvich", 35000, 85, 130, 70},
    {480, "Comet", 280000, 125, 240, 115},
    {560, "Sultan", 70000, 100, 175, 85},
    {567, "Savanna", 50000, 85, 135, 72}
};

// ============ ПРЕДУСТАНОВЛЕННЫЕ ГАРАЖИ ============

enum DefaultGarage {
    DefaultName[32],
    Float:DefaultX,
    Float:DefaultY,
    Float:DefaultZ,
    DefaultMaxSlots,
    DefaultPrice
};

new DefaultGarages[5][DefaultGarage] = {
    {"Гараж на Арбате", 200.0, 200.0, 15.0, 10, 100000},
    {"Гараж на Тверской", 300.0, 300.0, 15.0, 15, 150000},
    {"Гараж на Красной площади", 400.0, 400.0, 15.0, 20, 200000},
    {"Парковка ЦУМа", 500.0, 500.0, 15.0, 8, 80000},
    {"Гараж на Новом Арбате", 600.0, 600.0, 15.0, 12, 120000}
};

// ============ CALLBACK'И ============

public OnFilterScriptInit() {
    print("\n");
    print("====================================");
    print("Transport & Garage System загружена!");
    print("====================================\n");
    
    LoadGarages();
    CreateGarageMarkers();
    InitGarages();
    
    return 1;
}

public OnFilterScriptExit() {
    print("[Garage] Система гаражей выгружена");
    return 1;
}

public OnPlayerConnect(playerid) {
    PlayerInGarage[playerid] = -1;
    PlayerVehicle[playerid] = -1;
    return 1;
}

public OnPlayerDisconnect(playerid, reason) {
    SaveAllGarageData();
    SaveAllVehicleData();
    return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid) {
    for(new i = 0; i < GarageCount; i++) {
        if(GaragePickups[i] == pickupid) {
            ShowGarageDialog(playerid, i);
            return 1;
        }
    }
    return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate) {
    if(newstate == PLAYER_STATE_DRIVER || newstate == PLAYER_STATE_PASSENGER) {
        new vehicleid = GetPlayerVehicleID(playerid);
        
        // TODO: Логирование использования транспорта
    }
    
    return 1;
}

// ============ ЗАГРУЗКА ГАРАЖЕЙ ============

LoadGarages() {
    print("[Garage] Загрузка гаражей...");
    
    for(new i = 0; i < 5; i++) {
        GarageInfo[i][GarageID] = i;
        strcpy(GarageInfo[i][GarageName], DefaultGarages[i][DefaultName], 32);
        GarageInfo[i][Owner] = -1;
        GarageInfo[i][EnterX] = DefaultGarages[i][DefaultX];
        GarageInfo[i][EnterY] = DefaultGarages[i][DefaultY];
        GarageInfo[i][EnterZ] = DefaultGarages[i][DefaultZ];
        GarageInfo[i][EnterAngle] = 0.0;
        GarageInfo[i][InteriorID] = 0;
        GarageInfo[i][VirtualWorldID] = 0;
        GarageInfo[i][MaxSlots] = DefaultGarages[i][DefaultMaxSlots];
        GarageInfo[i][UsedSlots] = 0;
        GarageInfo[i][IsPrivate] = false;
        GarageInfo[i][Price] = DefaultGarages[i][DefaultPrice];
        GarageInfo[i][IsForSale] = false;
        
        GarageCount++;
    }
    
    print("[Garage] Гаражи загружены!");
}

CreateGarageMarkers() {
    print("[Garage] Создание маркеров гаражей...");
    
    for(new i = 0; i < GarageCount; i++) {
        GaragePickups[i] = CreatePickup(1239, 1, GarageInfo[i][EnterX], GarageInfo[i][EnterY], GarageInfo[i][EnterZ]);
        CreateDynamicMapIcon(GarageInfo[i][EnterX], GarageInfo[i][EnterY], GarageInfo[i][EnterZ], 27, 0x0000FFFF, 0, 0, -1, 100.0);
    }
    
    printf("[Garage] Создано маркеров гаражей: %d", GarageCount);
}

InitGarages() {
    print("[Garage] Инициализация гаражей...");
    
    new query[512];
    
    for(new i = 0; i < GarageCount; i++) {
        mysql_format(g_SQL, query, sizeof(query),
            "INSERT IGNORE INTO `garages` (`ID`, `GarageName`, `EnterX`, `EnterY`, `EnterZ`, `MaxSlots`, `Price`, `IsForSale`) \
            VALUES (%d, '%s', %.2f, %.2f, %.2f, %d, %d, %d)",
            i, GarageInfo[i][GarageName], GarageInfo[i][EnterX], GarageInfo[i][EnterY], 
            GarageInfo[i][EnterZ], GarageInfo[i][MaxSlots], GarageInfo[i][Price], GarageInfo[i][IsForSale]);
        
        mysql_query(g_SQL, query, true);
    }
    
    print("[Garage] Инициализация гаражей завершена!");
}

// ============ КОМАНДЫ ============

CMD:garage(playerid, params[]) {
    new string[512];
    SendClientMessage(playerid, 0x00FF00FF, "=== ГАРАЖИ ГОРОДА ===");
    SendClientMessage(playerid, 0xFFFFFFFF, " ");
    
    for(new i = 0; i < GarageCount; i++) {
        if(GarageInfo[i][IsForSale]) {
            format(string, sizeof(string), "%d. %s - $%d (НА ПРОДАЖУ)", 
                i, GarageInfo[i][GarageName], GarageInfo[i][Price]);
            SendClientMessage(playerid, 0xFFD700FF, string);
        } else {
            format(string, sizeof(string), "%d. %s - Слотов: %d/%d", 
                i, GarageInfo[i][GarageName], GarageInfo[i][UsedSlots], GarageInfo[i][MaxSlots]);
            SendClientMessage(playerid, 0xFFFFFFFF, string);
        }
    }
    
    return 1;
}

CMD:mygarage(playerid, params[]) {
    new string[512];
    new garages = 0;
    
    SendClientMessage(playerid, 0x00FF00FF, "=== МОИ ГАРАЖИ ===");
    SendClientMessage(playerid, 0xFFFFFFFF, " ");
    
    for(new i = 0; i < GarageCount; i++) {
        if(GarageInfo[i][Owner] == playerid) {
            garages++;
            
            format(string, sizeof(string), "ID: %d | %s", i, GarageInfo[i][GarageName]);
            SendClientMessage(playerid, 0x00FF00FF, string);
            
            format(string, sizeof(string), "Машин: %d/%d | Цена: $%d", 
                GarageInfo[i][UsedSlots], GarageInfo[i][MaxSlots], GarageInfo[i][Price]);
            SendClientMessage(playerid, 0xFFFFFFFF, string);
            
            SendClientMessage(playerid, 0xFFFFFFFF, " ");
        }
    }
    
    if(garages == 0) {
        SendClientMessage(playerid, 0xFF0000FF, "У вас нет гаражей!");
    }
    
    return 1;
}

CMD:buygarage(playerid, params[]) {
    new garageid;
    
    if(sscanf(params, "d", garageid)) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Используйте: /buygarage [ID]");
        return 1;
    }
    
    if(garageid < 0 || garageid >= GarageCount) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Неправильный ID гаража!");
        return 1;
    }
    
    if(!GarageInfo[garageid][IsForSale]) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Этот гараж не на продажу!");
        return 1;
    }
    
    if(GetPlayerMoney(playerid) < GarageInfo[garageid][Price]) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Недостаточно денег!");
        return 1;
    }
    
    GivePlayerMoney(playerid, -GarageInfo[garageid][Price]);
    
    GarageInfo[garageid][Owner] = playerid;
    GarageInfo[garageid][IsForSale] = false;
    
    SaveGarageData(garageid);
    
    new string[256];
    format(string, sizeof(string), "[SUCCESS] Вы купили гараж '%s' за $%d", 
        GarageInfo[garageid][GarageName], GarageInfo[garageid][Price]);
    SendClientMessage(playerid, 0x00FF00FF, string);
    
    return 1;
}

CMD:sellgarage(playerid, params[]) {
    new garageid, sellprice;
    
    if(sscanf(params, "dd", garageid, sellprice)) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Используйте: /sellgarage [ID] [цена]");
        return 1;
    }
    
    if(garageid < 0 || garageid >= GarageCount) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Неправильный ID гаража!");
        return 1;
    }
    
    if(GarageInfo[garageid][Owner] != playerid) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Это не ваш гараж!");
        return 1;
    }
    
    GarageInfo[garageid][Price] = sellprice;
    GarageInfo[garageid][IsForSale] = true;
    GarageInfo[garageid][Owner] = -1;
    
    SaveGarageData(garageid);
    
    new string[256];
    format(string, sizeof(string), "[SUCCESS] Гараж выставлен на продажу за $%d", sellprice);
    SendClientMessage(playerid, 0x00FF00FF, string);
    
    return 1;
}

CMD:vehicles(playerid, params[]) {
    new string[512];
    new vcount = 0;
    
    SendClientMessage(playerid, 0x00FF00FF, "=== МОИ АВТОМОБИЛИ ===");
    SendClientMessage(playerid, 0xFFFFFFFF, " ");
    
    for(new i = 0; i < MAX_VEHICLES; i++) {
        if(VehicleInfo[i][Owner] == playerid) {
            vcount++;
            
            format(string, sizeof(string), "ID: %d | %s", i, VehicleInfo[i][VehicleID]);
            SendClientMessage(playerid, 0x00FF00FF, string);
            
            format(string, sizeof(string), "Гараж: %d | Топливо: %d | Состояние: %d%%", 
                VehicleInfo[i][GarageID], VehicleInfo[i][Fuel], VehicleInfo[i][Condition]);
            SendClientMessage(playerid, 0xFFFFFFFF, string);
            
            SendClientMessage(playerid, 0xFFFFFFFF, " ");
        }
    }
    
    if(vcount == 0) {
        SendClientMessage(playerid, 0xFF0000FF, "У вас нет автомобилей!");
    }
    
    return 1;
}

CMD:buycar(playerid, params[]) {
    new carid;
    
    if(sscanf(params, "d", carid)) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Используйте: /buycar [модель]");
        SendClientMessage(playerid, 0xFFFFFFFF, "Доступные модели: 0-19");
        return 1;
    }
    
    if(carid < 0 || carid >= sizeof(Vehicles)) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Неправильный ID модели!");
        return 1;
    }
    
    if(GetPlayerMoney(playerid) < Vehicles[carid][Price]) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Недостаточно денег!");
        new string[128];
        format(string, sizeof(string), "Требуется: $%d", Vehicles[carid][Price]);
        SendClientMessage(playerid, 0xFFFFFFFF, string);
        return 1;
    }
    
    // Ищем свободный гараж у игрока
    new garageid = -1;
    for(new i = 0; i < GarageCount; i++) {
        if(GarageInfo[i][Owner] == playerid && GarageInfo[i][UsedSlots] < GarageInfo[i][MaxSlots]) {
            garageid = i;
            break;
        }
    }
    
    if(garageid == -1) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] У вас нет свободного места в гараже!");
        SendClientMessage(playerid, 0xFFFFFFFF, "Купите или освободите гараж");
        return 1;
    }
    
    GivePlayerMoney(playerid, -Vehicles[carid][Price]);
    
    // Создаем транспортное средство
    new vehicleid = CreateVehicle(Vehicles[carid][ModelID], 
        GarageInfo[garageid][EnterX] + 5.0, 
        GarageInfo[garageid][EnterY] + 5.0, 
        GarageInfo[garageid][EnterZ], 
        0.0, 1, 1);
    
    // Сохраняем информацию
    VehicleInfo[vehicleid][Owner] = playerid;
    VehicleInfo[vehicleid][GarageID] = garageid;
    VehicleInfo[vehicleid][Fuel] = Vehicles[carid][MaxFuel];
    VehicleInfo[vehicleid][Condition] = 100;
    VehicleInfo[vehicleid][Price] = Vehicles[carid][Price];
    strcpy(VehicleInfo[vehicleid][VehicleID], Vehicles[carid][ModelName], 32);
    
    GarageInfo[garageid][UsedSlots]++;
    
    SaveVehicleData(vehicleid);
    SaveGarageData(garageid);
    
    new string[256];
    format(string, sizeof(string), "[SUCCESS] Вы купили %s за $%d", 
        Vehicles[carid][ModelName], Vehicles[carid][Price]);
    SendClientMessage(playerid, 0x00FF00FF, string);
    
    format(string, sizeof(string), "Автомобиль припаркован в гараже: %s", GarageInfo[garageid][GarageName]);
    SendClientMessage(playerid, 0xFFFFFFFF, string);
    
    return 1;
}

CMD:carlist(playerid, params[]) {
    new string[512];
    SendClientMessage(playerid, 0x00FF00FF, "=== ДОСТУПНЫЕ АВТОМОБИЛИ ===");
    SendClientMessage(playerid, 0xFFFFFFFF, " ");
    
    for(new i = 0; i < sizeof(Vehicles); i++) {
        format(string, sizeof(string), "%d. %s - $%d", i, Vehicles[i][ModelName], Vehicles[i][Price]);
        SendClientMessage(playerid, 0xFFFFFFFF, string);
        
        format(string, sizeof(string), "   Макс.скорость: %d км/ч | Ускорение: %d", 
            Vehicles[i][Speed], Vehicles[i][Acceleration]);
        SendClientMessage(playerid, 0xFFFFFFFF, string);
    }
    
    return 1;
}

CMD:driveto(playerid, params[]) {
    new targetid;
    
    if(sscanf(params, "u", targetid)) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Используйте: /driveto [ID игрока]");
        return 1;
    }
    
    if(!IsPlayerConnected(targetid)) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Игрок не найден!");
        return 1;
    }
    
    new Float:x, Float:y, Float:z;
    GetPlayerPos(targetid, x, y, z);
    
    new string[256];
    format(string, sizeof(string), "[GPS] Маршрут построен к игроку %s", GetPlayerNameEx(targetid));
    SendClientMessage(playerid, 0x00FF00FF, string);
    
    format(string, sizeof(string), "Координаты: %.2f, %.2f, %.2f", x, y, z);
    SendClientMessage(playerid, 0xFFFFFFFF, string);
    
    return 1;
}

CMD:fuel(playerid, params[]) {
    if(!IsPlayerInAnyVehicle(playerid)) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Вы не в транспорте!");
        return 1;
    }
    
    new vehicleid = GetPlayerVehicleID(playerid);
    new string[128];
    
    format(string, sizeof(string), "Топливо: %d л из %d л", 
        VehicleInfo[vehicleid][Fuel], 100);
    SendClientMessage(playerid, 0xFFFFFFFF, string);
    
    return 1;
}

CMD:refuel(playerid, params[]) {
    new amount;
    
    if(sscanf(params, "d", amount)) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Используйте: /refuel [кол-во литров]");
        return 1;
    }
    
    if(!IsPlayerInAnyVehicle(playerid)) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Вы не в транспорте!");
        return 1;
    }
    
    new vehicleid = GetPlayerVehicleID(playerid);
    new cost = amount * 50; // 50$ за литр
    
    if(GetPlayerMoney(playerid) < cost) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Недостаточно денег!");
        return 1;
    }
    
    if(VehicleInfo[vehicleid][Fuel] + amount > 100) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Бак переполнится!");
        return 1;
    }
    
    GivePlayerMoney(playerid, -cost);
    VehicleInfo[vehicleid][Fuel] += amount;
    
    SaveVehicleData(vehicleid);
    
    new string[256];
    format(string, sizeof(string), "[SUCCESS] Вы заправили %d литров за $%d", amount, cost);
    SendClientMessage(playerid, 0x00FF00FF, string);
    
    return 1;
}

// ============ ДИАЛОГИ ============

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[]) {
    if(dialogid >= 4000 && dialogid <= 4099) { // Гараж диалоги
        new garageid = dialogid - 4000;
        
        if(!response) return 1;
        
        switch(listitem) {
            case 0: { // Купить гараж
                if(!GarageInfo[garageid][IsForSale]) {
                    SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Эт��т гараж не на продажу!");
                    return 1;
                }
                
                if(GetPlayerMoney(playerid) < GarageInfo[garageid][Price]) {
                    SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Недостаточно денег!");
                    return 1;
                }
                
                GivePlayerMoney(playerid, -GarageInfo[garageid][Price]);
                GarageInfo[garageid][Owner] = playerid;
                GarageInfo[garageid][IsForSale] = false;
                
                SaveGarageData(garageid);
                
                new string[256];
                format(string, sizeof(string), "[SUCCESS] Вы купили гараж '%s' за $%d", 
                    GarageInfo[garageid][GarageName], GarageInfo[garageid][Price]);
                SendClientMessage(playerid, 0x00FF00FF, string);
            }
            
            case 1: { // Информация
                new string[512];
                format(string, sizeof(string), 
                    "Гараж: %s\n\n\
                    Слотов: %d\n\
                    Использовано: %d/%d\n\
                    Цена: $%d\n\
                    На продажу: %s",
                    GarageInfo[garageid][GarageName],
                    GarageInfo[garageid][MaxSlots],
                    GarageInfo[garageid][UsedSlots],
                    GarageInfo[garageid][MaxSlots],
                    GarageInfo[garageid][Price],
                    GarageInfo[garageid][IsForSale] ? "ДА" : "НЕТ");
                
                ShowPlayerDialog(playerid, 9998, DIALOG_STYLE_MSGBOX, "Информация о гараже", string, "OK", "");
            }
        }
    }
    
    return 1;
}

// ============ ДИАЛОГОВЫЕ ФУНКЦИИ ============

stock ShowGarageDialog(playerid, garageid) {
    new string[512];
    
    format(string, sizeof(string), 
        "%s\n\n\
        Выберите действие:\n\n\
        Купить гараж\n\
        Информация",
        GarageInfo[garageid][GarageName]);
    
    ShowPlayerDialog(playerid, 4000 + garageid, DIALOG_STYLE_LIST, "Гараж", string, "Выбрать", "Отмена");
}

// ============ HELPER ФУНКЦИИ ============

stock SaveGarageData(garageid) {
    new query[512];
    
    mysql_format(g_SQL, query, sizeof(query),
        "UPDATE `garages` SET `Owner` = %d, `UsedSlots` = %d, `IsForSale` = %d, `Price` = %d WHERE `ID` = %d",
        GarageInfo[garageid][Owner], GarageInfo[garageid][UsedSlots], 
        GarageInfo[garageid][IsForSale], GarageInfo[garageid][Price], garageid);
    
    mysql_query(g_SQL, query, true);
}

stock SaveAllGarageData() {
    for(new i = 0; i < GarageCount; i++) {
        SaveGarageData(i);
    }
}

stock SaveVehicleData(vehicleid) {
    new query[512];
    
    mysql_format(g_SQL, query, sizeof(query),
        "INSERT INTO `player_vehicles` (`VehicleID`, `Owner`, `GarageID`, `Fuel`, `Condition`, `Price`) \
        VALUES (%d, %d, %d, %d, %d, %d) \
        ON DUPLICATE KEY UPDATE `Fuel` = %d, `Condition` = %d",
        vehicleid, VehicleInfo[vehicleid][Owner], VehicleInfo[vehicleid][GarageID],
        VehicleInfo[vehicleid][Fuel], VehicleInfo[vehicleid][Condition], VehicleInfo[vehicleid][Price],
        VehicleInfo[vehicleid][Fuel], VehicleInfo[vehicleid][Condition]);
    
    mysql_query(g_SQL, query, true);
}

stock SaveAllVehicleData() {
    for(new i = 0; i < MAX_VEHICLES; i++) {
        if(VehicleInfo[i][Owner] != -1) {
            SaveVehicleData(i);
        }
    }
}

stock GetPlayerMoney(playerid) {
    return GetPlayerCash(playerid);
}

stock GetPlayerNameEx(playerid) {
    new name[24];
    GetPlayerName(playerid, name, sizeof(name));
    return name;
}

stock strcpy(dest[], const source[], maxlength = sizeof dest) {
    strmid(dest, source, 0, strlen(source), maxlength);
}
