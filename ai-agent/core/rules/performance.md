# Roblox Performance Optimization Guidelines

Optimizing your Roblox game ensures smooth gameplay across low-end mobile devices and high-end PCs alike.

## 1. Network Ownership for Physics Models
- **Assign Network Owner**:
  - When creating a physics-based object (like a Pet using `AlignPosition` or `AlignOrientation`) that is tied to a specific player, assign its Network Owner to that player on the server.
  - This delegates the physics calculation of the model to the client, preventing network lag and stuttering.
  ```lua
  local petRoot = petModel.PrimaryPart
  if petRoot then
      petRoot:SetNetworkOwner(player)
  end
  ```
- **Disable CanCollide**:
  - Ensure the pet's collision properties are turned off (`CanCollide = false`) to prevent the physics engine from wasting calculations on pet-character collisions, and to stop the pet from pushing the player around.

## 2. Event Connection Cleanup (Prevent Memory Leaks)
- **Disconnect Connections**:
  - Unused event connections hang in memory and cause memory leaks. Always store your connections and call `:Disconnect()` when cleaning up.
  ```lua
  local connection
  connection = player.CharacterAdded:Connect(function(char)
      -- logic
  end)

  -- When cleaning up:
  if connection then
      connection:Disconnect()
  end
  ```

## 3. ViewportFrame Performance
- **Avoid heavy rendering in ViewportFrames**:
  - ViewportFrames do not support shadows, lighting effects, or post-processing, and they require extra draw calls.
  - Keep models inside ViewportFrames simple.
  - Do not spin or move models in ViewportFrames using heavy Server-side script. Use a simple client-side rotation script on `RunService.RenderStepped` for visual effects.

## 4. UI Scale Responsiveness
- **Use scale rather than offset**:
  - Ensure ScreenGuis adapt to different resolutions (PC vs. Phone vs. Tablet).
  - Use `AutoScale Lite` or set positions and sizes using the **Scale** components of `UDim2` (e.g. `UDim2.fromScale(0.5, 0.5)`) instead of hardcoded pixel **Offset** values.
  - Use `UIAspectRatioConstraint` to prevent frames from getting stretched out of proportion on wider or taller screens.
