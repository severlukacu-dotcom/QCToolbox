# Domain Blocker

Ứng dụng chặn domain thật bằng Network Extension (Packet Tunnel).

## Tính năng
- Bật / tắt chặn kiểu VPN
- Chặn domain mặc định (Find My / iCloud)
- Thêm / xóa domain tùy chọn
- Network Extension Packet Tunnel

## Yêu cầu
- Apple Developer Program (trả phí)
- Entitlement **Network Extension** + **App Groups**
- Ký app bằng chứng chỉ cá nhân (GitHub Actions hiện build unsigned)

## Cách dùng
1. Ký app và extension bằng Xcode + chứng chỉ của bạn
2. Cài lên máy
3. Mở app → **Bật chặn** → cho phép cài VPN
4. Domain trong danh sách sẽ bị chặn

## Build IPA
Vào **Actions** → **Build QC Modules IPA** → **Run workflow**  
(Bản unsigned có thể không kích hoạt được extension. Nên ký local.)
