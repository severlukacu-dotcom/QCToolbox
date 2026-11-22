import Foundation

enum ResourceType: String, Codable {
    case module
    case config
}

struct ResourceItem: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var detail: String
    var url: String
    var type: ResourceType
    var symbol: String
    var tag: String
}

enum ResourceStore {
    private static let key = "qc-toolbox-custom-v1"

    static let modules: [ResourceItem] = [
        item("adblock", "Chặn quảng cáo chung", "Chặn domain quảng cáo và tracker phổ biến. Chỉ gồm luật REJECT.", "https://raw.githubusercontent.com/akiralereal/shadowrocket-toolkit/main/dist/adblock.module", .module, "shield.fill", "Quảng cáo"),
        item("apps-ad", "Chặn quảng cáo ứng dụng", "Luật chặn quảng cáo mở màn hình và banner trong một số ứng dụng.", "https://raw.githubusercontent.com/uxudjs/Shadowrocket/refs/heads/main/modules/fuck_apps_ad_sr.sgmodule", .module, "eye.slash.fill", "Quảng cáo"),
        item("xiaoqi", "XiaoQi Adblock", "Module chặn quảng cáo tổng hợp, có danh sách trắng để giảm chặn nhầm.", "https://raw.githubusercontent.com/SherryBX/XiaoQi-sgmodule/main/xiaoqi.sgmodule", .module, "eye.slash.fill", "Quảng cáo"),
        item("reject", "Reject Rules", "Tập luật REJECT lớn cho quảng cáo và tracker.", "https://raw.githubusercontent.com/GMOogway/shadowrocket-rules/master/sr_reject_list.module", .module, "xmark.shield.fill", "Tracker"),
        item("apple", "Apple chặn theo dõi", "Chặn một số domain phân tích và quảng cáo của hệ thống Apple.", "https://raw.githubusercontent.com/uxudjs/Shadowrocket/refs/heads/main/modules/apple_block_sr.sgmodule", .module, "apple.logo", "Riêng tư"),
        item("nodns", "No DNS Leak", "DoH cho tên trực tiếp, fallback qua proxy, và phản hồi STUN giả.", "https://raw.githubusercontent.com/FelixTensor/shadowrocket-config/main/modules/core/NoDNSLeak.sgmodule", .module, "network", "DNS")
    ]

    static let configs: [ResourceItem] = [
        item("across", "Across — xuất cảnh", "Nội địa đi trực tiếp, phần còn lại đi proxy. Bạn tự thêm node trong Shadowrocket.", "https://raw.githubusercontent.com/uxudjs/Shadowrocket/refs/heads/main/Across_GFW.conf", .config, "globe.asia.australia.fill", "Quy tắc"),
        item("back", "Back — hồi quốc", "Media chỉ định đi proxy, còn lại trực tiếp. Không kèm máy chủ hay mật khẩu.", "https://raw.githubusercontent.com/uxudjs/Shadowrocket/refs/heads/main/Back_CN.conf", .config, "flag.fill", "Quy tắc"),
        item("simple", "Config ví dụ", "Khung cấu hình cơ bản để thay bằng quy tắc và node của bạn.", "https://raw.githubusercontent.com/dlisin/shadowrocket-config/master/shadowrocket.conf", .config, "doc.text.fill", "Mẫu")
    ]

    static func loadCustom() -> [ResourceItem] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([ResourceItem].self, from: data)) ?? []
    }

    static func saveCustom(_ items: [ResourceItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func scheme(for item: ResourceItem) -> URL? {
        let trimmed = item.url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parsed = URL(string: trimmed), parsed.scheme?.lowercased() == "https" else { return nil }
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        guard let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: allowed) else { return nil }
        let raw = item.type == .module
            ? "shadowrocket://install?module=\(encoded)"
            : "shadowrocket://config/add/\(encoded)"
        return URL(string: raw)
    }

    private static func item(
        _ id: String,
        _ name: String,
        _ detail: String,
        _ url: String,
        _ type: ResourceType,
        _ symbol: String,
        _ tag: String
    ) -> ResourceItem {
        ResourceItem(id: id, name: name, detail: detail, url: url, type: type, symbol: symbol, tag: tag)
    }
}
