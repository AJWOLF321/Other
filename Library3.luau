--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                 KITTYWARE NEXT-GEN CHEAT UI FRAMEWORK                     ║
    ║   Ultra-Custom Landscape Suite (880x560), Custom Typography (bold.ttf)    ║
    ║   Modern 40px Capsule Tabs with Icons, 20px Animated Toggle Checkboxes    ║
    ║   Rounded Card Groupboxes, Custom Smooth Sliders, Dropdowns & Controls    ║
    ║   Live Stats Watermark & Keybinds Monitor, Fatality Loader Sequence       ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

local InputService = game:GetService('UserInputService');
local TextService = game:GetService('TextService');
local CoreGui = game:GetService('CoreGui');
local Teams = game:GetService('Teams');
local Players = game:GetService('Players');
local RunService = game:GetService('RunService');
local TweenService = game:GetService('TweenService');
local RenderStepped = RunService.RenderStepped;
local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait();
local Mouse = LocalPlayer:GetMouse();

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

local SafeContainer = GetSafeContainer()
local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end);

-- Clean up any prior running instances
if getgenv().KittyWareCleanup then
    pcall(getgenv().KittyWareCleanup)
end
if getgenv().KittyWareGui and getgenv().KittyWareGui.Parent then
    pcall(function() getgenv().KittyWareGui:Destroy() end)
end
local existingBlur = game:GetService("Lighting"):FindFirstChild("KittyWareBlur")
if existingBlur then
    pcall(function() existingBlur:Destroy() end)
end

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                               ASSET MANAGER                               ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

local AssetManager = {}
do
    local GITHUB_BASE = "https://raw.githubusercontent.com/AJWOLF321/Kitty/main/Assets/"

    local ASSET_REGISTRY = {
        Fonts = {
            ["bold.ttf"] = GITHUB_BASE .. "Fonts/bold.ttf"
        },
        Images = {
            ["person.png"] = GITHUB_BASE .. "Images/person.png",
            ["latency.png"] = GITHUB_BASE .. "Images/latency.png",
            ["latencyy.png"] = GITHUB_BASE .. "Images/latency.png",
            ["clock.png"] = GITHUB_BASE .. "Images/clock.png",
            ["keyboard.png"] = GITHUB_BASE .. "Images/keyboard.png",
            ["computer.png"] = GITHUB_BASE .. "Images/computer.png",
            ["shadow.png"] = GITHUB_BASE .. "Images/shadow.png",
            ["aim.png"] = GITHUB_BASE .. "Images/aim.png",
            ["terrain.png"] = GITHUB_BASE .. "Images/terrain.png",
            ["bolt.png"] = GITHUB_BASE .. "Images/bolt.png",
            ["cog.png"] = GITHUB_BASE .. "Images/cog.png",
            ["checkmark.png"] = GITHUB_BASE .. "Images/checkmark.png",
            ["paintbrush.png"] = GITHUB_BASE .. "Images/paintbrush.png",
            ["down_arrow.png"] = GITHUB_BASE .. "Images/down_arrow.png"
        }
    }

    local EMBEDDED_FALLBACKS = {
        ["KittyWare/Assets/Images/paintbrush.png"] = "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAkUlEQVR4nNWTMQrDMBRD3ybm4Nq5Q8hSOlco7g26tT5CL2F1hIzkBDmEm37sYEkVJMQOBj/x8xKkE4AR9b1XvgCXZVn1fCgAbwBwB96f8wBfD309l1IAvAEvwNl8q2VZa632fGmt8wVomk5q213n3E3Xv+z73iPqug7GmD+v2bZtrbW2LMu0bdudc88YY9CyrPP7AQq4Vj4qD8TfAAAAAElFTkSuQmCC",
        ["KittyWare/Assets/Images/checkmark.png"] = "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAA7SURBVDhPY/j//z9FGBgYgGKYGG4AmwY8BtAMwGUxigG4LEbXQJRBKAZhGEQxDMxHGYRikJCG/xQzEAQAAM/3HQ41P2cAAAAASUVORK5CYII="
    }

    local b64_chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local b64_lookup = {}
    for i = 1, #b64_chars do
        b64_lookup[b64_chars:sub(i, i)] = i - 1
    end

    local function base64Decode(data)
        local chars = {}
        local len = #data
        local padding = 0
        if data:sub(-2) == '==' then padding = 2
        elseif data:sub(-1) == '=' then padding = 1 end

        local bit_pattern = 0
        local bits_count = 0
        for i = 1, len - padding do
            local char = data:sub(i, i)
            local val = b64_lookup[char]
            if val then
                bit_pattern = (bit_pattern * 64) + val
                bits_count = bits_count + 6
                if bits_count >= 8 then
                    bits_count = bits_count - 8
                    local byte = math.floor(bit_pattern / (2 ^ bits_count)) % 256
                    table.insert(chars, string.char(byte))
                end
            end
        end
        return table.concat(chars, "")
    end

    function AssetManager:Init()
        local requiredFolders = {
            "KittyWare",
            "KittyWare/Assets",
            "KittyWare/Assets/Fonts",
            "KittyWare/Assets/Images"
        }
        for _, folder in ipairs(requiredFolders) do
            if makefolder and isfolder and not isfolder(folder) then
                pcall(makefolder, folder)
            end
        end

        for fileName, url in pairs(ASSET_REGISTRY.Fonts) do
            local localPath = "KittyWare/Assets/Fonts/" .. fileName
            if writefile and isfile and not isfile(localPath) then
                pcall(function()
                    local data = game:HttpGet(url)
                    if data and #data > 0 then
                        writefile(localPath, data)
                    end
                end)
            end
        end

        for fileName, url in pairs(ASSET_REGISTRY.Images) do
            local localPath = "KittyWare/Assets/Images/" .. fileName
            if writefile and isfile and not isfile(localPath) then
                local downloaded = false
                pcall(function()
                    local data = game:HttpGet(url)
                    if data and #data > 0 then
                        writefile(localPath, data)
                        downloaded = true
                    end
                end)

                if not downloaded and EMBEDDED_FALLBACKS[localPath] then
                    pcall(function()
                        writefile(localPath, base64Decode(EMBEDDED_FALLBACKS[localPath]))
                    end)
                end
            end
        end
    end

    function AssetManager:GetAsset(path)
        if not string.find(path, "/") then
            path = "KittyWare/Assets/Images/" .. path
            if not string.find(path, "%.png$") then
                path = path .. ".png"
            end
        end
        if getcustomasset and isfile and isfile(path) then
            local ok, asset = pcall(getcustomasset, path)
            if ok and asset then return asset end
        elseif getsynasset and isfile and isfile(path) then
            local ok, asset = pcall(getsynasset, path)
            if ok and asset then return asset end
        end
        return ""
    end

    function AssetManager:GetCustomFont(fontPath)
        if getcustomasset and isfile and isfile(fontPath) then
            local ok, asset = pcall(getcustomasset, fontPath)
            if ok and asset then
                local okFont, fontFace = pcall(function()
                    return Font.new(asset, Enum.FontWeight.Bold, Enum.FontStyle.Normal)
                end)
                if okFont and fontFace then
                    return fontFace
                end
            end
        end
        return Font.fromEnum(Enum.Font.GothamBold)
    end
end

AssetManager:Init()

local CustomFont = AssetManager:GetCustomFont("KittyWare/Assets/Fonts/bold.ttf")

local ScreenGui = Instance.new('ScreenGui');
ScreenGui.Name = GetRandomSymbolString(16);
ProtectGui(ScreenGui);

ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;
ScreenGui.Parent = SafeContainer;
getgenv().KittyWareGui = ScreenGui;

local Toggles = {};
local Options = {};

getgenv().Toggles = Toggles;
getgenv().Options = Options;

local Library = {
    Registry = {};
    RegistryMap = {};
    HudRegistry = {};

    FontColor = Color3.fromRGB(240, 240, 248);
    MainColor = Color3.fromRGB(16, 16, 22);
    BackgroundColor = Color3.fromRGB(12, 12, 16);
    CardColor = Color3.fromRGB(20, 20, 26);
    AccentColor = Color3.fromRGB(175, 40, 255);
    AccentColorDark = Color3.fromRGB(120, 25, 180);
    OutlineColor = Color3.fromRGB(38, 38, 48);
    RiskColor = Color3.fromRGB(255, 60, 60);

    Black = Color3.new(0, 0, 0);
    Font = Enum.Font.GothamBold;
    CustomFont = CustomFont;

    OpenedFrames = {};
    DependencyBoxes = {};
    Signals = {};
    ScreenGui = ScreenGui;
    AssetManager = AssetManager;
};

function Library:SafeCallback(f, ...)
    if (not f) then return end;
    if not Library.NotifyOnError then return f(...) end;
    local success, event = pcall(f, ...);
    if not success then
        local _, i = event:find(":%d+: ");
        if not i then return Library:Notify(event) end;
        return Library:Notify(event:sub(i + 1), 3);
    end;
end;

function Library:AttemptSave()
    if Library.SaveManager then
        pcall(function() Library.SaveManager:Save() end);
    end;
end;

function Library:Create(Class, Properties)
    local _Instance = Class;
    if type(Class) == 'string' then
        _Instance = Instance.new(Class);
    end;
    for Property, Value in next, Properties do
        _Instance[Property] = Value;
    end;
    return _Instance;
end;

function Library:ApplyTextStroke(Inst)
    Inst.TextStrokeTransparency = 1;
end;

function Library:CreateLabel(Properties, IsHud)
    local _Instance = Library:Create('TextLabel', {
        BackgroundTransparency = 1;
        FontFace = Library.CustomFont;
        Font = Enum.Font.GothamBold;
        TextColor3 = Library.FontColor;
        TextSize = 13;
        TextStrokeTransparency = 1;
    });

    Library:AddToRegistry(_Instance, {
        TextColor3 = 'FontColor';
    }, IsHud);

    return Library:Create(_Instance, Properties);
end;

function Library:MakeDraggable(Instance, Cutoff)
    Instance.Active = true;
    Instance.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            local ObjPos = Vector2.new(
                Mouse.X - Instance.AbsolutePosition.X,
                Mouse.Y - Instance.AbsolutePosition.Y
            );
            if ObjPos.Y > (Cutoff or 46) then return end;

            while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                Instance.Position = UDim2.new(
                    0,
                    Mouse.X - ObjPos.X + (Instance.Size.X.Offset * Instance.AnchorPoint.X),
                    0,
                    Mouse.Y - ObjPos.Y + (Instance.Size.Y.Offset * Instance.AnchorPoint.Y)
                );
                RenderStepped:Wait();
            end;
        end;
    end)
end;

function Library:AddToolTip(InfoStr, HoverInstance)
    local X, Y = Library:GetTextBounds(InfoStr, Library.Font, 13);
    local Tooltip = Library:Create('Frame', {
        BackgroundColor3 = Color3.fromRGB(22, 22, 28),
        BorderColor3 = Color3.fromRGB(48, 48, 62),
        Size = UDim2.fromOffset(X + 16, Y + 10),
        ZIndex = 300,
        Parent = Library.ScreenGui,
        Visible = false,
    })

    Library:Create('UICorner', {
        CornerRadius = UDim.new(0, 5),
        Parent = Tooltip
    })

    Library:CreateLabel({
        Position = UDim2.fromOffset(8, 5),
        Size = UDim2.fromOffset(X, Y);
        TextSize = 12;
        Text = InfoStr,
        TextColor3 = Color3.fromRGB(240, 240, 248),
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 301,
        Parent = Tooltip;
    });

    local IsHovering = false
    HoverInstance.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame() then return end
        IsHovering = true
        Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        Tooltip.Visible = true
        while IsHovering do
            Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
            RenderStepped:Wait()
        end
        Tooltip.Visible = false
    end)

    HoverInstance.MouseLeave:Connect(function()
        IsHovering = false
    end)
end;

function Library:OnHighlight(HighlightInstance, Instance, PropertiesDisabled, PropertiesEnabled)
    HighlightInstance.MouseEnter:Connect(function()
        for Property, Value in next, PropertiesDisabled do
            Instance[Property] = type(Value) == 'string' and Library[Value] or Value
        end
    end);
    HighlightInstance.MouseLeave:Connect(function()
        for Property, Value in next, PropertiesEnabled do
            Instance[Property] = type(Value) == 'string' and Library[Value] or Value
        end
    end);
end;

function Library:MouseIsOverOpenedFrame()
    for Frame, _ in next, Library.OpenedFrames do
        local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;
        if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
            and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then
            return true;
        end;
    end;
end;

function Library:IsMouseOverFrame(Frame)
    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;
    if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
        and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then
        return true;
    end;
end;

function Library:UpdateDependencyBoxes()
    for _, Depbox in next, Library.DependencyBoxes do
        Depbox:Update();
    end;
end;

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
    return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB;
end;

function Library:GetTextBounds(Text, Font, Size, Resolution)
    local Bounds = TextService:GetTextSize(Text, Size, Font or Enum.Font.GothamBold, Resolution or Vector2.new(1920, 1080))
    return Bounds.X, Bounds.Y
end;

function Library:GetDarkerColor(Color)
    local H, S, V = Color3.toHSV(Color);
    return Color3.fromHSV(H, S, V / 1.5);
end;

function Library:AddToRegistry(Instance, Properties, IsHud)
    local Idx = #Library.Registry + 1;
    local Data = {
        Instance = Instance;
        Properties = Properties;
        Idx = Idx;
    };
    table.insert(Library.Registry, Data);
    Library.RegistryMap[Instance] = Data;
    if IsHud then
        table.insert(Library.HudRegistry, Data);
    end;
end;

function Library:RemoveFromRegistry(Instance)
    local Data = Library.RegistryMap[Instance];
    if Data then
        for Idx = #Library.Registry, 1, -1 do
            if Library.Registry[Idx] == Data then
                table.remove(Library.Registry, Idx);
            end;
        end;
        for Idx = #Library.HudRegistry, 1, -1 do
            if Library.HudRegistry[Idx] == Data then
                table.remove(Library.HudRegistry, Idx);
            end;
        end;
        Library.RegistryMap[Instance] = nil;
    end;
end;

function Library:GiveSignal(Signal)
    table.insert(Library.Signals, Signal)
end

function Library:Unload()
    for Idx = #Library.Signals, 1, -1 do
        local Connection = table.remove(Library.Signals, Idx)
        Connection:Disconnect()
    end
    if Library.OnUnload then
        Library.OnUnload()
    end
    ScreenGui:Destroy()
end

function Library:OnUnload(Callback)
    Library.OnUnload = Callback
end

local BaseAddons = {};
do
    local Funcs = {};

    function Funcs:AddColorPicker(Idx, Info)
        local ToggleLabel = self.TextLabel;
        assert(Info.Default, 'AddColorPicker: Missing default value.');

        local ColorPicker = {
            Value = Info.Default;
            Transparency = Info.Transparency or 0;
            Type = 'ColorPicker';
            Title = type(Info.Title) == 'string' and Info.Title or 'Color Picker',
            Callback = Info.Callback or function(Color) end;
        };

        function ColorPicker:SetHSVFromRGB(Color)
            local H, S, V = Color3.toHSV(Color);
            ColorPicker.Hue = H;
            ColorPicker.Sat = S;
            ColorPicker.Vib = V;
        end;

        ColorPicker:SetHSVFromRGB(ColorPicker.Value);

        local DisplayFrame = Library:Create('Frame', {
            BackgroundColor3 = ColorPicker.Value;
            BorderColor3 = Color3.fromRGB(50, 50, 64);
            Size = UDim2.new(0, 24, 0, 15);
            ZIndex = 6;
            Parent = ToggleLabel;
        });

        Library:Create('UICorner', {
            CornerRadius = UDim.new(0, 4),
            Parent = DisplayFrame
        })

        local PickerFrameOuter = Library:Create('Frame', {
            Name = 'Color';
            BackgroundColor3 = Color3.fromRGB(16, 16, 22);
            BorderColor3 = Color3.fromRGB(48, 48, 62);
            Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 20),
            Size = UDim2.fromOffset(230, 255),
            Visible = false;
            ZIndex = 15;
            Parent = ScreenGui,
        });

        Library:Create('UICorner', {
            CornerRadius = UDim.new(0, 6),
            Parent = PickerFrameOuter
        })

        DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            PickerFrameOuter.Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 20);
        end)

        local Highlight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 0, 2);
            ZIndex = 16;
            Parent = PickerFrameOuter;
        });

        local SatVibMapOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.fromRGB(20, 20, 26);
            BorderColor3 = Color3.fromRGB(44, 44, 56);
            Position = UDim2.new(0, 8, 0, 16);
            Size = UDim2.new(0, 192, 0, 192);
            ZIndex = 17;
            Parent = PickerFrameOuter;
        });

        Library:Create('UICorner', {
            CornerRadius = UDim.new(0, 4),
            Parent = SatVibMapOuter
        })

        local SatVibMap = Library:Create('ImageLabel', {
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Image = 'rbxassetid://4155801252';
            Parent = SatVibMapOuter;
        });

        Library:Create('UICorner', {
            CornerRadius = UDim.new(0, 4),
            Parent = SatVibMap
        })

        local CursorOuter = Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0.5, 0.5);
            Size = UDim2.new(0, 8, 0, 8);
            BackgroundTransparency = 1;
            Image = 'http://www.roblox.com/asset/?id=9619665977';
            ImageColor3 = Color3.new(0, 0, 0);
            ZIndex = 19;
            Parent = SatVibMap;
        });

        local HueSelectorOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.fromRGB(20, 20, 26);
            BorderColor3 = Color3.fromRGB(44, 44, 56);
            Position = UDim2.new(0, 206, 0, 16);
            Size = UDim2.new(0, 16, 0, 192);
            ZIndex = 17;
            Parent = PickerFrameOuter;
        });

        Library:Create('UICorner', {
            CornerRadius = UDim.new(0, 4),
            Parent = HueSelectorOuter
        })

        local HueCursor = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 0, 2);
            ZIndex = 19;
            Parent = HueSelectorOuter;
        });

        local HexBox = Library:Create('TextBox', {
            BackgroundColor3 = Color3.fromRGB(24, 24, 32);
            BorderColor3 = Color3.fromRGB(44, 44, 56);
            Position = UDim2.new(0, 8, 0, 218);
            Size = UDim2.new(1, -16, 0, 24);
            FontFace = Library.CustomFont;
            Font = Enum.Font.GothamBold;
            TextSize = 12;
            TextColor3 = Library.FontColor;
            Text = '#' .. ColorPicker.Value:ToHex();
            ZIndex = 18;
            Parent = PickerFrameOuter;
        });

        Library:Create('UICorner', {
            CornerRadius = UDim.new(0, 4),
            Parent = HexBox
        })

        local SequenceTable = {};
        for Hue = 0, 1, 0.1 do
            table.insert(SequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)));
        end;

        Library:Create('UIGradient', {
            Color = ColorSequence.new(SequenceTable);
            Rotation = 90;
            Parent = HueSelectorOuter;
        });

        HexBox.FocusLost:Connect(function(enter)
            if enter then
                local success, result = pcall(Color3.fromHex, HexBox.Text)
                if success and typeof(result) == 'Color3' then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(result)
                end
            end
            ColorPicker:Display()
        end)

        function ColorPicker:Display()
            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib);
            SatVibMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1);
            DisplayFrame.BackgroundColor3 = ColorPicker.Value;
            CursorOuter.Position = UDim2.new(ColorPicker.Sat, 0, 1 - ColorPicker.Vib, 0);
            HueCursor.Position = UDim2.new(0, 0, ColorPicker.Hue, 0);
            HexBox.Text = '#' .. ColorPicker.Value:ToHex()
            Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value);
            Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value);
        end;

        function ColorPicker:OnChanged(Func)
            ColorPicker.Changed = Func;
            Func(ColorPicker.Value)
        end;

        function ColorPicker:Show()
            for Frame, _ in next, Library.OpenedFrames do
                if Frame.Name == 'Color' then Frame.Visible = false Library.OpenedFrames[Frame] = nil end
            end
            PickerFrameOuter.Visible = true;
            Library.OpenedFrames[PickerFrameOuter] = true;
        end;

        function ColorPicker:Hide()
            PickerFrameOuter.Visible = false;
            Library.OpenedFrames[PickerFrameOuter] = nil;
        end;

        function ColorPicker:SetValueRGB(Color)
            ColorPicker:SetHSVFromRGB(Color);
            ColorPicker:Display();
        end;

        SatVibMap.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local MinX = SatVibMap.AbsolutePosition.X;
                    local MaxX = MinX + SatVibMap.AbsoluteSize.X;
                    local MouseX = math.clamp(Mouse.X, MinX, MaxX);
                    local MinY = SatVibMap.AbsolutePosition.Y;
                    local MaxY = MinY + SatVibMap.AbsoluteSize.Y;
                    local MouseY = math.clamp(Mouse.Y, MinY, MaxY);
                    ColorPicker.Sat = (MouseX - MinX) / (MaxX - MinX);
                    ColorPicker.Vib = 1 - ((MouseY - MinY) / (MaxY - MinY));
                    ColorPicker:Display();
                    RenderStepped:Wait();
                end;
                Library:AttemptSave();
            end;
        end);

        HueSelectorOuter.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local MinY = HueSelectorOuter.AbsolutePosition.Y;
                    local MaxY = MinY + HueSelectorOuter.AbsoluteSize.Y;
                    local MouseY = math.clamp(Mouse.Y, MinY, MaxY);
                    ColorPicker.Hue = ((MouseY - MinY) / (MaxY - MinY));
                    ColorPicker:Display();
                    RenderStepped:Wait();
                end;
                Library:AttemptSave();
            end;
        end);

        DisplayFrame.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                if PickerFrameOuter.Visible then ColorPicker:Hide() else ColorPicker:Show() end;
            end;
        end);

        ColorPicker:Display();
        Options[Idx] = ColorPicker;
        return self;
    end;

    function Funcs:AddKeyPicker(Idx, Info)
        local ParentObj = self;
        local ToggleLabel = self.TextLabel;
        assert(Info.Default, 'AddKeyPicker: Missing default value.');

        local KeyPicker = {
            Value = Info.Default;
            Toggled = false;
            Mode = Info.Mode or 'Toggle';
            Type = 'KeyPicker';
            SyncToggleState = Info.SyncToggleState or false;
            Callback = Info.Callback or function(Value) end;
            ChangedCallback = Info.ChangedCallback or function(New) end;
        };

        if KeyPicker.SyncToggleState then
            KeyPicker.Toggled = ParentObj.Value;
        end;

        local PickOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.fromRGB(28, 28, 38);
            BorderColor3 = Color3.fromRGB(50, 50, 64);
            Size = UDim2.new(0, 38, 0, 18);
            ZIndex = 6;
            Parent = ToggleLabel;
        });

        Library:Create('UICorner', {
            CornerRadius = UDim.new(0, 4),
            Parent = PickOuter
        })

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = 11;
            Text = Info.Default;
            TextXAlignment = Enum.TextXAlignment.Center;
            ZIndex = 7;
            Parent = PickOuter;
        });

        local ContainerLabel = Library:CreateLabel({
            TextXAlignment = Enum.TextXAlignment.Left;
            Size = UDim2.new(1, 0, 0, 20);
            TextSize = 13;
            Visible = false;
            ZIndex = 110;
            Parent = Library.KeybindContainer;
        }, true);

        function KeyPicker:Update()
            if Info.NoUI then return end;
            local State = KeyPicker:GetState();
            ContainerLabel.Text = string.format('[%s] %s (%s)', KeyPicker.Value, Info.Text or 'Keybind', KeyPicker.Mode);
            ContainerLabel.Visible = true;
            ContainerLabel.TextColor3 = State and Library.AccentColor or Library.FontColor;

            local YSize = 0
            local XSize = 0
            for _, Label in next, Library.KeybindContainer:GetChildren() do
                if Label:IsA('TextLabel') and Label.Visible then
                    YSize = YSize + 22;
                    if (Label.TextBounds.X > XSize) then XSize = Label.TextBounds.X end
                end;
            end;
            Library.KeybindFrame.Size = UDim2.new(0, math.max(XSize + 24, 200), 0, YSize + 36)
        end;

        function KeyPicker:GetState()
            if KeyPicker.Mode == 'Always' then
                return true;
            elseif KeyPicker.Mode == 'Hold' then
                if KeyPicker.Value == 'None' then return false end
                local Key = KeyPicker.Value;
                if Key == 'MB1' or Key == 'MB2' then
                    return Key == 'MB1' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                        or Key == 'MB2' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2);
                else
                    return InputService:IsKeyDown(Enum.KeyCode[KeyPicker.Value]);
                end;
            else
                return KeyPicker.Toggled;
            end;
        end;

        function KeyPicker:SetValue(Data)
            local Key, Mode = Data[1], Data[2];
            DisplayLabel.Text = Key;
            KeyPicker.Value = Key;
            KeyPicker.Mode = Mode or KeyPicker.Mode;
            KeyPicker:Update();
        end;

        function KeyPicker:OnClick(Callback) KeyPicker.Clicked = Callback end
        function KeyPicker:OnChanged(Callback) KeyPicker.Changed = Callback Callback(KeyPicker.Value) end

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, KeyPicker)
        end

        function KeyPicker:DoClick()
            if ParentObj.Type == 'Toggle' and KeyPicker.SyncToggleState then
                ParentObj:SetValue(not ParentObj.Value)
            end
            Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
            Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)
        end

        local Picking = false;
        PickOuter.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                Picking = true;
                DisplayLabel.Text = '...';

                local Event;
                Event = InputService.InputBegan:Connect(function(KeyInput)
                    local Key;
                    if KeyInput.UserInputType == Enum.UserInputType.Keyboard then
                        Key = KeyInput.KeyCode.Name;
                    elseif KeyInput.UserInputType == Enum.UserInputType.MouseButton1 then
                        Key = 'MB1';
                    elseif KeyInput.UserInputType == Enum.UserInputType.MouseButton2 then
                        Key = 'MB2';
                    end;
                    Picking = false;
                    DisplayLabel.Text = Key;
                    KeyPicker.Value = Key;
                    Library:SafeCallback(KeyPicker.ChangedCallback, KeyInput.KeyCode or KeyInput.UserInputType)
                    Library:SafeCallback(KeyPicker.Changed, KeyInput.KeyCode or KeyInput.UserInputType)
                    Library:AttemptSave();
                    Event:Disconnect();
                end);
            end;
        end);

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if (not Picking) then
                if KeyPicker.Mode == 'Toggle' then
                    local Key = KeyPicker.Value;
                    if Key == 'MB1' or Key == 'MB2' then
                        if Key == 'MB1' and Input.UserInputType == Enum.UserInputType.MouseButton1
                        or Key == 'MB2' and Input.UserInputType == Enum.UserInputType.MouseButton2 then
                            KeyPicker.Toggled = not KeyPicker.Toggled
                            KeyPicker:DoClick()
                        end;
                    elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                        if Input.KeyCode.Name == Key then
                            KeyPicker.Toggled = not KeyPicker.Toggled;
                            KeyPicker:DoClick()
                        end;
                    end;
                end;
                KeyPicker:Update();
            end;
        end))

        Library:GiveSignal(InputService.InputEnded:Connect(function(Input)
            if (not Picking) then KeyPicker:Update(); end;
        end))

        KeyPicker:Update();
        Options[Idx] = KeyPicker;
        return self;
    end;

    BaseAddons.__index = Funcs;
    BaseAddons.__namecall = function(Table, Key, ...) return Funcs[Key](...); end;
end;

local BaseGroupbox = {};
do
    local Funcs = {};

    function Funcs:AddBlank(Size)
        local Groupbox = self;
        Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, Size or 6);
            ZIndex = 1;
            Parent = Groupbox.Container;
        });
    end;

    function Funcs:AddDivider()
        local Groupbox = self;
        Library:Create('Frame', {
            BackgroundColor3 = Color3.fromRGB(36, 36, 46);
            BorderSizePixel = 0;
            Size = UDim2.new(1, -4, 0, 1);
            ZIndex = 4;
            Parent = Groupbox.Container;
        });
        Groupbox:AddBlank(4);
        Groupbox:Resize();
    end;

    function Funcs:AddLabel(Text, DoesWrap)
        local Label = {};
        local Groupbox = self;

        local TextLabel = Library:CreateLabel({
            Size = UDim2.new(1, -4, 0, 18);
            TextSize = 13;
            Text = Text;
            TextWrapped = DoesWrap or false,
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5;
            Parent = Groupbox.Container;
        });

        if DoesWrap then
            local Y = select(2, Library:GetTextBounds(Text, Library.Font, 13, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
            TextLabel.Size = UDim2.new(1, -4, 0, Y)
        else
            Library:Create('UIListLayout', {
                Padding = UDim.new(0, 6);
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Right;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = TextLabel;
            });
        end

        Label.TextLabel = TextLabel;
        Label.Container = Groupbox.Container;

        function Label:SetText(NewText)
            TextLabel.Text = NewText;
            if DoesWrap then
                local Y = select(2, Library:GetTextBounds(NewText, Library.Font, 13, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
                TextLabel.Size = UDim2.new(1, -4, 0, Y)
            end
            Groupbox:Resize();
        end

        if (not DoesWrap) then setmetatable(Label, BaseAddons) end
        Groupbox:AddBlank(4);
        Groupbox:Resize();
        return Label;
    end;

    function Funcs:AddButton(...)
        local Button = {};
        local Props = select(1, ...)
        if type(Props) == 'table' then
            Button.Text = Props.Text
            Button.Func = Props.Func
            Button.DoubleClick = Props.DoubleClick
            Button.Tooltip = Props.Tooltip
            Button.Risky = Props.Risky
            Button.Color = Props.Color
        else
            Button.Text = select(1, ...)
            Button.Func = select(2, ...)
        end

        assert(type(Button.Func) == 'function', 'AddButton: `Func` callback is missing.');

        local Groupbox = self;
        local Outer = Library:Create('Frame', {
            BackgroundColor3 = Color3.fromRGB(26, 26, 34);
            BorderColor3 = Color3.fromRGB(48, 48, 62);
            Size = UDim2.new(1, -4, 0, 28);
            ZIndex = 5;
            Parent = Groupbox.Container;
        });

        Library:Create('UICorner', {
            CornerRadius = UDim.new(0, 5),
            Parent = Outer
        })

        local Label = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = 13;
            Text = Button.Text;
            ZIndex = 6;
            Parent = Outer;
        });

        if Button.Color then
            Label.TextColor3 = Button.Color
        elseif Button.Risky then
            Label.TextColor3 = Library.RiskColor
        end

        Outer.MouseEnter:Connect(function()
            TweenService:Create(Outer, TweenInfo.new(0.18), { BackgroundColor3 = Color3.fromRGB(36, 36, 48) }):Play()
        end)
        Outer.MouseLeave:Connect(function()
            TweenService:Create(Outer, TweenInfo.new(0.18), { BackgroundColor3 = Color3.fromRGB(26, 26, 34) }):Play()
        end)

        Outer.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                TweenService:Create(Outer, TweenInfo.new(0.1), { BackgroundColor3 = Library.AccentColor }):Play()
                task.delay(0.12, function()
                    TweenService:Create(Outer, TweenInfo.new(0.18), { BackgroundColor3 = Color3.fromRGB(26, 26, 34) }):Play()
                end)
                Library:SafeCallback(Button.Func);
            end
        end)

        if type(Button.Tooltip) == 'string' then
            Library:AddToolTip(Button.Tooltip, Outer)
        end

        Button.Outer = Outer;
        Button.Label = Label;
        function Button:SetText(Text) Label.Text = Text; end

        Groupbox:AddBlank(5);
        Groupbox:Resize();
        return Button;
    end;

    --[[
        MODERN 20PX CHECKBOX TOGGLE WITH CHECKMARK ASSET & TWEEN ANIMATIONS
    ]]
    function Funcs:AddToggle(Idx, Info)
        assert(Info.Text, 'AddToggle: Missing `Text` string.')

        local Toggle = {
            Value = Info.Default or false;
            Type = 'Toggle';
            Callback = Info.Callback or function(Value) end;
            Addons = {},
            Risky = Info.Risky,
        };

        local Groupbox = self;
        local ToggleRow = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, -4, 0, 24);
            ZIndex = 5;
            Parent = Groupbox.Container;
        });

        -- 20x20 Checkbox
        local ToggleBox = Library:Create('Frame', {
            BackgroundColor3 = Toggle.Value and Library.AccentColor or Color3.fromRGB(26, 26, 34);
            BorderColor3 = Color3.fromRGB(48, 48, 62);
            Position = UDim2.new(0, 0, 0.5, -10);
            Size = UDim2.new(0, 20, 0, 20);
            ZIndex = 6;
            Parent = ToggleRow;
        });

        Library:Create('UICorner', {
            CornerRadius = UDim.new(0, 5),
            Parent = ToggleBox
        })

        local CheckmarkAsset = AssetManager:GetAsset("KittyWare/Assets/Images/checkmark.png")
        local CheckmarkIcon = Library:Create('ImageLabel', {
            BackgroundTransparency = 1;
            AnchorPoint = Vector2.new(0.5, 0.5);
            Position = UDim2.new(0.5, 0, 0.5, 0);
            Size = Toggle.Value and UDim2.new(0, 14, 0, 14) or UDim2.new(0, 0, 0, 0);
            Image = CheckmarkAsset;
            ImageColor3 = Color3.fromRGB(255, 255, 255);
            ImageTransparency = Toggle.Value and 0 or 1;
            ScaleType = Enum.ScaleType.Fit;
            ZIndex = 7;
            Parent = ToggleBox;
        });

        local ToggleLabel = Library:CreateLabel({
            Size = UDim2.new(1, -28, 1, 0);
            Position = UDim2.new(0, 28, 0, 0);
            TextSize = 13;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 6;
            Parent = ToggleRow;
        });

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 6);
            FillDirection = Enum.FillDirection.Horizontal;
            HorizontalAlignment = Enum.HorizontalAlignment.Right;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ToggleLabel;
        });

        ToggleRow.MouseEnter:Connect(function()
            if not Toggle.Value then
                TweenService:Create(ToggleBox, TweenInfo.new(0.18), { BorderColor3 = Library.AccentColor }):Play()
            end
        end)
        ToggleRow.MouseLeave:Connect(function()
            if not Toggle.Value then
                TweenService:Create(ToggleBox, TweenInfo.new(0.18), { BorderColor3 = Color3.fromRGB(48, 48, 62) }):Play()
            end
        end)

        function Toggle:Display()
            if Toggle.Value then
                TweenService:Create(ToggleBox, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundColor3 = Library.AccentColor,
                    BorderColor3 = Library.AccentColor
                }):Play()
                TweenService:Create(CheckmarkIcon, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, 14, 0, 14),
                    ImageTransparency = 0
                }):Play()
            else
                TweenService:Create(ToggleBox, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundColor3 = Color3.fromRGB(26, 26, 34),
                    BorderColor3 = Color3.fromRGB(48, 48, 62)
                }):Play()
                TweenService:Create(CheckmarkIcon, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, 0, 0, 0),
                    ImageTransparency = 1
                }):Play()
            end
        end;

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func;
            Func(Toggle.Value);
        end;

        function Toggle:SetValue(Bool)
            Bool = (not not Bool);
            Toggle.Value = Bool;
            Toggle:Display();

            for _, Addon in next, Toggle.Addons do
                if Addon.Type == 'KeyPicker' and Addon.SyncToggleState then
                    Addon.Toggled = Bool
                    Addon:Update()
                end
            end

            Library:SafeCallback(Toggle.Callback, Toggle.Value);
            Library:SafeCallback(Toggle.Changed, Toggle.Value);
            Library:UpdateDependencyBoxes();
        end;

        ToggleRow.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                Toggle:SetValue(not Toggle.Value)
                Library:AttemptSave();
            end;
        end);

        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, ToggleRow)
        end

        Toggle.TextLabel = ToggleLabel;
        Toggle.Container = Groupbox.Container;
        setmetatable(Toggle, BaseAddons);

        Toggles[Idx] = Toggle;
        Groupbox:AddBlank(4);
        Groupbox:Resize();
        return Toggle;
    end;

    --[[
        MODERN SMOOTH SLIDER WITH VALUE BADGE
    ]]
    function Funcs:AddSlider(Idx, Info)
        assert(Info.Default, 'AddSlider: Missing default value.');
        assert(Info.Text, 'AddSlider: Missing slider text.');
        assert(Info.Min, 'AddSlider: Missing minimum value.');
        assert(Info.Max, 'AddSlider: Missing maximum value.');
        assert(Info.Rounding, 'AddSlider: Missing rounding value.');

        local Slider = {
            Value = Info.Default;
            Min = Info.Min;
            Max = Info.Max;
            Rounding = Info.Rounding;
            Format = Info.Format or (Info.Suffix and ('%s ' .. Info.Suffix) or '%s');
            Type = 'Slider';
            Callback = Info.Callback or function(Value) end;
        };

        local Groupbox = self;
        local SliderHolder = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, -4, 0, 38);
            ZIndex = 5;
            Parent = Groupbox.Container;
        });

        local Label = Library:CreateLabel({
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(0.65, 0, 0, 16);
            TextSize = 13;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 6;
            Parent = SliderHolder;
        });

        local ValueBadge = Library:Create('Frame', {
            BackgroundColor3 = Color3.fromRGB(26, 26, 34);
            BorderColor3 = Color3.fromRGB(46, 46, 58);
            Position = UDim2.new(1, -60, 0, 0);
            Size = UDim2.new(0, 60, 0, 18);
            ZIndex = 6;
            Parent = SliderHolder;
        });

        Library:Create('UICorner', {
            CornerRadius = UDim.new(0, 4),
            Parent = ValueBadge
        })

        local ValueLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = 11;
            Text = string.format(Slider.Format, Slider.Value);
            TextColor3 = Library.AccentColor;
            TextXAlignment = Enum.TextXAlignment.Center;
            ZIndex = 7;
            Parent = ValueBadge;
        });

        local TrackOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.fromRGB(26, 26, 34);
            BorderColor3 = Color3.fromRGB(46, 46, 58);
            Position = UDim2.new(0, 0, 0, 24);
            Size = UDim2.new(1, 0, 0, 8);
            ZIndex = 6;
            Parent = SliderHolder;
        });

        Library:Create('UICorner', {
            CornerRadius = UDim.new(0, 4),
            Parent = TrackOuter
        })

        local Fill = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Size = UDim2.new((Slider.Value - Slider.Min) / (Slider.Max - Slider.Min), 0, 1, 0);
            ZIndex = 7;
            Parent = TrackOuter;
        });

        Library:Create('UICorner', {
            CornerRadius = UDim.new(0, 4),
            Parent = Fill
        })

        function Slider:Display()
            ValueLabel.Text = string.format(Slider.Format, Slider.Value);
            local frac = math.clamp((Slider.Value - Slider.Min) / (Slider.Max - Slider.Min), 0, 1)
            TweenService:Create(Fill, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(frac, 0, 1, 0)
            }):Play()
            Library:SafeCallback(Slider.Callback, Slider.Value);
            Library:SafeCallback(Slider.Changed, Slider.Value);
        end;

        function Slider:SetValue(Val)
            Val = math.clamp(Val, Slider.Min, Slider.Max);
            if Slider.Rounding == 0 then
                Val = math.floor(Val + 0.5);
            else
                local mult = 10 ^ Slider.Rounding;
                Val = math.floor(Val * mult + 0.5) / mult;
            end;
            Slider.Value = Val;
            Slider:Display();
        end;

        function Slider:OnChanged(Func)
            Slider.Changed = Func;
            Func(Slider.Value);
        end;

        TrackOuter.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local MinX = TrackOuter.AbsolutePosition.X;
                    local MaxX = MinX + TrackOuter.AbsoluteSize.X;
                    local MouseX = math.clamp(Mouse.X, MinX, MaxX);
                    local frac = (MouseX - MinX) / (MaxX - MinX);
                    Slider:SetValue(Slider.Min + (Slider.Max - Slider.Min) * frac);
                    RenderStepped:Wait();
                end;
                Library:AttemptSave();
            end;
        end);

        Options[Idx] = Slider;
        Groupbox:AddBlank(4);
        Groupbox:Resize();
        return Slider;
    end;

    --[[
        MODERN ACCORDION DROPDOWN WITH CHEVRON ANIMATION
    ]]
    function Funcs:AddDropdown(Idx, Info)
        assert(Info.Values, 'AddDropdown: Missing `Values` table.');

        local Dropdown = {
            Values = Info.Values;
            Value = Info.Default or (Info.Multi and {} or Info.Values[1]);
            Multi = Info.Multi or false;
            Type = 'Dropdown';
            Callback = Info.Callback or function(Value) end;
        };

        local Groupbox = self;
        local DropdownHolder = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, -4, 0, Info.Text and 46 or 30);
            ZIndex = 5;
            Parent = Groupbox.Container;
        });

        if Info.Text then
            Library:CreateLabel({
                Position = UDim2.new(0, 0, 0, 0);
                Size = UDim2.new(1, 0, 0, 14);
                TextSize = 13;
                Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                ZIndex = 6;
                Parent = DropdownHolder;
            });
        end

        local DropdownBox = Library:Create('Frame', {
            BackgroundColor3 = Color3.fromRGB(24, 24, 32);
            BorderColor3 = Color3.fromRGB(46, 46, 58);
            Position = UDim2.new(0, 0, 0, Info.Text and 16 or 0);
            Size = UDim2.new(1, 0, 0, 28);
            ZIndex = 6;
            Parent = DropdownHolder;
        });

        Library:Create('UICorner', {
            CornerRadius = UDim.new(0, 5),
            Parent = DropdownBox
        })

        local DisplayLabel = Library:CreateLabel({
            Position = UDim2.new(0, 10, 0, 0);
            Size = UDim2.new(1, -30, 1, 0);
            TextSize = 12;
            Text = '';
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 7;
            Parent = DropdownBox;
        });

        local ArrowAsset = AssetManager:GetAsset("KittyWare/Assets/Images/down_arrow.png")
        local DropdownArrow = Library:Create('ImageLabel', {
            BackgroundTransparency = 1;
            AnchorPoint = Vector2.new(0.5, 0.5);
            Position = UDim2.new(1, -14, 0.5, 0);
            Size = UDim2.new(0, 10, 0, 10);
            Image = ArrowAsset;
            ImageColor3 = Library.FontColor;
            ScaleType = Enum.ScaleType.Fit;
            ZIndex = 7;
            Parent = DropdownBox;
        });

        local ListOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.fromRGB(18, 18, 24);
            BorderColor3 = Color3.fromRGB(48, 48, 62);
            Size = UDim2.new(1, 0, 0, 0);
            Visible = false;
            ZIndex = 100;
            Parent = ScreenGui;
        });

        Library:Create('UICorner', {
            CornerRadius = UDim.new(0, 6),
            Parent = ListOuter
        })

        local ListScrolling = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Size = UDim2.new(1, -2, 1, -2);
            Position = UDim2.new(0, 1, 0, 1);
            ScrollBarThickness = 2;
            ScrollBarImageColor3 = Library.AccentColor;
            ZIndex = 101;
            Parent = ListOuter;
        });

        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ListScrolling;
        });

        local function RecalculateListPosition()
            ListOuter.Position = UDim2.fromOffset(DropdownBox.AbsolutePosition.X, DropdownBox.AbsolutePosition.Y + 30);
            ListOuter.Size = UDim2.fromOffset(DropdownBox.AbsoluteSize.X, math.min(#Dropdown.Values * 26 + 6, 160));
            ListScrolling.CanvasSize = UDim2.fromOffset(0, #Dropdown.Values * 26 + 6);
        end

        DropdownBox:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            if ListOuter.Visible then RecalculateListPosition() end
        end)

        function Dropdown:Display()
            if Dropdown.Multi then
                local selected = {}
                for k, v in pairs(Dropdown.Value) do
                    if v then table.insert(selected, k) end
                end
                DisplayLabel.Text = #selected > 0 and table.concat(selected, ', ') or 'None'
            else
                DisplayLabel.Text = tostring(Dropdown.Value or 'None')
            end
        end

        function Dropdown:BuildList()
            for _, child in ipairs(ListScrolling:GetChildren()) do
                if not child:IsA('UIListLayout') then child:Destroy() end
            end

            for _, val in ipairs(Dropdown.Values) do
                local ItemBtn = Library:Create('Frame', {
                    BackgroundColor3 = Color3.fromRGB(22, 22, 28);
                    BorderSizePixel = 0;
                    Size = UDim2.new(1, 0, 0, 26);
                    ZIndex = 102;
                    Parent = ListScrolling;
                });

                local isSelected = Dropdown.Multi and Dropdown.Value[val] or (Dropdown.Value == val)

                local ItemLabel = Library:CreateLabel({
                    Position = UDim2.new(0, 10, 0, 0);
                    Size = UDim2.new(1, -20, 1, 0);
                    TextSize = 12;
                    Text = tostring(val);
                    TextColor3 = isSelected and Library.AccentColor or Library.FontColor;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    ZIndex = 103;
                    Parent = ItemBtn;
                });

                ItemBtn.MouseEnter:Connect(function()
                    TweenService:Create(ItemBtn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(34, 34, 46) }):Play()
                end)
                ItemBtn.MouseLeave:Connect(function()
                    TweenService:Create(ItemBtn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(22, 22, 28) }):Play()
                end)

                ItemBtn.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if Dropdown.Multi then
                            Dropdown.Value[val] = not Dropdown.Value[val]
                        else
                            Dropdown.Value = val
                            Dropdown:Close()
                        end
                        Dropdown:Display()
                        Dropdown:BuildList()
                        Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                        Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
                        Library:AttemptSave()
                    end
                end)
            end
        end

        function Dropdown:Open()
            RecalculateListPosition()
            ListOuter.Visible = true
            Library.OpenedFrames[ListOuter] = true
            TweenService:Create(DropdownArrow, TweenInfo.new(0.2), { Rotation = 180 }):Play()
        end

        function Dropdown:Close()
            ListOuter.Visible = false
            Library.OpenedFrames[ListOuter] = nil
            TweenService:Create(DropdownArrow, TweenInfo.new(0.2), { Rotation = 0 }):Play()
        end

        DropdownBox.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                if ListOuter.Visible then Dropdown:Close() else Dropdown:Open() end
            end
        end)

        function Dropdown:SetValue(Val)
            Dropdown.Value = Val
            Dropdown:Display()
            Dropdown:BuildList()
        end

        function Dropdown:SetValues(NewVals)
            Dropdown.Values = NewVals
            Dropdown:BuildList()
        end

        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func;
            Func(Dropdown.Value);
        end

        Dropdown:Display()
        Dropdown:BuildList()

        Options[Idx] = Dropdown;
        Groupbox:AddBlank(4);
        Groupbox:Resize();
        return Dropdown;
    end;

    function Funcs:AddInput(Idx, Info)
        assert(Info.Text, 'AddInput: Missing `Text` string.');

        local Textbox = {
            Value = Info.Default or '';
            Numeric = Info.Numeric or false;
            Finished = Info.Finished or false;
            Type = 'Input';
            Callback = Info.Callback or function(Value) end;
        };

        local Groupbox = self;
        local BoxHolder = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, -4, 0, 46);
            ZIndex = 5;
            Parent = Groupbox.Container;
        });

        Library:CreateLabel({
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 0, 14);
            TextSize = 13;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 6;
            Parent = BoxHolder;
        });

        local Box = Library:Create('TextBox', {
            BackgroundColor3 = Color3.fromRGB(24, 24, 32);
            BorderColor3 = Color3.fromRGB(46, 46, 58);
            Position = UDim2.new(0, 0, 0, 16);
            Size = UDim2.new(1, 0, 0, 28);
            FontFace = Library.CustomFont;
            Font = Enum.Font.GothamBold;
            TextSize = 12;
            TextColor3 = Library.FontColor;
            Text = Textbox.Value;
            PlaceholderText = Info.Placeholder or '';
            TextXAlignment = Enum.TextXAlignment.Left;
            ClearTextOnFocus = false;
            ZIndex = 6;
            Parent = BoxHolder;
        });

        Library:Create('UICorner', {
            CornerRadius = UDim.new(0, 5),
            Parent = Box
        })

        Library:Create('UIPadding', {
            PaddingLeft = UDim.new(0, 10);
            Parent = Box
        })

        Box.FocusLost:Connect(function(enter)
            Textbox.Value = Box.Text
            Library:SafeCallback(Textbox.Callback, Textbox.Value)
            Library:SafeCallback(Textbox.Changed, Textbox.Value)
            Library:AttemptSave()
        end)

        function Textbox:SetValue(Val)
            Textbox.Value = tostring(Val)
            Box.Text = Textbox.Value
        end

        function Textbox:OnChanged(Func)
            Textbox.Changed = Func
            Func(Textbox.Value)
        end

        Options[Idx] = Textbox
        Groupbox:AddBlank(4);
        Groupbox:Resize();
        return Textbox;
    end;

    function Funcs:AddDependencyBox()
        local Depbox = { Dependencies = {} };
        local Groupbox = self;

        local Holder = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, 0);
            Visible = false;
            ZIndex = 1;
            Parent = Groupbox.Container;
        });

        local Frame = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 1, 0);
            Visible = true;
            ZIndex = 1;
            Parent = Holder;
        });

        local Layout = Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Frame;
        });

        function Depbox:Resize()
            Holder.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y);
            Groupbox:Resize();
        end;

        Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
            Depbox:Resize();
        end);

        function Depbox:Update()
            for _, Dependency in next, Depbox.Dependencies do
                local Elem = Dependency[1];
                local Value = Dependency[2];
                if Elem.Type == 'Toggle' and Elem.Value ~= Value then
                    Holder.Visible = false;
                    Depbox:Resize();
                    return;
                end;
            end;
            Holder.Visible = true;
            Depbox:Resize();
        end;

        function Depbox:SetupDependencies(Dependencies)
            Depbox.Dependencies = Dependencies;
            Depbox:Update();
        end;

        Depbox.Container = Frame;
        setmetatable(Depbox, BaseGroupbox);
        table.insert(Library.DependencyBoxes, Depbox);
        return Depbox;
    end;

    BaseGroupbox.__index = Funcs;
    BaseGroupbox.__namecall = function(Table, Key, ...) return Funcs[Key](...); end;
end;

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                   WATERMARK, KEYBINDS & NOTIFICATION AREA                 ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

do
    Library.NotificationArea = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 20, 0, 40);
        Size = UDim2.new(0, 320, 0, 200);
        ZIndex = 100;
        Parent = ScreenGui;
    });

    Library:Create('UIListLayout', {
        Padding = UDim.new(0, 6);
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = Library.NotificationArea;
    });

    -- Modern Floating Watermark Pill
    local WatermarkOuter = Library:Create('Frame', {
        BackgroundColor3 = Color3.fromRGB(16, 16, 22);
        BorderColor3 = Color3.fromRGB(42, 42, 54);
        Position = UDim2.new(0, 24, 0, 24);
        Size = UDim2.new(0, 0, 0, 30);
        AutomaticSize = Enum.AutomaticSize.X;
        ZIndex = 200;
        Visible = false;
        Parent = ScreenGui;
    });

    Library:Create('UICorner', {
        CornerRadius = UDim.new(0, 6),
        Parent = WatermarkOuter
    })

    local WatermarkStripe = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, 0, 0, 2);
        ZIndex = 201;
        Parent = WatermarkOuter;
    });

    Library:Create('UIListLayout', {
        FillDirection = Enum.FillDirection.Horizontal;
        VerticalAlignment = Enum.VerticalAlignment.Center;
        HorizontalAlignment = Enum.HorizontalAlignment.Left;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Padding = UDim.new(0, 8);
        Parent = WatermarkOuter;
    });

    Library:Create('UIPadding', {
        PaddingLeft = UDim.new(0, 12);
        PaddingRight = UDim.new(0, 12);
        PaddingTop = UDim.new(0, 2);
        Parent = WatermarkOuter;
    });

    local PersonIconAsset = AssetManager:GetAsset("KittyWare/Assets/Images/person.png");
    local ComputerIconAsset = AssetManager:GetAsset("KittyWare/Assets/Images/computer.png");
    local LatencyIconAsset = AssetManager:GetAsset("KittyWare/Assets/Images/latency.png");
    local ClockIconAsset = AssetManager:GetAsset("KittyWare/Assets/Images/clock.png");

    local function createWatermarkIcon(asset, order)
        local icon = Library:Create('ImageLabel', {
            BackgroundTransparency = 1;
            Size = UDim2.new(0, 14, 0, 14);
            Image = asset;
            ImageColor3 = Library.AccentColor;
            ScaleType = Enum.ScaleType.Fit;
            LayoutOrder = order;
            ZIndex = 202;
            Parent = WatermarkOuter;
        });
        return icon;
    end

    local function createWatermarkLabel(text, order, color)
        local lbl = Library:CreateLabel({
            BackgroundTransparency = 1;
            Size = UDim2.new(0, 0, 1, 0);
            AutomaticSize = Enum.AutomaticSize.X;
            Text = text;
            TextColor3 = color or Library.FontColor;
            TextSize = 12;
            TextXAlignment = Enum.TextXAlignment.Left;
            TextYAlignment = Enum.TextYAlignment.Center;
            LayoutOrder = order;
            ZIndex = 203;
            Parent = WatermarkOuter;
        }, true);
        return lbl;
    end

    createWatermarkIcon(PersonIconAsset, 1);
    local UserLabel = createWatermarkLabel(LocalPlayer.Name or "aj6886", 2);
    createWatermarkLabel("|", 3, Color3.fromRGB(75, 75, 90));

    createWatermarkIcon(ComputerIconAsset, 4);
    local FPSLabel = createWatermarkLabel("60 fps", 5);
    createWatermarkLabel("|", 6, Color3.fromRGB(75, 75, 90));

    createWatermarkIcon(LatencyIconAsset, 7);
    local PingLabel = createWatermarkLabel("24 ms", 8);
    createWatermarkLabel("|", 9, Color3.fromRGB(75, 75, 90));

    createWatermarkIcon(ClockIconAsset, 10);
    local ClockLabel = createWatermarkLabel(os.date("%H:%M:%S"), 11);

    local FrameTimer = tick()
    local FrameCounter = 0
    local CurrentFPS = 60

    table.insert(Library.Signals, RenderStepped:Connect(function()
        FrameCounter = FrameCounter + 1
        local now = tick()
        if (now - FrameTimer) >= 0.5 then
            CurrentFPS = math.floor(FrameCounter / (now - FrameTimer))
            FrameCounter = 0
            FrameTimer = now
            if FPSLabel then FPSLabel.Text = string.format("%d fps", CurrentFPS) end
            if PingLabel then
                local pingVal = 0.04
                pcall(function()
                    local p = LocalPlayer:GetNetworkPing()
                    if p and p > 0 then pingVal = p end
                end)
                PingLabel.Text = string.format("%d ms", math.floor(pingVal * 1000))
            end
        end
        if ClockLabel then ClockLabel.Text = os.date("%H:%M:%S") end
    end))

    Library.Watermark = WatermarkOuter;
    Library.WatermarkUserLabel = UserLabel;
    Library:MakeDraggable(Library.Watermark);

    -- Modern Keybinds Box
    local KeybindOuter = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0, 0.5);
        BackgroundColor3 = Color3.fromRGB(16, 16, 22);
        BorderColor3 = Color3.fromRGB(42, 42, 54);
        Position = UDim2.new(0, 24, 0.5, 0);
        Size = UDim2.new(0, 200, 0, 30);
        Visible = false;
        ZIndex = 100;
        Parent = ScreenGui;
    });

    Library:Create('UICorner', {
        CornerRadius = UDim.new(0, 6),
        Parent = KeybindOuter
    })

    local KeybindStripe = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Size = UDim2.new(1, 0, 0, 2);
        ZIndex = 101;
        Parent = KeybindOuter;
    });

    local HeaderFrame = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Size = UDim2.new(1, 0, 0, 26);
        Position = UDim2.new(0, 0, 0, 2);
        ZIndex = 102;
        Parent = KeybindOuter;
    });

    Library:Create('UIListLayout', {
        FillDirection = Enum.FillDirection.Horizontal;
        VerticalAlignment = Enum.VerticalAlignment.Center;
        Padding = UDim.new(0, 8);
        Parent = HeaderFrame;
    });

    Library:Create('UIPadding', {
        PaddingLeft = UDim.new(0, 10);
        Parent = HeaderFrame;
    });

    local KeyboardIconAsset = AssetManager:GetAsset("KittyWare/Assets/Images/keyboard.png");
    Library:Create('ImageLabel', {
        BackgroundTransparency = 1;
        Size = UDim2.new(0, 14, 0, 14);
        Image = KeyboardIconAsset;
        ImageColor3 = Library.AccentColor;
        ScaleType = Enum.ScaleType.Fit;
        ZIndex = 103;
        Parent = HeaderFrame;
    });

    Library:CreateLabel({
        Size = UDim2.new(0, 0, 1, 0);
        AutomaticSize = Enum.AutomaticSize.X;
        TextXAlignment = Enum.TextXAlignment.Left;
        TextYAlignment = Enum.TextYAlignment.Center;
        Text = 'Active Keybinds';
        TextSize = 12;
        ZIndex = 103;
        Parent = HeaderFrame;
    });

    local KeybindContainer = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Size = UDim2.new(1, 0, 1, -28);
        Position = UDim2.new(0, 0, 0, 28);
        ZIndex = 102;
        Parent = KeybindOuter;
    });

    Library:Create('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = KeybindContainer;
    });

    Library:Create('UIPadding', {
        PaddingLeft = UDim.new(0, 10);
        PaddingRight = UDim.new(0, 10);
        PaddingTop = UDim.new(0, 4);
        PaddingBottom = UDim.new(0, 4);
        Parent = KeybindContainer;
    });

    Library.KeybindFrame = KeybindOuter;
    Library.KeybindContainer = KeybindContainer;
    Library:MakeDraggable(KeybindOuter);
end;

function Library:SetWatermarkVisibility(Bool)
    Library.Watermark.Visible = Bool;
end;

function Library:SetWatermark(Text)
    if Library.WatermarkUserLabel and Text and Text ~= "" then
        Library.WatermarkUserLabel.Text = tostring(Text);
    end;
    Library:SetWatermarkVisibility(true);
end;

function Library:Notify(Text, Time)
    local XSize, YSize = Library:GetTextBounds(Text, Library.Font, 13);
    YSize = YSize + 16

    local NotifyOuter = Library:Create('Frame', {
        BackgroundColor3 = Color3.fromRGB(20, 20, 26);
        BorderColor3 = Color3.fromRGB(45, 45, 58);
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(0, 0, 0, YSize);
        ClipsDescendants = true;
        ZIndex = 150;
        Parent = Library.NotificationArea;
    });

    Library:Create('UICorner', {
        CornerRadius = UDim.new(0, 6),
        Parent = NotifyOuter
    })

    local LeftColor = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Size = UDim2.new(0, 3, 1, 0);
        ZIndex = 151;
        Parent = NotifyOuter;
    });

    local NotifyLabel = Library:CreateLabel({
        Position = UDim2.new(0, 12, 0, 0);
        Size = UDim2.new(1, -16, 1, 0);
        Text = Text;
        TextXAlignment = Enum.TextXAlignment.Left;
        TextSize = 13;
        ZIndex = 152;
        Parent = NotifyOuter;
    });

    pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, XSize + 28, 0, YSize), 'Out', 'Quad', 0.35, true);

    task.spawn(function()
        wait(Time or 4);
        pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, 0, 0, YSize), 'Out', 'Quad', 0.35, true);
        wait(0.4);
        NotifyOuter:Destroy();
    end);
end;

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║        NEXT-GEN LANDSCAPE WINDOW (880x560) & 40PX CAPSULE TABS WITH ICONS ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

function Library:CreateWindow(...)
    local Arguments = { ... }
    local Config = { AnchorPoint = Vector2.zero }

    if type(...) == 'table' then
        Config = ...;
    else
        Config.Title = Arguments[1]
        Config.AutoShow = Arguments[2] or false;
    end

    if type(Config.Title) ~= 'string' then Config.Title = 'KittyWare' end
    if type(Config.TabPadding) ~= 'number' then Config.TabPadding = 8 end
    if type(Config.MenuFadeTime) ~= 'number' then Config.MenuFadeTime = 0.2 end

    -- Generous landscape proportions (880 x 560)
    if typeof(Config.Position) ~= 'UDim2' then Config.Position = UDim2.fromOffset(80, 40) end
    if typeof(Config.Size) ~= 'UDim2' then Config.Size = UDim2.fromOffset(880, 560) end

    if Config.Center then
        Config.AnchorPoint = Vector2.new(0.5, 0.5)
        Config.Position = UDim2.fromScale(0.5, 0.5)
    end

    local Window = {
        Tabs = {};
    };

    -- Outer Window Canvas
    local Outer = Library:Create('Frame', {
        AnchorPoint = Config.AnchorPoint,
        BackgroundColor3 = Color3.fromRGB(14, 14, 18);
        BorderColor3 = Color3.fromRGB(36, 36, 48);
        Position = Config.Position,
        Size = Config.Size,
        Visible = false,
        ZIndex = 1,
        Parent = ScreenGui;
    });

    Library:Create('UICorner', {
        CornerRadius = UDim.new(0, 8),
        Parent = Outer
    })

    Library:MakeDraggable(Outer, 50);

    -- Top Accent Glow Stripe
    local TopAccent = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Size = UDim2.new(1, 0, 0, 2);
        ZIndex = 2;
        Parent = Outer;
    });

    Library:Create('UICorner', {
        CornerRadius = UDim.new(0, 8),
        Parent = TopAccent
    })

    -- Header Bar
    local HeaderBar = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 18, 0, 2);
        Size = UDim2.new(1, -36, 0, 44);
        ZIndex = 2;
        Parent = Outer;
    });

    -- Brand Glow Dot
    local BrandDot = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Position = UDim2.new(0, 0, 0.5, -4);
        Size = UDim2.new(0, 8, 0, 8);
        ZIndex = 3;
        Parent = HeaderBar;
    });

    Library:Create('UICorner', {
        CornerRadius = UDim.new(1, 0),
        Parent = BrandDot
    })

    local WindowLabel = Library:CreateLabel({
        Position = UDim2.new(0, 16, 0, 0);
        Size = UDim2.new(0.5, 0, 1, 0);
        Text = Config.Title or 'KittyWare';
        TextSize = 15;
        TextXAlignment = Enum.TextXAlignment.Left;
        TextYAlignment = Enum.TextYAlignment.Center;
        ZIndex = 3;
        Parent = HeaderBar;
    });

    local StatusLabel = Library:CreateLabel({
        Position = UDim2.new(0.5, 0, 0, 0);
        Size = UDim2.new(0.5, 0, 1, 0);
        RichText = true;
        Text = '<font color="rgb(90,255,140)">● Undetected</font> <font color="rgb(160,160,175)">v2.5</font>';
        TextSize = 12;
        TextXAlignment = Enum.TextXAlignment.Right;
        TextYAlignment = Enum.TextYAlignment.Center;
        ZIndex = 3;
        Parent = HeaderBar;
    });

    -- Navigation Bar (Tabs Area) - 40px Height
    local NavContainer = Library:Create('Frame', {
        BackgroundColor3 = Color3.fromRGB(18, 18, 24);
        BorderColor3 = Color3.fromRGB(34, 34, 44);
        Position = UDim2.new(0, 18, 0, 48);
        Size = UDim2.new(1, -36, 0, 40);
        ZIndex = 2;
        Parent = Outer;
    });

    Library:Create('UICorner', {
        CornerRadius = UDim.new(0, 6),
        Parent = NavContainer
    })

    local TabArea = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 6, 0, 4);
        Size = UDim2.new(1, -12, 1, -8);
        ZIndex = 3;
        Parent = NavContainer;
    });

    Library:Create('UIListLayout', {
        Padding = UDim.new(0, 8);
        FillDirection = Enum.FillDirection.Horizontal;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = TabArea;
    });

    -- Content Body Area
    local TabContainer = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 18, 0, 96);
        Size = UDim2.new(1, -36, 1, -108);
        ZIndex = 2;
        Parent = Outer;
    });

    function Window:SetWindowTitle(Title)
        WindowLabel.Text = Title;
    end;

    local TAB_ICONS = {
        ['Combat'] = 'aim.png',
        ['Rage'] = 'aim.png',
        ['Visuals'] = 'terrain.png',
        ['ESP'] = 'terrain.png',
        ['Misc'] = 'bolt.png',
        ['Movement'] = 'bolt.png',
        ['UI Settings'] = 'cog.png',
        ['Settings'] = 'cog.png',
        ['Themes'] = 'paintbrush.png'
    }

    function Window:AddTab(Name, CustomIcon)
        local Tab = {
            Groupboxes = {};
            Tabboxes = {};
        };

        local iconFileName = CustomIcon or TAB_ICONS[Name] or 'cog.png'
        local iconAsset = AssetManager:GetAsset(iconFileName)
        local TabButtonWidth = Library:GetTextBounds(Name, Library.Font, 13);

        -- Capsule Tab Button with Icon
        local TabButton = Library:Create('Frame', {
            BackgroundColor3 = Color3.fromRGB(24, 24, 32);
            BorderSizePixel = 0;
            Size = UDim2.new(0, TabButtonWidth + 44, 1, 0);
            ZIndex = 4;
            Parent = TabArea;
        });

        Library:Create('UICorner', {
            CornerRadius = UDim.new(0, 6),
            Parent = TabButton
        })

        local TabIcon = Library:Create('ImageLabel', {
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 10, 0.5, -8);
            Size = UDim2.new(0, 16, 0, 16);
            Image = iconAsset;
            ImageColor3 = Color3.fromRGB(160, 160, 175);
            ScaleType = Enum.ScaleType.Fit;
            ZIndex = 5;
            Parent = TabButton;
        });

        local TabText = Library:CreateLabel({
            Position = UDim2.new(0, 32, 0, 0);
            Size = UDim2.new(1, -36, 1, 0);
            TextSize = 13;
            Text = Name;
            TextColor3 = Color3.fromRGB(160, 160, 175);
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5;
            Parent = TabButton;
        });

        local TabFrame = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 1, 0);
            Visible = false;
            ZIndex = 2;
            Parent = TabContainer;
        });

        local LeftSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(0.5, -8, 1, 0);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            ScrollBarThickness = 2;
            ScrollBarImageColor3 = Library.AccentColor;
            ZIndex = 2;
            Parent = TabFrame;
        });

        local RightSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0.5, 8, 0, 0);
            Size = UDim2.new(0.5, -8, 1, 0);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            ScrollBarThickness = 2;
            ScrollBarImageColor3 = Library.AccentColor;
            ZIndex = 2;
            Parent = TabFrame;
        });

        local LeftLayout = Library:Create('UIListLayout', {
            Padding = UDim.new(0, 12);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = LeftSide;
        });

        local RightLayout = Library:Create('UIListLayout', {
            Padding = UDim.new(0, 12);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = RightSide;
        });

        LeftLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
            LeftSide.CanvasSize = UDim2.fromOffset(0, LeftLayout.AbsoluteContentSize.Y + 12);
        end);

        RightLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
            RightSide.CanvasSize = UDim2.fromOffset(0, RightLayout.AbsoluteContentSize.Y + 12);
        end);

        function Tab:ShowTab()
            for _, OtherTab in next, Window.Tabs do
                OtherTab:HideTab();
            end;

            TweenService:Create(TabButton, TweenInfo.new(0.2), { BackgroundColor3 = Library.AccentColor }):Play();
            TweenService:Create(TabText, TweenInfo.new(0.2), { TextColor3 = Color3.fromRGB(255, 255, 255) }):Play();
            TweenService:Create(TabIcon, TweenInfo.new(0.2), { ImageColor3 = Color3.fromRGB(255, 255, 255) }):Play();
            TabFrame.Visible = true;
        end;

        function Tab:HideTab()
            TweenService:Create(TabButton, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(24, 24, 32) }):Play();
            TweenService:Create(TabText, TweenInfo.new(0.2), { TextColor3 = Color3.fromRGB(160, 160, 175) }):Play();
            TweenService:Create(TabIcon, TweenInfo.new(0.2), { ImageColor3 = Color3.fromRGB(160, 160, 175) }):Play();
            TabFrame.Visible = false;
        end;

        TabButton.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                Tab:ShowTab();
            end;
        end);

        TabButton.MouseEnter:Connect(function()
            if not TabFrame.Visible then
                TweenService:Create(TabButton, TweenInfo.new(0.18), { BackgroundColor3 = Color3.fromRGB(34, 34, 46) }):Play();
                TweenService:Create(TabText, TweenInfo.new(0.18), { TextColor3 = Color3.fromRGB(225, 225, 240) }):Play();
                TweenService:Create(TabIcon, TweenInfo.new(0.18), { ImageColor3 = Color3.fromRGB(225, 225, 240) }):Play();
            end
        end)
        TabButton.MouseLeave:Connect(function()
            if not TabFrame.Visible then
                TweenService:Create(TabButton, TweenInfo.new(0.18), { BackgroundColor3 = Color3.fromRGB(24, 24, 32) }):Play();
                TweenService:Create(TabText, TweenInfo.new(0.18), { TextColor3 = Color3.fromRGB(160, 160, 175) }):Play();
                TweenService:Create(TabIcon, TweenInfo.new(0.18), { ImageColor3 = Color3.fromRGB(160, 160, 175) }):Play();
            end
        end)

        -- Modern Card Groupbox
        function Tab:AddGroupbox(Info)
            local Groupbox = {};

            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Color3.fromRGB(20, 20, 26);
                BorderColor3 = Color3.fromRGB(38, 38, 50);
                Size = UDim2.new(1, 0, 0, 0);
                ZIndex = 2;
                Parent = Info.Side == 1 and LeftSide or RightSide;
            });

            Library:Create('UICorner', {
                CornerRadius = UDim.new(0, 8),
                Parent = BoxOuter
            })

            local Header = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, -24, 0, 30);
                Position = UDim2.new(0, 12, 0, 2);
                ZIndex = 3;
                Parent = BoxOuter;
            });

            -- Groupbox Accent Bar
            local GroupboxAccent = Library:Create('Frame', {
                BackgroundColor3 = Library.AccentColor;
                BorderSizePixel = 0;
                Position = UDim2.new(0, 0, 0.5, -6);
                Size = UDim2.new(0, 3, 0, 12);
                ZIndex = 4;
                Parent = Header;
            });

            Library:Create('UICorner', {
                CornerRadius = UDim.new(0, 2),
                Parent = GroupboxAccent
            })

            Library:CreateLabel({
                Position = UDim2.new(0, 10, 0, 0);
                Size = UDim2.new(1, -10, 1, 0);
                Text = Info.Name or 'Groupbox';
                TextSize = 13;
                TextColor3 = Color3.fromRGB(230, 230, 245);
                TextXAlignment = Enum.TextXAlignment.Left;
                ZIndex = 4;
                Parent = Header;
            });

            local Divider = Library:Create('Frame', {
                BackgroundColor3 = Color3.fromRGB(32, 32, 42);
                BorderSizePixel = 0;
                Position = UDim2.new(0, 12, 0, 30);
                Size = UDim2.new(1, -24, 0, 1);
                ZIndex = 3;
                Parent = BoxOuter;
            });

            local Container = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 12, 0, 36);
                Size = UDim2.new(1, -24, 1, -42);
                ZIndex = 4;
                Parent = BoxOuter;
            });

            local Layout = Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = Container;
            });

            function Groupbox:Resize()
                BoxOuter.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y + 46);
            end;

            Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                Groupbox:Resize();
            end);

            Groupbox.Container = Container;
            setmetatable(Groupbox, BaseGroupbox);

            Groupbox:AddBlank(4);
            Groupbox:Resize();
            return Groupbox;
        end;

        function Tab:AddLeftGroupbox(Name) return Tab:AddGroupbox({ Side = 1, Name = Name }); end;
        function Tab:AddRightGroupbox(Name) return Tab:AddGroupbox({ Side = 2, Name = Name }); end;
        function Tab:AddTabbox(Info) return Tab:AddGroupbox(Info); end;
        function Tab:AddLeftTabbox() return Tab:AddGroupbox({ Side = 1, Name = "Tabbox" }); end;
        function Tab:AddRightTabbox() return Tab:AddGroupbox({ Side = 2, Name = "Tabbox" }); end;

        table.insert(Window.Tabs, Tab);
        if #Window.Tabs == 1 then Tab:ShowTab(); end;

        return Tab;
    end;

    local Toggled = false;
    local Fading = false;

    function Library:Toggle()
        if Fading then return end;
        Fading = true;
        Toggled = not Toggled;

        if Toggled then
            Outer.Visible = true;
            TweenService:Create(Outer, TweenInfo.new(Config.MenuFadeTime), { BackgroundTransparency = 0 }):Play();
        else
            local tw = TweenService:Create(Outer, TweenInfo.new(Config.MenuFadeTime), { BackgroundTransparency = 1 });
            tw:Play();
            tw.Completed:Wait();
            Outer.Visible = false;
        end;

        Fading = false;
    end;

    Library:GiveSignal(InputService.InputBegan:Connect(function(Input, Processed)
        if type(Library.ToggleKeybind) == 'table' and Library.ToggleKeybind.Type == 'KeyPicker' then
            if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Library.ToggleKeybind.Value then
                task.spawn(Library.Toggle)
            end
        elseif Input.KeyCode == Enum.KeyCode.RightControl or (Input.KeyCode == Enum.KeyCode.Insert and (not Processed)) then
            task.spawn(Library.Toggle)
        end
    end))

    if Config.AutoShow then task.spawn(Library.Toggle) end

    Window.Holder = Outer;
    return Window;
end;

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                         FATALITY LOADING SCREEN SEQUENCE                  ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

local ActiveBlur = nil
local ActiveLoaderGui = nil

function Library:PlayLoader(Config)
    Config = Config or {}
    Config.Name = Config.Name or "KittyWare"
    Config.Duration = Config.Duration or 3.0
    Config.Scale = Config.Scale or 3

    local Lighting = game:GetService("Lighting")
    local Blur = Instance.new("BlurEffect")
    Blur.Name = "KittyWareBlur"
    Blur.Size = 0
    Blur.Parent = Lighting
    ActiveBlur = Blur

    local SafeParent = SafeContainer
    local LoaderGui = Instance.new("ScreenGui")
    LoaderGui.Name = GetRandomSymbolString(16)
    LoaderGui.ResetOnSpawn = false
    LoaderGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    LoaderGui.IgnoreGuiInset = true
    LoaderGui.DisplayOrder = 100000

    ProtectGui(LoaderGui)
    LoaderGui.Parent = SafeParent
    ActiveLoaderGui = LoaderGui

    local BlackFrame = Instance.new("Frame")
    BlackFrame.Name = ""
    BlackFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    BlackFrame.BackgroundTransparency = 1
    BlackFrame.BorderSizePixel = 0
    BlackFrame.Size = UDim2.new(1, 0, 1, 0)
    BlackFrame.ZIndex = 1
    BlackFrame.Parent = LoaderGui

    local texts = Instance.new("Frame")
    texts.Name = ""
    texts.AnchorPoint = Vector2.new(0.5, 0.5)
    texts.BackgroundTransparency = 1
    texts.BorderSizePixel = 0
    texts.Position = UDim2.new(0.5, 0, 0.5, 0)
    texts.Size = UDim2.new(1, 0, 0, 200)
    texts.ZIndex = 8
    texts.Parent = LoaderGui

    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Parent = texts
    UIListLayout.FillDirection = Enum.FillDirection.Horizontal
    UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    UIListLayout.Padding = UDim.new(0, Config.Scale * 5)

    local function Anim(instance, time, style, property)
        local tween = TweenService:Create(
            instance,
            TweenInfo.new(time or 1, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            property
        )
        tween:Play()
        return tween
    end

    Anim(Blur, 1, Enum.EasingStyle.Quint, { Size = 60 })

    local blackTween = Anim(BlackFrame, 0.5, Enum.EasingStyle.Quint, { BackgroundTransparency = 0.7 })
    blackTween.Completed:Wait()
    task.wait(0.5)

    local UText = { Y = 14 }
    local purpleGradient = ColorSequence.new{
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(215, 125, 255)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(125, 25, 200))
    }

    local createText = function(char, charIndex)
        local LIT = Instance.new("Frame")
        local ASCII = Instance.new("TextLabel")
        local UIScale = Instance.new("UIScale")

        LIT.Name = ""
        LIT.BackgroundTransparency = 1
        LIT.BorderSizePixel = 0
        LIT.Size = UDim2.new(0, 56, 0, 100)
        LIT.ZIndex = 8

        ASCII.Name = ""
        ASCII.Parent = LIT
        ASCII.AnchorPoint = Vector2.new(0.5, 0.5)
        ASCII.BackgroundTransparency = 1
        ASCII.BorderSizePixel = 0
        ASCII.Position = UDim2.new(0.5, 0, 0.5, 0)
        ASCII.Size = UDim2.new(0, 28, 0, 50)
        ASCII.ZIndex = 8
        ASCII.FontFace = CustomFont
        ASCII.Font = Enum.Font.GothamBold
        ASCII.Text = char
        ASCII.TextColor3 = Color3.fromRGB(255, 255, 255)
        ASCII.TextSize = 50.000
        ASCII.TextWrapped = true

        local textBounds = TextService:GetTextSize(
            char,
            50,
            Enum.Font.GothamBold,
            Vector2.new(2000, 2000)
        )

        ASCII.Size = UDim2.new(0, textBounds.X + 100, 0, 50)
        LIT.Size = UDim2.new(0, (textBounds.X * 2.5) + (UText[char] or 0), 0, 100)

        if charIndex <= 5 then
            local UIGradient = Instance.new("UIGradient")
            UIGradient.Color = purpleGradient
            UIGradient.Rotation = 88
            UIGradient.Parent = ASCII
        end

        UIScale.Parent = ASCII
        UIScale.Scale = Config.Scale

        return LIT, ASCII
    end

    local PosText = {}
    local isFirst = true
    local charIndex = 0

    string.gsub(Config.Name, ".", function(T)
        charIndex += 1
        local L, A = createText(T, charIndex)
        L.Parent = texts
        A.TextTransparency = 1
        if not isFirst then
            A.Position = UDim2.new(0.5, 0, 0.5, 200)
        end
        table.insert(PosText, { Frame = L, Text = A })
        isFirst = false
    end)

    local firstChar = Config.Name:sub(1, 1)
    local StartText = Instance.new("TextLabel")
    local UIScale = Instance.new("UIScale")

    StartText.Name = ""
    StartText.Parent = LoaderGui
    StartText.AnchorPoint = Vector2.new(0.5, 0.5)
    StartText.BackgroundTransparency = 1
    StartText.BorderSizePixel = 0
    StartText.Position = UDim2.new(0.5, 0, 0.5, 0)
    StartText.Size = UDim2.new(0, 28, 0, 50)
    StartText.ZIndex = 8
    StartText.FontFace = CustomFont
    StartText.Font = Enum.Font.GothamBold
    StartText.Text = firstChar
    StartText.TextColor3 = Color3.fromRGB(255, 255, 255)
    StartText.TextSize = 50.000
    StartText.TextWrapped = true
    StartText.TextTransparency = 1

    local firstTextBounds = TextService:GetTextSize(
        firstChar,
        50,
        Enum.Font.GothamBold,
        Vector2.new(2000, 2000)
    )
    StartText.Size = UDim2.new(0, firstTextBounds.X + 100, 0, 50)

    local StartGradient = Instance.new("UIGradient")
    StartGradient.Color = purpleGradient
    StartGradient.Rotation = 88
    StartGradient.Parent = StartText

    UIScale.Parent = StartText
    UIScale.Scale = Config.Scale * 4

    Anim(StartText, 0.45, Enum.EasingStyle.Quint, { TextTransparency = 0 })
    Anim(UIScale, 0.5, Enum.EasingStyle.Quint, { Scale = Config.Scale })
    task.wait(0.45)

    if PosText[1] and PosText[1].Frame then
        local targetX = PosText[1].Frame.AbsolutePosition.X + (PosText[1].Frame.AbsoluteSize.X / 2)
        local targetY = PosText[1].Frame.AbsolutePosition.Y + (PosText[1].Frame.AbsoluteSize.Y / 2) + math.abs(LoaderGui.AbsolutePosition.Y)
        Anim(StartText, 0.35, Enum.EasingStyle.Quint, { Position = UDim2.fromOffset(targetX, targetY) })
    end
    task.wait(0.5)

    for i, v in ipairs(PosText) do
        if i > 1 then
            Anim(v.Text, 0.65, Enum.EasingStyle.Quint, {
                Position = UDim2.new(0.5, 0, 0.5, 0),
                TextTransparency = 0
            })
        end
    end

    task.wait((Config.Duration - 0.5) + 0.65)

    Anim(StartText, 1.2, Enum.EasingStyle.Quint, { TextTransparency = 1 })
    for _, v in ipairs(PosText) do
        Anim(v.Text, 1.2, Enum.EasingStyle.Quint, { TextTransparency = 1 })
    end
    Anim(Blur, 1.2, Enum.EasingStyle.Quint, { Size = 0 })
    Anim(BlackFrame, 1.2, Enum.EasingStyle.Quint, { BackgroundTransparency = 1 })

    task.wait(1.25)
    if Blur and Blur.Parent then pcall(function() Blur:Destroy() end) end
    if LoaderGui and LoaderGui.Parent then pcall(function() LoaderGui:Destroy() end) end
    ActiveBlur = nil
    ActiveLoaderGui = nil
end

Library.Loader = Library.PlayLoader

getgenv().KittyWareCleanup = function()
    Library:Unload()
    if ActiveBlur and ActiveBlur.Parent then pcall(function() ActiveBlur:Destroy() end) end
    if ActiveLoaderGui and ActiveLoaderGui.Parent then pcall(function() ActiveLoaderGui:Destroy() end) end
    if getgenv().KittyWareGui and getgenv().KittyWareGui.Parent then pcall(function() getgenv().KittyWareGui:Destroy() end) end
end

getgenv().Library = Library
return Library
