# QC Toolbox

Ứng dụng tiện ích iOS viết bằng SwiftUI, hỗ trợ iOS 15 trở lên.

## Tính năng
- Thông tin thiết bị và phiên bản iOS.
- Tạo UUID ngẫu nhiên.
- Mã hóa / giải mã Base64.
- Tạo mã QR và chia sẻ.
- Ghi chú lưu cục bộ bằng `AppStorage`.

## Cấu trúc
```text
QCToolbox/
├── .github/workflows/build-ipa.yml
├── QCToolbox.xcodeproj/project.pbxproj
├── QCToolbox/
│   ├── App/QCToolboxApp.swift
│   ├── Models/ToolItem.swift
│   ├── Services/DeviceInfo.swift
│   ├── Views/
│   │   ├── ContentView.swift
│   │   ├── DeviceInfoView.swift
│   │   ├── UUIDView.swift
│   │   ├── Base64View.swift
│   │   ├── QRView.swift
│   │   └── NotesView.swift
│   └── Info.plist
└── README.md
```

## Build IPA bằng GitHub Actions

1. Tạo repository mới trên GitHub.
2. Upload toàn bộ nội dung thư mục này lên repository (giữ nguyên đường dẫn `.github/workflows/build-ipa.yml`).
3. Mở tab **Actions**.
4. Chọn **Build QC Toolbox IPA**.
5. Nhấn **Run workflow** (hoặc push lên nhánh `main`).
6. Khi workflow thành công, mở lần chạy đó và tải artifact **QC-Toolbox-unsigned-IPA**.

### Quan trọng về chữ ký
Workflow mặc định tạo **IPA chưa ký (unsigned)** để bạn kiểm tra cấu trúc/build. IPA này không thể cài trực tiếp lên iPhone bằng cách sideload thông thường. Để cài đặt, cần ký ứng dụng bằng chứng chỉ và provisioning profile hợp lệ (Apple Development / Ad Hoc / Enterprise) hoặc dùng quy trình ký phù hợp với công cụ sideload của bạn.

Không đưa certificate, private key, provisioning profile hoặc mật khẩu vào mã nguồn/repository công khai. Nếu muốn, có thể bổ sung workflow ký IPA bằng GitHub Secrets.

## Build bằng Xcode trên Mac
Mở `QCToolbox.xcodeproj`, chọn target `QCToolbox`, cấu hình Team và Bundle Identifier `com.quocchien.qctoolbox`, sau đó chọn **Any iOS Device (arm64)** → **Product → Archive** → **Distribute App**.

## Tùy chỉnh
- Bundle ID: sửa `PRODUCT_BUNDLE_IDENTIFIER` trong project.
- Tên hiển thị: sửa `CFBundleDisplayName` trong `QCToolbox/Info.plist`.
- Minimum iOS: sửa `IPHONEOS_DEPLOYMENT_TARGET` trong project.
