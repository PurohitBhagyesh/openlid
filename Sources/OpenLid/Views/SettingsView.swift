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
    @State private var copiedEmail: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.green)
                    Text("OpenLid Settings")
                        .font(.system(size: 15, weight: .bold))
                    Text("v1.0.0")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.12))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                Button(action: {
                    if let onDismiss = onDismiss {
                        onDismiss()
                    } else {
                        dismiss()
                        SettingsWindowManager.shared.closeSettings()
                    }
                }) {
                    Text("Done")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 10)
            
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

                // Contact Developer Section
                Section(header: Text("Contact Developer").font(.headline)) {
                    VStack(alignment: .leading, spacing: 10) {
                        // Developer Info Row
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.18))
                                    .frame(width: 42, height: 42)
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 26))
                                    .foregroundColor(.green)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text("Bhagyesh Purohit")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("Creator")
                                        .font(.system(size: 9, weight: .heavy))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.green.opacity(0.15))
                                        .foregroundColor(.green)
                                        .clipShape(Capsule())
                                }
                                Text("Lead Developer & Maintainer")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("@PurohitBhagyesh")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.12))
                                .cornerRadius(6)
                        }
                        .padding(.vertical, 4)
                        
                        Divider()

                        // GitHub Link Option
                        Link(destination: URL(string: "https://github.com/PurohitBhagyesh")!) {
                            ContactOptionRow(
                                iconName: "chevron.left.forwardslash.chevron.right",
                                iconColor: .primary,
                                iconBg: Color.primary.opacity(0.08),
                                title: "GitHub Profile",
                                detail: "github.com/PurohitBhagyesh",
                                actionBadge: "GitHub ↗"
                            )
                        }
                        .buttonStyle(.plain)

                        // Website Link Option
                        Link(destination: URL(string: "https://openlid.devs.li")!) {
                            ContactOptionRow(
                                iconName: "globe",
                                iconColor: .blue,
                                iconBg: Color.blue.opacity(0.12),
                                title: "Official Website",
                                detail: "openlid.devs.li",
                                actionBadge: "Website ↗"
                            )
                        }
                        .buttonStyle(.plain)

                        // Report a Problem / Email Option
                        Link(destination: URL(string: "mailto:purohitunofficialbhagyesh@gmail.com?subject=OpenLid%20Problem%20Report&body=Hi%20Bhagyesh,%0D%0A%0D%0AI%20would%20like%20to%20report%20a%20problem%20with%20OpenLid:%0D%0A-%20Device:%20MacBook%0D%0A-%20macOS%20Version:%0D%0A-%20Description:%20%0D%0A")!) {
                            ContactOptionRow(
                                iconName: "envelope.fill",
                                iconColor: .green,
                                iconBg: Color.green.opacity(0.12),
                                title: "Report a Problem",
                                detail: "purohitunofficialbhagyesh@gmail.com",
                                actionBadge: "Email ↗"
                            )
                        }
                        .buttonStyle(.plain)
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
        .frame(minWidth: 500, idealWidth: 540, maxWidth: 650, minHeight: 540, idealHeight: 640, maxHeight: 850)
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

// Reusable, spacious Contact Option Row
struct ContactOptionRow: View {
    let iconName: String
    let iconColor: Color
    let iconBg: Color
    let title: String
    let detail: String
    let actionBadge: String
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconBg)
                    .frame(width: 32, height: 32)
                Image(systemName: iconName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                Text(detail)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(actionBadge)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(isHovered ? 0.16 : 0.08))
            .cornerRadius(6)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(isHovered ? 0.08 : 0.03))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isHovered ? Color.green.opacity(0.4) : Color.secondary.opacity(0.1), lineWidth: 1)
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .contentShape(Rectangle())
    }
}
