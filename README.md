Not finished with alot of stuff just putting here to write documentation as I go.


# **Immediate Drawing.**
This is an implementation of a draw and refresh system.
### How to use
Make a listener on the OnPaint event.
```lua
PixelPilot.OnPaint:Connect(function()
    -- Code 
end);
```

### Drawing 
Example 3D Box use
Drawing is used with either  ```PixelPilot.ImmediateDraw<Class, Properties>``` or ```PixelPilot.ImmediateDrawVerticies<Verticies, Properties>```
```lua 
PixelPilot.OnPaint:Listen(function()
    for _, k in next, game.Players:GetPlayers() do 
        if (not k.Character) then continue; end; 

        local Faces = { };
        local Vertex, Size = k.Character:GetBoundingBox();
        local XMax, YMax, XMin, YMin = 0, 0, Camera.ViewportSize.X, Camera.ViewportSize.Y;
        local Visible = true; 
        
        --@ Calculate Points
        for i = 1, #PixelPilot.QuadCubeVerticies do 
            local Face = { };

            for v = 1, 4 do 
                local N = PixelPilot.QuadCubeVerticies[i][v];
                local P, V = Camera:WorldToViewportPoint((Vertex * CFrame.new((Size.X / 2 * N[1]), (Size.Y / 2 * N[2]), (Size.Z / 2 * N[3]))).Position);
                local X, Y = P.X, P.Y;

                if X > XMax then XMax = X end;
                if X < XMin then XMin = X end;
                if Y > YMax then YMax = Y end;
                if Y < YMin then YMin = Y end;

                Visible = V;
                Insert(Face, PixelPilot.Vector2(X, Y));
            end; 

            Insert(Faces, Face);
        end;  

        --@ 3D Bounding Box 
        for i, Face in pairs(Faces) do 
            PixelPilot.ImmediateDraw("Quad", {
                PointA = Face[1];
                PointB = Face[2];
                PointC = Face[3];
                PointD = Face[4];
                Color = Color3.fromRGB(0, 0, 255);
                Visible = Visible;
            });
        end; 
    end; 
end);
```
