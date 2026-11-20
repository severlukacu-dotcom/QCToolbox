# QC Video

Ứng dụng xem video kiểu YouTube.

## Tính năng hiện tại (Local)
- Feed video + tìm kiếm + lọc danh mục
- Đăng ký / Đăng nhập (lưu trên máy)
- Tải video từ **Thư viện Ảnh** hoặc Files
- Tab **Của tôi**
- Trình phát video

## Deploy Backend lên Render

1. Vào [render.com](https://render.com) → đăng nhập
2. **New** → **Web Service**
3. Kết nối repo `QCToolbox`
4. Cài đặt:
   - **Root Directory**: `backend`
   - **Build Command**: `npm install`
   - **Start Command**: `node server.js`
5. Thêm Environment Variable:
   - Key: `MONGO_URI`
   - Value: `mongodb+srv://quocchienn:chien207@cluster0.0swxhya.mongodb.net/?appName=Cluster0`
6. Nhấn **Create Web Service**

Sau khi deploy xong, Render sẽ cho URL dạng `https://qc-video-backend.onrender.com`.

### Lưu ý
- Free tier Render sẽ ngủ sau 15 phút không dùng (lần đầu gọi API hơi chậm).
- Video upload lưu trên đĩa Render (free tier có giới hạn).

## Build IPA
Vào **Actions** → **Build QC Modules IPA** → **Run workflow**
