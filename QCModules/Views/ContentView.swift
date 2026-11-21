import SwiftUI

struct ContentView: View {
    @StateObject private var store = BlockStore()
    @State private var newDomain = ""
    @State private var showAdd = false
    @State private var showRules = false

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
                    Button(action: { showRules = true }) {
                        Label("Xem rule chặn", systemImage: "doc.text")
                    }
                }

                Section("Cách dùng") {
                    Text("1. Thêm domain\n2. Nhấn Xem rule chặn\n3. Copy và dán vào Shadowrocket (Config → Rules)")
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
            .sheet(isPresented: $showRules) {
                RulesView(rules: store.rules)
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
    }
}

struct RulesView: View {
    let rules: String
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false

    var body: some View {
        NavigationView {
            ScrollView {
                Text(rules)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Đóng") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(copied ? "Đã copy" : "Copy") {
                        UIPasteboard.general.string = rules
                        copied = true
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
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
