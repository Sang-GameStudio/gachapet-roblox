# 📝 Nhật Ký Thực Hiện Dự Án (Roblox Game Test)

File này ghi nhận tất cả các công việc, công nghệ áp dụng và kiến thức đã thực hiện trong quá trình xây dựng dự án game. Đây là tài liệu giúp bạn hiểu tổng quan về toàn bộ hệ thống dự án của mình.

---

## 📅 Nhật Ký Chi Tiết

### 🛠️ Task 1: Khởi Tạo Dự Án & Thiết Lập Quy Tắc Cho AI Agent
* **Ngày thực hiện:** 24/06/2026

#### 1. Công việc đã thực hiện:
- **Cập nhật kế hoạch [plan.md](file:///../doc/plan.md):** 
  - Bổ sung cơ chế `game:BindToClose()` ở Server để chống mất dữ liệu khi test trong Roblox Studio.
  - Bổ sung Dictionary `lastPurchaseTime` dạng `[UserId] = tick()` cho Server-side Debounce để rate-limit từng người chơi riêng biệt.
  - Bổ sung tối ưu vật lý `SetNetworkOwner(player)` cho con Pet khi di chuyển bám đuôi người chơi.
- **Tạo Workspace Rules [roblox_project_rules.md](file:///.agents/rules/roblox_project_rules.md):**
  - Giúp Antigravity IDE tự động nhận diện ngữ cảnh dự án là game Roblox và ngôn ngữ Luau.
  - Cấu hình chỉ đường dẫn để AI tự động tìm đọc folder `ai-agent` nhằm tiết kiệm token và chạy nhanh hơn.
  - Áp dụng quy tắc bắt buộc AI phải ghi nhật ký vào `task-log.md` sau khi hoàn thành bất kỳ task nào.
- **Tái cấu trúc folder `project/ai-agent`:**
  - Xóa toàn bộ tệp tin dự án Monolith/Microservices Spring Boot cũ không liên quan.
  - Tạo cấu trúc thư mục Roblox tiêu chuẩn bao gồm: `core/`, `context/`, `skills/`.
  - Thiết lập [system.prompt.md](file:///ai-agent/core/system.prompt.md) để định hướng vai trò Roblox Developer.
  - Thiết lập quy tắc lập trình và đặt tên Luau tại [naming.md](file:///ai-agent/core/rules/naming.md), [coding.md](file:///ai-agent/core/rules/coding.md) và [performance.md](file:///ai-agent/core/rules/performance.md).
  - Soạn thảo 4 cẩm nang kỹ năng lập trình Roblox cốt lõi cho game test:
    - [datastore.md](file:///ai-agent/skills/datastore.md) (Lưu trữ và Cache dữ liệu người chơi).
    - [follow_pet.md](file:///ai-agent/skills/follow_pet.md) (Pet di chuyển theo bằng Physics Constraints).
    - [gacha_logic.md](file:///ai-agent/skills/gacha_logic.md) (Thuật toán Weighted Random).
    - [viewport_rendering.md](file:///ai-agent/skills/viewport_rendering.md) (Hiển thị Pet 3D trên UI 2D).

#### 2. Công nghệ áp dụng:
- **Công cụ**: Rojo, Git.
- **Ngôn ngữ**: Luau (Lua Roblox).
- **Roblox Services**: DataStoreService, Players, ReplicatedStorage, ServerScriptService, RunService.

#### 3. Kiến thức áp dụng:
- **Server-Authoritative Network Design**: Mô hình máy chủ làm chủ để chống hacker can thiệp UI hoặc can thiệp coin/gacha.
- **Physics Constraint Objects (`AlignPosition`, `AlignOrientation`)**: Giải pháp di chuyển mượt mà, tự động né va chạm thông qua engine vật lý C++ tích hợp của Roblox.
- **Weighted Random Algorithm (Thuật toán xác suất có trọng số)**: Cơ chế tính toán tỷ lệ mở trứng gacha Common 80% / Rare 15% / Legendary 5% bằng cách tính tổng trọng số và nội suy khoảng.
- **Session Caching & BindToClose**: Kỹ thuật lưu trữ tạm thời data người chơi trên RAM server để giảm tải request lên cloud DataStore, đồng thời lưu đè an toàn khi tắt server đột ngột.

---

### 🔒 Task 2: Hiện Thực Hóa Backend & DataStore (Logic Server & Data Persistence)
* **Ngày thực hiện:** 24/06/2026

#### 1. Công việc đã thực hiện:
- **Xây dựng module xác suất [GachaModule.luau](file:///project/src/shared/GachaModule.luau):**
  - Khai báo pool Pet khớp 100% với cấu trúc Assets trong ReplicatedStorage của người chơi (Common: `Common1` -> `Common5` với trọng số 16; Rare: `Rate1` -> `Rate3` với trọng số 5; Legendary: `Legendary1` với trọng số 5).
  - Implement thuật toán Weighted Random trong `GachaModule.RollPet()` để tính toán pet trúng giải dựa trên tổng trọng số.
- **Xây dựng trình quản lý dữ liệu [DataManager.server.luau](file:///project/src/server/DataManager.server.luau):**
  - Kết nối và thao tác với Roblox `DataStoreService` để lưu/tải dữ liệu bằng `UpdateAsync` & `GetAsync` có bọc `pcall`.
  - Thiết lập RAM cache `sessionData` trên Server, lưu vết Coins, Inventory và EquippedPet cho từng người chơi (gán mặc định là Pet `Common1` thay vì `Common_Dog`, mặc định Coins lúc khởi tạo tăng từ `100` lên `100,000` coins phục vụ kiểm thử gacha, đồng thời nâng cấp key lưu trữ thành `PlayerSaveData_v2` để kích hoạt reset).
  - Tạo `leaderstats` và IntValue `Coins` để tự động hiển thị số xu của player lên Leaderboard UI mặc định của Roblox Studio.
  - Đăng ký `game:BindToClose()` để lưu lại toàn bộ dữ liệu người chơi đang online khi Server tắt hoặc khi ngắt chế độ chơi thử.
- **Xây dựng logic bám đuôi và gacha tại [GameLogic.server.luau](file:///project/src/server/GameLogic.server.luau):**
  - Kết nối và đăng ký lắng nghe các RemoteEvents/RemoteFunctions (`OpenEggEvent`, `EquipPetEvent`, `GetInventory`).
  - Xử lý mua trứng an toàn: Server tự động kiểm tra xu của người chơi trên Server RAM (không tin cậy Client), trừ tiền an toàn, thực hiện quay gacha thông qua `GachaModule.RollPet()`, lưu pet mới vào inventory, và trả kết quả về cho Client chạy hiệu ứng.
  - Tích hợp Dictionary debounce `lastPurchaseTime[userId]` trên Server để chặn spam RemoteEvent từ hacker (cooldown 0.8s).
  - Viết logic trang bị Pet: Xác minh quyền sở hữu Pet, tự động định tuyến đường dẫn tìm kiếm model động trong `ReplicatedStorage.Assets.Pets.[Common/Rate/Legendary]` để tìm chính xác Pet, clone ra Workspace, cấu hình physics constraints bám đuôi (`AlignPosition` & `AlignOrientation`) có gia tốc mượt mà, tắt va chạm và set `SetNetworkOwner` về máy Client để khử lag.
  - Tự động spawn lại Pet đang trang bị khi người chơi hồi sinh (`CharacterAdded`).

#### 2. Công nghệ áp dụng:
- **Công cụ**: Rojo, Roblox Studio.
- **Roblox API**: DataStoreService, Players, ReplicatedStorage, Workspace, RunService, Physics Constraints (`AlignPosition`, `AlignOrientation`, `Attachment`).
- **Network Boundaries**: RemoteEvent (`OpenEggEvent`, `EquipPetEvent`), RemoteFunction (`GetInventory`).

#### 3. Kiến thức áp dụng:
- **Physics Constraint-based Follower**: Dịch chuyển mô hình vật lý dựa trên Attachments giúp Pet đi theo người chơi có quán tính rất đẹp mắt và tối ưu hiệu năng C++.
- **Client-Side Physics Ownership (Network Owner)**: Chuyển quyền xử lý vật lý của Pet sang Client giúp giảm tải server và triệt tiêu độ trễ mạng, tạo ra chuyển động cực kỳ mượt mà.
- **Secure Remote Validation**: Nguyên tắc an toàn hệ thống game, không tin tưởng Client, thực hiện kiểm tra số dư, trừ tiền, và cooldown hoàn toàn ở phía Server.

---

### 🎨 Task 3: Hiện Thực Hóa Frontend (UI & Client-Server Network)
* **Ngày thực hiện:** 26/06/2026

#### 1. Công việc đã thực hiện:
- **Xây dựng trình điều khiển giao diện [UIController.client.luau](file:///project/src/client/UIController.client.luau):**
  - **Quản lý đóng/mở Frame**: Đồng bộ nút bấm `HUD.ShopBtn`, `HUD.InvBtn` cùng các nút đóng `BtnCloseInventory` và `BtnCloseShop` để toggle ẩn/hiển thị các bảng điều khiển tương ứng. Sử dụng `TweenService` phóng to/thu nhỏ UI mượt mà dựa trên kích thước gốc cấu hình trong Studio để tăng trải nghiệm người dùng (UX/Game Feel). Tích hợp thêm các hiệu ứng phản hồi vi mô (micro-interactions) cho cả 2 nút đóng như Hover (di chuột vào mờ nhẹ `235, 235, 235`), Press (click xuống tối hẳn `170, 170, 170`), Release (thả chuột ra trả về màu Hover) chỉ đổi màu ảnh `ImageColor3` mà không đổi Scale để tạo cảm giác cơ học chân thực.
  - **Tải và Hiển thị Inventory (Đồng bộ nâng cao)**:
    - Sửa lại đường dẫn `PetSlotTemplate` trỏ đúng vào thư mục `ReplicatedStorage.Templates.PetSlotTemplate`.
    - Gọi RemoteFunction `GetInventory` để lấy thông tin Coins, Inventory danh sách Pet và Pet đang trang bị từ Server.
    - **Tối ưu hóa tái sử dụng ô vật phẩm**: Thay vì xóa toàn bộ và vẽ lại gây reset góc quay camera của ViewportFrame, hệ thống tự động giữ lại và tái sử dụng các ô cũ, chỉ vẽ mới nếu là ô mới tạo hoặc thay đổi loài Pet.
    - Viết logic tìm kiếm vị trí model chính xác thông qua hàm quét đệ quy thư mục `ReplicatedStorage.Assets.Pets.[Common/Rate/Legendary]`.
    - Sử dụng **ViewportFrame (`PetView`)** và Camera ảo để render Pet 3D lên ô UI 2D. Tích hợp thuật toán lượng giác xoay Camera 360 độ quanh tâm Bounding Box của Pet với tốc độ `120 độ/giây` giúp Pet quay nhanh và mượt mà hơn trên mọi màn hình. Giải phóng sự kiện (disconnect) khi ô vật phẩm bị hủy để tránh rò rỉ bộ nhớ.
  - **Logic nút trang bị (EquipBtn)**:
    - Kiểm tra xem Pet hiển thị có trùng khớp với `EquippedPet` không.
    - Tự động hiển thị viền sáng (`Border.Enabled = true`) và thẻ đánh dấu (`EquippedTag.Visible = true`) cho Pet đang được trang bị, ẩn viền sáng/thẻ đánh dấu đối với các Pet khác để giao diện trực quan.
    - Bấm nút để trang bị (hoặc tháo trang bị nếu đang được trang bị), gửi RemoteEvent lên Server và tự động refresh lại kho hàng ngay lập tức.
    - **Dọn dẹp kết nối (Event listener recycling)**: Tận dụng cơ chế lưu trữ connection vào Dictionary và disconnect sự kiện cũ trước khi kết nối sự kiện bấm nút mới để ngăn chặn rò rỉ bộ nhớ khi tái sử dụng các ô UI.
  - **Logic mua trứng & hiển thị cửa hàng (ShopFrame)**:
    - Khi mở `ShopFrame`, hệ thống tự động lấy mô hình trứng tĩnh từ `ReplicatedStorage.Assets.Egg` và render 3D tĩnh vào ViewportFrame `EggView`.
    - Camera được đặt cố định ở góc nghiêng phía trước (trục Z) và chếch lên trên (trục Y) hướng thẳng vào tâm quả trứng mà không chạy vòng lặp xoay tròn, tạo bố cục cân đối và chuyên nghiệp.
    - Bấm nút `BuyEggBtn` trong ShopFrame sẽ bắn tín hiệu `OpenEggEvent:FireServer("BasicEgg")`.
    - Lắng nghe `OpenEggEvent.OnClientEvent` để nhận thông tin pet mới mở được, hiển thị thông báo ra log và tự động refresh lại hòm đồ và Coins HUD.

#### 2. Công nghệ áp dụng:
- **Roblox UI Elements**: ScreenGui, Frame, ScrollingFrame, ViewportFrame, TextButton, TextLabel, UIAspectRatioConstraint, UIGridLayout.
- **Client APIs**: TweenService, RunService.RenderStepped, Camera, Instance.new, GetBoundingBox, PivotTo.
- **Network Boundaries**: RemoteEvent (`OpenEggEvent`, `EquipPetEvent`), RemoteFunction (`GetInventory`).

#### 3. Kiến thức áp dụng:
- **3D-in-2D Viewport Rendering**: Kỹ thuật chiếu mô hình 3D lên giao diện phẳng bằng ViewportFrame, tự động tính toán tiêu cự và khoảng cách camera dựa trên Bounding Box của mô hình để hiển thị Pet cân đối trong khung hình.
- **Tween UI Animation**: Sử dụng EasingStyle (như `Back.Out`) giúp giao diện chuyển động sinh động, tạo phản hồi thao tác tốt (Game Feel).
- **Client Memory Leak Prevention**: Nguyên tắc lập trình Roblox, tự động dọn dẹp các sự kiện lặp khung hình (`RenderStepped`) khi các Instance UI cha tương ứng bị phá hủy.

---

### ✨ Task 4: Hiện Thực Hóa Hiệu Ứng Gacha & Tách Biệt Mô-đun (VFX/SFX Cutscene & Code Refactoring)
* **Ngày thực hiện:** 28/06/2026

#### 1. Công việc đã thực hiện:
- **Tách riêng mô-đun cắt cảnh [CutsceneController.luau](file:///project/src/client/CutsceneController.luau):**
  - Xây dựng mô-đun dịch vụ dưới dạng **ModuleScript** giúp mã nguồn tinh gọn, dễ quản lý và bảo trì.
  - Tích hợp hàm `CutsceneController.Play()` xử lý toàn bộ vòng đời của cắt cảnh mở trứng 3D.
- **Hiện thực hóa Timeline Cắt cảnh (Gacha Cutscene Lifecycle):**
  - **Khởi tạo & Cô lập không gian**: Chuyển Camera sang `Scriptable`, khóa camera cố định trên một tọa độ ảo trên bầu trời (`Vector3.new(0, 200, 0)`) để cách ly hoàn toàn với thế giới mặt đất, tránh vướng víu cảnh vật. Tự động ẩn cả hai UI Shop và Inventory để người chơi tập trung.
  - **Giai đoạn Rung lắc (Buildup Phase)**: Nhân bản mô hình Trứng động (hỗ trợ cả tìm từ `ReplicatedStorage.Assets.Egg` và fallback ở `workspace`). Áp dụng ma trận Rotation gốc (`eggTemplate.CFrame.Rotation`) để trứng đứng thẳng chuẩn chỉnh, không bị lộn ngược đầu. Sử dụng thuật toán lượng giác lắc xoay trục Z ở tần số cao (`45 rad/s`, góc `12 độ`) trong `1.5 giây` tạo cảm giác rung lắc dữ dội trước khi nở.
  - **Giai đoạn Phát nổ & Đắp nền tia sáng (Pop Phase)**: Xóa bỏ trứng, định tuyến trực tiếp đến hiệu ứng vương giả. **Thiết kế Modular & Hỗ trợ Đa Rarity VFX**: Sử dụng mô-đun [VFXManager.luau](file:///d:/Study/Unity/VNG/project/src/client/VFXManager.luau). Khi trứng vỡ, `VFXManager` tự động tìm nạp hiệu ứng hạt theo độ hiếm của Pet: độ hiếm `Legendary` sẽ kích hoạt vòng tròn ma pháp thánh khiết hoàng kim **`K - HOLINESS`**, độ hiếm `Rare` sẽ kích hoạt vòng tròn ma pháp hoàng kim **`B - TREASURE`**, các độ hiếm khác sử dụng ngôi sao lấp lánh `E - GLOW`. Logic cấu hình hạt được tách biệt độc lập cho cả 3 độ hiếm (Common, Rare, Legendary) để tùy biến chỉ số mặc định riêng biệt (như độ lớn Size, tốc độ phát hạt Rate, số hạt mồi Emit) phù hợp hoàn hảo với đặc tính của từng gói VFX trong Workspace.
  - **Giai đoạn Tiết lộ Pet & Tạo cao trào kịch tính (Reveal Phase)**: Ép hiệu ứng hạt của `K - HOLINESS`, `B - TREASURE` hoặc `E - GLOW` chạy đơn lẻ trước trong **`0.5 giây`** để tạo cao trào kịch tính. Sau đó mới clone Pet đặt tại tâm cắt cảnh, chạy Tween búng đàn hồi `Back.Out` trong `0.5s` để chú Pet xuất hiện lung linh nổi bật trước phông nền lấp lánh ngoài không gian bầu trời nguyên bản sáng đẹp tự nhiên của map. Hệ thống hoàn tất quá trình kiểm thử và đã được trả lại cấu hình tỷ lệ ngẫu nhiên có trọng số (Weighted Random) chuẩn xác ban đầu.
  - **Cơ chế tương tác Click/Tap để tiếp tục**: Thay vì tự đóng sau 3 giây, hệ thống chuyển sang chế độ **chờ tương tác vô tận**. Sử dụng `UserInputService` để lắng nghe thao tác Click chuột (PC) hoặc Chạm màn hình (Mobile/Tablet). Chú Pet sẽ liên tục xoay tròn Idle thư thái quanh trục Y (`os.clock() * 2.2`) cho đến khi người chơi click/tap màn hình để xác nhận. Sau đó, ngắt kết nối sự kiện (disconnect) tránh rò rỉ bộ nhớ, dọn dẹp các vật thể ảo, phục hồi camera ban đầu về nhân vật chính, tự động kích hoạt hiển thị Cửa hàng (`ShopFrame.Visible = true`) và gọi `refreshInventoryUI()`.
- **Tích hợp hiệu ứng âm thanh SFX (SFX Integration):**
  - Viết hàm `playSFX()` tự động tìm kiếm các file âm thanh `EggShake` và `Explosion` trong `ReplicatedStorage.Assets.SFXs`, clone vào `SoundService` và tự hủy sau khi phát xong để tối ưu hiệu năng.

#### 2. Công nghệ áp dụng:
- **Roblox Services**: SoundService, TweenService, ReplicatedStorage, Workspace, Players.
- **Luau Language**: ModuleScript, Object-Oriented/Modular Programming, `require`.
- **Cơ chế mô phỏng**: Camera Scripting (`Enum.CameraType.Scriptable`), Lượng giác lắc trứng (`math.sin`), Particle Emitter Activation, Garbage Collection (task.delay).

#### 3. Kiến thức áp dụng:
- **Modular Code Architecture**: Tách biệt logic UI và logic Cutscene qua ModuleScript giúp giảm kích thước file LocalScript chính (`UIController`), tránh mã nguồn spaghetti.
- **3D Space Isolation (Skybox Stage)**: Dựng sân khấu ảo trên không trung tách biệt hoàn toàn để chạy các cảnh quay đặc biệt mà không lo bị vật thể khác che mắt hoặc ảnh hưởng hiệu suất render của game chính.
- **Dynamic Asset Fallback**: Cơ chế kiểm tra dự phòng (Egg/Explosion) giúp game chạy mượt mà ngay cả khi môi trường Assets có sự thay đổi vị trí lưu trữ giữa Workspace và ReplicatedStorage.

---

### Cập nhật bổ sung (28/06/2026)
- **Đồng bộ tên nút bấm HUD**: Cập nhật tệp [UIController.client.luau](file:///d:/Study/Unity/VNG/project/src/client/UIController.client.luau) để sử dụng chính xác các tên nút bấm mới tại `MainGui.HUD`:
  - `ShopBtn` -> `BtnShop`
  - `InvBtn` -> `BtnInventory`
  - `CoinsLabel` -> `LabelCoins`
  - Việc này giúp tránh lỗi kịch bản khi người dùng cập nhật lại giao diện người dùng trên Roblox Studio.
- **Tinh chỉnh giao diện Coins & Hiệu ứng HUD**:
  - Gỡ bỏ hoàn toàn tiền tố `"Coins: "` của `LabelCoins.Text` tại tất cả các điểm cập nhật dữ liệu để chỉ hiển thị thuần túy số lượng xu, đồng thời tích hợp thêm định dạng dấu phẩy hàng nghìn (ví dụ: `79,400` thay vì `79400`) giúp cải thiện tính dễ đọc của số dư lớn.
  - Tích hợp thêm hiệu ứng lún cơ học chuyên nghiệp cho hai nút `BtnInventory` và `BtnShop` khi người dùng di chuột (`MouseEnter`/`MouseLeave`) và bấm giữ chuột trái/chạm màn hình (`MouseButton1Down`/`MouseButton1Up`) tương tự như các nút đóng menu.
- **Lọc trùng lặp Pet trên UI Inventory**:
  - Cập nhật hàm `refreshInventoryUI()` để thực hiện lọc trùng lặp danh sách Pet sở hữu thông qua Hash-Map. Mỗi loại Pet duy nhất chỉ xuất hiện một ô đại diện duy nhất trên ScrollingFrame để tối ưu hóa không gian trưng bày, trong khi các ô Viewport ảo 3D cũ và các liên kết sự kiện tương tác vẫn được duy trì mượt mà không bị tải lại hoặc rò rỉ bộ nhớ.
- **Cơ chế đứng yên hướng mặt về phía trước cho Pet trong Kho đồ**:
  - **Trong kho đồ Inventory**: Loại bỏ hoàn toàn vòng lặp `RenderStepped` xoay camera ảo 360 độ trong [UIController.client.luau](file:///d:/Study/Unity/VNG/project/src/client/UIController.client.luau). Thiết lập góc đặt camera trực diện mặt trước (`-radius` trên trục Z) tĩnh một lần duy nhất, giải phóng tài nguyên xử lý và giúp các chú Pet quay mặt chính diện hướng ra ngoài màn hình.
  - **Trong cắt cảnh Gacha**: Khôi phục lại kịch bản xoay tròn thời gian thực của Pet trong [CutsceneController.luau](file:///d:/Study/Unity/VNG/project/src/client/CutsceneController.luau) (`spinAngle` dựa trên `os.clock() * 2.2`) theo đúng yêu cầu để tăng tính sinh động khi mở trứng.
- **Tích hợp hệ thống âm thanh SFX & BGM**:
  - **Nhạc nền BGM (Background)**: Tự động kích hoạt nhân bản và phát nhạc nền `Background` sang `SoundService` ngay khi khởi chạy game (lần đầu tải UI trong [UIController.client.luau](file:///d:/Study/Unity/VNG/project/src/client/UIController.client.luau)), bảo đảm nhạc phát xuyên suốt và lặp lại liên tục tự động.
  - **Nhạc lắc trứng (Egg)**: Nhân bản và phát nhạc `Egg` ở dạng lặp (`Looped = true`) trong suốt Giai đoạn 1 (rung lắc). Ngay khi chuyển sang Giai đoạn 2 (phát nổ), hệ thống lập tức ngắt (`Stop`) và giải phóng bộ nhớ (`Destroy`) âm thanh này một cách dứt điểm.
  - **Âm thanh chúc mừng theo độ hiếm**: Phát âm thanh một lần (`Looped = false`) khi Pet xuất hiện tương thích hoàn toàn với tên độ hiếm (`Common`, `Rare`, `Legendary`) để tạo điểm nhấn âm thanh, tự động xóa bản sao sau khi phát xong. Cập nhật đồng bộ theo tên tệp âm thanh `"Rare"` mới bạn đã sửa đổi trong Roblox Studio.
- **Sửa lỗi so sánh kiểu dữ liệu khi mua trứng (Gacha)**:
  - **Khắc phục lỗi logic so sánh kiểu dữ liệu**: Sửa lỗi `attempt to compare number <= string` xuất hiện ở server khi người chơi nhấn nút Gacha. Lỗi này do dữ liệu Coins lưu từ DataStore phiên bản cũ được lưu dưới dạng chuỗi (string) thay vì số (number).
  - **Chuẩn hóa dữ liệu khi Load**: Cập nhật tệp [DataManager.server.luau](file:///d:/Study/Unity/VNG/project/src/server/DataManager.server.luau) để ép kiểu `tonumber(savedData.Coins)` khi tải thông tin từ DataStore.
  - **Gia cố bảo vệ so sánh trên Server**: Cập nhật tệp [GameLogic.server.luau](file:///d:/Study/Unity/VNG/project/src/server/GameLogic.server.luau) để đảm bảo chuyển đổi `tonumber(playerData.Coins)` trước khi so sánh với giá trứng `EGG_PRICE`.
- **Cập nhật Bảng Tỷ Lệ Gacha Shop & Click SFX**:
  - **Khởi tạo bảng tỷ lệ Gacha**: Đồng bộ tỷ lệ mở trứng lên 3 TextLabel (`CommonText`, `RareText`, `LegendaryText`) nằm trong `RatePanel` của `ShopFrame` tại client (Common: 80%, Rare: 15%, Legendary: 5%). Việc này giúp ghi đè các giá trị placeholder thiết kế thô trong Roblox Studio một cách linh hoạt.
  - **Tích hợp âm thanh tương tác click (Click SFX)**: Thêm hàm bổ trợ `playClickSFX` để tự động phát tệp âm thanh `Click` từ `SFXs` khi người chơi nhấp chọn các nút trên HUD (BtnShop, BtnInventory), các nút đóng panel (BtnCloseShop, BtnCloseInventory), nút mua trứng (BuyEggBtn) và nút trang bị Pet (EquipBtn), nâng cao đáng kể cảm giác phản hồi giao diện.
- **Tích hợp hiệu ứng Hào quang dưới chân Pet (Aura)**:
  - **Tạo Module Cấu hình**: Tạo tệp tin [PetAuraConfig.luau](file:///d:/Study/Unity/VNG/project/src/shared/PetAuraConfig.luau) chứa danh sách toàn bộ 9 chú Pet và ID ảnh decal hào quang tương ứng của chúng (người chơi đã cung cấp ID cho tất cả các loại Pet bao gồm cả Common).
  - **Hàm khởi tạo sinh bệ xoay Aura**: Thêm hàm `applyCustomAuraToPet` vào [GameLogic.server.luau](file:///d:/Study/Unity/VNG/project/src/server/GameLogic.server.luau) để tự động sinh bệ xoay bám theo chân Pet. Sử dụng khớp nối **`Weld`** cổ điển (`AuraAnimateWeld`) thay thế cho `WeldConstraint`, đặt chiều cao lệch `AURA_HEIGHT_OFFSET = -4.4` để hào quang bám sát chạm đất 100%. Đảm bảo gán `Anchored = false` và `CanCollide = false` cho bệ hào quang để tránh kẹt chuyển động hoặc khóa chết nhân vật/Pet không di chuyển được.
  - **Tối ưu hóa hiệu năng vòng lặp xoay Aura**: Khai báo sự kiện `RunService.Heartbeat` ở server để quay khớp nối `C0` với vận tốc **60 độ/giây**. Bằng việc chỉ nhân xoay khớp `C0` của `Weld`, **chỉ có bệ hào quang xoay tròn** dưới đất, trong khi chú Pet vẫn hướng mặt về phía trước và di chuyển/bám đuôi người chơi mượt mà theo đúng cơ chế vật lý.
- **Khắc phục lỗi mất hiển thị nền Pet Slot theo độ hiếm**:
  - **Lưu cấu hình PetConfig trên ổ đĩa**: Tạo thư mục cấu hình `src/shared/PetConfig` và các tệp văn bản `CommonBG.txt`, `RareBG.txt`, `LegendaryBG.txt` chứa ID ảnh nền tương ứng. Việc này ngăn chặn Rojo tự động xóa thư mục cấu hình khi đồng bộ hóa từ ổ đĩa sang Roblox Studio.
  - **Phục hồi và Tối ưu hóa tải ảnh nền**: Cập nhật hàm cập nhật giao diện trong [UIController.client.luau](file:///d:/Study/Unity/VNG/project/src/client/UIController.client.luau) để sử dụng `WaitForChild("PetConfig", 2)` giúp ngăn chặn tình trạng bất đồng bộ/chậm tải khi game khởi chạy.
- **Tích hợp Vòng lặp Autosave Rải Rác (Staggered Autosave Loop)**:
  - **Thiết lập chu kỳ lưu ngầm định kỳ**: Bổ sung hàm `startAutosaveLoop` chạy ngầm ở cuối tệp [DataManager.server.luau](file:///d:/Study/Unity/VNG/project/src/server/DataManager.server.luau) để tự động quét và lưu dữ liệu người chơi định kỳ mỗi **5 phút** (`AUTOSAVE_INTERVAL = 300` giây).
  - **Triệt tiêu Rate Limit qua cơ chế rải tải**: Sử dụng nghỉ luồng tĩnh `task.wait(2)` giữa các lượt lưu của từng người chơi để chia đều lưu lượng ghi xuống Roblox DataStore Cloud, đảm bảo tính bền vững và an toàn 100% cho Server.
  - **Gọi lưu bất đồng bộ**: Sử dụng `task.spawn` để thực thi lưu bất đồng bộ `savePlayerData(player)` của từng người chơi mà không gây block hàng đợi của người chơi tiếp theo.

