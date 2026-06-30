--[[
	CutsceneController.luau
	Quản lý và thực hiện hiệu ứng cắt cảnh 3D ngoài Workspace khi mở trứng Gacha.
	(Đã nâng cấp: Tích hợp hệ thống âm thanh SFX, quản lý lặp nhạc nền Background và nhạc lắc trứng Egg, phát âm thanh chúc mừng theo độ hiếm)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

-- Require mô-đun quản lý hạt
local VFXManager = require(script.Parent:WaitForChild("VFXManager"))

local CutsceneController = {}

-- HÀM PHÁT SFX NGẮN (One-shot SFX): Tự động tìm kiếm, nhân bản và tự giải phóng bộ nhớ khi phát xong
local function playSFX(soundName)
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local sfxFolder = assets and assets:FindFirstChild("SFXs")
	if not sfxFolder then return end
	
	local sound = sfxFolder:FindFirstChild(soundName)
	
	if sound and sound:IsA("Sound") then
		local soundClone = sound:Clone()
		soundClone.Parent = SoundService
		soundClone.Looped = false -- Đảm bảo âm thanh chúc mừng chỉ nổ một lần duy nhất
		soundClone:Play()
		-- Dọn dẹp bản sao sfx sau khi phát xong để tránh rác bộ nhớ Explorer
		task.delay(soundClone.TimeLength + 0.5, function()
			soundClone:Destroy()
		end)
	end
end

-- Định vị và di chuyển mô hình/part an toàn (tương thích cả Model và BasePart)
local function setInstanceCFrame(instance, udimCFrame)
	if instance:IsA("BasePart") then
		instance.CFrame = udimCFrame
	elseif instance:IsA("Model") then
		instance:PivotTo(udimCFrame)
	end
end

-- Tìm mô hình Pet gốc động trong Assets -> Pets -> [Common/Rare/Legendary]
local function findPetModel(petName)
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local petsFolder = assets and assets:FindFirstChild("Pets")
	if petsFolder then
		for _, rarityFolder in ipairs(petsFolder:GetChildren()) do
			local model = rarityFolder:FindFirstChild(petName)
			if model then
				return model
			end
		end
	end
	return nil
end

--[[
	Hàm chạy cắt cảnh mở trứng 3D
]]
function CutsceneController.Play(petName, rarity, shopFrame, inventoryFrame, refreshInventoryUI)
	local camera = workspace.CurrentCamera
	local originalCameraCFrame = camera.CFrame
	local originalCameraType = camera.CameraType
	
	-- Mảng lưu trữ quản lý các asset ảo ngoài không gian sky
	local activeVFXs = {}
	
	-- 1. ĐẢM BẢO BACKGROUND BGM HOẠT ĐỘNG:
	-- Đảm bảo bản nhạc nền Background được clone sang SoundService để phát nghe thấy được
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local sfxFolder = assets and assets:FindFirstChild("SFXs")
	local soundServiceBGM = SoundService:FindFirstChild("Background")
	if not soundServiceBGM and sfxFolder then
		local originalBGM = sfxFolder:FindFirstChild("Background")
		if originalBGM and originalBGM:IsA("Sound") then
			soundServiceBGM = originalBGM:Clone()
			soundServiceBGM.Parent = SoundService
		end
	end
	if soundServiceBGM and not soundServiceBGM.IsPlaying then
		soundServiceBGM:Play()
	end
	
	-- 2. CÔ LẬP KHÔNG GIAN: Đặt tọa độ ảo trên bầu trời
	local cutscenePos = Vector3.new(0, 200, 0)
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.new(cutscenePos + Vector3.new(0, 3, 8), cutscenePos + Vector3.new(0, 1.5, 0))
	
	if shopFrame then shopFrame.Visible = false end
	if inventoryFrame then inventoryFrame.Visible = false end
	
	-- 3. KHỞI TẠO TRỨNG
	local eggTemplate = (ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Egg")) or workspace:FindFirstChild("Egg")
	if not eggTemplate then
		if shopFrame then shopFrame.Visible = true end
		camera.CameraType = originalCameraType
		return
	end
	
	local eggClone = eggTemplate:Clone()
	eggClone.Parent = workspace
	local eggRotation = eggTemplate:IsA("Model") and eggTemplate:GetPivot().Rotation or eggTemplate.CFrame.Rotation
	setInstanceCFrame(eggClone, CFrame.new(cutscenePos + Vector3.new(0, 1.5, 0)) * eggRotation)
	
	-- 4. GIAI ĐOẠN 1: KHỞI CHẠY VÒNG LẶP ÂM THANH RUNG TRỨNG
	local activeEggSound = nil
	local eggSoundTemplate = sfxFolder and sfxFolder:FindFirstChild("Egg")
	if eggSoundTemplate and eggSoundTemplate:IsA("Sound") then
		activeEggSound = eggSoundTemplate:Clone()
		activeEggSound.Parent = SoundService
		activeEggSound.Looped = true -- Ép lặp âm thanh liên tục trong quá trình lắc
		activeEggSound:Play()
	end
	
	-- Thực hiện vòng lặp lắc cơ học quả trứng
	local shakeDuration = 1.5
	local startTime = os.clock()
	while os.clock() - startTime < shakeDuration do
		local elapsed = os.clock() - startTime
		local angle = math.sin(elapsed * 45) * 12
		local targetCFrame = CFrame.new(cutscenePos + Vector3.new(0, 1.5, 0)) * eggRotation * CFrame.Angles(0, 0, math.rad(angle))
		setInstanceCFrame(eggClone, targetCFrame)
		task.wait()
	end
	
	-- 5. KẾT THÚC GIAI ĐOẠN 1: Ngắt dứt điểm âm thanh Egg trước khi nổ phá cảnh
	if activeEggSound then
		activeEggSound:Stop()
		activeEggSound:Destroy()
		activeEggSound = nil
	end
	
	-- 6. GIAI ĐOẠN 2: PHÁT NỔ & KÍCH HOẠT LUỒNG TIA SÁNG RỰC RỠ
	eggClone:Destroy()
	
	local glowTemplate = VFXManager.FindTemplate(rarity)
	if glowTemplate then
		local vfxClone = glowTemplate:Clone()
		vfxClone.Parent = workspace
		table.insert(activeVFXs, vfxClone)
		
		if vfxClone:IsA("BasePart") then vfxClone.Anchored = true end
		for _, part in ipairs(vfxClone:GetDescendants()) do
			if part:IsA("BasePart") then part.Anchored = true end
		end
		
		setInstanceCFrame(vfxClone, CFrame.new(cutscenePos + Vector3.new(0, 1.4, 0)))
		
		-- Duyệt cấu hình thông minh cho dải hạt (Tương thích hoàn hảo cho Common, Rare lẫn Legendary)
		VFXManager.SetupVFX(vfxClone, rarity)
	end
	
	-- Ép luồng hiệu ứng chạy trước độc đạo trong 0.5 giây để tích tụ cao trào thị giác!
	task.wait(0.5)
	
	-- 7. GIAI ĐOẠN 3: CHÚ PET BÚNG MẠNH RA XOAY VÒNG & PHÁT TIẾNG CHÚC MỪNG TƯƠNG ỨNG ĐỘ HIẾM
	local petTemplate = findPetModel(petName)
	if petTemplate then
		local petClone = petTemplate:Clone()
		petClone.Parent = workspace
		table.insert(activeVFXs, petClone)
		
		for _, part in ipairs(petClone:GetDescendants()) do
			if part:IsA("BasePart") then part.Anchored = true end
		end
		if petClone:IsA("BasePart") then petClone.Anchored = true end
		
		local targetCenter = cutscenePos + Vector3.new(0, 1.2, 0)
		
		-- Khởi chạy hiệu ứng Búng Đàn Hồi cho Pet
		local popValue = Instance.new("NumberValue")
		popValue.Value = 0
		local popTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		local popTween = TweenService:Create(popValue, popTweenInfo, {Value = 1})
		popTween:Play()
		
		-- ĐÚNG YÊU CẦU: Gọi tên SFX chúc mừng trùng khớp hoàn toàn với tên độ hiếm (Common/Rare/Legendary)
		playSFX(rarity)
		
		-- Lắng nghe tương tác click chuột / chạm màn hình để thoát
		local userHasClicked = false
		local inputConnection
		inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				userHasClicked = true
			end
		end)
		
		-- VÒNG LẶP IDLE XOAY TRÒN: Giữ lại hiệu ứng xoay tròn nghệ thuật sinh động khi mở trứng
		while not userHasClicked do
			local currentPop = popValue.Value
			if petClone then
				local spinAngle = os.clock() * 2.2
				local currentYOffset = (currentPop - 1) * 2
				local currentCFrame = CFrame.new(targetCenter + Vector3.new(0, currentYOffset, 0)) * CFrame.Angles(0, spinAngle, 0)
				setInstanceCFrame(petClone, currentCFrame)
			end
			task.wait()
		end
		
		if inputConnection then inputConnection:Disconnect() end
	end
	
	-- 8. DỌN DẸP SẠCH SẼ ASSET ẢO TRÊN TRỜI
	for _, instance in ipairs(activeVFXs) do
		if instance then instance:Destroy() end
	end
	
	-- 9. HOÀN NGUYÊN CAMERA VỀ LẠI GIAO DIỆN SHOP
	camera.CameraType = originalCameraType
	camera.CFrame = originalCameraCFrame
	
	if refreshInventoryUI then refreshInventoryUI() end
	if shopFrame then shopFrame.Visible = true end
end

return CutsceneController

