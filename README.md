# QC Video

Ứng dụng xem video kiểu YouTube.

## Tính năng hiện tại (Local)
- Feed video + tìm kiếm + lọc danh mục
- Đăng ký / Đăng nhập (lưu trên máy)
- **Tải video từ Thư viện Ảnh** hoặc Files
- Tab **Của tôi** xem video đã tải
- Trình phát video

## Backend MongoDB (tùy chọn)
Thư mục `backend/` chứa server Node.js + Express kết nối MongoDB.

### Chạy backend
```bash
cd backend
npm install
MONGO_URI="mongodb+srv://..." node server.js
```

**Lưu ý**: Đừng nhúng connection string vào app iOS. Dùng backend làm trung gian.

## Build IPA
Vào **Actions** → **Build QC Modules IPA** → **Run workflow**
