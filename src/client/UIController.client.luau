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
local SoundService = game:GetService("SoundService")

local CutsceneController = require(script.Parent:WaitForChild("CutsceneController"))

local LocalPlayer = Players.LocalPlayer
-- Lấy bảng PlayerGui chứa giao diện người chơi
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local MainGui = PlayerGui:WaitForChild("MainGui")

-- Tham chiếu tới các thành phần UI theo cấu trúc Explorer thực tế
local HUD = MainGui:WaitForChild("HUD")
local ShopBtn = HUD:WaitForChild("BtnShop")
local InvBtn = HUD:WaitForChild("BtnInventory")
local CoinsLabel = HUD:WaitForChild("LabelCoins")

local ShopFrame = MainGui:WaitForChild("ShopFrame")
local BuyEggBtn = ShopFrame:WaitForChild("BuyEggBtn")
local BtnCloseShop = ShopFrame:WaitForChild("BtnCloseShop")

local InventoryFrame = MainGui:WaitForChild("InventoryFrame")
local PetScrollingFrame = InventoryFrame:WaitForChild("PetScrollingFrame")
local BtnCloseInventory = InventoryFrame:WaitForChild("BtnCloseInventory")

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

-- Helper để định dạng số bằng dấu phẩy phân tách hàng nghìn (ví dụ: 79,400)
local function formatNumber(value)
	local str = tostring(value)
	local formatted = str
	while true do
		local k
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then break end
	end
	return formatted
end

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
		cam.FieldOfView = 50 -- FOV hẹp giúp camera zoom cận cảnh nhìn rõ Pet hơn
		viewport.CurrentCamera = cam
		cam.Parent = viewport
		
		-- 3. Thiết lập Camera ảo hướng thẳng vào mặt Pet (Đứng yên không xoay để tối ưu hiệu năng)
		local modelCFrame, modelSize = petClone:GetBoundingBox()
		local centerPos = modelCFrame.Position
		
		local radius = modelSize.Magnitude * 1.5 -- Khoảng cách camera dựa theo kích thước Pet
		local height = modelSize.Y * 0.5 -- Chiều cao đặt camera (nhìn xéo nhẹ từ trên xuống)
		
		cam.CFrame = CFrame.new(
			centerPos + Vector3.new(0, height, -radius),
			centerPos -- Luôn luôn hướng góc nhìn thẳng vào tâm Pet
		)
	end
end

--[[
	Hàm làm mới và đồng bộ dữ liệu giao diện túi đồ từ Server
]]
-- Bảng lưu trữ kết nối sự kiện click nút trang bị để dọn dẹp tránh trùng lặp/rò rỉ bộ nhớ
local buttonConnections = {}

--[[
	Hàm làm mới và đồng bộ dữ liệu giao diện túi đồ từ Server
	(Đã tối ưu hóa: Giữ nguyên các ô cũ để không bị reset vòng quay mô hình 3D)
]]
local function refreshInventoryUI()
	-- Gửi RemoteFunction lên Server lấy dữ liệu an toàn
	local playerData = GetInventory:InvokeServer()
	if not playerData then return end
	
	-- Cập nhật Coins hiển thị trên HUD
	CoinsLabel.Text = formatNumber(playerData.Coins)
	
	-- Lấy thông tin con Pet hiện tại đang được trang bị từ Server
	local currentlyEquipped = playerData.EquippedPet
	local inventory = playerData.Inventory or {}
	
	-- 🎯 BỘ LỌC TRÙNG: Chỉ hiển thị mỗi loại Pet duy nhất một lần (lọc trùng tuyệt đối)
	local uniqueInventory = {}
	local seenPets = {}
	for _, petName in ipairs(inventory) do
		if not seenPets[petName] then
			seenPets[petName] = true
			table.insert(uniqueInventory, petName)
		end
	end
	
	-- 1. LẤY DANH SÁCH CÁC Ô SLOT HIỆN ĐANG CÓ TRÊN GIAO DIỆN
	local existingSlots = {}
	for _, child in ipairs(PetScrollingFrame:GetChildren()) do
		-- Kiểm tra đúng là ô Frame chứa Pet (bỏ qua UIGridLayout, UIPadding...)
		if child:IsA("Frame") then
			table.insert(existingSlots, child)
		end
	end
	
	-- 2. DUYỆT QUA TÚI ĐỒ MỚI (LỌC TRÙNG): THIẾU THÌ TẠO THÊM, CÓ SẴN THÌ DÙNG LẠI
	for i, petName in ipairs(uniqueInventory) do
		local slot = existingSlots[i]
		local isNewSlot = false
		
		if not slot then
			-- Nếu số ô hiện tại ít hơn số Pet thực tế -> Clone thêm ô mới tinh
			slot = PetSlotTemplate:Clone()
			slot.Parent = PetScrollingFrame
			isNewSlot = true
		end
		
		slot.Name = petName
		slot.Visible = true
		
		-- ✨ ĐIỀU KIỆN VÀNG: Chỉ nạp lại mô hình 3D nếu là ô mới tạo hoặc chưa có PetView
		-- Giúp giữ nguyên ViewportFrame cũ đang xoay lơ lửng, không bị reset góc quay!
		local viewport = slot:FindFirstChild("PetView")
		if isNewSlot or not viewport or not viewport:FindFirstChild(petName) then
			renderPetToSlot(slot, petName)
		end
		
		-- 🎯 CẬP NHẬT TRẠNG THÁI TRANG BỊ TRỰC TIẾP
		local border = slot:FindFirstChild("Border")
		local tag = slot:FindFirstChild("EquippedTag")
		
		if petName == currentlyEquipped then
			if border then border.Enabled = true end
			if tag then tag.Visible = true end
		else
			if border then border.Enabled = false end
			if tag then tag.Visible = false end
		end
		
		-- ⚡ LÀM SẠCH VÀ GẮN LẠI SỰ KIỆN CLICK (Dùng cơ chế Disconnect thay vì Destroy nút giúp mượt mà hơn)
		local equipBtn = slot:FindFirstChild("EquipBtn")
		if equipBtn then
			-- Nếu đã có kết nối cũ thì ngắt đi để tránh lặp sự kiện
			if buttonConnections[slot] then
				buttonConnections[slot]:Disconnect()
			end
			
			buttonConnections[slot] = equipBtn.Activated:Connect(function()
				if petName == currentlyEquipped then
					EquipPetEvent:FireServer(nil)
				else
					EquipPetEvent:FireServer(petName)
				end
				
				-- Đợi Server xử lý và đồng bộ trạng thái
				task.wait(0.1)
				refreshInventoryUI()
			end)
		end
	end
	
	-- 3. DỌN DẸP CÁC Ô THỪA (Trường hợp danh sách duy nhất giảm đi)
	if #existingSlots > #uniqueInventory then
		for i = #uniqueInventory + 1, #existingSlots do
			local oldSlot = existingSlots[i]
			if oldSlot then
				-- Giải phóng kết nối nút bấm tương ứng trước khi xóa
				if buttonConnections[oldSlot] then
					buttonConnections[oldSlot]:Disconnect()
					buttonConnections[oldSlot] = nil
				end
				oldSlot:Destroy()
			end
		end
	end
end

--[[
	Hàm vẽ mô hình Trứng 3D tĩnh vào ô EggView của Cửa hàng
	(Cố định camera góc nghiêng, không chạy vòng lặp xoay tròn)
]]
local function renderEggToShop()
	local eggView = ShopFrame:FindFirstChild("EggView")
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	
	-- Quả trứng được lưu trực tiếp dưới Assets với tên là "Egg"
	local eggModelTemplate = assets and assets:FindFirstChild("Egg")
	
	if eggView and eggModelTemplate then
		-- 1. Dọn sạch các mô hình trứng hoặc camera cũ nếu có (giữ lại các UI constraint)
		for _, child in ipairs(eggView:GetChildren()) do
			if child:IsA("Model") or child:IsA("BasePart") or child:IsA("Camera") then
				child:Destroy()
			end
		end
		
		-- 2. Clone mô hình quả trứng đặt vào ViewportFrame
		local eggClone = eggModelTemplate:Clone()
		eggClone.Parent = eggView
		
		-- Anchor toàn bộ các Part cấu thành quả trứng để tránh bị rơi tự do
		if eggClone:IsA("BasePart") then
			eggClone.Anchored = true
		else
			for _, part in ipairs(eggClone:GetDescendants()) do
				if part:IsA("BasePart") then 
					part.Anchored = true 
				end
			end
		end
		
		-- 3. Khởi tạo Camera ảo cố định
		local cam = Instance.new("Camera")
		cam.FieldOfView = 45 -- Góc FOV vừa phải giúp quả trứng nhìn đầy đặn
		eggView.CurrentCamera = cam
		cam.Parent = eggView
		
		-- 4. Tính toán tiêu điểm dựa trên kích thước thực tế của quả trứng
		local modelCFrame, modelSize
		if eggClone:IsA("Model") then
			modelCFrame, modelSize = eggClone:GetBoundingBox()
		else
			modelCFrame = eggClone.CFrame
			modelSize = eggClone.Size
		end
		
		local centerPos = modelCFrame.Position
		local radius = modelSize.Magnitude * 1.3 -- Khoảng cách camera lùi ra xa vừa đủ ôm trọn quả trứng
		
		-- 🎯 ĐẶT CAMERA GÓC TĨNH CỐ ĐỊNH (KHÔNG DÙNG RENDERSTEPPED)
		-- Đặt camera chếch về phía trước (trục Z) và hơi cao hơn tâm quả trứng một chút (trục Y)
		cam.CFrame = CFrame.new(
			centerPos + Vector3.new(0, modelSize.Y * 0.2, radius), 
			centerPos -- Luôn khóa góc nhìn hướng thẳng vào tâm quả trứng
		)
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
		-- Tải mô hình trứng 3D tĩnh khi mở ShopFrame
		elseif frame == ShopFrame then
			renderEggToShop()
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

-- 🖲️ HIỆU ỨNG HOVER & PRESS CHỈ ĐỔI MÀU CHO NÚT ĐÓNG (KHÔNG SCALE)
local function tweenCloseButtonColor(button, targetColor)
	local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(button, tweenInfo, { ImageColor3 = targetColor }):Play()
end

-- Hàm thiết lập hiệu ứng Hover, Press và sự kiện đóng cho nút đóng
local function setupCloseButtonEffects(button, closeFrame, originalSize)
	-- 1. Khi di chuột vào (Hover) -> Nút hơi mờ/tối nhẹ đi một chút tinh tế
	button.MouseEnter:Connect(function()
		tweenCloseButtonColor(button, Color3.fromRGB(235, 235, 235))
	end)

	-- 2. Khi rời chuột ra -> Trả về màu sắc ảnh gốc nguyên bản
	button.MouseLeave:Connect(function()
		tweenCloseButtonColor(button, Color3.fromRGB(255, 255, 255))
	end)

	-- 3. Khi ấn chuột xuống (Press) -> Tối hẳn xuống để tạo hiệu ứng lún cơ học rõ rệt
	button.MouseButton1Down:Connect(function()
		tweenCloseButtonColor(button, Color3.fromRGB(170, 170, 170))
	end)

	-- 4. Khi thả chuột ra -> Trả về màu đang Hover để chờ lượt tương tác tiếp theo
	button.MouseButton1Up:Connect(function()
		tweenCloseButtonColor(button, Color3.fromRGB(235, 235, 235))
	end)

	-- 5. Kích hoạt hàm đóng khung tương ứng khi click
	button.Activated:Connect(function()
		if closeFrame.Visible then
			toggleFrame(closeFrame, originalSize)
		end
	end)
end

-- Hàm thiết lập hiệu ứng Hover, Press cho các nút HUD (Shop/Inventory)
local function setupHUDButtonEffects(button)
	button.MouseEnter:Connect(function()
		tweenCloseButtonColor(button, Color3.fromRGB(235, 235, 235))
	end)

	button.MouseLeave:Connect(function()
		tweenCloseButtonColor(button, Color3.fromRGB(255, 255, 255))
	end)

	button.MouseButton1Down:Connect(function()
		tweenCloseButtonColor(button, Color3.fromRGB(170, 170, 170))
	end)

	button.MouseButton1Up:Connect(function()
		tweenCloseButtonColor(button, Color3.fromRGB(235, 235, 235))
	end)
end

-- Thiết lập hiệu ứng và sự kiện cho cả 2 nút đóng của Kho hàng và Cửa hàng
setupCloseButtonEffects(BtnCloseInventory, InventoryFrame, inventoryFrameOriginalSize)
setupCloseButtonEffects(BtnCloseShop, ShopFrame, shopFrameOriginalSize)

-- Thiết lập hiệu ứng Hover/Press cho các nút trên HUD
setupHUDButtonEffects(ShopBtn)
setupHUDButtonEffects(InvBtn)

-- Lắng nghe nút mua trứng trong Shop
BuyEggBtn.Activated:Connect(function()
	OpenEggEvent:FireServer("BasicEgg")
end)

-- Lắng nghe kết quả mở trứng thành công từ Server và chạy cắt cảnh 3D
OpenEggEvent.OnClientEvent:Connect(function(petName, rarity)
	print("✨ [UI] Server báo trúng chú Pet: " .. petName .. " [" .. rarity .. "]")
	
	-- Chạy hiệu ứng cắt cảnh mở trứng 3D ngoài không gian ảo
	CutsceneController.Play(petName, rarity, ShopFrame, InventoryFrame, refreshInventoryUI)
end)

-- Khởi động lần đầu: đồng bộ và hiển thị số tiền Coins, tự động phát BGM
task.spawn(function()
	-- 🎵 KÍCH HOẠT NHẠC NỀN BACKGROUND TỰ ĐỘNG KHI CHƠI GAME
	local assets = ReplicatedStorage:WaitForChild("Assets")
	local sfxFolder = assets:WaitForChild("SFXs")
	local soundServiceBGM = SoundService:FindFirstChild("Background")
	if not soundServiceBGM then
		local originalBGM = sfxFolder:WaitForChild("Background")
		if originalBGM and originalBGM:IsA("Sound") then
			soundServiceBGM = originalBGM:Clone()
			soundServiceBGM.Parent = SoundService
		end
	end
	if soundServiceBGM and not soundServiceBGM.IsPlaying then
		soundServiceBGM:Play()
	end
	
	task.wait(0.5)
	local data = GetInventory:InvokeServer()
	if data then
		CoinsLabel.Text = formatNumber(data.Coins)
	end
end)
