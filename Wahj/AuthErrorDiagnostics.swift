//
//  AuthErrorDiagnostics.swift
//  Wahj
//
//  Logs the full details of a Firebase Auth error (domain, code, the
//  underlying error and the server's reply) so problems like
//  "An internal error has occurred" can be traced to their real cause.
//  Emails, passwords, tokens and keys are never logged.
//

import Foundation
import os
import FirebaseAuth

enum AuthErrorDiagnostics {
    private static let logger = Logger(subsystem: "com.ghalaalshreef.wahj", category: "auth")

    // userInfo keys whose values may identify the user or carry secrets.
    private static let sensitiveMarkers = ["email", "password", "token", "credential", "key", "phone", "secret", "id_token"]

    static func log(_ error: Error, operation: String) {
        let text = describe(error)
        logger.error("Auth \(operation, privacy: .public) failed: \(text, privacy: .public)")
        #if DEBUG
        print("[AuthError] \(operation): \(text)")
        #endif
    }

    static func describe(_ error: Error) -> String {
        describe(error as NSError, depth: 0)
    }

    private static func describe(_ error: NSError, depth: Int) -> String {
        var parts = ["domain=\(error.domain)", "code=\(error.code)"]
        if error.domain == AuthErrorDomain, let name = AuthErrorCode(rawValue: error.code).map({ "\($0)" }) {
            parts.append("authCode=\(name)")
        }
        parts.append("description=\(error.localizedDescription)")

        // What Firebase's server actually answered (e.g. CONFIGURATION_NOT_FOUND).
        if let response = error.userInfo["FIRAuthErrorUserInfoDeserializedResponseKey"] {
            parts.append("serverResponse=\(redact(response))")
        }
        if let underlying = error.userInfo[NSUnderlyingErrorKey] as? NSError, depth < 3 {
            parts.append("underlying={\(describe(underlying, depth: depth + 1))}")
        }
        let otherKeys = error.userInfo.keys
            .filter { $0 != NSUnderlyingErrorKey && $0 != NSLocalizedDescriptionKey
                && $0 != "FIRAuthErrorUserInfoDeserializedResponseKey" && !isSensitive($0) }
            .sorted()
        if !otherKeys.isEmpty {
            parts.append("otherKeys=\(otherKeys.joined(separator: ","))")
        }
        return parts.joined(separator: " ")
    }

    private static func isSensitive(_ key: String) -> Bool {
        let lower = key.lowercased()
        return sensitiveMarkers.contains { lower.contains($0) }
    }

    // Keeps the server's message and error reasons, drops anything sensitive.
    private static func redact(_ value: Any) -> String {
        if let dict = value as? [String: Any] {
            let safe = dict.filter { !isSensitive($0.key) }
                .map { "\($0.key): \(redact($0.value))" }
                .sorted()
            return "{" + safe.joined(separator: ", ") + "}"
        }
        if let array = value as? [Any] {
            return "[" + array.map(redact).joined(separator: ", ") + "]"
        }
        let text = "\(value)"
        // Never echo anything that looks like an email address.
        return text.contains("@") ? "<redacted>" : text
    }
}
