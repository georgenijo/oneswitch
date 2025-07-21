import Foundation

struct Constants {
    struct App {
        static let bundleIdentifier = "dev.quicktoggle.app"
        static let appName = "QuickToggle"
        static let minimumMacOSVersion = 11.0
    }
    
    struct MenuBar {
        static let iconName = "switch.2"
        static let iconAccessibilityDescription = "QuickToggle Menu"
    }
    
    struct UserDefaults {
        static let firstLaunchKey = "hasLaunchedBefore"
        static let enabledTogglesKey = "enabledToggles"
        static let toggleOrderKey = "toggleOrder"
        static let launchAtLoginKey = "launchAtLogin"
    }
    
    struct Notifications {
        static let toggleStateChanged = Notification.Name("toggleStateChanged")
        static let preferencesChanged = Notification.Name("preferencesChanged")
    }
}