game:GetService("StarterGui"):SetCore("SendNotification",{
Title = "Summer Hub",
Text = "please follow my tiktok", 
Duration = 5
})

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local localplayer = Players.LocalPlayer

local tweenSpeed = 15
local layUndergroundOffset = 3.7

local farmMode = nil
local autoFarm = false
local autoResetEnabled = false
local avoidMurderCoins = false
local waitInLobbyEnabled = false
local deadUntilNextRound = false
local visitedCoins = {}
local activeTween = nil
local humanoidDiedConn = nil
local waitingForNewMap = false
local farmLoopRunning = false
local isSpectatingMidRound = false
local antiFlingConnection = nil
local flingMurderEnabled = false
local autoShootMurderEnabled = false
local killAllEnabled = false
local flingLoopActive = false
local shootLoopActive = false
local roundHadCoins = false -- true only once coins were actually seen this round

-- Underground (Valentine-style) state
local valFloatPart = nil
local valHeartbeatConn = nil
local valLoopActive = false
local valFirstCoin = true

-- Lay state
local layPlatform = nil
local layHeartbeatConn = nil
local layTween = nil
local layLoopActive = false
local layFirstCoin = true

local LOBBY_POSITION = CFrame.new(629.1, 482.7, 37.5)

-- Safe mode settings
local SAFE_WAIT_TIME = 1.9      -- seconds to wait at the safe coordinates between coins
local SAFE_TOUCH_TIMEOUT = 1    -- max seconds spent touching one coin before giving up
local SAFE_POSITION = Vector3.new(-28.3, 338.6, -115.7) -- where Safe mode waits between coins

local function getActiveMap()
    for _, child in pairs(Workspace:GetChildren()) do
        if child:GetAttribute("MapID") then
            return child
        end
    end
    return nil
end

local function getCoinContainer()
    local map = getActiveMap()
    if not map then return nil end
    return map:FindFirstChild("CoinContainer")
end

local function isCoinCollectable(coin)
    if not coin or not coin.Parent then return false end
    if not coin:IsA("BasePart") then return false end
    -- Removed CoinID requirement so candy and other collectibles work.
    local collected = coin:GetAttribute("Collected")
    if collected then return false end
    local coinVisual = coin:FindFirstChild("CoinVisual")
    if not coinVisual then return false end
    local mainCoin = coinVisual:FindFirstChild("MainCoin")
    if not mainCoin then
        -- Fallback: accept if visual exists and is visible
        return coinVisual:IsA("BasePart") and coinVisual.Transparency == 0
    end
    if mainCoin.Transparency ~= 0 then return false end
    return true
end

-- Returns the part we should actually tween to (the visible coin/candy)
local function getCoinVisualPart(coin)
    if not coin then return nil end
    local coinVisual = coin:FindFirstChild("CoinVisual")
    if not coinVisual then return coin end
    local mainCoin = coinVisual:FindFirstChild("MainCoin")
    if mainCoin then return mainCoin end
    if coinVisual:IsA("BasePart") then return coinVisual end
    return coin
end

local function SkidFling(TargetPlayer)
    local Player = localplayer
    local Character = Player.Character
    if not Character then return end
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    if not Humanoid or not RootPart then return end
    local TCharacter = TargetPlayer.Character
    if not TCharacter then return end
    local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    if not THumanoid then return end
    local TRootPart = THumanoid.RootPart
    local THead = TCharacter:FindFirstChild("Head")
    local Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    local Handle = Accessory and Accessory:FindFirstChild("Handle")
    if not TRootPart and not THead and not Handle then return end
    if RootPart.Velocity.Magnitude < 50 then
        getgenv().OldPos = RootPart.CFrame
    end
    if THumanoid and THumanoid.Sit then
        return
    end
    if THead then
        workspace.CurrentCamera.CameraSubject = THead
    elseif Handle then
        workspace.CurrentCamera.CameraSubject = Handle
    elseif THumanoid and TRootPart then
        workspace.CurrentCamera.CameraSubject = THumanoid
    end
    if not TCharacter:FindFirstChildWhichIsA("BasePart") then
        return
    end
    local FPos = function(BasePart, Pos, Ang)
        RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
        Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
        RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
        RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
    end
    local SFBasePart = function(BasePart)
        local TimeToWait = 2
        local Time = tick()
        local Angle = 0
        repeat
            if RootPart and THumanoid then
                if BasePart.Velocity.Magnitude < 50 then
                    Angle = Angle + 100
                    FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle),0 ,0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                else
                    FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                    task.wait()
                end
            end
        until Time + TimeToWait < tick()
    end
    workspace.FallenPartsDestroyHeight = 0/0
    local BV = Instance.new("BodyVelocity")
    BV.Parent = RootPart
    BV.Velocity = Vector3.new(0, 0, 0)
    BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
    if TRootPart then
        SFBasePart(TRootPart)
    elseif THead then
        SFBasePart(THead)
    elseif Handle then
        SFBasePart(Handle)
    else
        BV:Destroy()
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        return
    end
    BV:Destroy()
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    workspace.CurrentCamera.CameraSubject = Humanoid
    if getgenv().OldPos then
        repeat
            RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
            Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
            Humanoid:ChangeState("GettingUp")
            for _, part in pairs(Character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.Velocity, part.RotVelocity = Vector3.new(), Vector3.new()
                end
            end
            task.wait()
        until (RootPart.Position - getgenv().OldPos.p).Magnitude < 25
    end
end

local function tpShootMurderer()
    local player = localplayer
    local character = player.Character
    if not character then return false end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    local gun = nil
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") and tool.Name == "Gun" then
            gun = tool
            break
        end
    end
    if not gun then
        for _, tool in ipairs(player.Backpack:GetChildren()) do
            if tool:IsA("Tool") and tool.Name == "Gun" then
                gun = tool
                break
            end
        end
    end
    if not gun then return false end
    local murderer = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            local hasKnife = false
            if p.Backpack and p.Backpack:FindFirstChild("Knife") then
                hasKnife = true
            end
            if not hasKnife and p.Character and p.Character:FindFirstChild("Knife") then
                hasKnife = true
            end
            if hasKnife then
                murderer = p
                break
            end
        end
    end
    if not murderer then return false end
    local murderChar = murderer.Character
    if not murderChar then return false end
    local murderHRP = murderChar:FindFirstChild("HumanoidRootPart")
    if not murderHRP then return false end
    local murderHumanoid = murderChar:FindFirstChildOfClass("Humanoid")
    if not murderHumanoid or murderHumanoid.Health <= 0 then return false end
    local savedPos = hrp.CFrame
    local teleportPos = murderHRP.CFrame * CFrame.new(0, 0, 3)
    hrp.CFrame = teleportPos
    task.wait(0.05)
    if gun.Parent ~= character then
        humanoid:EquipTool(gun)
        task.wait(0.15)
    end
    local success = false
    pcall(function()
        local shootEvent = gun:FindFirstChild("Shoot")
        if shootEvent then
            local velocity = murderHRP.Velocity
            local predictedPos = murderHRP.Position + (velocity * 0.12)
            local rightHand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
            if rightHand then
                shootEvent:FireServer(CFrame.new(rightHand.Position), CFrame.new(predictedPos))
                success = true
            else
                shootEvent:FireServer(CFrame.new(hrp.Position + Vector3.new(0, 3, 0)), CFrame.new(predictedPos))
                success = true
            end
        else
            local remote = ReplicatedStorage:FindFirstChild("Shoot") or ReplicatedStorage:FindFirstChild("Fire")
            if remote then
                remote:FireServer(CFrame.new(hrp.Position), CFrame.new(murderHRP.Position))
                success = true
            end
        end
    end)
    task.wait(0.1)
    hrp.CFrame = LOBBY_POSITION
    task.delay(0.3, function()
        pcall(function() humanoid:UnequipTools() end)
    end)
    return success
end

local function killEveryone()
    local plr = localplayer
    local char = plr.Character
    if not char then return end
    local knife = nil
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            knife = tool
            break
        end
    end
    if not knife then
        for _, tool in ipairs(plr.Backpack:GetChildren()) do
            if tool:IsA("Tool") then
                knife = tool
                break
            end
        end
        if knife then
            knife.Parent = char
            task.wait(0.2)
            knife = char:FindFirstChildOfClass("Tool")
        end
    end
    if not knife then
        return false
    end
    local killedCount = 0
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= plr and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP and humanoid and humanoid.Health > 0 then
                pcall(function()
                    knife:Activate()
                    firetouchinterest(targetHRP, knife.Handle, 0)
                    firetouchinterest(targetHRP, knife.Handle, 1)
                    killedCount = killedCount + 1
                end)
                task.wait(0.1)
            end
        end
    end
    return true
end

local function hasGun()
    local char = localplayer.Character
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") and tool.Name == "Gun" then
                return true
            end
        end
    end
    if localplayer.Backpack then
        for _, tool in ipairs(localplayer.Backpack:GetChildren()) do
            if tool:IsA("Tool") and tool.Name == "Gun" then
                return true
            end
        end
    end
    return false
end

local function hasKnife()
    local char = localplayer.Character
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name == "Knife" or tool.Name:find("Knife")) then
                return true
            end
        end
    end
    if localplayer.Backpack then
        for _, tool in ipairs(localplayer.Backpack:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name == "Knife" or tool.Name:find("Knife")) then
                return true
            end
        end
    end
    return false
end

local function flingMurdererLoop()
    if flingLoopActive then return end
    flingLoopActive = true
    while flingMurderEnabled and autoFarm do
        if hasGun() or hasKnife() then
            break
        end
        local murderer = nil
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= localplayer then
                local hasKnife = false
                if p.Backpack and p.Backpack:FindFirstChild("Knife") then
                    hasKnife = true
                end
                if not hasKnife and p.Character and p.Character:FindFirstChild("Knife") then
                    hasKnife = true
                end
                if hasKnife then
                    murderer = p
                    break
                end
            end
        end
        if not murderer or not murderer.Character then
            break
        end
        local murderHumanoid = murderer.Character:FindFirstChildOfClass("Humanoid")
        if not murderHumanoid or murderHumanoid.Health <= 0 then
            break
        end
        local char = localplayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local murderHRP = murderer.Character:FindFirstChild("HumanoidRootPart")
                if murderHRP then
                    hrp.CFrame = murderHRP.CFrame * CFrame.new(0, 0, 3)
                end
            end
        end
        task.wait(0.1)
        pcall(function()
            SkidFling(murderer)
        end)
        task.wait(0.05)
        if not murderHumanoid.Parent or murderHumanoid.Health <= 0 then
            break
        end
    end
    flingLoopActive = false
end

local function autoShootMurdererLoop()
    if shootLoopActive then return end
    shootLoopActive = true
    while autoShootMurderEnabled and autoFarm do
        if not hasGun() then
            task.wait(2)
            continue
        end
        local murderer = nil
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= localplayer then
                local hasKnife = false
                if p.Backpack and p.Backpack:FindFirstChild("Knife") then
                    hasKnife = true
                end
                if not hasKnife and p.Character and p.Character:FindFirstChild("Knife") then
                    hasKnife = true
                end
                if hasKnife then
                    murderer = p
                    break
                end
            end
        end
        if not murderer then
            task.wait(2)
            continue
        end
        if not murderer.Character then
            task.wait(2)
            continue
        end
        local murderHumanoid = murderer.Character:FindFirstChildOfClass("Humanoid")
        if not murderHumanoid or murderHumanoid.Health <= 0 then
            break
        end
        local success = tpShootMurderer()
        if success then
            task.wait(0.8)
            if not murderer.Character or not murderer.Character:FindFirstChildOfClass("Humanoid") or 
               murderer.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then
                break
            end
        end
        task.wait(3)
    end
    shootLoopActive = false
end

local function enableAntiFling()
    if antiFlingConnection then return end
    local speaker = localplayer
    antiFlingConnection = RunService.PreSimulation:Connect(function()
        if not autoFarm then return end
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= speaker and player.Character then
                for _, v in pairs(player.Character:GetDescendants()) do
                    if v:IsA("BasePart") then v.CanCollide = false end
                end
            end
        end
    end)
end

local function disableAntiFling()
    if antiFlingConnection then antiFlingConnection:Disconnect(); antiFlingConnection = nil end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localplayer and player.Character then
            for _, v in pairs(player.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = true end
            end
        end
    end
end

local function cancelActiveTween()
    if activeTween then pcall(function() activeTween:Cancel() end); activeTween = nil end
end

local function anchorHRP(hrp, state)
    if hrp then hrp.Anchored = state end
end

local function forceServerSync(char)
    if char and char.PrimaryPart then
        char:PivotTo(CFrame.new(char.PrimaryPart.Position))
        char.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
    end
end

local MURDERER_DANGER_RADIUS = 20
local function getMurdererHRP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == localplayer then continue end
        local char = player.Character
        if not char then continue end
        local hasKnife = char:FindFirstChild("Knife") ~= nil
        if not hasKnife then
            local bp = player:FindFirstChild("Backpack")
            if bp then hasKnife = bp:FindFirstChild("Knife") ~= nil end
        end
        if hasKnife then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then return hrp end
        end
    end
    return nil
end

local function isCoinNearMurderer(coinPos)
    if not avoidMurderCoins then return false end
    local murderHRP = getMurdererHRP()
    if not murderHRP then return false end
    return (murderHRP.Position - coinPos).Magnitude < MURDERER_DANGER_RADIUS
end

local function findNearestCoin(hrp)
    if not hrp then return nil end
    local container = getCoinContainer()
    if not container then return nil end
    local nearest = nil
    local bestDist = math.huge
    for _, child in pairs(container:GetChildren()) do
        if isCoinCollectable(child) then
            if not visitedCoins[child] then
                if not isCoinNearMurderer(child.Position) then
                    local dist = (hrp.Position - child.Position).Magnitude
                    if dist < bestDist then
                        bestDist = dist
                        nearest = child
                    end
                end
            end
        end
    end
    return nearest
end

local function isRoundActive()
    local container = getCoinContainer()
    if not container then return false end
    for _, child in pairs(container:GetChildren()) do
        if isCoinCollectable(child) then
            return true
        end
    end
    return false
end

local function allCoinsGone()
    local container = getCoinContainer()
    if not container then return true end
    for _, child in pairs(container:GetChildren()) do
        if isCoinCollectable(child) then
            return false
        end
    end
    return true
end

local function killCharacter()
    local char = localplayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.Health = 0 end
    end
end

local function waitForNewMapToLoad()
    waitingForNewMap = true
    local oldMap = getActiveMap()
    while getActiveMap() == oldMap and oldMap and oldMap.Parent do task.wait(0.5) end
    local timeout = tick() + 60
    while not getActiveMap() and tick() < timeout do task.wait(0.5) end
    task.wait(2)
    waitingForNewMap = false
end

local function isPlayerSpectating()
    local char = localplayer.Character
    if not char then return true end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return true end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return true end
    if hrp.Position.Y > 400 and isRoundActive() then return true end
    return false
end

local function waitIfSpectatingMidRound()
    if not isRoundActive() then return end
    if not isPlayerSpectating() then return end
    isSpectatingMidRound = true
    while autoFarm and isRoundActive() do task.wait(0.5) end
    if autoFarm then waitForNewMapToLoad() end
    isSpectatingMidRound = false
    visitedCoins = {}
    roundHadCoins = false
end

local function doNormalFarm(hrp)
    if not hrp or not hrp.Parent or deadUntilNextRound or waitingForNewMap then return end
    local coin = findNearestCoin(hrp)
    while coin and not isCoinCollectable(coin) do
        visitedCoins[coin] = true; coin = findNearestCoin(hrp)
    end
    if not coin or not isCoinCollectable(coin) then return end
    task.wait()
    if not isCoinCollectable(coin) then return end
    visitedCoins[coin] = true
    -- Tween to the actual visible part (MainCoin / CoinVisual) so candy works
    local refPart = getCoinVisualPart(coin) or coin
    local targetPos = Vector3.new(refPart.Position.X, refPart.Position.Y, refPart.Position.Z)
    local tweenTime = math.max((hrp.Position - targetPos).Magnitude / tweenSpeed, 0.1)
    cancelActiveTween()
    activeTween = TweenService:Create(hrp, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), { CFrame = CFrame.new(targetPos) })
    local coinGone = false
    local watchConn
    watchConn = RunService.Heartbeat:Connect(function()
        if not isCoinCollectable(coin) then
            coinGone = true; cancelActiveTween()
            if watchConn then watchConn:Disconnect(); watchConn = nil end
        end
    end)
    activeTween:Play(); activeTween.Completed:Wait(); activeTween = nil
    if watchConn then watchConn:Disconnect(); watchConn = nil end
    if not coinGone and isCoinCollectable(coin) then hrp.CFrame = CFrame.new(targetPos); task.wait(0.05) end
end

-- Runs the "when full coins action" toggles. Does NOT stop the farm loops itself;
-- callers are responsible for cleaning up before calling this.
local function handleRoundEnd(hrp)
    cancelActiveTween(); visitedCoins = {}
    anchorHRP(hrp, false); deadUntilNextRound = true
    local coinsGone = allCoinsGone()
    local hasGunNow = hasGun()
    local hasKnifeNow = hasKnife()

    -- Priority order: kill-all > shoot > fling > lobby > reset
    if killAllEnabled and coinsGone and hasKnifeNow then
        task.spawn(function()
            killEveryone()
        end)
        local char = localplayer.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then root.CFrame = LOBBY_POSITION end
        end
        return
    end
    if autoShootMurderEnabled and coinsGone and hasGunNow then
        task.spawn(function()
            autoShootMurdererLoop()
        end)
        local char = localplayer.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then root.CFrame = LOBBY_POSITION end
        end
        return
    end
    if flingMurderEnabled and coinsGone and not hasGunNow and not hasKnifeNow then
        task.spawn(function()
            flingMurdererLoop()
        end)
        local char = localplayer.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then root.CFrame = LOBBY_POSITION end
        end
        return
    end
    if waitInLobbyEnabled then
        local char = localplayer.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then root.CFrame = LOBBY_POSITION end
        end
        return
    end
    if autoResetEnabled then
        killCharacter()
        return
    end
end

-- Only fires the end-of-round actions if coins really appeared this round.
-- If the round never had coins, just idle until the next round (no actions).
local function finishRound(hrp)
    if roundHadCoins then
        roundHadCoins = false
        handleRoundEnd(hrp)
    else
        cancelActiveTween(); visitedCoins = {}
        if hrp then anchorHRP(hrp, false) end
        deadUntilNextRound = true
    end
end

local function normalFarmMain(hrp)
    if not hrp or waitingForNewMap then return end
    while autoFarm and not deadUntilNextRound and not waitingForNewMap and farmMode == "Normal" do
        if isRoundActive() then roundHadCoins = true end
        if not isRoundActive() or allCoinsGone() then
            finishRound(hrp)
            break
        end
        doNormalFarm(hrp); task.wait(0.05)
    end
end

-- ============================================================
-- Underground farm (Valentine-style floating platform)
-- ============================================================

local function valGetRoot()
    local char = localplayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function valIsAlive()
    local char = localplayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return char and hum and hum.Health > 0
end

local function valFindCoin()
    local root = valGetRoot()
    if not root then return end
    local container = getCoinContainer()
    if not container then return end
    local best, bestDist
    for _, child in pairs(container:GetChildren()) do
        -- Removed CoinID requirement; accept candy and other collectibles
        if child:IsA("BasePart") and not child:GetAttribute("Collected") then
            if not isCoinNearMurderer(child.Position) then
                local visual = child:FindFirstChild("CoinVisual")
                local main = visual and visual:FindFirstChild("MainCoin")
                local visible = false
                if main then
                    visible = main.Transparency == 0
                elseif visual then
                    visible = visual:IsA("BasePart") and visual.Transparency == 0
                end
                if visible then
                    local d = (root.Position - child.Position).Magnitude
                    if not bestDist or d < bestDist then
                        best, bestDist = child, d
                    end
                end
            end
        end
    end
    return best
end

local function valStopFarm()
    valLoopActive = false
    valFirstCoin = true
    if valHeartbeatConn then valHeartbeatConn:Disconnect(); valHeartbeatConn = nil end
    if valFloatPart then valFloatPart:Destroy(); valFloatPart = nil end
    local root = valGetRoot()
    if root then
        root.Anchored = false
        root.Velocity = Vector3.zero
        root.RotVelocity = Vector3.zero
    end
end

local function valStartFarm()
    if valFloatPart then return end

    valFloatPart = Instance.new("Part")
    valFloatPart.Name = "ValFarmFloat"
    valFloatPart.Size = Vector3.new(5, 0.1, 5)
    valFloatPart.CanCollide = true
    valFloatPart.Anchored = true
    valFloatPart.Transparency = 1
    valFloatPart.CanQuery = false
    valFloatPart.CastShadow = false
    valFloatPart.Parent = Workspace

    local root = valGetRoot()
    local startPos = root and (root.Position - Vector3.new(0, 7, 0)) or Vector3.zero
    valFloatPart.CFrame = CFrame.new(startPos)

    valHeartbeatConn = RunService.Heartbeat:Connect(function()
        local r = valGetRoot()
        if r and valFloatPart and valIsAlive() then
            local cf = valFloatPart.CFrame * CFrame.new(0, 3, 0)
            if (cf.Position - r.Position).Magnitude < 400 then
                r.CFrame = cf
            end
            r.Velocity = Vector3.zero
            r.RotVelocity = Vector3.zero
        end
    end)

    if valLoopActive then return end
    valLoopActive = true

    task.spawn(function()
        while valLoopActive and autoFarm do
            local r = valGetRoot()
            if r and valIsAlive() and getActiveMap() then
                local coin = valFindCoin()
                if coin then
                    local refPart = getCoinVisualPart(coin) or coin
                    local cf = CFrame.new(refPart.Position) * CFrame.new(0, -7, 0)
                    local dist = (r.Position - cf.Position).Magnitude
                    if valFirstCoin then
                        -- First coin of a fresh farm session: teleport directly
                        valFloatPart.CFrame = cf
                        valFirstCoin = false
                    elseif dist >= 200 then
                        valFloatPart.CFrame = cf
                    else
                        local tween = TweenService:Create(
                            valFloatPart,
                            TweenInfo.new(dist / tweenSpeed, Enum.EasingStyle.Linear),
                            { CFrame = cf }
                        )
                        tween:Play()
                        tween.Completed:Wait()
                    end

                    local touchStart = tick()
                    while coin and coin.Parent and isCoinCollectable(coin) and tick() - touchStart < 2 do
                        local rr = valGetRoot()
                        if not rr then break end
                        pcall(function()
                            firetouchinterest(rr, coin, 1)
                            firetouchinterest(rr, coin, 0)
                        end)
                        task.wait(0.05)
                    end
                else
                    task.wait(0.2)
                end
            else
                if valFloatPart then valFloatPart.CFrame = CFrame.new(100, -500, 100) end
                task.wait(0.3)
            end
            task.wait()
        end
        valLoopActive = false
    end)
end

local function safeFarmMain(hrp)
    if not hrp or waitingForNewMap then return end
    valStartFarm()
    while autoFarm and not deadUntilNextRound and not waitingForNewMap and farmMode == "Underground" do
        if isRoundActive() then roundHadCoins = true end
        if not isRoundActive() or allCoinsGone() then
            valStopFarm()
            finishRound(hrp)
            break
        end
        task.wait(0.1)
    end
    valStopFarm()
end

-- ============================================================
-- Lay farm (invisible platform, HRP laid flat below coin)
-- ============================================================

local function layGetRoot()
    local char = localplayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function layIsAlive()
    local char = localplayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return char and hum and hum.Health > 0
end

local function layFindCoin()
    local root = layGetRoot()
    if not root then return end
    local container = getCoinContainer()
    if not container then return end
    local best, bestDist
    for _, child in pairs(container:GetChildren()) do
        -- Removed CoinID requirement
        if child:IsA("BasePart") and not child:GetAttribute("Collected") then
            if not isCoinNearMurderer(child.Position) then
                local visual = child:FindFirstChild("CoinVisual")
                local main = visual and visual:FindFirstChild("MainCoin")
                local visible = false
                if main then
                    visible = main.Transparency == 0
                elseif visual then
                    visible = visual:IsA("BasePart") and visual.Transparency == 0
                end
                if visible then
                    local d = (root.Position - child.Position).Magnitude
                    if not bestDist or d < bestDist then
                        best, bestDist = child, d
                    end
                end
            end
        end
    end
    return best
end

local function layStopFarm()
    layLoopActive = false
    layFirstCoin = true
    if layHeartbeatConn then layHeartbeatConn:Disconnect(); layHeartbeatConn = nil end
    if layTween then pcall(function() layTween:Cancel() end); layTween = nil end
    if layPlatform then layPlatform:Destroy(); layPlatform = nil end
    local root = layGetRoot()
    if root then
        root.Anchored = false
        root.Velocity = Vector3.zero
        root.RotVelocity = Vector3.zero
    end
end

local function layStartFarm()
    if layPlatform then return end

    local root = layGetRoot()
    if not root then return end

    local platform = Instance.new("Part")
    platform.Name = "LayPlatform"
    platform.Size = Vector3.new(5, 0.1, 5)
    platform.Anchored = true
    platform.CanCollide = true
    platform.Transparency = 1
    platform.CanQuery = false
    platform.CastShadow = false
    platform.CFrame = CFrame.new(root.Position - Vector3.new(0, layUndergroundOffset + 3, 0))
    platform.Parent = Workspace
    layPlatform = platform

    layHeartbeatConn = RunService.Heartbeat:Connect(function()
        local char = localplayer.Character
        local r = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not r or not hum or hum.Health <= 0 then return end
        if not layPlatform or not layPlatform.Parent then return end

        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("BasePart") and d.CanCollide then
                d.CanCollide = false
            end
        end

        r.CFrame = layPlatform.CFrame * CFrame.new(0, 3, 0) * CFrame.Angles(math.rad(90), 0, 0)
        r.Velocity = Vector3.zero
        r.RotVelocity = Vector3.zero
    end)

    if layLoopActive then return end
    layLoopActive = true

    task.spawn(function()
        while layLoopActive and autoFarm do
            local r = layGetRoot()
            if r and layIsAlive() and getActiveMap() then
                local coin = layFindCoin()
                if coin then
                    local refPart = getCoinVisualPart(coin) or coin
                    local target = CFrame.new(refPart.Position) * CFrame.new(0, -layUndergroundOffset - 3, 0)
                    local dist = (layPlatform.CFrame.Position - target.Position).Magnitude
                    if layFirstCoin then
                        -- First coin of a fresh farm session: teleport directly
                        layPlatform.CFrame = target
                        layFirstCoin = false
                    elseif dist >= 200 then
                        layPlatform.CFrame = target
                    else
                        if layTween then pcall(function() layTween:Cancel() end) end
                        layTween = TweenService:Create(
                            layPlatform,
                            TweenInfo.new(math.max(dist / tweenSpeed, 0.05), Enum.EasingStyle.Linear),
                            { CFrame = target }
                        )
                        layTween:Play()
                        layTween.Completed:Wait()
                        layTween = nil
                    end

                    local touchStart = tick()
                    while coin and coin.Parent and isCoinCollectable(coin) and tick() - touchStart < 2 do
                        local rr = layGetRoot()
                        if not rr then break end
                        pcall(function()
                            firetouchinterest(rr, coin, 1)
                            firetouchinterest(rr, coin, 0)
                        end)
                        task.wait(0.05)
                    end
                else
                    task.wait(0.2)
                end
            else
                if layPlatform then
                    layPlatform.CFrame = CFrame.new(100, -500, 100)
                end
                task.wait(0.3)
            end
            task.wait()
        end
        layLoopActive = false
    end)
end

local function layFarmMain(hrp)
    if not hrp or waitingForNewMap then return end
    layStartFarm()
    while autoFarm and not deadUntilNextRound and not waitingForNewMap and farmMode == "Lay" do
        if isRoundActive() then roundHadCoins = true end
        if not isRoundActive() or allCoinsGone() then
            layStopFarm()
            finishRound(hrp)
            break
        end
        task.wait(0.1)
    end
    layStopFarm()
end

-- ============================================================
-- Safe mode (teleport to a random coin, return to safe
-- coordinates, wait, repeat). Uses the same visibility /
-- collectable check as Underground so invisible coins are skipped.
-- ============================================================

local function safeGetRandomCoin()
    local container = getCoinContainer()
    if not container then return nil end
    local candidates = {}
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("BasePart")
            and isCoinCollectable(child)
            and not isCoinNearMurderer(child.Position) then
            table.insert(candidates, child)
        end
    end
    if #candidates == 0 then return nil end
    return candidates[math.random(1, #candidates)]
end

local safeFloatPart = nil
local safeHeartbeatConn = nil

local function safeStopFarm()
    if safeHeartbeatConn then safeHeartbeatConn:Disconnect(); safeHeartbeatConn = nil end
    if safeFloatPart then safeFloatPart:Destroy(); safeFloatPart = nil end
    local root = valGetRoot()
    if root then
        root.Anchored = false
        root.Velocity = Vector3.zero
        root.RotVelocity = Vector3.zero
    end
end

local function safeModeMain(hrp)
    if not hrp or waitingForNewMap then return end
    safeStopFarm()

    -- platform sits 3 studs below the safe coordinates so the player stands exactly at them
    local safeHome = CFrame.new(SAFE_POSITION - Vector3.new(0, 3, 0))

    -- same invisible float platform the Underground mode uses
    safeFloatPart = Instance.new("Part")
    safeFloatPart.Name = "SafeFarmFloat"
    safeFloatPart.Size = Vector3.new(5, 0.1, 5)
    safeFloatPart.CanCollide = true
    safeFloatPart.Anchored = true
    safeFloatPart.Transparency = 1
    safeFloatPart.CanQuery = false
    safeFloatPart.CastShadow = false
    safeFloatPart.CFrame = safeHome
    safeFloatPart.Parent = Workspace

    -- keeps the character glued to the platform (no distance cap so it can jump to/from the safe spot)
    safeHeartbeatConn = RunService.Heartbeat:Connect(function()
        local r = valGetRoot()
        if r and safeFloatPart and valIsAlive() then
            r.CFrame = safeFloatPart.CFrame * CFrame.new(0, 3, 0)
            r.Velocity = Vector3.zero
            r.RotVelocity = Vector3.zero
        end
    end)

    while autoFarm and not deadUntilNextRound and not waitingForNewMap and farmMode == "Safe" do
        if isRoundActive() then roundHadCoins = true end
        if not isRoundActive() or allCoinsGone() then
            safeStopFarm()
            finishRound(hrp)
            return
        end

        if valIsAlive() and safeFloatPart then
            local coin = safeGetRandomCoin()
            if coin then
                -- 1) teleport the platform to a random coin, 7 studs underground (same as Underground mode)
                local refPart = getCoinVisualPart(coin) or coin
                safeFloatPart.CFrame = CFrame.new(refPart.Position) * CFrame.new(0, -7, 0)
                task.wait(0.1)

                -- 2) firetouchinterest the coin until it's collected (or timeout)
                local touchStart = tick()
                while coin and coin.Parent and isCoinCollectable(coin) and tick() - touchStart < SAFE_TOUCH_TIMEOUT do
                    local rr = valGetRoot()
                    if not rr then break end
                    pcall(function()
                        firetouchinterest(rr, coin, 1)
                        firetouchinterest(rr, coin, 0)
                    end)
                    task.wait(0.05)
                end

                -- 3) go back to the safe coordinates
                if safeFloatPart then safeFloatPart.CFrame = safeHome end
            end
        end

        -- 4) wait at the safe coordinates, bail out early if farm is turned off / mode changes
        local untilT = tick() + SAFE_WAIT_TIME
        while tick() < untilT and autoFarm and farmMode == "Safe" and not deadUntilNextRound do
            task.wait(0.05)
        end
    end

    safeStopFarm()
end

local function customDeathHandler()
    deadUntilNextRound = true; cancelActiveTween()
    visitedCoins = {}; valStopFarm(); layStopFarm(); safeStopFarm(); disableAntiFling()
    if localplayer.Character and localplayer.Character:FindFirstChild("HumanoidRootPart") then
        localplayer.Character.HumanoidRootPart.Anchored = false
    end
end

local function startFarmLoop()
    if farmLoopRunning then return end
    farmLoopRunning = true
    enableAntiFling()
    task.spawn(function()
        waitIfSpectatingMidRound()
        if not autoFarm then farmLoopRunning = false; return end
        while autoFarm do
            if deadUntilNextRound then
                local char = localplayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then
                    localplayer.CharacterAdded:Wait(); task.wait(0.5)
                end
                -- Wait for coins to come back (new round) OR a new map, instead of
                -- a hard waitForNewMapToLoad that could hang past round end actions.
                local timeout = tick() + 90
                while autoFarm and deadUntilNextRound and tick() < timeout do
                    if isRoundActive() then break end
                    task.wait(0.5)
                end
                if not autoFarm then break end
                -- Only wait for map load if the old map is actually gone
                local map = getActiveMap()
                if not map then waitForNewMapToLoad() end
                -- No coins this round: stay idle (still "dead") and keep waiting for
                -- a round that has coins. Do NOT run any end-of-round actions.
                if not isRoundActive() then task.wait(0.5); continue end
                deadUntilNextRound = false; visitedCoins = {}
                roundHadCoins = false
                -- Fresh round: reset first-coin teleport for Lay/Underground
                valFirstCoin = true
                layFirstCoin = true
                task.wait(0.5); continue
            end
            local char = localplayer.Character
            if not char then task.wait(0.5); continue end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local humanoid = char:FindFirstChild("Humanoid")
            if humanoid then
                if humanoidDiedConn then pcall(function() humanoidDiedConn:Disconnect() end) end
                humanoidDiedConn = humanoid.Died:Connect(customDeathHandler)
            end
            if not hrp or not humanoid or humanoid.Health <= 0 or deadUntilNextRound or waitingForNewMap then
                task.wait(0.5); continue
            end
            -- Wait for a round to be active (unless one already is)
            local waitStart = tick()
            while autoFarm and not isRoundActive() and not deadUntilNextRound do
                task.wait(0.1)
                if tick() - waitStart > 90 then break end
            end
            if not autoFarm or deadUntilNextRound then task.wait(0.2); continue end
            -- Timed out with no coins: don't enter the farm (it would instantly
            -- think the round ended and fire the round-end actions). Keep waiting.
            if not isRoundActive() then task.wait(0.5); continue end
            char = localplayer.Character
            if not char then task.wait(0.5); continue end
            hrp = char:FindFirstChild("HumanoidRootPart")
            humanoid = char:FindFirstChild("Humanoid")
            if not hrp or not humanoid or humanoid.Health <= 0 then task.wait(0.5); continue end
            -- Fresh round detection: if coins are active and we haven't set first-coin yet, honor it
            if farmMode == "Underground" then 
                safeFarmMain(hrp) 
            elseif farmMode == "Lay" then
                layFarmMain(hrp)
            elseif farmMode == "Safe" then
                safeModeMain(hrp)
            else 
                normalFarmMain(hrp) 
            end
            -- After a farm main returns, if we didn't set deadUntilNextRound and
            -- coins are gone, force handleRoundEnd so toggles fire.
            if autoFarm and not deadUntilNextRound and not waitingForNewMap and (not isRoundActive() or allCoinsGone()) then
                finishRound(hrp)
            end
        end
        farmLoopRunning = false; disableAntiFling()
    end)
end

localplayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    local char = localplayer.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid then
        if humanoidDiedConn then humanoidDiedConn:Disconnect() end
        humanoidDiedConn = humanoid.Died:Connect(customDeathHandler)
    end
end)

Workspace.ChildAdded:Connect(function(child)
    if not autoFarm or deadUntilNextRound then return end
    if child:IsA("Model") and child:GetAttribute("MapID") and child:FindFirstChild("Spawns") then
        task.spawn(function()
            task.wait(2)
            if autoFarm and not deadUntilNextRound and not waitingForNewMap then
                local char = localplayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local mapModel = getActiveMap()
                if hrp and mapModel then
                    local spawnsFolder = mapModel:FindFirstChild("Spawns")
                    if spawnsFolder then
                        local pts = spawnsFolder:GetChildren()
                        if #pts > 0 then
                            hrp.CFrame = CFrame.new(pts[math.random(1, #pts)].Position + Vector3.new(0, 3, 0))
                            forceServerSync(char)
                        end
                    end
                end
            end
        end)
    end
end)

local sg = Instance.new("ScreenGui")
sg.Name = "SummerHub"; sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.IgnoreGuiInset = true
sg.Parent = game.CoreGui

local W, H = 260, 420

local main = Instance.new("Frame")
main.Size = UDim2.new(0, W, 0, H)
main.Position = UDim2.new(0.5, -W/2, 0.08, 0)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
main.BorderSizePixel = 0
main.Active = true
main.Parent = sg
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

local mainGradient = Instance.new("UIGradient", main)
mainGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 32)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 18, 22))
}
mainGradient.Rotation = 45

local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color = Color3.fromRGB(45, 45, 55)
mainStroke.Thickness = 1

local titleH = 44
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, titleH)
titleBar.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 3
titleBar.Parent = main
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)

local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0.5, 0)
titleFix.Position = UDim2.new(0, 0, 0.5, 0)
titleFix.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
titleFix.BorderSizePixel = 0
titleFix.Parent = titleBar

local subtitleLbl = Instance.new("TextLabel")
subtitleLbl.Size = UDim2.new(1, -96, 0, 14)
subtitleLbl.Position = UDim2.new(0, 12, 0, 22)
subtitleLbl.BackgroundTransparency = 1
subtitleLbl.Text = "unknowuser238183 on tiktok"
subtitleLbl.TextColor3 = Color3.fromRGB(180, 180, 200)
subtitleLbl.TextSize = 8
subtitleLbl.Font = Enum.Font.Gotham
subtitleLbl.TextXAlignment = Enum.TextXAlignment.Left
subtitleLbl.ZIndex = 4
subtitleLbl.Parent = titleBar

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 22, 0, 22)
minBtn.Position = UDim2.new(1, -52, 0.5, -11)
minBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
minBtn.BorderSizePixel = 0
minBtn.Text = "−"
minBtn.TextColor3 = Color3.fromRGB(180, 180, 200)
minBtn.TextSize = 14
minBtn.Font = Enum.Font.GothamBold
minBtn.ZIndex = 5
minBtn.Parent = titleBar
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 22, 0, 22)
closeBtn.Position = UDim2.new(1, -27, 0.5, -11)
closeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(180, 180, 200)
closeBtn.TextSize = 11
closeBtn.Font = Enum.Font.GothamBold
closeBtn.ZIndex = 5
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

local body = Instance.new("Frame")
body.Size = UDim2.new(1, 0, 1, -titleH)
body.Position = UDim2.new(0, 0, 0, titleH)
body.BackgroundTransparency = 1
body.ClipsDescendants = true
body.Parent = main

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -12, 1, -10)
content.Position = UDim2.new(0, 6, 0, 5)
content.BackgroundTransparency = 1
content.ClipsDescendants = true
content.Parent = body

local farmPage = Instance.new("ScrollingFrame")
farmPage.Size = UDim2.new(1, 0, 1, 0)
farmPage.BackgroundTransparency = 1
farmPage.BorderSizePixel = 0
farmPage.ScrollBarThickness = 3
farmPage.ScrollBarImageColor3 = Color3.fromRGB(55, 55, 70)
farmPage.CanvasSize = UDim2.new(0, 0, 0, 0)
farmPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
farmPage.Visible = true
farmPage.Parent = content

local list = Instance.new("UIListLayout", farmPage)
list.FillDirection = Enum.FillDirection.Vertical
list.Padding = UDim.new(0, 0)
list.SortOrder = Enum.SortOrder.LayoutOrder

local pad = Instance.new("UIPadding", farmPage)
pad.PaddingLeft = UDim.new(0, 6)
pad.PaddingRight = UDim.new(0, 6)
pad.PaddingTop = UDim.new(0, 6)
pad.PaddingBottom = UDim.new(0, 6)

local changelogFrame = Instance.new("Frame")
changelogFrame.Size = UDim2.new(1, 0, 0, 64)
changelogFrame.BackgroundColor3 = Color3.fromRGB(26, 26, 33)
changelogFrame.BorderSizePixel = 0
changelogFrame.LayoutOrder = 0
changelogFrame.Parent = farmPage
Instance.new("UICorner", changelogFrame).CornerRadius = UDim.new(0, 6)

local clStroke = Instance.new("UIStroke", changelogFrame)
clStroke.Color = Color3.fromRGB(48, 48, 60)
clStroke.Thickness = 1
clStroke.Transparency = 0.2

local clTitle = Instance.new("TextLabel")
clTitle.Size = UDim2.new(1, -14, 0, 14)
clTitle.Position = UDim2.new(0, 7, 0, 4)
clTitle.BackgroundTransparency = 1
clTitle.Text = "changelog"
clTitle.TextColor3 = Color3.fromRGB(150, 150, 175)
clTitle.TextSize = 9
clTitle.Font = Enum.Font.GothamMedium
clTitle.TextXAlignment = Enum.TextXAlignment.Left
clTitle.Parent = changelogFrame

local clLine = Instance.new("Frame")
clLine.Size = UDim2.new(1, -14, 0, 1)
clLine.Position = UDim2.new(0, 7, 0, 20)
clLine.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
clLine.BorderSizePixel = 0
clLine.Parent = changelogFrame

local clText = Instance.new("TextLabel")
clText.Size = UDim2.new(1, -14, 1, -24)
clText.Position = UDim2.new(0, 7, 0, 22)
clText.BackgroundTransparency = 1
clText.Text = "added new Safe mode)\ncoin detection fixed, shouldnt tween to coins that are already gone now\nyes im aware of a issue where it will fling murder at the start of the round/\nunderground + fixed for halloween\n\nthe script has a few bugs so please be aware"
clText.TextColor3 = Color3.fromRGB(140, 140, 160)
clText.TextSize = 8
clText.Font = Enum.Font.Gotham
clText.TextXAlignment = Enum.TextXAlignment.Left
clText.TextYAlignment = Enum.TextYAlignment.Top
clText.TextWrapped = true
clText.Parent = changelogFrame

local function makeSection(parent, text, order)
    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1, 0, 0, 18)
    wrap.BackgroundTransparency = 1
    wrap.LayoutOrder = order
    wrap.Parent = parent
    local lbl = Instance.new("TextLabel", wrap)
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(90, 90, 110)
    lbl.TextSize = 9
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
end

local function makeDivider(parent, order)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 1)
    f.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    f.BorderSizePixel = 0
    f.LayoutOrder = order
    f.Parent = parent
end

local function makeToggle(parent, label, order)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 34)
    row.BackgroundTransparency = 1
    row.LayoutOrder = order
    row.Parent = parent
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, -54, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(190, 190, 205)
    lbl.TextSize = 10
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local track = Instance.new("TextButton", row)
    track.Size = UDim2.new(0, 40, 0, 22)
    track.Position = UDim2.new(1, -44, 0.5, -11)
    track.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    track.BorderSizePixel = 0
    track.Text = ""
    track.AutoButtonColor = false
    track.ZIndex = 10
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local ts = Instance.new("UIStroke", track)
    ts.Color = Color3.fromRGB(55, 55, 68)
    ts.Thickness = 1
    local knob = Instance.new("Frame", track)
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(90, 90, 105)
    knob.BorderSizePixel = 0
    knob.ZIndex = 11
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    return track, knob
end

local function setToggle(track, knob, state)
    TweenService:Create(track, TweenInfo.new(0.15), {
        BackgroundColor3 = state and Color3.fromRGB(75, 75, 95) or Color3.fromRGB(40, 40, 50)
    }):Play()
    TweenService:Create(knob, TweenInfo.new(0.15), {
        Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
        BackgroundColor3 = state and Color3.fromRGB(230, 230, 245) or Color3.fromRGB(90, 90, 105)
    }):Play()
    TweenService:Create(knob.Parent:FindFirstChildOfClass("UIStroke"), TweenInfo.new(0.15), {
        Color = state and Color3.fromRGB(90, 90, 120) or Color3.fromRGB(55, 55, 68)
    }):Play()
end

makeSection(farmPage, "AUTO FARM", 1)
local farmTrack, farmKnob = makeToggle(farmPage, "Enable Auto Farm", 2)

local modeRow = Instance.new("Frame")
modeRow.Size = UDim2.new(1, 0, 0, 34)
modeRow.BackgroundTransparency = 1
modeRow.LayoutOrder = 3
modeRow.Parent = farmPage

local modeLbl = Instance.new("TextLabel", modeRow)
modeLbl.Size = UDim2.new(0.4, 0, 1, 0)
modeLbl.BackgroundTransparency = 1
modeLbl.Text = "Farm Mode"
modeLbl.TextColor3 = Color3.fromRGB(190, 190, 205)
modeLbl.TextSize = 10
modeLbl.Font = Enum.Font.Gotham
modeLbl.TextXAlignment = Enum.TextXAlignment.Left

local modeBtn = Instance.new("TextButton", modeRow)
modeBtn.Size = UDim2.new(0, 90, 0, 22)
modeBtn.Position = UDim2.new(1, -94, 0.5, -11)
modeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
modeBtn.BorderSizePixel = 0
modeBtn.Text = "Select"
modeBtn.TextColor3 = Color3.fromRGB(180, 180, 200)
modeBtn.TextSize = 9
modeBtn.Font = Enum.Font.GothamMedium
modeBtn.AutoButtonColor = false
Instance.new("UICorner", modeBtn).CornerRadius = UDim.new(0, 6)
local mbs = Instance.new("UIStroke", modeBtn)
mbs.Color = Color3.fromRGB(50, 50, 62)
mbs.Thickness = 1

local modeDrop = Instance.new("Frame")
modeDrop.Size = UDim2.new(0, 94, 0, 102)
modeDrop.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
modeDrop.BorderSizePixel = 0
modeDrop.Visible = false
modeDrop.ZIndex = 30
modeDrop.Parent = main
Instance.new("UICorner", modeDrop).CornerRadius = UDim.new(0, 8)
local mds = Instance.new("UIStroke", modeDrop)
mds.Color = Color3.fromRGB(50, 50, 62)
mds.Thickness = 1

for i, opt in ipairs({"Normal", "Underground", "Lay", "Safe"}) do
    local b = Instance.new("TextButton", modeDrop)
    b.Size = UDim2.new(1, 0, 0, 24)
    b.Position = UDim2.new(0, 0, 0, (i-1)*24)
    b.BackgroundTransparency = 1
    b.Text = opt
    b.TextColor3 = Color3.fromRGB(180, 180, 200)
    b.TextSize = 9
    b.Font = Enum.Font.Gotham
    b.ZIndex = 31
    b.TextXAlignment = Enum.TextXAlignment.Left
    local bp = Instance.new("UIPadding", b)
    bp.PaddingLeft = UDim.new(0, 10)
    b.MouseEnter:Connect(function() 
        b.BackgroundTransparency = 0
        b.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    end)
    b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
    b.MouseButton1Click:Connect(function()
        farmMode = opt
        modeBtn.Text = opt
        modeDrop.Visible = false
        if autoFarm then
            cancelActiveTween()
            valStopFarm()
            layStopFarm()
            safeStopFarm()
            -- Mid-round mode switch: don't let the next Lay/Underground session
            -- teleport to a coin. Keep first-coin teleport only for fresh starts.
            valFirstCoin = false
            layFirstCoin = false
            local char = localplayer.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.Anchored = false end
            end
        end
    end)
end

modeBtn.MouseButton1Click:Connect(function()
    modeDrop.Visible = not modeDrop.Visible
    if modeDrop.Visible then
        local ap = modeBtn.AbsolutePosition
        local mp = main.AbsolutePosition
        modeDrop.Position = UDim2.new(0, ap.X - mp.X - 50, 0, ap.Y - mp.Y + 24)
    end
end)

makeDivider(farmPage, 4)
makeSection(farmPage, "WHEN FULL COINS ACTION", 5)
local resetTrack, resetKnob = makeToggle(farmPage, "Auto Reset Character", 6)
local killAllTrack, killAllKnob = makeToggle(farmPage, "Kill All Players", 7)
local shootTrack, shootKnob = makeToggle(farmPage, "Auto Shoot Murderer", 8)
local flingTrack, flingKnob = makeToggle(farmPage, "Fling Murderer", 9)
local lobbyTrack, lobbyKnob = makeToggle(farmPage, "Return to Lobby", 10)

makeDivider(farmPage, 11)
makeSection(farmPage, "SETTINGS", 12)
local avoidTrack, avoidKnob = makeToggle(farmPage, "Avoid Murderer Coins", 13)

local speedWrap = Instance.new("Frame")
speedWrap.Size = UDim2.new(1, 0, 0, 60)
speedWrap.BackgroundTransparency = 1
speedWrap.LayoutOrder = 14
speedWrap.Parent = farmPage

local speedLbl = Instance.new("TextLabel", speedWrap)
speedLbl.Size = UDim2.new(0.6, 0, 0, 16)
speedLbl.BackgroundTransparency = 1
speedLbl.Text = "Tween Speed"
speedLbl.TextColor3 = Color3.fromRGB(180, 180, 200)
speedLbl.TextSize = 10
speedLbl.Font = Enum.Font.Gotham
speedLbl.TextXAlignment = Enum.TextXAlignment.Left

local speedVal = Instance.new("TextLabel", speedWrap)
speedVal.Size = UDim2.new(0.4, 0, 0, 16)
speedVal.Position = UDim2.new(0.6, 0, 0, 0)
speedVal.BackgroundTransparency = 1
speedVal.Text = tostring(tweenSpeed)
speedVal.TextColor3 = Color3.fromRGB(200, 200, 220)
speedVal.TextSize = 10
speedVal.Font = Enum.Font.GothamBold
speedVal.TextXAlignment = Enum.TextXAlignment.Right

local speedWarn = Instance.new("TextLabel", speedWrap)
speedWarn.Size = UDim2.new(1, 0, 0, 20)
speedWarn.Position = UDim2.new(0, 0, 0, 16)
speedWarn.BackgroundTransparency = 1
speedWarn.Text = "WARNING: Setting the speed higher than 22 may get you kicked for \"invalid position\", be cautious"
speedWarn.TextColor3 = Color3.fromRGB(230, 90, 90)
speedWarn.TextSize = 8
speedWarn.Font = Enum.Font.GothamBold
speedWarn.TextXAlignment = Enum.TextXAlignment.Left
speedWarn.TextYAlignment = Enum.TextYAlignment.Top
speedWarn.TextWrapped = true

local sTrack = Instance.new("Frame", speedWrap)
sTrack.Size = UDim2.new(1, 0, 0, 4)
sTrack.Position = UDim2.new(0, 0, 0, 40)
sTrack.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
sTrack.BorderSizePixel = 0
Instance.new("UICorner", sTrack).CornerRadius = UDim.new(1, 0)

local sFill = Instance.new("Frame", sTrack)
sFill.Size = UDim2.new(tweenSpeed/30, 0, 1, 0)
sFill.BackgroundColor3 = Color3.fromRGB(110, 110, 140)
sFill.BorderSizePixel = 0
Instance.new("UICorner", sFill).CornerRadius = UDim.new(1, 0)

local sKnob = Instance.new("Frame", sTrack)
sKnob.Size = UDim2.new(0, 14, 0, 14)
sKnob.AnchorPoint = Vector2.new(0.5, 0.5)
sKnob.Position = UDim2.new(tweenSpeed/30, 0, 0.5, 0)
sKnob.BackgroundColor3 = Color3.fromRGB(220, 220, 240)
sKnob.BorderSizePixel = 0
Instance.new("UICorner", sKnob).CornerRadius = UDim.new(1, 0)

local sHit = Instance.new("TextButton", sTrack)
sHit.Size = UDim2.new(1, 0, 0, 24)
sHit.Position = UDim2.new(0, 0, 0.5, -12)
sHit.BackgroundTransparency = 1
sHit.Text = ""

local sliding = false
local function updateSlider(x)
    local rel = math.clamp((x - sTrack.AbsolutePosition.X) / sTrack.AbsoluteSize.X, 0, 1)
    local spd = math.max(math.round(rel * 30), 1)
    tweenSpeed = spd
    speedVal.Text = tostring(spd)
    sFill.Size = UDim2.new(rel, 0, 1, 0)
    sKnob.Position = UDim2.new(rel, 0, 0.5, 0)
end

sHit.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        sliding = true
        updateSlider(i.Position.X)
    end
end)
sHit.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        sliding = false
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        updateSlider(i.Position.X)
    end
end)

farmTrack.MouseButton1Click:Connect(function()
    if not farmMode then 
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Summer Hub",
            Text = "Select a farm mode first!",
            Duration = 3
        })
        return 
    end

    autoFarm = not autoFarm
    setToggle(farmTrack, farmKnob, autoFarm)
    if autoFarm then
        deadUntilNextRound = false
        roundHadCoins = false
        visitedCoins = {}
        -- Fresh start: allow first-coin teleport for Lay/Underground
        valFirstCoin = true
        layFirstCoin = true
        startFarmLoop()
    else
        cancelActiveTween()
        valStopFarm()
        layStopFarm()
        safeStopFarm()
        disableAntiFling()
        flingLoopActive = false
        shootLoopActive = false
        local char = localplayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.Anchored = false end
        end
    end
end)

resetTrack.MouseButton1Click:Connect(function()
    autoResetEnabled = not autoResetEnabled
    setToggle(resetTrack, resetKnob, autoResetEnabled)
end)

killAllTrack.MouseButton1Click:Connect(function()
    killAllEnabled = not killAllEnabled
    setToggle(killAllTrack, killAllKnob, killAllEnabled)
end)

shootTrack.MouseButton1Click:Connect(function()
    autoShootMurderEnabled = not autoShootMurderEnabled
    setToggle(shootTrack, shootKnob, autoShootMurderEnabled)
    if not autoShootMurderEnabled then
        shootLoopActive = false
    end
end)

flingTrack.MouseButton1Click:Connect(function()
    flingMurderEnabled = not flingMurderEnabled
    setToggle(flingTrack, flingKnob, flingMurderEnabled)
    if not flingMurderEnabled then
        flingLoopActive = false
    end
end)

lobbyTrack.MouseButton1Click:Connect(function()
    waitInLobbyEnabled = not waitInLobbyEnabled
    setToggle(lobbyTrack, lobbyKnob, waitInLobbyEnabled)
end)

avoidTrack.MouseButton1Click:Connect(function()
    avoidMurderCoins = not avoidMurderCoins
    setToggle(avoidTrack, avoidKnob, avoidMurderCoins)
end)

-- Execute Full Summer Hub button
local execWrap = Instance.new("Frame")
execWrap.Size = UDim2.new(1, 0, 0, 34)
execWrap.BackgroundTransparency = 1
execWrap.LayoutOrder = 15
execWrap.Parent = farmPage

local execBtn = Instance.new("TextButton")
execBtn.Size = UDim2.new(1, 0, 0, 28)
execBtn.Position = UDim2.new(0, 0, 0.5, -14)
execBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
execBtn.BorderSizePixel = 0
execBtn.Text = "Execute Full Summer Hub"
execBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
execBtn.TextSize = 10
execBtn.Font = Enum.Font.GothamMedium
execBtn.AutoButtonColor = false
execBtn.Parent = execWrap
Instance.new("UICorner", execBtn).CornerRadius = UDim.new(0, 6)

local execStroke = Instance.new("UIStroke", execBtn)
execStroke.Color = Color3.fromRGB(50, 50, 62)
execStroke.Thickness = 1

execBtn.MouseButton1Click:Connect(function()
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Johnnyissocoollol/mm2/refs/heads/main/mm2hub.lua"))()
    end)
end)

-- Credit
local creditLbl = Instance.new("TextLabel")
creditLbl.Size = UDim2.new(1, 0, 0, 16)
creditLbl.BackgroundTransparency = 1
creditLbl.Text = "unknowuser238183 on tiktok"
creditLbl.TextColor3 = Color3.fromRGB(180, 180, 200)
creditLbl.TextSize = 9
creditLbl.Font = Enum.Font.Gotham
creditLbl.TextXAlignment = Enum.TextXAlignment.Center
creditLbl.LayoutOrder = 16
creditLbl.Parent = farmPage

local minimized = false
local savedPosition = main.Position

minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        savedPosition = main.Position
        main.Size = UDim2.new(0, W, 0, titleH)
        body.Visible = false
        mainStroke.Visible = false
        minBtn.Text = "+"
    else
        main.Size = UDim2.new(0, W, 0, H)
        body.Visible = true
        mainStroke.Visible = true
        minBtn.Text = "−"
        main.Position = savedPosition
    end
end)

local toggleBar = Instance.new("TextButton")
toggleBar.Size = UDim2.new(0, 120, 0, 24)
toggleBar.Position = UDim2.new(0.5, -60, 0, 6)
toggleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
toggleBar.BorderSizePixel = 0
toggleBar.Text = "Summer Hub 🎃"
toggleBar.TextColor3 = Color3.fromRGB(200, 200, 220)
toggleBar.TextSize = 10
toggleBar.Font = Enum.Font.GothamMedium
toggleBar.AutoButtonColor = false
toggleBar.Visible = false
toggleBar.ZIndex = 50
toggleBar.Parent = sg

Instance.new("UICorner", toggleBar).CornerRadius = UDim.new(0, 8)

local tbStroke = Instance.new("UIStroke", toggleBar)
tbStroke.Color = Color3.fromRGB(45, 45, 55)
tbStroke.Thickness = 1

local tbDot = Instance.new("Frame", toggleBar)
tbDot.Size = UDim2.new(0, 6, 0, 6)
tbDot.Position = UDim2.new(0, 9, 0.5, -3)
tbDot.BackgroundColor3 = Color3.fromRGB(90, 200, 130)
tbDot.BorderSizePixel = 0
Instance.new("UICorner", tbDot).CornerRadius = UDim.new(1, 0)

local tbDragData = {active = false, startPos = nil, startMouse = nil, moved = false}

toggleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
       input.UserInputType == Enum.UserInputType.Touch then
        tbDragData.active = true
        tbDragData.startPos = toggleBar.Position
        tbDragData.startMouse = input.Position
        tbDragData.moved = false
    end
end)

toggleBar.InputChanged:Connect(function(input)
    if not tbDragData.active then return end
    local delta = input.Position - tbDragData.startMouse
    if math.abs(delta.X) > 3 or math.abs(delta.Y) > 3 then
        tbDragData.moved = true
    end
    local vp = workspace.CurrentCamera.ViewportSize
    local newX = tbDragData.startPos.X.Scale + (tbDragData.startPos.X.Offset + delta.X) / vp.X
    local newY = tbDragData.startPos.Y.Scale + (tbDragData.startPos.Y.Offset + delta.Y) / vp.Y
    toggleBar.Position = UDim2.new(newX, 0, newY, 0)
end)

toggleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
       input.UserInputType == Enum.UserInputType.Touch then
        tbDragData.active = false
    end
end)

toggleBar.MouseButton1Click:Connect(function()
    if tbDragData.moved then return end
    toggleBar.Visible = false
    main.Visible = true
end)

-- Close button just hides the window now; farming keeps running in the background
closeBtn.MouseButton1Click:Connect(function()
    main.Visible = false
    toggleBar.Visible = true
end)

local function makeDraggableMobile(handle, target)
    local dragData = {active = false, startPos = nil, startMouse = nil}
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragData.active = true
            dragData.startPos = target.Position
            dragData.startMouse = input.Position
        end
    end)
    handle.InputChanged:Connect(function(input)
        if not dragData.active then return end
        local delta = input.Position - dragData.startMouse
        local vp = workspace.CurrentCamera.ViewportSize
        local newX = dragData.startPos.X.Scale + (dragData.startPos.X.Offset + delta.X) / vp.X
        local newY = dragData.startPos.Y.Scale + (dragData.startPos.Y.Offset + delta.Y) / vp.Y
        target.Position = UDim2.new(newX, 0, newY, 0)
    end)
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragData.active = false
        end
    end)
end

makeDraggableMobile(titleBar, main)

UserInputService.InputBegan:Connect(function(inp)
    if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    local mp = inp.Position
    local function out(f)
        local p, s = f.AbsolutePosition, f.AbsoluteSize
        return not (mp.X >= p.X and mp.X <= p.X+s.X and mp.Y >= p.Y and mp.Y <= p.Y+s.Y)
    end
    if modeDrop.Visible and out(modeDrop) and out(modeBtn) then modeDrop.Visible = false end
end)
