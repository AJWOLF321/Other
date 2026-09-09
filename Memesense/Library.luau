--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                        MEMESENSE CHEAT INTERFACE                          ║
    ║               Pixel-Perfect 1:1 Recreation of MemeSense Menu              ║
    ║        Exact Layout, Obsidian Dark Theme, Glowing Gradient Top Bar,       ║
    ║        Custom TTF Font & Icon Downloader, Strict LayoutOrder Hierarchy    ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()

-- Clean up any existing running instances
if getgenv().MemeSenseCleanup then
    pcall(getgenv().MemeSenseCleanup)
end
if getgenv().MemeSenseGui and getgenv().MemeSenseGui.Parent then
    pcall(function() getgenv().MemeSenseGui:Destroy() end)
end
if getgenv().MemeSenseContainer and getgenv().MemeSenseContainer.Parent then
    pcall(function() getgenv().MemeSenseContainer:Destroy() end)
end


local Connections = {}

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                              THEME & TOKENS                               ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

local Theme = {
    -- Window backgrounds
    Background = Color3.fromRGB(15, 16, 18),        -- Main obsidian body
    SidebarBg = Color3.fromRGB(12, 13, 15),         -- Left navigation sidebar
    HeaderBg = Color3.fromRGB(15, 16, 18),          -- Top bar
    Border = Color3.fromRGB(26, 28, 33),            -- Outer / divider borders
    BorderSubtle = Color3.fromRGB(22, 23, 27),

    -- Accent & Branding
    Accent = Color3.fromRGB(229, 37, 53),           -- Signature MemeSense crimson red
    AccentHover = Color3.fromRGB(245, 55, 72),
    AccentMuted = Color3.fromRGB(140, 25, 36),

    -- Control Colors
    CheckboxOff = Color3.fromRGB(29, 30, 34),       -- exact rgba(29, 30, 34) (no outline)
    CheckboxHoverOff = Color3.fromRGB(115, 24, 38), -- transparent red hover highlight from user screenshot
    CheckboxChecked = Color3.fromRGB(229, 37, 53),

    ControlBg = Color3.fromRGB(20, 21, 26),
    DropdownBg = Color3.fromRGB(39, 40, 44),        -- exact rgba(39, 40, 44)
    DropdownHoverBg = Color3.fromRGB(95, 102, 112), -- exact rgba(95, 102, 112)
    ControlBorder = Color3.fromRGB(32, 34, 42),
    ControlBorderHover = Color3.fromRGB(48, 50, 60),

    SliderTrack = Color3.fromRGB(25, 27, 33),
    SliderFill = Color3.fromRGB(188, 192, 202),      -- Light silver fill as seen in Bullet end & X/Y

    -- Text Tones
    TextActive = Color3.fromRGB(255, 255, 255),     -- Pure super white
    TextInactive = Color3.fromRGB(255, 255, 255),   -- Pure super white for unselected tabs
    TextDim = Color3.fromRGB(110, 114, 125),        -- Unchecked toggle label tone
    TextSub = Color3.fromRGB(160, 164, 175),        -- Section titles & slider values
    
    -- Fonts (All menu text bolded)
    FontMedium = Enum.Font.GothamBold,
    FontBold = Enum.Font.GothamBold,
    FontRegular = Enum.Font.GothamBold
}

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║            FONT DOWNLOADER & POTASSIUM GETCUSTOMASSET ENGINE              ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

local GITHUB_RAW = "https://raw.githubusercontent.com/AJWOLF321/Other/main/Memesense/"
local FONT_FILES = {
    "gui-icons.ttf",
    "pixel7.ttf",
    "visuals-icons.ttf"
}

-- Ensure folders exist in executor workspace
if makefolder and isfolder then
    if not isfolder("Memesense") then
        pcall(makefolder, "Memesense")
    end
    if not isfolder("Memesense/fonts") then
        pcall(makefolder, "Memesense/fonts")
    end
end

-- Download fonts into Memesense/fonts if not already present
if writefile and isfile then
    for _, fontName in ipairs(FONT_FILES) do
        local localPath = "Memesense/fonts/" .. fontName
        if not isfile(localPath) then
            pcall(function()
                local content = game:HttpGet(GITHUB_RAW .. fontName)
                if content and #content > 0 then
                    writefile(localPath, content)
                end
            end)
        end
    end
end

local customAsset = getcustomasset or getsynasset
local GuiIconsFont = nil
local ttfPath = "Memesense/fonts/gui-icons.ttf"

if customAsset and isfile and isfile(ttfPath) then
    local okTtf, ttfAssetId = pcall(customAsset, ttfPath)

    -- Method 1: Roblox Font Family Manifest (Required by modern Roblox engine Font.new)
    local manifest = HttpService:JSONEncode({
        name = "MemeSenseIcons",
        faces = {
            {
                name = "Regular",
                weight = 400,
                style = "normal",
                assetId = ttfAssetId
            }
        }
    })

    local jsonPath = "Memesense/fonts/gui-icons.json"
    local fontManifestPath = "Memesense/fonts/gui-icons.font"
    pcall(writefile, jsonPath, manifest)
    pcall(writefile, fontManifestPath, manifest)

    -- Try loading from .json
    local okJsonAsset, jsonAssetId = pcall(customAsset, jsonPath)
    if okJsonAsset and jsonAssetId then
        local okFont, fontFace = pcall(function()
            return Font.new(jsonAssetId, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        end)
        if okFont and fontFace then
            GuiIconsFont = fontFace
        end
    end

    -- Try loading from .font if .json didn't work
    if not GuiIconsFont then
        local okFontAsset, fontAssetId = pcall(customAsset, fontManifestPath)
        if okFontAsset and fontAssetId then
            local okFont, fontFace = pcall(function()
                return Font.new(fontAssetId, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            end)
            if okFont and fontFace then
                GuiIconsFont = fontFace
            end
        end
    end

    -- Method 2: Direct raw TTF assetId fallback
    if not GuiIconsFont and okTtf and ttfAssetId then
        local okDirect, fontFace = pcall(function()
            return Font.new(ttfAssetId, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        end)
        if okDirect and fontFace then
            GuiIconsFont = fontFace
        end
    end
end

if not GuiIconsFont then
    GuiIconsFont = Font.fromEnum(Theme.FontMedium)
end

-- Glyphs for tabs
local TabIconGlyphs = {
    ["Legitbot"]      = "!",
    ["Aim Assist"]    = '"',
    ["Players"]       = "%",
    ["Chams"]         = "&",
    ["Items"]         = "1",
    ["Visuals"]       = "4",
    ["World"]         = "'",
    ["View"]          = "(",
    ["Indicators"]    = ")",
    ["Miscellaneous"] = "6",
    ["Inventory"]     = "-",
    ["Configs"]       = "."
}

local CommonIcons = {
    Checkmark = "rbxassetid://6031094667",
    Keyboard  = "rbxassetid://6034440027",
    CloudSave = "rbxassetid://6031075931",
    Chevron   = "rbxassetid://6034818379"
}

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                        CORE GUI & WINDOW BUILDER                          ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

-- ============================================================================
-- RANDOM SYMBOL STRING GENERATOR
-- Randomizes names of all instances created in CoreGui (same as base.luau)
-- ============================================================================
local SYMBOL_RAW = "│┤╡╢╖╕╣ ║╝╜╛ ┐ └┴┬├─┼ ╞╟╚╔╩╦ ╠═ ╬╧╨╤ ╥╙╘╒╓ ╫╪┘┌"

local SYMBOL_POOL = {}
for first, last in utf8.graphemes(SYMBOL_RAW) do
    local char = string.sub(SYMBOL_RAW, first, last)
    if char ~= " " and char ~= "\t" and char ~= "\n" and char ~= "\r" then
        table.insert(SYMBOL_POOL, char)
    end
end

local function GetRandomSymbolString(length)
    local len = length or math.random(12, 20)
    local result = table.create(len)
    local poolSize = #SYMBOL_POOL
    for i = 1, len do
        result[i] = SYMBOL_POOL[math.random(1, poolSize)]
    end
    return table.concat(result, "")
end

-- Safe Container Resolver (CoreGui > RobloxGui > Modules > Shell > Components)
local function GetSafeContainer()
    local targetParent = CoreGui

    local ok = pcall(function()
        local robloxGui = CoreGui:FindFirstChild("RobloxGui") or CoreGui:WaitForChild("RobloxGui", 2)
        if robloxGui then
            local modules = robloxGui:FindFirstChild("Modules") or robloxGui:WaitForChild("Modules", 2)
            if not modules then
                local newModules = Instance.new("Folder")
                newModules.Name = "Modules"
                newModules.Parent = robloxGui
                modules = newModules
            end

            local shell = modules:FindFirstChild("Shell") or modules:WaitForChild("Shell", 1)
            if not shell then
                local newShell = Instance.new("Folder")
                newShell.Name = "Shell"
                newShell.Parent = modules
                shell = newShell
            end

            local components = shell:FindFirstChild("Components") or shell:WaitForChild("Components", 1)
            if not components then
                local newComponents = Instance.new("Folder")
                newComponents.Name = "Components"
                newComponents.Parent = shell
                components = newComponents
            end

            targetParent = components
        end
    end)

    if not ok or not targetParent then
        targetParent = CoreGui
    end

    local folder = Instance.new("Folder")
    folder.Name = GetRandomSymbolString(16)
    folder.Parent = targetParent

    return folder
end

local Container = GetSafeContainer()
getgenv().MemeSenseContainer = Container

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GetRandomSymbolString(16)
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 10000
ScreenGui.IgnoreGuiInset = true

if syn and syn.protect_gui then
    pcall(syn.protect_gui, ScreenGui)
    pcall(syn.protect_gui, Container)
end
ScreenGui.Parent = Container
getgenv().MemeSenseGui = ScreenGui

Container.AncestryChanged:Connect(function(_, parent)
    if not parent then
        if getgenv().MemeSenseCleanup then
            getgenv().MemeSenseCleanup()
        end
    end
end)

-- ============================================================================
-- INSTANCE OBFUSCATION ENGINE
-- Ensures every single UI instance created in CoreGui is obfuscated with
-- random symbol strings identical to base.luau
-- ============================================================================
local realInstanceNew = Instance.new
local function createObfuscatedInstance(className, parent)
    local inst = realInstanceNew(className)
    pcall(function()
        inst.Name = GetRandomSymbolString(math.random(14, 20))
    end)
    if parent then
        inst.Parent = parent
    end
    return inst
end
local Instance = {
    new = createObfuscatedInstance
}

local function obfuscateInstanceName(inst)
    if typeof(inst) == "Instance" then
        pcall(function()
            inst.Name = GetRandomSymbolString(math.random(14, 20))
        end)
    end
end

local descAddedConn = Container.DescendantAdded:Connect(function(inst)
    obfuscateInstanceName(inst)
    task.defer(obfuscateInstanceName, inst)
end)
table.insert(Connections, descAddedConn)

local screenDescAddedConn = ScreenGui.DescendantAdded:Connect(function(inst)
    obfuscateInstanceName(inst)
    task.defer(obfuscateInstanceName, inst)
end)
table.insert(Connections, screenDescAddedConn)


-- Utility helpers
local function createCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 1)
    corner.Parent = parent
    return corner
end

local function createStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.Border
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

local GuiService = game:GetService("GuiService")
local PopupsLayer = nil

local function getRealMousePos()
    return UserInputService:GetMouseLocation()
end

local function getScreenPos(gui)
    if PopupsLayer and PopupsLayer.AbsolutePosition then
        return gui.AbsolutePosition - PopupsLayer.AbsolutePosition
    end
    return gui.AbsolutePosition
end

local function isPosInGui(gui, pos, pad)
    if not gui or not gui.Visible then return false end
    local sp = gui.AbsolutePosition
    local s = gui.AbsoluteSize
    local ep = pad or 0
    local m = pos
    if not m then
        m = UserInputService:GetMouseLocation()
    elseif typeof(m) == "Vector3" then
        m = Vector2.new(m.X, m.Y)
    end

    return m.X >= (sp.X - ep) and m.X <= (sp.X + s.X + ep) and m.Y >= (sp.Y - ep) and m.Y <= (sp.Y + s.Y + ep)
end

-- Utility to calculate dropdown popover width:
-- Matches the opener's width if the text can fit, or expands dynamically if text is longer
local function calculateDropdownWidth(openerAbsWidth, options, font, fontSize, extraPadding)
    local maxTextW = 0
    font = font or Theme.FontBold
    fontSize = fontSize or 11
    extraPadding = extraPadding or 20
    for _, opt in ipairs(options) do
        local str = tostring(opt)
        local success, sz = pcall(function()
            return TextService:GetTextSize(str, fontSize, font, Vector2.new(2000, 100))
        end)
        if success and sz and sz.X > maxTextW then
            maxTextW = sz.X
        end
    end
    local neededW = maxTextW + extraPadding
    if neededW <= openerAbsWidth then
        return openerAbsWidth
    else
        return math.ceil(neededW)
    end
end

-- Global popup closer for dropdowns & keybinds
local ActiveTab = nil
local WeaponChevron = nil
local ActivePopups = {}
local ColorPickerModal = nil
local draggingSV = false
local draggingHue = false
local draggingAlpha = false
local lastTypeSelectTime = 0

-- Modal Blocker to sink input and prevent hover over menu items when any dropdown is open
local ModalBlocker = Instance.new("TextButton")
ModalBlocker.Name = "ModalBlocker"
ModalBlocker.Size = UDim2.new(1, 0, 1, 0)
ModalBlocker.Position = UDim2.new(0, 0, 0, 0)
ModalBlocker.BackgroundTransparency = 1
ModalBlocker.Text = ""
ModalBlocker.AutoButtonColor = false
ModalBlocker.Active = true
ModalBlocker.Visible = false
ModalBlocker.ZIndex = 490
ModalBlocker.Parent = ScreenGui

local function CloseAllPopups(preservePredicate)
    if draggingSV or draggingHue or draggingAlpha then
        return
    end
    for _, item in ipairs(ActivePopups) do
        local frame = nil
        local onClose = nil
        if typeof(item) == "Instance" then
            frame = item
        elseif typeof(item) == "table" then
            frame = item.Frame
            onClose = item.OnClose
        end

        if frame then
            if frame == ColorPickerModal and (draggingSV or draggingHue or draggingAlpha) then
                -- Do NOT close color picker while actively dragging SV/Hue/Alpha
            elseif preservePredicate and preservePredicate(frame, item) then
                -- Skip closing this preserved popup
            else
                if frame.Parent then frame.Visible = false end
                if onClose then onClose() end
            end
        end
    end
    if WeaponChevron then
        WeaponChevron.Text = "C"
    end
    local anyStillOpen = false
    for _, item in ipairs(ActivePopups) do
        local frame = (typeof(item) == "table") and item.Frame or item
        if frame and frame:IsA("GuiObject") and frame.Visible then
            anyStillOpen = true
            break
        end
    end
    if not anyStillOpen and ModalBlocker then
        ModalBlocker.Visible = false
    end
end

local function handleModalBlockerClick()
    if draggingSV or draggingHue or draggingAlpha or (os.clock() - lastTypeSelectTime < 0.35) then return end
    local mouse = UserInputService:GetMouseLocation()
    for _, item in ipairs(ActivePopups) do
        local frame = (typeof(item) == "table") and item.Frame or item
        if frame and frame:IsA("GuiObject") and frame.Visible then
            if isPosInGui(frame, mouse, 6) then
                return
            end
            for _, desc in ipairs(frame:GetDescendants()) do
                if desc:IsA("GuiObject") and desc.Name == "TypePopover" then
                    if isPosInGui(desc, mouse, 6) then
                        return
                    end
                end
            end
        end
    end
    CloseAllPopups()
end

ModalBlocker.MouseButton1Down:Connect(handleModalBlockerClick)
ModalBlocker.MouseButton1Click:Connect(handleModalBlockerClick)

local function makeDraggable(mainFrame, dragHandle)
    local dragging = false
    local dragInput, dragStart, startPos

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            CloseAllPopups()
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local lastPopoverDragTime = 0

local function makePopoverDraggable(frame, isExcluded)
    local dragging = false
    local dragStart = nil
    local startPos = nil
    local moved = false

    local connBegan = UserInputService.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and frame.Visible then
            local pos = input.Position
            if isPosInGui(frame, pos) then
                if isExcluded and isExcluded(pos) then
                    return
                end
                dragging = true
                moved = false
                dragStart = UserInputService:GetMouseLocation()
                startPos = frame.Position
            end
        end
    end)
    table.insert(Connections, connBegan)

    local connChanged = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local curMouse = UserInputService:GetMouseLocation()
            local delta = curMouse - dragStart
            if not moved and (math.abs(delta.X) > 2 or math.abs(delta.Y) > 2) then
                moved = true
            end
            if moved then
                frame.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end
    end)
    table.insert(Connections, connChanged)

    local connEnded = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging and moved then
                lastPopoverDragTime = os.clock()
            end
            dragging = false
        end
    end)
    table.insert(Connections, connEnded)
end

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                           MAIN WINDOW CONTAINER                           ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

local WindowWidth = 700
local WindowHeight = 590

local MainWindow = Instance.new("Frame")
MainWindow.Name = "MainWindow"
MainWindow.Size = UDim2.new(0, WindowWidth, 0, WindowHeight)
MainWindow.Position = UDim2.new(0.5, -WindowWidth / 2, 0.5, -WindowHeight / 2)
MainWindow.BackgroundColor3 = Theme.Background
MainWindow.BorderSizePixel = 0
MainWindow.Parent = ScreenGui

createStroke(MainWindow, Theme.Border, 1)

-- Background overlay (darkens screen when menu is visible)
local BgOverlay = Instance.new("Frame")
BgOverlay.Name = "BgOverlay"
BgOverlay.Size = UDim2.new(1, 0, 1, 0)
BgOverlay.Position = UDim2.new(0, 0, 0, 0)
BgOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
BgOverlay.BackgroundTransparency = 0.65
BgOverlay.BorderSizePixel = 0
BgOverlay.ZIndex = 0
BgOverlay.Parent = ScreenGui

-- Popup Layer Container (ZIndex 500 on top of all base UI elements, parented to ScreenGui so popups never clip)
PopupsLayer = Instance.new("Frame")
PopupsLayer.Name = "PopupsLayer"
PopupsLayer.Size = UDim2.new(1, 0, 1, 0)
PopupsLayer.Position = UDim2.new(0, 0, 0, 0)
PopupsLayer.BackgroundTransparency = 1
PopupsLayer.ZIndex = 500
PopupsLayer.Parent = ScreenGui

-- Top Accent Bar (Square 0px corners, animated rainbow gradient like Gamesense)
local TopGlowBar = Instance.new("Frame")
TopGlowBar.Name = "TopGlowBar"
TopGlowBar.Size = UDim2.new(1, 0, 0, 2)
TopGlowBar.Position = UDim2.new(0, 0, 0, 0)
TopGlowBar.BorderSizePixel = 0
TopGlowBar.ZIndex = 15
TopGlowBar.Parent = MainWindow

local TopGradient = Instance.new("UIGradient")
TopGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(245, 60, 45)),
    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(235, 45, 90)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(200, 35, 130))
}
TopGradient.Parent = TopGlowBar

-- Smooth Gamesense-style animated rainbow hue cycle
local RainbowConn = RunService.RenderStepped:Connect(function()
    local t = (tick() * 0.375) % 1
    local c1 = Color3.fromHSV(t, 0.85, 1)
    local c2 = Color3.fromHSV((t + 0.15) % 1, 0.85, 1)
    local c3 = Color3.fromHSV((t + 0.30) % 1, 0.85, 1)
    TopGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0.0, c3),
        ColorSequenceKeypoint.new(0.5, c2),
        ColorSequenceKeypoint.new(1.0, c1)
    }
end)
table.insert(Connections, RainbowConn)

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                              HEADER BAR                               ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

local HeaderFrame = Instance.new("Frame")
HeaderFrame.Name = "HeaderFrame"
HeaderFrame.Size = UDim2.new(1, 0, 0, 48)
HeaderFrame.Position = UDim2.new(0, 0, 0, 2)
HeaderFrame.BackgroundColor3 = Theme.HeaderBg
HeaderFrame.BorderSizePixel = 0
HeaderFrame.ZIndex = 5
HeaderFrame.Parent = MainWindow

makeDraggable(MainWindow, HeaderFrame)

-- MemeSense Logo
local LogoLabel = Instance.new("TextLabel")
LogoLabel.Name = "Logo"
LogoLabel.Size = UDim2.new(0, 130, 1, 0)
LogoLabel.Position = UDim2.new(0, 20, 0, 0)
LogoLabel.BackgroundTransparency = 1
LogoLabel.RichText = true
LogoLabel.Text = '<font color="#E52535"><b>Meme</b></font><font color="#FFFFFF"><b>Sense</b></font>'
LogoLabel.TextSize = 19
LogoLabel.Font = Theme.FontBold
LogoLabel.TextXAlignment = Enum.TextXAlignment.Left
LogoLabel.Parent = HeaderFrame

-- Center Header CanvasGroup (Tweens transparency on tab switch; contains Master switch & Weapon dropdown)
local HeaderCenterGroup = Instance.new("CanvasGroup")
HeaderCenterGroup.Name = "HeaderCenterGroup"
HeaderCenterGroup.Size = UDim2.new(1, -290, 1, 0)
HeaderCenterGroup.Position = UDim2.new(0, 175, 0, 0)
HeaderCenterGroup.BackgroundTransparency = 1
HeaderCenterGroup.BorderSizePixel = 0
HeaderCenterGroup.GroupTransparency = 0
HeaderCenterGroup.Parent = HeaderFrame

-- Master Switch Toggle inside HeaderCenterGroup
local MasterSwitchFrame = Instance.new("Frame")
MasterSwitchFrame.Name = "MasterSwitch"
MasterSwitchFrame.Size = UDim2.new(0, 135, 0, 26)
MasterSwitchFrame.Position = UDim2.new(0, 5, 0.5, -13)
MasterSwitchFrame.BackgroundTransparency = 1
MasterSwitchFrame.Parent = HeaderCenterGroup

local MasterBox = Instance.new("TextButton")
MasterBox.Name = "Box"
MasterBox.Size = UDim2.new(0, 16, 0, 16)
MasterBox.Position = UDim2.new(0, 0, 0.5, -8)
MasterBox.BackgroundColor3 = Theme.CheckboxOff
MasterBox.BorderSizePixel = 0
MasterBox.AutoButtonColor = false
MasterBox.Text = ""
MasterBox.Parent = MasterSwitchFrame
createCorner(MasterBox, 3)

local MasterCheckLabel = Instance.new("TextLabel")
MasterCheckLabel.Name = "Check"
MasterCheckLabel.Size = UDim2.new(1, 0, 1, 0)
MasterCheckLabel.BackgroundTransparency = 1
MasterCheckLabel.FontFace = GuiIconsFont
MasterCheckLabel.Text = "X"
MasterCheckLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
MasterCheckLabel.TextSize = 13
MasterCheckLabel.TextXAlignment = Enum.TextXAlignment.Center
MasterCheckLabel.TextYAlignment = Enum.TextYAlignment.Center
MasterCheckLabel.Visible = false
MasterCheckLabel.Parent = MasterBox

local MasterLabel = Instance.new("TextButton")
MasterLabel.Name = "Label"
MasterLabel.Size = UDim2.new(0, 86, 1, 0)
MasterLabel.Position = UDim2.new(0, 24, 0, 0)
MasterLabel.BackgroundTransparency = 1
MasterLabel.Text = "Master switch"
MasterLabel.TextColor3 = Theme.TextDim
MasterLabel.TextSize = 13
MasterLabel.Font = Theme.FontMedium
MasterLabel.TextXAlignment = Enum.TextXAlignment.Left
MasterLabel.AutoButtonColor = false
MasterLabel.Parent = MasterSwitchFrame

local masterState = false
local function toggleMaster(newState)
    masterState = (newState ~= nil) and newState or (not masterState)
    if masterState then
        MasterBox.BackgroundColor3 = Theme.CheckboxChecked
        MasterCheckLabel.Visible = true
        MasterLabel.TextColor3 = Theme.TextActive
    else
        MasterBox.BackgroundColor3 = Theme.CheckboxOff
        MasterCheckLabel.Visible = false
        MasterLabel.TextColor3 = Theme.TextDim
    end
end

-- Hover highlight on unchecked box (transparent red)
local function onMasterHoverEnter()
    if not masterState then
        MasterBox.BackgroundColor3 = Theme.CheckboxHoverOff
    end
end
local function onMasterHoverLeave()
    if not masterState then
        MasterBox.BackgroundColor3 = Theme.CheckboxOff
    end
end
MasterBox.MouseEnter:Connect(onMasterHoverEnter)
MasterBox.MouseLeave:Connect(onMasterHoverLeave)
MasterLabel.MouseEnter:Connect(onMasterHoverEnter)
MasterLabel.MouseLeave:Connect(onMasterHoverLeave)

MasterBox.MouseButton1Click:Connect(function() toggleMaster() end)
MasterLabel.MouseButton1Click:Connect(function() toggleMaster() end)

-- Weapon Selection Dropdown in HeaderCenterGroup
local WeaponDropdownFrame = Instance.new("Frame")
WeaponDropdownFrame.Name = "WeaponDropdown"
WeaponDropdownFrame.Size = UDim2.new(0, 115, 0, 26)
WeaponDropdownFrame.Position = UDim2.new(0, 145, 0.5, -13)
WeaponDropdownFrame.BackgroundColor3 = Theme.DropdownBg
WeaponDropdownFrame.Parent = HeaderCenterGroup
createCorner(WeaponDropdownFrame, 3)
createStroke(WeaponDropdownFrame, Theme.ControlBorder, 1)

local WeaponBtn = Instance.new("TextButton")
WeaponBtn.Name = "Button"
WeaponBtn.Size = UDim2.new(1, 0, 1, 0)
WeaponBtn.BackgroundTransparency = 1
WeaponBtn.Text = "  All weapons"
WeaponBtn.TextColor3 = Theme.TextActive
WeaponBtn.TextSize = 12
WeaponBtn.Font = Theme.FontMedium
WeaponBtn.TextXAlignment = Enum.TextXAlignment.Left
WeaponBtn.AutoButtonColor = false
WeaponBtn.Parent = WeaponDropdownFrame

WeaponBtn.MouseEnter:Connect(function()
    WeaponDropdownFrame.BackgroundColor3 = Color3.fromRGB(95, 102, 112)
end)
WeaponBtn.MouseLeave:Connect(function()
    WeaponDropdownFrame.BackgroundColor3 = Theme.DropdownBg
end)

WeaponChevron = Instance.new("TextLabel")
WeaponChevron.Name = "Chevron"
WeaponChevron.Size = UDim2.new(0, 14, 0, 14)
WeaponChevron.Position = UDim2.new(1, -18, 0.5, -7)
WeaponChevron.BackgroundTransparency = 1
WeaponChevron.FontFace = GuiIconsFont
WeaponChevron.Text = "C"
WeaponChevron.TextColor3 = Color3.fromRGB(255, 255, 255)
WeaponChevron.TextSize = 13
WeaponChevron.TextXAlignment = Enum.TextXAlignment.Center
WeaponChevron.TextYAlignment = Enum.TextYAlignment.Center
WeaponChevron.Parent = WeaponDropdownFrame

-- Unified "Bigger Dropdown" Popover (starts from opener top, covering it seamlessly)
local WeaponPopover = Instance.new("Frame")
WeaponPopover.Name = "WeaponPopover"
WeaponPopover.Size = UDim2.new(0, 115, 0, 26 + 78)
WeaponPopover.BackgroundColor3 = Theme.DropdownBg
WeaponPopover.BorderSizePixel = 0
WeaponPopover.Visible = false
WeaponPopover.ZIndex = 120
WeaponPopover.Parent = PopupsLayer
createCorner(WeaponPopover, 3)
createStroke(WeaponPopover, Theme.ControlBorder, 1)

local WeaponPopHeader = Instance.new("Frame")
WeaponPopHeader.Name = "Header"
WeaponPopHeader.Size = UDim2.new(1, 0, 0, 26)
WeaponPopHeader.Position = UDim2.new(0, 0, 0, 0)
WeaponPopHeader.BackgroundTransparency = 1
WeaponPopHeader.Visible = false
WeaponPopHeader.ZIndex = 121
WeaponPopHeader.Parent = WeaponPopover

local WeaponPopHeaderLabel = Instance.new("TextLabel")
WeaponPopHeaderLabel.Name = "Selected"
WeaponPopHeaderLabel.Size = UDim2.new(1, -22, 1, 0)
WeaponPopHeaderLabel.Position = UDim2.new(0, 0, 0, 0)
WeaponPopHeaderLabel.BackgroundTransparency = 1
WeaponPopHeaderLabel.Text = "  All weapons"
WeaponPopHeaderLabel.TextColor3 = Theme.TextActive
WeaponPopHeaderLabel.TextSize = 12
WeaponPopHeaderLabel.Font = Theme.FontMedium
WeaponPopHeaderLabel.TextXAlignment = Enum.TextXAlignment.Left
WeaponPopHeaderLabel.Visible = false
WeaponPopHeaderLabel.ZIndex = 122
WeaponPopHeaderLabel.Parent = WeaponPopHeader

local WeaponPopChevron = Instance.new("TextLabel")
WeaponPopChevron.Name = "Chevron"
WeaponPopChevron.Size = UDim2.new(0, 14, 0, 14)
WeaponPopChevron.Position = UDim2.new(1, -18, 0.5, -7)
WeaponPopChevron.BackgroundTransparency = 1
WeaponPopChevron.FontFace = GuiIconsFont
WeaponPopChevron.Text = "B"
WeaponPopChevron.TextColor3 = Color3.fromRGB(255, 255, 255)
WeaponPopChevron.TextSize = 13
WeaponPopChevron.TextXAlignment = Enum.TextXAlignment.Center
WeaponPopChevron.TextYAlignment = Enum.TextYAlignment.Center
WeaponPopChevron.Visible = false
WeaponPopChevron.ZIndex = 122
WeaponPopChevron.Parent = WeaponPopHeader

local WeaponPopHeaderBtn = Instance.new("TextButton")
WeaponPopHeaderBtn.Name = "CloseTrigger"
WeaponPopHeaderBtn.Size = UDim2.new(1, 0, 1, 0)
WeaponPopHeaderBtn.BackgroundTransparency = 1
WeaponPopHeaderBtn.Text = ""
WeaponPopHeaderBtn.Visible = false
WeaponPopHeaderBtn.ZIndex = 123
WeaponPopHeaderBtn.Parent = WeaponPopHeader

WeaponPopHeaderBtn.MouseButton1Click:Connect(function()
    CloseAllPopups()
end)

local WeaponPopContainer = Instance.new("Frame")
WeaponPopContainer.Name = "ListContainer"
WeaponPopContainer.Size = UDim2.new(1, 0, 1, -26)
WeaponPopContainer.Position = UDim2.new(0, 0, 0, 26)
WeaponPopContainer.BackgroundTransparency = 1
WeaponPopContainer.ZIndex = 121
WeaponPopContainer.Parent = WeaponPopover

table.insert(ActivePopups, {
    Frame = WeaponPopover,
    OnClose = function()
        WeaponChevron.Text = "C"
    end
})

local WeaponPopList = Instance.new("UIListLayout")
WeaponPopList.Padding = UDim.new(0, 1)
WeaponPopList.Parent = WeaponPopContainer

local WeaponPopPad = Instance.new("UIPadding")
WeaponPopPad.PaddingTop = UDim.new(0, 3)
WeaponPopPad.PaddingBottom = UDim.new(0, 3)
WeaponPopPad.PaddingLeft = UDim.new(0, 3)
WeaponPopPad.PaddingRight = UDim.new(0, 3)
WeaponPopPad.Parent = WeaponPopContainer

local SubWeaponDropdownFrame = nil

local weaponOptions = { "Per weapons", "All weapons", "Per groups" }
local chamsOptions = { "Players", "Ragdolls", "Local player" }

local legitbotWeaponMode = "All weapons"
local aimAssistWeaponMode = "All weapons"
local chamsMode = "Players"

local function getActiveHeaderModeInfo()
    local curTab = ActiveTab and ActiveTab.Name or "Legitbot"
    if curTab == "Chams" then
        return chamsOptions, chamsMode, function(opt)
            chamsMode = opt
            WeaponBtn.Text = "  " .. opt
            if SubWeaponDropdownFrame then SubWeaponDropdownFrame.Visible = false end
        end
    elseif curTab == "Aim Assist" then
        return weaponOptions, aimAssistWeaponMode, function(opt)
            aimAssistWeaponMode = opt
            WeaponBtn.Text = "  " .. opt
            if SubWeaponDropdownFrame then
                SubWeaponDropdownFrame.Visible = (opt ~= "All weapons")
            end
        end
    else
        return weaponOptions, legitbotWeaponMode, function(opt)
            legitbotWeaponMode = opt
            WeaponBtn.Text = "  " .. opt
            if SubWeaponDropdownFrame then
                SubWeaponDropdownFrame.Visible = (opt ~= "All weapons")
            end
        end
    end
end

local function buildWeaponOptions()
    for _, child in ipairs(WeaponPopContainer:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local currentOpts, curSelected, onSelect = getActiveHeaderModeInfo()
    for optIdx, opt in ipairs(currentOpts) do
        local OptBtn = Instance.new("TextButton")
        OptBtn.Name = opt
        OptBtn.LayoutOrder = optIdx
        OptBtn.Size = UDim2.new(1, 0, 0, 23)
        local isSel = (opt == curSelected)
        OptBtn.BackgroundColor3 = Theme.DropdownBg
        OptBtn.Text = "  " .. opt
        OptBtn.TextColor3 = isSel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 134, 145)
        OptBtn.TextSize = 12
        OptBtn.Font = isSel and Theme.FontBold or Theme.FontMedium
        OptBtn.TextXAlignment = Enum.TextXAlignment.Left
        OptBtn.AutoButtonColor = false
        OptBtn.ZIndex = 122
        OptBtn.Parent = WeaponPopContainer
        createCorner(OptBtn, 2)

        OptBtn.MouseEnter:Connect(function()
            if opt ~= curSelected then
                OptBtn.TextColor3 = Color3.fromRGB(195, 200, 210)
            end
        end)
        OptBtn.MouseLeave:Connect(function()
            if opt ~= curSelected then
                OptBtn.TextColor3 = Color3.fromRGB(130, 134, 145)
            end
        end)
        OptBtn.MouseButton1Click:Connect(function()
            onSelect(opt)
            WeaponPopHeaderLabel.Text = "  " .. opt
            WeaponPopover.Visible = false
            WeaponChevron.Text = "C"
            if ModalBlocker then ModalBlocker.Visible = false end
            buildWeaponOptions()
        end)
    end
end
buildWeaponOptions()

WeaponBtn.MouseButton1Click:Connect(function()
    local isOpen = WeaponPopover.Visible
    CloseAllPopups()
    if not isOpen then
        buildWeaponOptions()
        local boxPos = getScreenPos(WeaponDropdownFrame)
        local absSize = WeaponDropdownFrame.AbsoluteSize
        local currentOpts = getActiveHeaderModeInfo()
        local optionsH = #currentOpts * 24 + 4
        local totalH = absSize.Y + optionsH
        WeaponPopover.Position = UDim2.new(0, boxPos.X, 0, boxPos.Y)
        WeaponPopover.Size = UDim2.new(0, absSize.X, 0, totalH)
        WeaponPopHeader.Size = UDim2.new(1, 0, 0, absSize.Y)
        WeaponPopHeader.Visible = true
        WeaponPopHeaderLabel.Visible = true
        WeaponPopHeaderLabel.Text = WeaponBtn.Text
        WeaponPopChevron.Visible = true
        WeaponPopChevron.Text = "B"
        WeaponPopHeaderBtn.Visible = true
        WeaponPopContainer.Position = UDim2.new(0, 0, 0, absSize.Y)
        WeaponPopContainer.Size = UDim2.new(1, 0, 1, -absSize.Y)
        WeaponPopover.Visible = true
        WeaponChevron.Text = "B"
        if ModalBlocker then ModalBlocker.Visible = true end
    else
        WeaponChevron.Text = "C"
    end
end)

-- Sub-Weapon / Weapon Class Dropdown (Pistol, Rifle, etc. on Legitbot tab)
SubWeaponDropdownFrame = Instance.new("Frame")
SubWeaponDropdownFrame.Name = "SubWeaponDropdown"
SubWeaponDropdownFrame.Size = UDim2.new(0, 115, 0, 26)
SubWeaponDropdownFrame.Position = UDim2.new(0, 265, 0.5, -13)
SubWeaponDropdownFrame.BackgroundColor3 = Theme.DropdownBg
SubWeaponDropdownFrame.Visible = false
SubWeaponDropdownFrame.Parent = HeaderCenterGroup
createCorner(SubWeaponDropdownFrame, 3)
createStroke(SubWeaponDropdownFrame, Theme.ControlBorder, 1)

local SubWeaponBtn = Instance.new("TextButton")
SubWeaponBtn.Name = "Button"
SubWeaponBtn.Size = UDim2.new(1, 0, 1, 0)
SubWeaponBtn.BackgroundTransparency = 1
SubWeaponBtn.Text = "  Pistol"
SubWeaponBtn.TextColor3 = Theme.TextActive
SubWeaponBtn.TextSize = 12
SubWeaponBtn.Font = Theme.FontMedium
SubWeaponBtn.TextXAlignment = Enum.TextXAlignment.Left
SubWeaponBtn.AutoButtonColor = false
SubWeaponBtn.Parent = SubWeaponDropdownFrame

SubWeaponBtn.MouseEnter:Connect(function()
    SubWeaponDropdownFrame.BackgroundColor3 = Color3.fromRGB(95, 102, 112)
end)
SubWeaponBtn.MouseLeave:Connect(function()
    SubWeaponDropdownFrame.BackgroundColor3 = Theme.DropdownBg
end)

local SubWeaponChevron = Instance.new("TextLabel")
SubWeaponChevron.Name = "Chevron"
SubWeaponChevron.Size = UDim2.new(0, 14, 0, 14)
SubWeaponChevron.Position = UDim2.new(1, -18, 0.5, -7)
SubWeaponChevron.BackgroundTransparency = 1
SubWeaponChevron.FontFace = GuiIconsFont
SubWeaponChevron.Text = "C"
SubWeaponChevron.TextColor3 = Color3.fromRGB(255, 255, 255)
SubWeaponChevron.TextSize = 13
SubWeaponChevron.TextXAlignment = Enum.TextXAlignment.Center
SubWeaponChevron.TextYAlignment = Enum.TextYAlignment.Center
SubWeaponChevron.Parent = SubWeaponDropdownFrame

-- Unified "Bigger Dropdown" Popover (starts from opener top, covering it seamlessly)
local SubWeaponPopover = Instance.new("Frame")
SubWeaponPopover.Name = "SubWeaponPopover"
SubWeaponPopover.Size = UDim2.new(0, 115, 0, 26 + 138)
SubWeaponPopover.BackgroundColor3 = Theme.DropdownBg
SubWeaponPopover.BorderSizePixel = 0
SubWeaponPopover.Visible = false
SubWeaponPopover.ZIndex = 120
SubWeaponPopover.Parent = PopupsLayer
createCorner(SubWeaponPopover, 3)
createStroke(SubWeaponPopover, Theme.ControlBorder, 1)

local SubWeaponPopHeader = Instance.new("Frame")
SubWeaponPopHeader.Name = "Header"
SubWeaponPopHeader.Size = UDim2.new(1, 0, 0, 26)
SubWeaponPopHeader.Position = UDim2.new(0, 0, 0, 0)
SubWeaponPopHeader.BackgroundTransparency = 1
SubWeaponPopHeader.Visible = false
SubWeaponPopHeader.ZIndex = 121
SubWeaponPopHeader.Parent = SubWeaponPopover

local SubWeaponPopHeaderLabel = Instance.new("TextLabel")
SubWeaponPopHeaderLabel.Name = "Selected"
SubWeaponPopHeaderLabel.Size = UDim2.new(1, -22, 1, 0)
SubWeaponPopHeaderLabel.Position = UDim2.new(0, 0, 0, 0)
SubWeaponPopHeaderLabel.BackgroundTransparency = 1
SubWeaponPopHeaderLabel.Text = "  Pistol"
SubWeaponPopHeaderLabel.TextColor3 = Theme.TextActive
SubWeaponPopHeaderLabel.TextSize = 12
SubWeaponPopHeaderLabel.Font = Theme.FontMedium
SubWeaponPopHeaderLabel.TextXAlignment = Enum.TextXAlignment.Left
SubWeaponPopHeaderLabel.Visible = false
SubWeaponPopHeaderLabel.ZIndex = 122
SubWeaponPopHeaderLabel.Parent = SubWeaponPopHeader

local SubWeaponPopChevron = Instance.new("TextLabel")
SubWeaponPopChevron.Name = "Chevron"
SubWeaponPopChevron.Size = UDim2.new(0, 14, 0, 14)
SubWeaponPopChevron.Position = UDim2.new(1, -18, 0.5, -7)
SubWeaponPopChevron.BackgroundTransparency = 1
SubWeaponPopChevron.FontFace = GuiIconsFont
SubWeaponPopChevron.Text = "B"
SubWeaponPopChevron.TextColor3 = Color3.fromRGB(255, 255, 255)
SubWeaponPopChevron.TextSize = 13
SubWeaponPopChevron.TextXAlignment = Enum.TextXAlignment.Center
SubWeaponPopChevron.TextYAlignment = Enum.TextYAlignment.Center
SubWeaponPopChevron.Visible = false
SubWeaponPopChevron.ZIndex = 122
SubWeaponPopChevron.Parent = SubWeaponPopHeader

local SubWeaponPopHeaderBtn = Instance.new("TextButton")
SubWeaponPopHeaderBtn.Name = "CloseTrigger"
SubWeaponPopHeaderBtn.Size = UDim2.new(1, 0, 1, 0)
SubWeaponPopHeaderBtn.BackgroundTransparency = 1
SubWeaponPopHeaderBtn.Text = ""
SubWeaponPopHeaderBtn.Visible = false
SubWeaponPopHeaderBtn.ZIndex = 123
SubWeaponPopHeaderBtn.Parent = SubWeaponPopHeader

SubWeaponPopHeaderBtn.MouseButton1Click:Connect(function()
    CloseAllPopups()
end)

local SubWeaponPopContainer = Instance.new("Frame")
SubWeaponPopContainer.Name = "ListContainer"
SubWeaponPopContainer.Size = UDim2.new(1, 0, 1, -26)
SubWeaponPopContainer.Position = UDim2.new(0, 0, 0, 26)
SubWeaponPopContainer.BackgroundTransparency = 1
SubWeaponPopContainer.ZIndex = 121
SubWeaponPopContainer.Parent = SubWeaponPopover

table.insert(ActivePopups, {
    Frame = SubWeaponPopover,
    OnClose = function()
        SubWeaponChevron.Text = "C"
    end
})

local SubWeaponPopList = Instance.new("UIListLayout")
SubWeaponPopList.Padding = UDim.new(0, 1)
SubWeaponPopList.Parent = SubWeaponPopContainer

local SubWeaponPopPad = Instance.new("UIPadding")
SubWeaponPopPad.PaddingTop = UDim.new(0, 3)
SubWeaponPopPad.PaddingBottom = UDim.new(0, 3)
SubWeaponPopPad.PaddingLeft = UDim.new(0, 3)
SubWeaponPopPad.PaddingRight = UDim.new(0, 3)
SubWeaponPopPad.Parent = SubWeaponPopContainer

local subWeaponOptions = { "Pistol", "Rifle", "Sniper", "SMG", "Shotgun", "Machine gun" }
local selectedSubWeapon = "Pistol"

local function buildSubWeaponOptions()
    for _, child in ipairs(SubWeaponPopContainer:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, opt in ipairs(subWeaponOptions) do
        local OptBtn = Instance.new("TextButton")
        OptBtn.Name = opt
        OptBtn.Size = UDim2.new(1, 0, 0, 22)
        local isSel = (opt == selectedSubWeapon)
        OptBtn.BackgroundColor3 = Theme.DropdownBg
        OptBtn.Text = "  " .. opt
        OptBtn.TextColor3 = isSel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 134, 145)
        OptBtn.TextSize = 12
        OptBtn.Font = isSel and Theme.FontBold or Theme.FontMedium
        OptBtn.TextXAlignment = Enum.TextXAlignment.Left
        OptBtn.AutoButtonColor = false
        OptBtn.ZIndex = 122
        OptBtn.Parent = SubWeaponPopContainer
        createCorner(OptBtn, 2)

        OptBtn.MouseEnter:Connect(function()
            if opt ~= selectedSubWeapon then
                OptBtn.TextColor3 = Color3.fromRGB(195, 200, 210)
            end
        end)
        OptBtn.MouseLeave:Connect(function()
            if opt ~= selectedSubWeapon then
                OptBtn.TextColor3 = Color3.fromRGB(130, 134, 145)
            end
        end)
        OptBtn.MouseButton1Click:Connect(function()
            selectedSubWeapon = opt
            SubWeaponBtn.Text = "  " .. opt
            SubWeaponPopHeaderLabel.Text = "  " .. opt
            SubWeaponPopover.Visible = false
            SubWeaponChevron.Text = "C"
            if ModalBlocker then ModalBlocker.Visible = false end
            buildSubWeaponOptions()
        end)
    end
end
buildSubWeaponOptions()

SubWeaponBtn.MouseButton1Click:Connect(function()
    local isOpen = SubWeaponPopover.Visible
    CloseAllPopups()
    if not isOpen then
        local boxPos = getScreenPos(SubWeaponDropdownFrame)
        local absSize = SubWeaponDropdownFrame.AbsoluteSize
        local optionsH = 138
        local totalH = absSize.Y + optionsH
        SubWeaponPopover.Position = UDim2.new(0, boxPos.X, 0, boxPos.Y)
        SubWeaponPopover.Size = UDim2.new(0, absSize.X, 0, totalH)
        SubWeaponPopHeader.Size = UDim2.new(1, 0, 0, absSize.Y)
        SubWeaponPopHeader.Visible = true
        SubWeaponPopHeaderLabel.Visible = true
        SubWeaponPopHeaderLabel.Text = SubWeaponBtn.Text
        SubWeaponPopChevron.Visible = true
        SubWeaponPopChevron.Text = "B"
        SubWeaponPopHeaderBtn.Visible = true
        SubWeaponPopContainer.Position = UDim2.new(0, 0, 0, absSize.Y)
        SubWeaponPopContainer.Size = UDim2.new(1, 0, 1, -absSize.Y)
        SubWeaponPopover.Visible = true
        SubWeaponChevron.Text = "B"
        if ModalBlocker then ModalBlocker.Visible = true end
    else
        SubWeaponChevron.Text = "C"
    end
end)



-- Save Config Button (Top Right, using custom icon "3")
local SaveBtnFrame = Instance.new("Frame")
SaveBtnFrame.Name = "SaveBtn"
SaveBtnFrame.Size = UDim2.new(0, 78, 0, 26)
SaveBtnFrame.Position = UDim2.new(1, -98, 0.5, -13)
SaveBtnFrame.BackgroundColor3 = Theme.DropdownBg
SaveBtnFrame.Parent = HeaderFrame
createCorner(SaveBtnFrame, 3)
createStroke(SaveBtnFrame, Theme.ControlBorder, 1)

local SaveIcon = Instance.new("TextLabel")
SaveIcon.Name = "Icon"
SaveIcon.Size = UDim2.new(0, 16, 0, 16)
SaveIcon.Position = UDim2.new(0, 8, 0.5, -8)
SaveIcon.BackgroundTransparency = 1
SaveIcon.FontFace = GuiIconsFont
SaveIcon.Text = "3"
SaveIcon.TextSize = 15
SaveIcon.TextColor3 = Theme.TextActive
SaveIcon.TextXAlignment = Enum.TextXAlignment.Center
SaveIcon.TextYAlignment = Enum.TextYAlignment.Center
SaveIcon.ZIndex = 3
SaveIcon.Parent = SaveBtnFrame

local SaveBtn = Instance.new("TextButton")
SaveBtn.Name = "Button"
SaveBtn.Size = UDim2.new(1, 0, 1, 0)
SaveBtn.Position = UDim2.new(0, 0, 0, 0)
SaveBtn.BackgroundTransparency = 1
SaveBtn.Text = "       Save"
SaveBtn.TextColor3 = Theme.TextActive
SaveBtn.TextSize = 12
SaveBtn.Font = Theme.FontMedium
SaveBtn.TextXAlignment = Enum.TextXAlignment.Center
SaveBtn.AutoButtonColor = false
SaveBtn.ZIndex = 2
SaveBtn.Parent = SaveBtnFrame

SaveBtn.MouseEnter:Connect(function()
    SaveBtnFrame.BackgroundColor3 = Color3.fromRGB(95, 102, 112)
end)
SaveBtn.MouseLeave:Connect(function()
    SaveBtnFrame.BackgroundColor3 = Theme.DropdownBg
end)
SaveBtn.MouseButton1Click:Connect(function()
    SaveBtn.Text = "       Saved!"
    task.delay(1, function()
        SaveBtn.Text = "       Save"
    end)
end)

local SidebarWidth = 145

-- Header divider line (Stops before going above tabs, starts after sidebar, thicker 2px gray line)
local HeaderDivider = Instance.new("Frame")
HeaderDivider.Name = "Divider"
HeaderDivider.Size = UDim2.new(1, -SidebarWidth, 0, 2)
HeaderDivider.Position = UDim2.new(0, SidebarWidth, 1, -2)
HeaderDivider.BackgroundColor3 = Color3.fromRGB(38, 40, 48)
HeaderDivider.BorderSizePixel = 0
HeaderDivider.Parent = HeaderFrame

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                           SIDEBAR NAVIGATION                              ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

-- Sidebar Scrollable Container
local SidebarFrame = Instance.new("ScrollingFrame")
SidebarFrame.Name = "Sidebar"
SidebarFrame.Size = UDim2.new(0, SidebarWidth, 1, -50)
SidebarFrame.Position = UDim2.new(0, 0, 0, 50)
SidebarFrame.BackgroundColor3 = Theme.SidebarBg
SidebarFrame.BorderSizePixel = 0
SidebarFrame.ScrollBarThickness = 0
SidebarFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
SidebarFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
SidebarFrame.Parent = MainWindow

local SidebarList = Instance.new("UIListLayout")
SidebarList.Name = "List"
SidebarList.SortOrder = Enum.SortOrder.LayoutOrder  -- STRICT LAYOUT ORDER TO PREVENT ALPHABETICAL SCRAMBLING
SidebarList.Padding = UDim.new(0, 2)
SidebarList.HorizontalAlignment = Enum.HorizontalAlignment.Center
SidebarList.Parent = SidebarFrame

local SidebarPadding = Instance.new("UIPadding")
SidebarPadding.PaddingTop = UDim.new(0, 6)
SidebarPadding.PaddingBottom = UDim.new(0, 6)
SidebarPadding.PaddingLeft = UDim.new(0, 5)
SidebarPadding.PaddingRight = UDim.new(0, 5)
SidebarPadding.Parent = SidebarFrame

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                           CONTENT CONTAINER                               ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -SidebarWidth, 1, -50)
ContentArea.Position = UDim2.new(0, SidebarWidth, 0, 50)
ContentArea.BackgroundTransparency = 1
ContentArea.BorderSizePixel = 0
ContentArea.Parent = MainWindow

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                            TAB MANAGEMENT                                 ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

local Tabs = {}
ActiveTab = nil
local isTabSwitching = false

local function SelectTab(tabName)
    if ActiveTab and ActiveTab.Name == tabName then return end
    if isTabSwitching then return end
    CloseAllPopups()

    local prevTab = ActiveTab
    local newTab = Tabs[tabName]
    if not newTab then return end

    -- Immediate tab button state update
    for name, tabData in pairs(Tabs) do
        local isSelected = (name == tabName)
        if isSelected then
            tabData.Indicator.Visible = true
            tabData.Button.BackgroundColor3 = Color3.fromRGB(24, 25, 31)
            tabData.Icon.TextColor3 = Theme.Accent
            tabData.Label.TextColor3 = Color3.fromRGB(255, 255, 255)
            ActiveTab = tabData
        else
            tabData.Indicator.Visible = false
            tabData.Button.BackgroundColor3 = Color3.fromRGB(12, 13, 15)
            tabData.Icon.TextColor3 = Color3.fromRGB(255, 255, 255)
            tabData.Label.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end

    local function applyHeaderConfig()
        if tabName == "Players" or tabName == "Visuals" or tabName == "World" or tabName == "View" or tabName == "Miscellaneous" or tabName == "Inventory" or tabName == "Configs" or tabName == "Indicators" then
            HeaderCenterGroup.Visible = false
        else
            HeaderCenterGroup.Visible = true
            MasterSwitchFrame.Visible = true
            if tabName == "Aim Assist" then
                WeaponDropdownFrame.Visible = true
                WeaponBtn.Text = "  " .. aimAssistWeaponMode
                SubWeaponDropdownFrame.Visible = (aimAssistWeaponMode ~= "All weapons")
                buildWeaponOptions()
            elseif tabName == "Legitbot" then
                WeaponDropdownFrame.Visible = true
                WeaponBtn.Text = "  " .. legitbotWeaponMode
                SubWeaponDropdownFrame.Visible = (legitbotWeaponMode ~= "All weapons")
                buildWeaponOptions()
            elseif tabName == "Chams" then
                WeaponDropdownFrame.Visible = true
                WeaponBtn.Text = "  " .. chamsMode
                SubWeaponDropdownFrame.Visible = false
                buildWeaponOptions()
            elseif tabName == "Items" then
                WeaponDropdownFrame.Visible = false
                SubWeaponDropdownFrame.Visible = false
            else
                WeaponDropdownFrame.Visible = false
                SubWeaponDropdownFrame.Visible = false
            end
        end
    end

    if not prevTab then
        for name, tabData in pairs(Tabs) do
            tabData.Content.Visible = (name == tabName)
            if tabData.Content:IsA("CanvasGroup") then
                tabData.Content.GroupTransparency = 0
            end
        end
        applyHeaderConfig()
        HeaderCenterGroup.GroupTransparency = 0
        return
    end

    isTabSwitching = true
    local tweenInfoOut = TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tweenInfoIn = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    if prevTab and prevTab.Content and prevTab.Content:IsA("CanvasGroup") then
        TweenService:Create(prevTab.Content, tweenInfoOut, { GroupTransparency = 1 }):Play()
    end
    if HeaderCenterGroup.Visible then
        TweenService:Create(HeaderCenterGroup, tweenInfoOut, { GroupTransparency = 1 }):Play()
    end

    task.delay(0.09, function()
        for name, tabData in pairs(Tabs) do
            if name ~= tabName then
                tabData.Content.Visible = false
                if tabData.Content:IsA("CanvasGroup") then
                    tabData.Content.GroupTransparency = 1
                end
            end
        end

        applyHeaderConfig()
        if HeaderCenterGroup.Visible then
            HeaderCenterGroup.GroupTransparency = 1
            TweenService:Create(HeaderCenterGroup, tweenInfoIn, { GroupTransparency = 0 }):Play()
        end

        newTab.Content.Visible = true
        if newTab.Content:IsA("CanvasGroup") then
            newTab.Content.GroupTransparency = 1
            local inTween = TweenService:Create(newTab.Content, tweenInfoIn, { GroupTransparency = 0 })
            inTween:Play()
            inTween.Completed:Connect(function()
                isTabSwitching = false
            end)
        else
            isTabSwitching = false
        end
    end)
end

local function CreateTab(name, orderIndex)
    local TabButton = Instance.new("TextButton")
    TabButton.Name = name .. "_Tab"
    TabButton.Size = UDim2.new(1, 0, 0, 30)
    TabButton.BackgroundColor3 = Color3.fromRGB(12, 13, 15)
    TabButton.BorderSizePixel = 0
    TabButton.AutoButtonColor = false
    TabButton.LayoutOrder = orderIndex
    TabButton.Text = ""
    TabButton.Parent = SidebarFrame
    createCorner(TabButton, 3)

    -- Left red active indicator bar
    local Indicator = Instance.new("Frame")
    Indicator.Name = "Indicator"
    Indicator.Size = UDim2.new(0, 3, 0, 16)
    Indicator.Position = UDim2.new(0, 2, 0.5, -8)
    Indicator.BackgroundColor3 = Theme.Accent
    Indicator.BorderSizePixel = 0
    Indicator.Visible = false
    Indicator.Parent = TabButton
    createCorner(Indicator, 2)

    -- Custom TTF Font Icon Label using gui-icons.ttf
    local Icon = Instance.new("TextLabel")
    Icon.Name = "Icon"
    Icon.Size = UDim2.new(0, 18, 0, 18)
    Icon.Position = UDim2.new(0, 10, 0.5, -9)
    Icon.BackgroundTransparency = 1
    Icon.FontFace = GuiIconsFont
    Icon.Text = TabIconGlyphs[name] or ""
    Icon.TextSize = 16
    Icon.TextColor3 = Color3.fromRGB(255, 255, 255)
    Icon.TextXAlignment = Enum.TextXAlignment.Center
    Icon.TextYAlignment = Enum.TextYAlignment.Center
    Icon.Parent = TabButton

    -- Label
    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Size = UDim2.new(1, -34, 1, 0)
    Label.Position = UDim2.new(0, 34, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextSize = 13
    Label.Font = Theme.FontBold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = TabButton

    -- Hover effect: shows indicator bar, red icon, and highlighted background
    TabButton.MouseEnter:Connect(function()
        if not ActiveTab or ActiveTab.Name ~= name then
            Indicator.Visible = true
            TabButton.BackgroundColor3 = Color3.fromRGB(20, 21, 27)
            Icon.TextColor3 = Theme.Accent
            Label.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end)
    TabButton.MouseLeave:Connect(function()
        if not ActiveTab or ActiveTab.Name ~= name then
            Indicator.Visible = false
            TabButton.BackgroundColor3 = Color3.fromRGB(12, 13, 15)
            Icon.TextColor3 = Color3.fromRGB(255, 255, 255)
            Label.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end)
    TabButton.MouseButton1Click:Connect(function()
        SelectTab(name)
    end)

    -- Tab Content Container (CanvasGroup for smooth transparency transitions between tabs)
    local Content = Instance.new("CanvasGroup")
    Content.Name = name .. "_Content"
    Content.Size = UDim2.new(1, 0, 1, 0)
    Content.BackgroundTransparency = 1
    Content.BorderSizePixel = 0
    Content.GroupTransparency = 0
    Content.Visible = false
    Content.Parent = ContentArea

    -- Left Column Frame (Zero scrollbar thickness matching MemeSense)
    local LeftCol = Instance.new("ScrollingFrame")
    LeftCol.Name = "LeftColumn"
    LeftCol.Size = UDim2.new(0.5, -12, 1, -12)
    LeftCol.Position = UDim2.new(0, 14, 0, 8)
    LeftCol.BackgroundTransparency = 1
    LeftCol.BorderSizePixel = 0
    LeftCol.ScrollBarThickness = 0
    LeftCol.CanvasSize = UDim2.new(0, 0, 0, 0)
    LeftCol.AutomaticCanvasSize = Enum.AutomaticSize.Y
    LeftCol.Parent = Content

    local LeftColLayout = Instance.new("UIListLayout")
    LeftColLayout.SortOrder = Enum.SortOrder.LayoutOrder
    LeftColLayout.Padding = UDim.new(0, 4)
    LeftColLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    LeftColLayout.Parent = LeftCol

    -- Right Column Frame (Zero scrollbar thickness matching MemeSense)
    local RightCol = Instance.new("ScrollingFrame")
    RightCol.Name = "RightColumn"
    RightCol.Size = UDim2.new(0.5, -12, 1, -12)
    RightCol.Position = UDim2.new(0.5, 4, 0, 8)
    RightCol.BackgroundTransparency = 1
    RightCol.BorderSizePixel = 0
    RightCol.ScrollBarThickness = 0
    RightCol.CanvasSize = UDim2.new(0, 0, 0, 0)
    RightCol.AutomaticCanvasSize = Enum.AutomaticSize.Y
    RightCol.Parent = Content

    local RightColLayout = Instance.new("UIListLayout")
    RightColLayout.SortOrder = Enum.SortOrder.LayoutOrder
    RightColLayout.Padding = UDim.new(0, 4)
    RightColLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    RightColLayout.Parent = RightCol

    local tabObj = {
        Name = name,
        Button = TabButton,
        Indicator = Indicator,
        Icon = Icon,
        Label = Label,
        Content = Content,
        LeftColumn = LeftCol,
        RightColumn = RightCol
    }

    Tabs[name] = tabObj
    return tabObj
end

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                        CONTROL BUILDER SYSTEM                             ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

local Controls = {}

--[[
    ═══════════════════════════════════════════════════════════════════════════
                             INTERACTIVE COLOR PICKER
                           (1:1 Matching Screenshot)
    ═══════════════════════════════════════════════════════════════════════════
]]

do
ColorPickerModal = Instance.new("Frame")
ColorPickerModal.Name = "MemeSense_ColorPicker"
ColorPickerModal.Size = UDim2.new(0, 316, 0, 266)
ColorPickerModal.BackgroundColor3 = Color3.fromRGB(19, 20, 24)
ColorPickerModal.BorderSizePixel = 0
ColorPickerModal.Visible = false
ColorPickerModal.ZIndex = 650
ColorPickerModal.Parent = PopupsLayer
createCorner(ColorPickerModal, 2)

local ColorPickerDismiss = Instance.new("TextButton")
ColorPickerDismiss.Name = "ColorPickerDismiss"
ColorPickerDismiss.Size = UDim2.new(1, 0, 1, 0)
ColorPickerDismiss.Position = UDim2.new(0, 0, 0, 0)
ColorPickerDismiss.BackgroundTransparency = 1
ColorPickerDismiss.Text = ""
ColorPickerDismiss.AutoButtonColor = false
ColorPickerDismiss.ZIndex = 508
ColorPickerDismiss.Visible = false
ColorPickerDismiss.Parent = PopupsLayer

ColorPickerDismiss.MouseButton1Click:Connect(function()
    ColorPickerModal.Visible = false
    ColorPickerDismiss.Visible = false
end)

table.insert(ActivePopups, {
    Frame = ColorPickerModal,
    OnClose = function()
        ColorPickerDismiss.Visible = false
    end
})

-- Saturation / Value (SV) Box
local SVBox = Instance.new("Frame")
SVBox.Name = "SVBox"
SVBox.Size = UDim2.new(0, 216, 0, 210)
SVBox.Position = UDim2.new(0, 10, 0, 10)
SVBox.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
SVBox.BorderSizePixel = 0
SVBox.ClipsDescendants = true
SVBox.ZIndex = 511
SVBox.Parent = ColorPickerModal
createCorner(SVBox, 2)
createStroke(SVBox, Color3.fromRGB(35, 36, 42), 1)

local WhiteGrad = Instance.new("Frame")
WhiteGrad.Name = "WhiteGradient"
WhiteGrad.Size = UDim2.new(1, 0, 1, 0)
WhiteGrad.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
WhiteGrad.BorderSizePixel = 0
WhiteGrad.ZIndex = 512
WhiteGrad.Parent = SVBox
local WhiteGradUi = Instance.new("UIGradient")
WhiteGradUi.Transparency = NumberSequence.new{
    NumberSequenceKeypoint.new(0, 0),
    NumberSequenceKeypoint.new(1, 1)
}
WhiteGradUi.Rotation = 0
WhiteGradUi.Parent = WhiteGrad

local BlackGrad = Instance.new("Frame")
BlackGrad.Name = "BlackGradient"
BlackGrad.Size = UDim2.new(1, 0, 1, 0)
BlackGrad.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
BlackGrad.BorderSizePixel = 0
BlackGrad.ZIndex = 513
BlackGrad.Parent = SVBox
local BlackGradUi = Instance.new("UIGradient")
BlackGradUi.Transparency = NumberSequence.new{
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(1, 0)
}
BlackGradUi.Rotation = 90
BlackGradUi.Parent = BlackGrad

local SVHandle = Instance.new("Frame")
SVHandle.Name = "SVHandle"
SVHandle.Size = UDim2.new(0, 12, 0, 12)
SVHandle.AnchorPoint = Vector2.new(0.5, 0.5)
SVHandle.Position = UDim2.new(0, 0, 0, 0)
SVHandle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SVHandle.BorderSizePixel = 0
SVHandle.ZIndex = 515
SVHandle.Parent = SVBox
createCorner(SVHandle, 6)
createStroke(SVHandle, Color3.fromRGB(255, 255, 255), 1.5)

-- Vertical Hue Rainbow Slider (Middle)
local HueBar = Instance.new("Frame")
HueBar.Name = "HueBar"
HueBar.Size = UDim2.new(0, 28, 0, 210)
HueBar.Position = UDim2.new(0, 236, 0, 10)
HueBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
HueBar.BorderSizePixel = 0
HueBar.ClipsDescendants = false
HueBar.ZIndex = 511
HueBar.Parent = ColorPickerModal
createCorner(HueBar, 2)
createStroke(HueBar, Color3.fromRGB(35, 36, 42), 1)

local HueGrad = Instance.new("UIGradient")
HueGrad.Rotation = 90
HueGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
    ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
    ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0))
}
HueGrad.Parent = HueBar

local HueLeftPointer = Instance.new("TextLabel")
HueLeftPointer.Name = "LeftPointer"
HueLeftPointer.Size = UDim2.new(0, 7, 0, 10)
HueLeftPointer.Position = UDim2.new(0, -6, 0, -5)
HueLeftPointer.BackgroundTransparency = 1
HueLeftPointer.Text = "►"
HueLeftPointer.TextColor3 = Color3.fromRGB(255, 255, 255)
HueLeftPointer.TextSize = 9
HueLeftPointer.ZIndex = 516
HueLeftPointer.Parent = HueBar

local HueRightPointer = Instance.new("TextLabel")
HueRightPointer.Name = "RightPointer"
HueRightPointer.Size = UDim2.new(0, 7, 0, 10)
HueRightPointer.Position = UDim2.new(1, -1, 0, -5)
HueRightPointer.BackgroundTransparency = 1
HueRightPointer.Text = "◄"
HueRightPointer.TextColor3 = Color3.fromRGB(255, 255, 255)
HueRightPointer.TextSize = 9
HueRightPointer.ZIndex = 516
HueRightPointer.Parent = HueBar

-- Vertical Alpha Slider with Checkered Pattern (Right)
local AlphaBar = Instance.new("Frame")
AlphaBar.Name = "AlphaBar"
AlphaBar.Size = UDim2.new(0, 28, 0, 210)
AlphaBar.Position = UDim2.new(0, 274, 0, 10)
AlphaBar.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
AlphaBar.BorderSizePixel = 0
AlphaBar.ClipsDescendants = false
AlphaBar.ZIndex = 511
AlphaBar.Parent = ColorPickerModal
createCorner(AlphaBar, 2)
createStroke(AlphaBar, Color3.fromRGB(35, 36, 42), 1)

local AlphaCheckers = Instance.new("Frame")
AlphaCheckers.Name = "Checkers"
AlphaCheckers.Size = UDim2.new(1, 0, 1, 0)
AlphaCheckers.BackgroundColor3 = Color3.fromRGB(160, 160, 160)
AlphaCheckers.BorderSizePixel = 0
AlphaCheckers.ClipsDescendants = true
AlphaCheckers.ZIndex = 512
AlphaCheckers.Parent = AlphaBar
createCorner(AlphaCheckers, 2)

for row = 0, 34 do
    for col = 0, 4 do
        if (row + col) % 2 == 0 then
            local sq = Instance.new("Frame")
            sq.Size = UDim2.new(0, 6, 0, 6)
            sq.Position = UDim2.new(0, col * 6, 0, row * 6)
            sq.BackgroundColor3 = Color3.fromRGB(215, 215, 215)
            sq.BorderSizePixel = 0
            sq.ZIndex = 512
            sq.Parent = AlphaCheckers
        end
    end
end

local AlphaColorOverlay = Instance.new("Frame")
AlphaColorOverlay.Name = "ColorOverlay"
AlphaColorOverlay.Size = UDim2.new(1, 0, 1, 0)
AlphaColorOverlay.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
AlphaColorOverlay.BorderSizePixel = 0
AlphaColorOverlay.ZIndex = 513
AlphaColorOverlay.Parent = AlphaBar
createCorner(AlphaColorOverlay, 2)

local AlphaGrad = Instance.new("UIGradient")
AlphaGrad.Rotation = 90
AlphaGrad.Transparency = NumberSequence.new{
    NumberSequenceKeypoint.new(0.00, 0),
    NumberSequenceKeypoint.new(1.00, 1)
}
AlphaGrad.Parent = AlphaColorOverlay

local AlphaLeftPointer = Instance.new("TextLabel")
AlphaLeftPointer.Name = "LeftPointer"
AlphaLeftPointer.Size = UDim2.new(0, 7, 0, 10)
AlphaLeftPointer.Position = UDim2.new(0, -6, 0, -5)
AlphaLeftPointer.BackgroundTransparency = 1
AlphaLeftPointer.Text = "►"
AlphaLeftPointer.TextColor3 = Color3.fromRGB(255, 255, 255)
AlphaLeftPointer.TextSize = 9
AlphaLeftPointer.ZIndex = 516
AlphaLeftPointer.Parent = AlphaBar

local AlphaRightPointer = Instance.new("TextLabel")
AlphaRightPointer.Name = "RightPointer"
AlphaRightPointer.Size = UDim2.new(0, 7, 0, 10)
AlphaRightPointer.Position = UDim2.new(1, -1, 0, -5)
AlphaRightPointer.BackgroundTransparency = 1
AlphaRightPointer.Text = "◄"
AlphaRightPointer.TextColor3 = Color3.fromRGB(255, 255, 255)
AlphaRightPointer.TextSize = 9
AlphaRightPointer.ZIndex = 516
AlphaRightPointer.Parent = AlphaBar

-- Bottom Row: Hex Code Input Box (Left) & Preview Box (Right)
local HexFrame = Instance.new("Frame")
HexFrame.Name = "HexFrame"
HexFrame.Position = UDim2.new(0, 10, 0, 228)
HexFrame.Size = UDim2.new(0, 254, 0, 28)
HexFrame.BackgroundColor3 = Color3.fromRGB(26, 28, 33)
HexFrame.BorderSizePixel = 0
HexFrame.ZIndex = 511
HexFrame.Parent = ColorPickerModal
createCorner(HexFrame, 2)
createStroke(HexFrame, Color3.fromRGB(35, 36, 42), 1)

local HexInput = Instance.new("TextBox")
HexInput.Name = "HexInput"
HexInput.Size = UDim2.new(1, -12, 1, 0)
HexInput.Position = UDim2.new(0, 8, 0, 0)
HexInput.BackgroundTransparency = 1
HexInput.Text = "#FFD19D55"
HexInput.TextColor3 = Color3.fromRGB(255, 255, 255)
HexInput.TextSize = 12
HexInput.Font = Theme.FontBold
HexInput.TextXAlignment = Enum.TextXAlignment.Left
HexInput.ClearTextOnFocus = false
HexInput.ZIndex = 512
HexInput.Parent = HexFrame

local HexRedLine = Instance.new("Frame")
HexRedLine.Name = "RedLine"
HexRedLine.Size = UDim2.new(1, 0, 0, 2)
HexRedLine.Position = UDim2.new(0, 0, 1, -2)
HexRedLine.BackgroundColor3 = Theme.Accent
HexRedLine.BorderSizePixel = 0
HexRedLine.Visible = false
HexRedLine.ZIndex = 515
HexRedLine.Parent = HexFrame
createCorner(HexRedLine, 2)

HexInput.Focused:Connect(function()
    HexRedLine.Visible = true
end)
HexInput.FocusLost:Connect(function()
    HexRedLine.Visible = false
end)

-- Preview Frame: Split 50/50: Solid Full Color on Left, Transparent Alpha over Checkers on Right
local PreviewFrame = Instance.new("Frame")
PreviewFrame.Name = "PreviewFrame"
PreviewFrame.Position = UDim2.new(0, 274, 0, 228)
PreviewFrame.Size = UDim2.new(0, 28, 0, 28)
PreviewFrame.BackgroundColor3 = Color3.fromRGB(160, 160, 160)
PreviewFrame.BorderSizePixel = 0
PreviewFrame.ClipsDescendants = true
PreviewFrame.ZIndex = 511
PreviewFrame.Parent = ColorPickerModal
createCorner(PreviewFrame, 2)
createStroke(PreviewFrame, Color3.fromRGB(35, 36, 42), 1)

-- Left half: Solid full color
local PreviewSolid = Instance.new("Frame")
PreviewSolid.Name = "PreviewSolid"
PreviewSolid.Size = UDim2.new(0.5, 0, 1, 0)
PreviewSolid.Position = UDim2.new(0, 0, 0, 0)
PreviewSolid.BackgroundColor3 = Color3.fromRGB(255, 209, 157)
PreviewSolid.BackgroundTransparency = 0
PreviewSolid.BorderSizePixel = 0
PreviewSolid.ZIndex = 513
PreviewSolid.Parent = PreviewFrame

-- Right half: Checkered alpha pattern with overlay
local PreviewAlphaContainer = Instance.new("Frame")
PreviewAlphaContainer.Name = "PreviewAlphaContainer"
PreviewAlphaContainer.Size = UDim2.new(0.5, 0, 1, 0)
PreviewAlphaContainer.Position = UDim2.new(0.5, 0, 0, 0)
PreviewAlphaContainer.BackgroundColor3 = Color3.fromRGB(160, 160, 160)
PreviewAlphaContainer.BorderSizePixel = 0
PreviewAlphaContainer.ClipsDescendants = true
PreviewAlphaContainer.ZIndex = 512
PreviewAlphaContainer.Parent = PreviewFrame

for row = 0, 5 do
    for col = 0, 2 do
        if (row + col) % 2 == 0 then
            local psq = Instance.new("Frame")
            psq.Size = UDim2.new(0, 5, 0, 5)
            psq.Position = UDim2.new(0, col * 5, 0, row * 5)
            psq.BackgroundColor3 = Color3.fromRGB(215, 215, 215)
            psq.BorderSizePixel = 0
            psq.ZIndex = 512
            psq.Parent = PreviewAlphaContainer
        end
    end
end

local PreviewAlphaOverlay = Instance.new("Frame")
PreviewAlphaOverlay.Name = "PreviewAlphaOverlay"
PreviewAlphaOverlay.Size = UDim2.new(1, 0, 1, 0)
PreviewAlphaOverlay.Position = UDim2.new(0, 0, 0, 0)
PreviewAlphaOverlay.BackgroundColor3 = Color3.fromRGB(255, 209, 157)
PreviewAlphaOverlay.BorderSizePixel = 0
PreviewAlphaOverlay.ZIndex = 514
PreviewAlphaOverlay.Parent = PreviewAlphaContainer

local curH = 0.08
local curS = 0.38
local curV = 1.0
local curA = 0.33
local activeColorCallback = nil
local activeAnchorGui = nil

local function toHexRGBA(color, alpha)
    local r = math.clamp(math.round(color.R * 255), 0, 255)
    local g = math.clamp(math.round(color.G * 255), 0, 255)
    local b = math.clamp(math.round(color.B * 255), 0, 255)
    local a = math.clamp(math.round((alpha or 1) * 255), 0, 255)
    return string.format("#%02X%02X%02X%02X", r, g, b, a)
end

local function parseHexRGBA(str)
    str = string.gsub(str, "[^%w]", "")
    if #str == 6 then
        local r = tonumber(string.sub(str, 1, 2), 16)
        local g = tonumber(string.sub(str, 3, 4), 16)
        local b = tonumber(string.sub(str, 5, 6), 16)
        if r and g and b then
            return Color3.fromRGB(r, g, b), 1
        end
    elseif #str >= 8 then
        local r = tonumber(string.sub(str, 1, 2), 16)
        local g = tonumber(string.sub(str, 3, 4), 16)
        local b = tonumber(string.sub(str, 5, 6), 16)
        local a = tonumber(string.sub(str, 7, 8), 16)
        if r and g and b and a then
            return Color3.fromRGB(r, g, b), a / 255
        end
    end
    return nil, nil
end

local function syncColorPickerUI(triggerCallback)
    local pureHue = Color3.fromHSV(curH, 1, 1)
    local finalColor = Color3.fromHSV(curH, curS, curV)

    SVBox.BackgroundColor3 = pureHue
    SVHandle.Position = UDim2.new(curS, 0, 1 - curV, 0)
    SVHandle.BackgroundColor3 = finalColor

    HueLeftPointer.Position = UDim2.new(0, -6, curH, -5)
    HueRightPointer.Position = UDim2.new(1, -1, curH, -5)

    AlphaColorOverlay.BackgroundColor3 = finalColor
    local alphaY = 1 - curA
    AlphaLeftPointer.Position = UDim2.new(0, -6, alphaY, -5)
    AlphaRightPointer.Position = UDim2.new(1, -1, alphaY, -5)

    -- Left half solid, right half transparent over checkers
    PreviewSolid.BackgroundColor3 = finalColor
    PreviewSolid.BackgroundTransparency = 0
    PreviewAlphaOverlay.BackgroundColor3 = finalColor
    PreviewAlphaOverlay.BackgroundTransparency = 1 - curA

    if not HexInput:IsFocused() then
        HexInput.Text = toHexRGBA(finalColor, curA)
    end

    if triggerCallback and activeColorCallback then
        pcall(activeColorCallback, finalColor, curA)
    end
end

HexInput.FocusLost:Connect(function()
    local parsedColor, parsedAlpha = parseHexRGBA(HexInput.Text)
    if parsedColor then
        curH, curS, curV = Color3.toHSV(parsedColor)
        curA = parsedAlpha or 1
        syncColorPickerUI(true)
    else
        syncColorPickerUI(false)
    end
end)

draggingSV = false
draggingHue = false
draggingAlpha = false

local function handleSVInput(pos)
    local inset = GuiService:GetGuiInset()
    local m = pos or UserInputService:GetMouseLocation()
    local mx = (typeof(m) == "Vector3") and (m.X + inset.X) or m.X
    local my = (typeof(m) == "Vector3") and (m.Y + inset.Y) or m.Y
    local abs = SVBox.AbsolutePosition + inset
    local sz = SVBox.AbsoluteSize
    local relX = math.clamp(mx - abs.X, 0, sz.X)
    local relY = math.clamp(my - abs.Y, 0, sz.Y)
    curS = relX / sz.X
    curV = 1 - (relY / sz.Y)
    syncColorPickerUI(true)
end

local function handleHueInput(pos)
    local inset = GuiService:GetGuiInset()
    local m = pos or UserInputService:GetMouseLocation()
    local my = (typeof(m) == "Vector3") and (m.Y + inset.Y) or m.Y
    local abs = HueBar.AbsolutePosition + inset
    local sz = HueBar.AbsoluteSize
    local relY = math.clamp(my - abs.Y, 0, sz.Y)
    curH = math.clamp(relY / sz.Y, 0, 1)
    syncColorPickerUI(true)
end

local function handleAlphaInput(pos)
    local inset = GuiService:GetGuiInset()
    local m = pos or UserInputService:GetMouseLocation()
    local my = (typeof(m) == "Vector3") and (m.Y + inset.Y) or m.Y
    local abs = AlphaBar.AbsolutePosition + inset
    local sz = AlphaBar.AbsoluteSize
    local relY = math.clamp(my - abs.Y, 0, sz.Y)
    curA = math.clamp(1 - (relY / sz.Y), 0, 1)
    syncColorPickerUI(true)
end

SVBox.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingSV = true
        handleSVInput(input.Position)
    end
end)

HueBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingHue = true
        handleHueInput(input.Position)
    end
end)

AlphaBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingAlpha = true
        handleAlphaInput(input.Position)
    end
end)

local cpMoveConn = UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if draggingSV then
            handleSVInput(input.Position)
        elseif draggingHue then
            handleHueInput(input.Position)
        elseif draggingAlpha then
            handleAlphaInput(input.Position)
        end
    end
end)
table.insert(Connections, cpMoveConn)

local cpEndConn = UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingSV = false
        draggingHue = false
        draggingAlpha = false
    end
end)
table.insert(Connections, cpEndConn)

-- Click anywhere outside modal to close
local cpClickOutsideConn = UserInputService.InputBegan:Connect(function(input, processed)
    if not ColorPickerModal or not ColorPickerModal.Visible then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if draggingSV or draggingHue or draggingAlpha or (os.clock() - lastPopoverDragTime < 0.2) then
            return
        end
        local pos = input.Position
        if isPosInGui(ColorPickerModal, pos, 6) then
            return
        end
        if activeAnchorGui and isPosInGui(activeAnchorGui, pos, 6) then
            return
        end
        ColorPickerModal.Visible = false
        ColorPickerDismiss.Visible = false
    end
end)
table.insert(Connections, cpClickOutsideConn)

makePopoverDraggable(ColorPickerModal, function(pos)
    if draggingSV or draggingHue or draggingAlpha then return true end
    if isPosInGui(SVBox, pos) then return true end
    if isPosInGui(HueBar, pos) then return true end
    if isPosInGui(AlphaBar, pos) then return true end
    if isPosInGui(HexFrame, pos) then return true end
    return false
end)

function Controls:OpenColorPicker(anchorGui, initialColor, initialAlpha, callback)
    if ColorPickerModal.Visible and activeAnchorGui == anchorGui then
        ColorPickerModal.Visible = false
        ColorPickerDismiss.Visible = false
        return
    end

    local isGrenadeAnchor = false
    local anchorAncestors = {}
    if anchorGui then
        local cur = anchorGui
        while cur do
            anchorAncestors[cur] = true
            if cur.Name == "GrenadeSettingsPopover" or cur.Name == "GrenadeTracersPopover" then
                isGrenadeAnchor = true
            end
            cur = cur.Parent
        end
    end

    CloseAllPopups(function(frame, item)
        if frame == ColorPickerModal then
            return true
        end
        if anchorAncestors[frame] then
            return true
        end
        if isGrenadeAnchor and (frame.Name == "GrenadeSettingsPopover" or frame.Name == "GrenadeTracersPopover") then
            return true
        end
        return false
    end)

    activeColorCallback = callback
    activeAnchorGui = anchorGui

    if initialColor then
        curH, curS, curV = Color3.toHSV(initialColor)
    else
        curH, curS, curV = 0, 0, 1.0
    end
    curA = initialAlpha or 1

    local pickerW = 316
    local pickerH = 266
    ColorPickerModal.Size = UDim2.new(0, pickerW, 0, pickerH)

    -- Top-left of color picker opens where cursor is, offset slightly to the right
    local mousePos = getRealMousePos()
    local posX = mousePos.X + 8
    local posY = mousePos.Y - 2

    local cam = workspace.CurrentCamera
    local viewSize = cam and cam.ViewportSize or Vector2.new(1920, 1080)
    if posX + pickerW > viewSize.X - 8 then
        posX = math.max(8, viewSize.X - pickerW - 8)
    end
    if posY + pickerH > viewSize.Y - 8 then
        posY = math.max(8, viewSize.Y - pickerH - 8)
    end
    if posY < 8 then
        posY = 8
    end

    ColorPickerModal.Position = UDim2.new(0, posX, 0, posY)
    ColorPickerDismiss.Visible = false
    ColorPickerModal.Visible = true
    if ModalBlocker then ModalBlocker.Visible = true end
    syncColorPickerUI(false)
end
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
                    SOUND VOLUME / EXTRA SETTINGS POPOVER
                            (Matching Image 5)
    ═══════════════════════════════════════════════════════════════════════════
]]

do
local SoundVolumePopover = Instance.new("Frame")
SoundVolumePopover.Name = "SoundVolumePopover"
SoundVolumePopover.Size = UDim2.new(0, 190, 0, 48)
SoundVolumePopover.BackgroundColor3 = Color3.fromRGB(19, 20, 24)
SoundVolumePopover.BorderSizePixel = 0
SoundVolumePopover.Visible = false
SoundVolumePopover.ZIndex = 520
SoundVolumePopover.Parent = PopupsLayer
createCorner(SoundVolumePopover, 2)

local svPad = Instance.new("UIPadding")
svPad.PaddingTop = UDim.new(0, 8)
svPad.PaddingBottom = UDim.new(0, 8)
svPad.PaddingLeft = UDim.new(0, 10)
svPad.PaddingRight = UDim.new(0, 10)
svPad.Parent = SoundVolumePopover

local svHeader = Instance.new("Frame")
svHeader.Name = "Header"
svHeader.Size = UDim2.new(1, 0, 0, 16)
svHeader.BackgroundTransparency = 1
svHeader.Parent = SoundVolumePopover

local svLabel = Instance.new("TextLabel")
svLabel.Name = "Label"
svLabel.Size = UDim2.new(0.6, 0, 1, 0)
svLabel.BackgroundTransparency = 1
svLabel.Text = "Volume"
svLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
svLabel.TextSize = 13
svLabel.Font = Theme.FontBold
svLabel.TextXAlignment = Enum.TextXAlignment.Left
svLabel.Parent = svHeader

local svVal = Instance.new("TextLabel")
svVal.Name = "Value"
svVal.Size = UDim2.new(0.4, 0, 1, 0)
svVal.Position = UDim2.new(0.6, 0, 0, 0)
svVal.BackgroundTransparency = 1
svVal.Text = "5.000"
svVal.TextColor3 = Color3.fromRGB(255, 255, 255)
svVal.TextSize = 13
svVal.Font = Theme.FontBold
svVal.TextXAlignment = Enum.TextXAlignment.Right
svVal.Parent = svHeader

local svTrack = Instance.new("TextButton")
svTrack.Name = "Track"
svTrack.Size = UDim2.new(1, 0, 0, 4)
svTrack.Position = UDim2.new(0, 0, 0, 24)
svTrack.BackgroundColor3 = Color3.fromRGB(38, 40, 48)
svTrack.BorderSizePixel = 0
svTrack.AutoButtonColor = false
svTrack.Text = ""
svTrack.Parent = SoundVolumePopover
createCorner(svTrack, 2)

local svFill = Instance.new("Frame")
svFill.Name = "Fill"
svFill.Size = UDim2.new(1, 0, 1, 0)
svFill.BackgroundColor3 = Color3.fromRGB(160, 165, 180)
svFill.BorderSizePixel = 0
svFill.Parent = svTrack
createCorner(svFill, 2)

local activeSvAnchor = nil
local activeSvCallback = nil
local currentSvNum = 5.000
local draggingSvTrack = false

local function setSvNum(val)
    currentSvNum = math.clamp(val, 0, 5)
    svVal.Text = string.format("%.3f", currentSvNum)
    svFill.Size = UDim2.new(math.clamp(currentSvNum / 5, 0, 1), 0, 1, 0)
    if activeSvCallback then
        pcall(activeSvCallback, currentSvNum)
    end
end

local function updateSvFromMouse(input)
    local tPos = svTrack.AbsolutePosition
    local tWidth = svTrack.AbsoluteSize.X
    if tWidth <= 0 then return end
    local frac = math.clamp((input.Position.X - tPos.X) / tWidth, 0, 1)
    setSvNum(frac * 5)
end

svTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingSvTrack = true
        updateSvFromMouse(input)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingSvTrack and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateSvFromMouse(input)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingSvTrack = false
    end
end)

makePopoverDraggable(SoundVolumePopover, function(pos)
    return isPosInGui(svTrack, pos, 4) or draggingSvTrack
end)

function Controls:OpenVolumePopover(anchorBtn, currentVal, callback)
    if SoundVolumePopover.Visible and activeSvAnchor == anchorBtn then
        SoundVolumePopover.Visible = false
        activeSvAnchor = nil
        return
    end
    CloseAllPopups()
    activeSvAnchor = anchorBtn
    activeSvCallback = callback
    setSvNum(currentVal or 5.000)

    local screenPos = getScreenPos(anchorBtn)
    local absSize = anchorBtn.AbsoluteSize
    local posX = screenPos.X - 160
    local posY = screenPos.Y + absSize.Y + 4
    local cam = workspace.CurrentCamera
    local viewSize = cam and cam.ViewportSize or Vector2.new(1920, 1080)
    posX = math.clamp(posX, 8, viewSize.X - 195)
    posY = math.clamp(posY, 8, viewSize.Y - 55)

    SoundVolumePopover.Position = UDim2.new(0, posX, 0, posY)
    SoundVolumePopover.Visible = true
end

table.insert(ActivePopups, {
    Frame = SoundVolumePopover,
    OnClose = function()
        activeSvAnchor = nil
    end
})

local svOutsideConn = UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if not SoundVolumePopover.Visible then return end
        if draggingSvTrack or (os.clock() - lastPopoverDragTime < 0.2) then return end
        local pos = input.Position
        if isPosInGui(SoundVolumePopover, pos) then
            return
        end
        if activeSvAnchor and isPosInGui(activeSvAnchor, pos) then
            return
        end
        SoundVolumePopover.Visible = false
        activeSvAnchor = nil
    end
end)
table.insert(Connections, svOutsideConn)
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
                         GRENADE TRACERS POPOVERS
    ═══════════════════════════════════════════════════════════════════════════
]]

do
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

function Controls:OpenGrenadeTracers(btn)
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
        if ColorPickerModal and ColorPickerModal.Visible and isPosInGui(ColorPickerModal, pos) then
            return
        end
        GrenadeSettingsPopover.Visible = false
        GrenadeTracersPopover.Visible = false
    end
end)
table.insert(Connections, gtOutsideConn)
end

-- Section Header Label (Centered over column)
function Controls:CreateSectionHeader(parent, title, order)
    local HeaderLabel = Instance.new("TextLabel")
    HeaderLabel.Name = title .. "_Header"
    HeaderLabel.Size = UDim2.new(1, 0, 0, 24)
    HeaderLabel.BackgroundTransparency = 1
    HeaderLabel.Text = title
    HeaderLabel.TextColor3 = Theme.TextSub
    HeaderLabel.TextSize = 13
    HeaderLabel.Font = Theme.FontMedium
    HeaderLabel.TextXAlignment = Enum.TextXAlignment.Center
    HeaderLabel.LayoutOrder = order or 0
    HeaderLabel.Parent = parent
    return HeaderLabel
end

-- Checkbox Toggle (with optional Keybind button)
function Controls:CreateToggle(parent, config)
    local name = config.Name or "Toggle"
    local default = false
    local hasKeybind = (config.Keybind ~= nil)
    local callback = config.Callback
    local order = config.LayoutOrder or 0

    local ToggleRow = Instance.new("Frame")
    ToggleRow.Name = name .. "_Row"
    ToggleRow.Size = UDim2.new(1, -6, 0, 22)
    ToggleRow.BackgroundTransparency = 1
    ToggleRow.LayoutOrder = order
    ToggleRow.Parent = parent

    -- Box (No outline, constant color rgba(29, 30, 34))
    local Box = Instance.new("TextButton")
    Box.Name = "Box"
    Box.Size = UDim2.new(0, 16, 0, 16)
    Box.Position = UDim2.new(0, 4, 0.5, -8)
    Box.BackgroundColor3 = default and Theme.CheckboxChecked or Theme.CheckboxOff
    Box.BorderSizePixel = 0
    Box.AutoButtonColor = false
    Box.Text = ""
    Box.Parent = ToggleRow
    createCorner(Box, 3)

    local CheckIcon = Instance.new("TextLabel")
    CheckIcon.Name = "Check"
    CheckIcon.Size = UDim2.new(1, 0, 1, 0)
    CheckIcon.BackgroundTransparency = 1
    CheckIcon.FontFace = GuiIconsFont
    CheckIcon.Text = "X"
    CheckIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    CheckIcon.TextSize = 13
    CheckIcon.TextXAlignment = Enum.TextXAlignment.Center
    CheckIcon.TextYAlignment = Enum.TextYAlignment.Center
    CheckIcon.TextStrokeTransparency = 0.75
    CheckIcon.Visible = default
    CheckIcon.Parent = Box

    -- Calculate right spacing for label based on elements present
    local rightMargin = -8
    if config.Dropdown and config.SettingsIcon then
        local ddWidth = (config.Dropdown.Width or (config.Dropdown.Multi and 136 or 76))
        rightMargin = -(ddWidth + 30)
    elseif config.Dropdown and config.ColorChip then
        local ddWidth = (config.Dropdown.Width or (config.Dropdown.Multi and 136 or 76))
        rightMargin = -(ddWidth + 38)
    elseif config.Dropdown then
        local ddWidth = (config.Dropdown.Width or (config.Dropdown.Multi and 136 or 76))
        rightMargin = -(ddWidth + 10)
    elseif config.ColorChips then
        local baseRight = (config.SettingsIcon and 26 or 4)
        rightMargin = -(baseRight + #config.ColorChips * 18 + 8)
    elseif config.ColorChip and config.SettingsIcon then
        rightMargin = -48
    elseif config.ColorChip then
        rightMargin = -24
    elseif config.SettingsIcon then
        rightMargin = -26
    elseif hasKeybind then
        rightMargin = -55
    end

    -- Label
    local Label = Instance.new("TextButton")
    Label.Name = "Label"
    Label.Size = UDim2.new(1, rightMargin, 1, 0)
    Label.Position = UDim2.new(0, 28, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = config.TextColor or (default and Theme.TextActive or Theme.TextDim)
    Label.TextSize = 13
    Label.Font = Theme.FontBold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = ToggleRow

    local state = default
    local function updateState(val)
        state = val
        if state then
            Box.BackgroundColor3 = Theme.CheckboxChecked
            CheckIcon.Visible = true
            Label.TextColor3 = config.TextColor or Theme.TextActive
        else
            Box.BackgroundColor3 = Theme.CheckboxOff
            CheckIcon.Visible = false
            Label.TextColor3 = config.TextColor or Theme.TextDim
        end
        if callback then
            pcall(callback, state)
        end
    end

    -- Hover effect on checkbox box (transparent red highlight on toggle hover matching screenshot)
    local function onToggleHoverEnter()
        if not state then
            Box.BackgroundColor3 = Theme.CheckboxHoverOff
        end
    end
    local function onToggleHoverLeave()
        if not state then
            Box.BackgroundColor3 = Theme.CheckboxOff
        end
    end

    ToggleRow.MouseEnter:Connect(onToggleHoverEnter)
    ToggleRow.MouseLeave:Connect(onToggleHoverLeave)
    Box.MouseEnter:Connect(onToggleHoverEnter)
    Box.MouseLeave:Connect(onToggleHoverLeave)
    Label.MouseEnter:Connect(onToggleHoverEnter)
    Label.MouseLeave:Connect(onToggleHoverLeave)

    Box.MouseButton1Click:Connect(function() updateState(not state) end)
    Label.MouseButton1Click:Connect(function() updateState(not state) end)

    if config.SettingsIcon then
        local SettingsBtn = Instance.new("TextButton")
        SettingsBtn.Name = "SettingsBtn"
        SettingsBtn.Size = UDim2.new(0, 16, 0, 16)
        if config.Dropdown then
            local ddWidth = (config.Dropdown.Width or (config.Dropdown.Multi and 136 or 76))
            SettingsBtn.Position = UDim2.new(1, -(ddWidth + 24), 0.5, -8)
        else
            SettingsBtn.Position = UDim2.new(1, -20, 0.5, -8)
        end
        SettingsBtn.BackgroundTransparency = 1
        if config.SettingsIconFont or GuiIconsFont then
            SettingsBtn.FontFace = config.SettingsIconFont or GuiIconsFont
            SettingsBtn.Text = config.SettingsIconText or "6"
            SettingsBtn.TextSize = config.SettingsIconSize or 13
        else
            SettingsBtn.Font = Theme.FontBold
            SettingsBtn.Text = config.SettingsIconText or "≡"
            SettingsBtn.TextSize = config.SettingsIconSize or 15
        end
        SettingsBtn.TextColor3 = Color3.fromRGB(180, 185, 195)
        SettingsBtn.AutoButtonColor = false
        SettingsBtn.Parent = ToggleRow
        SettingsBtn.MouseEnter:Connect(function() SettingsBtn.TextColor3 = Color3.fromRGB(255, 255, 255) end)
        SettingsBtn.MouseLeave:Connect(function() SettingsBtn.TextColor3 = Color3.fromRGB(180, 185, 195) end)
        if config.OnSettingsClick then
            SettingsBtn.MouseButton1Click:Connect(function()
                config.OnSettingsClick(SettingsBtn)
            end)
        end
    end

    if config.ColorChips then
        local count = #config.ColorChips
        local baseRight = (config.SettingsIcon and 26 or 4)
        for i, chipColor in ipairs(config.ColorChips) do
            local Chip = Instance.new("TextButton")
            Chip.Name = "Chip_" .. i
            Chip.Size = UDim2.new(0, 14, 0, 14)
            local offset = baseRight + (count - i) * 18
            Chip.Position = UDim2.new(1, -offset - 14, 0.5, -7)
            Chip.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Chip.BorderSizePixel = 0
            Chip.Text = ""
            Chip.AutoButtonColor = false
            Chip.Parent = ToggleRow
            createCorner(Chip, 4.75)

            local chipIdx = i
            Chip.MouseButton1Click:Connect(function()
                Controls:OpenColorPicker(Chip, Chip.BackgroundColor3, 1, function(newColor, newAlpha)
                    Chip.BackgroundColor3 = newColor
                    if config.ColorCallback then
                        pcall(config.ColorCallback, chipIdx, newColor, newAlpha)
                    end
                end)
            end)
        end
    elseif config.ColorChip then
        local Chip = Instance.new("TextButton")
        Chip.Name = "ColorChip"
        Chip.Size = UDim2.new(0, 14, 0, 14)
        local ddWidth = config.Dropdown and (config.Dropdown.Width or (config.Dropdown.Multi and 136 or 76)) or 0
        local offset = config.Dropdown and (ddWidth + 22) or (config.SettingsIcon and 40 or 18)
        Chip.Position = UDim2.new(1, -offset, 0.5, -7)
        Chip.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Chip.BorderSizePixel = 0
        Chip.Text = ""
        Chip.AutoButtonColor = false
        Chip.Parent = ToggleRow
        createCorner(Chip, 4.75)

        Chip.MouseButton1Click:Connect(function()
            Controls:OpenColorPicker(Chip, Chip.BackgroundColor3, 1, function(newColor, newAlpha)
                Chip.BackgroundColor3 = newColor
                if config.ColorCallback then
                    pcall(config.ColorCallback, newColor, newAlpha)
                end
            end)
        end)
    end

    if config.Dropdown then
        local ddConfig = config.Dropdown
        local dOpts = ddConfig.Options or { "Left", "Right" }
        local isMulti = (ddConfig.Multi == true)
        local dSel = nil
        if isMulti then
            dSel = {}
            if typeof(ddConfig.Default) == "table" then
                for _, k in ipairs(ddConfig.Default) do dSel[k] = true end
                for k, v in pairs(ddConfig.Default) do if v == true then dSel[k] = true end end
            elseif typeof(ddConfig.Default) == "string" then
                dSel[ddConfig.Default] = true
            end
        else
            dSel = ddConfig.Default or dOpts[1]
        end

        local ddWidth = ddConfig.Width or (isMulti and 136 or 76)
        local DdBox = Instance.new("Frame")
        DdBox.Name = "InlineDropdown"
        DdBox.Size = UDim2.new(0, ddWidth, 0, 22)
        DdBox.Position = UDim2.new(1, -(ddWidth + 2), 0.5, -11)
        DdBox.BackgroundColor3 = Theme.DropdownBg
        DdBox.Parent = ToggleRow
        createCorner(DdBox, 3)
        createStroke(DdBox, Theme.ControlBorder, 1)

        local function getDisplayText()
            if isMulti then
                local list = {}
                for _, opt in ipairs(dOpts) do
                    if dSel[opt] then
                        table.insert(list, opt)
                    end
                end
                if #list == 0 then return "None" end
                return table.concat(list, ", ")
            else
                return tostring(dSel)
            end
        end

        local DdLabel = Instance.new("TextLabel")
        DdLabel.Name = "Selected"
        DdLabel.Size = UDim2.new(1, -22, 1, 0)
        DdLabel.Position = UDim2.new(0, 6, 0, 0)
        DdLabel.BackgroundTransparency = 1
        DdLabel.ClipsDescendants = true
        DdLabel.Text = getDisplayText()
        DdLabel.TextColor3 = Theme.TextActive
        DdLabel.TextSize = 11
        DdLabel.Font = Theme.FontBold
        DdLabel.TextXAlignment = Enum.TextXAlignment.Left
        DdLabel.Parent = DdBox

        local DdChevron = Instance.new("TextLabel")
        DdChevron.Name = "Chevron"
        DdChevron.Size = UDim2.new(0, 12, 0, 12)
        DdChevron.Position = UDim2.new(1, -15, 0.5, -6)
        DdChevron.BackgroundTransparency = 1
        DdChevron.FontFace = GuiIconsFont
        DdChevron.Text = "C"
        DdChevron.TextColor3 = Color3.fromRGB(255, 255, 255)
        DdChevron.TextSize = 11
        DdChevron.Parent = DdBox

        local DdTrigger = Instance.new("TextButton")
        DdTrigger.Name = "Trigger"
        DdTrigger.Size = UDim2.new(1, 0, 1, 0)
        DdTrigger.BackgroundTransparency = 1
        DdTrigger.Text = ""
        DdTrigger.Parent = DdBox

        DdTrigger.MouseEnter:Connect(function()
            DdBox.BackgroundColor3 = Color3.fromRGB(95, 102, 112)
        end)
        DdTrigger.MouseLeave:Connect(function()
            DdBox.BackgroundColor3 = Theme.DropdownBg
        end)

        -- Unified "Bigger Dropdown" Popover (starts from opener top, covering it seamlessly)
        local DdPopover = Instance.new("Frame")
        DdPopover.Name = name .. "_InlineDdPop"
        DdPopover.Size = UDim2.new(0, ddWidth, 0, 22 + #dOpts * 21 + 4)
        DdPopover.BackgroundColor3 = Theme.DropdownBg
        DdPopover.BorderSizePixel = 0
        DdPopover.Visible = false
        DdPopover.ZIndex = 140
        DdPopover.Parent = PopupsLayer
        createCorner(DdPopover, 3)
        createStroke(DdPopover, Theme.ControlBorder, 1)

        -- Top Header inside the open dropdown (shows current selection + up chevron, clicks to close)
        local DdPopHeader = Instance.new("Frame")
        DdPopHeader.Name = "Header"
        DdPopHeader.Size = UDim2.new(1, 0, 0, 22)
        DdPopHeader.Position = UDim2.new(0, 0, 0, 0)
        DdPopHeader.BackgroundTransparency = 1
        DdPopHeader.Visible = false
        DdPopHeader.ZIndex = 141
        DdPopHeader.Parent = DdPopover

        local DdPopHeaderLabel = Instance.new("TextLabel")
        DdPopHeaderLabel.Name = "Selected"
        DdPopHeaderLabel.Size = UDim2.new(1, -22, 1, 0)
        DdPopHeaderLabel.Position = UDim2.new(0, 6, 0, 0)
        DdPopHeaderLabel.BackgroundTransparency = 1
        DdPopHeaderLabel.ClipsDescendants = true
        DdPopHeaderLabel.Text = getDisplayText()
        DdPopHeaderLabel.TextColor3 = Theme.TextActive
        DdPopHeaderLabel.TextSize = 11
        DdPopHeaderLabel.Font = Theme.FontBold
        DdPopHeaderLabel.TextXAlignment = Enum.TextXAlignment.Left
        DdPopHeaderLabel.Visible = false
        DdPopHeaderLabel.ZIndex = 142
        DdPopHeaderLabel.Parent = DdPopHeader

        local DdPopChevron = Instance.new("TextLabel")
        DdPopChevron.Name = "Chevron"
        DdPopChevron.Size = UDim2.new(0, 12, 0, 12)
        DdPopChevron.Position = UDim2.new(1, -15, 0.5, -6)
        DdPopChevron.BackgroundTransparency = 1
        DdPopChevron.FontFace = GuiIconsFont
        DdPopChevron.Text = "B"
        DdPopChevron.TextColor3 = Color3.fromRGB(255, 255, 255)
        DdPopChevron.TextSize = 11
        DdPopChevron.TextXAlignment = Enum.TextXAlignment.Center
        DdPopChevron.TextYAlignment = Enum.TextYAlignment.Center
        DdPopChevron.Visible = false
        DdPopChevron.ZIndex = 142
        DdPopChevron.Parent = DdPopHeader

        local DdPopHeaderBtn = Instance.new("TextButton")
        DdPopHeaderBtn.Name = "CloseTrigger"
        DdPopHeaderBtn.Size = UDim2.new(1, 0, 1, 0)
        DdPopHeaderBtn.BackgroundTransparency = 1
        DdPopHeaderBtn.Text = ""
        DdPopHeaderBtn.Visible = false
        DdPopHeaderBtn.ZIndex = 143
        DdPopHeaderBtn.Parent = DdPopHeader

        DdPopHeaderBtn.MouseButton1Click:Connect(function()
            CloseAllPopups()
        end)

        local DdListContainer = Instance.new("Frame")
        DdListContainer.Name = "ListContainer"
        DdListContainer.Size = UDim2.new(1, 0, 1, -22)
        DdListContainer.Position = UDim2.new(0, 0, 0, 22)
        DdListContainer.BackgroundTransparency = 1
        DdListContainer.ZIndex = 141
        DdListContainer.Parent = DdPopover

        table.insert(ActivePopups, {
            Frame = DdPopover,
            OnClose = function()
                DdChevron.Text = "C"
            end
        })

        local DdList = Instance.new("UIListLayout")
        DdList.Padding = UDim.new(0, 1)
        DdList.SortOrder = Enum.SortOrder.LayoutOrder
        DdList.Parent = DdListContainer

        local function updateOptionColors()
            for _, child in ipairs(DdListContainer:GetChildren()) do
                if child:IsA("TextButton") then
                    local active = false
                    if isMulti then
                        active = (dSel[child.Name] == true)
                    else
                        active = (child.Name == dSel)
                    end
                    child.BackgroundColor3 = Theme.DropdownBg
                    child.TextColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 134, 145)
                    child.Font = active and Theme.FontBold or Theme.FontMedium
                end
            end
        end

        for optIdx, opt in ipairs(dOpts) do
            local OBtn = Instance.new("TextButton")
            OBtn.Name = opt
            OBtn.LayoutOrder = optIdx
            OBtn.Size = UDim2.new(1, 0, 0, 20)
            local isSel = false
            if isMulti then
                isSel = (dSel[opt] == true)
            else
                isSel = (opt == dSel)
            end
            OBtn.BackgroundColor3 = Theme.DropdownBg
            OBtn.Text = "  " .. opt
            OBtn.TextColor3 = isSel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 134, 145)
            OBtn.TextSize = 11
            OBtn.Font = isSel and Theme.FontBold or Theme.FontMedium
            OBtn.TextXAlignment = Enum.TextXAlignment.Left
            OBtn.ZIndex = 142
            OBtn.AutoButtonColor = false
            OBtn.Parent = DdListContainer
            createCorner(OBtn, 2)

            OBtn.MouseEnter:Connect(function()
                local isCur = (isMulti and dSel[opt] or opt == dSel)
                if not isCur then
                    OBtn.TextColor3 = Color3.fromRGB(195, 200, 210)
                end
            end)
            OBtn.MouseLeave:Connect(function()
                local isCur = (isMulti and dSel[opt] or opt == dSel)
                if not isCur then
                    OBtn.TextColor3 = Color3.fromRGB(130, 134, 145)
                end
            end)
            OBtn.MouseButton1Click:Connect(function()
                if isMulti then
                    dSel[opt] = not dSel[opt]
                    local txt = getDisplayText()
                    DdLabel.Text = txt
                    DdPopHeaderLabel.Text = txt
                    updateOptionColors()
                    if ddConfig.Callback then pcall(ddConfig.Callback, dSel) end
                else
                    dSel = opt
                    local txt = getDisplayText()
                    DdLabel.Text = txt
                    DdPopHeaderLabel.Text = txt
                    DdPopover.Visible = false
                    if ModalBlocker then ModalBlocker.Visible = false end
                    updateOptionColors()
                    if ddConfig.Callback then pcall(ddConfig.Callback, opt) end
                end
            end)
        end

        DdTrigger.MouseButton1Click:Connect(function()
            local isOpen = DdPopover.Visible
            CloseAllPopups()
            if not isOpen then
                local boxPos = getScreenPos(DdBox)
                local absSize = DdBox.AbsoluteSize
                local optionsH = #dOpts * 21 + 4
                local totalH = absSize.Y + optionsH
                DdPopover.Position = UDim2.new(0, boxPos.X, 0, boxPos.Y)
                DdPopover.Size = UDim2.new(0, absSize.X, 0, totalH)
                DdPopHeader.Size = UDim2.new(1, 0, 0, absSize.Y)
                DdPopHeader.Visible = true
                DdPopHeaderLabel.Visible = true
                DdPopHeaderLabel.Text = getDisplayText()
                DdPopChevron.Visible = true
                DdPopChevron.Text = "B"
                DdPopHeaderBtn.Visible = true
                DdListContainer.Position = UDim2.new(0, 0, 0, absSize.Y)
                DdListContainer.Size = UDim2.new(1, 0, 1, -absSize.Y)
                DdPopover.Visible = true
                DdChevron.Text = "B"
                updateOptionColors()
                if ModalBlocker then ModalBlocker.Visible = true end
            else
                DdPopover.Visible = false
                DdChevron.Text = "C"
            end
        end)
    end

    -- Keybind Button on Right using icon "D" (Screenshot 3 & 4)
    local keybindObj = nil
    if hasKeybind then
        local hasIndicatorUI = (typeof(config.Keybind) == "table" and config.Keybind.HasIndicator == true)
        local bindData = {
            Key = nil,
            Type = "Always On",
            Indicator = false,
            IndicatorText = "",
            ColorActive = Color3.fromRGB(255, 255, 255),
            ColorInactive = Color3.fromRGB(255, 255, 255)
        }

        if typeof(config.Keybind) == "table" then
            for k, v in pairs(config.Keybind) do
                bindData[k] = v
            end
        elseif typeof(config.Keybind) == "EnumItem" then
            bindData.Key = config.Keybind
        end
        if not bindData.Type or bindData.Type == "Always on" then
            bindData.Type = "Always On"
        end

        local function getKeyDisplayName(k)
            if not k then return "[none]" end
            local raw = typeof(k) == "EnumItem" and k.Name or tostring(k)
            return string.lower(raw)
        end

        local BindBtn = Instance.new("TextButton")
        BindBtn.Name = "KeybindBtn"
        BindBtn.Size = UDim2.new(0, 18, 0, 18)
        BindBtn.Position = UDim2.new(1, -22, 0.5, -9)
        BindBtn.BackgroundTransparency = 1
        BindBtn.FontFace = GuiIconsFont
        BindBtn.Text = "D"
        BindBtn.TextSize = 15
        BindBtn.AutoButtonColor = false
        BindBtn.Parent = ToggleRow

        local function updateBindBtn()
            local isBound = (bindData.Key ~= nil and bindData.Key ~= Enum.KeyCode.Unknown)
            local isUnboundWarning = (not isBound and (bindData.Type == "Toggle" or bindData.Type == "On key down" or bindData.Type == "Hold"))
            if isUnboundWarning then
                BindBtn.TextColor3 = Theme.Accent
            else
                BindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
        end
        updateBindBtn()

        BindBtn.MouseEnter:Connect(function()
            local isBound = (bindData.Key ~= nil and bindData.Key ~= Enum.KeyCode.Unknown)
            local isUnboundWarning = (not isBound and (bindData.Type == "Toggle" or bindData.Type == "On key down" or bindData.Type == "Hold"))
            if isUnboundWarning then
                BindBtn.TextColor3 = Theme.AccentHover
            else
                BindBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
            end
        end)
        BindBtn.MouseLeave:Connect(function()
            updateBindBtn()
        end)

        -- Keybind Popover Modal: square, no outline, rgba(19, 20, 24)
        local BindPopover = Instance.new("Frame")
        BindPopover.Name = name .. "_BindPopover"
        BindPopover.Size = UDim2.new(0, 185, 0, hasIndicatorUI and 126 or 70)
        BindPopover.BackgroundColor3 = Color3.fromRGB(19, 20, 24)
        BindPopover.BorderSizePixel = 0
        BindPopover.Visible = false
        BindPopover.ZIndex = 130
        BindPopover.Parent = PopupsLayer
        createCorner(BindPopover, 3)

        local TypePopover = nil
        local TypeChevron = nil
        table.insert(ActivePopups, {
            Frame = BindPopover,
            OnClose = function()
                if TypePopover then TypePopover.Visible = false end
                if TypeChevron then TypeChevron.Text = "C" end
            end
        })

        local PopoverPad = Instance.new("UIPadding")
        PopoverPad.PaddingTop = UDim.new(0, 8)
        PopoverPad.PaddingBottom = UDim.new(0, 8)
        PopoverPad.PaddingLeft = UDim.new(0, 8)
        PopoverPad.PaddingRight = UDim.new(0, 8)
        PopoverPad.Parent = BindPopover

        local PopoverLayout = Instance.new("UIListLayout")
        PopoverLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PopoverLayout.Padding = UDim.new(0, 6)
        PopoverLayout.Parent = BindPopover

        local IndCheck = nil
        local SwatchContainer = nil
        local IndTextBox = nil

        if hasIndicatorUI then
            -- Row 1: Show indicator toggle + color swatches
            local Row1 = Instance.new("Frame")
            Row1.Name = "Row1_Indicator"
            Row1.Size = UDim2.new(1, 0, 0, 18)
            Row1.BackgroundTransparency = 1
            Row1.LayoutOrder = 1
            Row1.ZIndex = 131
            Row1.Parent = BindPopover

            IndCheck = Instance.new("TextButton")
            IndCheck.Name = "Check"
            IndCheck.Size = UDim2.new(0, 14, 0, 14)
            IndCheck.Position = UDim2.new(0, 0, 0.5, -7)
            IndCheck.BackgroundColor3 = bindData.Indicator and Theme.CheckboxChecked or Theme.CheckboxOff
            IndCheck.BorderSizePixel = 0
            IndCheck.AutoButtonColor = false
            IndCheck.Text = ""
            IndCheck.ZIndex = 132
            IndCheck.Parent = Row1
            createCorner(IndCheck, 3)

            IndCheck.MouseEnter:Connect(function()
                if not bindData.Indicator then
                    IndCheck.BackgroundColor3 = Theme.CheckboxHoverOff
                end
            end)
            IndCheck.MouseLeave:Connect(function()
                if not bindData.Indicator then
                    IndCheck.BackgroundColor3 = Theme.CheckboxOff
                end
            end)

            local IndCheckIcon = Instance.new("TextLabel")
            IndCheckIcon.Name = "Icon"
            IndCheckIcon.Size = UDim2.new(1, 0, 1, 0)
            IndCheckIcon.BackgroundTransparency = 1
            IndCheckIcon.FontFace = GuiIconsFont
            IndCheckIcon.Text = "X"
            IndCheckIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
            IndCheckIcon.TextSize = 11
            IndCheckIcon.TextXAlignment = Enum.TextXAlignment.Center
            IndCheckIcon.TextYAlignment = Enum.TextYAlignment.Center
            IndCheckIcon.Visible = bindData.Indicator
            IndCheckIcon.ZIndex = 133
            IndCheckIcon.Parent = IndCheck

            local IndLabel = Instance.new("TextButton")
            IndLabel.Name = "Label"
            IndLabel.Size = UDim2.new(0, 95, 1, 0)
            IndLabel.Position = UDim2.new(0, 20, 0, 0)
            IndLabel.BackgroundTransparency = 1
            IndLabel.Text = "Show indicator"
            IndLabel.TextColor3 = bindData.Indicator and Theme.TextActive or Theme.TextDim
            IndLabel.TextSize = 11
            IndLabel.Font = Theme.FontMedium
            IndLabel.TextXAlignment = Enum.TextXAlignment.Left
            IndLabel.AutoButtonColor = false
            IndLabel.ZIndex = 132
            IndLabel.Parent = Row1

            -- Row 2: TextBox for indicator text
            local Row2 = Instance.new("Frame")
            Row2.Name = "Row2_TextBox"
            Row2.Size = UDim2.new(1, 0, 0, 24)
            Row2.BackgroundColor3 = bindData.Indicator and Color3.fromRGB(18, 19, 22) or Color3.fromRGB(15, 16, 18)
            Row2.BorderSizePixel = 0
            Row2.LayoutOrder = 2
            Row2.ZIndex = 131
            Row2.Parent = BindPopover
            createCorner(Row2, 3)

            IndTextBox = Instance.new("TextBox")
            IndTextBox.Name = "Input"
            IndTextBox.Size = UDim2.new(1, -12, 1, 0)
            IndTextBox.Position = UDim2.new(0, 6, 0, 0)
            IndTextBox.BackgroundTransparency = 1
            IndTextBox.Text = bindData.IndicatorText or ""
            IndTextBox.TextEditable = bindData.Indicator
            IndTextBox.TextColor3 = bindData.Indicator and Theme.TextActive or Theme.TextDim
            IndTextBox.TextSize = 12
            IndTextBox.Font = Theme.FontMedium
            IndTextBox.TextXAlignment = Enum.TextXAlignment.Left
            IndTextBox.ClearTextOnFocus = false
            IndTextBox.PlaceholderText = ""
            IndTextBox.ZIndex = 132
            IndTextBox.Parent = Row2

            local IndRedLine = Instance.new("Frame")
            IndRedLine.Name = "RedLine"
            IndRedLine.Size = UDim2.new(1, 0, 0, 2)
            IndRedLine.Position = UDim2.new(0, 0, 1, -2)
            IndRedLine.BackgroundColor3 = Theme.Accent
            IndRedLine.BorderSizePixel = 0
            IndRedLine.Visible = false
            IndRedLine.ZIndex = 135
            IndRedLine.Parent = Row2
            createCorner(IndRedLine, 2)

            IndTextBox.Focused:Connect(function()
                if bindData.Indicator then
                    IndRedLine.Visible = true
                end
            end)

            IndTextBox.FocusLost:Connect(function()
                IndRedLine.Visible = false
                if bindData.Indicator then
                    bindData.IndicatorText = IndTextBox.Text
                end
            end)

            local function updateIndicatorState()
                IndCheck.BackgroundColor3 = bindData.Indicator and Theme.CheckboxChecked or Theme.CheckboxOff
                IndCheckIcon.Visible = bindData.Indicator
                IndLabel.TextColor3 = bindData.Indicator and Theme.TextActive or Theme.TextDim
                IndTextBox.TextEditable = bindData.Indicator
                IndTextBox.TextColor3 = bindData.Indicator and Theme.TextActive or Theme.TextDim
                Row2.BackgroundColor3 = bindData.Indicator and Color3.fromRGB(18, 19, 22) or Color3.fromRGB(15, 16, 18)
            end

            local function toggleIndicator()
                if os.clock() - lastPopoverDragTime < 0.12 then return end
                bindData.Indicator = not bindData.Indicator
                updateIndicatorState()
            end
            IndCheck.MouseButton1Click:Connect(toggleIndicator)
            IndLabel.MouseButton1Click:Connect(toggleIndicator)

            -- Green & Red Color Chips (Clickable -> OpenColorPicker)
            SwatchContainer = Instance.new("Frame")
            SwatchContainer.Name = "Swatches"
            SwatchContainer.Size = UDim2.new(0, 32, 0, 14)
            SwatchContainer.Position = UDim2.new(1, -32, 0.5, -7)
            SwatchContainer.BackgroundTransparency = 1
            SwatchContainer.ZIndex = 132
            SwatchContainer.Parent = Row1

            local SwatchLayout = Instance.new("UIListLayout")
            SwatchLayout.FillDirection = Enum.FillDirection.Horizontal
            SwatchLayout.Padding = UDim.new(0, 4)
            SwatchLayout.Parent = SwatchContainer

            local GreenChip = Instance.new("TextButton")
            GreenChip.Name = "Green"
            GreenChip.Size = UDim2.new(0, 14, 0, 14)
            GreenChip.BackgroundColor3 = bindData.ColorActive or Color3.fromRGB(255, 255, 255)
            GreenChip.BorderSizePixel = 0
            GreenChip.Text = ""
            GreenChip.AutoButtonColor = false
            GreenChip.ZIndex = 133
            GreenChip.Parent = SwatchContainer
            createCorner(GreenChip, 4.75)

            GreenChip.MouseButton1Click:Connect(function()
                Controls:OpenColorPicker(GreenChip, bindData.ColorActive or Color3.fromRGB(255, 255, 255), 1, function(newColor)
                    bindData.ColorActive = newColor
                    GreenChip.BackgroundColor3 = newColor
                    updateBindBtn()
                end)
            end)

            local RedChip = Instance.new("TextButton")
            RedChip.Name = "Red"
            RedChip.Size = UDim2.new(0, 14, 0, 14)
            RedChip.BackgroundColor3 = bindData.ColorInactive or Color3.fromRGB(255, 255, 255)
            RedChip.BorderSizePixel = 0
            RedChip.Text = ""
            RedChip.AutoButtonColor = false
            RedChip.ZIndex = 133
            RedChip.Parent = SwatchContainer
            createCorner(RedChip, 4.75)

            RedChip.MouseButton1Click:Connect(function()
                Controls:OpenColorPicker(RedChip, bindData.ColorInactive or Color3.fromRGB(255, 255, 255), 1, function(newColor)
                    bindData.ColorInactive = newColor
                    RedChip.BackgroundColor3 = newColor
                    updateBindBtn()
                end)
            end)
        end

        -- Row 3: "Type" Label + Dropdown (Strict ZIndex 150 to render on top of Row 4)
        local Row3 = Instance.new("Frame")
        Row3.Name = "Row3_Type"
        Row3.Size = UDim2.new(1, 0, 0, 24)
        Row3.BackgroundTransparency = 1
        Row3.LayoutOrder = 3
        Row3.ZIndex = 150
        Row3.Parent = BindPopover

        local TypeLabel = Instance.new("TextLabel")
        TypeLabel.Name = "Label"
        TypeLabel.Size = UDim2.new(0, 42, 1, 0)
        TypeLabel.Position = UDim2.new(0, 0, 0, 0)
        TypeLabel.BackgroundTransparency = 1
        TypeLabel.Text = "Type"
        TypeLabel.TextColor3 = Theme.TextActive
        TypeLabel.TextSize = 12
        TypeLabel.Font = Theme.FontMedium
        TypeLabel.TextXAlignment = Enum.TextXAlignment.Left
        TypeLabel.ZIndex = 151
        TypeLabel.Parent = Row3

        local TypeDropdown = Instance.new("Frame")
        TypeDropdown.Name = "Dropdown"
        TypeDropdown.Size = UDim2.new(1, -46, 1, 0)
        TypeDropdown.Position = UDim2.new(0, 46, 0, 0)
        TypeDropdown.BackgroundColor3 = Theme.DropdownBg
        TypeDropdown.BorderSizePixel = 0
        TypeDropdown.ZIndex = 151
        TypeDropdown.Parent = Row3
        createCorner(TypeDropdown, 3)
        createStroke(TypeDropdown, Theme.ControlBorder, 1)

        local TypeBottomCover = Instance.new("Frame")
        TypeBottomCover.Name = "BottomCover"
        TypeBottomCover.Size = UDim2.new(1, 0, 0, 4)
        TypeBottomCover.Position = UDim2.new(0, 0, 1, -4)
        TypeBottomCover.BackgroundColor3 = Theme.DropdownBg
        TypeBottomCover.BorderSizePixel = 0
        TypeBottomCover.Visible = false
        TypeBottomCover.ZIndex = 152
        TypeBottomCover.Parent = TypeDropdown

        local TypeText = Instance.new("TextLabel")
        TypeText.Name = "Text"
        TypeText.Size = UDim2.new(1, -20, 1, 0)
        TypeText.Position = UDim2.new(0, 6, 0, 0)
        TypeText.BackgroundTransparency = 1
        TypeText.Text = (bindData.Type == "Always on" and "Always On") or bindData.Type or "Always On"
        TypeText.TextColor3 = Theme.TextActive
        TypeText.TextSize = 11
        TypeText.Font = Theme.FontMedium
        TypeText.TextXAlignment = Enum.TextXAlignment.Left
        TypeText.ZIndex = 152
        TypeText.Parent = TypeDropdown

        TypeChevron = Instance.new("TextLabel")
        TypeChevron.Name = "Chevron"
        TypeChevron.Size = UDim2.new(0, 12, 0, 12)
        TypeChevron.Position = UDim2.new(1, -15, 0.5, -6)
        TypeChevron.BackgroundTransparency = 1
        TypeChevron.FontFace = GuiIconsFont
        TypeChevron.Text = "C"
        TypeChevron.TextColor3 = Color3.fromRGB(255, 255, 255)
        TypeChevron.TextSize = 12
        TypeChevron.TextXAlignment = Enum.TextXAlignment.Center
        TypeChevron.TextYAlignment = Enum.TextYAlignment.Center
        TypeChevron.ZIndex = 152
        TypeChevron.Parent = TypeDropdown

        local TypeTrigger = Instance.new("TextButton")
        TypeTrigger.Name = "Trigger"
        TypeTrigger.Size = UDim2.new(1, 0, 1, 0)
        TypeTrigger.BackgroundTransparency = 1
        TypeTrigger.Text = ""
        TypeTrigger.ZIndex = 153
        TypeTrigger.Parent = TypeDropdown

        TypeTrigger.MouseEnter:Connect(function()
            TypeDropdown.BackgroundColor3 = Color3.fromRGB(95, 102, 112)
            TypeBottomCover.BackgroundColor3 = TypeDropdown.BackgroundColor3
        end)
        TypeTrigger.MouseLeave:Connect(function()
            TypeDropdown.BackgroundColor3 = Theme.DropdownBg
            TypeBottomCover.BackgroundColor3 = TypeDropdown.BackgroundColor3
        end)

        TypePopover = Instance.new("Frame")
        TypePopover.Name = "TypePopover"
        TypePopover.Size = UDim2.new(1, 0, 0, 88)
        TypePopover.Position = UDim2.new(0, 0, 1, -1)
        TypePopover.BackgroundColor3 = Theme.DropdownBg
        TypePopover.BorderSizePixel = 0
        TypePopover.Visible = false
        TypePopover.ZIndex = 160
        TypePopover.Parent = TypeDropdown
        createCorner(TypePopover, 3)

        local TypePopTopCover = Instance.new("Frame")
        TypePopTopCover.Name = "TopCover"
        TypePopTopCover.Size = UDim2.new(1, 0, 0, 4)
        TypePopTopCover.Position = UDim2.new(0, 0, 0, 0)
        TypePopTopCover.BackgroundColor3 = Theme.DropdownBg
        TypePopTopCover.BorderSizePixel = 0
        TypePopTopCover.ZIndex = 160
        TypePopTopCover.Parent = TypePopover

        local TypePopContainer = Instance.new("Frame")
        TypePopContainer.Name = "ListContainer"
        TypePopContainer.Size = UDim2.new(1, 0, 1, 0)
        TypePopContainer.BackgroundTransparency = 1
        TypePopContainer.ZIndex = 161
        TypePopContainer.Parent = TypePopover

        local TypePopList = Instance.new("UIListLayout")
        TypePopList.SortOrder = Enum.SortOrder.LayoutOrder
        TypePopList.Padding = UDim.new(0, 1)
        TypePopList.Parent = TypePopContainer

        local typeOptions = { "Always On", "On key down", "Toggle", "Disable" }
        local function updateTypeOptionColors()
            for _, child in ipairs(TypePopContainer:GetChildren()) do
                if child:IsA("TextButton") then
                    local isSel = (child.Name == bindData.Type or (bindData.Type == "Always on" and child.Name == "Always On"))
                    child.BackgroundColor3 = Theme.DropdownBg
                    child.TextColor3 = isSel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 134, 145)
                    child.Font = isSel and Theme.FontBold or Theme.FontMedium
                end
            end
        end

        -- Row 4: Key Listener Button (Forward Declaration for updatePopoverLayout)
        local Row4 = Instance.new("Frame")
        Row4.Name = "Row4_Key"
        Row4.Size = UDim2.new(1, 0, 0, 24)
        Row4.BackgroundColor3 = Theme.DropdownBg
        Row4.BorderSizePixel = 0
        Row4.LayoutOrder = 4
        Row4.ZIndex = 131
        Row4.Parent = BindPopover
        createCorner(Row4, 3)

        local function updatePopoverLayout()
            local showKey = (bindData.Type ~= "Always On" and bindData.Type ~= "Always on" and bindData.Type ~= "Disable")
            Row4.Visible = showKey
            if hasIndicatorUI then
                BindPopover.Size = UDim2.new(0, 185, 0, showKey and 126 or 94)
            else
                BindPopover.Size = UDim2.new(0, 185, 0, showKey and 70 or 40)
            end
        end
        updatePopoverLayout()

        for optIdx, tOpt in ipairs(typeOptions) do
            local TBtn = Instance.new("TextButton")
            TBtn.Name = tOpt
            TBtn.LayoutOrder = optIdx
            TBtn.Size = UDim2.new(1, 0, 0, 21)
            local isSel = (tOpt == bindData.Type or (bindData.Type == "Always on" and tOpt == "Always On"))
            TBtn.BackgroundColor3 = Theme.DropdownBg
            TBtn.Text = "  " .. tOpt
            TBtn.TextColor3 = isSel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 134, 145)
            TBtn.TextSize = 11
            TBtn.Font = isSel and Theme.FontBold or Theme.FontMedium
            TBtn.TextXAlignment = Enum.TextXAlignment.Left
            TBtn.ZIndex = 162
            TBtn.AutoButtonColor = false
            TBtn.Parent = TypePopContainer
            createCorner(TBtn, 2)

            TBtn.MouseEnter:Connect(function()
                local isSel = (tOpt == bindData.Type or (bindData.Type == "Always on" and tOpt == "Always On"))
                if not isSel then
                    TBtn.TextColor3 = Color3.fromRGB(195, 200, 210)
                else
                    TBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                end
            end)
            TBtn.MouseLeave:Connect(function()
                local isSel = (tOpt == bindData.Type or (bindData.Type == "Always on" and tOpt == "Always On"))
                if not isSel then
                    TBtn.TextColor3 = Color3.fromRGB(130, 134, 145)
                else
                    TBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                end
            end)
            local function selectType()
                lastTypeSelectTime = os.clock()
                bindData.Type = tOpt
                TypeText.Text = tOpt
                updateTypeOptionColors()
                updateBindBtn()
                updatePopoverLayout()
                task.defer(function()
                    TypePopover.Visible = false
                    TypeBottomCover.Visible = false
                    TypeChevron.Text = "C"
                end)
            end
            TBtn.MouseButton1Down:Connect(selectType)
            TBtn.MouseButton1Click:Connect(selectType)
        end

        TypeTrigger.MouseButton1Click:Connect(function()
            TypePopover.Visible = not TypePopover.Visible
            TypeBottomCover.Visible = TypePopover.Visible
            TypeChevron.Text = TypePopover.Visible and "B" or "C"
            if TypePopover.Visible then
                updateTypeOptionColors()
            end
        end)

        local KeyBtn = Instance.new("TextButton")
        KeyBtn.Name = "KeyButton"
        KeyBtn.Size = UDim2.new(1, 0, 1, 0)
        KeyBtn.BackgroundTransparency = 1
        KeyBtn.Text = getKeyDisplayName(bindData.Key)
        KeyBtn.TextColor3 = Theme.TextActive
        KeyBtn.TextSize = 12
        KeyBtn.Font = Theme.FontMedium
        KeyBtn.AutoButtonColor = false
        KeyBtn.ZIndex = 132
        KeyBtn.Parent = Row4

        KeyBtn.MouseEnter:Connect(function()
            Row4.BackgroundColor3 = Color3.fromRGB(95, 102, 112)
        end)
        KeyBtn.MouseLeave:Connect(function()
            Row4.BackgroundColor3 = Theme.DropdownBg
        end)

        local listening = false
        local listenConn = nil

        KeyBtn.MouseButton1Click:Connect(function()
            if bindData.Key ~= nil then
                -- When pressed again, unbind back to [none]
                bindData.Key = nil
                KeyBtn.Text = "[none]"
                KeyBtn.TextColor3 = Theme.TextActive
                updateBindBtn()
                listening = false
                if listenConn then
                    listenConn:Disconnect()
                    listenConn = nil
                end
                return
            end

            if listening then return end
            listening = true
            KeyBtn.Text = "..."
            KeyBtn.TextColor3 = Color3.fromRGB(255, 215, 0) -- "..." in yellow

            listenConn = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Delete then
                        bindData.Key = nil
                        KeyBtn.Text = "[none]"
                        KeyBtn.TextColor3 = Theme.TextActive
                        updateBindBtn()
                    else
                        bindData.Key = input.KeyCode
                        KeyBtn.Text = string.lower(input.KeyCode.Name) -- keybind in lowercase e.g. "d"
                        KeyBtn.TextColor3 = Theme.TextActive
                        updateBindBtn()
                    end
                    listening = false
                    if listenConn then
                        listenConn:Disconnect()
                        listenConn = nil
                    end
                elseif input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
                    local name = (input.UserInputType == Enum.UserInputType.MouseButton2) and "m2" or "m3"
                    bindData.Key = name
                    KeyBtn.Text = name
                    KeyBtn.TextColor3 = Theme.TextActive
                    updateBindBtn()
                    listening = false
                    if listenConn then
                        listenConn:Disconnect()
                        listenConn = nil
                    end
                end
            end)
        end)

        makePopoverDraggable(BindPopover, function(pos)
            if hasIndicatorUI then
                if IndCheck and isPosInGui(IndCheck, pos) then return true end
                if SwatchContainer and isPosInGui(SwatchContainer, pos) then return true end
                if IndTextBox and isPosInGui(IndTextBox, pos) then return true end
            end
            if isPosInGui(TypeDropdown, pos) then return true end
            if TypePopover and isPosInGui(TypePopover, pos) then return true end
            if Row4.Visible and isPosInGui(KeyBtn, pos) then return true end
            return false
        end)

        local bindOutsideConn = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                if not BindPopover.Visible then return end
                if listening or (os.clock() - lastPopoverDragTime < 0.2) or (os.clock() - lastTypeSelectTime < 0.35) then return end
                local pos = input.Position
                if isPosInGui(BindPopover, pos) then return end
                if isPosInGui(BindBtn, pos) then return end
                if TypePopover and TypePopover.Visible and isPosInGui(TypePopover, pos, 6) then return end
                if ColorPickerModal and ColorPickerModal.Visible and isPosInGui(ColorPickerModal, pos) then return end
                BindPopover.Visible = false
                if TypePopover then TypePopover.Visible = false end
                if TypeBottomCover then TypeBottomCover.Visible = false end
                if TypeChevron then TypeChevron.Text = "C" end
            end
        end)
        table.insert(Connections, bindOutsideConn)

        -- Top-left of keybind popover opens where cursor is on bottom-right of keybind
        BindBtn.MouseButton1Click:Connect(function()
            local isOpen = BindPopover.Visible
            CloseAllPopups()
            if not isOpen then
                TypePopover.Visible = false
                if TypeBottomCover then TypeBottomCover.Visible = false end
                TypeChevron.Text = "C"

                updatePopoverLayout()

                local mousePos = getRealMousePos()
                local popX = mousePos.X + 4
                local popY = mousePos.Y - 2

                if mousePos.X <= 0 and mousePos.Y <= 0 then
                    local absPos = BindBtn.AbsolutePosition
                    popX = absPos.X + BindBtn.AbsoluteSize.X
                    popY = absPos.Y + BindBtn.AbsoluteSize.Y
                end

                local cam = workspace.CurrentCamera
                local viewSize = cam and cam.ViewportSize or Vector2.new(1920, 1080)
                popX = math.clamp(popX, 5, viewSize.X - 190)
                popY = math.clamp(popY, 5, viewSize.Y - (BindPopover.AbsoluteSize.Y + 10))
                BindPopover.Position = UDim2.new(0, popX, 0, popY)
                BindPopover.Visible = true
                if ModalBlocker then ModalBlocker.Visible = true end
            end
        end)

        updatePopoverLayout()

        keybindObj = {
            Set = function(k)
                bindData.Key = k
                KeyBtn.Text = getKeyDisplayName(k)
                KeyBtn.TextColor3 = Theme.TextActive
                updateBindBtn()
            end,
            Get = function() return bindData.Key end,
            GetData = function() return bindData end
        }
    end

    return {
        Set = updateState,
        Get = function() return state end,
        Keybind = keybindObj
    }
end

-- Slider (Label + Value on top, Track bar on bottom)
function Controls:CreateSlider(parent, config)
    local name = config.Name or "Slider"
    local min = config.Min or 0
    local max = config.Max or 100
    local default = math.clamp(config.Default or min, min, max)
    local decimals = config.Decimals or 0
    local zeroText = config.ZeroText
    local suffix = config.Suffix or ""
    if suffix == "disabled" then
        zeroText = "disabled"
        suffix = config.Unit or ""
    end
    local callback = config.Callback
    local order = config.LayoutOrder or 0
    local isEnabled = (config.Enabled ~= false)

    local SliderContainer = Instance.new("Frame")
    SliderContainer.Name = name .. "_Slider"
    SliderContainer.Size = UDim2.new(1, -6, 0, 32)
    SliderContainer.BackgroundTransparency = 1
    SliderContainer.LayoutOrder = order
    SliderContainer.Parent = parent

    -- Top Row: Label on left, Value on right
    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Size = UDim2.new(0.65, 0, 0, 16)
    Label.Position = UDim2.new(0, 4, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Theme.TextActive
    Label.TextSize = 12
    Label.Font = Theme.FontBold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = SliderContainer

    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Name = "Value"
    ValueLabel.Size = UDim2.new(0.35, -8, 0, 16)
    ValueLabel.Position = UDim2.new(0.65, 0, 0, 0)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.TextColor3 = Theme.TextActive
    ValueLabel.TextSize = 12
    ValueLabel.Font = Theme.FontBold
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValueLabel.Parent = SliderContainer

    -- Bottom Row: Track & Fill bar
    local Track = Instance.new("Frame")
    Track.Name = "Track"
    Track.Size = UDim2.new(1, -8, 0, 3)
    Track.Position = UDim2.new(0, 4, 0, 22)
    Track.BackgroundColor3 = Theme.SliderTrack
    Track.BorderSizePixel = 0
    Track.Parent = SliderContainer
    createCorner(Track, 2)

    local Fill = Instance.new("Frame")
    Fill.Name = "Fill"
    Fill.Size = UDim2.new(0, 0, 1, 0)
    Fill.BackgroundColor3 = Theme.SliderFill
    Fill.BorderSizePixel = 0
    Fill.Parent = Track
    createCorner(Fill, 2)

    local function formatValue(val)
        if zeroText and (val == 0 or math.abs(val) < 0.0001 or (min == 0 and val == min)) then
            return zeroText
        end
        local sep = (suffix == "s" and decimals == 0) and "" or ((suffix ~= "" and suffix ~= "°" and suffix ~= "%") and " " or "")
        if decimals > 0 then
            local fmt = string.format("%%.%df", decimals)
            return string.format(fmt, val) .. (suffix ~= "" and (sep .. suffix) or "")
        else
            return string.format("%d", math.round(val)) .. (suffix ~= "" and (sep .. suffix) or "")
        end
    end

    local currentValue = default
    local function setSlider(val)
        currentValue = math.clamp(val, min, max)
        local pct = (max == min) and 0 or math.clamp((currentValue - min) / (max - min), 0, 1)
        Fill.Size = UDim2.new(pct, 0, 1, 0)
        ValueLabel.Text = formatValue(currentValue)
        if callback then
            pcall(callback, currentValue)
        end
    end

    local function setEnabled(state)
        isEnabled = state
        if isEnabled then
            Label.TextColor3 = Theme.TextActive
            ValueLabel.TextColor3 = Theme.TextSub
            Fill.BackgroundColor3 = Theme.SliderFill
        else
            Label.TextColor3 = Theme.TextDim
            ValueLabel.TextColor3 = Theme.TextDim
            Fill.BackgroundColor3 = Color3.fromRGB(55, 57, 65)
        end
    end
    setEnabled(isEnabled)

    setSlider(default)

    -- Mouse dragging
    local sliding = false
    local function updateFromInput(input)
        local posX = input.Position.X
        local trackStart = Track.AbsolutePosition.X
        local trackWidth = Track.AbsoluteSize.X
        local pct = math.clamp((posX - trackStart) / trackWidth, 0, 1)
        local factor = 10 ^ decimals
        local raw = min + (max - min) * pct
        local rounded = math.round(raw * factor) / factor
        setSlider(rounded)
    end

    Track.InputBegan:Connect(function(input)
        if not isEnabled then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            updateFromInput(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromInput(input)
        end
    end)

    return {
        Set = setSlider,
        Get = function() return currentValue end,
        SetEnabled = setEnabled
    }
end

-- Dropdown Selector (Single Choice)
function Controls:CreateDropdown(parent, config)
    local name = config.Name or "Dropdown"
    local options = config.Options or {}
    local current = config.Default or options[1] or ""
    local callback = config.Callback
    local order = config.LayoutOrder or 0

    local DropdownContainer = Instance.new("Frame")
    DropdownContainer.Name = name .. "_Dropdown"
    DropdownContainer.Size = UDim2.new(1, -6, 0, 26)
    DropdownContainer.BackgroundTransparency = 1
    DropdownContainer.LayoutOrder = order
    DropdownContainer.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Size = UDim2.new(0.5, 0, 1, 0)
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
    Box.Size = UDim2.new(0.48, 0, 1, 0)
    Box.Position = UDim2.new(0.52, -4, 0, 0)
    Box.BackgroundColor3 = Theme.DropdownBg
    Box.Parent = DropdownContainer
    createCorner(Box, 3)
    createStroke(Box, Theme.ControlBorder, 1)


    local SelectedLabel = Instance.new("TextLabel")
    SelectedLabel.Name = "Selected"
    SelectedLabel.Size = UDim2.new(1, -22, 1, 0)
    SelectedLabel.Position = UDim2.new(0, 8, 0, 0)
    SelectedLabel.BackgroundTransparency = 1
    SelectedLabel.Text = current
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

    -- Unified "Bigger Dropdown" Popover (starts from opener top, covering it seamlessly)
    local Popover = Instance.new("Frame")
    Popover.Name = name .. "_Popover"
    Popover.Size = UDim2.new(0, 120, 0, 26 + math.min(#options * 24 + 6, 140))
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
    PopHeaderLabel.Text = current
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

    local function selectOption(opt)
        current = opt
        SelectedLabel.Text = opt
        PopHeaderLabel.Text = opt
        Popover.Visible = false
        Chevron.Text = "C"
        if ModalBlocker then ModalBlocker.Visible = false end
        if callback then
            pcall(callback, opt)
        end
    end

    local function buildOptions()
        for _, c in ipairs(ScrollList:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for optIdx, opt in ipairs(options) do
            local OptBtn = Instance.new("TextButton")
            OptBtn.Name = opt
            OptBtn.LayoutOrder = optIdx
            OptBtn.Size = UDim2.new(1, 0, 0, 22)
            local isSel = (opt == current)
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
                if opt ~= current then
                    OptBtn.TextColor3 = Color3.fromRGB(195, 200, 210)
                end
            end)
            OptBtn.MouseLeave:Connect(function()
                if opt ~= current then
                    OptBtn.TextColor3 = Color3.fromRGB(130, 134, 145)
                end
            end)
            OptBtn.MouseButton1Click:Connect(function()
                selectOption(opt)
            end)
        end
    end
    buildOptions()

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
            PopHeaderLabel.Text = current
            PopChevron.Visible = true
            PopChevron.Text = "B"
            PopHeaderBtn.Visible = true
            ScrollList.Position = UDim2.new(0, 0, 0, absSize.Y)
            ScrollList.Size = UDim2.new(1, 0, 1, -absSize.Y)
            ScrollList.CanvasSize = UDim2.new(0, 0, 0, #options * 23 + 6)
            Popover.Visible = true
            Chevron.Text = "B"
            buildOptions()
            if ModalBlocker then ModalBlocker.Visible = true end
        else
            Popover.Visible = false
            Chevron.Text = "C"
        end
    end)

    return {
        Set = selectOption,
        Get = function() return current end
    }
end

-- Multi-Select Dropdown (Checkbox list)
function Controls:CreateMultiDropdown(parent, config)
    local name = config.Name or "MultiDropdown"
    local options = config.Options or {}
    local selected = config.Default or {}
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
    SelectedLabel.Text = "None"
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

    -- Unified "Bigger Dropdown" Popover (starts from opener top, covering it seamlessly)
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
        local res = (#list == 0) and "None" or table.concat(list, ", ")
        SelectedLabel.Text = res
        PopHeaderLabel.Text = res
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
                end
            end)
            OptBtn.MouseLeave:Connect(function()
                if not selected[opt] then
                    OptBtn.TextColor3 = Color3.fromRGB(130, 134, 145)
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
            if ModalBlocker then ModalBlocker.Visible = true end
        else
            Popover.Visible = false
            Chevron.Text = "C"
        end
    end)

    return {
        Get = function() return selected end
    }
end

-- Dual-Option Filter Tabs (e.g. Visible vs Auto wall)
function Controls:CreateDualFilter(parent, config)
    local opt1 = config.Option1 or "Visible"
    local opt2 = config.Option2 or "Auto wall"
    local callback = config.Callback
    local order = config.LayoutOrder or 0

    local Row = Instance.new("Frame")
    Row.Name = "DualFilter"
    Row.Size = UDim2.new(1, -6, 0, 24)
    Row.BackgroundTransparency = 1
    Row.LayoutOrder = order
    Row.Parent = parent

    local Btn1 = Instance.new("TextButton")
    Btn1.Name = opt1
    Btn1.Size = UDim2.new(0.5, -2, 1, 0)
    Btn1.Position = UDim2.new(0, 0, 0, 0)
    Btn1.BackgroundTransparency = 1
    Btn1.Text = opt1
    Btn1.TextColor3 = Theme.TextActive
    Btn1.TextSize = 12
    Btn1.Font = Theme.FontMedium
    Btn1.TextXAlignment = Enum.TextXAlignment.Left
    Btn1.Parent = Row

    local Btn2 = Instance.new("TextButton")
    Btn2.Name = opt2
    Btn2.Size = UDim2.new(0.5, -2, 1, 0)
    Btn2.Position = UDim2.new(0.5, 2, 0, 0)
    Btn2.BackgroundTransparency = 1
    Btn2.Text = opt2
    Btn2.TextColor3 = Theme.TextDim
    Btn2.TextSize = 12
    Btn2.Font = Theme.FontMedium
    Btn2.TextXAlignment = Enum.TextXAlignment.Right
    Btn2.Parent = Row

    local active = opt1
    local function select(opt)
        active = opt
        if opt == opt1 then
            Btn1.TextColor3 = Theme.TextActive
            Btn2.TextColor3 = Theme.TextDim
        else
            Btn1.TextColor3 = Theme.TextDim
            Btn2.TextColor3 = Theme.TextActive
        end
        if callback then pcall(callback, active) end
    end

    Btn1.MouseButton1Click:Connect(function() select(opt1) end)
    Btn2.MouseButton1Click:Connect(function() select(opt2) end)

    return {
        Get = function() return active end,
        Set = select
    }
end

-- Sub-Tabs Filter (e.g. Aim / Accuracy / RCS / Misc on Legitbot)
function Controls:CreateSubTabs(parent, options, defaultOpt, order, callback)
    local Container = Instance.new("Frame")
    Container.Name = "SubTabs"
    Container.Size = UDim2.new(1, -6, 0, 22)
    Container.BackgroundTransparency = 1
    Container.LayoutOrder = order or 0
    Container.Parent = parent

    local Pad = Instance.new("UIPadding")
    Pad.PaddingLeft = UDim.new(0, 4)
    Pad.PaddingRight = UDim.new(0, 4)
    Pad.Parent = Container

    local Layout = Instance.new("UIListLayout")
    Layout.FillDirection = Enum.FillDirection.Horizontal
    Layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    Layout.VerticalAlignment = Enum.VerticalAlignment.Center
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Padding = UDim.new(0, 32)
    pcall(function()
        Layout.HorizontalFlex = Enum.UIFlexAlignment.SpaceBetween
        Layout.Padding = UDim.new(0, 0)
    end)
    Layout.Parent = Container

    local active = defaultOpt or options[1]
    local buttons = {}

    local function updateVisuals()
        for opt, btn in pairs(buttons) do
            local isSel = (opt == active)
            btn.TextColor3 = isSel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 134, 145)
            btn.Font = isSel and Theme.FontBold or Theme.FontMedium
        end
    end

    for optIdx, opt in ipairs(options) do
        local TabBtn = Instance.new("TextButton")
        TabBtn.Name = opt
        TabBtn.LayoutOrder = optIdx
        TabBtn.AutomaticSize = Enum.AutomaticSize.X
        TabBtn.Size = UDim2.new(0, 0, 1, 0)
        TabBtn.BackgroundTransparency = 1
        TabBtn.Text = opt
        local isSel = (opt == active)
        TabBtn.TextColor3 = isSel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 134, 145)
        TabBtn.TextSize = 12
        TabBtn.Font = isSel and Theme.FontBold or Theme.FontMedium
        TabBtn.AutoButtonColor = false
        TabBtn.Parent = Container

        buttons[opt] = TabBtn

        TabBtn.MouseEnter:Connect(function()
            if opt ~= active then
                TabBtn.TextColor3 = Color3.fromRGB(200, 205, 215)
            end
        end)
        TabBtn.MouseLeave:Connect(function()
            if opt ~= active then
                TabBtn.TextColor3 = Color3.fromRGB(130, 134, 145)
            end
        end)

        TabBtn.MouseButton1Click:Connect(function()
            active = opt
            updateVisuals()
            if callback then pcall(callback, active) end
        end)
    end

    return {
        Get = function() return active end,
        Set = function(opt)
            active = opt
            updateVisuals()
            if callback then pcall(callback, active) end
        end
    }
end

-- Dual Toggle on Same Row (e.g. Auto stop + Auto scope)
function Controls:CreateDualToggle(parent, config1, config2, order)
    local Row = Instance.new("Frame")
    Row.Name = "DualToggleRow"
    Row.Size = UDim2.new(1, -6, 0, 22)
    Row.BackgroundTransparency = 1
    Row.LayoutOrder = order or 0
    Row.Parent = parent

    local function makeSingle(cfg, posX)
        local cName = cfg.Name or "Toggle"
        local cDef = false
        local cState = false

        local SubBox = Instance.new("TextButton")
        SubBox.Name = "Box"
        SubBox.Size = UDim2.new(0, 16, 0, 16)
        SubBox.Position = UDim2.new(posX, 4, 0.5, -8)
        SubBox.BackgroundColor3 = cDef and Theme.CheckboxChecked or Theme.CheckboxOff
        SubBox.BorderSizePixel = 0
        SubBox.AutoButtonColor = false
        SubBox.Text = ""
        SubBox.Parent = Row
        createCorner(SubBox, 3)

        local SubCheck = Instance.new("TextLabel")
        SubCheck.Name = "Check"
        SubCheck.Size = UDim2.new(1, 0, 1, 0)
        SubCheck.BackgroundTransparency = 1
        SubCheck.FontFace = GuiIconsFont
        SubCheck.Text = "X"
        SubCheck.TextColor3 = Color3.fromRGB(255, 255, 255)
        SubCheck.TextSize = 13
        SubCheck.TextXAlignment = Enum.TextXAlignment.Center
        SubCheck.TextYAlignment = Enum.TextYAlignment.Center
        SubCheck.Visible = cDef
        SubCheck.Parent = SubBox

        local SubLabel = Instance.new("TextButton")
        SubLabel.Name = "Label"
        SubLabel.Size = UDim2.new(0.48, -26, 1, 0)
        SubLabel.Position = UDim2.new(posX, 26, 0, 0)
        SubLabel.BackgroundTransparency = 1
        SubLabel.Text = cName
        SubLabel.TextColor3 = cDef and Theme.TextActive or Theme.TextDim
        SubLabel.TextSize = 12
        SubLabel.Font = Theme.FontBold
        SubLabel.TextXAlignment = Enum.TextXAlignment.Left
        SubLabel.AutoButtonColor = false
        SubLabel.Parent = Row

        local function update(val)
            cState = val
            if cState then
                SubBox.BackgroundColor3 = Theme.CheckboxChecked
                SubCheck.Visible = true
                SubLabel.TextColor3 = Theme.TextActive
            else
                SubBox.BackgroundColor3 = Theme.CheckboxOff
                SubCheck.Visible = false
                SubLabel.TextColor3 = Theme.TextDim
            end
            if cfg.Callback then pcall(cfg.Callback, cState) end
        end

        SubBox.MouseButton1Click:Connect(function() update(not cState) end)
        SubLabel.MouseButton1Click:Connect(function() update(not cState) end)
    end

    makeSingle(config1, 0)
    makeSingle(config2, 0.50)
end

-- Matrix Header Tooltip ("Box", "Text", "Icon", "Distance")
local MatrixTooltip = Instance.new("Frame")
MatrixTooltip.Name = "MatrixTooltip"
MatrixTooltip.BackgroundColor3 = Color3.fromRGB(19, 20, 24)
MatrixTooltip.BorderSizePixel = 0
MatrixTooltip.AutomaticSize = Enum.AutomaticSize.XY
MatrixTooltip.Visible = false
MatrixTooltip.ZIndex = 600
MatrixTooltip.Parent = PopupsLayer
createCorner(MatrixTooltip, 2)

local mtPadding = Instance.new("UIPadding")
mtPadding.PaddingTop = UDim.new(0, 3)
mtPadding.PaddingBottom = UDim.new(0, 3)
mtPadding.PaddingLeft = UDim.new(0, 6)
mtPadding.PaddingRight = UDim.new(0, 6)
mtPadding.Parent = MatrixTooltip

local mtLabel = Instance.new("TextLabel")
mtLabel.Name = "Label"
mtLabel.BackgroundTransparency = 1
mtLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
mtLabel.TextSize = 11
mtLabel.Font = Theme.FontBold
mtLabel.AutomaticSize = Enum.AutomaticSize.XY
mtLabel.TextXAlignment = Enum.TextXAlignment.Center
mtLabel.TextYAlignment = Enum.TextYAlignment.Center
mtLabel.Parent = MatrixTooltip

table.insert(ActivePopups, MatrixTooltip)

local activeTooltipTarget = nil

local function updateMatrixTooltipPos()
    if not activeTooltipTarget or not MatrixTooltip.Visible then return end
    local m = getRealMousePos()
    local cam = workspace.CurrentCamera
    local viewSize = cam and cam.ViewportSize or Vector2.new(1920, 1080)
    local posX = m.X + 14
    local posY = m.Y
    if posX + 70 > viewSize.X then
        posX = m.X - 70
    end
    MatrixTooltip.AnchorPoint = Vector2.new(0, 0.5)
    MatrixTooltip.Position = UDim2.new(0, posX, 0, posY)
end

local function showMatrixTooltip(targetGui, text)
    activeTooltipTarget = targetGui
    mtLabel.Text = text
    updateMatrixTooltipPos()
    MatrixTooltip.Visible = true
end

local function hideMatrixTooltip(targetGui)
    if not targetGui or activeTooltipTarget == targetGui then
        activeTooltipTarget = nil
        MatrixTooltip.Visible = false
    end
end

local mtMoveConn = UserInputService.InputChanged:Connect(function(input)
    if activeTooltipTarget and MatrixTooltip.Visible and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateMatrixTooltipPos()
    end
end)
table.insert(Connections, mtMoveConn)

local MatrixColNames = {
    B = "Box",
    T = "Text",
    I = "Icon",
    D = "Distance"
}

-- Items Matrix Header ("B  T  I  D")
function Controls:CreateMatrixHeader(parent, order)
    local Row = Instance.new("Frame")
    Row.Name = "MatrixHeader"
    Row.Size = UDim2.new(1, -6, 0, 18)
    Row.BackgroundTransparency = 1
    Row.LayoutOrder = order or 0
    Row.Parent = parent

    local cols = { "B", "T", "I", "D" }
    for i, col in ipairs(cols) do
        local Lbl = Instance.new("TextButton")
        Lbl.Name = col
        Lbl.Size = UDim2.new(0, 18, 1, 0)
        Lbl.Position = UDim2.new(1, -((4 - i + 1) * 22) + 2, 0, 0)
        Lbl.BackgroundTransparency = 1
        Lbl.Text = col
        Lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        Lbl.TextSize = 12
        Lbl.Font = Theme.FontBold
        Lbl.TextXAlignment = Enum.TextXAlignment.Center
        Lbl.AutoButtonColor = false
        Lbl.Parent = Row

        Lbl.MouseEnter:Connect(function()
            showMatrixTooltip(Lbl, MatrixColNames[col])
        end)
        Lbl.MouseMoved:Connect(function()
            if activeTooltipTarget == Lbl then
                updateMatrixTooltipPos()
            end
        end)
        Lbl.MouseLeave:Connect(function()
            hideMatrixTooltip(Lbl)
        end)
    end
end

-- Items Matrix Row (Label + 4 Checkboxes)
function Controls:CreateMatrixRow(parent, config)
    local name = config.Name or "Item"
    local states = {
        B = false,
        T = false,
        I = false,
        D = false
    }
    local baseColor = config.Color or Color3.fromRGB(255, 255, 255)
    local boxColors = {
        B = baseColor,
        T = baseColor,
        I = baseColor,
        D = baseColor
    }
    local order = config.LayoutOrder or 0

    local Row = Instance.new("Frame")
    Row.Name = name .. "_MatrixRow"
    Row.Size = UDim2.new(1, -6, 0, 20)
    Row.BackgroundTransparency = 1
    Row.LayoutOrder = order
    Row.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Size = UDim2.new(1, -95, 1, 0)
    Label.Position = UDim2.new(0, 4, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = (states.B or states.T or states.I or states.D) and Color3.fromRGB(255, 255, 255) or Theme.TextDim
    Label.TextSize = 12
    Label.Font = Theme.FontBold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Row

    local cols = { "B", "T", "I", "D" }
    for i, col in ipairs(cols) do
        local Box = Instance.new("TextButton")
        Box.Name = col
        Box.Size = UDim2.new(0, 15, 0, 15)
        Box.Position = UDim2.new(1, -((4 - i + 1) * 22) + 4, 0.5, -7)
        Box.BackgroundColor3 = states[col] and boxColors[col] or Theme.CheckboxOff
        Box.BorderSizePixel = 0
        Box.AutoButtonColor = false
        Box.Text = ""
        Box.Parent = Row
        createCorner(Box, 4.75)

        Box.MouseButton1Click:Connect(function()
            states[col] = not states[col]
            Box.BackgroundColor3 = states[col] and boxColors[col] or Theme.CheckboxOff
            local anyActive = (states.B or states.T or states.I or states.D)
            Label.TextColor3 = anyActive and Color3.fromRGB(255, 255, 255) or Theme.TextDim
            if config.Callback then pcall(config.Callback, col, states[col], boxColors[col]) end
        end)

        Box.MouseButton2Click:Connect(function()
            Controls:OpenColorPicker(Box, boxColors[col], 1, function(newColor, newAlpha)
                boxColors[col] = newColor
                if states[col] then
                    Box.BackgroundColor3 = newColor
                end
                if config.ColorCallback then
                    pcall(config.ColorCallback, col, newColor, newAlpha)
                end
            end)
        end)
    end
end

-- Text Input Box (e.g. Player name input on Misc tab)
function Controls:CreateTextInput(parent, config)
    local placeholder = config.Placeholder or "Enter text..."
    local default = config.Default or ""
    local callback = config.Callback
    local order = config.LayoutOrder or 0

    local Frame = Instance.new("Frame")
    Frame.Name = "TextInputFrame"
    Frame.Size = UDim2.new(1, -6, 0, 26)
    Frame.BackgroundColor3 = Theme.DropdownBg
    Frame.BorderSizePixel = 0
    Frame.LayoutOrder = order
    Frame.Parent = parent
    createCorner(Frame, 3)
    createStroke(Frame, Theme.ControlBorder, 1)

    local RedLine = Instance.new("Frame")
    RedLine.Name = "RedLine"
    RedLine.Size = UDim2.new(1, 0, 0, 2)
    RedLine.Position = UDim2.new(0, 0, 1, -2)
    RedLine.BackgroundColor3 = Theme.Accent
    RedLine.BorderSizePixel = 0
    RedLine.Visible = false
    RedLine.ZIndex = 5
    RedLine.Parent = Frame
    createCorner(RedLine, 2)

    local Box = Instance.new("TextBox")
    Box.Name = "Input"
    Box.Size = UDim2.new(1, -12, 1, 0)
    Box.Position = UDim2.new(0, 8, 0, 0)
    Box.BackgroundTransparency = 1
    Box.Text = default
    Box.PlaceholderText = placeholder
    Box.PlaceholderColor3 = Color3.fromRGB(110, 114, 125)
    Box.TextColor3 = Theme.TextActive
    Box.TextSize = 12
    Box.Font = Theme.FontMedium
    Box.TextXAlignment = Enum.TextXAlignment.Left
    Box.ClearTextOnFocus = false
    Box.ZIndex = 6
    Box.Parent = Frame

    Box.Focused:Connect(function()
        RedLine.Visible = true
    end)

    Box.FocusLost:Connect(function()
        RedLine.Visible = false
        if callback then pcall(callback, Box.Text) end
    end)

    return {
        Get = function() return Box.Text end,
        Set = function(val) Box.Text = val end
    }
end

-- Push Button (e.g. "Unload cheat" on Misc tab, "Apply changes" on Inventory)
function Controls:CreateButton(parent, config)
    local text = config.Name or config.Text or "Button"
    local callback = config.Callback
    local order = config.LayoutOrder or 0

    local Btn = Instance.new("TextButton")
    Btn.Name = text .. "_Btn"
    Btn.Size = UDim2.new(1, -6, 0, 26)
    Btn.BackgroundColor3 = Theme.DropdownBg
    Btn.BorderSizePixel = 0
    Btn.AutoButtonColor = false
    Btn.Text = text
    Btn.TextColor3 = Theme.TextActive
    Btn.TextSize = 12
    Btn.Font = Theme.FontBold
    Btn.LayoutOrder = order
    Btn.Parent = parent
    createCorner(Btn, 3)
    createStroke(Btn, Theme.ControlBorder, 1)

    Btn.MouseEnter:Connect(function()
        Btn.BackgroundColor3 = Color3.fromRGB(95, 102, 112)
    end)
    Btn.MouseLeave:Connect(function()
        Btn.BackgroundColor3 = Theme.DropdownBg
    end)
    Btn.MouseButton1Click:Connect(function()
        if callback then pcall(callback) end
    end)

    return Btn
end

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                           LIBRARY API DEFINITION                          ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

local Library = {
    Theme = Theme,
    Tabs = Tabs,
    Controls = Controls,
    MainWindow = MainWindow,
    ScreenGui = ScreenGui,
    Container = Container,
    PopupsLayer = PopupsLayer,
    ActivePopups = ActivePopups,
    TabIconGlyphs = TabIconGlyphs,
    CommonIcons = CommonIcons,
    GuiIconsFont = GuiIconsFont
}

function Library:CreateTab(name, orderIndex)
    return CreateTab(name, orderIndex)
end

function Library:SelectTab(name)
    return SelectTab(name)
end

function Library:CloseAllPopups(preservePredicate)
    return CloseAllPopups(preservePredicate)
end

function Library:SetTabGlyphs(glyphsTable)
    for tName, glyph in pairs(glyphsTable) do
        TabIconGlyphs[tName] = glyph
        if Tabs[tName] and Tabs[tName].Icon then
            Tabs[tName].Icon.Text = glyph
        end
    end
end

function Library:CreateWindow(config)
    return Library
end

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                       MENU TOGGLE & CLEANUP SYSTEM                        ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

do
    local MenuVisible = true

    local CameraController = nil
    local function getCameraController()
        if CameraController then return CameraController end
        pcall(function()
    local function updateMouseLock(menuOpen)
        pcall(function()
            if menuOpen then
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                UserInputService.MouseIconEnabled = true
            else
                UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
                UserInputService.MouseIconEnabled = false
            end
        end)
    end

    -- Initial mouse unlock on execution since Menu starts visible
    updateMouseLock(true)

    -- Guard mouse unlock while menu is visible
    local MouseLockConn = RunService.RenderStepped:Connect(function()
        if MenuVisible then
            pcall(function()
                if UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default then
                    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                end
                if not UserInputService.MouseIconEnabled then
                    UserInputService.MouseIconEnabled = true
                end
            end)
        end
    end)
    table.insert(Connections, MouseLockConn)

    local function setMenuVisible(visible)
        if visible == MenuVisible then return end
        MenuVisible = visible
        updateMouseLock(visible)

        if not visible then
            pcall(CloseAllPopups)
            pcall(function()
                MainWindow.Visible = false
                BgOverlay.Visible = false
                PopupsLayer.Visible = false
                ScreenGui.Enabled = false
            end)
        else
            pcall(function()
                ScreenGui.Enabled = true
                MainWindow.Visible = true
                BgOverlay.Visible = true
                PopupsLayer.Visible = true
            end)
        end
    end

    local ToggleConn = UserInputService.InputBegan:Connect(function(input, processed)
        if input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.RightControl then
            setMenuVisible(not MenuVisible)
        end
        -- Close dropdowns on outside click
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
                    if draggingSV or draggingHue or draggingAlpha then return end
                    local mousePos = UserInputService:GetMouseLocation()
                    local clickedOnPopup = false
                    for _, item in ipairs(ActivePopups) do
                        local frame = (typeof(item) == "table") and item.Frame or item
                        if frame and frame:IsA("GuiObject") and frame.Visible then
                            if isPosInGui(frame, mousePos, 6) then
                                clickedOnPopup = true
                                break
                            end
                        end
                    end
                    if not clickedOnPopup and not (os.clock() - lastPopoverDragTime < 0.2) and not (draggingSV or draggingHue or draggingAlpha) then
                        CloseAllPopups()
                    end
                end)
            end
        end
    end)
    table.insert(Connections, ToggleConn)

    -- Spawning Mechanics Guard: ensure menu and mouse unlock persist across character spawns
    local charAddedConn = LocalPlayer.CharacterAdded:Connect(function()
        task.defer(function()
            if MenuVisible then
                pcall(function()
                    ScreenGui.Enabled = true
                    MainWindow.Visible = true
                    BgOverlay.Visible = true
                    PopupsLayer.Visible = true
                    updateMouseLock(true)
                end)
            end
        end)
    end)
    table.insert(Connections, charAddedConn)

    getgenv().MemeSenseCleanup = function()
        for _, conn in ipairs(Connections) do
            pcall(function() conn:Disconnect() end)
        end
        table.clear(Connections)
        if getgenv().MemeSenseGui and getgenv().MemeSenseGui.Parent then
            pcall(function() getgenv().MemeSenseGui:Destroy() end)
        end
        if getgenv().MemeSenseContainer and getgenv().MemeSenseContainer.Parent then
            pcall(function() getgenv().MemeSenseContainer:Destroy() end)
        end
    end

    -- Final sweep: ensure every instance in the hierarchy has an obfuscated symbol name
    pcall(function()
        for _, desc in ipairs(Container:GetDescendants()) do
            pcall(function()
                desc.Name = GetRandomSymbolString(math.random(14, 20))
            end)
        end
    end)

    function Library:Toggle(val)
        local target = (val ~= nil) and val or (not MenuVisible)
        setMenuVisible(target)
    end

    function Library:Ready()
        pcall(function()
            for _, desc in ipairs(Container:GetDescendants()) do
                pcall(function()
                    desc.Name = GetRandomSymbolString(math.random(14, 20))
                end)
            end
        end)
        if not ActiveTab and Tabs["Aim Assist"] then
            SelectTab("Aim Assist")
        end
    end

    Library.Cleanup = getgenv().MemeSenseCleanup
end

getgenv().MemeSenseLibrary = Library
return Library
