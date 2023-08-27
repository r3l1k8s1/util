local API = {}

local oldTraceback
oldTraceback = hookfunction(getrenv().debug.traceback, function(lol)
    local traceback = oldTraceback(lol)
    if checkcaller() then
        local a = traceback:split("\n")
        return string.format("%s\n%s\n", a[1], a[3])
    end
    return traceback
end)

local oldInfo
oldInfo = hookfunction(getrenv().debug.info, function(lvl, a)
    if checkcaller() then
        return oldInfo(3, a)
    end
    return oldInfo(lvl, a)
end)

function API:Load()
    API.Services = {}
    setmetatable(API.Services, {
        __index = function(_, Service_Name)
            return game:GetService(Service_Name)
        end
    })
end

function API:GetPlayerHeadshot()
    local Request = ((syn and syn.request) or (http and http.request) or http_request or function() end){
        Url = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds="..game.Players.LocalPlayer.UserId.."&size=720x720&format=Png&isCircular=false"
    }
    local HttpService = game:GetService("HttpService")
    local Body = HttpService:JSONDecode(Request.Body)
    return Body.data[1].imageUrl
end

function API:Webhook(Url, Data)
    ((syn and syn.request) or (http and http.request) or http_request or function() end){
        Url = Url,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = game:GetService("HttpService"):JSONEncode(Data)
    }
end

function API:VirtualPressButton(Button)
    game:GetService("VirtualInputManager"):SendKeyEvent(true, Button, false, nil)
    task.wait()
    game:GetService("VirtualInputManager"):SendKeyEvent(false, Button, false, nil)
end

function API:RobloxNotify(Title, Description, Duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = Title;
            Text = Description;
            Duration = Duration;
        })
    end)
end

function API:Tween(vec3, speed)
    assert(typeof(vec3) == "Vector3", "Argument #1 must be a Vector3")
    assert(typeof(speed) == "number", "Argument #2 must be a number")

    local dist = game.Players.LocalPlayer:DistanceFromCharacter(vec3)
    local info = TweenInfo.new(dist / speed, Enum.EasingStyle.Linear)

    local tween = game.TweenService:Create(self:Root(), info, { CFrame = CFrame.new(vec3) })
    tween:Play()

    local conn = game.RunService.RenderStepped:Connect(function()
        game.Players.LocalPlayer.Character.PrimaryPart.Velocity = Vector3.zero
        for _, v in next, game.Players.LocalPlayer.Character:GetDescendants() do
            if v:IsA("BasePart") and v.CanCollide == true then
                v.CanCollide = false
            end
        end
    end)

    tween.Completed:Connect(function()
        conn:Disconnect()
    end)

    return tween
end

function API:Pathfind(Destination, Speed)
    local Path = game.PathfindingService:CreatePath({ AgentCanJump = true, AgentCanClimb = true })

    local Success, ErrorMessage = pcall(function()
        Path:ComputeAsync(game.Players.LocalPlayer.Character.PrimaryPart.Position, Destination)
    end)

    if Success and Path.Status == Enum.PathStatus.Success then
        local Waypoints = Path:GetWaypoints()

        for _, Waypoint in next, Waypoints do
            if game.Players.LocalPlayer.Character:FindFirstChild("Humanoid").Health <= 0 then
                break
            end
            if Waypoint.Action == Enum.PathWaypointAction.Jump then
                game.Players.LocalPlayer.Character:FindFirstChild("Humanoid").Jump = true
            end
            repeat task.wait() game.Players.LocalPlayer.Character:FindFirstChild("Humanoid"):MoveTo(Waypoint.Position) until game.Players.LocalPlayer.Character:FindFirstChild("Humanoid").MoveToFinished
            local TimeOut = game.Players.LocalPlayer.Character:FindFirstChild("Humanoid").MoveToFinished:Wait(0.1)
            if not TimeOut then
                game.Players.LocalPlayer.Character:FindFirstChild("Humanoid").Jump = true
                self:Pathfind(Destination)
                break
            end
        end
    else
        warn(ErrorMessage)
        self:Tween(Speed, Destination)
    end
end

function API:FormatSeconds(Seconds)
    local Days = math.floor(Seconds / 86400)
    local Hours = math.floor((Seconds % 86400) / 3600)
    local Minutes = math.floor(((Seconds % 86400) % 3600) / 60)
    local RemainingSeconds = (Seconds % 86400) % 60
    local Result

    if Days == 0 then
        Result = string.format("%d:%02d:%02d", Hours, Minutes, RemainingSeconds)
    else
        Result = string.format("%d days, %d:%02d:%02d", Days, Hours, Minutes, RemainingSeconds)
    end

    return Result
end

function API:AbbreviateNumber(Number)
    local FormattedNumber
    local Abbreviations = {[10^3] = "K", [10^6] = "M", [10^9] = "B", [10^12] = "T", [10^15] = "Q", [10^18] = "Qi", [10^21] = "Sx", [10^24] = "Sp"}

    if Number < 1000 then
        FormattedNumber = string.format("%d", Number)
    else
        local Thresholds = {}
        for Threshold in next, Abbreviations do
          table.insert(Thresholds, Threshold)
        end
        table.sort(Thresholds, function(a, b) return a > b end)
        for _, Threshold in next, Thresholds do
            if Number >= Threshold then
                FormattedNumber = string.format("%.3f %s", Number / Threshold, Abbreviations[Threshold])
                break
            end
        end
    end

    return FormattedNumber
end

function API:Create(Class, Properties)
    local _Instance = Class

    if type(Class) == 'string' then
        _Instance = Instance.new(Class)
    end

    for Property, Value in next, Properties do
        _Instance[Property] = Value
    end

    return _Instance
end

function API:IsVisible(Part, Ignore)
    return (#workspace.CurrentCamera:GetPartsObscuringTarget({ Part.Position }, { Ignore }) == 0)
end

function API:SecureCall(Function, Script, ...)
    if syn and syn.toast_notification then

        local Info = debug.getinfo(Function)
        local Options = {
            script = Script,
            identity = 2,
            env = getsenv(Script),
            thread = getscriptthread and getscriptthread(Script)
        }
        local Callstack = {Info}

        return syn.trampoline_call(Function, Callstack, Options, ...)
    elseif syn then
        return syn.secure_call(Function, Script, ...)
    elseif Krnl then
        return coroutine.wrap(function(...)
            setthreadcontext(2)
            setfenv(0, getsenv(Script))
            setfenv(1, getsenv(Script))
            return Function(...)
        end)(...)
    elseif identifyexecutor and string.match(identifyexecutor(), "ScriptWare") then
        local func, env = Function, Script
        local functype, envtype = typeof(func), typeof(env)
        local envclass = env.ClassName

        assert(functype == "function", string.format("bad argument #1 to 'secure_call' (function expected, got %s)", functype))
        assert(envtype == "Instance", string.format("bad argument #2 to 'secure_call' (Instance expected, got %s)", envtype))
        assert(envclass == "LocalScript" or envclass == "ModuleScript", string.format("bad argument #2 to 'secure_call' (LocalScript or ModuleScript expected, got %s)", envclass))

        local _, fenv = xpcall(function()
            return getsenv(env)
        end, function()
            return getfenv(func)
        end)

        return coroutine.wrap(function(...)
            setidentity(2)
            setfenv(0, fenv)
            setfenv(1, fenv)
            return func(...)
        end)(...)
    elseif identifyexecutor and string.match(identifyexecutor(), "Fluxus") or identifyexecutor and string.match(identifyexecutor(), "Electron") then
        return coroutine.wrap(function(...)
            setthreadcontext(2)
            setfenv(0, getsenv(Script))
            setfenv(1, getsenv(Script))
            return Function(...)
        end)(...)
    else
        error("Unsupported executor")
    end
end

return API
