import Foundation

/// Protocol for individual toggle service implementations
protocol ToggleServiceProtocol {
    /// The type of toggle this service manages
    var toggleType: ToggleType { get }
    
    /// Check if this toggle is currently enabled
    /// - Returns: Current state of the toggle
    /// - Throws: ToggleError if state cannot be determined
    func isEnabled() async throws -> Bool
    
    /// Enable or disable this toggle
    /// - Parameter enabled: Desired state
    /// - Throws: ToggleError if state cannot be changed
    func setEnabled(_ enabled: Bool) async throws
    
    /// Check if this toggle is available on the current system
    /// - Returns: Whether the toggle can be used
    func isAvailable() async -> Bool
    
    /// Check if the app has permission to use this toggle
    /// - Returns: Whether permission is granted
    func hasPermission() async -> Bool
    
    /// Request permission to use this toggle
    /// - Returns: Whether permission was granted
    func requestPermission() async -> Bool
    
    /// Perform the action (for action-type toggles)
    /// - Throws: ToggleError if action cannot be performed
    func performAction() async throws
}