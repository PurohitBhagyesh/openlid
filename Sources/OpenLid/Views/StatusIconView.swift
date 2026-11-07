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
        if powerManager.clamshell.isLidClosed {
            return "display.trianglebadge.exclamationmark" // or special closed-lid indicator
        }
        if powerManager.isEnabled {
            return "macbook.gen2"
        } else {
            return "macbook"
        }
    }
    
    private var iconColor: Color {
        if powerManager.isEnabled {
            return .green
        }
        return .primary
    }
}
