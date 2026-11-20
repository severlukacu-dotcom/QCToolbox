import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var vm = BrowserModel()

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                    pathChips
                    mainContent
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $vm.selected) { item in
                EditorSheet(url: item.url)
            }
            .fileImporter(isPresented: $vm.importing, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
                if case .success(let urls) = result {
                    vm.importURLs(urls)
                }
            }
            .alert("Thư mục mới", isPresented: $vm.creatingFolder) {
                TextField("Tên", text: $vm.nameInput)
                Button("Tạo") { vm.makeFolder() }
                Button("Hủy", role: .cancel) {}
            }
            .alert("File mới", isPresented: $vm.creatingFile) {
                TextField("Tên", text: $vm.nameInput)
                Button("Tạo") { vm.makeFile() }
                Button("Hủy", role: .cancel) {}
            }
            .alert("Đổi tên", isPresented: $vm.renaming) {
                TextField("Tên mới", text: $vm.nameInput)
                Button("Đổi") { vm.doRename() }
                Button("Hủy", role: .cancel) {}
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
        .onAppear { vm.start() }
    }

    private var header: some View {
        HStack {
            if vm.canBack {
                Button(action: { vm.back() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("QC Files")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                Text(vm.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }

            Spacer()

            Menu {
                Button(action: { vm.creatingFolder = true }) {
                    Label("Thư mục", systemImage: "folder.badge.plus")
                }
                Button(action: { vm.creatingFile = true }) {
                    Label("File", systemImage: "doc.badge.plus")
                }
                Button(action: { vm.importing = true }) {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
                Button(action: { vm.reload() }) {
                    Label("Làm mới", systemImage: "arrow.clockwise")
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(width: 36, height: 36)
                    .background(Color.cyan)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var pathChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(vm.crumbs.enumerated()), id: \.offset) { i, name in
                    Button(action: { vm.jump(to: i) }) {
                        Text(name)
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(i == vm.crumbs.count - 1 ? Color.cyan : Color.white.opacity(0.08))
                            .foregroundColor(i == vm.crumbs.count - 1 ? .black : .white)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        if vm.loading {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if vm.entries.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "tray")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
                Text("Trống")
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(vm.entries) { item in
                        EntryCard(item: item)
                            .onTapGesture {
                                if item.isDir {
                                    vm.enter(item.url)
                                } else {
                                    vm.selected = item
                                }
                            }
                            .contextMenu {
                                if !item.isDir {
                                    Button { vm.selected = item } label: {
                                        Label("Mở", systemImage: "doc")
                                    }
                                }
                                Button {
                                    vm.entryToRename = item
                                    vm.nameInput = item.name
                                    vm.renaming = true
                                } label: {
                                    Label("Đổi tên", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    vm.remove(item)
                                } label: {
                                    Label("Xóa", systemImage: "trash")
                                }
                            }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
    }
}

struct EntryCard: View {
    let item: Entry

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.symbol)
                .font(.system(size: 18))
                .foregroundColor(item.tint)
                .frame(width: 40, height: 40)
                .background(item.tint.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(item.subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }

            Spacer()

            if item.isDir {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct EditorSheet: View {
    let url: URL
    @State private var text = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            TextEditor(text: $text)
                .font(Font.system(.body, design: .monospaced))
                .padding(8)
                .background(Color.black)
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
        .preferredColorScheme(.dark)
    }
}

struct Entry: Identifiable {
    let id = UUID()
    let name: String
    let url: URL
    let isDir: Bool
    let size: Int64
    let date: Date?

    var subtitle: String {
        if isDir { return "Thư mục" }
        let sizeText = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
        if let date = date {
            let f = DateFormatter()
            f.dateStyle = .short
            f.timeStyle = .short
            return "\(sizeText) · \(f.string(from: date))"
        }
        return sizeText
    }

    var symbol: String {
        if isDir { return "folder.fill" }
        switch url.pathExtension.lowercased() {
        case "txt", "md", "json", "xml", "plist": return "doc.text.fill"
        case "png", "jpg", "jpeg", "gif": return "photo.fill"
        case "mp4", "mov": return "film.fill"
        case "mp3", "m4a": return "music.note"
        case "zip", "ipa": return "archivebox.fill"
        default: return "doc.fill"
        }
    }

    var tint: Color {
        isDir ? .orange : .cyan
    }
}

class BrowserModel: ObservableObject {
    @Published var entries: [Entry] = []
    @Published var loading = false
    @Published var selected: Entry?
    @Published var creatingFolder = false
    @Published var creatingFile = false
    @Published var renaming = false
    @Published var importing = false
    @Published var nameInput = ""
    @Published var entryToRename: Entry?

    private var stack: [URL] = []

    private var current: URL {
        stack.last ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    var title: String {
        let n = current.lastPathComponent
        return n == "Documents" ? "Documents" : n
    }

    var crumbs: [String] {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var list = ["Home"]
        let rel = current.path.replacingOccurrences(of: docs.path, with: "")
        let parts = rel.split(separator: "/").map { String($0) }.filter { !$0.isEmpty }
        list.append(contentsOf: parts)
        return list
    }

    var canBack: Bool { stack.count > 1 }

    func start() {
        if stack.isEmpty { stack = [current] }
        reload()
    }

    func reload() {
        loading = true
        let url = current
        DispatchQueue.global(qos: .userInitiated).async {
            var result: [Entry] = []
            let fm = FileManager.default
            if let list = try? fm.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
            ) {
                for u in list {
                    let v = try? u.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
                    result.append(Entry(
                        name: u.lastPathComponent,
                        url: u,
                        isDir: v?.isDirectory ?? false,
                        size: Int64(v?.fileSize ?? 0),
                        date: v?.contentModificationDate
                    ))
                }
            }
            result.sort { a, b in
                if a.isDir != b.isDir { return a.isDir }
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
            DispatchQueue.main.async {
                self.entries = result
                self.loading = false
            }
        }
    }

    func enter(_ url: URL) {
        stack.append(url)
        reload()
    }

    func back() {
        if stack.count > 1 {
            stack.removeLast()
            reload()
        }
    }

    func jump(to index: Int) {
        let target = index + 1
        while stack.count > target { stack.removeLast() }
        reload()
    }

    func makeFolder() {
        let name = nameInput.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        try? FileManager.default.createDirectory(at: current.appendingPathComponent(name), withIntermediateDirectories: false)
        nameInput = ""
        reload()
    }

    func makeFile() {
        let name = nameInput.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        FileManager.default.createFile(atPath: current.appendingPathComponent(name).path, contents: Data())
        nameInput = ""
        reload()
    }

    func doRename() {
        guard let item = entryToRename else { return }
        let name = nameInput.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, name != item.name else { return }
        let newURL = item.url.deletingLastPathComponent().appendingPathComponent(name)
        try? FileManager.default.moveItem(at: item.url, to: newURL)
        nameInput = ""
        entryToRename = nil
        reload()
    }

    func remove(_ item: Entry) {
        try? FileManager.default.removeItem(at: item.url)
        reload()
    }

    func importURLs(_ urls: [URL]) {
        for url in urls {
            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                let dest = current.appendingPathComponent(url.lastPathComponent)
                try? FileManager.default.copyItem(at: url, to: dest)
            }
        }
        reload()
    }
}
