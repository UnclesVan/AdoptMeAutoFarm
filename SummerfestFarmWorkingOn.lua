--!strict
print("Script Version: 2025-07-07_ConsolidatedUIAndTreasureAndCannon_v70_FIXED_V7") -- Updated version for clarity

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local UserInputService = game:GetService("UserInputService")
local workspace = game:GetService("Workspace")

-- Global state variables
local scriptEnabled: boolean = false
local currentActivePageName: string = "Log" -- Default page

-- UI elements that need to be accessed by logic
local consoleTextLabel: TextLabel?
local cc_statusLabel: TextLabel?
local td_statusLabel: TextLabel?

-- Initialize tables for connections and parts
local cc_timerConnections: {RBXScriptConnection} = {}
local cc_allPileInteractionParts: {BasePart} = {} -- Assuming BasePart or specific Part types
local cc_allCannonInteractionParts: {BasePart} = {}
local cc_reloadPart: BasePart?

-- Custom logging function for the UI console
local function logToConsole(...)
    local message = table.concat({...}, "\t")
    
    print(message) -- Print to Roblox Output (F9 console) for general debugging

    if consoleTextLabel then
        local timeStamp = os.date("%H:%M:%S")
        consoleTextLabel.Text = consoleTextLabel.Text .. "\n[" .. timeStamp .. "] " .. message
        
        if consoleTextLabel.Parent and consoleTextLabel.Parent:IsA("ScrollingFrame") then
            task.defer(function()
                consoleTextLabel.Parent.CanvasPosition = Vector2.new(0, consoleTextLabel.Parent.CanvasSize.Y.Offset)
            end)
        end
    end
end

--- Placeholder Functions (YOU MUST IMPLEMENT THESE)
local function cc_parseTimeToSeconds(timeString: string): number
    local parts = {}
    for part in string.gmatch(timeString, "%d+") do
        table.insert(parts, tonumber(part))
    end

    local totalSeconds = 0
    if #parts == 2 then -- MM:SS
        totalSeconds = (parts[1] * 60) + parts[2]
    elseif #parts == 3 then -- HH:MM:SS or similar
        totalSeconds = (parts[1] * 3600) + (parts[2] * 60) + parts[3]
    end
    return totalSeconds
end

local function cc_teleportPlayer(partToTeleportTo: BasePart, forceTeleport: boolean)
    if player and player.Character then
        logToConsole(string.format("Attempting to teleport player to %s (Force: %s)", partToTeleportTo.Name, tostring(forceTeleport)))
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local newCFrame = partToTeleportTo.CFrame * CFrame.new(0, 5, 0)
            player.Character:SetPrimaryPartCFrame(newCFrame)
            logToConsole(string.format("Teleported player to %s", partToTeleportTo.Name))
        else
            warn("HumanoidRootPart not found for teleport.")
            logToConsole("Error: HumanoidRootPart not found for teleport.")
        end
    else
        warn("Player character not found for teleport.")
        logToConsole("Error: Player character not found for teleport.")
    end
end

local cc_hasInstantlyTeleportedByTimer: boolean = false

--- Modules for Game Logic
local CannonCircleModule = {
    cc_isActive = false,
    cc_isRunning = false,

    start = function()
        if CannonCircleModule.cc_isRunning then return end
        logToConsole("CannonCircle start()")
        CannonCircleModule.cc_isActive = true
        CannonCircleModule.cc_isRunning = true;

        if cc_statusLabel then
            cc_statusLabel.Text = "Status: Running"
            cc_statusLabel.TextColor3 = Color3.new(0, 1, 0)
        end
        logToConsole("CannonCircle module started its internal logic.")
    end,

    stop = function()
        if not CannonCircleModule or not CannonCircleModule.cc_isRunning then return end
        logToConsole("CannonCircle stop()")
        CannonCircleModule.cc_isActive = false
        CannonCircleModule.cc_isRunning = false;

        for _, c in ipairs(cc_timerConnections) do
            c:Disconnect()
        end
        table.clear(cc_timerConnections)

        if cc_statusLabel then
            cc_statusLabel.Text = "Status: Stopped"
            cc_statusLabel.TextColor3 = Color3.new(1, 0, 0)
        end
        logToConsole("CannonCircle module stopped its internal logic.")
    end,
}

local TreasureDefenceModule = {
    td_isActive = false,
    td_isRunning = false,

    start = function()
        if TreasureDefenceModule.td_isRunning then return end
        logToConsole("TreasureDefence start()")
        TreasureDefenceModule.td_isActive = true
        TreasureDefenceModule.td_isRunning = true;

        if td_statusLabel then
            td_statusLabel.Text = "Status: Running"
            td_statusLabel.TextColor3 = Color3.new(0, 1, 0)
        end
        logToConsole("TreasureDefence module started its internal logic.")
    end,

    stop = function()
        if not TreasureDefenceModule or not TreasureDefenceModule.td_isRunning then return end
        logToConsole("TreasureDefence stop()")
        TreasureDefenceModule.td_isActive = false
        TreasureDefenceModule.td_isRunning = false;

        if td_statusLabel then
            td_statusLabel.Text = "Status: Stopped"
            td_statusLabel.TextColor3 = Color3.new(1, 0, 0)
        end
        logToConsole("TreasureDefence module stopped its internal logic.")
    end,
}

--- UI Creation
local function createUI(): ScreenGui
    local mainGui = Instance.new("ScreenGui")
    mainGui.Name = "MainConsole"

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.6, 0, 0.5, 0)
    frame.Position = UDim2.new(0.2, 0, 0.25, 0)
    frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.new(1, 1, 1)
    frame.Parent = mainGui

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    header.Active = true
    header.Parent = frame

    -- Draggable header
    local function makeDraggable(guiObj: GuiObject, target: GuiObject)
        local dragging = false
        local dragStart: Vector2
        local startPos: UDim2

        guiObj.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = target.Position
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
    end
    makeDraggable(header, frame)

    -- Toggle Script Button
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 120, 1, 0)
    toggleBtn.Position = UDim2.new(0, 5, 0, 0)
    toggleBtn.BackgroundColor3 = Color3.new(0.2, 0.2, 0.8)
    toggleBtn.Text = "Script: OFF"
    toggleBtn.TextColor3 = Color3.new(1, 1, 1)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.FontSize = Enum.FontSize.Size14
    toggleBtn.TextSize = 18
    toggleBtn.Parent = header

    local function updateToggleUI()
        if scriptEnabled then
            toggleBtn.Text = "Script: ON"
            toggleBtn.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
        else
            toggleBtn.Text = "Script: OFF"
            toggleBtn.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
        end
    end
    updateToggleUI()

    toggleBtn.MouseButton1Click:Connect(function()
        scriptEnabled = not scriptEnabled
        updateToggleUI()
        if scriptEnabled then
            logToConsole("Main script ENABLED")
            if CannonCircleModule.cc_isActive then
                task.spawn(CannonCircleModule.start)
            end
            if TreasureDefenceModule.td_isActive then
                task.spawn(TreasureDefenceModule.start)
            end
            initTimers()
        else
            logToConsole("Main script DISABLED")
            CannonCircleModule.stop()
            TreasureDefenceModule.stop()
            for _, c in ipairs(cc_timerConnections) do
                c:Disconnect()
            end
            table.clear(cc_timerConnections)
        end
    })

    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 50, 1, 0)
    closeBtn.Position = UDim2.new(1, -55, 0, 0)
    closeBtn.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.FontSize = Enum.FontSize.Size14
    closeBtn.TextSize = 24
    closeBtn.Parent = header
    closeBtn.MouseButton1Click:Connect(function()
        CannonCircleModule.stop()
        TreasureDefenceModule.stop()
        for _, c in ipairs(cc_timerConnections) do
            c:Disconnect()
        end
        table.clear(cc_timerConnections)
        logToConsole("Closed UI and stopped all modules.")
        mainGui:Destroy()
    end)

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -120 - 55 - 10, 1, 0)
    title.Position = UDim2.new(0, 120 + 5 + 10, 0, 0)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Text = "SummerFest 2025: CannonCircle & TreasureDefence"
    title.Font = Enum.Font.GothamBold
    title.FontSize = Enum.FontSize.Size18
    title.TextSize = 22
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.TextYAlignment = Enum.TextYAlignment.Center
    title.TextScaled = true
    title.Parent = header

    -- Content Frame
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -10, 1, -55)
    content.Position = UDim2.new(0, 5, 0, 55)
    content.BackgroundTransparency = 1
    content.Parent = frame

    -- Create pages
    local pageNames = {"Log", "Changelog", "CannonCircle", "TreasureDefence", "CircleTimers"}
    local pageFrames: {[string]: Frame} = {}

    local function createPage(name: string): Frame
        local p = Instance.new("Frame")
        p.Name = name
        p.Size = UDim2.new(1, 0, 1, 0)
        p.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
        p.BorderSizePixel = 1
        p.BorderColor3 = Color3.new(0.5, 0.5, 0.5)
        p.Visible = false
        p.Parent = content
        return p
    end

    for _, name in ipairs(pageNames) do
        pageFrames[name] = createPage(name)
    end

    -- Setup Log page content
    local logScroll = Instance.new("ScrollingFrame")
    logScroll.Size = UDim2.new(1, 0, 1, 0)
    logScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    logScroll.BackgroundTransparency = 1
    logScroll.ScrollBarImageColor3 = Color3.new(0.7, 0.7, 0.7)
    logScroll.ScrollBarThickness = 8
    logScroll.Parent = pageFrames["Log"]

    local logText = Instance.new("TextLabel")
    logText.Size = UDim2.new(1, 0, 0, 0)
    logText.Position = UDim2.new(0, 0, 0, 0)
    logText.BackgroundTransparency = 1
    logText.TextColor3 = Color3.new(1, 1, 1)
    logText.TextXAlignment = Enum.TextXAlignment.Left
    logText.TextYAlignment = Enum.TextYAlignment.Top
    logText.TextWrapped = true
    logText.Font = Enum.Font.Code
    logText.FontSize = Enum.FontSize.Size14
    logText.Text = "Console Log:\n"
    logText.AutomaticSize = Enum.AutomaticSize.Y
    logText.Parent = logScroll
    consoleTextLabel = logText

    -- Setup Changelog page content
    local changelogText = Instance.new("TextLabel")
    changelogText.Size = UDim2.new(1, 0, 1, 0)
    changelogText.BackgroundTransparency = 1
    changelogText.TextColor3 = Color3.new(1, 1, 1)
    changelogText.TextXAlignment = Enum.TextXAlignment.Left
    changelogText.TextYAlignment = Enum.TextYAlignment.Top
    changelogText.TextWrapped = true
    changelogText.Font = Enum.Font.SourceSans
    changelogText.FontSize = Enum.FontSize.Size14
    changelogText.Text = "Changelog:\n- Initial UI setup.\n- Added draggable frame.\n- Implemented page navigation.\n- Integrated module toggles.\n- Fixed strict type errors and undefined globals."
    changelogText.AutomaticSize = Enum.AutomaticSize.Y
    changelogText.Parent = pageFrames["Changelog"] -- Ensure text is parented

    local changelogUIList = Instance.new("UIListLayout") -- FIX: Create UIListLayout WITHOUT parenting immediately
    changelogUIList.FillDirection = Enum.FillDirection.Vertical
    changelogUIList.HorizontalAlignment = Enum.HorizontalAlignment.Left
    changelogUIList.Padding = UDim.new(0, 5)
    changelogUIList.Parent = changelogText -- FIX: THEN parent it to changelogText

    -- Setup CannonCircle page content
    local ccPage = pageFrames["CannonCircle"]
    local ccStatusTitle = Instance.new("TextLabel")
    ccStatusTitle.Size = UDim2.new(1, 0, 0, 30)
    ccStatusTitle.Position = UDim2.new(0, 0, 0, 10)
    ccStatusTitle.BackgroundTransparency = 1
    ccStatusTitle.TextColor3 = Color3.new(1, 1, 1)
    ccStatusTitle.Text = "Cannon Circle Module"
    ccStatusTitle.Font = Enum.Font.GothamBold
    ccStatusTitle.FontSize = Enum.FontSize.Size18
    ccStatusTitle.TextSize = 20
    ccStatusTitle.Parent = ccPage

    local ccStatusLabelInstance = Instance.new("TextLabel")
    ccStatusLabelInstance.Size = UDim2.new(1, 0, 0, 30)
    ccStatusLabelInstance.Position = UDim2.new(0, 0, 0, 50)
    ccStatusLabelInstance.BackgroundTransparency = 1
    ccStatusLabelInstance.TextColor3 = Color3.new(1, 0, 0)
    ccStatusLabelInstance.Text = "Status: Stopped"
    ccStatusLabelInstance.Font = Enum.Font.Gotham
    ccStatusLabelInstance.FontSize = Enum.FontSize.Size14
    ccStatusLabelInstance.Parent = ccPage
    cc_statusLabel = ccStatusLabelInstance

    local ccToggleBtn = Instance.new("TextButton")
    ccToggleBtn.Size = UDim2.new(0, 150, 0, 40)
    ccToggleBtn.Position = UDim2.new(0.5, -75, 0.5, 0)
    ccToggleBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    ccToggleBtn.Text = "Toggle Cannon Circle"
    ccToggleBtn.TextColor3 = Color3.new(1,1,1)
    ccToggleBtn.Font = Enum.Font.GothamBold
    ccToggleBtn.FontSize = Enum.FontSize.Size14
    ccToggleBtn.Parent = ccPage
    ccToggleBtn.MouseButton1Click:Connect(function()
        CannonCircleModule.cc_isActive = not CannonCircleModule.cc_isActive
        if CannonCircleModule.cc_isActive and scriptEnabled then
            task.spawn(CannonCircleModule.start)
        else
            CannonCircleModule.stop()
        end
    end)
    if CannonCircleModule.cc_isActive then
        cc_statusLabel.Text = "Status: Running"
        cc_statusLabel.TextColor3 = Color3.new(0, 1, 0)
    else
        cc_statusLabel.Text = "Status: Stopped"
        cc_statusLabel.TextColor3 = Color3.new(1, 0, 0)
    end


    -- Setup TreasureDefence page content
    local tdPage = pageFrames["TreasureDefence"]
    local tdStatusTitle = Instance.new("TextLabel")
    tdStatusTitle.Size = UDim2.new(1, 0, 0, 30)
    tdStatusTitle.Position = UDim2.new(0, 0, 0, 10)
    tdStatusTitle.BackgroundTransparency = 1
    tdStatusTitle.TextColor3 = Color3.new(1, 1, 1)
    tdStatusTitle.Text = "Treasure Defence Module"
    tdStatusTitle.Font = Enum.Font.GothamBold
    tdStatusTitle.FontSize = Enum.FontSize.Size18
    tdStatusTitle.TextSize = 20
    tdStatusTitle.Parent = tdPage

    local tdStatusLabelInstance = Instance.new("TextLabel")
    tdStatusLabelInstance.Size = UDim2.new(1, 0, 0, 30)
    tdStatusLabelInstance.Position = UDim2.new(0, 0, 0, 50)
    tdStatusLabelInstance.BackgroundTransparency = 1
    tdStatusLabelInstance.TextColor3 = Color3.new(1, 0, 0)
    tdStatusLabelInstance.Text = "Status: Stopped"
    tdStatusLabelInstance.Font = Enum.Font.Gotham
    tdStatusLabelInstance.FontSize = Enum.FontSize.Size14
    tdStatusLabelInstance.Parent = tdPage
    td_statusLabel = tdStatusLabelInstance

    local tdToggleBtn = Instance.new("TextButton")
    tdToggleBtn.Size = UDim2.new(0, 150, 0, 40)
    tdToggleBtn.Position = UDim2.new(0.5, -75, 0.5, 0)
    tdToggleBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    tdToggleBtn.Text = "Toggle Treasure Defence"
    tdToggleBtn.TextColor3 = Color3.new(1,1,1)
    tdToggleBtn.Font = Enum.Font.GothamBold
    tdToggleBtn.FontSize = Enum.FontSize.Size14
    tdToggleBtn.Parent = tdPage
    tdToggleBtn.MouseButton1Click:Connect(function()
        TreasureDefenceModule.td_isActive = not TreasureDefenceModule.td_isActive
        if TreasureDefenceModule.td_isActive and scriptEnabled then
            task.spawn(TreasureDefenceModule.start)
        else
            TreasureDefenceModule.stop()
        end
    end)
    if TreasureDefenceModule.td_isActive then
        td_statusLabel.Text = "Status: Running"
        td_statusLabel.TextColor3 = Color3.new(0, 1, 0)
    else
        td_statusLabel.Text = "Status: Stopped"
        td_statusLabel.TextColor3 = Color3.new(1, 0, 0)
    end

    -- Setup CircleTimers page content (placeholder)
    local circleTimersPage = pageFrames["CircleTimers"]
    local timersTitle = Instance.new("TextLabel")
    timersTitle.Size = UDim2.new(1, 0, 0, 30)
    timersTitle.Position = UDim2.new(0, 0, 0, 10)
    timersTitle.BackgroundTransparency = 1
    timersTitle.TextColor3 = Color3.new(1, 1, 1)
    timersTitle.Text = "Active Circle Timers (Logs to Console)"
    timersTitle.Font = Enum.Font.GothamBold
    timersTitle.FontSize = Enum.FontSize.Size18
    timersTitle.TextSize = 20
    timersTitle.Parent = circleTimersPage

    -- Dropdown for page selection
    local function createPageDropdown(headerFrame: Frame, pagesList: {string}, pagesMap: {[string]: Frame}): TextButton
        local dropdownBtn = Instance.new("TextButton")
        dropdownBtn.Size = UDim2.new(0, 150, 1, 0)
        dropdownBtn.Position = UDim2.new(0, 120 + 5 + 10, 0, 0)
        dropdownBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
        dropdownBtn.Text = "Select Page"
        dropdownBtn.TextColor3 = Color3.new(1, 1, 1)
        dropdownBtn.Font = Enum.Font.GothamBold
        dropdownBtn.FontSize = Enum.FontSize.Size14
        dropdownBtn.ZIndex = 2
        dropdownBtn.Parent = headerFrame

        local optionFrame = Instance.new("Frame")
        optionFrame.Size = UDim2.new(0, 150, 0, #pagesList * 30)
        optionFrame.Position = UDim2.new(dropdownBtn.Position.X.Scale, dropdownBtn.Position.X.Offset, 1, 0)
        optionFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        optionFrame.Visible = false
        optionFrame.ClipsDescendants = true
        optionFrame.ZIndex = 3
        optionFrame.Parent = headerFrame

        local uiLayout -- Declare it first to avoid type issues if Instance.new returns nil

        -- Debugging checks for UIListLayout creation
        print("--- Debugging UIListLayout creation in dropdown ---")
        print("Script path:", script:GetFullName())
        print("Is this a LocalScript?", script:IsA("LocalScript"))
        print("Parent of optionFrame:", optionFrame.Parent)
        print("Parent of optionFrame type:", typeof(optionFrame.Parent))

        uiLayout = Instance.new("UIListLayout") -- Line 345 (or nearby, based on exact formatting)
        
        -- Check if uiLayout was actually created
        if uiLayout == nil then
            warn("CRITICAL ERROR: Instance.new('UIListLayout') returned nil in dropdown! This indicates a problem with the script's environment or type.")
            logToConsole("CRITICAL ERROR: Failed to create UIListLayout for dropdown. UI will not function correctly.")
            return dropdownBtn -- Exit the function early as UI is fundamentally broken
        end
        print("UIListLayout created successfully in dropdown:", typeof(uiLayout)) -- If this prints, it means the next lines are the issue

        uiLayout.FillDirection = Enum.FillDirection.Vertical
        uiLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left -- Line 346 (assuming no other lines were added/removed)
        uiLayout.Padding = UDim.new(0, 0)
        uiLayout.SortOrder = Enum.SortOrder.LayoutOrder
        uiLayout.Parent = optionFrame

        for _, pageName in ipairs(pagesList) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 30)
            btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
            btn.Text = pageName
            btn.TextColor3 = Color3.new(1, 1, 1)
            btn.Font = Enum.Font.GothamBold
            btn.FontSize = Enum.FontSize.Size14
            btn.Parent = optionFrame -- This is the crucial line for dropdown options

            btn.MouseButton1Click:Connect(function()
                for _, p in pairs(pagesMap) do p.Visible = false end
                local selectedPage = pagesMap[pageName]
                if selectedPage then
                    selectedPage.Visible = true
                end
                dropdownBtn.Text = pageName
                currentActivePageName = pageName
                optionFrame.Visible = false

                if scriptEnabled then
                    if pageName == "CannonCircle" and CannonCircleModule.cc_isActive then
                        task.spawn(CannonCircleModule.start)
                    elseif pageName == "TreasureDefence" and TreasureDefenceModule.td_isActive then
                        task.spawn(TreasureDefenceModule.start)
                    end
                end
            end)
        end

        dropdownBtn.MouseButton1Click:Connect(function()
            optionFrame.Visible = not optionFrame.Visible
        end)

        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if not gameProcessed and optionFrame.Visible then
                local mousePos = input.Position
                local dropdownBtnAbsPos = dropdownBtn.AbsolutePosition
                local dropdownBtnAbsSize = dropdownBtn.AbsoluteSize
                local optionFrameAbsPos = optionFrame.AbsolutePosition
                local optionFrameAbsSize = optionFrame.AbsoluteSize

                local clickedOnDropdownButton = (mousePos.X >= dropdownBtnAbsPos.X and mousePos.X <= dropdownBtnAbsPos.X + dropdownBtnAbsSize.X and
                    mousePos.Y >= dropdownBtnAbsPos.Y and mousePos.Y <= dropdownBtnAbsPos.Y + dropdownBtnAbsSize.Y)
                local clickedOnOptionsFrame = (mousePos.X >= optionFrameAbsPos.X and mousePos.X <= optionFrameAbsPos.X + optionFrameAbsSize.X and
                    mousePos.Y >= optionFrameAbsPos.Y and mousePos.Y <= optionFrameAbsPos.Y + optionFrameAbsSize.Y)

                if not clickedOnDropdownButton and not clickedOnOptionsFrame then
                    optionFrame.Visible = false
                end
            end
        end)

        pagesMap["Log"].Visible = true
        dropdownBtn.Text = "Log"
        currentActivePageName = "Log"
        return dropdownBtn
    end

    local pagesMap = {
        Log = pageFrames["Log"],
        Changelog = pageFrames["Changelog"],
        CannonCircle = pageFrames["CannonCircle"],
        TreasureDefence = pageFrames["TreasureDefence"],
        CircleTimers = pageFrames["CircleTimers"],
    }
    local pageDropdownButton = createPageDropdown(header, pageNames, pagesMap)
    
    mainGui.Parent = playerGui

    return mainGui
end

local mainGui = createUI()

--- Timer setup
local function getPathObject(pathStr: string): Instance?
    local parts = {}
    for part in string.gmatch(pathStr, "[^%.%[%]\"']+") do
        table.insert(parts, part)
    end

    local current: Instance? = workspace
    for i, p in ipairs(parts) do
        if not current then
            warn("Failed to find previous part in path: " .. table.concat(parts, ".", 1, i - 1))
            return nil
        end
        local success, obj = pcall(function() return current:WaitForChild(p, 5) end)
        if success and obj then
            current = obj
        else
            warn("Failed to find part: '" .. p .. "' in path: " .. pathStr .. " (Step " .. i .. ")")
            return nil
        end
    end
    return current
end

local activeTeleportTimers: {[Instance]: number} = {}

local function setupTimer(timerPathStr: string, reloadPathStr: string)
    local timerObj = getPathObject(timerPathStr)
    local reloadObj = getPathObject(reloadPathStr)

    if not timerObj or not reloadObj then
        logToConsole(string.format("Failed to set up timer: TimerObj or ReloadObj not found for paths '%s' and '%s'", timerPathStr, reloadPathStr))
        return
    end
    if not (timerObj:IsA("TextLabel") or timerObj:IsA("TextBox")) then
        logToConsole(string.format("Timer object is not a TextLabel or TextBox: %s", timerPathStr))
        return
    end
    if not reloadObj:IsA("BasePart") then
        logToConsole(string.format("Reload object is not a BasePart: %s", reloadPathStr))
        return
    end

    local lastTeleportTime = activeTeleportTimers[timerObj] or 0
    local COOLDOWN_SECONDS = 35

    local function updateTimer()
        if not scriptEnabled or (not CannonCircleModule or not CannonCircleModule.cc_isActive or not CannonCircleModule.cc_isRunning) then
            return
        end

        local text = timerObj.Text or ""
        local timeMatch = text:match("([%d:]+)$")
        if not timeMatch then return end

        local sec = cc_parseTimeToSeconds(timeMatch)
        local currentTime = os.time()

        if (sec >= 29 and sec <= 30) and (currentTime - lastTeleportTime > COOLDOWN_SECONDS) then
            logToConsole(string.format("Timer '%s' at %s hit teleport threshold. Teleporting...", timerObj.Name, text))
            cc_teleportPlayer(reloadObj, true)
            activeTeleportTimers[timerObj] = currentTime
        end
    end

    local conn = timerObj:GetPropertyChangedSignal("Text"):Connect(updateTimer)
    table.insert(cc_timerConnections, conn)
    logToConsole(string.format("Timer '%s' setup complete. Monitoring text changes.", timerPathStr))
end

local function initTimers()
    for _, c in ipairs(cc_timerConnections) do
        c:Disconnect()
    end
    table.clear(cc_timerConnections)
    table.clear(activeTeleportTimers)

    logToConsole("Initializing timers...")
    local path1 = "Interiors[\"MainMap!Summerfest\"].CoconutBonkJoinZone.Billboard.BillboardGui.TimerLabel"
    local reload1 = "Interiors[\"MainMap!Summerfest\"].CoconutBonkJoinZone.Ring"
    local path2 = "Interiors[\"MainMap!Summerfest\"].JoetationMinigameJoinZone.Billboard.BillboardGui.TimerLabel"
    local reload2 = "Interiors[\"MainMap!Summerfest\"].JoetationMinigameJoinZone.Ring"

    setupTimer(path1, reload1)
    setupTimer(path2, reload2)
    logToConsole("Timers initialized.")
end

script.AncestryChanged:Connect(function()
    if not script:IsDescendantOf(game) then
        warn("LocalScript removed from game hierarchy. Performing cleanup.")
        if CannonCircleModule then CannonCircleModule.stop() end
        if TreasureDefenceModule then TreasureDefenceModule.stop() end
        for _, c in ipairs(cc_timerConnections) do
            c:Disconnect()
        end
        table.clear(cc_timerConnections)
        if mainGui and mainGui.Parent then
            mainGui:Destroy()
        end
    end
end)
