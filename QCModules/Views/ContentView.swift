import SwiftUI

struct ContentView: View {
    @Environment(\.openURL) private var openURL
    @State private var selectedTab = 0
    @State private var customURL = ""
    @State private var customType: ResourceType = .module
    @State private var showAlert = false
    @State private var alertMessage = ""

    private let tabs = [
        (title: "Modules", icon: "square.stack.3d.up.fill"),
        (title: "Configs", icon: "doc.text.fill"),
        (title: "Tùy chỉnh", icon: "link")
    ]

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: [
                        Color(uiColor: .systemBackground),
                        Color(uiColor: .secondarySystemBackground).opacity(0.5)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .padding(.bottom, 4)

                    TabView(selection: $selectedTab) {
                        resourceList(ResourceStore.modules)
                            .tag(0)
                        resourceList(ResourceStore.configs)
                            .tag(1)
                        customView
                            .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .padding(.bottom, 72)
                }

                liquidGlassTabBar
            }
            .navigationBarHidden(true)
            .alert("Thông báo", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
        .navigationViewStyle(.stack)
        .tint(.cyan)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .frame(width: 36, height: 36)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(LinearGradient(colors: [.cyan.opacity(0.6), .blue.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                        )

                    Image(systemName: "square.and.arrow.up.on.square.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("QC MODULES")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(.secondary)

                    Text("Modules & Configs")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }

                Spacer()
            }

            Text("Mở trực tiếp sang Shadowrocket")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var liquidGlassTabBar: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selectedTab = index
                    }
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: tabs[index].icon)
                            .font(.system(size: 15, weight: .semibold))
                        Text(tabs[index].title)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(selectedTab == index ? .cyan : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        Group {
                            if selectedTab == index {
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.cyan.opacity(0.5), lineWidth: 0.8)
                                    )
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.22), lineWidth: 0.6)
                )
                .shadow(color: .black.opacity(0.12), radius: 10, y: 5)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    private func resourceList(_ items: [ResourceItem]) -> some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(items) { item in
                    ResourceCard(item: item) {
                        openResource(item)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .padding(.bottom, 20)
        }
    }

    private var customView: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Image(systemName: "link.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(
                            LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .padding(.top, 8)

                    Text("Mở tùy chỉnh")
                        .font(.title3.bold())

                    Text("Nhập URL Module hoặc Config")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Loại")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)

                    Picker("Loại", selection: $customType) {
                        Text("Module").tag(ResourceType.module)
                        Text("Config").tag(ResourceType.config)
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("URL")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)

                    TextField("https://...", text: $customURL)
                        .font(.subheadline)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.2), lineWidth: 0.8)
                        )
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.URL)
                }

                Button(action: openCustom) {
                    HStack {
                        Image(systemName: "arrow.up.right.square.fill")
                        Text("Mở trong Shadowrocket")
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: customURL.isEmpty ? [Color.gray.opacity(0.4)] : [Color.cyan, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(customURL.isEmpty)

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
        }
    }

    private func openResource(_ item: ResourceItem) {
        openInShadowrocket(urlString: item.url, type: item.type)
    }

    private func openCustom() {
        guard !customURL.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        openInShadowrocket(urlString: customURL, type: customType)
    }

    private func openInShadowrocket(urlString: String, type: ResourceType) {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            alertMessage = "URL không hợp lệ."
            showAlert = true
            return
        }

        let schemeURL: String
        switch type {
        case .module:
            schemeURL = "shadowrocket://install?module=\(encoded)"
        case .config:
            schemeURL = "shadowrocket://config/add/\(encoded)"
        }

        guard let url = URL(string: schemeURL) else {
            alertMessage = "Không thể tạo URL Scheme."
            showAlert = true
            return
        }

        openURL(url) { accepted in
            if !accepted {
                alertMessage = "Không thể mở Shadowrocket. Hãy đảm bảo ứng dụng đã được cài đặt."
                showAlert = true
            }
        }
    }
}

struct ResourceCard: View {
    let item: ResourceItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.ultraThinMaterial)
                        .frame(width: 40, height: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
                        )

                    Image(systemName: item.symbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(item.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Spacer()

                        Text(item.type.rawValue)
                            .font(.system(size: 9, weight: .semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.ultraThinMaterial)
                            .foregroundStyle(item.type == .module ? .cyan : .orange)
                            .clipShape(Capsule())
                    }

                    Text(item.description)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.15), lineWidth: 0.8)
                    )
            )
            .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }
}
