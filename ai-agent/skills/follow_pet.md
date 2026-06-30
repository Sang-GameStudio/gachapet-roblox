# Skill: Pet Following Mechanics via Physics Constraints

This skill details how to make a pet model follow behind a player smoothly using Roblox's physics engine (modern constraint objects).

## 1. Principles
- **AlignPosition**: Moves the pet's primary part to match a target position (behind the player character).
- **AlignOrientation**: Rotates the pet's primary part to match the character's orientation.
- **SetNetworkOwner**: Delegating physics computation of the pet model to the player's client eliminates replication latency.
- **CanCollide = false**: Prevents pets from colliding with characters or terrain and causing physics issues.

## 2. Server Implementation Example
```lua
local function equipPetPhysics(player, character, petModel)
    local rootPart = character:WaitForChild("HumanoidRootPart")
    local petRoot = petModel.PrimaryPart or petModel:FindFirstChildWhichIsA("BasePart")
    
    if not petRoot then
        warn("Pet model must have a PrimaryPart configured!")
        return
    end
    
    -- 1. Create attachments
    local attachmentPet = Instance.new("Attachment")
    attachmentPet.Parent = petRoot
    
    local attachmentPlayer = Instance.new("Attachment")
    -- Position: 2 studs right, 1 stud up, 3 studs behind player
    attachmentPlayer.Position = Vector3.new(2, 1, 3) 
    attachmentPlayer.Parent = rootPart
    
    -- 2. Configure AlignPosition
    local alignPos = Instance.new("AlignPosition")
    alignPos.Attachment0 = attachmentPet
    alignPos.Attachment1 = attachmentPlayer
    alignPos.MaxForce = 20000
    alignPos.Responsiveness = 15 -- Adjust responsiveness for latency delay game-feel
    alignPos.Parent = petRoot
    
    -- 3. Configure AlignOrientation
    local alignOrient = Instance.new("AlignOrientation")
    alignOrient.Attachment0 = attachmentPet
    alignOrient.Attachment1 = attachmentPlayer
    alignOrient.MaxTorque = 20000
    alignOrient.Responsiveness = 15
    alignOrient.Parent = petRoot
    
    -- 4. Set Collisions and Network Ownership
    for _, part in ipairs(petModel:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            -- Make sure the client can't push it out of bounds
            part.Anchored = false 
        end
    end
    
    -- Sync physics calculations to the player's device
    petRoot:SetNetworkOwner(player)
end
```
