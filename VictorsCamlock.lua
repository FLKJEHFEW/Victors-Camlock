--========================================================--
--                  VICTORS CAMLOCK                       --
--              External Developer Interface              --
--========================================================--

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--========================================================--
-- SETTINGS
--========================================================--

local Settings = {
	Camlock = false,
	Smoothness = 0.75,
	Prediction = 0.04,

	Highlight = true,
	HighlightColor = Color3.fromRGB(255,255,255),
	FillTransparency = 0.82,
	OutlineTransparency = 0.35,

	ESP = false,
	ESPColor = Color3.fromRGB(80,255,120),

	WalkSpeed = 16,
	JumpPower = 50,
	InfiniteJump = false,
	Noclip = false,

	HideKey = Enum.KeyCode.RightShift,
	UIVisible = true,
}

local target = nil
local highlight = nil
local camlockToggleButton = nil

--========================================================--
-- TARGET FINDER
--========================================================--

local function getClosest()
	local closest = nil
	local distance = math.huge
	local center = camera.ViewportSize / 2

	for _, p in Players:GetPlayers() do
		if p ~= player and p.Character then

			local humanoid =
				p.Character:FindFirstChildOfClass("Humanoid")

			local root =
				p.Character:FindFirstChild("HumanoidRootPart")

			if humanoid and humanoid.Health > 0 and root then

				local screenPos, visible =
					camera:WorldToViewportPoint(root.Position)

				if visible then

					local screenDistance =
						(Vector2.new(
							screenPos.X,
							screenPos.Y
						) - center).Magnitude

					if screenDistance < distance then
						distance = screenDistance
						closest = p
					end

				end
			end
		end
	end

	return closest
end

--========================================================--
-- HIGHLIGHT
--========================================================--

local function removeHighlight()

	if highlight then
		highlight:Destroy()
		highlight = nil
	end

end

local function addHighlight(character)

	removeHighlight()

	if not Settings.Highlight then
		return
	end

	highlight = Instance.new("Highlight")

	highlight.Name = "VictorsTargetHighlight"
	highlight.Adornee = character

	highlight.FillColor =
		Settings.HighlightColor

	highlight.FillTransparency =
		Settings.FillTransparency

	highlight.OutlineColor =
		Settings.HighlightColor

	highlight.OutlineTransparency =
		Settings.OutlineTransparency

	highlight.DepthMode =
		Enum.HighlightDepthMode.Occluded

	highlight.Parent = character

end

--========================================================--
-- CAMLOCK UI
--========================================================--

local function updateCamlockUI()

	if not camlockToggleButton then
		return
	end

	if Settings.Camlock then

		camlockToggleButton.BackgroundColor3 =
			Color3.fromRGB(70,205,125)

	else

		camlockToggleButton.BackgroundColor3 =
			Color3.fromRGB(38,41,49)

	end

end

--========================================================--
-- CAMLOCK
--========================================================--

local function unlockTarget()

	Settings.Camlock = false
	target = nil

	removeHighlight()
	updateCamlockUI()

end

local function lockTarget()

	target = getClosest()

	if target and target.Character then

		Settings.Camlock = true

		addHighlight(target.Character)

	else

		Settings.Camlock = false

	end

	updateCamlockUI()

end

local function toggleCamlock()

	if Settings.Camlock then
		unlockTarget()
	else
		lockTarget()
	end

end

--========================================================--
-- CAMLOCK KEY
--========================================================--

UIS.InputBegan:Connect(function(input, processed)

	if processed then
		return
	end

	if input.KeyCode == Enum.KeyCode.X then
		toggleCamlock()
	end

end)

--========================================================--
-- CAMERA TRACKING
--========================================================--

RunService.RenderStepped:Connect(function()

	if not Settings.Camlock or not target then
		return
	end

	local character =
		target.Character

	if not character then
		unlockTarget()
		return
	end

	local humanoid =
		character:FindFirstChildOfClass("Humanoid")

	local root =
		character:FindFirstChild("HumanoidRootPart")

	if not humanoid
		or humanoid.Health <= 0
		or not root then

		unlockTarget()
		return
	end

	local predictedPosition =
		root.Position +
		root.AssemblyLinearVelocity *
		Settings.Prediction

	local desired =
		CFrame.lookAt(
			camera.CFrame.Position,
			predictedPosition
		)

	camera.CFrame =
		camera.CFrame:Lerp(
			desired,
			Settings.Smoothness
		)

end)

--========================================================--
-- ESP COLORS
--========================================================--

local function getESPColor(p)

	local role =
		p:GetAttribute("Role")

	if role == "Murderer" then
		return Color3.fromRGB(255,70,70)
	end

	if role == "Sheriff" then
		return Color3.fromRGB(70,150,255)
	end

	if role == "Innocent" then
		return Color3.fromRGB(80,255,120)
	end

	if p.Team then

		local teamName =
			string.lower(p.Team.Name)

		if teamName == "murderer" then
			return Color3.fromRGB(255,70,70)
		elseif teamName == "sheriff" then
			return Color3.fromRGB(70,150,255)
		elseif teamName == "innocent" then
			return Color3.fromRGB(80,255,120)
		end

	end

	return Settings.ESPColor

end

--========================================================--
-- ESP
--========================================================--

local function removeESP(p)

	if not p.Character then
		return
	end

	local oldESP =
		p.Character:FindFirstChild("VictorsESP")

	if oldESP then
		oldESP:Destroy()
	end

	local oldName =
		p.Character:FindFirstChild("VictorsESPName")

	if oldName then
		oldName:Destroy()
	end

end

local function createESP(p)

	if p == player then
		return
	end

	local char =
		p.Character

	if not char then
		return
	end

	removeESP(p)

	if not Settings.ESP then
		return
	end

	local color =
		getESPColor(p)

	local esp =
		Instance.new("Highlight")

	esp.Name = "VictorsESP"
	esp.Adornee = char

	esp.FillColor = color
	esp.FillTransparency = 0.9

	esp.OutlineColor = color
	esp.OutlineTransparency = 0.15

	esp.DepthMode =
		Enum.HighlightDepthMode.AlwaysOnTop

	esp.Parent = char

	local root =
		char:FindFirstChild("Head")
		or char:FindFirstChild("HumanoidRootPart")

	if root then

		local billboard =
			Instance.new("BillboardGui")

		billboard.Name =
			"VictorsESPName"

		billboard.Adornee =
			root

		billboard.Size =
			UDim2.fromOffset(160,28)

		billboard.StudsOffset =
			Vector3.new(0,2.8,0)

		billboard.AlwaysOnTop = true
		billboard.MaxDistance = 500
		billboard.Parent = char

		local nameLabel =
			Instance.new("TextLabel")

		nameLabel.Size =
			UDim2.fromScale(1,1)

		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = p.DisplayName

		nameLabel.TextColor3 = color
		nameLabel.TextSize = 13

		nameLabel.Font =
			Enum.Font.GothamMedium

		nameLabel.TextStrokeTransparency = 0.5
		nameLabel.TextStrokeColor3 =
			Color3.fromRGB(0,0,0)

		nameLabel.Parent = billboard

	end

end

local function refreshESP()

	for _, p in Players:GetPlayers() do

		if p ~= player then
			createESP(p)
		end

	end

end

Players.PlayerAdded:Connect(function(p)

	p.CharacterAdded:Connect(function()

		task.wait(0.2)
		createESP(p)

	end)

	p:GetPropertyChangedSignal("Team"):Connect(function()
		createESP(p)
	end)

end)

for _, p in Players:GetPlayers() do

	if p ~= player then

		p.CharacterAdded:Connect(function()

			task.wait(0.2)
			createESP(p)

		end)

	end

end

--========================================================--
-- MOVEMENT
--========================================================--

local function getHumanoid()

	local character =
		player.Character

	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")

end

UIS.JumpRequest:Connect(function()

	if not Settings.InfiniteJump then
		return
	end

	local humanoid = getHumanoid()

	if humanoid then

		humanoid:ChangeState(
			Enum.HumanoidStateType.Jumping
		)

	end

end)

RunService.Stepped:Connect(function()

	local character =
		player.Character

	if not character then
		return
	end

	local humanoid =
		character:FindFirstChildOfClass("Humanoid")

	if humanoid then

		humanoid.WalkSpeed =
			Settings.WalkSpeed

		humanoid.JumpPower =
			Settings.JumpPower

	end

	if Settings.Noclip then

		for _, part in character:GetDescendants() do

			if part:IsA("BasePart") then
				part.CanCollide = false
			end

		end

	end

end)

--========================================================--
-- UI
--========================================================--

local gui =
	Instance.new("ScreenGui")

gui.Name =
	"VictorsCamlock"

gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent =
	player:WaitForChild("PlayerGui")

--========================================================--
-- MAIN WINDOW
--========================================================--

local main =
	Instance.new("Frame")

main.Name = "MainWindow"

main.Size =
	UDim2.fromOffset(660,445)

main.Position =
	UDim2.new(0.5,-330,0.5,-222)

main.BackgroundColor3 =
	Color3.fromRGB(12,14,18)

main.BorderSizePixel = 0
main.Parent = gui

local mainCorner =
	Instance.new("UICorner")

mainCorner.CornerRadius =
	UDim.new(0,16)

mainCorner.Parent = main

local mainStroke =
	Instance.new("UIStroke")

mainStroke.Color =
	Color3.fromRGB(55,60,72)

mainStroke.Thickness = 1
mainStroke.Transparency = 0.25
mainStroke.Parent = main

--========================================================--
-- HEADER
--========================================================--

local header =
	Instance.new("Frame")

header.Size =
	UDim2.new(1,0,0,72)

header.BackgroundColor3 =
	Color3.fromRGB(17,19,25)

header.BorderSizePixel = 0
header.Parent = main

local headerCorner =
	Instance.new("UICorner")

headerCorner.CornerRadius =
	UDim.new(0,16)

headerCorner.Parent = header

local title =
	Instance.new("TextLabel")

title.Size =
	UDim2.new(1,-50,0,30)

title.Position =
	UDim2.fromOffset(22,10)

title.BackgroundTransparency = 1

title.Text =
	"VICTORS CAMLOCK"

title.TextColor3 =
	Color3.fromRGB(245,247,250)

title.TextSize = 19
title.Font = Enum.Font.GothamBold
title.TextXAlignment =
	Enum.TextXAlignment.Left

title.Parent = header

local subtitle =
	Instance.new("TextLabel")

subtitle.Size =
	UDim2.new(1,-50,0,20)

subtitle.Position =
	UDim2.fromOffset(22,39)

subtitle.BackgroundTransparency = 1

subtitle.Text =
	"PRECISION CONTROL  •  VISUALS  •  MOVEMENT"

subtitle.TextColor3 =
	Color3.fromRGB(105,112,128)

subtitle.TextSize = 9
subtitle.Font = Enum.Font.GothamMedium

subtitle.TextXAlignment =
	Enum.TextXAlignment.Left

subtitle.Parent = header

local status =
	Instance.new("Frame")

status.Size =
	UDim2.fromOffset(8,8)

status.Position =
	UDim2.new(1,-27,0,17)

status.BackgroundColor3 =
	Color3.fromRGB(80,220,140)

status.BorderSizePixel = 0
status.Parent = header

local statusCorner =
	Instance.new("UICorner")

statusCorner.CornerRadius =
	UDim.new(1,0)

statusCorner.Parent = status

--========================================================--
-- SIDEBAR
--========================================================--

local sidebar =
	Instance.new("Frame")

sidebar.Size =
	UDim2.fromOffset(155,355)

sidebar.Position =
	UDim2.fromOffset(12,82)

sidebar.BackgroundColor3 =
	Color3.fromRGB(16,18,23)

sidebar.BorderSizePixel = 0
sidebar.Parent = main

local sidebarCorner =
	Instance.new("UICorner")

sidebarCorner.CornerRadius =
	UDim.new(0,11)

sidebarCorner.Parent = sidebar

local sideTitle =
	Instance.new("TextLabel")

sideTitle.Size =
	UDim2.new(1,-24,0,20)

sideTitle.Position =
	UDim2.fromOffset(12,12)

sideTitle.BackgroundTransparency = 1

sideTitle.Text =
	"CONTROL CENTER"

sideTitle.TextColor3 =
	Color3.fromRGB(85,92,108)

sideTitle.TextSize = 9
sideTitle.Font = Enum.Font.GothamBold

sideTitle.TextXAlignment =
	Enum.TextXAlignment.Left

sideTitle.Parent = sidebar

local function sidebarButton(text,y)

	local b =
		Instance.new("TextButton")

	b.Size =
		UDim2.new(1,-20,0,42)

	b.Position =
		UDim2.fromOffset(10,y)

	b.BackgroundColor3 =
		Color3.fromRGB(23,25,31)

	b.BorderSizePixel = 0

	b.Text = text

	b.TextColor3 =
		Color3.fromRGB(165,171,185)

	b.TextSize = 11
	b.Font = Enum.Font.GothamBold

	b.Parent = sidebar

	local c =
		Instance.new("UICorner")

	c.CornerRadius =
		UDim.new(0,8)

	c.Parent = b

	return b

end

local combatButton =
	sidebarButton("COMBAT",45)

local visualsButton =
	sidebarButton("VISUALS",95)

local movementButton =
	sidebarButton("MOVEMENT",145)

local uiButton =
	sidebarButton("UI SETTINGS",195)

--========================================================--
-- CONTENT
--========================================================--

local content =
	Instance.new("ScrollingFrame")

content.Size =
	UDim2.new(1,-182,1,-94)

content.Position =
	UDim2.fromOffset(174,84)

content.BackgroundTransparency = 1
content.BorderSizePixel = 0

content.ScrollBarThickness = 2

content.ScrollBarImageColor3 =
	Color3.fromRGB(75,82,98)

content.CanvasSize =
	UDim2.new()

content.Parent = main

local layout =
	Instance.new("UIListLayout")

layout.Padding =
	UDim.new(0,9)

layout.Parent = content

local padding =
	Instance.new("UIPadding")

padding.PaddingBottom =
	UDim.new(0,18)

padding.Parent = content

--========================================================--
-- CONTENT HELPERS
--========================================================--

local function clearContent()

	for _, child in content:GetChildren() do

		if not child:IsA("UIListLayout")
			and not child:IsA("UIPadding") then

			child:Destroy()

		end

	end

end

local function section(text)

	local label =
		Instance.new("TextLabel")

	label.Size =
		UDim2.new(1,-10,0,22)

	label.BackgroundTransparency = 1
	label.Text = text

	label.TextColor3 =
		Color3.fromRGB(86,94,112)

	label.TextSize = 9
	label.Font = Enum.Font.GothamBold

	label.TextXAlignment =
		Enum.TextXAlignment.Left

	label.Parent = content

end

--========================================================--
-- TOGGLE
--========================================================--

local function toggle(text,value,callback,keybind)

	local holder =
		Instance.new("Frame")

	holder.Size =
		UDim2.new(1,-10,0,43)

	holder.BackgroundColor3 =
		Color3.fromRGB(20,22,28)

	holder.BorderSizePixel = 0
	holder.Parent = content

	local c =
		Instance.new("UICorner")

	c.CornerRadius =
		UDim.new(0,9)

	c.Parent = holder

	local label =
		Instance.new("TextLabel")

	label.Size =
		UDim2.new(1,-105,1,0)

	label.Position =
		UDim2.fromOffset(13,0)

	label.BackgroundTransparency = 1
	label.Text = text

	label.TextColor3 =
		Color3.fromRGB(215,218,226)

	label.TextSize = 11
	label.Font = Enum.Font.GothamMedium

	label.TextXAlignment =
		Enum.TextXAlignment.Left

	label.Parent = holder

	if keybind then

		local keyLabel =
			Instance.new("TextLabel")

		keyLabel.Size =
			UDim2.fromOffset(38,20)

		keyLabel.Position =
			UDim2.new(1,-94,0.5,-10)

		keyLabel.BackgroundTransparency = 1

		keyLabel.Text =
			"("..keybind..")"

		keyLabel.TextColor3 =
			Color3.fromRGB(105,112,128)

		keyLabel.TextSize = 10
		keyLabel.Font = Enum.Font.GothamMedium
		keyLabel.Parent = holder

	end

	local button =
		Instance.new("TextButton")

	button.Size =
		UDim2.fromOffset(42,22)

	button.Position =
		UDim2.new(1,-54,0.5,-11)

	button.Text = ""
	button.BorderSizePixel = 0

	button.BackgroundColor3 =
		value
		and Color3.fromRGB(70,205,125)
		or Color3.fromRGB(38,41,49)

	button.Parent = holder

	local bc =
		Instance.new("UICorner")

	bc.CornerRadius =
		UDim.new(1,0)

	bc.Parent = button

	if keybind == "X" then
		camlockToggleButton = button
	end

	button.MouseButton1Click:Connect(function()

		value = not value

		button.BackgroundColor3 =
			value
			and Color3.fromRGB(70,205,125)
			or Color3.fromRGB(38,41,49)

		callback(value)

	end)

	return button

end

--========================================================--
-- SLIDER
--========================================================--

local function slider(text,min,max,value,callback,wholeNumber)

	local holder =
		Instance.new("Frame")

	holder.Size =
		UDim2.new(1,-10,0,62)

	holder.BackgroundColor3 =
		Color3.fromRGB(20,22,28)

	holder.BorderSizePixel = 0
	holder.Parent = content

	local c =
		Instance.new("UICorner")

	c.CornerRadius =
		UDim.new(0,9)

	c.Parent = holder

	local label =
		Instance.new("TextLabel")

	label.Size =
		UDim2.new(1,-24,0,25)

	label.Position =
		UDim2.fromOffset(12,4)

	label.BackgroundTransparency = 1

	label.Text =
		text.."  "..(
			wholeNumber
			and tostring(math.round(value))
			or string.format("%.2f",value)
		)

	label.TextColor3 =
		Color3.fromRGB(215,218,226)

	label.TextSize = 11
	label.Font = Enum.Font.GothamMedium

	label.TextXAlignment =
		Enum.TextXAlignment.Left

	label.Parent = holder

	local bar =
		Instance.new("Frame")

	bar.Size =
		UDim2.new(1,-24,0,5)

	bar.Position =
		UDim2.fromOffset(12,43)

	bar.BackgroundColor3 =
		Color3.fromRGB(40,43,51)

	bar.BorderSizePixel = 0
	bar.Parent = holder

	local bc =
		Instance.new("UICorner")

	bc.CornerRadius =
		UDim.new(1,0)

	bc.Parent = bar

	local fill =
		Instance.new("Frame")

	fill.Size =
		UDim2.new(
			(value-min)/(max-min),
			0,1,0
		)

	fill.BackgroundColor3 =
		Color3.fromRGB(80,210,140)

	fill.BorderSizePixel = 0
	fill.Parent = bar

	local fc =
		Instance.new("UICorner")

	fc.CornerRadius =
		UDim.new(1,0)

	fc.Parent = fill

	local dragging = false

	bar.InputBegan:Connect(function(input)

		if input.UserInputType ==
			Enum.UserInputType.MouseButton1 then

			dragging = true

		end

	end)

	UIS.InputEnded:Connect(function(input)

		if input.UserInputType ==
			Enum.UserInputType.MouseButton1 then

			dragging = false

		end

	end)

	UIS.InputChanged:Connect(function(input)

		if dragging
			and input.UserInputType ==
				Enum.UserInputType.MouseMovement then

			local pos =
				math.clamp(
					(
						input.Position.X -
						bar.AbsolutePosition.X
					) /
					bar.AbsoluteSize.X,
					0,1
				)

			local newValue =
				min + (max-min)*pos

			if wholeNumber then
				newValue =
					math.round(newValue)
			end

			local normalized =
				(newValue-min)/(max-min)

			fill.Size =
				UDim2.new(
					normalized,
					0,1,0
				)

			label.Text =
				text.."  "..(
					wholeNumber
					and tostring(newValue)
					or string.format("%.2f",newValue)
				)

			callback(newValue)

		end

	end)

end

--========================================================--
-- COMBAT TAB
--========================================================--

local function combatTab()

	clearContent()

	section("CAMLOCK")

	toggle(
		"Camlock",
		Settings.Camlock,
		function(v)

			if v then
				lockTarget()
			else
				unlockTarget()
			end

		end,
		"X"
	)

	slider(
		"Smoothness",
		0.02,
		1,
		Settings.Smoothness,
		function(v)
			Settings.Smoothness = v
		end,
		false
	)

	slider(
		"Prediction",
		0,
		1,
		Settings.Prediction,
		function(v)
			Settings.Prediction = v
		end,
		false
	)

	section("TARGET")

	toggle(
		"Target Highlight",
		Settings.Highlight,
		function(v)

			Settings.Highlight = v

			if target and target.Character then
				addHighlight(target.Character)
			end

		end
	)

end

--========================================================--
-- VISUALS TAB
--========================================================--

local function visualTab()

	clearContent()

	section("PLAYER ESP")

	toggle(
		"Enable ESP",
		Settings.ESP,
		function(v)

			Settings.ESP = v

			if v then

				refreshESP()

			else

				for _, p in Players:GetPlayers() do

					if p ~= player then
						removeESP(p)
					end

				end

			end

		end
	)

	section("ROLE COLORS")

	local info =
		Instance.new("TextLabel")

	info.Size =
		UDim2.new(1,-10,0,95)

	info.BackgroundColor3 =
		Color3.fromRGB(20,22,28)

	info.BorderSizePixel = 0

	info.Text =
		"ROLE IDENTIFICATION\n\n" ..
		"Murderer     RED\n" ..
		"Sheriff          BLUE\n" ..
		"Innocent       GREEN\n\n" ..
		"Other players use the custom ESP color."

	info.TextColor3 =
		Color3.fromRGB(175,181,193)

	info.TextSize = 11
	info.Font = Enum.Font.GothamMedium
	info.TextWrapped = true

	info.TextXAlignment =
		Enum.TextXAlignment.Left

	info.Parent = content

	local c =
		Instance.new("UICorner")

	c.CornerRadius =
		UDim.new(0,9)

	c.Parent = info

end

--========================================================--
-- MOVEMENT TAB
--========================================================--

local function movementTab()

	clearContent()

	section("MOVEMENT")

	slider(
		"WalkSpeed",
		8,
		200,
		Settings.WalkSpeed,
		function(v)

			Settings.WalkSpeed =
				math.clamp(
					math.round(v),
					8,200
				)

		end,
		true
	)

	slider(
		"JumpPower",
		25,
		150,
		Settings.JumpPower,
		function(v)

			Settings.JumpPower =
				math.round(v)

		end,
		true
	)

	toggle(
		"Infinite Jump",
		Settings.InfiniteJump,
		function(v)

			Settings.InfiniteJump = v

		end
	)

	toggle(
		"Noclip",
		Settings.Noclip,
		function(v)

			Settings.Noclip = v

		end
	)

end

--========================================================--
-- UI SETTINGS TAB
--========================================================--

local function uiSettingsTab()

	clearContent()

	section("INTERFACE")

	local keyHolder =
		Instance.new("Frame")

	keyHolder.Size =
		UDim2.new(1,-10,0,64)

	keyHolder.BackgroundColor3 =
		Color3.fromRGB(20,22,28)

	keyHolder.BorderSizePixel = 0
	keyHolder.Parent = content

	local corner =
		Instance.new("UICorner")

	corner.CornerRadius =
		UDim.new(0,9)

	corner.Parent = keyHolder

	local label =
		Instance.new("TextLabel")

	label.Size =
		UDim2.new(1,-145,0,25)

	label.Position =
		UDim2.fromOffset(13,7)

	label.BackgroundTransparency = 1

	label.Text =
		"Menu Visibility Key"

	label.TextColor3 =
		Color3.fromRGB(215,218,226)

	label.TextSize = 11
	label.Font = Enum.Font.GothamMedium

	label.TextXAlignment =
		Enum.TextXAlignment.Left

	label.Parent = keyHolder

	local sub =
		Instance.new("TextLabel")

	sub.Size =
		UDim2.new(1,-145,0,20)

	sub.Position =
		UDim2.fromOffset(13,31)

	sub.BackgroundTransparency = 1

	sub.Text =
		"Press the key to hide / reopen the menu"

	sub.TextColor3 =
		Color3.fromRGB(100,107,122)

	sub.TextSize = 9
	sub.Font = Enum.Font.Gotham

	sub.TextXAlignment =
		Enum.TextXAlignment.Left

	sub.Parent = keyHolder

	local keyButton =
		Instance.new("TextButton")

	keyButton.Size =
		UDim2.fromOffset(105,32)

	keyButton.Position =
		UDim2.new(1,-118,0.5,-16)

	keyButton.BackgroundColor3 =
		Color3.fromRGB(32,35,43)

	keyButton.BorderSizePixel = 0

	keyButton.Text =
		Settings.HideKey.Name

	keyButton.TextColor3 =
		Color3.fromRGB(220,225,235)

	keyButton.TextSize = 10
	keyButton.Font = Enum.Font.GothamBold

	keyButton.Parent = keyHolder

	local keyCorner =
		Instance.new("UICorner")

	keyCorner.CornerRadius =
		UDim.new(0,7)

	keyCorner.Parent = keyButton

	-- CURRENT KEY

	section("CURRENT KEY")

	local current =
		Instance.new("TextLabel")

	current.Size =
		UDim2.new(1,-10,0,45)

	current.BackgroundColor3 =
		Color3.fromRGB(18,20,25)

	current.BorderSizePixel = 0

	current.Text =
		"Menu toggle:  " ..
		Settings.HideKey.Name

	current.TextColor3 =
		Color3.fromRGB(130,138,154)

	current.TextSize = 10
	current.Font = Enum.Font.GothamMedium

	current.TextXAlignment =
		Enum.TextXAlignment.Left

	current.Parent = content

	local cc =
		Instance.new("UICorner")

	cc.CornerRadius =
		UDim.new(0,9)

	cc.Parent = current

	-- KEY LISTENING

	local listening = false

	keyButton.MouseButton1Click:Connect(function()

		listening = true

		keyButton.Text =
			"PRESS KEY..."

		keyButton.BackgroundColor3 =
			Color3.fromRGB(60,120,95)

	end)

	UIS.InputBegan:Connect(function(input, processed)

		if not listening then
			return
		end

		if processed then
			return
		end

		if input.UserInputType ==
			Enum.UserInputType.Keyboard then

			Settings.HideKey =
				input.KeyCode

			local newKey =
				input.KeyCode.Name

			-- Update button

			keyButton.Text =
				newKey

			keyButton.BackgroundColor3 =
				Color3.fromRGB(32,35,43)

			-- Update CURRENT KEY immediately

			current.Text =
				"Menu toggle:  " ..
				newKey

			listening = false

		end

	end)

end

--========================================================--
-- TAB CONNECTIONS
--========================================================--

combatButton.MouseButton1Click:Connect(
	combatTab
)

visualsButton.MouseButton1Click:Connect(
	visualTab
)

movementButton.MouseButton1Click:Connect(
	movementTab
)

uiButton.MouseButton1Click:Connect(
	uiSettingsTab
)

combatTab()

--========================================================--
-- MENU VISIBILITY
--========================================================--

UIS.InputBegan:Connect(function(input, processed)

	if processed then
		return
	end

	if input.KeyCode ==
		Settings.HideKey then

		Settings.UIVisible =
			not Settings.UIVisible

		main.Visible =
			Settings.UIVisible

	end

end)

--========================================================--
-- WINDOW DRAG
--========================================================--

local dragging = false
local dragStart
local startPosition

header.InputBegan:Connect(function(input)

	if input.UserInputType ==
		Enum.UserInputType.MouseButton1 then

		dragging = true
		dragStart = input.Position
		startPosition = main.Position

	end

end)

UIS.InputChanged:Connect(function(input)

	if dragging
		and input.UserInputType ==
			Enum.UserInputType.MouseMovement then

		local delta =
			input.Position - dragStart

		main.Position =
			UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			)

	end

end)

UIS.InputEnded:Connect(function(input)

	if input.UserInputType ==
		Enum.UserInputType.MouseButton1 then

		dragging = false

	end

end)

--========================================================--
-- INITIALIZE
--========================================================--

task.wait(0.5)

refreshESP()
updateCamlockUI()
