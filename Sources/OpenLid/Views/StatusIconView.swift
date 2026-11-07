import SwiftUI
import OpenLidCore

struct StatusIconView: View {
    @ObservedObject var powerManager: PowerManager
    @ObservedObject var timer: SessionTimer
    
    init(powerManager: PowerManager = .shared) {
        self.powerManager = powerManager
        self.timer = powerManager.timer
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .renderingMode(.template)
                .font(.system(size: 14, weight: .semibold))
            
            if powerManager.isEnabled && timer.isTimerRunning {
                Text(timer.formattedRemainingTime)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
            }
        }
    }
    
    private var iconName: String {
        if powerManager.isEnabled {
            // Open, vigilant eye when awake
            return powerManager.clamshell.isLidClosed ? "eye.circle.fill" : "eye.fill"
        } else {
            // Slashed eye when sleep is allowed
            return "eye.slash"
        }
    }
}
