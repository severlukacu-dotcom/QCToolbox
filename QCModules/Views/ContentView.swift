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
                // Background
                LinearGradient(
                    colors: [
                        Color(uiColor: .systemBackground),
                        Color(uiColor: .secondarySystemBackground).opacity(0.6)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 8)

                    TabView(selection: $selectedTab) {
                        resourceList(ResourceStore.modules)
                            .tag(0)
                        resourceList(ResourceStore.configs)
                            .tag(1)
                        customView
                            .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .padding(.bottom, 90) // space for floating tab bar
                }

                // Liquid Glass Tab Bar
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .frame(width: 52, height: 52)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(LinearGradient(colors: [.cyan.opacity(0.6), .blue.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.2)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)

                    Image(systemName: "square.and.arrow.up.on.square.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("QC MODULES")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(.secondary)

                    Text("Modules & Configs")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                }

                Spacer()
            }

            Text("Mở trực tiếp Module và Config sang Shadowrocket bằng URL Scheme.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }

    private var liquidGlassTabBar: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tabs[index].icon)
                            .font(.system(size: 18, weight: .semibold))
                        Text(tabs[index].title)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(selectedTab == index ? .cyan : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        Group {
                            if selectedTab == index {
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                                    )
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                )
                .shadow(color: .black.opacity(0.15), radius: 16, y: 8)
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }

    private func resourceList(_ items: [ResourceItem]) -> some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(items) { item in
                    ResourceCard(item: item) {
                        openResource(item)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .padding(.bottom, 30)
        }
    }

    private var customView: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "link.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .padding(.top, 12)

                    Text("Mở tùy chỉnh")
                        .font(.title2.bold())

                    Text("Nhập URL Module hoặc Config để mở trực tiếp trong Shadowrocket")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Loại")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    Picker("Loại", selection: $customType) {
                        Text("Module").tag(ResourceType.module)
                        Text("Config").tag(ResourceType.config)
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("URL")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    TextField("https://...", text: $customURL)
                        .textFieldStyle(.plain)
                        .padding(14)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
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
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: customURL.isEmpty ? [Color.gray.opacity(0.4)] : [Color.cyan, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: customURL.isEmpty ? .clear : .cyan.opacity(0.35), radius: 10, y: 4)
                }
                .disabled(customURL.isEmpty)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
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
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.ultraThinMaterial)
                        .frame(width: 56, height: 56)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )

                    Image(systemName: item.symbol)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(item.name)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Spacer()

                        Text(item.type.rawValue)
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.ultraThinMaterial)
                            .foregroundStyle(item.type == .module ? .cyan : .orange)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.15), lineWidth: 0.8)
                            )
                    }

                    Text(item.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
    }
}
