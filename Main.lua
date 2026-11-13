-- FemBoyStrawberry.GG
-- Main script — loads custom library from GitHub

if not game:IsLoaded() then game.Loaded:Wait() end
if not syn or not protectgui then getgenv().protectgui = function() end end

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Acuz3D/FemBoyStrawberryGG/main/Library.lua"))()

local SilentAimSettings = {
    Enabled = false,
    TeamCheck = false,
    VisibleCheck = false,
    TargetPart = "HumanoidRootPart",
    SilentAimMethod = "Raycast",
    FOVRadius = 130,
    FOVVisible = false,
    ShowSilentAimTarget = false,
    MouseHitPrediction = false,
    MouseHitPredictionAmount = 0.165,
    HitChance = 100
}
getgenv().SilentAimSettings = SilentAimSettings

local MainFileName = "UniversalSilentAim"
local FileToSave = ""

local Camera          = workspace.CurrentCamera
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UserInputService= game:GetService("UserInputService")
local HttpService     = game:GetService("HttpService")
local CoreGui         = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

local GetPlayers            = Players.GetPlayers
local WorldToScreen         = Camera.WorldToScreenPoint
local WorldToViewportPoint  = Camera.WorldToViewportPoint
local GetPartsObscuringTarget = Camera.GetPartsObscuringTarget
local FindFirstChild        = game.FindFirstChild
local RenderStepped         = RunService.RenderStepped
local GetMouseLocation      = UserInputService.GetMouseLocation

local resume = coroutine.resume
local create = coroutine.create

local ValidTargetParts = {"Head","HumanoidRootPart"}
local PredictionAmount = 0.165
local RNG = Random.new()

local Unloaded       = false
local RenderConnection = nil
local ESPConnection  = nil
local oldNamecall    = nil
local oldIndex       = nil

-- ESP state
local Drawings   = {ESP={}, Skeleton={}}
local Highlights = {}

local ESPColors = {
    Enemy   = Color3.fromRGB(255, 25, 25),
    Ally    = Color3.fromRGB(25, 255, 25),
    Health  = Color3.fromRGB(0, 255, 0),
    Rainbow = nil,
}

local ESPSettings = {
    Enabled              = false,
    TeamCheck            = false,
    ShowTeam             = false,
    BoxESP               = false,
    BoxStyle             = "Corner",
    BoxThickness         = 1,
    TracerESP            = false,
    TracerOrigin         = "Bottom",
    TracerThickness      = 1,
    HealthESP            = false,
    HealthStyle          = "Bar",
    HealthTextSuffix     = "HP",
    NameESP              = false,
    NameMode             = "DisplayName",
    ShowDistance         = false,
    DistanceUnit         = "studs",
    TextSize             = 14,
    TextFont             = 2,
    MaxDistance          = 1000,
    RefreshRate          = 1/144,
    Snaplines            = false,
    RainbowEnabled       = false,
    RainbowBoxes         = false,
    RainbowTracers       = false,
    RainbowText          = false,
    RainbowSpeed         = 1,
    ChamsEnabled         = false,
    ChamsOutlineColor    = Color3.fromRGB(255,255,255),
    ChamsFillColor       = Color3.fromRGB(255,0,0),
    ChamsTransparency    = 0.5,
    ChamsOutlineTransparency = 0,
    SkeletonESP          = false,
    SkeletonColor        = Color3.fromRGB(255,255,255),
    SkeletonThickness    = 1.5,
    SkeletonTransparency = 1,
}

-- Silent aim drawings
local mouse_box = Drawing.new("Square")
mouse_box.Visible=false; mouse_box.ZIndex=999; mouse_box.Color=Color3.fromRGB(54,57,241)
mouse_box.Thickness=20; mouse_box.Size=Vector2.new(20,20); mouse_box.Filled=true

local fov_circle = Drawing.new("Circle")
fov_circle.Thickness=1; fov_circle.NumSides=100; fov_circle.Radius=180
fov_circle.Filled=false; fov_circle.Visible=false; fov_circle.ZIndex=999
fov_circle.Transparency=1; fov_circle.Color=Color3.fromRGB(54,57,241)

local ExpectedArguments = {
    FindPartOnRayWithIgnoreList = {ArgCountRequired=3, Args={"Instance","Ray","table","boolean","boolean"}},
    FindPartOnRayWithWhitelist  = {ArgCountRequired=3, Args={"Instance","Ray","table","boolean"}},
    FindPartOnRay               = {ArgCountRequired=2, Args={"Instance","Ray","Instance","boolean","boolean"}},
    Raycast                     = {ArgCountRequired=3, Args={"Instance","Vector3","Vector3","RaycastParams"}},
}

function CalculateChance(Percentage)
    Percentage=math.floor(Percentage)
    local chance=math.floor(RNG:NextNumber(0,1)*100)/100
    return chance<=Percentage/100
end

do
    if not isfolder(MainFileName) then makefolder(MainFileName) end
    if not isfolder(("%s/%s"):format(MainFileName,tostring(game.PlaceId))) then
        makefolder(("%s/%s"):format(MainFileName,tostring(game.PlaceId)))
    end
end

local function GetFiles()
    local files=listfiles(("%s/%s"):format(MainFileName,tostring(game.PlaceId)))
    local out={}
    for _,file in ipairs(files) do
        if file:sub(-4)=='.lua' then
            local pos=file:find('.lua',1,true); local start=pos
            local char=file:sub(pos,pos)
            while char~='/' and char~='\\' and char~='' do pos=pos-1; char=file:sub(pos,pos) end
            if char=='/' or char=='\\' then table.insert(out,file:sub(pos+1,start-1)) end
        end
    end
    return out
end

local function UpdateFile(n) assert(type(n)=="string"); writefile(("%s/%s/%s.lua"):format(MainFileName,tostring(game.PlaceId),n),HttpService:JSONEncode(SilentAimSettings)) end
local function LoadFile(n)
    assert(type(n)=="string")
    local d=HttpService:JSONDecode(readfile(("%s/%s/%s.lua"):format(MainFileName,tostring(game.PlaceId),n)))
    for k,v in next,d do SilentAimSettings[k]=v end
end
local function DeleteFile(n)
    assert(type(n)=="string")
    local p=("%s/%s/%s.lua"):format(MainFileName,tostring(game.PlaceId),n)
    if isfile(p) then delfile(p) end
end

local function getPositionOnScreen(v)
    local v3,on=WorldToScreen(Camera,v); return Vector2.new(v3.X,v3.Y),on
end
local function ValidateArguments(Args,RM)
    local m=0; if #Args<RM.ArgCountRequired then return false end
    for p,a in next,Args do if typeof(a)==RM.Args[p] then m+=1 end end
    return m>=RM.ArgCountRequired
end
local function getDirection(O,P) return (P-O).Unit*1000 end
local function getMousePosition() return GetMouseLocation(UserInputService) end

local function IsPlayerVisible(Player)
    local pc=Player.Character; local lc=LocalPlayer.Character
    if not(pc and lc) then return false end
    local pr=FindFirstChild(pc,Options.TargetPart.Value) or FindFirstChild(pc,"HumanoidRootPart")
    if not pr then return false end
    return #GetPartsObscuringTarget(Camera,{pr.Position},{lc,pc})==0
end

local function getClosestPlayer()
    if not Options.TargetPart.Value then return end
    local Closest,DTM
    for _,Player in next,GetPlayers(Players) do
        if Player==LocalPlayer then continue end
        if Toggles.TeamCheck.Value and Player.Team==LocalPlayer.Team then continue end
        local C=Player.Character; if not C then continue end
        if Toggles.VisibleCheck.Value and not IsPlayerVisible(Player) then continue end
        local HRP=FindFirstChild(C,"HumanoidRootPart"); local Hum=FindFirstChild(C,"Humanoid")
        if not HRP or not Hum or Hum.Health<=0 then continue end
        local SP,OS=getPositionOnScreen(HRP.Position); if not OS then continue end
        local D=(getMousePosition()-SP).Magnitude
        local R=Options.Radius.Value or 2000
        if D<=(DTM or R) then
            local TV=Options.TargetPart.Value
            Closest=(TV=="Random" and C[ValidTargetParts[math.random(1,#ValidTargetParts)]]) or C[TV]
            DTM=D
        end
    end
    return Closest
end

-- ESP helpers
local function GetPlayerColor(p)
    if ESPSettings.RainbowEnabled and ESPColors.Rainbow then return ESPColors.Rainbow end
    return (p.Team==LocalPlayer.Team) and ESPColors.Ally or ESPColors.Enemy
end
local function GetTracerOrigin()
    if ESPSettings.TracerOrigin=="Bottom" then return Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y)
    elseif ESPSettings.TracerOrigin=="Top" then return Vector2.new(Camera.ViewportSize.X/2,0)
    elseif ESPSettings.TracerOrigin=="Mouse" then return UserInputService:GetMouseLocation()
    else return Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2) end
end

local function CreateESP(player)
    if player==LocalPlayer then return end
    if Drawings.ESP[player] then return end

    local box={
        TopLeft=Drawing.new("Line"),TopRight=Drawing.new("Line"),
        BottomLeft=Drawing.new("Line"),BottomRight=Drawing.new("Line"),
        Left=Drawing.new("Line"),Right=Drawing.new("Line"),
        Top=Drawing.new("Line"),Bottom=Drawing.new("Line"),
    }
    for _,l in pairs(box) do l.Visible=false;l.Color=ESPColors.Enemy;l.Thickness=ESPSettings.BoxThickness end

    local tracer=Drawing.new("Line"); tracer.Visible=false; tracer.Color=ESPColors.Enemy; tracer.Thickness=ESPSettings.TracerThickness

    local hb={Outline=Drawing.new("Square"),Fill=Drawing.new("Square"),Text=Drawing.new("Text")}
    hb.Fill.Filled=true; hb.Fill.Color=ESPColors.Health
    hb.Text.Center=true; hb.Text.Size=ESPSettings.TextSize; hb.Text.Font=ESPSettings.TextFont; hb.Text.Color=ESPColors.Health
    for _,o in pairs(hb) do o.Visible=false end

    local info={Name=Drawing.new("Text"),Distance=Drawing.new("Text")}
    for _,t in pairs(info) do t.Visible=false;t.Center=true;t.Size=ESPSettings.TextSize;t.Color=ESPColors.Enemy;t.Font=ESPSettings.TextFont;t.Outline=true end

    local snapline=Drawing.new("Line"); snapline.Visible=false; snapline.Color=ESPColors.Enemy; snapline.Thickness=1

    -- Highlight stored in Highlights table, NOT a local — this was the bug
    local hl=Instance.new("Highlight")
    hl.FillColor=ESPSettings.ChamsFillColor; hl.OutlineColor=ESPSettings.ChamsOutlineColor
    hl.FillTransparency=ESPSettings.ChamsTransparency; hl.OutlineTransparency=ESPSettings.ChamsOutlineTransparency
    hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.Enabled=false
    Highlights[player]=hl

    local skeleton={}
    for _,k in ipairs({"Head","Neck","UpperSpine","LowerSpine","LeftShoulder","LeftUpperArm","LeftLowerArm","LeftHand","RightShoulder","RightUpperArm","RightLowerArm","RightHand","LeftHip","LeftUpperLeg","LeftLowerLeg","LeftFoot","RightHip","RightUpperLeg","RightLowerLeg","RightFoot"}) do
        local l=Drawing.new("Line"); l.Visible=false; l.Color=ESPSettings.SkeletonColor; l.Thickness=ESPSettings.SkeletonThickness; l.Transparency=ESPSettings.SkeletonTransparency
        skeleton[k]=l
    end
    Drawings.Skeleton[player]=skeleton
    Drawings.ESP[player]={Box=box,Tracer=tracer,HealthBar=hb,Info=info,Snapline=snapline}
end

local function RemoveESP(player)
    local esp=Drawings.ESP[player]
    if esp then
        for _,o in pairs(esp.Box) do o:Remove() end
        esp.Tracer:Remove()
        for _,o in pairs(esp.HealthBar) do o:Remove() end
        for _,o in pairs(esp.Info) do o:Remove() end
        esp.Snapline:Remove()
        Drawings.ESP[player]=nil
    end
    local hl=Highlights[player]
    if hl then hl:Destroy(); Highlights[player]=nil end
    local sk=Drawings.Skeleton[player]
    if sk then for _,l in pairs(sk) do l:Remove() end; Drawings.Skeleton[player]=nil end
end

local function HideAll(esp,sk)
    if esp then
        for _,o in pairs(esp.Box) do o.Visible=false end
        esp.Tracer.Visible=false
        for _,o in pairs(esp.HealthBar) do o.Visible=false end
        for _,o in pairs(esp.Info) do o.Visible=false end
        esp.Snapline.Visible=false
    end
    if sk then for _,l in pairs(sk) do l.Visible=false end end
end

local function UpdateESP(player)
    local esp=Drawings.ESP[player]; if not esp then return end
    local sk=Drawings.Skeleton[player]
    local char=player.Character; if not char then HideAll(esp,sk); return end
    local root=char:FindFirstChild("HumanoidRootPart"); if not root then HideAll(esp,sk); return end
    local hum=char:FindFirstChild("Humanoid"); if not hum or hum.Health<=0 then HideAll(esp,sk); return end
    local pos,onScreen=Camera:WorldToViewportPoint(root.Position)
    if not onScreen then HideAll(esp,sk); return end
    local dist=(root.Position-Camera.CFrame.Position).Magnitude
    if dist>ESPSettings.MaxDistance then HideAll(esp,sk); return end
    if ESPSettings.TeamCheck and player.Team==LocalPlayer.Team and not ESPSettings.ShowTeam then HideAll(esp,sk); return end

    local color=GetPlayerColor(player)
    local size=char:GetExtentsSize(); local cf=root.CFrame
    local top=Camera:WorldToViewportPoint((cf*CFrame.new(0,size.Y/2,0)).Position)
    local bottom=Camera:WorldToViewportPoint((cf*CFrame.new(0,-size.Y/2,0)).Position)
    local sH=bottom.Y-top.Y; local bW=sH*0.65
    local bPos=Vector2.new(top.X-bW/2,top.Y); local bSize=Vector2.new(bW,sH)

    for _,o in pairs(esp.Box) do o.Visible=false end

    if ESPSettings.BoxESP then
        if ESPSettings.BoxStyle=="Corner" then
            local cs=bW*0.2
            local ld={
                {esp.Box.TopLeft,    bPos,                            bPos+Vector2.new(cs,0)},
                {esp.Box.TopRight,   bPos+Vector2.new(bSize.X,0),    bPos+Vector2.new(bSize.X-cs,0)},
                {esp.Box.BottomLeft, bPos+Vector2.new(0,bSize.Y),    bPos+Vector2.new(cs,bSize.Y)},
                {esp.Box.BottomRight,bPos+bSize,                     bPos+Vector2.new(bSize.X-cs,bSize.Y)},
                {esp.Box.Left,       bPos,                            bPos+Vector2.new(0,cs)},
                {esp.Box.Right,      bPos+Vector2.new(bSize.X,0),    bPos+Vector2.new(bSize.X,cs)},
                {esp.Box.Top,        bPos+Vector2.new(0,bSize.Y),    bPos+Vector2.new(0,bSize.Y-cs)},
                {esp.Box.Bottom,     bPos+bSize,                     bPos+Vector2.new(bSize.X,bSize.Y-cs)},
            }
            for _,d in ipairs(ld) do d[1].From=d[2];d[1].To=d[3];d[1].Color=color;d[1].Thickness=ESPSettings.BoxThickness;d[1].Visible=true end
        elseif ESPSettings.BoxStyle=="Full" then
            local ld={
                {esp.Box.Left,  bPos,                         bPos+Vector2.new(0,bSize.Y)},
                {esp.Box.Right, bPos+Vector2.new(bSize.X,0),  bPos+bSize},
                {esp.Box.Top,   bPos,                         bPos+Vector2.new(bSize.X,0)},
                {esp.Box.Bottom,bPos+Vector2.new(0,bSize.Y),  bPos+bSize},
            }
            for _,d in ipairs(ld) do d[1].From=d[2];d[1].To=d[3];d[1].Color=color;d[1].Thickness=ESPSettings.BoxThickness;d[1].Visible=true end
        elseif ESPSettings.BoxStyle=="ThreeD" then
            local function wp(v) local p=Camera:WorldToViewportPoint((cf*CFrame.new(v)).Position); return Vector2.new(p.X,p.Y) end
            local f={TL=wp(Vector3.new(-size.X/2,size.Y/2,-size.Z/2)),TR=wp(Vector3.new(size.X/2,size.Y/2,-size.Z/2)),BL=wp(Vector3.new(-size.X/2,-size.Y/2,-size.Z/2)),BR=wp(Vector3.new(size.X/2,-size.Y/2,-size.Z/2))}
            local b={TL=wp(Vector3.new(-size.X/2,size.Y/2,size.Z/2)),TR=wp(Vector3.new(size.X/2,size.Y/2,size.Z/2)),BL=wp(Vector3.new(-size.X/2,-size.Y/2,size.Z/2)),BR=wp(Vector3.new(size.X/2,-size.Y/2,size.Z/2))}
            local ld={{esp.Box.TopLeft,f.TL,f.TR},{esp.Box.TopRight,f.TR,f.BR},{esp.Box.BottomLeft,f.BL,f.BR},{esp.Box.BottomRight,f.TL,f.BL},{esp.Box.Left,b.TL,b.TR},{esp.Box.Right,b.TR,b.BR},{esp.Box.Top,b.BL,b.BR},{esp.Box.Bottom,b.TL,b.BL}}
            for _,d in ipairs(ld) do d[1].From=d[2];d[1].To=d[3];d[1].Color=color;d[1].Thickness=ESPSettings.BoxThickness;d[1].Visible=true end
            task.spawn(function()
                local cl={}
                for _,pair in ipairs({{f.TL,b.TL},{f.TR,b.TR},{f.BL,b.BL},{f.BR,b.BR}}) do
                    local l=Drawing.new("Line");l.From=pair[1];l.To=pair[2];l.Color=color;l.Thickness=ESPSettings.BoxThickness;l.Visible=true
                    table.insert(cl,l)
                end
                task.wait()
                for _,l in ipairs(cl) do l:Remove() end
            end)
        end
    end

    if ESPSettings.TracerESP then
        esp.Tracer.From=GetTracerOrigin(); esp.Tracer.To=Vector2.new(pos.X,pos.Y)
        esp.Tracer.Color=color; esp.Tracer.Visible=true
    else esp.Tracer.Visible=false end

    if ESPSettings.HealthESP then
        local hp=hum.Health/hum.MaxHealth
        local bH=sH*0.8; local bW2=4
        local bP=Vector2.new(bPos.X-bW2-2,bPos.Y+(sH-bH)/2)
        esp.HealthBar.Outline.Size=Vector2.new(bW2,bH); esp.HealthBar.Outline.Position=bP; esp.HealthBar.Outline.Visible=true
        esp.HealthBar.Fill.Size=Vector2.new(bW2-2,bH*hp); esp.HealthBar.Fill.Position=Vector2.new(bP.X+1,bP.Y+bH*(1-hp))
        esp.HealthBar.Fill.Color=Color3.fromRGB(255-(255*hp),255*hp,0); esp.HealthBar.Fill.Visible=true
        if ESPSettings.HealthStyle=="Both" or ESPSettings.HealthStyle=="Text" then
            esp.HealthBar.Text.Text=math.floor(hum.Health)..ESPSettings.HealthTextSuffix
            esp.HealthBar.Text.Position=Vector2.new(bP.X+bW2+2,bP.Y+bH/2); esp.HealthBar.Text.Visible=true
        else esp.HealthBar.Text.Visible=false end
    else for _,o in pairs(esp.HealthBar) do o.Visible=false end end

    if ESPSettings.NameESP then
        local ns=(ESPSettings.NameMode=="DisplayName") and player.DisplayName or player.Name
        if ESPSettings.ShowDistance then ns=ns.." ["..math.floor(dist)..ESPSettings.DistanceUnit.."]" end
        esp.Info.Name.Text=ns; esp.Info.Name.Position=Vector2.new(bPos.X+bW/2,bPos.Y-18)
        esp.Info.Name.Color=color; esp.Info.Name.Size=ESPSettings.TextSize; esp.Info.Name.Visible=true
    else esp.Info.Name.Visible=false end

    if ESPSettings.ShowDistance and not ESPSettings.NameESP then
        esp.Info.Distance.Text=math.floor(dist)..ESPSettings.DistanceUnit
        esp.Info.Distance.Position=Vector2.new(bPos.X+bW/2,bPos.Y-18)
        esp.Info.Distance.Color=color; esp.Info.Distance.Size=ESPSettings.TextSize; esp.Info.Distance.Visible=true
    else esp.Info.Distance.Visible=false end

    if ESPSettings.Snaplines then
        esp.Snapline.From=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y)
        esp.Snapline.To=Vector2.new(pos.X,pos.Y); esp.Snapline.Color=color; esp.Snapline.Visible=true
    else esp.Snapline.Visible=false end

    -- Fixed: use Highlights[player] not a stale local
    local hl=Highlights[player]
    if hl then
        if ESPSettings.ChamsEnabled and char then
            hl.Parent=char
            hl.FillColor=ESPSettings.ChamsFillColor
            hl.OutlineColor=ESPSettings.ChamsOutlineColor
            hl.FillTransparency=ESPSettings.ChamsTransparency
            hl.OutlineTransparency=ESPSettings.ChamsOutlineTransparency
            hl.Enabled=true
        else
            hl.Enabled=false
            hl.Parent=nil
        end
    end

    if ESPSettings.SkeletonESP then
        local function gb(n,f) return char:FindFirstChild(n) or (f and char:FindFirstChild(f)) end
        local bn={
            Head=gb("Head"),UpperTorso=gb("UpperTorso","Torso"),LowerTorso=gb("LowerTorso","Torso"),
            LeftUpperArm=gb("LeftUpperArm","Left Arm"),LeftLowerArm=gb("LeftLowerArm","Left Arm"),LeftHand=gb("LeftHand","Left Arm"),
            RightUpperArm=gb("RightUpperArm","Right Arm"),RightLowerArm=gb("RightLowerArm","Right Arm"),RightHand=gb("RightHand","Right Arm"),
            LeftUpperLeg=gb("LeftUpperLeg","Left Leg"),LeftLowerLeg=gb("LeftLowerLeg","Left Leg"),LeftFoot=gb("LeftFoot","Left Leg"),
            RightUpperLeg=gb("RightUpperLeg","Right Leg"),RightLowerLeg=gb("RightLowerLeg","Right Leg"),RightFoot=gb("RightFoot","Right Leg"),
        }
        local function db(from,to,line)
            if not from or not to then line.Visible=false; return end
            local fs,fv=Camera:WorldToViewportPoint(from.CFrame.Position)
            local ts,tv=Camera:WorldToViewportPoint(to.CFrame.Position)
            if not(fv and tv) or fs.Z<0 or ts.Z<0 then line.Visible=false; return end
            line.From=Vector2.new(fs.X,fs.Y); line.To=Vector2.new(ts.X,ts.Y)
            line.Color=ESPSettings.SkeletonColor; line.Thickness=ESPSettings.SkeletonThickness
            line.Transparency=ESPSettings.SkeletonTransparency; line.Visible=true
        end
        if sk and bn.Head and bn.UpperTorso then
            db(bn.Head,bn.UpperTorso,sk.Head); db(bn.UpperTorso,bn.LowerTorso,sk.UpperSpine)
            db(bn.UpperTorso,bn.LeftUpperArm,sk.LeftShoulder); db(bn.LeftUpperArm,bn.LeftLowerArm,sk.LeftUpperArm)
            db(bn.LeftLowerArm,bn.LeftHand,sk.LeftLowerArm); db(bn.UpperTorso,bn.RightUpperArm,sk.RightShoulder)
            db(bn.RightUpperArm,bn.RightLowerArm,sk.RightUpperArm); db(bn.RightLowerArm,bn.RightHand,sk.RightLowerArm)
            db(bn.LowerTorso,bn.LeftUpperLeg,sk.LeftHip); db(bn.LeftUpperLeg,bn.LeftLowerLeg,sk.LeftUpperLeg)
            db(bn.LeftLowerLeg,bn.LeftFoot,sk.LeftLowerLeg); db(bn.LowerTorso,bn.RightUpperLeg,sk.RightHip)
            db(bn.RightUpperLeg,bn.RightLowerLeg,sk.RightUpperLeg); db(bn.RightLowerLeg,bn.RightFoot,sk.RightLowerLeg)
        end
    else
        if sk then for _,l in pairs(sk) do l.Visible=false end end
    end
end

local function CleanupESP()
    for _,p in ipairs(Players:GetPlayers()) do RemoveESP(p) end
    Drawings.ESP={}; Drawings.Skeleton={}; Highlights={}
end

local function DisableAllESP()
    for _,p in ipairs(Players:GetPlayers()) do HideAll(Drawings.ESP[p],Drawings.Skeleton[p]) end
end

local function RefreshConfigDropdown()
    local fresh=GetFiles()
    Options.ConfigDropdown:SetValues(fresh)
    if not table.find(fresh,Options.ConfigDropdown.Value) then Options.ConfigDropdown:SetValue(nil) end
end

local function Unload()
    Unloaded=true
    if RenderConnection then RenderConnection:Disconnect(); RenderConnection=nil end
    if ESPConnection then ESPConnection:Disconnect(); ESPConnection=nil end
    CleanupESP()
    mouse_box.Visible=false; fov_circle.Visible=false
    mouse_box:Remove(); fov_circle:Remove()
    pcall(function()
        local gui=CoreGui:FindFirstChild("ScreenGui")
        if gui then gui:Destroy() end
        local gui2=CoreGui:FindFirstChild("FBSLib")
        if gui2 then gui2:Destroy() end
    end)
end

-- UI
Library:SetWatermark("FemBoyStrawberry.GG")
local Window=Library:CreateWindow({Title="FemBoyStrawberry.GG", Center=true})

-- AIM TAB
local AimTab=Window:AddTab("Aim")

local MainBOX=AimTab:AddLeftTabbox("Main")
do
    local Main=MainBOX:AddTab("Main")
    Main:AddToggle("aim_Enabled",{Text="Enabled"}):AddKeyPicker("aim_Enabled_KeyPicker",{Default="RightAlt",SyncToggleState=true,Mode="Toggle",Text="Enabled"})
    Options.aim_Enabled_KeyPicker:OnClick(function()
        SilentAimSettings.Enabled=not SilentAimSettings.Enabled
        Toggles.aim_Enabled:SetValue(SilentAimSettings.Enabled)
        mouse_box.Visible=SilentAimSettings.Enabled
    end)
    Main:AddToggle("TeamCheck",{Text="Team Check",Default=false}):OnChanged(function() SilentAimSettings.TeamCheck=Toggles.TeamCheck.Value end)
    Main:AddToggle("VisibleCheck",{Text="Visible Check",Default=false}):OnChanged(function() SilentAimSettings.VisibleCheck=Toggles.VisibleCheck.Value end)
    Main:AddDropdown("TargetPart",{AllowNull=true,Text="Target Part",Default="HumanoidRootPart",Values={"Head","HumanoidRootPart","Random"}}):OnChanged(function() SilentAimSettings.TargetPart=Options.TargetPart.Value end)
    Main:AddDropdown("Method",{AllowNull=true,Text="Aim Method",Default="Raycast",Values={"Raycast","FindPartOnRay","FindPartOnRayWithWhitelist","FindPartOnRayWithIgnoreList","Mouse.Hit/Target"}}):OnChanged(function() SilentAimSettings.SilentAimMethod=Options.Method.Value end)
    Main:AddSlider("HitChance",{Text="Hit Chance",Default=100,Min=0,Max=100,Rounding=1})
    Options.HitChance:OnChanged(function() SilentAimSettings.HitChance=Options.HitChance.Value end)
end

local MiscBOX=AimTab:AddLeftTabbox("Miscellaneous")
local FOVBOX=AimTab:AddLeftTabbox("Field Of View")
do
    local Main=FOVBOX:AddTab("Visuals")
    Main:AddToggle("Visible",{Text="Show FOV Circle"}):AddColorPicker("Color",{Default=Color3.fromRGB(54,57,241)}):OnChanged(function()
        fov_circle.Visible=Toggles.Visible.Value; SilentAimSettings.FOVVisible=Toggles.Visible.Value
    end)
    Main:AddSlider("Radius",{Text="FOV Radius",Min=0,Max=360,Default=130,Rounding=0}):OnChanged(function()
        fov_circle.Radius=Options.Radius.Value; SilentAimSettings.FOVRadius=Options.Radius.Value
    end)
    Main:AddToggle("MousePosition",{Text="Show Aim Target"}):AddColorPicker("MouseVisualizeColor",{Default=Color3.fromRGB(54,57,241)}):OnChanged(function()
        mouse_box.Visible=Toggles.MousePosition.Value; SilentAimSettings.ShowSilentAimTarget=Toggles.MousePosition.Value
    end)
    local PT=MiscBOX:AddTab("Prediction")
    PT:AddToggle("Prediction",{Text="Hit Prediction"}):OnChanged(function() SilentAimSettings.MouseHitPrediction=Toggles.Prediction.Value end)
    PT:AddSlider("Amount",{Text="Prediction Amount",Min=0.165,Max=1,Default=0.165,Rounding=3}):OnChanged(function()
        PredictionAmount=Options.Amount.Value; SilentAimSettings.MouseHitPredictionAmount=Options.Amount.Value
    end)
end

-- ESP TAB
local ESPTab=Window:AddTab("ESP")

local ESPLeftBOX=ESPTab:AddLeftTabbox("ESP")
do
    local Main=ESPLeftBOX:AddTab("Main")
    Main:AddToggle("ESPEnabled",{Text="Enable ESP",Default=false}):OnChanged(function()
        ESPSettings.Enabled=Toggles.ESPEnabled.Value
        if not ESPSettings.Enabled then
            CleanupESP()
        else
            for _,p in ipairs(Players:GetPlayers()) do
                if p~=LocalPlayer then CreateESP(p) end
            end
        end
    end)
    Main:AddToggle("ESPTeamCheck",{Text="Team Check",Default=false}):OnChanged(function() ESPSettings.TeamCheck=Toggles.ESPTeamCheck.Value end)
    Main:AddToggle("ESPShowTeam",{Text="Show Team",Default=false}):OnChanged(function() ESPSettings.ShowTeam=Toggles.ESPShowTeam.Value end)
    Main:AddSlider("ESPMaxDistance",{Text="Max Distance",Min=100,Max=5000,Default=1000,Rounding=0}):OnChanged(function() ESPSettings.MaxDistance=Options.ESPMaxDistance.Value end)

    local Box=ESPLeftBOX:AddTab("Box")
    Box:AddToggle("BoxESP",{Text="Box ESP",Default=false}):OnChanged(function() ESPSettings.BoxESP=Toggles.BoxESP.Value end)
    Box:AddDropdown("BoxStyle",{Text="Style",Default="Corner",Values={"Corner","Full","ThreeD"}}):OnChanged(function() ESPSettings.BoxStyle=Options.BoxStyle.Value end)
    Box:AddSlider("BoxThickness",{Text="Thickness",Min=1,Max=5,Default=1,Rounding=1}):OnChanged(function() ESPSettings.BoxThickness=Options.BoxThickness.Value end)
    Box:AddToggle("TracerESP",{Text="Tracer ESP",Default=false}):OnChanged(function() ESPSettings.TracerESP=Toggles.TracerESP.Value end)
    Box:AddDropdown("TracerOrigin",{Text="Tracer Origin",Default="Bottom",Values={"Bottom","Top","Mouse","Center"}}):OnChanged(function() ESPSettings.TracerOrigin=Options.TracerOrigin.Value end)
    Box:AddSlider("TracerThickness",{Text="Tracer Thickness",Min=1,Max=5,Default=1,Rounding=1}):OnChanged(function() ESPSettings.TracerThickness=Options.TracerThickness.Value end)
    Box:AddToggle("Snaplines",{Text="Snaplines",Default=false}):OnChanged(function() ESPSettings.Snaplines=Toggles.Snaplines.Value end)
end

local ESPRightBOX=ESPTab:AddRightTabbox("Details")
do
    local Health=ESPRightBOX:AddTab("Health")
    Health:AddToggle("HealthESP",{Text="Health Bar",Default=false}):OnChanged(function() ESPSettings.HealthESP=Toggles.HealthESP.Value end)
    Health:AddDropdown("HealthStyle",{Text="Style",Default="Bar",Values={"Bar","Text","Both"}}):OnChanged(function() ESPSettings.HealthStyle=Options.HealthStyle.Value end)

    local Name=ESPRightBOX:AddTab("Name")
    Name:AddToggle("NameESP",{Text="Name ESP",Default=false}):OnChanged(function() ESPSettings.NameESP=Toggles.NameESP.Value end)
    Name:AddDropdown("NameMode",{Text="Mode",Default="DisplayName",Values={"DisplayName","Username"}}):OnChanged(function() ESPSettings.NameMode=Options.NameMode.Value end)
    Name:AddToggle("ShowDistance",{Text="Show Distance",Default=false}):OnChanged(function() ESPSettings.ShowDistance=Toggles.ShowDistance.Value end)
    Name:AddDropdown("DistanceUnit",{Text="Unit",Default="studs",Values={"studs","m"}}):OnChanged(function() ESPSettings.DistanceUnit=Options.DistanceUnit.Value end)
    Name:AddSlider("ESPTextSize",{Text="Text Size",Min=10,Max=24,Default=14,Rounding=0}):OnChanged(function() ESPSettings.TextSize=Options.ESPTextSize.Value end)

    local Chams=ESPRightBOX:AddTab("Chams")
    Chams:AddToggle("ChamsEnabled",{Text="Enable Chams",Default=false}):OnChanged(function() ESPSettings.ChamsEnabled=Toggles.ChamsEnabled.Value end)
    Chams:AddColorPicker("ChamsFillColor",{Text="Fill Color",Default=Color3.fromRGB(255,0,0)}):OnChanged(function() ESPSettings.ChamsFillColor=Options.ChamsFillColor.Value end)
    Chams:AddColorPicker("ChamsOutlineColor",{Text="Outline Color",Default=Color3.fromRGB(255,255,255)}):OnChanged(function() ESPSettings.ChamsOutlineColor=Options.ChamsOutlineColor.Value end)
    Chams:AddSlider("ChamsTransparency",{Text="Fill Transparency",Min=0,Max=1,Default=0.5,Rounding=2}):OnChanged(function() ESPSettings.ChamsTransparency=Options.ChamsTransparency.Value end)
    Chams:AddSlider("ChamsOutlineTransparency",{Text="Outline Transparency",Min=0,Max=1,Default=0,Rounding=2}):OnChanged(function() ESPSettings.ChamsOutlineTransparency=Options.ChamsOutlineTransparency.Value end)

    local Skel=ESPRightBOX:AddTab("Skeleton")
    Skel:AddToggle("SkeletonESP",{Text="Skeleton ESP",Default=false}):OnChanged(function() ESPSettings.SkeletonESP=Toggles.SkeletonESP.Value end)
    Skel:AddColorPicker("SkeletonColor",{Text="Color",Default=Color3.fromRGB(255,255,255)}):OnChanged(function()
        ESPSettings.SkeletonColor=Options.SkeletonColor.Value
        for _,p in ipairs(Players:GetPlayers()) do local sk=Drawings.Skeleton[p]; if sk then for _,l in pairs(sk) do l.Color=ESPSettings.SkeletonColor end end end
    end)
    Skel:AddSlider("SkeletonThickness",{Text="Thickness",Min=1,Max=3,Default=1,Rounding=1}):OnChanged(function()
        ESPSettings.SkeletonThickness=Options.SkeletonThickness.Value
        for _,p in ipairs(Players:GetPlayers()) do local sk=Drawings.Skeleton[p]; if sk then for _,l in pairs(sk) do l.Thickness=ESPSettings.SkeletonThickness end end end
    end)
    Skel:AddSlider("SkeletonTransparency",{Text="Transparency",Min=0,Max=1,Default=1,Rounding=2}):OnChanged(function()
        ESPSettings.SkeletonTransparency=Options.SkeletonTransparency.Value
        for _,p in ipairs(Players:GetPlayers()) do local sk=Drawings.Skeleton[p]; if sk then for _,l in pairs(sk) do l.Transparency=ESPSettings.SkeletonTransparency end end end
    end)

    local Colors=ESPRightBOX:AddTab("Colors")
    Colors:AddColorPicker("EnemyColor",{Text="Enemy",Default=Color3.fromRGB(255,25,25)}):OnChanged(function() ESPColors.Enemy=Options.EnemyColor.Value end)
    Colors:AddColorPicker("AllyColor",{Text="Ally",Default=Color3.fromRGB(25,255,25)}):OnChanged(function() ESPColors.Ally=Options.AllyColor.Value end)
    Colors:AddColorPicker("HealthColor",{Text="Health",Default=Color3.fromRGB(0,255,0)}):OnChanged(function() ESPColors.Health=Options.HealthColor.Value end)
    Colors:AddToggle("RainbowEnabled",{Text="Rainbow Mode",Default=false}):OnChanged(function() ESPSettings.RainbowEnabled=Toggles.RainbowEnabled.Value end)
    Colors:AddSlider("RainbowSpeed",{Text="Rainbow Speed",Min=0.1,Max=5,Default=1,Rounding=1}):OnChanged(function() ESPSettings.RainbowSpeed=Options.RainbowSpeed.Value end)
    Colors:AddDropdown("RainbowParts",{Text="Rainbow Parts",Default="All",Values={"All","Box Only","Tracers Only","Text Only"}}):OnChanged(function(v)
        ESPSettings.RainbowBoxes=v=="All" or v=="Box Only"
        ESPSettings.RainbowTracers=v=="All" or v=="Tracers Only"
        ESPSettings.RainbowText=v=="All" or v=="Text Only"
    end)
end

-- SETTINGS TAB
local SettingsTab=Window:AddTab("Settings")

local ConfigBOX=SettingsTab:AddLeftTabbox("Configuration")
do
    local Main=ConfigBOX:AddTab("Configuration")
    Main:AddDropdown("ConfigDropdown",{AllowNull=true,Values=GetFiles(),Text="Select Config"})
    Main:AddInput("ConfigNameInput",{Default="",Numeric=false,Finished=false,Text="Config Name",Placeholder="Enter name..."}):OnChanged(function()
        FileToSave=Options.ConfigNameInput.Value
    end)
    Main:AddButton("Create",function()
        if FileToSave and FileToSave~="" then UpdateFile(FileToSave); RefreshConfigDropdown(); Options.ConfigDropdown:SetValue(FileToSave) end
    end)
    Main:AddButton("Save",function()
        local s=Options.ConfigDropdown.Value; if s and s~="" then UpdateFile(s) end
    end)
    Main:AddButton("Load",function()
        local s=Options.ConfigDropdown.Value
        if s and table.find(GetFiles(),s) then
            LoadFile(s)
            Toggles.TeamCheck:SetValue(SilentAimSettings.TeamCheck)
            Toggles.VisibleCheck:SetValue(SilentAimSettings.VisibleCheck)
            Options.TargetPart:SetValue(SilentAimSettings.TargetPart)
            Options.Method:SetValue(SilentAimSettings.SilentAimMethod)
            Toggles.Visible:SetValue(SilentAimSettings.FOVVisible)
            Options.Radius:SetValue(SilentAimSettings.FOVRadius)
            Toggles.MousePosition:SetValue(SilentAimSettings.ShowSilentAimTarget)
            Toggles.Prediction:SetValue(SilentAimSettings.MouseHitPrediction)
            Options.Amount:SetValue(SilentAimSettings.MouseHitPredictionAmount)
            Options.HitChance:SetValue(SilentAimSettings.HitChance)
        end
    end)
    Main:AddButton("Overwrite",function()
        local s=Options.ConfigDropdown.Value; if s and s~="" then UpdateFile(s) end
    end)
    Main:AddButton("Delete",function()
        local s=Options.ConfigDropdown.Value; if s and s~="" then DeleteFile(s); RefreshConfigDropdown() end
    end)
end

local ScriptBOX=SettingsTab:AddRightTabbox("Script")
do
    local Main=ScriptBOX:AddTab("Script")
    Main:AddButton("Unload",function() Unload() end)
end

-- Rainbow loop
task.spawn(function()
    while task.wait(0.1) do
        if Unloaded then break end
        ESPColors.Rainbow=Color3.fromHSV(tick()*ESPSettings.RainbowSpeed%1,1,1)
    end
end)

-- Silent aim render loop
resume(create(function()
    RenderConnection=RenderStepped:Connect(function()
        if Unloaded then return end
        local AimOn=Toggles.aim_Enabled.Value
        if Toggles.MousePosition.Value and AimOn then
            local T=getClosestPlayer()
            if T then
                local Root=T.Parent.PrimaryPart or T
                local rvp,onS=WorldToViewportPoint(Camera,Root.Position)
                mouse_box.Visible=onS; mouse_box.Position=Vector2.new(rvp.X,rvp.Y)
            else mouse_box.Visible=false; mouse_box.Position=Vector2.new() end
        end
        if Toggles.Visible.Value then
            fov_circle.Visible=true; fov_circle.Color=Options.Color.Value; fov_circle.Position=getMousePosition()
        end
    end)
end))

-- ESP render loop
local lastUpdate=0
ESPConnection=RenderStepped:Connect(function()
    if Unloaded then return end
    if not ESPSettings.Enabled then DisableAllESP(); return end
    local now=tick()
    if now-lastUpdate>=ESPSettings.RefreshRate then
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LocalPlayer then
                if not Drawings.ESP[p] then CreateESP(p) end
                UpdateESP(p)
            end
        end
        lastUpdate=now
    end
end)

Players.PlayerAdded:Connect(function(p) if ESPSettings.Enabled then CreateESP(p) end end)
Players.PlayerRemoving:Connect(RemoveESP)

-- Hooks
oldNamecall=hookmetamethod(game,"__namecall",newcclosure(function(...)
    local Method=getnamecallmethod(); local Arguments={...}; local self=Arguments[1]
    if not Unloaded and Toggles.aim_Enabled.Value and self==workspace and not checkcaller() and CalculateChance(SilentAimSettings.HitChance) then
        local MV=Options.Method.Value
        local function rr(i)
            local hp=getClosestPlayer()
            if hp then local o=Arguments[i].Origin; Arguments[i]=Ray.new(o,getDirection(o,hp.Position)); return oldNamecall(unpack(Arguments)) end
        end
        if Method=="FindPartOnRayWithIgnoreList" and MV==Method then if ValidateArguments(Arguments,ExpectedArguments.FindPartOnRayWithIgnoreList) then return rr(2) end
        elseif Method=="FindPartOnRayWithWhitelist" and MV==Method then if ValidateArguments(Arguments,ExpectedArguments.FindPartOnRayWithWhitelist) then return rr(2) end
        elseif Method:lower()=="findpartonray" and MV:lower()==Method:lower() then if ValidateArguments(Arguments,ExpectedArguments.FindPartOnRay) then return rr(2) end
        elseif Method=="Raycast" and MV==Method then
            if ValidateArguments(Arguments,ExpectedArguments.Raycast) then
                local hp=getClosestPlayer(); if hp then Arguments[3]=getDirection(Arguments[2],hp.Position); return oldNamecall(unpack(Arguments)) end
            end
        end
    end
    return oldNamecall(...)
end))

oldIndex=hookmetamethod(game,"__index",newcclosure(function(self,Index)
    if not Unloaded and self==Mouse and not checkcaller() and Toggles.aim_Enabled.Value and Options.Method.Value=="Mouse.Hit/Target" then
        local hp=getClosestPlayer()
        if hp then
            if Index=="Target" or Index=="target" then return hp
            elseif Index=="Hit" or Index=="hit" then return Toggles.Prediction.Value and (hp.CFrame+(hp.Velocity*PredictionAmount)) or hp.CFrame
            elseif Index=="UnitRay" then return Ray.new(self.Origin,(self.Hit-self.Origin).Unit) end
        end
    end
    return oldIndex(self,Index)
end))
