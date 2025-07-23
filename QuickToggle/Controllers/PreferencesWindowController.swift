import Cocoa
import SwiftUI
import os.log

class PreferencesWindowController: NSWindowController {
    
    // Singleton instance
    private static var shared: PreferencesWindowController?
    
    // MARK: - Initialization
    
    convenience init() {
        let preferencesView = PreferencesView()
        let hostingController = NSHostingController(rootView: preferencesView)
        
        // Create window
        let window = NSWindow(contentViewController: hostingController)
        window.title = "QuickToggle Preferences"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.center()
        window.setFrameAutosaveName("PreferencesWindow")
        
        // Set window properties
        window.isReleasedWhenClosed = false
        window.level = .floating
        
        self.init(window: window)
        
        Logger.preferences.info("PreferencesWindowController initialized")
    }
    
    // MARK: - Public Methods
    
    static func showPreferences() {
        if shared == nil {
            shared = PreferencesWindowController()
        }
        
        guard let controller = shared else { return }
        
        // Show window
        controller.showWindow(nil)
        
        // Bring to front
        NSApp.activate(ignoringOtherApps: true)
        controller.window?.makeKeyAndOrderFront(nil)
        
        Logger.preferences.info("Showing preferences window")
    }
    
    // MARK: - NSWindowController Overrides
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Additional window setup if needed
    }
    
    // MARK: - NSWindowDelegate
    
    func windowWillClose(_ notification: Notification) {
        Logger.preferences.debug("Preferences window will close")
    }
}