import Foundation

enum ResourceType: String {
    case module = "Module"
    case config = "Config"
}

struct ResourceItem: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let url: String
    let type: ResourceType
    let symbol: String
}

struct ResourceStore {
    static let modules: [ResourceItem] = [
        ResourceItem(
            name: "YouTube No Ads",
            description: "Loại bỏ quảng cáo YouTube, hỗ trợ PiP và phát nền",
            url: "https://gitlab.com/chienq895/module-ad-config/-/raw/main/youtubepro.module",
            type: .module,
            symbol: "play.rectangle.fill"
        ),
        ResourceItem(
            name: "TikTok Unlock",
            description: "Mở khóa khu vực TikTok không cần thẻ SIM",
            url: "https://raw.githubusercontent.com/Keywos/Rule-Snippets/master/Unlock/TikTok.sgmodule",
            type: .module,
            symbol: "music.note"
        ),
        ResourceItem(
            name: "PicsArt Premium",
            description: "Kích hoạt Premium cho PicsArt",
            url: "https://github.com/QuocChienn2709/quocchiennshadowrocket/raw/refs/heads/main/picsart.module",
            type: .module,
            symbol: "shield.fill"
        ),
        ResourceItem(
            name: "Spotify",
            description: "Hỗ trợ Spotify (một số tính năng)",
            url: "https://gitlab.com/chienq895/module-ad-config/-/raw/main/spotifyVIP.module",
            type: .module,
            symbol: "music.note.list"
        ),
        ResourceItem(
            name: "Alight Motion Pro",
            description: "Unlock Pro Alight Motion",
            url: "https://raw.githubusercontent.com/QuocChienn2709/quocchiennshadowrocket/refs/heads/main/alightmotion.module",
            type: .module,
            symbol: "xmark.shield.fill"
        ),
        ResourceItem(
            name: "Lightroom Creative Cloud Standard",
            description: "Được kích hoạt gói Creative Cloud Standard",
            url: "https://raw.githubusercontent.com/QuocChienn2709/quocchiennshadowrocket/refs/heads/main/lightroom.module",
            type: .module,
            symbol: "cart.fill"
        ),
        ResourceItem(
            name: "Apple System Optimize",
            description: "Tối ưu dịch vụ hệ thống Apple",
            url: "https://raw.githubusercontent.com/uxudjs/Shadowrocket/refs/heads/main/modules/apple_system_sr.sgmodule",
            type: .module,
            symbol: "apple.logo"
        ),
        ResourceItem(
            name: "XiaoQi Adblock",
            description: "Module chặn quảng cáo tổng hợp của XiaoQi",
            url: "https://raw.githubusercontent.com/SherryBX/XiaoQi-sgmodule/main/xiaoqi.sgmodule",
            type: .module,
            symbol: "eye.slash.fill"
        )
    ]

    static let configs: [ResourceItem] = [
        ResourceItem(
            name: "Across GFW (Xuất cảnh)",
            description: "Cấu hình quy tắc xuất cảnh - Trung Quốc direct, còn lại proxy",
            url: "https://raw.githubusercontent.com/uxudjs/Shadowrocket/refs/heads/main/Across_GFW.conf",
            type: .config,
            symbol: "globe.asia.australia.fill"
        ),
        ResourceItem(
            name: "Back CN (Hồi quốc)",
            description: "Cấu hình quy tắc hồi quốc - media TQ proxy, còn lại direct",
            url: "https://raw.githubusercontent.com/uxudjs/Shadowrocket/refs/heads/main/Back_CN.conf",
            type: .config,
            symbol: "flag.fill"
        ),
        ResourceItem(
            name: "Simple Example Config",
            description: "Cấu hình ví dụ cơ bản (có thể thay thế bằng config của bạn)",
            url: "https://raw.githubusercontent.com/dlisin/shadowrocket-config/master/shadowrocket.conf",
            type: .config,
            symbol: "doc.text.fill"
        )
    ]
}
