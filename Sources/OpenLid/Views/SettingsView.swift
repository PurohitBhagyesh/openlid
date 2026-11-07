import SwiftUI
import ServiceManagement
import OpenLidCore

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    var onDismiss: (() -> Void)? = nil
    
    @ObservedObject var powerManager = PowerManager.shared
    @State private var helperInstalled: Bool = PrivilegeManager.shared.isHelperInstalled()
    @State private var helperStatusMessage: String? = nil
    @State private var isProcessingHelper: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Navigation Bar with Back & Done buttons
            HStack(alignment: .center) {
                Button(action: {
                    dismiss()
                    onDismiss?()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .bold))
                        Text("Back")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.secondary.opacity(0.15))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])
                
                Spacer()
                
                Text("Settings")
                    .font(.system(size: 14, weight: .bold))
                
                Spacer()
                
                Button(action: {
                    dismiss()
                    onDismiss?()
                }) {
                    Text("Done")
                        .font(.system(size: 12, weight: .bold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            Divider()
            
            // Settings Form
            Form {
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

                // Contact & Developer Support Section
                Section(header: Text("Contact Developer").font(.headline)) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "person.crop.circle.fill")
                                .foregroundColor(.accentColor)
                                .font(.system(size: 16))
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Bhagyesh Purohit")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Lead Developer & Creator")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("@PurohitBhagyesh")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.12))
                                .cornerRadius(4)
                        }
                        .padding(.vertical, 2)
                        
                        Divider()

                        // GitHub Link
                        Link(destination: URL(string: "https://github.com/PurohitBhagyesh")!) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left.forwardslash.chevron.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.primary)
                                    .frame(width: 18)
                                Text("GitHub: @PurohitBhagyesh")
                                    .font(.system(size: 12))
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }

                        // Website Link
                        Link(destination: URL(string: "https://openlid.devs.li")!) {
                            HStack(spacing: 8) {
                                Image(systemName: "globe")
                                    .font(.system(size: 12))
                                    .foregroundColor(.blue)
                                    .frame(width: 18)
                                Text("Website: openlid.devs.li")
                                    .font(.system(size: 12))
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }

                        // Report a Problem / Email
                        Link(destination: URL(string: "mailto:purohitunofficialbhagyesh@gmail.com?subject=OpenLid%20Problem%20Report&body=Hi%20Bhagyesh,%0D%0A%0D%0AI%20would%20like%20to%20report%20an%20issue%20with%20OpenLid:%0D%0A")!) {
                            HStack(spacing: 8) {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.green)
                                    .frame(width: 18)
                                Text("Report a Problem: purohitunofficialbhagyesh@gmail.com")
                                    .font(.system(size: 12))
                                    .lineLimit(1)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
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
        }
        .frame(width: 370, height: 520)
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
