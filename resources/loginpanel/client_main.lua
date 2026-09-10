local sX, sY = guiGetScreenSize()
local scale = math.max(0.85, math.min(1.15, sX / 1600))

local loginMusic = {
	url = "", -- Ejemplo: "https://tusitio.com/login.mp3" o "audio/login.mp3"
	volume = 0.35,
	loop = true
}

local state = {
	mode = "login",
	hasAccount = false,
	error = "",
	errorTick = 0,
	startTick = getTickCount(),
	music = nil,
	musicMuted = false,
	blur = {
		shader = dxCreateShader("img/blur.fx"),
		screensource = dxCreateScreenSource(sX, sY)
	},
	login = {},
	register = {},
	forgotpass = {},
	buttons = {}
}

local function sx(value)
	return value * scale
end

local function panelRect()
	local w = math.min(sX - sx(48), sx(920))
	local h = math.min(sY - sx(48), sx(520))
	return (sX - w) / 2, (sY - h) / 2, w, h
end

local function setLoginError(text, timeout)
	state.error = tostring(text or "")
	state.errorTick = getTickCount() + (timeout or 3500)
end

local function resetLoginError()
	state.error = ""
	state.errorTick = 0
end

local function setBusy(button, busy)
	if button and isElement(button) then
		dxSetButtonEnabled(button, not busy)
	end
end

local function startLoginMusic()
	if loginMusic.url == "" or state.musicMuted or isElement(state.music) then
		return
	end

	state.music = playSound(loginMusic.url, loginMusic.loop)
	if isElement(state.music) then
		setSoundVolume(state.music, loginMusic.volume or 0.35)
	end
end

local function stopLoginMusic()
	if isElement(state.music) then
		stopSound(state.music)
	end
	state.music = nil
end

local function toggleLoginMusic()
	state.musicMuted = not state.musicMuted
	if state.musicMuted then
		stopLoginMusic()
	else
		startLoginMusic()
	end
end

local function drawBlur()
	if isElement(state.blur.shader) and isElement(state.blur.screensource) then
		dxUpdateScreenSource(state.blur.screensource)
		dxSetShaderValue(state.blur.shader, "ScreenSource", state.blur.screensource)
		dxSetShaderValue(state.blur.shader, "UVSize", sX, sY)
		dxSetShaderValue(state.blur.shader, "BlurStrength", 7)
		dxDrawImage(0, 0, sX, sY, state.blur.shader)
	else
		dxDrawRectangle(0, 0, sX, sY, tocolor(10, 13, 18, 235))
	end
end

local function drawBackground()
	local tick = getTickCount() - state.startTick
	local pulse = (math.sin(tick / 900) + 1) / 2
	dxDrawRectangle(0, 0, sX, sY, tocolor(9, 11, 16, 215))
	dxDrawRectangle(0, 0, sX, sY, tocolor(26, 36, 46, 90 + pulse * 35))

	for i = 1, 9 do
		local x = ((tick / (28 + i * 3)) + i * 173) % (sX + sx(140)) - sx(70)
		local y = (sY * 0.12) + ((i * 73) % math.max(1, sY * 0.78))
		local alpha = 18 + (i % 3) * 8
		dxDrawRectangle(x, y, sx(92), 1, tocolor(255, 255, 255, alpha))
	end
end

local function drawHeader(px, py, pw)
	dxDrawText("Rolombia Roleplay", px, py, px + pw, py + sx(48), tocolor(255, 255, 255, 255), sx(1.8), "default-bold", "left", "center")
	dxDrawText("Los Santos abierto. Crea tu cuenta o entra con tu usuario.", px, py + sx(42), px + pw, py + sx(70), tocolor(190, 200, 210, 235), sx(1), "default", "left", "center")
end

local function drawTabs(px, py, pw)
	local tabW = sx(132)
	local activeLogin = state.mode == "login"
	local activeRegister = state.mode == "register"
	dxDrawRectangle(px, py, tabW, sx(34), activeLogin and tocolor(43, 126, 219, 230) or tocolor(255, 255, 255, 28))
	dxDrawRectangle(px + tabW + sx(8), py, tabW, sx(34), activeRegister and tocolor(43, 126, 219, 230) or tocolor(255, 255, 255, 28))
	dxDrawText("Entrar", px, py, px + tabW, py + sx(34), tocolor(255, 255, 255, 255), sx(1), "default-bold", "center", "center")
	dxDrawText("Registro", px + tabW + sx(8), py, px + tabW * 2 + sx(8), py + sx(34), tocolor(255, 255, 255, 255), sx(1), "default-bold", "center", "center")

	if getKeyState("mouse1") then
		if isMouseInPosition(px, py, tabW, sx(34)) then
			state.mode = "login"
		elseif isMouseInPosition(px + tabW + sx(8), py, tabW, sx(34)) then
			state.mode = "register"
		end
	end
end

local function drawStatus(px, py, pw)
	if state.error ~= "" then
		if state.errorTick > 0 and getTickCount() > state.errorTick then
			resetLoginError()
			return
		end
		dxDrawText(state.error, px, py, px + pw, py + sx(34), tocolor(255, 225, 225, 255), sx(1), "default-bold", "center", "center", true, true)
	end
end

local function drawLogin()
	local px, py, pw, ph = panelRect()
	local leftX = px + sx(42)
	local rightX = px + pw * 0.52
	local contentY = py + sx(122)
	local inputW = math.min(sx(360), pw * 0.42)

	drawBlur()
	drawBackground()

	dxDrawRectangle(px, py, pw, ph, tocolor(17, 22, 30, 232))
	dxDrawRectangle(px, py, sx(5), ph, tocolor(43, 126, 219, 255))
	dxDrawRectangle(rightX - sx(28), py + sx(42), 1, ph - sx(84), tocolor(255, 255, 255, 45))

	drawHeader(leftX, py + sx(34), pw * 0.42)
	drawTabs(leftX, contentY, inputW)

	if state.mode == "login" then
		dxDrawEdit(state.login.username)
		dxDrawEdit(state.login.password)
		dxDrawButton(state.login.button)
		dxDrawButton(state.forgotpass.fpass)
	else
		if state.hasAccount then
			dxDrawText("Este PC ya tiene una cuenta registrada.", leftX, contentY + sx(60), leftX + inputW, contentY + sx(126), tocolor(230, 235, 240, 245), sx(1.1), "default-bold", "center", "center", true, true)
		else
			dxDrawEdit(state.register.username)
			dxDrawEdit(state.register.password)
			dxDrawEdit(state.register.repassword)
			dxDrawButton(state.register.button)
		end
	end

	if state.mode == "forgot" then
		dxDrawRectangle(leftX, contentY + sx(170), inputW, sx(112), tocolor(255, 255, 255, 24))
		dxDrawText("Recuperar clave", leftX, contentY + sx(174), leftX + inputW, contentY + sx(204), tocolor(255, 255, 255, 245), sx(1), "default-bold", "center", "center")
		dxDrawEdit(state.forgotpass.pass)
		dxDrawButton(state.forgotpass.button)
	end

	drawStatus(leftX, py + ph - sx(70), inputW)

	dxDrawText("Bienvenido", rightX + sx(18), py + sx(54), px + pw - sx(42), py + sx(86), tocolor(255, 255, 255, 255), sx(1.25), "default-bold", "left", "center")
	dxDrawText("Una ciudad nueva esta cargando.\nElige tu cuenta y prepara tu personaje.", rightX + sx(18), py + sx(106), px + pw - sx(42), py + sx(230), tocolor(198, 208, 218, 240), sx(1), "default", "left", "top", false, true)
	dxDrawButton(state.buttons.music)
end

local function createControls()
	local px, py, pw, ph = panelRect()
	local leftX = px + sx(42)
	local contentY = py + sx(122)
	local inputW = math.min(sx(360), pw * 0.42)
	local inputH = sx(38)

	state.login.username = dxCreateEdit(leftX, contentY + sx(54), inputW, inputH, sx(1), "Usuario")
	state.login.password = dxCreateEdit(leftX, contentY + sx(102), inputW, inputH, sx(1), "Clave")
	dxSetEditMask(state.login.password, true)
	state.login.button = dxCreateButton(leftX, contentY + sx(158), inputW, sx(38), "Iniciar sesion", tocolor(43, 126, 219, 245), sx(1))
	state.forgotpass.fpass = dxCreateButton(leftX, contentY + sx(206), inputW, sx(28), "Olvide mi clave", tocolor(255, 255, 255, 28), sx(0.9))

	state.register.username = dxCreateEdit(leftX, contentY + sx(54), inputW, inputH, sx(1), "Nuevo usuario")
	state.register.password = dxCreateEdit(leftX, contentY + sx(102), inputW, inputH, sx(1), "Clave")
	state.register.repassword = dxCreateEdit(leftX, contentY + sx(150), inputW, inputH, sx(1), "Repetir clave")
	dxSetEditMask(state.register.password, true)
	dxSetEditMask(state.register.repassword, true)
	state.register.button = dxCreateButton(leftX, contentY + sx(206), inputW, sx(38), "Crear cuenta", tocolor(43, 126, 219, 245), sx(1))

	state.forgotpass.pass = dxCreateEdit(leftX + sx(16), contentY + sx(212), inputW - sx(32), inputH, sx(1), "Nueva clave")
	dxSetEditMask(state.forgotpass.pass, true)
	state.forgotpass.button = dxCreateButton(leftX + sx(16), contentY + sx(254), inputW - sx(32), sx(28), "Cambiar clave", tocolor(43, 126, 219, 245), sx(0.9))

	state.buttons.music = dxCreateButton(px + pw - sx(172), py + ph - sx(72), sx(130), sx(30), "Musica on/off", tocolor(255, 255, 255, 28), sx(0.85))
end

function showLogin(serialRegistered)
	showCursor(true)
	state.hasAccount = serialRegistered and true or false
	state.mode = "login"
	state.startTick = getTickCount()
	if not isElement(state.blur.shader) then
		state.blur.shader = dxCreateShader("img/blur.fx")
	end
	if not isElement(state.blur.screensource) then
		state.blur.screensource = dxCreateScreenSource(sX, sY)
	end
	createControls()
	startLoginMusic()
	addEventHandler("onClientRender", root, drawLogin)
end

addEvent("players:loginResult", true)
addEventHandler("players:loginResult", localPlayer,
	function(code)
		setBusy(state.login.button, false)
		if code == 1 then
			setLoginError("Usuario o clave incorrectos.")
		elseif code == 2 then
			setLoginError("Esta cuenta se encuentra baneada.", 6000)
		elseif code == 3 then
			setLoginError("La cuenta requiere completar el test de rol.", 6000)
		elseif code == 4 then
			setLoginError("Error desconocido. Intentalo de nuevo.")
		elseif code == 5 then
			setLoginError("Otra persona esta usando esta cuenta.")
		elseif code == 6 then
			setLoginError("La cuenta esta desactivada por staff.", 6000)
		end
	end
)

addEvent("players:registrationResult", true)
addEventHandler("players:registrationResult", localPlayer,
	function(code)
		setBusy(state.register.button, false)
		if code == 0 then
			local username = dxGetEditText(state.register.username)
			local password = dxGetEditText(state.register.password)
			triggerServerEvent("server:login", localPlayer, username, password)
		elseif code == 1 then
			setLoginError("No se pudo completar el registro.")
		elseif code == 2 then
			setLoginError("El registro esta deshabilitado.")
		elseif code == 3 then
			setLoginError("Ese usuario ya existe.")
		elseif code == 4 then
			setLoginError("Error de base de datos al registrar.")
		elseif code == 5 then
			setLoginError("Solo se permite una cuenta por serial.", 6000)
		elseif code == 6 then
			setLoginError("Solo se permiten dos cuentas por IP.", 6000)
		end
	end
)

addEvent("client:recoverFailed", true)
addEventHandler("client:recoverFailed", localPlayer,
	function()
		setLoginError("No se pudo recuperar la clave.")
	end
)

addEvent("client:init:callBack", true)
addEventHandler("client:init:callBack", root,
	function(serialRegistered)
		showLogin(serialRegistered)
	end
)

addEvent("onDestroyLoginPanel", true)
addEventHandler("onDestroyLoginPanel", root,
	function()
		showCursor(false)
		guiSetInputEnabled(false)
		stopLoginMusic()
		removeEventHandler("onClientRender", root, drawLogin)
		if isElement(state.blur.screensource) then
			destroyElement(state.blur.screensource)
		end
		if isElement(state.blur.shader) then
			destroyElement(state.blur.shader)
		end
	end
)

addEvent("client:forgotpass:callBack", true)
addEventHandler("client:forgotpass:callBack", root,
	function(usernameCheck)
		if usernameCheck == true then
			state.mode = "forgot"
		else
			setLoginError("No puedes cambiar la clave de ese usuario.")
		end
	end
)

addEvent("onClientdxButtonClick", true)
addEventHandler("onClientdxButtonClick", root,
	function(plr)
		if plr ~= localPlayer then
			return
		end

		if source == state.login.button then
			local username = dxGetEditText(state.login.username)
			local password = dxGetEditText(state.login.password)
			if #username < 3 then
				setLoginError("El usuario debe tener minimo 3 caracteres.")
			elseif #password < 5 then
				setLoginError("La clave debe tener minimo 5 caracteres.")
			else
				setBusy(state.login.button, true)
				triggerServerEvent("server:login", localPlayer, username, password)
			end
		elseif source == state.register.button then
			local username = dxGetEditText(state.register.username)
			local password = dxGetEditText(state.register.password)
			local repassword = dxGetEditText(state.register.repassword)
			if state.hasAccount then
				setLoginError("Este PC ya tiene una cuenta registrada.")
			elseif #username < 3 then
				setLoginError("El usuario debe tener minimo 3 caracteres.")
			elseif #password < 8 then
				setLoginError("La clave debe tener minimo 8 caracteres.")
			elseif password ~= repassword then
				setLoginError("Las claves no coinciden.")
			else
				setBusy(state.register.button, true)
				triggerServerEvent("server:register", localPlayer, username, password)
			end
		elseif source == state.forgotpass.fpass then
			local username = dxGetEditText(state.login.username)
			if #username > 0 then
				triggerServerEvent("server:forgotpass", localPlayer, username)
			else
				setLoginError("Introduce primero tu usuario.")
			end
		elseif source == state.forgotpass.button then
			local username = dxGetEditText(state.login.username)
			local password = dxGetEditText(state.forgotpass.pass)
			if #username == 0 then
				setLoginError("Introduce primero tu usuario.")
			elseif #password < 8 then
				setLoginError("La clave debe tener minimo 8 caracteres.")
			else
				triggerServerEvent("server:changePassword", localPlayer, username, password)
			end
		elseif source == state.buttons.music then
			toggleLoginMusic()
		end
	end
)
