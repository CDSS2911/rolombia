local allowedGroupIDs =
{
	[1] = "Duenos / Developers",
	[2] = "MTA Administrators",
	[3] = "Moderadores",
}

local ownerUserIDs =
{
	[1] = true,
}

local function getAdminPanelRole(player)
	local userID = exports.players:getUserID(player)
	if not userID then
		return false
	end

	if ownerUserIDs[tonumber(userID)] then
		return "Dueno del servidor"
	end

	local rows = exports.sql:query_assoc("SELECT groupID FROM wcf1_user_to_groups WHERE userID = " .. tonumber(userID))
	if rows then
		for key, row in ipairs(rows) do
			local groupID = tonumber(row.groupID)
			if allowedGroupIDs[groupID] then
				return allowedGroupIDs[groupID]
			end
		end
	end

	return false
end

function isAdminPanelAllowed(player)
	return getAdminPanelRole(player) and true or false
end

local function getPlayerRows()
	local rows = {}
	for key, player in ipairs(getElementsByType("player")) do
		if exports.players:isLoggedIn(player) then
			table.insert(rows,
				{
					player = player,
					name = getPlayerName(player):gsub("_", " "),
					id = getElementData(player, "playerid") or "-",
					health = math.floor(getElementHealth(player)),
					armor = math.floor(getPedArmor(player)),
					hunger = tonumber(getElementData(player, "hambre")) or 0,
					thirst = tonumber(getElementData(player, "sed")) or 0,
					money = exports.players:getMoney(player) or 0,
					dimension = getElementDimension(player),
					interior = getElementInterior(player),
				}
			)
		end
	end
	return rows
end

local function sendPanel(player)
	local role = getAdminPanelRole(player)
	if not role then
		outputChatBox("No tienes permisos para abrir el panel administrativo.", player, 255, 0, 0)
		return
	end

	triggerClientEvent(player, "adminpanel:open", player, getPlayerRows(), role)
end

addEvent("adminpanel:openFromAyuda", true)
addEventHandler("adminpanel:openFromAyuda", root,
	function()
		if getElementType(source) == "player" then
			sendPanel(source)
		end
	end
)

addEvent("adminpanel:requestPlayers", true)
addEventHandler("adminpanel:requestPlayers", root,
	function()
		if source == client and isAdminPanelAllowed(client) then
			triggerClientEvent(client, "adminpanel:updatePlayers", client, getPlayerRows())
		end
	end
)

local function revivePlayer(admin, target)
	local x, y, z = getElementPosition(target)
	local _, _, rot = getElementRotation(target)
	local skin = getElementModel(target)
	local dim = getElementDimension(target)
	local int = getElementInterior(target)

	for i = 3, 9 do
		removeElementData(target, "herida" .. tostring(i))
	end

	triggerClientEvent(target, "onClientNoMuerto", target)
	exports.medico:anularLlevarse(target)
	removeElementData(target, "muerto")
	removeElementData(target, "accidente")
	exports.items:guardarArmas(target, true)
	spawnPlayer(target, x, y, z, rot, skin, int, dim)
	fadeCamera(target, true)
	setCameraTarget(target, target)
	setCameraInterior(target, int)
	setElementHealth(target, 100)

	outputChatBox("Has revivido a " .. getPlayerName(target):gsub("_", " ") .. ".", admin, 0, 255, 153)
	outputChatBox("Un administrador te ha revivido.", target, 0, 255, 153)
end

addEvent("adminpanel:action", true)
addEventHandler("adminpanel:action", root,
	function(action, target, amount)
		if source ~= client or not isAdminPanelAllowed(client) then
			return
		end

		if not isElement(target) or getElementType(target) ~= "player" or not exports.players:isLoggedIn(target) then
			outputChatBox("Selecciona un jugador valido.", client, 255, 0, 0)
			return
		end

		if action == "revive" then
			revivePlayer(client, target)
		elseif action == "health" then
			removeElementData(target, "muerto")
			setElementHealth(target, 100)
			outputChatBox("Has restaurado la vida de " .. getPlayerName(target):gsub("_", " ") .. ".", client, 0, 255, 153)
		elseif action == "needs" then
			setElementData(target, "hambre", 100)
			setElementData(target, "sed", 100)
			setElementData(target, "cansancio", 100)
			outputChatBox("Has restaurado hambre, sed y cansancio de " .. getPlayerName(target):gsub("_", " ") .. ".", client, 0, 255, 153)
		elseif action == "armor" then
			setPedArmor(target, 100)
			outputChatBox("Has dado chaleco a " .. getPlayerName(target):gsub("_", " ") .. ".", client, 0, 255, 153)
		elseif action == "goto" then
			local x, y, z = getElementPosition(target)
			setElementInterior(client, getElementInterior(target))
			setElementDimension(client, getElementDimension(target))
			setElementPosition(client, x + 1, y, z)
		elseif action == "bring" then
			local x, y, z = getElementPosition(client)
			setElementInterior(target, getElementInterior(client))
			setElementDimension(target, getElementDimension(client))
			setElementPosition(target, x + 1, y, z)
		elseif action == "freeze" then
			local frozen = not isElementFrozen(target)
			setElementFrozen(target, frozen)
			toggleAllControls(target, not frozen, true, false)
			outputChatBox((frozen and "Has congelado a " or "Has descongelado a ") .. getPlayerName(target):gsub("_", " ") .. ".", client, 0, 255, 153)
		elseif action == "money" then
			amount = tonumber(amount)
			if not amount or amount <= 0 or amount > 10000000 then
				outputChatBox("Introduce una cantidad valida entre 1 y 10000000.", client, 255, 0, 0)
				return
			end

			amount = math.floor(amount)
			if exports.players:giveMoney(target, amount) then
				outputChatBox("Has dado $" .. amount .. " a " .. getPlayerName(target):gsub("_", " ") .. ".", client, 0, 255, 153)
				outputChatBox("Un administrador te ha dado $" .. amount .. ".", target, 0, 255, 153)
			end
		end

		triggerClientEvent(client, "adminpanel:updatePlayers", client, getPlayerRows())
	end
)

addCommandHandler("paneladmin",
	function(player)
		if exports.players:isLoggedIn(player) then
			sendPanel(player)
		end
	end
)
