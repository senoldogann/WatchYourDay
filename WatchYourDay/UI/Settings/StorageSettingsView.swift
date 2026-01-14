import SwiftUI
import SwiftData

struct StorageSettingsView: View {
    @State private var showingClearConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "internaldrive")
                    .foregroundStyle(Color.claudeAccent)
                Text("STORAGE")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.claudeSecondaryAccent)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Snapshots")
                        .font(.caption)
                        .foregroundStyle(Color.gray)
                    Text("Calculated dynamically") // Placeholder
                        .font(.headline)
                        .foregroundStyle(Color.claudeTextPrimary)
                }
                Spacer()
            }
            
            Button("Clear All Data") {
                showingClearConfirmation = true
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)
            .alert("Clear All Data?", isPresented: $showingClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    let context = PersistenceController.shared.container.mainContext
                    try? context.delete(model: Snapshot.self)
                    // Also clear images? This is a deeper op, for now DB clear is main.
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
        .padding()
        .background(Color.claudeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
