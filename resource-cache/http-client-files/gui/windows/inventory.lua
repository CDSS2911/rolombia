local function getItemTitle(item)
	if not item then
		return ""
	end

	if item.name and tostring(item.name) ~= "" then
		return tostring(item.name)
	end

	return exports.items:getName(item.item, item.value, item.name) or ("Item " .. tostring(item.item))
end

local function getWeightValues()
	local current = exports.items:getCurrentWeight(localPlayer) or 0
	local max = exports.items:getMaxWeight(localPlayer) or exports.items:getDefaultMaxWeight()
	return current, max
end

local function getWeightText()
	local current, max = getWeightValues()
	return "Carga: " .. string.format("%.1f", current) .. " / " .. string.format("%.1f", max) .. " kg"
end

local function getActionText()
	if getKeyState("s") then
		return "Soltar"
	elseif getKeyState("c") then
		return "Dar"
	end

	return "Usar"
end

local function drawItemTooltip(item, name, category, weight, pos)
	local x = pos[1] + 66
	local y = math.max(10, pos[2] - 58)
	local w = 270
	local h = 62

	dxDrawRectangle(x, y, w, h, tocolor(0, 0, 0, 225), true)
	dxDrawText(name, x + 10, y + 6, x + w - 10, y + 26, tocolor(255, 255, 255, 255), 1, "default-bold", "left", "center", true, false, true)
	dxDrawText(category .. " | " .. string.format("%.1f", weight) .. " kg", x + 10, y + 28, x + w - 10, y + 44, tocolor(215, 225, 235, 255), 1, "default", "left", "center", true, false, true)
	dxDrawText(getActionText() .. " con click izquierdo", x + 10, y + 44, x + w - 10, y + h - 4, tocolor(170, 185, 205, 255), 1, "default", "left", "center", true, false, true)
end

local function addItemPane(panes, slot, item, targetPlayer)
	if not item then
		return
	end

	local name = getItemTitle(item)
	local category = exports.items:getCategory(item.item) or "General"
	local weight = exports.items:getWeight(item.item, item.value, name, item.value2) or 0

	table.insert(panes,
		{
			image = exports.items:getImage(item.item, item.value, name) or ":players/images/skins/-1.png",
			title = name,
			onHover = function(cursor, pos)
				local color = {255, 255, 0, 70}
				if getKeyState("s") then
					color = {255, 80, 80, 80}
				elseif getKeyState("c") then
					color = {80, 170, 255, 80}
				end

				dxDrawRectangle(pos[1], pos[2], pos[3] - pos[1], pos[4] - pos[2], tocolor(unpack(color)), true)
				drawItemTooltip(item, name, category, weight, pos)
			end,
			onClick = function(key)
				if key ~= 1 then
					return
				end

				if targetPlayer then
					triggerServerEvent("items:use2", localPlayer, slot, targetPlayer)
				elseif getKeyState("s") then
					triggerServerEvent("items:destroy", localPlayer, slot)
				elseif getKeyState("c") then
					triggerServerEvent("items:give", localPlayer, slot)
				else
					triggerServerEvent("items:use", localPlayer, slot)
				end
			end
		}
	)
end

windows.inventory =
{
	{
		type = "label",
		text = "Inventario",
		font = "bankgothic",
		alignX = "center"
	},
	{
		type = "label",
		text = getWeightText,
		color = {125, 220, 145, 255},
		alignX = "center"
	},
	{
		type = "vpane",
		lines = 7,
		panes = {}
	},
	{
		type = "label",
		text = function()
			return "Click: usar | S + click: soltar | C + click: dar"
		end,
		alignX = "center"
	},
	{
		type = "button",
		text = "Cerrar",
		onClick = function()
			hide()
			triggerEvent("offCursor", localPlayer)
		end
	}
}

function updateInventory()
	windows.inventory[3].panes = {}

	local items = exports.items:get(localPlayer)
	if items then
		for slot, item in ipairs(items) do
			addItemPane(windows.inventory[3].panes, slot, item)
		end
	end
end
setTimer(updateInventory, 500, 1)

windows.inventory_other =
{
	{
		type = "label",
		text = "Inventario del jugador",
		font = "bankgothic",
		alignX = "center"
	},
	{
		type = "vpane",
		lines = 7,
		panes = {}
	},
	{
		type = "button",
		text = "Cerrar",
		onClick = function()
			hide()
			triggerEvent("offCursor", localPlayer)
		end
	}
}

function updateInventory2(items, otherPlayer)
	windows.inventory_other[2].panes = {}

	if items then
		for slot, item in ipairs(items) do
			addItemPane(windows.inventory_other[2].panes, slot, item, otherPlayer)
		end
	end

	show("inventory_other")
end
addEvent("onOpenInventory", true)
addEventHandler("onOpenInventory", root, updateInventory2)
addEvent("onRequestAnotherInventory", true)
addEventHandler("onRequestAnotherInventory", root, updateInventory2)
