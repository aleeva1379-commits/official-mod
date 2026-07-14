/*
 * Black Russia - Defines
 * Константы и дефайны
 */

#if defined _defines_inc_
    #endinput
#endif
#define _defines_inc_

// ============ КООРДИНАТЫ МОСКВЫ ============

// Красная площадь
#define RED_SQUARE_X 0.0
#define RED_SQUARE_Y 0.0
#define RED_SQUARE_Z 0.0

// Кремль
#define KREMLIN_X 100.0
#define KREMLIN_Y 100.0
#define KREMLIN_Z 0.0

// Арбат
#define ARBAT_X 200.0
#define ARBAT_Y 200.0
#define ARBAT_Z 0.0

// МВД
#define POLICE_HQ_X 300.0
#define POLICE_HQ_Y 300.0
#define POLICE_HQ_Z 0.0

// Военный архив
#define ARMY_HQ_X 400.0
#define ARMY_HQ_Y 400.0
#define ARMY_HQ_Z 0.0

// ============ ЦВЕТА ============

#define COLOR_POLICE 0x0087CEFF
#define COLOR_ARMY 0x228B22FF
#define COLOR_MAFIA 0xFF0000FF
#define COLOR_GANG 0xFFFF00FF
#define COLOR_CIVILIAN 0xFFFFFFFF
#define COLOR_ERROR 0xFF0000FF
#define COLOR_SUCCESS 0x00FF00FF
#define COLOR_INFO 0x00FFFFFF
#define COLOR_WARNING 0xFFFF00FF
#define COLOR_SYSTEM 0xFFFF00FF

// ============ ID ОБЪЕКТОВ ============

#define OBJECT_POLICE_STATION 1
#define OBJECT_BANK 2
#define OBJECT_SHOP_24_7 3
#define OBJECT_BAR 4
#define OBJECT_GARAGE 5
#define OBJECT_APARTMENT 6
#define OBJECT_BUSINESS 7

// ============ ТЕКСТОВЫЕ ПЕРЕМЕННЫЕ ============

#define POLICE_NAME "МВД - Полиция"
#define POLICE_LOGO "МВД"
#define POLICE_RANK_1 "Рядовой"
#define POLICE_RANK_2 "Сержант"
#define POLICE_RANK_3 "Лейтенант"
#define POLICE_RANK_4 "Капитан"
#define POLICE_RANK_5 "Майор"
#define POLICE_RANK_6 "Полковник"
#define POLICE_RANK_7 "Генерал"

#define ARMY_NAME "Армия России"
#define ARMY_LOGO "ВС РФ"
#define ARMY_RANK_1 "Боец"
#define ARMY_RANK_2 "Сержант"
#define ARMY_RANK_3 "Лейтенант"
#define ARMY_RANK_4 "Капитан"
#define ARMY_RANK_5 "Майор"
#define ARMY_RANK_6 "Полковник"
#define ARMY_RANK_7 "Генерал"

// ============ ЭКОНОМИЧЕСКИЕ ПАРАМЕТРЫ ============

#define STARTING_MONEY 1000
#define STARTING_BANK_MONEY 5000
#define TAX_RATE 0.1 // 10% налог
#define SALARY_MULTIPLIER 1.5
#define DEATH_MONEY_LOSS 0.1 // 10% потери денег при смерти
#define ARREST_MONEY_LOSS 0.2 // 20% потери денег при аресте

// ============ ВРЕМЯ ============

#define GAME_TIME_SCALE 1.0
#define WORK_START_HOUR 6
#define WORK_END_HOUR 22
#define BUSINESS_OPEN_HOUR 8
#define BUSINESS_CLOSE_HOUR 23

// ============ ДИСТАНЦИИ ============

#define INTERACTION_DISTANCE 5.0
#define BUSINESS_ENTER_DISTANCE 3.0
#define GARAGE_ENTER_DISTANCE 3.0
#define APARTMENT_ENTER_DISTANCE 3.0
#define NPC_TALK_DISTANCE 5.0

// ============ НАГРАДЫ ============

#define KILL_REWARD 1000
#define ARREST_REWARD 2000
#define MISSION_REWARD 5000
#define QUEST_REWARD 3000
#define DAILY_BONUS 500
#define LEVEL_UP_BONUS 1000

// ============ ОПЫТ ============

#define EXP_KILL 50
#define EXP_ARREST 100
#define EXP_MISSION 200
#define EXP_QUEST 150
#define EXP_LEVEL_UP 1000

// ============ СКИНЫ ============

#define SKIN_COP 280
#define SKIN_SOLDIER 287
#define SKIN_CIVILIAN 0
#define SKIN_BUSINESS 1
#define SKIN_GANG 102

// ============ ТРАНСПОРТ ============

#define VEHICLE_CAR 400 // Landstalker
#define VEHICLE_POLICE 598 // Police
#define VEHICLE_AMBULANCE 416 // Ambulance
#define VEHICLE_MILITARY 433 // Barracks
#define VEHICLE_BUS 431 // Bus
#define VEHICLE_TAXI 420 // Taxi

// ============ ИНТЕРЬЕРЫ ============

#define INTERIOR_BANK 0
#define INTERIOR_POLICE 0
#define INTERIOR_APARTMENT 1
#define INTERIOR_BUSINESS 0
#define INTERIOR_GARAGE 0

// ============ СООБЩЕНИЯ ============

#define MSG_WELCOME "Добро пожаловать на сервер Black Russia!"
#define MSG_GOODBYE "До встречи на сервере Black Russia!"
#define MSG_ADMIN_ONLY "[ADMIN] Эта команда только для администраторов!"
#define MSG_NOT_AUTHORIZED "[ERROR] Вы не авторизованы!"
#define MSG_NOT_ENOUGH_MONEY "[ERROR] Недостаточно денег!"
#define MSG_INVALID_ARGS "[ERROR] Неправильные аргументы команды!"

// ============ МАКСИМУМЫ ============

#define MAX_FRIENDS 50
#define MAX_IGNORE 20
#define MAX_REPORTS 10
#define MAX_INVENTORY_ITEMS 20
#define MAX_HOUSE_FURNITURE 50
#define MAX_FACTION_MEMBERS 100
#define MAX_BAN_REASON_LENGTH 128
#define MAX_NAME_LENGTH 24
#define MAX_QUEST_OBJECTIVES 10
