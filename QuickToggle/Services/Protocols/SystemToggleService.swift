import Foundation

/// Protocol for services that manage system toggles
protocol SystemToggleService {
    /// Get the current state of a toggle
    /// - Parameter type: The toggle type to check
    /// - Returns: The current enabled state
    /// - Throws: ToggleError if the operation fails
    func getCurrentState(for type: ToggleType) async throws -> Bool
    
    /// Set the state of a toggle
    /// - Parameters:
    ///   - enabled: The desired state
    ///   - type: The toggle type to modify
    /// - Throws: ToggleError if the operation fails
    func setState(_ enabled: Bool, for type: ToggleType) async throws
    
    /// Check if a toggle is available on this system
    /// - Parameter type: The toggle type to check
    /// - Returns: Whether the toggle is supported
    func isAvailable(for type: ToggleType) async -> Bool
    
    /// Check if the app has permission to modify a toggle
    /// - Parameter type: The toggle type to check
    /// - Returns: Whether permission is granted
    func hasPermission(for type: ToggleType) async -> Bool
}