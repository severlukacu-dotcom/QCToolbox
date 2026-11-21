import SwiftUI
import NetworkExtension

struct ContentView: View {
    @StateObject private var store = BlockStore()
    @State private var newDomain = ""
    @State private var showAdd = false
    @State private var statusText = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                statusHeader
                domainList
            }
            .navigationTitle("Domain Blocker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAdd = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("Thêm domain", isPresented: $showAdd) {
                TextField("vd: example.com", text: $newDomain)
                    .autocapitalization(.none)
                Button("Thêm") {
                    store.addCustom(newDomain)
                    newDomain = ""
                }
                Button("Hủy", role: .cancel) { newDomain = "" }
            } message: {
                Text("Nhập domain muốn chặn")
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
        .onAppear {
            store.checkStatus()
        }
    }

    private var statusHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(store.isBlocking ? Color.green.opacity(0.2) : Color.gray.opacity(0.15))
                    .frame(width: 140, height: 140)

                Circle()
                    .stroke(store.isBlocking ? Color.green : Color.gray.opacity(0.4), lineWidth: 4)
                    .frame(width: 140, height: 140)

                VStack(spacing: 4) {
                    Image(systemName: store.isBlocking ? "shield.fill" : "shield")
                        .font(.system(size: 36))
                        .foregroundColor(store.isBlocking ? .green : .gray)
                    Text(store.isBlocking ? "ĐANG CHẶN" : "TẮT")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(store.isBlocking ? .green : .gray)
                }
            }

            Button(action: { store.toggleBlocking() }) {
                Text(store.isBlocking ? "Tắt chặn" : "Bật chặn")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(store.isBlocking ? Color.red : Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 20)

            if !store.statusMessage.isEmpty {
                Text(store.statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            Text(store.isBlocking
                 ? "\(store.enabledCount) domain đang bị chặn"
                 : "Chặn đang tắt")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 20)
        .background(Color(UIColor.secondarySystemBackground))
    }

    private var domainList: some View {
        List {
            Section("Mặc định") {
                ForEach(store.defaults) { item in
                    DomainRow(item: item, blocking: store.isBlocking) {
                        store.toggle(item)
                    }
                }
            }

            if !store.customs.isEmpty {
                Section("Tùy chọn") {
                    ForEach(store.customs) { item in
                        DomainRow(item: item, blocking: store.isBlocking) {
                            store.toggle(item)
                        }
                    }
                    .onDelete { store.deleteCustom(at: $0) }
                }
            }

            Section {
                Text("Bật chặn sẽ yêu cầu cài VPN. Cần ký app bằng chứng chỉ có Network Extension.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct DomainRow: View {
    let item: BlockItem
    let blocking: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.domain)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(blocking && item.enabled ? .primary : .secondary)
                if !item.note.isEmpty {
                    Text(item.note)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            if blocking && item.enabled {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 14))
            }
            Toggle("", isOn: Binding(
                get: { item.enabled },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
        }
    }
}

struct BlockItem: Identifiable, Codable, Equatable {
    let id: UUID
    let domain: String
    let note: String
    var enabled: Bool
    let isDefault: Bool

    init(id: UUID = UUID(), domain: String, note: String = "", enabled: Bool = true, isDefault: Bool = false) {
        self.id = id
        self.domain = domain
        self.note = note
        self.enabled = enabled
        self.isDefault = isDefault
    }
}

class BlockStore: ObservableObject {
    @Published var items: [BlockItem] = []
    @Published var isBlocking = false
    @Published var statusMessage = ""

    private let itemsKey = "blocked_domains"
    private let blockingKey = "is_blocking"
    private let appGroup = "group.com.quocchien.qcmodules"

    init() {
        load()
    }

    var defaults: [BlockItem] { items.filter { $0.isDefault } }
    var customs: [BlockItem] { items.filter { !$0.isDefault } }
    var enabledCount: Int { items.filter { $0.enabled }.count }

    var activeDomains: [String] {
        items.filter { $0.enabled }.map { $0.domain }
    }

    func checkStatus() {
        NEVPNManager.shared().loadFromPreferences { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.statusMessage = "Lỗi: \(error.localizedDescription)"
                    return
                }
                let status = NEVPNManager.shared().connection.status
                self?.isBlocking = (status == .connected || status == .connecting)
            }
        }
    }

    func toggleBlocking() {
        if isBlocking {
            stopTunnel()
        } else {
            startTunnel()
        }
    }

    private func startTunnel() {
        statusMessage = "Đang kết nối..."
        let manager = NEVPNManager.shared()
        manager.loadFromPreferences { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                DispatchQueue.main.async {
                    self.statusMessage = "Lỗi: \(error.localizedDescription)"
                }
                return
            }

            let proto = NETunnelProviderProtocol()
            proto.providerBundleIdentifier = "com.quocchien.qcmodules.tunnel"
            proto.serverAddress = "Domain Blocker"
            proto.providerConfiguration = ["blockedDomains": self.activeDomains as NSArray]

            manager.protocolConfiguration = proto
            manager.localizedDescription = "Domain Blocker"
            manager.isEnabled = true

            manager.saveToPreferences { error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.statusMessage = "Lỗi lưu: \(error.localizedDescription)"
                    }
                    return
                }
                do {
                    try manager.connection.startVPNTunnel()
                    DispatchQueue.main.async {
                        self.isBlocking = true
                        self.statusMessage = "Đã bật chặn"
                        UserDefaults.standard.set(true, forKey: self.blockingKey)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.statusMessage = "Lỗi khởi động: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    private func stopTunnel() {
        NEVPNManager.shared().connection.stopVPNTunnel()
        isBlocking = false
        statusMessage = "Đã tắt"
        UserDefaults.standard.set(false, forKey: blockingKey)
    }

    func toggle(_ item: BlockItem) {
        if let i = items.firstIndex(where: { $0.id == item.id }) {
            items[i].enabled.toggle()
            save()
            if isBlocking {
                restartTunnel()
            }
        }
    }

    private func restartTunnel() {
        stopTunnel()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.startTunnel()
        }
    }

    func addCustom(_ domain: String) {
        let d = domain.trimmingCharacters(in: .whitespaces).lowercased()
        guard !d.isEmpty, !items.contains(where: { $0.domain == d }) else { return }
        items.append(BlockItem(domain: d, note: "Tùy chọn", isDefault: false))
        save()
    }

    func deleteCustom(at offsets: IndexSet) {
        let list = customs
        for index in offsets {
            items.removeAll { $0.id == list[index].id }
        }
        save()
    }

    private func load() {
        isBlocking = UserDefaults.standard.bool(forKey: blockingKey)
        if let data = UserDefaults.standard.data(forKey: itemsKey),
           let decoded = try? JSONDecoder().decode([BlockItem].self, from: data) {
            items = decoded
            return
        }
        items = Self.defaultList
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: itemsKey)
        }
        let domains = activeDomains
        UserDefaults(suiteName: appGroup)?.set(domains, forKey: "blocked_domains")
    }

    private static let defaultList: [BlockItem] = [
        BlockItem(domain: "fmipmobile.icloud.com", note: "Find My iPhone", isDefault: true),
        BlockItem(domain: "fmip.icloud.com", note: "Find My", isDefault: true),
        BlockItem(domain: "gs.apple.com", note: "Apple GS", isDefault: true),
        BlockItem(domain: "identity.apple.com", note: "Apple ID", isDefault: true),
        BlockItem(domain: "setup.icloud.com", note: "iCloud Setup", isDefault: true),
        BlockItem(domain: "appleid.apple.com", note: "Apple ID", isDefault: true),
        BlockItem(domain: "ax.init.itunes.apple.com", note: "iTunes Init", isDefault: true),
        BlockItem(domain: "icloud.com", note: "iCloud", isDefault: true)
    ]
}
