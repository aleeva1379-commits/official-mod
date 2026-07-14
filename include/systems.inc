/*
 * Black Russia - Systems Include
 * Структуры систем игры
 */

#if defined _systems_inc_
    #endinput
#endif
#define _systems_inc_

// ============ СИСТЕМА ФРАКЦИЙ ============

enum FactionRankData {
    RankID,
    RankName[32],
    RankSalary,
    RankPermissions,
    RankLevel
};

// ============ СИСТЕМА ЭКОНОМИКИ ============

enum BankAccountData {
    AccountID,
    AccountOwner,
    AccountBalance,
    CreatedAt,
    bool:IsActive,
    PinCode[4]
};

enum TransactionData {
    TransactionID,
    FromAccount,
    ToAccount,
    Amount,
    TransactionTime,
    TransactionType[32],
    TransactionDescription[128]
};

// ============ СИСТЕМА БИЗНЕСА ============

enum BusinessInventoryData {
    ItemID,
    ItemName[32],
    ItemQuantity,
    ItemPrice,
    ItemType,
    ExpiryDate
};

enum BusinessEmployeeData {
    EmployeeID,
    EmployeeName[24],
    EmployeeRank,
    Salary,
    HiredDate,
    bool:IsActive
};

// ============ СИСТЕМА ТРАНСПОРТА ============

enum VehicleModData {
    ModID,
    ModType,
    ModPart,
    ModPrice,
    ModPerformance // 0-100
};

enum VehicleFuelData {
    VehicleID,
    CurrentFuel,
    FuelCapacity,
    FuelConsumption,
    LastRefuel
};

// ============ СИСТЕМА ЖИЛЬЯ ============

enum ApartmentFurnitureData {
    FurnitureID,
    FurnitureName[32],
    FurnitureType,
    FurniturePrice,
    FurnitureX,
    FurnitureY,
    FurnitureZ,
    FurnitureRotation
};

// ============ СИСТЕМА КВЕСТОВ ============

enum QuestObjectiveData {
    ObjectiveID,
    ObjectiveDescription[256],
    ObjectiveLocation[32],
    Float:ObjectiveX,
    Float:ObjectiveY,
    Float:ObjectiveZ,
    bool:IsCompleted,
    CompletedTime,
    Progress
};

enum QuestRewardData {
    RewardID,
    RewardType, // 0 = Money, 1 = Item, 2 = Exp, 3 = Faction Points
    RewardAmount,
    RewardDescription[128]
};

// ============ СИСТЕМА РАБОТ ============

enum JobData {
    JobID,
    JobName[32],
    JobType,
    JobDescription[256],
    MinLevel,
    BaseSalary,
    SalaryPerTask,
    bool:IsActive,
    CreatedAt
};

enum JobTaskData {
    TaskID,
    TaskName[32],
    TaskDescription[256],
    TaskType,
    Float:TaskStartX,
    Float:TaskStartY,
    Float:TaskStartZ,
    Float:TaskEndX,
    Float:TaskEndY,
    Float:TaskEndZ,
    TaskReward,
    TaskTime
};

// ============ СИСТЕМА ТЕЛЕФОНА ============

enum PhoneContactData {
    ContactID,
    ContactName[24],
    ContactNumber[16],
    ContactType, // 0 = Friend, 1 = Business, 2 = Service
    AddedDate
};

enum PhoneMessageData {
    MessageID,
    FromNumber[16],
    ToNumber[16],
    MessageText[128],
    MessageTime,
    bool:IsRead
};

// ============ СИСТЕМА НАРУШЕНИЙ ============

enum WantedLevelData {
    WantedID,
    PlayerID,
    Reason[256],
    WantedLevel,
    CreatedAt,
    ExpiryTime,
    IsActive
};

enum ArrestData {
    ArrestID,
    ArrestedPlayer,
    ArrestingOfficer,
    ArrestReason[256],
    ArrestTime,
    BailPrice,
    SentenceTime
};

// ============ СИСТЕМА БОЕПРИПАСОВ И ОРУЖИЯ ============

enum WeaponData {
    WeaponID,
    WeaponName[32],
    WeaponModel,
    WeaponType, // 0 = Melee, 1 = Pistol, 2 = Rifle, 3 = Shotgun
    WeaponPrice,
    WeaponAmmo,
    WeaponLicense,
    LegalUse
};

enum AmmoData {
    AmmoID,
    AmmoType,
    AmmoPrice,
    AmmoQuantity,
    AmmoExpiry
};

// ============ СИСТЕМА МАГАЗИНОВ ============

enum ShopInventoryData {
    ShopID,
    ItemID,
    ItemName[32],
    ItemQuantity,
    ItemPrice,
    ItemExpiry,
    bool:IsAvailable
};

enum ShopEmployeeData {
    EmployeeID,
    ShopID,
    EmployeeName[24],
    EmployeeRank,
    Salary,
    HiredDate,
    ShiftStart,
    ShiftEnd
};

// ============ СИСТЕМА МАРКЕРОВ ============

enum MarkerData {
    MarkerID,
    MarkerType, // 0 = Business, 1 = Apartment, 2 = Garage, 3 = Quest, 4 = NPC
    MarkerName[32],
    Float:MarkerX,
    Float:MarkerY,
    Float:MarkerZ,
    MarkerInterior,
    MarkerVirtualWorld,
    MarkerColor,
    LinkedID // ID связанного объекта (бизнес, квартира и т.д.)
};

// ============ ФУНКЦИИ СИСТЕМ ============

stock CreateMarker(type, const name[], Float:x, Float:y, Float:z, interior, virtualworld, color, linkedid) {
    // Создание маркера
    return 1;
}

stock DeleteMarker(markerid) {
    // Удаление маркера
    return 1;
}

stock UpdateMarkerPosition(markerid, Float:x, Float:y, Float:z) {
    // Обновление позиции маркера
    return 1;
}

stock GetNearbyMarkers(playerid, Float:distance) {
    // Получение ближайших маркеров
    return 1;
}
