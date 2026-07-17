--[[
	DataManager.server.luau
	Quản lý dữ liệu người chơi (Coins, Inventory, EquippedPet) bằng DataStoreService.
	Sử dụng cơ chế Session Caching trên RAM Server để tối ưu hiệu năng và chống exploit.
]]

local DataStoreService = game:GetService("DataStoreService")

local playerDataStore
local datastoreSuccess, datastoreErr = pcall(function()
	playerDataStore = DataStoreService:GetDataStore("PlayerSaveData_v2")
end)
if not datastoreSuccess then
	warn("⚠️ [DataManager] Không thể kết nối DataStore (Game chưa được Publish hoặc chưa bật API): " .. tostring(datastoreErr))
end

local Players = game:GetService("Players")

-- Cấu hình mặc định cho người chơi mới (Đã tăng mặc định Coins lên 100,000 để phục vụ test Gacha)
local DEFAULT_DATA = {
	Coins = 100000,
	Inventory = { "Common1" },
	EquippedPet = "Common1",
	RarePityCount = 0,       -- Số lần hụt Rare tích lũy
	LegendaryPityCount = 0   -- Số lần hụt Legendary tích lũy
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
	Hàm tăng đếm Pity (số lần hụt) cho từng loại độ hiếm
]]
function shared.DataManager.IncrementPity(player, rarityType)
	local data = sessionData[player.UserId]
	if data then
		if rarityType == "Rare" then
			data.RarePityCount = (data.RarePityCount or 0) + 1
		elseif rarityType == "Legendary" then
			data.LegendaryPityCount = (data.LegendaryPityCount or 0) + 1
		end
	end
end

--[[
	Hàm reset đếm Pity về 0 khi người chơi trúng được Pet tương ứng
]]
function shared.DataManager.ResetPity(player, rarityType)
	local data = sessionData[player.UserId]
	if data then
		if rarityType == "Rare" then
			data.RarePityCount = 0
		elseif rarityType == "Legendary" then
			data.LegendaryPityCount = 0
		end
	end
end

--[[
	Hàm cộng hoặc trừ tiền (Coins) của người chơi an toàn trên Server
]]
function shared.DataManager.AddCoins(player, amount)
	local data = sessionData[player.UserId]
	if data then
		data.Coins = math.max(0, data.Coins + amount) -- so sánh 2 số a,b trả về số lớn hơn
		
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
			data.EquippedPet = petName -- thao tác tháo pet, không chọn/trang bị pet nữa
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
	local leaderstats = Instance.new("Folder") -- hàm có sẵn trong Roblox để khởi tọa 1 đói tượng folder
	leaderstats.Name = "leaderstats" -- bắt buộc khai báo tên như này, để kích hoạt tính năng tự vẽ bảng điểm của Roblox
	leaderstats.Parent = player -- gắn folder này vào player
	
	local coinsValue = Instance.new("IntValue") -- khởi tạo 1 đối tượng intvalue để lưu số tiền 
	coinsValue.Name = "Coins" -- đặt tên hiển thị cho cột coin trên bảng là "Coins"
	coinsValue.Value = 0 -- giá trị ban đầu
	coinsValue.Parent = leaderstats -- gắn coinsValue vào leaderstats

	-- Gọi DataStore bằng pcall vì đây là API call qua internet có thể thất bại
	local success, savedData = pcall(function()
		return playerDataStore:GetAsync(playerKey)
	end)
	
	if success and savedData then
		-- Đã tìm thấy dữ liệu cũ, nạp vào RAM
		sessionData[userId] = {
			Coins = tonumber(savedData.Coins) or DEFAULT_DATA.Coins,
			Inventory = savedData.Inventory or { unpack(DEFAULT_DATA.Inventory) }, -- unpack: sao chép ra 1 mảng độc lập, tránh việc người chơi mới dùng chung và chỉnh sửa đè lên mảng gốc
			EquippedPet = savedData.EquippedPet, -- Có thể nil nếu không trang bị gì
			RarePityCount = savedData.RarePityCount or DEFAULT_DATA.RarePityCount,
			LegendaryPityCount = savedData.LegendaryPityCount or DEFAULT_DATA.LegendaryPityCount
		}
		print("Tải dữ liệu thành công cho: " .. player.Name)
	else
		-- Người chơi mới hoặc gặp lỗi tải, gán dữ liệu mặc định
		sessionData[userId] = {
			Coins = DEFAULT_DATA.Coins,
			Inventory = { unpack(DEFAULT_DATA.Inventory) },
			EquippedPet = DEFAULT_DATA.EquippedPet,
			RarePityCount = DEFAULT_DATA.RarePityCount,
			LegendaryPityCount = DEFAULT_DATA.LegendaryPityCount
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
	local data = sessionData[userId] -- lấy data của player ra
	
	if data then
		local playerKey = "Player_" .. userId
		
		-- Sử dụng UpdateAsync vì nó an toàn hơn SetAsync trong việc tránh xung đột ghi đè
		local success, err = pcall(function()
			playerDataStore:UpdateAsync(playerKey, function(oldValue) -- dữ liệu cũ trên cloud mà updateAsync gọi đến, chuẩn bị ghi đè
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
Players.PlayerAdded:Connect(onPlayerAdded) -- khi có player mới vào game thì load data lên: onPlayerAdded
Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player) -- khi player thoát ra thì lưu dữ liệu vào data store
	sessionData[player.UserId] = nil -- Giải phóng bộ nhớ RAM cache khi người chơi thoát
end)

--[[
	CRITICAL: Xử lý game:BindToClose() để tránh mất dữ liệu.
	Hàm tự động kích hoạt khi server bị sập đột ngột, hoặc khi bấm nút "Stop" trong Roblox Studio.
	Hàm này đảm bảo server sẽ đứng đợi cho đến khi lưu xong toàn bộ người chơi.
]]
game:BindToClose(function()
	print("Game đang đóng! Đang lưu dữ liệu cho tất cả người chơi còn lại...")
	for _, player in ipairs(Players:GetPlayers()) do -- duyệt qua tất cả player đang online 
		savePlayerData(player) -- lưu data của từng người chơi 
	end
	task.wait(1) -- Đợi thêm 1s để chắc chắn các request mạng hoàn thành, lệnh lưu chạy bất đồng bộ, nếu không đợi, server sẽ tắt ngay  khiến các request đang bay bị hủy --> mất data
end)

local AUTOSAVE_INTERVAL = 300 -- 5 phút tự động quét 1 lần (300 giây)
local DELAY_BETWEEN_PLAYERS = 2 -- Nghỉ 2 giây giữa mỗi người chơi để triệt tiêu Rate Limit

--[[
	Hàm chạy ngầm tự động lưu dữ liệu rải rác (Staggered Autosave)
	Giúp phân bổ đều tải DataStore ra dòng thời gian, chống Rate Limit
]]
	
local function startAutosaveLoop()
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL) -- Chờ đúng 5 phút rồi mới kích hoạt đợt lưu mới
			
			local activePlayers = Players:GetPlayers() -- lấy tất cả player đang onl trong server tại đúng khoảnh khắc đó, ném vào biến activePlayers
			
			for _, player in ipairs(activePlayers) do
				-- Kiểm tra phòng hờ người chơi đã thoát trong lúc đang đợi hàng đợi
				if player and player.Parent == Players then
					-- Chỉ tiến hành lưu nếu dữ liệu của họ đã được nạp thành công vào RAM Cache trước đó
					if shared.DataManager.IsLoaded(player) then
						-- Sử dụng task.spawn để việc lưu của Player này hoàn toàn bất đồng bộ, không bắt Player sau phải đợi
						task.spawn(function()
							savePlayerData(player)
						end)
					end
				end
				
				--  BÍ QUYẾT CỐT LÕI: Nghỉ 2 giây trước khi tiến hành lưu người chơi tiếp theo
				task.wait(DELAY_BETWEEN_PLAYERS)
			end
		end
	end)
end

-- Kích hoạt cỗ máy Autosave chạy ngầm
startAutosaveLoop()
