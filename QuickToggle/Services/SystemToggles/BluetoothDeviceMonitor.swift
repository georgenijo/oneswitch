import Foundation
@preconcurrency import IOBluetooth
import os.log

protocol BluetoothDeviceMonitorDelegate: AnyObject {
    func deviceDidConnect(_ device: IOBluetoothDevice)
    func deviceDidDisconnect(_ device: IOBluetoothDevice)
}

/// Monitors Bluetooth device connection and disconnection events
class BluetoothDeviceMonitor: NSObject {
    weak var delegate: BluetoothDeviceMonitorDelegate?
    
    private var connectionNotification: IOBluetoothUserNotification?
    private var disconnectionNotification: IOBluetoothUserNotification?
    
    override init() {
        super.init()
        Logger.toggles.info("BluetoothDeviceMonitor initialized")
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Public Methods
    
    func startMonitoring() {
        Logger.toggles.info("Starting Bluetooth device monitoring")
        
        // Register for device connection notifications
        connectionNotification = IOBluetoothDevice.register(
            forConnectNotifications: self,
            selector: #selector(deviceDidConnect(_:fromDevice:))
        )
        
        // Register for device disconnection notifications  
        // Note: We need to register for each paired device individually
        registerForDisconnectionNotifications()
    }
    
    func stopMonitoring() {
        Logger.toggles.info("Stopping Bluetooth device monitoring")
        
        connectionNotification?.unregister()
        connectionNotification = nil
        
        // Note: Individual device notifications are unregistered automatically
        // when the device object is deallocated
    }
    
    // MARK: - Private Methods
    
    private func registerForDisconnectionNotifications() {
        guard let pairedDevices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
            Logger.toggles.error("Failed to get paired devices for monitoring")
            return
        }
        
        for device in pairedDevices {
            // Register for disconnection notifications for each device
            device.register(forDisconnectNotification: self, selector: #selector(deviceDidDisconnect(_:fromDevice:)))
        }
        
        Logger.toggles.debug("Registered for disconnection notifications for \(pairedDevices.count) devices")
    }
    
    // MARK: - Notification Callbacks
    
    @objc private func deviceDidConnect(_ notification: IOBluetoothUserNotification?, fromDevice device: IOBluetoothDevice) {
        Logger.toggles.info("Device connected: \(device.name ?? "Unknown") [\(device.addressString ?? "")]")
        
        // Register for disconnection notifications for this device
        device.register(forDisconnectNotification: self, selector: #selector(deviceDidDisconnect(_:fromDevice:)))
        
        // Notify delegate
        delegate?.deviceDidConnect(device)
    }
    
    @objc private func deviceDidDisconnect(_ notification: IOBluetoothUserNotification?, fromDevice device: IOBluetoothDevice) {
        Logger.toggles.info("Device disconnected: \(device.name ?? "Unknown") [\(device.addressString ?? "")]")
        
        // Notify delegate
        delegate?.deviceDidDisconnect(device)
        
        // Re-register for future disconnection notifications
        // (The notification is automatically unregistered after firing)
        device.register(forDisconnectNotification: self, selector: #selector(deviceDidDisconnect(_:fromDevice:)))
    }
}