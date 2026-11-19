import SwiftUI

struct ContentView: View {
    @State private var selected: ToolItem = .device

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(ToolItem.allCases) { item in
                            NavigationLink(destination: destination(for: item)) {
                                ToolCard(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.green)
                        Text("Công cụ chạy trực tiếp trên thiết bị. Dữ liệu ghi chú được lưu cục bộ.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
                .padding(20)
            }
            .background(Color(uiColor: .systemBackground))
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .tint(.cyan)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 44, height: 44)
                    .background(LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                Spacer()
                Text("QC TOOLBOX")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(2)
                    .foregroundColor(.secondary)
            }
            Text("Bộ công cụ\ncủa bạn.")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)
            Text("Tiện ích nhỏ gọn, nhanh chóng và riêng tư.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func destination(for item: ToolItem) -> some View {
        switch item {
        case .device: DeviceInfoView()
        case .uuid: UUIDView()
        case .base64: Base64View()
        case .qr: QRView()
        case .notes: NotesView()
        }
    }
}

struct ToolCard: View {
    let item: ToolItem

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Image(systemName: item.symbol)
                .font(.system(size: 23, weight: .semibold))
                .foregroundColor(.cyan)
                .frame(width: 48, height: 48)
                .background(Color.cyan.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 15))
            VStack(alignment: .leading, spacing: 5) {
                Text(item.rawValue)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(item.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 145, alignment: .leading)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }
}
