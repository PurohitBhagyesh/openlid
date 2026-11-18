import SwiftUI
import AppKit
import Combine
import OpenLidCore

public struct MoveToApplicationsView: View {
    @State private var stage: ApplicationMoveStage = .idle
    @State private var dontAskAgain: Bool = false
    @State private var chevronPhase: Int = 0
    
    public var onDismiss: () -> Void
    
    private let locationName = ApplicationMover.currentLocationDescription()
    private let timer = Timer.publish(every: 0.42, on: .main, in: .common).autoconnect()
    
    private var isMoving: Bool {
        switch stage {
        case .copying, .authorizing, .cleaningUp, .relaunching:
            return true
        case .idle, .failed:
            return false
        }
    }
    
    private var statusText: String {
        switch stage {
        case .idle:
            return ""
        case .copying:
            return "Copying OpenLid to /Applications..."
        case .authorizing:
            return "Waiting for macOS administrator permission..."
        case .cleaningUp:
            return "Finishing installation..."
        case .relaunching:
            return "Relaunching OpenLid from Applications..."
        case .failed(let message):
            return message
        }
    }
    
    public init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        ZStack {
            // Deep obsidian surface
            Color(red: 0.045, green: 0.055, blue: 0.075)
                .ignoresSafeArea()
            
            // Subtle ambient emerald top glow
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.06, green: 0.72, blue: 0.50).opacity(0.18),
                    Color.clear
                ]),
                center: .top,
                startRadius: 10,
                endRadius: 260
            )
            .ignoresSafeArea()
            
            VStack(spacing: 18) {
                // Location pill badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(red: 0.06, green: 0.72, blue: 0.50))
                        .frame(width: 6, height: 6)
                    Text("RUNNING FROM \(locationName.uppercased())")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .tracking(0.8)
                        .foregroundColor(Color(red: 0.45, green: 0.90, blue: 0.72))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(red: 0.06, green: 0.72, blue: 0.50).opacity(0.10))
                .cornerRadius(999)
                .overlay(
                    Capsule()
                        .stroke(Color(red: 0.06, green: 0.72, blue: 0.50).opacity(0.28), lineWidth: 1)
                )
                .padding(.top, 26)
                
                // Visual transfer stage: App Icon -> Animated Chevrons -> Applications Folder
                HStack(spacing: 18) {
                    iconTile(
                        image: NSApplication.shared.applicationIconImage,
                        label: "OpenLid.app",
                        glowColor: Color(red: 0.06, green: 0.72, blue: 0.50)
                    )
                    
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { idx in
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(
                                    chevronPhase == idx
                                        ? Color(red: 0.16, green: 0.85, blue: 0.62)
                                        : Color.white.opacity(0.22)
                                )
                                .scaleEffect(chevronPhase == idx ? 1.15 : 1.0)
                                .animation(.easeInOut(duration: 0.25), value: chevronPhase)
                        }
                    }
                    .padding(.bottom, 16)
                    
                    iconTile(
                        image: NSWorkspace.shared.icon(forFile: "/Applications"),
                        label: "Applications",
                        glowColor: Color(red: 0.22, green: 0.56, blue: 0.98)
                    )
                }
                .padding(.top, 4)
                
                // Headline & description
                VStack(spacing: 6) {
                    Text("Move OpenLid to Applications")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Install OpenLid in your Applications folder for full macOS compatibility, Launch at Login, and reliable clamshell wake locks.")
                        .font(.system(size: 12.5))
                        .foregroundColor(Color(white: 0.68))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .frame(maxWidth: 380)
                }
                
                // Compact frosted benefits card
                VStack(alignment: .leading, spacing: 11) {
                    benefitRow(
                        icon: "folder.badge.checkmark",
                        iconColor: Color(red: 0.16, green: 0.85, blue: 0.62),
                        title: "Keeps your \(locationName) folder clean",
                        subtitle: "Moves the app cleanly so duplicate copies aren't left behind."
                    )
                    Divider().background(Color.white.opacity(0.06))
                    benefitRow(
                        icon: "bolt.shield.fill",
                        iconColor: Color(red: 0.20, green: 0.78, blue: 0.95),
                        title: "Bypasses Gatekeeper App Translocation",
                        subtitle: "Ensures Launch at Login and background power guards stay active."
                    )
                    Divider().background(Color.white.opacity(0.06))
                    benefitRow(
                        icon: "arrow.triangle.2.circlepath",
                        iconColor: Color(red: 0.58, green: 0.65, blue: 0.98),
                        title: "Automatic Handoff & Relaunch",
                        subtitle: "Installs atomically into /Applications and reopens right away."
                    )
                }
                .padding(14)
                .background(Color.white.opacity(0.035))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .padding(.horizontal, 24)
                
                // Status / Error feedback area
                if case .failed(let errorMsg) = stage {
                    VStack(spacing: 8) {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 13))
                            Text(errorMsg)
                                .font(.system(size: 11.5))
                                .foregroundColor(Color(white: 0.85))
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                        HStack {
                            Spacer()
                            Button("Open Applications Folder in Finder") {
                                NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications"))
                            }
                            .buttonStyle(.link)
                            .font(.system(size: 11.5, weight: .medium))
                        }
                    }
                    .padding(10)
                    .background(Color.orange.opacity(0.10))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.orange.opacity(0.30), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                }
                
                Spacer(minLength: 4)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: startMove) {
                        HStack(spacing: 8) {
                            if isMoving {
                                ProgressView()
                                    .scaleEffect(0.65)
                                    .colorInvert()
                                    .brightness(1)
                                Text(statusText)
                                    .font(.system(size: 13.5, weight: .semibold))
                            } else {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Move to Applications Folder")
                                    .font(.system(size: 13.5, weight: .bold))
                            }
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.16, green: 0.86, blue: 0.62),
                                    Color(red: 0.06, green: 0.72, blue: 0.50)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                        .shadow(color: Color(red: 0.06, green: 0.72, blue: 0.50).opacity(0.30), radius: 10, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    .disabled(isMoving)
                    .keyboardShortcut(.defaultAction)
                    
                    HStack {
                        Toggle(isOn: $dontAskAgain) {
                            Text("Don't ask again")
                                .font(.system(size: 12))
                                .foregroundColor(Color(white: 0.60))
                        }
                        .toggleStyle(.checkbox)
                        .disabled(isMoving)
                        
                        Spacer()
                        
                        Button(action: handleNotNow) {
                            Text("Not Now")
                                .font(.system(size: 12.5, weight: .medium))
                                .foregroundColor(Color(white: 0.72))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(7)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 7)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(isMoving)
                        .keyboardShortcut(.cancelAction)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 22)
            }
        }
        .frame(width: 460, height: 500)
        .onReceive(timer) { _ in
            chevronPhase = (chevronPhase + 1) % 3
        }
    }
    
    private func iconTile(image: NSImage?, label: String, glowColor: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 74, height: 74)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(glowColor.opacity(0.32), lineWidth: 1)
                    )
                    .shadow(color: glowColor.opacity(0.20), radius: 12, x: 0, y: 4)
                
                if let img = image {
                    Image(nsImage: img)
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 54, height: 54)
                }
            }
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(white: 0.72))
        }
    }
    
    private func benefitRow(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(iconColor.opacity(0.14))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(Color(white: 0.62))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private func startMove() {
        ApplicationMover.relocateToApplications(
            onStageChange: { newStage in
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.stage = newStage
                }
            },
            completion: { _ in }
        )
    }
    
    private func handleNotNow() {
        if dontAskAgain {
            ApplicationMover.setPromptSuppressed(true)
        }
        onDismiss()
    }
}
