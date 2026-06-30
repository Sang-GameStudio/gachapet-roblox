# Naming Conventions for Roblox (Luau)

Ensure you follow these naming guidelines to keep the codebase clean, readable, and consistent.

## 1. Directory & File Names
- **Files mapped by Rojo**:
  - Module scripts or OOP classes: `PascalCase.luau` (e.g., `GachaModule.luau`, `PetClass.luau`).
  - Server scripts: `PascalCase.server.luau` (e.g., `DataManager.server.luau`).
  - Client scripts: `PascalCase.client.luau` (e.g., `ShopController.client.luau`).

## 2. Variables & Constants
- **Local Variables / Parameters**: `camelCase` (e.g., `playerCoins`, `eggName`, `rolledPet`).
- **Global / Script-level Constants**: `UPPER_SNAKE_CASE` (e.g., `COOLDOWN_TIME`, `DEFAULT_PET_NAME`).
- **Services**: Use the same name as the service itself (e.g., `local ReplicatedStorage = game:GetService("ReplicatedStorage")`).
- **Private Variables / Fields**: Prefix with an underscore `_` (e.g., `self._equippedPet`).

## 3. Functions & Methods
- **Local Functions**: `camelCase` (e.g., `local function onPlayerAdded()`).
- **Module/Class Public Methods**: `PascalCase` (e.g., `function Pet:FollowPlayer()`, `function GachaModule.RollPet()`).
- **OOP Constructors**: Always name the constructor `new` (e.g., `function Pet.new(name)`).

## 4. Roblox Instances (Explorer Nodes)
- **Folder Names**: `PascalCase` (e.g., `Models`, `SharedModules`).
- **Remote Events**: `PascalCase` with `Event` suffix (e.g., `OpenEggEvent`, `EquipPetEvent`).
- **Remote Functions**: `PascalCase` with `Function` suffix or a descriptive action (e.g., `GetInventory`).
- **UI Elements (Guis)**: `PascalCase` suffixing the type (e.g., `ShopFrame`, `InventoryScrollingFrame`, `OpenShopButton`).
