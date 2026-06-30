--[[
	PetConfig.luau
	Cấu hình hợp nhất dữ liệu Pet (Độ hiếm, Trọng số sắp xếp, Khung hình Slot và Bệ hào quang Aura).
	Đóng vai trò Single Source of Truth hướng dữ liệu (Data-Driven) cho toàn dự án.
]]

local PetConfig = {}

-- 1. Trọng số sắp xếp độ hiếm của Pet (Dùng để sắp xếp trong Inventory)
PetConfig.RARITY_WEIGHTS = {
	Common = 1,
	Rare = 2,
	Legendary = 3
}

-- 2. Cấu hình ảnh nền khung slot trong Inventory theo độ hiếm
PetConfig.RARITY_BG = {
	Common = "rbxassetid://71068865248976",
	Rare = "rbxassetid://124461782966661",
	Legendary = "rbxassetid://138928603128591"
}

-- 3. Cơ sở dữ liệu chi tiết cho từng loại Pet (độ hiếm, aura rbxassetid)
PetConfig.Pets = {
	["Common1"] = {
		Rarity = "Common",
		AuraId = "rbxassetid://72572375521823"
	},
	["Common2"] = {
		Rarity = "Common",
		AuraId = "rbxassetid://131349455084583"
	},
	["Common3"] = {
		Rarity = "Common",
		AuraId = "rbxassetid://102569767411589"
	},
	["Common4"] = {
		Rarity = "Common",
		AuraId = "rbxassetid://70561920681639"
	},
	["Common5"] = {
		Rarity = "Common",
		AuraId = "rbxassetid://88589526596502"
	},
	["Rare1"] = {
		Rarity = "Rare",
		AuraId = "rbxassetid://80256630540184"
	},
	["Rare2"] = {
		Rarity = "Rare",
		AuraId = "rbxassetid://93910204707943"
	},
	["Rare3"] = {
		Rarity = "Rare",
		AuraId = "rbxassetid://140733127937409"
	},
	["Legendary1"] = {
		Rarity = "Legendary",
		AuraId = "rbxassetid://130276993224611"
	}
}

--[[
	Hàm xác định độ hiếm dựa theo cấu hình của tên Pet
	Ví dụ: "Common1" -> "Common"
]]
function PetConfig.GetRarity(petName: string): string
	local petData = PetConfig.Pets[petName]
	if petData then
		return petData.Rarity
	end
	
	-- Fallback nếu có pet mới chưa kịp định nghĩa trong config
	if string.find(petName, "Common") then
		return "Common"
	elseif string.find(petName, "Rare") then
		return "Rare"
	elseif string.find(petName, "Legendary") then
		return "Legendary"
	end
	return "Common" -- Mặc định phòng hờ
end

return PetConfig
