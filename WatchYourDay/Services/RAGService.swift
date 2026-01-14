//
//  RAGService.swift
//  WatchYourDay
//

import Foundation
import SwiftData

/// Orchestrates the RAG pipeline: Query → Embed → Retrieve → Generate
actor RAGService {
    static let shared = RAGService()
    
    private init() {}
    
    // MARK: - Query with Context
    func query(_ userQuery: String, modelContext: ModelContext) async throws -> String {
        WDLogger.info("RAG: Processing query: \(userQuery)", category: .ai)
        
        // 1. Embed the query
        let queryEmbedding: [Float]
        do {
            queryEmbedding = try await EmbeddingService.shared.embed(text: userQuery)
        } catch {
            WDLogger.error("RAG: Failed to embed query - \(error.localizedDescription)", category: .ai)
            // Fallback: Use regular AI without RAG
            return try await fallbackQuery(userQuery, modelContext: modelContext)
        }
        
        // 2. Search for similar documents
        let searchResults = try await VectorStore.shared.searchSimilar(
            queryEmbedding: queryEmbedding,
            limit: 5
        )
        
        WDLogger.info("RAG: Found \(searchResults.count) relevant documents", category: .ai)
        
        // 3. Build context from results
        var context = ""
        if !searchResults.isEmpty {
            context = "Here is relevant information from the user's activity history:\n\n"
            for (index, result) in searchResults.enumerated() {
                context += "\(index + 1). \(result.text)\n"
            }
            context += "\n"
        } else {
            // No embeddings - use snapshot data directly
            context = try await buildContextFromSnapshots(modelContext: modelContext)
        }
        
        // 4. Generate response with context
        let prompt = """
        You are a helpful assistant that answers questions about the user's computer activity.
        
        \(context)
        
        User Question: \(userQuery)
        
        Please provide a helpful, concise answer based on the activity data above.
        If you don't have enough information, say so politely.
        """
        
        // 5. Call LLM
        return try await generateResponse(prompt: prompt)
    }
    
    // MARK: - Fallback Query (No Embeddings)
    private func fallbackQuery(_ userQuery: String, modelContext: ModelContext) async throws -> String {
        WDLogger.info("RAG: Using fallback mode (no embeddings)", category: .ai)
        
        // Get today's snapshots directly
        let context = try await buildContextFromSnapshots(modelContext: modelContext)
        
        let prompt = """
        You are a helpful assistant that answers questions about the user's computer activity.
        
        \(context)
        
        User Question: \(userQuery)
        
        Please provide a helpful, concise answer based on the activity data above.
        """
        
        return try await generateResponse(prompt: prompt)
    }
    
    // MARK: - Build Context from Snapshots
    private func buildContextFromSnapshots(modelContext: ModelContext) async throws -> String {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = #Predicate<Snapshot> { $0.timestamp >= startOfDay }
        let descriptor = FetchDescriptor<Snapshot>(predicate: predicate)
        
        let snapshots = try modelContext.fetch(descriptor)
        
        guard !snapshots.isEmpty else {
            return "No activity data recorded today."
        }
        
        // Aggregate by app
        var appCounts: [String: Int] = [:]
        var windowTitles: [String: Set<String>] = [:]
        
        for s in snapshots {
            appCounts[s.appName, default: 0] += 1
            if !s.windowTitle.isEmpty {
                windowTitles[s.appName, default: []].insert(s.windowTitle)
            }
        }
        
        // Build context
        var context = "Today's Activity Summary:\n"
        context += "Total snapshots: \(snapshots.count)\n\n"
        
        context += "Applications used (sorted by time):\n"
        for (app, count) in appCounts.sorted(by: { $0.value > $1.value }).prefix(10) {
            let minutes = count // Each snapshot ≈ 1 minute
            context += "- \(app): \(minutes) minutes\n"
            
            if let titles = windowTitles[app]?.prefix(3) {
                for title in titles {
                    context += "  • \(title)\n"
                }
            }
        }
        
        return context
    }
    
    // MARK: - Generate Response
    private func generateResponse(prompt: String) async throws -> String {
        return try await AIService.shared.generateResponse(prompt: prompt)
    }
    
    // MARK: - Index Snapshot (for embedding new data)
    func indexSnapshot(_ snapshot: Snapshot) async {
        // Build text representation
        let text = "\(snapshot.appName): \(snapshot.windowTitle) (\(snapshot.timestamp.formatted()))"
        
        do {
            let embedding = try await EmbeddingService.shared.embed(text: text)
            try await VectorStore.shared.insertEmbedding(
                snapshotId: snapshot.id.uuidString,
                text: text,
                embedding: embedding
            )
            WDLogger.debug("RAG: Indexed snapshot \(snapshot.id)", category: .ai)
        } catch {
            // Silently fail - embedding is optional
            WDLogger.debug("RAG: Failed to index snapshot - \(error.localizedDescription)", category: .ai)
        }
    }
}

// MARK: - Errors
enum RAGError: Error, LocalizedError {
    case embeddingFailed
    case llmFailed
    
    var errorDescription: String? {
        switch self {
        case .embeddingFailed:
            return "Failed to generate embedding"
        case .llmFailed:
            return "Failed to get response from LLM"
        }
    }
}
