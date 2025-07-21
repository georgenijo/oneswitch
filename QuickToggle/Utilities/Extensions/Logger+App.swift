import os.log

extension Logger {
    /// Main logger for QuickToggle app
    static let app = Logger(subsystem: Constants.App.bundleIdentifier, category: "QuickToggle")
    
    /// Logger for menu bar related operations
    static let menuBar = Logger(subsystem: Constants.App.bundleIdentifier, category: "MenuBar")
    
    /// Logger for toggle services
    static let toggles = Logger(subsystem: Constants.App.bundleIdentifier, category: "Toggles")
    
    /// Logger for preferences
    static let preferences = Logger(subsystem: Constants.App.bundleIdentifier, category: "Preferences")
}