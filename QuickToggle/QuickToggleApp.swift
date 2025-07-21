import SwiftUI
import os.log

@main
struct QuickToggleApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarController: MenuBarController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        Logger.app.info("QuickToggle launching")
        
        // Register real services
        registerServices()
        
        // Initialize menu bar
        menuBarController = MenuBarController()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        Logger.app.info("QuickToggle terminating")
        
        // Stop all services
        Task {
            await ToggleServiceManager.shared.stopAllServices()
        }
        
        menuBarController = nil
    }
    
    @MainActor
    private func registerServices() {
        Logger.app.info("Registering toggle services")
        
        // Register Dark Mode service
        let darkModeService = DarkModeService()
        ToggleServiceManager.shared.register(darkModeService, for: .darkMode)
        
        // Register Hide Desktop Icons service
        let hideDesktopIconsService = HideDesktopIconsService()
        ToggleServiceManager.shared.register(hideDesktopIconsService, for: .desktopIcons)
        
        // Register Keep Awake service
        let keepAwakeService = KeepAwakeService()
        ToggleServiceManager.shared.register(keepAwakeService, for: .keepAwake)
        
        // Register Screen Lock service (action)
        let screenLockService = ScreenLockService()
        ToggleServiceManager.shared.register(screenLockService, for: .screenLock)
        
        // Register Empty Trash service (action)
        let emptyTrashService = EmptyTrashService()
        ToggleServiceManager.shared.register(emptyTrashService, for: .emptyTrash)
        
        // Future services will be registered here
    }
}