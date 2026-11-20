import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var vm = FileBrowserViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                pathBar
                sortBar
                content
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { vm.goBack() }) {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(!vm.canGoBack)
                }
                ToolbarItem(placement: .principal) {
                    Text(vm.currentName).font(.headline)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { vm.showNewFolder = true }) {
                            Label("Thư mục mới", systemImage: "folder.badge.plus")
                        }
                        Button(action: { vm.showNewFile = true }) {
                            Label("File mới", systemImage: "doc.badge.plus")
                        }
                        Divider()
                        Button(action: { vm.showImporter = true }) {
                            Label("Import", systemImage: "square.and.arrow.down")
                        }
                        Button(action: { vm.refresh() }) {
                            Label("Làm mới", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(item: $vm.selectedFile) { item in
                TextEditorView(url: item.url)
            }
            .fileImporter(isPresented: $vm.showImporter, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
                if case .success(let urls) = result {
                    vm.importFiles(urls)
                }
            }
            .alert("Thư mục mới", isPresented: $vm.showNewFolder) {
                TextField("Tên", text: $vm.input)
                Button("Tạo") { vm.createFolder() }
                Button("Hủy", role: .cancel) {}
            }
            .alert("File mới", isPresented: $vm.showNewFile) {
                TextField("Tên file", text: $vm.input)
                Button("Tạo") { vm.createFile() }
                Button("Hủy", role: .cancel) {}
            }
            .alert("Đổi tên", isPresented: $vm.showRename) {
                TextField("Tên mới", text: $vm.input)
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
                ForEach(Array(vm.pathComponents.enumerated()), id: \.offset) { i, name in
                    Button(action: { vm.goToIndex(i) }) {
                        Text(name)
                            .font(.caption)
                            .foregroundColor(i == vm.pathComponents.count - 1 ? .primary : .cyan)
                    }
                    if i < vm.pathComponents.count - 1 {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .background(Color(UIColor.secondarySystemBackground))
    }

    private var sortBar: some View {
        Picker("Sắp xếp", selection: Binding(
            get: { vm.sort },
            set: { newValue in
                vm.sort = newValue
                vm.refresh()
            }
        )) {
            Text("Tên").tag(SortOrder.name)
            Text("Kích thước").tag(SortOrder.size)
            Text("Ngày").tag(SortOrder.date)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var content: some View {
        if vm.isLoading {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if vm.items.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "folder")
                    .font(.system(size: 44))
                    .foregroundColor(.secondary)
                Text("Thư mục trống")
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(vm.items) { item in
                    FileRow(item: item)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if item.isDirectory {
                                vm.open(item.url)
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
                                vm.input = item.name
                                vm.showRename = true
                            } label: {
                                Label("Đổi tên", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                vm.delete(item)
                            } label: {
                                Label("Xóa", systemImage: "trash")
                            }
                        }
                }
            }
            .listStyle(.plain)
        }
    }
}

struct FileRow: View {
    let item: BrowserItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.system(size: 20))
                .foregroundColor(item.color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    if !item.isDirectory {
                        Text(item.sizeText)
                    }
                    Text(item.dateText)
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
            Spacer()
            if item.isDirectory {
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct TextEditorView: View {
    let url: URL
    @State private var text = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            TextEditor(text: $text)
                .font(Font.system(.body, design: .monospaced))
                .padding(8)
                .navigationTitle(url.lastPathComponent)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Đóng") { dismiss() }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Lưu") {
                            try? text.write(to: url, atomically: true, encoding: .utf8)
                        }
                    }
                }
                .onAppear {
                    text = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
                }
        }
    }
}

enum SortOrder: String {
    case name, size, date
}

struct BrowserItem: Identifiable {
    let id = UUID()
    let name: String
    let url: URL
    let isDirectory: Bool
    let size: Int64
    let modified: Date?

    var sizeText: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var dateText: String {
        guard let modified = modified else { return "" }
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f.string(from: modified)
    }

    var icon: String {
        if isDirectory { return "folder.fill" }
        switch url.pathExtension.lowercased() {
        case "txt", "md", "json", "xml", "plist", "log": return "doc.text.fill"
        case "png", "jpg", "jpeg", "gif", "heic": return "photo.fill"
        case "mp4", "mov": return "film.fill"
        case "mp3", "m4a", "wav": return "music.note"
        case "zip", "ipa": return "doc.zipper"
        default: return "doc.fill"
        }
    }

    var color: Color {
        isDirectory ? .yellow : .cyan
    }
}

class FileBrowserViewModel: ObservableObject {
    @Published var items: [BrowserItem] = []
    @Published var isLoading = false
    @Published var selectedFile: BrowserItem?
    @Published var showNewFolder = false
    @Published var showNewFile = false
    @Published var showRename = false
    @Published var showImporter = false
    @Published var input = ""
    @Published var itemToRename: BrowserItem?
    @Published var sort: SortOrder = .name

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
        var c = ["Documents"]
        let rel = currentURL.path.replacingOccurrences(of: docs.path, with: "")
        let parts = rel.split(separator: "/").map { String($0) }.filter { !$0.isEmpty }
        c.append(contentsOf: parts)
        return c
    }

    var canGoBack: Bool { history.count > 1 }

    func load() {
        if history.isEmpty { history = [currentURL] }
        refresh()
    }

    func refresh() {
        isLoading = true
        let url = currentURL
        let order = sort
        DispatchQueue.global(qos: .userInitiated).async {
            var list: [BrowserItem] = []
            let fm = FileManager.default
            if let contents = try? fm.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
            ) {
                for u in contents {
                    let v = try? u.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
                    list.append(BrowserItem(
                        name: u.lastPathComponent,
                        url: u,
                        isDirectory: v?.isDirectory ?? false,
                        size: Int64(v?.fileSize ?? 0),
                        modified: v?.contentModificationDate
                    ))
                }
            }
            list.sort { a, b in
                if a.isDirectory != b.isDirectory { return a.isDirectory }
                switch order {
                case .name:
                    return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
                case .size:
                    return a.size > b.size
                case .date:
                    return (a.modified ?? .distantPast) > (b.modified ?? .distantPast)
                }
            }
            DispatchQueue.main.async {
                self.items = list
                self.isLoading = false
            }
        }
    }

    func open(_ url: URL) {
        history.append(url)
        refresh()
    }

    func goBack() {
        if history.count > 1 {
            history.removeLast()
            refresh()
        }
    }

    func goToIndex(_ index: Int) {
        let target = index + 1
        while history.count > target { history.removeLast() }
        refresh()
    }

    func createFolder() {
        let name = input.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        try? FileManager.default.createDirectory(at: currentURL.appendingPathComponent(name), withIntermediateDirectories: false)
        input = ""
        refresh()
    }

    func createFile() {
        let name = input.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        FileManager.default.createFile(atPath: currentURL.appendingPathComponent(name).path, contents: Data())
        input = ""
        refresh()
    }

    func rename() {
        guard let item = itemToRename else { return }
        let name = input.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, name != item.name else { return }
        let newURL = item.url.deletingLastPathComponent().appendingPathComponent(name)
        try? FileManager.default.moveItem(at: item.url, to: newURL)
        input = ""
        itemToRename = nil
        refresh()
    }

    func delete(_ item: BrowserItem) {
        try? FileManager.default.removeItem(at: item.url)
        refresh()
    }

    func importFiles(_ urls: [URL]) {
        for url in urls {
            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                let dest = currentURL.appendingPathComponent(url.lastPathComponent)
                try? FileManager.default.copyItem(at: url, to: dest)
            }
        }
        refresh()
    }
}
