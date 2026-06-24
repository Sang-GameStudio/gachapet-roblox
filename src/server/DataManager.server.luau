--[[
	DataManager.server.luau
	Quản lý dữ liệu người chơi (Coins, Inventory, EquippedPet) bằng DataStoreService.
	Sử dụng cơ chế Session Caching trên RAM Server để tối ưu hiệu năng và chống exploit.
]]

local DataStoreService = game:GetService("DataStoreService")
-- Tạo hoặc lấy DataStore tên là "PlayerSaveData_v1"
local PlayerDataStore = DataStoreService:GetDataStore("PlayerSaveData_v1")
local Players = game:GetService("Players")

-- Cấu hình mặc định cho người chơi mới
local DEFAULT_DATA = {
	Coins = 100,
	Inventory = { "Common1" },
	EquippedPet = "Common1"
}

-- RAM Cache trên Server để truy cập nhanh chóng
local sessionData = {}

-- Expose các API thông qua bảng shared để các Script Server khác có thể gọi được
shared.DataManager = {}

--[[
	Hàm lấy toàn bộ dữ liệu của một người chơi từ RAM Cache
]]
function shared.DataManager.GetData(player)
	return sessionData[player.UserId]
end

--[[
	Hàm kiểm tra xem người chơi đã tải xong dữ liệu chưa
]]
function shared.DataManager.IsLoaded(player)
	return sessionData[player.UserId] ~= nil
end

--[[
	Hàm cộng hoặc trừ tiền (Coins) của người chơi an toàn trên Server
]]
function shared.DataManager.AddCoins(player, amount)
	local data = sessionData[player.UserId]
	if data then
		data.Coins = math.max(0, data.Coins + amount)
		
		-- Đồng bộ hiển thị lên Leaderstats UI của Roblox
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local coinsValue = leaderstats:FindFirstChild("Coins")
			if coinsValue then
				coinsValue.Value = data.Coins
			end
		end
		return true
	end
	return false
end

--[[
	Hàm thêm Pet mới vào Inventory của người chơi trên Server
]]
function shared.DataManager.AddPet(player, petName)
	local data = sessionData[player.UserId]
	if data then
		table.insert(data.Inventory, petName)
		return true
	end
	return false
end

--[[
	Hàm cập nhật trạng thái trang bị Pet của người chơi trên Server
]]
function shared.DataManager.SetEquippedPet(player, petName)
	local data = sessionData[player.UserId]
	if data then
		-- Kiểm tra xem player có sở hữu pet đó trong inventory không
		local ownsPet = false
		for _, ownedPet in ipairs(data.Inventory) do
			if ownedPet == petName then
				ownsPet = true
				break
			end
		end
		
		if ownsPet or petName == nil then
			data.EquippedPet = petName
			return true
		end
	end
	return false
end

--[[
	Hàm tải dữ liệu người chơi từ DataStore lên RAM Cache
]]
local function onPlayerAdded(player)
	local userId = player.UserId
	local playerKey = "Player_" .. userId
	
	-- Tạo leaderstats để hiển thị tiền lên góc phải màn hình game Roblox mặc định
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	local coinsValue = Instance.new("IntValue")
	coinsValue.Name = "Coins"
	coinsValue.Value = 0
	coinsValue.Parent = leaderstats

	-- Gọi DataStore bằng pcall vì đây là API call qua internet có thể thất bại
	local success, savedData = pcall(function()
		return PlayerDataStore:GetAsync(playerKey)
	end)
	
	if success and savedData then
		-- Đã tìm thấy dữ liệu cũ, nạp vào RAM
		sessionData[userId] = {
			Coins = savedData.Coins or DEFAULT_DATA.Coins,
			Inventory = savedData.Inventory or { unpack(DEFAULT_DATA.Inventory) },
			EquippedPet = savedData.EquippedPet -- Có thể nil nếu không trang bị gì
		}
		print("Tải dữ liệu thành công cho: " .. player.Name)
	else
		-- Người chơi mới hoặc gặp lỗi tải, gán dữ liệu mặc định
		sessionData[userId] = {
			Coins = DEFAULT_DATA.Coins,
			Inventory = { unpack(DEFAULT_DATA.Inventory) },
			EquippedPet = DEFAULT_DATA.EquippedPet
		}
		warn("Người chơi mới hoặc lỗi tải dữ liệu. Sử dụng dữ liệu mặc định cho: " .. player.Name)
	end
	
	-- Cập nhật giá trị hiển thị trên bảng Leaderboard
	coinsValue.Value = sessionData[userId].Coins
end

--[[
	Hàm lưu dữ liệu từ RAM Cache xuống DataStore
]]
local function savePlayerData(player)
	local userId = player.UserId
	local data = sessionData[userId]
	
	if data then
		local playerKey = "Player_" .. userId
		
		-- Sử dụng UpdateAsync vì nó an toàn hơn SetAsync trong việc tránh xung đột ghi đè
		local success, err = pcall(function()
			PlayerDataStore:UpdateAsync(playerKey, function(oldValue)
				-- Trả về dữ liệu hiện tại để ghi đè lên cloud
				return data
			end)
		end)
		
		if success then
			print("Đã lưu dữ liệu thành công cho: " .. player.Name)
		else
			warn("Lỗi lưu dữ liệu cho: " .. player.Name .. " - Lỗi: " .. tostring(err))
		end
	end
end

-- Đăng ký các sự kiện kết nối người chơi
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player)
	-- Giải phóng bộ nhớ RAM cache khi người chơi thoát
	sessionData[player.UserId] = nil
end)

--[[
	CRITICAL: Xử lý game:BindToClose() để tránh mất dữ liệu.
	Khi chạy test trong Studio hoặc server đột ngột sập, Roblox sẽ tắt ngay lập tức.
	Hàm này đảm bảo server sẽ đứng đợi cho đến khi lưu xong toàn bộ người chơi.
]]
game:BindToClose(function()
	print("Game đang đóng! Đang lưu dữ liệu cho tất cả người chơi còn lại...")
	for _, player in ipairs(Players:GetPlayers()) do
		savePlayerData(player)
	end
	-- Đợi thêm 1s để chắc chắn các request mạng hoàn thành
	task.wait(1)
end)
