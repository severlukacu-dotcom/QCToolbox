import SwiftUI
import AVKit
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var auth = AuthManager()
    @StateObject private var uploads = UploadStore()
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var selectedVideo: VideoItem?
    @State private var showAccount = false
    @State private var showUpload = false

    private let categories = ["All", "Mine", "Nature", "Tech", "Music", "Travel"]

    private var filtered: [VideoItem] {
        var base: [VideoItem]
        if selectedCategory == "Mine" {
            base = uploads.videos
        } else if selectedCategory == "All" {
            base = uploads.videos + VideoStore.samples
        } else {
            base = VideoStore.samples.filter { $0.category == selectedCategory }
        }
        if searchText.isEmpty { return base }
        return base.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.channel.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchBar
                categoryBar
                videoList
            }
            .navigationTitle("QC Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showAccount = true }) {
                        Image(systemName: auth.isLoggedIn ? "person.circle.fill" : "person.circle")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showUpload = true }) {
                        Image(systemName: "plus")
                    }
                    .disabled(!auth.isLoggedIn)
                }
            }
            .sheet(item: $selectedVideo) { video in
                PlayerView(video: video)
            }
            .sheet(isPresented: $showAccount) {
                AccountView(auth: auth)
            }
            .sheet(isPresented: $showUpload) {
                UploadView(auth: auth, uploads: uploads)
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
        .onAppear { uploads.load() }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Tìm video...", text: $searchText)
                .foregroundColor(.white)
        }
        .padding(10)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { cat in
                    Button(action: { selectedCategory = cat }) {
                        Text(cat == "Mine" ? "Của tôi" : cat)
                            .font(.system(size: 13, weight: .medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(selectedCategory == cat ? Color.red : Color.white.opacity(0.1))
                            .foregroundColor(selectedCategory == cat ? .white : .gray)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
    }

    private var videoList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if filtered.isEmpty {
                    Text(selectedCategory == "Mine" ? "Chưa có video nào" : "Không tìm thấy")
                        .foregroundColor(.gray)
                        .padding(.top, 40)
                } else {
                    ForEach(filtered) { video in
                        VideoCard(video: video)
                            .onTapGesture { selectedVideo = video }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 20)
        }
    }
}

struct AccountView: View {
    @ObservedObject var auth: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var username = ""
    @State private var password = ""
    @State private var isRegister = false
    @State private var message = ""

    var body: some View {
        NavigationView {
            Form {
                if auth.isLoggedIn {
                    Section {
                        Text("Đã đăng nhập: \(auth.currentUser ?? "")")
                        Button("Đăng xuất", role: .destructive) {
                            auth.logout()
                            dismiss()
                        }
                    }
                } else {
                    Section(isRegister ? "Đăng ký" : "Đăng nhập") {
                        TextField("Tên đăng nhập", text: $username)
                            .autocapitalization(.none)
                        SecureField("Mật khẩu", text: $password)
                        if !message.isEmpty {
                            Text(message).foregroundColor(.red).font(.caption)
                        }
                        Button(isRegister ? "Tạo tài khoản" : "Đăng nhập") {
                            if isRegister {
                                message = auth.register(username: username, password: password) ? "" : "Tên đã tồn tại hoặc quá ngắn"
                            } else {
                                message = auth.login(username: username, password: password) ? "" : "Sai tên hoặc mật khẩu"
                            }
                            if message.isEmpty { dismiss() }
                        }
                        Button(isRegister ? "Đã có tài khoản? Đăng nhập" : "Chưa có tài khoản? Đăng ký") {
                            isRegister.toggle()
                            message = ""
                        }
                        .font(.caption)
                    }
                    Section {
                        Text("Tài khoản chỉ lưu trên máy này.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Tài khoản")
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

struct UploadView: View {
    @ObservedObject var auth: AuthManager
    @ObservedObject var uploads: UploadStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var showPicker = false
    @State private var selectedURL: URL?
    @State private var message = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Thông tin") {
                    TextField("Tiêu đề", text: $title)
                    TextField("Mô tả", text: $description)
                }
                Section("Video") {
                    Button("Chọn file video") { showPicker = true }
                    if let url = selectedURL {
                        Text(url.lastPathComponent)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if !message.isEmpty {
                        Text(message).foregroundColor(.red).font(.caption)
                    }
                }
                Section {
                    Button("Tải lên") {
                        guard !title.isEmpty, let url = selectedURL else {
                            message = "Nhập tiêu đề và chọn video"
                            return
                        }
                        uploads.add(
                            title: title,
                            channel: auth.currentUser ?? "User",
                            description: description.isEmpty ? "Video của tôi" : description,
                            sourceURL: url
                        )
                        dismiss()
                    }
                    .disabled(title.isEmpty || selectedURL == nil)
                }
            }
            .navigationTitle("Tải video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") { dismiss() }
                }
            }
            .fileImporter(isPresented: $showPicker, allowedContentTypes: [.movie, .video, .mpeg4Movie]) { result in
                if case .success(let url) = result {
                    selectedURL = url
                    message = ""
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct VideoCard: View {
    let video: VideoItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .aspectRatio(16/9, contentMode: .fit)
                    .overlay(
                        Image(systemName: "play.rectangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.4))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Text(video.duration)
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(6)
            }

            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(Color.red.opacity(0.8))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(video.channel.prefix(1)))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(video.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    Text("\(video.channel) · \(video.views)")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

struct PlayerView: View {
    let video: VideoItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VideoPlayer(player: AVPlayer(url: video.url))
                    .aspectRatio(16/9, contentMode: .fit)
                    .background(Color.black)

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(video.title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text("\(video.channel) · \(video.views)")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text(video.description)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.top, 8)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Đóng") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct VideoItem: Identifiable {
    let id: UUID
    let title: String
    let channel: String
    let views: String
    let duration: String
    let category: String
    let description: String
    let url: URL

    init(id: UUID = UUID(), title: String, channel: String, views: String, duration: String, category: String, description: String, url: URL) {
        self.id = id
        self.title = title
        self.channel = channel
        self.views = views
        self.duration = duration
        self.category = category
        self.description = description
        self.url = url
    }
}

class AuthManager: ObservableObject {
    @Published var currentUser: String?
    @Published var isLoggedIn = false

    private let usersKey = "qc_users"
    private let sessionKey = "qc_session"

    init() {
        if let saved = UserDefaults.standard.string(forKey: sessionKey) {
            currentUser = saved
            isLoggedIn = true
        }
    }

    func register(username: String, password: String) -> Bool {
        let name = username.trimmingCharacters(in: .whitespaces)
        guard name.count >= 3, password.count >= 3 else { return false }
        var users = loadUsers()
        guard users[name] == nil else { return false }
        users[name] = password
        saveUsers(users)
        currentUser = name
        isLoggedIn = true
        UserDefaults.standard.set(name, forKey: sessionKey)
        return true
    }

    func login(username: String, password: String) -> Bool {
        let users = loadUsers()
        guard users[username] == password else { return false }
        currentUser = username
        isLoggedIn = true
        UserDefaults.standard.set(username, forKey: sessionKey)
        return true
    }

    func logout() {
        currentUser = nil
        isLoggedIn = false
        UserDefaults.standard.removeObject(forKey: sessionKey)
    }

    private func loadUsers() -> [String: String] {
        UserDefaults.standard.dictionary(forKey: usersKey) as? [String: String] ?? [:]
    }

    private func saveUsers(_ users: [String: String]) {
        UserDefaults.standard.set(users, forKey: usersKey)
    }
}

class UploadStore: ObservableObject {
    @Published var videos: [VideoItem] = []

    private var folder: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Uploads")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private var metaURL: URL {
        folder.appendingPathComponent("meta.json")
    }

    func load() {
        guard let data = try? Data(contentsOf: metaURL),
              let items = try? JSONDecoder().decode([UploadMeta].self, from: data) else {
            videos = []
            return
        }
        videos = items.compactMap { meta in
            let url = folder.appendingPathComponent(meta.filename)
            guard FileManager.default.fileExists(atPath: url.path) else { return nil }
            return VideoItem(
                id: meta.id,
                title: meta.title,
                channel: meta.channel,
                views: "Video của tôi",
                duration: "Local",
                category: "Mine",
                description: meta.description,
                url: url
            )
        }
    }

    func add(title: String, channel: String, description: String, sourceURL: URL) {
        let didAccess = sourceURL.startAccessingSecurityScopedResource()
        defer { if didAccess { sourceURL.stopAccessingSecurityScopedResource() } }

        let filename = "\(UUID().uuidString).mp4"
        let dest = folder.appendingPathComponent(filename)
        do {
            if FileManager.default.fileExists(atPath: dest.path) {
                try FileManager.default.removeItem(at: dest)
            }
            try FileManager.default.copyItem(at: sourceURL, to: dest)
        } catch {
            return
        }

        var metas = loadMetas()
        let meta = UploadMeta(
            id: UUID(),
            title: title,
            channel: channel,
            description: description,
            filename: filename
        )
        metas.insert(meta, at: 0)
        saveMetas(metas)
        load()
    }

    private func loadMetas() -> [UploadMeta] {
        guard let data = try? Data(contentsOf: metaURL),
              let items = try? JSONDecoder().decode([UploadMeta].self, from: data) else {
            return []
        }
        return items
    }

    private func saveMetas(_ metas: [UploadMeta]) {
        if let data = try? JSONEncoder().encode(metas) {
            try? data.write(to: metaURL)
        }
    }
}

struct UploadMeta: Codable {
    let id: UUID
    let title: String
    let channel: String
    let description: String
    let filename: String
}

enum VideoStore {
    static let samples: [VideoItem] = [
        VideoItem(
            title: "Big Buck Bunny",
            channel: "Blender Foundation",
            views: "12M lượt xem",
            duration: "9:56",
            category: "Nature",
            description: "Phim hoạt hình ngắn của Blender Foundation.",
            url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!
        ),
        VideoItem(
            title: "Elephant Dream",
            channel: "Orange Open Movie",
            views: "3.2M lượt xem",
            duration: "10:53",
            category: "Nature",
            description: "Phim mở đầu tiên của Blender.",
            url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4")!
        ),
        VideoItem(
            title: "Sintel",
            channel: "Blender Foundation",
            views: "8.1M lượt xem",
            duration: "14:48",
            category: "Nature",
            description: "Phim hoạt hình Sintel.",
            url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4")!
        ),
        VideoItem(
            title: "Tears of Steel",
            channel: "Blender Foundation",
            views: "5.4M lượt xem",
            duration: "12:14",
            category: "Tech",
            description: "Phim khoa học viễn tưởng ngắn.",
            url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4")!
        ),
        VideoItem(
            title: "Subaru Outback On Street And Dirt",
            channel: "Garage419",
            views: "1.1M lượt xem",
            duration: "2:10",
            category: "Travel",
            description: "Video demo xe Subaru.",
            url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4")!
        ),
        VideoItem(
            title: "For Bigger Fun",
            channel: "Google",
            views: "1.8M lượt xem",
            duration: "0:15",
            category: "Music",
            description: "Video mẫu Google.",
            url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4")!
        )
    ]
}
