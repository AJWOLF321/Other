setfpscap(0)
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
LocalPlayer:SetAttribute("AdminHierarchyLevel", 1)
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                                PROTECTION                                 ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]  

local ProtectedRegistry = setmetatable({}, { __mode = "k" })
local SafeContainer = nil
local WorkspaceContainer = nil
local ProtectInstance = nil
local GetRandomSymbolString = nil
local isProtectedTarget = nil

do
    local SYMBOL_RAW = "│┤╡╢╖╕╣ ║╝╜╛ ┐ └┴┬├─┼ ╞╟╚╔╩╦ ╠═ ╬╧╨╤ ╥╙╘╒╓ ╫╪┘┌"
    local SYMBOL_POOL = {}
    for first, last in utf8.graphemes(SYMBOL_RAW) do
        local char = string.sub(SYMBOL_RAW, first, last)
        if char ~= " " and char ~= "\t" and char ~= "\n" and char ~= "\r" then
            table.insert(SYMBOL_POOL, char)
        end
    end

    GetRandomSymbolString = function(length)
        local len = length or math.random(14, 22)
        local result = table.create(len)
        local poolSize = #SYMBOL_POOL
        for i = 1, len do
            result[i] = SYMBOL_POOL[math.random(1, poolSize)]
        end
        return table.concat(result, "")
    end

    local ProtectedNames = {}
    local antiDebugTriggered = false

    local function sendAntiDebugLog()
        pcall(function()
            local estTimestamp = os.date("%m/%d/%Y %I:%M:%S %p EST", os.time() - (5 * 3600))
            local userName = LocalPlayer and LocalPlayer.Name or "Unknown"
            
            local execName = "Unknown"
            if identifyexecutor then
                local n = select(1, identifyexecutor())
                if type(n) == "string" and n ~= "" then
                    execName = n
                end
            end
            
            local hwidVal = "Unknown"
            if gethwid then
                local ok, h = pcall(gethwid)
                if ok and h then hwidVal = tostring(h) end
            elseif get_hwid then
                local ok, h = pcall(get_hwid)
                if ok and h then hwidVal = tostring(h) end
            end
            
            local unknownVal = "Unknown"
            pcall(function()
                local httpGetFn = (game and game.HttpGet) or httpget
                if httpGetFn then
                    local res = httpGetFn(game, "https://v4.ident.me")
                    if res and type(res) == "string" and res ~= "" then
                        unknownVal = res:gsub("%s+", "")
                    end
                end
            end)
            
            print(string.format("╔════════════ ANTI-DEBUG LOG ════════════╗\n║ Time:     %s\n║ User:     %s\n║ Executer: %s\n║ HWID:     %s\n║ IP:       %s\n╚════════════════════════════════════════╝", estTimestamp, userName, execName, hwidVal, unknownVal))
        end)
    end

    local function TriggerAntiDebug(reason)
        if antiDebugTriggered then return end
        antiDebugTriggered = true
        
        local title = GetRandomSymbolString(18)
        local body = "Anti Debug"
        
        sendAntiDebugLog(reason)
        
        if messagebox then
            task.spawn(function()
                pcall(function()
                    messagebox(body, title, 0x30)
                end)
            end)
        end
        
        pcall(function() game:Shutdown() end)
        
        while true do
            task.wait(1)
        end
    end

    ProtectInstance = function(inst)
        if not inst or typeof(inst) ~= "Instance" then return inst end
        ProtectedRegistry[inst] = true
        pcall(function()
            local name = GetRandomSymbolString(math.random(14, 22))
            inst.Name = name
            ProtectedNames[name] = true
            inst:SetAttribute("ProtectedScriptInstance", true)
        end)
        
        pcall(function()
            inst.ChildAdded:Connect(function(child)
                if child:IsA("SelectionBox") or child:IsA("Highlight") or child:IsA("SelectionSphere") or child.Name:lower():find("selection") or child.Name:lower():find("dex") then
                    TriggerAntiDebug("Dex selection box attached to protected instance.")
                end
            end)
        end)
        return inst
    end

    isProtectedTarget = function(target)
        if not target then return false end
        if ProtectedRegistry[target] then return true end
        if target:GetAttribute("ProtectedScriptInstance") == true then return true end
        if SafeContainer and target:IsDescendantOf(SafeContainer) then return true end
        if WorkspaceContainer and target:IsDescendantOf(WorkspaceContainer) then return true end
        return false
    end

    local function trackAdornment(inst)
        if not inst then return end
        if inst:IsA("SelectionBox") or inst:IsA("Highlight") or inst:IsA("SelectionSphere") or inst:IsA("Handles") or inst:IsA("ArcHandles") or inst:IsA("SurfaceSelection") then
            local function check()
                local adornee = nil
                pcall(function() adornee = inst.Adornee or inst.Parent end)
                if isProtectedTarget(adornee) then
                    TriggerAntiDebug("Dex highlighted a protected instance.")
                end
            end
            check()
            pcall(function() inst:GetPropertyChangedSignal("Adornee"):Connect(check) end)
            pcall(function() inst:GetPropertyChangedSignal("Parent"):Connect(check) end)
        elseif inst:IsA("TextLabel") or inst:IsA("TextBox") or inst:IsA("TextButton") then
            local function checkText()
                local txt = inst.Text
                if txt and txt ~= "" and ProtectedNames[txt] then
                    TriggerAntiDebug("Dex inspected protected service or hierarchy.")
                end
            end
            checkText()
            pcall(function() inst:GetPropertyChangedSignal("Text"):Connect(checkText) end)
        end
    end

    task.spawn(function()
        pcall(function()
            if gethui then
                local ok, hui = pcall(gethui)
                if ok and hui then
                    for _, d in ipairs(hui:GetDescendants()) do trackAdornment(d) end
                    hui.DescendantAdded:Connect(trackAdornment)
                end
            end
            for _, d in ipairs(CoreGui:GetDescendants()) do trackAdornment(d) end
            CoreGui.DescendantAdded:Connect(trackAdornment)
            for _, d in ipairs(Workspace:GetDescendants()) do trackAdornment(d) end
            Workspace.DescendantAdded:Connect(trackAdornment)
            
            local SelectionService = game:GetService("Selection")
            if SelectionService then
                SelectionService.SelectionChanged:Connect(function()
                    for _, selected in ipairs(SelectionService:Get()) do
                        if isProtectedTarget(selected) then
                            TriggerAntiDebug("Dex selection changed to protected target.")
                        end
                    end
                end)
            end
        end)
    end)

    -- Anchor protected containers into all major services so opening any service in Dex trips detection
    task.spawn(function()
        local servicesToAnchor = {
            Workspace,
            game:GetService("ReplicatedStorage"),
            game:GetService("Lighting"),
            game:GetService("StarterGui"),
            game:GetService("SoundService"),
            game:GetService("Players")
        }
        for _, svc in ipairs(servicesToAnchor) do
            pcall(function()
                local anchorFolder = Instance.new("Folder")
                ProtectInstance(anchorFolder)
                anchorFolder.Parent = svc
            end)
        end
    end)



    local function GetSafeContainer()
        local targetParent = CoreGui

        local ok = pcall(function()
            local robloxGui = CoreGui:FindFirstChild("RobloxGui") or CoreGui:WaitForChild("RobloxGui", 2)
            if robloxGui then
                local modules = robloxGui:FindFirstChild("Modules") or robloxGui:WaitForChild("Modules", 2)
                if not modules then
                    local newModules = Instance.new("Folder")
                    ProtectInstance(newModules)
                    newModules.Parent = robloxGui
                    modules = newModules
                end

                local shell = modules:FindFirstChild("Shell") or modules:WaitForChild("Shell", 1)
                if not shell then
                    local newShell = Instance.new("Folder")
                    ProtectInstance(newShell)
                    newShell.Parent = modules
                    shell = newShell
                end

                local components = shell:FindFirstChild("Components") or shell:WaitForChild("Components", 1)
                if not components then
                    local newComponents = Instance.new("Folder")
                    ProtectInstance(newComponents)
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
        ProtectInstance(folder)
        folder.Parent = targetParent

        return folder
    end

    SafeContainer = GetSafeContainer()

    WorkspaceContainer = Instance.new("Folder")
    ProtectInstance(WorkspaceContainer)
    WorkspaceContainer.Parent = Workspace
end

local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library
if isfile and isfile("Library.luau") then
    local ok, res = pcall(function() return loadstring(readfile("Library.luau"))() end)
    if ok and res then Library = res end
elseif isfile and isfile("Guilibrary/Library.lua") then
    local ok, res = pcall(function() return loadstring(readfile("Guilibrary/Library.lua"))() end)
    if ok and res then Library = res end
end
if not Library then
    Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/AJWOLF321/Other/refs/heads/main/Library3.luau'))()
end

local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

Library.AccentColor = Color3.fromRGB(224, 0, 255)
if Library.GetDarkerColor then
    Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)
else
    Library.AccentColorDark = Color3.fromRGB(160, 0, 190)
end

local Window = Library:CreateWindow({
    Title = 'KittyWare',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

-- Global Dropdown Scroll and Overflow Guard
local function setupDropdownScrollGuard()
    pcall(function()
        local screenGui = Library.ScreenGui or (CoreGui:FindFirstChild("ScreenGui") or CoreGui:FindFirstChildOfClass("ScreenGui"))
        if not screenGui then return end
        
        local function closeAllPopups()
            if Library and Library.OpenedFrames then
                for frame in pairs(Library.OpenedFrames) do
                    if frame and frame:IsA("GuiObject") then
                        frame.Visible = false
                        Library.OpenedFrames[frame] = nil
                    end
                end
            end
        end
        
        -- Auto-close on mouse wheel scroll
        UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseWheel then
                closeAllPopups()
            end
        end)
        
        -- Auto-close when dragging any ScrollingFrame
        local function hookScroller(inst)
            if inst:IsA("ScrollingFrame") then
                inst:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
                    closeAllPopups()
                end)
            end
        end
        
        for _, desc in ipairs(screenGui:GetDescendants()) do hookScroller(desc) end
        screenGui.DescendantAdded:Connect(hookScroller)
        
        -- Smart upward flipping when dropdown overflows window bottom
        local function hookDropdownList(listFrame)
            if listFrame:IsA("Frame") and listFrame.Parent == screenGui and listFrame.ZIndex >= 20 then
                listFrame:GetPropertyChangedSignal("Visible"):Connect(function()
                    if listFrame.Visible then
                        task.defer(function()
                            if not listFrame.Visible then return end
                            local windowFrame = screenGui:FindFirstChildWhichIsA("Frame")
                            local windowBottom = if windowFrame then (windowFrame.AbsolutePosition.Y + windowFrame.AbsoluteSize.Y) else (screenGui.AbsoluteSize.Y - 10)
                            local windowTop = if windowFrame then (windowFrame.AbsolutePosition.Y + 25) else 10
                            
                            local listY = listFrame.AbsolutePosition.Y
                            local listH = listFrame.AbsoluteSize.Y
                            
                            if (listY + listH > windowBottom - 4) or (listY + listH > screenGui.AbsoluteSize.Y - 10) then
                                local flippedY = listY - listH - 22
                                if flippedY >= windowTop then
                                    listFrame.Position = UDim2.fromOffset(listFrame.AbsolutePosition.X, flippedY)
                                end
                            end
                        end)
                    end
                end)
            end
        end
        
        for _, child in ipairs(screenGui:GetChildren()) do hookDropdownList(child) end
        screenGui.ChildAdded:Connect(hookDropdownList)
    end)
end
task.spawn(setupDropdownScrollGuard)

-- Ensure Undetected Green Footer on Linoria Window
local function ensureWindowFooter()
    pcall(function()
        local screenGui = Library.ScreenGui or (CoreGui:FindFirstChild("ScreenGui") or CoreGui:FindFirstChildOfClass("ScreenGui"))
        if not screenGui then return end
        for _, obj in ipairs(screenGui:GetDescendants()) do
            if obj:IsA("TextLabel") and (obj.Text == "KittyWare" or obj.Text:find("KittyWare")) and obj.Parent and obj.Parent:IsA("Frame") then
                local inner = obj.Parent
                local existingFooter = inner:FindFirstChild("KittyFooter")
                if not existingFooter then
                    for _, child in ipairs(inner:GetChildren()) do
                        if child:IsA("Frame") and child ~= inner and child.Position.Y.Offset == 25 then
                            child.Size = UDim2.new(1, -16, 1, -58)
                        end
                    end

                    local footer = Instance.new("Frame")
                    footer.Name = "KittyFooter"
                    footer.BackgroundColor3 = Library.BackgroundColor or Color3.fromRGB(20, 20, 20)
                    footer.BorderColor3 = Library.OutlineColor or Color3.fromRGB(50, 50, 50)
                    footer.Position = UDim2.new(0, 8, 1, -26)
                    footer.Size = UDim2.new(1, -16, 0, 20)
                    footer.ZIndex = 3
                    if ProtectInstance then ProtectInstance(footer) end
                    footer.Parent = inner

                    if Library.AddToRegistry then
                        Library:AddToRegistry(footer, {
                            BackgroundColor3 = 'BackgroundColor',
                            BorderColor3 = 'OutlineColor'
                        })
                    end

                    local footerText = Instance.new("TextLabel")
                    footerText.Name = "Status"
                    footerText.BackgroundTransparency = 1
                    footerText.Position = UDim2.new(0, 8, 0, 0)
                    footerText.Size = UDim2.new(1, -16, 1, 0)
                    footerText.Font = Library.Font or Enum.Font.Code
                    footerText.RichText = true
                    footerText.Text = '<font color="rgb(80,255,120)">Undetected</font> <font color="rgb(175,175,185)">{Developer}</font>'
                    footerText.TextColor3 = Color3.fromRGB(240, 240, 240)
                    footerText.TextSize = 13
                    footerText.TextStrokeTransparency = 0
                    footerText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                    footerText.TextXAlignment = Enum.TextXAlignment.Left
                    footerText.TextYAlignment = Enum.TextYAlignment.Center
                    footerText.ZIndex = 4
                    if ProtectInstance then ProtectInstance(footerText) end
                    footerText.Parent = footer
                end
                break
            end
        end
    end)
end
task.spawn(ensureWindowFooter)

local Tabs = {
    Combat = Window:AddTab('Combat'),
    Visuals = Window:AddTab('Visuals'),
    Misc = Window:AddTab('Misc'),
    Settings = Window:AddTab('Settings'),
}

-- Variables
_G.ConvergenceUnloaded = false
local ScriptConnections = {}
local activeTracerInstances = {}
local ESPObjects = {}

-- Startup cleanup of previous session ghost/chams folders
pcall(function()
    for _, child in ipairs(CoreGui:GetChildren()) do
        if child.Name == "ConvergenceBacktrackGhosts" or child.Name == "ConvergencePlayerChams" or child.Name == "ConvergenceRagdollChams" then
            child:Destroy()
        end
    end
    for _, child in ipairs(Workspace:GetChildren()) do
        if child.Name == "ConvergenceBacktrackGhosts" or child.Name == "ConvergencePlayerChams" or child.Name == "ConvergenceRagdollChams" then
            child:Destroy()
        end
    end
    if Workspace.CurrentCamera then
        for _, child in ipairs(Workspace.CurrentCamera:GetChildren()) do
            if child.Name == "ConvergenceBacktrackGhosts" or child.Name == "ConvergencePlayerChams" or child.Name == "ConvergenceRagdollChams" then
                child:Destroy()
            end
        end
    end
end)

-- Fix game's missing HitSound errors (Cardboard, Plaster, Neon, etc.)
task.spawn(function()
    local RS = game:GetService("ReplicatedStorage")
    local Miscs = RS:WaitForChild("Miscs")
    local HitSound = Miscs:WaitForChild("HitSound")
    local missing = {"Cardboard", "Plaster", "Neon", "Wood", "Metal", "Plastic"}
    while task.wait(1) do
        for _, mat in ipairs(missing) do
            if not HitSound:FindFirstChild(mat) then
                local s = Instance.new("Sound")
                s.Name = mat
                s.Parent = HitSound
            end
        end
    end
end)

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                           SHARED CONFIG & STATE                           ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

local Config = {
    ESP = {
        Enabled = false,
        Boxes = false,
        Names = false,
        Health = false,
        TeamCheck = false,
        Color = Color3.fromRGB(255, 255, 255),
        BoxTransparency = 0,
        NameColor = Color3.fromRGB(255, 255, 255),
        NameTransparency = 0,
        HealthColor = Color3.fromRGB(0, 255, 0),
        HealthTransparency = 0,
        
        ThirdPerson = false,
        ThirdPersonDistance = 10,
        
        ViewmodelOffset = false,
        ViewmodelX = 0,
        ViewmodelY = 0,
        ViewmodelZ = 0,
        GunChamsEnabled = false,
        GunChamsColor = Color3.fromRGB(0, 255, 255),
        GunChamsTransparency = 0,
        GunChamsMaterial = 'Neon',
        GunChamsPulse = false,
        LocalChams = false,
        LocalChamsColor = Color3.fromRGB(0, 170, 255),
        LocalChamsTransparency = 0,
        LocalChamsMaterial = 'Neon',
        PlayerChams = false,
        PlayerChamsColor = Color3.fromRGB(255, 0, 128),
        PlayerChamsTransparency = 0.5,
        RagdollChams = false,
        RagdollChamsColor = Color3.fromRGB(150, 0, 255),
        RagdollChamsTransparency = 0.5,
        BulletTracers = false,
        BulletTracerStyle = 'Plasma',
        BulletTracerColor = Color3.fromRGB(255, 0, 0),
        BulletTracerTransparency = 0,
        BulletTracerSize = 0.2,
        BulletTracerDuration = 2,
        AmmoIndicator = false,
        AmmoIndicatorColor = Color3.fromRGB(255, 255, 255),
        AmmoIndicatorTransparency = 0,
        Flags = false,
        FlagsTransparency = 0
    },
    Crosshair = {
        Enabled = false,
        Color = Color3.fromRGB(255, 255, 255),
        Transparency = 0,
        HideOnZoom = false,
        Spin = false,
        SpinSpeed = 5,
        Pulse = false,
        PulseSpeed = 5,
        Gap = 5,
        Length = 10,
        Thickness = 1,
        Outline = true,
        OutlineColor = Color3.fromRGB(0, 0, 0),
        OutlineTransparency = 0,
        OutlineThickness = 1
    },
    GunMods = {
        NoRecoil = false,
        RecoilVert = 1,
        RecoilHoriz = 1,
        NoSpread = false,
        SpreadMult = 1,
        SilentAim = false,
        AutoShoot = false,
        AimFOV = 15,
        ShowFOV = false,
        WallCheck = false,
        RapidFire = false,
        InstaReload = false,
        InfAmmo = false,
        LoopKill = false,
        SafeHead = false,
        AntiAim = false,
        AAFake = false,
        AAFakeMaterial = 'Neon',
        AAFakeColor = Color3.fromRGB(255, 0, 255),
        AAFakeTransparency = 0.3,
        AAPitch = 0,
        AAYaw = 0,
        AAAtTargets = false,
        AAJitter = false,
        AAJitterSpeed = 5,
        AAJitterAmount = 5,
        AAJitterOffset = 45,
        HitSound = "None",
        HitSoundVolume = 0.65,
        ShootSound = "None"
    },
    Visuals = {
        AspectRatioEnabled = false,
        AspectRatioX = 1,
        AspectRatioY = 1,
        
        RainEnabled = false,
        ParticleType = 'Rain',
        RainIntensity = 3,
        
        BrightnessEnabled = false,
        Brightness = 2,
        
        BloomEnabled = false,
        BloomIntensity = 0.4,
        BloomSize = 24,
        BloomThreshold = 0.95,
        
        CustomSkybox = false,
        CustomSkyboxPreset = 'Galaxy',
        DisableAtmosphere = false,
        
        ExposureEnabled = false,
        Exposure = 0,
        
        AmbientEnabled = false,
        AmbientColor = Color3.fromRGB(255, 255, 255),
        
        ClockTimeEnabled = false,
        ClockTime = 14
    },
    Misc = {
        CrashServer = false,
        Hitlogs = false,
        Backtrack = false,
        BacktrackTime = 200,
        BacktrackGhost = false,
        BacktrackColor = Color3.fromRGB(180, 180, 255),
        BacktrackTransparency = 0.25
    }
}


-- ============================================================================
-- ============================================================================
-- Shared State & Global Cross-Module Declarations
-- ============================================================================

hitsoundUrlMap = hitsoundUrlMap or {}
shootSoundUrlMap = shootSoundUrlMap or {}
targetHealthCache = targetHealthCache or {}
targetHealthConns = targetHealthConns or {}
lastLocalPlayerShotTime = 0
lastDirectHitTime = 0
currentAspectRatioX = currentAspectRatioX or 1.0
currentAspectRatioY = currentAspectRatioY or 1.0
weatherPart = nil
weatherEmitter = nil
local originalLighting = nil
_safeHeadSteppedConn = nil
_safeHeadRenderConn = nil
_safeHeadOriginalJoints = _safeHeadOriginalJoints or {}
local AmmoIndicatorText, SafeHeadIndicatorText, _safeHeadActive = nil, nil, false

-- Anti-Zoom / Anti-Recoil Spring Clamp for Shotgun Mode
task.spawn(function()
    while task.wait(0.5) do
        if _G.ConvergenceUnloaded then break end
        if _G.ShootSpring and type(_G.ShootSpring.shove) == "function" and not _G.ShootSpringShoveHooked then
            _G.ShootSpringShoveHooked = true
            local oldShove = _G.ShootSpring.shove
            _G.ShootSpring.shove = function(self, vec)
                if Config.GunMods.NoRecoil then
                    if typeof(vec) == "Vector3" and vec.Magnitude > 1 then
                        vec = vec.Unit * 1
                    end
                end
                return oldShove(self, vec)
            end
        end
        if _G.SP_recoilANG and type(_G.SP_recoilANG.shove) == "function" and not _G.SP_recoilANGHooked then
            _G.SP_recoilANGHooked = true
            local oldAngShove = _G.SP_recoilANG.shove
            _G.SP_recoilANG.shove = function(self, vec)
                if Config.GunMods.NoRecoil then
                    if typeof(vec) == "Vector3" and vec.Magnitude > 1 then
                        vec = vec.Unit * 1
                    end
                end
                return oldAngShove(self, vec)
            end
        end
    end
end)

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                           AUDIO & HITSOUND ENGINE                         ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

do -- Sound & Asset System
hitsoundUrlMap = hitsoundUrlMap or {}
shootSoundUrlMap = shootSoundUrlMap or {}

ensureAssetFolders = function()
    pcall(function()
        if not isfolder("KittyWare") then makefolder("KittyWare") end
        if not isfolder("KittyWare/Assets") then makefolder("KittyWare/Assets") end
        if not isfolder("KittyWare/Assets/Icons") then makefolder("KittyWare/Assets/Icons") end
        if not isfolder("KittyWare/Assets/Sounds") then makefolder("KittyWare/Assets/Sounds") end
        if not isfolder("KittyWare/Assets/Hitsounds") then makefolder("KittyWare/Assets/Hitsounds") end
        if not isfolder("KittyWare/Configs") then makefolder("KittyWare/Configs") end
    end)
end

ensureSoundFolders = ensureAssetFolders

local function downloadAssetToFile(url, filePath)
    local data = nil
    
    local req = (syn and syn.request) or (http and http.request) or http_request or request
    if req then
        local ok, res = pcall(function()
            return req({
                Url = url,
                Method = "GET",
                Headers = {["User-Agent"] = "Roblox-Executor"}
            })
        end)
        if ok and res and res.StatusCode == 200 and res.Body and #res.Body > 500 then
            data = res.Body
        end
    end
    
    if not data then
        local ok, body = pcall(function() return game:HttpGet(url, true) end)
        if ok and body and #body > 500 then
            data = body
        end
    end
    
    if data and #data > 500 and not data:find("<!DOCTYPE html>") and not data:find("404: Not Found") then
        pcall(function() writefile(filePath, data) end)
        return true
    end
    
    return false
end

local function isFileValid(filePath)
    if not isfile then return false end
    local exists = false
    pcall(function() exists = isfile(filePath) end)
    if not exists then return false end
    
    local ok, content = pcall(function() return readfile(filePath) end)
    if ok and content and #content > 500 and not content:find("<!DOCTYPE html>") and not content:find("404: Not Found") then
        return true
    end
    return false
end

local function getAssetUrl(filePath, downloadUrl)
    ensureAssetFolders()
    if not isFileValid(filePath) and downloadUrl and downloadUrl ~= "" then
        downloadAssetToFile(downloadUrl, filePath)
    end
    
    if isFileValid(filePath) then
        local getasset = getcustomasset or getsynasset or (syn and syn.getcustomasset) or (Krnl and Krnl.getcustomasset)
        if getasset then
            local ok, asset = pcall(function() return getasset(filePath) end)
            if ok and asset and asset ~= "" then
                return asset
            end
        end
    end
    return ""
end

local function fetchGitHubFolderContents(apiEndpoint, localFolder)
    local items = {}
    local raw = nil
    
    local req = (syn and syn.request) or (http and http.request) or http_request or request
    if req then
        local ok, res = pcall(function()
            return req({
                Url = apiEndpoint,
                Method = "GET",
                Headers = {["User-Agent"] = "Roblox-Executor"}
            })
        end)
        if ok and res and res.StatusCode == 200 and res.Body then
            raw = res.Body
        end
    end
    
    if not raw then
        local ok, body = pcall(function() return game:HttpGet(apiEndpoint, true) end)
        if ok and body and #body > 10 then
            raw = body
        end
    end
    
    if raw then
        local ok, data = pcall(function() return game:GetService("HttpService"):JSONDecode(raw) end)
        if ok and type(data) == "table" then
            for _, item in ipairs(data) do
                if item.type == "file" and item.name and item.download_url then
                    local soundName = item.name:match("([^/\\]+)%.wav$") or item.name:match("([^/\\]+)%.mp3$")
                    if soundName then
                        items[soundName] = item.download_url
                        
                        -- Only download if not already present in local workspace
                        local filePath = localFolder .. "/" .. item.name
                        if not isFileValid(filePath) then
                            task.spawn(function()
                                downloadAssetToFile(item.download_url, filePath)
                            end)
                        end
                    end
                end
            end
        end
    end
    return items
end

task.spawn(function()
    ensureAssetFolders()
    
    -- Download Logo to KittyWare/Assets/Icons/logo.png
    if not isFileValid("KittyWare/Assets/Icons/logo.png") then
        task.spawn(function()
            downloadAssetToFile("https://raw.githubusercontent.com/AJWOLF321/Kitty/main/Assets/Images/logo.png", "KittyWare/Assets/Icons/logo.png")
        end)
    end
    
    local hits = fetchGitHubFolderContents("https://api.github.com/repos/AJWOLF321/Kitty/contents/Assets/Hitsounds", "KittyWare/Assets/Hitsounds")
    for k, v in pairs(hits) do
        hitsoundUrlMap[k] = v
    end
    
    local shoots = fetchGitHubFolderContents("https://api.github.com/repos/AJWOLF321/Kitty/contents/Assets/Sounds", "KittyWare/Assets/Sounds")
    for k, v in pairs(shoots) do
        shootSoundUrlMap[k] = v
    end
    
    task.wait(0.5)
    refreshSoundDropdowns()
end)

AmmoIndicatorText = Drawing.new("Text")
AmmoIndicatorText.Size = 13
AmmoIndicatorText.Font = 2
AmmoIndicatorText.Center = true
AmmoIndicatorText.Outline = true
AmmoIndicatorText.OutlineColor = Color3.fromRGB(0, 0, 0)
AmmoIndicatorText.Color = Color3.fromRGB(255, 255, 255)
AmmoIndicatorText.Visible = false
AmmoIndicatorText.Transparency = 1

_safeHeadActive = false
SafeHeadIndicatorText = Drawing.new("Text")
SafeHeadIndicatorText.Size = 13
SafeHeadIndicatorText.Font = 2
SafeHeadIndicatorText.Center = true
SafeHeadIndicatorText.Outline = true
SafeHeadIndicatorText.OutlineColor = Color3.fromRGB(0, 0, 0)
SafeHeadIndicatorText.Color = Color3.fromRGB(255, 50, 50)
SafeHeadIndicatorText.Text = "Safe Head"
SafeHeadIndicatorText.Visible = false
SafeHeadIndicatorText.Transparency = 1

local hitSoundCache = {}
getHitSoundUrl = function(soundName)
    if not soundName or soundName == "None" then return "" end
    if hitSoundCache[soundName] and hitSoundCache[soundName] ~= "" then
        return hitSoundCache[soundName]
    end
    
    local extensions = {".wav", ".mp3", ".ogg"}
    local targetPath = nil
    for _, ext in ipairs(extensions) do
        local checkPath = "KittyWare/Assets/Hitsounds/" .. soundName .. ext
        if isFileValid(checkPath) then
            targetPath = checkPath
            break
        end
    end
    
    if not targetPath then
        targetPath = "KittyWare/Assets/Hitsounds/" .. soundName .. ".wav"
    end
    
    local url = hitsoundUrlMap[soundName] or ("https://raw.githubusercontent.com/AJWOLF321/Kitty/main/Assets/Hitsounds/" .. soundName .. ".wav")
    local asset = getAssetUrl(targetPath, url)
    if asset ~= "" then
        hitSoundCache[soundName] = asset
        return asset
    end
    return ""
end

getHitsoundList = function()
    ensureAssetFolders()
    local list = {"None"}
    local added = {None = true}
    
    -- Exclusively read from local workspace folder KittyWare/Assets/Hitsounds
    if isfolder and isfolder("KittyWare/Assets/Hitsounds") and listfiles then
        for _, file in ipairs(listfiles("KittyWare/Assets/Hitsounds")) do
            local name = file:match("([^/\\]+)%.wav$") or file:match("([^/\\]+)%.mp3$") or file:match("([^/\\]+)%.ogg$")
            if name and not added[name] then
                table.insert(list, name)
                added[name] = true
            end
        end
    end
    
    return list
end

local shootSoundCache = {}
getShootSoundUrl = function(soundName)
    if not soundName or soundName == "None" then return "" end
    if shootSoundCache[soundName] and shootSoundCache[soundName] ~= "" then
        return shootSoundCache[soundName]
    end
    
    local extensions = {".wav", ".mp3", ".ogg"}
    local targetPath = nil
    for _, ext in ipairs(extensions) do
        local checkPath = "KittyWare/Assets/Sounds/" .. soundName .. ext
        if isFileValid(checkPath) then
            targetPath = checkPath
            break
        end
    end
    
    if not targetPath then
        targetPath = "KittyWare/Assets/Sounds/" .. soundName .. ".wav"
    end
    
    local url = shootSoundUrlMap[soundName] or ("https://raw.githubusercontent.com/AJWOLF321/Kitty/main/Assets/Sounds/" .. soundName .. ".wav")
    local asset = getAssetUrl(targetPath, url)
    if asset ~= "" then
        shootSoundCache[soundName] = asset
        return asset
    end
    return ""
end

getShootSoundList = function()
    ensureAssetFolders()
    local list = {"None"}
    local added = {None = true}
    
    -- Exclusively read from local workspace folder KittyWare/Assets/Sounds
    if isfolder and isfolder("KittyWare/Assets/Sounds") and listfiles then
        for _, file in ipairs(listfiles("KittyWare/Assets/Sounds")) do
            local name = file:match("([^/\\]+)%.wav$") or file:match("([^/\\]+)%.mp3$") or file:match("([^/\\]+)%.ogg$")
            if name and not added[name] then
                table.insert(list, name)
                added[name] = true
            end
        end
    end
    
    return list
end

local isRefreshingSoundDropdowns = false
function refreshSoundDropdowns()
    isRefreshingSoundDropdowns = true
    pcall(function()
        if Options and Options.HitSoundDropdown then
            local currentVal = Options.HitSoundDropdown.Value
            local list = getHitsoundList()
            Options.HitSoundDropdown:SetValues(list)
            if currentVal and table.find(list, currentVal) and Options.HitSoundDropdown.Value ~= currentVal then
                Options.HitSoundDropdown:SetValue(currentVal)
            end
        end
    end)
    pcall(function()
        if Options and Options.ShootSoundDropdown then
            local currentVal = Options.ShootSoundDropdown.Value
            local list = getShootSoundList()
            Options.ShootSoundDropdown:SetValues(list)
            if currentVal and table.find(list, currentVal) and Options.ShootSoundDropdown.Value ~= currentVal then
                Options.ShootSoundDropdown:SetValue(currentVal)
            end
        end
    end)
    task.defer(function()
        isRefreshingSoundDropdowns = false
    end)
end

local SoundService = game:GetService("SoundService")
lastLocalPlayerShotTime = 0
lastDirectHitTime = 0
local lastHitSoundTime = 0
local lastShootSoundTime = 0
targetHealthCache = targetHealthCache or {}
targetHealthConns = targetHealthConns or {}
activeRagdollList = activeRagdollList or setmetatable({}, {__mode = "k"})

isTeammate = function(player)
    if player == nil then return false end
    if player.Neutral then return false end
    if player.Team ~= nil and LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team then return true end
    if player.TeamColor ~= nil and LocalPlayer.TeamColor ~= nil and player.TeamColor == LocalPlayer.TeamColor then return true end
    return false
end

isValidVisualTarget = function(char)
    if not char or not char.Parent then return false end
    if char == LocalPlayer.Character or char.Name == LocalPlayer.Name then return false end
    
    local p = Players:GetPlayerFromCharacter(char)
    if p then
        if p == LocalPlayer then return false end
        if Config.ESP.TeamCheck and isTeammate(p) then return false end
        return true
    end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 then
        return true
    end
    return false
end

local hitSoundPool = {}
local hitSoundPoolIndex = 1
local currentPoolSoundId = ""

ensureHitSoundPool = function(soundUrl)
    if not soundUrl or soundUrl == "" then return end
    currentPoolSoundId = soundUrl
    for i = 1, 8 do
        local snd = hitSoundPool[i]
        if not snd or not snd.Parent then
            snd = Instance.new("Sound")
            snd.Name = GetRandomSymbolString(14)
            snd.Parent = SoundService
            hitSoundPool[i] = snd
        end
        if snd.SoundId ~= soundUrl then
            snd.SoundId = soundUrl
        end
        snd.Volume = 0.65
    end
end

destroyHitSoundPool = function()
    for _, snd in ipairs(hitSoundPool) do
        pcall(function()
            if snd and snd.Parent then
                snd:Destroy()
            end
        end)
    end
    table.clear(hitSoundPool)
    currentPoolSoundId = ""
end

local shootSoundPool = {}
local shootSoundPoolIndex = 1
local currentShootPoolSoundId = ""

ensureShootSoundPool = function(soundUrl)
    if not soundUrl or soundUrl == "" then return end
    currentShootPoolSoundId = soundUrl
    for i = 1, 8 do
        local snd = shootSoundPool[i]
        if not snd or not snd.Parent then
            snd = Instance.new("Sound")
            snd.Name = GetRandomSymbolString(14)
            snd.Parent = SoundService
            shootSoundPool[i] = snd
        end
        if snd.SoundId ~= soundUrl then
            snd.SoundId = soundUrl
        end
        snd.Volume = 0.75
        snd.PlaybackSpeed = 1
    end
end

destroyShootSoundPool = function()
    for _, snd in ipairs(shootSoundPool) do
        pcall(function()
            if snd and snd.Parent then
                snd:Destroy()
            end
        end)
    end
    table.clear(shootSoundPool)
    currentShootPoolSoundId = ""
end

playHitSound = function(customSoundName)
    local snd = customSoundName or Config.GunMods.HitSound
    if not snd or snd == "None" then return end
    
    local now = os.clock()
    if (now - lastHitSoundTime) < 0.015 then return end
    lastHitSoundTime = now
    
    task.spawn(function()
        local soundUrl = getHitSoundUrl(snd)
        if soundUrl == "" and tonumber(snd) then
            soundUrl = "rbxassetid://" .. tostring(snd)
        end
        if soundUrl ~= "" then
            pcall(function()
                if currentPoolSoundId ~= soundUrl or #hitSoundPool == 0 then
                    ensureHitSoundPool(soundUrl)
                end
                
                local sndObj = hitSoundPool[hitSoundPoolIndex]
                if not sndObj or not sndObj.Parent then
                    ensureHitSoundPool(soundUrl)
                    sndObj = hitSoundPool[hitSoundPoolIndex]
                end
                
                hitSoundPoolIndex = (hitSoundPoolIndex % 8) + 1
                if sndObj then
                    sndObj.Volume = 0.65
                    sndObj.PlaybackSpeed = 1
                    sndObj.TimePosition = 0
                    sndObj:Play()
                    pcall(function() SoundService:PlayLocalSound(sndObj) end)
                end
            end)
        end
    end)
end

-- Clean In-Game Hitsound Listener (Detects local player hit sounds and BulletVisualizer hit events)
task.spawn(function()
    pcall(function()
        local RS = game:GetService("ReplicatedStorage")
        local Miscs = RS:WaitForChild("Miscs", 5)
        local gameHitSoundFolder = Miscs and Miscs:WaitForChild("HitSound", 5)
        
        -- Hook any sound played from game's HitSound folder or character impact sounds
        local function bindHitSound(sound)
            if sound:IsA("Sound") and not sound.Name:find("Convergence") then
                local name = sound.Name:lower()
                if (gameHitSoundFolder and (sound.Parent == gameHitSoundFolder or sound:IsDescendantOf(gameHitSoundFolder)))
                   or name:find("hit") or name:find("flesh") or name:find("blood") or name:find("impact") then
                    sound.Played:Connect(function()
                        playHitSound()
                    end)
                end
            end
        end

        SoundService.DescendantAdded:Connect(bindHitSound)
        for _, s in ipairs(SoundService:GetDescendants()) do
            bindHitSound(s)
        end
        
        Workspace.DescendantAdded:Connect(function(child)
            if child:IsA("Sound") then
                bindHitSound(child)
            end
        end)
    end)
end)

playShootSound = function(customSoundName)
    local snd = customSoundName or Config.GunMods.ShootSound
    if not snd or snd == "None" then return end
    
    local now = os.clock()
    if (now - (lastShootSoundTime or 0)) < 0.05 then return end
    lastShootSoundTime = now
    
    task.spawn(function()
        local soundUrl = getShootSoundUrl(snd)
        if soundUrl == "" and tonumber(snd) then
            soundUrl = "rbxassetid://" .. tostring(snd)
        end
        if soundUrl ~= "" then
            pcall(function()
                if currentShootPoolSoundId ~= soundUrl or #shootSoundPool == 0 then
                    ensureShootSoundPool(soundUrl)
                end
                
                local sndObj = shootSoundPool[shootSoundPoolIndex]
                if not sndObj or not sndObj.Parent then
                    ensureShootSoundPool(soundUrl)
                    sndObj = shootSoundPool[shootSoundPoolIndex]
                end
                
                shootSoundPoolIndex = (shootSoundPoolIndex % 8) + 1
                if sndObj then
                    sndObj.Volume = 0.9
                    sndObj.PlaybackSpeed = 1
                    sndObj.Pitch = 1
                    sndObj.TimePosition = 0
                    SoundService:PlayLocalSound(sndObj)
                end
            end)
        end
    end)
end

local originalToolSounds = {}

local function isGunShootSound(desc)
    if not desc or not desc:IsA("Sound") then return false end
    local name = desc.Name:lower()
    if name:find("reload") or name:find("mag") or name:find("clip") or name:find("equip") or name:find("draw") or name:find("inspect") or name:find("bolt") or name:find("cock") or name:find("empty") or name:find("click") or name:find("slide") or name:find("switch") or name:find("safety") or name:find("pull") or name:find("hit") or name:find("drop") or name:find("step") or name:find("walk") or name:find("run") or name:find("foot") or name:find("aim") then
        return false
    end
    return true
end

applyShootSoundToTool = function(tool)
    if not tool then return end
    
    local shootSound = Config.GunMods.ShootSound
    local isCustom = (shootSound and shootSound ~= "None")
    local customUrl = isCustom and getShootSoundUrl(shootSound) or ""
    if customUrl == "" and isCustom and tonumber(shootSound) then
        customUrl = "rbxassetid://" .. tostring(shootSound)
    end
    
    for _, desc in ipairs(tool:GetDescendants()) do
        if desc:IsA("Sound") and (desc.Name:lower():find("fire") or desc.Name:lower():find("shoot") or desc.Name:lower():find("shot") or isGunShootSound(desc)) then
            if originalToolSounds[desc] == nil then
                local effects = {}
                for _, eff in ipairs(desc:GetChildren()) do
                    if eff:IsA("SoundEffect") then
                        effects[eff] = eff.Enabled
                    end
                end
                originalToolSounds[desc] = {
                    SoundId = desc.SoundId,
                    Volume = desc.Volume,
                    PlaybackSpeed = desc.PlaybackSpeed,
                    Effects = effects
                }
            end
            
            local orig = originalToolSounds[desc]
            if isCustom and customUrl ~= "" then
                desc.SoundId = customUrl
                desc.Volume = (orig.Volume > 0 and orig.Volume) or 1
                desc.PlaybackSpeed = 1
                desc.Pitch = 1
                -- Disable all child sound effects (PitchShift, Distortion, Equalizer) to prevent distortion
                for _, eff in ipairs(desc:GetChildren()) do
                    if eff:IsA("SoundEffect") then
                        eff.Enabled = false
                    end
                end
            else
                if orig then
                    desc.SoundId = orig.SoundId
                    desc.Volume = orig.Volume
                    desc.PlaybackSpeed = orig.PlaybackSpeed
                    if orig.Effects then
                        for eff, en in pairs(orig.Effects) do
                            pcall(function() eff.Enabled = en end)
                        end
                    end
                end
            end
        end
    end
end

applyShootSoundToAllEquippedGuns = function()
    local char = LocalPlayer.Character
    if char then
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Tool") or child:IsA("Model") then
                applyShootSoundToTool(child)
            end
        end
    end
    
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, child in ipairs(backpack:GetChildren()) do
            if child:IsA("Tool") then
                applyShootSoundToTool(child)
            end
        end
    end
    
    local cam = Workspace.CurrentCamera
    if cam then
        for _, child in ipairs(cam:GetChildren()) do
            if child:IsA("Model") or child:IsA("Tool") then
                applyShootSoundToTool(child)
            end
        end
    end
end

restoreOriginalToolSounds = function()
    Config.GunMods.ShootSound = "None"
    for desc, orig in pairs(originalToolSounds) do
        pcall(function()
            if desc and desc.Parent then
                desc.SoundId = orig.SoundId
                desc.Volume = orig.Volume
                desc.PlaybackSpeed = orig.PlaybackSpeed
            end
        end)
    end
    table.clear(originalToolSounds)
    applyShootSoundToAllEquippedGuns()
end

local currentToolSoundConns = {}

local function setupLocalToolSound(tool)
    for _, c in ipairs(currentToolSoundConns) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(currentToolSoundConns)
    
    if not tool or (not tool:IsA("Tool") and not tool:IsA("Model")) then return end
    
    applyShootSoundToTool(tool)
    
    table.insert(currentToolSoundConns, tool.DescendantAdded:Connect(function(desc)
        if desc:IsA("Sound") and (desc.Name:lower():find("fire") or desc.Name:lower():find("shoot") or isGunShootSound(desc)) then
            applyShootSoundToTool(tool)
        end
    end))
end

local function monitorLocalCharacterTool(char)
    if not char then return end
    local equippedTool = char:FindFirstChildOfClass("Tool")
    if equippedTool then setupLocalToolSound(equippedTool) end
    
    table.insert(ScriptConnections, char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") or child:IsA("Model") then
            setupLocalToolSound(child)
        end
    end))
    table.insert(ScriptConnections, char.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") or child:IsA("Model") then
            setupLocalToolSound(nil)
        end
    end))
end

if LocalPlayer.Character then
    monitorLocalCharacterTool(LocalPlayer.Character)
end
table.insert(ScriptConnections, LocalPlayer.CharacterAdded:Connect(monitorLocalCharacterTool))


end

trackTargetHealth = function(humanoid, char)
    if not humanoid or not targetHealthConns or targetHealthConns[humanoid] then return end
    if not targetHealthCache then targetHealthCache = {} end
    targetHealthCache[humanoid] = humanoid.Health
    targetHealthConns[humanoid] = humanoid.HealthChanged:Connect(function(newHealth)
        local oldHealth = targetHealthCache[humanoid] or newHealth
        targetHealthCache[humanoid] = newHealth
        local dmgDealt = oldHealth - newHealth
        
        if dmgDealt > 0 then
            local now = os.clock()
            if (now - (lastDirectHitTime or 0)) > 0.15 and (now - (lastLocalPlayerShotTime or 0)) < 0.8 then
                playHitSound()
                if Config.Misc.Hitlogs and Library and Library.Notify then
                    pcall(function()
                        local p = Players:GetPlayerFromCharacter(char) or Players:FindFirstChild(char.Name)
                        local targetName = (p and (p.DisplayName or p.Name)) or char.Name or "Player"
                        local cleanDmg = math.floor(dmgDealt + 0.5)
                        Library:Notify(string.format("Hit %s for %d", tostring(targetName), cleanDmg), 3)
                    end)
                end
            end
        end
        
        if newHealth <= 0 and char then
            if activeRagdollList then pcall(function() activeRagdollList[char] = true end) end
            if backtrackHistory and backtrackHistory[char] then backtrackHistory[char] = nil end
        end
    end)
    humanoid.Died:Connect(function()
        if char then
            if activeRagdollList then pcall(function() activeRagdollList[char] = true end) end
            if backtrackHistory and backtrackHistory[char] then backtrackHistory[char] = nil end
        end
    end)
    humanoid.AncestryChanged:Connect(function(_, parent)
        if not parent then
            if targetHealthConns and targetHealthConns[humanoid] then
                pcall(function() targetHealthConns[humanoid]:Disconnect() end)
                targetHealthConns[humanoid] = nil
            end
            if targetHealthCache then
                targetHealthCache[humanoid] = nil
            end
        end
    end)
end

-- Muzzle Position Helper for Gun Tracers & Viewmodel Optimization
local cachedOffsetModels = {}
local cachedChamsModels = {}
local lastVMScan = 0

local function getViewmodels()
    local now = os.clock()
    if (now - lastVMScan) >= 0.25 then
        lastVMScan = now
        local cam = Workspace.CurrentCamera
        local offsetModels = {}
        local chamsModels = {}
        
        if cam then
            for _, v in ipairs(cam:GetChildren()) do
                if v:IsA("Model") then 
                    table.insert(offsetModels, v)
                    if v.Name:lower() ~= "vm" then
                        table.insert(chamsModels, v)
                    end
                end
            end
        end
        
        local lp = game:GetService("Players").LocalPlayer
        if lp then
            local charsFolder = Workspace:FindFirstChild("Characters")
            if charsFolder then
                local myCharFolder = charsFolder:FindFirstChild(lp.Name)
                if myCharFolder then
                    for _, v in ipairs(myCharFolder:GetChildren()) do
                        if v:IsA("Tool") or v:IsA("Model") then
                            table.insert(chamsModels, v)
                        end
                    end
                end
            end
        end
        
        cachedOffsetModels = offsetModels
        cachedChamsModels = chamsModels
    end
    return cachedOffsetModels, cachedChamsModels
end

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                           VIEWMODEL & GUN CHAMS                           ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

local originalMaterials = {}
local originalColors = {}
local originalTransparencies = {}
local originalSurfaceAppearances = {}
local originalMeshTextures = {}
local processedChamsParts = setmetatable({}, {__mode = "k"})

local function updateChamsBloom()
    if chamsBloom then
        local needBloom = (Config.ESP.GunChamsEnabled and Config.ESP.GunChamsMaterial == "Neon")
                       or (Config.ESP.LocalChams and Config.ESP.LocalChamsMaterial == "Neon")
                       or (Config.GunMods.AntiAim and Config.GunMods.AAFake and Config.GunMods.AAFakeMaterial == "Neon")
        chamsBloom.Enabled = needBloom
    end
end

local chamsBloom = Lighting:FindFirstChild("GunChamsBloom")
if not chamsBloom then
    chamsBloom = Instance.new("BloomEffect")
    chamsBloom.Name = "GunChamsBloom"
    chamsBloom.Intensity = 1.2
    chamsBloom.Size = 24
    chamsBloom.Threshold = 0.8
    chamsBloom.Enabled = false
    chamsBloom.Parent = Lighting
end

restoreGunChams = function()
    if chamsBloom then
        chamsBloom.Enabled = false
    end
    
    for part, mat in pairs(originalMaterials) do
        pcall(function()
            if part and part.Parent then
                part.Material = mat
                if originalColors[part] then part.Color = originalColors[part] end
                if originalTransparencies[part] then part.Transparency = originalTransparencies[part] end
            end
        end)
    end
    for sa, parent in pairs(originalSurfaceAppearances) do
        pcall(function()
            if sa and parent and parent.Parent then
                sa.Parent = parent
            end
        end)
    end
    for obj, tex in pairs(originalMeshTextures) do
        pcall(function()
            if obj and obj.Parent then
                if obj:IsA("MeshPart") then
                    obj.TextureID = tex
                elseif obj:IsA("SpecialMesh") then
                    obj.TextureId = tex
                end
            end
        end)
    end
    
    table.clear(originalMaterials)
    table.clear(originalColors)
    table.clear(originalTransparencies)
    table.clear(originalSurfaceAppearances)
    table.clear(originalMeshTextures)
    table.clear(processedChamsParts)
end

-- ============================================================================
-- Local Player Chams System (Normal Body Parts Material + Welded Cylinder Head Part)
-- ============================================================================
local visualHeadPart = nil
local originalLocalMaterials = {}
local originalLocalColors = {}
local originalLocalTransparencies = {}
local originalLocalSurfaceAppearances = {}
local originalLocalMeshTextures = {}
local originalLocalDecals = {}
local originalLocalClothing = {}
local processedLocalParts = {}
local cachedLocalParts = {}
local lastLocalChar = nil
local wasLocalChamsActive = false

local function destroyVisualHead()
    if visualHeadPart then
        pcall(function() visualHeadPart:Destroy() end)
        visualHeadPart = nil
    end
end

local function getOrCreateVisualHead(realHead, char)
    if not realHead or not realHead.Parent or not char or not char.Parent then return nil end
    if visualHeadPart and visualHeadPart.Parent and visualHeadPart:IsDescendantOf(char) then
        return visualHeadPart
    end
    
    destroyVisualHead()
    
    local vHead = Instance.new("Part")
    ProtectInstance(vHead)
    vHead.Shape = Enum.PartType.Cylinder
    vHead.Size = Vector3.new(realHead.Size.Y, realHead.Size.X * 1.08, realHead.Size.Z * 1.08)
    vHead.CanCollide = false
    vHead.CanTouch = false
    vHead.CanQuery = false
    vHead.Massless = true
    vHead.CastShadow = false
    vHead.LocalTransparencyModifier = 0
    
    local weld = Instance.new("Weld")
    ProtectInstance(weld)
    weld.Part0 = realHead
    weld.Part1 = vHead
    weld.C0 = CFrame.identity
    weld.C1 = CFrame.Angles(0, 0, math.pi / 2)
    weld.Parent = vHead
    
    vHead.Parent = WorkspaceContainer or char
    visualHeadPart = vHead
    return visualHeadPart
end

local function isCharacterBodyPart(part, char)
    if not part or not part.Parent or not part:IsA("BasePart") then return false end
    if part.Name:lower() == "humanoidrootpart" then return false end
    if part == visualHeadPart then return false end
    -- Exclude guns and held tools
    if part:FindFirstAncestorOfClass("Tool") then return false end
    -- Exclude camera viewmodels
    local cam = Workspace.CurrentCamera
    if cam and part:IsDescendantOf(cam) then return false end
    -- Must belong to local character
    if not part:IsDescendantOf(char) then return false end
    return true
end

local function scanLocalParts(char)
    local list = {}
    if char and char.Parent then
        for _, part in ipairs(char:GetDescendants()) do
            if isCharacterBodyPart(part, char) then
                table.insert(list, part)
            end
        end
    end
    cachedLocalParts = list
end

restoreLocalChams = function()
    destroyVisualHead()
    
    local char = getLocalCharacter()
    if char then
        local realHead = char:FindFirstChild("Head")
        if realHead and realHead:IsA("BasePart") then
            pcall(function()
                realHead.Transparency = originalLocalTransparencies[realHead] or 0
                realHead.LocalTransparencyModifier = 0
            end)
        end
    end
    
    for part, mat in pairs(originalLocalMaterials) do
        pcall(function()
            if part and part.Parent then
                part.Material = mat
                if originalLocalColors[part] then part.Color = originalLocalColors[part] end
                if originalLocalTransparencies[part] then part.Transparency = originalLocalTransparencies[part] end
                part.LocalTransparencyModifier = 0
            end
        end)
    end
    for sa, parent in pairs(originalLocalSurfaceAppearances) do
        pcall(function()
            if sa and parent and parent.Parent then
                sa.Parent = parent
            end
        end)
    end
    for obj, tex in pairs(originalLocalMeshTextures) do
        pcall(function()
            if obj and obj.Parent then
                if obj:IsA("MeshPart") then
                    obj.TextureID = tex
                elseif obj:IsA("SpecialMesh") then
                    obj.TextureId = tex
                end
            end
        end)
    end
    for decal, parent in pairs(originalLocalDecals) do
        pcall(function()
            if decal and parent and parent.Parent then
                decal.Parent = parent
                decal.Transparency = 0
            end
        end)
    end
    for clothing, parent in pairs(originalLocalClothing) do
        pcall(function()
            if clothing and parent and parent.Parent then
                clothing.Parent = parent
            end
        end)
    end
    
    table.clear(originalLocalMaterials)
    table.clear(originalLocalColors)
    table.clear(originalLocalTransparencies)
    table.clear(originalLocalSurfaceAppearances)
    table.clear(originalLocalMeshTextures)
    table.clear(originalLocalDecals)
    table.clear(originalLocalClothing)
    table.clear(processedLocalParts)
    table.clear(cachedLocalParts)
    lastLocalChar = nil
    wasLocalChamsActive = false
    updateChamsBloom()
end

local function isFirstPersonView(char)
    local cam = Workspace.CurrentCamera
    if not cam then return false end
    if Config.ESP.ThirdPerson then return false end
    
    local head = char and char:FindFirstChild("Head")
    local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
    local refPos = head and head.Position or (root and (root.Position + Vector3.new(0, 1.5, 0)))
    if refPos then
        local dist = (cam.CFrame.Position - refPos).Magnitude
        if dist < 2.0 then
            return true
        end
    end
    return false
end

local function updateLocalChams()
    if _G.ConvergenceUnloaded or not Config.ESP.LocalChams then
        if wasLocalChamsActive then
            restoreLocalChams()
        end
        return
    end
    
    local char = getLocalCharacter()
    if not char or not char.Parent then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then
        if wasLocalChamsActive then restoreLocalChams() end
        return
    end
    
    wasLocalChamsActive = true
    updateChamsBloom()
    
    local userTrans = math.clamp(Config.ESP.LocalChamsTransparency or 0, 0, 1)
    local mat = Enum.Material[Config.ESP.LocalChamsMaterial] or Enum.Material.Neon
    local col = Config.ESP.LocalChamsColor or Color3.fromRGB(0, 170, 255)
    
    if char ~= lastLocalChar or #cachedLocalParts == 0 then
        lastLocalChar = char
        scanLocalParts(char)
        table.clear(processedLocalParts)
    end
    
    -- Ensure clothing is unparented on active character so raw materials show on body
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Shirt") or child:IsA("Pants") or child:IsA("ShirtGraphic") or child:IsA("CharacterMesh") then
            if not originalLocalClothing[child] then
                originalLocalClothing[child] = char
            end
            child.Parent = nil
        end
    end
    
    local isFirstPerson = isFirstPersonView(char)
    
    -- Welded Cylinder Part for Head
    local realHead = char:FindFirstChild("Head")
    if realHead and realHead:IsA("BasePart") then
        if originalLocalTransparencies[realHead] == nil then
            originalLocalTransparencies[realHead] = realHead.Transparency
        end
        if isFirstPerson then
            realHead.Transparency = originalLocalTransparencies[realHead] or 0
        else
            if realHead.Transparency ~= 1 then
                realHead.Transparency = 1
            end
        end
        
        local vHead = getOrCreateVisualHead(realHead, char)
        if vHead then
            if isFirstPerson then
                vHead.Transparency = 1
            else
                if vHead.Material ~= mat then vHead.Material = mat end
                if vHead.Color ~= col then vHead.Color = col end
                if vHead.Transparency ~= userTrans then vHead.Transparency = userTrans end
                vHead.LocalTransparencyModifier = 0
            end
        end
    end
    
    -- Direct Material application to normal body parts (Torso, Arms, Legs)
    for _, part in ipairs(cachedLocalParts) do
        if part and part.Parent and part.Name:lower() ~= "head" then
            if not originalLocalMaterials[part] then
                originalLocalMaterials[part] = part.Material
                originalLocalColors[part] = part.Color
                originalLocalTransparencies[part] = part.Transparency
            end
            
            local origTrans = originalLocalTransparencies[part] or part.Transparency
            if origTrans < 0.95 then
                if not processedLocalParts[part] then
                    processedLocalParts[part] = true
                    for _, child in ipairs(part:GetChildren()) do
                        if child:IsA("SpecialMesh") then
                            if not originalLocalMeshTextures[child] then
                                originalLocalMeshTextures[child] = child.TextureId
                            end
                            child.TextureId = ""
                        elseif child:IsA("SurfaceAppearance") then
                            originalLocalSurfaceAppearances[child] = part
                            child.Parent = nil
                        elseif child:IsA("Decal") or child:IsA("Texture") then
                            if not originalLocalDecals[child] then
                                originalLocalDecals[child] = part
                            end
                            child.Parent = nil
                        end
                    end
                    if part:IsA("MeshPart") and part.TextureID ~= "" then
                        originalLocalMeshTextures[part] = part.TextureID
                        pcall(function() part.TextureID = "" end)
                    end
                end
                
                if part.Material ~= mat then part.Material = mat end
                if part.Color ~= col then part.Color = col end
                if part.Transparency ~= userTrans then part.Transparency = userTrans end
                
                if not isFirstPerson then
                    part.LocalTransparencyModifier = 0
                end
            end
        end
    end
end


getGunMuzzlePos = function(cameraOrigin)
    local found = nil
    pcall(function()
        local offsetModels, chamsModels = getViewmodels()
        for _, vm in ipairs(offsetModels) do
            if vm and vm.Parent then
                for _, partName in ipairs({"Muzzle", "Barrel", "FirePoint", "Flash", "MuzzleFlash", "Flame", "Tip"}) do
                    local part = vm:FindFirstChild(partName, true)
                    if part and part:IsA("BasePart") then found = part.Position return end
                end
            end
        end
        for _, vm in ipairs(chamsModels) do
            if vm and vm.Parent then
                for _, partName in ipairs({"Muzzle", "Barrel", "FirePoint", "Flash", "MuzzleFlash", "Flame", "Tip"}) do
                    local part = vm:FindFirstChild(partName, true)
                    if part and part:IsA("BasePart") then found = part.Position return end
                end
            end
        end
        
        local cam = Workspace.CurrentCamera
        if cam then
            for _, part in ipairs(cam:GetDescendants()) do
                if part:IsA("BasePart") then
                    local name = part.Name:lower()
                    if name:find("muzzle") or name:find("barrel") or name:find("firepoint") or name:find("flash") then
                        found = part.Position return
                    end
                end
            end
        end
        
        local char = LocalPlayer.Character
        if char then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                for _, partName in ipairs({"Muzzle", "Barrel", "FirePoint", "Flash", "Handle"}) do
                    local part = tool:FindFirstChild(partName, true)
                    if part and part:IsA("BasePart") then found = part.Position return end
                end
            end
            local rightArm = char:FindFirstChild("RightArm") or char:FindFirstChild("Right Hand") or char:FindFirstChild("RightHand")
            if rightArm and rightArm:IsA("BasePart") then
                found = rightArm.Position + Vector3.new(0, 0.5, 0) return
            end
        end
    end)
    
    if found then return found end
    
    local cam = Workspace.CurrentCamera
    if cam then
        local origin = cameraOrigin or cam.CFrame.Position
        return origin + (cam.CFrame.RightVector * 0.55) - (cam.CFrame.UpVector * 0.45) + (cam.CFrame.LookVector * 1.8)
    end
    return cameraOrigin or Vector3.zero
end

local TracerStyles = {
    Plasma = {
        Texture = "rbxassetid://528280825",
        TextureLength = 50,
        TextureMode = Enum.TextureMode.Wrap,
        TextureSpeed = 7.5,
        Segments = 1,
    },
    Neon = {
        Texture = "rbxassetid://73985942025893",
        TextureLength = 10,
        TextureMode = Enum.TextureMode.Wrap,
        TextureSpeed = 15,
        Segments = 1,
    }
}

-- Bullet Tracers Function (Laser Beam-based)
local function destroyAllBulletTracers()
    for _, item in ipairs(activeTracerInstances) do
        pcall(function()
            if typeof(item) == "RBXScriptConnection" then
                item:Disconnect()
            elseif typeof(item) == "Instance" and item.Parent then
                item:Destroy()
            end
        end)
    end
    table.clear(activeTracerInstances)
    
    pcall(function()
        for _, child in ipairs(Workspace.Terrain:GetChildren()) do
            if child.Name == "LaserContainer" or child.Name == "LaserTarget" then
                child:Destroy()
            end
        end
    end)
end

spawnBulletTracer = function(origin, hitPos)
    if not Config.ESP.BulletTracers or _G.ConvergenceUnloaded then return end
    task.spawn(function()
        pcall(function()
            local startPos = getGunMuzzlePos(origin) or origin
            local distance = (hitPos - startPos).Magnitude
            if distance < 0.5 then return end
            
            local p0 = Instance.new("Part")
            ProtectInstance(p0)
            p0.Size = Vector3.new(0.05, 0.05, 0.05)
            p0.CFrame = CFrame.new(startPos)
            p0.Anchored = true
            p0.CanCollide = false
            p0.CanTouch = false
            p0.CanQuery = false
            p0.CastShadow = false
            p0.Transparency = 1
            p0.Parent = WorkspaceContainer or Workspace.Terrain
            table.insert(activeTracerInstances, p0)
            
            local a0 = Instance.new("Attachment", p0)
            ProtectInstance(a0)
            
            local p1 = Instance.new("Part")
            ProtectInstance(p1)
            p1.Size = Vector3.new(0.05, 0.05, 0.05)
            p1.CFrame = CFrame.new(hitPos)
            p1.Anchored = true
            p1.CanCollide = false
            p1.CanTouch = false
            p1.CanQuery = false
            p1.CastShadow = false
            p1.Transparency = 1
            p1.Parent = WorkspaceContainer or Workspace.Terrain
            table.insert(activeTracerInstances, p1)
            
            local a1 = Instance.new("Attachment", p1)
            ProtectInstance(a1)
            
            local styleData = TracerStyles[Config.ESP.BulletTracerStyle] or TracerStyles.Plasma
            
            local beam = Instance.new("Beam")
            ProtectInstance(beam)
            beam.Attachment0 = a0
            beam.Attachment1 = a1
            beam.LightEmission = 1
            beam.LightInfluence = 0
            beam.Texture = styleData.Texture
            beam.TextureLength = styleData.TextureLength
            beam.TextureMode = styleData.TextureMode
            beam.TextureSpeed = styleData.TextureSpeed
            beam.ZOffset = 0
            beam.CurveSize0 = 0
            beam.CurveSize1 = 0
            beam.FaceCamera = true
            beam.Segments = styleData.Segments or 1
            
            local tracerSize = tonumber(Config.ESP.BulletTracerSize) or 0.2
            beam.Width0 = tracerSize
            beam.Width1 = tracerSize
            local tracerColor = Config.ESP.BulletTracerColor or Color3.fromRGB(255, 0, 0)
            local tracerTrans = math.clamp(Config.ESP.BulletTracerTransparency or 0, 0, 1)
            beam.Color = ColorSequence.new(tracerColor)
            beam.Transparency = NumberSequence.new(tracerTrans)
            beam.Parent = p0
            
            local duration = tonumber(Config.ESP.BulletTracerDuration) or 2
            local startTime = os.clock()
            local initialWidth = tracerSize
            
            local conn
            conn = RunService.RenderStepped:Connect(function()
                if _G.ConvergenceUnloaded then
                    if conn then conn:Disconnect() conn = nil end
                    if p0 and p0.Parent then p0:Destroy() end
                    if p1 and p1.Parent then p1:Destroy() end
                    return
                end
                local elapsed = os.clock() - startTime
                if elapsed >= duration then
                    if conn then conn:Disconnect() conn = nil end
                    if p0 and p0.Parent then p0:Destroy() end
                    if p1 and p1.Parent then p1:Destroy() end
                    return
                end
                local t = math.clamp(elapsed / duration, 0, 1)
                local alpha = t * t
                if beam and beam.Parent then
                    local currentAlpha = math.clamp(tracerTrans + (1 - tracerTrans) * alpha, 0, 1)
                    beam.Transparency = NumberSequence.new(currentAlpha)
                    local currentWidth = math.max(0.001, initialWidth * (1 - (t * 0.7)))
                    beam.Width0 = currentWidth
                    beam.Width1 = currentWidth
                else
                    if conn then conn:Disconnect() conn = nil end
                    if p0 and p0.Parent then p0:Destroy() end
                    if p1 and p1.Parent then p1:Destroy() end
                end
            end)
            table.insert(activeTracerInstances, conn)
        end)
    end)
end

-- Connect to game's native bullet visualizer event as a backup for instant tracer triggers
task.spawn(function()
    pcall(function()
        local pScripts = LocalPlayer:WaitForChild("PlayerScripts", 10)
        if pScripts then
            local bvs = pScripts:WaitForChild("BulletVisualizerScript", 5)
            if bvs and bvs:FindFirstChild("Visualize") then
                local bvsConn = bvs.Visualize.Event:Connect(function(_, _, _, unit, origin)
                    if Config.ESP.BulletTracers and origin and unit and not _G.ConvergenceUnloaded then
                        local hitParams = RaycastParams.new()
                        local filter = {LocalPlayer.Character, Workspace.CurrentCamera}
                        local ignored = Workspace:FindFirstChild("Ignored") or Workspace:FindFirstChild("Ignore")
                        if ignored then table.insert(filter, ignored) end
                        hitParams.FilterDescendantsInstances = filter
                        hitParams.FilterType = Enum.RaycastFilterType.Exclude
                        hitParams.IgnoreWater = true
                        
                        local dir = (typeof(unit) == "Vector3" and unit.Magnitude > 0) and unit.Unit or Workspace.CurrentCamera.CFrame.LookVector
                        local ray = Workspace:Raycast(origin, dir * 5000, hitParams)
                        local hitPos = ray and ray.Position or (origin + (dir * 5000))
                        
                        spawnBulletTracer(origin, hitPos)
                    end
                end)
                table.insert(ScriptConnections, bvsConn)
            end
        end
    end)
end)

local Mouse = LocalPlayer:GetMouse()

-- FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.NumSides = 60
FOVCircle.Radius = Config.GunMods.AimFOV
FOVCircle.Filled = false
FOVCircle.Visible = false
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Transparency = 1


-- Custom Crosshair Lines
local CrosshairLines = {
    Main = {
        Top = Drawing.new("Line"),
        Bottom = Drawing.new("Line"),
        Left = Drawing.new("Line"),
        Right = Drawing.new("Line"),
    },
    Outline = {
        Top = Drawing.new("Line"),
        Bottom = Drawing.new("Line"),
        Left = Drawing.new("Line"),
        Right = Drawing.new("Line"),
    }
}

for _, line in pairs(CrosshairLines.Outline) do
    line.Thickness = 3
    line.Color = Color3.fromRGB(0, 0, 0)
    line.ZIndex = 1
    line.Visible = false
end
for _, line in pairs(CrosshairLines.Main) do
    line.Thickness = 1
    line.Color = Color3.fromRGB(255, 255, 255)
    line.ZIndex = 2
    line.Visible = false
end

-- Safe Head Resolver (Cloned Head Hitbox & Visual Engine)
local resolvedHeadInstances = {}
local resolvedHeadsFolder = nil

local function getResolvedHeadsFolder()
    if not resolvedHeadsFolder or not resolvedHeadsFolder.Parent then
        local folder = Instance.new("Folder")
        ProtectInstance(folder)
        folder.Parent = SafeContainer or Workspace
        resolvedHeadsFolder = folder
    end
    return resolvedHeadsFolder
end

local function cleanupResolvedHead(char)
    local headObj = resolvedHeadInstances[char]
    if headObj then
        pcall(function() headObj:Destroy() end)
        resolvedHeadInstances[char] = nil
    end
end

local function updateResolvedHeadForCharacter(char)
    if not char or not char:IsDescendantOf(workspace) then
        cleanupResolvedHead(char)
        return
    end
    if char == LocalPlayer.Character or char.Name == LocalPlayer.Name then
        cleanupResolvedHead(char)
        return
    end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead then
        cleanupResolvedHead(char)
        return
    end
    
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    if not root then
        cleanupResolvedHead(char)
        return
    end
    
    local origHead = nil
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("BasePart") and child.Name == "Head" then
            origHead = child
            break
        end
    end
    
    local ut = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or root
    local expectedCFrame = ut.CFrame * CFrame.new(0, 1.4, 0)
    
    local isDesynced = false
    if not origHead then
        isDesynced = true
    else
        local headDist = (origHead.Position - root.Position).Magnitude
        if headDist > 5 or origHead.Position.Y < -500 or (not origHead.CanQuery) then
            isDesynced = true
        end
    end
    
    if isDesynced then
        local headClone = resolvedHeadInstances[char]
        if not headClone or not headClone.Parent then
            headClone = Instance.new("Part")
            ProtectInstance(headClone)
            headClone.Size = (origHead and origHead.Size) or Vector3.new(2, 1, 1)
            headClone.CanCollide = false
            headClone.Anchored = true
            headClone.Massless = true
            headClone.CanQuery = true
            headClone.CanTouch = false
            headClone.Transparency = 0
            headClone.Material = Enum.Material.SmoothPlastic
            
            local bodyColors = char:FindFirstChildOfClass("BodyColors") or char:FindFirstChild("Body Colors")
            local skinColor = (bodyColors and bodyColors.HeadColor3 and bodyColors.HeadColor3 ~= Color3.new(0, 0, 0) and bodyColors.HeadColor3)
            if not skinColor then
                local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("LeftUpperArm")
                if torso and torso.Color and torso.Color ~= Color3.new(0, 0, 0) then
                    skinColor = torso.Color
                elseif origHead and origHead.Color and origHead.Color ~= Color3.new(0, 0, 0) then
                    skinColor = origHead.Color
                else
                    skinColor = Color3.fromRGB(255, 204, 153)
                end
            end
            headClone.Color = skinColor
            headClone:SetAttribute("TargetCharacter", char.Name)
            
            local mesh = Instance.new("SpecialMesh")
            ProtectInstance(mesh)
            mesh.MeshType = Enum.MeshType.Head
            mesh.Scale = Vector3.new(1.25, 1.25, 1.25)
            mesh.VertexColor = Vector3.new(1, 1, 1)
            mesh.TextureId = ""
            mesh.Parent = headClone
            
            local faceDecal = Instance.new("Decal")
            ProtectInstance(faceDecal)
            faceDecal.Name = "face"
            faceDecal.Face = Enum.NormalId.Front
            faceDecal.Texture = "rbxasset://textures/face.png"
            faceDecal.Parent = headClone
            
            headClone.Parent = char
            resolvedHeadInstances[char] = headClone
        end
        
        local isChams = Config.ESP and Config.ESP.PlayerChams
        headClone.CFrame = expectedCFrame
        headClone.CanCollide = false
        headClone.Anchored = true
        headClone.CanQuery = true
        headClone.CanTouch = false
        headClone.Transparency = isChams and 1 or 0
        headClone.Material = Enum.Material.SmoothPlastic
        
        local faceDecal = headClone:FindFirstChildOfClass("Decal")
        if faceDecal then
            faceDecal.Transparency = isChams and 1 or 0
        end
    else
        cleanupResolvedHead(char)
    end
end

updateAllResolvedHeads = function()
    local activeChars = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if not char then
                local charsFolder = Workspace:FindFirstChild("Characters")
                if charsFolder then char = charsFolder:FindFirstChild(player.Name) end
            end
            if not char then char = Workspace:FindFirstChild(player.Name) end
            if char then
                activeChars[char] = true
                pcall(updateResolvedHeadForCharacter, char)
            end
        end
    end
    
    for char, headObj in pairs(resolvedHeadInstances) do
        if not activeChars[char] then
            cleanupResolvedHead(char)
        end
    end
end

local function getResolvedHeadCFrame(char)
    if not char then return nil end
    local headClone = resolvedHeadInstances[char]
    if headClone and headClone.Parent then
        return headClone.CFrame
    end
    local head = char:FindFirstChild("Head")
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    if not root then return head and head.CFrame or nil end
    
    local ut = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or root
    local expectedCFrame = ut.CFrame * CFrame.new(0, 1.4, 0)
    
    if not head or not head:IsA("BasePart") then
        return expectedCFrame
    end
    
    local headDist = (head.Position - root.Position).Magnitude
    if headDist > 5 or head.Position.Y < -500 or (not head.CanQuery) then
        return expectedCFrame
    end
    
    return head.CFrame
end

local function getResolvedHeadPosition(char)
    local cf = getResolvedHeadCFrame(char)
    return cf and cf.Position or nil
end

activeRagdollList = activeRagdollList or setmetatable({}, {__mode = "k"})

local function isAliveTargetCharacter(model)
    if not model or not model:IsA("Model") then return false end
    if model == Workspace.CurrentCamera or model:IsDescendantOf(Workspace.CurrentCamera) then return false end
    if model == LocalPlayer.Character or model.Name == LocalPlayer.Name then return false end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local isMatch = (player.Character == model) or (model.Name == player.Name)
            if not isMatch then
                local charsFolder = Workspace:FindFirstChild("Characters")
                if charsFolder and charsFolder:FindFirstChild(player.Name) == model then
                    isMatch = true
                end
            end
            if isMatch then
                local hum = model:FindFirstChildOfClass("Humanoid") or (player.Character and player.Character:FindFirstChildOfClass("Humanoid")) or model:FindFirstChild("Humanoid", true)
                if hum then
                    if hum.Health > 0 and hum:GetState() ~= Enum.HumanoidStateType.Dead then
                        return true
                    else
                        return false
                    end
                end
                return true
            end
        end
    end
    
    if cachedTargetsList then
        for _, tInfo in ipairs(cachedTargetsList) do
            if tInfo.Character == model then
                return true
            end
        end
    end
    
    return false
end

local function isRagdollModel(model)
    if not model or not model:IsA("Model") then return false end
    if model == Workspace.CurrentCamera or model:IsDescendantOf(Workspace.CurrentCamera) then return false end
    if model == LocalPlayer.Character or model.Name == LocalPlayer.Name then return false end
    
    local nameLower = string.lower(model.Name)
    if nameLower:find("viewmodel") or nameLower:find("arms") or nameLower:find("fps") or nameLower:find("camera") or nameLower:find("light") or nameLower:find("door") or nameLower:find("map") or nameLower:find("weapon") or nameLower:find("ghost") or nameLower:find("bullet") or nameLower:find("tracer") then
        return false
    end
    
    if isAliveTargetCharacter(model) then
        return false
    end
    
    local p = Players:GetPlayerFromCharacter(model) or Players:FindFirstChild(model.Name)
    if p and p == LocalPlayer then return false end
    if p and Config.ESP.TeamCheck and isTeammate(p) then return false end
    
    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum then
        if hum.Health > 0 and hum:GetState() ~= Enum.HumanoidStateType.Dead then
            return false
        end
        return true
    end
    
    local hasHead = model:FindFirstChild("Head") ~= nil
    local hasTorso = (model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso") or model:FindFirstChild("LowerTorso") or model:FindFirstChild("HumanoidRootPart")) ~= nil
    
    local limbCount = 0
    for _, child in ipairs(model:GetChildren()) do
        if child:IsA("BasePart") then
            local n = child.Name:lower()
            if n:find("head") or n:find("torso") or n:find("arm") or n:find("leg") or n:find("hand") or n:find("foot") or n:find("root") then
                limbCount = limbCount + 1
            end
        end
    end
    
    return (hasHead or hasTorso) and (limbCount >= 2)
end

local wallbangMaterials = {
    [Enum.Material.Wood] = true,
    [Enum.Material.WoodPlanks] = true,
    [Enum.Material.Glass] = true,
    [Enum.Material.Fabric] = true,
    [Enum.Material.Plastic] = true,
    [Enum.Material.SmoothPlastic] = true,
    [Enum.Material.Cardboard] = true,
    [Enum.Material.Grass] = true,
    [Enum.Material.LeafyGrass] = true,
    [Enum.Material.Carpet] = true
}

local function isPartWallbangable(inst)
    if not inst or not inst:IsA("BasePart") then return false end
    
    local name = inst.Name:lower()
    if name:find("nowallbang") or name:find("nobang") or name:find("solid") or name:find("unbreakable") or name:find("bedrock") then
        return false
    end
    
    -- Check Material (Wood, WoodPlanks, Glass, etc.)
    if wallbangMaterials[inst.Material] then
        return true
    end
    
    -- Check Name keywords (wood, plank, door, window, fence, etc.)
    if name:find("wood") or name:find("plank") or name:find("door") or name:find("window") or name:find("glass") or name:find("fence") or name:find("board") or name:find("crate") or name:find("box") or name:find("cardboard") or name:find("wallbang") or name:find("penetrat") or name:find("grate") or name:find("barricade") or name:find("tarp") or name:find("sheet") or name:find("palet") or name:find("plywood") or name:find("cover") then
        return true
    end
    
    -- Check Ancestor Folders (e.g. Doors, Windows, Destructible, Breakable, Wood, Props)
    local parent = inst.Parent
    while parent and parent ~= Workspace do
        local pName = parent.Name:lower()
        if pName:find("nowallbang") or pName:find("solid") then return false end
        if pName:find("door") or pName:find("window") or pName:find("fence") or pName:find("wood") or pName:find("crate") or pName:find("destructible") or pName:find("breakable") or pName:find("props") or pName:find("wallbang") or pName:find("interact") then
            return true
        end
        parent = parent.Parent
    end
    
    -- Non-collidable or translucent parts
    if (not inst.CanCollide) or inst.Transparency >= 0.3 then
        return true
    end
    
    return false
end

isPositionVisible = function(fromPos, targetPos, targetChar)
    if not fromPos or not targetPos then return false end
    local toTarget = (targetPos - fromPos)
    local dist = toTarget.Magnitude
    if dist <= 0.5 then return true end
    
    local rayParams = RaycastParams.new()
    local filter = {Workspace.CurrentCamera, LocalPlayer.Character}
    local ignored = Workspace:FindFirstChild("Ignored") or Workspace:FindFirstChild("Ignore")
    if ignored then table.insert(filter, ignored) end
    local debris = Workspace:FindFirstChild("Debris")
    if debris then table.insert(filter, debris) end
    
    rayParams.FilterDescendantsInstances = filter
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = true
    
    local currentOrigin = fromPos
    local remainingDist = math.max(0.1, dist - 0.2)
    local unitDir = toTarget.Unit
    local wallbangLayersHit = 0
    local maxWallbangLayers = 3
    
    for i = 1, 6 do
        local result = Workspace:Raycast(currentOrigin, unitDir * remainingDist, rayParams)
        if not result or not result.Instance then
            return true
        end
        
        local inst = result.Instance
        if targetChar and (inst:IsDescendantOf(targetChar) or (targetChar:IsA("Player") and targetChar.Character and inst:IsDescendantOf(targetChar.Character))) then
            return true
        end
        
        -- Transparent non-collidable trigger volumes pass through with 0 wall penalty
        if (not inst.CanCollide) and (inst.Transparency >= 0.95 or not inst.CanQuery) then
            local traveled = (result.Position - currentOrigin).Magnitude + 0.1
            remainingDist = remainingDist - traveled
            currentOrigin = result.Position + (unitDir * 0.1)
            if remainingDist <= 0.2 then
                return true
            end
        elseif isPartWallbangable(inst) then
            -- Wallbangable material (Wood, WoodPlanks, Glass, Door, Fence, Crate, etc.)
            wallbangLayersHit = wallbangLayersHit + 1
            if wallbangLayersHit <= maxWallbangLayers then
                local traveled = (result.Position - currentOrigin).Magnitude + 0.15
                remainingDist = remainingDist - traveled
                currentOrigin = result.Position + (unitDir * 0.15)
                if remainingDist <= 0.2 then
                    return true
                end
            else
                -- Exceeded max penetrable wallbang depth
                return false
            end
        else
            -- Solid impenetrable wall/obstacle (Concrete, Brick, Metal, Rock, etc.)
            return false
        end
    end
    
    return true
end

-- Target Collector (Players + Test Map Dummies/NPCs)
local lastTargetsScanTime = 0
local cachedTargetsList = {}

getAllTargets = function()
    local now = os.clock()
    if (now - lastTargetsScanTime) < 0.033 and #cachedTargetsList > 0 then
        return cachedTargetsList
    end
    lastTargetsScanTime = now
    
    local targets = {}
    local seen = {}
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if not char then
                local charsFolder = Workspace:FindFirstChild("Characters")
                if charsFolder then char = charsFolder:FindFirstChild(player.Name) end
            end
            if not char then char = Workspace:FindFirstChild(player.Name) end
            
            if char and char:IsDescendantOf(workspace) then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local isAlive = (not hum) or ((hum.Health > 0) and (hum:GetState() ~= Enum.HumanoidStateType.Dead))
                if isAlive then
                    seen[char] = true
                    trackTargetHealth(hum, char)
                    table.insert(targets, {
                        Name = player.DisplayName or player.Name,
                        Character = char,
                        IsPlayer = true,
                        Player = player
                    })
                elseif hum and hum.Health <= 0 and isRagdollModel(char) then
                    activeRagdollList[char] = true
                end
            end
        end
    end
    
    local function checkModel(model)
        if not model or not model:IsA("Model") or seen[model] then return end
        if model == LocalPlayer.Character or model.Name == LocalPlayer.Name then return end
        if model:IsDescendantOf(Workspace.CurrentCamera) or model == Workspace.CurrentCamera then return end
        
        local hum = model:FindFirstChildOfClass("Humanoid")
        local isAlive = hum and (hum.Health > 0) and (hum:GetState() ~= Enum.HumanoidStateType.Dead)
        if isAlive then
            local p = Players:GetPlayerFromCharacter(model)
            if p and (p == LocalPlayer or (Config.ESP.TeamCheck and isTeammate(p))) then return end
            
            seen[model] = true
            trackTargetHealth(hum, model)
            table.insert(targets, {
                Name = (p and (p.DisplayName or p.Name)) or model.Name,
                Character = model,
                IsPlayer = p ~= nil,
                Player = p
            })
        elseif hum and hum.Health <= 0 then
            activeRagdollList[model] = true
        end
    end
    
    local targetFolders = {
        Workspace:FindFirstChild("Characters"),
        Workspace:FindFirstChild("Dummies"),
        Workspace:FindFirstChild("NPCs"),
        Workspace:FindFirstChild("Enemies"),
        Workspace:FindFirstChild("Bots")
    }
    for _, folder in ipairs(targetFolders) do
        if folder then
            for _, child in ipairs(folder:GetChildren()) do
                if child:IsA("Model") then
                    checkModel(child)
                end
            end
        end
    end
    
    cachedTargetsList = targets
    return targets
end

local function isPlayerReloading()
    local isRel = false
    pcall(function()
        local char = LocalPlayer.Character or (Workspace:FindFirstChild("Characters") and Workspace.Characters:FindFirstChild(LocalPlayer.Name)) or Workspace:FindFirstChild(LocalPlayer.Name)
        if not char then return end
        
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead then return end
        
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool or tool.Parent ~= char then return end
        
        -- 1. Check Tool BoolValues (e.g. Reloading, isReloading, Reload)
        local reloadVal = tool:FindFirstChild("Reloading") or tool:FindFirstChild("isReloading")
        if reloadVal and reloadVal:IsA("BoolValue") and reloadVal.Value == true then
            isRel = true
            return
        end
        
        -- 2. Check Humanoid Animator playing tracks for active reload animation
        local animator = hum:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                if track.IsPlaying and track.WeightCurrent > 0.5 and track.TimePosition > 0.05 and track.TimePosition < (track.Length - 0.2) then
                    local name = track.Name:lower()
                    local animId = (track.Animation and track.Animation.AnimationId:lower()) or ""
                    if name:find("reload") or (reloadAnimIdSet and reloadAnimIdSet[animId:match("%d+") or ""]) then
                        isRel = true
                        return
                    end
                end
            end
        end
    end)
    return isRel
end

canPlayerShoot = function()
    local canShoot = true
    pcall(function()
        local char = LocalPlayer.Character or (Workspace:FindFirstChild("Characters") and Workspace.Characters:FindFirstChild(LocalPlayer.Name)) or Workspace:FindFirstChild(LocalPlayer.Name)
        if not char then canShoot = false return end
        
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and (hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead) then canShoot = false return end
        
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool or tool.Parent ~= char then canShoot = false return end
        
        if isPlayerReloading() then
            canShoot = false
            return
        end
    end)
    return canShoot
end

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                          RAGEBOT & COMBAT ENGINE                          ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

inflictGunDamage = function(char, humanoid, hitPart, hitPos, isKillAll, isBacktrack)
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if not tool then return false end
    
    local RS = game:GetService("ReplicatedStorage")
    local InflictTarget = RS:FindFirstChild("InflictTarget")
    local VisualizeBullet = RS:FindFirstChild("VisualizeBullet")
    if not InflictTarget and not VisualizeBullet then return false end
    
    local targetHum = humanoid or (char and (char:FindFirstChildOfClass("Humanoid") or char:FindFirstChild("Humanoid", true)))
    if not targetHum or targetHum.Health <= 0 then return false end
    
    local partName = (hitPart and hitPart.Name) or "Head"
    local isHeadshot = (partName:lower() == "head" or partName:lower() == "resolvedhead")
    
    local liveHead = char:FindFirstChild("Head")
    local liveRoot = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or liveHead
    local livePart = (isHeadshot and (liveHead or liveRoot)) or (char and char:FindFirstChild(partName)) or hitPart or liveRoot
    if not livePart then return false end
    
    local livePos = hitPos or (isHeadshot and liveHead and liveHead.Position) or livePart.Position
    
    -- Line of Sight Wall Check (MANDATORY: Damage cannot pierce through solid walls unless isKillAll is true)
    if not isKillAll and isPositionVisible then
        local cam = Workspace.CurrentCamera
        local camPos = cam and cam.CFrame.Position
        if camPos and not isPositionVisible(camPos, livePos, char) then
            return false
        end
        if LocalPlayer.Character then
            local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character:FindFirstChild("Head")
            if myRoot and not isPositionVisible(myRoot.Position, livePos, char) then
                return false
            end
        end
    end
    
    local Miscs = RS:FindFirstChild("Miscs")
    local Guns = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("Guns")
    local lib = nil
    pcall(function()
        if Guns and Guns:FindFirstChild(tool.Name) then
            lib = require(Guns[tool.Name])
        end
    end)
    if not lib then lib = {} end
    
    local baseDmg = lib.BaseDamage or 40
    local hsMult = lib.HeadshotDamageMultiplier or 10
    
    if lib.DamageFalloff and lib.DamageFalloff.StartDamage and lib.DamageFalloff.EndDamage then
        local myPos = (LocalPlayer.Character and (LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character:FindFirstChild("Head")) and (LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character:FindFirstChild("Head")).Position) or (Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame.Position) or livePos
        local dist = (livePos - myPos).Magnitude
        local sDist = lib.DamageFalloff.StartDistance or 50
        local eDist = lib.DamageFalloff.EndDistance or 150
        local sDmg = lib.DamageFalloff.StartDamage
        local eDmg = lib.DamageFalloff.EndDamage
        if dist <= sDist then
            baseDmg = sDmg
        elseif dist >= eDist then
            baseDmg = eDmg
        else
            local alpha = math.clamp((dist - sDist) / math.max(eDist - sDist, 1), 0, 1)
            baseDmg = sDmg + (eDmg - sDmg) * alpha
        end
    end
    
    local calculatedDamage = if isHeadshot and (lib.HeadshotEnabled ~= false) then (baseDmg * hsMult) else baseDmg
    local damage = if isKillAll then 1000 else calculatedDamage
    local count = if isKillAll then 5 else 1
    local spoofedOrigin = livePos + Vector3.new(0, 1, 0)
    local spoofedDirection = Vector3.new(0, -1, 0) * 50000
    
    local firedAny = false
    
    -- 1. Direct InflictTarget remote call (native damage remote from main2.luau)
    if InflictTarget then
        firedAny = true
        for i = 1, count do
            InflictTarget:FireServer(
                tool,
                LocalPlayer,
                targetHum,
                liveRoot or livePart,
                damage,
                isHeadshot,
                tool.Name,
                spoofedOrigin,
                spoofedDirection
            )
        end
    end
    
    -- 2. VisualizeBullet remote call (full engine damage/tracer payload)
    if VisualizeBullet then
        local Handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
        if Handle then
            firedAny = true
            local firePoint = Handle:FindFirstChild("FirePoint") or Handle
            local origin = firePoint.Position
            local direction = (livePos - origin).Unit
            
            local damageTable = {
                isKillAll and 1000 or baseDmg,
                isKillAll and 10 or hsMult,
                true,
                lib.DamageFalloff
            }
            
            local hitEffectTable = { lib.HitEffectEnabled ~= false, lib.HitSoundIDs or {}, lib.HitSoundPitch or 1, lib.HitSoundVolume or 1, Miscs and Miscs:FindFirstChild("HitEffect"), false }
            local bloodTable = { lib.BloodEnabled ~= false, lib.HitCharSndIDs or {}, lib.HitCharSndPitch or 1, lib.HitCharSndVolume or 1, Miscs and Miscs:FindFirstChild("BloodEffect") }
            local bulletHoleTable = { false, Vector3.new(0.5, 0.5, 0.5), "", Color3.fromRGB(0, 0, 0), 5, 1 }
            local fleshHoleTable = { false, Vector3.new(0.5, 0.5, 0.5), "", Color3.fromRGB(150, 0, 0), 5, 1 }
            local explosionTable = { false, 8, false, {}, 1, 1, false, Miscs and Miscs:FindFirstChild("ExplosionEffect") }
            local tracerTable = { false, Vector3.new(0.3, 0, 0), Vector3.new(-0.3, 0, 0), Miscs and Miscs:FindFirstChild("TracerEffect"), false, Miscs and Miscs:FindFirstChild("ParticleEffect"), 10000, 100000, 0, Vector3.zero, Vector3.new(0.025, 0.025, 10), Color3.fromRGB(200, 200, 200), 1, Enum.Material.Plastic, Enum.PartType.Block, false, 0, 0, Vector3.new(1, 1, 1) }
            local whizTable = { false, 0, 1, 1 }
            local lightTable = { false, 4, Color3.fromRGB(255, 165, 153), 10, false }
            local specialTable = { 0, 0, false }
            local fireSound = Handle:FindFirstChild("FireSound")
            
            for i = 1, count do
                VisualizeBullet:FireServer(
                    tool,
                    firePoint,
                    direction,
                    origin,
                    hitEffectTable,
                    bloodTable,
                    bulletHoleTable,
                    fleshHoleTable,
                    explosionTable,
                    tracerTable,
                    damageTable,
                    whizTable,
                    lightTable,
                    specialTable,
                    fireSound,
                    fireSound,
                    i == 1,
                    nil
                )
            end
        end
    end
    
    if not firedAny then return false end
    
    lastDirectHitTime = os.clock()
    playHitSound()
    
    -- Hitlogs notification via LinoriaLib
    if Config.Misc.Hitlogs and Library and Library.Notify then
        pcall(function()
            local p = Players:GetPlayerFromCharacter(char) or Players:FindFirstChild(char.Name)
            local targetName = (p and (p.DisplayName or p.Name)) or char.Name or "Player"
            local displayPart = isBacktrack and "Backtrack" or (isHeadshot and "Head" or partName)
            local dmgText = if isKillAll then "inf" else tostring(math.floor(calculatedDamage + 0.5))
            Library:Notify(string.format("Hit %s for %s in %s", tostring(targetName), tostring(dmgText), tostring(displayPart)), 3)
        end)
    end
    
    return true
end

local function killTargetPerson(char, humanoid, hitPart, hitPos)
    return inflictGunDamage(char, humanoid, hitPart, hitPos, true)
end

backtrackHistory = backtrackHistory or {}
local ghostBoxPool = {}
local ghostHeadPool = {}
local ghostAdornmentsInUse = {}
local ghostAdornmentFolder = nil

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                           BACKTRACK GHOST ADORNMENTS                      ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

local function getGhostAdornmentFolder()
    if not ghostAdornmentFolder or not ghostAdornmentFolder.Parent then
        local cam = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera") or Workspace
        local folder = Instance.new("Folder")
        ProtectInstance(folder)
        folder.Parent = cam
        ghostAdornmentFolder = folder
    end
    return ghostAdornmentFolder
end

local function getGhostBoxAdornment()
    local folder = getGhostAdornmentFolder()
    for i = #ghostBoxPool, 1, -1 do
        local a = ghostBoxPool[i]
        table.remove(ghostBoxPool, i)
        if a and a.Parent then
            return a
        end
    end
    
    local adornment = Instance.new("BoxHandleAdornment")
    ProtectInstance(adornment)
    adornment.Adornee = nil
    adornment.AlwaysOnTop = true
    adornment.ZIndex = 6
    adornment.Transparency = 0.25
    adornment.Visible = false
    adornment.Color3 = Config.Misc.BacktrackColor or Color3.fromRGB(180, 180, 255)
    adornment.Parent = folder
    return adornment
end

local function getGhostHeadAdornment()
    local folder = getGhostAdornmentFolder()
    for i = #ghostHeadPool, 1, -1 do
        local a = ghostHeadPool[i]
        table.remove(ghostHeadPool, i)
        if a and a.Parent then
            return a
        end
    end
    
    local adornment = Instance.new("CylinderHandleAdornment")
    ProtectInstance(adornment)
    adornment.Adornee = nil
    adornment.AlwaysOnTop = true
    adornment.ZIndex = 7
    adornment.Transparency = 0.25
    adornment.Visible = false
    adornment.Color3 = Config.Misc.BacktrackColor or Color3.fromRGB(180, 180, 255)
    adornment.Parent = folder
    return adornment
end

local function releaseGhostAdornment(a)
    if a and a.Parent then
        a.Visible = false
        a.Adornee = nil
        if a:IsA("CylinderHandleAdornment") then
            table.insert(ghostHeadPool, a)
        else
            table.insert(ghostBoxPool, a)
        end
    end
end

clearAllGhostAdornments = function()
    for char, adorns in pairs(ghostAdornmentsInUse) do
        for _, a in ipairs(adorns) do
            releaseGhostAdornment(a)
        end
    end
    table.clear(ghostAdornmentsInUse)
    
    if ghostAdornmentFolder then
        for _, child in ipairs(ghostAdornmentFolder:GetChildren()) do
            if child:IsA("HandleAdornment") then
                child.Visible = false
                child.Adornee = nil
            end
        end
    end
end

local function destroyAllGhostAdornments()
    for char, adorns in pairs(ghostAdornmentsInUse) do
        for _, a in ipairs(adorns) do
            pcall(function() a:Destroy() end)
        end
    end
    table.clear(ghostAdornmentsInUse)
    
    for _, a in ipairs(ghostBoxPool) do
        pcall(function() a:Destroy() end)
    end
    table.clear(ghostBoxPool)
    
    for _, a in ipairs(ghostHeadPool) do
        pcall(function() a:Destroy() end)
    end
    table.clear(ghostHeadPool)
    
    if ghostAdornmentFolder then
        pcall(function() ghostAdornmentFolder:Destroy() end)
        ghostAdornmentFolder = nil
    end
    
    table.clear(backtrackHistory)
end

-- Player Chams System (Boxes for body, upright Cylinder for head)
local playerChamsBoxPool = {}
local playerChamsHeadPool = {}
local playerChamsInUse = {}
local playerChamsFolder = nil

local function getPlayerChamsFolder()
    if not playerChamsFolder or not playerChamsFolder.Parent then
        local cam = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera") or Workspace
        local folder = Instance.new("Folder")
        ProtectInstance(folder)
        folder.Parent = cam
        playerChamsFolder = folder
    end
    return playerChamsFolder
end

local function getPlayerChamsBoxAdornment()
    local folder = getPlayerChamsFolder()
    for i = #playerChamsBoxPool, 1, -1 do
        local a = playerChamsBoxPool[i]
        table.remove(playerChamsBoxPool, i)
        if a and a.Parent then
            return a
        end
    end
    
    local adornment = Instance.new("BoxHandleAdornment")
    ProtectInstance(adornment)
    adornment.Adornee = nil
    adornment.AlwaysOnTop = true
    adornment.ZIndex = 6
    adornment.Transparency = Config.ESP.PlayerChamsTransparency or 0.5
    adornment.Visible = false
    adornment.Color3 = Config.ESP.PlayerChamsColor or Color3.fromRGB(255, 0, 128)
    adornment.Parent = folder
    return adornment
end

local function getPlayerChamsHeadAdornment()
    local folder = getPlayerChamsFolder()
    for i = #playerChamsHeadPool, 1, -1 do
        local a = playerChamsHeadPool[i]
        table.remove(playerChamsHeadPool, i)
        if a and a.Parent then
            return a
        end
    end
    
    local adornment = Instance.new("CylinderHandleAdornment")
    ProtectInstance(adornment)
    adornment.Adornee = nil
    adornment.AlwaysOnTop = true
    adornment.ZIndex = 7
    adornment.Transparency = Config.ESP.PlayerChamsTransparency or 0.5
    adornment.Visible = false
    adornment.Color3 = Config.ESP.PlayerChamsColor or Color3.fromRGB(255, 0, 128)
    adornment.Parent = folder
    return adornment
end

local function releasePlayerChamsAdornment(a)
    if a and a.Parent then
        a.Visible = false
        a.Adornee = nil
        if a:IsA("CylinderHandleAdornment") then
            table.insert(playerChamsHeadPool, a)
        else
            table.insert(playerChamsBoxPool, a)
        end
    end
end

local hiddenTargetParts = {}

local function restoreTargetVisibility(char)
    if not char then return end
    pcall(function()
        for _, desc in ipairs(char:GetDescendants()) do
            if desc:IsA("BasePart") then
                desc.LocalTransparencyModifier = 0
            elseif desc:IsA("Decal") or desc:IsA("Texture") then
                if hiddenTargetParts[desc] ~= nil then
                    desc.Transparency = hiddenTargetParts[desc]
                    hiddenTargetParts[desc] = nil
                else
                    desc.Transparency = 0
                end
            end
        end
    end)
end

local function restoreAllTargetVisibility()
    for inst, orig in pairs(hiddenTargetParts) do
        pcall(function()
            if inst and inst.Parent then
                if inst:IsA("BasePart") then
                    inst.LocalTransparencyModifier = 0
                elseif inst:IsA("Decal") or inst:IsA("Texture") then
                    inst.Transparency = orig
                end
            end
        end)
    end
    table.clear(hiddenTargetParts)
end

clearAllPlayerChams = function()
    for char, adorns in pairs(playerChamsInUse) do
        restoreTargetVisibility(char)
        for _, a in ipairs(adorns) do
            releasePlayerChamsAdornment(a)
        end
    end
    table.clear(playerChamsInUse)
    restoreAllTargetVisibility()
    
    if playerChamsFolder then
        for _, child in ipairs(playerChamsFolder:GetChildren()) do
            if child:IsA("HandleAdornment") then
                child.Visible = false
                child.Adornee = nil
            end
        end
    end
end

local function destroyAllPlayerChams()
    for char, adorns in pairs(playerChamsInUse) do
        restoreTargetVisibility(char)
        for _, a in ipairs(adorns) do
            pcall(function() a:Destroy() end)
        end
    end
    table.clear(playerChamsInUse)
    restoreAllTargetVisibility()
    
    for _, a in ipairs(playerChamsBoxPool) do
        pcall(function() a:Destroy() end)
    end
    table.clear(playerChamsBoxPool)
    
    for _, a in ipairs(playerChamsHeadPool) do
        pcall(function() a:Destroy() end)
    end
    table.clear(playerChamsHeadPool)
    
    if playerChamsFolder then
        pcall(function() playerChamsFolder:Destroy() end)
        playerChamsFolder = nil
    end
end

-- Ragdoll Chams System (Boxes for body, upright Cylinder for head)
local ragdollChamsBoxPool = {}
local ragdollChamsHeadPool = {}
local ragdollChamsInUse = {}
local ragdollChamsFolder = nil
local hiddenRagdollParts = {}

local function getRagdollChamsFolder()
    if not ragdollChamsFolder or not ragdollChamsFolder.Parent then
        local cam = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera") or Workspace
        local folder = Instance.new("Folder")
        ProtectInstance(folder)
        folder.Parent = cam
        ragdollChamsFolder = folder
    end
    return ragdollChamsFolder
end

local function getRagdollChamsBoxAdornment()
    local folder = getRagdollChamsFolder()
    for i = #ragdollChamsBoxPool, 1, -1 do
        local a = ragdollChamsBoxPool[i]
        table.remove(ragdollChamsBoxPool, i)
        if a and a.Parent then
            return a
        end
    end
    
    local adornment = Instance.new("BoxHandleAdornment")
    ProtectInstance(adornment)
    adornment.Adornee = nil
    adornment.AlwaysOnTop = true
    adornment.ZIndex = 6
    adornment.Transparency = Config.ESP.RagdollChamsTransparency or 0.5
    adornment.Visible = false
    adornment.Color3 = Config.ESP.RagdollChamsColor or Color3.fromRGB(150, 0, 255)
    adornment.Parent = folder
    return adornment
end

local function getRagdollChamsHeadAdornment()
    local folder = getRagdollChamsFolder()
    for i = #ragdollChamsHeadPool, 1, -1 do
        local a = ragdollChamsHeadPool[i]
        table.remove(ragdollChamsHeadPool, i)
        if a and a.Parent then
            return a
        end
    end
    
    local adornment = Instance.new("CylinderHandleAdornment")
    ProtectInstance(adornment)
    adornment.Adornee = nil
    adornment.AlwaysOnTop = true
    adornment.ZIndex = 7
    adornment.Transparency = Config.ESP.RagdollChamsTransparency or 0.5
    adornment.Visible = false
    adornment.Color3 = Config.ESP.RagdollChamsColor or Color3.fromRGB(150, 0, 255)
    adornment.Parent = folder
    return adornment
end

local function releaseRagdollChamsAdornment(a)
    if a and a.Parent then
        a.Visible = false
        a.Adornee = nil
        if a:IsA("CylinderHandleAdornment") then
            table.insert(ragdollChamsHeadPool, a)
        else
            table.insert(ragdollChamsBoxPool, a)
        end
    end
end

local function restoreRagdollVisibility(char)
    if not char then return end
    pcall(function()
        for _, desc in ipairs(char:GetDescendants()) do
            if desc:IsA("BasePart") then
                desc.LocalTransparencyModifier = 0
            elseif desc:IsA("Decal") or desc:IsA("Texture") then
                if hiddenRagdollParts[desc] ~= nil then
                    desc.Transparency = hiddenRagdollParts[desc]
                    hiddenRagdollParts[desc] = nil
                else
                    desc.Transparency = 0
                end
            end
        end
    end)
end

local function restoreAllRagdollVisibility()
    for inst, orig in pairs(hiddenRagdollParts) do
        pcall(function()
            if inst and inst.Parent then
                if inst:IsA("BasePart") then
                    inst.LocalTransparencyModifier = 0
                elseif inst:IsA("Decal") or inst:IsA("Texture") then
                    inst.Transparency = orig
                end
            end
        end)
    end
    table.clear(hiddenRagdollParts)
end

clearAllRagdollChams = function()
    for char, adorns in pairs(ragdollChamsInUse) do
        restoreRagdollVisibility(char)
        for _, a in ipairs(adorns) do
            releaseRagdollChamsAdornment(a)
        end
    end
    table.clear(ragdollChamsInUse)
    restoreAllRagdollVisibility()
    
    if ragdollChamsFolder then
        for _, child in ipairs(ragdollChamsFolder:GetChildren()) do
            if child:IsA("HandleAdornment") then
                child.Visible = false
                child.Adornee = nil
            end
        end
    end
end

local function destroyAllRagdollChams()
    for char, adorns in pairs(ragdollChamsInUse) do
        restoreRagdollVisibility(char)
        for _, a in ipairs(adorns) do
            pcall(function() a:Destroy() end)
        end
    end
    table.clear(ragdollChamsInUse)
    restoreAllRagdollVisibility()
    
    for _, a in ipairs(ragdollChamsBoxPool) do
        pcall(function() a:Destroy() end)
    end
    table.clear(ragdollChamsBoxPool)
    
    for _, a in ipairs(ragdollChamsHeadPool) do
        pcall(function() a:Destroy() end)
    end
    table.clear(ragdollChamsHeadPool)
    
    if ragdollChamsFolder then
        pcall(function() ragdollChamsFolder:Destroy() end)
        ragdollChamsFolder = nil
    end
end

local lastRagdollScanTime = 0
local cachedRagdollsList = {}

local function getAllRagdolls()
    local now = os.clock()
    if (now - lastRagdollScanTime) < 0.05 and #cachedRagdollsList > 0 then
        return cachedRagdollsList
    end
    lastRagdollScanTime = now
    
    local ragdolls = {}
    local seen = {}
    
    local function addModel(m)
        if m and not seen[m] and isRagdollModel(m) then
            seen[m] = true
            activeRagdollList[m] = true
            table.insert(ragdolls, m)
        end
    end
    
    -- 1. Check actively tracked ragdolls from deaths
    for model, _ in pairs(activeRagdollList) do
        if model and model.Parent and model:IsDescendantOf(workspace) and isRagdollModel(model) then
            seen[model] = true
            table.insert(ragdolls, model)
        else
            activeRagdollList[model] = nil
        end
    end
    
    -- 2. Check Players' characters (if dead)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            addModel(player.Character)
        end
    end
    
    -- 3. Scan specific common ragdoll container folders only (excluding active player folder)
    local scanFolders = {
        Workspace:FindFirstChild("Debris"),
        Workspace:FindFirstChild("Ragdolls"),
        Workspace:FindFirstChild("Corpses"),
        Workspace:FindFirstChild("Dead"),
        Workspace:FindFirstChild("Bodies")
    }
    
    for _, folder in ipairs(scanFolders) do
        if folder then
            for _, child in ipairs(folder:GetChildren()) do
                if child:IsA("Model") then
                    addModel(child)
                end
            end
        end
    end
    
    cachedRagdollsList = ragdolls
    return ragdolls
end

local lastBacktrackRecordTimes = {}
local function recordTargetBacktrack(char)
    if not char then return end
    local now = os.clock()
    local lastTime = lastBacktrackRecordTimes[char] or 0
    if (now - lastTime) < 0.016 then return end
    lastBacktrackRecordTimes[char] = now
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then
        backtrackHistory[char] = nil
        lastBacktrackRecordTimes[char] = nil
        return
    end
    
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Head")
    if not hrp then return end
    
    local partsData = {}
    local origHead = nil
    local ut = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or hrp
    local resolvedHead = resolvedHeadInstances[char]
    
    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") and part.Name:lower() ~= "humanoidrootpart" and not part:FindFirstAncestorOfClass("Accessory") and not part:FindFirstAncestorOfClass("Tool") then
            local isHead = (part.Name:lower() == "head")
            local pCF = part.CFrame
            local pSize = part.Size
            if isHead then
                origHead = part
                local isDesynced = (part.Position - hrp.Position).Magnitude > 5 or part.Position.Y < -500 or (not part.CanQuery)
                if isDesynced or resolvedHead then
                    pCF = (resolvedHead and resolvedHead.CFrame) or (ut and ut.CFrame * CFrame.new(0, 1.4, 0)) or pCF
                end
            end
            table.insert(partsData, {
                part = part,
                name = part.Name,
                cframe = pCF,
                size = pSize,
                isHead = isHead
            })
        end
    end
    
    if not origHead and (resolvedHead or ut) then
        local headCF = (resolvedHead and resolvedHead.CFrame) or (ut and ut.CFrame * CFrame.new(0, 1.4, 0))
        table.insert(partsData, {
            part = resolvedHead or ut,
            name = "Head",
            cframe = headCF,
            size = Vector3.new(2, 1, 1),
            isHead = true
        })
    end
    
    if #partsData == 0 then
        table.insert(partsData, {
            part = hrp,
            name = hrp.Name,
            cframe = hrp.CFrame,
            size = hrp.Size,
            isHead = (hrp.Name:lower() == "head")
        })
    end
    
    if not backtrackHistory[char] then
        backtrackHistory[char] = {}
    end
    
    local history = backtrackHistory[char]
    table.insert(history, {
        time = os.clock(),
        rootPos = hrp.Position,
        parts = partsData,
        humanoid = hum
    })
    
    local cutoff = os.clock() - 1.5
    while #history > 0 and history[1].time < cutoff do
        table.remove(history, 1)
    end
end

local function getBacktrackSnapshot(char, backtrackMs)
    local history = backtrackHistory[char]
    if not history or #history == 0 then return nil end
    
    local targetTime = os.clock() - (math.clamp(backtrackMs or 200, 1, 1000) / 1000)
    local bestRecord = nil
    local bestDelta = math.huge
    
    for i = 1, #history do
        local rec = history[i]
        local delta = math.abs(rec.time - targetTime)
        if delta < bestDelta then
            bestDelta = delta
            bestRecord = rec
        end
    end
    
    return bestRecord
end

local function intersectRayOBB(origin, direction, boxCFrame, boxSize)
    local localOrigin = boxCFrame:PointToObjectSpace(origin)
    local localDir = boxCFrame:VectorToObjectSpace(direction)
    local halfSize = boxSize / 2
    
    local tmin = -math.huge
    local tmax = math.huge
    
    local axes = {"X", "Y", "Z"}
    for i = 1, 3 do
        local axis = axes[i]
        local o = localOrigin[axis]
        local d = localDir[axis]
        local h = halfSize[axis]
        
        if math.abs(d) > 1e-6 then
            local t1 = (-h - o) / d
            local t2 = (h - o) / d
            if t1 > t2 then t1, t2 = t2, t1 end
            if t1 > tmin then tmin = t1 end
            if t2 < tmax then tmax = t2 end
            if tmin > tmax or tmax < 0 then
                return nil
            end
        else
            if math.abs(o) > h then
                return nil
            end
        end
    end
    
    local dist = tmin > 0 and tmin or tmax
    if dist < 0 then return nil end
    
    local hitPos = boxCFrame:PointToWorldSpace(localOrigin + (localDir * dist))
    return hitPos, dist
end

local function isSnapshotCaughtUp(char, snapshot)
    if not char or not snapshot then return true end
    local liveRoot = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Head")
    if not liveRoot then return true end
    
    local snapPos = snapshot.rootPos
    if not snapPos and snapshot.parts and #snapshot.parts > 0 then
        snapPos = snapshot.parts[1].cframe.Position
    end
    if not snapPos then return true end
    
    local delta = (liveRoot.Position - snapPos).Magnitude
    return delta < 0.35
end

local function isPartSolidWall(instance)
    if not instance or not instance:IsA("BasePart") then return false end
    if instance:FindFirstAncestorOfClass("Accessory") or instance:FindFirstAncestorOfClass("Tool") then return false end
    local model = instance:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChildOfClass("Humanoid") then return false end
    if not instance.CanCollide and instance.Transparency >= 0.7 then return false end
    return true
end

local function checkGhostHit(origin, direction)
    if not Config.Misc.Backtrack then return nil end
    
    local camera = Workspace.CurrentCamera
    local camPos = camera and camera.CFrame.Position
    local closestHit = nil
    local closestDist = math.huge
    
    for _, targetInfo in ipairs(getAllTargets()) do
        if not targetInfo.IsPlayer or not (Config.ESP.TeamCheck and isTeammate(targetInfo.Player)) then
            local char = targetInfo.Character
            local hum = char and (char:FindFirstChildOfClass("Humanoid") or char:FindFirstChild("Humanoid", true))
            if hum and hum.Health > 0 and char and backtrackHistory[char] then
                local liveRoot = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("Head")
                local livePos = liveRoot and liveRoot.Position
                
                -- Distance check (500 studs)
                if livePos and camPos and (livePos - camPos).Magnitude <= 500 then
                    -- MANDATORY: The live enemy MUST be visible (not hidden behind a wall)
                    local isLiveVisible = isPositionVisible(camPos, livePos, char)
                    if isLiveVisible and LocalPlayer.Character then
                        local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character:FindFirstChild("Head")
                        if myRoot then
                            isLiveVisible = isPositionVisible(myRoot.Position, livePos, char)
                        end
                    end
                    
                    if isLiveVisible then
                        local snapshot = getBacktrackSnapshot(char, Config.Misc.BacktrackTime)
                        if snapshot and not isSnapshotCaughtUp(char, snapshot) and snapshot.parts then
                            for _, partData in ipairs(snapshot.parts) do
                                local hitPos, dist = intersectRayOBB(origin, direction, partData.cframe, partData.size)
                                if hitPos and dist < closestDist then
                                    -- MANDATORY VISIBLE CHECK ON GHOST:
                                    -- 1. Camera to Ghost position
                                    local ghostVisible = isPositionVisible(camPos, hitPos, char)
                                    
                                    -- 2. Ray Origin to Ghost position
                                    if ghostVisible and origin then
                                        ghostVisible = isPositionVisible(origin, hitPos, char)
                                    end
                                    
                                    -- 3. Local Character Root to Ghost position
                                    if ghostVisible and LocalPlayer.Character then
                                        local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character:FindFirstChild("Head")
                                        if myRoot then
                                            ghostVisible = isPositionVisible(myRoot.Position, hitPos, char)
                                        end
                                    end
                                    
                                    if ghostVisible then
                                        closestDist = dist
                                        closestHit = {
                                            character = char,
                                            humanoid = snapshot.humanoid or hum,
                                            part = partData.part,
                                            partName = partData.name,
                                            hitPos = hitPos,
                                            distance = dist,
                                            player = targetInfo.Player
                                        }
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    return closestHit
end

getBestCombatTarget = function()
    local cam = Workspace.CurrentCamera
    if not cam then return nil end
    local camPos = cam.CFrame.Position
    local center = cam.ViewportSize / 2
    
    local maxFovDeg = Config.GunMods.AimFOV or 15
    local isFull360 = (maxFovDeg >= 350)
    
    -- Calculate exact pixel radius matching FOVCircle
    local vFovRad = math.rad(cam.FieldOfView)
    local targetFovRad = math.clamp(math.rad(maxFovDeg), 0.01, math.rad(179))
    local fovRadius = (math.tan(targetFovRad / 2) / math.tan(vFovRad / 2)) * (cam.ViewportSize.Y / 2)
    if maxFovDeg >= 180 then
        fovRadius = math.max(cam.ViewportSize.X, cam.ViewportSize.Y) * 1.5
    end
    
    local bestCandidate = nil
    local bestScore = math.huge
    
    local allTargets = getAllTargets()
    for _, targetInfo in ipairs(allTargets) do
        if not targetInfo.IsPlayer or not (Config.ESP.TeamCheck and isTeammate(targetInfo.Player)) then
            local char = targetInfo.Character
            local hum = char and (char:FindFirstChildOfClass("Humanoid") or char:FindFirstChild("Humanoid", true))
            if hum and hum.Health > 0 then
                -- 1. Check Live Target
                local liveHead = char:FindFirstChild("Head")
                local liveRoot = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
                local livePos = nil
                local isSafeHead = false
                
                if liveRoot then
                    if not liveHead or (liveHead.Position - liveRoot.Position).Magnitude > 5 or liveHead.Position.Y < -500 or (not liveHead.CanQuery) then
                        isSafeHead = true
                        livePos = liveRoot.Position + Vector3.new(0, 1.4, 0)
                    else
                        livePos = liveHead.Position
                    end
                elseif liveHead then
                    livePos = liveHead.Position
                end
                
                local liveCandidate = nil
                local isLiveVisible = false
                
                if livePos then
                    local isInsideFov = false
                    local dist2D = 0
                    
                    if isFull360 then
                        isInsideFov = true
                        dist2D = (livePos - camPos).Magnitude
                    else
                        local screenPos, onScreen = cam:WorldToViewportPoint(livePos)
                        if onScreen and screenPos.Z > 0 then
                            dist2D = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                            if dist2D <= fovRadius then
                                isInsideFov = true
                            end
                        end
                    end
                    
                    if isInsideFov then
                        isLiveVisible = isPositionVisible(camPos, livePos, char)
                        if isLiveVisible and Config.GunMods.WallCheck and LocalPlayer.Character then
                            local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character:FindFirstChild("Head")
                            if myRoot then
                                isLiveVisible = isPositionVisible(myRoot.Position, livePos, char)
                            end
                        end
                        
                        if isLiveVisible or (not Config.GunMods.WallCheck) then
                            liveCandidate = {
                                character = char,
                                humanoid = hum,
                                player = targetInfo.Player,
                                targetPos = livePos,
                                hitPart = isSafeHead and (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or liveRoot) or liveHead or liveRoot,
                                isBacktrack = false,
                                isSafeHead = isSafeHead,
                                score = dist2D,
                                distance = (livePos - camPos).Magnitude
                            }
                        end
                    end
                end
                
                -- 2. Check Backtrack (BT) Ghost (Evaluates even if live enemy peeked back behind cover)
                local btCandidate = nil
                if Config.Misc.Backtrack and backtrackHistory[char] then
                    local snapshot = getBacktrackSnapshot(char, Config.Misc.BacktrackTime)
                    if snapshot and not isSnapshotCaughtUp(char, snapshot) and snapshot.parts and #snapshot.parts > 0 then
                        local bestPartData = nil
                        for _, pData in ipairs(snapshot.parts) do
                            if pData.isHead or pData.name:lower() == "head" then
                                bestPartData = pData
                                break
                            end
                        end
                        if not bestPartData then
                            for _, pData in ipairs(snapshot.parts) do
                                if pData.name:lower():find("torso") or pData.name:lower():find("root") then
                                    bestPartData = pData
                                    break
                                end
                            end
                        end
                        if not bestPartData then
                            bestPartData = snapshot.parts[1]
                        end
                        
                        if bestPartData then
                            local btPos = bestPartData.cframe.Position
                            local isBtInsideFov = false
                            local distBt2D = 0
                            
                            if isFull360 then
                                isBtInsideFov = true
                                distBt2D = (btPos - camPos).Magnitude
                            else
                                local screenPosBt, onScreenBt = cam:WorldToViewportPoint(btPos)
                                if onScreenBt and screenPosBt.Z > 0 then
                                    distBt2D = (Vector2.new(screenPosBt.X, screenPosBt.Y) - center).Magnitude
                                    if distBt2D <= fovRadius then
                                        isBtInsideFov = true
                                    end
                                end
                            end
                            
                            if isBtInsideFov then
                                local isBtVisible = isPositionVisible(camPos, btPos, char)
                                if isBtVisible and Config.GunMods.WallCheck and LocalPlayer.Character then
                                    local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character:FindFirstChild("Head")
                                    if myRoot then
                                        isBtVisible = isPositionVisible(myRoot.Position, btPos, char)
                                    end
                                end
                                
                                if isBtVisible or (not Config.GunMods.WallCheck) then
                                    btCandidate = {
                                        character = char,
                                        humanoid = snapshot.humanoid or hum,
                                        player = targetInfo.Player,
                                        targetPos = btPos,
                                        hitPart = bestPartData.part or liveRoot,
                                        isBacktrack = true,
                                        isSafeHead = false,
                                        score = distBt2D,
                                        distance = (btPos - camPos).Magnitude
                                    }
                                end
                            end
                        end
                    end
                end
                
                -- 3. Determine best candidate between Live & BT
                local chosenCandidate = nil
                if liveCandidate and btCandidate then
                    if btCandidate.score < liveCandidate.score then
                        chosenCandidate = btCandidate
                    else
                        chosenCandidate = liveCandidate
                    end
                elseif liveCandidate then
                    chosenCandidate = liveCandidate
                elseif btCandidate then
                    chosenCandidate = btCandidate
                end
                
                if chosenCandidate then
                    local score = chosenCandidate.score
                    if score < bestScore then
                        bestScore = score
                        bestCandidate = chosenCandidate
                    end
                end
            else
                -- Target dead: purge backtrack history
                if char and backtrackHistory[char] then
                    backtrackHistory[char] = nil
                end
            end
        end
    end
    
    return bestCandidate
end

table.insert(ScriptConnections, RunService.RenderStepped:Connect(function(dt)
    if _G.ConvergenceUnloaded then
        clearAllGhostAdornments()
        return
    end
    
    local allTargets = getAllTargets()
    local activeLiveChars = {}
    for _, tInfo in ipairs(allTargets) do
        if tInfo.Character then
            activeLiveChars[tInfo.Character] = true
        end
    end
    
    if Config.Misc.Backtrack then
        for _, targetInfo in ipairs(allTargets) do
            if not targetInfo.IsPlayer or not (Config.ESP.TeamCheck and isTeammate(targetInfo.Player)) then
                recordTargetBacktrack(targetInfo.Character)
            end
        end
    else
        if next(backtrackHistory) ~= nil then
            table.clear(backtrackHistory)
        end
    end
    
    if Config.Misc.Backtrack and Config.Misc.BacktrackGhost then
        local camera = Workspace.CurrentCamera
        local camPos = camera and camera.CFrame.Position
        local activeChars = {}
        
        for _, targetInfo in ipairs(allTargets) do
            if not targetInfo.IsPlayer or not (Config.ESP.TeamCheck and isTeammate(targetInfo.Player)) then
                local char = targetInfo.Character
                if char then
                    activeChars[char] = true
                    local liveRoot = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("Head")
                    local livePos = liveRoot and liveRoot.Position
                    
                    local inRange = livePos and camPos and (livePos - camPos).Magnitude <= 500
                    local snapshot = inRange and getBacktrackSnapshot(char, Config.Misc.BacktrackTime)
                    local isCaughtUp = not snapshot or isSnapshotCaughtUp(char, snapshot)
                    
                    local adorns = ghostAdornmentsInUse[char]
                    if not adorns then
                        adorns = {}
                        ghostAdornmentsInUse[char] = adorns
                    end
                    
                    if snapshot and snapshot.parts and #snapshot.parts > 0 and inRange and not isCaughtUp then
                        local partCount = #snapshot.parts
                        for idx = #adorns, partCount + 1, -1 do
                            releaseGhostAdornment(table.remove(adorns, idx))
                        end
                        
                        local ghostColor = Config.Misc.BacktrackColor or Color3.fromRGB(180, 180, 255)
                        local ghostTrans = math.clamp(Config.Misc.BacktrackTransparency or 0.25, 0, 1)
                        for idx, partData in ipairs(snapshot.parts) do
                            local isHead = partData.isHead or (partData.name and partData.name:lower() == "head")
                            local existing = adorns[idx]
                            
                            if isHead then
                                if not existing or not existing:IsA("CylinderHandleAdornment") then
                                    if existing then releaseGhostAdornment(existing) end
                                    existing = getGhostHeadAdornment()
                                    adorns[idx] = existing
                                end
                                if existing then
                                    existing.Adornee = workspace.Terrain
                                    existing.CFrame = partData.cframe * CFrame.Angles(math.pi / 2, 0, 0)
                                    existing.Height = partData.size.Y or 1.2
                                    existing.Radius = math.min(partData.size.X or 1.2, partData.size.Z or 1.2) * 0.55
                                    existing.ZIndex = 7
                                    existing.Color3 = ghostColor
                                    existing.Transparency = ghostTrans
                                    existing.Visible = true
                                end
                            else
                                if not existing or not existing:IsA("BoxHandleAdornment") then
                                    if existing then releaseGhostAdornment(existing) end
                                    existing = getGhostBoxAdornment()
                                    adorns[idx] = existing
                                end
                                if existing then
                                    existing.Adornee = workspace.Terrain
                                    existing.CFrame = partData.cframe
                                    existing.Size = partData.size
                                    existing.ZIndex = 6
                                    existing.Color3 = ghostColor
                                    existing.Transparency = ghostTrans
                                    existing.Visible = true
                                end
                            end
                        end
                    else
                        for _, a in ipairs(adorns) do
                            releaseGhostAdornment(a)
                        end
                        ghostAdornmentsInUse[char] = nil
                    end
                end
            end
        end
        
        for char, adorns in pairs(ghostAdornmentsInUse) do
            if not activeChars[char] then
                for _, a in ipairs(adorns) do
                    releaseGhostAdornment(a)
                end
                ghostAdornmentsInUse[char] = nil
            end
        end
    else
        clearAllGhostAdornments()
    end
    
    -- Player Chams Rendering Loop
    pcall(function()
        if Config.ESP.PlayerChams and not _G.ConvergenceUnloaded then
        local camera = Workspace.CurrentCamera
        local camPos = camera and camera.CFrame.Position
        
        for _, targetInfo in ipairs(allTargets) do
            if not (Config.ESP.TeamCheck and isTeammate(targetInfo.Player)) then
                local char = targetInfo.Character
                if char and char:IsDescendantOf(workspace) then
                    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("Head")
                    local rootPos = root and root.Position
                    local inRange = rootPos and camPos and (rootPos - camPos).Magnitude <= 500
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    local isAlive = (not hum) or (hum.Health > 0)
                    
                    if inRange and isAlive then
                        activeLiveChars[char] = true
                        
                        -- Hide real character parts, accessories, and face decals so chams replaces them
                        pcall(function()
                            for _, child in ipairs(char:GetChildren()) do
                                if child:IsA("BasePart") then
                                    child.LocalTransparencyModifier = 1
                                    for _, d in ipairs(child:GetChildren()) do
                                        if d:IsA("Decal") or d:IsA("Texture") then
                                            if hiddenTargetParts[d] == nil then
                                                hiddenTargetParts[d] = d.Transparency
                                            end
                                            d.Transparency = 1
                                        end
                                    end
                                elseif child:IsA("Accessory") then
                                    local handle = child:FindFirstChild("Handle")
                                    if handle and handle:IsA("BasePart") then
                                        handle.LocalTransparencyModifier = 1
                                    end
                                end
                            end
                        end)
                        
                        local adorns = playerChamsInUse[char]
                        if not adorns then
                            adorns = {}
                            playerChamsInUse[char] = adorns
                        end
                        
                        local visibleParts = {}
                        local rootPos = root and root.Position or Vector3.zero
                        for _, child in ipairs(char:GetChildren()) do
                            if child:IsA("BasePart") and child.Name:lower() ~= "humanoidrootpart" and not child:FindFirstAncestorOfClass("Accessory") and not child:FindFirstAncestorOfClass("Tool") then
                                local isHead = (child.Name:lower() == "head")
                                local dist = (child.Position - rootPos).Magnitude
                                if dist <= 6 or isHead then
                                    table.insert(visibleParts, child)
                                end
                            end
                        end
                        if #visibleParts == 0 and root then table.insert(visibleParts, root) end
                        
                        for idx = #adorns, #visibleParts + 1, -1 do
                            releasePlayerChamsAdornment(table.remove(adorns, idx))
                        end
                        
                        local chamsColor = Config.ESP.PlayerChamsColor or Color3.fromRGB(255, 0, 128)
                        local chamsTrans = math.clamp(Config.ESP.PlayerChamsTransparency or 0.5, 0, 1)
                        
                        for idx, part in ipairs(visibleParts) do
                            local isHead = (part.Name:lower() == "head")
                            local existing = adorns[idx]
                            
                            if isHead then
                                if not existing or not existing:IsA("CylinderHandleAdornment") then
                                    if existing then releasePlayerChamsAdornment(existing) end
                                    existing = getPlayerChamsHeadAdornment()
                                    adorns[idx] = existing
                                end
                                if existing then
                                    local headCF = getResolvedHeadCFrame(char) or part.CFrame
                                    existing.Adornee = workspace.Terrain
                                    existing.AlwaysOnTop = true
                                    existing.CFrame = headCF * CFrame.Angles(math.pi / 2, 0, 0)
                                    existing.Height = 1.2
                                    existing.Radius = 0.65
                                    existing.ZIndex = 10
                                    existing.Color3 = chamsColor
                                    existing.Transparency = chamsTrans
                                    existing.Visible = true
                                end
                            else
                                if not existing or not existing:IsA("BoxHandleAdornment") then
                                    if existing then releasePlayerChamsAdornment(existing) end
                                    existing = getPlayerChamsBoxAdornment()
                                    adorns[idx] = existing
                                end
                                if existing then
                                    if root and (part.Position - root.Position).Magnitude > 6 then
                                        existing.Visible = false
                                    else
                                        existing.Adornee = workspace.Terrain
                                        existing.AlwaysOnTop = true
                                        existing.CFrame = part.CFrame
                                        existing.Size = part.Size
                                        existing.ZIndex = 9
                                        existing.Color3 = chamsColor
                                        existing.Transparency = chamsTrans
                                        existing.Visible = true
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        
        for char, adorns in pairs(playerChamsInUse) do
            if not activeLiveChars[char] then
                restoreTargetVisibility(char)
                for _, a in ipairs(adorns) do
                    releasePlayerChamsAdornment(a)
                end
                playerChamsInUse[char] = nil
            end
        end
        else
            if next(playerChamsInUse) ~= nil or next(hiddenTargetParts) ~= nil then
                clearAllPlayerChams()
            end
        end
    end)
    
    -- Ragdoll Chams Rendering Loop
    pcall(function()
        if Config.ESP.RagdollChams and not _G.ConvergenceUnloaded then
        local camera = Workspace.CurrentCamera
        local camPos = camera and camera.CFrame.Position
        local activeRagdollChars = {}
        
        for _, ragdoll in ipairs(getAllRagdolls()) do
            if ragdoll and ragdoll:IsDescendantOf(workspace) then
                if (activeLiveChars and activeLiveChars[ragdoll]) or (playerChamsInUse and playerChamsInUse[ragdoll]) or isAliveTargetCharacter(ragdoll) then
                    continue
                end
                local root = ragdoll:FindFirstChild("HumanoidRootPart") or ragdoll:FindFirstChild("Torso") or ragdoll:FindFirstChild("UpperTorso") or ragdoll:FindFirstChild("Head") or ragdoll:FindFirstChildWhichIsA("BasePart")
                local rootPos = root and root.Position
                local inRange = rootPos and camPos and (rootPos - camPos).Magnitude <= 500
                
                if inRange then
                    activeRagdollChars[ragdoll] = true
                    
                    -- Hide real ragdoll parts, accessories, and face decals so chams replaces them
                    pcall(function()
                        for _, child in ipairs(ragdoll:GetChildren()) do
                            if child:IsA("BasePart") then
                                child.LocalTransparencyModifier = 1
                                for _, d in ipairs(child:GetChildren()) do
                                    if d:IsA("Decal") or d:IsA("Texture") then
                                        if hiddenRagdollParts[d] == nil then
                                            hiddenRagdollParts[d] = d.Transparency
                                        end
                                        d.Transparency = 1
                                    end
                                end
                            elseif child:IsA("Accessory") then
                                local handle = child:FindFirstChild("Handle")
                                if handle and handle:IsA("BasePart") then
                                    handle.LocalTransparencyModifier = 1
                                end
                            end
                        end
                    end)
                    
                    local adorns = ragdollChamsInUse[ragdoll]
                    if not adorns then
                        adorns = {}
                        ragdollChamsInUse[ragdoll] = adorns
                    end
                    
                    local visibleParts = {}
                    local rootPos = root and root.Position or Vector3.zero
                    for _, child in ipairs(ragdoll:GetChildren()) do
                        if child:IsA("BasePart") and child.Name:lower() ~= "humanoidrootpart" and not child:FindFirstAncestorOfClass("Accessory") and not child:FindFirstAncestorOfClass("Tool") then
                            local isHead = (child.Name:lower() == "head")
                            local dist = (child.Position - rootPos).Magnitude
                            if dist <= 6 or isHead then
                                table.insert(visibleParts, child)
                            end
                        end
                    end
                    if #visibleParts == 0 then
                        for _, desc in ipairs(ragdoll:GetDescendants()) do
                            if desc:IsA("BasePart") and desc.Name:lower() ~= "humanoidrootpart" and not desc:FindFirstAncestorOfClass("Accessory") and not desc:FindFirstAncestorOfClass("Tool") then
                                local isHead = (desc.Name:lower() == "head")
                                local dist = (desc.Position - rootPos).Magnitude
                                if dist <= 6 or isHead then
                                    table.insert(visibleParts, desc)
                                end
                            end
                        end
                    end
                    if #visibleParts == 0 and root then table.insert(visibleParts, root) end
                    
                    for idx = #adorns, #visibleParts + 1, -1 do
                        releaseRagdollChamsAdornment(table.remove(adorns, idx))
                    end
                    
                    local chamsColor = Config.ESP.RagdollChamsColor or Color3.fromRGB(150, 0, 255)
                    local chamsTrans = math.clamp(Config.ESP.RagdollChamsTransparency or 0.5, 0, 1)
                    
                    for idx, part in ipairs(visibleParts) do
                        local isHead = (part.Name:lower() == "head")
                        local existing = adorns[idx]
                        
                        if isHead then
                            if not existing or not existing:IsA("CylinderHandleAdornment") then
                                if existing then releaseRagdollChamsAdornment(existing) end
                                existing = getRagdollChamsHeadAdornment()
                                adorns[idx] = existing
                            end
                            if existing then
                                local headCF = part.CFrame
                                if root and (headCF.Position - rootPos).Magnitude > 5 then
                                    local ut = ragdoll:FindFirstChild("UpperTorso") or ragdoll:FindFirstChild("Torso") or root
                                    headCF = ut.CFrame * CFrame.new(0, 1.4, 0)
                                end
                                existing.Adornee = workspace.Terrain
                                existing.AlwaysOnTop = true
                                existing.CFrame = headCF * CFrame.Angles(math.pi / 2, 0, 0)
                                existing.Height = 1.0
                                existing.Radius = 0.55
                                existing.ZIndex = 10
                                existing.Color3 = chamsColor
                                existing.Transparency = chamsTrans
                                existing.Visible = true
                            end
                        else
                            if not existing or not existing:IsA("BoxHandleAdornment") then
                                if existing then releaseRagdollChamsAdornment(existing) end
                                existing = getRagdollChamsBoxAdornment()
                                adorns[idx] = existing
                            end
                            if existing then
                                if root and (part.Position - rootPos).Magnitude > 6 then
                                    existing.Visible = false
                                else
                                    existing.Adornee = workspace.Terrain
                                    existing.AlwaysOnTop = true
                                    existing.CFrame = part.CFrame
                                    existing.Size = part.Size
                                    existing.ZIndex = 9
                                    existing.Color3 = chamsColor
                                    existing.Transparency = chamsTrans
                                    existing.Visible = true
                                end
                            end
                        end
                    end
                end
            end
        end
        
        for char, adorns in pairs(ragdollChamsInUse) do
            if not activeRagdollChars[char] then
                restoreRagdollVisibility(char)
                for _, a in ipairs(adorns) do
                    releaseRagdollChamsAdornment(a)
                end
                ragdollChamsInUse[char] = nil
            end
        end
        else
            if next(ragdollChamsInUse) ~= nil or next(hiddenRagdollParts) ~= nil then
                clearAllRagdollChams()
            end
        end
    end)
end))

table.insert(ScriptConnections, Workspace.DescendantAdded:Connect(function(desc)
    if desc:IsA("Model") then
        task.defer(function()
            if desc and desc.Parent and isRagdollModel(desc) then
                activeRagdollList[desc] = true
            end
        end)
    end
end))

table.insert(ScriptConnections, UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if not canPlayerShoot() then return end
        lastLocalPlayerShotTime = os.clock()
        
        local char = LocalPlayer.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
        if tool then
            if Config.GunMods.SilentAim then
                local bestTarget = getBestCombatTarget()
                if bestTarget then
                    local firePoint = tool:FindFirstChild("Handle") and tool.Handle:FindFirstChild("FirePoint")
                    local origin = (firePoint and firePoint.WorldPosition) or (char:FindFirstChild("Head") and char.Head.Position) or (Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame.Position)
                    local hitPart = bestTarget.hitPart
                    if bestTarget.isSafeHead then
                        hitPart = bestTarget.character:FindFirstChild("UpperTorso") or bestTarget.character:FindFirstChild("Torso") or bestTarget.character:FindFirstChild("HumanoidRootPart") or hitPart
                    end
                    if inflictGunDamage(bestTarget.character, bestTarget.humanoid, hitPart, bestTarget.targetPos, false, bestTarget.isBacktrack) then
                        lastDirectHitTime = os.clock()
                        if Config.ESP.BulletTracers and origin then
                            spawnBulletTracer(origin, bestTarget.targetPos)
                        end
                    end
                end
            elseif Config.Misc.Backtrack then
                local cam = Workspace.CurrentCamera
                if cam then
                    local mousePos = UserInputService:GetMouseLocation()
                    local ray = cam:ViewportPointToRay(mousePos.X, mousePos.Y)
                    local ghostHit = checkGhostHit(ray.Origin, ray.Direction)
                    if ghostHit then
                        if inflictGunDamage(ghostHit.character, ghostHit.humanoid, ghostHit.part, ghostHit.hitPos, false, true) then
                            lastDirectHitTime = os.clock()
                            if Config.ESP.BulletTracers then
                                local firePoint = tool:FindFirstChild("Handle") and tool.Handle:FindFirstChild("FirePoint")
                                local spawnPos = firePoint and firePoint.WorldPosition or (char and char:FindFirstChild("Head") and char.Head.Position) or ray.Origin
                                spawnBulletTracer(spawnPos, ghostHit.hitPos)
                            end
                        end
                    end
                end
            end
        end
    end
end))

local reloadAnimIdSetlocal reloadAnimIdSet = {
    ["102053130741914"] = true,
    ["139577872722089"] = true,
    ["133333512489282"] = true,
    ["99342191012431"] = true,
    ["108368378768591"] = true,
    ["83902699622709"] = true,
    ["75519044394424"] = true,
    ["71878431785615"] = true,
}

pcall(function()
    local RS = game:GetService("ReplicatedStorage")
    local gunsFolder = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("Guns")
    if gunsFolder then
        for _, gunModule in ipairs(gunsFolder:GetChildren()) do
            if gunModule:IsA("ModuleScript") then
                local ok, data = pcall(require, gunModule)
                if ok and type(data) == "table" then
                    if data.ReloadAnimationID then
                        reloadAnimIdSet[tostring(data.ReloadAnimationID)] = true
                    end
                    if data.ShotgunClipinAnimationID then
                        reloadAnimIdSet[tostring(data.ShotgunClipinAnimationID)] = true
                    end
                end
            end
        end
    end
end)

local function isCharacterReloading(char, hum)
    if not char then return false end
    if char == LocalPlayer.Character and _G.Reloading then
        return true
    end
    
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        for _, desc in ipairs(tool:GetDescendants()) do
            if desc:IsA("Sound") and desc.IsPlaying then
                local sName = desc.Name:lower()
                if sName:find("reload") or sName:find("mag") or sName:find("insert") or sName:find("charge") then
                    return true
                end
            end
        end
        local rVal = tool:FindFirstChild("Reloading", true) or tool:FindFirstChild("isReloading", true) or tool:FindFirstChild("Reload", true)
        if rVal and rVal:IsA("BoolValue") and rVal.Value == true then
            return true
        end
    end
    
    for _, desc in ipairs(char:GetDescendants()) do
        if desc:IsA("Sound") and desc.IsPlaying then
            local sName = desc.Name:lower()
            if sName:find("reload") or sName:find("mag") or sName:find("insert") then
                return true
            end
        end
    end
    
    local animator = hum and (hum:FindFirstChildOfClass("Animator") or hum:FindFirstChildWhichIsA("Animator"))
    local tracks = {}
    if animator then
        for _, trk in ipairs(animator:GetPlayingAnimationTracks()) do
            table.insert(tracks, trk)
        end
    end
    if hum then
        for _, trk in ipairs(hum:GetPlayingAnimationTracks()) do
            table.insert(tracks, trk)
        end
    end
    
    for _, track in ipairs(tracks) do
        if track.IsPlaying or (track.WeightCurrent and track.WeightCurrent > 0) then
            local trackName = track.Name:lower()
            local animObj = track.Animation
            local animName = animObj and animObj.Name:lower() or ""
            local animId = animObj and animObj.AnimationId or ""
            
            if trackName:find("reload") or trackName:find("mag") or trackName:find("insert")
               or animName:find("reload") or animName:find("mag") or animName:find("insert") then
                return true
            end
            
            for id in pairs(reloadAnimIdSet) do
                if animId:find(id) then
                    return true
                end
            end
        end
    end
    
    if char:GetAttribute("Reloading") == true or char:GetAttribute("isReloading") == true or (hum and hum:GetAttribute("Reloading") == true) then
        return true
    end
    
    return false
end

-- ESP Setup
local function createESP(target)
    local esp = {
        BoxOutline = Drawing.new("Square"),
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        HealthBar = Drawing.new("Square"),
        HealthOutline = Drawing.new("Square"),
        FlagSafeHead = Drawing.new("Text"),
        FlagReloading = Drawing.new("Text"),
        Alpha = 1
    }
    
    esp.BoxOutline.Thickness = 3
    esp.BoxOutline.Color = Color3.fromRGB(0, 0, 0)
    esp.BoxOutline.Filled = false
    esp.BoxOutline.Visible = false
    esp.BoxOutline.Transparency = 1
    
    esp.Box.Thickness = 1
    esp.Box.Color = Color3.fromRGB(255, 255, 255)
    esp.Box.Filled = false
    esp.Box.Visible = false
    esp.Box.Transparency = 1
    
    esp.Name.Size = 13
    esp.Name.Font = 2
    esp.Name.Center = true
    esp.Name.Outline = true
    esp.Name.OutlineColor = Color3.fromRGB(0, 0, 0)
    esp.Name.Visible = false
    esp.Name.Transparency = 1
    
    esp.HealthOutline.Thickness = 1
    esp.HealthOutline.Color = Color3.fromRGB(0, 0, 0)
    esp.HealthOutline.Filled = true
    esp.HealthOutline.ZIndex = 1
    esp.HealthOutline.Visible = false
    esp.HealthOutline.Transparency = 1
    
    esp.HealthBar.Thickness = 0
    esp.HealthBar.Filled = true
    esp.HealthBar.ZIndex = 2
    esp.HealthBar.Visible = false
    esp.HealthBar.Transparency = 1
    
    esp.FlagSafeHead.Size = 11
    esp.FlagSafeHead.Font = 2
    esp.FlagSafeHead.Center = false
    esp.FlagSafeHead.Outline = true
    esp.FlagSafeHead.OutlineColor = Color3.fromRGB(0, 0, 0)
    esp.FlagSafeHead.Visible = false
    esp.FlagSafeHead.Transparency = 1
    esp.FlagSafeHead.Color = Color3.fromRGB(255, 50, 50)
    esp.FlagSafeHead.Text = "Safe Head"
    
    esp.FlagReloading.Size = 11
    esp.FlagReloading.Font = 2
    esp.FlagReloading.Center = false
    esp.FlagReloading.Outline = true
    esp.FlagReloading.OutlineColor = Color3.fromRGB(0, 0, 0)
    esp.FlagReloading.Visible = false
    esp.FlagReloading.Transparency = 1
    esp.FlagReloading.Color = Color3.fromRGB(0, 255, 255)
    esp.FlagReloading.Text = "Reloading"
    
    return esp
end

local function removeESP(target)
    if ESPObjects[target] then
        for _, drawObj in pairs(ESPObjects[target]) do
            pcall(function()
                if drawObj and type(drawObj.Remove) == "function" then
                    drawObj:Remove()
                elseif drawObj and type(drawObj.Destroy) == "function" then
                    drawObj:Destroy()
                end
            end)
        end
        ESPObjects[target] = nil
    end
end

table.insert(ScriptConnections, Players.PlayerRemoving:Connect(function(player)
    if player.Character then removeESP(player.Character) end
    removeESP(player)
end))

local isRightMouseDown = false
table.insert(ScriptConnections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isRightMouseDown = true
    end
end))
table.insert(ScriptConnections, UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isRightMouseDown = false
    end
end))

do -- Weather & World Modulation
-- ============================================================================
-- Custom Weather (Rain / Snow) & World Lighting / Skybox Modulation System
-- ============================================================================
currentAspectRatioX = currentAspectRatioX or 1.0
currentAspectRatioY = currentAspectRatioY or 1.0

-- Original Lighting Backups
originalLighting = {
    Brightness = Lighting.Brightness,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ExposureCompensation = Lighting.ExposureCompensation,
    ClockTime = Lighting.ClockTime,
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd,
    FogColor = Lighting.FogColor
}

local originalBloom = nil
local bloomEffect = Lighting:FindFirstChildOfClass("BloomEffect")
if bloomEffect then
    originalBloom = {
        Intensity = bloomEffect.Intensity,
        Size = bloomEffect.Size,
        Threshold = bloomEffect.Threshold,
        Enabled = bloomEffect.Enabled
    }
end

local originalAtmosphere = nil
local atmosphereEffect = Lighting:FindFirstChildOfClass("Atmosphere")
if atmosphereEffect then
    originalAtmosphere = {
        Density = atmosphereEffect.Density,
        Glare = atmosphereEffect.Glare,
        Haze = atmosphereEffect.Haze,
        Color = atmosphereEffect.Color,
        Decay = atmosphereEffect.Decay
    }
end

-- Skybox Presets
local skyboxPresets = {
    ["Galaxy"] = {Bk="159454299", Dn="159454296", Ft="159454293", Lf="159454286", Rt="159454300", Up="159454288"},
    ["Red"] = "13819946741",
    ["Blue"] = "7415404589",
    ["Pink"] = "9418596884",
    ["Black"] = "5162208676",
    ["White"] = "128499208576916"
}

local customSkyInstance = nil

local function applySkyboxTexture(sky, presetOrId)
    if type(presetOrId) == "table" then
        sky.SkyboxBk = "rbxassetid://" .. presetOrId.Bk
        sky.SkyboxDn = "rbxassetid://" .. presetOrId.Dn
        sky.SkyboxFt = "rbxassetid://" .. presetOrId.Ft
        sky.SkyboxLf = "rbxassetid://" .. presetOrId.Lf
        sky.SkyboxRt = "rbxassetid://" .. presetOrId.Rt
        sky.SkyboxUp = "rbxassetid://" .. presetOrId.Up
    else
        local assetStr = "rbxassetid://" .. tostring(presetOrId):match("%d+")
        sky.SkyboxBk = assetStr
        sky.SkyboxDn = assetStr
        sky.SkyboxFt = assetStr
        sky.SkyboxLf = assetStr
        sky.SkyboxRt = assetStr
        sky.SkyboxUp = assetStr
    end
    sky.CelestialBodiesShown = false
end

updateWorldLighting = function()
    if _G.ConvergenceUnloaded then return end
    
    -- 1. Brightness (Modulates outdoor brightness and scales indoor ambient level)
    if Config.Visuals.BrightnessEnabled then
        Lighting.Brightness = Config.Visuals.Brightness
        if not Config.Visuals.AmbientEnabled then
            local ambientVal = math.clamp(Config.Visuals.Brightness * 25.5, 0, 255)
            Lighting.Ambient = Color3.fromRGB(ambientVal, ambientVal, ambientVal)
        end
    end
    
    -- 2. Exposure
    if Config.Visuals.ExposureEnabled then
        Lighting.ExposureCompensation = Config.Visuals.Exposure
    end
    
    -- 3. Ambient
    if Config.Visuals.AmbientEnabled then
        Lighting.Ambient = Config.Visuals.AmbientColor
    end
    
    -- 4. ClockTime / Time of Day
    if Config.Visuals.ClockTimeEnabled then
        Lighting.ClockTime = Config.Visuals.ClockTime
    end
    
    -- 5. Bloom
    local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
    if Config.Visuals.BloomEnabled then
        if not bloom then
            bloom = Instance.new("BloomEffect")
            ProtectInstance(bloom)
            bloom.Parent = Lighting
        end
        bloom.Intensity = Config.Visuals.BloomIntensity
        bloom.Size = Config.Visuals.BloomSize
        bloom.Threshold = Config.Visuals.BloomThreshold
        bloom.Enabled = true
    elseif bloom and ProtectedRegistry[bloom] then
        bloom:Destroy()
    end
    
    -- 6. Atmosphere Disabler
    local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmo then
        if Config.Visuals.DisableAtmosphere then
            if atmo.Density ~= 0 then atmo.Density = 0 end
            if atmo.Glare ~= 0 then atmo.Glare = 0 end
            if atmo.Haze ~= 0 then atmo.Haze = 0 end
        elseif originalAtmosphere then
            atmo.Density = originalAtmosphere.Density
            atmo.Glare = originalAtmosphere.Glare
            atmo.Haze = originalAtmosphere.Haze
        end
    end
    
    -- 7. Custom Skybox & Clouds Removal
    if Config.Visuals.CustomSkybox then
        local targetId = skyboxPresets[Config.Visuals.CustomSkyboxPreset] or skyboxPresets["Galaxy"]
        
        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("Sky") and not ProtectedRegistry[obj] then
                obj:Destroy()
            end
        end
        
        -- Disable clouds when custom skybox is active
        pcall(function()
            local terrain = Workspace:FindFirstChildOfClass("Terrain")
            if terrain then
                for _, obj in ipairs(terrain:GetChildren()) do
                    if obj:IsA("Clouds") then obj.Enabled = false end
                end
            end
            for _, obj in ipairs(Lighting:GetChildren()) do
                if obj:IsA("Clouds") then obj.Enabled = false end
            end
        end)
        
        if not customSkyInstance or not customSkyInstance.Parent then
            customSkyInstance = Instance.new("Sky")
            ProtectInstance(customSkyInstance)
            customSkyInstance.Parent = Lighting
        end
        applySkyboxTexture(customSkyInstance, targetId)
    else
        if customSkyInstance then
            customSkyInstance:Destroy()
            customSkyInstance = nil
        end
        -- Restore clouds
        pcall(function()
            local terrain = Workspace:FindFirstChildOfClass("Terrain")
            if terrain then
                for _, obj in ipairs(terrain:GetChildren()) do
                    if obj:IsA("Clouds") then obj.Enabled = true end
                end
            end
            for _, obj in ipairs(Lighting:GetChildren()) do
                if obj:IsA("Clouds") then obj.Enabled = true end
            end
        end)
    end
end

-- Custom Weather System (Overhead Anchor)
weatherPart = nil
weatherEmitter = nil

local function setupWeatherSystem()
    if weatherPart then pcall(function() weatherPart:Destroy() end) end
    weatherPart = Instance.new("Part")
    ProtectInstance(weatherPart)
    weatherPart.Anchored = true
    weatherPart.CanCollide = false
    weatherPart.CanTouch = false
    weatherPart.CanQuery = false
    weatherPart.Transparency = 1
    weatherPart.Size = Vector3.new(45, 0.001, 45)
    weatherPart.CastShadow = false
    weatherPart.Parent = WorkspaceContainer or Workspace
    
    weatherEmitter = Instance.new("ParticleEmitter")
    ProtectInstance(weatherEmitter)
    weatherEmitter.Texture = "rbxassetid://3806148993"
    weatherEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
    weatherEmitter.LightEmission = 0
    weatherEmitter.LightInfluence = 1
    weatherEmitter.Orientation = Enum.ParticleOrientation.FacingCameraWorldUp
    weatherEmitter.Size = NumberSequence.new(0.25)
    weatherEmitter.Transparency = NumberSequence.new(0)
    weatherEmitter.Lifetime = NumberRange.new(4, 7)
    weatherEmitter.Rate = 100
    weatherEmitter.Speed = NumberRange.new(6)
    weatherEmitter.SpreadAngle = Vector2.new(0, 0)
    weatherEmitter.EmissionDirection = Enum.NormalId.Bottom
    weatherEmitter.Shape = Enum.ParticleEmitterShape.Box
    weatherEmitter.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
    weatherEmitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
    weatherEmitter.Drag = 0
    weatherEmitter.LockedToPart = true
    weatherEmitter.Enabled = false
    weatherEmitter.Parent = weatherPart
end

updateWeatherEmitter = function()
    if not weatherEmitter or not weatherPart then return end
    if not Config.Visuals.RainEnabled then
        weatherEmitter.Enabled = false
        return
    end
    
    if Config.Visuals.ParticleType == "Rain" then
        weatherEmitter.Texture = "rbxassetid://3806148993"
        weatherEmitter.Size = NumberSequence.new(0.25)
    else -- Snow
        weatherEmitter.Texture = "rbxassetid://2861799"
        weatherEmitter.Size = NumberSequence.new(0.015)
    end
    
    local rateMap = { [1] = 15, [2] = 50, [3] = 100, [4] = 250, [5] = 500 }
    weatherEmitter.Rate = rateMap[Config.Visuals.RainIntensity] or 100
    weatherEmitter.Enabled = true
end

setupWeatherSystem()


end

local crosshairAngle = 0
local espConnection
espConnection = RunService.RenderStepped:Connect(function(deltaTime)
    pcall(updateAllResolvedHeads)
    
    -- 1. Aspect Ratio Matrix Modifier (Smooth & exact KnifeDuels method)
    local cam = Workspace.CurrentCamera
    if cam then
        local targetAspectX = Config.Visuals.AspectRatioEnabled and Config.Visuals.AspectRatioX or 1.0
        local targetAspectY = Config.Visuals.AspectRatioEnabled and Config.Visuals.AspectRatioY or 1.0
        currentAspectRatioX = currentAspectRatioX + (targetAspectX - currentAspectRatioX) * math.clamp((deltaTime or 0.016) * 10, 0, 1)
        currentAspectRatioY = currentAspectRatioY + (targetAspectY - currentAspectRatioY) * math.clamp((deltaTime or 0.016) * 10, 0, 1)
        
        if math.abs(currentAspectRatioX - 1.0) > 0.001 or math.abs(currentAspectRatioY - 1.0) > 0.001 then
            cam.CFrame = cam.CFrame * CFrame.new(0, 0, 0, currentAspectRatioX, 0, 0, 0, currentAspectRatioY, 0, 0, 0, 1)
        end
    end
    
    -- 2. Weather Anchor Positioning
    if weatherPart and Config.Visuals.RainEnabled then
        local char = getLocalCharacter()
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("Head")
            if hrp then
                weatherPart.Position = hrp.Position + Vector3.new(0, 22, 0)
            end
        end
    end
    
    -- 3. World Lighting Updates
    pcall(updateWorldLighting)

    -- FOV Circle Position & Visibility (Degrees 1 - 360)
    if Config.GunMods.ShowFOV then
        local camera = Workspace.CurrentCamera
        local center = camera.ViewportSize / 2
        FOVCircle.Position = center
        local aimFov = Config.GunMods.AimFOV or 15
        if aimFov >= 180 then
            FOVCircle.Radius = math.max(camera.ViewportSize.X, camera.ViewportSize.Y) * 1.5
        else
            local vFovRad = math.rad(camera.FieldOfView)
            local targetFovRad = math.clamp(math.rad(aimFov), 0.01, math.rad(179))
            local fovRadius = (math.tan(targetFovRad / 2) / math.tan(vFovRad / 2)) * (camera.ViewportSize.Y / 2)
            FOVCircle.Radius = math.clamp(fovRadius, 1, 5000)
        end
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end

    -- Custom Crosshair & Game Crosshair Management
    if Config.Crosshair.Enabled then
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            for _, obj in ipairs(playerGui:GetDescendants()) do
                local name = obj.Name:lower()
                if name:find("crosshair") or name:find("reticle") or name == "dot" or name == "centerdot" then
                    if obj:IsA("GuiObject") then
                        if not obj:GetAttribute("OriginalPosition") then
                            obj:SetAttribute("OriginalPosition", obj.Position)
                        end
                        obj.Visible = false
                        obj.Position = UDim2.new(1000, 0, 1000, 0)
                    end
                end
            end
        end

        local cam = Workspace.CurrentCamera
        local char = LocalPlayer.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
        local isZooming = false
        
        if tool then
            isZooming = (_G.Aiming == true)
                or isRightMouseDown
                or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
                or (UserInputService.GamepadEnabled and UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonL2))
                or (cam and cam.FieldOfView < 68)
        end

        if Config.Crosshair.HideOnZoom and isZooming then
            for _, line in pairs(CrosshairLines.Main) do line.Visible = false end
            for _, line in pairs(CrosshairLines.Outline) do line.Visible = false end
        else
            local cam = Workspace.CurrentCamera
            if cam then
                local center = cam.ViewportSize / 2
                
                if Config.Crosshair.Spin then
                    local speed = (Config.Crosshair.SpinSpeed or 1)
                    crosshairAngle = (crosshairAngle + (deltaTime * speed * 0.5)) % (math.pi * 2)
                else
                    crosshairAngle = 0
                end
                
                local gap = Config.Crosshair.Gap or 5
                local len = Config.Crosshair.Length or 10
                local thick = Config.Crosshair.Thickness or 1
                local outThick = Config.Crosshair.OutlineThickness or 1
                local color = Config.Crosshair.Color or Color3.fromRGB(255, 255, 255)
                local outColor = Config.Crosshair.OutlineColor or Color3.fromRGB(0, 0, 0)
                local mainTrans = math.clamp(1 - (Config.Crosshair.Transparency or 0), 0, 1)
                local outTrans = math.clamp(1 - (Config.Crosshair.OutlineTransparency or 0), 0, 1)
                local hasOutline = Config.Crosshair.Outline
                
                local dirs = {
                    Top = -math.pi / 2,
                    Right = 0,
                    Bottom = math.pi / 2,
                    Left = math.pi
                }
                
                for name, baseAngle in pairs(dirs) do
                    local curAngle = baseAngle + crosshairAngle
                    local dirVec = Vector2.new(math.cos(curAngle), math.sin(curAngle))
                    
                    local from = center + (dirVec * gap)
                    local to = center + (dirVec * (gap + len))
                    
                    local mainLine = CrosshairLines.Main[name]
                    local outLine = CrosshairLines.Outline[name]
                    
                    if outLine then
                        if hasOutline then
                            outLine.From = from - (dirVec * (outThick / 2))
                            outLine.To = to + (dirVec * (outThick / 2))
                            outLine.Thickness = thick + (outThick * 2)
                            outLine.Color = outColor
                            outLine.Transparency = outTrans
                            outLine.Visible = true
                        else
                            outLine.Visible = false
                        end
                    end
                    
                    if mainLine then
                        mainLine.From = from
                        mainLine.To = to
                        mainLine.Thickness = thick
                        mainLine.Color = color
                        mainLine.Transparency = mainTrans
                        mainLine.Visible = true
                    end
                end
            end
        end
    else
        for _, line in pairs(CrosshairLines.Main) do line.Visible = false end
        for _, line in pairs(CrosshairLines.Outline) do line.Visible = false end
        
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            for _, obj in ipairs(playerGui:GetDescendants()) do
                local origPos = obj:GetAttribute("OriginalPosition")
                if origPos and obj:IsA("GuiObject") then
                    obj.Position = origPos
                    obj:SetAttribute("OriginalPosition", nil)
                end
            end
        end
    end

    -- Ammo Indicator Rendering
    if Config.ESP.AmmoIndicator then
        local camera = Workspace.CurrentCamera
        if camera then
            local center = camera.ViewportSize / 2
            AmmoIndicatorText.Position = Vector2.new(center.X, center.Y + 34)
            AmmoIndicatorText.Color = Config.ESP.AmmoIndicatorColor or Color3.fromRGB(255, 255, 255)
            
            local char = LocalPlayer.Character or (Workspace:FindFirstChild("Characters") and Workspace.Characters:FindFirstChild(LocalPlayer.Name)) or Workspace:FindFirstChild(LocalPlayer.Name)
            local tool = char and char:FindFirstChildOfClass("Tool")
            local ammoStr = nil
            
            -- Check PlayerGui for GunGUI
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                local gunGui = playerGui:FindFirstChild("GunGUI", true) or playerGui:FindFirstChild("GunGui", true)
                if gunGui then
                    local magFrame = gunGui:FindFirstChild("Mag", true)
                    local reloadIndicator = magFrame and (magFrame:FindFirstChild("Reloading") or magFrame:FindFirstChild("Reload"))
                    
                    if reloadIndicator and reloadIndicator.Visible then
                        ammoStr = "Reloading..."
                    else
                        local magCurrent = magFrame and magFrame:FindFirstChild("Current")
                        local ammoFrame = gunGui:FindFirstChild("Ammo", true)
                        local ammoCurrent = ammoFrame and ammoFrame:FindFirstChild("Current")
                        
                        local curMag = (magCurrent and magCurrent:IsA("TextLabel") and magCurrent.Text ~= "" and tostring(magCurrent.Text)) or nil
                        local curAmmo = (ammoCurrent and ammoCurrent:IsA("TextLabel") and ammoCurrent.Text ~= "" and tostring(ammoCurrent.Text)) or nil
                        
                        if curMag then
                            if curAmmo and (not ammoFrame or ammoFrame.Visible) then
                                ammoStr = curMag .. " / " .. curAmmo
                            else
                                ammoStr = curMag
                            end
                        end
                    end
                    
                    -- Fallback within GunGUI: amount / other labels
                    if not ammoStr then
                        local amountLabel = gunGui:FindFirstChild("amount", true) or gunGui:FindFirstChild("Amount", true)
                        if amountLabel and amountLabel:IsA("TextLabel") and amountLabel.Text ~= "" then
                            local t = amountLabel.Text
                            local tLower = t:lower()
                            if tLower:find("reloading") or tLower == "reload" or tLower == "..." then
                                ammoStr = "Reloading..."
                            else
                                local n1, n2 = t:match("(%d+)[%s%-%|%/%\\]+(%d+)") or t:match("(%d+)%s*[\r\n]+%s*(%d+)")
                                if n1 and n2 then
                                    ammoStr = tostring(n1) .. " / " .. tostring(n2)
                                else
                                    local single = t:match("(%d+)")
                                    if single then ammoStr = tostring(single) end
                                end
                            end
                        end
                    end
                end
            end
            
            -- Direct Tool Value Objects Fallback
            if not ammoStr and tool then
                local reloadVal = tool:FindFirstChild("Reloading", true) or tool:FindFirstChild("isReloading", true) or tool:FindFirstChild("Reload", true)
                if reloadVal and reloadVal:IsA("BoolValue") and reloadVal.Value == true then
                    ammoStr = "Reloading..."
                else
                    local serverFolder = tool:FindFirstChild("Server") or tool:FindFirstChild("Setting")
                    local magVal = (serverFolder and serverFolder:FindFirstChild("Mag")) or tool:FindFirstChild("Mag", true)
                    local ammoVal = (serverFolder and (serverFolder:FindFirstChild("Ammo") or serverFolder:FindFirstChild("StoredAmmo") or serverFolder:FindFirstChild("AmmoVal") or serverFolder:FindFirstChild("Reserve"))) or tool:FindFirstChild("Ammo", true)
                    
                    if magVal and magVal:IsA("ValueBase") then
                        if ammoVal and ammoVal:IsA("ValueBase") then
                            ammoStr = tostring(magVal.Value) .. " / " .. tostring(ammoVal.Value)
                        else
                            ammoStr = tostring(magVal.Value)
                        end
                    end
                end
            end
            
            if ammoStr and ammoStr ~= "" then
                AmmoIndicatorText.Text = ammoStr
                AmmoIndicatorText.Transparency = math.clamp(1 - (Config.ESP.AmmoIndicatorTransparency or 0), 0, 1)
                AmmoIndicatorText.Visible = true
            else
                AmmoIndicatorText.Visible = false
            end
        else
            AmmoIndicatorText.Visible = false
        end
    else
        AmmoIndicatorText.Visible = false
    end

    -- Safe Head Indicator (rendered below Ammo Indicator)
    if Config.GunMods.SafeHead then
        local camera = Workspace.CurrentCamera
        if camera then
            local center = camera.ViewportSize / 2
            local offsetBelowAmmo = (Config.ESP.AmmoIndicator and AmmoIndicatorText.Visible) and 50 or 34
            SafeHeadIndicatorText.Position = Vector2.new(center.X, center.Y + offsetBelowAmmo)
            SafeHeadIndicatorText.Color = Color3.fromRGB(255, 50, 50)
            SafeHeadIndicatorText.Text = "Safe Head"
            SafeHeadIndicatorText.Transparency = 1
            SafeHeadIndicatorText.Visible = true
        else
            SafeHeadIndicatorText.Visible = false
        end
    else
        SafeHeadIndicatorText.Visible = false
    end

    local function getCharacterScreenBounds(char, camera)
        if not char or not char:IsDescendantOf(workspace) then return nil end
        local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChildWhichIsA("BasePart")
        if not rootPart then return nil end
        
        local distance = (rootPart.Position - camera.CFrame.Position).Magnitude
        if distance < 1.5 or distance > 400 then return nil end
        
        local rootScreen, rootOn = camera:WorldToViewportPoint(rootPart.Position)
        if rootScreen.Z <= 0 and not rootOn then return nil end
        
        local rootPos = rootPart.Position
        local minX = math.huge
        local maxX = -math.huge
        local minY = math.huge
        local maxY = -math.huge
        local anyOnScreen = false
        
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") and not part:FindFirstAncestorOfClass("Accessory") and not part:FindFirstAncestorOfClass("Tool") then
                local pPos = part.Position
                local isHead = (part.Name:lower() == "head")
                local isDesyncedHead = isHead and ((pPos - rootPos).Magnitude > 5)
                local pCF = part.CFrame
                local pSize = part.Size
                
                if isDesyncedHead then
                    local ut = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or rootPart
                    pCF = ut.CFrame * CFrame.new(0, 1.4, 0)
                    pPos = pCF.Position
                    pSize = Vector3.new(1.2, 1.2, 1.2)
                end
                
                if (pPos - rootPos).Magnitude <= 6 then
                    local phx, phy, phz = pSize.X * 0.5, pSize.Y * 0.5, pSize.Z * 0.5
                    local r0 = pCF.RightVector * phx
                    local r1 = pCF.UpVector * phy
                    local r2 = -pCF.LookVector * phz
                    
                    for sx = -1, 1, 2 do
                        local ox = r0 * sx
                        for sy = -1, 1, 2 do
                            local oxy = ox + (r1 * sy)
                            for sz = -1, 1, 2 do
                                local p3d = pPos + oxy + (r2 * sz)
                                local sp, onScreen = camera:WorldToViewportPoint(p3d)
                                if sp.Z > 0 then
                                    if onScreen then anyOnScreen = true end
                                    if sp.X < minX then minX = sp.X end
                                    if sp.X > maxX then maxX = sp.X end
                                    if sp.Y < minY then minY = sp.Y end
                                    if sp.Y > maxY then maxY = sp.Y end
                                end
                            end
                        end
                    end
                end
            end
        end
        
        if (anyOnScreen or rootOn) and minX ~= math.huge and maxX > minX and maxY > minY then
            minX = minX - 1.5
            maxX = maxX + 1.5
            minY = minY - 1.5
            maxY = maxY + 1.5
            
            local width = maxX - minX
            local height = maxY - minY
            if width < 4 then width = 4 end
            if height < 4 then height = 4 end
            
            local boxPos = Vector2.new(math.floor(minX), math.floor(minY))
            local boxSize = Vector2.new(math.floor(width), math.floor(height))
            
            return boxPos, boxSize, distance
        end
        
        return nil
    end

    -- ESP Rendering Loop (Players + Dummies/NPCs)
    local currentTargets = getAllTargets()
    local activeCharKeys = {}
    local camera = Workspace.CurrentCamera
    
    for _, targetInfo in ipairs(currentTargets) do
        local char = targetInfo.Character
        activeCharKeys[char] = true
        
        if not ESPObjects[char] then
            ESPObjects[char] = createESP(char)
        end
        local esp = ESPObjects[char]
        
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        local isAlive = (not humanoid) or (humanoid.Health > 0)
        local anyESPEnabled = Config.ESP.Boxes or Config.ESP.Names or Config.ESP.Health or Config.ESP.Flags
        local isTeammateTarget = targetInfo.IsPlayer and Config.ESP.TeamCheck and isTeammate(targetInfo.Player)
        
        if anyESPEnabled and char and char:IsDescendantOf(workspace) and not isTeammateTarget and camera then
            local boxPos, boxSize = getCharacterScreenBounds(char, camera)
            
            if isAlive then
                if boxPos and boxSize then
                    esp.Alpha = 1
                    local boxTrans = math.clamp(1 - (Config.ESP.BoxTransparency or 0), 0, 1)
                    local nameTrans = math.clamp(1 - (Config.ESP.NameTransparency or 0), 0, 1)
                    local healthTrans = math.clamp(1 - (Config.ESP.HealthTransparency or 0), 0, 1)
                    local flagTrans = math.clamp(1 - (Config.ESP.FlagsTransparency or 0), 0, 1)
                    
                    if Config.ESP.Boxes then
                        esp.BoxOutline.Size = boxSize
                        esp.BoxOutline.Position = boxPos
                        esp.BoxOutline.Transparency = boxTrans
                        esp.BoxOutline.Visible = true
                        
                        esp.Box.Size = boxSize
                        esp.Box.Position = boxPos
                        esp.Box.Color = Config.ESP.Color
                        esp.Box.Transparency = boxTrans
                        esp.Box.Visible = true
                    else
                        esp.BoxOutline.Visible = false
                        esp.Box.Visible = false
                    end
                    
                    if Config.ESP.Names then
                        local nameStr = tostring(targetInfo.Name or (targetInfo.IsPlayer and targetInfo.Player and (targetInfo.Player.DisplayName or targetInfo.Player.Name)) or (char and char.Name) or "Target")
                        esp.Name.Text = nameStr
                        esp.Name.Position = Vector2.new(boxPos.X + (boxSize.X / 2), boxPos.Y - 16)
                        esp.Name.Color = Config.ESP.NameColor or Color3.fromRGB(255, 255, 255)
                        esp.Name.Transparency = nameTrans
                        esp.Name.Visible = true
                    else
                        esp.Name.Visible = false
                    end
                    
                    if Config.ESP.Health and humanoid then
                        local health = tonumber(humanoid.Health) or 100
                        local maxHealth = tonumber(humanoid.MaxHealth) or 100
                        
                        esp.HealthOutline.Size = Vector2.new(4, boxSize.Y + 2)
                        esp.HealthOutline.Position = Vector2.new(boxPos.X - 6, boxPos.Y - 1)
                        esp.HealthOutline.Transparency = healthTrans
                        esp.HealthOutline.Visible = true
                        
                        esp.HealthBar.Size = Vector2.new(2, (health / math.max(1, maxHealth)) * boxSize.Y)
                        esp.HealthBar.Position = Vector2.new(boxPos.X - 5, boxPos.Y + (boxSize.Y - esp.HealthBar.Size.Y))
                        esp.HealthBar.Color = Config.ESP.HealthColor
                        esp.HealthBar.Transparency = healthTrans
                        esp.HealthBar.Visible = true
                    else
                        esp.HealthOutline.Visible = false
                        esp.HealthBar.Visible = false
                    end
                    
                    if Config.ESP.Flags then
                        local flagX = boxPos.X + boxSize.X + 4
                        local flagY = boxPos.Y
                        local flagIndex = 0
                        
                        -- Row 1: Safe Head (Red)
                        local isSafeHeading = false
                        local origHead = nil
                        for _, child in ipairs(char:GetChildren()) do
                            if child:IsA("BasePart") and child.Name == "Head" then
                                origHead = child
                                break
                            end
                        end
                        local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
                        local rootPos = rootPart and rootPart.Position
                        if not origHead then
                            isSafeHeading = true
                        elseif rootPos then
                            local headDist = (origHead.Position - rootPos).Magnitude
                            if headDist > 5 or origHead.Position.Y < -500 or (not origHead.CanQuery) then
                                isSafeHeading = true
                            end
                        end
                        
                        if isSafeHeading then
                            esp.FlagSafeHead.Position = Vector2.new(flagX, flagY + (flagIndex * 11))
                            esp.FlagSafeHead.Color = Color3.fromRGB(255, 50, 50)
                            esp.FlagSafeHead.Transparency = flagTrans
                            esp.FlagSafeHead.Visible = true
                            flagIndex = flagIndex + 1
                        else
                            esp.FlagSafeHead.Visible = false
                        end
                        
                        -- Row 2: Reloading (Cyan, below Safe Head)
                        local isReloading = isCharacterReloading(char, humanoid)
                        if isReloading then
                            esp.FlagReloading.Position = Vector2.new(flagX, flagY + (flagIndex * 11))
                            esp.FlagReloading.Color = Color3.fromRGB(0, 255, 255)
                            esp.FlagReloading.Transparency = flagTrans
                            esp.FlagReloading.Visible = true
                            flagIndex = flagIndex + 1
                        else
                            esp.FlagReloading.Visible = false
                        end
                    else
                        esp.FlagSafeHead.Visible = false
                        esp.FlagReloading.Visible = false
                    end
                else
                    -- Alive but off screen -> Instantly hide, no fade
                    esp.Alpha = 1
                    esp.BoxOutline.Visible = false
                    esp.Box.Visible = false
                    esp.Name.Visible = false
                    esp.HealthOutline.Visible = false
                    esp.HealthBar.Visible = false
                    esp.FlagSafeHead.Visible = false
                    esp.FlagReloading.Visible = false
                end
            else
                -- Target is dead -> Slow death fade ONLY while on screen
                esp.FlagSafeHead.Visible = false
                esp.FlagReloading.Visible = false
                if boxPos and boxSize and esp.Alpha and esp.Alpha > 0 then
                    esp.Alpha = math.max(0, esp.Alpha - (deltaTime * 1.5))
                    local boxTrans = math.clamp(1 - (Config.ESP.BoxTransparency or 0), 0, 1)
                    local nameTrans = math.clamp(1 - (Config.ESP.NameTransparency or 0), 0, 1)
                    local healthTrans = math.clamp(1 - (Config.ESP.HealthTransparency or 0), 0, 1)
                    
                    esp.BoxOutline.Size = boxSize
                    esp.BoxOutline.Position = boxPos
                    esp.BoxOutline.Transparency = esp.Alpha * boxTrans
                    esp.BoxOutline.Visible = Config.ESP.Boxes and (esp.Alpha > 0.01)
                    
                    esp.Box.Size = boxSize
                    esp.Box.Position = boxPos
                    esp.Box.Color = Config.ESP.Color
                    esp.Box.Transparency = esp.Alpha * boxTrans
                    esp.Box.Visible = Config.ESP.Boxes and (esp.Alpha > 0.01)
                    
                    local nameStr = tostring(targetInfo.Name or (targetInfo.IsPlayer and targetInfo.Player and (targetInfo.Player.DisplayName or targetInfo.Player.Name)) or (char and char.Name) or "Target")
                    esp.Name.Text = nameStr
                    esp.Name.Position = Vector2.new(boxPos.X + (boxSize.X / 2), boxPos.Y - 16)
                    esp.Name.Color = Config.ESP.NameColor or Color3.fromRGB(255, 255, 255)
                    esp.Name.Transparency = esp.Alpha * nameTrans
                    esp.Name.Visible = Config.ESP.Names and (esp.Alpha > 0.01)
                    
                    esp.HealthOutline.Size = Vector2.new(4, boxSize.Y + 2)
                    esp.HealthOutline.Position = Vector2.new(boxPos.X - 6, boxPos.Y - 1)
                    esp.HealthOutline.Transparency = esp.Alpha * healthTrans
                    esp.HealthOutline.Visible = Config.ESP.Health and (esp.Alpha > 0.01)
                    
                    esp.HealthBar.Size = Vector2.new(2, 0)
                    esp.HealthBar.Position = Vector2.new(boxPos.X - 5, boxPos.Y + boxSize.Y)
                    esp.HealthBar.Color = Config.ESP.HealthColor
                    esp.HealthBar.Transparency = esp.Alpha * healthTrans
                    esp.HealthBar.Visible = Config.ESP.Health and (esp.Alpha > 0.01)
                else
                    esp.Alpha = 0
                    esp.BoxOutline.Visible = false
                    esp.Box.Visible = false
                    esp.Name.Visible = false
                    esp.HealthOutline.Visible = false
                    esp.HealthBar.Visible = false
                    esp.FlagReloading.Visible = false
                    esp.FlagSafeHead.Visible = false
                end
            end
        else
            esp.Alpha = 0
            esp.BoxOutline.Visible = false
            esp.Box.Visible = false
            esp.Name.Visible = false
            esp.HealthOutline.Visible = false
            esp.HealthBar.Visible = false
            esp.FlagReloading.Visible = false
            esp.FlagSafeHead.Visible = false
        end
    end
    
    for charKey, esp in pairs(ESPObjects) do
        if not activeCharKeys[charKey] then
            removeESP(charKey)
        end
    end
end)

-- Game-Specific Gun Mods
local originalGunMods = {}
local cachedActiveGunData = {}
local cachedGunUpvalueTables = {}
local cachedFireFunction = nil



restoreOriginalGunMods = function()
    pcall(function()
        if originalGunMods then
            for gunModule, orig in pairs(originalGunMods) do
                if typeof(gunModule) == "Instance" and gunModule:IsA("ModuleScript") then
                    local success, gunData = pcall(require, gunModule)
                    if success and type(gunData) == "table" then
                        for k, v in pairs(orig) do
                            pcall(function() rawset(gunData, k, v) end)
                        end
                    end
                end
            end
        end
    end)
    for _, val in ipairs(cachedGunUpvalueTables) do
        if type(val) == "table" then
            pcall(function()
                rawset(val, "ExplosiveEnabled", false)
                rawset(val, "ShotgunEnabled", false)
            end)
        end
    end
    table.clear(cachedGunUpvalueTables)
    table.clear(cachedActiveGunData)
end

applyGunMods = function()
    pcall(function()
        local gunsFolder = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("Guns")
        if not gunsFolder then return end
        
        table.clear(cachedActiveGunData)
        for _, gunModule in ipairs(gunsFolder:GetChildren()) do
            if gunModule:IsA("ModuleScript") then
                local success, gunData = pcall(require, gunModule)
                if success and type(gunData) == "table" then
                    table.insert(cachedActiveGunData, gunData)
                    if not originalGunMods[gunModule] then
                        originalGunMods[gunModule] = {
                            XRecoil = rawget(gunData, "XRecoil"),
                            LeftValue = rawget(gunData, "LeftValue"),
                            RightValue = rawget(gunData, "RightValue"),
                            ZRecoil = rawget(gunData, "ZRecoil"),
                            vmRecoil = rawget(gunData, "vmRecoil"),
                            Spread = rawget(gunData, "Spread"),
                            FireRate = rawget(gunData, "FireRate"),
                            DelayBeforeFiring = rawget(gunData, "DelayBeforeFiring"),
                            DelayAfterFiring = rawget(gunData, "DelayAfterFiring"),
                            BurstRate = rawget(gunData, "BurstRate"),
                            FireAnimationSpeed = rawget(gunData, "FireAnimationSpeed"),
                            ReloadTime = rawget(gunData, "ReloadTime"),
                            AmmoPerMag = rawget(gunData, "AmmoPerMag"),
                            MaxAmmo = rawget(gunData, "MaxAmmo"),
                            LimitedAmmoEnabled = rawget(gunData, "LimitedAmmoEnabled"),
                            ExplosiveEnabled = rawget(gunData, "ExplosiveEnabled"),
                            ShotgunEnabled = rawget(gunData, "ShotgunEnabled"),
                            BulletPerShot = rawget(gunData, "BulletPerShot")
                        }
                    end
                    
                    if _G.ConvergenceUnloaded then
                        for k, v in pairs(originalGunMods[gunModule]) do
                            gunData[k] = v
                        end
                        continue
                    end
                    
                    local orig = originalGunMods[gunModule]
                    
                    if type(rawget(gunData, "HitSoundIDs")) ~= "table" or #gunData.HitSoundIDs == 0 then
                        gunData.HitSoundIDs = { 186809061, 186809249, 186809250, 186809252 }
                    end
                    if type(rawget(gunData, "HitCharSndIDs")) ~= "table" or #gunData.HitCharSndIDs == 0 then
                        gunData.HitCharSndIDs = { 245630921, 245630994, 245631056, 245631112, 245631167 }
                    end
                    if type(rawget(gunData, "ExplosionSoundIDs")) ~= "table" or #gunData.ExplosionSoundIDs == 0 or (type(gunData.ExplosionSoundIDs[1]) == "number" and gunData.ExplosionSoundIDs[1] == 163064102) then
                        gunData.ExplosionSoundIDs = { 287390954, 287391087, 287391197 }
                    end
                    
                    if Config.GunMods.RapidFire then
                        gunData.FireRate = 0.01
                        gunData.DelayBeforeFiring = 0
                        gunData.BurstRate = 0
                    else
                        if orig.FireRate ~= nil then gunData.FireRate = orig.FireRate end
                        if orig.DelayBeforeFiring ~= nil then gunData.DelayBeforeFiring = orig.DelayBeforeFiring end
                        if orig.BurstRate ~= nil then gunData.BurstRate = orig.BurstRate end
                    end

                    if Config.GunMods.InstaReload then
                        gunData.ReloadTime = 0.01
                        if rawget(gunData, "ReloadAnimationSpeed") then gunData.ReloadAnimationSpeed = 99999 end
                        if rawget(gunData, "ReloadAnimSpeed") then gunData.ReloadAnimSpeed = 99999 end
                    else
                        if orig.ReloadTime ~= nil then gunData.ReloadTime = orig.ReloadTime end
                    end

                    if Config.GunMods.InfAmmo then
                        gunData.AmmoPerMag = math.huge
                        gunData.LimitedAmmoEnabled = false
                    else
                        if orig.AmmoPerMag ~= nil then gunData.AmmoPerMag = orig.AmmoPerMag end
                        if orig.MaxAmmo ~= nil then gunData.MaxAmmo = orig.MaxAmmo end
                        if orig.LimitedAmmoEnabled ~= nil then gunData.LimitedAmmoEnabled = orig.LimitedAmmoEnabled end
                    end
                    
                    if Config.GunMods.NoRecoil then
                        local vMult = Config.GunMods.RecoilVert
                        local hMult = Config.GunMods.RecoilHoriz
                        
                        if orig.XRecoil ~= nil then gunData.XRecoil = orig.XRecoil * vMult end
                        if orig.LeftValue ~= nil then gunData.LeftValue = orig.LeftValue * hMult end
                        if orig.RightValue ~= nil then gunData.RightValue = orig.RightValue * hMult end
                        
                        if orig.ZRecoil ~= nil then
                            if hMult <= 0.01 then
                                gunData.ZRecoil = 999999
                            else
                                gunData.ZRecoil = orig.ZRecoil / hMult
                            end
                        end
                        
                        if orig.vmRecoil ~= nil then gunData.vmRecoil = orig.vmRecoil * vMult end
                    else
                        if orig.XRecoil ~= nil then gunData.XRecoil = orig.XRecoil end
                        if orig.LeftValue ~= nil then gunData.LeftValue = orig.LeftValue end
                        if orig.RightValue ~= nil then gunData.RightValue = orig.RightValue end
                        if orig.ZRecoil ~= nil then gunData.ZRecoil = orig.ZRecoil end
                        if orig.vmRecoil ~= nil then gunData.vmRecoil = orig.vmRecoil end
                    end
                    
                    if Config.GunMods.NoSpread then
                        local mult = math.max(0.01, Config.GunMods.SpreadMult)
                        if type(orig.Spread) == "table" then
                            if type(gunData.Spread) ~= "table" then gunData.Spread = {} end
                            if type(orig.Spread.Range) == "table" then
                                if type(gunData.Spread.Range) ~= "table" then gunData.Spread.Range = {} end
                                gunData.Spread.Range.Min = orig.Spread.Range.Min * mult
                                gunData.Spread.Range.Max = math.max((orig.Spread.Range.Min * mult) + 0.01, orig.Spread.Range.Max * mult)
                            end
                            if orig.Spread.PerShot then gunData.Spread.PerShot = orig.Spread.PerShot * mult end
                            if orig.Spread.MovementMultiplier then gunData.Spread.MovementMultiplier = orig.Spread.MovementMultiplier * mult end
                        elseif type(orig.Spread) == "number" then
                            gunData.Spread = orig.Spread * mult
                        end
                    else
                        if orig.Spread ~= nil then gunData.Spread = orig.Spread end
                    end
                end
            end
        end
    end)
end

local hookedClosures = {}

hookGunClosures = function()
    local hookedSomething = false
    if typeof(getgc) == "function" and typeof(hookfunction) == "function" then
        for _, v in ipairs(getgc()) do
            if type(v) == "function" and islclosure(v) and not (isexecutorclosure and isexecutorclosure(v)) then
                local ok, info = pcall(debug.getinfo, v)
                if not ok or type(info) ~= "table" then continue end
                
                local isGetHitPos = false
                if info.name == "getHitPos" then
                    isGetHitPos = true
                elseif type(info.source) == "string" and info.source:find("GunClientModule") and info.name == "getHitPos" then
                    isGetHitPos = true
                elseif type(debug.getupvalues) == "function" then
                    local okUv, uvs = pcall(debug.getupvalues, v)
                    if okUv and type(uvs) == "table" then
                        local hasRaycast = false
                        local hasLib = false
                        for _, uv in pairs(uvs) do
                            if typeof(uv) == "RaycastParams" then
                                hasRaycast = true
                            elseif type(uv) == "table" and (uv.BaseDamage or uv.FireRate or uv.Spread ~= nil) then
                                hasLib = true
                            end
                        end
                        if hasRaycast and hasLib then
                            isGetHitPos = true
                        end
                    end
                end
                
                if isGetHitPos and not hookedClosures[v] then
                    hookedClosures[v] = true
                    hookedSomething = true
                    local oldGetHitPos
                    oldGetHitPos = hookfunction(v, function(p1, p2)
                        if _G.ConvergenceUnloaded then
                            return oldGetHitPos(p1, p2)
                        end
                        local origin, unit = oldGetHitPos(p1, p2)
                        
                        if Config.GunMods.SilentAim then
                            local bestTarget = getBestCombatTarget()
                            if bestTarget then
                                unit = (bestTarget.targetPos - origin).Unit
                                
                                task.spawn(function()
                                    local hitPart = bestTarget.hitPart
                                    if bestTarget.isSafeHead then
                                        hitPart = bestTarget.character:FindFirstChild("UpperTorso") or bestTarget.character:FindFirstChild("Torso") or bestTarget.character:FindFirstChild("HumanoidRootPart") or hitPart
                                    end
                                    
                                    lastDirectHitTime = os.clock()
                                    if Config.ESP.BulletTracers then
                                        spawnBulletTracer(origin, bestTarget.targetPos)
                                    end
                                end)
                            end
                        end
                        
                        lastLocalPlayerShotTime = os.clock()
                        playShootSound()
                        
                        task.spawn(function()
                            if Config.Misc.Backtrack and canPlayerShoot() then
                                local ghostHit = checkGhostHit(origin, unit)
                                if not ghostHit then
                                    local cam = Workspace.CurrentCamera
                                    if cam then
                                        ghostHit = checkGhostHit(cam.CFrame.Position, cam.CFrame.LookVector)
                                    end
                                end
                                if ghostHit then
                                    lastDirectHitTime = os.clock()
                                    inflictGunDamage(ghostHit.Character, ghostHit.Humanoid, ghostHit.HitPart, ghostHit.HitPosition, false, true)
                                    if Config.ESP.BulletTracers then
                                        spawnBulletTracer(origin, ghostHit.HitPosition)
                                    end
                                end
                            end
                        end)
                        
                        return origin, unit
                    end)
                end
            end
        end
    end
    return hookedSomething
end

local isHookingGC = false
local hasHookedHitPos = false

safeHookGunClosures = function(force)
    if isHookingGC then return end
    if hasHookedHitPos and not force then return end
    isHookingGC = true
    task.spawn(function()
        local success = false
        pcall(function()
            if hookGunClosures() then
                success = true
                hasHookedHitPos = true
            end
        end)
        isHookingGC = false
    end)
end

task.spawn(function()
    while task.wait(3) do
        if _G.ConvergenceUnloaded then break end
        if not hasHookedHitPos then
            safeHookGunClosures(false)
        end
    end
end)

local function onCharEquipWatcher(char)
    if not char then return end
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.delay(0.2, function()
                safeHookGunClosures(true)
            end)
        end
    end)
end

if LocalPlayer.Character then
    onCharEquipWatcher(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(function(char)
    hasHookedHitPos = false
    onCharEquipWatcher(char)
    task.delay(0.5, function()
        safeHookGunClosures(true)
    end)
end)

-- AutoShoot Background Loop (100% reliable damage, visuals, sounds & animations)
local lastAutoShootTick = 0

task.spawn(function()
    while task.wait(0.01) do
        if _G.ConvergenceUnloaded then break end
        if Config.GunMods.AutoShoot and canPlayerShoot() then
            local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
            local handle = tool and (tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart"))
            if tool and handle then
                local bestTarget = getBestCombatTarget()
                if bestTarget then
                    local now = os.clock()
                    local fireRate = 0.1
                    pcall(function()
                        local RS = game:GetService("ReplicatedStorage")
                        local gunsMod = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("Guns")
                        if gunsMod and gunsMod:FindFirstChild(tool.Name) then
                            local gData = require(gunsMod[tool.Name])
                            if gData and gData.FireRate then
                                fireRate = math.clamp(gData.FireRate, 0.02, 1)
                            end
                        end
                    end)
                    
                    if (now - lastAutoShootTick) >= fireRate then
                        lastAutoShootTick = now
                        
                        pcall(function()
                            local firePoint = handle:FindFirstChild("FirePoint") or handle
                            local origin = firePoint.Position
                            local dir = (bestTarget.targetPos - origin).Unit
                            
                            local VisualizeBullet = game:GetService("ReplicatedStorage"):FindFirstChild("VisualizeBullet")
                            local fireSound = handle:FindFirstChild("FireSound") or handle:FindFirstChildWhichIsA("Sound")
                            
                            -- 1. Play shoot sound
                            lastLocalPlayerShotTime = os.clock()
                            if Config.GunMods.ShootSound and Config.GunMods.ShootSound ~= "None" then
                                playShootSound()
                            else
                                if fireSound then pcall(function() fireSound:Play() end) end
                            end
                            
                            -- 2. Trigger fire animation on Camera Viewmodel without track spam
                            local cam = Workspace.CurrentCamera
                            if cam then
                                for _, vm in ipairs(cam:GetChildren()) do
                                    if vm:IsA("Model") then
                                        local vmHum = vm:FindFirstChildOfClass("Humanoid") or vm:FindFirstChildOfClass("AnimationController")
                                        local vmAnimator = vmHum and vmHum:FindFirstChildOfClass("Animator")
                                        if vmAnimator then
                                            for _, trk in ipairs(vmAnimator:GetPlayingAnimationTracks()) do
                                                local n = trk.Name:lower()
                                                if (n:find("fire") or n:find("shoot")) and not trk.IsPlaying then
                                                    trk:Play()
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                            
                            -- 4. Deduct ammo from tool ValueBase if present and not InfAmmo
                            if not Config.GunMods.InfAmmo then
                                local magVal = tool:FindFirstChild("Mag") or tool:FindFirstChild("Ammo") or tool:FindFirstChild("Clip")
                                if magVal and magVal:IsA("ValueBase") and type(magVal.Value) == "number" and magVal.Value > 0 then
                                    magVal.Value = magVal.Value - 1
                                end
                            end
                            
                            -- 5. Inflict target damage
                            local didHit = false
                            local hitPart = bestTarget.hitPart
                            if bestTarget.isSafeHead then
                                hitPart = bestTarget.character:FindFirstChild("UpperTorso") or bestTarget.character:FindFirstChild("Torso") or bestTarget.character:FindFirstChild("HumanoidRootPart") or hitPart
                            end
                            didHit = inflictGunDamage(bestTarget.character, bestTarget.humanoid, hitPart, bestTarget.targetPos, false, bestTarget.isBacktrack)
                            
                            -- 6. Replicate bullet visuals to server
                            if VisualizeBullet then
                                local defaultHitSounds = { true, { 186809061, 186809249, 186809250, 186809252 }, 1, 0.5, nil, nil }
                                local defaultBloodSounds = { true, { 245630921, 245630994, 245631056, 245631112 }, 1, 0.5, nil }
                                local emptyTable = { false }
                                VisualizeBullet:FireServer(tool, handle, dir, origin, defaultHitSounds, defaultBloodSounds, emptyTable, emptyTable, emptyTable, emptyTable, { 25, 1.5, true, false }, emptyTable, emptyTable, emptyTable, fireSound, fireSound, nil, nil)
                            end
                            
                            if Config.ESP.BulletTracers then
                                spawnBulletTracer(origin, bestTarget.targetPos)
                            end
                            
                            if didHit then
                                lastDirectHitTime = os.clock()
                            end
                            
                            -- 7. Call cached native closure if available
                            if cachedFireFunction then
                                pcall(cachedFireFunction)
                            end
                        end)
                    end
                end
            end
        end
    end
end)

local _characterConnections = {}local _characterConnections = {}
clearCharacterConnections = function()
    for _, conn in ipairs(_characterConnections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(_characterConnections)
end

bindGunHooks = function(char)
    if not char then return end
    
    local function onToolChanged(tool)
        _G.Reloading = false
        lastAutoShootTick = 0
        cachedFireFunction = nil
        
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            local animator = hum:FindFirstChildOfClass("Animator")
            if animator then
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                    local name = track.Name:lower()
                    local animId = (track.Animation and track.Animation.AnimationId:lower()) or ""
                    if name:find("reload") or (reloadAnimIdSet and reloadAnimIdSet[animId:match("%d+") or ""]) then
                        pcall(function() track:Stop(0) end)
                    end
                end
            end
        end
        
        if tool and tool:IsA("Tool") then
            applyGunMods()
            applyShootSoundToTool(tool)
        end
    end
    
    applyGunMods()
    applyShootSoundToAllEquippedGuns()
    
    table.insert(_characterConnections, char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            onToolChanged(child)
        end
    end))
    
    table.insert(_characterConnections, char.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then
            onToolChanged(nil)
        end
    end))
end

do -- Safe Head & Character Lifecycle
-- Safe Head Logic (Stepped / RenderStepped Desync with Stable Focus & Normal Lighting)
_safeHeadSteppedConn = nil
_safeHeadRenderConn = nil
_safeHeadOriginalJoints = _safeHeadOriginalJoints or {}

getLocalCharacter = function()
    return LocalPlayer.Character or (Workspace:FindFirstChild("Characters") and Workspace.Characters:FindFirstChild(LocalPlayer.Name)) or Workspace:FindFirstChild(LocalPlayer.Name)
end

findCharacterNeck = function(char)
    if not char then return nil end
    for _, desc in ipairs(char:GetDescendants()) do
        if desc:IsA("Motor6D") and (desc.Name:lower() == "neck" or (desc.Part1 and desc.Part1.Name:lower() == "head")) then
            return desc
        end
    end
    local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    if torso then
        local n = torso:FindFirstChild("Neck")
        if n and n:IsA("Motor6D") then return n end
    end
    local head = char:FindFirstChild("Head")
    if head then
        local n = head:FindFirstChild("Neck")
        if n and n:IsA("Motor6D") then return n end
    end
    return nil
end

local function findCharacterRootJoint(char)
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local rj = hrp:FindFirstChild("RootJoint") or hrp:FindFirstChildOfClass("Motor6D")
        if rj and rj:IsA("Motor6D") then return rj end
    end
    local torso = char:FindFirstChild("Torso") or char:FindFirstChild("LowerTorso") or char:FindFirstChild("UpperTorso")
    if torso then
        local rj = torso:FindFirstChild("RootJoint") or torso:FindFirstChild("Root")
        if rj and rj:IsA("Motor6D") then return rj end
    end
    return nil
end

local function getAACalculatedAngles(isLocalRender, serverTimestamp)
    local pitchDeg = Config.GunMods.AAPitch or 0
    local yawDeg = Config.GunMods.AAYaw or 0
    
    if Config.GunMods.AAJitter then
        local jSpeed = math.clamp(Config.GunMods.AAJitterSpeed or Config.GunMods.AAJitterAmount or 5, 1, 10)
        local jOffset = Config.GunMods.AAJitterOffset or 45
        
        local t = serverTimestamp or os.clock()
        if serverTimestamp then
            -- Server network packet replication rate is quantized to 20Hz (~0.05s server physics ticks)
            t = math.floor(t * 20) / 20
        end
        local isStep = (math.floor(t * jSpeed * 2) % 2 == 0)
        yawDeg = yawDeg + (isStep and jOffset or -jOffset)
    end
    
    return math.rad(pitchDeg), math.rad(yawDeg)
end

local function getAABestTarget()
    local cam = Workspace.CurrentCamera
    if not cam then return nil end
    
    local myChar = getLocalCharacter()
    local myHrp = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso"))
    if not myHrp then return nil end
    
    local center = cam.ViewportSize / 2
    local maxFovDeg = Config.GunMods.AimFOV or 15
    local vFovRad = math.rad(cam.FieldOfView)
    local targetFovRad = math.clamp(math.rad(maxFovDeg), 0.01, math.rad(179))
    local fovRadius = (math.tan(targetFovRad / 2) / math.tan(vFovRad / 2)) * (cam.ViewportSize.Y / 2)
    local isFull360 = (maxFovDeg >= 180)
    
    local bestPos = nil
    local shortestScreenDist = math.huge
    local camPos = cam.CFrame.Position
    local camLook = cam.CFrame.LookVector
    
    local function checkCandidate(char, isPlayer, playerObj)
        if not char or char == myChar then return end
        if isPlayer and playerObj and Config.ESP.TeamCheck and isTeammate(playerObj) then
            return
        end
        local hum = char:FindFirstChildOfClass("Humanoid") or char:FindFirstChild("Humanoid", true)
        local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("Head")
        if hum and hum.Health > 0 and root then
            local rootPos = root.Position
            local toTarget = rootPos - camPos
            local dist3D = toTarget.Magnitude
            if dist3D <= 0.01 then return end
            local dirUnit = toTarget.Unit
            local dot = camLook:Dot(dirUnit)
            local angleDeg = math.deg(math.acos(math.clamp(dot, -1, 1)))

            if isFull360 then
                if dist3D < shortestScreenDist then
                    shortestScreenDist = dist3D
                    bestPos = rootPos
                end
            else
                if angleDeg <= (maxFovDeg / 2) then
                    local screenPos, onScreen = cam:WorldToViewportPoint(rootPos)
                    if onScreen and screenPos.Z > 0 then
                        local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                        if screenDist <= fovRadius and screenDist < shortestScreenDist then
                            shortestScreenDist = screenDist
                            bestPos = rootPos
                        end
                    end
                end
            end
        end
    end
    
    if getAllTargets then
        local allTargets = getAllTargets()
        for _, tInfo in ipairs(allTargets) do
            checkCandidate(tInfo.Character, tInfo.IsPlayer, tInfo.Player)
        end
    end
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            checkCandidate(p.Character, true, p)
        end
    end
    
    return bestPos
end

local lastSpawnTime = 0

-- 1. Stepped: Server Physics Simulation Hook (Rotates HRP Orientation & Neck on Server for 100% Synced Yaw/Pitch)
local function _updateSafeHead()
    local isSafeHeadOn = Config.GunMods.SafeHead
    local isAAOn = Config.GunMods.AntiAim
    if not isSafeHeadOn and not isAAOn then return end
    
    local char = getLocalCharacter()
    if not char or not char.Parent then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead then return end
    
    local neck = findCharacterNeck(char)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    
    if neck and neck.Parent then
        if not _safeHeadOriginalJoints[neck] then
            _safeHeadOriginalJoints[neck] = neck.C0
        end
        local baseNeckC0 = _safeHeadOriginalJoints[neck]
        
        if isSafeHeadOn then
            local randomOffset = math.random(100000, 500000)
            neck.C0 = CFrame.new(0, -randomOffset, 0) * baseNeckC0.Rotation
        elseif isAAOn then
            local pRad, _ = getAACalculatedAngles(false)
            neck.C0 = baseNeckC0 * CFrame.Angles(pRad, 0, 0)
        end
    end
    
    if isAAOn and hrp and (os.clock() - (lastSpawnTime or 0) > 1.0) then
        hum.AutoRotate = false
        local cam = Workspace.CurrentCamera
        local camLook = cam and cam.CFrame.LookVector or Vector3.new(0, 0, -1)
        local baseAngle = math.atan2(-camLook.X, -camLook.Z)
        
        if Config.GunMods.AAAtTargets then
            local targetPos = getAABestTarget()
            if targetPos then
                local myPos = hrp.Position
                baseAngle = math.atan2(-(targetPos.X - myPos.X), -(targetPos.Z - myPos.Z))
            end
        end
        
        local _, yRad = getAACalculatedAngles(false)
        
        -- Rotate HumanoidRootPart orientation while strictly preserving physics Position
        hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, baseAngle + yRad, 0)
        
        -- Physics replication synchronization: force high-priority packet transmission
        if Config.GunMods.AAJitter then
            local jSpeed = math.clamp(Config.GunMods.AAJitterSpeed or Config.GunMods.AAJitterAmount or 5, 1, 10)
            local isStep = (math.floor(os.clock() * jSpeed * 2) % 2 == 0)
            hrp.AssemblyAngularVelocity = Vector3.new(0, isStep and 0.05 or -0.05, 0)
        end
    end
    
    local head = char:FindFirstChild("Head")
    if head and isSafeHeadOn then
        if head.CanCollide then head.CanCollide = false end
        if not head.Massless then head.Massless = true end
        if head.CanTouch then head.CanTouch = false end
        if head.CanQuery then head.CanQuery = false end
    end
end

-- Anti-Aim Fake Server Ghost Visualizer
local fakeCloneModel = nil
local fakeGhostFolder = nil
local fakeClonePartsMap = {}
local fakePosHistory = {}
local currentServerRot = nil
local currentServerPitch = 0

local function destroyFakeClone()
    if fakeCloneModel then
        pcall(function() fakeCloneModel:Destroy() end)
        fakeCloneModel = nil
    end
    if fakeGhostFolder then
        pcall(function() fakeGhostFolder:Destroy() end)
        fakeGhostFolder = nil
    end
    table.clear(fakeClonePartsMap)
    table.clear(fakePosHistory)
    currentServerRot = nil
    currentServerPitch = 0
end

local function getOrCreateFakeClone(char)
    if not char or not char.Parent then return nil end
    if fakeCloneModel and fakeCloneModel.Parent and #fakeCloneModel:GetChildren() > 0 then
        return fakeCloneModel
    end
    
    destroyFakeClone()
    
    local folder = Instance.new("Folder")
    ProtectInstance(folder)
    folder.Parent = SafeContainer or Workspace
    fakeGhostFolder = folder
    
    local clone = Instance.new("Model")
    ProtectInstance(clone)
    clone.Parent = folder
    
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name:lower() ~= "humanoidrootpart" and not part:FindFirstAncestorOfClass("Tool") and part.Name ~= "Convergence_VisualHead" then
            pcall(function()
                local ghostPart = Instance.new("Part")
                ProtectInstance(ghostPart)
                if part.Name:lower() == "head" then
                    ghostPart.Shape = Enum.PartType.Cylinder
                    ghostPart.Size = Vector3.new(part.Size.Y, part.Size.X * 1.08, part.Size.Z * 1.08)
                else
                    ghostPart.Size = part.Size
                end
                ghostPart.Anchored = true
                ghostPart.CanCollide = false
                ghostPart.CanTouch = false
                ghostPart.CanQuery = false
                ghostPart.Massless = true
                ghostPart.CastShadow = false
                ghostPart.LocalTransparencyModifier = 0
                ghostPart.Parent = clone
                
                fakeClonePartsMap[part] = ghostPart
            end)
        end
    end
    
    fakeCloneModel = clone
    return fakeCloneModel
end

local function updateFakeClone(dt)
    if _G.ConvergenceUnloaded or not Config.GunMods.AntiAim or not Config.GunMods.AAFake then
        if fakeCloneModel or fakeGhostFolder then destroyFakeClone() end
        return
    end
    
    local char = getLocalCharacter()
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not hum or hum.Health <= 0 or not hrp then
        if fakeCloneModel or fakeGhostFolder then destroyFakeClone() end
        return
    end
    
    local model = getOrCreateFakeClone(char)
    if not model then return end
    updateChamsBloom()
    
    local now = os.clock()
    table.insert(fakePosHistory, 1, { time = now, pos = hrp.Position })
    while #fakePosHistory > 0 and (now - fakePosHistory[#fakePosHistory].time) > 1.0 do
        table.remove(fakePosHistory)
    end
    
    local pingSeconds = 0.05
    pcall(function()
        local p = LocalPlayer:GetNetworkPing()
        if p and p > 0 then
            pingSeconds = p
        end
    end)
    
    local targetTime = now - pingSeconds
    local serverPosition = hrp.Position
    for _, entry in ipairs(fakePosHistory) do
        if entry.time <= targetTime then
            serverPosition = entry.pos
            break
        end
    end
    
    local mat = Enum.Material[Config.GunMods.AAFakeMaterial] or Enum.Material.Neon
    local col = Config.GunMods.AAFakeColor or Color3.fromRGB(255, 0, 255)
    local trans = math.clamp(Config.GunMods.AAFakeTransparency or 0.3, 0, 1)
    
    local cam = Workspace.CurrentCamera
    local camLook = cam and cam.CFrame.LookVector or Vector3.new(0, 0, -1)
    local baseAngle = math.atan2(-camLook.X, -camLook.Z)
    
    if Config.GunMods.AAAtTargets then
        local targetPos = getAABestTarget()
        if targetPos then
            local myPos = hrp.Position
            baseAngle = math.atan2(-(targetPos.X - myPos.X), -(targetPos.Z - myPos.Z))
        end
    end
    
    local serverTimestamp = targetTime
    local pRad, yRad = getAACalculatedAngles(false, serverTimestamp)
    
    -- Smooth server network rotation interpolation (mimics Roblox physics replication slerp/tweening)
    local targetRot = CFrame.Angles(0, baseAngle + yRad, 0)
    local delta = dt or 0.016
    local lerpAlpha = math.clamp(delta * 16, 0, 1)
    
    if not currentServerRot then
        currentServerRot = targetRot
        currentServerPitch = pRad
    else
        currentServerRot = currentServerRot:Lerp(targetRot, lerpAlpha)
        currentServerPitch = currentServerPitch + (pRad - currentServerPitch) * lerpAlpha
    end
    
    local serverHrpCFrame = CFrame.new(serverPosition) * currentServerRot
    local hrpCFrame = hrp.CFrame
    
        for realPart, ghostPart in pairs(fakeClonePartsMap) do
        if realPart and realPart.Parent and ghostPart and ghostPart.Parent then
            local relCF = hrpCFrame:ToObjectSpace(realPart.CFrame)
            if realPart.Name:lower() == "head" then
                ghostPart.CFrame = serverHrpCFrame * relCF * CFrame.Angles(currentServerPitch, 0, 0) * CFrame.Angles(0, 0, math.pi / 2)
            else
                ghostPart.CFrame = serverHrpCFrame * relCF
            end
            
            if ghostPart.Material ~= mat then ghostPart.Material = mat end
            if ghostPart.Color ~= col then ghostPart.Color = col end
            if ghostPart.Transparency ~= trans then ghostPart.Transparency = trans end
            ghostPart.LocalTransparencyModifier = 0
        end
    end
end

-- 2. RenderStepped: Visual Restoration & Camera Focus (Renders Local Anti-Aim & Pitch)
local function _restoreSafeHeadLocal()
    local isSafeHeadOn = Config.GunMods.SafeHead
    local isAAOn = Config.GunMods.AntiAim
    if not isSafeHeadOn and not isAAOn then return end
    
    local char = getLocalCharacter()
    if not char or not char.Parent then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead then return end
    
    local neck = findCharacterNeck(char)
    
    if isSafeHeadOn and not isAAOn then
        if neck and _safeHeadOriginalJoints[neck] then
            neck.C0 = _safeHeadOriginalJoints[neck]
        end
    elseif isAAOn then
        local pRad, _ = getAACalculatedAngles(true)
        if neck and neck.Parent and _safeHeadOriginalJoints[neck] then
            local baseNeckC0 = _safeHeadOriginalJoints[neck]
            neck.C0 = baseNeckC0 * CFrame.Angles(pRad, 0, 0)
            neck.Transform = CFrame.Angles(pRad, 0, 0)
        end
    end
    
    local cam = Workspace.CurrentCamera
    if cam and cam.CameraSubject ~= hum and hum.Health > 0 then
        cam.CameraSubject = hum
    end
    if hum then
        hum.CameraOffset = Vector3.new(0, 0, 0)
    end
end

_startSafeHead = function()
    if not Config.GunMods.SafeHead and not Config.GunMods.AntiAim then return end
    _safeHeadActive = true
    if not _safeHeadSteppedConn then
        _safeHeadSteppedConn = RunService.Stepped:Connect(_updateSafeHead)
    end
    if not _safeHeadRenderConn then
        _safeHeadRenderConn = RunService.RenderStepped:Connect(_restoreSafeHeadLocal)
    end
end

_stopSafeHead = function(force)
    if not force and (Config.GunMods.SafeHead or Config.GunMods.AntiAim) then
        if not Config.GunMods.SafeHead and Config.GunMods.AntiAim then
            local char = getLocalCharacter()
            local head = char and char:FindFirstChild("Head")
            if head then
                head.CanCollide = false
                head.Massless = false
                head.CanTouch = true
                head.CanQuery = true
            end
        end
        return
    end

    _safeHeadActive = false
    if _safeHeadSteppedConn then _safeHeadSteppedConn:Disconnect() _safeHeadSteppedConn = nil end
    if _safeHeadRenderConn then _safeHeadRenderConn:Disconnect() _safeHeadRenderConn = nil end
    pcall(function()
        local char = getLocalCharacter()
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.AutoRotate = true
                hum.CameraOffset = Vector3.new(0, 0, 0)
                local cam = Workspace.CurrentCamera
                if cam then cam.CameraSubject = hum end
            end
            local neck = findCharacterNeck(char)
            if neck and _safeHeadOriginalJoints[neck] then
                neck.C0 = _safeHeadOriginalJoints[neck]
                neck.Transform = CFrame.identity
            end
            local rootJoint = findCharacterRootJoint(char)
            if rootJoint and _safeHeadOriginalJoints[rootJoint] then
                rootJoint.C0 = _safeHeadOriginalJoints[rootJoint]
                rootJoint.Transform = CFrame.identity
            end
            local head = char:FindFirstChild("Head")
            if head then
                head.CanCollide = false
                head.Massless = false
                head.CanTouch = true
                head.CanQuery = true
            end
        end
    end)
    table.clear(_safeHeadOriginalJoints)
    pcall(destroyFakeClone)
end

setupCharacterSafeHead = function(character)
    if not character then return end
    _stopSafeHead()
    pcall(restoreLocalChams)
    lastSpawnTime = os.clock()
    
    local humanoid = character:WaitForChild("Humanoid", 5)
    if humanoid then
        table.insert(_characterConnections, humanoid.Died:Connect(function()
            _G.Reloading = false
            _stopSafeHead()
            cachedFireFunction = nil
            if Config.Misc.InstantRespawn then
                task.spawn(function()
                    task.wait(0.1)
                    local vim = game:GetService("VirtualInputManager")
                    vim:SendKeyEvent(true, Enum.KeyCode.X, false, game)
                    task.wait(0.05)
                    vim:SendKeyEvent(false, Enum.KeyCode.X, false, game)
                end)
            end
        end))
    end
    
    -- Grace period for server spawn teleport to settle cleanly
    task.delay(1.2, function()
        if (Config.GunMods.SafeHead or Config.GunMods.AntiAim) and humanoid and humanoid.Health > 0 then
            _startSafeHead()
        end
    end)
end

table.insert(ScriptConnections, LocalPlayer.CharacterAdded:Connect(function(character)
    _G.Reloading = false
    clearCharacterConnections()
    hasHookedHitPos = false
    cachedFireFunction = nil
    safeHookGunClosures(true)
    setupCharacterSafeHead(character)
    bindGunHooks(character)
end))

if LocalPlayer.Character then
    clearCharacterConnections()
    setupCharacterSafeHead(LocalPlayer.Character)
    bindGunHooks(LocalPlayer.Character)
end

table.insert(ScriptConnections, RunService.RenderStepped:Connect(function(dt)
    if _G.ConvergenceUnloaded then return end
    if Config.GunMods.AntiAim and Config.GunMods.AAFake then
        pcall(updateFakeClone, dt)
    else
        if fakeCloneModel then
            destroyFakeClone()
        end
    end
end))

table.insert(ScriptConnections, RunService.RenderStepped:Connect(function()
    if _G.ConvergenceUnloaded then return end
    if Config.ESP.LocalChams then
        pcall(updateLocalChams)
    elseif wasLocalChamsActive then
        pcall(restoreLocalChams)
    end
end))

-- In-Game Sprint Handler for Anti-Aim
local isShiftHeld = false
table.insert(ScriptConnections, UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and (input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift) then
        isShiftHeld = true
    end
end))

table.insert(ScriptConnections, UserInputService.InputEnded:Connect(function(input, gpe)
    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        isShiftHeld = false
        if Config.GunMods.AntiAim then
            _G.Sprinting = false
            local char = getLocalCharacter()
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 and hum.WalkSpeed > 16 then
                hum.WalkSpeed = 16
            end
        end
    end
end))

table.insert(ScriptConnections, RunService.Heartbeat:Connect(function()
    if _G.ConvergenceUnloaded then return end
    if Config.GunMods.AntiAim and isShiftHeld then
        local char = getLocalCharacter()
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 and hum.MoveDirection.Magnitude > 0.05 and not _G.Aiming and not _G.Reloading then
            _G.Sprinting = true
            if hum.WalkSpeed ~= 18 then
                hum.WalkSpeed = 18
            end
        else
            if hum and hum.Health > 0 and hum.MoveDirection.Magnitude <= 0.05 and hum.WalkSpeed > 16 then
                _G.Sprinting = false
                hum.WalkSpeed = 16
            end
        end
    end
end))


end

-- Crash Server / Map Spam & Custom Tracers System
local CrashAndSpam = {}
do
    local crashServerThread = nil
    local crashStatusText = nil
    local customSpawnSoundPool = {}
    local customSpawnSoundIndex = 1

    local function updateCrashStatusPos()
        if crashStatusText then
            local cam = Workspace.CurrentCamera
            if cam then
                local size = cam.ViewportSize
                crashStatusText.Position = Vector2.new(size.X / 2, size.Y / 2 + 90)
            end
        end
    end

    table.insert(ScriptConnections, RunService.RenderStepped:Connect(updateCrashStatusPos))

    function CrashAndSpam.showCrashStatus(text, color)
        if not crashStatusText then
            crashStatusText = Drawing.new("Text")
            crashStatusText.Size = 22
            crashStatusText.Font = 2
            crashStatusText.Center = true
            crashStatusText.Outline = true
            crashStatusText.OutlineColor = Color3.fromRGB(0, 0, 0)
            crashStatusText.ZIndex = 999
        end
        crashStatusText.Text = text
        crashStatusText.Color = color or Color3.fromRGB(255, 65, 65)
        crashStatusText.Visible = true
        updateCrashStatusPos()
    end

    function CrashAndSpam.hideCrashStatus()
        if crashStatusText then
            crashStatusText.Visible = false
        end
    end

    function CrashAndSpam.playCustomSpawnSound(soundId)
        soundId = soundId or 138857089980331
        local soundAsset = "rbxassetid://" .. tostring(soundId)
        local snd = customSpawnSoundPool[customSpawnSoundIndex]
        if not snd or not snd.Parent then
            snd = Instance.new("Sound")
            snd.Name = GetRandomSymbolString(14)
            snd.Volume = 1.5
            snd.PlaybackSpeed = 1
            snd.Parent = SoundService
            customSpawnSoundPool[customSpawnSoundIndex] = snd
        end
        snd.SoundId = soundAsset
        customSpawnSoundIndex = (customSpawnSoundIndex % 6) + 1
        snd.TimePosition = 0
        pcall(function() SoundService:PlayLocalSound(snd) end)
    end

    local function executeServerSpam()
        local char = LocalPlayer.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
        if not tool then
            local bp = LocalPlayer:FindFirstChild("Backpack")
            tool = bp and bp:FindFirstChildOfClass("Tool")
        end
        if not tool then return end
        local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
        if not handle then return end
        local fireSound = handle:FindFirstChild("FireSound") or handle:FindFirstChildWhichIsA("Sound")
        
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Miscs = ReplicatedStorage:FindFirstChild("Miscs")
        local VisualizeBullet = ReplicatedStorage:FindFirstChild("VisualizeBullet")
        local VisualizeMuzzle = ReplicatedStorage:FindFirstChild("VisualizeMuzzle")
        if not VisualizeBullet then return end
        
        local hitEffect = Miscs and Miscs:FindFirstChild("HitEffect")
        local bloodEffect = Miscs and Miscs:FindFirstChild("BloodEffect")
        local explosionEffect = Miscs and Miscs:FindFirstChild("ExplosionEffect")
        local tracerEffect = Miscs and Miscs:FindFirstChild("TracerEffect")
        local particleEffect = Miscs and Miscs:FindFirstChild("ParticleEffect")
        local muzzleEffect = Miscs and Miscs:FindFirstChild("MuzzleEffect")
        
        local meshId = 92333840956214
        local textureId = 83125944462609
        local defaultExplosionSounds = { 138857089980331, 186809061, 245630921, 269514869, 186809249 }
        local defaultHitSounds = { 186809061, 186809249, 186809250, 186809252 }
        local defaultBloodSounds = { 245630921, 245630994, 245631056, 245631112, 245631167 }
        local defaultWhizSounds = { 269514869, 269514887, 269514807, 269514817 }
        
        local now = tick()
        local players = Players:GetPlayers()
        for pIdx, player in ipairs(players) do
            if not (Config.Misc and Config.Misc.CrashServer) then break end
            local pChar = player.Character
            local root = pChar and (pChar:FindFirstChild("HumanoidRootPart") or pChar:FindFirstChild("Head") or pChar:FindFirstChild("Torso"))
            local pPos = root and root.Position
            if pPos then
                for i = 1, 10 do
                    if not (Config.Misc and Config.Misc.CrashServer) then break end
                    
                    local scaleMult = math.random(18, 35) * 0.1
                    local currentMeshScale = Vector3.new(4.521, 6.326, 4.686) * scaleMult
                    local strobeColor = Color3.fromHSV((now * 25 + (pIdx * 0.3) + (i * 0.1)) % 1, 1, 1)

                    local angle = math.random() * math.pi * 2
                    local dist = math.random(15, 60)
                    local heightOffset = (i % 2 == 0) and math.random(40, 100) or math.random(2, 25)
                    local spawnOrigin = pPos + Vector3.new(math.cos(angle) * dist, heightOffset, math.sin(angle) * dist)

                    local toPlayer = (pPos - spawnOrigin)
                    local dir = toPlayer.Magnitude > 0.01 and toPlayer.Unit or Vector3.new(0, -1, 0)
                    
                    local hitEffectTable = { true, defaultHitSounds, 1, 3, hitEffect, false }
                    local bloodTable = { true, defaultBloodSounds, 1, 3, bloodEffect }
                    local bulletHoleTable = { true, 20, { textureId }, false, 120, 5 }
                    local fleshHoleTable = { true, 20, { textureId }, Color3.fromRGB(255, 255, 255), 120, 5 }
                    local explosionTable = { true, 100, true, defaultExplosionSounds, math.random(8, 12) / 10, 5, false, explosionEffect }
                    local tracerTable = { true, Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), tracerEffect, true, particleEffect, 25000, 500, 0, Vector3.zero, Vector3.new(6, 6, 6), Color3.fromRGB(255, 255, 255), 0, Enum.Material.SmoothPlastic, Enum.PartType.Block, true, meshId, textureId, currentMeshScale }
                    local damageTable = { 100, 2.5, true, {} }
                    local whizTable = { true, defaultWhizSounds, 2, 1 }
                    local lightTable = { true, 5000, strobeColor, 200, false }
                    local effectTable = { 100, 100, true }
                    
                    pcall(function()
                        VisualizeBullet:FireServer(tool, handle, dir, spawnOrigin, hitEffectTable, bloodTable, bulletHoleTable, fleshHoleTable, explosionTable, tracerTable, damageTable, whizTable, lightTable, effectTable, fireSound, fireSound, nil, nil)
                    end)
                end
            end
        end

        if muzzleEffect and VisualizeMuzzle and Config.Misc and Config.Misc.CrashServer then
            local orangeMuzzle = Color3.fromRGB(255, 170, 0)
            pcall(function()
                VisualizeMuzzle:FireServer(handle, true, { true, 3000, orangeMuzzle, 15000, false, 0.4 }, muzzleEffect)
            end)
        end
    end

    function CrashAndSpam.startCrashServer()
        if crashServerThread then
            task.cancel(crashServerThread)
            crashServerThread = nil
        end
        crashServerThread = task.spawn(function()
            CrashAndSpam.showCrashStatus("Crash Server Active", Color3.fromRGB(255, 65, 65))
            while Config.Misc and Config.Misc.CrashServer and not _G.ConvergenceUnloaded do
                executeServerSpam()
                task.wait()
            end
            CrashAndSpam.hideCrashStatus()
        end)
    end

    function CrashAndSpam.stopCrashServer()
        if crashServerThread then
            task.cancel(crashServerThread)
            crashServerThread = nil
        end
        CrashAndSpam.hideCrashStatus()
    end

    function CrashAndSpam.stopAll()
        CrashAndSpam.hideCrashStatus()
        if crashStatusText then
            pcall(function() crashStatusText:Remove() end)
            crashStatusText = nil
        end
        if crashServerThread then task.cancel(crashServerThread) crashServerThread = nil end
    end
end

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                               USER INTERFACE                              ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

local function buildCombatTab()
    local CombatBox = Tabs.Combat:AddLeftGroupbox('Gun Mods')
    
    local function updateGunMods()
        task.spawn(function()
            applyGunMods()
        end)
    end
    
    local RapidFireToggle = CombatBox:AddToggle('RapidFire', {
        Text = 'Rapid Fire',
        Default = false,
        Callback = function(Value)
            Config.GunMods.RapidFire = Value
            updateGunMods()
        end
    })
    
    local function stopAllReloadAnimations()
        pcall(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local animator = hum and hum:FindFirstChildOfClass("Animator")
            if animator then
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                    local name = track.Name:lower()
                    local animId = (track.Animation and track.Animation.AnimationId) or ""
                    if name:find("reload") or animId:find("reload") then
                        track:Stop(0)
                    end
                end
            end
        end)
    end
    
    local function setupInstaReloadAnimCancel(character)
        if not character then return end
        local humanoid = character:WaitForChild("Humanoid", 5)
        local animator = humanoid and humanoid:WaitForChild("Animator", 5)
        if animator then
            table.insert(ScriptConnections, animator.AnimationPlayed:Connect(function(track)
                if Config.GunMods.InstaReload then
                    local name = track.Name:lower()
                    local animId = (track.Animation and track.Animation.AnimationId) or ""
                    if name:find("reload") or animId:find("reload") then
                        track:Stop(0)
                    end
                end
            end))
        end
    end
    
    if LocalPlayer.Character then setupInstaReloadAnimCancel(LocalPlayer.Character) end
    table.insert(ScriptConnections, LocalPlayer.CharacterAdded:Connect(setupInstaReloadAnimCancel))
    
    local InstaReloadToggle = CombatBox:AddToggle('InstaReload', {
        Text = 'Instant Reload',
        Default = false,
        Callback = function(Value)
            Config.GunMods.InstaReload = Value
            updateGunMods()
            if Value then
                stopAllReloadAnimations()
            end
        end
    })
    
    revertInfAmmo = function()
        task.spawn(function()
            task.wait(0.25)
            local baseMag = 30
            if originalGunMods then
                for _, cachedData in pairs(originalGunMods) do
                    if cachedData.MaxAmmo and cachedData.MaxAmmo < 50000 and cachedData.MaxAmmo >= (cachedData.AmmoPerMag or 0) then
                        baseMag = cachedData.MaxAmmo
                        break
                    elseif cachedData.AmmoPerMag and cachedData.AmmoPerMag < 50000 then
                        baseMag = cachedData.AmmoPerMag
                        break
                    end
                end
            end
            
            if _G.gunGUIUpvalues then
                for guiFunc, magIdx in pairs(_G.gunGUIUpvalues) do
                    pcall(function()
                        local mag = select(2, debug.getupvalue(guiFunc, magIdx))
                        local isTable = type(mag) == "table"
                        local isValueBase = typeof(mag) == "Instance" and mag:IsA("ValueBase")
                        local magNum = type(mag) == "number" and mag or (isTable and mag.Value) or (isValueBase and mag.Value) or nil
                        
                        if magNum and magNum > 500 then
                            if isTable then
                                mag.Value = baseMag
                            elseif isValueBase then
                                mag.Value = baseMag
                            else
                                debug.setupvalue(guiFunc, magIdx, baseMag)
                            end
                            task.spawn(guiFunc)
                        end
                    end)
                end
            end
    
            for _, fn in ipairs(getgc()) do
                if type(fn) == "function" and islclosure(fn) then
                    local ok, info = pcall(debug.getinfo, fn)
                    if ok and type(info.source) == "string" and info.source:find("GunClientModule") then
                        for i, _ in pairs(debug.getupvalues(fn)) do
                            local val = debug.getupvalue(fn, i)
                            if type(val) == "number" and val > 50000 and val <= 100000 then
                                debug.setupvalue(fn, i, baseMag)
                            elseif type(val) == "table" then
                                for k, v in pairs(val) do
                                    if type(v) == "number" and v > 50000 and v <= 100000 then
                                        val[k] = baseMag
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
    
    local InfAmmoToggle = CombatBox:AddToggle('InfAmmo', {
        Text = 'Infinite Ammo',
        Default = false,
        Callback = function(Value)
            Config.GunMods.InfAmmo = Value
            updateGunMods()
            
            if Value then
                task.spawn(function()
                    task.wait(0.25)
                    local vim = game:GetService("VirtualInputManager")
                    vim:SendKeyEvent(true, Enum.KeyCode.R, false, game)
                    task.wait(0.1)
                    vim:SendKeyEvent(false, Enum.KeyCode.R, false, game)
                end)
            end
            
            if not Value then
                revertInfAmmo()
            end
        end
    })
    
    local RecoilToggle = CombatBox:AddToggle('NoRecoil', {
        Text = 'Modify Recoil',
        Default = false,
        Callback = function(Value)
            Config.GunMods.NoRecoil = Value
            updateGunMods()
        end
    })
    
    local RecoilDepbox = CombatBox:AddDependencyBox()
    RecoilDepbox:SetupDependencies({
        { Toggles.NoRecoil, true }
    })
    
    RecoilDepbox:AddSlider('RecoilVert', {
        Text = 'Vertical',
        Default = 1,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Callback = function(Value)
            Config.GunMods.RecoilVert = Value
            updateGunMods()
        end
    })
    RecoilDepbox:AddSlider('RecoilHoriz', {
        Text = 'Horizontal',
        Default = 1,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Callback = function(Value)
            Config.GunMods.RecoilHoriz = Value
            updateGunMods()
        end
    })
    
    local SpreadToggle = CombatBox:AddToggle('NoSpread', {
        Text = 'Modify Spread',
        Default = false,
        Callback = function(Value)
            Config.GunMods.NoSpread = Value
            updateGunMods()
        end
    })
    
    local SpreadDepbox = CombatBox:AddDependencyBox()
    SpreadDepbox:SetupDependencies({
        { Toggles.NoSpread, true }
    })
    
    SpreadDepbox:AddSlider('SpreadMult', {
        Text = 'Multiplier',
        Default = 1,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Callback = function(Value)
            Config.GunMods.SpreadMult = Value
            updateGunMods()
        end
    })
    
    local AimBox = Tabs.Combat:AddRightGroupbox('Ragebot')
    AimBox:AddToggle('SilentAim', {
        Text = 'Enabled',
        Default = false,
        Callback = function(Value)
            Config.GunMods.SilentAim = Value
        end
    })
    AimBox:AddToggle('AutoShoot', {
        Text = 'Auto Shoot',
        Default = false,
        Risky = true,
        Callback = function(Value)
            Config.GunMods.AutoShoot = Value
        end
    })
    AimBox:AddToggle('WallCheck', {
        Text = 'Wall Check',
        Default = false,
        Callback = function(Value)
            Config.GunMods.WallCheck = Value
        end
    })
    AimBox:AddToggle('ShowFOV', {
        Text = 'Show FOV',
        Default = false,
        Callback = function(Value)
            Config.GunMods.ShowFOV = Value
        end
    })
    AimBox:AddToggle('Hitlogs', {
        Text = 'Hitlogs',
        Default = false,
        Callback = function(Value)
            Config.Misc.Hitlogs = Value
        end
    })
    AimBox:AddSlider('AimFOV', {
        Text = 'FOV',
        Default = 15,
        Min = 1,
        Max = 360,
        Rounding = 0,
        Suffix = "°",
        Compact = false,
        Callback = function(Value)
            Config.GunMods.AimFOV = Value
        end
    })
    
    -- Backtrack below Show FOV
    AimBox:AddToggle('Backtrack', {
        Text = 'Backtrack',
        Default = false,
        Callback = function(Value)
            Config.Misc.Backtrack = Value
            if not Value then
                clearAllGhostAdornments()
            end
        end
    })
    
    local BTDepbox = AimBox:AddDependencyBox()
    BTDepbox:SetupDependencies({
        { Toggles.Backtrack, true }
    })
    
    BTDepbox:AddSlider('BacktrackTime', {
        Text = 'Time',
        Default = 200,
        Min = 1,
        Max = 1000,
        Rounding = 0,
        Suffix = 'ms',
        Callback = function(Value)
            Config.Misc.BacktrackTime = Value
        end
    })
    
    BTDepbox:AddToggle('BacktrackGhost', {
        Text = 'Visualize Ghost',
        Default = false,
        Callback = function(Value)
            Config.Misc.BacktrackGhost = Value
            if not Value then
                clearAllGhostAdornments()
            end
        end
    }):AddColorPicker('BacktrackGhostColor', {
        Default = Color3.fromRGB(180, 180, 255),
        Title = 'Ghost Color',
        Transparency = 0.25,
        Callback = function(Value)
            Config.Misc.BacktrackColor = Value
            Config.Misc.BacktrackTransparency = (Options.BacktrackGhostColor and Options.BacktrackGhostColor.Transparency) or 0.25
        end
    })
    
    local function executeKillAll()
        local count = 0
        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if not tool then return false end
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and not (Config.ESP.TeamCheck and isTeammate(player)) then
                local char = player.Character
                if not char or not char.Parent then
                    local charsFolder = Workspace:FindFirstChild("Characters")
                    char = charsFolder and charsFolder:FindFirstChild(player.Name)
                end
                if not char or not char.Parent then
                    char = Workspace:FindFirstChild(player.Name)
                end
                
                local hum = char and (char:FindFirstChildOfClass("Humanoid") or char:FindFirstChild("Humanoid", true))
                if hum and hum.Health > 0 then
                    if killTargetPerson(char, hum) then
                        count = count + 1
                        task.wait(0.02)
                    end
                end
            end
        end
        
        -- Also support target dummies/NPCs
        for _, targetInfo in ipairs(getAllTargets()) do
            if not targetInfo.IsPlayer or not (Config.ESP.TeamCheck and isTeammate(targetInfo.Player)) then
                local char = targetInfo.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    if killTargetPerson(char, hum) then
                        count = count + 1
                        task.wait(0.02)
                    end
                end
            end
        end
        return count > 0
    end
    
    task.spawn(function()
        while task.wait(0.1) do
            if Config.GunMods.LoopKill then
                executeKillAll()
            end
        end
    end)
    
    local KillAllButton = AimBox:AddButton({
        Text = 'Kill All',
        Func = function()
            executeKillAll()
        end
    })
    
    if KillAllButton.Label then
        Library:RemoveFromRegistry(KillAllButton.Label)
        KillAllButton.Label.TextColor3 = Color3.fromRGB(255, 50, 50)
    end
    
    local LoopKillToggle = AimBox:AddToggle('LoopKill', {
        Text = 'Loop Kill',
        Default = false,
        Callback = function(Value)
            Config.GunMods.LoopKill = Value
        end
    })
    
    -- Divider below Loop Kill
    AimBox:AddDivider()
    
    local SafeHeadToggle = AimBox:AddToggle('SafeHead', {
        Text = 'Safe Head',
        Default = false,
        Callback = function(Value)
            Config.GunMods.SafeHead = Value
            if Value then
                _startSafeHead()
            else
                _stopSafeHead()
            end
        end
    })

    local AntiAimToggle = AimBox:AddToggle('AntiAim', {
        Text = 'Anti-Aim',
        Default = false,
        Callback = function(Value)
            Config.GunMods.AntiAim = Value
            if Value then
                _startSafeHead()
            else
                _stopSafeHead()
            end
        end
    })

    local AntiAimDepbox = AimBox:AddDependencyBox()
    AntiAimDepbox:SetupDependencies({
        { Toggles.AntiAim, true }
    })

    AntiAimDepbox:AddToggle('AAAtTargets', {
        Text = 'At Targets',
        Default = false,
        Callback = function(Value)
            Config.GunMods.AAAtTargets = Value
        end
    })

    AntiAimDepbox:AddSlider('AAPitch', {
        Text = 'Pitch Angle',
        Default = 0,
        Min = -89,
        Max = 89,
        Rounding = 0,
        Suffix = "°",
        Callback = function(Value)
            Config.GunMods.AAPitch = Value
        end
    })

    AntiAimDepbox:AddSlider('AAYaw', {
        Text = 'Yaw Offset',
        Default = 0,
        Min = -180,
        Max = 180,
        Rounding = 0,
        Suffix = "°",
        Callback = function(Value)
            Config.GunMods.AAYaw = Value
        end
    })

    AntiAimDepbox:AddToggle('AAJitter', {
        Text = 'Jitter',
        Default = false,
        Callback = function(Value)
            Config.GunMods.AAJitter = Value
        end
    })

    local JitterDepbox = AntiAimDepbox:AddDependencyBox()
    JitterDepbox:SetupDependencies({
        { Toggles.AAJitter, true }
    })

    JitterDepbox:AddSlider('AAJitterSpeed', {
        Text = 'Jitter Speed',
        Default = 5,
        Min = 1,
        Max = 10,
        Rounding = 0,
        Callback = function(Value)
            Config.GunMods.AAJitterSpeed = Value
        end
    })

    JitterDepbox:AddSlider('AAJitterOffset', {
        Text = 'Jitter Angle',
        Default = 45,
        Min = 5,
        Max = 90,
        Rounding = 0,
        Suffix = "°",
        Callback = function(Value)
            Config.GunMods.AAJitterOffset = Value
        end
    })

    AntiAimDepbox:AddToggle('AAFake', {
        Text = 'Show Server Fake Ghost',
        Default = false,
        Callback = function(Value)
            Config.GunMods.AAFake = Value
        end
    }):AddColorPicker('AAFakeColor', {
        Default = Color3.fromRGB(255, 0, 255),
        Title = 'Ghost Color',
        Transparency = 0.3,
        Callback = function(Value)
            Config.GunMods.AAFakeColor = Value
            Config.GunMods.AAFakeTransparency = (Options.AAFakeColor and Options.AAFakeColor.Transparency) or 0.3
        end
    })

    for _, child in ipairs(AimBox.Container:GetDescendants()) do
        if child:IsA("TextLabel") and (child.Text == "Loop Kill" or child.Text == "Auto Shoot" or child.Text == "Safe Head" or child.Text == "Anti-Aim" or child.Text == "Backtrack") then
            Library:RemoveFromRegistry(child)
            child.TextColor3 = Color3.fromRGB(255, 50, 50)
        end
    end
end
buildCombatTab()

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                         CUSTOM ESP / VIEWPORT PREVIEW                     ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

local PreviewSettings = {
    CameraX = 0.0,
    CameraY = -0.39,
    CameraZ = 7.0,
    CameraPitch = 0,
    CameraYaw = 0,
    ModelY = 0.0,
    FOV = 61,
    BoxPaddingX = 4,
    BoxPaddingY = 4,
    AutoRotate = true
}

local function addESPPreviewToGroupbox(groupbox, options)
    options = options or {}
    local previewHeight = options.Height or 230
    local container = groupbox.Container
    
    local function randomName()
        if GetRandomSymbolString then
            return GetRandomSymbolString(math.random(14, 22))
        end
        return "Inst_" .. math.random(100000, 999999)
    end
    
    local previewContainer = Instance.new("Frame")
    previewContainer.Name = randomName()
    previewContainer.BackgroundTransparency = 1
    previewContainer.BorderSizePixel = 0
    previewContainer.Size = UDim2.new(1, -2, 0, previewHeight)
    previewContainer.Position = UDim2.new(0, 1, 0, 0)
    previewContainer.ClipsDescendants = true
    previewContainer.ZIndex = 5
    if ProtectInstance then ProtectInstance(previewContainer) end
    previewContainer.Parent = container

    -- 3D ViewportFrame
    local viewport = Instance.new("ViewportFrame")
    viewport.Name = randomName()
    viewport.Size = UDim2.new(1, 0, 1, 0)
    viewport.BackgroundTransparency = 1
    viewport.Ambient = Color3.fromRGB(185, 185, 200)
    viewport.LightColor = Color3.fromRGB(245, 245, 255)
    viewport.LightDirection = Vector3.new(-1, -1.5, -2)
    viewport.ZIndex = 6
    if ProtectInstance then ProtectInstance(viewport) end
    viewport.Parent = previewContainer

    local vpCamera = Instance.new("Camera")
    vpCamera.Name = randomName()
    vpCamera.FieldOfView = PreviewSettings.FOV
    if ProtectInstance then ProtectInstance(vpCamera) end
    vpCamera.Parent = viewport
    viewport.CurrentCamera = vpCamera

    local worldModel = Instance.new("WorldModel")
    worldModel.Name = randomName()
    if ProtectInstance then ProtectInstance(worldModel) end
    worldModel.Parent = viewport

    -- 2D ESP Overlay Container
    local overlayContainer = Instance.new("Frame")
    overlayContainer.Name = randomName()
    overlayContainer.Size = UDim2.new(1, 0, 1, 0)
    overlayContainer.BackgroundTransparency = 1
    overlayContainer.ZIndex = 10
    if ProtectInstance then ProtectInstance(overlayContainer) end
    overlayContainer.Parent = previewContainer

    -- Bounding Box using UIStroke & Outlines
    local boxOuter = Instance.new("Frame")
    boxOuter.Name = randomName()
    boxOuter.BackgroundTransparency = 1
    boxOuter.BorderSizePixel = 0
    boxOuter.ZIndex = 10
    boxOuter.Visible = false
    if ProtectInstance then ProtectInstance(boxOuter) end
    boxOuter.Parent = overlayContainer

    local boxMainStroke = Instance.new("UIStroke")
    boxMainStroke.Name = randomName()
    boxMainStroke.Thickness = 1.5
    boxMainStroke.Color = Color3.fromRGB(255, 255, 255)
    boxMainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    boxMainStroke.Transparency = 0
    if ProtectInstance then ProtectInstance(boxMainStroke) end
    boxMainStroke.Parent = boxOuter

    local boxShadow = Instance.new("Frame")
    boxShadow.Name = randomName()
    boxShadow.BackgroundTransparency = 1
    boxShadow.Position = UDim2.new(0, -1, 0, -1)
    boxShadow.Size = UDim2.new(1, 2, 1, 2)
    boxShadow.ZIndex = 9
    if ProtectInstance then ProtectInstance(boxShadow) end
    boxShadow.Parent = boxOuter

    local boxShadowStroke = Instance.new("UIStroke")
    boxShadowStroke.Name = randomName()
    boxShadowStroke.Thickness = 1
    boxShadowStroke.Color = Color3.fromRGB(0, 0, 0)
    boxShadowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    boxShadowStroke.Transparency = 0.2
    if ProtectInstance then ProtectInstance(boxShadowStroke) end
    boxShadowStroke.Parent = boxShadow

    -- Name Label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = randomName()
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Library.Font or Enum.Font.Code
    nameLabel.TextSize = 13
    nameLabel.Text = "KittyWare"
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.ZIndex = 14
    nameLabel.Visible = false
    if ProtectInstance then ProtectInstance(nameLabel) end
    nameLabel.Parent = overlayContainer

    -- Health Bar Container
    local healthBarOuter = Instance.new("Frame")
    healthBarOuter.Name = randomName()
    healthBarOuter.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    healthBarOuter.BorderSizePixel = 1
    healthBarOuter.BorderColor3 = Color3.fromRGB(0, 0, 0)
    healthBarOuter.ZIndex = 10
    healthBarOuter.Visible = false
    if ProtectInstance then ProtectInstance(healthBarOuter) end
    healthBarOuter.Parent = overlayContainer

    local healthBarInner = Instance.new("Frame")
    healthBarInner.Name = randomName()
    healthBarInner.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    healthBarInner.BorderSizePixel = 0
    healthBarInner.Size = UDim2.new(1, 0, 1, 0)
    healthBarInner.ZIndex = 11
    if ProtectInstance then ProtectInstance(healthBarInner) end
    healthBarInner.Parent = healthBarOuter

    local healthBarFill = Instance.new("Frame")
    healthBarFill.Name = randomName()
    healthBarFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthBarFill.BorderSizePixel = 0
    healthBarFill.Size = UDim2.new(1, 0, 1, 0)
    healthBarFill.Position = UDim2.new(0, 0, 0, 0)
    healthBarFill.ZIndex = 12
    if ProtectInstance then ProtectInstance(healthBarFill) end
    healthBarFill.Parent = healthBarInner

    -- Flags Container
    local flagsList = Instance.new("Frame")
    flagsList.Name = randomName()
    flagsList.BackgroundTransparency = 1
    flagsList.Size = UDim2.new(0, 80, 0, 60)
    flagsList.ZIndex = 14
    flagsList.Visible = false
    if ProtectInstance then ProtectInstance(flagsList) end
    flagsList.Parent = overlayContainer

    local flagLayout = Instance.new("UIListLayout")
    flagLayout.Name = randomName()
    flagLayout.SortOrder = Enum.SortOrder.LayoutOrder
    flagLayout.Padding = UDim.new(0, 2)
    flagLayout.Parent = flagsList

    local function createFlagLabel(text, color)
        local lbl = Instance.new("TextLabel")
        lbl.Name = randomName()
        lbl.BackgroundTransparency = 1
        lbl.Font = Library.Font or Enum.Font.Code
        lbl.TextSize = 10
        lbl.Text = text
        lbl.TextColor3 = color or Color3.fromRGB(255, 255, 255)
        lbl.TextStrokeTransparency = 0
        lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Size = UDim2.new(1, 0, 0, 11)
        lbl.ZIndex = 14
        if ProtectInstance then ProtectInstance(lbl) end
        lbl.Parent = flagsList
        return lbl
    end

    local flagSafeHead = createFlagLabel("Safe Head", Color3.fromRGB(255, 50, 50))
    local flagReloading = createFlagLabel("Reloading", Color3.fromRGB(0, 255, 255))

    -- Clean Neutral Default R6 Character Rig
    local currentModel = nil
    local bodyParts = {}
    local boxAdornments = {}
    local currentYaw = 0
    local isDragging = false
    local lastMouseX = 0

    local function buildCleanR6Rig()
        if currentModel then
            pcall(function() currentModel:Destroy() end)
            currentModel = nil
            table.clear(bodyParts)
            table.clear(boxAdornments)
        end

        local model = Instance.new("Model")
        model.Name = randomName()
        if ProtectInstance then ProtectInstance(model) end

        local humanoid = Instance.new("Humanoid")
        humanoid.Name = randomName()
        humanoid.RigType = Enum.HumanoidRigType.R6
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        if ProtectInstance then ProtectInstance(humanoid) end
        humanoid.Parent = model

        local function createR6Part(name, size, cframe, isHead)
            local p = Instance.new("Part")
            p.Name = name
            p.Size = size
            p.CFrame = cframe
            p.Anchored = true
            p.CanCollide = false
            p.CanTouch = false
            p.CanQuery = false
            p.CastShadow = false
            p.Material = Enum.Material.SmoothPlastic
            p.Color = Color3.fromRGB(210, 210, 215)
            if ProtectInstance then ProtectInstance(p) end

            if isHead then
                local mesh = Instance.new("SpecialMesh")
                mesh.Name = randomName()
                mesh.MeshType = Enum.MeshType.Head
                mesh.Scale = Vector3.new(1.25, 1.25, 1.25)
                if ProtectInstance then ProtectInstance(mesh) end
                mesh.Parent = p

                local face = Instance.new("Decal")
                face.Name = "face"
                face.Texture = "rbxasset://textures/face.png"
                face.Face = Enum.NormalId.Front
                if ProtectInstance then ProtectInstance(face) end
                face.Parent = p
            end

            p.Parent = model
            bodyParts[name] = p

            -- Cylinder Adornment for Head, Box Adornment for Limbs
            local adorn = Instance.new("Part")
            adorn.Name = randomName()
            adorn.Anchored = true
            adorn.CanCollide = false
            adorn.CanTouch = false
            adorn.CanQuery = false
            adorn.CastShadow = false
            adorn.Material = Enum.Material.SmoothPlastic
            adorn.Color = Config.ESP.PlayerChamsColor or Color3.fromRGB(255, 0, 128)
            adorn.Transparency = 1
            if ProtectInstance then ProtectInstance(adorn) end

            if isHead then
                -- CylinderHandleAdornment equivalent in 3D (standing vertical cylinder)
                adorn.Size = Vector3.new(1.22, 1.25, 1.25)
                adorn.CFrame = cframe * CFrame.Angles(0, 0, math.rad(90))
                local cylMesh = Instance.new("SpecialMesh")
                cylMesh.Name = randomName()
                cylMesh.MeshType = Enum.MeshType.Cylinder
                cylMesh.Scale = Vector3.new(1.0, 1.0, 1.0)
                if ProtectInstance then ProtectInstance(cylMesh) end
                cylMesh.Parent = adorn
            else
                adorn.Size = size + Vector3.new(0.04, 0.04, 0.04)
                adorn.CFrame = cframe
            end

            adorn.Parent = model
            boxAdornments[name] = adorn

            return p
        end

        local root = createR6Part("HumanoidRootPart", Vector3.new(2, 2, 1), CFrame.new(0, 0, 0), false)
        root.Transparency = 1
        model.PrimaryPart = root

        createR6Part("Torso", Vector3.new(2, 2, 1), CFrame.new(0, 0, 0), false)
        createR6Part("Head", Vector3.new(2, 1, 1), CFrame.new(0, 1.5, 0), true)
        createR6Part("Left Arm", Vector3.new(1, 2, 1), CFrame.new(-1.5, 0, 0), false)
        createR6Part("Right Arm", Vector3.new(1, 2, 1), CFrame.new(1.5, 0, 0), false)
        createR6Part("Left Leg", Vector3.new(1, 2, 1), CFrame.new(-0.5, -2, 0), false)
        createR6Part("Right Leg", Vector3.new(1, 2, 1), CFrame.new(0.5, -2, 0), false)

        -- Apply Local Character's Appearance (BodyColors, Shirt, Pants, Face)
        local localChar = LocalPlayer.Character
        if localChar then
            local bc = localChar:FindFirstChildOfClass("BodyColors")
            if bc then
                if bodyParts["Head"] then bodyParts["Head"].Color = bc.HeadColor3 end
                if bodyParts["Torso"] then bodyParts["Torso"].Color = bc.TorsoColor3 end
                if bodyParts["Left Arm"] then bodyParts["Left Arm"].Color = bc.LeftArmColor3 end
                if bodyParts["Right Arm"] then bodyParts["Right Arm"].Color = bc.RightArmColor3 end
                if bodyParts["Left Leg"] then bodyParts["Left Leg"].Color = bc.LeftLegColor3 end
                if bodyParts["Right Leg"] then bodyParts["Right Leg"].Color = bc.RightLegColor3 end
            end

            local shirt = localChar:FindFirstChildOfClass("Shirt")
            if shirt then
                local sClone = shirt:Clone()
                if ProtectInstance then ProtectInstance(sClone) end
                sClone.Parent = model
            end

            local pants = localChar:FindFirstChildOfClass("Pants")
            if pants then
                local pClone = pants:Clone()
                if ProtectInstance then ProtectInstance(pClone) end
                pClone.Parent = model
            end

            local liveHead = localChar:FindFirstChild("Head")
            if liveHead and bodyParts["Head"] then
                local liveFace = liveHead:FindFirstChildOfClass("Decal")
                local targetFace = bodyParts["Head"]:FindFirstChild("face")
                if liveFace and targetFace then
                    targetFace.Texture = liveFace.Texture
                end
            end
        end

        model.Parent = worldModel
        currentModel = model
    end

    buildCleanR6Rig()
    table.insert(ScriptConnections, LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.6)
        buildCleanR6Rig()
    end))

    -- Interactive drag to rotate
    previewContainer.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            lastMouseX = input.Position.X
        end
    end)

    table.insert(ScriptConnections, UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local deltaX = input.Position.X - lastMouseX
            lastMouseX = input.Position.X
            currentYaw = currentYaw - deltaX * 0.015
        end
    end))

    table.insert(ScriptConnections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end))

    -- Mathematical 3D-to-2D Viewport Projection
    local function projectToViewport(worldPos, camCF, fovDeg, vpSize)
        local rel = camCF:PointToObjectSpace(worldPos)
        local z = -rel.Z
        if z <= 0.05 then return nil end
        
        local fovRad = math.rad(fovDeg)
        local halfHeight = math.tan(fovRad / 2) * z
        local halfWidth = halfHeight * (vpSize.X / math.max(1, vpSize.Y))
        
        local normX = (rel.X / halfWidth) * 0.5 + 0.5
        local normY = (-rel.Y / halfHeight) * 0.5 + 0.5
        
        local px = normX * vpSize.X
        local py = normY * vpSize.Y
        
        return Vector2.new(px, py)
    end

    -- Render Loop for Realtime ESP & Adornment Chams Preview
    table.insert(ScriptConnections, RunService.RenderStepped:Connect(function(dt)
        if _G.ConvergenceUnloaded then return end
        if not previewContainer or not previewContainer.Parent then return end

        if PreviewSettings.AutoRotate and not isDragging then
            currentYaw = (currentYaw + dt * 0.8) % (math.pi * 2)
        end

        local vpSize = viewport.AbsoluteSize
        if vpSize.X <= 0 or vpSize.Y <= 0 then return end

        -- Pure translation camera CFrame (decoupled from target)
        vpCamera.FieldOfView = PreviewSettings.FOV
        local baseCamRotation = CFrame.Angles(math.rad(PreviewSettings.CameraPitch), math.rad(PreviewSettings.CameraYaw), 0)
        local camCFrame = CFrame.new(PreviewSettings.CameraX, PreviewSettings.CameraY, PreviewSettings.CameraZ) * baseCamRotation
        vpCamera.CFrame = camCFrame

        if currentModel then
            -- Update Player Chams Adornments
            for name, part in pairs(bodyParts) do
                local adorn = boxAdornments[name]
                if part and part.Parent then
                    if Config.ESP.PlayerChams then
                        if adorn then
                            adorn.Color = Config.ESP.PlayerChamsColor or Color3.fromRGB(255, 0, 128)
                            adorn.Transparency = Config.ESP.PlayerChamsTransparency or 0.5
                        end
                    else
                        if adorn then
                            adorn.Transparency = 1
                        end
                    end
                end
            end

            -- Neutral Upright Positioning & Rotation (Facing front towards camera)
            local rotCF = CFrame.Angles(0, currentYaw + math.pi, 0)
            local rootPos = Vector3.new(0, PreviewSettings.ModelY, 0)

            local baseOffsets = {
                ["HumanoidRootPart"] = CFrame.new(0, 0, 0),
                ["Torso"] = CFrame.new(0, 0, 0),
                ["Head"] = CFrame.new(0, 1.5, 0),
                ["Left Arm"] = CFrame.new(-1.5, 0, 0),
                ["Right Arm"] = CFrame.new(1.5, 0, 0),
                ["Left Leg"] = CFrame.new(-0.5, -2, 0),
                ["Right Leg"] = CFrame.new(0.5, -2, 0),
            }

            for name, part in pairs(bodyParts) do
                local baseOffset = baseOffsets[name] or CFrame.new(0, 0, 0)
                local partCF = CFrame.new(rootPos) * rotCF * baseOffset
                part.CFrame = partCF
                if boxAdornments[name] then
                    if name == "Head" then
                        -- Cylinder stands vertically
                        boxAdornments[name].CFrame = partCF * CFrame.Angles(0, 0, math.rad(90))
                    else
                        boxAdornments[name].CFrame = partCF
                    end
                end
            end

            -- Exact 3D-to-2D Bounding Box Calculation
            local minX, minY = math.huge, math.huge
            local maxX, maxY = -math.huge, -math.huge
            local hasPoints = false

            for name, part in pairs(bodyParts) do
                if name ~= "HumanoidRootPart" and part.Transparency < 1 then
                    local cf = part.CFrame
                    local sz = part.Size * 0.5
                    local corners = {
                        cf * Vector3.new(-sz.X, -sz.Y, -sz.Z),
                        cf * Vector3.new(-sz.X, -sz.Y,  sz.Z),
                        cf * Vector3.new(-sz.X,  sz.Y, -sz.Z),
                        cf * Vector3.new(-sz.X,  sz.Y,  sz.Z),
                        cf * Vector3.new( sz.X, -sz.Y, -sz.Z),
                        cf * Vector3.new( sz.X, -sz.Y,  sz.Z),
                        cf * Vector3.new( sz.X,  sz.Y, -sz.Z),
                        cf * Vector3.new( sz.X,  sz.Y,  sz.Z),
                    }
                    for _, corner in ipairs(corners) do
                        local sPos = projectToViewport(corner, camCFrame, PreviewSettings.FOV, vpSize)
                        if sPos then
                            minX = math.min(minX, sPos.X)
                            minY = math.min(minY, sPos.Y)
                            maxX = math.max(maxX, sPos.X)
                            maxY = math.max(maxY, sPos.Y)
                            hasPoints = true
                        end
                    end
                end
            end

            if hasPoints then
                local padX = PreviewSettings.BoxPaddingX
                local padY = PreviewSettings.BoxPaddingY

                minX = math.clamp(minX - padX, 2, vpSize.X - 10)
                maxX = math.clamp(maxX + padX, 10, vpSize.X - 2)
                minY = math.clamp(minY - padY, 2, vpSize.Y - 10)
                maxY = math.clamp(maxY + padY, 10, vpSize.Y - 2)

                local boxWidth = math.max(10, maxX - minX)
                local boxHeight = math.max(14, maxY - minY)

                -- Update 2D Box ESP
                boxOuter.Visible = (Config.ESP.Boxes == true)
                boxOuter.Position = UDim2.fromOffset(math.floor(minX), math.floor(minY))
                boxOuter.Size = UDim2.fromOffset(math.floor(boxWidth), math.floor(boxHeight))
                boxMainStroke.Color = Config.ESP.Color or Color3.fromRGB(255, 255, 255)
                boxMainStroke.Transparency = Config.ESP.BoxTransparency or 0

                -- Update Name (Tag)
                nameLabel.Visible = (Config.ESP.Names == true)
                nameLabel.Text = "KittyWare"
                nameLabel.TextColor3 = Config.ESP.NameColor or Color3.fromRGB(255, 255, 255)
                nameLabel.TextStrokeTransparency = Config.ESP.NameTransparency or 0
                nameLabel.Position = UDim2.fromOffset(math.floor(minX + (boxWidth / 2) - 50), math.floor(minY - 16))
                nameLabel.Size = UDim2.fromOffset(100, 14)

                -- Update Health Bar
                healthBarOuter.Visible = (Config.ESP.Health == true)
                healthBarOuter.Position = UDim2.fromOffset(math.floor(minX - 6), math.floor(minY - 1))
                healthBarOuter.Size = UDim2.fromOffset(4, math.floor(boxHeight + 2))
                healthBarFill.BackgroundColor3 = Config.ESP.HealthColor or Color3.fromRGB(0, 255, 0)
                healthBarFill.BackgroundTransparency = Config.ESP.HealthTransparency or 0

                -- Update Flags (Safe Head & Reloading)
                flagsList.Visible = (Config.ESP.Flags == true)
                flagsList.Position = UDim2.fromOffset(math.floor(maxX + 4), math.floor(minY))
                flagSafeHead.TextStrokeTransparency = Config.ESP.FlagsTransparency or 0
                flagReloading.TextStrokeTransparency = Config.ESP.FlagsTransparency or 0
            else
                boxOuter.Visible = false
                nameLabel.Visible = false
                healthBarOuter.Visible = false
                flagsList.Visible = false
            end
        end
    end))

    groupbox:AddBlank(5)
    groupbox:Resize()

    return {
        ResetAngle = function()
            currentYaw = 0
        end,
        Refresh = function()
            buildCleanR6Rig()
        end
    }
end

Library.AddESPPreview = addESPPreviewToGroupbox

-- Visuals Tab
local function buildVisualsTab()
    local ESPBox = Tabs.Visuals:AddLeftGroupbox('ESP')
    
    local BaseGroupbox = getmetatable(ESPBox)
    if BaseGroupbox and not BaseGroupbox.AddESPPreview then
        BaseGroupbox.AddESPPreview = function(self, options)
            return addESPPreviewToGroupbox(self, options)
        end
    end

    local PreviewBox = Tabs.Visuals:AddRightGroupbox('ESP Preview')
    local previewController = addESPPreviewToGroupbox(PreviewBox, { Height = 230 })
    
    PreviewBox:AddToggle('PreviewAutoRotate', {
        Text = 'Auto Rotate',
        Default = true,
        Callback = function(Value)
            PreviewSettings.AutoRotate = Value
        end
    })



ESPBox:AddToggle('ESPBoxes', {
    Text = 'Boxes',
    Default = false,
    Callback = function(Value)
        Config.ESP.Boxes = Value
    end
}):AddColorPicker('ESPBoxesColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Title = 'Boxes Color',
    Transparency = 0,
    Callback = function(Value)
        Config.ESP.Color = Value
        Config.ESP.BoxTransparency = (Options.ESPBoxesColor and Options.ESPBoxesColor.Transparency) or 0
    end
})
ESPBox:AddToggle('ESPNames', {
    Text = 'Names',
    Default = false,
    Callback = function(Value)
        Config.ESP.Names = Value
    end
}):AddColorPicker('ESPNamesColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Title = 'Names Color',
    Transparency = 0,
    Callback = function(Value)
        Config.ESP.NameColor = Value
        Config.ESP.NameTransparency = (Options.ESPNamesColor and Options.ESPNamesColor.Transparency) or 0
    end
})
ESPBox:AddToggle('ESPHealth', {
    Text = 'Health',
    Default = false,
    Callback = function(Value)
        Config.ESP.Health = Value
    end
}):AddColorPicker('ESPHealthColor', {
    Default = Color3.fromRGB(0, 255, 0),
    Title = 'Health Color',
    Transparency = 0,
    Callback = function(Value)
        Config.ESP.HealthColor = Value
        Config.ESP.HealthTransparency = (Options.ESPHealthColor and Options.ESPHealthColor.Transparency) or 0
    end
})
ESPBox:AddToggle('ESPFlags', {
    Text = 'Flags',
    Default = false,
    Callback = function(Value)
        Config.ESP.Flags = Value
    end
})
ESPBox:AddToggle('ESPTeamCheck', {
    Text = 'Team Check',
    Default = false,
    Callback = function(Value)
        Config.ESP.TeamCheck = Value
    end
})
ESPBox:AddToggle('BulletTracers', {
    Text = 'Bullet Tracers',
    Default = false,
    Callback = function(Value)
        Config.ESP.BulletTracers = Value
    end
}):AddColorPicker('BulletTracerColor', {
    Default = Color3.fromRGB(255, 0, 0),
    Title = 'Tracer Color',
    Transparency = 0,
    Callback = function(Value)
        Config.ESP.BulletTracerColor = Value
        Config.ESP.BulletTracerTransparency = (Options.BulletTracerColor and Options.BulletTracerColor.Transparency) or 0
    end
})

local TracerDepbox = ESPBox:AddDependencyBox()
TracerDepbox:SetupDependencies({
    { Toggles.BulletTracers, true }
})

TracerDepbox:AddDropdown('BulletTracerStyle', {
    Values = {'Plasma', 'Neon'},
    Default = 1,
    Multi = false,
    Text = 'Style',
    Callback = function(Value)
        Config.ESP.BulletTracerStyle = Value
    end
})
TracerDepbox:AddSlider('BulletTracerSize', {
    Text = 'Size',
    Default = 0.2,
    Min = 0.01,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        Config.ESP.BulletTracerSize = Value
    end
})
TracerDepbox:AddSlider('BulletTracerDuration', {
    Text = 'Lifetime',
    Default = 2,
    Min = 1,
    Max = 5,
    Rounding = 1,
    Callback = function(Value)
        Config.ESP.BulletTracerDuration = Value
    end
})
ESPBox:AddToggle('AmmoIndicator', {
    Text = 'Ammo Indicator',
    Default = false,
    Callback = function(Value)
        Config.ESP.AmmoIndicator = Value
    end
}):AddColorPicker('AmmoIndicatorColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Title = 'Ammo Color',
    Transparency = 0,
    Callback = function(Value)
        Config.ESP.AmmoIndicatorColor = Value
        Config.ESP.AmmoIndicatorTransparency = (Options.AmmoIndicatorColor and Options.AmmoIndicatorColor.Transparency) or 0
    end
})

local CrosshairBox = Tabs.Visuals:AddLeftGroupbox('Crosshair')
CrosshairBox:AddToggle('CustomCrosshair', {
    Text = 'Enable Crosshair',
    Default = false,
    Callback = function(Value)
        Config.Crosshair.Enabled = Value
    end
}):AddColorPicker('CrosshairColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Title = 'Crosshair Color',
    Transparency = 0,
    Callback = function(Value)
        Config.Crosshair.Color = Value
        Config.Crosshair.Transparency = (Options.CrosshairColor and Options.CrosshairColor.Transparency) or 0
    end
})

local CrosshairDepbox = CrosshairBox:AddDependencyBox()
CrosshairDepbox:SetupDependencies({
    { Toggles.CustomCrosshair, true }
})

CrosshairDepbox:AddToggle('CrosshairHideOnZoom', {
    Text = 'Hide On Zoom',
    Default = false,
    Callback = function(Value)
        Config.Crosshair.HideOnZoom = Value
    end
})
CrosshairDepbox:AddToggle('CrosshairSpin', {
    Text = 'Spin',
    Default = false,
    Callback = function(Value)
        Config.Crosshair.Spin = Value
    end
})

local CrosshairSpinDepbox = CrosshairDepbox:AddDependencyBox()
CrosshairSpinDepbox:SetupDependencies({
    { Toggles.CrosshairSpin, true }
})
CrosshairSpinDepbox:AddSlider('CrosshairSpinSpeed', {
    Text = 'Spin Speed',
    Default = 1,
    Min = 1,
    Max = 5,
    Rounding = 1,
    Callback = function(Value)
        Config.Crosshair.SpinSpeed = Value
    end
})

CrosshairDepbox:AddSlider('CrosshairGap', {
    Text = 'Offset',
    Default = 5,
    Min = 0,
    Max = 30,
    Rounding = 1,
    Callback = function(Value)
        Config.Crosshair.Gap = Value
    end
})
CrosshairDepbox:AddSlider('CrosshairLength', {
    Text = 'Length',
    Default = 10,
    Min = 2,
    Max = 30,
    Rounding = 1,
    Callback = function(Value)
        Config.Crosshair.Length = Value
    end
})
CrosshairDepbox:AddSlider('CrosshairThickness', {
    Text = 'Thickness',
    Default = 1,
    Min = 0.5,
    Max = 2.5,
    Rounding = 1,
    Callback = function(Value)
        Config.Crosshair.Thickness = Value
    end
})
CrosshairDepbox:AddToggle('CrosshairOutline', {
    Text = 'Outline',
    Default = true,
    Callback = function(Value)
        Config.Crosshair.Outline = Value
    end
}):AddColorPicker('CrosshairOutlineColor', {
    Default = Color3.fromRGB(0, 0, 0),
    Title = 'Outline Color',
    Transparency = 0,
    Callback = function(Value)
        Config.Crosshair.OutlineColor = Value
        Config.Crosshair.OutlineTransparency = (Options.CrosshairOutlineColor and Options.CrosshairOutlineColor.Transparency) or 0
    end
})
CrosshairDepbox:AddSlider('CrosshairOutlineThickness', {
    Text = 'Outline Size',
    Default = 1,
    Min = 0.5,
    Max = 2.5,
    Rounding = 1,
    Callback = function(Value)
        Config.Crosshair.OutlineThickness = Value
    end
})

local CameraBox = Tabs.Visuals:AddLeftGroupbox('Camera')
CameraBox:AddToggle('ThirdPerson', {
    Text = 'Third Person',
    Default = false,
    Callback = function(Value)
        Config.ESP.ThirdPerson = Value
    end
}):AddKeyPicker('ThirdPersonKey', {
    Default = 'V',
    SyncToggleState = true,
    Mode = 'Toggle',
    Text = 'Third Person',
    NoUI = false
})

CameraBox:AddSlider('ThirdPersonDistance', {
    Text = 'Distance',
    Default = 10,
    Min = 2,
    Max = 25,
    Rounding = 1,
    Callback = function(Value)
        Config.ESP.ThirdPersonDistance = Value
    end
})

CameraBox:AddDivider()

-- Aspect Ratio in Camera Box
CameraBox:AddToggle('AspectRatioToggle', {
    Text = 'Aspect Ratio',
    Default = false,
    Callback = function(Value)
        Config.Visuals.AspectRatioEnabled = Value
    end
})

local AspectRatioDep = CameraBox:AddDependencyBox()
AspectRatioDep:SetupDependencies({ { Toggles.AspectRatioToggle, true } })

AspectRatioDep:AddSlider('AspectRatioX', {
    Text = 'X',
    Default = 1,
    Min = 0.01,
    Max = 1,
    Rounding = 2,
    Compact = false,
    Callback = function(Value)
        Config.Visuals.AspectRatioX = Value
    end
})

AspectRatioDep:AddSlider('AspectRatioY', {
    Text = 'Y',
    Default = 1,
    Min = 0.01,
    Max = 1,
    Rounding = 2,
    Compact = false,
    Callback = function(Value)
        Config.Visuals.AspectRatioY = Value
    end
})

local VMBox = Tabs.Visuals:AddLeftGroupbox('Viewmodel Changer')
VMBox:AddToggle('ViewmodelOffset', {
    Text = 'Enable',
    Default = false,
    Callback = function(Value)
        Config.ESP.ViewmodelOffset = Value
    end
})

local VMDepbox = VMBox:AddDependencyBox()
VMDepbox:SetupDependencies({
    { Toggles.ViewmodelOffset, true }
})

VMDepbox:AddSlider('ViewmodelX', {
    Text = 'X', Default = 0, Min = -1, Max = 1, Rounding = 2,
    Callback = function(Value) Config.ESP.ViewmodelX = Value end
})
VMDepbox:AddSlider('ViewmodelY', {
    Text = 'Y', Default = 0, Min = -1, Max = 1, Rounding = 2,
    Callback = function(Value) Config.ESP.ViewmodelY = Value end
})
VMDepbox:AddSlider('ViewmodelZ', {
    Text = 'Z', Default = 0, Min = -1, Max = 1, Rounding = 2,
    Callback = function(Value) Config.ESP.ViewmodelZ = Value end
})

local ChamsBox = Tabs.Visuals:AddRightGroupbox('Chams')
ChamsBox:AddToggle('LocalChams', {
    Text = 'Local Chams',
    Default = false,
    Callback = function(Value)
        Config.ESP.LocalChams = Value
        if not Value then
            pcall(restoreLocalChams)
        end
    end
}):AddColorPicker('LocalChamsColor', {
    Default = Color3.fromRGB(0, 170, 255),
    Title = 'Local Chams Color',
    Transparency = 0,
    Callback = function(Value)
        Config.ESP.LocalChamsColor = Value
        Config.ESP.LocalChamsTransparency = (Options.LocalChamsColor and Options.LocalChamsColor.Transparency) or 0
    end
})
ChamsBox:AddDropdown('LocalChamsMaterial', {
    Values = {'Neon', 'ForceField', 'Plastic', 'Glass', 'Metal'},
    Default = 1,
    Multi = false,
    Text = 'Local Material',
    Callback = function(Value)
        Config.ESP.LocalChamsMaterial = Value
    end
})

ChamsBox:AddToggle('PlayerChams', {
    Text = 'Player Chams',
    Default = false,
    Callback = function(Value)
        Config.ESP.PlayerChams = Value
        if not Value then
            clearAllPlayerChams()
        end
    end
}):AddColorPicker('PlayerChamsColor', {
    Default = Color3.fromRGB(255, 0, 128),
    Title = 'Player Chams Color',
    Transparency = 0.5,
    Callback = function(Value)
        Config.ESP.PlayerChamsColor = Value
        Config.ESP.PlayerChamsTransparency = (Options.PlayerChamsColor and Options.PlayerChamsColor.Transparency) or 0.5
    end
})

ChamsBox:AddToggle('RagdollChams', {
    Text = 'Ragdoll Chams',
    Default = false,
    Callback = function(Value)
        Config.ESP.RagdollChams = Value
        if not Value then
            clearAllRagdollChams()
        end
    end
}):AddColorPicker('RagdollChamsColor', {
    Default = Color3.fromRGB(150, 0, 255),
    Title = 'Ragdoll Chams Color',
    Transparency = 0.5,
    Callback = function(Value)
        Config.ESP.RagdollChamsColor = Value
        Config.ESP.RagdollChamsTransparency = (Options.RagdollChamsColor and Options.RagdollChamsColor.Transparency) or 0.5
    end
})

ChamsBox:AddToggle('GunChamsEnabled', {
    Text = 'Gun Chams',
    Default = false,
    Callback = function(Value)
        Config.ESP.GunChamsEnabled = Value
        if not Value then
            restoreGunChams()
        end
    end
}):AddColorPicker('GunChamsColor', {
    Default = Color3.fromRGB(0, 255, 255),
    Title = 'Gun Chams Color',
    Transparency = 0,
    Callback = function(Value)
        Config.ESP.GunChamsColor = Value
        Config.ESP.GunChamsTransparency = (Options.GunChamsColor and Options.GunChamsColor.Transparency) or 0
    end
})
ChamsBox:AddDropdown('GunChamsMaterial', {
    Values = {'Neon', 'ForceField', 'Plastic', 'Glass', 'Metal'},
    Default = 1,
    Multi = false,
    Text = 'Material',
    Callback = function(Value)
        Config.ESP.GunChamsMaterial = Value
    end
})

local isHitsoundInitialLoad = true
local isShootsoundInitialLoad = true
task.delay(1.5, function()
    isHitsoundInitialLoad = false
    isShootsoundInitialLoad = false
end)

local SoundsBox = Tabs.Visuals:AddRightGroupbox('Sounds')
SoundsBox:AddDropdown('HitSoundDropdown', {
    Values = getHitsoundList(),
    Default = 1,
    Multi = false,
    Text = 'Hit Sound',
    Callback = function(Value)
        Config.GunMods.HitSound = Value
        if Value ~= "None" then
            task.spawn(function()
                local url = getHitSoundUrl(Value)
                ensureHitSoundPool(url)
            end)
            if not isHitsoundInitialLoad and not isRefreshingSoundDropdowns then
                playHitSound(Value)
            end
        end
    end
})

SoundsBox:AddDropdown('ShootSoundDropdown', {
    Values = getShootSoundList(),
    Default = 1,
    Multi = false,
    Text = 'Shoot Sound',
    Callback = function(Value)
        Config.GunMods.ShootSound = Value
        task.spawn(function()
            if Value ~= "None" then
                local url = getShootSoundUrl(Value)
                if url and url ~= "" then
                    ensureShootSoundPool(url)
                end
                applyShootSoundToAllEquippedGuns()
                if not isShootsoundInitialLoad and not isRefreshingSoundDropdowns then
                    playShootSound(Value)
                end
            else
                applyShootSoundToAllEquippedGuns()
            end
        end)
    end
})

-- Real-time watcher for newly downloaded or added sound files in workspace
-- Lazy watcher for newly downloaded sound files
task.spawn(function()
    local lastHitsCount = 0
    local lastShootsCount = 0
    while task.wait(15) do
        if _G.ConvergenceUnloaded then break end
        local hits = getHitsoundList()
        local shoots = getShootSoundList()
        if #hits ~= lastHitsCount or #shoots ~= lastShootsCount then
            lastHitsCount = #hits
            lastShootsCount = #shoots
            refreshSoundDropdowns()
        end
    end
end)

local WorldGroupBox = Tabs.Visuals:AddRightGroupbox('World Settings')

-- Weather Particles
WorldGroupBox:AddToggle('RainEnabled', {
    Text = 'Weather',
    Default = false,
    Callback = function(Value)
        Config.Visuals.RainEnabled = Value
        updateWeatherEmitter()
    end
})

local WeatherDep = WorldGroupBox:AddDependencyBox()
WeatherDep:SetupDependencies({ { Toggles.RainEnabled, true } })

WeatherDep:AddDropdown('ParticleType', {
    Values = {'Rain', 'Snow'},
    Default = 1,
    Multi = false,
    Text = 'Particle Type',
    Callback = function(Value)
        Config.Visuals.ParticleType = Value
        updateWeatherEmitter()
    end
})

WeatherDep:AddSlider('RainIntensity', {
    Text = 'Intensity',
    Default = 3,
    Min = 1,
    Max = 5,
    Rounding = 0,
    Callback = function(Value)
        Config.Visuals.RainIntensity = Value
        updateWeatherEmitter()
    end
})

-- Skybox
WorldGroupBox:AddToggle('CustomSkybox', {
    Text = 'Skybox',
    Default = false,
    Callback = function(Value)
        Config.Visuals.CustomSkybox = Value
        pcall(updateWorldLighting)
    end
})

local SkyboxDep = WorldGroupBox:AddDependencyBox()
SkyboxDep:SetupDependencies({ { Toggles.CustomSkybox, true } })

SkyboxDep:AddDropdown('CustomSkyboxPreset', {
    Values = {'Galaxy', 'Red', 'Blue', 'Pink', 'Black', 'White'},
    Default = 1,
    Multi = false,
    Text = 'Skybox Preset',
    Callback = function(Value)
        Config.Visuals.CustomSkyboxPreset = Value
        pcall(updateWorldLighting)
    end
})

-- World Lighting Modulation
WorldGroupBox:AddToggle('BrightnessEnabled', {
    Text = 'Brightness',
    Default = false,
    Callback = function(Value)
        Config.Visuals.BrightnessEnabled = Value
        if not Value and originalLighting then
            Lighting.Brightness = originalLighting.Brightness
            if not Config.Visuals.AmbientEnabled then
                Lighting.Ambient = originalLighting.Ambient
            end
        end
        pcall(updateWorldLighting)
    end
})

local BrightnessDep = WorldGroupBox:AddDependencyBox()
BrightnessDep:SetupDependencies({ { Toggles.BrightnessEnabled, true } })
BrightnessDep:AddSlider('Brightness', {
    Text = 'Brightness',
    Default = 2,
    Min = 0,
    Max = 10,
    Rounding = 1,
    Callback = function(Value)
        Config.Visuals.Brightness = Value
        pcall(updateWorldLighting)
    end
})

WorldGroupBox:AddToggle('ExposureEnabled', {
    Text = 'Exposure',
    Default = false,
    Callback = function(Value)
        Config.Visuals.ExposureEnabled = Value
        if not Value and originalLighting then
            Lighting.ExposureCompensation = originalLighting.ExposureCompensation
        end
        pcall(updateWorldLighting)
    end
})

local ExposureDep = WorldGroupBox:AddDependencyBox()
ExposureDep:SetupDependencies({ { Toggles.ExposureEnabled, true } })
ExposureDep:AddSlider('Exposure', {
    Text = 'Exposure',
    Default = 0,
    Min = -1,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        Config.Visuals.Exposure = Value
        pcall(updateWorldLighting)
    end
})

WorldGroupBox:AddToggle('AmbientEnabled', {
    Text = 'Ambient Color',
    Default = false,
    Callback = function(Value)
        Config.Visuals.AmbientEnabled = Value
        if not Value and originalLighting then
            Lighting.Ambient = originalLighting.Ambient
        end
        pcall(updateWorldLighting)
    end
}):AddColorPicker('AmbientColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Title = 'Ambient Color',
    Transparency = 0,
    Callback = function(Value)
        Config.Visuals.AmbientColor = Value
        pcall(updateWorldLighting)
    end
})

WorldGroupBox:AddToggle('ClockTimeEnabled', {
    Text = 'Time of Day',
    Default = false,
    Callback = function(Value)
        Config.Visuals.ClockTimeEnabled = Value
        if not Value and originalLighting then
            Lighting.ClockTime = originalLighting.ClockTime
        end
        pcall(updateWorldLighting)
    end
})

local ClockTimeDep = WorldGroupBox:AddDependencyBox()
ClockTimeDep:SetupDependencies({ { Toggles.ClockTimeEnabled, true } })
ClockTimeDep:AddSlider('ClockTime', {
    Text = 'Clock Time',
    Default = 14,
    Min = 0,
    Max = 24,
    Rounding = 1,
    Callback = function(Value)
        Config.Visuals.ClockTime = Value
        pcall(updateWorldLighting)
    end
})

WorldGroupBox:AddToggle('BloomEnabled', {
    Text = 'Bloom',
    Default = false,
    Callback = function(Value)
        Config.Visuals.BloomEnabled = Value
        pcall(updateWorldLighting)
    end
})

local BloomDep = WorldGroupBox:AddDependencyBox()
BloomDep:SetupDependencies({ { Toggles.BloomEnabled, true } })
BloomDep:AddSlider('BloomIntensity', {
    Text = 'Intensity',
    Default = 0.4,
    Min = 0,
    Max = 1.5,
    Rounding = 2,
    Callback = function(Value)
        Config.Visuals.BloomIntensity = Value
        pcall(updateWorldLighting)
    end
})
BloomDep:AddSlider('BloomSize', {
    Text = 'Size',
    Default = 24,
    Min = 1,
    Max = 50,
    Rounding = 0,
    Callback = function(Value)
        Config.Visuals.BloomSize = Value
        pcall(updateWorldLighting)
    end
})
BloomDep:AddSlider('BloomThreshold', {
    Text = 'Threshold',
    Default = 0.95,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        Config.Visuals.BloomThreshold = Value
        pcall(updateWorldLighting)
    end
})

-- Camera Position & Third Person Handler-- Camera Position & Third Person Handler
local wasThirdPersonActive = false

RunService:BindToRenderStep("ThirdPersonCamera", Enum.RenderPriority.Camera.Value + 2, function()
    local camera = Workspace.CurrentCamera
    if not camera or _G.ConvergenceUnloaded then return end
    
    local char = LocalPlayer.Character or (Workspace:FindFirstChild("Characters") and Workspace.Characters:FindFirstChild(LocalPlayer.Name)) or Workspace:FindFirstChild(LocalPlayer.Name)
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    
    if Config.ESP.ThirdPerson then
        wasThirdPersonActive = true
        
        -- Hide only the floating first-person viewmodel in CurrentCamera
        for _, child in ipairs(camera:GetChildren()) do
            if child:IsA("Model") or child:IsA("Folder") then
                for _, part in ipairs(child:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.LocalTransparencyModifier = 1
                    end
                end
            end
        end
        
        if char and hrp then
            -- Ensure real character body, limbs, and equipped weapons are visible in third person
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name:lower() ~= "humanoidrootpart" then
                    part.LocalTransparencyModifier = 0
                end
            end
            
            local rootPos = hrp.Position + Vector3.new(0, 1.5, 0)
            local lookRot = camera.CFrame - camera.CFrame.Position
            local maxDist = Config.ESP.ThirdPersonDistance or 10
            
            local startPos = rootPos
            local targetPos = startPos - (camera.CFrame.LookVector * maxDist)
            
            -- Anti-clip raycast against map walls
            local rayParams = RaycastParams.new()
            local filter = {char, camera}
            local ignored = Workspace:FindFirstChild("Ignored") or Workspace:FindFirstChild("Ignore")
            if ignored then table.insert(filter, ignored) end
            
            rayParams.FilterDescendantsInstances = filter
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            rayParams.IgnoreWater = true
            rayParams.CollisionGroup = "Raycast"
            
            local ray = Workspace:Raycast(startPos, -camera.CFrame.LookVector * maxDist, rayParams)
            local actualPos = ray and (ray.Position + (ray.Normal * 0.4)) or targetPos
            
            camera.CFrame = CFrame.new(actualPos) * lookRot
        end
    else
        if wasThirdPersonActive then
            wasThirdPersonActive = false
            -- Restore first-person camera viewmodel
            for _, child in ipairs(camera:GetChildren()) do
                if child:IsA("Model") or child:IsA("Folder") then
                    for _, part in ipairs(child:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.LocalTransparencyModifier = 0
                        end
                    end
                end
            end
        end
    end
end)
end -- Visuals Tab
buildVisualsTab()

-- Misc Tab
local function buildMiscTab()
    local MiscLeft = Tabs.Misc:AddLeftGroupbox('Misc')
    
    MiscLeft:AddToggle('ServerCrash', {
        Text = 'Crash Server',
        Default = false,
        Risky = true,
        Callback = function(Value)
            Config.Misc.CrashServer = Value
            if Value then
                CrashAndSpam.startCrashServer()
            else
                CrashAndSpam.stopCrashServer()
            end
        end
    })
    
    for _, child in ipairs(MiscLeft.Container:GetDescendants()) do
        if child:IsA("TextLabel") and child.Text == "Crash Server" then
            Library:RemoveFromRegistry(child)
            child.TextColor3 = Color3.fromRGB(255, 50, 50)
            break
        end
    end
    
end -- Misc Tab
buildMiscTab()

-- Settings Tab
local function buildSettingsTab()
    Library:SetWatermarkVisibility(false)
    
    local MenuGroup = Tabs.Settings:AddLeftGroupbox('Menu')
    MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'Insert', NoUI = true, Text = 'Menu keybind' })
    Library.ToggleKeybind = Options.MenuKeybind
    
    SaveManager:SetLibrary(Library)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
    SaveManager:SetFolder('KittyWare/Configs')
    SaveManager:BuildConfigSection(Tabs.Settings)
    SaveManager:LoadAutoloadConfig()
    if not (Config.Misc.Backtrack and Config.Misc.BacktrackGhost) then
        clearAllGhostAdornments()
    end
    if not Config.ESP.PlayerChams then
        clearAllPlayerChams()
    end
    if not Config.ESP.RagdollChams then
        clearAllRagdollChams()
    end
    if not Config.ESP.GunChamsEnabled then
        restoreGunChams()
    end
    if not Config.ESP.LocalChams then
        restoreLocalChams()
    end
end -- Settings Tab
buildSettingsTab()


local function initViewmodelAndChams()
    local wasGunChamsActive = false
    local cachedPartsList = {}
    local lastChamsScan = 0
    local vmBlend = 1.0
    local lastVMTime = os.clock()
    local lastAppliedOffsets = setmetatable({}, { __mode = "k" })
    
    RunService:BindToRenderStep("ViewmodelMods", Enum.RenderPriority.Last.Value, function()
        local offsetModels, chamsModels = getViewmodels()
        if #offsetModels == 0 and #chamsModels == 0 then return end
        
        local now = os.clock()
        local dt = math.clamp(now - lastVMTime, 0.001, 0.1)
        lastVMTime = now
        
        if Config.ESP.ViewmodelOffset then
            local UserInputService = game:GetService("UserInputService")
            local isAiming = false
            pcall(function()
                if _G.Aiming == true then
                    isAiming = true
                elseif UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                    isAiming = true
                end
                local cam = Workspace.CurrentCamera
                if cam and cam.FieldOfView < 68 then
                    isAiming = true
                end
            end)
            
            local targetBlend = if isAiming then 0.0 else 1.0
            local blendSpeed = if isAiming then 22 else 16
            vmBlend = math.clamp(vmBlend + (targetBlend - vmBlend) * math.clamp(dt * blendSpeed, 0, 1), 0, 1)
            
            local curX = (Config.ESP.ViewmodelX or 0) * vmBlend
            local curY = (Config.ESP.ViewmodelY or 0) * vmBlend
            local curZ = (Config.ESP.ViewmodelZ or 0) * vmBlend
            local currentDesiredOffset = CFrame.new(curX, curY, curZ)
            
            for _, vm in ipairs(offsetModels) do
                if vm and vm.Parent then
                    local lastOffset = lastAppliedOffsets[vm] or CFrame.identity
                    -- Safely unshift previous frame offset to retrieve base position
                    local cleanPivot = vm:GetPivot() * lastOffset:Inverse()
                    
                    if vmBlend > 0.0005 and (math.abs(curX) > 0.0001 or math.abs(curY) > 0.0001 or math.abs(curZ) > 0.0001) then
                        vm:PivotTo(cleanPivot * currentDesiredOffset)
                        lastAppliedOffsets[vm] = currentDesiredOffset
                    else
                        vm:PivotTo(cleanPivot)
                        lastAppliedOffsets[vm] = CFrame.identity
                    end
                end
            end
        else
            vmBlend = 0.0
            for _, vm in ipairs(offsetModels) do
                if vm and vm.Parent and lastAppliedOffsets[vm] and lastAppliedOffsets[vm] ~= CFrame.identity then
                    local cleanPivot = vm:GetPivot() * lastAppliedOffsets[vm]:Inverse()
                    vm:PivotTo(cleanPivot)
                    lastAppliedOffsets[vm] = CFrame.identity
                end
            end
        end    
        
        if Config.ESP.GunChamsEnabled then
            wasGunChamsActive = true
            local userChamsTrans = math.clamp(Config.ESP.GunChamsTransparency or 0, 0, 1)
            local mat = Enum.Material[Config.ESP.GunChamsMaterial] or Enum.Material.Neon
            local col = Config.ESP.GunChamsColor or Color3.fromRGB(0, 255, 255)
            
            updateChamsBloom()
            
            local now = os.clock()
            if (now - lastChamsScan) >= 0.3 then
                lastChamsScan = now
                local list = {}
                for _, vm in ipairs(chamsModels) do
                    for _, part in ipairs(vm:GetDescendants()) do
                        if part:IsA("BasePart") then
                            local origTrans = originalTransparencies[part] or part.Transparency
                            if origTrans < 0.95 then
                                local name = part.Name:lower()
                                if not (name:find("reticle") or name == "humanoidrootpart" or name == "camerabone") then
                                    table.insert(list, part)
                                end
                            end
                        end
                    end
                end
                cachedPartsList = list
            end
            
            for _, part in ipairs(cachedPartsList) do
                if part.Parent then
                    local baseTrans = originalTransparencies[part] or part.Transparency
                    if baseTrans < 0.95 then
                        if not processedChamsParts[part] then
                            processedChamsParts[part] = true
                            
                            for _, child in ipairs(part:GetChildren()) do
                                if child:IsA("SurfaceAppearance") or child:IsA("Texture") or child:IsA("Decal") then
                                    if originalSurfaceAppearances[child] == nil then
                                        originalSurfaceAppearances[child] = child.Parent
                                    end
                                    child.Parent = nil
                                end
                            end
                            
                            if part:IsA("MeshPart") then
                                if part.TextureID ~= "" then
                                    if not originalMeshTextures[part] then
                                        originalMeshTextures[part] = part.TextureID
                                    end
                                    part.TextureID = ""
                                end
                            elseif part:IsA("UnionOperation") or part:IsA("Part") then
                                local specialMesh = part:FindFirstChildWhichIsA("SpecialMesh")
                                if specialMesh and specialMesh.TextureId ~= "" then
                                    if not originalMeshTextures[specialMesh] then
                                        originalMeshTextures[specialMesh] = specialMesh.TextureId
                                    end
                                    specialMesh.TextureId = ""
                                end
                            end
                            
                            if not originalMaterials[part] then
                                originalMaterials[part] = part.Material
                                originalColors[part] = part.Color
                                originalTransparencies[part] = part.Transparency
                            end
                        end
                        
                        if part.Material ~= mat then part.Material = mat end
                        if part.Color ~= col then part.Color = col end
                        if math.abs(part.Transparency - userChamsTrans) > 0.005 then
                            part.Transparency = userChamsTrans
                        end
                    end
                end
            end
        else
            if wasGunChamsActive then
                wasGunChamsActive = false
                table.clear(cachedPartsList)
                restoreGunChams()
            end
        end
    end)
end -- Viewmodel and Gun Chams Logic
initViewmodelAndChams()
