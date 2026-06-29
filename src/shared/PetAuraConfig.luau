--[[
	PetAuraConfig.luau
	Cấu hình ID hiệu ứng bệ hào quang (Aura) tương ứng cho từng loại Pet.
	Hỗ trợ người chơi dễ dàng thay đổi ID hình ảnh decal vòng xoay trong Roblox Studio.
]]

local PetAuraConfig = {}

-- Cơ sở dữ liệu cấu hình Aura độc bản cho từng con Pet
PetAuraConfig.Pets = {
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

return PetAuraConfig
