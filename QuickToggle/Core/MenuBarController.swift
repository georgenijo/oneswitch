import Cocoa
import SwiftUI
import Combine
import os.log

@MainActor
class MenuBarController: NSObject, NSMenuDelegate {
    private var statusItem: NSStatusItem?
    private var menu: NSMenu?
    private let viewModel = ToggleViewModel()
    private var menuBuilder: MenuBuilder!
    private var cancellables = Set<AnyCancellable>()
    private var appearanceObserver: NSKeyValueObservation?
    
    override init() {
        super.init()
        self.menuBuilder = MenuBuilder(target: self)
        
        Logger.menuBar.info("Initializing MenuBarController")
        setupMenuBar()
        setupObservers()
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            updateMenuBarIcon()
            button.action = #selector(menuBarButtonClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        updateMenu()
    }
    
    private func setupObservers() {
        // Observe toggle changes
        viewModel.$toggles
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenu()
            }
            .store(in: &cancellables)
        
        // Observe appearance changes
        appearanceObserver = NSApp.observe(\.effectiveAppearance) { [weak self] _, _ in
            Task { @MainActor in
                self?.updateMenuBarIcon()
            }
        }
        
        // Observe toggle state changes
        NotificationCenter.default.publisher(for: Constants.Notifications.toggleStateChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenu()
            }
            .store(in: &cancellables)
        
        // Observe preference changes
        NotificationCenter.default.publisher(for: Constants.Notifications.preferencesChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenu()
            }
            .store(in: &cancellables)
    }
    
    private func updateMenu() {
        Logger.menuBar.debug("Updating menu")
        menu = menuBuilder.buildMenu(with: viewModel.toggles)
        menu?.delegate = self
        statusItem?.menu = menu
    }
    
    private func updateMenuBarIcon() {
        guard let button = statusItem?.button else { return }
        
        let isDarkMode = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        Logger.menuBar.debug("Updating menu bar icon for \(isDarkMode ? "dark" : "light") mode")
        
        if let image = NSImage(systemSymbolName: Constants.MenuBar.iconName, 
                               accessibilityDescription: Constants.MenuBar.iconAccessibilityDescription) {
            image.isTemplate = true
            button.image = image
        }
    }
    
    @objc private func menuBarButtonClicked(_ sender: NSStatusBarButton) {
        Logger.menuBar.debug("Menu bar button clicked")
        // Menu will show automatically due to statusItem?.menu assignment
    }
    
    @objc func toggleClicked(_ sender: NSMenuItem) {
        guard let toggle = sender.representedObject as? Toggle else {
            Logger.menuBar.error("No toggle found in menu item")
            return
        }
        
        Logger.menuBar.info("Toggle clicked: \(toggle.type.displayName)")
        viewModel.toggle(toggle)
    }
    
    @objc func actionClicked(_ sender: NSMenuItem) {
        guard let action = sender.representedObject as? Toggle else {
            Logger.menuBar.error("No action found in menu item")
            return
        }
        
        Logger.menuBar.info("Action clicked: \(action.type.displayName)")
        viewModel.performAction(action)
    }
    
    @objc func bluetoothDeviceClicked(_ sender: NSMenuItem) {
        guard let device = sender.representedObject as? BluetoothDeviceInfo else {
            Logger.menuBar.error("No device found in menu item")
            return
        }
        
        Logger.menuBar.info("Bluetooth device clicked: \(device.name)")
        
        // Get the Bluetooth service to handle the connection
        if let bluetoothService = ToggleServiceManager.shared.service(for: .bluetooth) as? BluetoothService {
            Task {
                do {
                    if device.isConnected {
                        // Disconnect the device
                        try await bluetoothService.disconnectDevice(address: device.address)
                    } else {
                        // Connect the device
                        try await bluetoothService.connectDevice(address: device.address)
                    }
                    
                    // Update menu after connection change
                    await MainActor.run {
                        self.updateMenu()
                    }
                } catch {
                    Logger.menuBar.error("Failed to \(device.isConnected ? "disconnect" : "connect") device: \(error)")
                }
            }
        }
    }
    
    @objc func openPreferences() {
        Logger.menuBar.info("Preferences menu item clicked")
        PreferencesWindowController.showPreferences()
    }
    
    @objc func quit() {
        Logger.menuBar.info("Quit menu item clicked")
        NSApp.terminate(nil)
    }
    
    deinit {
        appearanceObserver?.invalidate()
        statusItem = nil
    }
    
    // MARK: - NSMenuDelegate
    
    func menuWillOpen(_ menu: NSMenu) {
        Logger.menuBar.debug("Menu will open - refreshing dynamic content")
        
        // Refresh dynamic toggles (like trash count) and update Bluetooth devices
        Task {
            // Update Bluetooth device list if service is available
            if let bluetoothService = ToggleServiceManager.shared.service(for: .bluetooth) as? BluetoothService {
                bluetoothService.updateDeviceList()
            }
            
            await viewModel.refreshDynamicToggles()
            await MainActor.run {
                self.updateMenu()
            }
        }
    }
}