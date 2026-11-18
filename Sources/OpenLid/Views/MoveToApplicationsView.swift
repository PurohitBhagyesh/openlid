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
        case .copying: return "Moving..."
        case .authorizing: return "Authorizing..."
        case .cleaningUp: return "Finishing..."
        case .relaunching: return "Relaunching..."
        case .failed(let message): return message
        }
    }
    
    public init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        ZStack {
            LiquidGlassCanvas()
            
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    iconTile(image: NSApplication.shared.applicationIconImage, label: "OpenLid")
                    
                    HStack(spacing: 3) {
                        ForEach(0..<3, id: \.self) { idx in
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(chevronPhase == idx ? .white : Color.white.opacity(0.22))
                                .animation(.easeInOut(duration: 0.25), value: chevronPhase)
                        }
                    }
                    .padding(.bottom, 16)
                    
                    iconTile(image: NSWorkspace.shared.icon(forFile: "/Applications"), label: "Applications")
                }
                .padding(.top, 28)
                
                VStack(spacing: 5) {
                    Text("Move to Applications")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Running from \(locationName). Move OpenLid to Applications for Launch at Login and updates.")
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .frame(maxWidth: 300)
                }
                
                if case .failed(let errorMsg) = stage {
                    VStack(spacing: 4) {
                        Text(errorMsg)
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        Button("Open Applications Folder") {
                            NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications"))
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer(minLength: 0)
                
                VStack(spacing: 10) {
                    Button(action: startMove) {
                        HStack(spacing: 7) {
                            if isMoving {
                                ProgressView()
                                    .scaleEffect(0.55)
                                Text(statusText)
                                    .font(.system(size: 13, weight: .semibold))
                            } else {
                                Text("Move to Applications")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Color.white)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(isMoving)
                    .keyboardShortcut(.defaultAction)
                    
                    HStack {
                        Toggle(isOn: $dontAskAgain) {
                            Text("Don't ask again")
                                .font(.system(size: 11.5))
                                .foregroundColor(Color.white.opacity(0.48))
                        }
                        .toggleStyle(.checkbox)
                        .disabled(isMoving)
                        
                        Spacer()
                        
                        Button("Not Now", action: handleNotNow)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.62))
                            .buttonStyle(.plain)
                            .disabled(isMoving)
                            .keyboardShortcut(.cancelAction)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 18)
            }
            .ignoresSafeArea(.container, edges: .top)
        }
        .frame(width: 380, height: 300)
        .preferredColorScheme(.dark)
        .onReceive(timer) { _ in
            chevronPhase = (chevronPhase + 1) % 3
        }
    }
    
    private func iconTile(image: NSImage?, label: String) -> some View {
        VStack(spacing: 5) {
            ZStack {
                if let img = image {
                    Image(nsImage: img)
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 44, height: 44)
                }
            }
            .frame(width: 62, height: 62)
            .liquidGlassCard(cornerRadius: 15, elevated: false)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Color.white.opacity(0.55))
        }
    }
    
    private func startMove() {
        ApplicationMover.relocateToApplications(
            onStageChange: { newStage in
                withAnimation(.easeInOut(duration: 0.18)) {
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
