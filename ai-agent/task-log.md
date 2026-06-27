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
  - Thiết lập RAM cache `sessionData` trên Server, lưu vết Coins, Inventory và EquippedPet cho từng người chơi (gán mặc định là Pet `Common1` thay vì `Common_Dog`).
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


