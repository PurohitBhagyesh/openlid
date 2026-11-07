import SwiftUI
import ServiceManagement
import OpenLidCore

struct SettingsView: View {
    @ObservedObject var powerManager = PowerManager.shared
    @State private var helperInstalled: Bool = PrivilegeManager.shared.isHelperInstalled()
    @State private var helperStatusMessage: String? = nil
    @State private var isProcessingHelper: Bool = false
    @State private var launchAtLogin: Bool = false
    
    var body: some View {
        Form {
            Section(header: Text("Safety & Battery Protection").font(.headline)) {
                Toggle("Auto-off on Low Battery", isOn: Binding(
                    get: { powerManager.battery.lowBatteryCutoffEnabled },
                    set: { powerManager.battery.lowBatteryCutoffEnabled = $0 }
                ))
                
                if powerManager.battery.lowBatteryCutoffEnabled {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Battery cutoff threshold:")
                            Spacer()
                            Text("\(powerManager.battery.lowBatteryThreshold)%")
                                .fontWeight(.semibold)
                        }
                        Slider(
                            value: Binding(
                                get: { Double(powerManager.battery.lowBatteryThreshold) },
                                set: { powerManager.battery.lowBatteryThreshold = Int($0) }
                            ),
                            in: 5...30,
                            step: 1
                        )
                        Text("OpenLid will automatically disable sleep prevention and allow sleep if the battery reaches this level.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Toggle("Thermal Overheating Guard", isOn: Binding(
                    get: { powerManager.thermal.thermalProtectionEnabled },
                    set: { powerManager.thermal.thermalProtectionEnabled = $0 }
                ))
                Text("Disables sleep prevention immediately if CPU or chassis temperatures hit dangerous levels.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("Startup & Login Behavior").font(.headline)) {
                Toggle("Launch OpenLid at Login", isOn: Binding(
                    get: { LaunchAtLoginManager.shared.isLaunchAtLoginEnabled },
                    set: { newValue in
                        try? LaunchAtLoginManager.shared.setLaunchAtLogin(enabled: newValue)
                    }
                ))
                
                Toggle("Auto-Awake on Login", isOn: Binding(
                    get: { LaunchAtLoginManager.shared.awakeOnLogin },
                    set: { LaunchAtLoginManager.shared.awakeOnLogin = $0 }
                ))
                Text("When enabled, OpenLid automatically awakens your Mac in closed-lid mode as soon as you log in.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("Privileges & Quick Toggle").font(.headline)) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Instant Toggle Helper")
                                .fontWeight(.medium)
                            Text(helperInstalled ? "Installed (Passwordless instant toggling enabled)" : "Not installed (macOS prompts for admin password each toggle)")
                                .font(.caption)
                                .foregroundColor(helperInstalled ? .green : .orange)
                        }
                        Spacer()
                        if isProcessingHelper {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Button(helperInstalled ? "Uninstall Helper" : "Install Helper") {
                                toggleHelper()
                            }
                        }
                    }
                    
                    if let msg = helperStatusMessage {
                        Text(msg)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("Hardware Guidelines").font(.headline)) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Airflow Warning", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.subheadline.bold())
                    Text("MacBooks dissipate heat partially through the keyboard and hinge assembly. Never leave your Mac running with the lid closed inside a tightly zipped backpack, sleeve, or enclosed container.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 420)
        .onAppear {
            helperInstalled = PrivilegeManager.shared.isHelperInstalled()
        }
    }
    
    private func toggleHelper() {
        isProcessingHelper = true
        helperStatusMessage = nil
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                if helperInstalled {
                    try PrivilegeManager.shared.uninstallHelper()
                    DispatchQueue.main.async {
                        self.helperInstalled = false
                        self.helperStatusMessage = "Helper uninstalled successfully."
                        self.isProcessingHelper = false
                    }
                } else {
                    try PrivilegeManager.shared.installHelper()
                    DispatchQueue.main.async {
                        self.helperInstalled = true
                        self.helperStatusMessage = "Helper installed! Toggles will now be instantaneous."
                        self.isProcessingHelper = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.helperStatusMessage = "Failed: \(error.localizedDescription)"
                    self.isProcessingHelper = false
                }
            }
        }
    }
}

