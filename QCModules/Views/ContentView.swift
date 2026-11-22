import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.openURL) private var openURL
    @State private var tab = 0
    @State private var query = ""
    @State private var custom: [ResourceItem] = ResourceStore.loadCustom()
    @State private var draftName = ""
    @State private var draftURL = ""
    @State private var draftType: ResourceType = .module
    @State private var message: String?

    private var visible: [ResourceItem] {
        let base: [ResourceItem]
        switch tab {
        case 0: base = ResourceStore.modules
        case 1: base = ResourceStore.configs
        default: base = custom
        }
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return base }
        return base.filter {
            $0.name.lowercased().contains(q)
                || $0.detail.lowercased().contains(q)
                || $0.tag.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Mục", selection: $tab) {
                    Text("Module").tag(0)
                    Text("Config").tag(1)
                    Text("Của tôi").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                TextField("Tìm", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                if tab == 2 {
                    customForm
                }

                List {
                    if visible.isEmpty {
                        Text(tab == 2 ? "Chưa có liên kết. Thêm URL https ở trên." : "Không có mục khớp.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(visible) { item in
                            row(item)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("QC Toolbox")
            .alert("Thông báo", isPresented: Binding(
                get: { message != nil },
                set: { if !$0 { message = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(message ?? "")
            }
        }
    }

    private var customForm: some View {
        VStack(spacing: 8) {
            Picker("Loại", selection: $draftType) {
                Text("Module").tag(ResourceType.module)
                Text("Config").tag(ResourceType.config)
            }
            .pickerStyle(.segmented)

            TextField("Tên", text: $draftName)
                .textFieldStyle(.roundedBorder)

            TextField("https://", text: $draftURL)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                .autocorrectionDisabled()

            Button(action: addCustom) {
                Label("Lưu trên máy này", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
        .padding(.bottom, 4)
    }

    private func row(_ item: ResourceItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: item.symbol)
                    .foregroundStyle(Color.teal)
                Text(item.name)
                    .font(.headline)
                Spacer()
                Text(item.tag)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.teal.opacity(0.12))
                    .clipShape(Capsule())
            }
            Text(item.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Button {
                    open(item)
                } label: {
                    Label("Mở Shadowrocket", systemImage: "arrow.up.right.square")
                }
                .buttonStyle(.borderedProminent)
                .tint(.teal)

                Button {
                    UIPasteboard.general.string = item.url
                    message = "Đã sao chép liên kết."
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.bordered)

                if tab == 2 {
                    Button(role: .destructive) {
                        remove(item.id)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func open(_ item: ResourceItem) {
        guard let url = ResourceStore.scheme(for: item) else {
            message = "URL không hợp lệ."
            return
        }
        openURL(url) { accepted in
            if !accepted {
                message = "Không mở được Shadowrocket. Hãy cài app rồi thử lại."
            }
        }
    }

    private func addCustom() {
        let name = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        let link = draftURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard name.count >= 2 else {
            message = "Nhập tên, ít nhất 2 ký tự."
            return
        }
        guard let parsed = URL(string: link), parsed.scheme?.lowercased() == "https" else {
            message = "Chỉ nhận liên kết https."
            return
        }
        let created = ResourceItem(
            id: UUID().uuidString,
            name: name,
            detail: "Liên kết bạn thêm trên máy này.",
            url: link,
            type: draftType,
            symbol: draftType == .module ? "square.stack.3d.up" : "doc.text",
            tag: "Của tôi"
        )
        custom.insert(created, at: 0)
        ResourceStore.saveCustom(custom)
        draftName = ""
        draftURL = ""
        message = "Đã lưu."
    }

    private func remove(_ id: String) {
        custom.removeAll { $0.id == id }
        ResourceStore.saveCustom(custom)
    }
}
