import SwiftUI

struct ContentView: View {
    @Environment(\.openURL) private var openURL
    @State private var selectedTab = 0
    @State private var customURL = ""
    @State private var customType: ResourceType = .module
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                header
                Picker("", selection: $selectedTab) {
                    Text("Modules").tag(0)
                    Text("Configs").tag(1)
                    Text("Tùy chỉnh").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
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
            }
            .background(Color(uiColor: .systemBackground))
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "square.and.arrow.up.on.square.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 44, height: 44)
                    .background(LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                Spacer()
                Text("QC MODULES")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(2)
                    .foregroundColor(.secondary)
            }
            Text("Modules &\nConfigs")
                .font(.system(size: 32, weight: .bold, design: .rounded))
            Text("Mở trực tiếp sang Shadowrocket bằng URL Scheme.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private func resourceList(_ items: [ResourceItem]) -> some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(items) { item in
                    ResourceCard(item: item) {
                        openResource(item)
                    }
                }
            }
            .padding(20)
        }
    }

    private var customView: some View {
        VStack(spacing: 20) {
            Text("Nhập URL Module hoặc Config của bạn")
                .font(.headline)
                .padding(.top, 20)

            Picker("Loại", selection: $customType) {
                Text("Module").tag(ResourceType.module)
                Text("Config").tag(ResourceType.config)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            TextField("https://raw.githubusercontent.com/...", text: $customURL)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .keyboardType(.URL)
                .padding(.horizontal)

            Button(action: openCustom) {
                Label("Mở trong Shadowrocket", systemImage: "arrow.up.right.square")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.cyan)
                    .foregroundColor(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)
            .disabled(customURL.isEmpty)

            Spacer()
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
            HStack(spacing: 14) {
                Image(systemName: item.symbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.cyan)
                    .frame(width: 48, height: 48)
                    .background(Color.cyan.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(item.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "arrow.up.right.square")
                    .foregroundColor(.cyan)
            }
            .padding(14)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
