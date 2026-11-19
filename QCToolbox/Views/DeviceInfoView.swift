import SwiftUI

struct DeviceInfoView: View {
    var body: some View {
        List {
            Section {
                ForEach(Array(DeviceInfo.rows.enumerated()), id: \.offset) { _, row in
                    HStack {
                        Text(row.0).foregroundColor(.secondary)
                        Spacer()
                        Text(row.1)
                            .multilineTextAlignment(.trailing)
                            .textSelection(.enabled)
                    }
                    .padding(.vertical, 3)
                }
            } header: {
                Text("Thông tin cơ bản")
            } footer: {
                Text("Mã model là định danh phần cứng công khai (ví dụ iPhone…); không phải UDID hoặc số serial.")
            }
        }
        .navigationTitle("Thiết bị")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    UIPasteboard.general.string = DeviceInfo.rows.map { "\($0.0): \($0.1)" }.joined(separator: "\n")
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .accessibilityLabel("Sao chép thông tin")
            }
        }
    }
}
