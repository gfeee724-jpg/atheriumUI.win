--// VibeUI smoke test
--// Loads the module from GitHub raw and exercises the public API.
--// Paste into any executor. Everything is guarded: a broken control prints
--// "FAIL" with the reason instead of killing the script.

local URL = "https://raw.githubusercontent.com/gfeee724-jpg/atheriumUI.win/refs/heads/main/VibeUI.lua"
local BUST = URL .. "?t=" .. tostring(os.time())

local results = {}
local function log(name, ok, err)
	table.insert(results, { name = name, ok = ok, err = err })
	if ok then
		print(string.format("[VibeUI TEST] OK   %s", name))
	else
		print(string.format("[VibeUI TEST] FAIL %s -> %s", name, tostring(err)))
	end
end
local function check(name, fn)
	local ok, err = pcall(fn)
	log(name, ok, err)
	return ok, err
end

local t0 = os.clock()

-- 1. download -----------------------------------------------------------------
local src
local okDl, dlErr = pcall(function()
	src = game:HttpGet(BUST)
end)
if not okDl or type(src) ~= "string" or #src < 50000 then
	warn("[VibeUI TEST] download failed: " .. tostring(dlErr))
	return
end
log("download (" .. tostring(math.floor(#src / 1024)) .. " KB)", true)

-- 2. compile ------------------------------------------------------------------
local VibeUI
if not check("compile", function()
	VibeUI = assert(loadstring(src))()
	assert(type(VibeUI) == "table", "module did not return a table")
	assert(type(VibeUI.CreateWindow) == "function", "CreateWindow missing")
end) then return end

check("version", function()
	assert(VibeUI.Version, "Version missing")
	print("[VibeUI TEST] version = " .. tostring(VibeUI.Version) .. ", tag = " .. tostring(VibeUI.BuildTag))
end)

-- 3. clean previous instance ---------------------------------------------------
pcall(function()
	local env = getgenv and getgenv()
	local old = env and (env.AtheriumWin or env.AhteriumWin)
	if old and old._destroyAcrylic then old._destroyAcrylic() end
	local hull = gethui and gethui()
	if hull then
		for _, g in ipairs(hull:GetChildren()) do
			if g.Name == "Atherium" then g:Destroy() end
		end
	end
	for _, g in ipairs(game:GetService("Players").LocalPlayer.PlayerGui:GetChildren()) do
		if g.Name == "Atherium" then g:Destroy() end
	end
end)

-- 4. window -------------------------------------------------------------------
local win
if not check("CreateWindow", function()
	win = VibeUI:CreateWindow({ Title = "VibeUI Test", Subtitle = "v" .. tostring(VibeUI.Version), Autosave = false })
	assert(win._gui, "ScreenGui missing")
end) then return end

local tab = assert(win:AddTab("Controls", "sliders-horizontal"))
local sec = assert(tab:AddSection("Basic", "sparkles"))

-- 5. controls -----------------------------------------------------------------
check("AddToggle", function()
	local t = sec:AddToggle({ Name = "Test Toggle", Default = false })
	assert(t:Get() == false, "default not applied")
	t:Set(true)
	assert(t:Get() == true, "Set(true) not applied")
end)

check("AddSlider", function()
	local s = sec:AddSlider({ Name = "Test Slider", Min = 0, Max = 100, Default = 30 })
	assert(tonumber(s:Get()) == 30, "default not applied")
	s:Set(75)
	assert(tonumber(s:Get()) == 75, "Set(75) not applied")
end)

check("AddDropdown", function()
	local d = sec:AddDropdown({ Name = "Test Dropdown", Options = { "Alpha", "Beta", "Gamma" }, Default = "Beta" })
	assert(d:Get() == "Beta", "default not applied")
	d:SetOptions({ "One", "Two", "Three" })
	d:Set("Three")
	assert(d:Get() == "Three", "Set after SetOptions failed")
end)

check("AddTextBox", function()
	local tb = sec:AddTextBox({ Name = "Test TextBox", Placeholder = "type here", Default = "hello" })
	assert(tb:Get() == "hello", "default not applied")
	tb:Set("world")
	assert(tb:Get() == "world", "Set failed")
end)

check("AddColorPicker", function()
	local preview = Instance.new("Frame")
	preview.Size = UDim2.new(0, 18, 0, 18)
	preview.Parent = win._gui
	local cp = sec:AddColorPicker({
		Name = "Test Color", Transparency = 0.1, Default = Color3.fromRGB(200, 200, 210),
		Callback = function(c, t) VibeUI.Paint(preview, c, t) end,
	})
	local c = cp:Get()
	assert(typeof(c) == "Color3", "Get did not return Color3")
	cp:Set(Color3.fromRGB(255, 255, 255), false)
	cp:SetTransparency(0.5)
	pcall(function() preview:Destroy() end)
end)

check("AddKeybind", function()
	local kb = sec:AddKeybind({ Name = "Test Keybind", Default = Enum.KeyCode.F })
	assert(typeof(kb:Get()) == "EnumItem", "default not applied")
	kb:Set(Enum.KeyCode.G)
	assert(kb:Get() == Enum.KeyCode.G, "Set failed")
end)

check("AddButton", function()
	sec:AddButton({ Name = "Test Button", Icon = "play", Style = "dark", Callback = function() end })
end)

check("AddLabel", function()
	sec:AddLabel("plain label")
end)

check("AddColumns", function()
	local left, right = sec:AddColumns()
	assert(left and right, "columns did not return two sections")
	left:AddLabel("left")
	right:AddLabel("right")
end)

-- 6. extras -------------------------------------------------------------------
local tab2 = assert(win:AddTab("Extras", "layers"))
local sec2 = assert(tab2:AddSection("Data", "activity"))

check("AddChart", function()
	local ch = sec2:AddChart({ Name = "Test Chart", Type = "line", Height = 96, Window = 30 })
	for i = 1, 30 do ch:Push(math.sin(i / 4) * 40 + 60) end
	ch:SetValue(72)
	ch:SetColors("mono")
	ch:SetSmooth(true)
	local st = ch:GetStats()
	assert(type(st) == "table" and st.count and st.count > 0, "GetStats empty")
	ch:SetType("bar")
	ch:SetType("line")
end)

check("AddViewport", function()
	local vp = sec2:AddViewport({ Name = "Test Viewport", Height = 200, AutoRotate = true, ShowControls = true })
	vp:SetPlayer()
	task.wait(0.25)
	vp:Focus()
	vp:SetDistance(9)
	vp:SetFOV(40)
	vp:SetAngles(35, 12)
	local model = vp:GetModel()
	assert(model, "no model in viewport")
	local parts, hidden = 0, 0
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			parts = parts + 1
			if (d.LocalTransparencyModifier or 0) > 0.05 then hidden = hidden + 1 end
		end
	end
	assert(parts > 0, "viewport model has no parts")
	assert(hidden == 0, tostring(hidden) .. " parts still first-person faded")
	print("[VibeUI TEST] viewport parts = " .. tostring(parts) .. ", hidden = " .. tostring(hidden))
end)

check("Stream line", function()
	local lp = sec2:AddChart({ Name = "Stream Line", Type = "line", Height = 90, MaxPoints = 20 })
	lp:Stream(function() return 42 end, 0.1)
	task.wait(0.6)
	local d = lp:GetData()
	assert(type(d) == "table" and #d >= 1, "line stream pushed nothing")
	lp:Stop()
end)

check("Notify", function()
	win:Notify("VibeUI Test", "controls built, " .. tostring(#results) .. " checks")
end)

check("CreatePanel", function()
	local p = win:CreatePanel({ Title = "Test Panel", Icon = "terminal", Width = 220 })
	assert(p.frame and p.body, "panel parts missing")
end)

check("CreateKeyList", function()
	local kl = win:CreateKeyList()
	assert(kl and kl.frame, "keylist missing")
end)

check("CreateWatermark", function()
	local wm = win:CreateWatermark()
	assert(wm and wm.frame, "watermark missing")
	wm:SetOption("players", true)
	wm:SetOption("time", true)
	assert(wm:GetVisible() == true, "GetVisible wrong")
	wm:SetVisible(false)
	wm:SetVisible(true)
end)

check("Theme", function()
	win:SetAccent(Color3.fromRGB(235, 235, 245))
	win:SetThemeFont("Inter")
	win:ResetTheme()
	win:SetAccent(Color3.fromRGB(255, 255, 255))
end)

check("Configs", function()
	win:SaveConfig("smoke_test", true)
	local list = win:ListConfigs()
	assert(type(list) == "table", "ListConfigs did not return a table")
	win:LoadConfig("smoke_test")
	win:DeleteConfig("smoke_test")
end)

check("Toggle", function()
	win:Toggle()
	task.wait(0.25)
	win:Toggle()
end)

-- 7. globals ------------------------------------------------------------------
check("getgenv().Atherium", function()
	local api = getgenv and getgenv().Atherium
	assert(type(api) == "table", "Atherium table missing")
	assert(api.Version == VibeUI.Version, "Version mismatch")
	assert(api.Window == win, "Window mismatch")
	assert(type(api.Watermark) == "table", "Watermark missing")
	print("[VibeUI TEST] api = { Version, UI, Window, Watermark }")
end)

check("legacy aliases", function()
	local env = getgenv()
	assert(env.AtheriumUI == VibeUI, "AtheriumUI alias broken")
	assert(env.AtheriumWin == win, "AtheriumWin alias broken")
end)

-- 7.5 perf sample --------------------------------------------------------------
local avgFPS = 0
check("perf sample", function()
	local RunService = game:GetService("RunService")
	local frames, t0 = 0, os.clock()
	local conn = RunService.RenderStepped:Connect(function() frames = frames + 1 end)
	task.wait(3)
	conn:Disconnect()
	avgFPS = frames / math.max(os.clock() - t0, 1e-3)
	print(string.format("[VibeUI TEST] avg %.1f fps over 3s", avgFPS))
	getgenv().VibeUITestFPS = avgFPS
	if avgFPS < 30 then
		warn(string.format("[VibeUI TEST] low fps: %.1f - try win:SetAcrylic(false)", avgFPS))
	end
end)

-- 8. summary ------------------------------------------------------------------
local pass, fail = 0, 0
local failed = {}
for _, r in ipairs(results) do
	if r.ok then
		pass = pass + 1
	else
		fail = fail + 1
		table.insert(failed, r.name .. ": " .. tostring(r.err))
	end
end

local head = string.format("%d/%d passed in %.2fs, %.1f fps", pass, pass + fail, os.clock() - t0, avgFPS)
print("[VibeUI TEST] ===============================================")
print("[VibeUI TEST] " .. head)
for _, f in ipairs(failed) do print("[VibeUI TEST] FAILED " .. f) end
print("[VibeUI TEST] window: RightShift toggles, right-click watermark for its menu")

if fail == 0 then
	win:Notify("VibeUI Test", head .. " - all good", 6)
else
	win:Notify("VibeUI Test", head .. " - see console", 8)
end

getgenv().VibeUITest = { Win = win, UI = VibeUI, Results = results }
