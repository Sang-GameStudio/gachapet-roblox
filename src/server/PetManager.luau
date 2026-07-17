--[[
	PetManager.luau
	ModuleScript quản lý vòng đời, vật lý di chuyển, và bệ hào quang (Aura) của Pet trên Server.
	Tuân thủ nguyên lý Single Responsibility Principle (SRP) và tối ưu hóa hiệu năng vật lý.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService") -- quản lý vòng lặp thời gian ( Game loop/ frame Management ) của Engine đồ họa

-- Gọi file cấu hình hợp nhất
local PetConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PetConfig"))

local PetManager = {}

-- Chiều cao dịch chuyển để hào quang chạm hẳn mặt đất (Pet cao 2 studs, nửa thân là 1 stud)
local AURA_HEIGHT_OFFSET = -4.4
local ROTATION_SPEED = 60 -- Vận tốc xoay (Độ/giây)

--[[
	Hàm dọn dẹp (destroy) Pet cũ đang đi theo người chơi trong Workspace nếu có
]]
function PetManager.DestroyExistingPet(player)
	local existingPet = workspace:FindFirstChild(player.Name .. "_Pet") -- được quy ước, cách đặt tên ở SpawnPetModel
	if existingPet then
		existingPet:Destroy()
	end
end

--[[
	Hàm tìm kiếm Model Pet trong ReplicatedStorage dựa theo tên
]]
local function findPetTemplate(petName)
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if not assets then return nil end
	
	local petsFolder = assets:FindFirstChild("Pets")
	if not petsFolder then return nil end
	
	-- Duyệt qua các folder độ hiếm (Common, Rare, Legendary)
	for _, rarityFolder in ipairs(petsFolder:GetChildren()) do
		if rarityFolder:IsA("Folder") then -- IsA: kiểm tra kiểu của object --> Kiểm tra chính các folder: Common/Rare/Legendary xem nó có đúng là kiểu Folder hay không
			local petTemplate = rarityFolder:FindFirstChild(petName)
			if petTemplate then
				return petTemplate
			end
		end
	end
	
	-- Fallback: Tìm đệ quy trong ReplicatedStorage
	return ReplicatedStorage:FindFirstChild(petName, true)
end

--[[
	Hàm sinh bệ xoay hào quang (Aura) dưới chân Pet dựa theo cấu hình
]]
local function applyCustomAuraToPet(petModel, petName)
	-- Tra cứu dữ liệu cấu hình Aura
	local petData = PetConfig.Pets[petName]
	if not petData or not petData.AuraId or petData.AuraId == "" or petData.AuraId == "rbxassetid://0" then
		return
	end
	
	-- Tìm phôi mẫu Aura một cách an toàn
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local auraFolder = assets and assets:FindFirstChild("Aura")
	local auraTemplate = auraFolder and auraFolder:FindFirstChild("Aura")
	
	if not auraTemplate then
		warn("LỖI: Không tìm thấy mẫu Aura tại Assets/Aura/Aura")
		return
	end
	
	-- Sao chép phôi mẫu Aura
	local newAura = auraTemplate:Clone() -- nhân bản 1 bệ Aura mới từ phôi mẫu
	newAura.Name = "ActivePetAura" -- đổi tên nó thành "ActivePetAura" để quản lý
	
	-- Tắt va chạm, vật lý neo, và TRIỆT TIÊU TRỌNG LƯỢNG (Massless = true) cho bệ hào quang để tránh kẹt hoặc giật vật lý
	if newAura:IsA("BasePart") then
		newAura.CanCollide = false -- tắt va chạm để player có thể đi xuyên qua được
		newAura.Anchored = false -- tắt để bệ Aura di chuyển theo pet
		newAura.Massless = true -- triệt tiêu trọng lượng = 0
	end
	for _, child in ipairs(newAura:GetDescendants()) do -- GetChildren thì lấy con ở tầng thứ 1, GetDescendant thì lấy all con cháu của aura để đảm bảo không 1 mảnh vỡ nào của Aura còn sót lại các thuộc tính va chạm/cân nặng này
		if child:IsA("BasePart") then
			child.CanCollide = false
			child.Anchored = false
			child.Massless = true
		end
	end
	
	-- Gán ID ảnh Decal an toàn
	local decal = newAura:FindFirstChildOfClass("Decal")
	if decal then
		local success = pcall(function()
			decal.Texture = petData.AuraId -- gắn decal trong phiên bản cũ
		end)
		if not success then
			pcall(function()
				decal.ColorMapContent = Content.fromUri(petData.AuraId) -- gắn decal trong phiên bản mới
			end)
		end
	end
	
	newAura.Parent = petModel
	
	-- Định vị bệ nằm ngay sát mặt đất dưới chân khối trục chính (Base) của Pet
	local rootPart = petModel.PrimaryPart or petModel:WaitForChild("Base") --Xác định khối trục chính ( khối tâm ) của Pet để làm điểm tựa
	
	-- Dùng Weld cổ điển để quay khớp C0 mà không làm xoay cả mô hình Pet
	local jointWeld = Instance.new("Weld") -- tạo 1 mối hàn vật lý cứng ( weld )
	jointWeld.Name = "AuraAnimateWeld" -- đặt tên cho aura
	jointWeld.Part0 = rootPart -- bộ phận gốc làm chủ ( thân con Pet )
	jointWeld.Part1 = newAura -- bộ phận con bị xích theo ( vòng tròn Aura )
	
	-- Thiết lập vị trí tương đối đẩy bệ xuống sát đất
	jointWeld.C0 = CFrame.new(0, AURA_HEIGHT_OFFSET, 0) -- vị trí tương đối của Part1 so với Part0 --> đẩy tọa độ khớp hàn xuống sát đất ( theo chỉ số đã thiết lập )
	jointWeld.C1 = CFrame.new(0, 0, 0) -- vị trí tương đối của Part0 so với Part1
	jointWeld.Parent = newAura
	
	-- Tắt bóng đổ mặc định của Pet để bệ hào quang làm nhiệm vụ thay thế bóng đổ nghệ thuật
	for _, child in ipairs(petModel:GetChildren()) do
		if child:IsA("BasePart") then
			child.CastShadow = false
		end
	end
end

--[[
	Hàm khởi tạo thiết lập vật lý bám đuôi (AlignPosition & AlignOrientation)
]]
local function setupPetPhysics(player, character, petModel)
	local rootPart = character:WaitForChild("HumanoidRootPart") -- lấy khối trọng tâm của Player
	local petRoot = petModel.PrimaryPart -- lấy khối trọng tâm của pet
	
	if not petRoot then
		warn("LỖI: Pet model không cấu hình PrimaryPart!")
		return
	end
	
	-- Tắt va chạm và thiết lập Massless = true cho mọi bộ phận của Pet (giữ lại PrimaryPart để ổn định vật lý)
	for _, part in ipairs(petModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.Anchored = false
			if part ~= petRoot then 
				part.Massless = true -- all bộ phận của pet ( Tai, đuôi...) đều có trọng lượng = 0
			else
				part.Massless = false -- Cần ít nhất 1 part có khối lượng trong Assembly để tránh lỗi rung lắc của Roblox Physics
			end
		end
	end

	-- Điểm neo trên người Player (lệch sang phải 2 studs, cao 1.5 studs, sau lưng 5 studs)
	-- tạo ra 2 cây đinh: player, pet để buộc dây 2 điểm này vào để kéo pet theo
	local attachmentPlayer = rootPart:FindFirstChild("PetAttachment") 
	if not attachmentPlayer then -- nếu player chưa có đinh, 
		attachmentPlayer = Instance.new("Attachment") -- dùng instance tạo ra định cho player
		attachmentPlayer.Name = "PetAttachment" -- đặt tên
		attachmentPlayer.Position = Vector3.new(2, 1.5, 5) -- đặt vị trí, sau lưng người chơi
		attachmentPlayer.Parent = rootPart -- gắn cây đinh vào HumanoiRootPart
	end
	
	-- Điểm neo trên người con Pet
	local attachmentPet = Instance.new("Attachment")
	attachmentPet.Name = "PetRootAttachment"
	attachmentPet.Parent = petRoot
	
	-- Lực hút vị trí (AlignPosition) đưa Pet bám theo điểm neo của Player
	local alignPos = Instance.new("AlignPosition")
	alignPos.Attachment0 = attachmentPet -- buộc đầu dây vào pet
	alignPos.Attachment1 = attachmentPlayer -- buộc dây còn lại vào player
	alignPos.MaxForce = 20000 -- độ khỏe của lực kéo
	alignPos.Responsiveness = 15 -- Tạo độ nhạy mượt mà ( càng cao thì bay theo càng nhanh, càng mượt )
	alignPos.Parent = petRoot
	
	-- Lực xoay hướng (AlignOrientation) giúp Pet quay mặt theo hướng Player đi
	local alignOrient = Instance.new("AlignOrientation")
	alignOrient.Attachment0 = attachmentPet
	alignOrient.Attachment1 = attachmentPlayer
	alignOrient.MaxTorque = 20000 -- lực xoay cổ
	alignOrient.Responsiveness = 15 -- độ nhạy xoay
	alignOrient.Parent = petRoot

	-- Giao quyền tính toán vật lý về cho máy Client của người chơi để triệt tiêu độ trễ mạng
	local success, err = pcall(function()
		petRoot:SetNetworkOwner(player)
	end)
	if not success then
		warn("Không thể set Network Owner: " .. tostring(err))
	end
end

--[[
	Hàm spawn mô hình Pet 3D và kích hoạt vật lý bám đuôi
]]
function PetManager.SpawnPetModel(player, character, petName)
	-- Dọn dẹp Pet cũ trước khi spawn
	PetManager.DestroyExistingPet(player)
	
	if not petName then return end

	local petTemplate = findPetTemplate(petName)
	if petTemplate then
		local petClone = petTemplate:Clone()
		petClone.Name = player.Name .. "_Pet" -- quy ước tạo tên cho pet
		petClone.Parent = workspace -- lôi nó ra workspace để hiển thị lên 
		
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			petClone:SetPrimaryPartCFrame(rootPart.CFrame * CFrame.new(2, 1.5, 5)) -- kéo PrimaryPart của pet theo rootPart của player và all khối linh kiện phụ khác ( tai, mắt, đuôi..) của pet cùng di chuyển với PrimaryPart
		end
		
		-- Cài đặt vật lý bám đuôi (đã tối ưu Massless)
		setupPetPhysics(player, character, petClone)
		
		-- Cài đặt bệ hào quang (đã tối ưu Massless)
		applyCustomAuraToPet(petClone, petName)
	else
		warn("LỖI: Không tìm thấy model Pet trong Assets/ReplicatedStorage có tên: " .. petName)
	end
end

--[[
	Khởi chạy vòng lặp xoay bệ hào quang tập trung trong RunService.Heartbeat
]]
function PetManager.Init()
	RunService.Heartbeat:Connect(function(deltaTime) -- sự kiên tự động kích hoạt sau mỗi khi Server tính toán và dựng xong 1 khung hình ( Frame ) vật lý. Nếu server chạy 60FPS , thì cái hàm ẩn danh bên trong Heartbeat sẽ được gọi 60 lầ trong vòng đúng 1s
		for _, player in ipairs(Players:GetPlayers()) do
			local petModel = workspace:FindFirstChild(player.Name .. "_Pet")
			if petModel then
				local aura = petModel:FindFirstChild("ActivePetAura")
				if aura then
					local jointWeld = aura:FindFirstChild("AuraAnimateWeld")
					if jointWeld and jointWeld:IsA("Weld") then
						jointWeld.C0 = jointWeld.C0 * CFrame.Angles(0, math.rad(ROTATION_SPEED) * deltaTime, 0)
					end
				end
			end
		end
	end)
end

return PetManager
