import Foundation
import UIKit

struct DeviceInfo {
    static var rows: [(String, String)] {
        let device = UIDevice.current
        let info = Bundle.main.infoDictionary ?? [:]
        let appVersion = info["CFBundleShortVersionString"] as? String ?? "—"
        let build = info["CFBundleVersion"] as? String ?? "—"
        return [
            ("Tên thiết bị", device.name),
            ("Model", device.model),
            ("Mã model", device.modelIdentifier),
            ("Hệ điều hành", "\(device.systemName) \(device.systemVersion)"),
            ("Phiên bản QC Toolbox", appVersion),
            ("Build", build),
            ("Ngôn ngữ", Locale.current.identifier),
            ("Múi giờ", TimeZone.current.identifier)
        ]
    }
}

private extension UIDevice {
    var modelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
    }
}
