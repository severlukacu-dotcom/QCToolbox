# Domain Blocker

Quản lý và tạo rule chặn domain.

## Tính năng
- Công tắc **Bật/Tắt** tổng
- Bật/tắt từng domain
- Thêm / xóa domain
- Xuất rule **Shadowrocket** (`DOMAIN-SUFFIX,domain,REJECT`)

## Cách chặn thật
1. Mở app → bật công tắc
2. Nhấn **Xem rule chặn** → Copy
3. Mở **Shadowrocket** → Config → Rules → dán vào
4. Bật proxy

## Lưu ý
App iOS thông thường không thể chặn domain toàn hệ thống. Dùng rule với Shadowrocket để chặn thật.

## Build IPA
Actions → Build QC Modules IPA → Run workflow
