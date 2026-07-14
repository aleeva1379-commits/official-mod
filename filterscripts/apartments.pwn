/*
 * Black Russia - Apartments & Houses System
 * Система квартир и домов
 */

#define FILTERSCRIPT

#include <a_samp>
#include <zcmd>
#include <sscanf2>

#include "../include/blackrussia.inc"
#include "../include/defines.inc"
#include "../include/database.inc"

// ============ ПЕРЕМЕННЫЕ ============

new ApartmentInfo[MAX_APARTMENTS][ApartmentData];
new ApartmentPickups[MAX_APARTMENTS];
new ApartmentCount = 0;
new PlayerInApartment[MAX_PLAYERS];

#define MAX_APARTMENTS 30

enum InteriorType {
    InteriorID,
    InteriorX,
    Float:InteriorY,
    Float:InteriorZ,
    Float:InteriorA,
    InteriorWorld
};

new Interiors[10][InteriorType] = {
    {0, 383.0, 1247.0, 1084.0, 90.0, 0},
    {1, 234.0, 139.0, 1010.0, 90.0, 0},
    {2, 478.0, 1370.0, 1084.0, 90.0, 0},
    {3, 383.0, 1140.0, 1084.0, 90.0, 0},
    {4, 226.0, 1114.0, 1083.0, 90.0, 0},
    {5, 295.0, 1106.0, 1084.0, 90.0, 0},
    {6, 288.0, 173.0, 1010.0, 90.0, 0},
    {7, 383.0, 1140.0, 1084.0, 90.0, 0},
    {8, 264.0, 1211.0, 1084.0, 90.0, 0},
    {9, 234.0, 1114.0, 1084.0, 90.0, 0}
};

// ============ ПРЕДУСТАНОВЛЕННЫЕ КВАРТИРЫ ============

enum DefaultApartment {
    DefaultName[32],
    Float:DefaultX,
    Float:DefaultY,
    Float:DefaultZ,
    DefaultRooms,
    DefaultPrice,
    DefaultRentPrice
};

new DefaultApartments[15][DefaultApartment] = {
    {"Квартира на Тверской #1", 250.0, 250.0, 15.0, 2, 150000, 5000},
    {"Квартира на Тверской #2", 260.0, 260.0, 15.0, 3, 200000, 7000},
    {"Квартира на Арбате #1", 300.0, 300.0, 15.0, 1, 100000, 3000},
    {"Квартира на Арбате #2", 310.0, 310.0, 15.0, 2, 150000, 5000},
    {"Квартира на Арбате #3", 320.0, 320.0, 15.0, 4, 300000, 10000},
    {"Квартира на Красной #1", 350.0, 350.0, 15.0, 2, 180000, 6000},
    {"Квартира на Красной #2", 360.0, 360.0, 15.0, 3, 220000, 8000},
    {"Лофт на Новом Арбате", 400.0, 400.0, 15.0, 2, 250000, 9000},
    {"Апартаменты люкс #1", 450.0, 450.0, 15.0, 3, 400000, 15000},
    {"Апартаменты люкс #2", 460.0, 460.0, 15.0, 4, 500000, 20000},
    {"Студия на Цветном", 500.0, 500.0, 15.0, 1, 80000, 2500},
    {"Квартира на Кутузовском", 550.0, 550.0, 15.0, 3, 350000, 12000},
    {"Пентхаус на Садовом", 600.0, 600.0, 15.0, 5, 800000, 30000},
    {"Апартаменты на Патриархах", 650.0, 650.0, 15.0, 2, 180000, 6500},
    {"Жилой комплекс 'Престиж'", 700.0, 700.0, 15.0, 3, 280000, 10000}
};

// ============ CALLBACK'И ============

public OnFilterScriptInit() {
    print("\n");
    print("====================================");
    print("Apartments & Houses System загружена!");
    print("====================================\n");
    
    LoadApartments();
    CreateApartmentMarkers();
    InitApartments();
    
    return 1;
}

public OnFilterScriptExit() {
    print("[Apartments] Система квартир выгружена");
    return 1;
}

public OnPlayerConnect(playerid) {
    PlayerInApartment[playerid] = -1;
    return 1;
}

public OnPlayerDisconnect(playerid, reason) {
    SaveAllApartmentData();
    return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid) {
    for(new i = 0; i < ApartmentCount; i++) {
        if(ApartmentPickups[i] == pickupid) {
            ShowApartmentDialog(playerid, i);
            return 1;
        }
    }
    return 1;
}

// ============ ЗАГРУЗКА КВАРТИР ============

LoadApartments() {
    print("[Apartments] Загрузка квартир...");
    
    for(new i = 0; i < 15; i++) {
        ApartmentInfo[i][ApartmentID] = i;
        strcpy(ApartmentInfo[i][ApartmentName], DefaultApartments[i][DefaultName], 32);
        ApartmentInfo[i][Owner] = -1;
        ApartmentInfo[i][EnterX] = DefaultApartments[i][DefaultX];
        ApartmentInfo[i][EnterY] = DefaultApartments[i][DefaultY];
        ApartmentInfo[i][EnterZ] = DefaultApartments[i][DefaultZ];
        ApartmentInfo[i][EnterAngle] = 0.0;
        ApartmentInfo[i][InteriorID] = i % 10; // Выбираем интерьер
        ApartmentInfo[i][VirtualWorldID] = i;
        ApartmentInfo[i][Price] = DefaultApartments[i][DefaultPrice];
        ApartmentInfo[i][Rooms] = DefaultApartments[i][DefaultRooms];
        ApartmentInfo[i][IsForSale] = true;
        ApartmentInfo[i][SecurityLevel] = 1;
        ApartmentInfo[i][RentPrice] = DefaultApartments[i][DefaultRentPrice];
        ApartmentInfo[i][IsRented] = false;
        ApartmentInfo[i][CurrentRenter] = -1;
        
        ApartmentCount++;
    }
    
    print("[Apartments] Квартиры загружены!");
}

CreateApartmentMarkers() {
    print("[Apartments] Создание маркеров квартир...");
    
    for(new i = 0; i < ApartmentCount; i++) {
        ApartmentPickups[i] = CreatePickup(1239, 1, ApartmentInfo[i][EnterX], ApartmentInfo[i][EnterY], ApartmentInfo[i][EnterZ]);
        CreateDynamicMapIcon(ApartmentInfo[i][EnterX], ApartmentInfo[i][EnterY], ApartmentInfo[i][EnterZ], 32, 0xFF69B4FF, 0, 0, -1, 100.0);
    }
    
    printf("[Apartments] Создано маркеров квартир: %d", ApartmentCount);
}

InitApartments() {
    print("[Apartments] Инициализация квартир...");
    
    new query[512];
    
    for(new i = 0; i < ApartmentCount; i++) {
        mysql_format(g_SQL, query, sizeof(query),
            "INSERT IGNORE INTO `apartments` (`ID`, `ApartmentName`, `EnterX`, `EnterY`, `EnterZ`, `Interior`, `Price`, `Rooms`, `RentPrice`) \
            VALUES (%d, '%s', %.2f, %.2f, %.2f, %d, %d, %d, %d)",
            i, ApartmentInfo[i][ApartmentName], ApartmentInfo[i][EnterX], ApartmentInfo[i][EnterY], 
            ApartmentInfo[i][EnterZ], ApartmentInfo[i][InteriorID], ApartmentInfo[i][Price], 
            ApartmentInfo[i][Rooms], ApartmentInfo[i][RentPrice]);
        
        mysql_query(g_SQL, query, true);
    }
    
    print("[Apartments] Инициализация квартир завершена!");
}

// ============ КОМАНДЫ ============

CMD:apartments(playerid, params[]) {
    new string[512];
    SendClientMessage(playerid, 0x00FF00FF, "=== КВАРТИРЫ И ДОМА ГОРОДА ===");
    SendClientMessage(playerid, 0xFFFFFFFF, " ");
    
    for(new i = 0; i < ApartmentCount; i++) {
        if(ApartmentInfo[i][IsForSale]) {
            format(string, sizeof(string), "%d. %s - $%d (НА ПРОДАЖУ)", 
                i, ApartmentInfo[i][ApartmentName], ApartmentInfo[i][Price]);
            SendClientMessage(playerid, 0xFFD700FF, string);
        } else {
            format(string, sizeof(string), "%d. %s - Комнат: %d | Собственник: %s", 
                i, ApartmentInfo[i][ApartmentName], ApartmentInfo[i][Rooms],
                (ApartmentInfo[i][Owner] == -1) ? "Государство" : GetPlayerNameEx(ApartmentInfo[i][Owner]));
            SendClientMessage(playerid, 0xFFFFFFFF, string);
        }
        
        format(string, sizeof(string), "   Цена: $%d | Аренда: $%d в день", 
            ApartmentInfo[i][Price], ApartmentInfo[i][RentPrice]);
        SendClientMessage(playerid, 0xFFFFFFFF, string);
    }
    
    return 1;
}

CMD:myapartment(playerid, params[]) {
    new string[512];
    new count = 0;
    
    SendClientMessage(playerid, 0x00FF00FF, "=== МОИ КВАРТИРЫ ===");
    SendClientMessage(playerid, 0xFFFFFFFF, " ");
    
    for(new i = 0; i < ApartmentCount; i++) {
        if(ApartmentInfo[i][Owner] == playerid) {
            count++;
            
            format(string, sizeof(string), "ID: %d | %s", i, ApartmentInfo[i][ApartmentName]);
            SendClientMessage(playerid, 0x00FF00FF, string);
            
            format(string, sizeof(string), "Комнат: %d | Безопасность: %d/5", 
                ApartmentInfo[i][Rooms], ApartmentInfo[i][SecurityLevel]);
            SendClientMessage(playerid, 0xFFFFFFFF, string);
            
            if(ApartmentInfo[i][IsRented]) {
                format(string, sizeof(string), "Сдается в аренду: %s", GetPlayerNameEx(ApartmentInfo[i][CurrentRenter]));
            } else {
                format(string, sizeof(string), "Статус: Свободна");
            }
            SendClientMessage(playerid, 0xFFFFFFFF, string);
            
            SendClientMessage(playerid, 0xFFFFFFFF, " ");
        }
    }
    
    if(count == 0) {
        SendClientMessage(playerid, 0xFF0000FF, "У вас нет квартир!");
    }
    
    return 1;
}

CMD:buyapartment(playerid, params[]) {
    new apartmentid;
    
    if(sscanf(params, "d", apartmentid)) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Используйте: /buyapartment [ID]");
        return 1;
    }
    
    if(apartmentid < 0 || apartmentid >= ApartmentCount) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Неправильный ID квартиры!");
        return 1;
    }
    
    if(!ApartmentInfo[apartmentid][IsForSale]) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Эта квартира не на продажу!");
        return 1;
    }
    
    if(GetPlayerMoney(playerid) < ApartmentInfo[apartmentid][Price]) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Недостаточно денег!");
        return 1;
    }
    
    GivePlayerMoney(playerid, -ApartmentInfo[apartmentid][Price]);
    
    ApartmentInfo[apartmentid][Owner] = playerid;
    ApartmentInfo[apartmentid][IsForSale] = false;
    
    SaveApartmentData(apartmentid);
    
    new string[256];
    format(string, sizeof(string), "[SUCCESS] Вы купили квартиру '%s' за $%d", 
        ApartmentInfo[apartmentid][ApartmentName], ApartmentInfo[apartmentid][Price]);
    SendClientMessage(playerid, 0x00FF00FF, string);
    
    SendClientMessageToAll(0xFFFFFFFF, string);
    
    return 1;
}

CMD:sellapartment(playerid, params[]) {
    new apartmentid, sellprice;
    
    if(sscanf(params, "dd", apartmentid, sellprice)) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Используйте: /sellapartment [ID] [цена]");
        return 1;
    }
    
    if(apartmentid < 0 || apartmentid >= ApartmentCount) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Неправильный ID квартиры!");
        return 1;
    }
    
    if(ApartmentInfo[apartmentid][Owner] != playerid) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Это не ваша квартира!");
        return 1;
    }
    
    ApartmentInfo[apartmentid][Price] = sellprice;
    ApartmentInfo[apartmentid][IsForSale] = true;
    ApartmentInfo[apartmentid][Owner] = -1;
    
    SaveApartmentData(apartmentid);
    
    new string[256];
    format(string, sizeof(string), "[SUCCESS] Квартира выставлена на продажу за $%d", sellprice);
    SendClientMessage(playerid, 0x00FF00FF, string);
    
    return 1;
}

CMD:rentapartment(playerid, params[]) {
    new apartmentid;
    
    if(sscanf(params, "d", apartmentid)) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Используйте: /rentapartment [ID]");
        return 1;
    }
    
    if(apartmentid < 0 || apartmentid >= ApartmentCount) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Неправильный ID квартиры!");
        return 1;
    }
    
    if(ApartmentInfo[apartmentid][Owner] == playerid) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Это ваша квартира!");
        return 1;
    }
    
    if(ApartmentInfo[apartmentid][IsRented]) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Квартира уже сдается!");
        return 1;
    }
    
    if(GetPlayerMoney(playerid) < ApartmentInfo[apartmentid][RentPrice]) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Недостаточно денег для аренды!");
        return 1;
    }
    
    GivePlayerMoney(playerid, -ApartmentInfo[apartmentid][RentPrice]);
    
    // Отправляем деньги хозяину (если есть)
    if(ApartmentInfo[apartmentid][Owner] != -1) {
        // TODO: Добавить деньги хозяину
    }
    
    ApartmentInfo[apartmentid][IsRented] = true;
    ApartmentInfo[apartmentid][CurrentRenter] = playerid;
    
    SaveApartmentData(apartmentid);
    
    new string[256];
    format(string, sizeof(string), "[SUCCESS] Вы снял квартиру '%s' на 1 день за $%d", 
        ApartmentInfo[apartmentid][ApartmentName], ApartmentInfo[apartmentid][RentPrice]);
    SendClientMessage(playerid, 0x00FF00FF, string);
    
    return 1;
}

CMD:apartmentinfo(playerid, params[]) {
    new apartmentid;
    
    if(sscanf(params, "d", apartmentid)) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Используйте: /apartmentinfo [ID]");
        return 1;
    }
    
    if(apartmentid < 0 || apartmentid >= ApartmentCount) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Неправильный ID квартиры!");
        return 1;
    }
    
    new string[512];
    
    format(string, sizeof(string), 
        "Квартира: %s\n\n\
        Комнат: %d\n\
        Цена покупки: $%d\n\
        Цена аренды: $%d в день\n\
        Безопасность: %d/5\n\n\
        Собственник: %s\n\
        На продажу: %s\n\
        На аренду: %s",
        ApartmentInfo[apartmentid][ApartmentName],
        ApartmentInfo[apartmentid][Rooms],
        ApartmentInfo[apartmentid][Price],
        ApartmentInfo[apartmentid][RentPrice],
        ApartmentInfo[apartmentid][SecurityLevel],
        (ApartmentInfo[apartmentid][Owner] == -1) ? "Государство" : GetPlayerNameEx(ApartmentInfo[apartmentid][Owner]),
        ApartmentInfo[apartmentid][IsForSale] ? "ДА" : "НЕТ",
        ApartmentInfo[apartmentid][IsRented] ? "ДА" : "НЕТ");
    
    ShowPlayerDialog(playerid, 9997, DIALOG_STYLE_MSGBOX, "Информация о квартире", string, "OK", "");
    
    return 1;
}

CMD:enterapartment(playerid, params[]) {
    new apartmentid;
    
    if(sscanf(params, "d", apartmentid)) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Используйте: /enterapartment [ID]");
        return 1;
    }
    
    if(apartmentid < 0 || apartmentid >= ApartmentCount) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Неправильный ID квартиры!");
        return 1;
    }
    
    // Проверяем право входа
    if(ApartmentInfo[apartmentid][Owner] != playerid && ApartmentInfo[apartmentid][CurrentRenter] != playerid) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Это не ваша квартира!");
        return 1;
    }
    
    // Телепортируем внутрь
    new interior = ApartmentInfo[apartmentid][InteriorID];
    
    SetPlayerInterior(playerid, interior);
    SetPlayerVirtualWorld(playerid, ApartmentInfo[apartmentid][VirtualWorldID]);
    SetPlayerPos(playerid, Interiors[interior][InteriorX], Interiors[interior][InteriorY], Interiors[interior][InteriorZ]);
    SetPlayerFacingAngle(playerid, Interiors[interior][InteriorA]);
    
    PlayerInApartment[playerid] = apartmentid;
    
    new string[256];
    format(string, sizeof(string), "[INFO] Вы вошли в квартиру: %s", ApartmentInfo[apartmentid][ApartmentName]);
    SendClientMessage(playerid, 0x00FF00FF, string);
    
    return 1;
}

CMD:exitapartment(playerid, params[]) {
    if(PlayerInApartment[playerid] == -1) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Вы не в квартире!");
        return 1;
    }
    
    new apartmentid = PlayerInApartment[playerid];
    
    SetPlayerInterior(playerid, 0);
    SetPlayerVirtualWorld(playerid, 0);
    SetPlayerPos(playerid, ApartmentInfo[apartmentid][EnterX], ApartmentInfo[apartmentid][EnterY], ApartmentInfo[apartmentid][EnterZ]);
    
    PlayerInApartment[playerid] = -1;
    
    SendClientMessage(playerid, 0x00FF00FF, "[INFO] Вы вышли из квартиры");
    
    return 1;
}

CMD:furniture(playerid, params[]) {
    if(PlayerInApartment[playerid] == -1) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Вы должны быть в квартире!");
        return 1;
    }
    
    new string[512];
    SendClientMessage(playerid, 0x00FF00FF, "=== МЕБЕЛЬ И ПРЕДМЕТЫ ===");
    SendClientMessage(playerid, 0xFFFFFFFF, " ");
    SendClientMessage(playerid, 0xFFFFFFFF, "Кровать - $1000");
    SendClientMessage(playerid, 0xFFFFFFFF, "Диван - $1500");
    SendClientMessage(playerid, 0xFFFFFFFF, "Стол - $800");
    SendClientMessage(playerid, 0xFFFFFFFF, "Стул - $500");
    SendClientMessage(playerid, 0xFFFFFFFF, "Шкаф - $2000");
    SendClientMessage(playerid, 0xFFFFFFFF, "Холодильник - $3000");
    SendClientMessage(playerid, 0xFFFFFFFF, "ТВ - $5000");
    SendClientMessage(playerid, 0xFFFFFFFF, " ");
    SendClientMessage(playerid, 0xFFFFFFFF, "Используйте: /buyfurniture [название]");
    
    return 1;
}

CMD:buyfurniture(playerid, params[]) {
    new furniturename[32];
    
    if(sscanf(params, "s[32]", furniturename)) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Используйте: /buyfurniture [название]");
        return 1;
    }
    
    if(PlayerInApartment[playerid] == -1) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Вы должны быть в квартире!");
        return 1;
    }
    
    new price = 0;
    
    if(!strcmp(furniturename, "кровать", false)) {
        price = 1000;
    } else if(!strcmp(furniturename, "диван", false)) {
        price = 1500;
    } else if(!strcmp(furniturename, "стол", false)) {
        price = 800;
    } else if(!strcmp(furniturename, "стул", false)) {
        price = 500;
    } else if(!strcmp(furniturename, "шкаф", false)) {
        price = 2000;
    } else if(!strcmp(furniturename, "холодильник", false)) {
        price = 3000;
    } else if(!strcmp(furniturename, "тв", false)) {
        price = 5000;
    } else {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Неизвестная мебель!");
        return 1;
    }
    
    if(GetPlayerMoney(playerid) < price) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Недостаточно денег!");
        return 1;
    }
    
    GivePlayerMoney(playerid, -price);
    
    new string[256];
    format(string, sizeof(string), "[SUCCESS] Вы купили %s за $%d", furniturename, price);
    SendClientMessage(playerid, 0x00FF00FF, string);
    
    return 1;
}

// ============ ДИАЛОГИ ============

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[]) {
    if(dialogid >= 5000 && dialogid <= 5099) { // Диалоги квартир
        new apartmentid = dialogid - 5000;
        
        if(!response) return 1;
        
        switch(listitem) {
            case 0: { // Купить квартиру
                if(!ApartmentInfo[apartmentid][IsForSale]) {
                    SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Эта квартира не на продажу!");
                    return 1;
                }
                
                if(GetPlayerMoney(playerid) < ApartmentInfo[apartmentid][Price]) {
                    SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Недостаточно денег!");
                    return 1;
                }
                
                GivePlayerMoney(playerid, -ApartmentInfo[apartmentid][Price]);
                ApartmentInfo[apartmentid][Owner] = playerid;
                ApartmentInfo[apartmentid][IsForSale] = false;
                
                SaveApartmentData(apartmentid);
                
                new string[256];
                format(string, sizeof(string), "[SUCCESS] Вы купили квартиру '%s' за $%d", 
                    ApartmentInfo[apartmentid][ApartmentName], ApartmentInfo[apartmentid][Price]);
                SendClientMessage(playerid, 0x00FF00FF, string);
            }
            
            case 1: { // Снять на аренду
                if(ApartmentInfo[apartmentid][Owner] == playerid) {
                    SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Это ваша квартира!");
                    return 1;
                }
                
                if(ApartmentInfo[apartmentid][IsRented]) {
                    SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Квартира уже сдается!");
                    return 1;
                }
                
                if(GetPlayerMoney(playerid) < ApartmentInfo[apartmentid][RentPrice]) {
                    SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Недостаточно денег!");
                    return 1;
                }
                
                GivePlayerMoney(playerid, -ApartmentInfo[apartmentid][RentPrice]);
                ApartmentInfo[apartmentid][IsRented] = true;
                ApartmentInfo[apartmentid][CurrentRenter] = playerid;
                
                SaveApartmentData(apartmentid);
                
                new string[256];
                format(string, sizeof(string), "[SUCCESS] Вы снял квартиру на 1 день за $%d", ApartmentInfo[apartmentid][RentPrice]);
                SendClientMessage(playerid, 0x00FF00FF, string);
            }
            
            case 2: { // Информация
                new string[512];
                format(string, sizeof(string), 
                    "Квартира: %s\n\n\
                    Комнат: %d\n\
                    Цена: $%d\n\
                    Аренда: $%d в день\n\n\
                    Собственник: %s\n\
                    На продажу: %s",
                    ApartmentInfo[apartmentid][ApartmentName],
                    ApartmentInfo[apartmentid][Rooms],
                    ApartmentInfo[apartmentid][Price],
                    ApartmentInfo[apartmentid][RentPrice],
                    (ApartmentInfo[apartmentid][Owner] == -1) ? "Государство" : GetPlayerNameEx(ApartmentInfo[apartmentid][Owner]),
                    ApartmentInfo[apartmentid][IsForSale] ? "ДА" : "НЕТ");
                
                ShowPlayerDialog(playerid, 9999, DIALOG_STYLE_MSGBOX, "Информация", string, "OK", "");
            }
        }
    }
    
    return 1;
}

// ============ ДИАЛОГОВЫЕ ФУНКЦИИ ============

stock ShowApartmentDialog(playerid, apartmentid) {
    new string[512];
    
    format(string, sizeof(string), 
        "%s\n\n\
        Комнат: %d | Цена: $%d\n\
        Аренда: $%d в день\n\n\
        Выберите действие:\n\n\
        Купить квартиру\n\
        Снять на аренду\n\
        Информация",
        ApartmentInfo[apartmentid][ApartmentName],
        ApartmentInfo[apartmentid][Rooms],
        ApartmentInfo[apartmentid][Price],
        ApartmentInfo[apartmentid][RentPrice]);
    
    ShowPlayerDialog(playerid, 5000 + apartmentid, DIALOG_STYLE_LIST, "Квартира", string, "Выбрать", "Отмена");
}

// ============ HELPER ФУНКЦИИ ============

stock SaveApartmentData(apartmentid) {
    new query[512];
    
    mysql_format(g_SQL, query, sizeof(query),
        "UPDATE `apartments` SET `Owner` = %d, `IsForSale` = %d, `Price` = %d, `IsRented` = %d, `CurrentRenter` = %d WHERE `ID` = %d",
        ApartmentInfo[apartmentid][Owner], ApartmentInfo[apartmentid][IsForSale], ApartmentInfo[apartmentid][Price],
        ApartmentInfo[apartmentid][IsRented], ApartmentInfo[apartmentid][CurrentRenter], apartmentid);
    
    mysql_query(g_SQL, query, true);
}

stock SaveAllApartmentData() {
    for(new i = 0; i < ApartmentCount; i++) {
        SaveApartmentData(i);
    }
}

stock LoadApartmentData(apartmentid) {
    // TODO: Загрузить данные квартиры из БД
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
