import Cocoa
import os.log

@MainActor
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
        
        // Add submenu for Bluetooth to show devices
        if toggle.type == .bluetooth, 
           let service = ToggleServiceManager.shared.service(for: .bluetooth) as? BluetoothService {
            menuItem.submenu = createBluetoothSubmenu(for: service)
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
    
    private func createBluetoothSubmenu(for service: BluetoothService) -> NSMenu {
        let submenu = NSMenu()
        
        // Add toggle item at top
        let toggleItem = NSMenuItem(
            title: service.currentState ? "Turn Bluetooth Off" : "Turn Bluetooth On",
            action: #selector(MenuBarController.toggleClicked(_:)),
            keyEquivalent: ""
        )
        toggleItem.target = target
        toggleItem.representedObject = Toggle(type: .bluetooth)
        submenu.addItem(toggleItem)
        submenu.addItem(NSMenuItem.separator())
        
        // Get paired devices
        let devices = service.getPairedDevices()
        
        if devices.isEmpty {
            let noDevicesItem = NSMenuItem(title: "No Paired Devices", action: nil, keyEquivalent: "")
            noDevicesItem.isEnabled = false
            submenu.addItem(noDevicesItem)
        } else {
            // Group devices by type
            let groupedDevices = Dictionary(grouping: devices) { $0.deviceType }
            let sortedTypes = groupedDevices.keys.sorted { $0.rawValue < $1.rawValue }
            
            for (index, deviceType) in sortedTypes.enumerated() {
                if index > 0 {
                    submenu.addItem(NSMenuItem.separator())
                }
                
                // Add devices of this type
                if let devicesOfType = groupedDevices[deviceType] {
                    for device in devicesOfType.sorted(by: { $0.name < $1.name }) {
                        let deviceItem = createBluetoothDeviceMenuItem(for: device, service: service)
                        submenu.addItem(deviceItem)
                    }
                }
            }
        }
        
        return submenu
    }
    
    private func createBluetoothDeviceMenuItem(for device: BluetoothDeviceInfo, service: BluetoothService) -> NSMenuItem {
        var title = device.displayName
        
        // Add battery level if available
        if let batteryLevel = device.batteryLevel {
            title += " (\(batteryLevel)%)"
        }
        
        let menuItem = NSMenuItem(
            title: title,
            action: #selector(MenuBarController.bluetoothDeviceClicked(_:)),
            keyEquivalent: ""
        )
        
        menuItem.target = target
        menuItem.representedObject = device
        
        // Set state based on connection
        menuItem.state = device.isConnected ? .on : .off
        
        // Add device icon
        if let image = NSImage(systemSymbolName: device.deviceType.iconName, accessibilityDescription: device.deviceType.rawValue) {
            menuItem.image = image
        }
        
        // Add battery icon if available
        if let batteryIconName = device.batteryIconName,
           let batteryImage = NSImage(systemSymbolName: batteryIconName, accessibilityDescription: "Battery Level") {
            // Create attributed title with battery icon
            let attachment = NSTextAttachment()
            attachment.image = batteryImage
            let attributedString = NSMutableAttributedString(string: title + " ")
            attributedString.append(NSAttributedString(attachment: attachment))
            menuItem.attributedTitle = attributedString
        }
        
        return menuItem
    }
}

