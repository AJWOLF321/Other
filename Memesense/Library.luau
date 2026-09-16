local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")
local CoreGui = nil
pcall(function()
    CoreGui = game:GetService("CoreGui")
end)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()

pcall(function()
    if getgenv().MemeSenseCleanup then
        getgenv().MemeSenseCleanup()
    end
end)
pcall(function()
    game:GetService("RunService"):UnbindFromRenderStep("MemeSense_ThirdPerson")
end)
pcall(function()
    game:GetService("RunService"):UnbindFromRenderStep("MemeSenseMouseUnlock")
end)
pcall(function()
    local cam = workspace.CurrentCamera
    if cam then
        pcall(function()
            cam.CFrame = CFrame.fromMatrix(cam.CFrame.Position, cam.CFrame.RightVector.Unit, cam.CFrame.UpVector.Unit)
        end)
        local oldHolder = cam:FindFirstChild("ChamHolder")
        if oldHolder then oldHolder:Destroy() end
    end
end)
pcall(function()
    local function purgeMemeSenseGui(gui)
        if not gui then return end
        pcall(function() gui.Enabled = false end)
        pcall(function()
            for _, child in ipairs(gui:GetChildren()) do
                if child:IsA("GuiObject") then
                    child.Visible = false
                    child.Position = UDim2.new(0, -10000, 0, -10000)
                end
            end
        end)
        pcall(function() gui.Parent = nil end)
        pcall(function() gui:Destroy() end)
    end

    local oldGui = getgenv().MemeSenseGui
    if oldGui then
        getgenv().MemeSenseGui = nil
        purgeMemeSenseGui(oldGui)
    end

    local oldContainer = getgenv().MemeSenseContainer
    if oldContainer then
        getgenv().MemeSenseContainer = nil
        pcall(function() oldContainer:Destroy() end)
    end

    local oldScope = getgenv().MemeSenseScopeGui
    if oldScope then
        getgenv().MemeSenseScopeGui = nil
        purgeMemeSenseGui(oldScope)
    end

    local function isOrphanedMemeSense(gui)
        if not gui or not gui:IsA("ScreenGui") then return false end
        if gui.Name == "MemeSenseScopeGui" or gui.Name == "MemeSenseGui" then return true end
        for _, child in ipairs(gui:GetChildren()) do
            if child:IsA("GuiObject") then
                if child.Name == "MainWindow" or (child.Size.X.Offset == 700 and child.Size.Y.Offset == 590) then
                    return true
                end
            end
        end
        return false
    end

    local function sweepContainer(container)
        if not container then return end
        pcall(function()
            for _, child in ipairs(container:GetChildren()) do
                if isOrphanedMemeSense(child) then
                    purgeMemeSenseGui(child)
                end
            end
        end)
    end
    sweepContainer(LocalPlayer:FindFirstChild("PlayerGui"))
    if CoreGui then sweepContainer(CoreGui) end
    pcall(function()
        if typeof(gethui) == "function" then sweepContainer(gethui()) end
    end)
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if pGui then
        local pgScope = pGui:FindFirstChild("MemeSenseScopeGui")
        if pgScope then pgScope:Destroy() end
        local mg = pGui:FindFirstChild("MainGui")
        local mid = mg and (mg:FindFirstChild("Middle") or (mg:FindFirstChild("Gameplay") and mg.Gameplay:FindFirstChild("Middle")))
        if mid then
            local oldSnipCross = mid:FindFirstChild("MemeSenseSniperCrosshair")
            if oldSnipCross then oldSnipCross:Destroy() end
        end
        local ss = mid and mid:FindFirstChild("SniperScope")
        if ss then
            for _, child in ipairs(ss:GetChildren()) do
                if child.Name == "MemeSenseCustomScopeCrosshair" then
                    child:Destroy()
                end
            end
        end
    end
end)

local Connections = {}
local unloadChamSystem = nil
local updateChamsCategoryView = nil
local chamsMasterEnabled = false

local Library = nil
do
    local loaded = false
    -- 1. Try loading from local file system first
    pcall(function()
        if type(readfile) == "function" then
            local paths = { "Memesense/Library.luau", "Library.luau", "scripts/Memesense/Library.luau" }
            for _, path in ipairs(paths) do
                if (type(isfile) == "function" and isfile(path)) or true then
                    local ok, content = pcall(readfile, path)
                    if ok and content and #content > 0 then
                        local fn = loadstring(content)
                        if fn then
                            Library = fn()
                            if Library then
                                loaded = true
                                getgenv().MemeSenseLibrary = Library
                                break
                            end
                        end
                    end
                end
            end
        end
    end)

    -- 2. Try global cache if already loaded
    if not loaded and getgenv().MemeSenseLibrary then
        Library = getgenv().MemeSenseLibrary
        loaded = true
    end

    -- 3. Fallback to fetching directly from GitHub raw URL
    if not loaded or not Library then
        pcall(function()
            local url = "https://raw.githubusercontent.com/AJWOLF321/Other/refs/heads/main/Memesense/Library.luau"
            local content = game:HttpGet(url)
            if content and #content > 0 then
                local fn = loadstring(content)
                if fn then
                    Library = fn()
                    loaded = true
                    getgenv().MemeSenseLibrary = Library
                    -- Optionally cache locally if writefile exists
                    if type(writefile) == "function" then
                        pcall(function()
                            if type(makefolder) == "function" and not isfolder("Memesense") then
                                makefolder("Memesense")
                            end
                            writefile("Memesense/Library.luau", content)
                        end)
                    end
                end
            end
        end)
    end

    if not loaded or not Library then
        Library = getgenv().MemeSenseLibrary
    end
end

if not Library then
    error("[MemeSense] Failed to load Library.luau from local file or GitHub raw.")
end

local Theme = Library.Theme
local Tabs = Library.Tabs
local Controls = Library.Controls
local MainWindow = Library.MainWindow
local ScreenGui = Library.ScreenGui
local Container = Library.Container
local PopupsLayer = Library.PopupsLayer
local ActivePopups = Library.ActivePopups
local TabIconGlyphs = Library.TabIconGlyphs
local CommonIcons = Library.CommonIcons
local GuiIconsFont = Library.GuiIconsFont
local UIControlRegistry = Library.UIControlRegistry
for _, c in ipairs(Library.Connections or {}) do table.insert(Connections, c) end
local ContentArea = Library.ContentArea
local SidebarFrame = Library.SidebarFrame
local HeaderFrame = Library.HeaderFrame
local HeaderCenterGroup = Library.HeaderCenterGroup
local MasterSwitchFrame = Library.MasterSwitchFrame
local WeaponDropdownFrame = Library.WeaponDropdownFrame
local SubWeaponDropdownFrame = Library.SubWeaponDropdownFrame
local tabMasterStates = Library.tabMasterStates
local updateMasterSwitchUI = Library.updateMasterSwitchUI
local createCorner = Library.createCorner
local createStroke = Library.createStroke
local isPosInGui = Library.isPosInGui
local getRealMousePos = Library.getRealMousePos
local getScreenPos = Library.getScreenPos
local CreateTab = function(name, orderIndex) return Library:CreateTab(name, orderIndex) end
local CloseAllPopups = function(preservePredicate) return Library:CloseAllPopups(preservePredicate) end
local SelectTab = function(name) return Library:SelectTab(name) end

-- Override Controls:CreateMultiDropdown to guarantee robust functioning across all library versions
local function getParentPath(inst)
    local path = {}
    local curr = inst
    while curr and curr ~= ScreenGui and curr ~= MainWindow and curr ~= game do
        table.insert(path, 1, curr.Name)
        curr = curr.Parent
    end
    return table.concat(path, "/")
end

function Controls:CreateMultiDropdown(parent, config)
    local name = config.Name or "MultiDropdown"
    local options = config.Options or {}
    local rawSel = config.Default or {}
    local selected = {}
    if typeof(rawSel) == "table" then
        for _, k in ipairs(rawSel) do selected[k] = true end
        for k, v in pairs(rawSel) do if v == true then selected[k] = true end end
    elseif typeof(rawSel) == "string" then
        selected[rawSel] = true
    end
    local callback = config.Callback
    local order = config.LayoutOrder or 0

    local DropdownContainer = Instance.new("Frame")
    DropdownContainer.Name = name .. "_MultiDropdown"
    DropdownContainer.Size = UDim2.new(1, -6, 0, 26)
    DropdownContainer.BackgroundTransparency = 1
    DropdownContainer.LayoutOrder = order
    DropdownContainer.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Size = UDim2.new(0.45, 0, 1, 0)
    Label.Position = UDim2.new(0, 4, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Theme.TextActive
    Label.TextSize = 12
    Label.Font = Theme.FontMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = DropdownContainer

    local Box = Instance.new("Frame")
    Box.Name = "Box"
    Box.Size = UDim2.new(0.53, 0, 1, 0)
    Box.Position = UDim2.new(0.47, -4, 0, 0)
    Box.BackgroundColor3 = Theme.DropdownBg
    Box.Parent = DropdownContainer
    createCorner(Box, 3)
    createStroke(Box, Theme.ControlBorder, 1)

    local SelectedLabel = Instance.new("TextLabel")
    SelectedLabel.Name = "Selected"
    SelectedLabel.Size = UDim2.new(1, -22, 1, 0)
    SelectedLabel.Position = UDim2.new(0, 8, 0, 0)
    SelectedLabel.BackgroundTransparency = 1
    SelectedLabel.Text = "..."
    SelectedLabel.ClipsDescendants = true
    SelectedLabel.TextColor3 = Theme.TextActive
    SelectedLabel.TextSize = 12
    SelectedLabel.Font = Theme.FontMedium
    SelectedLabel.TextXAlignment = Enum.TextXAlignment.Left
    SelectedLabel.Parent = Box

    local Chevron = Instance.new("TextLabel")
    Chevron.Name = "Chevron"
    Chevron.Size = UDim2.new(0, 14, 0, 14)
    Chevron.Position = UDim2.new(1, -16, 0.5, -7)
    Chevron.BackgroundTransparency = 1
    Chevron.FontFace = GuiIconsFont
    Chevron.Text = "C"
    Chevron.TextColor3 = Color3.fromRGB(255, 255, 255)
    Chevron.TextSize = 13
    Chevron.TextXAlignment = Enum.TextXAlignment.Center
    Chevron.TextYAlignment = Enum.TextYAlignment.Center
    Chevron.Parent = Box

    local Trigger = Instance.new("TextButton")
    Trigger.Name = "Trigger"
    Trigger.Size = UDim2.new(1, 0, 1, 0)
    Trigger.BackgroundTransparency = 1
    Trigger.Text = ""
    Trigger.AutoButtonColor = false
    Trigger.Parent = Box

    Trigger.MouseEnter:Connect(function()
        Box.BackgroundColor3 = Color3.fromRGB(95, 102, 112)
    end)
    Trigger.MouseLeave:Connect(function()
        Box.BackgroundColor3 = Theme.DropdownBg
    end)

    local Popover = Instance.new("Frame")
    Popover.Name = name .. "_Popover"
    Popover.Size = UDim2.new(0, 130, 0, 26 + math.min(#options * 24 + 8, 160))
    Popover.BackgroundColor3 = Theme.DropdownBg
    Popover.BorderSizePixel = 0
    Popover.Visible = false
    Popover.ZIndex = 120
    Popover.Parent = PopupsLayer
    createCorner(Popover, 3)
    createStroke(Popover, Theme.ControlBorder, 1)

    local PopHeader = Instance.new("Frame")
    PopHeader.Name = "Header"
    PopHeader.Size = UDim2.new(1, 0, 0, 26)
    PopHeader.Position = UDim2.new(0, 0, 0, 0)
    PopHeader.BackgroundTransparency = 1
    PopHeader.Visible = false
    PopHeader.ZIndex = 121
    PopHeader.Parent = Popover

    local PopHeaderLabel = Instance.new("TextLabel")
    PopHeaderLabel.Name = "Selected"
    PopHeaderLabel.Size = UDim2.new(1, -22, 1, 0)
    PopHeaderLabel.Position = UDim2.new(0, 8, 0, 0)
    PopHeaderLabel.BackgroundTransparency = 1
    PopHeaderLabel.ClipsDescendants = true
    PopHeaderLabel.TextColor3 = Theme.TextActive
    PopHeaderLabel.TextSize = 12
    PopHeaderLabel.Font = Theme.FontMedium
    PopHeaderLabel.TextXAlignment = Enum.TextXAlignment.Left
    PopHeaderLabel.Visible = false
    PopHeaderLabel.ZIndex = 122
    PopHeaderLabel.Parent = PopHeader

    local PopChevron = Instance.new("TextLabel")
    PopChevron.Name = "Chevron"
    PopChevron.Size = UDim2.new(0, 14, 0, 14)
    PopChevron.Position = UDim2.new(1, -16, 0.5, -7)
    PopChevron.BackgroundTransparency = 1
    PopChevron.FontFace = GuiIconsFont
    PopChevron.Text = "B"
    PopChevron.TextColor3 = Color3.fromRGB(255, 255, 255)
    PopChevron.TextSize = 13
    PopChevron.TextXAlignment = Enum.TextXAlignment.Center
    PopChevron.TextYAlignment = Enum.TextYAlignment.Center
    PopChevron.Visible = false
    PopChevron.ZIndex = 122
    PopChevron.Parent = PopHeader

    local PopHeaderBtn = Instance.new("TextButton")
    PopHeaderBtn.Name = "CloseTrigger"
    PopHeaderBtn.Size = UDim2.new(1, 0, 1, 0)
    PopHeaderBtn.BackgroundTransparency = 1
    PopHeaderBtn.Text = ""
    PopHeaderBtn.Visible = false
    PopHeaderBtn.ZIndex = 123
    PopHeaderBtn.Parent = PopHeader

    PopHeaderBtn.MouseButton1Click:Connect(function()
        CloseAllPopups()
    end)

    local ScrollList = Instance.new("ScrollingFrame")
    ScrollList.Name = "ScrollList"
    ScrollList.Size = UDim2.new(1, 0, 1, -26)
    ScrollList.Position = UDim2.new(0, 0, 0, 26)
    ScrollList.BackgroundTransparency = 1
    ScrollList.BorderSizePixel = 0
    ScrollList.ScrollBarThickness = 2
    ScrollList.ScrollBarImageColor3 = Theme.ControlBorder
    ScrollList.ZIndex = 122
    ScrollList.Parent = Popover

    table.insert(ActivePopups, {
        Frame = Popover,
        OnClose = function()
            Chevron.Text = "C"
        end
    })

    local PopoverList = Instance.new("UIListLayout")
    PopoverList.Padding = UDim.new(0, 1)
    PopoverList.SortOrder = Enum.SortOrder.LayoutOrder
    PopoverList.Parent = ScrollList

    local PopoverPad = Instance.new("UIPadding")
    PopoverPad.PaddingTop = UDim.new(0, 3)
    PopoverPad.PaddingBottom = UDim.new(0, 3)
    PopoverPad.PaddingLeft = UDim.new(0, 3)
    PopoverPad.PaddingRight = UDim.new(0, 3)
    PopoverPad.Parent = ScrollList

    local function updateText()
        local list = {}
        for _, opt in ipairs(options) do
            if selected[opt] then
                table.insert(list, opt)
            end
        end
        if #list == 0 then
            SelectedLabel.Text = "..."
        elseif #list == 1 then
            SelectedLabel.Text = list[1]
        else
            SelectedLabel.Text = table.concat(list, ", ")
        end
        PopHeaderLabel.Text = SelectedLabel.Text
    end
    updateText()

    local function buildOptions()
        for _, c in ipairs(ScrollList:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for optIdx, opt in ipairs(options) do
            local OptBtn = Instance.new("TextButton")
            OptBtn.Name = opt
            OptBtn.LayoutOrder = optIdx
            OptBtn.Size = UDim2.new(1, 0, 0, 22)
            local isSel = (selected[opt] == true)
            OptBtn.BackgroundColor3 = Theme.DropdownBg
            OptBtn.Text = "  " .. opt
            OptBtn.TextColor3 = isSel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 134, 145)
            OptBtn.TextSize = 12
            OptBtn.Font = isSel and Theme.FontBold or Theme.FontMedium
            OptBtn.TextXAlignment = Enum.TextXAlignment.Left
            OptBtn.AutoButtonColor = false
            OptBtn.ZIndex = 123
            OptBtn.Parent = ScrollList
            createCorner(OptBtn, 2)

            OptBtn.MouseEnter:Connect(function()
                if not selected[opt] then
                    OptBtn.TextColor3 = Color3.fromRGB(195, 200, 210)
                else
                    OptBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                end
            end)
            OptBtn.MouseLeave:Connect(function()
                if not selected[opt] then
                    OptBtn.TextColor3 = Color3.fromRGB(130, 134, 145)
                else
                    OptBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                end
            end)

            OptBtn.MouseButton1Click:Connect(function()
                selected[opt] = not selected[opt]
                updateText()
                buildOptions()
                if callback then
                    pcall(callback, selected)
                end
            end)
        end
    end

    Trigger.MouseButton1Click:Connect(function()
        local isOpen = Popover.Visible
        CloseAllPopups()
        if not isOpen then
            local boxPos = getScreenPos(Box)
            local absSize = Box.AbsoluteSize
            local optionsH = math.min(#options * 23 + 6, 160)
            local totalH = absSize.Y + optionsH
            Popover.Position = UDim2.new(0, boxPos.X, 0, boxPos.Y)
            Popover.Size = UDim2.new(0, absSize.X, 0, totalH)
            PopHeader.Size = UDim2.new(1, 0, 0, absSize.Y)
            PopHeader.Visible = true
            PopHeaderLabel.Visible = true
            PopHeaderLabel.Text = SelectedLabel.Text
            PopChevron.Visible = true
            PopChevron.Text = "B"
            PopHeaderBtn.Visible = true
            ScrollList.Position = UDim2.new(0, 0, 0, absSize.Y)
            ScrollList.Size = UDim2.new(1, 0, 1, -absSize.Y)
            ScrollList.CanvasSize = UDim2.new(0, 0, 0, #options * 23 + 6)
            updateText()
            Popover.Visible = true
            Chevron.Text = "B"
            buildOptions()
        else
            Popover.Visible = false
            Chevron.Text = "C"
        end
    end)

    local multiCtrlKey = getParentPath(DropdownContainer)
    local multiCtrlObj = {
        Type = "MultiDropdown",
        Name = name,
        Key = multiCtrlKey,
        GetValue = function() return selected end,
        SetValue = function(val)
            if typeof(val) == "table" then
                table.clear(selected)
                for k, v in pairs(val) do
                    if typeof(k) == "number" and typeof(v) == "string" then
                        selected[v] = true
                    elseif v == true then
                        selected[k] = true
                    end
                end
                updateText()
                buildOptions()
                if callback then pcall(callback, selected) end
            end
        end
    }

    if UIControlRegistry then
        UIControlRegistry[multiCtrlKey] = multiCtrlObj
        if not UIControlRegistry[name] then UIControlRegistry[name] = multiCtrlObj end
        local lowerName = string.lower(name)
        if not UIControlRegistry[lowerName] then UIControlRegistry[lowerName] = multiCtrlObj end
        local pathSegments = string.split(multiCtrlKey, "/")
        if #pathSegments >= 2 then
            local shortKey = pathSegments[#pathSegments - 1] .. "/" .. pathSegments[#pathSegments]
            if not UIControlRegistry[shortKey] then UIControlRegistry[shortKey] = multiCtrlObj end
        end
    end

    return {
        Get = function() return selected end,
        GetValue = multiCtrlObj.GetValue,
        SetValue = multiCtrlObj.SetValue
    }
end

local TabNames = {
    "Legitbot",
    "Aim Assist",
    "Players",
    "Chams",
    "Items",
    "Visuals",
    "World",
    "View",
    "Indicators",
    "Miscellaneous",
    "Inventory",
    "Configs"
}

for i, tName in ipairs(TabNames) do
    CreateTab(tName, i)
end

do
    local function run()
        local AimAssistTab = Tabs["Aim Assist"]
    local Left = AimAssistTab.LeftColumn
    local Right = AimAssistTab.RightColumn

    do
        local leftOrder = 0
        local function nextLeft()
            leftOrder += 1
            return leftOrder
        end
Controls:CreateSectionHeader(Left, "Trigger", nextLeft())

Controls:CreateToggle(Left, {
    Name = "Enable",
    Default = false,
    Keybind = { Key = nil, Type = "Always On" },
    LayoutOrder = nextLeft(),
    Callback = function(v) end
})

Controls:CreateToggle(Left, {
    Name = "Through wall",
    Default = false,
    Keybind = { Key = nil, Type = "Always On" },
    LayoutOrder = nextLeft(),
    Callback = function(v) end
})

Controls:CreateToggle(Left, {
    Name = "Air check",
    Default = false,
    LayoutOrder = nextLeft(),
    Callback = function(v) end
})

Controls:CreateToggle(Left, {
    Name = "Auto scope",
    Default = false,
    LayoutOrder = nextLeft(),
    Callback = function(v) end
})

Controls:CreateToggle(Left, {
    Name = "Scope check",
    Default = false,
    LayoutOrder = nextLeft(),
    Callback = function(v) end
})

Controls:CreateToggle(Left, {
    Name = "Flash check",
    Default = false,
    LayoutOrder = nextLeft(),
    Callback = function(v) end
})

Controls:CreateToggle(Left, {
    Name = "Smoke check",
    Default = false,
    LayoutOrder = nextLeft(),
    Callback = function(v) end
})

Controls:CreateToggle(Left, {
    Name = "Ignore breakables",
    Default = false,
    LayoutOrder = nextLeft(),
    Callback = function(v) end
})

Controls:CreateSlider(Left, {
    Name = "Lock camera after shot",
    Min = 0.000,
    Max = 2.000,
    Default = 0.000,
    Decimals = 3,
    Suffix = "s",
    LayoutOrder = nextLeft(),
    Callback = function(v) end
})

Controls:CreateSlider(Left, {
    Name = "Delay between shots",
    Min = 0.000,
    Max = 2.000,
    Default = 0.000,
    Decimals = 3,
    Suffix = "s",
    LayoutOrder = nextLeft(),
    Callback = function(v) end
})

Controls:CreateDropdown(Left, {
    Name = "Hit chance type",
    Options = { "Spread", "Recoil", "Static", "Dynamic" },
    Default = "Spread",
    LayoutOrder = nextLeft(),
    Callback = function(v) end
})

Controls:CreateDualFilter(Left, {
    Option1 = "Visible",
    Option2 = "Auto wall",
    LayoutOrder = nextLeft(),
    Callback = function(v) end
})

Controls:CreateMultiDropdown(Left, {
    Name = "Hit groups",
    Options = { "Head", "Neck", "Chest", "Stomach", "Arms", "Legs" },
    Default = { Head = true, Neck = true, Chest = true },
    LayoutOrder = nextLeft(),
    Callback = function(v) end
})

Controls:CreateSlider(Left, {
    Name = "Minimum damage",
    Min = 0,
    Max = 100,
    Default = 0,
    Decimals = 0,
    Suffix = "HP",
    LayoutOrder = nextLeft(),
    Callback = function(v) end
})

Controls:CreateSlider(Left, {
    Name = "Minimum hit chance",
    Min = 0,
    Max = 100,
    Default = 0,
    Decimals = 0,
    Suffix = "%",
    LayoutOrder = nextLeft(),
    Callback = function(v) end
})

Controls:CreateSlider(Left, {
    Name = "Reaction time",
    Min = 0,
    Max = 500,
    Default = 0,
    Decimals = 0,
    Suffix = "ms",
    LayoutOrder = nextLeft(),
    Callback = function(v) end
})
end

do
local rightOrder = 0
local function nextRight()
    rightOrder += 1
    return rightOrder
end

Controls:CreateSectionHeader(Right, "RCS", nextRight())

local rcsBulletStart, rcsBulletEnd, rcsX, rcsY

local function updateRCSSliders(enabled)
    if rcsBulletStart then rcsBulletStart.SetEnabled(enabled) end
    if rcsBulletEnd then rcsBulletEnd.SetEnabled(enabled) end
    if rcsX then rcsX.SetEnabled(enabled) end
    if rcsY then rcsY.SetEnabled(enabled) end
end

local rcsEnable = Controls:CreateToggle(Right, {
    Name = "Enable",
    Default = false,
    Keybind = { Key = nil, Type = "Always On" },
    LayoutOrder = nextRight(),
    Callback = function(v)
        updateRCSSliders(v)
    end
})

rcsBulletStart = Controls:CreateSlider(Right, {
    Name = "Bullet start",
    Min = 1,
    Max = 30,
    Default = 2,
    Decimals = 0,
    Enabled = false,
    LayoutOrder = nextRight(),
    Callback = function(v) end
})

rcsBulletEnd = Controls:CreateSlider(Right, {
    Name = "Bullet end",
    Min = 1,
    Max = 30,
    Default = 30,
    Decimals = 0,
    Enabled = false,
    LayoutOrder = nextRight(),
    Callback = function(v) end
})

rcsX = Controls:CreateSlider(Right, {
    Name = "X",
    Min = 0.000,
    Max = 1.000,
    Default = 1.000,
    Decimals = 3,
    Enabled = false,
    LayoutOrder = nextRight(),
    Callback = function(v) end
})

rcsY = Controls:CreateSlider(Right, {
    Name = "Y",
    Min = 0.000,
    Max = 1.000,
    Default = 1.000,
    Decimals = 3,
    Enabled = false,
    LayoutOrder = nextRight(),
    Callback = function(v) end
})

updateRCSSliders(false)

Controls:CreateSectionHeader(Right, "Auto Pistol", nextRight())

Controls:CreateToggle(Right, {
    Name = "Enable",
    Default = false,
    Keybind = { Key = nil, Type = "Always On" },
    LayoutOrder = nextRight(),
    Callback = function(v) end
})

Controls:CreateSlider(Right, {
    Name = "Delay between shots",
    Min = 0,
    Max = 500,
    Default = 0,
    Decimals = 0,
    ZeroText = "disabled",
    Suffix = "ms",
    LayoutOrder = nextRight(),
    Callback = function(v) end
})
end
    end
    run()
end

do
    local function run()
        local LegitTab = Tabs["Legitbot"]
    local LLeft = LegitTab.LeftColumn
    local LRight = LegitTab.RightColumn

local lLeftOrder = 0
local function nextLLeft()
    lLeftOrder += 1
    return lLeftOrder
end

local lRightOrder = 0
local function nextLRight()
    lRightOrder += 1
    return lRightOrder
end

Controls:CreateSectionHeader(LLeft, "General", nextLLeft())

Controls:CreateToggle(LLeft, {
    Name = "Enable",
    Default = false,
    LayoutOrder = nextLLeft()
})

Controls:CreateToggle(LLeft, {
    Name = "Aim key",
    Default = false,
    Keybind = { Key = nil, Type = "Always On" },
    LayoutOrder = nextLLeft()
})

Controls:CreateToggle(LLeft, {
    Name = "Draw FOV",
    Default = false,
    LayoutOrder = nextLLeft()
})

Controls:CreateSlider(LLeft, {
    Name = "Aim time",
    Min = 0,
    Max = 100,
    Default = 0,
    ZeroText = "disabled",
    Suffix = "s",
    LayoutOrder = nextLLeft()
})

local function makeSubTabContainer(name, isVisible)
    local frame = Instance.new("Frame")
    frame.Name = name .. "Container"
    frame.Size = UDim2.new(1, 0, 0, 0)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.BackgroundTransparency = 1
    frame.Visible = isVisible
    frame.LayoutOrder = nextLLeft()
    frame.Parent = LLeft

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 4)
    layout.Parent = frame
    return frame
end

local subTabsOrder = nextLLeft()
local AimContainer = makeSubTabContainer("Aim", true)
local AccuracyContainer = makeSubTabContainer("Accuracy", false)
local RCSContainer = makeSubTabContainer("RCS", false)
local MiscContainer = makeSubTabContainer("Misc", false)

Controls:CreateSubTabs(LLeft, { "Aim", "Accuracy", "RCS", "Misc" }, "Aim", subTabsOrder, function(activeTab)
    AimContainer.Visible = (activeTab == "Aim")
    AccuracyContainer.Visible = (activeTab == "Accuracy")
    RCSContainer.Visible = (activeTab == "RCS")
    MiscContainer.Visible = (activeTab == "Misc")
end)

    Controls:CreateDropdown(AimContainer, {
        Name = "Radius type",
        Options = { "Static", "Dynamic" },
        Default = "Static",
        LayoutOrder = 1
    })

    Controls:CreateSlider(AimContainer, {
        Name = "Radius",
        Min = 0,
        Max = 30,
        Default = 10,
        Decimals = 3,
        Suffix = "°",
        LayoutOrder = 2
    })

    Controls:CreateSlider(AimContainer, {
        Name = "Multiplier",
        Min = 1,
        Max = 10,
        Default = 4,
        Decimals = 2,
        LayoutOrder = 3
    })

    Controls:CreateDropdown(AimContainer, {
        Name = "Smooth type",
        Options = { "Dynamic", "Static" },
        Default = "Dynamic",
        LayoutOrder = 4
    })

    Controls:CreateSlider(AimContainer, {
        Name = "Smooth pitch",
        Min = 0,
        Max = 100,
        Default = 0,
        ZeroText = "disabled",
        Suffix = "",
        LayoutOrder = 5
    })

    Controls:CreateSlider(AimContainer, {
        Name = "Smooth yaw",
        Min = 0,
        Max = 100,
        Default = 0,
        ZeroText = "disabled",
        Suffix = "",
        LayoutOrder = 6
    })

    Controls:CreateDropdown(AccuracyContainer, {
        Name = "First shot delay type",
        Options = { "Combined", "Static", "Dynamic" },
        Default = "Combined",
        LayoutOrder = 1
    })

    Controls:CreateSlider(AccuracyContainer, {
        Name = "First shot delay",
        Min = 0,
        Max = 100,
        Default = 0,
        ZeroText = "disabled",
        Suffix = "ms",
        LayoutOrder = 2
    })

    Controls:CreateSlider(AccuracyContainer, {
        Name = "Target switch delay",
        Min = 0,
        Max = 100,
        Default = 0,
        ZeroText = "disabled",
        Suffix = "ms",
        LayoutOrder = 3
    })

    Controls:CreateSlider(AccuracyContainer, {
        Name = "Minimum hit chance",
        Min = 0,
        Max = 100,
        Default = 100,
        Suffix = "%",
        LayoutOrder = 4
    })

    Controls:CreateSlider(AccuracyContainer, {
        Name = "Minimum damage",
        Min = 0,
        Max = 100,
        Default = 92,
        Suffix = "HP",
        LayoutOrder = 5
    })

    Controls:CreateSlider(AccuracyContainer, {
        Name = "Reaction time",
        Min = 0,
        Max = 500,
        Default = 0,
        ZeroText = "disabled",
        Suffix = "ms",
        LayoutOrder = 6
    })

    Controls:CreateToggle(RCSContainer, {
        Name = "Enable",
        Default = false,
        LayoutOrder = 1
    })

    Controls:CreateToggle(RCSContainer, {
        Name = "Disable on non-auto weapons",
        Default = false,
        LayoutOrder = 2
    })

    Controls:CreateToggle(RCSContainer, {
        Name = "Start on first bullet",
        Default = false,
        LayoutOrder = 3
    })

    Controls:CreateToggle(RCSContainer, {
        Name = "Custom radius",
        Default = false,
        LayoutOrder = 4
    })

    Controls:CreateToggle(RCSContainer, {
        Name = "Custom smooth",
        Default = false,
        Dropdown = { Options = { "Dynamic", "Static" }, Default = "Dynamic" },
        LayoutOrder = 5
    })

    Controls:CreateSlider(RCSContainer, {
        Name = "X",
        Min = 0,
        Max = 2,
        Default = 1.000,
        Decimals = 3,
        LayoutOrder = 6
    })

    Controls:CreateSlider(RCSContainer, {
        Name = "Y",
        Min = 0,
        Max = 2,
        Default = 1.000,
        Decimals = 3,
        LayoutOrder = 7
    })

    Controls:CreateSlider(RCSContainer, {
        Name = "Radius",
        Min = 0,
        Max = 30,
        Default = 0.000,
        Decimals = 3,
        Suffix = "°",
        LayoutOrder = 8
    })

    Controls:CreateSlider(RCSContainer, {
        Name = "Smooth pitch",
        Min = 0,
        Max = 100,
        Default = 0,
        ZeroText = "disabled",
        Suffix = "",
        LayoutOrder = 9
    })

    Controls:CreateSlider(RCSContainer, {
        Name = "Smooth yaw",
        Min = 0,
        Max = 100,
        Default = 0,
        ZeroText = "disabled",
        Suffix = "",
        LayoutOrder = 10
    })

    Controls:CreateToggle(MiscContainer, {
        Name = "Scope check",
        Default = false,
        LayoutOrder = 1
    })

    Controls:CreateToggle(MiscContainer, {
        Name = "Air check",
        Default = false,
        LayoutOrder = 2
    })

    Controls:CreateToggle(MiscContainer, {
        Name = "Smoke check",
        Default = false,
        LayoutOrder = 3
    })

    Controls:CreateToggle(MiscContainer, {
        Name = "Flash check",
        Default = false,
        LayoutOrder = 4
    })

    Controls:CreateToggle(MiscContainer, {
        Name = "Auto pistol",
        Default = false,
        LayoutOrder = 5
    })

    Controls:CreateToggle(MiscContainer, {
        Name = "Target air check",
        Default = false,
        LayoutOrder = 6
    })

do
    Controls:CreateSectionHeader(LRight, "Hit groups", nextLRight())

    Controls:CreateDropdown(LRight, {
        Name = "Selection",
        Options = { "Head", "Chest", "Stomach", "Arms", "Legs" },
        Default = "Head",
        LayoutOrder = nextLRight()
    })

    Controls:CreateToggle(LRight, {
        Name = "Only body aim",
        Default = false,
        Keybind = { Key = nil, Type = "Always On", HasIndicator = true, Indicator = false, IndicatorText = "BAIM" },
        LayoutOrder = nextLRight()
    })

    Controls:CreateToggle(LRight, {
        Name = "Prefer head aim",
        Default = false,
        LayoutOrder = nextLRight()
    })

    Controls:CreateToggle(LRight, {
        Name = "Prefer body aim",
        Default = false,
        LayoutOrder = nextLRight()
    })

    Controls:CreateToggle(LRight, {
        Name = "Body aim if lethal",
        Default = false,
        LayoutOrder = nextLRight()
    })

    Controls:CreateDropdown(LRight, {
        Name = "Targets",
        Options = { "Players", "Allies", "Enemies" },
        Default = "Players",
        LayoutOrder = nextLRight()
    })
end

do
    local dualFilterOrder = nextLRight()

    local AutoFireContainer = Instance.new("Frame")
    AutoFireContainer.Name = "AutoFireContainer"
    AutoFireContainer.Size = UDim2.new(1, 0, 0, 0)
    AutoFireContainer.AutomaticSize = Enum.AutomaticSize.Y
    AutoFireContainer.BackgroundTransparency = 1
    AutoFireContainer.Visible = true
    AutoFireContainer.LayoutOrder = nextLRight()
    AutoFireContainer.Parent = LRight

    local afLayout = Instance.new("UIListLayout")
    afLayout.SortOrder = Enum.SortOrder.LayoutOrder
    afLayout.Padding = UDim.new(0, 4)
    afLayout.Parent = AutoFireContainer

    local AutoWallContainer = Instance.new("Frame")
    AutoWallContainer.Name = "AutoWallContainer"
    AutoWallContainer.Size = UDim2.new(1, 0, 0, 0)
    AutoWallContainer.AutomaticSize = Enum.AutomaticSize.Y
    AutoWallContainer.BackgroundTransparency = 1
    AutoWallContainer.Visible = false
    AutoWallContainer.LayoutOrder = nextLRight()
    AutoWallContainer.Parent = LRight

    local awLayout = Instance.new("UIListLayout")
    awLayout.SortOrder = Enum.SortOrder.LayoutOrder
    awLayout.Padding = UDim.new(0, 4)
    awLayout.Parent = AutoWallContainer

    Controls:CreateDualFilter(LRight, {
        Option1 = "Auto fire",
        Option2 = "Auto wall",
        LayoutOrder = dualFilterOrder,
        Callback = function(selected)
            AutoFireContainer.Visible = (selected == "Auto fire")
            AutoWallContainer.Visible = (selected == "Auto wall")
        end
    })

    Controls:CreateToggle(AutoFireContainer, {
        Name = "Enable",
        Default = false,
        Keybind = { Key = nil, Type = "Always On", HasIndicator = true, Indicator = false, IndicatorText = "AF" },
        LayoutOrder = 1
    })

    Controls:CreateDualToggle(AutoFireContainer,
        { Name = "Auto stop", Default = false },
        { Name = "Auto scope", Default = false },
        2
    )

    Controls:CreateDropdown(AutoFireContainer, {
        Name = "Hit chance type",
        Options = { "Spread", "Hitchance" },
        Default = "Spread",
        LayoutOrder = 3
    })

    Controls:CreateSlider(AutoFireContainer, {
        Name = "Reaction time",
        Min = 0,
        Max = 200,
        Default = 36,
        Suffix = "ms",
        LayoutOrder = 4
    })

    Controls:CreateSlider(AutoFireContainer, {
        Name = "Delay between shots",
        Min = 0,
        Max = 500,
        Default = 0,
        ZeroText = "disabled",
        Suffix = "ms",
        LayoutOrder = 5
    })

    Controls:CreateSlider(AutoFireContainer, {
        Name = "Minimum hit chance",
        Min = 0,
        Max = 100,
        Default = 61,
        Suffix = "%",
        LayoutOrder = 6
    })

    Controls:CreateSlider(AutoFireContainer, {
        Name = "Ghost time",
        Min = 0,
        Max = 500,
        Default = 0,
        ZeroText = "disabled",
        Suffix = "ms",
        LayoutOrder = 7
    })

    Controls:CreateToggle(AutoWallContainer, {
        Name = "Enable",
        Default = false,
        Keybind = { Key = nil, Type = "Always On", HasIndicator = true, Indicator = false, IndicatorText = "AW" },
        LayoutOrder = 1
    })

    Controls:CreateSlider(AutoWallContainer, {
        Name = "Minimum damage",
        Min = 0,
        Max = 100,
        Default = 100,
        Suffix = "HP",
        LayoutOrder = 2
    })

    Controls:CreateDropdown(AutoWallContainer, {
        Name = "Hit groups",
        Options = { "Head", "Chest", "Stomach", "Arms", "Legs" },
        Default = "Head",
        LayoutOrder = 3
    })
end
    end
    run()
end

local MemeSensePlayers = {
    Enable = false,
    ThroughWall = false,
    Nickname = {
        Enabled = false,
        Color = Color3.fromRGB(255, 255, 255),
        FontSize = 10,
    },
    Box = {
        Enabled = false,
        Color = {
            Invis = Color3.fromRGB(255, 255, 255),
            Vis = Color3.fromRGB(255, 255, 255),
        },
        Filled = false,
        FillColor = {
            Invis = Color3.fromRGB(255, 60, 60),
            Vis = Color3.fromRGB(255, 60, 60),
        },
        Outline = false,
        OutlineColor = {
            Invis = Color3.fromRGB(0, 0, 0),
            Vis = Color3.fromRGB(0, 0, 0),
        },
        Type = "Default",
    },
    HealthBar = {
        Enabled = false,
    },
    Weapon = {
        Enabled = false,
        ShowIcon = false,
        IconColor = Color3.fromRGB(255, 255, 255),
        ShowName = false,
        NameColor = Color3.fromRGB(255, 255, 255),
    }
}

;(function()
    local function run()
        local PlayersTab = Tabs["Players"]
        local PLeft = PlayersTab.LeftColumn
        local PRight = PlayersTab.RightColumn

        local pLeftOrder = 0
        local function nextPLeft()
            pLeftOrder += 1
            return pLeftOrder
        end

        local pRightOrder = 0
        local function nextPRight()
            pRightOrder += 1
            return pRightOrder
        end

        Controls:CreateSectionHeader(PLeft, "General", nextPLeft())

        -- Popover builders
        local activeNicknamePop = nil
        local activeNicknameAnchor = nil
        local function openNicknamePopover(anchorBtn)
            if activeNicknamePop and activeNicknamePop.Parent and activeNicknameAnchor == anchorBtn then
                activeNicknamePop.Visible = false
                activeNicknamePop:Destroy()
                activeNicknamePop = nil
                activeNicknameAnchor = nil
                return
            end
            CloseAllPopups()
            activeNicknameAnchor = anchorBtn

            local pop = Instance.new("Frame")
            pop.Name = "NicknamePopover"
            pop.Size = UDim2.new(0, 160, 0, 52)
            pop.BackgroundColor3 = Color3.fromRGB(19, 20, 24)
            pop.BorderSizePixel = 0
            pop.ZIndex = 520
            pop.Parent = PopupsLayer
            createCorner(pop, 3)
            activeNicknamePop = pop

            local pPad = Instance.new("UIPadding")
            pPad.PaddingTop = UDim.new(0, 6)
            pPad.PaddingBottom = UDim.new(0, 6)
            pPad.PaddingLeft = UDim.new(0, 8)
            pPad.PaddingRight = UDim.new(0, 8)
            pPad.Parent = pop

            -- Color row
            local cRow = Instance.new("Frame")
            cRow.Size = UDim2.new(1, 0, 0, 18)
            cRow.BackgroundTransparency = 1
            cRow.Parent = pop

            local cLbl = Instance.new("TextLabel")
            cLbl.Size = UDim2.new(0.6, 0, 1, 0)
            cLbl.BackgroundTransparency = 1
            cLbl.Text = "Color"
            cLbl.TextColor3 = Color3.fromRGB(220, 225, 235)
            cLbl.TextSize = 12
            cLbl.Font = Theme.FontBold
            cLbl.TextXAlignment = Enum.TextXAlignment.Left
            cLbl.Parent = cRow

            local cChip = Instance.new("TextButton")
            cChip.Size = UDim2.new(0, 14, 0, 14)
            cChip.Position = UDim2.new(1, -16, 0.5, -7)
            cChip.BackgroundColor3 = MemeSensePlayers.Nickname.Color
            cChip.BorderSizePixel = 0
            cChip.Text = ""
            cChip.AutoButtonColor = false
            cChip.Parent = cRow
            createCorner(cChip, 3.5)

            cChip.MouseButton1Click:Connect(function()
                Controls:OpenColorPicker(cChip, MemeSensePlayers.Nickname.Color, 1, function(newCol)
                    cChip.BackgroundColor3 = newCol
                    MemeSensePlayers.Nickname.Color = newCol
                end)
            end)

            -- Font size row
            local sRow = Instance.new("Frame")
            sRow.Position = UDim2.new(0, 0, 0, 20)
            sRow.Size = UDim2.new(1, 0, 0, 20)
            sRow.BackgroundTransparency = 1
            sRow.Parent = pop

            local sLbl = Instance.new("TextLabel")
            sLbl.Size = UDim2.new(0.6, 0, 1, 0)
            sLbl.BackgroundTransparency = 1
            sLbl.Text = "Font size"
            sLbl.TextColor3 = Color3.fromRGB(220, 225, 235)
            sLbl.TextSize = 12
            sLbl.Font = Theme.FontBold
            sLbl.TextXAlignment = Enum.TextXAlignment.Left
            sLbl.Parent = sRow

            local sVal = Instance.new("TextLabel")
            sVal.Size = UDim2.new(0.4, 0, 1, 0)
            sVal.Position = UDim2.new(0.6, 0, 0, 0)
            sVal.BackgroundTransparency = 1
            sVal.Text = tostring(MemeSensePlayers.Nickname.FontSize) .. " px"
            sVal.TextColor3 = Color3.fromRGB(180, 185, 195)
            sVal.TextSize = 11
            sVal.Font = Theme.FontBold
            sVal.TextXAlignment = Enum.TextXAlignment.Right
            sVal.Parent = sRow

            local sHit = Instance.new("TextButton")
            sHit.Size = UDim2.new(1, 0, 0, 8)
            sHit.Position = UDim2.new(0, 0, 1, -6)
            sHit.BackgroundTransparency = 1
            sHit.Text = ""
            sHit.AutoButtonColor = false
            sHit.Parent = sRow

            local sTrack = Instance.new("Frame")
            sTrack.Size = UDim2.new(1, 0, 0, 3)
            sTrack.Position = UDim2.new(0, 0, 0.5, -1)
            sTrack.BackgroundColor3 = Color3.fromRGB(38, 40, 48)
            sTrack.BorderSizePixel = 0
            sTrack.Parent = sHit
            createCorner(sTrack, 1.5)

            local sFill = Instance.new("Frame")
            local initialPct = math.clamp((MemeSensePlayers.Nickname.FontSize - 8) / 10, 0, 1)
            sFill.Size = UDim2.new(initialPct, 0, 1, 0)
            sFill.BackgroundColor3 = Theme.Accent
            sFill.BorderSizePixel = 0
            sFill.Parent = sTrack
            createCorner(sFill, 1.5)

            local dragging = false
            local function updateSlider(input)
                local abs = sTrack.AbsolutePosition
                local w = sTrack.AbsoluteSize.X
                local pct = math.clamp((input.Position.X - abs.X) / w, 0, 1)
                local val = math.floor(8 + pct * 10 + 0.5)
                MemeSensePlayers.Nickname.FontSize = val
                sFill.Size = UDim2.new(pct, 0, 1, 0)
                sVal.Text = tostring(val) .. " px"
            end

            sHit.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    updateSlider(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    updateSlider(input)
                end
            end)

            local mousePos = UserInputService:GetMouseLocation()
            local popLayerPos = PopupsLayer and PopupsLayer.AbsolutePosition or Vector2.zero
            pop.Position = UDim2.new(0, mousePos.X - popLayerPos.X, 0, mousePos.Y - popLayerPos.Y)
            pop.Visible = true

            local outsideConn
            outsideConn = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    if not pop.Parent or not pop.Visible then
                        if outsideConn then outsideConn:Disconnect() end
                        return
                    end
                    if dragging then return end
                    local pos = input.Position
                    if isPosInGui(pop, pos) or isPosInGui(anchorBtn, pos) or (ColorPickerModal and ColorPickerModal.Visible and isPosInGui(ColorPickerModal, pos)) then
                        return
                    end
                    pop.Visible = false
                    pop:Destroy()
                    activeNicknamePop = nil
                    activeNicknameAnchor = nil
                    if outsideConn then outsideConn:Disconnect() end
                end
            end)
            table.insert(Connections, outsideConn)

            table.insert(ActivePopups, {
                Frame = pop,
                OnClose = function()
                    if outsideConn then outsideConn:Disconnect() end
                    pop.Visible = false
                    pop:Destroy()
                    activeNicknamePop = nil
                    activeNicknameAnchor = nil
                end
            })
        end

        local activeBoxPop = nil
        local activeBoxAnchor = nil
        local function openBoxPopover(anchorBtn)
            if activeBoxPop and activeBoxPop.Parent and activeBoxAnchor == anchorBtn then
                activeBoxPop.Visible = false
                activeBoxPop:Destroy()
                activeBoxPop = nil
                activeBoxAnchor = nil
                return
            end
            CloseAllPopups()
            activeBoxAnchor = anchorBtn

            local pop = Instance.new("Frame")
            pop.Name = "BoxPopover"
            pop.Size = UDim2.new(0, 180, 0, 102)
            pop.BackgroundColor3 = Color3.fromRGB(19, 20, 24)
            pop.BorderSizePixel = 0
            pop.ClipsDescendants = false
            pop.ZIndex = 520
            pop.Parent = PopupsLayer
            createCorner(pop, 3)
            activeBoxPop = pop

            local pPad = Instance.new("UIPadding")
            pPad.PaddingTop = UDim.new(0, 6)
            pPad.PaddingBottom = UDim.new(0, 6)
            pPad.PaddingLeft = UDim.new(0, 8)
            pPad.PaddingRight = UDim.new(0, 8)
            pPad.Parent = pop

            local dList = nil
            local r4Chev = nil
            local function closeDList()
                if dList and dList.Visible then
                    dList.Visible = false
                    if r4Chev then r4Chev.Text = "C" end
                end
            end

            -- Row 1: Color (Invis + Vis chips)
            local r1 = Instance.new("Frame")
            r1.Size = UDim2.new(1, 0, 0, 22)
            r1.BackgroundTransparency = 1
            r1.Parent = pop

            local r1Lbl = Instance.new("TextLabel")
            r1Lbl.Size = UDim2.new(0.5, 0, 1, 0)
            r1Lbl.BackgroundTransparency = 1
            r1Lbl.Text = "Color"
            r1Lbl.TextColor3 = Color3.fromRGB(220, 225, 235)
            r1Lbl.TextSize = 12
            r1Lbl.Font = Theme.FontBold
            r1Lbl.TextXAlignment = Enum.TextXAlignment.Left
            r1Lbl.Parent = r1

            local r1Invis = Instance.new("TextButton")
            r1Invis.Size = UDim2.new(0, 14, 0, 14)
            r1Invis.Position = UDim2.new(1, -38, 0.5, -7)
            r1Invis.BackgroundColor3 = MemeSensePlayers.Box.Color.Invis
            r1Invis.BorderSizePixel = 0; r1Invis.Text = ""; r1Invis.AutoButtonColor = false; r1Invis.Parent = r1
            createCorner(r1Invis, 3.5)
            r1Invis.MouseButton1Click:Connect(function()
                closeDList()
                Controls:OpenColorPicker(r1Invis, MemeSensePlayers.Box.Color.Invis, 1, function(c)
                    r1Invis.BackgroundColor3 = c; MemeSensePlayers.Box.Color.Invis = c
                end)
            end)

            local r1Vis = Instance.new("TextButton")
            r1Vis.Size = UDim2.new(0, 14, 0, 14)
            r1Vis.Position = UDim2.new(1, -16, 0.5, -7)
            r1Vis.BackgroundColor3 = MemeSensePlayers.Box.Color.Vis
            r1Vis.BorderSizePixel = 0; r1Vis.Text = ""; r1Vis.AutoButtonColor = false; r1Vis.Parent = r1
            createCorner(r1Vis, 3.5)
            r1Vis.MouseButton1Click:Connect(function()
                closeDList()
                Controls:OpenColorPicker(r1Vis, MemeSensePlayers.Box.Color.Vis, 1, function(c)
                    r1Vis.BackgroundColor3 = c; MemeSensePlayers.Box.Color.Vis = c
                end)
            end)

            -- Row 2: Filled (Checkbox + Invis + Vis chips)
            local r2 = Instance.new("Frame")
            r2.Position = UDim2.new(0, 0, 0, 24)
            r2.Size = UDim2.new(1, 0, 0, 22)
            r2.BackgroundTransparency = 1
            r2.Parent = pop

            local r2Box = Instance.new("TextButton")
            r2Box.Size = UDim2.new(0, 14, 0, 14)
            r2Box.Position = UDim2.new(0, 0, 0.5, -7)
            r2Box.BackgroundColor3 = MemeSensePlayers.Box.Filled and Theme.CheckboxChecked or Theme.CheckboxOff
            r2Box.BorderSizePixel = 0; r2Box.Text = ""; r2Box.AutoButtonColor = false; r2Box.Parent = r2
            createCorner(r2Box, 2.5)

            local r2Check = Instance.new("TextLabel")
            r2Check.Size = UDim2.new(1, 0, 1, 0)
            r2Check.BackgroundTransparency = 1
            r2Check.FontFace = GuiIconsFont
            r2Check.Text = "X"
            r2Check.TextColor3 = Color3.fromRGB(255, 255, 255)
            r2Check.TextSize = 11
            r2Check.Visible = MemeSensePlayers.Box.Filled
            r2Check.Parent = r2Box

            local r2Lbl = Instance.new("TextButton")
            r2Lbl.Position = UDim2.new(0, 20, 0, 0)
            r2Lbl.Size = UDim2.new(0.5, -20, 1, 0)
            r2Lbl.BackgroundTransparency = 1
            r2Lbl.Text = "Filled"
            r2Lbl.TextColor3 = MemeSensePlayers.Box.Filled and Theme.TextActive or Theme.TextDim
            r2Lbl.TextSize = 12
            r2Lbl.Font = Theme.FontBold
            r2Lbl.TextXAlignment = Enum.TextXAlignment.Left
            r2Lbl.Parent = r2

            local function toggleFilled()
                closeDList()
                MemeSensePlayers.Box.Filled = not MemeSensePlayers.Box.Filled
                r2Box.BackgroundColor3 = MemeSensePlayers.Box.Filled and Theme.CheckboxChecked or Theme.CheckboxOff
                r2Check.Visible = MemeSensePlayers.Box.Filled
                r2Lbl.TextColor3 = MemeSensePlayers.Box.Filled and Theme.TextActive or Theme.TextDim
            end
            r2Box.MouseButton1Click:Connect(toggleFilled)
            r2Lbl.MouseButton1Click:Connect(toggleFilled)

            local r2Invis = Instance.new("TextButton")
            r2Invis.Size = UDim2.new(0, 14, 0, 14)
            r2Invis.Position = UDim2.new(1, -38, 0.5, -7)
            r2Invis.BackgroundColor3 = MemeSensePlayers.Box.FillColor.Invis
            r2Invis.BorderSizePixel = 0; r2Invis.Text = ""; r2Invis.AutoButtonColor = false; r2Invis.Parent = r2
            createCorner(r2Invis, 3.5)
            r2Invis.MouseButton1Click:Connect(function()
                closeDList()
                Controls:OpenColorPicker(r2Invis, MemeSensePlayers.Box.FillColor.Invis, 1, function(c)
                    r2Invis.BackgroundColor3 = c; MemeSensePlayers.Box.FillColor.Invis = c
                end)
            end)

            local r2Vis = Instance.new("TextButton")
            r2Vis.Size = UDim2.new(0, 14, 0, 14)
            r2Vis.Position = UDim2.new(1, -16, 0.5, -7)
            r2Vis.BackgroundColor3 = MemeSensePlayers.Box.FillColor.Vis
            r2Vis.BorderSizePixel = 0; r2Vis.Text = ""; r2Vis.AutoButtonColor = false; r2Vis.Parent = r2
            createCorner(r2Vis, 3.5)
            r2Vis.MouseButton1Click:Connect(function()
                closeDList()
                Controls:OpenColorPicker(r2Vis, MemeSensePlayers.Box.FillColor.Vis, 1, function(c)
                    r2Vis.BackgroundColor3 = c; MemeSensePlayers.Box.FillColor.Vis = c
                end)
            end)

            -- Row 3: Outline (Checkbox + Invis + Vis chips)
            local r3 = Instance.new("Frame")
            r3.Position = UDim2.new(0, 0, 0, 48)
            r3.Size = UDim2.new(1, 0, 0, 22)
            r3.BackgroundTransparency = 1
            r3.Parent = pop

            local r3Box = Instance.new("TextButton")
            r3Box.Size = UDim2.new(0, 14, 0, 14)
            r3Box.Position = UDim2.new(0, 0, 0.5, -7)
            r3Box.BackgroundColor3 = MemeSensePlayers.Box.Outline and Theme.CheckboxChecked or Theme.CheckboxOff
            r3Box.BorderSizePixel = 0; r3Box.Text = ""; r3Box.AutoButtonColor = false; r3Box.Parent = r3
            createCorner(r3Box, 2.5)

            local r3Check = Instance.new("TextLabel")
            r3Check.Size = UDim2.new(1, 0, 1, 0)
            r3Check.BackgroundTransparency = 1
            r3Check.FontFace = GuiIconsFont
            r3Check.Text = "X"
            r3Check.TextColor3 = Color3.fromRGB(255, 255, 255)
            r3Check.TextSize = 11
            r3Check.Visible = MemeSensePlayers.Box.Outline
            r3Check.Parent = r3Box

            local r3Lbl = Instance.new("TextButton")
            r3Lbl.Position = UDim2.new(0, 20, 0, 0)
            r3Lbl.Size = UDim2.new(0.5, -20, 1, 0)
            r3Lbl.BackgroundTransparency = 1
            r3Lbl.Text = "Outline"
            r3Lbl.TextColor3 = MemeSensePlayers.Box.Outline and Theme.TextActive or Theme.TextDim
            r3Lbl.TextSize = 12
            r3Lbl.Font = Theme.FontBold
            r3Lbl.TextXAlignment = Enum.TextXAlignment.Left
            r3Lbl.Parent = r3

            local function toggleOutline()
                closeDList()
                MemeSensePlayers.Box.Outline = not MemeSensePlayers.Box.Outline
                r3Box.BackgroundColor3 = MemeSensePlayers.Box.Outline and Theme.CheckboxChecked or Theme.CheckboxOff
                r3Check.Visible = MemeSensePlayers.Box.Outline
                r3Lbl.TextColor3 = MemeSensePlayers.Box.Outline and Theme.TextActive or Theme.TextDim
            end
            r3Box.MouseButton1Click:Connect(toggleOutline)
            r3Lbl.MouseButton1Click:Connect(toggleOutline)

            local r3Invis = Instance.new("TextButton")
            r3Invis.Size = UDim2.new(0, 14, 0, 14)
            r3Invis.Position = UDim2.new(1, -38, 0.5, -7)
            r3Invis.BackgroundColor3 = MemeSensePlayers.Box.OutlineColor.Invis
            r3Invis.BorderSizePixel = 0; r3Invis.Text = ""; r3Invis.AutoButtonColor = false; r3Invis.Parent = r3
            createCorner(r3Invis, 3.5)
            r3Invis.MouseButton1Click:Connect(function()
                closeDList()
                Controls:OpenColorPicker(r3Invis, MemeSensePlayers.Box.OutlineColor.Invis, 1, function(c)
                    r3Invis.BackgroundColor3 = c; MemeSensePlayers.Box.OutlineColor.Invis = c
                end)
            end)

            local r3Vis = Instance.new("TextButton")
            r3Vis.Size = UDim2.new(0, 14, 0, 14)
            r3Vis.Position = UDim2.new(1, -16, 0.5, -7)
            r3Vis.BackgroundColor3 = MemeSensePlayers.Box.OutlineColor.Vis
            r3Vis.BorderSizePixel = 0; r3Vis.Text = ""; r3Vis.AutoButtonColor = false; r3Vis.Parent = r3
            createCorner(r3Vis, 3.5)
            r3Vis.MouseButton1Click:Connect(function()
                closeDList()
                Controls:OpenColorPicker(r3Vis, MemeSensePlayers.Box.OutlineColor.Vis, 1, function(c)
                    r3Vis.BackgroundColor3 = c; MemeSensePlayers.Box.OutlineColor.Vis = c
                end)
            end)

            -- Row 4: Type (Dropdown)
            local r4 = Instance.new("Frame")
            r4.Position = UDim2.new(0, 0, 0, 72)
            r4.Size = UDim2.new(1, 0, 0, 22)
            r4.BackgroundTransparency = 1
            r4.Parent = pop

            local r4Lbl = Instance.new("TextLabel")
            r4Lbl.Size = UDim2.new(0.4, 0, 1, 0)
            r4Lbl.BackgroundTransparency = 1
            r4Lbl.Text = "Type"
            r4Lbl.TextColor3 = Color3.fromRGB(220, 225, 235)
            r4Lbl.TextSize = 12
            r4Lbl.Font = Theme.FontBold
            r4Lbl.TextXAlignment = Enum.TextXAlignment.Left
            r4Lbl.Parent = r4

            local r4Dd = Instance.new("TextButton")
            r4Dd.Size = UDim2.new(0.55, 0, 0, 20)
            r4Dd.Position = UDim2.new(0.45, 0, 0.5, -10)
            r4Dd.BackgroundColor3 = Color3.fromRGB(24, 25, 30)
            r4Dd.BorderSizePixel = 0
            r4Dd.AutoButtonColor = false
            r4Dd.Text = ""
            r4Dd.Parent = r4
            createCorner(r4Dd, 3)
            createStroke(r4Dd, Theme.ControlBorder, 1)

            local r4Text = Instance.new("TextLabel")
            r4Text.Size = UDim2.new(1, -18, 1, 0)
            r4Text.Position = UDim2.new(0, 6, 0, 0)
            r4Text.BackgroundTransparency = 1
            r4Text.Text = MemeSensePlayers.Box.Type
            r4Text.TextColor3 = Theme.TextActive
            r4Text.TextSize = 11
            r4Text.Font = Theme.FontBold
            r4Text.TextXAlignment = Enum.TextXAlignment.Left
            r4Text.Parent = r4Dd

            r4Chev = Instance.new("TextLabel")
            r4Chev.Size = UDim2.new(0, 12, 1, 0)
            r4Chev.Position = UDim2.new(1, -14, 0, 0)
            r4Chev.BackgroundTransparency = 1
            r4Chev.FontFace = GuiIconsFont
            r4Chev.Text = "C"
            r4Chev.TextColor3 = Theme.TextDim
            r4Chev.TextSize = 10
            r4Chev.Parent = r4Dd

            dList = Instance.new("Frame")
            dList.Name = "TypeList"
            dList.Size = UDim2.new(0.55, 0, 0, 44)
            dList.Position = UDim2.new(0.45, 0, 0, 96)
            dList.BackgroundColor3 = Color3.fromRGB(19, 20, 24)
            dList.BorderSizePixel = 0
            dList.ZIndex = 540
            dList.Visible = false
            dList.Parent = pop
            createCorner(dList, 3)
            createStroke(dList, Theme.ControlBorder, 1)

            local optDefault = Instance.new("TextButton")
            optDefault.Size = UDim2.new(1, 0, 0, 22)
            optDefault.Position = UDim2.new(0, 0, 0, 0)
            optDefault.BackgroundTransparency = 1
            optDefault.Text = "Default"
            optDefault.TextColor3 = (MemeSensePlayers.Box.Type == "Default") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 165, 175)
            optDefault.Font = Theme.FontBold
            optDefault.TextSize = 11
            optDefault.TextXAlignment = Enum.TextXAlignment.Left
            optDefault.ZIndex = 541
            optDefault.AutoButtonColor = false
            optDefault.Parent = dList

            local optDefaultPad = Instance.new("UIPadding")
            optDefaultPad.PaddingLeft = UDim.new(0, 6)
            optDefaultPad.Parent = optDefault

            local optCorner = Instance.new("TextButton")
            optCorner.Size = UDim2.new(1, 0, 0, 22)
            optCorner.Position = UDim2.new(0, 0, 0, 22)
            optCorner.BackgroundTransparency = 1
            optCorner.Text = "Corner"
            optCorner.TextColor3 = (MemeSensePlayers.Box.Type == "Corner") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 165, 175)
            optCorner.Font = Theme.FontBold
            optCorner.TextSize = 11
            optCorner.TextXAlignment = Enum.TextXAlignment.Left
            optCorner.ZIndex = 541
            optCorner.AutoButtonColor = false
            optCorner.Parent = dList

            local optCornerPad = Instance.new("UIPadding")
            optCornerPad.PaddingLeft = UDim.new(0, 6)
            optCornerPad.Parent = optCorner

            local function updateOptionsHighlight()
                optDefault.TextColor3 = (MemeSensePlayers.Box.Type == "Default") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 165, 175)
                optCorner.TextColor3 = (MemeSensePlayers.Box.Type == "Corner") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 165, 175)
            end

            optDefault.MouseEnter:Connect(function()
                optDefault.TextColor3 = Color3.fromRGB(255, 255, 255)
            end)
            optDefault.MouseLeave:Connect(function()
                updateOptionsHighlight()
            end)
            optDefault.MouseButton1Click:Connect(function()
                MemeSensePlayers.Box.Type = "Default"
                r4Text.Text = "Default"
                dList.Visible = false
                r4Chev.Text = "C"
                updateOptionsHighlight()
            end)

            optCorner.MouseEnter:Connect(function()
                optCorner.TextColor3 = Color3.fromRGB(255, 255, 255)
            end)
            optCorner.MouseLeave:Connect(function()
                updateOptionsHighlight()
            end)
            optCorner.MouseButton1Click:Connect(function()
                MemeSensePlayers.Box.Type = "Corner"
                r4Text.Text = "Corner"
                dList.Visible = false
                r4Chev.Text = "C"
                updateOptionsHighlight()
            end)

            r4Dd.MouseButton1Click:Connect(function()
                dList.Visible = not dList.Visible
                r4Chev.Text = dList.Visible and "B" or "C"
                updateOptionsHighlight()
            end)

            local mousePos = UserInputService:GetMouseLocation()
            local popLayerPos = PopupsLayer and PopupsLayer.AbsolutePosition or Vector2.zero
            pop.Position = UDim2.new(0, mousePos.X - popLayerPos.X, 0, mousePos.Y - popLayerPos.Y)
            pop.Visible = true

            local outsideConn
            outsideConn = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    if not pop.Parent or not pop.Visible then
                        if outsideConn then outsideConn:Disconnect() end
                        return
                    end
                    local pos = input.Position
                    if isPosInGui(pop, pos) or isPosInGui(anchorBtn, pos) or (dList and dList.Visible and isPosInGui(dList, pos)) or (ColorPickerModal and ColorPickerModal.Visible and isPosInGui(ColorPickerModal, pos)) then
                        return
                    end
                    pop.Visible = false
                    pop:Destroy()
                    activeBoxPop = nil
                    activeBoxAnchor = nil
                    if outsideConn then outsideConn:Disconnect() end
                end
            end)
            table.insert(Connections, outsideConn)

            table.insert(ActivePopups, {
                Frame = pop,
                OnClose = function()
                    if outsideConn then outsideConn:Disconnect() end
                    pop.Visible = false
                    pop:Destroy()
                    activeBoxPop = nil
                    activeBoxAnchor = nil
                end
            })
        end

        local activeWeaponPop = nil
        local activeWeaponAnchor = nil
        local function openWeaponPopover(anchorBtn)
            if activeWeaponPop and activeWeaponPop.Parent and activeWeaponAnchor == anchorBtn then
                activeWeaponPop.Visible = false
                activeWeaponPop:Destroy()
                activeWeaponPop = nil
                activeWeaponAnchor = nil
                return
            end
            CloseAllPopups()
            activeWeaponAnchor = anchorBtn

            local pop = Instance.new("Frame")
            pop.Name = "WeaponPopover"
            pop.Size = UDim2.new(0, 175, 0, 52)
            pop.BackgroundColor3 = Color3.fromRGB(19, 20, 24)
            pop.BorderSizePixel = 0
            pop.ZIndex = 520
            pop.Parent = PopupsLayer
            createCorner(pop, 3)
            activeWeaponPop = pop

            local pPad = Instance.new("UIPadding")
            pPad.PaddingTop = UDim.new(0, 6)
            pPad.PaddingBottom = UDim.new(0, 6)
            pPad.PaddingLeft = UDim.new(0, 8)
            pPad.PaddingRight = UDim.new(0, 8)
            pPad.Parent = pop

            -- Row 1: Show weapon icon
            local r1 = Instance.new("Frame")
            r1.Size = UDim2.new(1, 0, 0, 22)
            r1.BackgroundTransparency = 1
            r1.Parent = pop

            local r1Box = Instance.new("TextButton")
            r1Box.Size = UDim2.new(0, 14, 0, 14)
            r1Box.Position = UDim2.new(0, 0, 0.5, -7)
            r1Box.BackgroundColor3 = MemeSensePlayers.Weapon.ShowIcon and Theme.CheckboxChecked or Theme.CheckboxOff
            r1Box.BorderSizePixel = 0; r1Box.Text = ""; r1Box.AutoButtonColor = false; r1Box.Parent = r1
            createCorner(r1Box, 2.5)

            local r1Check = Instance.new("TextLabel")
            r1Check.Size = UDim2.new(1, 0, 1, 0)
            r1Check.BackgroundTransparency = 1
            r1Check.FontFace = GuiIconsFont
            r1Check.Text = "X"
            r1Check.TextColor3 = Color3.fromRGB(255, 255, 255)
            r1Check.TextSize = 11
            r1Check.Visible = MemeSensePlayers.Weapon.ShowIcon
            r1Check.Parent = r1Box

            local r1Lbl = Instance.new("TextButton")
            r1Lbl.Position = UDim2.new(0, 20, 0, 0)
            r1Lbl.Size = UDim2.new(0.65, 0, 1, 0)
            r1Lbl.BackgroundTransparency = 1
            r1Lbl.Text = "Show weapon icon"
            r1Lbl.TextColor3 = MemeSensePlayers.Weapon.ShowIcon and Theme.TextActive or Theme.TextDim
            r1Lbl.TextSize = 12
            r1Lbl.Font = Theme.FontBold
            r1Lbl.TextXAlignment = Enum.TextXAlignment.Left
            r1Lbl.Parent = r1

            local function toggleIcon()
                MemeSensePlayers.Weapon.ShowIcon = not MemeSensePlayers.Weapon.ShowIcon
                r1Box.BackgroundColor3 = MemeSensePlayers.Weapon.ShowIcon and Theme.CheckboxChecked or Theme.CheckboxOff
                r1Check.Visible = MemeSensePlayers.Weapon.ShowIcon
                r1Lbl.TextColor3 = MemeSensePlayers.Weapon.ShowIcon and Theme.TextActive or Theme.TextDim
            end
            r1Box.MouseButton1Click:Connect(toggleIcon)
            r1Lbl.MouseButton1Click:Connect(toggleIcon)

            local r1Chip = Instance.new("TextButton")
            r1Chip.Size = UDim2.new(0, 14, 0, 14)
            r1Chip.Position = UDim2.new(1, -16, 0.5, -7)
            r1Chip.BackgroundColor3 = MemeSensePlayers.Weapon.IconColor
            r1Chip.BorderSizePixel = 0; r1Chip.Text = ""; r1Chip.AutoButtonColor = false; r1Chip.Parent = r1
            createCorner(r1Chip, 3.5)
            r1Chip.MouseButton1Click:Connect(function()
                Controls:OpenColorPicker(r1Chip, MemeSensePlayers.Weapon.IconColor, 1, function(c)
                    r1Chip.BackgroundColor3 = c; MemeSensePlayers.Weapon.IconColor = c
                end)
            end)

            -- Row 2: Show weapon name
            local r2 = Instance.new("Frame")
            r2.Position = UDim2.new(0, 0, 0, 24)
            r2.Size = UDim2.new(1, 0, 0, 22)
            r2.BackgroundTransparency = 1
            r2.Parent = pop

            local r2Box = Instance.new("TextButton")
            r2Box.Size = UDim2.new(0, 14, 0, 14)
            r2Box.Position = UDim2.new(0, 0, 0.5, -7)
            r2Box.BackgroundColor3 = MemeSensePlayers.Weapon.ShowName and Theme.CheckboxChecked or Theme.CheckboxOff
            r2Box.BorderSizePixel = 0; r2Box.Text = ""; r2Box.AutoButtonColor = false; r2Box.Parent = r2
            createCorner(r2Box, 2.5)

            local r2Check = Instance.new("TextLabel")
            r2Check.Size = UDim2.new(1, 0, 1, 0)
            r2Check.BackgroundTransparency = 1
            r2Check.FontFace = GuiIconsFont
            r2Check.Text = "X"
            r2Check.TextColor3 = Color3.fromRGB(255, 255, 255)
            r2Check.TextSize = 11
            r2Check.Visible = MemeSensePlayers.Weapon.ShowName
            r2Check.Parent = r2Box

            local r2Lbl = Instance.new("TextButton")
            r2Lbl.Position = UDim2.new(0, 20, 0, 0)
            r2Lbl.Size = UDim2.new(0.65, 0, 1, 0)
            r2Lbl.BackgroundTransparency = 1
            r2Lbl.Text = "Show weapon name"
            r2Lbl.TextColor3 = MemeSensePlayers.Weapon.ShowName and Theme.TextActive or Theme.TextDim
            r2Lbl.TextSize = 12
            r2Lbl.Font = Theme.FontBold
            r2Lbl.TextXAlignment = Enum.TextXAlignment.Left
            r2Lbl.Parent = r2

            local function toggleName()
                MemeSensePlayers.Weapon.ShowName = not MemeSensePlayers.Weapon.ShowName
                r2Box.BackgroundColor3 = MemeSensePlayers.Weapon.ShowName and Theme.CheckboxChecked or Theme.CheckboxOff
                r2Check.Visible = MemeSensePlayers.Weapon.ShowName
                r2Lbl.TextColor3 = MemeSensePlayers.Weapon.ShowName and Theme.TextActive or Theme.TextDim
            end
            r2Box.MouseButton1Click:Connect(toggleName)
            r2Lbl.MouseButton1Click:Connect(toggleName)

            local r2Chip = Instance.new("TextButton")
            r2Chip.Size = UDim2.new(0, 14, 0, 14)
            r2Chip.Position = UDim2.new(1, -16, 0.5, -7)
            r2Chip.BackgroundColor3 = MemeSensePlayers.Weapon.NameColor
            r2Chip.BorderSizePixel = 0; r2Chip.Text = ""; r2Chip.AutoButtonColor = false; r2Chip.Parent = r2
            createCorner(r2Chip, 3.5)
            r2Chip.MouseButton1Click:Connect(function()
                Controls:OpenColorPicker(r2Chip, MemeSensePlayers.Weapon.NameColor, 1, function(c)
                    r2Chip.BackgroundColor3 = c; MemeSensePlayers.Weapon.NameColor = c
                end)
            end)

            local mousePos = UserInputService:GetMouseLocation()
            local popLayerPos = PopupsLayer and PopupsLayer.AbsolutePosition or Vector2.zero
            pop.Position = UDim2.new(0, mousePos.X - popLayerPos.X, 0, mousePos.Y - popLayerPos.Y)
            pop.Visible = true

            local outsideConn
            outsideConn = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    if not pop.Parent or not pop.Visible then
                        if outsideConn then outsideConn:Disconnect() end
                        return
                    end
                    local pos = input.Position
                    if isPosInGui(pop, pos) or isPosInGui(anchorBtn, pos) or (ColorPickerModal and ColorPickerModal.Visible and isPosInGui(ColorPickerModal, pos)) then
                        return
                    end
                    pop.Visible = false
                    pop:Destroy()
                    activeWeaponPop = nil
                    activeWeaponAnchor = nil
                    if outsideConn then outsideConn:Disconnect() end
                end
            end)
            table.insert(Connections, outsideConn)

            table.insert(ActivePopups, {
                Frame = pop,
                OnClose = function()
                    if outsideConn then outsideConn:Disconnect() end
                    pop.Visible = false
                    pop:Destroy()
                    activeWeaponPop = nil
                    activeWeaponAnchor = nil
                end
            })
        end

        Controls:CreateToggle(PLeft, {
            Name = "Enable",
            Default = false,
            Keybind = { Key = nil, Type = "Always On" },
            LayoutOrder = nextPLeft(),
            Callback = function(v)
                MemeSensePlayers.Enable = v
            end
        })

        Controls:CreateToggle(PLeft, {
            Name = "Through wall",
            Default = false,
            LayoutOrder = nextPLeft(),
            Callback = function(v)
                MemeSensePlayers.ThroughWall = v
            end
        })

        Controls:CreateToggle(PLeft, {
            Name = "Nickname",
            Default = false,
            SettingsIcon = true,
            LayoutOrder = nextPLeft(),
            Callback = function(v)
                MemeSensePlayers.Nickname.Enabled = v
            end,
            OnSettingsClick = function(btn)
                openNicknamePopover(btn)
            end
        })

        Controls:CreateToggle(PLeft, {
            Name = "Box",
            Default = false,
            SettingsIcon = true,
            LayoutOrder = nextPLeft(),
            Callback = function(v)
                MemeSensePlayers.Box.Enabled = v
            end,
            OnSettingsClick = function(btn)
                openBoxPopover(btn)
            end
        })

        Controls:CreateToggle(PLeft, {
            Name = "Health bar",
            Default = false,
            LayoutOrder = nextPLeft(),
            Callback = function(v)
                MemeSensePlayers.HealthBar.Enabled = v
            end
        })

        Controls:CreateToggle(PLeft, {
            Name = "Armor bar",
            Default = false,
            ColorChip = Color3.fromRGB(255, 255, 255),
            Dropdown = { Options = { "Left", "Right", "Top", "Bottom" }, Default = "Left" },
            LayoutOrder = nextPLeft()
        })

        Controls:CreateToggle(PLeft, {
            Name = "Ammo bar",
            Default = false,
            ColorChip = Color3.fromRGB(255, 255, 255),
            Dropdown = { Options = { "Left", "Right", "Top", "Bottom" }, Default = "Left" },
            LayoutOrder = nextPLeft()
        })

        Controls:CreateToggle(PLeft, {
            Name = "Weapon",
            Default = false,
            SettingsIcon = true,
            LayoutOrder = nextPLeft(),
            Callback = function(v)
                MemeSensePlayers.Weapon.Enabled = v
            end,
            OnSettingsClick = function(btn)
                openWeaponPopover(btn)
            end
        })

        Controls:CreateToggle(PLeft, {
            Name = "Skeleton",
            Default = false,
            SettingsIcon = true,
            LayoutOrder = nextPLeft()
        })

        Controls:CreateToggle(PLeft, {
            Name = "Sound arrow",
            Default = false,
            SettingsIcon = true,
            LayoutOrder = nextPLeft()
        })

        Controls:CreateToggle(PLeft, {
            Name = "Out of FOV arrow",
            Default = false,
            SettingsIcon = true,
            LayoutOrder = nextPLeft()
        })

        Controls:CreateToggle(PLeft, {
            Name = "Sound world circles",
            Default = false,
            SettingsIcon = true,
            LayoutOrder = nextPLeft()
        })

        Controls:CreateSectionHeader(PRight, "Flags", nextPRight())

        local playerFlags = {
            { Name = "Bomb", Default = false },
            { Name = "Health", Default = false },
            { Name = "Ammo", Default = false },
            { Name = "Reload", Default = false },
            { Name = "Scoped", Default = false },
            { Name = "Flashed", Default = false },
            { Name = "Distance", Default = false },
            { Name = "Defuse kit", Default = false },
            { Name = "Helmet & kevlar", Default = false },
            { Name = "Defusing / rescuing", Default = false },
            { Name = "Pin pulled", Default = false },
            { Name = "Planting", Default = false }
        }

        for _, flag in ipairs(playerFlags) do
            Controls:CreateToggle(PRight, {
                Name = flag.Name,
                Default = flag.Default,
                SettingsIcon = true,
                LayoutOrder = nextPRight()
            })
        end
    end
    run()

-- =========================================================================
-- Players Tab 2D ESP Rendering Engine (Directly ported from base.luau)
-- =========================================================================
local CORE_LIMB_NAMES = {
    Head = true, Torso = true, UpperTorso = true, LowerTorso = true,
    LeftUpperArm = true, LeftLowerArm = true, LeftHand = true,
    RightUpperArm = true, RightLowerArm = true, RightHand = true,
    LeftUpperLeg = true, LeftLowerLeg = true, LeftFoot = true,
    RightUpperLeg = true, RightLowerLeg = true, RightFoot = true,
    ["Left Arm"] = true, ["Right Arm"] = true, ["Left Leg"] = true, ["Right Leg"] = true,
}

local CORNER_SIGNS = {
    Vector3.new(-1, -1, -1),
    Vector3.new( 1, -1, -1),
    Vector3.new(-1,  1, -1),
    Vector3.new( 1,  1, -1),
    Vector3.new(-1, -1,  1),
    Vector3.new( 1, -1,  1),
    Vector3.new(-1,  1,  1),
    Vector3.new( 1,  1,  1),
}

local function GetCharacterScreenBounds(char, rootPart)
    local camera = workspace.CurrentCamera
    if not camera then return nil, nil, false end

    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local anyOnScreen = false

    local partsToMeasure = {}
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("BasePart") and CORE_LIMB_NAMES[child.Name] and child.Transparency < 1 then
            table.insert(partsToMeasure, child)
        end
    end

    if #partsToMeasure == 0 then
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("BasePart") and not child:IsA("Accessory") and child.Name ~= "HumanoidRootPart" and child.Transparency < 1 then
                table.insert(partsToMeasure, child)
            end
        end
    end

    if #partsToMeasure == 0 then
        table.insert(partsToMeasure, rootPart)
    end

    for _, part in ipairs(partsToMeasure) do
        local pcf = part.CFrame
        local psize = part.Size * 0.5
        local px, py, pz = psize.X, psize.Y, psize.Z

        for _, sign in ipairs(CORNER_SIGNS) do
            local cornerWorld = pcf:PointToWorldSpace(Vector3.new(sign.X * px, sign.Y * py, sign.Z * pz))
            local screenPos, onScreen = camera:WorldToViewportPoint(cornerWorld)
            if screenPos.Z > 0 then
                anyOnScreen = true
                if screenPos.X < minX then minX = screenPos.X end
                if screenPos.X > maxX then maxX = screenPos.X end
                if screenPos.Y < minY then minY = screenPos.Y end
                if screenPos.Y > maxY then maxY = screenPos.Y end
            end
        end
    end

    if not anyOnScreen or minX == math.huge then
        return nil, nil, false
    end

    local topLeft = Vector2.new(minX, minY)
    local size = Vector2.new(maxX - minX, maxY - minY)
    return topLeft, size, true
end

local WEAPON_ICON_GLYPHS = {
    ["AK-47"] = "W",
    ["M4A4"] = "L",
    ["M4A1-S"] = "M",
    ["AWP"] = "Z",
    ["SSG 08"] = "a",
    ["Galil AR"] = "Q",
    ["FAMAS"] = "R",
    ["AUG"] = "U",
    ["SG 553"] = "V",
    ["G3SG1"] = "X",
    ["SCAR-20"] = "Y",
    ["Desert Eagle"] = "A",
    ["Glock-18"] = "C",
    ["USP-S"] = "P",
    ["P250"] = "F",
    ["Tec-9"] = "H",
    ["CZ75-Auto"] = "I",
    ["Five-SeveN"] = "E",
    ["Dual Berettas"] = "B",
    ["R8 Revolver"] = "J",
    ["MAC-10"] = "K",
    ["MP9"] = "N",
    ["MP7"] = "O",
    ["MP5-SD"] = "p",
    ["UMP-45"] = "b",
    ["P90"] = "c",
    ["PP-Bizon"] = "d",
    ["Nova"] = "e",
    ["XM1014"] = "f",
    ["MAG-7"] = "g",
    ["Sawed-Off"] = "k",
    ["M249"] = "i",
    ["Negev"] = "j",
    ["CT Knife"] = "1",
    ["T Knife"] = "1",
    ["Knife"] = "1",
    ["C4"] = "o",
    ["HE Grenade"] = "h",
    ["Flashbang"] = "i",
    ["Smoke Grenade"] = "k",
    ["Molotov"] = "l",
    ["Incendiary Grenade"] = "l",
    ["Decoy Grenade"] = "m",
    ["Zeus x27"] = "n",
    ["Defuse kit"] = "r",
}

local function getWeaponIconGlyph(name)
    if not name or name == "" then return "" end
    if WEAPON_ICON_GLYPHS[name] then
        return WEAPON_ICON_GLYPHS[name]
    end
    for baseName, glyph in pairs(WEAPON_ICON_GLYPHS) do
        if string.find(name, baseName) then
            return glyph
        end
    end
    local lName = string.lower(name)
    if string.find(lName, "knife") or string.find(lName, "karambit") or string.find(lName, "bayonet") or string.find(lName, "dagger") then
        return "1"
    end
    return "[" .. lName .. "]"
end

local playerDrawingObjects = {}

local function CreateESPDrawing()
    if not Drawing or not Drawing.new then return nil end

    local boxOutline = Drawing.new("Square")
    boxOutline.Thickness = 3
    boxOutline.Color = Color3.fromRGB(0, 0, 0)
    boxOutline.Filled = false
    boxOutline.Visible = false
    boxOutline.ZIndex = 1

    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Color = Color3.fromRGB(255, 255, 255)
    box.Filled = false
    box.Visible = false
    box.ZIndex = 2

    local boxFill = Drawing.new("Square")
    boxFill.Thickness = 0
    boxFill.Filled = true
    boxFill.Transparency = 0.85
    boxFill.Visible = false
    boxFill.ZIndex = 1

    local healthOutline = Drawing.new("Line")
    healthOutline.Thickness = 3
    healthOutline.Color = Color3.fromRGB(0, 0, 0)
    healthOutline.Visible = false
    healthOutline.ZIndex = 1

    local healthBar = Drawing.new("Line")
    healthBar.Thickness = 1
    healthBar.Color = Color3.fromRGB(0, 255, 120)
    healthBar.Visible = false
    healthBar.ZIndex = 2

    local fontToUse = Theme.CustomDrawingFont or (Drawing.Fonts and Drawing.Fonts.Monospace) or 3

    local healthText = Drawing.new("Text")
    healthText.Size = 9
    healthText.Font = fontToUse
    healthText.Text = ""
    healthText.Center = true
    healthText.Outline = true
    healthText.OutlineColor = Color3.fromRGB(0, 0, 0)
    healthText.Color = Color3.fromRGB(255, 255, 255)
    healthText.Visible = false
    healthText.ZIndex = 3

    local name = Drawing.new("Text")
    name.Size = 11
    name.Font = fontToUse
    name.Text = ""
    name.Center = true
    name.Outline = true
    name.OutlineColor = Color3.fromRGB(0, 0, 0)
    name.Color = Color3.fromRGB(255, 255, 255)
    name.Visible = false
    name.ZIndex = 3

    local weapon = Drawing.new("Text")
    weapon.Size = 9
    weapon.Font = fontToUse
    weapon.Text = ""
    weapon.Center = true
    weapon.Outline = true
    weapon.OutlineColor = Color3.fromRGB(0, 0, 0)
    weapon.Color = Color3.fromRGB(255, 255, 255)
    weapon.Visible = false
    weapon.ZIndex = 3

    local weaponIcon = Drawing.new("Text")
    weaponIcon.Size = 13
    weaponIcon.Font = Theme.VisualsIconsDrawingFont or fontToUse
    weaponIcon.Text = ""
    weaponIcon.Center = true
    weaponIcon.Outline = true
    weaponIcon.OutlineColor = Color3.fromRGB(0, 0, 0)
    weaponIcon.Color = Color3.fromRGB(255, 255, 255)
    weaponIcon.Visible = false
    weaponIcon.ZIndex = 3

    local cornerLines = {}
    for i = 1, 8 do
        local line = Drawing.new("Line")
        line.Thickness = 1
        line.Color = Color3.fromRGB(255, 255, 255)
        line.Visible = false
        line.ZIndex = 2
        cornerLines[i] = line
    end

    return {
        Box = box,
        BoxOutline = boxOutline,
        BoxFill = boxFill,
        HealthBar = healthBar,
        HealthOutline = healthOutline,
        HealthText = healthText,
        Name = name,
        Weapon = weapon,
        WeaponIcon = weaponIcon,
        CornerLines = cornerLines
    }
end

local function hideESPDrawing(grp)
    if not grp then return end
    grp.Box.Visible = false
    grp.BoxOutline.Visible = false
    grp.BoxFill.Visible = false
    grp.HealthBar.Visible = false
    grp.HealthOutline.Visible = false
    grp.HealthText.Visible = false
    grp.Name.Visible = false
    grp.Weapon.Visible = false
    if grp.WeaponIcon then grp.WeaponIcon.Visible = false end
    if grp.CornerLines then
        for _, l in ipairs(grp.CornerLines) do l.Visible = false end
    end
end

local function removeESPDrawing(grp)
    if not grp then return end
    pcall(function() grp.Box:Remove() end)
    pcall(function() grp.BoxOutline:Remove() end)
    pcall(function() grp.BoxFill:Remove() end)
    pcall(function() grp.HealthBar:Remove() end)
    pcall(function() grp.HealthOutline:Remove() end)
    pcall(function() grp.HealthText:Remove() end)
    pcall(function() grp.Name:Remove() end)
    pcall(function() grp.Weapon:Remove() end)
    if grp.CornerLines then
        for _, l in ipairs(grp.CornerLines) do pcall(function() l:Remove() end) end
    end
end

Players.PlayerRemoving:Connect(function(player)
    if playerDrawingObjects[player] then
        removeESPDrawing(playerDrawingObjects[player])
        playerDrawingObjects[player] = nil
    end
end)

local charsFolder = workspace:FindFirstChild("Characters")

local function espGetPlayerTeam(p)
    if not p then return nil end
    local attr = p:GetAttribute("Team")
    if attr and typeof(attr) == "string" and attr ~= "" then return attr end
    if p.Team then return p.Team.Name end
    local ch = p.Character or (charsFolder and charsFolder:FindFirstChild(p.Name))
    if ch then
        local cattr = ch:GetAttribute("Team")
        if cattr and typeof(cattr) == "string" and cattr ~= "" then return cattr end
    end
    return nil
end

local function espIsTeammate(p)
    if not p or p == LocalPlayer then return true end
    local isDM = workspace:GetAttribute("Gamemode") == "Deathmatch" or workspace:GetAttribute("ServerGamemode") == "Deathmatch"
    if isDM then return false end
    local myTeam = espGetPlayerTeam(LocalPlayer)
    local theirTeam = espGetPlayerTeam(p)
    if myTeam and theirTeam and myTeam ~= "Spectators" and myTeam ~= "" then
        return myTeam == theirTeam
    end
    return false
end

local espRayParams = RaycastParams.new()
espRayParams.FilterType = Enum.RaycastFilterType.Exclude

local function checkPlayerVisible(cameraPos, char, rootPart)
    local head = char:FindFirstChild("Head")
    local checkPart = head or rootPart
    if not checkPart then return false end
    local origin = cameraPos
    local targetPos = checkPart.Position
    local dir = targetPos - origin
    local dist = dir.Magnitude
    if dist <= 0.5 then return true end

    espRayParams.FilterDescendantsInstances = { workspace.CurrentCamera, LocalPlayer.Character }
    local hit = workspace:Raycast(origin, dir.Unit * (dist - 0.1), espRayParams)
    return not hit or hit.Instance:IsDescendantOf(char)
end

table.insert(Connections, RunService.RenderStepped:Connect(function()
    if not MemeSensePlayers.Enable then
        for _, grp in pairs(playerDrawingObjects) do
            hideESPDrawing(grp)
        end
        return
    end

    local camera = workspace.CurrentCamera
    if not camera then return end
    local camPos = camera.CFrame.Position

    local activePlayers = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if espIsTeammate(player) then
            if playerDrawingObjects[player] then
                hideESPDrawing(playerDrawingObjects[player])
            end
            continue
        end

        local char = (charsFolder and charsFolder:FindFirstChild(player.Name)) or player.Character
        if not char or not char:IsDescendantOf(workspace) then
            if playerDrawingObjects[player] then
                hideESPDrawing(playerDrawingObjects[player])
            end
            continue
        end

        if char:GetAttribute("Dead") == true or player:GetAttribute("Dead") == true then
            if playerDrawingObjects[player] then
                hideESPDrawing(playerDrawingObjects[player])
            end
            continue
        end

        if char:GetAttribute("ClientRagdoll") == true or char:GetAttribute("PreparedRagdoll") == true or char:GetAttribute("Ragdolled") == true then
            if playerDrawingObjects[player] then
                hideESPDrawing(playerDrawingObjects[player])
            end
            continue
        end

        local charHealth = char:GetAttribute("Health")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if typeof(charHealth) == "number" then
            if charHealth <= 0 then
                if playerDrawingObjects[player] then
                    hideESPDrawing(playerDrawingObjects[player])
                end
                continue
            end
        elseif hum then
            if hum.Health <= 0 then
                if playerDrawingObjects[player] then
                    hideESPDrawing(playerDrawingObjects[player])
                end
                continue
            end
        end

        local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Head")
        if not rootPart then
            if playerDrawingObjects[player] then
                hideESPDrawing(playerDrawingObjects[player])
            end
            continue
        end

        local isVis = checkPlayerVisible(camPos, char, rootPart)
        if not MemeSensePlayers.ThroughWall and not isVis then
            if playerDrawingObjects[player] then
                hideESPDrawing(playerDrawingObjects[player])
            end
            continue
        end

        local topLeft, boxSize, onScreen = GetCharacterScreenBounds(char, rootPart)
        if not onScreen or not topLeft or not boxSize then
            if playerDrawingObjects[player] then
                hideESPDrawing(playerDrawingObjects[player])
            end
            continue
        end

        activePlayers[player] = true

        if not playerDrawingObjects[player] then
            playerDrawingObjects[player] = CreateESPDrawing()
        end
        local grp = playerDrawingObjects[player]
        if not grp then continue end

        local boxX = math.floor(topLeft.X - 1)
        local boxY = math.floor(topLeft.Y - 1)
        local boxWidth = math.floor(boxSize.X + 2)
        local boxHeight = math.floor(boxSize.Y + 2)

        local curBoxCol = isVis and MemeSensePlayers.Box.Color.Vis or MemeSensePlayers.Box.Color.Invis
        local curFillCol = isVis and MemeSensePlayers.Box.FillColor.Vis or MemeSensePlayers.Box.FillColor.Invis
        local curOutCol = isVis and MemeSensePlayers.Box.OutlineColor.Vis or MemeSensePlayers.Box.OutlineColor.Invis

        -- 1. Box ESP (from base.luau)
        if MemeSensePlayers.Box.Enabled then
            if MemeSensePlayers.Box.Type == "Corner" then
                grp.Box.Visible = false
                grp.BoxOutline.Visible = false
                local cLen = math.clamp(math.floor(boxWidth * 0.25), 4, 14)
                local cLenH = math.clamp(math.floor(boxHeight * 0.25), 4, 14)
                local cl = grp.CornerLines
                cl[1].From = Vector2.new(boxX, boxY); cl[1].To = Vector2.new(boxX + cLen, boxY); cl[1].Color = curBoxCol; cl[1].Visible = true
                cl[2].From = Vector2.new(boxX, boxY); cl[2].To = Vector2.new(boxX, boxY + cLenH); cl[2].Color = curBoxCol; cl[2].Visible = true
                cl[3].From = Vector2.new(boxX + boxWidth - cLen, boxY); cl[3].To = Vector2.new(boxX + boxWidth, boxY); cl[3].Color = curBoxCol; cl[3].Visible = true
                cl[4].From = Vector2.new(boxX + boxWidth, boxY); cl[4].To = Vector2.new(boxX + boxWidth, boxY + cLenH); cl[4].Color = curBoxCol; cl[4].Visible = true
                cl[5].From = Vector2.new(boxX, boxY + boxHeight); cl[5].To = Vector2.new(boxX + cLen, boxY + boxHeight); cl[5].Color = curBoxCol; cl[5].Visible = true
                cl[6].From = Vector2.new(boxX, boxY + boxHeight - cLenH); cl[6].To = Vector2.new(boxX, boxY + boxHeight); cl[6].Color = curBoxCol; cl[6].Visible = true
                cl[7].From = Vector2.new(boxX + boxWidth - cLen, boxY + boxHeight); cl[7].To = Vector2.new(boxX + boxWidth, boxY + boxHeight); cl[7].Color = curBoxCol; cl[7].Visible = true
                cl[8].From = Vector2.new(boxX + boxWidth, boxY + boxHeight - cLenH); cl[8].To = Vector2.new(boxX + boxWidth, boxY + boxHeight); cl[8].Color = curBoxCol; cl[8].Visible = true
            else
                if grp.CornerLines then
                    for _, l in ipairs(grp.CornerLines) do l.Visible = false end
                end
                if MemeSensePlayers.Box.Outline then
                    grp.BoxOutline.Size = Vector2.new(boxWidth, boxHeight)
                    grp.BoxOutline.Position = Vector2.new(boxX, boxY)
                    grp.BoxOutline.Color = curOutCol
                    grp.BoxOutline.Visible = true
                else
                    grp.BoxOutline.Visible = false
                end

                grp.Box.Size = Vector2.new(boxWidth, boxHeight)
                grp.Box.Position = Vector2.new(boxX, boxY)
                grp.Box.Color = curBoxCol
                grp.Box.Visible = true
            end

            if MemeSensePlayers.Box.Filled then
                grp.BoxFill.Size = Vector2.new(boxWidth, boxHeight)
                grp.BoxFill.Position = Vector2.new(boxX, boxY)
                grp.BoxFill.Color = curFillCol
                grp.BoxFill.Visible = true
            else
                grp.BoxFill.Visible = false
            end
        else
            grp.Box.Visible = false
            grp.BoxOutline.Visible = false
            grp.BoxFill.Visible = false
            if grp.CornerLines then
                for _, l in ipairs(grp.CornerLines) do l.Visible = false end
            end
        end

        -- 2. Healthbar ESP (from base.luau)
        if MemeSensePlayers.HealthBar.Enabled then
            local attrMax = char:GetAttribute("MaxHealth")
            local maxHealth = (typeof(attrMax) == "number" and attrMax > 0) and attrMax or (hum and hum.MaxHealth and hum.MaxHealth > 0 and hum.MaxHealth or 100)
            local curHp = (typeof(charHealth) == "number") and charHealth or (hum and hum.Health or 100)
            local curHealth = math.clamp(curHp, 0, maxHealth)
            local healthPct = math.clamp(curHealth / maxHealth, 0, 1)

            local barX = boxX - 4
            local startY = boxY + boxHeight
            local currentHealthY = startY - (boxHeight * healthPct)
            local endY = boxY

            grp.HealthOutline.Thickness = 3
            grp.HealthOutline.From = Vector2.new(barX, startY + 1)
            grp.HealthOutline.To = Vector2.new(barX, endY - 1)
            grp.HealthOutline.Color = Color3.fromRGB(0, 0, 0)
            grp.HealthOutline.Visible = true

            local barColor = Color3.fromRGB(0, 255, 120)

            grp.HealthBar.Thickness = 1
            grp.HealthBar.From = Vector2.new(barX, startY)
            grp.HealthBar.To = Vector2.new(barX, currentHealthY)
            grp.HealthBar.Color = barColor
            grp.HealthBar.Visible = true

            grp.HealthText.Visible = false
        else
            grp.HealthBar.Visible = false
            grp.HealthOutline.Visible = false
            grp.HealthText.Visible = false
        end

        -- 3. Nickname
        if MemeSensePlayers.Nickname.Enabled then
            grp.Name.Text = player.DisplayName or player.Name
            grp.Name.Size = MemeSensePlayers.Nickname.FontSize or 11
            grp.Name.Color = MemeSensePlayers.Nickname.Color
            grp.Name.Position = Vector2.new(boxX + (boxWidth / 2), boxY - 13)
            grp.Name.Visible = true
        else
            grp.Name.Visible = false
        end

        -- 4. Weapon
        local wepEnabled = MemeSensePlayers.Weapon.Enabled and (MemeSensePlayers.Weapon.ShowName or MemeSensePlayers.Weapon.ShowIcon)
        if wepEnabled then
            local currentEq = player:GetAttribute("CurrentEquipped")
            local wName = (typeof(currentEq) == "string" and string.match(currentEq, '"Name"%s*:%s*"([^"]+)"'))
            if not wName or wName == "" then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then wName = tool.Name end
            end
            if wName and wName ~= "" then
                local currentY = boxY + boxHeight + 2

                if MemeSensePlayers.Weapon.ShowName then
                    grp.Weapon.Text = wName
                    grp.Weapon.Color = MemeSensePlayers.Weapon.NameColor or Color3.fromRGB(255, 255, 255)
                    grp.Weapon.Position = Vector2.new(boxX + (boxWidth / 2), currentY)
                    grp.Weapon.Visible = true
                    currentY = currentY + 11
                else
                    grp.Weapon.Visible = false
                end

                if MemeSensePlayers.Weapon.ShowIcon then
                    local glyph = getWeaponIconGlyph(wName)
                    grp.WeaponIcon.Text = glyph
                    grp.WeaponIcon.Color = MemeSensePlayers.Weapon.IconColor or Color3.fromRGB(255, 255, 255)
                    grp.WeaponIcon.Position = Vector2.new(boxX + (boxWidth / 2), currentY)
                    grp.WeaponIcon.Visible = true
                else
                    grp.WeaponIcon.Visible = false
                end
            else
                grp.Weapon.Visible = false
                grp.WeaponIcon.Visible = false
            end
        else
            grp.Weapon.Visible = false
            grp.WeaponIcon.Visible = false
        end
    end

    for plr, grp in pairs(playerDrawingObjects) do
        if not activePlayers[plr] then
            hideESPDrawing(grp)
        end
    end
end))
end)()

local MemeSenseChams = {
    Players = {
        Enemy = {
            Glow = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Transparency = 0 },
            Visible = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Transparency = 0, Style = "Bloom" },
            Invisible = { Enabled = false, Color = Color3.fromRGB(0, 255, 255), Transparency = 0, Style = "Bloom" },
        },
        Team = {
            Glow = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Transparency = 0 },
            Visible = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Transparency = 0, Style = "Bloom" },
            Invisible = { Enabled = false, Color = Color3.fromRGB(0, 255, 255), Transparency = 0, Style = "Bloom" },
        },
    },
    Ragdolls = {},
    LocalPlayer = {
        Glow = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Transparency = 0 },
        Visible = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Transparency = 0, Style = "Bloom" },
        Invisible = { Enabled = false, Color = Color3.fromRGB(0, 255, 255), Transparency = 0, Style = "Bloom" },
        Arms = {
            Hands = { Enabled = false, Color = Color3.fromRGB(80, 140, 255), Transparency = 0, Style = "Bloom" },
            Weapons = { Enabled = false, Color = Color3.fromRGB(115, 175, 200), Transparency = 0, Style = "Bloom" },
        },
    },
}

;(function()
    local function isChamsMasterOn()
        if tabMasterStates["Chams"] == false then
            local p = MemeSenseChams and MemeSenseChams.Players
            local lp = MemeSenseChams and MemeSenseChams.LocalPlayer
            if p and lp then
                if ((p.Enemy.Glow and p.Enemy.Glow.Enabled) or p.Enemy.Visible.Enabled or p.Enemy.Invisible.Enabled
                    or (p.Team.Glow and p.Team.Glow.Enabled) or p.Team.Visible.Enabled or p.Team.Invisible.Enabled
                    or (lp.Glow and lp.Glow.Enabled) or lp.Visible.Enabled or lp.Invisible.Enabled
                    or lp.Arms.Hands.Enabled or lp.Arms.Weapons.Enabled) then
                    tabMasterStates["Chams"] = true
                    if updateMasterSwitchUI then updateMasterSwitchUI() end
                    return true
                end
            end
            return false
        end
        return true
    end

    local function getChamFolder()
        local cam = workspace.CurrentCamera or workspace:FindFirstChildOfClass("Camera")
        if not cam then return nil end
        local folder = cam:FindFirstChild("ChamHolder")
        if not folder then
            folder = Instance.new("Folder")
            folder.Name = "ChamHolder"
            folder.Parent = cam
        elseif folder.Parent ~= cam then
            folder.Parent = cam
        end
        return folder
    end

    local activeProxies = {}

    local function getPlayerTeam(player)
        if not player then return nil end
        local attr = player:GetAttribute("Team")
        if attr and typeof(attr) == "string" and attr ~= "" then
            return attr
        end
        if player.Team then
            return player.Team.Name
        end
        local char = player.Character or (workspace:FindFirstChild("Characters") and workspace.Characters:FindFirstChild(player.Name))
        if char then
            local cattr = char:GetAttribute("Team")
            if cattr and typeof(cattr) == "string" and cattr ~= "" then
                return cattr
            end
        end
        return nil
    end

    local function isTeammate(player)
        if not player then return false end
        if player == LocalPlayer then return true end
        local isDM = workspace:GetAttribute("Gamemode") == "Deathmatch" or workspace:GetAttribute("ServerGamemode") == "Deathmatch"
        if isDM then
            return false
        end

        local myTeam = getPlayerTeam(LocalPlayer)
        local theirTeam = getPlayerTeam(player)

        if myTeam and theirTeam and myTeam ~= "Spectators" and myTeam ~= "" then
            return myTeam == theirTeam
        end

        return false
    end

    local function isRealAlivePlayer(player, char)
        if not player or typeof(player) ~= "Instance" or not player:IsA("Player") or player.Parent ~= Players then
            return false
        end
        if player:GetAttribute("IsSpectating") == true or player:GetAttribute("Dead") == true then
            return false
        end
        local pTeam = getPlayerTeam(player)
        if pTeam == "Spectators" or pTeam == "" then
            return false
        end

        if not char or typeof(char) ~= "Instance" or not char:IsA("Model") or not char.Parent then
            return false
        end
        if char.Parent.Name == "Debris" or not char:IsDescendantOf(workspace) then
            return false
        end

        local charsFolder = workspace:FindFirstChild("Characters")
        local realChar = (charsFolder and charsFolder:FindFirstChild(player.Name)) or player.Character
        if realChar and char ~= realChar and char ~= player.Character then
            return false
        end

        if char:GetAttribute("ClientRagdoll") == true
            or char:GetAttribute("PreparedRagdoll") == true
            or char:GetAttribute("Ragdolled") == true
            or string.find(char.Name, "Ragdoll")
            or string.find(char.Name, "Corpse")
            or string.find(char.Name, "Menu") then
            return false
        end

        if char:GetAttribute("Dead") == true then
            return false
        end

        local hp = char:GetAttribute("Health")
        if typeof(hp) == "number" and hp <= 0 then
            return false
        end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            return false
        end

        local head = char:FindFirstChild("Head")
        if not head then
            return false
        end

        return true
    end

    local function getStyleMaterialAndTransparency(style)
        if style == "Bloom" then
            return Enum.Material.Neon, 0
        elseif style == "Flat" then
            return Enum.Material.Plastic, 0
        elseif style == "Glass" then
            return Enum.Material.Glass, 0.25
        elseif style == "Textured" then
            return Enum.Material.Foil, 0
        elseif style == "Model" then
            return Enum.Material.Plastic, 0
        end
        return Enum.Material.Neon, 0
    end

    local visRayParams = RaycastParams.new()
    visRayParams.FilterType = Enum.RaycastFilterType.Exclude
    visRayParams.IgnoreWater = true
    local chamBaseFilter = table.create(16)

    local function isPassThroughPart(part)
        if not part or not part:IsA("BasePart") then return false end
        if part.Transparency >= 0.95 then return true end
        if not part.CanCollide and (part.Transparency > 0.5 or not part.CastShadow) then return true end
        local name = part.Name
        if name == "Hitbox" or name == "RaycastIgnore" or name == "Clip" or name == "Trigger" or name == "Bounds" or name == "Zone" or name == "Barrier" then
            return true
        end
        return false
    end

    local function castVisRay(origin, targetPos, targetPart, char)
        local dir = targetPos - origin
        local totalDist = dir.Magnitude
        if totalDist <= 0.05 then return true, totalDist end
        local unitDir = dir.Unit

        local hit = workspace:Raycast(origin, unitDir * totalDist, visRayParams)
        if not hit then
            return true, totalDist
        end

        local hitInst = hit.Instance
        if hitInst == targetPart or hitInst:IsDescendantOf(targetPart) then
            return true, (hit.Position - origin).Magnitude
        end

        if char and (hitInst == char or hitInst:IsDescendantOf(char)) then
            return true, (hit.Position - origin).Magnitude
        end

        if isPassThroughPart(hitInst) then
            local stepDist = (hit.Position - origin).Magnitude + 0.05
            if stepDist < totalDist then
                local hit2 = workspace:Raycast(hit.Position + (unitDir * 0.05), unitDir * (totalDist - stepDist), visRayParams)
                if not hit2 then return true, totalDist end
                local hit2Inst = hit2.Instance
                if hit2Inst == targetPart or hit2Inst:IsDescendantOf(targetPart) or (char and (hit2Inst == char or hit2Inst:IsDescendantOf(char))) then
                    return true, (hit2.Position - origin).Magnitude
                end
            else
                return true, totalDist
            end
        end

        return false, (hit.Position - origin).Magnitude
    end

    local function checkPartVisibility(cameraPos, targetPart, char)
        if not targetPart or not targetPart.Parent then return false, 0 end
        return castVisRay(cameraPos, targetPart.Position, targetPart, char)
    end

    local function isPartVisible(cameraPos, targetPart, char)
        local vis = checkPartVisibility(cameraPos, targetPart, char)
        return vis
    end

    local function createChamEntry(holder, characterOrModel, targetPart)
        local visualPart
        local isHead = (targetPart.Name == "Head")

        if isHead then
            visualPart = Instance.new("Part")
            visualPart.Shape = Enum.PartType.Cylinder
            visualPart.Name = "ChamProxy_" .. targetPart.Name
        elseif targetPart:IsA("MeshPart") then
            visualPart = targetPart:Clone()
            for _, child in ipairs(visualPart:GetChildren()) do
                child:Destroy()
            end
            visualPart.TextureID = ""
            visualPart.Name = "ChamProxy_" .. targetPart.Name
        elseif targetPart:FindFirstChildOfClass("SpecialMesh") then
            visualPart = targetPart:Clone()
            for _, child in ipairs(visualPart:GetChildren()) do
                if not child:IsA("SpecialMesh") then
                    child:Destroy()
                end
            end
            visualPart.Name = "ChamProxy_" .. targetPart.Name
        else
            visualPart = Instance.new("Part")
            visualPart.Name = "ChamProxy_" .. targetPart.Name
        end

        visualPart.Material = Enum.Material.Neon
        visualPart.Color = Color3.fromRGB(255, 255, 255)
        visualPart.Transparency = 1
        visualPart.CanCollide = false
        visualPart.CanTouch = false
        visualPart.CanQuery = false
        visualPart.CastShadow = false
        visualPart.Anchored = true
        visualPart.Size = targetPart.Size
        visualPart.Parent = getChamFolder() or workspace

        local origSA = (not isHead) and targetPart:FindFirstChildOfClass("SurfaceAppearance")
        local cachedSA = origSA and origSA:Clone() or nil
        local origSM = (not isHead) and targetPart:FindFirstChildOfClass("SpecialMesh")
        local cachedMeshScale = origSM and origSM.Scale or Vector3.new(1, 1, 1)
        local origTexture = ""
        if not isHead then
            if targetPart:IsA("MeshPart") then
                origTexture = targetPart.TextureID
            elseif origSM then
                origTexture = origSM.TextureId
            end
        end

        return {
            target = targetPart,
            visual = visualPart,
            isHead = isHead,
            origMaterial = targetPart.Material,
            origColor = targetPart.Color,
            origTransparency = targetPart.Transparency,
            origTexture = origTexture,
            origSA = cachedSA,
            origMeshScale = cachedMeshScale,
            lastStyle = nil,
            lastColor = nil,
            lastTrans = nil,
            currentTrans = 1,
        }
    end

    local function applyPartStyle(item, targetConfig)
        local visualPart = item.visual
        local style = targetConfig.Style or "Bloom"
        local color = targetConfig.Color or Color3.fromRGB(255, 255, 255)
        local trans = targetConfig.Transparency or 0

        if item.isHead then
            pcall(function() visualPart.Shape = Enum.PartType.Cylinder end)
            local sa = visualPart:FindFirstChildOfClass("SurfaceAppearance")
            if sa then sa:Destroy() end
            if style == "Bloom" then
                visualPart.Material = Enum.Material.Neon
                visualPart.Transparency = trans
            elseif style == "Flat" then
                visualPart.Material = Enum.Material.Plastic
                visualPart.Transparency = trans
            elseif style == "Glass" then
                visualPart.Material = Enum.Material.Glass
                visualPart.Transparency = if trans == 0 then 0.25 else trans
            elseif style == "Textured" then
                visualPart.Material = Enum.Material.Foil
                visualPart.Transparency = trans
            else
                visualPart.Material = Enum.Material.Plastic
                visualPart.Transparency = trans
            end
            visualPart.Color = color
            return
        end

        if style == "Bloom" then
            local sa = visualPart:FindFirstChildOfClass("SurfaceAppearance")
            if sa then sa:Destroy() end
            if visualPart:IsA("MeshPart") and visualPart.TextureID ~= "" then
                visualPart.TextureID = ""
            end
            visualPart.Material = Enum.Material.Neon
            visualPart.Color = color
            visualPart.Transparency = trans
        elseif style == "Flat" then
            local sa = visualPart:FindFirstChildOfClass("SurfaceAppearance")
            if sa then sa:Destroy() end
            if visualPart:IsA("MeshPart") and visualPart.TextureID ~= "" then
                visualPart.TextureID = ""
            end
            visualPart.Material = Enum.Material.Plastic
            visualPart.Color = color
            visualPart.Transparency = trans
        elseif style == "Glass" then
            local sa = visualPart:FindFirstChildOfClass("SurfaceAppearance")
            if sa then sa:Destroy() end
            if visualPart:IsA("MeshPart") and visualPart.TextureID ~= "" then
                visualPart.TextureID = ""
            end
            visualPart.Material = Enum.Material.Glass
            visualPart.Color = color
            visualPart.Transparency = if trans == 0 then 0.25 else trans
        elseif style == "Textured" then
            local sa = visualPart:FindFirstChildOfClass("SurfaceAppearance")
            if sa then sa:Destroy() end
            if visualPart:IsA("MeshPart") and visualPart.TextureID ~= "" then
                visualPart.TextureID = ""
            end
            visualPart.Material = Enum.Material.Foil
            visualPart.Color = color
            visualPart.Transparency = trans
        elseif style == "Model" then
            if item.origSA then
                local curSA = visualPart:FindFirstChildOfClass("SurfaceAppearance")
                if not curSA then
                    local newSA = item.origSA:Clone()
                    newSA.AlphaMode = Enum.AlphaMode.Overlay
                    newSA.Parent = visualPart
                else
                    curSA.AlphaMode = Enum.AlphaMode.Overlay
                end
            elseif item.origTexture ~= "" and visualPart:IsA("MeshPart") then
                visualPart.TextureID = item.origTexture
            end
            visualPart.Material = item.origMaterial or Enum.Material.Plastic
            visualPart.Color = color
            visualPart.Transparency = trans
        end
    end

    local function clearPlayerCham(player)
        local data = activeProxies[player]
        if not data then return end
        for _, conn in ipairs(data.connections) do pcall(function() conn:Disconnect() end) end
        local isDead = false
        if data.char and data.char.Parent and player ~= LocalPlayer then
            isDead = (data.char:GetAttribute("Dead") == true) or (player and player:GetAttribute("Dead") == true)
            local hum = data.char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health <= 0 then isDead = true end
            if isDead then
                deadCharactersToHide[data.char] = true
            end
        end
        for _, item in ipairs(data.parts) do
            pcall(function()
                if item.target and item.target.Parent and player ~= LocalPlayer then
                    if not isDead then
                        item.target.LocalTransparencyModifier = 0
                    else
                        item.target.LocalTransparencyModifier = 1
                    end
                end
                if item.visual then item.visual:Destroy() end
                if item.origSA then item.origSA:Destroy() end
            end)
        end
        if data.highlight then
            pcall(function() data.highlight:Destroy() end)
            data.highlight = nil
        end
        if data.char and data.char.Parent and player ~= LocalPlayer then
            if isDead then
                pcall(function()
                    for _, desc in ipairs(data.char:GetDescendants()) do
                        if desc:IsA("BasePart") then
                            desc.LocalTransparencyModifier = 1
                        end
                    end
                end)
            else
                pcall(function()
                    for _, desc in ipairs(data.char:GetDescendants()) do
                        if desc:IsA("BasePart") and string.sub(desc.Name, 1, 9) ~= "ChamProxy" then
                            desc.LocalTransparencyModifier = 0
                        end
                    end
                end)
            end
        end
        activeProxies[player] = nil
    end

    local function setupPlayerChams(player)
        if not player or typeof(player) ~= "Instance" or not player:IsA("Player") or player.Parent ~= Players then
            return
        end

        local function onCharacterAdded(character)
            if not character or not character.Parent then return end
            if not player or player.Parent ~= Players then return end
            for deadChar, _ in pairs(deadCharactersToHide) do
                if deadChar.Name == player.Name or (player.Character and deadChar == player.Character) then
                    deadCharactersToHide[deadChar] = nil
                end
            end

            if character:GetAttribute("ClientRagdoll") == true
                or character:GetAttribute("PreparedRagdoll") == true
                or character:GetAttribute("Ragdolled") == true
                or string.find(character.Name, "Ragdoll")
                or string.find(character.Name, "Corpse") then
                return
            end
            local charType = character:GetAttribute("CharacterType")
            if charType ~= nil and charType ~= "PlayerCustomCharacter" then
                return
            end
            if character:GetAttribute("Dead") == true then
                return
            end

            clearPlayerCham(player)
            local proxyData = { char = character, parts = {}, connections = {}, highlight = nil }

            pcall(function()
                for _, desc in ipairs(character:GetDescendants()) do
                    if desc:IsA("BoxHandleAdornment") and string.sub(desc.Name, 1, 13) == "HiddenESPBox_" then
                        desc:Destroy()
                    end
                end
            end)

            local function addPart(child)
                if not isValidChamPart(child) then return end
                for _, existing in ipairs(proxyData.parts) do
                    if existing.target == child then return end
                end
                table.insert(proxyData.parts, createChamEntry(player, character, child))
            end

            for _, desc in ipairs(character:GetDescendants()) do
                addPart(desc)
            end

            table.insert(proxyData.connections, character.DescendantAdded:Connect(function(desc)
                if desc:IsA("BasePart") and isValidChamPart(desc) then
                    task.delay(0.02, function() addPart(desc) end)
                end
            end))
            table.insert(proxyData.connections, character.DescendantRemoving:Connect(function(desc)
                for i, item in ipairs(proxyData.parts) do
                    if item.target == desc then
                        pcall(function()
                            if item.visual then item.visual:Destroy() end
                            if item.origSA then item.origSA:Destroy() end
                        end)
                        table.remove(proxyData.parts, i)
                        break
                    end
                end
            end))
            table.insert(proxyData.connections, character:GetAttributeChangedSignal("Dead"):Connect(function()
                if character:GetAttribute("Dead") == true then clearPlayerCham(player) end
            end))
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                table.insert(proxyData.connections, humanoid.Died:Connect(function() clearPlayerCham(player) end))
            end
            table.insert(proxyData.connections, character.AncestryChanged:Connect(function(_, parent)
                if not parent or parent.Name == "Debris" then clearPlayerCham(player) end
            end))
            activeProxies[player] = proxyData
        end

        local charConn = player.CharacterAdded:Connect(onCharacterAdded)
        table.insert(Connections, charConn)
        local propConn = player:GetPropertyChangedSignal("Character"):Connect(function()
            if player.Character then onCharacterAdded(player.Character) end
        end)
        local charsFolder = workspace:FindFirstChild("Characters")
        local initialChar = (charsFolder and charsFolder:FindFirstChild(player.Name)) or player.Character
        if initialChar and isRealAlivePlayer(player, initialChar) then
            task.spawn(onCharacterAdded, initialChar)
        end
    end

    local lastChamScanTick = 0
    local function scanAndRegisterAllCharacters()
        local charsFolder = workspace:FindFirstChild("Characters")
        for _, player in ipairs(Players:GetPlayers()) do
            local char = (charsFolder and charsFolder:FindFirstChild(player.Name)) or player.Character
            if char and char.Parent and isRealAlivePlayer(player, char) then
                local proxyData = activeProxies[player]
                if not proxyData or proxyData.char ~= char then
                    setupPlayerChams(player)
                else
                    for _, desc in ipairs(char:GetDescendants()) do
                        if desc:IsA("BasePart") and isValidChamPart(desc) then
                            local found = false
                            for _, item in ipairs(proxyData.parts) do
                                if item.target == desc then
                                    found = true
                                    break
                                end
                            end
                            if not found then
                                table.insert(proxyData.parts, createChamEntry(player, char, desc))
                            end
                        end
                    end
                end
            end
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do setupPlayerChams(p) end
    table.insert(Connections, Players.PlayerAdded:Connect(setupPlayerChams))
    table.insert(Connections, Players.PlayerRemoving:Connect(clearPlayerCham))

    local charsFolder = workspace:FindFirstChild("Characters")
    if charsFolder then
        table.insert(Connections, charsFolder.ChildAdded:Connect(function(child)
            if child:IsA("Model") and not string.find(child.Name, "Ragdoll") and not string.find(child.Name, "Corpse") then
                local pl = Players:FindFirstChild(child.Name)
                if pl and pl:IsA("Player") and pl.Parent == Players then
                    task.delay(0.02, function()
                        if child and child.Parent and isRealAlivePlayer(pl, child) then
                            setupPlayerChams(pl)
                        end
                    end)
                end
            end
        end))
    end
    local wsCharsWatchConn = workspace.ChildAdded:Connect(function(child)
        if child.Name == "Characters" then
            table.insert(Connections, child.ChildAdded:Connect(function(c)
                if c:IsA("Model") and not string.find(c.Name, "Ragdoll") and not string.find(c.Name, "Corpse") then
                    local pl = Players:FindFirstChild(c.Name)
                    if pl and pl:IsA("Player") and pl.Parent == Players then
                        task.delay(0.02, function()
                            if c and c.Parent and isRealAlivePlayer(pl, c) then
                                setupPlayerChams(pl)
                            end
                        end)
                    end
                end
            end))
        end
    end)
    table.insert(Connections, wsCharsWatchConn)

    scanAndRegisterAllCharacters()

    local wallRayParams = RaycastParams.new()
    wallRayParams.FilterType = Enum.RaycastFilterType.Exclude
    wallRayParams.IgnoreWater = true

    local vmCachedList = {}
    local vmActiveModel = nil
    local vmNeedsRescan = true
    local vmLastScanTick = 0
    local camChildAddedConn = nil
    local camChildRemovedConn = nil
    local lastBoundCam = nil

    local function isViewModelScopedOrHidden()

        if LocalPlayer:GetAttribute("IsSniperScoped") == true then
            return true
        end
        local scopeInc = LocalPlayer:GetAttribute("ScopeIncrement")
        if type(scopeInc) == "number" and scopeInc > 0 then
            return true
        end
        return false
    end

    local function restoreCachedViewModelPart(item)
        local p = item.part
        if not p or not p.Parent then return end
        pcall(function()
            p.Material = item.origMaterial
            p.Color = item.origColor
            p.Transparency = item.origTransparency
            if p:IsA("MeshPart") then
                p.TextureID = item.origTexture or ""
            end
            local curSA = p:FindFirstChildOfClass("SurfaceAppearance")
            if item.hadSA and item.origSA then
                if not curSA then
                    item.origSA:Clone().Parent = p
                else
                    curSA.AlphaMode = item.origSA.AlphaMode
                end
            elseif curSA and not item.hadSA then
                curSA:Destroy()
            end
            if item.textures then
                for c, origT in pairs(item.textures) do
                    if c.Parent then c.Transparency = origT end
                end
            end
        end)
        item.lastAppliedStyle = nil
        item.lastAppliedColor = nil
        item.lastAppliedTrans = nil
        item.lastScopedState = nil
    end

    local function restoreAllCachedViewModelParts()
        for _, item in ipairs(vmCachedList) do
            restoreCachedViewModelPart(item)
        end
    end

    local function cleanupViewModelChams()
        for _, item in ipairs(vmCachedList) do
            restoreCachedViewModelPart(item)
            if item.origSA then
                pcall(function() item.origSA:Destroy() end)
            end
        end
        table.clear(vmCachedList)
        vmActiveModel = nil
        vmNeedsRescan = true
    end

    local function isBlacklistedPart(p)
        if not p or not p:IsA("BasePart") then return true end

        local pName = string.lower(p.Name)

        if pName == "fakecamera" or string.find(pName, "fakecamera") or string.find(pName, "fake_camera")
           or pName == "camera" or pName == "campart" or pName == "cam_part" or pName == "cam"
           or string.find(pName, "viewmodelcamera") then
            if p.Transparency < 1 then p.Transparency = 1 end
            return true
        end

        if pName == "humanoidrootpart" or pName == "rootpart" or pName == "root" or pName == "hrp"
           or string.find(pName, "hitbox") or pName == "insert" or pName == "move" then
            if p.Transparency < 1 then p.Transparency = 1 end
            return true
        end

        if pName == "viewmodellight" or pName == "light" or string.find(pName, "viewmodellight") then
            if p.Transparency < 1 then p.Transparency = 1 end
            return true
        end

        if pName == "aimpart" or pName == "aim" or pName == "origin" or pName == "bobble" then
            if p.Transparency < 1 then p.Transparency = 1 end
            return true
        end

        local isBarrelOrSilencer = string.find(pName, "silencer") ~= nil
            or string.find(pName, "suppressor") ~= nil
            or string.find(pName, "barrel") ~= nil
        if isBarrelOrSilencer then
            return false
        end

        local isMesh = p:IsA("MeshPart") or (p:FindFirstChildOfClass("SpecialMesh") ~= nil)
        if not isMesh and (pName == "muzzlepart" or pName == "muzzlepartl" or pName == "muzzlepartr"
           or string.find(pName, "muzzleflash")) then
            if p.Transparency < 1 then p.Transparency = 1 end
            return true
        end

        if pName == "scopereticlepart" or string.find(pName, "reticle") then
            return true
        end

        local p1 = string.lower(p.Parent and p.Parent.Name or "")
        local p2 = string.lower(p.Parent and p.Parent.Parent and p.Parent.Parent.Name or "")
        if p1 == "largeweaponmodel" or p1 == "largecharmmodel" or p2 == "largeweaponmodel" or p2 == "largecharmmodel" then
            if p.Transparency < 1 then p.Transparency = 1 end
            return true
        end

        if not p:IsA("MeshPart") and p:FindFirstChildOfClass("SpecialMesh") == nil and p.Transparency >= 0.99 then
            return true
        end

        return false
    end

    local function isHandsPart(p)

        local curr = p
        while curr and curr ~= workspace and curr ~= workspace.CurrentCamera do
            local cName = string.lower(curr.Name)
            if cName == "left arm" or cName == "right arm"
               or cName == "leftarm" or cName == "rightarm"
               or cName == "lefthand" or cName == "righthand"
               or cName == "leftupperarm" or cName == "rightupperarm"
               or cName == "leftlowerarm" or cName == "rightlowerarm"
               or cName == "leftglove" or cName == "rightglove"
               or cName == "arm" or cName == "arms"
               or cName == "hand" or cName == "hands"
               or cName == "glove" or string.find(cName, "glove") ~= nil
               or cName == "sleeve" or string.find(cName, "sleeve") ~= nil then
                return true
            end

            if string.find(cName, "arm") and not string.find(cName, "sidearm") and not string.find(cName, "charm") and not string.find(cName, "warm") then
                return true
            end
            if string.find(cName, "hand") and not string.find(cName, "handle") then
                return true
            end

            curr = curr.Parent
        end

        return false
    end

    local function classifyViewModelPart(p)
        if not p or not p:IsA("BasePart") then return nil end

        if isBlacklistedPart(p) then return nil end

        if isHandsPart(p) then return "Hands" end

        return "Weapons"
    end

    local function applyCachedViewModelPartStyle(item, style, color, trans, isScoped)
        local p = item.part
        if not p or not p.Parent then return end

        pcall(function()
            if style == "Bloom" then
                local sa = p:FindFirstChildOfClass("SurfaceAppearance")
                if sa then sa:Destroy() end
                if p:IsA("MeshPart") and p.TextureID ~= "" then p.TextureID = "" end
                local sm = p:FindFirstChildOfClass("SpecialMesh")
                if sm and sm.TextureId ~= "" then sm.TextureId = "" end
                if item.textures then
                    for c in pairs(item.textures) do
                        if c.Parent then c.Transparency = 1 end
                    end
                end
                for _, c in ipairs(p:GetChildren()) do
                    if c:IsA("Texture") or c:IsA("Decal") then
                        c.Transparency = 1
                    end
                end
                p.Material = Enum.Material.Neon
                p.Color = color
                p.Transparency = trans
            elseif style == "Flat" then
                local sa = p:FindFirstChildOfClass("SurfaceAppearance")
                if sa then sa:Destroy() end
                if p:IsA("MeshPart") and p.TextureID ~= "" then p.TextureID = "" end
                local sm = p:FindFirstChildOfClass("SpecialMesh")
                if sm and sm.TextureId ~= "" then sm.TextureId = "" end
                if item.textures then
                    for c in pairs(item.textures) do
                        if c.Parent then c.Transparency = 1 end
                    end
                end
                for _, c in ipairs(p:GetChildren()) do
                    if c:IsA("Texture") or c:IsA("Decal") then
                        c.Transparency = 1
                    end
                end
                p.Material = Enum.Material.Plastic
                p.Color = color
                p.Transparency = trans
            elseif style == "Textured" then
                local sa = p:FindFirstChildOfClass("SurfaceAppearance")
                if sa then sa:Destroy() end
                if p:IsA("MeshPart") and p.TextureID ~= "" then p.TextureID = "" end
                local sm = p:FindFirstChildOfClass("SpecialMesh")
                if sm and sm.TextureId ~= "" then sm.TextureId = "" end
                if item.textures then
                    for c in pairs(item.textures) do
                        if c.Parent then c.Transparency = 1 end
                    end
                end
                for _, c in ipairs(p:GetChildren()) do
                    if c:IsA("Texture") or c:IsA("Decal") then
                        c.Transparency = 1
                    end
                end
                p.Material = Enum.Material.Foil
                p.Color = color
                p.Transparency = trans
            elseif style == "Glass" then
                local sa = p:FindFirstChildOfClass("SurfaceAppearance")
                if sa then sa:Destroy() end
                if p:IsA("MeshPart") and p.TextureID ~= "" then p.TextureID = "" end
                local sm = p:FindFirstChildOfClass("SpecialMesh")
                if sm and sm.TextureId ~= "" then sm.TextureId = "" end
                if item.textures then
                    for c in pairs(item.textures) do
                        if c.Parent then c.Transparency = 1 end
                    end
                end
                for _, c in ipairs(p:GetChildren()) do
                    if c:IsA("Texture") or c:IsA("Decal") then
                        c.Transparency = 1
                    end
                end
                p.Material = Enum.Material.Glass
                p.Color = color
                p.Transparency = if trans == 0 then 0.25 else trans
            elseif style == "Model" then
                p.Material = item.origMaterial
                p.Color = color
                local curSA = p:FindFirstChildOfClass("SurfaceAppearance")
                if item.hadSA and item.origSA then
                    if not curSA then
                        local newSA = item.origSA:Clone()
                        newSA.AlphaMode = Enum.AlphaMode.Overlay
                        newSA.Parent = p
                    else
                        curSA.AlphaMode = Enum.AlphaMode.Overlay
                    end
                elseif item.origTexture ~= "" and p:IsA("MeshPart") then
                    p.TextureID = item.origTexture
                end
                if item.textures then
                    for c, origT in pairs(item.textures) do
                        if c.Parent then c.Transparency = if isScoped then 1 else origT end
                    end
                end
                p.Transparency = trans
            elseif style == "Default" then
                p.Material = item.origMaterial
                p.Color = item.origColor
                p.Transparency = trans
                if p:IsA("MeshPart") then
                    p.TextureID = item.origTexture or ""
                end
                local sm = p:FindFirstChildOfClass("SpecialMesh")
                if sm and item.origSMTexture then
                    sm.TextureId = item.origSMTexture
                end
                local curSA = p:FindFirstChildOfClass("SurfaceAppearance")
                if item.hadSA and item.origSA then
                    if not curSA then
                        item.origSA:Clone().Parent = p
                    else
                        curSA.AlphaMode = item.origSA.AlphaMode
                    end
                elseif curSA and not item.hadSA then
                    curSA:Destroy()
                end
                if item.textures then
                    for c, origT in pairs(item.textures) do
                        if c.Parent then c.Transparency = if isScoped then 1 else origT end
                    end
                end
            end
        end)
    end

    local function scanAndCacheViewModel(cam)
        for _, item in ipairs(vmCachedList) do
            if item.origSA then
                pcall(function() item.origSA:Destroy() end)
            end
        end
        table.clear(vmCachedList)
        vmActiveModel = nil

        local foundVM = nil
        for _, child in ipairs(cam:GetChildren()) do
            if child:IsA("Model") and child.Name ~= "ChamHolder" then
                local isVM = child:FindFirstChild("Left Arm")
                    or child:FindFirstChild("Right Arm")
                    or child:FindFirstChild("LeftArm")
                    or child:FindFirstChild("RightArm")
                    or child:FindFirstChild("LeftHand")
                    or child:FindFirstChild("RightHand")
                    or child:FindFirstChild("Weapon")
                    or child:FindFirstChild("WeaponL")
                    or child:FindFirstChild("WeaponR")
                    or child:FindFirstChild("CharmBase")
                    or child:FindFirstChild("Interactables")
                    or child:FindFirstChild("Stats")
                    or child:FindFirstChild("FakeCamera")
                    or child:FindFirstChildOfClass("AnimationController")
                    or child:FindFirstChildOfClass("Humanoid")
                    or string.find(string.lower(child.Name), "viewmodel") ~= nil
                    or child:FindFirstChild("Glove")

                if isVM then
                    foundVM = child
                    break
                end
            end
        end

        if not foundVM then
            return
        end

        vmActiveModel = foundVM
        pcall(function()
            foundVM.DescendantAdded:Connect(function(desc)
                if desc:IsA("BasePart") then
                    vmNeedsRescan = true
                end
            end)
        end)
        for _, p in ipairs(foundVM:GetDescendants()) do
            if p:IsA("BasePart") then
                local category = classifyViewModelPart(p)
                if category then
                    local pNameLower = string.lower(p.Name)
                    local isBarrelOrSilencer = string.find(pNameLower, "silencer") ~= nil
                        or string.find(pNameLower, "suppressor") ~= nil
                        or string.find(pNameLower, "barrel") ~= nil

                    local sa = p:FindFirstChildOfClass("SurfaceAppearance")
                    local sm = p:FindFirstChildOfClass("SpecialMesh")
                    local texChildren = {}
                    for _, c in ipairs(p:GetChildren()) do
                        if c:IsA("Texture") or c:IsA("Decal") then
                            texChildren[c] = c.Transparency
                        end
                    end
                    local rawTrans = p:GetAttribute("HiddenTransparency") or p.Transparency
                    local defaultTrans = p:GetAttribute("HiddenTransparency") or rawTrans
                    if not isBarrelOrSilencer and defaultTrans >= 0.99 and not p:IsA("MeshPart") and not sm then
                        continue
                    end

                    table.insert(vmCachedList, {
                        part = p,
                        category = category,
                        origMaterial = p.Material,
                        origColor = p.Color,
                        origTransparency = if isBarrelOrSilencer then 0 else defaultTrans,
                        origTexture = (p:IsA("MeshPart") and p.TextureID) or "",
                        origSMTexture = (sm and sm.TextureId) or "",
                        hadSA = (sa ~= nil),
                        origSA = sa and sa:Clone() or nil,
                        textures = texChildren,
                        isSilencer = isBarrelOrSilencer,

                        lastAppliedStyle = nil,
                        lastAppliedColor = nil,
                        lastAppliedTrans = nil,
                        lastScopedState = nil,
                    })
                end
            end
        end
    end

    local function setupCameraListeners(cam)
        if lastBoundCam == cam then return end
        lastBoundCam = cam

        if camChildAddedConn then camChildAddedConn:Disconnect() camChildAddedConn = nil end
        if camChildRemovedConn then camChildRemovedConn:Disconnect() camChildRemovedConn = nil end

        if cam then
            camChildAddedConn = cam.ChildAdded:Connect(function(child)
                if child:IsA("Model") and child.Name ~= "ChamHolder" then
                    vmNeedsRescan = true
                end
            end)
            camChildRemovedConn = cam.ChildRemoved:Connect(function(child)
                if child:IsA("Model") and child.Name ~= "ChamHolder" then
                    vmNeedsRescan = true
                end
            end)
            table.insert(Connections, camChildAddedConn)
            table.insert(Connections, camChildRemovedConn)
        end
    end

    local function applyViewModelChams()
        local cam = workspace.CurrentCamera
        if not cam then return end

        setupCameraListeners(cam)

        local now = tick()
        local needsRescan = vmNeedsRescan
            or (vmActiveModel == nil)
            or (vmActiveModel.Parent ~= cam)
            or (#vmCachedList == 0 and (now - vmLastScanTick > 0.5))

        if needsRescan then
            vmLastScanTick = now
            vmNeedsRescan = false
            scanAndCacheViewModel(cam)
        end

        if #vmCachedList == 0 then return end

        local armsCfg = MemeSenseChams.LocalPlayer.Arms
        local isScoped = isViewModelScopedOrHidden()

        local invalidFound = false
        for _, item in ipairs(vmCachedList) do
            local p = item.part
            if not p or not p.Parent then
                invalidFound = true
                continue
            end

            local cfg = armsCfg[item.category]
            local isEnabled = cfg and cfg.Enabled

            local targetStyle = if isEnabled then (cfg.Style or "Bloom") else "Default"
            local targetColor = if isEnabled then (cfg.Color or Color3.fromRGB(255, 255, 255)) else item.origColor
            local targetTrans = if isScoped then 1 else (if isEnabled then (cfg.Transparency or 0) else item.origTransparency)

            local needsApply = (item.lastAppliedStyle ~= targetStyle)
                or (item.lastAppliedColor ~= targetColor)
                or (item.lastAppliedTrans ~= targetTrans)
                or (item.lastScopedState ~= isScoped)

            if not needsApply and isEnabled and not isScoped then
                local expectedMat = if targetStyle == "Bloom" then Enum.Material.Neon elseif targetStyle == "Flat" then Enum.Material.Plastic elseif targetStyle == "Textured" then Enum.Material.Foil else item.origMaterial
                if p.Material ~= expectedMat or p.Color ~= targetColor or p:FindFirstChildOfClass("SurfaceAppearance") ~= nil then
                    needsApply = true
                elseif item.isSilencer and p.Transparency ~= targetTrans then
                    needsApply = true
                end
            end

            if needsApply then
                item.lastAppliedStyle = targetStyle
                item.lastAppliedColor = targetColor
                item.lastAppliedTrans = targetTrans
                item.lastScopedState = isScoped

                applyCachedViewModelPartStyle(item, targetStyle, targetColor, targetTrans, isScoped)
            end
        end

        if invalidFound then
            vmNeedsRescan = true
        end
    end

    local chamRenderConn = RunService.RenderStepped:Connect(function()
        local camera = workspace.CurrentCamera
        if not camera then return end

        for deadChar, _ in pairs(deadCharactersToHide) do
            if deadChar and deadChar.Parent then
                pcall(function()
                    for _, desc in ipairs(deadChar:GetDescendants()) do
                        if desc:IsA("BasePart") then
                            desc.LocalTransparencyModifier = 1
                        end
                    end
                end)
            else
                deadCharactersToHide[deadChar] = nil
            end
        end

        local masterOn = isChamsMasterOn()
        if not masterOn then
            for ply, data in pairs(activeProxies) do
                for _, item in ipairs(data.parts) do
                    if item.visual and item.visual.Parent then
                        item.visual.Transparency = 1
                        item.lastStyle = nil
                    end
                    if item.target and item.target.Parent and ply ~= LocalPlayer then
                        item.target.LocalTransparencyModifier = 0
                    end
                end
                if data.char and data.char.Parent and ply ~= LocalPlayer then
                    for _, desc in ipairs(data.char:GetDescendants()) do
                        if desc:IsA("BasePart") and string.sub(desc.Name, 1, 9) ~= "ChamProxy" then
                            desc.LocalTransparencyModifier = 0
                        end
                    end
                end
            end
            local hadApplied = false
            for _, item in ipairs(vmCachedList) do
                if item.lastAppliedStyle ~= nil then
                    hadApplied = true
                    break
                end
            end
            if hadApplied then
                restoreAllCachedViewModelParts()
            end
            return
        end

        local localHead = LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
        local camDistToHead = if (localHead and camera) then (camera.CFrame.Position - localHead.Position).Magnitude else 0
        local isThirdPerson = (MemeSenseCamera and MemeSenseCamera.ThirdPersonEnabled == true)
            or (camDistToHead > 2.2)
        local camCF = camera.CFrame
        local camPos = camCF.Position
        local camLook = camCF.LookVector
        local chamFolder = getChamFolder()

        table.clear(chamBaseFilter)
        if camera then table.insert(chamBaseFilter, camera) end
        if chamFolder then table.insert(chamBaseFilter, chamFolder) end
        if LocalPlayer and LocalPlayer.Character then table.insert(chamBaseFilter, LocalPlayer.Character) end
        wallRayParams.FilterDescendantsInstances = chamBaseFilter
        visRayParams.FilterDescendantsInstances = chamBaseFilter

        local camWallDist = 1.20
        local wallHit = workspace:Raycast(camPos, camLook * 2.0, wallRayParams)
        if wallHit and wallHit.Distance > 0.1 then
            camWallDist = math.clamp(wallHit.Distance - 0.05, 0.80, 1.50)
        end

        local nowTick = tick()
        if nowTick - lastChamScanTick > 2.0 then
            lastChamScanTick = nowTick
            scanAndRegisterAllCharacters()
        end

        for player, data in pairs(activeProxies) do
            local char = data.char
            if not isRealAlivePlayer(player, char) then
                local altChar = (workspace:FindFirstChild("Characters") and workspace.Characters:FindFirstChild(player.Name)) or player.Character
                if altChar and altChar ~= char and isRealAlivePlayer(player, altChar) then
                    setupPlayerChams(player)
                else
                    if char and char.Parent and player ~= LocalPlayer then
                        deadCharactersToHide[char] = true
                    end
                    if data.highlight then data.highlight.Enabled = false end
                    for _, item in ipairs(data.parts) do
                        if item.visual and item.visual.Parent and item.currentTrans ~= 1 then
                            item.currentTrans = 1
                            item.visual.Transparency = 1
                            item.lastStyle = nil
                        end
                        if item.target and item.target.Parent and player ~= LocalPlayer then
                            item.target.LocalTransparencyModifier = 1
                        end
                    end
                    if char and char.Parent and player ~= LocalPlayer then
                        for _, desc in ipairs(char:GetDescendants()) do
                            if desc:IsA("BasePart") then
                                desc.LocalTransparencyModifier = 1
                            end
                        end
                    end
                end
                continue
            end

            local isLocal = (player == LocalPlayer)
            local isTeammatePlayer = isTeammate(player)

            if isLocal and not isThirdPerson then
                if data.highlight then data.highlight.Enabled = false end
                for _, item in ipairs(data.parts) do
                    if item.visual and item.visual.Parent and item.currentTrans ~= 1 then
                        item.currentTrans = 1
                        item.visual.Transparency = 1
                        item.lastStyle = nil
                    end
                    if item.target and item.target.Parent then
                        item.target.LocalTransparencyModifier = 1
                    end
                end
                if char and char.Parent then
                    for _, desc in ipairs(char:GetDescendants()) do
                        if desc:IsA("BasePart") and string.sub(desc.Name, 1, 9) ~= "ChamProxy" then
                            desc.LocalTransparencyModifier = 1
                        end
                    end
                end
                continue
            end

            local visCfg, invisCfg, glowCfg
            if isLocal then
                glowCfg = MemeSenseChams.LocalPlayer.Glow
                visCfg = MemeSenseChams.LocalPlayer.Visible
                invisCfg = MemeSenseChams.LocalPlayer.Invisible
            elseif isTeammatePlayer then
                glowCfg = MemeSenseChams.Players.Team.Glow
                visCfg = MemeSenseChams.Players.Team.Visible
                invisCfg = MemeSenseChams.Players.Team.Invisible
            else
                glowCfg = MemeSenseChams.Players.Enemy.Glow
                visCfg = MemeSenseChams.Players.Enemy.Visible
                invisCfg = MemeSenseChams.Players.Enemy.Invisible
            end

            local glowEnabled = masterOn and glowCfg and (glowCfg.Enabled == true)
            local chamsPartsEnabled = masterOn and ((visCfg and visCfg.Enabled) or (invisCfg and invisCfg.Enabled))

            if not glowEnabled and not chamsPartsEnabled then
                if data.highlight then data.highlight.Enabled = false end
                for _, item in ipairs(data.parts) do
                    if item.visual and item.visual.Parent and item.currentTrans ~= 1 then
                        item.currentTrans = 1
                        item.visual.Transparency = 1
                        item.lastStyle = nil
                    end
                end
                continue
            end

            local pIdx = 1
            while pIdx <= #data.parts do
                local item = data.parts[pIdx]
                if not item.target or not item.target.Parent or not item.target:IsDescendantOf(workspace) then
                    if item.visual then item.visual:Destroy() end
                    if item.origSA then item.origSA:Destroy() end
                    table.remove(data.parts, pIdx)
                else
                    pIdx = pIdx + 1
                end
            end

            -- Strict Viewport / Frustum culling check:
            local hrp = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart or char:FindFirstChild("Head")
            if hrp then
                local sPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
                if (not onScreen) or (sPos.Z <= 0) then
                    for _, item in ipairs(data.parts) do
                        if item.visual and item.visual.Parent and item.currentTrans ~= 1 then
                            item.currentTrans = 1
                            item.visual.Transparency = 1
                            item.lastStyle = nil
                        end
                    end
                    continue
                end
            end

            -- Torso-only visibility raycast (1 raycast per player instead of per-limb):
            local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or hrp or char:FindFirstChild("Head")
            local isVis = false
            if torso then
                isVis = castVisRay(camPos, torso.Position, torso, char)
            end

            local targetConfig = nil
            if isVis and visCfg.Enabled then
                targetConfig = visCfg
            elseif not isVis and invisCfg.Enabled then
                targetConfig = invisCfg
            end

            if not targetConfig then
                for _, item in ipairs(data.parts) do
                    if item.visual and item.visual.Parent and item.currentTrans ~= 1 then
                        item.currentTrans = 1
                        item.visual.Transparency = 1
                        item.lastStyle = nil
                    end
                end
                continue
            end

            for _, item in ipairs(data.parts) do
                local target = item.target
                local visualPart = item.visual

                if target and target.Parent and visualPart and visualPart.Parent then
                    if chamFolder and visualPart.Parent ~= chamFolder then
                        visualPart.Parent = chamFolder
                    end

                    local targetPos = target.Position
                    local dir = targetPos - camPos
                    local forwardDist = dir:Dot(camLook)

                    if forwardDist <= 0.05 then
                        if item.currentTrans ~= 1 then
                            item.currentTrans = 1
                            visualPart.Transparency = 1
                            item.lastStyle = nil
                        end
                    else
                        local distance = dir.Magnitude
                        local renderDistance = 1.30
                        local effectiveRenderDist = if distance < (renderDistance + 0.5) then (distance * 0.5) else renderDistance
                        local scale = effectiveRenderDist / distance
                        local projectedPos = camPos + (dir * scale)

                        if item.isHead then
                            local headSize = Vector3.new(target.Size.Y, target.Size.X, target.Size.Z) * scale
                            visualPart.Size = headSize
                            visualPart.CFrame = CFrame.new(projectedPos) * target.CFrame.Rotation * CFrame.Angles(0, 0, math.pi / 2)
                        else
                            visualPart.Size = target.Size * scale
                            visualPart.CFrame = CFrame.new(projectedPos) * target.CFrame.Rotation
                            local sm = item.cachedSM or visualPart:FindFirstChildOfClass("SpecialMesh")
                            if sm and item.origMeshScale then
                                sm.Scale = item.origMeshScale * scale
                            end
                        end

                        local targetStyle = targetConfig.Style or "Bloom"
                        local targetColor = targetConfig.Color or Color3.fromRGB(255, 255, 255)
                        local targetTrans = targetConfig.Transparency or 0

                        if item.lastStyle ~= targetStyle or item.lastColor ~= targetColor or item.lastTrans ~= targetTrans then
                            item.lastStyle = targetStyle
                            item.lastColor = targetColor
                            item.lastTrans = targetTrans
                            item.currentTrans = targetTrans
                            applyPartStyle(item, targetConfig)
                        elseif item.currentTrans ~= targetTrans then
                            item.currentTrans = targetTrans
                            visualPart.Transparency = targetTrans
                        end
                    end
                else
                    if item.currentTrans ~= 1 then
                        item.currentTrans = 1
                        if visualPart and visualPart.Parent then visualPart.Transparency = 1 end
                    end
                end
            end

            local charHL = data.highlight
            if glowEnabled then
                if not charHL or not charHL.Parent then
                    charHL = Instance.new("Highlight")
                    charHL.Name = "ChamGlow_" .. player.Name
                    charHL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    charHL.FillTransparency = 1
                    charHL.Parent = char
                    data.highlight = charHL
                end
                charHL.Adornee = char
                charHL.FillTransparency = 1
                charHL.OutlineColor = glowCfg.Color or Color3.fromRGB(255, 255, 255)
                charHL.OutlineTransparency = math.clamp(glowCfg.Transparency or 0, 0, 1)
                charHL.Enabled = true
            else
                if charHL then
                    charHL.Enabled = false
                end
            end
        end

        local anyArmsEnabled = MemeSenseChams.LocalPlayer.Arms.Hands.Enabled
            or MemeSenseChams.LocalPlayer.Arms.Weapons.Enabled

        if masterOn and not isThirdPerson and anyArmsEnabled then
            applyViewModelChams()
        else
            local hadApplied = false
            for _, item in ipairs(vmCachedList) do
                if item.lastAppliedStyle ~= nil then
                    hadApplied = true
                    break
                end
            end
            if hadApplied then
                restoreAllCachedViewModelParts()
            end
        end
    end)
    table.insert(Connections, chamRenderConn)

    unloadChamSystem = function()
        if chamRenderConn then
            pcall(function() chamRenderConn:Disconnect() end)
            chamRenderConn = nil
        end
        if camChildAddedConn then
            pcall(function() camChildAddedConn:Disconnect() end)
            camChildAddedConn = nil
        end
        if camChildRemovedConn then
            pcall(function() camChildRemovedConn:Disconnect() end)
            camChildRemovedConn = nil
        end
        for player in pairs(activeProxies) do
            clearPlayerCham(player)
        end
        cleanupViewModelChams()
        local folder = getChamFolder()
        if folder and folder.Parent then
            pcall(function() folder:Destroy() end)
        end
    end

    local function run()
        local ChamsTab = Tabs["Chams"]
        local CHLeft = ChamsTab.LeftColumn
        local CHRight = ChamsTab.RightColumn

        local function createColGroup(parent, name)
            local frame = Instance.new("Frame")
            frame.Name = name
            frame.Size = UDim2.new(1, 0, 0, 0)
            frame.AutomaticSize = Enum.AutomaticSize.Y
            frame.BackgroundTransparency = 1
            frame.BorderSizePixel = 0
            frame.Parent = parent

            local list = Instance.new("UIListLayout")
            list.SortOrder = Enum.SortOrder.LayoutOrder
            list.Padding = UDim.new(0, 4)
            list.Parent = frame

            return frame
        end

        local PlayersLeftGroup = createColGroup(CHLeft, "PlayersLeftGroup")
        local PlayersRightGroup = createColGroup(CHRight, "PlayersRightGroup")
        local LocalLeftGroup = createColGroup(CHLeft, "LocalLeftGroup")
        local LocalRightGroup = createColGroup(CHRight, "LocalRightGroup")

        Controls:CreateSectionHeader(PlayersLeftGroup, "Enemy team", 1)
        Controls:CreateSectionHeader(PlayersLeftGroup, "Customizations", 2)
        Controls:CreateToggle(PlayersLeftGroup, {
            Name = "Glow",
            Default = false,
            ColorChip = MemeSenseChams.Players.Enemy.Glow.Color,
            ColorAlpha = 1 - (MemeSenseChams.Players.Enemy.Glow.Transparency or 0),
            LayoutOrder = 3,
            Callback = function(v)
                MemeSenseChams.Players.Enemy.Glow.Enabled = v
            end,
            ColorCallback = function(col, alpha)
                MemeSenseChams.Players.Enemy.Glow.Color = col
                if alpha ~= nil then
                    MemeSenseChams.Players.Enemy.Glow.Transparency = 1 - alpha
                end
            end,
        })
        Controls:CreateToggle(PlayersLeftGroup, {
            Name = "Visible",
            Default = false,
            ColorChip = MemeSenseChams.Players.Enemy.Visible.Color,
            ColorAlpha = 1 - (MemeSenseChams.Players.Enemy.Visible.Transparency or 0),
            Dropdown = {
                Options = { "Bloom", "Flat", "Glass", "Textured" },
                Default = MemeSenseChams.Players.Enemy.Visible.Style,
                Callback = function(opt)
                    MemeSenseChams.Players.Enemy.Visible.Style = opt
                end,
            },
            LayoutOrder = 4,
            Callback = function(v)
                MemeSenseChams.Players.Enemy.Visible.Enabled = v
            end,
            ColorCallback = function(col, alpha)
                MemeSenseChams.Players.Enemy.Visible.Color = col
                if alpha ~= nil then
                    MemeSenseChams.Players.Enemy.Visible.Transparency = 1 - alpha
                end
            end,
        })
        Controls:CreateToggle(PlayersLeftGroup, {
            Name = "Invisible",
            Default = false,
            ColorChip = MemeSenseChams.Players.Enemy.Invisible.Color,
            ColorAlpha = 1 - (MemeSenseChams.Players.Enemy.Invisible.Transparency or 0),
            Dropdown = {
                Options = { "Bloom", "Flat", "Glass", "Textured" },
                Default = MemeSenseChams.Players.Enemy.Invisible.Style,
                Callback = function(opt)
                    MemeSenseChams.Players.Enemy.Invisible.Style = opt
                end,
            },
            LayoutOrder = 5,
            Callback = function(v)
                MemeSenseChams.Players.Enemy.Invisible.Enabled = v
            end,
            ColorCallback = function(col, alpha)
                MemeSenseChams.Players.Enemy.Invisible.Color = col
                if alpha ~= nil then
                    MemeSenseChams.Players.Enemy.Invisible.Transparency = 1 - alpha
                end
            end,
        })

        Controls:CreateSectionHeader(PlayersRightGroup, "Team", 1)
        Controls:CreateSectionHeader(PlayersRightGroup, "Customizations", 2)
        Controls:CreateToggle(PlayersRightGroup, {
            Name = "Glow",
            Default = false,
            ColorChip = MemeSenseChams.Players.Team.Glow.Color,
            ColorAlpha = 1 - (MemeSenseChams.Players.Team.Glow.Transparency or 0),
            LayoutOrder = 3,
            Callback = function(v)
                MemeSenseChams.Players.Team.Glow.Enabled = v
            end,
            ColorCallback = function(col, alpha)
                MemeSenseChams.Players.Team.Glow.Color = col
                if alpha ~= nil then
                    MemeSenseChams.Players.Team.Glow.Transparency = 1 - alpha
                end
            end,
        })
        Controls:CreateToggle(PlayersRightGroup, {
            Name = "Visible",
            Default = false,
            ColorChip = MemeSenseChams.Players.Team.Visible.Color,
            ColorAlpha = 1 - (MemeSenseChams.Players.Team.Visible.Transparency or 0),
            Dropdown = {
                Options = { "Bloom", "Flat", "Glass", "Textured" },
                Default = MemeSenseChams.Players.Team.Visible.Style,
                Callback = function(opt)
                    MemeSenseChams.Players.Team.Visible.Style = opt
                end,
            },
            LayoutOrder = 4,
            Callback = function(v)
                MemeSenseChams.Players.Team.Visible.Enabled = v
            end,
            ColorCallback = function(col, alpha)
                MemeSenseChams.Players.Team.Visible.Color = col
                if alpha ~= nil then
                    MemeSenseChams.Players.Team.Visible.Transparency = 1 - alpha
                end
            end,
        })
        Controls:CreateToggle(PlayersRightGroup, {
            Name = "Invisible",
            Default = false,
            ColorChip = MemeSenseChams.Players.Team.Invisible.Color,
            ColorAlpha = 1 - (MemeSenseChams.Players.Team.Invisible.Transparency or 0),
            Dropdown = {
                Options = { "Bloom", "Flat", "Glass", "Textured" },
                Default = MemeSenseChams.Players.Team.Invisible.Style,
                Callback = function(opt)
                    MemeSenseChams.Players.Team.Invisible.Style = opt
                end,
            },
            LayoutOrder = 5,
            Callback = function(v)
                MemeSenseChams.Players.Team.Invisible.Enabled = v
            end,
            ColorCallback = function(col, alpha)
                MemeSenseChams.Players.Team.Invisible.Color = col
                if alpha ~= nil then
                    MemeSenseChams.Players.Team.Invisible.Transparency = 1 - alpha
                end
            end,
        })

        Controls:CreateSectionHeader(LocalLeftGroup, "Customizations", 1)
        Controls:CreateToggle(LocalLeftGroup, {
            Name = "Glow",
            Default = false,
            ColorChip = MemeSenseChams.LocalPlayer.Glow.Color,
            ColorAlpha = 1 - (MemeSenseChams.LocalPlayer.Glow.Transparency or 0),
            LayoutOrder = 2,
            Callback = function(v)
                MemeSenseChams.LocalPlayer.Glow.Enabled = v
            end,
            ColorCallback = function(col, alpha)
                MemeSenseChams.LocalPlayer.Glow.Color = col
                if alpha ~= nil then
                    MemeSenseChams.LocalPlayer.Glow.Transparency = 1 - alpha
                end
            end,
        })
        Controls:CreateToggle(LocalLeftGroup, {
            Name = "Visible",
            Default = false,
            ColorChip = MemeSenseChams.LocalPlayer.Visible.Color,
            ColorAlpha = 1 - (MemeSenseChams.LocalPlayer.Visible.Transparency or 0),
            Dropdown = {
                Options = { "Bloom", "Flat", "Glass", "Textured" },
                Default = MemeSenseChams.LocalPlayer.Visible.Style,
                Callback = function(opt)
                    MemeSenseChams.LocalPlayer.Visible.Style = opt
                end,
            },
            LayoutOrder = 3,
            Callback = function(v)
                MemeSenseChams.LocalPlayer.Visible.Enabled = v
            end,
            ColorCallback = function(col, alpha)
                MemeSenseChams.LocalPlayer.Visible.Color = col
                if alpha ~= nil then
                    MemeSenseChams.LocalPlayer.Visible.Transparency = 1 - alpha
                end
            end,
        })
        Controls:CreateToggle(LocalLeftGroup, {
            Name = "Invisible",
            Default = false,
            ColorChip = MemeSenseChams.LocalPlayer.Invisible.Color,
            ColorAlpha = 1 - (MemeSenseChams.LocalPlayer.Invisible.Transparency or 0),
            Dropdown = {
                Options = { "Bloom", "Flat", "Glass", "Textured" },
                Default = MemeSenseChams.LocalPlayer.Invisible.Style,
                Callback = function(opt)
                    MemeSenseChams.LocalPlayer.Invisible.Style = opt
                end,
            },
            LayoutOrder = 4,
            Callback = function(v)
                MemeSenseChams.LocalPlayer.Invisible.Enabled = v
            end,
            ColorCallback = function(col, alpha)
                MemeSenseChams.LocalPlayer.Invisible.Color = col
                if alpha ~= nil then
                    MemeSenseChams.LocalPlayer.Invisible.Transparency = 1 - alpha
                end
            end,
        })

        Controls:CreateSectionHeader(LocalRightGroup, "Arms", 1)
        Controls:CreateToggle(LocalRightGroup, {
            Name = "Hands",
            Default = false,
            ColorChip = MemeSenseChams.LocalPlayer.Arms.Hands.Color,
            ColorAlpha = 1 - (MemeSenseChams.LocalPlayer.Arms.Hands.Transparency or 0),
            Dropdown = {
                Options = { "Bloom", "Flat", "Glass", "Textured" },
                Default = MemeSenseChams.LocalPlayer.Arms.Hands.Style,
                Callback = function(opt)
                    MemeSenseChams.LocalPlayer.Arms.Hands.Style = opt
                end,
            },
            LayoutOrder = 2,
            Callback = function(v)
                MemeSenseChams.LocalPlayer.Arms.Hands.Enabled = v
            end,
            ColorCallback = function(col, alpha)
                MemeSenseChams.LocalPlayer.Arms.Hands.Color = col
                if alpha ~= nil then
                    MemeSenseChams.LocalPlayer.Arms.Hands.Transparency = 1 - alpha
                end
            end,
        })
        Controls:CreateToggle(LocalRightGroup, {
            Name = "Weapons",
            Default = false,
            ColorChip = MemeSenseChams.LocalPlayer.Arms.Weapons.Color,
            ColorAlpha = 1 - (MemeSenseChams.LocalPlayer.Arms.Weapons.Transparency or 0),
            Dropdown = {
                Options = { "Bloom", "Flat", "Glass", "Textured" },
                Default = MemeSenseChams.LocalPlayer.Arms.Weapons.Style,
                Callback = function(opt)
                    MemeSenseChams.LocalPlayer.Arms.Weapons.Style = opt
                end,
            },
            LayoutOrder = 3,
            Callback = function(v)
                MemeSenseChams.LocalPlayer.Arms.Weapons.Enabled = v
            end,
            ColorCallback = function(col, alpha)
                MemeSenseChams.LocalPlayer.Arms.Weapons.Color = col
                if alpha ~= nil then
                    MemeSenseChams.LocalPlayer.Arms.Weapons.Transparency = 1 - alpha
                end
            end,
        })

        updateChamsCategoryView = function(category)
            if category == "Local player" then
                PlayersLeftGroup.Visible = false
                PlayersRightGroup.Visible = false
                LocalLeftGroup.Visible = true
                LocalRightGroup.Visible = true
            else
                PlayersLeftGroup.Visible = true
                PlayersRightGroup.Visible = true
                LocalLeftGroup.Visible = false
                LocalRightGroup.Visible = false
            end
        end

        updateChamsCategoryView(chamsMode)
    end
    run()
end)()

do
    local ItemsTab = Tabs["Items"]
    local ITLeft = ItemsTab.LeftColumn
    local ITRight = ItemsTab.RightColumn

local itLeftOrder = 0
local function nextITLeft()
    itLeftOrder += 1
    return itLeftOrder
end

local itRightOrder = 0
local function nextITRight()
    itRightOrder += 1
    return itRightOrder
end

Controls:CreateMatrixHeader(ITLeft, nextITLeft())

local leftItems = {
    { Name = "C4", B = false, T = false, I = false, D = false },
    { Name = "Planted C4", B = false, T = false, I = false, D = false },
    { Name = "Defuse kit", B = false, T = false, I = false, D = false },
    { Name = "Hostage", B = false, T = false, I = false, D = false },
    { Name = "Taser", B = false, T = false, I = false, D = false },
    { Name = "Knife", B = false, T = false, I = false, D = false },
    { Name = "Pistol", B = false, T = false, I = false, D = false },
    { Name = "Rifle", B = false, T = false, I = false, D = false },
    { Name = "Shotgun", B = false, T = false, I = false, D = false },
    { Name = "Sniper", B = false, T = false, I = false, D = false },
    { Name = "Machine gun", B = false, T = false, I = false, D = false },
    { Name = "Submachine gun", B = false, T = false, I = false, D = false }
}

for _, item in ipairs(leftItems) do
    item.LayoutOrder = nextITLeft()
    Controls:CreateMatrixRow(ITLeft, item)
end

Controls:CreateMatrixHeader(ITRight, nextITRight())

local rightItems = {
    { Name = "Grenade", B = false, T = false, I = false, D = false, Color = Color3.fromRGB(255, 255, 255) },
    { Name = "Decoy", B = false, T = false, I = false, D = false },
    { Name = "Flashbang", B = false, T = false, I = false, D = false },
    { Name = "Smoke grenade", B = false, T = false, I = false, D = false },
    { Name = "Incendiary grenade", B = false, T = false, I = false, D = false },
    { Name = "Grenade projectile", B = false, T = false, I = false, D = false },
    { Name = "Decoy projectile", B = false, T = false, I = false, D = false },
    { Name = "Flashbang projectile", B = false, T = false, I = false, D = false },
    { Name = "Smoke projectile", B = false, T = false, I = false, D = false },
    { Name = "Molotov projectile", B = false, T = false, I = false, D = false }
}

for _, item in ipairs(rightItems) do
    item.LayoutOrder = nextITRight()
    Controls:CreateMatrixRow(ITRight, item)
end
end

do
local function createGrenadeTracersUI()

    local GrenadeTypes = {
        { Id = "decoy", Name = "Decoy grenade", Enabled = false, Color = Color3.fromRGB(255, 255, 255), Time = 5.00, Thickness = 1.10 },
        { Id = "flash", Name = "Flashbang", Enabled = false, Color = Color3.fromRGB(255, 255, 255), Time = 5.00, Thickness = 1.10 },
        { Id = "smoke", Name = "Smoke grenade", Enabled = false, Color = Color3.fromRGB(255, 255, 255), Time = 5.00, Thickness = 1.10 },
        { Id = "incendiary", Name = "Incendiary grenade", Enabled = false, Color = Color3.fromRGB(255, 255, 255), Time = 5.00, Thickness = 1.10 },
        { Id = "he", Name = "High explosive grenade", Enabled = false, Color = Color3.fromRGB(255, 255, 255), Time = 5.00, Thickness = 1.10 },
    }

    local GrenadeTracersPopover = Instance.new("Frame")
    GrenadeTracersPopover.Name = "GrenadeTracersPopover"
    GrenadeTracersPopover.Size = UDim2.new(0, 205, 0, 142)
    GrenadeTracersPopover.BackgroundColor3 = Color3.fromRGB(19, 20, 24)
    GrenadeTracersPopover.BorderSizePixel = 0
    GrenadeTracersPopover.Visible = false
    GrenadeTracersPopover.ZIndex = 520
    GrenadeTracersPopover.Parent = PopupsLayer
    createCorner(GrenadeTracersPopover, 2)

    local gtPadding = Instance.new("UIPadding")
    gtPadding.PaddingTop = UDim.new(0, 6)
    gtPadding.PaddingBottom = UDim.new(0, 6)
    gtPadding.PaddingLeft = UDim.new(0, 8)
    gtPadding.PaddingRight = UDim.new(0, 8)
    gtPadding.Parent = GrenadeTracersPopover

    local gtList = Instance.new("UIListLayout")
    gtList.SortOrder = Enum.SortOrder.LayoutOrder
    gtList.Padding = UDim.new(0, 2)
    gtList.Parent = GrenadeTracersPopover

    local GrenadeSettingsPopover = Instance.new("Frame")
    GrenadeSettingsPopover.Name = "GrenadeSettingsPopover"
    GrenadeSettingsPopover.Size = UDim2.new(0, 195, 0, 116)
    GrenadeSettingsPopover.BackgroundColor3 = Color3.fromRGB(19, 20, 24)
    GrenadeSettingsPopover.BorderSizePixel = 0
    GrenadeSettingsPopover.Visible = false
    GrenadeSettingsPopover.ZIndex = 530
    GrenadeSettingsPopover.Parent = PopupsLayer
    createCorner(GrenadeSettingsPopover, 2)

    local gsPadding = Instance.new("UIPadding")
    gsPadding.PaddingTop = UDim.new(0, 6)
    gsPadding.PaddingBottom = UDim.new(0, 6)
    gsPadding.PaddingLeft = UDim.new(0, 10)
    gsPadding.PaddingRight = UDim.new(0, 10)
    gsPadding.Parent = GrenadeSettingsPopover

    local activeGrenadeItem = GrenadeTypes[1]

    local ColorRow = Instance.new("Frame")
    ColorRow.Name = "ColorRow"
    ColorRow.Size = UDim2.new(1, 0, 0, 22)
    ColorRow.Position = UDim2.new(0, 0, 0, 4)
    ColorRow.BackgroundTransparency = 1
    ColorRow.Parent = GrenadeSettingsPopover

    local ColorLbl = Instance.new("TextLabel")
    ColorLbl.Name = "ColorLabel"
    ColorLbl.Size = UDim2.new(0.6, 0, 1, 0)
    ColorLbl.BackgroundTransparency = 1
    ColorLbl.Text = "Color"
    ColorLbl.TextColor3 = Theme.TextActive
    ColorLbl.TextSize = 13
    ColorLbl.Font = Theme.FontBold
    ColorLbl.TextXAlignment = Enum.TextXAlignment.Left
    ColorLbl.Parent = ColorRow

    local ColorSwatch = Instance.new("TextButton")
    ColorSwatch.Name = "Swatch"
    ColorSwatch.Size = UDim2.new(0, 26, 0, 14)
    ColorSwatch.Position = UDim2.new(1, -26, 0.5, -7)
    ColorSwatch.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ColorSwatch.BorderSizePixel = 0
    ColorSwatch.AutoButtonColor = false
    ColorSwatch.Text = ""
    ColorSwatch.Parent = ColorRow
    createCorner(ColorSwatch, 3)

    ColorSwatch.MouseButton1Click:Connect(function()
        if not activeGrenadeItem then return end
        Controls:OpenColorPicker(ColorSwatch, activeGrenadeItem.Color, 1, function(newCol)
            activeGrenadeItem.Color = newCol
            ColorSwatch.BackgroundColor3 = newCol
        end)
    end)

    local TimeRow = Instance.new("Frame")
    TimeRow.Name = "TimeRow"
    TimeRow.Size = UDim2.new(1, 0, 0, 36)
    TimeRow.Position = UDim2.new(0, 0, 0, 32)
    TimeRow.BackgroundTransparency = 1
    TimeRow.Parent = GrenadeSettingsPopover

    local TimeLbl = Instance.new("TextLabel")
    TimeLbl.Name = "Label"
    TimeLbl.Size = UDim2.new(0.6, 0, 0, 16)
    TimeLbl.Position = UDim2.new(0, 0, 0, 0)
    TimeLbl.BackgroundTransparency = 1
    TimeLbl.Text = "Time"
    TimeLbl.TextColor3 = Theme.TextActive
    TimeLbl.TextSize = 13
    TimeLbl.Font = Theme.FontBold
    TimeLbl.TextXAlignment = Enum.TextXAlignment.Left
    TimeLbl.Parent = TimeRow

    local TimeVal = Instance.new("TextLabel")
    TimeVal.Name = "Value"
    TimeVal.Size = UDim2.new(0.4, 0, 0, 16)
    TimeVal.Position = UDim2.new(0.6, 0, 0, 0)
    TimeVal.BackgroundTransparency = 1
    TimeVal.Text = "5.00 s"
    TimeVal.TextColor3 = Theme.TextActive
    TimeVal.TextSize = 12
    TimeVal.Font = Theme.FontMedium
    TimeVal.TextXAlignment = Enum.TextXAlignment.Right
    TimeVal.Parent = TimeRow

    local TimeTrack = Instance.new("TextButton")
    TimeTrack.Name = "Track"
    TimeTrack.Size = UDim2.new(1, 0, 0, 6)
    TimeTrack.Position = UDim2.new(0, 0, 0, 22)
    TimeTrack.BackgroundColor3 = Color3.fromRGB(35, 37, 44)
    TimeTrack.BorderSizePixel = 0
    TimeTrack.AutoButtonColor = false
    TimeTrack.Text = ""
    TimeTrack.Parent = TimeRow
    createCorner(TimeTrack, 2)

    local TimeFill = Instance.new("Frame")
    TimeFill.Name = "Fill"
    TimeFill.Size = UDim2.new((5.00 - 0.5) / 9.5, 0, 1, 0)
    TimeFill.BackgroundColor3 = Color3.fromRGB(120, 125, 135)
    TimeFill.BorderSizePixel = 0
    TimeFill.Parent = TimeTrack
    createCorner(TimeFill, 2)

    local function updateTimeFromInput(input)
        if not activeGrenadeItem then return end
        local rel = math.clamp((input.Position.X - TimeTrack.AbsolutePosition.X) / math.max(1, TimeTrack.AbsoluteSize.X), 0, 1)
        local val = 0.5 + rel * (10.0 - 0.5)
        activeGrenadeItem.Time = val
        TimeFill.Size = UDim2.new(rel, 0, 1, 0)
        TimeVal.Text = string.format("%.2f s", val)
    end

    local isDraggingTime = false
    TimeTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingTime = true
            updateTimeFromInput(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingTime = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if isDraggingTime and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateTimeFromInput(input)
        end
    end)

    local ThickRow = Instance.new("Frame")
    ThickRow.Name = "ThickRow"
    ThickRow.Size = UDim2.new(1, 0, 0, 36)
    ThickRow.Position = UDim2.new(0, 0, 0, 72)
    ThickRow.BackgroundTransparency = 1
    ThickRow.Parent = GrenadeSettingsPopover

    local ThickLbl = Instance.new("TextLabel")
    ThickLbl.Name = "Label"
    ThickLbl.Size = UDim2.new(0.6, 0, 0, 16)
    ThickLbl.Position = UDim2.new(0, 0, 0, 0)
    ThickLbl.BackgroundTransparency = 1
    ThickLbl.Text = "Thickness"
    ThickLbl.TextColor3 = Theme.TextActive
    ThickLbl.TextSize = 13
    ThickLbl.Font = Theme.FontBold
    ThickLbl.TextXAlignment = Enum.TextXAlignment.Left
    ThickLbl.Parent = ThickRow

    local ThickVal = Instance.new("TextLabel")
    ThickVal.Name = "Value"
    ThickVal.Size = UDim2.new(0.4, 0, 0, 16)
    ThickVal.Position = UDim2.new(0.6, 0, 0, 0)
    ThickVal.BackgroundTransparency = 1
    ThickVal.Text = "1.10"
    ThickVal.TextColor3 = Theme.TextActive
    ThickVal.TextSize = 12
    ThickVal.Font = Theme.FontMedium
    ThickVal.TextXAlignment = Enum.TextXAlignment.Right
    ThickVal.Parent = ThickRow

    local ThickTrack = Instance.new("TextButton")
    ThickTrack.Name = "Track"
    ThickTrack.Size = UDim2.new(1, 0, 0, 6)
    ThickTrack.Position = UDim2.new(0, 0, 0, 22)
    ThickTrack.BackgroundColor3 = Color3.fromRGB(35, 37, 44)
    ThickTrack.BorderSizePixel = 0
    ThickTrack.AutoButtonColor = false
    ThickTrack.Text = ""
    ThickTrack.Parent = ThickRow
    createCorner(ThickTrack, 2)

    local ThickFill = Instance.new("Frame")
    ThickFill.Name = "Fill"
    ThickFill.Size = UDim2.new((1.10 - 0.1) / 4.9, 0, 1, 0)
    ThickFill.BackgroundColor3 = Color3.fromRGB(120, 125, 135)
    ThickFill.BorderSizePixel = 0
    ThickFill.Parent = ThickTrack
    createCorner(ThickFill, 2)

    local function updateThickFromInput(input)
        if not activeGrenadeItem then return end
        local rel = math.clamp((input.Position.X - ThickTrack.AbsolutePosition.X) / math.max(1, ThickTrack.AbsoluteSize.X), 0, 1)
        local val = 0.1 + rel * (5.0 - 0.1)
        activeGrenadeItem.Thickness = val
        ThickFill.Size = UDim2.new(rel, 0, 1, 0)
        ThickVal.Text = string.format("%.2f", val)
    end

    local isDraggingThick = false
    ThickTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingThick = true
            updateThickFromInput(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingThick = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if isDraggingThick and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateThickFromInput(input)
        end
    end)

    local function openGrenadeSettings(gItem)
        activeGrenadeItem = gItem
        ColorSwatch.BackgroundColor3 = gItem.Color
        TimeVal.Text = string.format("%.2f s", gItem.Time)
        TimeFill.Size = UDim2.new(math.clamp((gItem.Time - 0.5) / 9.5, 0, 1), 0, 1, 0)
        ThickVal.Text = string.format("%.2f", gItem.Thickness)
        ThickFill.Size = UDim2.new(math.clamp((gItem.Thickness - 0.1) / 4.9, 0, 1), 0, 1, 0)

        local mousePos = getRealMousePos()
        local subX = mousePos.X + 8
        local subY = mousePos.Y - 4
        local cam = workspace.CurrentCamera
        local viewSize = cam and cam.ViewportSize or Vector2.new(1920, 1080)
        if subX + 195 > viewSize.X - 8 then
            subX = math.max(8, viewSize.X - 195 - 8)
        end
        if subY + 116 > viewSize.Y - 8 then
            subY = math.max(8, viewSize.Y - 116 - 8)
        end
        if subY < 8 then subY = 8 end

        GrenadeSettingsPopover.Position = UDim2.new(0, subX, 0, subY)
        GrenadeSettingsPopover.Visible = true
    end

    local tracerClickables = {}

    local function buildGrenadeRow(idx, gData)
        local gRow = Instance.new("Frame")
        gRow.Name = "Row_" .. gData.Id
        gRow.Size = UDim2.new(1, 0, 0, 24)
        gRow.BackgroundTransparency = 1
        gRow.LayoutOrder = idx
        gRow.Parent = GrenadeTracersPopover

        local gBox = Instance.new("Frame")
        gBox.Name = "Box"
        gBox.Size = UDim2.new(0, 14, 0, 14)
        gBox.Position = UDim2.new(0, 0, 0.5, -7)
        gBox.BackgroundColor3 = gData.Enabled and Theme.CheckboxChecked or Theme.CheckboxOff
        gBox.BorderSizePixel = 0
        gBox.Parent = gRow
        createCorner(gBox, 2)

        local gCheck = Instance.new("TextLabel")
        gCheck.Name = "Check"
        gCheck.Size = UDim2.new(1, 0, 1, 0)
        gCheck.BackgroundTransparency = 1
        if GuiIconsFont then gCheck.FontFace = GuiIconsFont end
        gCheck.Text = "X"
        gCheck.TextColor3 = Color3.fromRGB(255, 255, 255)
        gCheck.TextSize = 11
        gCheck.Visible = gData.Enabled
        gCheck.Parent = gBox

        local gLabel = Instance.new("TextButton")
        gLabel.Name = "Label"
        gLabel.Size = UDim2.new(1, -44, 1, 0)
        gLabel.Position = UDim2.new(0, 22, 0, 0)
        gLabel.BackgroundTransparency = 1
        gLabel.Text = gData.Name
        gLabel.TextColor3 = gData.Enabled and Theme.TextActive or Theme.TextDim
        gLabel.TextSize = 12
        gLabel.Font = Theme.FontBold
        gLabel.TextXAlignment = Enum.TextXAlignment.Left
        gLabel.AutoButtonColor = false
        gLabel.Parent = gRow

        local gListBtn = Instance.new("TextButton")
        gListBtn.Name = "ListBtn"
        gListBtn.Size = UDim2.new(0, 16, 0, 16)
        gListBtn.Position = UDim2.new(1, -16, 0.5, -8)
        gListBtn.BackgroundTransparency = 1
        if GuiIconsFont then
            gListBtn.FontFace = GuiIconsFont
            gListBtn.Text = "6"
        else
            gListBtn.Font = Theme.FontBold
            gListBtn.Text = "≡"
        end
        gListBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        gListBtn.TextSize = 13
        gListBtn.AutoButtonColor = false
        gListBtn.Parent = gRow

        local function toggleRow()
            if os.clock() - lastPopoverDragTime < 0.12 then return end
            gData.Enabled = not gData.Enabled
            gBox.BackgroundColor3 = gData.Enabled and Theme.CheckboxChecked or Theme.CheckboxOff
            gCheck.Visible = gData.Enabled
            gLabel.TextColor3 = gData.Enabled and Theme.TextActive or Theme.TextDim
        end

        local gTrigger = Instance.new("TextButton")
        gTrigger.Name = "Trigger"
        gTrigger.Size = UDim2.new(0, 14, 0, 14)
        gTrigger.Position = UDim2.new(0, 0, 0.5, -7)
        gTrigger.BackgroundTransparency = 1
        gTrigger.Text = ""
        gTrigger.Parent = gRow
        gTrigger.MouseButton1Click:Connect(toggleRow)
        gLabel.MouseButton1Click:Connect(toggleRow)

        table.insert(tracerClickables, gTrigger)
        table.insert(tracerClickables, gLabel)
        table.insert(tracerClickables, gListBtn)

        gListBtn.MouseButton1Click:Connect(function()
            if GrenadeSettingsPopover.Visible and activeGrenadeItem == gData then
                GrenadeSettingsPopover.Visible = false
            else
                openGrenadeSettings(gData)
            end
        end)
    end

    for idx, gData in ipairs(GrenadeTypes) do
        buildGrenadeRow(idx, gData)
    end

    table.insert(ActivePopups, {
        Frame = GrenadeTracersPopover,
        OnClose = function()
            GrenadeSettingsPopover.Visible = false
            activeGrenadeAnchor = nil
        end
    })
    table.insert(ActivePopups, GrenadeSettingsPopover)

    makePopoverDraggable(GrenadeTracersPopover, function(pos)
        for _, elem in ipairs(tracerClickables) do
            if elem and isPosInGui(elem, pos) then return true end
        end
        return false
    end)

    makePopoverDraggable(GrenadeSettingsPopover, function(pos)
        if isPosInGui(ColorSwatch, pos) then return true end
        if isPosInGui(TimeTrack, pos, 4) then return true end
        if isPosInGui(ThickTrack, pos, 4) then return true end
        return false
    end)

    local activeGrenadeAnchor = nil

    local function toggleGrenadeTracers(btn)
        activeGrenadeAnchor = btn
        if GrenadeTracersPopover.Visible then
            GrenadeTracersPopover.Visible = false
            GrenadeSettingsPopover.Visible = false
        else
            CloseAllPopups()
            local mousePos = getRealMousePos()
            local posX = mousePos.X + 8
            local posY = mousePos.Y - 4
            local cam = workspace.CurrentCamera
            local viewSize = cam and cam.ViewportSize or Vector2.new(1920, 1080)
            if posX + 205 > viewSize.X - 8 then
                posX = math.max(8, viewSize.X - 205 - 8)
            end
            if posY + 142 > viewSize.Y - 8 then
                posY = math.max(8, viewSize.Y - 142 - 8)
            end
            if posY < 8 then posY = 8 end
            GrenadeTracersPopover.Position = UDim2.new(0, posX, 0, posY)
            GrenadeTracersPopover.Visible = true
        end
    end

    local gtOutsideConn = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if not GrenadeTracersPopover.Visible and not GrenadeSettingsPopover.Visible then return end
            if os.clock() - lastPopoverDragTime < 0.2 then return end
            local pos = input.Position
            if isPosInGui(GrenadeTracersPopover, pos) then
                return
            end
            if isPosInGui(GrenadeSettingsPopover, pos) then
                return
            end
            if activeGrenadeAnchor and isPosInGui(activeGrenadeAnchor, pos) then
                return
            end
            if ColorPickerModal.Visible and isPosInGui(ColorPickerModal, pos) then
                return
            end
            GrenadeSettingsPopover.Visible = false
            GrenadeTracersPopover.Visible = false
        end
    end)
    table.insert(Connections, gtOutsideConn)

    return toggleGrenadeTracers
end

    local toggleGrenadeTracers = createGrenadeTracersUI()
    function Controls:OpenGrenadeTracers(btn)
        toggleGrenadeTracers(btn)
    end
end

do
    local function run()
        local VisualsTab = Tabs["Visuals"]
        local VLeft = VisualsTab.LeftColumn
        local VRight = VisualsTab.RightColumn

        local vLeftOrder = 0
        local function nextVLeft()
            vLeftOrder += 1
            return vLeftOrder
        end

        local vRightOrder = 0
        local function nextVRight()
            vRightOrder += 1
            return vRightOrder
        end

        Controls:CreateSectionHeader(VLeft, "Grenades", nextVLeft())

        Controls:CreateToggle(VLeft, {
            Name = "Grenade prediction",
            Default = false,
            ColorChips = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255) },
            LayoutOrder = nextVLeft()
        })

        Controls:CreateToggle(VLeft, {
            Name = "Smoke grenade timer",
            Default = false,
            ColorChip = Color3.fromRGB(255, 255, 255),
            LayoutOrder = nextVLeft()
        })

        Controls:CreateToggle(VLeft, {
            Name = "Incendiary grenade timer",
            Default = false,
            ColorChip = Color3.fromRGB(255, 255, 255),
            LayoutOrder = nextVLeft()
        })

        Controls:CreateToggle(VLeft, {
            Name = "Grenade tracers",
            Default = false,
            SettingsIcon = true,
            SettingsIconText = "6",
            SettingsIconFont = GuiIconsFont,
            SettingsIconSize = 13,
            OnSettingsClick = function(btn)
                if Controls.OpenGrenadeTracers then
                    Controls:OpenGrenadeTracers(btn)
                end
            end,
            LayoutOrder = nextVLeft()
        })

        Controls:CreateSectionHeader(VRight, "Miscellaneous", nextVRight())

        Controls:CreateToggle(VRight, {
            Name = "Bomb timer",
            Default = false,
            LayoutOrder = nextVRight()
        })

        Controls:CreateToggle(VRight, {
            Name = "Spectator list",
            Default = false,
            LayoutOrder = nextVRight()
        })

        Controls:CreateToggle(VRight, {
            Name = "Hit marker",
            Default = false,
            ColorChip = Color3.fromRGB(255, 255, 255),
            LayoutOrder = nextVRight()
        })
    end
    run()
end

MemeSenseInventory = {
    MasterSwitch = (tabMasterStates["Inventory"] ~= false),
    Items = {},
    CurrentCategory = "Equipment",
    CurrentSubcategory = "Knives",
    ActiveView = "Grid",
    SelectedWeapon = nil,
    RefreshUI = nil,
    SyncGame = nil,
    OnMasterSwitchChanged = nil,
}

local MemeSenseViewmodel = {
    HandShakes = true,
    FieldOfView = 0,
    CustomOrigin = false,
    OriginX = 0,
    OriginY = 0,
    OriginZ = 0,
    CustomAngles = false,
    Pitch = 0,
    Yaw = 0,
    Roll = 0,
}

local MemeSenseCamera = {
    FieldOfView = 0,
    ZoomFieldOfView1 = 0,
    ZoomFieldOfView2 = 0,
    ThirdPersonEnabled = false,
    ThirdPersonDistance = 150,
    ThirdPersonHeight = -0.6,
    ThirdPersonSide = 0.0,
    ZoomHud = false,
    ZoomSpread = false,
    ForceSniperCrosshair = false,
    SpreadRemoval = false,
    VisualRecoilRemoval = false,
    SmokeRemoval = false,
    FlashScale = 1.00,
    CustomAmbientEnabled = false,
    CustomAmbientColor = Color3.fromRGB(255, 255, 255),
    CustomLightingEnabled = false,
    CustomLightingR = 10.000,
    CustomLightingG = 10.000,
    CustomLightingB = 10.000,
    Exposure = 1.000,
}

local sniperCrosshairClone = nil

local function getGameCrosshairAndMiddle()
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    local mg = pGui and pGui:FindFirstChild("MainGui")
    local mid = mg and (mg:FindFirstChild("Middle") or (mg:FindFirstChild("Gameplay") and mg.Gameplay:FindFirstChild("Middle")))
    local crosshair = mid and mid:FindFirstChild("Crosshair")
    return crosshair, mid
end

local function getOrCreateSniperCrosshair()
    if sniperCrosshairClone and sniperCrosshairClone.Parent then
        return sniperCrosshairClone
    end
    local gameCrosshair = getGameCrosshairAndMiddle()
    if gameCrosshair and ScopeScreenGui then
        sniperCrosshairClone = gameCrosshair:Clone()
        sniperCrosshairClone.Name = "MemeSenseSniperCrosshair"
        sniperCrosshairClone.Position = UDim2.fromScale(0.5, 0.5)
        sniperCrosshairClone.AnchorPoint = Vector2.new(0.5, 0.5)
        sniperCrosshairClone.Visible = false
        sniperCrosshairClone.Parent = ScopeScreenGui
        return sniperCrosshairClone
    end
    return nil
end

local function isCurrentWeaponSniper()
    local cam = workspace.CurrentCamera
    if cam then
        for _, v in ipairs(cam:GetChildren()) do
            if v:IsA("Model") and v:FindFirstChild("Stats") then
                local n = string.lower(v.Name)
                if string.find(n, "awp") or string.find(n, "ssg") or string.find(n, "scout") or string.find(n, "sniper") then
                    return true
                end
            end
        end
        for _, v in ipairs(cam:GetDescendants()) do
            if v:IsA("Model") and v:FindFirstChild("Stats") then
                local n = string.lower(v.Name)
                if string.find(n, "awp") or string.find(n, "ssg") or string.find(n, "scout") or string.find(n, "sniper") then
                    return true
                end
            end
        end
    end
    local char = LocalPlayer.Character
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") or (item:IsA("Model") and item:FindFirstChild("Handle")) then
                local n = string.lower(item.Name)
                if string.find(n, "awp") or string.find(n, "ssg") or string.find(n, "scout") or string.find(n, "sniper") then
                    return true
                end
            end
        end
    end
    local currentWeaponAttr = LocalPlayer:GetAttribute("CurrentWeapon") or LocalPlayer:GetAttribute("EquippedWeapon")
    if currentWeaponAttr and typeof(currentWeaponAttr) == "string" then
        local n = string.lower(currentWeaponAttr)
        if string.find(n, "awp") or string.find(n, "ssg") or string.find(n, "scout") or string.find(n, "sniper") then
            return true
        end
    end
    return false
end

local function isPlayerAiming()
    if hookedScopeInstance and hookedScopeInstance.Visible then
        return true
    end
    if ScopeOverlay and ScopeOverlay.Visible then
        return true
    end
    if LocalPlayer:GetAttribute("IsAiming") == true or LocalPlayer:GetAttribute("IsSniperScoped") == true then
        return true
    end
    local scopeInc = LocalPlayer:GetAttribute("ScopeIncrement")
    if type(scopeInc) == "number" and scopeInc > 0 then
        return true
    end
    return false
end

local function areGameMenusOpen(mid)
    if not mid then
        local _, foundMid = getGameCrosshairAndMiddle()
        mid = foundMid
    end
    if not mid then return false end
    local ts = mid:FindFirstChild("TeamSelection")
    local lb = mid:FindFirstChild("Leaderboard")
    local es = mid:FindFirstChild("EndScreen")
    local bm = mid:FindFirstChild("BuyMenu")
    return (ts and ts.Visible) or (lb and lb.Visible) or (es and es.Visible) or (bm and bm.Visible) or false
end

local function updateSniperCrosshairFrame()
    if not MemeSenseCamera.ForceSniperCrosshair then
        if sniperCrosshairClone then
            sniperCrosshairClone.Visible = false
        end
        return
    end

    local isSniper = isCurrentWeaponSniper()
    local isAiming = isPlayerAiming()
    local inMenu = areGameMenusOpen()

    if isSniper and not isAiming and not inMenu then
        local clone = getOrCreateSniperCrosshair()
        if clone then
            clone.Visible = true
            local ticks = clone:FindFirstChild("Ticks")
            if ticks then ticks.Visible = true end
            local dot = clone:FindFirstChild("Dot")
            if dot then
                local originalCrosshair = getGameCrosshairAndMiddle()
                if originalCrosshair and originalCrosshair:FindFirstChild("Dot") then
                    dot.Visible = originalCrosshair.Dot.Visible
                    dot.BackgroundColor3 = originalCrosshair.Dot.BackgroundColor3
                else
                    dot.Visible = true
                end
            end
        end
    else
        if sniperCrosshairClone then
            sniperCrosshairClone.Visible = false
        end
    end
end

local function setForceSniperCrosshair(enabled)
    MemeSenseCamera.ForceSniperCrosshair = enabled
    if not enabled then
        if sniperCrosshairClone then
            sniperCrosshairClone.Visible = false
        end
    else
        updateSniperCrosshairFrame()
    end
end

local SpreadState = {
    hooked = false,
    origGetTrueSpread = nil,
    origGetSpreadForConfig = nil,
    origGetBaseSpread = nil,
    origGetBaseSpreadForConfig = nil,
    origGetMovementSpreadForConfig = nil,
    origPerformRaycast = nil,
}

local function hookSpreadRemoval()
    pcall(function()
        local components = ReplicatedStorage:FindFirstChild("Components")
        local weaponComp = components and components:FindFirstChild("Weapon")
        local classes = weaponComp and weaponComp:FindFirstChild("Classes")
        local bulletScript = classes and classes:FindFirstChild("Bullet")
        if bulletScript then
            local BulletClass = require(bulletScript)
            if BulletClass and not SpreadState.hooked then
                SpreadState.hooked = true
                SpreadState.origGetTrueSpread = BulletClass.getTrueSpread
                SpreadState.origGetSpreadForConfig = BulletClass.getSpreadForConfig
                SpreadState.origGetBaseSpread = BulletClass.getBaseSpread
                SpreadState.origGetBaseSpreadForConfig = BulletClass.getBaseSpreadForConfig
                SpreadState.origGetMovementSpreadForConfig = BulletClass.getMovementSpreadForConfig
                SpreadState.origPerformRaycast = BulletClass._performRaycast

                if type(BulletClass.getTrueSpread) == "function" then
                    BulletClass.getTrueSpread = function(self, ...)
                        if MemeSenseCamera.SpreadRemoval then
                            return 0
                        end
                        if SpreadState.origGetTrueSpread then
                            return SpreadState.origGetTrueSpread(self, ...)
                        end
                        return 0
                    end
                end

                if type(BulletClass.getSpreadForConfig) == "function" then
                    BulletClass.getSpreadForConfig = function(self, ...)
                        if MemeSenseCamera.SpreadRemoval then
                            return 0
                        end
                        if SpreadState.origGetSpreadForConfig then
                            return SpreadState.origGetSpreadForConfig(self, ...)
                        end
                        return 0
                    end
                end

                if type(BulletClass.getBaseSpread) == "function" then
                    BulletClass.getBaseSpread = function(self, ...)
                        if MemeSenseCamera.SpreadRemoval then
                            return 0
                        end
                        if SpreadState.origGetBaseSpread then
                            return SpreadState.origGetBaseSpread(self, ...)
                        end
                        return 0
                    end
                end

                if type(BulletClass.getBaseSpreadForConfig) == "function" then
                    BulletClass.getBaseSpreadForConfig = function(self, ...)
                        if MemeSenseCamera.SpreadRemoval then
                            return 0
                        end
                        if SpreadState.origGetBaseSpreadForConfig then
                            return SpreadState.origGetBaseSpreadForConfig(self, ...)
                        end
                        return 0
                    end
                end

                if type(BulletClass.getMovementSpreadForConfig) == "function" then
                    BulletClass.getMovementSpreadForConfig = function(self, ...)
                        if MemeSenseCamera.SpreadRemoval then
                            return 0
                        end
                        if SpreadState.origGetMovementSpreadForConfig then
                            return SpreadState.origGetMovementSpreadForConfig(self, ...)
                        end
                        return 0
                    end
                end

                if type(BulletClass._performRaycast) == "function" then
                    BulletClass._performRaycast = function(self, spreadValue, ...)
                        if MemeSenseCamera.SpreadRemoval then
                            spreadValue = 0
                        end
                        if SpreadState.origPerformRaycast then
                            return SpreadState.origPerformRaycast(self, spreadValue, ...)
                        end
                    end
                end
            end
        end
    end)
end

local function setSpreadRemoval(enable)
    MemeSenseCamera.SpreadRemoval = enable
    hookSpreadRemoval()
end

local LightingState = {
    isApplying = false,
    cameraLightingCC = nil,
    origAmbient = Lighting and Lighting.Ambient,
    origOutdoorAmbient = Lighting and Lighting.OutdoorAmbient,
    origColorShift_Top = Lighting and Lighting.ColorShift_Top,
    origColorShift_Bottom = Lighting and Lighting.ColorShift_Bottom,
    origExposureCompensation = Lighting and Lighting.ExposureCompensation or 0,
    lastMapName = nil,
    cachedMapProps = nil,
    customLightingApplied = false,
    customAmbientApplied = false,
    exposureApplied = false,
}

local function getMapLightingProperties()
    local mapObj = workspace:FindFirstChild("Map")
    local mapName = mapObj and mapObj:GetAttribute("MapName")
    if mapName and type(mapName) == "string" then
        if LightingState.lastMapName == mapName and LightingState.cachedMapProps then
            return LightingState.cachedMapProps
        end
        local db = ReplicatedStorage:FindFirstChild("Database")
        local custom = db and db:FindFirstChild("Custom")
        local gameStats = custom and custom:FindFirstChild("GameStats")
        local maps = gameStats and gameStats:FindFirstChild("Maps")
        local mapMod = maps and maps:FindFirstChild(mapName)
        if mapMod and mapMod:IsA("ModuleScript") then
            local success, mapData = pcall(require, mapMod)
            if success and mapData and mapData.Lighting and mapData.Lighting.Properties then
                LightingState.lastMapName = mapName
                LightingState.cachedMapProps = mapData.Lighting.Properties
                return mapData.Lighting.Properties
            end
        end
    end
    return nil
end

local function applyLightingEnforcement()
    if LightingState.isApplying then return end
    LightingState.isApplying = true
    pcall(function()
        local mapProps = getMapLightingProperties()
        local defaultAmbient = mapProps and mapProps.Ambient or LightingState.origAmbient or Lighting.Ambient
        local defaultOutdoor = mapProps and mapProps.OutdoorAmbient or LightingState.origOutdoorAmbient or Lighting.OutdoorAmbient
        local defaultShiftTop = mapProps and mapProps.ColorShift_Top or LightingState.origColorShift_Top or Lighting.ColorShift_Top
        local defaultShiftBottom = mapProps and mapProps.ColorShift_Bottom or LightingState.origColorShift_Bottom or Lighting.ColorShift_Bottom
        local defaultExposure = mapProps and mapProps.ExposureCompensation or LightingState.origExposureCompensation or 0

        local curExp = MemeSenseCamera.Exposure or 1.000
        if math.abs(curExp - 1.000) > 0.001 then
            LightingState.exposureApplied = true
            local targetExposure = defaultExposure + (curExp - 1.000) * 2.0
            if Lighting.ExposureCompensation ~= targetExposure then
                Lighting.ExposureCompensation = targetExposure
            end
        else
            if LightingState.exposureApplied then
                if Lighting.ExposureCompensation ~= defaultExposure then
                    Lighting.ExposureCompensation = defaultExposure
                end
                LightingState.exposureApplied = false
            end
        end

        if MemeSenseCamera.CustomAmbientEnabled then
            LightingState.customAmbientApplied = true
            local amb = MemeSenseCamera.CustomAmbientColor or Color3.fromRGB(255, 255, 255)
            if Lighting.Ambient ~= amb then
                Lighting.Ambient = amb
            end
            if Lighting.OutdoorAmbient ~= amb then
                Lighting.OutdoorAmbient = amb
            end
            for _, child in ipairs(Lighting:GetChildren()) do
                if child:IsA("Atmosphere") then
                    if child.Color ~= amb then child.Color = amb end
                    if child.Decay ~= amb then child.Decay = amb end
                end
            end
        else
            if LightingState.customAmbientApplied then
                if Lighting.Ambient ~= defaultAmbient then
                    Lighting.Ambient = defaultAmbient
                end
                if Lighting.OutdoorAmbient ~= defaultOutdoor then
                    Lighting.OutdoorAmbient = defaultOutdoor
                end
                LightingState.customAmbientApplied = false
            end
        end

        local cam = workspace.CurrentCamera
        local camCC = LightingState.cameraLightingCC
        if not camCC or not camCC.Parent or (cam and camCC.Parent ~= cam) then
            if cam then
                camCC = cam:FindFirstChild("MemeSenseCustomLighting")
                if not camCC then
                    camCC = Instance.new("ColorCorrectionEffect")
                    camCC.Name = "MemeSenseCustomLighting"
                    camCC.Parent = cam
                end
                LightingState.cameraLightingCC = camCC
            end
        end

        if MemeSenseCamera.CustomLightingEnabled then
            LightingState.customLightingApplied = true
            local r = math.clamp(MemeSenseCamera.CustomLightingR or 10, 0, 10) / 10
            local g = math.clamp(MemeSenseCamera.CustomLightingG or 10, 0, 10) / 10
            local b = math.clamp(MemeSenseCamera.CustomLightingB or 10, 0, 10) / 10
            local tint = Color3.new(r, g, b)

            if camCC then
                if not camCC.Enabled then camCC.Enabled = true end
                if camCC.TintColor ~= tint then camCC.TintColor = tint end
            end

            local topCol = Color3.fromRGB(math.clamp(r * 255, 0, 255), math.clamp(g * 255, 0, 255), math.clamp(b * 255, 0, 255))
            if Lighting.ColorShift_Top ~= topCol then
                Lighting.ColorShift_Top = topCol
            end

            local botCol = Color3.fromRGB(math.clamp(r * 128, 0, 255), math.clamp(g * 128, 0, 255), math.clamp(b * 128, 0, 255))
            if Lighting.ColorShift_Bottom ~= botCol then
                Lighting.ColorShift_Bottom = botCol
            end

            if not MemeSenseCamera.CustomAmbientEnabled then
                local outCol = Color3.fromRGB(math.clamp(r * 220, 0, 255), math.clamp(g * 220, 0, 255), math.clamp(b * 220, 0, 255))
                if Lighting.OutdoorAmbient ~= outCol then
                    Lighting.OutdoorAmbient = outCol
                end
                local inCol = Color3.fromRGB(math.clamp(r * 180, 0, 255), math.clamp(g * 180, 0, 255), math.clamp(b * 180, 0, 255))
                if Lighting.Ambient ~= inCol then
                    Lighting.Ambient = inCol
                end
            end
        else
            if camCC and camCC.Enabled then
                camCC.Enabled = false
            end
            if LightingState.customLightingApplied then
                if Lighting.ColorShift_Top ~= defaultShiftTop then
                    Lighting.ColorShift_Top = defaultShiftTop
                end
                if Lighting.ColorShift_Bottom ~= defaultShiftBottom then
                    Lighting.ColorShift_Bottom = defaultShiftBottom
                end
                if not MemeSenseCamera.CustomAmbientEnabled then
                    if Lighting.Ambient ~= defaultAmbient then
                        Lighting.Ambient = defaultAmbient
                    end
                    if Lighting.OutdoorAmbient ~= defaultOutdoor then
                        Lighting.OutdoorAmbient = defaultOutdoor
                    end
                end
                LightingState.customLightingApplied = false
            end
        end
    end)
    LightingState.isApplying = false
end

local function updateLightingState()
    applyLightingEnforcement()
end

local function setExposure(val)
    MemeSenseCamera.Exposure = val
    applyLightingEnforcement()
end

local RecoilState = {
    origWeaponKick = nil,
    origSetWeaponRecoil = nil,
    origResetWeaponRecoil = nil,
    origGetWeaponRecoil = nil,
}

local function hookCameraControllerRecoil()
    pcall(function()
        local controllers = ReplicatedStorage:FindFirstChild("Controllers")
        local cc = controllers and controllers:FindFirstChild("CameraController")
        if cc then
            local cameraController = require(cc)
            if cameraController then
                if not RecoilState.origWeaponKick and type(cameraController.weaponKick) == "function" then
                    RecoilState.origWeaponKick = cameraController.weaponKick
                end
                if not RecoilState.origSetWeaponRecoil and type(cameraController.setWeaponRecoil) == "function" then
                    RecoilState.origSetWeaponRecoil = cameraController.setWeaponRecoil
                end
                if not RecoilState.origResetWeaponRecoil and type(cameraController.resetWeaponRecoil) == "function" then
                    RecoilState.origResetWeaponRecoil = cameraController.resetWeaponRecoil
                end
                if not RecoilState.origGetWeaponRecoil and type(cameraController.getWeaponRecoil) == "function" then
                    RecoilState.origGetWeaponRecoil = cameraController.getWeaponRecoil
                end

                cameraController.weaponKick = function(p54, p55)
                    if MemeSenseCamera.VisualRecoilRemoval then
                        return
                    end
                    if RecoilState.origWeaponKick then
                        return RecoilState.origWeaponKick(p54, p55)
                    end
                end

                cameraController.setWeaponRecoil = function(p56, p57)
                    if MemeSenseCamera.VisualRecoilRemoval then
                        if cameraController.resetWeaponRecoil then
                            pcall(cameraController.resetWeaponRecoil)
                        elseif RecoilState.origResetWeaponRecoil then
                            pcall(RecoilState.origResetWeaponRecoil)
                        end
                        return
                    end
                    if RecoilState.origSetWeaponRecoil then
                        return RecoilState.origSetWeaponRecoil(p56, p57)
                    end
                end

                cameraController.getWeaponRecoil = function()
                    if MemeSenseCamera.VisualRecoilRemoval then
                        return Vector3.zero
                    end
                    if RecoilState.origGetWeaponRecoil then
                        return RecoilState.origGetWeaponRecoil()
                    end
                    return Vector3.zero
                end
            end
        end
    end)
end

local function setVisualRecoilRemoval(enable)
    MemeSenseCamera.VisualRecoilRemoval = enable
    hookCameraControllerRecoil()
    if enable then
        pcall(function()
            local controllers = ReplicatedStorage:FindFirstChild("Controllers")
            local cc = controllers and controllers:FindFirstChild("CameraController")
            if cc then
                local cameraController = require(cc)
                if cameraController and cameraController.resetWeaponRecoil then
                    cameraController.resetWeaponRecoil()
                end
            end
        end)
    end
end

local FlashState = {
    connections = {},
    moduleHooked = false,
}

local function hookFlashEffectModule()
    if FlashState.moduleHooked then return end
    pcall(function()
        local feMod = ReplicatedStorage:FindFirstChild("Components")
            and ReplicatedStorage.Components:FindFirstChild("Common")
            and ReplicatedStorage.Components.Common:FindFirstChild("VFXLibary")
            and ReplicatedStorage.Components.Common.VFXLibary:FindFirstChild("FlashEffect")
        if feMod then
            local FlashEffect = require(feMod)
            if FlashEffect and type(FlashEffect.Flash) == "function" and not FlashEffect.__memesense_hooked then
                local origFlash = FlashEffect.Flash
                FlashEffect.__memesense_hooked = true
                FlashEffect.Flash = function(params)
                    local currentScale = MemeSenseCamera.FlashScale or 0.00
                    if currentScale <= 0.00 then
                        pcall(function()
                            if FlashEffect.CancelFlash then
                                FlashEffect.CancelFlash()
                            end
                        end)
                        return false
                    end
                    local res = origFlash(params)
                    pcall(applyFlashScale)
                    return res
                end
                FlashState.moduleHooked = true
            end
        end
    end)
end

local function applyFlashScale()
    local scale = MemeSenseCamera.FlashScale or 0.00
    if scale >= 1.00 then return end

    if scale <= 0.00 then
        pcall(function()
            local feMod = ReplicatedStorage:FindFirstChild("Components")
                and ReplicatedStorage.Components:FindFirstChild("Common")
                and ReplicatedStorage.Components.Common:FindFirstChild("VFXLibary")
                and ReplicatedStorage.Components.Common.VFXLibary:FindFirstChild("FlashEffect")
            if feMod then
                local FlashEffect = require(feMod)
                if FlashEffect and FlashEffect.CancelFlash then
                    FlashEffect.CancelFlash()
                end
            end
        end)
    end

    pcall(function()
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        if pGui then
            for _, child in ipairs(pGui:GetChildren()) do
                if child:IsA("ScreenGui") and (child.Name == "FlashbangEffect" or child.Name == "FlashScreenshot" or string.find(child.Name:lower(), "flash")) then
                    child.Enabled = (scale > 0.00)
                    for _, desc in ipairs(child:GetDescendants()) do
                        if scale <= 0.00 then
                            if desc:IsA("GuiObject") then
                                desc.Visible = false
                                if desc:IsA("Frame") then
                                    desc.BackgroundTransparency = 1
                                elseif desc:IsA("ImageLabel") or desc:IsA("ImageButton") then
                                    desc.ImageTransparency = 1
                                end
                            end
                        else
                            local minTrans = 1 - scale
                            if desc:IsA("Frame") then
                                if desc.BackgroundTransparency < minTrans then
                                    desc.BackgroundTransparency = minTrans
                                end
                                desc.Visible = true
                            elseif desc:IsA("ImageLabel") or desc:IsA("ImageButton") then
                                if desc.ImageTransparency < minTrans then
                                    desc.ImageTransparency = minTrans
                                end
                                desc.Visible = true
                            end
                        end
                    end
                end
            end
        end
    end)

    pcall(function()
        local function processColorCorrection(parent)
            if not parent then return end
            for _, child in ipairs(parent:GetChildren()) do
                if child:IsA("ColorCorrectionEffect") and (child.Name == "FlashbangColorCorrection" or string.find(child.Name:lower(), "flash")) then
                    if scale <= 0.00 then
                        child.Brightness = 0
                        child.Saturation = 0
                        child.Contrast = 0
                        child.Enabled = false
                    else
                        if child.Brightness > scale then
                            child.Brightness = scale
                        end
                        if child.Saturation < -scale then
                            child.Saturation = -scale
                        end
                        child.Enabled = true
                    end
                end
            end
        end
        processColorCorrection(Lighting)
        processColorCorrection(workspace.CurrentCamera)
    end)

    pcall(function()
        local cam = workspace.CurrentCamera
        if cam then
            for _, child in ipairs(cam:GetChildren()) do
                if child:IsA("Sound") and (child.Name == "Flashed" or string.find(child.Name:lower(), "flash")) then
                    if scale <= 0.00 then
                        child.Volume = 0
                        child:Stop()
                    else
                        child.Volume = math.min(child.Volume, scale)
                    end
                end
            end
        end
    end)
end

local function hookFlashListeners()
    hookFlashEffectModule()
    if #FlashState.connections > 0 then return end

    pcall(function()
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        if pGui then
            local pGuiConn = pGui.ChildAdded:Connect(function(child)
                if child:IsA("ScreenGui") and (child.Name == "FlashbangEffect" or child.Name == "FlashScreenshot" or string.find(child.Name:lower(), "flash")) then
                    task.defer(applyFlashScale)
                    local cConn = child.DescendantAdded:Connect(function()
                        task.defer(applyFlashScale)
                    end)
                    table.insert(FlashState.connections, cConn)
                    table.insert(Connections, cConn)
                end
            end)
            table.insert(FlashState.connections, pGuiConn)
            table.insert(Connections, pGuiConn)
        end
    end)

    pcall(function()
        local lightConn = Lighting.ChildAdded:Connect(function(child)
            if child:IsA("ColorCorrectionEffect") and (child.Name == "FlashbangColorCorrection" or string.find(child.Name:lower(), "flash")) then
                task.defer(applyFlashScale)
                local ccConn = child:GetPropertyChangedSignal("Brightness"):Connect(function()
                    applyFlashScale()
                end)
                table.insert(FlashState.connections, ccConn)
                table.insert(Connections, ccConn)
            end
        end)
        table.insert(FlashState.connections, lightConn)
        table.insert(Connections, lightConn)
    end)

    pcall(function()
        local cam = workspace.CurrentCamera
        if cam then
            local camConn = cam.ChildAdded:Connect(function(child)
                if (child:IsA("Sound") and string.find(child.Name:lower(), "flash")) or child:IsA("ColorCorrectionEffect") then
                    task.defer(applyFlashScale)
                end
            end)
            table.insert(FlashState.connections, camConn)
            table.insert(Connections, camConn)
        end
    end)
end

local function setFlashScale(val)
    val = math.clamp(tonumber(val) or 0.00, 0.00, 1.00)
    MemeSenseCamera.FlashScale = val
    hookFlashListeners()
    applyFlashScale()
end

local SmokeState = {
    conn = nil,
    originalEmitterStates = {},
}

local function applySmokeRemovalToInstance(inst)
    if not inst then return end
    pcall(function()
        if inst:IsA("ParticleEmitter") then
            local parent = inst.Parent
            local isSmokeEmitter = false
            if parent and (parent.Name == "SmokeVoxel" or string.find(parent.Name, "Smoke") or (parent.Parent and string.find(parent.Parent.Name, "VoxelSmoke"))) then
                isSmokeEmitter = true
            elseif string.find(inst.Name, "Smoke") then
                isSmokeEmitter = true
            end
            if isSmokeEmitter then
                if SmokeState.originalEmitterStates[inst] == nil then
                    SmokeState.originalEmitterStates[inst] = {
                        Enabled = inst.Enabled,
                        Rate = inst.Rate,
                        Transparency = inst.Transparency
                    }
                end
                inst.Enabled = false
                inst.Rate = 0
                inst.Transparency = NumberSequence.new(1)
            end
        elseif inst:IsA("BasePart") and inst.Name == "SmokeVoxel" then
            inst.Transparency = 1
            for _, child in ipairs(inst:GetDescendants()) do
                if child:IsA("ParticleEmitter") then
                    if SmokeState.originalEmitterStates[child] == nil then
                        SmokeState.originalEmitterStates[child] = {
                            Enabled = child.Enabled,
                            Rate = child.Rate,
                            Transparency = child.Transparency
                        }
                    end
                    child.Enabled = false
                    child.Rate = 0
                    child.Transparency = NumberSequence.new(1)
                end
            end
        elseif inst:IsA("Folder") and string.find(inst.Name, "^VoxelSmoke_") then
            for _, desc in ipairs(inst:GetDescendants()) do
                if desc:IsA("BasePart") then
                    desc.Transparency = 1
                elseif desc:IsA("ParticleEmitter") then
                    if SmokeState.originalEmitterStates[desc] == nil then
                        SmokeState.originalEmitterStates[desc] = {
                            Enabled = desc.Enabled,
                            Rate = desc.Rate,
                            Transparency = desc.Transparency
                        }
                    end
                    desc.Enabled = false
                    desc.Rate = 0
                    desc.Transparency = NumberSequence.new(1)
                end
            end
        end
    end)
end

local function restoreSmokeEmitters()
    for emitter, state in pairs(SmokeState.originalEmitterStates) do
        pcall(function()
            if emitter and emitter.Parent then
                emitter.Enabled = state.Enabled
                emitter.Rate = state.Rate
                emitter.Transparency = state.Transparency
            end
        end)
    end
    table.clear(SmokeState.originalEmitterStates)
end

local function scanAndRemoveAllSmoke()
    pcall(function()
        local debris = workspace:FindFirstChild("Debris")
        if debris then
            for _, child in ipairs(debris:GetChildren()) do
                applySmokeRemovalToInstance(child)
            end
        end
        for _, child in ipairs(workspace:GetChildren()) do
            if string.find(child.Name, "Smoke") then
                applySmokeRemovalToInstance(child)
            end
        end
    end)
end

local function setSmokeRemoval(enable)
    MemeSenseCamera.SmokeRemoval = enable
    if enable then
        scanAndRemoveAllSmoke()
        if not SmokeState.conn then
            SmokeState.conn = workspace.DescendantAdded:Connect(function(desc)
                if MemeSenseCamera.SmokeRemoval then
                    applySmokeRemovalToInstance(desc)
                end
            end)
            table.insert(Connections, SmokeState.conn)
        end
    else
        if SmokeState.conn then
            SmokeState.conn:Disconnect()
            SmokeState.conn = nil
        end
        restoreSmokeEmitters()
    end
end

local hookedScopeInstance = nil
local scopeConns = {}
local isEnforcingZoomSpread = false

local function enforceZoomSpread(ssInstance)
    if not ssInstance or isEnforcingZoomSpread then return end
    if not MemeSenseCamera.ZoomSpread then return end
    isEnforcingZoomSpread = true
    pcall(function()
        local blur = ssInstance:FindFirstChild("Blur")
        local sharp = ssInstance:FindFirstChild("Sharp")
        if blur then
            if blur.Visible then
                blur.Visible = false
            end
            if (blur:IsA("ImageLabel") or blur:IsA("ImageButton")) and blur.ImageTransparency < 1 then
                blur.ImageTransparency = 1
            end
        end
        if sharp then
            if not sharp.Visible then
                sharp.Visible = true
            end
            if (sharp:IsA("ImageLabel") or sharp:IsA("ImageButton")) and sharp.ImageTransparency > 0 then
                sharp.ImageTransparency = 0
            end
        end
    end)
    isEnforcingZoomSpread = false
end

local function setupScopeHook(ssInstance)
    if not ssInstance or hookedScopeInstance == ssInstance then return end
    hookedScopeInstance = ssInstance

    pcall(function()
        for _, child in ipairs(ssInstance:GetChildren()) do
            if child.Name == "MemeSenseCustomScopeCrosshair" then
                child:Destroy()
            end
        end
    end)

    for _, c in ipairs(scopeConns) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(scopeConns)

    table.insert(scopeConns, ssInstance.ChildAdded:Connect(function(child)
        if child.Name == "MemeSenseCustomScopeCrosshair" then
            task.defer(function() child:Destroy() end)
        elseif MemeSenseCamera.ZoomHud and child:IsA("GuiObject") and not child:IsA("UIAspectRatioConstraint") then
            child.Visible = false
        elseif MemeSenseCamera.ZoomHud and child:IsA("UIStroke") then
            child.Enabled = false
        end
    end))

    local blur = ssInstance:FindFirstChild("Blur")
    local sharp = ssInstance:FindFirstChild("Sharp")

    if blur then
        table.insert(scopeConns, blur:GetPropertyChangedSignal("Visible"):Connect(function()
            if MemeSenseCamera.ZoomHud and blur.Visible then
                blur.Visible = false
            elseif MemeSenseCamera.ZoomSpread and blur.Visible then
                enforceZoomSpread(ssInstance)
            end
        end))
        if blur:IsA("ImageLabel") or blur:IsA("ImageButton") then
            table.insert(scopeConns, blur:GetPropertyChangedSignal("ImageTransparency"):Connect(function()
                if MemeSenseCamera.ZoomSpread and blur.ImageTransparency < 1 then
                    enforceZoomSpread(ssInstance)
                end
            end))
        end
    end

    if sharp then
        table.insert(scopeConns, sharp:GetPropertyChangedSignal("Visible"):Connect(function()
            if MemeSenseCamera.ZoomHud and sharp.Visible then
                sharp.Visible = false
            elseif MemeSenseCamera.ZoomSpread and not sharp.Visible then
                enforceZoomSpread(ssInstance)
            end
        end))
        if sharp:IsA("ImageLabel") or sharp:IsA("ImageButton") then
            table.insert(scopeConns, sharp:GetPropertyChangedSignal("ImageTransparency"):Connect(function()
                if MemeSenseCamera.ZoomSpread and sharp.ImageTransparency > 0 then
                    enforceZoomSpread(ssInstance)
                end
            end))
        end
    end
end

local function updateScopeVisuals(ssInstance, ssVisible)
    if not ssInstance then
        if ScopeOverlay and ScopeOverlay.Visible then
            ScopeOverlay.Visible = false
        end
        return
    end

    if MemeSenseCamera.ZoomHud then
        if ssVisible then
            ScopeOverlay.Visible = true
            ssInstance.BackgroundTransparency = 1
            ssInstance.BorderSizePixel = 0
            local ssStroke = ssInstance:FindFirstChildOfClass("UIStroke")
            if ssStroke then ssStroke.Enabled = false end
            for _, child in ipairs(ssInstance:GetChildren()) do
                if child.Name == "MemeSenseCustomScopeCrosshair" then
                    child:Destroy()
                elseif child:IsA("GuiObject") and not child:IsA("UIAspectRatioConstraint") then
                    child.Visible = false
                elseif child:IsA("UIStroke") then
                    child.Enabled = false
                end
            end
        else
            ScopeOverlay.Visible = false
        end
    else
        ScopeOverlay.Visible = false
        if ssVisible then
            for _, child in ipairs(ssInstance:GetChildren()) do
                if child.Name == "MemeSenseCustomScopeCrosshair" then
                    child:Destroy()
                elseif child:IsA("GuiObject") and not child:IsA("UIAspectRatioConstraint") then
                    child.Visible = true
                elseif child:IsA("UIStroke") then
                    child.Enabled = true
                end
            end
            local ssStroke = ssInstance:FindFirstChildOfClass("UIStroke")
            if ssStroke then ssStroke.Enabled = true end
            if MemeSenseCamera.ZoomSpread then
                enforceZoomSpread(ssInstance)
            end
        end
    end
end

local zoomRenderSteppedConn = RunService.RenderStepped:Connect(function()
    pcall(function()
        if not hookedScopeInstance or not hookedScopeInstance.Parent then
            local pGui = LocalPlayer:FindFirstChild("PlayerGui")
            local mg = pGui and pGui:FindFirstChild("MainGui")
            local mid = mg and (mg:FindFirstChild("Middle") or (mg:FindFirstChild("Gameplay") and mg.Gameplay:FindFirstChild("Middle")))
            local ss = mid and mid:FindFirstChild("SniperScope")
            if ss then
                setupScopeHook(ss)
            end
        end

        if hookedScopeInstance and hookedScopeInstance.Visible then
            if MemeSenseCamera.ZoomHud then
                ScopeOverlay.Visible = true
                hookedScopeInstance.BackgroundTransparency = 1
                hookedScopeInstance.BorderSizePixel = 0
                local ssStroke = hookedScopeInstance:FindFirstChildOfClass("UIStroke")
                if ssStroke then ssStroke.Enabled = false end
                for _, child in ipairs(hookedScopeInstance:GetChildren()) do
                    if child.Name == "MemeSenseCustomScopeCrosshair" then
                        child:Destroy()
                    elseif child:IsA("GuiObject") and not child:IsA("UIAspectRatioConstraint") then
                        child.Visible = false
                    elseif child:IsA("UIStroke") then
                        child.Enabled = false
                    end
                end
            elseif MemeSenseCamera.ZoomSpread then
                enforceZoomSpread(hookedScopeInstance)
            end
        end
    end)

    pcall(function()
        if MemeSenseCamera.ForceSniperCrosshair then
            updateSniperCrosshairFrame()
        elseif sniperCrosshairClone and sniperCrosshairClone.Visible then
            sniperCrosshairClone.Visible = false
        end
    end)

    pcall(function()
        if MemeSenseCamera.FlashScale and MemeSenseCamera.FlashScale < 1.00 then
            applyFlashScale()
        end
    end)

    pcall(function()
        if MemeSenseCamera.VisualRecoilRemoval then
            local controllers = ReplicatedStorage:FindFirstChild("Controllers")
            local cc = controllers and controllers:FindFirstChild("CameraController")
            if cc then
                local cameraController = require(cc)
                if cameraController and cameraController.resetWeaponRecoil then
                    cameraController.resetWeaponRecoil()
                end
            end
        end
    end)

    if MemeSenseCamera.CustomLightingEnabled or MemeSenseCamera.CustomAmbientEnabled or math.abs((MemeSenseCamera.Exposure or 1.000) - 1.000) > 0.001 or LightingState.customLightingApplied or LightingState.customAmbientApplied or LightingState.exposureApplied then
        pcall(function()
            applyLightingEnforcement()
        end)
    end
end)
table.insert(Connections, zoomRenderSteppedConn)

if Lighting then
    local lightingChangedConn = Lighting.Changed:Connect(function()
        if MemeSenseCamera.CustomAmbientEnabled or MemeSenseCamera.CustomLightingEnabled or math.abs((MemeSenseCamera.Exposure or 1.000) - 1.000) > 0.001 then
            applyLightingEnforcement()
        end
    end)
    table.insert(Connections, lightingChangedConn)
end

local function onMapLightingChanged()
    LightingState.lastMapName = nil
    LightingState.cachedMapProps = nil
    applyLightingEnforcement()
end

local mapChildConn = workspace.ChildAdded:Connect(function(child)
    if child.Name == "Map" then
        onMapLightingChanged()
        local attrConn = child:GetAttributeChangedSignal("MapName"):Connect(onMapLightingChanged)
        table.insert(Connections, attrConn)
    end
end)
table.insert(Connections, mapChildConn)

local existingMap = workspace:FindFirstChild("Map")
if existingMap then
    local attrConn = existingMap:GetAttributeChangedSignal("MapName"):Connect(onMapLightingChanged)
    table.insert(Connections, attrConn)
end

do
    local function run()
        local WorldTab = Tabs["World"]
        local WLeft = WorldTab.LeftColumn
        local WRight = WorldTab.RightColumn

        local wLeftOrder = 0
        local function nextWLeft()
            wLeftOrder += 1
            return wLeftOrder
        end

        local wRightOrder = 0
        local function nextWRight()
            wRightOrder += 1
            return wRightOrder
        end

        Controls:CreateSectionHeader(WLeft, "Textures", nextWLeft())

        Controls:CreateToggle(WLeft, {
            Name = "Skybox",
            Default = false,
            ColorChip = Color3.fromRGB(255, 255, 255),
            Dropdown = { Options = { "Default", "Night", "Sunset", "Clear" }, Default = "Default" },
            LayoutOrder = nextWLeft()
        })

        Controls:CreateToggle(WLeft, {
            Name = "Custom ambient color",
            Default = false,
            ColorChip = Color3.fromRGB(255, 255, 255),
            ColorCallback = function(newColor)
                MemeSenseCamera.CustomAmbientColor = newColor
                updateLightingState()
            end,
            Callback = function(v)
                MemeSenseCamera.CustomAmbientEnabled = v
                updateLightingState()
            end,
            LayoutOrder = nextWLeft()
        })

        Controls:CreateToggle(WLeft, {
            Name = "Custom lighting",
            Default = false,
            SettingsIcon = true,
            SettingsIconText = "6",
            SettingsIconFont = GuiIconsFont,
            SettingsIconSize = 13,
            OnSettingsClick = function(btn)
                Controls:OpenLightingPopover(btn, MemeSenseCamera.CustomLightingR, MemeSenseCamera.CustomLightingG, MemeSenseCamera.CustomLightingB, function(r, g, b)
                    MemeSenseCamera.CustomLightingR = r
                    MemeSenseCamera.CustomLightingG = g
                    MemeSenseCamera.CustomLightingB = b
                    updateLightingState()
                end)
            end,
            Callback = function(v)
                MemeSenseCamera.CustomLightingEnabled = v
                updateLightingState()
            end,
            LayoutOrder = nextWLeft()
        })

        Controls:CreateSlider(WLeft, {
            Name = "Exposure",
            Min = 0.000,
            Max = 2.000,
            Default = 1.000,
            Decimals = 3,
            LayoutOrder = nextWLeft(),
            Callback = function(v)
                setExposure(v)
            end
        })

        Controls:CreateSectionHeader(WLeft, "Extra", nextWLeft())

        Controls:CreateToggle(WLeft, {
            Name = "Force sniper crosshair",
            Default = false,
            LayoutOrder = nextWLeft(),
            Callback = function(v)
                setForceSniperCrosshair(v)
            end
        })

        Controls:CreateToggle(WLeft, {
            Name = "Penetration crosshair",
            Default = false,
            SettingsIcon = true,
            SettingsIconText = "6",
            SettingsIconFont = GuiIconsFont,
            SettingsIconSize = 13,
            LayoutOrder = nextWLeft()
        })

        Controls:CreateSlider(WLeft, {
            Name = "Flash scale",
            Min = 0.00,
            Max = 1.00,
            Default = 1.00,
            Decimals = 2,
            LayoutOrder = nextWLeft(),
            Callback = function(v)
                setFlashScale(v)
            end
        })

        Controls:CreateSectionHeader(WRight, "Removals", nextWRight())

        local toggleZoomSpread
        local toggleZoomHud

        toggleZoomHud = Controls:CreateToggle(WRight, {
            Name = "Zoom hud",
            Default = false,
            LayoutOrder = nextWRight(),
            Callback = function(v)
                MemeSenseCamera.ZoomHud = v
                if toggleZoomSpread then
                    if v then
                        toggleZoomSpread.Set(false)
                        toggleZoomSpread.SetEnabled(false)
                    else
                        toggleZoomSpread.SetEnabled(true)
                    end
                end
                if not v then
                    if ScopeOverlay then
                        ScopeOverlay.Visible = false
                    end
                    pcall(function()
                        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
                        local mg = pGui and pGui:FindFirstChild("MainGui")
                        local mid = mg and (mg:FindFirstChild("Middle") or (mg:FindFirstChild("Gameplay") and mg.Gameplay:FindFirstChild("Middle")))
                        local ss = mid and mid:FindFirstChild("SniperScope")
                        if ss then
                            local ssStroke = ss:FindFirstChildOfClass("UIStroke")
                            if ssStroke then ssStroke.Enabled = true end
                            for _, child in ipairs(ss:GetChildren()) do
                                if child.Name == "MemeSenseCustomScopeCrosshair" then
                                    child:Destroy()
                                elseif child:IsA("GuiObject") and not child:IsA("UIAspectRatioConstraint") then
                                    child.Visible = true
                                elseif child:IsA("UIStroke") then
                                    child.Enabled = true
                                end
                            end
                        end
                    end)
                elseif hookedScopeInstance then
                    setupScopeHook(hookedScopeInstance)
                    updateScopeVisuals(hookedScopeInstance, hookedScopeInstance.Visible)
                end
            end
        })

        toggleZoomSpread = Controls:CreateToggle(WRight, {
            Name = "Zoom spread",
            Default = false,
            LayoutOrder = nextWRight(),
            Callback = function(v)
                MemeSenseCamera.ZoomSpread = v
                if not v then
                    pcall(function()
                        if hookedScopeInstance then
                            local blur = hookedScopeInstance:FindFirstChild("Blur")
                            local sharp = hookedScopeInstance:FindFirstChild("Sharp")
                            if blur then
                                blur.Visible = true
                                if blur:IsA("ImageLabel") or blur:IsA("ImageButton") then
                                    blur.ImageTransparency = 0
                                end
                            end
                            if sharp then
                                sharp.Visible = true
                            end
                        end
                    end)
                elseif hookedScopeInstance then
                    setupScopeHook(hookedScopeInstance)
                    enforceZoomSpread(hookedScopeInstance)
                end
            end
        })

        Controls:CreateToggle(WRight, {
            Name = "Visual recoil",
            Default = false,
            LayoutOrder = nextWRight(),
            Callback = function(v)
                setVisualRecoilRemoval(v)
            end
        })

        Controls:CreateToggle(WRight, {
            Name = "Spread",
            Default = false,
            LayoutOrder = nextWRight(),
            Callback = function(v)
                setSpreadRemoval(v)
            end
        })

        Controls:CreateToggle(WRight, {
            Name = "Smoke grenades",
            Default = false,
            LayoutOrder = nextWRight(),
            Callback = function(v)
                setSmokeRemoval(v)
            end
        })
    end
    run()
    pcall(function()
        setFlashScale(MemeSenseCamera.FlashScale or 1.00)
    end)
end

do
    local function run()

        local defaultGameFOV = 70
    pcall(function()
        local const = ReplicatedStorage:FindFirstChild("Database")
            and ReplicatedStorage.Database:FindFirstChild("Custom")
            and ReplicatedStorage.Database.Custom:FindFirstChild("Constants")
        if const then
            local c = require(const)
            if c and c.DEFAULT_CAMERA_FOV then
                defaultGameFOV = c.DEFAULT_CAMERA_FOV
            end
        end
    end)
    pcall(function()
        local cam = workspace.CurrentCamera
        if cam and cam.FieldOfView and cam.FieldOfView >= 40 and cam.FieldOfView <= 120 then
            defaultGameFOV = math.round(cam.FieldOfView)
        end
    end)

    -- MemeSenseViewmodel is declared at file scope

    local cachedCameraController = nil
    local function getCameraController()
        if not cachedCameraController then
            pcall(function()
                local controllers = ReplicatedStorage:FindFirstChild("Controllers")
                local cc = controllers and controllers:FindFirstChild("CameraController")
                if cc then
                    cachedCameraController = require(cc)
                end
            end)
        end
        return cachedCameraController
    end

    local ViewmodelClass = nil
    local originalRender = nil
    local BobbleClass = nil
    local originalBobbleGetNext = nil
    local originalBobbleScopeKick = nil
    local currentBobbleCF = CFrame.identity
    local ViewmodelHooked = false

    local function findActiveViewmodelModel()
        local cam = workspace.CurrentCamera
        if not cam then return nil end
        for _, v in ipairs(cam:GetChildren()) do
            if v:IsA("Model") and v:FindFirstChild("Stats") then
                return v
            end
        end
        for _, v in ipairs(cam:GetDescendants()) do
            if v:IsA("Model") and v:FindFirstChild("Stats") then
                return v
            end
        end
        return nil
    end

    local cachedDataController = nil
    local function getGameViewmodelOffset(player)
        if not cachedDataController then
            pcall(function()
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local controllers = ReplicatedStorage:FindFirstChild("Controllers")
                    local dc = controllers and controllers:FindFirstChild("DataController")
                    if dc then
                        cachedDataController = require(dc)
                    end
                end
            end)
        end
        if cachedDataController and type(cachedDataController.Get) == "function" then
            local ok, v1 = pcall(cachedDataController.Get, player or Players.LocalPlayer, "Settings.Game.Viewmodel")
            if ok and v1 and type(v1) == "table" then
                return CFrame.new((v1["X Offset"] or 0) / 100, (v1["Y Offset"] or 0) / 100, (v1["Z Offset"] or 0) / 100)
            end
        end
        return CFrame.identity
    end

    local function applyViewmodelTransform(p1)
        if not (p1 and p1.Model and p1.Model:FindFirstChild("Stats")) then
            return
        end

        local cam = workspace.CurrentCamera
        if not cam then return end

        local stats = p1.Model.Stats
        local rotVal = (stats:FindFirstChild("Rotation") and stats.Rotation.Value) or Vector3.zero
        local defVal = (stats:FindFirstChild("Default") and stats.Default.Value) or Vector3.zero

        local gameOffset = getGameViewmodelOffset(p1.Player or Players.LocalPlayer)

        local v3 = CFrame.identity
        if MemeSenseViewmodel.HandShakes then
            if currentBobbleCF and currentBobbleCF ~= CFrame.identity then
                v3 = currentBobbleCF
            elseif p1.Bobble and p1.Bobble.getNextCFrame then
                local ok, b3 = pcall(function() return p1.Bobble:getNextCFrame(0) end)
                if ok and b3 then v3 = b3 end
            end
        end

        local angleCF = CFrame.identity
        if MemeSenseViewmodel.CustomAngles then
            angleCF = CFrame.Angles(
                math.rad(MemeSenseViewmodel.Pitch or 0),
                math.rad(MemeSenseViewmodel.Yaw or 0),
                math.rad(MemeSenseViewmodel.Roll or 0)
            )
        end

        local originOffset = CFrame.identity
        if MemeSenseViewmodel.CustomOrigin then
            local scale = 2.5 / 10
            local posX = (MemeSenseViewmodel.OriginX or 0) * scale
            local posUp = (MemeSenseViewmodel.OriginZ or 0) * scale
            local posDepth = -(MemeSenseViewmodel.OriginY or 0) * scale
            originOffset = CFrame.new(posX, posUp, posDepth)
        end

        local fovOffsetCF = CFrame.identity
        if MemeSenseViewmodel.FieldOfView and MemeSenseViewmodel.FieldOfView > 0 and MemeSenseViewmodel.FieldOfView ~= defaultGameFOV then
            local diff = MemeSenseViewmodel.FieldOfView - defaultGameFOV
            fovOffsetCF = CFrame.new(0, 0, -diff * 0.008)
        end

        local baseRot = CFrame.Angles(rotVal.X, rotVal.Y, rotVal.Z)
        local defPos = CFrame.new(defVal)

        local targetCF = cam.CFrame * fovOffsetCF * v3 * baseRot * defPos * gameOffset * originOffset * angleCF
        p1.Model:PivotTo(targetCF)

        if p1.LargeWeaponModel and p1.SmallWeaponModel then
            p1.LargeWeaponModel:PivotTo(p1.SmallWeaponModel:GetPivot())
        end
    end

    local function hookViewmodel()
        if ViewmodelHooked then return true end

        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            return false
        end
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not pGui or not pGui:FindFirstChild("MainGui") then
            return false
        end

        local ok, res = pcall(function()
            local classes = ReplicatedStorage:FindFirstChild("Classes")
            local wc = classes and classes:FindFirstChild("WeaponComponent")
            local wcc = wc and wc:FindFirstChild("Classes")
            local vm = wcc and wcc:FindFirstChild("Viewmodel")
            if vm then
                return require(vm)
            end
            return nil
        end)
        if ok and res and type(res) == "table" and type(res.render) == "function" then
            ViewmodelClass = res
            if not originalRender then
                originalRender = res.render
            end
            res.render = function(p1, p2)
                if MemeSenseCamera.ThirdPersonEnabled then
                    local vmModel = (p1 and p1.model) or findActiveViewmodelModel()
                    if vmModel then
                        vmModel:PivotTo(CFrame.new(0, -9999, 0))
                    end
                    return
                end
                pcall(originalRender, p1, p2)
                applyViewmodelTransform(p1)
            end
            ViewmodelHooked = true

            pcall(function()
                local classes = ReplicatedStorage:FindFirstChild("Classes")
                local wc = classes and classes:FindFirstChild("WeaponComponent")
                local wcc = wc and wc:FindFirstChild("Classes")
                local vm = wcc and wcc:FindFirstChild("Viewmodel")
                local bClass = vm and vm:FindFirstChild("Classes") and vm.Classes:FindFirstChild("Bobble")
                if bClass then
                    local bMod = require(bClass)
                    if bMod and bMod.getNextCFrame and not originalBobbleGetNext then
                        BobbleClass = bMod
                        originalBobbleGetNext = bMod.getNextCFrame
                        bMod.getNextCFrame = function(self, dt)
                            local cf, v1, v2 = originalBobbleGetNext(self, dt)
                            if not MemeSenseViewmodel.HandShakes then
                                currentBobbleCF = CFrame.identity
                                return CFrame.identity, Vector3.zero, Vector3.zero
                            end
                            currentBobbleCF = cf
                            return cf, v1, v2
                        end
                    end
                    if bMod and bMod.addScopeKick and not originalBobbleScopeKick then
                        originalBobbleScopeKick = bMod.addScopeKick
                        bMod.addScopeKick = function(self)
                            if MemeSenseCamera.VisualRecoilRemoval then
                                return
                            end
                            return originalBobbleScopeKick(self)
                        end
                    end
                end
            end)

            return true
        end
        return false
    end

    local ViewmodelRenderConn = RunService.RenderStepped:Connect(function()
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            return
        end

        if not ViewmodelHooked then
            hookViewmodel()
        end

        if not ViewmodelHooked then
            local cam = workspace.CurrentCamera
            if cam then
                local vm = findActiveViewmodelModel()
                if vm and vm:FindFirstChild("Stats") then
                    if MemeSenseCamera.ThirdPersonEnabled then
                        vm:PivotTo(CFrame.new(0, -9999, 0))
                        return
                    end
                    local stats = vm.Stats
                    local rotVal = (stats:FindFirstChild("Rotation") and stats.Rotation.Value) or Vector3.zero
                    local defVal = (stats:FindFirstChild("Default") and stats.Default.Value) or Vector3.zero

                    local gameOffset = getGameViewmodelOffset(Players.LocalPlayer)

                    local angleCF = CFrame.identity
                    if MemeSenseViewmodel.CustomAngles then
                        angleCF = CFrame.Angles(
                            math.rad(MemeSenseViewmodel.Pitch or 0),
                            math.rad(MemeSenseViewmodel.Yaw or 0),
                            math.rad(MemeSenseViewmodel.Roll or 0)
                        )
                    end

                    local originOffset = CFrame.identity
                    if MemeSenseViewmodel.CustomOrigin then
                        local scale = 2.5 / 10
                        local posX = (MemeSenseViewmodel.OriginX or 0) * scale
                        local posUp = (MemeSenseViewmodel.OriginZ or 0) * scale
                        local posDepth = -(MemeSenseViewmodel.OriginY or 0) * scale
                        originOffset = CFrame.new(posX, posUp, posDepth)
                    end

                    local fovOffsetCF = CFrame.identity
                    if MemeSenseViewmodel.FieldOfView and MemeSenseViewmodel.FieldOfView > 0 and MemeSenseViewmodel.FieldOfView ~= defaultGameFOV then
                        local diff = MemeSenseViewmodel.FieldOfView - defaultGameFOV
                        fovOffsetCF = CFrame.new(0, 0, -diff * 0.008)
                    end

                    local baseRot = CFrame.Angles(rotVal.X, rotVal.Y, rotVal.Z)
                    local defPos = CFrame.new(defVal)
                    local targetCF = cam.CFrame * fovOffsetCF * baseRot * defPos * gameOffset * originOffset * angleCF
                    vm:PivotTo(targetCF)

                    for _, child in ipairs(cam:GetChildren()) do
                        if child:IsA("Model") and child ~= vm and (child.Name:find("Weapon") or child.Name:find("Pistol") or child.Name:find("Rifle") or child.Name:find("Knife")) then
                            local small = vm:FindFirstChild(child.Name) or vm:FindFirstChild("Weapon")
                            if small and small:IsA("Model") then
                                child:PivotTo(small:GetPivot())
                            end
                        end
                    end
                end
            end
        end
    end)
    table.insert(Connections, ViewmodelRenderConn)

    local function getBloxStrikeSensSettings()
        local mouseSens = 1
        local zoomSens = 0.5
        pcall(function()
            local controllers = ReplicatedStorage:FindFirstChild("Controllers")
            local dc = controllers and controllers:FindFirstChild("DataController")
            if dc then
                local dataMod = require(dc)
                if dataMod and type(dataMod.Get) == "function" then
                    local ms = dataMod.Get(LocalPlayer, "Settings.Keyboard/Mouse.Keyboard & Mouse Settings.Mouse Sensitivity")
                    if type(ms) == "number" then
                        mouseSens = math.clamp(ms, 0.1, 10)
                    end
                    local zs = dataMod.Get(LocalPlayer, "Settings.Keyboard/Mouse.Keyboard & Mouse Settings.Zoom Sensitivity Multiplier")
                    if type(zs) == "number" then
                        zoomSens = math.clamp(zs, 0.1, 5)
                    end
                end
            end
        end)
        return mouseSens, zoomSens
    end

    local wasThirdPerson = false
    local wasFOVModified = false

    RunService:BindToRenderStep("MemeSense_ThirdPerson", Enum.RenderPriority.Camera.Value + 2, function()
        local cam = workspace.CurrentCamera
        if not cam then return end

        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and (char:FindFirstChild("Head") or root)

        local isFOVLocked = false
        local cc = getCameraController()
        if cc and type(cc.isFOVLocked) == "function" then
            pcall(function() isFOVLocked = cc.isFOVLocked() end)
        end
        if MemeSenseCamera.VisualRecoilRemoval and cc and type(cc.resetWeaponRecoil) == "function" then
            pcall(cc.resetWeaponRecoil)
        end

        local ss = nil
        local ssVisible = false
        pcall(function()
            local pGui = LocalPlayer:FindFirstChild("PlayerGui")
            local mg = pGui and pGui:FindFirstChild("MainGui")
            local mid = mg and (mg:FindFirstChild("Middle") or (mg:FindFirstChild("Gameplay") and mg.Gameplay:FindFirstChild("Middle")))
            ss = mid and mid:FindFirstChild("SniperScope")
            if ss and ss.Visible then
                ssVisible = true
            end
        end)

        if not isFOVLocked then
            local scopeIncrement = LocalPlayer:GetAttribute("ScopeIncrement") or 0
            local hasSniperScope = ssVisible

            local isSniperScopedAttr = LocalPlayer:GetAttribute("IsSniperScoped")
            local isAimingAttr = LocalPlayer:GetAttribute("IsAiming")
            if isSniperScopedAttr == false and isAimingAttr == false and not ssVisible then
                scopeIncrement = 0
            end
            if ssVisible and scopeIncrement == 0 then
                scopeIncrement = 1
                hasSniperScope = true
            end

            local targetFOV = nil
            local isScoped = (scopeIncrement >= 1)

            if scopeIncrement >= 2 then

                if MemeSenseCamera.ZoomFieldOfView2 and MemeSenseCamera.ZoomFieldOfView2 > 0 then
                    targetFOV = MemeSenseCamera.ZoomFieldOfView2
                end
            elseif scopeIncrement == 1 then

                if MemeSenseCamera.ZoomFieldOfView1 and MemeSenseCamera.ZoomFieldOfView1 > 0 then
                    targetFOV = MemeSenseCamera.ZoomFieldOfView1
                end
            else

                if MemeSenseCamera.FieldOfView and MemeSenseCamera.FieldOfView > 0 and MemeSenseCamera.FieldOfView ~= defaultGameFOV then
                    targetFOV = MemeSenseCamera.FieldOfView
                end
            end

            if targetFOV then
                wasFOVModified = true
                cam.FieldOfView = targetFOV
                local mouseSens, zoomSens = getBloxStrikeSensSettings()
                local targetSens = (targetFOV / 70) * mouseSens * (isScoped and zoomSens or 1)
                UserInputService.MouseDeltaSensitivity = targetSens
            elseif wasFOVModified then
                wasFOVModified = false
                local mouseSens, zoomSens = getBloxStrikeSensSettings()
                local nativeFOV = 70
                if scopeIncrement >= 2 then
                    nativeFOV = 10
                elseif scopeIncrement == 1 then
                    nativeFOV = hasSniperScope and 33 or 55
                end
                cam.FieldOfView = nativeFOV
                local targetSens = (nativeFOV / 70) * mouseSens * (isScoped and zoomSens or 1)
                UserInputService.MouseDeltaSensitivity = targetSens
            end
        end

        if ScopeScreenGui and (not ScopeScreenGui.Parent or not ScopeScreenGui.Parent.Parent) then
            pcall(function()
                ScopeScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
            end)
        end
        if ss then
            setupScopeHook(ss)
            updateScopeVisuals(ss, ssVisible)
        else
            if ScopeOverlay and ScopeOverlay.Visible then
                ScopeOverlay.Visible = false
            end
        end

        if MemeSenseCamera.ThirdPersonEnabled and char and head then
            wasThirdPerson = true

            if LocalPlayer.CameraMode ~= Enum.CameraMode.Classic then
                LocalPlayer.CameraMode = Enum.CameraMode.Classic
            end

            local hOffset = MemeSenseCamera.ThirdPersonHeight or -0.6
            local sOffset = MemeSenseCamera.ThirdPersonSide or 0.0
            local origin = head.Position + Vector3.new(0, hOffset, 0) + (cam.CFrame.RightVector * sOffset)
            local lookDir = cam.CFrame.LookVector
            local camRotation = cam.CFrame.Rotation

            local rawDist = MemeSenseCamera.ThirdPersonDistance or 100
            local desiredDist = math.clamp(rawDist * 0.1, 2, 25)

            local debris = workspace:FindFirstChild("Debris")
            local excludeList = {char, cam}
            if debris then
                table.insert(excludeList, debris)
            end

            local rayParams = RaycastParams.new()
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            rayParams.FilterDescendantsInstances = excludeList
            rayParams.IgnoreWater = true

            local hit = workspace:Raycast(origin, -lookDir * desiredDist, rayParams)
            local actualDist = hit and math.max(1, (hit.Position - origin).Magnitude - 0.5) or desiredDist

            cam.CFrame = CFrame.new(origin - (lookDir * actualDist)) * camRotation

            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.LocalTransparencyModifier = 0
                end
            end

            if debris then
                local pWeapon = debris:FindFirstChild(LocalPlayer.Name .. "_Weapon")
                if pWeapon then
                    for _, part in ipairs(pWeapon:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.LocalTransparencyModifier = 0
                            part.Transparency = 0
                        end
                    end
                end
                local pAtt = debris:FindFirstChild(LocalPlayer.Name .. "_WeaponAttachments")
                if pAtt then
                    for _, part in ipairs(pAtt:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.LocalTransparencyModifier = 0
                            part.Transparency = 0
                        end
                    end
                end
            end
        elseif wasThirdPerson then
            wasThirdPerson = false
            LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
            LocalPlayer.CameraMinZoomDistance = 0
            LocalPlayer.CameraMaxZoomDistance = 0
            cam.CameraType = Enum.CameraType.Custom
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and part.Name ~= "CameraPart" then
                        part.LocalTransparencyModifier = 1
                    end
                end
            end
        end
    end)
    table.insert(Connections, {
        Disconnect = function()
            pcall(function() RunService:UnbindFromRenderStep("MemeSense_ThirdPerson") end)
        end
    })

    table.insert(Connections, {
        Disconnect = function()
            pcall(function() RunService:UnbindFromRenderStep("MemeSense_ThirdPerson") end)
            if ViewmodelClass and originalRender then
                ViewmodelClass.render = originalRender
            end
            if BobbleClass and originalBobbleGetNext then
                BobbleClass.getNextCFrame = originalBobbleGetNext
            end
            if BobbleClass and originalBobbleScopeKick then
                BobbleClass.addScopeKick = originalBobbleScopeKick
            end
            pcall(function()
                local cc = getCameraController()
                if cc and cc.setPerspective then
                    cc.setPerspective(true, false)
                end
                LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
                LocalPlayer.CameraMinZoomDistance = 0
                LocalPlayer.CameraMaxZoomDistance = 0
                local cam = workspace.CurrentCamera
                if cam and cam.CameraType ~= Enum.CameraType.Custom then
                    cam.CameraType = Enum.CameraType.Custom
                end
                local char = LocalPlayer.Character
                if char then
                    for _, part in ipairs(char:GetChildren()) do
                        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and part.Name ~= "CameraPart" then
                            part.LocalTransparencyModifier = 1
                        elseif part:IsA("Accessory") then
                            local h = part:FindFirstChild("Handle")
                            if h and h:IsA("BasePart") then
                                h.LocalTransparencyModifier = 1
                            end
                        end
                    end
                end
            end)
        end
    })

    local ViewTab = Tabs["View"]
    local VWLeft = ViewTab.LeftColumn
        local VWRight = ViewTab.RightColumn

        local vwLeftOrder = 0
        local function nextVWLeft()
            vwLeftOrder += 1
            return vwLeftOrder
        end

        local vwRightOrder = 0
        local function nextVWRight()
            vwRightOrder += 1
            return vwRightOrder
        end

        Controls:CreateSectionHeader(VWLeft, "View model", nextVWLeft())

        Controls:CreateToggle(VWLeft, {
            Name = "Hand shakes",
            Default = true,
            LayoutOrder = nextVWLeft(),
            Callback = function(v)
                MemeSenseViewmodel.HandShakes = v
            end
        })

        Controls:CreateSlider(VWLeft, {
            Name = "Field of view",
            Min = 0,
            Max = 120,
            Default = 0,
            ZeroText = "auto",
            Suffix = "°",
            LayoutOrder = nextVWLeft(),
            Callback = function(v)
                MemeSenseViewmodel.FieldOfView = v
            end
        })

        local sliderOriginX, sliderOriginY, sliderOriginZ
        local function updateOriginSliders(enabled)
            if sliderOriginX then sliderOriginX.SetEnabled(enabled) end
            if sliderOriginY then sliderOriginY.SetEnabled(enabled) end
            if sliderOriginZ then sliderOriginZ.SetEnabled(enabled) end
        end

        Controls:CreateToggle(VWLeft, {
            Name = "Custom origin",
            Default = false,
            LayoutOrder = nextVWLeft(),
            Callback = function(v)
                MemeSenseViewmodel.CustomOrigin = v
                updateOriginSliders(v)
            end
        })

        sliderOriginX = Controls:CreateSlider(VWLeft, {
            Name = "X",
            Min = -10,
            Max = 10,
            Default = 0,
            Decimals = 3,
            Enabled = false,
            LayoutOrder = nextVWLeft(),
            Callback = function(v)
                MemeSenseViewmodel.OriginX = v
            end
        })

        sliderOriginY = Controls:CreateSlider(VWLeft, {
            Name = "Y",
            Min = -10,
            Max = 10,
            Default = 0,
            Decimals = 3,
            Enabled = false,
            LayoutOrder = nextVWLeft(),
            Callback = function(v)
                MemeSenseViewmodel.OriginY = v
            end
        })

        sliderOriginZ = Controls:CreateSlider(VWLeft, {
            Name = "Z",
            Min = -10,
            Max = 10,
            Default = 0,
            Decimals = 3,
            Enabled = false,
            LayoutOrder = nextVWLeft(),
            Callback = function(v)
                MemeSenseViewmodel.OriginZ = v
            end
        })

        local sliderPitch, sliderYaw, sliderRoll
        local function updateAngleSliders(enabled)
            if sliderPitch then sliderPitch.SetEnabled(enabled) end
            if sliderYaw then sliderYaw.SetEnabled(enabled) end
            if sliderRoll then sliderRoll.SetEnabled(enabled) end
        end

        Controls:CreateToggle(VWLeft, {
            Name = "Custom angles",
            Default = false,
            LayoutOrder = nextVWLeft(),
            Callback = function(v)
                MemeSenseViewmodel.CustomAngles = v
                updateAngleSliders(v)
            end
        })

        sliderPitch = Controls:CreateSlider(VWLeft, {
            Name = "Pitch",
            Min = -90,
            Max = 90,
            Default = 0,
            Decimals = 3,
            Suffix = "°",
            Enabled = false,
            LayoutOrder = nextVWLeft(),
            Callback = function(v)
                MemeSenseViewmodel.Pitch = v
            end
        })

        sliderYaw = Controls:CreateSlider(VWLeft, {
            Name = "Yaw",
            Min = -180,
            Max = 180,
            Default = 0,
            Decimals = 3,
            Suffix = "°",
            Enabled = false,
            LayoutOrder = nextVWLeft(),
            Callback = function(v)
                MemeSenseViewmodel.Yaw = v
            end
        })

        sliderRoll = Controls:CreateSlider(VWLeft, {
            Name = "Roll",
            Min = -180,
            Max = 180,
            Default = 0,
            Decimals = 3,
            Suffix = "°",
            Enabled = false,
            LayoutOrder = nextVWLeft(),
            Callback = function(v)
                MemeSenseViewmodel.Roll = v
            end
        })

        Controls:CreateSectionHeader(VWRight, "Camera", nextVWRight())

        Controls:CreateSlider(VWRight, {
            Name = "Field of view",
            Min = 0,
            Max = 120,
            Default = 0,
            ZeroText = "auto",
            Suffix = "°",
            LayoutOrder = nextVWRight(),
            Callback = function(v)
                MemeSenseCamera.FieldOfView = v
            end
        })

        Controls:CreateSlider(VWRight, {
            Name = "Zoom field of view 1",
            Min = 0,
            Max = 120,
            Default = 0,
            ZeroText = "auto",
            Suffix = "°",
            LayoutOrder = nextVWRight(),
            Callback = function(v)
                MemeSenseCamera.ZoomFieldOfView1 = v
            end
        })

        Controls:CreateSlider(VWRight, {
            Name = "Zoom field of view 2",
            Min = 0,
            Max = 120,
            Default = 0,
            ZeroText = "auto",
            Suffix = "°",
            LayoutOrder = nextVWRight(),
            Callback = function(v)
                MemeSenseCamera.ZoomFieldOfView2 = v
            end
        })

        Controls:CreateSectionHeader(VWRight, "Third-person", nextVWRight())

        local sliderMaxDistance
        local function updateThirdpersonSliders(enabled)
            if sliderMaxDistance then sliderMaxDistance.SetEnabled(enabled) end
        end

        Controls:CreateToggle(VWRight, {
            Name = "Enable",
            Default = false,
            Keybind = { Key = nil, Type = "Always On" },
            LayoutOrder = nextVWRight(),
            Callback = function(v)
                MemeSenseCamera.ThirdPersonEnabled = v
                updateThirdpersonSliders(v)
                if not v then
                    pcall(function()
                        LocalPlayer.CameraMinZoomDistance = 0
                        LocalPlayer.CameraMaxZoomDistance = 0
                        LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
                        local cam = workspace.CurrentCamera
                        if cam and cam.CameraType ~= Enum.CameraType.Custom then
                            cam.CameraType = Enum.CameraType.Custom
                        end
                        local char = LocalPlayer.Character
                        if char then
                            for _, part in ipairs(char:GetDescendants()) do
                                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and part.Name ~= "CameraPart" then
                                    part.LocalTransparencyModifier = 1
                                end
                            end
                        end
                    end)
                end
            end
        })

        sliderMaxDistance = Controls:CreateSlider(VWRight, {
            Name = "Max distance",
            Min = 10,
            Max = 150,
            Default = 100,
            Suffix = "s",
            Enabled = false,
            LayoutOrder = nextVWRight(),
            Callback = function(v)
                MemeSenseCamera.ThirdPersonDistance = v
            end
        })
    end
    run()
end

do
    local function run()
        local IndicatorsTab = Tabs["Indicators"]
        local IndLeft = IndicatorsTab.LeftColumn
        local IndRight = IndicatorsTab.RightColumn

        IndLeft.Position = UDim2.new(0, 14, 0, 52)
        IndLeft.Size = UDim2.new(0.5, -12, 1, -56)
        IndRight.Position = UDim2.new(0.5, 4, 0, 52)
        IndRight.Size = UDim2.new(0.5, -12, 1, -56)

        local TopHeader = Instance.new("Frame")
        TopHeader.Name = "IndicatorsTopHeader"
        TopHeader.Size = UDim2.new(1, -28, 0, 42)
        TopHeader.Position = UDim2.new(0, 14, 0, 4)
        TopHeader.BackgroundTransparency = 1
        TopHeader.Parent = IndicatorsTab.Content

        local MasterFrame = Instance.new("Frame")
        MasterFrame.Name = "MasterSwitchFrame"
        MasterFrame.Size = UDim2.new(0, 130, 0, 24)
        MasterFrame.Position = UDim2.new(0, 0, 0, 9)
        MasterFrame.BackgroundTransparency = 1
        MasterFrame.Parent = TopHeader

        local masterBox = Instance.new("TextButton")
        masterBox.Name = "Checkbox"
        masterBox.Size = UDim2.new(0, 16, 0, 16)
        masterBox.Position = UDim2.new(0, 0, 0.5, -8)
        masterBox.BackgroundColor3 = (tabMasterStates["Indicators"] ~= false) and Theme.CheckboxChecked or Theme.CheckboxOff
        masterBox.BorderSizePixel = 0
        masterBox.AutoButtonColor = false
        masterBox.Text = ""
        masterBox.Parent = MasterFrame
        createCorner(masterBox, 3)

        local masterLabel = Instance.new("TextLabel")
        masterLabel.Name = "Label"
        masterLabel.Size = UDim2.new(1, -24, 1, 0)
        masterLabel.Position = UDim2.new(0, 24, 0, 0)
        masterLabel.BackgroundTransparency = 1
        masterLabel.Text = "Master switch"
        masterLabel.TextColor3 = (tabMasterStates["Indicators"] ~= false) and Color3.fromRGB(255, 255, 255) or Theme.TextDim
        masterLabel.TextSize = 12
        masterLabel.Font = Theme.FontBold
        masterLabel.TextXAlignment = Enum.TextXAlignment.Left
        masterLabel.Parent = MasterFrame

        local function toggleMaster()
            local newState = not (tabMasterStates["Indicators"] ~= false)
            tabMasterStates["Indicators"] = newState
            masterBox.BackgroundColor3 = newState and Theme.CheckboxChecked or Theme.CheckboxOff
            masterLabel.TextColor3 = newState and Color3.fromRGB(255, 255, 255) or Theme.TextDim
        end

        local masterTrigger = Instance.new("TextButton")
        masterTrigger.Name = "Trigger"
        masterTrigger.Size = UDim2.new(1, 0, 1, 0)
        masterTrigger.BackgroundTransparency = 1
        masterTrigger.Text = ""
        masterTrigger.Parent = MasterFrame
        masterTrigger.MouseButton1Click:Connect(toggleMaster)
        masterBox.MouseButton1Click:Connect(toggleMaster)

        local SaveBtn = Instance.new("TextButton")
        SaveBtn.Name = "SaveButton"
        SaveBtn.Size = UDim2.new(0, 72, 0, 24)
        SaveBtn.Position = UDim2.new(1, -72, 0, 9)
        SaveBtn.BackgroundColor3 = Theme.DropdownBg
        SaveBtn.BorderSizePixel = 0
        SaveBtn.AutoButtonColor = false
        SaveBtn.Text = ""
        SaveBtn.Parent = TopHeader
        createCorner(SaveBtn, 3)

        local SaveIcon = Instance.new("ImageLabel")
        SaveIcon.Name = "Icon"
        SaveIcon.Size = UDim2.new(0, 14, 0, 14)
        SaveIcon.Position = UDim2.new(0, 9, 0.5, -7)
        SaveIcon.BackgroundTransparency = 1
        SaveIcon.Image = "rbxassetid://6031075931"
        SaveIcon.ImageColor3 = Theme.TextActive
        SaveIcon.Parent = SaveBtn

        local SaveLabel = Instance.new("TextLabel")
        SaveLabel.Name = "Label"
        SaveLabel.Size = UDim2.new(1, -28, 1, 0)
        SaveLabel.Position = UDim2.new(0, 27, 0, 0)
        SaveLabel.BackgroundTransparency = 1
        SaveLabel.Text = "Save"
        SaveLabel.TextColor3 = Theme.TextActive
        SaveLabel.TextSize = 12
        SaveLabel.Font = Theme.FontBold
        SaveLabel.TextXAlignment = Enum.TextXAlignment.Left
        SaveLabel.Parent = SaveBtn

        SaveBtn.MouseEnter:Connect(function()
            SaveBtn.BackgroundColor3 = Color3.fromRGB(95, 102, 112)
        end)
        SaveBtn.MouseLeave:Connect(function()
            SaveBtn.BackgroundColor3 = Theme.DropdownBg
        end)

        local Divider = Instance.new("Frame")
        Divider.Name = "TopDivider"
        Divider.Size = UDim2.new(1, -28, 0, 1)
        Divider.Position = UDim2.new(0, 14, 0, 44)
        Divider.BackgroundColor3 = Color3.fromRGB(28, 29, 35)
        Divider.BorderSizePixel = 0
        Divider.Parent = IndicatorsTab.Content

        local indLeftOrder = 0
        local function nextIndLeft()
            indLeftOrder += 1
            return indLeftOrder
        end

        local indRightOrder = 0
        local function nextIndRight()
            indRightOrder += 1
            return indRightOrder
        end

        Controls:CreateSectionHeader(IndLeft, "General", nextIndLeft())

        Controls:CreateToggle(IndLeft, {
            Name = "Shadow text",
            Default = false,
            LayoutOrder = nextIndLeft()
        })

        Controls:CreateToggle(IndLeft, {
            Name = "Centered text",
            Default = false,
            LayoutOrder = nextIndLeft()
        })

        Controls:CreateToggle(IndLeft, {
            Name = "Show only if enabled",
            Default = false,
            LayoutOrder = nextIndLeft()
        })

        Controls:CreateToggle(IndLeft, {
            Name = "Hide when chat opened",
            Default = true,
            LayoutOrder = nextIndLeft()
        })

        Controls:CreateSlider(IndLeft, {
            Name = "Font size",
            Min = 8,
            Max = 32,
            Default = 14,
            Suffix = " px",
            LayoutOrder = nextIndLeft()
        })

        Controls:CreateSlider(IndLeft, {
            Name = "Text offset",
            Min = 0,
            Max = 50,
            Default = 10,
            Suffix = " px",
            LayoutOrder = nextIndLeft()
        })

        Controls:CreateSectionHeader(IndRight, "Position", nextIndRight())

        Controls:CreateDropdown(IndRight, {
            Name = "Align at",
            Options = { "Left", "Center", "Right" },
            Default = "Left",
            LayoutOrder = nextIndRight()
        })

        Controls:CreateSlider(IndRight, {
            Name = "X",
            Min = 0,
            Max = 1920,
            Default = 12,
            Suffix = " px",
            LayoutOrder = nextIndRight()
        })

        Controls:CreateSlider(IndRight, {
            Name = "Y",
            Min = 0,
            Max = 1080,
            Default = 681,
            Suffix = " px",
            LayoutOrder = nextIndRight()
        })
    end
    run()
end

local MemeSenseMisc = {
    Bhop = false,
    InGameRadar = false,
    PreserveKillfeed = false,
    GlitchSpectators = false,
}

local MiscHooks = {}
local cleanupMiscHooks = function()
    if MiscHooks.cleanupMiscHooks then
        MiscHooks.cleanupMiscHooks()
    end
end

local MemeSenseSounds = {
    HitEnabled = false,
    KillEnabled = false,
    SelectedHit = "Default",
    SelectedKill = "Default",
    HitVolume = 1.000,
    KillVolume = 1.000,
    SetupListeners = nil,
    Cleanup = nil,
}

;(function()
    local charController = nil

    local function getCharController()
        if charController then return charController end
        pcall(function()
            local controllers = ReplicatedStorage:FindFirstChild("Controllers")
            local cc = controllers and controllers:FindFirstChild("CharacterController")
            if cc then
                if cc:IsA("ModuleScript") then
                    charController = require(cc)
                elseif cc:FindFirstChild("init") and cc.init:IsA("ModuleScript") then
                    charController = require(cc.init)
                elseif cc:FindFirstChild("LocalCharacter") and cc.LocalCharacter:IsA("ModuleScript") then
                    charController = require(cc.LocalCharacter)
                end
            end
        end)
        return charController
    end

    local function getCharacterObject()
        local curr = nil
        pcall(function()
            local router = require(ReplicatedStorage.Database.Security.Router)
            if router and type(router.broadcastRouter) == "function" then
                curr = router.broadcastRouter("GetCurrentCharacter")
            end
        end)
        if not curr then
            local cc = getCharController()
            if cc and type(cc.getCurrentCharacter) == "function" then
                pcall(function() curr = cc.getCurrentCharacter() end)
            end
        end
        return curr
    end

    local function stepBhop()
        if not MemeSenseMisc.Bhop then return end

        pcall(function()
            if LocalPlayer:GetAttribute("_BhopArena") ~= nil then
                LocalPlayer:SetAttribute("_BhopArena", nil)
            end
            if LocalPlayer:GetAttribute("_SurfArena") ~= nil then
                LocalPlayer:SetAttribute("_SurfArena", nil)
            end
        end)

        if not UserInputService:IsKeyDown(Enum.KeyCode.Space) then return end
        if UserInputService:GetFocusedTextBox() then return end

        local char = LocalPlayer.Character
        if not char or not char:IsDescendantOf(workspace) then return end
        if char:GetAttribute("Dead") == true or LocalPlayer:GetAttribute("Dead") == true then return end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local curr = getCharacterObject()
        if curr then
            if curr.Stamina and curr.Stamina < 60 then curr.Stamina = 60 end
            if curr.MovementState and curr.MovementState.Stamina and curr.MovementState.Stamina < 60 then
                curr.MovementState.Stamina = 60
            end
        end

        local isGrounded = (hum.FloorMaterial ~= Enum.Material.Air)
        if not isGrounded and curr then
            if curr.OnGround == true or (curr.MovementState and curr.MovementState.OnGround == true) then
                isGrounded = true
            end
        end
        if not isGrounded then
            local velY = hrp.AssemblyLinearVelocity.Y
            if velY <= 1.5 then
                local rayParams = RaycastParams.new()
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                rayParams.FilterDescendantsInstances = { char, workspace.CurrentCamera }
                local hit = workspace:Raycast(hrp.Position, Vector3.new(0, -3.2, 0), rayParams)
                if hit then
                    isGrounded = true
                end
            end
        end

        if isGrounded then
            local now = os.clock()
            if now - (hrp:GetAttribute("LastBhopTick") or 0) > 0.05 then
                hrp:SetAttribute("LastBhopTick", now)
                hum.Jump = true
                pcall(function()
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end)
                local curVel = hrp.AssemblyLinearVelocity
                hrp.AssemblyLinearVelocity = Vector3.new(curVel.X, math.max(curVel.Y, 48), curVel.Z)
                if curr then
                    curr.JumpPulsePending = true
                    curr.JumpInputDown = true
                    if curr.MovementState then
                        curr.MovementState.JumpPulsePending = true
                    end
                    task.delay(0.03, function()
                        if curr then curr.JumpInputDown = false end
                    end)
                end
            end
        end
    end

    MiscHooks.setupBhop = function()
        if MiscHooks.bhopBound then return end
        MiscHooks.bhopBound = true

        pcall(function()
            RunService:BindToRenderStep("MemeSense_Bhop", Enum.RenderPriority.Camera.Value - 3, stepBhop)
        end)
        local hbConn = RunService.Heartbeat:Connect(stepBhop)
        table.insert(Connections, hbConn)

        pcall(function()
            LocalPlayer:SetAttribute("_BhopArena", nil)
            LocalPlayer:SetAttribute("_SurfArena", nil)
            table.insert(Connections, LocalPlayer:GetAttributeChangedSignal("_BhopArena"):Connect(function()
                if LocalPlayer:GetAttribute("_BhopArena") ~= nil then
                    LocalPlayer:SetAttribute("_BhopArena", nil)
                end
            end))
            table.insert(Connections, LocalPlayer:GetAttributeChangedSignal("_SurfArena"):Connect(function()
                if LocalPlayer:GetAttribute("_SurfArena") ~= nil then
                    LocalPlayer:SetAttribute("_SurfArena", nil)
                end
            end))
        end)

        table.insert(Connections, {
            Disconnect = function()
                pcall(function() RunService:UnbindFromRenderStep("MemeSense_Bhop") end)
                if hbConn then hbConn:Disconnect() end
                MiscHooks.bhopBound = false
            end
        })
    end

    -- Automatically set up Bhop handler
    MiscHooks.setupBhop()
end)()

;(function()
    local origRadarRender = nil
    local radarModuleInstance = nil

    MiscHooks.hookInGameRadar = function()
        if origRadarRender then return end
        pcall(function()
            local screens = ReplicatedStorage:FindFirstChild("Interface") and ReplicatedStorage.Interface:FindFirstChild("Screens")
            local gameplay = screens and screens:FindFirstChild("Gameplay")
            local middle = gameplay and gameplay:FindFirstChild("Middle")
            local radarMod = middle and middle:FindFirstChild("Radar")
            if radarMod then
                local radar = require(radarMod)
                if radar and type(radar.Render) == "function" then
                    origRadarRender = radar.Render
                    radarModuleInstance = radar
                    radar.Render = function(self, ...)
                        if MemeSenseMisc.InGameRadar and self.EnemyVisibilityCache then
                            local myTeam = LocalPlayer:GetAttribute("Team")
                            local now = tick()
                            for _, player in ipairs(Players:GetPlayers()) do
                                if player ~= LocalPlayer and player:GetAttribute("Team") ~= myTeam then
                                    local pChar = player.Character
                                    if pChar and pChar:IsDescendantOf(workspace) and player:GetAttribute("Dead") ~= true and pChar:GetAttribute("Dead") ~= true then
                                        local root = pChar:FindFirstChild("HumanoidRootPart") or pChar:FindFirstChild("Head")
                                        if root then
                                            self.EnemyVisibilityCache[player.UserId .. "_Player"] = {
                                                Visible = true,
                                                UpdatedAt = now + 5
                                            }
                                        end
                                    end
                                end
                            end
                        end
                        return origRadarRender(self, ...)
                    end
                end
            end
        end)
    end

    MiscHooks.cleanupRadar = function()
        if radarModuleInstance and origRadarRender then
            radarModuleInstance.Render = origRadarRender
            origRadarRender = nil
            radarModuleInstance = nil
        end
    end
end)()

;(function()
    local origKillFeedCreateTemplate = nil
    local killFeedModuleInstance = nil
    local preservedKillCards = {}
    local activeContainer = nil
    local kfChildAddedConn = nil
    local kfChildRemovedConn = nil

    local function updateKillFeedOrder(container)
        if not container or not container.Parent then return end
        pcall(function()
            local listLayout = container:FindFirstChildOfClass("UIListLayout")
            if listLayout and listLayout.SortOrder ~= Enum.SortOrder.LayoutOrder then
                listLayout.SortOrder = Enum.SortOrder.LayoutOrder
            end

            local cards = {}
            for _, child in ipairs(container:GetChildren()) do
                if child:IsA("GuiObject") and child.Name == "Kill" and child.Visible then
                    table.insert(cards, child)
                end
            end

            table.sort(cards, function(a, b)
                local tA = a:GetAttribute("KillSpawnTick") or 0
                local tB = b:GetAttribute("KillSpawnTick") or 0
                return tA > tB
            end)

            for idx, card in ipairs(cards) do
                card.LayoutOrder = idx
            end

            if #cards > 6 then
                for i = 7, #cards do
                    local oldCard = cards[i]
                    if oldCard and oldCard.Parent then
                        local isPreserved = false
                        for _, pCard in ipairs(preservedKillCards) do
                            if pCard == oldCard then isPreserved = true break end
                        end
                        if not isPreserved then
                            pcall(function() oldCard:Destroy() end)
                        end
                    end
                end
            end
        end)
    end

    MiscHooks.clearPreservedKillCards = function()
        for _, card in ipairs(preservedKillCards) do
            pcall(function()
                if card and card.Parent then
                    local tw = TweenService:Create(card, TweenInfo.new(0.4), { GroupTransparency = 1 })
                    tw:Play()
                    local stroke = card:FindFirstChild("UIStroke")
                    if stroke then
                        TweenService:Create(stroke, TweenInfo.new(0.4), { Transparency = 1 }):Play()
                    end
                    task.delay(0.4, function()
                        if card and card.Parent then card:Destroy() end
                    end)
                end
            end)
        end
        table.clear(preservedKillCards)
        if activeContainer then
            task.delay(0.45, function()
                updateKillFeedOrder(activeContainer)
            end)
        end
    end

    MiscHooks.hookKillFeed = function()
        if origKillFeedCreateTemplate then return end
        pcall(function()
            local screens = ReplicatedStorage:FindFirstChild("Interface") and ReplicatedStorage.Interface:FindFirstChild("Screens")
            local gameplay = screens and screens:FindFirstChild("Gameplay")
            local middle = gameplay and gameplay:FindFirstChild("Middle")
            local kfMod = middle and middle:FindFirstChild("KillFeed")
            if kfMod then
                local kf = require(kfMod)
                if kf and type(kf.createTemplate) == "function" then
                    origKillFeedCreateTemplate = kf.createTemplate
                    killFeedModuleInstance = kf

                    local function getContainer()
                        if activeContainer and activeContainer.Parent then
                            return activeContainer
                        end

                        pcall(function()
                            local getUps = (debug and debug.getupvalues) or getupvalues
                            if getUps and origKillFeedCreateTemplate then
                                local ups = getUps(origKillFeedCreateTemplate)
                                for _, v in pairs(ups) do
                                    if typeof(v) == "Instance" and v:IsA("GuiObject") then
                                        activeContainer = v
                                        return
                                    end
                                end
                            end
                        end)
                        if activeContainer and activeContainer.Parent then
                            return activeContainer
                        end

                        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
                        local mg = pGui and (pGui:FindFirstChild("MainGui") or pGui:FindFirstChild("Gui"))
                        if mg then
                            local gplay = mg:FindFirstChild("Gameplay") or mg
                            local mid = gplay:FindFirstChild("Middle") or gplay
                            local kfObj = mid:FindFirstChild("KillFeed") or mg:FindFirstChild("KillFeed", true)
                            if kfObj and kfObj:IsA("GuiObject") then
                                activeContainer = kfObj
                                return activeContainer
                            end
                        end
                        return nil
                    end

                    local container = getContainer()
                    local function bindContainerEvents(c)
                        if not c then return end
                        if kfChildAddedConn then kfChildAddedConn:Disconnect() end
                        if kfChildRemovedConn then kfChildRemovedConn:Disconnect() end

                        kfChildAddedConn = c.ChildAdded:Connect(function(child)
                            if child:IsA("GuiObject") and child.Name == "Kill" then
                                if not child:GetAttribute("KillSpawnTick") then
                                    child:SetAttribute("KillSpawnTick", os.clock())
                                end
                                task.defer(function()
                                    updateKillFeedOrder(c)
                                end)
                            end
                        end)
                        table.insert(Connections, kfChildAddedConn)

                        kfChildRemovedConn = c.ChildRemoved:Connect(function(child)
                            if child:IsA("GuiObject") and child.Name == "Kill" then
                                task.defer(function()
                                    updateKillFeedOrder(c)
                                end)
                            end
                        end)
                        table.insert(Connections, kfChildRemovedConn)
                    end
                    if container then
                        bindContainerEvents(container)
                    end

                    local function convertLabel(p5, p6, p7)
                        if p7 then
                            local pl = Players:GetPlayerByUserId(p7)
                            if not (pl and pl:IsDescendantOf(Players)) then
                                p6.Visible = false
                                return
                            end
                            local team = pl:GetAttribute("Team")
                            p6.Text = pl.DisplayName
                            p6.Visible = true
                            if LocalPlayer.UserId == p7 then
                                local stroke = p5:FindFirstChild("UIStroke")
                                if stroke then
                                    stroke.Color = Color3.fromRGB(255, 0, 0)
                                end
                            end
                            if team == "Counter-Terrorists" then
                                p6.TextColor3 = Color3.fromRGB(165, 183, 212)
                            elseif team == "Terrorists" then
                                p6.TextColor3 = Color3.fromRGB(219, 199, 126)
                            end
                        end
                    end

                    local function createPreservedCard(p11, targetContainer)
                        local wpMod = ReplicatedStorage:FindFirstChild("Database")
                            and ReplicatedStorage.Database:FindFirstChild("Custom")
                            and ReplicatedStorage.Database.Custom:FindFirstChild("Weapons")
                            and ReplicatedStorage.Database.Custom.Weapons:FindFirstChild(p11.Weapon)
                        if not wpMod then return nil end
                        local wData = require(wpMod)
                        local kAsset = ReplicatedStorage:FindFirstChild("Assets")
                            and ReplicatedStorage.Assets:FindFirstChild("UI")
                            and ReplicatedStorage.Assets.UI:FindFirstChild("KillFeed")
                            and ReplicatedStorage.Assets.UI.KillFeed:FindFirstChild("Kill")
                        if not kAsset then return nil end

                        targetContainer.Visible = true
                        local card = kAsset:Clone()
                        local pad = card.Contents:FindFirstChild("UIPadding")
                        if not pad then
                            pad = Instance.new("UIPadding")
                            pad.Parent = card.Contents
                        end
                        pad.PaddingLeft = UDim.new(0, 5)
                        pad.PaddingRight = UDim.new(0, 5)

                        convertLabel(card, card.Contents.Player, tonumber(p11.Killer))
                        convertLabel(card, card.Contents.Enemy, tonumber(p11.Victim))

                        if p11.Assistor then
                            convertLabel(card, card.Contents.Assistor, tonumber(p11.Assistor))
                            card.Contents.Addition.Visible = true
                            card.Contents.FlashAssist.Visible = (p11.FlashAssist == true)
                        else
                            card.Contents.Assistor.Visible = false
                            card.Contents.Addition.Visible = false
                            card.Contents.FlashAssist.Visible = false
                        end

                        card.Contents.Weapon.Image = wData.ReverseIcon
                        card.Contents.Headshot.Visible = (p11.Headshot == true)
                        card.Contents.NoScope.Visible = (p11.NoScope == true)
                        card.Contents.Smoke.Visible = (p11.Smoke == true)
                        card.Contents.Blind.Visible = (p11.Blind == true)
                        card.Contents.Wallbang.Visible = (p11.Wallbang == true)
                        card.Contents.Jump.Visible = (p11.Jump == true)

                        local order = 0
                        if p11.Blind == true then card.Contents.Blind.LayoutOrder = order; order += 1 end
                        card.Contents.Player.LayoutOrder = order; order += 1
                        if p11.Assistor then
                            card.Contents.Addition.LayoutOrder = order; order += 1
                            if p11.FlashAssist == true then card.Contents.FlashAssist.LayoutOrder = order; order += 1 end
                            card.Contents.Assistor.LayoutOrder = order; order += 1
                        end
                        if p11.Jump == true then card.Contents.Jump.LayoutOrder = order; order += 1 end
                        card.Contents.Weapon.LayoutOrder = order; order += 1
                        if p11.NoScope == true then card.Contents.NoScope.LayoutOrder = order; order += 1 end
                        if p11.Smoke == true then card.Contents.Smoke.LayoutOrder = order; order += 1 end
                        if p11.Wallbang == true then card.Contents.Wallbang.LayoutOrder = order; order += 1 end
                        if p11.Headshot == true then card.Contents.Headshot.LayoutOrder = order; order += 1 end
                        card.Contents.Enemy.LayoutOrder = order

                        card:SetAttribute("KillSpawnTick", os.clock())
                        card.Visible = true
                        card.Parent = targetContainer
                        return card
                    end

                    kf.createTemplate = function(p11)
                        local isLocalKill = (tonumber(p11.Killer) == LocalPlayer.UserId)
                        local cont = getContainer()
                        if cont and not kfChildAddedConn then
                            bindContainerEvents(cont)
                        end

                        if MemeSenseMisc.PreserveKillfeed and isLocalKill and cont then
                            local ok, card = pcall(createPreservedCard, p11, cont)
                            if ok and card then
                                table.insert(preservedKillCards, card)
                                updateKillFeedOrder(cont)
                                return card
                            end
                        end
                        local res = origKillFeedCreateTemplate(p11)
                        if cont then
                            task.defer(function()
                                updateKillFeedOrder(cont)
                            end)
                        end
                        return res
                    end
                end
            end
        end)

        local function connectCharDeath(char)
            if not char then return end
            local conn = char:GetAttributeChangedSignal("Dead"):Connect(function()
                if char:GetAttribute("Dead") == true then
                    MiscHooks.clearPreservedKillCards()
                end
            end)
            table.insert(Connections, conn)
        end
        connectCharDeath(LocalPlayer.Character)
        local charAddedConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
            MiscHooks.clearPreservedKillCards()
            connectCharDeath(newChar)
        end)
        table.insert(Connections, charAddedConn)
    end

    MiscHooks.cleanupKillFeed = function()
        if killFeedModuleInstance and origKillFeedCreateTemplate then
            killFeedModuleInstance.createTemplate = origKillFeedCreateTemplate
            origKillFeedCreateTemplate = nil
            killFeedModuleInstance = nil
        end
        if kfChildAddedConn then
            pcall(function() kfChildAddedConn:Disconnect() end)
            kfChildAddedConn = nil
        end
        if kfChildRemovedConn then
            pcall(function() kfChildRemovedConn:Disconnect() end)
            kfChildRemovedConn = nil
        end
        activeContainer = nil
        MiscHooks.clearPreservedKillCards()
    end
end)()

;(function()
    local soundCache = {}
    local soundsHooked = false
    local recentKills = {}
    local lastLocalKillTick = 0
    local lastHitSoundPlayedTick = 0
    local lastVictimDamagedUserId = nil
    local lastVictimDamagedTick = 0

    local function ensureSoundsDirectory()
        pcall(function()
            if type(isfolder) == "function" and type(makefolder) == "function" then
                if not isfolder("Memesense") then
                    pcall(makefolder, "Memesense")
                end
                if not isfolder("Memesense/sounds") then
                    pcall(makefolder, "Memesense/sounds")
                end
            end
        end)
    end

    local function downloadDefaultSound()
        local targetPath = "Memesense/sounds/Default.wav"
        if type(isfile) == "function" and isfile(targetPath) then
            return true
        end
        ensureSoundsDirectory()
        local rawUrl = "https://raw.githubusercontent.com/AJWOLF321/Other/main/Memesense/Hitsounds/Default.wav"
        local data = nil
        pcall(function()
            data = game:HttpGet(rawUrl)
        end)
        if (not data or #data == 0) then
            local req = (syn and syn.request) or (http and http.request) or http_request or request
            if req then
                local ok, res = pcall(req, { Url = rawUrl, Method = "GET" })
                if ok and res and (res.StatusCode == 200 or res.Status == 200) and res.Body and #res.Body > 0 then
                    data = res.Body
                end
            end
        end
        if data and #data > 0 and type(writefile) == "function" then
            pcall(writefile, targetPath, data)
            return true
        end
        return false
    end

    task.spawn(downloadDefaultSound)

    local function playCustomSound(soundName, volume)
        if not soundName or soundName == "" then return end
        pcall(function()
            local vol = tonumber(volume) or 1
            local assetUrl = soundCache[soundName]
            if not assetUrl then
                if soundName == "Default" then
                    local targetPath = "Memesense/sounds/Default.wav"
                    if type(isfile) == "function" and not isfile(targetPath) then
                        downloadDefaultSound()
                    end
                end

                if type(getcustomasset) == "function" then
                    local candidates = {
                        "Memesense/sounds/" .. soundName .. ".wav",
                        "Memesense/sounds/" .. soundName .. ".mp3",
                        "Memesense/sounds/" .. soundName .. ".ogg",
                        "Memesense/" .. soundName .. ".wav",
                        "Memesense/" .. soundName .. ".mp3",
                        soundName .. ".wav"
                    }
                    for _, path in ipairs(candidates) do
                        if type(isfile) == "function" and isfile(path) then
                            local ok, url = pcall(getcustomasset, path)
                            if ok and url and url ~= "" then
                                assetUrl = url
                                break
                            end
                        end
                    end
                end

                if assetUrl then
                    soundCache[soundName] = assetUrl
                end
            end

            if not assetUrl or assetUrl == "" or assetUrl == "rbxassetid://0" or assetUrl == "rbxassetid://" then
                return
            end

            local ss = game:GetService("SoundService")
            local s = Instance.new("Sound")
            s.Name = "MemeSense_" .. soundName
            s.SoundId = assetUrl
            s.Volume = math.clamp(vol, 0, 10)
            s.Parent = ss or workspace

            local played = false
            if ss and type(ss.PlayLocalSound) == "function" then
                local ok = pcall(function() ss:PlayLocalSound(s) end)
                if ok then played = true end
            end
            if not played then
                s:Play()
            end
            task.delay(3, function()
                pcall(function() if s and s.Parent then s:Destroy() end end)
            end)
        end)
    end

    MemeSenseSounds.SetupListeners = function()
        if soundsHooked then return end
        soundsHooked = true
        pcall(function()
            local remotes = ReplicatedStorage:FindFirstChild("Database")
                and ReplicatedStorage.Database:FindFirstChild("Security")
                and ReplicatedStorage.Database.Security:FindFirstChild("Remotes")
            if remotes then
                local RemotesObj = require(remotes)
                if not RemotesObj then return end

                if RemotesObj.UI and RemotesObj.UI.UIPlayerKilled then
                    RemotesObj.UI.UIPlayerKilled.Listen(function(p21)
                        if not p21 then return end
                        local killerId = tonumber(p21.Killer)
                        local victimId = tonumber(p21.Victim)
                        if killerId == LocalPlayer.UserId then
                            if victimId then
                                recentKills[victimId] = tick()
                            end
                            lastLocalKillTick = tick()

                            if MemeSenseSounds.KillEnabled then
                                playCustomSound(MemeSenseSounds.SelectedKill, MemeSenseSounds.KillVolume)
                            end
                        end
                    end)
                end

                if RemotesObj.Character and RemotesObj.Character.CharacterDamaged then
                    RemotesObj.Character.CharacterDamaged.Listen(function(p1)
                        if not p1 then return end
                        local vId = tonumber(p1.VictimUserId)
                        if vId and vId ~= LocalPlayer.UserId then
                            lastVictimDamagedUserId = vId
                            lastVictimDamagedTick = tick()
                        end
                    end)
                end

                if RemotesObj.VFX and RemotesObj.VFX.CreateImpact then
                    RemotesObj.VFX.CreateImpact.Listen(function(p1)
                        if not p1 then return end
                        if p1.Exit == true then return end

                        local attackerStr = tostring(p1.AttackerUserId or "")
                        if attackerStr ~= tostring(LocalPlayer.UserId) then return end

                        local victimPlayer = nil
                        local victimChar = nil
                        local victimUserId = nil

                        if p1.Instance then
                            victimChar = p1.Instance:FindFirstAncestorOfClass("Model")
                            if victimChar then
                                victimPlayer = Players:GetPlayerFromCharacter(victimChar)
                                if victimPlayer then
                                    victimUserId = victimPlayer.UserId
                                end
                            end
                        end

                        if not victimUserId and (tick() - lastVictimDamagedTick) < 0.05 then
                            victimUserId = lastVictimDamagedUserId
                            victimPlayer = Players:GetPlayerByUserId(victimUserId)
                            if victimPlayer then
                                victimChar = victimPlayer.Character
                            end
                        end

                        local isPlayerHit = (p1.Material == "Blood Splatter") or (victimPlayer ~= nil)
                        if not isPlayerHit then return end

                        if victimPlayer and victimPlayer == LocalPlayer then return end

                        if victimUserId and recentKills[victimUserId] and (tick() - recentKills[victimUserId]) < 0.5 then
                            return
                        end
                        if (tick() - lastLocalKillTick) < 0.15 then
                            return
                        end
                        if victimPlayer and victimPlayer:GetAttribute("Dead") == true then
                            return
                        end
                        if victimChar and victimChar:GetAttribute("Dead") == true then
                            return
                        end

                        task.delay(0.06, function()

                            if victimUserId and recentKills[victimUserId] and (tick() - recentKills[victimUserId]) < 0.5 then
                                return
                            end
                            if (tick() - lastLocalKillTick) < 0.15 then
                                return
                            end
                            if victimPlayer and (victimPlayer:GetAttribute("Dead") == true or not victimPlayer.Parent) then
                                return
                            end
                            if victimChar and (victimChar:GetAttribute("Dead") == true or not victimChar.Parent) then
                                return
                            end

                            local hum = victimChar and victimChar:FindFirstChildOfClass("Humanoid")
                            if hum and hum.Health <= 0 then
                                return
                            end

                            if MemeSenseSounds.HitEnabled then

                                local now = tick()
                                if (now - lastHitSoundPlayedTick) >= 0.04 then
                                    lastHitSoundPlayedTick = now
                                    playCustomSound(MemeSenseSounds.SelectedHit, MemeSenseSounds.HitVolume)
                                end
                            end
                        end)
                    end)
                end
            end
        end)
    end

    MemeSenseSounds.Cleanup = function()
        for _, s in pairs(soundCache) do
            pcall(function() if s and s.Parent then s:Destroy() end end)
        end
        table.clear(soundCache)
    end
end)()

;(function()
    local origSpectateSend = nil
    local spectatePacketInstance = nil
    local glitchHeartbeatConn = nil
    local lastGlitchSendTick = 0

    local function getGlitchCFrame(cf)
        local pos = cf.Position
        local pitch = math.rad(math.random(-89, 89))
        local yaw = math.rad(math.random(-180, 180))
        local roll = math.rad(math.random(-180, 180))
        return CFrame.new(pos) * CFrame.Angles(pitch, yaw, roll)
    end

    MiscHooks.hookGlitchSpectators = function()
        if not MemeSenseMisc.GlitchSpectators then return end

        pcall(function()
            local remotesMod = ReplicatedStorage:FindFirstChild("Database")
                and ReplicatedStorage.Database:FindFirstChild("Security")
                and ReplicatedStorage.Database.Security:FindFirstChild("Remotes")
            if remotesMod then
                local RemotesObj = require(remotesMod)
                if RemotesObj and RemotesObj.Spectate and RemotesObj.Spectate.UpdateCameraCFrame then
                    local packet = RemotesObj.Spectate.UpdateCameraCFrame
                    if type(packet.Send) == "function" and not origSpectateSend then
                        spectatePacketInstance = packet
                        if type(setreadonly) == "function" then
                            pcall(setreadonly, RemotesObj.Spectate, false)
                            pcall(setreadonly, packet, false)
                        elseif type(make_writeable) == "function" then
                            pcall(make_writeable, RemotesObj.Spectate)
                            pcall(make_writeable, packet)
                        end

                        if type(hookfunction) == "function" then
                            origSpectateSend = hookfunction(packet.Send, function(cf, ...)
                                if MemeSenseMisc.GlitchSpectators and typeof(cf) == "CFrame" then
                                    cf = getGlitchCFrame(cf)
                                end
                                return origSpectateSend(cf, ...)
                            end)
                        else
                            origSpectateSend = packet.Send
                            packet.Send = function(cf, ...)
                                if MemeSenseMisc.GlitchSpectators and typeof(cf) == "CFrame" then
                                    cf = getGlitchCFrame(cf)
                                end
                                return origSpectateSend(cf, ...)
                            end
                        end
                    end
                end
            end
        end)

        if not glitchHeartbeatConn then
            glitchHeartbeatConn = RunService.Heartbeat:Connect(function()
                if not MemeSenseMisc.GlitchSpectators then return end
                local cam = workspace.CurrentCamera
                if not cam then return end
                local now = os.clock()
                if (now - lastGlitchSendTick) < 0.025 then return end
                lastGlitchSendTick = now

                pcall(function()
                    local specCount = LocalPlayer:GetAttribute("Spectators")
                    if specCount and specCount > 0 then
                        if spectatePacketInstance and origSpectateSend then
                            origSpectateSend(getGlitchCFrame(cam.CFrame))
                        end
                    end
                end)
            end)
            table.insert(Connections, glitchHeartbeatConn)
        end
    end

    MiscHooks.cleanupGlitchSpectators = function()
        if spectatePacketInstance and origSpectateSend then
            if type(hookfunction) == "function" then
                pcall(hookfunction, spectatePacketInstance.Send, origSpectateSend)
            else
                spectatePacketInstance.Send = origSpectateSend
            end
            origSpectateSend = nil
            spectatePacketInstance = nil
        end
        if glitchHeartbeatConn then
            pcall(function() glitchHeartbeatConn:Disconnect() end)
            glitchHeartbeatConn = nil
        end
    end
end)()

MiscHooks.cleanupMiscHooks = function()
    if MiscHooks.bhopConn then
        pcall(function() MiscHooks.bhopConn:Disconnect() end)
        MiscHooks.bhopConn = nil
    end
    if MiscHooks.cleanupRadar then
        pcall(MiscHooks.cleanupRadar)
    end
    if MiscHooks.cleanupKillFeed then
        pcall(MiscHooks.cleanupKillFeed)
    end
    if MiscHooks.clearPreservedKillCards then
        pcall(MiscHooks.clearPreservedKillCards)
    end
    if MiscHooks.cleanupGlitchSpectators then
        pcall(MiscHooks.cleanupGlitchSpectators)
    end
    if MemeSenseSounds and MemeSenseSounds.Cleanup then
        pcall(MemeSenseSounds.Cleanup)
    end
end

;(function()
    local MiscTab = Tabs["Miscellaneous"]
    local MLeft = MiscTab.LeftColumn
    local MRight = MiscTab.RightColumn

    local mLeftOrder = 0
    local function nextMLeft()
        mLeftOrder += 1
        return mLeftOrder
    end

    local mRightOrder = 0
    local function nextMRight()
        mRightOrder += 1
        return mRightOrder
    end

    Controls:CreateSectionHeader(MLeft, "Interface", nextMLeft())

    Controls:CreateToggle(MLeft, {
        Name = "Event logs",
        Default = false,
        Dropdown = {
            Multi = true,
            Width = 136,
            Options = { "View votes", "Bomb events", "Damage dealt", "Damage received" },
            Default = { "View votes" }
        },
        LayoutOrder = nextMLeft()
    })

    Controls:CreateToggle(MLeft, {
        Name = "In-game radar",
        Default = false,
        LayoutOrder = nextMLeft(),
        Callback = function(v)
            MemeSenseMisc.InGameRadar = v
            if v and MiscHooks.hookInGameRadar then MiscHooks.hookInGameRadar() end
        end
    })

    Controls:CreateToggle(MLeft, {
        Name = "Preserve kill-feed",
        Default = false,
        LayoutOrder = nextMLeft(),
        Callback = function(v)
            MemeSenseMisc.PreserveKillfeed = v
            if v then
                if MiscHooks.hookKillFeed then MiscHooks.hookKillFeed() end
            else
                if MiscHooks.clearPreservedKillCards then MiscHooks.clearPreservedKillCards() end
            end
        end
    })

    Controls:CreateToggle(MLeft, {
        Name = "Glitch spectators",
        Default = false,
        LayoutOrder = nextMLeft(),
        Callback = function(v)
            MemeSenseMisc.GlitchSpectators = v
            if v then
                if MiscHooks.hookGlitchSpectators then MiscHooks.hookGlitchSpectators() end
            else
                if MiscHooks.cleanupGlitchSpectators then MiscHooks.cleanupGlitchSpectators() end
            end
        end
    })

    Controls:CreateSectionHeader(MLeft, "Movement", nextMLeft())

    Controls:CreateToggle(MLeft, {
        Name = "Bhop",
        Default = false,
        LayoutOrder = nextMLeft(),
        Callback = function(v)
            MemeSenseMisc.Bhop = v
            if v then
                if MiscHooks.setupBhop then MiscHooks.setupBhop() end
            else
                pcall(function()
                    local cc = ReplicatedStorage:FindFirstChild("Controllers") and ReplicatedStorage.Controllers:FindFirstChild("CharacterController")
                    if cc then
                        local charController = require(cc)
                        local curr = charController and charController.getCurrentCharacter and charController.getCurrentCharacter()
                        if curr then
                            curr.JumpInputDown = false
                            curr.JumpPulsePending = false
                        end
                    end
                end)
            end
        end
    })

    Controls:CreateSectionHeader(MRight, "Extra", nextMRight())

    local soundList = { "Default" }

    Controls:CreateToggle(MRight, {
        Name = "Hit sound",
        Default = false,
        SettingsIcon = true,
        SettingsIconText = "6",
        SettingsIconFont = GuiIconsFont,
        SettingsIconSize = 13,
        Dropdown = {
            Options = soundList,
            Default = "Default",
            Width = 84,
            Callback = function(opt)
                MemeSenseSounds.SelectedHit = opt
            end
        },
        OnSettingsClick = function(btn)
            Controls:OpenVolumePopover(btn, MemeSenseSounds.HitVolume, function(v)
                MemeSenseSounds.HitVolume = v
            end)
        end,
        Callback = function(v)
            MemeSenseSounds.HitEnabled = v
            if v and MemeSenseSounds.SetupListeners then MemeSenseSounds.SetupListeners() end
        end,
        LayoutOrder = nextMRight()
    })

    Controls:CreateToggle(MRight, {
        Name = "Kill sound",
        Default = false,
        SettingsIcon = true,
        SettingsIconText = "6",
        SettingsIconFont = GuiIconsFont,
        SettingsIconSize = 13,
        Dropdown = {
            Options = soundList,
            Default = "Default",
            Width = 84,
            Callback = function(opt)
                MemeSenseSounds.SelectedKill = opt
            end
        },
        OnSettingsClick = function(btn)
            Controls:OpenVolumePopover(btn, MemeSenseSounds.KillVolume, function(v)
                MemeSenseSounds.KillVolume = v
            end)
        end,
        Callback = function(v)
            MemeSenseSounds.KillEnabled = v
            if v and MemeSenseSounds.SetupListeners then MemeSenseSounds.SetupListeners() end
        end,
        LayoutOrder = nextMRight()
    })

    Controls:CreateButton(MRight, {
        Name = "Unload cheat",
        Callback = function()
            if getgenv().MemeSenseCleanup then
                getgenv().MemeSenseCleanup()
            end
        end,
        LayoutOrder = nextMRight()
    })
end)()

;(function()
    local InventoryTab = Tabs["Inventory"]
    if not InventoryTab then return end

    local LeftCol = InventoryTab.LeftColumn
    local RightCol = InventoryTab.RightColumn

    if LeftCol then LeftCol.Visible = false end
    if RightCol then RightCol.Visible = false end

    -- ========================================================================
    -- BLOXSTRIKE GAME INTEGRATION & HOOK ENGINE (Unlock.luau Parity)
    -- ========================================================================
    local DataController = nil
    local SkinsLib = nil
    local CasesLib = nil
    local Remotes = nil
    local WeaponComponent = nil
    local Viewmodel = nil
    local GetWeaponProperties = nil
    local GetResolvedSkinInformation = nil
    local Store = nil
    local Router = nil

    pcall(function()
        DataController = require(ReplicatedStorage:WaitForChild("Controllers"):WaitForChild("DataController"))
    end)
    pcall(function()
        SkinsLib = require(ReplicatedStorage:WaitForChild("Database"):WaitForChild("Components"):WaitForChild("Libraries"):WaitForChild("Skins"))
    end)
    pcall(function()
        CasesLib = require(ReplicatedStorage:WaitForChild("Database"):WaitForChild("Components"):WaitForChild("Libraries"):WaitForChild("Cases"))
    end)
    pcall(function()
        Remotes = require(ReplicatedStorage:WaitForChild("Database"):WaitForChild("Security"):WaitForChild("Remotes"))
    end)
    pcall(function()
        WeaponComponent = require(ReplicatedStorage:WaitForChild("Classes"):WaitForChild("WeaponComponent"))
    end)
    pcall(function()
        Viewmodel = require(ReplicatedStorage:WaitForChild("Classes"):WaitForChild("WeaponComponent"):WaitForChild("Classes"):WaitForChild("Viewmodel"))
    end)
    pcall(function()
        GetWeaponProperties = require(ReplicatedStorage:WaitForChild("Components"):WaitForChild("Common"):WaitForChild("GetWeaponProperties"))
    end)

    local weaponPropCache = {}
    pcall(function()
        local CustomWeapons = (ReplicatedStorage:FindFirstChild("Database") and ReplicatedStorage.Database:FindFirstChild("Custom") and ReplicatedStorage.Database.Custom:FindFirstChild("Weapons"))
        if CustomWeapons then
            for _, child in ipairs(CustomWeapons:GetChildren()) do
                if child:IsA("ModuleScript") then
                    local okReq, def = pcall(require, child)
                    if okReq and typeof(def) == "table" then
                        weaponPropCache[child.Name] = def
                        weaponPropCache[string.gsub(child.Name, "%-", " ")] = def
                        weaponPropCache[string.gsub(child.Name, " ", "-")] = def
                    end
                end
            end
        end
    end)

    if typeof(GetWeaponProperties) == "function" and typeof(hookfunction) == "function" then
        local oldGWP
        oldGWP = hookfunction(GetWeaponProperties, function(p1)
            if not p1 then return nil end
            if weaponPropCache[p1] then return weaponPropCache[p1] end
            if typeof(p1) == "string" then
                local spaced = string.gsub(p1, "%-", " ")
                if weaponPropCache[spaced] then return weaponPropCache[spaced] end
                local hyphenated = string.gsub(p1, " ", "-")
                if weaponPropCache[hyphenated] then return weaponPropCache[hyphenated] end
            end
            if oldGWP then
                local okCall, res = pcall(oldGWP, p1)
                if okCall and res then return res end
            end
            return nil
        end)
    end

    local function safeGetWeaponProperties(p1)
        if not p1 then return nil end
        if weaponPropCache[p1] then return weaponPropCache[p1] end
        if typeof(p1) == "string" then
            local spaced = string.gsub(p1, "%-", " ")
            if weaponPropCache[spaced] then return weaponPropCache[spaced] end
            local hyphenated = string.gsub(p1, " ", "-")
            if weaponPropCache[hyphenated] then return weaponPropCache[hyphenated] end
        end
        if GetWeaponProperties then
            local okCall, res = pcall(GetWeaponProperties, p1)
            if okCall and res then return res end
        end
        return nil
    end

    pcall(function()
        GetResolvedSkinInformation = require(ReplicatedStorage:WaitForChild("Components"):WaitForChild("Common"):WaitForChild("GetResolvedSkinInformation"))
    end)
    pcall(function()
        Store = require(ReplicatedStorage:WaitForChild("Interface"):WaitForChild("Screens"):WaitForChild("Menu"):WaitForChild("Store"))
    end)
    pcall(function()
        Router = require(ReplicatedStorage:WaitForChild("Database"):WaitForChild("Security"):WaitForChild("Router"))
    end)
    local CareerWeaponIcon = nil
    local getStockWeaponIcon = nil
    pcall(function()
        CareerWeaponIcon = require(ReplicatedStorage:WaitForChild("Interface"):WaitForChild("Screens"):WaitForChild("Menu"):WaitForChild("Career"):WaitForChild("WeaponIcon"))
        if CareerWeaponIcon and CareerWeaponIcon.Get then
            local gu = debug.getupvalues or getupvals or getupvalues
            if gu then
                local uvs = gu(CareerWeaponIcon.Get)
                if typeof(uvs) == "table" then
                    for _, u in pairs(uvs) do
                        if typeof(u) == "function" and debug.getinfo(u).name == "GetStockIcon" then
                            getStockWeaponIcon = u
                            break
                        end
                    end
                    if not getStockWeaponIcon and typeof(uvs[5]) == "function" then
                        getStockWeaponIcon = uvs[5]
                    end
                end
            end
        end
    end)

    local refreshGridItems = nil
    local unlockedDict = {}
    local injectedItemIds = {}
    pcall(function()
        if DataController and typeof(DataController.ApplyInventoryDelta) == "function" then
            local origApplyDelta = DataController.ApplyInventoryDelta
            DataController.ApplyInventoryDelta = function(player, added, removed)
                if removed and typeof(removed) == "table" and #removed > 0 then
                    local changed = false
                    for _, rId in ipairs(removed) do
                        if rId then
                            unlockedDict[rId] = nil
                            injectedItemIds[rId] = nil
                            for idx = #MemeSenseInventory.Items, 1, -1 do
                                if MemeSenseInventory.Items[idx]._id == rId then
                                    table.remove(MemeSenseInventory.Items, idx)
                                    changed = true
                                    break
                                end
                            end
                        end
                    end
                    if changed then
                        if refreshGridItems then pcall(refreshGridItems) end
                        if MemeSenseInventory and MemeSenseInventory.RefreshUI then pcall(MemeSenseInventory.RefreshUI) end
                    end
                end
                return origApplyDelta(player, added, removed)
            end
        end
    end)
    local currentLocalViewmodel = nil
    local customLoadout = {
        ["Counter-Terrorists"] = {
            Weapons = {},
            Knife = nil,
            Glove = nil,
            Badge = nil
        },
        ["Terrorists"] = {
            Weapons = {},
            Knife = nil,
            Glove = nil,
            Badge = nil
        }
    }
    MemeSenseInventory.CustomLoadout = customLoadout

    local getWeaponClass = nil
    local getRarityColor = nil

    local function sanitize(str)
        if not str then return "" end
        return string.gsub(string.gsub(tostring(str), "%s+", ""), "[^%w]", "")
    end

    getRarityColor = function(rarityName, isSpecial)
        if isSpecial then return Color3.fromRGB(255, 215, 0) end
        local r = string.lower(tostring(rarityName or ""))
        if string.find(r, "special") then
            return Color3.fromRGB(255, 215, 0)
        elseif string.find(r, "covert") or string.find(r, "extraordinary") or string.find(r, "ancient") or string.find(r, "red") then
            return Color3.fromRGB(245, 60, 60)
        elseif string.find(r, "classified") or string.find(r, "legendary") or string.find(r, "pink") then
            return Color3.fromRGB(225, 65, 195)
        elseif string.find(r, "restricted") or string.find(r, "mythical") or string.find(r, "purple") then
            return Color3.fromRGB(150, 75, 255)
        elseif string.find(r, "mil%-spec") or string.find(r, "milspec") or string.find(r, "rare") or string.find(r, "blue") then
            return Color3.fromRGB(75, 120, 255)
        elseif string.find(r, "industrial") then
            return Color3.fromRGB(95, 160, 235)
        elseif string.find(r, "consumer") then
            return Color3.fromRGB(180, 205, 235)
        end
        return Color3.fromRGB(160, 165, 175)
    end

    getWeaponClass = function(wName)
        if not wName or wName == "" then return "Weapon" end
        if safeGetWeaponProperties then
            local prop = safeGetWeaponProperties(wName)
            if prop then
                if prop.Type then return prop.Type end
                if prop.Class == "Melee" or prop.Slot == "Melee" then return "Melee" end
                if prop.Class == "Glove" then return "Glove" end
                return prop.Class or "Weapon"
            end
        end
        local lower = string.lower(wName)
        if string.find(lower, "knife") or string.find(lower, "bayonet") or string.find(lower, "karambit") or string.find(lower, "lightsaber") then return "Melee" end
        if string.find(lower, "glove") or string.find(lower, "wrap") then return "Glove" end
        if string.find(lower, "case") or string.find(lower, "capsule") then return "Case" end
        if string.find(lower, "package") then return "Package" end
        if string.find(lower, "charm") then return "Charm" end
        if string.find(lower, "badge") then return "Badge" end
        return "Weapon"
    end


    local function getEquippedSkin(teamName, weaponName)
        local cleanW = sanitize(weaponName)
        local teamData = customLoadout[teamName]
        if teamData and teamData.Weapons then
            for wKey, wData in pairs(teamData.Weapons) do
                if sanitize(wKey) == cleanW or wKey == weaponName then
                    return wData
                end
            end
        end
        local otherTeam = (teamName == "Counter-Terrorists" and "Terrorists") or "Counter-Terrorists"
        if customLoadout[otherTeam] and customLoadout[otherTeam].Weapons then
            for wKey, wData in pairs(customLoadout[otherTeam].Weapons) do
                if sanitize(wKey) == cleanW or wKey == weaponName then
                    return wData
                end
            end
        end

        local loadout = nil
        pcall(function()
            if DataController then loadout = DataController.Get(LocalPlayer, "Loadout") end
        end)
        if loadout and loadout[teamName] and loadout[teamName].Loadout then
            for _, cat in pairs(loadout[teamName].Loadout) do
                if cat and cat.Options then
                    for _, optId in pairs(cat.Options) do
                        if optId and unlockedDict[optId] and (sanitize(unlockedDict[optId].Name) == cleanW or unlockedDict[optId].Name == weaponName) then
                            return unlockedDict[optId]
                        end
                    end
                end
            end
        end

        return nil
    end

    local function getEquippedKnife(teamName)
        local teamData = customLoadout[teamName]
        if teamData and teamData.Knife then
            return teamData.Knife
        end
        local otherTeam = (teamName == "Counter-Terrorists" and "Terrorists") or "Counter-Terrorists"
        if customLoadout[otherTeam] and customLoadout[otherTeam].Knife then
            return customLoadout[otherTeam].Knife
        end

        local loadout = nil
        pcall(function()
            if DataController then loadout = DataController.Get(LocalPlayer, "Loadout") end
        end)
        if loadout then
            for _, tName in ipairs({ teamName, otherTeam, "Global" }) do
                if loadout[tName] and loadout[tName].Equipped then
                    local knifeId = loadout[tName].Equipped["Equipped Melee"] or loadout[tName].Equipped["Melee"]
                    if knifeId and unlockedDict[knifeId] then
                        return unlockedDict[knifeId]
                    end
                end
            end
        end

        if MemeSenseInventory and MemeSenseInventory.Items then
            for _, it in ipairs(MemeSenseInventory.Items) do
                local itClass = it.Type or ""
                if (itClass == "Melee" or string.find(string.lower(it.Name), "knife") or it.Name == "Karambit" or it.Name == "LightSaber") and it.Equipped then
                    return it
                end
            end
        end
        return nil
    end

    local function getEquippedGlove(teamName)
        local teamData = customLoadout[teamName]
        if teamData and teamData.Glove then
            return teamData.Glove
        end
        local otherTeam = (teamName == "Counter-Terrorists" and "Terrorists") or "Counter-Terrorists"
        if customLoadout[otherTeam] and customLoadout[otherTeam].Glove then
            return customLoadout[otherTeam].Glove
        end

        local loadout = nil
        pcall(function()
            if DataController then loadout = DataController.Get(LocalPlayer, "Loadout") end
        end)
        if loadout then
            for _, tName in ipairs({ teamName, otherTeam, "Global" }) do
                if loadout[tName] and loadout[tName].Equipped then
                    local gloveId = loadout[tName].Equipped["Equipped Gloves"] or loadout[tName].Equipped["Glove"]
                    if gloveId and unlockedDict[gloveId] then
                        return unlockedDict[gloveId]
                    end
                end
            end
        end

        if MemeSenseInventory and MemeSenseInventory.Items then
            for _, it in ipairs(MemeSenseInventory.Items) do
                local itClass = it.Type or ""
                if (itClass == "Glove" or string.find(string.lower(it.Name), "glove") or string.find(string.lower(it.Name), "wrap")) and it.Equipped then
                    return it
                end
            end
        end
        return nil
    end

    local function applyGlovesToCharacter(customGlove)
        if not customGlove then return end
        pcall(function()
            local gSkin = (customGlove.Skin == "Vanilla" and "Stock") or customGlove.Skin or "Stock"
            local encoded = HttpService:JSONEncode({
                Name = customGlove.Name,
                Skin = gSkin,
                Float = customGlove.Float or 0.0001
            })
            pcall(function() LocalPlayer:SetAttribute("EquippedGloves", encoded) end)
            local char = LocalPlayer.Character or (workspace:FindFirstChild("Characters") and workspace.Characters:FindFirstChild(LocalPlayer.Name))
            if char and typeof(char) == "Instance" then
                pcall(function() char:SetAttribute("EquippedGloves", encoded) end)
            end
        end)
    end

    local function updateLoadoutInMemory(teamName, category, slotIndex, itemId)
        local item = unlockedDict[itemId]
        local function applyToTeam(tName)
            pcall(function()
                if not DataController then return end
                local loadout = DataController.Get(LocalPlayer, "Loadout")
                if loadout and loadout[tName] and loadout[tName].Loadout then
                    local cat = loadout[tName].Loadout[category]
                    if not cat then
                        cat = { Options = {} }
                        loadout[tName].Loadout[category] = cat
                    end
                    cat.Options[slotIndex] = itemId
                end
            end)

            if item then
                local realSkin = (item.Skin == "Vanilla" and "Stock") or item.Skin or "Stock"
                local isKnife = (item.Type == "Melee" or string.find(string.lower(item.Name), "knife") or item.Name == "Karambit" or item.Name == "LightSaber")
                local isGlove = (item.Type == "Glove" or string.find(string.lower(item.Name), "glove") or string.find(string.lower(item.Name), "wrap"))

                if isKnife then
                    customLoadout[tName].Knife = {
                        Name = item.Name,
                        Skin = realSkin,
                        Float = item.Float or 0.0001
                    }
                elseif isGlove then
                    customLoadout[tName].Glove = {
                        Name = item.Name,
                        Skin = realSkin,
                        Float = item.Float or 0.0001
                    }
                    applyGlovesToCharacter(customLoadout[tName].Glove)
                else
                    customLoadout[tName].Weapons[item.Name] = {
                        Name = item.Name,
                        Skin = realSkin,
                        Float = item.Float or 0.0001,
                        Charm = item.Charm or false
                    }
                    customLoadout[tName].Weapons[string.gsub(item.Name, " ", "-")] = customLoadout[tName].Weapons[item.Name]
                    customLoadout[tName].Weapons[string.gsub(item.Name, "%-", " ")] = customLoadout[tName].Weapons[item.Name]
                end
            end
        end

        if teamName == "Global" or not teamName or teamName == "" then
            applyToTeam("Counter-Terrorists")
            applyToTeam("Terrorists")
        else
            applyToTeam(teamName)
        end

        if item then
            for _, other in ipairs(MemeSenseInventory.Items) do
                if other ~= item and sanitize(other.Name) == sanitize(item.Name) then
                    other.Equipped = false
                end
            end
            item.Equipped = true
        end
    end

    local function updateSpecialInMemory(teamName, path, itemId)
        local item = unlockedDict[itemId]
        local function applyToTeam(tName)
            pcall(function()
                if not DataController then return end
                local loadout = DataController.Get(LocalPlayer, "Loadout")
                if loadout and loadout[tName] then
                    loadout[tName].Equipped = loadout[tName].Equipped or {}
                    loadout[tName].Equipped[path] = itemId
                    if path == "Equipped Melee" or path == "Melee" then
                        loadout[tName].Equipped["Equipped Melee"] = itemId
                        loadout[tName].Equipped["Melee"] = itemId
                    elseif path == "Equipped Gloves" or path == "Glove" then
                        loadout[tName].Equipped["Equipped Gloves"] = itemId
                        loadout[tName].Equipped["Glove"] = itemId
                    end
                end
            end)
            if item then
                local realSkin = (item.Skin == "Vanilla" and "Stock") or item.Skin or "Stock"
                if path == "Melee" or path == "Equipped Melee" or item.Type == "Melee" then
                    customLoadout[tName].Knife = {
                        Name = item.Name,
                        Skin = realSkin,
                        Float = item.Float or 0.0001
                    }
                elseif path == "Glove" or path == "Equipped Gloves" or item.Type == "Glove" then
                    customLoadout[tName].Glove = {
                        Name = item.Name,
                        Skin = realSkin,
                        Float = item.Float or 0.0001
                    }
                    applyGlovesToCharacter(customLoadout[tName].Glove)
                elseif path == "Equipped Badge" or path == "Badge" or item.Type == "Badge" then
                    customLoadout[tName].Badge = item
                    pcall(function()
                        if DataController then
                            local loadout = DataController.Get(LocalPlayer, "Loadout")
                            if loadout and loadout[tName] and loadout[tName].Equipped then
                                loadout[tName].Equipped["Equipped Badge"] = itemId
                            end
                        end
                    end)
                end
            end
        end
        if teamName == "Global" or not teamName or teamName == "" then
            applyToTeam("Counter-Terrorists")
            applyToTeam("Terrorists")
        else
            applyToTeam(teamName)
        end
    end

    -- ========================================================================
    -- CASE UNBOXING SYSTEM & BLOXSTRIKE INTEGRATION
    -- ========================================================================
    local defaultWeaponIconCache = {}
    local getSkinSpecificIcon = nil

    getSkinSpecificIcon = function(weaponName, skinName)
        if not weaponName or weaponName == "" or not skinName or skinName == "" then return "" end
        if skinName == "Stock" or skinName == "Vanilla" or skinName == "-" or skinName == "Standard" then
            return (getStockWeaponIcon and getStockWeaponIcon(weaponName)) or (getWeaponIcon and getWeaponIcon(weaponName)) or ""
        end

        -- 1. Try availableSkinsCache for the specific skin
        if availableSkinsCache then
            local wSkins = availableSkinsCache[weaponName]
                or availableSkinsCache[string.gsub(weaponName, " ", "-")]
                or availableSkinsCache[string.gsub(weaponName, "-", " ")]
            if wSkins and typeof(wSkins) == "table" then
                local sData = wSkins[skinName]
                if sData then
                    local sIcon = (sData.wearImages and #sData.wearImages > 0 and sData.wearImages[1].assetId) or sData.imageAssetId or ""
                    if sIcon ~= "" and not (WeaponDisplaySilhouettes and WeaponDisplaySilhouettes[sIcon]) then
                        return sIcon
                    end
                end
            end
        end

        -- 2. Try SkinsLib.GetSkinInformation
        if SkinsLib and SkinsLib.GetSkinInformation then
            local ok, info = pcall(SkinsLib.GetSkinInformation, weaponName, skinName)
            if ok and info then
                local sIcon = ""
                if SkinsLib.GetWearImageForFloat then
                    sIcon = SkinsLib.GetWearImageForFloat(info, 0.0001) or ""
                end
                if sIcon == "" then
                    sIcon = (info.wearImages and #info.wearImages > 0 and info.wearImages[1].assetId) or info.imageAssetId or ""
                end
                if sIcon ~= "" and not (WeaponDisplaySilhouettes and WeaponDisplaySilhouettes[sIcon]) then
                    return sIcon
                end
            end
        end

        -- 3. Try SkinsLib.GetAllSkinsForWeapon
        if SkinsLib and SkinsLib.GetAllSkinsForWeapon then
            local ok, allSkins = pcall(SkinsLib.GetAllSkinsForWeapon, weaponName)
            if ok and allSkins and typeof(allSkins) == "table" then
                for _, sInfo in ipairs(allSkins) do
                    if sInfo.skin == skinName or sInfo.name == skinName or sInfo.displayName == skinName then
                        local sIcon = (sInfo.wearImages and #sInfo.wearImages > 0 and sInfo.wearImages[1].assetId)
                            or (SkinsLib.GetWearImageForFloat and SkinsLib.GetWearImageForFloat(sInfo, 0.0001))
                            or sInfo.imageAssetId or ""
                        if sIcon ~= "" and not (WeaponDisplaySilhouettes and WeaponDisplaySilhouettes[sIcon]) then
                            return sIcon
                        end
                    end
                end
            end
        end

        -- 4. Try GetResolvedSkinInformation
        if GetResolvedSkinInformation then
            local ok, rInfo = pcall(GetResolvedSkinInformation, { Name = weaponName, Skin = skinName, Float = 0.0001 })
            if ok and rInfo and rInfo.assetId and rInfo.assetId ~= "" and not (WeaponDisplaySilhouettes and WeaponDisplaySilhouettes[rInfo.assetId]) then
                return rInfo.assetId
            end
        end

        -- Fallback to default stock weapon icon
        return (getStockWeaponIcon and getStockWeaponIcon(weaponName)) or (getWeaponIcon and getWeaponIcon(weaponName)) or ""
    end

    local currentCaseState = {
        caseId = nil,
        state = nil,
        caseIdentifier = nil,
        caseDef = nil
    }

    local isUnboxingActive = false
    local lastUnboxTimestamp = 0
    local lastWonItem = nil

    local storeInternal = {
        state = nil,
        bulkState = nil,
        pending = nil,
        queue = nil,
        tryProcess = nil,
        startResolvedJob = nil,
        openCase = nil,
        bulkOpen = nil,
        runScrollAnimation = nil,
    }

    local function safeRawGet(t, key)
        if typeof(t) ~= "table" then return nil end
        local ok, res = pcall(rawget, t, key)
        if ok then return res end
        return nil
    end

    local function isPlainTable(t)
        if typeof(t) ~= "table" then return false end
        local ok, mt = pcall(getmetatable, t)
        return ok and mt == nil
    end

    local function isModuleOrClassTable(t)
        if typeof(t) ~= "table" then return false end
        for _, v in pairs(t) do
            if typeof(v) == "function" then return true end
        end
        if safeRawGet(t, "mark") ~= nil or safeRawGet(t, "scope") ~= nil or safeRawGet(t, "defer") ~= nil or safeRawGet(t, "spawn") ~= nil then
            return true
        end
        if safeRawGet(t, "SetScreen") ~= nil or safeRawGet(t, "HideMenu") ~= nil or safeRawGet(t, "IsInspectActive") ~= nil then
            return true
        end
        if safeRawGet(t, "GetState") ~= nil or safeRawGet(t, "ListenToState") ~= nil then
            return true
        end
        return false
    end

    local function parseSkinFromCaseName(name)
        if not name or typeof(name) ~= "string" then return "AWP", "Asiimov" end
        local clean = name
        if string.sub(clean, 1, 8) == "Package " then clean = string.sub(clean, 9)
        elseif string.sub(clean, 1, 5) == "Case " then clean = string.sub(clean, 6) end
        local parts = string.split(clean, " | ")
        if #parts >= 2 then
            local weapon = parts[1]
            local skin = parts[2]
            return (weapon ~= "" and weapon or "AWP"), (skin ~= "" and skin or "Asiimov")
        end
        return (clean ~= "" and clean or "AWP"), "Asiimov"
    end

    local function ensureCaseHasContents(cDef, wonItem)
        if not cDef or typeof(cDef) ~= "table" then return end
        local isCharm = (cDef.caseType == "Charm Capsule" or (cDef.name and string.find(cDef.name, "Charm")) or (cDef.Name and string.find(cDef.Name, "Charm")) or (cDef.caseId and string.find(cDef.caseId, "charm")))
        local isConsole = (cDef.caseType == "Console" or (cDef.name and string.find(cDef.name, "Console")) or (cDef.Name and string.find(cDef.Name, "Console")) or (cDef.caseId and string.find(cDef.caseId, "console")))
        local isPkg = (cDef.caseType == "Package" or (cDef.name and string.find(cDef.name, " | ")) or (cDef.Name and string.find(cDef.Name, " | ")))

        if isCharm then
            cDef.caseType = "Charm Capsule"
            if not cDef.contents or #cDef.contents == 0 then
                local charmFiller = {}
                local charmNames = { "Missing Link", "Small Arms", "Hot Wurst", "Baby Karat CT", "Baby Karat T", "Tite Diamond", "Lil' Monster", "Hot Howl", "Pinch O' Salt", "Die-cast AK", "Glamour Shot" }
                for _, cn in ipairs(charmNames) do
                    table.insert(charmFiller, {
                        rarity = "Pink",
                        weight = 100,
                        isSpecial = false,
                        skinId = "Charm | " .. cn,
                        skin = { weaponName = "Charm", skinName = cn, type = "Charm" }
                    })
                end
                cDef.contents = charmFiller
            end
        elseif isConsole then
            cDef.caseType = "Console"
            if not cDef.contents or #cDef.contents == 0 then
                cDef.contents = {
                    { skinId = "Glock-18 | Hero of Hell", rarity = "Blue", weight = 1, skin = { weaponName = "Glock-18", skinName = "Hero of Hell", type = "Weapon" }, isSpecial = false },
                    { skinId = "AUG | Hero of Hell", rarity = "Purple", weight = 1, skin = { weaponName = "AUG", skinName = "Hero of Hell", type = "Weapon" }, isSpecial = false },
                    { skinId = "Desert Eagle | Hero of Hell", rarity = "Pink", weight = 1, skin = { weaponName = "Desert Eagle", skinName = "Hero of Hell", type = "Weapon" }, isSpecial = false },
                    { skinId = "M4A4 | Hero of Hell", rarity = "Red", weight = 1, skin = { weaponName = "M4A4", skinName = "Hero of Hell", type = "Weapon" }, isSpecial = false }
                }
            end
        elseif isPkg then
            cDef.caseType = "Package"
            if not cDef.contents or #cDef.contents == 0 then
                local cName = cDef.name or cDef.Name or ""
                local parts = string.split(cName, " | ")
                local w = parts[1] or "AK-47"
                local s = parts[2] or "Lore"
                cDef.contents = {
                    { skinId = w .. " | " .. s, rarity = "Red", weight = 1, skin = { weaponName = w, skinName = s, type = "Weapon" }, isSpecial = false }
                }
            end
        else
            cDef.caseType = cDef.caseType or "Case"
            if not cDef.contents or #cDef.contents == 0 then
                local filler = {}
                pcall(function()
                    local allCases = CasesLib and CasesLib.GetCases()
                    if allCases then
                        for _, c in ipairs(allCases) do
                            if c ~= cDef and c.contents and #c.contents >= 5 then
                                for _, it in ipairs(c.contents) do
                                    if it.skin and (it.skin.weaponName or it.skin.name) then
                                        local w = it.skin.weaponName or it.skin.name
                                        local s = it.skin.skinName or it.skin.skin or "Stock"
                                        local r = it.rarity or "Blue"
                                        table.insert(filler, {
                                            rarity = r,
                                            weight = it.weight or 100,
                                            isSpecial = it.isSpecial or false,
                                            skinId = it.skinId or (w .. " | " .. s),
                                            skin = { weaponName = w, skinName = s, type = it.skin.type or "Weapon" }
                                        })
                                    end
                                end
                                break
                            end
                        end
                    end
                end)
                if #filler == 0 then
                    local defaultSkins = {
                        { "AK-47", "Asiimov", "Red" },
                        { "M4A4", "Howl", "Red" },
                        { "AWP", "Dragon Lore", "Red" },
                        { "Desert Eagle", "Printstream", "Pink" },
                        { "USP-S", "Kill Confirmed", "Red" },
                        { "Glock-18", "Water Elemental", "Purple" }
                    }
                    for _, ds in ipairs(defaultSkins) do
                        table.insert(filler, {
                            rarity = ds[3],
                            weight = 100,
                            isSpecial = false,
                            skinId = ds[1] .. " | " .. ds[2],
                            skin = { weaponName = ds[1], skinName = ds[2], type = "Weapon" }
                        })
                    end
                end
                cDef.contents = filler
            end
        end
        if wonItem and cDef.contents then
            local found = false
            for _, entry in ipairs(cDef.contents) do
                if entry.skin and entry.skin.weaponName == wonItem.Name and entry.skin.skinName == wonItem.Skin then
                    found = true
                    break
                end
            end
            if not found then
                local mappedRarity = "Red"
                if wonItem.Type == "Melee" or wonItem.Type == "Glove" then
                    mappedRarity = "Special"
                elseif wonItem.Rarity == "Special" or wonItem.Rarity == "Extraordinary" then
                    mappedRarity = "Special"
                elseif wonItem.Rarity == "Classified" or wonItem.Rarity == "Pink" then
                    mappedRarity = "Pink"
                elseif wonItem.Rarity == "Restricted" or wonItem.Rarity == "Purple" then
                    mappedRarity = "Purple"
                elseif wonItem.Rarity == "Mil-Spec" or wonItem.Rarity == "Blue" then
                    mappedRarity = "Blue"
                end
                table.insert(cDef.contents, {
                    rarity = mappedRarity,
                    weight = 100,
                    isSpecial = (wonItem.Type == "Melee" or wonItem.Type == "Glove"),
                    skinId = wonItem.Name .. " | " .. wonItem.Skin,
                    skin = { weaponName = wonItem.Name, skinName = wonItem.Skin, type = wonItem.Type }
                })
            end
        end
    end

    local origOpenCaseContent = nil

    local function triggerItemNotification(item)
        if not item then return end
        pcall(function()
            local invMod = ReplicatedStorage:FindFirstChild("Interface") 
                and ReplicatedStorage.Interface:FindFirstChild("Screens") 
                and ReplicatedStorage.Interface.Screens:FindFirstChild("Menu") 
                and ReplicatedStorage.Interface.Screens.Menu:FindFirstChild("Inventory")
            if invMod then
                local InventoryModule = require(invMod)
                if InventoryModule then
                    if type(InventoryModule.QueueNewItemNotification) == "function" then
                        InventoryModule.QueueNewItemNotification(item)
                    elseif type(InventoryModule.ShowNewItemNotification) == "function" then
                        InventoryModule.ShowNewItemNotification(item)
                    end
                end
            end
        end)
        pcall(function()
            local routerMod = ReplicatedStorage:FindFirstChild("Database") 
                and ReplicatedStorage.Database:FindFirstChild("Security") 
                and ReplicatedStorage.Database.Security:FindFirstChild("Router")
            if routerMod then
                local Router = require(routerMod)
                if Router and type(Router.broadcastRouter) == "function" then
                    Router.broadcastRouter("RunInterfaceSound", "New Item Reveal")
                end
            end
        end)
        pcall(function()
            local pGui = LocalPlayer:FindFirstChild("PlayerGui")
            local mainGui = pGui and (pGui:FindFirstChild("MainGui") or pGui:FindFirstChild("Menu"))
            local menu = mainGui and (mainGui:FindFirstChild("Menu") or mainGui)
            if menu then
                for _, desc in ipairs(menu:GetDescendants()) do
                    if desc:IsA("GuiButton") and desc.Name == "Inventory" then
                        local alert = desc:FindFirstChild("Alert")
                        if alert then alert.Visible = true end
                    end
                end
            end
            if TabBadges and TabBadges["Inventory"] and TabBadges["Inventory"].Badge then
                TabBadges["Inventory"].Badge.Visible = true
            end
        end)
    end

    local function scanForStoreInternals()
        if not Store then return false end
        local getupv = (debug and (debug.getupvalues or debug.getupvals)) or getupvalues
        if not getupv then return false end

        local visited = {}
        local discoveredFns = {}

        local function inspectTable(t)
            if not isPlainTable(t) or isModuleOrClassTable(t) then return end
            if safeRawGet(t, "isPendingOpenRequest") ~= nil or safeRawGet(t, "isOpening") ~= nil then
                storeInternal.state = t
            end
            if safeRawGet(t, "isBulkOpening") ~= nil then
                storeInternal.bulkState = t
            end
        end

        local function exploreFn(fn, depth)
            if typeof(fn) ~= "function" or visited[fn] or (depth and depth > 8) then return end
            visited[fn] = true
            table.insert(discoveredFns, fn)

            local ok, uvs = pcall(getupv, fn)
            if not ok or typeof(uvs) ~= "table" then return end

            for _, u in pairs(uvs) do
                if isPlainTable(u) then
                    inspectTable(u)
                    for _, sub in pairs(u) do
                        if typeof(sub) == "function" then
                            exploreFn(sub, (depth or 0) + 1)
                        end
                    end
                elseif typeof(u) == "function" then
                    exploreFn(u, (depth or 0) + 1)
                end
            end
        end

        -- Direct deterministic extraction of Store internals via TryProcessResolvedCaseOpenQueue
        local tryProcessFn = Store.TryProcessResolvedCaseOpenQueue
        if not tryProcessFn then
            for _, name in pairs({"Start", "Initialize", "BeginOpenCaseRequest", "ClearPendingOpenCaseRequest", "OpenCaseContent", "OpenTab", "OpenCase"}) do
                if typeof(Store[name]) == "function" then
                    exploreFn(Store[name], 1)
                end
            end
            if typeof(origOpenCaseContent) == "function" then
                exploreFn(origOpenCaseContent, 1)
            end
            for _, fn in ipairs(discoveredFns) do
                if debug.getinfo(fn).name == "TryProcessResolvedCaseOpenQueue" then
                    tryProcessFn = fn
                    break
                end
            end
        end

        if tryProcessFn then
            storeInternal.tryProcess = tryProcessFn
            local ok, uvs = pcall(getupv, tryProcessFn)
            if ok and typeof(uvs) == "table" then
                local sJob = nil
                for _, u in pairs(uvs) do
                    if typeof(u) == "function" and (debug.getinfo(u).name == "StartResolvedCaseOpenJob") then
                        sJob = u
                        break
                    elseif isPlainTable(u) and not isModuleOrClassTable(u) then
                        if safeRawGet(u, "isOpening") == nil and safeRawGet(u, "isBulkOpening") == nil then
                            storeInternal.queue = u
                        end
                    end
                end
                if not sJob and typeof(uvs[6]) == "function" then
                    sJob = uvs[6]
                end
                if sJob then
                    storeInternal.startResolvedJob = sJob
                    local ok2, sJobUvs = pcall(getupv, sJob)
                    if ok2 and typeof(sJobUvs) == "table" then
                        if typeof(sJobUvs[3]) == "function" then
                            storeInternal.bulkOpen = sJobUvs[3]
                        end
                        if typeof(sJobUvs[4]) == "function" then
                            local fName = debug.getinfo(sJobUvs[4]).name or ""
                            if fName ~= "ResetProgressBar" and not string.find(fName, "Reset") then
                                storeInternal.openCase = sJobUvs[4]
                            end
                        end
                        if not storeInternal.openCase or not storeInternal.bulkOpen then
                            for _, su in pairs(sJobUvs) do
                                if typeof(su) == "function" then
                                    local ok3, tUvs = pcall(getupv, su)
                                    if ok3 and typeof(tUvs) == "table" then
                                        for _, tu in pairs(tUvs) do
                                            if typeof(tu) == "table" then
                                                if rawget(tu, "isBulkOpening") ~= nil and not storeInternal.bulkOpen then
                                                    storeInternal.bulkOpen = su
                                                    storeInternal.bulkState = tu
                                                elseif rawget(tu, "isOpening") ~= nil and rawget(tu, "isBulkOpening") == nil and not storeInternal.openCase then
                                                    local fName = debug.getinfo(su).name or ""
                                                    if fName ~= "ResetProgressBar" and not string.find(fName, "Reset") then
                                                        storeInternal.openCase = su
                                                        storeInternal.state = tu
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        if storeInternal.openCase then
            local ok, uvs = pcall(getupv, storeInternal.openCase)
            if ok and typeof(uvs) == "table" then
                if typeof(uvs[2]) == "table" and rawget(uvs[2], "isOpening") ~= nil then
                    storeInternal.state = uvs[2]
                end
                for _, u in pairs(uvs) do
                    if typeof(u) == "function" then
                        local fnName = debug.getinfo(u).name or ""
                        if fnName == "RunScrollAnimation" or string.find(fnName, "Scroll") then
                            storeInternal.runScrollAnimation = u
                        end
                    elseif typeof(u) == "table" and rawget(u, "isOpening") ~= nil and not storeInternal.state then
                        storeInternal.state = u
                    end
                end
            end
        end

        if typeof(Store.BeginOpenCaseRequest) == "function" then
            local ok, uvs = pcall(getupv, Store.BeginOpenCaseRequest)
            if ok and typeof(uvs) == "table" then
                for _, u in pairs(uvs) do
                    if isPlainTable(u) and not isModuleOrClassTable(u) and safeRawGet(u, "isOpening") == nil and safeRawGet(u, "isPendingOpenRequest") == nil then
                        storeInternal.pending = u
                    end
                end
            end
        end

        return storeInternal.openCase ~= nil or storeInternal.state ~= nil
    end

    scanForStoreInternals()

    pcall(function()
        local okCSC, CSC = pcall(require, ReplicatedStorage:WaitForChild("Controllers"):WaitForChild("CaseSceneController"))
        if okCSC and CSC and CSC.TransitionToUnboxing then
            local origTransition = CSC.TransitionToUnboxing
            CSC.TransitionToUnboxing = function(cb)
                if cb and typeof(cb) == "function" then
                    local executed = false
                    local function safeCb(...)
                        if not executed then
                            executed = true
                            return cb(...)
                        end
                    end
                    task.delay(1.5, function()
                        if not executed and isUnboxingActive then
                            safeCb()
                        end
                    end)
                    local ok, err = pcall(origTransition, safeCb)
                    if not ok then
                        safeCb()
                    end
                else
                    return origTransition(cb)
                end
            end
        end
    end)

    -- Cases and packages are only added if explicitly added by the user in Memesense


    local function resolveValidCaseId(caseDef, fallbackId)
        if fallbackId and typeof(fallbackId) == "string" and CasesLib and CasesLib.GetCase and CasesLib.GetCase(fallbackId) then
            return fallbackId
        end
        if caseDef then
            if caseDef.caseId and CasesLib and CasesLib.GetCase and CasesLib.GetCase(caseDef.caseId) then
                return caseDef.caseId
            end
            if caseDef.name and CasesLib and CasesLib.GetCaseByName then
                local byName = CasesLib.GetCaseByName(caseDef.name)
                if byName and byName.caseId and CasesLib and CasesLib.GetCase and CasesLib.GetCase(byName.caseId) then
                    return byName.caseId
                end
            end
            if caseDef.caseId and CasesLib and CasesLib.GetCaseByName then
                local byName = CasesLib.GetCaseByName(caseDef.caseId)
                if byName and byName.caseId and CasesLib and CasesLib.GetCase and CasesLib.GetCase(byName.caseId) then
                    return byName.caseId
                end
            end
        end
        if fallbackId and typeof(fallbackId) == "string" and CasesLib and CasesLib.GetCaseByName then
            local byName = CasesLib.GetCaseByName(fallbackId)
            if byName and byName.caseId then return byName.caseId end
        end
        local all = CasesLib and CasesLib.GetCases and CasesLib.GetCases()
        if all and #all > 0 then
            return all[1].caseId
        end
        return "Revolver Case"
    end

    if Store and Store.OpenCaseContent then
        origOpenCaseContent = Store.OpenCaseContent
        Store.OpenCaseContent = function(s14, s15, s16)
            if CasesLib then
                currentCaseState.caseDef = (CasesLib.GetCase and CasesLib.GetCase(s14)) or (CasesLib.GetCaseByName and CasesLib.GetCaseByName(s14))
            end
            currentCaseState.caseId = s14
            currentCaseState.state = s15
            if not currentCaseState.caseDef and CasesLib and CasesLib.GetCase then
                currentCaseState.caseDef = CasesLib.GetCase(s14)
            end
            if currentCaseState.caseDef then
                local cd = currentCaseState.caseDef
                if (cd.name and string.find(cd.name, "Console")) or (cd.caseId and string.find(cd.caseId, "console")) then
                    cd.caseType = "Console"
                elseif (cd.name and string.find(cd.name, "Charm")) or (cd.caseId and string.find(cd.caseId, "charm")) then
                    cd.caseType = "Charm Capsule"
                elseif cd.caseType == "Package" or (cd.name and string.find(cd.name, " | ")) then
                    cd.caseType = "Package"
                else
                    cd.caseType = cd.caseType or "Case"
                end
                ensureCaseHasContents(cd)
            end

            if not s16 then
                for _, it in ipairs(MemeSenseInventory.Items) do
                    if (it.Type == "Case" or it.Type == "Package" or it.Type == "Capsule" or it.Type == "Charm Capsule" or it.Type == "Sticker Capsule")
                        and (it.caseId == s14 or it.Name == s14 or it.Skin == s14) then
                        s16 = it._id
                        currentCaseState.caseIdentifier = s16
                        break
                    end
                end
            end
            if not s16 and s15 == "Open" then
                s16 = "memesense_case_virtual_" .. sanitize((currentCaseState.caseDef and currentCaseState.caseDef.name) or s14)
                currentCaseState.caseIdentifier = s16
            end

            isUnboxingActive = false
            scanForStoreInternals()
            if storeInternal.state then
                storeInternal.state.isOpening = false
                storeInternal.state.isPendingOpenRequest = false
                storeInternal.state.pendingOpenRequestId = nil
                storeInternal.state.isQuickUnlock = false
                if storeInternal.state.renderConnection then
                    pcall(function() storeInternal.state.renderConnection:Disconnect() end)
                    storeInternal.state.renderConnection = nil
                end
                if storeInternal.state.viewportConnection then
                    pcall(function() storeInternal.state.viewportConnection:Disconnect() end)
                    storeInternal.state.viewportConnection = nil
                end
                if storeInternal.state.currentTween then
                    pcall(function() storeInternal.state.currentTween:Cancel() end)
                    storeInternal.state.currentTween = nil
                end
                if storeInternal.state.currentZoomTween then
                    pcall(function() storeInternal.state.currentZoomTween:Cancel() end)
                    storeInternal.state.currentZoomTween = nil
                end
            end
            if storeInternal.pending and not isModuleOrClassTable(storeInternal.pending) then
                for k, _ in pairs(storeInternal.pending) do
                    if typeof(k) == "string" or typeof(k) == "number" then
                        storeInternal.pending[k] = nil
                    end
                end
            end
            if storeInternal.queue and not isModuleOrClassTable(storeInternal.queue) then
                for idx = #storeInternal.queue, 1, -1 do
                    table.remove(storeInternal.queue, idx)
                end
            end

            pcall(function()
                for i = 1, 100 do
                    Store.ClearPendingOpenCaseRequest(tostring(i))
                end
            end)

            if scanAndAttachOpenButtons then
                task.defer(scanAndAttachOpenButtons)
            end

            return origOpenCaseContent(s14, s15, s16)
        end
    end

    local function getMenuRoot()
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not pGui then return nil, nil end
        local mainGui = pGui:FindFirstChild("MainGui") or pGui:FindFirstChild("Menu")
        if mainGui then
            local menu = mainGui:FindFirstChild("Menu")
            if menu then return menu, mainGui end
            return mainGui, mainGui
        end
        for _, desc in ipairs(pGui:GetChildren()) do
            if desc:IsA("ScreenGui") then
                local m = desc:FindFirstChild("Menu")
                if m then return m, desc end
                if desc:FindFirstChild("Store") or desc:FindFirstChild("Inventory") then
                    return desc, desc
                end
            end
        end
        return nil, nil
    end

    local function detectCurrentCaseFromUI()
        if currentCaseState.caseDef then
            return currentCaseState.caseDef
        end
        if currentCaseState.caseId then
            local c = (CasesLib and CasesLib.GetCase and CasesLib.GetCase(currentCaseState.caseId))
                or (CasesLib and CasesLib.GetCaseByName and CasesLib.GetCaseByName(currentCaseState.caseId))
            if c then return c end
        end

        local menu, mainGui = getMenuRoot()
        local store = menu and menu:FindFirstChild("Store")
        local caseContent = store and store:FindFirstChild("CaseContent")

        if caseContent and caseContent.Visible then
            local container = caseContent:FindFirstChild("Main")
                and caseContent.Main:FindFirstChild("CaseContent")
                and caseContent.Main.CaseContent:FindFirstChild("Container")
            if container then
                local sampleItemNames = {}
                for _, itemFrame in ipairs(container:GetChildren()) do
                    if itemFrame:IsA("Frame") or itemFrame:IsA("GuiObject") then
                        local footer = itemFrame:FindFirstChild("Bottom") and itemFrame.Bottom:FindFirstChild("Footer")
                        local wName = footer and footer:FindFirstChild("WeaponName") and footer.WeaponName.Text
                        local sName = footer and footer:FindFirstChild("SkinName") and footer.SkinName.Text
                        if wName and sName and wName ~= "" and sName ~= "" then
                            table.insert(sampleItemNames, { weapon = wName, skin = sName })
                            if #sampleItemNames >= 2 then break end
                        end
                    end
                end

                if #sampleItemNames > 0 and CasesLib and CasesLib.GetCases then
                    local ok, allCases = pcall(CasesLib.GetCases)
                    if ok and allCases then
                        for _, c in ipairs(allCases) do
                            if c.contents then
                                local matchCount = 0
                                for _, sample in ipairs(sampleItemNames) do
                                    for _, cItem in ipairs(c.contents) do
                                        local sWeapon = cItem.skin and (cItem.skin.weaponName or cItem.skin.name)
                                        local sSkin = cItem.skin and (cItem.skin.skinName or cItem.skin.skin)
                                        if sWeapon == sample.weapon and sSkin == sample.skin then
                                            matchCount = matchCount + 1
                                            break
                                        end
                                    end
                                end
                                if matchCount >= 1 then
                                    return c
                                end
                            end
                        end
                    end
                end
            end
        end

        for _, item in ipairs(MemeSenseInventory.Items) do
            if (item.Type == "Case" or item.Type == "Package") and item.caseId and CasesLib then
                local c = (CasesLib.GetCase and CasesLib.GetCase(item.caseId)) or (CasesLib.GetCaseByName and CasesLib.GetCaseByName(item.caseId))
                if c then return c end
            end
        end

        if CasesLib and CasesLib.GetCases then
            local ok, clist = pcall(CasesLib.GetCases)
            if ok and clist and #clist > 0 then
                return clist[1]
            end
        end
        return nil
    end

    local scanAndAttachOpenButtons = nil
    local dismissCaseOpenUI = nil
    local lastDeletedCaseIds = {}

    local function forceRefreshAllInventoryUIs(deletedIdList, caseNameStr)
        deletedIdList = deletedIdList or lastDeletedCaseIds or {}

        -- 1. Remove deleted case button from Bloxstrike's inventory UI immediately
        pcall(function()
            local menu, mainGui = getMenuRoot()
            local pGui = LocalPlayer:FindFirstChild("PlayerGui")
            local invFrame = (menu and menu:FindFirstChild("Inventory")) or (mainGui and mainGui:FindFirstChild("Inventory")) or (pGui and pGui:FindFirstChild("Inventory", true))
            if invFrame then
                local container = invFrame:FindFirstChild("Container", true)
                if container then
                    for _, child in ipairs(container:GetChildren()) do
                        if child:IsA("GuiObject") and child.Name ~= "UIGridLayout" and child.Name ~= "UIListLayout" and child.Name ~= "UIPadding" and child.Name ~= "Title" and child.Name ~= "Label" then
                            local shouldRemove = false
                            if table.find(deletedIdList, child.Name) then
                                shouldRemove = true
                            end
                            if not shouldRemove and caseNameStr and caseNameStr ~= "" then
                                local footer = child:FindFirstChild("Footer", true) or child:FindFirstChild("Bottom")
                                local wLabel = (footer and footer:FindFirstChild("WeaponName")) or child:FindFirstChild("WeaponName", true)
                                local sLabel = (footer and footer:FindFirstChild("SkinName")) or child:FindFirstChild("SkinName", true)
                                local wText = wLabel and wLabel.Text
                                local sText = sLabel and sLabel.Text
                                if (wText and (wText == caseNameStr or string.find(wText, caseNameStr))) or (sText and (sText == caseNameStr or string.find(sText, caseNameStr))) then
                                    shouldRemove = true
                                end
                            end
                            if shouldRemove then
                                child:Destroy()
                            end
                        end
                    end
                end
            end
        end)

        -- 2. Trigger Bloxstrike's internal Inventory module update
        pcall(function()
            local okInv, InvModule = pcall(require, ReplicatedStorage:WaitForChild("Interface"):WaitForChild("Screens"):WaitForChild("Menu"):WaitForChild("Inventory"))
            if okInv and InvModule then
                local invData = (DataController and DataController.Get and DataController.Get(LocalPlayer, "Inventory")) or {}
                if InvModule.UpdateInventory then
                    pcall(InvModule.UpdateInventory, invData)
                end
                if InvModule.UpdateInventoryFilter then
                    pcall(InvModule.UpdateInventoryFilter)
                end
            end
        end)

        -- 3. Broadcast ResetInventoryToGrid so Bloxstrike's router listeners update
        pcall(function()
            if Router and Router.broadcastRouter then
                Router.broadcastRouter("ResetInventoryToGrid")
            end
        end)

        -- 4. Update Memesense's internal inventory UI
        pcall(function()
            if refreshGridItems then
                refreshGridItems()
            end
            if MemeSenseInventory and MemeSenseInventory.RefreshUI then
                MemeSenseInventory.RefreshUI()
            end
        end)

        -- Defer and delay follow-up checks to ensure tab transitions don't drop removal
        task.defer(function()
            pcall(function()
                local okInv, InvModule = pcall(require, ReplicatedStorage:WaitForChild("Interface"):WaitForChild("Screens"):WaitForChild("Menu"):WaitForChild("Inventory"))
                if okInv and InvModule and InvModule.UpdateInventoryFilter then
                    InvModule.UpdateInventoryFilter()
                end
                if refreshGridItems then refreshGridItems() end
                if MemeSenseInventory and MemeSenseInventory.RefreshUI then MemeSenseInventory.RefreshUI() end
            end)
        end)
        task.delay(0.15, function()
            pcall(function()
                local okInv, InvModule = pcall(require, ReplicatedStorage:WaitForChild("Interface"):WaitForChild("Screens"):WaitForChild("Menu"):WaitForChild("Inventory"))
                if okInv and InvModule and InvModule.UpdateInventoryFilter then
                    InvModule.UpdateInventoryFilter()
                end
                if refreshGridItems then refreshGridItems() end
                if MemeSenseInventory and MemeSenseInventory.RefreshUI then MemeSenseInventory.RefreshUI() end
            end)
        end)
    end

    -- Listen for Bloxstrike Inventory screen becoming visible to immediately refresh filter
    pcall(function()
        task.spawn(function()
            local menu = getMenuRoot()
            local invFrame = menu and menu:FindFirstChild("Inventory")
            if not invFrame then
                local pGui = LocalPlayer:FindFirstChild("PlayerGui")
                invFrame = pGui and pGui:FindFirstChild("Inventory", true)
            end
            if invFrame then
                invFrame:GetPropertyChangedSignal("Visible"):Connect(function()
                    if invFrame.Visible then
                        pcall(function()
                            local okInv, InvModule = pcall(require, ReplicatedStorage:WaitForChild("Interface"):WaitForChild("Screens"):WaitForChild("Menu"):WaitForChild("Inventory"))
                            if okInv and InvModule and InvModule.UpdateInventoryFilter then
                                InvModule.UpdateInventoryFilter()
                            end
                        end)
                        pcall(function()
                            if refreshGridItems then refreshGridItems() end
                            if MemeSenseInventory and MemeSenseInventory.RefreshUI then MemeSenseInventory.RefreshUI() end
                        end)
                    end
                end)
            end
        end)
    end)

    dismissCaseOpenUI = function(restoreToInventory)
        isUnboxingActive = false
        scanForStoreInternals()
        if storeInternal.state then
            storeInternal.state.isPendingOpenRequest = false
            storeInternal.state.pendingOpenRequestId = nil
            storeInternal.state.isOpening = false
            storeInternal.state.isQuickUnlock = false
            storeInternal.state.currentInventoryItem = nil
            storeInternal.state.currentCaseIdentifier = nil
            if storeInternal.state.renderConnection then
                pcall(function() storeInternal.state.renderConnection:Disconnect() end)
                storeInternal.state.renderConnection = nil
            end
            if storeInternal.state.viewportConnection then
                pcall(function() storeInternal.state.viewportConnection:Disconnect() end)
                storeInternal.state.viewportConnection = nil
            end
            if storeInternal.state.currentTween then
                pcall(function() storeInternal.state.currentTween:Cancel() end)
                storeInternal.state.currentTween = nil
            end
            if storeInternal.state.currentZoomTween then
                pcall(function() storeInternal.state.currentZoomTween:Cancel() end)
                storeInternal.state.currentZoomTween = nil
            end
        end
        if storeInternal.pending and not isModuleOrClassTable(storeInternal.pending) then
            for k, _ in pairs(storeInternal.pending) do
                if typeof(k) == "string" or typeof(k) == "number" then
                    storeInternal.pending[k] = nil
                end
            end
        end
        if storeInternal.queue and not isModuleOrClassTable(storeInternal.queue) then
            for idx = #storeInternal.queue, 1, -1 do
                table.remove(storeInternal.queue, idx)
            end
        end

        local menu, mainGui = getMenuRoot()
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        local storeUI = (menu and menu:FindFirstChild("Store")) or (pGui and pGui:FindFirstChild("Store", true))
        local caseContent = (storeUI and storeUI:FindFirstChild("CaseContent")) or (pGui and pGui:FindFirstChild("CaseContent", true))
        local openCaseUI = (menu and menu:FindFirstChild("OpenCase")) or (mainGui and mainGui:FindFirstChild("OpenCase", true)) or (pGui and pGui:FindFirstChild("OpenCase", true))
        local okCSC, CSC = pcall(require, ReplicatedStorage:WaitForChild("Controllers"):WaitForChild("CaseSceneController"))
        local okMS, MenuState = pcall(require, ReplicatedStorage:WaitForChild("Interface"):WaitForChild("MenuState"))

        if openCaseUI then
            openCaseUI.Visible = false
            for _, child in ipairs(openCaseUI:GetChildren()) do
                if child:IsA("GuiObject") then
                    if child.Name == "CanvasGroup" or child.Name == "Zoom" or child.Name == "Line" then
                        child.Visible = false
                    end
                end
            end
        end

        if caseContent then
            caseContent.Visible = false
        end

        if okCSC and CSC and CSC.HideCaseScene then
            pcall(CSC.HideCaseScene)
        end

        if storeUI then
            if storeUI:FindFirstChild("Tabs") and storeUI.Tabs:FindFirstChild("Container") then
                storeUI.Tabs.Container.Visible = true
            end
            if storeUI:FindFirstChild("Top") then
                storeUI.Top.Visible = true
            end
            if restoreToInventory then
                storeUI.Visible = false
            end
        end

        pcall(function()
            local mRoot, mGui = getMenuRoot()
            local function restoreTop(m)
                if not m then return end
                if m:FindFirstChild("Top") then
                    m.Top.Visible = true
                    if m.Top:FindFirstChild("Bottom") then m.Top.Bottom.Visible = true end
                    if m.Top:FindFirstChild("Top") then m.Top.Top.Visible = true end
                end
                if m:FindFirstChild("GameDashboard") then
                    m.GameDashboard.Visible = true
                end
            end
            restoreTop(mRoot)
            restoreTop(mGui and mGui:FindFirstChild("Menu"))
            local pGui = LocalPlayer:FindFirstChild("PlayerGui")
            if pGui then
                local top = pGui:FindFirstChild("Top", true)
                if top and top.Parent and top.Parent.Name == "Menu" then
                    top.Visible = true
                    if top:FindFirstChild("Bottom") then top.Bottom.Visible = true end
                    if top:FindFirstChild("Top") then top.Top.Visible = true end
                end
                local gd = pGui:FindFirstChild("GameDashboard", true)
                if gd and gd.Parent and gd.Parent.Name == "Menu" then
                    gd.Visible = true
                end
            end
        end)

        if restoreToInventory then
            pcall(function()
                local okTop, TopModule = pcall(require, ReplicatedStorage:WaitForChild("Interface"):WaitForChild("Screens"):WaitForChild("Menu"):WaitForChild("Top"))
                if okTop and TopModule and TopModule.openFrame then
                    pcall(TopModule.openFrame, "Inventory")
                end
            end)
            if okMS and MenuState and MenuState.SetScreen then
                pcall(MenuState.SetScreen, nil)
                pcall(MenuState.SetScreen, "Inventory")
            end
            pcall(function()
                if Router and Router.broadcastRouter then
                    Router.broadcastRouter("ResetInventoryToGrid")
                end
            end)
        end

        forceRefreshAllInventoryUIs(lastDeletedCaseIds, (currentCaseState.caseDef and currentCaseState.caseDef.name) or currentCaseState.caseId)

        if pGui then
            local sweep = pGui:FindFirstChild("ConsoleInspectSweep", true)
            if sweep then sweep:Destroy() end
        end
    end

    local function attachCloseBtn(btn)
        if not btn or not btn:IsA("GuiButton") then return end
        if btn:GetAttribute("LocalCloseAttached") then return end
        btn:SetAttribute("LocalCloseAttached", true)

        local function doClose()
            dismissCaseOpenUI(true)
        end

        btn.MouseButton1Click:Connect(doClose)
        btn.Activated:Connect(doClose)
    end

    local function attachOpenBtn(btn)
        if not btn or not btn:IsA("GuiButton") then return end
        if btn:GetAttribute("LocalUnboxAttached") then return end
        btn:SetAttribute("LocalUnboxAttached", true)

        local function resetStoreOpenState()
            scanForStoreInternals()
            if storeInternal.state then
                storeInternal.state.isPendingOpenRequest = false
                storeInternal.state.pendingOpenRequestId = nil
                storeInternal.state.isOpening = false
                storeInternal.state.isQuickUnlock = false
            end
            if storeInternal.pending and not isModuleOrClassTable(storeInternal.pending) then
                for k, _ in pairs(storeInternal.pending) do
                    if typeof(k) == "string" or typeof(k) == "number" then
                        storeInternal.pending[k] = nil
                    end
                end
            end
        end

        btn.MouseButton1Down:Connect(function()
            resetStoreOpenState()
            if not currentCaseState.caseDef or not currentCaseState.caseDef.contents then
                currentCaseState.caseDef = detectCurrentCaseFromUI()
            end
        end)

        btn.MouseButton1Click:Connect(function()
            resetStoreOpenState()
            if not currentCaseState.caseDef or not currentCaseState.caseDef.contents then
                currentCaseState.caseDef = detectCurrentCaseFromUI()
            end
            task.delay(0.4, function()
                if not isUnboxingActive and (os.clock() - lastUnboxTimestamp > 0.5) then
                    startLocalUnboxing("ButtonBackup")
                end
            end)
        end)
    end

    scanAndAttachOpenButtons = function()
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not pGui then return end
        for _, desc in ipairs(pGui:GetDescendants()) do
            if desc:IsA("GuiButton") and desc.Name == "Open" then
                local parent = desc.Parent
                if parent and parent.Name == "CenterButtons" then
                    attachOpenBtn(desc)
                end
            end
        end
    end

    task.spawn(function()
        task.wait(0.5)
        scanAndAttachOpenButtons()
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        if pGui then
            pGui.DescendantAdded:Connect(function(desc)
                if desc:IsA("GuiButton") and desc.Name == "Open" then
                    local parent = desc.Parent
                    if parent and parent.Name == "CenterButtons" then
                        task.wait(0.05)
                        attachOpenBtn(desc)
                    end
                end
            end)
        end
        while true do
            task.wait(1.5)
            scanAndAttachOpenButtons()
        end
    end)

    local function rollCaseItem(caseDef)
        if not caseDef or not caseDef.contents or #caseDef.contents == 0 then
            pcall(function()
                local allCases = CasesLib and CasesLib.GetCases()
                if allCases then
                    for _, c in ipairs(allCases) do
                        if c.contents and #c.contents >= 5 then
                            caseDef = c
                            break
                        end
                    end
                end
            end)
        end

        local chosenEntry = nil
        if caseDef and caseDef.contents and #caseDef.contents > 0 then
            chosenEntry = caseDef.contents[math.random(1, #caseDef.contents)]
        end

        local weaponName = ""
        local skinName = ""
        local itemType = "Weapon"
        local rarity = (chosenEntry and chosenEntry.rarity) or "Covert"

        if chosenEntry then
            if chosenEntry.skin and typeof(chosenEntry.skin) == "table" then
                weaponName = chosenEntry.skin.weaponName or chosenEntry.skin.name or ""
                skinName = chosenEntry.skin.skinName or chosenEntry.skin.skin or "Asiimov"
                itemType = chosenEntry.skin.type or getWeaponClass(weaponName)
            elseif chosenEntry.skinId then
                local parts = string.split(chosenEntry.skinId, " | ")
                weaponName = parts[1] or chosenEntry.skinId
                skinName = parts[2] or "Asiimov"
                itemType = getWeaponClass(weaponName)
            else
                weaponName = chosenEntry.name or chosenEntry.weaponName or "AWP"
                skinName = chosenEntry.skin or chosenEntry.skinName or "Asiimov"
                itemType = getWeaponClass(weaponName)
            end
        else
            weaponName = "AWP"
            skinName = "Asiimov"
            itemType = "Rifle"
            rarity = "Covert"
        end

        if not weaponName or weaponName == "" then weaponName = "AWP" end
        if not skinName or skinName == "" or skinName == "Stock" then skinName = "Asiimov" end

        local floatVal = math.random(1, 800) / 10000
        local isKG = (itemType == "Melee" or itemType == "Glove")
        local uniqueId = "memesense_unboxed_" .. sanitize(weaponName) .. "_" .. sanitize(skinName) .. "_" .. HttpService:GenerateGUID(false)

        local wonItem = {
            _id = uniqueId,
            Type = itemType,
            Name = weaponName,
            Skin = skinName,
            Serial = 1,
            Rarity = rarity,
            RarityColor = getRarityColor(rarity, isKG),
            Float = floatVal,
            StatTrack = false,
            StatTrak = false,
            KillCount = 0,
            IsTradeable = false,
            NameTag = false,
            Charm = false,
            Pattern = math.random(1, 999),
            Equipped = false,
            Icon = (weaponName == "Charm" and availableSkinsCache and availableSkinsCache["Charm"] and availableSkinsCache["Charm"][skinName] and (availableSkinsCache["Charm"][skinName].imageAssetId or (availableSkinsCache["Charm"][skinName].charmImages and availableSkinsCache["Charm"][skinName].charmImages[1] and availableSkinsCache["Charm"][skinName].charmImages[1].assetId)))
                or (getSkinSpecificIcon and getSkinSpecificIcon(weaponName, skinName))
                or (getStockWeaponIcon and getStockWeaponIcon(weaponName))
                or "",
            CustomName = "",
            Stickers = {},
            MetaData = {
                Origin = "Unboxed",
                CreatedAt = os.time(),
                LastTradeAt = 0,
                Owner = LocalPlayer.UserId,
                OriginalOwner = LocalPlayer.UserId,
                TradeHistory = {}
            }
        }
        return wonItem
    end

    local function runFallbackUnboxAnimation(caseDef, wonItems, caseIdent)
        local menu, mainGui = getMenuRoot()
        local openCaseUI = (menu and menu:FindFirstChild("OpenCase")) or (mainGui and mainGui:FindFirstChild("OpenCase", true))
        local storeUI = menu and menu:FindFirstChild("Store")
        local caseContent = storeUI and storeUI:FindFirstChild("CaseContent")

        local okCSC, CSC = pcall(require, ReplicatedStorage:WaitForChild("Controllers"):WaitForChild("CaseSceneController"))
        local okMS, MenuState = pcall(require, ReplicatedStorage:WaitForChild("Interface"):WaitForChild("MenuState"))

        if caseContent then caseContent.Visible = false end
        pcall(function()
            if menu and menu:FindFirstChild("Top") then
                menu.Top.Visible = false
                if menu.Top:FindFirstChild("Bottom") then menu.Top.Bottom.Visible = false end
            end
            if menu and menu:FindFirstChild("GameDashboard") then
                menu.GameDashboard.Visible = false
            end
        end)
        if okCSC and CSC and CSC.TransitionToUnboxing then
            pcall(CSC.TransitionToUnboxing)
        end

        task.wait(0.8)

        local won = wonItems and wonItems[1]
        if openCaseUI then
            pcall(function()
                if openCaseUI:FindFirstChild("CaseName") then
                    openCaseUI.CaseName.Text = "Unlock " .. ((caseDef and caseDef.name) or "Case")
                end
                openCaseUI.Visible = true
                if storeUI then storeUI.Visible = false end
                local contents = openCaseUI:FindFirstChild("Contents")
                local closeBtn = contents and contents:FindFirstChild("Close")
                if closeBtn and closeBtn:FindFirstChild("TextLabel") then
                    closeBtn.TextLabel.Text = "CLOSE"
                end
            end)

            local ranScroll = false
            if storeInternal.runScrollAnimation and caseDef and won then
                local okRun = pcall(function()
                    if storeInternal.state then storeInternal.state.isOpening = true end
                    storeInternal.runScrollAnimation(caseDef, won)
                    ranScroll = true
                end)
            end

            if not ranScroll then
                local cg = openCaseUI:FindFirstChild("CanvasGroup")
                local container = cg and cg:FindFirstChild("Container")
                if container then
                    pcall(function()
                        local TweenService = game:GetService("TweenService")
                        local target = math.random(3000, 5000)
                        local tw = TweenService:Create(container, TweenInfo.new(4.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            CanvasPosition = Vector2.new(target, 0)
                        })
                        tw:Play()
                        tw.Completed:Wait()
                    end)
                else
                    task.wait(3.5)
                end
            end
        else
            task.wait(3.0)
        end

        if openCaseUI then openCaseUI.Visible = false end
        if okCSC and CSC and CSC.HideCaseScene then pcall(CSC.HideCaseScene) end
        if storeUI then
            if storeUI:FindFirstChild("Tabs") and storeUI.Tabs:FindFirstChild("Container") then
                storeUI.Tabs.Container.Visible = true
            end
            if storeUI:FindFirstChild("Top") then storeUI.Top.Visible = true end
            storeUI.Visible = false
        end
        pcall(function()
            local mRoot, mGui = getMenuRoot()
            local function restoreTop(m)
                if not m then return end
                if m:FindFirstChild("Top") then
                    m.Top.Visible = true
                    if m.Top:FindFirstChild("Bottom") then m.Top.Bottom.Visible = true end
                    if m.Top:FindFirstChild("Top") then m.Top.Top.Visible = true end
                end
                if m:FindFirstChild("GameDashboard") then
                    m.GameDashboard.Visible = true
                end
            end
            restoreTop(mRoot)
            restoreTop(mGui and mGui:FindFirstChild("Menu"))
            local pGui = LocalPlayer:FindFirstChild("PlayerGui")
            if pGui then
                local top = pGui:FindFirstChild("Top", true)
                if top and top.Parent and top.Parent.Name == "Menu" then
                    top.Visible = true
                    if top:FindFirstChild("Bottom") then top.Bottom.Visible = true end
                    if top:FindFirstChild("Top") then top.Top.Visible = true end
                end
                local gd = pGui:FindFirstChild("GameDashboard", true)
                if gd and gd.Parent and gd.Parent.Name == "Menu" then
                    gd.Visible = true
                end
            end
        end)
        pcall(function()
            local okTop, TopModule = pcall(require, ReplicatedStorage:WaitForChild("Interface"):WaitForChild("Screens"):WaitForChild("Menu"):WaitForChild("Top"))
            if okTop and TopModule and TopModule.openFrame then
                pcall(TopModule.openFrame, "Inventory")
            end
        end)
        if okMS and MenuState and MenuState.SetScreen then
            pcall(MenuState.SetScreen, nil)
            pcall(MenuState.SetScreen, "Inventory")
        end
        pcall(function()
            if Router and Router.broadcastRouter then
                Router.broadcastRouter("ResetInventoryToGrid")
            end
        end)
        forceRefreshAllInventoryUIs(lastDeletedCaseIds, (caseDef and caseDef.name) or currentCaseState.caseId)

        isUnboxingActive = false
        if storeInternal.state then
            storeInternal.state.isOpening = false
        end

        if won then
            pcall(function()
                if Router and Router.broadcastRouter then
                    Router.broadcastRouter("WeaponInspect", won.Name, won.Skin, won.Float, won.StatTrack, won.NameTag, won.Charm, won.Stickers, won.Type, won.Pattern, won._id, won.Serial, won.IsTradeable)
                end
            end)
            pcall(triggerItemNotification, won)
        end
    end

    local function handleSequenceFinished(data)
        if refreshGridItems then pcall(refreshGridItems) end
        if MemeSenseInventory and MemeSenseInventory.RefreshUI then pcall(MemeSenseInventory.RefreshUI) end
        if dismissCaseOpenUI then
            dismissCaseOpenUI(true)
        else
            isUnboxingActive = false
            if storeInternal.state then
                storeInternal.state.isOpening = false
                storeInternal.state.isPendingOpenRequest = false
                storeInternal.state.pendingOpenRequestId = nil
                storeInternal.state.isQuickUnlock = false
                if storeInternal.state.renderConnection then
                    pcall(function() storeInternal.state.renderConnection:Disconnect() end)
                    storeInternal.state.renderConnection = nil
                end
            end
            pcall(function()
                local okTop, TopModule = pcall(require, ReplicatedStorage:WaitForChild("Interface"):WaitForChild("Screens"):WaitForChild("Menu"):WaitForChild("Top"))
                if okTop and TopModule and TopModule.openFrame then
                    pcall(TopModule.openFrame, "Inventory")
                end
            end)
            if okMS and MenuState and MenuState.SetScreen then
                pcall(MenuState.SetScreen, nil)
                pcall(MenuState.SetScreen, "Inventory")
            end
            pcall(function()
                if Router and Router.broadcastRouter then
                    Router.broadcastRouter("ResetInventoryToGrid")
                end
            end)
            forceRefreshAllInventoryUIs(lastDeletedCaseIds, (currentCaseState.caseDef and currentCaseState.caseDef.name) or currentCaseState.caseId)
        end
        if lastWonItem then
            local won = lastWonItem
            task.delay(0.1, function()
                pcall(function()
                    if Router and Router.broadcastRouter then
                        Router.broadcastRouter("WeaponInspect", won.Name, won.Skin, won.Float, won.StatTrack, won.NameTag, won.Charm, won.Stickers, won.Type, won.Pattern, won._id, won.Serial, won.IsTradeable)
                    end
                end)
                pcall(triggerItemNotification, won)
            end)
        end
    end

    local function replenishCaseIfLow(caseDef, realCaseId)
        -- Consumable inventory: opened cases are consumed and never automatically re-inserted
    end

    local function startLocalUnboxing(source, rawData)
        local now = os.clock()
        -- If isUnboxingActive is stuck from a previous run that never properly cleaned up,
        -- allow re-entry after 2 seconds instead of 0.5 to prevent permanent lockout
        if isUnboxingActive then
            if (now - lastUnboxTimestamp < 2.0) then return end
            -- Force reset the stuck state so we can proceed
            isUnboxingActive = false
            if storeInternal.state then
                storeInternal.state.isOpening = false
                storeInternal.state.isPendingOpenRequest = false
                storeInternal.state.pendingOpenRequestId = nil
                storeInternal.state.isQuickUnlock = false
            end
        end

        isUnboxingActive = true
        lastUnboxTimestamp = now

        local caseId = rawData and rawData.CaseId
        local caseDef = (caseId and CasesLib and (CasesLib.GetCase(caseId) or CasesLib.GetCaseByName(caseId)))
        if not caseDef and rawData and rawData.CaseIdentifiers and rawData.CaseIdentifiers[1] then
            local ci = unlockedDict[rawData.CaseIdentifiers[1]]
            if ci and ci.caseId and CasesLib then
                caseDef = CasesLib.GetCase(ci.caseId) or CasesLib.GetCaseByName(ci.caseId) or CasesLib.GetCaseByName(ci.Name)
            end
        end
        if not caseDef and currentCaseState.caseDef then
            caseDef = currentCaseState.caseDef
        end
        if not caseDef and currentCaseState.caseId and CasesLib then
            caseDef = CasesLib.GetCase(currentCaseState.caseId) or CasesLib.GetCaseByName(currentCaseState.caseId)
        end
        if not caseDef and detectCurrentCaseFromUI then
            caseDef = detectCurrentCaseFromUI()
        end

        local isCharm = (caseDef and (caseDef.caseType == "Charm Capsule" or (caseDef.name and string.find(caseDef.name, "Charm")) or (caseDef.Name and string.find(caseDef.Name, "Charm")) or (caseDef.caseId and string.find(caseDef.caseId, "charm"))))
        local isConsole = (caseDef and (caseDef.caseType == "Console" or (caseDef.name and string.find(caseDef.name, "Console")) or (caseDef.Name and string.find(caseDef.Name, "Console")) or (caseDef.caseId and string.find(caseDef.caseId, "console"))))
        local isPkg = (caseDef and (caseDef.caseType == "Package" or (caseDef.name and string.find(caseDef.name, " | ")) or (caseDef.Name and string.find(caseDef.Name, " | "))))

        pcall(function()
            local MenuState = require(ReplicatedStorage.Interface.MenuState)
            if MenuState.IsInspectActive() then MenuState.ExitInspect() end
            if not isCharm and MenuState.IsCaseSceneActive() then MenuState.ExitCaseScene() end
        end)

        scanForStoreInternals()

        pcall(function()
            local menu, mainGui = getMenuRoot()
            if menu then
                if menu:FindFirstChild("Top") then
                    menu.Top.Visible = false
                    if menu.Top:FindFirstChild("Bottom") then
                        menu.Top.Bottom.Visible = false
                    end
                end
                if menu:FindFirstChild("GameDashboard") then
                    menu.GameDashboard.Visible = false
                end
                if menu:FindFirstChild("Store") then
                    menu.Store.Visible = false
                end
            end
            if mainGui and mainGui:FindFirstChild("Menu") then
                local m = mainGui.Menu
                if m:FindFirstChild("Top") then
                    m.Top.Visible = false
                    if m.Top:FindFirstChild("Bottom") then
                        m.Top.Bottom.Visible = false
                    end
                end
                if m:FindFirstChild("GameDashboard") then
                    m.GameDashboard.Visible = false
                end
            end
            local pGui = LocalPlayer:FindFirstChild("PlayerGui")
            if pGui then
                local top = pGui:FindFirstChild("Top", true)
                if top and top.Parent and top.Parent.Name == "Menu" then
                    top.Visible = false
                    if top:FindFirstChild("Bottom") then
                        top.Bottom.Visible = false
                    end
                end
                local gd = pGui:FindFirstChild("GameDashboard", true)
                if gd and gd.Parent and gd.Parent.Name == "Menu" then
                    gd.Visible = false
                end
            end
        end)

        if caseDef then
            if isCharm then caseDef.caseType = "Charm Capsule"
            elseif isConsole then caseDef.caseType = "Console"
            elseif isPkg then caseDef.caseType = "Package"
            else caseDef.caseType = caseDef.caseType or "Case" end
            ensureCaseHasContents(caseDef)
        end

        local realCaseId = resolveValidCaseId(caseDef, caseId or currentCaseState.caseId)
        if not realCaseId then
            isUnboxingActive = false
            if storeInternal.state then
                storeInternal.state.isOpening = false
                storeInternal.state.isPendingOpenRequest = false
                storeInternal.state.pendingOpenRequestId = nil
                storeInternal.state.isQuickUnlock = false
            end
            return
        end

        local cInCases = CasesLib and CasesLib.GetCase and CasesLib.GetCase(realCaseId)
        if cInCases then
            if isCharm then cInCases.caseType = "Charm Capsule"
            elseif isConsole then cInCases.caseType = "Console"
            elseif isPkg then cInCases.caseType = "Package"
            else cInCases.caseType = cInCases.caseType or "Case" end
            ensureCaseHasContents(cInCases)
        end

        if not caseDef or not (CasesLib and CasesLib.GetCase and CasesLib.GetCase(caseDef.caseId or "")) then
            caseDef = cInCases or (CasesLib and CasesLib.GetCase and CasesLib.GetCase(realCaseId))
        end
        if caseDef then
            if isCharm then caseDef.caseType = "Charm Capsule"
            elseif isConsole then caseDef.caseType = "Console"
            elseif isPkg then caseDef.caseType = "Package"
            else caseDef.caseType = caseDef.caseType or "Case" end
            ensureCaseHasContents(caseDef)
        end
        if not caseDef then
            isUnboxingActive = false
            if storeInternal.state then
                storeInternal.state.isOpening = false
                storeInternal.state.isPendingOpenRequest = false
                storeInternal.state.pendingOpenRequestId = nil
                storeInternal.state.isQuickUnlock = false
            end
            return
        end

        local isBulk = (rawData and rawData.OpenType == "Bulk") or (rawData and rawData.CaseIdentifiers and #rawData.CaseIdentifiers > 1)
        local count = 1
        if rawData and rawData.CaseIdentifiers and #rawData.CaseIdentifiers > 1 then
            count = #rawData.CaseIdentifiers
        else
            pcall(function()
                local pGui = LocalPlayer:FindFirstChild("PlayerGui")
                local amtText = pGui and pGui.Menu.Menu.Store.CaseContent.Main.Bottom.Buttons.CenterButtons.Amount.Header.TextLabel.Text
                local n = tonumber(amtText)
                if n and n > 0 then count = n end
            end)
        end

        local wonItems = {}
        for _ = 1, count do
            local won = rollCaseItem(caseDef)
            if won then
                won.Equipped = false
                unlockedDict[won._id] = won
                table.insert(MemeSenseInventory.Items, won)
                table.insert(wonItems, won)
            end
        end

        if #wonItems > 0 then
            lastWonItem = wonItems[1]
            ensureCaseHasContents(caseDef, wonItems[1])
            if cInCases then
                ensureCaseHasContents(cInCases, wonItems[1])
            end
        end

        if #wonItems == 0 then
            isUnboxingActive = false
            if storeInternal.state then
                storeInternal.state.isOpening = false
                storeInternal.state.isPendingOpenRequest = false
                storeInternal.state.pendingOpenRequestId = nil
                storeInternal.state.isQuickUnlock = false
            end
            return
        end

        local caseIdent = (rawData and rawData.CaseIdentifiers and rawData.CaseIdentifiers[1]) or currentCaseState.caseIdentifier
        local deletedIds = {}
        local memeSenseCasesRemoved = 0

        -- 1. Remove exact ID matches from MemeSenseInventory.Items and unlockedDict
        if rawData and rawData.CaseIdentifiers then
            for _, id in ipairs(rawData.CaseIdentifiers) do
                unlockedDict[id] = nil
                injectedItemIds[id] = nil
                if not table.find(deletedIds, id) then
                    table.insert(deletedIds, id)
                end
                for idx = #MemeSenseInventory.Items, 1, -1 do
                    if MemeSenseInventory.Items[idx]._id == id then
                        table.remove(MemeSenseInventory.Items, idx)
                        memeSenseCasesRemoved = memeSenseCasesRemoved + 1
                        break
                    end
                end
            end
        end

        local function isMatchingCase(it)
            if not it then return false end
            if it._id == caseIdent then return true end
            if caseId and (it.caseId == caseId or it.Name == caseId or it.Skin == caseId) then return true end
            if it.caseId == realCaseId then return true end
            if caseDef and (it.Name == caseDef.name or it.Skin == caseDef.name or it.caseId == caseDef.caseId) then return true end
            if currentCaseState.caseId and (it.caseId == currentCaseState.caseId or it.Name == currentCaseState.caseId or it.Skin == currentCaseState.caseId) then return true end
            local sReal = string.lower(string.gsub(tostring(realCaseId or ""), "[^%w]", ""))
            local sDef = caseDef and string.lower(string.gsub(tostring(caseDef.name or caseDef.caseId or ""), "[^%w]", ""))
            local sItName = string.lower(string.gsub(tostring(it.Name or ""), "[^%w]", ""))
            local sItCaseId = string.lower(string.gsub(tostring(it.caseId or ""), "[^%w]", ""))
            if sReal ~= "" and (sItName == sReal or sItCaseId == sReal or string.find(sItName, sReal) or string.find(sReal, sItName)) then
                return true
            end
            if sDef and sDef ~= "" and (sItName == sDef or sItCaseId == sDef or string.find(sItName, sDef) or string.find(sDef, sItName)) then
                return true
            end
            return false
        end

        -- 2. ALWAYS remove matching cases from MemeSenseInventory.Items up to count!
        if memeSenseCasesRemoved < count then
            for idx = #MemeSenseInventory.Items, 1, -1 do
                local it = MemeSenseInventory.Items[idx]
                if (it.Type == "Case" or it.Type == "Package" or it.Type == "Capsule" or it.Type == "Charm Capsule" or it.Type == "Sticker Capsule" or string.find(tostring(it.Type or ""), "Case") or string.find(tostring(it.Name or ""), "Case"))
                    and isMatchingCase(it) then
                    if not table.find(deletedIds, it._id) then
                        table.insert(deletedIds, it._id)
                    end
                    unlockedDict[it._id] = nil
                    injectedItemIds[it._id] = nil
                    table.remove(MemeSenseInventory.Items, idx)
                    if not caseIdent then
                        caseIdent = it._id
                    end
                    memeSenseCasesRemoved = memeSenseCasesRemoved + 1
                    if memeSenseCasesRemoved >= count then
                        break
                    end
                end
            end
        end

        -- Instantly refresh MemeSense grid so the case card disappears immediately when unbox starts!
        if refreshGridItems then pcall(refreshGridItems) end
        if MemeSenseInventory and MemeSenseInventory.RefreshUI then pcall(MemeSenseInventory.RefreshUI) end

        if #deletedIds < count and DataController and DataController.Get then
            pcall(function()
                local dcInv = DataController.Get(LocalPlayer, "Inventory")
                if dcInv and typeof(dcInv) == "table" then
                    for _, it in pairs(dcInv) do
                        if it and (it.Type == "Case" or it.Type == "Package" or it.Type == "Capsule" or it.Type == "Charm Capsule" or it.Type == "Sticker Capsule") and isMatchingCase(it) then
                            if it._id and not table.find(deletedIds, it._id) then
                                table.insert(deletedIds, it._id)
                                if not caseIdent then
                                    caseIdent = it._id
                                end
                                if #deletedIds >= count then
                                    break
                                end
                            end
                        end
                    end
                end
            end)
        end

        if not caseIdent then
            caseIdent = "memesense_case_virtual_" .. sanitize((caseDef and caseDef.name) or realCaseId)
        end

        lastDeletedCaseIds = deletedIds
        currentCaseState.caseDef = caseDef
        currentCaseState.caseId = realCaseId

        pcall(DataController.ApplyInventoryDelta, LocalPlayer, wonItems, deletedIds)

        if MemeSenseInventory and MemeSenseInventory.SyncGame then
            pcall(MemeSenseInventory.SyncGame)
        end
        forceRefreshAllInventoryUIs(deletedIds, (caseDef and caseDef.name) or realCaseId)
        task.defer(function()
            forceRefreshAllInventoryUIs(deletedIds, (caseDef and caseDef.name) or realCaseId)
            if refreshGridItems then pcall(refreshGridItems) end
            if MemeSenseInventory and MemeSenseInventory.RefreshUI then pcall(MemeSenseInventory.RefreshUI) end
        end)
        task.delay(0.1, function()
            if refreshGridItems then pcall(refreshGridItems) end
            if MemeSenseInventory and MemeSenseInventory.RefreshUI then pcall(MemeSenseInventory.RefreshUI) end
        end)
        task.delay(0.25, function()
            if refreshGridItems then pcall(refreshGridItems) end
            if MemeSenseInventory and MemeSenseInventory.RefreshUI then pcall(MemeSenseInventory.RefreshUI) end
        end)

        local reqId = rawData and rawData.RequestId
        if storeInternal.state then
            storeInternal.state.isPendingOpenRequest = false
            storeInternal.state.pendingOpenRequestId = nil
            storeInternal.state.isQuickUnlock = false
            if storeInternal.state.renderConnection then
                pcall(function() storeInternal.state.renderConnection:Disconnect() end)
                storeInternal.state.renderConnection = nil
            end
        end
        if storeInternal.pending and reqId and not isModuleOrClassTable(storeInternal.pending) then
            storeInternal.pending[reqId] = nil
        end

        local isQuick = (rawData and rawData.OpenType == "Quick Open") or false
        local job = {
            CaseId = realCaseId,
            InventoryItems = wonItems,
            CaseIdentifier = caseIdent,
            IsQuickUnlock = isQuick,
            RequestId = reqId
        }

        pcall(function()
            local okCSC, CSC = pcall(require, ReplicatedStorage:WaitForChild("Controllers"):WaitForChild("CaseSceneController"))
            if okCSC and CSC.CancelConsoleOpening then
                pcall(CSC.CancelConsoleOpening)
            end
            local menu, mainGui = getMenuRoot()
            local openCase = (menu and menu:FindFirstChild("OpenCase")) or (mainGui and mainGui:FindFirstChild("OpenCase", true))
            if openCase then
                for _, child in ipairs(openCase:GetChildren()) do
                    if child:IsA("GuiObject") then
                        child.Visible = true
                    end
                end
                local contents = openCase:FindFirstChild("Contents")
                if contents then
                    for _, child in ipairs(contents:GetChildren()) do
                        if child:IsA("GuiObject") then
                            child.Visible = true
                        end
                    end
                    local closeBtn = contents:FindFirstChild("Close")
                    if closeBtn and closeBtn:FindFirstChild("TextLabel") then
                        closeBtn.TextLabel.Text = "CLOSE"
                    end
                end
                local cg = openCase:FindFirstChild("CanvasGroup")
                if cg then cg.Visible = true end
                local zoom = openCase:FindFirstChild("Zoom")
                if zoom then zoom.Visible = true end
                local line = openCase:FindFirstChild("Line")
                if line then line.Visible = true end
            end
            local pGui = LocalPlayer:FindFirstChild("PlayerGui")
            if pGui then
                local sweep = pGui:FindFirstChild("ConsoleInspectSweep", true)
                if sweep then sweep:Destroy() end
            end
        end)

        if storeInternal.state then
            storeInternal.state.isPendingOpenRequest = false
            storeInternal.state.pendingOpenRequestId = nil
            storeInternal.state.isQuickUnlock = false
            storeInternal.state.isOpening = true
            storeInternal.state.currentInventoryItem = wonItems[1]
        end

        local animationStarted = false

        local canUseOpenCase = storeInternal.openCase and typeof(storeInternal.openCase) == "function"
            and (debug.getinfo(storeInternal.openCase).name ~= "ResetProgressBar")
            and not string.find(debug.getinfo(storeInternal.openCase).name or "", "Reset")

        if isConsole then
            animationStarted = true
            task.delay(2.2, function()
                dismissCaseOpenUI(true)
                if wonItems and wonItems[1] then
                    local won = wonItems[1]
                    pcall(function()
                        if Router and Router.broadcastRouter then
                            Router.broadcastRouter("WeaponInspect", won.Name, won.Skin, won.Float, won.StatTrack, won.NameTag, won.Charm, won.Stickers, won.Type, won.Pattern, won._id, won.Serial, won.IsTradeable)
                        end
                    end)
                end
            end)
        elseif count > 1 then
            if storeInternal.bulkOpen then
                local okBulk = pcall(function()
                    task.spawn(storeInternal.bulkOpen, realCaseId, wonItems, caseIdent)
                end)
                if okBulk then animationStarted = true end
            end
        else
            if canUseOpenCase then
                local okOpen = pcall(function()
                    task.spawn(storeInternal.openCase, realCaseId, wonItems[1], caseIdent, false, reqId)
                end)
                if okOpen then animationStarted = true end
            end
        end

        if not animationStarted and storeInternal.startResolvedJob then
            local okJob = pcall(function()
                task.spawn(storeInternal.startResolvedJob, job)
            end)
            if okJob then animationStarted = true end
        end

        if not animationStarted and storeInternal.queue and storeInternal.tryProcess and not isModuleOrClassTable(storeInternal.queue) then
            table.insert(storeInternal.queue, job)
            local okQ, resQ = pcall(storeInternal.tryProcess)
            if okQ and resQ then animationStarted = true end
        end

        if not animationStarted then
            task.spawn(function()
                runFallbackUnboxAnimation(caseDef, wonItems, caseIdent)
            end)
        end

        -- Safety timer: reset isUnboxingActive if the native animation path
        -- completes without calling our dismissCaseOpenUI/handleSequenceFinished.
        -- This prevents the 2nd case from being blocked.
        task.delay(8, function()
            if isUnboxingActive and (os.clock() - lastUnboxTimestamp >= 7.5) then
                isUnboxingActive = false
                if storeInternal.state then
                    storeInternal.state.isOpening = false
                    storeInternal.state.isPendingOpenRequest = false
                    storeInternal.state.pendingOpenRequestId = nil
                    storeInternal.state.isQuickUnlock = false
                end
            end
        end)
        task.delay(10, function()
            if isUnboxingActive and (os.clock() - lastUnboxTimestamp >= 9.5) then
                handleSequenceFinished()
                if wonItems and wonItems[1] then
                    pcall(triggerItemNotification, wonItems[1])
                end
            end
        end)
    end

    -- Hook game remotes and network handlers
    pcall(function()
        if CasesLib then
            local origGetCase = CasesLib.GetCase
            if typeof(origGetCase) == "function" then
                CasesLib.GetCase = function(id)
                    local c = origGetCase(id)
                    if not c and CasesLib.GetCaseByName then
                        c = CasesLib.GetCaseByName(id)
                    end
                    if c then
                        if (c.name and string.find(c.name, "Console")) or (c.caseId and string.find(c.caseId, "console")) then
                            c.caseType = "Console"
                        elseif (c.name and string.find(c.name, "Charm")) or (c.caseId and string.find(c.caseId, "charm")) then
                            c.caseType = "Charm Capsule"
                        elseif (c.name and string.find(c.name, " | ")) then
                            c.caseType = "Package"
                        end
                    end
                    return c
                end
            end
            local origGetCaseByName = CasesLib.GetCaseByName
            if typeof(origGetCaseByName) == "function" then
                CasesLib.GetCaseByName = function(name)
                    if not name or name == "" or name == "Stock" then return nil end
                    local c = origGetCaseByName(name)
                    if not c and CasesLib.GetCase then
                        c = CasesLib.GetCase(name)
                    end
                    if c then
                        if (c.name and string.find(c.name, "Console")) or (c.caseId and string.find(c.caseId, "console")) then
                            c.caseType = "Console"
                        elseif (c.name and string.find(c.name, "Charm")) or (c.caseId and string.find(c.caseId, "charm")) then
                            c.caseType = "Charm Capsule"
                        elseif (c.name and string.find(c.name, " | ")) then
                            c.caseType = "Package"
                        end
                    end
                    return c
                end
            end
            local origGetCases = CasesLib.GetCases
            if typeof(origGetCases) == "function" then
                CasesLib.GetCases = function(...)
                    local list = origGetCases(...)
                    if list and typeof(list) == "table" then
                        for _, c in ipairs(list) do
                            if c then
                                if (c.name and string.find(c.name, "Console")) or (c.caseId and string.find(c.caseId, "console")) then
                                    c.caseType = "Console"
                                elseif (c.name and string.find(c.name, "Charm")) or (c.caseId and string.find(c.caseId, "charm")) then
                                    c.caseType = "Charm Capsule"
                                elseif (c.name and string.find(c.name, " | ")) then
                                    c.caseType = "Package"
                                end
                            end
                        end
                    end
                    return list
                end
            end
        end

        pcall(function()
            local okCSC, CSC = pcall(require, ReplicatedStorage:WaitForChild("Controllers"):WaitForChild("CaseSceneController"))
            if okCSC and CSC and CSC.ShowCaseScene then
                local origShow = CSC.ShowCaseScene
                CSC.ShowCaseScene = function(caseType, caseName)
                    if caseName then
                        local lower = string.lower(caseName)
                        if string.find(lower, "console") then
                            caseType = "Console"
                        elseif string.find(lower, "charm") then
                            caseType = "Charm Capsule"
                        elseif CasesLib and CasesLib.GetCaseByName then
                            local cd = CasesLib.GetCaseByName(caseName)
                            if cd and cd.caseType then
                                caseType = cd.caseType
                            end
                        end
                    end
                    return origShow(caseType, caseName)
                end
            end
        end)

        pcall(function()
            local okInv, InvModule = pcall(require, ReplicatedStorage:WaitForChild("Interface"):WaitForChild("Screens"):WaitForChild("Menu"):WaitForChild("Inventory"))
            if okInv and InvModule and InvModule.SetupInformationFrame then
                local origSetup = InvModule.SetupInformationFrame
                InvModule.SetupInformationFrame = function(item, ...)
                    local ret = origSetup(item, ...)
                    pcall(function()
                        if item and (item.Type == "Case" or item.Type == "Package" or item.Type == "Charm Capsule" or item.Type == "Console" or item.caseId or (item.Skin and CasesLib and CasesLib.GetCaseByName and CasesLib.GetCaseByName(item.Skin))) then
                            local menu, mainGui = getMenuRoot()
                            local pGui = LocalPlayer:FindFirstChild("PlayerGui")
                            local inv = (menu and menu:FindFirstChild("Inventory")) or (mainGui and mainGui:FindFirstChild("Inventory", true)) or (pGui and pGui:FindFirstChild("Inventory", true))
                            if inv then
                                local info = inv:FindFirstChild("InformationFrame", true)
                                local unlockBtn = info and info:FindFirstChild("Unlock")
                                if unlockBtn then
                                    unlockBtn.Visible = true
                                end
                            end
                        end
                    end)
                    return ret
                end
            end
        end)

        if Store then
            local origSweep = Store._RunConsoleInspectSweep
            local safeSweep = function(callback)
                pcall(function()
                    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
                    if pGui then
                        local sweep = pGui:FindFirstChild("ConsoleInspectSweep", true)
                        if sweep then sweep:Destroy() end
                    end
                end)
                if typeof(callback) == "function" then pcall(callback) end
            end
            if typeof(hookfunction) == "function" and typeof(origSweep) == "function" then
                pcall(hookfunction, origSweep, safeSweep)
            end
            Store._RunConsoleInspectSweep = safeSweep
        end

        pcall(function()
            local pGui = LocalPlayer:FindFirstChild("PlayerGui")
            if pGui then
                pGui.DescendantAdded:Connect(function(desc)
                    if desc.Name == "ConsoleInspectSweep" then
                        desc:Destroy()
                    end
                end)
            end
        end)

        if Router and typeof(Router.broadcastRouter) == "function" then
            local origBroadcast = Router.broadcastRouter
            local isCallingBroadcast = false
            local function handleBroadcast(name, ...)
                if isCallingBroadcast then
                    if origBroadcast then return origBroadcast(name, ...) end
                    return
                end
                if name == "CreateMenuNotification" then
                    local args = { ... }
                    if args[2] and typeof(args[2]) == "string" and string.find(string.lower(args[2]), "timed out") then
                        return
                    end
                elseif name == "WeaponInspect" then
                    if dismissCaseOpenUI then
                        dismissCaseOpenUI(false)
                    else
                        isUnboxingActive = false
                        if storeInternal.state then
                            storeInternal.state.isOpening = false
                            storeInternal.state.isPendingOpenRequest = false
                            storeInternal.state.pendingOpenRequestId = nil
                            storeInternal.state.isQuickUnlock = false
                        end
                    end
                    local args = { ... }
                    local itemObj = (args[10] and unlockedDict[args[10]]) or nil
                    if not itemObj and lastWonItem and (lastWonItem.Name == args[1] or lastWonItem._id == args[10]) then
                        itemObj = lastWonItem
                    end
                    local wName = (typeof(args[1]) == "string" and args[1] ~= "" and args[1]) or (itemObj and itemObj.Name) or (lastWonItem and lastWonItem.Name) or "AWP"
                    local sName = (typeof(args[2]) == "string" and args[2] ~= "" and args[2]) or (itemObj and itemObj.Skin) or (lastWonItem and lastWonItem.Skin) or "Asiimov"
                    local fVal = typeof(args[3]) == "number" and args[3] or (itemObj and itemObj.Float) or (lastWonItem and lastWonItem.Float) or 0.05
                    local sTrack = args[4] or (itemObj and itemObj.StatTrack) or (lastWonItem and lastWonItem.StatTrack) or false
                    local nTag = args[5] or (itemObj and itemObj.NameTag) or (lastWonItem and lastWonItem.NameTag) or false
                    local charm = (args[6] ~= nil and args[6]) or (itemObj and itemObj.Charm) or (lastWonItem and lastWonItem.Charm) or false
                    local stickers = typeof(args[7]) == "table" and args[7] or (itemObj and itemObj.Stickers) or (lastWonItem and lastWonItem.Stickers) or {}
                    local iType = typeof(args[8]) == "string" and args[8] or (itemObj and itemObj.Type) or (lastWonItem and lastWonItem.Type) or getWeaponClass(wName)
                    local pat = typeof(args[9]) == "number" and args[9] or (itemObj and itemObj.Pattern) or (lastWonItem and lastWonItem.Pattern) or 1
                    local id = (typeof(args[10]) == "string" and args[10] ~= "") and args[10] or (itemObj and itemObj._id) or (lastWonItem and lastWonItem._id) or ("inspect_" .. sanitize(wName) .. "_" .. sanitize(sName) .. "_" .. tostring(os.clock()))
                    local serial = typeof(args[11]) == "number" and args[11] or (itemObj and itemObj.Serial) or (lastWonItem and lastWonItem.Serial) or 1
                    local trade = args[12] or (itemObj and itemObj.IsTradeable) or (lastWonItem and lastWonItem.IsTradeable) or false

                    if origBroadcast then
                        isCallingBroadcast = true
                        local okCall, res = pcall(origBroadcast, name, wName, sName, fVal, sTrack, nTag, charm, stickers, iType, pat, id, serial, trade)
                        isCallingBroadcast = false
                        if okCall then return res end
                    end
                    return
                end

                if origBroadcast then
                    isCallingBroadcast = true
                    local okCall, res = pcall(origBroadcast, name, ...)
                    isCallingBroadcast = false
                    if okCall then return res end
                end
                return
            end

            local hookSucceeded = false
            if typeof(hookfunction) == "function" then
                local ok, res = pcall(function()
                    return hookfunction(Router.broadcastRouter, function(...)
                        return handleBroadcast(...)
                    end)
                end)
                if ok and typeof(res) == "function" then
                    origBroadcast = res
                    hookSucceeded = true
                end
            end

            if not hookSucceeded then
                if setreadonly then pcall(setreadonly, Router, false) end
                Router.broadcastRouter = function(...)
                    return handleBroadcast(...)
                end
            end
        end

        if Remotes and Remotes.Inventory then
            if Remotes.Inventory.EquipLoadoutSkin and Remotes.Inventory.EquipLoadoutSkin.Send then
                local origEquipLoadout = Remotes.Inventory.EquipLoadoutSkin.Send
                local isCallingEquip = false
                local function hookEquipLoadout(data)
                    if isCallingEquip then
                        if origEquipLoadout then return origEquipLoadout(data) end
                        return
                    end
                    if data and data.Identifier and (string.sub(tostring(data.Identifier), 1, 7) == "unlock_" or string.sub(tostring(data.Identifier), 1, 10) == "memesense_" or unlockedDict[data.Identifier]) then
                        updateLoadoutInMemory(data.Team, data.Type, (data.Slot or 0) + 1, data.Identifier)
                        pcall(function() if DataController then DataController.ApplyInventoryDelta(LocalPlayer, {}) end end)
                        pcall(function() if Remotes.Inventory.LoadoutResponse then Remotes.Inventory.LoadoutResponse.Fire(true) end end)
                        return
                    end
                    if origEquipLoadout then
                        isCallingEquip = true
                        local okCall, res = pcall(origEquipLoadout, data)
                        isCallingEquip = false
                        if okCall then return res end
                    end
                end
                local equipHookOk = false
                if typeof(hookfunction) == "function" then
                    local ok, res = pcall(function()
                        return hookfunction(Remotes.Inventory.EquipLoadoutSkin.Send, hookEquipLoadout)
                    end)
                    if ok and typeof(res) == "function" then
                        origEquipLoadout = res
                        equipHookOk = true
                    end
                end
                if not equipHookOk then
                    if setreadonly then pcall(setreadonly, Remotes.Inventory.EquipLoadoutSkin, false) end
                    Remotes.Inventory.EquipLoadoutSkin.Send = hookEquipLoadout
                end
            end

            if Remotes.Inventory.EquipSpecialItem and Remotes.Inventory.EquipSpecialItem.Send then
                local origEquipSpecial = Remotes.Inventory.EquipSpecialItem.Send
                local isCallingSpecial = false
                local function hookEquipSpecial(data)
                    if isCallingSpecial then
                        if origEquipSpecial then return origEquipSpecial(data) end
                        return
                    end
                    if data and data.Identifier and (string.sub(tostring(data.Identifier), 1, 7) == "unlock_" or string.sub(tostring(data.Identifier), 1, 10) == "memesense_" or unlockedDict[data.Identifier]) then
                        updateSpecialInMemory(data.Team, data.Path, data.Identifier)
                        pcall(function() if DataController then DataController.ApplyInventoryDelta(LocalPlayer, {}) end end)
                        pcall(function() if Remotes.Inventory.LoadoutResponse then Remotes.Inventory.LoadoutResponse.Fire(true) end end)
                        return
                    end
                    if origEquipSpecial then
                        isCallingSpecial = true
                        local okCall, res = pcall(origEquipSpecial, data)
                        isCallingSpecial = false
                        if okCall then return res end
                    end
                end
                local specialHookOk = false
                if typeof(hookfunction) == "function" then
                    local ok, res = pcall(function()
                        return hookfunction(Remotes.Inventory.EquipSpecialItem.Send, hookEquipSpecial)
                    end)
                    if ok and typeof(res) == "function" then
                        origEquipSpecial = res
                        specialHookOk = true
                    end
                end
                if not specialHookOk then
                    if setreadonly then pcall(setreadonly, Remotes.Inventory.EquipSpecialItem, false) end
                    Remotes.Inventory.EquipSpecialItem.Send = hookEquipSpecial
                end
            end

            if Remotes.Inventory.SwapLoadoutSkins and Remotes.Inventory.SwapLoadoutSkins.Send then
                local origSwap = Remotes.Inventory.SwapLoadoutSkins.Send
                local isCallingSwap = false
                local function hookSwap(data)
                    if isCallingSwap then
                        if origSwap then return origSwap(data) end
                        return
                    end
                    local loadout = nil
                    pcall(function() if DataController then loadout = DataController.Get(LocalPlayer, "Loadout") end end)
                    if loadout and loadout[data.Team] and loadout[data.Team].Loadout and loadout[data.Team].Loadout[data.Type] then
                        local opts = loadout[data.Team].Loadout[data.Type].Options
                        local idx1 = (data.SlotOne or 0) + 1
                        local idx2 = (data.SlotTwo or 0) + 1
                        opts[idx1], opts[idx2] = opts[idx2], opts[idx1]
                    end
                    pcall(function() if DataController then DataController.ApplyInventoryDelta(LocalPlayer, {}) end end)
                    pcall(function() if Remotes.Inventory.LoadoutResponse then Remotes.Inventory.LoadoutResponse.Fire(true) end end)
                    if origSwap then
                        isCallingSwap = true
                        local okCall, res = pcall(origSwap, data)
                        isCallingSwap = false
                        if okCall then return res end
                    end
                end
                local swapHookOk = false
                if typeof(hookfunction) == "function" then
                    local ok, res = pcall(function()
                        return hookfunction(Remotes.Inventory.SwapLoadoutSkins.Send, hookSwap)
                    end)
                    if ok and typeof(res) == "function" then
                        origSwap = res
                        swapHookOk = true
                    end
                end
                if not swapHookOk then
                    if setreadonly then pcall(setreadonly, Remotes.Inventory.SwapLoadoutSkins, false) end
                    Remotes.Inventory.SwapLoadoutSkins.Send = hookSwap
                end
            end
        end

        pcall(function()
            if typeof(hookfunction) == "function" and Remotes and Remotes.Store and Remotes.Store.OpenCase and Remotes.Store.OpenCase.Send then
                hookfunction(Remotes.Store.OpenCase.Send, function(data)
                    startLocalUnboxing("RemoteSend", data)
                end)
            end
        end)

        pcall(function()
            if setreadonly and Remotes and Remotes.Store and Remotes.Store.OpenCase then pcall(setreadonly, Remotes.Store.OpenCase, false) end
            if Remotes and Remotes.Store and Remotes.Store.OpenCase then
                Remotes.Store.OpenCase.Send = function(data)
                    startLocalUnboxing("RemoteSend", data)
                end
            end
        end)

        if Remotes and Remotes.Store and Remotes.Store.OpenConsole and Remotes.Store.OpenConsole.Send then
            pcall(function()
                if typeof(hookfunction) == "function" then
                    hookfunction(Remotes.Store.OpenConsole.Send, function(data)
                        startLocalUnboxing("RemoteSend", data)
                    end)
                end
            end)
            pcall(function()
                if setreadonly then pcall(setreadonly, Remotes.Store.OpenConsole, false) end
                Remotes.Store.OpenConsole.Send = function(data)
                    startLocalUnboxing("RemoteSend", data)
                end
            end)
        end

        if Remotes and Remotes.Store and Remotes.Store.CaseOpenSequenceFinished and Remotes.Store.CaseOpenSequenceFinished.Send then
            local function hookFinished(data)
                handleSequenceFinished(data)
            end
            if typeof(hookfunction) == "function" then
                pcall(hookfunction, Remotes.Store.CaseOpenSequenceFinished.Send, hookFinished)
            else
                if setreadonly then pcall(setreadonly, Remotes.Store.CaseOpenSequenceFinished, false) end
                Remotes.Store.CaseOpenSequenceFinished.Send = hookFinished
            end
        end

        -- Metamethod __namecall hook for packets sent via FireServer
        pcall(function()
            if typeof(hookmetamethod) == "function" then
                local origNamecall
                origNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                    local method = getnamecallmethod()
                    if (method == "FireServer" or method == "fireServer") and typeof(self) == "Instance" then
                        if self.Name == "OpenCase" or self.Name == "OpenConsole" then
                            task.spawn(function()
                                if not isUnboxingActive then
                                    startLocalUnboxing("Namecall")
                                end
                            end)
                            return
                        elseif self.Name == "CaseOpenSequenceFinished" then
                            handleSequenceFinished(...)
                            return
                        elseif self.Name == "EquipLoadoutSkin" then
                            local data = ...
                            if data and data.Identifier and (string.sub(tostring(data.Identifier), 1, 7) == "unlock_" or string.sub(tostring(data.Identifier), 1, 10) == "memesense_" or unlockedDict[data.Identifier]) then
                                updateLoadoutInMemory(data.Team, data.Type, (data.Slot or 0) + 1, data.Identifier)
                                pcall(function() if DataController then DataController.ApplyInventoryDelta(LocalPlayer, {}) end end)
                                pcall(function() if Remotes and Remotes.Inventory and Remotes.Inventory.LoadoutResponse then Remotes.Inventory.LoadoutResponse.Fire(true) end end)
                                return
                            end
                        elseif self.Name == "EquipSpecialItem" then
                            local data = ...
                            if data and data.Identifier and (string.sub(tostring(data.Identifier), 1, 7) == "unlock_" or string.sub(tostring(data.Identifier), 1, 10) == "memesense_" or unlockedDict[data.Identifier]) then
                                updateSpecialInMemory(data.Team, data.Path, data.Identifier)
                                pcall(function() if DataController then DataController.ApplyInventoryDelta(LocalPlayer, {}) end end)
                                pcall(function() if Remotes and Remotes.Inventory and Remotes.Inventory.LoadoutResponse then Remotes.Inventory.LoadoutResponse.Fire(true) end end)
                                return
                            end
                        end
                    end
                    return origNamecall(self, ...)
                end)
            end
        end)

        -- Viewmodel hooks for 1st-person view and gloves
        if Viewmodel then
            if Viewmodel.attachSleeves then
                local origAttachSleeves = Viewmodel.attachSleeves
                Viewmodel.attachSleeves = function(self, charName)
                    if self.Team ~= "Counter-Terrorists" then return end
                    local sleeves = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Sleeves")
                    if sleeves then
                        local target = (charName and charName ~= "" and sleeves:FindFirstChild(charName))
                            or (workspace:GetAttribute("CTCharacter") and sleeves:FindFirstChild(workspace:GetAttribute("CTCharacter")))
                            or sleeves:FindFirstChild("IDF")
                            or sleeves:FindFirstChildWhichIsA("Folder")
                            or sleeves:GetChildren()[1]
                        if target then
                            return origAttachSleeves(self, target.Name)
                        end
                    end
                    return origAttachSleeves(self, charName)
                end
            end

            if Viewmodel.construct then
                local origConstruct = Viewmodel.construct
                Viewmodel.construct = function(self, char, p3)
                    local isLocal = (self.Player == LocalPlayer or not self.Player)
                    if isLocal then
                        currentLocalViewmodel = self
                        self._lastChar = char
                        self._lastWeaponComponent = p3

                        if MemeSenseInventory.MasterSwitch ~= false then
                            local team = LocalPlayer:GetAttribute("Team") or (LocalPlayer.Team and LocalPlayer.Team.Name) or self.Team or "Counter-Terrorists"
                            if team ~= "Counter-Terrorists" and team ~= "Terrorists" then
                                team = "Counter-Terrorists"
                            end
                            local customGlove = getEquippedGlove(team)
                            if customGlove then
                                local encoded = HttpService:JSONEncode({
                                    Name = customGlove.Name,
                                    Skin = (customGlove.Skin == "Vanilla" and "Stock") or customGlove.Skin or "Stock",
                                    Float = customGlove.Float or 0.0001
                                })
                                if char and typeof(char) == "Instance" then
                                    pcall(function() char:SetAttribute("EquippedGloves", encoded) end)
                                end
                                if LocalPlayer.Character and typeof(LocalPlayer.Character) == "Instance" then
                                    pcall(function() LocalPlayer.Character:SetAttribute("EquippedGloves", encoded) end)
                                end
                                pcall(function() LocalPlayer:SetAttribute("EquippedGloves", encoded) end)
                            end
                        end
                    end
                    return origConstruct(self, char, p3)
                end
            end

            if Viewmodel.addAttachments then
                local origAddAttachments = Viewmodel.addAttachments
                Viewmodel.addAttachments = function(self, p2)
                    if (self.Player == LocalPlayer or not self.Player) and (MemeSenseInventory.MasterSwitch ~= false) then
                        local team = LocalPlayer:GetAttribute("Team") or (LocalPlayer.Team and LocalPlayer.Team.Name) or self.Team or "Counter-Terrorists"
                        if team ~= "Counter-Terrorists" and team ~= "Terrorists" then
                            team = "Counter-Terrorists"
                        end
                        local customGlove = getEquippedGlove(team)
                        if customGlove then
                            p2 = {
                                Name = customGlove.Name,
                                Skin = (customGlove.Skin == "Vanilla" and "Stock") or customGlove.Skin or "Stock",
                                Float = customGlove.Float or 0.0001
                            }
                        end
                    end
                    return origAddAttachments(self, p2)
                end
            end
        end

        -- Skins library hooks: GetGloves, GetSkinInformation, IsSkinAvailable
        if SkinsLib then
            if SkinsLib.GetGloves then
                local origGetGloves = SkinsLib.GetGloves
                SkinsLib.GetGloves = function(weaponName, skinName, floatVal)
                    if not weaponName or weaponName == "" then return nil end
                    local res = origGetGloves(weaponName, skinName, floatVal)
                    if res then return res end

                    local nameVariants = {
                        weaponName,
                        string.gsub(weaponName, "%-", " "),
                        string.gsub(weaponName, " ", "-")
                    }
                    local lowerW = string.lower(weaponName)
                    if string.find(lowerW, "sport") then
                        table.insert(nameVariants, "Sports Gloves")
                        table.insert(nameVariants, "Sport Gloves")
                        table.insert(nameVariants, "Sports-Gloves")
                        table.insert(nameVariants, "Sport-Gloves")
                    elseif string.find(lowerW, "driver") then
                        table.insert(nameVariants, "Driver Gloves")
                        table.insert(nameVariants, "Driver-Gloves")
                    elseif string.find(lowerW, "wrap") then
                        table.insert(nameVariants, "Hand Wraps")
                        table.insert(nameVariants, "Hand-Wraps")
                    elseif string.find(lowerW, "operator") then
                        table.insert(nameVariants, "Operator Gloves")
                        table.insert(nameVariants, "Operator-Gloves")
                    end

                    for _, vName in ipairs(nameVariants) do
                        if vName ~= weaponName then
                            local r = origGetGloves(vName, skinName, floatVal)
                            if r then return r end
                        end
                    end

                    local weaponsFolder = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Weapons")
                    local skinsFolder = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Skins")
                    if weaponsFolder then
                        local wBase = nil
                        for _, vName in ipairs(nameVariants) do
                            wBase = weaponsFolder:FindFirstChild(vName)
                            if wBase then break end
                        end
                        if not wBase then
                            for _, child in ipairs(weaponsFolder:GetChildren()) do
                                local childName = child.Name
                                local lowerChild = string.lower(childName)
                                if lowerChild == lowerW or string.gsub(lowerChild, "%-", " ") == string.gsub(lowerW, "%-", " ") then
                                    wBase = child
                                    break
                                end
                            end
                        end

                        if wBase then
                            local model = Instance.new("Model")
                            model.Name = weaponName
                            for _, part in ipairs(wBase:GetChildren()) do
                                if part:IsA("BasePart") then
                                    part:Clone().Parent = model
                                end
                            end

                            if skinsFolder and skinName and skinName ~= "" and skinName ~= "Stock" then
                                local sWeapon = nil
                                for _, vName in ipairs(nameVariants) do
                                    sWeapon = skinsFolder:FindFirstChild(vName)
                                    if sWeapon then break end
                                end
                                if not sWeapon then
                                    for _, child in ipairs(skinsFolder:GetChildren()) do
                                        local childName = child.Name
                                        local lowerChild = string.lower(childName)
                                        if lowerChild == lowerW or string.gsub(lowerChild, "%-", " ") == string.gsub(lowerW, "%-", " ") then
                                            sWeapon = child
                                            break
                                        end
                                    end
                                end

                                if sWeapon then
                                    local sSkin = sWeapon:FindFirstChild(skinName)
                                    if not sSkin then
                                        for _, child in ipairs(sWeapon:GetChildren()) do
                                            if string.lower(child.Name) == string.lower(skinName) then
                                                sSkin = child
                                                break
                                            end
                                        end
                                    end

                                    if sSkin then
                                        local camFolder = sSkin:FindFirstChild("Camera") or sSkin
                                        local wearFolder = camFolder:FindFirstChild("Factory New")
                                            or camFolder:FindFirstChild("Minimal Wear")
                                            or camFolder:FindFirstChild("Field-Tested")
                                            or camFolder:FindFirstChildWhichIsA("Folder")
                                            or camFolder
                                        if wearFolder then
                                            pcall(function()
                                                for _, tex in ipairs(wearFolder:GetChildren()) do
                                                    if tex:IsA("Texture") or tex:IsA("Decal") then
                                                        local targetPart = model:FindFirstChild(tex.Name)
                                                        if targetPart then
                                                            tex:Clone().Parent = targetPart
                                                        end
                                                    end
                                                end
                                            end)
                                        end
                                    end
                                end
                            end

                            return model
                        end
                    end
                    return nil
                end
            end

            if SkinsLib and SkinsLib.GetSkinInformation then
                local origGetSkinInformation = SkinsLib.GetSkinInformation
                local function hookGetSkinInformation(p186, p187)
                    local info = origGetSkinInformation(p186, p187)
                    if info then return info end

                    if p186 and p187 then
                        local cleanW = sanitize(p186)
                        local cleanS = sanitize(p187)
                        local it = unlockedDict["unlock_" .. cleanW .. "_" .. cleanS]
                            or unlockedDict["memesense_" .. cleanW .. "_" .. cleanS]
                        if not it then
                            for _, item in pairs(unlockedDict) do
                                if (item.Name == p186 or sanitize(item.Name) == cleanW) and (item.Skin == p187 or sanitize(item.Skin) == cleanS) then
                                    it = item
                                    break
                                end
                            end
                        end

                        local itType = (it and it.Type) or (p186 == "Badge" and "Badge") or (p186 == "Charm" and "Charm") or getWeaponClass(p186)
                        local itRarity = (it and it.Rarity) or (p186 == "Badge" and "Special") or "Covert"
                        local imgAssetId = (it and it.Icon) or ""
                        if p186 == "Badge" and imgAssetId == "" then
                            local bLookup = {
                                ["Beta"] = "rbxassetid://98169487322185",
                                ["Ambassador"] = "rbxassetid://122099710419173",
                                ["The Ambassador"] = "rbxassetid://122099710419173",
                                ["Prototype"] = "rbxassetid://108121837557444",
                                ["Verified"] = "rbxassetid://1158949543",
                                ["Accelerator"] = "rbxassetid://94056445028784",
                                ["Administrator"] = "rbxassetid://102913689742485",
                                ["Premium"] = "rbxassetid://86898254493830",
                                ["Star Creator"] = "rbxassetid://95965239643084",
                                                                ["Medal.tv"] = "rbxassetid://124834395957965",
                                ["Contributor"] = "rbxassetid://125370656636279",
                            }
                            imgAssetId = bLookup[p187] or ""
                        end

                        return {
                            paintId = p187,
                            skin = p187,
                            rarity = itRarity,
                            supportsStatTrak = (p186 ~= "Badge" and p186 ~= "Charm"),
                            statTrakChance = 0,
                            isEnabled = true,
                            isMarketplaceVisible = false,
                            collection = nil,
                            description = p187,
                            caseRarity = itRarity,
                            type = itType,
                            name = p186,
                            floatRange = { min = 0, max = 1 },
                            floatChances = { { wear = "Factory New", chance = 100 } },
                            charmImages = {},
                            wearImages = {},
                            imageAssetId = imgAssetId
                        }
                    end
                    return info
                end

                SkinsLib.GetSkinInformation = hookGetSkinInformation
            end

            if SkinsLib and SkinsLib.GetCharacterModel then
                local origGetCharacterModel = SkinsLib.GetCharacterModel
                local function hookGetCharacterModel(s30, s31, n11, p38, p39, p40, pExtras, s32)
                    local model = origGetCharacterModel(s30, s31, n11, p38, p39, p40, pExtras, s32)
                    if model then return model end
                    local okFall, fallbackModel = pcall(function()
                        local Weapons = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Weapons")
                        local s30_2 = Weapons and Weapons:FindFirstChild(s30)
                        local charModel = s30_2 and s30_2:FindFirstChild("Character")
                        if charModel and charModel:IsA("Model") then
                            local clone = charModel:Clone()
                            local assetsSkins = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Skins")
                            local skinsFolder = assetsSkins and assetsSkins:FindFirstChild(s30)
                            local skinFolder = skinsFolder and skinsFolder:FindFirstChild(s31)
                            local charTex = skinFolder and skinFolder:FindFirstChild("Character")
                            if charTex then
                                for _, part in ipairs(clone:GetDescendants()) do
                                    if part:IsA("MeshPart") or part:IsA("Part") then
                                        local texPart = charTex:FindFirstChild(part.Name)
                                        if texPart and (texPart:IsA("Decal") or texPart:IsA("Texture")) then
                                            part.TextureID = texPart.Texture
                                        end
                                    end
                                end
                            end
                            return clone
                        end
                        return nil
                    end)
                    if okFall and fallbackModel then return fallbackModel end
                    return model
                end
                SkinsLib.GetCharacterModel = hookGetCharacterModel
            end

            if SkinsLib and SkinsLib.GetBadgeModel then
                local origGetBadgeModel = SkinsLib.GetBadgeModel
                local function hookGetBadgeModel(s24)
                    local m = origGetBadgeModel(s24)
                    if m then return m end
                    local okModel, dummy = pcall(function()
                        local model = Instance.new("Model")
                        model.Name = tostring(s24)
                        local part = Instance.new("Part")
                        part.Name = "Badge"
                        part.Size = Vector3.new(1, 1, 0.1)
                        part.Transparency = 1
                        part.Anchored = true
                        part.CanCollide = false
                        part.Parent = model
                        model.PrimaryPart = part
                        return model
                    end)
                    if okModel and dummy then return dummy end
                    return nil
                end
                SkinsLib.GetBadgeModel = hookGetBadgeModel
            end

            if SkinsLib and SkinsLib.IsSkinAvailable then
                local origIsSkinAvailable = SkinsLib.IsSkinAvailable
                SkinsLib.IsSkinAvailable = function(p193, p194)
                    if origIsSkinAvailable(p193, p194) then
                        return true
                    end
                    return true
                end
            end
        end

        if WeaponComponent and WeaponComponent.new then
            local origWCNew = WeaponComponent.new
            WeaponComponent.new = function(player, identifier, id, slot, name, skin, float, statTrack, nameTag, origOwner, charm, stickers)
                if player == LocalPlayer and (MemeSenseInventory.MasterSwitch ~= false) then
                    local team = LocalPlayer:GetAttribute("Team") or (LocalPlayer.Team and LocalPlayer.Team.Name) or "Counter-Terrorists"
                    if team ~= "Counter-Terrorists" and team ~= "Terrorists" then
                        team = "Counter-Terrorists"
                    end
                    local isKnife = (name == "CT Knife" or name == "T Knife" or string.find(string.lower(name), "knife") ~= nil or name == "Karambit" or name == "LightSaber")
                    if isKnife then
                        local customKnife = getEquippedKnife(team)
                        if customKnife then
                            name = customKnife.Name
                            skin = (customKnife.Skin == "Vanilla" and "Stock") or customKnife.Skin or "Stock"
                            float = 0.0001
                        end
                    else
                        local customSkin = getEquippedSkin(team, name)
                        if customSkin then
                            skin = (customSkin.Skin == "Vanilla" and "Stock") or customSkin.Skin or "Stock"
                            float = 0.0001
                            if customSkin.Charm then charm = customSkin.Charm end
                        end
                    end
                    local customGlove = getEquippedGlove(team)
                    if customGlove then
                        applyGlovesToCharacter(customGlove)
                    end
                end
                return origWCNew(player, identifier, id, slot, name, skin, float, statTrack, nameTag, origOwner, charm, stickers)
            end
        end

        pcall(function()
            local CWM = require(ReplicatedStorage:WaitForChild("Controllers"):WaitForChild("Observers"):WaitForChild("Players"):WaitForChild("Components"):WaitForChild("CreateWeaponModel"))
            if typeof(CWM) == "table" then
                local mt = getmetatable(CWM)
                if mt and mt.__call then
                    local origCall = mt.__call
                    mt.__call = function(tbl, p61, p62, t7)
                        if p61 == LocalPlayer and p62 and typeof(p62) == "table" and (MemeSenseInventory.MasterSwitch ~= false) then
                            local team = LocalPlayer:GetAttribute("Team") or (LocalPlayer.Team and LocalPlayer.Team.Name) or "Counter-Terrorists"
                            if team ~= "Counter-Terrorists" and team ~= "Terrorists" then
                                team = "Counter-Terrorists"
                            end
                            local isKnife = (p62.Name == "CT Knife" or p62.Name == "T Knife" or string.find(string.lower(p62.Name), "knife") ~= nil or p62.Name == "Karambit" or p62.Name == "LightSaber")
                            if isKnife then
                                local customKnife = getEquippedKnife(team)
                                if customKnife then
                                    local cloned = table.clone(p62)
                                    cloned.Name = customKnife.Name
                                    cloned.Skin = (customKnife.Skin == "Vanilla" and "Stock") or customKnife.Skin or "Stock"
                                    cloned.Float = 0.0001
                                    p62 = cloned
                                end
                            else
                                local customSkin = getEquippedSkin(team, p62.Name)
                                if customSkin then
                                    local cloned = table.clone(p62)
                                    cloned.Skin = (customSkin.Skin == "Vanilla" and "Stock") or customSkin.Skin or "Stock"
                                    cloned.Float = 0.0001
                                    if customSkin.Charm then cloned.Charm = customSkin.Charm end
                                    p62 = cloned
                                end
                            end
                        end
                        return origCall(tbl, p61, p62, t7)
                    end
                end
            end
        end)
    end)

    -- ========================================================================
    -- 3D COLORED INVENTORY ICONS MAPPING (Directly from BloxStrike CustomWeapons)
    -- ========================================================================
    local WeaponDisplaySilhouettes = {
        ["rbxassetid://78088217065173"] = true,
        ["rbxassetid://119105180712017"] = true,
        ["rbxassetid://103569239379116"] = true,
        ["rbxassetid://139380311026447"] = true,
        ["rbxassetid://91965772008164"] = true,
        ["rbxassetid://134706510344449"] = true,
        ["rbxassetid://85121618781867"] = true,
        ["rbxassetid://125193639488260"] = true,
        ["rbxassetid://92481124554479"] = true,
        ["rbxassetid://73573766861663"] = true,
        ["rbxassetid://71208637985987"] = true,
        -- Glove & drop-shadow asset IDs to block from previews
        ["rbxassetid://90107530894790"] = true,
        ["rbxassetid://108558626830196"] = true,
        ["rbxassetid://107229775675458"] = true,
        ["rbxassetid://136737792038823"] = true,
        ["rbxassetid://93849480884386"] = true,
        ["rbxassetid://102867561868882"] = true,
    }

    local DefaultWeaponIcons = {
        -- Pistols (Real colored 3D icons from CustomWeapons)
        ["Desert Eagle"] = "rbxassetid://122477921917392",
        ["Desert-Eagle"] = "rbxassetid://122477921917392",
        ["Dual Berettas"] = "rbxassetid://111854065134079",
        ["Dual-Berettas"] = "rbxassetid://111854065134079",
        ["Five-SeveN"] = "rbxassetid://90570942481875",
        ["Five-Seven"] = "rbxassetid://90570942481875",
        ["Glock-18"] = "rbxassetid://101406018897044",
        ["Glock 18"] = "rbxassetid://101406018897044",
        ["P250"] = "rbxassetid://73666032770570",
        ["R8 Revolver"] = "rbxassetid://112745953600473",
        ["R8-Revolver"] = "rbxassetid://112745953600473",
        ["Tec-9"] = "rbxassetid://119232881698906",
        ["Tec 9"] = "rbxassetid://119232881698906",
        ["USP-S"] = "rbxassetid://131658947857971",
        ["USP-s"] = "rbxassetid://131658947857971",

        -- Mid-Tier (Real colored 3D icons from CustomWeapons)
        ["MAC-10"] = "rbxassetid://83671879972945",
        ["MAC 10"] = "rbxassetid://83671879972945",
        ["MAG-7"] = "rbxassetid://86291171438206",
        ["MAG 7"] = "rbxassetid://86291171438206",
        ["MP9"] = "rbxassetid://135384625641866",
        ["Negev"] = "rbxassetid://134163874921903",
        ["Nova"] = "rbxassetid://127273982496076",
        ["P90"] = "rbxassetid://82724138944322",
        ["Sawed-Off"] = "rbxassetid://117478678996500",
        ["Sawed Off"] = "rbxassetid://117478678996500",
        ["XM1014"] = "rbxassetid://115344320193773",

        -- Rifles (Real colored 3D icons from CustomWeapons)
        ["AK-47"] = "rbxassetid://83097083839889",
        ["AK 47"] = "rbxassetid://83097083839889",
        ["AUG"] = "rbxassetid://119885531832389",
        ["AWP"] = "rbxassetid://79794264811775",
        ["FAMAS"] = "rbxassetid://125469152582044",
        ["Galil AR"] = "rbxassetid://75166557697975",
        ["Galil-AR"] = "rbxassetid://75166557697975",
        ["M4A1-S"] = "rbxassetid://113144230602399",
        ["M4A1-s"] = "rbxassetid://113144230602399",
        ["M4A4"] = "rbxassetid://93053662997899",
        ["SG 553"] = "rbxassetid://133547075528778",
        ["SG-553"] = "rbxassetid://133547075528778",
        ["SSG 08"] = "rbxassetid://112132914334737",
        ["SSG-08"] = "rbxassetid://112132914334737",

        -- Misc / Equipment
        ["Zeus x27"] = "rbxassetid://71464446190434",
        ["Zeus-x27"] = "rbxassetid://71464446190434",
        ["Taser"] = "rbxassetid://71464446190434",

        -- Gloves
        ["Driver Gloves"] = "rbxassetid://90107530894790",
        ["Driver-Gloves"] = "rbxassetid://90107530894790",
        ["Hand Wraps"] = "rbxassetid://136737792038823",
        ["Hand-Wraps"] = "rbxassetid://136737792038823",
        ["Handwraps"] = "rbxassetid://136737792038823",
        ["Operator Gloves"] = "rbxassetid://108558626830196",
        ["Operator-Gloves"] = "rbxassetid://108558626830196",
        ["Sports Gloves"] = "rbxassetid://107229775675458",
        ["Sports-Gloves"] = "rbxassetid://107229775675458",
        ["Sport Gloves"] = "rbxassetid://107229775675458",
        ["Sport-Gloves"] = "rbxassetid://107229775675458",

        -- Knives
        ["Butterfly Knife"] = "rbxassetid://78213551472461",
        ["Butterfly-Knife"] = "rbxassetid://78213551472461",
        ["CT Knife"] = "rbxassetid://83421949194974",
        ["CT-Knife"] = "rbxassetid://83421949194974",
        ["Flip Knife"] = "rbxassetid://114223585745501",
        ["Flip-Knife"] = "rbxassetid://114223585745501",
        ["Gut Knife"] = "rbxassetid://127390958045577",
        ["Gut-Knife"] = "rbxassetid://127390958045577",
        ["Karambit"] = "rbxassetid://130354351154792",
        ["M9 Bayonet"] = "rbxassetid://99401987714397",
        ["M9-Bayonet"] = "rbxassetid://99401987714397",
        ["Skeleton Knife"] = "rbxassetid://90954924716133",
        ["Skeleton-Knife"] = "rbxassetid://90954924716133",
        ["Stiletto Knife"] = "rbxassetid://90954924716133",
        ["Stiletto-Knife"] = "rbxassetid://90954924716133",
        ["T Knife"] = "rbxassetid://134665473505478",
        ["T-Knife"] = "rbxassetid://134665473505478",
        ["LightSaber"] = "rbxassetid://109405629168962",
    }

    local CaseIconDefault = "rbxassetid://73880049881356"
    local KeyIconDefault = "rbxassetid://110520095994318"
    local CharmIconDefault = "rbxassetid://127888213250008"
    local BadgeIconDefault = "rbxassetid://98169487322185"

    local availableSkinsCache = {}
    local glovePreviewIconCache = {}
    local function getGlovePreviewIcon(wName)
        if glovePreviewIconCache[wName] then
            return glovePreviewIconCache[wName]
        end
        local variants = {
            wName,
            string.gsub(wName, " ", "-"),
            string.gsub(wName, "-", " "),
            string.gsub(wName, "s$", ""),
        }
        local validIcons = {}
        for _, v in ipairs(variants) do
            local gSkins = availableSkinsCache[v]
            if gSkins and typeof(gSkins) == "table" then
                for sName, sData in pairs(gSkins) do
                    local icon = (sData.wearImages and #sData.wearImages > 0 and sData.wearImages[1].assetId)
                        or sData.imageAssetId
                    if icon and icon ~= "" and not WeaponDisplaySilhouettes[icon] and icon ~= "rbxassetid://83097083839889" then
                        table.insert(validIcons, icon)
                    end
                end
            end
        end
        if #validIcons == 0 and SkinsLib and SkinsLib.GetAllSkinsForWeapon then
            for _, v in ipairs(variants) do
                local ok, skinsList = pcall(SkinsLib.GetAllSkinsForWeapon, v)
                if ok and skinsList and typeof(skinsList) == "table" then
                    for _, sInfo in ipairs(skinsList) do
                        local icon = (SkinsLib.GetWearImageForFloat and SkinsLib.GetWearImageForFloat(sInfo, 0.0001))
                            or sInfo.imageAssetId
                        if icon and icon ~= "" and not WeaponDisplaySilhouettes[icon] and icon ~= "rbxassetid://83097083839889" then
                            table.insert(validIcons, icon)
                        end
                    end
                end
            end
        end
        if #validIcons > 0 then
            local chosen = validIcons[math.random(1, #validIcons)]
            glovePreviewIconCache[wName] = chosen
            return chosen
        end
        return nil
    end

    getWeaponIcon = function(wName)
        if not wName or wName == "" then return "rbxassetid://83097083839889" end

        local lowerW = string.lower(wName)
        local isGlove = (string.find(lowerW, "glove") ~= nil or string.find(lowerW, "wrap") ~= nil)
        if isGlove then
            local gIcon = getGlovePreviewIcon(wName)
            if gIcon then return gIcon end
        end

        -- 1. Try game's stock icon (immune to equipped custom skins)
        if getStockWeaponIcon then
            local okStock, sIcon = pcall(getStockWeaponIcon, wName)
            if okStock and sIcon and typeof(sIcon) == "string" and sIcon ~= "" and not WeaponDisplaySilhouettes[sIcon] then
                return sIcon
            end
        end

        -- 1b. Try game's Career/WeaponIcon logic
        if CareerWeaponIcon and CareerWeaponIcon.Get then
            local ok, cIcon = pcall(CareerWeaponIcon.Get, wName)
            if ok and cIcon and typeof(cIcon) == "string" and cIcon ~= "" and not WeaponDisplaySilhouettes[cIcon] then
                return cIcon
            end
        end

        -- 2. Try availableSkinsCache (AvaiableSkins attribute dumped at runtime)
        local wSkins = availableSkinsCache[wName]
            or availableSkinsCache[string.gsub(wName, " ", "-")]
            or availableSkinsCache[string.gsub(wName, "-", " ")]

        if wSkins and typeof(wSkins) == "table" then
            for _, sKey in ipairs({ "Vanilla", "Stock", "Standard", "-" }) do
                local sData = wSkins[sKey]
                if sData then
                    local sIcon = (sData.wearImages and #sData.wearImages > 0 and sData.wearImages[1].assetId) or sData.imageAssetId or ""
                    if sIcon ~= "" and not WeaponDisplaySilhouettes[sIcon] then
                        return sIcon
                    end
                end
            end
            for _, sData in pairs(wSkins) do
                local sIcon = (sData.wearImages and #sData.wearImages > 0 and sData.wearImages[1].assetId) or sData.imageAssetId or ""
                if sIcon ~= "" and not WeaponDisplaySilhouettes[sIcon] then
                    return sIcon
                end
            end
        end

        -- 3. Try Skins library (ReplicatedStorage.Database.Components.Libraries.Skins)
        if SkinsLib then
            if SkinsLib.GetAllSkinsForWeapon then
                local ok, allSkins = pcall(SkinsLib.GetAllSkinsForWeapon, wName)
                if ok and allSkins and typeof(allSkins) == "table" then
                    for _, sInfo in ipairs(allSkins) do
                        if sInfo.skin == "Vanilla" or sInfo.skin == "Stock" then
                            local sIcon = (SkinsLib.GetWearImageForFloat and SkinsLib.GetWearImageForFloat(sInfo, 0)) or sInfo.imageAssetId or ""
                            if sIcon ~= "" and not WeaponDisplaySilhouettes[sIcon] then
                                return sIcon
                            end
                        end
                    end
                    for _, sInfo in ipairs(allSkins) do
                        local sIcon = (SkinsLib.GetWearImageForFloat and SkinsLib.GetWearImageForFloat(sInfo, 0)) or sInfo.imageAssetId or ""
                        if sIcon ~= "" and not WeaponDisplaySilhouettes[sIcon] then
                            return sIcon
                        end
                    end
                end
            end
            if SkinsLib.GetSkinInformation then
                for _, sKey in ipairs({ "Vanilla", "Stock" }) do
                    local ok, info = pcall(SkinsLib.GetSkinInformation, wName, sKey)
                    if ok and info then
                        local sIcon = (SkinsLib.GetWearImageForFloat and SkinsLib.GetWearImageForFloat(info, 0)) or info.imageAssetId or ""
                        if sIcon ~= "" and not WeaponDisplaySilhouettes[sIcon] then
                            return sIcon
                        end
                    end
                end
            end
        end

        -- 4. Try GetResolvedSkinInformation
        if GetResolvedSkinInformation then
            for _, sKey in ipairs({ "Vanilla", "Stock" }) do
                local ok, info = pcall(GetResolvedSkinInformation, wName, sKey)
                if ok and info then
                    local sIcon = (info.wearImages and #info.wearImages > 0 and info.wearImages[1].assetId) or info.imageAssetId or ""
                    if sIcon ~= "" and not WeaponDisplaySilhouettes[sIcon] then
                        return sIcon
                    end
                end
            end
        end

        -- 5. Try DefaultWeaponIcons (for guns and other weapons with valid colored 3D icons)
        local def = DefaultWeaponIcons[wName]
            or DefaultWeaponIcons[string.gsub(wName, " ", "-")]
            or DefaultWeaponIcons[string.gsub(wName, "-", " ")]
        if def and def ~= "" and not WeaponDisplaySilhouettes[def] then
            return def
        end

        -- 6. Check GetWeaponProperties (only if not in WeaponDisplaySilhouettes)
        if safeGetWeaponProperties then
            local prop = safeGetWeaponProperties(wName)
            if prop and prop.Icon and not WeaponDisplaySilhouettes[prop.Icon] then
                return prop.Icon
            end
        end

        -- 7. Specific category defaults (Cases, Charms, Keys, Badges)
        if string.find(wName, "Key") then
            return KeyIconDefault
        elseif string.find(wName, "Case") or string.find(wName, "Capsule") or string.find(wName, "Package") or string.find(wName, "Box") or string.find(wName, "Pack") then
            return CaseIconDefault
        elseif string.find(wName, "Charm") or string.find(wName, "Baby") or string.find(wName, "Lil'") or string.find(wName, "Wurst") or string.find(wName, "Howl") then
            return CharmIconDefault
        elseif string.find(wName, "Badge") or string.find(wName, "Medal") or string.find(wName, "Coin") or string.find(wName, "Pass") or string.find(wName, "Veteran") then
            return BadgeIconDefault
        end

        return def or "rbxassetid://83097083839889"
    end

    -- Real BloxStrike Categories and Items (Strict Game Parity)
    local WeaponsByCategory = {
        ["Knives"] = {
            "Butterfly Knife", "Flip Knife", "Gut Knife", "Karambit", "M9 Bayonet",
            "Skeleton Knife", "Stiletto Knife", "CT Knife", "T Knife", "LightSaber"
        },
        ["Pistols"] = {
            "Desert Eagle", "Dual Berettas", "Five-SeveN", "Glock-18", "P250",
            "R8 Revolver", "Tec-9", "USP-S"
        },
        ["Mid-Tier"] = {
            "MAC-10", "MAG-7", "MP9", "Negev", "Nova", "P90", "Sawed-Off", "XM1014"
        },
        ["Rifles"] = {
            "AK-47", "AUG", "AWP", "FAMAS", "Galil AR", "M4A1-S", "M4A4", "SG 553", "SSG 08"
        },
        ["Misc"] = {
            "Zeus x27"
        },
        ["Gloves"] = {
            "Driver Gloves", "Hand Wraps", "Operator Gloves", "Sports Gloves"
        },
        ["Weapon Cases"] = {
            "Winter 2025", "Finishline Case", "Viridian Case", "Nebula Case", "Lionheart",
            "Glove Case 2", "Glove Case", "Chrysalis", "Case #1", "Apex Case",
            "Charm Pack #1", "Hero of Hell Console"
        },
        ["Packages"] = {
            "AK-47 | Lore", "AK-47 | Midas", "AK-47 | PinPoint", "AUG | Anodized Red",
            "AWP | Freedom", "AWP | High Octane", "AWP | Lore", "AWP | Tekko",
            "Desert Eagle | Freedom", "Desert Eagle | High Octane", "Desert Eagle | Lore",
            "Glock-18 | Midas", "Glock-18 | PinPoint", "M4A1-S | Anodized Red",
            "M4A1-S | SuperSoaked", "M4A4 | Freedom", "M4A4 | Tekko", "MAC-10 | Midas",
            "MP-9 | Anodized Red", "MP9 | High Octane", "P90 | PinPoint",
            "Sawed-Off | SuperSoaked", "Tec-9 | Medal.tv", "USP-S | SuperSoaked", "USP-S | Tekko"
        },
        ["Name Tags"] = {
            "Name Tag"
        },
        ["Charms"] = {
            "8-bit Heart", "Anchor", "Billiard Ball", "Bullet", "Bullseye", "CapStone",
            "Cassette", "Cheer", "Contributor", "Credit", "F8", "Flight Tag", "Flora",
            "For Sale", "Game Buddy", "Hero of Hell", "Lil' nade", "Prototype", "Relic",
            "Soda Pop", "South Paw", "Treat"
        },
        ["Badges"] = {
            "Accelerator", "Administrator", "Beta", "Contributor", "Medal.tv",
            "Premium", "Prototype", "Star Creator", "The Ambassador", "Verified"
        },
    }

    local Categories = {
        "Profile", "Equipment", "Containers", "Graphic Art"
    }

    local SubcategoriesByCategory = {
        ["Profile"] = { "Badges" },
        ["Equipment"] = { "Knives", "Pistols", "Mid-Tier", "Rifles", "Misc", "Gloves" },
        ["Containers"] = { "Weapon Cases", "Packages" },
        ["Graphic Art"] = { "Charms" },
    }

    getWeaponClass = function(wName)
        if not wName or wName == "" then return "Weapon" end
        for sub, list in pairs(WeaponsByCategory) do
            for _, item in ipairs(list) do
                if item == wName or string.gsub(item, " ", "-") == wName or string.gsub(item, "-", " ") == wName then
                    if sub == "Knives" then return "Melee" end
                    if sub == "Gloves" then return "Glove" end
                    if sub == "Pistols" then return "Pistol" end
                    if sub == "Rifles" then return "Rifle" end
                    if sub == "Mid-Tier" then
                        if item == "MAC-10" or item == "MP9" or item == "P90" then
                            return "SMG"
                        else
                            return "Heavy"
                        end
                    end
                    if sub == "Misc" then return "Zeus x27" end
                    if sub == "Weapon Cases" then return "Case" end
                    if sub == "Packages" then return "Package" end
                    if sub == "Name Tags" then return "Tool" end
                    if sub == "Charms" then return "Charm" end
                    if sub == "Badges" then return "Badge" end
                end
            end
        end
        if safeGetWeaponProperties then
            local prop = safeGetWeaponProperties(wName)
            if prop then
                if prop.Type then return prop.Type end
                if prop.Class == "Melee" or prop.Slot == "Melee" then return "Melee" end
                if prop.Class == "Glove" then return "Glove" end
                return prop.Class or "Weapon"
            end
        end
        local lower = string.lower(wName)
        if string.find(lower, "knife") or string.find(lower, "bayonet") or string.find(lower, "karambit") or string.find(lower, "lightsaber") then return "Melee" end
        if string.find(lower, "glove") or string.find(lower, "wrap") then return "Glove" end
        if string.find(lower, "case") or string.find(lower, "capsule") then return "Case" end
        if string.find(lower, "package") then return "Package" end
        if string.find(lower, "charm") then return "Charm" end
        if string.find(lower, "badge") then return "Badge" end
        return "Weapon"
    end

    getRarityColor = function(rarityName, isSpecial)
        if isSpecial then return Color3.fromRGB(255, 215, 0) end
        local r = string.lower(tostring(rarityName or ""))
        if string.find(r, "special") then
            return Color3.fromRGB(255, 215, 0)
        elseif string.find(r, "covert") or string.find(r, "extraordinary") or string.find(r, "ancient") or string.find(r, "red") then
            return Color3.fromRGB(245, 60, 60)
        elseif string.find(r, "classified") or string.find(r, "legendary") or string.find(r, "pink") then
            return Color3.fromRGB(225, 65, 195)
        elseif string.find(r, "restricted") or string.find(r, "mythical") or string.find(r, "purple") then
            return Color3.fromRGB(150, 75, 255)
        elseif string.find(r, "mil%-spec") or string.find(r, "milspec") or string.find(r, "rare") or string.find(r, "blue") then
            return Color3.fromRGB(75, 120, 255)
        elseif string.find(r, "industrial") then
            return Color3.fromRGB(95, 160, 235)
        elseif string.find(r, "consumer") then
            return Color3.fromRGB(180, 205, 235)
        end
        return Color3.fromRGB(160, 165, 175)
    end

    local fallbackKnifeSkins = {
        "Fade", "Doppler", "Marble Fade", "Tiger Tooth", "Case Hardened",
        "Crimson Web", "Slaughter", "Lore", "Autotronic", "Gamma Doppler",
        "Vanilla", "Blue Steel", "Night", "Ultraviolet", "Damascus Steel",
        "Rust Coat", "Urban Masked", "Forest DDPAT", "Safari Mesh", "Boreal Forest"
    }

    -- availableSkinsCache hoisted above for glove preview
    local function updateAvailableSkinsCache()
        local attr = ReplicatedStorage:GetAttribute("AvaiableSkins")
        if attr and typeof(attr) == "string" then
            local ok, parsed = pcall(HttpService.JSONDecode, HttpService, attr)
            if ok and typeof(parsed) == "table" then
                availableSkinsCache = parsed
                -- Dynamically augment subcategories if new items are discovered in game
                if availableSkinsCache["Case"] then
                    for cName, _ in pairs(availableSkinsCache["Case"]) do
                        if not table.find(WeaponsByCategory["Weapon Cases"], cName) then
                            table.insert(WeaponsByCategory["Weapon Cases"], cName)
                        end
                    end
                end
                if availableSkinsCache["Package"] then
                    for pName, _ in pairs(availableSkinsCache["Package"]) do
                        if not table.find(WeaponsByCategory["Packages"], pName) then
                            table.insert(WeaponsByCategory["Packages"], pName)
                        end
                    end
                end
                if availableSkinsCache["Charm"] then
                    for chName, _ in pairs(availableSkinsCache["Charm"]) do
                        if not table.find(WeaponsByCategory["Charms"], chName) then
                            table.insert(WeaponsByCategory["Charms"], chName)
                        end
                    end
                end
                if availableSkinsCache["Badge"] then
                    for bName, _ in pairs(availableSkinsCache["Badge"]) do
                        if not table.find(WeaponsByCategory["Badges"], bName) then
                            table.insert(WeaponsByCategory["Badges"], bName)
                        end
                    end
                end
            end
        end
    end
    updateAvailableSkinsCache()
    pcall(function()
        ReplicatedStorage:GetAttributeChangedSignal("AvaiableSkins"):Connect(updateAvailableSkinsCache)
    end)

    local function getWeaponSkins(weaponName)
        local list = {}
        local seen = {}

        local wSkins = availableSkinsCache[weaponName]
            or availableSkinsCache[string.gsub(weaponName, " ", "-")]
            or availableSkinsCache[string.gsub(weaponName, "-", " ")]

        if wSkins and typeof(wSkins) == "table" then
            for sName, sData in pairs(wSkins) do
                if not seen[sName] then
                    seen[sName] = true
                    local icon = ""
                    if sData.wearImages and #sData.wearImages > 0 and sData.wearImages[1].assetId then
                        icon = sData.wearImages[1].assetId
                    elseif sData.imageAssetId and sData.imageAssetId ~= "" then
                        icon = sData.imageAssetId
                    end
                    if icon == "" and SkinsLib and SkinsLib.GetSkinInformation then
                        local ok, info = pcall(SkinsLib.GetSkinInformation, weaponName, sName)
                        if ok and info then
                            if SkinsLib.GetWearImageForFloat then
                                icon = SkinsLib.GetWearImageForFloat(info, 0.0001) or ""
                            end
                            if icon == "" and info.imageAssetId then
                                icon = info.imageAssetId
                            end
                        end
                    end
                    if icon == "" and GetResolvedSkinInformation then
                        local ok2, info2 = pcall(GetResolvedSkinInformation, weaponName, sName)
                        if ok2 and info2 then
                            icon = (info2.wearImages and #info2.wearImages > 0 and info2.wearImages[1].assetId) or info2.imageAssetId or ""
                        end
                    end
                    if icon == "" then
                        icon = getWeaponIcon(weaponName)
                    end
                    table.insert(list, {
                        Skin = sName,
                        Rarity = sData.rarity or "Covert",
                        Icon = icon,
                        SkinData = sData
                    })
                end
            end
        end

        pcall(function()
            local assetsSkins = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Skins")
            if assetsSkins then
                local wFolder = assetsSkins:FindFirstChild(weaponName)
                    or assetsSkins:FindFirstChild(string.gsub(weaponName, " ", "-"))
                    or assetsSkins:FindFirstChild(string.gsub(weaponName, "-", " "))
                if wFolder then
                    for _, sFolder in ipairs(wFolder:GetChildren()) do
                        local sName = sFolder.Name
                        if not seen[sName] then
                            seen[sName] = true
                            local icon = ""
                            if SkinsLib and SkinsLib.GetSkinInformation then
                                local ok, info = pcall(SkinsLib.GetSkinInformation, weaponName, sName)
                                if ok and info then
                                    icon = (SkinsLib.GetWearImageForFloat and SkinsLib.GetWearImageForFloat(info, 0.0001)) or info.imageAssetId or ""
                                end
                            end
                            if icon == "" then
                                icon = getWeaponIcon(weaponName)
                            end
                            table.insert(list, {
                                Skin = sName,
                                Rarity = "Covert",
                                Icon = icon,
                            })
                        end
                    end
                end
            end
        end)

        if #list == 0 then
            table.insert(list, {
                Skin = "Vanilla",
                Rarity = "Special",
                Icon = getWeaponIcon(weaponName),
            })
            local isKnifeOrGlove = (getWeaponClass(weaponName) == "Melee" or getWeaponClass(weaponName) == "Glove")
            if isKnifeOrGlove then
                for _, sName in ipairs(fallbackKnifeSkins) do
                    local icon = ""
                    if SkinsLib and SkinsLib.GetSkinInformation then
                        local ok, info = pcall(SkinsLib.GetSkinInformation, weaponName, sName)
                        if ok and info then
                            icon = (SkinsLib.GetWearImageForFloat and SkinsLib.GetWearImageForFloat(info, 0.0001)) or info.imageAssetId or ""
                        end
                    end
                    if icon == "" then
                        icon = getWeaponIcon(weaponName)
                    end
                    table.insert(list, {
                        Skin = sName,
                        Rarity = (sName == "Doppler" or sName == "Fade" or sName == "Marble Fade") and "Special" or "Covert",
                        Icon = icon,
                    })
                end
            else
                for _, sName in ipairs({"Asiimov", "Redline", "Vulcan", "Hyper Beast", "Printstream"}) do
                    local icon = ""
                    if SkinsLib and SkinsLib.GetSkinInformation then
                        local ok, info = pcall(SkinsLib.GetSkinInformation, weaponName, sName)
                        if ok and info then
                            icon = (SkinsLib.GetWearImageForFloat and SkinsLib.GetWearImageForFloat(info, 0.0001)) or info.imageAssetId or ""
                        end
                    end
                    if icon == "" then
                        icon = getWeaponIcon(weaponName)
                    end
                    table.insert(list, { Skin = sName, Rarity = "Covert", Icon = icon })
                end
            end
        end

        table.sort(list, function(a, b)
            return tostring(a.Skin) < tostring(b.Skin)
        end)

        return list
    end

    local function getItemDisplayData(itemName, subcategory)
        local icon = ""
        local rarity = "Covert"

        if subcategory == "Gloves" or getWeaponClass(itemName) == "Glove" then
            local gIcon = getGlovePreviewIcon(itemName)
            if gIcon then
                return gIcon, "Special"
            end
        end

        if subcategory == "Weapon Cases" or subcategory == "Case" then
            local cData = availableSkinsCache["Case"] and availableSkinsCache["Case"][itemName]
            if cData then
                icon = cData.imageAssetId or (cData.wearImages and cData.wearImages[1] and cData.wearImages[1].assetId) or ""
                rarity = cData.rarity or "Covert"
            end
        elseif subcategory == "Packages" or subcategory == "Package" then
            local pData = availableSkinsCache["Package"] and availableSkinsCache["Package"][itemName]
            if pData then
                icon = pData.imageAssetId or (pData.wearImages and pData.wearImages[1] and pData.wearImages[1].assetId) or ""
                rarity = pData.rarity or "Classified"
            end
        elseif subcategory == "Charms" or subcategory == "Charm" then
            local chData = availableSkinsCache["Charm"] and availableSkinsCache["Charm"][itemName]
            if chData then
                icon = (chData.charmImages and chData.charmImages[1] and chData.charmImages[1].assetId) or chData.imageAssetId or ""
                rarity = chData.rarity or "Purple"
            end
        elseif subcategory == "Badges" or subcategory == "Badge" then
            local bData = availableSkinsCache["Badge"] and availableSkinsCache["Badge"][itemName]
            if bData then
                icon = bData.imageAssetId or (bData.wearImages and bData.wearImages[1] and bData.wearImages[1].assetId) or ""
                rarity = bData.rarity or "Special"
            end
            if icon == "" then
                local bLookup = {
                    ["Beta"] = "rbxassetid://98169487322185",
                    ["Ambassador"] = "rbxassetid://122099710419173",
                    ["The Ambassador"] = "rbxassetid://122099710419173",
                    ["Prototype"] = "rbxassetid://108121837557444",
                    ["Verified"] = "rbxassetid://1158949543",
                    ["Accelerator"] = "rbxassetid://94056445028784",
                    ["Administrator"] = "rbxassetid://102913689742485",
                    ["Premium"] = "rbxassetid://86898254493830",
                    ["Star Creator"] = "rbxassetid://95965239643084",
                                        ["Medal.tv"] = "rbxassetid://124834395957965",
                    ["Contributor"] = "rbxassetid://125370656636279",
                    ["Loyalty"] = "rbxassetid://98169487322185",
                }
                icon = bLookup[itemName] or ""
                rarity = "Special"
            end
        elseif subcategory == "Name Tags" or itemName == "Name Tag" then
            local ntData = availableSkinsCache["Name Tag"] and availableSkinsCache["Name Tag"]["Name Tag"]
            if ntData then
                icon = ntData.imageAssetId or ""
                rarity = ntData.rarity or "Blue"
            end
        end

        if icon == "" then
            icon = getWeaponIcon(itemName)
        end
        return icon, rarity
    end

    -- Resolves the correct icon for a specific weapon+skin combo (not just the default weapon icon)
    local function getSkinSpecificIcon(weaponName, skinName)
        if not weaponName or weaponName == "" or not skinName or skinName == "" then return "" end
        if skinName == "Stock" or skinName == "Vanilla" or skinName == "-" or skinName == "Standard" then
            return getWeaponIcon(weaponName)
        end

        -- 1. Try availableSkinsCache for the specific skin
        local wSkins = availableSkinsCache[weaponName]
            or availableSkinsCache[string.gsub(weaponName, " ", "-")]
            or availableSkinsCache[string.gsub(weaponName, "-", " ")]
        if wSkins and typeof(wSkins) == "table" then
            local sData = wSkins[skinName]
            if sData then
                local sIcon = (sData.wearImages and #sData.wearImages > 0 and sData.wearImages[1].assetId) or sData.imageAssetId or ""
                if sIcon ~= "" and not WeaponDisplaySilhouettes[sIcon] then
                    return sIcon
                end
            end
        end

        -- 2. Try SkinsLib.GetSkinInformation
        if SkinsLib and SkinsLib.GetSkinInformation then
            local ok, info = pcall(SkinsLib.GetSkinInformation, weaponName, skinName)
            if ok and info then
                local sIcon = ""
                if SkinsLib.GetWearImageForFloat then
                    sIcon = SkinsLib.GetWearImageForFloat(info, 0.0001) or ""
                end
                if sIcon == "" and info.imageAssetId then
                    sIcon = info.imageAssetId
                end
                if sIcon ~= "" and not WeaponDisplaySilhouettes[sIcon] then
                    return sIcon
                end
            end
        end

        -- 3. Try GetResolvedSkinInformation
        if GetResolvedSkinInformation then
            local ok, info = pcall(GetResolvedSkinInformation, weaponName, skinName)
            if ok and info then
                local sIcon = (info.wearImages and #info.wearImages > 0 and info.wearImages[1].assetId) or info.imageAssetId or ""
                if sIcon ~= "" and not WeaponDisplaySilhouettes[sIcon] then
                    return sIcon
                end
            end
        end

        -- Fallback to default weapon icon
        return getWeaponIcon(weaponName)
    end

    local function generateId()
        local ok, guid = pcall(function() return HttpService:GenerateGUID(false) end)
        if ok and guid and guid ~= "" then
            return "memesense_" .. guid
        end
        return "memesense_" .. tostring(os.clock()) .. "_" .. tostring(math.random(100000, 999999))
    end

    local function createBloxStrikeItem(name, skin, rarityColor, rarityName, icon, itemType, caseId)
        local itType = itemType
        if not itType then
            itType = getWeaponClass(name)
        end
        local rawSkin = (skin and skin ~= "" and skin ~= "-") and skin or "Stock"
        local realSkin = (rawSkin == "Vanilla") and "Stock" or rawSkin
        local finalIcon = (icon and icon ~= "" and not WeaponDisplaySilhouettes[icon]) and icon or getWeaponIcon(name)
        local isContainer = (itType == "Case" or itType == "Package" or itType == "Console" or itType == "Charm Capsule" or string.find(tostring(itType), "Case") ~= nil or string.find(tostring(itType), "Capsule") ~= nil or string.find(tostring(itType), "Console") ~= nil)
        local isTool = (itType == "Tool")

        local item = {
            _id = generateId(),
            Serial = 1,
            Type = itType,
            Name = name,
            Skin = isContainer and name or realSkin,
            caseId = isContainer and (caseId or name) or nil,
            Float = isContainer and 0 or 0.0001,
            Pattern = isContainer and 0 or 1,
            StatTrack = false,
            StatTrak = false,
            KillCount = 0,
            IsTradeable = false,
            NameTag = false,
            Charm = false,
            Equipped = false,
            Rarity = rarityName or "Covert",
            RarityColor = rarityColor or Color3.fromRGB(235, 75, 75),
            Icon = finalIcon,
            CustomName = "",
            Stickers = {},
            MetaData = {
                LastTradeAt = 0,
                CreatedAt = os.time(),
                OriginalOwner = LocalPlayer.UserId or 0,
                Owner = LocalPlayer.UserId or 0,
                Origin = "MemeSense",
                TradeHistory = {}
            }
        }
        return item
    end

    local function equipItemInLoadout(item)
        if not item then return end
        local realSkin = (item.Skin == "Vanilla" and "Stock") or item.Skin or "Stock"
        local itType = item.Type or getWeaponClass(item.Name)
        local isKnife = (itType == "Melee" or string.find(string.lower(item.Name), "knife") or item.Name == "Karambit" or item.Name == "LightSaber")
        local isGlove = (itType == "Glove" or string.find(string.lower(item.Name), "glove") or string.find(string.lower(item.Name), "wrap"))

        for _, other in ipairs(MemeSenseInventory.Items) do
            if other ~= item then
                local otherType = other.Type or getWeaponClass(other.Name)
                local otherIsKnife = (otherType == "Melee" or string.find(string.lower(other.Name), "knife") or other.Name == "Karambit" or other.Name == "LightSaber")
                local otherIsGlove = (otherType == "Glove" or string.find(string.lower(other.Name), "glove") or string.find(string.lower(other.Name), "wrap"))

                if isKnife and otherIsKnife then
                    other.Equipped = false
                elseif isGlove and otherIsGlove then
                    other.Equipped = false
                elseif sanitize(other.Name) == sanitize(item.Name) then
                    other.Equipped = false
                end
            end
        end
        item.Equipped = true

        for _, tName in ipairs({ "Counter-Terrorists", "Terrorists" }) do
            if isKnife then
                customLoadout[tName].Knife = {
                    Name = item.Name,
                    Skin = realSkin,
                    Float = item.Float or 0.0001
                }
                updateSpecialInMemory(tName, "Equipped Melee", item._id)
                updateSpecialInMemory(tName, "Melee", item._id)
            elseif isGlove then
                customLoadout[tName].Glove = {
                    Name = item.Name,
                    Skin = realSkin,
                    Float = item.Float or 0.0001
                }
                updateSpecialInMemory(tName, "Equipped Gloves", item._id)
                updateSpecialInMemory(tName, "Glove", item._id)
                applyGlovesToCharacter(customLoadout[tName].Glove)
            elseif itType == "Badge" then
                customLoadout[tName].Badge = item
                updateSpecialInMemory(tName, "Equipped Badge", item._id)
                updateSpecialInMemory(tName, "Badge", item._id)
                pcall(function()
                    if DataController then
                        local loadout = DataController.Get(LocalPlayer, "Loadout")
                        if loadout and loadout[tName] then
                            loadout[tName].Equipped = loadout[tName].Equipped or {}
                            loadout[tName].Equipped["Equipped Badge"] = item._id
                        end
                    end
                end)
            else
                customLoadout[tName].Weapons[item.Name] = {
                    Name = item.Name,
                    Skin = realSkin,
                    Float = item.Float or 0.0001,
                    Charm = item.Charm or false
                }
                customLoadout[tName].Weapons[string.gsub(item.Name, " ", "-")] = customLoadout[tName].Weapons[item.Name]
                customLoadout[tName].Weapons[string.gsub(item.Name, "%-", " ")] = customLoadout[tName].Weapons[item.Name]
                pcall(function()
                    if DataController then
                        local loadout, inv = DataController.Get(LocalPlayer, "Loadout", "Inventory")
                        if loadout and loadout[tName] and loadout[tName].Loadout then
                            local catKey = (itType == "Pistol" and "Pistols") or (itType == "Rifle" and "Rifles") or "Mid Tier"
                            local cat = loadout[tName].Loadout[catKey]
                            if cat and cat.Options then
                                local slotFound = nil
                                for sIdx, existingId in ipairs(cat.Options) do
                                    local existing = unlockedDict[existingId]
                                    if existing and (sanitize(existing.Name) == sanitize(item.Name) or existing.Name == item.Name) then
                                        slotFound = sIdx
                                        break
                                    end
                                    if not slotFound and inv and typeof(inv) == "table" then
                                        for _, invItem in ipairs(inv) do
                                            if invItem._id == existingId and (sanitize(invItem.Name) == sanitize(item.Name) or invItem.Name == item.Name) then
                                                slotFound = sIdx
                                                break
                                            end
                                        end
                                    end
                                    if slotFound then break end
                                end
                                if not slotFound then
                                    local nm = sanitize(item.Name)
                                    if catKey == "Pistols" then
                                        if string.find(nm, "glock") or string.find(nm, "usp") or string.find(nm, "p2000") then slotFound = 1
                                        elseif string.find(nm, "dual") then slotFound = 2
                                        elseif string.find(nm, "p250") then slotFound = 3
                                        elseif string.find(nm, "five") or string.find(nm, "tec") or string.find(nm, "cz") then slotFound = 4
                                        elseif string.find(nm, "deagle") or string.find(nm, "desert") or string.find(nm, "revolver") or string.find(nm, "r8") then slotFound = 5
                                        else slotFound = 1 end
                                    elseif catKey == "Rifles" then
                                        if string.find(nm, "famas") or string.find(nm, "galil") then slotFound = 1
                                        elseif string.find(nm, "m4") or string.find(nm, "ak") then slotFound = 2
                                        elseif string.find(nm, "ssg") or string.find(nm, "scout") then slotFound = 3
                                        elseif string.find(nm, "aug") or string.find(nm, "sg") then slotFound = 4
                                        elseif string.find(nm, "awp") or string.find(nm, "scar") or string.find(nm, "g3") then slotFound = 5
                                        else slotFound = 2 end
                                    else -- Mid Tier
                                        if string.find(nm, "mp9") or string.find(nm, "mac") then slotFound = 1
                                        elseif string.find(nm, "mp7") or string.find(nm, "mp5") then slotFound = 2
                                        elseif string.find(nm, "ump") then slotFound = 3
                                        elseif string.find(nm, "p90") or string.find(nm, "bizon") then slotFound = 4
                                        else slotFound = 5 end
                                    end
                                end
                                cat.Options[slotFound] = item._id
                                while #cat.Options > 5 do
                                    table.remove(cat.Options)
                                end
                            end
                            pcall(function()
                                if Remotes and Remotes.PlayerData and Remotes.PlayerData.PlayerDataChanged then
                                    Remotes.PlayerData.PlayerDataChanged.Fire({
                                        Player = LocalPlayer,
                                        Data = { ["Loadout"] = loadout }
                                    })
                                end
                                local loadoutModule = nil
                                pcall(function()
                                    local loadoutScr = ReplicatedStorage:FindFirstChild("Interface", true)
                                    if loadoutScr then
                                        local lm = loadoutScr:FindFirstChild("Loadout", true)
                                        if lm and lm:IsA("ModuleScript") then
                                            loadoutModule = require(lm)
                                        end
                                    end
                                end)
                                if not loadoutModule then
                                    pcall(function()
                                        local pGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
                                        if pGui then
                                            local lm = pGui:FindFirstChild("Loadout", true)
                                            if lm and lm:IsA("ModuleScript") then
                                                loadoutModule = require(lm)
                                            end
                                        end
                                    end)
                                end
                                if loadoutModule then
                                    pcall(function()
                                        if loadoutModule.UpdateLoadoutContainer then loadoutModule.UpdateLoadoutContainer(loadout) end
                                        if loadoutModule.UpdateSidebarFrames then loadoutModule.UpdateSidebarFrames(loadout) end
                                    end)
                                end
                            end)
                        end
                    end
                end)
            end
        end
    end

    local function unequipItemInLoadout(item)
        if not item then return end
        item.Equipped = false
        local itType = item.Type or getWeaponClass(item.Name)
        local isKnife = (itType == "Melee" or string.find(string.lower(item.Name), "knife") or item.Name == "Karambit" or item.Name == "LightSaber")
        local isGlove = (itType == "Glove" or string.find(string.lower(item.Name), "glove") or string.find(string.lower(item.Name), "wrap"))

        for _, tName in ipairs({ "Counter-Terrorists", "Terrorists" }) do
            if isKnife then
                customLoadout[tName].Knife = nil
            elseif isGlove then
                customLoadout[tName].Glove = nil
            else
                customLoadout[tName].Weapons[item.Name] = nil
                customLoadout[tName].Weapons[string.gsub(item.Name, " ", "-")] = nil
                customLoadout[tName].Weapons[string.gsub(item.Name, "%-", " ")] = nil
            end
        end
    end

    local function syncGameInventory()
        task.spawn(function()
            pcall(function()
                if not DataController then return end
                if not DataController.IsDataLoaded(LocalPlayer) then
                    pcall(function()
                        DataController.WaitForDataLoaded(LocalPlayer)
                    end)
                end
                local toInject = {}
                for _, item in ipairs(MemeSenseInventory.Items) do
                    if not item.MetaData or typeof(item.MetaData) ~= "table" then
                        item.MetaData = {
                            LastTradeAt = 0,
                            CreatedAt = os.time(),
                            OriginalOwner = 0,
                            Owner = 0,
                            Origin = "MemeSense",
                            TradeHistory = {}
                        }
                    else
                        if item.MetaData.LastTradeAt == nil then item.MetaData.LastTradeAt = 0 end
                        if item.MetaData.CreatedAt == nil then item.MetaData.CreatedAt = os.time() end
                    end
                    if item.StatTrack == nil then item.StatTrack = false end
                    if item.Serial == nil then item.Serial = 1 end
                    unlockedDict[item._id] = item
                    if not injectedItemIds[item._id] then
                        injectedItemIds[item._id] = true
                        table.insert(toInject, item)
                    end
                end
                if #toInject > 0 then
                    DataController.ApplyInventoryDelta(LocalPlayer, toInject)
                end
            end)
        end)
    end
    MemeSenseInventory.SyncGame = syncGameInventory

    MemeSenseInventory.OnMasterSwitchChanged = function(enabled)
        if not enabled then
            for _, tName in ipairs({ "Counter-Terrorists", "Terrorists" }) do
                customLoadout[tName].Knife = nil
                customLoadout[tName].Glove = nil
                customLoadout[tName].Badge = nil
                customLoadout[tName].Weapons = {}
                pcall(function()
                    if DataController then
                        local loadout = DataController.Get(LocalPlayer, "Loadout")
                        if loadout and loadout[tName] then
                            if loadout[tName].Equipped then
                                loadout[tName].Equipped["Equipped Melee"] = nil
                                loadout[tName].Equipped["Melee"] = nil
                                loadout[tName].Equipped["Equipped Gloves"] = nil
                                loadout[tName].Equipped["Glove"] = nil
                                loadout[tName].Equipped["Equipped Badge"] = nil
                                loadout[tName].Equipped["Badge"] = nil
                            end
                            if loadout[tName].Loadout then
                                for _, cat in pairs(loadout[tName].Loadout) do
                                    if cat and cat.Options then
                                        for sIdx, optId in pairs(cat.Options) do
                                            if optId and (string.sub(tostring(optId), 1, 10) == "memesense_" or unlockedDict[optId]) then
                                                cat.Options[sIdx] = nil
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
            end
            for _, it in ipairs(MemeSenseInventory.Items) do
                it.Equipped = false
            end
            pcall(function()
                if DataController and DataController.ApplyInventoryDelta then
                    DataController.ApplyInventoryDelta(LocalPlayer, {})
                end
            end)
            pcall(refreshGridItems)
        else
            syncGameInventory()
        end
    end

    -- ========================================================================
    -- ROOT UI CONTAINERS (Created ONCE at startup)
    -- ========================================================================
    local InvContainer = Instance.new("Frame")
    InvContainer.Name = "InventoryMainContainer"
    InvContainer.Size = UDim2.new(1, -28, 1, -12)
    InvContainer.Position = UDim2.new(0, 14, 0, 8)
    InvContainer.BackgroundTransparency = 1
    InvContainer.Parent = InventoryTab.Content

    -- [Category Navigation Bar] (Top of tab content)
    local CategoryBar = Instance.new("Frame")
    CategoryBar.Name = "CategoryBar"
    CategoryBar.Size = UDim2.new(1, 0, 0, 32)
    CategoryBar.Position = UDim2.new(0, 0, 0, 2)
    CategoryBar.BackgroundTransparency = 1
    CategoryBar.Parent = InvContainer

    local CatUnderline = Instance.new("Frame")
    CatUnderline.Name = "CatUnderline"
    CatUnderline.Size = UDim2.new(0, 60, 0, 2)
    CatUnderline.Position = UDim2.new(0, 4, 1, -2)
    CatUnderline.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    CatUnderline.BorderSizePixel = 0
    CatUnderline.ZIndex = 5
    CatUnderline.Parent = CategoryBar

    -- [Subcategory Navigation Bar]
    local SubcategoryBar = Instance.new("Frame")
    SubcategoryBar.Name = "SubcategoryBar"
    SubcategoryBar.Size = UDim2.new(1, 0, 0, 26)
    SubcategoryBar.Position = UDim2.new(0, 0, 0, 36)
    SubcategoryBar.BackgroundTransparency = 1
    SubcategoryBar.Parent = InvContainer

    -- Horizontal Divider Line
    local DividerLine = Instance.new("Frame")
    DividerLine.Name = "DividerLine"
    DividerLine.Size = UDim2.new(1, 0, 0, 1)
    DividerLine.Position = UDim2.new(0, 0, 0, 64)
    DividerLine.BackgroundColor3 = Color3.fromRGB(26, 28, 33)
    DividerLine.BorderSizePixel = 0
    DividerLine.Parent = InvContainer

    -- [Views Area]
    local ViewsHolder = Instance.new("Frame")
    ViewsHolder.Name = "ViewsHolder"
    ViewsHolder.Size = UDim2.new(1, 0, 1, -68)
    ViewsHolder.Position = UDim2.new(0, 0, 0, 68)
    ViewsHolder.BackgroundTransparency = 1
    ViewsHolder.Parent = InvContainer

    -- ------------------------------------------------------------------------
    -- VIEW 1: ViewGrid (Main Inventory Grid)
    -- ------------------------------------------------------------------------
    local ViewGrid = Instance.new("ScrollingFrame")
    ViewGrid.Name = "ViewGrid"
    ViewGrid.Size = UDim2.new(1, 0, 1, 0)
    ViewGrid.BackgroundTransparency = 1
    ViewGrid.BorderSizePixel = 0
    ViewGrid.ScrollBarThickness = 3
    ViewGrid.ScrollBarImageColor3 = Color3.fromRGB(45, 48, 60)
    ViewGrid.CanvasSize = UDim2.new(0, 0, 0, 0)
    ViewGrid.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ViewGrid.Visible = true
    ViewGrid.Parent = ViewsHolder

    local ViewGridLayout = Instance.new("UIGridLayout")
    ViewGridLayout.CellSize = UDim2.new(0, 114, 0, 114)
    ViewGridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
    ViewGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ViewGridLayout.Parent = ViewGrid

    -- Card 1: [+] Add Button
    local AddCard = Instance.new("TextButton")
    AddCard.Name = "AddCard"
    AddCard.BackgroundColor3 = Color3.fromRGB(18, 20, 25)
    AddCard.BorderSizePixel = 0
    AddCard.Text = ""
    AddCard.AutoButtonColor = false
    AddCard.LayoutOrder = 1
    AddCard.Parent = ViewGrid
    createCorner(AddCard, 4)
    createStroke(AddCard, Color3.fromRGB(28, 30, 38), 1)

    local CircleBadge = Instance.new("Frame")
    CircleBadge.Name = "CircleBadge"
    CircleBadge.Size = UDim2.new(0, 44, 0, 44)
    CircleBadge.Position = UDim2.new(0.5, -22, 0.5, -22)
    CircleBadge.BackgroundColor3 = Color3.fromRGB(36, 39, 48)
    CircleBadge.BorderSizePixel = 0
    CircleBadge.Parent = AddCard
    createCorner(CircleBadge, 22)

    local PlusIcon = Instance.new("TextLabel")
    PlusIcon.Size = UDim2.new(1, 0, 1, 0)
    PlusIcon.BackgroundTransparency = 1
    PlusIcon.Text = "+"
    PlusIcon.TextColor3 = Color3.fromRGB(220, 225, 235)
    PlusIcon.TextSize = 26
    PlusIcon.Font = Theme.FontBold
    PlusIcon.TextXAlignment = Enum.TextXAlignment.Center
    PlusIcon.TextYAlignment = Enum.TextYAlignment.Center
    PlusIcon.Parent = CircleBadge

    AddCard.MouseEnter:Connect(function()
        CircleBadge.BackgroundColor3 = Color3.fromRGB(50, 55, 68)
        AddCard.BackgroundColor3 = Color3.fromRGB(22, 24, 30)
    end)
    AddCard.MouseLeave:Connect(function()
        CircleBadge.BackgroundColor3 = Color3.fromRGB(36, 39, 48)
        AddCard.BackgroundColor3 = Color3.fromRGB(18, 20, 25)
    end)

    -- Pre-Created Pool of 64 Reusable Inventory Item Cards
    local ItemCardsPool = {}

    for i = 1, 64 do
        local ICard = Instance.new("TextButton")
        ICard.Name = "ItemCard_" .. i
        ICard.BackgroundColor3 = Color3.fromRGB(18, 20, 25)
        ICard.BorderSizePixel = 0
        ICard.Text = ""
        ICard.AutoButtonColor = false
        ICard.LayoutOrder = i + 1
        ICard.Visible = false
        ICard.Parent = ViewGrid
        createCorner(ICard, 4)
        local IStroke = createStroke(ICard, Color3.fromRGB(28, 30, 38), 1)

        local Thumb = Instance.new("ImageLabel")
        Thumb.Name = "Thumb"
        Thumb.AnchorPoint = Vector2.new(0.5, 0.5)
        Thumb.Position = UDim2.new(0.5, 0, 0, 44)
        Thumb.Size = UDim2.new(1, -12, 0, 76)
        Thumb.BackgroundTransparency = 1
        Thumb.Image = "rbxassetid://90954924716133"
        Thumb.ScaleType = Enum.ScaleType.Fit
        Thumb.ZIndex = 2
        Thumb.Parent = ICard

        local Title = Instance.new("TextLabel")
        Title.Name = "Title"
        Title.Size = UDim2.new(1, -12, 0, 16)
        Title.Position = UDim2.new(0, 6, 1, -22)
        Title.BackgroundTransparency = 1
        Title.Text = ""
        Title.TextColor3 = Color3.fromRGB(255, 255, 255)
        Title.TextSize = 11
        Title.Font = Theme.FontBold
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.ClipsDescendants = true
        Title.Parent = ICard

        local SkinLabel = Instance.new("TextLabel")
        SkinLabel.Name = "SkinLabel"
        SkinLabel.Size = UDim2.new(1, -12, 0, 0)
        SkinLabel.Position = UDim2.new(0, 6, 1, -22)
        SkinLabel.BackgroundTransparency = 1
        SkinLabel.Text = ""
        SkinLabel.TextColor3 = Color3.fromRGB(160, 165, 175)
        SkinLabel.TextSize = 10
        SkinLabel.Font = Theme.FontRegular
        SkinLabel.TextXAlignment = Enum.TextXAlignment.Left
        SkinLabel.ClipsDescendants = true
        SkinLabel.Visible = false
        SkinLabel.Parent = ICard

        local EquippedLine = Instance.new("Frame")
        EquippedLine.Name = "EquippedLine"
        EquippedLine.Size = UDim2.new(1, 0, 0, 2)
        EquippedLine.Position = UDim2.new(0, 0, 1, -2)
        EquippedLine.BackgroundColor3 = Color3.fromRGB(180, 210, 255)
        EquippedLine.BorderSizePixel = 0
        EquippedLine.Visible = true
        EquippedLine.Parent = ICard

        local RemoveBtn = Instance.new("TextButton")
        RemoveBtn.Name = "RemoveBtn"
        RemoveBtn.Size = UDim2.new(0, 18, 0, 18)
        RemoveBtn.Position = UDim2.new(1, -19, 0, 2)
        RemoveBtn.BackgroundTransparency = 1
        RemoveBtn.ZIndex = 5
        RemoveBtn.Text = "x"
        RemoveBtn.TextColor3 = Color3.fromRGB(120, 125, 135)
        RemoveBtn.TextSize = 12
        RemoveBtn.Font = Theme.FontBold
        RemoveBtn.Parent = ICard

        RemoveBtn.MouseEnter:Connect(function()
            RemoveBtn.TextColor3 = Color3.fromRGB(245, 55, 72)
        end)
        RemoveBtn.MouseLeave:Connect(function()
            RemoveBtn.TextColor3 = Color3.fromRGB(120, 125, 135)
        end)

        ICard.MouseEnter:Connect(function()
            ICard.BackgroundColor3 = Color3.fromRGB(24, 26, 33)
        end)
        ICard.MouseLeave:Connect(function()
            ICard.BackgroundColor3 = Color3.fromRGB(18, 20, 25)
        end)

        table.insert(ItemCardsPool, {
            Root = ICard,
            Thumb = Thumb,
            Title = Title,
            SkinLabel = SkinLabel,
            EquippedLine = EquippedLine,
            RemoveBtn = RemoveBtn,
            Stroke = IStroke,
            CurrentItem = nil,
            IsRemoving = false,
        })
    end

    -- ------------------------------------------------------------------------
    -- VIEW 2: ViewWeaponSelect (Select Item / Weapon View)
    -- ------------------------------------------------------------------------
    local ViewWeaponSelect = Instance.new("Frame")
    ViewWeaponSelect.Name = "ViewWeaponSelect"
    ViewWeaponSelect.Size = UDim2.new(1, 0, 1, 0)
    ViewWeaponSelect.BackgroundTransparency = 1
    ViewWeaponSelect.Visible = false
    ViewWeaponSelect.Parent = ViewsHolder

    local WHeader = Instance.new("Frame")
    WHeader.Name = "Header"
    WHeader.Size = UDim2.new(1, 0, 0, 32)
    WHeader.BackgroundTransparency = 1
    WHeader.Parent = ViewWeaponSelect

    local WBackBtn = Instance.new("TextButton")
    WBackBtn.Name = "BackBtn"
    WBackBtn.Size = UDim2.new(0, 68, 0, 26)
    WBackBtn.Position = UDim2.new(0, 2, 0, 3)
    WBackBtn.BackgroundColor3 = Color3.fromRGB(24, 26, 33)
    WBackBtn.BorderSizePixel = 0
    WBackBtn.Text = "< Back"
    WBackBtn.TextColor3 = Color3.fromRGB(210, 215, 225)
    WBackBtn.TextSize = 12
    WBackBtn.Font = Theme.FontMedium
    WBackBtn.AutoButtonColor = false
    WBackBtn.Parent = WHeader
    createCorner(WBackBtn, 3)
    createStroke(WBackBtn, Color3.fromRGB(38, 41, 52), 1)

    WBackBtn.MouseEnter:Connect(function()
        WBackBtn.BackgroundColor3 = Color3.fromRGB(32, 35, 45)
    end)
    WBackBtn.MouseLeave:Connect(function()
        WBackBtn.BackgroundColor3 = Color3.fromRGB(24, 26, 33)
    end)

    local WTitle = Instance.new("TextLabel")
    WTitle.Name = "Title"
    WTitle.Size = UDim2.new(0, 250, 1, 0)
    WTitle.Position = UDim2.new(0, 80, 0, 0)
    WTitle.BackgroundTransparency = 1
    WTitle.Text = "Select Weapon"
    WTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    WTitle.TextSize = 13
    WTitle.Font = Theme.FontBold
    WTitle.TextXAlignment = Enum.TextXAlignment.Left
    WTitle.Parent = WHeader

    local WSearch = Instance.new("TextBox")
    WSearch.Name = "Search"
    WSearch.Size = UDim2.new(0, 150, 0, 26)
    WSearch.Position = UDim2.new(1, -150, 0, 3)
    WSearch.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
    WSearch.BorderSizePixel = 0
    WSearch.PlaceholderText = "Search..."
    WSearch.PlaceholderColor3 = Color3.fromRGB(110, 115, 125)
    WSearch.Text = ""
    WSearch.TextColor3 = Color3.fromRGB(240, 245, 255)
    WSearch.TextSize = 11
    WSearch.Font = Theme.FontRegular
    WSearch.Parent = WHeader
    createCorner(WSearch, 3)
    createStroke(WSearch, Color3.fromRGB(32, 35, 44), 1)

    local WeaponScroll = Instance.new("ScrollingFrame")
    WeaponScroll.Name = "WeaponScroll"
    WeaponScroll.Size = UDim2.new(1, 0, 1, -38)
    WeaponScroll.Position = UDim2.new(0, 0, 0, 38)
    WeaponScroll.BackgroundTransparency = 1
    WeaponScroll.BorderSizePixel = 0
    WeaponScroll.ScrollBarThickness = 3
    WeaponScroll.ScrollBarImageColor3 = Color3.fromRGB(45, 48, 60)
    WeaponScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    WeaponScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    WeaponScroll.Parent = ViewWeaponSelect

    local WeaponGridLayout = Instance.new("UIGridLayout")
    WeaponGridLayout.CellSize = UDim2.new(0, 114, 0, 114)
    WeaponGridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
    WeaponGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    WeaponGridLayout.Parent = WeaponScroll

    -- Pre-Created Pool of 64 Reusable Weapon Selection Cards
    local WeaponCardsPool = {}
    local selectedWeaponName = nil

    for i = 1, 64 do
        local WCard = Instance.new("TextButton")
        WCard.Name = "WeaponCard_" .. i
        WCard.BackgroundColor3 = Color3.fromRGB(18, 20, 25)
        WCard.BorderSizePixel = 0
        WCard.Text = ""
        WCard.AutoButtonColor = false
        WCard.LayoutOrder = i
        WCard.Visible = false
        WCard.Parent = WeaponScroll
        createCorner(WCard, 4)
        createStroke(WCard, Color3.fromRGB(28, 30, 38), 1)

        local Thumb = Instance.new("ImageLabel")
        Thumb.Name = "Thumb"
        Thumb.AnchorPoint = Vector2.new(0.5, 0.5)
        Thumb.Position = UDim2.new(0.5, 0, 0, 44)
        Thumb.Size = UDim2.new(1, -12, 0, 76)
        Thumb.BackgroundTransparency = 1
        Thumb.Image = "rbxassetid://90954924716133"
        Thumb.ScaleType = Enum.ScaleType.Fit
        Thumb.ZIndex = 2
        Thumb.Parent = WCard

        local Label = Instance.new("TextLabel")
        Label.Name = "Label"
        Label.Size = UDim2.new(1, -12, 0, 20)
        Label.Position = UDim2.new(0, 6, 1, -26)
        Label.BackgroundTransparency = 1
        Label.Text = ""
        Label.TextColor3 = Color3.fromRGB(255, 255, 255)
        Label.TextSize = 11
        Label.Font = Theme.FontBold
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.ClipsDescendants = true
        Label.Parent = WCard

        local RarityLine = Instance.new("Frame")
        RarityLine.Name = "RarityLine"
        RarityLine.Size = UDim2.new(1, 0, 0, 3)
        RarityLine.Position = UDim2.new(0, 0, 1, -3)
        RarityLine.BackgroundColor3 = Color3.fromRGB(180, 210, 255)
        RarityLine.BorderSizePixel = 0
        RarityLine.Visible = false
        RarityLine.Parent = WCard

        WCard.MouseEnter:Connect(function()
            WCard.BackgroundColor3 = Color3.fromRGB(24, 26, 33)
        end)
        WCard.MouseLeave:Connect(function()
            WCard.BackgroundColor3 = Color3.fromRGB(18, 20, 25)
        end)

        table.insert(WeaponCardsPool, {
            Root = WCard,
            Thumb = Thumb,
            Label = Label,
            RarityLine = RarityLine,
            WeaponName = "",
        })
    end

    -- ------------------------------------------------------------------------
    -- VIEW 3: ViewSkinSelect (Select Skin View)
    -- ------------------------------------------------------------------------
    local ViewSkinSelect = Instance.new("Frame")
    ViewSkinSelect.Name = "ViewSkinSelect"
    ViewSkinSelect.Size = UDim2.new(1, 0, 1, 0)
    ViewSkinSelect.BackgroundTransparency = 1
    ViewSkinSelect.Visible = false
    ViewSkinSelect.Parent = ViewsHolder

    local SHeader = Instance.new("Frame")
    SHeader.Name = "Header"
    SHeader.Size = UDim2.new(1, 0, 0, 32)
    SHeader.BackgroundTransparency = 1
    SHeader.Parent = ViewSkinSelect

    local SBackBtn = Instance.new("TextButton")
    SBackBtn.Name = "BackBtn"
    SBackBtn.Size = UDim2.new(0, 68, 0, 26)
    SBackBtn.Position = UDim2.new(0, 2, 0, 3)
    SBackBtn.BackgroundColor3 = Color3.fromRGB(24, 26, 33)
    SBackBtn.BorderSizePixel = 0
    SBackBtn.Text = "< Back"
    SBackBtn.TextColor3 = Color3.fromRGB(210, 215, 225)
    SBackBtn.TextSize = 12
    SBackBtn.Font = Theme.FontMedium
    SBackBtn.AutoButtonColor = false
    SBackBtn.Parent = SHeader
    createCorner(SBackBtn, 3)
    createStroke(SBackBtn, Color3.fromRGB(38, 41, 52), 1)

    SBackBtn.MouseEnter:Connect(function()
        SBackBtn.BackgroundColor3 = Color3.fromRGB(32, 35, 45)
    end)
    SBackBtn.MouseLeave:Connect(function()
        SBackBtn.BackgroundColor3 = Color3.fromRGB(24, 26, 33)
    end)

    local STitle = Instance.new("TextLabel")
    STitle.Name = "Title"
    STitle.Size = UDim2.new(0, 250, 1, 0)
    STitle.Position = UDim2.new(0, 80, 0, 0)
    STitle.BackgroundTransparency = 1
    STitle.Text = "Select Skin"
    STitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    STitle.TextSize = 13
    STitle.Font = Theme.FontBold
    STitle.TextXAlignment = Enum.TextXAlignment.Left
    STitle.Parent = SHeader

    local SSearch = Instance.new("TextBox")
    SSearch.Name = "Search"
    SSearch.Size = UDim2.new(0, 150, 0, 26)
    SSearch.Position = UDim2.new(1, -150, 0, 3)
    SSearch.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
    SSearch.BorderSizePixel = 0
    SSearch.PlaceholderText = "Search..."
    SSearch.PlaceholderColor3 = Color3.fromRGB(110, 115, 125)
    SSearch.Text = ""
    SSearch.TextColor3 = Color3.fromRGB(240, 245, 255)
    SSearch.TextSize = 11
    SSearch.Font = Theme.FontRegular
    SSearch.Parent = SHeader
    createCorner(SSearch, 3)
    createStroke(SSearch, Color3.fromRGB(32, 35, 44), 1)

    local SkinScroll = Instance.new("ScrollingFrame")
    SkinScroll.Name = "SkinScroll"
    SkinScroll.Size = UDim2.new(1, 0, 1, -38)
    SkinScroll.Position = UDim2.new(0, 0, 0, 38)
    SkinScroll.BackgroundTransparency = 1
    SkinScroll.BorderSizePixel = 0
    SkinScroll.ScrollBarThickness = 3
    SkinScroll.ScrollBarImageColor3 = Color3.fromRGB(45, 48, 60)
    SkinScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    SkinScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    SkinScroll.Parent = ViewSkinSelect

    local SkinGridLayout = Instance.new("UIGridLayout")
    SkinGridLayout.CellSize = UDim2.new(0, 114, 0, 114)
    SkinGridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
    SkinGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    SkinGridLayout.Parent = SkinScroll

    -- Pre-Created Pool of 96 Reusable Skin Selection Cards
    local SkinCardsPool = {}
    local currentSkinList = {}

    for i = 1, 96 do
        local SCard = Instance.new("TextButton")
        SCard.Name = "SkinCard_" .. i
        SCard.BackgroundColor3 = Color3.fromRGB(18, 20, 25)
        SCard.BorderSizePixel = 0
        SCard.Text = ""
        SCard.AutoButtonColor = false
        SCard.LayoutOrder = i
        SCard.Visible = false
        SCard.Parent = SkinScroll
        createCorner(SCard, 4)
        createStroke(SCard, Color3.fromRGB(28, 30, 38), 1)

        local Thumb = Instance.new("ImageLabel")
        Thumb.Name = "Thumb"
        Thumb.AnchorPoint = Vector2.new(0.5, 0.5)
        Thumb.Position = UDim2.new(0.5, 0, 0, 44)
        Thumb.Size = UDim2.new(1, -12, 0, 76)
        Thumb.BackgroundTransparency = 1
        Thumb.Image = "rbxassetid://90954924716133"
        Thumb.ScaleType = Enum.ScaleType.Fit
        Thumb.ZIndex = 2
        Thumb.Parent = SCard

        local Label = Instance.new("TextLabel")
        Label.Name = "Label"
        Label.Size = UDim2.new(1, -12, 0, 20)
        Label.Position = UDim2.new(0, 6, 1, -26)
        Label.BackgroundTransparency = 1
        Label.Text = ""
        Label.TextColor3 = Color3.fromRGB(255, 255, 255)
        Label.TextSize = 11
        Label.Font = Theme.FontBold
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.ClipsDescendants = true
        Label.Parent = SCard

        local RarityLine = Instance.new("Frame")
        RarityLine.Name = "RarityLine"
        RarityLine.Size = UDim2.new(1, 0, 0, 2)
        RarityLine.Position = UDim2.new(0, 0, 1, -2)
        RarityLine.BackgroundColor3 = Color3.fromRGB(150, 155, 165)
        RarityLine.BorderSizePixel = 0
        RarityLine.Parent = SCard

        SCard.MouseEnter:Connect(function()
            SCard.BackgroundColor3 = Color3.fromRGB(24, 26, 33)
        end)
        SCard.MouseLeave:Connect(function()
            SCard.BackgroundColor3 = Color3.fromRGB(18, 20, 25)
        end)

        table.insert(SkinCardsPool, {
            Root = SCard,
            Thumb = Thumb,
            Label = Label,
            RarityLine = RarityLine,
            SkinData = nil,
        })
    end

    -- ========================================================================
    -- VIEW SWITCHING & RENDERING LOGIC (ZERO Instance creation on click)
    -- ========================================================================
    -- refreshGridItems declared in outer scope above
    local openWeaponSelectView = nil
    local openSkinSelectView = nil

    local function itemMatchesSubcategory(item, cat, sub)
        if not item then return false end
        if cat == "Equipment" then
            if sub == "Knives" and (item.Type == "Melee" or string.find(string.lower(item.Name or ""), "knife") or string.find(string.lower(item.Name or ""), "bayonet") or string.find(string.lower(item.Name or ""), "karambit") or string.find(string.lower(item.Name or ""), "lightsaber")) then
                return true
            end
            if sub == "Gloves" and (item.Type == "Glove" or string.find(string.lower(item.Name or ""), "glove") or string.find(string.lower(item.Name or ""), "wrap")) then
                return true
            end
            local wList = WeaponsByCategory[sub] or {}
            for _, w in ipairs(wList) do
                if item.Name == w or item.Name == string.gsub(w, "-", " ") or item.Name == string.gsub(w, " ", "-") then
                    return true
                end
            end
            return false
        elseif cat == "Containers" then
            if sub == "Weapon Cases" then
                return item.Type == "Case" or string.find(item.Name, "Case") or string.find(item.Name, "Pack") or string.find(item.Name, "Chrysalis") or string.find(item.Name, "Console") or string.find(item.Name, "Lionheart")
            elseif sub == "Packages" then
                return item.Type == "Package" or string.find(item.Name, "|")
            end
        elseif cat == "Graphic Art" then
            return item.Type == "Charm"
        elseif cat == "Profile" then
            return item.Type == "Badge"
        end
        return false
    end

    refreshGridItems = function()
        local cat = MemeSenseInventory.CurrentCategory
        local sub = MemeSenseInventory.CurrentSubcategory
        local matchingItems = {}

        for _, item in ipairs(MemeSenseInventory.Items) do
            if itemMatchesSubcategory(item, cat, sub) then
                table.insert(matchingItems, item)
            end
        end

        for i, cardData in ipairs(ItemCardsPool) do
            local item = matchingItems[i]
            if item then
                cardData.CurrentItem = item
                -- Only show the clean single-line skin name, matching screenshot
                local sText = item.Skin
                if not sText or sText == "" or sText == "-" or sText == "Vanilla" or sText == "Standard" then
                    sText = item.Name
                end
                cardData.Title.Text = sText
                cardData.Title.Position = UDim2.new(0, 6, 1, -22)
                cardData.Title.Size = UDim2.new(1, -12, 0, 16)
                cardData.SkinLabel.Text = ""
                cardData.SkinLabel.Visible = false
                -- Resolve the correct skin-specific icon instead of the default weapon icon
                local finalIcon = ""
                if item.Icon and item.Icon ~= "" and not WeaponDisplaySilhouettes[item.Icon] then
                    finalIcon = item.Icon
                else
                    -- Try to get the specific skin's icon
                    local skinIcon = ""
                    pcall(function()
                        skinIcon = getSkinSpecificIcon(item.Name, item.Skin)
                    end)
                    if skinIcon and skinIcon ~= "" and not WeaponDisplaySilhouettes[skinIcon] then
                        finalIcon = skinIcon
                    else
                        local displayIcon, _ = getItemDisplayData(item.Name, sub)
                        finalIcon = displayIcon
                    end
                end
                cardData.Thumb.Image = finalIcon
                local isKG = (getWeaponClass(item.Name) == "Melee" or getWeaponClass(item.Name) == "Glove")
                local rColor = item.RarityColor or getRarityColor(item.Rarity, isKG)
                cardData.EquippedLine.BackgroundColor3 = rColor
                cardData.Root.BackgroundColor3 = Color3.fromRGB(18, 20, 25)
                cardData.EquippedLine.Size = UDim2.new(1, 0, 0, 2)
                cardData.EquippedLine.BackgroundTransparency = 0
                cardData.Root.Visible = true
            else
                cardData.CurrentItem = nil
                cardData.Root.Visible = false
            end
        end
    end

    -- Connect Item Cards click events (Instant Delete)
    for _, cardData in ipairs(ItemCardsPool) do

        cardData.RemoveBtn.MouseButton1Down:Connect(function()
            cardData.IsRemoving = true
        end)

        cardData.RemoveBtn.MouseButton1Click:Connect(function()
            cardData.IsRemoving = true
            local it = cardData.CurrentItem
            if it then
                local removeId = it._id
                cardData.CurrentItem = nil
                for idx, other in ipairs(MemeSenseInventory.Items) do
                    if other._id == removeId then
                        table.remove(MemeSenseInventory.Items, idx)
                        break
                    end
                end
                injectedItemIds[removeId] = nil
                unlockedDict[removeId] = nil
                pcall(refreshGridItems)
                task.spawn(function()
                    pcall(unequipItemInLoadout, it)
                    pcall(function()
                        if DataController and DataController.ApplyInventoryDelta then
                            DataController.ApplyInventoryDelta(LocalPlayer, {}, { removeId })
                        end
                    end)
                    pcall(syncGameInventory)
                end)
            end
            task.delay(0.2, function()
                cardData.IsRemoving = false
            end)
        end)
    end

    -- Cache for default weapon icons so equipped custom skins don't corrupt weapon card previews
    local defaultWeaponIconCache = {}

    openWeaponSelectView = function()
        ViewGrid.Visible = false
        ViewSkinSelect.Visible = false
        ViewWeaponSelect.Visible = true
        MemeSenseInventory.ActiveView = "WeaponSelect"

        local cat = MemeSenseInventory.CurrentCategory
        local sub = MemeSenseInventory.CurrentSubcategory
        WTitle.Text = "Select " .. (sub or cat)
        WSearch.Text = ""

        for _, cardData in ipairs(WeaponCardsPool) do
            cardData.WeaponName = ""
            cardData.Root.Visible = false
        end

        local rawList = WeaponsByCategory[sub] or {}
        local filterText = string.lower(WSearch.Text)

        local displayedList = {}
        for _, wName in ipairs(rawList) do
            if filterText == "" or string.find(string.lower(wName), filterText) then
                table.insert(displayedList, wName)
            end
        end

        for i, cardData in ipairs(WeaponCardsPool) do
            local wName = displayedList[i]
            if wName then
                cardData.WeaponName = wName
                cardData.Label.Text = wName
                -- Use cached default icon to prevent custom skin contamination
                local icon = defaultWeaponIconCache[wName]
                local rarity = "Covert"
                if not icon or icon == "" then
                    if getStockWeaponIcon then
                        local okStock, sIcon = pcall(getStockWeaponIcon, wName)
                        if okStock and sIcon and typeof(sIcon) == "string" and sIcon ~= "" and not WeaponDisplaySilhouettes[sIcon] then
                            icon = sIcon
                        end
                    end
                    if not icon or icon == "" then
                        pcall(function()
                            icon, rarity = getItemDisplayData(wName, sub)
                        end)
                    end
                    if not icon or icon == "" or icon == "rbxassetid://83097083839889" then
                        icon = getWeaponIcon(wName)
                    end
                    -- Cache the first-resolved default icon permanently
                    if icon and icon ~= "" and icon ~= "rbxassetid://83097083839889" then
                        defaultWeaponIconCache[wName] = icon
                    end
                end
                cardData.Thumb.Image = icon
                if sub == "Charms" or sub == "Weapon Cases" or sub == "Packages" or sub == "Badges" then
                    cardData.RarityLine.BackgroundColor3 = getRarityColor(rarity)
                    cardData.RarityLine.Visible = true
                else
                    cardData.RarityLine.Visible = false
                end
                cardData.Root.Visible = true
            else
                cardData.WeaponName = ""
                cardData.Root.Visible = false
            end
        end
    end

    WSearch:GetPropertyChangedSignal("Text"):Connect(function()
        task.spawn(function()
            pcall(function()
                if MemeSenseInventory.ActiveView ~= "WeaponSelect" then return end
                local sub = MemeSenseInventory.CurrentSubcategory
                local rawList = WeaponsByCategory[sub] or {}
                local filterText = string.lower(WSearch.Text)

                local displayedList = {}
                for _, wName in ipairs(rawList) do
                    if filterText == "" or string.find(string.lower(wName), filterText) then
                        table.insert(displayedList, wName)
                    end
                end

                for _, cardData in ipairs(WeaponCardsPool) do
                    cardData.WeaponName = ""
                    cardData.Root.Visible = false
                end

                for i, cardData in ipairs(WeaponCardsPool) do
                    local wName = displayedList[i]
                    if wName then
                        cardData.WeaponName = wName
                        cardData.Label.Text = wName
                        local icon = defaultWeaponIconCache[wName]
                        local rarity = "Covert"
                        if not icon or icon == "" then
                            if getStockWeaponIcon then
                                local okStock, sIcon = pcall(getStockWeaponIcon, wName)
                                if okStock and sIcon and typeof(sIcon) == "string" and sIcon ~= "" and not WeaponDisplaySilhouettes[sIcon] then
                                    icon = sIcon
                                end
                            end
                            if not icon or icon == "" then
                                pcall(function()
                                    icon, rarity = getItemDisplayData(wName, sub)
                                end)
                            end
                            if not icon or icon == "" or icon == "rbxassetid://83097083839889" then
                                icon = getWeaponIcon(wName)
                            end
                            if icon and icon ~= "" and icon ~= "rbxassetid://83097083839889" then
                                defaultWeaponIconCache[wName] = icon
                            end
                        end
                        cardData.Thumb.Image = icon
                        if sub == "Charms" or sub == "Weapon Cases" or sub == "Packages" or sub == "Badges" then
                            cardData.RarityLine.BackgroundColor3 = getRarityColor(rarity)
                            cardData.RarityLine.Visible = true
                        else
                            cardData.RarityLine.Visible = false
                        end
                        cardData.Root.Visible = true
                    else
                        cardData.WeaponName = ""
                        cardData.Root.Visible = false
                    end
                end
            end)
        end)
    end)

    openSkinSelectView = function(weaponName)
        selectedWeaponName = weaponName
        ViewGrid.Visible = false
        ViewWeaponSelect.Visible = false
        ViewSkinSelect.Visible = true
        MemeSenseInventory.ActiveView = "SkinSelect"

        STitle.Text = weaponName .. " Skins"
        SSearch.Text = ""

        currentSkinList = getWeaponSkins(weaponName)
        local filterText = string.lower(SSearch.Text)

        local displayedSkins = {}
        for _, sData in ipairs(currentSkinList) do
            if filterText == "" or string.find(string.lower(sData.Skin), filterText) then
                table.insert(displayedSkins, sData)
            end
        end

        local isKG = (getWeaponClass(weaponName) == "Melee" or getWeaponClass(weaponName) == "Glove")
        for i, cardData in ipairs(SkinCardsPool) do
            local sData = displayedSkins[i]
            if sData then
                cardData.SkinData = sData
                cardData.Label.Text = sData.Skin
                cardData.Thumb.Image = (sData.Icon and sData.Icon ~= "") and sData.Icon or getWeaponIcon(weaponName)
                cardData.RarityLine.BackgroundColor3 = getRarityColor(sData.Rarity, isKG)
                cardData.Root.Visible = true
            else
                cardData.SkinData = nil
                cardData.Root.Visible = false
            end
        end
    end

    SSearch:GetPropertyChangedSignal("Text"):Connect(function()
        task.spawn(function()
            pcall(function()
                if MemeSenseInventory.ActiveView ~= "SkinSelect" or not selectedWeaponName then return end
                local filterText = string.lower(SSearch.Text)
                local displayedSkins = {}
                for _, sData in ipairs(currentSkinList) do
                    if filterText == "" or string.find(string.lower(sData.Skin), filterText) then
                        table.insert(displayedSkins, sData)
                    end
                end

                local isKG = (getWeaponClass(selectedWeaponName) == "Melee" or getWeaponClass(selectedWeaponName) == "Glove")
                for i, cardData in ipairs(SkinCardsPool) do
                    local sData = displayedSkins[i]
                    if sData then
                        cardData.SkinData = sData
                        cardData.Label.Text = sData.Skin
                        cardData.Thumb.Image = (sData.Icon and sData.Icon ~= "") and sData.Icon or getWeaponIcon(selectedWeaponName)
                        cardData.RarityLine.BackgroundColor3 = getRarityColor(sData.Rarity, isKG)
                        cardData.Root.Visible = true
                    else
                        cardData.SkinData = nil
                        cardData.Root.Visible = false
                    end
                end
            end)
        end)
    end)

    -- Connect Weapon Cards clicks
    local isCardActionBusy = false

    local function onWeaponCardClicked(cardData)
        if isCardActionBusy then return end
        isCardActionBusy = true
        task.delay(0.25, function() isCardActionBusy = false end)

        local wName = cardData.WeaponName
        if not wName or wName == "" then return end
        local cat = MemeSenseInventory.CurrentCategory
        local sub = MemeSenseInventory.CurrentSubcategory
        if cat == "Equipment" then
            openSkinSelectView(wName)
        else
            local icon, rarity = getItemDisplayData(wName, sub)
            local itType = getWeaponClass(wName)
            local itemToAdd = nil

            if cat == "Containers" or sub == "Weapon Cases" or sub == "Packages" or itType == "Case" or itType == "Package" then
                local caseDef = nil
                if CasesLib then
                    if CasesLib.GetCaseByName then caseDef = CasesLib.GetCaseByName(wName) end
                    if not caseDef and CasesLib.GetCase then caseDef = CasesLib.GetCase(wName) end
                end
                local cid = (caseDef and (caseDef.caseId or caseDef.id or caseDef.Id)) or wName
                local cType = (sub == "Packages" and "Package") or "Case"
                local cRarity = (caseDef and (caseDef.caseRarity or caseDef.rarity)) or rarity or "Red"
                local cIcon = (caseDef and (caseDef.imageAssetId or caseDef.icon or caseDef.Icon)) or icon

                local newCase = createBloxStrikeItem(wName, wName, getRarityColor(cRarity), cRarity, cIcon, cType, cid)
                newCase.Equipped = false
                table.insert(MemeSenseInventory.Items, newCase)
                unlockedDict[newCase._id] = newCase
                itemToAdd = newCase
            elseif itType == "Badge" then
                local bIcon, bRarity = getItemDisplayData(wName, "Badges")
                local newBadge = createBloxStrikeItem("Badge", wName, getRarityColor(bRarity), bRarity, bIcon, "Badge")
                newBadge.CustomName = wName
                local isMaster = (tabMasterStates["Inventory"] == true) and (MemeSenseInventory and MemeSenseInventory.MasterSwitch == true)
                newBadge.Equipped = isMaster
                table.insert(MemeSenseInventory.Items, newBadge)
                unlockedDict[newBadge._id] = newBadge
                if isMaster then
                    equipItemInLoadout(newBadge)
                end
                itemToAdd = newBadge
            else
                local newItem = createBloxStrikeItem(wName, wName, getRarityColor(rarity), rarity, icon, itType)
                local isMaster = (tabMasterStates["Inventory"] == true) and (MemeSenseInventory and MemeSenseInventory.MasterSwitch == true)
                newItem.Equipped = isMaster
                table.insert(MemeSenseInventory.Items, newItem)
                unlockedDict[newItem._id] = newItem
                if isMaster then
                    equipItemInLoadout(newItem)
                end
                itemToAdd = newItem
            end

            -- Return to inventory grid view IMMEDIATELY so the user is never stuck
            ViewSkinSelect.Visible = false
            ViewWeaponSelect.Visible = false
            ViewGrid.Visible = true
            MemeSenseInventory.ActiveView = "Grid"
            pcall(refreshGridItems)

            task.spawn(function()
                pcall(function()
                    if itemToAdd and DataController and DataController.ApplyInventoryDelta then
                        DataController.ApplyInventoryDelta(LocalPlayer, { itemToAdd })
                    end
                end)
                pcall(syncGameInventory)
                pcall(refreshGridItems)
                if itemToAdd then
                    pcall(triggerItemNotification, itemToAdd)
                end
            end)
        end
    end

    for _, cardData in ipairs(WeaponCardsPool) do
        cardData.Root.Activated:Connect(function() onWeaponCardClicked(cardData) end)
        cardData.Root.MouseButton1Click:Connect(function() onWeaponCardClicked(cardData) end)
    end

    -- Connect Skin Cards clicks
    local function onSkinCardClicked(cardData)
        if isCardActionBusy then return end
        isCardActionBusy = true
        task.delay(0.25, function() isCardActionBusy = false end)

        local sData = cardData.SkinData
        if not sData or not selectedWeaponName then return end

        local chosenSkin = (sData.Skin == "-" or sData.Skin == "Vanilla") and "Stock" or sData.Skin
        -- Resolve the skin-specific icon (not just default weapon icon)
        local icon = ""
        if sData.Icon and sData.Icon ~= "" and not WeaponDisplaySilhouettes[sData.Icon] then
            icon = sData.Icon
        else
            pcall(function()
                icon = getSkinSpecificIcon(selectedWeaponName, chosenSkin)
            end)
            if not icon or icon == "" then
                icon = getWeaponIcon(selectedWeaponName)
            end
        end
        local rName = sData.Rarity or "Covert"
        local isKG = (getWeaponClass(selectedWeaponName) == "Melee" or getWeaponClass(selectedWeaponName) == "Glove")
        local newItem = createBloxStrikeItem(selectedWeaponName, chosenSkin, getRarityColor(rName, isKG), rName, icon)

        -- Set Equipped BEFORE adding to inventory and refreshing UI
        local isMaster = (tabMasterStates["Inventory"] == true) and (MemeSenseInventory and MemeSenseInventory.MasterSwitch == true)
        newItem.Equipped = isMaster

        table.insert(MemeSenseInventory.Items, newItem)
        unlockedDict[newItem._id] = newItem

        -- Return to inventory grid view IMMEDIATELY so the user is never stuck
        ViewSkinSelect.Visible = false
        ViewWeaponSelect.Visible = false
        ViewGrid.Visible = true
        MemeSenseInventory.ActiveView = "Grid"
        pcall(refreshGridItems)

        -- Perform loadout equipping and inventory syncing
        task.spawn(function()
            if isMaster then
                local okEquip, equipErr = pcall(equipItemInLoadout, newItem)
                if not okEquip then
                    warn("[MemeSense] equipItemInLoadout non-fatal warning:", equipErr)
                end
            end
            pcall(function()
                if DataController and DataController.ApplyInventoryDelta then
                    DataController.ApplyInventoryDelta(LocalPlayer, { newItem })
                end
            end)
            pcall(syncGameInventory)
            pcall(refreshGridItems)
            if newItem then
                pcall(triggerItemNotification, newItem)
            end
        end)
    end

    for _, cardData in ipairs(SkinCardsPool) do
        cardData.Root.Activated:Connect(function() onSkinCardClicked(cardData) end)
        cardData.Root.MouseButton1Click:Connect(function() onSkinCardClicked(cardData) end)
    end

    -- Back Buttons
    WBackBtn.MouseButton1Click:Connect(function()
        task.spawn(function()
            pcall(function()
                ViewWeaponSelect.Visible = false
                ViewGrid.Visible = true
                MemeSenseInventory.ActiveView = "Grid"
                refreshGridItems()
            end)
        end)
    end)

    SBackBtn.MouseButton1Click:Connect(function()
        task.spawn(function()
            pcall(function()
                ViewSkinSelect.Visible = false
                ViewWeaponSelect.Visible = true
                MemeSenseInventory.ActiveView = "WeaponSelect"
            end)
        end)
    end)

    AddCard.MouseButton1Click:Connect(function()
        task.spawn(function()
            pcall(function()
                openWeaponSelectView()
            end)
        end)
    end)

    -- ========================================================================
    -- CATEGORY & SUBCATEGORY NAVIGATION BUTTONS
    -- ========================================================================
    local CategoryButtons = {}
    local SubcategoryButtons = {}
    local selectCategory = nil
    local selectSubcategory = nil

    local curCatX = 0
    for idx, catName in ipairs(Categories) do
        local catBtn = Instance.new("TextButton")
        catBtn.Name = "CatBtn_" .. catName
        catBtn.BackgroundTransparency = 1
        catBtn.Text = catName
        catBtn.TextColor3 = (catName == MemeSenseInventory.CurrentCategory) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 135, 145)
        catBtn.TextSize = 13
        catBtn.Font = Theme.FontBold
        catBtn.AutoButtonColor = false
        catBtn.Size = UDim2.new(0, #catName * 8 + 24, 1, 0)
        catBtn.Position = UDim2.new(0, curCatX, 0, 0)
        catBtn.Parent = CategoryBar

        curCatX = curCatX + #catName * 8 + 36

        catBtn.MouseEnter:Connect(function()
            if catName ~= MemeSenseInventory.CurrentCategory then
                catBtn.TextColor3 = Color3.fromRGB(185, 190, 200)
            end
        end)
        catBtn.MouseLeave:Connect(function()
            if catName ~= MemeSenseInventory.CurrentCategory then
                catBtn.TextColor3 = Color3.fromRGB(130, 135, 145)
            end
        end)

        catBtn.MouseButton1Click:Connect(function()
            task.spawn(function()
                pcall(function()
                    selectCategory(catName)
                end)
            end)
        end)

        CategoryButtons[catName] = catBtn
    end

    -- Create Subcategory Buttons for each category
    for catName, subs in pairs(SubcategoriesByCategory) do
        local curSubX = 0
        for sIdx, subName in ipairs(subs) do
            local subBtn = Instance.new("TextButton")
            subBtn.Name = "SubBtn_" .. catName .. "_" .. subName
            subBtn.BackgroundTransparency = 1
            subBtn.Text = subName
            subBtn.TextColor3 = (subName == MemeSenseInventory.CurrentSubcategory) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(115, 120, 130)
            subBtn.TextSize = 12
            subBtn.Font = Theme.FontMedium
            subBtn.AutoButtonColor = false
            subBtn.Size = UDim2.new(0, #subName * 7 + 18, 1, 0)
            subBtn.Position = UDim2.new(0, curSubX, 0, 0)
            subBtn.Visible = (catName == MemeSenseInventory.CurrentCategory)
            subBtn.Parent = SubcategoryBar

            curSubX = curSubX + #subName * 7 + 28

            subBtn.MouseEnter:Connect(function()
                if subName ~= MemeSenseInventory.CurrentSubcategory then
                    subBtn.TextColor3 = Color3.fromRGB(165, 170, 180)
                end
            end)
            subBtn.MouseLeave:Connect(function()
                if subName ~= MemeSenseInventory.CurrentSubcategory then
                    subBtn.TextColor3 = Color3.fromRGB(115, 120, 130)
                end
            end)

            subBtn.MouseButton1Click:Connect(function()
                task.spawn(function()
                    pcall(function()
                        selectSubcategory(subName)
                    end)
                end)
            end)

            if not SubcategoryButtons[catName] then
                SubcategoryButtons[catName] = {}
            end
            SubcategoryButtons[catName][subName] = subBtn
        end
    end

    local function updateUnderlinePosition(catName)
        local btn = CategoryButtons[catName]
        if btn then
            CatUnderline.Position = UDim2.new(0, btn.Position.X.Offset, 1, -2)
            CatUnderline.Size = UDim2.new(0, btn.Size.X.Offset, 0, 2)
        end
    end

    selectSubcategory = function(subName)
        MemeSenseInventory.CurrentSubcategory = subName
        local cat = MemeSenseInventory.CurrentCategory
        local catSubs = SubcategoryButtons[cat] or {}
        for sName, btn in pairs(catSubs) do
            btn.TextColor3 = (sName == subName) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(115, 120, 130)
        end

        ViewSkinSelect.Visible = false
        ViewWeaponSelect.Visible = false
        ViewGrid.Visible = true
        MemeSenseInventory.ActiveView = "Grid"
        refreshGridItems()
    end

    selectCategory = function(catName)
        MemeSenseInventory.CurrentCategory = catName
        for name, btn in pairs(CategoryButtons) do
            btn.TextColor3 = (name == catName) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 135, 145)
        end
        updateUnderlinePosition(catName)

        -- Update visible subcategory buttons
        for cName, subs in pairs(SubcategoryButtons) do
            for _, btn in pairs(subs) do
                btn.Visible = (cName == catName)
            end
        end

        -- Select first subcategory of this category
        local subList = SubcategoriesByCategory[catName] or {}
        local firstSub = subList[1] or ""
        MemeSenseInventory.CurrentSubcategory = firstSub

        local catSubs = SubcategoryButtons[catName] or {}
        for sName, btn in pairs(catSubs) do
            btn.TextColor3 = (sName == firstSub) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(115, 120, 130)
        end

        ViewSkinSelect.Visible = false
        ViewWeaponSelect.Visible = false
        ViewGrid.Visible = true
        MemeSenseInventory.ActiveView = "Grid"
        refreshGridItems()
    end

    -- Initialize initial category and subcategory state
    updateUnderlinePosition(MemeSenseInventory.CurrentCategory)
    refreshGridItems()

    MemeSenseInventory.RefreshUI = function()
        pcall(refreshGridItems)
    end
end)()

;(function()
    local ConfigsTab = Tabs["Configs"]
    if not ConfigsTab then return end

    local LeftCol = ConfigsTab.LeftColumn
    local RightCol = ConfigsTab.RightColumn

    LeftCol.Size = UDim2.new(1, -28, 1, -12)
    LeftCol.Position = UDim2.new(0, 14, 0, 8)
    if RightCol then
        RightCol.Visible = false
    end

    local function serializeValue(val)
        local t = typeof(val)
        if t == "Color3" then
            return { __isColor = true, r = val.R, g = val.G, b = val.B }
        elseif t == "EnumItem" then
            return { __isEnum = true, enumType = tostring(val.EnumType), name = val.Name }
        elseif t == "Vector3" then
            return { __isVector3 = true, x = val.X, y = val.Y, z = val.Z }
        elseif t == "table" then
            local res = {}
            for k, v in pairs(val) do
                if type(v) ~= "function" and typeof(v) ~= "RBXScriptConnection" and typeof(v) ~= "Instance" then
                    res[tostring(k)] = serializeValue(v)
                end
            end
            return res
        elseif t == "number" or t == "boolean" or t == "string" then
            return val
        end
        return nil
    end

    local function deserializeValue(val)
        if typeof(val) == "table" then
            if val.__isColor then
                return Color3.new(val.r or 1, val.g or 1, val.b or 1)
            elseif val.__isEnum then
                local ok, res = pcall(function()
                    return Enum[val.enumType][val.name]
                end)
                if ok and res then return res end
                local ok2, res2 = pcall(function()
                    return Enum.KeyCode[val.name]
                end)
                if ok2 and res2 then return res2 end
                return val.name
            elseif val.__isVector3 then
                return Vector3.new(val.x or 0, val.y or 0, val.z or 0)
            end
            local res = {}
            for k, v in pairs(val) do
                local numKey = tonumber(k)
                if numKey then
                    res[numKey] = deserializeValue(v)
                else
                    res[k] = deserializeValue(v)
                end
            end
            return res
        end
        return val
    end

    local function deepMerge(dest, src)
        for k, v in pairs(src) do
            if typeof(v) == "table" and typeof(dest[k]) == "table" and not v.__isColor then
                deepMerge(dest[k], v)
            else
                dest[k] = v
            end
        end
    end

    local function ensureFolders()
        pcall(function()
            if type(makefolder) == "function" then
                if type(isfolder) == "function" then
                    if not isfolder("Memesense") then makefolder("Memesense") end
                    if not isfolder("Memesense/configs") then makefolder("Memesense/configs") end
                else
                    pcall(makefolder, "Memesense")
                    pcall(makefolder, "Memesense/configs")
                end
            end
        end)
    end

    local function saveConfig(filename)
        ensureFolders()
        local curDate = os.date("%Y/%m/%d %H:%M:%S")
        local controlsPayload = {}
        for key, ctrl in pairs(UIControlRegistry) do
            if ctrl and ctrl.GetValue then
                local ok, val = pcall(ctrl.GetValue)
                if ok and val ~= nil then
                    controlsPayload[key] = serializeValue(val)
                end
            end
        end

        local savedLoadout = nil
        pcall(function()
            if DataController and DataController.Get then
                savedLoadout = DataController.Get(LocalPlayer, "Loadout")
            end
        end)

        local payload = {
            Name = filename or "-",
            Modified = curDate,
            MasterStates = tabMasterStates,
            Controls = controlsPayload,
            Chams = serializeValue(MemeSenseChams),
            Camera = serializeValue(MemeSenseCamera),
            Viewmodel = serializeValue(MemeSenseViewmodel),
            Misc = serializeValue(MemeSenseMisc),
            Sounds = serializeValue(MemeSenseSounds),
            Inventory = serializeValue(MemeSenseInventory),
            CustomLoadout = serializeValue(customLoadout or (MemeSenseInventory and MemeSenseInventory.CustomLoadout)),
            Players = serializeValue(MemeSensePlayers),
            GameLoadout = serializeValue(savedLoadout),
        }
        local success = false
        pcall(function()
            local jsonStr = HttpService:JSONEncode(payload)
            if type(writefile) == "function" then
                writefile("Memesense/configs/" .. filename, jsonStr)
                success = true
            end
        end)
        return success, curDate
    end

    GlobalSaveConfig = saveConfig

    local function loadConfig(filename)
        local loaded = nil
        pcall(function()
            local path = "Memesense/configs/" .. filename
            local raw = nil
            if type(readfile) == "function" then
                if type(isfile) == "function" then
                    if isfile(path) then raw = readfile(path) end
                else
                    pcall(function() raw = readfile(path) end)
                end
            end
            if raw and #raw > 0 then
                loaded = HttpService:JSONDecode(raw)
            end
        end)
        if not loaded then return false end

        pcall(function()
            if loaded.MasterStates and typeof(loaded.MasterStates) == "table" then
                for k, v in pairs(loaded.MasterStates) do
                    tabMasterStates[k] = v
                end
                chamsMasterEnabled = (tabMasterStates["Chams"] == true)
                if MemeSenseInventory then
                    MemeSenseInventory.MasterSwitch = (tabMasterStates["Inventory"] == true)
                    if MemeSenseInventory.OnMasterSwitchChanged then
                        pcall(MemeSenseInventory.OnMasterSwitchChanged, MemeSenseInventory.MasterSwitch)
                    end
                end
                updateMasterSwitchUI()
            end
        end)

        pcall(function()
            if loaded.Players and MemeSensePlayers then
                local pl = deserializeValue(loaded.Players)
                deepMerge(MemeSensePlayers, pl)
            end
        end)

        pcall(function()
            if loaded.Chams and MemeSenseChams then
                local ch = deserializeValue(loaded.Chams)
                deepMerge(MemeSenseChams, ch)
            end
        end)

        pcall(function()
            if loaded.Camera and MemeSenseCamera then
                local cm = deserializeValue(loaded.Camera)
                deepMerge(MemeSenseCamera, cm)
            end
        end)

        pcall(function()
            if loaded.Viewmodel and MemeSenseViewmodel then
                local vm = deserializeValue(loaded.Viewmodel)
                deepMerge(MemeSenseViewmodel, vm)
            end
        end)

        pcall(function()
            if loaded.Misc and MemeSenseMisc then
                local ms = deserializeValue(loaded.Misc)
                deepMerge(MemeSenseMisc, ms)
            end
        end)

        pcall(function()
            if loaded.Sounds and MemeSenseSounds then
                local sd = deserializeValue(loaded.Sounds)
                deepMerge(MemeSenseSounds, sd)
            end
        end)

        -- 1. Restore Inventory Items
        pcall(function()
            if loaded.Inventory and typeof(loaded.Inventory) == "table" then
                local inv = deserializeValue(loaded.Inventory)
                if inv and typeof(inv) == "table" then
                    if inv.Items and typeof(inv.Items) == "table" then
                        MemeSenseInventory.Items = inv.Items
                    end
                    if inv.MasterSwitch ~= nil then
                        MemeSenseInventory.MasterSwitch = inv.MasterSwitch
                        tabMasterStates["Inventory"] = inv.MasterSwitch
                        updateMasterSwitchUI()
                        if MemeSenseInventory.OnMasterSwitchChanged then
                            pcall(MemeSenseInventory.OnMasterSwitchChanged, inv.MasterSwitch)
                        end
                    end
                end
            end
        end)

        -- 2. Synchronously register & inject all inventory items into DataController and unlockedDict
        pcall(function()
            if DataController and MemeSenseInventory and MemeSenseInventory.Items then
                local toInject = {}
                for _, item in ipairs(MemeSenseInventory.Items) do
                    if not item.MetaData or typeof(item.MetaData) ~= "table" then
                        item.MetaData = {
                            LastTradeAt = 0,
                            CreatedAt = os.time(),
                            OriginalOwner = 0,
                            Owner = 0,
                            Origin = "MemeSense",
                            TradeHistory = {}
                        }
                    end
                    if item.StatTrack == nil then item.StatTrack = false end
                    if item.Serial == nil then item.Serial = 1 end
                    unlockedDict[item._id] = item
                    if not injectedItemIds[item._id] then
                        injectedItemIds[item._id] = true
                        table.insert(toInject, item)
                    end
                end
                if #toInject > 0 then
                    pcall(DataController.ApplyInventoryDelta, LocalPlayer, toInject)
                end
            end
        end)

        -- 3. Restore customLoadout
        pcall(function()
            if loaded.CustomLoadout then
                local cl = deserializeValue(loaded.CustomLoadout)
                local targetCL = customLoadout or (MemeSenseInventory and MemeSenseInventory.CustomLoadout)
                if targetCL and cl then
                    deepMerge(targetCL, cl)
                end
            end
        end)

        -- 4. Restore in-game loadout for both Counter-Terrorists and Terrorists
        pcall(function()
            if DataController then
                local loadout, inv = DataController.Get(LocalPlayer, "Loadout", "Inventory")
                if loadout then
                    -- If GameLoadout was saved, merge it into loadout
                    if loaded.GameLoadout then
                        local gl = deserializeValue(loaded.GameLoadout)
                        if gl and typeof(gl) == "table" then
                            deepMerge(loadout, gl)
                        end
                    end

                    -- Also sync from customLoadout into loadout to ensure every equipped item is present
                    local targetCL = customLoadout or (MemeSenseInventory and MemeSenseInventory.CustomLoadout)
                    if targetCL then
                        for _, tName in ipairs({ "Counter-Terrorists", "Terrorists" }) do
                            if targetCL[tName] and loadout[tName] then
                                -- Knives
                                if targetCL[tName].Knife and targetCL[tName].Knife.Name then
                                    for _, it in ipairs(MemeSenseInventory.Items) do
                                        if it.Name == targetCL[tName].Knife.Name and (it.Skin == targetCL[tName].Knife.Skin or targetCL[tName].Knife.Skin == "Stock" or it.Skin == "Vanilla") then
                                            loadout[tName].Equipped = loadout[tName].Equipped or {}
                                            loadout[tName].Equipped["Equipped Melee"] = it._id
                                            loadout[tName].Equipped["Melee"] = it._id
                                            it.Equipped = true
                                            break
                                        end
                                    end
                                end
                                -- Gloves
                                if targetCL[tName].Glove and targetCL[tName].Glove.Name then
                                    for _, it in ipairs(MemeSenseInventory.Items) do
                                        if it.Name == targetCL[tName].Glove.Name and (it.Skin == targetCL[tName].Glove.Skin or targetCL[tName].Glove.Skin == "Stock" or it.Skin == "Vanilla") then
                                            loadout[tName].Equipped = loadout[tName].Equipped or {}
                                            loadout[tName].Equipped["Equipped Gloves"] = it._id
                                            loadout[tName].Equipped["Glove"] = it._id
                                            it.Equipped = true
                                            pcall(applyGlovesToCharacter, targetCL[tName].Glove)
                                            break
                                        end
                                    end
                                end
                                -- Badge
                                if targetCL[tName].Badge and targetCL[tName].Badge._id then
                                    loadout[tName].Equipped = loadout[tName].Equipped or {}
                                    loadout[tName].Equipped["Equipped Badge"] = targetCL[tName].Badge._id
                                    loadout[tName].Equipped["Badge"] = targetCL[tName].Badge._id
                                    for _, it in ipairs(MemeSenseInventory.Items) do
                                        if it._id == targetCL[tName].Badge._id then
                                            it.Equipped = true
                                            break
                                        end
                                    end
                                end
                                -- Weapons
                                if targetCL[tName].Weapons then
                                    for wName, wData in pairs(targetCL[tName].Weapons) do
                                        for _, it in ipairs(MemeSenseInventory.Items) do
                                            if (it.Name == wName or sanitize(it.Name) == sanitize(wName)) and (it.Skin == wData.Skin or wData.Skin == "Stock" or it.Skin == "Vanilla") then
                                                local itType = it.Type or getWeaponClass(it.Name)
                                                local catKey = (itType == "Pistol" and "Pistols") or (itType == "Rifle" and "Rifles") or "Mid Tier"
                                                if loadout[tName].Loadout and loadout[tName].Loadout[catKey] and loadout[tName].Loadout[catKey].Options then
                                                    local opts = loadout[tName].Loadout[catKey].Options
                                                    local slotFound = nil
                                                    for sIdx, existingId in ipairs(opts) do
                                                        local existing = unlockedDict[existingId]
                                                        if existing and (sanitize(existing.Name) == sanitize(it.Name) or existing.Name == it.Name) then
                                                            slotFound = sIdx
                                                            break
                                                        end
                                                        if not slotFound and inv and typeof(inv) == "table" then
                                                            for _, invItem in ipairs(inv) do
                                                                if invItem._id == existingId and (sanitize(invItem.Name) == sanitize(it.Name) or invItem.Name == it.Name) then
                                                                    slotFound = sIdx
                                                                    break
                                                                end
                                                            end
                                                        end
                                                        if slotFound then break end
                                                    end
                                                    if not slotFound then
                                                        local nm = sanitize(it.Name)
                                                        if catKey == "Pistols" then
                                                            if string.find(nm, "glock") or string.find(nm, "usp") or string.find(nm, "p2000") then slotFound = 1
                                                            elseif string.find(nm, "dual") then slotFound = 2
                                                            elseif string.find(nm, "p250") then slotFound = 3
                                                            elseif string.find(nm, "five") or string.find(nm, "tec") or string.find(nm, "cz") then slotFound = 4
                                                            elseif string.find(nm, "deagle") or string.find(nm, "desert") or string.find(nm, "revolver") or string.find(nm, "r8") then slotFound = 5
                                                            else slotFound = 1 end
                                                        elseif catKey == "Rifles" then
                                                            if string.find(nm, "famas") or string.find(nm, "galil") then slotFound = 1
                                                            elseif string.find(nm, "m4") or string.find(nm, "ak") then slotFound = 2
                                                            elseif string.find(nm, "ssg") or string.find(nm, "scout") then slotFound = 3
                                                            elseif string.find(nm, "aug") or string.find(nm, "sg") then slotFound = 4
                                                            elseif string.find(nm, "awp") or string.find(nm, "scar") or string.find(nm, "g3") then slotFound = 5
                                                            else slotFound = 2 end
                                                        else -- Mid Tier
                                                            if string.find(nm, "mp9") or string.find(nm, "mac") then slotFound = 1
                                                            elseif string.find(nm, "mp7") or string.find(nm, "mp5") then slotFound = 2
                                                            elseif string.find(nm, "ump") then slotFound = 3
                                                            elseif string.find(nm, "p90") or string.find(nm, "bizon") then slotFound = 4
                                                            else slotFound = 5 end
                                                        end
                                                    end
                                                    opts[slotFound] = it._id
                                                    while #opts > 5 do
                                                        table.remove(opts)
                                                    end
                                                end
                                                it.Equipped = true
                                                break
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end

                    -- Notify game that loadout updated!
                    pcall(function() DataController.ApplyInventoryDelta(LocalPlayer, { ["Loadout"] = loadout }) end)
                    pcall(function()
                        if Remotes and Remotes.PlayerData and Remotes.PlayerData.PlayerDataChanged then
                            Remotes.PlayerData.PlayerDataChanged.Fire({
                                Player = LocalPlayer,
                                Data = { ["Loadout"] = loadout }
                            })
                        end
                    end)
                    pcall(function()
                        if Remotes and Remotes.Inventory and Remotes.Inventory.LoadoutResponse then
                            Remotes.Inventory.LoadoutResponse.Fire(true)
                        end
                    end)
                    pcall(function()
                        local lm = ReplicatedStorage:FindFirstChild("Interface") and ReplicatedStorage.Interface:FindFirstChild("Screens") and ReplicatedStorage.Interface.Screens:FindFirstChild("Menu") and ReplicatedStorage.Interface.Screens.Menu:FindFirstChild("Loadout")
                        if lm then
                            local LoadoutModule = require(lm)
                            if LoadoutModule.SelectTeam then
                                LoadoutModule.SelectTeam("CT")
                            end
                        end
                    end)
                end
            end
        end)

        -- 5. Refresh Memesense UI
        if refreshGridItems then pcall(refreshGridItems) end
        if MemeSenseInventory and MemeSenseInventory.RefreshUI then pcall(MemeSenseInventory.RefreshUI) end

        -- 6. Safely restore all UI controls (WITHOUT runElevated)
        if loaded.Controls and typeof(loaded.Controls) == "table" then
            for key, rawVal in pairs(loaded.Controls) do
                local ctrl = UIControlRegistry[key]
                if ctrl and ctrl.SetValue then
                    local val = deserializeValue(rawVal)
                    pcall(ctrl.SetValue, val)
                end
            end
        end

        -- 7. Comprehensive Synchronization of UI controls from feature data
        pcall(function()
            if MemeSenseChams then
                local chamsMapping = {
                    ["Chams_Content/LeftColumn/PlayersLeftGroup/Glow"] = MemeSenseChams.Players and MemeSenseChams.Players.Enemy and MemeSenseChams.Players.Enemy.Glow,
                    ["Chams_Content/LeftColumn/PlayersLeftGroup/Visible"] = MemeSenseChams.Players and MemeSenseChams.Players.Enemy and MemeSenseChams.Players.Enemy.Visible,
                    ["Chams_Content/LeftColumn/PlayersLeftGroup/Invisible"] = MemeSenseChams.Players and MemeSenseChams.Players.Enemy and MemeSenseChams.Players.Enemy.Invisible,
                    ["Chams_Content/RightColumn/PlayersRightGroup/Glow"] = MemeSenseChams.Players and MemeSenseChams.Players.Team and MemeSenseChams.Players.Team.Glow,
                    ["Chams_Content/RightColumn/PlayersRightGroup/Visible"] = MemeSenseChams.Players and MemeSenseChams.Players.Team and MemeSenseChams.Players.Team.Visible,
                    ["Chams_Content/RightColumn/PlayersRightGroup/Invisible"] = MemeSenseChams.Players and MemeSenseChams.Players.Team and MemeSenseChams.Players.Team.Invisible,
                    ["Chams_Content/LeftColumn/LocalLeftGroup/Glow"] = MemeSenseChams.LocalPlayer and MemeSenseChams.LocalPlayer.Glow,
                    ["Chams_Content/LeftColumn/LocalLeftGroup/Visible"] = MemeSenseChams.LocalPlayer and MemeSenseChams.LocalPlayer.Visible,
                    ["Chams_Content/LeftColumn/LocalLeftGroup/Invisible"] = MemeSenseChams.LocalPlayer and MemeSenseChams.LocalPlayer.Invisible,
                    ["Chams_Content/RightColumn/LocalRightGroup/Hands"] = MemeSenseChams.LocalPlayer and MemeSenseChams.LocalPlayer.Hands,
                    ["Chams_Content/RightColumn/LocalRightGroup/Weapons"] = MemeSenseChams.LocalPlayer and MemeSenseChams.LocalPlayer.Weapons,
                }
                for key, data in pairs(chamsMapping) do
                    local ctrl = UIControlRegistry[key] or UIControlRegistry[string.lower(key)]
                    if ctrl and ctrl.SetValue and data then
                        pcall(function()
                            ctrl.SetValue({
                                State = (data.Enabled == true),
                                ColorChip = {
                                    Color = data.Color or Color3.fromRGB(255, 255, 255),
                                    Alpha = 1 - (data.Transparency or 0)
                                },
                                Dropdown = data.Style
                            })
                        end)
                    end
                end
            end
        end)

        pcall(function()
            if MemeSensePlayers then
                local playersMapping = {
                    ["Enable"] = { State = (MemeSensePlayers.Enable == true) },
                    ["Through wall"] = { State = (MemeSensePlayers.ThroughWall == true) },
                    ["Nickname"] = { State = (MemeSensePlayers.Nickname and MemeSensePlayers.Nickname.Enabled == true), Color = MemeSensePlayers.Nickname and MemeSensePlayers.Nickname.Color },
                    ["Box"] = { State = (MemeSensePlayers.Box and MemeSensePlayers.Box.Enabled == true) },
                    ["Health bar"] = { State = (MemeSensePlayers.HealthBar and MemeSensePlayers.HealthBar.Enabled == true) },
                    ["Weapon"] = { State = (MemeSensePlayers.Weapon and MemeSensePlayers.Weapon.Enabled == true) },
                }
                for key, val in pairs(playersMapping) do
                    local ctrl = UIControlRegistry[key] or UIControlRegistry[string.lower(key)]
                    if ctrl and ctrl.SetValue then
                        pcall(function() ctrl.SetValue(val) end)
                    end
                end
            end
        end)

        pcall(function()
            if MemeSenseMisc then
                local miscMapping = {
                    ["Auto bunnyhop"] = { State = (MemeSenseMisc.Bhop == true) },
                    ["Bhop"] = { State = (MemeSenseMisc.Bhop == true) },
                    ["Bunnyhop"] = { State = (MemeSenseMisc.Bhop == true) },
                    ["Glitch spectators"] = { State = (MemeSenseMisc.GlitchSpectators == true) },
                    ["In-game radar"] = { State = (MemeSenseMisc.InGameRadar == true) },
                    ["Preserve killfeed"] = { State = (MemeSenseMisc.PreserveKillfeed == true) },
                    ["Unlock all inventory"] = { State = (MemeSenseMisc.UnlockInventory == true) },
                }
                for key, val in pairs(miscMapping) do
                    local ctrl = UIControlRegistry[key] or UIControlRegistry[string.lower(key)]
                    if ctrl and ctrl.SetValue then
                        pcall(function() ctrl.SetValue(val) end)
                    end
                end
            end
        end)

        pcall(function()
            if MemeSenseCamera then
                local camMapping = {
                    ["Field of view"] = MemeSenseCamera.FieldOfView,
                    ["Zoom field of view 1"] = MemeSenseCamera.ZoomFieldOfView1,
                    ["Zoom field of view 2"] = MemeSenseCamera.ZoomFieldOfView2,
                    ["Max distance"] = MemeSenseCamera.ThirdPersonDistance,
                }
                for key, val in pairs(camMapping) do
                    local ctrl = UIControlRegistry[key] or UIControlRegistry[string.lower(key)]
                    if ctrl and ctrl.SetValue and val ~= nil then
                        pcall(function() ctrl.SetValue(val) end)
                    end
                end
            end
        end)

        -- 9. Misc hooks & Sounds listeners
        pcall(function()
            if MemeSenseMisc and MemeSenseMisc.Bhop and MiscHooks and MiscHooks.setupBhop then
                MiscHooks.setupBhop()
            end
            if MemeSenseMisc and MemeSenseMisc.GlitchSpectators and MiscHooks and MiscHooks.hookGlitchSpectators then
                MiscHooks.hookGlitchSpectators()
            elseif MemeSenseMisc and not MemeSenseMisc.GlitchSpectators and MiscHooks and MiscHooks.cleanupGlitchSpectators then
                MiscHooks.cleanupGlitchSpectators()
            end
            if MemeSenseMisc and MemeSenseMisc.InGameRadar and MiscHooks and MiscHooks.hookRadar then
                MiscHooks.hookRadar()
            elseif MemeSenseMisc and not MemeSenseMisc.InGameRadar and MiscHooks and MiscHooks.cleanupRadar then
                MiscHooks.cleanupRadar()
            end
            if MemeSenseMisc and MemeSenseMisc.PreserveKillfeed and MiscHooks and MiscHooks.hookKillFeed then
                MiscHooks.hookKillFeed()
            elseif MemeSenseMisc and not MemeSenseMisc.PreserveKillfeed and MiscHooks and MiscHooks.cleanupKillFeed then
                MiscHooks.cleanupKillFeed()
            end
        end)

        pcall(function()
            if MemeSenseSounds and MemeSenseSounds.HitEnabled and MemeSenseSounds.SetupListeners then
                MemeSenseSounds.SetupListeners()
            end
        end)

        return true
    end

    GlobalLoadConfig = loadConfig

    local initialModified = "2026/02/06 01:48:13"
    pcall(function()
        local path = "Memesense/configs/Default.json"
        if type(readfile) == "function" then
            local canRead = true
            if type(isfile) == "function" then
                canRead = isfile(path)
            end
            if canRead then
                local raw = readfile(path)
                if raw and #raw > 0 then
                    local data = HttpService:JSONDecode(raw)
                    if data and data.Modified then
                        initialModified = data.Modified
                    end
                end
            end
        end
    end)

    local Card = Instance.new("Frame")
    Card.Name = "ConfigCard_Default"
    Card.Size = UDim2.new(1, 0, 0, 50)
    Card.BackgroundColor3 = Color3.fromRGB(15, 16, 21)
    Card.BorderSizePixel = 0
    Card.LayoutOrder = 1
    Card.Parent = LeftCol
    createCorner(Card, 4)

    local CardStroke = Instance.new("UIStroke")
    CardStroke.Color = Color3.fromRGB(28, 30, 40)
    CardStroke.Thickness = 1
    CardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    CardStroke.Parent = Card

    local LeftIcon = Instance.new("TextLabel")
    LeftIcon.Name = "LeftIcon"
    LeftIcon.Size = UDim2.new(0, 22, 0, 22)
    LeftIcon.Position = UDim2.new(0, 12, 0.5, -11)
    LeftIcon.BackgroundTransparency = 1
    LeftIcon.FontFace = GuiIconsFont
    LeftIcon.Text = "-"
    LeftIcon.TextSize = 16
    LeftIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    LeftIcon.TextXAlignment = Enum.TextXAlignment.Center
    LeftIcon.TextYAlignment = Enum.TextYAlignment.Center
    LeftIcon.Parent = Card

    local NameLabel = Instance.new("TextLabel")
    NameLabel.Name = "NameLabel"
    NameLabel.Size = UDim2.new(0, 200, 0, 16)
    NameLabel.Position = UDim2.new(0, 40, 0, 8)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Font = Theme.FontBold
    NameLabel.TextSize = 13
    NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    NameLabel.Text = "-"
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.Parent = Card

    local ModifiedLabel = Instance.new("TextLabel")
    ModifiedLabel.Name = "ModifiedLabel"
    ModifiedLabel.Size = UDim2.new(0, 260, 0, 14)
    ModifiedLabel.Position = UDim2.new(0, 40, 0, 27)
    ModifiedLabel.BackgroundTransparency = 1
    ModifiedLabel.Font = Theme.FontMedium
    ModifiedLabel.TextSize = 11
    ModifiedLabel.RichText = true
    ModifiedLabel.Text = '<font color="rgb(140,140,150)">Modified: </font><font color="rgb(220,60,60)">' .. initialModified .. '</font>'
    ModifiedLabel.TextXAlignment = Enum.TextXAlignment.Left
    ModifiedLabel.Parent = Card

    GlobalUpdateConfigModifiedLabel = function(newDate)
        if ModifiedLabel and ModifiedLabel.Parent then
            ModifiedLabel.Text = '<font color="rgb(140,140,150)">Modified: </font><font color="rgb(220,60,60)">' .. newDate .. '</font>'
        end
    end

    local SaveBtn = Instance.new("TextButton")
    SaveBtn.Name = "SaveBtn"
    SaveBtn.Size = UDim2.new(0, 84, 0, 28)
    SaveBtn.Position = UDim2.new(1, -96, 0.5, -14)
    SaveBtn.BackgroundColor3 = Color3.fromRGB(35, 36, 38)
    SaveBtn.BorderSizePixel = 0
    SaveBtn.AutoButtonColor = false
    SaveBtn.Text = ""
    SaveBtn.Parent = Card
    createCorner(SaveBtn, 4)

    local SaveIcon = Instance.new("TextLabel")
    SaveIcon.Name = "SaveIcon"
    SaveIcon.Size = UDim2.new(0, 16, 0, 16)
    SaveIcon.Position = UDim2.new(0, 12, 0.5, -8)
    SaveIcon.BackgroundTransparency = 1
    SaveIcon.FontFace = GuiIconsFont
    SaveIcon.Text = "3"
    SaveIcon.TextSize = 13
    SaveIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    SaveIcon.TextXAlignment = Enum.TextXAlignment.Center
    SaveIcon.TextYAlignment = Enum.TextYAlignment.Center
    SaveIcon.Parent = SaveBtn

    local SaveText = Instance.new("TextLabel")
    SaveText.Name = "SaveText"
    SaveText.Size = UDim2.new(1, -38, 1, 0)
    SaveText.Position = UDim2.new(0, 34, 0, 0)
    SaveText.BackgroundTransparency = 1
    SaveText.Font = Theme.FontMedium
    SaveText.Text = "Save"
    SaveText.TextSize = 12
    SaveText.TextColor3 = Color3.fromRGB(255, 255, 255)
    SaveText.TextXAlignment = Enum.TextXAlignment.Left
    SaveText.Parent = SaveBtn

    GlobalSaveConfig = function(filename)
        local ok, curDate = saveConfig(filename)
        if ok or curDate then
            if GlobalUpdateConfigModifiedLabel then
                GlobalUpdateConfigModifiedLabel(curDate)
            end
        end
        return ok, curDate
    end

    Card.MouseEnter:Connect(function()
        Card.BackgroundColor3 = Color3.fromRGB(19, 21, 28)
        CardStroke.Color = Color3.fromRGB(36, 40, 52)
    end)
    Card.MouseLeave:Connect(function()
        Card.BackgroundColor3 = Color3.fromRGB(15, 16, 21)
        CardStroke.Color = Color3.fromRGB(28, 30, 40)
    end)

    SaveBtn.MouseButton1Click:Connect(function()
        local ok, newDate = saveConfig("Default.json")
        if ok or newDate then
            if GlobalUpdateConfigModifiedLabel then
                pcall(GlobalUpdateConfigModifiedLabel, newDate)
            end
            pcall(function()
                SaveText.Text = "Saved!"
                SaveText.TextColor3 = Color3.fromRGB(80, 220, 120)
                SaveIcon.TextColor3 = Color3.fromRGB(80, 220, 120)
            end)
            task.delay(1.2, function()
                pcall(function()
                    SaveText.Text = "Save"
                    SaveText.TextColor3 = Color3.fromRGB(255, 255, 255)
                    SaveIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
                end)
            end)
        end
    end)

    -- Autoload config on startup
    task.spawn(function()
        task.wait(0.15)
        pcall(function()
            loadConfig("Default.json")
        end)
    end)
end)()

SelectTab("Aim Assist")

local MemeSense
;(function()
    local MenuVisible = true

    local animToken = 0
    local savedMenuPos = nil

    local function setMenuVisible(visible)
        if visible == MenuVisible then return end
        MenuVisible = visible
        animToken = animToken + 1
        local currentToken = animToken

        local duration = 0.16
        local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

        if not visible then
            pcall(CloseAllPopups)
            pcall(function()
                if MainWindow.Position.X.Offset > -5000 and MainWindow.Position.Y.Offset > -5000 then
                    savedMenuPos = MainWindow.Position
                end
                TweenService:Create(MainWindow, tweenInfo, { GroupTransparency = 1 }):Play()
                TweenService:Create(BgOverlay, tweenInfo, { BackgroundTransparency = 1 }):Play()
            end)

            task.delay(duration, function()
                if animToken == currentToken and not MenuVisible then
                    pcall(function()
                        MainWindow.Position = UDim2.new(0, -10000, 0, -10000)
                        MainWindow.Visible = false
                        BgOverlay.Position = UDim2.new(0, -10000, 0, -10000)
                        BgOverlay.Visible = false
                        PopupsLayer.Position = UDim2.new(0, -10000, 0, -10000)
                        PopupsLayer.Visible = false
                        if ScreenGui then ScreenGui.Enabled = false end
                    end)
                end
            end)
        else
            pcall(function()
                if ScreenGui then ScreenGui.Enabled = true end
                local targetPos = (savedMenuPos and savedMenuPos.X.Offset > -5000) and savedMenuPos or UDim2.new(0.5, -WindowWidth / 2, 0.5, -WindowHeight / 2)
                MainWindow.Position = targetPos
                MainWindow.Visible = true
                MainWindow.GroupTransparency = 1
                BgOverlay.Position = UDim2.new(0, 0, 0, 0)
                BgOverlay.Visible = true
                BgOverlay.BackgroundTransparency = 1
                PopupsLayer.Position = UDim2.new(0, 0, 0, 0)
                PopupsLayer.Visible = true

                TweenService:Create(MainWindow, tweenInfo, { GroupTransparency = 0 }):Play()
                TweenService:Create(BgOverlay, tweenInfo, { BackgroundTransparency = 0.65 }):Play()
                pcall(function()
                    if MemeSenseInventory and MemeSenseInventory.RefreshUI then
                        MemeSenseInventory.RefreshUI()
                    end
                end)
            end)
        end
    end

    local ToggleConn = UserInputService.InputBegan:Connect(function(input, processed)
        if input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == Enum.KeyCode.Delete or input.KeyCode == Enum.KeyCode.RightControl then
            setMenuVisible(not MenuVisible)
        end

        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local hasOpenPopup = false
            for _, item in ipairs(ActivePopups) do
                local frame = (typeof(item) == "table") and item.Frame or item
                if frame and frame:IsA("GuiObject") and frame.Visible then
                    hasOpenPopup = true
                    break
                end
            end
            if hasOpenPopup then
                task.delay(0.1, function()
                    if draggingSV or draggingHue or draggingAlpha or draggingSoundVol or (os.clock() - lastTypeSelectTime < 0.35) then return end
                    local mousePos = UserInputService:GetMouseLocation()
                    local clickedOnPopup = false
                    for _, item in ipairs(ActivePopups) do
                        local frame = (typeof(item) == "table") and item.Frame or item
                        if frame and frame:IsA("GuiObject") and frame.Visible then
                            if isPosInGui(frame, mousePos, 8) then
                                clickedOnPopup = true
                                break
                            else
                                for _, desc in ipairs(frame:GetDescendants()) do
                                    if desc:IsA("GuiObject") and desc.Visible and isPosInGui(desc, mousePos, 8) then
                                        clickedOnPopup = true
                                        break
                                    end
                                end
                                if clickedOnPopup then break end
                            end
                        end
                    end
                    if not clickedOnPopup and not (os.clock() - lastPopoverDragTime < 0.2) and not (os.clock() - lastTypeSelectTime < 0.35) and not (draggingSV or draggingHue or draggingAlpha or draggingSoundVol) then
                        CloseAllPopups()
                    end
                end)
            end
        end
    end)
    table.insert(Connections, ToggleConn)

    local charAddedConn = LocalPlayer.CharacterAdded:Connect(function()
        task.defer(function()
            if MenuVisible then
                pcall(function()
                    local targetPos = (savedMenuPos and savedMenuPos.X.Offset > -5000) and savedMenuPos or UDim2.new(0.5, -WindowWidth / 2, 0.5, -WindowHeight / 2)
                    MainWindow.Position = targetPos
                    MainWindow.Visible = true
                    MainWindow.GroupTransparency = 0
                    BgOverlay.Position = UDim2.new(0, 0, 0, 0)
                    BgOverlay.BackgroundTransparency = 0.65
                    BgOverlay.Visible = true
                    PopupsLayer.Position = UDim2.new(0, 0, 0, 0)
                    PopupsLayer.Visible = true
                    if ScreenGui then ScreenGui.Enabled = true end
                end)
            else
                pcall(function()
                    MainWindow.Position = UDim2.new(0, -10000, 0, -10000)
                    MainWindow.Visible = false
                    MainWindow.GroupTransparency = 1
                    BgOverlay.Position = UDim2.new(0, -10000, 0, -10000)
                    BgOverlay.Visible = false
                    PopupsLayer.Position = UDim2.new(0, -10000, 0, -10000)
                    PopupsLayer.Visible = false
                    if ScreenGui then ScreenGui.Enabled = false end
                end)
            end
            pcall(function()
                if ScopeScreenGui and (not ScopeScreenGui.Parent or not ScopeScreenGui.Parent.Parent) then
                    ScopeScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
                end
            end)
        end)
    end)
    table.insert(Connections, charAddedConn)

    getgenv().MemeSenseCleanup = function()
        pcall(function()
            RunService:UnbindFromRenderStep("MemeSenseMouseUnlock")
        end)
        pcall(function()
            RunService:UnbindFromRenderStep("MemeSense_ThirdPerson")
        end)
        if ScopeScreenGui then
            pcall(function() ScopeScreenGui:Destroy() end)
        elseif ScopeOverlay then
            pcall(function() ScopeOverlay:Destroy() end)
        end
        local globalScope = getgenv().MemeSenseScopeGui
        if globalScope then
            getgenv().MemeSenseScopeGui = nil
            pcall(function() globalScope:Destroy() end)
        end
        for _, c in ipairs(scopeConns) do
            pcall(function() c:Disconnect() end)
        end
        table.clear(scopeConns)
        pcall(function()
            if hookedScopeInstance then
                local ssStroke = hookedScopeInstance:FindFirstChildOfClass("UIStroke")
                if ssStroke then ssStroke.Enabled = true end
                for _, child in ipairs(hookedScopeInstance:GetChildren()) do
                    if child.Name == "MemeSenseCustomScopeCrosshair" then
                        child:Destroy()
                    elseif child:IsA("GuiObject") and not child:IsA("UIAspectRatioConstraint") then
                        child.Visible = true
                    elseif child:IsA("UIStroke") then
                        child.Enabled = true
                    end
                end
                local blur = hookedScopeInstance:FindFirstChild("Blur")
                if blur and (blur:IsA("ImageLabel") or blur:IsA("ImageButton")) then
                    blur.ImageTransparency = 0
                end
            end
        end)
        pcall(function()
            if setForceSniperCrosshair then
                setForceSniperCrosshair(false)
            end
            if setSpreadRemoval then
                setSpreadRemoval(false)
            end
            pcall(function()
                pcall(function()
                    if unloadChamSystem then
                        unloadChamSystem()
                    end
                end)
                MemeSenseCamera.CustomAmbientEnabled = false
                MemeSenseCamera.CustomLightingEnabled = false
                MemeSenseCamera.Exposure = 1.000
                if LightingState then
                    if LightingState.cameraLightingCC then
                        LightingState.cameraLightingCC:Destroy()
                        LightingState.cameraLightingCC = nil
                    end
                end
                local mapProps = getMapLightingProperties()
                local defExp = mapProps and mapProps.ExposureCompensation or (LightingState and LightingState.origExposureCompensation) or 0
                Lighting.ExposureCompensation = defExp
                if mapProps then
                    Lighting.Ambient = mapProps.Ambient
                    Lighting.OutdoorAmbient = mapProps.OutdoorAmbient
                    Lighting.ColorShift_Top = mapProps.ColorShift_Top
                    Lighting.ColorShift_Bottom = mapProps.ColorShift_Bottom
                elseif LightingState then
                    if LightingState.origAmbient then Lighting.Ambient = LightingState.origAmbient end
                    if LightingState.origOutdoorAmbient then Lighting.OutdoorAmbient = LightingState.origOutdoorAmbient end
                    if LightingState.origColorShift_Top then Lighting.ColorShift_Top = LightingState.origColorShift_Top end
                    if LightingState.origColorShift_Bottom then Lighting.ColorShift_Bottom = LightingState.origColorShift_Bottom end
                end
            end)
            if setVisualRecoilRemoval then
                setVisualRecoilRemoval(false)
            end
            if setSmokeRemoval then
                setSmokeRemoval(false)
            end
            if setFlashScale then
                setFlashScale(1.00)
            end
            for _, c in ipairs(flashConnections) do
                pcall(function() c:Disconnect() end)
            end
            table.clear(flashConnections)
            if origGetWeaponRecoil then
                pcall(function()
                    local controllers = ReplicatedStorage:FindFirstChild("Controllers")
                    local cc = controllers and controllers:FindFirstChild("CameraController")
                    if cc then
                        local cameraController = require(cc)
                        if cameraController then
                            cameraController.getWeaponRecoil = origGetWeaponRecoil
                        end
                    end
                end)
            end
            if MiscHooks and MiscHooks.cleanupMiscHooks then
                pcall(MiscHooks.cleanupMiscHooks)
            end
        end)
        for _, conn in ipairs(Connections) do
            pcall(function() conn:Disconnect() end)
        end
        table.clear(Connections)
        pcall(function()
            local gui = getgenv().MemeSenseGui
            if gui then
                getgenv().MemeSenseGui = nil
                gui:Destroy()
            end
        end)
        pcall(function()
            local cont = getgenv().MemeSenseContainer
            if cont and cont.Name == "MemeSenseContainer" then
                getgenv().MemeSenseContainer = nil
                pcall(function() cont:Destroy() end)
            end
        end)
    end

    local api = {
        Window = MainWindow,
        ScreenGui = ScreenGui,
        Tabs = Tabs,
        Theme = Theme,
        Controls = Controls,
        SelectTab = SelectTab,
        SetTabGlyphs = function(glyphsTable)
            for tName, glyph in pairs(glyphsTable) do
                TabIconGlyphs[tName] = glyph
                if Tabs[tName] and Tabs[tName].Icon then
                    Tabs[tName].Icon.Text = glyph
                end
            end
        end,
        Toggle = function(val)
            local target = (val ~= nil) and val or (not MenuVisible)
            setMenuVisible(target)
        end,
        Cleanup = getgenv().MemeSenseCleanup,
        Inventory = MemeSenseInventory
    }
    getgenv().MemeSenseInventory = MemeSenseInventory

    MemeSense = api
end)()

getgenv().MemeSense = MemeSense
return MemeSense
