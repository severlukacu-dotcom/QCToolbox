import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var info = DeviceInfo()

    var body: some View {
        NavigationView {
            List {
                Section("Thiết bị") {
                    InfoRow(title: "Model", value: info.model)
                    InfoRow(title: "Tên máy", value: info.deviceName)
                    InfoRow(title: "Hệ điều hành", value: info.systemVersion)
                    InfoRow(title: "Build", value: info.build)
                }

                Section("Màn hình") {
                    InfoRow(title: "Kích thước", value: info.screenSize)
                    InfoRow(title: "Scale", value: info.screenScale)
                    InfoRow(title: "Safe Area Top", value: info.safeTop)
                }

                Section("Dung lượng") {
                    InfoRow(title: "Tổng", value: info.totalDisk)
                    InfoRow(title: "Còn trống", value: info.freeDisk)
                    InfoRow(title: "Đã dùng", value: info.usedDisk)
                }

                Section("Pin") {
                    InfoRow(title: "Mức pin", value: info.batteryLevel)
                    InfoRow(title: "Trạng thái", value: info.batteryState)
                }

                Section("Khác") {
                    InfoRow(title: "Ngôn ngữ", value: info.language)
                    InfoRow(title: "Múi giờ", value: info.timezone)
                    InfoRow(title: "App Version", value: info.appVersion)
                }
            }
            .navigationTitle("Device Info")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                info.refresh()
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
        .onAppear {
            info.refresh()
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

class DeviceInfo: ObservableObject {
    @Published var model = "-"
    @Published var deviceName = "-"
    @Published var systemVersion = "-"
    @Published var build = "-"
    @Published var screenSize = "-"
    @Published var screenScale = "-"
    @Published var safeTop = "-"
    @Published var totalDisk = "-"
    @Published var freeDisk = "-"
    @Published var usedDisk = "-"
    @Published var batteryLevel = "-"
    @Published var batteryState = "-"
    @Published var language = "-"
    @Published var timezone = "-"
    @Published var appVersion = "-"

    func refresh() {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true

        model = device.model
        deviceName = device.name
        systemVersion = "\(device.systemName) \(device.systemVersion)"

        if let build = Bundle.main.infoDictionary?["DTSDKBuild"] as? String {
            self.build = build
        } else {
            self.build = "-"
        }

        let screen = UIScreen.main
        let size = screen.bounds.size
        screenSize = "\(Int(size.width)) × \(Int(size.height))"
        screenScale = "\(screen.scale)x"

        if let window = UIApplication.shared.windows.first {
            safeTop = "\(Int(window.safeAreaInsets.top)) pt"
        }

        let fm = FileManager.default
        if let attrs = try? fm.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let total = attrs[.systemSize] as? Int64,
           let free = attrs[.systemFreeSize] as? Int64 {
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            totalDisk = formatter.string(fromByteCount: total)
            freeDisk = formatter.string(fromByteCount: free)
            usedDisk = formatter.string(fromByteCount: total - free)
        }

        let level = device.batteryLevel
        if level < 0 {
            batteryLevel = "Không hỗ trợ"
        } else {
            batteryLevel = "\(Int(level * 100))%"
        }

        switch device.batteryState {
        case .charging: batteryState = "Đang sạc"
        case .full: batteryState = "Đầy"
        case .unplugged: batteryState = "Rút sạc"
        case .unknown: batteryState = "Không rõ"
        @unknown default: batteryState = "Không rõ"
        }

        language = Locale.current.identifier
        timezone = TimeZone.current.identifier

        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            appVersion = version
        }
    }
}
