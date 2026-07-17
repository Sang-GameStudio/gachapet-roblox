--[[
	GameLogic.server.luau
	Logic xử lý các Remote Events và Remote Functions trên Server.
	Đảm bảo Server-Authoritative: trừ tiền, quay gacha, kiểm tra debounce, và ủy quyền trang bị Pet.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Import các Module cần thiết
local GachaModule = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GachaModule")) -- gọi từ gốc xuống
local PetManager = require(script.Parent:WaitForChild("PetManager")) -- lên 1 bậc --> gọi xuống

-- Tham chiếu tới các Remote từ ReplicatedStorage
local OpenEggEvent = ReplicatedStorage:WaitForChild("OpenEggEvent")  -- đăng setup trong file defalt của Rojo hoặc tự tạo ở Roblox studio
local EquipPetEvent = ReplicatedStorage:WaitForChild("EquipPetEvent")
local GetInventory = ReplicatedStorage:WaitForChild("GetInventory")

-- Giá tiền của các loại trứng
local EGG_PRICE = 100 
-- Cooldown mua trứng chống spam (giây)
local GACHA_COOLDOWN = 0.8

-- Dictionary quản lý cooldown mua trứng của từng người chơi riêng biệt
local lastPurchaseTime = {} -- [player.UserId] = tick()

--[[
	1. XỬ LÝ GET INVENTORY (RemoteFunction) - 2 chiều
	Trả về dữ liệu Inventory ảo trên RAM Server về cho Client hiển thị UI.
]]
GetInventory.OnServerInvoke = function(player)
	-- Đợi dữ liệu tải xong từ DataStore nếu người chơi vừa vào game
	local timeout = 5
	local elapsed = 0
	while not shared.DataManager.IsLoaded(player) and elapsed < timeout do -- nếu player vừa vào game mà dữ liệu trên cloud chưa kịp tải vào RAM --> server đóng băng tạm, cứ mỗi 0.1s kiểm tra 1 lần đến khi tải data xong, nếu quá 5s không tải xong thì trả về nil và in ra lỗi
		task.wait(0.1)
		elapsed = elapsed + 0.1
	end
	
	if shared.DataManager.IsLoaded(player) then -- nếu data đã nạp và ram, server đóng gói all dữ liệu trả về client 
		return shared.DataManager.GetData(player) -- trả về dữ liệu cho client
	else -- nếu quá 5s không tải xong
		warn("LỖI: Timeout chờ tải dữ liệu người chơi: " .. player.Name)
		return nil
	end
end

--[[
	2. XỬ LÝ MỞ TRỨNG GACHA (RemoteEvent) - 1 chiều
]]
OpenEggEvent.OnServerEvent:Connect(function(player, eggType)
	-- Kiểm tra dữ liệu người chơi đã tải chưa
	if not shared.DataManager.IsLoaded(player) then return end
	
	local userId = player.UserId
	local currentTime = tick()  -- lấy mốc thời gian hiện tại của server tính bằng giây
	
	-- Kiểm tra Debounce chống spam click
	local lastTime = lastPurchaseTime[userId] or 0 -- lastTime lấy giá trị tick() gần nhất của người chơi, nếu chưa có thì mặc định là 0
	if currentTime - lastTime < GACHA_COOLDOWN then -- nếu thời gian hiện tại trừ đi thời gian gần nhất nhỏ hơn 0.8s thì
		warn("Spam click phát hiện từ: " .. player.Name)
		return
	end
	lastPurchaseTime[userId] = currentTime -- cập nhật lại thời gian gần nhất

	local playerData = shared.DataManager.GetData(player) -- lấy dữ liệu của player ra để check coins
	
	-- Đảm bảo an toàn: Kiểm tra số dư xu của người chơi trên Server
	local playerCoins = tonumber(playerData.Coins) or 0
	if playerCoins >= EGG_PRICE then
		-- 1. Trừ tiền an toàn trên Server
		shared.DataManager.AddCoins(player, -EGG_PRICE)
		
		-- 2. Thực hiện Roll Pet từ GachaModule (truyền player vào để tính Pity)
		local rolledPet = GachaModule.RollPet(player)
		
		-- 3. Thêm Pet trúng thưởng vào Inventory người chơi
		shared.DataManager.AddPet(player, rolledPet.Name)
		
		-- 4. Bắn tín hiệu kết quả và dữ liệu Pity đếm mới cập nhật về Client
		local updatedData = shared.DataManager.GetData(player)
		OpenEggEvent:FireClient(
			player, 
			rolledPet.Name, 
			rolledPet.Rarity, 
			updatedData.RarePityCount or 0, 
			updatedData.LegendaryPityCount or 0
		)
		print("Player " .. player.Name .. " mở thành công: " .. rolledPet.Name .. " (" .. rolledPet.Rarity .. ")")
	else
		warn("Người chơi không đủ tiền nhưng vẫn yêu cầu mua trứng: " .. player.Name)
	end
end)

--[[
	3. XỬ LÝ TRANG BỊ PET (RemoteEvent)
]]
EquipPetEvent.OnServerEvent:Connect(function(player, petName)
	if not shared.DataManager.IsLoaded(player) then return end -- kiểm tra đã nạp data lên ram chưa
	
	local character = player.Character -- xem nhân vật có đang sống ngoài sân không
	if not character then return end
	
	-- Cập nhật thông tin trang bị trong DataManager (có hàm check sở hữu bên trong)
	local success = shared.DataManager.SetEquippedPet(player, petName)
	
	if success then
		-- Gọi PetManager để xử lý Spawn mô hình và cấu hình vật lý bám đuôi
		PetManager.SpawnPetModel(player, character, petName)
		print("Trang bị Pet thành công: " .. (petName or "None") .. " cho " .. player.Name)
	else
		warn("LỖI: Trang bị Pet thất bại, có thể không sở hữu Pet: " .. tostring(petName))
	end
end)

--[[
	Tự động trang bị lại Pet khi người chơi hồi sinh (CharacterAdded)
]]
Players.PlayerAdded:Connect(function(player) -- lắng nghe khi có người chơi bước vào server
	player.CharacterAdded:Connect(function(character) -- lắng nghe nv được sinh ra ngoài sàn đấu
		-- Chờ nhân vật load hoàn chỉnh rồi mới spawn Pet
		task.wait(0.5)
		if shared.DataManager.IsLoaded(player) then
			local data = shared.DataManager.GetData(player)
			if data and data.EquippedPet then
				PetManager.SpawnPetModel(player, character, data.EquippedPet)
			end
		end
	end)
end)

-- Khởi chạy vòng xoay bệ hào quang (Aura)
PetManager.Init()
