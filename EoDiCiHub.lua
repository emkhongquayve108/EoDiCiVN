local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- 1. Cấu hình trạng thái ESP và đồng bộ màu sắc hệ thống
local ESPConfig = {
    Enabled = false,
    Boxes = false,
    Lines = false,
    Skeleton = false,
    Health = false,
    Names = false,
    CountEnemy = false,
    Color = Color3.fromRGB(255, 255, 255) -- Màu sắc đồng bộ toàn bộ hệ thống ESP (Mặc định: Trắng)
}

-- 2. Tạo cửa sổ chính (tắt MinimizeKey để dùng nút ảo trên mobile)
local Window = Fluent:CreateWindow({
    Title = "EoDiCi Hub",
    SubTitle = "Duc Cuong Dep Trai",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 360),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = nil -- Đã tắt phím tắt để không phụ thuộc bàn phím vật lý
})

-- 3. Khởi tạo các Tab
local Tabs = {
    AIM = Window:AddTab({ Title = "AIM", Icon = "crosshair" }),
    ESP = Window:AddTab({ Title = "ESP", Icon = "eye" }),
    Other = Window:AddTab({ Title = "Other", Icon = "settings" })
}

-- ===== TAB AIM =====
local AIMEnabled = false
local AimbotActive = false
local FovRadius = 100

Tabs.AIM:AddToggle("MyToggle", {Title = "Enable Aim", Default = false}):OnChanged(function(Value)
    AIMEnabled = Value
    if Value then print("Đã bật Aim") else print("Đã tắt Aim") end
end)

Tabs.AIM:AddToggle("AimbotToggle", {Title = "Aimbot", Default = false}):OnChanged(function(Value)
    AimbotActive = Value
end)

Tabs.AIM:AddSlider("FovSlider", {
    Title = "FOV Radius",
    Default = 100,
    Min = 30,
    Max = 500,
    Rounding = 0
}):OnChanged(function(Value)
    FovRadius = Value
    if FovCircle then
        FovCircle.Radius = Value
    end
end)

-- ===== TAB ESP =====
Tabs.ESP:AddToggle("MainESP", {Title = "Enable ESP", Default = false}):OnChanged(function(Value) ESPConfig.Enabled = Value end)
Tabs.ESP:AddToggle("ESPBox", {Title = "ESP Box", Default = false}):OnChanged(function(Value) ESPConfig.Boxes = Value end)
Tabs.ESP:AddToggle("ESPLine", {Title = "ESP Line", Default = false}):OnChanged(function(Value) ESPConfig.Lines = Value end)
Tabs.ESP:AddToggle("ESPSkeleton", {Title = "ESP Skeleton", Default = false}):OnChanged(function(Value) ESPConfig.Skeleton = Value end)
Tabs.ESP:AddToggle("ESPHealth", {Title = "ESP Health", Default = false}):OnChanged(function(Value) ESPConfig.Health = Value end)
Tabs.ESP:AddToggle("ESPName", {Title = "ESP Name", Default = false}):OnChanged(function(Value) ESPConfig.Names = Value end)
Tabs.ESP:AddToggle("CountEnemyToggle", {Title = "Count Enemy", Default = false}):OnChanged(function(Value) ESPConfig.CountEnemy = Value end)

-- ===== TAB OTHER =====
local NoClipEnabled = false
Tabs.Other:AddToggle("NoClipToggle", {Title = "No Clip", Default = false}):OnChanged(function(Value)
    NoClipEnabled = Value
end)

Fluent:Notify({ Title = "EoDiCi Hub", Content = "Menu đã tải thành công!", Duration = 5 })

----------------------------------------------------------------===
-- HỆ THỐNG ĐẾM FPS VÀ ĐỔI CHỮ TIÊU ĐỀ
----------------------------------------------------------------===
local RunService = game:GetService("RunService")
local FPS, FrameCount, LastUpdate = 0, 0, os.clock()

RunService.RenderStepped:Connect(function()
    FrameCount = FrameCount + 1
    local Now = os.clock()
    if Now - LastUpdate >= 1 then
        FPS = FrameCount
        FrameCount = 0
        LastUpdate = Now
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if Window and Window.Root then
                for _, object in pairs(Window.Root:GetDescendants()) do
                    if object:IsA("TextLabel") and (object.Text == "EoDiCi Hub" or string.find(object.Text, "FPS:")) then
                        object.Text = "EoDiCi Hub | FPS: " .. tostring(FPS)
                    end
                end
            end
        end)
    end
end)

----------------------------------------------------------------===
-- LẬP TRÌNH KỸ THUẬT ĐỒ HỌA ESP TOÀN DIỆN (ĐÃ TỐI ƯU HÓA)
----------------------------------------------------------------===
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local ESPCache = {}

local EnemyCounter = Drawing.new("Text")
EnemyCounter.Visible = false
EnemyCounter.Color = ESPConfig.Color
EnemyCounter.Size = 20
EnemyCounter.Center = true
EnemyCounter.Outline = true
EnemyCounter.OutlineColor = Color3.fromRGB(0, 0, 0)

-- Vòng tròn hiển thị FOV của Aimbot
local FovCircle = Drawing.new("Circle")
FovCircle.Visible = false
FovCircle.Color = ESPConfig.Color
FovCircle.Thickness = 1
FovCircle.Filled = false
FovCircle.Radius = FovRadius
FovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

local function CreateESP(player)
    if player == LocalPlayer then return end

    local Box = Drawing.new("Square")
    Box.Visible = false
    Box.Thickness = 1
    Box.Filled = false
    Box.Color = ESPConfig.Color

    local Line = Drawing.new("Line")
    Line.Visible = false
    Line.Thickness = 1
    Line.Color = ESPConfig.Color

    local HealthBarBg = Drawing.new("Line")
    HealthBarBg.Visible = false
    HealthBarBg.Color = Color3.fromRGB(0, 0, 0)
    HealthBarBg.Thickness = 8

    local HealthBar = Drawing.new("Line")
    HealthBar.Visible = false
    HealthBar.Thickness = 8

    local NameTag = Drawing.new("Text")
    NameTag.Visible = false
    NameTag.Size = 13
    NameTag.Center = true
    NameTag.Outline = true
    NameTag.OutlineColor = Color3.fromRGB(0, 0, 0)
    NameTag.Color = ESPConfig.Color

    local SkeletonLines = {}
    for i = 1, 12 do
        local SLine = Drawing.new("Line")
        SLine.Visible = false
        SLine.Thickness = 1
        SLine.Color = ESPConfig.Color
        table.insert(SkeletonLines, SLine)
    end

    ESPCache[player] = {
        Box = Box, Line = Line, Skeleton = SkeletonLines,
        HealthBarBg = HealthBarBg, HealthBar = HealthBar, NameTag = NameTag
    }
end

local function RemoveESP(player)
    if ESPCache[player] then
        ESPCache[player].Box:Remove()
        ESPCache[player].Line:Remove()
        ESPCache[player].HealthBarBg:Remove()
        ESPCache[player].HealthBar:Remove()
        ESPCache[player].NameTag:Remove()
        for _, sLine in pairs(ESPCache[player].Skeleton) do sLine:Remove() end
        ESPCache[player] = nil
    end
end

for _, player in pairs(Players:GetPlayers()) do CreateESP(player) end
Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)

RunService.RenderStepped:Connect(function()
    -- Hiển thị vòng tròn FOV khi Enable Aim + Aimbot được bật
    if AIMEnabled and AimbotActive then
        FovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FovCircle.Radius = FovRadius
        FovCircle.Visible = true
    else
        FovCircle.Visible = false
    end

    -- Logic Aimbot
    if AIMEnabled and AimbotActive then
        local closestTarget = nil
        local shortestDist = FovRadius
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local char = player.Character
                local hum = char and char:FindFirstChild("Humanoid")
                local head = char and char:FindFirstChild("Head")
                if hum and hum.Health > 0 and head then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
                        if dist <= shortestDist then
                            shortestDist = dist
                            closestTarget = head
                        end
                    end
                end
            end
        end
        if closestTarget then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, closestTarget.Position), 0.3)
        end
    end

    local ActiveEnemies = 0

    for player, drawing in pairs(ESPCache) do
        local Box, Line, Skeleton = drawing.Box, drawing.Line, drawing.Skeleton
        local HealthBarBg, HealthBar, NameTag = drawing.HealthBarBg, drawing.HealthBar, drawing.NameTag

        local Char = player.Character
        local Hum = Char and Char:FindFirstChild("Humanoid")
        local RootPart = Char and Char:FindFirstChild("HumanoidRootPart")
        local Head = Char and Char:FindFirstChild("Head")

        local IsRendered = false

        if ESPConfig.Enabled and Hum and Hum.Health > 0 and RootPart and Head then
            local Position, OnScreen = Camera:WorldToViewportPoint(RootPart.Position)
            local TopHeadPosition, TopHeadOnScreen = Camera:WorldToViewportPoint(Head.Position + Vector3.new(0, 0.5, 0))

            if OnScreen or TopHeadOnScreen then
                IsRendered = true
                ActiveEnemies = ActiveEnemies + 1

                local LegPosition = Camera:WorldToViewportPoint(RootPart.Position - Vector3.new(0, 3, 0))
                local Height = math.abs(TopHeadPosition.Y - LegPosition.Y)
                local Width = Height * 0.6
                local BoxPosX = Position.X - Width / 2
                local BoxPosY = TopHeadPosition.Y

                -- ESP Box
                if ESPConfig.Boxes then
                    Box.Size = Vector2.new(Width, Height)
                    Box.Position = Vector2.new(BoxPosX, BoxPosY)
                    Box.Visible = true
                else
                    Box.Visible = false
                end

                -- ESP Line
                if ESPConfig.Lines then
                    Line.From = Vector2.new(Camera.ViewportSize.X / 2, 0)
                    Line.To = Vector2.new(TopHeadPosition.X, TopHeadPosition.Y)
                    Line.Visible = true
                else
                    Line.Visible = false
                end

                -- ESP Health
                if ESPConfig.Health then
                    local HealthPercent = Hum.Health / Hum.MaxHealth
                    local BarHeight = Height * HealthPercent

                    if HealthPercent > 0.66 then
                        HealthBar.Color = Color3.fromRGB(0, 255, 0)
                    elseif HealthPercent > 0.33 then
                        HealthBar.Color = Color3.fromRGB(255, 255, 0)
                    else
                        HealthBar.Color = Color3.fromRGB(255, 0, 0)
                    end

                    local BarX = BoxPosX - 10

                    HealthBarBg.From = Vector2.new(BarX, BoxPosY + Height)
                    HealthBarBg.To = Vector2.new(BarX, BoxPosY)
                    HealthBarBg.Visible = true

                    HealthBar.From = Vector2.new(BarX, BoxPosY + Height)
                    HealthBar.To = Vector2.new(BarX, (BoxPosY + Height) - BarHeight)
                    HealthBar.Visible = true
                else
                    HealthBarBg.Visible = false
                    HealthBar.Visible = false
                end

                -- ESP Name
                if ESPConfig.Names then
                    NameTag.Text = player.Name
                    NameTag.Position = Vector2.new(Position.X, BoxPosY + Height + 4)
                    NameTag.Visible = true
                else
                    NameTag.Visible = false
                end

                -- ESP Skeleton
                if ESPConfig.Skeleton then
                    local RigPairs = Char:FindFirstChild("UpperTorso") and {
                        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
                        {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"},
                        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"},
                        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"},
                        {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}
                    } or {
                        {"Head", "Torso"},
                        {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
                        {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
                    }

                    for i, joints in ipairs(RigPairs) do
                        local Part1, Part2 = Char:FindFirstChild(joints[1]), Char:FindFirstChild(joints[2])
                        if Part1 and Part2 then
                            local Pos1, V1 = Camera:WorldToViewportPoint(Part1.Position)
                            local Pos2, V2 = Camera:WorldToViewportPoint(Part2.Position)
                            if V1 and V2 then
                                Skeleton[i].From = Vector2.new(Pos1.X, Pos1.Y)
                                Skeleton[i].To = Vector2.new(Pos2.X, Pos2.Y)
                                Skeleton[i].Visible = true
                            else
                                Skeleton[i].Visible = false
                            end
                        else
                            Skeleton[i].Visible = false
                        end
                    end
                    for i = #RigPairs + 1, #Skeleton do
                        Skeleton[i].Visible = false
                    end
                else
                    for _, sLine in pairs(Skeleton) do
                        sLine.Visible = false
                    end
                end
            end
        end

        if not IsRendered then
            Box.Visible = false
            Line.Visible = false
            HealthBarBg.Visible = false
            HealthBar.Visible = false
            NameTag.Visible = false
            for _, sLine in pairs(Skeleton) do
                sLine.Visible = false
            end
        end
    end

    -- Cập nhật số lượng địch
    if ESPConfig.Enabled and ESPConfig.CountEnemy then
        EnemyCounter.Text = "Enemy: " .. tostring(ActiveEnemies)
        EnemyCounter.Position = Vector2.new(Camera.ViewportSize.X / 2, 40)
        EnemyCounter.Visible = true
    else
        EnemyCounter.Visible = false
    end
end)

-- ===== NO CLIP LOGIC =====
RunService.Stepped:Connect(function()
    if NoClipEnabled and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- ===== NÚT TOGGLE MENU CHO ĐIỆN THOẠI (CHỮ "LDC" & DI CHUYỂN TỰ DO) =====
local UserInputService = game:GetService("UserInputService")

local function createMobileToggle()
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "MobileMenuToggle"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = PlayerGui

    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0, 60, 0, 40) -- Rộng hơn một chút để chứa chữ
    ToggleButton.Position = UDim2.new(1, -70, 0, 10) -- Góc phải trên
    ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    ToggleButton.BackgroundTransparency = 0.4
    ToggleButton.Text = "LDC"
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.TextScaled = true
    ToggleButton.Font = Enum.Font.SourceSansBold
    ToggleButton.ZIndex = 10
    ToggleButton.Parent = ScreenGui

    -- Bo góc cho đẹp
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = ToggleButton

    -- Chỉ hiện trên thiết bị cảm ứng & không có bàn phím vật lý
    ToggleButton.Visible = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

    -- Cập nhật trạng thái hiển thị khi loại thiết bị đầu vào thay đổi
    UserInputService.LastInputTypeChanged:Connect(function(lastInputType)
        if lastInputType == Enum.UserInputType.Touch then
            ToggleButton.Visible = true
        elseif lastInputType == Enum.UserInputType.Keyboard then
            ToggleButton.Visible = false
        end
    end)

    -- Logic kéo thả + phân biệt tap
    local UIS = UserInputService
    local dragging = false
    local dragStartPos = nil
    local startButtonPos = nil
    local dragThreshold = 5 -- pixel, dưới mức này coi là tap

    ToggleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStartPos = input.Position
            startButtonPos = ToggleButton.Position
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStartPos
            -- Cập nhật vị trí nút (theo offset pixel)
            ToggleButton.Position = UDim2.new(
                startButtonPos.X.Scale,
                startButtonPos.X.Offset + delta.X,
                startButtonPos.Y.Scale,
                startButtonPos.Y.Offset + delta.Y
            )
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                local delta = (input.Position - dragStartPos).Magnitude
                if delta <= dragThreshold then
                    -- Tap: Toggle menu
                    if Window and Window.Root then
                        Window.Root.Visible = not Window.Root.Visible
                    end
                end
                dragging = false
            end
        end
    end)
end

-- Chạy an toàn
pcall(createMobileToggle)