import SwiftUI

struct Base64View: View {
    @State private var input = ""
    @State private var output = ""
    @State private var mode = 0
    @State private var error = ""

    var body: some View {
        Form {
            Section {
                Picker("Chế độ", selection: $mode) {
                    Text("Mã hóa").tag(0)
                    Text("Giải mã").tag(1)
                }
                .pickerStyle(.segmented)
                TextEditor(text: $input)
                    .frame(minHeight: 150)
                    .overlay(alignment: .topLeading) {
                        if input.isEmpty {
                            Text(mode == 0 ? "Nhập văn bản cần mã hóa…" : "Nhập chuỗi Base64…")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }
            } header: { Text("Nội dung đầu vào") }

            Section {
                Button(mode == 0 ? "Mã hóa Base64" : "Giải mã Base64") { convert() }
                    .disabled(input.isEmpty)
                if !error.isEmpty {
                    Text(error).foregroundColor(.red)
                }
                TextEditor(text: $output)
                    .frame(minHeight: 150)
                    .textSelection(.enabled)
                Button {
                    UIPasteboard.general.string = output
                } label: {
                    Label("Sao chép kết quả", systemImage: "doc.on.doc")
                }
                .disabled(output.isEmpty)
            } header: { Text("Kết quả") }
        }
        .navigationTitle("Base64")
    }

    private func convert() {
        error = ""
        if mode == 0 {
            output = Data(input.utf8).base64EncodedString()
        } else if let data = Data(base64Encoded: input),
                  let decoded = String(data: data, encoding: .utf8) {
            output = decoded
        } else {
            output = ""
            error = "Chuỗi Base64 không hợp lệ hoặc không phải văn bản UTF-8."
        }
    }
}
