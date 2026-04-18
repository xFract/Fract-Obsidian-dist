local cloneref = (cloneref or clonereference or function(instance: any)
    return instance
end)
local clonefunction = (clonefunction or copyfunction or function(func)
    return func
end)

local HttpService: HttpService = cloneref(game:GetService("HttpService"))
local Players: Players = cloneref(game:GetService("Players"))
local VirtualUser: VirtualUser = cloneref(game:GetService("VirtualUser"))
local TeleportService: TeleportService = cloneref(game:GetService("TeleportService"))
local Lighting: Lighting = cloneref(game:GetService("Lighting"))
local GuiService: GuiService = cloneref(game:GetService("GuiService"))
local MarketplaceService: MarketplaceService = cloneref(game:GetService("MarketplaceService"))
local CoreGui = cloneref(game:GetService("CoreGui"))

local isfolder, isfile, listfiles = isfolder, isfile, listfiles

if typeof(clonefunction) == "function" then
    local isfolderCopy = clonefunction(isfolder)
    local isfileCopy = clonefunction(isfile)
    local listfilesCopy = clonefunction(listfiles)

    local isfolderSuccess, isfolderError = pcall(function()
        return isfolderCopy("test" .. tostring(math.random(1000000, 9999999)))
    end)

    if isfolderSuccess == false or typeof(isfolderError) ~= "boolean" then
        isfolder = function(path)
            local success, result = pcall(isfolderCopy, path)
            return if success then result else false
        end

        isfile = function(path)
            local success, result = pcall(isfileCopy, path)
            return if success then result else false
        end

        listfiles = function(path)
            local success, result = pcall(listfilesCopy, path)
            return if success and typeof(result) == "table" then result else {}
        end
    end
end

local DEFAULT_SETTINGS = {
    Theme = "Default",
    MenuKeybind = "RightShift",
    AutoMinimize = false,
    AutoExecute = false,
    AutoExecuteGist = "https://gist.githubusercontent.com/xFract/56ca5d02d698ea6536e4d975c4cf3d1e/raw/script.lua",
    AntiAFK = false,
    PerformanceMode = false,
    FPSCap = 60,
    AutoRejoin = false,
    LowPlayerHop = false,
    StaffDetector = false,
    WebhookURL = "",
}

local function deepCopy(source)
    local out = {}

    for key, value in pairs(source) do
        if typeof(value) == "table" then
            out[key] = deepCopy(value)
        else
            out[key] = value
        end
    end

    return out
end

local function getHttpRequest()
    return (syn and syn.request) or request or http_request or (http and http.request)
end

local function getQueueOnTeleport()
    return (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
end

local InterfaceManager = {}
InterfaceManager.__index = InterfaceManager

InterfaceManager.Folder = "ObsidianLibSettings"
InterfaceManager.Library = nil
InterfaceManager.Window = nil
InterfaceManager.ThemeManager = nil
InterfaceManager.Settings = deepCopy(DEFAULT_SETTINGS)
InterfaceManager.AutoExecuteSource = nil
InterfaceManager.AutoExecuteBound = false
InterfaceManager.AutoRejoinBound = false
InterfaceManager.StaffDetectorBound = false
InterfaceManager.AFKThread = nil
InterfaceManager.IsRejoining = false
InterfaceManager.IsHopping = false
InterfaceManager.OriginalLighting = nil
InterfaceManager.PerformanceRestore = {}

function InterfaceManager:SetFolder(folder)
    self.Folder = folder
    self:BuildFolderTree()
end

function InterfaceManager:SetLibrary(library)
    self.Library = library
end

function InterfaceManager:SetWindow(window)
    self.Window = window
end

function InterfaceManager:SetThemeManager(themeManager)
    self.ThemeManager = themeManager
end

function InterfaceManager:SetAutoExecuteSource(source)
    self.AutoExecuteSource = source
    self.AutoExecuteBound = false
end

function InterfaceManager:BuildAutoExecuteSource()
    local url = self.Settings.AutoExecuteGist
    if typeof(url) ~= "string" or url == "" then
        self.AutoExecuteSource = nil
        return
    end

    self.AutoExecuteSource = string.format(
        "repeat task.wait() until game:IsLoaded(); loadstring(game:HttpGet(%q))()",
        url
    )
end

function InterfaceManager:SetAutoExecuteUrl(url)
    self.Settings.AutoExecuteGist = if typeof(url) == "string" then url else ""
    self:BuildAutoExecuteSource()
    self.AutoExecuteBound = false
    self:BindTeleportAutoExecute()
    self:SaveSettings()
end

function InterfaceManager:GetPaths()
    local paths = {}
    local parts = self.Folder:split("/")

    for index = 1, #parts do
        paths[#paths + 1] = table.concat(parts, "/", 1, index)
    end

    paths[#paths + 1] = self.Folder .. "/settings"

    return paths
end

function InterfaceManager:BuildFolderTree()
    if not makefolder or not isfolder then
        return
    end

    for _, path in ipairs(self:GetPaths()) do
        if not isfolder(path) then
            makefolder(path)
        end
    end
end

function InterfaceManager:SaveSettings()
    if not writefile then
        return false
    end

    self:BuildFolderTree()
    writefile(self.Folder .. "/settings/interface.json", HttpService:JSONEncode(self.Settings))
    return true
end

function InterfaceManager:LoadSettings()
    if not isfile or not readfile then
        return false
    end

    local path = self.Folder .. "/settings/interface.json"
    if not isfile(path) then
        self:BuildAutoExecuteSource()
        return false
    end

    local success, decoded = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)

    if not success or typeof(decoded) ~= "table" then
        self:BuildAutoExecuteSource()
        return false
    end

    self.Settings = deepCopy(DEFAULT_SETTINGS)

    for key, value in pairs(decoded) do
        self.Settings[key] = value
    end

    self:BuildAutoExecuteSource()

    return true
end

function InterfaceManager:Notify(title, description, duration)
    if not self.Library or not self.Library.Notify then
        return
    end

    local success = pcall(function()
        self.Library:Notify({
            Title = title,
            Description = description,
            Time = duration or 6,
        })
    end)

    if not success then
        pcall(function()
            self.Library:Notify(string.format("%s: %s", tostring(title), tostring(description)))
        end)
    end
end

function InterfaceManager:GetThemeManager()
    return self.ThemeManager or rawget(getgenv(), "ObsidianThemeManager")
end

function InterfaceManager:GetThemeNames()
    local themeManager = self:GetThemeManager()
    if not themeManager then
        return { DEFAULT_SETTINGS.Theme }
    end

    local names = {}
    local seen = {}

    if typeof(themeManager.BuiltInThemes) == "table" then
        local ordered = {}
        for name, data in pairs(themeManager.BuiltInThemes) do
            ordered[#ordered + 1] = { Name = name, Order = data[1] or math.huge }
        end

        table.sort(ordered, function(left, right)
            if left.Order == right.Order then
                return left.Name < right.Name
            end

            return left.Order < right.Order
        end)

        for _, entry in ipairs(ordered) do
            seen[entry.Name] = true
            names[#names + 1] = entry.Name
        end
    end

    if type(themeManager.ReloadCustomThemes) == "function" then
        for _, name in ipairs(themeManager:ReloadCustomThemes()) do
            if not seen[name] then
                seen[name] = true
                names[#names + 1] = name
            end
        end
    end

    if #names == 0 then
        names[1] = DEFAULT_SETTINGS.Theme
    end

    return names
end

function InterfaceManager:ApplyTheme(themeName)
    local themeManager = self:GetThemeManager()
    if not themeManager or type(themeManager.ApplyTheme) ~= "function" then
        return false
    end

    local success = pcall(function()
        themeManager:ApplyTheme(themeName)
    end)

    if success then
        self.Settings.Theme = themeName
    end

    return success
end

function InterfaceManager:SetPerformanceMode(enabled)
    self.Settings.PerformanceMode = enabled == true

    if self.Settings.PerformanceMode then
        if not self.OriginalLighting then
            self.OriginalLighting = {
                GlobalShadows = Lighting.GlobalShadows,
                FogEnd = Lighting.FogEnd,
                ShadowSoftness = Lighting.ShadowSoftness,
            }
        end

        self.PerformanceRestore = {}

        task.spawn(function()
            pcall(function()
                Lighting.GlobalShadows = false
                Lighting.FogEnd = 9e9
                Lighting.ShadowSoftness = 0
            end)

            pcall(function()
                for _, instance in ipairs(workspace:GetDescendants()) do
                    if instance:IsA("BasePart") then
                        self.PerformanceRestore[instance] = {
                            Kind = "BasePart",
                            Material = instance.Material,
                        }
                        instance.Material = Enum.Material.SmoothPlastic
                    elseif instance:IsA("Decal") or instance:IsA("Texture") then
                        self.PerformanceRestore[instance] = {
                            Kind = "TextureLike",
                            Transparency = instance.Transparency,
                        }
                        instance.Transparency = 1
                    elseif instance:IsA("ParticleEmitter") or instance:IsA("Trail") then
                        self.PerformanceRestore[instance] = {
                            Kind = "Fx",
                            Enabled = instance.Enabled,
                        }
                        instance.Enabled = false
                    end
                end
            end)
        end)

        return
    end

    if self.OriginalLighting then
        pcall(function()
            Lighting.GlobalShadows = self.OriginalLighting.GlobalShadows
            Lighting.FogEnd = self.OriginalLighting.FogEnd
            Lighting.ShadowSoftness = self.OriginalLighting.ShadowSoftness
        end)
    end

    pcall(function()
        for instance, state in pairs(self.PerformanceRestore) do
            if instance and instance.Parent then
                if state.Kind == "BasePart" then
                    instance.Material = state.Material
                elseif state.Kind == "TextureLike" then
                    instance.Transparency = state.Transparency
                elseif state.Kind == "Fx" then
                    instance.Enabled = state.Enabled
                end
            end
        end
    end)

    self.PerformanceRestore = {}
end

function InterfaceManager:SetFPSCap(value)
    self.Settings.FPSCap = value

    if type(setfpscap) == "function" then
        setfpscap(value)
    end
end

function InterfaceManager:SetAntiAFK(enabled)
    self.Settings.AntiAFK = enabled == true

    if self.AFKThread then
        task.cancel(self.AFKThread)
        self.AFKThread = nil
    end

    if not self.Settings.AntiAFK then
        return
    end

    self.AFKThread = task.spawn(function()
        while self.Settings.AntiAFK do
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.zero)
            task.wait(60)
        end
    end)
end

function InterfaceManager:SendWebhook(title, description)
    local webhookUrl = self.Settings.WebhookURL
    if typeof(webhookUrl) ~= "string" or webhookUrl == "" then
        return
    end

    task.spawn(function()
        pcall(function()
            local httpRequest = getHttpRequest()
            if not httpRequest then
                return
            end

            httpRequest({
                Url = webhookUrl,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json",
                },
                Body = HttpService:JSONEncode({
                    embeds = {
                        {
                            title = title,
                            description = description,
                            color = 16711680,
                            footer = {
                                text = "Obsidian InterfaceManager",
                            },
                            timestamp = DateTime.now():ToIsoDate(),
                        },
                    },
                }),
            })
        end)
    end)
end

function InterfaceManager:ServerHop()
    if self.IsHopping then
        return
    end

    self.IsHopping = true

    task.spawn(function()
        local lowPlayerOnly = self.Settings.LowPlayerHop == true

        local success, response = pcall(function()
            local url = string.format(
                "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100",
                game.PlaceId
            )
            return HttpService:JSONDecode(game:HttpGet(url))
        end)

        local targetServer
        if success and response and typeof(response.data) == "table" then
            for _, server in ipairs(response.data) do
                if server.id ~= game.JobId and server.playing and server.maxPlayers then
                    if not lowPlayerOnly or server.playing < (server.maxPlayers * 0.3) then
                        targetServer = server
                        break
                    end
                end
            end
        end

        pcall(function()
            if targetServer then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, targetServer.id, Players.LocalPlayer)
            else
                TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
            end
        end)

        task.wait(5)
        self.IsHopping = false
    end)
end

function InterfaceManager:IsStaff(player)
    if not player or player == Players.LocalPlayer then
        return false
    end

    if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then
        return true
    end

    if game.CreatorType == Enum.CreatorType.Group then
        local rankSuccess, rank = pcall(function()
            return player:GetRankInGroup(game.CreatorId)
        end)

        if rankSuccess and rank >= 200 then
            return true
        end
    end

    local badgeSuccess, hasBadge = pcall(function()
        return player.HasVerifiedBadge
    end)

    return badgeSuccess and hasBadge == true
end

function InterfaceManager:BindAutoRejoin()
    if self.AutoRejoinBound then
        return
    end

    self.AutoRejoinBound = true

    local function triggerRejoin()
        if not self.Settings.AutoRejoin or self.IsRejoining then
            return
        end

        self.IsRejoining = true
        task.wait(3)

        pcall(function()
            if #game.JobId > 0 then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Players.LocalPlayer)
            else
                TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
            end
        end)

        task.wait(5)
        self.IsRejoining = false
    end

    pcall(function()
        local promptOverlay = CoreGui:FindFirstChild("RobloxPromptGui")
        promptOverlay = promptOverlay and promptOverlay:FindFirstChild("promptOverlay")

        if promptOverlay then
            promptOverlay.ChildAdded:Connect(function(child)
                if child.Name == "ErrorPrompt" then
                    triggerRejoin()
                end
            end)
        end
    end)

    pcall(function()
        GuiService.ErrorMessageChanged:Connect(function()
            triggerRejoin()
        end)
    end)
end

function InterfaceManager:BindStaffDetector()
    if self.StaffDetectorBound then
        return
    end

    self.StaffDetectorBound = true

    local function checkPlayer(player)
        if not self.Settings.StaffDetector or not self:IsStaff(player) then
            return
        end

        local gameName = "Unknown"
        pcall(function()
            gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
        end)

        self:SendWebhook(
            "Staff Detected",
            string.format(
                "**Player:** %s\n**UserId:** %d\n**Game:** %s (PlaceId: %d)\n**Action:** Auto Hop",
                player.Name,
                player.UserId,
                gameName,
                game.PlaceId
            )
        )

        task.wait(1)
        self:ServerHop()
    end

    Players.PlayerAdded:Connect(checkPlayer)

    task.spawn(function()
        for _, player in ipairs(Players:GetPlayers()) do
            checkPlayer(player)
        end
    end)
end

function InterfaceManager:BindTeleportAutoExecute()
    if self.AutoExecuteBound or not self.AutoExecuteSource or not Players.LocalPlayer then
        return
    end

    local queueOnTeleport = getQueueOnTeleport()
    if not queueOnTeleport then
        return
    end

    self.AutoExecuteBound = true

    local queued = false
    Players.LocalPlayer.OnTeleport:Connect(function()
        if queued or not self.Settings.AutoExecute then
            return
        end

        queueOnTeleport(self.AutoExecuteSource)
        queued = true
    end)
end

function InterfaceManager:SetMenuKeybind(key)
    self.Settings.MenuKeybind = key

    if self.Library and self.Library.Options and self.Library.Options.InterfaceManager_MenuKeybind then
        self.Library.ToggleKeybind = self.Library.Options.InterfaceManager_MenuKeybind
    end

    self:SaveSettings()
end

function InterfaceManager:GetWindowVisible()
    local mainFrame = self.Window and self.Window.MainFrame
    if mainFrame and mainFrame:IsA("GuiObject") then
        return mainFrame.Visible
    end

    if self.Library and typeof(self.Library.Toggled) == "boolean" then
        return self.Library.Toggled
    end

    return true
end

function InterfaceManager:MinimizeWindow()
    if not self.Window or type(self.Window.Toggle) ~= "function" or not self:GetWindowVisible() then
        return false
    end

    self.Window:Toggle()
    return true
end

function InterfaceManager:ApplyLoadedSettings()
    self:ApplyTheme(self.Settings.Theme)
    self:BindTeleportAutoExecute()
    self:BindAutoRejoin()
    self:BindStaffDetector()

    if self.Settings.AntiAFK then
        self:SetAntiAFK(true)
    end

    if self.Settings.PerformanceMode then
        self:SetPerformanceMode(true)
    end

    if type(setfpscap) == "function" then
        self:SetFPSCap(self.Settings.FPSCap or DEFAULT_SETTINGS.FPSCap)
    end

    if self.Library and self.Library.Options and self.Library.Options.InterfaceManager_MenuKeybind then
        self.Library.ToggleKeybind = self.Library.Options.InterfaceManager_MenuKeybind
    end

    if self.Settings.AutoMinimize then
        task.defer(function()
            self:MinimizeWindow()
        end)
    end
end

function InterfaceManager:BuildInterfaceSection(tab, side)
    assert(self.Library, "Must set InterfaceManager.Library")
    assert(self.Window, "Must set InterfaceManager.Window")

    self:LoadSettings()
    self:ApplyLoadedSettings()

    side = (typeof(side) == "string" and side:lower()) or "right"

    local appearanceSection
    local utilitySection
    local serverSection

    if side == "left" then
        appearanceSection = tab:AddLeftGroupbox("Appearance", "paintbrush")
        utilitySection = tab:AddLeftGroupbox("Utility", "wrench")
        serverSection = tab:AddLeftGroupbox("Server & Safety", "shield")
    else
        appearanceSection = tab:AddRightGroupbox("Appearance", "paintbrush")
        utilitySection = tab:AddRightGroupbox("Utility", "wrench")
        serverSection = tab:AddRightGroupbox("Server & Safety", "shield")
    end

    local themeNames = self:GetThemeNames()
    appearanceSection:AddDropdown("InterfaceManager_Theme", {
        Text = "Theme",
        Values = themeNames,
        Default = table.find(themeNames, self.Settings.Theme) or 1,
        AllowNull = false,
    })

    appearanceSection:AddLabel("Menu bind")
        :AddKeyPicker("InterfaceManager_MenuKeybind", {
            Default = self.Settings.MenuKeybind,
            NoUI = true,
            Text = "Menu keybind",
        })

    appearanceSection:AddToggle("InterfaceManager_AutoMinimize", {
        Text = "Auto minimize",
        Default = self.Settings.AutoMinimize,
    })

    utilitySection:AddToggle("InterfaceManager_AutoExecute", {
        Text = "Auto execute",
        Default = self.Settings.AutoExecute,
    })

    utilitySection:AddToggle("InterfaceManager_AntiAFK", {
        Text = "Anti AFK",
        Default = self.Settings.AntiAFK,
    })

    utilitySection:AddToggle("InterfaceManager_PerformanceMode", {
        Text = "Performance mode",
        Default = self.Settings.PerformanceMode,
    })

    utilitySection:AddSlider("InterfaceManager_FPSCap", {
        Text = "FPS Cap",
        Default = self.Settings.FPSCap or DEFAULT_SETTINGS.FPSCap,
        Min = 15,
        Max = 240,
        Rounding = 0,
    })

    serverSection:AddToggle("InterfaceManager_AutoRejoin", {
        Text = "Auto rejoin",
        Default = self.Settings.AutoRejoin,
    })

    serverSection:AddToggle("InterfaceManager_LowPlayerHop", {
        Text = "Low player hop",
        Default = self.Settings.LowPlayerHop,
    })

    serverSection:AddToggle("InterfaceManager_StaffDetector", {
        Text = "Staff detector",
        Default = self.Settings.StaffDetector,
    })

    serverSection:AddInput("InterfaceManager_WebhookURL", {
        Text = "Discord webhook URL",
        Default = self.Settings.WebhookURL,
        Placeholder = "https://discord.com/api/webhooks/...",
        Finished = true,
    })

    serverSection:AddButton("Server hop", function()
        self:ServerHop()
    end)

    self.Library.Options.InterfaceManager_Theme:OnChanged(function(value)
        if not self:ApplyTheme(value) then
            self:Notify("Interface Manager", "ThemeManager is not available for theme switching.")
            return
        end

        self:SaveSettings()
    end)

    self.Library.Options.InterfaceManager_MenuKeybind:OnChanged(function()
        self:SetMenuKeybind(self.Library.Options.InterfaceManager_MenuKeybind.Value)
    end)

    self.Library.Toggles.InterfaceManager_AutoMinimize:OnChanged(function()
        self.Settings.AutoMinimize = self.Library.Toggles.InterfaceManager_AutoMinimize.Value
        self:SaveSettings()
    end)

    self.Library.Toggles.InterfaceManager_AutoExecute:OnChanged(function()
        self.Settings.AutoExecute = self.Library.Toggles.InterfaceManager_AutoExecute.Value
        self:SaveSettings()
    end)

    self.Library.Toggles.InterfaceManager_AntiAFK:OnChanged(function()
        self:SetAntiAFK(self.Library.Toggles.InterfaceManager_AntiAFK.Value)
        self:SaveSettings()
    end)

    self.Library.Toggles.InterfaceManager_PerformanceMode:OnChanged(function()
        self:SetPerformanceMode(self.Library.Toggles.InterfaceManager_PerformanceMode.Value)
        self:SaveSettings()
    end)

    self.Library.Options.InterfaceManager_FPSCap:OnChanged(function()
        self:SetFPSCap(self.Library.Options.InterfaceManager_FPSCap.Value)
        self:SaveSettings()
    end)

    self.Library.Toggles.InterfaceManager_AutoRejoin:OnChanged(function()
        self.Settings.AutoRejoin = self.Library.Toggles.InterfaceManager_AutoRejoin.Value
        self:SaveSettings()
    end)

    self.Library.Toggles.InterfaceManager_LowPlayerHop:OnChanged(function()
        self.Settings.LowPlayerHop = self.Library.Toggles.InterfaceManager_LowPlayerHop.Value
        self:SaveSettings()
    end)

    self.Library.Toggles.InterfaceManager_StaffDetector:OnChanged(function()
        self.Settings.StaffDetector = self.Library.Toggles.InterfaceManager_StaffDetector.Value
        self:SaveSettings()
    end)

    self.Library.Options.InterfaceManager_WebhookURL:OnChanged(function()
        self.Settings.WebhookURL = self.Library.Options.InterfaceManager_WebhookURL.Value
        self:SaveSettings()
    end)

    self.Library.ToggleKeybind = self.Library.Options.InterfaceManager_MenuKeybind
end

function InterfaceManager:BuildAutoLoadThemeList()
    local dropdown = self.Library and self.Library.Options and self.Library.Options.InterfaceManager_Theme
    if not dropdown then
        return
    end

    dropdown:SetValues(self:GetThemeNames())
end

InterfaceManager:BuildFolderTree()
InterfaceManager:BuildAutoExecuteSource()

getgenv().ObsidianInterfaceManager = InterfaceManager
return InterfaceManager
