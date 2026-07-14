/*
 * Black Russia - Business & Trading System
 * Система бизнеса и торговли
 */

#define FILTERSCRIPT

#include <a_samp>
#include <zcmd>
#include <sscanf2>

#include "../include/blackrussia.inc"
#include "../include/defines.inc"
#include "../include/database.inc"

// ============ ПЕРЕМЕННЫЕ ============

new BusinessInfo[MAX_BUSINESS][BusinessData];
new BusinessPickups[MAX_BUSINESS];
new BusinessCount = 0;
new PlayerInBusiness[MAX_PLAYERS];

// ============ ПРЕДУСТАНОВЛЕННЫЕ БИЗНЕСЫ ============

enum DefaultBusiness {
    DefaultName[32],
    DefaultType,
    Float:DefaultX,
    Float:DefaultY,
    Float:DefaultZ,
    DefaultPrice,
    DefaultIncome
};

new DefaultBusinesses[10][DefaultBusiness] = {
    {"7-Eleven #1", BUSINESS_SHOP, 600.0, 100.0, 20.0, 50000, 5000},
    {"7-Eleven #2", BUSINESS_SHOP, 700.0, 100.0, 20.0, 50000, 5000},
    {"Бар 'Колхоз'", BUSINESS_BAR, 800.0, 200.0, 20.0, 100000, 10000},
    {"Казино 'Москва'", BUSINESS_CASINO, 900.0, 300.0, 20.0, 500000, 50000},
    {"АЗС 'Лукойл'", BUSINESS_GAS_STATION, 1000.0, 400.0, 20.0, 150000, 15000},
    {"Ресторан 'Русь'", BUSINESS_RESTAURANT, 1100.0, 500.0, 20.0, 200000, 20000},
    {"Ночной клуб 'Ночь'", BUSINESS_NIGHTCLUB, 1200.0, 600.0, 20.0, 300000, 30000},
    {"Фабрика одежды", BUSINESS_FACTORY, 1300.0, 700.0, 20.0, 400000, 40000},
    {"Маркет 'Лучший'", BUSINESS_SHOP, 1400.0, 800.0, 20.0, 75000, 7500},
    {"Пивная 'Охота'", BUSINESS_BAR, 1500.0, 900.0, 20.0, 120000, 12000}
};

// ============ ТИПЫ ТОВАРОВ ============

enum ItemData {
    ItemName[32],
    ItemPrice,
    ItemStock,
    ItemType // 0 = Еда, 1 = Напитки, 2 = Одежда, 3 = Электроника, 4 = Оружие
};

new ShopItems[10][ItemData] = {
    {"Гамбургер", 50, 100, 0},
    {"Пицца", 100, 50, 0},
    {"Сандвич", 75, 75, 0},
    {"Пиво", 150, 200, 1},
    {"Водка", 200, 100, 1},
    {"Сок", 50, 150, 1},
    {"Рубашка", 500, 30, 2},
    {"Джинсы", 400, 40, 2},
    {"Кроссовки", 300, 50, 2},
    {"Часы", 2000, 10, 3}
};

// ============ CALLBACK'И ============

public OnFilterScriptInit() {
    print("\n");
    print("====================================");
    print("Business & Trading System загружена!");
    print("====================================\n");
    
    LoadBusinesses();
    CreateBusinessMarkers();
    
    return 1;
}

public OnFilterScriptExit() {
    print("[Business] Система бизнеса выгружена");
    return 1;
}

public OnPlayerConnect(playerid) {
    PlayerInBusiness[playerid] = -1;
    return 1;
}

public OnPlayerDisconnect(playerid, reason) {
    SaveAllBusinessData();
    return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid) {
    for(new i = 0; i < BusinessCount; i++) {
        if(BusinessPickups[i] == pickupid) {
            ShowBusinessDialog(playerid, i);
            return 1;
        }
    }
    return 1;
}

// ============ ЗАГРУЗКА БИЗНЕСОВ ============

LoadBusinesses() {
    print("[Business] Загрузка бизнесов...");
    
    // Создаем предустановленные бизнесы
    for(new i = 0; i < 10; i++) {
        BusinessInfo[i][BusinessID] = i;
        strcpy(BusinessInfo[i][BusinessName], DefaultBusinesses[i][DefaultName], 32);
        BusinessInfo[i][BusinessType] = DefaultBusinesses[i][DefaultType];
        BusinessInfo[i][Owner] = -1; // Не имеет хозяина
        BusinessInfo[i][EnterX] = DefaultBusinesses[i][DefaultX];
        BusinessInfo[i][EnterY] = DefaultBusinesses[i][DefaultY];
        BusinessInfo[i][EnterZ] = DefaultBusinesses[i][DefaultZ];
        BusinessInfo[i][EnterAngle] = 0.0;
        BusinessInfo[i][InteriorID] = 0;
        BusinessInfo[i][VirtualWorldID] = 0;
        BusinessInfo[i][Income] = 0;
        BusinessInfo[i][MaxInventory] = 1000;
        BusinessInfo[i][CurrentInventory] = 500;
        BusinessInfo[i][IsOpen] = true;
        BusinessInfo[i][OpenHour] = 8;
        BusinessInfo[i][CloseHour] = 23;
        BusinessInfo[i][Price] = DefaultBusinesses[i][DefaultPrice];
        BusinessInfo[i][IsForSale] = true;
        BusinessInfo[i][SecurityLevel] = 1;
        
        BusinessCount++;
    }
    
    print("[Business] Бизнесы загружены!");
}

CreateBusinessMarkers() {
    print("[Business] Создание маркеров бизнесов...");
    
    for(new i = 0; i < BusinessCount; i++) {
        BusinessPickups[i] = CreatePickup(1239, 1, BusinessInfo[i][EnterX], BusinessInfo[i][EnterY], BusinessInfo[i][EnterZ]);
        
        new color = 0x00FF00FF; // Зеленый цвет по умолчанию
        
        if(BusinessInfo[i][BusinessType] == BUSINESS_SHOP) {
            color = 0xFF6347FF; // Помидор красный
        } else if(BusinessInfo[i][BusinessType] == BUSINESS_BAR) {
            color = 0xFFD700FF; // Золотой
        } else if(BusinessInfo[i][BusinessType] == BUSINESS_CASINO) {
            color = 0xFF1493FF; // Глубокий розовый
        } else if(BusinessInfo[i][BusinessType] == BUSINESS_GAS_STATION) {
            color = 0x00BFFFFF; // Синий
        }
        
        CreateDynamicMapIcon(BusinessInfo[i][EnterX], BusinessInfo[i][EnterY], BusinessInfo[i][EnterZ], 52, color, 0, 0, -1, 100.0);
    }
    
    printf("[Business] Создано маркеров: %d", BusinessCount);
}

// ============ КОМАНДЫ ============

CMD:business(playerid, params[]) {
    new string[512];
    SendClientMessage(playerid, 0x00FF00FF, "=== БИЗНЕСЫ ГОРОДА ===");
    SendClientMessage(playerid, 0xFFFFFFFF, " ");
    
    for(new i = 0; i < BusinessCount; i++) {
        new typetext[32];
        GetBusinessType(BusinessInfo[i][BusinessType], typetext);
        
        if(BusinessInfo[i][IsForSale]) {
            format(string, sizeof(string), "%d. %s [%s] - $%d (НА ПРОДАЖУ)", 
                i, BusinessInfo[i][BusinessName], typetext, BusinessInfo[i][Price]);
            SendClientMessage(playerid, 0xFFD700FF, string);
        } else {
            format(string, sizeof(string), "%d. %s [%s] - Владелец: %s", 
                i, BusinessInfo[i][BusinessName], typetext, 
                (BusinessInfo[i][Owner] == -1) ? "Государство" : GetPlayerNameEx(BusinessInfo[i][Owner]));
            SendClientMessage(playerid, 0xFFFFFFFF, string);
        }
        
        format(string, sizeof(string), "   Прибыль: $%d | Товаров: %d/%d", 
            BusinessInfo[i][Income], BusinessInfo[i][CurrentInventory], BusinessInfo[i][MaxInventory]);
        SendClientMessage(playerid, 0xFFFFFFFF, string);
    }
    
    return 1;
}

CMD:buybusiness(playerid, params[]) {
    new businessid;
    
    if(sscanf(params, "d", businessid)) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Используйте: /buybusiness [ID бизнеса]");
        return 1;
    }
    
    if(businessid < 0 || businessid >= BusinessCount) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Неправильный ID бизнеса!");
        return 1;
    }
    
    if(!BusinessInfo[businessid][IsForSale]) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Этот бизнес не на продажу!");
        return 1;
    }
    
    if(GetPlayerMoney(playerid) < BusinessInfo[businessid][Price]) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Недостаточно денег!");
        return 1;
    }
    
    // Снимаем деньги
    GivePlayerMoney(playerid, -BusinessInfo[businessid][Price]);
    
    // Назначаем хозяина
    BusinessInfo[businessid][Owner] = playerid;
    BusinessInfo[businessid][IsForSale] = false;
    BusinessInfo[businessid][Income] = 0;
    
    // Сохраняем в БД
    SaveBusinessData(businessid);
    
    new string[256];
    format(string, sizeof(string), "[SUCCESS] Вы купили бизнес '%s' за $%d", 
        BusinessInfo[businessid][BusinessName], BusinessInfo[businessid][Price]);
    SendClientMessage(playerid, 0x00FF00FF, string);
    
    SendClientMessageToAll(0xFFFFFFFF, string);
    
    return 1;
}

CMD:sellbusiness(playerid, params[]) {
    new businessid, sellprice;
    
    if(sscanf(params, "dd", businessid, sellprice)) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Используйте: /sellbusiness [ID] [цена]");
        return 1;
    }
    
    if(businessid < 0 || businessid >= BusinessCount) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Неправильный ID бизнеса!");
        return 1;
    }
    
    if(BusinessInfo[businessid][Owner] != playerid) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Это не ваш бизнес!");
        return 1;
    }
    
    if(sellprice <= 0) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Цена должна быть больше нуля!");
        return 1;
    }
    
    BusinessInfo[businessid][Price] = sellprice;
    BusinessInfo[businessid][IsForSale] = true;
    BusinessInfo[businessid][Owner] = -1;
    
    SaveBusinessData(businessid);
    
    new string[256];
    format(string, sizeof(string), "[SUCCESS] Бизнес '%s' выставлен на продажу за $%d", 
        BusinessInfo[businessid][BusinessName], sellprice);
    SendClientMessage(playerid, 0x00FF00FF, string);
    
    return 1;
}

CMD:mybusiness(playerid, params[]) {
    new string[512];
    new ownedcount = 0;
    
    SendClientMessage(playerid, 0x00FF00FF, "=== МОИ БИЗНЕСЫ ===");
    SendClientMessage(playerid, 0xFFFFFFFF, " ");
    
    for(new i = 0; i < BusinessCount; i++) {
        if(BusinessInfo[i][Owner] == playerid) {
            ownedcount++;
            
            new typetext[32];
            GetBusinessType(BusinessInfo[i][BusinessType], typetext);
            
            format(string, sizeof(string), "ID: %d | %s [%s]", i, BusinessInfo[i][BusinessName], typetext);
            SendClientMessage(playerid, 0x00FF00FF, string);
            
            format(string, sizeof(string), "Прибыль: $%d | Товаров: %d/%d", 
                BusinessInfo[i][Income], BusinessInfo[i][CurrentInventory], BusinessInfo[i][MaxInventory]);
            SendClientMessage(playerid, 0xFFFFFFFF, string);
            
            if(BusinessInfo[i][IsOpen]) {
                SendClientMessage(playerid, 0x00FF00FF, "Статус: ОТКРЫТО");
            } else {
                SendClientMessage(playerid, 0xFF0000FF, "Статус: ЗАКРЫТО");
            }
            
            SendClientMessage(playerid, 0xFFFFFFFF, " ");
        }
    }
    
    if(ownedcount == 0) {
        SendClientMessage(playerid, 0xFF0000FF, "У вас нет бизнесов!");
    }
    
    return 1;
}

CMD:businessinfo(playerid, params[]) {
    new businessid;
    
    if(sscanf(params, "d", businessid)) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Используйте: /businessinfo [ID]");
        return 1;
    }
    
    if(businessid < 0 || businessid >= BusinessCount) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Неправильный ID бизнеса!");
        return 1;
    }
    
    new string[512], typetext[32];
    GetBusinessType(BusinessInfo[businessid][BusinessType], typetext);
    
    format(string, sizeof(string), 
        "Бизнес: %s\n\
        Тип: %s\n\
        Хозяин: %s\n\
        Цена: $%d\n\
        На продажу: %s\n\n\
        Прибыль: $%d\n\
        Товаров: %d/%d\n\
        Статус: %s",
        BusinessInfo[businessid][BusinessName],
        typetext,
        (BusinessInfo[businessid][Owner] == -1) ? "Государство" : GetPlayerNameEx(BusinessInfo[businessid][Owner]),
        BusinessInfo[businessid][Price],
        BusinessInfo[businessid][IsForSale] ? "ДА" : "НЕТ",
        BusinessInfo[businessid][Income],
        BusinessInfo[businessid][CurrentInventory],
        BusinessInfo[businessid][MaxInventory],
        BusinessInfo[businessid][IsOpen] ? "ОТКРЫТО" : "ЗАКРЫТО");
    
    ShowPlayerDialog(playerid, 9998, DIALOG_STYLE_MSGBOX, "Информация о бизнесе", string, "OK", "");
    
    return 1;
}

CMD:buygood(playerid, params[]) {
    new businessid, itemid, quantity;
    
    if(sscanf(params, "ddd", businessid, itemid, quantity)) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Используйте: /buygood [бизнес] [товар] [кол-во]");
        return 1;
    }
    
    if(businessid < 0 || businessid >= BusinessCount) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Неправильный ID бизнеса!");
        return 1;
    }
    
    if(itemid < 0 || itemid >= sizeof(ShopItems)) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Неправильный ID товара!");
        return 1;
    }
    
    new totalcost = ShopItems[itemid][ItemPrice] * quantity;
    
    if(GetPlayerMoney(playerid) < totalcost) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Недостаточно денег!");
        return 1;
    }
    
    if(ShopItems[itemid][ItemStock] < quantity) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Недостаточно товара в наличии!");
        return 1;
    }
    
    // Снимаем деньги с игрока
    GivePlayerMoney(playerid, -totalcost);
    
    // Добавляем прибыль бизнесу
    BusinessInfo[businessid][Income] += totalcost;
    
    // Уменьшаем товар
    ShopItems[itemid][ItemStock] -= quantity;
    
    SaveBusinessData(businessid);
    
    new string[256];
    format(string, sizeof(string), "[SUCCESS] Вы купили %d x %s за $%d", 
        quantity, ShopItems[itemid][ItemName], totalcost);
    SendClientMessage(playerid, 0x00FF00FF, string);
    
    return 1;
}

CMD:withdrawbiz(playerid, params[]) {
    new businessid;
    
    if(sscanf(params, "d", businessid)) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Используйте: /withdrawbiz [ID]");
        return 1;
    }
    
    if(businessid < 0 || businessid >= BusinessCount) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Неправильный ID бизнеса!");
        return 1;
    }
    
    if(BusinessInfo[businessid][Owner] != playerid) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Это не ваш бизнес!");
        return 1;
    }
    
    if(BusinessInfo[businessid][Income] <= 0) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Нет средств для вывода!");
        return 1;
    }
    
    new income = BusinessInfo[businessid][Income];
    
    GivePlayerMoney(playerid, income);
    BusinessInfo[businessid][Income] = 0;
    
    SaveBusinessData(businessid);
    
    new string[256];
    format(string, sizeof(string), "[SUCCESS] Вы вывели $%d из бизнеса", income);
    SendClientMessage(playerid, 0x00FF00FF, string);
    
    return 1;
}

// ============ ДИАЛОГИ ============

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[]) {
    if(dialogid >= 3000 && dialogid <= 3099) { // Бизнес диалоги
        new businessid = dialogid - 3000;
        
        if(!response) return 1;
        
        switch(listitem) {
            case 0: { // Купить бизнес
                if(!BusinessInfo[businessid][IsForSale]) {
                    SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Этот бизнес не на продажу!");
                    return 1;
                }
                
                if(GetPlayerMoney(playerid) < BusinessInfo[businessid][Price]) {
                    SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Недостаточно денег!");
                    new string[128];
                    format(string, sizeof(string), "Требуется: $%d", BusinessInfo[businessid][Price]);
                    SendClientMessage(playerid, 0xFFFFFFFF, string);
                    return 1;
                }
                
                GivePlayerMoney(playerid, -BusinessInfo[businessid][Price]);
                BusinessInfo[businessid][Owner] = playerid;
                BusinessInfo[businessid][IsForSale] = false;
                
                SaveBusinessData(businessid);
                
                new string[256];
                format(string, sizeof(string), "[SUCCESS] Вы купили бизнес '%s' за $%d", 
                    BusinessInfo[businessid][BusinessName], BusinessInfo[businessid][Price]);
                SendClientMessage(playerid, 0x00FF00FF, string);
            }
            
            case 1: { // Информация
                new string[512], typetext[32];
                GetBusinessType(BusinessInfo[businessid][BusinessType], typetext);
                
                format(string, sizeof(string), 
                    "Бизнес: %s\n\
                    Тип: %s\n\
                    Хозяин: %s\n\
                    Цена: $%d\n\n\
                    Прибыль: $%d\n\
                    Товаров: %d/%d",
                    BusinessInfo[businessid][BusinessName],
                    typetext,
                    (BusinessInfo[businessid][Owner] == -1) ? "Государство" : GetPlayerNameEx(BusinessInfo[businessid][Owner]),
                    BusinessInfo[businessid][Price],
                    BusinessInfo[businessid][Income],
                    BusinessInfo[businessid][CurrentInventory],
                    BusinessInfo[businessid][MaxInventory]);
                
                ShowPlayerDialog(playerid, 9999, DIALOG_STYLE_MSGBOX, "Информация о бизнесе", string, "OK", "");
            }
        }
    }
    
    return 1;
}

// ============ ДИАЛОГОВЫЕ ФУНКЦИИ ============

stock ShowBusinessDialog(playerid, businessid) {
    new string[512], typetext[32];
    GetBusinessType(BusinessInfo[businessid][BusinessType], typetext);
    
    format(string, sizeof(string), 
        "%s [%s]\n\n\
        Выберите действие:\n\n\
        Купить бизнес\n\
        Информация о би��несе",
        BusinessInfo[businessid][BusinessName], typetext);
    
    ShowPlayerDialog(playerid, 3000 + businessid, DIALOG_STYLE_LIST, "Бизнес", string, "Выбрать", "Отмена");
}

// ============ HELPER ФУНКЦИИ ============

stock GetBusinessType(type, text[]) {
    switch(type) {
        case BUSINESS_SHOP: strcpy(text, "Магазин");
        case BUSINESS_BAR: strcpy(text, "Бар");
        case BUSINESS_CASINO: strcpy(text, "Казино");
        case BUSINESS_GAS_STATION: strcpy(text, "АЗС");
        case BUSINESS_RESTAURANT: strcpy(text, "Ресторан");
        case BUSINESS_NIGHTCLUB: strcpy(text, "Ночной клуб");
        case BUSINESS_FACTORY: strcpy(text, "Фабрика");
        default: strcpy(text, "Неизвестный");
    }
}

stock SaveBusinessData(businessid) {
    new query[512];
    
    mysql_format(g_SQL, query, sizeof(query),
        "UPDATE `business` SET `Owner` = %d, `Income` = %d, `IsForSale` = %d, `Price` = %d WHERE `ID` = %d",
        BusinessInfo[businessid][Owner], BusinessInfo[businessid][Income], 
        BusinessInfo[businessid][IsForSale], BusinessInfo[businessid][Price], businessid);
    
    mysql_query(g_SQL, query, true);
}

stock SaveAllBusinessData() {
    for(new i = 0; i < BusinessCount; i++) {
        SaveBusinessData(i);
    }
}

stock LoadBusinessData(businessid) {
    // TODO: Загрузить данные бизнеса из БД
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
