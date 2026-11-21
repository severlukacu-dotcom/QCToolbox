import SwiftUI

struct ContentView: View {
    @State private var path: [String] = []
    @State private var items: [FileItem] = []
    @State private var selected: FileItem?
    @State private var showText = false
    @State private var textContent = ""
    @State private var error = ""

    private var currentURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return path.reduce(docs) { $0.appendingPathComponent($1) }
    }

    var body: some View {
        NavigationView {
            List {
                if !error.isEmpty {
                    Section {
                        Text(error).foregroundColor(.red).font(.caption)
                    }
                }

                Section(header: Text(path.isEmpty ? "Documents" : path.joined(separator: " / "))) {
                    if items.isEmpty {
                        Text("Thư mục trống")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(items) { item in
                            HStack {
                                Image(systemName: item.isDir ? "folder.fill" : icon(for: item.name))
                                    .foregroundColor(item.isDir ? .yellow : .blue)
                                    .frame(width: 28)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.system(size: 15))
                                    if !item.isDir {
                                        Text(item.size)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                if item.isDir {
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if item.isDir {
                                    path.append(item.name)
                                    load()
                                } else {
                                    openFile(item)
                                }
                            }
                        }
                        .onDelete { offsets in
                            delete(at: offsets)
                        }
                    }
                }

                Section("Công cụ") {
                    Button(action: createFolder) {
                        Label("Tạo thư mục", systemImage: "folder.badge.plus")
                    }
                    Button(action: { load() }) {
                        Label("Làm mới", systemImage: "arrow.clockwise")
                    }
                }
            }
            .navigationTitle("WQ Files")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !path.isEmpty {
                        Button(action: goBack) {
                            Image(systemName: "chevron.left")
                        }
                    }
                }
            }
            .sheet(isPresented: $showText) {
                TextViewer(content: textContent, name: selected?.name ?? "")
            }
            .onAppear { load() }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
    }

    private func load() {
        error = ""
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: currentURL,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
            )
            items = contents.map { url in
                let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                return FileItem(name: url.lastPathComponent, isDir: isDir, size: formatSize(size))
            }.sorted { a, b in
                if a.isDir != b.isDir { return a.isDir }
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
        } catch {
            self.error = error.localizedDescription
            items = []
        }
    }

    private func goBack() {
        if !path.isEmpty {
            path.removeLast()
            load()
        }
    }

    private func createFolder() {
        let name = "NewFolder_\(Int(Date().timeIntervalSince1970))"
        let url = currentURL.appendingPathComponent(name)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        load()
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let item = items[index]
            let url = currentURL.appendingPathComponent(item.name)
            try? FileManager.default.removeItem(at: url)
        }
        load()
    }

    private func openFile(_ item: FileItem) {
        let url = currentURL.appendingPathComponent(item.name)
        if let data = try? Data(contentsOf: url),
           let text = String(data: data, encoding: .utf8) {
            textContent = text
            selected = item
            showText = true
        } else {
            error = "Không mở được file này"
        }
    }

    private func icon(for name: String) -> String {
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "txt", "md", "json", "plist", "xml": return "doc.text"
        case "png", "jpg", "jpeg", "gif": return "photo"
        case "mp4", "mov": return "film"
        case "mp3", "m4a": return "music.note"
        case "zip", "ipa": return "doc.zipper"
        default: return "doc"
        }
    }

    private func formatSize(_ bytes: Int) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return String(format: "%.1f KB", Double(bytes) / 1024) }
        return String(format: "%.1f MB", Double(bytes) / 1024 / 1024)
    }
}

struct FileItem: Identifiable {
    let id = UUID()
    let name: String
    let isDir: Bool
    let size: String
}

struct TextViewer: View {
    let content: String
    let name: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                Text(content)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .navigationTitle(name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
