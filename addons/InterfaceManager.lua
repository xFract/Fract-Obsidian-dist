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
    AutoMinimize = false,
    AutoExecute = false,
    AutoExecuteGist = "https://gist.githubusercontent.com/xFract/56ca5d02d698ea6536e4d975c4cf3d1e/raw/script.lua",
    AntiAFK = false,
    PerformanceMode = false,
    FPSCap = 60,
    AutoRejoin = false,
    LowPlayerHop = false,
    AntiStuckHop = false,
    AntiStuckHopSeconds = 300,
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

local SERVER_HOP_MAX_PAGES = 5
local LOW_PLAYER_RATIO = 0.3
local MAX_ANTI_STUCK_SECONDS = 3600

local InterfaceManager = {}
InterfaceManager.__index = InterfaceManager

InterfaceManager.Folder = "ObsidianLibSettings"
InterfaceManager.Library = nil
InterfaceManager.Window = nil
InterfaceManager.Settings = deepCopy(DEFAULT_SETTINGS)
InterfaceManager.AutoExecuteSource = nil
InterfaceManager.AutoExecuteBound = false
InterfaceManager.AutoRejoinBound = false
InterfaceManager.StaffDetectorBound = false
InterfaceManager.AFKThread = nil
InterfaceManager.AntiStuckThread = nil
InterfaceManager.AntiStuckDeadline = nil
InterfaceManager.AntiStuckStatusLabel = nil
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

function InterfaceManager:GetAntiStuckSeconds(value)
    local seconds = tonumber(value or self.Settings.AntiStuckHopSeconds) or DEFAULT_SETTINGS.AntiStuckHopSeconds
    return math.clamp(math.floor(seconds), 1, MAX_ANTI_STUCK_SECONDS)
end

function InterfaceManager:FormatDuration(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))

    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local remainingSeconds = seconds % 60

    if hours > 0 then
        return string.format("%d:%02d:%02d", hours, minutes, remainingSeconds)
    end

    return string.format("%02d:%02d", minutes, remainingSeconds)
end

function InterfaceManager:UpdateAntiStuckStatus(remainingSeconds)
    if not self.AntiStuckStatusLabel then
        return
    end

    if not self.Settings.AntiStuckHop then
        self.AntiStuckStatusLabel:SetText(
            string.format("Anti stuck hop: disabled (delay: %s)", self:FormatDuration(self:GetAntiStuckSeconds()))
        )
        return
    end

    self.AntiStuckStatusLabel:SetText(
        string.format("Anti stuck hop: %s remaining", self:FormatDuration(remainingSeconds))
    )
end

function InterfaceManager:ResetAntiStuckTimer()
    self.Settings.AntiStuckHopSeconds = self:GetAntiStuckSeconds()
    self.AntiStuckDeadline = os.clock() + self.Settings.AntiStuckHopSeconds
    self:UpdateAntiStuckStatus(self.Settings.AntiStuckHopSeconds)
end

function InterfaceManager:SetAntiStuckHop(enabled)
    self.Settings.AntiStuckHop = enabled == true

    if self.AntiStuckThread then
        task.cancel(self.AntiStuckThread)
        self.AntiStuckThread = nil
    end

    if not self.Settings.AntiStuckHop then
        self.AntiStuckDeadline = nil
        self:UpdateAntiStuckStatus()
        return
    end

    self:ResetAntiStuckTimer()

    self.AntiStuckThread = task.spawn(function()
        while self.Settings.AntiStuckHop do
            local remainingSeconds = math.max(0, math.ceil((self.AntiStuckDeadline or os.clock()) - os.clock()))
            self:UpdateAntiStuckStatus(remainingSeconds)

            if remainingSeconds <= 0 then
                self:Notify("Anti stuck hop", "Timer elapsed; server hopping.", 5)
                self:ServerHop()
                self:ResetAntiStuckTimer()
            end

            task.wait(1)
        end
    end)
end

function InterfaceManager:SetAntiStuckSeconds(value)
    self.Settings.AntiStuckHopSeconds = self:GetAntiStuckSeconds(value)

    if self.Settings.AntiStuckHop then
        self:ResetAntiStuckTimer()
    else
        self:UpdateAntiStuckStatus()
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

function InterfaceManager:GetJson(url)
    local httpRequest = getHttpRequest()

    if httpRequest then
        local requestSuccess, requestResult = pcall(function()
            return httpRequest({
                Url = url,
                Method = "GET",
                Headers = {
                    Accept = "application/json",
                },
            })
        end)

        if requestSuccess and typeof(requestResult) == "table" then
            local statusCode = tonumber(
                requestResult.StatusCode or requestResult.status_code or requestResult.Status
            )
            local body = requestResult.Body or requestResult.body

            if body and (not statusCode or (statusCode >= 200 and statusCode < 300)) then
                local decodeSuccess, decoded = pcall(function()
                    return HttpService:JSONDecode(body)
                end)

                if decodeSuccess then
                    return true, decoded
                end
            end
        end
    end

    local getSuccess, getResult = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(url))
    end)

    if getSuccess then
        return true, getResult
    end

    return false, nil
end

function InterfaceManager:GetServerListUrl(cursor)
    local url = string.format(
        "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100&excludeFullGames=true",
        game.PlaceId
    )

    if typeof(cursor) == "string" and cursor ~= "" then
        url = url .. "&cursor=" .. HttpService:UrlEncode(cursor)
    end

    return url
end

function InterfaceManager:IsHopCandidate(server)
    if typeof(server) ~= "table" or typeof(server.id) ~= "string" or server.id == game.JobId then
        return false
    end

    local playing = tonumber(server.playing)
    local maxPlayers = tonumber(server.maxPlayers)

    return playing ~= nil and maxPlayers ~= nil and maxPlayers > 0 and playing < maxPlayers
end

function InterfaceManager:GetLowPlayerLimit(maxPlayers)
    return math.max(1, math.floor(maxPlayers * LOW_PLAYER_RATIO))
end

function InterfaceManager:TeleportToHopTarget(targetServer)
    if targetServer then
        local success = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, targetServer.id, Players.LocalPlayer)
        end)

        if success then
            return true, nil
        end

        self:Notify("Server hop", "Target server became unavailable; trying another public server.", 5)
        return pcall(function()
            TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
        end)
    end

    return pcall(function()
        TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
    end)
end

function InterfaceManager:FindServerHopTarget(lowPlayerOnly)
    local cursor = nil
    local bestServer = nil
    local bestPlaying = math.huge

    for _ = 1, SERVER_HOP_MAX_PAGES do
        local success, response = self:GetJson(self:GetServerListUrl(cursor))

        if not success or typeof(response) ~= "table" or typeof(response.data) ~= "table" then
            break
        end

        for _, server in ipairs(response.data) do
            if self:IsHopCandidate(server) then
                local playing = tonumber(server.playing) or math.huge
                local maxPlayers = tonumber(server.maxPlayers) or 0

                if not lowPlayerOnly then
                    return server
                end

                if playing < bestPlaying then
                    bestServer = server
                    bestPlaying = playing
                end

                if playing <= self:GetLowPlayerLimit(maxPlayers) then
                    return server
                end
            end
        end

        cursor = response.nextPageCursor
        if typeof(cursor) ~= "string" or cursor == "" then
            break
        end

        task.wait(0.15)
    end

    return bestServer
end

function InterfaceManager:ServerHop()
    if self.IsHopping then
        return
    end

    self.IsHopping = true

    task.spawn(function()
        local lowPlayerOnly = self.Settings.LowPlayerHop == true

        local targetServer = self:FindServerHopTarget(lowPlayerOnly)
        local teleportSuccess, teleportError = self:TeleportToHopTarget(targetServer)

        if not teleportSuccess then
            self:Notify("Server hop failed", tostring(teleportError), 6)
        elseif lowPlayerOnly and not targetServer then
            self:Notify("Server hop", "No low-player server was found; joining another public server.", 6)
        end

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
    self:BindTeleportAutoExecute()
    self:BindAutoRejoin()
    self:BindStaffDetector()

    if self.Settings.AntiAFK then
        self:SetAntiAFK(true)
    end

    if self.Settings.AntiStuckHop then
        self:SetAntiStuckHop(true)
    end

    if self.Settings.PerformanceMode then
        self:SetPerformanceMode(true)
    end

    if type(setfpscap) == "function" then
        self:SetFPSCap(self.Settings.FPSCap or DEFAULT_SETTINGS.FPSCap)
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

    serverSection:AddToggle("InterfaceManager_AntiStuckHop", {
        Text = "Anti stuck hop",
        Default = self.Settings.AntiStuckHop,
    })

    serverSection:AddSlider("InterfaceManager_AntiStuckHopSeconds", {
        Text = "Anti stuck seconds",
        Default = self:GetAntiStuckSeconds(),
        Min = 1,
        Max = MAX_ANTI_STUCK_SECONDS,
        Rounding = 0,
        Suffix = "s",
    })

    self.AntiStuckStatusLabel = serverSection:AddLabel("Anti stuck hop: disabled")
    self:UpdateAntiStuckStatus(
        if self.Settings.AntiStuckHop and self.AntiStuckDeadline then
            math.max(0, math.ceil(self.AntiStuckDeadline - os.clock()))
        else
            self.Settings.AntiStuckHopSeconds
    )

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

    self.Library.Toggles.InterfaceManager_AntiStuckHop:OnChanged(function()
        self:SetAntiStuckHop(self.Library.Toggles.InterfaceManager_AntiStuckHop.Value)
        self:SaveSettings()
    end)

    self.Library.Options.InterfaceManager_AntiStuckHopSeconds:OnChanged(function()
        self:SetAntiStuckSeconds(self.Library.Options.InterfaceManager_AntiStuckHopSeconds.Value)
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
end

InterfaceManager:BuildFolderTree()
InterfaceManager:BuildAutoExecuteSource()

getgenv().ObsidianInterfaceManager = InterfaceManager
return InterfaceManager
