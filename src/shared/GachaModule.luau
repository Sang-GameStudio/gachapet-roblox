--[[
	GachaModule.luau
	Thuật toán bốc thăm ngẫu nhiên có trọng số (Weighted Random) kết hợp hệ thống bảo hiểm (Pity).
	Hỗ trợ:
	- Bảo hiểm cứng (Hard Pity): Trúng 100% Rare sau 8 lần trượt, 100% Legendary sau 15 lần trượt.
	- Bảo hiểm mềm (Soft Pity): Tăng dần tỷ lệ trúng từ mốc 5 lần trượt (Rare) và 10 lần trượt (Legendary).
]]

local GachaModule = {}

-- Bảng mapping danh sách tên Pet tương ứng trong Assets để sinh ngẫu nhiên
local PET_POOL = {
	Common = {"Common1", "Common2", "Common3", "Common4", "Common5"},
	Rare = {"Rare1", "Rare2", "Rare3"},
	Legendary = {"Legendary1"}
}

-- Cấu hình pool Pet gốc để tương thích ngược nếu cần
GachaModule.PET_POOL = {
	{ Name = "Common1", Rarity = "Common", Weight = 16 },
	{ Name = "Common2", Rarity = "Common", Weight = 16 },
	{ Name = "Common3", Rarity = "Common", Weight = 16 },
	{ Name = "Common4", Rarity = "Common", Weight = 16 },
	{ Name = "Common5", Rarity = "Common", Weight = 16 },
	{ Name = "Rare1",   Rarity = "Rare",   Weight = 5 },
	{ Name = "Rare2",   Rarity = "Rare",   Weight = 5 },
	{ Name = "Rare3",   Rarity = "Rare",   Weight = 5 },
	{ Name = "Legendary1", Rarity = "Legendary", Weight = 5 }
}

--[[
	Hàm thực hiện quay gacha dựa theo Pity của người chơi trên Server
]]
function GachaModule.RollPet(player)
	local playerData = shared.DataManager.GetData(player)
	if not playerData then 
		return { Name = "Common1", Rarity = "Common" } 
	end

	local rareCount = playerData.RarePityCount or 0
	local legCount = playerData.LegendaryPityCount or 0
	local chosenRarity = "Common"

	-- 1. ĐIỀU KIỆN BẢO HIỂM CỨNG (HARD PITY) - NGẮT MẠCH SỚM
	if legCount >= 15 then
		chosenRarity = "Legendary"
	elseif rareCount >= 8 then
		chosenRarity = "Rare"
	else
		-- 2. ĐIỀU KIỆN BẢO HIỂM MỀM ĐỘNG (SOFT PITY)
		local commonWeight = 80
		local rareWeight = 15
		local legWeight = 5

		-- Kiểm tra mốc 10 hụt của Legendary -> Tăng tỷ lệ Legendary lên 25% (Common giảm 20%)
		if legCount >= 10 then
			legWeight = 25
			commonWeight = commonWeight - 20
		end

		-- Kiểm tra mốc 5 hụt của Rare -> Tăng tỷ lệ Rare lên 35% (Common giảm 20%)
		if rareCount >= 5 then
			rareWeight = 35
			commonWeight = commonWeight - 20
		end

		-- Thuật toán bốc thăm theo trọng số (Tổng luôn chuẩn 100%)
		local roll = math.random(1, 100)
		if roll <= legWeight then
			chosenRarity = "Legendary"
		elseif roll <= (legWeight + rareWeight) then
			chosenRarity = "Rare"
		else
			chosenRarity = "Common"
		end
	end

	-- 3. QUY TẮC RESET ĐỘC LẬP & TĂNG BỘ ĐẾM KHI HỤT
	if chosenRarity == "Legendary" then
		shared.DataManager.ResetPity(player, "Legendary")
		shared.DataManager.IncrementPity(player, "Rare") -- Lượt này ra Leg nghĩa là vẫn trượt Rare
	elseif chosenRarity == "Rare" then
		shared.DataManager.ResetPity(player, "Rare")
		shared.DataManager.IncrementPity(player, "Legendary") -- Lượt này ra Rare nghĩa là vẫn trượt Leg
	else
		-- Ra Common thì tăng cả 2 bộ đếm tích lũy
		shared.DataManager.IncrementPity(player, "Rare")
		shared.DataManager.IncrementPity(player, "Legendary")
	end

	-- Lấy ngẫu nhiên một con pet thuộc nhóm độ hiếm đã chọn
	local pool = PET_POOL[chosenRarity]
	local selectedPetName = pool[math.random(1, #pool)]

	return { Name = selectedPetName, Rarity = chosenRarity }
end

--[[
	Hàm lấy danh sách cấu hình tỷ lệ (dùng để hiển thị UI Shop ở Client)
]]
function GachaModule.GetChances()
	return GachaModule.PET_POOL
end

return GachaModule
