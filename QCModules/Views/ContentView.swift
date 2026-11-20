import SwiftUI
import AVKit

struct ContentView: View {
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var selectedVideo: VideoItem?

    private let categories = ["All", "Nature", "Tech", "Music", "Travel"]

    private var filtered: [VideoItem] {
        let base = selectedCategory == "All"
            ? VideoStore.all
            : VideoStore.all.filter { $0.category == selectedCategory }
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
            .sheet(item: $selectedVideo) { video in
                PlayerView(video: video)
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
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
                        Text(cat)
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
                ForEach(filtered) { video in
                    VideoCard(video: video)
                        .onTapGesture {
                            selectedVideo = video
                        }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 20)
        }
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
    let id = UUID()
    let title: String
    let channel: String
    let views: String
    let duration: String
    let category: String
    let description: String
    let url: URL
}

enum VideoStore {
    static let all: [VideoItem] = [
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
            title: "For Bigger Blazes",
            channel: "Google",
            views: "890K lượt xem",
            duration: "0:15",
            category: "Tech",
            description: "Video mẫu Google.",
            url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4")!
        ),
        VideoItem(
            title: "For Bigger Escape",
            channel: "Google",
            views: "2.3M lượt xem",
            duration: "0:15",
            category: "Travel",
            description: "Video mẫu Google.",
            url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4")!
        ),
        VideoItem(
            title: "For Bigger Fun",
            channel: "Google",
            views: "1.8M lượt xem",
            duration: "0:15",
            category: "Music",
            description: "Video mẫu Google.",
            url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4")!
        ),
        VideoItem(
            title: "For Bigger Joyrides",
            channel: "Google",
            views: "960K lượt xem",
            duration: "0:15",
            category: "Travel",
            description: "Video mẫu Google.",
            url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4")!
        ),
        VideoItem(
            title: "For Bigger Meltdowns",
            channel: "Google",
            views: "1.4M lượt xem",
            duration: "0:15",
            category: "Music",
            description: "Video mẫu Google.",
            url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4")!
        )
    ]
}
