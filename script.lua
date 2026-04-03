-- LOAD UI
local Library = loadstring(game:HttpGet(
    "https://codeberg.org/VenomVent/Ventura-UI/raw/branch/main/VenturaLibrary.lua"
))()

-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

-- WINDOW
local GUI = Library:new({
    name = "Blox Hunt Hub V1.0",
    subtitle = "By Old Scripts",
    accent = Color3.fromRGB(110,160,255),
    toggleKey = Enum.KeyCode.Insert,
    minimizeKey = Enum.KeyCode.K,
    loadingTime = 0.5,
    keyEnabled = false
})

-- =========================
-- TABS
-- =========================

GUI:NavSection("MAIN")
local Seeker = GUI:CreateTab({ name = "Seeker", icon = "🎯" })

GUI:NavSection("HIDER")
local Hider = GUI:CreateTab({ name = "Hider", icon = "💤" })

GUI:NavSection("VISUAL")
local Visual = GUI:CreateTab({ name = "Visual", icon = "👁️" })

-- =========================
-- HITBOX SYSTEM
-- =========================

local hitboxEnabled = false
local hitboxSize = 10
local originalSizes = {}

Seeker:Slider({
    name = "Hitbox Hider",
    min = 1,
    max = 20,
    default = 10,
    callback = function(v)
        hitboxSize = v
    end
})

Seeker:Toggle({
    name = "Expand Hitbox",
    default = false,
    callback = function(v)
        hitboxEnabled = v

        if not v then
            for part, size in pairs(originalSizes) do
                if part and part.Parent then
                    part.Size = size
                    part.Transparency = 1
                end
            end
            originalSizes = {}
        end
    end
})

local function applyHitbox()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then

            local parts = plr.Character:FindFirstChild("CharacterParts")
            if parts then
                local obj = parts:FindFirstChild("ObjectModel")
                if obj then
                    local hitbox = obj:FindFirstChild("HitBox")

                    if hitbox and hitbox:IsA("BasePart") then
                        if not originalSizes[hitbox] then
                            originalSizes[hitbox] = hitbox.Size
                        end

                        hitbox.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
                        hitbox.Transparency = 0.5
                        hitbox.Color = Color3.fromRGB(255,0,0)
                    end
                end
            end
        end
    end
end

RunService.Heartbeat:Connect(function()
    if hitboxEnabled then
        applyHitbox()
    end
end)

-- =========================
-- AUTO ZAP BUTTON
-- =========================

Seeker:Button({
    name = "Auto Zap",
    callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Johndoe305/AutoZap/refs/heads/main/script.lua"))()
    end
})

-- =========================
-- TP JUMP SYSTEM
-- =========================

local UserInputService = game:GetService("UserInputService")
local tpJumpEnabled = false
local debounce = false
local DISTANCE = 10

local function doTeleport()
	if debounce then return end
	debounce = true

	local char = LP.Character
	if not char then return end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local forward = hrp.CFrame.LookVector
	local newPos = hrp.Position + (forward * DISTANCE)

	hrp.CFrame = CFrame.new(newPos)

	task.wait(0.2)
	debounce = false
end

-- CONEXÃO GLOBAL (fica rodando sempre)
UserInputService.JumpRequest:Connect(function()
	if tpJumpEnabled then
		doTeleport()
	end
end)

-- TOGGLE NA UI
Hider:Toggle({
	name = "TP Jump",
	description = "Teleport forward when jumping",
	default = false,
	callback = function(v)
		tpJumpEnabled = v
	end
})

-- =========================
-- WALL BOOST (HIDER)
-- =========================

local wallBoostEnabled = false
local debounce = false

-- CONFIG
local CLIMB_DURATION = 0.30
local UP_VELOCITY_TARGET = 400
local BACK_VELOCITY_TARGET = 120
local DETECT_DIST = 2.5
local MAX_BOOST_SPEED = 77
local WALL_JUMP_COOLDOWN = 0.25
local ACCELERATION_RATE = 1

local function wallBoost()
	if debounce then return end
	debounce = true

	local char = LP.Character
	if not char then debounce = false return end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then debounce = false return end

	-- RAYCAST
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {char}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local origin = hrp.Position
	local direction = hrp.CFrame.LookVector * DETECT_DIST
	local result = workspace:Raycast(origin, direction, raycastParams)

	if not result then
		debounce = false
		return
	end

	-- BOOST
	local originalState = humanoid:GetState()
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)

	local startTick = tick()
	while tick() - startTick < CLIMB_DURATION do
		local currentVelocity = hrp.AssemblyLinearVelocity
		local target = Vector3.new(0, UP_VELOCITY_TARGET, 0)

		hrp.AssemblyLinearVelocity = currentVelocity:Lerp(target, ACCELERATION_RATE)

		if hrp.AssemblyLinearVelocity.Magnitude > MAX_BOOST_SPEED then
			hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity.Unit * MAX_BOOST_SPEED
		end

		RunService.RenderStepped:Wait()
	end

	-- BACK PUSH
	local backDir = -hrp.CFrame.LookVector
	local targetBack = backDir * BACK_VELOCITY_TARGET + Vector3.new(0, UP_VELOCITY_TARGET/4, 0)

	local currentVelocity = hrp.AssemblyLinearVelocity
	hrp.AssemblyLinearVelocity = currentVelocity:Lerp(targetBack, ACCELERATION_RATE * 2)

	if hrp.AssemblyLinearVelocity.Magnitude > MAX_BOOST_SPEED then
		hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity.Unit * MAX_BOOST_SPEED
	end

	task.wait(0.3)
	humanoid:ChangeState(originalState)

	task.wait(WALL_JUMP_COOLDOWN)
	debounce = false
end

-- LOOP AUTOMÁTICO
RunService.RenderStepped:Connect(function()
	if wallBoostEnabled then
		wallBoost()
	end
end)

-- TOGGLE
Hider:Toggle({
	name = "Wall Boost",
	description = "Auto climb walls",
	default = false,
	callback = function(v)
		wallBoostEnabled = v
	end
})

-- =========================
-- ROLE ESP (HIDER / SEEKER)
-- =========================

local seekerESP = false
local hiderESP = false

local roleHighlights = {}

local function clearRoleESP()
    for char, hl in pairs(roleHighlights) do
        if hl then
            hl:Destroy()
        end
    end
    roleHighlights = {}
end

local function applyRoleESP()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then

            local data = plr:FindFirstChild("Player Data")
            local char = plr.Character

            if not data then continue end
            local role = data:FindFirstChild("Role")
            if not role then continue end

            -- evita duplicar
            if roleHighlights[char] then continue end

            -- lógica
            if role.Value == "Seeker" and seekerESP then
                local hl = Instance.new("Highlight")
                hl.FillColor = Color3.fromRGB(255,0,0)
                hl.FillTransparency = 0.3
                hl.OutlineTransparency = 0
                hl.Parent = char

                roleHighlights[char] = hl

            elseif role.Value == "Hider" and hiderESP then
                local hl = Instance.new("Highlight")
                hl.FillColor = Color3.fromRGB(0,170,255)
                hl.FillTransparency = 0.3
                hl.OutlineTransparency = 0
                hl.Parent = char

                roleHighlights[char] = hl
            end
        end
    end
end

-- LOOP
task.spawn(function()
    while task.wait(1) do
        if seekerESP or hiderESP then
            applyRoleESP()
        else
            clearRoleESP()
        end
    end
end)

-- TOGGLE SEEKER
Visual:Toggle({
    name = "Seeker ESP🔴",
    default = false,
    callback = function(v)
        seekerESP = v
        if not v then clearRoleESP() end
    end
})

-- TOGGLE HIDER
Visual:Toggle({
    name = "Hider ESP🔵",
    default = false,
    callback = function(v)
        hiderESP = v
        if not v then clearRoleESP() end
    end
})

-- =========================
-- LOADED
-- =========================

task.delay(1, function()
    GUI.notify("Blox Hunt", "Loaded successfully ⚡", 3)
end)
