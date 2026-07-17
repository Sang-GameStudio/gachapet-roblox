# spec-ui-html-templates

Thư mục này chứa hệ thống thiết kế và các thành phần giao diện đặc tả (System Spec UI System), phục vụ cho việc tạo tài liệu kỹ thuật, sơ đồ hệ thống và mô tả API một cách đồng nhất và chuyên nghiệp.

## Các tệp tin chính

- **[index.html](file:///D:/Projects/zalogram/docs/spec-design-system/index.html)**: Trang tài liệu mẫu và đặc tả hệ thống thiết kế. Tệp này đóng vai trò giới thiệu trực quan, chứa hướng dẫn thiết lập layout, các thành phần UI cơ bản (typography, card, table) và các thành phần nâng cao phục vụ cho việc biểu diễn API/hệ thống (badge HTTP method, nhãn trạng thái, callout, code block, sơ đồ Mermaid). Đồng thời tệp chứa thẻ `<template id="ai-ruleset">` đóng vai trò là tập hợp quy tắc định hướng cho AI khi tự động tạo mã nguồn HTML theo đúng tiêu chuẩn thiết kế này.
- **[styles.css](file:///D:/Projects/zalogram/docs/spec-design-system/styles.css)**: Định nghĩa toàn bộ design tokens (màu sắc, kiểu chữ, khoảng cách), các hiệu ứng nền gradient, lưới trang trí và phong cách hiển thị cho tất cả các thành phần UI được định nghĩa trong [index.html](file:///D:/Projects/zalogram/docs/spec-design-system/index.html).

## Cách sử dụng

1. **Xem trực tiếp**: Mở trực tiếp [index.html](file:///D:/Projects/zalogram/docs/spec-design-system/index.html) bằng trình duyệt web để xem hướng dẫn trực quan và danh mục các component.
2. **Tuân thủ AI Ruleset**: Khi sử dụng AI để tạo mã nguồn HTML mới, hãy cung cấp nội dung trong thẻ `#ai-ruleset` của [index.html](file:///D:/Projects/zalogram/docs/spec-design-system/index.html#L22-L56) làm quy định bắt buộc đối với AI để đảm bảo tính đồng bộ về giao diện và cấu trúc đặc tả.
