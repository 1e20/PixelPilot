local Vector2, Draw, Color3New = Vector2.new, Drawing.new, Color3.fromRGB;
local Floor, Ceil, Clamp = math.floor, math.ceil, math.clamp; 
local Insert, Remove, ClearTable, FindInTable = table.insert, table.remove, table.clear, table.find;

if (setfpscap) then setfpscap(math.huge); end;

local function Lerp(a, b, t) 
    return a + (b - a) * t; 
end;

local function Switch(Cases)
    return function(Value)
        local Func = Cases[Value];
        if (not Func) then return Cases.Default(); end;
        return Func();
    end;
end;

local TweenService = game:GetService("TweenService");
local InputService = game:GetService("UserInputService");
local RunService = game:GetService("RunService");

local PixelPilot = {
    SelectorSquare = Draw("Square");    
    DeltaPosition = Vector2(0, 0);
    RenderBin = nil;
    MouseDelta = 0;
    Mouse1Cooking = false;
    Mouse2Cooking = false;
    Mouse1Down = false; 
    Mouse2Down = false; 
    Mouse1Up = false; 
    Mouse1Down = false;
    PaintFireFps = 60;
    __ImmediateMemory = { Square = { }; Line = { }; Text = { }; Quad = { }; Triangle = { } };
    __ImmediateCache = { };
    __ZIndexPile = { };
    __ZIndex = 1;
    __MouseDeltaPoint = 0;
};

PixelPilot.TriCubeVerticies = {
    {{-1, 1, 1}, {-1, -1, 1}, {1, 1, 1}};
    {{1, 1, 1}, {1, -1, 1}, {-1, -1, 1}};
    {{1, -1, -1}, {-1, -1, -1}, {-1, 1, -1}};
    {{1, -1, -1}, {-1, 1, -1}, {1, 1, -1}};
    {{-1, -1, 1}, {-1, -1, -1}, {-1, 1, -1}};
    {{-1, -1, 1}, {-1, 1, -1}, {-1, 1, 1}};
    {{1, -1, 1}, {1, -1, -1}, {1, 1, -1}};
    {{1, -1, 1}, {1, 1, -1}, {1, 1, 1}};
    {{1, 1, 1}, {-1, 1, 1}, {-1, 1, -1}};
    {{1, 1, 1}, {-1, 1, -1}, {1, 1, -1}};
    {{1, -1, 1}, {-1, -1, 1}, {-1, -1, -1}};
    {{1, -1, 1}, {-1, -1, -1}, {1, -1, -1}};
};

PixelPilot.QuadCubeVerticies = {
    {{-1, 1, 1}, {-1, -1, 1}, {1, -1, 1}, {1, 1, 1}};
    {{1, -1, -1}, {-1, -1, -1}, {-1, 1, -1}, {1, 1, -1}};
    {{-1, -1, 1}, {-1, -1, -1}, {-1, 1, -1}, {-1, 1, 1}};
    {{1, -1, 1}, {1, -1, -1}, {1, 1, -1}, {1, 1, 1}};
    {{1, 1, 1}, {-1, 1, 1}, {-1, 1, -1}, {1, 1, -1}};
    {{1, -1, 1}, {-1, -1, 1}, {-1, -1, -1}, {1, -1, -1}};
};


local ClearScreen = function()
    for i, v in pairs(PixelPilot.__ImmediateMemory) do 
        for x, render in pairs(v) do 
            render.Render:Remove();
            ClearTable(render);
            v[x] = nil;
        end; 
    end; 

    for i, v in pairs(PixelPilot.__ImmediateCache) do 
        v.Visible = false;
        PixelPilot.__ImmediateMemory[v.Class][i] = v; 
        PixelPilot.__ImmediateCache[i] = nil; 
    end; 
end;

local GetStackLine = function()
    return debug.getinfo(2, "Sl").currentline;
end; 

---@ Used to avoid visual blur 
---@param x 
---@param y 
function PixelPilot.Vector2(X, Y, R)
    return Vector2(Floor(X), Floor(Y));
end; 

---@ Signal
---@ Signal:Listen(function)
---@ Listener:Close()
---@ Signal:Close()
local Signal = { };
Signal.__index = Signal; 

function Signal:Listen(Callback)
    local Listener = { 
        Type = "Listener";
        Callback = Callback;  
        IdIndex = 0;
    };
    
    function Listener:Close()
        ClearTable(Listener);
        Listener = nil;
    
    end; 

    Insert(self.OpenConnections, Listener);
    IdIndex = #self.OpenConnections;

    self.Active = true;
    return Listener;
end;

function Signal:WaitAsync()
    local Waiter = { Type = "Listener" };

    function Waiter.Then(Callback)
        Waiter.ThenCallback = Callback;
    end; 

    Insert(self.Waiters, Waiter);
    return Waiter;
end;

function Signal:Fire(...)
    for i, listener in pairs(self.OpenConnections) do 
        listener.Callback(...);
    end; 

    for i, waiter in pairs(self.Waiters) do 
        waiter.ThenCallback(...);
        ClearTable(waiter);
    end;

    ClearTable(self.Waiters);
end; 

function Signal:Close()
    for i, listener in pairs(self.OpenConnections) do 
        listener:Close();
    end; 

    ClearTable(self);
end; 

---@ Bin for quick cleanup
---@ Bin:Add(Object)
---@ Bin:Clear()
local Bin = { }; 
Bin.__index = Bin; 

function Bin:Add(Object)
    Insert(self.Collection, Object);
    return Object;
end; 

function Bin:Remove(Object)
    local Index = FindInTable(self.Collection, Object);
    if (not Index) then return; end;
    Remove(self.Collection, Index); 
end;

function Bin:Clear()
    for i, g in pairs(self:GetCollection()) do 
        local Type = typeof(g);
        local IsTable = (Type == "table");

        if (IsTable and g.Remove) then 
            g:Remove();
            continue;
        elseif (IsTable and g.Type) then 
            Type = g.Type;
        end;

        Switch({
            Default = function() 
                ClearTable(g);
            end; 
            
            RBXScriptConnection = function()
                g:Disconnect();
            end;

            Instance = function()
                g:Destroy();
            end;

            Signal = function()
                g:Close();
            end; 

            Bin = function()
                g:Clear();
            end;
        })(Type);
    end; 
end; 

function Bin:Destroy()
    self:Clear();
    ClearTable(self);
end;

function Bin:GetCollection()
    return self.Collection;
end;

--@ Tween Class 
--@ Tween:Play()
--@ Tween:Pause()
local Tween = { };
Tween.__index = Tween;

function Tween:Pause()
    self.Paused = true;
    self.PlaybackState = Enum.PlaybackState.Paused;
end; 

function Tween:Resume()
    self.Paused = false; 
    self.PlaybackState = Enum.PlaybackState.Playing;
end; 

function Tween:Cancel() 
    self.Cancelled = true;
    self.PlaybackState = Enum.PlaybackState.Cancelled;
end; 

function Tween:Play()
    self.PlaybackState = Enum.PlaybackState.Playing;

    self.Stepped = RunService.Stepped:Connect(function(_, DeltaTime)
        if (self.Cancelled) then 
            self.Stepped:Disconnect();
            return; 
        elseif (self.Paused) then 
            return;
        end; 

        self.Elapsed = (self.Elapsed + DeltaTime); 

        local Alpha = TweenService:GetValue(self.Elapsed / self.Info.Time, self.Info.EasingStyle, self.Info.EasingDirection);
        
        for p, g in next, self.Goals do 
            if (typeof(g) == "Color3") then 
                local R, G, B = Lerp(self.Original[p].R, g.R, Alpha), Lerp(self.Original[p].G, g.G, Alpha), Lerp(self.Original[p].B, g.B, Alpha);
                self.Object:SetProperty(p, Color3New(R, G, B));
            elseif (typeof(g) == "Vector2") then 
                local X, Y = Lerp(self.Original[p].X, g.X, Alpha), Lerp(self.Original[p].Y, g.Y, Alpha);
                self.Object:SetProperty(p, Vector2(X, Y));
            else 
                self.Object:SetProperty(p, Lerp(self.Original[p], g, Alpha));
            end; 
        end;

        if (self.Elapsed >= self.Info.Time) then 
            self.Stepped:Disconnect();
            self.Completed:Fire();
            self.PlaybackState = Enum.PlaybackState.Completed;
        end; 
    end);
end; 

function PixelPilot.Signal()
    local NewSignal = { 
        Type = "Signal";
        Active = false;
        Waiters = { };
        OpenConnections = { };
    };

    setmetatable(NewSignal, Signal);
    return NewSignal;
end; 

function PixelPilot.Bin()
    local NewBin = { 
        Type = "Bin";
        Collection = { };
    };

    setmetatable(NewBin, Bin)
    return NewBin; 
end; 

function PixelPilot.Tween(Object, TweenInfo, Goals)
    local NewTween = { 
        Type = "Tween";
        PlaybackState = Enum.PlaybackState.Begin;
        Completed = PixelPilot.Signal();
        Object = Object;
        Info = TweenInfo;
        Goals = Goals;
        Original = { };
        Elapsed = 0;
        Stepped = nil;
        Paused = false;
        Cancelled = false;
    };

    for p, v in next, NewTween.Goals do 
        NewTween.Original[p] = Object[p];
    end; 
    
    setmetatable(NewTween, Tween);
    return NewTween;
end; 

function PixelPilot.GetMouseLocation()
    return InputService:GetMouseLocation();
end; 

function PixelPilot.IsMouseOnObject(Object)
    local Mouse = InputService:GetMouseLocation(); 
    local Size = (Object.TextBounds or Object.Size);

    local X = (Mouse.X >= Object.Position.X and Mouse.X <= Object.Position.X + Size.X); 
    local Y = (Mouse.Y >= Object.Position.Y and Mouse.Y <= Object.Position.Y + Size.Y);

    return (X and Y);
end;

function PixelPilot.IsMouseOnHigherZIndexThan(Object)
    for i, render in pairs(PixelPilot.RenderBin.Collection) do 
        if (render.Visible and render.Filled and render.Transparency > 0 and render.ZIndex > render.ZIndex and PixelPilot.IsMouseOnObject(render)) then 
            return true;
        end; 
    end; 
end;

--@ PixelPilot.New
local Gui = { };

function Gui:SetProperty(index, value)
    self.Properties[index] = value;
    
    Switch({
        Default = function()
            self.Render[index] = value;
        end;

        Parent = function()
            Render.Properties.Parent = value; 
            
            if (value) then 
                Insert(value.Properties.Children, self); 
            elseif (value and self.Properties.Parent) then
                table.remove(self.Properties.Parent.Properties.Children, FindInTable(self.Properties.Parent.Properties.Children, self));
                Insert(value.Properties.Children, self);
            else 
                table.remove(self.Properties.Parent.Properties.Children, FindInTable(self.Properties.Parent.Properties.Children, self));
            end; 
        end;

        RelativePosition = function()
            self:UpdateChildren(index, value);

        end;
    })(index);
end;

function Gui:GetChildren()
    return self.Properties.Children;
end;

function Gui:Remove()
    PixelPilot.RenderBin:Remove(self);
    self.ObjectBin:Destroy();
    self.Render:Remove();
    ClearTable(self);
end;

function PixelPilot.New(Class, Properties)
    local ObjectBin = PixelPilot.Bin();

    local Render, RenderMT = { 
        Type = "Render";
        TypeOf = Class; 
        Render = Draw(Class);
        ObjectBin = ObjectBin;
        Properties = { 
            RelativePosition = Vector2(0, 0);
            Children = { };
            Parent = nil;
        };
        HiddenProperties = { };
        Mouse1Click = ObjectBin:Add(PixelPilot.Signal());
        Mouse1Down = ObjectBin:Add(PixelPilot.Signal());
        Mouse1Up = ObjectBin:Add(PixelPilot.Signal());    
        MouseEnter = ObjectBin:Add(PixelPilot.Signal());
        MouseLeave = ObjectBin:Add(PixelPilot.Signal());
        ChildAdded = ObjectBin:Add(PixelPilot.Signal());
        Changed = ObjectBin:Add(PixelPilot.Signal());
    }, { };

    RenderMT.__index = function(self, index)
        return (Gui[index] or self.Properties[index] or self.Render[index]);
    end; 

    RenderMT.__newindex = function(self, index, value)
        self:SetProperty(index, value);
        self.Changed:Fire(index, value);
    end;
    
    setmetatable(Render, RenderMT);

    function Render:UpdateChildren(index, value)
        for i, render in pairs(self:GetChildren()) do 

        end;
    end; 

    -- Property Set 
    for property, value in pairs(Properties or { }) do
        Render:SetProperty(property, value);
    end; 

    PixelPilot.RenderBin:Add(Render);
    return Render; 
end; 

PixelPilot.RenderBin = PixelPilot.Bin();
PixelPilot.OnPaint = PixelPilot.Signal();

PixelPilot.ImmediateDraw = function(Class, Properties)
    if (Properties.Visible == false) then return; end; 

    local Memory = PixelPilot.__ImmediateMemory[Class];
    local Drawing = Memory[#Memory] or { Render = Draw(Class); Class = Class; };
    table.remove(Memory, #Memory);
    Drawing.Render.Visible = true; 

    for p, v in Properties do 
        Drawing.Render[p] = v; 
    end;    

    Insert(PixelPilot.__ImmediateCache, Drawing);

    return Drawing;
end;

PixelPilot.ImmediateDrawPolygon = function(Poly, Properties, Bounds)
    for i = 1, #Poly do 
        local To = (Poly[i + 1] or Poly[1]); 
        local From = Poly[i];
        Properties.From = PixelPilot.Vector2(Clamp(From.x, Bounds.Min.x, Bounds.Max.x), Clamp(From.y, Bounds.Min.y, Bounds.Max.y));
        Properties.To = PixelPilot.Vector2(Clamp(To.x, Bounds.Min.x, Bounds.Max.x), Clamp(To.y, Bounds.Min.y, Bounds.Max.y));
        PixelPilot.ImmediateDraw("Line", Properties);
    end; 
end;

coroutine.resume(coroutine.create(function()
    while (true) do 
        ClearScreen();
        PixelPilot.OnPaint:Fire();
        task.wait(1/PixelPilot.PaintFireFps);
    end;
end));

InputService.InputBegan:Connect(function(Input)
    if (Input.UserInputType == Enum.UserInputType.MouseButton1) then 
        for i, render in pairs(PixelPilot.RenderBin.Collection) do 
            if (PixelPilot.IsMouseOnObject(render) and not PixelPilot.IsMouseOnHigherZIndexThan(render)) then
                render.Mouse1Down:Fire();
            end;
        end; 

        PixelPilot.Mouse1Down = true;
        PixelPilot.Mouse1Cooking = true;
    end;

    if (Input.UserInputType == Enum.UserInputType.MouseButton2) then 
        for i, render in pairs(PixelPilot.RenderBin.Collection) do 
            if (PixelPilot.IsMouseOnObject(render) and not PixelPilot.IsMouseOnHigherZIndexThan(render)) then
                render.Mouse1Down:Fire();
            end;
        end; 

        PixelPilot.Mouse1Down = true;
        PixelPilot.Mouse1Cooking = true;
    end;
end);

InputService.InputEnded:Connect(function(Input)
    if (Input.UserInputType == Enum.UserInputType.MouseButton1) then 
        if (PixelPilot.Mouse1Cooking) then 
            for i, render in pairs(PixelPilot.RenderBin.Collection) do 
                if (PixelPilot.IsMouseOnObject(render) and not PixelPilot.IsMouseOnHigherZIndexThan(render)) then
                    render.Mouse1Click:Fire();
                    render.Mouse1Up:Fire();
                end;
            end; 

            PixelPilot.Mouse1Cooking = false;
        end;
    end;

    if (Input.UserInputType == Enum.UserInputType.MouseButton2) then 
        if (PixelPilot.Mouse2Cooking) then 
            for i, render in pairs(PixelPilot.RenderBin.Collection) do 
                if (PixelPilot.IsMouseOnObject(render) and not PixelPilot.IsMouseOnHigherZIndexThan(render)) then
                    render.Mouse2Click:Fire();
                    render.Mouse2Up:Fire();
                end;
            end; 

            PixelPilot.Mouse2Cooking = false;
        end;
    end;
end);

InputService.InputChanged:Connect(function(Input)
    if (Enum.UserInputType.MouseMovement == Input.UserInputType) then
    end; 
end);

return PixelPilot;
