import Cocoa
import SwiftUI
import Combine
import os.log

@MainActor
class MenuBarController: NSObject {
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
    
    @objc func openPreferences() {
        Logger.menuBar.info("Preferences menu item clicked - not yet implemented")
        // TODO: Implement preferences window in a future ticket
    }
    
    @objc func quit() {
        Logger.menuBar.info("Quit menu item clicked")
        NSApp.terminate(nil)
    }
    
    deinit {
        appearanceObserver?.invalidate()
        statusItem = nil
    }
}