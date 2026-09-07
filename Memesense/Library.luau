--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                        MEMESENSE CHEAT INTERFACE                          ║
    ║               Built with MemeSense UI Library (Library.luau)              ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

-- Load the MemeSense Library
local Library = getgenv().MemeSenseLibrary or getgenv().MemeSense

if not Library then
    local candidates = {
        "Memesense/Library.luau",
        "Library.luau",
        "Memesense/Library.lua",
        "Library.lua",
        "scripts/Memesense/Library.luau",
        "scripts/Library.luau",
        "RobloxScripts/Memesense/Library.luau",
    }
    for _, path in ipairs(candidates) do
        if typeof(isfile) == "function" and pcall(function() return isfile(path) end) and isfile(path) then
            if typeof(loadfile) == "function" then
                local ok, res = pcall(function() return loadfile(path)() end)
                if ok and res then Library = res break end
            end
            if not Library and typeof(readfile) == "function" then
                local ok, res = pcall(function() return loadstring(readfile(path))() end)
                if ok and res then Library = res break end
            end
        end
    end
end

if not Library then
    local cacheBust = "?t=" .. tostring(os.time() or tick())
    local urls = {
        "https://raw.githubusercontent.com/AJWOLF321/Other/main/Memesense/Library.luau" .. cacheBust,
        "https://raw.githubusercontent.com/AJWOLF321/Other/main/Memesense/Library.luau",
        "https://raw.githubusercontent.com/AJWOLF321/Other/refs/heads/main/Memesense/Library.luau" .. cacheBust,
        "https://raw.githubusercontent.com/AJWOLF321/Other/refs/heads/main/Memesense/Library.luau",
    }
    local loadError = "Unknown error"
    for _, url in ipairs(urls) do
        local okHttp, content = pcall(function()
            return game:HttpGet(url)
        end)
        if okHttp and typeof(content) == "string" and #content > 500 then
            local fn, compileErr = loadstring(content)
            if fn then
                local okRun, res = pcall(fn)
                if okRun and res then
                    Library = res
                    break
                else
                    loadError = "Runtime error in Library: " .. tostring(res)
                    warn("[MemeSense] " .. loadError)
                end
            else
                loadError = "Compile error (" .. #content .. " bytes): " .. tostring(compileErr)
                warn("[MemeSense] " .. loadError)
            end
        else
            loadError = "HttpGet failed: " .. tostring(content)
        end
    end
end

if not Library then
    error("Failed to load MemeSense Library from GitHub or local files. Please run main.luau directly (which is fully self-contained), or verify GitHub raw URL.")
end

local Tabs = Library.Tabs
local Controls = Library.Controls
local GuiIconsFont = Library.GuiIconsFont
local Theme = Library.Theme
local function CreateTab(name, order)
    return Library:CreateTab(name, order)
end
local function SelectTab(name)
    return Library:SelectTab(name)
end

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║             INITIALIZE ALL 12 MEMESENSE TABS (STRICT ORDER)               ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

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
    "Grenade Helper",
    "Configs"
}

for i, tName in ipairs(TabNames) do
    CreateTab(tName, i)
end

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║         POPULATE "AIM ASSIST" (EXACT CONTROLS FROM SCREENSHOT)            ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

do
    local function run()
        local AimAssistTab = Tabs["Aim Assist"]
    local Left = AimAssistTab.LeftColumn
    local Right = AimAssistTab.RightColumn

    -- ─── LEFT COLUMN: TRIGGER ──────────────────────────────────────────────────
    do
        local leftOrder = 0
        local function nextLeft()
            leftOrder += 1
            return leftOrder
        end
Controls:CreateSectionHeader(Left, "Trigger", nextLeft())

-- 1. Enable toggle (Checked, with keybind active/red - Screenshot 2 & 4)
Controls:CreateToggle(Left, {
    Name = "Enable",
    Default = true,
    Keybind = { Key = Enum.KeyCode.E, Type = "On key down" },
    LayoutOrder = nextLeft(),
    Callback = function(v) end
})

-- 2. Through wall toggle (Unchecked, with keybind inactive/gray - Screenshot 2)
Controls:CreateToggle(Left, {
    Name = "Through wall",
    Default = false,
    Keybind = { Key = nil, Type = "On key down" },
    LayoutOrder = nextLeft(),
    Callback = function(v) end
})

-- 3. Air check (Unchecked)
Controls:CreateToggle(Left, {
    Name = "Air check",
    Default = false,
    LayoutOrder = nextLeft(),
    Callback = function(v) end
})

-- 4. Auto scope (Unchecked)
Controls:CreateToggle(Left, {
    Name = "Auto scope",
    Default = false,
    LayoutOrder = nextLeft(),
    Callback = function(v) end
})

-- 5. Scope check (Unchecked, hover-highlight ready)
Controls:CreateToggle(Left, {
    Name = "Scope check",
    Default = false,
    LayoutOrder = nextLeft(),
    Callback = function(v) end
})

-- 6. Flash check (Checked)
Controls:CreateToggle(Left, {
    Name = "Flash check",
    Default = true,
    LayoutOrder = nextLeft(),
    Callback = function(v) end
})

-- 7. Smoke check (Checked)
Controls:CreateToggle(Left, {
    Name = "Smoke check",
    Default = true,
    LayoutOrder = nextLeft(),
    Callback = function(v) end
})

-- 8. Ignore breakables (Unchecked)
Controls:CreateToggle(Left, {
    Name = "Ignore breakables",
    Default = false,
    LayoutOrder = nextLeft(),
    Callback = function(v) end
})

-- 9. Lock camera after shot slider (0.000 s)
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

-- 10. Delay between shots slider (0.000 s)
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

-- 11. Hit chance type dropdown ("Spread")
Controls:CreateDropdown(Left, {
    Name = "Hit chance type",
    Options = { "Spread", "Recoil", "Static", "Dynamic" },
    Default = "Spread",
    LayoutOrder = nextLeft(),
    Callback = function(v) end
})

-- 12. Visible / Auto wall Dual Selector
Controls:CreateDualFilter(Left, {
    Option1 = "Visible",
    Option2 = "Auto wall",
    LayoutOrder = nextLeft(),
    Callback = function(v) end
})

-- 13. Hit groups Multi-select dropdown ("Head, Neck, C")
Controls:CreateMultiDropdown(Left, {
    Name = "Hit groups",
    Options = { "Head", "Neck", "Chest", "Stomach", "Arms", "Legs" },
    Default = { Head = true, Neck = true, Chest = true },
    LayoutOrder = nextLeft(),
    Callback = function(v) end
})

-- 14. Minimum damage slider (0 HP)
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

-- 15. Minimum hit chance slider (0%)
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

-- 16. Reaction time slider (0 ms)
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

-- ─── RIGHT COLUMN: RCS & AUTO PISTOL ───────────────────────────────────────
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

-- 1. Enable toggle (Unchecked by default matching Screenshot 1, with keybind)
local rcsEnable = Controls:CreateToggle(Right, {
    Name = "Enable",
    Default = false,
    Keybind = { Key = nil, Type = "On key down" },
    LayoutOrder = nextRight(),
    Callback = function(v)
        updateRCSSliders(v)
    end
})

-- 2. Bullet start slider (Value: 2 in Screenshot 1, disabled if RCS Enable is off)
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

-- 3. Bullet end slider (Value: 30 in Screenshot 1, disabled if RCS Enable is off)
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

-- 4. X slider (Value: 1.000 in Screenshot 1, disabled if RCS Enable is off)
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

-- 5. Y slider (Value: 1.000 in Screenshot 1, disabled if RCS Enable is off)
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

-- Auto Pistol Sub-Section
Controls:CreateSectionHeader(Right, "Auto Pistol", nextRight())

-- 6. Enable toggle (Unchecked)
Controls:CreateToggle(Right, {
    Name = "Enable",
    Default = false,
    Keybind = { Key = nil, Type = "On key down" },
    LayoutOrder = nextRight(),
    Callback = function(v) end
})

-- 7. Delay between shots slider (0 ms)
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

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║         POPULATE "LEGITBOT" (EXACT CONTROLS FROM USER SCREENSHOT)         ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

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

-- ─── LEGITBOT: GENERAL (LEFT COLUMN) ─────────────────────────────────────────
Controls:CreateSectionHeader(LLeft, "General", nextLLeft())

Controls:CreateToggle(LLeft, {
    Name = "Enable",
    Default = true,
    LayoutOrder = nextLLeft()
})

Controls:CreateToggle(LLeft, {
    Name = "Aim key",
    Default = true,
    Keybind = { Key = nil, Type = "On key down" },
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

-- Sub-tabs Container Setup (Order: Aim, Accuracy, RCS, Misc)
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

-- ─── SUB-TAB: AIM ─────────────────────────────────────────────────────────────
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

-- ─── SUB-TAB: ACCURACY (Screenshot 3) ─────────────────────────────────────────
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

-- ─── SUB-TAB: RCS (Screenshot 4) ──────────────────────────────────────────────
    Controls:CreateToggle(RCSContainer, {
        Name = "Enable",
        Default = true,
        LayoutOrder = 1
    })

    Controls:CreateToggle(RCSContainer, {
        Name = "Disable on non-auto weapons",
        Default = true,
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

-- ─── SUB-TAB: MISC (Screenshot 5) ─────────────────────────────────────────────
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

-- ─── LEGITBOT: HIT GROUPS (RIGHT COLUMN) ─────────────────────────────────────
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
        Keybind = { Key = nil, Type = "On key down", HasIndicator = true, Indicator = false, IndicatorText = "BAIM" },
        LayoutOrder = nextLRight()
    })

    Controls:CreateToggle(LRight, {
        Name = "Prefer head aim",
        Default = true,
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

-- ─── LEGITBOT: AUTO FIRE / AUTO WALL (RIGHT COLUMN) ──────────────────────────
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

    -- Auto Fire Controls
    Controls:CreateToggle(AutoFireContainer, {
        Name = "Enable",
        Default = true,
        Keybind = { Key = nil, Type = "On key down", HasIndicator = true, Indicator = false, IndicatorText = "AF" },
        LayoutOrder = 1
    })

    Controls:CreateDualToggle(AutoFireContainer,
        { Name = "Auto stop", Default = true },
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

    -- Auto Wall Controls (Screenshot 2)
    Controls:CreateToggle(AutoWallContainer, {
        Name = "Enable",
        Default = true,
        Keybind = { Key = nil, Type = "On key down", HasIndicator = true, Indicator = false, IndicatorText = "AW" },
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

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║          POPULATE "PLAYERS" (EXACT CONTROLS FROM SCREENSHOT)              ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

do
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

Controls:CreateToggle(PLeft, {
    Name = "Enable",
    Default = true,
    Keybind = { Key = nil, Type = "On key down" },
    LayoutOrder = nextPLeft()
})

Controls:CreateToggle(PLeft, {
    Name = "Through wall",
    Default = true,
    LayoutOrder = nextPLeft()
})

Controls:CreateToggle(PLeft, {
    Name = "Nickname",
    Default = true,
    SettingsIcon = true,
    LayoutOrder = nextPLeft()
})

Controls:CreateToggle(PLeft, {
    Name = "Box",
    Default = false,
    SettingsIcon = true,
    LayoutOrder = nextPLeft()
})

Controls:CreateToggle(PLeft, {
    Name = "Health bar",
    Default = true,
    SettingsIcon = true,
    LayoutOrder = nextPLeft()
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
    Default = true,
    SettingsIcon = true,
    LayoutOrder = nextPLeft()
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

-- Right Column: Flags
Controls:CreateSectionHeader(PRight, "Flags", nextPRight())

local playerFlags = {
    { Name = "Bomb", Default = true },
    { Name = "Health", Default = true },
    { Name = "Ammo", Default = false },
    { Name = "Reload", Default = false },
    { Name = "Scoped", Default = false },
    { Name = "Flashed", Default = true },
    { Name = "Distance", Default = false },
    { Name = "Defuse kit", Default = false },
    { Name = "Helmet & kevlar", Default = false },
    { Name = "Defusing / rescuing", Default = true },
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
end

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║           POPULATE "CHAMS" (EXACT CONTROLS FROM SCREENSHOT)               ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

do
    local function run()
        local ChamsTab = Tabs["Chams"]
    local CHLeft = ChamsTab.LeftColumn
    local CHRight = ChamsTab.RightColumn

local chLeftOrder = 0
local function nextCHLeft()
    chLeftOrder += 1
    return chLeftOrder
end

local chRightOrder = 0
local function nextCHRight()
    chRightOrder += 1
    return chRightOrder
end

-- Left Column: Enemy team
Controls:CreateSectionHeader(CHLeft, "Enemy team", nextCHLeft())

Controls:CreateToggle(CHLeft, {
    Name = "Gun game immunity",
    Default = false,
    LayoutOrder = nextCHLeft()
})

Controls:CreateSectionHeader(CHLeft, "Customizations", nextCHLeft())

Controls:CreateToggle(CHLeft, {
    Name = "Glow",
    Default = true,
    ColorChip = Color3.fromRGB(255, 255, 255),
    LayoutOrder = nextCHLeft()
})

Controls:CreateToggle(CHLeft, {
    Name = "Visible",
    Default = true,
    ColorChip = Color3.fromRGB(68, 175, 245),
    Dropdown = { Options = { "Bloom", "Flat", "Model", "Textured" }, Default = "Bloom" },
    LayoutOrder = nextCHLeft()
})

Controls:CreateToggle(CHLeft, {
    Name = "Invisible",
    Default = true,
    ColorChip = Color3.fromRGB(68, 175, 245),
    Dropdown = { Options = { "Bloom", "Flat", "Model", "Textured" }, Default = "Flat" },
    LayoutOrder = nextCHLeft()
})

Controls:CreateToggle(CHLeft, {
    Name = "Sound",
    Default = false,
    ColorChip = Color3.fromRGB(255, 255, 255),
    LayoutOrder = nextCHLeft()
})

-- Right Column: Local team
Controls:CreateSectionHeader(CHRight, "Local team", nextCHRight())

Controls:CreateToggle(CHRight, {
    Name = "Gun game immunity",
    Default = false,
    LayoutOrder = nextCHRight()
})

Controls:CreateSectionHeader(CHRight, "Customizations", nextCHRight())

Controls:CreateToggle(CHRight, {
    Name = "Glow",
    Default = false,
    ColorChip = Color3.fromRGB(255, 255, 255),
    LayoutOrder = nextCHRight()
})

Controls:CreateToggle(CHRight, {
    Name = "Visible",
    Default = false,
    ColorChip = Color3.fromRGB(255, 255, 255),
    Dropdown = { Options = { "Bloom", "Flat", "Model", "Textured" }, Default = "Bloom" },
    LayoutOrder = nextCHRight()
})

Controls:CreateToggle(CHRight, {
    Name = "Invisible",
    Default = false,
    ColorChip = Color3.fromRGB(255, 255, 255),
    Dropdown = { Options = { "Bloom", "Flat", "Model", "Textured" }, Default = "Bloom" },
    LayoutOrder = nextCHRight()
})

Controls:CreateToggle(CHRight, {
    Name = "Sound",
    Default = false,
    ColorChip = Color3.fromRGB(255, 255, 255),
    LayoutOrder = nextCHRight()
})
    end
    run()
end

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║           POPULATE "ITEMS" (EXACT CONTROLS FROM SCREENSHOT)               ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

do
    local function run()
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
            { Name = "C4", B = false, T = true, I = true, D = false },
            { Name = "Planted C4", B = false, T = true, I = true, D = false },
            { Name = "Defuse kit", B = false, T = false, I = false, D = false },
            { Name = "Chicken", B = false, T = false, I = false, D = false },
            { Name = "Hostage", B = false, T = false, I = false, D = false },
            { Name = "Taser", B = false, T = false, I = false, D = false },
            { Name = "Knife", B = false, T = false, I = false, D = false },
            { Name = "Pistol", B = false, T = false, I = true, D = false },
            { Name = "Rifle", B = false, T = false, I = false, D = false },
            { Name = "Shotgun", B = false, T = false, I = false, D = false },
            { Name = "Sniper", B = false, T = false, I = true, D = false },
            { Name = "Machine gun", B = false, T = false, I = false, D = false },
            { Name = "Submachine gun", B = false, T = false, I = false, D = false }
        }

        for _, item in ipairs(leftItems) do
            item.LayoutOrder = nextITLeft()
            Controls:CreateMatrixRow(ITLeft, item)
        end

        Controls:CreateMatrixHeader(ITRight, nextITRight())

        local rightItems = {
            { Name = "Grenade", B = false, T = true, I = false, D = false, Color = Color3.fromRGB(215, 130, 45) },
            { Name = "Decoy", B = false, T = false, I = false, D = false },
            { Name = "Flashbang", B = false, T = false, I = false, D = false },
            { Name = "Smoke grenade", B = false, T = false, I = true, D = false },
            { Name = "Incendiary grenade", B = false, T = false, I = true, D = false },
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
    run()
end

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║          POPULATE "VISUALS" (EXACT CONTROLS FROM SCREENSHOT)              ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

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

        -- Left Column: Grenades
        Controls:CreateSectionHeader(VLeft, "Grenades", nextVLeft())

        Controls:CreateToggle(VLeft, {
            Name = "Grenade prediction",
            Default = true,
            ColorChips = { Color3.fromRGB(230, 180, 120), Color3.fromRGB(230, 180, 120) },
            LayoutOrder = nextVLeft()
        })

        Controls:CreateToggle(VLeft, {
            Name = "Smoke grenade timer",
            Default = true,
            ColorChip = Color3.fromRGB(255, 255, 255),
            LayoutOrder = nextVLeft()
        })

        Controls:CreateToggle(VLeft, {
            Name = "Incendiary grenade timer",
            Default = true,
            ColorChip = Color3.fromRGB(255, 255, 255),
            LayoutOrder = nextVLeft()
        })

        Controls:CreateToggle(VLeft, {
            Name = "Grenade tracers",
            Default = true,
            SettingsIcon = true,
            SettingsIconText = "6",
            SettingsIconFont = GuiIconsFont,
            SettingsIconSize = 13,
            OnSettingsClick = function(btn)
                Controls:OpenGrenadeTracers(btn)
            end,
            LayoutOrder = nextVLeft()
        })

        -- Right Column: Miscellaneous
        Controls:CreateSectionHeader(VRight, "Miscellaneous", nextVRight())

        Controls:CreateToggle(VRight, {
            Name = "Bomb timer",
            Default = true,
            LayoutOrder = nextVRight()
        })

        Controls:CreateToggle(VRight, {
            Name = "Spectator list",
            Default = true,
            LayoutOrder = nextVRight()
        })

        Controls:CreateToggle(VRight, {
            Name = "Hit marker",
            Default = false,
            ColorChip = Color3.fromRGB(230, 180, 120),
            LayoutOrder = nextVRight()
        })

        Controls:CreateToggle(VRight, {
            Name = "Textured radar",
            Default = false,
            SettingsIcon = true,
            SettingsIconText = "6",
            SettingsIconFont = GuiIconsFont,
            SettingsIconSize = 13,
            LayoutOrder = nextVRight()
        })
    end
    run()
end

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║           POPULATE "WORLD" (EXACT CONTROLS FROM SCREENSHOT)               ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

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

        -- Left Column: Textures & Extra
        Controls:CreateSectionHeader(WLeft, "Textures", nextWLeft())

        Controls:CreateToggle(WLeft, {
            Name = "Skybox",
            Default = true,
            ColorChip = Color3.fromRGB(230, 160, 60),
            Dropdown = { Options = { "Default", "Night", "Sunset", "Clear" }, Default = "Default" },
            LayoutOrder = nextWLeft()
        })

        Controls:CreateToggle(WLeft, {
            Name = "Override post-processing",
            Default = false,
            SettingsIcon = true,
            SettingsIconText = "6",
            SettingsIconFont = GuiIconsFont,
            SettingsIconSize = 13,
            LayoutOrder = nextWLeft()
        })

        Controls:CreateToggle(WLeft, {
            Name = "Override DoF",
            Default = false,
            SettingsIcon = true,
            SettingsIconText = "6",
            SettingsIconFont = GuiIconsFont,
            SettingsIconSize = 13,
            LayoutOrder = nextWLeft()
        })

        Controls:CreateToggle(WLeft, {
            Name = "Custom ambient color",
            Default = false,
            ColorChip = Color3.fromRGB(255, 255, 255),
            LayoutOrder = nextWLeft()
        })

        local customLightingVal = 1.384
        Controls:CreateToggle(WLeft, {
            Name = "Custom lighting",
            Default = true,
            SettingsIcon = true,
            SettingsIconText = "6",
            SettingsIconFont = GuiIconsFont,
            SettingsIconSize = 13,
            OnSettingsClick = function(btn)
                Controls:OpenVolumePopover(btn, customLightingVal, function(v)
                    customLightingVal = v
                end)
            end,
            LayoutOrder = nextWLeft()
        })

        Controls:CreateToggle(WLeft, {
            Name = "Modulate textures",
            Default = true,
            ColorChip = Color3.fromRGB(165, 150, 135),
            LayoutOrder = nextWLeft()
        })

        Controls:CreateToggle(WLeft, {
            Name = "Modulate static props",
            Default = false,
            ColorChip = Color3.fromRGB(190, 185, 230),
            LayoutOrder = nextWLeft()
        })

        Controls:CreateToggle(WLeft, {
            Name = "Modulate clouds",
            Default = true,
            ColorChip = Color3.fromRGB(255, 255, 255),
            LayoutOrder = nextWLeft()
        })

        Controls:CreateToggle(WLeft, {
            Name = "World textures overlay",
            Default = false,
            LayoutOrder = nextWLeft()
        })

        Controls:CreateSlider(WLeft, {
            Name = "Exposure",
            Min = 0.000,
            Max = 5.000,
            Default = 1.384,
            Decimals = 3,
            LayoutOrder = nextWLeft()
        })

        Controls:CreateSectionHeader(WLeft, "Extra", nextWLeft())

        Controls:CreateToggle(WLeft, {
            Name = "Force sniper crosshair",
            Default = false,
            LayoutOrder = nextWLeft()
        })

        Controls:CreateToggle(WLeft, {
            Name = "Penetration crosshair",
            Default = true,
            SettingsIcon = true,
            LayoutOrder = nextWLeft()
        })

        Controls:CreateSlider(WLeft, {
            Name = "Flash scale",
            Min = 0.00,
            Max = 1.00,
            Default = 0.00,
            Decimals = 2,
            LayoutOrder = nextWLeft()
        })

        -- Right Column: Removals
        Controls:CreateSectionHeader(WRight, "Removals", nextWRight())

        Controls:CreateToggle(WRight, {
            Name = "Blood",
            Default = true,
            LayoutOrder = nextWRight()
        })

        Controls:CreateToggle(WRight, {
            Name = "Shadows",
            Default = true,
            LayoutOrder = nextWRight()
        })

        Controls:CreateToggle(WRight, {
            Name = "Zoom hud",
            Default = true,
            LayoutOrder = nextWRight()
        })

        Controls:CreateToggle(WRight, {
            Name = "Zoom spread",
            Default = false,
            LayoutOrder = nextWRight()
        })

        Controls:CreateToggle(WRight, {
            Name = "Visual recoil",
            Default = true,
            LayoutOrder = nextWRight()
        })

        Controls:CreateToggle(WRight, {
            Name = "3D skybox",
            Default = true,
            LayoutOrder = nextWRight()
        })

        Controls:CreateToggle(WRight, {
            Name = "Smoke grenades",
            Default = true,
            LayoutOrder = nextWRight()
        })

        Controls:CreateToggle(WRight, {
            Name = "First-person legs",
            Default = true,
            LayoutOrder = nextWRight()
        })

        Controls:CreateToggle(WRight, {
            Name = "Team intro",
            Default = true,
            LayoutOrder = nextWRight()
        })
    end
    run()
end

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║            POPULATE "VIEW" (EXACT CONTROLS FROM SCREENSHOT)               ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

do
    local function run()
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

        -- Left Column: View model
        Controls:CreateSectionHeader(VWLeft, "View model", nextVWLeft())

        Controls:CreateToggle(VWLeft, {
            Name = "Hand shakes",
            Default = true,
            LayoutOrder = nextVWLeft()
        })

        Controls:CreateSlider(VWLeft, {
            Name = "Field of view",
            Min = 0,
            Max = 150,
            Default = 120,
            Suffix = "°",
            LayoutOrder = nextVWLeft()
        })

        Controls:CreateToggle(VWLeft, {
            Name = "Custom origin",
            Default = true,
            LayoutOrder = nextVWLeft()
        })

        Controls:CreateSlider(VWLeft, {
            Name = "X",
            Min = -20,
            Max = 20,
            Default = 8.147,
            Decimals = 3,
            LayoutOrder = nextVWLeft()
        })

        Controls:CreateSlider(VWLeft, {
            Name = "Y",
            Min = -20,
            Max = 20,
            Default = 3.664,
            Decimals = 3,
            LayoutOrder = nextVWLeft()
        })

        Controls:CreateSlider(VWLeft, {
            Name = "Z",
            Min = -20,
            Max = 20,
            Default = -7.974,
            Decimals = 3,
            LayoutOrder = nextVWLeft()
        })

        Controls:CreateToggle(VWLeft, {
            Name = "Custom angles",
            Default = true,
            LayoutOrder = nextVWLeft()
        })

        Controls:CreateSlider(VWLeft, {
            Name = "Pitch",
            Min = -90,
            Max = 90,
            Default = 4.267,
            Decimals = 3,
            Suffix = "°",
            LayoutOrder = nextVWLeft()
        })

        Controls:CreateSlider(VWLeft, {
            Name = "Yaw",
            Min = -180,
            Max = 180,
            Default = -10.000,
            Decimals = 3,
            Suffix = "°",
            LayoutOrder = nextVWLeft()
        })

        Controls:CreateSlider(VWLeft, {
            Name = "Roll",
            Min = -180,
            Max = 180,
            Default = 2.457,
            Decimals = 3,
            Suffix = "°",
            LayoutOrder = nextVWLeft()
        })

        -- Right Column: Camera & Third-person
        Controls:CreateSectionHeader(VWRight, "Camera", nextVWRight())

        Controls:CreateToggle(VWRight, {
            Name = "Free look",
            Default = false,
            Keybind = { Key = Enum.KeyCode.Unknown, Mode = "Hold" },
            LayoutOrder = nextVWRight()
        })

        Controls:CreateSlider(VWRight, {
            Name = "Aspect ratio",
            Min = 0.5,
            Max = 2.5,
            Default = 1.099,
            Decimals = 3,
            LayoutOrder = nextVWRight()
        })

        Controls:CreateSlider(VWRight, {
            Name = "Field of view",
            Min = 0,
            Max = 150,
            Default = 120,
            Suffix = "°",
            LayoutOrder = nextVWRight()
        })

        Controls:CreateSlider(VWRight, {
            Name = "Zoom field of view 1",
            Min = 0,
            Max = 150,
            Default = 120,
            Suffix = "°",
            LayoutOrder = nextVWRight()
        })

        Controls:CreateSlider(VWRight, {
            Name = "Zoom field of view 2",
            Min = 0,
            Max = 150,
            Default = 80,
            Suffix = "°",
            LayoutOrder = nextVWRight()
        })

        Controls:CreateSectionHeader(VWRight, "Third-person", nextVWRight())

        Controls:CreateToggle(VWRight, {
            Name = "Enable",
            Default = true,
            Keybind = { Key = Enum.KeyCode.Unknown, Mode = "Toggle" },
            LayoutOrder = nextVWRight()
        })

        Controls:CreateSlider(VWRight, {
            Name = "Max distance",
            Min = 0,
            Max = 300,
            Default = 150,
            Suffix = "u",
            LayoutOrder = nextVWRight()
        })
    end
    run()
end

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║         POPULATE "INDICATORS" (EXACT CONTROLS FROM SCREENSHOT)            ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

do
    local function run()
        local IndicatorsTab = Tabs["Indicators"]
        local IndLeft = IndicatorsTab.LeftColumn
        local IndRight = IndicatorsTab.RightColumn

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

        -- Left Column: Indicators (Screenshot media_1788799615273.png)
        Controls:CreateSectionHeader(IndLeft, "Indicators", nextIndLeft())

        Controls:CreateToggle(IndLeft, {
            Name = "Bomb timer",
            Default = true,
            ColorChip = Color3.fromRGB(230, 160, 60),
            LayoutOrder = nextIndLeft()
        })

        Controls:CreateToggle(IndLeft, {
            Name = "Spectator list",
            Default = true,
            SettingsIcon = true,
            SettingsIconText = "6",
            SettingsIconFont = GuiIconsFont,
            SettingsIconSize = 13,
            LayoutOrder = nextIndLeft()
        })

        Controls:CreateToggle(IndLeft, {
            Name = "Keybind list",
            Default = true,
            SettingsIcon = true,
            SettingsIconText = "6",
            SettingsIconFont = GuiIconsFont,
            SettingsIconSize = 13,
            LayoutOrder = nextIndLeft()
        })

        Controls:CreateToggle(IndLeft, {
            Name = "Watermark",
            Default = true,
            ColorChip = Color3.fromRGB(229, 37, 53),
            LayoutOrder = nextIndLeft()
        })

        Controls:CreateToggle(IndLeft, {
            Name = "Velocity indicator",
            Default = false,
            LayoutOrder = nextIndLeft()
        })

        -- Right Column: Crosshairs & Alerts (Screenshot media_1788799615273.png)
        Controls:CreateSectionHeader(IndRight, "Crosshairs & Alerts", nextIndRight())

        Controls:CreateToggle(IndRight, {
            Name = "Recoil crosshair",
            Default = false,
            ColorChip = Color3.fromRGB(255, 255, 255),
            LayoutOrder = nextIndRight()
        })

        Controls:CreateToggle(IndRight, {
            Name = "Sniper crosshair",
            Default = false,
            ColorChip = Color3.fromRGB(255, 255, 255),
            LayoutOrder = nextIndRight()
        })

        Controls:CreateToggle(IndRight, {
            Name = "Hit marker",
            Default = true,
            ColorChip = Color3.fromRGB(245, 166, 35),
            LayoutOrder = nextIndRight()
        })

        Controls:CreateToggle(IndRight, {
            Name = "Damage indicator",
            Default = true,
            ColorChip = Color3.fromRGB(229, 37, 53),
            LayoutOrder = nextIndRight()
        })

        Controls:CreateToggle(IndRight, {
            Name = "Grenade trajectory",
            Default = true,
            ColorChip = Color3.fromRGB(100, 181, 246),
            LayoutOrder = nextIndRight()
        })
    end
    run()
end

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║        POPULATE "MISCELLANEOUS" (EXACT CONTROLS FROM SCREENSHOT)          ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

do
    local function run()
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

        -- Left Column: Interface & Movement (Screenshot media_1788795454395.png)
        Controls:CreateSectionHeader(MLeft, "Interface", nextMLeft())

        Controls:CreateToggle(MLeft, {
            Name = "Event logs",
            Default = true,
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
            Default = true,
            LayoutOrder = nextMLeft()
        })

        Controls:CreateToggle(MLeft, {
            Name = "Preserve kill-feed",
            Default = false,
            LayoutOrder = nextMLeft()
        })

        Controls:CreateToggle(MLeft, {
            Name = "Panorama extensions",
            Default = true,
            LayoutOrder = nextMLeft()
        })

        Controls:CreateSectionHeader(MLeft, "Movement", nextMLeft())

        Controls:CreateToggle(MLeft, {
            Name = "Bhop",
            Default = true,
            LayoutOrder = nextMLeft()
        })

        -- Right Column: Game interactive & Extra (Screenshot media_1788795454395.png)
        Controls:CreateSectionHeader(MRight, "Game interactive", nextMRight())

        Controls:CreateToggle(MRight, {
            Name = "Auto-accept match",
            Default = true,
            LayoutOrder = nextMRight()
        })

        Controls:CreateToggle(MRight, {
            Name = "Custom sound mixer",
            Default = false,
            SettingsIcon = true,
            SettingsIconText = "6",
            SettingsIconFont = GuiIconsFont,
            SettingsIconSize = 13,
            LayoutOrder = nextMRight()
        })

        Controls:CreateToggle(MRight, {
            Name = "Clan-tag spammer",
            Default = false,
            TextColor = Color3.fromRGB(208, 48, 48),
            LayoutOrder = nextMRight()
        })

        Controls:CreateTextInput(MRight, {
            Placeholder = "Enter custom player name...",
            Default = "",
            LayoutOrder = nextMRight()
        })

        Controls:CreateSectionHeader(MRight, "Extra", nextMRight())

        local hitSoundVolume = 5.000
        local killSoundVolume = 5.000
        local soundList = { "Default", "agpa1", "agpa2", "aimbooster", "amongus_kill", "applepay", "arena_switch", "bameware" }

        Controls:CreateToggle(MRight, {
            Name = "Hit sound",
            Default = true,
            SettingsIcon = true,
            SettingsIconText = "6",
            SettingsIconFont = GuiIconsFont,
            SettingsIconSize = 13,
            Dropdown = { Options = soundList, Default = "Default", Width = 84 },
            OnSettingsClick = function(btn)
                Controls:OpenVolumePopover(btn, hitSoundVolume, function(v)
                    hitSoundVolume = v
                end)
            end,
            LayoutOrder = nextMRight()
        })

        Controls:CreateToggle(MRight, {
            Name = "Kill sound",
            Default = true,
            SettingsIcon = true,
            SettingsIconText = "6",
            SettingsIconFont = GuiIconsFont,
            SettingsIconSize = 13,
            Dropdown = { Options = soundList, Default = "Default", Width = 84 },
            OnSettingsClick = function(btn)
                Controls:OpenVolumePopover(btn, killSoundVolume, function(v)
                    killSoundVolume = v
                end)
            end,
            LayoutOrder = nextMRight()
        })

        Controls:CreateToggle(MRight, {
            Name = "Region picker",
            Default = false,
            Dropdown = { Options = { "All", "EU", "NA", "ASIA" }, Default = "All", Width = 84 },
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
    end
    run()
end

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║        POPULATE "INVENTORY" (SKIN CHANGER & INVENTORY UTILITIES)          ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

do
    local function run()
        local InventoryTab = Tabs["Inventory"]
        local InvLeft = InventoryTab.LeftColumn
        local InvRight = InventoryTab.RightColumn

        local invLeftOrder = 0
        local function nextInvLeft()
            invLeftOrder += 1
            return invLeftOrder
        end

        local invRightOrder = 0
        local function nextInvRight()
            invRightOrder += 1
            return invRightOrder
        end

        -- Left Column: Skin Changer
        Controls:CreateSectionHeader(InvLeft, "Skin Changer", nextInvLeft())

        Controls:CreateToggle(InvLeft, {
            Name = "Enable",
            Default = true,
            LayoutOrder = nextInvLeft()
        })

        Controls:CreateDropdown(InvLeft, {
            Name = "Weapon",
            Options = { "AK-47", "M4A4", "M4A1-S", "AWP", "Desert Eagle", "USP-S", "Glock-18" },
            Default = "AK-47",
            LayoutOrder = nextInvLeft()
        })

        Controls:CreateDropdown(InvLeft, {
            Name = "Skin name",
            Options = { "Asiimov", "Redline", "Dragon Lore", "Printstream", "Howl", "Fade", "Hyper Beast" },
            Default = "Asiimov",
            LayoutOrder = nextInvLeft()
        })

        Controls:CreateSlider(InvLeft, {
            Name = "Wear",
            Min = 0.00,
            Max = 1.00,
            Default = 0.01,
            Decimals = 2,
            LayoutOrder = nextInvLeft()
        })

        Controls:CreateToggle(InvLeft, {
            Name = "StatTrak",
            Default = true,
            LayoutOrder = nextInvLeft()
        })

        Controls:CreateSlider(InvLeft, {
            Name = "StatTrak kills",
            Min = 0,
            Max = 99999,
            Default = 1337,
            Decimals = 0,
            LayoutOrder = nextInvLeft()
        })

        -- Right Column: Utilities
        Controls:CreateSectionHeader(InvRight, "Utilities", nextInvRight())

        Controls:CreateToggle(InvRight, {
            Name = "Force knife model",
            Default = false,
            Dropdown = { Options = { "Karambit", "Butterfly", "M9 Bayonet", "Skeleton", "Karambit Fade" }, Default = "Karambit" },
            LayoutOrder = nextInvRight()
        })

        Controls:CreateToggle(InvRight, {
            Name = "Force gloves model",
            Default = false,
            Dropdown = { Options = { "Sport Gloves | Vice", "Specialist Gloves | Crimson Kimono", "Driver Gloves | Snow Leopard" }, Default = "Sport Gloves | Vice" },
            LayoutOrder = nextInvRight()
        })

        Controls:CreateToggle(InvRight, {
            Name = "Unlock all inventory",
            Default = true,
            LayoutOrder = nextInvRight()
        })

        Controls:CreateButton(InvRight, {
            Name = "Apply changes",
            LayoutOrder = nextInvRight()
        })
    end
    run()
end

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                     POPULATE "GRENADE HELPER" TAB                         ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

do
    local function run()
        local GrenadeHelperTab = Tabs["Grenade Helper"]
        local GHLeft = GrenadeHelperTab.LeftColumn
        local GHRight = GrenadeHelperTab.RightColumn

        local ghLeftOrder = 0
        local function nextGHLeft()
            ghLeftOrder += 1
            return ghLeftOrder
        end

        local ghRightOrder = 0
        local function nextGHRight()
            ghRightOrder += 1
            return ghRightOrder
        end

        -- Left Column: General
        Controls:CreateSectionHeader(GHLeft, "General", nextGHLeft())

        Controls:CreateToggle(GHLeft, {
            Name = "Enable",
            Default = true,
            ColorChip = Color3.fromRGB(229, 37, 53),
            LayoutOrder = nextGHLeft()
        })

        Controls:CreateToggle(GHLeft, {
            Name = "Aim assist",
            Default = true,
            LayoutOrder = nextGHLeft()
        })

        Controls:CreateToggle(GHLeft, {
            Name = "Auto throw",
            Default = true,
            LayoutOrder = nextGHLeft()
        })

        Controls:CreateToggle(GHLeft, {
            Name = "On key only",
            Default = true,
            Keybind = { Key = Enum.KeyCode.E, Type = "On key down" },
            LayoutOrder = nextGHLeft()
        })

        -- Right Column: Visualization
        Controls:CreateSectionHeader(GHRight, "Visualization", nextGHRight())

        Controls:CreateToggle(GHRight, {
            Name = "Show trajectory",
            Default = true,
            ColorChip = Color3.fromRGB(100, 181, 246),
            LayoutOrder = nextGHRight()
        })

        Controls:CreateToggle(GHRight, {
            Name = "Show bounce points",
            Default = true,
            LayoutOrder = nextGHRight()
        })

        Controls:CreateToggle(GHRight, {
            Name = "Show name",
            Default = true,
            LayoutOrder = nextGHRight()
        })

        Controls:CreateToggle(GHRight, {
            Name = "Show preview",
            Default = true,
            LayoutOrder = nextGHRight()
        })

        Controls:CreateSlider(GHRight, {
            Name = "Distance limit",
            Min = 0,
            Max = 500,
            Default = 100,
            Suffix = "m",
            LayoutOrder = nextGHRight()
        })
    end
    run()
end

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                     POPULATE "CONFIGS" TAB                                ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

do
    local function run()
        local ConfigsTab = Tabs["Configs"]
        local CLeft = ConfigsTab.LeftColumn
        local CRight = ConfigsTab.RightColumn

        Controls:CreateSectionHeader(CLeft, "Config Manager", 1)
        Controls:CreateDropdown(CLeft, {
            Name = "Config list",
            Options = { "Default", "Legit_1", "Rage_HvH", "Comp_Safe" },
            Default = "Default",
            LayoutOrder = 2
        })
        Controls:CreateToggle(CLeft, { Name = "Auto save on change", Default = true, LayoutOrder = 3 })
        Controls:CreateButton(CLeft, { Name = "Save Config", LayoutOrder = 4 })
        Controls:CreateButton(CLeft, { Name = "Load Config", LayoutOrder = 5 })
        Controls:CreateButton(CLeft, { Name = "Import from clipboard", LayoutOrder = 6 })
        Controls:CreateButton(CLeft, { Name = "Export to clipboard", LayoutOrder = 7 })

        Controls:CreateSectionHeader(CRight, "Menu Settings", 1)
        Controls:CreateSlider(CRight, {
            Name = "Menu key",
            Min = 0,
            Max = 255,
            Default = 45,
            Suffix = "Insert",
            LayoutOrder = 2
        })
        Controls:CreateToggle(CRight, { Name = "Rainbow top bar", Default = true, LayoutOrder = 3 })
        Controls:CreateToggle(CRight, { Name = "Watermark", Default = true, LayoutOrder = 4 })
        Controls:CreateToggle(CRight, { Name = "Keybinds list", Default = true, LayoutOrder = 5 })
        Controls:CreateToggle(CRight, { Name = "Spectator list", Default = true, LayoutOrder = 6 })
    end
    run()
end

-- Select Aim Assist by default as in the screenshot
SelectTab("Aim Assist")


-- Finalize the menu with the Library
Library:Ready()

getgenv().MemeSense = Library
return Library
