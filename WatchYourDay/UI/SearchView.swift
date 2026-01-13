import SwiftUI
import SwiftData

struct SearchView: View {
    @State private var searchText: String = ""
    @Binding var selectedSnapshot: Snapshot?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .foregroundStyle(Color.claudeAccent)
                
                Text("INTELLIGENT SEARCH")
                    .font(.headline)
                    .foregroundStyle(Color.claudeTextPrimary)
                
                Spacer()
            }
            .padding()
            .background(Color.claudeBackground)
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.gray)
                
                TextField("Search screen text (OCR)...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.title3)
            }
            .padding()
            .background(Color.claudeSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            .padding(.bottom)
            
            // Results
            if searchText.isEmpty {
                emptyState
            } else {
                SearchResultsView(searchText: searchText, selectedSnapshot: $selectedSnapshot)
            }
        }
        .background(Color.claudeBackground)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(Color.gray.opacity(0.3))
            
            Text("Type to search your history")
                .font(.title3)
                .foregroundStyle(Color.gray)
            
            Text("WatchYourDay indexes text on your screen.\nSearch for keywords, code snippets, or conversations.")
                .multilineTextAlignment(.center)
                .font(.caption)
                .foregroundStyle(Color.gray.opacity(0.7))
                .frame(maxWidth: 300)
            
            Spacer()
        }
    }
}

private struct SearchResultsView: View {
    @Query var snapshots: [Snapshot]
    @Binding var selectedSnapshot: Snapshot?
    
    init(searchText: String, selectedSnapshot: Binding<Snapshot?>) {
        _selectedSnapshot = selectedSnapshot
        // Predicate to match OCR text OR App Name OR Window Title
        let p = #Predicate<Snapshot> {
            $0.ocrText.localizedStandardContains(searchText) ||
            $0.appName.localizedStandardContains(searchText) ||
            $0.windowTitle.localizedStandardContains(searchText)
        }
        _snapshots = Query(filter: p, sort: \.timestamp, order: .reverse)
    }
    
    var body: some View {
        if snapshots.isEmpty {
            VStack {
                Spacer()
                Text("No matches found.")
                    .foregroundStyle(Color.gray)
                Spacer()
            }
        } else {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 16) {
                    ForEach(snapshots) { snapshot in
                        SnapshotThumbnail(snapshot: snapshot) {
                            selectedSnapshot = snapshot
                        }
                    }
                }
                .padding()
            }
        }
    }
}
