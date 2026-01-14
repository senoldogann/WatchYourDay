//
//  VectorStore.swift
//  WatchYourDay
//
//  Phase 2: RAG - Vector Store for Semantic Search
//

import Foundation
import SQLite3

/// Stores embeddings and performs similarity search
actor VectorStore {
    static let shared = VectorStore()
    
    private var db: OpaquePointer?
    private let dbPath: String
    
    private var initTask: Task<Void, Never>?
    
    private init() {
        // Store in Application Support
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("WatchYourDay", isDirectory: true)
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        
        self.dbPath = appFolder.appendingPathComponent("embeddings.sqlite").path
        
        self.initTask = Task {
            await initializeDatabase()
        }
    }
    
    /// Waits for database initialization to complete
    private func ensureReady() async {
        _ = await initTask?.result
    }
    
    // MARK: - Database Setup
    private func initializeDatabase() {
        guard sqlite3_open(dbPath, &db) == SQLITE_OK else {
            WDLogger.error("VectorStore: Failed to open database", category: .ai)
            return
        }
        
        let createTable = """
        CREATE TABLE IF NOT EXISTS embeddings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            snapshot_id TEXT NOT NULL,
            text TEXT NOT NULL,
            embedding BLOB NOT NULL,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(snapshot_id)
        );
        CREATE INDEX IF NOT EXISTS idx_timestamp ON embeddings(timestamp);
        """
        
        var errorMessage: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, createTable, nil, nil, &errorMessage) != SQLITE_OK {
            let error = errorMessage.map { String(cString: $0) } ?? "Unknown error"
            WDLogger.error("VectorStore: Failed to create table - \(error)", category: .ai)
            sqlite3_free(errorMessage)
        } else {
            WDLogger.info("VectorStore: Database initialized at \(dbPath)", category: .ai)
        }
    }
    
    // MARK: - Insert Embedding
    func insertEmbedding(snapshotId: String, text: String, embedding: [Float]) async throws {
        await ensureReady()
        guard let db = db else { throw VectorStoreError.databaseNotOpen }
        
        let sql = "INSERT OR REPLACE INTO embeddings (snapshot_id, text, embedding) VALUES (?, ?, ?)"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw VectorStoreError.prepareFailed
        }
        
        defer { sqlite3_finalize(statement) }
        
        // Bind parameters
        sqlite3_bind_text(statement, 1, snapshotId, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_text(statement, 2, text, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        
        // Convert [Float] to Data (BLOB)
        let embeddingData = embedding.withUnsafeBufferPointer { Data(buffer: $0) }
        embeddingData.withUnsafeBytes { rawBuffer in
            sqlite3_bind_blob(statement, 3, rawBuffer.baseAddress, Int32(embeddingData.count), nil)
        }
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw VectorStoreError.insertFailed
        }
        
        WDLogger.debug("VectorStore: Inserted embedding for \(snapshotId)", category: .ai)
    }
    
    // MARK: - Search Similar
    func searchSimilar(queryEmbedding: [Float], limit: Int = 5) async throws -> [SearchResult] {
        await ensureReady()
        guard let db = db else { throw VectorStoreError.databaseNotOpen }
        
        // Performance Note: Currently using basic SQL fetch with LIMIT to avoid O(N) scan.
        // For production scaling (>10k vectors) with high recall, consider integrating `sqlite-vec` or a dedicated vector DB.
        let sql = "SELECT snapshot_id, text, embedding FROM embeddings ORDER BY timestamp DESC LIMIT 1000"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw VectorStoreError.prepareFailed
        }
        
        defer { sqlite3_finalize(statement) }
        
        var results: [(snapshotId: String, text: String, similarity: Float)] = []
        
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let snapshotIdPtr = sqlite3_column_text(statement, 0),
                  let textPtr = sqlite3_column_text(statement, 1) else { continue }
            
            let snapshotId = String(cString: snapshotIdPtr)
            let text = String(cString: textPtr)
            
            // Get embedding blob
            let blobSize = sqlite3_column_bytes(statement, 2)
            guard let blobPtr = sqlite3_column_blob(statement, 2) else { continue }
            
            let data = Data(bytes: blobPtr, count: Int(blobSize))
            let embedding = data.withUnsafeBytes { buffer in
                Array(buffer.bindMemory(to: Float.self))
            }
            
            // Calculate cosine similarity
            let similarity = cosineSimilarity(queryEmbedding, embedding)
            results.append((snapshotId, text, similarity))
        }
        
        // Sort by similarity (descending) and return top K
        let topResults = results
            .sorted { $0.similarity > $1.similarity }
            .prefix(limit)
            .map { SearchResult(snapshotId: $0.snapshotId, text: $0.text, similarity: $0.similarity) }
        
        return topResults
    }
    
    // MARK: - Cosine Similarity
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        
        var dotProduct: Float = 0
        var normA: Float = 0
        var normB: Float = 0
        
        for i in 0..<a.count {
            dotProduct += a[i] * b[i]
            normA += a[i] * a[i]
            normB += b[i] * b[i]
        }
        
        let denominator = sqrt(normA) * sqrt(normB)
        return denominator > 0 ? dotProduct / denominator : 0
    }
    
    // MARK: - Stats
    func getEmbeddingCount() async -> Int {
        await ensureReady()
        guard let db = db else { return 0 }
        
        let sql = "SELECT COUNT(*) FROM embeddings"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return 0 }
        defer { sqlite3_finalize(statement) }
        
        if sqlite3_step(statement) == SQLITE_ROW {
            return Int(sqlite3_column_int(statement, 0))
        }
        return 0
    }
}

// MARK: - Supporting Types
struct SearchResult {
    let snapshotId: String
    let text: String
    let similarity: Float
}

enum VectorStoreError: Error {
    case databaseNotOpen
    case prepareFailed
    case insertFailed
}
