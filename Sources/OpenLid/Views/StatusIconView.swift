import SwiftUI
import OpenLidCore

struct StatusIconView: View {
    @ObservedObject var powerManager: PowerManager
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: iconName)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(iconColor)
            
            if powerManager.isEnabled && powerManager.timer.isTimerRunning {
                Text(powerManager.timer.formattedRemainingTime)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
            }
        }
    }
    
    private var iconName: String {
        if powerManager.isEnabled {
            // Open, vigilant eye when awake
            return powerManager.clamshell.isLidClosed ? "eye.circle.fill" : "eye.fill"
        } else {
            // Closed/slashed eye when sleep is allowed
            return "eye.slash"
        }
    }
    
    private var iconColor: Color {
        if powerManager.isEnabled {
            return .green
        }
        return .secondary
    }
}

