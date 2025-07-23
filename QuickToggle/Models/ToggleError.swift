import Foundation

/// Errors that can occur during toggle operations
enum ToggleError: LocalizedError {
    case notSupported(ToggleType)
    case permissionDenied(ToggleType)
    case systemError(Error)
    case timeout
    case invalidState
    case unknown
    case operationFailed
    
    var errorDescription: String? {
        switch self {
        case .notSupported(let type):
            return "\(type.displayName) is not supported on this system"
        case .permissionDenied(let type):
            return "Permission denied for \(type.displayName). Please check System Preferences."
        case .systemError(let error):
            return "System error: \(error.localizedDescription)"
        case .timeout:
            return "Operation timed out"
        case .invalidState:
            return "Invalid state for this operation"
        case .unknown:
            return "An unknown error occurred"
        case .operationFailed:
            return "The operation failed to complete"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return "Grant permission in System Preferences > Security & Privacy"
        case .notSupported:
            return "This feature requires a newer version of macOS or different hardware"
        default:
            return nil
        }
    }
}