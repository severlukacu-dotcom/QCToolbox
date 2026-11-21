import SwiftUI

struct ContentView: View {
    @StateObject private var store = BlockStore()
    @State private var newDomain = ""
    @State private var showAdd = false
    @State private var showShare = false
    @State private var profileURL: URL?
    @State private var status = ""

    var body: some View {
        NavigationView {
            List {
                Section {
                    Toggle(isOn: $store.enabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Bật chặn")
                                .font(.headline)
                            Text(store.enabled ? "Đang bật" : "Đang tắt")
                                .font(.caption)
                                .foregroundColor(store.enabled ? .green : .secondary)
                        }
                    }
                    .tint(.red)
                }

                Section("Domain") {
                    ForEach(store.items) { item in
                        HStack {
                            Text(item.domain)
                                .font(.system(size: 15))
                                .foregroundColor(store.enabled && item.enabled ? .primary : .secondary)
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { item.enabled },
                                set: { _ in store.toggle(item) }
                            ))
                            .labelsHidden()
                            .disabled(!store.enabled)
                        }
                    }
                    .onDelete { offsets in
                        store.delete(at: offsets)
                    }
                }

                Section {
                    Button(action: { showAdd = true }) {
                        Label("Thêm domain", systemImage: "plus")
                    }
                    Button(action: exportProfile) {
                        Label("Tải file cấu hình", systemImage: "square.and.arrow.down")
                    }
                    Button(action: { showRules() }) {
                        Label("Copy rule Shadowrocket", systemImage: "doc.on.doc")
                    }
                }

                if !status.isEmpty {
                    Section {
                        Text(status)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section("Hướng dẫn") {
                    Text("1. Nhấn Tải file cấu hình\n2. Chọn Lưu vào Tệp\n3. Mở file .mobileconfig\n4. Cài đặt → Đã tải về → Cài đặt")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Domain Blocker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .alert("Thêm domain", isPresented: $showAdd) {
                TextField("vd: ads.example.com", text: $newDomain)
                    .autocapitalization(.none)
                Button("Thêm") {
                    store.add(newDomain)
                    newDomain = ""
                }
                Button("Hủy", role: .cancel) { newDomain = "" }
            }
            .sheet(isPresented: $showShare) {
                if let url = profileURL {
                    ShareSheet(items: [url])
                }
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
    }

    private func exportProfile() {
        let xml = ProfileGenerator.make()
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("DomainBlocker.mobileconfig")
        do {
            try xml.write(to: url, atomically: true, encoding: .utf8)
            profileURL = url
            showShare = true
            status = "Đã tạo file. Chọn Lưu vào Tệp."
        } catch {
            status = "Lỗi tạo file"
        }
    }

    private func showRules() {
        UIPasteboard.general.string = store.rules
        status = "Đã copy rule. Dán vào Shadowrocket."
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        vc.excludedActivityTypes = [.assignToContact, .addToReadingList]
        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct BlockItem: Identifiable, Codable, Equatable {
    let id: UUID
    let domain: String
    var enabled: Bool

    init(id: UUID = UUID(), domain: String, enabled: Bool = true) {
        self.id = id
        self.domain = domain
        self.enabled = enabled
    }
}

class BlockStore: ObservableObject {
    @Published var items: [BlockItem] = []
    @Published var enabled: Bool = true {
        didSet { UserDefaults.standard.set(enabled, forKey: "blocker_enabled") }
    }

    private let key = "blocked_domains"

    init() {
        enabled = UserDefaults.standard.object(forKey: "blocker_enabled") as? Bool ?? true
        load()
    }

    var rules: String {
        guard enabled else { return "# Đang tắt" }
        let active = items.filter { $0.enabled }
        if active.isEmpty { return "# Không có domain" }
        return active.map { "DOMAIN-SUFFIX,\($0.domain),REJECT" }.joined(separator: "\n")
    }

    func toggle(_ item: BlockItem) {
        if let i = items.firstIndex(where: { $0.id == item.id }) {
            items[i].enabled.toggle()
            save()
        }
    }

    func add(_ domain: String) {
        let d = domain.trimmingCharacters(in: .whitespaces).lowercased()
        guard !d.isEmpty, !items.contains(where: { $0.domain == d }) else { return }
        items.append(BlockItem(domain: d))
        save()
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        save()
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([BlockItem].self, from: data),
           !decoded.isEmpty {
            items = decoded
            return
        }
        items = [
            BlockItem(domain: "ads.example.com"),
            BlockItem(domain: "tracker.example.com")
        ]
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

enum ProfileGenerator {
    static func make() -> String {
        let uuid1 = UUID().uuidString
        let uuid2 = UUID().uuidString
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
        <key>PayloadContent</key>
        <array>
        <dict>
        <key>DNSSettings</key>
        <dict>
        <key>DNSProtocol</key>
        <string>HTTPS</string>
        <key>ServerURL</key>
        <string>https://dns.adguard-dns.com/dns-query</string>
        <key>ServerName</key>
        <string>dns.adguard-dns.com</string>
        </dict>
        <key>PayloadDescription</key>
        <string>DNS Filter</string>
        <key>PayloadDisplayName</key>
        <string>DNS Blocker</string>
        <key>PayloadIdentifier</key>
        <string>com.quocchien.dns.\(uuid1)</string>
        <key>PayloadType</key>
        <string>com.apple.dnsSettings.managed</string>
        <key>PayloadUUID</key>
        <string>\(uuid1)</string>
        <key>PayloadVersion</key>
        <integer>1</integer>
        <key>ProhibitDisablement</key>
        <false/>
        </dict>
        </array>
        <key>PayloadDisplayName</key>
        <string>Domain Blocker</string>
        <key>PayloadIdentifier</key>
        <string>com.quocchien.domainblocker</string>
        <key>PayloadRemovalDisallowed</key>
        <false/>
        <key>PayloadType</key>
        <string>Configuration</string>
        <key>PayloadUUID</key>
        <string>\(uuid2)</string>
        <key>PayloadVersion</key>
        <integer>1</integer>
        </dict>
        </plist>
        """
    }
}
