# Skill: 3D Model Rendering in 2D UI via ViewportFrame

This skill explains how to display 3D models (such as Pets or Eggs) inside a 2D UI frame (e.g. inventory slots or gacha reveals) using a `ViewportFrame` and a client-side virtual camera.

## 1. Flow
1. Instantiate or get a `ViewportFrame` inside your UI.
2. Clone the 3D model (e.g. the pet model) and parent it to the ViewportFrame.
3. Create a new `Camera` object, parent it to the ViewportFrame, and assign it to the `ViewportFrame.CurrentCamera` property.
4. Position the Camera so it frames the model nicely.
5. (Optional) Run a `RenderStepped` loop on the Client to rotate the model for a dynamic, premium look.

## 2. Client Implementation Example
```lua
local RunService = game:GetService("RunService")

local function renderPetInViewport(viewportFrame, petModelPrefab)
    -- Clear previous items
    viewportFrame:ClearAllChildren()
    
    -- 1. Clone & parent model
    local model = petModelPrefab:Clone()
    model.Parent = viewportFrame
    
    -- 2. Setup Camera
    local camera = Instance.new("Camera")
    camera.FieldOfView = 40
    camera.Parent = viewportFrame
    viewportFrame.CurrentCamera = camera
    
    -- 3. Position Camera based on bounding box
    local modelCFrame, modelSize = model:GetBoundingBox()
    local extents = modelSize.Magnitude
    
    -- Calculate distance to fit model inside view
    local distance = extents * 1.1 
    local cameraCFrame = CFrame.new(
        modelCFrame.Position + Vector3.new(0, extents * 0.2, distance),
        modelCFrame.Position
    )
    camera.CFrame = cameraCFrame
    
    -- 4. Optional: Spin the model inside UI slot
    local connection
    connection = RunService.RenderStepped:Connect(function(dt)
        if not viewportFrame or not viewportFrame.Parent then
            connection:Disconnect() -- Clean up connection when UI is destroyed
            return
        end
        -- Rotate pet slightly on Y axis every frame
        model:SetPrimaryPartCFrame(modelCFrame * CFrame.Angles(0, tick() % (math.pi * 2), 0))
    end)
    
    return model
end
```
