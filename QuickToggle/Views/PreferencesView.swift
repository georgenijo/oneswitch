import SwiftUI
import os.log

struct PreferencesView: View {
    @StateObject private var viewModel = PreferencesViewModel()
    @State private var selectedTab = "general"
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                GeneralPreferencesView(viewModel: viewModel)
                    .tabItem {
                        Label("General", systemImage: "gear")
                    }
                    .tag("general")
                
                TogglePreferencesView(viewModel: viewModel)
                    .tabItem {
                        Label("Toggles", systemImage: "switch.2")
                    }
                    .tag("toggles")
            }
            .padding()
        }
        .frame(width: 500, height: 400)
        .navigationTitle("Preferences")
    }
}

struct GeneralPreferencesView: View {
    @ObservedObject var viewModel: PreferencesViewModel
    
    var body: some View {
        Form {
            Section {
                SwiftUI.Toggle("Launch at Login", isOn: $viewModel.launchAtLogin)
                    .onChange(of: viewModel.launchAtLogin) { newValue in
                        Logger.preferences.info("Launch at Login changed to: \(newValue)")
                    }
                
                SwiftUI.Toggle("Show in Dock", isOn: $viewModel.showInDock)
                    .onChange(of: viewModel.showInDock) { newValue in
                        Logger.preferences.info("Show in Dock changed to: \(newValue)")
                    }
            }
            
            Section(header: Text("Toggle Settings").font(.headline)) {
                HStack {
                    Text("Empty Trash:")
                    Picker("", selection: $viewModel.skipEmptyTrashConfirmation) {
                        Text("Ask Before Emptying").tag(false)
                        Text("Empty Without Asking").tag(true)
                    }
                    .pickerStyle(RadioGroupPickerStyle())
                    .labelsHidden()
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct TogglePreferencesView: View {
    @ObservedObject var viewModel: PreferencesViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose which toggles appear in the menu:")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.top, 8)
            
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(ToggleType.allCases, id: \.self) { toggleType in
                        ToggleRowView(
                            toggleType: toggleType,
                            isEnabled: viewModel.isToggleEnabled(toggleType),
                            onToggle: { isEnabled in
                                viewModel.setToggleEnabled(toggleType, enabled: isEnabled)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ToggleRowView: View {
    let toggleType: ToggleType
    let isEnabled: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack {
            SwiftUI.Toggle(isOn: .init(
                get: { isEnabled },
                set: { onToggle($0) }
            )) {
                HStack(spacing: 12) {
                    Image(systemName: toggleType.iconName)
                        .font(.system(size: 16))
                        .frame(width: 20)
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(toggleType.displayName)
                            .font(.system(size: 13, weight: .medium))
                        
                        if let description = toggleType.description {
                            Text(description)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .toggleStyle(CheckboxToggleStyle())
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}

extension ToggleType {
    var description: String? {
        switch self {
        case .darkMode:
            return "Toggle between light and dark appearance"
        case .desktopIcons:
            return "Show or hide desktop files and folders"
        case .keepAwake:
            return "Prevent your Mac from sleeping"
        case .screenLock:
            return "Lock your screen immediately"
        case .emptyTrash:
            return "Permanently delete items in trash"
        case .nightShift:
            return "Adjust display color temperature"
        case .airPods:
            return "Quick connect to AirPods"
        case .screenSaver:
            return "Start screen saver immediately"
        case .trueTone:
            return "Adapt display to ambient lighting"
        case .lowPowerMode:
            return "Reduce energy usage"
        case .hideMenuBarIcons:
            return "Hide third-party menu bar icons"
        case .wifi:
            return "Toggle Wi-Fi on or off"
        case .bluetooth:
            return "Toggle Bluetooth on or off"
        }
    }
}

#if DEBUG
struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
#endif