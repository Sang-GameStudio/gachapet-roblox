# Skill: Weighted Random Gacha & Server Debounce

This skill documents how to create an exploit-proof gacha system using weights, including the math behind random rolls and proper cooldown checks.

## 1. Weighted Random Selection
Instead of matching simple percentages directly, sum the total weight and choose a random integer within that range. Then iterate through the pool to find where the integer falls.

### Weight Config:
- **Common**: 80% (Weight = 80)
- **Rare**: 15% (Weight = 15)
- **Legendary**: 5% (Weight = 5)
- **Total**: 100

## 2. Server Implementation Example
```lua
local GachaModule = {}

local PET_POOL = {
    { Name = "Common_Dog",       Rarity = "Common",    Weight = 80 },
    { Name = "Rare_Cat",         Rarity = "Rare",      Weight = 15 },
    { Name = "Legendary_Dragon", Rarity = "Legendary", Weight = 5  }
}

-- Calculate overall weights once
local totalWeight = 0
for _, item in ipairs(PET_POOL) do
    totalWeight = totalWeight + item.Weight
end

function GachaModule.RollPet()
    local rolledValue = math.random(1, totalWeight)
    local currentSum = 0
    
    for _, item in ipairs(PET_POOL) do
        currentSum = currentSum + item.Weight
        if rolledValue <= currentSum then
            return item -- Returns the full item table {Name, Rarity, Weight}
        end
    end
end

return GachaModule
```

## 3. Exploit Prevention (Server Debounce Verification)
```lua
local lastActionTime = {}
local COOLDOWN = 0.8 -- Cooldown time between rolls

local function buyEgg(player)
    local userId = player.UserId
    local currentTime = tick()
    
    -- Check rate limiting
    if currentTime - (lastActionTime[userId] or 0) < COOLDOWN then
        warn("Spam detected from player: " .. player.Name)
        return false
    end
    lastActionTime[userId] = currentTime

    -- Proceed with coins deduction & RollPet logic
    return true
end
```
