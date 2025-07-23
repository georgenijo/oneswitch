import Foundation
@preconcurrency import IOBluetooth
import IOKit
import Cocoa
import os.log

/// Service for managing Bluetooth state and devices
class BluetoothService: BaseObservableToggleService {
    // Device tracking
    private var pairedDevices: [BluetoothDeviceInfo] = []
    private var deviceMonitor: BluetoothDeviceMonitor?
    private let updateQueue = DispatchQueue(label: "dev.quicktoggle.bluetooth", qos: .userInitiated)
    
    // Polling timer for device updates
    private var deviceUpdateTimer: Timer?
    
    init() {
        super.init(toggleType: .bluetooth)
        
        // Initialize device monitor
        deviceMonitor = BluetoothDeviceMonitor()
        deviceMonitor?.delegate = self
        
        // Initial availability check
        Task { @MainActor in
            self.currentAvailability = true
            self.currentPermission = await checkBluetoothPermission()
        }
    }
    
    // MARK: - ToggleServiceProtocol
    
    override func isEnabled() async throws -> Bool {
        // Check if Bluetooth is powered on
        guard let controller = IOBluetoothHostController.default() else {
            Logger.toggles.error("Failed to get Bluetooth controller")
            throw ToggleError.systemError(NSError(domain: "BluetoothService", code: -1))
        }
        
        let powerState = controller.powerState
        // BluetoothHCIPowerState.on is rawValue 1
        return powerState.rawValue == 1
    }
    
    override func setEnabled(_ enabled: Bool) async throws {
        Logger.toggles.info("Setting Bluetooth state to: \(enabled)")
        
        if enabled {
            try await turnOnBluetooth()
        } else {
            try await turnOffBluetooth()
        }
        
        // Update state
        await MainActor.run {
            self.currentState = enabled
        }
    }
    
    override func isAvailable() async -> Bool {
        // Bluetooth is always available on macOS
        return true
    }
    
    override func hasPermission() async -> Bool {
        return await checkBluetoothPermission()
    }
    
    override func requestPermission() async -> Bool {
        // Bluetooth permission is requested automatically when accessing devices
        // Try to access devices to trigger permission prompt
        _ = IOBluetoothDevice.pairedDevices()
        return await checkBluetoothPermission()
    }
    
    // MARK: - Device Management
    
    func getPairedDevices() -> [BluetoothDeviceInfo] {
        updateQueue.sync {
            return pairedDevices
        }
    }
    
    func updateDeviceList() {
        Logger.toggles.debug("Updating Bluetooth device list")
        
        guard let devices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
            Logger.toggles.error("Failed to get paired devices")
            return
        }
        
        let deviceInfos = devices.compactMap { device -> BluetoothDeviceInfo? in
            guard let name = device.name,
                  let address = device.addressString else {
                return nil
            }
            
            let majorClass = device.classOfDevice >> 8 & 0x1F
            let minorClass = device.classOfDevice >> 2 & 0x3F
            
            return BluetoothDeviceInfo(
                id: address,
                name: name,
                address: address,
                isConnected: device.isConnected(),
                isPaired: device.isPaired(),
                batteryLevel: getBatteryLevel(for: address),
                deviceType: BluetoothDeviceInfo.deviceType(
                    from: majorClass,
                    minorClass: minorClass,
                    name: name
                ),
                lastSeenDate: device.recentAccessDate(),
                majorDeviceClass: majorClass,
                minorDeviceClass: minorClass
            )
        }
        
        updateQueue.async {
            self.pairedDevices = deviceInfos
        }
        
        Logger.toggles.info("Found \(deviceInfos.count) paired Bluetooth devices")
        
        // Notify UI of device list update
        Task { @MainActor in
            NotificationCenter.default.post(
                name: Notification.Name("BluetoothDevicesUpdated"),
                object: nil
            )
        }
    }
    
    func connectDevice(address: String) async throws {
        Logger.toggles.info("Attempting to connect to device: \(address)")
        
        guard let device = IOBluetoothDevice(addressString: address) else {
            throw ToggleError.operationFailed
        }
        
        if !device.isPaired() {
            Logger.toggles.error("Device is not paired: \(address)")
            throw ToggleError.invalidState
        }
        
        if device.isConnected() {
            Logger.toggles.info("Device already connected: \(address)")
            return
        }
        
        // Attempt connection
        let result = await withCheckedContinuation { continuation in
            updateQueue.async {
                let connectionResult = device.openConnection()
                continuation.resume(returning: connectionResult)
            }
        }
        
        if result != kIOReturnSuccess {
            Logger.toggles.error("Failed to connect device: \(result)")
            throw ToggleError.operationFailed
        }
        
        Logger.toggles.info("Successfully connected to device: \(address)")
        
        // Update device list
        updateDeviceList()
    }
    
    func disconnectDevice(address: String) async throws {
        Logger.toggles.info("Attempting to disconnect device: \(address)")
        
        guard let device = IOBluetoothDevice(addressString: address) else {
            throw ToggleError.operationFailed
        }
        
        if !device.isConnected() {
            Logger.toggles.info("Device already disconnected: \(address)")
            return
        }
        
        // Multiple attempts may be needed for some devices
        var attempts = 0
        let maxAttempts = 5
        
        while device.isConnected() && attempts < maxAttempts {
            let result = await withCheckedContinuation { continuation in
                updateQueue.async {
                    let disconnectResult = device.closeConnection()
                    continuation.resume(returning: disconnectResult)
                }
            }
            
            if result == kIOReturnSuccess {
                Logger.toggles.info("Successfully disconnected device: \(address)")
                break
            }
            
            attempts += 1
            if attempts < maxAttempts {
                // Wait before retry
                try await Task.sleep(nanoseconds: 500_000_000) // 500ms
                Logger.toggles.debug("Retrying disconnect, attempt \(attempts + 1)")
            }
        }
        
        if device.isConnected() {
            Logger.toggles.error("Failed to disconnect device after \(maxAttempts) attempts")
            throw ToggleError.operationFailed
        }
        
        // Update device list
        updateDeviceList()
    }
    
    // MARK: - Private Methods
    
    private func checkBluetoothPermission() async -> Bool {
        // Check if we can access Bluetooth devices
        // Permission is granted if we can get the device list without issues
        return IOBluetoothDevice.pairedDevices() != nil
    }
    
    private func turnOnBluetooth() async throws {
        // Try using blueutil command if available
        let blueutilPath = "/usr/local/bin/blueutil"
        
        if FileManager.default.fileExists(atPath: blueutilPath) {
            let result = await runCommand(blueutilPath, arguments: ["--power", "1"])
            if result {
                Logger.toggles.info("Bluetooth turned on using blueutil")
                return
            }
        }
        
        // Fallback: Bluetooth power control requires system-level access
        // For now, log that manual control is needed
        Logger.toggles.warning("Bluetooth power control not fully implemented - manual control required")
    }
    
    private func turnOffBluetooth() async throws {
        // Try using blueutil command if available
        let blueutilPath = "/usr/local/bin/blueutil"
        
        if FileManager.default.fileExists(atPath: blueutilPath) {
            let result = await runCommand(blueutilPath, arguments: ["--power", "0"])
            if result {
                Logger.toggles.info("Bluetooth turned off using blueutil")
                return
            }
        }
        
        Logger.toggles.warning("Bluetooth power control not fully implemented")
    }
    
    private func runCommand(_ path: String, arguments: [String]) async -> Bool {
        return await withCheckedContinuation { continuation in
            updateQueue.async {
                let task = Process()
                task.launchPath = path
                task.arguments = arguments
                
                do {
                    try task.run()
                    task.waitUntilExit()
                    continuation.resume(returning: task.terminationStatus == 0)
                } catch {
                    Logger.toggles.error("Failed to run command: \(error)")
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    private func getBatteryLevel(for address: String) -> Int? {
        var iterator = io_iterator_t()
        defer { 
            if iterator != 0 {
                IOObjectRelease(iterator)
            }
        }
        
        let matchingDict = IOServiceMatching("AppleDeviceManagementHIDEventService")
        let result: kern_return_t
        if #available(macOS 12.0, *) {
            result = IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, &iterator)
        } else {
            result = IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, &iterator)
        }
        
        guard result == KERN_SUCCESS else { return nil }
        
        var service = IOIteratorNext(iterator)
        while service != 0 {
            defer { 
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }
            
            // Check if this service matches our device
            if let deviceAddrData = IORegistryEntryCreateCFProperty(
                service, 
                "DeviceAddress" as CFString, 
                kCFAllocatorDefault, 
                0
            )?.takeRetainedValue() as? String,
               deviceAddrData.replacingOccurrences(of: "-", with: ":") == address {
                
                // Get battery percentage
                if let batteryData = IORegistryEntryCreateCFProperty(
                    service, 
                    "BatteryPercent" as CFString, 
                    kCFAllocatorDefault, 
                    0
                )?.takeRetainedValue() as? Int {
                    return batteryData
                }
            }
        }
        
        return nil
    }
    
    private func startDeviceMonitoring() {
        // Start periodic device list updates
        deviceUpdateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateDeviceList()
        }
        
        // Initial update
        updateDeviceList()
        
        // Start connection monitoring
        deviceMonitor?.startMonitoring()
    }
    
    private func stopDeviceMonitoring() {
        deviceUpdateTimer?.invalidate()
        deviceUpdateTimer = nil
        deviceMonitor?.stopMonitoring()
    }
    
    // MARK: - ServiceLifecycle
    
    override func start() async {
        Logger.toggles.info("Starting Bluetooth service")
        await super.start()
        
        await MainActor.run {
            startDeviceMonitoring()
        }
    }
    
    override func stop() async {
        Logger.toggles.info("Stopping Bluetooth service")
        await super.stop()
        
        await MainActor.run {
            stopDeviceMonitoring()
        }
    }
}

// MARK: - BluetoothDeviceMonitorDelegate

extension BluetoothService: BluetoothDeviceMonitorDelegate {
    func deviceDidConnect(_ device: IOBluetoothDevice) {
        Logger.toggles.info("Device connected: \(device.name ?? "Unknown")")
        updateDeviceList()
    }
    
    func deviceDidDisconnect(_ device: IOBluetoothDevice) {
        Logger.toggles.info("Device disconnected: \(device.name ?? "Unknown")")
        updateDeviceList()
    }
}