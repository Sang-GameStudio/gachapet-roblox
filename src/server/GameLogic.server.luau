--[[
	GameLogic.server.luau
	Logic xử lý các Remote Events và Remote Functions trên Server.
	Đảm bảo Server-Authoritative: trừ tiền, quay gacha, kiểm tra debounce, trang bị pet và thiết lập vật lý bám đuôi.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Import GachaModule từ ReplicatedStorage.Shared
local GachaModule = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GachaModule"))

-- Tham chiếu tới các Remote từ ReplicatedStorage
local OpenEggEvent = ReplicatedStorage:WaitForChild("OpenEggEvent")
local EquipPetEvent = ReplicatedStorage:WaitForChild("EquipPetEvent")
local GetInventory = ReplicatedStorage:WaitForChild("GetInventory")

-- Giá tiền của các loại trứng (Đề bài yêu cầu: trứng mở ra Pet)
local EGG_PRICE = 100 
-- Cooldown mua trứng chống spam (giây)
local GACHA_COOLDOWN = 0.8

-- Dictionary quản lý cooldown mua trứng của từng người chơi riêng biệt
local lastPurchaseTime = {} -- [player.UserId] = tick()

--[[
	Hàm dọn dẹp (destroy) Pet cũ đang đi theo người chơi trong Workspace nếu có
]]
local function destroyExistingPet(player)
	local existingPet = workspace:FindFirstChild(player.Name .. "_Pet")
	if existingPet then
		existingPet:Destroy()
	end
end

--[[
	Hàm khởi tạo thiết lập vật lý bám đuôi (AlignPosition & AlignOrientation)
	đưa Pet theo sau lưng nhân vật của Player
]]
local function setupPetPhysics(player, character, petModel)
	local rootPart = character:WaitForChild("HumanoidRootPart")
	local petRoot = petModel.PrimaryPart
	
	if not petRoot then
		warn("LỖI: Pet model không cấu hình PrimaryPart!")
		return
	end
	
	-- Thiết lập thuộc tính cơ bản của Pet
	for _, part in ipairs(petModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false -- Tắt va chạm để tránh đẩy người chơi bay lên
			part.Anchored = false   -- Tắt anchored để vật lý hoạt động
		end
	end

	-- Điểm neo trên người Player (lệch sang phải 2 studs, cao 1.5 studs, sau lưng 3 studs)
	local attachmentPlayer = rootPart:FindFirstChild("PetAttachment")
	if not attachmentPlayer then
		attachmentPlayer = Instance.new("Attachment")
		attachmentPlayer.Name = "PetAttachment"
		attachmentPlayer.Position = Vector3.new(2, 1.5, 3)
		attachmentPlayer.Parent = rootPart
	end
	
	-- Điểm neo trên người con Pet
	local attachmentPet = Instance.new("Attachment")
	attachmentPet.Name = "PetRootAttachment"
	attachmentPet.Parent = petRoot
	
	-- Lực hút vị trí (AlignPosition) đưa Pet bám theo điểm neo của Player
	local alignPos = Instance.new("AlignPosition")
	alignPos.Attachment0 = attachmentPet
	alignPos.Attachment1 = attachmentPlayer
	alignPos.MaxForce = 20000
	alignPos.Responsiveness = 15 -- Tạo độ nhạy mượt mà, có gia tốc tự nhiên
	alignPos.Parent = petRoot
	
	-- Lực xoay hướng (AlignOrientation) giúp Pet quay mặt theo hướng Player đi
	local alignOrient = Instance.new("AlignOrientation")
	alignOrient.Attachment0 = attachmentPet
	alignOrient.Attachment1 = attachmentPlayer
	alignOrient.MaxTorque = 20000
	alignOrient.Responsiveness = 15
	alignOrient.Parent = petRoot

	-- QUAN TRỌNG: Giao quyền tính toán vật lý về cho máy Client của người chơi.
	-- Điều này triệt tiêu độ trễ mạng (network lag) giúp chuyển động mượt 100%.
	local success, err = pcall(function()
		petRoot:SetNetworkOwner(player)
	end)
	if not success then
		warn("Không thể set Network Owner: " .. tostring(err))
	end
end

--[[
	Hàm tìm kiếm Model Pet trong ReplicatedStorage dựa theo tên
	Tìm kiếm trong cấu hình Assets -> Pets -> [Common/Rate/Legendary]
]]
local function findPetTemplate(petName)
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if not assets then return nil end
	
	local petsFolder = assets:FindFirstChild("Pets")
	if not petsFolder then return nil end
	
	-- Duyệt qua các folder độ hiếm (Common, Rate, Legendary)
	for _, rarityFolder in ipairs(petsFolder:GetChildren()) do
		if rarityFolder:IsA("Folder") then
			local petTemplate = rarityFolder:FindFirstChild(petName)
			if petTemplate then
				return petTemplate
			end
		end
	end
	
	-- Fallback: Tìm đệ quy trong ReplicatedStorage nếu có thay đổi ngoài ý muốn
	return ReplicatedStorage:FindFirstChild(petName, true)
end

--[[
	Hàm spawn mô hình Pet 3D vào game và gắn vật lý bám theo
]]
local function spawnPetModel(player, character, petName)
	-- Bước 1: Dọn dẹp Pet cũ nếu có
	destroyExistingPet(player)
	
	if not petName then return end

	-- Tìm model Pet tương ứng trong Assets
	local petTemplate = findPetTemplate(petName)
	
	if petTemplate then
		local petClone = petTemplate:Clone()
		petClone.Name = player.Name .. "_Pet"
		petClone.Parent = workspace
		
		-- Đặt vị trí xuất hiện ban đầu ngay sau lưng người chơi để tránh di chuyển đột ngột từ tọa độ 0,0,0
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			petClone:SetPrimaryPartCFrame(rootPart.CFrame * CFrame.new(2, 1.5, 3))
		end
		
		-- Cài đặt vật lý bám đuôi
		setupPetPhysics(player, character, petClone)
	else
		warn("LỖI: Không tìm thấy model Pet trong Assets/ReplicatedStorage có tên: " .. petName)
	end
end

--[[
	1. XỬ LÝ GET INVENTORY (RemoteFunction)
	Trả về dữ liệu Inventory ảo trên RAM Server về cho Client hiển thị UI.
]]
GetInventory.OnServerInvoke = function(player)
	-- Đợi dữ liệu tải xong từ DataStore nếu người chơi vừa vào game
	local timeout = 5
	local elapsed = 0
	while not shared.DataManager.IsLoaded(player) and elapsed < timeout do
		task.wait(0.1)
		elapsed = elapsed + 0.1
	end
	
	if shared.DataManager.IsLoaded(player) then
		return shared.DataManager.GetData(player)
	else
		warn("LỖI: Timeout chờ tải dữ liệu người chơi: " .. player.Name)
		return nil
	end
end

--[[
	2. XỬ LÝ MỞ TRỨNG GACHA (RemoteEvent)
]]
OpenEggEvent.OnServerEvent:Connect(function(player, eggType)
	-- Kiểm tra dữ liệu người chơi đã tải chưa
	if not shared.DataManager.IsLoaded(player) then return end
	
	local userId = player.UserId
	local currentTime = tick()
	
	-- Kiểm tra Debounce chống spam click
	local lastTime = lastPurchaseTime[userId] or 0
	if currentTime - lastTime < GACHA_COOLDOWN then
		warn("Spam click phát hiện từ: " .. player.Name)
		return
	end
	lastPurchaseTime[userId] = currentTime

	local playerData = shared.DataManager.GetData(player)
	
	-- Đảm bảo an toàn: Kiểm tra số dư xu của người chơi trên Server
	if playerData.Coins >= EGG_PRICE then
		-- 1. Trừ tiền an toàn trên Server
		shared.DataManager.AddCoins(player, -EGG_PRICE)
		
		-- 2. Thực hiện Roll Pet từ GachaModule
		local rolledPet = GachaModule.RollPet()
		
		-- 3. Thêm Pet trúng thưởng vào Inventory người chơi
		shared.DataManager.AddPet(player, rolledPet.Name)
		
		-- 4. Bắn tín hiệu kết quả về lại duy nhất Client của người chơi đó để chạy hiệu ứng
		OpenEggEvent:FireClient(player, rolledPet.Name, rolledPet.Rarity)
		print("Player " .. player.Name .. " mở thành công: " .. rolledPet.Name .. " (" .. rolledPet.Rarity .. ")")
	else
		warn("Người chơi không đủ tiền nhưng vẫn yêu cầu mua trứng: " .. player.Name)
	end
end)

--[[
	3. XỬ LÝ TRANG BỊ PET (RemoteEvent)
]]
EquipPetEvent.OnServerEvent:Connect(function(player, petName)
	if not shared.DataManager.IsLoaded(player) then return end
	
	local character = player.Character
	if not character then return end
	
	-- Cập nhật thông tin trang bị trong DataManager (có hàm check sở hữu bên trong)
	local success = shared.DataManager.SetEquippedPet(player, petName)
	
	if success then
		-- Spawn model Pet bám đuôi người chơi
		spawnPetModel(player, character, petName)
		print("Trang bị Pet thành công: " .. (petName or "None") .. " cho " .. player.Name)
	else
		warn("LỖI: Trang bị Pet thất bại, có thể không sở hữu Pet: " .. tostring(petName))
	end
end)

--[[
	Tự động trang bị lại Pet khi người chơi hồi sinh (CharacterAdded)
]]
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		-- Chờ nhân vật load hoàn chỉnh rồi mới spawn Pet
		task.wait(0.5)
		if shared.DataManager.IsLoaded(player) then
			local data = shared.DataManager.GetData(player)
			if data and data.EquippedPet then
				spawnPetModel(player, character, data.EquippedPet)
			end
		end
	end)
end)
