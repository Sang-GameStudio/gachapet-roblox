# 🤖 Roblox Gameplay Developer AI Agent Guidelines

Bộ hướng dẫn tổng hợp giúp AI Assistant (Antigravity IDE) và Developer xây dựng dự án game Roblox (Mở Trứng Gacha & Pet) đạt điểm tối đa dựa trên các tiêu chí chuyên nghiệp.

---

## 📋 Mục lục cấu trúc

### 🧠 Core — Prompt & Rules (Quy tắc & Định hướng)
| File | Mô tả |
|---|---|
| [`core/system.prompt.md`](core/system.prompt.md) | Định hướng vai trò Roblox Gameplay Developer cho AI |
| [`core/rules/naming.md`](core/rules/naming.md) | Quy tắc đặt tên chuẩn Luau (Scripts, Variables, Services...) |
| [`core/rules/coding.md`](core/rules/coding.md) | Hướng dẫn code an toàn (Server-Authoritative, DataStore, BindToClose...) |
| [`core/rules/performance.md`](core/rules/performance.md) | Hướng dẫn tối ưu hiệu năng (Network Owner, Tween UI, Connections...) |

### 🧩 Templates — Mẫu cấu trúc Code
| File | Mô tả |
|---|---|
| [`core/templates/feature.md`](core/templates/feature.md) | Template tạo class OOP hoặc ModuleScript mới |
| [`core/templates/bugfix.md`](core/templates/bugfix.md) | Template sửa lỗi logic client-server |

### 📖 Context — Thiết kế Kiến trúc
| File | Mô tả |
|---|---|
| [`context/architecture.md`](context/architecture.md) | Sequence diagram Client-Server & Cấu trúc Rojo |

### 🛠️ Skills — Kỹ năng lập trình Roblox chuyên biệt
| File | Mô tả |
|---|---|
| [`skills/datastore.md`](skills/datastore.md) | Thao tác DataStore an toàn, cơ chế Cache & BindToClose |
| [`skills/follow_pet.md`](skills/follow_pet.md) | Xây dựng Pet theo đuôi bằng Physics Constraints |
| [`skills/gacha_logic.md`](skills/gacha_logic.md) | Thuật toán Weighted Random mở trứng |
| [`skills/viewport_rendering.md`](skills/viewport_rendering.md) | Hiển thị Pet 3D lên ô UI 2D bằng ViewportFrame |

### 📊 Nhật ký thực hiện
| File | Mô tả |
|---|---|
| [`task-log.md`](task-log.md) | Nhật ký công việc, công nghệ và kiến thức đã áp dụng |

---

## 🚀 Cách sử dụng

Khi bắt đầu một phiên làm việc hoặc viết tính năng mới, AI Agent sẽ tự động đọc cấu hình tại `.agents/rules/roblox_project_rules.md` ở gốc workspace và tham chiếu đến các tài liệu trong folder này để đảm bảo viết mã nguồn tối ưu nhất.
