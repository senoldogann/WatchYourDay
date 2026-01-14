import Foundation

/// Centralized service for Privacy & PII (Personally Identifiable Information) protection.
/// Ensures sensitive data is scrubbed before leaving the device or being logged.
struct PrivacyGuard {
    static let shared = PrivacyGuard()
    
    // Centralized Sensitive Patterns
    // Public so other services (like Redactor) can access the raw patterns if needed for Vision API
    let sensitivePatterns: [String] = [
        #"\b\d{4}[ -]?\d{4}[ -]?\d{4}[ -]?\d{4}\b"#, // Credit Card formatting
        #"\bTR\d{2}[ ]?\d{4}[ ]?\d{4}[ ]?\d{4}[ ]?\d{2}\b"#, // TR IBAN
        #"(?i)password"#,
        #"(?i)parola"#,
        #"(?i)şifre"#,
        #"(?i)api key"#,
        #"(?i)bearer"#,
        #"(?i)secret"#,
        #"(?i)private key"#,
        #"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}"# // Email
    ]
    
    // Cached Regex Objects
    private let compiledRegexes: [NSRegularExpression]
    
    private init() {
        self.compiledRegexes = sensitivePatterns.compactMap { pattern in
            try? NSRegularExpression(pattern: pattern, options: [])
        }
    }
    
    /// Scrubs sensitive information from a text string.
    /// - Parameter text: The raw text that might contain PII.
    /// - Returns: Sanitized text with PII replaced by [REDACTED].
    func scrub(_ text: String) -> String {
        var scrubbedText = text
        let range = NSRange(location: 0, length: scrubbedText.utf16.count)
        
        for regex in compiledRegexes {
            scrubbedText = regex.stringByReplacingMatches(in: scrubbedText, options: [], range: range, withTemplate: "[REDACTED]")
        }
        return scrubbedText
    }
    
    /// Checks if the text contains any probable PII.
    func containsPII(_ text: String) -> Bool {
        let range = NSRange(location: 0, length: text.utf16.count)
        for regex in compiledRegexes {
            if regex.firstMatch(in: text, options: [], range: range) != nil {
                return true
            }
        }
        return false
    }
}
