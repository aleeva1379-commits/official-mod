/*
 * Black Russia - Authentication System
 * Система входа и регистрации
 */

#include <a_samp>
#include <zcmd>
#include <sscanf2>

new PlayerInfo[MAX_PLAYERS][PlayerData];
new bool:IsPlayerLogged[MAX_PLAYERS] = false;
new PlayerDatabaseID[MAX_PLAYERS] = -1;
new LoginAttempts[MAX_PLAYERS] = 0;

// ============ ДИАЛОГИ ============

#define DIALOG_LOGIN 1
#define DIALOG_REGISTER 2
#define DIALOG_REGISTER_PASSWORD 3
#define DIALOG_REGISTER_PASSWORD_CONFIRM 4

// ============ CALLBACKS ============

public OnPlayerConnect(playerid) {
    LoginAttempts[playerid] = 0;
    IsPlayerLogged[playerid] = false;
    PlayerDatabaseID[playerid] = -1;
    
    new playerName[24];
    GetPlayerName(playerid, playerName, sizeof(playerName));
    
    new string[256];
    format(string, sizeof(string), "[SERVER] Игрок %s подключился", playerName);
    SendClientMessageToAll(0x00FF00FF, string);
    
    // Показываем диалог входа
    ShowLoginDialog(playerid);
    
    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[]) {
    switch(dialogid) {
        case DIALOG_LOGIN: {
            if(!response) {
                Kick(playerid);
                return 1;
            }
            
            if(sscanf(inputtext, "s[24]s[24]", PlayerInfo[playerid][FirstName], PlayerInfo[playerid][LastName])) {
                SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Используйте: /login [пароль]");
                ShowLoginDialog(playerid);
                return 1;
            }
            
            // Проверяем пароль в БД
            if(DB_VerifyPassword(PlayerInfo[playerid][FirstName], PlayerInfo[playerid][LastName])) {
                PlayerDatabaseID[playerid] = DB_GetPlayerID(PlayerInfo[playerid][FirstName]);
                IsPlayerLogged[playerid] = true;
                LoginAttempts[playerid] = 0;
                
                // Загружаем данные игрока из БД
                LoadPlayerDataFromDB(playerid);
                
                new string[256];
                format(string, sizeof(string), "[SUCCESS] Добро пожаловать, %s!", PlayerInfo[playerid][FirstName]);
                SendClientMessage(playerid, 0x00FF00FF, string);
                
                // Спавним игрока
                SpawnPlayer(playerid);
            } else {
                LoginAttempts[playerid]++;
                
                if(LoginAttempts[playerid] >= 3) {
                    SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Вы превысили количество попыток входа!");
                    Kick(playerid);
                    return 1;
                }
                
                new string[256];
                format(string, sizeof(string), "[ERROR] Неправильный пароль! Попыток осталось: %d", 3 - LoginAttempts[playerid]);
                SendClientMessage(playerid, 0xFF0000FF, string);
                
                ShowLoginDialog(playerid);
            }
        }
        
        case DIALOG_REGISTER: {
            if(!response) {
                Kick(playerid);
                return 1;
            }
            
            new playerName[24];
            GetPlayerName(playerid, playerName, sizeof(playerName));
            
            if(DB_PlayerExists(playerName)) {
                SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Это имя уже занято!");
                ShowLoginDialog(playerid);
                return 1;
            }
            
            // Показываем диалог для ввода пароля
            ShowDialog(playerid, DIALOG_REGISTER_PASSWORD, "Регистрация", "Введите пароль (минимум 6 символов):", "Далее", "Отмена");
        }
        
        case DIALOG_REGISTER_PASSWORD: {
            if(!response) {
                ShowLoginDialog(playerid);
                return 1;
            }
            
            if(strlen(inputtext) < 6) {
                SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Пароль должен быть минимум 6 символов!");
                ShowDialog(playerid, DIALOG_REGISTER_PASSWORD, "Регистрация", "Введите пароль (минимум 6 символов):", "Далее", "Отмена");
                return 1;
            }
            
            // Сохраняем пароль
            strcpy(PlayerInfo[playerid][FirstName], inputtext, 24);
            
            // Показываем диалог подтверждения пароля
            ShowDialog(playerid, DIALOG_REGISTER_PASSWORD_CONFIRM, "Регистрация", "Подтвердите пароль:", "Готово", "Отмена");
        }
        
        case DIALOG_REGISTER_PASSWORD_CONFIRM: {
            if(!response) {
                ShowLoginDialog(playerid);
                return 1;
            }
            
            if(!strcmp(inputtext, PlayerInfo[playerid][FirstName], false)) {
                new playerName[24];
                GetPlayerName(playerid, playerName, sizeof(playerName));
                
                // Вставляем игрока в БД
                if(DB_InsertPlayer(playerName, inputtext)) {
                    PlayerDatabaseID[playerid] = DB_GetPlayerID(playerName);
                    IsPlayerLogged[playerid] = true;
                    
                    // Инициализируем данные нового игрока
                    InitNewPlayerData(playerid);
                    
                    new string[256];
                    format(string, sizeof(string), "[SUCCESS] Добро пожаловать, %s! Вы успешно зарегистрировались!", playerName);
                    SendClientMessage(playerid, 0x00FF00FF, string);
                    
                    // Спавним игрока
                    SpawnPlayer(playerid);
                } else {
                    SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Ошибка при создании аккаунта!");
                    ShowLoginDialog(playerid);
                }
            } else {
                SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Пароли не совпадают!");
                ShowDialog(playerid, DIALOG_REGISTER_PASSWORD, "Регистрация", "Введите пароль (минимум 6 символов):", "Далее", "Отмена");
            }
        }
    }
    
    return 1;
}

// ============ ДИАЛОГОВЫЕ ФУНКЦИИ ============

stock ShowLoginDialog(playerid) {
    new string[512];
    
    strcat(string, "Добро пожаловать на сервер Black Russia!\n\n");
    strcat(string, "Введите ваш пароль или зарегистрируйтесь\n\n");
    strcat(string, "Кнопка 1: Войти с существующим паролем\n");
    strcat(string, "Кнопка 2: Создать новый аккаунт\n");
    
    ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_INPUT, 
        "Black Russia - Вход", string, "Войти", "Регистрация");
}

stock ShowDialog(playerid, dialogid, const title[], const content[], const button1[], const button2[]) {
    ShowPlayerDialog(playerid, dialogid, DIALOG_STYLE_INPUT, title, content, button1, button2);
}

// ============ ДАННЫЕ ИГРОКА ============

stock InitNewPlayerData(playerid) {
    // Инициализируем данные нового игрока
    PlayerInfo[playerid][Money] = STARTING_MONEY;
    PlayerInfo[playerid][BankMoney] = STARTING_BANK_MONEY;
    PlayerInfo[playerid][Level] = 1;
    PlayerInfo[playerid][Experience] = 0;
    PlayerInfo[playerid][Skin] = 0;
    PlayerInfo[playerid][Faction] = FACTION_NONE;
    PlayerInfo[playerid][Rank] = 0;
    PlayerInfo[playerid][House] = -1;
    PlayerInfo[playerid][Apartment] = -1;
    PlayerInfo[playerid][PlayedHours] = 0;
    PlayerInfo[playerid][KillsCount] = 0;
    PlayerInfo[playerid][DeathsCount] = 0;
    PlayerInfo[playerid][Warnings] = 0;
}

stock LoadPlayerDataFromDB(playerid) {
    // TODO: Загружаем данные игрока из БД по PlayerDatabaseID[playerid]
    InitNewPlayerData(playerid);
}

stock SavePlayerDataToDB(playerid) {
    if(!IsPlayerLogged[playerid]) return 0;
    
    new query[512];
    
    mysql_format(g_SQL, query, sizeof(query),
        "UPDATE `players` SET `Money` = %d, `BankMoney` = %d, `Level` = %d, `Experience` = %d WHERE `ID` = %d",
        PlayerInfo[playerid][Money], PlayerInfo[playerid][BankMoney], 
        PlayerInfo[playerid][Level], PlayerInfo[playerid][Experience],
        PlayerDatabaseID[playerid]);
    
    mysql_query(g_SQL, query, true);
    
    return 1;
}

// ============ КОМАНДЫ ============

CMD:login(playerid, params[]) {
    if(IsPlayerLogged[playerid]) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Вы уже вошли в систему!");
        return 1;
    }
    
    if(sscanf(params, "s[24]", params)) {
        SendClientMessage(playerid, 0xFFFFFFFF, "Используйте: /login [пароль]");
        return 1;
    }
    
    ShowLoginDialog(playerid);
    return 1;
}

CMD:register(playerid, params[]) {
    if(IsPlayerLogged[playerid]) {
        SendClientMessage(playerid, 0xFF0000FF, "[ERROR] Вы уже зарегистрированы!");
        return 1;
    }
    
    ShowDialog(playerid, DIALOG_REGISTER_PASSWORD, "Регистрация", 
        "Введите пароль (минимум 6 символов):", "Далее", "Отмена");
    
    return 1;
}

// ============ HELPER ФУНКЦИИ ============

stock strcpy(dest[], const source[], maxlength = sizeof dest) {
    strmid(dest, source, 0, strlen(source), maxlength);
}

stock GetPlayerDatabaseID(playerid) {
    return PlayerDatabaseID[playerid];
}

stock IsPlayerAuthenticated(playerid) {
    return IsPlayerLogged[playerid];
}
