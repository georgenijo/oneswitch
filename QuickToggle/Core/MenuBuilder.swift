import Cocoa
import os.log

class MenuBuilder {
    private weak var target: AnyObject?
    
    init(target: AnyObject? = nil) {
        self.target = target
    }
    
    func buildMenu(with toggles: [Toggle]) -> NSMenu {
        Logger.menuBar.debug("Building menu with \(toggles.count) toggles")
        
        let menu = NSMenu()
        
        // Add header
        let headerItem = NSMenuItem(title: Constants.App.appName, action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        menu.addItem(NSMenuItem.separator())
        
        // Group toggles by type
        let (toggleItems, actionItems) = toggles.partition { !$0.type.isAction }
        
        // Add toggle items
        if !toggleItems.isEmpty {
            for toggle in toggleItems {
                let menuItem = createToggleMenuItem(for: toggle)
                menu.addItem(menuItem)
            }
            menu.addItem(NSMenuItem.separator())
        }
        
        // Add action items
        if !actionItems.isEmpty {
            for action in actionItems {
                let menuItem = createActionMenuItem(for: action)
                menu.addItem(menuItem)
            }
            menu.addItem(NSMenuItem.separator())
        }
        
        // Add system items
        addSystemItems(to: menu)
        
        return menu
    }
    
    private func createToggleMenuItem(for toggle: Toggle) -> NSMenuItem {
        let menuItem = NSMenuItem(
            title: toggle.title,
            action: #selector(MenuBarController.toggleClicked(_:)),
            keyEquivalent: getKeyEquivalent(for: toggle.type)
        )
        
        menuItem.target = target
        menuItem.representedObject = toggle
        menuItem.state = toggle.isEnabled ? .on : .off
        menuItem.isEnabled = toggle.isAvailable
        
        if let image = NSImage(systemSymbolName: toggle.iconName, accessibilityDescription: toggle.title) {
            menuItem.image = image
        }
        
        return menuItem
    }
    
    private func createActionMenuItem(for action: Toggle) -> NSMenuItem {
        let menuItem = NSMenuItem(
            title: action.title,
            action: #selector(MenuBarController.actionClicked(_:)),
            keyEquivalent: getKeyEquivalent(for: action.type)
        )
        
        menuItem.target = target
        menuItem.representedObject = action
        menuItem.isEnabled = action.isAvailable
        
        if let image = NSImage(systemSymbolName: action.iconName, accessibilityDescription: action.title) {
            menuItem.image = image
        }
        
        return menuItem
    }
    
    private func addSystemItems(to menu: NSMenu) {
        // Preferences
        let preferencesItem = NSMenuItem(
            title: "Preferences...",
            action: #selector(MenuBarController.openPreferences),
            keyEquivalent: ","
        )
        preferencesItem.target = target
        menu.addItem(preferencesItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(
            title: "Quit \(Constants.App.appName)",
            action: #selector(MenuBarController.quit),
            keyEquivalent: "q"
        )
        quitItem.target = target
        menu.addItem(quitItem)
    }
    
    private func getKeyEquivalent(for toggleType: ToggleType) -> String {
        switch toggleType {
        case .darkMode: return "d"
        case .keepAwake: return "k"
        case .screenLock: return "l"
        default: return ""
        }
    }
}

