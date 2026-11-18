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
    private let timer = Timer.publish(every: 0.45, on: .main, in: .common).autoconnect()
    private let emerald = Color(red: 0.063, green: 0.725, blue: 0.506)
    
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
        case .idle: return ""
        case .copying: return "Moving to /Applications..."
        case .authorizing: return "Waiting for authorization..."
        case .cleaningUp: return "Finishing up..."
        case .relaunching: return "Relaunching..."
        case .failed(let message): return message
        }
    }
    
    public init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        ZStack {
            Color(red: 0.047, green: 0.055, blue: 0.071)
                .ignoresSafeArea()
            
            RadialGradient(
                gradient: Gradient(colors: [emerald.opacity(0.14), Color.clear]),
                center: .top,
                startRadius: 8,
                endRadius: 220
            )
            .ignoresSafeArea()
            
            VStack(spacing: 18) {
                // Visual transfer icons
                HStack(spacing: 18) {
                    iconTile(
                        image: NSApplication.shared.applicationIconImage,
                        label: "OpenLid",
                        borderColor: emerald.opacity(0.32)
                    )
                    
                    HStack(spacing: 3) {
                        ForEach(0..<3, id: \.self) { idx in
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(chevronPhase == idx ? emerald : Color.white.opacity(0.20))
                                .animation(.easeInOut(duration: 0.25), value: chevronPhase)
                        }
                    }
                    .padding(.bottom, 16)
                    
                    iconTile(
                        image: NSWorkspace.shared.icon(forFile: "/Applications"),
                        label: "Applications",
                        borderColor: Color.white.opacity(0.14)
                    )
                }
                .padding(.top, 32)
                
                // Concise copy
                VStack(spacing: 6) {
                    Text("Move to Applications?")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("OpenLid is running from \(locationName). Move it to your Applications folder to keep Launch at Login and updates working cleanly.")
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.58))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .frame(maxWidth: 320)
                }
                
                if case .failed(let errorMsg) = stage {
                    VStack(spacing: 6) {
                        Text(errorMsg)
                            .font(.system(size: 11))
                            .foregroundColor(.orange)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        Button("Open /Applications in Finder") {
                            NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications"))
                        }
                        .buttonStyle(.link)
                        .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer(minLength: 0)
                
                // Actions
                VStack(spacing: 12) {
                    Button(action: startMove) {
                        HStack(spacing: 8) {
                            if isMoving {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .colorInvert()
                                Text(statusText)
                                    .font(.system(size: 13, weight: .semibold))
                            } else {
                                Text("Move to Applications")
                                    .font(.system(size: 13, weight: .bold))
                            }
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(emerald)
                        .cornerRadius(9)
                    }
                    .buttonStyle(.plain)
                    .disabled(isMoving)
                    .keyboardShortcut(.defaultAction)
                    
                    HStack {
                        Toggle(isOn: $dontAskAgain) {
                            Text("Don't ask again")
                                .font(.system(size: 11.5))
                                .foregroundColor(Color.white.opacity(0.50))
                        }
                        .toggleStyle(.checkbox)
                        .disabled(isMoving)
                        
                        Spacer()
                        
                        Button("Not Now", action: handleNotNow)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.65))
                            .buttonStyle(.plain)
                            .disabled(isMoving)
                            .keyboardShortcut(.cancelAction)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 22)
            }
        }
        .frame(width: 400, height: 330)
        .preferredColorScheme(.dark)
        .onReceive(timer) { _ in
            chevronPhase = (chevronPhase + 1) % 3
        }
    }
    
    private func iconTile(image: NSImage?, label: String, borderColor: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 66, height: 66)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(borderColor, lineWidth: 1)
                    )
                if let img = image {
                    Image(nsImage: img)
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                }
            }
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.white.opacity(0.60))
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
