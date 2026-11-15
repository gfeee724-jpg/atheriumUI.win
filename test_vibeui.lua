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

local EXPECTED = "11.1" -- bump together with VibeUI.Version

check("version", function()
	assert(VibeUI.Version, "Version missing")
	local v = tostring(VibeUI.Version)
	print("[VibeUI TEST] version = " .. v .. ", tag = " .. tostring(VibeUI.BuildTag))
	if v ~= EXPECTED then
		warn(string.format(
			"[VibeUI TEST] module is v%s, expected v%s - this is a cached build. Re-run in a minute or add ?v=%d to the URL.",
			v, EXPECTED, os.time()))
	end
	getgenv().VibeUITestExpected = EXPECTED
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
	local row = win._gui:FindFirstChild("Row_Test Slider", true)
	assert(row, "slider row missing")
	local thumb = row:FindFirstChild("Thumb", true)
	assert(thumb, "thumb missing")
	assert(thumb.AbsoluteSize.X >= 10, "thumb too small")
	assert(thumb.Size.X.Offset == 15 and thumb.Size.Y.Offset == 20,
		string.format("old slider geometry: thumb is %dx%d, expected 15x20",
			thumb.Size.X.Offset, thumb.Size.Y.Offset))
	assert(row:FindFirstChild("Rail", true), "rail missing")
	assert(row:FindFirstChild("Fill", true), "fill missing")
	local rail = row:FindFirstChild("Rail", true)
	assert(not row:FindFirstChild("GlowCore", true), "glow band stack is back")
	assert(not row:FindFirstChild("GlowWide", true), "glow band stack is back")
	assert(rail.Size.Y.Offset > 0 and rail.Size.Y.Offset <= 6,
		"rail should stay thin, got " .. tostring(rail.Size.Y.Offset))
	local vlab = row:FindFirstChild("Value", true)
	assert(vlab, "value readout missing")
	assert(vlab.TextTransparency < 0.05, "value should be visible by default")
	assert(vlab.TextSize == 12, "value must stay on the 12px tabular size")
	assert(vlab.TextXAlignment == Enum.TextXAlignment.Right, "value must be right aligned")
	assert(vlab.Size.X.Offset == 64, "value slot must keep a fixed 64px width")
	assert(vlab.Text == "75", "value readout out of sync: " .. tostring(vlab.Text))
	-- one capsule + one rim: no concentric rings inside the thumb
	local inner, rim = 0, 0
	for _, ch in ipairs(thumb:GetChildren()) do
		if ch:IsA("Frame") then inner = inner + 1 end
		if ch:IsA("UIStroke") then rim = rim + 1 end
	end
	assert(inner == 0, tostring(inner) .. " stacked frames inside the thumb")
	assert(rim == 1, "thumb needs exactly one rim stroke, got " .. tostring(rim))
	if rail.AbsoluteSize.Y > 0 then
		local tyc = thumb.AbsolutePosition.Y + thumb.AbsoluteSize.Y / 2
		local ryc = rail.AbsolutePosition.Y + rail.AbsoluteSize.Y / 2
		assert(math.abs(tyc - ryc) <= 2.5,
			string.format("thumb sits off the rail: thumb %.1f vs rail %.1f", tyc, ryc))
	end
	-- gutters: title, rail and value share the same 12px inset
	if rail.AbsoluteSize.X > 0 then
		local track = row:FindFirstChild("Track", true)
		local gutL = track.AbsolutePosition.X - row.AbsolutePosition.X
		local gutR = (row.AbsolutePosition.X + row.AbsoluteSize.X) - (track.AbsolutePosition.X + track.AbsoluteSize.X)
		assert(math.abs(gutL - gutR) <= 1.5,
			string.format("rail is not centered: left %.1f vs right %.1f", gutL, gutR))
		local label = row:FindFirstChild("Title", true)
		if label and vlab.AbsoluteSize.X > 0 then
			local labL = label.AbsolutePosition.X - row.AbsolutePosition.X
			local valR = (row.AbsolutePosition.X + row.AbsoluteSize.X) - (vlab.AbsolutePosition.X + vlab.AbsoluteSize.X)
			assert(math.abs(labL - valR) <= 1.5,
				string.format("value inset %.1f does not match title inset %.1f", valR, labL))
		end
	end
	for _, d in ipairs(row:GetDescendants()) do
		if d:IsA("TextLabel") and string.find(d.Text, "%%") then
			error("percent text still sits on the rail: " .. d:GetFullName())
		end
	end
end)

check("Slider ShowValue=false", function()
	local s = sec:AddSlider({ Name = "Bare Slider", Min = 0, Max = 10, Default = 4, ShowValue = false })
	s:Set(7)
	local row = win._gui:FindFirstChild("Row_Bare Slider", true)
	assert(row, "slider row missing")
	assert(not row:FindFirstChild("Value", true), "ShowValue=false must drop the whole value slot")
	local title = row:FindFirstChild("Title", true)
	assert(title, "title missing")
	assert(title.Size.X.Offset == -24, "hidden value slot should hand its width back to the title")
end)

check("AddDropdown", function()
	local d = sec:AddDropdown({ Name = "Test Dropdown", Options = { "Alpha", "Beta", "Gamma" }, Default = "Beta" })
	assert(d:Get() == "Beta", "default not applied")
	d:SetOptions({ "One", "Two", "Three" })
	d:Set("Three")
	assert(d:Get() == "Three", "Set after SetOptions failed")
end)

check("AddDropdown Multiple", function()
	local d = sec:AddDropdown({
		Name = "Multi Dropdown",
		Options = { "Head", "Torso", "Arms", "Legs" },
		Default = { "Head", "Torso" },
		Multiple = true,
	})
	assert(d:IsMultiple(), "Multiple flag not honoured")
	local got = d:Get()
	assert(type(got) == "table" and #got == 2, "default selection not applied, got " .. tostring(#got))
	d:Set({ "Legs" })
	got = d:Get()
	assert(#got == 1 and got[1] == "Legs", "Set(table) failed")
	d:Set({ "Head", "Arms", "Nope" })
	got = d:Get()
	assert(#got == 2, "Set should ignore unknown options, got " .. tostring(#got))
	d:SetOptions({ "Head", "Legs" })
	got = d:Get()
	assert(#got == 1 and got[1] == "Head", "SetOptions should drop selections that vanished")
end)

check("Dropdown search", function()
	local d = sec:AddDropdown({
		Name = "Long List",
		Options = { "one", "two", "three", "four", "five", "six", "seven", "eight" },
	})
	d:Open()
	local row = win._gui:FindFirstChild("Row_Long List", true)
	assert(row, "dropdown row missing")
	local box = row:FindFirstChild("Search", true)
	assert(box and box:IsA("TextBox"), "long lists should render a search field")
	d:Close()
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

check("Config colour transparency", function()
	local cp = sec:AddColorPicker({
		Name = "Round Trip", Default = Color3.fromRGB(10, 200, 30), Transparency = 0.62,
		Callback = function() end,
	})
	win:SaveConfig("smoke_alpha", true)
	cp:SetTransparency(0.05)
	win:LoadConfig("smoke_alpha")
	local _, t = cp:Get()
	assert(math.abs(t - 0.62) < 0.01, "transparency not restored, got " .. tostring(t))
	win:DeleteConfig("smoke_alpha")
end)

check("Profiles", function()
	win:SaveProfile("smoke_prof")
	local found = false
	for _, p in ipairs(win:ListProfiles()) do
		assert(type(p.size) == "number", "profile entry has no size")
		if p.name == "smoke_prof" then found = true end
	end
	assert(found, "SaveProfile did not create a file")

	local code = win:ExportConfig()
	assert(type(code) == "string" and #code > 16, "ExportConfig returned nothing")
	assert(code:sub(1, 5) == "ATH1:", "share code is missing the ATH1 prefix")
	assert(win:ImportConfig(code, true) > 0, "ImportConfig applied nothing")

	assert(win:RenameProfile("smoke_prof", "smoke_prof2"), "RenameProfile failed")
	assert(win:LoadProfile("smoke_prof2"), "renamed profile does not load")
	assert(win:DeleteProfile("smoke_prof2"), "DeleteProfile failed")
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
