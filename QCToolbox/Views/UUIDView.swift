import SwiftUI

struct UUIDView: View {
    @State private var value = UUID().uuidString
    @State private var copied = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "number.circle.fill")
                .font(.system(size: 58))
                .foregroundColor(.cyan)
            Text("UUID ngẫu nhiên")
                .font(.title2.bold())
            Text(value)
                .font(.system(.body, design: .monospaced))
                .multilineTextAlignment(.center)
                .textSelection(.enabled)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            Button {
                UIPasteboard.general.string = value
                copied = true
            } label: {
                Label(copied ? "Đã sao chép" : "Sao chép UUID", systemImage: copied ? "checkmark" : "doc.on.doc")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            Button {
                value = UUID().uuidString
                copied = false
            } label: {
                Label("Tạo mã mới", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            Spacer()
        }
        .padding(20)
        .navigationTitle("Tạo UUID")
    }
}
