-- FemBoyStrawberry.GG UI Library
-- Full drop-in replacement for LinoriaLib
-- API: AddToggle, AddSlider, AddDropdown, AddColorPicker, AddButton, AddInput, AddKeyPicker
-- AddLeftTabbox, AddRightTabbox — no tab limits

local Library = {}
Library.__index = Library

local Players         = game:GetService("Players")
local UserInputService= game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")
local CoreGui         = game:GetService("CoreGui")
local LocalPlayer     = Players.LocalPlayer

getgenv().Toggles = getgenv().Toggles or {}
getgenv().Options  = getgenv().Options  or {}
local Toggles = getgenv().Toggles
local Options  = getgenv().Options

local Theme = {
    Background       = Color3.fromRGB(18, 18, 22),
    TopBar           = Color3.fromRGB(13, 13, 16),
    TabBar           = Color3.fromRGB(22, 22, 28),
    TabActive        = Color3.fromRGB(54, 57, 241),
    TabInactive      = Color3.fromRGB(28, 28, 36),
    TabboxBG         = Color3.fromRGB(24, 24, 30),
    TabboxHeader     = Color3.fromRGB(40, 43, 180),
    TabboxHeaderText = Color3.fromRGB(255, 255, 255),
    Element          = Color3.fromRGB(30, 30, 40),
    ElementHover     = Color3.fromRGB(38, 38, 52),
    ElementBorder    = Color3.fromRGB(45, 45, 60),
    Text             = Color3.fromRGB(220, 220, 230),
    TextDim          = Color3.fromRGB(140, 140, 160),
    TextDisabled     = Color3.fromRGB(70, 70, 90),
    Accent           = Color3.fromRGB(54, 57, 241),
    AccentHover      = Color3.fromRGB(80, 85, 255),
    AccentDark       = Color3.fromRGB(35, 38, 160),
    Toggle_ON        = Color3.fromRGB(54, 57, 241),
    Toggle_OFF       = Color3.fromRGB(50, 50, 68),
    SliderFill       = Color3.fromRGB(54, 57, 241),
    SliderBG         = Color3.fromRGB(38, 38, 52),
    InputBG          = Color3.fromRGB(18, 18, 26),
    ScrollBar        = Color3.fromRGB(54, 57, 241),
    White            = Color3.fromRGB(255, 255, 255),
    Shadow           = Color3.fromRGB(0, 0, 0),
    Danger           = Color3.fromRGB(210, 55, 55),
    Success          = Color3.fromRGB(50, 200, 100),
}

local function Tween(obj, props, t)
    TweenService:Create(obj, TweenInfo.new(t or 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function Make(class, props)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then o[k] = v end
    end
    if props and props.Parent then o.Parent = props.Parent end
    return o
end

local function Corner(r, p) local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r or 4);c.Parent=p;return c end
local function Stroke(col, th, tr, p) local s=Instance.new("UIStroke");s.Color=col or Theme.ElementBorder;s.Thickness=th or 1;s.Transparency=tr or 0;s.Parent=p;return s end
local function Pad(t,b,l,r,p) local u=Instance.new("UIPadding");u.PaddingTop=UDim.new(0,t or 4);u.PaddingBottom=UDim.new(0,b or 4);u.PaddingLeft=UDim.new(0,l or 4);u.PaddingRight=UDim.new(0,r or 4);u.Parent=p;return u end
local function List(p,pad,fd,ha,va) local l=Instance.new("UIListLayout");l.Padding=UDim.new(0,pad or 4);l.FillDirection=fd or Enum.FillDirection.Vertical;l.HorizontalAlignment=ha or Enum.HorizontalAlignment.Left;l.VerticalAlignment=va or Enum.VerticalAlignment.Top;l.SortOrder=Enum.SortOrder.LayoutOrder;l.Parent=p;return l end

local function Draggable(handle, frame)
    local drag, ds, dp = false, nil, nil
    handle.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true;ds=i.Position;dp=frame.Position end end)
    UserInputService.InputChanged:Connect(function(i) if drag and i.UserInputType==Enum.UserInputType.MouseMovement then local d=i.Position-ds;frame.Position=UDim2.new(dp.X.Scale,dp.X.Offset+d.X,dp.Y.Scale,dp.Y.Offset+d.Y) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
end

local ScreenGui = Make("ScreenGui",{Name="FBSLib",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=999})
pcall(function() ScreenGui.Parent=CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent=LocalPlayer:WaitForChild("PlayerGui") end

-- Watermark
local WMBar = Make("Frame",{Parent=ScreenGui,Size=UDim2.new(0,200,0,24),Position=UDim2.new(0,8,0,8),BackgroundColor3=Theme.TopBar,BorderSizePixel=0,ZIndex=2})
Corner(4,WMBar); Stroke(Theme.Accent,1,0,WMBar)
local WMLabel = Make("TextLabel",{Parent=WMBar,Size=UDim2.new(1,-16,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,Text="FemBoyStrawberry.GG",TextColor3=Theme.Text,TextSize=13,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=3})

function Library:SetWatermark(text) WMLabel.Text=text end

function Library:CreateWindow(config)
    config=config or {}
    local title=config.Title or "FemBoyStrawberry.GG"
    local W,H=560,420

    local Root=Make("Frame",{Parent=ScreenGui,Size=UDim2.new(0,W,0,H),Position=UDim2.new(0.5,-W/2,0.5,-H/2),BackgroundColor3=Theme.Background,BorderSizePixel=0,ClipsDescendants=true,ZIndex=10})
    Corner(6,Root); Stroke(Theme.ElementBorder,1,0,Root)

    -- Top bar
    local Top=Make("Frame",{Parent=Root,Size=UDim2.new(1,0,0,36),BackgroundColor3=Theme.TopBar,BorderSizePixel=0,ZIndex=11})
    Corner(6,Top)
    Make("Frame",{Parent=Top,Size=UDim2.new(1,0,0.5,0),Position=UDim2.new(0,0,0.5,0),BackgroundColor3=Theme.TopBar,BorderSizePixel=0,ZIndex=11})
    Make("TextLabel",{Parent=Top,Size=UDim2.new(1,-80,1,0),Position=UDim2.new(0,12,0,0),BackgroundTransparency=1,Text=title,TextColor3=Theme.Text,TextSize=14,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12})
    Make("Frame",{Parent=Root,Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,0,36),BackgroundColor3=Theme.Accent,BorderSizePixel=0,ZIndex=11})

    -- Close
    local CloseBtn=Make("TextButton",{Parent=Top,Size=UDim2.new(0,26,0,18),Position=UDim2.new(1,-30,0.5,-9),BackgroundColor3=Theme.Danger,Text="×",TextColor3=Theme.White,TextSize=15,Font=Enum.Font.GothamBold,AutoButtonColor=false,ZIndex=13})
    Corner(4,CloseBtn)
    CloseBtn.MouseButton1Click:Connect(function() Root.Visible=false end)

    -- Minimize
    local MinBtn=Make("TextButton",{Parent=Top,Size=UDim2.new(0,26,0,18),Position=UDim2.new(1,-60,0.5,-9),BackgroundColor3=Theme.AccentDark,Text="−",TextColor3=Theme.White,TextSize=15,Font=Enum.Font.GothamBold,AutoButtonColor=false,ZIndex=13})
    Corner(4,MinBtn)
    local minimized=false
    MinBtn.MouseButton1Click:Connect(function()
        minimized=not minimized
        Tween(Root,{Size=minimized and UDim2.new(0,W,0,36) or UDim2.new(0,W,0,H)},0.2)
    end)

    Draggable(Top,Root)

    -- Tab bar
    local TabBar=Make("Frame",{Parent=Root,Size=UDim2.new(1,0,0,28),Position=UDim2.new(0,0,0,37),BackgroundColor3=Theme.TabBar,BorderSizePixel=0,ZIndex=11,ClipsDescendants=false})
    local TBLayout=List(TabBar,0,Enum.FillDirection.Horizontal,Enum.HorizontalAlignment.Left,Enum.VerticalAlignment.Center)
    Pad(0,0,6,6,TabBar)
    Make("Frame",{Parent=Root,Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,0,65),BackgroundColor3=Theme.ElementBorder,BorderSizePixel=0,ZIndex=11})

    -- Content
    local Content=Make("Frame",{Parent=Root,Size=UDim2.new(1,0,1,-66),Position=UDim2.new(0,0,0,66),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=11,ClipsDescendants=true})

    local ActivePage,ActiveTabBtn=nil,nil
    local Tabs={}
    local Window={}

    function Window:AddTab(name)
        local TabBtn=Make("TextButton",{Parent=TabBar,Size=UDim2.new(0,76,1,0),BackgroundColor3=Theme.TabInactive,Text=name,TextColor3=Theme.TextDim,TextSize=12,Font=Enum.Font.GothamSemibold,BorderSizePixel=0,AutoButtonColor=false,ZIndex=12})
        local Indicator=Make("Frame",{Parent=TabBtn,Size=UDim2.new(1,0,0,2),Position=UDim2.new(0,0,1,-2),BackgroundColor3=Theme.Accent,BorderSizePixel=0,Visible=false,ZIndex=13})

        local Page=Make("Frame",{Parent=Content,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,Visible=false,ZIndex=12})

        local LeftCol=Make("ScrollingFrame",{Parent=Page,Size=UDim2.new(0.5,-5,1,-6),Position=UDim2.new(0,4,0,3),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2,ScrollBarImageColor3=Theme.ScrollBar,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ZIndex=13})
        List(LeftCol,5); Pad(2,2,2,2,LeftCol)

        local RightCol=Make("ScrollingFrame",{Parent=Page,Size=UDim2.new(0.5,-5,1,-6),Position=UDim2.new(0.5,2,0,3),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2,ScrollBarImageColor3=Theme.ScrollBar,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ZIndex=13})
        List(RightCol,5); Pad(2,2,2,2,RightCol)

        local function Activate()
            if ActivePage then ActivePage.Visible=false end
            if ActiveTabBtn then
                Tween(ActiveTabBtn,{BackgroundColor3=Theme.TabInactive,TextColor3=Theme.TextDim},0.12)
                local ind=ActiveTabBtn:FindFirstChildOfClass("Frame")
                if ind then ind.Visible=false end
            end
            Page.Visible=true
            Tween(TabBtn,{BackgroundColor3=Theme.TabBar,TextColor3=Theme.White},0.12)
            Indicator.Visible=true
            ActivePage=Page; ActiveTabBtn=TabBtn
        end

        TabBtn.MouseButton1Click:Connect(Activate)
        TabBtn.MouseEnter:Connect(function() if TabBtn~=ActiveTabBtn then Tween(TabBtn,{BackgroundColor3=Theme.ElementHover},0.1) end end)
        TabBtn.MouseLeave:Connect(function() if TabBtn~=ActiveTabBtn then Tween(TabBtn,{BackgroundColor3=Theme.TabInactive},0.1) end end)
        if #Tabs==0 then Activate() end
        table.insert(Tabs,{Btn=TabBtn,Page=Page})

        local Tab={}

        local function MakeTabbox(col, label)
            local Box=Make("Frame",{Parent=col,Size=UDim2.new(1,0,0,0),BackgroundColor3=Theme.TabboxBG,BorderSizePixel=0,AutomaticSize=Enum.AutomaticSize.Y,ZIndex=col.ZIndex+1})
            Corner(5,Box); Stroke(Theme.ElementBorder,1,0,Box)

            local Hdr=Make("Frame",{Parent=Box,Size=UDim2.new(1,0,0,22),BackgroundColor3=Theme.TabboxHeader,BorderSizePixel=0,ZIndex=Box.ZIndex+1})
            Corner(5,Hdr)
            Make("Frame",{Parent=Hdr,Size=UDim2.new(1,0,0.5,0),Position=UDim2.new(0,0,0.5,0),BackgroundColor3=Theme.TabboxHeader,BorderSizePixel=0,ZIndex=Hdr.ZIndex})
            Make("TextLabel",{Parent=Hdr,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=label,TextColor3=Theme.White,TextSize=12,Font=Enum.Font.GothamBold,ZIndex=Hdr.ZIndex+1})

            -- Sub tab bar
            local SubBar=Make("Frame",{Parent=Box,Size=UDim2.new(1,0,0,22),Position=UDim2.new(0,0,0,22),BackgroundColor3=Theme.TabBar,BorderSizePixel=0,ZIndex=Box.ZIndex+1,Visible=false})
            List(SubBar,0,Enum.FillDirection.Horizontal); Pad(0,0,3,3,SubBar)

            local BoxContent=Make("Frame",{Parent=Box,Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,0,22),BackgroundTransparency=1,BorderSizePixel=0,AutomaticSize=Enum.AutomaticSize.Y,ZIndex=Box.ZIndex+1})
            List(BoxContent,2); Pad(3,3,3,3,BoxContent)

            local ActiveSP,ActiveSB=nil,nil
            local SubTabs={}
            local Tabbox={}

            function Tabbox:AddTab(tabName)
                local SubBtn=Make("TextButton",{Parent=SubBar,Size=UDim2.new(0,66,1,0),BackgroundColor3=Theme.TabInactive,Text=tabName,TextColor3=Theme.TextDim,TextSize=11,Font=Enum.Font.GothamSemibold,BorderSizePixel=0,AutoButtonColor=false,ZIndex=SubBar.ZIndex+1})

                local SubPage=Make("Frame",{Parent=BoxContent,Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,BorderSizePixel=0,AutomaticSize=Enum.AutomaticSize.Y,Visible=false,ZIndex=BoxContent.ZIndex+1})
                List(SubPage,2); Pad(1,1,0,0,SubPage)

                local function ActivateSub()
                    if ActiveSP then ActiveSP.Visible=false end
                    if ActiveSB then Tween(ActiveSB,{BackgroundColor3=Theme.TabInactive,TextColor3=Theme.TextDim},0.1) end
                    SubPage.Visible=true
                    Tween(SubBtn,{BackgroundColor3=Theme.Accent,TextColor3=Theme.White},0.1)
                    ActiveSP=SubPage; ActiveSB=SubBtn
                end

                SubBtn.MouseButton1Click:Connect(ActivateSub)

                if #SubTabs==0 then
                    ActivateSub()
                    SubBar.Visible=false
                    BoxContent.Position=UDim2.new(0,0,0,22)
                else
                    SubBar.Visible=true
                    BoxContent.Position=UDim2.new(0,0,0,44)
                end
                table.insert(SubTabs,{Btn=SubBtn,Page=SubPage})

                local S={}

                local function ElBase(h)
                    local e=Make("Frame",{Parent=SubPage,Size=UDim2.new(1,0,0,h or 28),BackgroundColor3=Theme.Element,BorderSizePixel=0,ZIndex=SubPage.ZIndex+1})
                    Corner(4,e); return e
                end
                local function Lbl(p,txt,x,y,w,h,sz,fn,col,ax)
                    return Make("TextLabel",{Parent=p,Position=UDim2.new(0,x or 0,0,y or 0),Size=UDim2.new(0,w or 100,0,h or 20),BackgroundTransparency=1,Text=txt or "",TextColor3=col or Theme.Text,TextSize=sz or 12,Font=fn or Enum.Font.Gotham,TextXAlignment=ax or Enum.TextXAlignment.Left,ZIndex=p.ZIndex+1})
                end

                -- TOGGLE
                function S:AddToggle(id, cfg)
                    cfg=cfg or {}
                    local val=cfg.Default or false
                    local El=ElBase(28); Pad(0,0,8,8,El)
                    Lbl(El,cfg.Text or id,8,0,160,28,12,Enum.Font.Gotham,Theme.Text)

                    local Track=Make("Frame",{Parent=El,Size=UDim2.new(0,34,0,14),Position=UDim2.new(1,-42,0.5,-7),BackgroundColor3=val and Theme.Toggle_ON or Theme.Toggle_OFF,BorderSizePixel=0,ZIndex=El.ZIndex+1})
                    Corner(10,Track)
                    local Knob=Make("Frame",{Parent=Track,Size=UDim2.new(0,10,0,10),Position=val and UDim2.new(1,-12,0.5,-5) or UDim2.new(0,2,0.5,-5),BackgroundColor3=Theme.White,BorderSizePixel=0,ZIndex=Track.ZIndex+1})
                    Corner(10,Knob)

                    local cbs={}
                    local T={}; T.Value=val

                    function T:SetValue(v)
                        val=v; self.Value=v
                        Tween(Track,{BackgroundColor3=v and Theme.Toggle_ON or Theme.Toggle_OFF},0.14)
                        Tween(Knob,{Position=v and UDim2.new(1,-12,0.5,-5) or UDim2.new(0,2,0.5,-5)},0.14)
                        for _,cb in ipairs(cbs) do pcall(cb) end
                    end
                    function T:OnChanged(cb) table.insert(cbs,cb); return self end

                    local Btn=Make("TextButton",{Parent=El,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=El.ZIndex+3})
                    Btn.MouseButton1Click:Connect(function() T:SetValue(not val) end)
                    Btn.MouseEnter:Connect(function() Tween(El,{BackgroundColor3=Theme.ElementHover},0.1) end)
                    Btn.MouseLeave:Connect(function() Tween(El,{BackgroundColor3=Theme.Element},0.1) end)

                    Toggles[id]=T

                    function T:AddKeyPicker(kid, kc)
                        kc=kc or {}
                        local mode=kc.Mode or "Toggle"
                        local sync=kc.SyncToggleState~=false
                        local bk=kc.Default and Enum.KeyCode[kc.Default] or nil
                        local kcbs={}; local binding=false

                        local KLbl=Make("TextButton",{Parent=El,Size=UDim2.new(0,22,0,16),Position=UDim2.new(1,-68,0.5,-8),BackgroundColor3=Theme.AccentDark,Text=bk and bk.Name or "...",TextColor3=Theme.Text,TextSize=9,Font=Enum.Font.GothamSemibold,AutoButtonColor=false,ZIndex=El.ZIndex+4})
                        Corner(3,KLbl)

                        KLbl.MouseButton1Click:Connect(function() binding=true; KLbl.Text="..."; KLbl.BackgroundColor3=Theme.Accent end)
                        UserInputService.InputBegan:Connect(function(i,gp)
                            if gp then return end
                            if binding then
                                if i.UserInputType==Enum.UserInputType.Keyboard then
                                    bk=i.KeyCode; KLbl.Text=i.KeyCode.Name; KLbl.BackgroundColor3=Theme.AccentDark; binding=false
                                end
                            elseif bk and i.KeyCode==bk then
                                if mode=="Toggle" then
                                    if sync then T:SetValue(not T.Value) end
                                    for _,cb in ipairs(kcbs) do pcall(cb) end
                                elseif mode=="Hold" then
                                    for _,cb in ipairs(kcbs) do pcall(cb) end
                                end
                            end
                        end)

                        local KP={}
                        function KP:OnClick(cb) table.insert(kcbs,cb); return self end
                        Options[kid]=KP; return KP
                    end

                    return T
                end

                -- SLIDER
                function S:AddSlider(id, cfg)
                    cfg=cfg or {}
                    local mn=cfg.Min or 0; local mx=cfg.Max or 100
                    local def=cfg.Default or mn; local rnd=cfg.Rounding or 0
                    local suf=cfg.Suffix or ""

                    local El=ElBase(44)
                    Lbl(El,cfg.Text or id,8,4,160,14,11,Enum.Font.Gotham,Theme.Text)
                    local VLbl=Make("TextLabel",{Parent=El,Size=UDim2.new(0,70,0,14),Position=UDim2.new(1,-78,0,4),BackgroundTransparency=1,Text=tostring(def)..suf,TextColor3=Theme.TextDim,TextSize=10,Font=Enum.Font.GothamSemibold,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=El.ZIndex+1})

                    local Track=Make("Frame",{Parent=El,Size=UDim2.new(1,-16,0,5),Position=UDim2.new(0,8,1,-12),BackgroundColor3=Theme.SliderBG,BorderSizePixel=0,ZIndex=El.ZIndex+1})
                    Corner(4,Track)
                    local Fill=Make("Frame",{Parent=Track,Size=UDim2.new((def-mn)/(mx-mn),0,1,0),BackgroundColor3=Theme.SliderFill,BorderSizePixel=0,ZIndex=Track.ZIndex+1})
                    Corner(4,Fill)
                    local SKnob=Make("Frame",{Parent=Track,Size=UDim2.new(0,9,0,9),Position=UDim2.new((def-mn)/(mx-mn),-4,0.5,-4),BackgroundColor3=Theme.White,BorderSizePixel=0,ZIndex=Track.ZIndex+2})
                    Corner(10,SKnob)

                    local val=def; local cbs={}
                    local Sl={}; Sl.Value=val

                    local function Set(v)
                        v=math.clamp(v,mn,mx)
                        if rnd==0 then v=math.floor(v+0.5) else v=math.floor(v*10^rnd+0.5)/10^rnd end
                        val=v; Sl.Value=v
                        local pct=(v-mn)/(mx-mn)
                        Fill.Size=UDim2.new(pct,0,1,0)
                        SKnob.Position=UDim2.new(pct,-4,0.5,-4)
                        VLbl.Text=tostring(v)..suf
                        for _,cb in ipairs(cbs) do pcall(cb,v) end
                    end

                    function Sl:SetValue(v) Set(v) end
                    function Sl:OnChanged(cb) table.insert(cbs,cb); return self end

                    local drag=false
                    local DB=Make("TextButton",{Parent=Track,Size=UDim2.new(1,0,1,8),Position=UDim2.new(0,0,0,-4),BackgroundTransparency=1,Text="",ZIndex=Track.ZIndex+3})
                    DB.MouseButton1Down:Connect(function(x)
                        drag=true
                        Set(mn+math.clamp((x-Track.AbsolutePosition.X)/Track.AbsoluteSize.X,0,1)*(mx-mn))
                    end)
                    UserInputService.InputChanged:Connect(function(i)
                        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
                            Set(mn+math.clamp((i.Position.X-Track.AbsolutePosition.X)/Track.AbsoluteSize.X,0,1)*(mx-mn))
                        end
                    end)
                    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)

                    El.MouseEnter:Connect(function() Tween(El,{BackgroundColor3=Theme.ElementHover},0.1) end)
                    El.MouseLeave:Connect(function() Tween(El,{BackgroundColor3=Theme.Element},0.1) end)

                    Options[id]=Sl; return Sl
                end

                -- DROPDOWN
                function S:AddDropdown(id, cfg)
                    cfg=cfg or {}
                    local vals=cfg.Values or {}
                    local def=cfg.Default
                    local null=cfg.AllowNull or false

                    local El=ElBase(28)
                    Lbl(El,cfg.Text or id,8,0,110,28,11,Enum.Font.Gotham,Theme.Text)

                    local DB=Make("TextButton",{Parent=El,Size=UDim2.new(0,108,0,20),Position=UDim2.new(1,-112,0.5,-10),BackgroundColor3=Theme.InputBG,Text=def or (null and "None" or (vals[1] or "")),TextColor3=Theme.Text,TextSize=11,Font=Enum.Font.GothamSemibold,AutoButtonColor=false,ClipsDescendants=true,ZIndex=El.ZIndex+2})
                    Corner(4,DB); Stroke(Theme.ElementBorder,1,0,DB)
                    Make("TextLabel",{Parent=DB,Size=UDim2.new(0,14,1,0),Position=UDim2.new(1,-16,0,0),BackgroundTransparency=1,Text="▾",TextColor3=Theme.TextDim,TextSize=11,Font=Enum.Font.GothamBold,ZIndex=DB.ZIndex+1})

                    local DL=Make("Frame",{Parent=ScreenGui,Size=UDim2.new(0,108,0,0),BackgroundColor3=Theme.TabboxBG,BorderSizePixel=0,Visible=false,ZIndex=600})
                    Corner(4,DL); Stroke(Theme.Accent,1,0,DL)
                    local DLL=List(DL,1); Pad(2,2,2,2,DL)

                    local value=def; local cbs={}; local open=false
                    local D={}; D.Value=value

                    local function Rebuild()
                        for _,c in ipairs(DL:GetChildren()) do if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end end
                        local items=null and {"None"} or {}
                        for _,v in ipairs(vals) do table.insert(items,v) end
                        for _,item in ipairs(items) do
                            local IB=Make("TextButton",{Parent=DL,Size=UDim2.new(1,0,0,20),BackgroundColor3=item==value and Theme.Accent or Theme.Element,Text=item,TextColor3=Theme.Text,TextSize=11,Font=Enum.Font.Gotham,AutoButtonColor=false,ZIndex=DL.ZIndex+1})
                            Corner(3,IB)
                            IB.MouseButton1Click:Connect(function()
                                value=(item=="None" and null) and nil or item
                                D.Value=value; DB.Text=item
                                open=false; DL.Visible=false
                                for _,cb in ipairs(cbs) do pcall(cb,value) end
                                Rebuild()
                            end)
                            IB.MouseEnter:Connect(function() if item~=value then Tween(IB,{BackgroundColor3=Theme.ElementHover},0.1) end end)
                            IB.MouseLeave:Connect(function() if item~=value then Tween(IB,{BackgroundColor3=Theme.Element},0.1) end end)
                        end
                        DL.Size=UDim2.new(0,108,0,math.min(#items*21+4,130))
                    end
                    Rebuild()

                    DB.MouseButton1Click:Connect(function()
                        open=not open
                        if open then local a=DB.AbsolutePosition; DL.Position=UDim2.new(0,a.X,0,a.Y+22); Rebuild() end
                        DL.Visible=open
                    end)
                    UserInputService.InputBegan:Connect(function(i)
                        if i.UserInputType==Enum.UserInputType.MouseButton1 and open then
                            local mp=UserInputService:GetMouseLocation(); local ap=DL.AbsolutePosition; local as=DL.AbsoluteSize
                            if not(mp.X>=ap.X and mp.X<=ap.X+as.X and mp.Y>=ap.Y and mp.Y<=ap.Y+as.Y) then open=false; DL.Visible=false end
                        end
                    end)

                    function D:SetValue(v) value=v; self.Value=v; DB.Text=v or "None"; Rebuild(); for _,cb in ipairs(cbs) do pcall(cb,v) end end
                    function D:SetValues(v) vals=v; Rebuild() end
                    function D:OnChanged(cb) table.insert(cbs,cb); return self end

                    El.MouseEnter:Connect(function() Tween(El,{BackgroundColor3=Theme.ElementHover},0.1) end)
                    El.MouseLeave:Connect(function() Tween(El,{BackgroundColor3=Theme.Element},0.1) end)

                    Options[id]=D; return D
                end

                -- BUTTON
                function S:AddButton(text, cb)
                    local B=Make("TextButton",{Parent=SubPage,Size=UDim2.new(1,0,0,24),BackgroundColor3=Theme.Accent,Text=text,TextColor3=Theme.White,TextSize=12,Font=Enum.Font.GothamBold,AutoButtonColor=false,BorderSizePixel=0,ZIndex=SubPage.ZIndex+1})
                    Corner(4,B)
                    B.MouseButton1Click:Connect(function()
                        Tween(B,{BackgroundColor3=Theme.AccentDark},0.08)
                        task.delay(0.15,function() Tween(B,{BackgroundColor3=Theme.Accent},0.1) end)
                        pcall(cb)
                    end)
                    B.MouseEnter:Connect(function() Tween(B,{BackgroundColor3=Theme.AccentHover},0.1) end)
                    B.MouseLeave:Connect(function() Tween(B,{BackgroundColor3=Theme.Accent},0.1) end)
                    return B
                end

                -- INPUT
                function S:AddInput(id, cfg)
                    cfg=cfg or {}
                    local El=ElBase(44)
                    Lbl(El,cfg.Text or id,8,4,200,14,11,Enum.Font.Gotham,Theme.TextDim)
                    local Box=Make("TextBox",{Parent=El,Size=UDim2.new(1,-16,0,20),Position=UDim2.new(0,8,1,-24),BackgroundColor3=Theme.InputBG,Text=cfg.Default or "",PlaceholderText=cfg.Placeholder or "",PlaceholderColor3=Theme.TextDisabled,TextColor3=Theme.Text,TextSize=11,Font=Enum.Font.Gotham,ClearTextOnFocus=false,BorderSizePixel=0,ZIndex=El.ZIndex+2})
                    Corner(4,Box)
                    local BS=Stroke(Theme.Accent,1,0.5,Box)
                    Pad(0,0,4,4,Box)
                    Box.Focused:Connect(function() Tween(BS,{Transparency=0},0.1) end)
                    Box.FocusLost:Connect(function() Tween(BS,{Transparency=0.5},0.1) end)

                    local val=cfg.Default or ""; local cbs={}
                    local I={}; I.Value=val
                    Box:GetPropertyChangedSignal("Text"):Connect(function() val=Box.Text; I.Value=val; for _,cb in ipairs(cbs) do pcall(cb) end end)
                    function I:SetValue(v) Box.Text=v; val=v; self.Value=v end
                    function I:OnChanged(cb) table.insert(cbs,cb); return self end

                    El.MouseEnter:Connect(function() Tween(El,{BackgroundColor3=Theme.ElementHover},0.1) end)
                    El.MouseLeave:Connect(function() Tween(El,{BackgroundColor3=Theme.Element},0.1) end)

                    Options[id]=I; return I
                end

                -- COLOR PICKER
                function S:AddColorPicker(id, cfg)
                    cfg=cfg or {}
                    local def=cfg.Default or Color3.fromRGB(255,255,255)
                    local El=ElBase(28)
                    Lbl(El,cfg.Text or id,8,0,140,28,11,Enum.Font.Gotham,Theme.Text)

                    local Sw=Make("TextButton",{Parent=El,Size=UDim2.new(0,18,0,14),Position=UDim2.new(1,-26,0.5,-7),BackgroundColor3=def,Text="",AutoButtonColor=false,BorderSizePixel=0,ZIndex=El.ZIndex+2})
                    Corner(3,Sw); Stroke(Theme.ElementBorder,1,0,Sw)

                    local Popup=Make("Frame",{Parent=ScreenGui,Size=UDim2.new(0,174,0,152),BackgroundColor3=Theme.TabboxBG,BorderSizePixel=0,Visible=false,ZIndex=600})
                    Corner(6,Popup); Stroke(Theme.Accent,1,0,Popup); Pad(6,6,6,6,Popup)

                    local SVBox=Make("Frame",{Parent=Popup,Size=UDim2.new(1,-20,0,118),Position=UDim2.new(0,0,0,0),BackgroundColor3=Color3.fromHSV(0,1,1),BorderSizePixel=0,ZIndex=Popup.ZIndex+1,ClipsDescendants=true})
                    Corner(4,SVBox)
                    -- White gradient left-right
                    local SG=Instance.new("UIGradient"); SG.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,Color3.new(1,1,1))}); SG.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}); SG.Parent=SVBox
                    -- Black gradient top-bottom overlay
                    local BFrame=Make("Frame",{Parent=SVBox,Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,ZIndex=SVBox.ZIndex+1})
                    local BG=Instance.new("UIGradient"); BG.Color=ColorSequence.new(Color3.new(0,0,0)); BG.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)}); BG.Rotation=90; BG.Parent=BFrame

                    local SVK=Make("Frame",{Parent=SVBox,Size=UDim2.new(0,8,0,8),BackgroundColor3=Theme.White,BorderSizePixel=0,ZIndex=SVBox.ZIndex+3})
                    Corner(10,SVK); Stroke(Theme.Shadow,1,0,SVK)

                    local HBar=Make("Frame",{Parent=Popup,Size=UDim2.new(0,12,0,118),Position=UDim2.new(1,-12,0,0),BorderSizePixel=0,ZIndex=Popup.ZIndex+1})
                    Corner(4,HBar)
                    local HG=Instance.new("UIGradient")
                    HG.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromHSV(0,1,1)),ColorSequenceKeypoint.new(0.17,Color3.fromHSV(0.17,1,1)),ColorSequenceKeypoint.new(0.33,Color3.fromHSV(0.33,1,1)),ColorSequenceKeypoint.new(0.5,Color3.fromHSV(0.5,1,1)),ColorSequenceKeypoint.new(0.67,Color3.fromHSV(0.67,1,1)),ColorSequenceKeypoint.new(0.83,Color3.fromHSV(0.83,1,1)),ColorSequenceKeypoint.new(1,Color3.fromHSV(1,1,1))})
                    HG.Rotation=90; HG.Parent=HBar
                    local HK=Make("Frame",{Parent=HBar,Size=UDim2.new(1,0,0,3),BackgroundColor3=Theme.White,BorderSizePixel=0,ZIndex=HBar.ZIndex+2})
                    Stroke(Theme.Shadow,1,0,HK)

                    local h,s,v2=Color3.toHSV(def)
                    local value=def; local cbs={}
                    local CO={}; CO.Value=value

                    local function Apply()
                        value=Color3.fromHSV(h,s,v2); CO.Value=value; Sw.BackgroundColor3=value
                        SVBox.BackgroundColor3=Color3.fromHSV(h,1,1)
                        SVK.Position=UDim2.new(s,-4,1-v2,-4)
                        HK.Position=UDim2.new(0,0,h,-1)
                        for _,cb in ipairs(cbs) do pcall(cb,value) end
                    end
                    Apply()

                    local svd=false
                    local SVBtn=Make("TextButton",{Parent=SVBox,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=SVBox.ZIndex+4})
                    SVBtn.MouseButton1Down:Connect(function(x,y) svd=true; s=math.clamp((x-SVBox.AbsolutePosition.X)/SVBox.AbsoluteSize.X,0,1); v2=math.clamp(1-(y-SVBox.AbsolutePosition.Y)/SVBox.AbsoluteSize.Y,0,1); Apply() end)
                    UserInputService.InputChanged:Connect(function(i) if svd and i.UserInputType==Enum.UserInputType.MouseMovement then s=math.clamp((i.Position.X-SVBox.AbsolutePosition.X)/SVBox.AbsoluteSize.X,0,1); v2=math.clamp(1-(i.Position.Y-SVBox.AbsolutePosition.Y)/SVBox.AbsoluteSize.Y,0,1); Apply() end end)
                    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then svd=false end end)

                    local hd=false
                    local HBtn=Make("TextButton",{Parent=HBar,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=HBar.ZIndex+3})
                    HBtn.MouseButton1Down:Connect(function(x,y) hd=true; h=math.clamp((y-HBar.AbsolutePosition.Y)/HBar.AbsoluteSize.Y,0,1); Apply() end)
                    UserInputService.InputChanged:Connect(function(i) if hd and i.UserInputType==Enum.UserInputType.MouseMovement then h=math.clamp((i.Position.Y-HBar.AbsolutePosition.Y)/HBar.AbsoluteSize.Y,0,1); Apply() end end)
                    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then hd=false end end)

                    local popOpen=false
                    Sw.MouseButton1Click:Connect(function()
                        popOpen=not popOpen
                        if popOpen then local a=Sw.AbsolutePosition; Popup.Position=UDim2.new(0,a.X-80,0,a.Y+20) end
                        Popup.Visible=popOpen
                    end)
                    UserInputService.InputBegan:Connect(function(i)
                        if i.UserInputType==Enum.UserInputType.MouseButton1 and popOpen then
                            local mp=UserInputService:GetMouseLocation(); local ap=Popup.AbsolutePosition; local as=Popup.AbsoluteSize
                            if not(mp.X>=ap.X and mp.X<=ap.X+as.X and mp.Y>=ap.Y and mp.Y<=ap.Y+as.Y) then popOpen=false; Popup.Visible=false end
                        end
                    end)

                    function CO:SetValue(v) value=v; self.Value=v; h,s,v2=Color3.toHSV(v); Apply() end
                    function CO:OnChanged(cb) table.insert(cbs,cb); return self end

                    El.MouseEnter:Connect(function() Tween(El,{BackgroundColor3=Theme.ElementHover},0.1) end)
                    El.MouseLeave:Connect(function() Tween(El,{BackgroundColor3=Theme.Element},0.1) end)

                    Options[id]=CO; return CO
                end

                return S
            end

            return Tabbox
        end

        function Tab:AddLeftTabbox(label)  return MakeTabbox(LeftCol,  label) end
        function Tab:AddRightTabbox(label) return MakeTabbox(RightCol, label) end

        return Tab
    end

    function Window:Destroy() ScreenGui:Destroy() end

    return Window
end

function Library:Notify(cfg)
    cfg=cfg or {}
    local NF=Make("Frame",{Parent=ScreenGui,Size=UDim2.new(0,220,0,52),Position=UDim2.new(1,-230,1,-70),BackgroundColor3=Theme.TabboxBG,BorderSizePixel=0,ZIndex=999})
    Corner(5,NF); Stroke(Theme.Accent,1,0,NF)
    Make("TextLabel",{Parent=NF,Size=UDim2.new(1,-8,0,18),Position=UDim2.new(0,8,0,4),BackgroundTransparency=1,Text=cfg.Title or "",TextColor3=Theme.Accent,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=NF.ZIndex+1})
    Make("TextLabel",{Parent=NF,Size=UDim2.new(1,-8,0,24),Position=UDim2.new(0,8,0,22),BackgroundTransparency=1,Text=cfg.Content or "",TextColor3=Theme.Text,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,ZIndex=NF.ZIndex+1})
    task.delay(cfg.Duration or 3,function()
        Tween(NF,{Position=UDim2.new(1,-230,1,-40),BackgroundTransparency=1},0.3)
        game:GetService("Debris"):AddItem(NF,0.4)
    end)
end

function Library:Destroy() ScreenGui:Destroy() end

return Library
