import SwiftUI

struct ContentView: View {
    @StateObject private var fileManager = FileManagerViewModel()

    var body: some View {
        NavigationView {
            Group {
                if fileManager.isLoading {
                    ProgressView()
                } else if fileManager.items.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "folder")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("Thư mục trống")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    List {
                        ForEach(fileManager.items) { item in
                            FileRow(item: item) {
                                if item.isDirectory {
                                    fileManager.navigate(to: item.url)
                                } else {
                                    fileManager.selectedFile = item
                                }
                            }
                        }
                        .onDelete(perform: fileManager.delete)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(fileManager.currentPathName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if fileManager.canGoBack {
                        Button {
                            fileManager.goBack()
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            fileManager.showNewFolderAlert = true
                        } label: {
                            Label("Thư mục mới", systemImage: "folder.badge.plus")
                        }
                        Button {
                            fileManager.showNewFileAlert = true
                        } label: {
                            Label("File mới", systemImage: "doc.badge.plus")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $fileManager.selectedFile) { item in
                FileViewer(url: item.url)
            }
            .alert("Thư mục mới", isPresented: $fileManager.showNewFolderAlert) {
                TextField("Tên thư mục", text: $fileManager.newName)
                Button("Tạo") { fileManager.createFolder() }
                Button("Hủy", role: .cancel) {}
            }
            .alert("File mới", isPresented: $fileManager.showNewFileAlert) {
                TextField("Tên file", text: $fileManager.newName)
                Button("Tạo") { fileManager.createFile() }
                Button("Hủy", role: .cancel) {}
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
        .onAppear {
            fileManager.load()
        }
    }
}

struct FileRow: View {
    let item: FileItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(item.isDirectory ? .yellow : .cyan)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if !item.isDirectory {
                        Text(item.sizeString)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if item.isDirectory {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct FileViewer: View {
    let url: URL
    @State private var content = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                Text(content)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .navigationTitle(url.lastPathComponent)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") { dismiss() }
                }
            }
            .onAppear {
                content = (try? String(contentsOf: url, encoding: .utf8)) ?? "Không thể đọc file"
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

    var sizeString: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

class FileManagerViewModel: ObservableObject {
    @Published var items: [FileItem] = []
    @Published var isLoading = false
    @Published var selectedFile: FileItem?
    @Published var showNewFolderAlert = false
    @Published var showNewFileAlert = false
    @Published var newName = ""

    private var history: [URL] = []
    private var currentURL: URL {
        history.last ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    var currentPathName: String {
        currentURL.lastPathComponent == "Documents" ? "Documents" : currentURL.lastPathComponent
    }

    var canGoBack: Bool {
        history.count > 1
    }

    func load() {
        if history.isEmpty {
            history = [currentURL]
        }
        refresh()
    }

    func refresh() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let fm = FileManager.default
            var result: [FileItem] = []

            if let contents = try? fm.contentsOfDirectory(
                at: self.currentURL,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
            ) {
                for url in contents {
                    let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])
                    let isDir = values?.isDirectory ?? false
                    let size = Int64(values?.fileSize ?? 0)
                    result.append(FileItem(name: url.lastPathComponent, url: url, isDirectory: isDir, size: size))
                }
            }

            result.sort { a, b in
                if a.isDirectory != b.isDirectory {
                    return a.isDirectory
                }
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
        let url = currentURL.appendingPathComponent(name)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
        newName = ""
        refresh()
    }

    func createFile() {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let url = currentURL.appendingPathComponent(name)
        FileManager.default.createFile(atPath: url.path, contents: Data())
        newName = ""
        refresh()
    }

    func delete(at offsets: IndexSet) {
        for index in offsets {
            let item = items[index]
            try? FileManager.default.removeItem(at: item.url)
        }
        refresh()
    }
}
