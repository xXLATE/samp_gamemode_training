/*------------------------------------------------------------------------------
							   Разработчик - xlate
----------------------------------=[ Инклюды ]=-------------------------------*/

#include <a_samp>
#include <sscanf2>
#include <Pawn.CMD>
#include <foreach>
#include <a_mysql>
#include <MD5>
// #include <streamer>

/*------------------------------=[ Данные MySQL ]=----------------------------*/

#define MYSQL_HOST      "localhost"		// Адрес, по которому расположен MySQL-Сервер
#define MYSQL_USER      "root"			// Имя пользователя, на которого была создана база данных
#define MYSQL_DATABASE  "training_samp"	// Имя базы данных
#define MYSQL_PASSWORD  "root"			// Пароль для доступа к серверу MySQL

/*-------------------------------=[ Переменные ]=-----------------------------*/

new MySQL:mySql;

new IsPlayerAuth[MAX_PLAYERS char];
new ChangePlayerColorCooldown[MAX_PLAYERS];
new MoneyPickups[MAX_PICKUPS];
new SpeedForPenaltyTimers[MAX_PLAYERS];

/*--------------------------------=[ Enum's ]=--------------------------------*/

enum e_dialogId
{
	D_KICK,
    D_LOGIN,
	D_REGISTER
};

enum e_pInfo
{
	id,
	name[MAX_PLAYER_NAME],
	password_hash[50]
};
new pInfo[MAX_PLAYERS][e_pInfo];

/*--------------------------------=[ Прочее ]=--------------------------------*/

main()
{
	print("\n----------------------------------");
	print("        READY XLATE MODE            ");
	print("----------------------------------\n");
}

/*-------------------------------=[ Public's ]=-------------------------------*/

public OnGameModeInit()
{
	SetGameModeText("xlate mode");
	SetTimer("DisplayPlayersCount", 30000, true);
	ConnectToDB();
	return 1;
}

public OnGameModeExit()
{
	mysql_close(mySql);
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	return 1;
}

public OnPlayerConnect(playerid)
{
	TogglePlayerSpectating(playerid, true);	
    GetPlayerName(playerid, pInfo[playerid][name], MAX_PLAYER_NAME);
	CheckPlayerExists(playerid);
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	return 1;
}

public OnPlayerSpawn(playerid)
{
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	return 1;
}

public OnVehicleSpawn(vehicleid)
{
	return 1;
}

public OnVehicleDeath(vehicleid, killerid)
{
	return 1;
}

public OnPlayerText(playerid, text[])
{
    if(!IsPlayerAuth{playerid})
    {
    	SendClientMessage(playerid, -1, "Вы не авторизировались и не можете писать в чат!");
    	return 0;
	}

    return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
	if(!IsPlayerAuth{playerid})
		return SendClientMessage(playerid, -1, "Вы не авторизировались и не можете использовать команды!");
		
    return 0;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	return 1;
}

public OnPlayerEnterCheckpoint(playerid)
{
	return 1;
}

public OnPlayerLeaveCheckpoint(playerid)
{
	return 1;
}

public OnPlayerEnterRaceCheckpoint(playerid)
{
	return 1;
}

public OnPlayerLeaveRaceCheckpoint(playerid)
{
	return 1;
}

public OnRconCommand(cmd[])
{
	return 1;
}

public OnPlayerRequestSpawn(playerid)
{
	return 1;
}

public OnObjectMoved(objectid)
{
	return 1;
}

public OnPlayerObjectMoved(playerid, objectid)
{
	return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid)
{
	CheckMoneyPickup(playerid, pickupid);
	return 1;
}

public OnVehicleMod(playerid, vehicleid, componentid)
{
	return 1;
}

public OnVehiclePaintjob(playerid, vehicleid, paintjobid)
{
	return 1;
}

public OnVehicleRespray(playerid, vehicleid, color1, color2)
{
	return 1;
}

public OnPlayerSelectedMenuRow(playerid, row)
{
	return 1;
}

public OnPlayerExitedMenu(playerid)
{
	return 1;
}

public OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid)
{
	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	return 1;
}

public OnRconLoginAttempt(ip[], password[], success)
{
	return 1;
}

public OnPlayerUpdate(playerid)
{
	CheckSpeedForPenalty(playerid);
	return 1;
}

public OnPlayerStreamIn(playerid, forplayerid)
{
	return 1;
}

public OnPlayerStreamOut(playerid, forplayerid)
{
	return 1;
}

public OnVehicleStreamIn(vehicleid, forplayerid)
{
	return 1;
}

public OnVehicleStreamOut(vehicleid, forplayerid)
{
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch (dialogid)
	{
		case D_REGISTER:
		{
			if (!response)
			{
				ShowKickDialog(playerid, "Отказ от авторизации.");
				return 1;
			}
			RegisterPlayer(playerid, inputtext);
			return 1;
		}
		case D_LOGIN:
		{
			if (!response)
			{
				ShowKickDialog(playerid, "Отказ от авторизации.");
				return 1;
			}
			LoginPlayer(playerid, inputtext);
			return 1;
		}
	}
	return 1;
}

stock ShowKickDialog(playerid, reason[])
{
    new dialogText[256];
    format(dialogText, sizeof(dialogText), "{FFFFFF}Вы были кикнуты с сервера.\n{FF0000}Причина: %s\n{FFFFFF}Для выхода с сервера введите \"/q\" в чат", reason);

    ShowPlayerDialog(playerid, D_KICK, DIALOG_STYLE_MSGBOX, "Оповещение", dialogText, "Выход", "");
    SetTimerEx("KickWithDelay", 1000, false, "%i", playerid);
}

forward KickWithDelay(playerid);
public KickWithDelay(playerid){
	Kick(playerid);
}

public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
	return 1;
}

// ----------------------------------------
// ----------------------------------------
// ----------------------------------------

stock ConnectToDB()
{
	mySql = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE);
	new errno = mysql_errno(mySql);
	
	if (errno == 0)
		print("[DB] Successful connection to database!");
	else
	{
		new error[100];	
		mysql_error(error, sizeof(error), mySql);
		printf("[ERROR] #%d '%s'", errno, error);
	}
}

stock CheckPlayerExists(playerid)
{
    new query[128];
    mysql_format(mySql, query, sizeof(query), "SELECT * FROM players WHERE name = '%s'", pInfo[playerid][name]);
	mysql_tquery(mySql, query, "OnCheckPlayerExistsFromDB", "i", playerid);
}

forward OnCheckPlayerExistsFromDB(playerid);
public OnCheckPlayerExistsFromDB(playerid)
{
	if (cache_num_rows() > 0)
	{
		ShowPlayerDialog(playerid, D_LOGIN, DIALOG_STYLE_INPUT, "Авторизация", "Введите пароль для входа:", "Войти", "Отмена");
		cache_get_value_name_int(0, "id", pInfo[playerid][id]);
		cache_get_value_name(0, "password_hash", pInfo[playerid][password_hash]);
	}
    else
        ShowPlayerDialog(playerid, D_REGISTER, DIALOG_STYLE_INPUT, "Регистрация", "Введите пароль для регистрации:", "Регистрация", "Отмена");

	SetTimerEx("SetCameraToAuthPos", 1000, false, "%i", playerid);
}

forward SetCameraToAuthPos(playerid);
public SetCameraToAuthPos(playerid)
{
	SetPlayerPos(playerid, 1958.3783, 1343.1572, 15.3746);
	SetPlayerCameraPos(playerid, 1958.3783, 1343.1572, 15.3746);
	SetPlayerCameraLookAt(playerid, 1958.3783, 1343.1572, 15.3746);
}

stock RegisterPlayer(playerid, password[])
{
	if(!strlen(password))
		return ShowPlayerDialog(playerid, D_REGISTER, DIALOG_STYLE_INPUT, "Регистрация нового пользователя", "{FF0000}Ошибка: {FFFFFF}Вы не можете продолжить регистрацию не введя пароль!\nВведите пароль для регистрации нового аккаунта:\n{C0C0C0}Примечание:\n{666666}- Пароль чувствителен к регистру.\n- Пароль должен содержать от 4 до 30 символов.\n- Пароль может содержать латинские/кириллические символы и цифры (aA-zZ, аА-яЯ, 0-9).", "Регистрация", "Выход");
	else if(strlen(password) < 4)
		return ShowPlayerDialog(playerid, D_REGISTER, DIALOG_STYLE_INPUT, "Регистрация нового пользователя", "{FF0000}Ошибка: {FFFFFF}Пароль слишком короткий!\nВведите пароль для регистрации нового аккаунта:\n{C0C0C0}Примечание:\n{666666}- Пароль чувствителен к регистру.\n- Пароль должен содержать от 4 до 30 символов.\n- Пароль может содержать латинские/кириллические символы и цифры (aA-zZ, аА-яЯ, 0-9).", "Регистрация", "Выход");
	else if(strlen(password) > 30)
		return ShowPlayerDialog(playerid, D_REGISTER, DIALOG_STYLE_INPUT, "Регистрация нового пользователя", "{FF0000}Ошибка: {FFFFFF}Пароль слишком длинный!\nВведите пароль для регистрации нового аккаунта:\n{C0C0C0}Примечание:\n{666666}- Пароль чувствителен к регистру.\n- Пароль должен содержать от 4 до 30 символов.\n- Пароль может содержать латинские/кириллические символы и цифры (aA-zZ, аА-яЯ, 0-9).", "Регистрация", "Выход");
	for(new i = strlen(password)-1; i != -1; i--)
	{
		switch(password[i])
		{
			case '0'..'9', 'а'..'я', 'a'..'z', 'А'..'Я', 'A'..'Z':
				continue;
			default:
				return ShowPlayerDialog(playerid, D_REGISTER, DIALOG_STYLE_INPUT, "Регистрация нового пользователя", "{FF0000}Ошибка: {FFFFFF}Пароль содержит запрещённые символы!\nВведите пароль для регистрации нового аккаунта:\n{C0C0C0}Примечание:\n{666666}- Пароль чувствителен к регистру.\n- Пароль должен содержать от 4 до 30 символов.\n- Пароль может содержать латинские/кириллические символы и цифры (aA-zZ, аА-яЯ, 0-9).", "Регистрация", "Выход");
		}
	}

	pInfo[playerid][password_hash][0] = EOS;
	strins(pInfo[playerid][password_hash], password, 0);

    new query_string[66+MAX_PLAYER_NAME-4+30+1];
    mysql_format(mySql, query_string, sizeof(query_string), "INSERT INTO `players` (`name`, `password_hash`) VALUES ('%s', '%s')", pInfo[playerid][name], pInfo[playerid][password_hash]);
    mysql_tquery(mySql, query_string, "UploadPlayerAccountNumber", "i", playerid);

    format(query_string, sizeof(query_string), "Аккаунт %s успешно зарегистрирован. Желаем Вам приятной игры!", pInfo[playerid][name]);
    SendClientMessage(playerid, 0xFFFFFF00, query_string);
    Spawn(playerid);
    return 1;
}

forward UploadPlayerAccountNumber(playerid);
public UploadPlayerAccountNumber(playerid) pInfo[playerid][id] = cache_insert_id();

stock LoginPlayer(playerid, password[])
{
	if(!strlen(password))
		return ShowPlayerDialog(playerid, D_LOGIN, DIALOG_STYLE_INPUT, "Авторизация", "{FF0000}Ошибка: {FFFFFF}Вы не можете продолжить авторизацию не введя пароль!\nВведите пароль от аккаунта для входа на сервер:", "Вход", "Выход");
	
	for(new i = strlen(password)-1; i != -1; i--)
	{
		switch(password[i])
		{
			case '0'..'9', 'а'..'я', 'a'..'z', 'А'..'Я', 'A'..'Z':
				continue;
			default:
				return ShowPlayerDialog(playerid, D_LOGIN, DIALOG_STYLE_INPUT, "Авторизация", "{FF0000}Ошибка: {FFFFFF}Введённый пароль содержит запрещённые символы!\nВведите пароль от аккаунта для входа на сервер:", "Вход", "Выход");
		}
	}

	if(!strcmp(pInfo[playerid][password_hash], password))
		Spawn(playerid);		
	else
	{
		switch(GetPVarInt(playerid, "WrongPassword"))
		{
			case 0:
				ShowPlayerDialog(playerid, D_LOGIN, DIALOG_STYLE_INPUT, "Авторизация", "{FF0000}Ошибка: {FFFFFF}Вы ввели неверный пароль! У Вас осталось 3 попытки.\nВведите пароль от аккаунта для входа на сервер:", "Вход", "Выход");
			case 1:
				ShowPlayerDialog(playerid, D_LOGIN, DIALOG_STYLE_INPUT, "Авторизация", "{FF0000}Ошибка: {FFFFFF}Вы ввели неверный пароль! У Вас осталось 2 попытки.\nВведите пароль от аккаунта для входа на сервер:", "Вход", "Выход");
			case 2:
				ShowPlayerDialog(playerid, D_LOGIN, DIALOG_STYLE_INPUT, "Авторизация", "{FF0000}Ошибка: {FFFFFF}Вы ввели неверный пароль! У Вас осталось 1 попытка.\nВведите пароль от аккаунта для входа на сервер:", "Вход", "Выход");
			case 3:
				ShowPlayerDialog(playerid, D_LOGIN, DIALOG_STYLE_INPUT, "Авторизация", "{FF0000}Ошибка: {FFFFFF}Вы ввели неверный пароль! У Вас осталась последняя попытка, после чего Вас кикнет.\nВведите пароль от аккаунта для входа на сервер:", "Вход", "Выход");
			default:
			{
				ShowPlayerDialog(playerid, D_KICK, DIALOG_STYLE_MSGBOX, "Оповещение", "{FFFFFF}Вы были кикнуты с сервера.\n{FF0000}Причина: Превышен лимит попыток на ввод пароля.\n{FFFFFF}Для выхода с сервера введите \"/q\" в чат", "Выход", "");
				SetTimerEx("KickWithDelay", 1000, false, "%i", playerid);
				return 1;
			}
		}
		SetPVarInt(playerid, "WrongPassword", GetPVarInt(playerid, "WrongPassword") + 1);
	}
	return 1;
}

forward Spawn(playerid);
public Spawn(playerid)
{
	IsPlayerAuth{playerid} = 1;
	GreetingPlayers(playerid);
	AddPlayerClass(0, 2070.6699, 1258.7913, 10.6719, 179.2384, 24, 100, 0, 0, 0, 0);
	TogglePlayerSpectating(playerid, false);
    return 1;
}

stock GreetingPlayers(playerid)
{
    new hour;    
    gettime(hour);
    
    new greeting[128];    
    if (hour >= 5 && hour < 11)
        format(greeting, sizeof(greeting), "Добро пожаловать, %s! Доброе утро!", pInfo[playerid][name]);
    else if (hour >= 11 && hour < 17)
        format(greeting, sizeof(greeting), "Добро пожаловать, %s! Добрый день!", pInfo[playerid][name]);
	else if (hour >= 17 && hour < 23)
        format(greeting, sizeof(greeting), "Добро пожаловать, %s! Добрый вечер!", pInfo[playerid][name]);
    else
        format(greeting, sizeof(greeting), "Добро пожаловать, %s! Доброй ночи!", pInfo[playerid][name]);
    
    SendClientMessage(playerid, -1, greeting);
}

stock RemovePlayerInfo(playerid)
{
    pInfo[playerid][id] = 0;
    pInfo[playerid][name][0] = EOS;
    pInfo[playerid][password_hash][0] = EOS;
    IsPlayerAuth{playerid} = 0;
    return 1;
}

cmd:color(playerid)
{
	new currentTime = GetTickCount();

	if (currentTime - ChangePlayerColorCooldown[playerid] < 60000)
	{
		SendClientMessage(playerid, 0xFF0000FF, "Вы можете менять цвет только раз в минуту!");
		return 1;
	}

	new color = random(0xFFFFFF);
	SetPlayerColor(playerid, 0xFF000000 | color);
	ChangePlayerColorCooldown[playerid] = currentTime;
	SendClientMessage(playerid, 0x00FF00FF, "Ваш цвет был успешно изменён!");
	return 1;
}

cmd:heal(playerid)
{
	new Float:currentHp;
	GetPlayerHealth(playerid, currentHp);
	if (currentHp < 50)
	{
		SetPlayerHealth(playerid, 100);
		SendClientMessage(playerid, 0x00FF00FF, "Здоровье восстановлено");
	}
	else
		SendClientMessage(playerid, 0xFF0000FF, "Лечение недоступно");

	return 1;
}

cmd:sethp(playerid, params[])
{
    new targetid, healthValue;

    if (sscanf(params, "ii", targetid, healthValue)) 
    {
        SendClientMessage(playerid, -1, "Использование: /sethp [id] [value]");
        return 1;
    }

    if (!IsPlayerConnected(targetid)) 
    {
        SendClientMessage(playerid, -1, "Игрок с таким ID не подключен");
        return 1;
    }

    if (healthValue < 0 || healthValue > 100) 
    {
        SendClientMessage(playerid, -1, "Значение здоровья должно быть от 0 до 100");
        return 1;
    }

    SetPlayerHealth(targetid, float(healthValue));

    new string[128];
    format(string, sizeof(string), "Вы установили игроку %s[%d] %d единиц здоровья", pInfo[playerid][name], targetid, healthValue);
    SendClientMessage(playerid, -1, string);

    format(string, sizeof(string), "Ваше здоровье было установлено на %d единиц", healthValue);
    SendClientMessage(targetid, -1, string);

    return 1;
}

cmd:car(playerid, params[])
{
	new carid;
	if (sscanf(params, "i", carid)) 
    {
        SendClientMessage(playerid, -1, "Использование: /car [id]");
        return 1;
    }

	new Float:x, Float:y, Float:z;
	GetPlayerPos(playerid, x, y, z);

	new Float:checkRadius = 10.0;
	for (new i = 1; i < MAX_VEHICLES; i++)
	{
		if (IsVehicleStreamedIn(i, playerid))
		{
			if (GetVehicleDistanceFromPoint(i, x, y, z) <= checkRadius)
			{
				SendClientMessage(playerid, 0xFF0000FF, "Рядом уже есть транспортное средство!");
				return 1;
			}
		}
	}

	new Float:rotation;
	GetPlayerFacingAngle(playerid, rotation);
	new carColor = 0xFF000000 | random(0xFFFFFF);
	new vehicle = CreateVehicle(carid, x - 2, y, z, rotation, carColor, carColor, 60000);
	if (vehicle != INVALID_VEHICLE_ID)
		SendClientMessage(playerid, 0x00FF00FF, "Транспортное средство успешно создано");
	else
		SendClientMessage(playerid, 0xFF0000FF, "Ошибка при создании транспортного средства");

	return 1;
}

CMD:giveweapon(playerid, params[])
{
    new targetid, weaponid, ammo;

    if (sscanf(params, "iii", targetid, weaponid, ammo))
    {
        SendClientMessage(playerid, -1, "Использование: /giveweapon [player id] [weapon id] [count]");
        return 1;
    }

    if (!IsPlayerConnected(targetid))
    {
        SendClientMessage(playerid, -1, "Игрок с таким ID не подключен.");
        return 1;
    }

    if (weaponid < 0 || weaponid > 46)
    {
        SendClientMessage(playerid, -1, "Неверный идентификатор оружия. Используйте значение от 0 до 46.");
        return 1;
    }
    if (ammo <= 0)
    {
        SendClientMessage(playerid, -1, "Количество патронов должно быть больше 0.");
        return 1;
    }

    GivePlayerWeapon(targetid, weaponid, ammo);

    new string[128], weaponName[32];
	GetWeaponName(weaponid, weaponName, sizeof(weaponName));
    format(string, sizeof(string), "Вы выдали игроку %s[%d] оружие %s с %d патронами.", pInfo[playerid][name], targetid, weaponName, ammo);
    SendClientMessage(playerid, -1, string);

    format(string, sizeof(string), "Вам было выдано оружие %s с %d патронами.", weaponName, ammo);
    SendClientMessage(targetid, -1, string);

    return 1;
}

cmd:spawnactor(playerid, params[])
{
	new modelid;
	if (sscanf(params, "i", modelid)) 
    {
        SendClientMessage(playerid, -1, "Использование: /spawnactor [id]");
        return 1;
    }

	new Float:x, Float:y, Float:z, Float:rotation;
	GetPlayerPos(playerid, x, y, z);
	GetPlayerFacingAngle(playerid, rotation);
	new actorid = CreateActor(modelid, x - 1, y, z, rotation);
	SetActorInvulnerable(actorid, false);
	if (actorid != INVALID_ACTOR_ID)
		SendClientMessage(playerid, 0x00FF00FF, "Актер успешно создан");
	else
		SendClientMessage(playerid, 0xFF0000FF, "Ошибка при создании актера");

	return 1;
}

public OnPlayerGiveDamageActor(playerid, damaged_actorid, Float:amount, weaponid, bodypart)
{
	new Float:health, string[128];
	GetActorHealth(damaged_actorid, health);
	health -= amount;
	SetActorHealth(damaged_actorid, health);
	format(string, sizeof(string), "Здоровье актера: %f", health);
	SendClientMessage(playerid, -1, string);
}

forward DisplayPlayersCount();
public DisplayPlayersCount()
{
    new playerCount;
	foreach(new playerid : Player)
		playerCount++;
    
    new message[40];
    format(message, sizeof(message), "Количество игроков на сервере: %d", playerCount);
    SendClientMessageToAll(0xFFEE00AA, message);
    return 1;
}

cmd:tp(playerid, params[])
{
    if(IsPlayerInAnyVehicle(playerid))
    {
        SendClientMessage(playerid, 0xFF0000FF, "Вы не можете телепортироваться в транспортном средстве.");
        return 1;
    }

    new Float:x, Float:y, Float:z;

    if(sscanf(params, "fff", x, y, z))
    {
        SendClientMessage(playerid, -1, "Используйте: /tp [x] [y] [z]");
        return 1;
    }

    SetPlayerPos(playerid, x, y, z);
    SendClientMessage(playerid, 0x00FF00FF, "Вы были успешно телепортированы.");
    return 1;
}

cmd:moneypickup(playerid, params[])
{
	new Float:x, Float:y, Float:z;
	GetPlayerPos(playerid, x, y, z);

	new pickupid = CreatePickup(1212, 19, x + 2, y + 2, z);
	MoneyPickups[pickupid] = true;
	SendClientMessage(playerid, -1, "Вы создали денежный пикап. Через 30 секунд он изчезнет.");
	SetTimerEx("DeletePickup", 30000, false, "ii", playerid, pickupid);

	return 1;
}

forward DeletePickup(playerid, pickupid);
public DeletePickup(playerid, pickupid)
{
	if (!MoneyPickups[pickupid])
		return;

	MoneyPickups[pickupid] = false;
	DestroyPickup(pickupid);
	SendClientMessage(playerid, -1, "Ваш денежный пикап изчез.");

	return;
}

stock CheckMoneyPickup(playerid, pickupid)
{
	if (!MoneyPickups[pickupid])
		return;

	MoneyPickups[pickupid] = false;
	GivePlayerMoney(playerid, 1000);
	SendClientMessage(playerid, 0x00FF00FF, "Вы получили 1000$!");
}

stock CheckSpeedForPenalty(playerid)
{
	if (IsPlayerInAnyVehicle(playerid))
    {
        new vehicleid = GetPlayerVehicleID(playerid);
        new Float:velX, Float:velY, Float:velZ;
        
        GetVehicleVelocity(vehicleid, velX, velY, velZ);        
        new Float:speed = floatsqroot(velX * velX + velY * velY + velZ * velZ) * 200;

        if (speed > 150)
        {
            if (SpeedForPenaltyTimers[playerid] == 0)
            {
                SpeedForPenaltyTimers[playerid] = SetTimerEx("PenaltyForSpeed", 10000, false, "ii", playerid, vehicleid);
            }
        }
        else
        {
            if (SpeedForPenaltyTimers[playerid] != 0)
            {
                KillTimer(SpeedForPenaltyTimers[playerid]);
                SpeedForPenaltyTimers[playerid] = 0;
            }
        }
    }
}

forward PenaltyForSpeed(playerid, vehicleid);
public PenaltyForSpeed(playerid, vehicleid)
{
	DestroyVehicle(vehicleid);
	GivePlayerMoney(playerid, -500);
	SendClientMessage(playerid, 0xFF0000AA, "Вы превысили скорость 150 км/ч! Ваш транспорт уничтожен, штраф $500.");
	SpeedForPenaltyTimers[playerid] = 0;
}