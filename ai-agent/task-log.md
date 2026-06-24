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
