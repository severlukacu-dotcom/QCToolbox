import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct QRView: View {
    @State private var text = ""
    @State private var image: UIImage?
    @State private var showShare = false
    private let context = CIContext()

    var body: some View {
        VStack(spacing: 18) {
            TextField("Nhập văn bản hoặc đường dẫn…", text: $text)
                .textFieldStyle(.roundedBorder)
            Button("Tạo mã QR") { generate() }
                .buttonStyle(.borderedProminent)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            if let image {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 260)
                    .padding(18)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                Button {
                    showShare = true
                } label: {
                    Label("Chia sẻ mã QR", systemImage: "square.and.arrow.up")
                }
                .sheet(isPresented: $showShare) {
                    ActivityView(activityItems: [image])
                }
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "qrcode").font(.system(size: 44))
                    Text("Chưa có mã QR").font(.headline)
                    Text("Nhập nội dung rồi chọn Tạo mã QR.")
                        .font(.caption).foregroundColor(.secondary)
                }
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, minHeight: 180)
            }
            Spacer()
        }
        .padding(20)
        .navigationTitle("Tạo mã QR")
    }

    private func generate() {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else {
            image = nil
            return
        }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else {
            image = nil
            return
        }
        image = UIImage(cgImage: cgImage)
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
