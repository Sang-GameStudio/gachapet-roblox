--[[
	VFXManager.luau
	Quản lý việc tải mẫu VFX, phóng đại kích thước hạt, khóa tần suất hạt sinh sản và mồi hạt.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VFXManager = {}

-- Hàm bổ trợ cấu trúc dải hạt NumberSequence của Roblox
local function scaleNumberSequence(sequence, multiplier)
	local keypoints = sequence.Keypoints -- 1. Trích xuất all các mốc ( keypoints ) hiện tại của dải hạt
	local newKeypoints = {} -- 2. Tạo 1 mảng rỗng để chứa mốc mới sau khi nhân tỉ lệ
	-- 3. chạy vòng lặp duyệt qua từng mốc một
	for i, kp in ipairs(keypoints) do -- khởi tạo 1 mốc mới ( kp.Time ) nhưng giá trị kích thước (kp.Value) và biên độ ngẫu nhiên (kp.Envelope) sẽ được nhân với hệ số multiplier
		table.insert(newKeypoints, NumberSequenceKeypoint.new(kp.Time, kp.Value * multiplier, kp.Envelope * multiplier))
	end
	return NumberSequence.new(newKeypoints) -- 4. Trả về dải hạt đã được nhân tỉ lệ
end

-- TỐI ƯU ĐA NHÁNH VFX: Tự động lùng asset theo độ hiếm truyền vào từ Server
function VFXManager.FindTemplate(rarity)
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local vfxs = assets and assets:FindFirstChild("VFXs")
	
	if vfxs then
		local particlePack = vfxs:FindFirstChild("PARTICLE PACK by ReiAkaris")
		local baseFolder = particlePack and particlePack:FindFirstChild("BASE")
		local miscFolder = baseFolder and baseFolder:FindFirstChild("08 - MISC")
		
		if miscFolder then
			-- Nếu trúng Legendary -> Đi thẳng tới vòng ma pháp G - CHARGE
			if rarity == "Legendary" then
				local legendaryFX = miscFolder:FindFirstChild("K - HOLINESS")
				if legendaryFX then return legendaryFX end
			end
			-- Nếu trúng Rare -> Đi thẳng tới vòng tròn ma pháp hoàng kim B - TREASURE
			if rarity == "Rare" then
				local rareFX = miscFolder:FindFirstChild("B - TREASURE")
				if rareFX then return rareFX end
			end
			-- Mặc định hoặc Common -> Dùng ngôi sao lấp lánh dịu nhẹ E - GLOW
			local defaultFX = miscFolder:FindFirstChild("E - GLOW")
			if defaultFX then return defaultFX end
		end
	end
	return nil
end

-- Duyệt cấu hình thông minh cho dải hạt (Tách biệt riêng cho Common, Rare lẫn Legendary)
function VFXManager.SetupVFX(vfxClone, rarity)
	if rarity == "Legendary" then
		--  HIỆU ỨNG LEGENDARY (G - CHARGE)
		for _, child in ipairs(vfxClone:GetDescendants()) do
			if child:IsA("ParticleEmitter") then
				if child.Name == "Main Core" or child.Name == "Core" then
					child.Enabled = false -- Khóa lõi phát sáng chói mắt
				else
					-- Tùy chỉnh thông số riêng cho Legendary (G - CHARGE)
					child.Size = scaleNumberSequence(child.Size, 2.5) -- tăng kích thước của dải hiệu ứng lên 2.5 lần
					child.Rate = 5 -- Tuần suất sinh sản hạt liên tục bằng 5 hạt/giây
					child.Enabled = true -- kích hoạt, cho bộ phát hạt hoạt động. Lúc này hệ thống bắt đầu bơm các hạt bụi ra ngoài môi trường theo nhịp độ Rate đã cài ở trên
					child:Emit(3) -- phát 3 hạt bụi ra ngoài không gian ngay lập tức, không phải đợi Rate ( 0.2 giây mới có hạt đầu tiên)
				end
			end
		end
	elseif rarity == "Rare" then
		--  HIỆU ỨNG RARE (B - TREASURE)
		for _, child in ipairs(vfxClone:GetDescendants()) do
			if child:IsA("ParticleEmitter") then
				if child.Name == "Core" or child.Name == "Glowing Core" then
					child.Enabled = false -- Khóa lõi ma pháp
				else
					-- Tùy chỉnh thông số riêng cho Rare (B - TREASURE)
					child.Size = scaleNumberSequence(child.Size, 1.3)
					child.Rate = 5 -- Giữ nhịp sinh sản hạt của B - TREASURE
					child.Enabled = true
					child:Emit(1) -- Mồi hạt lập tức ra không gian
				end
			end
		end
	else
		--  HIỆU ỨNG COMMON / MẶC ĐỊNH (E - GLOW)
		for _, child in ipairs(vfxClone:GetDescendants()) do
			if child:IsA("ParticleEmitter") then
				if child.Name == "Glowing Core" or child.Name == "Core" then
					child.Enabled = false -- Khóa lõi chói E - GLOW
				else
					-- Tùy chỉnh thông số riêng cho Common (E - GLOW)
					child.Size = scaleNumberSequence(child.Size, 2.2)
					child.Rate = 5 -- Giữ nhịp sinh sản hạt của E - GLOW
					child.Enabled = true
					child:Emit(4) -- Mồi hạt lập tức ra không gian
				end
			end
		end
	end
end

return VFXManager
