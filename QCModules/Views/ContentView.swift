import SwiftUI

struct ContentView: View {
    @StateObject private var store = BlockStore()
    @State private var newDomain = ""
    @State private var showAdd = false

    var body: some View {
        NavigationView {
            List {
                Section("Mặc định") {
                    ForEach(store.defaults) { item in
                        DomainRow(item: item) {
                            store.toggle(item)
                        }
                    }
                }

                if !store.customs.isEmpty {
                    Section("Tùy chọn") {
                        ForEach(store.customs) { item in
                            DomainRow(item: item) {
                                store.toggle(item)
                            }
                        }
                        .onDelete { offsets in
                            store.deleteCustom(at: offsets)
                        }
                    }
                }

                Section {
                    Button(action: { showAdd = true }) {
                        Label("Thêm domain", systemImage: "plus")
                    }
                }

                Section("Thông tin") {
                    Text("App lưu danh sách chặn trên máy. Để chặn thật sự cần dùng với Content Blocker hoặc proxy.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Chặn Domain")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .alert("Thêm domain", isPresented: $showAdd) {
                TextField("vd: example.com", text: $newDomain)
                    .autocapitalization(.none)
                Button("Thêm") {
                    store.addCustom(newDomain)
                    newDomain = ""
                }
                Button("Hủy", role: .cancel) {
                    newDomain = ""
                }
            } message: {
                Text("Nhập domain muốn chặn")
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
    }
}

struct DomainRow: View {
    let item: BlockItem
    let onToggle: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.domain)
                    .font(.system(size: 15, weight: .medium))
                if !item.note.isEmpty {
                    Text(item.note)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
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

    private let key = "blocked_domains"

    init() {
        load()
    }

    var defaults: [BlockItem] {
        items.filter { $0.isDefault }
    }

    var customs: [BlockItem] {
        items.filter { !$0.isDefault }
    }

    func toggle(_ item: BlockItem) {
        if let i = items.firstIndex(where: { $0.id == item.id }) {
            items[i].enabled.toggle()
            save()
        }
    }

    func addCustom(_ domain: String) {
        let d = domain.trimmingCharacters(in: .whitespaces).lowercased()
        guard !d.isEmpty, !items.contains(where: { $0.domain == d }) else { return }
        items.append(BlockItem(domain: d, note: "Tùy chọn", isDefault: false))
        save()
    }

    func deleteCustom(at offsets: IndexSet) {
        let customs = self.customs
        for index in offsets {
            let item = customs[index]
            items.removeAll { $0.id == item.id }
        }
        save()
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([BlockItem].self, from: data) {
            items = decoded
            return
        }
        items = Self.defaultList
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
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
