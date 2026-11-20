import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var vm = FilzaViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                pathBar
                if vm.isLoading {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.items.isEmpty {
                    emptyState
                } else {
                    fileList
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { vm.goBack() } label: { Image(systemName: "chevron.left") }
                        .disabled(!vm.canGoBack)
                }
                ToolbarItem(placement: .principal) {
                    Text(vm.currentName).font(.headline)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button { vm.showNewFolder = true } label: { Label("Thư mục mới", systemImage: "folder.badge.plus") }
                        Button { vm.showNewFile = true } label: { Label("File mới", systemImage: "doc.badge.plus") }
                        Divider()
                        Button { vm.showImporter = true } label: { Label("Import file", systemImage: "square.and.arrow.down") }
                        Button { vm.refresh() } label: { Label("Làm mới", systemImage: "arrow.clockwise") }
                    } label: { Image(systemName: "ellipsis.circle") }
                }
            }
            .sheet(item: $vm.selectedFile) { item in
                FileEditorView(url: item.url)
            }
            .fileImporter(isPresented: $vm.showImporter, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
                if case .success(let urls) = result {
                    vm.importFiles(urls)
                }
            }
            .alert("Thư mục mới", isPresented: $vm.showNewFolder) {
                TextField("Tên", text: $vm.inputName)
                Button("Tạo") { vm.createFolder() }
                Button("Hủy", role: .cancel) {}
            }
            .alert("File mới", isPresented: $vm.showNewFile) {
                TextField("Tên file", text: $vm.inputName)
                Button("Tạo") { vm.createFile() }
                Button("Hủy", role: .cancel) {}
            }
            .alert("Đổi tên", isPresented: $vm.showRename) {
                TextField("Tên mới", text: $vm.inputName)
                Button("Đổi") { vm.performRename() }
                Button("Hủy", role: .cancel) {}
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
        .onAppear { vm.load() }
    }

    private var pathBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(vm.pathComponents.enumerated()), id: \.offset) { idx, name in
                    Button {
                        vm.goToPathIndex(idx)
                    } label: {
                        Text(name)
                            .font(.caption)
                            .foregroundStyle(idx == vm.pathComponents.count - 1 ? .primary : .cyan)
                    }
                    if idx < vm.pathComponents.count - 1 {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color(uiColor: .secondarySystemBackground))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Thư mục trống")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var fileList: some View {
        List {
            ForEach(vm.items) { item in
                FileRowView(item: item)
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
                            Button { vm.selectedFile = item } label: { Label("Mở", systemImage: "doc.text") }
                        }
                        Button {
                            vm.itemToRename = item
                            vm.inputName = item.name
                            vm.showRename = true
                        } label: { Label("Đổi tên", systemImage: "pencil") }
                        Button(role: .destructive) {
                            vm.delete(item)
                        } label: { Label("Xóa", systemImage: "trash") }
                    }
            }
        }
        .listStyle(.plain)
    }
}

struct FileRowView: View {
    let item: FileItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.iconName)
                .font(.system(size: 22))
                .foregroundStyle(item.iconColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if !item.isDirectory {
                        Text(item.sizeString)
                    }
                    Text(item.modifiedString)
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

struct FileEditorView: View {
    let url: URL
    @State private var text = ""
    @State private var isDirty = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            TextEditor(text: $text)
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .onChange(of: text) { newValue in
                    isDirty = true
                }
                .navigationTitle(url.lastPathComponent)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Đóng") { dismiss() }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Lưu") {
                            try? text.write(to: url, atomically: true, encoding: .utf8)
                            isDirty = false
                        }
                        .disabled(!isDirty)
                    }
                }
                .onAppear {
                    text = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
                    isDirty = false
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

    var modifiedString: String {
        guard let modified else { return "" }
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f.string(from: modified)
    }

    var iconName: String {
        if isDirectory { return "folder.fill" }
        switch url.pathExtension.lowercased() {
        case "txt", "md", "json", "xml", "plist", "log": return "doc.text.fill"
        case "png", "jpg", "jpeg", "gif", "heic", "webp": return "photo.fill"
        case "mp4", "mov", "m4v": return "film.fill"
        case "mp3", "m4a", "wav", "aac": return "music.note"
        case "zip", "ipa", "tar", "gz": return "doc.zipper"
        case "pdf": return "doc.richtext.fill"
        default: return "doc.fill"
        }
    }

    var iconColor: Color {
        isDirectory ? .yellow : .cyan
    }
}

class FilzaViewModel: ObservableObject {
    @Published var items: [FileItem] = []
    @Published var isLoading = false
    @Published var selectedFile: FileItem?
    @Published var showNewFolder = false
    @Published var showNewFile = false
    @Published var showRename = false
    @Published var showImporter = false
    @Published var inputName = ""
    @Published var itemToRename: FileItem?

    private var history: [URL] = []
    private var currentURL: URL {
        history.last ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    var currentName: String {
        let n = currentURL.lastPathComponent
        return n == "Documents" ? "Documents" : n
    }

    var pathComponents: [String] {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var comps = ["Documents"]
        let relative = currentURL.path.replacingOccurrences(of: docs.path, with: "")
        let parts = relative.split(separator: "/").map(String.init).filter { !$0.isEmpty }
        comps.append(contentsOf: parts)
        return comps
    }

    var canGoBack: Bool { history.count > 1 }

    func load() {
        if history.isEmpty { history = [currentURL] }
        refresh()
    }

    func refresh() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            var result: [FileItem] = []
            let fm = FileManager.default
            if let contents = try? fm.contentsOfDirectory(
                at: self.currentURL,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
            ) {
                for url in contents {
                    let vals = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
                    result.append(FileItem(
                        name: url.lastPathComponent,
                        url: url,
                        isDirectory: vals?.isDirectory ?? false,
                        size: Int64(vals?.fileSize ?? 0),
                        modified: vals?.contentModificationDate
                    ))
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

    func goToPathIndex(_ index: Int) {
        let targetCount = index + 1
        while history.count > targetCount {
            history.removeLast()
        }
        refresh()
    }

    func createFolder() {
        let name = inputName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        try? FileManager.default.createDirectory(at: currentURL.appendingPathComponent(name), withIntermediateDirectories: false)
        inputName = ""
        refresh()
    }

    func createFile() {
        let name = inputName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        FileManager.default.createFile(atPath: currentURL.appendingPathComponent(name).path, contents: Data())
        inputName = ""
        refresh()
    }

    func performRename() {
        guard let item = itemToRename else { return }
        let name = inputName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, name != item.name else { return }
        let newURL = item.url.deletingLastPathComponent().appendingPathComponent(name)
        try? FileManager.default.moveItem(at: item.url, to: newURL)
        inputName = ""
        itemToRename = nil
        refresh()
    }

    func delete(_ item: FileItem) {
        try? FileManager.default.removeItem(at: item.url)
        refresh()
    }

    func importFiles(_ urls: [URL]) {
        for url in urls {
            guard url.startAccessingSecurityScopedResource() else { continue }
            defer { url.stopAccessingSecurityScopedResource() }
            let dest = currentURL.appendingPathComponent(url.lastPathComponent)
            try? FileManager.default.copyItem(at: url, to: dest)
        }
        refresh()
    }
}
