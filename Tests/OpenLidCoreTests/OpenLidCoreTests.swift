import XCTest
@testable import OpenLidCore

final class OpenLidCoreTests: XCTestCase {
    func testClamshellMonitor() {
        let monitor = ClamshellMonitor.shared
        let isClosed = monitor.updateLidState()
        // On a laptop or Mac desktop, this should return a boolean without crashing
        XCTAssertNotNil(isClosed)
    }
    
    func testBatteryMonitor() {
        let monitor = BatteryMonitor.shared
        monitor.updateBatteryState()
        XCTAssertGreaterThanOrEqual(monitor.batteryPercent, 0)
        XCTAssertLessThanOrEqual(monitor.batteryPercent, 100)
    }
    
    func testThermalMonitor() {
        let monitor = ThermalMonitor.shared
        monitor.updateThermalState()
        XCTAssertFalse(monitor.stateDescription.isEmpty)
    }
    
    func testSessionTimerFormatting() {
        let timer = SessionTimer()
        timer.start(preset: .min30)
        XCTAssertTrue(timer.isTimerRunning)
        XCTAssertEqual(timer.formattedRemainingTime, "30:00")
        timer.stop()
        XCTAssertFalse(timer.isTimerRunning)
        XCTAssertEqual(timer.formattedRemainingTime, "")
    }
    
    func testSessionPresets() {
        XCTAssertNil(SessionPreset.indefinite.duration)
        XCTAssertEqual(SessionPreset.min15.duration, 15 * 60)
        XCTAssertEqual(SessionPreset.min30.duration, 30 * 60)
        XCTAssertEqual(SessionPreset.hour1.duration, 60 * 60)
        XCTAssertEqual(SessionPreset.hour2.duration, 120 * 60)
    }
}

