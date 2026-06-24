# Template: Roblox Feature Implementation

Use this template when implementing a new Roblox/Luau gameplay feature (e.g., Gacha module, Shop UI, DataManager).

## 1. Description
Briefly describe what this feature does, where it is placed in the Rojo structure, and what clients/servers it communicates with.

## 2. Interface / API Definition
Define the methods, properties, and RemoteEvents/RemoteFunctions that this feature exposes or listens to.

### Remote Events / Functions Mapped:
- `ReplicatedStorage.Shared.Name` (ModuleScript / OOP)
- `ReplicatedStorage.RemoteName` (Event/Function)

## 3. Server Logic (if applicable)
```lua
-- File: src/server/MyFeatureServer.server.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Remote references
-- Cooldowns / Debounce handling
-- PlayerAdded / BindToClose routines
```

## 4. Client Logic (if applicable)
```lua
-- File: src/client/MyFeatureClient.client.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- UI element references
-- Remote calls
-- Tween animations
```

## 5. Security & Performance Checklist
- [ ] Server parameter validation (Does the client parameterize price or weights?)
- [ ] Cooldowns implemented per player ID.
- [ ] Network Ownership set to client for physics models.
- [ ] event connections disconnected appropriately.
- [ ] ViewportFrame cameras/models cleaned up on close.
- [ ] All network/Datastore errors handled using `pcall`.
