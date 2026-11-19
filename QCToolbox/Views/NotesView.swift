import SwiftUI

struct NotesView: View {
    @AppStorage("qc.toolbox.notes") private var notes = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ghi chú của bạn")
                .font(.title2.bold())
            Text("Nội dung được lưu tự động trên iPhone này.")
                .font(.caption)
                .foregroundColor(.secondary)
            TextEditor(text: $notes)
                .padding(8)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            HStack {
                Label("Lưu tự động", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Spacer()
                Text("\(notes.count) ký tự")
                    .foregroundColor(.secondary)
            }
            .font(.caption)
            Spacer()
        }
        .padding(20)
        .navigationTitle("Ghi chú")
    }
}
