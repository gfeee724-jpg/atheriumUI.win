--// ATHERIUM v11.2 | VibeUI.OpenLink + channel on inject
--// Palette: #09090B bg, #0D0D0F side, #121215 cards, #4A4A52 disabled, #8A8A93 dim, #FFFFFF accent
--// Rules: ASCII only, Lucide icons, sidebar tabs left, section cards, live HSV color picker.

local VibeUI = {}
VibeUI.__index = VibeUI
-- public build metadata: scripts may check VibeUI.Version before using
-- features that were added later
VibeUI.Version = "11.2"
VibeUI.BuildTag = "viewport-charts-8"

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local ACCENT_DEFAULT = Color3.fromRGB(255, 255, 255)
local BG_MAIN   = Color3.fromRGB(9, 9, 11)
local BG_TOP    = Color3.fromRGB(13, 13, 15)
local BG_CARD   = Color3.fromRGB(18, 18, 21)
local BG_HOVER  = Color3.fromRGB(26, 26, 32)
local BG_TRACK  = Color3.fromRGB(42, 42, 50)
local TXT_MAIN  = Color3.fromRGB(255, 255, 255)
local TXT_DIM   = Color3.fromRGB(138, 138, 147)
local TXT_FAINT = Color3.fromRGB(74, 74, 82)
local TXT_SIDEBAR = Color3.fromRGB(130, 130, 140)
local TXT_SOFT  = Color3.fromRGB(118, 118, 128)
local TXT_HEAD  = Color3.fromRGB(170, 170, 180)
local LINE      = Color3.fromRGB(34, 34, 43)
--// Icon palette (lighter than text dim/faint so Lucide glyphs stay readable on #121215)
local ICON_MAIN = Color3.fromRGB(235, 235, 240)
local ICON_DIM  = Color3.fromRGB(185, 185, 195)
local ICON_FAINT = Color3.fromRGB(160, 160, 170)
local ICON_SIDE = Color3.fromRGB(175, 175, 186)

local WIN_W, WIN_H = 640, 660

--// ---------- Lucide ----------
local IconsMod = nil
pcall(function()
	IconsMod = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua"))()
end)

local function applyLucide(imgLabel, iconName)
	if typeof(imgLabel) ~= "Instance" or not imgLabel:IsA("ImageLabel") then return false end
	if IconsMod == nil then imgLabel.Visible = false return false end
	local ok, res = pcall(function() return IconsMod.Icon2(iconName) end)
	if not ok or res == nil then imgLabel.Visible = false return false end
	local ok2 = pcall(function()
		if typeof(res) == "string" then
			imgLabel.Image = res
		elseif typeof(res) == "table" then
			imgLabel.Image = res[1]
			local d = res[2]
			if d and d.ImageRectSize and d.ImageRectSize.Magnitude > 0 then
				imgLabel.ImageRectSize = d.ImageRectSize
				imgLabel.ImageRectOffset = d.ImageRectPosition
			end
		end
	end)
	if not ok2 then imgLabel.Visible = false return false end
	imgLabel.Visible = true
	return true
end

local function makeIcon(parent, iconName, size, color, pos, anchor)
	local img = Instance.new("ImageLabel")
	img.Name = "Icon_" .. tostring(iconName)
	img.Size = UDim2.new(0, size, 0, size)
	if pos then img.Position = pos end
	if anchor then img.AnchorPoint = anchor end
	img.BackgroundTransparency = 1
	img.ImageColor3 = color or ICON_DIM
	img.ScaleType = Enum.ScaleType.Fit
	img.Parent = parent
	applyLucide(img, iconName)
	return img
end

--// ---------- builders ----------
local function corner(inst, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = inst
	return c
end

local function stroke(inst, color, transp, thick)
	local s = Instance.new("UIStroke")
	s.Color = color or LINE
	s.Transparency = transp or 0
	s.Thickness = thick or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = inst
	return s
end

-- only the tiles that sit fully inside the rounded rect are drawn, so the
-- silhouette always comes from the parent's own UICorner. No clipping, no
-- CanvasGroup, nothing that can poke a square corner through the curve.
local function insideRoundRect(x, y, w, h, r)
	if not r or r <= 0 then return true end
	local px, py = math.min(x, w - x), math.min(y, h - y)
	if px >= r or py >= r then return true end
	local dx, dy = r - px, r - py
	return dx * dx + dy * dy <= r * r
end

local function checkerFill(parent, maxW, maxH, cell, radius, z, tint)
	cell = cell or 6
	radius = radius or 0
	local holder = Instance.new("Frame")
	holder.Name = "Checker"
	holder.Size = UDim2.new(1, 0, 1, 0)
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.Parent = parent
	if z then holder.ZIndex = z end
	local tile = tint or Color3.fromRGB(62, 62, 72)
	for y = 0, math.ceil(maxH / cell) - 1 do
		for x = 0, math.ceil(maxW / cell) - 1 do
			if (x + y) % 2 == 0 then
				local x0, y0 = x * cell, y * cell
				local x1 = math.min(maxW, x0 + cell)
				local y1 = math.min(maxH, y0 + cell)
				if insideRoundRect(x0, y0, maxW, maxH, radius)
					and insideRoundRect(x1, y0, maxW, maxH, radius)
					and insideRoundRect(x0, y1, maxW, maxH, radius)
					and insideRoundRect(x1, y1, maxW, maxH, radius) then
					local sq = Instance.new("Frame")
					sq.Size = UDim2.new(0, cell, 0, cell)
					sq.Position = UDim2.new(0, x0, 0, y0)
					sq.BackgroundColor3 = tile
					sq.BorderSizePixel = 0
					sq.Parent = holder
					if z then sq.ZIndex = z end
				end
			end
		end
	end
	return holder
end

local function hairline(parent, yPos)
	local l = Instance.new("Frame")
	l.Name = "Hairline"
	l.Size = UDim2.new(1, -24, 0, 1)
	l.Position = UDim2.new(0, 12, 0, yPos or 0)
	l.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	l.BackgroundTransparency = 0.82
	l.BorderSizePixel = 0
	l.Parent = parent
	local g = Instance.new("UIGradient")
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.25, 0),
		NumberSequenceKeypoint.new(0.75, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	g.Parent = l
	return l
end

local function makeDrag(frame, handle)
	local dragging, dragStart, startPos = false, nil, nil
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

local function clickSound(parent, enabledFn)
	if not enabledFn or not enabledFn() then return end
	pcall(function()
		local s = Instance.new("Sound")
		s.SoundId = "rbxassetid://4590657391"
		s.Volume = 0.3
		s.Parent = parent
		s:Play()
		game:GetService("Debris"):AddItem(s, 1)
	end)
end

local function hoverRow(row)
	row.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseMovement then
			TweenService:Create(row, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
		end
	end)
	row.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseMovement then
			TweenService:Create(row, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
		end
	end)
end

local function rgbToHsv(c)
	local r, g, b = c.R, c.G, c.B
	local mx = math.max(r, g, b)
	local mn = math.min(r, g, b)
	local d = mx - mn
	local h, s, v = 0, 0, mx
	if mx > 0 then s = d / mx end
	if d > 0 then
		if mx == r then h = ((g - b) / d) % 6
		elseif mx == g then h = (b - r) / d + 2
		else h = (r - g) / d + 4 end
		h = h / 6
		if h < 0 then h = h + 1 end
	end
	return h, s, v
end

local function rgbToHex(c)
	return string.format("%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

local function hexToRgb(s)
	s = string.gsub(string.gsub(tostring(s), "#", ""), "%s+", "")
	if string.len(s) ~= 6 then return nil end
	if string.match(s, "[^0-9a-fA-F]") then return nil end
	local r = tonumber(string.sub(s, 1, 2), 16)
	local g = tonumber(string.sub(s, 3, 4), 16)
	local b = tonumber(string.sub(s, 5, 6), 16)
	if not r or not g or not b then return nil end
	return Color3.fromRGB(r, g, b)
end

--// ---------- theme font registry (validated against live Enum; safe on old clients) ----------
local ValidFonts = {}
pcall(function()
	for _, e in ipairs(Enum.Font:GetEnumItems()) do
		if e.Name then ValidFonts[e.Name] = e end
	end
end)
local FONT_ORDER = { "Gotham", "Montserrat", "Roboto", "SourceSans", "Arial", "Ubuntu", "Inter", "FredokaOne" }
local THEME_HEADS = {
	Gotham = "GothamBold", Montserrat = "MontserratBold", Roboto = "RobotoBold",
	SourceSans = "SourceSansBold", Arial = "ArialBold", Ubuntu = "UbuntuBold",
	RobotoMono = "RobotoMono", Inter = "Inter", FredokaOne = "FredokaOne", Code = "Code",
}
local function resolveFont(name)
	return ValidFonts[name]
end

function VibeUI.FontChoices()
	local out = { "Default" }
	for _, n in ipairs(FONT_ORDER) do
		if ValidFonts[n] then table.insert(out, n) end
	end
	return out
end
-- Applies a picker color + transparency to a Drawing/UI object.
-- Pair it with the color picker: Callback = function(c, t) VibeUI.Paint(myBox, c, t) end
function VibeUI.Paint(inst, color, transp)
	if typeof(inst) ~= "Instance" then return end
	pcall(function() inst.Color = color end)
	if transp ~= nil then pcall(function() inst.Transparency = transp end) end
end

--// Opens a URL in the system browser when the executor exposes a launcher.
--// Returns "browser" (opened), "clipboard" (link copied instead) or "none".
--// Luau itself has no shell and Roblox has no browser API, so the launcher
--// names below are the ones executors are known to inject.
local LINK_LAUNCHERS = { "openbrowser", "openbrowserwindow", "open_url", "openurl", "open_web", "launchurl", "launch_url" }
function VibeUI.OpenLink(url)
	url = tostring(url or "")
	if url == "" then return "none" end
	local env = nil
	pcall(function() env = getgenv() end)
	for _, name in ipairs(LINK_LAUNCHERS) do
		local fn = nil
		if env then pcall(function() fn = env[name] end) end
		if type(fn) ~= "function" and type(_G[name]) == "function" then fn = _G[name] end
		if type(fn) == "function" then
			local ok, res = pcall(fn, url)
			if ok and res ~= false then return "browser" end
		end
	end
	if type(setclipboard) == "function" and pcall(setclipboard, url) then return "clipboard" end
	return "none"
end

--// ---------- Acrylic (Fluent-style: DoF + camera-tracked glass + frost) ----------
local Acrylic = {}
do
	local function viewportPointToWorld(location, distance)
		local cam = workspace.CurrentCamera
		if not cam then return Vector3.new(0, 0, 0) end
		local ray = cam:ScreenPointToRay(location.X, location.Y)
		return ray.Origin + ray.Direction * distance
	end
	local function getOffset()
		local cam = workspace.CurrentCamera
		local h = (cam and cam.ViewportSize.Y) or 800
		return (h - 0) * (56 - 8) / (2560 - 0) + 8
	end
	function Acrylic.ensureDoF()
		local li = game:GetService("Lighting")
		if li:FindFirstChild("AtheriumDoF") then return end
		local d = Instance.new("DepthOfFieldEffect")
		d.Name = "AtheriumDoF"
		d.FarIntensity = 0
		d.InFocusRadius = 0.1
		d.NearIntensity = 1
		d.Parent = li
	end
	function Acrylic.destroyDoF()
		local ex = game:GetService("Lighting"):FindFirstChild("AtheriumDoF")
		if ex then ex:Destroy() end
	end
	-- tracks a GuiObject rect with a glass part in front of the camera.
	-- opts.inset=false maps AbsolutePosition 1:1 (used by floating surfaces:
	-- panels + watermark). The main window keeps the tuned inset mapping.
	function Acrylic.track(guiObj, distance, opts)
		distance = distance or 0.001
		opts = opts or {}
		local blank = { setVisible = function() end, destroy = function() end }
		local cam = workspace.CurrentCamera
		if not cam then return blank end
		local folder = cam:FindFirstChild("AtheriumAcrylic")
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = "AtheriumAcrylic"
			folder.Parent = cam
		end
		local useInset = opts.inset ~= false
		local part = Instance.new("Part")
		part.Name = opts.name or "Surface"
		part.Color = Color3.new(0, 0, 0)
		part.Material = Enum.Material.Glass
		part.Size = Vector3.new(1, 1, 0)
		part.Anchored = true
		part.CanCollide = false
		part.CastShadow = false
		part.Transparency = 1
		part.CanQuery = false
		part.CanTouch = false
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Brick
		mesh.Offset = Vector3.new(0, 0, -0.000001)
		mesh.Parent = part
		part.Parent = folder
		-- note: ScreenPointToRay uses screen space, same as our
		-- IgnoreGuiInset gui, so no topbar inset compensation here
		local tl, tr, br = Vector2.new(), Vector2.new(), Vector2.new()
		local conns = {}
		local function render()
			local c = workspace.CurrentCamera
			if not c or not part.Parent then return end
			local cf = c.CFrame
			local tl3 = viewportPointToWorld(tl, distance)
			local tr3 = viewportPointToWorld(tr, distance)
			local br3 = viewportPointToWorld(br, distance)
			local w = (tr3 - tl3).Magnitude
			local hgt = (tr3 - br3).Magnitude
			if w < 0.001 or hgt < 0.001 then return end
			part.CFrame = CFrame.fromMatrix((tl3 + br3) / 2, cf.XVector, cf.YVector, cf.ZVector)
			mesh.Scale = Vector3.new(w, hgt, 0)
		end
		local function updateFromGui()
			if not guiObj.Parent then return end
			if useInset then
				local off = getOffset()
				local sz = guiObj.AbsoluteSize - Vector2.new(off, off)
				local ps = guiObj.AbsolutePosition + Vector2.new(off / 2, off / 2)
				tl = ps
				tr = ps + Vector2.new(sz.X, 0)
				br = ps + sz
			else
				local sz = guiObj.AbsoluteSize
				tl = guiObj.AbsolutePosition
				tr = tl + Vector2.new(sz.X, 0)
				br = tl + sz
			end
			render()
		end
		table.insert(conns, cam:GetPropertyChangedSignal("CFrame"):Connect(render))
		table.insert(conns, cam:GetPropertyChangedSignal("ViewportSize"):Connect(render))
		table.insert(conns, cam:GetPropertyChangedSignal("FieldOfView"):Connect(render))
		table.insert(conns, guiObj:GetPropertyChangedSignal("AbsolutePosition"):Connect(updateFromGui))
		table.insert(conns, guiObj:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateFromGui))
		table.insert(conns, guiObj:GetPropertyChangedSignal("Position"):Connect(updateFromGui))
		table.insert(conns, guiObj:GetPropertyChangedSignal("Size"):Connect(updateFromGui))
		updateFromGui()
		local dead = false
		return {
			setVisible = function(v)
				if not dead and part.Parent then
					part.Transparency = v and 0.98 or 1
				end
			end,
			destroy = function()
				dead = true
				for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
				pcall(function() part:Destroy() end)
				if folder and #folder:GetChildren() == 0 then pcall(function() folder:Destroy() end) end
			end,
		}
	end
end

--// ================= SECTION =================
local Section = {}
Section.__index = Section

function Section:AddToggle(opts)
	local win = self._win
	local name = opts.Name or "Toggle"
	local default = opts.Default or false
	local callback = opts.Callback or function() end

	local row = Instance.new("Frame")
	row.Name = "Row_" .. name
	row.Size = UDim2.new(1, 0, 0, 38)
	row.BackgroundColor3 = BG_HOVER
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.Parent = self._body
	row.LayoutOrder = #self._body:GetChildren()
	corner(row, 6)
	hoverRow(row)
	win._registerRow(row, name, self)
	if opts.Tooltip then win:_attachTip(row, opts.Tooltip) end

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -64, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = TXT_MAIN
	label.Text = name
	label.Parent = row
	win:ThemeRegister(label, "text")

	local box = Instance.new("TextButton")
	box.Name = "Check"
	box.Size = UDim2.new(0, 20, 0, 20)
	box.AnchorPoint = Vector2.new(1, 0.5)
	box.Position = UDim2.new(1, -10, 0.5, 0)
	box.BackgroundColor3 = BG_TRACK
	box.Text = ""
	box.AutoButtonColor = false
	box.ClipsDescendants = true
	box.Parent = row
	corner(box, 6)
	stroke(box, Color3.fromRGB(58, 58, 70), 0, 1)

	local fill = Instance.new("Frame")
	fill.AnchorPoint = Vector2.new(0.5, 0.5)
	fill.Position = UDim2.new(0.5, 0, 0.5, 0)
	fill.Size = UDim2.new(0, 0, 0, 0)
	fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	fill.BorderSizePixel = 0
	fill.Parent = box
	corner(fill, 4)
	local fillGrad = Instance.new("UIGradient")
	fillGrad.Rotation = 90
	fillGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(199, 199, 209)),
	})
	fillGrad.Parent = fill
	win._reg(function(c)
		pcall(function()
			if fill.Parent then
				TweenService:Create(fill, TweenInfo.new(0.25), {BackgroundColor3 = c}):Play()
			end
		end)
	end)

	local check = makeIcon(box, "check", 13, Color3.fromRGB(9, 9, 11), UDim2.new(0.5, 0, 0.5, 0), Vector2.new(0.5, 0.5))
	check.ImageTransparency = 1
	check.Size = UDim2.new(0, 8, 0, 8)

	local state = default and true or false
	local function paint(instant)
		if instant then
			fill.Size = state and UDim2.new(1, 0, 1, 0) or UDim2.new(0, 0, 0, 0)
			check.ImageTransparency = state and 0 or 1
			check.Size = UDim2.new(0, state and 13 or 8, 0, state and 13 or 8)
		else
			if state then
				TweenService:Create(fill, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 1, 0)}):Play()
				task.delay(0.12, function()
					if not box.Parent then return end
					TweenService:Create(check, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {ImageTransparency = 0, Size = UDim2.new(0, 13, 0, 13)}):Play()
				end)
			else
				TweenService:Create(check, TweenInfo.new(0.12), {ImageTransparency = 1, Size = UDim2.new(0, 8, 0, 8)}):Play()
				TweenService:Create(fill, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)}):Play()
			end
		end
	end
	paint(true)

	local obj = {}
	obj._name = name
	function obj:Get() return state end
	function obj:Set(v, fire) state = not not v paint(false) if fire then pcall(callback, state) end win._refreshKeyList() end
	table.insert(win._cfg, { kind = "toggle", tab = self._tab._name, sec = self._title or "?", name = name, get = function() return obj:Get() end, set = function(v) obj:Set(v, true) end })
	box.MouseButton1Click:Connect(function()
		state = not state
		win._dirty = true
		paint(false)
		win._refreshKeyList()
		clickSound(win._gui, function() return win._sounds end)
		pcall(callback, state)
		print(string.format("[ATHERIUM] toggle '%s' -> %s", name, tostring(state)))
	end)
	pcall(callback, state)
	return obj
end

function Section:AddSlider(opts)
	local win = self._win
	local name = opts.Name or "Slider"
	local min = tonumber(opts.Min) or 0
	local max = tonumber(opts.Max) or 100
	if max <= min then max = min + 1 end
	local default = tonumber(opts.Default) or ((min + max) / 2)
	local callback = opts.Callback or function() end

	local row = Instance.new("Frame")
	row.Name = "Row_" .. name
	row.Size = UDim2.new(1, 0, 0, 48)
	row.BackgroundColor3 = BG_HOVER
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.Parent = self._body
	row.LayoutOrder = #self._body:GetChildren()
	corner(row, 6)
	win._registerRow(row, name, self)
	if opts.Tooltip then win:_attachTip(row, opts.Tooltip) end

	local label = Instance.new("TextLabel")
	label.Name = "Title"
	label.Size = UDim2.new(1, -92, 0, 16)
	label.Position = UDim2.new(0, 12, 0, 8)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = TXT_MAIN
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Text = name
	label.Parent = row
	win:ThemeRegister(label, "text")

	-- right slot: fixed 64px, monospace digits, right aligned. Every slider
	-- reserves the same slot so rows line up; ShowValue = false drops the slot
	-- entirely instead of leaving an empty hole.
	local showValue = opts.ShowValue ~= false
	local vlab
	if showValue then
		vlab = Instance.new("TextLabel")
		vlab.Name = "Value"
		vlab.Size = UDim2.new(0, 64, 0, 16)
		vlab.AnchorPoint = Vector2.new(1, 0)
		vlab.Position = UDim2.new(1, -12, 0, 8)
		vlab.BackgroundTransparency = 1
		vlab.Font = Enum.Font.Code
		vlab.TextSize = 12
		vlab.TextXAlignment = Enum.TextXAlignment.Right
		vlab.TextColor3 = TXT_SOFT
		vlab.Text = "0"
		vlab.Parent = row
		win:ThemeRegister(vlab, "sub")
	end
	-- keep an 8px channel between the title and the value slot
	label.Size = UDim2.new(1, showValue and -92 or -24, 0, 16)

	local track = Instance.new("TextButton")
	track.Name = "Track"
	track.Size = UDim2.new(1, -24, 0, 22)
	track.Position = UDim2.new(0, 12, 0, 24)
	track.BackgroundTransparency = 1
	track.Text = ""
	track.AutoButtonColor = false
	track.Parent = row

	-- flat track: one 5px capsule. No glow stack, no dark sleeve around the
	-- active part -- just a clean rounded line and an even fill.
	local rail = Instance.new("Frame")
	rail.Name = "Rail"
	rail.Size = UDim2.new(1, 0, 0, 5)
	rail.Position = UDim2.new(0, 0, 0.5, -2.5)
	rail.BackgroundColor3 = Color3.fromRGB(54, 54, 62)
	rail.BorderSizePixel = 0
	rail.ClipsDescendants = true
	rail.Parent = track
	corner(rail, 3)

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(0, 0, 1, 0)
	-- slightly off-white: pure #FFFFFF bloomed against the dark rail
	fill.BackgroundColor3 = Color3.fromRGB(231, 231, 240)
	fill.BorderSizePixel = 0
	fill.Parent = rail
	corner(fill, 3)
	win._reg(function(c)
		pcall(function()
			if fill.Parent then
				-- the shipped accent is pure white; pull it a touch toward the
				-- slate so the active part does not bloom over the rail
				local tinted = c:Lerp(Color3.fromRGB(150, 150, 168), 0.1)
				TweenService:Create(fill, TweenInfo.new(0.25), { BackgroundColor3 = tinted }):Play()
			end
		end)
	end)

	-- thumb: exactly one capsule + one hairline rim. The depth comes from the
	-- capsule's own gradient, not from stacked halos or a fake shadow.
	local thumb = Instance.new("Frame")
	thumb.Name = "Thumb"
	thumb.AnchorPoint = Vector2.new(0.5, 0.5)
	thumb.Position = UDim2.new(0, 0, 0.5, 0)
	thumb.Size = UDim2.new(0, 10, 0, 14)
	thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	thumb.BorderSizePixel = 0
	thumb.ZIndex = 4
	thumb.Parent = track
	corner(thumb, 5)
	local thumbGrad = Instance.new("UIGradient")
	thumbGrad.Rotation = 90
	thumbGrad.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(243, 243, 249))
	thumbGrad.Parent = thumb
	-- neutral 1px edge: visible against both the white fill and the dark rail,
	-- so the capsule reads as one even glass rim instead of a top-only shine
	local thumbRim = Instance.new("UIStroke")
	thumbRim.Color = Color3.fromRGB(222, 222, 232)
	thumbRim.Thickness = 1
	thumbRim.Transparency = 0.4
	thumbRim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	thumbRim.Parent = thumb

	local value = default
	local lastInt = math.floor(default + 0.5)
	local dragging = false
	local hover = false
	local RAIL_DIM = Color3.fromRGB(54, 54, 62)
	local RAIL_HOT = Color3.fromRGB(68, 68, 78)

	local function fmtVal(v)
		local span = max - min
		if span <= 5 then return string.format("%.2f", v) end
		if span <= 20 then return string.format("%.1f", v) end
		return tostring(math.floor(v + 0.5))
	end

	-- the number sits still and only gains brightness while in use, so two
	-- rows never disagree about alignment
	local function toneVal(hot)
		if not vlab then return end
		TweenService:Create(vlab, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextColor3 = hot and TXT_MAIN or TXT_SOFT,
		}):Play()
	end

	-- squash: idle capsule -> slightly taller on hover -> flattened and
	-- stretched while dragging, then a springy return on release
	local THUMB = {
		idle = { w = 10, h = 14, dur = 0.46, style = Enum.EasingStyle.Back },
		hover = { w = 12, h = 16, dur = 0.26, style = Enum.EasingStyle.Quad },
		drag = { w = 14, h = 9, dur = 0.22, style = Enum.EasingStyle.Quad },
	}
	local squashState = "idle"
	local function squash(mode)
		mode = THUMB[mode] and mode or "idle"
		if squashState == mode then return end
		squashState = mode
		local p = THUMB[mode]
		TweenService:Create(thumb, TweenInfo.new(p.dur, p.style, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, p.w, 0, p.h),
		}):Play()
	end

	local function setActive(on)
		local hot = on or dragging
		TweenService:Create(rail, TweenInfo.new(0.22), { BackgroundColor3 = hot and RAIL_HOT or RAIL_DIM }):Play()
		toneVal(hot)
	end

	local function place(a, instant)
		-- Y must stay at 0.5: a plain UDim2.new(a,0,0,0) parks the thumb at
		-- the top edge of the track instead of riding the rail
		local px = UDim2.new(a, 0, 0.5, 0)
		if instant or dragging then
			fill.Size = UDim2.new(a, 0, 1, 0)
			thumb.Position = px
		else
			TweenService:Create(fill, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(a, 0, 1, 0) }):Play()
			TweenService:Create(thumb, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = px }):Play()
		end
	end

	local function apply(v, fire, instant)
		value = math.clamp(tonumber(v) or value, min, max)
		if fire then win._dirty = true end
		local a = (value - min) / math.max(1e-6, (max - min))
		local txt = fmtVal(value)
		if vlab then vlab.Text = txt end
		place(a, instant)
		local iv = math.floor(value + 0.5)
		if fire then
			if iv ~= lastInt then
				lastInt = iv
				print(string.format("[ATHERIUM] slider '%s' -> %s", name, txt))
			end
			pcall(callback, value)
		end
	end

	apply(default, false, true)

	local function posToVal(x)
		local w = math.max(1, rail.AbsoluteSize.X)
		return min + (max - min) * math.clamp((x - rail.AbsolutePosition.X) / w, 0, 1)
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			squash("drag")
			setActive(true)
			apply(posToVal(input.Position.X), true, true)
		end
	end)
	track.MouseEnter:Connect(function()
		if dragging then return end
		hover = true
		setActive(true)
		squash("hover")
	end)
	track.MouseLeave:Connect(function()
		hover = false
		if dragging then return end
		squash("idle")
		setActive(false)
	end)
	local dragConn, endConn
	dragConn = UserInputService.InputChanged:Connect(function(input)
		if not row.Parent then dragConn:Disconnect() return end
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			apply(posToVal(input.Position.X), true, true)
		end
	end)
	endConn = UserInputService.InputEnded:Connect(function(input)
		if not row.Parent then endConn:Disconnect() return end
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		dragging = false
		squash(hover and "hover" or "idle")
		setActive(hover)
	end)
	rail:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		local a = (value - min) / math.max(1e-6, (max - min))
		place(a, true)
	end)

	local obj = {}
	function obj:Get() return value end
	function obj:Set(v) apply(v, true, false) end
	table.insert(win._cfg, { kind = "slider", tab = self._tab._name, sec = self._title or "?", name = name, get = function() return obj:Get() end, set = function(v) obj:Set(tonumber(v) or value) end })
	pcall(callback, value)
	return obj
end

function Section:AddButton(opts)
	local win = self._win
	local name = opts.Name or "Button"
	local icon = opts.Icon or "zap"
	local callback = opts.Callback or function() end
	local dark = (opts.Style == "dark")
	local h = math.clamp(tonumber(opts.Height) or 36, 20, 60)
	local btn = Instance.new("TextButton")
	btn.Name = "Row_" .. name
	btn.Size = UDim2.new(1, 0, 0, h)
	btn.BackgroundColor3 = dark and Color3.fromRGB(30, 30, 34) or Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.TextColor3 = dark and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(9, 9, 11)
	btn.Text = "    " .. name
	btn.AutoButtonColor = false
	btn.Parent = self._body
	btn.LayoutOrder = #self._body:GetChildren()
	corner(btn, 8)
	if dark then stroke(btn, Color3.fromRGB(39, 39, 42), 0, 1) end
	win._registerRow(btn, name, self)
	if opts.Tooltip then win:_attachTip(btn, opts.Tooltip) end
	makeIcon(btn, icon, 14, dark and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(9, 9, 11), UDim2.new(0, 12, 0.5, -7))
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = dark and Color3.fromRGB(45, 45, 53) or Color3.fromRGB(215, 215, 222)}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = dark and Color3.fromRGB(30, 30, 34) or Color3.fromRGB(255, 255, 255)}):Play()
	end)
	btn.MouseButton1Click:Connect(function()
		clickSound(win._gui, function() return win._sounds end)
		TweenService:Create(btn, TweenInfo.new(0.07), {Size = UDim2.new(1, -6, 0, h - 2)}):Play()
		task.wait(0.07)
		TweenService:Create(btn, TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, h)}):Play()
		pcall(callback)
		print(string.format("[ATHERIUM] button '%s' clicked", name))
	end)
	return btn
end

function Section:AddDropdown(opts)
	local win = self._win
	local name = opts.Name or "Dropdown"
	local options = {}
	for i, o in ipairs(opts.Options or { "Option 1", "Option 2" }) do options[i] = tostring(o) end
	local multiple = opts.Multiple == true
	local allowSearch = opts.Search ~= false and #options > 6
	local callback = opts.Callback or function() end

	local row = Instance.new("TextButton")
	row.Name = "Row_" .. name
	row.Size = UDim2.new(1, 0, 0, 38)
	row.BackgroundColor3 = BG_HOVER
	row.BackgroundTransparency = 1
	row.Text = ""
	row.AutoButtonColor = false
	row.Parent = self._body
	row.LayoutOrder = #self._body:GetChildren()
	corner(row, 6)
	hoverRow(row)
	win._registerRow(row, name, self)
	if opts.Tooltip then win:_attachTip(row, opts.Tooltip) end

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -130, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = TXT_MAIN
	label.Text = name
	label.Parent = row
	win:ThemeRegister(label, "text")

	local trigger = Instance.new("TextButton")
	trigger.Name = "Trigger"
	trigger.Size = UDim2.new(0, 110, 0, 28)
	trigger.AnchorPoint = Vector2.new(1, 0.5)
	trigger.Position = UDim2.new(1, -10, 0.5, 0)
	trigger.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
	trigger.Text = ""
	trigger.AutoButtonColor = false
	trigger.Parent = row
	corner(trigger, 4)
	stroke(trigger, Color3.fromRGB(39, 39, 42), 0, 1)
	trigger.MouseEnter:Connect(function()
		TweenService:Create(trigger, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(36, 36, 43)}):Play()
	end)
	trigger.MouseLeave:Connect(function()
		TweenService:Create(trigger, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(26, 26, 30)}):Play()
	end)

	local cur = Instance.new("TextLabel")
	cur.Name = "Value"
	cur.Size = UDim2.new(1, -32, 1, 0)
	cur.Position = UDim2.new(0, 10, 0, 0)
	cur.BackgroundTransparency = 1
	cur.Font = Enum.Font.Gotham
	cur.TextSize = 12
	cur.TextXAlignment = Enum.TextXAlignment.Left
	cur.TextTruncate = Enum.TextTruncate.AtEnd
	cur.TextColor3 = TXT_MAIN
	cur.Text = ""
	cur.Parent = trigger
	win:ThemeRegister(cur, "text")
	local chev = makeIcon(trigger, "chevron-down", 13, ICON_FAINT, UDim2.new(1, -20, 0.5, -6))

	local list = Instance.new("Frame")
	list.Name = "Drop_" .. name
	list.Size = UDim2.new(1, 0, 0, 0)
	list.BackgroundTransparency = 1
	list.ClipsDescendants = true
	list.Visible = false
	list.Parent = self._body
	list.LayoutOrder = #self._body:GetChildren()
	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(0, 200, 1, 0)
	panel.AnchorPoint = Vector2.new(1, 0)
	panel.Position = UDim2.new(1, 0, 0, 0)
	panel.BackgroundColor3 = Color3.fromRGB(13, 13, 16)
	panel.BorderSizePixel = 0
	panel.Parent = list
	corner(panel, 8)
	stroke(panel, LINE, 0, 1)
	win._glass(panel, 0.3)
	local ppad = Instance.new("UIPadding")
	ppad.PaddingTop = UDim.new(0, 4)
	ppad.PaddingBottom = UDim.new(0, 4)
	ppad.PaddingLeft = UDim.new(0, 4)
	ppad.PaddingRight = UDim.new(0, 4)
	ppad.Parent = panel
	local play = Instance.new("UIListLayout")
	play.Padding = UDim.new(0, 4)
	play.SortOrder = Enum.SortOrder.LayoutOrder
	play.Parent = panel

	-- optional search field, only worth it on long lists
	local searchInput
	if allowSearch then
		local sbox = Instance.new("Frame")
		sbox.Name = "SearchBox"
		sbox.Size = UDim2.new(1, 0, 0, 26)
		sbox.LayoutOrder = 1
		sbox.BackgroundColor3 = BG_HOVER
		sbox.BorderSizePixel = 0
		sbox.Parent = panel
		corner(sbox, 5)
		makeIcon(sbox, "search", 11, ICON_FAINT, UDim2.new(0, 7, 0.5, -5))
		searchInput = Instance.new("TextBox")
		searchInput.Name = "Search"
		searchInput.Size = UDim2.new(1, -26, 1, 0)
		searchInput.Position = UDim2.new(0, 22, 0, 0)
		searchInput.BackgroundTransparency = 1
		searchInput.Font = Enum.Font.Gotham
		searchInput.TextSize = 12
		searchInput.TextXAlignment = Enum.TextXAlignment.Left
		searchInput.TextColor3 = TXT_MAIN
		searchInput.PlaceholderText = "Search"
		searchInput.PlaceholderColor3 = TXT_FAINT
		searchInput.Text = ""
		searchInput.ClearTextOnFocus = false
		searchInput.Parent = sbox
		win:ThemeRegister(searchInput, "text")
	end

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Options"
	scroll.Size = UDim2.new(1, 0, 0, 0)
	scroll.LayoutOrder = 2
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.ScrollBarThickness = 2
	scroll.ScrollBarImageColor3 = Color3.fromRGB(58, 58, 68)
	scroll.ElasticBehavior = Enum.ElasticBehavior.Never
	scroll.Parent = panel
	local olay = Instance.new("UIListLayout")
	olay.Padding = UDim.new(0, 2)
	olay.SortOrder = Enum.SortOrder.LayoutOrder
	olay.Parent = scroll

	-- footer actions, only useful with multiple selection
	local footer
	if multiple then
		footer = Instance.new("Frame")
		footer.Name = "Footer"
		footer.Size = UDim2.new(1, 0, 0, 22)
		footer.LayoutOrder = 3
		footer.BackgroundTransparency = 1
		footer.Parent = panel
		local function mkAction(text, order, fn)
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(0.5, -2, 1, 0)
			b.Position = UDim2.new(order == 1 and 0 or 0.5, order == 1 and 0 or 2, 0, 0)
			b.BackgroundColor3 = BG_HOVER
			b.BackgroundTransparency = 1
			b.Font = Enum.Font.Gotham
			b.TextSize = 11
			b.TextColor3 = TXT_SOFT
			b.Text = text
			b.AutoButtonColor = false
			b.Parent = footer
			corner(b, 4)
			b.MouseEnter:Connect(function()
				TweenService:Create(b, TweenInfo.new(0.12), {BackgroundTransparency = 0, TextColor3 = win:_tc("text")}):Play()
			end)
			b.MouseLeave:Connect(function()
				TweenService:Create(b, TweenInfo.new(0.15), {BackgroundTransparency = 1, TextColor3 = win:_tc("sub")}):Play()
			end)
			b.MouseButton1Click:Connect(fn)
			return b
		end
		local allBtn = mkAction("Select all", 1, function() end)
		local noneBtn = mkAction("Clear", 2, function() end)
		footer._all = allBtn
		footer._none = noneBtn
	end

	local selected = {}
	local current = nil
	local close, obj
	if multiple then
		if type(opts.Default) == "table" then
			for _, v in ipairs(opts.Default) do selected[tostring(v)] = true end
		end
	else
		current = tostring(opts.Default or options[1] or "")
	end
	local filter = ""
	local optBtns = {}

	local function countSelected()
		local n = 0
		for _ in pairs(selected) do n = n + 1 end
		return n
	end

	local function summary()
		if not multiple then return tostring(current or "") end
		local n = countSelected()
		if n == 0 then return "None" end
		if n == 1 then
			for k in pairs(selected) do return k end
		end
		return n .. " selected"
	end

	local function refreshTrigger()
		cur.Text = summary()
	end

	local function isSelected(o)
		if multiple then return selected[o] == true end
		return current == o
	end

	local function visibleOptions()
		if filter == "" then return options end
		local out = {}
		local needle = string.lower(filter)
		for _, o in ipairs(options) do
			if string.find(string.lower(o), needle, 1, true) then table.insert(out, o) end
		end
		return out
	end

	local FULL_H = 0
	local function measure()
		local shown = #visibleOptions()
		local rows = math.clamp(shown, 1, 8)
		scroll.Size = UDim2.new(1, 0, 0, rows * 30 + math.max(0, shown - 1) * 2)
		FULL_H = 8 + rows * 30 + math.max(0, rows - 1) * 2
		if allowSearch then FULL_H = FULL_H + 30 end
		if multiple then FULL_H = FULL_H + 26 end
		if list.Visible then list.Size = UDim2.new(1, 0, 0, FULL_H) end
	end

	local function paint()
		for _, o in pairs(optBtns) do
			local sel = isSelected(o.name)
			o.chk.Visible = sel
			o.btn.TextColor3 = sel and win:_tc("text") or win:_tc("sub")
			o.btn.BackgroundTransparency = sel and 0 or 1
		end
	end

	local function pick(o)
		if multiple then
			if selected[o] then selected[o] = nil else selected[o] = true end
			win._dirty = true
			refreshTrigger()
			paint()
			clickSound(win._gui, function() return win._sounds end)
			pcall(callback, obj:Get())
			print(string.format("[ATHERIUM] dropdown '%s' -> %d selected", name, countSelected()))
		else
			current = o
			win._dirty = true
			refreshTrigger()
			paint()
			close()
			clickSound(win._gui, function() return win._sounds end)
			pcall(callback, o)
			print(string.format("[ATHERIUM] dropdown '%s' -> %s", name, tostring(o)))
		end
	end

	local function buildOptions()
		for _, ch in ipairs(scroll:GetChildren()) do
			if ch:IsA("TextButton") then ch:Destroy() end
		end
		for k in pairs(optBtns) do optBtns[k] = nil end
		local shown = visibleOptions()
		for oidx, opt in ipairs(shown) do
			local b = Instance.new("TextButton")
			b.Name = "Opt_" .. tostring(opt)
			b.LayoutOrder = oidx
			b.Size = UDim2.new(1, -2, 0, 30)
			b.BackgroundColor3 = BG_HOVER
			b.BackgroundTransparency = 1
			b.Font = Enum.Font.Gotham
			b.TextSize = 12
			b.TextColor3 = TXT_DIM
			b.TextXAlignment = Enum.TextXAlignment.Left
			b.TextTruncate = Enum.TextTruncate.AtEnd
			b.Text = tostring(opt)
			b.AutoButtonColor = false
			b.Parent = scroll
			corner(b, 6)
			local bpad = Instance.new("UIPadding")
			bpad.PaddingLeft = UDim.new(0, 12)
			bpad.PaddingRight = UDim.new(0, 26)
			bpad.Parent = b
			b.BackgroundTransparency = isSelected(opt) and 0 or 1
			b.TextColor3 = isSelected(opt) and win:_tc("text") or win:_tc("sub")
			b.MouseEnter:Connect(function()
				TweenService:Create(b, TweenInfo.new(0.12), {BackgroundTransparency = 0}):Play()
			end)
			b.MouseLeave:Connect(function()
				TweenService:Create(b, TweenInfo.new(0.15), {BackgroundTransparency = isSelected(opt) and 0 or 1}):Play()
			end)
			local chk = makeIcon(b, "check", 12, TXT_MAIN, UDim2.new(1, -22, 0.5, -6))
			chk.Visible = isSelected(opt)
			optBtns[opt] = { btn = b, chk = chk, name = opt }
			b.MouseButton1Click:Connect(function() pick(opt) end)
		end
		measure()
	end

	local anim = nil
	local function open()
		if anim then anim:Cancel() end
		if searchInput then searchInput.Text = "" end
		filter = ""
		buildOptions()
		list.Visible = true
		list.Size = UDim2.new(1, 0, 0, 0)
		TweenService:Create(chev, TweenInfo.new(0.2), {Rotation = 180}):Play()
		anim = TweenService:Create(list, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, FULL_H)})
		anim:Play()
	end
	close = function()
		if anim then anim:Cancel() end
		TweenService:Create(chev, TweenInfo.new(0.15), {Rotation = 0}):Play()
		anim = TweenService:Create(list, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Size = UDim2.new(1, 0, 0, 0)})
		local mine = anim
		mine.Completed:Connect(function()
			if anim == mine then list.Visible = false end
		end)
		anim:Play()
	end
	table.insert(win._dropLists, { list = list, chev = chev })

	if searchInput then
		searchInput:GetPropertyChangedSignal("Text"):Connect(function()
			filter = searchInput.Text or ""
			buildOptions()
		end)
		searchInput.FocusLost:Connect(function(enter)
			if not enter then return end
			local shown = visibleOptions()
			if shown[1] then pick(shown[1]) end
		end)
	end

	if footer then
		footer._all.MouseButton1Click:Connect(function()
			for _, o in ipairs(options) do selected[o] = true end
			win._dirty = true
			refreshTrigger()
			buildOptions()
			pcall(callback, obj:Get())
		end)
		footer._none.MouseButton1Click:Connect(function()
			selected = {}
			win._dirty = true
			refreshTrigger()
			buildOptions()
			pcall(callback, obj:Get())
		end)
	end

	local function toggleList()
		if list.Visible then close() else open() end
	end
	row.MouseButton1Click:Connect(toggleList)
	trigger.MouseButton1Click:Connect(toggleList)

	obj = {}
	function obj:Get()
		if not multiple then return current end
		local out = {}
		for _, o in ipairs(options) do
			if selected[o] then table.insert(out, o) end
		end
		return out
	end
	function obj:Set(v, fire)
		if multiple then
			selected = {}
			if type(v) == "table" then
				for _, x in ipairs(v) do selected[tostring(x)] = true end
			elseif v ~= nil then
				selected[tostring(v)] = true
			end
			if fire then win._dirty = true end
			refreshTrigger()
			if list.Visible then buildOptions() else measure() end
			if fire ~= false then pcall(callback, obj:Get()) end
			return
		end
		local key = tostring(v)
		if v == nil or not table.find(options, key) then return end
		current = key
		refreshTrigger()
		if list.Visible then buildOptions() else measure() end
		if fire ~= false then pcall(callback, key) end
	end
	function obj:SetOptions(newOpts)
		options = {}
		for i, o in ipairs(newOpts or {}) do options[i] = tostring(o) end
		if multiple then
			local keep = {}
			for _, o in ipairs(options) do
				if selected[o] then keep[o] = true end
			end
			selected = keep
		else
			if not table.find(options, tostring(current)) then current = options[1] or "" end
		end
		refreshTrigger()
		buildOptions()
	end
	function obj:IsMultiple() return multiple end
	function obj:Open() if not list.Visible then open() end end
	function obj:Close() if list.Visible then close() end end
	refreshTrigger()
	measure()
	if not opts.NoSave then
		table.insert(win._cfg, { kind = "dropdown", tab = self._tab._name, sec = self._title or "?", name = name, get = function() return obj:Get() end, set = function(v) obj:Set(v, true) end })
	end
	pcall(callback, obj:Get())
	return obj
end

function Section:AddTextBox(opts)
	local win = self._win
	local name = opts.Name or "Input"
	local default = opts.Default or ""
	local ph = opts.Placeholder or "Enter text..."
	local callback = opts.Callback or function() end

	local row = Instance.new("Frame")
	row.Name = "Row_" .. name
	row.Size = UDim2.new(1, 0, 0, 38)
	row.BackgroundColor3 = BG_HOVER
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.Parent = self._body
	row.LayoutOrder = #self._body:GetChildren()
	corner(row, 6)
	hoverRow(row)
	win._registerRow(row, name, self)
	if opts.Tooltip then win:_attachTip(row, opts.Tooltip) end

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -170, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = TXT_MAIN
	label.Text = name
	label.Parent = row
	win:ThemeRegister(label, "text")

	local box = Instance.new("TextBox")
	box.Name = "Input"
	box.Size = UDim2.new(0, 150, 0, 26)
	box.AnchorPoint = Vector2.new(1, 0.5)
	box.Position = UDim2.new(1, -10, 0.5, 0)
	box.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
	box.Font = Enum.Font.Gotham
	box.TextSize = 12
	box.TextColor3 = TXT_MAIN
	box.PlaceholderColor3 = TXT_FAINT
	box.PlaceholderText = ph
	box.Text = tostring(default)
	box.ClearTextOnFocus = false
	box.Parent = row
	corner(box, 6)
	stroke(box, Color3.fromRGB(39, 39, 42), 0, 1)
	box.Focused:Connect(function()
		TweenService:Create(box, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(34, 34, 41)}):Play()
	end)
	box.FocusLost:Connect(function(enter)
		TweenService:Create(box, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(26, 26, 30)}):Play()
		if enter then
			win._dirty = true
			pcall(callback, box.Text)
			print(string.format("[ATHERIUM] input '%s' -> %s", name, tostring(box.Text)))
		end
	end)

	local obj = {}
	function obj:Get() return box.Text end
	function obj:Set(v, fire) box.Text = tostring(v ~= nil and v or "") if fire then pcall(callback, box.Text) end end
	if not opts.NoSave then
		table.insert(win._cfg, { kind = "text", tab = self._tab._name, sec = self._title or "?", name = name, get = function() return obj:Get() end, set = function(v) obj:Set(v, true) end })
	end
	return obj
end

-- HSV color picker: SV canvas + hue/sat/alpha strips + HEX input, all live, no Done button.
-- Callback(color, transparency). Feed both into your visuals, e.g. via VibeUI.Paint.
function Section:AddColorPicker(opts)
	local win = self._win
	local name = opts.Name or "Color"
	local default = opts.Default or Color3.fromRGB(255, 255, 255)
	local callback = opts.Callback or function() end
	local transp = math.clamp(tonumber(opts.Transparency) or 0, 0, 1)

	local row = Instance.new("Frame")
	row.Name = "Row_" .. name
	row.Size = UDim2.new(1, 0, 0, 38)
	row.BackgroundColor3 = BG_HOVER
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.Parent = self._body
	row.LayoutOrder = #self._body:GetChildren()
	corner(row, 6)
	hoverRow(row)
	win._registerRow(row, name, self)
	if opts.Tooltip then win:_attachTip(row, opts.Tooltip) end

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -56, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = TXT_MAIN
	label.Text = name
	label.Parent = row
	win:ThemeRegister(label, "text")

	-- swatch: checkerboard under the colour, so alpha reads as alpha instead
	-- of fading the chip into the row behind it
	local swWrap = Instance.new("Frame")
	swWrap.Name = "Swatch"
	swWrap.Size = UDim2.new(0, 20, 0, 18)
	swWrap.AnchorPoint = Vector2.new(1, 0.5)
	swWrap.Position = UDim2.new(1, -10, 0.5, 0)
	swWrap.BackgroundColor3 = Color3.fromRGB(44, 44, 52)
	swWrap.BorderSizePixel = 0
	swWrap.ClipsDescendants = true
	swWrap.Parent = row
	corner(swWrap, 7)
	checkerFill(swWrap, 20, 18, 3, 7, 1, Color3.fromRGB(55, 55, 64))

	local sw = Instance.new("TextButton")
	sw.Name = "Fill"
	sw.Size = UDim2.new(1, 0, 1, 0)
	sw.BackgroundColor3 = default
	sw.BackgroundTransparency = transp
	sw.Text = ""
	sw.AutoButtonColor = false
	sw.ZIndex = 2
	sw.Parent = swWrap
	corner(sw, 7)
	stroke(sw, Color3.fromRGB(255, 255, 255), 0.85, 1)

	local h, s, v = rgbToHsv(default)
	local color = default
	local popup = nil
	local live = nil -- refreshed by popup internals
	local outsideConn = nil

	local function fire()
		win._dirty = true
		sw.BackgroundColor3 = color
		sw.BackgroundTransparency = transp
		if live then live() end
		pcall(callback, color, transp)
	end

	local function closePopup(animated)
		if outsideConn then pcall(function() outsideConn:Disconnect() end) outsideConn = nil end
		if popup then
			local p = popup
			popup = nil live = nil
			if animated == false then
				pcall(function() p:Destroy() end)
			else
				pcall(function()
					local tw = TweenService:Create(p, TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Size = UDim2.new(0, 150, 0, 176), BackgroundTransparency = 1})
					tw:Play()
					tw.Completed:Connect(function() pcall(function() p:Destroy() end) end)
				end)
			end
		end
	end

	sw.MouseButton1Click:Connect(function()
		clickSound(win._gui, function() return win._sounds end)
		if popup and not popup.Parent then popup = nil live = nil end
		if popup then closePopup() return end

		h, s, v = rgbToHsv(color)
		popup = Instance.new("Frame")
		popup.Name = "ColorPopup"
		popup.Size = UDim2.new(0, 150, 0, 176)
		popup.AnchorPoint = Vector2.new(0, 0)
		do
			local popW, popH = 176, 202
			local px, py = 0, 0
			pcall(function()
				local mp = win._main.AbsolutePosition
				local ms = win._main.AbsoluteSize
				local rp = row.AbsolutePosition
				local rs = row.AbsoluteSize
				px = rp.X - mp.X + rs.X - popW - 8
				py = rp.Y - mp.Y + rs.Y + 6
				px = math.clamp(px, 8, math.max(8, ms.X - popW - 8))
				py = math.clamp(py, 60, math.max(60, ms.Y - popH - 8))
			end)
			popup.Position = UDim2.new(0, px, 0, py)
		end
		popup.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
		popup.BackgroundTransparency = 1
		popup.BorderSizePixel = 0
		popup.ZIndex = 50
		popup.Parent = win._main
		corner(popup, 12)
		stroke(popup, LINE, 0, 1)
		local popScale = Instance.new("UIScale")
		popScale.Scale = 0.92
		popScale.Parent = popup
		TweenService:Create(popup, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 176, 0, 202), BackgroundTransparency = 0}):Play()
		TweenService:Create(popScale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
		local Z = 51
		local function zw(inst, z)
			inst.ZIndex = z or Z
			return inst
		end

		local pt = Instance.new("TextLabel")
		pt.Size = UDim2.new(1, -38, 0, 18)
		pt.Position = UDim2.new(0, 10, 0, 7)
		pt.BackgroundTransparency = 1
		pt.Font = Enum.Font.GothamBold
		pt.TextSize = 12
		pt.TextXAlignment = Enum.TextXAlignment.Left
		pt.TextColor3 = TXT_MAIN
		pt.Text = name
		zw(pt).Parent = popup

		local xBtn = Instance.new("TextButton")
		xBtn.Size = UDim2.new(0, 20, 0, 20)
		xBtn.AnchorPoint = Vector2.new(1, 0)
		xBtn.Position = UDim2.new(1, -5, 0, 6)
		xBtn.BackgroundTransparency = 1
		xBtn.Text = ""
		zw(xBtn).Parent = popup
		makeIcon(xBtn, "x", 11, ICON_FAINT, UDim2.new(0.5, -5, 0.5, -5)).ZIndex = Z
		xBtn.MouseButton1Click:Connect(function()
			print(string.format("[ATHERIUM] color '%s' -> #%s", name, rgbToHex(color)))
			closePopup()
		end)

		-- SV canvas
		local canvas = Instance.new("Frame")
		canvas.Name = "SVCanvas"
		canvas.Size = UDim2.new(1, -20, 0, 84)
		canvas.Position = UDim2.new(0, 10, 0, 28)
		canvas.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		canvas.BorderSizePixel = 0
		canvas.ClipsDescendants = true
		zw(canvas).Parent = popup
		corner(canvas, 7)

		local whiteOv = Instance.new("Frame")
		whiteOv.Size = UDim2.new(1, 0, 1, 0)
		whiteOv.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		whiteOv.BorderSizePixel = 0
		zw(whiteOv, Z + 1).Parent = canvas
		local wg = Instance.new("UIGradient")
		wg.Rotation = 0
		wg.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		wg.Parent = whiteOv

		local blackOv = Instance.new("Frame")
		blackOv.Size = UDim2.new(1, 0, 1, 0)
		blackOv.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		blackOv.BorderSizePixel = 0
		zw(blackOv, Z + 2).Parent = canvas
		local bgGrad = Instance.new("UIGradient")
		bgGrad.Rotation = 90
		bgGrad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		})
		bgGrad.Parent = blackOv

		local cur = Instance.new("Frame")
		cur.Name = "SVCursor"
		cur.Size = UDim2.new(0, 12, 0, 12)
		cur.AnchorPoint = Vector2.new(0.5, 0.5)
		cur.Position = UDim2.new(s, 0, 1 - v, 0)
		cur.BackgroundTransparency = 1
		zw(cur, Z + 3).Parent = canvas
		corner(cur, 6)
		stroke(cur, Color3.fromRGB(255, 255, 255), 0, 2)

		local hit = Instance.new("TextButton")
		hit.Size = UDim2.new(1, 0, 1, 0)
		hit.BackgroundTransparency = 1
		hit.Text = ""
		zw(hit, Z + 4).Parent = canvas

		-- hue strip
		local hueBar = Instance.new("Frame")
		hueBar.Size = UDim2.new(1, -20, 0, 8)
		hueBar.Position = UDim2.new(0, 10, 0, 118)
		hueBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		hueBar.BorderSizePixel = 0
		zw(hueBar).Parent = popup
		corner(hueBar, 4)
		local hueGrad = Instance.new("UIGradient")
		hueGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
		})
		hueGrad.Parent = hueBar
		local hueCur = Instance.new("Frame")
		hueCur.Size = UDim2.new(0, 12, 0, 12)
		hueCur.AnchorPoint = Vector2.new(0.5, 0.5)
		hueCur.Position = UDim2.new(h, 0, 0.5, 0)
		hueCur.BackgroundTransparency = 1
		zw(hueCur, Z + 1).Parent = hueBar
		corner(hueCur, 6)
		stroke(hueCur, Color3.fromRGB(255, 255, 255), 0, 2)
		local hueHit = Instance.new("TextButton")
		hueHit.Size = UDim2.new(1, -20, 0, 16)
		hueHit.Position = UDim2.new(0, 10, 0, 114)
		hueHit.BackgroundTransparency = 1
		hueHit.Text = ""
		zw(hueHit, Z + 2).Parent = popup

		-- transparency strip: checkerboard under a ramp that runs from the real
		-- colour to fully transparent, so the handle means what it says
		local alphaBar = Instance.new("Frame")
		alphaBar.Size = UDim2.new(1, -58, 0, 12)
		alphaBar.Position = UDim2.new(0, 10, 0, 132)
		alphaBar.BackgroundColor3 = Color3.fromRGB(44, 44, 52)
		alphaBar.BorderSizePixel = 0
		zw(alphaBar).Parent = popup
		corner(alphaBar, 6)
		checkerFill(alphaBar, 240, 12, 5, 6, Z)
		local alphaFill = Instance.new("Frame")
		alphaFill.Name = "Ramp"
		alphaFill.Size = UDim2.new(1, 0, 1, 0)
		alphaFill.BackgroundColor3 = color
		alphaFill.BorderSizePixel = 0
		zw(alphaFill, Z + 1).Parent = alphaBar
		corner(alphaFill, 6)
		local alphaGrad = Instance.new("UIGradient")
		alphaGrad.Rotation = 0
		alphaGrad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		alphaGrad.Parent = alphaFill
		local alphaCur = Instance.new("Frame")
		alphaCur.Size = UDim2.new(0, 12, 0, 12)
		alphaCur.AnchorPoint = Vector2.new(0.5, 0.5)
		alphaCur.Position = UDim2.new(transp, 0, 0.5, 0)
		alphaCur.BackgroundTransparency = 1
		zw(alphaCur, Z + 2).Parent = alphaBar
		corner(alphaCur, 6)
		stroke(alphaCur, Color3.fromRGB(255, 255, 255), 0, 2)
		local alphaHit = Instance.new("TextButton")
		alphaHit.Size = UDim2.new(1, -58, 0, 16)
		alphaHit.Position = UDim2.new(0, 10, 0, 130)
		alphaHit.BackgroundTransparency = 1
		alphaHit.Text = ""
		zw(alphaHit, Z + 3).Parent = popup
		local alphaPct = Instance.new("TextLabel")
		alphaPct.Size = UDim2.new(0, 32, 0, 12)
		alphaPct.Position = UDim2.new(1, -42, 0, 133)
		alphaPct.BackgroundTransparency = 1
		alphaPct.Font = Enum.Font.Code
		alphaPct.TextSize = 10
		alphaPct.TextXAlignment = Enum.TextXAlignment.Right
		alphaPct.TextColor3 = TXT_SOFT
		alphaPct.TextStrokeTransparency = 1
		alphaPct.Text = "0%"
		zw(alphaPct, Z + 4).Parent = popup

		-- HEX row: small preview chip + hex textbox
		local chip = Instance.new("Frame")
		chip.Size = UDim2.new(0, 24, 0, 20)
		chip.Position = UDim2.new(0, 10, 0, 152)
		chip.BackgroundColor3 = Color3.fromRGB(44, 44, 52)
		chip.BorderSizePixel = 0
		chip.ClipsDescendants = true
		zw(chip).Parent = popup
		corner(chip, 7)
		checkerFill(chip, 24, 20, 3, 7, Z, Color3.fromRGB(55, 55, 64))
		local chipFill = Instance.new("Frame")
		chipFill.Name = "Fill"
		chipFill.Size = UDim2.new(1, 0, 1, 0)
		chipFill.BackgroundColor3 = color
		chipFill.BackgroundTransparency = transp
		chipFill.BorderSizePixel = 0
		zw(chipFill, Z + 1).Parent = chip
		corner(chipFill, 7)
		stroke(chipFill, Color3.fromRGB(255, 255, 255), 0.8, 1)

		local hexBox = Instance.new("TextBox")
		hexBox.Size = UDim2.new(1, -44, 0, 20)
		hexBox.Position = UDim2.new(0, 40, 0, 152)
		hexBox.BackgroundColor3 = BG_TRACK
		hexBox.Font = Enum.Font.Code
		hexBox.TextSize = 11
		hexBox.TextColor3 = TXT_MAIN
		hexBox.PlaceholderColor3 = TXT_FAINT
		hexBox.PlaceholderText = "#FFFFFF"
		hexBox.Text = "#" .. rgbToHex(color)
		hexBox.ClearTextOnFocus = false
		zw(hexBox).Parent = popup
		corner(hexBox, 5)

		-- compact presets (single row of small chips)
		local presets = {
			Color3.fromRGB(255,255,255), Color3.fromRGB(199,199,209), Color3.fromRGB(138,138,147),
			Color3.fromRGB(82,82,91), Color3.fromRGB(30,30,36), Color3.fromRGB(200,90,90),
			Color3.fromRGB(110,160,200), Color3.fromRGB(160,130,200),
		}
		local prow = Instance.new("Frame")
		prow.Size = UDim2.new(1, -20, 0, 14)
		prow.Position = UDim2.new(0, 10, 0, 180)
		prow.BackgroundTransparency = 1
		zw(prow).Parent = popup
		local pl = Instance.new("UIGridLayout")
		pl.SortOrder = Enum.SortOrder.LayoutOrder
		pl.CellSize = UDim2.new(0, 16, 0, 14)
		pl.CellPadding = UDim2.new(0, 3, 0, 3)
		pl.Parent = prow
		for pidx, pc in ipairs(presets) do
			local b = Instance.new("TextButton")
			b.LayoutOrder = pidx
			b.Size = UDim2.new(0, 16, 0, 14)
			b.BackgroundColor3 = pc
			b.Text = ""
			b.AutoButtonColor = false
			zw(b).Parent = prow
			corner(b, 4)
			stroke(b, Color3.fromRGB(255, 255, 255), 0.85, 1)
			b.MouseButton1Click:Connect(function()
				color = pc
				h, s, v = rgbToHsv(pc)
				fire()
			end)
		end

		local curTween, hueTween, alphaTween = nil, nil, nil
		live = function()
			if not popup then return end
			canvas.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			local cw, chh = canvas.AbsoluteSize.X, canvas.AbsoluteSize.Y
			if cw > 10 and chh > 10 then
				local m = 6
				local target = UDim2.new(0, m + s * (cw - m * 2), 0, m + (1 - v) * (chh - m * 2))
				if curTween then pcall(function() curTween:Cancel() end) end
				curTween = TweenService:Create(cur, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = target})
				curTween:Play()
			end
			local hw = hueBar.AbsoluteSize.X
			if hw > 20 then
				local hTarget = UDim2.new(0, 6 + h * (hw - 12), 0.5, 0)
				if hueTween then pcall(function() hueTween:Cancel() end) end
				hueTween = TweenService:Create(hueCur, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = hTarget})
				hueTween:Play()
			else
				hueCur.Position = UDim2.new(h, 0, 0.5, 0)
			end
			chipFill.BackgroundColor3 = color
			chipFill.BackgroundTransparency = transp
			if not hexBox:IsFocused() then
				hexBox.Text = "#" .. rgbToHex(color)
			end
			alphaFill.BackgroundColor3 = color
			alphaPct.Text = tostring(math.floor(transp * 100 + 0.5)) .. "%"
			local aw = alphaBar.AbsoluteSize.X
			if aw > 20 then
				local aTarget = UDim2.new(0, 6 + transp * (aw - 12), 0.5, 0)
				if alphaTween then pcall(function() alphaTween:Cancel() end) end
				alphaTween = TweenService:Create(alphaCur, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = aTarget})
				alphaTween:Play()
			end
		end

		local function applySV(x, y)
			local m = 6
			local cw = math.max(1, canvas.AbsoluteSize.X - m * 2)
			local chh = math.max(1, canvas.AbsoluteSize.Y - m * 2)
			s = math.clamp((x - canvas.AbsolutePosition.X - m) / cw, 0, 1)
			v = 1 - math.clamp((y - canvas.AbsolutePosition.Y - m) / chh, 0, 1)
			color = Color3.fromHSV(h, s, v)
			fire()
		end
		local svDrag = false
		hit.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				svDrag = true
				applySV(input.Position.X, input.Position.Y)
			end
		end)
		local function applyHue(x)
			local w = math.max(1, hueBar.AbsoluteSize.X - 12)
			h = math.clamp((x - hueBar.AbsolutePosition.X - 6) / w, 0, 1)
			color = Color3.fromHSV(h, s, v)
			fire()
		end
		local hueDrag = false
		hueHit.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				hueDrag = true
				applyHue(input.Position.X)
			end
		end)
		local function applyAlpha(x)
			local w = math.max(1, alphaBar.AbsoluteSize.X - 12)
			transp = math.clamp((x - alphaBar.AbsolutePosition.X - 6) / w, 0, 1)
			fire()
		end
		local alphaDrag = false
		alphaHit.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				alphaDrag = true
				applyAlpha(input.Position.X)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if svDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				applySV(input.Position.X, input.Position.Y)
			elseif hueDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				applyHue(input.Position.X)
			elseif alphaDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				applyAlpha(input.Position.X)
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				if svDrag or hueDrag or alphaDrag then
					print(string.format("[ATHERIUM] color '%s' -> #%s", name, rgbToHex(color)))
				end
				svDrag = false
				hueDrag = false
				alphaDrag = false
			end
		end)
		hexBox.FocusLost:Connect(function(enter)
			if not enter then return end
			local c = hexToRgb(hexBox.Text)
			if c then
				color = c
				h, s, v = rgbToHsv(c)
				fire()
				print(string.format("[ATHERIUM] color '%s' -> #%s", name, rgbToHex(color)))
			else
				hexBox.Text = "#" .. rgbToHex(color)
			end
		end)

		outsideConn = UserInputService.InputBegan:Connect(function(input)
			if not popup then return end
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
			local pp = popup
			if not pp or not pp.Parent then return end
			local pos = pp.AbsolutePosition
			local sz = pp.AbsoluteSize
			local mp = input.Position
			local inside = mp.X >= pos.X and mp.X <= pos.X + sz.X and mp.Y >= pos.Y and mp.Y <= pos.Y + sz.Y
			local sp = sw.AbsolutePosition
			local ss = sw.AbsoluteSize
			local onSw = mp.X >= sp.X and mp.X <= sp.X + ss.X and mp.Y >= sp.Y and mp.Y <= sp.Y + ss.Y
			if not inside and not onSw then
				print(string.format("[ATHERIUM] color '%s' -> #%s", name, rgbToHex(color)))
				closePopup()
			end
		end)

		task.defer(function()
			if popup then live() end
		end)
		task.delay(0.1, function()
			if popup then live() end
		end)
		win:ApplyTheme(popup)
	end)

	local obj = {}
	function obj:Set(c, fire) if typeof(c) == "Color3" then color = c end sw.BackgroundColor3 = color if fire then pcall(callback, color, transp) end end
	function obj:Get() return color, transp end
	function obj:SetTransparency(t, notify)
		transp = math.clamp(tonumber(t) or 0, 0, 1)
		if notify then
			fire() -- repaint, mark dirty, callback
		else
			sw.BackgroundTransparency = transp
			if live then live() end
		end
	end
	table.insert(win._cfg, { kind = "color", tab = self._tab._name, sec = self._title or "?", name = name, get = function() local c, t = obj:Get() return { hex = rgbToHex(c), transp = t } end, set = function(v) if typeof(v) == "table" then local c = hexToRgb(v.hex) if c then obj:Set(c) end obj:SetTransparency(v.transp, true) end end })
	pcall(callback, color, transp)
	return obj
end

--// ---------- chart palettes + number formats (shared by viewport/charts) ----------
local CHART_PALS = {
	mono = { "FFFFFF", "C7C7D1", "8A8A93", "52525B", "3A3A44" },
	frost = { "9CC3FF", "6EA8FE", "4A7DD6", "B9D4FF", "E4EEFF" },
	ember = { "FF9D6B", "FF7A59", "E85D3D", "FFC59C", "FFE3C7" },
	mint = { "7FE3B0", "4CD08A", "2AA86B", "B5F0D2", "E2F8EC" },
	candy = { "9CC3FF", "FF9D6B", "7FE3B0", "D3A6FF", "FFE08A" },
}
function VibeUI.Palette(name)
	local hexes = CHART_PALS[string.lower(tostring(name or "mono"))] or CHART_PALS.mono
	local out = {}
	for _, h in ipairs(hexes) do
		local c = hexToRgb(h)
		if c then table.insert(out, c) end
	end
	if #out == 0 then table.insert(out, Color3.fromRGB(255, 255, 255)) end
	return out
end
function VibeUI.FmtInt(v)
	v = tonumber(v) or 0
	return tostring(math.floor(v + 0.5))
end
function VibeUI.FmtK(v)
	v = tonumber(v) or 0
	local a = math.abs(v)
	if a >= 1000000 then return string.format("%.1fM", v / 1000000) end
	if a >= 1000 then return string.format("%.1fK", v / 1000) end
	return tostring(math.floor(v + 0.5))
end
function VibeUI.FmtPct(v, digits)
	v = tonumber(v) or 0
	return string.format("%." .. tostring(math.clamp(math.floor(tonumber(digits) or 1), 0, 3)) .. "f%%", v)
end

-- Safety net: pulls the live character out of any viewport WorldModel it
-- got stuck in (a viewport must only ever hold CLONES). Returns true if
-- anything was rescued. Called automatically on inject and inside SetPlayer.
function VibeUI.RescueCharacter()
	local lp = LocalPlayer
	if not lp then return false end
	local ch = lp.Character
	if not ch then return false end
	local saved = false
	local function scan(root)
		if not root then return end
		for _, d in ipairs(root:GetDescendants()) do
			if d:IsA("WorldModel") and ch:IsDescendantOf(d) then
				pcall(function() ch.Parent = workspace end)
				saved = true
			end
		end
	end
	pcall(function() scan(game:GetService("CoreGui")) end)
	pcall(function() if gethui then scan(gethui()) end end)
	pcall(function()
		local pg = lp:FindFirstChildOfClass("PlayerGui")
		if pg then scan(pg) end
	end)
	if saved then print("[ATHERIUM] character rescued from viewport") end
	return saved
end

-- 3D viewport: drop a player rig, a place model or any prop inside the GUI.
-- Section:AddViewport({ Name = "Preview", Height = 190, FOV = 40,
--   AutoRotate = true, RotateSpeed = 25, Angle = { az = 35, el = 12 },
--   ShowControls = true, Model = nil, Backdrop = nil, Lighting = nil })
-- handle:SetModel(inst, { Clone = true, Clean = true }) -- clone keeps your live game untouched
-- handle:SetPlayer()      -- clones LocalPlayer.Character (waits for spawn if needed)
-- handle:SetFromGame(obj) -- alias of SetModel for place objects/props
-- handle:Clear() handle:GetModel() handle:Focus() handle:Refresh()
-- handle:SetAngles(az, el) handle:SetDistance(d) handle:SetFOV(f)
-- handle:SetAutoRotate(b) handle:SetSpeed(s)
-- handle:SetLighting(ambient, lightColor, lightDir) handle:SetBackdrop(color or nil)
function Section:AddViewport(opts)
	local win = self._win
	opts = opts or {}
	local name = opts.Name or "Viewport"
	local vh = math.clamp(math.floor(tonumber(opts.Height) or 190), 120, 420)
	local showCtl = opts.ShowControls ~= false
	local ang = opts.Angle or {}

	local row = Instance.new("Frame")
	row.Name = "Row_" .. name
	row.Size = UDim2.new(1, 0, 0, 24 + vh + (showCtl and 30 or 6))
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.Parent = self._body
	row.LayoutOrder = #self._body:GetChildren()
	win._registerRow(row, name, self)
	if opts.Tooltip then win:_attachTip(row, opts.Tooltip) end

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -110, 0, 20)
	title.Position = UDim2.new(0, 10, 0, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamMedium
	title.TextSize = 13
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = TXT_MAIN
	title.Text = name
	title.Parent = row
	win:ThemeRegister(title, "text")

	local hint = Instance.new("TextLabel")
	hint.Size = UDim2.new(0, 100, 0, 20)
	hint.AnchorPoint = Vector2.new(1, 0)
	hint.Position = UDim2.new(1, -8, 0, 0)
	hint.BackgroundTransparency = 1
	hint.Font = Enum.Font.Code
	hint.TextSize = 10
	hint.TextXAlignment = Enum.TextXAlignment.Right
	hint.TextColor3 = TXT_FAINT
	hint.Text = "drag to orbit"
	hint.Parent = row

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.new(1, -16, 0, vh)
	panel.Position = UDim2.new(0, 8, 0, 24)
	panel.BackgroundColor3 = Color3.fromRGB(13, 13, 16)
	panel.BorderSizePixel = 0
	panel.ClipsDescendants = true
	panel.Parent = row
	corner(panel, 8)
	stroke(panel, LINE, 0, 1)

	local vp = Instance.new("ViewportFrame")
	vp.Name = "View"
	vp.Size = UDim2.new(1, 0, 1, 0)
	vp.BackgroundTransparency = 1
	vp.BorderSizePixel = 0
	vp.Ambient = Color3.fromRGB(135, 135, 142)
	vp.LightColor = Color3.fromRGB(255, 255, 255)
	vp.LightDirection = Vector3.new(-0.4, -1, -0.35)
	vp.Parent = panel
	if opts.Backdrop then
		vp.BackgroundColor3 = opts.Backdrop
		vp.BackgroundTransparency = 0
	end
	if type(opts.Lighting) == "table" then
		if typeof(opts.Lighting.Ambient) == "Color3" then vp.Ambient = opts.Lighting.Ambient end
		if typeof(opts.Lighting.Color) == "Color3" then vp.LightColor = opts.Lighting.Color end
		if typeof(opts.Lighting.Direction) == "Vector3" then vp.LightDirection = opts.Lighting.Direction end
	end

	local world = Instance.new("WorldModel")
	world.Parent = vp
	local cam = Instance.new("Camera")
	cam.FieldOfView = math.clamp(tonumber(opts.FOV) or 40, 10, 100)
	cam.Parent = vp
	vp.CurrentCamera = cam

	local ph = Instance.new("TextLabel")
	ph.Size = UDim2.new(1, -20, 0, 20)
	ph.AnchorPoint = Vector2.new(0.5, 0.5)
	ph.Position = UDim2.new(0.5, 0, 0.5, 0)
	ph.BackgroundTransparency = 1
	ph.Font = Enum.Font.Code
	ph.TextSize = 12
	ph.TextColor3 = TXT_FAINT
	ph.Text = "No model - call SetModel()"
	ph.Parent = panel

	local fov0 = cam.FieldOfView
	local state = {
		model = nil, target = Vector3.new(0, 0, 0),
		az = tonumber(ang.az) or 35, el = math.clamp(tonumber(ang.el) or 12, -80, 80),
		dist = 10, minD = 3, maxD = 80, fov = fov0,
		auto = opts.AutoRotate ~= false, speed = tonumber(opts.RotateSpeed) or 25,
	}
	local conns = {}
	local dead = false
	local function cleanup()
		if dead then return end
		dead = true
		for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
		table.clear(conns)
	end
	row.AncestryChanged:Connect(function()
		if not row:IsDescendantOf(game) then cleanup() end
	end)

	local function render()
		if dead or not cam.Parent then return end
		local azr, elr = math.rad(state.az), math.rad(state.el)
		local dir = Vector3.new(math.cos(elr) * math.cos(azr), math.sin(elr), math.cos(elr) * math.sin(azr))
		cam.FieldOfView = state.fov
		cam.CFrame = CFrame.lookAt(state.target + dir * state.dist, state.target)
	end
	table.insert(conns, RunService.RenderStepped:Connect(function(dt)
		if dead then return end
		if not row.Parent then return end
		-- off-screen or hidden window: skip the whole orbit update
		if win._visible == false then return end
		if vp.AbsoluteSize.X < 8 then return end
		if state.auto and state.model and state.model.Parent then
			state.az = (state.az + state.speed * math.min(dt, 0.1)) % 360
			render()
		end
	end))

	local function clearModel()
		if state.model then pcall(function() state.model:Destroy() end) end
		state.model = nil
		ph.Visible = true
	end
	local rotBtn, rotIco = nil, nil

	local obj = {}
	function obj:GetModel() return state.model end
	function obj:Clear() clearModel() end
	function obj:SetModel(inst, mopts)
		if dead then return false end
		if typeof(inst) ~= "Instance" then return false end
		mopts = mopts or {}
		-- HARD RULE: the live character never leaves Workspace. Clone mode
		-- that fails to clone aborts instead of touching the real rig.
		local wantClone = mopts.Clone ~= false
		if inst == LocalPlayer.Character and not wantClone then
			print("[ATHERIUM] viewport: live character refused (Clone=false)")
			return false
		end
		VibeUI.RescueCharacter()
		clearModel()
		local src = inst
		local live = false
		if wantClone then
			-- characters often ship with Archivable=false which makes
			-- Clone() silently return nil. Flip the flag (harmless) first,
			-- then fall back to a manual per-child deep copy.
			pcall(function() inst.Archivable = true end)
			local ok, cp = pcall(function() return inst:Clone() end)
			if ok and typeof(cp) == "Instance" and cp ~= inst then
				src = cp
			else
				local mm = Instance.new("Model")
				mm.Name = inst.Name
				local any = false
				for _, cc in ipairs(inst:GetChildren()) do
					local ok2, kc = pcall(function() return cc:Clone() end)
					if ok2 and typeof(kc) == "Instance" then
						kc.Parent = mm
						any = true
					end
				end
				if any then
					src = mm
				else
					pcall(function() mm:Destroy() end)
					print("[ATHERIUM] viewport: clone failed, aborting (live game kept safe)")
					return false
				end
			end
		else
			live = true
		end
		if src == LocalPlayer.Character then
			print("[ATHERIUM] viewport: live character refused")
			return false
		end
		if not live and mopts.Clean ~= false then
			for _, d in ipairs(src:GetDescendants()) do
				pcall(function()
					if d:IsA("LuaSourceContainer") then
						d:Destroy()
					elseif d:IsA("BasePart") then
						d.Anchored = true
						d.CanCollide = false
						d.CanTouch = false
						d.CanQuery = false
						-- cloned limbs keep the first-person fade, which would
						-- make the whole preview invisible
						pcall(function() d.LocalTransparencyModifier = 0 end)
					elseif d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail") or d:IsA("Fire") or d:IsA("Smoke") then
						d.Enabled = false
					end
				end)
			end
		end
		src.Parent = world
		state.model = src
		state.live = live
		ph.Visible = false
		obj:Focus()
		print(string.format("[ATHERIUM] viewport '%s' model <- %s (%s)", name, src:GetFullName(), live and "live" or "clone"))
		return true
	end
	function obj:SetFromGame(inst, mopts) return obj:SetModel(inst, mopts) end
	function obj:SetPlayer()
		if dead then return false end
		if obj._charConn then pcall(function() obj._charConn:Disconnect() end) obj._charConn = nil end
		local ch = LocalPlayer and LocalPlayer.Character
		if ch then return obj:SetModel(ch) end
		ph.Text = "Waiting for character..."
		obj._charConn = LocalPlayer.CharacterAdded:Connect(function(nc)
			task.defer(function()
				if dead then return end
				if obj:SetModel(nc) then
					if obj._charConn then pcall(function() obj._charConn:Disconnect() end) obj._charConn = nil end
				end
			end)
		end)
		table.insert(conns, obj._charConn)
		return false
	end
	function obj:Focus()
		local m = state.model
		if not m or not m.Parent then return false end
		local ok, cfr, sz = pcall(function() return m:GetBoundingBox() end)
		if not ok or typeof(cfr) ~= "CFrame" or typeof(sz) ~= "Vector3" then return false end
		if state.live then
			-- live reference: never move it, aim at where it stands
			state.target = cfr.Position
		else
			pcall(function() m:PivotTo(m:GetPivot() - cfr.Position) end)
			state.target = Vector3.new(0, 0, 0)
		end
		local md = math.max(sz.X, sz.Y, sz.Z)
		if md < 0.5 then md = 0.5 end
		state.dist = (md * 0.5) / math.tan(math.rad(state.fov * 0.5)) * 1.45
		state.minD = md * 0.6
		state.maxD = md * 8
		render()
		return true
	end
	function obj:Refresh() return obj:Focus() end
	function obj:SetAngles(az, el)
		if tonumber(az) then state.az = tonumber(az) % 360 end
		if tonumber(el) then state.el = math.clamp(tonumber(el), -80, 80) end
		render()
	end
	function obj:SetDistance(d)
		d = tonumber(d)
		if d then state.dist = math.clamp(d, state.minD, state.maxD) render() end
	end
	function obj:GetDistance() return state.dist end
	function obj:SetFOV(f)
		f = tonumber(f)
		if f then state.fov = math.clamp(f, 10, 100) render() end
	end
	function obj:SetAutoRotate(b)
		state.auto = not not b
		if rotBtn then
			rotBtn:SetAttribute("On", state.auto)
			applyLucide(rotIco, state.auto and "pause" or "play")
			rotBtn.BackgroundColor3 = state.auto and Color3.fromRGB(48, 48, 56) or Color3.fromRGB(30, 30, 34)
		end
	end
	function obj:GetAutoRotate() return state.auto end
	function obj:SetSpeed(s) if tonumber(s) then state.speed = tonumber(s) end end
	function obj:SetLighting(amb, col, dir)
		if typeof(amb) == "Color3" then vp.Ambient = amb end
		if typeof(col) == "Color3" then vp.LightColor = col end
		if typeof(dir) == "Vector3" then vp.LightDirection = dir end
	end
	function obj:SetBackdrop(c)
		if typeof(c) == "Color3" then
			vp.BackgroundColor3 = c
			vp.BackgroundTransparency = 0
		else
			vp.BackgroundTransparency = 1
		end
	end

	-- orbit / zoom input (transparent catcher above the view)
	local grab = Instance.new("TextButton")
	grab.Name = "Orbit"
	grab.Size = UDim2.new(1, 0, 1, 0)
	grab.BackgroundTransparency = 1
	grab.Text = ""
	grab.AutoButtonColor = false
	grab.Parent = panel
	local orbiting, lx, ly = false, 0, 0
	grab.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			orbiting = true
			lx, ly = input.Position.X, input.Position.Y
		end
	end)
	table.insert(conns, UserInputService.InputChanged:Connect(function(input)
		if not orbiting or dead then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local dx, dy = input.Position.X - lx, input.Position.Y - ly
		lx, ly = input.Position.X, input.Position.Y
		state.az = (state.az + dx * 0.45) % 360
		state.el = math.clamp(state.el + dy * 0.3, -80, 80)
		render()
	end))
	table.insert(conns, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			orbiting = false
		end
	end))
	grab.MouseWheelForward:Connect(function()
		state.dist = math.clamp(state.dist * 0.88, state.minD, state.maxD)
		render()
	end)
	grab.MouseWheelBackward:Connect(function()
		state.dist = math.clamp(state.dist * 1.14, state.minD, state.maxD)
		render()
	end)

	-- controls: rotate toggle / zoom out / zoom in / refit
	if showCtl then
		local bar = Instance.new("Frame")
		bar.Name = "Controls"
		bar.Size = UDim2.new(1, -16, 0, 26)
		bar.Position = UDim2.new(0, 8, 0, 24 + vh + 4)
		bar.BackgroundTransparency = 1
		bar.Parent = row
		local cx = 0
		local function ctlBtn(icon, tip, cb)
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(0, 34, 0, 26)
			b.Position = UDim2.new(0, cx, 0, 0)
			b.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
			b.Text = ""
			b.AutoButtonColor = false
			b.Parent = bar
			corner(b, 6)
			stroke(b, Color3.fromRGB(39, 39, 42), 0, 1)
			local ic = makeIcon(b, icon, 13, ICON_DIM, UDim2.new(0.5, -6, 0.5, -6))
			b.MouseEnter:Connect(function()
				TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(48, 48, 56)}):Play()
			end)
			b.MouseLeave:Connect(function()
				local on = b:GetAttribute("On")
				TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = (on and Color3.fromRGB(48, 48, 56) or Color3.fromRGB(30, 30, 34))}):Play()
			end)
			b.MouseButton1Click:Connect(function()
				clickSound(win._gui, function() return win._sounds end)
				cb(b)
			end)
			cx = cx + 38
			return b, ic
		end
		rotBtn, rotIco = ctlBtn(state.auto and "pause" or "play", "rotate", function(b)
			obj:SetAutoRotate(not state.auto)
		end)
		rotBtn:SetAttribute("On", state.auto)
		if state.auto then rotBtn.BackgroundColor3 = Color3.fromRGB(48, 48, 56) end
		ctlBtn("zoom-out", "out", function() obj:SetDistance(state.dist * 1.2) end)
		ctlBtn("zoom-in", "in", function() obj:SetDistance(state.dist * 0.84) end)
		ctlBtn("locate-fixed", "refit", function() obj:Focus() end)
	end

	if opts.Model and typeof(opts.Model) == "Instance" then
		task.defer(function() obj:SetModel(opts.Model) end)
	end
	render()
	return obj
end

-- Infographics: bars, lines, dotted donuts, big stats, sparklines.
-- Section:AddChart({ Name = "Chart", Type = "bar", Height = 170,
--   Data = { { label = "Mon", value = 12 }, { label = "Tue", value = 30 } },
--   Colors = "frost", Animated = true, Format = VibeUI.FmtInt,
--   ShowLabels = true, MaxPoints = 30, Value = 0, Delta = 0, Caption = "",
--   Thickness = 1.5, AnimationSpeed = 1 })
-- datum: { label, value, color? } or plain number. Colors: palette name
-- ("mono","frost","ember","mint","candy"), "accent" (live theme accent),
-- single Color3 or {Color3...} (graph gradient from -> to).
-- Thickness: stroke width in px (line/spark/graph, default 1.5).
-- AnimationSpeed: multiplier for every animation incl. stream glide.
-- handle:SetData(t) handle:Push(label, value) handle:SetColors(p)
-- handle:SetTitle(t) handle:SetFormat(fn) handle:SetType(t)
-- handle:SetThickness(px) handle:SetAnimationSpeed(x)
-- handle:SetValue(v, delta, caption)  -- stat type
-- handle:GetData() handle:GetTotal() handle:Clear() handle:Refresh()
-- GRAPH only: handle:SetWindow(n) handle:SetSmooth(b)
-- handle:Stream(fn, interval)  -- fn=nil means live FPS meter
-- handle:Stop() handle:GetStats() -> { min, max, avg, last, count }
function Section:AddChart(opts)
	local win = self._win
	opts = opts or {}
	local name = opts.Name or "Chart"
	local TYPES = { bar = true, line = true, donut = true, stat = true, spark = true, graph = true }
	local ctype = string.lower(tostring(opts.Type or "bar"))
	if not TYPES[ctype] then ctype = "bar" end
	local DEF_H = { bar = 170, line = 160, donut = 180, stat = 86, spark = 64, graph = 170 }
	local ch = math.clamp(math.floor(tonumber(opts.Height) or DEF_H[ctype]), 48, 420)
	local animated = opts.Animated ~= false
	local maxPts = math.clamp(math.floor(tonumber(opts.MaxPoints) or 30), 2, 120)
	local showLab = opts.ShowLabels ~= false
	local fmt = opts.Format
	if type(fmt) ~= "function" then fmt = VibeUI.FmtInt end
	local palOpt = opts.Colors or "mono"

	local headH = (ctype == "spark") and 22 or 26
	local row = Instance.new("Frame")
	row.Name = "Row_" .. name
	row.Size = UDim2.new(1, 0, 0, headH + 4 + ch)
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.Parent = self._body
	row.LayoutOrder = #self._body:GetChildren()
	win._registerRow(row, name, self)
	if opts.Tooltip then win:_attachTip(row, opts.Tooltip) end

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -110, 0, headH)
	title.Position = UDim2.new(0, 10, 0, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamMedium
	title.TextSize = 13
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = TXT_MAIN
	title.Text = name
	title.Parent = row
	win:ThemeRegister(title, "text")

	local meta = Instance.new("TextLabel")
	meta.Size = UDim2.new(0, 100, 0, headH)
	meta.AnchorPoint = Vector2.new(1, 0)
	meta.Position = UDim2.new(1, -8, 0, 0)
	meta.BackgroundTransparency = 1
	meta.Font = Enum.Font.Code
	meta.TextSize = 11
	meta.TextXAlignment = Enum.TextXAlignment.Right
	meta.TextColor3 = TXT_DIM
	meta.Text = ""
	meta.Parent = row

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.new(1, -16, 0, ch)
	panel.Position = UDim2.new(0, 8, 0, headH + 4)
	panel.BackgroundColor3 = Color3.fromRGB(13, 13, 16)
	panel.BorderSizePixel = 0
	panel.ClipsDescendants = true
	panel.Parent = row
	corner(panel, 8)
	stroke(panel, LINE, 0, 1)

	local data = {}
	local function ingest(t)
		data = {}
		if type(t) ~= "table" then return end
		for _, d in ipairs(t) do
			if type(d) == "table" then
				table.insert(data, { label = tostring(d.label or d[1] or ""), value = tonumber(d.value or d[2]) or 0, color = d.color })
			elseif tonumber(d) then
				table.insert(data, { label = "", value = tonumber(d) })
			end
			if #data >= maxPts then break end
		end
	end
	ingest(opts.Data)

	local statV = tonumber(opts.Value) or 0
	local statD = opts.Delta
	local statCap = tostring(opts.Caption or "")
	local shownV = statV
	local obj

	local dead = false
	local drawId = 0
	local window = math.clamp(math.floor(tonumber(opts.Window) or 40), 5, 120)
	window = math.min(window, maxPts)
	local smooth = opts.Smooth ~= false
	local streamConn, streamFn, streamInt, streamAcc, streamFrames = nil, nil, 0.25, 0, 0
	local gPool = nil -- persistent graph objects: Push updates them, no rebuild
	local draw -- forward: graphPush (below) runs before the assignment
	local thick = math.clamp(tonumber(opts.Thickness) or 1.5, 1, 6)
	local speed = math.clamp(tonumber(opts.AnimationSpeed) or 1, 0.25, 4)
	local GX_PAD = 0.015 -- graph edge inset (fractions of plot width)
	local accentConn = nil
	row.AncestryChanged:Connect(function()
		if not row:IsDescendantOf(game) then
			dead = true
			drawId = drawId + 1
			if streamConn then pcall(function() streamConn:Disconnect() end) streamConn = nil end
			if accentConn then pcall(function() accentConn:Disconnect() end) accentConn = nil end
		end
	end)

	local function palette()
		if palOpt == "accent" then
			return { win:_tc("accent", Color3.fromRGB(255, 255, 255)) }
		end
		if type(palOpt) == "table" and #palOpt > 0 then return palOpt end
		return VibeUI.Palette(palOpt)
	end
	local function datumColors()
		local pal = palette()
		local out = {}
		for i, d in ipairs(data) do
			if typeof(d.color) == "Color3" then out[i] = d.color
			else out[i] = pal[((i - 1) % #pal) + 1] end
		end
		return out
	end
	local function clearPanel()
		for _, c in ipairs(panel:GetChildren()) do pcall(function() c:Destroy() end) end
	end
	local function emptyNote(txt)
		local l = Instance.new("TextLabel")
		l.Size = UDim2.new(1, -20, 0, 18)
		l.AnchorPoint = Vector2.new(0.5, 0.5)
		l.Position = UDim2.new(0.5, 0, 0.5, 0)
		l.BackgroundTransparency = 1
		l.Font = Enum.Font.Code
		l.TextSize = 11
		l.TextColor3 = TXT_FAINT
		l.Text = txt or "No data"
		l.Parent = panel
	end
	local function total()
		local s = 0
		for _, d in ipairs(data) do s = s + (tonumber(d.value) or 0) end
		return s
	end
	local function tweenIn(inst, props, delay, dur)
		if dead then return end
		if not animated then
			pcall(function() for k, v in pairs(props) do inst[k] = v end end)
			return
		end
		local bid = drawId
		local sc = speed or 1
		task.delay((delay or 0) / sc, function()
			if dead or bid ~= drawId then return end
			pcall(function()
				if inst.Parent then
					TweenService:Create(inst, TweenInfo.new((dur or 0.35) / sc, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play()
				end
			end)
		end)
	end

	-- shared hairlines: reads as a grid without adding visual noise
	local function grid(parent, count)
		count = count or 3
		for i = 1, count do
			local gl = Instance.new("Frame")
			gl.Size = UDim2.new(1, 0, 0, 1)
			gl.Position = UDim2.new(0, 0, i / (count + 1), 0)
			gl.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			gl.BackgroundTransparency = 0.94
			gl.BorderSizePixel = 0
			gl.Parent = parent
		end
	end

	local function vgrad(inst, c)
		local g = Instance.new("UIGradient")
		g.Rotation = 90
		g.Color = ColorSequence.new(c, c:Lerp(Color3.fromRGB(0, 0, 0), 0.45))
		g.Parent = inst
		return g
	end

	local function drawBar()
		clearPanel()
		if #data == 0 then emptyNote() meta.Text = "" return end
		meta.Text = fmt(total())
		local cols = datumColors()
		local hasLab = showLab and tostring(data[1].label or "") ~= ""
		local plot = Instance.new("Frame")
		plot.Name = "Plot"
		plot.Size = UDim2.new(1, -16, 1, -(14 + (hasLab and 16 or 4)))
		plot.Position = UDim2.new(0, 8, 0, 12)
		plot.BackgroundTransparency = 1
		plot.Parent = panel
		grid(plot, 3)
		local base = Instance.new("Frame")
		base.Size = UDim2.new(1, 0, 0, 1)
		base.Position = UDim2.new(0, 0, 1, -1)
		base.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		base.BackgroundTransparency = 0.86
		base.BorderSizePixel = 0
		base.Parent = plot
		local labRow
		if hasLab then
			labRow = Instance.new("Frame")
			labRow.Size = UDim2.new(1, -16, 0, 14)
			labRow.Position = UDim2.new(0, 8, 1, -14)
			labRow.BackgroundTransparency = 1
			labRow.Parent = panel
		end
		local mx = 0.0001
		for _, d in ipairs(data) do mx = math.max(mx, tonumber(d.value) or 0) end
		local n = #data
		for i, d in ipairs(data) do
			local h = math.clamp((tonumber(d.value) or 0) / mx, 0, 1)
			local slot = Instance.new("Frame")
			slot.Size = UDim2.new(1 / n, 0, 1, 0)
			slot.Position = UDim2.new((i - 1) / n, 0, 0, 0)
			slot.BackgroundTransparency = 1
			slot.Parent = plot
			local bar = Instance.new("Frame")
			bar.Name = "Bar"
			bar.AnchorPoint = Vector2.new(0.5, 1)
			bar.Position = UDim2.new(0.5, 0, 1, 0)
			bar.Size = UDim2.new(0.54, 0, 0, 0)
			bar.BackgroundColor3 = cols[i] or Color3.fromRGB(255, 255, 255)
			bar.BorderSizePixel = 0
			bar.Parent = slot
			corner(bar, 3)
			vgrad(bar, bar.BackgroundColor3)
			tweenIn(bar, { Size = UDim2.new(0.54, 0, math.max(h, 0.008), 0) }, (i - 1) * 0.03, 0.42)
			if n <= 8 then
				local vlab = Instance.new("TextLabel")
				vlab.AnchorPoint = Vector2.new(0.5, 1)
				vlab.Position = UDim2.new(0.5, 0, 1 - math.max(h, 0.008), -5)
				vlab.Size = UDim2.new(2, 0, 0, 12)
				vlab.BackgroundTransparency = 1
				vlab.Font = Enum.Font.Code
				vlab.TextSize = 9
				vlab.TextColor3 = TXT_SOFT
				vlab.Text = fmt(d.value)
				vlab.Parent = slot
			end
			if hasLab then
				local xlab = Instance.new("TextLabel")
				xlab.AnchorPoint = Vector2.new(0.5, 0)
				xlab.Position = UDim2.new((i - 0.5) / n, 0, 0, 0)
				xlab.Size = UDim2.new(1 / n, -4, 1, 0)
				xlab.BackgroundTransparency = 1
				xlab.Font = Enum.Font.Code
				xlab.TextSize = 9
				xlab.TextColor3 = TXT_FAINT
				xlab.TextTruncate = Enum.TextTruncate.AtEnd
				xlab.Text = tostring(d.label)
				xlab.Parent = labRow
			end
		end
	end

	local function drawLine(mini)
		clearPanel()
		if #data == 0 then emptyNote() meta.Text = "" return end
		local cols = datumColors()
		local lineC = cols[1] or Color3.fromRGB(255, 255, 255)
		meta.Text = fmt(data[#data].value)
		local topPad, botPad, lPad, rPad = 10, (mini or not showLab) and 6 or 18, (mini and 4 or 30), 8
		if not mini then
			local mx0 = -1e18
			for _, d in ipairs(data) do mx0 = math.max(mx0, tonumber(d.value) or 0) end
			local hi = Instance.new("TextLabel")
			hi.Size = UDim2.new(0, 26, 0, 12)
			hi.Position = UDim2.new(0, 2, 0, 2)
			hi.BackgroundTransparency = 1
			hi.Font = Enum.Font.Code
			hi.TextSize = 9
			hi.TextXAlignment = Enum.TextXAlignment.Right
			hi.TextColor3 = TXT_FAINT
			hi.Text = fmt(mx0)
			hi.Parent = panel
		end
		local plot = Instance.new("Frame")
		plot.Size = UDim2.new(1, -(lPad + rPad), 1, -(topPad + botPad))
		plot.Position = UDim2.new(0, lPad, 0, topPad)
		plot.BackgroundTransparency = 1
		plot.Parent = panel
		local n = #data
		local mn, mx = 1e18, -1e18
		for _, d in ipairs(data) do
			local v = tonumber(d.value) or 0
			mn = math.min(mn, v)
			mx = math.max(mx, v)
		end
		if mx - mn < 1e-6 then mx, mn = mn + 1, mn - 1 end
		local pad = (mx - mn) * 0.15
		mn, mx = mn - pad, mx + pad
		local function pt(i)
			local v = tonumber(data[i].value) or 0
			local x = (n == 1) and 0.5 or ((i - 1) / (n - 1))
			return x, 1 - (v - mn) / (mx - mn)
		end
		grid(plot, 3)
		local base = Instance.new("Frame")
		base.Size = UDim2.new(1, 0, 0, 1)
		base.Position = UDim2.new(0, 0, 1, -1)
		base.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		base.BackgroundTransparency = 0.86
		base.BorderSizePixel = 0
		base.Parent = plot
		local function buildPx()
			if dead or not plot.Parent then return end
			local pw, phh = plot.AbsoluteSize.X, plot.AbsoluteSize.Y
			if pw < 10 or phh < 10 then return end
			-- soft glow under the polyline instead of a blocky area fill
			for i = 1, n - 1 do
				local x1, y1 = pt(i)
				local x2, y2 = pt(i + 1)
				local ax, ay = x1 * pw, y1 * phh
				local bx, by = x2 * pw, y2 * phh
				local len = math.sqrt((bx - ax) * (bx - ax) + (by - ay) * (by - ay))
				if len >= 2 then
					local gl = Instance.new("Frame")
					gl.AnchorPoint = Vector2.new(0.5, 0.5)
					gl.Size = UDim2.new(0, len + 6, 0, thick + 5)
					gl.Position = UDim2.new(0, (ax + bx) * 0.5, 0, (ay + by) * 0.5)
					gl.Rotation = math.deg(math.atan2(by - ay, bx - ax))
					gl.BackgroundColor3 = cols[1] or lineC
					gl.BackgroundTransparency = 0.88
					gl.BorderSizePixel = 0
					gl.Parent = plot
					corner(gl, 3)
				end
			end
			for i = 1, n - 1 do
				local x1, y1 = pt(i)
				local x2, y2 = pt(i + 1)
				local ax, ay = x1 * pw, y1 * phh
				local bx, by = x2 * pw, y2 * phh
				local len = math.sqrt((bx - ax) * (bx - ax) + (by - ay) * (by - ay))
				if len >= 2 then
					local sg = Instance.new("Frame")
					local ang = math.atan2(by - ay, bx - ax)
					sg.AnchorPoint = Vector2.new(0.5, 0.5)
					sg.Size = UDim2.new(0, len + 4, 0, thick)
					sg.Position = UDim2.new(0, (ax + bx) * 0.5, 0, (ay + by) * 0.5)
					sg.Rotation = math.deg(ang)
					sg.BackgroundColor3 = mini and (cols[1] or lineC) or lineC
					sg.BackgroundTransparency = 1
					sg.BorderSizePixel = 0
					sg.Parent = plot
					corner(sg, 1)
					tweenIn(sg, { BackgroundTransparency = 0 }, (i - 1) * 0.03, 0.3)
				end
			end
			-- one crisp endpoint marker, not a dot on every sample
			local x, y = pt(n)
			local dot = Instance.new("Frame")
			dot.AnchorPoint = Vector2.new(0.5, 0.5)
			dot.Position = UDim2.new(x, 0, y, 0)
			dot.Size = UDim2.new(0, mini and 4 or 6, 0, mini and 4 or 6)
			dot.BackgroundColor3 = cols[1] or lineC
			dot.BorderSizePixel = 0
			dot.Parent = plot
			corner(dot, 6)
			local ring = Instance.new("Frame")
			ring.AnchorPoint = Vector2.new(0.5, 0.5)
			ring.Position = UDim2.new(x, 0, y, 0)
			ring.Size = UDim2.new(0, mini and 10 or 13, 0, mini and 10 or 13)
			ring.BackgroundColor3 = cols[1] or lineC
			ring.BackgroundTransparency = 0.8
			ring.BorderSizePixel = 0
			ring.ZIndex = 0
			ring.Parent = plot
			corner(ring, 13)
		end
		if plot.AbsoluteSize.Y > 10 then buildPx()
		else task.defer(function() buildPx() end) end
		if not mini and showLab and n > 1 then
			local a = Instance.new("TextLabel")
			a.Size = UDim2.new(0, 60, 0, 12)
			a.Position = UDim2.new(0, lPad, 1, -14)
			a.BackgroundTransparency = 1
			a.Font = Enum.Font.Code
			a.TextSize = 9
			a.TextXAlignment = Enum.TextXAlignment.Left
			a.TextColor3 = TXT_FAINT
			a.TextTruncate = Enum.TextTruncate.AtEnd
			a.Text = tostring(data[1].label or "")
			a.Parent = panel
			local b = Instance.new("TextLabel")
			b.Size = UDim2.new(0, 60, 0, 12)
			b.AnchorPoint = Vector2.new(1, 0)
			b.Position = UDim2.new(1, -rPad, 1, -14)
			b.BackgroundTransparency = 1
			b.Font = Enum.Font.Code
			b.TextSize = 9
			b.TextXAlignment = Enum.TextXAlignment.Right
			b.TextColor3 = TXT_FAINT
			b.TextTruncate = Enum.TextTruncate.AtEnd
			b.Text = tostring(data[n].label or "")
			b.Parent = panel
		end
	end

	local function drawDonut()
		clearPanel()
		if #data == 0 then emptyNote() meta.Text = "" return end
		local tot = math.max(total(), 0.0001)
		meta.Text = fmt(total())
		local cols = datumColors()
		local bounds = {}
		local acc = 0
		for i, d in ipairs(data) do
			acc = acc + math.max(tonumber(d.value) or 0, 0) / tot
			bounds[i] = acc
		end
		local side = ch - 16
		local holder = Instance.new("Frame")
		holder.AnchorPoint = Vector2.new(0, 0.5)
		holder.Position = UDim2.new(0, 10, 0.5, 0)
		holder.Size = UDim2.new(0, side, 0, side)
		holder.BackgroundTransparency = 1
		holder.Parent = panel
		local SEG = 48
		local R = side / 2 - 8
		local RING = 7
		local DIMC = Color3.fromRGB(48, 48, 56)
		for i = 0, SEG - 1 do
			local f0 = i / SEG
			local f1 = (i + 1) / SEG
			local frac = (f0 + f1) * 0.5
			local si = 1
			for k, b in ipairs(bounds) do
				si = k
				if frac <= b then break end
			end
			local a = frac * math.pi * 2 - math.pi / 2
			local chord = 2 * R * math.sin(math.pi / SEG) + 1.8
			local dt = Instance.new("Frame")
			dt.AnchorPoint = Vector2.new(0.5, 0.5)
			dt.Position = UDim2.new(0.5, math.cos(a) * R, 0.5, math.sin(a) * R)
			dt.Size = UDim2.new(0, math.ceil(chord), 0, RING)
			dt.Rotation = math.deg(a) + 90
			dt.BackgroundColor3 = DIMC
			dt.BorderSizePixel = 0
			dt.Parent = holder
			corner(dt, 2)
			tweenIn(dt, { BackgroundColor3 = cols[si] or DIMC }, i * 0.006, 0.3)
		end
		local tv = Instance.new("TextLabel")
		tv.Size = UDim2.new(1, 0, 0, 24)
		tv.AnchorPoint = Vector2.new(0.5, 0.5)
		tv.Position = UDim2.new(0.5, 0, 0.5, -7)
		tv.BackgroundTransparency = 1
		tv.Font = Enum.Font.GothamBold
		tv.TextSize = 18
		tv.TextColor3 = TXT_MAIN
		tv.Text = fmt(total())
		tv.Parent = holder
		win:ThemeRegister(tv, "text")
		local tc = Instance.new("TextLabel")
		tc.Size = UDim2.new(1, 0, 0, 12)
		tc.AnchorPoint = Vector2.new(0.5, 0.5)
		tc.Position = UDim2.new(0.5, 0, 0.5, 10)
		tc.BackgroundTransparency = 1
		tc.Font = Enum.Font.Code
		tc.TextSize = 10
		tc.TextColor3 = TXT_FAINT
		tc.Text = "total"
		tc.Parent = holder
		local leg = Instance.new("Frame")
		leg.Position = UDim2.new(0, side + 20, 0, 6)
		leg.Size = UDim2.new(1, -(side + 28), 1, -12)
		leg.BackgroundTransparency = 1
		leg.Parent = panel
		local ll = Instance.new("UIListLayout")
		ll.SortOrder = Enum.SortOrder.LayoutOrder
		ll.VerticalAlignment = Enum.VerticalAlignment.Center
		ll.Padding = UDim.new(0, 4)
		ll.Parent = leg
		local shown = 0
		for i, d in ipairs(data) do
			if shown >= 6 then break end
			shown = shown + 1
			local lr = Instance.new("Frame")
			lr.Size = UDim2.new(1, 0, 0, 16)
			lr.BackgroundTransparency = 1
			lr.LayoutOrder = i
			lr.Parent = leg
			local chip = Instance.new("Frame")
			chip.Size = UDim2.new(0, 10, 0, 10)
			chip.Position = UDim2.new(0, 0, 0.5, -5)
			chip.BackgroundColor3 = cols[i]
			chip.BorderSizePixel = 0
			chip.Parent = lr
			corner(chip, 3)
			local lb = Instance.new("TextLabel")
			lb.Size = UDim2.new(1, -104, 1, 0)
			lb.Position = UDim2.new(0, 15, 0, 0)
			lb.BackgroundTransparency = 1
			lb.Font = Enum.Font.Gotham
			lb.TextSize = 11
			lb.TextXAlignment = Enum.TextXAlignment.Left
			lb.TextTruncate = Enum.TextTruncate.AtEnd
			lb.TextColor3 = TXT_DIM
			lb.Text = tostring(d.label or ("#" .. tostring(i)))
			lb.Parent = lr
			win:ThemeRegister(lb, "sub")
			local vv = Instance.new("TextLabel")
			vv.Size = UDim2.new(0, 88, 1, 0)
			vv.AnchorPoint = Vector2.new(1, 0)
			vv.Position = UDim2.new(1, 0, 0, 0)
			vv.BackgroundTransparency = 1
			vv.Font = Enum.Font.Code
			vv.TextSize = 10
			vv.TextXAlignment = Enum.TextXAlignment.Right
			vv.TextTruncate = Enum.TextTruncate.AtEnd
			vv.TextColor3 = TXT_MAIN
			local share = math.floor((tonumber(d.value) or 0) / tot * 100 + 0.5)
			vv.Text = fmt(d.value) .. "   " .. tostring(share) .. "%"
			vv.Parent = lr
			win:ThemeRegister(vv, "text")
		end
	end

	local function drawStat()
		clearPanel()
		meta.Text = ""
		local vv = Instance.new("TextLabel")
		vv.Size = UDim2.new(1, -16, 0, 40)
		vv.Position = UDim2.new(0, 10, 0, 2)
		vv.BackgroundTransparency = 1
		vv.Font = Enum.Font.GothamBold
		vv.TextSize = 30
		vv.TextXAlignment = Enum.TextXAlignment.Left
		vv.TextColor3 = TXT_MAIN
		vv.Text = fmt(shownV)
		vv.Parent = panel
		win:ThemeRegister(vv, "text")
		obj._statLabel = vv
		local bx = 10
		if statD ~= nil and tonumber(statD) then
			local sd = tonumber(statD)
			local pill = Instance.new("Frame")
			pill.Size = UDim2.new(0, 0, 0, 20)
			pill.AutomaticSize = Enum.AutomaticSize.X
			pill.Position = UDim2.new(0, 10, 0, 46)
			pill.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
			pill.BorderSizePixel = 0
			pill.Parent = panel
			corner(pill, 5)
			stroke(pill, LINE, 0, 1)
			local pp = Instance.new("UIPadding")
			pp.PaddingLeft = UDim.new(0, 8)
			pp.PaddingRight = UDim.new(0, 8)
			pp.Parent = pill
			local dt = Instance.new("TextLabel")
			dt.Size = UDim2.new(0, 0, 1, 0)
			dt.AutomaticSize = Enum.AutomaticSize.X
			dt.BackgroundTransparency = 1
			dt.Font = Enum.Font.Code
			dt.TextSize = 11
			-- monochrome trend: direction is carried by the glyph, not by hue
			dt.TextColor3 = (sd >= 0) and TXT_MAIN or TXT_SOFT
			dt.Text = (sd >= 0 and "+" or "") .. fmt(sd)
			dt.Parent = pill
			bx = 10
		end
		if statCap ~= "" then
			local cp = Instance.new("TextLabel")
			cp.Size = UDim2.new(1, -20, 0, 16)
			cp.Position = UDim2.new(0, 10, 0, ch - 22)
			cp.BackgroundTransparency = 1
			cp.Font = Enum.Font.Gotham
			cp.TextSize = 11
			cp.TextXAlignment = Enum.TextXAlignment.Left
			cp.TextTruncate = Enum.TextTruncate.AtEnd
			cp.TextColor3 = TXT_FAINT
			cp.Text = statCap
			cp.Parent = panel
		end
	end

	local function gcols()
		if palOpt == "accent" then
			local a = win:_tc("accent", Color3.fromRGB(255, 255, 255))
			return a, a
		end
		local pal = palette()
		local from = pal[1] or Color3.fromRGB(255, 255, 255)
		local to = pal[2] or from
		if type(palOpt) == "table" then
			if typeof(palOpt[1]) == "Color3" then from = palOpt[1] end
			if typeof(palOpt[2]) == "Color3" then to = palOpt[2] end
		end
		return from, to
	end

	-- streaming smooth graph: Catmull-Rom curve, gradient stroke, area fill,
	-- draw-on sweep animation, avg line, glowing head. Built for Push/Stream.
	local function renderGraph(sweep, xoff)
		if #data == 0 then return end
		if not sweep then drawId = drawId + 1 end -- cancel pending sweep tweens
		xoff = tonumber(xoff) or 0
		local P = gPool
		if (not P) or (not P.plot) or (not P.plot.Parent) then return end
		local fromC, toC = gcols()
		local vis = {}
		for i = math.max(1, #data - window + 1), #data do vis[#vis + 1] = data[i] end
		local m = #vis
		if m == 0 then return end
		local mn, mx, sum = 1e18, -1e18, 0
		for _, d in ipairs(vis) do
			local v = tonumber(d.value) or 0
			mn = math.min(mn, v)
			mx = math.max(mx, v)
			sum = sum + v
		end
		local avg = sum / m
		local rawHi = mx
		-- range floor: tiny noise (e.g. 60 -> 59 fps) must never stretch to
		-- full plot height. Enforce a minimum span relative to the signal.
		if mx - mn < math.max(1e-6, math.abs(avg) * 0.08) then
			local half = math.max(0.5, math.abs(avg) * 0.04)
			mn, mx = avg - half, avg + half
		end
		local pad = (mx - mn) * 0.15
		mn, mx = mn - pad, mx + pad
		-- eased range: glide the scale toward its target instead of jumping,
		-- kills vertical jitter while streaming
		if P.rMn == nil or sweep then
			P.rMn, P.rMx = mn, mx
		else
			P.rMn = P.rMn + (mn - P.rMn) * 0.35
			P.rMx = P.rMx + (mx - P.rMx) * 0.35
		end
		mn, mx = P.rMn, P.rMx
		meta.Text = fmt(tonumber(vis[m].value) or 0)
		P.hi.Text = fmt(rawHi)
		P.av.Text = fmt(avg)
		if showLab and m > 1 then
			P.xa.Text = tostring(vis[1].label or "")
			P.xb.Text = tostring(vis[m].label or "")
			P.xa.Visible = true
			P.xb.Visible = true
		else
			P.xa.Visible = false
			P.xb.Visible = false
		end
		local plot = P.plot
		local host = P.slide or plot
		local function yf(v) return 1 - (v - mn) / (mx - mn) end
		local xs, ys = {}, {}
		local xspan = (m == 1) and 0 or (1 - 2 * GX_PAD)
		local xslot = (m == 1) and 0 or (xspan / (m - 1))
		for i = 1, m do
			xs[i] = (m == 1) and 0.5 or (GX_PAD + xspan * (i - 1) / (m - 1) + xoff * xslot)
			ys[i] = yf(tonumber(vis[i].value) or 0)
		end
		-- columns overlap slightly so the fill reads as one surface, not bars
		local colW = (m == 1) and 1 or (1.06 / (m - 1))
		while #P.cols < m do
			local ac = Instance.new("Frame")
			ac.AnchorPoint = Vector2.new(0.5, 1)
			ac.BackgroundTransparency = 0.85
			ac.BorderSizePixel = 0
			ac.Visible = false
			ac.Parent = host
			P.cols[#P.cols + 1] = ac
		end
		for i = 1, #P.cols do
			local ac = P.cols[i]
			if i <= m then
				ac.Visible = true
				ac.BackgroundColor3 = toC
				ac.Position = UDim2.new(xs[i], 0, 1, 0)
				if sweep then
					ac.Size = UDim2.new(colW, 0, 0, 0)
					tweenIn(ac, { Size = UDim2.new(colW, 0, 1 - ys[i], 0) }, (i - 1) * 0.012, 0.3)
				else
					ac.Size = UDim2.new(colW, 0, 1 - ys[i], 0)
				end
			else
				ac.Visible = false
			end
		end
		local samples = {}
		if smooth and m >= 3 then
			local SUB = 6
			local function cr(p0, p1, p2, p3, t)
				local t2, t3 = t * t, t * t * t
				return 0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3)
			end
			for i = 1, m - 1 do
				local p0 = ys[math.max(1, i - 1)]
				local p1, p2 = ys[i], ys[i + 1]
				local p3 = ys[math.min(m, i + 2)]
				for s = 0, SUB - 1 do
					local t = s / SUB
					samples[#samples + 1] = { xs[i] + (xs[i + 1] - xs[i]) * t, math.clamp(cr(p0, p1, p2, p3, t), -0.05, 1.05) }
				end
			end
			samples[#samples + 1] = { 1, ys[m] }
		else
			for i = 1, m do samples[i] = { xs[i], ys[i] } end
		end
		local function buildPx()
			if dead or not plot.Parent then return end
			local pw, phh = plot.AbsoluteSize.X, plot.AbsoluteSize.Y
			if pw < 10 or phh < 10 then return end
			local need = math.max(0, #samples - 1)
			while #P.segs < need do
				local sg = Instance.new("Frame")
				sg.AnchorPoint = Vector2.new(0.5, 0.5)
				sg.BackgroundTransparency = 0
				sg.BorderSizePixel = 0
				sg.Visible = false
				sg.ZIndex = 2
				sg.Parent = host
				P.segs[#P.segs + 1] = sg
			end
			while #P.glow < need do
				local gl2 = Instance.new("Frame")
				gl2.AnchorPoint = Vector2.new(0.5, 0.5)
				gl2.BackgroundTransparency = 0.8
				gl2.BorderSizePixel = 0
				gl2.Visible = false
				gl2.ZIndex = 1
				gl2.Parent = host
				P.glow[#P.glow + 1] = gl2
			end
			for i = need + 1, #P.glow do P.glow[i].Visible = false end
			for i = 1, #P.segs do
				local sg = P.segs[i]
				if i <= need then
					local s1, s2 = samples[i], samples[i + 1]
					local ax, ay = s1[1] * pw, s1[2] * phh
					local bx, by = s2[1] * pw, s2[2] * phh
					local dx, dy = bx - ax, by - ay
					local len = math.sqrt(dx * dx + dy * dy)
					local gl2 = P.glow[i]
					if len >= 0.25 and gl2 then
						-- center anchor + midpoint: Roblox rotates around the
						-- rect center, so the center must sit exactly halfway
						-- between samples. +4px swallowed seams, square ends.
						-- soft underlay (glow) rides the same geometry.
						local ang = math.atan2(dy, dx)
						local cx, cy = (ax + bx) * 0.5, (ay + by) * 0.5
						local gc = fromC:Lerp(toC, s1[1])
						local rot = math.deg(ang)
						sg.Visible = true
						sg.Size = UDim2.new(0, len + 4, 0, thick)
						sg.Position = UDim2.new(0, cx, 0, cy)
						sg.Rotation = rot
						sg.BackgroundColor3 = gc
						gl2.Visible = true
						gl2.Size = UDim2.new(0, len + 4, 0, thick * 3 + 3)
						gl2.Position = UDim2.new(0, cx, 0, cy)
						gl2.Rotation = rot
						gl2.BackgroundColor3 = gc
						if sweep then
							sg.BackgroundTransparency = 1
							tweenIn(sg, { BackgroundTransparency = 0 }, s1[1] * 0.6, 0.25)
							gl2.BackgroundTransparency = 1
							tweenIn(gl2, { BackgroundTransparency = 0.8 }, s1[1] * 0.6, 0.25)
						else
							sg.BackgroundTransparency = 0
							gl2.BackgroundTransparency = 0.8
						end
					else
						sg.Visible = false
						if gl2 then gl2.Visible = false end
					end
				else
					sg.Visible = false
				end
			end
			local hx, hy = samples[#samples][1], samples[#samples][2]
			P.halo.Position = UDim2.new(hx, 0, hy, 0)
			P.head.Position = UDim2.new(hx, 0, hy, 0)
			local haloSz = 8 + thick * 3
			local headSz = 4 + thick * 2
			if sweep then
				P.halo.Size = UDim2.new(0, 6, 0, 6)
				tweenIn(P.halo, { Size = UDim2.new(0, haloSz, 0, haloSz) }, 0.55, 0.35)
				P.head.Size = UDim2.new(0, 4, 0, 4)
				P.head.BackgroundTransparency = 1
				tweenIn(P.head, { Size = UDim2.new(0, headSz, 0, headSz), BackgroundTransparency = 0 }, 0.55, 0.3)
			else
				P.halo.Size = UDim2.new(0, haloSz, 0, haloSz)
				P.head.Size = UDim2.new(0, headSz, 0, headSz)
				P.head.BackgroundTransparency = 0
			end
			local ay = yf(avg)
			if ay > 0.02 and ay < 0.98 then
				P.avgLine.Visible = true
				P.avgLine.Position = UDim2.new(0, 0, ay, 0)
			else
				P.avgLine.Visible = false
			end
		end
		if plot.AbsoluteSize.Y > 10 then buildPx()
		elseif sweep then task.defer(function() if not dead then buildPx() end end) end
	end

	local function drawGraph()
		clearPanel()
		gPool = nil
		if #data == 0 then emptyNote("No data - Push() or Stream()") meta.Text = "" return end
		local topPad, botPad, lPad, rPad = 10, 18, 38, 8
		for i = 1, 3 do
			local gl = Instance.new("Frame")
			gl.Size = UDim2.new(1, -46, 0, 1)
			gl.Position = UDim2.new(0, 38, 0, math.floor(ch * i / 4))
			gl.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			gl.BackgroundTransparency = 0.93
			gl.BorderSizePixel = 0
			gl.Parent = panel
		end
		local hi = Instance.new("TextLabel")
		hi.Size = UDim2.new(0, 32, 0, 12)
		hi.Position = UDim2.new(0, 2, 0, 2)
		hi.BackgroundTransparency = 1
		hi.Font = Enum.Font.Code
		hi.TextSize = 9
		hi.TextXAlignment = Enum.TextXAlignment.Right
		hi.TextColor3 = TXT_FAINT
		hi.Text = ""
		hi.Parent = panel
		local av = Instance.new("TextLabel")
		av.Size = UDim2.new(0, 32, 0, 12)
		av.AnchorPoint = Vector2.new(0, 1)
		av.Position = UDim2.new(0, 2, 1, -2)
		av.BackgroundTransparency = 1
		av.Font = Enum.Font.Code
		av.TextSize = 9
		av.TextXAlignment = Enum.TextXAlignment.Right
		av.TextColor3 = TXT_FAINT
		av.Text = ""
		av.Parent = panel
		local plot = Instance.new("Frame")
		plot.Size = UDim2.new(1, -(lPad + rPad), 1, -(topPad + botPad))
		plot.Position = UDim2.new(0, lPad, 0, topPad)
		plot.BackgroundTransparency = 1
		plot.ClipsDescendants = true
		plot.Parent = panel
		local slide = Instance.new("Frame")
		slide.Name = "Slide"
		slide.Size = UDim2.new(1, 0, 1, 0)
		slide.BackgroundTransparency = 1
		slide.Parent = plot
		local al = Instance.new("Frame")
		al.Size = UDim2.new(1, 0, 0, 1)
		al.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		al.BackgroundTransparency = 0.75
		al.BorderSizePixel = 0
		al.Visible = false
		al.Parent = slide
		local xa = Instance.new("TextLabel")
		xa.Size = UDim2.new(0, 60, 0, 12)
		xa.Position = UDim2.new(0, lPad, 1, -14)
		xa.BackgroundTransparency = 1
		xa.Font = Enum.Font.Code
		xa.TextSize = 9
		xa.TextXAlignment = Enum.TextXAlignment.Left
		xa.TextColor3 = TXT_FAINT
		xa.TextTruncate = Enum.TextTruncate.AtEnd
		xa.Text = ""
		xa.Visible = false
		xa.Parent = panel
		local xb = Instance.new("TextLabel")
		xb.Size = UDim2.new(0, 60, 0, 12)
		xb.AnchorPoint = Vector2.new(1, 0)
		xb.Position = UDim2.new(1, -rPad, 1, -14)
		xb.BackgroundTransparency = 1
		xb.Font = Enum.Font.Code
		xb.TextSize = 9
		xb.TextXAlignment = Enum.TextXAlignment.Right
		xb.TextColor3 = TXT_FAINT
		xb.TextTruncate = Enum.TextTruncate.AtEnd
		xb.Text = ""
		xb.Visible = false
		xb.Parent = panel
		local halo = Instance.new("Frame")
		halo.AnchorPoint = Vector2.new(0.5, 0.5)
		halo.Position = UDim2.new(0.5, 0, 0.5, 0)
		halo.Size = UDim2.new(0, 6, 0, 6)
		halo.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		halo.BackgroundTransparency = 0.65
		halo.BorderSizePixel = 0
		halo.Parent = slide
		corner(halo, 7)
		local head = Instance.new("Frame")
		head.AnchorPoint = Vector2.new(0.5, 0.5)
		head.Position = UDim2.new(0.5, 0, 0.5, 0)
		head.Size = UDim2.new(0, 4, 0, 4)
		head.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		head.BackgroundTransparency = 1
		head.BorderSizePixel = 0
		head.ZIndex = 3
		head.Parent = slide
		corner(head, 4)
		gPool = { plot = plot, slide = slide, hi = hi, av = av, avgLine = al, xa = xa, xb = xb, head = head, halo = halo, segs = {}, cols = {}, glow = {}, scrollTw = nil, scrollId = 0 }
		renderGraph(true, 0)
	end

	-- streaming push: the strip glides one slot left instead of jumping.
	-- geometry is rendered pre-shifted (+1 slot, carried points keep exact
	-- screen pos), then the slide container tweens to -1 slot. Seamless.
	local function graphPush()
		local P = gPool
		if (not P) or (not P.plot) or (not P.plot.Parent) then draw() return end
		local m = math.min(#data, window)
		local pw = P.plot.AbsoluteSize.X
		if #data < window or m < 2 or pw < 10 then
			renderGraph(false, 0)
			return
		end
		if P.scrollTw then pcall(function() P.scrollTw:Cancel() end) P.scrollTw = nil end
		P.scrollId = (P.scrollId or 0) + 1
		P.slide.Position = UDim2.new(0, 0, 0, 0)
		renderGraph(false, 1)
		local slotPx = ((1 - 2 * GX_PAD) / (m - 1)) * pw
		-- Linear at ~interval speed: constant-velocity conveyor, no
		-- stop-start stutter between pushes
		local dur = math.min(0.25 / (speed or 1), 0.24)
		local sid = P.scrollId
		local okTw, tw = pcall(function()
			return TweenService:Create(P.slide, TweenInfo.new(dur, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), { Position = UDim2.new(0, -slotPx, 0, 0) })
		end)
		if not okTw or not tw then renderGraph(false, 0) return end
		P.scrollTw = tw
		tw.Completed:Connect(function(st)
			if st ~= Enum.PlaybackState.Completed then return end
			if dead or P.scrollId ~= sid then return end
			if not P.plot or not P.plot.Parent then return end
			P.scrollTw = nil
			P.slide.Position = UDim2.new(0, 0, 0, 0)
			renderGraph(false, 0)
		end)
		tw:Play()
	end

	-- a full rebuild is cheap but not free: streams coalesce to 5 redraws/s
	local lastDraw, drawQueued = 0, false
	local function drawSoft()
		if dead then return end
		local now = os.clock()
		local gap = now - lastDraw
		if gap >= 0.2 then
			lastDraw = now
			draw()
			return
		end
		if drawQueued then return end
		drawQueued = true
		task.delay(0.2 - gap, function()
			drawQueued = false
			if dead then return end
			lastDraw = os.clock()
			draw()
		end)
	end

	obj = {}
	draw = function()
		if dead then return end
		drawId = drawId + 1
		if ctype == "bar" then drawBar()
		elseif ctype == "line" then drawLine(false)
		elseif ctype == "spark" then drawLine(true)
		elseif ctype == "donut" then drawDonut()
		elseif ctype == "stat" then drawStat()
		elseif ctype == "graph" then drawGraph() end
	end
	function obj:SetData(t)
		if ctype == "stat" then
			if type(t) == "table" then
				if t.value ~= nil then statV = tonumber(t.value) or statV end
				if t.delta ~= nil then statD = t.delta end
				if t.caption ~= nil then statCap = tostring(t.caption) end
			elseif tonumber(t) then
				statV = tonumber(t)
			end
			obj:SetValue(statV, statD, statCap)
			return
		end
		ingest(t)
		draw()
	end
	function obj:Push(label, value)
		if ctype == "stat" then
			obj:SetValue(tonumber(label) or tonumber(value) or statV, statD, statCap)
			return
		end
		if value == nil and tonumber(label) then value, label = label, "" end
		table.insert(data, { label = tostring(label or ""), value = tonumber(value) or 0 })
		while #data > maxPts do table.remove(data, 1) end
		if ctype == "graph" then
			graphPush()
		else
			drawSoft()
		end
	end
	function obj:SetValue(v, delta, caption)
		statV = tonumber(v) or statV
		if delta ~= nil then statD = delta end
		if caption ~= nil then statCap = tostring(caption) end
		local from = shownV
		shownV = statV
		draw()
		if animated and obj._statLabel and obj._statLabel.Parent and math.abs(statV - from) > 0.0001 then
			local lab = obj._statLabel
			local bid = drawId
			task.spawn(function()
				local steps = 12
				for s = 1, steps do
					if dead or bid ~= drawId then return end
					if not lab.Parent then return end
					local t = s / steps
					pcall(function() lab.Text = fmt(from + (statV - from) * t) end)
					task.wait(0.03)
				end
			end)
		end
	end
	local function ensureAccent()
		if accentConn or palOpt ~= "accent" then return end
		local ev = win._accentChanged
		if ev and ev.Event then
			local ok, cn = pcall(function()
				return ev.Event:Connect(function()
					if dead then return end
					if palOpt == "accent" then draw() end
				end)
			end)
			if ok and cn then accentConn = cn end
		end
	end
	function obj:SetColors(p)
		if type(p) == "string" or typeof(p) == "Color3" or (type(p) == "table" and #p > 0) then
			palOpt = (typeof(p) == "Color3") and { p } or p
			ensureAccent()
			draw()
		end
	end
	function obj:SetThickness(t)
		t = tonumber(t)
		if t then thick = math.clamp(t, 1, 6) draw() end
	end
	function obj:SetAnimationSpeed(s)
		s = tonumber(s)
		if s then speed = math.clamp(s, 0.25, 4) end
	end
	function obj:SetTitle(t) title.Text = tostring(t or "") end
	function obj:SetFormat(fn) if type(fn) == "function" then fmt = fn draw() end end
	function obj:SetType(t)
		t = string.lower(tostring(t or ""))
		if TYPES[t] and t ~= ctype then
			ctype = t
			if ctype == "stat" then shownV = statV end
			draw()
		end
	end
	function obj:GetData()
		local out = {}
		for i, d in ipairs(data) do out[i] = { label = d.label, value = d.value } end
		return out
	end
	function obj:GetTotal() return total() end
	function obj:Clear()
		data = {}
		statV, statD, shownV = 0, nil, 0
		draw()
	end
	function obj:Refresh() draw() end
	function obj:SetWindow(n)
		n = math.floor(tonumber(n) or window)
		window = math.clamp(n, 5, maxPts)
		draw()
	end
	function obj:SetSmooth(b) smooth = not not b draw() end
	function obj:Stop()
		if streamConn then pcall(function() streamConn:Disconnect() end) streamConn = nil end
	end
	-- live stream: fn() is sampled every `interval` sec and pushed.
	-- fn == nil means built-in FPS meter. Returns nothing; call Stop() to end.
	function obj:Stream(fn, interval)
		obj:Stop()
		if dead then return false end
		streamFn = (type(fn) == "function") and fn or nil
		streamInt = math.clamp(tonumber(interval) or 0.25, 0.1, 5)
		-- frame counter stays a one-line callback; sampling runs on a timer
		local frames, t0 = 0, os.clock()
		streamConn = RunService.RenderStepped:Connect(function()
			if dead then return end
			frames = frames + 1
		end)
		task.spawn(function()
			while not dead and streamConn do
				task.wait(streamInt)
				if dead or not streamConn then break end
				local now = os.clock()
				local span = math.max(now - t0, 1e-3)
				local v
				if streamFn then
					local ok, r = pcall(streamFn)
					v = (ok and tonumber(r)) or nil
				else
					v = frames / span
				end
				frames, t0 = 0, now
				if v ~= nil then obj:Push("", v) end
			end
		end)
		return true
	end
	function obj:GetStats()
		local vis = {}
		for i = math.max(1, #data - window + 1), #data do vis[#vis + 1] = data[i] end
		if #vis == 0 then return { min = 0, max = 0, avg = 0, last = 0, count = 0 } end
		local mn, mx, sum = 1e18, -1e18, 0
		for _, d in ipairs(vis) do
			local v = tonumber(d.value) or 0
			mn = math.min(mn, v)
			mx = math.max(mx, v)
			sum = sum + v
		end
		return { min = mn, max = mx, avg = sum / #vis, last = tonumber(vis[#vis].value) or 0, count = #vis }
	end
	obj._draw = draw

	task.defer(function() if not dead then ensureAccent() draw() end end)
	return obj
end

function Section:AddKeybind(opts)
	local win = self._win
	local name = opts.Name or "Bind"
	local default = opts.Default
	local callback = opts.Callback or function() end

	local row = Instance.new("Frame")
	row.Name = "Row_" .. name
	row.Size = UDim2.new(1, 0, 0, 38)
	row.BackgroundColor3 = BG_HOVER
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.Parent = self._body
	row.LayoutOrder = #self._body:GetChildren()
	corner(row, 6)
	hoverRow(row)
	win._registerRow(row, name, self)
	if opts.Tooltip then win:_attachTip(row, opts.Tooltip) end

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -90, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = TXT_MAIN
	label.Text = name
	label.Parent = row
	win:ThemeRegister(label, "text")

	local pill = Instance.new("TextButton")
	pill.Size = UDim2.new(0, 62, 0, 22)
	pill.AnchorPoint = Vector2.new(1, 0.5)
	pill.Position = UDim2.new(1, -10, 0.5, 0)
	pill.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
	pill.Font = Enum.Font.GothamBold
	pill.TextSize = 11
	pill.TextColor3 = (default and win:_tc("text") or win:_tc("sub"))
	pill.Text = default and default.Name or "NONE"
	pill.TextTruncate = Enum.TextTruncate.AtEnd
	pill.AutoButtonColor = false
	pill.Parent = row
	corner(pill, 5)
	stroke(pill, Color3.fromRGB(39, 39, 42), 0, 1)
	pill.MouseEnter:Connect(function()
		TweenService:Create(pill, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(48, 48, 56)}):Play()
	end)
	pill.MouseLeave:Connect(function()
		if pill:GetAttribute("Held") then
			TweenService:Create(pill, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(58, 58, 68)}):Play()
		else
			TweenService:Create(pill, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 34)}):Play()
		end
	end)

	local bound = default
	local tabIcon = nil
	pcall(function()
		local tb = self._tab
		if tb then
			tabIcon = tb._icon
			if tb._isSub and tb._parent and (tabIcon == nil or tabIcon == "circle") then tabIcon = tb._parent._icon end
		end
	end)
	local entry = { name = name, get = function() return bound end, held = false, toggle = opts.Toggle, tabIcon = tabIcon }
	table.insert(win._keybinds, entry)
	win._kbWatch = win._kbWatch or {}
	table.insert(win._kbWatch, { pill = pill, entry = entry, get = function() return bound end })
	if not win._kbWatchConn then
		win._kbWatchConn = true
		UserInputService.WindowFocusReleased:Connect(function()
			for _, w in ipairs(win._kbWatch) do
				pcall(function()
					w.entry.held = false
					w.pill:SetAttribute("Held", false)
					w.pill.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
					w.pill.TextColor3 = (w.get() and win:_tc("text") or win:_tc("sub"))
				end)
			end
			win._refreshKeyList()
		end)
	end
	local listening = false
	local conn = nil
	local pulse = nil
	local function stopListen()
		listening = false
		if conn then conn:Disconnect() conn = nil end
		if pulse then task.cancel(pulse) pulse = nil end
		pill.BackgroundTransparency = 0
		pill.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
		pill.TextColor3 = (bound and win:_tc("text") or win:_tc("sub"))
	end
	-- press feedback: flash section pill + keylist row while bound key is held
	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if listening then return end
		if input.UserInputType == Enum.UserInputType.Keyboard and bound and not entry.held and input.KeyCode == bound then
			entry.held = true
			win._refreshKeyList()
			pill:SetAttribute("Held", true)
			TweenService:Create(pill, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(58, 58, 68), TextColor3 = win:_tc("text")}):Play()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Keyboard and bound and entry.held and input.KeyCode == bound then
			entry.held = false
			win._refreshKeyList()
			pill:SetAttribute("Held", false)
			TweenService:Create(pill, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 34), TextColor3 = (bound and win:_tc("text") or win:_tc("sub"))}):Play()
		end
	end)
	pill.MouseButton1Click:Connect(function()
		if listening then stopListen() pill.Text = bound and bound.Name or "NONE" return end
		listening = true
		pill.Text = "..."
		pill.TextColor3 = win:_tc("text")
		pulse = task.spawn(function()
			while listening and pill.Parent do
				TweenService:Create(pill, TweenInfo.new(0.4), {BackgroundTransparency = 0.4}):Play()
				task.wait(0.42)
				if not listening then break end
				TweenService:Create(pill, TweenInfo.new(0.4), {BackgroundTransparency = 0}):Play()
				task.wait(0.42)
			end
		end)
		conn = UserInputService.InputBegan:Connect(function(input, gpe)
			if not listening then return end
			if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
			local kc = input.KeyCode
			if kc == Enum.KeyCode.Escape then
				stopListen()
				pill.Text = bound and bound.Name or "NONE"
				return
			end
			if kc == Enum.KeyCode.Backspace then
				stopListen()
				bound = nil
				win._dirty = true
				pill.Text = "NONE"
				pill.TextColor3 = win:_tc("sub")
				pcall(callback, nil)
				win._refreshKeyList()
				print(string.format("[ATHERIUM] keybind '%s' cleared", name))
				return
			end
			if kc == Enum.KeyCode.RightShift then
				stopListen()
				pill.Text = bound and bound.Name or "NONE"
				win:Notify("Keybind", "RightShift is reserved for UI toggle")
				return
			end
			if kc == Enum.KeyCode.Unknown then return end
			stopListen()
			bound = kc
			win._dirty = true
			pill.Text = kc.Name
			pill.TextColor3 = win:_tc("text")
			clickSound(win._gui, function() return win._sounds end)
			pcall(callback, kc)
			print(string.format("[ATHERIUM] keybind '%s' -> %s", name, kc.Name))
			win._refreshKeyList()
		end)
	end)

	local obj = {}
	function obj:Get() return bound end
	function obj:Set(kc, fire)
		bound = kc
		pill.Text = kc and kc.Name or "NONE"
		pill.TextColor3 = (kc and win:_tc("text") or win:_tc("sub"))
		if fire ~= false then pcall(callback, kc) end
		win._refreshKeyList()
	end
	table.insert(win._cfg, { kind = "keybind", tab = self._tab._name, sec = self._title or "?", name = name, get = function() local k = obj:Get() return k and k.Name or nil end, set = function(v) local kc = nil pcall(function() kc = Enum.KeyCode[v] end) obj:Set(kc, true) end })
	if bound then pcall(callback, bound) end
	win._refreshKeyList()
	return obj
end

function Section:AddLabel(text)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, 0, 0, 20)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.Gotham
	l.TextSize = 12
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextColor3 = TXT_DIM
	l.Text = tostring(text)
	l.Parent = self._body
	l.LayoutOrder = #self._body:GetChildren()
	return l
end

-- two side-by-side columns inside one card; returns left, right proxy sections
function Section:AddColumns()
	local win = self._win
	local wrap = Instance.new("Frame")
	wrap.Name = "Cols"
	wrap.Size = UDim2.new(1, 0, 0, 0)
	wrap.AutomaticSize = Enum.AutomaticSize.Y
	wrap.BackgroundTransparency = 1
	wrap.Parent = self._body
	wrap.LayoutOrder = #self._body:GetChildren()
	local lay = Instance.new("UIListLayout")
	lay.FillDirection = Enum.FillDirection.Horizontal
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Padding = UDim.new(0, 8)
	lay.Parent = wrap
	local function mkCol(order)
		local c = Instance.new("Frame")
		c.Size = UDim2.new(0.5, -4, 0, 0)
		c.AutomaticSize = Enum.AutomaticSize.Y
		c.BackgroundTransparency = 1
		c.Parent = wrap
		c.LayoutOrder = order
		local l = Instance.new("UIListLayout")
		l.SortOrder = Enum.SortOrder.LayoutOrder
		l.Padding = UDim.new(0, 4)
		l.Parent = c
		return c
	end
	local function proxy(body)
		return setmetatable({ _win = win, _body = body, _tab = self._tab, _card = self._card, _head = self._head, _title = self._title }, Section)
	end
	return proxy(mkCol(1)), proxy(mkCol(2))
end

--// ================= TAB =================
local Tab = {}
Tab.__index = Tab

function Tab:AddSection(title, iconName)
	local win = self._win
	local head = Instance.new("Frame")
	head.Name = "Head_" .. tostring(title)
	head.Size = UDim2.new(1, 0, 0, 22)
	head.BackgroundTransparency = 1
	head.Parent = self._page
	head.LayoutOrder = #self._page:GetChildren()
	makeIcon(head, iconName or "chevron-down", 13, ICON_DIM, UDim2.new(0, 2, 0.5, -6))
	local ht = Instance.new("TextLabel")
	ht.Size = UDim2.new(1, -22, 1, 0)
	ht.Position = UDim2.new(0, 20, 0, 0)
	ht.BackgroundTransparency = 1
	ht.Font = Enum.Font.GothamBold
	ht.TextSize = 12
	ht.TextXAlignment = Enum.TextXAlignment.Left
	ht.TextColor3 = TXT_HEAD
	ht.Text = string.upper(tostring(title))
	ht.Parent = head
	win:ThemeRegister(ht, "sub")

	local card = Instance.new("Frame")
	card.Name = "Card_" .. tostring(title)
	card.Size = UDim2.new(1, 0, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundColor3 = BG_CARD
	card.BorderSizePixel = 0
	card.ClipsDescendants = false
	card.Parent = self._page
	card.LayoutOrder = #self._page:GetChildren()
	corner(card, 10)
	stroke(card, LINE, 0, 1)
	hairline(card, 0)
	win._glass(card, 0.34)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 14)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 6)
	pad.PaddingRight = UDim.new(0, 6)
	pad.Parent = card
	local lay = Instance.new("UIListLayout")
	lay.Padding = UDim.new(0, 4)
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Parent = card

	local sec = setmetatable({ _win = win, _body = card, _head = head, _card = card, _tab = self }, Section)
	sec._title = tostring(title)
	table.insert(win._sections, sec)
	return sec
end

--// ================= WINDOW (left sidebar) =================
function VibeUI:CreateWindow(opts)
	opts = opts or {}
	local title = opts.Title or "VIBE HUB"
	local subtitle = opts.Subtitle or ("v" .. VibeUI.Version .. " mono")
	local accent = opts.Accent or ACCENT_DEFAULT

	local gui = Instance.new("ScreenGui")
	gui.Name = "Atherium"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.IgnoreGuiInset = true
	local okHui, hui = pcall(function() return gethui and gethui() end)
	if okHui and typeof(hui) == "Instance" then gui.Parent = hui
	else gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

	local win = setmetatable({
		_gui = gui,
		_accent = accent,
		_sounds = true,
		_accentChanged = Instance.new("BindableEvent"),
		_tabs = {},
		_sections = {},
		_themeListeners = {},
		_rowRegs = {},
	}, VibeUI)

	function win._reg(fn)
		table.insert(win._themeListeners, fn)
		pcall(fn, win._accent)
	end
	function win:SetAccent(c)
		if typeof(c) ~= "Color3" then return end
		win._accent = c
		win._theme.accent = c
		win._theme.accentTouched = true
		win._dirty = true
		for _, fn in ipairs(win._themeListeners) do pcall(fn, c) end
		win._accentChanged:Fire(c)
		win:ApplyTheme(gui)
	end
	function win._registerRow(row, name, sec)
		table.insert(win._rowRegs, { row = row, name = tostring(name):lower(), sec = sec })
		win:ApplyTheme(row) -- newborn rows inherit the active theme (async, throttled)
	end

	--// ================= THEME (fonts + text/sub/accent colors, nil = untouched) =================
	win._theme = {
		fontName = nil, body = nil, head = nil, prevBody = nil, prevHead = nil,
		accent = nil, accentTouched = false, text = nil, sub = nil,
	}
	win._accentDefault = accent
	local THEME_WHITE = Color3.fromRGB(255, 255, 255)
	local THEME_SUBS = {
		[Color3.fromRGB(138, 138, 147)] = true, -- TXT_DIM
		[Color3.fromRGB(118, 118, 128)] = true, -- TXT_SOFT
		[Color3.fromRGB(170, 170, 180)] = true, -- TXT_HEAD (legacy const)
		[Color3.fromRGB(130, 130, 140)] = true, -- TXT_SIDEBAR
		[Color3.fromRGB(161, 161, 170)] = true, -- key letters idle
		[Color3.fromRGB(235, 235, 240)] = true, -- title pale
	}
	-- (font tables live top-level: ValidFonts / THEME_HEADS / resolveFont)
	local THEME_HEADS_BROKEN = {
		Gotham = "GothamBold", Montserrat = "MontserratBold", Roboto = "RobotoBold",
		SourceSans = "SourceSansBold", Arial = "ArialBold", Code = "Code",
	}
	local function resolveFontBroken(name)
		local ok, f = pcall(function() return Enum.Font[name] end)
		if ok and typeof(f) == "EnumItem" then return f end
		return nil
	end
	-- original per-instance values (weak: dead instances vanish). Enables Reset.
	local themeOrig = setmetatable({}, { __mode = "k" })
	local function themeOrigGet(inst, prop)
		local e = themeOrig[inst]
		if e and e[prop] ~= nil then return e[prop] end
		local ok, v = pcall(function() return inst[prop] end)
		if not ok then return nil end
		e = e or {}
		e[prop] = v
		themeOrig[inst] = e
		return v
	end
	-- tier role: text/sub share TextColor3, so remember who claimed the instance
	local function themeTierIs(inst, tier)
		local e = themeOrig[inst]
		return e and e._tier == tier
	end
	local function themeClaim(inst, tier, prop)
		themeOrigGet(inst, prop)
		local e = themeOrig[inst]
		if e then e._tier = tier end
	end
	local THEME_TWEEN = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	function win._doApplyTheme(root)
		if not root or not root.Parent then
			if root ~= gui then return end
		end
		local th = win._theme
		-- always scan live: weak-key registries proved unreliable across executors
		-- (drained 700 -> 265 entries). Steady-state cost is ~nil: paints skip at-target.
		local okRoot, des = pcall(function() return root:GetDescendants() end)
		if not okRoot or type(des) ~= "table" then return end
		local th = win._theme
		local bodyIsCode = (th.body ~= nil and th.body == Enum.Font.Code)
		win._themeStats = { n = 0, ok = 0, err = 0, lastErr = "" }
		local function paintOne(d)
			-- opt-out marker: fixed-typography labels (watermark metrics, keycaps)
			-- keep their own font/color hierarchy regardless of the theme font.
			if d:GetAttribute("KeepFont") then return end
			if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
				-- font tier (role-pinned: survives ANY pick order, no generation chains)
				if th.body then
					local src = d.Font
					local tgt, role = nil, nil
					local e0 = themeOrig[d]
					if src == Enum.Font.GothamMedium or src == Enum.Font.Gotham or src == Enum.Font.Legacy then
						tgt, role = th.body, "body"
					elseif src == Enum.Font.GothamBold or src == Enum.Font.GothamBlack then
						tgt, role = th.head, "head"
					elseif src == Enum.Font.Code and bodyIsCode then
						tgt, role = th.body, "body"
					elseif e0 and e0._frole == "body" then
						tgt, role = th.body, "body"
					elseif e0 and e0._frole == "head" then
						tgt, role = th.head, "head"
					end
					if tgt then
						themeOrigGet(d, "Font")
						local e = themeOrig[d]
						if e then e._frole = role end
						if d.Font ~= tgt then d.Font = tgt end
					end
				else
					local e = themeOrig[d]
					if e and e.Font and d.Font ~= e.Font then d.Font = e.Font end
					if e then e._frole = nil end
				end
				-- main text tier (pure white text only: buttons bg / fills are other classes)
				if th.text then
					local c = d.TextColor3
					local e0 = themeOrig[d]
					local lum = c.R * 0.299 + c.G * 0.587 + c.B * 0.114
					if c == THEME_WHITE or themeTierIs(d, "text")
						or ((e0 == nil or e0._tier == nil) and lum > 0.8 and not THEME_SUBS[c]) then
						themeClaim(d, "text", "TextColor3")
						if d.TextColor3 ~= th.text then
							TweenService:Create(d, THEME_TWEEN, { TextColor3 = th.text }):Play()
						end
					end
				else
					local e = themeOrig[d]
					if e and e._tier == "text" and e.TextColor3 and d.TextColor3 ~= e.TextColor3 then
						TweenService:Create(d, THEME_TWEEN, { TextColor3 = e.TextColor3 }):Play()
					end
				end
				-- sub text tier
				if th.sub then
					if THEME_SUBS[d.TextColor3] or themeTierIs(d, "sub") then
						themeClaim(d, "sub", "TextColor3")
						if d.TextColor3 ~= th.sub then
							TweenService:Create(d, THEME_TWEEN, { TextColor3 = th.sub }):Play()
						end
					end
				else
					local e = themeOrig[d]
					if e and e._tier == "sub" and e.TextColor3 and d.TextColor3 ~= e.TextColor3 then
						TweenService:Create(d, THEME_TWEEN, { TextColor3 = e.TextColor3 }):Play()
					end
				end
				-- layout guard: single-line only; multiline (Wrapped=true) is respected
				if not d.TextWrapped then
					if d:IsA("TextLabel") or d:IsA("TextButton") then
						pcall(function() d.TextTruncate = Enum.TextTruncate.AtEnd end)
					end
				end
				pcall(function() d.RichText = false end)
				pcall(function() d.AutoLocalize = false end)
			elseif d:IsA("ImageLabel") then
				if th.accentTouched and th.accent then
					if d.ImageColor3 == ICON_MAIN or themeTierIs(d, "icon") then
						themeClaim(d, "icon", "ImageColor3")
						if d.ImageColor3 ~= th.accent then
							TweenService:Create(d, THEME_TWEEN, { ImageColor3 = th.accent }):Play()
						end
					end
				else
					local e = themeOrig[d]
					if e and e._tier == "icon" and e.ImageColor3 and d.ImageColor3 ~= e.ImageColor3 then
						TweenService:Create(d, THEME_TWEEN, { ImageColor3 = e.ImageColor3 }):Play()
					end
				end
			end
		end
		for _, d in ipairs(des) do
			win._themeStats.n = win._themeStats.n + 1
			local ok, err = pcall(paintOne, d)
			if ok then
				win._themeStats.ok = win._themeStats.ok + 1
			else
				win._themeStats.err = win._themeStats.err + 1
				win._themeStats.lastErr = tostring(err)
			end
		end
	end
	win._themePending, win._themeWalking = nil, false
	function win:ApplyTheme(root)
		root = root or gui
		-- trailing-edge throttle: color pickers fire per mousemove, walk once
		if win._themePending == nil then
			win._themePending = root
		elseif root == gui then
			win._themePending = gui
		end
		if win._themeWalking then return end
		win._themeWalking = true
		task.defer(function()
			task.wait(0.06)
			local r = win._themePending or gui
			win._themePending = nil
			win._themeWalking = false
			pcall(function() win._doApplyTheme(r) end)
		end)
	end
	-- cinematic font swap: veil + loader while layouts rebuild, then smooth reveal
	function win:FontSwapFX(rebuild)
		local m = win._main -- main is declared later; never capture it as an upvalue here
		if not m or not m.Parent or not m.Visible then
			pcall(rebuild)
			return
		end
		if win._fontSwap and win._fontSwap.Parent then
			-- debounce: veil already running — apply the new target behind it, extend reveal
			win._fontSwapDeadline = os.clock() + 0.9
			pcall(rebuild)
			return
		end
		win._fontSwap = nil
		local veil = Instance.new("Frame")
		veil.Name = "FontSwapVeil"
		veil.Size = UDim2.new(1, 0, 1, 0)
		veil.Position = UDim2.new(0, 0, 0, 0)
		veil.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		veil.BackgroundTransparency = 1
		veil.BorderSizePixel = 0
		veil.Active = true
		veil.ZIndex = 600
		veil.Parent = m
		corner(veil, 14)
		-- film grain so the dim feels like frost, not a flat shade
		local grain = Instance.new("ImageLabel")
		grain.Name = "SwapGrain"
		grain.Size = UDim2.new(1, 0, 1, 0)
		grain.BackgroundTransparency = 1
		grain.Image = "rbxassetid://9968344227"
		grain.ImageTransparency = 1
		grain.ScaleType = Enum.ScaleType.Tile
		grain.TileSize = UDim2.new(0, 128, 0, 128)
		grain.ZIndex = 601
		grain.Parent = veil
		corner(grain, 14)
		win._fontSwap = veil
		win._fontSwapDeadline = os.clock() + 0.9
		local dead = false
		-- floaters hide for the rebuild, return on reveal (stash survives re-entry)
		win._fontSwapGen = (win._fontSwapGen or 0) + 1
		local myGen = win._fontSwapGen
		win._swapHidden = win._swapHidden or {}
		pcall(function()
			for _, pn in ipairs(win._panels) do
				if pn and pn.Parent and pn.Visible then
					pn.Visible = false
					local dup = false
					for _, s in ipairs(win._swapHidden) do if s.inst == pn then dup = true break end end
					if not dup then table.insert(win._swapHidden, { inst = pn, wm = false }) end
				end
			end
			local wf = win._watermark and win._watermark.frame
			if wf and wf.Parent and wf.Visible then
				wf.Visible = false
				local dup = false
				for _, s in ipairs(win._swapHidden) do if s.inst == wf then dup = true break end end
				if not dup then table.insert(win._swapHidden, { inst = wf, wm = true }) end
			end
			local wmh = win._watermark
			if wmh and wmh.CloseMenu then wmh:CloseMenu() end
		end)
		local spin = makeIcon(veil, "refresh-cw", 18, TXT_MAIN, UDim2.new(0.5, -9, 0.5, -26))
		spin.ZIndex = 602
		spin.ImageTransparency = 1
		local msg = Instance.new("TextLabel")
		msg.Size = UDim2.new(1, 0, 0, 20)
		msg.Position = UDim2.new(0, 0, 0.5, 0)
		msg.BackgroundTransparency = 1
		msg.Font = Enum.Font.GothamMedium
		msg.TextSize = 13
		msg.TextColor3 = TXT_MAIN
		msg.TextXAlignment = Enum.TextXAlignment.Center
		msg.TextYAlignment = Enum.TextYAlignment.Center
		msg.TextTransparency = 1
		msg.ZIndex = 602
		msg.Text = "Wait, new gui."
		msg.Parent = veil
		TweenService:Create(veil, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { BackgroundTransparency = 0.5 }):Play()
		TweenService:Create(grain, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { ImageTransparency = 0.88 }):Play()
		TweenService:Create(spin, TweenInfo.new(0.3), { ImageTransparency = 0 }):Play()
		TweenService:Create(msg, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
		local spinTw = nil
		pcall(function()
			spinTw = TweenService:Create(spin, TweenInfo.new(1.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, math.huge), { Rotation = 360 })
			spinTw:Play()
		end)
		task.spawn(function()
			local dots = 0
			while not dead and msg.Parent do
				dots = (dots + 1) % 4
				pcall(function() msg.Text = "Wait, new gui" .. string.rep(".", dots) end)
				task.wait(0.3)
			end
		end)
		task.delay(0.4, function()
			pcall(rebuild)
			task.wait(0.5)
			if dead or myGen ~= win._fontSwapGen then return end
			-- debounce window: rapid picks push the deadline, reveal waits for it
			while os.clock() < (win._fontSwapDeadline or 0) do task.wait(0.1) end
			if dead or myGen ~= win._fontSwapGen then return end
			dead = true
			pcall(function()
				local showPanels = win._main and win._main.Visible
				for _, s in ipairs(win._swapHidden or {}) do
					if s.inst and s.inst.Parent and (s.wm or showPanels) then
						s.inst.Visible = true
					end
				end
				win._swapHidden = {}
			end)
			pcall(function() if spinTw then spinTw:Cancel() end end)
			pcall(function()
				TweenService:Create(veil, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), { BackgroundTransparency = 1 }):Play()
				TweenService:Create(grain, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), { ImageTransparency = 1 }):Play()
				TweenService:Create(spin, TweenInfo.new(0.3), { ImageTransparency = 1 }):Play()
				local tw = TweenService:Create(msg, TweenInfo.new(0.3), { TextTransparency = 1 })
				tw:Play()
				tw.Completed:Connect(function() pcall(function() veil:Destroy() end) end)
			end)
			if win._fontSwap == veil then win._fontSwap = nil end
		end)
	end
	function win:SetThemeFont(name)
		-- mono stays reserved for metric values; a mono UI font made every label
		-- (watermark, keybinds, tabs) read like terminal output.
		if name == "Code" or name == "RobotoMono" then return false end
		if name == nil or name == "Default" then
			win._theme.fontName, win._theme.body, win._theme.head = nil, nil, nil
		else
			local b = resolveFont(name)
			if not b then return false end
			local h = resolveFont(THEME_HEADS[name] or name) or b
			win._theme.fontName, win._theme.body, win._theme.head = tostring(name), b, h
		end
		win._dirty = true
		win:FontSwapFX(function()
			pcall(function() win._doApplyTheme(gui) end)
		end)
		return true
	end
	function win:SetTextColor(c)
		if typeof(c) ~= "Color3" then return end
		win._theme.text = c
		win._dirty = true
		win:ApplyTheme(gui)
	end
	function win:SetSubColor(c)
		if typeof(c) ~= "Color3" then return end
		win._theme.sub = c
		win._dirty = true
		win:ApplyTheme(gui)
	end
	function win:ResetTheme()
		local th = win._theme
		th.fontName, th.body, th.head, th.prevBody, th.prevHead = nil, nil, nil, nil, nil
		th.accent, th.accentTouched, th.text, th.sub = nil, false, nil, nil
		win._accent = win._accentDefault
		for _, fn in ipairs(win._themeListeners) do pcall(fn, win._accent) end
		win._accentChanged:Fire(win._accent)
		win._dirty = true
		win:ApplyTheme(gui) -- restore pass via orig cache
		if win._refreshThemeControls then pcall(win._refreshThemeControls) end
	end
	function win:ApplyThemeData(v)
		if type(v) ~= "table" then return end
		if v.font ~= nil then win:SetThemeFont(v.font) end
		if v.accent ~= nil then
			local c = hexToRgb(v.accent)
			if c then win:SetAccent(c) end
		end
		if v.text ~= nil then
			local c = hexToRgb(v.text)
			if c then win:SetTextColor(c) end
		end
		if v.sub ~= nil then
			local c = hexToRgb(v.sub)
			if c then win:SetSubColor(c) end
		end
		if v.wmorder ~= nil then
			local ord = {}
			for k in string.gmatch(tostring(v.wmorder), "([^,]+)") do
				if k ~= "" then table.insert(ord, k) end
			end
			if #ord > 0 then win._wmOrder = ord end
			if win._watermark then win._watermark:Rebuild() end
		end
		if win._refreshThemeControls then pcall(win._refreshThemeControls) end
	end
	-- ThemeManager state registry: every Normal/Hover/Active write goes through
	-- win:_tc(role, fallback) so themed colors can never be permanently overwritten.
	function win:_tc(role, fallback)
		local th = self._theme
		if role == "text" then
			return th.text or fallback or TXT_MAIN
		elseif role == "sub" then
			return th.sub or fallback or TXT_DIM
		elseif role == "icon" then
			if th.accentTouched and th.accent then return th.accent end
			return fallback or ICON_MAIN
		elseif role == "accent" then
			return self._accent
		end
		return fallback
	end
	function win:_tf(which, fallback)
		local th = self._theme
		if which == "head" then
			return th.head or fallback or Enum.Font.GothamBold
		end
		return th.body or fallback or Enum.Font.Gotham
	end
	-- Explicit role pinning: ThemeManager:Register(element, "text"|"sub"|"icon").
	-- Paints instantly with the active theme (nil tiers skip) and records orig/role,
	-- so luminance guessing stays a pure fallback for unregistered elements.
	function win:ThemeRegister(inst, role)
		if typeof(inst) ~= "Instance" then return false end
		local th = self._theme
		if role == "text" or role == "sub" then
			local okC, cur = pcall(function() return inst.TextColor3 end)
			if not okC then return false end
			local e = themeOrig[inst] or {}
			if e.TextColor3 == nil then e.TextColor3 = cur end
			e._tier = role
			themeOrig[inst] = e
			local tgt = (role == "text") and th.text or th.sub
			if tgt and cur ~= tgt then
				TweenService:Create(inst, THEME_TWEEN, { TextColor3 = tgt }):Play()
			end
		elseif role == "icon" then
			local okC, cur = pcall(function() return inst.ImageColor3 end)
			if not okC then return false end
			local e = themeOrig[inst] or {}
			if e.ImageColor3 == nil then e.ImageColor3 = cur end
			e._tier = "icon"
			themeOrig[inst] = e
			if th.accentTouched and th.accent and cur ~= th.accent then
				TweenService:Create(inst, THEME_TWEEN, { ImageColor3 = th.accent }):Play()
			end
		else
			return false
		end
		return true
	end

	win._glassParts = {}
	win._acrylicOn = opts.Acrylic ~= false
	win._tracker = nil
	function win._glass(inst, acrylicTr)
		table.insert(win._glassParts, { inst = inst, base = inst.BackgroundTransparency, acrylic = acrylicTr })
		if win._acrylicOn then
			pcall(function() inst.BackgroundTransparency = acrylicTr end)
		end
	end
	function win:SetAcrylic(on)
		win._acrylicOn = not not on
		for _, p in ipairs(win._glassParts) do
			if p.inst.Parent then
				TweenService:Create(p.inst, TweenInfo.new(0.25), {BackgroundTransparency = win._acrylicOn and p.acrylic or p.base}):Play()
			end
		end
		if win._acrylicOn then
			Acrylic.ensureDoF()
		else
			Acrylic.destroyDoF()
		end
		if win._acrylicVeil then
			win._acrylicVeil.Visible = win._acrylicOn
		end
		win._syncGlass()
	end
	function win._destroyAcrylic()
		if win._tracker then
			pcall(function() win._tracker.destroy() end)
			win._tracker = nil
		end
		for fr, e in pairs(win._glassTrackers or {}) do
			pcall(function() e.tr.destroy() end)
			win._glassTrackers[fr] = nil
		end
		Acrylic.destroyDoF()
	end
	function win._addGlassSurface(fr)
		if not win._glassTrackers then win._glassTrackers = {} end
		if win._glassTrackers[fr] then return win._glassTrackers[fr] end
		local tr = Acrylic.track(fr, 0.0015, { inset = false, name = "Surface" })
		local entry = { tr = tr, fr = fr }
		local function sync()
			tr.setVisible(win._acrylicOn and fr.Visible and fr.Parent ~= nil)
		end
		entry.sync = sync
		win._glassTrackers[fr] = entry
		fr:GetPropertyChangedSignal("Visible"):Connect(sync)
		fr.Destroying:Connect(function()
			pcall(function() tr.destroy() end)
			win._glassTrackers[fr] = nil
		end)
		sync()
		return entry
	end
	function win._syncGlass()
		if win._tracker then
			win._tracker.setVisible(win._acrylicOn and win._visible and win._main.Visible)
		end
		for _, e in pairs(win._glassTrackers or {}) do
			pcall(e.sync)
		end
	end

	local notifyLayer = Instance.new("Frame")
	notifyLayer.Name = "NotifyLayer"
	notifyLayer.AnchorPoint = Vector2.new(1, 1)
	notifyLayer.Position = UDim2.new(1, -16, 1, -16)
	notifyLayer.Size = UDim2.new(0, 300, 1, -32)
	notifyLayer.BackgroundTransparency = 1
	notifyLayer.Parent = gui
	local nlay = Instance.new("UIListLayout")
	nlay.FillDirection = Enum.FillDirection.Vertical
	nlay.VerticalAlignment = Enum.VerticalAlignment.Bottom
	nlay.SortOrder = Enum.SortOrder.LayoutOrder
	nlay.Padding = UDim.new(0, 8)
	nlay.Parent = notifyLayer
	win._notifyLayer = notifyLayer
	win._notifyQueue = {}
	win._notifyLive = 0
	win._notifyMax = tonumber(opts.NotifyLimit) or 4
	win._notifySeq = 0

	-- tooltips: one bubble shared by every control, attached on demand
	local tipLayer = Instance.new("Frame")
	tipLayer.Name = "TipLayer"
	tipLayer.Size = UDim2.new(1, 0, 1, 0)
	tipLayer.BackgroundTransparency = 1
	tipLayer.ZIndex = 60
	tipLayer.Parent = gui
	local tip = Instance.new("Frame")
	tip.Name = "Tooltip"
	tip.AutomaticSize = Enum.AutomaticSize.XY
	tip.BackgroundColor3 = Color3.fromRGB(14, 14, 17)
	tip.BorderSizePixel = 0
	tip.Visible = false
	tip.ZIndex = 61
	tip.Parent = tipLayer
	corner(tip, 6)
	stroke(tip, Color3.fromRGB(48, 48, 58), 0, 1)
	local tipPad = Instance.new("UIPadding")
	tipPad.PaddingTop = UDim.new(0, 6)
	tipPad.PaddingBottom = UDim.new(0, 6)
	tipPad.PaddingLeft = UDim.new(0, 9)
	tipPad.PaddingRight = UDim.new(0, 9)
	tipPad.Parent = tip
	local tipTxt = Instance.new("TextLabel")
	tipTxt.Name = "Text"
	tipTxt.Size = UDim2.new(0, 0, 0, 0)
	tipTxt.AutomaticSize = Enum.AutomaticSize.XY
	tipTxt.BackgroundTransparency = 1
	tipTxt.Font = Enum.Font.Gotham
	tipTxt.TextSize = 12
	tipTxt.TextWrapped = true
	tipTxt.TextColor3 = Color3.fromRGB(228, 228, 236)
	tipTxt.TextXAlignment = Enum.TextXAlignment.Left
	tipTxt.TextYAlignment = Enum.TextYAlignment.Top
	tipTxt.Text = ""
	tipTxt.ZIndex = 62
	tipTxt.Parent = tip
	local tipLimit = Instance.new("UISizeConstraint")
	tipLimit.MaxSize = Vector2.new(230, 180)
	tipLimit.Parent = tipTxt

	function win:_attachTip(target, text)
		if not text or text == "" then return end
		local token = 0
		local function hide()
			token = token + 1
			tip.Visible = false
		end
		local function place()
			local base = tipLayer.AbsolutePosition
			local tp = target.AbsolutePosition - base
			local ts = target.AbsoluteSize
			local tw, th = tip.AbsoluteSize.X, tip.AbsoluteSize.Y
			local vw = tipLayer.AbsoluteSize.X
			local x = tp.X + ts.X * 0.5 - tw * 0.5
			x = math.clamp(x, 6, math.max(6, vw - tw - 6))
			local y = tp.Y - th - 8
			if y < 6 then y = tp.Y + ts.Y + 8 end
			tip.Position = UDim2.fromOffset(math.floor(x), math.floor(y))
		end
		local function show()
			token = token + 1
			local mine = token
			tipTxt.Text = tostring(text)
			tip.Visible = true
			task.spawn(function()
				RunService.Heartbeat:Wait()
				if mine == token and tip.Visible then place() end
			end)
		end
		local hoverToken = 0
		target.MouseEnter:Connect(function()
			hoverToken = hoverToken + 1
			local mine = hoverToken
			task.delay(0.35, function()
				if mine == hoverToken and target.Parent then show() end
			end)
		end)
		target.MouseLeave:Connect(function()
			hoverToken = hoverToken + 1
			hide()
		end)
		local pressToken = 0
		target.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.Touch then return end
			pressToken = pressToken + 1
			local mine = pressToken
			task.delay(0.45, function()
				if mine == pressToken and target.Parent then show() end
			end)
		end)
		target.InputEnded:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.Touch then return end
			pressToken = pressToken + 1
			hide()
		end)
	end

	local NOTIFY_ICONS = { info = "bell", success = "check", warn = "alert-triangle", error = "x" }
	local buildNotify

	local function pumpNotify()
		while win._notifyLive < win._notifyMax and #win._notifyQueue > 0 do
			local job = table.remove(win._notifyQueue, 1)
			if not job.cancel then
				win._notifyLive = win._notifyLive + 1
				buildNotify(job)
			end
		end
	end

	buildNotify = function(job)
		win._notifySeq = win._notifySeq + 1
		local kind = job.kind or "info"
		local card = Instance.new("TextButton")
		card.Name = "Notify"
		card.Size = UDim2.new(1, 0, 0, 0)
		card.AutomaticSize = Enum.AutomaticSize.Y
		card.BackgroundColor3 = BG_CARD
		card.BackgroundTransparency = 1
		card.AutoButtonColor = false
		card.Text = ""
		card.LayoutOrder = win._notifySeq
		card.Parent = notifyLayer
		corner(card, 10)
		stroke(card, LINE, 0, 1)
		win._glass(card, 0.3)

		local rail = Instance.new("Frame")
		rail.Size = UDim2.new(0, 2, 1, -20)
		rail.Position = UDim2.new(0, 7, 0, 10)
		rail.BackgroundColor3 = win._accent
		rail.BorderSizePixel = 0
		rail.Parent = card
		corner(rail, 1)
		win._reg(function(c) rail.BackgroundColor3 = c end)

		local icon = makeIcon(card, NOTIFY_ICONS[kind] or "bell", 14, ICON_DIM, UDim2.new(0, 16, 0, 11))

		local content = Instance.new("Frame")
		content.Name = "Content"
		content.Size = UDim2.new(1, -40, 0, 0)
		content.Position = UDim2.new(0, 38, 0, 0)
		content.AutomaticSize = Enum.AutomaticSize.Y
		content.BackgroundTransparency = 1
		content.Parent = card
		local cpad = Instance.new("UIPadding")
		cpad.PaddingTop = UDim.new(0, 10)
		cpad.PaddingBottom = UDim.new(0, 11)
		cpad.PaddingRight = UDim.new(0, 12)
		cpad.Parent = content
		local clay = Instance.new("UIListLayout")
		clay.Padding = UDim.new(0, 3)
		clay.SortOrder = Enum.SortOrder.LayoutOrder
		clay.Parent = content

		local t = Instance.new("TextLabel")
		t.Size = UDim2.new(1, 0, 0, 17)
		t.BackgroundTransparency = 1
		t.Font = Enum.Font.GothamBold
		t.TextSize = 13
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.TextTruncate = Enum.TextTruncate.AtEnd
		t.TextColor3 = TXT_MAIN
		t.Text = tostring(job.title)
		t.Parent = content
		win:ThemeRegister(t, "text")

		local d = Instance.new("TextLabel")
		d.Size = UDim2.new(1, 0, 0, 0)
		d.AutomaticSize = Enum.AutomaticSize.Y
		d.BackgroundTransparency = 1
		d.Font = Enum.Font.Gotham
		d.TextSize = 12
		d.TextWrapped = true
		d.TextXAlignment = Enum.TextXAlignment.Left
		d.TextYAlignment = Enum.TextYAlignment.Top
		d.TextColor3 = TXT_DIM
		d.Text = tostring(job.text)
		d.Parent = content
		win:ThemeRegister(d, "sub")

		local life = Instance.new("Frame")
		life.Name = "Life"
		life.AnchorPoint = Vector2.new(0, 1)
		life.Position = UDim2.new(0, 10, 1, -4)
		life.Size = UDim2.new(1, -20, 0, 1)
		life.BackgroundColor3 = win._accent
		life.BackgroundTransparency = 0.55
		life.BorderSizePixel = 0
		life.Parent = card
		win._reg(function(c) life.BackgroundColor3 = c end)

		local closed = false
		local function dismiss()
			if closed then return end
			closed = true
			if life.Parent then life:Destroy() end
			TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 1,
			}):Play()
			TweenService:Create(t, TweenInfo.new(0.16), {TextTransparency = 1}):Play()
			TweenService:Create(d, TweenInfo.new(0.16), {TextTransparency = 1}):Play()
			pcall(function()
				TweenService:Create(icon, TweenInfo.new(0.16), {ImageTransparency = 1}):Play()
			end)
			task.delay(0.22, function()
				if card.Parent then card:Destroy() end
				win._notifyLive = math.max(0, win._notifyLive - 1)
				pumpNotify()
			end)
		end
		job.close = dismiss
		card.MouseButton1Click:Connect(dismiss)

		TweenService:Create(card, TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0,
		}):Play()
		if job.dur and job.dur > 0 then
			TweenService:Create(life, TweenInfo.new(job.dur, Enum.EasingStyle.Linear), {
				Size = UDim2.new(0, 0, 0, 1),
			}):Play()
			task.delay(job.dur, dismiss)
		end
		if job.onClose then job.onClose(dismiss) end
	end

	function win:Notify(ntitle, ntext, ndur, kind)
		local job
		if type(ntitle) == "table" then
			local o = ntitle
			job = {
				title = o.Title or o[1] or "",
				text = o.Text or o[2] or "",
				dur = tonumber(o.Duration or o[3]) or 3.5,
				kind = o.Kind or o[4] or "info",
			}
		else
			job = {
				title = ntitle or "",
				text = ntext or "",
				dur = tonumber(ndur) or 3.5,
				kind = kind or "info",
			}
		end
		local handle = {}
		function handle:Close()
			if job.close then
				job.close()
			else
				job.cancel = true
			end
		end
		table.insert(win._notifyQueue, job)
		pumpNotify()
		return handle
	end

	-- splash
	local splash = Instance.new("Frame")
	splash.Size = UDim2.new(0, 280, 0, 130)
	splash.AnchorPoint = Vector2.new(0.5, 0.5)
	splash.Position = UDim2.new(0.5, 0, 0.5, 0)
	splash.BackgroundColor3 = BG_CARD
	splash.BorderSizePixel = 0
	splash.Parent = gui
	corner(splash, 14)
	stroke(splash, LINE, 0, 1)
	local logo = Instance.new("TextLabel")
	logo.Size = UDim2.new(1, 0, 0, 46)
	logo.Position = UDim2.new(0, 0, 0, 16)
	logo.BackgroundTransparency = 1
	logo.Font = Enum.Font.GothamBlack
	logo.TextSize = 30
	logo.TextColor3 = TXT_MAIN
	logo.Text = "ATHERIUM"
	logo.Parent = splash
	local lsub = Instance.new("TextLabel")
	lsub.Size = UDim2.new(1, 0, 0, 20)
	lsub.Position = UDim2.new(0, 0, 0, 62)
	lsub.BackgroundTransparency = 1
	lsub.Font = Enum.Font.Gotham
	lsub.TextSize = 12
	lsub.TextColor3 = TXT_DIM
	lsub.Text = "loading interface"
	lsub.Parent = splash
	local loadbar = Instance.new("Frame")
	loadbar.Size = UDim2.new(0, 0, 0, 2)
	loadbar.Position = UDim2.new(0, 20, 1, -18)
	loadbar.BackgroundColor3 = accent
	loadbar.BorderSizePixel = 0
	loadbar.Parent = splash
	corner(loadbar, 1)
	win._reg(function(c) loadbar.BackgroundColor3 = c end)
	TweenService:Create(loadbar, TweenInfo.new(0.9, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(1, -40, 0, 2)}):Play()

	-- main
	local main = Instance.new("Frame")
	main.Name = "Main"
	main.Size = UDim2.new(0, WIN_W, 0, WIN_H)
	main.AnchorPoint = Vector2.new(0.5, 0.5)
	main.Position = UDim2.new(0.5, 0, 0.5, 0)
	main.BackgroundColor3 = BG_MAIN
	main.BackgroundTransparency = 0.04
	main.BorderSizePixel = 0
	main.Visible = false
	main.Parent = gui
	corner(main, 14)
	stroke(main, Color3.fromRGB(255, 255, 255), 0.88, 1)
	win._main = main

	local sizeLock = Instance.new("UISizeConstraint")
	sizeLock.MinSize = Vector2.new(500, 540)
	sizeLock.MaxSize = Vector2.new(860, 800)
	sizeLock.Parent = main

	local grip = Instance.new("TextButton")
	grip.Name = "ResizeGrip"
	grip.Size = UDim2.new(0, 26, 0, 26)
	grip.AnchorPoint = Vector2.new(1, 1)
	grip.Position = UDim2.new(1, -6, 1, -6)
	grip.BackgroundTransparency = 1
	grip.Text = ""
	grip.AutoButtonColor = false
	grip.Parent = main
	makeIcon(grip, "move-diagonal-2", 14, ICON_FAINT, UDim2.new(0.5, -7, 0.5, -7))
	grip.MouseEnter:Connect(function()
		local ic = grip:FindFirstChildOfClass("ImageLabel")
		if ic then TweenService:Create(ic, TweenInfo.new(0.15), {ImageColor3 = ICON_MAIN}):Play() end
	end)
	grip.MouseLeave:Connect(function()
		local ic = grip:FindFirstChildOfClass("ImageLabel")
		if ic then TweenService:Create(ic, TweenInfo.new(0.2), {ImageColor3 = ICON_FAINT}):Play() end
	end)
	do
		local resizing, rStart, sStart, pStart = false, nil, nil, nil
		grip.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				resizing = true
				rStart = input.Position
				sStart = main.Size
				pStart = main.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then resizing = false end
				end)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local d = input.Position - rStart
				local nx = math.clamp(sStart.X.Offset + d.X, 500, 860)
				local ny = math.clamp(sStart.Y.Offset + d.Y, 540, 800)
				main.Size = UDim2.new(0, nx, 0, ny)
				main.Position = UDim2.new(0.5, pStart.X.Offset + (nx - sStart.X.Offset) / 2, 0.5, pStart.Y.Offset + (ny - sStart.Y.Offset) / 2)
				win._size = main.Size
			end
		end)
	end

	local vig = Instance.new("UIGradient")
	vig.Rotation = 90
	vig.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 22, 28)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 5, 7)),
	})
	vig.Parent = main

	-- acrylic frost + shadow + glass tracking on main window
	local veil = Instance.new("Frame")
	veil.Name = "AcrylicVeil"
	veil.Size = UDim2.new(1, 0, 1, 0)
	veil.BackgroundColor3 = Color3.fromRGB(5, 5, 7)
	veil.BackgroundTransparency = 0.62
	veil.BorderSizePixel = 0
	veil.Parent = main
	corner(veil, 14)
	win._acrylicVeil = veil
	local sheen = Instance.new("Frame")
	sheen.Name = "AcrylicSheen"
	sheen.Size = UDim2.new(1, 0, 1, 0)
	sheen.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	sheen.BackgroundTransparency = 0.94
	sheen.BorderSizePixel = 0
	sheen.Parent = main
	corner(sheen, 14)
	local sheenGrad = Instance.new("UIGradient")
	sheenGrad.Rotation = 90
	sheenGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.88),
		NumberSequenceKeypoint.new(0.35, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	sheenGrad.Parent = sheen
	local noise = Instance.new("ImageLabel")
	noise.Name = "AcrylicNoise"
	noise.Size = UDim2.new(1, 0, 1, 0)
	noise.BackgroundTransparency = 1
	noise.Image = "rbxassetid://9968344227"
	noise.ImageTransparency = 0.94
	noise.ScaleType = Enum.ScaleType.Tile
	noise.TileSize = UDim2.new(0, 128, 0, 128)
	noise.Parent = main
	corner(noise, 14)
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "DropShadow"
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://8992230677"
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(99, 99, 99, 99)
	shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	shadow.ImageTransparency = 0.6
	shadow.ZIndex = 0
	shadow.Visible = false
	shadow.Parent = gui
	local function syncShadow()
		shadow.Size = main.Size + UDim2.new(0, 30, 0, 30)
		shadow.Position = UDim2.new(main.Position.X.Scale, main.Position.X.Offset, main.Position.Y.Scale, main.Position.Y.Offset + 8)
		shadow.Visible = main.Visible
	end
	main:GetPropertyChangedSignal("Size"):Connect(syncShadow)
	main:GetPropertyChangedSignal("Position"):Connect(syncShadow)
	main:GetPropertyChangedSignal("Visible"):Connect(syncShadow)
	win._glass(main, 0.24)
	if win._acrylicOn then
		Acrylic.ensureDoF()
	end
	win._tracker = Acrylic.track(main)
	win._syncGlass()
	syncShadow()
	hairline(main, 1)

	-- header
	local top = Instance.new("Frame")
	top.Size = UDim2.new(1, 0, 0, 54)
	top.BackgroundColor3 = BG_TOP
	top.BackgroundTransparency = 0.1
	top.BorderSizePixel = 0
	top.Parent = main
	corner(top, 14)
	local topFix = Instance.new("Frame")
	topFix.Size = UDim2.new(1, 0, 0, 14)
	topFix.Position = UDim2.new(0, 0, 1, -14)
	topFix.BackgroundColor3 = BG_TOP
	topFix.BackgroundTransparency = top.BackgroundTransparency
	topFix.BorderSizePixel = 0
	topFix.Parent = top
	top:GetPropertyChangedSignal("BackgroundTransparency"):Connect(function()
		if topFix.Parent then
			topFix.BackgroundTransparency = top.BackgroundTransparency
		end
	end)
	makeDrag(main, top)
	win._glass(top, 0.1)

	local titleL = Instance.new("TextLabel")
	titleL.Size = UDim2.new(0, 220, 0, 24)
	titleL.Position = UDim2.new(0, 18, 0, 8)
	titleL.BackgroundTransparency = 1
	titleL.Font = Enum.Font.GothamBold
	titleL.TextSize = 16
	titleL.TextXAlignment = Enum.TextXAlignment.Left
	titleL.TextColor3 = Color3.fromRGB(235, 235, 240)
	titleL.TextTruncate = Enum.TextTruncate.AtEnd
	titleL.Text = title
	titleL.Parent = top
	local titleW = 80
	pcall(function()
		titleW = math.ceil(game:GetService("TextService"):GetTextSize(title, 16, Enum.Font.GothamBold, Vector2.new(500, 24)).X)
	end)
	local pillX = 18 + titleW + 10
	local pill = Instance.new("Frame")
	pill.Name = "CfgPill"
	pill.Size = UDim2.new(0, 110, 0, 30)
	pill.Position = UDim2.new(0, pillX, 0, 5)
	pill.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
	pill.BorderSizePixel = 0
	pill.Parent = top
	corner(pill, 6)
	stroke(pill, Color3.fromRGB(39, 39, 42), 0, 1)
	local saveB = Instance.new("TextButton")
	saveB.Name = "SaveCfg"
	saveB.Size = UDim2.new(0, 30, 1, 0)
	saveB.Position = UDim2.new(0, 0, 0, 0)
	saveB.BackgroundTransparency = 1
	saveB.Text = ""
	saveB.AutoButtonColor = false
	saveB.Parent = pill
	makeIcon(saveB, "save", 16, ICON_DIM, UDim2.new(0.5, -8, 0.5, -8))
	local div = Instance.new("Frame")
	div.Size = UDim2.new(0, 1, 0, 18)
	div.Position = UDim2.new(0, 30, 0.5, -9)
	div.BackgroundColor3 = Color3.fromRGB(39, 39, 42)
	div.BorderSizePixel = 0
	div.Parent = pill
	saveB.MouseEnter:Connect(function()
		local ic = saveB:FindFirstChildOfClass("ImageLabel")
		if ic then TweenService:Create(ic, TweenInfo.new(0.15), {ImageColor3 = ICON_MAIN}):Play() end
	end)
	saveB.MouseLeave:Connect(function()
		local ic = saveB:FindFirstChildOfClass("ImageLabel")
		if ic then TweenService:Create(ic, TweenInfo.new(0.2), {ImageColor3 = ICON_DIM}):Play() end
	end)
	local lastSaveClick = 0
	saveB.MouseButton1Click:Connect(function()
		clickSound(gui, function() return win._sounds end)
		local now = os.clock()
		if now - lastSaveClick < 0.35 then
			lastSaveClick = 0
			local target = win._activeCfg or "default"
			if win:LoadConfig(target) then
				win:Notify("Config", "Loaded '" .. tostring(target) .. "'")
			else
				win:Notify("Config", "Load failed")
			end
			print("[ATHERIUM] quick load -> " .. tostring(target))
		else
			lastSaveClick = now
			task.delay(0.35, function()
				if lastSaveClick ~= 0 and saveB.Parent then
					lastSaveClick = 0
					if win:SaveConfig(win._activeCfg) then
						local ic = saveB:FindFirstChildOfClass("ImageLabel")
						if ic then
							TweenService:Create(ic, TweenInfo.new(0.15), {ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play()
							task.delay(1, function()
								if ic.Parent then
									TweenService:Create(ic, TweenInfo.new(0.3), {ImageColor3 = TXT_DIM}):Play()
								end
							end)
						end
					end
				end
			end)
		end
	end)
	local cfgTrig = Instance.new("TextButton")
	cfgTrig.Name = "CfgQuick"
	cfgTrig.Size = UDim2.new(1, -31, 1, 0)
	cfgTrig.Position = UDim2.new(0, 31, 0, 0)
	cfgTrig.BackgroundTransparency = 1
	cfgTrig.Text = ""
	cfgTrig.AutoButtonColor = false
	cfgTrig.Parent = pill
	local cfgCur = Instance.new("TextLabel")
	cfgCur.Size = UDim2.new(1, -26, 1, 0)
	cfgCur.Position = UDim2.new(0, 8, 0, 0)
	cfgCur.BackgroundTransparency = 1
	cfgCur.Font = Enum.Font.Gotham
	cfgCur.TextSize = 12
	cfgCur.TextXAlignment = Enum.TextXAlignment.Left
	cfgCur.TextTruncate = Enum.TextTruncate.AtEnd
	cfgCur.TextColor3 = TXT_MAIN
	cfgCur.Text = tostring(win._activeCfg or "default")
	cfgCur.Parent = cfgTrig
	local cfgChev = makeIcon(cfgTrig, "chevron-down", 12, ICON_FAINT, UDim2.new(1, -18, 0.5, -6))
	local cfgListF = nil
	local function closeCfgList()
		if not cfgListF then return end
		local f = cfgListF
		cfgListF = nil
		TweenService:Create(cfgChev, TweenInfo.new(0.15), {Rotation = 0}):Play()
		local tw = TweenService:Create(f, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Size = UDim2.new(0, 140, 0, 0)})
		tw:Play()
		tw.Completed:Connect(function() pcall(function() f:Destroy() end) end)
	end
	local function openCfgList()
		if cfgListF then closeCfgList() return end
		local names = win:ListConfigs()
		if #names == 0 then names = { tostring(win._activeCfg or "default") } end
		local listW = 140
		local fullH = #names * 30 + 8
		cfgListF = Instance.new("Frame")
		cfgListF.Size = UDim2.new(0, listW, 0, 0)
		do
			local px, py = 0, 0
			pcall(function()
				local mp = main.AbsolutePosition
				local ms = main.AbsoluteSize
				local tp = pill.AbsolutePosition
				local ts = pill.AbsoluteSize
				px = tp.X - mp.X
				py = tp.Y - mp.Y + ts.Y + 4
				px = math.clamp(px, 8, math.max(8, ms.X - listW - 8))
			end)
			cfgListF.Position = UDim2.new(0, px, 0, py)
		end
		cfgListF.BackgroundColor3 = Color3.fromRGB(13, 13, 16)
		cfgListF.BorderSizePixel = 0
		cfgListF.ClipsDescendants = true
		cfgListF.ZIndex = 50
		cfgListF.Parent = main
		corner(cfgListF, 8)
		stroke(cfgListF, LINE, 0, 1)
		local cpad = Instance.new("UIPadding")
		cpad.PaddingTop = UDim.new(0, 4)
		cpad.PaddingBottom = UDim.new(0, 4)
		cpad.PaddingLeft = UDim.new(0, 4)
		cpad.PaddingRight = UDim.new(0, 4)
		cpad.Parent = cfgListF
		local clay = Instance.new("UIListLayout")
		clay.Padding = UDim.new(0, 2)
		clay.SortOrder = Enum.SortOrder.LayoutOrder
		clay.Parent = cfgListF
		for i, n in ipairs(names) do
			local b = Instance.new("TextButton")
			b.LayoutOrder = i
			b.Size = UDim2.new(1, 0, 0, 28)
			b.BackgroundColor3 = BG_HOVER
			b.BackgroundTransparency = 1
			b.Font = Enum.Font.Gotham
			b.TextSize = 12
			b.TextColor3 = TXT_DIM
			b.TextXAlignment = Enum.TextXAlignment.Left
			b.TextTruncate = Enum.TextTruncate.AtEnd
			b.Text = tostring(n)
			b.AutoButtonColor = false
			b.ZIndex = 51
			b.Parent = cfgListF
			corner(b, 6)
			local bpad = Instance.new("UIPadding")
			bpad.PaddingLeft = UDim.new(0, 10)
			bpad.Parent = b
			local sel = (tostring(n) == tostring(win._activeCfg or "default"))
			b.BackgroundTransparency = sel and 0 or 1
			b.TextColor3 = sel and TXT_MAIN or TXT_DIM
			local chk = makeIcon(b, "check", 12, TXT_MAIN, UDim2.new(1, -24, 0.5, -6))
			chk.ZIndex = 51
			chk.Visible = sel
			b.MouseEnter:Connect(function()
				TweenService:Create(b, TweenInfo.new(0.12), {BackgroundTransparency = 0}):Play()
			end)
			b.MouseLeave:Connect(function()
				local still = (tostring(n) == tostring(win._activeCfg or "default"))
				TweenService:Create(b, TweenInfo.new(0.15), {BackgroundTransparency = still and 0 or 1}):Play()
			end)
			b.MouseButton1Click:Connect(function()
				win._activeCfg = tostring(n)
				cfgCur.Text = tostring(n)
				closeCfgList()
				clickSound(gui, function() return win._sounds end)
				print("[ATHERIUM] active config -> " .. tostring(n))
			end)
		end
		TweenService:Create(cfgChev, TweenInfo.new(0.2), {Rotation = 180}):Play()
		TweenService:Create(cfgListF, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, listW, 0, fullH)}):Play()
		win:ApplyTheme(cfgListF)
	end
	cfgTrig.MouseButton1Click:Connect(function()
		clickSound(gui, function() return win._sounds end)
		cfgCur.Text = tostring(win._activeCfg or "default")
		openCfgList()
	end)
	UserInputService.InputBegan:Connect(function(input)
		if not cfgListF then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local pp = cfgListF
		if not pp or not pp.Parent then cfgListF = nil return end
		local pos = pp.AbsolutePosition
		local sz = pp.AbsoluteSize
		local mp = input.Position
		local inside = mp.X >= pos.X and mp.X <= pos.X + sz.X and mp.Y >= pos.Y and mp.Y <= pos.Y + sz.Y
		local sp = pill.AbsolutePosition
		local ss = pill.AbsoluteSize
		local onTrig = mp.X >= sp.X and mp.X <= sp.X + ss.X and mp.Y >= sp.Y and mp.Y <= sp.Y + ss.Y
		if not inside and not onTrig then closeCfgList() end
	end)
	local subL = Instance.new("TextLabel")
	subL.Size = UDim2.new(0, 220, 0, 14)
	subL.Position = UDim2.new(0, 18, 0, 32)
	subL.BackgroundTransparency = 1
	subL.Font = Enum.Font.Gotham
	subL.TextSize = 11
	subL.TextXAlignment = Enum.TextXAlignment.Left
	subL.TextColor3 = TXT_DIM
	subL.Text = subtitle
	subL.Parent = top
	local fpsL = Instance.new("TextLabel")
	fpsL.Size = UDim2.new(0, 120, 0, 16)
	fpsL.AnchorPoint = Vector2.new(1, 0.5)
	fpsL.Position = UDim2.new(1, -92, 0.5, 0)
	fpsL.BackgroundTransparency = 1
	fpsL.Font = Enum.Font.Code
	fpsL.TextSize = 11
	fpsL.TextXAlignment = Enum.TextXAlignment.Right
	fpsL.TextColor3 = TXT_SOFT
	fpsL.Text = "60 fps"
	fpsL.Parent = top
	local frames, lastT = 0, tick()
	RunService.RenderStepped:Connect(function()
		frames += 1
		local now = tick()
		if now - lastT >= 0.5 then
			local fps = math.floor(frames / (now - lastT) + 0.5)
			local ping = "--"
			pcall(function() ping = tostring(math.floor(LocalPlayer:GetNetworkPing() * 1000)) .. "ms" end)
			fpsL.Text = string.format("%d fps %s", fps, ping)
			frames, lastT = 0, now
		end
	end)

	local function topIconBtn(iconName, xOff)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0, 30, 0, 30)
		b.AnchorPoint = Vector2.new(1, 0.5)
		b.Position = UDim2.new(1, xOff, 0.5, 0)
		b.BackgroundColor3 = BG_CARD
		b.Text = ""
		b.AutoButtonColor = false
		b.Parent = top
		corner(b, 8)
		makeIcon(b, iconName, 14, ICON_DIM, UDim2.new(0.5, -7, 0.5, -7))
		return b
	end
	local closeB = topIconBtn("x", -10)
	local minB = topIconBtn("minus", -44)
	minB.MouseButton1Click:Connect(function() win:Toggle() end)
	closeB.MouseButton1Click:Connect(function()
		win:Notify(title, "UI unloaded. Re-run script to show again.")
		pcall(function() win:SaveConfig(win._activeCfg or "default", true) end)
		task.wait(0.4)
		win._destroyAcrylic()
		gui:Destroy()
	end)

	-- LEFT SIDEBAR (search + tabs + profile)
	local SIDE_W = 150
	local strip = Instance.new("Frame")
	strip.Name = "Sidebar"
	strip.Size = UDim2.new(0, SIDE_W, 1, -72)
	strip.Position = UDim2.new(0, 10, 0, 62)
	strip.BackgroundColor3 = BG_TOP
	strip.BorderSizePixel = 0
	strip.Parent = main
	corner(strip, 11)
	stroke(strip, LINE, 0, 1)

	-- compact search inside sidebar
	local searchBox = Instance.new("Frame")
	searchBox.Size = UDim2.new(1, -16, 0, 30)
	searchBox.Position = UDim2.new(0, 8, 0, 8)
	searchBox.BackgroundColor3 = BG_CARD
	searchBox.BorderSizePixel = 0
	searchBox.Parent = strip
	corner(searchBox, 8)
	local searchStroke = stroke(searchBox, LINE, 0, 1)
	local searchIcon = makeIcon(searchBox, "search", 12, ICON_FAINT, UDim2.new(0, 8, 0.5, -6))
	local searchInput = Instance.new("TextBox")
	searchInput.Size = UDim2.new(1, -56, 1, 0)
	searchInput.Position = UDim2.new(0, 26, 0, 0)
	searchInput.BackgroundTransparency = 1
	searchInput.Font = Enum.Font.Gotham
	searchInput.TextSize = 11
	searchInput.TextXAlignment = Enum.TextXAlignment.Left
	searchInput.TextColor3 = TXT_MAIN
	searchInput.PlaceholderColor3 = TXT_DIM
	searchInput.PlaceholderText = "Search..."
	searchInput.Text = ""
	searchInput.ClearTextOnFocus = false
	searchInput.Parent = searchBox
	local searchClear = Instance.new("TextButton")
	searchClear.Size = UDim2.new(0, 22, 0, 22)
	searchClear.AnchorPoint = Vector2.new(1, 0.5)
	searchClear.Position = UDim2.new(1, -4, 0.5, 0)
	searchClear.BackgroundTransparency = 1
	searchClear.Text = ""
	searchClear.Visible = false
	searchClear.Parent = searchBox
	makeIcon(searchClear, "x", 11, ICON_FAINT, UDim2.new(0.5, -5, 0.5, -5))
	win._glass(searchBox, 0.3)
	searchClear.MouseButton1Click:Connect(function()
		searchInput.Text = ""
		searchInput:ReleaseFocus()
	end)
	searchInput.Focused:Connect(function()
		TweenService:Create(searchStroke, TweenInfo.new(0.2), {Transparency = 0.6}):Play()
		TweenService:Create(searchIcon, TweenInfo.new(0.2), {ImageColor3 = ICON_MAIN}):Play()
	end)
	searchInput.FocusLost:Connect(function()
		TweenService:Create(searchStroke, TweenInfo.new(0.25), {Transparency = 0}):Play()
		TweenService:Create(searchIcon, TweenInfo.new(0.25), {ImageColor3 = ICON_FAINT}):Play()
	end)

	-- tabs holder: scrolls once the list is taller than the sidebar, so a hub
	-- with 12 tabs never pushes into the profile card
	local tabsHolder = Instance.new("ScrollingFrame")
	tabsHolder.Name = "TabsHolder"
	tabsHolder.Size = UDim2.new(1, -16, 1, -108)
	tabsHolder.Position = UDim2.new(0, 8, 0, 46)
	tabsHolder.BackgroundTransparency = 1
	tabsHolder.BorderSizePixel = 0
	tabsHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
	tabsHolder.AutomaticCanvasSize = Enum.AutomaticSize.Y
	tabsHolder.ScrollingDirection = Enum.ScrollingDirection.Y
	tabsHolder.ScrollBarThickness = 2
	tabsHolder.ScrollBarImageColor3 = Color3.fromRGB(58, 58, 68)
	tabsHolder.ScrollBarImageTransparency = 0.35
	tabsHolder.ElasticBehavior = Enum.ElasticBehavior.Never
	tabsHolder.Parent = strip
	local stripLay = Instance.new("UIListLayout")
	stripLay.FillDirection = Enum.FillDirection.Vertical
	stripLay.SortOrder = Enum.SortOrder.LayoutOrder
	stripLay.Padding = UDim.new(0, 6)
	stripLay.Parent = tabsHolder
	local stripPad = Instance.new("UIPadding")
	stripPad.PaddingTop = UDim.new(0, 2)
	stripPad.PaddingBottom = UDim.new(0, 6)
	stripPad.PaddingRight = UDim.new(0, 6)
	stripPad.Parent = tabsHolder
	win._tabsHolder = tabsHolder
	win._tabsScroll = function(dy)
		local maxY = math.max(0, tabsHolder.AbsoluteCanvasSize.Y - tabsHolder.AbsoluteSize.Y)
		tabsHolder.CanvasPosition = Vector2.new(0, math.clamp(tabsHolder.CanvasPosition.Y + dy, 0, maxY))
	end
	win._glass(strip, 0.26)

	-- profile pinned to sidebar bottom (clickable, opens profile card)
	local userCard = Instance.new("TextButton")
	userCard.Size = UDim2.new(1, -16, 0, 46)
	userCard.Position = UDim2.new(0, 8, 1, -54)
	userCard.BackgroundColor3 = BG_CARD
	userCard.BorderSizePixel = 0
	userCard.Text = ""
	userCard.AutoButtonColor = false
	userCard.Parent = strip
	corner(userCard, 9)
	stroke(userCard, LINE, 0, 1)
	userCard.MouseEnter:Connect(function()
		TweenService:Create(userCard, TweenInfo.new(0.15), {BackgroundColor3 = BG_HOVER}):Play()
	end)
	userCard.MouseLeave:Connect(function()
		TweenService:Create(userCard, TweenInfo.new(0.2), {BackgroundColor3 = BG_CARD}):Play()
	end)
	local av = Instance.new("TextLabel")
	av.Size = UDim2.new(0, 28, 0, 28)
	av.Position = UDim2.new(0, 8, 0.5, -14)
	av.BackgroundColor3 = TXT_FAINT
	av.Font = Enum.Font.GothamBlack
	av.TextSize = 12
	av.TextColor3 = TXT_MAIN
	av.Text = "V"
	pcall(function() av.Text = string.sub(LocalPlayer.DisplayName, 1, 1):upper() end)
	av.Parent = userCard
	corner(av, 14)
	local avImg = Instance.new("ImageLabel")
	avImg.Name = "Avatar"
	avImg.Size = UDim2.new(0, 28, 0, 28)
	avImg.Position = UDim2.new(0, 8, 0.5, -14)
	avImg.BackgroundTransparency = 1
	avImg.Visible = false
	avImg.Parent = userCard
	corner(avImg, 14)
	task.spawn(function()
		local ok, thumb = pcall(function()
			return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		end)
		if ok and typeof(thumb) == "string" and thumb ~= "" and avImg.Parent then
			avImg.Image = thumb
			avImg.Visible = true
			av.TextTransparency = 1
		end
	end)
	local un = Instance.new("TextLabel")
	un.Size = UDim2.new(1, -48, 0, 15)
	un.Position = UDim2.new(0, 42, 0, 8)
	un.BackgroundTransparency = 1
	un.Font = Enum.Font.GothamBold
	un.TextSize = 11
	un.TextXAlignment = Enum.TextXAlignment.Left
	un.TextColor3 = TXT_MAIN
	un.TextTruncate = Enum.TextTruncate.AtEnd
	un.Text = LocalPlayer.DisplayName
	un.Parent = userCard
	local hint = Instance.new("TextLabel")
	hint.Size = UDim2.new(1, -48, 0, 12)
	hint.Position = UDim2.new(0, 42, 0, 24)
	hint.BackgroundTransparency = 1
	hint.Font = Enum.Font.Gotham
	hint.TextSize = 9
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.TextColor3 = TXT_SOFT
	hint.Text = "RShift - hide"
	hint.Parent = userCard
	win._glass(userCard, 0.3)

	local profPop = nil
	local profConns = {}
	local function hideCard()
		pcall(function()
			TweenService:Create(userCard, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {BackgroundTransparency = 1}):Play()
			local st = userCard:FindFirstChildOfClass("UIStroke")
			if st then TweenService:Create(st, TweenInfo.new(0.18), {Transparency = 1}):Play() end
			TweenService:Create(av, TweenInfo.new(0.18), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
			TweenService:Create(avImg, TweenInfo.new(0.18), {ImageTransparency = 1}):Play()
			TweenService:Create(un, TweenInfo.new(0.18), {TextTransparency = 1}):Play()
			TweenService:Create(hint, TweenInfo.new(0.18), {TextTransparency = 1}):Play()
		end)
		task.delay(0.19, function() userCard.Visible = false end)
	end
	local function showCard()
		userCard.Visible = true
		pcall(function()
			TweenService:Create(userCard, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
			local st = userCard:FindFirstChildOfClass("UIStroke")
			if st then TweenService:Create(st, TweenInfo.new(0.22), {Transparency = 0}):Play() end
			TweenService:Create(av, TweenInfo.new(0.22), {BackgroundTransparency = 0, TextTransparency = avImg.Visible and 1 or 0}):Play()
			TweenService:Create(avImg, TweenInfo.new(0.22), {ImageTransparency = 0}):Play()
			TweenService:Create(un, TweenInfo.new(0.22), {TextTransparency = 0}):Play()
			TweenService:Create(hint, TweenInfo.new(0.22), {TextTransparency = 0}):Play()
		end)
	end
	local function closeProfile(animated)
		for _, c in ipairs(profConns) do pcall(function() c:Disconnect() end) end
		profConns = {}
		if profPop then
			local p = profPop
			profPop = nil
			if animated == false then
				pcall(function() p:Destroy() end)
				showCard()
			else
				pcall(function()
					local fx = p.Position.X.Offset
					local fy = p.Position.Y.Offset
					local tw = TweenService:Create(p, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(0, 10, 1, -30), BackgroundTransparency = 1})
					tw:Play()
					tw.Completed:Connect(function()
						pcall(function() p:Destroy() end)
						showCard()
					end)
				end)
			end
		end
	end
	local function openProfile()
		hideCard()
		local popW, popH = 196, 190
		profPop = Instance.new("Frame")
		profPop.Name = "ProfilePopup"
		profPop.Size = UDim2.new(0, popW, 0, popH)
		profPop.AnchorPoint = Vector2.new(0, 1)
		profPop.Position = UDim2.new(0, 10, 1, -80)
		profPop.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
		profPop.BackgroundTransparency = 1
		profPop.BorderSizePixel = 0
		profPop.ZIndex = 50
		profPop.Parent = main
		corner(profPop, 12)
		stroke(profPop, LINE, 0, 1)
		win._glass(profPop, 0.3)
		TweenService:Create(profPop, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0, 10, 1, -10), BackgroundTransparency = 0}):Play()
		local Z = 51
		local function zw(inst, z)
			inst.ZIndex = z or Z
			return inst
		end
		local pt = Instance.new("TextLabel")
		pt.Size = UDim2.new(1, -48, 0, 18)
		pt.Position = UDim2.new(0, 32, 0, 8)
		pt.BackgroundTransparency = 1
		pt.Font = Enum.Font.GothamBold
		pt.TextSize = 13
		pt.TextXAlignment = Enum.TextXAlignment.Left
		pt.TextColor3 = TXT_MAIN
		pt.Text = "Profile"
		zw(pt).Parent = profPop
		makeIcon(profPop, "user", 14, ICON_DIM, UDim2.new(0, 12, 0, 9)).ZIndex = Z
		local xBtn = Instance.new("TextButton")
		xBtn.Size = UDim2.new(0, 24, 0, 24)
		xBtn.AnchorPoint = Vector2.new(1, 0)
		xBtn.Position = UDim2.new(1, -8, 0, 8)
		xBtn.BackgroundTransparency = 1
		xBtn.Text = ""
		zw(xBtn).Parent = profPop
		makeIcon(xBtn, "x", 13, ICON_FAINT, UDim2.new(0.5, -6, 0.5, -6)).ZIndex = Z
		xBtn.MouseButton1Click:Connect(function() closeProfile() end)
		local big = Instance.new("ImageLabel")
		big.Size = UDim2.new(0, 36, 0, 36)
		big.Position = UDim2.new(0, 12, 0, 30)
		big.BackgroundColor3 = BG_TRACK
		big.BorderSizePixel = 0
		zw(big).Parent = profPop
		corner(big, 18)
		if avImg.Visible and avImg.Image ~= "" then
			big.Image = avImg.Image
		else			task.spawn(function()
				local ok, thumb = pcall(function()
					return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
				end)
				if ok and typeof(thumb) == "string" and thumb ~= "" and big.Parent then
					big.Image = thumb
				end
			end)
		end
		local dn = Instance.new("TextLabel")
		dn.Size = UDim2.new(1, -64, 0, 15)
		dn.Position = UDim2.new(0, 52, 0, 33)
		dn.BackgroundTransparency = 1
		dn.Font = Enum.Font.GothamBold
		dn.TextSize = 13
		dn.TextXAlignment = Enum.TextXAlignment.Left
		dn.TextTruncate = Enum.TextTruncate.AtEnd
		dn.TextColor3 = TXT_MAIN
		dn.Text = LocalPlayer.DisplayName
		zw(dn).Parent = profPop
		local at = Instance.new("TextLabel")
		at.Size = UDim2.new(1, -64, 0, 12)
		at.Position = UDim2.new(0, 52, 0, 48)
		at.BackgroundTransparency = 1
		at.Font = Enum.Font.Gotham
		at.TextSize = 11
		at.TextXAlignment = Enum.TextXAlignment.Left
		at.TextTruncate = Enum.TextTruncate.AtEnd
		at.TextColor3 = TXT_DIM
		at.Text = "@" .. LocalPlayer.Name
		zw(at).Parent = profPop
		local function infoRow(y, k, v, icon)
			makeIcon(profPop, icon, 12, ICON_FAINT, UDim2.new(0, 12, 0, y + 2)).ZIndex = Z
			local kl = Instance.new("TextLabel")
			kl.Size = UDim2.new(0, 56, 0, 16)
			kl.Position = UDim2.new(0, 30, 0, y)
			kl.BackgroundTransparency = 1
			kl.Font = Enum.Font.GothamMedium
			kl.TextSize = 11
			kl.TextXAlignment = Enum.TextXAlignment.Left
			kl.TextColor3 = TXT_DIM
			kl.Text = k
			zw(kl).Parent = profPop
			local vl = Instance.new("TextLabel")
			vl.Size = UDim2.new(1, -96, 0, 16)
			vl.Position = UDim2.new(0, 84, 0, y)
			vl.BackgroundTransparency = 1
			vl.Font = Enum.Font.Code
			vl.TextSize = 11
			vl.TextXAlignment = Enum.TextXAlignment.Right
			vl.TextTruncate = Enum.TextTruncate.AtEnd
			vl.TextColor3 = TXT_MAIN
			vl.Text = v
			zw(vl).Parent = profPop
			return vl
		end
		infoRow(72, "UserId", tostring(LocalPlayer.UserId), "hash")
		local srvL = infoRow(88, "Server", "", "server")
		local function refreshSrv()
			if not profPop then return end
			local n = 0
			pcall(function() n = #Players:GetPlayers() end)
			local mx = 0
			pcall(function() mx = Players.MaxPlayers end)
			srvL.Text = tostring(n) .. "/" .. tostring(mx)
		end
		refreshSrv()
		table.insert(profConns, Players.PlayerAdded:Connect(refreshSrv))
		table.insert(profConns, Players.PlayerRemoving:Connect(function()
			task.delay(0.5, refreshSrv)
		end))
		infoRow(104, "Place", tostring(game.PlaceId), "map-pin")
		infoRow(120, "Build", "11.10.26", "hammer")
		local copyB = Instance.new("TextButton")
		copyB.Size = UDim2.new(1, -24, 0, 22)
		copyB.Position = UDim2.new(0, 12, 0, 142)
		copyB.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		copyB.Font = Enum.Font.GothamBold
		copyB.TextSize = 12
		copyB.TextColor3 = Color3.fromRGB(9, 9, 11)
		copyB.Text = "Copy game link"
		copyB.AutoButtonColor = false
		zw(copyB).Parent = profPop
		corner(copyB, 7)
		copyB.MouseEnter:Connect(function()
			TweenService:Create(copyB, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(215, 215, 222)}):Play()
		end)
		copyB.MouseLeave:Connect(function()
			TweenService:Create(copyB, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
		end)
		copyB.MouseButton1Click:Connect(function()
			local link = "https://www.roblox.com/games/" .. tostring(game.PlaceId)
			local ok = false
			pcall(function()
				if setclipboard then setclipboard(link) ok = true end
			end)
			if ok then win:Notify("Profile", "Game link copied") else win:Notify("Profile", link) end
		end)
		local hint2 = Instance.new("TextLabel")
		hint2.Size = UDim2.new(1, -24, 0, 12)
		hint2.Position = UDim2.new(0, 12, 0, 168)
		hint2.BackgroundTransparency = 1
		hint2.Font = Enum.Font.Gotham
		hint2.TextSize = 10
		hint2.TextXAlignment = Enum.TextXAlignment.Left
		hint2.TextColor3 = TXT_FAINT
		hint2.Text = "Atherium v8.8 acrylic"
		zw(hint2).Parent = profPop
		table.insert(profConns, UserInputService.InputBegan:Connect(function(input)
			if not profPop then return end
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
			local pp = profPop
			if not pp or not pp.Parent then return end
			local pos = pp.AbsolutePosition
			local sz = pp.AbsoluteSize
			local mp = input.Position
			local inside = mp.X >= pos.X and mp.X <= pos.X + sz.X and mp.Y >= pos.Y and mp.Y <= pos.Y + sz.Y
			local sp = userCard.AbsolutePosition
			local ss = userCard.AbsoluteSize
			local onCard = mp.X >= sp.X and mp.X <= sp.X + ss.X and mp.Y >= sp.Y and mp.Y <= sp.Y + ss.Y
			if not inside and not onCard then closeProfile() end
		end))
		win:ApplyTheme(profPop)
	end
	userCard.MouseButton1Click:Connect(function()
		clickSound(gui, function() return win._sounds end)
		if profPop then closeProfile() else openProfile() end
	end)

	-- content (right of sidebar, runs to bottom)
	local content = Instance.new("Frame")
	content.Size = UDim2.new(1, -(SIDE_W + 30), 1, -72)
	content.Position = UDim2.new(0, SIDE_W + 20, 0, 62)
	content.BackgroundTransparency = 1
	content.Parent = main
	win._content = content

	-- in-flow dropdown registry (open lists push layout down, never overlap)
	win._dropLists = {}
	win._panels = {}
	win._keybinds = {}
	win._cfg = {}
	win._dirty = false
	win._activeCfg = nil
	if opts.Autosave then
		local interval = math.clamp(tonumber(opts.AutosaveInterval) or 30, 5, 600)
		task.spawn(function()
			while win._gui.Parent do
				task.wait(interval)
				if win._dirty and win._gui.Parent then
					win._dirty = false
					pcall(function() win:SaveConfig(win._activeCfg or "default", true) end)
				end
			end
		end)
	end
	win._keyListBody = nil
	win._keyListRows = {}
	win._keyListEmpty = nil
	win._keyListSeq = 0
	function win._refreshKeyList()
		if not win._gui.Parent then return end
		local body = win._keyListBody
		if not body or not body.Parent then return end
		win._keyListSeq = win._keyListSeq + 1
		local mySeq = win._keyListSeq
		-- 1) desired state in keybind order (no wipe: diff against live rows)
		local desired, desiredMap = {}, {}
		for _, kb in ipairs(win._keybinds) do
			local key = nil
			pcall(function() key = kb.get() end)
			if key then
				local linked = kb.toggle
				local on = false
				if linked ~= nil then
					pcall(function() on = linked:Get() == true end)
					if not on then on = kb.held end -- hold previews even when toggle is off
				else
					on = kb.held
				end
				if on then
					local fname = kb.name
					if linked ~= nil then
						if type(linked) == "table" and type(linked._name) == "string" then
							fname = linked._name
						else
							fname = string.gsub(string.gsub(fname, "%s+[Kk]ey$", ""), "%s+[Bb]ind$", "")
						end
					end
					local d = { name = kb.name, keyName = key.Name, fname = fname, held = kb.held and true or false, tabIcon = kb.tabIcon }
					table.insert(desired, d)
					desiredMap[d.name] = d
				end
			end
		end
		-- 2) animate out rows that are gone (collapse + fade, then destroy)
		for name, row in pairs(win._keyListRows) do
			if desiredMap[name] == nil then
				win._keyListRows[name] = nil
				local fr = row.frame
				local kL, nL, dt = row.keyL, row.nm, row.dot
				if fr and fr.Parent then
					pcall(function()
						TweenService:Create(fr, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Size = UDim2.new(1, 0, 0, 0)}):Play()
						if kL then
							TweenService:Create(kL, TweenInfo.new(0.15), {TextTransparency = 1, BackgroundTransparency = 1}):Play()
						end
						if nL then
							TweenService:Create(nL, TweenInfo.new(0.15), {TextTransparency = 1}):Play()
						end
						if dt then TweenService:Create(dt, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play() end
					end)
					task.delay(0.2, function()
						if mySeq ~= win._keyListSeq then
							-- a newer refresh took over; still safe to remove stale frame
						end
						pcall(function() if fr.Parent and win._keyListRows[name] == nil then fr:Destroy() end end)
					end)
				end
			end
		end
		-- 3) update live rows (text / held highlight) + create new with staggered rise-in
		local n = #desired
		for idx, d in ipairs(desired) do
			local row = win._keyListRows[d.name]
			if row and row.frame and row.frame.Parent then
				row.frame.LayoutOrder = idx
				if row.keyL then
					if row.keyL.Text ~= d.keyName then row.keyL.Text = d.keyName end
					pcall(function()
						row.keyL.Size = UDim2.new(0, 18, 0, 18)
						row.keyL.Position = UDim2.new(0, 8, 0.5, -9)
						row.keyL.BackgroundTransparency = 0
					end)
				end
				if row.nm and row.nm.Text ~= d.fname then row.nm.Text = d.fname end
				pcall(function()
					if row.nm then
						row.nm.Size = UDim2.new(1, -58, 1, 0)
						row.nm.Position = UDim2.new(0, 34, 0, 0)
						row.nm.TextTransparency = 0
					end
					if row.keyL then row.keyL.TextTransparency = 0 end
					if row.dot then
						row.dot.BackgroundTransparency = 0
						row.dot.BackgroundColor3 = d.held and TXT_MAIN or Color3.fromRGB(96, 96, 105)
					end
				end)
				-- repair: row exists but never finished rise-in (e.g. double refresh) -> replay enter
				if row.frame.Size.Y.Offset < 27.5 then
					local rr, kk, nn, dd = row.frame, row.keyL, row.nm, row.dot
					local wantName2 = d.name
					task.delay((idx - 1) * 0.035, function()
						local live = win._keyListRows[wantName2]
						if not live or live.frame ~= rr then return end
						if not rr.Parent then return end
						TweenService:Create(rr, TweenInfo.new(0.26, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 28)}):Play()
						if kk then TweenService:Create(kk, TweenInfo.new(0.26, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {TextTransparency = 0}):Play() end
						if nn then TweenService:Create(nn, TweenInfo.new(0.26, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {TextTransparency = 0}):Play() end
						if dd then TweenService:Create(dd, TweenInfo.new(0.26, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play() end
					end)
				end
			else
				local r = Instance.new("Frame")
				r.Name = "KB_" .. d.name
				r.Size = UDim2.new(1, 0, 0, 0)
				r.BackgroundTransparency = 1
				r.ClipsDescendants = true
				r.LayoutOrder = idx
				r.Parent = body
				-- keycap: E as a real interface element, not body text
				local keyL = Instance.new("TextLabel")
				keyL.Size = UDim2.new(0, 18, 0, 18)
				keyL.Position = UDim2.new(0, 8, 0.5, -9)
				keyL.BackgroundColor3 = BG_TRACK
				keyL.BackgroundTransparency = 0
				keyL.Font = Enum.Font.GothamBold
				keyL.TextSize = 10
				keyL.TextXAlignment = Enum.TextXAlignment.Center
				keyL.TextYAlignment = Enum.TextYAlignment.Center
				keyL.TextColor3 = TXT_MAIN
				keyL.TextTransparency = 1
				keyL.TextTruncate = Enum.TextTruncate.AtEnd
				keyL.RichText = false
				keyL.AutoLocalize = false
				keyL.Text = d.keyName
				keyL.Parent = r
				keyL:SetAttribute("KeepFont", true)
				corner(keyL, 5)
				stroke(keyL, LINE, 0.15, 1)
				local nm = Instance.new("TextLabel")
				nm.Size = UDim2.new(1, -58, 1, 0)
				nm.Position = UDim2.new(0, 34, 0, 3)
				nm.BackgroundTransparency = 1
				nm.Font = Enum.Font.GothamMedium
				nm.TextSize = 12
				nm.TextXAlignment = Enum.TextXAlignment.Left
				nm.TextYAlignment = Enum.TextYAlignment.Center
				nm.TextColor3 = TXT_MAIN
				nm.TextTransparency = 1
				nm.TextTruncate = Enum.TextTruncate.AtEnd
				nm.RichText = false
				nm.AutoLocalize = false
				nm.Text = d.fname
				nm.Parent = r
				nm:SetAttribute("KeepFont", true)
				win:ThemeRegister(nm, "text")
				-- status dot replaces the stray tab icon: white = held, dim = toggled on
				local dot = Instance.new("Frame")
				dot.Name = "State"
				dot.Size = UDim2.new(0, 6, 0, 6)
				dot.Position = UDim2.new(1, -14, 0.5, -3)
				dot.BackgroundColor3 = d.held and TXT_MAIN or Color3.fromRGB(96, 96, 105)
				dot.BackgroundTransparency = 1
				dot.BorderSizePixel = 0
				dot.Parent = r
				corner(dot, 3)
				win._keyListRows[d.name] = { frame = r, keyL = keyL, nm = nm, dot = dot }
				do
					local rr, kk, nn, dd = r, keyL, nm, dot
					local wantName = d.name
					task.delay((idx - 1) * 0.035, function()
						local live = win._keyListRows[wantName]
						if not live or live.frame ~= rr then return end
						if not rr.Parent then return end
						TweenService:Create(rr, TweenInfo.new(0.26, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 28)}):Play()
						TweenService:Create(kk, TweenInfo.new(0.26, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
						TweenService:Create(nn, TweenInfo.new(0.26, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = UDim2.new(0, 36, 0, 0), TextTransparency = 0}):Play()
						TweenService:Create(dd, TweenInfo.new(0.26, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
					end)
				end
			end
		end
		-- 4) empty placeholder with fade (no instant pop)
		local emp = win._keyListEmpty
		if n == 0 then
			if not emp or not emp.Parent then
				local e = Instance.new("TextLabel")
				e.Size = UDim2.new(1, 0, 0, 28)
				e.BackgroundTransparency = 1
				e.Font = Enum.Font.GothamMedium
				e.TextSize = 11
				e.TextColor3 = TXT_FAINT
				e.TextXAlignment = Enum.TextXAlignment.Left
				e.TextTransparency = 1
				e.Text = "No active keybinds"
				e.Parent = body
				win._keyListEmpty = e
				TweenService:Create(e, TweenInfo.new(0.25), {TextTransparency = 0}):Play()
			end
		else
			if emp and emp.Parent then
				win._keyListEmpty = nil
				pcall(function()
					local tw = TweenService:Create(emp, TweenInfo.new(0.15), {TextTransparency = 1})
					tw:Play()
					tw.Completed:Connect(function() pcall(function() emp:Destroy() end) end)
				end)
			end
		end
		-- header count keeps the card informative without extra chrome
		if win._keyListCount then
			win._keyListCount.Text = (n == 0) and "0 active" or (tostring(n) .. " active")
		end
		-- 5) deterministic panel height: tween body + frame together.
		-- AutomaticSize + a tweened row height used to fight each other and made
		-- the panel visibly breathe while a bind was held. One source of truth now.
		local panel = win._keyList and win._keyList.frame
		if panel and panel.Parent then
			local rows = math.max(n, 1)
			local bodyH = rows * 28 + math.max(rows - 1, 0) * 3
			local frameH = 46 + bodyH
			if win._klBodyTween then pcall(function() win._klBodyTween:Cancel() end) end
			if win._klFrameTween then pcall(function() win._klFrameTween:Cancel() end) end
			win._klBodyTween = TweenService:Create(body, TweenInfo.new(0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = UDim2.new(1, -16, 0, bodyH)})
			win._klFrameTween = TweenService:Create(panel, TweenInfo.new(0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = UDim2.new(0, panel.Size.X.Offset, 0, frameH)})
			win._klBodyTween:Play()
			win._klFrameTween:Play()
		end
		win._keyListLastPaint = true
	end
	function win._closeDrop()
		for _, d in ipairs(win._dropLists) do
			if d.list.Visible then
				d.list.Visible = false
				TweenService:Create(d.chev, TweenInfo.new(0.15), {Rotation = 0}):Play()
			end
		end
	end

	local noRes = Instance.new("TextLabel")
	noRes.Name = "NoResults"
	noRes.Size = UDim2.new(1, 0, 0, 40)
	noRes.Position = UDim2.new(0, 0, 0, 20)
	noRes.BackgroundTransparency = 1
	noRes.Font = Enum.Font.Gotham
	noRes.TextSize = 13
	noRes.TextColor3 = TXT_FAINT
	noRes.Text = "No features found"
	noRes.Visible = false
	noRes.Parent = content
	win._noRes = noRes

	-- (v5: no full-width footer; profile lives at sidebar bottom, content runs to bottom)

	local function applySearch()
		win._closeDrop()
		local q = string.lower(string.gsub(searchInput.Text, "^%s+", ""))
		q = string.gsub(q, "%s+$", "")
		searchClear.Visible = (q ~= "")
		local anyMatch = {}
		local total = 0
		if q == "" then
			for _, r in ipairs(win._rowRegs) do
				if r.row.Parent then r.row.Visible = true end
				local dd = r.row.Parent and r.row.Parent:FindFirstChild("Drop_" .. string.sub(r.row.Name, 5))
				if dd then dd.Visible = false end
			end
			for _, s in ipairs(win._sections) do
				s._card.Visible = true
				s._head.Visible = true
			end
			for _, t in ipairs(win._tabs) do
				if t._dot then t._dot.Visible = false end
			end
			win._noRes.Visible = false
			return
		end
		for _, r in ipairs(win._rowRegs) do
			local hit = string.find(r.name, q, 1, true) ~= nil
			if r.row.Parent then r.row.Visible = hit end
			if hit then anyMatch[r.sec._tab] = true total = total + 1 end
		end
		for _, s in ipairs(win._sections) do
			local vis = false
			for _, ch in ipairs(s._card:GetDescendants()) do
				if (ch:IsA("Frame") or ch:IsA("TextButton")) and ch.Visible and string.sub(ch.Name, 1, 4) == "Row_" then
					vis = true break
				end
			end
			s._card.Visible = vis
			s._head.Visible = vis
		end
		for _, t in ipairs(win._tabs) do
			if t._dot then t._dot.Visible = (anyMatch[t] and (not t._page.Visible)) or false end
		end
		win._noRes.Visible = total == 0
	end
	searchInput:GetPropertyChangedSignal("Text"):Connect(applySearch)
	searchInput.FocusLost:Connect(function(enter)
		if enter then
			for _, t in ipairs(win._tabs) do
				if t._dot and t._dot.Visible then
					t._select()
					break
				end
			end
		end
	end)

	task.delay(1, function()
		if not splash.Parent then return end
		TweenService:Create(splash, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
		for _, v in ipairs(splash:GetDescendants()) do
			if v:IsA("TextLabel") then TweenService:Create(v, TweenInfo.new(0.3), {TextTransparency = 1}):Play() end
			if v:IsA("Frame") then TweenService:Create(v, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play() end
		end
		task.wait(0.3)
		splash:Destroy()
		main.Visible = true
		main.Size = UDim2.new(0, WIN_W - 40, 0, WIN_H - 50)
		TweenService:Create(main, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, WIN_W, 0, WIN_H)}):Play()
		win:Notify(title, "Welcome, " .. LocalPlayer.DisplayName)
		win._syncGlass()
		for _, pn in ipairs(win._panels) do pn.Visible = main.Visible end
	end)

	win._visible = true
	function win:Toggle()
		win._visible = not win._visible
		if win._visible then
			main.Visible = true
			main.Size = UDim2.new(0, WIN_W - 40, 0, WIN_H - 50)
			TweenService:Create(main, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = win._size or UDim2.new(0, WIN_W, 0, WIN_H)}):Play()
			win._syncGlass()
			for _, pn in ipairs(win._panels) do pn.Visible = true end
		else
			win._size = main.Size
			local tw = TweenService:Create(main, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Size = UDim2.new(0, WIN_W - 40, 0, WIN_H - 50)})
			tw:Play() tw.Completed:Wait()
			if not win._visible then main.Visible = false end
			win._syncGlass()
			for _, pn in ipairs(win._panels) do pn.Visible = false end
		end
	end
	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == Enum.KeyCode.RightShift then win:Toggle() end
	end)

	function win:AddTab(name, lucideIcon)
		lucideIcon = lucideIcon or "circle"
		local btn = Instance.new("TextButton")
		btn.Name = "Tab_" .. name
		btn.Size = UDim2.new(1, 0, 0, 42)
		btn.BackgroundColor3 = BG_HOVER
		btn.BackgroundTransparency = 1
		btn.Text = ""
		btn.AutoButtonColor = false
		btn.Parent = win._tabsHolder
		btn.LayoutOrder = #win._tabsHolder:GetChildren()
		corner(btn, 9)
		local ic = makeIcon(btn, lucideIcon, 17, ICON_SIDE, UDim2.new(0, 11, 0.5, -8))
		local lb = Instance.new("TextLabel")
		lb.Size = UDim2.new(1, -38, 0, 18)
		lb.Position = UDim2.new(0, 34, 0.5, -9)
		lb.BackgroundTransparency = 1
		lb.Font = Enum.Font.Gotham
		lb.TextSize = 12
		lb.TextXAlignment = Enum.TextXAlignment.Left
		lb.TextColor3 = TXT_SIDEBAR
		lb.TextTruncate = Enum.TextTruncate.AtEnd
		lb.Text = name
		lb.Parent = btn
		local selBar = Instance.new("Frame")
		selBar.Name = "Sel"
		selBar.Size = UDim2.new(0, 3, 0, 22)
		selBar.AnchorPoint = Vector2.new(0, 0.5)
		selBar.Position = UDim2.new(0, 0, 0.5, 0)
		selBar.BackgroundColor3 = win._accent
		selBar.BorderSizePixel = 0
		selBar.Visible = false
		selBar.Parent = btn
		corner(selBar, 1)
		win._reg(function(c) selBar.BackgroundColor3 = c end)
		local dot2 = Instance.new("Frame")
		dot2.Name = "Dot"
		dot2.Size = UDim2.new(0, 6, 0, 6)
		dot2.Position = UDim2.new(1, -12, 0, 6)
		dot2.BackgroundColor3 = win._accent
		dot2.BorderSizePixel = 0
		dot2.Visible = false
		dot2.Parent = btn
		corner(dot2, 3)
		win._reg(function(c) dot2.BackgroundColor3 = c end)

		local page = Instance.new("ScrollingFrame")
		page.Size = UDim2.new(1, 0, 1, 0)
		page.BackgroundTransparency = 1
		page.BorderSizePixel = 0
		page.ScrollBarThickness = 2
		page.ScrollBarImageColor3 = TXT_FAINT
		page.AutomaticCanvasSize = Enum.AutomaticSize.Y
		page.CanvasSize = UDim2.new(0, 0, 0, 0)
		page.Visible = false
		page.Parent = content
		local lay = Instance.new("UIListLayout")
		lay.Padding = UDim.new(0, 12)
		lay.SortOrder = Enum.SortOrder.LayoutOrder
		lay.Parent = page
		local pad = Instance.new("UIPadding")
		pad.PaddingRight = UDim.new(0, 6)
		pad.PaddingBottom = UDim.new(0, 14)
		pad.Parent = page

		local tab = setmetatable({ _win = win, _page = page, _btn = btn, _name = name, _dot = dot2 }, Tab)
		tab._icon = lucideIcon
		table.insert(win._tabs, tab)
		local function select()
			for _, t in ipairs(win._tabs) do
				local active = (t == tab)
				t._active = active
				t._page.Visible = active
				local b2 = t._btn
				TweenService:Create(b2, TweenInfo.new(0.2), {BackgroundTransparency = active and 0 or 1}):Play()
				local ic2 = b2:FindFirstChildOfClass("ImageLabel")
				local lb2 = nil
				for _, ch in ipairs(b2:GetChildren()) do
					if ch:IsA("TextLabel") then lb2 = ch break end
				end
				local bar2 = b2:FindFirstChild("Sel")
			if ic2 then TweenService:Create(ic2, TweenInfo.new(0.2), {ImageColor3 = (active and win:_tc("icon", ICON_MAIN) or win:_tc("icon", ICON_SIDE))}):Play() end
				if lb2 then
					TweenService:Create(lb2, TweenInfo.new(0.2), {TextColor3 = (active and win:_tc("text") or win:_tc("sub", TXT_SIDEBAR))}):Play()
					lb2.Font = active and win:_tf("head") or win:_tf("body")
				end
				if bar2 then bar2.Visible = active end
				if active and t._dot then t._dot.Visible = false end
				if active then
					t._page.Position = UDim2.new(0, 8, 0, 0)
					TweenService:Create(t._page, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
				end
			end
			clickSound(gui, function() return win._sounds end)
			print("[ATHERIUM] tab -> " .. name)
		end
		tab._select = select
		btn.MouseButton1Click:Connect(select)
		btn.MouseEnter:Connect(function()
			if not tab._active then
				TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.7}):Play()
				TweenService:Create(ic, TweenInfo.new(0.15), {ImageColor3 = ICON_DIM}):Play()
				TweenService:Create(lb, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(190, 190, 200)}):Play()
			end
		end)
		btn.MouseLeave:Connect(function()
			if not tab._active then
				TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
				TweenService:Create(ic, TweenInfo.new(0.2), {ImageColor3 = win:_tc("icon", ICON_SIDE)}):Play()
				TweenService:Create(lb, TweenInfo.new(0.2), {TextColor3 = win:_tc("sub", TXT_SIDEBAR)}):Play()
			end
		end)
		if #win._tabs == 1 then
			task.delay(1.15, function() if btn.Parent then select() end end)
		end
		win:ApplyTheme(btn)
		return tab
	end

--// ================= SUBTAB (nested tab under a parent tab) =================
-- usage (open-source friendly):
--   local visuals = win:AddTab("Visuals", "eye")
--   local players = visuals:AddSubTab("Players", "users")
--   local world = visuals:AddSubTab("World", "globe")
--   players:AddSection("Players", "users"):AddToggle({...})
function Tab:AddSubTab(name, lucideIcon)
	lucideIcon = lucideIcon or "circle"
	local win = self._win
	if not self._folder then
		local folder = Instance.new("Frame")
		folder.Name = "SubFolder_" .. self._name
		folder.Size = UDim2.new(1, 0, 0, 0)
		folder.AutomaticSize = Enum.AutomaticSize.Y
		folder.BackgroundTransparency = 1
		folder.LayoutOrder = self._btn.LayoutOrder
		folder.Parent = win._tabsHolder
		local flay = Instance.new("UIListLayout")
		flay.FillDirection = Enum.FillDirection.Vertical
		flay.SortOrder = Enum.SortOrder.LayoutOrder
		flay.Padding = UDim.new(0, 4)
		flay.HorizontalAlignment = Enum.HorizontalAlignment.Right
		flay.Parent = folder
		self._btn.LayoutOrder = 1
		self._btn.Parent = folder
		self._folder = folder
		self._subs = {}
		self._expanded = true
		local chevB = Instance.new("TextButton")
		chevB.Name = "Expand"
		chevB.Size = UDim2.new(0, 24, 0, 24)
		chevB.AnchorPoint = Vector2.new(1, 0.5)
		chevB.Position = UDim2.new(1, -4, 0.5, 0)
		chevB.BackgroundTransparency = 1
		chevB.Text = ""
		chevB.AutoButtonColor = false
		chevB.Parent = self._btn
		self._chev = makeIcon(chevB, "chevron-down", 13, ICON_SIDE, UDim2.new(0.5, -6, 0.5, -6))
		local parentTab = self
		chevB.MouseButton1Click:Connect(function()
			parentTab._expanded = not parentTab._expanded
			for _, s in ipairs(parentTab._subs) do
				s._btn.Visible = parentTab._expanded
			end
			if parentTab._chev then
				TweenService:Create(parentTab._chev, TweenInfo.new(0.2), {Rotation = parentTab._expanded and 0 or -90}):Play()
			end
		end)
	end

	local btn = Instance.new("TextButton")
	btn.Name = "SubTab_" .. name
	btn.Size = UDim2.new(1, -18, 0, 32)
	btn.BackgroundColor3 = BG_HOVER
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.Visible = self._expanded
	btn.Parent = self._folder
	btn.LayoutOrder = 1 + #self._subs + 1
	corner(btn, 8)
	local ic = makeIcon(btn, lucideIcon, 13, ICON_SIDE, UDim2.new(0, 10, 0.5, -6))
	local lb = Instance.new("TextLabel")
	lb.Size = UDim2.new(1, -36, 0, 16)
	lb.Position = UDim2.new(0, 29, 0.5, -8)
	lb.BackgroundTransparency = 1
	lb.Font = Enum.Font.Gotham
	lb.TextSize = 11
	lb.TextXAlignment = Enum.TextXAlignment.Left
	lb.TextColor3 = TXT_SIDEBAR
	lb.TextTruncate = Enum.TextTruncate.AtEnd
	lb.Text = name
	lb.Parent = btn
	local selBar = Instance.new("Frame")
	selBar.Name = "Sel"
	selBar.Size = UDim2.new(0, 2, 0, 16)
	selBar.AnchorPoint = Vector2.new(0, 0.5)
	selBar.Position = UDim2.new(0, 0, 0.5, 0)
	selBar.BackgroundColor3 = win._accent
	selBar.BorderSizePixel = 0
	selBar.Visible = false
	selBar.Parent = btn
	corner(selBar, 1)
	win._reg(function(c) selBar.BackgroundColor3 = c end)
	local dot2 = Instance.new("Frame")
	dot2.Name = "Dot"
	dot2.Size = UDim2.new(0, 6, 0, 6)
	dot2.Position = UDim2.new(1, -12, 0, 6)
	dot2.BackgroundColor3 = win._accent
	dot2.BorderSizePixel = 0
	dot2.Visible = false
	dot2.Parent = btn
	corner(dot2, 3)
	win._reg(function(c) dot2.BackgroundColor3 = c end)

	local page = Instance.new("ScrollingFrame")
	page.Size = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 2
	page.ScrollBarImageColor3 = TXT_FAINT
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.Visible = false
	page.Parent = win._content
	local lay = Instance.new("UIListLayout")
	lay.Padding = UDim.new(0, 12)
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Parent = page
	local pad = Instance.new("UIPadding")
	pad.PaddingRight = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 14)
	pad.Parent = page

	local sub = setmetatable({ _win = win, _page = page, _btn = btn, _name = name, _dot = dot2, _isSub = true, _parent = self, _icon = lucideIcon }, Tab)
	table.insert(self._subs, sub)
	local pi = table.find(win._tabs, self) or #win._tabs
	table.insert(win._tabs, pi + 1, sub)
	local parentTab = self
	local function selectSub()
		for _, t in ipairs(win._tabs) do
			local isSel = (t == sub)
			local active = isSel or (t == parentTab)
			t._active = active
			t._page.Visible = isSel
			local b2 = t._btn
			TweenService:Create(b2, TweenInfo.new(0.2), {BackgroundTransparency = active and 0 or 1}):Play()
			local ic2 = b2:FindFirstChildOfClass("ImageLabel")
			local lb2 = nil
			for _, ch in ipairs(b2:GetChildren()) do
				if ch:IsA("TextLabel") then lb2 = ch break end
			end
			local bar2 = b2:FindFirstChild("Sel")
			if ic2 then TweenService:Create(ic2, TweenInfo.new(0.2), {ImageColor3 = (active and win:_tc("icon", ICON_MAIN) or win:_tc("icon", ICON_SIDE))}):Play() end
			if lb2 then
				TweenService:Create(lb2, TweenInfo.new(0.2), {TextColor3 = (active and win:_tc("text") or win:_tc("sub", TXT_SIDEBAR))}):Play()
				lb2.Font = active and Enum.Font.GothamBold or Enum.Font.Gotham
			end
			if bar2 then bar2.Visible = active end
			if isSel and t._dot then t._dot.Visible = false end
			if isSel then
				t._page.Position = UDim2.new(0, 8, 0, 0)
				TweenService:Create(t._page, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
			end
		end
		clickSound(win._gui, function() return win._sounds end)
		print("[ATHERIUM] subtab -> " .. name)
	end
	sub._select = selectSub
	btn.MouseButton1Click:Connect(selectSub)
	btn.MouseEnter:Connect(function()
		if not sub._active then
			TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.7}):Play()
			TweenService:Create(ic, TweenInfo.new(0.15), {ImageColor3 = ICON_DIM}):Play()
			TweenService:Create(lb, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(190, 190, 200)}):Play()
		end
	end)
	btn.MouseLeave:Connect(function()
		if not sub._active then
			TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
			TweenService:Create(ic, TweenInfo.new(0.2), {ImageColor3 = win:_tc("icon", ICON_SIDE)}):Play()
			TweenService:Create(lb, TweenInfo.new(0.2), {TextColor3 = win:_tc("sub", TXT_SIDEBAR)}):Play()
		end
	end)
	win:ApplyTheme(btn)
	return sub
end

	-- shared smart guides + magnetic snap-drag for overlay panels (keylist, user panels)
	win._guideV = Instance.new("Frame")
	win._guideV.Name = "SmartV"
	win._guideV.Size = UDim2.new(0, 1, 1, 0)
	win._guideV.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	win._guideV.BackgroundTransparency = 0.15
	win._guideV.BorderSizePixel = 0
	win._guideV.Visible = false
	win._guideV.ZIndex = 400
	win._guideV.Parent = gui
	win._guideH = Instance.new("Frame")
	win._guideH.Name = "SmartH"
	win._guideH.Size = UDim2.new(1, 0, 0, 1)
	win._guideH.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	win._guideH.BackgroundTransparency = 0.15
	win._guideH.BorderSizePixel = 0
	win._guideH.Visible = false
	win._guideH.ZIndex = 400
	win._guideH.Parent = gui
	function win._hideGuides()
		if win._guideV then win._guideV.Visible = false end
		if win._guideH then win._guideH.Visible = false end
	end
	-- render-space rect (Position formula; AbsolutePosition.Y lies in some envs)
	local function frameRect(inst, vw, vh)
		local pos = inst.Position
		local s = inst.AbsoluteSize
		return pos.X.Scale * vw + pos.X.Offset, pos.Y.Scale * vh + pos.Y.Offset, s.X, s.Y
	end
	-- Roblox CoreGui (topbar buttons/pills etc.) as extra snap targets.
	-- Scanned once per drag start; dy aligns CoreGui Abs-space to our render-space.
	local function scanCoreGui(dy)
		local rects = {}
		local ok, cg = pcall(function() return game:GetService("CoreGui") end)
		if not ok or not cg then return rects end
		local ok2, des = pcall(function() return cg:GetDescendants() end)
		if not ok2 or type(des) ~= "table" then return rects end
		for _, d in ipairs(des) do
			if #rects >= 48 then break end
			local ok3, r = pcall(function()
				if not d:IsA("GuiObject") then return nil end
				if d:IsDescendantOf(gui) then return nil end -- our own UI already has targets
				if not d.Visible then return nil end
				local s = d.AbsoluteSize
				if s.X < 20 or s.Y < 16 or s.X > 1200 then return nil end
				local ap = d.AbsolutePosition
				if ap.Y < -200 or ap.Y > 160 then return nil end -- top strip only
				local p = d.Parent
				while p and p ~= cg do
					if p:IsA("GuiObject") and not p.Visible then return nil end
					if p:IsA("LayerCollector") and p.Enabled == false then return nil end
					p = p.Parent
				end
				return { x = ap.X, y = ap.Y + (dy or 0), w = s.X, h = s.Y }
			end)
			if ok3 and r then table.insert(rects, r) end
		end
		return rects
	end
	local function snapDrag(f, handle)
		handle = handle or f
		local dragging, dragStart, startPos, extRects = false, nil, nil, {}
		local SNAP = 6
		handle.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = f.Position
				-- never leave the watermark menu orphaned while something is dragged
				pcall(function()
					local wmh = win._watermark
					if wmh and wmh.CloseMenu then wmh:CloseMenu() end
				end)
				-- measure render-vs-Abs Y shift, then cache CoreGui targets for this drag
				pcall(function()
					local dy = 0
					local ref = nil
					if f.Position.Y.Scale == 0 then ref = f end
					if not ref then
						local wf0 = win._watermark and win._watermark.frame
						if wf0 and wf0.Parent then ref = wf0 end
					end
					if ref then
						local v = ref.Position.Y.Offset - ref.AbsolutePosition.Y
						if type(v) == "number" and v == v and math.abs(v) < 500 then dy = v end
					end
					extRects = scanCoreGui(dy)
				end)
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
						win._hideGuides()
					end
				end)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if not dragging then return end
			if win._wmSegHold and win._watermark and f == win._watermark.frame then return end
			if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
			if not f.Parent then dragging = false win._hideGuides() return end
			local delta = input.Position - dragStart
			local nx = startPos.X.Offset + delta.X
			local ny = startPos.Y.Offset + delta.Y
			local w = f.AbsoluteSize.X
			local h = f.AbsoluteSize.Y
			if w < 10 then w = 200 end
			if h < 10 then h = 60 end
			local vw, vh = nil, nil
			local cam = workspace.CurrentCamera
			if cam then
				vw, vh = cam.ViewportSize.X, cam.ViewportSize.Y
			end
			local txs, tys = {}, {}
			if vw then
				table.insert(txs, vw / 2)
				table.insert(tys, vh / 2)
			end
			local function addRect(inst)
				local rx, ry, rw, rh = frameRect(inst, vw, vh)
				table.insert(txs, rx + rw / 2)
				table.insert(txs, rx)
				table.insert(txs, rx + rw)
				table.insert(tys, ry + rh / 2)
				table.insert(tys, ry)
				table.insert(tys, ry + rh)
			end
			if vw then
				local m = win._main -- same upvalue caveat as FontSwapFX
				if m and m ~= f and m.Parent and m.Visible then addRect(m) end
				local wf = win._watermark and win._watermark.frame
				if wf and wf ~= f and wf.Parent and wf.Visible then addRect(wf) end
				local kf = win._keyList and win._keyList.frame
				if kf and kf ~= f and kf.Parent and kf.Visible then addRect(kf) end
				for _, r in ipairs(extRects) do -- Roblox topbar etc., cached at drag start
					table.insert(txs, r.x + r.w / 2)
					table.insert(txs, r.x)
					table.insert(txs, r.x + r.w)
					table.insert(tys, r.y + r.h / 2)
					table.insert(tys, r.y)
					table.insert(tys, r.y + r.h)
				end
			end
			local cx, cy = nx + w / 2, ny + h / 2
			local gx, gy = nil, nil
			for _, tx in ipairs(txs) do
				if math.abs(cx - tx) <= SNAP then nx = tx - w / 2 gx = tx break end
			end
			if gx == nil then
				for _, tx in ipairs(txs) do
					if math.abs(nx - tx) <= SNAP then nx = tx gx = tx break
					elseif math.abs(nx + w - tx) <= SNAP then nx = tx - w gx = tx break end
				end
			end
			for _, ty in ipairs(tys) do
				if math.abs(cy - ty) <= SNAP then ny = ty - h / 2 gy = ty break end
			end
			if gy == nil then
				for _, ty in ipairs(tys) do
					if math.abs(ny - ty) <= SNAP then ny = ty gy = ty break
					elseif math.abs(ny + h - ty) <= SNAP then ny = ty - h gy = ty break end
				end
			end
			if vw then
				nx = math.clamp(nx, 40 - w, vw - 40)
				ny = math.clamp(ny, 0, vh - 40)
			end
			f.Position = UDim2.new(0, nx, 0, ny)
			if gx then win._guideV.Position = UDim2.new(0, gx, 0, 0) win._guideV.Visible = true else win._guideV.Visible = false end
			if gy then win._guideH.Position = UDim2.new(0, 0, 0, gy) win._guideH.Visible = true else win._guideH.Visible = false end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
				win._hideGuides()
			end
		end)
	end
	win._debugCoreRects = function(dy) return scanCoreGui(dy or 0) end

	-- // Liquid Glass surface: translucent tint + vertical depth gradient,
	-- inner top highlight, gradient 1px border, soft drop shadow.
	local GLASS_SHADOW = "rbxassetid://8992230677"
	local function glassShadow(fr, pad)
		pad = pad or 16
		local sh = Instance.new("ImageLabel")
		sh.Name = "GlassShadow"
		sh.AnchorPoint = fr.AnchorPoint
		sh.BackgroundTransparency = 1
		sh.Image = GLASS_SHADOW
		sh.ScaleType = Enum.ScaleType.Slice
		sh.SliceCenter = Rect.new(99, 99, 99, 99)
		sh.ImageColor3 = Color3.fromRGB(0, 0, 0)
		sh.ImageTransparency = 0.72
		sh.ZIndex = 0
		sh.Parent = gui
		local function sync()
			sh.Size = fr.Size + UDim2.new(0, pad * 2, 0, pad * 2)
			sh.Position = UDim2.new(fr.Position.X.Scale, fr.Position.X.Offset - pad, fr.Position.Y.Scale, fr.Position.Y.Offset - pad + 4)
			sh.Visible = fr.Visible
		end
		-- a shadow must never outlive the surface it belongs to
		fr.Destroying:Connect(function() pcall(function() sh:Destroy() end) end)
		sync()
		fr:GetPropertyChangedSignal("Size"):Connect(sync)
		fr:GetPropertyChangedSignal("Position"):Connect(sync)
		fr:GetPropertyChangedSignal("Visible"):Connect(sync)
		return sh
	end
	local function glassify(fr, radius, acrylicTr, blur)
		fr.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		fr.BackgroundTransparency = 0.3
		corner(fr, radius or 10)
		-- depth gradient with a bright top edge baked in: no extra child frames,
		-- so frames that use UIListLayout + AutomaticSize stay intact.
		local g = Instance.new("UIGradient")
		g.Name = "GlassTint"
		g.Rotation = 90
		g.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(72, 72, 82)),
			ColorSequenceKeypoint.new(0.06, Color3.fromRGB(42, 42, 49)),
			ColorSequenceKeypoint.new(0.45, Color3.fromRGB(24, 24, 29)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 12, 15)),
		})
		g.Parent = fr
		local old = fr:FindFirstChildOfClass("UIStroke")
		if old then old:Destroy() end
		local st = Instance.new("UIStroke")
		st.Thickness = 1
		st.Transparency = 0.5
		st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		local sg = Instance.new("UIGradient")
		sg.Rotation = 90
		sg.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.35),
			NumberSequenceKeypoint.new(0.5, 0.72),
			NumberSequenceKeypoint.new(1, 0.93),
		})
		sg.Parent = st
		st.Parent = fr
		win._glass(fr, acrylicTr or 0.3)
		if blur then win._addGlassSurface(fr) end
		return st
	end

	function win:CreatePanel(opts)
		opts = opts or {}
		local title = opts.Title or "Panel"
		local icon = opts.Icon or "layers"
		local width = opts.Width or 230
		local f = Instance.new("Frame")
		f.Name = "Panel_" .. title
		f.Size = UDim2.new(0, width, 0, 80)
		f.AnchorPoint = Vector2.new(0, 0.5)
		f.Position = UDim2.new(0.5, WIN_W / 2 + 16, 0.5, -120)
		f.BackgroundColor3 = BG_CARD
		f.BorderSizePixel = 0
		f.Visible = main.Visible
		f.Parent = gui
		glassify(f, 10, 0.2)
		glassShadow(f, 12)
		table.insert(win._panels, f)
		local hb = Instance.new("Frame")
		hb.Name = "Head"
		hb.Size = UDim2.new(1, 0, 0, 34)
		hb.BackgroundTransparency = 1
		hb.Parent = f
		makeIcon(hb, icon, 13, ICON_DIM, UDim2.new(0, 8, 0.5, -6))
		local tt = Instance.new("TextLabel")
		tt.Size = UDim2.new(1, -40, 1, 0)
		tt.Position = UDim2.new(0, 24, 0, 0)
		tt.BackgroundTransparency = 1
		tt.Font = Enum.Font.GothamBold
		tt.TextSize = 12
		tt.TextXAlignment = Enum.TextXAlignment.Left
		tt.TextColor3 = TXT_MAIN
		tt.Text = title
		tt.Parent = hb
		hairline(f, 34)
		snapDrag(f, hb)
		local pbody = Instance.new("Frame")
		pbody.Name = "Body"
		pbody.Size = UDim2.new(1, -16, 1, -50)
		pbody.Position = UDim2.new(0, 8, 0, 42)
		pbody.BackgroundTransparency = 1
		pbody.Parent = f
		local play = Instance.new("UIListLayout")
		play.SortOrder = Enum.SortOrder.LayoutOrder
		play.Padding = UDim.new(0, 4)
		play.Parent = pbody
		win:ApplyTheme(f)
		return { frame = f, body = pbody }
	end
	function win:CreateKeyList()
		if win._keyList then return win._keyList end
		local p = win:CreatePanel({ Title = "Keybinds", Icon = "keyboard", Width = 220 })
		pcall(function()
			local hl = p.frame:FindFirstChild("Hairline")
			if hl then hl:Destroy() end
		end)
		-- compact header: 32px, icon block + title share the row axis
		local head = p.frame:FindFirstChild("Head")
		if head then
			head.Size = UDim2.new(1, 0, 0, 32)
			local hic = head:FindFirstChildWhichIsA("ImageLabel")
			if hic then
				hic.Size = UDim2.new(0, 14, 0, 14)
				hic.Position = UDim2.new(0, 11, 0.5, -7)
			end
			local ttl = head:FindFirstChildOfClass("TextLabel")
			if ttl then
				ttl.Position = UDim2.new(0, 34, 0, 0)
				ttl.Size = UDim2.new(1, -110, 1, 0)
			end
		end
		-- right-aligned count, updates on every refresh
		local count = Instance.new("TextLabel")
		count.Name = "WmCount"
		count.Size = UDim2.new(0, 70, 0, 16)
		count.AnchorPoint = Vector2.new(1, 0.5)
		count.Position = UDim2.new(1, -10, 0.5, 0)
		count.BackgroundTransparency = 1
		count.Font = Enum.Font.GothamMedium
		count.TextSize = 10
		count.TextXAlignment = Enum.TextXAlignment.Right
		count.TextColor3 = TXT_SOFT
		count.Text = ""
		count.Parent = head
		win._keyListCount = count
		p.body.Position = UDim2.new(0, 8, 0, 38)
		p.body.Size = UDim2.new(1, -16, 0, 0)
		p.body.ClipsDescendants = true
		p.body.AutomaticSize = Enum.AutomaticSize.None
		pcall(function()
			local lay = p.body:FindFirstChildOfClass("UIListLayout")
			if lay then
				lay.Padding = UDim.new(0, 3)
				lay.SortOrder = Enum.SortOrder.LayoutOrder
			end
		end)
		p.frame.AutomaticSize = Enum.AutomaticSize.None
		p.frame.Size = UDim2.new(0, p.frame.Size.X.Offset, 0, 46)
		win._keyListBody = p.body
		win._keyList = p
		win._refreshKeyList()
		return p
	end
	function win:CreateWatermark(opts)
		opts = opts or {}
		if win._watermark and win._watermark.frame and win._watermark.frame.Parent then
			return win._watermark
		end
		local version = opts.Version or ("v" .. VibeUI.Version)
		local pos = opts.Position or UDim2.new(0, 16, 0, 54)
		local WM_KEYS = { cheat = true, player = true, fps = true, ping = true, time = true, players = true }
		-- fixed slots: brand -> players -> ping -> time -> nick -> fps.
		-- normalize() always sorts into this list, so re-enabling a module
		-- puts it back into its slot instead of appending it to the end.
		local WM_ALL = { "cheat", "players", "ping", "time", "player", "fps" }
		local WM_DEFAULT = { "cheat", "players", "ping", "time", "player", "fps" }
		-- no physical glass part under the pill: it reflected the sun as a
		-- white halo. Solid-ish frost reads the same and never blows out.
		local WM_BG_TR = 0.2

		local function normalize(keys, skip)
			local seen, out = {}, {}
			for _, k in ipairs(keys or {}) do
				if WM_KEYS[k] and k ~= skip and not seen[k] then
					seen[k] = true
				end
			end
			for _, k in ipairs(WM_ALL) do
				if seen[k] then table.insert(out, k) end
			end
			return out
		end
		if type(win._wmOrder) ~= "table" then win._wmOrder = {} end
		win._wmOrder = normalize(win._wmOrder)
		if #win._wmOrder == 0 then
			for _, k in ipairs(WM_DEFAULT) do table.insert(win._wmOrder, k) end
		end

		local Players = game:GetService("Players")
		local LocalPlayer = Players.LocalPlayer
		local RunService = game:GetService("RunService")
		local Stats = game:GetService("Stats")

		local f = Instance.new("Frame")
		f.Name = "Watermark"
		f.Size = UDim2.new(0, 0, 0, 30)
		f.AutomaticSize = Enum.AutomaticSize.X
		f.Position = UDim2.new(pos.X.Scale, pos.X.Offset, pos.Y.Scale, pos.Y.Offset - 6)
		f.BackgroundColor3 = BG_CARD
		f.BackgroundTransparency = WM_BG_TR
		f.BorderSizePixel = 0
		f.Active = true
		f.Parent = gui
		local fStroke = glassify(f, 12, WM_BG_TR)
		glassShadow(f, 14)

		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 12)
		pad.PaddingRight = UDim.new(0, 12)
		pad.Parent = f
		local lay = Instance.new("UIListLayout")
		lay.FillDirection = Enum.FillDirection.Horizontal
		lay.VerticalAlignment = Enum.VerticalAlignment.Center
		lay.SortOrder = Enum.SortOrder.LayoutOrder
		lay.Padding = UDim.new(0, 0)
		lay.Parent = f

		snapDrag(f, f)

		local fpsFrames, fpsT0, fpsVal = 0, os.clock(), 0
		local fpsConn
		fpsConn = RunService.RenderStepped:Connect(function()
			if not f.Parent then
				pcall(function() if fpsConn then fpsConn:Disconnect() end end)
				return
			end
			fpsFrames = fpsFrames + 1
			local now = os.clock()
			if now - fpsT0 >= 0.5 then
				fpsVal = math.floor(fpsFrames / (now - fpsT0) + 0.5)
				fpsFrames, fpsT0 = 0, now
			end
		end)

		local segUnits = { fps = "FPS", ping = "ms", players = "players" }
		local function segValue(key)
			if key == "cheat" then
				return "Atherium " .. version
			elseif key == "player" then
				return LocalPlayer and LocalPlayer.DisplayName or "Player"
			elseif key == "fps" then
				return tostring(fpsVal)
			elseif key == "ping" then
				local p = 0
				pcall(function() p = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5) end)
				return tostring(p)
			elseif key == "time" then
				return os.date("%H:%M:%S")
			elseif key == "players" then
				return tostring(#Players:GetPlayers())
			end
			return key
		end
		local segIcon = { player = "user", fps = "activity", ping = "wifi", time = "clock", players = "users" }

		-- contrast pass: icons and secondary labels must stay readable on a
		-- sunlit background behind the pill
		local WM_VALUE = Color3.fromRGB(246, 246, 250)
		local WM_ICON = Color3.fromRGB(236, 236, 242)
		local WM_UNIT = Color3.fromRGB(176, 176, 188)
		local WM_NAME = Color3.fromRGB(206, 206, 216)
		local TextService = game:GetService("TextService")

		local function measure(text, size, font)
			local ok, v = pcall(function()
				return TextService:GetTextSize(tostring(text), size, font, Vector2.new(600, 100))
			end)
			if ok and v then return v.X end
			return #tostring(text) * size * 0.6
		end
		-- reserved widths: digits never reflow the pill when a value ticks
		local segFixed = {
			fps = math.ceil(measure("999", 11, Enum.Font.Code)) + 1,
			ping = math.ceil(measure("999", 11, Enum.Font.Code)) + 1,
			time = math.ceil(measure("00:00:00", 11, Enum.Font.Code)) + 1,
			players = math.ceil(measure("999", 11, Enum.Font.Code)) + 1,
			player = 108,
		}

		local function softStroke(inst, tr)
			local st = Instance.new("UIStroke")
			st.Color = Color3.new(0, 0, 0)
			st.Thickness = 1
			st.Transparency = tr or 0.62
			st.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
			st.Parent = inst
			return st
		end

		-- CanvasGroup per segment costs an extra render pass each; fade the
		-- segment children instead. One NumberValue drives the whole fade.
		local function segAlpha(s, a)
			for _, ch in ipairs(s:GetDescendants()) do
				local base = ch:GetAttribute("BaseTr")
				if ch:IsA("TextLabel") then
					if base == nil then base = ch.TextTransparency ch:SetAttribute("BaseTr", base) end
					ch.TextTransparency = base + (1 - base) * a
				elseif ch:IsA("ImageLabel") then
					if base == nil then base = ch.ImageTransparency ch:SetAttribute("BaseTr", base) end
					ch.ImageTransparency = base + (1 - base) * a
				elseif ch:IsA("UIStroke") then
					if base == nil then base = ch.Transparency ch:SetAttribute("BaseTr", base) end
					ch.Transparency = base + (1 - base) * math.min(1, a + 0.15)
				elseif ch:IsA("Frame") then
					if base == nil then base = ch.BackgroundTransparency ch:SetAttribute("BaseTr", base) end
					ch.BackgroundTransparency = base + (1 - base) * a
				end
			end
		end

		local segs, divs, labels, alphaNodes = {}, {}, {}, {}
		local function createSeg(key)
			local s = Instance.new("Frame")
			s.Name = "Seg_" .. key
			s.Size = UDim2.new(0, 0, 1, 0)
			s.AutomaticSize = Enum.AutomaticSize.X
			s.BackgroundTransparency = 1
			s.BorderSizePixel = 0
			s.ClipsDescendants = true
			s.Parent = f
			local ip = Instance.new("UIPadding")
			ip.PaddingLeft = UDim.new(0, 9)
			ip.PaddingRight = UDim.new(0, 9)
			ip.Parent = s
			local il = Instance.new("UIListLayout")
			il.FillDirection = Enum.FillDirection.Horizontal
			il.VerticalAlignment = Enum.VerticalAlignment.Center
			il.SortOrder = Enum.SortOrder.LayoutOrder
			il.Padding = UDim.new(0, 6)
			il.Parent = s
			local iconName = segIcon[key]
			if iconName then
				local ic = makeIcon(s, iconName, 14, WM_ICON)
				ic.LayoutOrder = 1
				softStroke(ic, 0.7)
			else
				local dot = Instance.new("Frame")
				dot.Size = UDim2.new(0, 5, 0, 5)
				dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				dot.BorderSizePixel = 0
				dot.LayoutOrder = 1
				dot.Parent = s
				corner(dot, 3)
			end
			local numeric = (key == "fps" or key == "ping" or key == "time" or key == "players")
			local lb = Instance.new("TextLabel")
			lb.Name = "Val_" .. key
			local fixedW = segFixed[key]
			if fixedW then
				lb.Size = UDim2.new(0, fixedW, 1, 0)
				lb.AutomaticSize = Enum.AutomaticSize.None
			else
				lb.Size = UDim2.new(0, 0, 1, 0)
				lb.AutomaticSize = Enum.AutomaticSize.X
			end
			lb.BackgroundTransparency = 1
			lb.Font = numeric and Enum.Font.Code
				or (key == "cheat" and Enum.Font.GothamBold or Enum.Font.GothamMedium)
			lb.TextSize = 11
			lb.TextColor3 = numeric and WM_VALUE or (key == "cheat" and Color3.fromRGB(255, 255, 255) or WM_NAME)
			lb.TextXAlignment = Enum.TextXAlignment.Left
			lb.TextYAlignment = Enum.TextYAlignment.Center
			lb.TextTruncate = Enum.TextTruncate.AtEnd
			lb.RichText = false
			lb.AutoLocalize = false
			lb.Text = segValue(key)
			lb.LayoutOrder = 2
			lb.Parent = s
			lb:SetAttribute("KeepFont", true)
			softStroke(lb, 0.66)
			labels[key] = lb
			if segUnits[key] then
				local un = Instance.new("TextLabel")
				un.Name = "Unit_" .. key
				un.Size = UDim2.new(0, 0, 1, 0)
				un.AutomaticSize = Enum.AutomaticSize.X
				un.BackgroundTransparency = 1
				un.Font = Enum.Font.GothamMedium
				un.TextSize = 10
				un.TextColor3 = WM_UNIT
				un.TextXAlignment = Enum.TextXAlignment.Left
				un.TextYAlignment = Enum.TextYAlignment.Center
				un.Text = segUnits[key]
				un.LayoutOrder = 3
				un.Parent = s
				un:SetAttribute("KeepFont", true)
				softStroke(un, 0.78)
			end
			-- lock in the design transparency before any fade runs
			for _, ch in ipairs(s:GetDescendants()) do
				local b
				if ch:IsA("TextLabel") then b = ch.TextTransparency
				elseif ch:IsA("ImageLabel") then b = ch.ImageTransparency
				elseif ch:IsA("UIStroke") then b = ch.Transparency
				elseif ch:IsA("Frame") then b = ch.BackgroundTransparency end
				if b ~= nil then ch:SetAttribute("BaseTr", b) end
			end
			local nv = Instance.new("NumberValue")
			nv.Name = "Alpha"
			nv.Value = 0
			nv.Parent = s
			nv.Changed:Connect(function(v) segAlpha(s, v) end)
			alphaNodes[key] = nv
			return s
		end

		-- deterministic width so a newly enabled segment grows from 0px
		local function segWidth(key)
			local iconW = segIcon[key] and 14 or 5
			local w = 18 + iconW + 6
			local fixedW = segFixed[key]
			if fixedW then
				w = w + fixedW
			else
				local numeric = (key == "fps" or key == "ping" or key == "time" or key == "players")
				local vf = numeric and Enum.Font.Code
					or (key == "cheat" and Enum.Font.GothamBold or Enum.Font.GothamMedium)
				w = w + measure(segValue(key), 11, vf)
			end
			if segUnits[key] then w = w + 6 + measure(segUnits[key], 10, Enum.Font.GothamMedium) end
			return math.ceil(w) + 1
		end

		local function clearDivs()
			for _, d in ipairs(divs) do
				if d.Parent then d:Destroy() end
			end
			divs = {}
		end

		local function rebuildLayout()
			clearDivs()
			local prev = nil
			for i, key in ipairs(WM_ALL) do
				local s = segs[key]
				if s and s.Parent then
					s.LayoutOrder = i * 2
					if prev then
						local d = Instance.new("Frame")
						d.Name = "Div"
						d.Size = UDim2.new(0, 1, 0, 12)
						d.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						d.BackgroundTransparency = 0.82
						d.BorderSizePixel = 0
						d.LayoutOrder = i * 2 - 1
						d.Parent = f
						table.insert(divs, d)
					end
					prev = s
				end
			end
		end

		local function buildContent()
			local order = normalize(win._wmOrder)
			if #order == 0 then order = normalize(WM_DEFAULT) end
			win._wmOrder = order
			local keep = {}
			for _, key in ipairs(order) do
				keep[key] = true
				local s = segs[key]
				if not s or not s.Parent then
					s = createSeg(key)
					segs[key] = s
				end
			end
			for key, s in pairs(segs) do
				if not keep[key] then
					pcall(function() s:Destroy() end)
					segs[key] = nil
					labels[key] = nil
					alphaNodes[key] = nil
				end
			end
			rebuildLayout()
		end

		-- width is driven by the pill's AutomaticSize, so tweening a single
		-- segment width animates the whole bar without any layout math
		local function fadeSeg(key, to, dur)
			local nv = alphaNodes[key]
			if not nv or not nv.Parent then return end
			TweenService:Create(nv, TweenInfo.new(dur or 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Value = to }):Play()
		end
		local function animateSeg(key, adding)
			local s = segs[key]
			if not s or not s.Parent then return end
			if adding then
				local w = segWidth(key)
				s.AutomaticSize = Enum.AutomaticSize.None
				s.Size = UDim2.new(0, 0, 1, 0)
				local nv = alphaNodes[key]
				if nv then nv.Value = 1 end
				TweenService:Create(s, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					Size = UDim2.new(0, w, 1, 0),
				}):Play()
				fadeSeg(key, 0, 0.24)
				task.delay(0.24, function()
					if s.Parent then s.AutomaticSize = Enum.AutomaticSize.X end
				end)
			else
				local cur = math.max(s.AbsoluteSize.X, 1)
				s.AutomaticSize = Enum.AutomaticSize.None
				s.Size = UDim2.new(0, cur, 1, 0)
				-- the spacer before this segment collapses with it, so the
				-- neighbouring slot closes without a 1px snap
				local div
				for _, d in ipairs(divs) do
					if d.Parent and d.LayoutOrder == s.LayoutOrder - 1 then div = d break end
				end
				if div then
					TweenService:Create(div, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
						Size = UDim2.new(0, 0, 0, 12), BackgroundTransparency = 1,
					}):Play()
				end
				fadeSeg(key, 1, 0.2)
				local tw = TweenService:Create(s, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					Size = UDim2.new(0, 0, 1, 0),
				})
				tw:Play()
				tw.Completed:Connect(function()
					pcall(function() s:Destroy() end)
					segs[key] = nil
					labels[key] = nil
					alphaNodes[key] = nil
					pcall(function() div:Destroy() end)
					rebuildLayout()
				end)
			end
		end

		-- soft value swap: digits refresh with a short fade-in, never a blink
		local valTweens = {}
		local function setVal(lb, t)
			if not lb or lb.Text == t then return end
			lb.Text = t
			local old = valTweens[lb]
			if old then pcall(function() old:Cancel() end) end
			lb.TextTransparency = 0.35
			local tw = TweenService:Create(lb, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0})
			valTweens[lb] = tw
			tw:Play()
		end

		local shown = false
		local function intro()
			if shown then f.Visible = true return end
			shown = true
			f.Visible = true
			local sc = f:FindFirstChildOfClass("UIScale")
			if not sc then
				sc = Instance.new("UIScale")
				sc.Parent = f
			end
			sc.Scale = 0.94
			f.BackgroundTransparency = 1
			fStroke.Transparency = 1
			TweenService:Create(f, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = WM_BG_TR}):Play()
			TweenService:Create(fStroke, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency = 0.55}):Play()
			TweenService:Create(sc, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Scale = 1}):Play()
			local i = 0
			for key, s in pairs(segs) do
				local nv = alphaNodes[key]
				if nv then nv.Value = 1 end
				i = i + 1
				task.delay(0.03 * i, function()
					if s.Parent then
						TweenService:Create(nv, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = 0 }):Play()
					end
				end)
			end
		end

		-- // RMB menu: live segment toggles, same slate language, no bounce
		local menu, menuConn, openT = nil, nil, false
		local function closeMenu()
			if menuConn then pcall(function() menuConn:Disconnect() end) menuConn = nil end
			if not menu then return end
			local m = menu
			menu = nil
			pcall(function()
				local tw = TweenService:Create(m, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1})
				tw:Play()
				tw.Completed:Connect(function() pcall(function() m:Destroy() end) end)
			end)
			task.delay(0.16, function() pcall(function() m:Destroy() end) end)
		end

		local function refreshChecks(m)
			if not m then return end
			local enabled = {}
			for _, k in ipairs(win._wmOrder or {}) do enabled[k] = true end
			for _, ch in ipairs(m:GetDescendants()) do
				if ch:IsA("ImageLabel") and ch:GetAttribute("WmCheck") then
					ch.Visible = enabled[ch:GetAttribute("WmCheck")] == true
				end
			end
		end

		-- toggle keeps the canonical slot: enable -> grows in place,
		-- disable -> collapses in place, nothing jumps to the end
		local function applyToggle(key)
			local enabled = {}
			for _, k in ipairs(win._wmOrder or {}) do enabled[k] = true end
			if enabled[key] then
				if #win._wmOrder <= 1 then return end
				win._wmOrder = normalize(win._wmOrder, key)
				local s = segs[key]
				rebuildLayout()
				animateSeg(key, false)
			else
				win._wmOrder = normalize(win._wmOrder, nil)
				table.insert(win._wmOrder, key)
				win._wmOrder = normalize(win._wmOrder)
				local s = segs[key]
				if not s or not s.Parent then
					s = createSeg(key)
					segs[key] = s
				end
				rebuildLayout()
				animateSeg(key, true)
			end
			refreshChecks(menu)
			win._dirty = true
		end

		local function openMenu()
			if menu then closeMenu() return end
			openT = os.clock()
			local rowH = 22
			local headH = 28
			local menuW = 148
			local menuH = headH + #WM_ALL * rowH + 8
			local m = Instance.new("Frame")
			m.Name = "WatermarkMenu"
			m.Size = UDim2.new(0, menuW, 0, menuH)
			m.BackgroundColor3 = BG_CARD
			m.BackgroundTransparency = 0.04
			m.BorderSizePixel = 0
			m.ZIndex = 40
			m.Parent = gui
			corner(m, 8)
			stroke(m, LINE, 0.3, 1)
			local sc = Instance.new("UIScale")
			sc.Scale = 0.96
			sc.Parent = m
			TweenService:Create(sc, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1}):Play()

			local hdr = Instance.new("TextLabel")
			hdr.Size = UDim2.new(1, -20, 0, headH - 6)
			hdr.Position = UDim2.new(0, 10, 0, 6)
			hdr.BackgroundTransparency = 1
			hdr.Font = Enum.Font.GothamBold
			hdr.TextSize = 11
			hdr.TextXAlignment = Enum.TextXAlignment.Left
			hdr.TextColor3 = TXT_MAIN
			hdr.Text = "Watermark"
			hdr.ZIndex = 41
			hdr.Parent = m

			local listY = headH
			for i, key in ipairs(WM_ALL) do
				local row = Instance.new("TextButton")
				row.Name = "WmRow_" .. key
				row.Size = UDim2.new(1, -8, 0, rowH)
				row.Position = UDim2.new(0, 4, 0, listY + (i - 1) * rowH)
				row.BackgroundColor3 = BG_HOVER
				row.BackgroundTransparency = 1
				row.Text = ""
				row.AutoButtonColor = false
				row.ZIndex = 41
				row.Parent = m
				corner(row, 5)
				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(1, -28, 1, 0)
				lbl.Position = UDim2.new(0, 8, 0, 0)
				lbl.BackgroundTransparency = 1
				lbl.Font = Enum.Font.GothamMedium
				lbl.TextSize = 11
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.TextColor3 = TXT_DIM
				lbl.Text = ({
					cheat = "Title", player = "Player", fps = "FPS",
					ping = "Ping", time = "Time", players = "Players",
				})[key] or key
				lbl.ZIndex = 41
				lbl.Parent = row
				local chk = makeIcon(row, "check", 11, TXT_MAIN, UDim2.new(1, -18, 0.5, -5))
				chk.ZIndex = 41
				chk:SetAttribute("WmCheck", key)
				row.MouseEnter:Connect(function()
					TweenService:Create(row, TweenInfo.new(0.12), {BackgroundTransparency = 0.85}):Play()
				end)
				row.MouseLeave:Connect(function()
					TweenService:Create(row, TweenInfo.new(0.12), {BackgroundTransparency = 1}):Play()
				end)
				row.MouseButton1Click:Connect(function()
					applyToggle(key)
				end)
			end
			refreshChecks(m)
			menu = m

			-- place under the pill, clamped to viewport
			local px = f.AbsolutePosition.X
			local py = f.AbsolutePosition.Y + f.AbsoluteSize.Y + 6
			local cam = workspace.CurrentCamera
			if cam then
				local vw, vh = cam.ViewportSize.X, cam.ViewportSize.Y
				px = math.clamp(px, 8, math.max(8, vw - menuW - 8))
				py = math.clamp(py, 8, math.max(8, vh - menuH - 8))
			end
			m.Position = UDim2.new(0, px, 0, py)

			menuConn = UserInputService.InputBegan:Connect(function(input)
				if not menu then return end
				if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
				if os.clock() - openT < 0.1 then return end
				local mp = input.Position
				local a, s2 = menu.AbsolutePosition, menu.AbsoluteSize
				local inside = mp.X >= a.X and mp.X <= a.X + s2.X and mp.Y >= a.Y and mp.Y <= a.Y + s2.Y
				local fa, fs = f.AbsolutePosition, f.AbsoluteSize
				local onPill = mp.X >= fa.X and mp.X <= fa.X + fs.X and mp.Y >= fa.Y and mp.Y <= fa.Y + fs.Y
				if not inside and not onPill then closeMenu() end
			end)
		end

		f.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton2 then
				openMenu()
			end
		end)

		buildContent()
		intro()

		task.spawn(function()
			while f.Parent do
				task.wait(0.5)
				for key, lb in pairs(labels) do
					if lb.Parent then
						setVal(lb, segValue(key))
					end
				end
			end
		end)

		local handle = { frame = f }
		local visible = true
		function handle:SetVisible(v)
			visible = not not v
			if visible then
				f.Visible = true
				intro()
			else
				closeMenu()
				f.Visible = false
				shown = false
			end
		end
		function handle:GetVisible() return visible end
		function handle:Rebuild() buildContent() end
		function handle:CloseMenu() closeMenu() end
		function handle:ResetWatermark()
			win._wmOrder = {}
			for _, k in ipairs(WM_DEFAULT) do table.insert(win._wmOrder, k) end
			buildContent()
			refreshChecks(menu)
			win._dirty = true
		end
		function handle:HideAllWatermark()
			handle:SetVisible(false)
		end
		function handle:SetOption(key, v)
			if not WM_KEYS[key] then return false end
			local enabled = false
			for _, k in ipairs(win._wmOrder or {}) do
				if k == key then enabled = true end
			end
			if enabled ~= (not not v) then applyToggle(key) end
			return true
		end
		function handle:GetOptions()
			local out = {}
			for _, k in ipairs(win._wmOrder or {}) do out[k] = true end
			return out
		end
		function handle:AddDeath() end
		function handle:ResetKD() end
		function handle:SetKDSource() end
		function handle:Destroy()
			closeMenu()
			pcall(function() if fpsConn then fpsConn:Disconnect() end end)
			pcall(function() f:Destroy() end)
			if win._watermark == handle then win._watermark = nil end
		end
		win._watermark = handle
		if win._publish then win._publish() end
		function win:SetWatermarkVisible(v)
			handle:SetVisible(v)
		end
		return handle
	end
	local function cfgPath(name)
		name = tostring(name or "")
		if name:find("[/\\]") or name:sub(-5):lower() == ".json" then return name end
		pcall(function()
			if makefolder then
				pcall(function() makefolder("Atherium") end)
				pcall(function() makefolder("Atherium/Configs") end)
			end
		end)
		return "Atherium/Configs/" .. name .. ".json"
	end
	function win:ListConfigs()
		local out = {}
		pcall(function()
			if not listfiles then return end
			for _, p in ipairs(listfiles("Atherium/Configs")) do
				local n = tostring(p):match("([^/\\]+)%.json$")
				if n then table.insert(out, n) end
			end
		end)
		table.sort(out)
		return out
	end
	-- one canonical snapshot of every registered control + the theme; the file
	-- writer and the share-code exporter both read from here
	function win:_configBlob()
		local data = { version = 2, items = {} }
		for _, c in ipairs(win._cfg) do
			local ok, v = pcall(c.get)
			if ok then
				table.insert(data.items, { kind = c.kind, tab = c.tab, sec = c.sec, name = c.name, value = v })
			end
		end
		pcall(function()
			local th = win._theme
			if th then
				local tv = {}
				if th.fontName ~= nil then tv.font = th.fontName end
				if th.accentTouched and th.accent then tv.accent = rgbToHex(th.accent) end
				if th.text then tv.text = rgbToHex(th.text) end
				if th.sub then tv.sub = rgbToHex(th.sub) end
				if win._wmOrder then tv.wmorder = table.concat(win._wmOrder, ",") end
				table.insert(data.items, { kind = "theme", tab = "", sec = "", name = "theme", value = tv })
			end
		end)
		return data
	end
	function win:SaveConfig(fname, quiet)
		local path = cfgPath((fname == nil) and "default" or fname)
		local data = win:_configBlob()
		local ok, json = pcall(function() return game:GetService("HttpService"):JSONEncode(data) end)
		if not ok or type(json) ~= "string" then if not quiet then win:Notify("Config", "Encode failed") end return false end
		pcall(function() writefile(path, json) end)
		local verified = false
		for _ = 1, 6 do
			local rok, rtxt = pcall(function() return readfile(path) end)
			if rok and rtxt == json then verified = true break end
			task.wait(0.15)
		end
		if verified then
			win._dirty = false
			if not quiet then win:Notify("Config", "Saved (" .. tostring(#data.items) .. ")") end
		else
			if not quiet then win:Notify("Config", "Save FAILED - retry") end
		end
		print("[ATHERIUM] config saved -> " .. path .. " (" .. tostring(#data.items) .. " items) verified=" .. tostring(verified))
		return verified
	end
	-- applies a decoded config table; returns how many values actually landed
	function win:_applyConfig(data)
		local items = (type(data) == "table" and (data.items or data)) or nil
		if type(items) ~= "table" then return 0 end
		local n = 0
		for _, it in ipairs(items) do
			if type(it) == "table" then
				if it.kind == "theme" and type(it.value) == "table" then
					if pcall(function() win:ApplyThemeData(it.value) end) then n = n + 1 end
				else
					for _, c in ipairs(win._cfg) do
						if c.kind == it.kind and c.tab == it.tab and c.sec == it.sec and c.name == it.name then
							if pcall(c.set, it.value) then n = n + 1 end
							break
						end
					end
				end
			end
		end
		win._refreshKeyList()
		return n
	end
	function win:LoadConfig(fname)
		local paths = {}
		if fname == nil then
			paths = { cfgPath("default"), "AtheriumConfigs/default.json", "AtheriumConfig.json" }
		else
			paths = { cfgPath(fname) }
		end
		for _, path in ipairs(paths) do
			local ok, txt = false, nil
			for _ = 1, 3 do
				ok, txt = pcall(function() return readfile(path) end)
				if ok and type(txt) == "string" then break end
				task.wait(0.1)
			end
			if ok and type(txt) == "string" then
				local ok2, data = pcall(function() return game:GetService("HttpService"):JSONDecode(txt) end)
				if ok2 and type(data) == "table" then
					local n = win:_applyConfig(data)
					print("[ATHERIUM] config loaded <- " .. path .. " (" .. tostring(n) .. " items)")
					return n > 0
				end
			end
		end
		return false
	end
	function win:DeleteConfig(fname)
		if fname == nil or fname == "" or fname == "No configs" then win:Notify("Config", "Nothing to delete") return false end
		local path = cfgPath(fname)
		local ok = pcall(function() delfile(path) end)
		if ok then win:Notify("Config", "Deleted " .. tostring(fname)) else win:Notify("Config", "Delete failed") end
		return ok
	end

	--// ---------- profiles: named slots plus one-line share codes ----------
	-- A profile is just a config file; this layer adds sizes, rename and a
	-- portable export so a whole layout can travel through Discord.
	local B64C = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	local B64D = {}
	for i = 1, #B64C do B64D[B64C:sub(i, i)] = i - 1 end

	local function b64encode(str)
		local out = {}
		for i = 1, #str, 3 do
			local a, b, c = str:byte(i, i + 2)
			local n = a * 65536 + (b or 0) * 256 + (c or 0)
			table.insert(out, B64C:sub(math.floor(n / 262144) % 64 + 1, math.floor(n / 262144) % 64 + 1))
			table.insert(out, B64C:sub(math.floor(n / 4096) % 64 + 1, math.floor(n / 4096) % 64 + 1))
			table.insert(out, b and B64C:sub(math.floor(n / 64) % 64 + 1, math.floor(n / 64) % 64 + 1) or "=")
			table.insert(out, c and B64C:sub(n % 64 + 1, n % 64 + 1) or "=")
		end
		return table.concat(out)
	end

	local function b64decode(str)
		str = tostring(str):gsub("[^%w%+/=]", "")
		local out = {}
		for i = 1, #str, 4 do
			local chunk = str:sub(i, i + 3)
			local n1, n2 = B64D[chunk:sub(1, 1)], B64D[chunk:sub(2, 2)]
			local n3, n4 = B64D[chunk:sub(3, 3)], B64D[chunk:sub(4, 4)]
			if not n1 or not n2 then break end
			local n = n1 * 262144 + n2 * 4096 + (n3 or 0) * 64 + (n4 or 0)
			table.insert(out, string.char(math.floor(n / 65536) % 256))
			if n3 then table.insert(out, string.char(math.floor(n / 256) % 256)) end
			if n4 then table.insert(out, string.char(n % 256)) end
		end
		return table.concat(out)
	end

	function win:ListProfiles()
		local out = {}
		pcall(function()
			if not listfiles then return end
			for _, p in ipairs(listfiles("Atherium/Configs")) do
				local n = tostring(p):match("([^/\\]+)%.json$")
				if n then
					local size = 0
					pcall(function() size = #readfile("Atherium/Configs/" .. n .. ".json") end)
					table.insert(out, { name = n, size = size })
				end
			end
		end)
		table.sort(out, function(a, b) return string.lower(a.name) < string.lower(b.name) end)
		return out
	end

	function win:SaveProfile(name)
		if name == nil or tostring(name) == "" then return false end
		return win:SaveConfig(name, true)
	end

	function win:LoadProfile(name)
		if name == nil or tostring(name) == "" then return false end
		return win:LoadConfig(name)
	end

	function win:DeleteProfile(name)
		if name == nil or tostring(name) == "" then return false end
		return win:DeleteConfig(name)
	end

	function win:RenameProfile(oldName, newName)
		if oldName == nil or newName == nil then return false end
		local a, b = tostring(oldName), tostring(newName)
		if a == "" or b == "" or a == b then return false end
		local okRead, txt = pcall(function() return readfile(cfgPath(a)) end)
		if not okRead or type(txt) ~= "string" then return false end
		local okWrite = pcall(function() writefile(cfgPath(b), txt) end)
		if not okWrite then return false end
		pcall(function() delfile(cfgPath(a)) end)
		return true
	end

	-- portable snapshot: ATH1:<base64 json>, safe to paste in any chat client
	function win:ExportConfig()
		local ok, json = pcall(function() return game:GetService("HttpService"):JSONEncode(win:_configBlob()) end)
		if not ok or type(json) ~= "string" then return nil end
		return "ATH1:" .. b64encode(json)
	end

	function win:ImportConfig(code, quiet)
		if type(code) ~= "string" then return 0 end
		local body = code:gsub("%s+", ""):gsub("^ATH1:", "")
		if #body < 8 then return 0 end
		local ok, json = pcall(b64decode, body)
		if not ok or type(json) ~= "string" or #json < 2 then
			if not quiet then win:Notify("Profiles", "Share code is not valid", 4, "error") end
			return 0
		end
		local ok2, data = pcall(function() return game:GetService("HttpService"):JSONDecode(json) end)
		if not ok2 or type(data) ~= "table" then
			if not quiet then win:Notify("Profiles", "Share code has no config inside", 4, "error") end
			return 0
		end
		local n = win:_applyConfig(data)
		if not quiet then
			if n > 0 then
				win:Notify("Profiles", "Applied " .. tostring(n) .. " values", 4, "success")
			else
				win:Notify("Profiles", "Nothing matched this build", 4, "warn")
			end
		end
		return n
	end

	-- one stable entry point for external scripts: getgenv().Atherium
	-- legacy getgenv().AtheriumUI / AtheriumWin stay as aliases
	local function publish()
		pcall(function()
			local env = getgenv and getgenv()
			if type(env) ~= "table" then return end
			local api = env.Atherium
			if type(api) ~= "table" then
				api = {}
				env.Atherium = api
			end
			api.Version = VibeUI.Version
			api.UI = VibeUI
			api.Window = win
			api.Watermark = win._watermark
			env.AtheriumUI, env.AtheriumWin = VibeUI, win
			env.AhteriumUI, env.AhteriumWin = VibeUI, win
		end)
	end
	-- low-end safety: if the first seconds sit under 45 fps, drop the blur
	-- stack instead of letting the whole UI crawl
	if opts.AutoPerf ~= false then
		task.spawn(function()
			local frames, t0 = 0, os.clock()
			local samples, total = 0, 0
			local conn
			conn = RunService.RenderStepped:Connect(function()
				frames = frames + 1
			end)
			for _ = 1, 4 do
				task.wait(1)
				if not win._gui.Parent then break end
				local now = os.clock()
				local span = math.max(now - t0, 1e-3)
				total = total + frames / span
				samples = samples + 1
				frames, t0 = 0, now
			end
			if conn then pcall(function() conn:Disconnect() end) end
			if samples > 0 then
				local avg = total / samples
				if avg < 45 and win._acrylicOn then
					win:SetAcrylic(false)
					print(string.format("[ATHERIUM] auto-perf: %.0f fps, acrylic disabled", avg))
					pcall(function() win:Notify("Performance", "Blur off for smoother fps", 4) end)
				end
			end
		end)
	end

	win._publish = publish
	publish()
	return win
end

--// ================= DEMO =================
local function buildDemo()
	-- safety first: never destroy a GUI that holds the live character
	pcall(function() VibeUI.RescueCharacter() end)
	pcall(function()
		local ow = getgenv and (getgenv().AtheriumWin or getgenv().AhteriumWin)
		if ow and ow._destroyAcrylic then ow._destroyAcrylic() end
		local h = gethui and gethui()
		if h then for _, g in ipairs(h:GetChildren()) do if g.Name == "Atherium" or g.Name == "Ahterium" then g:Destroy() end end end
	end)
	pcall(function()
		for _, g in ipairs(LocalPlayer:WaitForChild("PlayerGui"):GetChildren()) do
			if g.Name == "Atherium" or g.Name == "Ahterium" then g:Destroy() end
		end
	end)

	local win = VibeUI:CreateWindow({ Title = "Atherium", Subtitle = "v11.2 acrylic", Autosave = true })

	local home = win:AddTab("Home", "house")
	local w = home:AddSection("General", "sparkles")
	w:AddLabel("Atherium base. Every control below is live.")
	w:AddButton({ Name = "Test Notification", Icon = "bell", Tooltip = "Shows all four notification kinds", Callback = function()
		win:Notify("Info", "Notifications now size themselves to the text.", 3.5, "info")
		win:Notify("Saved", "Config written to disk.", 3.5, "success")
		win:Notify("Warning", "Acrylic is off on this device.", 4, "warn")
		win:Notify("Error", "Load failed, check the console.", 4, "error")
	end })
	w:AddButton({ Name = "Print Hello", Icon = "zap", Callback = function()
		print("[ATHERIUM] hello from button")
	end })

	local social = home:AddSection("Community", "send")
	social:AddLabel("@AtheriumWIN - builds, previews and patch notes.")
	local TELEGRAM = "https://t.me/AtheriumWIN"
	local function openChannel(quiet)
		local how = VibeUI.OpenLink(TELEGRAM)
		if quiet then return how end
		if how == "browser" then
			win:Notify("Telegram", "Opened in your browser.", 3.5, "success")
		elseif how == "clipboard" then
			win:Notify("Telegram", "Link copied: t.me/AtheriumWIN", 4, "info")
		else
			win:Notify("Telegram", TELEGRAM, 5, "info")
		end
		return how
	end
	local socialL, socialR = social:AddColumns()
	socialL:AddButton({ Name = "Telegram", Icon = "send", Style = "dark", Height = 32, Tooltip = "t.me/AtheriumWIN", Callback = function()
		openChannel(false)
	end })
	socialR:AddButton({ Name = "TikTok", Icon = "music", Style = "dark", Height = 32, Tooltip = "Not live yet", Callback = function()
		win:Notify("TikTok", "Channel is not live yet - the Telegram has everything for now.", 4, "warn")
	end })

	local combat = win:AddTab("Combat", "swords")
	local tgt = combat:AddSection("Targeting", "crosshair")
	local tgtL, tgtR = tgt:AddColumns()
	local aimbotT = tgtL:AddToggle({ Name = "Enable Aimbot", Default = false, Callback = function(v) end })
	tgtL:AddToggle({ Name = "Team Check", Default = true, Tooltip = "Skips players on your own team", Callback = function(v) end })
	tgtL:AddToggle({ Name = "Wall Check", Default = true, Callback = function(v) end })
	tgtR:AddDropdown({ Name = "Aim Part", Options = { "Head", "Torso", "Random" }, Default = "Head", Callback = function(v) end })
	tgtR:AddKeybind({ Name = "Aim Key", Default = Enum.KeyCode.E, Toggle = aimbotT, Callback = function(k) end })
	local adj = combat:AddSection("Adjustments", "sliders-horizontal")
	local adjL, adjR = adj:AddColumns()
	adjL:AddSlider({ Name = "FOV Radius", Min = 10, Max = 400, Default = 120, Tooltip = "Radius of the target circle, in pixels", Callback = function(v) end })
	adjL:AddSlider({ Name = "Smoothness", Min = 1, Max = 30, Default = 8, Callback = function(v) end })
	adjR:AddColorPicker({ Name = "FOV Color", Default = Color3.fromRGB(255, 255, 255), Callback = function(c) end })
	adjR:AddDropdown({ Name = "Mode", Options = { "Legit", "Rage", "Silent" }, Default = "Legit", Callback = function(v) end })
	adjR:AddDropdown({
		Name = "Hit Parts",
		Options = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg", "Upper Torso", "Lower Torso" },
		Default = { "Head", "Torso" },
		Multiple = true,
		Tooltip = "Select any number of body parts",
		Callback = function(list) end,
	})

	local move = win:AddTab("Move", "wind")
	local m1 = move:AddSection("Movement", "gauge")
	m1:AddToggle({ Name = "Speed Hack", Default = false, Callback = function(v) end })
	local flyT = m1:AddToggle({ Name = "Fly", Default = false, Callback = function(v) end })
	m1:AddToggle({ Name = "Bunny Hop", Default = false, Callback = function(v) end })
	m1:AddSlider({ Name = "WalkSpeed", Min = 16, Max = 250, Default = 16, Callback = function(v) end })
	m1:AddSlider({ Name = "JumpPower", Min = 50, Max = 350, Default = 50, Callback = function(v) end })
	m1:AddKeybind({ Name = "Fly Key", Default = Enum.KeyCode.F, Toggle = flyT, Callback = function(k) end })

	local vis = win:AddTab("Visuals", "eye")
	local v1 = vis:AddSection("ESP", "eye")
	v1:AddToggle({ Name = "Box ESP", Default = false, Callback = function(v) end })
	v1:AddToggle({ Name = "Name ESP", Default = false, Callback = function(v) end })
	v1:AddToggle({ Name = "Health Bar", Default = true, Callback = function(v) end })
	v1:AddToggle({ Name = "Chams", Default = false, Callback = function(v) end })
	v1:AddSlider({ Name = "ESP Distance", Min = 100, Max = 5000, Default = 1500, Callback = function(v) end })
	v1:AddColorPicker({ Name = "ESP Color", Default = Color3.fromRGB(255, 255, 255), Callback = function(c) end })
	v1:AddKeybind({ Name = "ESP Toggle Key", Default = nil, Callback = function(k) end })
	local v2 = vis:AddSection("World", "globe")
	v2:AddToggle({ Name = "Fullbright", Default = false, Callback = function(v) end })
	v2:AddDropdown({ Name = "Sky", Options = { "Default", "Night", "Sunset", "Cyber" }, Default = "Default", Callback = function(v) end })
	local v3 = vis:AddSection("Preview", "eye")
	local vpDemo = v3:AddViewport({ Name = "Character", Height = 200 })
	vpDemo:SetPlayer()
	local stDemo = v3:AddChart({ Name = "Session", Type = "stat", Height = 86 })
	stDemo:SetValue(182, 12, "FPS right now")
	local barDemo = v3:AddChart({ Name = "Damage", Type = "bar", Height = 150, Colors = "mono",
		Data = { { label = "Mon", value = 12 }, { label = "Tue", value = 30 }, { label = "Wed", value = 18 }, { label = "Thu", value = 42 }, { label = "Fri", value = 27 } } })
	local donutDemo = v3:AddChart({ Name = "Loadout", Type = "donut", Height = 176, Colors = "mono",
		Data = { { label = "Rifles", value = 40 }, { label = "SMG", value = 25 }, { label = "Snipers", value = 20 }, { label = "Pistols", value = 15 } } })
	local grDemo = v3:AddChart({ Name = "FPS Live", Type = "graph", Height = 170,
		Colors = Color3.fromRGB(255, 255, 255) })
	grDemo:Stream(nil, 0.5)
	pcall(function()
		getgenv().AtheriumDemo = getgenv().AtheriumDemo or {}
		getgenv().AtheriumDemo.graph = grDemo
		getgenv().AtheriumDemo.viewport = vpDemo
	end)

	local cfg = win:AddTab("Config", "settings")
	local cfgs = cfg:AddSection("Configs", "save")
	local cfgName, cfgSel = "", ""
	local cfgList = nil
	local profileSummary = nil
	local function refreshCfgList()
		local names = win:ListConfigs()
		if #names == 0 then names = { "No configs" } end
		if cfgList then
			cfgList:SetOptions(names)
			cfgSel = tostring(cfgList:Get() or "")
		end
		if profileSummary then profileSummary() end
	end
	local cfgNameBox = cfgs:AddTextBox({ Name = "Name", Placeholder = "Config name...", NoSave = true, Callback = function(t) cfgName = tostring(t or "") end })
	cfgList = cfgs:AddDropdown({ Name = "List", Options = { "No configs" }, Default = "No configs", NoSave = true, Callback = function(v) cfgSel = tostring(v or "") if v ~= nil and v ~= "No configs" then win._activeCfg = tostring(v) end end })
	local colA, colB = cfgs:AddColumns()
	colA:AddButton({ Name = "Save", Icon = "save", Style = "dark", Height = 32, Callback = function()
		local raw = tostring(cfgNameBox:Get() or ""):gsub("^%s+", ""):gsub("%s+$", "")
		local n = (raw ~= "" and raw) or (cfgSel ~= "No configs" and cfgSel) or ""
		if n == "" or n == "No configs" then win:Notify("Config", "Enter a name first") return end
		if win:SaveConfig(n) then win._activeCfg = n cfgSel = n refreshCfgList() end
	end })
	colB:AddButton({ Name = "Load", Icon = "folder-open", Style = "dark", Height = 32, Callback = function()
		local raw = tostring(cfgNameBox:Get() or ""):gsub("^%s+", ""):gsub("%s+$", "")
		local n = (cfgSel ~= "" and cfgSel ~= "No configs" and cfgSel) or (raw ~= "" and raw) or ""
		if n == "" then win:Notify("Config", "Nothing to load") return end
		if win:LoadConfig(n) then win._activeCfg = n win:Notify("Config", "Loaded " .. n) else win:Notify("Config", "Load failed") end
	end })
	local colC, colD = cfgs:AddColumns()
	colC:AddButton({ Name = "Delete", Icon = "trash-2", Style = "dark", Height = 32, Callback = function()
		if cfgSel == "" or cfgSel == "No configs" then win:Notify("Config", "Nothing to delete") return end
		if win:DeleteConfig(cfgSel) then
			if win._activeCfg == cfgSel then win._activeCfg = nil end
			cfgSel = "" refreshCfgList()
		end
	end })
	colD:AddButton({ Name = "Refresh", Icon = "refresh-cw", Style = "dark", Height = 32, Callback = function() refreshCfgList() end })
	refreshCfgList()
	local share = cfg:AddSection("Profiles", "share-2")
	local shareBox = share:AddTextBox({ Name = "Share code", Placeholder = "paste ATH1:... here", NoSave = true })
	local shareInfo = share:AddLabel("Profiles are plain files in Atherium/Configs.")
	profileSummary = function()
		local list = win:ListProfiles()
		local total = 0
		for _, p in ipairs(list) do total = total + (p.size or 0) end
		shareInfo.Text = string.format("%d profiles, %.1f KB on disk", #list, total / 1024)
	end
	profileSummary()
	local sA, sB = share:AddColumns()
	sA:AddButton({ Name = "Export", Icon = "upload", Style = "dark", Height = 32, Tooltip = "Copies the whole layout as one ATH1 code", Callback = function()
		local code = win:ExportConfig()
		if not code then win:Notify("Profiles", "Export failed", 4, "error") return end
		shareBox:Set(code)
		if setclipboard then pcall(setclipboard, code) end
		win:Notify("Profiles", "Copied " .. tostring(#code) .. " chars", 4, "success")
	end })
	sB:AddButton({ Name = "Import", Icon = "download", Style = "dark", Height = 32, Tooltip = "Applies the code in the box", Callback = function()
		win:ImportConfig(shareBox:Get())
	end })
	local sC, sD = share:AddColumns()
	sC:AddButton({ Name = "Duplicate", Icon = "copy", Style = "dark", Height = 32, Tooltip = "Copies the selected profile", Callback = function()
		if cfgSel == "" or cfgSel == "No configs" then win:Notify("Profiles", "Pick a profile first", 4, "warn") return end
		local target = cfgSel .. " copy"
		if win:LoadConfig(cfgSel) and win:SaveProfile(target) then
			cfgSel = target
			refreshCfgList()
			win:Notify("Profiles", "Created " .. target, 4, "success")
		end
	end })
	sD:AddButton({ Name = "Rename", Icon = "pencil", Style = "dark", Height = 32, Tooltip = "Renames the selected profile to the name above", Callback = function()
		local raw = tostring(cfgNameBox:Get() or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if cfgSel == "" or cfgSel == "No configs" or raw == "" then win:Notify("Profiles", "Need a profile and a new name", 4, "warn") return end
		if win:RenameProfile(cfgSel, raw) then
			if win._activeCfg == cfgSel then win._activeCfg = raw end
			cfgSel = raw
			refreshCfgList()
			win:Notify("Profiles", "Renamed to " .. raw, 4, "success")
		end
	end })
	local c1 = cfg:AddSection("Interface", "settings")
	c1:AddToggle({ Name = "UI Sounds", Default = true, Callback = function(v) win._sounds = v end })
	c1:AddToggle({ Name = "Acrylic Blur", Default = true, Callback = function(v) win:SetAcrylic(v) end })
	c1:AddLabel("Acrylic needs Graphics Mode 8+.")
	c1:AddLabel("Theme lives in the Theme tab.")
	c1:AddButton({ Name = "Unload UI", Icon = "x", Callback = function() pcall(function() win:SaveConfig(win._activeCfg or "default", true) end) win._destroyAcrylic() win._gui:Destroy() end })

	local themeTab = win:AddTab("Theme", "palette")
	local tf = themeTab:AddSection("Interface Font", "type")
	tf:AddLabel("Cinematic apply: veil + loader, then reveal.")
	local fontDrop = tf:AddDropdown({ Name = "Font", Options = VibeUI.FontChoices(), Default = "Default", NoSave = true, Callback = function(v)
		win:SetThemeFont(v)
	end })
	local tc = themeTab:AddSection("Colors", "palette")
	tc:AddLabel("Accent paints toggles, sliders, checks, active icons.")
	local accPick = tc:AddColorPicker({ Name = "Accent", Default = Color3.fromRGB(255, 255, 255), NoSave = true, Callback = function(c)
		win:SetAccent(c)
	end })
	local txtPick = tc:AddColorPicker({ Name = "Text", Default = Color3.fromRGB(255, 255, 255), NoSave = true, Callback = function(c)
		win:SetTextColor(c)
	end })
	local subPick = tc:AddColorPicker({ Name = "Sub Text", Default = Color3.fromRGB(161, 161, 170), NoSave = true, Callback = function(c)
		win:SetSubColor(c)
	end })
	local tcol, tcol2 = tc:AddColumns()
	tcol:AddButton({ Name = "Reset", Icon = "refresh-cw", Style = "dark", Height = 32, Callback = function()
		win:ResetTheme()
	end })
	tcol2:AddButton({ Name = "Save Theme", Icon = "save", Style = "dark", Height = 32, Callback = function()
		if win:SaveConfig(win._activeCfg or "default") then win:Notify("Theme", "Saved to config") end
	end })
	win._refreshThemeControls = function()
		local th = win._theme
		pcall(function() fontDrop:Set(th.fontName or "Default", false) end)
		pcall(function() accPick:Set(th.accent or Color3.fromRGB(255, 255, 255)) end)
		pcall(function() txtPick:Set(th.text or Color3.fromRGB(255, 255, 255)) end)
		pcall(function() subPick:Set(th.sub or Color3.fromRGB(161, 161, 170)) end)
	end

	print("[ATHERIUM] demo v11.2 built")
	win:CreateKeyList()
	win:CreateWatermark()
	pcall(function() win:LoadConfig() end)

	-- one attempt per game session, so re-injecting does not spawn a browser
	-- every time; executors without a launcher just get the link on the clipboard
	pcall(function()
		local g = getgenv()
		if g and g.AtheriumLinkOpened then return end
		if g then g.AtheriumLinkOpened = true end
		local how = openChannel(true)
		if how == "browser" then
			win:Notify("Telegram", "Atherium window opened in your browser.", 5, "success")
		elseif how == "clipboard" then
			win:Notify("Telegram", "Link copied: t.me/AtheriumWIN", 6, "info")
		end
	end)
	return win
end

VibeUI._demo = buildDemo()

return VibeUI
