local PetClass = {}

PetClass.RARITY_WEIGHTS = {
	Common = 1,
	Rare = 2,
	Legendary = 3
}

--[[
	Hàm xác định độ hiếm dựa theo tên Pet
	Ví dụ: "Common1" hoặc "Common2" -> "Common"
]]
function PetClass.GetRarity(petName: string): string
	if string.find(petName, "Common") then
		return "Common"
	elseif string.find(petName, "Rare") then
		return "Rare"
	elseif string.find(petName, "Legendary") then
		return "Legendary"
	end
	return "Common" -- Mặc định phòng hờ
end

return PetClass
