--[[
	UIController.client.luau
	Điều khiển toàn bộ giao diện người dùng (Shop, Inventory, Coins HUD) ở phía Client.
	Đồng bộ và gửi yêu cầu mạng lên Server thông qua RemoteEvents & RemoteFunctions.
	Tích hợp hiệu ứng Camera xoay quanh Pet và Tween chuyển động khung hình UI.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
-- Lấy bảng PlayerGui chứa giao diện người chơi
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local MainGui = PlayerGui:WaitForChild("MainGui")

-- Tham chiếu tới các thành phần UI theo cấu trúc Explorer thực tế
local HUD = MainGui:WaitForChild("HUD")
local ShopBtn = HUD:WaitForChild("ShopBtn")
local InvBtn = HUD:WaitForChild("InvBtn")
local CoinsLabel = HUD:WaitForChild("CoinsLabel")

local ShopFrame = MainGui:WaitForChild("ShopFrame")
local BuyEggBtn = ShopFrame:WaitForChild("BuyEggBtn")

local InventoryFrame = MainGui:WaitForChild("InventoryFrame")
local PetScrollingFrame = InventoryFrame:WaitForChild("PetScrollingFrame")

-- Sửa lại đường dẫn PetSlotTemplate nằm trong thư mục Templates
local Templates = ReplicatedStorage:WaitForChild("Templates")
local PetSlotTemplate = Templates:WaitForChild("PetSlotTemplate")

-- Tham chiếu các cổng mạng (Remote) giao tiếp với Server
local OpenEggEvent = ReplicatedStorage:WaitForChild("OpenEggEvent")
local EquipPetEvent = ReplicatedStorage:WaitForChild("EquipPetEvent")
local GetInventory = ReplicatedStorage:WaitForChild("GetInventory")

-- Lưu giữ kích thước gốc của các bảng để phục vụ hiệu ứng Tween
local shopFrameOriginalSize = ShopFrame.Size
local inventoryFrameOriginalSize = InventoryFrame.Size

-- Ban đầu ẩn các bảng đi
ShopFrame.Visible = false
InventoryFrame.Visible = false

--[[
	Hàm tìm kiếm mô hình Pet gốc trong Assets -> Pets -> [Common/Rate/Legendary]
]]
local function findPetModel(petName)
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local petsFolder = assets and assets:FindFirstChild("Pets")
	if petsFolder then
		for _, rarityFolder in ipairs(petsFolder:GetChildren()) do
			if rarityFolder:IsA("Folder") then
				local template = rarityFolder:FindFirstChild(petName)
				if template then return template end
			end
		end
	end
	
	-- Fallback: Tìm đệ quy trong ReplicatedStorage phòng hờ
	return ReplicatedStorage:FindFirstChild(petName, true)
end

--[[
	Hàm vẽ mô hình Pet 3D vào ô ViewportFrame (PetView) 2D
	Tích hợp thuật toán xoay Camera lượng giác 360 độ xung quanh Pet
]]
local function renderPetToSlot(slotFrame, petName)
	local viewport = slotFrame:FindFirstChild("PetView")
	local petModelTemplate = findPetModel(petName)
	
	if viewport and petModelTemplate then
		-- Dọn sạch mô hình và camera cũ trong viewport
		for _, child in ipairs(viewport:GetChildren()) do
			if child:IsA("Model") or child:IsA("Camera") then 
				child:Destroy() 
			end
		end
		
		-- 1. Clone mô hình Pet đặt vào trong ViewportFrame
		local petClone = petModelTemplate:Clone()
		petClone.Parent = viewport
		
		-- Anchor toàn bộ các Part của Pet để tránh bị rơi tự do do trọng lực
		for _, part in ipairs(petClone:GetDescendants()) do
			if part:IsA("BasePart") then 
				part.Anchored = true 
			end
		end
		
		-- 2. Khởi tạo Camera ảo chuyên dụng
		local cam = Instance.new("Camera")
		cam.FieldOfView = 35 -- FOV hẹp giúp camera zoom cận cảnh nhìn rõ Pet hơn
		viewport.CurrentCamera = cam
		cam.Parent = viewport
		
		-- 3. Lập trình hiệu ứng Camera xoay quanh Pet thời gian thực
		local modelCFrame, modelSize = petClone:GetBoundingBox()
		local centerPos = modelCFrame.Position
		
		-- Tốc độ xoay (Tăng lên 120 độ mỗi giây để Pet quay nhanh hơn như yêu cầu)
		local rotationSpeed = 120 
		local currentAngle = 0
		
		local renderConnection
		renderConnection = RunService.RenderStepped:Connect(function(dt)
			-- BẢO VỆ TRÁNH RÒ RỈ BỘ NHỚ: Ngắt kết nối ngay nếu UI/Pet bị xóa
			if not petClone or not petClone.Parent or not cam or not cam.Parent then
				if renderConnection then 
					renderConnection:Disconnect() 
				end
				return
			end
			
			-- Tính toán góc xoay dựa trên delta time để mượt mà trên mọi màn hình (60Hz - 240Hz)
			currentAngle = currentAngle + (rotationSpeed * dt)
			local rad = math.rad(currentAngle)
			
			-- Thuật toán lượng giác quay camera xung quanh vị trí trung tâm của Pet
			local radius = modelSize.Magnitude * 1.2 -- Khoảng cách camera dựa theo kích thước Pet
			local height = modelSize.Y * 0.5 -- Chiều cao đặt camera (nhìn xéo nhẹ từ trên xuống)
			local offsetX = math.sin(rad) * radius
			local offsetZ = math.cos(rad) * radius
			
			cam.CFrame = CFrame.new(
				centerPos + Vector3.new(offsetX, height, offsetZ),
				centerPos -- Luôn luôn hướng góc nhìn thẳng vào tâm Pet
			)
		end)
	end
end

--[[
	Hàm làm mới và đồng bộ dữ liệu giao diện túi đồ từ Server
]]
local function refreshInventoryUI()
	-- Xóa toàn bộ các ô Pet cũ đang hiển thị (giữ lại UIGridLayout)
	for _, child in ipairs(PetScrollingFrame:GetChildren()) do
		if child:IsA("GuiObject") and child.Name ~= "UIGridLayout" then 
			child:Destroy() 
		end
	end
	
	-- Gửi RemoteFunction lên Server lấy dữ liệu an toàn
	local playerData = GetInventory:InvokeServer()
	if playerData then
		-- Cập nhật Coins hiển thị trên HUD
		CoinsLabel.Text = "Coins: " .. tostring(playerData.Coins)
		
		if playerData.Inventory then
			-- Tạo các ô vật phẩm tương ứng với danh sách sở hữu
			for _, petName in ipairs(playerData.Inventory) do
				local newSlot = PetSlotTemplate:Clone()
				newSlot.Name = petName
				newSlot.Visible = true
				newSlot.Parent = PetScrollingFrame
				
				-- Vẽ 3D Pet lên ô vật phẩm
				renderPetToSlot(newSlot, petName)
				
				-- Kiểm tra xem Pet này có đang được trang bị đi cùng người chơi không
				local isEquipped = (playerData.EquippedPet == petName)
				local equipBtn = newSlot:FindFirstChild("EquipBtn")
				
				if equipBtn then
					-- Cập nhật chữ và màu nền nút bấm tương ứng trạng thái trang bị
					if isEquipped then
						equipBtn.Text = "Unequip"
						equipBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 100) -- Màu đỏ báo tháo trang bị
					else
						equipBtn.Text = "Equip"
						equipBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100) -- Màu xanh báo trang bị
					end
					
					-- Kết nối sự kiện bấm nút để gửi yêu cầu trang bị/tháo trang bị lên Server
					equipBtn.Activated:Connect(function()
						if isEquipped then
							EquipPetEvent:FireServer(nil) -- Gửi nil để tháo trang bị
						else
							EquipPetEvent:FireServer(petName) -- Gửi tên pet để trang bị
						end
						
						-- Đợi Server xử lý đồng bộ và vẽ lại UI
						task.wait(0.2)
						refreshInventoryUI()
					end)
				end
			end
		end
	end
end

--[[
	Hàm thực hiện đóng/mở giao diện bằng hiệu ứng Tween mượt mà (Game Feel)
]]
local function toggleFrame(frame, originalSize)
	local isVisible = not frame.Visible
	
	if isVisible then
		-- Thu nhỏ về 0, kích hoạt hiển thị rồi Tween phóng to
		frame.Size = UDim2.fromScale(0, 0)
		frame.Visible = true
		
		local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		local tween = TweenService:Create(frame, tweenInfo, { Size = originalSize })
		tween:Play()
		
		-- Tải lại túi đồ khi mở Inventory
		if frame == InventoryFrame then
			refreshInventoryUI()
		end
	else
		-- Tween thu nhỏ về 0 rồi ẩn đi
		local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local tween = TweenService:Create(frame, tweenInfo, { Size = UDim2.fromScale(0, 0) })
		tween:Play()
		
		local connection
		connection = tween.Completed:Connect(function()
			frame.Visible = false
			connection:Disconnect()
		end)
	end
end

-- Cấu hình sự kiện bấm nút HUD đóng mở bảng
ShopBtn.Activated:Connect(function()
	toggleFrame(ShopFrame, shopFrameOriginalSize)
	if ShopFrame.Visible then
		-- Tự động đóng Inventory khi mở Shop
		if InventoryFrame.Visible then
			toggleFrame(InventoryFrame, inventoryFrameOriginalSize)
		end
	end
end)

InvBtn.Activated:Connect(function()
	toggleFrame(InventoryFrame, inventoryFrameOriginalSize)
	if InventoryFrame.Visible then
		-- Tự động đóng Shop khi mở Inventory
		if ShopFrame.Visible then
			toggleFrame(ShopFrame, shopFrameOriginalSize)
		end
	end
end)

-- Lắng nghe nút mua trứng trong Shop
BuyEggBtn.Activated:Connect(function()
	OpenEggEvent:FireServer("BasicEgg")
end)

-- Lắng nghe kết quả mở trứng thành công từ Server (Chuẩn bị làm hiệu ứng ở Ngày 4)
OpenEggEvent.OnClientEvent:Connect(function(petName, rarity)
	print("✨ [UI] Server báo trúng chú Pet: " .. petName .. " [" .. rarity .. "]")
	
	-- Làm mới túi đồ và đồng bộ Coins
	refreshInventoryUI()
end)

-- Khởi động lần đầu: đồng bộ và hiển thị số tiền Coins
task.spawn(function()
	task.wait(0.5)
	local data = GetInventory:InvokeServer()
	if data then
		CoinsLabel.Text = "Coins: " .. tostring(data.Coins)
	end
end)
