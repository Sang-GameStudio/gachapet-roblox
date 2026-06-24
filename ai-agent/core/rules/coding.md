# Roblox Coding Guidelines (Luau)

Follow these standards to write robust, secure, and exploit-proof Luau code.

## 1. Network Security (Server-Authoritative Design)
- **Never trust client parameters**:
  - The first argument of `OnServerEvent` or `OnServerInvoke` is always the `player` instance. The server must use this implicitly and NEVER allow the client to pass the player instance or parameterize crucial values like prices, rarity chances, or items they want to write to database.
  - **Example (Bad)**: Client says "give me Dog pet". Server gives it.
  - **Example (Good)**: Client fires `PurchaseEggEvent("BasicEgg")`. Server reads the price of `BasicEgg` from config, verifies player's coin balance from server data, deducts the coins on the server, rolls Gacha, and writes result to server inventory.

- **Rate Limiting / Debounce (Cooldown)**:
  - Hacker tools can fire RemoteEvents thousands of times per second.
  - Always use a player-specific cooldown dictionary on the server:
    ```lua
    local lastActionTime = {} -- [player.UserId] = tick()
    local COOLDOWN_DURATION = 0.5
    
    remoteEvent.OnServerEvent:Connect(function(player, ...)
        local currentTime = tick()
        local lastTime = lastActionTime[player.UserId] or 0
        if currentTime - lastTime < COOLDOWN_DURATION then
            warn("Player " .. player.Name .. " is rate limited!")
            return -- Block request
        end
        lastActionTime[player.UserId] = currentTime
        -- Process action...
    end)
    ```

## 2. Data Persistence (DataStore)
- **Wrap in pcall**:
  - DataStore calls interact with Roblox web services. They will occasionally fail due to network hiccups. Always wrap `GetAsync`, `SetAsync`, and `UpdateAsync` in a `pcall`:
    ```lua
    local success, data = pcall(function()
        return myDataStore:GetAsync(playerKey)
    end)
    if not success then
        warn("Failed to load data: " .. tostring(data))
    end
    ```

- **Avoid direct Model saving**:
  - Save tables containing standard Lua datatypes (string names of owned pets, integers for coins) instead of direct Roblox Instance objects.
  - Deserialize the strings into Roblox instances (e.g. cloning models from `ReplicatedStorage.Models`) when loading.

- **game:BindToClose()**:
  - Studio local servers close quickly. `PlayerRemoving` might not complete database calls before the server terminates. Always write a `BindToClose` routine to loop and save all active players before shutdown:
    ```lua
    game:BindToClose(function()
        for _, player in ipairs(game.Players:GetPlayers()) do
            savePlayerData(player) -- Custom function that wraps SetAsync/UpdateAsync
        end
    end)
    ```

## 3. Object-Oriented Programming (OOP)
- Use metatables to implement classes.
- Standard class template:
  ```lua
  local MyClass = {}
  MyClass.__index = MyClass

  function MyClass.new(arg1)
      local self = setmetatable({}, MyClass)
      self.arg1 = arg1
      return self
  end

  function MyClass:DoSomething()
      print(self.arg1)
  end

  return MyClass
  ```
