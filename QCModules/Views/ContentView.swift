import SwiftUI
import UIKit
import Darwin

struct ContentView: View {
    @StateObject private var info = DeviceInfo()

    var body: some View {
        NavigationView {
            List {
                Section("Thiết bị") {
                    InfoRow(title: "Tên hiển thị", value: info.deviceName)
                    InfoRow(title: "Model máy", value: info.machine)
                    InfoRow(title: "Loại", value: info.model)
                    InfoRow(title: "Hệ điều hành", value: info.systemVersion)
                    InfoRow(title: "Build OS", value: info.osBuild)
                }

                Section("Phần cứng") {
                    InfoRow(title: "CPU", value: info.cpu)
                    InfoRow(title: "Số nhân", value: info.cpuCores)
                    InfoRow(title: "RAM", value: info.ram)
                    InfoRow(title: "Architecture", value: info.arch)
                }

                Section("Màn hình") {
                    InfoRow(title: "Kích thước (pt)", value: info.screenPoints)
                    InfoRow(title: "Kích thước (px)", value: info.screenPixels)
                    InfoRow(title: "Scale", value: info.screenScale)
                    InfoRow(title: "Native Scale", value: info.nativeScale)
                    InfoRow(title: "Safe Area Top", value: info.safeTop)
                }

                Section("Lưu trữ") {
                    InfoRow(title: "Tổng", value: info.totalDisk)
                    InfoRow(title: "Còn trống", value: info.freeDisk)
                    InfoRow(title: "Đã dùng", value: info.usedDisk)
                }

                Section("Pin") {
                    InfoRow(title: "Mức pin", value: info.batteryLevel)
                    InfoRow(title: "Trạng thái", value: info.batteryState)
                    InfoRow(title: "Low Power", value: info.lowPower)
                }

                Section("Định danh") {
                    InfoRow(title: "IDFV (Vendor ID)", value: info.idfv)
                    InfoRow(title: "Ghi chú", value: "Không phải UDID thật")
                }

                Section("Khác") {
                    InfoRow(title: "Ngôn ngữ", value: info.language)
                    InfoRow(title: "Múi giờ", value: info.timezone)
                    InfoRow(title: "App Version", value: info.appVersion)
                    InfoRow(title: "App Build", value: info.appBuild)
                }
            }
            .navigationTitle("Device Info")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable { info.refresh() }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
        .onAppear { info.refresh() }
    }
}

struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .foregroundColor(.secondary)
                .frame(maxWidth: 140, alignment: .leading)
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
                .multilineTextAlignment(.trailing)
                .lineLimit(3)
                .minimumScaleFactor(0.6)
        }
    }
}

class DeviceInfo: ObservableObject {
    @Published var deviceName = "-"
    @Published var machine = "-"
    @Published var model = "-"
    @Published var systemVersion = "-"
    @Published var osBuild = "-"

    @Published var cpu = "-"
    @Published var cpuCores = "-"
    @Published var ram = "-"
    @Published var arch = "-"

    @Published var screenPoints = "-"
    @Published var screenPixels = "-"
    @Published var screenScale = "-"
    @Published var nativeScale = "-"
    @Published var safeTop = "-"

    @Published var totalDisk = "-"
    @Published var freeDisk = "-"
    @Published var usedDisk = "-"

    @Published var batteryLevel = "-"
    @Published var batteryState = "-"
    @Published var lowPower = "-"

    @Published var idfv = "-"

    @Published var language = "-"
    @Published var timezone = "-"
    @Published var appVersion = "-"
    @Published var appBuild = "-"

    func refresh() {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true

        deviceName = device.name
        model = device.model
        systemVersion = "\(device.systemName) \(device.systemVersion)"

        machine = Self.sysctlString("hw.machine") ?? "-"
        osBuild = Self.sysctlString("kern.osversion") ?? "-"
        cpu = Self.sysctlString("machdep.cpu.brand_string")
            ?? Self.sysctlString("hw.model")
            ?? machine

        cpuCores = "\(ProcessInfo.processInfo.activeProcessorCount)"

        let physical = ProcessInfo.processInfo.physicalMemory
        ram = ByteCountFormatter.string(fromByteCount: Int64(physical), countStyle: .memory)

        #if arch(arm64)
        arch = "arm64"
        #elseif arch(x86_64)
        arch = "x86_64"
        #else
        arch = "unknown"
        #endif

        let screen = UIScreen.main
        let bounds = screen.bounds
        screenPoints = "\(Int(bounds.width)) × \(Int(bounds.height))"
        screenScale = String(format: "%.1fx", screen.scale)
        nativeScale = String(format: "%.1fx", screen.nativeScale)
        let pxW = Int(bounds.width * screen.scale)
        let pxH = Int(bounds.height * screen.scale)
        screenPixels = "\(pxW) × \(pxH)"

        if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) ?? UIApplication.shared.windows.first {
            safeTop = "\(Int(window.safeAreaInsets.top)) pt"
        }

        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let total = attrs[.systemSize] as? Int64,
           let free = attrs[.systemFreeSize] as? Int64 {
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            totalDisk = formatter.string(fromByteCount: total)
            freeDisk = formatter.string(fromByteCount: free)
            usedDisk = formatter.string(fromByteCount: max(0, total - free))
        }

        let level = device.batteryLevel
        batteryLevel = level < 0 ? "Không hỗ trợ" : "\(Int(level * 100))%"

        switch device.batteryState {
        case .charging: batteryState = "Đang sạc"
        case .full: batteryState = "Đầy"
        case .unplugged: batteryState = "Rút sạc"
        case .unknown: batteryState = "Không rõ"
        @unknown default: batteryState = "Không rõ"
        }

        lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled ? "Bật" : "Tắt"

        idfv = device.identifierForVendor?.uuidString ?? "Không có"

        language = Locale.current.identifier
        timezone = TimeZone.current.identifier

        let info = Bundle.main.infoDictionary
        appVersion = info?["CFBundleShortVersionString"] as? String ?? "-"
        appBuild = info?["CFBundleVersion"] as? String ?? "-"
    }

    private static func sysctlString(_ name: String) -> String? {
        var size = 0
        sysctlbyname(name, nil, &size, nil, 0)
        guard size > 0 else { return nil }
        var buffer = [CChar](repeating: 0, count: size)
        let result = sysctlbyname(name, &buffer, &size, nil, 0)
        guard result == 0 else { return nil }
        return String(cString: buffer)
    }
}
