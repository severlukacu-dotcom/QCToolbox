import Foundation

enum ToolItem: String, CaseIterable, Identifiable {
    case device = "Thông tin thiết bị"
    case uuid = "Tạo UUID"
    case base64 = "Base64"
    case qr = "Tạo mã QR"
    case notes = "Ghi chú"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .device: return "iphone"
        case .uuid: return "number"
        case .base64: return "lock.shield"
        case .qr: return "qrcode"
        case .notes: return "note.text"
        }
    }

    var subtitle: String {
        switch self {
        case .device: return "Thông tin iPhone và hệ điều hành"
        case .uuid: return "Tạo mã định danh ngẫu nhiên"
        case .base64: return "Mã hóa và giải mã văn bản"
        case .qr: return "Tạo mã QR từ nội dung"
        case .notes: return "Lưu ghi chú trên thiết bị"
        }
    }
}
