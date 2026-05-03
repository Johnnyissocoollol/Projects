if getgenv().__MM2FarmCleanup then
    pcall(getgenv().__MM2FarmCleanup)
    getgenv().__MM2FarmCleanup = nil
end
local _existingGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
    and game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("AutoFarmGUI")
if _existingGui then _existingGui:Destroy() end
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local localplayer = Players.LocalPlayer
local tweenSpeed = 15
local safe2UndergroundOffset = -6.8
local layUndergroundOffset = -2.9
local safe2PickupOffsetY = -2.5
local farmMode = "Safe"
local autoFarm = false
local autoResetEnabled = false
local antiAfkEnabled = false
local flingMurderEnabled = false
local deadUntilNextRound = false
local visitedCoins = {}
local activeTween = nil
local fakeFloor = nil
local padFollowConnection = nil
local layGyro = nil
local layVelocity = nil
local layStabilizeConnection = nil
local antiAfkConnection = nil
local humanoidDiedConn = nil
local waitingForNewMap = false
local noclipConnections = {}
local farmLoopRunning = false
local antiFlingEnabled = false
local antiFlingConnection = nil
local hasFlingedThisRound = false
local flingRetryCount = 0
local MAX_FLING_RETRIES = 5
local isFlingInProgress = false
local cachedMurderer = nil
local murdererWatcherConn = nil
local lobbyLockConnection = nil
local lobbyLockCFrame = nil
local isSpectatingMidRound = false
local function findMurderer()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localplayer then
            if (player.Backpack and player.Backpack:FindFirstChild("Knife")) or 
               (player.Character and player.Character:FindFirstChild("Knife")) then
                return player
            end
        end
    end
    return nil
end
local function isLocalPlayerMurderer()
    return (localplayer.Backpack and localplayer.Backpack:FindFirstChild("Knife")) or
           (localplayer.Character and localplayer.Character:FindFirstChild("Knife"))
end
local function startMurdererWatcher()
    if murdererWatcherConn then return end
    cachedMurderer = nil
    murdererWatcherConn = RunService.Heartbeat:Connect(function()
        local found = findMurderer()
        if found then cachedMurderer = found end
    end)
end
local function stopMurdererWatcher()
    if murdererWatcherConn then
        murdererWatcherConn:Disconnect()
        murdererWatcherConn = nil
    end
end
local function isMurdererFriend(murderer)
    if not murderer then return false end
    local success, result = pcall(function()
        return Players:GetFriendsAsync(localplayer.UserId)
    end)
    if not success then return false end
    local pages = result
    while true do
        for _, entry in ipairs(pages:GetCurrentPage()) do
            if entry.Id == murderer.UserId then
                return true
            end
        end
        if pages.IsFinished then break end
        pages:AdvanceToNextPageAsync()
    end
    return false
end
local function SkidFling(TargetPlayer)
    local Player = localplayer
    local Character = Player.Character
    if not Character then return end
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    if not RootPart then return end
    local TCharacter = TargetPlayer.Character
    if not TCharacter then return end
    local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    local THead = TCharacter:FindFirstChild("Head")
    local Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    local Handle = Accessory and Accessory:FindFirstChild("Handle")
    if Character and Humanoid and RootPart then
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
end
local function flingMurdererAtRoundEnd()
    if not flingMurderEnabled or hasFlingedThisRound then return end
    hasFlingedThisRound = true
    task.spawn(function()
        if isLocalPlayerMurderer() then return end
        getgenv().OldPos = nil
        local murderer = nil
        local deadline = tick() + 5
        repeat
            task.wait(0.3)
            murderer = findMurderer()
        until murderer or tick() > deadline
        if not murderer then return end
        local friendCheckResult = false
        pcall(function()
            friendCheckResult = isMurdererFriend(murderer)
        end)
        if friendCheckResult then
            if autoResetEnabled then
                deadUntilNextRound = true
                local char = localplayer.Character
                if char then
                    local hum = char:FindFirstChild("Humanoid")
                    if hum then hum.Health = 0 end
                end
            end
            return
        end
        isFlingInProgress = true
        flingRetryCount = 0
        while flingRetryCount < MAX_FLING_RETRIES do
            local char = localplayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then
                localplayer.CharacterAdded:Wait()
                task.wait(1)
                char = localplayer.Character
            end
            if not char then break end
            local hum = char:FindFirstChild("Humanoid")
            if hum and hum.Health <= 0 then
                localplayer.CharacterAdded:Wait()
                task.wait(1)
                char = localplayer.Character
                if not char then break end
            end
            if not murderer or not murderer.Parent or not murderer.Character then
                murderer = findMurderer()
                if not murderer then break end
            end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = CFrame.new(13.6, 504.8, -50.2)
                task.wait(0.2)
            end
            local diedDuringFling = false
            local flingDone = false
            local deathConn
            char = localplayer.Character
            if char then
                local h = char:FindFirstChild("Humanoid")
                if h then
                    deathConn = h.Died:Connect(function()
                        diedDuringFling = true
                    end)
                end
            end
            local ok = pcall(SkidFling, murderer)
            if deathConn then deathConn:Disconnect() end
            flingDone = ok
            if diedDuringFling then
                flingRetryCount = flingRetryCount + 1
                localplayer.CharacterAdded:Wait()
                task.wait(1.2)
                murderer = findMurderer()
                if not murderer then break end
            else
                break
            end
        end
        isFlingInProgress = false
    end)
end
local function enableNoclip()
    for _, conn in pairs(noclipConnections) do
        pcall(function() conn:Disconnect() end)
    end
    noclipConnections = {}
    local char = localplayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = false end
    end
    local partAddedConn = char.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("BasePart") then descendant.CanCollide = false end
    end)
    table.insert(noclipConnections, partAddedConn)
    local preSimConn = RunService.PreSimulation:Connect(function()
        if char and char.Parent then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
    table.insert(noclipConnections, preSimConn)
end
local function disableNoclip()
    for _, conn in pairs(noclipConnections) do
        pcall(function() conn:Disconnect() end)
    end
    noclipConnections = {}
    local char = localplayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = true end
    end
end
local function forceServerSync(char)
    if char and char.PrimaryPart then
        char:PivotTo(CFrame.new(char.PrimaryPart.Position))
        char.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
    end
end
local function cancelActiveTween()
    if activeTween then pcall(function() activeTween:Cancel() end) activeTween = nil end
end
local function anchorHRP(hrp, state)
    if hrp then hrp.Anchored = state end
end
local PAD_Y_OFFSET = -3.5
local function createFloatingPad()
    if fakeFloor and fakeFloor.Parent then fakeFloor:Destroy() end
    if padFollowConnection then padFollowConnection:Disconnect(); padFollowConnection = nil end
    local pad = Instance.new("Part")
    pad.Anchored = true
    pad.CanCollide = true
    pad.Size = Vector3.new(10, 1, 10)
    pad.Transparency = 1
    pad.CanQuery = false
    pad.CastShadow = false
    pad.Name = "FloatingPad"
    pad.Parent = Workspace
    fakeFloor = pad
    padFollowConnection = RunService.PreSimulation:Connect(function()
        local char = localplayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp and pad and pad.Parent then
            pad.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y + PAD_Y_OFFSET, hrp.Position.Z)
        end
    end)
end
local function removeInvisibleFloor()
    if padFollowConnection then padFollowConnection:Disconnect(); padFollowConnection = nil end
    if fakeFloor and fakeFloor.Parent then fakeFloor:Destroy() end
    fakeFloor = nil
end
local function isCoinValid(coin)
    if not coin or not coin.Parent then return false end
    if not coin:IsDescendantOf(Workspace) then return false end
    if not coin:IsA("BasePart") then return false end
    local visual = coin:FindFirstChild("CoinVisual")
    if not visual then return false end
    if visual:IsA("BasePart") and visual.Transparency >= 1 then return false end
    return true
end
local function findActiveCoinContainer()
    for _, child in ipairs(Workspace:GetChildren()) do
        local coinContainer = child:FindFirstChild("CoinContainer")
        if coinContainer then return coinContainer, child end
    end
    return nil, nil
end
local function findNearestCoin(hrp)
    local nearest, bestDist = nil, math.huge
    local coinContainer = findActiveCoinContainer()
    if coinContainer then
        for _, coin in ipairs(coinContainer:GetChildren()) do
            if coin:IsA("BasePart") and coin.Name == "Coin_Server" and not visitedCoins[coin] then
                if isCoinValid(coin) then
                    local dist = (hrp.Position - coin.Position).Magnitude
                    if dist < bestDist then bestDist = dist; nearest = coin end
                end
            end
        end
    end
    return nearest
end
local function isRoundActive()
    local coinContainer = findActiveCoinContainer()
    if not coinContainer then return false end
    for _, coin in ipairs(coinContainer:GetChildren()) do
        if coin:IsA("BasePart") and coin.Name == "Coin_Server" and coin:FindFirstChild("CoinVisual") then
            return true
        end
    end
    return false
end
local function allCoinsGone()
    local coinContainer = findActiveCoinContainer()
    if not coinContainer then return true end
    for _, coin in ipairs(coinContainer:GetChildren()) do
        if coin:IsA("BasePart") and coin.Name == "Coin_Server" and coin:FindFirstChild("CoinVisual") then
            return false
        end
    end
    return true
end
local function getActiveMap()
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and obj:FindFirstChild("Spawns") and not obj.Name:lower():find("lobby") then
            return obj
        end
    end
    return nil
end
local function teleportToMap()
    local char = localplayer.Character or localplayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local mapModel = getActiveMap()
    if not mapModel then return false end
    local spawnsFolder = mapModel:FindFirstChild("Spawns")
    if spawnsFolder then
        local spawnPoints = spawnsFolder:GetChildren()
        if #spawnPoints > 0 then
            hrp.CFrame = CFrame.new(spawnPoints[math.random(1, #spawnPoints)].Position + Vector3.new(0, 3, 0))
            forceServerSync(char)
            return true
        end
    end
    if mapModel.PrimaryPart then
        hrp.CFrame = mapModel.PrimaryPart.CFrame + Vector3.new(0, 5, 0)
        forceServerSync(char)
        return true
    end
    return false
end
local function killCharacter()
    local char = localplayer.Character
    if char then
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then humanoid.Health = 0 end
    end
end
local function teleportToLobby()
    local char = localplayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    char.HumanoidRootPart.CFrame = CFrame.new(13.6, 504.8, -50.2)
end
local function lockInLobby()
    if lobbyLockConnection then
        lobbyLockConnection:Disconnect()
        lobbyLockConnection = nil
    end
    local char = localplayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    lobbyLockCFrame = hrp.CFrame
    lobbyLockConnection = RunService.PreSimulation:Connect(function()
        local c = localplayer.Character
        if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        if h and lobbyLockCFrame then
            h.CFrame = lobbyLockCFrame
            h.AssemblyLinearVelocity = Vector3.zero
            h.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end
local function unlockFromLobby()
    if lobbyLockConnection then
        lobbyLockConnection:Disconnect()
        lobbyLockConnection = nil
    end
    lobbyLockCFrame = nil
end
local function lobbyTPFarmMain(hrp)
    if not hrp or waitingForNewMap then return end
    while autoFarm and not deadUntilNextRound and not waitingForNewMap do
        if not isRoundActive() or allCoinsGone() then
            handleRoundEnd(hrp)
            break
        end
        local coin = findNearestCoin(hrp)
        if coin and isCoinValid(coin) then
            visitedCoins[coin] = true
            hrp.CFrame = CFrame.new(coin.Position.X, coin.Position.Y + 2, coin.Position.Z)
            forceServerSync(localplayer.Character)
            task.wait(0.35)
            teleportToLobby()
            task.wait(3.1)
        else
            task.wait(0.2)
        end
    end
end
local function waitForNewMapToLoad()
    waitingForNewMap = true
    local oldMap = getActiveMap()
    while getActiveMap() == oldMap and oldMap and oldMap.Parent do
        task.wait(0.5)
    end
    local timeout = tick() + 60
    while not getActiveMap() and tick() < timeout do
        task.wait(0.5)
    end
    task.wait(2)
    waitingForNewMap = false
    hasFlingedThisRound = false
    flingRetryCount = 0
    isFlingInProgress = false
    return getActiveMap() ~= nil
end
local function doNormalFarm(hrp)
    if not hrp or not hrp.Parent or deadUntilNextRound or waitingForNewMap then return end
    local coin = findNearestCoin(hrp)
    if not coin or not isCoinValid(coin) then
        task.wait(0.1)
        return
    end
    task.wait()
    if not isCoinValid(coin) then
        task.wait(0.05)
        return
    end
    visitedCoins[coin] = true
    local coinPos = Vector3.new(coin.Position.X, coin.Position.Y + 2, coin.Position.Z)
    local tweenTime = math.max((hrp.Position - coinPos).Magnitude / tweenSpeed, 0.1)
    anchorHRP(hrp, false)
    enableNoclip()
    createFloatingPad()
    cancelActiveTween()
    activeTween = TweenService:Create(hrp, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), { CFrame = CFrame.new(coinPos) })
    local coinGone = false
    local watchConn
    watchConn = RunService.Heartbeat:Connect(function()
        if not isCoinValid(coin) then
            coinGone = true
            cancelActiveTween()
            if watchConn then watchConn:Disconnect(); watchConn = nil end
        end
    end)
    activeTween:Play()
    activeTween.Completed:Wait()
    activeTween = nil
    if watchConn then watchConn:Disconnect(); watchConn = nil end
    disableNoclip()
    removeInvisibleFloor()
    forceServerSync(localplayer.Character)
    if coinGone then
        return
    end
    task.wait(0.05)
end
local function doSafe2Farm(hrp)
    if not hrp or not hrp.Parent or deadUntilNextRound or waitingForNewMap then return end
    local coin = findNearestCoin(hrp)
    if not coin or not isCoinValid(coin) then
        task.wait(0.05)
        return
    end
    task.wait()
    if not isCoinValid(coin) then return end
    visitedCoins[coin] = true
    anchorHRP(hrp, false)
    local deepPos = Vector3.new(coin.Position.X, coin.Position.Y + safe2UndergroundOffset, coin.Position.Z)
    local tweenTime = math.max((hrp.Position - deepPos).Magnitude / tweenSpeed, 0.1)
    if tweenTime > 0 then
        enableNoclip()
        createFloatingPad()
        cancelActiveTween()
        activeTween = TweenService:Create(hrp, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), { CFrame = CFrame.new(deepPos) })
        local coinGone = false
        local watchConn
        watchConn = RunService.Heartbeat:Connect(function()
            if not isCoinValid(coin) then
                coinGone = true
                cancelActiveTween()
                if watchConn then watchConn:Disconnect(); watchConn = nil end
            end
        end)
        activeTween:Play()
        activeTween.Completed:Wait()
        activeTween = nil
        if watchConn then watchConn:Disconnect(); watchConn = nil end
        disableNoclip()
        removeInvisibleFloor()
        forceServerSync(localplayer.Character)
        if coinGone then
            anchorHRP(hrp, true)
            return
        end
    end
    if not isCoinValid(coin) then
        anchorHRP(hrp, true)
        return
    end
    local pickupPos = Vector3.new(coin.Position.X, coin.Position.Y + safe2PickupOffsetY, coin.Position.Z)
    hrp.CFrame = CFrame.new(pickupPos)
    task.wait(0.001)
    if not isCoinValid(coin) then
        hrp.CFrame = CFrame.new(deepPos)
        anchorHRP(hrp, true)
        return
    end
    hrp.CFrame = CFrame.new(deepPos)
    anchorHRP(hrp, true)
end
local function applyLayPhysics(hrp)
    if layGyro and layGyro.Parent then layGyro:Destroy() end
    if layVelocity and layVelocity.Parent then layVelocity:Destroy() end
    local char = localplayer.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.PlatformStand = true
        humanoid.AutoRotate = false
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
    end
    for _, v in pairs(hrp:GetChildren()) do
        if v:IsA("BodyVelocity") or v:IsA("BodyGyro") or v:IsA("BodyAngularVelocity") then
            v:Destroy()
        end
    end
    local layTarget = CFrame.new(hrp.Position) * CFrame.Angles(math.rad(90), 0, 0)
    hrp.CFrame = layTarget
    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bg.D = 500
    bg.P = 100000
    bg.CFrame = layTarget
    bg.Parent = hrp
    layGyro = bg
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.Parent = hrp
    layVelocity = bv
end
local function removeLayPhysics()
    if layStabilizeConnection then
        layStabilizeConnection:Disconnect()
        layStabilizeConnection = nil
    end
    if layGyro and layGyro.Parent then layGyro:Destroy() end
    if layVelocity and layVelocity.Parent then layVelocity:Destroy() end
    layGyro = nil
    layVelocity = nil
    local char = localplayer.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.PlatformStand = false
        humanoid.AutoRotate = true
        humanoid.WalkSpeed = 16
        humanoid.JumpPower = 50
    end
end
local function doLayFarm(hrp)
    if not hrp or not hrp.Parent or deadUntilNextRound or waitingForNewMap then return end
    local coin = findNearestCoin(hrp)
    if not coin or not isCoinValid(coin) then
        task.wait(0.1)
        return
    end
    task.wait()
    if not isCoinValid(coin) then
        task.wait(0.05)
        return
    end
    visitedCoins[coin] = true
    anchorHRP(hrp, false)
    local deepPos = Vector3.new(coin.Position.X, coin.Position.Y + layUndergroundOffset, coin.Position.Z)
    local tweenTime = math.max((hrp.Position - deepPos).Magnitude / tweenSpeed, 0.1)
    if tweenTime > 0 then
        applyLayPhysics(hrp)
        if layStabilizeConnection then layStabilizeConnection:Disconnect() end
        layStabilizeConnection = RunService.PreSimulation:Connect(function()
            if layVelocity and layVelocity.Parent then
                layVelocity.Velocity = Vector3.new(0, 0, 0)
            end
            if layGyro and layGyro.Parent and hrp and hrp.Parent then
                layGyro.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(math.rad(90), 0, 0)
            end
        end)
        enableNoclip()
        createFloatingPad()
        cancelActiveTween()
        local targetCFrame = CFrame.new(deepPos) * CFrame.Angles(math.rad(90), 0, 0)
        activeTween = TweenService:Create(hrp, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), { CFrame = targetCFrame })
        local coinGone = false
        local watchConn
        watchConn = RunService.Heartbeat:Connect(function()
            if not isCoinValid(coin) then
                coinGone = true
                cancelActiveTween()
                if watchConn then watchConn:Disconnect(); watchConn = nil end
            end
        end)
        activeTween:Play()
        activeTween.Completed:Wait()
        activeTween = nil
        if watchConn then watchConn:Disconnect(); watchConn = nil end
        if layStabilizeConnection then layStabilizeConnection:Disconnect(); layStabilizeConnection = nil end
        disableNoclip()
        removeInvisibleFloor()
        removeLayPhysics()
        forceServerSync(localplayer.Character)
        if coinGone then
            anchorHRP(hrp, true)
            return
        end
    end
    if not isCoinValid(coin) then
        anchorHRP(hrp, true)
        return
    end
    local pickupPos = Vector3.new(coin.Position.X, coin.Position.Y, coin.Position.Z)
    hrp.CFrame = CFrame.new(pickupPos) * CFrame.Angles(math.rad(90), 0, 0)
    task.wait(0.001)
    if not isCoinValid(coin) then
        hrp.CFrame = CFrame.new(deepPos) * CFrame.Angles(math.rad(90), 0, 0)
        anchorHRP(hrp, true)
        return
    end
    hrp.CFrame = CFrame.new(deepPos) * CFrame.Angles(math.rad(90), 0, 0)
    anchorHRP(hrp, true)
end
local function runFling(flingPos)
    if not flingMurderEnabled or hasFlingedThisRound or isLocalPlayerMurderer() then return end
    hasFlingedThisRound = true
    local murderer = nil
    local deadline = tick() + 5
    repeat
        task.wait(0.3)
        murderer = findMurderer()
    until murderer or tick() > deadline
    if not murderer then return end
    local isFriend = false
    pcall(function() isFriend = isMurdererFriend(murderer) end)
    if isFriend then return end
    isFlingInProgress = true
    flingRetryCount = 0
    while flingRetryCount < MAX_FLING_RETRIES do
        local char = localplayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            localplayer.CharacterAdded:Wait()
            task.wait(1)
            char = localplayer.Character
        end
        if not char then break end
        local hum = char:FindFirstChild("Humanoid")
        if hum and hum.Health <= 0 then
            localplayer.CharacterAdded:Wait()
            task.wait(1)
            char = localplayer.Character
            if not char then break end
        end
        if not murderer or not murderer.Parent or not murderer.Character then
            murderer = findMurderer()
            if not murderer then break end
        end
        if flingPos then
            local fhrp = char:FindFirstChild("HumanoidRootPart")
            if fhrp then
                fhrp.CFrame = flingPos
                task.wait(0.2)
            end
        end
        local diedDuringFling = false
        local deathConn
        char = localplayer.Character
        if char then
            local h = char:FindFirstChild("Humanoid")
            if h then deathConn = h.Died:Connect(function() diedDuringFling = true end) end
        end
        pcall(SkidFling, murderer)
        if deathConn then deathConn:Disconnect() end
        if diedDuringFling then
            flingRetryCount = flingRetryCount + 1
            localplayer.CharacterAdded:Wait()
            task.wait(1.2)
            murderer = findMurderer()
            if not murderer then break end
        else
            break
        end
    end
    isFlingInProgress = false
end
local function handleRoundEnd(hrp)
    cancelActiveTween()
    disableNoclip()
    unlockFromLobby()
    removeLayPhysics()
    visitedCoins = {}
    removeInvisibleFloor()
    anchorHRP(hrp, false)
    deadUntilNextRound = true
    task.spawn(function()
        if autoResetEnabled then
            killCharacter()
            task.spawn(function()
                local deadline = tick() + 3
                while tick() < deadline do
                    task.wait(0.2)
                    local char = localplayer.Character
                    local hum = char and char:FindFirstChild("Humanoid")
                    if not char or not hum or hum.Health <= 0 then return end
                end
                local char = localplayer.Character
                local hum = char and char:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then hum.Health = 0 end
            end)
            if localplayer.Character then
                local hum = localplayer.Character:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    hum.Died:Wait()
                end
            end
            localplayer.CharacterAdded:Wait()
            task.wait(1)
            runFling(CFrame.new(13.6, 504.8, -50.2))
        else
            runFling(nil)
        end
    end)
end
local function normalFarmMain(hrp)
    if not hrp or waitingForNewMap then return end
    while autoFarm and not deadUntilNextRound and not waitingForNewMap do
        if not isRoundActive() or allCoinsGone() then
            handleRoundEnd(hrp)
            break
        end
        doNormalFarm(hrp)
        task.wait()
    end
    anchorHRP(hrp, false)
end
local function layFarmMain(hrp)
    if not hrp or waitingForNewMap then return end
    while autoFarm and not deadUntilNextRound and not waitingForNewMap do
        if not isRoundActive() or allCoinsGone() then
            handleRoundEnd(hrp)
            break
        end
        doLayFarm(hrp)
        task.wait()
    end
    removeLayPhysics()
    removeInvisibleFloor()
    anchorHRP(hrp, false)
end
local function safe2FarmMain(hrp)
    if not hrp or waitingForNewMap then return end
    anchorHRP(hrp, false)
    forceServerSync(localplayer.Character)
    anchorHRP(hrp, true)
    while autoFarm and not deadUntilNextRound and not waitingForNewMap do
        if isRoundActive() then
            doSafe2Farm(hrp)
        end
        if not isRoundActive() or allCoinsGone() then
            handleRoundEnd(hrp)
            break
        end
        task.wait(0.05)
    end
    removeInvisibleFloor()
    anchorHRP(hrp, false)
end
local function enableAntiAfk()
    if antiAfkConnection then return end
    antiAfkConnection = localplayer.Idled:Connect(function()
        if not antiAfkEnabled then return end
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end)
    task.spawn(function()
        while antiAfkConnection do
            task.wait(60)
            if antiAfkEnabled then
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new())
                end)
            end
        end
    end)
end
local function enableAntiFling()
    if antiFlingConnection then return end
    local speaker = localplayer
    antiFlingConnection = RunService.PreSimulation:Connect(function()
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= speaker and player.Character then
                for _, v in pairs(player.Character:GetDescendants()) do
                    if v:IsA("BasePart") then
                        v.CanCollide = false
                    end
                end
            end
        end
    end)
end
local function disableAntiFling()
    if antiFlingConnection then
        antiFlingConnection:Disconnect()
        antiFlingConnection = nil
    end
end
local function customDeathHandler()
    deadUntilNextRound = true
    cancelActiveTween()
    disableNoclip()
    unlockFromLobby()
    visitedCoins = {}
    removeInvisibleFloor()
    if not isFlingInProgress then
        hasFlingedThisRound = false
        flingRetryCount = 0
    end
    getgenv().OldPos = nil
    if localplayer.Character and localplayer.Character:FindFirstChild("HumanoidRootPart") then
        localplayer.Character.HumanoidRootPart.Anchored = false
    end
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
    print("[AutoFarm] Joined mid-round as spectator — waiting for round to end before farming.")
    while autoFarm and isRoundActive() do
        task.wait(0.5)
    end
    if autoFarm then
        waitForNewMapToLoad()
    end
    isSpectatingMidRound = false
    hasFlingedThisRound = false
    isFlingInProgress = false
    visitedCoins = {}
    print("[AutoFarm] Spectator wait done — joining next round.")
end
local function startFarmLoop()
    if farmLoopRunning then return end
    farmLoopRunning = true
    task.spawn(function()
        waitIfSpectatingMidRound()
        if not autoFarm then
            farmLoopRunning = false
            return
        end
        while autoFarm do
            if deadUntilNextRound then
                local char = localplayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then
                    localplayer.CharacterAdded:Wait()
                    task.wait(0.5)
                    char = localplayer.Character
                end
                if char and (farmMode == "Safe" or farmMode == "Lay") then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.CFrame = CFrame.new(-28.3, 338.6, -115.7)
                        task.wait(0.05)
                        lockInLobby()
                    end
                end
                waitForNewMapToLoad()
                unlockFromLobby()
                deadUntilNextRound = false
                visitedCoins = {}
                hasFlingedThisRound = false
                isFlingInProgress = false
                task.wait(1)
                task.wait(0.3)
                continue
            end
            local char = localplayer.Character
            if not char then task.wait(0.5) continue end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local humanoid = char:FindFirstChild("Humanoid")
            if humanoid then
                if humanoidDiedConn then
                    pcall(function() humanoidDiedConn:Disconnect() end)
                end
                humanoidDiedConn = humanoid.Died:Connect(customDeathHandler)
            end
            if not hrp or not humanoid or humanoid.Health <= 0 or deadUntilNextRound or waitingForNewMap then
                task.wait(0.5)
                continue
            end
            if farmMode == "Safe" or farmMode == "Lay" then
                hrp.CFrame = CFrame.new(-28.3, 338.6, -115.7)
                task.wait(0.1)
                lockInLobby()
            end
            local waitStart = tick()
            while autoFarm and not isRoundActive() and not deadUntilNextRound do
                task.wait(0.1)
                if (farmMode == "Safe" or farmMode == "Lay") and not lobbyLockConnection then
                    local c2 = localplayer.Character
                    local h2 = c2 and c2:FindFirstChild("HumanoidRootPart")
                    if h2 then
                        h2.CFrame = CFrame.new(-28.3, 338.6, -115.7)
                        task.wait(0.05)
                        lockInLobby()
                    end
                end
                if tick() - waitStart > 90 then break end
            end
            if farmMode == "Safe" or farmMode == "Lay" then
                unlockFromLobby()
            end
            if not autoFarm or deadUntilNextRound then
                task.wait(0.2)
                continue
            end
            char = localplayer.Character
            if not char then task.wait(0.5) continue end
            hrp = char:FindFirstChild("HumanoidRootPart")
            humanoid = char:FindFirstChild("Humanoid")
            if not hrp or not humanoid or humanoid.Health <= 0 then task.wait(0.5) continue end
            if farmMode == "Safe" then
                local coin = findNearestCoin(hrp)
                if coin and isCoinValid(coin) then
                    hrp.CFrame = CFrame.new(coin.Position.X, coin.Position.Y + safe2UndergroundOffset, coin.Position.Z)
                    forceServerSync(char)
                    task.wait(0.1)
                end
                safe2FarmMain(hrp)
            elseif farmMode == "Lay" then
                local coin = findNearestCoin(hrp)
                if coin and isCoinValid(coin) then
                    hrp.CFrame = CFrame.new(coin.Position.X, coin.Position.Y + layUndergroundOffset, coin.Position.Z) * CFrame.Angles(math.rad(90), 0, 0)
                    forceServerSync(char)
                    task.wait(0.1)
                end
                layFarmMain(hrp)
            else
                normalFarmMain(hrp)
            end
        end
        farmLoopRunning = false
    end)
end
local function onCharacterAdded()
    task.wait(0.5)
    local char = localplayer.Character
    if char then
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then
            if humanoidDiedConn then humanoidDiedConn:Disconnect() end
            humanoidDiedConn = humanoid.Died:Connect(customDeathHandler)
        end
        if autoFarm and not isRoundActive() and (farmMode == "Safe" or farmMode == "Lay") then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = CFrame.new(-28.3, 338.6, -115.7)
                task.wait(0.05)
                lockInLobby()
            end
        end
    end
    if autoResetEnabled and deadUntilNextRound then
        task.spawn(function()
            waitForNewMapToLoad()
            deadUntilNextRound = false
            visitedCoins = {}
            task.wait(1)
            teleportToMap()
        end)
    end
end
localplayer.CharacterAdded:Connect(onCharacterAdded)
Workspace.ChildAdded:Connect(function(child)
    if not autoFarm or deadUntilNextRound then return end
    if child:IsA("Model") and not child.Name:lower():find("lobby") and child:FindFirstChild("Spawns") then
        task.spawn(function()
            task.wait(2)
            if autoFarm and not deadUntilNextRound and not waitingForNewMap then
                teleportToMap()
                task.wait(0.3)
            end
        end)
    end
end)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoFarmGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = localplayer:WaitForChild("PlayerGui")
local frame = Instance.new("Frame")
frame.Name = "MainFrame"
frame.Size = UDim2.new(0, 220, 0, 340)
frame.Position = UDim2.new(0.5, -110, 0.1, 0)
frame.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = screenGui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
titleBar.BorderSizePixel = 0
titleBar.Parent = frame
local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleBar
local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0.5, 0)
titleFix.Position = UDim2.new(0, 0, 0.5, 0)
titleFix.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
titleFix.BorderSizePixel = 0
titleFix.Parent = titleBar
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -44, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Auto Farm"
titleLabel.TextColor3 = Color3.fromRGB(210, 210, 210)
titleLabel.TextSize = 13
titleLabel.Font = Enum.Font.GothamMedium
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 20)
closeBtn.Position = UDim2.new(1, -32, 0.5, -10)
closeBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
closeBtn.TextSize = 11
closeBtn.Font = Enum.Font.GothamMedium
closeBtn.Parent = titleBar
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 5)
closeCorner.Parent = closeBtn
local reopenBtn = Instance.new("TextButton")
reopenBtn.Size = UDim2.new(0, 90, 0, 26)
reopenBtn.Position = UDim2.new(0.5, -45, 0, 8)
reopenBtn.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
reopenBtn.BorderSizePixel = 0
reopenBtn.Text = "Auto Farm"
reopenBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
reopenBtn.TextSize = 11
reopenBtn.Font = Enum.Font.GothamMedium
reopenBtn.Visible = false
reopenBtn.ZIndex = 5
reopenBtn.Parent = screenGui
local reopenCorner = Instance.new("UICorner")
reopenCorner.CornerRadius = UDim.new(0, 7)
reopenCorner.Parent = reopenBtn
closeBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
    reopenBtn.Visible = true
end)
reopenBtn.MouseButton1Click:Connect(function()
    frame.Visible = true
    reopenBtn.Visible = false
end)
local function createToggleRow(parent, labelText, yPos)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -28, 0, 34)
    row.Position = UDim2.new(0, 14, 0, yPos)
    row.BackgroundTransparency = 1
    row.Parent = parent
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -58, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(185, 185, 185)
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    local toggleBg = Instance.new("Frame")
    toggleBg.Size = UDim2.new(0, 44, 0, 24)
    toggleBg.Position = UDim2.new(1, -44, 0.5, -12)
    toggleBg.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    toggleBg.BorderSizePixel = 0
    toggleBg.Parent = row
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggleBg
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = UDim2.new(0, 3, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    knob.BorderSizePixel = 0
    knob.Parent = toggleBg
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = toggleBg
    return btn, toggleBg, knob
end
local function setToggleState(toggleBg, knob, state)
    if state then
        TweenService:Create(toggleBg, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(130, 130, 130) }):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), { Position = UDim2.new(0, 23, 0.5, -9) }):Play()
    else
        TweenService:Create(toggleBg, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(80, 80, 80) }):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), { Position = UDim2.new(0, 3, 0.5, -9) }):Play()
    end
end
local farmBtn, farmBg, farmKnob = createToggleRow(frame, "Enable Auto Farm", 44)
local antiAfkBtn, antiAfkBg, antiAfkKnob = createToggleRow(frame, "Anti AFK", 84)
local resetBtn, resetBg, resetKnob = createToggleRow(frame, "Auto Reset", 124)
local flingBtn, flingBg, flingKnob = createToggleRow(frame, "Fling Murder", 164)
local antiFlingBtn, antiFlingBg, antiFlingKnob = createToggleRow(frame, "Anti Fling", 204)
setToggleState(farmBg, farmKnob, false)
setToggleState(antiAfkBg, antiAfkKnob, false)
setToggleState(resetBg, resetKnob, false)
setToggleState(flingBg, flingKnob, false)
setToggleState(antiFlingBg, antiFlingKnob, false)
local modeRow = Instance.new("Frame")
modeRow.Size = UDim2.new(1, -28, 0, 34)
modeRow.Position = UDim2.new(0, 14, 0, 244)
modeRow.BackgroundTransparency = 1
modeRow.Parent = frame
local modeLabel = Instance.new("TextLabel")
modeLabel.Size = UDim2.new(0, 60, 1, 0)
modeLabel.BackgroundTransparency = 1
modeLabel.Text = "Mode"
modeLabel.TextColor3 = Color3.fromRGB(185, 185, 185)
modeLabel.TextSize = 12
modeLabel.Font = Enum.Font.Gotham
modeLabel.TextXAlignment = Enum.TextXAlignment.Left
modeLabel.Parent = modeRow
local modes = { "Safe", "Normal", "Lay" }
local modeIndex = 1
local modeBtn = Instance.new("TextButton")
modeBtn.Size = UDim2.new(0, 110, 0, 24)
modeBtn.Position = UDim2.new(1, -110, 0.5, -12)
modeBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
modeBtn.BorderSizePixel = 0
modeBtn.Text = modes[modeIndex]
modeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
modeBtn.TextSize = 11
modeBtn.Font = Enum.Font.Gotham
modeBtn.Parent = modeRow
local modeBtnCorner = Instance.new("UICorner")
modeBtnCorner.CornerRadius = UDim.new(0, 6)
modeBtnCorner.Parent = modeBtn
local arrowLabel = Instance.new("TextLabel")
arrowLabel.Size = UDim2.new(0, 16, 1, 0)
arrowLabel.Position = UDim2.new(1, -18, 0, 0)
arrowLabel.BackgroundTransparency = 1
arrowLabel.Text = "v"
arrowLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
arrowLabel.TextSize = 9
arrowLabel.Font = Enum.Font.GothamMedium
arrowLabel.Parent = modeBtn
local dropPanel = Instance.new("Frame")
dropPanel.Size = UDim2.new(0, 110, 0, #modes * 28)
dropPanel.Position = UDim2.new(1, -110, 0, 236)
dropPanel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
dropPanel.BorderSizePixel = 0
dropPanel.ZIndex = 10
dropPanel.Visible = false
dropPanel.Parent = frame
local dropCorner = Instance.new("UICorner")
dropCorner.CornerRadius = UDim.new(0, 6)
dropCorner.Parent = dropPanel
for i, modeName in ipairs(modes) do
    local opt = Instance.new("TextButton")
    opt.Size = UDim2.new(1, 0, 0, 28)
    opt.Position = UDim2.new(0, 0, 0, (i - 1) * 28)
    opt.BackgroundTransparency = 1
    opt.Text = modeName
    opt.TextColor3 = Color3.fromRGB(200, 200, 200)
    opt.TextSize = 11
    opt.Font = Enum.Font.Gotham
    opt.ZIndex = 11
    opt.Parent = dropPanel
    opt.MouseButton1Click:Connect(function()
        modeIndex = i
        farmMode = modeName
        modeBtn.Text = modeName
        arrowLabel.Parent = modeBtn
        dropPanel.Visible = false
    end)
    opt.MouseEnter:Connect(function()
        TweenService:Create(opt, TweenInfo.new(0.1), { BackgroundTransparency = 0.7 }):Play()
        opt.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
    end)
    opt.MouseLeave:Connect(function()
        TweenService:Create(opt, TweenInfo.new(0.1), { BackgroundTransparency = 1 }):Play()
    end)
end
modeBtn.MouseButton1Click:Connect(function()
    dropPanel.Visible = not dropPanel.Visible
end)
local speedRow = Instance.new("Frame")
speedRow.Size = UDim2.new(1, -28, 0, 40)
speedRow.Position = UDim2.new(0, 14, 0, 285)
speedRow.BackgroundTransparency = 1
speedRow.Parent = frame
local speedHeader = Instance.new("Frame")
speedHeader.Size = UDim2.new(1, 0, 0, 16)
speedHeader.BackgroundTransparency = 1
speedHeader.Parent = speedRow
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0.7, 0, 1, 0)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Tween Speed"
speedLabel.TextColor3 = Color3.fromRGB(185, 185, 185)
speedLabel.TextSize = 12
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = speedHeader
local speedVal = Instance.new("TextLabel")
speedVal.Size = UDim2.new(0.3, 0, 1, 0)
speedVal.Position = UDim2.new(0.7, 0, 0, 0)
speedVal.BackgroundTransparency = 1
speedVal.Text = tostring(tweenSpeed)
speedVal.TextColor3 = Color3.fromRGB(200, 200, 200)
speedVal.TextSize = 12
speedVal.Font = Enum.Font.GothamMedium
speedVal.TextXAlignment = Enum.TextXAlignment.Right
speedVal.Parent = speedHeader
local sliderTrack = Instance.new("Frame")
sliderTrack.Size = UDim2.new(1, 0, 0, 4)
sliderTrack.Position = UDim2.new(0, 0, 0, 26)
sliderTrack.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
sliderTrack.BorderSizePixel = 0
sliderTrack.Parent = speedRow
local trackCorner = Instance.new("UICorner")
trackCorner.CornerRadius = UDim.new(1, 0)
trackCorner.Parent = sliderTrack
local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(tweenSpeed / 30, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderTrack
local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = sliderFill
local sliderKnob = Instance.new("Frame")
sliderKnob.Size = UDim2.new(0, 14, 0, 14)
sliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
sliderKnob.Position = UDim2.new(tweenSpeed / 30, 0, 0.5, 0)
sliderKnob.BackgroundColor3 = Color3.fromRGB(210, 210, 210)
sliderKnob.BorderSizePixel = 0
sliderKnob.Parent = sliderTrack
local knobCorner2 = Instance.new("UICorner")
knobCorner2.CornerRadius = UDim.new(1, 0)
knobCorner2.Parent = sliderKnob
local sliderBtn = Instance.new("TextButton")
sliderBtn.Size = UDim2.new(1, 0, 0, 24)
sliderBtn.Position = UDim2.new(0, 0, 0.5, -12)
sliderBtn.BackgroundTransparency = 1
sliderBtn.Text = ""
sliderBtn.Parent = sliderTrack
local sliding = false
local function updateSlider(inputX)
    local trackPos = sliderTrack.AbsolutePosition.X
    local trackSize = sliderTrack.AbsoluteSize.X
    local rel = math.clamp((inputX - trackPos) / trackSize, 0, 1)
    local newSpeed = math.round(rel * 30)
    if newSpeed < 1 then newSpeed = 1 end
    tweenSpeed = newSpeed
    speedVal.Text = tostring(newSpeed)
    sliderFill.Size = UDim2.new(rel, 0, 1, 0)
    sliderKnob.Position = UDim2.new(rel, 0, 0.5, 0)
end
sliderBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliding = true
        updateSlider(input.Position.X)
    end
end)
sliderBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliding = false
    end
end)
game:GetService("UserInputService").InputChanged:Connect(function(input)
    if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateSlider(input.Position.X)
    end
end)
local dragging = false
local dragInput, dragStart, startPos
local function onInputBegan(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end
local function onInputChanged(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end
titleBar.InputBegan:Connect(onInputBegan)
titleBar.InputChanged:Connect(onInputChanged)
game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)
farmBtn.MouseButton1Click:Connect(function()
    autoFarm = not autoFarm
    setToggleState(farmBg, farmKnob, autoFarm)
    if autoFarm then
        deadUntilNextRound = false
        visitedCoins = {}
        startFarmLoop()
    else
        cancelActiveTween()
        disableNoclip()
        unlockFromLobby()
        removeInvisibleFloor()
        local char = localplayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.Anchored = false end
        end
    end
end)
antiAfkBtn.MouseButton1Click:Connect(function()
    antiAfkEnabled = not antiAfkEnabled
    setToggleState(antiAfkBg, antiAfkKnob, antiAfkEnabled)
    if antiAfkEnabled then
        enableAntiAfk()
    else
        if antiAfkConnection then
            antiAfkConnection:Disconnect()
            antiAfkConnection = nil
        end
    end
end)
resetBtn.MouseButton1Click:Connect(function()
    autoResetEnabled = not autoResetEnabled
    setToggleState(resetBg, resetKnob, autoResetEnabled)
end)
flingBtn.MouseButton1Click:Connect(function()
    flingMurderEnabled = not flingMurderEnabled
    setToggleState(flingBg, flingKnob, flingMurderEnabled)
    if not flingMurderEnabled then
        hasFlingedThisRound = false
    end
end)
antiFlingBtn.MouseButton1Click:Connect(function()
    antiFlingEnabled = not antiFlingEnabled
    setToggleState(antiFlingBg, antiFlingKnob, antiFlingEnabled)
    if antiFlingEnabled then
        enableAntiFling()
    else
        disableAntiFling()
    end
end)
getgenv().__MM2FarmCleanup = function()
    autoFarm = false
    farmLoopRunning = false
    if activeTween then pcall(function() activeTween:Cancel() end) activeTween = nil end
    local function safeDisc(conn)
        if conn then pcall(function() conn:Disconnect() end) end
    end
    safeDisc(padFollowConnection)      padFollowConnection = nil
    safeDisc(layStabilizeConnection)   layStabilizeConnection = nil
    safeDisc(antiAfkConnection)        antiAfkConnection = nil
    safeDisc(humanoidDiedConn)         humanoidDiedConn = nil
    safeDisc(antiFlingConnection)      antiFlingConnection = nil
    safeDisc(murdererWatcherConn)      murdererWatcherConn = nil
    safeDisc(lobbyLockConnection)      lobbyLockConnection = nil
    for _, conn in pairs(noclipConnections) do
        pcall(function() conn:Disconnect() end)
    end
    noclipConnections = {}
    if layGyro and layGyro.Parent then pcall(function() layGyro:Destroy() end) end
    if layVelocity and layVelocity.Parent then pcall(function() layVelocity:Destroy() end) end
    if fakeFloor and fakeFloor.Parent then pcall(function() fakeFloor:Destroy() end) end
    layGyro = nil
    layVelocity = nil
    fakeFloor = nil
    local char = Players.LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.Anchored = false end
    end
    local gui = Players.LocalPlayer.PlayerGui:FindFirstChild("AutoFarmGUI")
    if gui then gui:Destroy() end
end
print("MM2 Farm loaded — re-execute anytime to restart cleanly.")