local screenW, screenH = guiGetScreenSize()
local panel = {}
local visible = false

local actions =
{
	{ id = "revive", label = "Revivir" },
	{ id = "health", label = "Vida 100" },
	{ id = "needs", label = "Hambre/Sed 100" },
	{ id = "armor", label = "Chaleco 100" },
	{ id = "goto", label = "Ir" },
	{ id = "bring", label = "Traer" },
	{ id = "freeze", label = "Congelar/Descongelar" },
}

local function destroyPanel()
	if panel.window and isElement(panel.window) then
		destroyElement(panel.window)
	end

	panel = {}
	visible = false
	showCursor(false)
end

local function getSelectedPlayer()
	if not panel.grid or not isElement(panel.grid) then
		return false
	end

	local row = guiGridListGetSelectedItem(panel.grid)
	if not row or row < 0 then
		outputChatBox("Selecciona primero un jugador.", 255, 0, 0)
		return false
	end

	local player = guiGridListGetItemData(panel.grid, row, 1)
	if not isElement(player) then
		outputChatBox("Ese jugador ya no esta disponible. Pulsa refrescar.", 255, 0, 0)
		return false
	end

	return player
end

local function fillPlayers(players)
	if not panel.grid or not isElement(panel.grid) then
		return
	end

	local search = ""
	if panel.search and isElement(panel.search) then
		search = guiGetText(panel.search):lower()
	end

	guiGridListClear(panel.grid)
	for key, data in ipairs(players or {}) do
		local name = tostring(data.name or "")
		if search == "" or name:lower():find(search, 1, true) then
			local row = guiGridListAddRow(panel.grid)
			guiGridListSetItemText(panel.grid, row, 1, tostring(data.id or "-"), false, true)
			guiGridListSetItemText(panel.grid, row, 2, name, false, false)
			guiGridListSetItemText(panel.grid, row, 3, tostring(data.health or 0), false, true)
			guiGridListSetItemText(panel.grid, row, 4, tostring(data.armor or 0), false, true)
			guiGridListSetItemText(panel.grid, row, 5, tostring(data.hunger or 0), false, true)
			guiGridListSetItemText(panel.grid, row, 6, tostring(data.thirst or 0), false, true)
			guiGridListSetItemText(panel.grid, row, 7, "$" .. tostring(data.money or 0), false, true)
			guiGridListSetItemText(panel.grid, row, 8, tostring(data.dimension or 0), false, true)
			guiGridListSetItemData(panel.grid, row, 1, data.player)
		end
	end
end

local function createPanel(players, role)
	destroyPanel()

	local w, h = 760, 510
	local x, y = (screenW - w) / 2, (screenH - h) / 2

	panel.window = guiCreateWindow(x, y, w, h, "Panel Administracion", false)
	guiWindowSetSizable(panel.window, false)

	panel.role = guiCreateLabel(18, 28, 420, 20, "Rango: " .. tostring(role or "Staff"), false, panel.window)
	guiSetFont(panel.role, "default-bold-small")

	panel.search = guiCreateEdit(18, 54, 260, 28, "", false, panel.window)
	panel.searchLabel = guiCreateLabel(285, 59, 160, 18, "Buscar jugador", false, panel.window)

	panel.refresh = guiCreateButton(610, 52, 130, 30, "Refrescar", false, panel.window)
	panel.moneyLabel = guiCreateLabel(610, 390, 130, 18, "Cantidad dinero", false, panel.window)
	panel.money = guiCreateEdit(610, 410, 130, 26, "1000", false, panel.window)
	panel.moneyButton = guiCreateButton(610, 440, 130, 28, "Dar dinero", false, panel.window)
	panel.close = guiCreateButton(610, 472, 130, 26, "Cerrar", false, panel.window)

	panel.grid = guiCreateGridList(18, 92, 555, 362, false, panel.window)
	guiGridListAddColumn(panel.grid, "ID", 0.10)
	guiGridListAddColumn(panel.grid, "Jugador", 0.25)
	guiGridListAddColumn(panel.grid, "Vida", 0.10)
	guiGridListAddColumn(panel.grid, "Armor", 0.10)
	guiGridListAddColumn(panel.grid, "Hambre", 0.11)
	guiGridListAddColumn(panel.grid, "Sed", 0.10)
	guiGridListAddColumn(panel.grid, "Dinero", 0.12)
	guiGridListAddColumn(panel.grid, "Dim", 0.08)

	for i, action in ipairs(actions) do
		local row = math.floor((i - 1) / 1)
		local button = guiCreateButton(610, 96 + row * 43, 130, 34, action.label, false, panel.window)
		addEventHandler("onClientGUIClick", button,
			function()
				local target = getSelectedPlayer()
				if target then
					triggerServerEvent("adminpanel:action", localPlayer, action.id, target)
				end
			end,
			false
		)
	end

	addEventHandler("onClientGUIClick", panel.close, destroyPanel, false)
	addEventHandler("onClientGUIClick", panel.moneyButton,
		function()
			local target = getSelectedPlayer()
			if target then
				triggerServerEvent("adminpanel:action", localPlayer, "money", target, guiGetText(panel.money))
			end
		end,
		false
	)
	addEventHandler("onClientGUIClick", panel.refresh,
		function()
			triggerServerEvent("adminpanel:requestPlayers", localPlayer)
		end,
		false
	)
	addEventHandler("onClientGUIChanged", panel.search,
		function()
			triggerServerEvent("adminpanel:requestPlayers", localPlayer)
		end,
		false
	)

	fillPlayers(players)
	visible = true
	showCursor(true)
end

addEvent("adminpanel:open", true)
addEventHandler("adminpanel:open", root, createPanel)

addEvent("adminpanel:updatePlayers", true)
addEventHandler("adminpanel:updatePlayers", root, fillPlayers)

addEvent("onAbrirPanelAyudaAdmin", true)
addEventHandler("onAbrirPanelAyudaAdmin", root,
	function(players, role)
		if visible then
			destroyPanel()
		else
			createPanel(players or {}, role or "Staff")
			triggerServerEvent("adminpanel:requestPlayers", localPlayer)
		end
	end
)
