import Foundation

public enum SessionPreset: String, Equatable, Hashable, CaseIterable, Identifiable {
    case indefinite = "indefinite"
    case min15 = "15m"
    case min30 = "30m"
    case hour1 = "1h"
    case hour2 = "2h"
    
    public var id: String { rawValue }
    
    public static var allCases: [SessionPreset] {
        return [.indefinite, .min15, .min30, .hour1, .hour2]
    }
    
    public var title: String {
        switch self {
        case .indefinite: return "Indefinitely"
        case .min15: return "15 Minutes"
        case .min30: return "30 Minutes"
        case .hour1: return "1 Hour"
        case .hour2: return "2 Hours"
        }
    }
    
    public var duration: TimeInterval? {
        switch self {
        case .indefinite: return nil
        case .min15: return 15 * 60
        case .min30: return 30 * 60
        case .hour1: return 60 * 60
        case .hour2: return 120 * 60
        }
    }
}

/// Manages timed sessions for OpenLid.
public final class SessionTimer: ObservableObject {
    @Published public private(set) var activePreset: SessionPreset = .indefinite
    @Published public private(set) var remainingSeconds: TimeInterval = 0
    @Published public private(set) var isTimerRunning: Bool = false
    
    public var onTimerExpired: (() -> Void)?
    private var timer: Timer?
    
    public init() {}
    
    deinit {
        timer?.invalidate()
    }
    
    public func start(preset: SessionPreset) {
        activePreset = preset
        timer?.invalidate()
        
        guard let duration = preset.duration else {
            // Indefinite
            isTimerRunning = false
            remainingSeconds = 0
            return
        }
        
        remainingSeconds = duration
        isTimerRunning = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.remainingSeconds > 1 {
                self.remainingSeconds -= 1
            } else {
                self.stop()
                self.onTimerExpired?()
            }
        }
    }
    
    public func stop() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
        remainingSeconds = 0
    }
    
    public var formattedRemainingTime: String {
        guard isTimerRunning else { return "" }
        let total = Int(remainingSeconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

