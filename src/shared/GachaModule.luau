local GachaModule = {}

--[[
	Cấu hình các loại Pet thực tế theo cấu hình Assets trong ReplicatedStorage.
	Common: Common1 -> Common5 (Tổng tỷ lệ = 80%, mỗi con có trọng số 16)
	Rare: Rate1 -> Rate3 (Tổng tỷ lệ = 15%, mỗi con có trọng số 5)
	Legendary: Legendary1 (Tổng tỷ lệ = 5%)
]]
GachaModule.PET_POOL = {
	-- Nhóm Common (Thường) - Tổng 80%
	{ Name = "Common1", Rarity = "Common", Weight = 16 },
	{ Name = "Common2", Rarity = "Common", Weight = 16 },
	{ Name = "Common3", Rarity = "Common", Weight = 16 },
	{ Name = "Common4", Rarity = "Common", Weight = 16 },
	{ Name = "Common5", Rarity = "Common", Weight = 16 },
	
	-- Nhóm Rare (Hiếm - Folder Rate trong Assets) - Tổng 15%
	{ Name = "Rare1",   Rarity = "Rare",   Weight = 5 },
	{ Name = "Rare2",   Rarity = "Rare",   Weight = 5 },
	{ Name = "Rare3",   Rarity = "Rare",   Weight = 5 },
	
	-- Nhóm Legendary (Huyền thoại) - Tổng 5%
	{ Name = "Legendary1", Rarity = "Legendary", Weight = 5 }
}

-- Tính tổng trọng số một lần để tối ưu hóa hiệu năng
local totalWeight = 0
for _, pet in ipairs(GachaModule.PET_POOL) do
	totalWeight = totalWeight + pet.Weight
end

--[[
	Hàm thực hiện quay gacha ngẫu nhiên có trọng số (Weighted Random)
	Trả về table thông tin của Pet trúng thưởng
]]
function GachaModule.RollPet()
	-- Sinh một số ngẫu nhiên từ 1 đến tổng trọng số (100)
	local rolledValue = math.random(1, totalWeight)
	local currentSum = 0
	
	-- Duyệt qua danh sách để tìm xem số ngẫu nhiên rơi vào khoảng nào
	for _, pet in ipairs(GachaModule.PET_POOL) do
		currentSum = currentSum + pet.Weight
		if rolledValue <= currentSum then
			return pet -- Trả về thông tin Pet trúng tuyển
		end
	end
	
	-- Phòng hờ trường hợp lỗi ngoài ý muốn, trả về Pet mặc định
	return GachaModule.PET_POOL[1]
end

--[[
	Hàm lấy danh sách cấu hình tỷ lệ (dùng để hiển thị UI Shop ở Client)
]]
function GachaModule.GetChances()
	return GachaModule.PET_POOL
end

return GachaModule
