# Roblox Project Client-Server Architecture

This document describes the design decisions, file structure, and network architecture for the Roblox Egg Gacha & Pet project.

---

## 1. Directory Structure (Rojo Mapping)

The workspace is organized to support a Rojo-to-Roblox synchronisation flow:

```
📁 project
├── 📁 src
│   ├── 📁 client               -- Maps to StarterPlayer.StarterPlayerScripts.Client
│   │   └── 📜 init.client.luau  -- Entry point for client scripts, listens to UI button events
│   │
│   ├── 📁 server               -- Maps to ServerScriptService.Server
│   │   ├── 📜 DataManager.server.luau -- Server-authoritative inventory save/load via DataStoreService
│   │   ├── 📜 GameLogic.server.luau   -- Listens to Gacha/Equip Remote events, checks player coins/debounces
│   │   └── 📜 init.server.luau        -- Server initialization script
│   │
│   └── 📁 shared               -- Maps to ReplicatedStorage.Shared
│       ├── 📜 GachaModule.luau  -- Weighted random probabilities (Common 80%, Rare 15%, Legendary 5%)
│       ├── 📜 PetClass.luau     -- OOP Metatable representation of Pet instances
│       └── 📜 Hello.luau        -- Simple greeting module
│
├── 📜 default.project.json     -- Rojo configurations (maps files to ReplicatedStorage, ServerScriptService, etc.)
└── 📜 rojo.exe                 -- Rojo CLI utility to sync project files with Roblox Studio
```

---

## 2. Sequence Diagram: Egg Hatching (Gacha Core Loop)

This sequence diagram depicts how client interactions invoke server validation and database write, followed by local client visual rendering:

```mermaid
sequenceDiagram
    autonumber
    actor Player as Player (Client UI)
    participant LocalScript as LocalScript (Client StarterGui)
    participant GameLogic as GameLogic (ServerScriptService)
    participant DataStore as DataStore (Roblox Cloud)

    Player->>LocalScript: Clicks "Purchase Egg"
    LocalScript->>GameLogic: FireServer("BasicEgg") via OpenEggEvent
    
    activate GameLogic
    Note over GameLogic: 1. Read price of BasicEgg<br/>2. Retrieve player coin balance<br/>3. Verify Player-specific Debounce dictionary
    
    alt Insufficient coins or rate-limited
        GameLogic-->>LocalScript: Warn/Do nothing (Fail check)
    else Sufficient coins and cooldown cleared
        Note over GameLogic: 4. Deduct coins from leaderstats<br/>5. Invoke GachaModule.Roll() -> "Legendary_Dragon"<br/>6. Update RAM session data (Inventory table)
        GameLogic->>DataStore: Save periodically or on player leave (BindToClose)
        GameLogic-->>LocalScript: FireClient("Legendary_Dragon") via OpenEggEvent
    end
    deactivate GameLogic

    activate LocalScript
    Note over LocalScript: 7. Play egg shake animation (TweenService)<br/>8. Emit light particles (VFX) and sound (SFX)<br/>9. Render 3D pet model inside ViewportFrame
    LocalScript-->>Player: Reveal new pet on screen!
    deactivate LocalScript
```

---

## 3. Network Boundaries & Exploit Prevention

| Operation | Client Role | Server Role (Authoritative) |
|---|---|---|
| **Egg Hatching** | Triggers UI request, plays egg shaking VFX/SFX. | Deducts coins, generates random roll, inserts item to server data cache. |
| **Equip Pet** | Triggers equip request by sending pet ID. | Validates that player actually owns the pet in server RAM, instantiates pet model, and binds physics constraints. |
| **Inventory View** | Renders 3D viewports from localized cache. | Reads from DataStore, returns clean tables via RemoteFunction. |
