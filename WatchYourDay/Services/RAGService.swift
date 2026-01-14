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
        
        // 1. Get Statistical Summary (The "Big Picture")
        // Always fetch this to prevent "tunnel vision" on just a few vector chunks
        let statsContext = try await buildContextFromSnapshots(modelContext: modelContext)
        
        // 2. Embed the query & Search (The "Details")
        var vectorContext = ""
        do {
            let queryEmbedding = try await EmbeddingService.shared.embed(text: userQuery)
            let searchResults = try await VectorStore.shared.searchSimilar(
                queryEmbedding: queryEmbedding,
                limit: 10 // Increased from 5 to 10 for better coverage
            )
            
            if !searchResults.isEmpty {
                vectorContext = "\nDetailed Semantic Matches:\n"
                for (index, result) in searchResults.enumerated() {
                    vectorContext += "\(index + 1). \(result.text)\n"
                }
            }
        } catch {
            WDLogger.error("RAG: Embedding/Search failed - \(error.localizedDescription)", category: .ai)
            // Continue with just statsContext
        }
        
        // 3. Combine Contexts
        let finalContext = """
        \(statsContext)
        
        \(vectorContext)
        """
        
        // 4. Generate response
        let prompt = """
        You are a smart Personal Activity Analyst. 
        Your goal is to explain what the user has been doing based on the provided data.
        
        DATA SOURCE 1: STATISTICS (Global Overview)
        \(statsContext)
        
        DATA SOURCE 2: SEMANTIC SEARCH (Specific Details)
        \(vectorContext)
        
        User Question: \(userQuery)
        
        INSTRUCTIONS:
        - Use the STATISTICS to give a high-level summary (e.g. "You spent 2 hours coding...").
        - Use the SEMANTIC SEARCH to add specific details (e.g. "...specifically working on RAGService.swift").
        - If the user asks for "all activities", rely heavily on the STATISTICS.
        - Be concise, professional, and helpful.
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
        // Use StatsService for accurate duration calculation
        // This ensures the numbers match what the user sees in the Dashboard
        let today = Date()
        
        guard let stats = await StatsService.shared.calculateReportingData(for: today) else {
             return "No activity data recorded today."
        }
        
        var context = "Today's Activity Summary (\(today.formatted(date: .abbreviated, time: .omitted))):\n"
        context += "Total Time Recorded: \(stats.totalMinutes) minutes\n"
        context += String(format: "Focus Score: %.1f%%\n\n", stats.focusScore)
        
        context += "Top Applications (by duration):\n"
        for (app, minutes) in stats.categoryCounts.sorted(by: { $0.value > $1.value }).prefix(10) {
             context += "- \(app): \(minutes) minutes\n"
        }
        
        // Also add top 5 apps list specifically for clarity
        context += "\nMost Used Apps: " + stats.topApps.joined(separator: ", ") + "\n"
        
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
