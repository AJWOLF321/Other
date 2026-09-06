--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                     KITTYWARE | MODULAR LUAU UI LIBRARY                   ║
    ║                  High-Performance Object-Oriented Framework               ║
    ║             Inspired by Neverlose: Pixel-Perfect & Smooth Tweens          ║
    ╚═══════════════════════════════════════════════════════════════════════════╝

    ENGINEERING & ARCHITECTURE HIGHLIGHTS:
    -----------------------------------------------------------------------------
    1. Custom UI Pathing:
       - Library:CreateWindow accepts a `Parent` configuration parameter.
       - If Parent is a ScreenGui, the menu parents directly into it.
       - If Parent is a Folder, CoreGui, or custom container, an anonymous
         ScreenGui is automatically generated and parented to that target.
       - Never hardcoded to CoreGui or PlayerGui.

    2. Non-Clipping Z-Index Overlay Popup Engine:
       - In standard Roblox UI hierarchies, child elements inside ScrollingFrames
         or Section containers with ClipsDescendants = true will clip expanded
         dropdowns and color pickers, or get layered behind lower sibling frames.
       - KittyWare permanently eliminates this via a dedicated, top-level
         `PopupOverlay` container (ZIndex = 9000, ClipsDescendants = false).
       - When a Dropdown or ColorPicker is toggled, its screen-space coordinates
         are mapped to the overlay, rendering completely free from clipping.
       - A global, event-driven listener dismisses active popups when clicking outside.

    3. Smooth Mouse-Delta Drag Mathematics:
       - Rather than absolute cursor-position snapping (which produces micro-jitter
         and latency across different refresh rates), the title bar uses mouse delta math:
         TargetPosition = startPosition + (inputPosition - dragStartPosition)
       - The target position is interpolated using TweenService (Quad Out, 0.06s),
         ensuring buttery-smooth dragging with zero frame drops.

    4. Pure Event-Driven Transitions:
       - Zero `while wait()` loops.
       - All interactions (switches, sliders, hover effects, scale animations) are
         driven strictly by UserInputService, TweenService, and RenderStepped.
       - Connections are registered in an internal connection pool for automatic
         disconnection and memory leak prevention upon cleanup.
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                         CENTRAL THEME SYSTEM                              ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
    Matches the KittyWare Watermark & Keybind List palette.
    Fully customizable at runtime via Library.Theme or CreateWindow({ Theme = ... })
]]

local Theme = {
    Background   = Color3.fromRGB(10, 11, 13),      -- Main window dark body
    Sidebar      = Color3.fromRGB(17, 17, 19),      -- Tab navigation sidebar
    Header       = Color3.fromRGB(13, 13, 15),      -- Titlebar & sub-headers
    Section      = Color3.fromRGB(13, 14, 16),      -- Content groupbox cards
    Outline      = Color3.fromRGB(30, 30, 35),      -- Pixel-perfect borders
    OutlineLight = Color3.fromRGB(48, 48, 56),      -- Focused/hover stroke
    Accent       = Color3.fromRGB(175, 40, 255),    -- Signature Neon Purple
    AccentDark   = Color3.fromRGB(130, 25, 195),    -- Deeper purple for gradients
    Text         = Color3.fromRGB(225, 225, 230),   -- Primary crisp text
    TextDim      = Color3.fromRGB(150, 155, 165),   -- Secondary label text
    TextMuted    = Color3.fromRGB(90, 95, 105),     -- Inactive / placeholder text
    ElementBg    = Color3.fromRGB(22, 22, 26),      -- Interactive control background
    ElementHover = Color3.fromRGB(28, 28, 34),      -- Control hover background
    Success      = Color3.fromRGB(80, 220, 120),    -- Active state green (optional)
    Font         = Enum.Font.GothamBold,            -- Clean, modern typography
    FontMedium   = Enum.Font.GothamMedium,
}

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                        UTILITY & TWEEN HELPERS                            ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

local function Tween(instance, time, properties, style, direction)
    local tweenInfo = TweenInfo.new(
        time or 0.18,
        style or Enum.EasingStyle.Quad,
        direction or Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

local function Create(className, properties, children)
    local inst = Instance.new(className)
    for prop, val in pairs(properties or {}) do
        inst[prop] = val
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                        OOP CLASS DEFINITIONS                              ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

local Library = {
    Theme = Theme,
    ActiveWindows = {},
    Connections = {},
}
Library.__index = Library

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local SubTab = {}
SubTab.__index = SubTab

local Section = {}
Section.__index = Section

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                         WINDOW CONSTRUCTOR                                ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

function Library:CreateWindow(config)
    config = config or {}
    local windowTitle   = config.Name or "KittyWare"
    local windowSize    = config.Size or UDim2.new(0, 720, 0, 480)
    local toggleKey     = config.ToggleKey or Enum.KeyCode.Insert
    local customParent  = config.Parent
    local currentTheme  = config.Theme or self.Theme

    -- Establish Custom ScreenGui or attach to user-supplied ScreenGui
    local targetScreenGui
    if customParent and customParent:IsA("ScreenGui") then
        targetScreenGui = customParent
    else
        targetScreenGui = Create("ScreenGui", {
            Name = "KittyWare_" .. windowTitle,
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            DisplayOrder = 100,
        })
        if customParent then
            targetScreenGui.Parent = customParent
        else
            local success, _ = pcall(function()
                targetScreenGui.Parent = CoreGui
            end)
            if not success then
                targetScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
            end
        end
    end

    local windowObj = setmetatable({
        Name = windowTitle,
        Theme = currentTheme,
        ScreenGui = targetScreenGui,
        Tabs = {},
        ActiveTab = nil,
        Visible = true,
        ToggleKey = toggleKey,
        Connections = {},
        ActivePopup = nil,
    }, Window)

    -- Root CanvasGroup for seamless fade and scale transitions
    local MainFrame = Create("CanvasGroup", {
        Name = "MainFrame",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = windowSize,
        BackgroundColor3 = currentTheme.Background,
        BorderSizePixel = 0,
        GroupTransparency = 0,
        Parent = targetScreenGui,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        Create("UIStroke", {
            Color = currentTheme.Outline,
            Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        }),
    })
    windowObj.MainFrame = MainFrame

    -- UIScale for smooth opening/closing zoom tween
    local WindowScale = Create("UIScale", {
        Scale = 1,
        Parent = MainFrame,
    })
    windowObj.WindowScale = WindowScale

    -- Top Accent Line (Neverlose Aesthetic Accent Bar)
    Create("Frame", {
        Name = "AccentStripe",
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = currentTheme.Accent,
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = MainFrame,
    }, {
        Create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0.0, currentTheme.Accent),
                ColorSequenceKeypoint.new(0.5, currentTheme.AccentDark),
                ColorSequenceKeypoint.new(1.0, currentTheme.Accent),
            }),
        }),
    })

    -- Title Bar (Smooth Drag Handle)
    local TitleBar = Create("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 38),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = currentTheme.Header,
        BorderSizePixel = 0,
        ZIndex = 4,
        Parent = MainFrame,
    }, {
        Create("UIPadding", {
            PaddingLeft = UDim.new(0, 14),
            PaddingRight = UDim.new(0, 14),
        }),
    })

    -- Title Text & Subtitle
    local TitleLabel = Create("TextLabel", {
        Name = "TitleLabel",
        Size = UDim2.new(0, 200, 1, 0),
        BackgroundTransparency = 1,
        Font = currentTheme.Font,
        Text = string.upper(windowTitle) .. " <font color=\"rgb(175,40,255)\">WARE</font>",
        RichText = true,
        TextColor3 = currentTheme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
        Parent = TitleBar,
    })

    local SubtitleLabel = Create("TextLabel", {
        Name = "SubtitleLabel",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 150, 1, 0),
        BackgroundTransparency = 1,
        Font = currentTheme.FontMedium,
        Text = "v2.0 | Private",
        TextColor3 = currentTheme.TextMuted,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 5,
        Parent = TitleBar,
    })

    -- Divider below Titlebar
    Create("Frame", {
        Name = "TitleDivider",
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = currentTheme.Outline,
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = TitleBar,
    })

    -- Window Body Container
    local Body = Create("Frame", {
        Name = "Body",
        Size = UDim2.new(1, 0, 1, -38),
        Position = UDim2.new(0, 0, 0, 38),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = MainFrame,
    })

    -- Left Sidebar (Main Tabs Navigation)
    local Sidebar = Create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 145, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = currentTheme.Sidebar,
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = Body,
    }, {
        Create("UIPadding", {
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
        }),
        Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 4),
        }),
    })
    windowObj.Sidebar = Sidebar

    -- Right Border on Sidebar
    Create("Frame", {
        Name = "SidebarBorder",
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = currentTheme.Outline,
        BorderSizePixel = 0,
        ZIndex = 4,
        Parent = Sidebar,
    })

    -- Content Container (Sub-Tab bar + Sub-Tab Viewport)
    local ContentContainer = Create("Frame", {
        Name = "ContentContainer",
        Size = UDim2.new(1, -145, 1, 0),
        Position = UDim2.new(0, 145, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = Body,
    })
    windowObj.ContentContainer = ContentContainer

    -- Top SubTab Bar Container
    local SubTabBar = Create("Frame", {
        Name = "SubTabBar",
        Size = UDim2.new(1, 0, 0, 36),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = currentTheme.Header,
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = ContentContainer,
    }, {
        Create("UIPadding", {
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
            PaddingTop = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 6),
        }),
        Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            VerticalAlignment = Enum.VerticalAlignment.Center,
        }),
    })
    windowObj.SubTabBar = SubTabBar

    Create("Frame", {
        Name = "SubTabDivider",
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = currentTheme.Outline,
        BorderSizePixel = 0,
        ZIndex = 4,
        Parent = SubTabBar,
    })

    -- SubTab Pages Container (Contains the columns and scrolling frames)
    local PagesContainer = Create("Frame", {
        Name = "PagesContainer",
        Size = UDim2.new(1, 0, 1, -36),
        Position = UDim2.new(0, 0, 0, 36),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 3,
        Parent = ContentContainer,
    })
    windowObj.PagesContainer = PagesContainer

    -- Dedicated Non-Clipping Popup Overlay Layer
    local PopupOverlay = Create("Frame", {
        Name = "PopupOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        ZIndex = 9000,
        Parent = targetScreenGui,
    })
    windowObj.PopupOverlay = PopupOverlay

    -- Initialize Smooth Mouse-Delta Drag Math
    windowObj:_InitDragging(TitleBar)

    -- Initialize Keybind Visibility Toggle
    windowObj:_InitToggleKey()

    -- Global Dismiss Connection for Popups
    local dismissConn = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if windowObj.ActivePopup and windowObj.ActivePopup.Instance then
                local popupInst = windowObj.ActivePopup.Instance
                local mousePos = input.Position
                local pAbsPos = popupInst.AbsolutePosition
                local pAbsSize = popupInst.AbsoluteSize

                local isInside = mousePos.X >= pAbsPos.X and mousePos.X <= (pAbsPos.X + pAbsSize.X)
                             and mousePos.Y >= pAbsPos.Y and mousePos.Y <= (pAbsPos.Y + pAbsSize.Y)

                if not isInside and windowObj.ActivePopup.IgnoreButton then
                    local btnPos = windowObj.ActivePopup.IgnoreButton.AbsolutePosition
                    local btnSize = windowObj.ActivePopup.IgnoreButton.AbsoluteSize
                    if mousePos.X >= btnPos.X and mousePos.X <= (btnPos.X + btnSize.X)
                       and mousePos.Y >= btnPos.Y and mousePos.Y <= (btnPos.Y + btnSize.Y) then
                        isInside = true
                    end
                end

                if not isInside then
                    windowObj:CloseActivePopup()
                end
            end
        end
    end)
    table.insert(windowObj.Connections, dismissConn)

    table.insert(Library.ActiveWindows, windowObj)
    return windowObj
end

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                     SMOOTH MOUSE-DELTA DRAGGING                           ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

function Window:_InitDragging(dragHandle)
    local dragging = false
    local dragStart = nil
    local startPos = nil

    local inputBeganConn = dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = self.MainFrame.Position
            self:CloseActivePopup()

            local inputEndedConn
            inputEndedConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    inputEndedConn:Disconnect()
                end
            end)
            table.insert(self.Connections, inputEndedConn)
        end
    end)
    table.insert(self.Connections, inputBeganConn)

    local inputChangedConn = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            -- Mouse Delta calculation prevents stuttering across different display refresh rates
            local delta = input.Position - dragStart
            local targetPos = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
            Tween(self.MainFrame, 0.06, { Position = targetPos }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end
    end)
    table.insert(self.Connections, inputChangedConn)
end

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                     SMOOTH VISIBILITY TOGGLE (INSERT)                     ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

function Window:_InitToggleKey()
    local toggleConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == self.ToggleKey then
            self:Toggle()
        end
    end)
    table.insert(self.Connections, toggleConn)
end

function Window:Toggle(targetState)
    if targetState == nil then
        self.Visible = not self.Visible
    else
        self.Visible = targetState
    end

    self:CloseActivePopup()

    if self.Visible then
        self.MainFrame.Visible = true
        self.PopupOverlay.Visible = true
        Tween(self.MainFrame, 0.22, { GroupTransparency = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        Tween(self.WindowScale, 0.22, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    else
        local t1 = Tween(self.MainFrame, 0.18, { GroupTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        local t2 = Tween(self.WindowScale, 0.18, { Scale = 0.96 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        t1.Completed:Connect(function()
            if not self.Visible then
                self.MainFrame.Visible = false
                self.PopupOverlay.Visible = false
            end
        end)
    end
end

function Window:CloseActivePopup()
    if self.ActivePopup then
        if self.ActivePopup.CloseCallback then
            pcall(self.ActivePopup.CloseCallback)
        end
        if self.ActivePopup.Instance and self.ActivePopup.Instance.Parent then
            self.ActivePopup.Instance:Destroy()
        end
        self.ActivePopup = nil
    end
end

function Window:Destroy()
    self:CloseActivePopup()
    for _, conn in ipairs(self.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(self.Connections)
    if self.ScreenGui and self.ScreenGui.Parent then
        self.ScreenGui:Destroy()
    end
end

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                             TAB COMPONENT                                 ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

function Window:CreateTab(config)
    config = config or {}
    local tabName = config.Name or "Tab"
    local tabIcon = config.Icon

    local tabObj = setmetatable({
        Window = self,
        Name = tabName,
        SubTabs = {},
        ActiveSubTab = nil,
        Connections = {},
    }, Tab)

    -- Tab Button in Sidebar
    local TabButton = Create("TextButton", {
        Name = "Tab_" .. tabName,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = self.Theme.Sidebar,
        AutoButtonColor = false,
        Text = "",
        BorderSizePixel = 0,
        Parent = self.Sidebar,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 5) }),
        Create("UIPadding", {
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
        }),
    })
    tabObj.TabButton = TabButton

    -- Active Accent Indicator Pill (Neverlose style vertical bar)
    local ActiveIndicator = Create("Frame", {
        Name = "ActiveIndicator",
        Size = UDim2.new(0, 3, 0, 0),
        Position = UDim2.new(0, -6, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        Parent = TabButton,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 2) }),
    })
    tabObj.ActiveIndicator = ActiveIndicator

    -- Tab Label
    local TabLabel = Create("TextLabel", {
        Name = "TabLabel",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = self.Theme.FontMedium,
        Text = tabName,
        TextColor3 = self.Theme.TextDim,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TabButton,
    })
    tabObj.TabLabel = TabLabel

    -- SubTab Navigation Bar Container (Exclusive to this Tab)
    local SubTabList = Create("Frame", {
        Name = "SubTabList_" .. tabName,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = self.SubTabBar,
    }, {
        Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
            VerticalAlignment = Enum.VerticalAlignment.Center,
        }),
    })
    tabObj.SubTabList = SubTabList

    -- Hover animations
    TabButton.MouseEnter:Connect(function()
        if self.ActiveTab ~= tabObj then
            Tween(TabButton, 0.15, { BackgroundColor3 = self.Theme.ElementBg })
            Tween(TabLabel, 0.15, { TextColor3 = self.Theme.Text })
        end
    end)

    TabButton.MouseLeave:Connect(function()
        if self.ActiveTab ~= tabObj then
            Tween(TabButton, 0.15, { BackgroundColor3 = self.Theme.Sidebar })
            Tween(TabLabel, 0.15, { TextColor3 = self.Theme.TextDim })
        end
    end)

    TabButton.MouseButton1Click:Connect(function()
        self:SelectTab(tabObj)
    end)

    table.insert(self.Tabs, tabObj)

    -- Automatically select the first created tab
    if #self.Tabs == 1 then
        self:SelectTab(tabObj)
    end

    return tabObj
end

function Window:SelectTab(targetTab)
    self:CloseActivePopup()

    for _, tab in ipairs(self.Tabs) do
        local isActive = (tab == targetTab)
        tab.SubTabList.Visible = isActive

        if isActive then
            Tween(tab.TabButton, 0.18, { BackgroundColor3 = self.Theme.ElementBg })
            Tween(tab.TabLabel, 0.18, { TextColor3 = self.Theme.Text })
            tab.TabLabel.Font = self.Theme.Font
            Tween(tab.ActiveIndicator, 0.2, { Size = UDim2.new(0, 3, 0, 18) })
        else
            Tween(tab.TabButton, 0.18, { BackgroundColor3 = self.Theme.Sidebar })
            Tween(tab.TabLabel, 0.18, { TextColor3 = self.Theme.TextDim })
            tab.TabLabel.Font = self.Theme.FontMedium
            Tween(tab.ActiveIndicator, 0.15, { Size = UDim2.new(0, 3, 0, 0) })
        end
    end

    self.ActiveTab = targetTab

    -- Auto-select first sub-tab if none selected
    if targetTab.ActiveSubTab then
        targetTab:SelectSubTab(targetTab.ActiveSubTab)
    elseif #targetTab.SubTabs > 0 then
        targetTab:SelectSubTab(targetTab.SubTabs[1])
    end
end

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                           SUB-TAB COMPONENT                               ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

function Tab:CreateSubTab(config)
    config = config or {}
    local subTabName = config.Name or "SubTab"

    local subTabObj = setmetatable({
        Tab = self,
        Window = self.Window,
        Name = subTabName,
        Sections = {},
        Connections = {},
    }, SubTab)

    -- SubTab Button (Top bar pill)
    local SubButton = Create("TextButton", {
        Name = "SubBtn_" .. subTabName,
        Size = UDim2.new(0, 0, 0, 24),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = self.Window.Theme.Header,
        AutoButtonColor = false,
        Text = "",
        BorderSizePixel = 0,
        Parent = self.SubTabList,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
        Create("UIPadding", {
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
        }),
    })
    subTabObj.SubButton = SubButton

    local SubLabel = Create("TextLabel", {
        Name = "SubLabel",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = self.Window.Theme.FontMedium,
        Text = subTabName,
        TextColor3 = self.Window.Theme.TextMuted,
        TextSize = 12,
        Parent = SubButton,
    })
    subTabObj.SubLabel = SubLabel

    -- Viewport Page for this SubTab (Featuring two clean columns)
    local PageFrame = Create("Frame", {
        Name = "Page_" .. subTabName,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = self.Window.PagesContainer,
    }, {
        Create("UIPadding", {
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
            PaddingTop = UDim.new(0, 12),
            PaddingBottom = UDim.new(0, 12),
        }),
    })
    subTabObj.PageFrame = PageFrame

    -- Left and Right Columns for structured dual-column layout
    local function CreateColumn(name, posScaleX)
        return Create("ScrollingFrame", {
            Name = name,
            Size = UDim2.new(0.5, -6, 1, 0),
            Position = UDim2.new(posScaleX, posScaleX == 0 and 0 or 6, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = self.Window.Theme.Accent,
            ScrollBarImageTransparency = 0.5,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ClipsDescendants = true,
            Parent = PageFrame,
        }, {
            Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 10),
            }),
            Create("UIPadding", {
                PaddingRight = UDim.new(0, 4),
            }),
        })
    end

    subTabObj.LeftColumn = CreateColumn("LeftColumn", 0)
    subTabObj.RightColumn = CreateColumn("RightColumn", 0.5)

    -- Hover animations
    SubButton.MouseEnter:Connect(function()
        if self.ActiveSubTab ~= subTabObj then
            Tween(SubLabel, 0.15, { TextColor3 = self.Window.Theme.Text })
        end
    end)

    SubButton.MouseLeave:Connect(function()
        if self.ActiveSubTab ~= subTabObj then
            Tween(SubLabel, 0.15, { TextColor3 = self.Window.Theme.TextMuted })
        end
    end)

    SubButton.MouseButton1Click:Connect(function()
        self:SelectSubTab(subTabObj)
    end)

    table.insert(self.SubTabs, subTabObj)

    if #self.SubTabs == 1 then
        self:SelectSubTab(subTabObj)
    end

    return subTabObj
end

function Tab:SelectSubTab(targetSubTab)
    self.Window:CloseActivePopup()

    for _, sub in ipairs(self.SubTabs) do
        local isActive = (sub == targetSubTab)
        sub.PageFrame.Visible = isActive

        if isActive then
            Tween(sub.SubButton, 0.18, { BackgroundColor3 = self.Window.Theme.ElementBg })
            Tween(sub.SubLabel, 0.18, { TextColor3 = self.Window.Theme.Text })
            sub.SubLabel.Font = self.Window.Theme.Font
        else
            Tween(sub.SubButton, 0.18, { BackgroundColor3 = self.Window.Theme.Header })
            Tween(sub.SubLabel, 0.18, { TextColor3 = self.Window.Theme.TextMuted })
            sub.SubLabel.Font = self.Window.Theme.FontMedium
        end
    end

    self.ActiveSubTab = targetSubTab
end

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                          SECTION / GROUPBOX                               ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

function SubTab:CreateSection(config)
    config = config or {}
    local sectionName = config.Name or "Section"
    local side = (config.Side and string.lower(config.Side)) or "left"
    local targetColumn = (side == "right") and self.RightColumn or self.LeftColumn

    local sectionObj = setmetatable({
        SubTab = self,
        Window = self.Window,
        Name = sectionName,
    }, Section)

    -- Section Container Card
    local SectionFrame = Create("Frame", {
        Name = "Section_" .. sectionName,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = self.Window.Theme.Section,
        BorderSizePixel = 0,
        Parent = targetColumn,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
        Create("UIStroke", {
            Color = self.Window.Theme.Outline,
            Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        }),
    })
    sectionObj.SectionFrame = SectionFrame

    -- Section Header Bar
    local HeaderBar = Create("Frame", {
        Name = "HeaderBar",
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = SectionFrame,
    }, {
        Create("UIPadding", {
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
        }),
    })

    local HeaderLabel = Create("TextLabel", {
        Name = "HeaderLabel",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = self.Window.Theme.Font,
        Text = string.upper(sectionName),
        TextColor3 = self.Window.Theme.TextDim,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = HeaderBar,
    })

    -- 1px divider below section header
    Create("Frame", {
        Name = "HeaderDivider",
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 0, 28),
        BackgroundColor3 = self.Window.Theme.Outline,
        BorderSizePixel = 0,
        Parent = SectionFrame,
    })

    -- Container for interactive controls
    local Container = Create("Frame", {
        Name = "Container",
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 29),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = SectionFrame,
    }, {
        Create("UIPadding", {
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
            PaddingTop = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 10),
        }),
        Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
        }),
    })
    sectionObj.Container = Container

    return sectionObj
end

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                        COMPONENT: TOGGLE SWITCH                           ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

function Section:CreateToggle(config)
    config = config or {}
    local name      = config.Name or "Toggle"
    local state     = config.Default or false
    local callback  = config.Callback or function() end
    local theme     = self.Window.Theme

    local toggleObj = {
        Value = state,
        Callback = callback,
    }

    local Row = Create("Frame", {
        Name = "Toggle_" .. name,
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Parent = self.Container,
    })

    local Label = Create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(1, -38, 1, 0),
        BackgroundTransparency = 1,
        Font = theme.FontMedium,
        Text = name,
        TextColor3 = state and theme.Text or theme.TextDim,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Row,
    })

    -- Neverlose-Style Pill Switch
    local Switch = Create("TextButton", {
        Name = "Switch",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 32, 0, 16),
        BackgroundColor3 = state and theme.Accent or theme.ElementBg,
        AutoButtonColor = false,
        Text = "",
        BorderSizePixel = 0,
        Parent = Row,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        Create("UIStroke", {
            Color = state and theme.Accent or theme.Outline,
            Thickness = 1,
        }),
    })

    -- Sliding Knob
    local Knob = Create("Frame", {
        Name = "Knob",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = state and UDim2.new(1, -14, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
        Size = UDim2.new(0, 12, 0, 12),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Parent = Switch,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
    })

    function toggleObj:Set(newState, suppressCallback)
        self.Value = newState
        local stroke = Switch:FindFirstChildOfClass("UIStroke")

        if newState then
            Tween(Switch, 0.18, { BackgroundColor3 = theme.Accent })
            Tween(Knob, 0.18, { Position = UDim2.new(1, -14, 0.5, 0) })
            Tween(Label, 0.18, { TextColor3 = theme.Text })
            if stroke then Tween(stroke, 0.18, { Color = theme.Accent }) end
        else
            Tween(Switch, 0.18, { BackgroundColor3 = theme.ElementBg })
            Tween(Knob, 0.18, { Position = UDim2.new(0, 2, 0.5, 0) })
            Tween(Label, 0.18, { TextColor3 = theme.TextDim })
            if stroke then Tween(stroke, 0.18, { Color = theme.Outline }) end
        end

        if not suppressCallback and self.Callback then
            pcall(self.Callback, self.Value)
        end
    end

    Switch.MouseButton1Click:Connect(function()
        toggleObj:Set(not toggleObj.Value)
    end)

    local ClickArea = Create("TextButton", {
        Name = "ClickArea",
        Size = UDim2.new(1, -36, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = Row,
    })
    ClickArea.MouseButton1Click:Connect(function()
        toggleObj:Set(not toggleObj.Value)
    end)

    return toggleObj
end

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                        COMPONENT: NUMERIC SLIDER                          ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

function Section:CreateSlider(config)
    config = config or {}
    local name      = config.Name or "Slider"
    local min       = config.Min or 0
    local max       = config.Max or 100
    local default   = math.clamp(config.Default or min, min, max)
    local decimals  = config.Decimals or 0
    local suffix    = config.Suffix or ""
    local callback  = config.Callback or function() end
    local theme     = self.Window.Theme

    local sliderObj = {
        Value = default,
        Callback = callback,
    }

    local Container = Create("Frame", {
        Name = "Slider_" .. name,
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 1,
        Parent = self.Container,
    })

    -- Top Row: Name on Left, Current Value on Right
    local HeaderRow = Create("Frame", {
        Name = "HeaderRow",
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Parent = Container,
    })

    local TitleLabel = Create("TextLabel", {
        Name = "TitleLabel",
        Size = UDim2.new(1, -60, 1, 0),
        BackgroundTransparency = 1,
        Font = theme.FontMedium,
        Text = name,
        TextColor3 = theme.TextDim,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = HeaderRow,
    })

    local ValueLabel = Create("TextLabel", {
        Name = "ValueLabel",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 60, 1, 0),
        BackgroundTransparency = 1,
        Font = theme.Font,
        Text = tostring(default) .. suffix,
        TextColor3 = theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = HeaderRow,
    })

    -- Slider Track Bar
    local Track = Create("TextButton", {
        Name = "Track",
        Position = UDim2.new(0, 0, 0, 20),
        Size = UDim2.new(1, 0, 0, 6),
        BackgroundColor3 = theme.ElementBg,
        AutoButtonColor = false,
        Text = "",
        BorderSizePixel = 0,
        Parent = Container,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
        Create("UIStroke", {
            Color = theme.Outline,
            Thickness = 1,
        }),
    })

    -- Smooth Fill Bar
    local initialRatio = math.clamp((default - min) / (max - min), 0, 1)
    local Fill = Create("Frame", {
        Name = "Fill",
        Size = UDim2.new(initialRatio, 0, 1, 0),
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Parent = Track,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
    })

    local isDragging = false

    local function UpdateFromInput(input)
        local trackAbsPos = Track.AbsolutePosition
        local trackAbsSize = Track.AbsoluteSize
        local ratio = math.clamp((input.Position.X - trackAbsPos.X) / trackAbsSize.X, 0, 1)
        local rawValue = min + (max - min) * ratio

        local roundedValue
        if decimals > 0 then
            local mult = 10 ^ decimals
            roundedValue = math.floor(rawValue * mult + 0.5) / mult
        else
            roundedValue = math.floor(rawValue + 0.5)
        end

        sliderObj:Set(roundedValue)
    end

    function sliderObj:Set(newVal, suppressCallback)
        newVal = math.clamp(newVal, min, max)
        self.Value = newVal

        local ratio = math.clamp((newVal - min) / (max - min), 0, 1)
        Tween(Fill, 0.08, { Size = UDim2.new(ratio, 0, 1, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

        if decimals > 0 then
            ValueLabel.Text = string.format("%." .. decimals .. "f", newVal) .. suffix
        else
            ValueLabel.Text = tostring(math.floor(newVal)) .. suffix
        end

        if not suppressCallback and self.Callback then
            pcall(self.Callback, newVal)
        end
    end

    Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            UpdateFromInput(input)
        end
    end)

    local inputEndedConn = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end)
    table.insert(self.Window.Connections, inputEndedConn)

    local inputChangedConn = UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdateFromInput(input)
        end
    end)
    table.insert(self.Window.Connections, inputChangedConn)

    return sliderObj
end

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                        COMPONENT: DROPDOWN (OVERLAY)                      ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
    Implements true top-level overlay rendering to prevent clipping inside frames.
]]

function Section:CreateDropdown(config)
    config = config or {}
    local name      = config.Name or "Dropdown"
    local options   = config.Options or {}
    local multi     = config.Multi or false
    local default   = config.Default or (multi and {} or options[1])
    local callback  = config.Callback or function() end
    local theme     = self.Window.Theme
    local window    = self.Window

    local dropdownObj = {
        Value = default,
        Options = options,
        Multi = multi,
        Callback = callback,
        IsOpen = false,
    }

    local Container = Create("Frame", {
        Name = "Dropdown_" .. name,
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundTransparency = 1,
        Parent = self.Container,
    })

    local TitleLabel = Create("TextLabel", {
        Name = "TitleLabel",
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Font = theme.FontMedium,
        Text = name,
        TextColor3 = theme.TextDim,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Container,
    })

    -- Combobox Header Button
    local DropButton = Create("TextButton", {
        Name = "DropButton",
        Position = UDim2.new(0, 0, 0, 20),
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundColor3 = theme.ElementBg,
        AutoButtonColor = false,
        Text = "",
        BorderSizePixel = 0,
        Parent = Container,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
        Create("UIStroke", {
            Color = theme.Outline,
            Thickness = 1,
        }),
        Create("UIPadding", {
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
        }),
    })

    local SelectedLabel = Create("TextLabel", {
        Name = "SelectedLabel",
        Size = UDim2.new(1, -20, 1, 0),
        BackgroundTransparency = 1,
        Font = theme.FontMedium,
        Text = "",
        TextColor3 = theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = DropButton,
    })

    local Chevron = Create("TextLabel", {
        Name = "Chevron",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 14, 0, 14),
        BackgroundTransparency = 1,
        Font = theme.Font,
        Text = "▼",
        TextColor3 = theme.TextDim,
        TextSize = 8,
        Parent = DropButton,
    })

    local function FormatText()
        if multi then
            local selectedList = {}
            for opt, isSelected in pairs(dropdownObj.Value) do
                if isSelected then
                    table.insert(selectedList, opt)
                end
            end
            if #selectedList == 0 then
                SelectedLabel.Text = "None"
            else
                SelectedLabel.Text = table.concat(selectedList, ", ")
            end
        else
            SelectedLabel.Text = tostring(dropdownObj.Value or "None")
        end
    end
    FormatText()

    local function CloseDropdown()
        if not dropdownObj.IsOpen then return end
        dropdownObj.IsOpen = false
        Tween(Chevron, 0.15, { Rotation = 0 })
        if window.ActivePopup and window.ActivePopup.Identifier == dropdownObj then
            window:CloseActivePopup()
        end
    end

    local function OpenDropdown()
        window:CloseActivePopup()
        dropdownObj.IsOpen = true
        Tween(Chevron, 0.15, { Rotation = 180 })

        -- Calculate Absolute Screen Position relative to Overlay
        local btnAbsPos = DropButton.AbsolutePosition
        local btnAbsSize = DropButton.AbsoluteSize
        local overlayPos = window.PopupOverlay.AbsolutePosition

        local relX = btnAbsPos.X - overlayPos.X
        local relY = (btnAbsPos.Y - overlayPos.Y) + btnAbsSize.Y + 4

        local maxVisibleItems = math.min(#dropdownObj.Options, 6)
        local targetHeight = (maxVisibleItems * 24) + 8

        local PopupFrame = Create("Frame", {
            Name = "DropdownPopup",
            Position = UDim2.new(0, relX, 0, relY),
            Size = UDim2.new(0, btnAbsSize.X, 0, targetHeight),
            BackgroundColor3 = theme.Header,
            BorderSizePixel = 0,
            ZIndex = 9005,
            ClipsDescendants = true,
            Parent = window.PopupOverlay,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 5) }),
            Create("UIStroke", {
                Color = theme.Outline,
                Thickness = 1,
            }),
        })

        local Scroll = Create("ScrollingFrame", {
            Name = "Scroll",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = theme.Accent,
            ScrollBarImageTransparency = 0.5,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent = PopupFrame,
        }, {
            Create("UIPadding", {
                PaddingTop = UDim.new(0, 4),
                PaddingBottom = UDim.new(0, 4),
                PaddingLeft = UDim.new(0, 4),
                PaddingRight = UDim.new(0, 4),
            }),
            Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 2),
            }),
        })

        -- Populate Option Rows
        for _, optionName in ipairs(dropdownObj.Options) do
            local isSelected = multi and (dropdownObj.Value[optionName] == true) or (dropdownObj.Value == optionName)

            local OptionBtn = Create("TextButton", {
                Name = "Option_" .. optionName,
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundColor3 = isSelected and theme.ElementBg or theme.Header,
                AutoButtonColor = false,
                Text = "",
                BorderSizePixel = 0,
                Parent = Scroll,
            }, {
                Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
                Create("UIPadding", {
                    PaddingLeft = UDim.new(0, 6),
                    PaddingRight = UDim.new(0, 6),
                }),
            })

            local OptionLabel = Create("TextLabel", {
                Name = "Label",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Font = isSelected and theme.Font or theme.FontMedium,
                Text = optionName,
                TextColor3 = isSelected and theme.Accent or theme.TextDim,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = OptionBtn,
            })

            OptionBtn.MouseEnter:Connect(function()
                if not (multi and dropdownObj.Value[optionName]) and dropdownObj.Value ~= optionName then
                    Tween(OptionBtn, 0.12, { BackgroundColor3 = theme.ElementHover })
                    Tween(OptionLabel, 0.12, { TextColor3 = theme.Text })
                end
            end)

            OptionBtn.MouseLeave:Connect(function()
                if not (multi and dropdownObj.Value[optionName]) and dropdownObj.Value ~= optionName then
                    Tween(OptionBtn, 0.12, { BackgroundColor3 = theme.Header })
                    Tween(OptionLabel, 0.12, { TextColor3 = theme.TextDim })
                end
            end)

            OptionBtn.MouseButton1Click:Connect(function()
                if multi then
                    dropdownObj.Value[optionName] = not dropdownObj.Value[optionName]
                    local active = dropdownObj.Value[optionName]
                    Tween(OptionBtn, 0.12, { BackgroundColor3 = active and theme.ElementBg or theme.Header })
                    Tween(OptionLabel, 0.12, { TextColor3 = active and theme.Accent or theme.TextDim })
                    OptionLabel.Font = active and theme.Font or theme.FontMedium
                    FormatText()
                    if dropdownObj.Callback then
                        pcall(dropdownObj.Callback, dropdownObj.Value)
                    end
                else
                    dropdownObj.Value = optionName
                    FormatText()
                    CloseDropdown()
                    if dropdownObj.Callback then
                        pcall(dropdownObj.Callback, dropdownObj.Value)
                    end
                end
            end)
        end

        window.ActivePopup = {
            Identifier = dropdownObj,
            Instance = PopupFrame,
            IgnoreButton = DropButton,
            CloseCallback = function()
                dropdownObj.IsOpen = false
                Tween(Chevron, 0.15, { Rotation = 0 })
            end,
        }
    end

    DropButton.MouseButton1Click:Connect(function()
        if dropdownObj.IsOpen then
            CloseDropdown()
        else
            OpenDropdown()
        end
    end)

    function dropdownObj:Set(val, suppressCallback)
        self.Value = val
        FormatText()
        if not suppressCallback and self.Callback then
            pcall(self.Callback, self.Value)
        end
    end

    function dropdownObj:Refresh(newOptions)
        self.Options = newOptions or {}
        CloseDropdown()
        FormatText()
    end

    return dropdownObj
end

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                      COMPONENT: COLOR PICKER (HSV MATRIX)                 ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

function Section:CreateColorPicker(config)
    config = config or {}
    local name      = config.Name or "Color Picker"
    local default   = config.Default or Color3.fromRGB(175, 40, 255)
    local callback  = config.Callback or function() end
    local theme     = self.Window.Theme
    local window    = self.Window

    local h, s, v = default:ToHSV()
    local colorObj = {
        Value = default,
        Hue = h,
        Saturation = s,
        Brightness = v,
        Callback = callback,
        IsOpen = false,
    }

    local Row = Create("Frame", {
        Name = "ColorPicker_" .. name,
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Parent = self.Container,
    })

    local TitleLabel = Create("TextLabel", {
        Name = "TitleLabel",
        Size = UDim2.new(1, -38, 1, 0),
        BackgroundTransparency = 1,
        Font = theme.FontMedium,
        Text = name,
        TextColor3 = theme.TextDim,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Row,
    })

    -- Compact Color Preview Swatch
    local PreviewSwatch = Create("TextButton", {
        Name = "PreviewSwatch",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 28, 0, 14),
        BackgroundColor3 = default,
        AutoButtonColor = false,
        Text = "",
        BorderSizePixel = 0,
        Parent = Row,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
        Create("UIStroke", {
            Color = theme.Outline,
            Thickness = 1,
        }),
    })

    local function OpenColorPicker()
        window:CloseActivePopup()
        colorObj.IsOpen = true

        local swatchAbsPos = PreviewSwatch.AbsolutePosition
        local swatchAbsSize = PreviewSwatch.AbsoluteSize
        local overlayPos = window.PopupOverlay.AbsolutePosition

        local relX = (swatchAbsPos.X - overlayPos.X) - 150 + swatchAbsSize.X
        local relY = (swatchAbsPos.Y - overlayPos.Y) + swatchAbsSize.Y + 6

        -- Main Color Picker Modal Frame
        local Modal = Create("Frame", {
            Name = "ColorPickerModal",
            Position = UDim2.new(0, relX, 0, relY),
            Size = UDim2.new(0, 180, 0, 160),
            BackgroundColor3 = theme.Header,
            BorderSizePixel = 0,
            ZIndex = 9010,
            Parent = window.PopupOverlay,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
            Create("UIStroke", {
                Color = theme.Outline,
                Thickness = 1,
            }),
            Create("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
                PaddingTop = UDim.new(0, 8),
                PaddingBottom = UDim.new(0, 8),
            }),
        })

        -- 2D Saturation / Value Canvas (130 x 110)
        local SVBox = Create("ImageButton", {
            Name = "SVBox",
            Size = UDim2.new(0, 134, 0, 114),
            BackgroundColor3 = Color3.fromHSV(colorObj.Hue, 1, 1),
            AutoButtonColor = false,
            BorderSizePixel = 0,
            ZIndex = 9011,
            Parent = Modal,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
            -- Horizontal White Gradient (Saturation)
            Create("ImageLabel", {
                Name = "WhiteOverlay",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Image = "rbxassetid://4155801252",
                ZIndex = 9012,
            }, { Create("UICorner", { CornerRadius = UDim.new(0, 4) }) }),
        })

        -- Draggable SV Crosshair Ring
        local Crosshair = Create("Frame", {
            Name = "Crosshair",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(colorObj.Saturation, 0, 1 - colorObj.Brightness, 0),
            Size = UDim2.new(0, 8, 0, 8),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 9013,
            Parent = SVBox,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
            Create("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 1,
            }),
        })

        -- Vertical Hue Slider (16 x 114)
        local HueBar = Create("ImageButton", {
            Name = "HueBar",
            Position = UDim2.new(0, 142, 0, 0),
            Size = UDim2.new(0, 18, 0, 114),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            AutoButtonColor = false,
            BorderSizePixel = 0,
            ZIndex = 9011,
            Parent = Modal,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
            Create("UIGradient", {
                Rotation = 90,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
                    ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
                    ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
                }),
            }),
        })

        -- Hue Slider Thumb
        local HueThumb = Create("Frame", {
            Name = "HueThumb",
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, -1, colorObj.Hue, 0),
            Size = UDim2.new(1, 2, 0, 4),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 9013,
            Parent = HueBar,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 2) }),
            Create("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 1,
            }),
        })

        -- Bottom Info Bar: Hex readout & RGB live preview
        local InfoBar = Create("Frame", {
            Name = "InfoBar",
            Position = UDim2.new(0, 0, 0, 122),
            Size = UDim2.new(1, 0, 0, 22),
            BackgroundColor3 = theme.ElementBg,
            BorderSizePixel = 0,
            ZIndex = 9011,
            Parent = Modal,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
            Create("UIStroke", {
                Color = theme.Outline,
                Thickness = 1,
            }),
        })

        local HexLabel = Create("TextLabel", {
            Name = "HexLabel",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Font = theme.FontMedium,
            Text = "#" .. colorObj.Value:ToHex():upper(),
            TextColor3 = theme.Text,
            TextSize = 11,
            ZIndex = 9012,
            Parent = InfoBar,
        })

        local function UpdateColor(triggerCallback)
            local finalColor = Color3.fromHSV(colorObj.Hue, colorObj.Saturation, colorObj.Brightness)
            colorObj.Value = finalColor
            PreviewSwatch.BackgroundColor3 = finalColor
            SVBox.BackgroundColor3 = Color3.fromHSV(colorObj.Hue, 1, 1)
            HexLabel.Text = "#" .. finalColor:ToHex():upper()

            if triggerCallback and colorObj.Callback then
                pcall(colorObj.Callback, finalColor)
            end
        end

        local svDragging = false
        local hueDragging = false

        local function UpdateSV(input)
            local absPos = SVBox.AbsolutePosition
            local absSize = SVBox.AbsoluteSize
            local sat = math.clamp((input.Position.X - absPos.X) / absSize.X, 0, 1)
            local val = 1 - math.clamp((input.Position.Y - absPos.Y) / absSize.Y, 0, 1)

            colorObj.Saturation = sat
            colorObj.Brightness = val
            Crosshair.Position = UDim2.new(sat, 0, 1 - val, 0)
            UpdateColor(true)
        end

        local function UpdateHue(input)
            local absPos = HueBar.AbsolutePosition
            local absSize = HueBar.AbsoluteSize
            local hVal = math.clamp((input.Position.Y - absPos.Y) / absSize.Y, 0, 1)

            colorObj.Hue = hVal
            HueThumb.Position = UDim2.new(0, -1, hVal, 0)
            UpdateColor(true)
        end

        SVBox.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                svDragging = true
                UpdateSV(input)
            end
        end)

        HueBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                hueDragging = true
                UpdateHue(input)
            end
        end)

        local dragEndConn = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                svDragging = false
                hueDragging = false
            end
        end)
        table.insert(window.Connections, dragEndConn)

        local dragMoveConn = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                if svDragging then
                    UpdateSV(input)
                elseif hueDragging then
                    UpdateHue(input)
                end
            end
        end)
        table.insert(window.Connections, dragMoveConn)

        window.ActivePopup = {
            Identifier = colorObj,
            Instance = Modal,
            IgnoreButton = PreviewSwatch,
            CloseCallback = function()
                colorObj.IsOpen = false
            end,
        }
    end

    PreviewSwatch.MouseButton1Click:Connect(function()
        if colorObj.IsOpen then
            window:CloseActivePopup()
        else
            OpenColorPicker()
        end
    end)

    function colorObj:Set(newColor, suppressCallback)
        self.Value = newColor
        self.Hue, self.Saturation, self.Brightness = newColor:ToHSV()
        PreviewSwatch.BackgroundColor3 = newColor

        if not suppressCallback and self.Callback then
            pcall(self.Callback, newColor)
        end
    end

    return colorObj
end

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                        COMPONENT: KEYBIND LISTENER                        ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

function Section:CreateKeybind(config)
    config = config or {}
    local name      = config.Name or "Keybind"
    local default   = config.Default or Enum.KeyCode.Insert
    local mode      = config.Mode or "Toggle" -- Toggle, Hold, Always
    local callback  = config.Callback or function() end
    local theme     = self.Window.Theme

    local keybindObj = {
        Value = default,
        Mode = mode,
        Listening = false,
        Callback = callback,
    }

    local Row = Create("Frame", {
        Name = "Keybind_" .. name,
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Parent = self.Container,
    })

    local TitleLabel = Create("TextLabel", {
        Name = "TitleLabel",
        Size = UDim2.new(1, -70, 1, 0),
        BackgroundTransparency = 1,
        Font = theme.FontMedium,
        Text = name,
        TextColor3 = theme.TextDim,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Row,
    })

    local BindButton = Create("TextButton", {
        Name = "BindButton",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 56, 0, 18),
        BackgroundColor3 = theme.ElementBg,
        AutoButtonColor = false,
        Text = "",
        BorderSizePixel = 0,
        Parent = Row,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
        Create("UIStroke", {
            Color = theme.Outline,
            Thickness = 1,
        }),
    })

    local BindLabel = Create("TextLabel", {
        Name = "BindLabel",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = theme.Font,
        Text = "[ " .. (default and default.Name or "None") .. " ]",
        TextColor3 = theme.Text,
        TextSize = 10,
        Parent = BindButton,
    })

    local stroke = BindButton:FindFirstChildOfClass("UIStroke")

    BindButton.MouseButton1Click:Connect(function()
        if keybindObj.Listening then return end
        keybindObj.Listening = true
        BindLabel.Text = "[ ... ]"
        if stroke then Tween(stroke, 0.15, { Color = theme.Accent }) end

        local listenConn
        listenConn = UserInputService.InputBegan:Connect(function(input)
            local isKey = (input.UserInputType == Enum.UserInputType.Keyboard)
            local isMouse = (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3)

            if isKey or isMouse then
                listenConn:Disconnect()
                keybindObj.Listening = false
                if stroke then Tween(stroke, 0.15, { Color = theme.Outline }) end

                local chosenBind
                if isKey then
                    if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
                        chosenBind = nil
                    else
                        chosenBind = input.KeyCode
                    end
                elseif isMouse then
                    chosenBind = input.UserInputType
                end

                keybindObj:Set(chosenBind)
            end
        end)
    end)

    function keybindObj:Set(newBind, suppressCallback)
        self.Value = newBind
        BindLabel.Text = "[ " .. (newBind and newBind.Name or "None") .. " ]"

        if not suppressCallback and self.Callback then
            pcall(self.Callback, newBind)
        end
    end

    return keybindObj
end

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                        COMPONENT: ACTION BUTTON                           ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

function Section:CreateButton(config)
    config = config or {}
    local name      = config.Name or "Button"
    local callback  = config.Callback or function() end
    local theme     = self.Window.Theme

    local Button = Create("TextButton", {
        Name = "Button_" .. name,
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundColor3 = theme.ElementBg,
        AutoButtonColor = false,
        Text = "",
        BorderSizePixel = 0,
        Parent = self.Container,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
        Create("UIStroke", {
            Color = theme.Outline,
            Thickness = 1,
        }),
    })

    local ButtonLabel = Create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = theme.Font,
        Text = name,
        TextColor3 = theme.Text,
        TextSize = 11,
        Parent = Button,
    })

    local stroke = Button:FindFirstChildOfClass("UIStroke")

    Button.MouseEnter:Connect(function()
        Tween(Button, 0.15, { BackgroundColor3 = theme.ElementHover })
        if stroke then Tween(stroke, 0.15, { Color = theme.OutlineLight }) end
    end)

    Button.MouseLeave:Connect(function()
        Tween(Button, 0.15, { BackgroundColor3 = theme.ElementBg })
        if stroke then Tween(stroke, 0.15, { Color = theme.Outline }) end
    end)

    Button.MouseButton1Click:Connect(function()
        -- Subtle Micro-Bounce Press Effect
        Tween(Button, 0.08, { BackgroundColor3 = theme.AccentDark })
        task.delay(0.1, function()
            Tween(Button, 0.15, { BackgroundColor3 = theme.ElementBg })
        end)
        if callback then
            pcall(callback)
        end
    end)

    return {
        Instance = Button,
        SetText = function(_, txt) ButtonLabel.Text = txt end,
    }
end

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                        COMPONENT: TEXT BOX INPUT                          ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

function Section:CreateTextBox(config)
    config = config or {}
    local name          = config.Name or "Input"
    local placeholder   = config.Placeholder or "Enter value..."
    local default       = config.Default or ""
    local callback      = config.Callback or function() end
    local theme         = self.Window.Theme

    local Container = Create("Frame", {
        Name = "TextBox_" .. name,
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
        Parent = self.Container,
    })

    local TitleLabel = Create("TextLabel", {
        Name = "TitleLabel",
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Font = theme.FontMedium,
        Text = name,
        TextColor3 = theme.TextDim,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Container,
    })

    local InputBox = Create("TextBox", {
        Name = "InputBox",
        Position = UDim2.new(0, 0, 0, 18),
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundColor3 = theme.ElementBg,
        Font = theme.FontMedium,
        Text = default,
        PlaceholderText = placeholder,
        PlaceholderColor3 = theme.TextMuted,
        TextColor3 = theme.Text,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        BorderSizePixel = 0,
        Parent = Container,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
        Create("UIStroke", {
            Color = theme.Outline,
            Thickness = 1,
        }),
        Create("UIPadding", {
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
        }),
    })

    local stroke = InputBox:FindFirstChildOfClass("UIStroke")

    InputBox.Focused:Connect(function()
        if stroke then Tween(stroke, 0.15, { Color = theme.Accent }) end
    end)

    InputBox.FocusLost:Connect(function(enterPressed)
        if stroke then Tween(stroke, 0.15, { Color = theme.Outline }) end
        if callback then
            pcall(callback, InputBox.Text, enterPressed)
        end
    end)

    return {
        Instance = InputBox,
        Get = function() return InputBox.Text end,
        Set = function(_, val) InputBox.Text = tostring(val or "") end,
    }
end

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                 COMPLETE RUNNABLE DEMONSTRATION & EXAMPLE                 ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
    Set RUN_DEMO = true to launch the interactive preview menu when running
    this file directly, or set to false when importing as a library module.
]]

-- Set getgenv().KittyWareDemo = true before executing if you want to preview standalone
local RUN_DEMO = (getgenv().KittyWareDemo == true)

if RUN_DEMO then
    local KittyWare = Library

    -- Custom Color Theme matching your exact Watermark & Keybinds List
    local CustomTheme = {
        Background   = Color3.fromRGB(10, 11, 13),      -- Dark body
        Sidebar      = Color3.fromRGB(17, 17, 19),      -- Sidebar container
        Header       = Color3.fromRGB(13, 13, 15),      -- Header & sub-header
        Section      = Color3.fromRGB(13, 14, 16),      -- Section card
        Outline      = Color3.fromRGB(30, 30, 35),      -- Border stroke
        OutlineLight = Color3.fromRGB(48, 48, 56),      -- Focused border
        Accent       = Color3.fromRGB(175, 40, 255),    -- Neon Purple
        AccentDark   = Color3.fromRGB(130, 25, 195),
        Text         = Color3.fromRGB(225, 225, 230),   -- Primary crisp text
        TextDim      = Color3.fromRGB(150, 155, 165),   -- Secondary text
        TextMuted    = Color3.fromRGB(90, 95, 105),     -- Placeholder
        ElementBg    = Color3.fromRGB(22, 22, 26),      -- Inputs / tracks
        ElementHover = Color3.fromRGB(28, 28, 34),
        Font         = Enum.Font.GothamBold,
        FontMedium   = Enum.Font.GothamMedium,
    }

    -- Initialize Window with Custom Parent support (Does NOT hardcode CoreGui)
    local Window = KittyWare:CreateWindow({
        Name = "KittyWare",
        Size = UDim2.new(0, 720, 0, 480),
        ToggleKey = Enum.KeyCode.Insert,
        Theme = CustomTheme,
        -- Parent = myCustomPath, -- Dictate your custom ScreenGui or Container here
    })

    -- Tab 1: Combat
    local CombatTab = Window:CreateTab({ Name = "Combat" })
    local MainSubTab = CombatTab:CreateSubTab({ Name = "Aimbot" })
    local TriggerSubTab = CombatTab:CreateSubTab({ Name = "Triggerbot" })

    -- Left Column: Targeting Features
    local AimSection = MainSubTab:CreateSection({ Name = "Target Assistance", Side = "Left" })

    local AimToggle = AimSection:CreateToggle({
        Name = "Silent Aim",
        Default = true,
        Callback = function(enabled)
            print("[KittyWare] Silent Aim:", enabled)
        end
    })

    local FovSlider = AimSection:CreateSlider({
        Name = "Field of View",
        Min = 10,
        Max = 360,
        Default = 90,
        Decimals = 0,
        Suffix = "°",
        Callback = function(val)
            print("[KittyWare] FOV Changed:", val)
        end
    })

    local HitboxDropdown = AimSection:CreateDropdown({
        Name = "Target Priority",
        Options = { "Head", "Neck", "Chest", "Pelvis", "Extremities" },
        Default = "Head",
        Multi = false,
        Callback = function(selected)
            print("[KittyWare] Hitbox Priority:", selected)
        end
    })

    local AimKeybind = AimSection:CreateKeybind({
        Name = "Activation Key",
        Default = Enum.KeyCode.E,
        Mode = "Hold",
        Callback = function(key)
            print("[KittyWare] Keybound to:", key)
        end
    })

    -- Right Column: Visual Overlays & ESP
    local VisualsSection = MainSubTab:CreateSection({ Name = "Visual Overlays", Side = "Right" })

    local BoxEspToggle = VisualsSection:CreateToggle({
        Name = "Bounding Boxes",
        Default = false,
        Callback = function(v)
            print("[KittyWare] Bounding Boxes:", v)
        end
    })

    local EspColorPicker = VisualsSection:CreateColorPicker({
        Name = "Box Color",
        Default = Color3.fromRGB(175, 40, 255),
        Callback = function(c)
            print("[KittyWare] Box Color:", c)
        end
    })

    local MultiDropdown = VisualsSection:CreateDropdown({
        Name = "ESP Flags",
        Options = { "Distance", "Health Bar", "Weapon Name", "Armor", "Chams" },
        Default = { Distance = true, Health Bar = true },
        Multi = true,
        Callback = function(flags)
            print("[KittyWare] Flags Updated")
        end
    })

    local ResetBtn = VisualsSection:CreateButton({
        Name = "Reset All Settings",
        Callback = function()
            print("[KittyWare] Reset settings clicked!")
        end
    })

    -- Tab 2: Visuals
    local VisualsTab = Window:CreateTab({ Name = "Visuals" })
    local PlayersSubTab = VisualsTab:CreateSubTab({ Name = "Players" })
    local WorldSubTab = VisualsTab:CreateSubTab({ Name = "World" })

    local ChamsSection = PlayersSubTab:CreateSection({ Name = "Player Chams", Side = "Left" })
    ChamsSection:CreateToggle({ Name = "Enable Chams", Default = true })
    ChamsSection:CreateColorPicker({ Name = "Visible Color", Default = Color3.fromRGB(80, 220, 120) })
    ChamsSection:CreateColorPicker({ Name = "Occluded Color", Default = Color3.fromRGB(175, 40, 255) })

    -- Tab 3: Settings
    local SettingsTab = Window:CreateTab({ Name = "Settings" })
    local ConfigSubTab = SettingsTab:CreateSubTab({ Name = "Configs" })
    local ConfigSection = ConfigSubTab:CreateSection({ Name = "Configuration Manager", Side = "Left" })
    ConfigSection:CreateTextBox({ Name = "Config Name", Placeholder = "Enter slot name..." })
    ConfigSection:CreateButton({ Name = "Save Configuration" })
    ConfigSection:CreateButton({ Name = "Load Configuration" })
end

return Library
