import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var vm = FileManagerViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Path bar (Filza-style)
                pathBar

                Group {
                    if vm.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if vm.items.isEmpty {
                        emptyView
                    } else {
                        fileList
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        vm.goBack()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(!vm.canGoBack)
                }
                ToolbarItem(placement: .principal) {
                    Text(vm.currentPathName)
                        .font(.headline)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button { vm.showNewFolder = true } label: {
                            Label("Thư mục mới", systemImage: "folder.badge.plus")
                        }
                        Button { vm.showNewFile = true } label: {
                            Label("File mới", systemImage: "doc.badge.plus")
                        }
                        Divider()
                        Button { vm.refresh() } label: {
                            Label("Làm mới", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $vm.selectedFile) { item in
                FileEditor(url: item.url)
            }
            .alert("Thư mục mới", isPresented: $vm.showNewFolder) {
                TextField("Tên", text: $vm.newName)
                Button("Tạo") { vm.createFolder() }
                Button("Hủy", role: .cancel) {}
            }
            .alert("File mới", isPresented: $vm.showNewFile) {
                TextField("Tên (vd: note.txt)", text: $vm.newName)
                Button("Tạo") { vm.createFile() }
                Button("Hủy", role: .cancel) {}
            }
            .alert("Đổi tên", isPresented: $vm.showRename) {
                TextField("Tên mới", text: $vm.newName)
                Button("Đổi") { vm.rename() }
                Button("Hủy", role: .cancel) {}
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
        .onAppear { vm.load() }
    }

    private var pathBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(vm.pathComponents, id: \.self) { component in
                    Text(component)
                        .font(.caption)
                        .foregroundStyle(.cyan)
                    if component != vm.pathComponents.last {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .background(Color(uiColor: .secondarySystemBackground))
    }

    private var emptyView: some View {
        VStack(spacing: 10) {
            Image(systemName: "folder")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("Thư mục trống")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var fileList: some View {
        List {
            ForEach(vm.items) { item in
                FileRow(item: item)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if item.isDirectory {
                            vm.navigate(to: item.url)
                        } else {
                            vm.selectedFile = item
                        }
                    }
                    .contextMenu {
                        if !item.isDirectory {
                            Button { vm.selectedFile = item } label: {
                                Label("Mở", systemImage: "doc.text")
                            }
                        }
                        Button {
                            vm.itemToRename = item
                            vm.newName = item.name
                            vm.showRename = true
                        } label: {
                            Label("Đổi tên", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            vm.delete(item: item)
                        } label: {
                            Label("Xóa", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.plain)
    }
}

struct FileRow: View {
    let item: FileItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.system(size: 22))
                .foregroundStyle(item.iconColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if !item.isDirectory {
                        Text(item.sizeString)
                    }
                    Text(item.dateString)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer()

            if item.isDirectory {
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct FileEditor: View {
    let url: URL
    @State private var content = ""
    @Environment(\.dismiss) private var dismiss
    @State private var saved = true

    var body: some View {
        NavigationView {
            TextEditor(text: $content)
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .onChange(of: content) { _ in saved = false }
                .navigationTitle(url.lastPathComponent)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Đóng") { dismiss() }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Lưu") {
                            try? content.write(to: url, atomically: true, encoding: .utf8)
                            saved = true
                        }
                        .disabled(saved)
                    }
                }
                .onAppear {
                    content = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
                    saved = true
                }
        }
    }
}

struct FileItem: Identifiable {
    let id = UUID()
    let name: String
    let url: URL
    let isDirectory: Bool
    let size: Int64
    let modified: Date?

    var sizeString: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var dateString: String {
        guard let modified else { return "" }
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f.string(from: modified)
    }

    var icon: String {
        if isDirectory { return "folder.fill" }
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "txt", "md", "json", "xml", "plist": return "doc.text.fill"
        case "png", "jpg", "jpeg", "gif", "heic": return "photo.fill"
        case "mp4", "mov": return "film.fill"
        case "mp3", "m4a", "wav": return "music.note"
        case "zip", "ipa": return "doc.zipper"
        default: return "doc.fill"
        }
    }

    var iconColor: Color {
        isDirectory ? .yellow : .cyan
    }
}

class FileManagerViewModel: ObservableObject {
    @Published var items: [FileItem] = []
    @Published var isLoading = false
    @Published var selectedFile: FileItem?
    @Published var showNewFolder = false
    @Published var showNewFile = false
    @Published var showRename = false
    @Published var newName = ""
    @Published var itemToRename: FileItem?

    private var history: [URL] = []
    private var currentURL: URL {
        history.last ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    var currentPathName: String {
        let name = currentURL.lastPathComponent
        return name == "Documents" ? "Documents" : name
    }

    var pathComponents: [String] {
        var components: [String] = ["Documents"]
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let relative = currentURL.path.replacingOccurrences(of: docs.path, with: "")
        let parts = relative.split(separator: "/").map(String.init).filter { !$0.isEmpty }
        components.append(contentsOf: parts)
        return components
    }

    var canGoBack: Bool { history.count > 1 }

    func load() {
        if history.isEmpty { history = [currentURL] }
        refresh()
    }

    func refresh() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let fm = FileManager.default
            var result: [FileItem] = []

            if let contents = try? fm.contentsOfDirectory(
                at: self.currentURL,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
            ) {
                for url in contents {
                    let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
                    let isDir = values?.isDirectory ?? false
                    let size = Int64(values?.fileSize ?? 0)
                    let date = values?.contentModificationDate
                    result.append(FileItem(name: url.lastPathComponent, url: url, isDirectory: isDir, size: size, modified: date))
                }
            }

            result.sort { a, b in
                if a.isDirectory != b.isDirectory { return a.isDirectory }
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }

            DispatchQueue.main.async {
                self.items = result
                self.isLoading = false
            }
        }
    }

    func navigate(to url: URL) {
        history.append(url)
        refresh()
    }

    func goBack() {
        guard history.count > 1 else { return }
        history.removeLast()
        refresh()
    }

    func createFolder() {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        try? FileManager.default.createDirectory(at: currentURL.appendingPathComponent(name), withIntermediateDirectories: false)
        newName = ""
        refresh()
    }

    func createFile() {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        FileManager.default.createFile(atPath: currentURL.appendingPathComponent(name).path, contents: Data())
        newName = ""
        refresh()
    }

    func rename() {
        guard let item = itemToRename else { return }
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, name != item.name else { return }
        let newURL = item.url.deletingLastPathComponent().appendingPathComponent(name)
        try? FileManager.default.moveItem(at: item.url, to: newURL)
        newName = ""
        itemToRename = nil
        refresh()
    }

    func delete(item: FileItem) {
        try? FileManager.default.removeItem(at: item.url)
        refresh()
    }
}
