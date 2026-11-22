# QC Toolbox

App mở module và config thẳng sang Shadowrocket.

## Trong app
- Tab Module: chặn quảng cáo, chặn theo dõi Apple, chống rò DNS
- Tab Config: bộ quy tắc (tự thêm node trong Shadowrocket, app không kèm máy chủ hay mật khẩu)
- Tab Của tôi: dán URL https của bạn, lưu trên máy

Nút mở dùng URL scheme:
- Module: `shadowrocket://install?module=`
- Config: `shadowrocket://config/add/`

## Đã bỏ
- Duyệt file Documents (WQ Files)
- Packet Tunnel
- Backend video

Không có module mở khóa Premium / Pro / VIP.

## Build IPA
Actions → **Build QC Toolbox IPA** → Run workflow.

Artifact `QC-Toolbox-unsigned.ipa` không ký. Tự ký bằng Apple ID của bạn (Sideloadly hoặc AltStore) rồi cài. Repo không chứa chứng chỉ ký.
