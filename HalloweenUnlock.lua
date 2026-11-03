local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local LP = Players.LocalPlayer

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UnlockGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999
screenGui.IgnoreGuiInset = true
pcall(function() screenGui.Parent = LP:WaitForChild("PlayerGui") end)
if not screenGui.Parent then screenGui.Parent = game:GetService("CoreGui") end

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 250, 0, 230)
mainFrame.Position = UDim2.new(0.5, -125, 0.5, -115)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(70, 70, 70)
stroke.Thickness = 1.5
stroke.Parent = mainFrame

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleBar

local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0, 15)
titleFix.Position = UDim2.new(0, 0, 1, -15)
titleFix.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
titleFix.BorderSizePixel = 0
titleFix.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -16, 1, 0)
titleLabel.Position = UDim2.new(0, 8, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "by unknowuser238183 on tiktok"
titleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
titleLabel.TextSize = 13
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Center
titleLabel.Parent = titleBar

local unlockBtn = Instance.new("TextButton")
unlockBtn.Name = "UnlockBtn"
unlockBtn.Size = UDim2.new(1, -40, 0, 44)
unlockBtn.Position = UDim2.new(0, 20, 0, 52)
unlockBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
unlockBtn.BorderSizePixel = 0
unlockBtn.Text = "Unlock All Tiers"
unlockBtn.TextColor3 = Color3.fromRGB(235, 235, 235)
unlockBtn.TextSize = 16
unlockBtn.Font = Enum.Font.GothamBold
unlockBtn.AutoButtonColor = false
unlockBtn.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = unlockBtn

local btnStroke = Instance.new("UIStroke")
btnStroke.Color = Color3.fromRGB(90, 90, 90)
btnStroke.Thickness = 1
btnStroke.Parent = unlockBtn

local extraBtn = Instance.new("TextButton")
extraBtn.Name = "ExtraBtn"
extraBtn.Size = UDim2.new(1, -40, 0, 44)
extraBtn.Position = UDim2.new(0, 20, 0, 104)
extraBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
extraBtn.BorderSizePixel = 0
extraBtn.Text = "Extra Stuff"
extraBtn.TextColor3 = Color3.fromRGB(235, 235, 235)
extraBtn.TextSize = 16
extraBtn.Font = Enum.Font.GothamBold
extraBtn.AutoButtonColor = false
extraBtn.Parent = mainFrame

local extraCorner = Instance.new("UICorner")
extraCorner.CornerRadius = UDim.new(0, 8)
extraCorner.Parent = extraBtn

local extraStroke = Instance.new("UIStroke")
extraStroke.Color = Color3.fromRGB(90, 90, 90)
extraStroke.Thickness = 1
extraStroke.Parent = extraBtn

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -30, 0, 40)
statusLabel.Position = UDim2.new(0, 15, 0, 160)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Ready"
statusLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
statusLabel.TextSize = 13
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextWrapped = true
statusLabel.Parent = mainFrame

local extraGui = Instance.new("ScreenGui")
extraGui.Name = "ExtraGUI"
extraGui.ResetOnSpawn = false
extraGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
extraGui.DisplayOrder = 1000
extraGui.IgnoreGuiInset = true
pcall(function() extraGui.Parent = LP:WaitForChild("PlayerGui") end)
if not extraGui.Parent then extraGui.Parent = game:GetService("CoreGui") end

local extraFrame = Instance.new("Frame")
extraFrame.Name = "ExtraFrame"
extraFrame.Size = UDim2.new(0, 250, 0, 170)
extraFrame.Position = UDim2.new(0.5, -125, 0.5, -85)
extraFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
extraFrame.BorderSizePixel = 0
extraFrame.Active = true
extraFrame.Visible = false
extraFrame.Parent = extraGui

local extraFrameCorner = Instance.new("UICorner")
extraFrameCorner.CornerRadius = UDim.new(0, 10)
extraFrameCorner.Parent = extraFrame

local extraFrameStroke = Instance.new("UIStroke")
extraFrameStroke.Color = Color3.fromRGB(70, 70, 70)
extraFrameStroke.Thickness = 1.5
extraFrameStroke.Parent = extraFrame

local extraTitleBar = Instance.new("Frame")
extraTitleBar.Name = "TitleBar"
extraTitleBar.Size = UDim2.new(1, 0, 0, 36)
extraTitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
extraTitleBar.BorderSizePixel = 0
extraTitleBar.Parent = extraFrame

local extraTitleCorner = Instance.new("UICorner")
extraTitleCorner.CornerRadius = UDim.new(0, 10)
extraTitleCorner.Parent = extraTitleBar

local extraTitleFix = Instance.new("Frame")
extraTitleFix.Size = UDim2.new(1, 0, 0, 15)
extraTitleFix.Position = UDim2.new(0, 0, 1, -15)
extraTitleFix.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
extraTitleFix.BorderSizePixel = 0
extraTitleFix.Parent = extraTitleBar

local extraTitleLabel = Instance.new("TextLabel")
extraTitleLabel.Size = UDim2.new(1, -16, 1, 0)
extraTitleLabel.Position = UDim2.new(0, 8, 0, 0)
extraTitleLabel.BackgroundTransparency = 1
extraTitleLabel.Text = "Extra Stuff"
extraTitleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
extraTitleLabel.TextSize = 14
extraTitleLabel.Font = Enum.Font.GothamBold
extraTitleLabel.TextXAlignment = Enum.TextXAlignment.Center
extraTitleLabel.Parent = extraTitleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -30, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.AutoButtonColor = false
closeBtn.Parent = extraTitleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

local farmBtn = Instance.new("TextButton")
farmBtn.Name = "FarmBtn"
farmBtn.Size = UDim2.new(1, -40, 0, 44)
farmBtn.Position = UDim2.new(0, 20, 0, 52)
farmBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
farmBtn.BorderSizePixel = 0
farmBtn.Text = "Auto Farm Script By Me"
farmBtn.TextColor3 = Color3.fromRGB(235, 235, 235)
farmBtn.TextSize = 14
farmBtn.Font = Enum.Font.GothamBold
farmBtn.AutoButtonColor = false
farmBtn.Parent = extraFrame

local farmCorner = Instance.new("UICorner")
farmCorner.CornerRadius = UDim.new(0, 8)
farmCorner.Parent = farmBtn

local farmStroke = Instance.new("UIStroke")
farmStroke.Color = Color3.fromRGB(90, 90, 90)
farmStroke.Thickness = 1
farmStroke.Parent = farmBtn

local extraStatus = Instance.new("TextLabel")
extraStatus.Name = "ExtraStatus"
extraStatus.Size = UDim2.new(1, -30, 0, 40)
extraStatus.Position = UDim2.new(0, 15, 0, 104)
extraStatus.BackgroundTransparency = 1
extraStatus.Text = "Ready"
extraStatus.TextColor3 = Color3.fromRGB(170, 170, 170)
extraStatus.TextSize = 13
extraStatus.Font = Enum.Font.Gotham
extraStatus.TextWrapped = true
extraStatus.Parent = extraFrame

local dragging, dragInput, dragStart, startPos
local function makeDraggable(frame, handle)
    handle = handle or frame
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
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
makeDraggable(mainFrame, titleBar)
makeDraggable(extraFrame, extraTitleBar)

local function setStatus(text, color)
    statusLabel.Text = text
    statusLabel.TextColor3 = color or Color3.fromRGB(170, 170, 170)
    print("[Unlock] " .. text)
end

local function setExtraStatus(text, color)
    extraStatus.Text = text
    extraStatus.TextColor3 = color or Color3.fromRGB(170, 170, 170)
    print("[Extra] " .. text)
end

local CONFIG = {
    UnlockBattlePass = true,
    CompleteQuests   = true,
    QuestRewards     = true,
    GrantFinalReward = true,
    Popups           = true,
}

local function runUnlock()
    local Event
    local ok, err = pcall(function()
        local EventInfo = require(RS:WaitForChild("SharedServices"):WaitForChild("EventInfoService"))
        EventInfo = EventInfo:WaitForInitializedAsync() or EventInfo
        Event = EventInfo:GetMainEvent()
    end)
    if not ok or not Event then
        return setStatus("No live event found", Color3.fromRGB(220, 90, 90))
    end

    local ProfileData = require(RS:WaitForChild("Modules"):WaitForChild("ProfileData"))
    local ItemPopup = require(RS:WaitForChild("ClientServices"):WaitForChild("ItemPopupService"))
    local InventoryRemotes = RS:WaitForChild("Remotes"):WaitForChild("Inventory")
    local InventoryDataChanged = InventoryRemotes:WaitForChild("InventoryDataChanged")
    local ProfileDataChanged = InventoryRemotes:WaitForChild("ProfileDataChanged")
    local UpdateDataClient = RS:WaitForChild("UpdateDataClient")
    local EventRemotes = RS:WaitForChild("Remotes"):WaitForChild("Events"):WaitForChild(Event.Title .. "Remotes")

    local Info = Event.EventStartInfo
    local Pass = Info.BattlePass
    local Mine = ProfileData[Event.Title]
    if not Mine then
        return setStatus("Open the event once, then retry", Color3.fromRGB(220, 180, 90))
    end
    Mine.ClaimedRewards = Mine.ClaimedRewards or {}
    Mine.Quests = Mine.Quests or {}

    local COUNTED = { Weapons = true, Pets = true, Materials = true }

    local function give(itemId, itemType, amount)
        if not itemId or not itemType then return end
        amount = amount or 1
        local bucket = ProfileData[itemType]
        if type(bucket) ~= "table" then return end
        bucket.Owned = bucket.Owned or {}
        local newValue
        if COUNTED[itemType] then
            newValue = (bucket.Owned[itemId] or 0) + amount
            bucket.Owned[itemId] = newValue
        else
            if not table.find(bucket.Owned, itemId) then table.insert(bucket.Owned, itemId) end
            newValue = amount
        end
        pcall(function() InventoryDataChanged:Fire(itemType, itemId, newValue) end)
        pcall(function() UpdateDataClient:Fire(false, ProfileData) end)
        if CONFIG.Popups then
            pcall(function() ItemPopup:AddNewItem(itemId, itemType, amount) end)
        end
    end

    local function refreshEventPages()
        pcall(function() ProfileDataChanged:Fire(Event.Title, Mine) end)
    end

    local function fireClient(remote, ...)
        if not remote then return false end
        local args = table.pack(...)
        if firesignal then
            return (pcall(firesignal, remote.OnClientEvent, table.unpack(args, 1, args.n)))
        end
        if getconnections then
            local any = false
            for _, c in ipairs(getconnections(remote.OnClientEvent)) do
                local fn = c.Function
                if fn then
                    task.spawn(fn, table.unpack(args, 1, args.n))
                    any = true
                end
            end
            return any
        end
        return false
    end

    local function tierReward(key)
        local r = Pass.Rewards and Pass.Rewards[key]
        if not r then return nil end
        return r.ItemID, r.ItemType, (r.Amount and r.Amount > 0) and r.Amount or 1
    end

    local function claimTier(key)
        key = tostring(key)
        if Mine.ClaimedRewards[key] then return end
        Mine.ClaimedRewards[key] = true
        local id, kind, amount = tierReward(key)
        give(id, kind, amount)
        refreshEventPages()
    end

    local function showFinalClaimed()
        pcall(function()
            local gui = LP.PlayerGui:FindFirstChild("CrossPlatform"):FindFirstChild(Event.Title)
            local right = gui.MainEvent.Main.FinalReward.Right
            right.LockText.Visible = false
            right.ClaimAmountText.Text = ("%dx CLAIMED"):format(Mine.FinalRewardClaimAmount or 1)
            right.ClaimAmountText.Visible = true
            local label = right.Claim:FindFirstChild("TextLabel", true)
            if label then label.Text = "CLAIMED" end
        end)
    end

    local function grantFinal()
        Mine.FinalRewardClaimAmount = (Mine.FinalRewardClaimAmount or 0) + 1
        give(Pass.FinalReward, Pass.FinalRewardType or "Weapons", 1)
        showFinalClaimed()
        refreshEventPages()
    end

    local function completeQuests()
        local quests = Info.Quests or {}
        local questRemote = EventRemotes:FindFirstChild("EventQuestProgressed")
        local done = 0
        for id, q in pairs(quests) do
            local steps = q.Quests or {}
            local goal = steps[#steps] and steps[#steps].ChallengeAmount or 1
            local had = Mine.Quests[id] and Mine.Quests[id].Progress or 0
            if had < goal then
                Mine.Quests[id] = Mine.Quests[id] or {}
                Mine.Quests[id].Progress = goal
                if CONFIG.QuestRewards then
                    for _, step in ipairs(steps) do
                        if (step.ChallengeAmount or 0) > had and step.RewardID then
                            give(step.RewardID, step.RewardType, step.RewardAmount or 1)
                        end
                    end
                end
                fireClient(questRemote, id, goal)
                done = done + 1
            end
        end
        return done
    end

    local HANDLERS = {
        ClaimBattlePassReward = function(key) claimTier(key) end,
        BuyBattlePassFinalReward = function() grantFinal() end,
        BuyBattlePassTiers = function(n)
            Mine.CurrentTier = math.min((Mine.CurrentTier or 1) + (tonumber(n) or 1), Pass.TotalTiers)
            refreshEventPages()
        end,
    }

    local hooked = false
    if hookmetamethod and getnamecallmethod then
        local old
        old = hookmetamethod(game, "__namecall", function(self, ...)
            if not checkcaller() and getnamecallmethod() == "FireServer"
                and typeof(self) == "Instance" and self.Parent == EventRemotes then
                local handler = HANDLERS[self.Name]
                if handler then
                    local args = { ... }
                    task.spawn(function() handler(table.unpack(args)) end)
                    return nil
                end
            end
            return old(self, ...)
        end)
        hooked = true
    end

    if CONFIG.UnlockBattlePass then
        Mine.CurrentTier = Pass.TotalTiers
        refreshEventPages()
    end

    local questCount = 0
    if CONFIG.CompleteQuests then questCount = completeQuests() end

    if CONFIG.GrantFinalReward and (Mine.FinalRewardClaimAmount or 0) < 1 then
        grantFinal()
    end

    if not hooked and CONFIG.UnlockBattlePass then
        for key in pairs(Pass.Rewards or {}) do
            if tonumber(key) ~= Pass.TotalTiers then claimTier(key) end
        end
    end

    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Unlock",
            Text = "Successfully Unlocked All Tiers",
            Duration = 5
        })
    end)
    setStatus("Successfully Unlocked All Tiers", Color3.fromRGB(120, 220, 120))
end

unlockBtn.MouseButton1Click:Connect(function()
    unlockBtn.Text = "Working..."
    unlockBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    setStatus("Unlocking...", Color3.fromRGB(220, 220, 120))
    task.spawn(function()
        local success, err = pcall(runUnlock)
        if not success then
            setStatus("Error: " .. tostring(err), Color3.fromRGB(220, 90, 90))
        end
        unlockBtn.Text = "Unlock All Tiers"
        unlockBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    end)
end)

unlockBtn.MouseEnter:Connect(function()
    unlockBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
end)
unlockBtn.MouseLeave:Connect(function()
    if unlockBtn.Text == "Unlock All Tiers" then
        unlockBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    end
end)

extraBtn.MouseButton1Click:Connect(function()
    extraFrame.Visible = not extraFrame.Visible
end)

extraBtn.MouseEnter:Connect(function()
    extraBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
end)
extraBtn.MouseLeave:Connect(function()
    extraBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
end)

closeBtn.MouseButton1Click:Connect(function()
    extraFrame.Visible = false
end)

closeBtn.MouseEnter:Connect(function()
    closeBtn.BackgroundColor3 = Color3.fromRGB(220, 80, 80)
end)
closeBtn.MouseLeave:Connect(function()
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
end)

farmBtn.MouseButton1Click:Connect(function()
    farmBtn.Text = "Loading..."
    farmBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    setExtraStatus("Loading Auto Farm...", Color3.fromRGB(220, 220, 120))
    task.spawn(function()
        local success, err = pcall(function()
            loadstring(game:HttpGet('https://raw.githubusercontent.com/Johnnyissocoollol/halloween/refs/heads/main/m2.lua'))()
        end)
        if success then
            setExtraStatus("Auto Farm Loaded", Color3.fromRGB(120, 220, 120))
        else
            setExtraStatus("Farm load failed: " .. tostring(err), Color3.fromRGB(220, 90, 90))
        end
        farmBtn.Text = "Auto Farm Script By Me"
        farmBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    end)
end)

farmBtn.MouseEnter:Connect(function()
    farmBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
end)
farmBtn.MouseLeave:Connect(function()
    if farmBtn.Text == "Auto Farm Script By Me" then
        farmBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    end
end)
