# Device Info

Ứng dụng xem thông tin thiết bị iOS (chính xác trong giới hạn API công khai).

## Hiển thị
- Tên máy, model phần cứng (`hw.machine`), loại, phiên bản iOS, build OS
- CPU, số nhân, RAM vật lý, architecture
- Màn hình (point + pixel), scale, native scale, safe area
- Dung lượng tổng / còn trống / đã dùng
- Mức pin, trạng thái, Low Power Mode
- **IDFV** (Identifier for Vendor) — không phải UDID thật
- Ngôn ngữ, múi giờ, phiên bản app

### Lưu ý về UDID
iOS không cho app thông thường đọc UDID phần cứng thật. App hiển thị **IDFV** (thay đổi khi gỡ toàn bộ app cùng vendor).

Kéo xuống để làm mới.

## Build IPA
Vào **Actions** → **Build QC Modules IPA** → **Run workflow**
