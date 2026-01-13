import Foundation
import Security

/// Thread-safe Keychain Manager for secure credential storage
/// Uses macOS Keychain Services API for enterprise-grade security
struct KeychainManager {
    static let service = "com.senoldogan.WatchYourDay.credentials"
    
    enum KeychainError: Error, LocalizedError {
        case duplicateEntry
        case unknown(OSStatus)
        case notFound
        case unexpectedData
        case encodingFailed
        
        var errorDescription: String? {
            switch self {
            case .duplicateEntry: return "Keychain entry already exists"
            case .unknown(let status): return "Keychain error: \(status)"
            case .notFound: return "Keychain item not found"
            case .unexpectedData: return "Unexpected keychain data format"
            case .encodingFailed: return "Failed to encode data"
            }
        }
    }
    
    // MARK: - Core Operations
    
    /// Save data to Keychain (thread-safe, upsert behavior)
    static func save(key: String, data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing first (upsert pattern)
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
    }
    
    /// Load data from Keychain
    static func load(key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecItemNotFound {
            throw KeychainError.notFound
        }
        
        guard status == errSecSuccess, let data = dataTypeRef as? Data else {
            throw KeychainError.unknown(status)
        }
        
        return data
    }
    
    /// Delete item from Keychain
    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Convenience Methods
    
    /// Save string to Keychain
    static func saveString(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        try save(key: key, data: data)
    }
    
    /// Load string from Keychain (returns nil if not found, logs other errors)
    static func loadString(key: String) -> String? {
        do {
            let data = try load(key: key)
            return String(data: data, encoding: .utf8)
        } catch KeychainError.notFound {
            return nil
        } catch {
            WDLogger.error("Keychain error for key '\(key)': \(error.localizedDescription)", category: .general)
            return nil
        }
    }
}
