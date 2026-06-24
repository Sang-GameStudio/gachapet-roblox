# Skill: Safe DataStore Management & Session Caching

This skill documents how to handle persistent data (inventory, coins) safely in Roblox, implementing session caching and robust saving mechanisms to prevent data loss.

## 1. Core Logic Design
1. **RAM Cache**: When a player joins, load their data from `DataStore` once and save it in a server-side script dictionary (`sessionData`). All subsequent modifications (purchasing eggs, equipping pets) update this RAM cache.
2. **`pcall` wrap**: Always execute DataStore operations in a `pcall` since web requests can fail.
3. **`BindToClose` loop**: Run a shutdown routine that forces saves for all players currently online when the game server shuts down or testing stops.

## 2. Server Implementation Example
```lua
local DataStoreService = game:GetService("DataStoreService")
local PlayerDataStore = DataStoreService:GetDataStore("GameData_v1")
local Players = game:GetService("Players")

local sessionData = {} -- [userId] = { Coins = 100, Inventory = {"Common_Dog"} }

local function loadData(player)
    local userId = player.UserId
    local playerKey = "Player_" .. userId
    
    local success, savedData = pcall(function()
        return PlayerDataStore:GetAsync(playerKey)
    end)
    
    if success and savedData then
        sessionData[userId] = savedData
    else
        -- Default data for new player
        sessionData[userId] = {
            Coins = 100,
            Inventory = {"Common_Dog"}
        }
    end
end

local function saveData(player)
    local userId = player.UserId
    if not sessionData[userId] then return end
    
    local playerKey = "Player_" .. userId
    local success, err = pcall(function()
        PlayerDataStore:SetAsync(playerKey, sessionData[userId])
    end)
    
    if not success then
        warn("Failed to save data for user " .. player.Name .. ": " .. tostring(err))
    end
end

-- Players events
Players.PlayerAdded:Connect(loadData)
Players.PlayerRemoving:Connect(function(player)
    saveData(player)
    sessionData[player.UserId] = nil -- Free memory
end)

-- CRITICAL: Save all online players when server is shutting down
game:BindToClose(function()
    print("Server closing! Saving all active players...")
    for _, player in ipairs(Players:GetPlayers()) do
        saveData(player)
    end
end)
```
