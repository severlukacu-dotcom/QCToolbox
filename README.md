# QC Modules

Ứng dụng iOS (SwiftUI) chứa danh sách **Modules** và **Configs** cho Shadowrocket.  
Cho phép mở trực tiếp Module hoặc Config sang ứng dụng Shadowrocket thông qua URL Scheme.

## Tính năng
- Danh sách Modules phổ biến (YouTube, TikTok, Adblock, Spotify...).
- Danh sách Configs (Across GFW, Back CN...).
- Nhập URL tùy chỉnh để mở Module hoặc Config.
- Một chạm mở sang Shadowrocket bằng:
  - Module: `shadowrocket://install?module=<URL>`
  - Config: `shadowrocket://config/add/<URL>`

## Cấu trúc
```text
QCModules/
├── .github/workflows/build-ipa.yml
├── QCModules.xcodeproj/project.pbxproj
├── QCModules/
│   ├── App/QCModulesApp.swift
│   ├── Models/ResourceItem.swift
│   ├── Views/ContentView.swift
│   └── Info.plist
└── README.md
```

## Build IPA bằng GitHub Actions

1. Tạo repository mới trên GitHub.
2. Upload toàn bộ nội dung thư mục này lên repository (giữ nguyên đường dẫn `.github/workflows/build-ipa.yml`).
3. Mở tab **Actions**.
4. Chọn **Build QC Modules IPA**.
5. Nhấn **Run workflow** (hoặc push lên nhánh `main`).
6. Khi workflow thành công, tải artifact **QC-Modules-unsigned-IPA**.

### Quan trọng về chữ ký
Workflow tạo **IPA chưa ký (unsigned)**. IPA này không thể cài trực tiếp lên iPhone.  
Bạn cần ký ứng dụng bằng chứng chỉ + provisioning profile hợp lệ (Development / Ad Hoc / Enterprise) hoặc dùng công cụ sideload phù hợp.

**Không** đưa certificate, private key, provisioning profile hoặc mật khẩu vào mã nguồn/repository công khai.

## Build bằng Xcode trên Mac
Mở `QCModules.xcodeproj`, chọn target `QCModules`, cấu hình Team và Bundle Identifier `com.quocchien.qcmodules`, sau đó Archive và Distribute.

## Tùy chỉnh
- Thêm/sửa Modules & Configs: chỉnh file `QCModules/Models/ResourceItem.swift`.
- Bundle ID / Display Name: sửa trong `Info.plist` và `project.pbxproj`.
- Minimum iOS: 15.0.
