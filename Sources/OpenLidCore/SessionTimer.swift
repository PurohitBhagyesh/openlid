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
        case .indefinite: return "Always"
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

/// Manages timed sessions and real-time live countdowns for OpenLid.
public final class SessionTimer: ObservableObject {
    @Published public private(set) var activePreset: SessionPreset = .indefinite
    @Published public private(set) var remainingSeconds: TimeInterval = 0
    @Published public private(set) var elapsedSeconds: TimeInterval = 0
    @Published public private(set) var isTimerRunning: Bool = false
    @Published public private(set) var sessionStartDate: Date? = nil
    
    public var onTimerExpired: (() -> Void)?
    private var timer: Timer?
    
    public init() {}
    
    deinit {
        timer?.invalidate()
    }
    
    public func start(preset: SessionPreset) {
        activePreset = preset
        sessionStartDate = Date()
        elapsedSeconds = 0
        
        timer?.invalidate()
        
        guard let duration = preset.duration else {
            // Indefinite ("Always") mode: run continuous live elapsed timer
            isTimerRunning = false
            remainingSeconds = 0
            
            let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.elapsedSeconds += 1
                }
            }
            RunLoop.main.add(t, forMode: .common)
            self.timer = t
            return
        }
        
        remainingSeconds = duration
        isTimerRunning = true
        
        // Use RunLoop.main in .common mode so timer ticks uninterrupted during mouse tracking & menus
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.elapsedSeconds += 1
                if self.remainingSeconds > 1 {
                    self.remainingSeconds -= 1
                } else {
                    self.stop()
                    self.onTimerExpired?()
                }
            }
        }
        RunLoop.main.add(t, forMode: .common)
        self.timer = t
    }
    
    public func stop() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
        remainingSeconds = 0
        elapsedSeconds = 0
        sessionStartDate = nil
    }
    
    /// Formatted real-time countdown string (ticks every second: e.g. "01:29:54" or "29:54")
    public var formattedRemainingTime: String {
        guard isTimerRunning else { return "" }
        let total = Int(remainingSeconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    /// Formatted real-time active elapsed time string (e.g. "00:14:32")
    public var formattedElapsedTime: String {
        let total = Int(elapsedSeconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
