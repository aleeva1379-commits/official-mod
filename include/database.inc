/*
 * Black Russia - Database Include
 * Система работы с базой данных MySQL
 * Подключение к хостингу
 */

#if defined _database_inc_
    #endinput
#endif
#define _database_inc_

#include <a_mysql>

// ============ КОНСТАНТЫ БД - ДАННЫЕ ДЛЯ ПОДКЛЮЧЕНИЯ ============

#define DB_HOST "127.0.0.1"          // Хост: 127.0.0.1
#define DB_USER "gs_345214"          // Пользователь: gs_345214
#define DB_PASS "6XjRVvTk5Pi8"       // Пароль: 6XjRVvTk5Pi8
#define DB_NAME "blackrussia"        // Имя БД: blackrussia
#define DB_PORT 3306                 // Порт MySQL (стандартный): 3306

// Примечание: Порт FTP (21) не используется для MySQL подключения!
// MySQL использует по умолчанию порт 3306

// ============ ПЕРЕМЕННЫЕ БД ============

new MySQL:g_SQL;
new bool:g_DBConnected = false;

// ============ ИНИЦИАЛИЗАЦИЯ БД ============

stock DB_Init() {
    new MySQL:handle = mysql_connect(DB_HOST, DB_USER, DB_PASS, DB_NAME, DB_PORT);
    
    if(mysql_errno() != 0) {
        print("[DATABASE] ============================================");
        print("[DATABASE] ОШИБКА ПОДКЛЮЧЕНИЯ К БД!");
        print("[DATABASE] ============================================");
        printf("[DATABASE] Хост: %s", DB_HOST);
        printf("[DATABASE] Пользователь: %s", DB_USER);
        printf("[DATABASE] БД: %s", DB_NAME);
        printf("[DATABASE] Порт: %d", DB_PORT);
        
        new error[256];
        mysql_error(error, _, sizeof(error));
        printf("[DATABASE] Ошибка: %s", error);
        print("[DATABASE] ============================================");
        return 0;
    }
    
    g_SQL = handle;
    g_DBConnected = true;
    
    print("[DATABASE] ============================================");
    print("[DATABASE] УСПЕШНОЕ ПОДКЛЮЧЕНИЕ К БД!");
    print("[DATABASE] ============================================");
    printf("[DATABASE] Хост: %s", DB_HOST);
    printf("[DATABASE] Пользователь: %s", DB_USER);
    printf("[DATABASE] БД: %s", DB_NAME);
    printf("[DATABASE] Порт: %d", DB_PORT);
    print("[DATABASE] ============================================");
    
    // Создание таблиц
    DB_CreateTables();
    
    return 1;
}

stock DB_Close() {
    if(g_DBConnected) {
        mysql_close(g_SQL);
        g_DBConnected = false;
        print("[DATABASE] Отключение от БД");
    }
}

// ============ СОЗДАНИЕ ТАБЛИЦ ============

stock DB_CreateTables() {
    new query[2048];
    
    print("[DATABASE] Создание таблиц...");
    
    // Таблица игроков
    mysql_format(g_SQL, query, sizeof(query),
        "CREATE TABLE IF NOT EXISTS `players` (\
        `ID` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,\
        `Name` VARCHAR(24) NOT NULL UNIQUE,\
        `FirstName` VARCHAR(24),\
        `LastName` VARCHAR(24),\
        `Password` VARCHAR(128) NOT NULL,\
        `Email` VARCHAR(64),\
        `Money` INT DEFAULT 1000,\
        `BankMoney` INT DEFAULT 5000,\
        `Level` INT DEFAULT 1,\
        `Experience` INT DEFAULT 0,\
        `Skin` INT DEFAULT 0,\
        `Faction` INT DEFAULT 0,\
        `Rank` INT DEFAULT 0,\
        `House` INT DEFAULT -1,\
        `Apartment` INT DEFAULT -1,\
        `CreatedAt` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,\
        `LastLogin` TIMESTAMP,\
        `PlayedHours` INT DEFAULT 0,\
        `KillsCount` INT DEFAULT 0,\
        `DeathsCount` INT DEFAULT 0,\
        `ArrestedCount` INT DEFAULT 0,\
        `Warnings` INT DEFAULT 0,\
        `IsBanned` BOOLEAN DEFAULT FALSE,\
        `BanReason` VARCHAR(256),\
        `BanDate` TIMESTAMP\
        )");
    
    mysql_tquery(g_SQL, query);
    
    // Таблица фракций
    mysql_format(g_SQL, query, sizeof(query),
        "CREATE TABLE IF NOT EXISTS `factions` (\
        `ID` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,\
        `FactionName` VARCHAR(32) NOT NULL UNIQUE,\
        `FactionType` INT DEFAULT 0,\
        `FactionLeader` INT,\
        `FactionBank` INT DEFAULT 0,\
        `MaxMembers` INT DEFAULT 50,\
        `Description` VARCHAR(256),\
        `CreatedAt` TIMESTAMP DEFAULT CURRENT_TIMESTAMP\
        )");
    
    mysql_tquery(g_SQL, query);
    
    // Таблица бизнесов
    mysql_format(g_SQL, query, sizeof(query),
        "CREATE TABLE IF NOT EXISTS `business` (\
        `ID` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,\
        `BusinessName` VARCHAR(32) NOT NULL,\
        `BusinessType` INT DEFAULT 0,\
        `Owner` INT,\
        `EnterX` FLOAT,\
        `EnterY` FLOAT,\
        `EnterZ` FLOAT,\
        `EnterAngle` FLOAT,\
        `Interior` INT DEFAULT 0,\
        `VirtualWorld` INT DEFAULT 0,\
        `Income` INT DEFAULT 0,\
        `MaxInventory` INT DEFAULT 100,\
        `CurrentInventory` INT DEFAULT 0,\
        `IsOpen` BOOLEAN DEFAULT TRUE,\
        `OpenHour` INT DEFAULT 8,\
        `CloseHour` INT DEFAULT 23,\
        `Price` INT DEFAULT 50000,\
        `IsForSale` BOOLEAN DEFAULT FALSE,\
        `SecurityLevel` INT DEFAULT 1,\
        `CreatedAt` TIMESTAMP DEFAULT CURRENT_TIMESTAMP\
        )");
    
    mysql_tquery(g_SQL, query);
    
    // Таблица гаражей
    mysql_format(g_SQL, query, sizeof(query),
        "CREATE TABLE IF NOT EXISTS `garages` (\
        `ID` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,\
        `GarageName` VARCHAR(32) NOT NULL,\
        `Owner` INT,\
        `EnterX` FLOAT,\
        `EnterY` FLOAT,\
        `EnterZ` FLOAT,\
        `EnterAngle` FLOAT,\
        `Interior` INT DEFAULT 0,\
        `VirtualWorld` INT DEFAULT 0,\
        `MaxSlots` INT DEFAULT 10,\
        `UsedSlots` INT DEFAULT 0,\
        `IsPrivate` BOOLEAN DEFAULT TRUE,\
        `Price` INT DEFAULT 25000,\
        `IsForSale` BOOLEAN DEFAULT FALSE,\
        `CreatedAt` TIMESTAMP DEFAULT CURRENT_TIMESTAMP\
        )");
    
    mysql_tquery(g_SQL, query);
    
    // Таблица квартир
    mysql_format(g_SQL, query, sizeof(query),
        "CREATE TABLE IF NOT EXISTS `apartments` (\
        `ID` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,\
        `ApartmentName` VARCHAR(32) NOT NULL,\
        `Owner` INT,\
        `EnterX` FLOAT,\
        `EnterY` FLOAT,\
        `EnterZ` FLOAT,\
        `EnterAngle` FLOAT,\
        `Interior` INT DEFAULT 0,\
        `VirtualWorld` INT DEFAULT 0,\
        `Price` INT DEFAULT 50000,\
        `Rooms` INT DEFAULT 2,\
        `IsForSale` BOOLEAN DEFAULT FALSE,\
        `SecurityLevel` INT DEFAULT 1,\
        `RentPrice` INT DEFAULT 5000,\
        `IsRented` BOOLEAN DEFAULT FALSE,\
        `CurrentRenter` INT,\
        `CreatedAt` TIMESTAMP DEFAULT CURRENT_TIMESTAMP\
        )");
    
    mysql_tquery(g_SQL, query);
    
    // Таблица квестов
    mysql_format(g_SQL, query, sizeof(query),
        "CREATE TABLE IF NOT EXISTS `quests` (\
        `ID` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,\
        `QuestName` VARCHAR(64) NOT NULL,\
        `Description` VARCHAR(256),\
        `Type` INT DEFAULT 0,\
        `Location` VARCHAR(32),\
        `QuestX` FLOAT,\
        `QuestY` FLOAT,\
        `QuestZ` FLOAT,\
        `Difficulty` INT DEFAULT 1,\
        `MinLevel` INT DEFAULT 1,\
        `Reward` INT DEFAULT 1000,\
        `RewardExp` INT DEFAULT 100,\
        `TimeLimit` INT DEFAULT 3600,\
        `IsActive` BOOLEAN DEFAULT TRUE,\
        `CreatedAt` TIMESTAMP DEFAULT CURRENT_TIMESTAMP\
        )");
    
    mysql_tquery(g_SQL, query);
    
    // Таблица квестов игрока
    mysql_format(g_SQL, query, sizeof(query),
        "CREATE TABLE IF NOT EXISTS `player_quests` (\
        `ID` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,\
        `PlayerID` INT NOT NULL,\
        `QuestID` INT NOT NULL,\
        `Status` INT DEFAULT 0,\
        `Progress` INT DEFAULT 0,\
        `StartTime` TIMESTAMP,\
        `CompletedTime` TIMESTAMP,\
        `Reward` INT DEFAULT 0,\
        KEY `PlayerID` (`PlayerID`),\
        KEY `QuestID` (`QuestID`)\
        )");
    
    mysql_tquery(g_SQL, query);
    
    // Таблица работ
    mysql_format(g_SQL, query, sizeof(query),
        "CREATE TABLE IF NOT EXISTS `jobs` (\
        `ID` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,\
        `JobName` VARCHAR(32) NOT NULL,\
        `JobType` INT DEFAULT 0,\
        `Description` VARCHAR(256),\
        `MinLevel` INT DEFAULT 1,\
        `BaseSalary` INT DEFAULT 500,\
        `SalaryPerTask` INT DEFAULT 100,\
        `IsActive` BOOLEAN DEFAULT TRUE,\
        `CreatedAt` TIMESTAMP DEFAULT CURRENT_TIMESTAMP\
        )");
    
    mysql_tquery(g_SQL, query);
    
    // Таблица банковских счетов
    mysql_format(g_SQL, query, sizeof(query),
        "CREATE TABLE IF NOT EXISTS `bank_accounts` (\
        `ID` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,\
        `PlayerID` INT NOT NULL,\
        `Balance` INT DEFAULT 0,\
        `CreatedAt` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,\
        `IsActive` BOOLEAN DEFAULT TRUE,\
        UNIQUE KEY `PlayerID` (`PlayerID`)\
        )");
    
    mysql_tquery(g_SQL, query);
    
    // Таблица транзакций
    mysql_format(g_SQL, query, sizeof(query),
        "CREATE TABLE IF NOT EXISTS `transactions` (\
        `ID` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,\
        `FromAccount` INT,\
        `ToAccount` INT,\
        `Amount` INT DEFAULT 0,\
        `TransactionType` VARCHAR(32),\
        `Description` VARCHAR(128),\
        `CreatedAt` TIMESTAMP DEFAULT CURRENT_TIMESTAMP\
        )");
    
    mysql_tquery(g_SQL, query);
    
    print("[DATABASE] Таблицы успешно созданы!");
}

// ============ ФУНКЦИИ ЗАПРОСОВ ============

stock DB_IsConnected() {
    return g_DBConnected;
}

stock DB_Escape(const source[], dest[], maxlength = sizeof dest) {
    mysql_escape_string(source, dest, g_SQL, maxlength);
}

stock DB_QueryFormat(query[], const format[], {Float,_}:...) {
    return mysql_format(g_SQL, query, sizeof(query), format, ___(2));
}

stock DB_Query(const query[]) {
    return mysql_query(g_SQL, query, true);
}

stock DB_TQuery(const query[], const callback[] = "", const format[] = "", {Float,_}:...) {
    return mysql_tquery(g_SQL, query, callback, format, ___(3));
}

stock DB_GetQueryErrorID() {
    return mysql_errno();
}

stock DB_GetQueryError(error[], maxlength = sizeof error) {
    mysql_error(error, g_SQL, maxlength);
}

// ============ HELPER ФУНКЦИИ ============

stock DB_InsertPlayer(const name[], const password[]) {
    new query[512], escaped_pass[256];
    
    DB_Escape(password, escaped_pass);
    
    mysql_format(g_SQL, query, sizeof(query),
        "INSERT INTO `players` (`Name`, `Password`) VALUES ('%s', SHA2('%s', 256))",
        name, escaped_pass);
    
    return mysql_query(g_SQL, query, true);
}

stock DB_GetPlayerID(const name[]) {
    new query[256];
    mysql_format(g_SQL, query, sizeof(query), "SELECT `ID` FROM `players` WHERE `Name` = '%s'", name);
    
    new result;
    if(mysql_query(g_SQL, query, true)) {
        if(mysql_num_rows(g_SQL) > 0) {
            mysql_fetch_row_format(query);
            result = strval(query);
        }
    }
    
    return result;
}

stock DB_PlayerExists(const name[]) {
    new query[256];
    mysql_format(g_SQL, query, sizeof(query), "SELECT `ID` FROM `players` WHERE `Name` = '%s'", name);
    
    mysql_query(g_SQL, query, true);
    return (mysql_num_rows(g_SQL) > 0);
}

stock DB_VerifyPassword(const name[], const password[]) {
    new query[512], escaped_pass[256];
    
    DB_Escape(password, escaped_pass);
    
    mysql_format(g_SQL, query, sizeof(query),
        "SELECT `ID` FROM `players` WHERE `Name` = '%s' AND `Password` = SHA2('%s', 256)",
        name, escaped_pass);
    
    mysql_query(g_SQL, query, true);
    return (mysql_num_rows(g_SQL) > 0);
}

stock DB_UpdatePlayerData(playerid, const fieldname[], const value[]) {
    new query[512];
    
    mysql_format(g_SQL, query, sizeof(query),
        "UPDATE `players` SET `%s` = '%s' WHERE `ID` = %d",
        fieldname, value, playerid);
    
    return mysql_query(g_SQL, query, true);
}

stock DB_UpdatePlayerMoney(playerid, money) {
    new query[256];
    
    mysql_format(g_SQL, query, sizeof(query),
        "UPDATE `players` SET `Money` = %d WHERE `ID` = %d",
        money, playerid);
    
    return mysql_query(g_SQL, query, true);
}

stock DB_UpdatePlayerBank(playerid, bankmoney) {
    new query[256];
    
    mysql_format(g_SQL, query, sizeof(query),
        "UPDATE `players` SET `BankMoney` = %d WHERE `ID` = %d",
        bankmoney, playerid);
    
    return mysql_query(g_SQL, query, true);
}
