/*
 * Black Russia - Economy & Bank System
 * Система экономики и банков
 */

#define FILTERSCRIPT

#include <a_samp>
#include <zcmd>
#include <sscanf2>

#include "../include/blackrussia.inc"
#include "../include/defines.inc"
#include "../include/database.inc"

// ============ ПЕРЕМЕННЫЕ ============

new PlayerBankAccount[MAX_PLAYERS];
new PlayerAccountBalance[MAX_PLAYERS];
new BankMarkers[MAX_BANKS];
new BankPickups[MAX_BANKS];

#define MAX_BANKS 5

enum BankInfo {
    BankID,
    BankName[32],
    Float:EnterX,
    Float:EnterY,
    Float:EnterZ,
    InteriorID,
    VirtualWorldID,
    BankBalance,
    SecurityLevel
};

new Banks[MAX_BANKS][BankInfo] = {
    {0, "ЦБ РФ - Московский офис", 300.0, 300.0, 15.0, 0, 0, 10000000, 5},
    {1, "Сбербанк", 350.0, 350.0, 15.0, 0, 0, 5000000, 4},
    {2, "Альфа-Банк", 400.0, 400.0, 15.0, 0, 0, 3000000, 3},
    {3, "ВТБ Банк", 450.0, 450.0, 15.0, 0, 0, 2000000, 2},
    {4, "Совкомбанк", 500.0, 500.0, 15.0, 0, 0, 1000000, 1}
};

// ============ CALLBACK'И ============

public OnFilterScriptInit() {
    print("\n");
    print("====================================");
    print("Economy & Bank System загружена!");
    print("====================================\n");
    
    CreateBankMarkers();
    InitBankAccounts();
    
    return 1;
}

public OnFilterScriptExit() {
    print("[Economy] Система экономики выгружена");
    return 1;
}

public OnPlayerConnect(playerid) {
    PlayerBankAccount[playerid] = -1;
    PlayerAccountBalance[playerid] = 0;
    return 1;
}

public OnPlayerDisconnect(playerid, reason) {
    SavePlayerBankData(playerid);
    return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid) {
    for(new i = 0; i < MAX_BANKS; i++) {
        if(BankPickups[i] == pickupid) {
            ShowBankDialog(playerid, i);
            return 1;
        }
    }
    return 1;
}

// ============ СОЗДАНИЕ БАНКОВ И МАРКЕРОВ ============

CreateBankMarkers() {
    print("[Economy] Создание маркеров банков...");
    
    for(new i = 0; i < MAX_BANKS; i++) {
        BankPickups[i] = CreatePickup(1239, 1, Banks[i][EnterX], Banks[i][EnterY], Banks[i][EnterZ]);
        CreateDynamicMapIcon(Banks[i][EnterX], Banks[i][EnterY], Banks[i][EnterZ], 56, 0x00FF00FF, 0, 0, -1, 100.0);
    }
    
    print("[Economy] Маркеры банков созданы!");
}

InitBankAccounts() {
    print("[Economy] Инициализация банков...");
    
    // Вставляем банки в БД если их нет
    new query[512];
    
    for(new i = 0; i < MAX_BANKS; i++) {
        mysql_format(g_SQL, query, sizeof(query),
            "INSERT IGNORE INTO `bank_accounts` (`ID`, `Balance`) VALUES (%d, %d)",
            i, Banks[i][BankBalance]);
        
        mysql_query(g_SQL, query, true);
    }
    
    print("[Economy] Инициализация банков завершена!");
}

// ============ КОМАНДЫ ИГРОКА ============

CMD:bank(playerid, params[]) {
    new string[512];
    
    if(PlayerBankAccount[playerid] == -1) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Вы не имеете банковского счета!");
        SendClientMessage(playerid, 0xFFFFFFFF, "Посетите банк и откройте счет командой /openaccount");
        return 1;
    }
    
    SendClientMessage(playerid, 0x00FF00FF, "=== ИНФОРМАЦИЯ О БАНКЕ ===");
    SendClientMessage(playerid, 0xFFFFFFFF, " ");
    
    format(string, sizeof(string), "На счету: $%d", PlayerAccountBalance[playerid]);
    SendClientMessage(playerid, 0x00FF00FF, string);
    
    format(string, sizeof(string), "Наличные: $%d", GetPlayerMoney(playerid));
    SendClientMessage(playerid, 0xFFFFFFFF, string);
    
    new total = GetPlayerMoney(playerid) + PlayerAccountBalance[playerid];
    format(string, sizeof(string), "Всего: $%d", total);
    SendClientMessage(playerid, 0x00FF00FF, string);
    
    SendClientMessage(playerid, 0xFFFFFFFF, " ");
    SendClientMessage(playerid, 0xFFFFFFFF, "Команды: /deposit, /withdraw, /transfer");
    
    return 1;
}

CMD:openaccount(playerid, params[]) {
    if(PlayerBankAccount[playerid] != -1) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] У вас уже есть банковский счет!");
        return 1;
    }
    
    new query[256], playerid_db = GetPlayerDatabaseID(playerid);
    
    mysql_format(g_SQL, query, sizeof(query),
        "INSERT INTO `bank_accounts` (`PlayerID`, `Balance`, `IsActive`) VALUES (%d, 0, 1)",
        playerid_db);
    
    if(mysql_query(g_SQL, query, true)) {
        PlayerBankAccount[playerid] = mysql_insert_id(g_SQL);
        PlayerAccountBalance[playerid] = 0;
        
        SendClientMessage(playerid, 0x00FF00FF, "[SUCCESS] Банковский счет успешно открыт!");
        
        new string[128];
        format(string, sizeof(string), "Номер счета: %d", PlayerBankAccount[playerid]);
        SendClientMessage(playerid, 0xFFFFFFFF, string);
    } else {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Ошибка при создании счета!");
    }
    
    return 1;
}

CMD:deposit(playerid, params[]) {
    new amount;
    
    if(sscanf(params, "d", amount)) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Используйте: /deposit [сумма]");
        return 1;
    }
    
    if(PlayerBankAccount[playerid] == -1) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] У вас нет банковского счета!");
        return 1;
    }
    
    if(amount <= 0) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Сумма должна быть больше нуля!");
        return 1;
    }
    
    if(GetPlayerMoney(playerid) < amount) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Недостаточно денег!");
        return 1;
    }
    
    // Снимаем деньги с наличности
    GivePlayerMoney(playerid, -amount);
    
    // Добавляем на счет
    PlayerAccountBalance[playerid] += amount;
    
    // Сохраняем в БД
    new query[256];
    mysql_format(g_SQL, query, sizeof(query),
        "UPDATE `bank_accounts` SET `Balance` = %d WHERE `ID` = %d",
        PlayerAccountBalance[playerid], PlayerBankAccount[playerid]);
    
    mysql_query(g_SQL, query, true);
    
    new string[128];
    format(string, sizeof(string), "[SUCCESS] Вы положили $%d на счет", amount);
    SendClientMessage(playerid, 0x00FF00FF, string);
    
    format(string, sizeof(string), "Остаток на счете: $%d", PlayerAccountBalance[playerid]);
    SendClientMessage(playerid, 0xFFFFFFFF, string);
    
    // Логирование транзакции
    LogTransaction(0, PlayerBankAccount[playerid], amount, "Пополнение счета");
    
    return 1;
}

CMD:withdraw(playerid, params[]) {
    new amount;
    
    if(sscanf(params, "d", amount)) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Используйте: /withdraw [сумма]");
        return 1;
    }
    
    if(PlayerBankAccount[playerid] == -1) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] У вас нет банковского счета!");
        return 1;
    }
    
    if(amount <= 0) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Сумма должна быть больше нуля!");
        return 1;
    }
    
    if(PlayerAccountBalance[playerid] < amount) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Недостаточно средств на счете!");
        return 1;
    }
    
    // Снимаем со счета
    PlayerAccountBalance[playerid] -= amount;
    
    // Выдаем наличность
    GivePlayerMoney(playerid, amount);
    
    // Сохраняем в БД
    new query[256];
    mysql_format(g_SQL, query, sizeof(query),
        "UPDATE `bank_accounts` SET `Balance` = %d WHERE `ID` = %d",
        PlayerAccountBalance[playerid], PlayerBankAccount[playerid]);
    
    mysql_query(g_SQL, query, true);
    
    new string[128];
    format(string, sizeof(string), "[SUCCESS] Вы снял $%d со счета", amount);
    SendClientMessage(playerid, 0x00FF00FF, string);
    
    format(string, sizeof(string), "Остаток на счете: $%d", PlayerAccountBalance[playerid]);
    SendClientMessage(playerid, 0xFFFFFFFF, string);
    
    // Логирование транзакции
    LogTransaction(PlayerBankAccount[playerid], 0, amount, "Снятие со счета");
    
    return 1;
}

CMD:transfer(playerid, params[]) {
    new targetid, amount;
    
    if(sscanf(params, "ud", targetid, amount)) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Используйте: /transfer [ID игрока] [сумма]");
        return 1;
    }
    
    if(!IsPlayerConnected(targetid)) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Игрок не найден!");
        return 1;
    }
    
    if(targetid == playerid) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Вы не можете отправить деньги самому себе!");
        return 1;
    }
    
    if(PlayerBankAccount[playerid] == -1) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] У вас нет банковского счета!");
        return 1;
    }
    
    if(PlayerBankAccount[targetid] == -1) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] У получателя нет банковского счета!");
        return 1;
    }
    
    if(amount <= 0) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Сумма должна быть больше нуля!");
        return 1;
    }
    
    if(PlayerAccountBalance[playerid] < amount) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Недостаточно средств на счете!");
        return 1;
    }
    
    // Процент комиссии (1%)
    new commission = floatround(amount * 0.01);
    new totalAmount = amount + commission;
    
    if(PlayerAccountBalance[playerid] < totalAmount) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Недостаточно средств с учетом комиссии!");
        new string[128];
        format(string, sizeof(string), "Требуется: $%d (комиссия: $%d)", totalAmount, commission);
        SendClientMessage(playerid, 0xFFFFFFFF, string);
        return 1;
    }
    
    // Переводим деньги
    PlayerAccountBalance[playerid] -= totalAmount;
    PlayerAccountBalance[targetid] += amount;
    
    // Сохраняем в БД
    new query[512];
    
    mysql_format(g_SQL, query, sizeof(query),
        "UPDATE `bank_accounts` SET `Balance` = %d WHERE `ID` = %d",
        PlayerAccountBalance[playerid], PlayerBankAccount[playerid]);
    mysql_query(g_SQL, query, true);
    
    mysql_format(g_SQL, query, sizeof(query),
        "UPDATE `bank_accounts` SET `Balance` = %d WHERE `ID` = %d",
        PlayerAccountBalance[targetid], PlayerBankAccount[targetid]);
    mysql_query(g_SQL, query, true);
    
    // Уведомления
    new string[256];
    format(string, sizeof(string), "[SUCCESS] Вы отправили $%d игроку %s (комиссия: $%d)", 
        amount, GetPlayerNameEx(targetid), commission);
    SendClientMessage(playerid, 0x00FF00FF, string);
    
    format(string, sizeof(string), "[INFO] Вы получили $%d от %s", amount, GetPlayerNameEx(playerid));
    SendClientMessage(targetid, 0x00FF00FF, string);
    
    // Логирование транзакции
    LogTransaction(PlayerBankAccount[playerid], PlayerBankAccount[targetid], amount, "Перевод между счетами");
    
    return 1;
}

CMD:tax(playerid, params[]) {
    new playerid_db = GetPlayerDatabaseID(playerid);
    new query[256], money;
    
    money = GetPlayerMoney(playerid);
    
    if(money <= 0) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] У вас нет денег для уплаты налога!");
        return 1;
    }
    
    new tax = floatround(money * TAX_RATE); // 10% налог
    
    GivePlayerMoney(playerid, -tax);
    
    // Добавляем в гос. казну (банк ID 0)
    Banks[0][BankBalance] += tax;
    
    mysql_format(g_SQL, query, sizeof(query),
        "UPDATE `factions` SET `FactionBank` = `FactionBank` + %d WHERE `ID` = 0",
        tax);
    mysql_query(g_SQL, query, true);
    
    new string[128];
    format(string, sizeof(string), "[INFO] Налог уплачен: $%d", tax);
    SendClientMessage(playerid, 0xFFFFFFFF, string);
    
    return 1;
}

CMD:salary(playerid, params[]) {
    new playerid_db = GetPlayerDatabaseID(playerid);
    new salary = 5000; // Базовая зарплата
    
    GivePlayerMoney(playerid, salary);
    
    new string[128];
    format(string, sizeof(string), "[SUCCESS] Вы получили зарплату: $%d", salary);
    SendClientMessage(playerid, 0x00FF00FF, string);
    
    return 1;
}

// ============ ДИАЛОГИ ============

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[]) {
    if(dialogid >= 2000 && dialogid <= 2004) { // Банковские диалоги
        new bankid = dialogid - 2000;
        
        if(!response) return 1;
        
        switch(listitem) {
            case 0: { // Открыть счет
                if(PlayerBankAccount[playerid] != -1) {
                    SendClientMessage(playerid, 0xFF0000FF, "[ERROR] У вас уже есть счет!");
                    return 1;
                }
                
                new query[256], playerid_db = GetPlayerDatabaseID(playerid);
                
                mysql_format(g_SQL, query, sizeof(query),
                    "INSERT INTO `bank_accounts` (`PlayerID`, `Balance`, `IsActive`) VALUES (%d, 5000, 1)",
                    playerid_db);
                
                if(mysql_query(g_SQL, query, true)) {
                    PlayerBankAccount[playerid] = mysql_insert_id(g_SQL);
                    PlayerAccountBalance[playerid] = 5000;
                    
                    SendClientMessage(playerid, 0x00FF00FF, "[SUCCESS] Счет успешно открыт!");
                    SendClientMessage(playerid, 0xFFFFFFFF, "На счет зачислено $5000 в качестве подарка!");
                    
                    new string[128];
                    format(string, sizeof(string), "Номер счета: %d", PlayerBankAccount[playerid]);
                    SendClientMessage(playerid, 0xFFFFFFFF, string);
                } else {
                    SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Ошибка при создании счета!");
                }
            }
            
            case 1: { // Информация о банке
                new string[512];
                format(string, sizeof(string), 
                    "Банк: %s\n\n\
                    Баланс: $%d\n\
                    Уровень безопасности: %d/5\n\n\
                    Услуги:\n\
                    - Открытие счета\n\
                    - Пополнение счета\n\
                    - Снятие со счета\n\
                    - Переводы между счетами",
                    Banks[bankid][BankName],
                    Banks[bankid][BankBalance],
                    Banks[bankid][SecurityLevel]);
                
                ShowPlayerDialog(playerid, 9999, DIALOG_STYLE_MSGBOX, "Информация о банке", string, "OK", "");
            }
        }
    }
    
    return 1;
}

// ============ ДИАЛОГОВЫЕ ФУНКЦИИ ============

stock ShowBankDialog(playerid, bankid) {
    new string[512];
    
    format(string, sizeof(string), 
        "Добро пожаловать в %s!\n\n\
        Выберите услугу:\n\n\
        Открыть счет (стартовый баланс: $5000)\n\
        Информация о банке",
        Banks[bankid][BankName]);
    
    ShowPlayerDialog(playerid, 2000 + bankid, DIALOG_STYLE_LIST, "Банковские услуги", string, "Выбрать", "Отмена");
}

// ============ HELPER ФУНКЦИИ ============

stock GetPlayerMoney(playerid) {
    return GetPlayerCash(playerid);
}

stock LogTransaction(fromaccount, toaccount, amount, const description[]) {
    new query[512];
    
    mysql_format(g_SQL, query, sizeof(query),
        "INSERT INTO `transactions` (`FromAccount`, `ToAccount`, `Amount`, `TransactionType`, `Description`) \
        VALUES (%d, %d, %d, 'Transfer', '%s')",
        fromaccount, toaccount, amount, description);
    
    mysql_query(g_SQL, query, true);
}

stock SavePlayerBankData(playerid) {
    if(PlayerBankAccount[playerid] != -1) {
        new query[256];
        
        mysql_format(g_SQL, query, sizeof(query),
            "UPDATE `bank_accounts` SET `Balance` = %d WHERE `ID` = %d",
            PlayerAccountBalance[playerid], PlayerBankAccount[playerid]);
        
        mysql_query(g_SQL, query, true);
    }
}

stock LoadPlayerBankData(playerid) {
    // TODO: Загрузить данные банка из БД
}

stock GetPlayerNameEx(playerid) {
    new name[24];
    GetPlayerName(playerid, name, sizeof(name));
    return name;
}

stock GetPlayerDatabaseID(playerid) {
    // TODO: Получить ID из БД
    return playerid;
}
